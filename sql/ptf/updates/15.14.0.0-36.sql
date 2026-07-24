CREATE TABLE IF NOT EXISTS tabela_frete_05 (
    id BIGSERIAL PRIMARY KEY,
    codigo INTEGER,
    descricao VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS tabela_frete_item_05 (
    id BIGSERIAL PRIMARY KEY,

    tabela_frete_05_id BIGINT NOT NULL,
    tipo_veiculo_id BIGINT NOT NULL,

    qtde_entregas_minimo INTEGER,
    km_minimo DOUBLE PRECISION,
    custo_por_km DOUBLE PRECISION,
    custo_extra_por_km DOUBLE PRECISION,
    custo_adc_por_entrega DOUBLE PRECISION,
    custo_diaria_apos_24_horas DOUBLE PRECISION,

    CONSTRAINT fk_tabela_frete_05
        FOREIGN KEY (tabela_frete_05_id)
        REFERENCES tabela_frete_05 (id)
        ON DELETE CASCADE,

    CONSTRAINT fk_tipo_veiculo
        FOREIGN KEY (tipo_veiculo_id)
        REFERENCES tipoveiculo (id),

    CONSTRAINT uk_tabela_frete_05_tipo_veiculo
        UNIQUE (tabela_frete_05_id, tipo_veiculo_id)
);


ALTER TABLE cenario ADD COLUMN IF NOT EXISTS id_tabela_frete_05 BIGINT;
ALTER TABLE rota ADD COLUMN IF NOT EXISTS check_percentual DOUBLE PRECISION;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_cenario_tabela_frete_05'
    ) THEN
        ALTER TABLE cenario
        ADD CONSTRAINT fk_cenario_tabela_frete_05
        FOREIGN KEY (id_tabela_frete_05)
        REFERENCES tabela_frete_05 (id)
        ON DELETE SET NULL;
    END IF;
END$$;

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.0-36' WHERE nomecampo = 'versao_banco';