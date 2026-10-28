setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)
f <- read.csv("data/film_analysis.csv")
d <- read.csv("data/diuretic_by_stay.csv")
d$diu <- as.integer(d$loop_postfilm == 1 | d$tor_postfilm == 1)
cs <- read.csv("data/code_status.csv")[, c("stay_id","dnr_24h")]
m <- merge(f, d[, c("stay_id","diu")], by = "stay_id", all.x = TRUE)
m <- merge(m, cs, by = "stay_id", all.x = TRUE)
m$diu[is.na(m$diu)] <- 0; m$dnr_24h[is.na(m$dnr_24h)] <- 0
m$fb10 <- m$fb72_mlkg/10
m$grp <- factor(m$grp, levels = c("A","B","C","D"))

cat("== diuretics by group ==\n")
for (g in c("A","B","C","D")) { s <- m[m$grp == g,]
  cat(sprintf("%s: %d/%d = %.1f%%\n", g, sum(s$diu), nrow(s), 100*mean(s$diu))) }
cat("\n== balance by treatment within group ==\n")
for (g in c("C","B")) { s <- m[m$grp == g,]
  cat(sprintf("%s treated %.1f vs untreated %.1f\n", g,
    median(s$fb72_mlkg[s$diu==1], na.rm=TRUE), median(s$fb72_mlkg[s$diu==0], na.rm=TRUE))) }
cat("\n== DNR prevalence ==\n"); print(table(m$dnr_24h))

pool <- function(fits) { B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1+1/length(fits))*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term=names(b), OR=exp(b), lcl=exp(b-1.96*se), ucl=exp(b+1.96*se)) }
vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(m[, vars], m = 20, printFlag = FALSE)
bases <- lapply(1:20, function(i) { dd <- complete(imp,i); dd$fb10 <- m$fb10; dd$diu <- m$diu; dd$dnr_24h <- m$dnr_24h; dd })
cat("\n== adjusted odds of diuretic use (C vs A) ==\n")
p1 <- pool(lapply(bases, function(dd) glm(diu ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data=dd, family=binomial)))
for (t in c("grpB","grpC","grpD")) cat(sprintf("  %s %.2f (%.2f-%.2f)\n", t, p1$OR[p1$term==t], p1$lcl[p1$term==t], p1$ucl[p1$term==t]))
cat("\n== mortality + DNR + balance ==\n")
p2 <- pool(lapply(bases, function(dd) glm(death30 ~ grp + dnr_24h + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data=dd, family=binomial)))
for (t in c("grpB","grpC","grpD","dnr_24h")) cat(sprintf("  %s %.2f (%.2f-%.2f)\n", t, p2$OR[p2$term==t], p2$lcl[p2$term==t], p2$ucl[p2$term==t]))
p3 <- pool(lapply(bases, function(dd) glm(death30 ~ grp + fb10 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data=dd, family=binomial)))
for (t in c("grpB","grpC","grpD","fb10")) cat(sprintf("  %s %.2f (%.2f-%.2f)\n", t, p3$OR[p3$term==t], p3$lcl[p3$term==t], p3$ucl[p3$term==t]))
