setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(mice); library(pROC)})
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$has_note <- d$has_note %in% c("t", "TRUE", "True", TRUE)

pooled <- function(dat, f, m = 20) {
  vars <- unique(c(all.vars(f), "death30")); dat <- dat[, intersect(vars, names(dat))]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Tt <- Reduce("+", V)/m + (1 + 1/m)*cov(t(b))
  se <- sqrt(diag(Tt)); idx <- grep("^grp", rownames(b))
  W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx,idx]) %*% bb[idx])
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
  attr(out,"joint") <- c(p = pchisq(W, length(idx), lower.tail = FALSE), n = nrow(dat), deaths = sum(dat$death30))
  out
}

d3 <- d[d$has_note & !is.na(d$fb72_mlkg), ]
d3$grp <- factor(ifelse(is.na(d3$cong_hybrid), "U",
                 ifelse(d3$cong_hybrid == 1, ifelse(d3$fb72_mlkg > 0, "D", "C"),
                                              ifelse(d3$fb72_mlkg > 0, "B", "A"))),
                 levels = c("A","B","C","D","U"))
cat("S10 分组：\n"); print(table(d3$grp))
r10 <- pooled(d3, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
cat("\n=== S10 ===\n"); print(subset(r10, grepl("^grp", term)), row.names = FALSE, digits = 3)
cat("N =", attr(r10,"joint")["n"], " deaths =", attr(r10,"joint")["deaths"],
    " p =", sprintf("%.2g", attr(r10,"joint")["p"]), "\n")

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
cc <- a[complete.cases(a[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
m0 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
m1 <- glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
p0 <- fitted(m0); p1 <- fitted(m1); y <- cc$death30

NRIe <- mean(p1[y==1] > p0[y==1]) - mean(p1[y==1] < p0[y==1])
NRIne <- mean(p1[y==0] < p0[y==0]) - mean(p1[y==0] > p0[y==0])
IDI <- (mean(p1[y==1]) - mean(p1[y==0])) - (mean(p0[y==1]) - mean(p0[y==0]))
cat(sprintf("\nNRI events = %.3f, NRI non-events = %.3f, NRI total = %.3f\n", NRIe, NRIne, NRIe+NRIne))
cat(sprintf("IDI = %.4f\n", IDI))
cat(sprintf("AUC: %.4f -> %.4f\n", as.numeric(auc(y,p0)), as.numeric(auc(y,p1))))
