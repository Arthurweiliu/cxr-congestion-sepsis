setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(survival))

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$dt <- as.POSIXct(ifelse(f$deathtime %in% c("", NA), NA, f$deathtime), tz = "UTC")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

dx <- as.numeric(difftime(f$dt, f$intime, units = "days"))
f$time <- pmin(ifelse(is.na(dx), 30, dx), 30)
f$event <- f$death30
f$time[f$time < 0] <- 0

sf <- survfit(Surv(time, event) ~ grp, data = f)
labs <- c(A = "A  congestion- / balance<=0", B = "B  congestion- / balance>0",
          C = "C  congestion+ / balance<=0", D = "D  congestion+ / balance>0")
cols <- c("#4d4d4d", "#4393c3", "#d6604d", "#b2182b")

draw <- function() {
  par(mar = c(4.6, 4.8, 2.2, 1), family = "sans")
  plot(sf, col = cols, lwd = 2, mark.time = FALSE, ylim = c(0, 1),
       xlab = "Days since ICU admission", ylab = "Cumulative survival",
       cex.lab = 1.05, cex.axis = 0.95, las = 1, yaxt = "n")
  axis(2, at = seq(0, 1, 0.2), labels = sprintf("%.0f%%", seq(0, 100, 20)), las = 1, cex.axis = 0.95)
  legend("bottomleft", legend = paste0(labs[levels(f$grp)], " (n=", as.numeric(table(f$grp)), ")"),
         col = cols, lwd = 2, bty = "n", cex = 0.8)
}

if (capabilities("cairo")) {
  cairo_pdf("figures/final_Fig3_KM.pdf", width = 6.6, height = 5.0); draw(); dev.off()
} else {
  pdf("figures/final_Fig3_KM.pdf", width = 6.6, height = 5.0); draw(); dev.off()
}
png("figures/final_Fig3_KM.png", width = 6.6, height = 5.0, units = "in", res = 300); draw(); dev.off()

cat("Fig3 regenerated with full 0-100% y axis\n")
cat("30-day survival by group:\n")
print(round(100 * summary(sf, times = 30)$surv, 1))
