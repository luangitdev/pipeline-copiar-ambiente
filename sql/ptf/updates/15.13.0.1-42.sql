CREATE TABLE IF NOT EXISTS veiculo_propriedade (
    parente_id BIGSERIAL NOT NULL,
    campo CHARACTER VARYING(30) NOT NULL,
    valor_string CHARACTER VARYING(255),
    valor_long BIGINT,
    valor_number DOUBLE PRECISION,
    valor_boolean BOOLEAN,
    valor_date date,
    tipo_campo CHAR(1) DEFAULT 'S',
    CONSTRAINT veiculo_propriedade_pk PRIMARY KEY (parente_id, campo),
    CONSTRAINT veiculo_propriedade_fk FOREIGN KEY (parente_id)
        REFERENCES veiculo (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE public.veiculo_propriedade IS 'Tabela de campos/valores adicionados por novas funcionalidades';

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-42' WHERE nomecampo = 'versao_banco';