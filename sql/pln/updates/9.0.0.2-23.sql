CREATE TABLE IF NOT EXISTS public.vendedor_resumo (
				id BIGSERIAL PRIMARY KEY,
				simulacao_id BIGINT,
				vendedor_id BIGINT NOT NULL,
				total_clientes INT,
				total_km_planejado DOUBLE PRECISION DEFAULT 0,
				total_custo DOUBLE PRECISION DEFAULT 0, 
				media_km_dia DOUBLE PRECISION DEFAULT 0,

				CONSTRAINT fk_simulacao FOREIGN KEY (simulacao_id) REFERENCES simulacao(id) ON DELETE CASCADE,    
				CONSTRAINT fk_vendedor FOREIGN KEY (vendedor_id) REFERENCES vendedor(id) ON DELETE CASCADE
			);

			CREATE TABLE IF NOT EXISTS public.vendedor_resumo_exportado (
				id BIGSERIAL PRIMARY KEY, 
				vendedor_id BIGINT NOT NULL UNIQUE,
				simulacao_id BIGINT NOT NULL,
				nome_vendedor VARCHAR(100) NOT NULL,
				codigo_vendedor VARCHAR(100) NOT NULL,
				dia_exportacao TIMESTAMP NOT NULL,
				data_do_planejamento TIMESTAMP NOT NULL,
				usuario_que_exporto VARCHAR(50) NOT NULL,
				total_clientes INT,
				total_km_planejado DOUBLE PRECISION,
				total_custo DOUBLE PRECISION,
				media_km_dia DOUBLE PRECISION,
				
				CONSTRAINT fk_vendedor FOREIGN KEY (vendedor_id) REFERENCES vendedor(id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION,
				CONSTRAINT fk_simulacao FOREIGN KEY (simulacao_id) REFERENCES simulacao(id) ON DELETE CASCADE
			);

			ALTER TABLE simulacao  ADD COLUMN IF NOT EXISTS dia_exportacao TIMESTAMP NULL;
			ALTER TABLE simulacao  ADD COLUMN IF NOT EXISTS usuario_que_exporto VARCHAR(50);

			INSERT INTO versaoBanco(versao)
            VALUES ('9.0.0.2-23')
            ON CONFLICT (versao)
            DO NOTHING;