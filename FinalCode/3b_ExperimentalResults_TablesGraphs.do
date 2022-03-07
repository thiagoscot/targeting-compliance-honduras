
******************************************************************************************************
********************************** 3. ESTIMATING RESULTS *********************************************
******************************************************************************************************

di in red "Creating IE tables and graphs"


***** Table 3: Primary Outcomes - Estimating Program Effects

global controls "presentó_djisr_2018 ingresos_isr_informados_2018_th ingresos_isr_declarados_2018_th ingresos_isv_2019_th i.strata "

eststo drop *
foreach var of varlist filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th {
	eststo:  qui reg `var' treatment_pooled $controls  , robust
		qui summ `var' if e(sample) == 1 & treatment_pooled == 0
	estadd scalar mean =  r(mean)
	estimates store t_`var'

} 

esttab using "$tables/experiment_ols_final.tex", replace f  keep(treatment_pooled) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 mean , ///
	 fmt(%18.0fc 3 %18.2fc) labels(Observations R-Squared "Control mean")) refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 mtitles("Filed declaration" "Gross Revenue" "Deductions" "Taxable Income") r2 ///
	 coeflabel(treatment_pooled "Treatment") star(* 0.10 ** 0.05 *** 0.01)

eststo drop *
foreach var of varlist filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {
	eststo:  qui ivregress 2sls 	`var'  $controls (opened = treatment_pooled) , robust
}

esttab using "$tables/experiment_ols_final.tex", append f keep(opened) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared )) refcat(opened "\emph{LATE estimates}", nolabel) ///
	 nomtitles nonumbers  r2  coeflabel(opened "Opened email") ///
	 star(* 0.10 ** 0.05 *** 0.01)


***** Table 4: Primary Outcomes - Different Treatment Arms
eststo drop *

foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {
eststo:  qui reg `var' 			 		i.treatment_status $controls  , robust
	qui test 1.treatment_status == 2.treatment_status
	estadd  scalar test1 = r(p) 
	qui test 1.treatment_status == 3.treatment_status
	estadd scalar test2 = r(p) 
	qui test 2.treatment_status == 3.treatment_status
	estadd scalar test3 = r(p) 
	qui summ `var' if e(sample) == 1 & treatment_pooled == 0
	estadd scalar mean =  r(mean)
}
esttab using "$tables/experiment_multiple_prelim.tex", replace f label keep(1.treatment_status 2.treatment_status 3.treatment_status) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 mean test1 test2 test3, ///
	 fmt(%18.0fc 3 %18.2fc 3 3 3) labels(Observations R-Squared "Control mean" "$\beta1 = \beta2$" "$\beta1 = \beta3$" "$\beta2 = \beta3$" )) refcat(1.treatment_status "\textbf{ITT estimates}", nolabel) ///
	 mtitles("Filed declaration" "Gross Revenue" "Deductions" "Taxable Income")  r2 ///
	 star(* 0.10 ** 0.05 *** 0.01)

eststo drop *
foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {
	eststo:  qui ivregress 2sls `var' $controls (opened_1 opened_2 opened_3 = i.treatment_status) , robust
}	

esttab using "$tables/experiment_multiple_prelim.tex", append f  keep(opened*) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared )) refcat(opened_1 "\textbf{LATE estimates}", nolabel) ///
	 nomtitles nonumbers r2 coeflabel(opened_1 "Opened (Sanctions)" opened_2 "Opened (Procedures)" opened_3 "Opened (Tax morale)") ///
	 star(* 0.10 ** 0.05 *** 0.01)
	
***** Table 5: SECONDARY Outcomes - Estimating Program Effects

global controls "presentó_djisr_2018 ingresos_isr_informados_2018_th ingresos_isr_declarados_2018_th ingresos_isv_2019_th i.strata "

eststo drop *
foreach var of varlist first_deadline second_deadline impuesto_liquid_isr_2019 total_ISV revise_any  {
	eststo:  qui reg `var' treatment_pooled $controls  , robust
	
	qui summ `var' if e(sample) == 1 & treatment_pooled == 0
	estadd scalar mean =  r(mean)
} 

esttab using "$tables/experiment_ols_secondary.tex", replace f  keep(treatment_pooled) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 mean , ///
	 fmt(%18.0fc 3 %18.2fc) labels(Observations R-Squared "Control mean")) refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 mtitles("Filed 1st deadline" "Filed 2nd deadline" "Total taxes paid" "Total sales taxes" "Revised previous filing") r2 ///
	 coeflabel(treatment_pooled "Treatment") star(* 0.10 ** 0.05 *** 0.01)
	

eststo drop *
foreach var of varlist first_deadline second_deadline impuesto_liquid_isr_2019 total_ISV revise_any  {
	eststo:  qui ivregress 2sls 	`var'  $controls (opened = treatment_pooled) , robust
}

esttab using "$tables/experiment_ols_secondary.tex", append f keep(opened) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared )) refcat(opened "\emph{LATE estimates}", nolabel) ///
	 nomtitles nonumbers  r2  coeflabel(opened "Opened email") ///
	 star(* 0.10 ** 0.05 *** 0.01)
	 
***** Table 6: Heterogeneity Analysis

eststo drop *
foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {
eststo:  qui reg `var' 	i.treatment_pooled i.ingresosdeterceros_2019  i.treatment_pooled#i.ingresosdeterceros_2019 $controls  , robust
	qui test 1.treatment_pooled + 1.treatment_pooled#1.ingresosdeterceros_2019 = 0
	estadd scalar pvalue =  r(p)
}

esttab using "$tables/experiment_het_prelim.tex", replace f label  keep(1.ingresosdeterceros_2019 1.treatment_pooled 1.treatment_pooled#1.ingresosdeterceros_2019) ///
	 order(1.treatment_pooled 1.treatment_pooled#1.ingresosdeterceros_2019  1.ingresosdeterceros_2019) ///
	 coeflabel(1.treatment_pooled#1.ingresosdeterceros_2019 "Treatment * Third party info available" ///
		1.ingresosdeterceros_2019 "Third party info available" 1.treatment_pooled "Treatment") ///
	 booktabs b(3) se(3) eqlabels(none) alignment(S) stats(N r2 pvalue, ///
	 fmt(%18.0fc 3) labels(Observations R-Squared "Third-party effect (p-value)")) refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 mtitles("Filed declaration" "Gross Revenue" "Deductions" "Taxable Income")  r2 ///
	 star(* 0.10 ** 0.05 *** 0.01)  

eststo drop *
foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {

	eststo:  qui reg `var' i.risk_level i.treatment_pooled i.treatment_pooled#i.risk_level $controls  , robust
	
	forv i = 2/5 {
	qui test 1.treatment_pooled + 1.treatment_pooled#`i'.risk_level = 0
	estadd scalar pvalue_`i' =  r(p)
	}
}

esttab using "$tables/experiment_het_prelim.tex", append f label keep(1.treatment_pooled 1.treatment_pooled#2.risk_level  1.treatment_pooled#3.risk_level ///
	 1.treatment_pooled#4.risk_level  1.treatment_pooled#5.risk_level ) ///
	 order(  1.treatment_pooled 1.treatment_pooled#2.risk_level  1.treatment_pooled#3.risk_level ///
	 1.treatment_pooled#4.risk_level  1.treatment_pooled#5.risk_level ) ///
	 coeflabel(1.treatment_pooled "Treatment" 1.treatment_pooled#2.risk_level "Treatment * Medium-low risk" ///
	 1.treatment_pooled#3.risk_level "Treatment * Medium risk" 1.treatment_pooled#4.risk_level "Treatment * Medium-high risk" ///
	 1.treatment_pooled#5.risk_level "Treatment * High risk") ///
	 booktabs b(3) se(3) eqlabels(none) alignment(S) stats(N r2 pvalue_2 pvalue_3 pvalue_4 pvalue_5 , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared "Medium-low risk effect (p-value)" "Medium risk effect (p-value)" ///
	 "Medium-high risk effect (p-value)" "High risk effect (p-value)")) ///
	 refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 nomtitles nonumbers  r2 ///
	 star(* 0.10 ** 0.05 *** 0.01)
	 
	 
eststo drop *
foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {

eststo:  qui reg `var' i.juridico_dummy i.treatment_pooled i.treatment_pooled#i.juridico_dummy $controls  , robust
	qui test 1.treatment_pooled + 1.treatment_pooled#1.juridico_dummy = 0
	estadd scalar pvalue =  r(p)
}
	 
esttab using "$tables/experiment_het_prelim.tex", append f  keep(1.juridico_dummy 1.treatment_pooled 1.treatment_pooled#1.juridico_dummy)  ///
	 order(1.treatment_pooled  1.treatment_pooled#1.juridico_dummy 1.juridico_dummy  ) ///
	 coeflabel(1.treatment_pooled#1.juridico_dummy "Treatment * Corporation" 1.treatment_pooled "Treatment" ///
			   1.juridico_dummy "Corporation" ) ///
	 booktabs b(3) se(3) eqlabels(none) alignment(S) stats(N r2 pvalue, ///
	 fmt(%18.0fc 3) labels(Observations R-Squared "Corporation effect (p-value)" )) refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 nomtitles nonumbers r2 ///
	 star(* 0.10 ** 0.05 *** 0.01)
	 
eststo drop *
foreach var of varlist  filed_declaration ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th  {
	eststo:  qui reg `var'  ib3.dom_nuevo i.treatment_pooled i.treatment_pooled#i.dom_nuevo $controls  , robust
	forv i = 1/2 {
	qui test 1.treatment_pooled + 1.treatment_pooled#`i'.dom_nuevo = 0
	estadd scalar pvalue_`i' =  r(p)
	}
}

esttab using "$tables/experiment_het_prelim.tex", append f keep(1.dom_nuevo 2.dom_nuevo 1.treatment_pooled 1.treatment_pooled#1.dom_nuevo 1.treatment_pooled#2.dom_nuevo) ///
	 coeflabel(1.treatment_pooled#1.dom_nuevo "Treatment * Distrito Central" 1.treatment_pooled#2.dom_nuevo "Treatment * San Pedro Sula" ///
	 1.treatment_pooled "Treatment" 1.dom_nuevo "Distrito Central" 2.dom_nuevo "San Pedro Sula") ///
	 order(1.treatment_pooled 1.treatment_pooled#1.dom_nuevo 1.treatment_pooled#2.dom_nuevo  1.dom_nuevo 2.dom_nuevo) ///
	 booktabs b(3) se(3) eqlabels(none) alignment(S) stats(N r2 pvalue_1 pvalue_2 , ///
	 fmt(%18.0fc 3) labels(Observations R-Squared "Distrito Central effect (p-value)" "San Pedro Sula effect (p-value)" )) ///
	 refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 nomtitles nonumbers r2 ///
	 star(* 0.10 ** 0.05 *** 0.01)
	 

*** Table A1: Primary outcomes trimmed at 99th percentile (non pre-specified)
eststo drop *
foreach var of varlist ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th {
	qui summ `var', d
	loc p99 = r(p99)
	
	eststo: qui reg `var' treatment_pooled $controls if `var' < `p99' , robust
		qui summ `var' if e(sample) == 1 & treatment_pooled == 0
	estadd scalar mean =  r(mean)
	estimates store t_`var'

} 

esttab using "$tables/experiment_ols_prelim_trim.tex", replace f  keep(treatment_pooled) ///
	 booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 mean , ///
	 fmt(%18.0fc 3 %18.2fc) labels(Observations R-Squared "Control mean")) refcat(treatment_pooled "\emph{ITT estimates}", nolabel) ///
	 mtitles("Gross Revenue" "Deductions" "Taxable Income") r2 ///
	 coeflabel(treatment_pooled "Treatment") star(* 0.10 ** 0.05 *** 0.01)

eststo drop * 
foreach var of varlist ingresos_isr_2019_th deducciones_isr_2019_th base_imponible_2019_th {
	qui summ `var', d
	loc p99 = r(p99)
	eststo:  qui reg `var' i.treatment_status $controls if `var' < `p99'  , robust
	
	qui summ `var' if e(sample) == 1 & treatment_pooled == 0
	estadd scalar mean =  r(mean)
} 

esttab using "$tables/experiment_ols_prelim_trim.tex", append f  keep(1.treatment_status 2.treatment_status 3.treatment_status) ///
	 label booktabs b(3) ci(3) eqlabels(none) alignment(S) stats(N r2 , ///
	 fmt(%18.0fc 3 %18.2fc) labels(Observations R-Squared ))  r2 nomtitles nonumbers ///
	 refcat(1.treatment_status "\emph{ITT estimates}", nolabel) ///
	 coeflabel(treatment_pooled "Treatment") star(* 0.10 ** 0.05 *** 0.01)
	 
	 
***************************************************************************************************************
***************************************  FIGURES **************************************************************
***************************************************************************************************************

*****    FIGURE 2: Cumulative distribution function of declared gross revenue - Treatment vs. control groups
cdfplot log_revenue if ingresos_isr_2019 > 10, by(treatment_pooled) graphregion(color(white)) ///
		opt1(lw(medthick medthick) lc(gs8 dknavy ) lp(dash solid))  ///
		xtitle("Log Declared Gross Revenue 2019") ytitle("") subtitle("Cumulative share", pos(11) span size(medsmall)) ylab(, nogrid) ///
		legend(lab(1 "Control") lab(2 "Treatment") region(lcolor(gs16)))
	graph export "$figures/cdf_pooled.pdf", replace
	
***** FIGURE 3a: Cumulative share of taxpayers filinf per week (a. Pooled treatment arms)
preserve
	count if treatment_pooled == 0
	loc n_control = r(N)
	count if treatment_pooled == 1
	loc n_treat = r(N)
	di `n_control'
	
	*Colapsando base para preparar graficas de resultados en el tiempo
	collapse (count) id (sum) impuesto_causado_l_2019_rn_rj, by(treatment_pooled week_relative)
	drop if week_relative == .
	
	bys treatment_pooled: gen cumul = sum(id)
	gen share = cumul/`n_control' if  treatment_pooled  == 0
	replace share = cumul/`n_treat' if  treatment_pooled  == 1
	by treatment_pooled: gen cumul_imp = sum(impuesto_causado_l_2019_rn_rj)

	twoway scatter share week_relative if treatment_pooled == 0, ///
		lcolor(gs8) lw(medthick) msymbol(d) msize(small) mcolor(gs8) connect(l) || ///
		scatter share week_relative if treatment_pooled == 1, ///
		lcolor(dknavy) lw(medthick) msymbol(o) msize(small) mcolor(dknavy) connect(l)  || , ///
		ylabel(0(.2).7,nogrid angle(horizontal)) graphregion(fcolor(white) lcolor(gs16)) xtitle("") ///
		xline(7 15 24, lp(dot) lw(thin) lc(red)) xtitle("Weeks since treatment") xlab(-6 0(10)30) /// 
		ytitle("") subtitle("% filed declaration", pos(11) span size(medsmall)) xscale(titlegap(*5))	///
			legend(lab(1 "Control") lab(2 "Treatment") ///
			region(lcolor(gs16))) ///
		text(0.65 7  "Original deadline", size(vsmall) color(gs8) placement(nw)) ///
		text(0.65 15 "First postponement", size(vsmall) color(gs8) placement(nw) ) ///
		text(0.65 24.5 "Final deadline", size(vsmall) color(gs8) placement(ne))
	graph export "$figures/cumulative_filing_week.pdf", replace
restore



***** FIGURE 3b: Cumulative share of taxpayers filinf per week (b. Separate treatment arms)
preserve
	count if treatment_status == 0
	loc n_control = r(N)
	count if treatment_status == 1 
	loc n_treat_san = r(N)
	count if treatment_status == 2 
	loc n_treat_doc = r(N)
	count if treatment_status == 3 
	loc n_treat_duty = r(N)
	
	*Colapsando base para preparar graficas de resultados en el tiempo
	collapse (count) id (sum) impuesto_causado_l_2019_rn_rj, by(treatment_status week_relative)
	drop if week_relative == .
	
	by treatment_status: gen cumul = sum(id)
	gen share = cumul/`n_control' if  treatment_status  == 0 
	replace share = cumul/`n_treat_san' if  treatment_status  == 1 
	replace share = cumul/`n_treat_doc' if  treatment_status  == 2
	replace share = cumul/`n_treat_duty' if  treatment_status  == 3
	by treatment_status: gen cumul_imp = sum(impuesto_causado_l_2019_rn_rj)

	twoway scatter share week_relative if treatment_status == 0, ///
		lcolor(gs8) lw(medthick) msymbol(d) msize(small) mcolor(gs8) connect(l) || ///
		scatter share week_relative if treatment_status == 1 , ///
		lcolor(dkgreen) lw(medthick) msymbol(o) msize(small) mcolor(dkgreen) connect(l)  || ///
		scatter share week_relative if treatment_status == 2, ///
		lcolor(dknavy) lw(medthick) msymbol(o) msize(small) mcolor(dknavy) connect(l)  ||  ///
		scatter share week_relative if treatment_status == 3, ///
		lcolor(dkorange) lw(medthick) msymbol(o) msize(small) mcolor(dkorange) connect(l)  || , ///
		ylabel(0(.2).7,nogrid angle(horizontal)) graphregion(fcolor(white) lcolor(gs16)) xtitle("") ///
		xline(7 15 24, lp(dot) lw(thin) lc(red)) xtitle("Weeks since treatment") xlab(-6 0(10)30) /// 
		ytitle("") subtitle("% filed declaration", pos(11) span size(medsmall)) xscale(titlegap(*5))	///
			legend(lab(1 "Control") lab(2 "Sanctions") lab(3 "Procedures") lab(4 "Moral Duty")  ///
			region(lcolor(gs16))) ///
		text(0.7 7  "Original deadline", size(vsmall) color(gs8) placement(nw)) ///
		text(0.7 15 "First postponement", size(vsmall) color(gs8) placement(nw) ) ///
		text(0.7 24.5 "Final deadline", size(vsmall) color(gs8) placement(ne))
	graph export "$figures/cumulative_filing_week_arms.pdf", replace
restore
	 
	 
