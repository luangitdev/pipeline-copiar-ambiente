-- ZADP
CREATE TABLE IF NOT EXISTS tabela_frete_zadp (
  id bigserial NOT NULL,
  id_deposito bigint NOT NULL, 
  termo_de_entrega character varying (3) NOT NULL,
  id_itinerario bigint NOT NULL,
  capacidade_veiculo double precision NOT NULL,
  numero_entregas integer NOT NULL,
  valor_fixo double precision NOT NULL,
  CONSTRAINT tabela_frete_zadp_fk PRIMARY KEY (id),
  CONSTRAINT tabela_frete_zadp_uk UNIQUE (id_deposito, termo_de_entrega, id_itinerario),
  FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_itinerario)
        REFERENCES public.itinerario (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE       
);

COMMENT ON TABLE public.tabela_frete_zadp
    IS 'Tabela de Frete ZADP - VOTORANTIM';

-- ZFIX
CREATE TABLE IF NOT EXISTS tabela_frete_zfix (
  id bigserial NOT NULL,
  id_deposito bigint NOT NULL, 
  id_grupo_produto bigint NOT NULL,
  termo_de_entrega character varying (3) NOT NULL,
  id_itinerario bigint NOT NULL,
  id_tipo_veiculo bigint NOT NULL,
  data_inicio date NOT NULL,
  data_fim date NOT NULL,
  tipo character varying (30) NOT NULL,
  CONSTRAINT tabela_frete_zfix_fk PRIMARY KEY (id),
  CONSTRAINT tabela_frete_zfix_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario, id_tipo_veiculo),
  FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_grupo_produto)
        REFERENCES public.grupoproduto (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,      
  FOREIGN KEY (id_itinerario)
        REFERENCES public.itinerario (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_tipo_veiculo)
        REFERENCES public.tipoveiculo (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE               
);

COMMENT ON TABLE public.tabela_frete_zfix
    IS 'Tabela de Frete ZFIX - VOTORANTIM'; 

CREATE TABLE IF NOT EXISTS tabela_frete_zfix_valores (
  id bigserial NOT NULL,
  id_zfix bigint NOT NULL,
  valor_frete double precision NOT NULL,
  FOREIGN KEY (id_zfix)
        REFERENCES public.tabela_frete_zfix (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE   
);  

-- 4RKM
CREATE TABLE IF NOT EXISTS tabela_frete_4rkm (
  id bigserial NOT NULL,
  id_deposito bigint NOT NULL, 
  id_grupo_produto bigint NOT NULL,
  termo_de_entrega character varying (3) NOT NULL,
  id_itinerario bigint NOT NULL,
  id_tipo_veiculo bigint NOT NULL,
  data_inicio date NOT NULL,
  data_fim date NOT NULL,
  tipo character varying (30) NOT NULL,
  km_minimo double precision NOT NULL,
  km_maximo double precision NOT NULL,
  valor_frete double precision NOT NULL,
  CONSTRAINT tabela_frete_4rkm_fk PRIMARY KEY (id),
  CONSTRAINT tabela_frete_4rkm_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario, id_tipo_veiculo),
  FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_grupo_produto)
        REFERENCES public.grupoproduto (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,      
  FOREIGN KEY (id_itinerario)
        REFERENCES public.itinerario (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_tipo_veiculo)
        REFERENCES public.tipoveiculo (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE       
);

COMMENT ON TABLE public.tabela_frete_4rkm
    IS 'Tabela de Frete 4RKM - VOTORANTIM'; 

-- ZFRL
CREATE TABLE IF NOT EXISTS tabela_frete_zfrl (
  id bigserial NOT NULL,
  id_deposito bigint NOT NULL, 
  id_grupo_produto bigint NOT NULL,
  termo_de_entrega character varying (3) NOT NULL,
  id_itinerario bigint NOT NULL,
  data_inicio date NOT NULL,
  data_fim date NOT NULL,
  tipo character varying (30) NOT NULL,
  CONSTRAINT tabela_frete_zfrl_fk PRIMARY KEY (id),
  CONSTRAINT tabela_frete_zfrl_uk UNIQUE (id_deposito, termo_de_entrega, id_grupo_produto, id_itinerario),
  FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_grupo_produto)
        REFERENCES public.grupoproduto (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,      
  FOREIGN KEY (id_itinerario)
        REFERENCES public.itinerario (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE       
);

COMMENT ON TABLE public.tabela_frete_zfrl
    IS 'Tabela de Frete ZFRL - VOTORANTIM'; 

CREATE TABLE IF NOT EXISTS tabela_frete_zfrl_valores (
  id bigserial NOT NULL,
  id_zfrl bigint NOT NULL,
  valor_frete double precision NOT NULL,
  FOREIGN KEY (id_zfrl)
        REFERENCES public.tabela_frete_zfrl (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE   
);      

-- 4AJD
CREATE TABLE IF NOT EXISTS tabela_frete_4ajd (
  id bigserial NOT NULL,
  id_deposito bigint NOT NULL, 
  termo_de_entrega character varying (3) NOT NULL,
  id_itinerario bigint NOT NULL,
  tipo character varying (30) NOT NULL,
  valor double precision NOT NULL,
  CONSTRAINT tabela_frete_4ajd_fk PRIMARY KEY (id),
  CONSTRAINT tabela_frete_4ajd_uk UNIQUE (id_deposito, termo_de_entrega, id_itinerario),
  FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  FOREIGN KEY (id_itinerario)
        REFERENCES public.itinerario (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE       
);

COMMENT ON TABLE public.tabela_frete_4ajd
    IS 'Tabela de Frete 4AJD - VOTORANTIM';
    
UPDATE public.configuracao SET valor_texto='v.15.13.0.0-68' WHERE nomecampo = 'versao_banco';