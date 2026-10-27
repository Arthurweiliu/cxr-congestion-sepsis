setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(patchwork)})

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$cong <- factor(ifelse(a$cong_hybrid == 1, "Congestion +", "Congestion -"),
                 levels = c("Congestion +", "Congestion -"))
a$fb <- factor(ifelse(a$fb72_mlkg > 0, "Balance > 0", "Balance <= 0"),
               levels = c("Balance <= 0", "Balance > 0"))

tab <- table(a$cong, a$fb)
rown <- prop.table(tab, 1) * 100
dfA <- data.frame(cong = rep(rownames(tab), times = ncol(tab)),
                  fb = rep(colnames(tab), each = nrow(tab)),
                  n = as.vector(tab), pct = as.vector(rown))
dfA$cong <- factor(dfA$cong, levels = c("Congestion +", "Congestion -"))
dfA$fb <- factor(dfA$fb, levels = c("Balance <= 0", "Balance > 0"))

pA <- ggplot(dfA, aes(fb, cong, fill = pct)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("n = %d\n%.1f%%", n, pct)), size = 3.9, lineheight = 0.95) +
  scale_fill_gradient(low = "#f7f7f7", high = "#bdbdbd", guide = "none") +
  labs(x = NULL, y = NULL,
       title = "A  Agreement (row %)", subtitle = "Cohen's kappa = -0.11") +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), plot.title = element_text(face = "bold", size = 10),
        plot.subtitle = element_text(size = 9))

agg <- aggregate(death30 ~ cong + fb, data = a, FUN = function(x) c(n = length(x), m = 100*mean(x)))
dfB <- data.frame(cong = agg$cong, fb = agg$fb, n = agg$death30[,"n"], mort = agg$death30[,"m"])
dfB$cong <- factor(dfB$cong, levels = c("Congestion +", "Congestion -"))
dfB$fb <- factor(dfB$fb, levels = c("Balance <= 0", "Balance > 0"))

pB <- ggplot(dfB, aes(fb, cong, fill = mort)) +
  geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("n = %d\n%.1f%%", n, mort)), size = 3.9, lineheight = 0.95) +
  scale_fill_gradient(low = "#e8f3fb", high = "#b2182b", name = "30-day\nmortality (%)") +
  labs(x = NULL, y = NULL, title = "B  30-day mortality") +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank(), plot.title = element_text(face = "bold", size = 10))

fig <- pA | pB
ggsave("figures/Fig2_2x2.pdf", fig, width = 9.2, height = 4.0)
ggsave("figures/Fig2_2x2.png", fig, width = 9.2, height = 4.0, dpi = 300)
cat("done\n"); print(tab)
