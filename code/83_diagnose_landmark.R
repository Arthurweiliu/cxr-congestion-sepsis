setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
f <- read.csv("data/film_analysis.csv")
f$intime <- as.POSIXct(f$intime, tz = "UTC")
cat("n =", nrow(f), " grp:\n"); print(table(f$grp))
cat("\ndeathtime class:", class(f$deathtime), " non-empty:", sum(!is.na(f$deathtime) & f$deathtime != ""), "\n")
t72 <- f$intime + 3*86400
dt <- suppressWarnings(as.POSIXct(ifelse(is.na(f$deathtime) | f$deathtime == "", NA, f$deathtime), tz = "UTC"))
alive <- is.na(dt) | dt > t72
cat("alive at 72h:", sum(alive), " excluded:", sum(!alive), "\n")
sub <- f[alive, ]
cat("landmark grp:\n"); print(table(sub$grp))
cat("landmark events by grp:\n"); print(tapply(sub$death30, sub$grp, sum))

d <- sub[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]
d <- d[complete.cases(d), ]
cat("\ncomplete-case landmark n =", nrow(d), " events =", sum(d$death30), "\n")
print(table(d$grp)); print(tapply(d$death30, d$grp, sum))
m <- glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = d, family = binomial)
print(round(summary(m)$coefficients[, c("Estimate","Std. Error","z value")], 3))
cat("\nany fitted probability within 1e-6 of 0/1:", sum(fitted(m) < 1e-6 | fitted(m) > 1-1e-6), "\n")
