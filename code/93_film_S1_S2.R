setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)
f <- read.csv("data/film_analysis.csv")
f$female <- as.integer(f$gender == "F")
f$cong <- as.integer(f$cong_hybrid); f$fb <- f$fb72_mlkg
f$grp <- factor(ifelse(f$cong==1, ifelse(f$fb>0,"D","C"), ifelse(f$fb>0,"B","A")), levels=c("A","B","C","D"))

# One imputation set, identical to the frame used for Table 2, shared by all three
# specifications so that only the comorbidity terms differ across models.
dd <- data.frame(death30 = f$death30, grp = f$grp, age = f$age, female = f$female,
                 sofa_score = f$sofa_score, lac = f$lac, vent24 = f$vent24,
                 vaso24 = f$vaso24, hf = f$hf, ckd = f$ckd)
imp <- mice(dd, m = 20, printFlag = FALSE)

poolFit <- function(rhs, outcome = "death30") {
  fits <- lapply(1:20, function(i) {
    d <- complete(imp, i)
    d$cci <- f$cci
    d$death90 <- f$death90
    glm(as.formula(paste(outcome, "~", rhs)), data = d, family = binomial)
  })
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term = names(b), OR = exp(b), lcl = exp(b-1.96*se), ucl = exp(b+1.96*se))
}
fmt <- function(r,t) sprintf("%.2f (%.2f–%.2f)", r$OR[r$term==t], r$lcl[r$term==t], r$ucl[r$term==t])

m1 <- poolFit("grp + age + female + sofa_score + lac + vent24 + vaso24 + cci + hf + ckd")
m2 <- poolFit("grp + age + female + sofa_score + lac + vent24 + vaso24 + cci")
m3 <- poolFit("grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd")
d90 <- poolFit("grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd", "death90")

L1 <- c("# Table S1. Model specification and secondary outcomes", "",
  "Film-anchored exposure. Multiple imputation (m = 20); one imputation set shared across models; only the comorbidity terms differ.", "",
  "**30-day mortality**", "", "| Model | Group B | Group C | Group D |", "|---|---|---|---|",
  sprintf("| M1: Charlson index + heart failure + CKD | %s | %s | %s |", fmt(m1,"grpB"), fmt(m1,"grpC"), fmt(m1,"grpD")),
  sprintf("| M2: Charlson index only | %s | %s | %s |", fmt(m2,"grpB"), fmt(m2,"grpC"), fmt(m2,"grpD")),
  sprintf("| M3: individual comorbidities only (primary) | %s | %s | %s |", fmt(m3,"grpB"), fmt(m3,"grpC"), fmt(m3,"grpD")),
  "", "**90-day mortality, adjusted (primary specification)**", "", "| Group | OR (95% CI) |", "|---|---|",
  sprintf("| B | %s |", fmt(d90,"grpB")), sprintf("| C | %s |", fmt(d90,"grpC")), sprintf("| D | %s |", fmt(d90,"grpD")))
writeLines(enc2utf8(L1), "v4/film/S1.md")

kap <- function(tab) {
  n <- sum(tab); po <- sum(diag(tab))/n
  pe <- sum(rowSums(tab)*colSums(tab))/n^2
  k <- (po-pe)/(1-pe); se <- sqrt(po*(1-po)/(n*(1-pe)^2))
  a <- tab[2,2]; b <- tab[1,2]; cc <- tab[2,1]; d <- tab[1,1]
  c(po=po, pe=pe, k=k, lo=k-1.96*se, hi=k+1.96*se,
    pabak=2*po-1, ppos=2*a/(2*a+b+cc), pneg=2*d/(2*d+b+cc), n=n)
}
t1 <- table(factor(f$cong,0:1), factor(as.integer(f$fb>0),0:1))
s <- f[f$cls_imp != "unknown", ]; s$cs <- as.integer(s$cls_imp=="pos_explicit")
t2 <- table(factor(s$cs,0:1), factor(as.integer(s$fb>0),0:1))
k1 <- kap(t1); k2 <- kap(t2)
L2 <- c("# Table S2. Agreement between radiographic congestion and film-anchored 72-h fluid balance", "",
  "| Definition | n | Observed agreement | Expected agreement | κ | PABAK | Ppos | Pneg |", "|---|---:|---:|---:|---:|---:|---:|---:|",
  sprintf("| Hybrid (primary) | %d | %.3f | %.3f | %.3f (%.3f to %.3f) | %.3f | %.3f | %.3f |",
    k1["n"], k1["po"], k1["pe"], k1["k"], k1["lo"], k1["hi"], k1["pabak"], k1["ppos"], k1["pneg"]),
  sprintf("| Strict impression-only | %d | %.3f | %.3f | %.3f (%.3f to %.3f) | %.3f | %.3f | %.3f |",
    k2["n"], k2["po"], k2["pe"], k2["k"], k2["lo"], k2["hi"], k2["pabak"], k2["ppos"], k2["pneg"]),
  "", "κ = Cohen's kappa; PABAK = prevalence-adjusted bias-adjusted kappa (2·Po − 1);",
  "Ppos/Pneg = positive and negative agreement (Byrt et al.). Fluid balance is measured from the film to 72 h later.")
writeLines(enc2utf8(L2), "v4/film/S2.md")
cat("S1 and S2 written\n")
cat("M3 check:", fmt(m3,"grpB"), "|", fmt(m3,"grpC"), "|", fmt(m3,"grpD"), "\n")
