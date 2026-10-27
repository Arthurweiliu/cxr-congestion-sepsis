setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
set.seed(20261025)

tab <- function(x, y) {
  tb <- table(factor(x, levels = c(0,1)), factor(y, levels = c(0,1)))
  n <- sum(tb); a <- tb[2,2]; b <- tb[2,1]; c <- tb[1,2]; dd <- tb[1,1]
  po <- (a + dd)/n
  pe <- (sum(tb[2,])*sum(tb[,2]) + sum(tb[1,])*sum(tb[,1]))/n^2
  c(kappa = (po - pe)/(1 - pe), pabak = 2*po - 1, po = po)
}

d$fbpos <- as.integer(d$fb72_mlkg > 0)
base <- tab(d$cong_hybrid, d$fbpos)
B <- 1000
res <- replicate(B, {
  i <- sample(nrow(d), replace = TRUE)
  tab(d$cong_hybrid[i], d$fbpos[i])
})
ci <- function(v) sprintf("%.3f (%.3f to %.3f)", base[[v]], quantile(res[v,], .025), quantile(res[v,], .975))
cat("kappa :", ci("kappa"), "\n")
cat("PABAK :", ci("pabak"), "\n")
cat("Po    :", ci("po"), "\n")

t <- readLines("tables/S2_agreement.md", encoding = "UTF-8")
t <- c(t, "",
  sprintf("**Uncertainty (1000 bootstrap resamples, hybrid definition).** κ = %.3f (95%% CI %.3f to %.3f); PABAK = %.3f (%.3f to %.3f); observed agreement = %.3f (%.3f to %.3f).",
    base[["kappa"]], quantile(res["kappa",], .025), quantile(res["kappa",], .975),
    base[["pabak"]], quantile(res["pabak",], .025), quantile(res["pabak",], .975),
    base[["po"]], quantile(res["po",], .025), quantile(res["po",], .975)))
writeLines(enc2utf8(t), con = file("tables/S2_agreement.md", "w", encoding = "UTF-8"))
cat("S2 updated\n")
