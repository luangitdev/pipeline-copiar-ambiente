UPDATE pedido_propriedade SET valor_string = 'N' WHERE campo = 'munck' AND valor_string ILIKE '%N%';
UPDATE pedido_propriedade SET valor_string = 'Y' WHERE campo = 'munck' AND valor_string ILIKE '%Y%';

UPDATE public.configuracao SET valor_texto= 'v.15.14.0.2-3' WHERE nomecampo = 'versao_banco';