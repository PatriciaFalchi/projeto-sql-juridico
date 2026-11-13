-- queries.sql
-- Consultas de análise do escritório (PostgreSQL). Cada uma responde a uma pergunta de negócio.
-- Convenções: agrupar sempre por ID (nomes podem repetir); usar a data de referência
-- abaixo em vez de CURRENT_DATE para que os resultados sejam reproduzíveis.
-- Data de referência do projeto: 2025-12-31

---------------------------------------------------------------------------
-- 1) Quantos casos cada advogado tem, e quantos estão em andamento?
--    LEFT JOIN: inclui advogados que ainda não têm nenhum caso.
---------------------------------------------------------------------------
SELECT a.id_advogado,
       a.nome                                         AS advogado,
       COUNT(c.id_caso)                               AS total_casos,
       COUNT(*) FILTER (WHERE c.status = 'Em andamento') AS em_andamento
FROM advogados a
LEFT JOIN casos c ON c.id_advogado = a.id_advogado
GROUP BY a.id_advogado, a.nome
ORDER BY total_casos DESC, a.nome;

---------------------------------------------------------------------------
-- 2) Quais clientes mais pagaram? (ranking de receita por cliente)
--    RANK() é uma window function: ordena sem "esconder" as linhas.
---------------------------------------------------------------------------
SELECT cl.id_cliente,
       cl.nome                                   AS cliente,
       SUM(p.valor)                              AS total_pago,
       RANK() OVER (ORDER BY SUM(p.valor) DESC)  AS posicao
FROM clientes cl
JOIN casos ca      ON ca.id_cliente = cl.id_cliente
JOIN pagamentos p  ON p.id_caso = ca.id_caso
GROUP BY cl.id_cliente, cl.nome
ORDER BY posicao, cliente;

---------------------------------------------------------------------------
-- 3) Quais audiências pendentes acontecem nos próximos 60 dias?
--    A data de referência entra por uma CTE (WITH), fácil de trocar.
---------------------------------------------------------------------------
WITH ref AS (SELECT DATE '2025-12-31' AS hoje)
SELECT au.data_audiencia,
       au.data_audiencia - ref.hoje AS dias_ate_audiencia,
       ca.id_caso,
       cl.nome AS cliente,
       a.nome  AS advogado,
       au.local
FROM audiencias au
JOIN casos ca      ON ca.id_caso = au.id_caso
JOIN clientes cl   ON cl.id_cliente = ca.id_cliente
JOIN advogados a   ON a.id_advogado = ca.id_advogado
CROSS JOIN ref
WHERE au.resultado = 'Pendente'
  AND au.data_audiencia BETWEEN ref.hoje AND ref.hoje + 60
ORDER BY au.data_audiencia;

---------------------------------------------------------------------------
-- 4) Qual o ticket médio por caso e quantos pagamentos, em média, cada caso tem?
--    (duas métricas diferentes: valor em R$ e quantidade de pagamentos)
---------------------------------------------------------------------------
WITH por_caso AS (
  SELECT id_caso,
         SUM(valor) AS total_pago,
         COUNT(*)   AS qtd_pagamentos
  FROM pagamentos
  GROUP BY id_caso
)
SELECT COUNT(*)                         AS casos_com_pagamento,
       ROUND(AVG(total_pago), 2)        AS ticket_medio_por_caso,
       ROUND(AVG(qtd_pagamentos), 1)    AS media_pagamentos_por_caso
FROM por_caso;

---------------------------------------------------------------------------
-- 5) Quantos casos cada advogado abriu por mês?
---------------------------------------------------------------------------
SELECT DATE_TRUNC('month', ca.data_abertura)::date AS mes,
       a.id_advogado,
       a.nome AS advogado,
       COUNT(*) AS casos_abertos
FROM casos ca
JOIN advogados a ON a.id_advogado = ca.id_advogado
GROUP BY 1, a.id_advogado, a.nome
ORDER BY mes, advogado;

---------------------------------------------------------------------------
-- 6) Qual a taxa de êxito de cada advogado nas audiências já realizadas?
--    Definição usada: êxito = resultado 'Favorável' ou 'Acordo'.
--    Audiências 'Pendente' ficam de fora (ainda não têm resultado).
---------------------------------------------------------------------------
SELECT a.id_advogado,
       a.nome AS advogado,
       COUNT(*) AS audiencias_realizadas,
       COUNT(*) FILTER (WHERE au.resultado IN ('Favorável', 'Acordo')) AS exitos,
       ROUND(100.0 * COUNT(*) FILTER (WHERE au.resultado IN ('Favorável', 'Acordo'))
             / COUNT(*), 1) AS taxa_exito_pct
FROM audiencias au
JOIN casos ca     ON ca.id_caso = au.id_caso
JOIN advogados a  ON a.id_advogado = ca.id_advogado
WHERE au.resultado <> 'Pendente'
GROUP BY a.id_advogado, a.nome
ORDER BY taxa_exito_pct DESC, audiencias_realizadas DESC;

---------------------------------------------------------------------------
-- 7) Onde há honorários a receber? (contratado x recebido, top 10 saldos)
--    CTE agrega os pagamentos antes do JOIN para não duplicar linhas.
---------------------------------------------------------------------------
WITH recebido AS (
  SELECT id_caso, SUM(valor) AS pago
  FROM pagamentos
  GROUP BY id_caso
)
SELECT ca.id_caso,
       cl.nome AS cliente,
       ca.area,
       ca.honorarios_contratados,
       COALESCE(r.pago, 0)                                      AS pago,
       ca.honorarios_contratados - COALESCE(r.pago, 0)          AS saldo_a_receber,
       ROUND(100.0 * COALESCE(r.pago, 0) / ca.honorarios_contratados, 1) AS pct_recebido
FROM casos ca
JOIN clientes cl      ON cl.id_cliente = ca.id_cliente
LEFT JOIN recebido r  ON r.id_caso = ca.id_caso
WHERE ca.honorarios_contratados - COALESCE(r.pago, 0) > 0
ORDER BY saldo_a_receber DESC
LIMIT 10;

---------------------------------------------------------------------------
-- 8) Como evolui a receita mês a mês? (variação e acumulado)
--    generate_series cria o calendário completo, para que meses SEM pagamento
--    entrem com receita 0 (senão o LAG compararia com o mês errado).
--    LAG() olha o mês anterior; SUM() OVER acumula.
---------------------------------------------------------------------------
WITH calendario AS (
  SELECT GENERATE_SERIES(
           (SELECT DATE_TRUNC('month', MIN(data_pagamento)) FROM pagamentos),
           (SELECT DATE_TRUNC('month', MAX(data_pagamento)) FROM pagamentos),
           INTERVAL '1 month')::date AS mes
),
mensal AS (
  SELECT c.mes,
         COALESCE(SUM(p.valor), 0) AS receita
  FROM calendario c
  LEFT JOIN pagamentos p ON DATE_TRUNC('month', p.data_pagamento)::date = c.mes
  GROUP BY c.mes
)
SELECT mes,
       receita,
       LAG(receita) OVER (ORDER BY mes) AS receita_mes_anterior,
       ROUND(100.0 * (receita - LAG(receita) OVER (ORDER BY mes))
             / NULLIF(LAG(receita) OVER (ORDER BY mes), 0), 1) AS variacao_pct,
       SUM(receita) OVER (ORDER BY mes) AS receita_acumulada
FROM mensal
ORDER BY mes;

---------------------------------------------------------------------------
-- 9) Quanto tempo, em média, leva da abertura do caso até a 1ª audiência, por área?
---------------------------------------------------------------------------
WITH primeira AS (
  SELECT id_caso, MIN(data_audiencia) AS primeira_audiencia
  FROM audiencias
  GROUP BY id_caso
)
SELECT ca.area,
       COUNT(*) AS casos_com_audiencia,
       ROUND(AVG(p.primeira_audiencia - ca.data_abertura), 0) AS media_dias_ate_1a_audiencia
FROM casos ca
JOIN primeira p ON p.id_caso = ca.id_caso
GROUP BY ca.area
ORDER BY media_dias_ate_1a_audiencia;

---------------------------------------------------------------------------
-- 10) Em cada área, quem mais gerou receita? (ranking dentro de cada grupo)
--     PARTITION BY reinicia o ranking a cada área.
---------------------------------------------------------------------------
WITH receita AS (
  SELECT ca.area, a.id_advogado, a.nome AS advogado, SUM(p.valor) AS total
  FROM pagamentos p
  JOIN casos ca     ON ca.id_caso = p.id_caso
  JOIN advogados a  ON a.id_advogado = ca.id_advogado
  GROUP BY ca.area, a.id_advogado, a.nome
)
SELECT area, advogado, total,
       RANK() OVER (PARTITION BY area ORDER BY total DESC) AS posicao_na_area
FROM receita
ORDER BY area, posicao_na_area;
