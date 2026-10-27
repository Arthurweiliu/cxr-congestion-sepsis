## 65_v4_figures.R — Figure 5（最终口径）
setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })

cv <- read.csv("v4/rcs_curves_final.csv")
o  <- readRDS("v4/final_numbers.rds")

cur <- function(w, title) {
  d <- cv[cv$panel == w, ]
  ggplot(d, aes(x = x, y = OR)) +
    geom_ribbon(aes(ymin = lcl, ymax = ucl), fill = "#9ecae1", alpha = .45) +
    geom_line(colour = "#08519c", linewidth = .9) +
    geom_hline(yintercept = 1, linetype = 2, colour = "grey40") +
    geom_vline(xintercept = 0, linetype = 3, colour = "grey60") +
    scale_y_log10(breaks = c(0.5, 0.75, 1, 1.5, 2, 3)) +
    coord_cartesian(ylim = c(0.6, 3)) +
    labs(x = if (w == "72h") "72-h fluid balance (mL/kg)" else "24-h fluid balance (mL/kg)",
         y = "Adjusted OR for 30-day mortality", title = title) +
    theme_classic(base_size = 9) +
    theme(plot.title = element_text(size = 9, face = "bold"))
}
pA <- cur("72h", "A  72-h window (reference = 0 mL/kg)")
pB <- cur("24h", "B  24-h window (reference = 0 mL/kg)")

g <- function(p, terms, lab) {
  t <- p$tab[match(terms, p$tab$term), ]
  data.frame(model = lab, group = sub("^grp(24)?", "", terms),
             OR = t$OR, lcl = t$lcl, ucl = t$ucl)
}
fd <- rbind(
  g(o$p1,  c("grpB","grpC","grpD"),        "72-h window"),
  g(o$p24, c("grp24B","grp24C","grp24D"),  "24-h window"),
  g(o$p2,  c("grpB","grpC","grpD"),        "72-h, + continuous balance")
)
fd$model <- factor(fd$model, levels = c("72-h window", "24-h window", "72-h, + continuous balance"))
fd$group <- factor(fd$group, levels = c("B", "C", "D"))
fd$row <- paste0(fd$model, "  |  group ", fd$group)
ord <- c(paste0("72-h window", "  |  group ", c("B","C","D")),
         paste0("24-h window", "  |  group ", c("B","C","D")),
         paste0("72-h, + continuous balance", "  |  group ", c("B","C","D")))
fd$row <- factor(fd$row, levels = rev(ord))

pC <- ggplot(fd, aes(x = OR, y = row)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey40") +
  geom_pointrange(aes(xmin = lcl, xmax = ucl, colour = group), size = .35, linewidth = .5) +
  scale_x_log10(breaks = c(0.75, 1, 1.5, 2, 3, 4)) +
  scale_colour_manual(values = c(B = "#74c476", C = "#f16913", D = "#cb181d"), guide = "none") +
  labs(x = "Odds ratio (95% CI), reference = group A", y = NULL,
       title = "C  Four-group model by fluid-balance window") +
  theme_classic(base_size = 9) +
  theme(plot.title = element_text(size = 9, face = "bold", margin = margin(t = 12, b = 2)),
        axis.text.y = element_text(size = 7.5))

fig <- (pA | pB) / pC + plot_layout(heights = c(1, 1.15))
ggsave("v4/Fig5_v4.png", fig, width = 7.1, height = 6.0, dpi = 400)
ggsave("v4/Fig5_v4.pdf", fig, width = 7.1, height = 6.0)
ggsave("v4/Figure5.tiff", fig, width = 7.1, height = 6.0, dpi = 600,
       device = "tiff", compression = "lzw")
cat("figure written\n")
