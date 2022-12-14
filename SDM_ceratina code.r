{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}}
{\*\generator Riched20 10.0.22000}\viewkind4\uc1 
\pard\sa200\sl276\slmult1\f0\fs22\lang9 setwd("D:/DMMG Review work/Clipped/Selected")\par
library(raster); library(sdm);library(rgdal);library(dismo);library(rJava);library(usdm)\par
#citation("usdm")\par
######################################################################\par
species <- shapefile("ceratina.shp") # read the shapefile\par
plot(species)\par
lst <- list.files(path="D:/DMMG Review work/Clipped/Selected", pattern='tif$',full.names = T) \par
lst2 <- list.files(path="D:/DMMG Review work/Clipped/245", pattern='tif$',full.names = T)\par
lst3 <- list.files(path="D:/DMMG Review work/Clipped/585",pattern='tif$',full.names = T)\par
# list the name of the raster files\par
# stack is a function in the raster package, to read/create a multi-layers raster dataset\par
preds <- stack(lst)\par
plot(preds)\par
preds2 <- stack(lst2)\par
preds3 <- stack(lst3)\par
# making a raster object\par
#Calculate VIFs suing all the variables\par
#vif(preds) # calculates vif for the variables in r\par
v1 <- vifcor(preds, th=0.7) # identify collinear variables that should be excluded\par
v1\par
#Create the SDM data to be used in the model using psudo absence data\par
d <- sdmData(formula=occ~., train=species, predictors=preds,bg=list(n=10000,method='gRandom',remove=TRUE))\par
d\par
write.sdm(d,"d_model",overwrite = TRUE)\par
d<-read.sdm("d_model.sdd")\par
getmethodNames('sdm') #gives you all the possible models in 'sdm' package\par
# fit the models (3 methods, and 10 replications using bootstrapping or cross validation procedure):\par
m <- sdm(occ~.,data=d,methods=c('rf','maxent',"svm"), replication='cv',cv.folds=10)\par
#use the graphical user interface\par
gui(m)\par
write.sdm(m, "m_model", overwrite = TRUE)\par
m<-read.sdm("m_model.sdm")\par
# predict for all the methods but take the mean over all replications for each replication method: \par
predict_curr <- predict(m, newdata=preds, filename='D:/DMMG Review work/Predictions/Current/current.tif',mean=T, overwrite = TRUE) #current\par
predict_245 <- predict(m, newdata=preds2, filename='D:/DMMG Review work/Predictions/245/SSP_245.tif',mean=T, overwrite = TRUE)#Future\par
predict_585 <- predict(m, newdata=preds3, filename='D:/DMMG Review work/Predictions/585/SSP_585.tif',mean=T, overwrite = TRUE)#Future\par
# ensemble using weighted averaging based on AUC statistic:\par
en_curr <- ensemble(m, newdata=preds, filename='D:/DMMG Review work/Predictions/Current/Ensemble_current.tif', setting=list(method='weighted',stat='AUC'))\par
en245 <- ensemble(m, newdata=preds2, filename='D:/DMMG Review work/Predictions/245/Ensemble_SSP245.tif', setting=list(method='weighted',stat='AUC'))\par
en585 <- ensemble(m, newdata=preds3, filename='D:/DMMG Review work/Predictions/585/Ensemble_SSP585.tif', setting=list(method='weighted',stat='AUC'))\par
#Models evaluation\par
eval <- getEvaluation(m,w=1:30,wtest='training',stat=c('AUC','TSS','COR','Deviance'),opt=1)    # get evaluation values from models\par
#then I can set what are the thresholds that I want:\par
auc.th <- 0.9\par
tss.th <- 0.9\par
# # then get my models from the matrix:\par
good_models <- eval[eval[,"AUC"] >= auc.th & eval[,"TSS"] >= tss.th,]\par
#You can view all the metrics in a CSV\par
write.csv(eval,'D:/DMMG Review work/all_models_evaluation.csv')\par
write.csv(good_models,'D:/DMMG Review work/good_models_evaluation.csv')\par
#You can change and predict with only the good models\par
# p <- predict(... , w = good_models$modelID)\par
#Plot the ROC and AUC\par
roc(m, smooth = TRUE)\par
#random forest\par
rf <- getVarImp(m,id=1:10,wtest='test.dep') # specify the modelIDs of the models\par
rf\par
plot(rf,'cor')\par
#Maxent model\par
maxent <- getVarImp(m,id=11:20,wtest='test.dep') # specify the modelIDs of the models\par
maxent \par
plot(maxent,'cor')\par
#Support vector machine\par
svm <- getVarImp(m,id=21:30,wtest='test.dep') # specify the modelIDs of the models\par
svm\par
plot(svm,'cor')\par
#Calculate the mean variable importance of all the models\par
meanVarImpo_All_models <- getVarImp(m,id=1:30,wtest='test.dep') \par
print('HoooRAY')\par
}
 