CREATE TABLE IF NOT EXISTS deposito_estoque (
  id_deposito bigint NOT NULL,
  id_produto bigint NOT NULL,
  id_grupo_produto bigint NOT NULL,
  quantidade bigint NOT NULL,
  data date NOT NULL, 
  CONSTRAINT deposito_estoque_pk PRIMARY KEY (id_deposito, id_produto)  
);

COMMENT ON TABLE public.deposito_estoque
    IS 'Tabela de estroque por deposito';

UPDATE public.configuracao SET valor_texto='v.15.13.0.0-34' WHERE nomecampo = 'versao_banco';