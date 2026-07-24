INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com Estoque no Deposito?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando HABILITADO, Envia para o PWS o estoque de produtos do Deposito.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Estoque no Deposito?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-50' WHERE nomecampo = 'versao_banco';