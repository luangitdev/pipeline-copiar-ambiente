ALTER TABLE rota_pedagio DROP CONSTRAINT IF EXISTS rota_pedagio_pk;
ALTER TABLE rota_pedagio ADD CONSTRAINT rota_pedagio_pk PRIMARY KEY (id_rota, id_pedagio, sentido);

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-10' WHERE nomecampo = 'versao_banco';