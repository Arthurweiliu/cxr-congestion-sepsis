setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

b <- read.csv("data/base.csv", stringsAsFactors = FALSE)
b$intime <- as.POSIXct(b$intime, tz = "UTC")
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]

m <- merge(b[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
h <- m$charttime >= m$intime - 6*3600 & m$charttime < m$intime + 24*3600
s <- tapply(m$valuenum[h], m$stay_id[h], max)
b$lac_lab <- as.numeric(s[as.character(b$stay_id)])

a <- b[!is.na(b$cong_hybrid) & !is.na(b$fb72_mlkg) & !is.na(b$death30), ]
a$female <- as.integer(a$gender == "F")
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

cat("=== 覆盖率对比 ===\n")
cat(sprintf("bg-derived : %d (%.1f%%), missing %d\n", sum(!is.na(a$lac_any)), 100*mean(!is.na(a$lac_any)), sum(is.na(a$lac_any))))
cat(sprintf("labevents  : %d (%.1f%%), missing %d\n", sum(!is.na(a$lac_lab)), 100*mean(!is.na(a$lac_lab)), sum(is.na(a$lac_lab))))
cat("\n=== 缺失率按组（labevents） ===\n")
print(round(100*tapply(a$lac_lab, a$grp, function(x) mean(is.na(x))), 1))

run <- function(lacvar, m = 20) {
  dd <- data.frame(death30 = a$death30, grp = a$grp, age = a$age, female = a$female,
                   sofa = a$sofa_score, lac = a[[lacvar]], vent = a$vent24,
                   vaso = a$vaso24, hf = a$hf, ckd = a$ckd)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  bb <- rowMeans(sapply(fits, coef)); V <- Reduce("+", lapply(fits, vcov))/m
  se <- sqrt(diag(V + (1 + 1/m)*cov(t(sapply(fits, coef)))))
  out <- data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
  out[grepl("^grp|^lac", out$term), ]
}

cat("\n=== 主模型对比（Model C，MI m=20）===\n")
cat("\n-- 旧：bg 乳酸（68.3% 覆盖）--\n"); print(run("lac_any"), row.names = FALSE, digits = 3)
cat("\n-- 新：labevents 乳酸（88.3% 覆盖）--\n"); print(run("lac_lab"), row.names = FALSE, digits = 3)

write.csv(b, "data/base_v2_lab_lactate.csv", row.names = FALSE)
cat("\nwrote data/base_v2_lab_lactate.csv\n")
