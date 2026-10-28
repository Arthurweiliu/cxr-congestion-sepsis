setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(pROC) })
set.seed(20261023)

f <- read.csv("data/final_with_lac.csv")
fb <- read.csv("data/fb_film.csv")
m <- merge(f, fb[, c("stay_id","fb_film_mlkg","intake","output")], by = "stay_id", all.x = TRUE)
cat("n =", nrow(m), " missing film-anchored balance =", sum(is.na(m$fb_film_mlkg)), "\n")

m$cong <- as.integer(m$cong_hybrid)
m$pos_new <- as.integer(m$fb_film_mlkg > 0)
m$grp2 <- factor(ifelse(m$cong==1, ifelse(m$pos_new==1,"D","C"), ifelse(m$pos_new==1,"B","A")), levels=c("A","B","C","D"))

cat("\n== distribution of film-anchored balance ==\n")
print(round(quantile(m$fb_film_mlkg, c(.1,.25,.5,.75,.9), na.rm=TRUE), 1))
cat("correlation with 0-72h balance:", round(cor(m$fb_film_mlkg, m$fb72_mlkg, use="complete.obs"), 3), "\n")

tab <- table(factor(m$cong, 0:1), factor(m$pos_new, 0:1))
print(tab)
n <- sum(tab); po <- sum(diag(tab))/n
pe <- sum(rowSums(tab)*colSums(tab))/n^2
k <- (po-pe)/(1-pe); se <- sqrt(po*(1-po)/(n*(1-pe)^2))
cat(sprintf("kappa = %.3f (95%% CI %.3f to %.3f); observed %.1f%%, expected %.1f%%\n", k, k-1.96*se, k+1.96*se, 100*po, 100*pe))

cat("\n== four groups (film-anchored) ==\n")
print(table(m$grp2))
cat("\ncrude 30-day mortality:\n")
print(round(100*tapply(m$death30, m$grp2, mean), 1))

c0 <- "age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd"
vars <- c("death30","grp2", "age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(m[, vars], m = 20, printFlag = FALSE)
fits <- lapply(1:20, function(i) glm(as.formula(paste("death30 ~ grp2 +", c0)), data=complete(imp,i), family=binomial))
B <- sapply(fits, coef); b <- rowMeans(B)
T <- Reduce("+", lapply(fits, vcov))/20 + (1+1/20)*cov(t(B)); se2 <- sqrt(diag(T))
cat("\nadjusted OR vs A:\n")
for (t in c("grp2B","grp2C","grp2D")) cat(sprintf("  %s: %.2f (%.2f-%.2f)\n", t, exp(b[t]), exp(b[t]-1.96*se2[t]), exp(b[t]+1.96*se2[t])))

cat("\n== discrimination, film-anchored balance ==\n")
cc <- m[complete.cases(m[, c("death30","fb_film_mlkg","cong","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")]), ]
cat("complete cases:", nrow(cc), " deaths:", sum(cc$death30), "\n")
nsb <- splines::ns(cc$fb_film_mlkg, df = 4)
Bm <- as.data.frame(unclass(nsb)); names(Bm) <- paste0("S",1:4); cc <- cbind(cc, Bm)
f0 <- glm(death30 ~ age+female+sofa_score+lac+vent24+vaso24+hf+ckd + S1+S2+S3+S4, data=cc, family=binomial)
f1 <- glm(death30 ~ age+female+sofa_score+lac+vent24+vaso24+hf+ckd + S1+S2+S3+S4 + cong, data=cc, family=binomial)
a0 <- as.numeric(auc(roc(cc$death30, fitted(f0), quiet=TRUE)))
a1 <- as.numeric(auc(roc(cc$death30, fitted(f1), quiet=TRUE)))
cat(sprintf("AUC base+balance %.4f -> +congestion %.4f  dAUC %.4f\n", a0, a1, a1-a0))
set.seed(7); Bn <- 500; idx <- seq_len(nrow(cc)); p0 <- fitted(f0); p1 <- fitted(f1); y <- cc$death30
dd <- replicate(Bn, { s <- sample(idx, length(idx), TRUE)
  as.numeric(auc(roc(y[s], p1[s], quiet=TRUE))) - as.numeric(auc(roc(y[s], p0[s], quiet=TRUE))) })
cat(sprintf("bootstrap 95%% CI %.4f to %.4f\n", quantile(dd,.025), quantile(dd,.975)))
