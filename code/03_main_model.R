setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/base.csv", stringsAsFactors = FALSE)

d$female <- as.integer(d$gender == "F")
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$deathtime <- as.POSIXct(ifelse(d$deathtime %in% c("", NA), NA, d$deathtime), tz = "UTC")
d$dod <- as.Date(ifelse(d$dod %in% c("", NA), NA, d$dod))

DYS <- NULL
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$fbpos <- as.integer(a$fb72_mlkg > 0)
a$grp <- factor(ifelse(a$cong_hybrid == 1,
                ifelse(a$fbpos == 1, "D", "C"),
                ifelse(a$fbpos == 1, "B", "A")), levels = c("A","B","C","D"))
a$fb10 <- a$fb72_mlkg / 10

cat("N =", nrow(a), " deaths =", sum(a$death30), sprintf("(%.1f%%)\n", 100*mean(a$death30)))
cat("lactate missing:", sum(is.na(a$lactate_max)), sprintf("(%.1f%%)\n", 100*mean(is.na(a$lactate_max))))

covs <- c("age","female","sofa_score","lactate_max","vent24","vaso24","hf","ckd","cci")
cc <- a[complete.cases(a[, c("death30","grp",covs)]), ]
cat("\ncomplete-case N =", nrow(cc), " deaths =", sum(cc$death30), "\n")

f <- as.formula(paste("death30 ~ grp +", paste(covs, collapse = " + ")))
m <- glm(f, data = cc, family = binomial)

b <- coef(m); V <- vcov(m); idx <- grep("^grp", names(b))
W <- as.numeric(t(b[idx]) %*% solve(V[idx, idx]) %*% b[idx])
pW <- pchisq(W, df = length(idx), lower.tail = FALSE)
m0 <- glm(as.formula(paste("death30 ~", paste(covs, collapse = " + "))), data = cc, family = binomial)
lr <- as.numeric(2 * (logLik(m) - logLik(m0)))
pLR <- pchisq(lr, df = length(idx), lower.tail = FALSE)

cat("\n===== 四组整体检验 =====\n")
cat(sprintf("Joint Wald: chi2 = %.2f, df = %d, p = %.4f\n", W, length(idx), pW))
cat(sprintf("Likelihood ratio: chi2 = %.2f, df = %d, p = %.4f\n", lr, length(idx), pLR))

cat("\n===== 主模型 OR =====\n")
o <- exp(cbind(OR = coef(m), confint.default(m)))
print(round(o, 3))

cat("\n===== 72h 界标分析 =====\n")
t72 <- a$intime + 3 * 86400
alive <- is.na(a$deathtime) | a$deathtime > t72
b72 <- a[alive & complete.cases(a[, c("death30","grp",covs)]), ]
m2 <- glm(f, data = b72, family = binomial)
o2 <- exp(cbind(OR = coef(m2), confint.default(m2)))
b2 <- coef(m2); V2 <- vcov(m2); i2 <- grep("^grp", names(b2))
W2 <- as.numeric(t(b2[i2]) %*% solve(V2[i2, i2]) %*% b2[i2])
cat("N =", nrow(b72), " deaths =", sum(b72$death30),
    sprintf("  Joint Wald p = %.4f\n", pchisq(W2, length(i2), lower.tail = FALSE)))
print(round(o2[grep("^grp", rownames(o2)), ], 3))

cat("\n===== 连续模型（探索性：淤血 × 液体）=====\n")
m3 <- glm(as.formula(paste("death30 ~ cong_hybrid + fb10 + cong_hybrid:fb10 +", paste(covs, collapse = " + "))),
          data = cc, family = binomial)
o3 <- exp(cbind(OR = coef(m3), confint.default(m3)))
cat("congestion:", sprintf("%.3f (%.3f-%.3f)\n", o3["cong_hybrid",1], o3["cong_hybrid",2], o3["cong_hybrid",3]))
cat("fluid10   :", sprintf("%.3f (%.3f-%.3f)\n", o3["fb10",1], o3["fb10",2], o3["fb10",3]))
cat("interaction:", sprintf("%.3f (%.3f-%.3f) p=%.3f  [exploratory]\n",
    o3["cong_hybrid:fb10",1], o3["cong_hybrid:fb10",2], o3["cong_hybrid:fb10",3],
    summary(m3)$coefficients["cong_hybrid:fb10",4]))

cat("\n===== 敏感性 preview：S12 严格定义 =====\n")
s <- d[!is.na(d$cong_primary) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
s$grp <- factor(ifelse(s$cong_primary == 1, ifelse(s$fb72_mlkg > 0, "D", "C"),
                       ifelse(s$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
s$female <- as.integer(s$gender == "F")
sc <- s[complete.cases(s[, c("death30","grp",covs)]), ]
ms <- glm(f, data = sc, family = binomial)
cat("N =", nrow(sc), " deaths =", sum(sc$death30), "\n")
print(round(exp(cbind(OR = coef(ms), confint.default(ms)))[grep("^grp", rownames(coef(ms))), ], 3))

cat("\n===== 敏感性 preview：S4 排除心衰 =====\n")
c4 <- cc[cc$hf == 0, ]
m4 <- glm(death30 ~ grp + age + female + sofa_score + lactate_max + vent24 + vaso24 + ckd + cci,
          data = c4, family = binomial)
cat("N =", nrow(c4), " deaths =", sum(c4$death30), "\n")
print(round(exp(cbind(OR = coef(m4), confint.default(m4)))[grep("^grp", rownames(coef(m4))), ], 3))

cat("\n===== 敏感性 preview：S9 输出完整 =====\n")
c9 <- cc[cc$output_complete == 1, ]
m9 <- glm(f, data = c9, family = binomial)
cat("N =", nrow(c9), " deaths =", sum(c9$death30), "\n")
print(round(exp(cbind(OR = coef(m9), confint.default(m9)))[grep("^grp", rownames(coef(m9))), ], 3))

cat("\n===== mice 可用性 =====\n")
cat("mice installed:", requireNamespace("mice", quietly = TRUE), "\n")
