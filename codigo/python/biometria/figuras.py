"""Gráficos de coeficientes com intervalos de confiança de 95%."""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402

from .config import ROTULOS_PAINEIS  # noqa: E402

AZUL, CINZA = "#1f4e79", "#9aa5b1"


def _formatar_eixo(ax, titulo, rotulos):
    ax.axvline(0, color="#888", lw=1, ls="--")
    ax.set_title(titulo, fontsize=11)
    ax.set_yticks(range(len(rotulos)))
    ax.set_yticklabels(rotulos)
    ax.xaxis.set_major_locator(plt.MaxNLocator(4))
    ax.grid(axis="x", alpha=.3)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)


def grafico_tendencias(df: pd.DataFrame, destino: Path) -> None:
    """Médias anuais de tratados em 2018 e controles nas eleições estaduais (Painel A,
    especificação do artigo): verificação visual das tendências pré-tratamento."""
    d = df[(df["cargo"] == "governador") & df["g_trat_est"].isin([2018, 0, 2022])].copy()
    d["grupo"] = (d["g_trat_est"] == 2018).map({True: "Tratados em 2018", False: "Controle"})
    medias = d.groupby(["ano", "grupo"])[["l_aptos", "prop_compa", "prop_pop", "l_compa"]].mean()

    paineis = [("l_aptos", "Log (Aptos)"), ("l_compa", "Log (Comparecimento)"),
               ("prop_compa", "Comparecimento / Aptos (%)"), ("prop_pop", "Comparecimento / População")]
    fig, axes = plt.subplots(2, 2, figsize=(11, 7.5), sharex=True)
    for ax, (y, titulo) in zip(axes.flat, paineis):
        for grupo, cor, estilo in (("Tratados em 2018", AZUL, "-"), ("Controle", CINZA, "--")):
            serie = medias.xs(grupo, level="grupo")[y]
            ax.plot(serie.index, serie.values, estilo, color=cor, lw=2.2, marker="o", ms=4, label=grupo)
        ax.axvline(2018, color="#c0392b", lw=1, ls=":")
        ax.set_title(titulo, fontsize=11)
        ax.set_xticks([2002, 2006, 2010, 2014, 2018, 2022])
        ax.grid(axis="y", alpha=.3)
        for lado in ("top", "right"):
            ax.spines[lado].set_visible(False)
    fig.legend(*axes[0, 0].get_legend_handles_labels(), loc="upper right", ncol=2, frameon=False, fontsize=10)
    fig.suptitle("Tendências pré-tratamento: eleições estaduais, tratados em 2018 × controles",
                 fontsize=13, x=0.01, ha="left")
    fig.text(0.01, 0.01, "Médias municipais por eleição. Controle: nunca tratados e recadastrados após 2018 "
             "(especificação do artigo). Linha vermelha: eleição de 2018.", fontsize=8.5, color="#555")
    fig.tight_layout(rect=(0, 0.03, 1, 0.94))
    fig.savefig(destino, dpi=200)
    plt.close(fig)


def grafico_comparacao(tab: pd.DataFrame, destino: Path) -> None:
    """Replicação (especificação do artigo) × Tabela 2 do artigo."""
    fig, axes = plt.subplots(1, 4, figsize=(15, 4.8), sharey=True)
    for ax, (y, sub) in zip(axes, tab.groupby("desfecho", sort=False)):
        sub = sub.reset_index(drop=True)
        for i, r in sub.iterrows():
            ax.errorbar(r.coef_artigo, i - 0.15, xerr=1.96 * r.ep_artigo, fmt="s", ms=6,
                        color=CINZA, capsize=3, lw=1.8, label="Artigo" if i == 0 else None)
            ax.errorbar(r.coef_replicacao, i + 0.15, xerr=1.96 * r.ep_replicacao, fmt="o", ms=7,
                        color=AZUL, capsize=3, lw=2, label="Replicação" if i == 0 else None)
        _formatar_eixo(ax, sub.rotulo.iloc[0], [ROTULOS_PAINEIS[p] for p in sub.painel])
    axes[0].invert_yaxis()
    fig.legend(*axes[0].get_legend_handles_labels(), loc="upper right", ncol=2, frameon=False, fontsize=10)
    fig.suptitle("Recadastramento biométrico: replicação × Forquesato & Rodrigues (2023)",
                 fontsize=13, x=0.01, ha="left")
    fig.text(0.01, 0.01,
             "Diferença em Diferenças com efeitos fixos de município e eleição; IC 95%, erros clusterizados "
             "por UF e eleição. Comp./Aptos em fração (0,05 = 5 p.p.).", fontsize=8.5, color="#555")
    fig.tight_layout(rect=(0, 0.04, 1, 0.94))
    fig.savefig(destino, dpi=200)
    plt.close(fig)
