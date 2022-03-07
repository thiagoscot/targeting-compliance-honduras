README file for reproducibility check
Targeting in Tax Compliance Interventions: Experimental Evidence from Honduras (Giselle del Carmen, Edgardo Henrique Espinal Hernandez and Thiago Scot)


## Code included in this folder

This folder includes all code used to produce graphs and tables of the original paper. The entire code can be performed by executing the "0_Master_experiment.do" Stata do-file.

##  Data

The data used in this paper is anonymized, individual level microdata on taxpayers in Honduras. These data are not public. They were provided to the authors through collaboration with the Servicio de Administracion de Rentas (SAR), the tax authority in Honduras. The original datasets used for the analysis and loaded by the code are the following:

a. "Baseline_experiment.csv": Dataset with "baseline" data. This is a dataset at the taxpayer-level, provided by the Tax Authority, containing (anonymized) information on individual taxpayers behavior before 2020. This was used to determine the study sample, perform the randomization and test for balance at baseline.

b. "Endline_experiment.csv": "Endline" dataset. This dataset is also at the taxpayer level, provided by the Tax Authority, and contains information from their 2020 income tax filings - our main outcomes of interest.

c. "AdditionalInfo_endline.csv": Supplemental dataset with other information at taxpayer level in 2020 (such as total monthly sales taxes declared) provided by the Tax Authority.

d. "Pilot_dataset.xlsx": Dataset containing the results from a small experiment, implemented in late 2019, to assess the impact of sending emails to taxpayers. The results of this pilot are discussed in Annex B.

e. "ExpertSurvey_dataset.csv": Dataset containing the responses from experts forecasting the experimental results. The survey was implemented in Qualtrics, filled online and data downloaded on June 1st, 2020.


## Running the code

Executing the Master do-file on a MacBook pro with Mac OS 8gb RAM took approximately 11 mins (less than 2 min to run the entire Stata section but 9 minutes to run the random forest model in R).



