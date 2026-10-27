setwd("F:/openclaw_workspace/CXR_congestion")

draw <- function() {
  par(mar = c(0.6, 0.6, 0.6, 0.6), family = "sans")
  plot.new(); plot.window(xlim = c(0, 100), ylim = c(0, 100))

  box <- function(y, txt, w = 46, x = 33, cex = 0.8, fill = "white", h = 4.2) {
    rect(x - w/2, y - h, x + w/2, y + h, col = fill, border = "black", lwd = 1.1)
    text(x, y, txt, cex = cex)
  }
  ex <- function(y, txt, nlines = 2, cex = 0.62) {
    segments(33 + 23, y, 68, y, lwd = 1)
    segments(68, y, 68, y - 2.2, lwd = 1)
    rect(69, y - 2 - 2.1*nlines - 1, 99, y - 0.5, col = "grey95", border = "grey45", lwd = 0.8)
    text(84, y - 2 - 2.1*nlines/2, txt, cex = cex)
  }

  box(93, "Sepsis-3 ICU admissions\nn = 32,971")
  box(79, "First sepsis-associated ICU stay,\nage \u2265 18 years\nn = 25,596")
  ex(79, "Excluded 7,375\nrepeat stay or <18 y")
  box(65, "Chest radiograph within \u00b124 h\nn = 7,050")
  ex(65, "Excluded 18,546\nno radiograph")
  box(51, "Matched to chest-radiograph report\nn = 6,595")
  ex(51, "Excluded 455\nno matched report")
  box(37, "Congestion classifiable\nn = 4,576")
  ex(37, "Excluded 2,019\nlungs not described")
  box(19, "Final cohort\nn = 3,963\n30-day deaths 832 (21.0%)", w = 50, fill = "grey93", h = 6)
  ex(19, "Excluded 613 in total:\nno fluid balance 224\nimplausible weight/FB or VAD 166\nsepsis timing outside \u00b124 h 223", nlines = 4)

  arrows(33, 88.4, 33, 83.6, length = 0.07)
  arrows(33, 74.4, 33, 69.6, length = 0.07)
  arrows(33, 60.4, 33, 55.6, length = 0.07)
  arrows(33, 46.4, 33, 41.6, length = 0.07)
  arrows(33, 32.4, 33, 25.6, length = 0.07)
}

if (capabilities("cairo")) {
  cairo_pdf("figures/final_Fig1_flow.pdf", width = 7.0, height = 7.0); draw(); dev.off()
} else {
  pdf("figures/final_Fig1_flow.pdf", width = 7.0, height = 7.0); draw(); dev.off()
}
png("figures/final_Fig1_flow.png", width = 7.0, height = 7.0, units = "in", res = 300); draw(); dev.off()
cat("flow redrawn: 5 main boxes + consolidated late-exclusion panel\n")
