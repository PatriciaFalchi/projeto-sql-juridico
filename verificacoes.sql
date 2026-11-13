-- verificacoes.sql
-- Checagens de qualidade dos dados. Todas devem retornar ZERO linhas.

-- 1) Pagamentos acima do valor contratado em algum caso
SELECT ca.id_caso, ca.honorarios_contratados, SUM(p.valor) AS pago
FROM casos ca JOIN pagamentos p ON p.id_caso = ca.id_caso
GROUP BY ca.id_caso, ca.honorarios_contratados
HAVING SUM(p.valor) > ca.honorarios_contratados;

-- 2) Audiência ou pagamento anterior à abertura do caso
SELECT 'audiencia' AS tipo, au.id_audiencia AS id
FROM audiencias au JOIN casos ca ON ca.id_caso = au.id_caso
WHERE au.data_audiencia < ca.data_abertura
UNION ALL
SELECT 'pagamento', p.id_pagamento
FROM pagamentos p JOIN casos ca ON ca.id_caso = p.id_caso
WHERE p.data_pagamento < ca.data_abertura;

-- 3) Audiência 'Pendente' no passado, ou com resultado já definido no futuro
--    (data de referência: 2025-12-31)
SELECT id_audiencia, data_audiencia, resultado
FROM audiencias
WHERE (resultado = 'Pendente' AND data_audiencia <= DATE '2025-12-31')
   OR (resultado <> 'Pendente' AND data_audiencia >  DATE '2025-12-31');

-- 4) Caso encerrado que ainda tem audiência pendente
SELECT DISTINCT ca.id_caso
FROM casos ca JOIN audiencias au ON au.id_caso = ca.id_caso
WHERE ca.status = 'Encerrado' AND au.resultado = 'Pendente';
