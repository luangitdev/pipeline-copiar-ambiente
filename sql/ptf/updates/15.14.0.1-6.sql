INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto)
SELECT 'politica-senha-mfa-unico', 'politica-senha', true, 'BOOLEAN', 0, 'NAO' 
WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'politica-senha-mfa-unico' and nometela = 'politica-senha');

INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor, valor_texto)
SELECT 'politica-senha-mfa-unico-url', 'politica-senha', true, 'STRING', 0, 'http://34.151.197.190:3001' 
WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'politica-senha-mfa-unico-url' and nometela = 'politica-senha');

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.1-6' WHERE nomecampo = 'versao_banco';