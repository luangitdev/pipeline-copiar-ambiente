ALTER TABLE log_kettle ADD IF NOT EXISTS client character varying(255);
ALTER TABLE eventos_simulacao ADD IF NOT EXISTS identificador bigint;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-101' WHERE nomecampo = 'versao_banco';