setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(mice); library(pROC)})
set.seed(20261023)

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$has_note <- d$has_note %in% c("t", "TRUE", "True", TRUE)

mk <- function(dat, cong_col, fb_col = "fb72_mlkg") {
  dat <- dat[!is.na(dat[[cong_col]]) & !is.na(dat[[fb_col]]), ]
  dat$grp <- factor(ifelse(dat[[cong_col]] == 1,
                    ifelse(dat[[fb_col]] > 0, "D", "C"),
                    ifelse(dat[[fb_col]] > 0, "B", "A")), levels = c("A","B","C","D"))
  dat$fb10 <- dat[[fb_col]] / 10
  dat
}

pooled <- function(dat, f, m = 20) {
  vars <- unique(c(all.vars(f), "death30"))
  dat <- dat[, intersect(vars, names(dat))]
  imp <- mice(dat, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(f, data = complete(imp, i), family = binomial))
  b <- sapply(fits, coef); V <- lapply(fits, vcov)
  bb <- rowMeans(b); Tt <- Reduce("+", V)/m + (1 + 1/m)*cov(t(b))
  se <- sqrt(diag(Tt)); idx <- grep("^grp", rownames(b))
  W <- if (length(idx)) as.numeric(t(bb[idx]) %*% solve(Tt[idx,idx]) %*% bb[idx]) else NA
  out <- data.frame(term = rownames(b), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
  attr(out,"joint") <- c(chisq = W, df = length(idx),
                         p = ifelse(is.na(W), NA, pchisq(W, length(idx), lower.tail = FALSE)),
                         n = nrow(dat), deaths = sum(dat$death30))
  out
}

F <- death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd
row <- function(lbl, r) {
  s <- subset(r, grepl("^grp", term)); g <- function(t) { x <- s[s$term==t,]
    if (!nrow(x)) "—" else sprintf("%.2f (%.2f-%.2f)", x$OR, x$lcl, x$ucl) }
  data.frame(设定 = lbl, N = attr(r,"joint")["n"], 死亡 = attr(r,"joint")["deaths"],
             B = g("grpB"), C = g("grpC"), D = g("grpD"),
             p整体 = sprintf("%.2g", attr(r,"joint")["p"]), check.names = FALSE)
}

out <- list()
a <- mk(d, "cong_hybrid")
out[[1]] <- row("主分析（hybrid, 72h）", pooled(a, F))

out[[2]] <- row("S1 FINDINGS 优先", pooled(mk(d, "cong_s1"), F))

d2 <- d; d2$cong_s2 <- d2$cong_hybrid
d2$cong_s2[is.na(d2$cong_s2) & d2$has_note] <- 0
out[[3]] <- row("S2 unknown 计为阴性", pooled(mk(d2, "cong_s2"), F))

out[[4]] <- row("S5 仅正位片", pooled(a[a$frontal == 1, ], F))

out[[5]] <- row("S6 24h 液体窗口", pooled(mk(d, "cong_hybrid", "fb24_mlkg"), F))

out[[6]] <- row("S11 院内死亡", {
  b <- a; b$death30 <- b$death_hosp
  pooled(b, F)
})

cat("\n===== 灵敏度汇总 =====\n")
tab <- do.call(rbind, out); print(tab, row.names = FALSE)

# ---- S10: unknown 作为第三类 ----
cat("\n===== S10 unknown 作为独立类别 =====\n")
d3 <- d[d$has_note, ]
d3$grp5 <- ifelse(is.na(d3$cong_hybrid), "U",
            ifelse(!is.na(d3$fb72_mlkg),
              ifelse(d3$cong_hybrid == 1, ifelse(d3$fb72_mlkg > 0, "D", "C"),
                                            ifelse(d3$fb72_mlkg > 0, "B", "A")), NA))
d3 <- d3[!is.na(d3$grp5), ]
d3$grp <- factor(d3$grp5, levels = c("A","B","C","D","U"))
r10 <- pooled(d3, death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd)
print(subset(r10, grepl("^grp", term)), row.names = FALSE, digits = 3)
cat("N =", attr(r10,"joint")["n"], " deaths =", attr(r10,"joint")["deaths"], "\n")

# ---- 判别力 ----
cat("\n===== 判别力（完整病例，Model C）=====\n")
cc <- a[complete.cases(a[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
m0 <- glm(death30 ~ age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = cc, family = binomial)
m1 <- glm(F, data = cc, family = binomial)
p0 <- fitted(m0); p1 <- fitted(m1); y <- cc$death30
a0 <- as.numeric(auc(y, p0)); a1 <- as.numeric(auc(y, p1))
set.seed(1); dB <- replicate(1000, { i <- sample(nrow(cc), replace = TRUE)
  if (length(unique(y[i])) < 2) return(NA)
  c(as.numeric(auc(y[i], p0[i])) - as.numeric(auc(y[i], p1[i]))) })
dB <- dB[!is.na(dB)]
cat(sprintf("AUC base = %.4f, +淤血 = %.4f, delta = %+.4f (bootstrap 95%% CI %.4f to %.4f)\n",
            a0, a1, a1-a0, quantile(-dB, .025), quantile(-dB, .975)))
cat(sprintf("N = %d, deaths = %d\n", nrow(cc), sum(y)))

# 连续 NRI + IDI
pH <- function(p, y) mean(ifelse(y==1, 1-p, p))
nri_e <- mean(ifelse(y==1, p1>p0, p1<p0)) - mean(ifelse(y==1, p1<p0, p1>p0))
idi <- (pH(p1,y) - pH(p0,y)) - (pH(p0,y) - pH(p1,y))
cat(sprintf("连续 NRI = %.4f ; IDI = %.4f\n", nri_e, idi))
