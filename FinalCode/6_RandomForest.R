##############################
# 0 - Load librairies
##############################

rm(list = ls())
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, tidyr, stringr,splitstackshape,pdftools,V8,purrr,stringr,
               gplots, apcluster,ggplot2,data.table, lubridate,
               grf, viridis, grid, gridExtra, cowplot)

options(scipen = 999)
set.seed(5855)

args = commandArgs(trailingOnly = "TRUE")

path = args[1]
  
#path = '/Users/thiagoscott/Dropbox/HondurasExperiment_Reproducibility/'
database = paste0(path,'/output/')
figures = paste0(path,'/out/Figures/')


#Loads dataset exported from Stata and create dummies and factor levels for Random Forest Algorithm
dataset = fread(paste0(database,'data_GRF.csv')) %>% 
  mutate(declaraciones_presentadas_2018_r = ifelse(is.na(declaraciones_presentadas_2018_r),0,declaraciones_presentadas_2018_r),
         z = ifelse(is.na(z), 0,z),
         dom_nuevo1 = ifelse(dom_nuevo == 1,1,0),
         dom_nuevo2 = ifelse(dom_nuevo == 2,1,0),
         dom_nuevo3 = ifelse(dom_nuevo == 3,1,0),
         risk_level_f = as.numeric(factor(risk_level)),
         risk_level_english = factor(risk_level, 
                                     labels = c("Low", "Medium-Low", "Medium","Medium-High", "High")))


########## Main specification: Random Forest using probability of filing as outcome of interest
outcome = dataset %>% select(filed_declaration) %>% as.matrix()
outcome_revenue = dataset %>% select(ingresos_isr_2019_ihs) %>% as.matrix()
covariates = dataset %>% select(comerciante_individual, asalariado_2018, profesional_independiente_2018,
                                ingresosdeterceros_2019,juridico_dummy,dom_nuevo1, dom_nuevo2,dom_nuevo3,
                                z,presentó_djisr_2018, ingresos_isr_informados_2018_th,
                                ingresos_isr_declarados_2018_th, base_imponible_renta_2018_th,ingresos_isv_2019_th,
                                declaraciones_presentadas_2018_r) %>% 
  as.matrix()
treatment = dataset %>% select(treatment_pooled) %>% as.matrix()

forest_outcome = causal_forest(Y = outcome,
                       X = covariates,
                       W = treatment,
                       num.trees = 2000,
                       sample.fraction = 0.2,
                       honesty = TRUE,
                       honesty.fraction = 0.5)

#rm(forest, outcome)
forest_revenue = causal_forest(Y = outcome_revenue,
                       X = covariates,
                       W = treatment,
                       num.trees = 2000,
                       sample.fraction = 0.2,
                       honesty = TRUE,
                       honesty.fraction = 0.5)

prediction         = predict(forest_outcome,covariates)
prediction_revenue = predict(forest_revenue,covariates)

dataset = dataset %>% mutate(predicted         = prediction$predictions,
                             predicted_revenue = prediction_revenue$predictions)

p5 = dataset %>% summarise(quantile = quantile(predicted, c(0.05,0.95)))

#Figures main text

{
  ##Figure 4: Estimated treatment effects on filing probability (Random Forest)
ggplot(dataset, aes(x = predicted)) +
  geom_histogram(bins = 100) + 
  geom_vline(xintercept = p5[1,1], linetype = 'dotted', color = 'red') + 
  geom_vline(xintercept = p5[2,1], linetype = 'dotted', color = 'red') +
  labs(x = "Predicted treatment effect", y = 'Count') +
  theme_classic() +
  theme(panel.border = element_blank(),
        panel.background = element_blank())
ggsave(paste0(figures, 'histo_predictions.png'),width = 6, height = 4)

##Figure 5a: Estimated treatment effects on filing probability (Random Forest) across risk levels
ggplot(dataset,aes(x = z, y = predicted)) +
  geom_point(alpha = 0.05)  +
  geom_smooth() + 
  geom_hline(yintercept = 0, color = 'red', linetype = 'dotted') +
  labs(x = "Risk-level", y = 'Predicted treatment effect') + 
  theme_classic() + 
  theme(panel.border = element_blank(),
        panel.background = element_blank())
ggsave(paste0(figures,'risk_predictions.png'),width = 6, height = 4)

##Figure 5b: Estimated treatment effects on filing probability (Random Forest) across risk levels
dataset %>% group_by(risk_level_english) %>% 
  summarise(mean = weighted.mean(predicted,w = ingresos_isr_declarados_2018_th)) %>% 
  ggplot(aes(x = risk_level_english, y = mean)) +
  geom_bar(stat = 'identity')  +  
  scale_y_continuous(limits = c(-0.02,0.02)) +
  labs(x = "Risk-level categories", y = 'Mean predicted treatment effect') + 
  theme_classic() + 
  theme(panel.border = element_blank(),
        panel.background = element_blank())
ggsave(paste0(figures,'risk_categories.png'),width = 6, height = 4)

}

####Appendix: Random Forest model for gross revenue


#Figures

{
#### Figure A1.a: Estimated treatment effects on declared gross revenue (Random Forest) 
dataset %>% group_by(risk_level_english) %>% 
  summarise(mean = weighted.mean(predicted_revenue,w = ingresos_isr_declarados_2018_th)) %>% 
  ggplot(aes(x = risk_level_english, y = mean)) +
  geom_bar(stat = 'identity')  +  
  labs(x = "Risk-level categories", y = 'Mean predicted treatment effect') + 
  theme_classic() +
  theme(panel.border = element_blank(),
        panel.background = element_blank())
ggsave(paste0(figures, 'risk_categories_revenue.png'),width = 6, height = 4)

#### Figure A1.b: Estimated treatment effects on declared gross revenue (Random Forest) 
ggplot(dataset, aes(x = predicted_revenue)) +
  geom_histogram(bins = 100) + 
  labs(x = "Predicted treatment effect", y = 'Count') +
  theme_classic() +
  theme(panel.border = element_blank(),
        panel.background = element_blank())
ggsave(paste0(figures,'histo_predictions_revenue.png'),width = 6, height = 4)

}

