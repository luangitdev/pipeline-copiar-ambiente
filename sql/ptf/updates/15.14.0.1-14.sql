INSERT INTO parametro (chave, valor, ordem, parametro_sistema, tipo_parametro, observacao, oculto, grupo, subgrupo)
SELECT 
    'Trabalha com Balsas no Mapa?', 'NAO', 0, TRUE, 'BOOLEAN', 
    'Quando ativo, possibilita o uso do cadastro de pontos de travessia de Balsas', FALSE, 'JORNADA', 'EXPEDIENTE'
WHERE NOT EXISTS (
    SELECT 1 FROM parametro WHERE chave = 'Trabalha com Balsas no Mapa?'
);



UPDATE public.configuracao SET valor_texto= 'v.15.14.0.1-14' WHERE nomecampo = 'versao_banco';