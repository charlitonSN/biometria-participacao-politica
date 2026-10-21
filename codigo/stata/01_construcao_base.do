/*==============================================================================
  01_construcao_base.do — construção do painel município × ano

  Entradas (dados/brutos)
    municipios.xls                 códigos IBGE e nomes dos municípios
    eleicoes.csv                   resultados eleitorais (Base dos Dados)
    revisoes_biometricas/AAAA.csv  revisões biométricas concluídas (TSE), 2008–2020
    pop_total.xlsx                 população em 2010 (Atlas Brasil)

  Saídas (dados/processados)
    base_mun.dta, eleicoes.dta, base_biometria.dta, pop_total.dta
    painel_final.dta               painel usado em todas as estimações

  Executado por 00_master.do (que define os globals de caminho).
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}
cd "$proc"


*==============================================================================
* 1. Municípios: chave código IBGE ↔ nome
*==============================================================================
import excel "$brutos/municipios.xls", cellrange(A7) firstrow clear

destring CódigoMunicípioCompleto, generate(cod_mun)
keep UF Nome_UF Nome_Município cod_mun

rename Nome_UF       uf
rename Nome_Município mun
rename UF            cod_uf

replace mun = ustrlower(mun)
replace mun = trim(mun)

drop cod_uf uf
duplicates report cod_mun

save base_mun.dta, replace


*==============================================================================
* 2. Resultados eleitorais: 1º turno, eleições ordinárias, prefeito e governador
*==============================================================================
import delimited "$brutos/eleicoes.csv", clear

drop if ano < 2002 | ano > 2022

* Apenas 1º turno
drop if turno == 2
drop turno id_municipio_tse

* Cargos do Executivo, como no artigo replicado
keep if cargo == "prefeito" | cargo == "governador"

* Exclui eleições suplementares
keep if tipo_eleicao == "eleicao ordinaria"

drop id_eleicao tipo_eleicao data_eleicao secoes secoes_agregadas        ///
     aptos_totalizadas secoes_totalizadas votos_brancos votos_nulos     ///
     votos_nominais votos_legenda proporcao_votos_brancos               ///
     proporcao_votos_nulos

tab cargo ano

rename sigla_uf     uf
rename id_municipio cod_mun

duplicates report cod_mun ano

* Observação sem código de município
list ano uf cod_mun if missing(cod_mun)
drop if missing(cod_mun)

save eleicoes.dta, replace


*==============================================================================
* 3. Revisões biométricas (TSE): empilha os arquivos anuais
*==============================================================================
local anos 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020

clear
tempfile base_total
save `base_total', emptyok

foreach a of local anos {
    import delimited "$brutos/revisoes_biometricas/`a'.csv", clear

    replace município = ustrlower(município)
    replace município = trim(município)

    * Ano e mês de conclusão da revisão
    gen datafim_dt = date(datafim, "DMY")
    format datafim_dt %td
    gen ano = year(datafim_dt)
    gen mes = month(datafim_dt)

    keep uf município ano mes
    drop if uf == "Total"

    append using `base_total'
    save `base_total', replace
}

use `base_total', clear

/* Definição do tratamento
   O município é tratado na primeira eleição realizada após a conclusão da
   revisão. Como as eleições ocorrem em outubro, uma revisão concluída até
   setembro do ano eleitoral já vale para a eleição daquele ano. */

* Eleições municipais (prefeito)
gen eleicao_municipal = .
replace eleicao_municipal = 2008 if  ano < 2008 | (ano == 2008 & mes < 10)
replace eleicao_municipal = 2012 if (ano > 2008 | (ano == 2008 & mes > 10)) & (ano < 2012 | (ano == 2012 & mes < 10))
replace eleicao_municipal = 2016 if (ano > 2012 | (ano == 2012 & mes > 10)) & (ano < 2016 | (ano == 2016 & mes < 10))
replace eleicao_municipal = 2020 if (ano > 2016 | (ano == 2016 & mes > 10))

* Eleições estaduais (governador)
gen eleicao_estadual = .
replace eleicao_estadual = 2010 if  ano < 2010 | (ano == 2010 & mes < 10)
replace eleicao_estadual = 2014 if (ano > 2010 | (ano == 2010 & mes > 10)) & (ano < 2014 | (ano == 2014 & mes < 10))
replace eleicao_estadual = 2018 if (ano > 2014 | (ano == 2014 & mes > 10)) & (ano < 2018 | (ano == 2018 & mes < 10))
replace eleicao_estadual = 2022 if (ano > 2018 | (ano == 2018 & mes > 10))

rename município mun

duplicates drop mun uf, force
sort eleicao_municipal eleicao_estadual
tab eleicao_municipal eleicao_estadual

drop mes
save base_biometria.dta, replace


*==============================================================================
* 4. População total (Censo 2010, Atlas Brasil)
*==============================================================================
import excel "$brutos/pop_total.xlsx", sheet("Worksheet") firstrow clear

keep Territorialidades Populaçãototal2010
rename Populaçãototal2010 pop
rename Territorialidades  municipio

* "Nome do Município (UF)" → nome e UF
split municipio, parse("(")
rename municipio1 mun
rename municipio2 sigla_uf

gen uf = ""
replace uf = trim(subinstr(sigla_uf, ")", "", .)) if sigla_uf != ""

replace mun = ustrlower(mun)
replace mun = trim(mun)

destring pop, generate(pop_total)
drop municipio sigla_uf pop

duplicates report mun uf
save pop_total.dta, replace


*==============================================================================
* 5. Painel final
*==============================================================================
use base_mun.dta, clear
merge 1:m cod_mun using eleicoes.dta
drop _merge

duplicates report cod_mun ano

* Revisões biométricas (merge por nome do município e UF)
merge m:1 mun uf using base_biometria.dta
drop _merge

* Indicadores de tratamento: 1 na eleição em que o município passa a ser tratado
gen trat_mun = 0
replace trat_mun = 1 if ano == eleicao_municipal

gen trat_est = 0
replace trat_est = 1 if ano == eleicao_estadual

* Conferências
count if trat_mun == 1 & ano <  2008
count if trat_est == 1 & ano <  2008
count if trat_mun == 1 & ano >= 2008
count if trat_est == 1 & ano >= 2008
duplicates report cod_mun ano
tab trat_mun, missing
tab trat_est, missing

* População
merge m:1 mun uf using pop_total.dta
sort cod_mun ano

drop if missing(pop_total, cod_mun)
bysort cod_mun (pop_total): replace pop_total = pop_total[1] if missing(pop_total)

drop _merge eleicao_municipal eleicao_estadual
order cargo uf mun cod_mun ano pop_total

rename comparecimento           compa
rename abstencoes               abst
rename votos_validos            validos
rename proporcao_comparecimento prop_compa
rename proporcao_votos_validos  prop_validos

* Variáveis de resultado
generate l_aptos   = log(aptos)
generate l_compa   = log(compa)
generate l_abst    = log(abst)
generate l_validos = log(validos)
generate prop_pop  = (compa / pop_total)

tabstat ano pop_total aptos compa abst validos prop_compa prop_validos       ///
        trat_mun trat_est l_aptos l_compa l_abst l_validos prop_pop,         ///
        statistics(mean sd p50 min max cv) columns(statistics)

label variable cargo        "Cargo Executivo"
label variable uf           "Unidade da federação"
label variable cod_mun      "Código do Município"
label variable ano          "Ano de Referência"
label variable mun          "Nome do Município"
label variable pop_total    "População Total"
label variable aptos        "Número de eleitores aptos"
label variable compa        "Número de Comparecimentos"
label variable abst         "Número de Abstenções"
label variable validos      "Número de votos válidos"
label variable prop_compa   "taxa de eleitores que compareceram para votar em relação ao total de eleitores aptos no município/ano."
label variable prop_validos "taxa de votos válidos em relação ao total de eleitores que compareceram."
label variable l_aptos      "Log de Aptos a votar"
label variable l_compa      "Log de comparecimento"
label variable l_abst       "Log de Abstenções"
label variable l_validos    "Log de votos válidos"
label variable prop_pop     "Razão entre comparecimento em relação à população total."
label variable trat_mun     "Tratamento - Eleição Municipal"
label variable trat_est     "Tratamento - EleiçãoEstadual"

save painel_final.dta, replace
