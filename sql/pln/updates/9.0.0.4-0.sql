			-- 9.0.0.4-0
				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('controltower-uri', 'control tower', true, 'STRING', 0, 'http://10.0.225.5:9090/api')
				ON CONFLICT (nomecampo) 
				DO NOTHING;
				--URL DE ACESSO EXTERNO 
				--UPDATE configuracao SET valor_texto = 'http://34.39.154.90:9590/api' WHERE nomecampo = 'controltower-uri';

				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('controltower-user', 'control tower', true, 'STRING', 0, 'roteirizador.path')
				ON CONFLICT (nomecampo) 
				DO NOTHING;

				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('controltower-password', 'control tower', true, 'STRING', 0, 'f!ndP4th$')
				ON CONFLICT (nomecampo) 
				DO NOTHING;

				INSERT INTO parametro (chave, valor, desistema, deconfiguracao, tipo_parametro, observacao) 
				VALUES ('Utiliza Control Tower?', 'NÃO', true, false, 'BOOLEAN', 'Habilita a integração do sistema com o Control Tower.')
				ON CONFLICT (chave) 
				DO NOTHING;

				ALTER TABLE vendedor ADD COLUMN IF NOT EXISTS idapp CHARACTER VARYING(255);

				ALTER TABLE vendedor ADD COLUMN IF NOT EXISTS gerente CHARACTER VARYING(255);
				ALTER TABLE vendedor ADD COLUMN IF NOT EXISTS supervisor CHARACTER VARYING(255);

				ALTER TABLE cliente ADD COLUMN IF NOT EXISTS telefone CHARACTER VARYING(255);
				ALTER TABLE cliente ADD COLUMN IF NOT EXISTS atividade CHARACTER VARYING(255);

				CREATE TABLE IF NOT EXISTS public.control_tower (
					id BIGSERIAL PRIMARY KEY,
					simulacao_id BIGINT NOT NULL,
					vendedor_id BIGINT NOT NULL,
					rota_id BIGINT NOT NULL,
					control_tower_id VARCHAR(150) NOT NULL,
					nome_rota VARCHAR(150) NOT NULL,
					data_rota DATE NOT NULL,
					data_exportacao TIMESTAMP NOT NULL,
					
					CONSTRAINT fk_vendedor FOREIGN KEY (vendedor_id) REFERENCES vendedor (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
					CONSTRAINT fk_simulacao FOREIGN KEY (simulacao_id) REFERENCES simulacao (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION
				);

				ALTER TABLE vendedor ADD COLUMN IF NOT EXISTS telefone CHARACTER VARYING(25);

				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('monitoramento-uri', 'monitoramento', true, 'STRING', 0, 'http://10.0.225.5:9593/api')
				ON CONFLICT (nomecampo) 
				DO NOTHING;

				--URL DE ACESSO EXTERNO 
				--UPDATE configuracao SET valor_texto = 'http://34.39.154.90:9593/api' WHERE nomecampo = 'monitoramento-uri';

				ALTER TABLE USUARIO ADD COLUMN IF NOT EXISTS monitoramento_visitas BOOLEAN NOT NULL DEFAULT false;

				UPDATE tipoveiculo SET especieveiculo = 0 WHERE especieveiculo IN(0, 1, 2, 4, 5);
				UPDATE tipoveiculo SET especieveiculo = 1 WHERE especieveiculo = 3;

				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.0.4-0')
				ON CONFLICT (versao)
				DO NOTHING;
