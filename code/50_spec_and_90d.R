setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$female <- as.integer(f$gender == "F")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

runMI <- function(dat, f, m = 20) {
  vars <- unique(c(all.vars(f), "death30"))
  dd <- dat[, intersect(vars, names(dat))]
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B)
  se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))))
  data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb - 1.96*se), ucl = exp(bb + 1.96*se))
}
g <- function(r) r[grepl("^grp", r$term), ]

m1 <- runMI(f, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cci)
m2 <- runMI(f, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + cci)
m3 <- runMI(f, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m90 <- runMI(f, death90 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)

cat("M1 CCI+hf+ckd:\n"); print(g(m1), row.names = FALSE, digits = 3)
cat("M2 CCI only:\n");    print(g(m2), row.names = FALSE, digits = 3)
cat("M3 primary:\n");     print(g(m3), row.names = FALSE, digits = 3)
cat("90-day adjusted:\n");print(g(m90), row.names = FALSE, digits = 3)

fmt <- function(r) sprintf("%.2f (%.2f–%.2f)", r$OR, r$lcl, r$ucl)
lines <- c("# Table S3. Model specification and 90-day outcome", "",
  "All models use multiple imputation (m = 20) and the same exposure; only the comorbidity terms differ.", "",
  "| Model | Group B | Group C | Group D |", "|---|---|---|---|",
  sprintf("| M1: Charlson index + heart failure + CKD | %s | %s | %s |", fmt(g(m1))[1], fmt(g(m1))[2], fmt(g(m1))[3]),
  sprintf("| M2: Charlson index only | %s | %s | %s |", fmt(g(m2))[1], fmt(g(m2))[2], fmt(g(m2))[3]),
  sprintf("| M3: individual comorbidities only (primary) | %s | %s | %s |", fmt(g(m3))[1], fmt(g(m3))[2], fmt(g(m3))[3]),
  "",
  "**90-day mortality, adjusted (primary specification)**", "",
  "| Group | OR (95% CI) |", "|---|---|",
  sprintf("| B | %s |", fmt(g(m90))[1]),
  sprintf("| C | %s |", fmt(g(m90))[2]),
  sprintf("| D | %s |", fmt(g(m90))[3]))
writeLines(enc2utf8(lines), con = file("tables/S3_specification.md", "w", encoding = "UTF-8"))
cat("\nwritten tables/S3_specification.md\n")
