	--9.0.0.2-0
			UPDATE parametro
			SET deconfiguracao = false, desistema = false, valor = 'NÃO', observacao = 'desabilitar o parametro por solicitação do PO versão:9.0.0.2-0 '
			WHERE chave = 'Funciona no domingo?';

			INSERT INTO versaoBanco(versao)
			VALUES ('9.0.0.2-0')
			ON CONFLICT (versao)
			DO NOTHING;