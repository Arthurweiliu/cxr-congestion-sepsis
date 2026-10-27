setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/base.csv", stringsAsFactors=FALSE)
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30),]
cat("median FB by cong:\n"); print(round(tapply(a$fb72_mlkg, a$cong_hybrid, median),1))
cat("IQR by cong:\n"); print(round(tapply(a$fb72_mlkg, a$cong_hybrid, quantile, c(.25,.75)),1))
cat("death90 overall %:", round(100*mean(a$death90,na.rm=TRUE),1), "\n")
cat("hf % in cong+:", round(100*mean(a$hf[a$cong_hybrid==1]),1), " cong-:", round(100*mean(a$hf[a$cong_hybrid==0]),1), "\n")
