/*==============================================================================
  O recadastramento biométrico reduz a participação política?
  Replicação de Forquesato & Rodrigues (2023), Estudos Econômicos 53(3)

  00_master.do — executa todas as etapas da análise em Stata

  Autor : Charliton da Silva Nogueira
  Stata : 17 ou superior (xtdidregress)

  Como usar
    1. Ajuste o global `raiz` abaixo para a pasta do repositório.
    2. Rode este arquivo:  do "codigo/stata/00_master.do"

  Etapas
    01_construcao_base.do       painel município × ano a partir das bases brutas
    02_descritivas.do           estatísticas descritivas e distribuição do tratamento
    03_did_relatorio.do         DiD, painéis A–C (especificação do relatório)
    04_placebo.do               teste placebo, painel D (especificação do relatório)
    05_tendencias_paralelas.do  gráficos de tendências pré-tratamento
    06_especificacao_artigo.do  painéis A–D com a especificação do artigo
==============================================================================*/

version 17
clear all
set more off

* ---------------------------------------------------------------- caminhos
global raiz    "C:/caminho/para/biometria-participacao-politica"   // <-- AJUSTE AQUI

global codigo  "$raiz/codigo/stata"
global brutos  "$raiz/dados/brutos"
global proc    "$raiz/dados/processados"
global tab     "$raiz/resultados/tabelas/stata"
global fig     "$raiz/resultados/figuras/tendencias_paralelas"

capture mkdir "$raiz/resultados/tabelas/stata"

* ---------------------------------------------------------------- parâmetros
* Variáveis dependentes, na ordem das colunas (1)–(4) do artigo
global desfechos "l_aptos prop_compa prop_pop l_compa"

* 1 = reconstrói o painel a partir dos dados brutos (requer dados/brutos/eleicoes.csv;
*     veja dados/README.md). 0 = usa dados/processados/painel_final.dta já pronto.
local reconstruir_base 0

* ---------------------------------------------------------------- pacotes
foreach pacote in estout ftools reghdfe {
    capture which `pacote'
    if _rc ssc install `pacote', replace
}

* ---------------------------------------------------------------- execução
log using "$raiz/resultados/log_stata.log", text replace

if `reconstruir_base' do "$codigo/01_construcao_base.do"
do "$codigo/02_descritivas.do"
do "$codigo/03_did_relatorio.do"
do "$codigo/04_placebo.do"
do "$codigo/05_tendencias_paralelas.do"
do "$codigo/06_especificacao_artigo.do"

log close
