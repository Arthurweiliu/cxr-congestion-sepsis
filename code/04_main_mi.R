setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F")
d$lac <- d$lac_any

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1,
                ifelse(a$fb72_mlkg > 0, "D", "C"),
                ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
a$fb10 <- a$fb72_mlkg / 10

covs <- c("age","female","sofa_score","lac","vent24","vaso24","hf","ckd","cci")
vars <- c("death30","grp",covs)
cat("N =", nrow(a), " deaths =", sum(a$death30), "\n")
cat("missing lac:", sum(is.na(a$lac)), sprintf("(%.1f%%)\n", 100*mean(is.na(a$lac))))
cat("missing any covariate:", sum(!complete.cases(a[, vars])), "\n")

getOR <- function(m, pat) {
  o <- exp(cbind(OR = coef(m), confint.default(m)))
  idx <- grep(pat, rownames(o))
  o[idx, , drop = FALSE]
}

# ---------- complete case ----------
cc <- a[complete.cases(a[, vars]), ]
f_full <- as.formula(paste("death30 ~ grp +", paste(covs, collapse = " + ")))
f_null <- as.formula(paste("death30 ~", paste(covs, collapse = " + ")))
m_cc <- glm(f_full, data = cc, family = binomial)
m0_cc <- glm(f_null, data = cc, family = binomial)
b <- coef(m_cc); V <- vcov(m_cc); i <- grep("^grp", names(b))
W <- as.numeric(t(b[i]) %*% solve(V[i,i]) %*% b[i])
cat("\n=== 完整病例 N =", nrow(cc), " deaths =", sum(cc$death30), "===\n")
cat(sprintf("Joint Wald chi2 = %.2f, p = %.4f\n", W, pchisq(W, length(i), lower.tail = FALSE)))
cat(sprintf("LR chi2 = %.2f, p = %.4f\n", 2*(logLik(m_cc)-logLik(m0_cc)),
            pchisq(2*(logLik(m_cc)-logLik(m0_cc)), length(i), lower.tail = FALSE)))
print(round(getOR(m_cc, "grp"), 3))

# ---------- multiple imputation ----------
cat("\n=== 多重插补 (m = 20) ===\n")
set.seed(20261023)
imp <- mice(a[, vars], m = 20, printFlag = FALSE)
fit  <- with(imp, glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cci, family = binomial))
fit0 <- with(imp, glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cci, family = binomial))
p <- summary(pool(fit), conf.int = TRUE)
p$OR <- exp(p$estimate); p$lcl <- exp(p$`2.5 %`); p$ucl <- exp(p$`97.5 %`)
cat("\nPooled OR:\n")
print(p[, c("term","OR","lcl","ucl","p.value")], row.names = FALSE, digits = 3)

pc <- pool.compare(fit, fit0, method = "D1")
cat("\n整体检验（D1）: chi2 =", sprintf("%.2f", pc$statistic), " df =", pc$df1,
    " p =", sprintf("%.4f", pc$pvalue), "\n")

# ---------- landmark 72h (complete case) ----------
cat("\n=== 72h 界标（完整病例）===\n")
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$deathtime <- as.POSIXct(ifelse(d$deathtime %in% c("", NA), NA, d$deathtime), tz = "UTC")
a$intime <- d$intime[match(a$stay_id, d$stay_id)]
a$deathtime <- d$deathtime[match(a$stay_id, d$stay_id)]
alive <- is.na(a$deathtime) | a$deathtime > a$intime + 3*86400
b72 <- a[alive & complete.cases(a[, vars]), ]
m72 <- glm(f_full, data = b72, family = binomial)
cat("N =", nrow(b72), " deaths =", sum(b72$death30), "\n")
print(round(getOR(m72, "grp"), 3))

# ---------- continuous model ----------
cat("\n=== 连续模型（探索性）===\n")
mc <- glm(death30 ~ cong_hybrid + fb10 + cong_hybrid:fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cci,
          data = cc, family = binomial)
oc <- exp(cbind(OR = coef(mc), confint.default(mc)))
for (v in c("cong_hybrid","fb10","cong_hybrid:fb10")) {
  cat(sprintf("%-20s %.3f (%.3f-%.3f) p=%.3f\n", v, oc[v,1], oc[v,2], oc[v,3],
              summary(mc)$coefficients[v,4]))
}

# ---------- sensitivity previews ----------
cat("\n=== S12 严格定义 ===\n")
s <- d[!is.na(d$cong_primary) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
s$grp <- factor(ifelse(s$cong_primary == 1, ifelse(s$fb72_mlkg > 0, "D", "C"),
                       ifelse(s$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
sc <- s[complete.cases(s[, vars]), ]
cat("N =", nrow(sc), " deaths =", sum(sc$death30), "\n")
print(round(getOR(glm(f_full, data = sc, family = binomial), "grp"), 3))

cat("\n=== S4 排除心衰 ===\n")
c4 <- cc[cc$hf == 0, ]
cat("N =", nrow(c4), " deaths =", sum(c4$death30), "\n")
print(round(getOR(glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + ckd + cci,
                      data = c4, family = binomial), "grp"), 3))

cat("\n=== S9 输出完整 ===\n")
c9 <- cc[cc$output_complete == 1, ]
cat("N =", nrow(c9), " deaths =", sum(c9$death30), "\n")
print(round(getOR(glm(f_full, data = c9, family = binomial), "grp"), 3))
