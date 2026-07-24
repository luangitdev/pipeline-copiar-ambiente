INSERT INTO parametro (chave, valor, ordem, parametro_sistema, tipo_parametro, observacao, oculto, grupo, subgrupo)
SELECT 
    'Utiliza Retroalimentacao Fretefy?', 'NAO', 0, TRUE, 'BOOLEAN',
    'Habilita/desabilita a exibicao do item de Retroalimentação do menu principal', FALSE, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (
    SELECT 1 FROM parametro WHERE chave = 'Utiliza Retroalimentacao Fretefy?'
);

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.3-7' WHERE nomecampo = 'versao_banco';