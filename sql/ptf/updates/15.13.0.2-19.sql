ALTER TABLE pontuacao ADD IF NOT EXISTS numero_paradas boolean, ADD IF NOT EXISTS ocupacao boolean, ADD IF NOT EXISTS custo_rota boolean, ADD IF NOT EXISTS faixa_km boolean;
ALTER TABLE pontuacao DROP IF EXISTS id_numero_paradas, DROP IF EXISTS pontos_numero_paradas;

ALTER TABLE pontuacao DROP IF EXISTS id_ocupacao, DROP IF EXISTS pontos_ocupacao;
ALTER TABLE pontuacao DROP IF EXISTS id_custo_rota, DROP IF EXISTS pontos_custo_rota;
ALTER TABLE pontuacao DROP IF EXISTS id_faixa_km, DROP IF EXISTS pontos_faixa_km;

ALTER TABLE pontuacao_adicional ADD IF NOT EXISTS minimo integer NOT NULL, ADD IF NOT EXISTS maximo integer NOT NULL, ADD IF NOT EXISTS pontos integer NOT NULL;

ALTER TABLE pontuacao ALTER COLUMN itinerario SET DEFAULT false;
ALTER TABLE pontuacao ALTER COLUMN cliente SET DEFAULT false;
ALTER TABLE pontuacao ALTER COLUMN chapa SET DEFAULT false;
ALTER TABLE pontuacao ALTER COLUMN numero_paradas SET DEFAULT false;
ALTER TABLE pontuacao ALTER COLUMN ocupacao SET DEFAULT false;
ALTER TABLE pontuacao ALTER COLUMN faixa_km SET DEFAULT false;

UPDATE public.configuracao SET valor_texto= 'v.15.13.0.2-19' WHERE nomecampo = 'versao_banco';