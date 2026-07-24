INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Url do Gerador de ID Unico', 'http://localhost:8083/api/v1/gerarId', 'STRING', true, false, 'INTEGRACAO', 'PARCEIROS', 'URL do gerador únido de ID para uso no multibanco'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Url do Gerador de ID Unico');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-70' WHERE nomecampo = 'versao_banco';