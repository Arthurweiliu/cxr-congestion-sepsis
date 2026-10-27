## 66_v4_table2_addon.R — 与主稿 Table 2 同一插补集，追加"校正连续平衡"一列
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
f$fb10 <- f$fb72_mlkg / 10
vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
dat <- f[, vars]
imp <- mice(dat, m = 20, printFlag = FALSE)

pool <- function(fits) {
  B <- sapply(fits, coef); b <- rowMeans(B)
  W <- Reduce("+", lapply(fits, vcov))/length(fits)
  T <- W + (1 + 1/length(fits))*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term = names(b), OR = exp(b), lcl = exp(b-1.96*se), ucl = exp(b+1.96*se),
             p = 2*pnorm(-abs(b/se)), row.names = NULL)
}
fits1 <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                      data = complete(imp, i), family = binomial))
fits2 <- lapply(1:20, function(i) glm(death30 ~ grp + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                      data = cbind(complete(imp, i), fb10 = f$fb10), family = binomial))
p1 <- pool(fits1); p2 <- pool(fits2)
cat("== main (reproduction) ==\n"); print(p1[p1$term %in% c("grpB","grpC","grpD"), ], digits = 3, row.names = FALSE)
cat("\n== + continuous 72-h balance ==\n"); print(p2[p2$term %in% c("grpB","grpC","grpD","fb10"), ], digits = 3, row.names = FALSE)

mk <- function(p, terms) {
  t <- p[p$term %in% terms, ]
  sprintf("%.2f (%.2f-%.2f)", t$OR, t$lcl, t$ucl)
}
L <- c("# Table 2 (extended). Adjusted association with 30-day mortality", "",
       sprintf("Multiple imputation (m=20, seed 20261023); n = %d, deaths = %d", nrow(dat), sum(dat$death30)), "",
       "| Variable | OR (95% CI), base model | OR (95% CI), + continuous balance |", "|---|---|---|",
       sprintf("| Group B | %s | %s |", mk(p1,"grpB"), mk(p2,"grpB")),
       sprintf("| Group C | %s | %s |", mk(p1,"grpC"), mk(p2,"grpC")),
       sprintf("| Group D | %s | %s |", mk(p1,"grpD"), mk(p2,"grpD")),
       sprintf("| 72-h balance, per 10 mL/kg | — | %s |", mk(p2,"fb10")),
       "", "Covariates as in Table 2: age, sex, SOFA, lactate, invasive ventilation, vasopressors, heart failure, chronic kidney disease.")
writeLines(enc2utf8(L), "v4/Table2_extended.md")
saveRDS(list(p1=p1,p2=p2), "v4/table2_addon.rds")
cat("\nwritten v4/Table2_extended.md\n")
