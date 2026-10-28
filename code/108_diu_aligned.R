setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/film_analysis.csv")
d <- read.csv("data/diu_film72.csv")
f$diu72 <- d$diu_film72[match(f$stay_id, d$stay_id)]
f$diu72[is.na(f$diu72)] <- 0
cat("n =", nrow(f), "\n")
for (g in c("A","B","C","D")) {
  s <- f[f$grp == g, ]
  cat(sprintf("%s %d/%d = %.1f%%\n", g, sum(s$diu72), nrow(s), 100*mean(s$diu72)))
}
vars <- c("diu72","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(diu72 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = complete(imp,i), family = binomial))
B <- sapply(fits, coef); b <- rowMeans(B); T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se <- sqrt(diag(T))
cat(sprintf("adjusted OR C vs A: %.2f (%.2f-%.2f)\n", exp(b["grpC"]), exp(b["grpC"]-1.96*se["grpC"]), exp(b["grpC"]+1.96*se["grpC"])))
