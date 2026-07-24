INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Quantidade de Dias de Pernoite', '0', 'NUMBER', true, false, 'INTEGRACAO', 'PARCEIROS', ''
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Quantidade de Dias de Pernoite');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-106' WHERE nomecampo = 'versao_banco';