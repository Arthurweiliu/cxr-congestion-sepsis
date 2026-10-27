setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(pROC)})

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$has_film <- d$has_film %in% c("t","TRUE","True",TRUE)
d$has_note <- d$has_note %in% c("t","TRUE","True",TRUE)

cat("队列:", nrow(d), " 拍片:", sum(d$has_film), " 未拍片:", sum(!d$has_film), "\n")

# ---------- 1. 拍片 vs 未拍片基线 ----------
cov <- c("age","female","sofa_score","vent24","vaso24","hf","ckd")
smd <- function(x, g) {
  m1 <- mean(x[g], na.rm=TRUE); m0 <- mean(x[!g], na.rm=TRUE)
  s1 <- sd(x[g], na.rm=TRUE); s0 <- sd(x[!g], na.rm=TRUE)
  (m1-m0)/sqrt((s1^2+s0^2)/2)
}
cat("\n=== 拍片 vs 未拍片 ===\n")
g <- d$has_film
tab <- data.frame(
  变量 = c(cov, "death30","death_hosp","lactate(有值%)"),
  拍片 = c(sapply(cov, function(v) sprintf("%.1f", mean(d[[v]][g], na.rm=TRUE))),
           sprintf("%.1f%%", 100*mean(d$death30[g], na.rm=TRUE)),
           sprintf("%.1f%%", 100*mean(d$death_hosp[g], na.rm=TRUE)),
           sprintf("%.1f%%", 100*mean(!is.na(d$lac[g])))),
  未拍片 = c(sapply(cov, function(v) sprintf("%.1f", mean(d[[v]][!g], na.rm=TRUE))),
            sprintf("%.1f%%", 100*mean(d$death30[!g], na.rm=TRUE)),
            sprintf("%.1f%%", 100*mean(d$death_hosp[!g], na.rm=TRUE)),
            sprintf("%.1f%%", 100*mean(!is.na(d$lac[!g])))),
  SMD = c(sprintf("%.2f", sapply(cov, function(v) smd(d[[v]], g))),
          sprintf("%.2f", smd(d$death30, g)), sprintf("%.2f", smd(d$death_hosp, g)), "—"),
  check.names = FALSE)
print(tab, row.names = FALSE)

# ---------- 2. 选择模型 ----------
cat("\n=== 选择模型 ===\n")
sel <- glm(has_film ~ age + female + sofa_score + vent24 + vaso24 + hf + ckd, data = d, family = binomial)
cat(sprintf("选择模型 AUC = %.3f\n", as.numeric(auc(d$has_film, fitted(sel)))))
d$psel <- fitted(sel)
cat("倾向得分分布（拍片组）:\n"); print(round(quantile(d$psel[g], c(.01,.25,.5,.75,.99)), 3))
cat("倾向得分分布（未拍片组）:\n"); print(round(quantile(d$psel[!g], c(.01,.25,.5,.75,.99)), 3))

# ---------- 3. IPW 加权主模型 ----------
a <- d[d$has_film & !is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
a$w <- 1 / a$psel
a$w <- pmin(a$w, quantile(a$w, 0.99))          # 截尾
a$w <- a$w / mean(a$w)                          # 标准化

cc <- a[complete.cases(a[, c("death30","grp","age","female","sofa_score","vent24","vaso24","hf","ckd")]), ]
cat("\n加权模型 N =", nrow(cc), " deaths =", sum(cc$death30),
    " 权重范围", sprintf("%.2f-%.2f", min(cc$w), max(cc$w)), "\n")

mw <- glm(death30 ~ grp + age + female + sofa_score + vent24 + vaso24 + hf + ckd,
          data = cc, family = binomial, weights = w)
o <- exp(cbind(OR = coef(mw), confint.default(mw)))
cat("\n=== S7 IPW 加权（不含乳酸，因选择模型无法纳入）===\n")
print(round(o[grep("^grp", rownames(o)), ], 3))

# 未加权对照
mu <- glm(death30 ~ grp + age + female + sofa_score + vent24 + vaso24 + hf + ckd,
          data = cc, family = binomial)
ou <- exp(cbind(OR = coef(mu), confint.default(mu)))
cat("\n=== 未加权对照 ===\n")
print(round(ou[grep("^grp", rownames(ou)), ], 3))
