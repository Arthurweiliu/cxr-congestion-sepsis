setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$dt <- as.POSIXct(ifelse(f$deathtime %in% c("", NA), NA, f$deathtime), tz = "UTC")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
alive <- is.na(f$dt) | f$dt > f$intime + 3*86400
cat("alive at 72h:", sum(alive), "of", nrow(f), "\n")
d <- f[alive, ]
d$death72p <- as.integer(ifelse(!is.na(d$dt), 1, 0) & d$death30 == 1)

dd <- data.frame(death30 = d$death30, grp = d$grp, age = d$age, female = d$female,
                 sofa = d$sofa_score, lac = d$lac, vent = d$vent24, vaso = d$vaso24,
                 hf = d$hf, ckd = d$ckd)
imp <- mice(dd, m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                     data = complete(imp, i), family = binomial))
B <- sapply(fits, coef); bb <- rowMeans(B)
se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/20 + (1 + 1/20)*cov(t(B))))
idx <- grep("^grp", names(bb))
cat(sprintf("N=%d deaths=%d\n", nrow(dd), sum(dd$death30)))
for (i in idx) cat(sprintf("%s: %.2f (%.2f-%.2f)\n", names(bb)[i], exp(bb[i]), exp(bb[i]-1.96*se[i]), exp(bb[i]+1.96*se[i])))
