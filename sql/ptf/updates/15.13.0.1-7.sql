INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
SELECT 'fretefy-url-integracao', 'fretefy', false, 'STRING', 0, 'https://api-fretefy-staging.azurewebsites.net/api'
WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'fretefy-url-integracao' and nometela = 'fretefy');

INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
SELECT 'fretefy-api-key', 'fretefy', false, 'STRING', 0, '6edcf758d2806130b97e3d5efb980dacfbd809eb6123027324d8a207cc74923f'
WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'fretefy-api-key' and nometela = 'fretefy');


ALTER TABLE motorista ADD COLUMN IF NOT EXISTS status_integracao character varying(20) NOT NULL DEFAULT 'NAO_INTEGRADO';
ALTER TABLE motorista ADD COLUMN IF NOT EXISTS id_integracao character varying(100);

ALTER TABLE veiculo ADD COLUMN IF NOT EXISTS status_integracao character varying(20) NOT NULL DEFAULT 'NAO_INTEGRADO';
ALTER TABLE veiculo ADD COLUMN IF NOT EXISTS id_integracao character varying(100);

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Trabalha com Integracao Fretefy?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Integracao Fretefy?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-7' WHERE nomecampo = 'versao_banco';
