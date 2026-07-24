CREATE TABLE IF NOT EXISTS pontuacao_chapa (
	id bigserial NOT NULL,
	sim_pontos integer NOT NULL,
	nao_pontos integer NOT NULL,
	CONSTRAINT pontuacao_chapa_pk PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS pontuacao_numero_paradas (
	id bigserial NOT NULL,
	numero_paradas integer NOT NULL UNiQUE,
	pontos integer NOT NULL,
	CONSTRAINT pontuacao_numero_paradas_pk PRIMARY KEY (id),
	CONSTRAINT pontuacao_numero_paradas_uk UNIQUE (numero_paradas)
);

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-18' WHERE nomecampo = 'versao_banco';