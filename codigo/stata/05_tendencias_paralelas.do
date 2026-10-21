/*==============================================================================
  05_tendencias_paralelas.do — gráficos de tendências pré-tratamento

  Para cada painel (estaduais 2018, estaduais 2014, municipais 2016) e cada
  variável dependente: média anual de tratados (linha contínua) e controles
  (linha tracejada), com o ano do tratamento marcado em vermelho.

  Entrada : dados/processados/painel_final.dta
  Saídas  : resultados/figuras/tendencias_paralelas/<painel>_<variável>.png
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}

local paineis    "estadual_2018 estadual_2014 municipal_2016"
local var_trat   "trat_est trat_est trat_mun"
local ano_trat   "2018 2014 2016"

forvalues i = 1/3 {
    local painel : word `i' of `paineis'
    local tv     : word `i' of `var_trat'
    local t0     : word `i' of `ano_trat'

    use "$proc/painel_final.dta", clear
    gen trat_ano = (`tv' == 1 & ano == `t0')
    bysort cod_mun: egen grupo_trat = max(trat_ano)

    foreach y of global desfechos {
        preserve
        collapse (mean) `y', by(ano grupo_trat)
        twoway                                                    ///
            (line `y' ano if grupo_trat == 1, lpattern(solid))    ///
            (line `y' ano if grupo_trat == 0, lpattern(dash)),    ///
            xline(`t0', lcolor(red) lpattern(dash))               ///
            legend(label(1 "Tratados") label(2 "Controle"))       ///
            xtitle("Ano") ytitle("Média de `y'")                  ///
            title("Tendências pré-tratamento")                    ///
            xlabel(, angle(vertical))
        graph export "$fig/`painel'_`y'.png", replace width(1600)
        restore
    }
}
