INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Ocupacao Minima para Carga Fechada', '0', 'STRING', true, false, 'INTEGRACAO', 'PARCEIROS', 'Criado para definir um valor de ocupação minima ao simular com Carga Fechada. Ex.: 95 ou 95,0 para definir 95%.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Ocupacao Minima para Carga Fechada');

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.0-34' WHERE nomecampo = 'versao_banco';