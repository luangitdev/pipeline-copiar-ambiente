-- DROP TABLE IF EXISTS frota_por_zona;
CREATE TABLE IF NOT EXISTS frota_por_zona (
   id bigserial NOT NULL,
   data_dia date NOT NULL,
   tipo_frota character varying(30) NOT NULL DEFAULT 'GERAL',
   zonas character varying(30) NULL,
   tipos_veiculo character varying(30) NOT NULL,
   qtde_frota integer NOT NULL,
   CONSTRAINT frota_por_zona_pk PRIMARY KEY(id),
   CONSTRAINT frota_por_zona_uk UNIQUE (data_dia, tipo_frota, zonas, tipos_veiculo)
);

DROP TABLE IF EXISTS zona_tipo_veiculo;

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-25' WHERE nomecampo = 'versao_banco';