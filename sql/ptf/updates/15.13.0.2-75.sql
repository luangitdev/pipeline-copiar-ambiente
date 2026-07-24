INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com chapa?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, considera o Chapa vinculado ao pedido.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com chapa?');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Permite mesclagem de chapa?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, define se é possível alocar, em uma mesma rota, pedidos com e sem chapa.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Permite mesclagem de chapa?');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-75' WHERE nomecampo = 'versao_banco';
