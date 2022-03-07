/*
Author: Thiago Scot
Date: March 17th 2020
Modified:
Name: Analysis_RCT_HND.do
Description: Uses randomized database to poduce descriptive tables for pre-analysis plan.
*/

di in red "Cleaning endline data"


******************************************************************************************************
***************************** 1. LOAD DATA AND SET-UP ************************************************
******************************************************************************************************

use "$output/randomized_base_experiment.dta", clear

encode calificacion_de_riesgo, gen(risk_level)

*Results from 2019 income tax declaration ("Endline" data, post intervention)
preserve

	import delimited "$input/Endline_experiment.csv", clear
	drop if duplicado == 1													//Dropping duplicate sample, not in experiment
	duplicates drop															//One duplicate in new database
	drop if id == 39022 & imp_s_tarifa_an_2019 == .							//Check why duplicated
	
	keep id fecha_presentacion_2019 ingresos_isr_2019 deducciones_isr_2019 resultado_del_ejercicio_2019 ///
		base_impon_rta_neta_grav_2019 base_impon_activo_neto_2019 base_impon_aport_solidaria_2019 ///
		presentó_djisr_2019 imp_s_tarifa_rnta_2019 imp_s_tarifa_an_2019 imp_s_tarifa_aport_solid_2019 ///
		impuesto_causado_2019_rn_rj impuesto_causado_l_2019_rn_rj impuesto_liquid_isr_2019 abrió_correo ///
		ingresos_isr_declarados_2018 treatment_status
		
	rename treatment_status treatment_status_check								//Checking merging is correct
	rename ingresos_isr_declarados_2018 ingresos_isr_declarados_2018_c
	
	tempfile data
	save "`data'"

restore

merge 1:1 id using "`data'"
assert _merge == 3
drop _merge

*Aditional data: ISV, previous filing,...
preserve

	import delimited "$input/AdditionalInfo_endline.csv", clear
	drop if duplicado == 1													//Dropping duplicate sample, not in experiment
	duplicates drop															//One duplicate in new database
	
	keep id treatment_status _impuesto_causado_isv _impuesto_liquido_isv v106 v107 v108 v109 v110 v111 v112 v113 ///
	v114 v115 _no_declaracion_corrige _impto_a_pagar_liq _fecha_presentacion v119 v120 v121 v122 v123 v124 ///
	v125 v126 v127 v128 v129 v130 mediodecomunicaciónutilizadapore razónporlaqueelobligadotributari ///
	alverificarenlabasededatosinstit usoelmaterialdeapoyoqueproporcio estematerialfuedeutilidad
		
	rename treatment_status treatment_status_check_2								//Checking merging is correct
	
	tempfile data
	save "`data'"

restore

merge 1:1 id using "`data'"
assert _merge == 3
drop _merge

assert ingresos_isr_declarados_2018 == ingresos_isr_declarados_2018_c			//Checking obs are the same
drop ingresos_isr_declarados_2018_c

tab treatment_status treatment_status_check										//Checking treat status is the same

drop treatment_status_check treatment_status_check_2


******************************************************************************************************
********************************** 2. CLEANING DATA **************************************************
******************************************************************************************************

*Date of filing in 2019
gen date_aux = substr(fecha_presentacion_2019,1,4) + "/" + substr(fecha_presentacion_2019,6,2) + "/" + ///
				substr(fecha_presentacion_2019,9,2)
gen date = date(date_aux, "YMD")
format date %td

*Using dates of previous filings to check whether treated units are more likely to correct past tax filings
foreach var of varlist _fecha_presentacion v121 v124 v127 v130 {
	gen aux_`var' = substr(`var',1,4) + "/" + substr(`var',6,2) + "/" + ///
				substr(`var',9,2)
	gen pre_`var' = date(aux_`var', "YMD")
	format pre_`var' %td
	drop aux_`var'
}

gen revise_18 = pre_v130 > td(01mar2020) & pre_v130 != .
gen revise_17 = pre_v127 > td(01mar2020) & pre_v127 != .
gen revise_16 = pre_v124 > td(01mar2020) & pre_v124 != .
gen revise_15 = pre_v121 > td(01mar2020) & pre_v121 != .
gen revise_14 = pre__fecha_presentacion > td(01mar2020)  & pre__fecha_presentacion != . 
egen revise_any_aux = rowtotal(revise_*)
gen revise_any = revise_any_aux != 0 

gen week = week(date)
gen week_relative = week - 11 			/// weeks since emails were sent

*Since filing deadlines were postponed, create indicators for filing before each deadline
gen first_deadline = date < d(30apr2020)
gen second_deadline = date < d(30jun2020)

rename abrió_correo opened
rename (_impuesto_causado_isv v106 v108 v110 v112 v114) ///
	   (ISV_03 ISV_04 ISV_05 ISV_06 ISV_07 ISV_08)
	   
egen total_ISV = rowtotal(ISV_03 ISV_04 ISV_05 ISV_06 ISV_07 ISV_08)

*We observe whether taxpayer clicked/opened the treatment email, so code that
replace opened = 0 if treatment_status== 0						//Set open to zero if control
gen opened_1 = (opened == 1 & treatment_status == 1)			//Create open status for each treat arm
gen opened_2 = (opened == 1 & treatment_status == 2)
gen opened_3 = (opened == 1 & treatment_status == 3)

replace presentó_djisr_2019 = 0 if presentó_djisr_2019 == .				//Creating dummy of presentation
rename presentó_djisr_2019 filed_declaration
 
rename base_impon_rta_neta_grav_2019 base_imponible_2019

foreach var of varlist ingresos_isr_2019 deducciones_isr_2019 base_imponible_2019 impuesto_liquid_isr_2019 {
	replace `var' = 0 if `var' == .
	gen `var'_ihs = asinh(`var')
}

gen ingresos_isr_2019_th = ingresos_isr_2019/1000
gen deducciones_isr_2019_th = deducciones_isr_2019/1000
gen base_imponible_2019_th = base_imponible_2019/1000

gen treatment_pooled = inlist(treatment_status,1,2,3)

gen log_revenue = ln(ingresos_isr_2019)

gen log_revenue_18 = ln(ingresos_isr_declarados_2018)

*Export data to csv to use in Random Forest estimates (in R)
export delimited using "$output/data_GRF.csv", replace
