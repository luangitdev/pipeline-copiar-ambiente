            --9.0.1.1-14
                ALTER TABLE vendedor_resumo_exportado ADD COLUMN IF NOT EXISTS nome_vendedor VARCHAR(255);

                INSERT INTO versaoBanco(versao)
                VALUES ('9.0.1.1-14')
                    ON CONFLICT (versao)
                DO NOTHING;