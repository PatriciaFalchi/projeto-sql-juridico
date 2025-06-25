-- queries.sql

-- a) Quantos casos cada advogado tem?
SELECT a.nome AS advogado, COUNT(c.id_caso) AS qtd_casos
FROM advogados a
LEFT JOIN casos c ON a.id_advogado = c.id_advogado
GROUP BY a.nome;

-- b) Receita total por cliente
SELECT cl.nome AS cliente, SUM(p.valor) AS total_pago
FROM clientes cl
JOIN casos ca ON cl.id_cliente = ca.id_cliente
JOIN pagamentos p ON ca.id_caso = p.id_caso
GROUP BY cl.nome;

-- c) Casos pendentes de audiência
SELECT ca.id_caso, cl.nome AS cliente, a.nome AS advogado, au.data_audiencia
FROM casos ca
JOIN clientes cl ON ca.id_cliente = cl.id_cliente
JOIN advogados a ON ca.id_advogado = a.id_advogado
JOIN audiencias au ON ca.id_caso = au.id_caso
WHERE au.resultado = 'Pendente';

-- d) Média de pagamentos por caso
SELECT AVG(qtd_pagamentos) AS media_pagamentos_por_caso
FROM (
  SELECT id_caso, COUNT(*) AS qtd_pagamentos
  FROM pagamentos
  GROUP BY id_caso
) sub;

-- e) Casos abertos por mês por advogado
SELECT a.nome AS advogado,
       TO_CHAR(ca.data_abertura, 'YYYY-MM') AS mes,
       COUNT(*) AS qtd_casos
FROM casos ca
JOIN advogados a ON ca.id_advogado = a.id_advogado
GROUP BY a.nome, TO_CHAR(ca.data_abertura, 'YYYY-MM')
ORDER BY a.nome, mes;