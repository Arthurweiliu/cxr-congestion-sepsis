setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(survival); library(patchwork)})

f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$dt <- as.POSIXct(ifelse(f$deathtime %in% c("", NA), NA, f$deathtime), tz = "UTC")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

## ---- Fig1 flow (7 steps) ----
draw <- function() {
  par(mar=c(1,1,1,1), family="sans")
  plot.new(); plot.window(xlim=c(0,100), ylim=c(0,100))
  box <- function(y, txt, w=52, x=38, cex=0.78, fill="white") {
    rect(x-w/2, y-3.6, x+w/2, y+3.6, col=fill, border="black", lwd=1); text(x, y, txt, cex=cex)
  }
  ex <- function(y, txt) {
    segments(38+26, y, 72, y, lwd=1); segments(72, y, 72, y-4.5, lwd=1)
    rect(74, y-8, 99, y-1, col="grey95", border="grey40", lwd=0.8)
    text(86.5, y-4.5, txt, cex=0.58)
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
  box(11, "Final cohort\nn = 3,963; 30-day deaths 832 (21.0%)", w=58, fill="grey92")
  ex(11, "Excluded 223\nsepsis timing outside +/-24 h")
  arrows(38,91.4,38,86.6,length=0.07); arrows(38,79.4,38,74.6,length=0.07)
  arrows(38,67.4,38,62.6,length=0.07); arrows(38,55.4,38,50.6,length=0.07)
  arrows(38,43.4,38,38.6,length=0.07); arrows(38,31.4,38,26.6,length=0.07)
  arrows(38,19.4,38,14.6,length=0.07)
}
pdf("figures/final_Fig1_flow.pdf", width=7.4, height=8.8); draw(); dev.off()
png("figures/final_Fig1_flow.png", width=7.4, height=8.8, units="in", res=200); draw(); dev.off()

## ---- Fig2 two panels ----
a <- f
a$cong <- factor(ifelse(a$cong_hybrid == 1, "Congestion +", "Congestion -"), levels=c("Congestion +","Congestion -"))
a$fb <- factor(ifelse(a$fb72_mlkg > 0, "Balance > 0", "Balance <= 0"), levels=c("Balance <= 0","Balance > 0"))
tb <- table(a$cong, a$fb); rn <- prop.table(tb,1)*100
dA <- data.frame(cong=rep(rownames(tb), times=ncol(tb)), fb=rep(colnames(tb), each=nrow(tb)),
                 n=as.vector(tb), pct=as.vector(rn))
dA$cong <- factor(dA$cong, levels=c("Congestion +","Congestion -")); dA$fb <- factor(dA$fb, levels=c("Balance <= 0","Balance > 0"))
pA <- ggplot(dA, aes(fb, cong, fill=pct)) + geom_tile(colour="white", linewidth=1.2) +
  geom_text(aes(label=sprintf("n = %d\n%.1f%%", n, pct)), size=3.8, lineheight=0.95) +
  scale_fill_gradient(low="#f7f7f7", high="#bdbdbd", guide="none") +
  labs(x=NULL, y=NULL, title="A  Agreement (row %)", subtitle="Cohen's kappa = -0.11") +
  theme_minimal(base_size=10) + theme(panel.grid=element_blank(),
    plot.title=element_text(face="bold", size=10), plot.subtitle=element_text(size=9))
ag <- aggregate(death30 ~ cong + fb, data=a, FUN=function(x) c(n=length(x), m=100*mean(x)))
dB <- data.frame(cong=ag$cong, fb=ag$fb, n=ag$death30[,"n"], mort=ag$death30[,"m"])
dB$cong <- factor(dB$cong, levels=c("Congestion +","Congestion -")); dB$fb <- factor(dB$fb, levels=c("Balance <= 0","Balance > 0"))
pB <- ggplot(dB, aes(fb, cong, fill=mort)) + geom_tile(colour="white", linewidth=1.2) +
  geom_text(aes(label=sprintf("n = %d\n%.1f%%", n, mort)), size=3.8, lineheight=0.95) +
  scale_fill_gradient(low="#e8f3fb", high="#b2182b", name="30-day\nmortality (%)") +
  labs(x=NULL, y=NULL, title="B  30-day mortality (unadjusted)") +
  theme_minimal(base_size=10) + theme(panel.grid=element_blank(), plot.title=element_text(face="bold", size=10))
ggsave("figures/final_Fig2_2x2.pdf", pA|pB, width=9.2, height=4.0)
ggsave("figures/final_Fig2_2x2.png", pA|pB, width=9.2, height=4.0, dpi=300)

## ---- Fig3 KM ----
dx <- as.numeric(difftime(f$dt, f$intime, units="days"))
f$time <- pmin(ifelse(is.na(dx), 30, dx), 30); f$event <- f$death30; f$time[f$time<0] <- 0
sf <- survfit(Surv(time, event) ~ grp, data=f)
labs <- c(A="A  congestion- / balance<=0", B="B  congestion- / balance>0",
          C="C  congestion+ / balance<=0", D="D  congestion+ / balance>0")
pc <- function() {
  par(mar=c(4.4,4.6,2.2,1))
  plot(sf, col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, mark.time=FALSE,
       xlab="Days since ICU admission", ylab="Cumulative survival", cex.lab=1.05, cex.axis=0.95, las=1)
  legend("bottomleft", legend=paste0(labs[levels(f$grp)], " (n=", as.numeric(table(f$grp)), ")"),
         col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, bty="n", cex=0.8)
}
pdf("figures/final_Fig3_KM.pdf", width=6.6, height=5.0); pc(); dev.off()
png("figures/final_Fig3_KM.png", width=6.6, height=5.0, units="in", res=200); pc(); dev.off()

## ---- Fig4 forest ----
fr <- data.frame(
  label=c("Main (72 h, hybrid)","S1 findings-first","S3 landmark 72 h","S4 excluding heart failure",
          "S5 frontal films only","S6 24-h fluid window","S9 output complete","S11 in-hospital death",
          "S12 strict definition","S15 lactate fallback","S16 no plausibility screen"),
  OR=c(1.59,1.58,1.67,2.41,1.54,1.13,1.46,1.60,1.93,1.57,1.61),
  lcl=c(1.08,1.08,1.11,1.37,1.05,0.77,0.98,0.97,1.17,1.07,1.12),
  ucl=c(2.33,2.31,2.50,4.26,2.27,1.67,2.19,2.63,3.19,2.30,2.33))
fr$label <- factor(fr$label, levels=rev(fr$label))
p4 <- ggplot(fr, aes(OR, label)) + geom_vline(xintercept=1, linetype="dashed", colour="grey50") +
  geom_errorbar(aes(xmin=lcl, xmax=ucl), width=0.18, colour="#2166ac") +
  geom_point(size=2.6, colour="#2166ac") +
  scale_x_log10(breaks=c(0.75,1,1.5,2,3,4), labels=c("0.75","1.0","1.5","2.0","3.0","4.0")) +
  labs(x="Odds ratio (group C vs A, log scale)", y=NULL,
       title="Discordant congestion and 30-day mortality: primary and sensitivity analyses") +
  theme_bw(base_size=10) + theme(plot.title=element_text(size=9.5, face="bold"), panel.grid.minor=element_blank())
ggsave("figures/final_Fig4_forest.pdf", p4, width=6.8, height=4.4)
ggsave("figures/final_Fig4_forest.png", p4, width=6.8, height=4.4, dpi=300)
cat("figures done\n")
