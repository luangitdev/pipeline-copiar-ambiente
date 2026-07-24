CREATE TABLE IF NOT EXISTS tipo_embalagem (
  id bigserial NOT NULL,
  descricao character varying (30) NOT NULL,
  CONSTRAINT tipo_embalagem_pk PRIMARY KEY (id)
);

INSERT INTO tipo_embalagem (id, descricao) VALUES (1, 'Caixa');
INSERT INTO tipo_embalagem (id, descricao) VALUES (2, 'Unidade');
INSERT INTO tipo_embalagem (id, descricao) VALUES (3, 'Outros');
INSERT INTO tipo_embalagem (id, descricao) VALUES (4, 'Conjunto');
INSERT INTO tipo_embalagem (id, descricao) VALUES (5, 'Display');
INSERT INTO tipo_embalagem (id, descricao) VALUES (6, 'PC');
INSERT INTO tipo_embalagem (id, descricao) VALUES (7, 'S01');
INSERT INTO tipo_embalagem (id, descricao) VALUES (8, 'S05');
INSERT INTO tipo_embalagem (id, descricao) VALUES (9, 'S08');
INSERT INTO tipo_embalagem (id, descricao) VALUES (10, 'S20');
INSERT INTO tipo_embalagem (id, descricao) VALUES (11, 'S25');
INSERT INTO tipo_embalagem (id, descricao) VALUES (12, 'S40');
INSERT INTO tipo_embalagem (id, descricao) VALUES (13, 'S50');

ALTER TABLE produto RENAME COLUMN tp_embalagem to id_tipo_embalagem;

UPDATE produto SET id_tipo_embalagem = (
    SELECT te.id FROM tipo_embalagem te JOIN produto p on (UPPER(te.descricao)=UPPER(p.descricao))
);

ALTER TABLE produto ALTER COLUMN id_tipo_embalagem TYPE BIGINT USING id_tipo_embalagem::bigint;
ALTER TABLE produto ADD CONSTRAINT fk_tipo_embalagem FOREIGN KEY (id_tipo_embalagem) REFERENCES tipo_embalagem(id);


UPDATE public.configuracao SET valor_texto='v.15.13.0.1-0' WHERE nomecampo = 'versao_banco';