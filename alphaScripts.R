################################################
###
### experimental alpha scripts
### load data
### explore skew, Hurst
### simple trading strategies
###
###
################################################

rm(list=ls())
options(max.print=80)

# suppress spurious timezone warning messages
options(xts_check_TZ=FALSE)

library(TTR)


########### start temp scripts ###########

###########
# perform aggregations by applying a function over a vector of endpoints

### create random xts time series
x_ts <- xts(x=rnorm(100), order.by=(Sys.time()-3600*(1:100)))
# split time series into daily list
list_xts <- split(x_ts, "days")
# rbind the list back into a time series and compare with the original
identical(x_ts, do_call_rbind(list_xts))

### load minutely price data
sym_bol <- load("C:/Develop/data/SPY.RData")

# plot average hourly volumes
price_s <- Vo(SPY["2012-02-01/2012-02-25"])
vol_ume <- period.apply(
  x=price_s, 
  INDEX=endpoints(price_s, "hours"), 
  sum)
chart_Series(vol_ume, name="hourly volumes")
in_dex <- format(index(vol_ume), "%H:%M")
vol_ume <- tapply(X=vol_ume, INDEX=in_dex, FUN=mean)
vol_ume <- xts(as.vector(vol_ume), order.by=as.POSIXct(names(vol_ume), format="%H:%M"))
# normalize and plot vol_ume
in_dex <- c(30, diff(index(vol_ume)))
chart_Series(vol_ume/in_dex, name="hourly volumes")


### agg_regate() calculates an aggregation of an xts series
# and returns an xts series with a single row
agg_regate <- function(da_ta) {
  agg_regation <- c(max=max(da_ta), min=min(da_ta))
  xts(t(agg_regation), order.by=end(da_ta))
}  # end agg_regate
agg_regate(price_s)


### perform aggregations using period.apply(), apply_rolling() and apply_xts()
# apply_rolling() is legacy function from utilLib.R

# extract closing prices for a single day of data
price_s <- Cl(SPY["2012-02-13"])

end_points <- endpoints(price_s, "hours")
agg_regations <- period.apply(x=price_s, 
                            INDEX=end_points, 
                            FUN=agg_regate)
foo_bar <- apply_rolling(x_ts=price_s, 
                         end_points=end_points, 
                         func_tion=agg_regate)
agg_regations <- apply_xts(x_ts=price_s, 
                         end_points=end_points, 
                         func_tion=agg_regate)

# verify that apply_rolling() and apply_xts() produce identical output
identical(agg_regations, foo_bar)

# compare speed of apply_rolling() versus apply_xts()
library(microbenchmark)
summary(microbenchmark(
  agg_sapply=apply_rolling(x_ts=price_s, 
                           end_points=end_points, 
                           func_tion=agg_regate), 
  agg_lapply=apply_xts(x_ts=price_s, 
                                   end_points=end_points, 
                                   func_tion=agg_regate), 
  times=10))[, c(1, 4, 5)]  # end microbenchmark summary

agg_regations <- apply_rolling(x_ts=price_s, 
                               end_points=end_points, 
                               look_back=3, 
                               func_tion=agg_regate)
# plot aggregations with custom line colors
plot_theme <- chart_theme()
plot_theme$col$line.col <- c("red", "green")
chart_Series(agg_regations, theme=plot_theme, 
             name="price aggregations")
legend("bottomright", legend=colnames(agg_regations), 
       bg="white", lty=c(1, 1), lwd=c(2, 2), 
       col=plot_theme$col$line.col, bty="n")



###########
# plot histograms of returns data

### calculate stddev, skewness, and quantiles of returns data

re_turns <- 86400*diff(Cl(SPY))/c(1, diff(.index(SPY)))
re_turns[1, ] <- 0
sum(is.na(re_turns))
re_turns <- na.locf(re_turns)

sd(x=coredata(re_turns))
# skewness() from package "moments"
skewness(x=coredata(re_turns))
quantile(x=re_turns, probs=c(0.05, 0.95))
quantile(x=re_turns, probs=c(0.1, 0.9))


# plot histograms of daily returns
hist(re_turns, breaks=200, main="returns", xlab="", ylab="", freq=FALSE)
lines(density(re_turns), col="red", lwd=1)  # draw density

hist(re_turns, breaks=200, main="returns", xlab="", ylab="", freq=FALSE)
lines(density(re_turns), col="red", lwd=1)  # draw density

hist(re_turns, breaks=300, main="returns", xlab="", ylab="", xlim=c(-0.05, 0.05), freq=FALSE)
lines(density(re_turns), col="red", lwd=1)  # draw density

hist(daily_returns, breaks=100, main="returns", xlim=c(-2.0e-4, 2.0e-4), ylim=c(0, 10000), xlab="", ylab="", freq=FALSE)
lines(density(daily_returns), col="red", lwd=1)  # draw density

# title(main=ch.title, line=-1)  # add title



hist(re_turns, breaks=400, main="", xlab="", ylab="", xlim=c(-0.006, 0.006), freq=FALSE)
lines(density(re_turns), col="red", lwd=1)

library(PerformanceAnalytics)
chart.CumReturns(re_turns, lwd=2,
                 ylab="", legend.loc="topleft", main="")
chart.Histogram(re_turns, main="",
                xlim=c(-0.003, 0.003),
                methods=c("add.density", "add.normal"))
chart.Histogram(re_turns, main="",
                xlim=c(-0.003, 0.003), breaks=300,
                methods=c("add.normal"))


# copy the xts data to a variable with the name "sym_bol"
sym_bol_rets <- paste(sym_bol, "rets", sep=".")
assign(sym_bol_rets, da_ta)

########### end temp ###########


################
# managing high frequency data using package HighFreq

# load a single day of seconds TAQ data
sym_bol <- load("C:/Develop/data/hfreq/src/SPY/2012.02.16.SPY.RData")
# extract one day of TAQ data from list, and subset to NYSE trading hours using "T notation"
price_s <- (get(sym_bol)[[6]])["T09:30:00/T16:00:00", ]
# extract trade price and volume
price_s <- price_s[, c("Trade.Price", "Volume")]

# calculate mid bid-offer prices and remove NAs
mid_prices <- 0.5 * (price_s[, "Bid.Price"] + price_s[, "Ask.Price"])
mid_prices <- na.omit(mid_prices)
colnames(mid_prices) <- "Mid.Price"

# calculate log returns
re_turns <- diff(log(mid_prices))/c(1, diff(.index(mid_prices)))
re_turns[1, ] <- 0
chart_Series(cumsum(re_turns), name=sym_bol)

# load minutely OHLC data
sym_bol <- load("C:/Develop/data/SPY.RData")
# or
sym_bol <- load(
  file.path(output_dir, 
            paste0(sym_bol, ".RData")))
# calculate log returns
re_turns <- diff(log(Cl(get(sym_bol))))/c(1, diff(.index(get(sym_bol))))
re_turns[1, ] <- 0
chart_Series(cumsum(re_turns), name=sym_bol)

# plot histograms of returns
hist(re_turns, breaks=30, main="returns", xlab="", ylab="", freq=FALSE)
hist(re_turns, breaks=100, main="returns", xlim=c(-2.0e-4, 2.0e-4), ylim=c(0, 10000), xlab="", ylab="", freq=FALSE)
lines(density(re_turns), col='red', lwd=1)  # draw density


### calculate daily seasonality of returns
re_turns <- diff(Cl(get("SPY")))/c(1, diff(.index(get("SPY"))))
re_turns[1, ] <- 0
re_turns <- na.locf(re_turns)
sum(is.na(re_turns))
# remove overnight return spikes at "09:31"
in_dex <- format(index(re_turns), "%H:%M")
re_turns <- re_turns[!in_dex=="09:31", ]
# calculate daily seasonality of returns
season_rets <- season_ality(x_ts=re_turns)
chart_Series(x=season_rets, 
             name=paste(colnames(season_rets), "daily seasonality"))


### volatility spikes
vol_at <- run_variance(ohlc=SPY["2012/", 1:4])
# rolling vwav volatility
var_rolling <- roll_moment(ohlc=SPY["2012/"], win_dow=20)
in_dex <- index(var_rolling)
dim(var_rolling)
head(var_rolling)
tail(var_rolling)
plot(coredata(var_rolling), t="l")


# plot histogram of volatility - similar to chi-squared distribution
library(PerformanceAnalytics)
chart.Histogram(var_rolling, main="", xlab=colnames(var_rolling), 
                xlim=c(0, 5e-6), 
                methods=c("add.density"))
# add title
title(main=paste(sym_bol, "vol"), line=-1)
x_var <- seq(from=0, to=5e-6, by=1e-7)
lines(x=x_var, y=50*NROW(var_rolling)*dchisq(11*x_var/mean(var_rolling), df=11), 
      xlab="", ylab="", lwd=1, col="blue")

# identify periods around volatility spikes
quantile(var_rolling, probs=c(0.9, 0.99))
vol_spikes <- var_rolling[var_rolling>quantile(var_rolling, probs=0.99), ]
class(vol_spikes)
dim(vol_spikes)
head(vol_spikes)

foo <- c(1, as.numeric(diff(index(vol_spikes))))
foo <- c(1, which(foo>1), length(vol_spikes))
length(foo)
head(foo)
tail(foo)
plot(coredata(vol_spikes[(foo[3]-10):(foo[4]-1), ]), t="l")
plot(coredata(vol_spikes[(foo[3]-10):(foo[3]+40), ]), t="l")
which.max(vol_spikes[foo[3]:(foo[4]-1), ])
vol_spike <- vol_spikes[foo[3]:(foo[4]-1), ]
max(vol_spike)
vol_spike[which.max(vol_spike)]
blah <- which(in_dex==index(vol_spike[which.max(vol_spike)]))
plot(coredata(var_rolling[(blah-10):(blah+30), ])/max(vol_spike), t="l")

vol_peaks <- lapply(1:(length(foo)-1), function(i_ter) {
  vol_spike <- vol_spikes[foo[i_ter]:(foo[i_ter+1]-1), ]
  vol_spike[which.max(vol_spike)]
})  # end lapply
vol_peaks <- do.call(rbind, vol_peaks)
class(vol_peaks)
length(vol_peaks)
head(vol_peaks)
which(in_dex==index(first(vol_peaks)))

foo_bar <- function(vol_peak) {
  which_peak <- which(in_dex==index(vol_peak))
  coredata(var_rolling[(which_peak-10):(which_peak+30), ])/as.numeric(vol_peak)
}  # end foo_bar
foo_bar(first(vol_peaks))
foo_bar(vol_peaks[3])
foo_bar(last(vol_peaks))
debug(foo_bar)

vol_profiles <- sapply(1:3, function(i_ter) foo_bar(vol_peaks[i_ter, ]))

# calcuate volatility around peak volatility
vol_profiles <- sapply(seq_along(vol_peaks), function(i_ter) {
  which_peak <- which(in_dex==index(vol_peaks[i_ter, ]))
  coredata(var_rolling[(which_peak-200):(which_peak+300), ])/as.numeric(vol_peaks[i_ter, ])
})  # end sapply
class(vol_profiles)
dim(vol_profiles)
blah <- rowMeans(vol_profiles)
plot(blah, t="l")

# calcuate returns around peak volatility
price_profiles <- sapply(seq_along(vol_peaks), function(i_ter) {
  which_peak <- which(in_dex==index(vol_peaks[i_ter, ]))
  core_data <- coredata(SPY["2012/", 4][(which_peak-200):(which_peak+300)])
  core_data/max(core_data)
})  # end sapply
class(price_profiles)
dim(price_profiles)
blah <- rowMeans(price_profiles)
plot(blah, t="l")
hurst_exp(blah)
hurst_exp(blah, 22)

foo_bar <- apply(X=price_profiles, MARGIN=2, hurst_exp)
class(foo_bar)
dim(foo_bar)
head(foo_bar, 33)


### calculate Hurst exponent using range for xts
hurst_exp <- function(re_turns) {
  cum_sum <- cumsum(re_turns)
  (max(cum_sum) - min(cum_sum))/sd(re_turns)/sqrt(length(re_turns))
}  # end hurst_exp
hurst_exp <- function(da_ta) {
  (max(da_ta) - min(da_ta))/sd(diff(da_ta)[-1])/sqrt(length(da_ta))
}  # end hurst_exp
# calculate Hurst exponent using range for xts ohlc
hurst_exp <- function(da_ta) {
  (max(Hi(da_ta)) - min(Lo(da_ta)))/(max(Hi(da_ta)) + min(Lo(da_ta)))/sum(run_variance(ohlc=da_ta[, 1:4]))/sqrt(NROW(da_ta))/2
}  # end hurst_exp
# calculate Hurst exponent using range for non-xts
hurst_exp <- function(da_ta) {
  (max(da_ta) - min(da_ta))/sd(da_ta[-1]-da_ta[-length(da_ta)])/sqrt(length(da_ta))
}  # end hurst_exp
# calculate Hurst exponent using variance ratios for non-xts
hurst_exp <- function(da_ta, l_ag=4) {
  len_gth <- length(da_ta)
  var(da_ta[-(1:l_ag)]-da_ta[-((len_gth-l_ag+1):len_gth)])/var(da_ta[-1]-da_ta[-len_gth])/l_ag
}  # end hurst_exp
hurst_exp(coredata(SPY["2012/", 4]))
hurst_exp(coredata(SPY["2012/", 4]), l_ag=10)
blah <- rnorm(length(SPY["2012/", 4]))
head(blah)
hurst_exp(cumsum(blah))
hurst_exp(cumsum(blah+c(0, 0.5*blah[-length(blah)])))


### yearly aggregations of volume, skew, and volat

# extract vector of ye_ars
ye_ars <- format(
  index(sk_ew[endpoints(sk_ew, on="years"), ]), 
  format="%Y")
# sum up volumes for each year
volumes_yearly <- sapply(ye_ars, function(ye_ar) sum(Vo(SPY)[ye_ar]))
# first plot without "x" axis
plot(volumes_yearly, t="l", xaxt="n", xlab=NA, ylab=NA)
# add "x" axis with monthly ticks
axis(side=1, at=seq_along(volumes_yearly),
     labels=names(volumes_yearly))
# sum up skew and volat for each year
sapply(ye_ars, function(ye_ar) sum(vol_at[ye_ar]))
sapply(ye_ars, function(ye_ar) sum(sk_ew[ye_ar]))
foo <- sapply(ye_ars, function(ye_ar) sum(Vo(SPY)[ye_ar]))
foo <- format(index(daily_skew[which.max(daily_skew)]), "%Y-%m-%d")

foo <- which.max(daily_skew)
foo <- which.min(daily_skew)
foo <- format(index(daily_skew[(foo-1):(foo+1), ]), "%Y-%m-%d")

chart_Series(get(sym_bol)[foo], name=paste(sym_bol, "skew"))


# daily returns
daily_rets <- Cl(get(sym_bol)[index(daily_skew), ])
daily_rets <- diff(log(daily_rets))
daily_rets[1, ] <- daily_rets[2, ]
colnames(daily_rets) <- paste(sym_bol, "rets", sep=".")
head(daily_rets)
tail(daily_rets)

date_s <- "2008-09/2009-05"
# daily_rets and sk_ew
bar <- cbind(coredata(daily_rets), coredata(daily_skew))
# daily_rets and lagged sk_ew
bar <- cbind(coredata(daily_rets), c(0, coredata(daily_skew)[-length(daily_skew)]))

head(bar)
dim(bar)
apply(bar, 2, mad)
ma_d <- mad(bar[, 2])
blah <- (abs(bar[, 2]-mean(bar[, 2])) > 5*ma_d)
length(blah)
sum(blah)
bar <- bar[!blah, ]


### returns

# lag_rets equals returns lagged by -1
re_turns <- run_returns(x_ts=get(sym_bol))
lag_rets <- re_turns
lag_rets <- c(lag_rets[-1, ], lag_rets[length(lag_rets)])
tail(lag_rets)

sk_ew <- run_skew(ohlc=get(sym_bol))
colnames(sk_ew) <- 
  paste(sym_bol, "skew", sep=".")
lag_skew <- lag(sk_ew)


win_dow <- 2*60*6.5 + 101

# calc var_mad
var_mad <- runmad(coredata(vari_ance), k=win_dow)
# lag var_mad
var_mad <- c(rep(0, (win_dow-1)/2), var_mad[-((length(var_mad)-(win_dow-1)/2+1):(length(var_mad)))])
length(var_mad)
head(var_mad)
tail(var_mad)
# calc skew_mad
skew_mad <- runmad(coredata(sk_ew), k=win_dow)
# lag skew_mad
skew_mad <- c(rep(0, (win_dow-1)/2), skew_mad[-((length(skew_mad)-(win_dow-1)/2+1):(length(skew_mad)))])
plot(skew_mad[(length(skew_mad)-100*win_dow):length(skew_mad)], t="l", xlab="", ylab="", main="skew_mad")
# calc mad_volu
quan_tiles <- c("0.5"=0.5, "0.75"=0.75, "0.85"=0.85, "0.95"=0.95)
mad_volu <- runquantile(coredata(Vo(get(sym_bol))), probs=quan_tiles, k=win_dow)
mad_volu <- mad_volu[, 1, ]
# lag mad_volu
mad_volu <- rbind(
  matrix(numeric(ncol(mad_volu)*(win_dow-1)/2), ncol=ncol(mad_volu)), 
  mad_volu[-((NROW(mad_volu)-(win_dow-1)/2+1):(NROW(mad_volu))), ])
colnames(mad_volu) <- names(quan_tiles)
mad_volu <- xts(mad_volu, order.by=index(get(sym_bol)))
# plot(mad_volu[(NROW(mad_volu)-100*win_dow):NROW(mad_volu[,]), 4], t="l", xlab="", ylab="", main="mad_volu")
chart_Series(mad_volu[(NROW(mad_volu)-100*win_dow):NROW(mad_volu[,]), 4], name=paste(sym_bol, "mad_volu"))
# plot volume spikes above 85% quantile
date_s <- (NROW(mad_volu)-4*win_dow):NROW(mad_volu[,])
chart_Series(mad_volu[date_s, 3], name=paste(sym_bol, "mad_volu"))
chart_Series(Vo(get(sym_bol)[date_s]) - mad_volu[date_s, 4], name=paste(sym_bol, "volume spikes"))
chart_Series(Cl(get(sym_bol)[date_s]), name=paste(sym_bol, "prices"))


# signal threshold trading level
pos_skew <- coredata(ifelse(sk_ew > 5*skew_mad, 1, 0))
colnames(pos_skew) <- paste(sym_bol, "p_skew", sep=".")
neg_skew <- coredata(ifelse(sk_ew < -5*skew_mad, -1, 0))
colnames(neg_skew) <- paste(sym_bol, "n_skew", sep=".")
c(pos_skew=sum(pos_skew)/length(pos_skew), neg_skew=-sum(neg_skew)/length(neg_skew))
plot(pos_skew)

spike_skew <- coredata(Vo(get(sym_bol)) - mad_volu[, 4] > 0, sign(sk_ew), 0)
colnames(spike_skew) <- paste(sym_bol, "spike_skew", sep=".")

var_rolling <- runSum(vari_ance, n=win_dow)
var_rolling[1:(win_dow-1)] <- 0
colnames(var_rolling) <- colnames(vari_ance)
head(var_rolling)

chart_Series(var_rolling[date_s], 
             name=paste(sym_bol, "volatility"))

roll_skew <- runSum(sk_ew, n=win_dow)
roll_skew[1:(win_dow-1)] <- 0
colnames(roll_skew) <- colnames(sk_ew)
head(roll_skew)

chart_Series(roll_skew[date_s], 
             name=paste(sym_bol, "skew"))

win_short <- 70
win_long <- 225
vwap_short <- roll_vwap(oh_lc=get(sym_bol), win_dow=win_short)
vwap_long <- roll_vwap(oh_lc=get(sym_bol), win_dow=win_long)
head(vwap_short)
head(vwap_long)
vwap_diff <- vwap_short - vwap_long
colnames(vwap_diff) <- paste(sym_bol, "vwap", sep=".")
vwap_diff <- na.locf(vwap_diff)


### data: lagged returns plus explanatory variables

# for lm reg
# bar <- cbind(lag_rets, coredata(re_turns), pos_skew, neg_skew)
# bar <- cbind(lag_rets, coredata(vwap_diff), pos_skew, neg_skew)
bar <- cbind(re_turns, lag_skew)
bar <- cbind(lag_rets, sign(coredata(vwap_diff)), pos_skew, neg_skew)
# bar <- cbind(sign(lag_rets), sign(coredata(vwap_diff)), pos_skew, neg_skew)
# for logistic reg
bar <- cbind((sign(coredata(lag_rets))+1)/2, sign(coredata(vwap_diff)), pos_skew, neg_skew)
# for lda qda
bar <- cbind(sign(lag_rets), coredata(vwap_diff), pos_skew, neg_skew)
# colnames(bar) <- c("SPY.lagrets", "SPY.rets", "SPY.poskew", "SPY.negskew")
class(bar)
tail(bar)


### lm

# lm formula with zero intercept
for_mula <- as.formula(paste(colnames(bar)[1], paste(paste(colnames(bar)[-1], collapse=" + "), "- 1"), sep="~"))
for_mula <- as.formula(paste(colnames(bar)[1], paste(colnames(bar)[2], "- 1"), sep="~"))

l_m <- lm(for_mula, data=as.data.frame(bar))
# perform regressions over different calendar periods
l_m <- lm(for_mula, data=as.data.frame(bar["2011-01-01/"]))
l_m <- lm(for_mula, data=as.data.frame(bar["/2011-01-01"]))
lm_summ <- summary(l_m)
l_m <- lm(for_mula, data=as.data.frame(bar["2013-02-04/2013-03-05"]))
lm_summ <- summary(l_m)
lm_predict <- predict(l_m, newdata=as.data.frame(bar["2013-03-06"]))
foo <- data.frame(sign(lm_predict), coredata(bar["2013-03-06", 1]))
colnames(foo) <- c("lm_pred", "realized")
table(foo)
cumu_pnl <- cumsum(sign(lm_predict)*re_turns["2013-03-06", 1])
last(cumu_pnl)
chart_Series(cumu_pnl, name=paste(sym_bol, "optim_rets"))

# loop over thresholds and return regression t-values
foo <- sapply(structure(2:10, paste0("thresh", names=2:10)), function(thresh_old) {
  pos_skew <- coredata(ifelse(sk_ew > thresh_old*skew_mad, 1, 0))
  colnames(pos_skew) <- paste(sym_bol, "p_skew", sep=".")
  neg_skew <- coredata(ifelse(sk_ew < -thresh_old*skew_mad, -1, 0))
  colnames(neg_skew) <- paste(sym_bol, "n_skew", sep=".")
  bar <- cbind(sign(lag_rets), sign(coredata(vwap_diff)), pos_skew, neg_skew)
  l_m <- lm(for_mula, data=as.data.frame(bar))
  lm_summ <- summary(l_m)
  lm_summ$coefficients[, "t value"]
}, USE.NAMES=TRUE)  # end sapply


# loop over periods
date_s <- "2013-06-01/"
date_s <- "2008-06-01/2009-06-01"
end_points <- endpoints(get(sym_bol)[date_s], on="days")
end_points <- format(index((get(sym_bol)[date_s])[end_points[-1], ]), "%Y-%m-%d")
win_dow <- 10

position_s <- 
  lapply(win_dow:length(end_points),
         function(end_point) {
           date_s <- paste0(end_points[end_point-win_dow+1], "/", end_points[end_point-1])
           l_m <- lm(for_mula, data=as.data.frame(bar[date_s]))
           da_ta <- bar[end_points[end_point]]
           xts(x=predict(l_m, newdata=as.data.frame(da_ta)), order.by=index(da_ta))
         }  # end anon function
  )  # end lapply
position_s <- do.call(rbind, position_s)
chart_Series(position_s, name=paste(sym_bol, "optim_rets"))

cumu_pnl <- cumsum(sign(position_s)*re_turns[index(position_s), 1])
last(cumu_pnl)
chart_Series(cumu_pnl, name=paste(sym_bol, "optim_rets"))


### logistic reg
library(MASS)
library(ISLR)
library(glmnet)
g_lm <- glm(for_mula, data=as.data.frame(bar), family=binomial)
summary(g_lm)


### lda
l_da <- lda(for_mula, data=as.data.frame(bar))
summary(l_da)
l_da <- lda(for_mula, data=as.data.frame(bar["2013-02-04/2013-03-05"]))
lda_predict <- predict(l_da, newdata=as.data.frame(bar["2013-03-06"]))
foo <- data.frame(lda_predict$class, coredata(bar["2013-03-06", 1]))
colnames(foo) <- c("lda_pred", "realized")
table(foo)


### qda
q_da <- qda(for_mula, data=as.data.frame(bar))
summary(q_da)
date_s <- "2013-02-04/2013-02-06"
q_da <- qda(for_mula, data=as.data.frame(bar["2013-02-04/2013-03-05"]))
date_s <- "2013-02-07"
qda_predict <- predict(q_da, newdata=as.data.frame(bar["2013-03-06"]))
str(qda_predict)
head(qda_predict$class)
tail(qda_predict$class)
length(qda_predict$class)
sum(qda_predict$class!=1)
sum(bar["2013-02-07", 1]!=1)
foo <- data.frame(qda_predict$class, coredata(bar["2013-03-06", 1]))
colnames(foo) <- c("qda_pred", "realized")
table(foo)

# scatterplot of sk_ew and daily_rets
plot(for_mula, data=bar, xlab="skew", ylab="rets")
abline(l_m, col="blue")

cor.test(formula=as.formula(paste("~", paste(colnames(bar), collapse=" + "))), data=as.data.frame(bar))


date_s <- "2013-06-01/"
bar <- cbind(
  coredata(re_turns[date_s, 1]), 
  c(0, coredata(roll_skew[date_s])[-NROW(roll_skew[date_s])]))


# multiply matrix columns
foo <- t(t(coredata(bar[, -1]))*coef(l_m)[-1])
dim(foo)
tail(foo)
apply(foo, MARGIN=2, sum)


### run simple strategy

# thresh_old <- 2*mad(roll_skew)  # signal threshold trading level
# position_s <- NA*numeric(NROW(sk_ew))
position_s <- ifelse((pos_skew!=0) | (neg_skew!=0), 1, sign(coredata(vwap_diff)))
position_s <- ifelse((pos_skew!=0) | (neg_skew!=0), 1, -coredata(re_turns))
position_s <- ifelse((pos_skew!=0) | (neg_skew!=0), 1, sign(coredata(vwap_diff)))
position_s <- pos_skew + neg_skew + sign(coredata(vwap_diff))
position_s <- -sign(sk_ew) + sign(coredata(vwap_diff))
position_s <- coredata(bar[, -1]) %*% coef(l_m)
sum(is.na(position_s))
length(position_s)
head(position_s)
plot(position_s[(length(position_s)-100*win_dow):length(position_s)], t="l", xlab="", ylab="", main="position_s")
plot(position_s, t="l", ylim=c(0, 0.001))

position_s <- ifelse(roll_skew>thresh_old, -1, position_s)
position_s <- ifelse(roll_skew<(-thresh_old), 1, position_s)
position_s <- ifelse((roll_skew*lag(roll_skew))<0, 0, position_s)
# lag the position_s
lag_positions <- c(0, position_s[-length(position_s)])
lag_positions <- na.locf(lag_positions)
lag_positions <- merge(roll_skew, lag_positions)
colnames(lag_positions)[2] <- 
  paste0(sym_bol, ".Position")
# cumulative PnL
cumu_pnl <- cumsum(lag_positions*re_turns)
last(cumu_pnl)
# cumu_pnl <- cumsum(lag_positions[, 2]*re_turns)
plot.zoo(cumu_pnl)
chart_Series(cumu_pnl, name=paste(sym_bol, "pnl"))

foo <- rutils::roll_sum(abs(sign(sk_ew)-sign(lag_skew)), win_dow=1000)
chart_Series(
  foo[endpoints(foo, on="days"), ], 
  name=paste(sym_bol, "contrarian skew strategy frequency of trades"))
# calculate transaction costs
bid_offer <- 0.001  # 10 bps for liquid ETFs
cost_s <- bid_offer*abs(position_s-lag_positions)
pnl_xts[, "pnl"] <- pnl_xts[, "pnl"] - co_sts


### optimize vwap

roll_vwap <- function(win_short=10, win_long=100, price_s, re_turns) {
  vwap_short <- coredata(roll_vwap(oh_lc=price_s, win_dow=win_short))
  vwap_long <- coredata(roll_vwap(oh_lc=price_s, win_dow=win_long))
# lag the position_s
  position_s <- sign(vwap_short - vwap_long)
  position_s <- c(0, position_s[-length(position_s)])
  sum(position_s*re_turns)
}  # end roll_vwap

roll_vwap(price_s=get(sym_bol), re_turns=re_turns)


short_windows <- seq(from=30, to=100, by=10)
names(short_windows) <- paste0("sh", short_windows)
long_windows <- seq(from=200, to=400, by=25)
names(long_windows) <- paste0("lo", long_windows)

mat_rix <- sapply(short_windows,
                  function(win_short, ...)
                    sapply(long_windows,
                           roll_vwap,
                           win_short=win_short, ...),
                  price_s=get(sym_bol), re_turns=re_turns)

# load rgl
library(rgl)
persp3d(z=mat_rix, col="green", x=short_windows, y=long_windows)


####


# seconds index
in_dex <- as.POSIXct("2015-01-01 00:00:00") + 0:1000
in_dex <- seq(from=as.POSIXct("2015-01-01 00:00:00"), 
              to=as.POSIXct("2015-01-03 00:00:00"), by="sec")
head(in_dex)
tail(in_dex)
length(in_dex)

# simulate lognormal prices
foo <- xts(exp(cumsum(rnorm(length(in_dex)))/100), order.by=in_dex)
dim(foo)

# aggregate minutes OHLC bars
bar <- to.period(x=foo, period="minutes", name="synth")
tail(bar)
# OHLC candlechart
chart_Series(x=bar["2015-01-01 01:00:00/2015-01-01 05:00:00"], 
             name="OHLC candlechart")

# rolling volatility
vol_at <- roll_moment(ohlc=bar, win_dow=1000, weight_ed=FALSE)
head(vol_at)
tail(vol_at)
# rolling skew
sk_ew <- roll_moment(ohlc=bar, mo_ment="run_skew", win_dow=1000, weight_ed=FALSE)
sk_ew <- sk_ew/(vol_at)^(1.5)
sk_ew[1, ] <- 0
sk_ew <- na.locf(sk_ew)
chart_Series(x=vol_at, name="volatility")
chart_Series(x=sk_ew, name="skew")


####

mat_rix <- matrix(1:6, ncol=2)

foo <- etf_rets[, sym_bols]
head(foo)
NROW(etf_rets)

foo <- xts(matrix(rnorm(3*NROW(etf_rets)), ncol=3), order.by=index(etf_rets))

colnames(foo) <- colnames(etf_rets[, sym_bols])
head(foo)

ann_weights <- sapply(2:length(end_points), 
                      function(in_dex) {
                        optim_portf(
                          portf_rets=foo, 
                          start_point=end_points[in_dex-1], 
                          end_point=end_points[in_dex])
                      }  # end anon function
)  # end sapply


colnames(ann_weights) <- format(index(foo[end_points[-1]]), "%Y")

ann_weights <- t(ann_weights)


bar <- lapply(3:length(end_points),
              function(in_dex) {
                foo[end_points[in_dex-1]:end_points[in_dex], ] %*% 
                  c(1, ann_weights[in_dex-2, ])
              }  # end anon function
)  # end lapply

bar <- do.call(rbind, bar)

plot(cumsum(bar), t="l")


### sprintf() example scripts
# A wrapper for the C function sprintf, that returns a character vector containing a formatted combination of text and variable values.
# sprintf {base}	R Documentation
# Use C-style String Formatting Commands

sprintf(fmt="%f", foo[1])

# use a literal % :
sprintf("%.0f%% said yes (out of a sample of size %.0f)", 66.666, 3)

# various formats of pi :
# re-use one argument three times, show difference between %x and %X
xx <- sprintf("%1$d %1$x %1$X", 0:15)
xx <- matrix(xx, dimnames=list(rep("", 16), "%d%x%X"))
noquote(format(xx, justify="right"))

# More sophisticated:

sprintf("min 10-char string '%10s'",
        c("a", "ABC", "and an even longer one"))

# Platform-dependent bad example from qdapTools 1.0.0:
# may pad with spaces or zeroes.
sprintf("%09s", month.name)

n <- 1:18
sprintf(paste0("e with %2d digits = %.", n, "g"), n, exp(1))

# Using arguments out of order
sprintf("second %2$1.0f, first %1$5.2f, third %3$1.0f", pi, 2, 3)

# Using asterisk for width or precision
sprintf("precision %.*f, width '%*.3f'", 3, pi, 8, pi)

# Asterisk and argument re-use, 'e' example reiterated:
sprintf("e with %1$2d digits = %2$.*1$g", n, exp(1))

# re-cycle arguments
sprintf("%s %d", "test", 1:3)

# binary output showing rounding/representation errors
x <- seq(0, 1.0, 0.1); y <- c(0,.1,.2,.3,.4,.5,.6,.7,.8,.9,1)
cbind(x, sprintf("%a", x), sprintf("%a", y))



###

# measure of dispersion
dis_persion <- function(da_ta, 
                        meth_od=c("mean", "mean_narm", "median")) {
  # validate "meth_od" argument
  meth_od <- match.arg(meth_od)
  switch(meth_od,
         mean=mean(da_ta),
         mean_narm=mean(da_ta, na.rm=TRUE),
         median=median(da_ta))
}  # end dis_persion

# sd
# range
# Interquartile range
# Median absolute deviation (MAD)


### rolling regressions using package roll

library(HighFreq)
library(roll)

# example of rolling beta regressions
# specify regression formula
reg_formula <- XLP ~ VTI
# perform rolling beta regressions every month
beta_s <- rollapply(env_etf$re_turns, width=252, 
                    FUN=function(design_matrix) 
                      coef(lm(reg_formula, data=design_matrix))[2],
                    by=22, by.column=FALSE, align="right")
beta_s <- na.omit(beta_s)
# plot beta_s in x11() window
x11()
chart_Series(x=beta_s, name=paste("rolling betas", format(reg_formula)))

# perform daily rolling beta regressions in parallel
beta_s <- roll::roll_lm(x=env_etf$re_turns[, "VTI"], 
                  y=env_etf$re_turns[, "XLP"],
                  width=252)$coefficients
chart_Series(x=beta_s, name=paste("rolling betas", format(reg_formula)))

# compare speed of rollapply() versus roll_lm()
library(microbenchmark)
da_ta <- env_etf$re_turns["2012", c("VTI", "XLP")]
summary(microbenchmark(
  rollapply=rollapply(da_ta, width=22, 
                      FUN=function(design_matrix) 
                        coef(lm(reg_formula, data=design_matrix))[2],
                      by.column=FALSE, align="right"), 
  roll_lm=roll::roll_lm(x=da_ta[, "VTI"], 
                  y=da_ta[, "XLP"],
                  width=22)$coefficients, 
  times=10))[, c(1, 4, 5)]  # end microbenchmark summary


### load SPY_design design matrix 

# load design matrix called SPY_design containing columns of aggregations
load("C:/Develop/data/SPY_design.RData")
head(SPY_design)

# create advanced returns
returns_running <- SPY_design[, "returns"]
returns_advanced <- rutils::lag_xts(returns_running, k=-1)
colnames(returns_advanced) <- "returns_advanced"
tail(cbind(returns_advanced, returns_running))


### SPY_design correlation and PCA analysis

# apply rolling centering and scaling of design matrix
SPY_design <- roll::roll_scale(data=SPY_design, width=6.5*60, min_obs=1)
# remove NAs
core_data <- coredata(SPY_design)
core_data[is.na(core_data)] <- 0
SPY_design <- xts(x=core_data, order.by=index(SPY_design))
sum(is.na(SPY_design))

# calculate correlation matrix
corr_matrix <- cor(SPY_design)
colnames(corr_matrix) <- colnames(SPY_design)
rownames(corr_matrix) <- colnames(SPY_design)
# Reorder the correlation matrix based on clusters
# Calculate permutation vector
library(corrplot)
corr_order <- corrMatOrder(corr_matrix, 
                           order="hclust", 
                           hclust.method="complete")
# Apply permutation vector
corr_matrix_ordered <- corr_matrix[corr_order, corr_order]
# Plot the correlation matrix
col3 <- colorRampPalette(c("red", "white", "blue"))
corrplot(corr_matrix_ordered, 
         tl.col="black", tl.cex=0.8, 
         method="square", col=col3(8), 
         cl.offset=0.75, cl.cex=0.7, 
         cl.align.text="l", cl.ratio=0.25)
# Draw rectangles on the correlation matrix plot
corrRect.hclust(corr_matrix_ordered, 
                k=NCOL(corr_matrix_ordered), 
                method="complete", col="red")

# draw dendrogram of correlation matrix
# convert correlation matrix into distance object
data_dist <- as.dist(1-corr_matrix_ordered)
# Perform hierarchical clustering analysis
data_cluster <- hclust(data_dist)
plot(data_cluster, ann=FALSE, xlab="", ylab="")
title("Dissimilarity = 1-Correlation", line=-0.5)


### rolling regressions over SPY_design using package roll

# perform rolling forecasting regressions in parallel
rolling_betas <- roll_lm(x=SPY_design["2011/2012", ], 
                  y=returns_advanced["2011/2012", ],
                  width=6.5*60, min_obs=1)
rolling_betas$coefficients[1, ] <- 0
sum(is.na(rolling_betas$coefficients))
head(rolling_betas$coefficients)
tail(rolling_betas$coefficients["2012-11-12"])
tail(rolling_betas$r.squared["2012-11-12"])
chart_Series(x=rolling_betas$r.squared["2012-11-12"], name="R-squared for rolling betas")

# calculate daily seasonality of R2
# remove first day containing warmup
in_dex <- "2011-01-03" == format(index(rolling_betas$r.squared), "%Y-%m-%d")
r2_seasonal <- season_ality(rolling_betas$r.squared[!in_dex])
colnames(r2_seasonal) <- "R-squared seasonality"
chart_Series(x=r2_seasonal, name="R-squared seasonality")

# plot coefficients with custom line colors
plot_theme <- chart_theme()
plot_theme$col$line.col <- rainbow(NCOL(rolling_betas$coefficients))
chart_Series(x=rolling_betas$coefficients["2012-11-12"], 
             theme=plot_theme, 
             name="coefficients for rolling betas")
legend("bottom", legend=colnames(rolling_betas$coefficients["2012-11-12"]), 
       bg="white", lty=c(1, 1), lwd=c(2, 2), 
       col=plot_theme$col$line.col, bty="n")


### rolling principal component regressions (PCR) over SPY_design using package roll

# perform rolling forecasting PCR regressions in parallel
# use only the first principal component argument "comps"
rolling_betas <- roll_pcr(x=SPY_design["2011/2012", ], 
                         y=returns_advanced["2011/2012", ],
                         width=1*60, comps=1:1, min_obs=1)
rolling_betas$coefficients[1, ] <- 0
sum(is.na(rolling_betas$coefficients))
head(rolling_betas$coefficients)
tail(rolling_betas$coefficients["2012-11-12"])
tail(rolling_betas$r.squared["2012-11-12"])
chart_Series(x=rolling_betas$r.squared["2012-11-12"], name="R-squared for rolling betas")

# calculate daily seasonality of R2
# remove first day containing warmup
in_dex <- "2011-01-03" == format(index(rolling_betas$r.squared), "%Y-%m-%d")
r2_seasonal <- season_ality(rolling_betas$r.squared[!in_dex])
colnames(r2_seasonal) <- "R-squared seasonality"
chart_Series(x=r2_seasonal, name="R-squared seasonality")

# plot coefficients with custom line colors
plot_theme <- chart_theme()
plot_theme$col$line.col <- rainbow(NCOL(rolling_betas$coefficients))
chart_Series(x=rolling_betas$coefficients["2012-11-12"], 
             theme=plot_theme, 
             name="coefficients for rolling betas")
legend("bottom", legend=colnames(rolling_betas$coefficients["2012-11-12"]), 
       bg="white", lty=c(1, 1), lwd=c(2, 2), 
       col=plot_theme$col$line.col, bty="n")


### calculate forecasts of returns

library(matrixStats)

# forecast the returns from today's factors times the lagged betas
betas_lagged <- rutils::lag_xts(rolling_betas$coefficients)
returns_forecast <- rowSums(betas_lagged[, -1]*SPY_design[index(rolling_betas$coefficients)]) + betas_lagged[, 1]
tail(returns_forecast)

forecast_lm <- lm(returns_advanced[index(returns_forecast)] ~ returns_forecast)
summary(forecast_lm)
x11()
# scatterplot
plot(coredata(returns_advanced[index(returns_forecast)]), coredata(returns_forecast))

# cumulative returns_backtest: invest proportional to returns_forecast
returns_backtest <- cumsum(returns_forecast * returns_advanced[index(returns_forecast)])
chart_Series(x=-returns_backtest, name="cumulative returns")
chart_Series(x=-returns_backtest["2011-08-07/2011-08-12"], name="cumulative returns")
chart_Series(x=SPY["2011-08-07/2011-08-12", 1], name="cumulative returns")

bar <- returns_advanced[index(returns_forecast)] * returns_forecast
foo <- which.max(-bar)
chart_Series(x=bar[(foo-10):(foo+10), ], name="cumulative returns")

chart_Series(x=cumsum(returns_running[(foo-1000):(foo+1000), ]), name="cumulative returns")



### test for data snooping in PCR using random data

# create time index of one second intervals
in_dex <- seq(from=as.POSIXct("2016-01-01 00:00:00"),
              to=as.POSIXct("2016-01-30 00:00:00"), by="1 sec")

# perform one random PCR simulation using function run_random_pcr()
run_random_pcr(in_dex)

# perform 100 random PCR simulations
pnl_s <- sapply(1:100, function(x, in_dex) run_random_pcr(in_dex), in_dex=in_dex)
hist(pnl_s, breaks="FD", xlim=c(-5e4, 5e4), main="distribution of Pnl's")

# perform a random PCR and return the Pnl
run_random_pcr <- function(in_dex) {
  x_ts <- xts(exp(cumsum(rnorm(length(in_dex), sd=0.001))), order.by=in_dex)
  oh_lc <- xts::to.period(x=x_ts, period="minutes", name="random")
  oh_lc <- cbind(oh_lc, sample(x=10*(2:18), size=NROW(oh_lc), replace=TRUE))
  colnames(oh_lc)[ 5] <- "random.volume"
  returns_running <- run_returns(x_ts=oh_lc)
  returns_advanced <- rutils::lag_xts(returns_running, k=-1)
  returns_rolling <- roll_vwap(oh_lc=oh_lc, x_ts=returns_running, win_dow=win_dow)
  var_running <- run_variance(oh_lc=oh_lc)
  skew_running <- run_skew(oh_lc=oh_lc)
  hurst_rolling <- roll_hurst(oh_lc=oh_lc, win_dow=win_dow)
  design_matrix <- cbind(returns_running, returns_rolling, var_running, skew_running, hurst_rolling, returns_running*var_running, returns_running*skew_running)
  design_matrix <- roll::roll_scale(data=design_matrix, width=60, min_obs=1)
  core_data <- coredata(design_matrix)
  core_data[is.na(core_data)] <- 0
  design_matrix <- xts(x=core_data, order.by=index(design_matrix))
  rolling_betas <- roll_pcr(x=design_matrix, y=returns_advanced, width=1*60, comps=1:1, min_obs=1)
  rolling_betas$coefficients[1, ] <- 0
  betas_lagged <- rutils::lag_xts(rolling_betas$coefficients)
  returns_forecast <- rowSums(betas_lagged[, -1]*design_matrix[index(rolling_betas$coefficients)]) + betas_lagged[, 1]
  sum(returns_forecast * returns_advanced[index(returns_forecast)])
}  # end run_random_pcr


# create xts of random prices
x_ts <- xts(exp(cumsum(rnorm(length(in_dex), sd=0.001))), order.by=in_dex)
colnames(x_ts) <- "random"
# chart_Series(x=x_ts["2016-01-10 09/2016-01-10 10"], name="random prices")
# aggregate to minutes OHLC data
oh_lc <- xts::to.period(x=x_ts, period="minutes", name="random")
# chart_Series(x=oh_lc["2016-01-10"], name="random OHLC prices")
# add volume
oh_lc <- cbind(oh_lc, sample(x=10*(2:18), size=NROW(oh_lc), replace=TRUE))
colnames(oh_lc)[ 5] <- "random.volume"
# tail(oh_lc)

# create SPY_design
SPY <- oh_lc
returns_running <- run_returns(x_ts=SPY)
returns_advanced <- rutils::lag_xts(returns_running, k=-1)
colnames(returns_advanced) <- "returns_advanced"
returns_rolling <- roll_vwap(oh_lc=SPY, x_ts=returns_running, win_dow=win_dow)
colnames(returns_running) <- "returns"
colnames(returns_rolling) <- "returns.WA5"
var_running <- run_variance(oh_lc=SPY)
colnames(var_running) <- "variance"
skew_running <- run_skew(oh_lc=SPY)
colnames(skew_running) <- "skew"
hurst_rolling <- roll_hurst(oh_lc=SPY, win_dow=win_dow)
colnames(hurst_rolling) <- "hurst"
SPY_design <- cbind(returns_running, returns_rolling, var_running, skew_running, hurst_rolling, returns_running*var_running, returns_running*skew_running)
colnames(SPY_design) <- c(colnames(SPY_design)[1:5], "rets_var", "rets_skew")

# scale SPY_design
SPY_design <- roll::roll_scale(data=SPY_design, width=60, min_obs=1)
core_data <- coredata(SPY_design)
core_data[is.na(core_data)] <- 0
SPY_design <- xts(x=core_data, order.by=index(SPY_design))

# perform PCR
rolling_betas <- roll_pcr(x=SPY_design, y=returns_advanced, width=1*60, comps=1:1, min_obs=1)
rolling_betas$coefficients[1, ] <- 0
betas_lagged <- rutils::lag_xts(rolling_betas$coefficients)
returns_forecast <- rowSums(betas_lagged[, -1]*SPY_design[index(rolling_betas$coefficients)]) + betas_lagged[, 1]

# forecast_lm <- lm(returns_advanced[index(returns_forecast)] ~ returns_forecast)
# summary(forecast_lm)

returns_backtest <- cumsum(returns_forecast * returns_advanced[index(returns_forecast)])
chart_Series(x=-returns_backtest, name="cumulative returns")



### rollSFM (rolling single-factor model) function to TTR

# rolling regression over time index
reg <- rollSFM(demo.xts, .index(demo.xts), 24)
rma <- reg$alpha + reg$beta*.index(demo.xts)
chart_Series(demo.xts, TA="add_TA(rma,on=1)")



###  Forecastable Component Analysis
library(ForeCA)
ret <- ts(diff(log(EuStockMarkets)) * 100) 
mod <- foreca(ret, spectrum.control=list(method="wosa"))
mod
summary(mod)
plot(mod)

