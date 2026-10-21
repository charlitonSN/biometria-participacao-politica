/*==============================================================================
  02_descritivas.do — estatísticas descritivas e distribuição do tratamento

  Entrada : dados/processados/painel_final.dta
  Saídas  : resultados/tabelas/stata/estatisticas_descritivas.csv
            resultados/tabelas/stata/distribuicao_tratamento_municipal.csv
            resultados/tabelas/stata/distribuicao_tratamento_estadual.csv
==============================================================================*/

if "$raiz" == "" {
    display as error "Defina os caminhos rodando 00_master.do."
    exit 198
}

use "$proc/painel_final.dta", clear
xtset cod_mun ano

summarize

* Tabela descritiva do relatório
local vars ano pop_total aptos compa abst validos prop_compa prop_pop ///
           l_aptos l_compa l_abst l_validos
estpost tabstat `vars', statistics(count mean sd min max) columns(statistics)
esttab using "$tab/estatisticas_descritivas.csv", replace csv noobs nonumber ///
    cells("count mean(fmt(4)) sd(fmt(4)) min max")

* Distribuição dos grupos de tratamento por ano
tab ano trat_mun
estpost tabulate ano trat_mun
esttab using "$tab/distribuicao_tratamento_municipal.csv", replace csv ///
    cell(b) unstack noobs nonumber

tab ano trat_est
estpost tabulate ano trat_est
esttab using "$tab/distribuicao_tratamento_estadual.csv", replace csv ///
    cell(b) unstack noobs nonumber
