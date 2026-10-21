/*==============================================================================
  03_did_relatorio.do — Diferença em Diferenças, painéis A–C (especificação do relatório)

  Painel A  eleições estaduais, municípios tratados em 2018
  Painel B  eleições estaduais, municípios tratados em 2014
  Painel C  eleições municipais, municípios tratados em 2016

  Para cada painel: did = pós × grupo tratado, estimado com
  xtdidregress (efeitos fixos de município e ano, erros clusterizados por
  município), seguido do teste de tendências paralelas (estat ptrends).

  Entrada : dados/processados/painel_final.dta
  Saídas  : resultados/tabelas/stata/did_painel_A.csv, _B.csv, _C.csv
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}

use "$proc/painel_final.dta", clear
xtset cod_mun ano

local paineis    "A B C"
local var_trat   "trat_est trat_est trat_mun"
local ano_trat   "2018 2014 2016"

forvalues i = 1/3 {
    local painel : word `i' of `paineis'
    local tv     : word `i' of `var_trat'
    local t0     : word `i' of `ano_trat'

    display _newline as result "==== Painel `painel': `tv', tratados em `t0' ===="

    * Grupo tratado: municípios com tratamento no ano `t0' (fixo para todos os anos)
    capture drop trat_ano grupo_trat post did
    gen trat_ano = (`tv' == 1 & ano == `t0')
    bysort cod_mun: egen grupo_trat = max(trat_ano)
    gen post = (ano >= `t0')
    gen did  = post * grupo_trat
    label variable did "Tratado × Pós"

    tab post grupo_trat

    eststo clear
    foreach y of global desfechos {
        xtdidregress (`y') (did), group(cod_mun) time(ano)
        estat ptrends
        capture noisily estadd scalar p_ptrends = r(p)
        eststo `y'
    }

    local opcoes se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) se(%9.3f) keep(did) ///
        mtitles($desfechos) scalars("p_ptrends p-valor tendências paralelas" "N N") ///
        label compress

    esttab $desfechos, `opcoes'
    esttab $desfechos using "$tab/did_painel_`painel'.csv", `opcoes' csv replace
}
