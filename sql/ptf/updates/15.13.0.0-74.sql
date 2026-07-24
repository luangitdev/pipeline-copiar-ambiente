ALTER TABLE tabela_frete_zadp DROP CONSTRAINT IF EXISTS tabela_frete_zadp_uk;
ALTER TABLE tabela_frete_zadp ADD CONSTRAINT tabela_frete_zadp_uk UNIQUE (id_deposito, termo_de_entrega, id_itinerario, capacidade_veiculo, numero_entregas);

ALTER TABLE tabela_frete_zfix ADD IF NOT EXISTS valor_frete double precision DEFAULT 0;

ALTER TABLE tabela_frete_zfrl ADD IF NOT EXISTS valor_frete double precision DEFAULT 0;

ALTER TABLE tabela_frete_4rkm DROP CONSTRAINT IF EXISTS tabela_frete_4rkm_uk;
ALTER TABLE tabela_frete_4rkm ADD CONSTRAINT tabela_frete_4rkm_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario, id_tipo_veiculo, data_inicio, data_fim, tipo, km_minimo, km_maximo);

DROP TABLE IF EXISTS tabela_frete_zfix_valores;
DROP TABLE IF EXISTS tabela_frete_zfrl_valores;

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-74' WHERE nomecampo = 'versao_banco';