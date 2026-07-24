			--9.0.1.1-24
				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('monitoramento-user', 'Monitoramento', true, 'STRING', 0, 'admin')
				ON CONFLICT (nomecampo) 
				DO NOTHING;

				INSERT INTO configuracao (nomecampo, nometela, selecionado, tipo, valor, valor_texto) 
				VALUES ('monitoramento-password', 'Monitoramento', true, 'STRING', 0, 'f!ndP4th$')
				ON CONFLICT (nomecampo) 
				DO NOTHING;

				ALTER TABLE usuario ADD COLUMN IF NOT EXISTS integracao_monitoramento_falhou BOOLEAN NOT NULL DEFAULT FALSE;

                INSERT INTO versaoBanco(versao)
                VALUES ('9.0.1.1-24')
                ON CONFLICT (versao)
                DO NOTHING;