CREATE TABLE itinerario (
  id bigserial NOT NULL,
  id_itinerario character varying (30) NOT NULL,
  descricao character varying (100) NOT NULL,
  CONSTRAINT itinerario_pk PRIMARY KEY (id),
  CONSTRAINT itinerario_uk UNIQUE (id_itinerario)
);

COMMENT ON TABLE itinerario IS 'Tabela de itinerarios utilizada inicialmente para VOLTARANTIM';

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-45' WHERE nomecampo = 'versao_banco';