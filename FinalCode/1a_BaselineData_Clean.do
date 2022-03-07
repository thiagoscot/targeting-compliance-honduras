/*
Author: Thiago Scot
Date: August 29th 2019
Modified March 5th 2020
Name: Experimento2020_DoFile_v2.do
Description: Initial Analysis of massive experiment dataset shared by SAR on August 28th 2019.	
	Update: final randomization for massive experiment, using data from march 2020 visit to SAR.
*/

di in red "Cleaning baseline data"


import delimited "$input/Baseline_experiment.csv", clear

/*Dropping irrelevant and outdated variables*/
drop correodisponible estado_final_correo correo_duplicado treatment

****************************************************************************************************************
************************************ PREPARING DATABASE ********************************************************
****************************************************************************************************************

gen diff_isv_2018 = ingresos_isv_declarados_2018-ingresos_isv_informados_2018
gen diff_isr_2018 = ingresos_isr_declarados_2018-ingresos_isr_informados_2018

gen ht = ingresos_isr_informados_2018/ingresos_isr_declarados_2018
replace ht = . if ingresos_isr_declarados_2018 <= 1000

*Making numbers more readable
foreach var of varlist at_2019 ingresos_isv_2019 ingresosdeterceros_2019 ingresos_isr_informados_2018 ingresos_isr_declarados_2018 ingresos_isv_informados_2018 ingresos_isv_declarados_2018 ingresos_informados_2017 ingresos_grav_declarados_2017 impuesto_causado_l_2018_rn_rj impuesto_causado_l_2017_rn_rj deducciones_isr_2018 base_imponible_renta_2018  deducciones_isr_2017 base_imponible_renta_2017 base_imponible_isr_2018  {
	gen `var'_a = `var'
	replace `var'_a = 0 if `var' == .
	gen `var'_th = `var'_a/1000
	format `var' %18.2fc
	format `var'_th %18.2fc
	drop `var'_a
}

gen ing_isr_2018_declared =   ingresos_isr_declarados_2018_th  if presentó_djisr_2018 	 == 1
gen ing_isr_2017_declared =   ingresos_grav_declarados_2017_th if presentó_djisr_2017    == 1

replace presentó_djisr_2017 = 0 if presentó_djisr_2017 == .
replace presentó_djisr_2018 = 0 if presentó_djisr_2018 == .

*Recode firm size
encode tamaño_ot, gen(tamano)
recode tamano (1/2 = 0) (3 = 1), gen(small_firm)
recode tamano (1/3 = 0) (2 = 1), gen(medium_firm)

*Recode firm nature (corporation or not)
encode tipo_ot, gen(tipo)
recode tipo (2 = 0), gen(juridico_dummy)

*Defining independent worker
gen profesional_ind_natural = profesional_independiente_2018
replace profesional_ind_natural = 0 if (juridico_dummy == 1|comerciante_individual==1)

*Group: corporation or commerce or individual worker
gen jur_comerc_ind = (juridico_dummy == 1 | comerciante_individual == 1| profesional_ind_natural == 1)

encode grupo, gen(group)
recode group (2 = 0), gen(no_priority)

*Dummy for declaring positive revenue
gen ingreso_positivo_isr = ingresos_isr_declarados_2018 > 0
gen ingreso_positivo_isv = ingresos_isv_declarados_2018 > 0
gen ingreso_positivo_isr_17 = ingresos_grav_declarados_2017 > 0

*Creating taxable base (Non-incorporated entities have L40,000 automatic deduction)
gen double net_revenue_18 = ingresos_isr_declarados_2018 - deducciones_isr_2018
gen double base_18 = net_revenue_18 if tipo_ot == "JURÍDICO"
replace base_18 = net_revenue_18 - 40000	if tipo_ot == "NATURAL"
replace base_18 = 0 if base_18 < 0 
format base_18 %14.2fc

*Effective tax rate (taxes/taxable base)
gen effec_taxrate = impuesto_causado_l_2018_rn_rj/base_imponible_isr_2018

**Create taxable base and taxes due only for those who declared
gen impuesto_2018_declared = impuesto_causado_l_2018_rn_rj_th if presentó_djisr_2018 == 1 
gen impuesto_2017_declared= impuesto_causado_l_2017_rn_rj_th if presentó_djisr_2017 == 1

gen tax_base_2018_declared = base_imponible_renta_2018_th if presentó_djisr_2018 == 1 
gen tax_base_2017_declared = base_imponible_renta_2017_th if presentó_djisr_2017 == 1

gen tax_base_2018_nomis = tax_base_2018_declared
replace tax_base_2018_nomis = 0 if tax_base_2018_nomis == .

*Status in 2018: why was unit taxed
gen income_tax_status_18 = .
replace income_tax_status_18 = 1 if impuesto_causado_2018_rn_rj == "NINGUNO" & presentó_djisr_2018 == 1
replace income_tax_status_18 = 2 if impuesto_causado_2018_rn_rj == "RENTA" & presentó_djisr_2018 == 1
replace income_tax_status_18 = 3 if impuesto_causado_2018_rn_rj == "AN" & presentó_djisr_2018 == 1

tab income_tax_status_18, gen(tax_status_18_)

gen ihs_ingresos = log(1+ingresos_isr_declarados_2018)

*Classifying third-party info
gen reported_OT 	= (a1t_2019 > 0 | a2t_2019 > 0) if ingresosdeterceros_2019 == 1
gen reported_atc 	= (a3t_2019 > 0)				if ingresosdeterceros_2019 == 1
gen reported_siafi  = (a4t_2019 > 0)				if ingresosdeterceros_2019 == 1
gen reported_export = (a5t_2019 > 0)				if ingresosdeterceros_2019 == 1

*Regions
gen dom_nuevo = 1 if municipio == "DISTRITO CENTRAL"
replace dom_nuevo = 2 if municipio == "SAN PEDRO SULA"
replace dom_nuevo = 3 if municipio != "DISTRITO CENTRAL" & municipio != "SAN PEDRO SULA"

tab dom_nuevo, gen(region_)
gen distrito_central = (dom_nuevo == 1)
gen san_pedro 		 = (dom_nuevo == 2)

**Dropping all large firms (only 88 firms)
drop if tamano == 1

*Risk levels (if empty then no risk assessed, we bundle them with low risk)
replace calificacion_de_riesgo = "1:bajo" if calificacion_de_riesgo == ""
tab calificacion_de_riesgo, gen(riesgo_)

*Creating strata (3 regions * 2 terceros * 2 juridico * 5 calif riesgo = 60 strata)
egen strata = group(dom_nuevo ingresosdeterceros_2019 juridico_dummy calificacion_de_riesgo)

*Labeling variables
{
lab var juridico_dummy 					 "Corporations"
lab var comerciante_individual 			 "Individual Business"
lab var asalariado_2018 				 "Salaried Worker"
lab var profesional_ind_natural 		 "Self-employed service providers"
lab var jur_comerc_ind 					 "Corporations, IB or self-employed"
lab var ingresos_isr_informados_2018_th  "Reported revenue (Income) (2018) (L1,000s)"
lab var ingresos_isr_declarados_2018_th  "Declared revenue (Income) (2018) (L1,000s)"
lab var ingresos_isv_informados_2018_th  "Reported revenue (Sales) (2018) (L1,000s)"
lab var ingresos_isv_declarados_2018_th  "Declared revenue (Sales) (2018) (L1,000s)"
lab var ingresos_informados_2017_th		 "Reported revenue (Income) (2017) (L1,000s)"
lab var ingresos_grav_declarados_2017_th "Declared revenue (Income) (2017) (L1,000s)"
lab var presentó_djisr_2017	  			 "Declared income tax in 2017"
lab var ingreso_positivo_isr	  		 "Declared positive revenue (Income) (2018)"
lab var ingreso_positivo_isv	  		 "Declared positive revenue (Sales) (2018)"
lab var ingreso_positivo_isr_17			 "Declared positive revenue (Income) (2017)"
lab var trat_pr5_p6						 "Risk of underpaying Income Tax"
lab var trat_pr7_p9						 "Risk of underpaying Sales Tax"
lab var trat_co41_p19					 "Risk of not presenting Income Tax"
lab var trat_co41_p20					 "Risk of not presenting Sales Tax"
lab var muestra_declarado_similar_inform "No assessed risk, similar declared to reported"
lab var tax_base_2018_declared 			 "Taxable base 2018 | declaring (L1,000s)"
lab var tax_base_2017_declared 			 "Taxable base 2017 | declaring (L1,000s)"
lab var impuesto_2018_declared 			 "Tax liability 2018 | declaring (L1,000s)"
lab var impuesto_2017_declared 			 "Tax liability 2017  | declaring (L1,000s)"
lab var small_firm  					 "Small firm"
lab var medium_firm 					 "Medium firm"
lab var ht 					  			 "Ratio Income informed by third-party/declared (>L1,000)"
lab var ing_isr_2018_declared 			 "Declared revenue 2018 | declaring  (L1,000s)"
lab var ing_isr_2017_declared 			 "Declared revenue 2017 | declaring  (L1,000s)"
lab var presentó_djisr_2018 			 "Declared income tax in 2018"
lab var tax_status_18_1 				 "Not liable for taxes"
lab var tax_status_18_2 				 "Liable for income taxes"
lab var tax_status_18_3 				 "Liable for asset taxes"
lab var effec_taxrate 					 "Effective tax rate"
lab var base_imponible_renta_2017_th 	 "Taxable income 2017"
lab var riesgo_1 						 "Low risk"
lab var riesgo_2 						 "Medium-low risk"
lab var riesgo_3 						 "Medium risk"
lab var riesgo_4 						 "Medium-high risk"
lab var riesgo_5 						 "High risk"
lab var region_1 						 "Distrito Central"
lab var region_2 						 "San Pedro Sula"
lab var region_3 						 "Other regions"
lab var ingresosdeterceros_2019			 "Third-party information available (2019)"
lab var hadeclaradoperdidasfiscales		 "Declared losses for five years"
lab var movimientosfinancieros			 "Atypical financial transactions"
lab var datosatipicos					 "Atypical declared revenue"
lab var reported_OT						 "Revenue reported by other taxpayers"
lab var reported_atc					 "Revenue reported by POS operators"
lab var reported_siafi					 "Revenue reported by government"
lab var reported_export					 "Revenue reported by customs"
lab var at_2019_th						 "Reported revenue (Sales) (2019) (L1,000s)" 
lab var	ingresos_isv_2019_th 			 "Declared revenue (Sales) (2019) (L1,000s)"
}


save "$output/baseline_clean.dta", replace
