ALTER TABLE frota_por_zona DROP IF EXISTS tipo_frota, DROP IF EXISTS tipos_veiculo;
ALTER TABLE frota_por_zona DROP IF EXISTS qtde_frota, DROP IF EXISTS data_dia;
ALTER TABLE frota_por_zona ADD IF NOT EXISTS data_inicio date, ADD IF NOT EXISTS data_fim date, ADD IF NOT EXISTS prioridade boolean DEFAULT false;
ALTER TABLE frota_por_zona ADD IF NOT EXISTS qtde_basal integer, ADD IF NOT EXISTS qtde_atual integer, ADD IF NOT EXISTS id_tipo_veiculo bigint;

ALTER TABLE frota_por_zona DROP CONSTRAINT IF EXISTS frota_por_zona_tipo_veiculo_fk;

ALTER TABLE frota_por_zona ADD CONSTRAINT frota_por_zona_tipo_veiculo_fk FOREIGN KEY (id_tipo_veiculo)
        REFERENCES public.tipoveiculo (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-46' WHERE nomecampo = 'versao_banco';