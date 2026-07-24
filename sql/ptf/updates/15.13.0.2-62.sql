ALTER TABLE eventos_simulacao ALTER COLUMN data_evento SET DEFAULT now();
ALTER TABLE eventos_simulacao ALTER COLUMN data_evento TYPE timestamp;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-62' WHERE nomecampo = 'versao_banco';