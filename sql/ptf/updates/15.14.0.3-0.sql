ALTER TABLE public.cliente
ADD CONSTRAINT cliente_codigocliente_unique UNIQUE (codigocliente);

CREATE TABLE IF NOT EXISTS public.cliente_atributos_temporarios (
    identificador VARCHAR(255) PRIMARY KEY,
    id_usuario BIGINT,
    datahora_importacao TIMESTAMP,
    codigocliente VARCHAR(255),
    status VARCHAR(255),
    datahora_aprovacao TIMESTAMP,
    datahora_reprovacao TIMESTAMP,
    centro VARCHAR(255),
    tempodeatendimento DOUBLE PRECISION,
    tempodeatendimento_old DOUBLE PRECISION,
    lat_tmp DOUBLE PRECISION,
    lng_tmp DOUBLE PRECISION,
    lat_tmp_old DOUBLE PRECISION,
    lng_tmp_old DOUBLE PRECISION,
    hora_cedo VARCHAR(6),
    hora_tarde VARCHAR(6),
    hora_cedo2 VARCHAR(6),
    hora_tarde2 VARCHAR(6),
    hora_cedo_old VARCHAR(6),
    hora_tarde_old VARCHAR(6),
    hora_cedo2_old VARCHAR(6),
    hora_tarde2_old VARCHAR(6),
   
    CONSTRAINT fk_cat_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES public.usuario(id)
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,

    CONSTRAINT fk_cat_cliente
        FOREIGN KEY (codigocliente)
        REFERENCES public.cliente(codigocliente)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS idx_cat_id_usuario
    ON public.cliente_atributos_temporarios (id_usuario);

CREATE INDEX IF NOT EXISTS idx_cat_codigocliente
    ON public.cliente_atributos_temporarios (codigocliente);

CREATE INDEX IF NOT EXISTS idx_cat_datahora_importacao
    ON public.cliente_atributos_temporarios (datahora_importacao);

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.3-0' WHERE nomecampo = 'versao_banco';