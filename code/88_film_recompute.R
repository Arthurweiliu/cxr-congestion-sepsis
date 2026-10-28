setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(pROC) })
set.seed(20261023)

f <- read.csv("data/film_analysis.csv")
f <- merge(f, read.csv("data/fb24_film.csv"), by = "stay_id", all.x = TRUE)
f$fb <- f$fb72_mlkg; f$fb24 <- f$fb24_film; f$inc <- f$fb - f$fb24
f$fb10 <- f$fb/10; f$fb2410 <- f$fb24/10; f$inc10 <- f$inc/10
f$cong <- as.integer(f$cong_hybrid)

c0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
vars <- c("death30","grp","cong","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
n72 <- ns(f$fb, df=4); n24 <- ns(f$fb24, df=4); nin <- ns(f$inc, df=4)
mk <- function(m,p){d<-as.data.frame(unclass(m));names(d)<-paste0(p,1:ncol(d));d}
bases <- lapply(1:20, function(i) cbind(complete(imp,i), fb10=f$fb10, fb2410=f$fb2410, inc10=f$inc10,
                                        mk(n72,"S72_"), mk(n24,"S24_"), mk(nin,"SIN_")))
pool <- function(fits){B<-sapply(fits,coef);b<-rowMeans(B)
  T<-Reduce("+",lapply(fits,vcov))/length(fits)+(1+1/length(fits))*cov(t(B));se<-sqrt(diag(T))
  list(b=b,T=T,tab=data.frame(term=names(b),OR=exp(b),lcl=exp(b-1.96*se),ucl=exp(b+1.96*se),p=2*pnorm(-abs(b/se))))}
W <- function(pf,ts){i<-which(names(pf$b)%in%ts);b<-pf$b[i];V<-pf$T[i,i];x<-as.numeric(t(b)%*%solve(V)%*%b);c(chi2=x,df=length(i),p=pchisq(x,length(i),lower.tail=FALSE))}

lr <- function(extra, base_f){
  r <- sapply(bases, function(d){m0<-glm(as.formula(paste("death30 ~",base_f)),data=d,family=binomial)
    m1<-glm(as.formula(paste("death30 ~",base_f,"+",extra)),data=d,family=binomial)
    c(2*(as.numeric(logLik(m1))-as.numeric(logLik(m0))), attr(logLik(m1),"df")-attr(logLik(m0),"df"))})
  p <- pchisq(r[1,], r[2,], lower.tail=FALSE)
  c(chi2=median(r[1,]), df=median(r[2,]), p=median(p))
}
cat("spline 72h vs linear: ", paste(round(lr("S72_1 + S72_2 + S72_3 + S72_4", paste("cong + fb10 +", c0)),3), collapse=" "), "\n")
cat("spline 24h vs linear: ", paste(round(lr("S24_1 + S24_2 + S24_3 + S24_4", paste("cong + fb2410 +", c0)),3), collapse=" "), "\n")

p_int <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ cong*fb10 +", c0)), data=d, family=binomial)))
cat(sprintf("interaction linear: OR %.3f (%.3f-%.3f) p=%.3f\n", p_int$tab$OR[p_int$tab$term=="cong:fb10"], p_int$tab$lcl[p_int$tab$term=="cong:fb10"], p_int$tab$ucl[p_int$tab$term=="cong:fb10"], p_int$tab$p[p_int$tab$term=="cong:fb10"]))
p_is <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ cong*(S72_1+S72_2+S72_3+S72_4) +", c0)), data=d, family=binomial)))
w <- W(p_is, c("cong:S72_1","cong:S72_2","cong:S72_3","cong:S72_4"))
cat(sprintf("interaction spline: chi2=%.2f df=%d p=%.3f\n", w[1], w[2], w[3]))

p_inc <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ S24_1+S24_2+S24_3+S24_4+SIN_1+SIN_2+SIN_3+SIN_4 +", c0)), data=d, family=binomial)))
w1 <- W(p_inc, paste0("S24_",1:4)); w2 <- W(p_inc, paste0("SIN_",1:4))
cat(sprintf("increment model: first24 chi2=%.2f p=%.3f | increment chi2=%.2f p=%.3f\n", w1[1], w1[3], w2[1], w2[3]))

cc <- f[complete.cases(f[, c("death30","fb","cong","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
B72 <- mk(ns(cc$fb, df=4), "Q"); cc <- cbind(cc, B72)
m0 <- glm(as.formula(paste("death30 ~", c0, "+ Q1+Q2+Q3+Q4")), data=cc, family=binomial)
m1 <- glm(as.formula(paste("death30 ~ cong +", c0, "+ Q1+Q2+Q3+Q4")), data=cc, family=binomial)
m2 <- glm(as.formula(paste("death30 ~ grp +", c0)), data=cc, family=binomial)
m3 <- glm(as.formula(paste("death30 ~", c0)), data=cc, family=binomial)
a <- function(m) as.numeric(auc(roc(cc$death30, fitted(m), quiet=TRUE)))
cat(sprintf("AUC base %.4f | +balance %.4f | +balance+cong %.4f | base+4grp %.4f\n", a(m3), a(m0), a(m1), a(m2)))
cat(sprintf("dAUC cong over balance %.4f | dAUC 4grp over base %.4f\n", a(m1)-a(m0), a(m2)-a(m3)))
