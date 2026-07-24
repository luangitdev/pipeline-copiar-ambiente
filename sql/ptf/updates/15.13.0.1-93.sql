CREATE TABLE IF NOT EXISTS pontuacao_itinerario (
  id BIGSERIAL PRIMARY KEY,
  id_itinerario BIGINT,
  pontos SMALLINT NOT NULL,
  
  CONSTRAINT id_itinerario_fk FOREIGN KEY (id_itinerario) REFERENCES itinerario(id)
    ON DELETE CASCADE
);

ALTER TABLE pontuacao_itinerario DROP CONSTRAINT IF EXISTS pontuacao_itinerario_id_itinerario_uk;
ALTER TABLE pontuacao_itinerario ADD CONSTRAINT pontuacao_itinerario_id_itinerario_uk UNIQUE (id_itinerario);


-----------------------------------------


CREATE TABLE IF NOT EXISTS pontuacao_cliente (
  id BIGSERIAL PRIMARY KEY,
  id_cliente BIGINT,
  pontos SMALLINT NOT NULL,
  
  CONSTRAINT id_cliente_fk FOREIGN KEY (id_cliente) REFERENCES cliente(id)
    ON DELETE CASCADE
);

ALTER TABLE pontuacao_cliente DROP CONSTRAINT IF EXISTS pontuacao_cliente_id_cliente_uk;
ALTER TABLE pontuacao_cliente ADD CONSTRAINT pontuacao_cliente_id_cliente_uk UNIQUE (id_cliente);


CREATE TABLE IF NOT EXISTS pontuacao_adicional (
    id BIGSERIAL PRIMARY KEY,
    tipo VARCHAR(255),
    valor VARCHAR(255)
);

ALTER TABLE pontuacao_adicional DROP CONSTRAINT IF EXISTS pontuacao_adicional_tipo_valor_uk;
ALTER TABLE pontuacao_adicional ADD CONSTRAINT pontuacao_adicional_tipo_valor_uk UNIQUE (tipo, valor);



CREATE TABLE IF NOT EXISTS pontuacao_cidade (
  id BIGSERIAL PRIMARY KEY,
  id_cidade BIGINT,
  pontos SMALLINT NOT NULL,
  
  CONSTRAINT id_cidade_fk FOREIGN KEY (id_cidade) REFERENCES cidade(id)
    ON DELETE CASCADE
);

ALTER TABLE pontuacao_cidade DROP CONSTRAINT IF EXISTS pontuacao_cidade_id_cidade_uk;
ALTER TABLE pontuacao_cidade ADD CONSTRAINT pontuacao_cidade_id_cidade_uk UNIQUE (id_cidade);



DROP TABLE IF EXISTS pontuacao;

CREATE TABLE IF NOT EXISTS pontuacao (
    id BIGSERIAL PRIMARY KEY,
    
    id_centro BIGINT,
  
    itinerario BOOLEAN,
  porcentagem_itinerario DOUBLE PRECISION,

  cliente BOOLEAN,
    porcentagem_cliente DOUBLE PRECISION,

  cidade_entrega BOOLEAN,
    porcentagem_cidade_entrega DOUBLE PRECISION,

    chapa BOOLEAN,
    pontos_chapa INTEGER,
    porcentagem_chapa DOUBLE PRECISION,
  
    id_numero_paradas BIGINT,
    pontos_numero_paradas INTEGER,
    porcentagem_numero_paradas DOUBLE PRECISION,
    
    id_custo_rota BIGINT,
    pontos_custo_rota INTEGER,
    porcentagem_custo_rota DOUBLE PRECISION,

  id_faixa_km BIGINT,
    pontos_faixa_km INTEGER,
    porcentagem_faixa_km DOUBLE PRECISION,
  
    id_ocupacao BIGINT,
    pontos_ocupacao INTEGER,
    porcentagem_ocupacao DOUBLE PRECISION,

    CONSTRAINT id_centro_fk FOREIGN KEY (id_centro) REFERENCES deposito(id),
  CONSTRAINT id_numero_paradas_fk FOREIGN KEY (id_numero_paradas) REFERENCES pontuacao_adicional(id),
  CONSTRAINT id_custo_rota_fk FOREIGN KEY (id_custo_rota) REFERENCES pontuacao_adicional(id),
    CONSTRAINT id_faixa_km_fk FOREIGN KEY (id_faixa_km) REFERENCES pontuacao_adicional(id),
  CONSTRAINT id_ocupacao_fk FOREIGN KEY (id_ocupacao) REFERENCES pontuacao_adicional(id)
);


COMMENT ON TABLE public.pontuacao IS 'Tabela para calculo de pontução da rota';


INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Utiliza Calculo Baseado em Real por KM?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, utiliza o calculo de frete baseado em R$ por KM. Se não, calcula o frete baseado R$ por TON. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Utiliza Calculo Baseado em Real por KM?');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Distancia Maxima de Atendimentos', '0', 'INTEGER', true, false, 'INTEGRACAO', 'PARCEIROS', ''
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Distancia Maxima de Atendimentos');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-93' WHERE nomecampo = 'versao_banco';