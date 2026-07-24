ALTER TABLE frota_por_zona ALTER COLUMN zonas TYPE character varying(255), ALTER COLUMN tipos_veiculo TYPE character varying(255);

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-32' WHERE nomecampo = 'versao_banco';