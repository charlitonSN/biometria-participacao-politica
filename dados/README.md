# Dados

## `brutos/` — dados de origem (não versionados)

Os dados brutos não estão no repositório. Eles só são necessários para **reconstruir** o painel com `01_construcao_base.do`. Para rodar a análise e os testes, basta o `processados/painel_final.dta`, que já está versionado.

Para reconstruir, baixe os arquivos abaixo e salve-os em `dados/brutos/` com exatamente estes nomes:

```
dados/brutos/
├── eleicoes.csv
├── municipios.xls
├── pop_total.xlsx
└── revisoes_biometricas/
    ├── 2008.csv
    ├── 2009.csv
    ├── …
    └── 2020.csv
```

### 1. Resultados eleitorais → `eleicoes.csv`

- **Fonte:** Base dos Dados, conjunto *Eleições brasileiras*, tabela de resultados por município: <https://basedosdados.org/dataset/eef764df-bde8-4905-b115-6fc23b6ba9d6?table=2e204854-e453-4257-9fef-5e10f3ff1f56>
- **Como baixar:** faça o download da tabela completa em CSV (~53 MB).
- **Colunas usadas:** `ano`, `turno`, `tipo_eleicao`, `cargo`, `sigla_uf`, `id_municipio`, `aptos`, `comparecimento`, `abstencoes`, `votos_validos`, `proporcao_comparecimento`, `proporcao_votos_validos`. O script filtra 2002–2022, 1º turno, eleições ordinárias, prefeito e governador.

### 2. Revisões biométricas → `revisoes_biometricas/AAAA.csv`

- **Fonte:** Tribunal Superior Eleitoral, *Histórico das Revisões Biométricas*: <https://sig.tse.jus.br/ords/dwtse/f?p=164:12>
- **Como baixar:** consulte um ano por vez, de 2008 a 2020, e exporte cada consulta em CSV com o nome do ano (`2008.csv`, `2009.csv`, …, `2020.csv`).
- **Formato esperado:** separador `;` e codificação Latin-1, com as colunas `UF;Município;(A);(P);% de P/A;(R);% de R/A;Data início;Data fim;Data fim prorrogada`. O script usa `UF`, `Município` e `Data fim`, que define o ano e o mês de conclusão da revisão.

### 3. Códigos dos municípios → `municipios.xls`

- **Fonte:** IBGE, *Divisão Territorial Brasileira (DTB)*: <https://www.ibge.gov.br/geociencias/organizacao-do-territorio/divisao-regional/23701-divisao-territorial-brasileira.html>
- **Como baixar:** baixe a DTB mais recente e use a planilha de municípios (*Relatório de Divisão Territorial Brasileira*, nível município). A versão usada aqui tem data-base 31/12/2024.
- **Formato esperado:** cabeçalho na linha 7, com as colunas `UF`, `Nome_UF`, `Código Município Completo` e `Nome_Município`.

### 4. População em 2010 → `pop_total.xlsx`

- **Fonte:** Atlas do Desenvolvimento Humano no Brasil (Pnud, Ipea e FJP), consulta *População total*: <http://www.atlasbrasil.org.br/consulta/população%20total>
- **Como baixar:** selecione o recorte **municípios**, o indicador **População total** e o ano **2010**, e exporte em Excel.
- **Formato esperado:** aba `Worksheet`, com as colunas `Territorialidades` (no formato "Nome do Município (UF)") e `População total 2010`.

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
