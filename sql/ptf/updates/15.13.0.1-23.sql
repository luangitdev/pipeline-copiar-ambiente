ALTER TABLE tipoveiculo 
ADD IF NOT EXISTS quantidade_por_frota integer, 
ADD IF NOT EXISTS capacidade_kg double precision, 
ADD IF NOT EXISTS capacidade_vl double precision, 
ADD IF NOT EXISTS capacidade_cubagem double precision, 
ADD IF NOT EXISTS temporaridade character varying(255), 
ADD IF NOT EXISTS status character varying(255) default 'DISPONIVEL';

UPDATE public.configuracao SET valor_texto='v.15.13.0.1-23' WHERE nomecampo = 'versao_banco';