/*==============================================================================
  06_especificacao_artigo.do — painéis A–D com a especificação do artigo

  Reproduz a Tabela 2 de Forquesato & Rodrigues (2023):
    - uma regressão por tipo de eleição (governador: A, B e D; prefeito: C);
    - grupo tratado contra nunca tratados (nas estaduais, também o grupo
      recadastrado após 2018, o que reproduz o N do artigo);
    - comparecimento/aptos em fração (0–1);
    - efeitos fixos de município e eleição, erros clusterizados por UF e eleição;
    - placebo: eleições estaduais de 2002 a 2014, com 2010 e 2014 como "pós".

  Mesma especificação de codigo/python/biometria/modelos.py (paineis_artigo).
  Obs.: o reghdfe descarta observações singleton, o que pode gerar diferenças
  mínimas em relação à versão em Python.

  Entrada : dados/processados/painel_final.dta
  Saída   : resultados/tabelas/stata/artigo_painel_A.csv … _D.csv
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}

use "$proc/painel_final.dta", clear

* Primeira eleição em que o município é tratado (0 = nunca tratado)
bysort cod_mun: egen g_est = min(cond(trat_est == 1, ano, .))
bysort cod_mun: egen g_mun = min(cond(trat_mun == 1, ano, .))
replace g_est = 0 if missing(g_est)
replace g_mun = 0 if missing(g_mun)

gen prop_compa_f = prop_compa / 100
label variable prop_compa_f "Comparecimento / aptos (fração)"

tempfile base
save `base'

*            painel  cargo         grupo  tratamento  controles         ano pós  ano máx.
local p1 `"  A       governador    g_est  2018        "0, 2022"         2018     2022   "'
local p2 `"  B       governador    g_est  2014        "0, 2022"         2014     2022   "'
local p3 `"  C       prefeito      g_mun  2016        "0"               2016     2022   "'
local p4 `"  D       governador    g_est  2018        "0, 2022"         2010     2014   "'

local desfechos_artigo "l_aptos prop_compa_f prop_pop l_compa"

forvalues i = 1/4 {
    tokenize `p`i''
    local painel `1'
    local cargo  `2'
    local g      `3'
    local t0     `4'
    local ctrl   `5'
    local tpos   `6'
    local tmax   `7'

    display _newline as result "==== Painel `painel' (especificação do artigo) ===="

    use `base', clear
    keep if cargo == "`cargo'" & ano <= `tmax'
    keep if inlist(`g', `t0', `ctrl')
    gen did = (`g' == `t0') & (ano >= `tpos')
    label variable did "Tratado × Pós"

    eststo clear
    foreach y of local desfechos_artigo {
        reghdfe `y' did, absorb(cod_mun ano) vce(cluster uf ano)
        eststo `y'
    }

    local opcoes se b(%9.4f) se(%9.4f) keep(did) mtitles(`desfechos_artigo') ///
        scalars("N N") label compress nostar

    esttab `desfechos_artigo', `opcoes'
    esttab `desfechos_artigo' using "$tab/artigo_painel_`painel'.csv", `opcoes' csv replace
}
