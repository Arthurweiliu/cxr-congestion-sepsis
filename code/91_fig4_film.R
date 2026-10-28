setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(ggplot2))

fr <- data.frame(
  label = c("Main analysis", "S1 findings-first", "S3 landmark 72 h",
            "S4 excluding heart failure", "S5 frontal films only",
            "S6 24-h balance window", "S9 output complete",
            "S11 in-hospital death", "S12 strict definition", "S15 lactate fallback"),
  OR  = c(1.73, 1.72, 1.69, 2.55, 1.68, 1.42, 1.55, 1.82, 2.16, 1.73),
  lcl = c(1.21, 1.20, 1.15, 1.52, 1.17, 0.99, 1.06, 1.15, 1.36, 1.20),
  ucl = c(2.48, 2.46, 2.47, 4.27, 2.41, 2.03, 2.27, 2.87, 3.43, 2.47))
fr$label <- factor(fr$label, levels = rev(fr$label))

p <- ggplot(fr, aes(OR, label)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(xmin = lcl, xmax = ucl), width = 0.18, colour = "#2166ac") +
  geom_point(size = 2.4, colour = "#2166ac") +
  scale_x_log10(breaks = c(0.75, 1, 1.5, 2, 3, 4), labels = c("0.75", "1.0", "1.5", "2.0", "3.0", "4.0")) +
  labs(x = "Odds ratio (group C vs A, log scale)", y = NULL,
       title = "Discordant congestion and 30-day mortality: primary and nine sensitivity analyses") +
  theme_bw(base_size = 9.5) +
  theme(plot.title = element_text(size = 9, face = "bold"),
        panel.grid.minor = element_blank())
ggsave("v4/film/Fig4.pdf", p, width = 6.9, height = 4.2)
ggsave("v4/film/Fig4.png", p, width = 6.9, height = 4.2, dpi = 300)
ggsave("v4/film/Fig4.tiff", p, width = 6.9, height = 4.2, dpi = 600, device = "tiff", compression = "lzw")
cat("Fig4 written\n")
