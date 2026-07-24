INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com Rotas Noturnas?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', ''
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Rotas Noturnas?');

UPDATE public.configuracao SET valor_texto= 'v.15.13.1.0-28' WHERE nomecampo = 'versao_banco';