            --9.0.1.1-2
                ALTER TABLE VENDEDOR DROP COLUMN IF EXISTS telefone;

                ALTER TABLE VENDEDOR ADD COLUMN IF NOT EXISTS ddi CHARACTER VARYING(5);
                ALTER TABLE VENDEDOR ADD COLUMN IF NOT EXISTS telefone CHARACTER VARYING(20);

                INSERT INTO versaoBanco(versao)
                VALUES ('9.0.1.1-2')
                    ON CONFLICT (versao)
                DO NOTHING;