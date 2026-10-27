## 63_v4_extension.R — v4 扩展分析
## 目的：①液体平衡非线性（RCS）②影像×平衡交互的正式检验 ③24h/72h 时间窗依赖 + 增量模型
## 数据：data/final_with_lac.csv（n=3,963；lac 缺失 464）
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(pROC) })
set.seed(20261025)
options(stringsAsFactors = FALSE)

f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A", "B", "C", "D"))
f$fb   <- f$fb72_mlkg
f$fb24 <- f$fb24_mlkg
f$inc  <- f$fb - f$fb24              # 24h -> 72h 增量
f$fb10   <- f$fb / 10
f$fb2410 <- f$fb24 / 10
f$inc10  <- f$inc / 10
f$cong <- as.integer(f$cong_hybrid)

covs <- c("age", "female", "sofa_score", "lac", "vent24", "vaso24", "hf", "ckd")
dat <- f[, c("death30", "grp", "cong", "fb10", "fb2410", "inc10", covs)]
cat("N =", nrow(dat), " deaths =", sum(dat$death30), sprintf("(%.1f%%)\n", 100 * mean(dat$death30)))

## ---------- 基函数（fb 完整，故可全局固定，保证各插补集可合并） ----------
ns72  <- ns(f$fb,   df = 4)
ns24  <- ns(f$fb24, df = 4)
nsinc <- ns(f$inc,  df = 4)
B72 <- as.data.frame(unclass(ns72));  names(B72) <- paste0("S72_", 1:4)
B24 <- as.data.frame(unclass(ns24));  names(B24) <- paste0("S24_", 1:4)
BIN <- as.data.frame(unclass(nsinc)); names(BIN) <- paste0("SIN_", 1:4)
dat <- cbind(dat, B72, B24, BIN)

## ---------- 多重插补（仅对原始变量插补；样条基函数插补后附加，避免共线性） ----------
imp_vars <- c("death30", "grp", "cong", "fb10", "fb2410", "inc10", covs)
imp <- mice(dat[, imp_vars], m = 20, printFlag = FALSE)
cat("imputations:", imp$m, "\n")
if (!is.null(imp$loggedEvents)) {
  cat("logged events (unique methods):\n")
  print(unique(imp$loggedEvents[, c("meth", "out")]))
}

pool_fits <- function(fits) {
  B <- sapply(fits, coef)
  b <- rowMeans(B)
  W <- Reduce("+", lapply(fits, vcov)) / length(fits)
  T <- W + (1 + 1 / length(fits)) * cov(t(B))
  se <- sqrt(diag(T))
  list(b = b, T = T, se = se,
       tab = data.frame(term = names(b), est = b, se = se,
                        OR = exp(b), lcl = exp(b - 1.96 * se), ucl = exp(b + 1.96 * se),
                        p = 2 * pnorm(-abs(b / se)), row.names = NULL))
}
wald_joint <- function(pf, terms) {
  idx <- which(names(pf$b) %in% terms)
  b <- pf$b[idx]; Tm <- pf$T[idx, idx]
  W <- as.numeric(t(b) %*% solve(Tm) %*% b)
  c(chi2 = W, df = length(idx), p = pchisq(W, length(idx), lower.tail = FALSE))
}
fmt_or <- function(o, l, u) sprintf("%.2f (%.2f-%.2f)", o, l, u)
fmt_p  <- function(p) ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))

bases <- list()
for (i in 1:imp$m) bases[[i]] <- cbind(complete(imp, i), B72, B24, BIN)

fit_all <- function(form) lapply(bases, function(d) glm(form, data = d, family = binomial))

## ---------- 1. 复现主模型 ----------
f_grp <- fit_all(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
p_grp <- pool_fits(f_grp)
cat("\n[1] 主模型复现（组 vs A）\n")
print(p_grp$tab[p_grp$tab$term %in% c("grpB", "grpC", "grpD"), ], digits = 3, row.names = FALSE)
cat("joint:", sprintf("chi2=%.1f df=%d p=%.3g", wald_joint(p_grp, c("grpB", "grpC", "grpD"))[1],
                      3, wald_joint(p_grp, c("grpB", "grpC", "grpD"))[3]), "\n")

## ---------- 2. 非线性：样条 vs 线性（LR，逐插补，报中位与范围） ----------
lr_test <- function(f_lin, f_spl) {
  out <- mapply(function(a, b) {
    d <- as.numeric(2 * (as.numeric(logLik(b)) - as.numeric(logLik(a))))
    c(chi2 = d, df = attr(logLik(b), "df") - attr(logLik(a), "df"),
      p = pchisq(d, attr(logLik(b), "df") - attr(logLik(a), "df"), lower.tail = FALSE))
  }, f_lin, f_spl)
  c(chi2 = median(out["chi2", ]), df = median(out["df", ]),
    p = median(out["p", ]), p_min = min(out["p", ]), p_max = max(out["p", ]))
}

m_lin72 <- fit_all(death30 ~ cong + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_spl72 <- fit_all(death30 ~ cong + S72_1 + S72_2 + S72_3 + S72_4 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_lin24 <- fit_all(death30 ~ cong + fb2410 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_spl24 <- fit_all(death30 ~ cong + S24_1 + S24_2 + S24_3 + S24_4 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)

L72 <- lr_test(m_lin72, m_spl72)
L24 <- lr_test(m_lin24, m_spl24)
cat("\n[2] 非线性 LR 检验\n")
cat(sprintf("72h: chi2=%.2f df=%d p=%.4f (范围 %.4f-%.4f)\n", L72[1], L72[2], L72[3], L72[4], L72[5]))
cat(sprintf("24h: chi2=%.2f df=%d p=%.4f (范围 %.4f-%.4f)\n", L24[1], L24[2], L24[3], L24[4], L24[5]))

## 样条 OR 曲线（相对 fb=0）
or_curve <- function(pf, nsobj, prefix, grid) {
  Bnew <- predict(nsobj, grid)
  B0   <- predict(nsobj, 0)
  idx  <- which(names(pf$b) %in% paste0(prefix, 1:ncol(Bnew)))
  b <- pf$b[idx]; Tm <- pf$T[idx, idx]
  C <- sweep(Bnew, 2, as.numeric(B0), "-")   # 每行 = B(x)-B(0)
  lp <- as.numeric(C %*% b)
  se <- sqrt(rowSums((C %*% Tm) * C))
  data.frame(x = grid, OR = exp(lp), lcl = exp(lp - 1.96 * se), ucl = exp(lp + 1.96 * se))
}
p_spl72 <- pool_fits(m_spl72); p_spl24 <- pool_fits(m_spl24)
p_splinc <- pool_fits(fit_all(death30 ~ SIN_1 + SIN_2 + SIN_3 + SIN_4 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd))

g72 <- seq(max(-40, quantile(f$fb, .01)), quantile(f$fb, .99), length.out = 200)
g24 <- seq(max(-40, quantile(f$fb24, .01)), quantile(f$fb24, .99), length.out = 200)
cv72 <- or_curve(p_spl72, ns72, "S72_", g72)
cv24 <- or_curve(p_spl24, ns24, "S24_", g24)

qs <- c(.10, .25, .50, .75, .90)
tab_pt <- rbind(
  data.frame(window = "72h", stat = "OR curve", x = round(quantile(f$fb, qs), 1),
             OR = cv72$OR[findInterval(quantile(f$fb, qs), cv72$x)],
             lcl = cv72$lcl[findInterval(quantile(f$fb, qs), cv72$x)],
             ucl = cv72$ucl[findInterval(quantile(f$fb, qs), cv72$x)]),
  data.frame(window = "24h", stat = "OR curve", x = round(quantile(f$fb24, qs), 1),
             OR = cv24$OR[findInterval(quantile(f$fb24, qs), cv24$x)],
             lcl = cv24$lcl[findInterval(quantile(f$fb24, qs), cv24$x)],
             ucl = cv24$ucl[findInterval(quantile(f$fb24, qs), cv24$x)])
)
cat("\n样条 OR（相对平衡=0，各百分位）：\n"); print(tab_pt, digits = 3, row.names = FALSE)

## ---------- 3. 交互的正式检验 ----------
m_int  <- fit_all(death30 ~ cong * fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_ints <- fit_all(death30 ~ cong * (S72_1 + S72_2 + S72_3 + S72_4) + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
p_int  <- pool_fits(m_int); p_ints <- pool_fits(m_ints)
int_terms <- c("cong:fb10")
cat("\n[3] 交互检验\n")
print(p_int$tab[p_int$tab$term %in% int_terms, c("term","OR","lcl","ucl","p")], digits = 3, row.names = FALSE)
w_ints <- wald_joint(p_ints, c("cong:S72_1", "cong:S72_2", "cong:S72_3", "cong:S72_4"))
cat(sprintf("样条交互联合: chi2=%.2f df=%d p=%.3f\n", w_ints[1], w_ints[2], w_ints[3]))

## ---------- 4. 时间窗依赖性 ----------
f$grp24 <- factor(ifelse(f$cong == 1, ifelse(f$fb24 > 0, "D", "C"),
                         ifelse(f$fb24 > 0, "B", "A")), levels = c("A","B","C","D"))
dat$grp24 <- f$grp24
imp_vars2 <- c("death30", "grp", "grp24", "cong", "fb10", "fb2410", "inc10", covs)
imp <- mice(dat[, imp_vars2], m = 20, printFlag = FALSE)   # 重建（含 grp24）
bases <- lapply(1:imp$m, function(i) cbind(complete(imp, i), B72, B24, BIN))

m_grp24 <- fit_all(death30 ~ grp24 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_cont72 <- fit_all(death30 ~ fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_cont24 <- fit_all(death30 ~ fb2410 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
m_inc    <- fit_all(death30 ~ S24_1 + S24_2 + S24_3 + S24_4 + SIN_1 + SIN_2 + SIN_3 + SIN_4 +
                      age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
p_grp24 <- pool_fits(m_grp24); p_c72 <- pool_fits(m_cont72); p_c24 <- pool_fits(m_cont24)
p_inc <- pool_fits(m_inc)

cat("\n[4] 24h 四格（vs A24）\n")
print(p_grp24$tab[p_grp24$tab$term %in% c("grp24B","grp24C","grp24D"), c("term","OR","lcl","ucl","p")], digits = 3, row.names = FALSE)
cat(sprintf("joint: chi2=%.1f p=%.3g\n", wald_joint(p_grp24, c("grp24B","grp24C","grp24D"))[1], wald_joint(p_grp24, c("grp24B","grp24C","grp24D"))[3]))
cat("\n连续项（每 10 mL/kg）:\n")
cat(sprintf("  72h: %s p=%s\n", fmt_or(p_c72$tab$OR[p_c72$tab$term=="fb10"], p_c72$tab$lcl[p_c72$tab$term=="fb10"], p_c72$tab$ucl[p_c72$tab$term=="fb10"]), fmt_p(p_c72$tab$p[p_c72$tab$term=="fb10"])))
cat(sprintf("  24h: %s p=%s\n", fmt_or(p_c24$tab$OR[p_c24$tab$term=="fb2410"], p_c24$tab$lcl[p_c24$tab$term=="fb2410"], p_c24$tab$ucl[p_c24$tab$term=="fb2410"]), fmt_p(p_c24$tab$p[p_c24$tab$term=="fb2410"])))
w_inc <- wald_joint(p_inc, c("SIN_1","SIN_2","SIN_3","SIN_4"))
w_fb24s <- wald_joint(p_inc, c("S24_1","S24_2","S24_3","S24_4"))
cat("\n增量模型（ns(24h)+ns(增量)）:\n")
cat(sprintf("  24h 部分联合: chi2=%.2f df=%d p=%.3f\n", w_fb24s[1], w_fb24s[2], w_fb24s[3]))
cat(sprintf("  增量部分联合: chi2=%.2f df=%d p=%.3f\n", w_inc[1], w_inc[2], w_inc[3]))

cat("\n[4b] 组效应在连续平衡校正后（72h）\n")
m_grp_fb <- fit_all(death30 ~ grp + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
p_grp_fb <- pool_fits(m_grp_fb)
print(p_grp_fb$tab[p_grp_fb$tab$term %in% c("grpB", "grpC", "grpD", "fb10"), c("term","OR","lcl","ucl","p")], digits = 3, row.names = FALSE)

## ---------- 5. 判别力（完全病例，n=3,499） ----------
cc <- dat[complete.cases(dat[, c("death30", covs)]), ]
cc <- cc[complete.cases(cc$fb10), ]
cat("\n[5] 判别力：完全病例 n =", nrow(cc), " deaths =", sum(cc$death30), "\n")
A0 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
A1 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cong, data = cc, family = binomial)
A2 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cong + fb10, data = cc, family = binomial)
A3 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + cong + S72_1 + S72_2 + S72_3 + S72_4, data = cc, family = binomial)
A4 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd + S72_1 + S72_2 + S72_3 + S72_4, data = cc, family = binomial)
pr <- lapply(list(A0, A1, A2, A3, A4), fitted)
au <- sapply(pr, function(p) as.numeric(auc(roc(cc$death30, p, quiet = TRUE))))
names(au) <- c("base", "base+cong", "base+cong+fb_lin", "base+cong+fb_spline", "base+fb_spline")
print(round(au, 4))

set.seed(7); B <- 500; idx <- seq_len(nrow(cc))
d_ab <- replicate(B, {
  s <- sample(idx, length(idx), TRUE)
  sapply(pr, function(p) as.numeric(auc(roc(cc$death30[s], p[s], quiet = TRUE))))
})
rownames(d_ab) <- names(au)
names(au) <- names(au)
cat(sprintf("dAUC cong over base        : %.4f (%.4f-%.4f)\n", au["base+cong"] - au["base"], quantile(d_ab["base+cong",] - d_ab["base",], .025), quantile(d_ab["base+cong",] - d_ab["base",], .975)))
cat(sprintf("dAUC cong over fb_spline   : %.4f (%.4f-%.4f)\n", au["base+cong+fb_spline"] - au["base+fb_spline"], quantile(d_ab["base+cong+fb_spline",] - d_ab["base+fb_spline",], .025), quantile(d_ab["base+cong+fb_spline",] - d_ab["base+fb_spline",], .975)))
cat(sprintf("dAUC fb_spline over linear : %.4f (%.4f-%.4f)\n", au["base+cong+fb_spline"] - au["base+cong+fb_lin"], quantile(d_ab["base+cong+fb_spline",] - d_ab["base+cong+fb_lin",], .025), quantile(d_ab["base+cong+fb_spline",] - d_ab["base+cong+fb_lin",], .975)))

## ---------- 6. 输出 ----------
dir.create("v4", showWarnings = FALSE)
write.csv(data.frame(panel = c(rep("72h", nrow(cv72)), rep("24h", nrow(cv24))),
                     x = c(cv72$x, cv24$x), OR = c(cv72$OR, cv24$OR),
                     lcl = c(cv72$lcl, cv24$lcl), ucl = c(cv72$ucl, cv24$ucl)),
          "v4/rcs_curves.csv", row.names = FALSE)

saveRDS(list(p_grp = p_grp, p_grp24 = p_grp24, p_int = p_int, p_ints = p_ints,
             p_c72 = p_c72, p_c24 = p_c24, p_inc = p_inc, p_grp_fb = p_grp_fb,
             L72 = L72, L24 = L24, w_ints = w_ints, w_inc = w_inc, w_fb24s = w_fb24s,
             au = au, d_ab = d_ab, tab_pt = tab_pt, n = nrow(f)),
        "v4/v4_objects.rds")
cat("\nDONE\n")
