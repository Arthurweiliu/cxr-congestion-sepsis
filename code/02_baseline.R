setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/base.csv", stringsAsFactors = FALSE)

cat("=== 三种定义的可分类数 ===\n")
cat(sprintf("strict(IMPRESSION only) : %d\n", sum(!is.na(d$cong_primary))))
cat(sprintf("hybrid(IMPRESSION>FINDINGS): %d\n", sum(!is.na(d$cong_hybrid))))
cat(sprintf("S1(FINDINGS-first)       : %d\n", sum(!is.na(d$cong_s1))))
cat(sprintf("hybrid vs S1 不同      : %d\n", sum(d$cong_hybrid != d$cong_s1, na.rm = TRUE)))
cat(sprintf("hybrid vs strict 不同  : %d\n", sum(d$cong_hybrid != d$cong_primary, na.rm = TRUE)))

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$fbpos <- as.integer(a$fb72_mlkg > 0)
a$grp <- ifelse(a$cong_hybrid == 1,
                ifelse(a$fbpos == 1, "D_cong+_FB+", "C_cong+_FB-"),
                ifelse(a$fbpos == 1, "B_cong-_FB+", "A_cong-_FB-"))
G <- c("A_cong-_FB-", "B_cong-_FB+", "C_cong+_FB-", "D_cong+_FB+")

cat("\n=== 主分析（hybrid）N =", nrow(a), " deaths =", sum(a$death30),
    sprintf("(%.1f%%)", 100*mean(a$death30)), "===\n")
print(table(a$grp))

cat("\n=== 基线（中位数 / %）===\n")
hdr <- sprintf("%-14s%10s%10s%10s%10s", "var", "A", "B", "C", "D"); cat(hdr, "\n")
for (v in c("age","sofa_score","lactate_max","fb72_mlkg","cci")) {
  cat(sprintf("%-14s", v))
  for (g in G) cat(sprintf("%10.1f", median(a[[v]][a$grp==g], na.rm=TRUE)))
  cat("\n")
}
for (v in c("female","vaso24","vent24","hf","ckd","death30")) {
  cat(sprintf("%-14s", v))
  for (g in G) cat(sprintf("%10.1f", 100*mean(a[[v]][a$grp==g], na.rm=TRUE)))
  cat("\n")
}
cat(sprintf("%-14s%10d%10d%10d%10d\n", "n", sum(a$grp=="A_cong-_FB-"), sum(a$grp=="B_cong-_FB+"),
            sum(a$grp=="C_cong+_FB-"), sum(a$grp=="D_cong+_FB+")))
cat("\n=== 粗 OR（vs A）===\n")
f <- glm(death30 ~ factor(grp, levels=G), data=a, family=binomial)
print(round(exp(cbind(coef(f), confint.default(f))), 2))
cat("\n=== S9：排除 output_complete=0 后 ===\n")
b <- a[a$output_complete==1, ]
cat("N =", nrow(b), " deaths =", sum(b$death30), "\n")
print(round(100*tapply(b$death30, b$grp, mean), 1))

cat("\n=== S4：排除心衰后 ===\n")
c4 <- a[a$hf==0, ]
cat("N =", nrow(c4), " deaths =", sum(c4$death30), "\n")
print(round(100*tapply(c4$death30, c4$grp, mean), 1))
