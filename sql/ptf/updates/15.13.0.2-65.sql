INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com Maximo KM por Zona?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Ao habilitar esse parâmetro a opção abaixo será exibidas na zona, caso não seja configurada nenhuma informação na zona, o sistema deverá considerar automaticamente o valor definido no parâmetro geral.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Maximo KM por Zona?');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-65' WHERE nomecampo = 'versao_banco';