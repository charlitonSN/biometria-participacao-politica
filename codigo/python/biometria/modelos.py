"""Estimadores de Diferença em Diferenças usados na replicação.

Duas especificações:

* **Relatório** (`paineis_relatorio`): a do trabalho original em Stata.
  - Painéis A–C: `xtdidregress (y) (did), group(cod_mun) time(ano)` em todas as
    60.770 observações; grupo tratado contra todos os demais municípios;
    erros clusterizados por município.
  - Painel D (placebo): `reghdfe y did_placebo, absorb(cod_mun ano)
    vce(cluster uf ano)` nas eleições de 2010 e 2014.

* **Artigo** (`paineis_artigo`): a de Forquesato & Rodrigues (2023, Tabela 2).
  Uma regressão por tipo de eleição, grupo tratado contra nunca tratados (nas
  estaduais, também o grupo recadastrado após 2018, o que reproduz o N do artigo),
  comparecimento/aptos em fração e erros clusterizados por UF e eleição.

Com cluster em duas vias, o p-valor usa t com min(G) − 1 graus de liberdade,
como o `reghdfe` no Stata.
"""
from dataclasses import dataclass

import pandas as pd
from linearmodels import PanelOLS
from scipy import stats

from .config import DESFECHOS, TABELA2_ARTIGO
from .dados import carregar_painel


@dataclass(frozen=True)
class Estimativa:
    coef: float
    erro_padrao: float
    p_valor: float
    n: int


def estimar_did(d: pd.DataFrame, y: str, cluster: str = "municipio") -> Estimativa:
    """TWFE: y ~ did + efeitos fixos de município e de ano.

    cluster="municipio" → erros clusterizados por município (xtdidregress).
    cluster="uf_ano"    → erros clusterizados em duas vias, UF e ano (reghdfe).
    """
    d = d.dropna(subset=[y]).copy()
    d["_uf"] = d["uf"].astype("category").cat.codes
    d["_ano"] = d["ano"]
    d = d.set_index(["cod_mun", "ano"])
    modelo = PanelOLS(d[y], d[["did"]], entity_effects=True, time_effects=True)

    if cluster == "municipio":
        r = modelo.fit(cov_type="clustered", cluster_entity=True)
        p = float(r.pvalues["did"])
    elif cluster == "uf_ano":
        r = modelo.fit(cov_type="clustered", clusters=d[["_uf", "_ano"]])
        gl = min(d["_uf"].nunique(), d["_ano"].nunique()) - 1
        p = float(2 * stats.t.sf(abs(r.params["did"] / r.std_errors["did"]), df=gl))
    else:
        raise ValueError(f"cluster desconhecido: {cluster}")

    return Estimativa(float(r.params["did"]), float(r.std_errors["did"]), p, int(r.nobs))


def _tabela(paineis: dict, desfechos: dict, cluster: str) -> pd.DataFrame:
    linhas = []
    for painel, (descricao, amostra) in paineis.items():
        for y, rotulo in desfechos.items():
            e = estimar_did(amostra, y, cluster[painel] if isinstance(cluster, dict) else cluster)
            linhas.append(dict(painel=painel, descricao=descricao, desfecho=y, rotulo=rotulo,
                               coef=e.coef, erro_padrao=e.erro_padrao, p_valor=e.p_valor, n=e.n))
    return pd.DataFrame(linhas)


# --------------------------------------------------------------------------- relatório
def _amostra_relatorio(df: pd.DataFrame, trat: str, ano_trat: int) -> pd.DataFrame:
    """Grupo = municípios com `trat == 1` no ano `ano_trat`; controle = todos os demais."""
    d = df.copy()
    tratado_no_ano = ((d[trat] == 1) & (d["ano"] == ano_trat)).astype(int)
    grupo = tratado_no_ano.groupby(d["cod_mun"]).transform("max")
    d["did"] = (d["ano"] >= ano_trat).astype(int) * grupo
    return d


def _amostra_placebo_relatorio(df: pd.DataFrame) -> pd.DataFrame:
    """Eleições estaduais de 2010 e 2014; 'tratados' = municípios tratados em 2018."""
    d = df[df["ano"].isin([2010, 2014])].copy()
    d["did"] = ((d["g_trat_est"] == 2018) & (d["ano"] == 2014)).astype(int)
    return d


def paineis_relatorio(df: pd.DataFrame | None = None) -> pd.DataFrame:
    df = carregar_painel() if df is None else df
    paineis = {
        "A": ("Estaduais: tratados em 2018 vs demais", _amostra_relatorio(df, "trat_est", 2018)),
        "B": ("Estaduais: tratados em 2014 vs demais", _amostra_relatorio(df, "trat_est", 2014)),
        "C": ("Municipais: tratados em 2016 vs demais", _amostra_relatorio(df, "trat_mun", 2016)),
        "D": ("Placebo: estaduais 2010-2014, futuros tratados em 2018", _amostra_placebo_relatorio(df)),
    }
    cluster = {"A": "municipio", "B": "municipio", "C": "municipio", "D": "uf_ano"}
    return _tabela(paineis, DESFECHOS, cluster)


# --------------------------------------------------------------------------- artigo
def _amostra_artigo(df, cargo, gvar, grupo, controles, ano_pos, ano_max=None):
    d = df[df["cargo"] == cargo]
    if ano_max is not None:
        d = d[d["ano"] <= ano_max]
    d = d[d[gvar].isin([grupo, *controles])].copy()
    d["did"] = ((d[gvar] == grupo) & (d["ano"] >= ano_pos)).astype(int)
    return d


def paineis_artigo(df: pd.DataFrame | None = None) -> pd.DataFrame:
    df = carregar_painel() if df is None else df
    paineis = {
        "A": ("Estaduais: tratados em 2018 vs nunca tratados",
              _amostra_artigo(df, "governador", "g_trat_est", 2018, [0, 2022], 2018)),
        "B": ("Estaduais: tratados em 2014 vs nunca tratados",
              _amostra_artigo(df, "governador", "g_trat_est", 2014, [0, 2022], 2014)),
        "C": ("Municipais: tratados em 2016 vs nunca tratados",
              _amostra_artigo(df, "prefeito", "g_trat_mun", 2016, [0], 2016)),
        "D": ("Placebo: estaduais 2002-2014, pós = 2010 e 2014",
              _amostra_artigo(df, "governador", "g_trat_est", 2018, [0, 2022], 2010, ano_max=2014)),
    }
    desfechos = {"l_aptos": "Log (Aptos)", "prop_compa_f": "Comp./Aptos",
                 "prop_pop": "Comp./População", "l_compa": "Log (Comp.)"}
    tab = _tabela(paineis, desfechos, "uf_ano")

    art = []
    for painel, (coefs, eps, n) in TABELA2_ARTIGO.items():
        for i, y in enumerate(desfechos):
            art.append(dict(painel=painel, desfecho=y,
                            coef_artigo=coefs[i], ep_artigo=eps[i], n_artigo=n))
    tab = tab.merge(pd.DataFrame(art), on=["painel", "desfecho"])
    return tab.rename(columns={"coef": "coef_replicacao", "erro_padrao": "ep_replicacao",
                               "p_valor": "p_valor_replicacao", "n": "n_replicacao"})
