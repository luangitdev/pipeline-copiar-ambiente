INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Trabalha com Itinerario?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Itinerario?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-26' WHERE nomecampo = 'versao_banco';