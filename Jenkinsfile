pipeline {
    agent any

    environment {
        PIPELINE_HOME = "${WORKSPACE}"
        SCRIPTS_PATH = "${WORKSPACE}/scripts"
        CONFIG_PATH = "${WORKSPACE}/config"
        SQL_PATH = "${WORKSPACE}/sql"
        TEMPLATES_PATH = "${WORKSPACE}/templates"
        DB_PORT = '5432'
        LOG_LEVEL = 'INFO'
    }

    stages {
        stage('🔍 Validação de Parâmetros') {
            steps {
                script {
                    properties([parameters([

                        // ==================== GERAL ====================
                        [$class: 'ChoiceParameterDefinition',
                            name: 'TIPO_AMBIENTE',
                            choices: 'PTF\nPLN',
                            description: 'Tipo do ambiente (PTF ou PLN)'
                        ],

                        // ==================== ORIGEM (SOURCE) ====================
                        [$class: 'CascadeChoiceParameter',
                            choiceType: 'PT_SINGLE_SELECT',
                            description: 'Servidor de banco de dados ORIGEM (onde o banco já existe)',
                            filterable: false,
                            name: 'SOURCE_SERVIDOR',
                            referencedParameters: 'TIPO_AMBIENTE',
                            script: [
                                $class: 'GroovyScript',
                                fallbackScript: [classpath: [], sandbox: true, script: 'return ["GCP01"]'],
                                script: [classpath: [], sandbox: true, script: '''
                                    if (TIPO_AMBIENTE == "PLN") {
                                        return ["GCP-PLN", "OCI-DB-QA"]
                                    } else {
                                        return ["GCP01", "GCP02", "GCP03", "OCI-DB-IMP", "OCI-DB-QA", "OCI-DB-02"]
                                    }
                                ''']
                            ]
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'SOURCE_NOME_BANCO',
                            defaultValue: '',
                            description: 'Nome do banco de dados existente no servidor origem',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'SOURCE_VERSAO_BANCO',
                            defaultValue: '',
                            description: 'Versão atual do banco origem (ex: 15.13.1.0-27 | 9.0.1.1-14)',
                            trim: true
                        ],
                        [$class: 'CascadeChoiceParameter',
                            choiceType: 'PT_SINGLE_SELECT',
                            description: 'Servidor de deploy ORIGEM (formato NOME:IP)',
                            filterable: false,
                            name: 'SOURCE_DEPLOY_TARGET',
                            referencedParameters: 'TIPO_AMBIENTE',
                            script: [
                                $class: 'GroovyScript',
                                fallbackScript: [classpath: [], sandbox: true, script: 'return ["N/A"]'],
                                script: [classpath: [], sandbox: true, script: '''
                                    if (TIPO_AMBIENTE == "PLN") {
                                        return [
                                            "OCI-PLN-QA:164.152.198.41",
                                            "PROD-02:34.151.209.238",
                                            "PROD-03:35.199.116.136",
                                            "PROD-04:35.198.30.206",
                                            "PROD-05:34.95.136.178",
                                            "PROD-06:34.95.143.104",
                                            "PROD-07:34.95.181.155"
                                        ]
                                    } else {
                                        return [
                                            "OCI-PTF-QA:134.65.30.12",
                                            "OCI-PTF-PROD-01:167.126.9.6",
                                            "OCI-IMP-01:157.151.5.126",
                                            "IMP-01:34.95.251.169",
                                            "PROD-01:35.247.243.102",
                                            "PROD-02:35.199.97.30",
                                            "PROD-03:34.95.176.6",
                                            "PROD-04:34.151.235.67",
                                            "PROD-05:35.247.231.213",
                                            "PROD-06:34.151.245.19",
                                            "PROD-07:35.199.65.37",
                                            "PROD-08:35.199.103.167",
                                            "PROD-09:35.199.120.245",
                                            "PROD-10:34.95.167.115",
                                            "PROD-11:34.39.155.140",
                                            "COM-01:34.151.239.130"
                                        ]
                                    }
                                ''']
                            ]
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'SOURCE_TOMCAT_VOLUME',
                            defaultValue: '',
                            description: 'Nome do volume Docker do Tomcat na origem (ex: ptf-routing_tomcat-v15_8081)',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'SOURCE_VERSAO_APP',
                            defaultValue: '',
                            description: 'Versão/ref atual da aplicação na origem',
                            trim: true
                        ],

                        // ==================== DESTINO (DESTINATION) ====================
                        [$class: 'BooleanParameterDefinition',
                            name: 'CRIAR_BANCO',
                            defaultValue: true,
                            description: 'Executar cópia do banco de dados'
                        ],
                        [$class: 'CascadeChoiceParameter',
                            choiceType: 'PT_SINGLE_SELECT',
                            description: 'Servidor de banco de dados DESTINO (onde criar o novo banco)',
                            filterable: false,
                            name: 'DESTINO_SERVIDOR',
                            referencedParameters: 'TIPO_AMBIENTE',
                            script: [
                                $class: 'GroovyScript',
                                fallbackScript: [classpath: [], sandbox: true, script: 'return ["GCP01"]'],
                                script: [classpath: [], sandbox: true, script: '''
                                    if (TIPO_AMBIENTE == "PLN") {
                                        return ["GCP-PLN", "OCI-DB-QA"]
                                    } else {
                                        return ["GCP01", "GCP02", "GCP03", "OCI-DB-IMP", "OCI-DB-QA", "OCI-DB-02"]
                                    }
                                ''']
                            ]
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'DESTINO_NOME_BANCO',
                            defaultValue: '',
                            description: 'Nome do novo banco de dados a ser criado no destino',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'DESTINO_VERSAO_BANCO',
                            defaultValue: '',
                            description: 'Versão desejada do banco destino (ex: PTF → 15.13.1.0-1 | PLN → 9.0.1.1-14)',
                            trim: true
                        ],

                        [$class: 'BooleanParameterDefinition',
                            name: 'DEPLOY_APP',
                            defaultValue: true,
                            description: 'Executar deploy da aplicação no destino (build do repo + deploy)'
                        ],
                        [$class: 'CascadeChoiceParameter',
                            choiceType: 'PT_SINGLE_SELECT',
                            description: 'Servidor de deploy DESTINO (formato NOME:IP)',
                            filterable: false,
                            name: 'DESTINO_DEPLOY_TARGET',
                            referencedParameters: 'TIPO_AMBIENTE',
                            script: [
                                $class: 'GroovyScript',
                                fallbackScript: [classpath: [], sandbox: true, script: 'return ["N/A"]'],
                                script: [classpath: [], sandbox: true, script: '''
                                    if (TIPO_AMBIENTE == "PLN") {
                                        return [
                                            "OCI-PLN-QA:164.152.198.41",
                                            "PROD-02:34.151.209.238",
                                            "PROD-03:35.199.116.136",
                                            "PROD-04:35.198.30.206",
                                            "PROD-05:34.95.136.178",
                                            "PROD-06:34.95.143.104",
                                            "PROD-07:34.95.181.155"
                                        ]
                                    } else {
                                        return [
                                            "OCI-PTF-QA:134.65.30.12",
                                            "OCI-PTF-PROD-01:167.126.9.6",
                                            "OCI-IMP-01:157.151.5.126",
                                            "IMP-01:34.95.251.169",
                                            "PROD-01:35.247.243.102",
                                            "PROD-02:35.199.97.30",
                                            "PROD-03:34.95.176.6",
                                            "PROD-04:34.151.235.67",
                                            "PROD-05:35.247.231.213",
                                            "PROD-06:34.151.245.19",
                                            "PROD-07:35.199.65.37",
                                            "PROD-08:35.199.103.167",
                                            "PROD-09:35.199.120.245",
                                            "PROD-10:34.95.167.115",
                                            "PROD-11:34.39.155.140",
                                            "COM-01:34.151.239.130"
                                        ]
                                    }
                                ''']
                            ]
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'DESTINO_TOMCAT_VOLUME',
                            defaultValue: '',
                            description: 'Nome do volume Docker do Tomcat no destino (ex: ptf-routing_tomcat-v15_8081)',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'DESTINO_APP_NAME',
                            defaultValue: 'pathfind_',
                            description: 'Nome final da aplicação no Tomcat destino',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'DESTINO_VERSAO_APP',
                            defaultValue: '',
                            description: 'Versão/ref desejada da aplicação destino. Se vazio, usa DESTINO_VERSAO_BANCO',
                            trim: true
                        ],

                        // ==================== INFRA / REPO ====================
                        [$class: 'BooleanParameterDefinition',
                            name: 'SINCRONIZAR_UPDATES_INFRA',
                            defaultValue: true,
                            description: 'Buscar updates SQL no repositório de infraestrutura (Azure DevOps)'
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'INFRA_REPO_URL',
                            defaultValue: 'https://MobiisLogistica@dev.azure.com/MobiisLogistica/Roteirizador/_git/infraestrutura',
                            description: 'URL do repositório de infraestrutura que contém as migrations',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'INFRA_REPO_BRANCH',
                            defaultValue: 'master',
                            description: 'Branch do repositório de infraestrutura',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'INFRA_REPO_CREDENTIALS_ID',
                            defaultValue: 'azure-credentials-luan',
                            description: 'Credentials ID para acessar o repositório de infraestrutura',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'APP_REPO_BRANCH',
                            defaultValue: '',
                            description: 'Branch do repositório da aplicação (ex: PTF → mvp | PLN → v8). Se vazio, usa o padrão.',
                            trim: true
                        ],
                        [$class: 'StringParameterDefinition',
                            name: 'APP_REPO_URL_OVERRIDE',
                            defaultValue: '',
                            description: 'Override técnico opcional da URL do repositório da aplicação',
                            trim: true
                        ]

                    ])])

                    echo "🚀 ===== PIPELINE COPIAR AMBIENTE ====="
                    echo "📋 Parâmetros recebidos:"
                    echo "   - Tipo Ambiente: ${params.TIPO_AMBIENTE}"
                    echo "   - Origem DB: ${params.SOURCE_SERVIDOR} / ${params.SOURCE_NOME_BANCO}"
                    echo "   - Origem App: ${params.SOURCE_DEPLOY_TARGET} / ${params.SOURCE_TOMCAT_VOLUME}"
                    echo "   - Destino DB: ${params.DESTINO_SERVIDOR} / ${params.DESTINO_NOME_BANCO}"
                    echo "   - Destino App: ${params.DESTINO_DEPLOY_TARGET} / ${params.DESTINO_TOMCAT_VOLUME}"
                    echo "   - Criar Banco: ${params.CRIAR_BANCO}"
                    echo "   - Deploy App: ${params.DEPLOY_APP}"
                    echo "======================================="

                    // Validações básicas
                    if (!params.SOURCE_NOME_BANCO || params.SOURCE_NOME_BANCO.trim() == '') {
                        error("❌ Nome do banco de origem é obrigatório!")
                    }
                    if (!params.DESTINO_NOME_BANCO || params.DESTINO_NOME_BANCO.trim() == '') {
                        error("❌ Nome do banco de destino é obrigatório!")
                    }
                    if (params.SOURCE_NOME_BANCO.trim() == params.DESTINO_NOME_BANCO.trim()) {
                        error("❌ Nome do banco origem e destino não podem ser iguais!")
                    }

                    def sourceVersaoBanco = params.SOURCE_VERSAO_BANCO?.trim()?.replaceAll('[,;\\s]', '')
                    def destinoVersaoBanco = params.DESTINO_VERSAO_BANCO?.trim()?.replaceAll('[,;\\s]', '')
                    env.SOURCE_VERSAO_BANCO_CLEAN = sourceVersaoBanco
                    env.DESTINO_VERSAO_BANCO_CLEAN = destinoVersaoBanco

                    if (params.CRIAR_BANCO && (!sourceVersaoBanco || !destinoVersaoBanco)) {
                        error("❌ SOURCE_VERSAO_BANCO e DESTINO_VERSAO_BANCO são obrigatórios quando CRIAR_BANCO=true.")
                    }

                    if (params.CRIAR_BANCO) {
                        def compareVersions = { String v ->
                            def matcher = (v =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)-(\d+)$/)
                            if (!matcher.matches()) {
                                error("❌ Versão de banco inválida: '${v}'. Use N.N.N.N-N.")
                            }
                            return [
                                matcher[0][1].toInteger(),
                                matcher[0][2].toInteger(),
                                matcher[0][3].toInteger(),
                                matcher[0][4].toInteger(),
                                matcher[0][5].toInteger()
                            ]
                        }
                        def isLowerThan = { left, right ->
                            for (int i = 0; i < left.size(); i++) {
                                if (left[i] < right[i]) return true
                                if (left[i] > right[i]) return false
                            }
                            return false
                        }
                        def srcTokens = compareVersions(sourceVersaoBanco)
                        def dstTokens = compareVersions(destinoVersaoBanco)
                        if (isLowerThan(dstTokens, srcTokens)) {
                            error("❌ DESTINO_VERSAO_BANCO (${destinoVersaoBanco}) não pode ser menor que SOURCE_VERSAO_BANCO (${sourceVersaoBanco}).")
                        }
                    }

                    def destinoVersaoAppParam = params.DESTINO_VERSAO_APP?.trim()

                    currentBuild.displayName = "#${BUILD_NUMBER} - ${params.DESTINO_NOME_BANCO}"
                    currentBuild.description = "Origem: ${params.SOURCE_SERVIDOR}/${params.SOURCE_NOME_BANCO} → Destino: ${params.DESTINO_SERVIDOR}/${params.DESTINO_NOME_BANCO}"

                    // ========== RESOLUÇÃO DE HOSTS ==========
                    env.SOURCE_DB_HOST = sh(
                        script: "${SCRIPTS_PATH}/get_db_host.sh ${params.SOURCE_SERVIDOR.toLowerCase()}",
                        returnStdout: true
                    ).trim()
                    env.DESTINO_DB_HOST = sh(
                        script: "${SCRIPTS_PATH}/get_db_host.sh ${params.DESTINO_SERVIDOR.toLowerCase()}",
                        returnStdout: true
                    ).trim()

                    // Mapeamento de IP interno por servidor (usado no jdbcurl do login.properties)
                    def dbInternalHostMap = [
                        'oci-db-qa'  : '10.0.2.143',
                        'oci-db-imp' : '10.0.1.245',
                        'oci-db-02'  : '10.0.1.21'
                    ]
                    env.SOURCE_DB_INTERNAL_HOST = dbInternalHostMap.get(params.SOURCE_SERVIDOR.toLowerCase(), env.SOURCE_DB_HOST)
                    env.DESTINO_DB_INTERNAL_HOST = dbInternalHostMap.get(params.DESTINO_SERVIDOR.toLowerCase(), env.DESTINO_DB_HOST)

                    // Credenciais de banco para o login.properties no deploy (destino)
                    def deployDbCredsByServer = [
                        'oci-db-qa'  : [user: 'ociadm', password: 'Mobiis@path#2026'],
                        'oci-db-imp' : [user: 'ociadm', password: 'Mobi!sfor#2027%'],
                        'oci-db-02'  : [user: 'ociadm', password: 'T8q#6m%74dZj'],
                    ]
                    def deployDbCreds = deployDbCredsByServer.get(params.DESTINO_SERVIDOR.toLowerCase(), [user: 'pathfinddb', password: 'Find**(path)$DB'])
                    env.DEPLOY_DB_USER     = deployDbCreds.user
                    env.DEPLOY_DB_PASSWORD = deployDbCreds.password

                    // ========== DEPLOY TARGET PARSING ==========
                    if (params.DEPLOY_APP) {
                        def validateDeployTarget = { String target, String label ->
                            def parts = target.split(':')
                            if (parts.size() != 2 || !parts[0].trim() || !parts[1].trim()) {
                                error("❌ ${label} inválido. Use o formato NOME:IP.")
                            }
                            def ip = parts[1].trim()
                            if (!(ip ==~ /^\d{1,3}(\.\d{1,3}){3}$/)) {
                                error("❌ ${label} inválido. IP fora do padrão esperado.")
                            }
                            return [parts[0].trim(), ip]
                        }
                        def sourceParts = validateDeployTarget(params.SOURCE_DEPLOY_TARGET, 'SOURCE_DEPLOY_TARGET')
                        env.SOURCE_DEPLOY_SERVER_NAME = sourceParts[0]
                        env.SOURCE_DEPLOY_SERVER_IP = sourceParts[1]

                        def destinoParts = validateDeployTarget(params.DESTINO_DEPLOY_TARGET, 'DESTINO_DEPLOY_TARGET')
                        env.DESTINO_DEPLOY_SERVER_NAME = destinoParts[0]
                        env.DESTINO_DEPLOY_SERVER_IP = destinoParts[1]

                        if (!params.DESTINO_TOMCAT_VOLUME || params.DESTINO_TOMCAT_VOLUME.trim() == '') {
                            error("❌ DESTINO_TOMCAT_VOLUME é obrigatório quando DEPLOY_APP=true!")
                        }
                        if (!params.DESTINO_APP_NAME || params.DESTINO_APP_NAME.trim() == '') {
                            error("❌ DESTINO_APP_NAME é obrigatório quando DEPLOY_APP=true!")
                        }

                        env.APP_VERSION_RESOLVED = destinoVersaoAppParam ? destinoVersaoAppParam : destinoVersaoBanco
                        if (!env.APP_VERSION_RESOLVED?.trim()) {
                            error("❌ DESTINO_VERSAO_APP é obrigatória quando DEPLOY_APP=true e DESTINO_VERSAO_BANCO está vazia.")
                        }
                    } else {
                        env.SOURCE_DEPLOY_SERVER_NAME = ''
                        env.SOURCE_DEPLOY_SERVER_IP = ''
                        env.DESTINO_DEPLOY_SERVER_NAME = ''
                        env.DESTINO_DEPLOY_SERVER_IP = ''
                        env.APP_VERSION_RESOLVED = ''
                    }

                    // ========== REPOSITÓRIO DA APLICAÇÃO ==========
                    def appRepoDefaults = [
                        'PTF': [url: 'https://MobiisLogistica@dev.azure.com/MobiisLogistica/Roteirizador/_git/pathfind', branch: 'mvp'],
                        'PLN': [url: 'https://MobiisLogistica@dev.azure.com/MobiisLogistica/Planner%20e%20Torre/_git/planner', branch: 'v8']
                    ]
                    def selectedRepo = appRepoDefaults[params.TIPO_AMBIENTE]
                    env.APP_REPO_URL = (params.APP_REPO_URL_OVERRIDE?.trim()) ? params.APP_REPO_URL_OVERRIDE.trim() : selectedRepo.url
                    env.APP_REPO_BRANCH = params.APP_REPO_BRANCH?.trim() ?: selectedRepo.branch

                    echo "✅ Validação concluída."
                    echo "   Origem DB Host: ${env.SOURCE_DB_HOST}"
                    echo "   Destino DB Host: ${env.DESTINO_DB_HOST}"
                    if (params.DEPLOY_APP) {
                        echo "   Destino Deploy: ${env.DESTINO_DEPLOY_SERVER_NAME} (${env.DESTINO_DEPLOY_SERVER_IP})"
                        echo "   Versão App: ${env.APP_VERSION_RESOLVED}"
                    }
                }
            }
        }

        stage('📁 Preparação do Ambiente') {
            steps {
                script {
                    echo "🔧 Preparando ambiente de trabalho..."
                    sh """
                        mkdir -p ${WORKSPACE}/temp
                        mkdir -p ${WORKSPACE}/logs
                        chmod +x ${SCRIPTS_PATH}/*.sh
                    """


                }
            }
        }

        stage('🔄 Sincronização de Migrations') {
            when {
                expression { params.CRIAR_BANCO }
            }
            steps {
                script {
                    def tipoAmbiente = params.TIPO_AMBIENTE.toLowerCase()
                    def outputDir = "${WORKSPACE}/temp/sql_updates/${tipoAmbiente}/updates"

                    sh """
                        mkdir -p "${outputDir}"
                        rm -f "${outputDir}"/*.sql
                    """

                    if (params.SINCRONIZAR_UPDATES_INFRA) {
                        echo "🔄 Sincronizando updates do repositório de infraestrutura..."
                        withCredentials([
                            usernamePassword(
                                credentialsId: params.INFRA_REPO_CREDENTIALS_ID,
                                usernameVariable: 'INFRA_GIT_USER',
                                passwordVariable: 'INFRA_GIT_TOKEN'
                            )
                        ]) {
                            sh """
                                ${SCRIPTS_PATH}/fetch_updates.sh \\
                                    --tipo-ambiente "${tipoAmbiente}" \\
                                    --repo-url "${params.INFRA_REPO_URL}" \\
                                    --repo-branch "${params.INFRA_REPO_BRANCH}" \\
                                    --work-dir "${WORKSPACE}/temp/infra_repo_cache" \\
                                    --output-dir "${outputDir}" \\
                                    --git-username "${INFRA_GIT_USER}" \\
                                    --git-token "${INFRA_GIT_TOKEN}"
                            """
                        }
                    } else {
                        echo "ℹ️ Sincronização desabilitada. Usando updates locais."
                        sh """
                            cp ${SQL_PATH}/${tipoAmbiente}/updates/*.sql "${outputDir}/" 2>/dev/null || true
                        """
                    }

                    sh """
                        echo "📋 Updates preparados para execução:"
                        ls -1 "${outputDir}"/*.sql 2>/dev/null || echo "Nenhum update disponível"
                    """
                }
            }
        }

        stage('🗄️ Cópia do Banco de Dados') {
            when {
                expression { params.CRIAR_BANCO }
            }
            steps {
                script {
                    echo "🗄️ Iniciando cópia do banco de dados..."

                    withCredentials([
                        string(credentialsId: 'BASTION_HOST', variable: 'BASTION_HOST'),
                        string(credentialsId: 'BASTION_USER', variable: 'BASTION_USER'),
                        string(credentialsId: 'db-pathfind-user', variable: 'DB_USER_GCP'),
                        string(credentialsId: 'db-pathfind-password', variable: 'DB_PASSWORD_GCP'),
                        string(credentialsId: 'db-pathfind-user-oci', variable: 'DB_USER_OCI'),
                        string(credentialsId: 'db-pathfind-password-oci-db-qa', variable: 'DB_PASSWORD_OCI_DB_QA'),
                        string(credentialsId: 'db-pathfind-password-oci-db-imp', variable: 'DB_PASSWORD_OCI_DB_IMP'),
                        string(credentialsId: 'db-pathfind-password-oci-db-02', variable: 'DB_PASSWORD_OCI_DB_02'),
                        sshUserPrivateKey(credentialsId: 'SSH_PRIVATE_KEY', keyFileVariable: 'SSH_KEY', passphraseVariable: 'SSH_PASSPHRASE')
                    ]) {
                        // ========== RESOLVE SOURCE CREDENTIALS ==========
                        def sourceLower = params.SOURCE_SERVIDOR.toLowerCase()
                        def ociPasswordMap = [
                            'oci-db-qa'  : env.DB_PASSWORD_OCI_DB_QA,
                            'oci-db-imp' : env.DB_PASSWORD_OCI_DB_IMP,
                            'oci-db-02'  : env.DB_PASSWORD_OCI_DB_02
                        ]
                        def sourceDbUser, sourceDbPassword
                        if (sourceLower.startsWith('oci-')) {
                            if (!ociPasswordMap.containsKey(sourceLower)) {
                                error("❌ Servidor OCI '${params.SOURCE_SERVIDOR}' não possui credencial de senha mapeada no pipeline.")
                            }
                            sourceDbUser = env.DB_USER_OCI
                            sourceDbPassword = ociPasswordMap[sourceLower]
                        } else {
                            sourceDbUser = env.DB_USER_GCP
                            sourceDbPassword = env.DB_PASSWORD_GCP
                        }

                        // ========== RESOLVE DESTINATION CREDENTIALS ==========
                        def destinoLower = params.DESTINO_SERVIDOR.toLowerCase()
                        def destinoDbUser, destinoDbPassword
                        if (destinoLower.startsWith('oci-')) {
                            if (!ociPasswordMap.containsKey(destinoLower)) {
                                error("❌ Servidor OCI '${params.DESTINO_SERVIDOR}' não possui credencial de senha mapeada no pipeline.")
                            }
                            destinoDbUser = env.DB_USER_OCI
                            destinoDbPassword = ociPasswordMap[destinoLower]
                        } else {
                            destinoDbUser = env.DB_USER_GCP
                            destinoDbPassword = env.DB_PASSWORD_GCP
                        }

                        def copyResult = sh(
                            script: """
                                # Criar script temporário para ssh-add
                                cat > /tmp/ssh-add-script-\$\$.sh << 'EOF'
#!/bin/bash
echo "\$SSH_PASSPHRASE"
EOF
                                chmod +x /tmp/ssh-add-script-\$\$.sh

                                # Configurar ssh-agent temporário
                                eval \$(ssh-agent -s)

                                # Adicionar chave com passphrase
                                DISPLAY=:0 SSH_ASKPASS=/tmp/ssh-add-script-\$\$.sh ssh-add \${SSH_KEY} < /dev/null

                                # Criar diretório no bastion
                                ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "mkdir -p /tmp/pipeline-${BUILD_NUMBER}"

                                # Copiar arquivos necessários
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/scripts/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/sql/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/dados/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/temp/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/

                                # Executar scripts no bastion
                                ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} << 'ENDCOPY'
cd /tmp/pipeline-${BUILD_NUMBER}
chmod +x scripts/*.sh

echo "=== DEBUG - Variáveis do Pipeline (Cópia) ==="
echo "TIPO_AMBIENTE: ${params.TIPO_AMBIENTE}"
echo "SOURCE_SERVIDOR: ${params.SOURCE_SERVIDOR}"
echo "SOURCE_NOME_BANCO: ${params.SOURCE_NOME_BANCO}"
echo "SOURCE_VERSAO_BANCO: ${env.SOURCE_VERSAO_BANCO_CLEAN}"
echo "SOURCE_DB_HOST: ${env.SOURCE_DB_HOST}"
echo "DESTINO_SERVIDOR: ${params.DESTINO_SERVIDOR}"
echo "DESTINO_NOME_BANCO: ${params.DESTINO_NOME_BANCO}"
echo "DESTINO_VERSAO_BANCO: ${env.DESTINO_VERSAO_BANCO_CLEAN}"
echo "DESTINO_DB_HOST: ${env.DESTINO_DB_HOST}"
echo "DESTINO_DB_INTERNAL_HOST: ${env.DESTINO_DB_INTERNAL_HOST}"
echo "================================="

# Executar cópia do banco
./scripts/copy_database.sh \\
    --tipo-ambiente "${params.TIPO_AMBIENTE.toLowerCase()}" \\
    --source-servidor "${params.SOURCE_SERVIDOR}" \\
    --source-db-host "${env.SOURCE_DB_HOST}" \\
    --source-db-port "${env.DB_PORT}" \\
    --source-db-user "${sourceDbUser}" \\
    --source-db-password "${sourceDbPassword}" \\
    --source-nome-banco "${params.SOURCE_NOME_BANCO}" \\
    --source-versao-banco "${env.SOURCE_VERSAO_BANCO_CLEAN}" \\
    --destino-servidor "${params.DESTINO_SERVIDOR}" \\
    --destino-db-host "${env.DESTINO_DB_HOST}" \\
    --destino-db-port "${env.DB_PORT}" \\
    --destino-db-user "${destinoDbUser}" \\
    --destino-db-password "${destinoDbPassword}" \\
    --destino-db-internal-host "${env.DESTINO_DB_INTERNAL_HOST}" \\
    --destino-nome-banco "${params.DESTINO_NOME_BANCO}" \\
    --destino-versao-banco "${env.DESTINO_VERSAO_BANCO_CLEAN}" \\
    --workspace "/tmp/pipeline-${BUILD_NUMBER}" \\
    --updates-dir "/tmp/pipeline-${BUILD_NUMBER}/temp/sql_updates/${params.TIPO_AMBIENTE.toLowerCase()}/updates"

if [ \$? -ne 0 ]; then
    echo "❌ ERRO: Falha na cópia do banco de dados!"
    exit 1
fi

echo "✅ Cópia do banco concluída com sucesso!"
ENDCOPY

                                SSH_EXIT_CODE=\$?

                                # Limpar
                                ssh-agent -k
                                rm -f /tmp/ssh-add-script-\$\$.sh

                                if [ \$SSH_EXIT_CODE -ne 0 ]; then
                                    echo "❌ ERRO: Script remoto falhou com código: \$SSH_EXIT_CODE"
                                    exit \$SSH_EXIT_CODE
                                fi
                            """,
                            returnStatus: true
                        )

                        if (copyResult != 0) {
                            error("❌ Falha na cópia do banco de dados! Exit code: ${copyResult}")
                        }

                        echo "✅ Banco de dados ${params.DESTINO_NOME_BANCO} copiado com sucesso!"
                    }
                }
            }
        }

        stage('🚀 Deploy da Aplicação no Destino') {
            when {
                expression { params.DEPLOY_APP }
            }
            steps {
                script {
                    echo "🚀 Iniciando deploy da aplicação no destino..."

                    withCredentials([
                        string(credentialsId: 'BASTION_HOST', variable: 'BASTION_HOST'),
                        string(credentialsId: 'BASTION_USER', variable: 'BASTION_USER'),
                        string(credentialsId: 'infra-sudo-pswd', variable: 'INFRA_SUDO_PASSWORD'),
                        usernamePassword(credentialsId: 'azure-credentials-luan', usernameVariable: 'APP_GIT_USER', passwordVariable: 'APP_GIT_TOKEN'),
                        sshUserPrivateKey(credentialsId: 'SSH_PRIVATE_KEY', keyFileVariable: 'SSH_KEY', passphraseVariable: 'SSH_PASSPHRASE'),
                        sshUserPrivateKey(credentialsId: 'ssh-credentials', keyFileVariable: 'DEPLOY_SSH_KEY', passphraseVariable: 'DEPLOY_SSH_PASSPHRASE')
                    ]) {
                        def deployResult = sh(
                            script: """
                                ARTIFACT_DIR="${WORKSPACE}/temp/app_artifact"
                                ARTIFACT_WAR="\${ARTIFACT_DIR}/app.war"
                                mkdir -p "\${ARTIFACT_DIR}"

                                echo "📦 Construindo WAR da aplicação"
                                ${SCRIPTS_PATH}/build_app_artifact.sh \\
                                    --tipo-ambiente "${params.TIPO_AMBIENTE.toLowerCase()}" \\
                                    --repo-url "${env.APP_REPO_URL}" \\
                                    --repo-branch "${env.APP_REPO_BRANCH}" \\
                                    --app-version "${env.APP_VERSION_RESOLVED}" \\
                                    --output-war "\${ARTIFACT_WAR}" \\
                                    --workspace "${WORKSPACE}" \\
                                    --git-username "\${APP_GIT_USER}" \\
                                    --git-token "\${APP_GIT_TOKEN}"

                                if [ ! -f "\${ARTIFACT_WAR}" ]; then
                                    echo "❌ ERRO: WAR final não encontrado em \${ARTIFACT_WAR}"
                                    exit 1
                                fi

                                # Criar script temporário para ssh-add
                                cat > /tmp/ssh-add-script-\$\$.sh << 'EOF'
#!/bin/bash
echo "\$SSH_PASSPHRASE"
EOF
                                chmod +x /tmp/ssh-add-script-\$\$.sh

                                # Configurar ssh-agent temporário
                                eval \$(ssh-agent -s)

                                # Adicionar chave com passphrase
                                DISPLAY=:0 SSH_ASKPASS=/tmp/ssh-add-script-\$\$.sh ssh-add \${SSH_KEY} < /dev/null

                                # Criar diretório no bastion e copiar arquivos
                                ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "mkdir -p /tmp/pipeline-${BUILD_NUMBER}"
                                scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/scripts/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/
                                scp -o StrictHostKeyChecking=no "\${ARTIFACT_WAR}" \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/app.war
                                scp -o StrictHostKeyChecking=no "\${DEPLOY_SSH_KEY}" \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key
                                ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "chmod 600 /tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key"
                                printf '%s' "\${INFRA_SUDO_PASSWORD}" > "${WORKSPACE}/temp/.infra_sudo_password"
                                scp -o StrictHostKeyChecking=no "${WORKSPACE}/temp/.infra_sudo_password" \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password
                                rm -f "${WORKSPACE}/temp/.infra_sudo_password"

                                # Executar deploy no bastion
                                ssh -A -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} << 'ENDDEPLOY'
cd /tmp/pipeline-${BUILD_NUMBER}
chmod +x scripts/*.sh
trap 'rm -f /tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password /tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key' EXIT
SUDO_PASSWORD_REMOTE="\$(cat /tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password)"

./scripts/deploy_application.sh \\
    --war-file "/tmp/pipeline-${BUILD_NUMBER}/app.war" \\
    --nome-banco "${params.DESTINO_NOME_BANCO}" \\
    --db-host "${env.DESTINO_DB_HOST}" \\
    --db-internal-host "${env.DESTINO_DB_INTERNAL_HOST}" \\
    --db-user "${env.DEPLOY_DB_USER}" \\
    --db-password "${env.DEPLOY_DB_PASSWORD}" \\
    --tipo-ambiente "${params.TIPO_AMBIENTE.toLowerCase()}" \\
    --deploy-server-name "${env.DESTINO_DEPLOY_SERVER_NAME}" \\
    --deploy-server-ip "${env.DESTINO_DEPLOY_SERVER_IP}" \\
    --tomcat-volume "${params.DESTINO_TOMCAT_VOLUME}" \\
    --app-name "${params.DESTINO_APP_NAME}" \\
    --ssh-key-file "/tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key" \\
    --workspace "/tmp/pipeline-${BUILD_NUMBER}" \\
    --multibanco "false" \\
    --sudo-password "\${SUDO_PASSWORD_REMOTE}"

if [ \$? -ne 0 ]; then
    echo "❌ ERRO: Falha no deploy da aplicação!"
    exit 1
fi

echo "✅ Deploy da aplicação concluído com sucesso!"
ENDDEPLOY

                                DEPLOY_EXIT_CODE=\$?

                                ssh-agent -k
                                rm -f /tmp/ssh-add-script-\$\$.sh

                                if [ \$DEPLOY_EXIT_CODE -ne 0 ]; then
                                    echo "❌ ERRO: Deploy falhou com código: \$DEPLOY_EXIT_CODE"
                                    exit \$DEPLOY_EXIT_CODE
                                fi
                            """,
                            returnStatus: true
                        )

                        if (deployResult != 0) {
                            error("❌ Falha no deploy da aplicação! Exit code: ${deployResult}")
                        }

                        echo "✅ Deploy da aplicação concluído com sucesso!"
                    }
                }
            }
        }

        stage('✅ Verificação Final') {
            steps {
                script {
                    echo "🔍 Executando verificações finais..."

                    withCredentials([
                        string(credentialsId: 'BASTION_HOST', variable: 'BASTION_HOST'),
                        string(credentialsId: 'BASTION_USER', variable: 'BASTION_USER'),
                        string(credentialsId: 'infra-sudo-pswd', variable: 'INFRA_SUDO_PASSWORD'),
                        string(credentialsId: 'db-pathfind-user', variable: 'DB_USER'),
                        string(credentialsId: 'db-pathfind-password', variable: 'DB_PASSWORD'),
                        sshUserPrivateKey(credentialsId: 'SSH_PRIVATE_KEY', keyFileVariable: 'SSH_KEY', passphraseVariable: 'SSH_PASSPHRASE'),
                        sshUserPrivateKey(credentialsId: 'ssh-credentials', keyFileVariable: 'DEPLOY_SSH_KEY', passphraseVariable: 'DEPLOY_SSH_PASSPHRASE')
                    ]) {
                        sh """
                            cat > /tmp/ssh-add-script-\$\$.sh << 'EOF'
#!/bin/bash
echo "\$SSH_PASSPHRASE"
EOF
                            chmod +x /tmp/ssh-add-script-\$\$.sh

                            eval \$(ssh-agent -s)
                            DISPLAY=:0 SSH_ASKPASS=/tmp/ssh-add-script-\$\$.sh ssh-add \${SSH_KEY} < /dev/null

                            ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "mkdir -p /tmp/pipeline-${BUILD_NUMBER}"
                            scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/scripts/ \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/
                            scp -o StrictHostKeyChecking=no "\${DEPLOY_SSH_KEY}" \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key
                            ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "chmod 600 /tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key"
                            printf '%s' "\${INFRA_SUDO_PASSWORD}" > "${WORKSPACE}/temp/.infra_sudo_password"
                            scp -o StrictHostKeyChecking=no "${WORKSPACE}/temp/.infra_sudo_password" \${BASTION_USER}@\${BASTION_HOST}:/tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password
                            rm -f "${WORKSPACE}/temp/.infra_sudo_password"

                            ssh -A -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} << 'ENDVERIFY'
cd /tmp/pipeline-${BUILD_NUMBER}
chmod +x scripts/*.sh
trap 'rm -f /tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password /tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key' EXIT
SUDO_PASSWORD_REMOTE="\$(cat /tmp/pipeline-${BUILD_NUMBER}/.infra_sudo_password)"

echo "🔍 Executando verificações..."

if [ "${params.CRIAR_BANCO}" = "true" ]; then
    ./scripts/verify_database.sh \\
        --nome-banco "${params.DESTINO_NOME_BANCO}" \\
        --db-host "${env.DESTINO_DB_HOST}" \\
        --db-port "${env.DB_PORT}" \\
        --db-user "${DB_USER}" \\
        --db-password "${DB_PASSWORD}"
fi

if [ "${params.DEPLOY_APP}" = "true" ]; then
    ./scripts/verify_deployment.sh \\
        --deploy-server-name "${env.DESTINO_DEPLOY_SERVER_NAME}" \\
        --deploy-server-ip "${env.DESTINO_DEPLOY_SERVER_IP}" \\
        --tomcat-volume "${params.DESTINO_TOMCAT_VOLUME}" \\
        --app-name "${params.DESTINO_APP_NAME}" \\
        --ssh-key-file "/tmp/pipeline-${BUILD_NUMBER}/.deploy_ssh_key" \\
        --sudo-password "\${SUDO_PASSWORD_REMOTE}"
fi

if [ \$? -ne 0 ]; then
    echo "❌ ERRO: Verificações falharam!"
    exit 1
fi

echo "✅ Todas as verificações concluídas com sucesso!"
ENDVERIFY

                            VERIFY_EXIT_CODE=\$?

                            ssh-agent -k
                            rm -f /tmp/ssh-add-script-\$\$.sh

                            if [ \$VERIFY_EXIT_CODE -ne 0 ]; then
                                echo "❌ ERRO: Verificações falharam com código: \$VERIFY_EXIT_CODE"
                                exit \$VERIFY_EXIT_CODE
                            fi
                        """
                    }

                    echo "✅ Todas as verificações foram concluídas com sucesso!"
                }
            }
        }
    }

    post {
        always {
            script {
                echo "🧹 Executando limpeza..."

                if (fileExists("${WORKSPACE}/logs")) {
                    archiveArtifacts artifacts: 'logs/**/*', allowEmptyArchive: true
                }

                sh """
                    rm -rf "${WORKSPACE}/temp/sql_updates" || true
                    rm -rf ${WORKSPACE}/temp
                    find ${WORKSPACE} -name "*.tmp" -delete 2>/dev/null || true
                """

                try {
                    withCredentials([
                        string(credentialsId: 'BASTION_HOST', variable: 'BASTION_HOST'),
                        string(credentialsId: 'BASTION_USER', variable: 'BASTION_USER'),
                        sshUserPrivateKey(credentialsId: 'SSH_PRIVATE_KEY', keyFileVariable: 'SSH_KEY', passphraseVariable: 'SSH_PASSPHRASE')
                    ]) {
                        sh """
                            cat > /tmp/ssh-add-script-\$\$.sh << 'EOF'
#!/bin/bash
echo "\$SSH_PASSPHRASE"
EOF
                            chmod +x /tmp/ssh-add-script-\$\$.sh
                            eval \$(ssh-agent -s)
                            DISPLAY=:0 SSH_ASKPASS=/tmp/ssh-add-script-\$\$.sh ssh-add \${SSH_KEY} < /dev/null
                            ssh -o StrictHostKeyChecking=no \${BASTION_USER}@\${BASTION_HOST} "rm -rf /tmp/pipeline-${BUILD_NUMBER}"
                            ssh-agent -k
                            rm -f /tmp/ssh-add-script-\$\$.sh
                        """
                    }
                } catch (Exception e) {
                    echo "⚠️ Erro na limpeza do bastion: ${e.getMessage()}"
                }
            }
        }

        success {
            echo """
🎉 ===== PIPELINE CONCLUÍDO COM SUCESSO! =====
📋 Resumo:
   - Origem DB: ${params.SOURCE_SERVIDOR} / ${params.SOURCE_NOME_BANCO}
   - Destino DB: ${params.DESTINO_SERVIDOR} / ${params.DESTINO_NOME_BANCO}
   - Deploy Target: ${params.DESTINO_DEPLOY_TARGET}
   - Cópia Banco: ${params.CRIAR_BANCO ? 'Sim' : 'Não'}
   - Deploy App: ${params.DEPLOY_APP ? 'Sim' : 'Não'}
=============================================
            """
        }

        failure {
            echo """
❌ ===== PIPELINE FALHOU! =====
📋 Verifique os logs para mais detalhes.
Parâmetros:
   - Origem: ${params.SOURCE_SERVIDOR} / ${params.SOURCE_NOME_BANCO}
   - Destino: ${params.DESTINO_SERVIDOR} / ${params.DESTINO_NOME_BANCO}
==============================
            """
        }
    }
}
