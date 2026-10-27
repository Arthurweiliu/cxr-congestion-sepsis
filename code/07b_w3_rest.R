setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(mice); library(pROC)})
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$has_note <- d$has_note %in% c("t", "TRUE", "True", TRUE)

pooled <- function(dat, f, m = 20) {
  vars <- unique(c(all.vars(f), "death30"))
  dat <- dat[, intersect(vars, names(dat))]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Tt <- Reduce("+", V)/m + (1 + 1/m)*cov(t(b))
  se <- sqrt(diag(Tt)); idx <- grep("^grp", rownames(b))
  W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx,idx]) %*% bb[idx])
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
  attr(out,"joint") <- c(p = pchisq(W, length(idx), lower.tail = FALSE),
                         n = nrow(dat), deaths = sum(dat$death30))
  out
}

cat("has_note TRUE:", sum(d$has_note), "\n")

d3 <- d[d$has_note & !is.na(d$fb72_mlkg), ]
d3$grp <- factor(ifelse(is.na(d3$cong_hybrid), "U",
                 ifelse(d3$cong_hybrid == 1, ifelse(d3$fb72_mlkg > 0, "D", "C"),
                                              ifelse(d3$fb72_mlkg > 0, "B", "A"))),
                 levels = c("A","B","C","D","U"))
cat("S10 分组：\n"); print(table(d3$grp))

r10 <- pooled(d3, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
cat("\n=== S10 unknown 作为独立类别 ===\n")
print(subset(r10, grepl("^grp", term)), row.names = FALSE, digits = 3)
cat("N =", attr(r10,"joint")["n"], " deaths =", attr(r10,"joint")["deaths"],
    " 整体 p =", sprintf("%.2g", attr(r10,"joint")["p"]), "\n")

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

cat("\n===== 判别力（完整病例）=====\n")
cc <- a[complete.cases(a[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
m0 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
m1 <- glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
p0 <- fitted(m0); p1 <- fitted(m1); y <- cc$death30
a0 <- as.numeric(auc(y, p0)); a1 <- as.numeric(auc(y, p1))
set.seed(1)
dB <- replicate(500, { i <- sample(nrow(cc), replace = TRUE)
  if (length(unique(y[i])) < 2) return(NA)
  as.numeric(auc(y[i], p1[i])) - as.numeric(auc(y[i], p0[i])) })
dB <- dB[!is.na(dB)]
cat(sprintf("AUC base = %.4f ; +淤血 = %.4f ; delta = %+.4f (95%% CI %.4f to %.4f)\n",
            a0, a1, a1-a0, quantile(dB,.025), quantile(dB,.975)))
cat(sprintf("N = %d, deaths = %d\n", nrow(cc), sum(y)))

nri_e <- mean(ifelse(y==1, p1>p0, p1<p0)) - mean(ifelse(y==1, p1<p0, p1>p0))
pbar0 <- mean(p0); pbar1 <- mean(p1)
idi <- (mean(ifelse(y==1,p1,p0)) - mean(ifelse(y==0,p1,p0))) / 2
cat(sprintf("连续 NRI = %.4f ; IDI(近似) = %.4f\n", nri_e, idi))
