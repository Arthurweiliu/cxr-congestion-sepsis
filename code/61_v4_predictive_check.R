d <- read.csv("F:/openclaw_workspace/CXR_congestion/data/final_cohort.csv", stringsAsFactors = FALSE)
d$fb <- d$fb24_mlkg
d$cong <- suppressWarnings(as.numeric(d$cong_hybrid))
vars <- c("death30", "fb", "cong", "age", "sofa_score", "lactate_max", "hf", "ckd")
dd <- d[complete.cases(d[, vars]), vars]
n <- nrow(dd); cat("n complete:", n, " deaths:", sum(dd$death30 == 1), "\n")

aucv <- function(p, y) { r <- rank(p); n1 <- sum(y); n0 <- sum(!y); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
fitp <- function(rhs) glm(as.formula(paste("death30 ~", rhs)), data = dd, family = binomial) |> fitted()
y <- dd$death30

sets <- list(
  base      = "age+sofa_score+lactate_max+hf+ckd",
  `base+film` = "age+sofa_score+lactate_max+hf+ckd+cong",
  `base+fb`   = "age+sofa_score+lactate_max+hf+ckd+fb",
  `base+both` = "age+sofa_score+lactate_max+hf+ckd+cong+fb"
)
ps <- lapply(sets, function(s) fitp(s))
for (k in names(ps)) cat(sprintf("%-10s AUC=%.4f\n", k, aucv(ps[[k]], y)))

set.seed(42)
B <- 400
boot <- sapply(1:B, function(b) {
  i <- sample(n, n, TRUE)
  sapply(ps, function(p) { tryCatch(aucv(p[i], y[i]), error = function(e) NA) })
})
for (k in names(ps)) {
  ci <- quantile(boot[k, ], c(.025, .975), na.rm = TRUE)
  cat(sprintf("%-10s boot 95%%CI %.4f-%.4f\n", k, ci[1], ci[2]))
}
dd_a <- boot["base+film", ] - boot["base", ]
dd_b <- boot["base+fb", ] - boot["base", ]
cat(sprintf("dAUC film  = %.4f (95%%CI %.4f to %.4f)\n", aucv(ps[["base+film"]], y) - aucv(ps[["base"]], y), quantile(dd_a, .025, na.rm=TRUE), quantile(dd_a, .975, na.rm=TRUE)))
cat(sprintf("dAUC fb    = %.4f (95%%CI %.4f to %.4f)\n", aucv(ps[["base+fb"]], y) - aucv(ps[["base"]], y), quantile(dd_b, .025, na.rm=TRUE), quantile(dd_b, .975, na.rm=TRUE)))

m2 <- glm(death30 ~ age+sofa_score+lactate_max+hf+ckd+cong, data = dd, family = binomial)
m3 <- glm(death30 ~ age+sofa_score+lactate_max+hf+ckd+fb, data = dd, family = binomial)
ci <- function(m, v, mult = 1) { b <- coef(m)[v] * mult; s <- sqrt(vcov(m)[v, v]) * mult; sprintf("OR=%.3f (%.3f-%.3f)", exp(b), exp(b - 1.96*s), exp(b + 1.96*s)) }
cat("cong      :", ci(m2, "cong"), "\n")
cat("fb /10mLkg:", ci(m3, "fb", 10), "\n")

dd$fbq <- cut(dd$fb, unique(quantile(dd$fb, 0:5/5)), include.lowest = TRUE)
cat("\n30d mortality by FB quintile (%):\n"); print(round(prop.table(table(dd$fbq, dd$death30), 1) * 100, 1))
cat("\nFB quintile ranges:\n"); print(tapply(dd$fb, dd$fbq, range))
