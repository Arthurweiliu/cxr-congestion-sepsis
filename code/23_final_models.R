setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_cohort.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$female <- as.integer(f$gender == "F")

# labevents lactate (L1: max -6h..+24h)
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
m <- merge(f[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
h <- m$charttime >= m$intime - 6*3600 & m$charttime < m$intime + 24*3600
s <- tapply(m$valuenum[h], m$stay_id[h], max)
f$lac <- as.numeric(s[as.character(f$stay_id)])
f$lac[f$lac < 0.5 | f$lac > 20] <- NA

f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

cat("N =", nrow(f), " deaths =", sum(f$death30), sprintf("(%.1f%%)\n", 100*mean(f$death30)))
cat("lactate coverage:", sum(!is.na(f$lac)), sprintf("(%.1f%%)\n", 100*mean(!is.na(f$lac))))
print(table(f$grp))

vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
dat <- f[, vars]
imp <- mice(dat, m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                     data = complete(imp, i), family = binomial))
B <- sapply(fits, coef); bb <- rowMeans(B)
se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/20 + (1 + 1/20)*cov(t(B))))
out <- data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se),
                  p = 2*pnorm(-abs(bb/se)))
print(out[out$term != "(Intercept)", ], row.names = FALSE, digits = 3)

idx <- grep("^grp", names(bb))
Tm <- Reduce("+", lapply(fits, vcov))/20 + (1 + 1/20)*cov(t(B))
W <- as.numeric(t(bb[idx]) %*% solve(Tm[idx, idx]) %*% bb[idx])
cat("\njoint Wald chi2 =", sprintf("%.2f", W), " df =", length(idx),
    " p =", sprintf("%.3g", pchisq(W, length(idx), lower.tail = FALSE)), "\n")

# ---- Table 1 with SMD ----
smd_c <- function(x, g, r) { m1<-mean(x[g],na.rm=TRUE); m0<-mean(x[r],na.rm=TRUE)
  s1<-sd(x[g],na.rm=TRUE); s0<-sd(x[r],na.rm=TRUE); (m1-m0)/sqrt((s1^2+s0^2)/2) }
smd_b <- function(x, g, r) { p1<-mean(x[g]==1,na.rm=TRUE); p0<-mean(x[r]==1,na.rm=TRUE)
  (p1-p0)/sqrt((p1*(1-p1)+p0*(1-p0))/2) }
mi <- function(x) sprintf("%.1f (%.1f–%.1f)", median(x,na.rm=TRUE), quantile(x,.25,na.rm=TRUE), quantile(x,.75,na.rm=TRUE))
pc <- function(x) sprintf("%d (%.1f)", sum(x==1,na.rm=TRUE), 100*mean(x==1,na.rm=TRUE))
I <- lapply(c("A","B","C","D"), function(g) which(f$grp == g)); names(I) <- c("A","B","C","D")
lab <- c(age="Age, years", sofa_score="SOFA score", lac="Lactate, mmol/L", fb72_mlkg="72-h fluid balance, mL/kg",
         female="Female sex", vent24="Invasive ventilation, day 1", vaso24="Vasopressor use, day 1",
         hf="Heart failure", ckd="Chronic kidney disease", death30="30-day mortality")
L1 <- c("# Table 1. Baseline characteristics (final cohort)", "",
        sprintf("n = %d; 30-day deaths %d (%.1f%%)", nrow(f), sum(f$death30), 100*mean(f$death30)), "",
        sprintf("A n=%d; B n=%d; C n=%d; D n=%d", length(I$A), length(I$B), length(I$C), length(I$D)), "",
        "| Variable | A | B | C | D | SMD B | SMD C | SMD D |", "|---|---|---|---|---|---:|---:|---:|")
for (v in c("age","sofa_score","lac","fb72_mlkg")) {
  L1 <- c(L1, sprintf("| %s | %s | %s | %s | %s | %.2f | %.2f | %.2f |", lab[[v]],
    mi(f[[v]][I$A]), mi(f[[v]][I$B]), mi(f[[v]][I$C]), mi(f[[v]][I$D]),
    smd_c(f[[v]], I$B, I$A), smd_c(f[[v]], I$C, I$A), smd_c(f[[v]], I$D, I$A)))
}
for (v in c("female","vent24","vaso24","hf","ckd","death30")) {
  L1 <- c(L1, sprintf("| %s | %s | %s | %s | %s | %.2f | %.2f | %.2f |", lab[[v]],
    pc(f[[v]][I$A]), pc(f[[v]][I$B]), pc(f[[v]][I$C]), pc(f[[v]][I$D]),
    smd_b(f[[v]], I$B, I$A), smd_b(f[[v]], I$C, I$A), smd_b(f[[v]], I$D, I$A)))
}
writeLines(enc2utf8(L1), con = file("tables/T1_final.md", "w", encoding = "UTF-8"))

# ---- Table 2 ----
tl <- c("(Intercept)"="Intercept", grpB="Group B (no congestion / balance >0)",
        grpC="Group C (congestion / balance <=0)", grpD="Group D (congestion / balance >0)",
        age="Age, per year", female="Female sex", sofa_score="SOFA, per point",
        lac="Lactate, per mmol/L", vent24="Invasive ventilation, day 1",
        vaso24="Vasopressor use, day 1", hf="Heart failure", ckd="Chronic kidney disease")
r2 <- out[out$term != "(Intercept)", ]
L2 <- c("# Table 2. Adjusted association with 30-day mortality", "",
        sprintf("Multiple imputation (m=20); n = %d, deaths = %d", nrow(dat), sum(dat$death30)), "",
        "| Variable | OR | 95% CI | p |", "|---|---:|---|---:|")
for (i in seq_len(nrow(r2))) L2 <- c(L2, sprintf("| %s | %.2f | %.2f–%.2f | %.3f |",
    tl[[r2$term[i]]], r2$OR[i], r2$lcl[i], r2$ucl[i], r2$p[i]))
L2 <- c(L2, "", sprintf("Joint test across groups: chi-square = %.1f, df = 3, p < 0.001.", W))
writeLines(enc2utf8(L2), con = file("tables/T2_final.md", "w", encoding = "UTF-8"))
write.csv(f, "data/final_with_lac.csv", row.names = FALSE)
cat("\ntables written\n")
