"""Gráficos de coeficientes com intervalos de confiança de 95%."""
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402

from .config import ROTULOS_PAINEIS  # noqa: E402

AZUL, AZUL_MEDIO, AZUL_CLARO, CINZA = "#1f4e79", "#5b8db8", "#a3c4e0", "#9aa5b1"


def _formatar_eixo(ax, titulo, rotulos):
    ax.axvline(0, color="#888", lw=1, ls="--")
    ax.set_title(titulo, fontsize=11)
    ax.set_yticks(range(len(rotulos)))
    ax.set_yticklabels(rotulos)
    ax.xaxis.set_major_locator(plt.MaxNLocator(4))
    ax.grid(axis="x", alpha=.3)
    for lado in ("top", "right"):
        ax.spines[lado].set_visible(False)


def grafico_relatorio(res: pd.DataFrame, destino: Path) -> None:
    """Painéis A–C da especificação do relatório."""
    cores = {"A": AZUL, "B": AZUL_MEDIO, "C": AZUL_CLARO}
    fig, axes = plt.subplots(1, 4, figsize=(15, 4.2), sharey=True)
    for ax, (y, sub) in zip(axes, res[res.painel != "D"].groupby("desfecho", sort=False)):
        sub = sub.reset_index(drop=True)
        for i, r in sub.iterrows():
            ax.errorbar(r.coef, i, xerr=1.96 * r.erro_padrao, fmt="o", ms=7,
                        color=cores[r.painel], capsize=4, lw=2)
        _formatar_eixo(ax, sub.rotulo.iloc[0], [ROTULOS_PAINEIS[p] for p in sub.painel])
    axes[0].invert_yaxis()  # eixo y compartilhado: inverter uma única vez
    fig.suptitle("Efeito do recadastramento biométrico (DiD, IC 95%)", fontsize=13, x=0.01, ha="left")
    fig.text(0.01, 0.005, "Eleitores aptos caem e a taxa de comparecimento sobe; comparecimento absoluto "
             "e em relação à população não se alteram → efeito mecânico.", fontsize=9, color="#555")
    fig.tight_layout(rect=(0, 0.04, 1, 0.95))
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
