ALTER TABLE item ADD IF NOT EXISTS seq_item integer DEFAULT 0;
ALTER TABLE eventos_simulacao ALTER COLUMN tipo_evento TYPE character varying(255);

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-58' WHERE nomecampo = 'versao_banco';