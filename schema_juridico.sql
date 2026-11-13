-- schema_juridico.sql
-- Modelo relacional de um escritório de advocacia (dados fictícios).
-- Decisão de modelagem (LGPD): o modelo NÃO guarda CPF nem outros dados pessoais
-- sensíveis. Para as análises, basta o identificador interno do cliente.

DROP TABLE IF EXISTS pagamentos, audiencias, casos, advogados, clientes CASCADE;

CREATE TABLE clientes (
  id_cliente    SERIAL PRIMARY KEY,
  nome          VARCHAR(100) NOT NULL,
  tipo_pessoa   CHAR(2)      NOT NULL CHECK (tipo_pessoa IN ('PF', 'PJ')),
  cidade        VARCHAR(50)  NOT NULL,
  uf            CHAR(2)      NOT NULL
);

CREATE TABLE advogados (
  id_advogado   SERIAL PRIMARY KEY,
  nome          VARCHAR(100) NOT NULL,
  oab           VARCHAR(20)  NOT NULL UNIQUE,
  especialidade VARCHAR(50)  NOT NULL
);

CREATE TABLE casos (
  id_caso                 SERIAL PRIMARY KEY,
  id_cliente              INT NOT NULL REFERENCES clientes(id_cliente),
  id_advogado             INT NOT NULL REFERENCES advogados(id_advogado),
  area                    VARCHAR(30)   NOT NULL,
  descricao               TEXT          NOT NULL,
  data_abertura           DATE          NOT NULL,
  data_encerramento       DATE,
  status                  VARCHAR(20)   NOT NULL
                          CHECK (status IN ('Em andamento', 'Encerrado')),
  honorarios_contratados  NUMERIC(10,2) NOT NULL CHECK (honorarios_contratados > 0),
  -- um caso encerrado precisa de data de encerramento, e só ele
  CHECK ((status = 'Encerrado') = (data_encerramento IS NOT NULL)),
  CHECK (data_encerramento IS NULL OR data_encerramento >= data_abertura)
);

CREATE TABLE audiencias (
  id_audiencia    SERIAL PRIMARY KEY,
  id_caso         INT NOT NULL REFERENCES casos(id_caso),
  data_audiencia  DATE        NOT NULL,
  local           VARCHAR(100) NOT NULL,
  resultado       VARCHAR(20) NOT NULL
                  CHECK (resultado IN ('Pendente', 'Favorável', 'Desfavorável', 'Acordo'))
);

CREATE TABLE pagamentos (
  id_pagamento    SERIAL PRIMARY KEY,
  id_caso         INT NOT NULL REFERENCES casos(id_caso),
  valor           NUMERIC(10,2) NOT NULL CHECK (valor > 0),
  data_pagamento  DATE NOT NULL
);

-- Índices nas chaves estrangeiras (acelera os JOINs quando a base cresce)
CREATE INDEX idx_casos_cliente    ON casos(id_cliente);
CREATE INDEX idx_casos_advogado   ON casos(id_advogado);
CREATE INDEX idx_audiencias_caso  ON audiencias(id_caso);
CREATE INDEX idx_pagamentos_caso  ON pagamentos(id_caso);
