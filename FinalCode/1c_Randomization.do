
****************************************************************************************************************
*************************** RANDOMIZATION AND BALANCE CHECKS ***************************************************
****************************************************************************************************************
di in red "Performing randomization"

loc seed_nb = 5855
set seed `seed_nb'			//Set seed for randomization
	
	
*Randomization
randtreat, generate(treatment_status) setseed(`seed_nb') replace unequal(49/100 17/100 17/100 17/100) ///
		misfit(wstrata) strata(strata)

**Defining treatment groups
lab var treatment_status "Treatment indicator"
lab def treatment_status 0"Control" 1"Sanctions treatment" 2"Tax procedures treatment" 3"Moral duty treatment"
lab val treatment_status treatment_status

recode treatment_status  (1 2 3 = 1) , gen(treatment_v_control)
recode treatment_status  (1 =1) (2 3 = .), gen(threat_v_control)
recode treatment_status  (2 =1) (1 3 = .), gen(pacta_v_control)
recode treatment_status  (3 =1) (1 2 = .), gen(deber_v_control)

egen treatment_tercero = group(treatment_status ingresosdeterceros_2019)
replace treatment_tercero = 2 if treatment_tercero == 1

*This is the dataset provided to IT in the Tax Authority to send out emails
preserve
	keep id treatment_status ingresosdeterceros_2019 treatment_tercero duplicado
	
	save "$output/base_tecnologia_masivo.dta",replace
restore

*Baseline data now including randomization status
save "$output/randomized_base_experiment.dta",replace


