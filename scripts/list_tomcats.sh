#!/bin/bash

# Lista ou localiza Tomcats (volumes Docker) em um servidor de deploy via SSH.
#
# Modos:
#   list  Lista os Tomcats existentes no servidor (RESULT:TOMCAT=<nome>, um por linha)
#   find  Localiza o Tomcat onde a aplicação --app-name está publicada (RESULT:TOMCAT=<nome>)
#
# A senha do sudo é lida de um arquivo (--sudo-password-file) e enviada ao sudo por stdin;
# nunca é passada como argumento nem logada.
# Saída: logs vão para stderr; o resultado é emitido em stdout como linhas "RESULT:CHAVE=valor".

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

exec 3>&1 1>&2

MODE=""
TIPO_AMBIENTE=""
DEPLOY_SERVER_IP=""
SSH_KEY_FILE=""
SUDO_PASSWORD_FILE=""
APP_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode)                MODE="$2"; shift 2 ;;
        --tipo-ambiente)       TIPO_AMBIENTE="$2"; shift 2 ;;
        --deploy-server-ip)    DEPLOY_SERVER_IP="$2"; shift 2 ;;
        --ssh-key-file)        SSH_KEY_FILE="$2"; shift 2 ;;
        --sudo-password-file)  SUDO_PASSWORD_FILE="$2"; shift 2 ;;
        --app-name)            APP_NAME="$2"; shift 2 ;;
        *)
            log_error "Parâmetro desconhecido: $1"
            exit 1
            ;;
    esac
done

if [[ "$MODE" != "list" && "$MODE" != "find" ]]; then
    log_error "--mode inválido: '$MODE' (esperado: list ou find)"
    exit 1
fi
if [[ -z "$DEPLOY_SERVER_IP" || -z "$SUDO_PASSWORD_FILE" ]]; then
    log_error "Parâmetros obrigatórios faltando (--deploy-server-ip, --sudo-password-file)."
    exit 1
fi
if [[ "$MODE" == "find" && -z "$APP_NAME" ]]; then
    log_error "--app-name é obrigatório no modo find."
    exit 1
fi
if [[ ! -f "$SUDO_PASSWORD_FILE" ]]; then
    log_error "Arquivo de senha do sudo não encontrado."
    exit 1
fi

case "$TIPO_AMBIENTE" in
    pln) REMOTE_LIST_SCRIPT="/opt/scripts/listarVersoesPlanner.sh" ;;
    ptf) REMOTE_LIST_SCRIPT="/opt/scripts/listarVersoesRoteirizador.sh" ;;
    *)
        log_error "--tipo-ambiente inválido: '$TIPO_AMBIENTE' (esperado: ptf ou pln)"
        exit 1
        ;;
esac

SSH_OPTS=(-o StrictHostKeyChecking=no -o ConnectTimeout=20 -o BatchMode=yes)
if [[ -n "$SSH_KEY_FILE" ]]; then
    if [[ ! -f "$SSH_KEY_FILE" ]]; then
        log_error "Arquivo de chave SSH não encontrado: $SSH_KEY_FILE"
        exit 1
    fi
    SSH_OPTS+=(-i "$SSH_KEY_FILE")
fi

log "🔎 Consultando $REMOTE_LIST_SCRIPT em $DEPLOY_SERVER_IP..."
if ! RAW=$({ cat "$SUDO_PASSWORD_FILE"; echo; } | ssh "${SSH_OPTS[@]}" "infra@${DEPLOY_SERVER_IP}" "sudo -S -p '' $REMOTE_LIST_SCRIPT"); then
    log_error "Falha ao executar $REMOTE_LIST_SCRIPT em $DEPLOY_SERVER_IP."
    exit 1
fi
RAW=$(printf '%s\n' "$RAW" | tr -d '\r')

if [[ "$MODE" == "list" ]]; then
    # 1ª coluna, sem espaços, sem duplicados, ignorando linhas que não parecem nome de tomcat
    TOMCATS=$(printf '%s\n' "$RAW" | cut -d '|' -f1 \
        | awk '{ gsub(/^[ \t]+|[ \t]+$/, "") } $0 ~ /^[A-Za-z0-9._-]+$/ && !seen[$0]++')
    if [[ -z "$TOMCATS" ]]; then
        log_error "Nenhum Tomcat encontrado em $DEPLOY_SERVER_IP."
        exit 1
    fi
    log_success "$(printf '%s\n' "$TOMCATS" | wc -l) Tomcat(s) encontrado(s) em $DEPLOY_SERVER_IP"
    while IFS= read -r t; do
        echo "RESULT:TOMCAT=$t" >&3
    done <<< "$TOMCATS"
else
    # Igualdade exata na 2ª coluna (evita casar nomes que apenas começam com o mesmo prefixo)
    TOMCAT=$(printf '%s\n' "$RAW" | awk -F '|' -v app="$APP_NAME" '
        { c1 = $1; c2 = $2; gsub(/^[ \t]+|[ \t]+$/, "", c1); gsub(/^[ \t]+|[ \t]+$/, "", c2) }
        c2 == app && c1 ~ /^[A-Za-z0-9._-]+$/ { print c1; exit }')
    if [[ -z "$TOMCAT" ]]; then
        log_warning "Aplicação '$APP_NAME' não encontrada em $DEPLOY_SERVER_IP."
    else
        log_success "Aplicação '$APP_NAME' encontrada no Tomcat '$TOMCAT'"
    fi
    echo "RESULT:TOMCAT=$TOMCAT" >&3
fi
