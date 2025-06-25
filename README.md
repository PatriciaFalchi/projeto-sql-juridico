# Projeto SQL – Escritório Jurídico

Este projeto simula a estrutura de dados de um escritório de advocacia, com foco em modelagem relacional, inserção de dados e consultas SQL úteis para análise de informações jurídicas.

---

## 📁 Estrutura dos Arquivos

- `schema_juridico.sql`: cria as tabelas principais do banco de dados
- `data_juridico.sql`: insere dados fictícios de clientes, advogados, casos, audiências e pagamentos
- `queries.sql`: contém consultas para análise de dados

---

## 🧱 Tabelas Criadas

- `clientes`: dados básicos dos clientes
- `advogados`: profissionais que atuam nos casos
- `casos`: vínculos entre clientes e advogados com descrição e data de abertura
- `audiencias`: datas, locais e resultados de audiências de cada caso
- `pagamentos`: valores pagos relacionados aos casos

---

## 📊 Consultas disponíveis

- Total de casos por advogado
- Receita total por cliente
- Casos com audiências pendentes
- Média de pagamentos por caso
- Casos abertos por mês por advogado

---

## 🛠️ Tecnologias utilizadas

- PostgreSQL
- SQL
- pgAdmin (interface para execução)

---
