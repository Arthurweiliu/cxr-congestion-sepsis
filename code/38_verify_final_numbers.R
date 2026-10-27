setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$female <- as.integer(f$gender == "F")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

## 1. IPW on final cohort
b <- read.csv("data/base.csv", stringsAsFactors = FALSE)
b$female <- as.integer(b$gender == "F")
b$has_film <- b$has_film %in% c("t","TRUE","True",TRUE)
sel <- glm(has_film ~ age + female + sofa_score + vent24 + vaso24 + hf + ckd, data = b, family = binomial)
b$psel <- fitted(sel)
f$psel <- b$psel[match(f$stay_id, b$stay_id)]
f$w <- 1 / f$psel
f$w <- pmin(f$w, quantile(f$w, 0.99))
f$w <- f$w / mean(f$w)

cc <- f[complete.cases(f[, c("death30","grp","age","female","sofa_score","vent24","vaso24","hf","ckd")]), ]
mw <- glm(death30 ~ grp + age + female + sofa_score + vent24 + vaso24 + hf + ckd,
          data = cc, family = binomial, weights = w)
ow <- exp(cbind(coef(mw), confint.default(mw)))
cat("=== IPW on final cohort (n =", nrow(cc), ") ===\n")
print(round(ow[grep("^grp", rownames(ow)), ], 3))

## 2. Interaction on final cohort (complete case)
f$fb10 <- f$fb72_mlkg / 10
ci <- f[complete.cases(f[, c("death30","cong_hybrid","fb10","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
mi <- glm(death30 ~ cong_hybrid * fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
          data = ci, family = binomial)
oi <- exp(cbind(coef(mi), confint.default(mi)))
cat("\n=== interaction on final cohort (n =", nrow(ci), ") ===\n")
for (v in c("cong_hybrid","fb10","cong_hybrid:fb10")) {
  cat(sprintf("%-20s %.3f (%.3f-%.3f) p=%.3f\n", v, oi[v,1], oi[v,2], oi[v,3], summary(mi)$coefficients[v,4]))
}

## 3. unknown group age
u <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
cat("\nmedian age  known:", median(f$age), " unknown:", median(u$age[u$cong_hybrid |> is.na()]), "\n")
cat("median age  C:", median(f$age[f$grp=="C"]), " A:", median(f$age[f$grp=="A"]), "\n")
