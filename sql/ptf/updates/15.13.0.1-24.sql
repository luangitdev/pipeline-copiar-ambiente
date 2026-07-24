INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Ocupacao Minima para Sinalizacao de Rota', '0', 'INTEGER', true, false, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Ocupacao Minima para Sinalizacao de Rota');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Trabalha com Integracao Votorantim?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Integracao Votorantim?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-24' WHERE nomecampo = 'versao_banco';