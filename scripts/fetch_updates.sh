#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

TIPO_AMBIENTE=""
REPO_URL=""
REPO_BRANCH=""
WORK_DIR=""
OUTPUT_DIR=""
GIT_USERNAME=""
GIT_TOKEN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tipo-ambiente)
            TIPO_AMBIENTE="$2"
            shift 2
            ;;
        --repo-url)
            REPO_URL="$2"
            shift 2
            ;;
        --repo-branch)
            REPO_BRANCH="$2"
            shift 2
            ;;
        --work-dir)
            WORK_DIR="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --git-username)
            GIT_USERNAME="$2"
            shift 2
            ;;
        --git-token)
            GIT_TOKEN="$2"
            shift 2
            ;;
        *)
            log_error "Parâmetro desconhecido: $1"
            exit 1
            ;;
    esac
done

if [[ -z "$TIPO_AMBIENTE" || -z "$REPO_URL" || -z "$REPO_BRANCH" || -z "$WORK_DIR" || -z "$OUTPUT_DIR" ]]; then
    log_error "Parâmetros obrigatórios faltando!"
    exit 1
fi

TIPO_AMBIENTE=$(echo "$TIPO_AMBIENTE" | tr '[:upper:]' '[:lower:]')
if [[ "$TIPO_AMBIENTE" != "ptf" && "$TIPO_AMBIENTE" != "pln" ]]; then
    log_error "Tipo de ambiente inválido: $TIPO_AMBIENTE (esperado: ptf ou pln)"
    exit 1
fi

if [[ -z "$GIT_USERNAME" || -z "$GIT_TOKEN" ]]; then
    log_error "Credenciais Git não informadas"
    exit 1
fi

CLONE_DIR="$WORK_DIR/infraestrutura"
mkdir -p "$WORK_DIR"
rm -rf "$CLONE_DIR"
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR"/*.sql

ASKPASS_SCRIPT="$WORK_DIR/git-askpass.sh"
cat > "$ASKPASS_SCRIPT" <<'EOF'
#!/bin/sh
case "$1" in
  *Username*) echo "$GIT_USERNAME" ;;
  *Password*) echo "$GIT_TOKEN" ;;
  *) echo "" ;;
esac
EOF
chmod 700 "$ASKPASS_SCRIPT"

cleanup() {
    rm -f "$ASKPASS_SCRIPT"
}
trap cleanup EXIT

export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS="$ASKPASS_SCRIPT"
export GIT_USERNAME
export GIT_TOKEN

log "🔄 Clonando repositório de migrations..."
if git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$CLONE_DIR"; then
    log_success "Repositório clonado em: $CLONE_DIR"
else
    clone_exit_code=$?
    log_error "Falha ao clonar repositório '$REPO_URL' na branch '$REPO_BRANCH' (exit code: $clone_exit_code)"
    log_error "Verifique URL, branch e credenciais (PAT/usuário) no Jenkins."
    exit "$clone_exit_code"
fi

find_updates_root() {
    find "$CLONE_DIR" -maxdepth 3 -type d \
        \( -iname "Atualizações de banco" -o -iname "Atualizacoes de banco" -o -iname "Atualizacoes banco" -o -iname "*atualiza*de*ban*" \) \
        | head -n1
}

find_env_dir() {
    local base_dir="$1"
    local env="$2"

    if [[ "$env" == "ptf" ]]; then
        find "$base_dir" -mindepth 1 -maxdepth 2 -type d -iname "*pathfind*" | head -n1
    else
        find "$base_dir" -mindepth 1 -maxdepth 2 -type d -iname "*planner*" | head -n1
    fi
}

UPDATES_ROOT=$(find_updates_root || true)
if [[ -z "${UPDATES_ROOT:-}" ]]; then
    log_error "Pasta de atualizações não encontrada no repositório"
    exit 1
fi

SOURCE_DIR=$(find_env_dir "$UPDATES_ROOT" "$TIPO_AMBIENTE" || true)
if [[ -z "${SOURCE_DIR:-}" ]]; then
    log_error "Pasta de updates do ambiente '$TIPO_AMBIENTE' não encontrada em '$UPDATES_ROOT'"
    exit 1
fi

log "📁 Origem dos updates: $SOURCE_DIR"

copied=0
skipped_identical=0
skipped_old_version=0

# Ignorar updates em pastas de versões antigas com base no ambiente
if [[ "$TIPO_AMBIENTE" == "ptf" ]]; then
    BASE_MAJOR=15
else
    BASE_MAJOR=9
fi

should_skip_old_version_path() {
    local file_path="$1"
    local rel_path="${file_path#$SOURCE_DIR/}"
    local segment
    local major

    IFS='/' read -r -a path_parts <<< "$rel_path"
    for segment in "${path_parts[@]}"; do
        if [[ "$segment" =~ [Vv]ers[aã]o[[:space:]_-]*([0-9]+) ]]; then
            major="${BASH_REMATCH[1]}"
            if [[ "$major" -lt "$BASE_MAJOR" ]]; then
                return 0
            fi
        fi
    done

    return 1
}

should_skip_outros_path() {
    local file_path="$1"
    local rel_path="${file_path#$SOURCE_DIR/}"
    local segment

    IFS='/' read -r -a path_parts <<< "$rel_path"
    for segment in "${path_parts[@]}"; do
        if [[ "$segment" =~ ^[Oo][Uu][Tt][Rr][Oo][Ss]$ ]]; then
            return 0
        fi
    done

    return 1
}

should_skip_pln_specific() {
    local file_path="$1"
    local rel_path="${file_path#$SOURCE_DIR/}"

    # Ignorar arquivos .sql soltos na raiz (sem subpasta)
    if [[ "$rel_path" != */* ]]; then
        return 0
    fi

    # Ignorar pasta serialização (e variações)
    local segment
    IFS='/' read -r -a path_parts <<< "$rel_path"
    for segment in "${path_parts[@]}"; do
        if [[ "$segment" =~ ^[Ss]erializa ]]; then
            return 0
        fi
    done

    return 1
}

skipped_pln=0

while IFS= read -r -d '' sql_file; do
    if should_skip_outros_path "$sql_file"; then
        continue
    fi

    if [[ "$TIPO_AMBIENTE" == "pln" ]] && should_skip_pln_specific "$sql_file"; then
        skipped_pln=$((skipped_pln + 1))
        continue
    fi

    if should_skip_old_version_path "$sql_file"; then
        skipped_old_version=$((skipped_old_version + 1))
        continue
    fi

    base_file="$(basename "$sql_file")"
    target_file="$OUTPUT_DIR/$base_file"

    if [[ -f "$target_file" ]]; then
        if cmp -s "$sql_file" "$target_file"; then
            log_warning "Arquivo SQL duplicado com conteúdo idêntico ignorado: $base_file"
            skipped_identical=$((skipped_identical + 1))
            continue
        fi

        log_warning "Conflito de arquivo SQL duplicado: $base_file — substituindo pelo mais recente"
        log_warning " - Substituído: $target_file"
        log_warning " - Novo arquivo: $sql_file"
    fi

    cp "$sql_file" "$target_file"
    copied=$((copied + 1))
done < <(find "$SOURCE_DIR" -type f -name "*.sql" -print0)

if [[ "$copied" -eq 0 ]]; then
    log_warning "Nenhum arquivo .sql encontrado na origem: $SOURCE_DIR"
else
    log_success "$copied arquivos SQL copiados para: $OUTPUT_DIR"
    if [[ "$skipped_identical" -gt 0 ]]; then
        log_warning "$skipped_identical duplicado(s) idêntico(s) ignorado(s)"
    fi
    if [[ "$skipped_old_version" -gt 0 ]]; then
        log_warning "$skipped_old_version arquivo(s) ignorado(s) por estarem em pastas de versão antiga (major < $BASE_MAJOR)"
    fi
    if [[ "$skipped_pln" -gt 0 ]]; then
        log_warning "$skipped_pln arquivo(s) PLN ignorado(s) (raiz ou pasta serialização)"
    fi
fi
