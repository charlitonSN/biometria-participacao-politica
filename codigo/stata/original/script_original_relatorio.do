clear all

//Carregar pasta com os arquivos
cd "C:\Users\charl\OneDrive\Área de Trabalho\TRABALHO AVALIACAO DE IMPACTOS\DADOS2\"

/////////////////////////////////////////////////////////

//Importar base de dados com codigo e nome do municipio para utilizar como base para o merge
import excel "municipios.xls", cellrange(A7) firstrow clear

//Transformar em Tipo numérico
destring CódigoMunicípioCompleto, generate(cod_mun)

// Deixar na base de dados apenas as variaveis que serão utilizadas
keep UF Nome_UF Nome_Município cod_mun

//Renomear as variaveis
rename Nome_UF uf
rename Nome_Município mun
rename UF cod_uf

// Transforma em minúsculas
replace mun = ustrlower(mun)

// remove espaços extras no início/fim
replace mun = trim(mun) 

// Excluir 
drop cod_uf uf     

//Verificar dados duplicados
duplicates report cod_mun

//Salvar a base de dados 
save base_mun.dta, replace

//////////////////////////////////////////////////////////

//Importar base de dados com detalhes sobre as votacoes
import delimited "eleicoes.csv", clear

// Excluir os anos inferiores a 2002 e maior que 2022
drop if ano < 2002 | ano > 2022 

// Excluir o segundo turno, pois a análise será feita com base apenas no primeiro. Excluir tambem codigo tse, pois será desnecessário
drop if turno == 2
drop turno id_municipio_tse

// manter na base de dados apenas prefeitos e Governadores, tal como o artigo replicado, ou seja, odis cargos do executivo
keep if cargo == "prefeito" | cargo == "governador"

//Deixar na base de dados apenas as eleições ordinárias e excluir as suplementares
keep if tipo_eleicao == "eleicao ordinaria"

//Excluir as variaveis que não serão utilizadas
drop id_eleicao tipo_eleicao data_eleicao secoes secoes_agregadas aptos_totalizadas secoes_totalizadas votos_brancos votos_nulos votos_nominais votos_legenda proporcao_votos_brancos proporcao_votos_nulos

// Verificar distribuição dos cargos
tab cargo ano

// Renomear 
rename sigla_uf uf

//Renomear id_municipio
rename id_municipio cod_mun

//Verificar dados duplicados
duplicates report cod_mun ano

// Excluir observação que não possui o codigo do municipio
list ano uf cod_mun if missing(cod_mun)
drop if missing(cod_mun)

//Salvar em dta.
save eleicoes.dta, replace

//////////////////////////////////////////////////
////// JUNTAR A BASE DE DADOS POR MEIO DO APPEND

// Criar Lista de anos
local anos 2008 2009 2010 2011 2012 2013 2014  2015 2016 2017 2018 2019 2020

clear
tempfile base_total
save `base_total', emptyok

foreach as of local anos {

    import delimited "`as'.csv", clear
    
    // Transforma em minúsculas
    replace mun = ustrlower(mun)

    // remove espaços extras no início/fim
    replace mun = trim(mun)   

    // Extrair Data
    // converte string em data
    gen datafim_dt = date(datafim, "DMY")
	
    // aplica formato de data   
    format datafim_dt %td                  

    // Extrair o ano
    gen ano = year(datafim_dt)
	
	// Extrair mês
    gen mes = month(datafim_dt)

    // manter
    keep uf município ano mes

    // Excluir o total na variavel uf
    drop if uf == "Total"
	 
    // Empilhar na base total
    append using `base_total'
    save `base_total', replace
}

// Carregar base final
use `base_total', clear

// Criar variável de eleição municipal (prefeito)
// Estratégia utilizada: Os municipios são considerados tratados  dependendo do ano e o mês em que foi finalizado o cadastramento biométrico.
// O ano eleitoral pós finalização do cadastramento é considerado o ano em que o municipio foi tratado, levando em consideração que as eleições ocorrem em Outubro, então se nesse ano eleitoral o município finalizou o cadastramento até Setemrbo, ele é considerado tratado no mesmo ano.

gen eleicao_municipal = .
replace eleicao_municipal = 2008 if ano < 2008 | (ano == 2008 & mes < 10)
replace eleicao_municipal = 2012 if (ano > 2008 | (ano == 2008 & mes > 10)) & (ano < 2012 | (ano == 2012 & mes < 10))
replace eleicao_municipal = 2016 if (ano > 2012 | (ano == 2012 & mes > 10)) & (ano < 2016 | (ano == 2016 & mes < 10))
replace eleicao_municipal = 2020 if (ano > 2016 | (ano == 2016 & mes > 10))

// Criar variável de eleição estadual (governador)
gen eleicao_estadual = .
replace eleicao_estadual = 2010 if ano < 2010 | (ano == 2010 & mes < 10)
replace eleicao_estadual = 2014 if (ano > 2010 | (ano == 2010 & mes > 10)) & (ano < 2014 | (ano == 2014 & mes < 10))
replace eleicao_estadual = 2018 if (ano > 2014 | (ano == 2014 & mes > 10)) & (ano < 2018 | (ano == 2018 & mes < 10))
replace eleicao_estadual = 2022 if (ano > 2018 | (ano == 2018 & mes > 10))

//Renomear
rename município mun

// Excluir municipios duplicados
duplicates drop mun uf, force

// Ordena por município e pelos anos crescentes
sort eleicao_municipal eleicao_estadual

// Conferir distribuição
tab eleicao_municipal eleicao_estadual

//Excluir
drop mes

//Salvar a base de dados
save base_biometria.dta, replace

//////////////////////////////////////////////////

//Importar base de população total
import excel "C:\Users\charl\OneDrive\Área de Trabalho\TRABALHO AVALIACAO DE IMPACTOS\DADOS\pop_total.xlsx", sheet("Worksheet") firstrow clear

// Manter apenas as variaveis de interesse
keep Territorialidades Populaçãototal2010

// Renomear
rename Populaçãototal2010 pop
rename Territorialidades municipio

// Separar município e UF
split municipio, parse("(")
rename municipio1 mun
rename municipio2 sigla_uf

// Criar nova variável uf primeiro
gen uf = ""
replace uf = trim(subinstr(sigla_uf, ")", "", .)) if sigla_uf != ""

// Transforma em minúsculas
replace mun = ustrlower(mun)

// remove espaços extras no início/fim
replace mun = trim(mun)

//Transformar em Tipo numérico
destring pop, generate(pop_total)

// Remover variáveis temporárias
drop municipio sigla_uf pop

// Verificar duplicatas
duplicates report mun uf

// Salvar
save pop_total.dta, replace

///////////////////////////////////////////////

//Carregar a base de dados matriz
use base_mun.dta, clear
merge 1:m cod_mun using eleicoes.dta

//Apagar a variavel merge
drop _merge

// Fazer o merge da base de dados quantidade biometria de 2008 a 2022

// Verificar duplicatas
duplicates report cod_mun ano

// fazer o merge
merge m:1 mun uf using base_biometria.dta

// Excluir
drop _merge

// Gerar variaval tratamento para eleição municipal
gen trat_mun = 0
replace trat_mun = 1 if ano == eleicao_municipal

// Gerar variaval tratamento para eleição Estadual
gen trat_est = 0
replace trat_est = 1 if ano == eleicao_estadual

// Eleições antes de 2008 ( Os grupos nao receberam tratamento)
count if trat_mun == 1 & ano < 2008
count if trat_est == 1 & ano < 2008

// Eleições Depois de 2008 ( Os grupos receberam tratamento)
count if trat_mun == 1 & ano >= 2008
count if trat_est == 1 & ano >= 2008

//Identificar os dados duplicados
duplicates report cod_mun ano

//Verificar dados faltantes no ano de tratamento
tab trat_mun, missing
tab trat_est, missing

// Fazer o merge com a base de dados de População Total
merge m:1 mun uf using pop_total.dta

// Ordenar os dados por município e ano 
sort cod_mun ano

//Excluir dados cuja população esta com dados faltantes e os municipios que nao possui observações das eleições
drop if missing(pop_total, cod_mun)

// Preenche valores faltantes copiando de anos anteriores se ainda restar
bysort cod_mun (pop_total): replace pop_total = pop_total[1] if missing(pop_total)

// Excluir
drop _merge eleicao_municipal eleicao_estadual

// Reordenar
order cargo uf mun cod_mun ano pop_total 

// Renomear
rename comparecimento compa
rename abstencoes abst
rename votos_validos validos
rename proporcao_comparecimento prop_compa
rename proporcao_votos_validos prop_validos

// Gerar Logaritimos
generate  l_aptos = log(aptos)
generate  l_compa = log(compa)
generate  l_abst = log(abst)
generate  l_validos = log(validos)

// Gerar Número de comparecimento em relação à população total.
generate prop_pop = (compa / pop_total)

// Verificar tabela descritiva
tabstat ano pop_total aptos compa abst validos prop_compa prop_validos trat_mun trat_est l_aptos l_compa l_abst l_validos prop_pop, statistics ( mean sd p50 min max cv) columns(statistics)

// Inserir Legenda
label variable cargo "Cargo Executivo"
label variable uf "Unidade da federação"
label variable cod_mun "Código do Município"
label variable ano "Ano de Referência"
label variable mun "Nome do Município"
label variable pop_total "População Total"
label variable aptos "Número de eleitores aptos"
label variable compa "Número de Comparecimentos"
label variable abst "Número de Abstenções"
label variable validos "Número de votos válidos"
label variable prop_compa "taxa de eleitores que compareceram para votar em relação ao total de eleitores aptos no município/ano."
label variable prop_validos "taxa de votos válidos em relação ao total de eleitores que compareceram."
label variable l_aptos "Log de Aptos a votar"
label variable l_compa "Log de comparecimento"
label variable l_abst "Log de Abstenções"
label variable l_validos "Log de votos válidos"
label variable prop_pop "Razão entre comparecimento em relação à população total."
label variable trat_mun "Tratamento - Eleição Municipal"
label variable trat_est "Tratamento - EleiçãoEstadual"

// Salvar
save GRUPO3.dta, replace

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///Carregar pasta com os arquivos
cd "C:\Users\charl\OneDrive\Área de Trabalho\TRABALHO AVALIACAO DE IMPACTOS\DADOS2\"

// Instalar biblioteca
ssc install estout

//Abrir arquivo
use GRUPO3.dta, clear

// Informar ao stata que estou trabalhando com dados em painel
xtset cod_mun ano

// Gerar tabela descritiva
summarize
tab ano trat_mun
tab ano trat_est

//////// DID ESTADUAL TRATADOS 2018 ///////////

// Criar indicador do grupo que será tratado
gen trat_2018 = (trat_est == 1 & ano == 2018)

// Tornar o grupo permanente para todos os anos daquele município
bysort cod_mun: egen grupo_trat_2018 = max(trat_2018)

// Criar post
gen post = (ano >= 2018)

// Criar DID
gen did = post * grupo_trat_2018

// Conferir tabela
tab post grupo_trat_2018

// Estimar Did 1
xtdidregress (l_aptos) (did), group(cod_mun) time(ano)

//Salvar resultado
est store m1

// Não rejeita a hipotese de tendências paralelas
estat ptrends

// Estimar Did 2
xtdidregress (prop_compa) (did), group(cod_mun) time(ano)

//Salvar resultado
est store m2

// Não rejeita a hipotese de tendências paralelas
estat ptrends

// Estimar Did 3
xtdidregress (prop_pop) (did), group(cod_mun) time(ano)

//Salvar resultado
est store m3

// Rejeita a hipotese de tendências paralela
estat ptrends

// Estimar Did 4
xtdidregress (l_compa) (did), group(cod_mun) time(ano)

//Salvar resultado
est store m4

// Não rejeita hipotese de tendências paralelas
estat ptrends

// Gerar tabela com os resultados das regressões
esttab m1 m2 m3 m4, se star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) se(%9.3f) ///
    keep(*did*) ///
    mtitles("l_aptos" "prop_compa" "prop_pop" "l_compa") ///
    label compress
	
///////   RESULTADO  ///////////////////

/*como o denominador (aptos) diminuiu, a proporção de pessoas que compareceram ao voto em relação ao total de aptos aumenta, mesmo que o número absoluto de comparecimentos não mude.

Mas esse efeito poderia conter uma redução no sufrágio efetivo de eleitores 
reais, que deixariam de se registrar para o voto.

Existe um efeito "sobrevivente" ou indireto do tratamento na base de eleitores aptos, ou seja, além do efeito mecânico na taxa de comparecimento, existe uma redução real do sufrágio, causada por custos adicionais de registro ou recadastramento.

1 - Efeito mecânico vs efeito real

Efeito mecânico:

O denominador (eleitores aptos) diminui por uma mudança administrativa ou seleção do município.

O número de comparecimentos (compa) não muda.

Resultado: a taxa de comparecimento sobe automaticamente, mas não significa que mais pessoas de fato votaram; é apenas uma proporção alterada pelo denominador menor.

Efeito real no sufrágio (colunas 3 e 4):

Agora consideramos que a redução nos eleitores aptos reflete cidadãos que deixaram de se registrar para votar, ou seja, eles efetivamente deixam de participar do processo eleitoral.

Isso é importante porque o benefício de votar é muito baixo (chance de ser decisivo/pivotal), mas o custo de se registrar aumenta com o recadastramento.

Logo, o tratamento pode reduzir o sufrágio efetivo, não só alterar a proporção por efeito mecânico.

A coluna 3 analisa o efeito sobre o comparecimento como proporção da 
população (no Censo de 2010), sendo uma medida do efeito do recadastramento na participação eleitoral desconsiderando o seu efeito sobre o 
número de aptos a votar. Aqui, o efeito é tanto econômico quanto estatisticamente insignificante, indicando que todo o efeito do tratamento sobre o comparecimento como proporção dos aptos na coluna 2 advém da redução 
no número de aptos. A análise do log do comparecimento eleitoral, na coluna 4, fornece resultados similares e corrobora essa conclusão.
*/
	
////// TENDÊNCIAS PARALELAS //////////////////////

// Gráfico para Log Aptos
preserve
collapse (mean) l_aptos, by(ano grupo_trat_2018)
twoway ///
    (line l_aptos ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_aptos ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2018, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_aptos") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para proporção de comparecimento
preserve
collapse (mean) prop_compa, by(ano grupo_trat_2018)
twoway ///
    (line prop_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2018, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de Prop_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para proporção de População
preserve
collapse (mean) prop_pop, by(ano grupo_trat_2018)
twoway ///
    (line prop_pop ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_pop ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2018, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("PMédia de Prop_pop") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para Log Comparecimento
preserve
collapse (mean) l_compa, by(ano grupo_trat_2018)
twoway ///
    (line l_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2018, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

//////// DID ESTADUAL TRATADOS 2014 ///////////
use GRUPO3.dta, clear

// Informar ao stata que estou trabalhando com dados em painel
xtset cod_mun ano

// Gerar tabela descritiva
summarize
tab ano trat_mun
tab ano trat_est

// Criar indicador do grupo que será tratado
gen trat_2014 = (trat_est == 1 & ano == 2014)

* Tornar o grupo permanente para todos os anos daquele município
bysort cod_mun: egen grupo_trat_2014 = max(trat_2014)

// Criar post
gen post = (ano >= 2014)

// Criar DID
gen did = post * grupo_trat_2014

// Conferir tabela
tab post grupo_trat_2014

// Estimar Did 1
xtdidregress (l_aptos) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m1

//Não rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 2
xtdidregress (prop_compa) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m2

//Rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 3
xtdidregress (prop_pop) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m3

//Rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 4
xtdidregress (l_compa) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m4

//Rejeita a hipotese de tendência paralela
estat ptrends

// Gerar tabela com os resultados das regressões
esttab m1 m2 m3 m4, se star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) se(%9.3f) ///
    keep(*did*) ///
    mtitles("l_aptos" "prop_compa" "prop_pop" "l_compa") ///
    label compress
	
/*
No Painel B, realizamos o mesmo exercício para municípios tratados antes da eleição de 2014, encontrando resultados qualitativamente similares, porém, apenas na análise para log_aptos os grupos seguiram uma tendência paralela.

*/	
	
////// TENDÊNCIAS PARALELAS //////////////////////

// Gráfico para Logarítimo de Aptos
preserve
collapse (mean) l_aptos, by(ano grupo_trat_2014)
twoway ///
    (line l_aptos ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_aptos ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2014, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_aptos") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para Proporção de comparecimento
preserve
* seus comandos aqui
collapse (mean) prop_compa, by(ano grupo_trat_2014)
twoway ///
    (line prop_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2014, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de Prop_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para proporção de População
preserve
collapse (mean) prop_pop, by(ano grupo_trat_2014)
twoway ///
    (line prop_pop ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_pop ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2014, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de Prop_pop") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para Log Comparecimento
preserve
collapse (mean) l_compa, by(ano grupo_trat_2014)
twoway ///
    (line l_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2014, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore


//////// DID MUNICIPAL TRATADOS 2016 ///////////
use GRUPO3.dta, clear

// Informar ao stata que estou trabalhando com dados em painel
xtset cod_mun ano

// Criar indicador do grupo que será tratado
gen trat_2016 = (trat_mun == 1 & ano == 2016)

* Tornar o grupo permanente para todos os anos daquele município
bysort cod_mun: egen grupo_trat_2016 = max(trat_2016)

// Criar post
gen post = (ano >= 2016)

// Criar DID
gen did = post * grupo_trat_2016

// Conferir tabela
tab post grupo_trat_2016

// Estimar Did 1
xtdidregress (l_aptos) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m1

//Rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 2
xtdidregress (prop_compa) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m2

//Rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 3
xtdidregress (prop_pop) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m3

//Rejeita a hipotese de tendência paralela
estat ptrends

// Estimar Did 4
xtdidregress (l_compa) (did), group(cod_mun) time(ano)
//Salvar resultado
est store m4

// Não rejeita a hipotese de tendência paralela
estat ptrends

// Gerar tabela com os resultados das regressões
esttab m1 m2 m3 m4, se star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) se(%9.3f) ///
    keep(*did*) ///
    mtitles("l_aptos" "prop_compa" "prop_pop" "l_compa") ///
    label compress

/*No Painel C, analisamos não mais eleições estaduais, mas municipais. 
Preferimos especificações com eleições estaduais, em que diferentes municípios votam sobre os mesmos candidatos, reduzindo o ruído da regressão. Ainda assim, nas eleições municipais encontramos resultados quase idênticos. O número de eleitores aptos a votar diminui, gerando uma 
elevação no comparecimento de eleitores aptos, ainda que o comparecimento em si não tenha se alterado de forma estatisticamente significante.

O fato dos resultados encontrados serem 
bastante similares, mesmo alterando ao longo dos painéis o tipo de eleição 
e os grupos de tratamento, nos dá confiança da boa identificação do nosso exercício empírico  */
	
////// TENDÊNCIAS PARALELAS //////////////////////

// Gráfico para Logarítimo de Aptos
preserve
collapse (mean) l_aptos, by(ano grupo_trat_2016)
twoway ///
    (line l_aptos ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_aptos ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2016, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_aptos") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para Proporção de Comparecimento
preserve
collapse (mean) prop_compa, by(ano grupo_trat_2016)
twoway ///
    (line prop_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2016, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de prop_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para proporção de População
preserve
collapse (mean) prop_pop, by(ano grupo_trat_2016)
twoway ///
    (line prop_pop ano if grupo_trat == 1, lpattern(solid)) ///
    (line prop_pop ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2016, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de Prop_pop") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

// Gráfico para Log Comparecimento
preserve
collapse (mean) l_compa, by(ano grupo_trat_2016)
twoway ///
    (line l_compa ano if grupo_trat == 1, lpattern(solid)) ///
    (line l_compa ano if grupo_trat == 0, lpattern(dash)), ///
    xline(2016, lcolor(red) lpattern(dash)) ///
    legend(label(1 "Tratados") label(2 "Controle")) ///
    xtitle("Ano") ytitle("Média de l_compa") ///
    title("Tendências pré-tratamento") ///
    xlabel(, angle(vertical))
restore

///////PLACEBO ELEIÇÃO ESTADUAL 2018 ////////// 

use GRUPO3.dta, clear

//Instalar Biblioteca
ssc install reghdfe, replace

// Para cada município (cod_mun), identificar o primeiro ano em que trat_est==1
bysort cod_mun: egen ano_trat_real = min(cond(trat_est==1, ano, .))

// Os nunca tratados terão missing — definir como 0
replace ano_trat_real = 0 if ano_trat_real==.


label define tratyear 0 "Nunca tratado" 2010 "Tratado em 2010" 2014 "Tratado em 2014" 2018 "Tratado em 2018" 2022 "Tratado em 2022"
label values ano_trat_real tratyear

// Filtrar só 2010-2014
keep if inlist(ano, 2010, 2014)

// Criar indicador de tratado futuro
gen tratado_placebo = (ano_trat_real == 2018)

// Pós-período placebo
gen pos_placebo = (ano == 2014)

// Interação DID
gen did_placebo = tratado_placebo * pos_placebo

// Estimar Did 1
reghdfe l_aptos did_placebo, absorb(cod_mun ano) vce(cluster uf ano)

//Salvar resultado
est store m1

// Estimar Did 2
reghdfe prop_compa did_placebo, absorb(cod_mun ano) vce(cluster uf ano)

//Salvar resultado
est store m2

// Estimar Did 3
reghdfe prop_pop did_placebo, absorb(cod_mun ano) vce(cluster uf ano)

//Salvar resultado
est store m3

// Estimar Did 4
reghdfe l_compa did_placebo, absorb(cod_mun ano) vce(cluster uf ano)

//Salvar resultado
est store m4

// Gerar tabela com os resultados das regressões
esttab m1 m2 m3 m4, se star(* 0.10 ** 0.05 *** 0.01) ///
    b(%9.3f) se(%9.3f) ///
    keep(*did*) ///
    mtitles("l_aptos" "prop_compa" "prop_pop" "l_compa") ///
    label compress

// gerar gráfico para l_aptos
preserve
collapse (mean) l_aptos, by(ano tratado_placebo)

twoway ///
    (line l_aptos ano if tratado_placebo==0, lwidth(medthick) lpattern(solid) ) ///
    (line l_aptos ano if tratado_placebo==1, lwidth(medthick) lpattern(dash) ) ///
, ///
    legend(order(1 "Controle (Nunca tratados)" 2 "Futuros tratados em 2018")) ///
    title("Placebo: Tendências 2010-2014") ///
    xtitle("Ano") ytitle("Média de l_aptos")
restore

// gerar gráfico para Prop_compa
preserve
collapse (mean) prop_compa, by(ano tratado_placebo)

twoway ///
    (line prop_compa ano if tratado_placebo==0, lwidth(medthick) lpattern(solid) ) ///
    (line prop_compa ano if tratado_placebo==1, lwidth(medthick) lpattern(dash) ) ///
, ///
    legend(order(1 "Controle (Nunca tratados)" 2 "Futuros tratados em 2018")) ///
    title("Placebo: Tendências 2010-2014") ///
    xtitle("Ano") ytitle("Média de l_aptos")
restore



