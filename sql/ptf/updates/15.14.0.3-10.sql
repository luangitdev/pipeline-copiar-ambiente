INSERT INTO parametro (chave, valor, ordem, parametro_sistema, tipo_parametro, observacao, oculto, grupo, subgrupo)
SELECT 
    'Trabalha com integracao de disponibilidade de veiculos Fretefy?', 'NAO', 0, TRUE, 'BOOLEAN',
    'Habilita/desabilita a exibicao do item de verificar disponibilidade no filtro de veiculos na simulacao', FALSE, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (
    SELECT 1 FROM parametro WHERE chave = 'Trabalha com integracao de disponibilidade de veiculos Fretefy?'
);

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.3-10' WHERE nomecampo = 'versao_banco';