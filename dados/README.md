# Dados

## `brutos/`

| Arquivo | Conteúdo | Fonte |
|---|---|---|
| `revisoes_biometricas/2008.csv` … `2020.csv` | Municípios com revisão biométrica concluída e datas de início/fim, por ano | TSE — [Histórico das Revisões Biométricas](https://sig.tse.jus.br/ords/dwtse/f?p=164:12) |
| `municipios.xls` | Código IBGE e nome de todos os municípios (chave de *merge*) | IBGE |
| `pop_total.xlsx` | População total dos municípios — Censo 2010 | [Atlas Brasil](http://www.atlasbrasil.org.br/consulta/população%20total) |
| `eleicoes.csv` | Resultados eleitorais por município (aptos, comparecimento, abstenções, votos válidos) | [Base dos Dados — Eleições brasileiras](https://basedosdados.org/dataset/eef764df-bde8-4905-b115-6fc23b6ba9d6?table=2e204854-e453-4257-9fef-5e10f3ff1f56) |

> **`eleicoes.csv` não está versionado** (~53 MB). Para reconstruir a base do zero, baixe a tabela *resultados por município* do conjunto "Eleições brasileiras" da Base dos Dados e salve como `dados/brutos/eleicoes.csv`. Para apenas rodar a análise, isso não é necessário: o painel final já está em `processados/painel_final.dta`.
>
> Os CSVs do TSE estão em codificação Latin-1 e separados por `;`.

## `processados/`

| Arquivo | Gerado por | Descrição |
|---|---|---|
| `painel_final.dta` | `01_construcao_base.do` | **Painel final** município × ano (2002–2022), 60.770 obs. Base usada em todas as estimações. |

Ao rodar `01_construcao_base.do`, também são gerados os arquivos intermediários `base_mun.dta`, `eleicoes.dta`, `base_biometria.dta` e `pop_total.dta`. Eles não são versionados (veja `.gitignore`).

### Dicionário do painel final

| Variável | Descrição |
|---|---|
| `cargo` | Cargo em disputa (`prefeito` ou `governador`) |
| `uf`, `mun`, `cod_mun` | UF, nome e código IBGE do município |
| `ano` | Ano da eleição |
| `pop_total` | População total (Censo 2010, constante no tempo) |
| `aptos` | Eleitores aptos |
| `compa` | Comparecimento |
| `abst` | Abstenções |
| `validos` | Votos válidos |
| `prop_compa` | Comparecimento / aptos (%) |
| `prop_validos` | Votos válidos / comparecimento (%) |
| `prop_pop` | Comparecimento / população total |
| `l_aptos`, `l_compa`, `l_abst`, `l_validos` | Logaritmos das variáveis correspondentes |
| `trat_mun` | 1 na eleição municipal em que o município passa a ser tratado |
| `trat_est` | 1 na eleição estadual em que o município passa a ser tratado |
