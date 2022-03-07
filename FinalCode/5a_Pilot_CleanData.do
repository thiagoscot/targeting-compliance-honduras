di in red "Cleaning pilot experiment dataset"

import excel "$input/Pilot_dataset.xlsx", sheet("default") firstrow clear

gen presented = FECHA_PRESENTACION != .

lab def presented 1"Presented declaration" 0"Did not present declaration"
lab val presented presented

gen treatment = CATEGORIA == "Tratamiento"
lab def  treatment 1"Treatment" 0"Control"
lab val treatment treatment

encode DEPARTAMENTO, gen(dept)
encode TIPO_OT, gen(type)
recode type (2 = 0), gen(juridico_dummy)

encode DIRECCIONESREGIONALESRA, gen(regional)

gen impuesto_causado = Impuesto_causado_L_2018
replace impuesto_causado = 0 if impuesto_causado == .

gen presento_2017 = Presentó_DJISR_2017
replace presento_2017 = 0 if presento_2017 == .
gen ing_isr_2017_declared =   Ingresos_grav_declarados_2017  
replace ing_isr_2017_declared = 0 if ing_isr_2017_declared==.


gen ihs_impuesto = asinh(impuesto_causado) 
gen log_impuesto = ln(1+impuesto_causado)

gen fecha_td = dofc(FECHA_PRESENTACION)
format fecha_td %td

gen received = Consolidado_Status == "clicked" | Consolidado_Status == "opened"


save "$output/pilot_dataset_clean.dta", replace
