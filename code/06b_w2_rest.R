setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any

mk <- function(dat, cong_col) {
  dat <- dat[!is.na(dat[[cong_col]]) & !is.na(dat$fb72_mlkg), ]
  dat$grp <- factor(ifelse(dat[[cong_col]] == 1, ifelse(dat$fb72_mlkg > 0, "D", "C"),
                    ifelse(dat$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
  dat$fb10 <- dat$fb72_mlkg / 10
  dat
}

pooled <- function(dat, f, m = 20) {
  vars <- unique(c(all.vars(f), "death30"))
  dat <- dat[, intersect(vars, names(dat))]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Wb <- Reduce("+", V)/m; Bt <- cov(t(b)); Tt <- Wb + (1 + 1/m)*Bt
  se <- sqrt(diag(Tt))
  idx <- grep("^grp", rownames(b))
  jt <- c(NA, NA, NA)
  if (length(idx) > 0) {
    W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx, idx]) %*% bb[idx])
    jt <- c(W, length(idx), pchisq(W, length(idx), lower.tail = FALSE))
  }
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb - 1.96*se),
                    ucl = exp(bb + 1.96*se), p = 2*pnorm(-abs(bb/se)))
  attr(out, "joint") <- c(chisq = jt[1], df = jt[2], p = jt[3],
                          n = nrow(dat), deaths = sum(dat$death30))
  out
}

a <- mk(d, "cong_hybrid")
F <- death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd

cat("=== CONTINUOUS (exploratory) ===\n")
r3 <- pooled(a, death30 ~ cong_hybrid + fb10 + cong_hybrid:fb10 + age + female +
                        sofa_score + lac + vent24 + vaso24 + hf + ckd)
print(subset(r3, term %in% c("cong_hybrid","fb10","cong_hybrid:fb10")), row.names = FALSE, digits = 3)

cat("\n=== S4 排除心衰 ===\n")
r4 <- pooled(a[a$hf == 0, ], death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + ckd)
cat(sprintf("N=%d deaths=%d joint p=%.4g\n", attr(r4,"joint")["n"], attr(r4,"joint")["deaths"], attr(r4,"joint")["p"]))
print(subset(r4, grepl("^grp", term)), row.names = FALSE, digits = 3)

cat("\n=== S9 输出完整 ===\n")
r5 <- pooled(a[a$output_complete == 1, ], F)
cat(sprintf("N=%d deaths=%d joint p=%.4g\n", attr(r5,"joint")["n"], attr(r5,"joint")["deaths"], attr(r5,"joint")["p"]))
print(subset(r5, grepl("^grp", term)), row.names = FALSE, digits = 3)

cat("\n=== S12 严格 IMPRESSION 定义 ===\n")
r6 <- pooled(mk(d, "cong_primary"), F)
cat(sprintf("N=%d deaths=%d joint p=%.4g\n", attr(r6,"joint")["n"], attr(r6,"joint")["deaths"], attr(r6,"joint")["p"]))
print(subset(r6, grepl("^grp", term)), row.names = FALSE, digits = 3)

fmt <- function(r, terms) { s <- subset(r, term %in% terms)
  sprintf("%s: %.2f (%.2f-%.2f), p=%.3f", s$term, s$OR, s$lcl, s$ucl, s$p) }
lines <- c("", "## 连续模型（探索性）", paste0("- ", fmt(r3, c("cong_hybrid","fb10","cong_hybrid:fb10"))),
           "", "## S4 排除心衰", paste0("- ", fmt(r4, c("grpB","grpC","grpD"))),
           "", "## S9 输出完整", paste0("- ", fmt(r5, c("grpB","grpC","grpD"))),
           "", "## S12 严格定义", paste0("- ", fmt(r6, c("grpB","grpC","grpD"))))
write(lines, "tables/W2_main_results.md", append = TRUE)
cat("\nappended\n")
