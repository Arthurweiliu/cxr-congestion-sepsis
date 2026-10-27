setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(survival); library(patchwork)})

DPI <- 600
f <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f$dt <- as.POSIXct(ifelse(f$deathtime %in% c("", NA), NA, f$deathtime), tz = "UTC")
f$grp <- factor(ifelse(f$cong_hybrid == 1, ifelse(f$fb72_mlkg > 0, "D", "C"),
                       ifelse(f$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

## ---------- Fig 1 ----------
flow <- function() {
  par(mar = c(0.6,0.6,0.6,0.6), family = "sans")
  plot.new(); plot.window(xlim = c(0,100), ylim = c(0,100))
  box <- function(y, txt, w = 46, x = 33, cex = 0.8, fill = "white", h = 4.2) {
    rect(x-w/2, y-h, x+w/2, y+h, col = fill, border = "black", lwd = 1.1); text(x, y, txt, cex = cex)
  }
  ex <- function(y, txt, nlines = 2, cex = 0.62) {
    segments(33+23, y, 68, y, lwd = 1); segments(68, y, 68, y-2.2, lwd = 1)
    rect(69, y-2-2.1*nlines-1, 99, y-0.5, col = "grey95", border = "grey45", lwd = 0.8)
    text(84, y-2-2.1*nlines/2, txt, cex = cex)
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
  arrows(33,88.4,33,83.6,length=0.07); arrows(33,74.4,33,69.6,length=0.07)
  arrows(33,60.4,33,55.6,length=0.07); arrows(33,46.4,33,41.6,length=0.07)
  arrows(33,32.4,33,25.6,length=0.07)
}
tiff("figures/Fig1_flow_600dpi.tiff", width = 7.0, height = 7.0, units = "in",
     res = DPI, compression = "lzw", type = "windows"); flow(); dev.off()

## ---------- Fig 2 ----------
a <- f
a$cong <- factor(ifelse(a$cong_hybrid == 1, "Congestion +", "Congestion -"), levels = c("Congestion +","Congestion -"))
a$fb <- factor(ifelse(a$fb72_mlkg > 0, "Balance > 0", "Balance <= 0"), levels = c("Balance <= 0","Balance > 0"))
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
ggsave("figures/Fig2_2x2_600dpi.tiff", pA|pB, width=9.2, height=4.0, dpi=DPI,
       device="tiff", compression="lzw")

## ---------- Fig 3 ----------
dx <- as.numeric(difftime(f$dt, f$intime, units="days"))
f$time <- pmin(ifelse(is.na(dx), 30, dx), 30); f$event <- f$death30; f$time[f$time<0] <- 0
sf <- survfit(Surv(time, event) ~ grp, data=f)
labs <- c(A="A  congestion- / balance<=0", B="B  congestion- / balance>0",
          C="C  congestion+ / balance<=0", D="D  congestion+ / balance>0")
cols <- c("#4d4d4d","#4393c3","#d6604d","#b2182b")
km <- function() {
  par(mar=c(4.6,4.8,2.2,1), family="sans")
  plot(sf, col=cols, lwd=2, mark.time=FALSE, ylim=c(0,1),
       xlab="Days since ICU admission", ylab="Cumulative survival",
       cex.lab=1.05, cex.axis=0.95, las=1, yaxt="n")
  axis(2, at=seq(0,1,0.2), labels=sprintf("%.0f%%", seq(0,100,20)), las=1, cex.axis=0.95)
  legend("bottomleft", legend=paste0(labs[levels(f$grp)], " (n=", as.numeric(table(f$grp)), ")"),
         col=cols, lwd=2, bty="n", cex=0.8)
}
tiff("figures/Fig3_KM_600dpi.tiff", width=6.6, height=5.0, units="in",
     res=DPI, compression="lzw", type="windows"); km(); dev.off()

## ---------- Fig 4 ----------
fr <- data.frame(
  label=c("Main (72 h, hybrid)","S1 findings-first","S2 unknown as negative","S3 landmark 72 h",
          "S4 excluding heart failure","S5 frontal films only","S6 24-h fluid window",
          "S9 output complete","S10 unknown as category","S11 in-hospital death",
          "S12 strict definition","S15 lactate fallback","S16 no plausibility screen"),
  OR =c(1.59,1.58,1.53,1.67,2.41,1.54,1.13,1.46,1.60,1.60,1.93,1.57,1.61),
  lcl=c(1.08,1.08,1.10,1.11,1.37,1.05,0.77,0.98,1.09,0.97,1.17,1.07,1.12),
  ucl=c(2.33,2.31,2.15,2.50,4.26,2.27,1.67,2.19,2.34,2.63,3.19,2.30,2.33))
fr$label <- factor(fr$label, levels=rev(fr$label))
p4 <- ggplot(fr, aes(OR, label)) + geom_vline(xintercept=1, linetype="dashed", colour="grey50") +
  geom_errorbar(aes(xmin=lcl, xmax=ucl), width=0.18, colour="#2166ac") +
  geom_point(size=2.4, colour="#2166ac") +
  scale_x_log10(breaks=c(0.75,1,1.5,2,3,4), labels=c("0.75","1.0","1.5","2.0","3.0","4.0")) +
  labs(x="Odds ratio (group C vs A, log scale)", y=NULL,
       title="Discordant congestion and 30-day mortality: primary and 13 sensitivity analyses",
       caption="S2 and S10 use a larger denominator (n=5,692) in which unclassifiable films are retained.") +
  theme_bw(base_size=9.5) + theme(plot.title=element_text(size=9, face="bold"),
    plot.caption=element_text(size=7, hjust=0), panel.grid.minor=element_blank())
ggsave("figures/Fig4_forest_600dpi.tiff", p4, width=7.0, height=4.8, dpi=DPI,
       device="tiff", compression="lzw")

cat("TIFF written at", DPI, "dpi\n")
print(list.files("figures", pattern = "600dpi", full.names = FALSE))
