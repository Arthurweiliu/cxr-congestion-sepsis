setwd("F:/openclaw_workspace/CXR_congestion")
f <- read.csv("data/final_with_lac.csv")
f$cong <- as.integer(f$cong_hybrid)
f$pos <- as.integer(f$fb72_mlkg > 0)
tab <- table(factor(f$cong, 0:1), factor(f$pos, 0:1))
print(tab)
n <- sum(tab)
po <- sum(diag(tab)) / n
pe <- sum(rowSums(tab) * colSums(tab)) / n^2
k <- (po - pe) / (1 - pe)
# Fleiss-Cohen asymptotic SE
p1 <- sum(diag(tab)) / n
se <- sqrt((p1 * (1 - p1)) / (n * (1 - pe)^2))
cat(sprintf("Po=%.4f Pe=%.4f kappa=%.4f SE=%.4f 95%%CI %.4f to %.4f\n", po, pe, k, se, k - 1.96*se, k + 1.96*se))
