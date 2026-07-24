DROP TABLE IF EXISTS public.deposito_estoque;
CREATE TABLE IF NOT EXISTS public.deposito_estoque
(
  id bigserial NOT NULL,
    id_deposito bigint NOT NULL,
    id_produto bigint NOT NULL,
    id_grupo_produto bigint NOT NULL,
    quantidade integer NOT NULL,
    data date NOT NULL,
    CONSTRAINT deposito_estoque_pk PRIMARY KEY (id),
  CONSTRAINT deposito_estoque_uk UNIQUE (id_deposito, id_produto),
  CONSTRAINT depositoestoque_deposito_fk FOREIGN KEY (id_deposito)
        REFERENCES public.deposito (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  CONSTRAINT depositoestoque_produto_fk FOREIGN KEY (id_produto)
        REFERENCES public.produto (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
  CONSTRAINT depositoestoque_grupoproduto_fk FOREIGN KEY (id_grupo_produto)
        REFERENCES public.grupoproduto (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
);

COMMENT ON TABLE public.deposito_estoque
    IS 'Tabela de estroque por deposito';

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-48' WHERE nomecampo = 'versao_banco';