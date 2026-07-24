-- DADOS INICIAIS
INSERT INTO empresa(id, cnpj, nome, produto) VALUES(1, '34436354000286', 'DISTRIBUIDORA DE BEBIDAS MARRA CENTRO OESTE LTDA', 'PLANNER');
INSERT INTO estado(id, nome, sigla) VALUES(1, 'Minas Gerais', 'MG');
INSERT INTO cidade(id, nome, estado_id) VALUES(1, 'Passos',1);
INSERT INTO maparoutes(id, descricao, nome, referencia) VALUES(1,'Minas Gerais', 'MG',1);
INSERT INTO centrodistribuicao(id, nome, endereco, bairro, cep, latitude, longitude,id_empresa,id_cidade,identificador, mapa_id) 
VALUES(1, 'DISTRIBUIDORA DE BEBIDAS MARRA CENTRO OESTE LTDA', 'Rua Isaura Kallas,287', 'Vila Romana', '37901-777', -20.741415136579498, -46.61180197558334,1,1,17766,1);
