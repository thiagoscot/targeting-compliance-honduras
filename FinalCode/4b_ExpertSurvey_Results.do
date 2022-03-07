
di in red "Creating expert survey results"


use "$output/survey_data_clean.dta", clear

******      TABLE 7: Descriptive Statistics - Forecast survey
global desc "Q1_trim Q4_1_trim Q4_2_trim Q4_3_trim Q2_trim Q5_1_trim Q5_2_trim Q5_3_trim  Q7_1_trim Q7_2_trim Q7_3_trim Q7_4_trim Q7_5_trim Q3_trim Q6_1_trim Q6_2_trim Q6_3_trim"
eststo drop *
eststo desc: quietly estpost summarize $desc ,d

esttab desc using "$tables/table_descriptive_survey.tex", replace ///
	cells("mean(fmt(%18.1fc)) p50 sd min p25  p75 max count(fmt(%18.0fc))") nonum ///
	refcat(Q1_trim "\emph{Filing probability (p.p.)}"  Q2_trim "\emph{Gross revenue (\%)}" Q3_trim "\emph{Taxable income (\%)}", nolabel) collabels("Mean" "p50" "SD" "Min" "p25" "p75" "Max" "N") /// 
	label  f booktabs brackets noobs ///
	starlevels(* 0.1 ** 0.05 *** 0.01) ///
	coeflabels(Q1_trim "\quad Pooled" Q4_1_trim "\quad Sanctions" Q4_2_trim "\quad Procedures" Q4_3_trim "\quad Tax morale" ///
	Q2_trim "\quad Pooled" Q5_1_trim "\quad Sanctions"  Q5_2_trim "\quad Procedures" Q5_3_trim "\quad Tax morale" ///
	Q7_1_trim "\quad Low risk" Q7_2_trim "\quad Medium-low risk" Q7_3_trim "\quad Medium risk" Q7_4_trim "\quad Medium-high" Q7_5_trim "\quad High risk" ///
	 Q3_trim "\quad Pooled"  Q6_1_trim "\quad Sanctions"   Q6_2_trim "\quad Procedures"  Q6_3_trim "\quad Tax morale")

	 
	 
*******     FIGURE 6: Survey estimates
preserve
	loc i = 1
	foreach var of varlist $desc {
		rename `var' q_`i'
		loc ++i
	}

	keep responseid q_* Q0_1
	reshape long q_, i(responseid) j(question)

	statsby N=r(N) mean=r(mean) ub=r(ub) lb=r(lb) , by(question) clear: ci means q_

	twoway (rcap ub lb question) (scatter mean question), xline(4.5, lp(dot) lw(thin)) xline(8.5, lp(dot) lw(thin)) xline(13.5, lp(dot) lw(thin)) ///
		xlabel(1 "Pooled"  2 "Sanctions"  3 "Procedure" 4 "Tax morale" 5 "Pooled"  6 "Sanctions" 7 "Procedure"  8 "Tax morale" ///
			   9 "Low"  10 "Medium-low"  11 "Medium" 12 "Medium-high"    13 "High" ///
			   14 "Pooled"  15 "Sanctions"  16 "Procedure" 17 "Tax morale", labsize(small) angle(45)) ///
		legend(off) graphregion(fcolor(white)  lcolor(gs16)) text(14.7 2.6 "Filing probablity (p.p.)", size(small))  ///
		text(14.7 6.5 "Gross revenue (%)", size(small)) text(14.7 11 "Gross revenue by risk (%)", size(small)) ///
		text(14.7 15.5 "Taxable income (%)", size(small))  xtitle("") ylab(, glw(vthin))
	graph export "$figures/graph_survey.pdf", replace	
restore



*******     FIGURE 7: Forecast by groups of respondents
preserve
	loc i = 1
	foreach var of varlist $desc {
		rename `var' q_`i'
		loc ++i
	}

	keep responseid q_* Q0_1 type_respondent
	reshape long q_, i(responseid) j(question)
	
	statsby N=r(N) mean=r(mean) ub=r(ub) lb=r(lb), by(question type_respondent) clear: ci means q_  
	
	gen x = _n
	
	separate mean, by(type_respondent)
	separate ub, by(type_respondent)
	separate lb, by(type_respondent)

	twoway (rcap ub1 lb1 x) (scatter mean1 x) ///
			(rcap ub2 lb2 x) (scatter mean2 x) ///
			(rcap ub3 lb3 x) (scatter mean3 x) if inlist(question,1,2,3,4), ///
			xline(3.5, lp(dot) lw(thin)) xline(6.5, lp(dot) lw(thin)) xline(9.5, lp(dot) lw(thin)) xline(12.5, lp(dot) lw(thin)) ///
		xlabel(1 "Academics"  2 "Govt employees"  3 "Policy workers" 4 "Academics"  5 "Govt employees"  6 "Policy workers" ///
			   7 "Academics"  8 "Govt employees"  9 "Policy workers" 10 "Academics"  11 "Govt employees"  12 "Policy workers" ///
			   , labsize(small) angle(45)) ///
		legend(off) graphregion(fcolor(white)  lcolor(gs16))   ///
		text(14.7 2 "Pooled sample", size(small)) text(14.7 5 "Sanctions arm", size(small)) ///
		text(14.7 8 "Procedure denial arm", size(small)) text(14.7 11 "Tax morale arm", size(small))  ///
		xtitle("") ylab(, glw(vthin)) ytitle("p.p. change in filing probability") yline(0, lc(black))
		graph export "$figures/survey_filing_het.pdf", replace	

	twoway (rcap ub1 lb1 x) (scatter mean1 x) ///
			(rcap ub2 lb2 x) (scatter mean2 x) ///
			(rcap ub3 lb3 x) (scatter mean3 x) if inlist(question,5,6,7,8), ///
			xline(15.5, lp(dot) lw(thin)) xline(18.5, lp(dot) lw(thin)) xline(21.5, lp(dot) lw(thin))  ///
		xlabel(13 "Academics"  14 "Govt employees"  15 "Policy workers" 16 "Academics"  17 "Govt employees"  18 "Policy workers" ///
			   19 "Academics"  20 "Govt employees"  21 "Policy workers" 22 "Academics"  23 "Govt employees"  24 "Policy workers" ///
			   , labsize(small) angle(45)) ///
		legend(off) graphregion(fcolor(white)  lcolor(gs16))   ///
		text(30 14 "Pooled sample", size(small)) text(30 17 "Sanctions arm", size(small)) ///
		text(30 20 "Procedure denial arm", size(small)) text(30 23 "Tax morale arm", size(small))  ///
		xtitle("") ylab(, glw(vthin)) ytitle("% change in declared gross income") yline(0, lc(black))
		graph export "$figures/survey_gross_het.pdf", replace	

		
	twoway (rcap ub1 lb1 x) (scatter mean1 x) ///
			(rcap ub2 lb2 x) (scatter mean2 x) ///
			(rcap ub3 lb3 x) (scatter mean3 x) if inlist(question,14,15,16,17), ///
			xline(42.5, lp(dot) lw(thin)) xline(45.5, lp(dot) lw(thin)) xline(48.5, lp(dot) lw(thin))  ///
		xlabel(40 "Academics"  41 "Govt employees"  42 "Policy workers" 43 "Academics"  44 "Govt employees"  45 "Policy workers" ///
			   46 "Academics"  47 "Govt employees"  48 "Policy workers" 49 "Academics"  50 "Govt employees"  51 "Policy workers" ///
			   , labsize(small) angle(45)) ///
		legend(off) graphregion(fcolor(white)  lcolor(gs16))   ///
		text(20 41 "Pooled sample", size(small)) text(20 44 "Sanctions arm", size(small)) ///
		text(20 47 "Procedure denial arm", size(small)) text(20 50 "Tax morale arm", size(small))  ///
		xtitle("") ylab(, glw(vthin)) ytitle("% change in declared taxable income") yline(0, lc(black))
		graph export "$figures/survey_taxable_het.pdf", replace	
restore



	
