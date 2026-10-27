setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))
set.seed(20261025)

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
a <- read.csv("data/aligned.csv", stringsAsFactors = FALSE)
d <- merge(f, a, by = "stay_id")
d$female <- as.integer(d$gender == "F")
d$fbpos <- as.integer(d$fb_before_film_mlkg > 0)

tab <- function(x, y) {
  tb <- table(factor(x, levels = c(0,1)), factor(y, levels = c(0,1)))
  n <- sum(tb); A <- tb[2,2]; B <- tb[2,1]; C <- tb[1,2]; D <- tb[1,1]
  po <- (A + D)/n; pe <- (sum(tb[2,])*sum(tb[,2]) + sum(tb[1,])*sum(tb[,1]))/n^2
  list(n = n, po = po, kappa = (po - pe)/(1 - pe), pabak = 2*po - 1, tb = tb)
}

r <- tab(d$cong_hybrid, d$fbpos)
cat("=== ALIGNED (post-ICU film, FB from admission to film) ===\n")
cat(sprintf("n = %d | observed agreement %.3f | kappa %.3f | PABAK %.3f\n", r$n, r$po, r$kappa, r$pabak))
print(r$tb)

set.seed(1)
bs <- replicate(500, {
  i <- sample(nrow(d), replace = TRUE)
  tab(d$cong_hybrid[i], d$fbpos[i])$kappa
})
cat(sprintf("kappa 95%% CI (bootstrap): %.3f to %.3f\n", quantile(bs, .025), quantile(bs, .975)))

d$grp <- factor(ifelse(d$cong_hybrid == 1, ifelse(d$fbpos == 1, "D", "C"),
                       ifelse(d$fbpos == 1, "B", "A")), levels = c("A","B","C","D"))
cat("\n=== mortality by group (aligned) ===\n")
print(data.frame(n = table(d$grp), deaths = tapply(d$death30, d$grp, sum),
                 pct = round(100*tapply(d$death30, d$grp, mean), 1)))

m <- runMI <- local({
  dd <- data.frame(death30 = d$death30, grp = d$grp, age = d$age, female = d$female,
                   sofa = d$sofa_score, lac = d$lac, vent = d$vent24,
                   vaso = d$vaso24, hf = d$hf, ckd = d$ckd)
  imp <- mice(dd, m = 20, printFlag = FALSE)
  fits <- lapply(1:20, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                       data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); bb <- rowMeans(B)
  se <- sqrt(diag(Reduce("+", lapply(fits, vcov))/20 + (1 + 1/20)*cov(t(B))))
  data.frame(term = names(bb), OR = exp(bb), lcl = exp(bb-1.96*se), ucl = exp(bb+1.96*se))
})
cat("\n=== adjusted ORs (aligned) ===\n")
print(m[grepl("^grp", m$term), ], row.names = FALSE, digits = 3)
