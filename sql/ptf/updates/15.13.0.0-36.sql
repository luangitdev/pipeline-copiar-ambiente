CREATE TABLE IF NOT EXISTS eventos_simulacao (
  id bigserial NOT NULL,
  tipo_evento character varying (20) NOT NULL, 
  data_evento date NOT NULL,
  payload_evento text NOT NULL,
  status_evento character varying (30) NOT NULL,
  versao_endpoint character varying (100) NOT NULL, 
  CONSTRAINT eventos_simulacao_pk PRIMARY KEY (id)
);

COMMENT ON TABLE public.eventos_simulacao
    IS 'Tabela de eventos assincronos de simulacao/reprocessamento';

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-36' WHERE nomecampo = 'versao_banco';