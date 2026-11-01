# Information -------

# Title: Time Series Project Analysis
# Author: John Inston
# Date: May 30th, 2023
# Course: PSTAT274
# Supervisor: Raya Feldman

# Setup ---------------

# load libraries
library(tsdl) # source for data
library(zoo) # rollmean 
library(ggplot2) # plots and figures
library(tidyr) # updaed r syntax
library(gridExtra) # multiple ggplots 
library(forecast) # seasonal plot
library(tseries) # adf test function
library(kableExtra) # tables
library(astsa) # acf2, 
library(LSTS) # 
library(MASS) # box-cox (potentially remove)
library(TSA)
library(ggpubr) # qqplot 
library(lmtest)

# time series decomposition
#devtools:: install_github("brisneve/ggplottimeseries")
library(ggplottimeseries)

# set plot information
theme_set(theme_minimal())

# set seed
set.seed(8467)

# define plot roots function
plot.roots <- function(ar.roots=NULL, ma.roots=NULL, size=2, angles=FALSE, special=NULL, sqecial=NULL,my.pch=1,first.col="blue",second.col="red",main=NULL)
{xylims <- c(-size,size)
omegas <- seq(0,2*pi,pi/500)
temp <- exp(complex(real=rep(0,length(omegas)),imag=omegas))
plot(Re(temp),Im(temp),typ="l",xlab="x",ylab="y",xlim=xylims,ylim=xylims,main=main)
abline(v=0,lty="dotted")
abline(h=0,lty="dotted")
if(!is.null(ar.roots))
{
  points(Re(1/ar.roots),Im(1/ar.roots),col=first.col,pch=my.pch)
  points(Re(ar.roots),Im(ar.roots),col=second.col,pch=my.pch)
}
if(!is.null(ma.roots))
{
  points(Re(1/ma.roots),Im(1/ma.roots),pch="*",cex=1.5,col=first.col)
  points(Re(ma.roots),Im(ma.roots),pch="*",cex=1.5,col=second.col)
}
if(angles)
{
  if(!is.null(ar.roots))
  {
    abline(a=0,b=Im(ar.roots[1])/Re(ar.roots[1]),lty="dotted")
    abline(a=0,b=Im(ar.roots[2])/Re(ar.roots[2]),lty="dotted")
  }
  if(!is.null(ma.roots))
  {
    sapply(1:length(ma.roots), function(j) abline(a=0,b=Im(ma.roots[j])/Re(ma.roots[j]),lty="dotted"))
  }
}
if(!is.null(special))
{
  lines(Re(special),Im(special),lwd=2)
}
if(!is.null(sqecial))
{
  lines(Re(sqecial),Im(sqecial),lwd=2)
}
}

# load data
tsdl_met <- subset(tsdl, 12, "Meteorology")
rawdata <- tsdl_met[[2]]

# select training data
data <- head(rawdata, n=length(rawdata)-(12*5))

# Exploratory Analysis ----------

## Undifferenced Data -----

## plot of training data (with trend line)
# trend line
maline <- rollmean(data, k=12, fill=NA, align='right')
# produce time series plot
plotdata <- data.frame(
  "Time" = seq(as.Date("1959/1/1"), as.Date("1985/12/1"), "months"),
  "data" = data,
  "trend" = maline
)
plotdata %>% 
  tidyr::gather("id", "value", 2:3) %>% 
  ggplot(., aes(Time, value, col=id, linetype=id))+
  geom_line() +
  theme_light() +
  labs(x = "Time", y = "CO2 (ppm)", color="Legend", linetype="Legend")

## time series decomposition
ts_decomp <- ggdecompose(dts2(data, type ="additive"))+
  xlab("Date")+
  ylab("Atmospheric Concentration of CO2")+
  ggtitle("Time Series Decomposition Plots")
# seasonal plot
seasplot <- ggseasonplot(data, year.labels=TRUE, year.labels.left=TRUE) +
  ylab("CO2 (ppm)") +
  ggtitle("Seasonal plot") +
  theme_minimal()
trendplot <- autoplot(maline, ts.color="red", main="Trend plot") +
  theme_minimal()
grid.arrange(ts_decomp, seasplot, trendplot,
             layout_matrix = rbind(c(1, 1),
                                   c(2, 3)))

## acf of undifferenced data
acf(data, 40, main="ACF and PACF of raw data.")

## conclusion
# - non-stationary, remove trend by differncing with lag 12

## Diff Lag 12 Data -------

# differencing data
data_d <- diff(data, 12)

# time series plot of differenced data
plot_data_d <- data.frame(
  "Time" = seq(as.Date("1960/1/1"), as.Date("1985/12/1"), "months"),
  "yt" = data_d
)
tsplot_data_d <- plot_data_d %>% 
  tidyr::gather("id", "value", 2:2) %>% 
  ggplot(., aes(Time, value))+
  geom_line() +
  theme_minimal() +
  labs(x = "Time", y = "Seasonally Differenced Monthly CO2") +
  geom_smooth(method=lm) #add linear trend line

# acf plot of differenced data
acfplot_data_d <- autoplot(acf(data_d, lag=40, plot = FALSE))

grid.arrange(tsplot_data_d,acfplot_data_d, ncol=2)

## Diff Lag 12 & 1 Data ---------

# difference again with lag 1
data_dd <- diff(data_d, 1)

# plot of transformed data
# time series plot of differenced data
plot_data_dd <- data.frame(
  "Time" = seq(as.Date("1960/2/1"), as.Date("1985/12/1"), "months"),
  "yt" = data_dd
)
plot_data_dd %>% 
  tidyr::gather("id", "value", 2:2) %>% 
  ggplot(., aes(Time, value))+
  geom_line() +
  theme_minimal() +
  labs(x = "Time", y = "Transformed Data (zt)")

# table of variance of differenced data
var_table <- data.frame(
  "Transformation" = c("None", "Differenced lag 12", "Differenced lag 12 and lag 1"),
  "Variance" = c(var(data), var(data_d), var(data_dd))
)

# acf of differenced data
acf_data_dd <- autoplot(acf(data_dd, lag=40))

# histogram of differenced data
hist_data_dd <- ggplot(data.frame("data"=data_dd), aes(x=data)) +
  geom_histogram(color="darkblue", fill="lightblue") +
  ggtitle("Histogram")

# q-q plot of differenced data
qqplot_data_dd <- ggqqplot(data_dd, color="darkblue") + ggtitle("Q-Q plot")

grid.arrange(acf_data_dd, hist_data_dd, qqplot_data_dd,ncol=3)

# stationarity tests (adf and kpss)
adf_test <- adf.test(data_dd)
kpss_test <- kpss.test(data_dd, null="Trend")
table_data <- data.frame(
  Test = c("ADF Test", "KPSS Test"),
  Null = c("Process has a unit root and therefore a trend.",
           "Process is stationary"),
  pValue = c("<0.01", ">0.1"),
  Conclusion = c("Data is stationary", "Data is stationary")
)

# data appears stationary, proceed to model fitting

# Model Fitting ----------

# acf & pacf for parameter range selection
acf2(data_dd, 60, main="ACF and PACF of transformed data")

## SIMA Model Fitting -----------

# model 1 - sarima(0,1,1)(0,1,0)12
model1 <- Arima(data, 
                order=c(0,1,1),
                seasonal=list(order=c(0,1,0), period=12),
                method="ML")
model1
coeftest(model1)
# all coeffs significant
# AICc 279.55

# model 2 - sarima(0,1,0)(0,1,1)12
model2 <- Arima(data, 
                order=c(0,1,0),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML")
model2
coeftest(model2)
# all coeffs significant
# AICc 154.53

# model 3 - sarima(0,1,2)(0,1,0)12
model3 <- Arima(data, 
                order=c(0,1,2),
                seasonal=list(order=c(0,1,0), period=12),
                method="ML")
model3
coeftest(model3)
# MA2 insignificant
# AICc 280.87

# model 4 - sarima(0,1,1)(0,1,1)12
model4 <- Arima(data, 
                order=c(0,1,1),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML")
model4
coeftest(model4)
# all coeffs signficant
# AICc 123.84 <- pretty bloody good!

# model 5 - sarima(0,1,3)(0,1,0)12
model5 <- Arima(data, 
                order=c(0,1,3),
                seasonal=list(order=c(0,1,0), period=12),
                method="ML")
model5
coeftest(model5)
# MA2 insignificant
# AICc 270.05

# model 6 - sarima(0,1,2)(0,1,1)12
model6 <- Arima(data, 
                order=c(0,1,2),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML")
model6
coeftest(model6)
# MA2 insignificant
# AICc 125.3

# model 7 - sarima(0,1,3)(0,1,1)12
model7 <- Arima(data, 
                order=c(0,1,3),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML")
model7
coeftest(model7)
# MA2 insignificant
# AICc 119.57 <- second best SIMA model

# model 8 - sarima(0,1,3)(0,1,0)12 (MA2 removed)
model8 <- Arima(data, 
                order=c(0,1,3),
                seasonal=list(order=c(0,1,0), period=12),
                method="ML",
                fixed=c(NA,0,NA))
model8
coeftest(model8)
# all coeffs signficant
# AICc 268.05

# model 9 - sarima(0,1,3)(0,1,1)12 (MA2 removed)
model9 <- Arima(data, 
                order=c(0,1,3),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML",
                fixed=c(NA,0,NA,NA))
model9
coeftest(model9)
# all coeffs signficant
# AICc 117.51 <- top SIMA model

## select final model 1
finalmodel1 <- model9

## AR Parameters -----

# model 10 - sarima(1,1,1)(0,1,1)12
model10 <- Arima(data, 
                order=c(1,1,1),
                seasonal=list(order=c(0,1,1), period=12),
                method="ML")
model10
coeftest(model10)
# all coeffs signficant
# AICc 123.37 <- decent!

# model 11 - sarima(0,1,1)(1,1,1)12
model11 <- Arima(data, 
                 order=c(0,1,1),
                 seasonal=list(order=c(1,1,1), period=12),
                 method="ML")
model11
coeftest(model11)
# SAR1 insignificant
# AICc 125.69 

# model 12 - sarima(1,1,3)(0,1,1)12 MA2=0
model12 <- Arima(data, 
                 order=c(1,1,3),
                 seasonal=list(order=c(0,1,1), period=12),
                 method="ML", 
                 fixed=c(NA,NA,0,NA,NA))
model12
coeftest(model12)
# AR1 insignificant
# AICc 119.55

# model 13 - sarima(3,1,3)(0,1,1)12 MA2=0
model13 <- Arima(data, 
                 order=c(3,1,3),
                 seasonal=list(order=c(0,1,1), period=12),
                 method="ML", 
                 fixed=c(NA,NA,NA,NA,0,NA,NA))
model13
coeftest(model13)
# numerous insignificant coefficients
# AICc 123.1

# model 14 - sarima(3,1,1)(0,1,1)12 MA2
model14 <- Arima(data, 
                 order=c(3,1,1),
                 seasonal=list(order=c(0,1,1), period=12),
                 method="ML", 
                 fixed=c(NA,NA,NA,NA,NA))
model14
coeftest(model14)
# insignificant AR2 and AR3
# AICc 121.15

# model 15 - sarima(3,1,1)(0,1,1)12 AR1=AR2=0
model15 <- Arima(data, 
                 order=c(3,1,1),
                 seasonal=list(order=c(0,1,1), period=12),
                 method="ML", 
                 fixed=c(0,0,NA,NA,NA))
model15
coeftest(model15)
# all coeffs significant
# AICc 119.96

finalmodel2 <- model10

## final models
finalmodel1
coeftest(finalmodel1)
finalmodel2
coeftest(finalmodel2)

# Diagnostic Checking --------

## Model 1 ----

# residual analysis plots
resplot_model1 <- autoplot(finalmodel1$residuals, ylab="Residuals")
acf_model1_res <- autoplot(acf(finalmodel1$residuals)) + ggtitle("ACF plot")
pacf_model1_res <- autoplot(pacf(finalmodel1$residuals)) + ggtitle("PACF plot")
hist_model1_res <- ggplot(data.frame("data"=finalmodel1$residuals), aes(x=data)) +
  geom_histogram(color="darkblue", fill="lightblue") +
  ggtitle("Histogram")

qqplot_model1_res <- ggqqplot(finalmodel1$residuals, color="darkblue") + ggtitle("Q-Q plot")

model1_ljung <- Box.Ljung.Test(finalmodel1$residuals, lag=30)

grid.arrange(resplot_model1, acf_model1_res,hist_model1_res, pacf_model1_res, qqplot_model1_res, model1_ljung,
             layout_matrix = rbind(c(1, 1),
                                   c(2, 3),
                                   c(4, 5), 
                                   c(6, 6)))

# portmanteau tests
model1_sw <- shapiro.test(finalmodel1$residuals)
model1_bp <- Box.test(finalmodel1$residuals, lag =18, type = c("Box-Pierce"), fitdf = 3)
model1_lb <- Box.test(finalmodel1$residuals, lag = 18, type = c("Ljung-Box"), fitdf = 3)
model1_lbs <- Box.test((finalmodel1$residuals)^2, lag = 18, type = c("Ljung-Box"), fitdf = 0)

model1_tests <- data.frame("Test"=c("Shapiro-Wilk", "Box-Pierce", "Ljung-Box", "Ljung-Box (squared)"),
                           "p-value"=c(model1_sw$p.value, model1_bp$p.value, model1_lb$p.value, model1_lbs$p.value),
                           "Conclusion"=c("Normal", "Independence", "No autocorrelation in residuals", "No autocorrelation in squared residuals"))
model1_tests

## explore fitting ar models
#ar(model2$residuals, aic = TRUE, order.max = NULL, method = c("yule-walker"))

## Model 2 ------

# residual analysis plots
resplot_model2 <- autoplot(finalmodel2$residuals, ylab="Residuals")
acf_model2_res <- autoplot(acf(finalmodel2$residuals)) + ggtitle("ACF plot")
pacf_model2_res <- autoplot(pacf(finalmodel2$residuals)) + ggtitle("PACF plot")
hist_model2_res <- ggplot(data.frame("data"=finalmodel2$residuals), aes(x=data)) +
  geom_histogram(color="darkblue", fill="lightblue") +
  ggtitle("Histogram")

qqplot_model2_res <- ggqqplot(finalmodel2$residuals, color="darkblue") + ggtitle("Q-Q plot")

model2_ljung <- Box.Ljung.Test(finalmodel2$residuals, lag=30)

grid.arrange(resplot_model2, acf_model2_res,hist_model2_res, pacf_model2_res, qqplot_model2_res, model2_ljung,
             layout_matrix = rbind(c(1, 1),
                                   c(2, 3),
                                   c(4, 5), 
                                   c(6, 6)))

# portmanteau tests
model2_sw <- shapiro.test(finalmodel2$residuals)
model2_bp <- Box.test(finalmodel2$residuals, lag =18, type = c("Box-Pierce"), fitdf = 3)
model2_lb <- Box.test(finalmodel2$residuals, lag = 18, type = c("Ljung-Box"), fitdf = 3)
model2_lbs <- Box.test((finalmodel2$residuals)^2, lag = 18, type = c("Ljung-Box"), fitdf = 0)

model2_tests <- data.frame("Test"=c("Shapiro-Wilk", "Box-Pierce", "Ljung-Box", "Ljung-Box (squared)"),
                           "p-value"=c(model2_sw$p.value, model2_bp$p.value, model2_lb$p.value, model2_lbs$p.value),
                           "Conclusion"=c("Not Normal", "Independence", "No autocorrelation in residuals", "No autocorrelation in squared residuals"))
model2_tests

# root plots
plot.roots(NULL,polyroot(c(1, 0.354998, 0, -0.155974)), main="(1) roots model 1 ma part, nonseasonal ")
plot.roots(polyroot(c(1, 0, 0, 0.138542)),NULL, main="(2) roots of model 2 ar part, nonseasonal")

# Forecasting --------

# forecast plot
pred.tr <- predict(finalmodel1, n.ahead = 60)
U.tr= pred.tr$pred + 2*pred.tr$se # upper bound of prediction interval 
L.tr= pred.tr$pred - 2*pred.tr$se # lower bound
plot(data,xlim=c(time(data)[1],(time(rawdata)[length(rawdata)])), ylim = c(min(data),max(U.tr)), xlab="CO2 (ppm)")
lines(U.tr, col="blue", lty="dashed")
lines(L.tr, col="blue", lty="dashed")
#points(seq(time(rawdata)[length(rawdata)-59], time(rawdata)[length(rawdata)], by=(1/12)), pred.tr$pred, col="red", pch=20)
lines(seq(time(rawdata)[length(rawdata)-59], time(rawdata)[length(rawdata)], by=(1/12)), pred.tr$pred, col="red")

# focussed forecast plot
plot(data, xlim=c(time(data)[length(rawdata)-130],(time(rawdata)[length(rawdata)])), ylim = c(330,max(U.tr)), xlab="CO2 (ppm)")
lines(U.tr, col="blue", lty="dashed")
lines(L.tr, col="blue", lty="dashed")
#points(seq(time(rawdata)[length(rawdata)-59], time(rawdata)[length(rawdata)], by=(1/12)), pred.tr$pred, col="red", pch=20)
lines(seq(time(rawdata)[length(rawdata)-59], time(rawdata)[length(rawdata)], by=(1/12)), pred.tr$pred, col="red")
points(seq(time(rawdata)[length(rawdata)-59], time(rawdata)[length(rawdata)], by=(1/12)), rawdata[(length(rawdata)-59):length(rawdata)], pch=20)
legend("topleft", legend=c("Forecast", "Confidence Bounds", "Observed Values"),
       col=c("red", "blue", "black"), lty=c(1,2,NA), pch=c(NA,NA,20))

# Spectral Analysis ------

# periodogrms
unloadNamespace("GeneCycle")
par(mfrow=c(1,2))
periodogram(data) #, main="Plot 1 - Periodogram from data")
periodogram(finalmodel1$residuals) #, main="Plot 2 - Periodogram from residuals")
par(mfrow=c(1,1))

# fisher g test
library(GeneCycle)
fisher.g.test(model2$residuals)

# cumulative periodogram
cpgram(finalmodel1$residuals, main="")



