setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
fb <- read.csv("data/fb_film.csv")
cs <- read.csv("data/code_status.csv")[, c("stay_id","dnr_24h")]
di <- read.csv("data/diuretic_by_stay.csv")
di$diu_post <- as.integer(di$loop_postfilm == 1 | di$tor_postfilm == 1)

m <- merge(f, fb[, c("stay_id","fb_film_mlkg")], by = "stay_id", all.x = TRUE)
m <- merge(m, cs, by = "stay_id", all.x = TRUE)
m <- merge(m, di[, c("stay_id","diu_post")], by = "stay_id", all.x = TRUE)
m$dnr_24h[is.na(m$dnr_24h)] <- 0
m$diu_post[is.na(m$diu_post)] <- 0
m$fb <- m$fb_film_mlkg
m$grp2 <- factor(ifelse(m$cong_hybrid == 1, ifelse(m$fb > 0, "D", "C"), ifelse(m$fb > 0, "B", "A")), levels = c("A","B","C","D"))
m$fb10 <- m$fb/10

cat("N =", nrow(m), " deaths =", sum(m$death30), sprintf(" (%.1f%%)\n", 100*mean(m$death30)))
cat("\n== group sizes / mortality ==\n")
print(cbind(n = table(m$grp2), deaths = tapply(m$death30, m$grp2, sum),
            pct = round(100*tapply(m$death30, m$grp2, mean), 1)))

cat("\n== Table 1 ==\n")
smd_c <- function(x, g, r) { m1<-mean(x[g],na.rm=TRUE); m0<-mean(x[r],na.rm=TRUE)
  s1<-sd(x[g],na.rm=TRUE); s0<-sd(x[r],na.rm=TRUE); (m1-m0)/sqrt((s1^2+s0^2)/2) }
smd_b <- function(x, g, r) { p1<-mean(x[g]==1,na.rm=TRUE); p0<-mean(x[r]==1,na.rm=TRUE)
  (p1-p0)/sqrt((p1*(1-p1)+p0*(1-p0))/2) }
mi <- function(x) sprintf("%.1f (%.1f-%.1f)", median(x,na.rm=TRUE), quantile(x,.25,na.rm=TRUE), quantile(x,.75,na.rm=TRUE))
pc <- function(x) sprintf("%d (%.1f)", sum(x==1,na.rm=TRUE), 100*mean(x==1,na.rm=TRUE))
I <- lapply(c("A","B","C","D"), function(g) which(m$grp2==g)); names(I) <- c("A","B","C","D")
for (v in c("age","sofa_score","lac","fb")) cat(sprintf("%-12s %s | %s | %s | %s || %.2f %.2f %.2f\n", v,
  mi(m[[v]][I$A]), mi(m[[v]][I$B]), mi(m[[v]][I$C]), mi(m[[v]][I$D]),
  smd_c(m[[v]],I$B,I$A), smd_c(m[[v]],I$C,I$A), smd_c(m[[v]],I$D,I$A)))
for (v in c("female","vent24","vaso24","hf","ckd","death30")) cat(sprintf("%-12s %s | %s | %s | %s || %.2f %.2f %.2f\n", v,
  pc(m[[v]][I$A]), pc(m[[v]][I$B]), pc(m[[v]][I$C]), pc(m[[v]][I$D]),
  smd_b(m[[v]],I$B,I$A), smd_b(m[[v]],I$C,I$A), smd_b(m[[v]],I$D,I$A)))

c0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
vars <- c("death30","grp2","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(m[, vars], m = 20, printFlag = FALSE)
bases <- lapply(1:20, function(i) { d <- complete(imp,i); d$fb10 <- m$fb10; d$dnr <- m$dnr_24h; d })
pool <- function(fits) { B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1+1/length(fits))*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term=names(b), OR=exp(b), lcl=exp(b-1.96*se), ucl=exp(b+1.96*se), p=2*pnorm(-abs(b/se))) }
sh <- function(p, ts) for (t in ts) cat(sprintf("  %-8s %.2f (%.2f-%.2f) p=%.3f\n", t, p$OR[p$term==t], p$lcl[p$term==t], p$ucl[p$term==t], p$p[p$term==t]))

cat("\n== main model ==\n")
p1 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp2 +", c0)), data=d, family=binomial)))
sh(p1, c("grp2B","grp2C","grp2D"))
cat("\n== + continuous balance ==\n")
p2 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp2 + fb10 +", c0)), data=d, family=binomial)))
sh(p2, c("grp2B","grp2C","grp2D","fb10"))
cat("\n== + DNR within 24h ==\n")
p3 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp2 + dnr +", c0)), data=d, family=binomial)))
sh(p3, c("grp2B","grp2C","grp2D","dnr"))

cat("\n== diuretics after film by new group ==\n")
for (g in c("A","B","C","D")) { s <- m[m$grp2==g,]
  cat(sprintf("  %s: %d/%d = %.1f%%\n", g, sum(s$diu_post), nrow(s), 100*mean(s$diu_post))) }
