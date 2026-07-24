				--9.0.1.1-28
				ALTER TABLE vendedor_resumo_exportado DROP COLUMN IF EXISTS nome_vendedor;

				ALTER TABLE vendedor ADD COLUMN IF NOT EXISTS nome_antigo VARCHAR(255);

				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.1.1-28')
				ON CONFLICT (versao)
				DO NOTHING;
	--9.0.1.2