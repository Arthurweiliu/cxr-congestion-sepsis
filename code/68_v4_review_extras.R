## 68_v4_review_extras.R — 评审要求的补充：节位敏感性、MI 合并 AUC、替代插补口径
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(pROC) })
set.seed(20261023)
f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
f$fb10 <- f$fb72_mlkg/10
vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
bases <- lapply(1:20, function(i) complete(imp, i))
y <- f$death30

## ---- 1. 节位敏感性：ns df=3/4/5 vs 线性 ----
B <- list()
for (df in 3:5) {
  m <- ns(f$fb72_mlkg, df = df)
  B[[as.character(df)]] <- as.data.frame(unclass(m))
  names(B[[as.character(df)]]) <- paste0("S", df, "_", 1:ncol(m))
}
lr <- function(d, extra, base_f) {
  m0 <- glm(as.formula(paste("death30 ~", base_f)), data = d, family = binomial)
  m1 <- glm(as.formula(paste("death30 ~", base_f, "+", extra)), data = d, family = binomial)
  c(chi2 = 2*(as.numeric(logLik(m1)) - as.numeric(logLik(m0))),
    df = attr(logLik(m1), "df") - attr(logLik(m0), "df"))
}
cov <- "cong + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
res <- sapply(names(B), function(df) {
  cols <- paste(names(B[[df]]), collapse = " + ")
  r <- mapply(function(d) {
    dd <- cbind(d, B[[df]]); dd$fb10 <- f$fb10; dd$cong <- as.integer(f$cong_hybrid); lr(dd, cols, cov)
  }, bases)
  c(df_knots = as.numeric(df), chi2 = median(r["chi2",]), p = median(pchisq(r["chi2",], r["df",], lower.tail = FALSE)))
})
cat("\n[1] 节位敏感性（ns df=3/4/5 vs 线性，72h）\n"); print(round(t(res), 4), row.names = FALSE)

## ---- 2. MI 合并 AUC（平均预测概率，全样本作为参考） ----
aucv <- function(p, yy) { r <- rank(p); n1 <- sum(yy); n0 <- sum(!yy); (sum(r[yy == 1]) - n1*(n1+1)/2)/(n1*n0) }
forms <- list(
  base = "death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd",
  `base+grp` = "death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd",
  `base+grp+fb` = "death30 ~ grp + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
)
aucMi <- sapply(forms, function(fm) {
  ps <- sapply(bases, function(d) { d$fb10 <- f$fb10; fitted(glm(as.formula(fm), data = d, family = binomial)) })
  aucv(rowMeans(ps), y)
})
cat("\n[2] MI 合并 AUC（m=20，平均预测概率）\n"); print(round(aucMi, 4))
cat("delta grp over base:", round(aucMi[2]-aucMi[1], 4), "\n")

## ---- 3. 替代插补口径下的校正估计（与 63 脚本一致，含事后暴露协变量） ----
vars2 <- c(vars, "cong_hybrid"); 
d2 <- f[, c(vars, "cong_hybrid")]; d2$cong <- as.integer(d2$cong_hybrid)
set.seed(20261025)
imp2 <- mice(d2[, c("death30","grp","cong","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")], m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) { d <- complete(imp2, i); d$fb10 <- f$fb10
  glm(death30 ~ grp + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = d, family = binomial) })
Bm <- sapply(fits, coef); b <- rowMeans(Bm)
Tm <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(Bm)); se <- sqrt(diag(Tm))
cat("\n[3] 替代插补口径（含事后暴露协变量）\n")
for (t in c("grpB","grpC","grpD","fb10")) cat(sprintf("  %s %.2f (%.2f-%.2f)\n", t, exp(b[t]), exp(b[t]-1.96*se[t]), exp(b[t]+1.96*se[t])))
