setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(mice); library(splines); library(ggplot2) })
set.seed(20261023)

f <- read.csv("data/film_analysis.csv")
f$cong <- as.integer(f$cong_hybrid); f$fb <- f$fb72_mlkg
vars <- c("death30","cong","age","female","sofa_score","lac","vent24","vaso24","hf","ckd")
imp <- mice(f[, vars], m = 20, printFlag = FALSE)
nsb <- ns(f$fb, df = 4)
B <- as.data.frame(unclass(nsb)); names(B) <- paste0("S", 1:4)
bases <- lapply(1:20, function(i) cbind(complete(imp, i), B))

pool <- function(fits) {
  Bm <- sapply(fits, coef); b <- rowMeans(Bm)
  T <- Reduce("+", lapply(fits, vcov))/length(fits) + (1+1/length(fits))*cov(t(Bm))
  list(b = b, T = T)
}
fits <- lapply(bases, function(d) glm(death30 ~ cong + S1 + S2 + S3 + S4 + age + female + sofa_score + lac + vent24 + vaso24 + hf + ckd, data = d, family = binomial))
p <- pool(fits)

grid <- seq(as.numeric(quantile(f$fb, .01)), as.numeric(quantile(f$fb, .95)), length.out = 200)
Bn <- predict(nsb, grid); B0 <- as.numeric(predict(nsb, 0))
idx <- which(names(p$b) %in% paste0("S", 1:4))
C <- sweep(Bn, 2, B0, "-")
lp <- as.numeric(C %*% p$b[idx]); se <- sqrt(rowSums((C %*% p$T[idx, idx]) * C))
cv <- data.frame(x = grid, OR = exp(lp), lcl = exp(lp - 1.96*se), ucl = exp(lp + 1.96*se))
write.csv(cv, "v4/film/Fig5_curves.csv", row.names = FALSE)

gg <- ggplot(cv, aes(x, OR)) +
  geom_ribbon(aes(ymin = lcl, ymax = ucl), fill = "#9ecae1", alpha = 0.45) +
  geom_line(colour = "#08519c", linewidth = 0.9) +
  geom_hline(yintercept = 1, linetype = 2, colour = "grey40") +
  geom_vline(xintercept = 0, linetype = 3, colour = "grey60") +
  scale_y_log10(breaks = c(0.5, 0.75, 1, 1.5, 2, 3)) +
  coord_cartesian(ylim = c(0.6, 3)) +
  labs(x = "72-h fluid balance after the index film (mL/kg)", y = "Adjusted OR for 30-day mortality") +
  theme_classic(base_size = 9)
ggsave("v4/film/Fig5.pdf", gg, width = 5.2, height = 4.0)
ggsave("v4/film/Fig5.png", gg, width = 5.2, height = 4.0, dpi = 300)
ggsave("v4/film/Fig5.tiff", gg, width = 5.2, height = 4.0, dpi = 600, device = "tiff", compression = "lzw")
cat("Fig5 written; OR at P50:", round(cv$OR[which.min(abs(cv$x - median(f$fb)))], 3), "\n")
