INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Desfaz Rota se Alguma Condicao de Frete Cadastrada?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', ''
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Desfaz Rota se Alguma Condicao de Frete Cadastrada?');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-86' WHERE nomecampo = 'versao_banco';