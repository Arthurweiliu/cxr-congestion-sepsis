setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))

u <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
u$intime <- as.POSIXct(u$intime, tz = "UTC")
u$female <- as.integer(u$gender == "F")
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
mm <- merge(u[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
h <- mm$charttime >= mm$intime - 6*3600 & mm$charttime < mm$intime + 24*3600
s <- tapply(mm$valuenum[h], mm$stay_id[h], max)
u$lac <- as.numeric(s[as.character(u$stay_id)])
u$lac[u$lac < 0.5 | u$lac > 20] <- NA

d <- merge(u, read.csv("data/fb_film_unknown.csv")[, c("stay_id","fb72_film")], by = "stay_id", all.x = TRUE)
d$exposure <- ifelse(is.na(d$cong_hybrid), "U",
  ifelse(d$cong_hybrid == 1, ifelse(d$fb72_film > 0, "D", "C"), ifelse(d$fb72_film > 0, "B", "A")))
d$exposure <- factor(d$exposure, levels = c("A","B","C","D","U"))
cat("N =", nrow(d), " deaths =", sum(d$death30), sprintf("(%.1f%%)\n", 100*mean(d$death30)))
print(cbind(n = table(d$exposure), deaths = tapply(d$death30, d$exposure, sum),
            pct = round(100*tapply(d$death30, d$exposure, mean), 1)))

cat("\n== Table 1 (5 groups) ==\n")
smd_c <- function(x,g,r){m1<-mean(x[g],na.rm=T);m0<-mean(x[r],na.rm=T);s1<-sd(x[g],na.rm=T);s0<-sd(x[r],na.rm=T);(m1-m0)/sqrt((s1^2+s0^2)/2)}
smd_b <- function(x,g,r){p1<-mean(x[g]==1,na.rm=T);p0<-mean(x[r]==1,na.rm=T);(p1-p0)/sqrt((p1*(1-p1)+p0*(1-p0))/2)}
mi <- function(x) sprintf("%.1f (%.1f-%.1f)", median(x,na.rm=T), quantile(x,.25,na.rm=T), quantile(x,.75,na.rm=T))
pc <- function(x) sprintf("%d (%.1f)", sum(x==1,na.rm=T), 100*mean(x==1,na.rm=T))
I <- lapply(c("A","B","C","D","U"), function(g) which(d$exposure==g)); names(I) <- c("A","B","C","D","U")
for (v in c("age","sofa_score","lac","fb72_film")) cat(sprintf("%-10s %s | %s | %s | %s | %s || %.2f %.2f %.2f %.2f\n", v,
  mi(d[[v]][I$A]),mi(d[[v]][I$B]),mi(d[[v]][I$C]),mi(d[[v]][I$D]),mi(d[[v]][I$U]),
  smd_c(d[[v]],I$B,I$A),smd_c(d[[v]],I$C,I$A),smd_c(d[[v]],I$D,I$A),smd_c(d[[v]],I$U,I$A)))
for (v in c("female","vent24","vaso24","hf","ckd","death30")) cat(sprintf("%-10s %s | %s | %s | %s | %s || %.2f %.2f %.2f %.2f\n", v,
  pc(d[[v]][I$A]),pc(d[[v]][I$B]),pc(d[[v]][I$C]),pc(d[[v]][I$D]),pc(d[[v]][I$U]),
  smd_b(d[[v]],I$B,I$A),smd_b(d[[v]],I$C,I$A),smd_b(d[[v]],I$D,I$A),smd_b(d[[v]],I$U,I$A)))
