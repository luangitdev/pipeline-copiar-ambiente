ALTER TABLE endereco ADD IF NOT EXISTS sigla_pais character varying(2);

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-51' WHERE nomecampo = 'versao_banco';