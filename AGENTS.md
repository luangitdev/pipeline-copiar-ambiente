# pipelineCopiarAmbiente — Agent Instructions

Pipeline Jenkins para **copiar/duplicar ambientes existentes** dos produtos **PTF** (PathFind) e **PLN** (Planner).

Baseado em [`pipelineCriarAmbiente`](../pipelineCriarAmbiente/), compartilhando infraestrutura (servidores, credenciais, bastion) mas com objetivo diferente: **origem é um banco já populado**, não um template limpo.

## Estrutura do Projeto

```
Jenkinsfile               # Pipeline principal — único ponto de entrada
config/environments.yaml  # Metadados de servidores (copiado de pipelineCriarAmbiente)
scripts/                  # Scripts bash executados via bastion
sql/{ptf,pln}/            # SQLs de configuração + migrations em updates/
```

## Fluxo de Execução

```
Jenkins → Bastion (SSH_PRIVATE_KEY)
   ├── Origem: dump do banco existente + localização do WAR
   └── Destino: restore do dump + updates + deploy da aplicação
```

## Stages do Jenkinsfile

1. **Validação de Parâmetros** — resolve hosts origem/destino, valida parâmetros estáticos
2. **Preparação do Ambiente** — cria `temp/` e diretórios de trabalho
3. **Descoberta da Origem** — `scripts/discover_source.sh` + `scripts/list_tomcats.sh`:
   - versão do banco origem (PTF: `configuracao.versao_banco`; PLN: `versaobanco` mais recente)
   - nome/versão da aplicação origem (`curl` em `<SOURCE_APP_URL>/login.xhtml`; `Pathfind v.` no PTF, `Planner v.` no PLN)
   - Tomcat onde a app origem roda (`listarVersoes{Planner|Roteirizador}.sh` via SSH + sudo; apenas informativo)
4. **Validação de Versões** — `DESTINO_VERSAO_BANCO` ≥ versão descoberta da origem
5. **Seleção do Tomcat Destino** — lista os Tomcats do servidor destino e pergunta ao usuário (`input`, timeout 15 min); só com `DEPLOY_APP=true`
6. **Sincronização de Migrations** — clona repo de infraestrutura (se necessário)
7. **Cópia do Banco de Dados** — executa via bastion: `scripts/copy_database.sh`
   - `pg_dump` do banco origem
   - `CREATE DATABASE` + restore no destino
   - Aplica updates da **versão origem → versão destino**
   - Executa config SQL (config-qa.sql, config-imp.sql, config-prod.sql, etc.)
   - Executa credentials.sql
8. **Deploy da Aplicação** — reutiliza `build_app_artifact.sh` + `deploy_application.sh`
9. **Verificação Final** — `verify_database.sh` + `verify_deployment.sh`

## Parâmetros (divididos em origem e destino)

### Origem (Source)

| Parâmetro | Descrição |
|---|---|
| `SOURCE_SERVIDOR` | Servidor de banco de dados onde o banco origem reside |
| `SOURCE_NOME_BANCO` | Nome do banco de dados existente |
| `SOURCE_DEPLOY_TARGET` | Servidor deploy + Tomcat onde a app origem rola (formato NOME:IP) |
| `SOURCE_APP_URL` | URL da aplicação origem, com ou sem `/login.xhtml` (obrigatória com `DEPLOY_APP=true`). O primeiro segmento do path é o nome da aplicação |
| `SOURCE_APP_NAME` | Opcional. Sobrescreve o nome da aplicação derivado da URL |

> Descobertos automaticamente (não são mais parâmetros): versão do banco origem, Tomcat origem e versão da aplicação origem.

### Destino (Destination)

| Parâmetro | Descrição |
|---|---|
| `DESTINO_SERVIDOR` | Servidor de banco de dados onde criar o novo banco |
| `DESTINO_NOME_BANCO` | Nome do novo banco |
| `DESTINO_VERSAO_BANCO` | Versão desejada para o banco destino (≥ source) |
| `DESTINO_DEPLOY_TARGET` | Servidor deploy + Tomcat destino (formato NOME:IP) |
| `DESTINO_APP_NAME` | Nome da aplicação no Tomcat destino |
| `DESTINO_VERSAO_APP` | Versão/ref desejada da aplicação |
| `TIPO_AMBIENTE` | PTF ou PLN |

### Comportamento de Aplicação

- **`DEPLOY_NOVO=true`** (padrão/recomendado): Compila a aplicação do repo com `build_app_artifact.sh` e faz deploy com `deploy_application.sh`. Garante que `login.properties` aponte para o banco destino.
- **`COPIAR_WAR=true`** (futuro/não implementado): Copia o WAR do servidor origem. Requer extração, patch de `login.properties`, e repack. Mais rápido mas mais frágil.

> **Nota:** Nesta versão do pipeline, o deploy da aplicação é sempre feito via build do repositório (reutilizando o mesmo mecanismo do pipeline de criação). Isso evita problemas de `login.properties` apontando para o banco errado.

## Reutilização do Pipeline de Criação

Este pipeline **reutiliza** os seguintes arquivos de `pipelineCriarAmbiente`:

- `config/environments.yaml` — mesmos servidores
- `scripts/get_db_host.sh` — mesma resolução de host
- `scripts/log_utils.sh` — mesmos utilitários de log
- `scripts/generate_start_sql.sh` — geração de start.sql
- `scripts/fetch_updates.sh` — sincronização de updates SQL
- `scripts/build_app_artifact.sh` — build do WAR
- `scripts/deploy_application.sh` — deploy no Tomcat
- `scripts/verify_database.sh` / `scripts/verify_deployment.sh` — verificações
- `sql/` e `dados/` — mesma estrutura de SQLs

## Particularidades da Cópia de Banco

### Versão de updates

O pipeline aplica **apenas** updates cuja versão está estritamente entre:
- versão do banco origem descoberta pelo pipeline (exclusivo)
- `DESTINO_VERSAO_BANCO` (inclusivo)

Isso é idêntico ao filtro de updates do pipeline de criação, mas com `VERSAO_BASE_INICIAL` = versão do banco origem descoberta.

### Multibanco

Não suportado na cópia (a base origem já possui sua estrutura de multibanco, se houver). Se necessário no futuro, pode ser adicionado.

## Checklist de Uso

- [ ] O banco origem está acessível via bastion usando as credenciais padrão do servidor
- [ ] O destino tem espaço suficiente para o dump (temporário em `/tmp/`)
- [ ] A versão destino do banco é **≥** a versão origem
- [ ] O servidor destino não possui um banco com o mesmo nome (`DESTINO_NOME_BANCO`)
- [ ] Se `DEPLOY_APP=true`, o `DESTINO_DEPLOY_TARGET`, `DESTINO_APP_NAME` e `SOURCE_APP_URL` estão corretos (o Tomcat destino é escolhido durante a execução)

## Convenções de Código

- Scripts bash usam `set -euo pipefail` e `source log_utils.sh` obrigatoriamente.
- Funções de log: `log`, `log_success`, `log_warning`, `log_error`.
- Parâmetros em scripts são sempre nomeados (`--param valor`), nunca posicionais.
- Senhas e dados sensíveis **nunca** são logados; use `[MASKED]` em mensagens de debug.
- Aliases de servidor são sempre **minúsculos** em scripts; o Jenkinsfile faz `.toLowerCase()` antes de passar.
