CREATE TABLE IF NOT EXISTS pontuacao (
    id BIGSERIAL PRIMARY KEY,
    
    id_centro BIGINT,
    id_itinerario BIGINT,
    numero_paradas INTEGER,
    pontos_numero_paradas INTEGER,
    porcentagem_numero_paradas DOUBLE PRECISION,
    
    chapa BOOLEAN,
    pontos_chapa INTEGER,
    porcentagem_chapa DOUBLE PRECISION,
    
    ocupacao DOUBLE PRECISION,
    pontos_ocupacao INTEGER,
    porcentagem_ocupacao DOUBLE PRECISION,
    
    codigo_cliente VARCHAR,
    pontos_codigo_cliente INTEGER,
    porcentagem_codigo_cliente DOUBLE PRECISION,
    
    custo_rota DOUBLE PRECISION,
    pontos_custo_rota INTEGER,
    porcentagem_custo_rota DOUBLE PRECISION,
    
    faixa_km DOUBLE PRECISION,
    pontos_faixa_km INTEGER,
    porcentagem_faixa_km DOUBLE PRECISION,
    
    id_segmento BIGINT,
    pontos_segmento INTEGER,
    porcentagem_segmento DOUBLE PRECISION,

    CONSTRAINT centro_id_fk FOREIGN KEY (id_centro) REFERENCES deposito(id),
    CONSTRAINT itinerario_id_fk FOREIGN KEY (id_itinerario) REFERENCES itinerario(id),
    CONSTRAINT segmento_id_fk FOREIGN KEY (id_segmento) REFERENCES segmentoentrega(id)
);

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Trabalha com pontuacao nas Rotas?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, exibe uma nova janela de cadastro, uma nova importação XLS e executa um calculo que ira ser exibido na grid de rotas. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Trabalha com pontuacao nas Rotas?');


COMMENT ON TABLE public.pontuacao IS 'Tabela para calculo de pontução da rota';

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-63' WHERE nomecampo = 'versao_banco';