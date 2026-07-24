INSERT INTO configuracao(nomecampo, nometela, selecionado, tipo, valor) 
SELECT 'Especialidade', 'imprimirRota', true, 'BOOLEAN', 0 WHERE NOT EXISTS (SELECT 1 FROM configuracao WHERE nomecampo = 'Especialidade' and nometela = 'imprimirRota' );
UPDATE public.configuracao SET valor_texto='v.15.13.0.0-18' WHERE nomecampo = 'versao_banco';
