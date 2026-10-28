setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)
f <- read.csv("data/film_analysis.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
d <- read.csv("data/diuretic_by_stay.csv")[, c("stay_id","film_offset_h")]
f$off <- d$film_offset_h[match(f$stay_id, d$stay_id)]
f$trunc <- factor(ifelse(f$off < 0, "trunc", "full"), levels = c("full","trunc"))
cat("trunc:", sum(f$trunc == "trunc"), " full:", sum(f$trunc == "full"), " NA:", sum(is.na(f$trunc)), "\n")
vars <- c("death30","grp","trunc","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(death30 ~ grp * trunc + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                     data = complete(imp, i), family = binomial))
B <- sapply(fits, coef); b <- rowMeans(B)
T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se <- sqrt(diag(T))
it <- grep(":", names(b), value = TRUE)
cat("interaction terms:", paste(it, collapse=", "), "\n")
cat("individual:\n")
for (t in it) cat(sprintf("  %s %.2f (%.2f-%.2f) p=%.3f\n", t, exp(b[t]), exp(b[t]-1.96*se[t]), exp(b[t]+1.96*se[t]), 2*pnorm(-abs(b[t]/se[t]))))
idx <- which(names(b) %in% it)
W <- as.numeric(t(b[idx]) %*% solve(T[idx, idx]) %*% b[idx])
cat(sprintf("joint interaction chi2=%.2f df=%d p=%.3f\n", W, length(idx), pchisq(W, length(idx), lower.tail = FALSE)))

# CheXpert labels among reports that never described the lungs (unknown set)
u <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
cat("\nunknown set n:", nrow(u), "\n")
if ("chex_edema" %in% names(u)) { cat("chex_edema table:\n"); print(table(u$chex_edema, useNA = "ifany")) }
if ("cls_imp" %in% names(u)) { cat("cls_imp table:\n"); print(table(u$cls_imp, useNA = "ifany")) }
