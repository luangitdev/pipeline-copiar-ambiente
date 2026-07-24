INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com Antecipacao de Pedido?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, envia para o PWS o dado de dia de antecipação do pedido ou cliente, subtraindo este da diferença da data de entrega - data de saída. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Antecipacao de Pedido?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-35' WHERE nomecampo = 'versao_banco';