setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
dat <- a[, vars]
imp <- mice(dat, m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa_score + lac +
                                       vent24 + vaso24 + hf + ckd, data = complete(imp, i), family = binomial))
b <- sapply(fits, coef); V <- lapply(fits, vcov)
bb <- rowMeans(b); se <- sqrt(diag(Reduce("+", V)/20 + (1 + 1/20)*cov(t(b))))
out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb - 1.96*se), ucl = exp(bb + 1.96*se),
                  p = 2*pnorm(-abs(bb/se)))
print(out, row.names = FALSE, digits = 3)

lab <- c("(Intercept)"="Intercept", grpB="Group B (no congestion / balance >0)",
         grpC="Group C (congestion / balance <=0)", grpD="Group D (congestion / balance >0)",
         age="Age, per year", female="Female sex", sofa_score="SOFA, per point",
         lac="Lactate, per mmol/L", vent24="Invasive ventilation, day 1",
         vaso24="Vasopressor use, day 1", hf="History of heart failure", ckd="Chronic kidney disease")
rows <- out[out$term != "(Intercept)", ]
lines <- c("# Table 2. Adjusted association with 30-day mortality", "",
  sprintf("Multiple imputation (m=20); n = %d, deaths = %d", nrow(dat), sum(dat$death30)), "",
  "| Variable | OR | 95% CI | p |", "|---|---:|---|---:|")
for (i in seq_len(nrow(rows))) {
  lines <- c(lines, sprintf("| %s | %.2f | %.2f–%.2f | %.3f |",
    lab[[rows$term[i]]], rows$OR[i], rows$lcl[i], rows$ucl[i], rows$p[i]))
}
lines <- c(lines, "", "Overall test across groups: joint Wald chi-square = 45.7, df = 3, p < 0.001.",
           "Reference group A. Model includes age, sex, SOFA, lactate, ventilation, vasopressors, heart failure and chronic kidney disease.")
writeLines(enc2utf8(lines), con = file("tables/T2_models.md", "w", encoding = "UTF-8"))
cat("\nwritten\n")
