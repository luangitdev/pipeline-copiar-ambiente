ALTER TABLE pedagio ADD IF NOT EXISTS status character varying(7) DEFAULT 'ATIVO';
ALTER TABLE pedagio ADD IF NOT EXISTS concessionaria character varying(255);

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, observacao)
SELECT 'Trabalha com Integracao Pedagio MoveMais?', 'NAO', 'BOOLEAN', true, 'Quando HABILITADO, será exibido na tela de pedágio o link de integração da MoveMais.'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com Integracao Pedagio MoveMais?');

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-8' WHERE nomecampo = 'versao_banco';