"""
Executa toda a análise em Python a partir de dados/processados/painel_final.dta.

Uso (na raiz do repositório):
    pip install -r requirements.txt
    python codigo/python/main.py

Saídas
    resultados/tabelas/estatisticas_descritivas.csv
    resultados/tabelas/distribuicao_tratamento.csv
    resultados/tabelas/resultados_did.csv        (especificação do relatório)
    resultados/tabelas/comparacao_artigo.csv     (especificação do artigo × Tabela 2)
    resultados/figuras/comparacao_artigo.png
    resultados/figuras/tendencias_estadual_2018.png
"""
from biometria import config
from biometria.dados import carregar_painel, distribuicao_tratamento, estatisticas_descritivas
from biometria.figuras import grafico_comparacao, grafico_tendencias
from biometria.modelos import paineis_artigo, paineis_relatorio


def main() -> None:
    config.TABELAS.mkdir(parents=True, exist_ok=True)
    config.FIGURAS.mkdir(parents=True, exist_ok=True)
    df = carregar_painel()

    print("1/4  Estatísticas descritivas")
    estatisticas_descritivas(df).to_csv(config.TABELAS / "estatisticas_descritivas.csv", index_label="variavel")
    distribuicao_tratamento(df).to_csv(config.TABELAS / "distribuicao_tratamento.csv", index_label="ano")

    print("2/4  DiD — especificação do relatório (painéis A–D)")
    rel = paineis_relatorio(df)
    rel.round(4).to_csv(config.TABELAS / "resultados_did.csv", index=False)

    print("3/4  DiD — especificação do artigo e comparação com a Tabela 2")
    art = paineis_artigo(df)
    art.round(4).to_csv(config.TABELAS / "comparacao_artigo.csv", index=False)
    grafico_comparacao(art, config.FIGURAS / "comparacao_artigo.png")
    grafico_tendencias(df, config.FIGURAS / "tendencias_estadual_2018.png")

    print("4/4  Resumo\n")
    cols = ["painel", "rotulo", "coef", "erro_padrao", "p_valor", "n"]
    print("Relatório:\n" + rel[cols].round(4).to_string(index=False))
    cols = ["painel", "rotulo", "coef_artigo", "coef_replicacao", "ep_artigo", "ep_replicacao", "p_valor_replicacao"]
    print("\nArtigo × replicação:\n" + art[cols].round(4).to_string(index=False))


if __name__ == "__main__":
    main()
