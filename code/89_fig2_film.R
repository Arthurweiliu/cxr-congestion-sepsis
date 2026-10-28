setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(survival); library(patchwork)})

W <- 6.9
DPI <- 600

## ---------- Fig 1 ----------
flow <- function() {
  par(mar = c(0.3, 0.3, 0.3, 0.3), family = "sans", ps = 12)
  plot.new(); plot.window(xlim = c(0, 100), ylim = c(0, 100))
  bx <- function(y, txt, w = 50, x = 28, cex = 0.84, fill = "white", h = 4.4) {
    rect(x - w/2, y - h, x + w/2, y + h, col = fill, border = "black", lwd = 1.2)
    text(x, y, txt, cex = cex)
  }
  ex <- function(y, txt, nlines = 2, cex = 0.70, x0 = 53) {
    segments(x0, y, 55, y, lwd = 1)
    h <- 2.15 * nlines + 2.0
    rect(56, y - h/2, 99, y + h/2, col = "grey95", border = "grey45", lwd = 0.9)
    text(77.5, y, txt, cex = cex)
  }
  bx(94, "Sepsis-3 ICU admissions\nn = 32,971")
  bx(78, "First sepsis-associated ICU stay,\nage \u2265 18 years\nn = 25,596")
  ex(78, "Excluded 7,375\nrepeat stay or <18 y")
  bx(62, "Chest radiograph within \u00b124 h\nn = 7,050")
  ex(62, "Excluded 18,546\nno radiograph")
  bx(46, "Matched to chest-radiograph report\nn = 6,595")
  ex(46, "Excluded 455\nno matched report")
  bx(30, "Congestion classifiable\nn = 4,576")
  ex(30, "Excluded 2,019\nlungs not described")
  bx(11, "Final cohort: n = 3,963\n30-day deaths 832 (21.0%)", w = 50, fill = "grey93", h = 5.4)
  ex(11, "Excluded 613:\nno fluid balance 224\nimplausible weight/FB or VAD 166\ntiming outside \u00b124 h 223", nlines = 4, x0 = 53)
  arrows(28, 89.6, 28, 82.4, length = 0.07)
  arrows(28, 73.6, 28, 66.4, length = 0.07)
  arrows(28, 57.6, 28, 50.4, length = 0.07)
  arrows(28, 41.6, 28, 34.4, length = 0.07)
  arrows(28, 25.6, 28, 16.4, length = 0.07)
}

cairo_pdf("v4/film/Fig1_flow.pdf", width = W, height = 5.6); flow(); dev.off()
png("v4/film/Fig1_flow.png", width = W, height = 5.6, units = "in", res = 300); flow(); dev.off()
tiff("v4/film/Fig1_flow.tiff", width = W, height = 5.6, units = "in",
     res = DPI, compression = "lzw", type = "windows"); flow(); dev.off()

## ---------- Fig 2 ----------
f <- read.csv("data/film_analysis.csv", stringsAsFactors = FALSE)
a <- f
a$cong <- factor(ifelse(a$cong_hybrid == 1, "Congestion +", "Congestion -"), levels = c("Congestion +","Congestion -"))
a$fb <- factor(ifelse(a$fb72_mlkg > 0, "Balance > 0", "Balance <= 0"), levels = c("Balance <= 0","Balance > 0"))
tb <- table(a$cong, a$fb); rn <- prop.table(tb, 1) * 100
dA <- data.frame(cong = rep(rownames(tb), times = ncol(tb)), fb = rep(colnames(tb), each = nrow(tb)),
                 n = as.vector(tb), pct = as.vector(rn))
dA$cong <- factor(dA$cong, levels = c("Congestion +","Congestion -"))
dA$fb <- factor(dA$fb, levels = c("Balance <= 0","Balance > 0"))
pA <- ggplot(dA, aes(fb, cong, fill = pct)) + geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("n = %d\n%.1f%%", n, pct)), size = 3.4, lineheight = 0.95) +
  scale_fill_gradient(low = "#f7f7f7", high = "#bdbdbd", guide = "none") +
  labs(x = NULL, y = NULL, title = "A  Agreement (row %)", subtitle = "Cohen's kappa = -0.11") +
  theme_minimal(base_size = 9) +
  theme(panel.grid = element_blank(), plot.title = element_text(face = "bold", size = 9),
        plot.subtitle = element_text(size = 8))

ag <- aggregate(death30 ~ cong + fb, data = a, FUN = function(x) c(n = length(x), m = 100*mean(x)))
dB <- data.frame(cong = ag$cong, fb = ag$fb, n = ag$death30[,"n"], mort = ag$death30[,"m"])
dB$cong <- factor(dB$cong, levels = c("Congestion +","Congestion -"))
dB$fb <- factor(dB$fb, levels = c("Balance <= 0","Balance > 0"))
pB <- ggplot(dB, aes(fb, cong, fill = mort)) + geom_tile(colour = "white", linewidth = 1.2) +
  geom_text(aes(label = sprintf("n = %d\n%.1f%%", n, mort)), size = 3.4, lineheight = 0.95) +
  scale_fill_gradient(low = "#e8f3fb", high = "#b2182b", name = "30-day\nmortality (%)") +
  labs(x = NULL, y = NULL, title = "B  30-day mortality (unadjusted)") +
  theme_minimal(base_size = 9) +
  theme(panel.grid = element_blank(), plot.title = element_text(face = "bold", size = 9))

fig2 <- pA | pB
ggsave("v4/film/Fig2.pdf", fig2, width = W, height = 3.4)
ggsave("v4/film/Fig2.png", fig2, width = W, height = 3.4, dpi = 300)
ggsave("v4/film/Fig2.tiff", fig2, width = W, height = 3.4, dpi = DPI,
       device = "tiff", compression = "lzw")

cat("Fig1 and Fig2 re-rendered at", W, "in\n")
