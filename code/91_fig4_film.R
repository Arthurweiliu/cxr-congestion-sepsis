setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(ggplot2))

fr <- data.frame(
  label = c("Main analysis", "S1 findings-first", "S3 landmark 72 h",
            "S4 excluding heart failure", "S5 frontal films only",
            "S6 24-h balance window", "S9 output complete",
            "S11 in-hospital death", "S12 strict definition", "S15 lactate fallback"),
  OR  = c(1.75, 1.74, 1.70, 2.47, 1.69, 1.43, 1.57, 1.80, 2.24, 1.74),
  lcl = c(1.22, 1.21, 1.16, 1.47, 1.18, 1.00, 1.07, 1.14, 1.41, 1.22),
  ucl = c(2.51, 2.49, 2.49, 4.15, 2.43, 2.04, 2.30, 2.84, 3.57, 2.50))
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
