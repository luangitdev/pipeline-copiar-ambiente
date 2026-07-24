-- PROD GCP V15 (IMP/HOM/PROD)
update configuracao set valor_texto = 'fd43N3T1ZmhDhKIOxXBaIiQFf78WRNG2rg8Q4Ar3Ij4' where nomecampo = 'here-key';
update configuracao set valor_texto = 'YkJKwgZJdd5H7gxGadiC' where nomecampo = 'here-code';
update configuracao set valor_texto = 'https://geocode.search.hereapi.com/v1/geocode?' where nomecampo = 'here-url';
update configuracao set valor_texto='cHRmX2tldHRsZTpwdGZAazN0dGwz' where nomecampo='kettle-key';
update parametro set valor='/opt/kettle-prod/importacao/uploads' where chave ='Kettle-Caminho Destino';
update parametro set valor='/opt/kettle-prod/importacao/modelos_ktr' where chave ='Kettle-Caminho Modelo';
update parametro set valor='http://10.0.16.17:8040/kettle' where chave ='Kettle-URL';
update parametro set valor=(select current_database()) where chave ='Nome Banco de Dados';
update parametro set valor='5432' where chave ='Porta do Servidor Banco de Dados';
update parametro set valor='10.200.0.19' where chave ='Servidor Banco de Dados';
INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto) SELECT 'versao_aplicacao', '', false, 'STRING', 0, '' WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'versao_aplicacao');
update parametro set valor='http://10.0.16.3:9081/ptfses4-13-1' where chave='Url Roteirizador' or chave='Url Roteirizador Reprocessar';
update configuracao set valor_texto='https://servicomonitoramento.com/api' where nomecampo='monitoramento-uri';
update configuracao set valor_texto='http://controltower.pathfindsistema.com.br/api' where nomecampo='controltower-uri';

--update configuracao set valor_texto='https://hom.back-monitoramento.sistemapathfind.com.br/api' where nomecampo='monitoramento-uri';
--update configuracao set valor_texto='https://hom.controltower.sistemapathfind.com.br/api' where nomecampo='controltower-uri';

DROP FUNCTION pathfind_atualiza_zona_em_lote();

CREATE OR REPLACE FUNCTION public.pathfind_atualiza_zona_em_lote(
    )
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
    ender record;
    zona record;
    qtde integer=0;
BEGIN
    --SET session_replication_role = replica;
    PERFORM pathfind_atualiza_geom_zonas();
    FOR ender IN SELECT id as id_endereco, latitude, longitude FROM endereco WHERE latitude is not null and longitude is not null LOOP
        -- RAISE NOTICE '%$ %$', ender.latitude, ender.longitude;
        FOR zona IN SELECT id as zona_id, tipo_zona FROM pathfind_zona_contendo_coordenada(ender.latitude, ender.longitude) LOOP
            -- qtde = qtde + 1;
            IF (zona.tipo_zona = 'SIMULACAO') THEN
                UPDATE endereco SET id_zona = zona.zona_id WHERE id = ender.id_endereco;
                qtde = qtde + 1;
            ELSIF (zona.tipo_zona = 'RESTRITA') THEN
                UPDATE endereco SET id_zona_restrita = zona.zona_id WHERE id = ender.id_endereco;
                qtde = qtde + 1;
          END IF;
        END LOOP;
    END LOOP;
  -- SET session_replication_role = DEFAULT;
   RETURN qtde;
END;
$BODY$;
--update configuracao set valor_texto = 'http://192.168.25.26:8081/api' where nomecampo = 'controltower-uri';
--update configuracao set valor_texto = 'http://192.168.25.36:8081/api' where nomecampo = 'monitoramento-uri';