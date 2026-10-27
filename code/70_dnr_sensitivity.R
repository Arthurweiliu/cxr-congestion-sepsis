## 70_dnr_sensitivity.R — code status（DNR/DNI/CMO）敏感性分析
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
f$fb10 <- f$fb72_mlkg/10

cs <- read.csv("data/code_status.csv")
cs <- cs[, c("stay_id","dnr_any","dnr_24h","n_records")]
f <- merge(f, cs, by = "stay_id", all.x = TRUE)
f$dnr_any[is.na(f$dnr_any)] <- 0
f$dnr_24h[is.na(f$dnr_24h)] <- 0
f$has_record <- as.integer(!is.na(f$n_records) & f$n_records > 0)

cat("N =", nrow(f), "\n")
cat("any code-status record :", sum(f$has_record), sprintf("(%.1f%%)\n", 100*mean(f$has_record)))
cat("any limitation (DNR/DNI/CMO):", sum(f$dnr_any), sprintf("(%.1f%%)\n", 100*mean(f$dnr_any)))
cat("limitation within 24 h     :", sum(f$dnr_24h), sprintf("(%.1f%%)\n", 100*mean(f$dnr_24h)))
cat("\nby group (%):\n")
print(round(100*rbind(any=tapply(f$dnr_any, f$grp, mean), h24=tapply(f$dnr_24h, f$grp, mean),
                      deaths=tapply(f$death30, f$grp, mean)), 1))
cat("\nmortality by limitation (within 24 h):\n")
print(round(100*tapply(f$death30, f$dnr_24h, mean), 1)); print(table(f$dnr_24h))

vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd","dnr_24h")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
bases <- lapply(1:20, function(i) { d <- complete(imp, i); d$fb10 <- f$fb10; d$dnr_any <- f$dnr_any; d })

pool <- function(fits) {
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1+1/length(fits))*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term=names(b), OR=exp(b), lcl=exp(b-1.96*se), ucl=exp(b+1.96*se), p=2*pnorm(-abs(b/se)), row.names=NULL)
}
c0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
m1 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp + dnr_24h +", c0)), data=d, family=binomial)))
m2 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp + dnr_24h + fb10 +", c0)), data=d, family=binomial)))
m3 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp + dnr_any +", c0)), data=d, family=binomial)))

show <- function(m, t) { r <- m[m$term %in% t, c("term","OR","lcl","ucl","p")]; print(r, digits=3, row.names=FALSE) }
cat("\n== + code status (24 h) ==\n"); show(m1, c("grpB","grpC","grpD","dnr_24h"))
cat("\n== + code status (24 h) + continuous balance ==\n"); show(m2, c("grpB","grpC","grpD","dnr_24h","fb10"))
cat("\n== + any limitation (whole stay; not tabulated) ==\n"); show(m3, c("grpB","grpC","grpD","dnr_any"))

fmt <- function(m, t) sprintf("%.2f (%.2f-%.2f)", m$OR[m$term==t], m$lcl[m$term==t], m$ucl[m$term==t])
L <- c("# Table S5. Sensitivity analysis with documented limitation of treatment", "",
  sprintf("n = %d. A DNR/DNI or comfort-measures order was charted within 24 h of ICU admission in %d patients (%.1f%%).",
          nrow(f), sum(f$dnr_24h), 100*mean(f$dnr_24h)), "",
  "| Documented limitation within 24 h, by group | A | B | C | D |", "|---|---:|---:|---:|---:|",
  sprintf("| n (%% of group) | %d (%.1f) | %d (%.1f) | %d (%.1f) | %d (%.1f) |",
    sum(f$dnr_24h[f$grp=="A"]), 100*mean(f$dnr_24h[f$grp=="A"]),
    sum(f$dnr_24h[f$grp=="B"]), 100*mean(f$dnr_24h[f$grp=="B"]),
    sum(f$dnr_24h[f$grp=="C"]), 100*mean(f$dnr_24h[f$grp=="C"]),
    sum(f$dnr_24h[f$grp=="D"]), 100*mean(f$dnr_24h[f$grp=="D"])), "",
  "| Variable | + limitation (24 h) | + limitation (24 h) + continuous balance |", "|---|---|---|",
  sprintf("| Group B | %s | %s |", fmt(m1,"grpB"), fmt(m2,"grpB")),
  sprintf("| Group C | %s | %s |", fmt(m1,"grpC"), fmt(m2,"grpC")),
  sprintf("| Group D | %s | %s |", fmt(m1,"grpD"), fmt(m2,"grpD")),
  sprintf("| Documented limitation | %s | %s |", fmt(m1,"dnr_24h"), fmt(m2,"dnr_24h")),
  sprintf("| 72-h balance, per 10 mL/kg | - | %s |", fmt(m2,"fb10")),
  "", "Covariates as in Table 2. Code status was taken from charted values of itemid 223758/228687.",
  "Only status documented within the first 24 h is used; a limitation charted later in the stay is not adjusted for, because it is post-baseline.")
writeLines(enc2utf8(L), "v4/Table_S5_code_status.md")
cat("\nwritten v4/Table_S5_code_status.md\n")
cat(sprintf("\nwhole-stay (not tabulated): C %s, D %s, limitation OR %s\n", fmt(m3,"grpC"), fmt(m3,"grpD"), fmt(m3,"dnr_any")))
