#!/bin/bash

# Descoberta de informações da ORIGEM.
#
# Modos:
#   db-version  Consulta a versão do banco de dados de origem (executar onde há acesso ao banco, ex.: bastion)
#   app-info    Normaliza a URL da aplicação de origem, deriva o nome da aplicação e lê a versão via curl
#
# Saída: logs vão para stderr; o resultado é emitido em stdout como linhas "RESULT:CHAVE=valor".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

# stdout original (fd 3) fica reservado para os RESULT; todo o resto vai para stderr
exec 3>&1 1>&2

MODE=""
TIPO_AMBIENTE=""
DB_HOST=""
DB_PORT="5432"
DB_USER=""
DB_PASSWORD_FILE=""
DB_NAME=""
APP_URL=""
APP_NAME_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)               MODE="$2"; shift 2 ;;
        --tipo-ambiente)      TIPO_AMBIENTE="$2"; shift 2 ;;
        --db-host)            DB_HOST="$2"; shift 2 ;;
        --db-port)            DB_PORT="$2"; shift 2 ;;
        --db-user)            DB_USER="$2"; shift 2 ;;
        --db-password-file)   DB_PASSWORD_FILE="$2"; shift 2 ;;
        --db-name)            DB_NAME="$2"; shift 2 ;;
        --app-url)            APP_URL="$2"; shift 2 ;;
        --app-name)           APP_NAME_OVERRIDE="$2"; shift 2 ;;
        *)
            log_error "Parâmetro desconhecido: $1"
            exit 1
            ;;
    esac
done

if [[ "$TIPO_AMBIENTE" != "ptf" && "$TIPO_AMBIENTE" != "pln" ]]; then
    log_error "--tipo-ambiente inválido: '$TIPO_AMBIENTE' (esperado: ptf ou pln)"
    exit 1
fi

extract_version_token() {
    local text="$1"
    if [[ "$text" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

discover_db_version() {
    if [[ -z "$DB_HOST" || -z "$DB_USER" || -z "$DB_PASSWORD_FILE" || -z "$DB_NAME" ]]; then
        log_error "Parâmetros obrigatórios faltando para db-version (--db-host, --db-user, --db-password-file, --db-name)."
        exit 1
    fi
    if [[ ! -f "$DB_PASSWORD_FILE" ]]; then
        log_error "Arquivo de senha do banco não encontrado."
        exit 1
    fi

    local query
    if [[ "$TIPO_AMBIENTE" == "pln" ]]; then
        query="select versao from versaobanco order by id desc limit 1"
    else
        query="select valor_texto from configuracao where nomecampo = 'versao_banco'"
    fi

    log "🔎 Consultando versão do banco '$DB_NAME' em $DB_HOST:$DB_PORT ($TIPO_AMBIENTE)..."
    local raw
    if ! raw=$(PGPASSWORD="$(cat "$DB_PASSWORD_FILE")" PGCONNECT_TIMEOUT=15 \
            psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tA -v ON_ERROR_STOP=1 -c "$query"); then
        log_error "Falha ao consultar a versão do banco de origem."
        exit 1
    fi

    local lines
    lines=$(printf '%s\n' "$raw" | tr -d '\r' | sed '/^[[:space:]]*$/d')
    local count
    count=$(printf '%s\n' "$lines" | sed '/^$/d' | wc -l)
    if [[ "$count" -ne 1 ]]; then
        log_error "A consulta de versão retornou $count linha(s); esperado exatamente 1."
        exit 1
    fi

    local version
    if ! version=$(extract_version_token "$lines"); then
        log_error "Valor de versão do banco origem fora do formato N.N.N.N-N: '$lines'"
        exit 1
    fi

    log_success "Versão do banco origem: $version"
    echo "RESULT:DB_VERSION=$version" >&3
}

discover_app_info() {
    if [[ -z "$APP_URL" ]]; then
        log_error "--app-url é obrigatório no modo app-info."
        exit 1
    fi

    local url="$APP_URL"
    if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
    fi

    local scheme="${url%%://*}"
    local rest="${url#*://}"
    local host="${rest%%/*}"
    host="${host%%[?#]*}"
    local path=""
    if [[ "$rest" == */* ]]; then
        path="${rest#*/}"
    fi
    local first_segment="${path%%[/?#]*}"

    if [[ -z "$host" || -z "$first_segment" || "$first_segment" == *.xhtml || "$first_segment" == *.html ]]; then
        log_error "A URL da origem não contém o path da aplicação (esperado: https://host/<aplicacao>[/login.xhtml])."
        exit 1
    fi

    local login_url="$scheme://$host/$first_segment/login.xhtml"
    local app_name="${APP_NAME_OVERRIDE:-$first_segment}"

    local pattern
    if [[ "$TIPO_AMBIENTE" == "pln" ]]; then
        pattern='Planner v\.\K[0-9.-]+'
    else
        pattern='Pathfind v\.\K[0-9.-]+'
    fi

    log "🔎 Consultando versão da aplicação em $login_url..."
    local version=""
    version=$(curl -s -L --max-time 15 "$login_url" 2>/dev/null | grep -oP "$pattern" | head -n1 || true)
    if [[ -z "$version" ]]; then
        log_warning "Não foi possível obter a versão da aplicação de origem em $login_url."
    else
        log_success "Versão da aplicação origem: $version"
    fi

    echo "RESULT:APP_NAME=$app_name" >&3
    echo "RESULT:APP_LOGIN_URL=$login_url" >&3
    echo "RESULT:APP_VERSION=$version" >&3
}

case "$MODE" in
    db-version) discover_db_version ;;
    app-info)   discover_app_info ;;
    *)
        log_error "--mode inválido: '$MODE' (esperado: db-version ou app-info)"
        exit 1
        ;;
esac
