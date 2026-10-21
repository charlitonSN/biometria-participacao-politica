/*==============================================================================
  04_placebo.do — teste placebo, painel D (especificação do relatório)

  Eleições estaduais de 2010 e 2014. "Tratados" = municípios que só seriam
  tratados em 2018; "pós" = 2014. Efeitos fixos de município e ano, erros
  clusterizados por UF e ano (reghdfe).

  Obs.: com apenas 2 anos, o reghdfe usa min(G) − 1 = 1 grau de liberdade
  para o teste t, o que torna os p-valores bastante conservadores.

  Entrada : dados/processados/painel_final.dta
  Saídas  : resultados/tabelas/stata/placebo_painel_D.csv
            resultados/figuras/tendencias_paralelas/placebo_2010_2014_*.png
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}

use "$proc/painel_final.dta", clear

* Primeira eleição estadual em que o município é tratado (0 = nunca tratado)
bysort cod_mun: egen ano_trat_real = min(cond(trat_est == 1, ano, .))
replace ano_trat_real = 0 if ano_trat_real == .

label define tratyear 0 "Nunca tratado" 2010 "Tratado em 2010" 2014 "Tratado em 2014" ///
                      2018 "Tratado em 2018" 2022 "Tratado em 2022", replace
label values ano_trat_real tratyear

keep if inlist(ano, 2010, 2014)

gen tratado_placebo = (ano_trat_real == 2018)
gen pos_placebo     = (ano == 2014)
gen did_placebo     = tratado_placebo * pos_placebo
label variable did_placebo "Tratado (2018) × 2014"

eststo clear
foreach y of global desfechos {
    reghdfe `y' did_placebo, absorb(cod_mun ano) vce(cluster uf ano)
    eststo `y'
}

local opcoes se star(* 0.10 ** 0.05 *** 0.01) b(%9.3f) se(%9.3f) keep(did_placebo) ///
    mtitles($desfechos) label compress

esttab $desfechos, `opcoes'
esttab $desfechos using "$tab/placebo_painel_D.csv", `opcoes' csv replace

* Gráficos: médias de tratados e controles em 2010 e 2014
foreach y in l_aptos prop_compa {
    preserve
    collapse (mean) `y', by(ano tratado_placebo)
    twoway                                                                      ///
        (line `y' ano if tratado_placebo == 0, lwidth(medthick) lpattern(solid)) ///
        (line `y' ano if tratado_placebo == 1, lwidth(medthick) lpattern(dash)), ///
        legend(order(1 "Controle (Nunca tratados)" 2 "Futuros tratados em 2018")) ///
        title("Placebo: Tendências 2010-2014")                                  ///
        xtitle("Ano") ytitle("Média de `y'")
    graph export "$fig/placebo_2010_2014_`y'.png", replace width(1600)
    restore
}
