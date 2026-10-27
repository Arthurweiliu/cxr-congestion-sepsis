setwd("F:/openclaw_workspace/CXR_congestion")
cat("cairo:", capabilities("cairo"), "\n")

draw <- function() {
  par(mar = c(1,1,1,1), family = "sans")
  plot.new(); plot.window(xlim = c(0,100), ylim = c(0,100))
  box <- function(y, txt, w = 52, x = 38, cex = 0.78, fill = "white") {
    rect(x - w/2, y - 3.6, x + w/2, y + 3.6, col = fill, border = "black", lwd = 1)
    text(x, y, txt, cex = cex)
  }
  ex <- function(y, txt) {
    segments(38 + 26, y, 72, y, lwd = 1); segments(72, y, 72, y - 4.5, lwd = 1)
    rect(74, y - 8, 99, y - 1, col = "grey95", border = "grey40", lwd = 0.8)
    text(86.5, y - 4.5, txt, cex = 0.58)
  }
  box(95, "Sepsis-3 ICU admissions\nn = 32,971")
  box(83, "First sepsis-associated ICU stay,\nage >= 18 years\nn = 25,596")
  ex(83, "Excluded 7,375\nrepeat sepsis stay or <18 y")
  box(71, "Chest radiograph within +/-24 h\nn = 7,050")
  ex(71, "Excluded 18,546\nno radiograph")
  box(59, "Matched to chest radiograph report\nn = 6,595")
  ex(59, "Excluded 455\nno matched report")
  box(47, "Congestion status classifiable\nn = 4,576")
  ex(47, "Excluded 2,019\nlungs not described")
  box(35, "Fluid balance calculable\nn = 4,352")
  ex(35, "Excluded 224\nintake or output missing")
  box(23, "After plausibility screen\nn = 4,186")
  ex(23, "Excluded 166\nimplausible weight/FB, VAD")
  box(11, "Final cohort\nn = 3,963; 30-day deaths 832 (21.0%)", w = 58, fill = "grey92")
  ex(11, "Excluded 223\nsepsis timing outside +/-24 h")
  arrows(38, 91.4, 38, 86.6, length = 0.07); arrows(38, 79.4, 38, 74.6, length = 0.07)
  arrows(38, 67.4, 38, 62.6, length = 0.07); arrows(38, 55.4, 38, 50.6, length = 0.07)
  arrows(38, 43.4, 38, 38.6, length = 0.07); arrows(38, 31.4, 38, 26.6, length = 0.07)
  arrows(38, 19.4, 38, 14.6, length = 0.07)
}

if (capabilities("cairo")) {
  cairo_pdf("figures/final_Fig1_flow.pdf", width = 7.4, height = 8.8); draw(); dev.off()
  cat("written with cairo_pdf\n")
} else {
  pdf("figures/final_Fig1_flow.pdf", width = 7.4, height = 8.8); draw(); dev.off()
  cat("cairo unavailable, plain pdf\n")
}
png("figures/final_Fig1_flow.png", width = 7.4, height = 8.8, units = "in", res = 300); draw(); dev.off()
