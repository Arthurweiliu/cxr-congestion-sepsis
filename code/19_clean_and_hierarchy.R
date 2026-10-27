setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

b <- read.csv("data/base.csv", stringsAsFactors = FALSE)
b$intime <- as.POSIXct(b$intime, tz = "UTC")
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]

core <- b[!is.na(b$cong_hybrid) & !is.na(b$fb72_mlkg) & !is.na(b$death30), ]
m <- merge(core[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
m$dt <- as.numeric(difftime(m$charttime, m$intime, units = "hours"))

# L1: max in [-6, +24]
h1 <- m$dt >= -6 & m$dt < 24
l1 <- tapply(m$valuenum[h1], m$stay_id[h1], max)

# L2: nearest value in [-24, +72] when L1 missing
h2 <- m$dt >= -24 & m$dt <= 72
sub2 <- m[h2, ]; sub2$absdt <- abs(sub2$dt)
sub2 <- sub2[order(sub2$stay_id, sub2$absdt), ]
l2 <- sub2[!duplicated(sub2$stay_id), c("stay_id","valuenum")]
l2v <- setNames(l2$valuenum, l2$stay_id)

core$lac_L1 <- as.numeric(l1[as.character(core$stay_id)])
core$lac_L2 <- ifelse(is.na(core$lac_L1), as.numeric(l2v[as.character(core$stay_id)]), core$lac_L1)

cat("=== 乳酸提取层级覆盖 ===\n")
cat(sprintf("L1 (max -6~+24h)          : %d (%.1f%%), missing %d\n", sum(!is.na(core$lac_L1)), 100*mean(!is.na(core$lac_L1)), sum(is.na(core$lac_L1))))
cat(sprintf("L2 (+最近值 -24~+72h)     : %d (%.1f%%), missing %d\n", sum(!is.na(core$lac_L2)), 100*mean(!is.na(core$lac_L2)), sum(is.na(core$lac_L2))))

# ---- 数据清洗 ----
vad <- read.csv("data/vad_transplant_subjects.csv", stringsAsFactors = FALSE)$x
vad <- as.integer(read.csv("data/vad_transplant_subjects.csv", stringsAsFactors = FALSE)[[1]])
n0 <- nrow(core)
core$bad <- with(core,
  (!is.na(weight_admit) & (weight_admit < 20 | weight_admit > 300)) |
  (!is.na(fb72) & abs(fb72) > 20000) |
  (!is.na(fb72_mlkg) & (fb72_mlkg > 300 | fb72_mlkg < -100)) |
  subject_id %in% vad)
cat("\n=== 清洗排除 ===\n")
cat("VAD/移植:", sum(core$subject_id %in% vad), "\n")
cat("体重异常:", sum(!is.na(core$weight_admit) & (core$weight_admit < 20 | core$weight_admit > 300)), "\n")
cat("|FB|>20L :", sum(!is.na(core$fb72) & abs(core$fb72) > 20000), "\n")
cat("FB>300或<-100 mL/kg:", sum(!is.na(core$fb72_mlkg) & (core$fb72_mlkg > 300 | core$fb72_mlkg < -100)), "\n")
cat("合计排除(去重):", sum(core$bad), " 剩余:", n0 - sum(core$bad), "\n")

a <- core[!core$bad, ]
a$lac_L2[!is.na(a$lac_L2) & (a$lac_L2 < 0.5 | a$lac_L2 > 20)] <- NA
a$female <- as.integer(a$gender == "F")
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
cat("\n清洗后 N =", nrow(a), " deaths =", sum(a$death30),
    sprintf("(%.1f%%)\n", 100*mean(a$death30)))
print(table(a$grp))

run <- function(dat, lacvar, m = 20) {
  dd <- data.frame(death30 = dat$death30, grp = dat$grp, age = dat$age, female = dat$female,
                   sofa = dat$sofa_score, lac = dat[[lacvar]], vent = dat$vent24,
                   vaso = dat$vaso24, hf = dat$hf, ckd = dat$ckd)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B); se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/m + (1+1/m)*cov(t(B))))
  out <- data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
  out[grepl("^grp|^lac", out$term), ]
}

cat("\n=== 清洗后主模型（L2 乳酸）===\n")
print(run(a, "lac_L2"), row.names = FALSE, digits = 3)

write.csv(a, "data/analysis_clean.csv", row.names = FALSE)
cat("\nwrote data/analysis_clean.csv\n")
