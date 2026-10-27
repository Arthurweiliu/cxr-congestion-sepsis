setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

prep <- function(df, cong_col, fb_col = "fb72_mlkg") {
  df <- df[!is.na(df[[cong_col]]) & !is.na(df[[fb_col]]), ]
  df$grp <- factor(ifelse(df[[cong_col]] == 1, ifelse(df[[fb_col]] > 0, "D", "C"),
                          ifelse(df[[fb_col]] > 0, "B", "A")), levels = c("A","B","C","D"))
  df
}

runMI <- function(dat, lacvar = "lac", m = 20) {
  dd <- data.frame(death30 = dat$death30, grp = dat$grp, age = dat$age,
                   female = dat$female, sofa = dat$sofa_score, lac = dat[[lacvar]],
                   vent = dat$vent24, vaso = dat$vaso24, hf = dat$hf, ckd = dat$ckd)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B)
  se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))))
  idx <- grep("^grp", names(bb))
  Tm <- Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))
  W <- as.numeric(t(bb[idx]) %*% solve(Tm[idx, idx]) %*% bb[idx])
  data.frame(term = names(bb)[idx], OR = exp(bb[idx]), lcl = exp(bb[idx]-1.96*se[idx]),
             ucl = exp(bb[idx]+1.96*se[idx]), p = pchisq(W, length(idx), lower.tail = FALSE)[1],
             n = nrow(dd), deaths = sum(dd$death30))
}

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")

# L2 乳酸：L1 缺失时取 -24~+72h 最近值
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
m <- merge(f[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
m$dt <- as.numeric(difftime(m$charttime, m$intime, units = "hours"))
s2 <- m[m$dt >= -24 & m$dt <= 72, ]; s2$absdt <- abs(s2$dt)
s2 <- s2[order(s2$stay_id, s2$absdt), ]
L2 <- setNames(s2$valuenum[!duplicated(s2$stay_id)], s2$stay_id[!duplicated(s2$stay_id)])
f$lacL2 <- ifelse(is.na(f$lac), as.numeric(L2[as.character(f$stay_id)]), f$lac)

f <- prep(f, "cong_hybrid")
rows <- list()
add <- function(lbl, r) rows[[length(rows)+1]] <<- data.frame(
  设定 = lbl, N = r$n[1], 死亡 = r$deaths[1],
  B = sprintf("%.2f (%.2f-%.2f)", r$OR[1], r$lcl[1], r$ucl[1]),
  C = sprintf("%.2f (%.2f-%.2f)", r$OR[2], r$lcl[2], r$ucl[2]),
  D = sprintf("%.2f (%.2f-%.2f)", r$OR[3], r$lcl[3], r$ucl[3]),
  p整体 = sprintf("%.2g", r$p[1]), check.names = FALSE)

add("主分析", runMI(f))
add("S1 FINDINGS 优先", runMI(prep(f, "cong_s1")))
add("S3 72h 界标", {
  t72 <- f$intime + 3*86400
  alive <- is.na(f$deathtime) | as.POSIXct(ifelse(f$deathtime=="", NA, f$deathtime), tz="UTC") > t72
  runMI(f[alive, ])
})
add("S4 排除心衰", runMI(f[f$hf == 0, ]))
add("S5 仅正位片", runMI(f[f$frontal == 1, ]))
add("S6 24h 液体窗口", runMI(prep(f, "cong_hybrid", "fb24_mlkg")))
add("S9 输出完整", runMI(f[f$output_complete == 1, ]))
add("S12 严格 IMPRESSION", runMI(prep(f, "cong_primary")))
add("S15 L2 乳酸层级", runMI(f, "lacL2"))

b <- f; b$death30 <- b$death_hosp
add("S11 院内死亡", runMI(b))

# S16 不清洗队列
u <- read.csv("data/base_v2_lab_lactate.csv", stringsAsFactors = FALSE)
u$female <- as.integer(u$gender == "F")
u$lac <- u$lac_lab; u$lac[u$lac < 0.5 | u$lac > 20] <- NA
u <- prep(u, "cong_hybrid")
add("S16 不清洗（原始 4,352）", runMI(u))

tab <- do.call(rbind, rows)
print(tab, row.names = FALSE)
writeLines(enc2utf8(c("# Table S1. 敏感性分析（最终队列 S2）", "",
  "| 设定 | N | 死亡 | B | C | D | 整体 p |", "|---|---:|---:|---|---|---|---|",
  sprintf("| %s | %d | %d | %s | %s | %s | %s |", tab$设定, tab$N, tab$死亡, tab$B, tab$C, tab$D, tab$p整体))),
  con = file("tables/S1_final.md", "w", encoding = "UTF-8"))
cat("\nwritten tables/S1_final.md\n")
