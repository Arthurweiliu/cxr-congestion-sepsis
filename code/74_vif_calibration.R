setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(car))
f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
f$fb10 <- f$fb72_mlkg/10
vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
d <- f[complete.cases(f[, vars]), ]
m <- glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = d, family = binomial)
v <- car::vif(m)
cat("VIF:\n"); print(round(v, 2))
cat("max VIF:", round(max(v), 2), "\n")

# Hosmer-Lemeshow (10 groups)
p <- fitted(m); y <- d$death30
q <- cut(p, quantile(p, 0:10/10), include.lowest = TRUE, labels = FALSE)
obs <- tapply(y, q, sum); exp <- tapply(p, q, sum); n <- tapply(y, q, length)
hl <- sum((obs - exp)^2 / (exp * (1 - exp/n)))
cat(sprintf("Hosmer-Lemeshow chi2 = %.2f, df = 8, p = %.3f\n", hl, pchisq(hl, 8, lower.tail = FALSE)))
cat(sprintf("n complete = %d, events = %d\n", nrow(d), sum(y)))
