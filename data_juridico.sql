-- Inserção dos dados de exemplo

INSERT INTO clientes (nome, cpf, cidade) VALUES
('Maria Silva','123.456.789-10','São Paulo'),
('Carlos Roberto','987.654.321-00','Rio de Janeiro'),
('Ricardo Jose','456.123.789-22','Ceara');

INSERT INTO advogados (nome, oab, especialidade) VALUES
('Dr. Pedro Rocha','SP12345','Direito Civil'),
('Dra. Luana Reis','RJ54321','Direito Penal'),
('Dr. Felipe Lima','MG67890','Trabalhista');

INSERT INTO casos (id_cliente, id_advogado, descricao, data_abertura) VALUES
(1,1,'Ação de indenização', '2023-11-15'),
(2,2,'Defesa criminal', '2024-01-10'),
(3,3,'Reclamação trabalhista','2024-02-20'),
(1,3,'Revisão contratual','2024-03-05');

INSERT INTO audiencias (id_caso, data_audiencia, local, resultado) VALUES
(1,'2024-02-01','Fórum SP','Pendente'),
(2,'2024-04-03','Fórum RJ','Perdido'),
(3,'2024-05-10','Fórum BH','Vencido'),
(4,'2024-06-15','Fórum SP','Pendente');

INSERT INTO pagamentos (id_caso, valor, data_pagamento) VALUES
(1,5000.00,'2024-02-10'),
(2,3000.00,'2024-04-05'),
(3,2000.00,'2024-05-12'),
(4,1500.00,'2024-06-20');