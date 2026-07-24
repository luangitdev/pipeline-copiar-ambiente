ALTER TABLE eventos_simulacao ADD COLUMN IF NOT EXISTS origem_id bigint;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-77' WHERE nomecampo = 'versao_banco';