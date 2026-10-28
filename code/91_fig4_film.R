setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(ggplot2))

fr <- data.frame(
  label = c("Main analysis", "S1 findings-first", "S3 landmark 72 h",
            "S4 excluding heart failure", "S5 frontal films only",
            "S6 24-h balance window", "S9 output complete",
            "S11 in-hospital death", "S12 strict definition", "S15 lactate fallback",
            "S16a film before ICU (truncated, post hoc)",
            "S16b film at/after ICU (untruncated, post hoc)"),
  OR  = c(1.75, 1.74, 1.69, 2.64, 1.71, 1.43, 1.55, 1.86, 2.17, 1.75, 1.40, 2.27),
  lcl = c(1.22, 1.21, 1.15, 1.57, 1.18, 1.00, 1.06, 1.17, 1.36, 1.22, 0.87, 1.27),
  ucl = c(2.52, 2.50, 2.47, 4.44, 2.46, 2.05, 2.27, 2.95, 3.47, 2.51, 2.25, 4.04))
fr$label <- factor(fr$label, levels = rev(fr$label))

p <- ggplot(fr, aes(OR, label)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(xmin = lcl, xmax = ucl), width = 0.18, colour = "#2166ac") +
  geom_point(size = 2.4, colour = "#2166ac") +
  scale_x_log10(breaks = c(0.75, 1, 1.5, 2, 3, 4, 5), labels = c("0.75", "1.0", "1.5", "2.0", "3.0", "4.0", "5.0")) +
  labs(x = "Odds ratio (group C vs A, log scale)", y = NULL,
       title = "Discordant congestion and 30-day mortality") +
  theme_bw(base_size = 9.5) +
  theme(plot.title = element_text(size = 9, face = "bold"),
        panel.grid.minor = element_blank())
ggsave("v4/film/Fig4.pdf", p, width = 6.9, height = 4.6)
ggsave("v4/film/Fig4.png", p, width = 6.9, height = 4.6, dpi = 300)
ggsave("v4/film/Fig4.tiff", p, width = 6.9, height = 4.6, dpi = 600, device = "tiff", compression = "lzw")
cat("Fig4 written with", nrow(fr), "rows\n")
