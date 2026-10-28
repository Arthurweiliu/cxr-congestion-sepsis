setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/film_analysis.csv")
d <- read.csv("data/diuretic_by_stay.csv")[, c("stay_id","film_offset_h")]
f$off <- d$film_offset_h[match(f$stay_id, d$stay_id)]
cat("missing offset:", sum(is.na(f$off)), "\n")

run <- function(dat, label) {
  cat("\n==", label, "n =", nrow(dat), "deaths =", sum(dat$death30), "==\n")
  v <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
  imp <- mice(dat[, v], m = 20, printFlag = FALSE)
  fits <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = complete(imp,i), family = binomial))
  B <- sapply(fits, coef); b <- rowMeans(B); T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se <- sqrt(diag(T))
  for (t in c("grpB","grpC","grpD")) cat(sprintf("  %s %.2f (%.2f-%.2f)\n", t, exp(b[t]), exp(b[t]-1.96*se[t]), exp(b[t]+1.96*se[t])))
}
run(f[!is.na(f$off) & f$off < 0, ], "film BEFORE ICU admission (truncated window)")
run(f[!is.na(f$off) & f$off >= 0, ], "film AT/AFTER ICU admission (untruncated window)")
