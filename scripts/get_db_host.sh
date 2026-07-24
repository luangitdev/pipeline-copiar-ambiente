#!/bin/bash

# Script para obter o host do banco de dados baseado no servidor
# Uso: get_db_host.sh <servidor>

set -euo pipefail

SERVIDOR="${1:-}"

if [[ -z "$SERVIDOR" ]]; then
    echo "❌ Erro: Servidor não fornecido" >&2
    exit 1
fi

# Converter para minúsculas para garantir compatibilidade
SERVIDOR=$(echo "$SERVIDOR" | tr '[:upper:]' '[:lower:]')

# Mapeamento de servidores para hosts de banco
case "$SERVIDOR" in
    "gcp01")
        echo "10.200.0.19"
        ;;
    "gcp02")
        echo "10.200.0.29"
        ;;
    "gcp-pln")
        echo "10.200.0.3"
        ;;
    "oci-pln-qa")
        echo "164.152.198.41"
        ;;
    "gcp03")
        echo "10.200.0.40"
        ;;
    "oci-db-imp")
        echo "204.216.191.1"
        ;;
    "oci-db-qa")
        echo "167.126.30.109"
        ;;
    "oci-db-02")
        echo "204.216.178.119"
        ;;
    *)
        echo "❌ Servidor desconhecido: $SERVIDOR (esperado: gcp01, gcp02, gcp03, gcp-pln, oci-pln-qa, oci-db-imp, oci-db-qa ou oci-db-02)" >&2
        exit 1
        ;;
esac