INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com munck?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, considera o Munck vinculado ao pedido.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com munck?');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Permite mesclagem de munck?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, define se é possível alocar, em uma mesma rota, pedidos com e sem munck.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Permite mesclagem de munck?');

ALTER TABLE frota_por_zona ADD IF NOT EXISTS munck BOOLEAN DEFAULT FALSE;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-85' WHERE nomecampo = 'versao_banco';