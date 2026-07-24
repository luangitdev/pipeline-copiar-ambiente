INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo)
SELECT 'Utiliza Prioridade pela Data do Pedido e Data de Saida?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Utiliza Prioridade pela Data do Pedido e Data de Saida?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-27' WHERE nomecampo = 'versao_banco';
