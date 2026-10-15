# SPEC — Descoberta automática de dados da origem e seleção dinâmica do Tomcat destino

Status: **implementado** (não executado em Jenkins; validado apenas sintaxe Groovy/bash e a lógica de parsing localmente).

Desvios em relação ao rascunho: a senha do sudo e a do banco são enviadas ao bastion como arquivos temporários (`--sudo-password-file`, `--db-password-file`, removidos ao final) em vez de argumento; o `input` roda com o `agent any` do pipeline, ou seja, segura o executor durante a espera (limitado a 15 min).

## 1. Objetivo

Reduzir os parâmetros manuais do pipeline, fazendo-o descobrir sozinho:

| Hoje (parâmetro manual) | Depois |
|---|---|
| `SOURCE_VERSAO_BANCO` | Query no banco de origem |
| `SOURCE_TOMCAT_VOLUME` | Consulta ao `listarVersoes*.sh` no servidor de origem |
| `SOURCE_VERSAO_APP` | `curl` na página de login da aplicação de origem |
| `DESTINO_TOMCAT_VOLUME` (texto livre) | Lista consultada no servidor destino + `input` interativo durante o build |

## 2. Situação atual (relevante)

- Os 4 parâmetros acima são definidos em [Jenkinsfile:52-113](Jenkinsfile#L52-L113) e [Jenkinsfile:200-205](Jenkinsfile#L200-L205).
- `SOURCE_TOMCAT_VOLUME` e `SOURCE_VERSAO_APP` hoje são **apenas exibidos em `echo`** ([Jenkinsfile:262](Jenkinsfile#L262)); nenhum script os consome. Portanto a descoberta deles é informativa (log/descrição do build), sem risco de regressão.
- `SOURCE_VERSAO_BANCO` é consumida em 3 lugares: validação de formato/comparação com o destino ([Jenkinsfile:280-315](Jenkinsfile#L280-L315)), `--source-versao-banco` do `copy_database.sh` ([Jenkinsfile:578](Jenkinsfile#L578)), e filtro de updates dentro do `copy_database.sh`.
- `DESTINO_TOMCAT_VOLUME` é consumido por `deploy_application.sh` e `verify_deployment.sh` (via `--tomcat-volume`) e validado como obrigatório no stage 1.
- A validação de parâmetros roda **dentro do stage 1**, antes de qualquer acesso a rede; a descoberta exige acesso (bastion/SSH/DB), então precisa de um stage novo e a validação de versões deve ser movida para depois dele.

## 3. Mudanças nos parâmetros

### Removidos
- `SOURCE_VERSAO_BANCO`
- `SOURCE_TOMCAT_VOLUME`
- `SOURCE_VERSAO_APP`
- `DESTINO_TOMCAT_VOLUME`

### Adicionados (ver pontos em aberto na seção 8)
- `SOURCE_APP_URL` (string) — URL da aplicação de origem (com ou sem `/login.xhtml`), ex.: `https://routing.pathfindsistema.com.br/pathfind_dbk_rp/login.xhtml`. Necessária para o `curl` e para derivar o nome da aplicação de origem.
- `SOURCE_APP_NAME` (string, opcional) — nome da aplicação de origem no Tomcat (ex.: `planner_lubpar_rj`). Se vazio, é derivado do path da `SOURCE_APP_URL`.

### Mantidos sem alteração
Todo o restante (`TIPO_AMBIENTE`, `SOURCE_SERVIDOR`, `SOURCE_NOME_BANCO`, `SOURCE_DEPLOY_TARGET`, `DESTINO_*`, `CRIAR_BANCO`, `DEPLOY_APP`, parâmetros de repositório).

## 4. Novo fluxo de stages

```
1. 🔍 Validação de Parâmetros     (só validações estáticas + resolução de hosts)
2. 📁 Preparação do Ambiente
3. 🔎 Descoberta da Origem         [NOVO]  versão do banco, tomcat, versão da app
4. ✔️  Validação de Versões        [NOVO]  compara origem × destino (movido do stage 1)
5. 🎯 Seleção do Tomcat Destino    [NOVO]  lista + input interativo (só se DEPLOY_APP)
6. 🔄 Sincronização de Migrations
7. 🗄️ Cópia do Banco de Dados
8. 🚀 Deploy da Aplicação
9. ✅ Verificação Final
```

> Decisão: o Tomcat é perguntado logo após a descoberta/validação, para o usuário responder no início e deixar o build rodar sozinho. Como o `input` fica antes de qualquer trabalho pesado, uma versão destino inválida já falha antes de perguntar.

## 5. Detalhamento

### 5.1 Stage "Descoberta da Origem" — novo script `scripts/discover_source.sh`

Executado no bastion (mesmo padrão ssh-agent + scp dos demais stages), saída em `key=value` num arquivo que o Jenkinsfile lê de volta (ou via stdout com marcadores). Parâmetros nomeados, `set -euo pipefail`, `source log_utils.sh`, senhas nunca logadas.

**a) Versão do banco** (somente se `CRIAR_BANCO=true`)

```bash
# PTF
psql -h $SOURCE_DB_HOST -U $USER -d $SOURCE_NOME_BANCO -tA \
  -c "select valor_texto from configuracao where nomecampo = 'versao_banco'"
# PLN
psql ... -tA -c "select versao from versaobanco order by id desc limit 1"
```

- Reutiliza a resolução de credenciais da origem já existente ([Jenkinsfile:494-511](Jenkinsfile#L494-L511)) — será extraída para um helper em Groovy, pois passará a ser usada em dois stages.
- Resultado passa por `extract_version_token` (regex `N.N.N.N-N`). Vazio, múltiplas linhas ou formato inválido ⇒ **falha o build** com mensagem clara (a versão é o que define quais updates rodam; não vale chutar).

**b) Tomcat da origem** (informativo)

Executado via SSH em `infra@<SOURCE_DEPLOY_SERVER_IP>` (mesma chave `ssh-credentials` usada no deploy), **com sudo** (senha da credential `infra-sudo-pswd`, enviada por stdin/arquivo temporário como o deploy já faz, nunca em argumento nem em log):

```bash
sudo /opt/scripts/listarVersoes{Planner|Roteirizador}.sh
```

Em vez de `| grep nome_app` puro, filtrar **pela segunda coluna com igualdade exata**, porque `grep planner_lubpar_rj` também casaria `planner_lubpar_rj2`, `planner_lubpar_rj_teste` etc.:

```bash
... | awk -F'|' -v app="$SOURCE_APP_NAME" \
      '{gsub(/ /,"",$1); gsub(/ /,"",$2)} $2==app {print $1; exit}'
```

- PLN → `listarVersoesPlanner.sh`; PTF → `listarVersoesRoteirizador.sh` (mesmo formato de saída: `tomcat | app | versão`, confirmado).
- Não encontrado ⇒ **warning** (não falha, pois o dado é só informativo).

> Confirmado: a busca roda no servidor de **origem** (`SOURCE_DEPLOY_TARGET`).

**c) Versão da aplicação de origem** (informativo)

```bash
# PTF
curl -s -L --max-time 15 "$SOURCE_APP_URL" | grep -oP "Pathfind v\.\K[0-9.-]+" | head -n1
# PLN
curl -s -L --max-time 15 "$SOURCE_APP_URL" | grep -oP "Planner v\.\K[0-9.-]+" | head -n1
```

- Roda no próprio agente Jenkins (URL pública), sem necessidade de bastion. Se o agente não alcançar, fallback para rodar via bastion.
- Falha/vazio ⇒ **warning**, `SOURCE_VERSAO_APP = "desconhecida"`.

**Normalização da URL:** a `SOURCE_APP_URL` pode vir com ou sem `/login.xhtml` (ou com barra final, query string, outra página da app). O script extrai `esquema://host/<primeiro-segmento>` e sempre monta `<base>/login.xhtml` antes do `curl`. Sem esquema, assume `https://`. Isso garante um único formato de consulta e o mesmo segmento usado para derivar `SOURCE_APP_NAME`. URL sem segmento de path (só o host) ⇒ erro claro pedindo `SOURCE_APP_NAME` ou a URL completa da aplicação. O `curl` segue redirects (`-L`).

**Saída:** `env.SOURCE_VERSAO_BANCO_CLEAN`, `env.SOURCE_TOMCAT_VOLUME_DISCOVERED`, `env.SOURCE_VERSAO_APP_DISCOVERED`; resumo no `currentBuild.description`.

### 5.2 Stage "Validação de Versões"

Move para cá o bloco de [Jenkinsfile:285-315](Jenkinsfile#L285-L315) (formato + `DESTINO ≥ ORIGEM`), agora comparando com a versão descoberta. Em caso de falha, o erro deve citar a versão descoberta (ex.: `DESTINO_VERSAO_BANCO (15.12.0.0-1) é menor que a versão do banco origem descoberta (15.13.1.0-27)`).

### 5.3 Stage "Seleção do Tomcat Destino" (só se `DEPLOY_APP=true`)

1. **Listar** via SSH em `infra@<DESTINO_DEPLOY_SERVER_IP>` (com `sudo`, igual à seção 5.1b):
   - PLN: `sudo /opt/scripts/listarVersoesPlanner.sh | cut -d "|" -f1 | awk '!seen[$0]++'`
   - PTF: `sudo /opt/scripts/listarVersoesRoteirizador.sh | cut -d "|" -f1 | awk '!seen[$0]++'`
   - Aplicar `trim` em cada linha (a saída de exemplo tem espaço no fim) e descartar vazias.
   - Lista vazia ou falha de SSH ⇒ falha o build (sem Tomcat não há deploy).
2. **Perguntar** com `input` (fora de bloco `node`/`agent` para não segurar executor):
   ```groovy
   def escolha = input(
       message: 'Em qual Tomcat deseja fazer o deploy do ambiente cópia?',
       ok: 'Confirmar',
       parameters: [choice(name: 'TOMCAT', choices: tomcats.join('\n'),
                           description: "Tomcats em ${DESTINO_DEPLOY_SERVER_NAME}")]
   )
   ```
   - Com `timeout(time: 15, unit: 'MINUTES')` — expirou ⇒ aborta o build (não assume default).
   - Se só existir 1 opção, ainda assim perguntar (evita deploy "automático" em Tomcat errado).
3. Gravar `env.DESTINO_TOMCAT_VOLUME = escolha` e substituir `params.DESTINO_TOMCAT_VOLUME` nos usos de [Jenkinsfile:700](Jenkinsfile#L700) e [Jenkinsfile:791](Jenkinsfile#L791).
4. A validação de "obrigatório" em [Jenkinsfile:372-374](Jenkinsfile#L372-L374) é removida.

### 5.4 Reutilização de SSH

Hoje o SSH para o servidor de deploy é feito de dentro do `deploy_application.sh` (bastion → `infra@IP`, com `.deploy_ssh_key` e `-A`). Para listar/descobrir, será criado `scripts/list_tomcats.sh` (parâmetros: `--tipo-ambiente`, `--deploy-server-ip`, `--ssh-key-file`, `--sudo-password`, `--app-name` opcional) reutilizado pelos stages 3 (item b) e 5, para não duplicar o mesmo bloco SSH.

## 6. Arquivos afetados

| Arquivo | Mudança |
|---|---|
| `Jenkinsfile` | Remove 4 params, adiciona 2, novos stages 3/4/5, helper de credenciais, usa `env.DESTINO_TOMCAT_VOLUME` |
| `scripts/discover_source.sh` | **novo** — versão do banco + versão da app |
| `scripts/list_tomcats.sh` | **novo** — lista/localiza Tomcat via SSH |
| `scripts/copy_database.sh` | Sem mudança de interface (continua recebendo `--source-versao-banco`) |
| `scripts/deploy_application.sh`, `verify_deployment.sh` | Sem mudança |
| `AGENTS.md`, `README.md` | Atualizar tabela de parâmetros, fluxo de stages e checklist |

## 7. Tratamento de erros (resumo)

| Situação | Comportamento |
|---|---|
| Versão do banco origem não obtida / inválida | **Falha** |
| Versão destino < versão origem descoberta | **Falha** |
| Tomcat da origem não encontrado | Warning |
| `curl` da versão da app falha / sem match | Warning |
| Lista de Tomcats destino vazia / SSH falha | **Falha** |
| Usuário não responde ao `input` em 15 min | Aborta |
| `CRIAR_BANCO=false` | Pula descoberta de versão do banco e validação de versões |
| `DEPLOY_APP=false` | Pula descoberta de tomcat/app e seleção do Tomcat destino |

## 8. Decisões tomadas

1. Busca do Tomcat/app de origem roda no servidor de **origem**.
2. Dois params novos: `SOURCE_APP_URL` e `SOURCE_APP_NAME` (opcional; derivado do path da URL se vazio).
3. Tomcat destino é perguntado logo após a descoberta e validação de versões.
4. Regex da versão da app: `Pathfind v.` (PTF) e `Planner v.` (PLN).
5. `listarVersoesRoteirizador.sh` tem o mesmo formato do planner e exige `sudo`.
6. Pergunta sempre, mesmo com um único Tomcat.

7. O nome da aplicação de origem é derivado do **primeiro segmento do path** da `SOURCE_APP_URL` nos dois tipos (PTF: `/pathfind_dbk_rp/login.xhtml` → `pathfind_dbk_rp`; PLN: `/planner_nome_cliente/...` → `planner_nome_cliente`). `SOURCE_APP_NAME` só serve para sobrescrever esse valor.

## 9. Fora de escopo (observação)

O Jenkinsfile contém senhas de banco em texto claro ([Jenkinsfile:342-346](Jenkinsfile#L342-L346)). Não faz parte desta mudança, mas vale migrar para credentials do Jenkins em outra oportunidade.

## 10. Plano de implementação (após aprovação)

1. Criar `list_tomcats.sh` e `discover_source.sh` (testáveis isoladamente via bastion).
2. Ajustar parâmetros e reorganizar stage 1 → stages 3/4.
3. Implementar stage de seleção do Tomcat e trocar os usos de `DESTINO_TOMCAT_VOLUME`.
4. Atualizar `AGENTS.md`/`README.md`.
5. Teste: execução com `CRIAR_BANCO=true/false` × `DEPLOY_APP=true/false`, uma origem PTF e uma PLN; caso de erro (app inexistente, versão destino menor).
