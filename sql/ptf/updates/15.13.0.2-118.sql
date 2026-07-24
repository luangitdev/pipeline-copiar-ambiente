ALTER TABLE frota_por_zona ALTER COLUMN zonas TYPE character varying(4000);

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-118' WHERE nomecampo = 'versao_banco';