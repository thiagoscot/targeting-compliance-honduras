/*
Author: Thiago Scot
Date: March 17th 2020
Modified:
Name: Master_experiment.do
Description: Master do-file for letter experiment in Honduras.
*/


/*Installing packages
ssc install rscript, replace
ssc install randtreat, replace
 ssc install ietoolkit
 */

local ssc_modules cdfplot rscript randtreat frmttable
foreach module in `ssc_modules' {
	capture which `module'
	if _rc == 111 {
		ssc install `module'
	}
}


clear all
set more off
ieboilstart , versionnumber(15.1) 
 `r(version)'

*Running time:   - See timing below*
timer clear 1
timer clear 2

timer on 1

**Set here = 2 and adjust path to personal folder below
global user = 1

** Thiago
if $user == 1 global path "/Users/thiagoscott/Dropbox/HondurasExperiment_Reproducibility"

** Other user
if $user == 2 global path "{set here user path}/HondurasExperiment_Reproducibility"


*Globals
global input 	"$path/Inputs"
global output 	"$path/output"
global do 	  	"$path/FinalCode"
global out 	  	"$path/out"
global tables 	"$out/Tables"
global figures	"$out/Figures"

quietly {
	*Do-File performing initial power calculations and performing randomization
	do "$do/1a_BaselineData_Clean.do"
	do "$do/1b_Power_Calculations_PreRand.do"
	do "$do/1c_Randomization.do"

	*Do-File using randomized database, treatment of variables and present balance tests and descriptive stats
	do "$do/2_BaselineDescriptives.do"

	*Generate final results from experiment
	do "$do/3a_ExperimentalResults_Clean.do"
	do "$do/3b_ExperimentalResults_TablesGraphs.do"
	
	*Expert survey results
	do "$do/4a_ExpertSurvey_Clean.do"
	do "$do/4b_ExpertSurvey_Results.do"
	
	*Annex: Pilot results
	do "$do/5a_Pilot_CleanData.do"
	do "$do/5b_Pilot_Results.do"
	
	timer off 1
}

*R-script to run Random Forest (ML) prediction model
timer on 2
di in red "Running R-script to generate ML model"

rscript using "$do/6_RandomForest.R", args("$path")

timer off 2
	

timer list 1
  /* Stata code 1:    156.55 /        1 =     156.5540 */

timer list 2
  /* R code 	2:     579.65 /        1 =     579.6510 */

