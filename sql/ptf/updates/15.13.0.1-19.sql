INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
SELECT 'fretefy-unidade-negocio-id', 'fretefy', false, 'STRING', 0, ''
WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'fretefy-unidade-negocio-id' and nometela = 'fretefy');

ALTER TABLE rota ADD COLUMN IF NOT EXISTS status_integracao character varying(20) NOT NULL DEFAULT 'NAO_INTEGRADO';
ALTER TABLE rota ADD COLUMN IF NOT EXISTS id_integracao character varying(100);

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-19' WHERE nomecampo = 'versao_banco';