INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Versao Layout Interface M62', 
  CASE 
    WHEN (SELECT valor from parametro where chave = 'Trabalha com Interface M62 V2?') = 'SIM' THEN 2
    ELSE 1
  END AS valor, 'INTEGER', false, false, 'INTEGRACAO', 'PARCEIROS', 'Modifca o layout de envio para Infolog.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Versao Layout Interface M62');

DELETE FROM parametro WHERE chave = 'Trabalha com Interface M62 V2?';

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-62' WHERE nomecampo = 'versao_banco';