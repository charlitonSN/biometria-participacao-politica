"""Caminhos do projeto e constantes compartilhadas."""
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]

DADOS_PROCESSADOS = RAIZ / "dados" / "processados"
PAINEL = DADOS_PROCESSADOS / "painel_final.dta"

TABELAS = RAIZ / "resultados" / "tabelas"
FIGURAS = RAIZ / "resultados" / "figuras"

# Variáveis dependentes, na ordem das colunas (1)–(4) do artigo
DESFECHOS = {
    "l_aptos": "Log (Aptos)",
    "prop_compa": "Comp./Aptos",
    "prop_pop": "Comp./População",
    "l_compa": "Log (Comp.)",
}

VARS_DESCRITIVAS = [
    "ano", "pop_total", "aptos", "compa", "abst", "validos",
    "prop_compa", "prop_pop", "l_aptos", "l_compa", "l_abst", "l_validos",
]

# Tabela 2 de Forquesato & Rodrigues (2023): (coeficientes, erros-padrão, N)
TABELA2_ARTIGO = {
    "A": ([-0.062, 0.050, 0.006, 0.0008], [0.020, 0.016, 0.009, 0.015], 28627),
    "B": ([-0.045, 0.039, 0.005, 0.004], [0.038, 0.014, 0.017, 0.029], 20479),
    "C": ([-0.048, 0.059, 0.017, 0.023], [0.028, 0.011, 0.017, 0.024], 10904),
    "D": ([-0.004, -0.007, -0.0003, -0.012], [0.013, 0.006, 0.005, 0.011], 19594),
}

ROTULOS_PAINEIS = {
    "A": "A: Estaduais 2018",
    "B": "B: Estaduais 2014",
    "C": "C: Municipais 2016",
    "D": "D: Placebo",
}
