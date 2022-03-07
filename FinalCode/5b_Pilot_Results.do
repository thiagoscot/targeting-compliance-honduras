
di in red "Creating pilot experiment results"

use "$output/pilot_dataset_clean.dta", clear

****** Table A2: Pilot Results
cap eststo drop *
qui summ presented if treatment ==0
loc mean_present: di%4.3f `r(mean)'
qui summ impuesto_causado if treatment ==0
loc mean_imp: di%3.2f `r(mean)'
qui summ ihs_impuesto if treatment ==0
loc mean_ihs: di%3.2f `r(mean)'


*Regresiones principal: efecto de asignacion a tratamiento sobre resultados de interes
global control "presento_2017 juridico_dummy ing_isr_2017_declared"

eststo: reg presented treatment  , vce(robust)
	estadd local control "No"
	estadd local mean `mean_present'
eststo: reg presented treatment $control, vce(robust)
	estadd local control "Yes"
	estadd local mean `mean_present'
eststo: reg impuesto_causado treatment, vce(robust)
	estadd local control "No"
	estadd local mean `mean_imp'
eststo: reg impuesto_causado treatment $control, vce(robust)
	estadd local control "Yes"
	estadd local mean `mean_imp'

	
esttab using "$tables/regs_piloto_english.tex", booktabs compress nogaps f keep(_cons treatment) replace ///
coeflabels(treatment "Treatment" _cons "Constant") refcat(treatment "\emph{ITT estimates}", nolabel) ///
se(2) stats(N r2  control mean,labels(Observations R-Squared "Controls?" "Control average")) star(* 0.10 ** 0.05 *** 0.01)  ///
nomtitles mgroups("Presented declaration" "Tax liability (L)", span prefix(\multicolumn{@span}{c}{) suffix(}) pattern(1 0 1 0))

*Regresiones adicionales: se consider que el "tratamiento" es hacer click o abrir correo, y se utiliza 
*asignacion a tratamiento como instrumento.
cap eststo drop *
eststo: ivregress 2sls presented (received = treatment), vce(robust)
	estadd local control "No"
	estadd local mean `mean_present'
eststo: ivregress 2sls presented  $control (received = treatment), vce(robust)
	estadd local control "Yes"
	estadd local mean `mean_present'
eststo: ivregress 2sls impuesto_causado (received = treatment), vce(robust)
	estadd local control "No"
	estadd local mean `mean_imp'
eststo: ivregress 2sls impuesto_causado $control (received = treatment), vce(robust)
	estadd local control "Yes"
	estadd local mean `mean_imp'
	
esttab using "$tables/regs_piloto_english.tex", booktabs compress f keep(_cons received) append ///
coeflabels(received "Clicked on email" _cons "Constant") refcat(received "\emph{LATE estimates}", nolabel) ///
se(2) stats(N r2  control mean,labels(Observations R-Squared "Controls?" "Control average")) star(* 0.10 ** 0.05 *** 0.01)  ///
nomtitles nonumbers 


egen group = group(treatment received)

preserve
	*Preparing database to generate graphs
	collapse (count) ID (sum) impuesto_causado, by(treatment fecha_td)
	drop if fecha_td == .

	by treatment: gen cumul = sum(ID)
	gen share = cumul/1562 if treatment == 0
	replace share = cumul/ 982 if treatment == 1
	by treatment: gen cumul_imp = sum(impuesto_causado)



	 ****** Figure A2: Probability of filing income taxes by treatment status
	twoway scatter share fecha_td if treatment == 0, ///
			lcolor(gs8) lw(medthick) msymbol(d) msize(small) mcolor(gs8) connect(l) || ///
			scatter share fecha_td if treatment == 1, ///
			lcolor(dknavy) lw(medthick) msymbol(o) msize(small) mcolor(dknavy) connect(l)  ||, ///
			ylabel(,nogrid angle(horizontal)) graphregion(fcolor(white) lcolor(gs16)) xtitle("") ///
			ytitle("") subtitle("% presented declaration", pos(11) span size(medsmall)) xscale(titlegap(*5))	///
				legend(lab(2 "Treatment") lab(1 "Control")  region(lcolor(gs16))) 
	 graph export "$figures/acumulado_trat_english.pdf", replace

	 
	 
	 ****** Figure A3: Declared tax liability by treatment status
	 twoway scatter cumul_imp fecha_td if treatment == 0, ///
			lcolor(gs8) lw(medthick) msymbol(d) msize(small) mcolor(gs8) connect(l) || ///
			scatter cumul_imp fecha_td if treatment == 1, ///
			lcolor(dknavy) lw(medthick) msymbol(o) msize(small) mcolor(dknavy) connect(l)  ||, ///
			ylabel(,nogrid angle(horizontal)) graphregion(fcolor(white) lcolor(gs16)) xtitle("") ///
			ytitle("") subtitle("Tax liability (L)", pos(11) span size(medsmall)) xscale(titlegap(*5))	///
				legend(lab(2 "Treatment") lab(1 "Control")  region(lcolor(gs16))) 
	 graph export "$figures/acumulado_impuesto_english.pdf", replace
restore
 
  ****** Figure A4: Probability of filing income taxes by email status
preserve
	*Colapsando base para preparar graficas de resultados en el tiempo
	collapse (count) ID (sum) impuesto_causado, by(group fecha_td)
	drop if fecha_td == .

	by group: gen cumul = sum(ID)
	gen share = cumul/1562 if group == 1
	replace share = cumul/661 if group == 2
	replace share = cumul/321 if group == 3
	by group: gen cumul_imp = sum(impuesto_causado)

	twoway scatter share fecha_td if group == 1, ///
		lcolor(gs8) lw(medthick) msymbol(d) msize(small) mcolor(gs8) connect(l) || ///
		scatter share fecha_td if group == 2, ///
		lcolor(gs10) lw(medthick) msymbol(o) msize(small) mcolor(gs10) connect(l)  || ///
		scatter share fecha_td if group == 3, ///
		lcolor(dknavy) lw(medthick) msymbol(o) msize(small) mcolor(dknavy) connect(l)  ||, ///
		ylabel(,nogrid angle(horizontal)) graphregion(fcolor(white) lcolor(gs16)) xtitle("") ///
		ytitle("") subtitle("% presented declaration", pos(11) span size(medsmall)) xscale(titlegap(*5))	///
			legend(lab(1 "Control") lab(2 "Treatment(didn't open meail)") lab(3 "Treatment(opened email)")   region(lcolor(gs16))) 
	graph export "$figures/acumulado_open_english.pdf", replace
restore

