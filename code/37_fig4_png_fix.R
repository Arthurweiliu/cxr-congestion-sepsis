setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(ggplot2))

W <- 6.9
fr <- data.frame(
  label = c("Main (72 h, hybrid)","S1 findings-first","S2 unknown as negative","S3 landmark 72 h",
            "S4 excluding heart failure","S5 frontal films only","S6 24-h fluid window",
            "S9 output complete","S10 unknown as category","S11 in-hospital death",
            "S12 strict definition","S15 lactate fallback","S16 no plausibility screen"),
  OR  = c(1.59,1.58,1.53,1.67,2.41,1.54,1.13,1.46,1.60,1.60,1.93,1.57,1.61),
  lcl = c(1.08,1.08,1.10,1.11,1.37,1.05,0.77,0.98,1.09,0.97,1.17,1.07,1.12),
  ucl = c(2.33,2.31,2.15,2.50,4.26,2.27,1.67,2.19,2.34,2.63,3.19,2.30,2.33))
fr$label <- factor(fr$label, levels = rev(fr$label))

p4 <- ggplot(fr, aes(OR, label)) +
  geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
  geom_errorbar(aes(xmin = lcl, xmax = ucl), width = 0.18, colour = "#2166ac") +
  geom_point(size = 2.2, colour = "#2166ac") +
  scale_x_log10(breaks = c(0.75,1,1.5,2,3,4), labels = c("0.75","1.0","1.5","2.0","3.0","4.0")) +
  labs(x = "Odds ratio (group C vs A, log scale)", y = NULL,
       title = "Discordant congestion and 30-day mortality",
       subtitle = "Primary and 13 pre-specified sensitivity analyses",
       caption = "S2 and S10 use a larger denominator (n = 5,692).") +
  theme_bw(base_size = 9) +
  theme(plot.title = element_text(size = 9, face = "bold"),
        plot.subtitle = element_text(size = 8),
        plot.caption = element_text(size = 8, hjust = 0),
        panel.grid.minor = element_blank())

ggsave("figures/Fig4_forest_print.pdf", p4, width = W, height = 4.3)
ggsave("figures/Fig4_forest_print.png", p4, width = W, height = 4.3, dpi = 300)
cat("Fig4 pdf+png regenerated\n")
