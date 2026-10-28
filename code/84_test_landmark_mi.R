setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
f <- read.csv("data/film_analysis.csv")
f$intime <- as.POSIXct(f$intime, tz = "UTC")
t72 <- f$intime + 3*86400
dt <- suppressWarnings(as.POSIXct(ifelse(is.na(f$deathtime) | f$deathtime == "", NA, f$deathtime), tz = "UTC"))
alive <- is.na(dt) | dt > t72
sub <- f[alive, ]
cat("subset n =", nrow(sub), " deaths =", sum(sub$death30), "\n")

runMI <- function(dat, lacvar = "lac", m = 20, seed = 20261023) {
  dd <- data.frame(death30 = dat$death30, grp = dat$grp, age = dat$age,
                   female = dat$female, sofa = dat$sofa_score, lac = dat[[lacvar]],
                   vent = dat$vent24, vaso = dat$vaso24, hf = dat$hf, ckd = dat$ckd)
  imp <- mice(dd, m = m, printFlag = FALSE, seed = seed)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B)
  se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))))
  data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb - 1.96*se), ucl = exp(bb + 1.96*se))
}
set.seed(20261023)
r <- runMI(sub)
print(r[r$term %in% c("grpB","grpC","grpD"), ], digits = 3, row.names = FALSE)

# check per-imputation max |coef| for grpC
dd <- data.frame(death30 = sub$death30, grp = sub$grp, age = sub$age, female = sub$female,
                 sofa = sub$sofa_score, lac = sub$lac, vent = sub$vent24, vaso = sub$vaso24,
                 hf = sub$hf, ckd = sub$ckd)
imp <- mice(dd, m = 20, printFlag = FALSE, seed = 20261023)
mc <- sapply(1:20, function(i) coef(glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                        data = complete(imp, i), family = binomial))["grpC"])
print(round(mc, 3))
