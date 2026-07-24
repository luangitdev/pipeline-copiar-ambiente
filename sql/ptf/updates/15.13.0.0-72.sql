ALTER TABLE pedido_propriedade ADD COLUMN IF NOT EXISTS valor_date date;

ALTER TABLE rota_propriedade ADD COLUMN IF NOT EXISTS valor_date date;

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Utiliza Data e Hora Carregamento no pedido?', 'NAO', 'BOOLEAN', true, false, 'PREFERENCIAS', 'GERAL'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Utiliza Data e Hora Carregamento no pedido?');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Utiliza Data e Hora Carregamento na rota?', 'NAO', 'BOOLEAN', true, false, 'PREFERENCIAS', 'GERAL'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Utiliza Data e Hora Carregamento na rota?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-72' WHERE nomecampo = 'versao_banco';