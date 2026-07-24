CREATE TABLE IF NOT EXISTS public.rota_noturna
(
    id bigserial NOT NULL,
    nome character varying(255) COLLATE pg_catalog."default",
    identificador integer,
    inicio timestamp without time zone,
    fim timestamp without time zone,    
  mesclagem_cliente boolean DEFAULT false,
    CONSTRAINT rota_noturna_pk PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS public.rota_noturna_zona
(
    id_rota_noturna bigint NOT NULL,
  id_zona bigint NOT NULL,
  CONSTRAINT rota_noturna_zona_pk PRIMARY KEY (id_rota_noturna, id_zona),
    CONSTRAINT rotanoturnazona_rotanoturna_fk FOREIGN KEY (id_rota_noturna)
        REFERENCES public.rota_noturna (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT rotanoturnazona_zona_fk FOREIGN KEY (id_zona)
        REFERENCES public.zona (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION 
);

UPDATE public.configuracao SET valor_texto= 'v.15.13.1.0-26' WHERE nomecampo = 'versao_banco';