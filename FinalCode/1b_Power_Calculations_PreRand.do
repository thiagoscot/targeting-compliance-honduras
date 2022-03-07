
****************************************************************************************************************
*************************** POWER CALCS & DROPPING OBSERVATIONS ************************************************
****************************************************************************************************************
di in red "Power calculations on baseline"

use "$output/baseline_clean.dta", clear

/*STEP 1: Exclude observations with no valid email*/
keep if correo_limpio == 1									//

/*STEP 2: Exclude and set to separate database observations with duplicate emails*/
bys group_email: gen number = _N
gen duplicado = number > 1

preserve
	keep if duplicado == 1
	save "$output/Muestra_experimento_04_03_2020_final_duplicados.dta", replace
restore

drop if duplicado == 1
drop if id == 68692											//Drop 1 observation with outlier deduction; remaining outliers below



/*This section performs Power calculations for several trimmed samples, 
in order to decide where to exclude outliers*/

cap mat drop power
qui summ ingresos_isr_declarados_2018_th ,d
loc total = `r(sum)'

loc compliance = 0.6			//local defining compliance, defined as opening email. Using 60% of treatment group.

eststo drop *
foreach pc of numlist 90(1)99 99.5 99.9 100{
	
	if `pc' != 100 {
		_pctile ingresos_isr_declarados_2018_th, p(`pc')
		loc threshold = `r(r1)'
	}
	
	else {
		qui summ ingresos_isr_declarados_2018_th
		loc threshold = `r(max)'
	}
	
	*Regression 2018 revenue
	eststo: qui reg ingresos_isr_declarados_2018_th base_imponible_renta_2017_th ///
		ingresos_informados_2017_th ingresos_grav_declarados_2017_th ///
		presentó_djisr_2017 ingresos_isv_informados_2018_th i.strata  ///
		if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold' 
	qui predict res, res
	qui summ res if ingresos_isr_declarados_2018_th < `threshold'  & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd_res = `r(sd)'

	
	*Power for revenue
	qui summ ingresos_isr_declarados_2018_th if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd = `r(sd)'
	loc mean = `r(mean)'
	loc p50 = `r(p50)'
	loc N = `r(N)'
	loc share = `r(sum)'/`total'
	loc share_total = `r(sum)'/1210253099
	loc effect = 1.10*`mean'
	
	qui power twomeans `mean', n(`N') sd(`sd_res') power(0.8) a(0.05)
	loc perc_effect = (`r(diff)'/`compliance')/`mean'
	
	*Power for taxable income
	qui reg base_imponible_renta_2018_th base_imponible_renta_2017_th ///
		ingresos_informados_2017_th ingresos_grav_declarados_2017_th ///
		presentó_djisr_2017 ingresos_isv_informados_2018_th i.strata ///
		if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold'
	qui predict res_util, res
	qui summ res_util if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd_res_util = `r(sd)'
	
	qui summ base_imponible_renta_2018_th if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd_util = `r(sd)'
	loc mean_util = `r(mean)'
	loc p50_util = `r(p50)'
	loc N_util = `r(N)'
	
	qui power twomeans `mean_util', n(`N_util') sd(`sd_res_util') power(0.8) a(0.05)
	loc util_effect = (`r(diff)'/`compliance')/`mean_util'
	
	*Power in proportion of positive income
	qui summ presentó_djisr_2018 if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc positivo = `r(mean)'
	
	qui power twoproportions `positivo', n(`N') power(0.8) a(0.05)
	loc efect_pos = (`r(diff)'/`compliance')
	
	*Power for deductions
	qui reg deducciones_isr_2018_th base_imponible_renta_2017_th ///
		ingresos_informados_2017_th ingresos_grav_declarados_2017_th ///
		presentó_djisr_2017 ingresos_isv_informados_2018_th i.strata ///
		if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold'
	qui predict res_deduc, res
	qui summ res_deduc if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd_res_deduc = `r(sd)'
	
	qui summ deducciones_isr_2018_th if ingresos_isr_declarados_2018_th < `threshold' & ingresos_grav_declarados_2017_th < `threshold',d
	loc sd_deduc = `r(sd)'
	loc mean_deduc = `r(mean)'
	loc p50_deduc = `r(p50)'
	loc N_deduc = `r(N)'
	
	qui power twomeans `mean_deduc', n(`N_deduc') sd(`sd_res_deduc') power(0.8) a(0.05)
	loc deduc_effect = (`r(diff)'/`compliance')/`mean_deduc'
	
	mat power = nullmat(power) \ (`pc',`threshold', `share', `share_total', `sd_res', `mean', `perc_effect',`util_effect', `efect_pos', `deduc_effect', `N')
	
	drop res res_util res_deduc
}

mat colnames power= Pct Umbral Sh_Ing Sh_Tot Res-SD Media MDE_ing MDE_uti MDE_prob MDE_deduc N


*****    FIGURE A5: Minimum Detectable Effect - Final Sample
preserve
 clear
 svmat power
 rename power1 percentile
 rename power7 mde_ing
 rename power8 mde_base
 rename power9 mde_pago
 rename power10 mde_deduc
 twoway (scatter mde_ing percentile, connect(l) lw(thick) lc(dknavy) mc(dknavy)) || ///
  (scatter mde_base percentile, connect(l) lw(thin) lc(gs10) mc(gs10) lp(dash)) ///
 (scatter mde_pago percentile, connect(l) lc(dkorange) mc(dkorange) lp(longdash))  ///
 (scatter mde_deduc percentile, connect(l) lc(dkgreen) mc(dkgreen) lp(longdash)) , ///
 graphregion(color(white)) xtitle("Percentile trimmed") ytitle("") ///
 ylabel(, nogrid format(%18.2fc) labsize(small) angle(horizontal)) xline(97, lw(vthin) lp(dash)) ///
 subtitle("Minimum Detectable Effect", pos(11) span size(medsmall)) ///
 xlabel(90(1)95 96 97 98 99 99.5 99.9 , labsize(small) angl (90)) ///
 legend(lab (1 "Gross Income (%)") lab (2 "Taxable Income (%)") lab (3 "Filing probability (p.p.)") ///
 lab(4 "Deductions (%)") region(lcolor(gs16))) 
 
 graph export "$figures/mde_graph_experiment.pdf", replace
restore

	
pctile pct =  ingresos_isr_declarados_2018_th, n(100)

/* STEP 3 - OUTLIER EXCLUSION: exclude OTs with revenue above 97th percentile in 2018 (use same threshold for 2017) */
drop if (ingresos_isr_declarados_2018_th > 19433 | ingresos_grav_declarados_2017_th > 19433)


					
