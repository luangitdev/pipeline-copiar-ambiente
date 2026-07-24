#!/bin/bash

# Script principal para cópia de banco de dados existente
# Baseado no create_database.sh, mas copia de um banco origem em vez de template

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

# ========== SOURCE (ORIGEM) ==========
SOURCE_SERVIDOR=""
SOURCE_DB_HOST=""
SOURCE_DB_PORT="5432"
SOURCE_DB_USER=""
SOURCE_DB_PASSWORD=""
SOURCE_NOME_BANCO=""
SOURCE_VERSAO_BANCO=""

# ========== DESTINO ==========
DESTINO_SERVIDOR=""
DESTINO_DB_HOST=""
DESTINO_DB_PORT="5432"
DESTINO_DB_USER=""
DESTINO_DB_PASSWORD=""
DESTINO_DB_INTERNAL_HOST=""
DESTINO_NOME_BANCO=""
DESTINO_VERSAO_BANCO=""

# ========== GERAIS ==========
TIPO_AMBIENTE=""
WORKSPACE=""
UPDATES_DIR_OVERRIDE=""
ALLOW_EXISTING_DB="${ALLOW_EXISTING_DB:-false}"

# Parse de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --tipo-ambiente)
            TIPO_AMBIENTE="$2"
            shift 2
            ;;
        --source-servidor)
            SOURCE_SERVIDOR="$2"
            shift 2
            ;;
        --source-db-host)
            SOURCE_DB_HOST="$2"
            shift 2
            ;;
        --source-db-port)
            SOURCE_DB_PORT="$2"
            shift 2
            ;;
        --source-db-user)
            SOURCE_DB_USER="$2"
            shift 2
            ;;
        --source-db-password)
            SOURCE_DB_PASSWORD="$2"
            shift 2
            ;;
        --source-nome-banco)
            SOURCE_NOME_BANCO="$2"
            shift 2
            ;;
        --source-versao-banco)
            SOURCE_VERSAO_BANCO="$2"
            shift 2
            ;;
        --destino-servidor)
            DESTINO_SERVIDOR="$2"
            shift 2
            ;;
        --destino-db-host)
            DESTINO_DB_HOST="$2"
            shift 2
            ;;
        --destino-db-port)
            DESTINO_DB_PORT="$2"
            shift 2
            ;;
        --destino-db-user)
            DESTINO_DB_USER="$2"
            shift 2
            ;;
        --destino-db-password)
            DESTINO_DB_PASSWORD="$2"
            shift 2
            ;;
        --destino-db-internal-host)
            DESTINO_DB_INTERNAL_HOST="$2"
            shift 2
            ;;
        --destino-nome-banco)
            DESTINO_NOME_BANCO="$2"
            shift 2
            ;;
        --destino-versao-banco)
            DESTINO_VERSAO_BANCO="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --updates-dir)
            UPDATES_DIR_OVERRIDE="$2"
            shift 2
            ;;
        *)
            log_error "Parâmetro desconhecido: $1"
            exit 1
            ;;
    esac
done

# Validações
if [[ -z "$TIPO_AMBIENTE" || -z "$SOURCE_DB_HOST" || -z "$SOURCE_DB_USER" || -z "$SOURCE_DB_PASSWORD" || -z "$SOURCE_NOME_BANCO" || -z "$SOURCE_VERSAO_BANCO" ]]; then
    log_error "Parâmetros de ORIGEM obrigatórios faltando!"
    exit 1
fi
if [[ -z "$DESTINO_DB_HOST" || -z "$DESTINO_DB_USER" || -z "$DESTINO_DB_PASSWORD" || -z "$DESTINO_NOME_BANCO" || -z "$DESTINO_VERSAO_BANCO" ]]; then
    log_error "Parâmetros de DESTINO obrigatórios faltando!"
    exit 1
fi

# Proteger senhas contra expansão usando base64 encoding
SOURCE_DB_PASSWORD_ENCODED=$(echo -n "$SOURCE_DB_PASSWORD" | base64)
DESTINO_DB_PASSWORD_ENCODED=$(echo -n "$DESTINO_DB_PASSWORD" | base64)

# ========== FUNÇÕES AUXILIARES ==========

compare_versions() {
    local v1="$1"
    local v2="$2"
    if [[ "$v1" == "$v2" ]]; then
        echo "0"
        return
    fi
    local sorted=$(printf '%s\n%s\n' "$v1" "$v2" | sort -V)
    local first_line=$(echo "$sorted" | head -n1)
    if [[ "$first_line" == "$v1" ]]; then
        echo "-1"
    else
        echo "1"
    fi
}

extract_version_token() {
    local text="$1"
    if [[ "$text" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

run_psql_source() {
    local password_decoded=$(echo "$SOURCE_DB_PASSWORD_ENCODED" | base64 -d)
    PGPASSWORD="$password_decoded" PGUSER="$SOURCE_DB_USER" "$@"
}

run_psql_dest() {
    local password_decoded=$(echo "$DESTINO_DB_PASSWORD_ENCODED" | base64 -d)
    PGPASSWORD="$password_decoded" PGUSER="$DESTINO_DB_USER" "$@"
}

execute_sql_dest() {
    local sql="$1"
    local database="${2:-$DESTINO_NOME_BANCO}"
    if ! run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "$database" -c "$sql"; then
        log_error "Falha ao executar comando SQL no destino: $sql"
        return 1
    fi
    return 0
}

execute_sql_file_dest() {
    local file="$1"
    local database="$2"
    if [[ ! -f "$file" ]]; then
        log_error "Arquivo SQL não encontrado: $file"
        return 1
    fi
    log "📄 Executando: $(basename "$file")"
    if ! SQL_OUTPUT=$(run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "$database" -v ON_ERROR_STOP=1 -f "$file" 2>&1); then
        log_error "Falha ao executar $(basename "$file"):"
        echo "$SQL_OUTPUT"
        return 1
    fi
    return 0
}

# Aplica config.sql, updates e credentials no banco destino.
# Opcionalmente aplica start.sql se um arquivo de dados for fornecido.
configure_db() {
    local target_db="$1"
    local versao_inicial="$2"
    local local_dados_file="${3:-}"

    if [[ -n "$local_dados_file" && -f "$local_dados_file" ]]; then
        # Gerar start.sql personalizado
        "$WORKSPACE/scripts/generate_start_sql.sh" "$local_dados_file" "$TIPO_AMBIENTE" "$WORKSPACE/temp"

        local START_SQL="$WORKSPACE/temp/start_${TIPO_AMBIENTE}.sql"
        if [[ -f "$START_SQL" ]]; then
            log "🔧 Executando configuração inicial em '$target_db'..."
            if execute_sql_file_dest "$START_SQL" "$target_db"; then
                log_success "Configuração inicial aplicada"
            else
                log_error "Falha ao aplicar configuração inicial"
                return 1
            fi
        else
            log_warning "Arquivo start.sql não encontrado: $START_SQL"
        fi
    fi

    local CONFIG_SQL=""
    if [[ "$TIPO_AMBIENTE" != "pln" ]]; then
        local servidor_lower
        servidor_lower=$(echo "$DESTINO_SERVIDOR" | tr '[:upper:]' '[:lower:]')
        case "$servidor_lower" in
            oci-db-qa)
                CONFIG_SQL="$WORKSPACE/sql/$TIPO_AMBIENTE/config-qa.sql"
                ;;
            oci-db-imp)
                CONFIG_SQL="$WORKSPACE/sql/$TIPO_AMBIENTE/config-imp.sql"
                ;;
            oci-db-02)
                CONFIG_SQL="$WORKSPACE/sql/$TIPO_AMBIENTE/config-prod.sql"
                ;;
            *)
                CONFIG_SQL="$WORKSPACE/sql/$TIPO_AMBIENTE/config.sql"
                ;;
        esac
        if [[ -f "$CONFIG_SQL" ]]; then
            log "⚙️ Executando scripts de configuração em '$target_db' ($(basename "$CONFIG_SQL"))..."
            if execute_sql_file_dest "$CONFIG_SQL" "$target_db"; then
                log_success "Scripts de configuração aplicados"
            else
                log_error "Falha ao aplicar configuração"
                return 1
            fi
        else
            log_warning "Arquivo de configuração não encontrado: $CONFIG_SQL"
        fi
    fi

    log "🔄 Executando updates necessários em '$target_db' ($versao_inicial → $DESTINO_VERSAO_BANCO)..."
    local UPDATES_DIR="${UPDATES_DIR_OVERRIDE:-$WORKSPACE/sql/$TIPO_AMBIENTE/updates}"
    local UPDATE_COUNT=0
    if [[ -d "$UPDATES_DIR" ]]; then
        local sorted_updates=()
        mapfile -t sorted_updates < <(find "$UPDATES_DIR" -maxdepth 1 -type f -name "*.sql" | sort -V)
        local eligible_update_files=()

        for update_file in "${sorted_updates[@]}"; do
            if [[ -f "$update_file" ]]; then
                local update_label
                update_label=$(basename "$update_file" .sql)
                local update_version
                if ! update_version=$(extract_version_token "$update_label"); then
                    log_warning "Pulando arquivo sem versão reconhecida no nome: $update_label"
                    continue
                fi
                local comp_atual comp_desejada
                comp_atual=$(compare_versions "$update_version" "$versao_inicial")
                comp_desejada=$(compare_versions "$update_version" "$DESTINO_VERSAO_BANCO")
                if [[ "$comp_atual" == "1" ]] && [[ "$comp_desejada" == "-1" || "$comp_desejada" == "0" ]]; then
                    eligible_update_files+=("$update_file")
                else
                    log "   ⏭️  Pulando update $update_version (comp_atual=$comp_atual vs $versao_inicial, comp_desejada=$comp_desejada vs $DESTINO_VERSAO_BANCO)"
                fi
            fi
        done

        log "🔄 ${#eligible_update_files[@]} updates elegíveis para aplicação ($versao_inicial → $DESTINO_VERSAO_BANCO)"
        local FAILED_UPDATES=()
        for update_file in "${eligible_update_files[@]}"; do
            local update_label
            update_label=$(basename "$update_file" .sql)
            local update_version
            update_version=$(extract_version_token "$update_label" || echo "$update_label")
            log "🔄 Aplicando update: $update_label [versão: $update_version]"
            if execute_sql_file_dest "$update_file" "$target_db"; then
                ((UPDATE_COUNT++))
                log_success "Update $update_version aplicado"
            else
                log_error "Falha ao aplicar update $update_version — continuando para o próximo"
                FAILED_UPDATES+=("$update_label (versão: $update_version)")
            fi
        done
        log_success "$UPDATE_COUNT/${#eligible_update_files[@]} updates aplicados com sucesso em '$target_db'"
        if [[ ${#FAILED_UPDATES[@]} -gt 0 ]]; then
            log_warning "⚠️  ${#FAILED_UPDATES[@]} update(s) falharam:"
            for f in "${FAILED_UPDATES[@]}"; do
                log_warning "   - $f"
            done
            # Propaga lista de falhas para o escopo global via arquivo temporário
            printf '%s\n' "${FAILED_UPDATES[@]}" > "$WORKSPACE/temp/.failed_updates"
        fi
    else
        log_warning "Diretório de updates não encontrado: $UPDATES_DIR"
    fi

    local CREDENTIALS_SQL="$WORKSPACE/sql/$TIPO_AMBIENTE/credentials.sql"
    if [[ -f "$CREDENTIALS_SQL" ]]; then
        log "🔐 Aplicando credenciais em '$target_db'..."
        if execute_sql_file_dest "$CREDENTIALS_SQL" "$target_db"; then
            log_success "Credenciais aplicadas com sucesso"
        else
            log_warning "Erro ao aplicar credenciais (pode ser normal se usuários já existem)"
        fi
    fi
}

# ========== NORMALIZAÇÃO DE VERSÕES ==========
if ! normalized_source_version=$(extract_version_token "$SOURCE_VERSAO_BANCO"); then
    log_error "Versão de banco origem inválida: '$SOURCE_VERSAO_BANCO' (esperado formato N.N.N.N-N)"
    exit 1
fi
SOURCE_VERSAO_BANCO="$normalized_source_version"

if ! normalized_dest_version=$(extract_version_token "$DESTINO_VERSAO_BANCO"); then
    log_error "Versão de banco destino inválida: '$DESTINO_VERSAO_BANCO' (esperado formato N.N.N.N-N)"
    exit 1
fi
DESTINO_VERSAO_BANCO="$normalized_dest_version"

log "🚀 Copiando banco '$SOURCE_NOME_BANCO' [$SOURCE_DB_HOST] → '$DESTINO_NOME_BANCO' [$DESTINO_DB_HOST]"
log "📊 Versões: origem=$SOURCE_VERSAO_BANCO | destino=$DESTINO_VERSAO_BANCO"

# ========== VERIFICAÇÃO DE FERRAMENTAS ==========
if ! command -v psql &> /dev/null; then
    log_error "PostgreSQL client (psql) não encontrado"
    exit 1
fi
if ! command -v pg_dump &> /dev/null; then
    log_error "pg_dump não encontrado"
    exit 1
fi

# ========== 1. TESTAR CONEXÃO COM ORIGEM ==========
log "🔍 Testando conexão com servidor de ORIGEM $SOURCE_DB_HOST:$SOURCE_DB_PORT..."
if ! run_psql_source psql -h "$SOURCE_DB_HOST" -p "$SOURCE_DB_PORT" -U "$SOURCE_DB_USER" -d "postgres" -c "SELECT 1;" &>/dev/null; then
    # Tentar com o próprio banco como fallback (o usuário pode não ter acesso ao postgres)
    if ! run_psql_source psql -h "$SOURCE_DB_HOST" -p "$SOURCE_DB_PORT" -U "$SOURCE_DB_USER" -d "$SOURCE_NOME_BANCO" -c "SELECT 1;" &>/dev/null; then
        log_error "Falha ao conectar no servidor de origem $SOURCE_DB_HOST:$SOURCE_DB_PORT (usuário: $SOURCE_DB_USER)"
        exit 1
    fi
fi
log_success "Conexão com servidor de origem estabelecida!"

# ========== 2. VERIFICAR SE BANCO ORIGEM EXISTE ==========
log "🔍 Verificando se banco origem '$SOURCE_NOME_BANCO' existe..."
DB_EXISTS=$(run_psql_source psql -h "$SOURCE_DB_HOST" -p "$SOURCE_DB_PORT" -U "$SOURCE_DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname = '$SOURCE_NOME_BANCO';" 2>/dev/null || echo "")
if [[ "$DB_EXISTS" != "1" ]]; then
    # Tentar novamente usando o próprio banco como template de conexão
    DB_EXISTS=$(run_psql_source psql -h "$SOURCE_DB_HOST" -p "$SOURCE_DB_PORT" -U "$SOURCE_DB_USER" -d "$SOURCE_NOME_BANCO" -tAc "SELECT 1 FROM pg_database WHERE datname = '$SOURCE_NOME_BANCO';" 2>/dev/null || echo "")
    if [[ "$DB_EXISTS" != "1" ]]; then
        log_error "Banco origem '$SOURCE_NOME_BANCO' não encontrado em $SOURCE_DB_HOST"
        exit 1
    fi
fi
log_success "Banco origem '$SOURCE_NOME_BANCO' confirmado!"

# ========== 3. TESTAR CONEXÃO COM DESTINO ==========
log "🔍 Testando conexão com servidor de DESTINO $DESTINO_DB_HOST:$DESTINO_DB_PORT..."
if ! run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "postgres" -c "SELECT 1;" &>/dev/null; then
    log_error "Falha ao conectar no servidor de destino $DESTINO_DB_HOST:$DESTINO_DB_PORT (usuário: $DESTINO_DB_USER)"
    exit 1
fi
log_success "Conexão com servidor de destino estabelecida!"

# ========== 4. VERIFICAR SE BANCO DESTINO JÁ EXISTE ==========
log "🔍 Verificando se banco destino '$DESTINO_NOME_BANCO' já existe..."
DB_EXISTS=$(run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname = '$DESTINO_NOME_BANCO';" 2>/dev/null || echo "")
if [[ "$DB_EXISTS" == "1" ]]; then
    if [[ "$ALLOW_EXISTING_DB" == "true" ]]; then
        log_warning "Banco '$DESTINO_NOME_BANCO' já existe no destino e ALLOW_EXISTING_DB=true; continuando."
    else
        log_error "Banco '$DESTINO_NOME_BANCO' já existe no servidor de destino."
        log_error "Remova o banco existente ou use ALLOW_EXISTING_DB=true."
        exit 1
    fi
else
    # ========== 5. CRIAR BANCO VAZIO NO DESTINO ==========
    log "📄 Criando banco vazio '$DESTINO_NOME_BANCO' no destino..."
    CREATE_OUTPUT=$(run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "postgres" -c "CREATE DATABASE \"$DESTINO_NOME_BANCO\";" 2>&1)
    if [[ $? -ne 0 ]]; then
        log_error "Falha ao criar banco '$DESTINO_NOME_BANCO' no destino:"
        echo "$CREATE_OUTPUT"
        exit 1
    fi
    log_success "Banco vazio criado no destino!"
fi

# ========== 6. DUMP DO BANCO ORIGEM ==========
log "📤 Fazendo dump do banco '$SOURCE_NOME_BANCO' em $SOURCE_DB_HOST..."
DUMP_FILE="/tmp/copy_dump_${SOURCE_NOME_BANCO}_$$.sql"

# Usar pg_dump com opções que garantem um dump completo e restaurável
if ! run_psql_source pg_dump \
    -h "$SOURCE_DB_HOST" \
    -p "$SOURCE_DB_PORT" \
    -U "$SOURCE_DB_USER" \
    -d "$SOURCE_NOME_BANCO" \
    --no-owner \
    --no-privileges \
    > "$DUMP_FILE"; then
    log_error "Falha ao fazer dump do banco '$SOURCE_NOME_BANCO'"
    rm -f "$DUMP_FILE"
    exit 1
fi

DUMP_SIZE=$(du -h "$DUMP_FILE" 2>/dev/null | cut -f1)
log_success "Dump concluído: $DUMP_FILE ($DUMP_SIZE)"

# ========== 7. RESTORE NO BANCO DESTINO ==========
log "📥 Restaurando dump no banco '$DESTINO_NOME_BANCO' em $DESTINO_DB_HOST..."
if ! run_psql_dest psql -h "$DESTINO_DB_HOST" -p "$DESTINO_DB_PORT" -U "$DESTINO_DB_USER" -d "$DESTINO_NOME_BANCO" < "$DUMP_FILE"; then
    log_error "Falha ao restaurar dump no banco '$DESTINO_NOME_BANCO'"
    rm -f "$DUMP_FILE"
    exit 1
fi
rm -f "$DUMP_FILE"
log_success "Restore concluído no destino!"

# ========== 8. CONFIGURAR BANCO DESTINO ==========
log "🔧 Configurando banco destino '$DESTINO_NOME_BANCO'..."
# Não aplicamos start.sql pois o banco destino é uma cópia do origem e
# já contém os dados de ambiente. Aplicamos apenas config, updates e credentials.
configure_db "$DESTINO_NOME_BANCO" "$SOURCE_VERSAO_BANCO"
if [[ $? -ne 0 ]]; then
    log_error "Falha na configuração do banco destino"
    exit 1
fi

log_success "Banco '$DESTINO_NOME_BANCO' copiado e configurado com sucesso!"
log_success "Versão final: $DESTINO_VERSAO_BANCO"

# ========== RESUMO DE UPDATES COM FALHA ==========
if [[ -f "$WORKSPACE/temp/.failed_updates" ]]; then
    log_warning "╔══════════════════════════════════════════════════════════════╗"
    log_warning "║  RESUMO: ALGUNS UPDATES NÃO FORAM APLICADOS COM SUCESSO      ║"
    log_warning "╠══════════════════════════════════════════════════════════════╣"
    while IFS= read -r line; do
        log_warning "║  - $line"
    done < "$WORKSPACE/temp/.failed_updates"
    log_warning "╚══════════════════════════════════════════════════════════════╝"
    log_warning "O pipeline prosseguiu, mas revise os updates acima manualmente."
fi
