CREATE OR REPLACE FUNCTION pathfind_distancia_haversine(
    lat1 numeric(10,6), lon1 numeric(10,6),
    lat2 numeric(10,6), lon2 numeric(10,6)
)
RETURNS double precision AS $$
  SELECT 6371 * acos(
    cos(radians(lat1)) * cos(radians(lat2)) *
    cos(radians(lon1 - lon2)) +
    sin(radians(lat1)) * sin(radians(lat2))
  ) AS distance;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION pathfind_distancia_haversine(
    lat1 double precision, lon1 double precision,
    lat2 double precision, lon2 double precision
)
RETURNS double precision AS $$
  SELECT 6371 * acos(
    cos(radians(lat1)) * cos(radians(lat2)) *
    cos(radians(lon1 - lon2)) +
    sin(radians(lat1)) * sin(radians(lat2))
  ) AS distance;
$$ LANGUAGE SQL;

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'Shortlist - Percentual do Raio', '10', 'INTEGER', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, Busca clientes com o Raio prograssivo a partir de cada parada. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'Shortlist - Percentual do Raio');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'ShortList - Respeita Zoneamento?', 'NAO', 'BOOLEAN', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, Busca clientes com o Raio prograssivo a partir de cada parada, mas da mesma zona da parada. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'ShortList - Respeita Zoneamento?');

INSERT INTO parametro (chave, valor, tipo_parametro, parametro_sistema, oculto, grupo, subgrupo, observacao)
SELECT 'ShortList - Raio de Abrangencia dos Clientes Elegiveis', '10', 'NUMBER', true, false, 'INTEGRACAO', 'PARCEIROS', 'Quando habilitado, Busca clientes com o Raio fixo a partir de cada parada. Integração Votorantim'
WHERE NOT EXISTS (SELECT 1 FROM parametro WHERE chave = 'ShortList - Raio de Abrangencia dos Clientes Elegiveis');

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.1-65' WHERE nomecampo = 'versao_banco';