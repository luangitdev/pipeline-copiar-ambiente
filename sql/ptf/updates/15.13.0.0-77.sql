ALTER TABLE tabela_frete_zfix DROP CONSTRAINT IF EXISTS tabela_frete_zfix_uk;
ALTER TABLE tabela_frete_zfix ADD CONSTRAINT tabela_frete_zfix_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario, id_tipo_veiculo, data_inicio, data_fim, tipo);

ALTER TABLE tabela_frete_zfrl DROP CONSTRAINT IF EXISTS tabela_frete_zfrl_uk;
ALTER TABLE tabela_frete_zfrl ADD CONSTRAINT tabela_frete_zfrl_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario, data_inicio, data_fim, tipo);

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-77' WHERE nomecampo = 'versao_banco';