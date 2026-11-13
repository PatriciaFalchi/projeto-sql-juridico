"""
gerar_dados.py
Gera o arquivo data_juridico.sql com dados FICTÍCIOS para o projeto.

Os dados são determinísticos (seed fixa): rodar o script de novo gera exatamente
o mesmo arquivo, então os resultados das consultas são reproduzíveis.

Uso:  python gerar_dados.py > data_juridico.sql
"""
import random
from datetime import date, timedelta

rnd = random.Random(42)

# Data de referência do "hoje" do projeto. Audiências depois dela ficam 'Pendente'.
HOJE = date(2025, 12, 31)

clientes = [
    ("Maria Silva", "PF", "São Paulo", "SP"),
    ("Carlos Roberto", "PF", "Rio de Janeiro", "RJ"),
    ("Ricardo José", "PF", "Fortaleza", "CE"),
    ("Ana Beatriz Costa", "PF", "Belo Horizonte", "MG"),
    ("João Pedro Alves", "PF", "Curitiba", "PR"),
    ("Fernanda Lima", "PF", "Campinas", "SP"),
    ("Marcos Vinícius Rocha", "PF", "Santos", "SP"),
    ("Juliana Prado", "PF", "São Paulo", "SP"),
    ("Padaria Pão Dourado Ltda", "PJ", "São Paulo", "SP"),
    ("Tecnova Sistemas S.A.", "PJ", "Campinas", "SP"),
    ("Transportes Horizonte Ltda", "PJ", "Belo Horizonte", "MG"),
    ("Clínica Vida Plena Ltda", "PJ", "Curitiba", "PR"),
    ("Mercado Boa Compra Ltda", "PJ", "Rio de Janeiro", "RJ"),
    ("Studio Aurora ME", "PJ", "Fortaleza", "CE"),
]

advogados = [
    ("Dr. Pedro Rocha", "SP-100101", "Cível"),
    ("Dra. Luana Reis", "RJ-200202", "Penal"),
    ("Dr. Felipe Lima", "MG-300303", "Trabalhista"),
    ("Dra. Camila Torres", "SP-100404", "Família"),
    ("Dr. André Matos", "SP-100505", "Consumidor"),
    ("Dra. Helena Braga", "PR-400606", "Empresarial"),
]

areas = {
    "Cível": ((4000, 15000), ["Ação de indenização", "Cobrança de dívida", "Revisão contratual", "Usucapião"]),
    "Penal": ((6000, 20000), ["Defesa criminal", "Pedido de liberdade provisória", "Recurso em sentido estrito"]),
    "Trabalhista": ((2500, 8000), ["Reclamação trabalhista", "Verbas rescisórias", "Reconhecimento de vínculo"]),
    "Família": ((3000, 9000), ["Divórcio consensual", "Pensão alimentícia", "Guarda compartilhada", "Inventário"]),
    "Consumidor": ((1500, 5000), ["Negativação indevida", "Vício em produto", "Cobrança indevida"]),
    "Empresarial": ((8000, 30000), ["Contrato societário", "Recuperação de crédito", "Rescisão contratual"]),
}

n_casos = 40
inicio, fim = date(2024, 1, 1), date(2025, 11, 30)

casos, audiencias, pagamentos = [], [], []

for id_caso in range(1, n_casos + 1):
    id_cliente = rnd.randint(1, len(clientes))
    id_adv = rnd.randint(1, len(advogados))
    area_adv = advogados[id_adv - 1][2]
    area = area_adv if rnd.random() < 0.85 else rnd.choice(list(areas))
    (lo, hi), descricoes = areas[area]
    descricao = rnd.choice(descricoes)
    abertura = inicio + timedelta(days=rnd.randint(0, (fim - inicio).days))
    honorarios = round(rnd.randint(lo // 100, hi // 100) * 100, 2)

    # encerramento: só casos com mais de um ano de vida podem estar encerrados
    encerramento, status = None, "Em andamento"
    if (HOJE - abertura).days > 365 and rnd.random() < 0.5:
        enc = abertura + timedelta(days=rnd.randint(150, 480))
        if enc <= HOJE:
            encerramento, status = enc, "Encerrado"
    casos.append((id_caso, id_cliente, id_adv, area, descricao, abertura, encerramento, status, honorarios))

    # audiências
    cidade = clientes[id_cliente - 1][2]
    local = f"Vara do Trabalho de {cidade}" if area == "Trabalhista" else f"Fórum de {cidade}"
    for k in range(rnd.randint(0, 3)):
        d = abertura + timedelta(days=45 * (k + 1) + rnd.randint(0, 25))
        if encerramento and d > encerramento:
            continue
        if d <= HOJE:
            res = rnd.choices(["Favorável", "Desfavorável", "Acordo"], weights=[45, 30, 25])[0]
        else:
            res = "Pendente"
        audiencias.append((d, id_caso, local, res))

    # pagamentos em parcelas mensais; nem todos os casos estão quitados
    n_parc = rnd.randint(1, 4)
    sorte = rnd.random()
    pagas = n_parc if sorte < 0.55 else (rnd.randint(1, n_parc) if sorte < 0.90 else 0)
    valor_parc = round(honorarios / n_parc, 2)
    for i in range(pagas):
        dp = abertura + timedelta(days=15 + 30 * i + rnd.randint(0, 5))
        if dp > HOJE:
            break
        v = valor_parc if i < n_parc - 1 else round(honorarios - valor_parc * (n_parc - 1), 2)
        pagamentos.append((id_caso, v, dp))

audiencias.sort()  # ordem cronológica
pagamentos.sort(key=lambda p: (p[2], p[0]))


def q(s):
    return "'" + str(s).replace("'", "''") + "'"


def d(x):
    return "NULL" if x is None else q(x.isoformat())


print("-- data_juridico.sql  (gerado por gerar_dados.py; dados 100% fictícios)\n")
print("INSERT INTO clientes (nome, tipo_pessoa, cidade, uf) VALUES")
print(",\n".join(f"({q(n)}, {q(t)}, {q(c)}, {q(u)})" for n, t, c, u in clientes) + ";\n")
print("INSERT INTO advogados (nome, oab, especialidade) VALUES")
print(",\n".join(f"({q(n)}, {q(o)}, {q(e)})" for n, o, e in advogados) + ";\n")
print("INSERT INTO casos (id_cliente, id_advogado, area, descricao, data_abertura, data_encerramento, status, honorarios_contratados) VALUES")
print(",\n".join(f"({c[1]}, {c[2]}, {q(c[3])}, {q(c[4])}, {d(c[5])}, {d(c[6])}, {q(c[7])}, {c[8]:.2f})" for c in casos) + ";\n")
print("INSERT INTO audiencias (id_caso, data_audiencia, local, resultado) VALUES")
print(",\n".join(f"({a[1]}, {d(a[0])}, {q(a[2])}, {q(a[3])})" for a in audiencias) + ";\n")
print("INSERT INTO pagamentos (id_caso, valor, data_pagamento) VALUES")
print(",\n".join(f"({p[0]}, {p[1]:.2f}, {d(p[2])})" for p in pagamentos) + ";")
