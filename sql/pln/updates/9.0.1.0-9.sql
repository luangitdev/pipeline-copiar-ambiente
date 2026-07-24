            --9.0.1.0-9
                ALTER TABLE centrodistribuicao DROP COLUMN IF EXISTS codigo;
				
				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.1.0-9')
				ON CONFLICT (versao)
				DO NOTHING;