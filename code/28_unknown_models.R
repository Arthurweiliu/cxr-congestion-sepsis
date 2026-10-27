setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

d <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$female <- as.integer(d$gender == "F")

L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
m <- merge(d[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
h <- m$charttime >= m$intime - 6*3600 & m$charttime < m$intime + 24*3600
s <- tapply(m$valuenum[h], m$stay_id[h], max)
d$lac <- as.numeric(s[as.character(d$stay_id)])
d$lac[d$lac < 0.5 | d$lac > 20] <- NA

runMI <- function(dat, m = 20) {
  dd <- data.frame(death30 = dat$death30, grp = dat$grp, age = dat$age, female = dat$female,
                   sofa = dat$sofa_score, lac = dat$lac, vent = dat$vent24, vaso = dat$vaso24,
                   hf = dat$hf, ckd = dat$ckd)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B)
  se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))))
  Tt <- Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B))
  idx <- grep("^grp", names(bb))
  W <- as.numeric(t(bb[idx]) %*% solve(Tt[idx, idx]) %*% bb[idx])
  out <- data.frame(term = names(bb)[idx], OR = exp(bb[idx]),
                    lcl = exp(bb[idx]-1.96*se[idx]), ucl = exp(bb[idx]+1.96*se[idx]))
  list(tab = out, n = nrow(dd), deaths = sum(dd$death30),
       p = pchisq(W, length(idx), lower.tail = FALSE))
}

# ---------- S2: unknown 计为阴性 ----------
s2 <- d
s2$cong2 <- ifelse(is.na(s2$cong_hybrid), 0, s2$cong_hybrid)
s2$grp <- factor(ifelse(s2$cong2 == 1, ifelse(s2$fb72_mlkg > 0, "D", "C"),
                        ifelse(s2$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
r2 <- runMI(s2)
cat("\n=== S2 unknown 计为阴性 ===\n")
cat(sprintf("N = %d, deaths = %d, joint p = %.3g\n", r2$n, r2$deaths, r2$p))
print(r2$tab, row.names = FALSE, digits = 3)
cat("组分布:\n"); print(table(s2$grp))

# ---------- S10: unknown 独立类别 ----------
s10 <- d
s10$grp <- factor(ifelse(is.na(s10$cong_hybrid), "U",
                  ifelse(s10$cong_hybrid == 1, ifelse(s10$fb72_mlkg > 0, "D", "C"),
                                                ifelse(s10$fb72_mlkg > 0, "B", "A"))),
                  levels = c("A","B","C","D","U"))
r10 <- runMI(s10)
cat("\n=== S10 unknown 独立类别 ===\n")
cat(sprintf("N = %d, deaths = %d, joint p = %.3g\n", r10$n, r10$deaths, r10$p))
print(r10$tab, row.names = FALSE, digits = 3)
cat("组分布与死亡率:\n"); print(data.frame(n = table(s10$grp), pct = round(100*tapply(s10$death30, s10$grp, mean),1)))
