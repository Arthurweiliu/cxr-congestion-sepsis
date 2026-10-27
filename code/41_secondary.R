setwd("F:/openclaw_workspace/CXR_congestion")
f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
v <- read.csv("data/vent28.csv", stringsAsFactors = FALSE)
f <- merge(f, v, by = "stay_id", all.x = TRUE)
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

f$vfd <- pmax(0, 28 - ifelse(is.na(f$vent_days), 0, f$vent_days))
f$vfd[f$death30 == 1] <- 0
f$death90 <- as.integer(f$death90)

cat("N =", nrow(f), "\n")
cat("\n90-day deaths by group:\n")
print(data.frame(n = table(f$grp),
                 d90 = tapply(f$death90, f$grp, sum),
                 pct = round(100 * tapply(f$death90, f$grp, mean), 1)))
cat("\nICU LOS median (IQR) by group:\n")
print(round(tapply(f$los, f$grp, median), 1))
print(round(tapply(f$los, f$grp, quantile, c(.25,.75)), 1))
cat("\nVentilator-free days median (IQR) by group:\n")
print(round(tapply(f$vfd, f$grp, median), 1))
print(round(tapply(f$vfd, f$grp, quantile, c(.25,.75)), 1))

cat("\n90-day mortality crude OR vs A:\n")
m <- glm(death90 ~ grp, data = f, family = binomial)
print(round(exp(cbind(OR = coef(m), confint.default(m))), 3))
