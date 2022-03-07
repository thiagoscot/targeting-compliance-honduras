/*
Author: Thiago Scot
Date: March 17th 2020
Modified:
Name: Analysis_RCT_HND.do
Description: Uses randomized database to produce descriptive tables for pre-analysis plan.
*/

di in red "Descriptives at baseline"

use "$output/randomized_base_experiment.dta", clear

encode calificacion_de_riesgo, gen(risk_level)

****************************************************************************************************************
*************************** POWER CALCULATION FOR EXPERIMENTAL SAMPLE ******************************************
****************************************************************************************************************


cap mat drop b c
eststo drop *
loc compliance = 0.6			//local defining compliance, defined as opening email. Using 60% of treatment group.


global controls "base_imponible_renta_2017_th ingresos_informados_2017_th ingresos_grav_declarados_2017_th presentó_djisr_2017 ingresos_isv_informados_2018_th i.strata"


*1. Power for revenue as an outcome
eststo: qui reg ingresos_isr_declarados_2018_th $controls, robust
qui predict res, res
qui summ res,d
loc sd_res = `r(sd)'

count if treatment_status == 0
loc N_control = `r(N)'

count if treatment_status == 1
loc N_treat1 = `r(N)'

qui summ ingresos_isr_declarados_2018_th,d
loc sd = `r(sd)'
loc mean = `r(mean)'
loc p50 = `r(p50)'
loc N = `r(N)'

power twomeans `mean', n(`N') sd(`sd_res') power(0.8) a(0.05)
loc rev_effect: di %18.2fc  (`r(diff)'/`compliance')
loc rev_perc_effect: di %18.3fc  (`r(diff)'/`compliance')/`mean'
loc rev_sd_effect: di %18.3fc  (`r(diff)'/`compliance')/`sd'

estadd local effect `rev_effect'
estadd loc perc_effect = `rev_perc_effect'
estadd loc sd_effect = `rev_sd_effect'
estadd local Strata "Yes"

**For each arm
power twomeans `mean', n1(`N_control') n2(`N_treat1') sd(`sd_res') power(0.8) a(0.05)
loc rev_effect_arms: di %18.2fc  (`r(diff)'/`compliance')
loc rev_perc_effect_arms: di %18.3fc  (`r(diff)'/`compliance')/`mean'

*2. Power for deductions as an outcome
eststo: qui reg deducciones_isr_2018_th $controls, robust
qui predict res_deduc, res
qui summ res_deduc,d
loc sd_res_deduc = `r(sd)'

qui summ deducciones_isr_2018_th,d
loc sd_deduc = `r(sd)'
loc mean_deduc = `r(mean)'
loc p50_deduc = `r(p50)'
loc N_deduc = `r(N)'

power twomeans `mean_deduc', n(`N_deduc') sd(`sd_res_deduc') power(0.8) a(0.05)
loc deduc_effect: di %18.2fc (`r(diff)'/`compliance')
loc deduc_perc_effect: di %18.3fc (`r(diff)'/`compliance')/`mean_deduc'
loc deduc_sd_effect: di %18.3fc  (`r(diff)'/`compliance')/`sd_deduc'

estadd loc effect = `deduc_effect'
estadd loc perc_effect = `deduc_perc_effect'
estadd loc sd_effect = `deduc_sd_effect'
 estadd local Strata "Yes"

**For each arm
power twomeans `mean_deduc',  n1(`N_control') n2(`N_treat1') sd(`sd_res_deduc') power(0.8) a(0.05)
loc deduc_effect_arms: di %18.2fc (`r(diff)'/`compliance')
loc deduc_perc_effect_arms: di %18.3fc (`r(diff)'/`compliance')/`mean_deduc'


*3. Power for profit/taxable base as an outcome
eststo: qui reg base_imponible_renta_2018_th $controls, robust
qui predict res_util, res
qui summ res_util ,d
loc sd_res_util = `r(sd)'

qui summ base_imponible_renta_2018_th,d
loc sd_util = `r(sd)'
loc mean_util = `r(mean)'
loc p50_util = `r(p50)'
loc N_util = `r(N)'

power twomeans `mean_util', n(`N_util') sd(`sd_res_util') power(0.8) a(0.05)
loc util_effect: di %18.2fc (`r(diff)'/`compliance')
loc util_perc_effect: di %18.3fc  (`r(diff)'/`compliance')/`mean_util'
loc util_sd_effect: di %18.3fc  (`r(diff)'/`compliance')/`sd_util'

estadd loc effect = `util_effect'
estadd loc perc_effect = `util_perc_effect'
estadd loc sd_effect = `util_sd_effect'
 estadd local Strata "Yes"

**For each arm
power twomeans `mean_deduc',  n1(`N_control') n2(`N_treat1') sd(`sd_res_util') power(0.8) a(0.05)
loc util_effect_arms: di %18.2fc (`r(diff)'/`compliance')
loc util_perc_effect_arms: di %18.3fc (`r(diff)'/`compliance')/`mean_deduc'


*4. Power for filing declaration as an outcome
qui summ presentó_djisr_2018,d
loc positivo = `r(mean)'
loc sd_pres  = `r(sd)'

qui power twoproportions `positivo', n(`N') power(0.8) a(0.05)
loc efect_pos = (`r(diff)'/`compliance')
loc efect_perc_pos = (`r(diff)'/`compliance')/`positivo'
loc efect_sd_pos = (`r(diff)'/`compliance')/`sd_pres'

**Treatment arms
qui power twoproportions `positivo', n1(`N_control') n2(`N_treat1') power(0.8) a(0.05)
loc efect_pos_arms = (`r(diff)'/`compliance')
loc efect_perc_pos_arms = (`r(diff)'/`compliance')/`positivo'


mat b = nullmat(b) \ (`rev_effect',`rev_perc_effect')
mat b = nullmat(b) \ (`deduc_effect',`deduc_perc_effect')
mat b = nullmat(b) \ (`util_effect',`util_perc_effect')
mat b = nullmat(b) \ (`efect_pos',`efect_perc_pos')

mat c = nullmat(c) \ (`rev_effect_arms',`rev_perc_effect_arms')
mat c = nullmat(c) \ (`deduc_effect_arms',`deduc_perc_effect_arms')
mat c = nullmat(c) \ (`util_effect_arms',`util_perc_effect_arms')
mat c = nullmat(c) \ (`efect_pos_arms',`efect_perc_pos_arms')

drop res res_util res_deduc



********   Table A4: Power Calculations - Final Sample
frmttable using "$tables/power_calcs_alt", replace statmat(b) tex ///
ctitle("Outcome", "Levels", "Percent" \ "","\it{MDE of pooled treatment}","")  nocenter  ///
rtitle("Gross Income"\ "Deductions"\ "Taxable Income"\ "Filing probability") ///
fr  sdec(2,3) addrows("" "\it{MDE of treatment arms}")

frmttable using "$tables/power_calcs_alt", append statmat(c) tex hline(110000100001) ///
rtitle("Gross Income"\ "Deductions"\ "Taxable Income"\ "Filing probability") ///
fr  sdec(2,3) nocenter  



*******    Table A3: Power Calculations - Residual Variance
esttab using "$tables/regressions_power.tex",  drop(*strata*) replace f label ///
	 booktabs b(3) se(3) eqlabels(none) alignment(S) stats(N r2 Strata  , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared "Strata FE")) ///
	 mtitles("Revenue" "Deductions" "Taxable Income") ///
	 mgroups("2018 primary outcomes", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 0)) ///
	star(* 0.10 ** 0.05 *** 0.01) 

	
	
	
****DESCRIPTIVE STATS
global vars "juridico_dummy comerciante_individual profesional_ind_natural jur_comerc_ind region_1 region_2 "
global vars2 "at_2019_th ingresos_isv_2019_th presentó_djisr_2018  ingresos_isr_informados_2018_th ingresos_isr_declarados_2018_th ing_isr_2018_declared tax_status_18_1 tax_status_18_2 tax_status_18_3 tax_base_2018_declared  impuesto_2018_declared effec_taxrate presentó_djisr_2017  ingresos_informados_2017_th ingresos_grav_declarados_2017_th ing_isr_2017_declared tax_base_2017_declared  impuesto_2017_declared"
global vars3 "ingresosdeterceros_2019 reported_OT reported_atc reported_siafi reported_export hadeclaradoperdidasfiscales movimientosfinancieros datosatipicos riesgo_1 riesgo_2 riesgo_3 riesgo_4 riesgo_5"

******    TABLE 1: Descriptive Statistics - Final Sample
estpost su $vars
est store indiv
esttab indiv using "$tables/descriptive_final.tex", replace ///
				refcat(juridico_dummy "\emph{Panel A: Taxpayers' characteristics}" , nolabel) ///
				cells("mean(fmt(%18.2fc)) sd p50 count(fmt(%18.0fc))") label booktabs nonum collabels("Mean" "SD" "p50" "N") f nogaps noobs		
	
estpost su $vars2, d
est  store indiv
esttab indiv using "$tables/descriptive_final.tex", append ///
				refcat(at_2019_th "\emph{Panel B: Past filing behavior}" presentó_djisr_2018 "\emph{Income Tax 2018}" presentó_djisr_2017 "\emph{Income Tax 2017}" , nolabel) ///
				cells("mean(fmt(%18.2fc)) sd p50 count(fmt(%18.0fc))") label booktabs nonum  collabels(none) f nogaps noobs		
estpost su $vars3
est store indiv
esttab indiv using "$tables/descriptive_final.tex", append ///
				refcat(ingresosdeterceros_2019 "\emph{Panel C: Third-party information}" hadeclaradoperdidasfiscales "\emph{Anomalies}" riesgo_1 "\emph{Risk assessment}", nolabel) ///
				cells("mean(fmt(%18.2fc)) sd p50 count(fmt(%18.0fc))") label booktabs nonum collabels(none) f nogaps noobs		

global vars_s "comerciante_individual profesional_ind_natural jur_comerc_ind "
global vars2_s "at_2019_th ingresos_isv_2019_th presentó_djisr_2018  ingresos_isr_informados_2018_th ingresos_isr_declarados_2018_th ing_isr_2018_declared tax_status_18_1 tax_status_18_2 tax_status_18_3 tax_base_2018_declared  impuesto_2018_declared effec_taxrate presentó_djisr_2017  ingresos_informados_2017_th ingresos_grav_declarados_2017_th ing_isr_2017_declared tax_base_2017_declared  impuesto_2017_declared"
global vars3_s "reported_OT reported_atc reported_siafi reported_export hadeclaradoperdidasfiscales movimientosfinancieros datosatipicos"



*****     TABLE 2: Balance Table - Baseline Characteristics
eststo drop *
eststo control: 	quietly estpost summarize $vars_s $vars2_s $vars3_s if treatment_status == 0
eststo treatment:   quietly estpost summarize $vars_s $vars2_s $vars3_s if inlist(treatment_status,1,2,3)
eststo threat:  	quietly estpost summarize $vars_s $vars2_s $vars3_s if treatment_status == 1
eststo pacta:   	quietly estpost summarize $vars_s $vars2_s $vars3_s if treatment_status == 2
eststo deber:   	quietly estpost summarize $vars_s $vars2_s $vars3_s if treatment_status == 3

eststo diff1: quietly estpost ttest $vars_s $vars2_s $vars3_s, by(treatment_v_control) unequal
eststo diff2: quietly estpost ttest $vars_s $vars2_s $vars3_s, by(threat_v_control) unequal
eststo diff3: quietly estpost ttest $vars_s $vars2_s $vars3_s, by(pacta_v_control) unequal
eststo diff4: quietly estpost ttest $vars_s $vars2_s $vars3_s, by(deber_v_control) unequal

esttab control treatment threat pacta deber diff1 diff2 diff3 diff4 using "$tables/table_balance.tex", ///
cells("mean(pattern(1 1 1 1 1 0 0 0 0) fmt(2)) b(star pattern(0 0 0 0 0 1 1 1 1) fmt(2) label(diff.) )" "sd(pattern(1 1 1 1 1 0 0 0 0) par ) ") ///
label replace f booktabs brackets mtitles("Control" "Treatment" "Sanctions" "Tax procedure" "Moral Duty"  ///
"\shortstack{Treatment v. \\ Control}" "\shortstack{Sanctions v. \\ Control}" "\shortstack{Procedures v. \\ Control}" "\shortstack{Moral duty v. \\ Control}") ///
starlevels(* 0.1 ** 0.05 *** 0.01) extracols(8) mgroups("Means by Group" "Difference in Means (t-test)", ///
span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 0 0 1 0 0))


esttab control control diff1 diff2 diff3 diff4 using "$tables/table_balance_short.tex", ///
cells("mean(pattern(1 0 0 0 0 0) fmt(2)) sd(pattern(0 1 0 0 0 0) par label(s.d.)) b(star pattern(0 0 1 1 1 1) fmt(2) label(diff.))") ///
label replace f booktabs brackets mtitles("Control" "Control" ///
"\shortstack{Treatment v. \\ Control}" "\shortstack{Sanctions v. \\ Control}" "\shortstack{Procedures v. \\ Control}" "\shortstack{Moral duty v. \\ Control}") ///
starlevels(* 0.1 ** 0.05 *** 0.01) extracols(7) mgroups("" "Difference in Means (t-test)", ///
span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 1 0 0 0))

