setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(pROC); library(car) })
set.seed(20261023)

f <- read.csv("data/film_analysis.csv")
di <- read.csv("data/diuretic_by_stay.csv")
dw <- read.csv("data/diu_win.csv")
cs <- read.csv("data/code_status.csv")[, c("stay_id","dnr_24h")]
m <- f
m$diu <- dw$diu_win[match(m$stay_id, dw$stay_id)]
m$film_offset_h <- di$film_offset_h[match(m$stay_id, di$stay_id)]
m$dnr_24h <- cs$dnr_24h[match(m$stay_id, cs$stay_id)]
m$diu[is.na(m$diu)] <- 0; m$dnr_24h[is.na(m$dnr_24h)] <- 0
m$fb10 <- m$fb72_mlkg/10
f <- m
f$grp <- factor(f$grp, levels = c("A","B","C","D"))

R <- list()
put <- function(k, v) R[[k]] <<- v

# counts
put("n_total", nrow(f)); put("n_deaths", sum(f$death30))
put("pct_deaths", round(100*mean(f$death30), 1))
put("n_cong", sum(f$cong_hybrid == 1)); put("pct_cong", round(100*mean(f$cong_hybrid == 1), 1))
for (g in c("A","B","C","D")) { put(paste0("n_", g), sum(f$grp == g)); put(paste0("pct_mort_", g), round(100*mean(f$death30[f$grp == g]), 1)) }

# kappa
tab <- table(factor(f$cong_hybrid, 0:1), factor(as.integer(f$fb72_mlkg > 0), 0:1))
n <- sum(tab); po <- sum(diag(tab))/n; pe <- sum(rowSums(tab)*colSums(tab))/n^2
kap <- (po-pe)/(1-pe); sek <- sqrt(po*(1-po)/(n*(1-pe)^2))
put("kappa", round(kap,3)); put("kappa_lcl", round(kap-1.96*sek,3)); put("kappa_ucl", round(kap+1.96*sek,3))
put("po", round(100*po,1)); put("pe", round(100*pe,1)); put("pabak", round(2*po-1,2))
put("ppos", round(2*tab[2,2]/(2*tab[2,2]+tab[1,2]+tab[2,1]),2))
put("pneg", round(2*tab[1,1]/(2*tab[1,1]+tab[1,2]+tab[2,1]),2))

# MI models
vars <- c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
bases <- lapply(1:20, function(i) { d <- complete(imp,i); d$fb10 <- f$fb10; d$dnr <- f$dnr_24h; d$diu <- f$diu; d$cong_hybrid <- f$cong_hybrid; d })
pool <- function(fits) {
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1+1/length(fits))*cov(t(B)); se <- sqrt(diag(T))
  data.frame(term = names(b), OR = exp(b), lcl = exp(b-1.96*se), ucl = exp(b+1.96*se), p = 2*pnorm(-abs(b/se)))
}
C0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
p1 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp +", C0)), data=d, family=binomial)))
p2 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp + fb10 +", C0)), data=d, family=binomial)))
p3 <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ grp + dnr +", C0)), data=d, family=binomial)))
for (g in c("B","C","D")) for (suf in c("","_bal","_dnr")) {
  p <- if (suf == "") p1 else if (suf == "_bal") p2 else p3
  t <- paste0("grp", g)
  put(paste0("or", g, suf), round(p$OR[p$term==t],2)); put(paste0("or", g, suf, "_lcl"), round(p$lcl[p$term==t],2)); put(paste0("or", g, suf, "_ucl"), round(p$ucl[p$term==t],2))
}
put("fb10_or", round(p2$OR[p2$term=="fb10"],2)); put("fb10_lcl", round(p2$lcl[p2$term=="fb10"],2)); put("fb10_ucl", round(p2$ucl[p2$term=="fb10"],2))
put("dnr_or", round(p3$OR[p3$term=="dnr"],2))

# diuretics
for (g in c("A","B","C","D")) put(paste0("diu_", g), round(100*mean(f$diu[f$grp==g]),1))
pd <- pool(lapply(bases, function(d) glm(diu ~ grp + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data=d, family=binomial)))
put("diu_orC", round(pd$OR[pd$term=="grpC"],2)); put("diu_orC_lcl", round(pd$lcl[pd$term=="grpC"],2)); put("diu_orC_ucl", round(pd$ucl[pd$term=="grpC"],2))

# discrimination
cc <- f[complete.cases(f[, c("death30","fb72_mlkg","cong_hybrid", "age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
B4 <- as.data.frame(unclass(ns(cc$fb72_mlkg, df=4))); names(B4) <- paste0("S",1:4); cc <- cbind(cc, B4)
m0 <- glm(death30 ~ age+female+sofa_score+lac+vent24+vaso24+hf+ckd+S1+S2+S3+S4, data=cc, family=binomial)
m1 <- glm(death30 ~ cong_hybrid+age+female+sofa_score+lac+vent24+vaso24+hf+ckd+S1+S2+S3+S4, data=cc, family=binomial)
m2 <- glm(death30 ~ grp + age+female+sofa_score+lac+vent24+vaso24+hf+ckd, data=cc, family=binomial)
m3 <- glm(death30 ~ age+female+sofa_score+lac+vent24+vaso24+hf+ckd, data=cc, family=binomial)
a <- function(mm) as.numeric(auc(roc(cc$death30, fitted(mm), quiet=TRUE)))
put("auc_base", round(a(m3),4)); put("auc_bal", round(a(m0),4)); put("auc_bal_cong", round(a(m1),4)); put("auc_4grp", round(a(m2),4))
put("dauc", round(a(m1)-a(m0),4))
set.seed(7); p0 <- fitted(m0); p1f <- fitted(m1); y <- cc$death30; nn <- nrow(cc)
d <- replicate(500, { s <- sample(nn, nn, TRUE); as.numeric(auc(roc(y[s], p1f[s], quiet=TRUE))) - as.numeric(auc(roc(y[s], p0[s], quiet=TRUE))) })
put("dauc_lcl", round(quantile(d,.025),4)); put("dauc_ucl", round(quantile(d,.975),4))
put("n_complete", nrow(cc))

# spline LR (MI), interaction, increment
lr <- function(extra, base_f) {
  r <- sapply(bases2, function(dd) {
    mm0 <- glm(as.formula(paste("death30 ~", base_f)), data=dd, family=binomial)
    mm1 <- glm(as.formula(paste("death30 ~", base_f, "+", extra)), data=dd, family=binomial)
    c(2*(as.numeric(logLik(mm1))-as.numeric(logLik(mm0))), attr(logLik(mm1),"df")-attr(logLik(mm0),"df"))
  })
  p <- pchisq(r[1,], r[2,], lower.tail=FALSE)
  c(median(r[1,]), median(r[2,]), median(p))
}
B72 <- as.data.frame(unclass(ns(f$fb72_mlkg, df=4))); names(B72) <- paste0("Q",1:4)
bases2 <- lapply(1:20, function(i) cbind(complete(imp,i), cong_hybrid = f$cong_hybrid, fb10 = f$fb10, B72))
l72 <- lr("Q1+Q2+Q3+Q4", paste("cong_hybrid + fb10 +", C0))
put("spline_chi2", round(l72[1],2)); put("spline_df", l72[2]); put("spline_p", round(l72[3],2))
pint <- pool(lapply(bases, function(d) glm(as.formula(paste("death30 ~ cong_hybrid*fb10 +", C0)), data=d, family=binomial)))
put("int_or", round(pint$OR[pint$term=="cong_hybrid:fb10"],3))
put("int_lcl", round(pint$lcl[pint$term=="cong_hybrid:fb10"],3))
put("int_ucl", round(pint$ucl[pint$term=="cong_hybrid:fb10"],3))
put("int_p", round(pint$p[pint$term=="cong_hybrid:fb10"],2))

# VIF + HL
d2 <- f[complete.cases(f[, c("death30","grp","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
mv <- glm(death30 ~ grp + age+female+sofa_score+lac+vent24+vaso24+hf+ckd, data=d2, family=binomial)
put("vif_max", round(max(car::vif(mv)[,1]),2))
pv <- fitted(mv); yv <- d2$death30; qv <- cut(pv, quantile(pv, 0:10/10), include.lowest=TRUE, labels=FALSE)
obs <- tapply(yv,qv,sum); exp_ <- tapply(pv,qv,sum); nq <- tapply(yv,qv,length)
hl <- sum((obs-exp_)^2/(exp_*(1-exp_/nq)))
put("hl_chi2", round(hl,2)); put("hl_p", round(pchisq(hl,8,lower.tail=FALSE),2))

# subgroup film <= admission
sub <- f[!is.na(f$film_offset_h) & f$film_offset_h < 0, ]
set.seed(20261023)
imp2 <- mice(sub[, vars], m = 20, printFlag = FALSE)
ps <- pool(lapply(1:20, function(i) glm(death30 ~ grp + age+female+sofa_score+lac+vent24+vaso24+hf+ckd, data=complete(imp2,i), family=binomial)))
put("sub_n", nrow(sub)); put("sub_deaths", sum(sub$death30))
for (g in c("B","C","D")) { put(paste0("sub_or", g), round(ps$OR[ps$term==paste0("grp",g)],2)); put(paste0("sub_or", g, "_lcl"), round(ps$lcl[ps$term==paste0("grp",g)],2)); put(paste0("sub_or", g, "_ucl"), round(ps$ucl[ps$term==paste0("grp",g)],2)) }

# film timing
put("film_median_h", round(median(f$film_offset_h, na.rm=TRUE),1))
put("film_q1_h", round(quantile(f$film_offset_h,.25,na.rm=TRUE),1))
put("film_q3_h", round(quantile(f$film_offset_h,.75,na.rm=TRUE),1))
put("film_pct_pre", round(100*mean(f$film_offset_h <= 0, na.rm=TRUE),1))

# write JSON
lines <- paste0('  "', names(R), '": ', vapply(R, function(x) format(x, scientific=FALSE, trim=TRUE), ""), collapse=",\n")
writeLines(paste0("{\n", lines, "\n}"), "registry/numbers.json")
cat("registry keys:", length(R), "\n")
