"""
Testes de reprodutibilidade.

1. Os dados e as estimações reproduzem os números publicados no relatório
   (relatorio/relatorio_replicacao_biometria.pdf).
2. A especificação do artigo reproduz a Tabela 2 de Forquesato & Rodrigues (2023)
   dentro de uma tolerância de 0,01.
3. As conclusões qualitativas se mantêm.

Uso (na raiz do repositório):  pytest
"""
import pandas as pd
import pytest

from biometria.dados import carregar_painel, distribuicao_tratamento, estatisticas_descritivas
from biometria.modelos import paineis_artigo, paineis_relatorio

# ------------------------------------------------------------------ valores do relatório (PDF)
# Painéis A–C: coeficiente e erro-padrão; Painel D: coeficiente, erro-padrão e p-valor
RELATORIO = {
    ("A", "l_aptos"): (-0.053, 0.003), ("A", "prop_compa"): (3.936, 0.096),
    ("A", "prop_pop"): (0.001, 0.002), ("A", "l_compa"): (-0.003, 0.003),
    ("B", "l_aptos"): (-0.023, 0.005), ("B", "prop_compa"): (2.014, 0.140),
    ("B", "prop_pop"): (0.002, 0.003), ("B", "l_compa"): (0.003, 0.005),
    ("C", "l_aptos"): (-0.032, 0.004), ("C", "prop_compa"): (2.609, 0.113),
    ("C", "prop_pop"): (0.005, 0.003), ("C", "l_compa"): (-0.001, 0.004),
}
PLACEBO_RELATORIO = {
    "l_aptos": (0.024, 0.0066568, 0.171),
    "prop_compa": (-1.416, 0.4801622, 0.208),
    "prop_pop": (0.006, 0.0024867, 0.250),
    "l_compa": (0.007, 0.0039492, 0.325),
}


@pytest.fixture(scope="module")
def df():
    return carregar_painel()


@pytest.fixture(scope="module")
def relatorio(df):
    return paineis_relatorio(df).set_index(["painel", "desfecho"])


@pytest.fixture(scope="module")
def artigo(df):
    return paineis_artigo(df).set_index(["painel", "desfecho"])


# ------------------------------------------------------------------ dados
def test_tamanho_do_painel(df):
    assert len(df) == 60770
    assert df["cod_mun"].nunique() == 5526
    assert df["ano"].min() == 2002 and df["ano"].max() == 2022


def test_estatisticas_descritivas(df):
    d = estatisticas_descritivas(df)
    assert d.loc["aptos", "media"] == pytest.approx(24584.39, abs=0.01)
    assert d.loc["compa", "media"] == pytest.approx(20101.97, abs=0.01)
    assert d.loc["prop_compa", "media"] == pytest.approx(82.8371, abs=1e-4)
    assert d.loc["l_aptos", "media"] == pytest.approx(9.155243, abs=1e-4)  # tabela arredondada a 4 casas
    assert d.loc["l_validos", "obs"] == 60766


def test_distribuicao_do_tratamento(df):
    d = distribuicao_tratamento(df)
    municipal = {2008: 3, 2012: 291, 2016: 1227, 2020: 2797}
    estadual = {2010: 59, 2014: 692, 2018: 1833, 2022: 1736}
    for ano, n in municipal.items():
        assert d.loc[ano, "municipal_tratados"] == n
    for ano, n in estadual.items():
        assert d.loc[ano, "estadual_tratados"] == n


# ------------------------------------------------------------------ relatório
@pytest.mark.parametrize("chave", list(RELATORIO))
def test_paineis_A_a_C_reproduzem_o_relatorio(relatorio, chave):
    coef, ep = RELATORIO[chave]
    r = relatorio.loc[chave]
    assert round(r.coef, 3) == pytest.approx(coef, abs=1e-9)
    # o xtdidregress aplica correção de graus de liberdade um pouco diferente
    assert r.erro_padrao == pytest.approx(ep, abs=0.01)
    assert r.n == 60770


@pytest.mark.parametrize("desfecho", list(PLACEBO_RELATORIO))
def test_placebo_reproduz_o_relatorio(relatorio, desfecho):
    coef, ep, p = PLACEBO_RELATORIO[desfecho]
    r = relatorio.loc[("D", desfecho)]
    assert round(r.coef, 3) == pytest.approx(coef, abs=1e-9)
    # base salva em float32: diferenças só a partir da 4ª casa decimal
    assert r.erro_padrao == pytest.approx(ep, rel=1e-3)
    assert round(r.p_valor, 3) == pytest.approx(p, abs=1e-9)
    assert r.n == 11052


# ------------------------------------------------------------------ artigo
def test_especificacao_do_artigo_reproduz_a_tabela_2(artigo):
    dif_coef = (artigo.coef_replicacao - artigo.coef_artigo).abs()
    dif_ep = (artigo.ep_replicacao - artigo.ep_artigo).abs()
    assert dif_coef.max() < 0.01, dif_coef.sort_values().tail()
    assert dif_ep.max() < 0.01, dif_ep.sort_values().tail()


def test_tamanho_das_amostras_proximo_ao_do_artigo(artigo):
    n = artigo.groupby(level="painel")[["n_replicacao", "n_artigo"]].first()
    assert n.loc["A", "n_replicacao"] == pytest.approx(n.loc["A", "n_artigo"], rel=0.01)
    assert ((n.n_replicacao / n.n_artigo - 1).abs() < 0.15).all()


# ------------------------------------------------------------------ conclusões
@pytest.mark.parametrize("painel", ["A", "B", "C"])
def test_aptos_caem_e_taxa_de_comparecimento_sobe(relatorio, artigo, painel):
    for tab, y in ((relatorio, "prop_compa"), (artigo, "prop_compa_f")):
        col = "coef" if "coef" in tab else "coef_replicacao"
        assert tab.loc[(painel, "l_aptos"), col] < 0
        assert tab.loc[(painel, y), col] > 0


@pytest.mark.parametrize("painel", ["A", "B", "C"])
def test_comparecimento_efetivo_nao_muda(relatorio, artigo, painel):
    for y in ("prop_pop", "l_compa"):
        assert relatorio.loc[(painel, y), "p_valor"] > 0.05
        assert artigo.loc[(painel, y), "p_valor_replicacao"] > 0.05


def test_placebo_nao_significativo(artigo):
    placebo = artigo.loc["D"]
    assert (placebo.p_valor_replicacao > 0.10).all()
