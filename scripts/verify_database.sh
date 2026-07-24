#!/bin/bash

# Script para verificar se o banco de dados foi criado corretamente

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --nome-banco)
            NOME_BANCO="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        *)
            log_error "Parâmetro desconhecido: $1"
            exit 1
            ;;
    esac
done

# Configurar conexão (assumindo que o bastion host já tem acesso direto ao DB)
TUNNEL_PID=""
EFFECTIVE_HOST="$DB_HOST"
EFFECTIVE_PORT="$DB_PORT"

log "🔍 Verificando banco '$NOME_BANCO' em $EFFECTIVE_HOST:$EFFECTIVE_PORT"

# Função para executar SQL com saída limpa
execute_sql() {
    local sql="$1"
    local database="${2:-$NOME_BANCO}"
    PGPASSWORD="$DB_PASSWORD" psql -h "$EFFECTIVE_HOST" -p "$EFFECTIVE_PORT" \
        -U "$DB_USER" -d "$database" -t -c "$sql" 2>/dev/null | xargs
}

# Testar conexão com retry (3 tentativas, 5s de intervalo)
log "🔍 Testando conexão com '$NOME_BANCO'..."
PSQL_ERROR=""
CONNECTED=false
for attempt in 1 2 3; do
    if PSQL_OUT=$(PGPASSWORD="$DB_PASSWORD" psql \
            -h "$EFFECTIVE_HOST" -p "$EFFECTIVE_PORT" \
            -U "$DB_USER" -d "$NOME_BANCO" \
            -c "SELECT 1;" 2>&1); then
        CONNECTED=true
        break
    else
        PSQL_ERROR="$PSQL_OUT"
        log_warning "Tentativa $attempt/3 falhou — aguardando 5s..."
        sleep 5
    fi
done

if [[ "$CONNECTED" != "true" ]]; then
    log_error "Falha ao conectar em $EFFECTIVE_HOST:$EFFECTIVE_PORT como '$DB_USER' no banco '$NOME_BANCO'"
    log_error "Erro PostgreSQL: $PSQL_ERROR"
    exit 1
fi
log_success "Conexão com '$NOME_BANCO' estabelecida"

# Verificar tabelas essenciais
log "📋 Verificando tabelas essenciais..."
TABELAS=("configuracao" "empresa" "usuario")
for tabela in "${TABELAS[@]}"; do
    count="0"
    count=$(execute_sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='$tabela';") || count="0"
    if [[ "${count:-0}" -gt 0 ]]; then
        log_success "Tabela '$tabela' presente"
    else
        log_error "Tabela '$tabela' não encontrada!"
        exit 1
    fi
done

# Verificar versão (não-bloqueante)
log "📊 Verificando versão do banco..."
versao=$(execute_sql "SELECT valor_texto FROM configuracao WHERE nomecampo = 'versao_banco' LIMIT 1;" 2>/dev/null || true)
if [[ -n "$versao" && "$versao" != "" ]]; then
    log_success "Versão do banco: $versao"
else
    log_warning "Campo versao_banco não encontrado na tabela configuracao"
fi

log_success "Verificação do banco '$NOME_BANCO' concluída"