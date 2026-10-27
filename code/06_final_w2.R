setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$deathtime <- as.POSIXct(ifelse(d$deathtime %in% c("", NA), NA, d$deathtime), tz = "UTC")

mk <- function(dat, cong_col) {
  dat <- dat[!is.na(dat[[cong_col]]) & !is.na(dat$fb72_mlkg), ]
  dat$grp <- factor(ifelse(dat[[cong_col]] == 1,
                    ifelse(dat$fb72_mlkg > 0, "D", "C"),
                    ifelse(dat$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
  dat$fb10 <- dat$fb72_mlkg / 10
  dat
}

pooled <- function(dat, f, m = 20, label = "") {
  vars <- all.vars(f)
  dat <- dat[complete.cases(dat[, intersect(vars, names(dat))]) |
             !is.na(dat$death30), ]
  dat <- dat[, unique(c(vars, "death30"))]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Wb <- Reduce("+", V)/m; Bt <- cov(t(b)); Tt <- Wb + (1 + 1/m)*Bt
  se <- sqrt(diag(Tt))
  idx <- grep("^grp", rownames(b))
  W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx, idx]) %*% bb[idx])
  pj <- pchisq(W, length(idx), lower.tail = FALSE)
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb - 1.96*se),
                    ucl = exp(bb + 1.96*se), p = 2*pnorm(-abs(bb/se)))
  attr(out, "joint") <- c(chisq = W, df = length(idx), p = pj, n = nrow(dat),
                          deaths = sum(dat$death30))
  out
}

F <- death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd
a <- mk(d, "cong_hybrid")

cat("=== MAIN (hybrid, MI m=20, Model C) ===\n")
r <- pooled(a, F)
cat(sprintf("N=%d deaths=%d joint chi2=%.2f df=%d p=%.4g\n",
            attr(r,"joint")["n"], attr(r,"joint")["deaths"], attr(r,"joint")["chisq"],
            attr(r,"joint")["df"], attr(r,"joint")["p"]))
print(subset(r, grepl("^grp|^lac|^hf|^ckd|^age|^sofa|^vent|^vaso", term)), row.names = FALSE, digits = 3)

main_tab <- r

cat("\n=== LANDMARK 72h (MI) ===\n")
alive <- is.na(a$deathtime) | a$deathtime > a$intime + 3*86400
r2 <- pooled(a[alive, ], F)
cat(sprintf("N=%d deaths=%d joint p=%.4g\n", attr(r2,"joint")["n"], attr(r2,"joint")["deaths"], attr(r2,"joint")["p"]))
print(subset(r2, grepl("^grp", term)), row.names = FALSE, digits = 3)

cat("\n=== CONTINUOUS (exploratory) ===\n")
r3 <- pooled(a, death30 ~ cong_hybrid + fb10 + cong_hybrid:fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
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
as_ <- mk(d, "cong_primary")
r6 <- pooled(as_, F)
cat(sprintf("N=%d deaths=%d joint p=%.4g\n", attr(r6,"joint")["n"], attr(r6,"joint")["deaths"], attr(r6,"joint")["p"]))
print(subset(r6, grepl("^grp", term)), row.names = FALSE, digits = 3)

# ---- 输出表 ----
fmt <- function(r, terms) {
  s <- subset(r, term %in% terms)
  sprintf("%s: %.2f (%.2f-%.2f), p=%.3f", s$term, s$OR, s$lcl, s$ucl, s$p)
}
lines <- c(
  "# W2 主结果（Model C: age + female + SOFA + lactate + vent + vaso + HF + CKD）",
  "",
  sprintf("主分析 N=%d, deaths=%d, joint Wald p=%.4g", attr(main_tab,"joint")["n"],
          attr(main_tab,"joint")["deaths"], attr(main_tab,"joint")["p"]),
  "",
  "## 四组（参照 A）", paste0("- ", fmt(main_tab, c("grpB","grpC","grpD"))),
  "",
  "## 72h 界标", paste0("- ", fmt(r2, c("grpB","grpC","grpD"))),
  "",
  "## 连续模型（探索性）", paste0("- ", fmt(r3, c("cong_hybrid","fb10","cong_hybrid:fb10"))),
  "",
  "## S4 排除心衰", paste0("- ", fmt(r4, c("grpB","grpC","grpD"))),
  "",
  "## S9 输出完整", paste0("- ", fmt(r5, c("grpB","grpC","grpD"))),
  "",
  "## S12 严格定义", paste0("- ", fmt(r6, c("grpB","grpC","grpD")))
)
writeLines(lines, "tables/W2_main_results.md")
cat("\nwritten tables/W2_main_results.md\n")
