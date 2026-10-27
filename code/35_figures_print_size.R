setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(survival); library(patchwork)})

# Final print width for MDPI full-page figure: 17.5 cm = 6.9 in
W <- 6.9
DPI <- 600

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$dt <- as.POSIXct(ifelse(f$deathtime %in% c("", NA), NA, f$deathtime), tz = "UTC")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

## ================= Fig 1: compact, print-width =================
flow <- function() {
  par(mar = c(0.3, 0.3, 0.3, 0.3), family = "sans", ps = 12)
  plot.new(); plot.window(xlim = c(0, 100), ylim = c(0, 100))

  bx <- function(y, txt, w = 50, x = 28, cex = 0.86, fill = "white", h = 4.6) {
    rect(x - w/2, y - h, x + w/2, y + h, col = fill, border = "black", lwd = 1.2)
    text(x, y, txt, cex = cex)
  }
  ex <- function(y, txt, nlines = 2, cex = 0.72) {
    segments(28 + 25, y, 56, y, lwd = 1)
    segments(56, y, 56, y - 1.6, lwd = 1)
    h <- 2.0 * nlines + 1.4
    rect(57, y - 1.2 - h, 99, y - 0.4, col = "grey95", border = "grey45", lwd = 0.9)
    text(78, y - 1.2 - h/2, txt, cex = cex)
  }

  bx(93, "Sepsis-3 ICU admissions\nn = 32,971")
  bx(76, "First sepsis-associated ICU stay,\nage \u2265 18 years\nn = 25,596")
  ex(76, "Excluded 7,375\nrepeat stay or <18 y")
  bx(59, "Chest radiograph within \u00b124 h\nn = 7,050")
  ex(59, "Excluded 18,546\nno radiograph")
  bx(42, "Matched to chest-radiograph report\nn = 6,595")
  ex(42, "Excluded 455\nno matched report")
  bx(25, "Congestion classifiable\nn = 4,576")
  ex(25, "Excluded 2,019\nlungs not described")
  bx(7, "Final cohort: n = 3,963\n30-day deaths 832 (21.0%)", w = 54, fill = "grey93", h = 5.2)
  ex(7, "Excluded 613:\nno fluid balance 224\nimplausible weight/FB or VAD 166\ntiming outside \u00b124 h 223", nlines = 4)

  arrows(28, 88.4, 28, 80.6, length = 0.07)
  arrows(28, 71.4, 28, 63.6, length = 0.07)
  arrows(28, 54.4, 28, 46.6, length = 0.07)
  arrows(28, 37.4, 28, 29.6, length = 0.07)
  arrows(28, 20.4, 28, 12.2, length = 0.07)
}

cairo_pdf("figures/Fig1_flow_print.pdf", width = W, height = 5.6); flow(); dev.off()
png("figures/Fig1_flow_print.png", width = W, height = 5.6, units = "in", res = 300); flow(); dev.off()
tiff("figures/Fig1_flow_600dpi.tiff", width = W, height = 5.6, units = "in",
     res = DPI, compression = "lzw", type = "windows"); flow(); dev.off()

## ================= Fig 2: print-width =================
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

ggsave("figures/Fig2_2x2_print.pdf", pA | pB, width = W, height = 3.4)
png("figures/Fig2_2x2_print.png", pA | pB, width = W, height = 3.4, units = "in", res = 300)
ggsave("figures/Fig2_2x2_600dpi.tiff", pA | pB, width = W, height = 3.4, dpi = DPI,
       device = "tiff", compression = "lzw")

## ================= Fig 3: same width, larger legend =================
dx <- as.numeric(difftime(f$dt, f$intime, units = "days"))
f$time <- pmin(ifelse(is.na(dx), 30, dx), 30); f$event <- f$death30; f$time[f$time < 0] <- 0
sf <- survfit(Surv(time, event) ~ grp, data = f)
labs <- c(A = "A  congestion- / balance<=0", B = "B  congestion- / balance>0",
          C = "C  congestion+ / balance<=0", D = "D  congestion+ / balance>0")
cols <- c("#4d4d4d","#4393c3","#d6604d","#b2182b")
km <- function() {
  par(mar = c(4.4,4.6,1.6,0.8), family = "sans", ps = 12)
  plot(sf, col = cols, lwd = 2, mark.time = FALSE, ylim = c(0,1),
       xlab = "Days since ICU admission", ylab = "Cumulative survival",
       cex.lab = 1.0, cex.axis = 0.9, las = 1, yaxt = "n")
  axis(2, at = seq(0,1,0.2), labels = sprintf("%.0f%%", seq(0,100,20)), las = 1, cex.axis = 0.9)
  legend("bottomleft", legend = paste0(labs[levels(f$grp)], " (n=", as.numeric(table(f$grp)), ")"),
         col = cols, lwd = 2, bty = "n", cex = 0.72)
}
cairo_pdf("figures/Fig3_KM_print.pdf", width = W, height = 4.6); km(); dev.off()
png("figures/Fig3_KM_print.png", width = W, height = 4.6, units = "in", res = 300); km(); dev.off()
tiff("figures/Fig3_KM_600dpi.tiff", width = W, height = 4.6, units = "in",
     res = DPI, compression = "lzw", type = "windows"); km(); dev.off()

## ================= Fig 4: print-width, larger caption =================
fr <- data.frame(
  label = c("Main (72 h, hybrid)","S1 findings-first","S2 unknown as negative","S3 landmark 72 h",
            "S4 excluding heart failure","S5 frontal films only","S6 24-h fluid window",
            "S9 output complete","S10 unknown as category","S11 in-hospital death",
            "S12 strict definition","S15 lactate fallback","S16 no plausibility screen"),
  OR  = c(1.59,1.58,1.53,1.67,2.41,1.54,1.13,1.46,1.60,1.60,1.93,1.57,1.61),
  lcl = c(1.08,1.08,1.10,1.11,1.37,1.05,0.77,0.98,1.09,0.97,1.17,1.07,1.12),
  ucl = c(2.33,2.31,2.15,2.50,4.26,2.27,1.67,2.19,2.34,2.63,3.19,2.30,2.33))
fr$label <- factor(fr$label, levels = rev(fr$label))
p4 <- ggplot(fr, aes(OR, label)) + geom_vline(xintercept = 1, linetype = "dashed", colour = "grey50") +
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
png("figures/Fig4_forest_print.png", p4, width = W, height = 4.3, units = "in", res = 300)
ggsave("figures/Fig4_forest_600dpi.tiff", p4, width = W, height = 4.3, dpi = DPI,
       device = "tiff", compression = "lzw")

cat("all figures rendered at print width", W, "in, 600 dpi TIFF\n")
