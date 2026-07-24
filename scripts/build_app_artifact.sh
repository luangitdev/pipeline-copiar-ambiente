#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

TIPO_AMBIENTE=""
REPO_URL=""
REPO_BRANCH=""
APP_VERSION=""
OUTPUT_WAR=""
WORKSPACE=""
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
        --app-version)
            APP_VERSION="$2"
            shift 2
            ;;
        --output-war)
            OUTPUT_WAR="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE="$2"
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

if [[ -z "$TIPO_AMBIENTE" || -z "$REPO_URL" || -z "$REPO_BRANCH" || -z "$APP_VERSION" || -z "$OUTPUT_WAR" || -z "$WORKSPACE" || -z "$GIT_USERNAME" || -z "$GIT_TOKEN" ]]; then
    log_error "Parâmetros obrigatórios faltando para build do artefato."
    exit 1
fi

BUILD_ROOT="${WORKSPACE}/temp/app_source"
REPO_DIR="${BUILD_ROOT}/repo"
mkdir -p "$BUILD_ROOT"
rm -rf "$REPO_DIR"

log "📥 Clonando '$REPO_URL' [$TIPO_AMBIENTE] branch '$REPO_BRANCH' — versão: $APP_VERSION"
AUTH_B64="$(printf '%s:%s' "$GIT_USERNAME" "$GIT_TOKEN" | base64 | tr -d '\n')"
git_with_auth() {
    git -c http.extraHeader="Authorization: Basic ${AUTH_B64}" "$@"
}

# Clone completo (sem --depth 1) para poder buscar em todos os commits da branch
git_with_auth clone --no-checkout --single-branch --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"

build_ok=false
pushd "$REPO_DIR" >/dev/null

resolved_ref=""

# ---------------------------------------------------------------------------
# Função: converte N.N.N.N-N em inteiro comparável para ordenação semântica
# (aceita prefixos: "v", "v." ou nenhum)
# ---------------------------------------------------------------------------
version_to_int() {
    local ver="$1"
    # Remove prefixo "v." ou "v"
    ver="${ver#v.}"
    ver="${ver#v}"
    local main="${ver%%-*}"
    local build="${ver##*-}"
    [[ "$ver" == *"-"* ]] || build=0
    # O build pode ser decimal (ex: "53.5" vindo de application.minorVersion).
    # Tratamos sempre como string e só extraímos as partes numéricas aqui —
    # nunca aplicamos printf "%d" sobre o valor bruto, pois isso quebra com
    # "printf: 53.5: invalid number".
    local build_major="${build%%.*}"
    local build_minor="0"
    [[ "$build" == *.* ]] && build_minor="${build#*.}"
    IFS='.' read -r a b c d <<< "$main"
    printf '%d%04d%04d%04d%06d%04d' "${a:-0}" "${b:-0}" "${c:-0}" "${d:-0}" "${build_major:-0}" "${build_minor:-0}"
}

# Normaliza versão para comparação canônica (remove prefixo v. ou v)
normalize_version() {
    local ver="$1"
    ver="${ver#v.}"
    ver="${ver#v}"
    echo "$ver"
}

# ---------------------------------------------------------------------------
# Caminho do arquivo de versão dentro do repositório da aplicação. Usado como
# fonte alternativa quando a versão de build é decimal (ex: "53.5"), formato
# que normalmente não aparece nos títulos de commit.
# ---------------------------------------------------------------------------
VERSION_PROPERTIES_PATH="src/main/resources/version.properties"

# ---------------------------------------------------------------------------
# Extrai "application.version-application.minorVersion" de um conteúdo de
# version.properties. Ignora comentários e espaços. Sempre retorna string
# (minorVersion pode ser decimal, ex "53.5" — nunca é tratado como número).
# ---------------------------------------------------------------------------
read_version_from_properties() {
    local content="$1"
    local version minor_version
    version="$(printf '%s\n' "$content" \
        | grep -E '^[[:space:]]*application\.version[[:space:]]*=' \
        | head -1 \
        | sed -E 's/^[[:space:]]*application\.version[[:space:]]*=[[:space:]]*//; s/[[:space:]]*(#.*)?$//')"
    minor_version="$(printf '%s\n' "$content" \
        | grep -E '^[[:space:]]*application\.minorVersion[[:space:]]*=' \
        | head -1 \
        | sed -E 's/^[[:space:]]*application\.minorVersion[[:space:]]*=[[:space:]]*//; s/[[:space:]]*(#.*)?$//')"
    if [[ -n "$version" && -n "$minor_version" ]]; then
        printf '%s-%s' "$version" "$minor_version"
    fi
}

# ---------------------------------------------------------------------------
# Busca o commit cujo título contém a versão desejada na branch clonada
# Suporta formatos: 15.14.0.1-10  /  v15.14.0.1-10  /  v.15.14.0.1-10
#
# Ordem de precedência (compatibilidade retroativa):
#   1) Título do commit (comportamento histórico do script)
#   2) src/main/resources/version.properties do commit (fallback — cobre
#      versões de build decimais, ex "53.5", que não aparecem em títulos)
# ---------------------------------------------------------------------------
log "🔍 Buscando versão '${APP_VERSION}' nos títulos de commits da branch '${REPO_BRANCH}'..."

APP_VERSION_NORM="$(normalize_version "$APP_VERSION")"
found_source=""

# Carrega todos os commits: hash + título completo
mapfile -t all_commits < <(
    git log --format="%H %s" origin/"${REPO_BRANCH}" 2>/dev/null \
        || git log --format="%H %s"
)

# Extrai versões únicas no formato (v.|v)?N.N.N.N-N presentes nos títulos
# e normaliza removendo prefixo para comparação uniforme
mapfile -t all_versions_raw < <(
    printf '%s\n' "${all_commits[@]}" \
        | grep -oE '(v\.)?[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+' \
        | sed 's/^v\.//' | sed 's/^v//' \
        | sort -u || true
)

found_commit=""
found_version=""

# Busca a versão nos títulos tentando todos os prefixos comuns
for entry in "${all_commits[@]}"; do
    commit_hash="${entry%% *}"
    commit_msg="${entry#* }"
    for candidate in "$APP_VERSION_NORM" "v${APP_VERSION_NORM}" "v.${APP_VERSION_NORM}"; do
        if echo "$commit_msg" | grep -qF "$candidate"; then
            found_commit="$commit_hash"
            found_version="$candidate"
            found_source="commit-title"
            break 2
        fi
    done
done

# Fallback: versão não encontrada em nenhum título de commit — provavelmente
# uma versão de build decimal (ex: "53.5"). Procura o valor equivalente em
# application.version + application.minorVersion dentro de version.properties,
# lendo o conteúdo de cada commit sem checkout (git show).
if [[ -z "$found_commit" ]]; then
    log_warning "⚠️  Versão '${APP_VERSION}' não encontrada nos títulos de commits; tentando localizar via '${VERSION_PROPERTIES_PATH}'..."
    for entry in "${all_commits[@]}"; do
        commit_hash="${entry%% *}"
        props_content="$(git show "${commit_hash}:${VERSION_PROPERTIES_PATH}" 2>/dev/null || true)"
        [[ -z "$props_content" ]] && continue
        props_version="$(read_version_from_properties "$props_content")"
        [[ -z "$props_version" ]] && continue
        props_version_norm="$(normalize_version "$props_version")"
        if [[ "$props_version_norm" == "$APP_VERSION_NORM" ]]; then
            found_commit="$commit_hash"
            found_version="$props_version_norm"
            found_source="version.properties"
            break
        fi
    done
fi

if [[ -n "$found_commit" ]]; then
    commit_title="$(git log -1 --format='%s' "$found_commit")"
    log "✅ Versão '${APP_VERSION}' encontrada no commit: ${found_commit:0:12} — \"${commit_title}\" (fonte: ${found_source})"

    # Verifica se o commit foi diretamente na branch ou via merge
    # git log --ancestry-path encontra o caminho mais curto até o commit
    merge_commit="$(git log --merges --ancestry-path --format="%H %s" \
        "${found_commit}..origin/${REPO_BRANCH}" 2>/dev/null \
        | tail -1 || true)"

    if [[ -n "$merge_commit" ]]; then
        merge_hash="${merge_commit%% *}"
        merge_msg="${merge_commit#* }"
        log "🔀 Incorporado à branch '${REPO_BRANCH}' via merge: ${merge_hash:0:12} — \"${merge_msg}\""
    else
        log "🌿 Commit direto na branch '${REPO_BRANCH}' (sem merge intermediário)"
    fi

    git checkout -q "$found_commit"
    resolved_ref="commit-by-version:${found_commit:0:12}(${found_version})[${found_source}]"
else
    log_error "❌ Versão '${APP_VERSION}' não encontrada nos títulos de commits nem em '${VERSION_PROPERTIES_PATH}' da branch '${REPO_BRANCH}'."

    # -------------------------------------------------------------------
    # Sugestão: versão mais próxima (anterior e posterior) encontrada
    # -------------------------------------------------------------------
    if [[ "${#all_versions_raw[@]}" -gt 0 ]]; then
        desired_int="$(version_to_int "$APP_VERSION")"
        best_lower=""
        best_lower_int=0
        best_upper=""
        best_upper_int=""

        for v in "${all_versions_raw[@]}"; do
            v_int="$(version_to_int "$v")"
            if [[ "$v_int" -le "$desired_int" ]]; then
                if [[ "$v_int" -gt "$best_lower_int" ]]; then
                    best_lower_int="$v_int"
                    best_lower="$v"
                fi
            else
                if [[ -z "$best_upper_int" || "$v_int" -lt "$best_upper_int" ]]; then
                    best_upper_int="$v_int"
                    best_upper="$v"
                fi
            fi
        done

        log_error "💡 Versões disponíveis nos commits da branch '${REPO_BRANCH}':"
        if [[ -n "$best_lower" ]]; then
            lower_commit="$(printf '%s\n' "${all_commits[@]}" | grep -E "(v\.?)?${best_lower//./\\.}" | head -1 | awk '{print $1}')"
            log_error "   ✅ Versão imediatamente ANTERIOR : ${best_lower}  (commit ${lower_commit:0:12})"
        fi
        if [[ -n "$best_upper" ]]; then
            upper_commit="$(printf '%s\n' "${all_commits[@]}" | grep -E "(v\.?)?${best_upper//./\\.}" | head -1 | awk '{print $1}')"
            log_error "   ⬆️  Versão imediatamente POSTERIOR: ${best_upper}  (commit ${upper_commit:0:12})"
        fi
        if [[ -z "$best_lower" && -z "$best_upper" ]]; then
            log_error "   Nenhuma versão no formato N.N.N.N-N encontrada nos commits."
        fi
    else
        log_error "💡 Nenhuma versão no formato N.N.N.N-N encontrada nos títulos de commits da branch '${REPO_BRANCH}'."
    fi

    popd >/dev/null
    exit 1
fi

log_success "Ref da aplicação resolvida: ${resolved_ref}"

JAVA_HOME_17=""
for candidate in "/usr/lib/jvm/java-17-openjdk-amd64" "/usr/lib/jvm/java-17-openjdk" "/usr/lib/jvm/temurin-17" "/usr/local/lib/jvm/java-17"; do
    if [[ -d "$candidate" ]]; then
        JAVA_HOME_17="$candidate"
        break
    fi
done

if [[ -n "$JAVA_HOME_17" ]]; then
    log "☁️ Forçando JAVA_HOME para Java 17: $JAVA_HOME_17"
    export JAVA_HOME="$JAVA_HOME_17"
    export PATH="$JAVA_HOME/bin:$PATH"
else
    log_warning "Java 17 não encontrado nos caminhos padrão; usando JAVA_HOME atual: ${JAVA_HOME:-não definido}"
fi

if [[ -x "./mvnw" ]]; then
    log "🔨 Build com Maven Wrapper"
    ./mvnw -DskipTests package
    build_ok=true
elif [[ -f "pom.xml" ]]; then
    if command -v mvn >/dev/null 2>&1; then
        log "🔨 Build com Maven"
        mvn -DskipTests package
        build_ok=true
    else
        log_warning "Maven não encontrado no agente."
    fi
elif [[ -x "./gradlew" ]]; then
    log "🔨 Build com Gradle Wrapper"
    ./gradlew clean bootWar war -x test || ./gradlew clean war -x test
    build_ok=true
elif [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
    if command -v gradle >/dev/null 2>&1; then
        log "🔨 Build com Gradle"
        gradle clean bootWar war -x test || gradle clean war -x test
        build_ok=true
    else
        log_warning "Gradle não encontrado no agente."
    fi
fi

if [[ "$build_ok" != "true" ]]; then
    log_warning "Nenhuma ferramenta de build encontrada. Tentando localizar WAR pré-gerado."
fi

mapfile -t war_candidates < <(
    find "$REPO_DIR" -type f -name "*.war" \
        ! -name "*sources*.war" \
        ! -name "*javadoc*.war" \
        -print | sort
)

if [[ "${#war_candidates[@]}" -eq 0 ]]; then
    log_error "Nenhum arquivo WAR encontrado após clone/build."
    popd >/dev/null
    exit 1
fi

selected_war="${war_candidates[0]}"
if [[ "${#war_candidates[@]}" -gt 1 ]]; then
    selected_war="$(ls -t "${war_candidates[@]}" | head -n1)"
fi

mkdir -p "$(dirname "$OUTPUT_WAR")"
cp "$selected_war" "$OUTPUT_WAR"
popd >/dev/null

log_success "WAR preparado com sucesso: $OUTPUT_WAR"
