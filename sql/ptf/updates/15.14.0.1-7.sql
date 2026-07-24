INSERT INTO parametro (chave, valor, ordem, parametro_sistema, tipo_parametro, observacao, oculto, grupo, subgrupo)
SELECT 
    'Trabalha com Integracao Middleware Fretefy?', 'NAO', 0, TRUE, 'BOOLEAN', 
    'Ativa botão ao lado de liberar para enviar as simulações em tela', FALSE, 'INTEGRACAO', 'PARCEIROS'
WHERE NOT EXISTS (
    SELECT 1 FROM parametro WHERE chave = 'Trabalha com Integracao Middleware Fretefy?'
);

INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto)
SELECT
  'fretefy-middleware-endpoint',
  'fretefy',
  true,
  'STRING',
  0,
  'https://ffy-flows.azurewebsites.net/api/castropil/pathdfind-webhook'
WHERE NOT EXISTS (
  SELECT 1 FROM configuracao WHERE nomecampo = 'fretefy-middleware-endpoint'
);

INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto)
SELECT
  'fretefy-middleware-basic-auth',
  'fretefy',
  true,
  'STRING',
  0,
  '25655cf4-593b-4b75-8054-637ecc760db5'
WHERE NOT EXISTS (
  SELECT 1 FROM configuracao WHERE nomecampo = 'fretefy-middleware-basic-auth'
);

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.1-7' WHERE nomecampo = 'versao_banco';