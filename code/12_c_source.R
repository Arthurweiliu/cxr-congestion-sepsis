setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

# 暴露来源分层（仅对 congestion+ 有意义）
a$source <- ifelse(a$cong_hybrid == 1,
  ifelse(!is.na(a$cls_imp) & a$cls_imp == "pos_explicit", "impression",
    ifelse(!is.na(a$cls_full) & a$cls_full == "pos_anywhere", "findings",
      ifelse(!is.na(a$chex_edema) & a$chex_edema == 1, "chexpert", "other"))),
  "negative")
cat("=== congestion+ 按来源 ===\n"); print(table(a$source))

cgrp <- a[a$grp == "C", ]
cat("\n=== 组 C 按来源 ===\n"); print(table(cgrp$source))
cat("组 C 各来源死亡率:\n")
print(round(100*tapply(cgrp$death30, cgrp$source, mean), 1))

cov <- c("age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
pooled <- function(dat, m = 20) {
  vars <- c("death30","grp",cov)
  dat <- dat[, vars]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa_score + lac +
                                        vent24 + vaso24 + hf + ckd, data = complete(imp,i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Tt <- Reduce("+", V)/m + (1+1/m)*cov(t(b))
  se <- sqrt(diag(Tt))
  data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
}

cat("\n=== 敏感性：仅用 IMPRESSION 明确阳性作为组 C（S12）===\n")
c_imp <- a[a$source %in% c("impression","negative") & (a$grp != "C" | a$source == "impression"), ]
c_imp$grp2 <- ifelse(c_imp$grp == "C", "C", as.character(c_imp$grp))
c_imp$grp2 <- factor(c_imp$grp2, levels = c("A","B","C","D"))
c_imp$grp <- c_imp$grp2
r1 <- pooled(c_imp)
print(subset(r1, grepl("^grp", term)), row.names = FALSE, digits = 3)
cat("N =", nrow(c_imp), "\n")

cat("\n=== 敏感性：排除 CheXpert 回填的组 C ===\n")
c_noch <- a[!(a$grp == "C" & a$source == "chexpert"), ]
r2 <- pooled(c_noch)
print(subset(r2, grepl("^grp", term)), row.names = FALSE, digits = 3)
cat("N =", nrow(c_noch), "\n")
