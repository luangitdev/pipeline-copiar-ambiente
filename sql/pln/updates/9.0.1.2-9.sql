	--9.0.1.2
				--9.0.1.2-9
				ALTER TABLE simulacao DROP COLUMN IF EXISTS erroSimulacao;

				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.1.2-9')
				ON CONFLICT (versao)
				DO NOTHING;