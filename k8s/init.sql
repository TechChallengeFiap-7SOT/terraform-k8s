CREATE TABLE IF NOT EXISTS cliente (
    cpf VARCHAR(11) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    PRIMARY KEY (cpf)
);

CREATE TABLE IF NOT EXISTS categoria (
    id INT NOT NULL,
    nome VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS produto (
    id VARCHAR(100) NOT NULL,
    nome VARCHAR(255) NOT NULL,
    descricao VARCHAR(255),
    preco DECIMAL(10, 2) NOT NULL,
    id_categoria INT NOT NULL,
    ativo TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id)
);

CREATE TABLE IF NOT EXISTS pedido (
    id VARCHAR(100) NOT NULL,
    cpf_cliente VARCHAR(11),
    data_hora TIMESTAMP NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    status_pgto VARCHAR(50) NOT NULL,
    id_transacao_pagamento VARCHAR(400),
    PRIMARY KEY (id),
    FOREIGN KEY(cpf_cliente) REFERENCES cliente (cpf)
);


CREATE TABLE IF NOT EXISTS pedido_produto
(
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido VARCHAR(100),
    id_produto VARCHAR(100),
    combo_num INT,
    preco DECIMAL(10,2),
    FOREIGN KEY(id_pedido) REFERENCES pedido (id),
    FOREIGN KEY(id_produto) REFERENCES produto (id)
);

INSERT INTO categoria (id, nome) VALUES
(1, 'Lanche'),
(2, 'Acompanhamento'),
(3, 'Bebida'),
(4, 'Sobremesa');

INSERT INTO produto VALUES 
('f09b0e98-e3ec-4518-b476-ad858d70fe26', 'Hamburguer de Siri5', 'Hamburguer feito com carne de Siri', 12.99, 1, 1),
('aedf53af-1ff2-4f17-b8e5-ef4ecc42e022', 'Hamburguer de Soja', 'Hamburguer feito a base de Soja', 8.99, 1, 1),
('aa1d4879-c831-4b81-908f-39c03d7f7eb8', 'Batata Frita', 'Batata palito frita', 5.99, 2, 1),
('09d3515f-7974-4f83-9db0-79936a50f211', 'Nuggets', 'Empanados de frango', 8.99, 2, 1),
('8a458fde-7946-46e3-b4e8-84059260e8dd', 'Refrigerante', 'Refrigerante sabor cola', 9.99, 3, 1),
('08df3e2a-7882-4509-93f0-39675221a20d', 'Suco', 'Suco sabor colorido', 10.99, 3, 1),
('5defc5aa-953e-494a-8043-3d1fdb866f02', 'Sorvete', 'Sorvete de creme', 4.99, 4, 1),
('57a26408-fde0-4abd-886b-056e0cff117b', 'Torta de maça', 'Torta sabor maça', 4.99, 4, 1);


INSERT INTO cliente VALUES 
('12345678910', 'Mauricio', 'mauricio@techchallenge.com.br'),
('12345678911', 'Jackson', 'jackson@techchallenge.com.br'),
('12345678912', 'Vinicius', 'vinicius@techchallenge.com.br');
