/*
Author: Thiago Scot
Date:
Modified:
Name: Analysis_survey.do
Description: Loads expert survey data and provide descriptive statistics
*/
di in red "Cleaning expert survey data"

*Loads answers from expert survey collected in Qualtrics
import delimited "$input/ExpertSurvey_dataset.csv", clear

drop if enddate == ""

rename q18 Q0_1
rename q19 Q0_2
rename q8  Q1
rename q11 Q2
rename q13 Q3
rename q15_1 Q4_1
rename q15_2 Q4_2
rename q15_3 Q4_3
rename q16_4 Q5_1
rename q16_5 Q5_2
rename q16_6 Q5_3
rename q27_4 Q6_1
rename q27_5 Q6_2
rename q27_6 Q6_3
rename q30_1 Q7_1
rename q30_2 Q7_2
rename q30_3 Q7_3
rename q30_4 Q7_4
rename q30_5 Q7_5
rename q20	 Q8

lab def Q0_1 1"Academic economist" 2"Public sector employee in Honduras" 3"Policy-oriented researcher" 4"Other"
lab val Q0_1 Q0_1
lab def Q0_2 1"Not confident at all" 2"Not very confident" 3"Somewhat confident" 4"Confident"
lab val Q0_2 Q0_2

drop if (Q4_1==. & Q4_2==. & Q4_3==.) | Q1 == .						//Deletes 35 incomplete observations

tab finished														//635 incomplete surveys have most answers, keeping them for now

recode  Q0_1 (4 = 3), gen(type_respondent)
lab def type_respondent 1"Academic economist" 2"Public sector employee in Honduras" 3"Policy-oriented researcher or other"
lab val type_respondent type_respondent

			   
**** CHECKING CONSISTENCY OF ANSWERS *****

/*For Q1, some respondents clearly input the total filing rate (e.g 90%) instead of treatment effect.
Consider that whenever answer is more than 80 they meant the total, so calculate prediction as difference
from baseline of 86% compliance.
*/
replace Q1 = Q1 - 86 if Q1 >= 80 & Q1 !=.

*Checking consistency for overall estimate vs. treatment arm estimates
*At a minimum, overall estimate needs to be within the minimum and maximum estimates for the three arms
forv i = 1/3 {
	loc j = `i'+3
	gen maxq`i' = max(Q`j'_1, Q`j'_2, Q`j'_3)
	gen minq`i' = min(Q`j'_1, Q`j'_2, Q`j'_3)
	gen consist_`i' = (Q`i' >= minq`i' & Q`i' <= maxq`i')

}

gen maxq7 = max(Q7_1, Q7_2, Q7_3,Q7_4,Q7_5)
gen minq7 = min(Q7_1, Q7_2, Q7_3,Q7_4,Q7_5)
gen consist_7 = (Q2 >= minq7 & Q2 <= maxq7)

egen total = rowtotal(consist_1 consist_2 consist_3 consist_7) 

tab total
/*
      total |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |         11       14.47       14.47
          1 |          7        9.21       23.68
          2 |          4        5.26       28.95
          3 |         23       30.26       59.21
          4 |         31       40.79      100.00
------------+-----------------------------------
      Total |         76      100.00


*/

drop if total == 0													//Drop 11	 observations which are inconsistent in all questions

*Trimming all values larger than mean + 3*sd
foreach var of varlist Q1 Q2 Q3 Q4_1 Q4_2 Q4_3 Q5_1 Q5_2 Q5_3 Q6_1 Q6_2 Q6_3 Q7_1 Q7_2 Q7_3 Q7_4 Q7_5 {
	summ `var'
	gen `var'_trim = `var'
	replace `var'_trim = . if abs(`var') > `r(mean)' + 3*`r(sd)'
}

lab var Q1_trim		"Filing probability (Pooled)"
lab var Q4_1_trim	"Filing probability (Sanctions)"
lab var Q4_2_trim	"Filing probability (Procedure)"
lab var Q4_3_trim	"Filing probability (Tax morale)"
lab var Q2_trim		"Gross revenue (Pooled)"
lab var Q5_1_trim	"Gross revenue (Sanctions)"
lab var Q5_2_trim	"Gross revenue (Procedure)"
lab var Q5_3_trim	"Gross revenue (Tax morale)"
lab var Q7_1_trim	"Gross revenue (Low risk)"
lab var Q7_2_trim	"Gross revenue (Medium-low risk)"		
lab var Q7_3_trim	"Gross revenue (Medium risk)"
lab var Q7_4_trim	"Gross revenue (Medium-high risk)"
lab var Q7_5_trim	"Gross revenue (High risk)"
lab var Q3_trim		"Taxable income (Pooled)"
lab var Q6_1_trim	"Taxable income (Sanctions)"	
lab var Q6_2_trim	"Taxable income (Procedure)"
lab var Q6_3_trim	"Taxable income (Tax morale)"


save "$output/survey_data_clean.dta", replace
