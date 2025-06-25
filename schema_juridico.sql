-- Criação das tabelas

CREATE TABLE clientes (
  id_cliente SERIAL PRIMARY KEY,
  nome VARCHAR(100),
  cpf VARCHAR(14),
  cidade VARCHAR(50)
);

CREATE TABLE advogados (
  id_advogado SERIAL PRIMARY KEY,
  nome VARCHAR(100),
  oab VARCHAR(20),
  especialidade VARCHAR(50)
);

CREATE TABLE casos (
  id_caso SERIAL PRIMARY KEY,
  id_cliente INT REFERENCES clientes(id_cliente),
  id_advogado INT REFERENCES advogados(id_advogado),
  descricao TEXT,
  data_abertura DATE
);

CREATE TABLE audiencias (
  id_audiencia SERIAL PRIMARY KEY,
  id_caso INT REFERENCES casos(id_caso),
  data_audiencia DATE,
  local VARCHAR(100),
  resultado VARCHAR(50)
);

CREATE TABLE pagamentos (
  id_pagamento SERIAL PRIMARY KEY,
  id_caso INT REFERENCES casos(id_caso),
  valor NUMERIC(10,2),
  data_pagamento DATE
);