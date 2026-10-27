setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

set.seed(20261023)
imp <- mice(a[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd","cci")],
            m = 20, printFlag = FALSE)

run <- function(lbl, f) {
  fits <- lapply(1:20, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef)
  V <- lapply(fits, vcov)
  bb <- rowMeans(b)
  Wb <- Reduce("+", V) / 20
  Bt <- cov(t(b))
  Tt <- Wb + (1 + 1/20) * Bt
  idx <- grep("^grp", rownames(b))
  W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx, idx]) %*% bb[idx])
  pval <- pchisq(W, length(idx), lower.tail = FALSE)
  cat("\n=====", lbl, "=====\n")
  cat(sprintf("整体 Wald chi2 = %.2f, df = %d, p = %.4f\n", W, length(idx), pval))
  se <- sqrt(diag(Tt))
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb - 1.96*se), ucl = exp(bb + 1.96*se))
  print(out[out$term %in% c("grpB","grpC","grpD","hf","ckd","cci","lac"), ], row.names = FALSE, digits = 3)
}

run("A) 协议原样：CCI + hf + ckd",
    death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cci)
run("B) 仅 CCI（去 hf/ckd，避免与 CCI 共线）",
    death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + cci)
run("C) 仅 hf + ckd（去 CCI）",
    death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
