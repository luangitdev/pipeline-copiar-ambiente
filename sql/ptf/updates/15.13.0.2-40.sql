CREATE TABLE IF NOT EXISTS pontuacao_segmento (
	id BIGSERIAL PRIMARY KEY,
	id_segmento BIGINT,
	pontos SMALLINT NOT NULL,
	
	CONSTRAINT id_segmento_fk FOREIGN KEY (id_segmento) REFERENCES segmentoentrega(id)
		ON DELETE CASCADE
);

ALTER TABLE pontuacao_segmento DROP CONSTRAINT IF EXISTS pontuacao_segmento_id_segmento_uk;
ALTER TABLE pontuacao_segmento ADD CONSTRAINT pontuacao_segmento_id_segmento_uk UNIQUE (id_segmento);

ALTER TABLE pontuacao ADD IF NOT EXISTS segmento BOOLEAN, ADD IF NOT EXISTS porcentagem_segmento DOUBLE PRECISION;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-40' WHERE nomecampo = 'versao_banco';