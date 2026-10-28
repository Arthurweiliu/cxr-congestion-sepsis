setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
f$grp <- factor(f$grp, levels = c("A","B","C","D"))
d <- read.csv("data/diuretic_by_stay.csv")
d$diu_post <- as.integer(d$loop_postfilm == 1 | d$tor_postfilm == 1)
d$diu_any  <- as.integer(d$loop_any == 1 | d$tor_any == 1)
m <- merge(f, d[, c("stay_id","film_offset_h","diu_post","diu_any")], by = "stay_id", all.x = TRUE)
cat("n =", nrow(m), " missing offset =", sum(is.na(m$film_offset_h)), "\n")

q <- quantile(m$film_offset_h, c(.1,.25,.5,.75,.9), na.rm = TRUE)
cat(sprintf("film offset (h): P10 %.1f P25 %.1f median %.1f P75 %.1f P90 %.1f\n", q[1],q[2],q[3],q[4],q[5]))
cat(sprintf("film at/before admission: %d (%.1f%%); after: %d (%.1f%%); after >24h: %d\n",
  sum(m$film_offset_h <= 0, na.rm=TRUE), 100*mean(m$film_offset_h <= 0, na.rm=TRUE),
  sum(m$film_offset_h > 0, na.rm=TRUE), 100*mean(m$film_offset_h > 0, na.rm=TRUE),
  sum(m$film_offset_h > 24, na.rm=TRUE)))

cat("\n== 72-h balance by group and post-film diuretic (median, IQR) ==\n")
for (g in c("A","B","C","D")) {
  s <- m[m$grp == g, ]
  a <- s$fb72_mlkg[s$diu_post == 1]; b <- s$fb72_mlkg[s$diu_post == 0]
  cat(sprintf("%s treated n=%d %.1f (%.1f to %.1f) | untreated n=%d %.1f (%.1f to %.1f)\n",
      g, length(a), median(a), quantile(a,.25), quantile(a,.75), length(b), median(b), quantile(b,.25), quantile(b,.75)))
}

cat("\n== adjusted odds of post-film diuretic by group ==\n")
vars <- c("diu_post","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(m[, vars], m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(diu_post ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                     data = complete(imp, i), family = binomial))
B <- sapply(fits, coef); b <- rowMeans(B)
T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se <- sqrt(diag(T))
for (t in c("grpB","grpC","grpD")) cat(sprintf("  %s: OR %.2f (%.2f-%.2f)\n", t, exp(b[t]), exp(b[t]-1.96*se[t]), exp(b[t]+1.96*se[t])))

cat("\n== sensitivity: mortality model restricted to film at/before admission ==\n")
sub <- m[!is.na(m$film_offset_h) & m$film_offset_h <= 0, ]
cat("n =", nrow(sub), " deaths =", sum(sub$death30), "\n")
vars2 <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp2 <- mice(sub[, vars2], m = 20, printFlag = FALSE)
fits2 <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd,
                                      data = complete(imp2, i), family = binomial))
B2 <- sapply(fits2, coef); b2 <- rowMeans(B2)
T2 <- Reduce("+", lapply(fits2, vcov))/20 + (1+1/20)*cov(t(B2)); se2 <- sqrt(diag(T2))
for (t in c("grpB","grpC","grpD")) cat(sprintf("  %s: OR %.2f (%.2f-%.2f)\n", t, exp(b2[t]), exp(b2[t]-1.96*se2[t]), exp(b2[t]+1.96*se2[t])))
write.csv(m[, c("stay_id","grp","film_offset_h","diu_post","diu_any","fb72_mlkg","death30")], "v4/film_diuretic_merged.csv", row.names = FALSE)
