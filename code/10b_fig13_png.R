setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(survival))

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$deathtime <- as.POSIXct(ifelse(d$deathtime %in% c("",NA), NA, d$deathtime), tz = "UTC")
d$dod <- as.Date(ifelse(d$dod %in% c("",NA), NA, d$dod))
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid==1, ifelse(a$fb72_mlkg>0,"D","C"),
                       ifelse(a$fb72_mlkg>0,"B","A")), levels=c("A","B","C","D"))
labs <- c(A="A  congestion- / balance<=0", B="B  congestion- / balance>0",
          C="C  congestion+ / balance<=0", D="D  congestion+ / balance>0")

png("figures/Fig1_flow.png", width=7.4, height=8.6, units="in", res=200)
par(mar=c(1,1,1,1), family="sans")
plot.new(); plot.window(xlim=c(0,100), ylim=c(0,100))
box <- function(y, txt, w=54, x=44, cex=0.8, fill="white") {
  rect(x-w/2, y-4, x+w/2, y+4, col=fill, border="black", lwd=1); text(x, y, txt, cex=cex)
}
ex <- function(y, txt) {
  segments(44+27, y, 70, y, lwd=1); segments(70, y, 70, y-5, lwd=1)
  rect(70, y-9, 99, y-1, col="grey95", border="grey40", lwd=0.8)
  text(84.5, y-5, txt, cex=0.62)
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
arrows(44,90,44,84,length=0.08); arrows(44,76,44,70,length=0.08)
arrows(44,62,44,56,length=0.08); arrows(44,48,44,42,length=0.08)
arrows(44,34,44,28,length=0.08); arrows(44,20,44,14,length=0.08)
dev.off()

dd <- a
dx <- as.numeric(difftime(dd$deathtime, dd$intime, units="days"))
dz <- as.numeric(dd$dod - as.Date(dd$intime))
tt <- ifelse(!is.na(dx), dx, ifelse(!is.na(dz), dz, 30))
dd$time <- pmin(tt, 30); dd$event <- dd$death30; dd$time[dd$time < 0] <- 0
sf <- survfit(Surv(time, event) ~ grp, data=dd)
png("figures/Fig3_KM.png", width=6.6, height=5.0, units="in", res=200)
par(mar=c(4.4,4.6,2.2,1))
plot(sf, col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, mark.time=FALSE,
     xlab="Days since ICU admission", ylab="Cumulative survival", cex.lab=1.05,
     cex.axis=0.95, las=1)
legend("bottomleft", legend=paste0(labs[levels(dd$grp)], " (n=", as.numeric(table(dd$grp)), ")"),
       col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, bty="n", cex=0.8)
dev.off()
cat("png done\n")
