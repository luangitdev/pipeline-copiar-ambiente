ALTER TABLE rota_noturna ADD COLUMN inicio_noturno timestamp without time zone;
ALTER TABLE rota_noturna ADD COLUMN fim_noturno timestamp without time zone;
ALTER TABLE rota_noturna ADD COLUMN id_zona_simulacao bigint;

ALTER TABLE rota_noturna ADD CONSTRAINT fk_id_zona_simulacao
FOREIGN KEY (id_zona_simulacao) REFERENCES zona(id);

ALTER TABLE tipoveiculo ADD COLUMN IF NOT EXISTS tipo_atendimento character varying(50);


UPDATE public.configuracao SET valor_texto= 'v.15.14.0.0-1' WHERE nomecampo = 'versao_banco';