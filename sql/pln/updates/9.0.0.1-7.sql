		--9.0.0.1-7
			DELETE FROM parametro WHERE chave = 'Pernoite na zona';
			UPDATE zona SET pernoite = false WHERE estrategia IN('ArrastaoPorGrupoInterior', 'ArrastaoPorGrupo') AND pernoite = true;

			INSERT INTO versaoBanco(versao) 
			VALUES ('9.0.0.1-7')
			ON CONFLICT (versao) 
			DO NOTHING;

