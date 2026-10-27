## 69_v4_final_numbers.R — §3.8 的单一权威口径
## 插补：与 Table 2 完全一致（m=20, seed 20261023, 10 个变量）；cong / 样条基函数事后附加
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines) })
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
f$fb   <- f$fb72_mlkg
f$fb24 <- f$fb24_mlkg
f$inc  <- f$fb - f$fb24
f$fb10 <- f$fb/10; f$fb2410 <- f$fb24/10; f$inc10 <- f$inc/10
f$cong <- as.integer(f$cong_hybrid)
f$grp24 <- factor(ifelse(f$cong == 1, ifelse(f$fb24 > 0, "D", "C"),
                         ifelse(f$fb24 > 0, "B", "A")), levels = c("A","B","C","D"))

vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
ns72 <- ns(f$fb, df = 4); ns24 <- ns(f$fb24, df = 4); nsinc <- ns(f$inc, df = 4)
mk <- function(m, p) { d <- as.data.frame(unclass(m)); names(d) <- paste0(p, 1:ncol(d)); d }
bases <- lapply(1:20, function(i) {
  d <- complete(imp, i)
  cbind(d, cong = f$cong, grp24 = f$grp24, fb10 = f$fb10, fb2410 = f$fb2410, inc10 = f$inc10,
        mk(ns72, "S72_"), mk(ns24, "S24_"), mk(nsinc, "SIN_"))
})

pool <- function(fits) {
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1 + 1/length(fits))*cov(t(B))
  se <- sqrt(diag(T))
  list(b = b, T = T, tab = data.frame(term = names(b), est = b, OR = exp(b),
       lcl = exp(b - 1.96*se), ucl = exp(b + 1.96*se), p = 2*pnorm(-abs(b/se)), row.names = NULL))
}
fitall <- function(fm) lapply(bases, function(d) glm(fm, data = d, family = binomial))
W <- function(pf, terms) { i <- which(names(pf$b) %in% terms); b <- pf$b[i]; V <- pf$T[i,i]
  x <- as.numeric(t(b) %*% solve(V) %*% b); c(chi2 = x, df = length(i), p = pchisq(x, length(i), lower.tail = FALSE)) }
line <- function(s) cat(s, "\n", sep = "")

c0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
out <- character()

## M1 / M2
p1 <- pool(fitall(as.formula(paste("death30 ~ grp +", c0))))
p2 <- pool(fitall(as.formula(paste("death30 ~ grp + fb10 +", c0))))
line("== M1 (Table 2) =="); print(p1$tab[p1$tab$term %in% c("grpB","grpC","grpD"), c("term","OR","lcl","ucl","p")], digits=3, row.names=FALSE)
line("== M2 (+ continuous balance) =="); print(p2$tab[p2$tab$term %in% c("grpB","grpC","grpD","fb10"), c("term","OR","lcl","ucl","p")], digits=3, row.names=FALSE)

## 样条 vs 线性（adjust cong）
lr <- function(d, extra, base_f) {
  m0 <- glm(as.formula(paste("death30 ~", base_f)), data = d, family = binomial)
  m1 <- glm(as.formula(paste("death30 ~", base_f, "+", extra)), data = d, family = binomial)
  c(chi2 = 2*(as.numeric(logLik(m1)) - as.numeric(logLik(m0))), df = attr(logLik(m1),"df") - attr(logLik(m0),"df"))
}
for (pre in c("S72_","S24_")) {
  cf <- if (pre == "S72_") "cong + fb10" else "cong + fb2410"
  cols <- paste0(pre, 1:4, collapse = " + ")
  r <- sapply(bases, function(d) lr(d, cols, paste(cf, "+", c0)))
  p <- pchisq(r["chi2",], r["df",], lower.tail = FALSE)
  line(sprintf("LR %s: chi2=%.2f df=%d p=%.3f (range %.2f-%.3f)", pre, median(r["chi2",]), median(r["df",]),
               median(p), min(p), max(p)))
}

## 曲线（相对 0）
as_cong <- . ~ cong + . 
p_s72 <- pool(fitall(as.formula(paste("death30 ~ cong + S72_1 + S72_2 + S72_3 + S72_4 +", c0))))
p_s24 <- pool(fitall(as.formula(paste("death30 ~ cong + S24_1 + S24_2 + S24_3 + S24_4 +", c0))))
curve <- function(pf, nso, prefix, grid) {
  Bn <- predict(nso, grid); B0 <- as.numeric(predict(nso, 0))
  i <- which(names(pf$b) %in% paste0(prefix, 1:ncol(Bn)))
  C <- sweep(Bn, 2, B0, "-"); lp <- as.numeric(C %*% pf$b[i]); se <- sqrt(rowSums((C %*% pf$T[i,i]) * C))
  data.frame(x = grid, OR = exp(lp), lcl = exp(lp - 1.96*se), ucl = exp(lp + 1.96*se))
}
g72 <- seq(as.numeric(quantile(f$fb, .01)), as.numeric(quantile(f$fb, .95)), length.out = 200)
g24 <- seq(as.numeric(quantile(f$fb24, .01)), as.numeric(quantile(f$fb24, .95)), length.out = 200)
cv72 <- curve(p_s72, ns72, "S72_", g72); cv24 <- curve(p_s24, ns24, "S24_", g24)

## 百分位 OR
for (w in c("72","24")) {
  xs <- if (w == "72") f$fb else f$fb24
  cv <- if (w == "72") cv72 else cv24
  qs <- quantile(xs, c(.10,.25,.50,.75,.90))
  idx <- sapply(qs, function(q) which.min(abs(cv$x - q)))
  line(sprintf("== %sh percentile OR ==", w))
  for (k in seq_along(qs)) line(sprintf("  %.1f mL/kg: %.2f (%.2f-%.2f)", qs[k], cv$OR[idx[k]], cv$lcl[idx[k]], cv$ucl[idx[k]]))
}

## 交互
p_int <- pool(fitall(as.formula(paste("death30 ~ cong * fb10 +", c0))))
line(sprintf("interaction linear: OR=%.3f (%.3f-%.3f) p=%.3f", p_int$tab$OR[p_int$tab$term=="cong:fb10"],
             p_int$tab$lcl[p_int$tab$term=="cong:fb10"], p_int$tab$ucl[p_int$tab$term=="cong:fb10"], p_int$tab$p[p_int$tab$term=="cong:fb10"]))
p_ints <- pool(fitall(as.formula(paste("death30 ~ cong * (S72_1 + S72_2 + S72_3 + S72_4) +", c0))))
wi <- W(p_ints, c("cong:S72_1","cong:S72_2","cong:S72_3","cong:S72_4"))
line(sprintf("interaction spline: chi2=%.2f df=%d p=%.3f", wi[1], wi[2], wi[3]))

## 24h 四格
p24 <- pool(fitall(as.formula(paste("death30 ~ grp24 +", c0))))
print(p24$tab[p24$tab$term %in% c("grp24B","grp24C","grp24D"), c("term","OR","lcl","ucl","p")], digits=3, row.names=FALSE)

## 增量
pinc <- pool(fitall(as.formula(paste("death30 ~ S24_1 + S24_2 + S24_3 + S24_4 + SIN_1 + SIN_2 + SIN_3 + SIN_4 +", c0))))
w1 <- W(pinc, paste0("S24_", 1:4)); w2 <- W(pinc, paste0("SIN_", 1:4))
line(sprintf("increment model: first24 chi2=%.2f df=%d p=%.3f | increment chi2=%.2f df=%d p=%.3f",
             w1[1], w1[2], w1[3], w2[1], w2[2], w2[3]))

## 导出曲线供绘图
write.csv(rbind(data.frame(panel="72h", cv72), data.frame(panel="24h", cv24)),
          "v4/rcs_curves_final.csv", row.names = FALSE)
saveRDS(list(p1=p1,p2=p2,p24=p24,pinc=pinc,p_int=p_int,p_ints=p_ints,wi=wi,w1=w1,w2=w2), "v4/final_numbers.rds")
