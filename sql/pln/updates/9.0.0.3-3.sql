            -- 9.0.0.3-3
				ALTER TABLE vendedor_resumo_exportado DROP COLUMN IF EXISTS nome_vendedor;
				ALTER TABLE vendedor_resumo_exportado DROP COLUMN IF EXISTS codigo_vendedor;

				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.0.3-3')
				ON CONFLICT (versao)
				DO NOTHING;