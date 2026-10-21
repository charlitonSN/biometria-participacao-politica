"""Leitura do painel final e construção das variáveis de tratamento."""
from functools import lru_cache

import pandas as pd

from .config import PAINEL, VARS_DESCRITIVAS


@lru_cache(maxsize=1)
def _ler_painel() -> pd.DataFrame:
    df = pd.read_stata(PAINEL)
    df["ano"] = df["ano"].astype(int)
    # Comparecimento/aptos em fração (0–1), escala usada no artigo
    df["prop_compa_f"] = df["prop_compa"] / 100
    # Primeira eleição em que o município é tratado (0 = nunca tratado)
    for trat in ("trat_est", "trat_mun"):
        primeira = df["ano"].where(df[trat] == 1)
        df[f"g_{trat}"] = primeira.groupby(df["cod_mun"]).transform("min").fillna(0).astype(int)
    return df


def carregar_painel() -> pd.DataFrame:
    """Devolve uma cópia do painel município × ano (dados/processados/painel_final.dta)."""
    return _ler_painel().copy()


def estatisticas_descritivas(df: pd.DataFrame) -> pd.DataFrame:
    desc = df[VARS_DESCRITIVAS].agg(["count", "mean", "std", "min", "max"]).T
    desc.columns = ["obs", "media", "desvio_padrao", "min", "max"]
    return desc.round(4)


def distribuicao_tratamento(df: pd.DataFrame) -> pd.DataFrame:
    tab_mun = pd.crosstab(df["ano"], df["trat_mun"])
    tab_est = pd.crosstab(df["ano"], df["trat_est"])
    return pd.DataFrame({
        "municipal_nao_tratados": tab_mun[0.0],
        "municipal_tratados": tab_mun[1.0],
        "estadual_nao_tratados": tab_est[0.0],
        "estadual_tratados": tab_est[1.0],
    })
