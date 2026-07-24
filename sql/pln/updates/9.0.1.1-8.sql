				--9.0.1.1-8
				ALTER TABLE control_tower
					ADD COLUMN IF NOT EXISTS semana VARCHAR(10) NOT NULL DEFAULT 'PRIMEIRA',
					ADD COLUMN IF NOT EXISTS dia VARCHAR(10) NOT NULL DEFAULT 'SEGUNDA',
					ADD COLUMN IF NOT EXISTS mes INTEGER NOT NULL DEFAULT 1;


				-- Atualiza os campos extraídos de nome_rota
				UPDATE control_tower
				SET
					dia = CASE
						when nome_rota ~* 'Segunda' THEN 'SEGUNDA'
						WHEN nome_rota ~* 'terça-feira' THEN 'TERCA'
						WHEN nome_rota ~* 'quarta-feira' THEN 'QUARTA'
						WHEN nome_rota ~* 'quinta-feira' THEN 'QUINTA'
						WHEN nome_rota ~* 'sexta-feira' THEN 'SEXTA'
						WHEN nome_rota ~* 'sábado' THEN 'SABADO'
						WHEN nome_rota ~* 'domingo' THEN 'DOMINGO'
						ELSE NULL
					END,

					semana = CASE
						WHEN nome_rota ~* '1ª\s+Semana' THEN 'PRIMEIRA'
						WHEN nome_rota ~* '2ª\s+Semana' THEN 'SEGUNDA'
						WHEN nome_rota ~* '3ª\s+Semana' THEN 'TERCEIRA'
						WHEN nome_rota ~* '4ª\s+Semana' THEN 'QUARTA'
						WHEN nome_rota ~* '5ª\s+Semana' THEN 'QUINTA'
						ELSE NULL
					END,

					mes = CAST(REGEXP_REPLACE(nome_rota, '.*Mês\s+([0-9]+).*', '\1') AS INTEGER)
				WHERE nome_rota IS NOT NULL;

				ALTER TABLE control_tower  DROP COLUMN IF EXISTS nome_rota;


				INSERT INTO versaoBanco(versao)
				VALUES ('9.0.1.1-8')
				ON CONFLICT (versao)
				DO NOTHING;