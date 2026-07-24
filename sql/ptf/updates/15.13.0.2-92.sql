INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Ocupacao Maxima do Veiculo', '0', 'NUMBER', true, false, 'INTEGRACAO', 'PARCEIROS', ''
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Ocupacao Maxima do Veiculo');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-92' WHERE nomecampo = 'versao_banco';
