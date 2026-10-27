setwd("F:/openclaw_workspace/CXR_congestion")
draw <- function() {
  par(mar=c(1,1,1,1), family="sans")
  plot.new(); plot.window(xlim=c(0,100), ylim=c(0,100))
  box <- function(y, txt, w=54, x=40, cex=0.8, fill="white") {
    rect(x-w/2, y-4, x+w/2, y+4, col=fill, border="black", lwd=1); text(x, y, txt, cex=cex)
  }
  ex <- function(y, txt) {
    segments(40+27, y, 74, y, lwd=1); segments(74, y, 74, y-5, lwd=1)
    rect(76, y-9, 99, y-1, col="grey95", border="grey40", lwd=0.8)
    text(87.5, y-5, txt, cex=0.62)
  }
  box(94, "Sepsis-3 ICU admissions\nn = 32,971")
  box(80, "First ICU stay, age >= 18 years\nn = 25,596")
  ex(80, "Excluded 7,375\nrepeat stay or <18 y")
  box(66, "Chest radiograph within +/-24 h\nn = 7,050")
  ex(66, "Excluded 18,546\nno radiograph")
  box(52, "Matched to radiology report\nn = 6,595")
  ex(52, "Excluded 455\nno matched report")
  box(38, "Congestion status classifiable\nn = 4,576")
  ex(38, "Excluded 2,019\nlungs not described")
  box(24, "Fluid balance calculable\nn = 4,352")
  ex(24, "Excluded 224\nmissing intake/output")
  box(10, "Analytic cohort\nn = 4,352; 30-day deaths 933 (21.4%)", w=62, fill="grey92")
  arrows(40,90,40,84,length=0.08); arrows(40,76,40,70,length=0.08)
  arrows(40,62,40,56,length=0.08); arrows(40,48,40,42,length=0.08)
  arrows(40,34,40,28,length=0.08); arrows(40,20,40,14,length=0.08)
}
pdf("figures/Fig1_flow.pdf", width=7.4, height=8.6); draw(); dev.off()
png("figures/Fig1_flow.png", width=7.4, height=8.6, units="in", res=200); draw(); dev.off()
cat("regenerated\n")
