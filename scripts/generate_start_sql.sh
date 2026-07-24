#!/bin/bash

# Script para gerar start.sql personalizado baseado nos dados do ambiente
# Uso: generate_start_sql.sh <dados_file> <tipo_ambiente> <output_dir>

set -euo pipefail

DADOS_FILE="$1"
TIPO_AMBIENTE="$2"
OUTPUT_DIR="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/log_utils.sh"

log "🔄 Gerando start.sql personalizado..."

# Criar diretório de saída se não existir
mkdir -p "$OUTPUT_DIR"

# Inicializar variáveis com valores padrão
ENDERECO="N/A"
BAIRRO="N/A"
CIDADE="N/A"
ESTADO="N/A"
CEP="N/A"
LAT="0.0"
LONG="0.0"
CNPJ="N/A"
RAZAO_SOCIAL="N/A"
ESTADO_NOME="N/A"

# Processar arquivo de dados se existir
if [[ -f "$DADOS_FILE" ]]; then
    log "📄 Processando dados de: $DADOS_FILE"
    
    # Adicionar quebra de linha ao final se não existir para garantir que última linha seja lida
    temp_file="/tmp/dados_temp_$$"
    if [ ! -s "$DADOS_FILE" ] || [ "$(tail -c1 "$DADOS_FILE" | wc -l)" -eq 0 ]; then
        cp "$DADOS_FILE" "$temp_file"
        echo >> "$temp_file"
    else
        cp "$DADOS_FILE" "$temp_file"
    fi
    
    while IFS=':' read -r key value || [ -n "$key" ]; do
        # Ignorar linhas vazias
        [[ -z "$key" ]] && continue
        
        # Remover espaços e converter para minúsculo
        key=$(echo "$key" | xargs | tr '[:upper:]' '[:lower:]' | sed 's/ã/a/g; s/ç/c/g; s/ /_/g')
        value=$(echo "$value" | xargs)
        

        
        case "$key" in
            "endereco") ENDERECO="$value" ;;
            "bairro") BAIRRO="$value" ;;
            "cidade") CIDADE="$value" ;;
            "estado") 
                ESTADO="$value"
                ESTADO_NOME="$value"
                ;;
            "cep") CEP="$(echo "$value" | tr -cd '0-9')" ;;
            "lat"|"latitude") LAT="$value" ;;
            "long"|"longitude") LONG="$value" ;;
            "cnpj")
                CNPJ="$(echo "$value" | tr -cd '0-9')"
                cnpj_len=${#CNPJ}
                if [[ "$cnpj_len" -gt 14 ]]; then
                    log_warning "CNPJ com $cnpj_len dígitos (esperado 14): '$CNPJ' — truncando para 14"
                    CNPJ="${CNPJ:0:14}"
                fi
                log "🔢 CNPJ sanitizado: '$CNPJ' (${#CNPJ} dígitos)"
                ;;
            "razao_social") RAZAO_SOCIAL="$value" ;;
        esac
    done < "$temp_file"
    
    # Limpar arquivo temporário
    rm -f "$temp_file"
    
    log_success "Dados processados com sucesso"
else
    log_warning "Arquivo de dados não encontrado, usando valores padrão"
fi

# Gerar SQL baseado no template
OUTPUT_FILE="$OUTPUT_DIR/start_${TIPO_AMBIENTE}.sql"

log "📝 Gerando arquivo: $OUTPUT_FILE"

# Template SQL seguindo exatamente o padrão do Ansible
if [[ "$TIPO_AMBIENTE" == "ptf" ]]; then
    cat > "$OUTPUT_FILE" << EOF
-- DADOS INICIAIS GERADOS DINAMICAMENTE PARA AMBIENTE PTF
-- INSERT na tabela 'empresa'
INSERT INTO empresa(cnpj, nome, codigocontrol, cobranca, valorunitario, bandeira, projeto, identificador, produto)
VALUES ('$CNPJ', '$RAZAO_SOCIAL', '0', 'total', 50, 'Outros', '0', '1', 'PATHFIND');

-- UPDATE na tabela 'empresa'
UPDATE public.empresa SET id=1;

-- INSERT na tabela 'maparoutes'
INSERT INTO maparoutes(descricao,nome,referencia) VALUES ('$ESTADO', '$ESTADO', 1);

-- UPDATE na tabela 'maparoutes'
UPDATE maparoutes SET descricao=(SELECT nome FROM estado WHERE sigla='$ESTADO'), nome='$ESTADO';
UPDATE maparoutes SET id=1;

-- INSERT na tabela 'centrodistribuicao'
INSERT INTO centrodistribuicao(bairro,cep,codigo,endereco,latitude,longitude,nome,id_cidade,id_empresa,mapa_id,identificador,idpromax,licencadistribuidor,nomeprogramagerador,versaolayoutpathfind,idchk)
VALUES ('$BAIRRO', '$CEP', '0', '$ENDERECO', $LAT, $LONG, '$RAZAO_SOCIAL', (SELECT id FROM cidade WHERE nome ILIKE '$CIDADE' LIMIT 1), 1, 1, '1', '0', 1, '0', '1', '0');

-- UPDATE na tabela 'centrodistribuicao'
UPDATE centrodistribuicao SET id=1;

-- INSERT na tabela 'centrodistribuicao'
INSERT INTO centrodistribuicao(bairro,cep,codigo,endereco,latitude,longitude,nome,id_cidade,id_empresa,mapa_id,identificador,idpromax,licencadistribuidor,nomeprogramagerador,versaolayoutpathfind,idchk)
VALUES ('$BAIRRO', '$CEP', '0', '$ENDERECO', $LAT, $LONG, '$RAZAO_SOCIAL', (SELECT id FROM cidade WHERE nome ILIKE '$CIDADE' LIMIT 1), 1, 1, '1', '0', 1, '0', '1', '0');

-- UPDATE na tabela 'centrodistribuicao'
UPDATE centrodistribuicao SET id=2 where id!=1;
EOF

else
    # Template para PLN
    cat > "$OUTPUT_FILE" << EOF
-- DADOS INICIAIS GERADOS DINAMICAMENTE PARA AMBIENTE PLN
-- Utiliza ON CONFLICT para sobrescrever dados do template com os dados corretos do ambiente
INSERT INTO empresa(id, cnpj, nome, produto) 
VALUES(1, '$CNPJ', '$RAZAO_SOCIAL', 'PLANNER')
ON CONFLICT (id) DO UPDATE SET cnpj = EXCLUDED.cnpj, nome = EXCLUDED.nome, produto = EXCLUDED.produto;

INSERT INTO estado(id, nome, sigla) 
VALUES(1, '$ESTADO_NOME', '$ESTADO')
ON CONFLICT (id) DO UPDATE SET nome = EXCLUDED.nome, sigla = EXCLUDED.sigla;

INSERT INTO cidade(id, nome, estado_id) 
VALUES(1, '$CIDADE', 1)
ON CONFLICT (id) DO UPDATE SET nome = EXCLUDED.nome, estado_id = EXCLUDED.estado_id;

INSERT INTO maparoutes(id, descricao, nome, referencia) 
VALUES(1, '$ESTADO_NOME', '$ESTADO', 1)
ON CONFLICT (id) DO UPDATE SET descricao = EXCLUDED.descricao, nome = EXCLUDED.nome, referencia = EXCLUDED.referencia;

INSERT INTO centrodistribuicao(id, nome, endereco, bairro, cep, latitude, longitude, id_empresa, id_cidade, identificador, mapa_id)
VALUES(1, '$RAZAO_SOCIAL', '$ENDERECO', '$BAIRRO', '$CEP', $LAT, $LONG, 1, 1, '1', 1)
ON CONFLICT (id) DO UPDATE SET nome = EXCLUDED.nome, endereco = EXCLUDED.endereco, bairro = EXCLUDED.bairro,
    cep = EXCLUDED.cep, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
    id_empresa = EXCLUDED.id_empresa, id_cidade = EXCLUDED.id_cidade,
    identificador = EXCLUDED.identificador, mapa_id = EXCLUDED.mapa_id;
EOF

fi

# Adicionar função de verificação de sequences (apenas para PTF)
if [[ "$TIPO_AMBIENTE" == "ptf" ]]; then
    cat >> "$OUTPUT_FILE" << EOF

-- Configurações baseadas no servidor
-- Função para checar as sequências
CREATE OR REPLACE FUNCTION check_sequences()
RETURNS void AS 
\$BODY\$
DECLARE
t record;
s_name record;
sch_lv int;
max_id int;
BEGIN
    FOR t IN (SELECT distinct substring(c.relname from -1 for (position('id_seq' in c.relname))) as tb_name,
c.relname as sq_name FROM
        pg_class c WHERE c.relkind = 'S' and (SELECT substring(c.relname from -1 for (position('id_seq' in c.relname))) in
        (SELECT distinct table_name FROM information_schema.columns  WHERE table_schema='public')AND c.relname IN
            (SELECT sequence_name  FROM information_schema.sequences where sequence_schema ='public'))) LOOP
    
    EXECUTE format('SELECT max(id) from %s',t.tb_name) INTO max_id;
    EXECUTE format('SELECT last_value from %s',t.sq_name) INTO sch_lv;

            IF (max_id <> sch_lv) THEN

              RAISE NOTICE '--------------------------------------';
              RAISE NOTICE 'Tabela - Sequence: %', t;
              RAISE NOTICE 'TABLE(max(id)): %',max_id;
              RAISE NOTICE 'SEQUENCE(last_value): %',sch_lv;
              RAISE NOTICE '--------------------------------------';
              EXECUTE format('select setval( ''%s'',(SELECT max(id) from %s ))', t.sq_name,t.tb_name);
              RAISE NOTICE '< SEQUENCE CORRIGIDA >';
            END IF;  

              RAISE NOTICE 'Tabela - Sequence: %', t;

    END LOOP;    
END;
\$BODY\$
LANGUAGE plpgsql VOLATILE
COST 100;

SELECT check_sequences();
DROP FUNCTION check_sequences();
SELECT max(id) FROM zona;
SELECT last_value FROM zona_id_seq;
SELECT setval('zona_id_seq', (SELECT max(id) FROM zona));
EOF
fi

log_success "Arquivo start.sql gerado: $OUTPUT_FILE"