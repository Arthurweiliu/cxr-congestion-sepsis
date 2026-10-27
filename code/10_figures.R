setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages({library(ggplot2); library(survival); library(scales)})

d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F")
d$intime <- as.POSIXct(d$intime, tz = "UTC")
d$deathtime <- as.POSIXct(ifelse(d$deathtime %in% c("",NA), NA, d$deathtime), tz = "UTC")
d$dod <- as.Date(ifelse(d$dod %in% c("",NA), NA, d$dod))
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid==1, ifelse(a$fb72_mlkg>0,"D","C"),
                       ifelse(a$fb72_mlkg>0,"B","A")), levels=c("A","B","C","D"))
labs <- c(A="A  congestion- / balance<=0", B="B  congestion- / balance>0",
          C="C  congestion+ / balance<=0", D="D  congestion+ / balance>0")

## Fig1 flow
pdf("figures/Fig1_flow.pdf", width=7.4, height=8.6); par(mar=c(1,1,1,1), family="sans")
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

## Fig2 heatmap
a$cong <- ifelse(a$cong_hybrid==1,"Congestion +","Congestion -")
a$fb   <- ifelse(a$fb72_mlkg>0,"Balance > 0","Balance <= 0")
agg <- aggregate(death30 ~ cong + fb, data=a, FUN=function(x) c(n=length(x), m=100*mean(x)))
hm <- data.frame(cong=agg$cong, fb=agg$fb, n=agg$death30[,"n"], mort=agg$death30[,"m"])
hm$cong <- factor(hm$cong, levels=c("Congestion +","Congestion -"))
hm$fb <- factor(hm$fb, levels=c("Balance <= 0","Balance > 0"))
p2 <- ggplot(hm, aes(fb, cong, fill=mort)) +
  geom_tile(colour="white", linewidth=1.2) +
  geom_text(aes(label=sprintf("n = %d\n%.1f%%", n, mort)), size=4.1, lineheight=0.95) +
  scale_fill_gradient(low="#e8f3fb", high="#b2182b", name="30-day\nmortality (%)") +
  labs(x=NULL, y=NULL, title="30-day mortality by radiographic congestion and fluid balance") +
  theme_minimal(base_size=11) +
  theme(panel.grid=element_blank(), plot.title=element_text(size=10.5, face="bold"))
ggsave("figures/Fig2_2x2.pdf", p2, width=5.8, height=4.2)
ggsave("figures/Fig2_2x2.png", p2, width=5.8, height=4.2, dpi=300)

## Fig3 KM
dd <- a
dx <- as.numeric(difftime(dd$deathtime, dd$intime, units="days"))
dz <- as.numeric(dd$dod - as.Date(dd$intime))
tt <- ifelse(!is.na(dx), dx, ifelse(!is.na(dz), dz, 30))
dd$time <- pmin(tt, 30); dd$event <- dd$death30
dd$time[dd$time < 0] <- 0
sf <- survfit(Surv(time, event) ~ grp, data=dd)
pdf("figures/Fig3_KM.pdf", width=6.6, height=5.0); par(mar=c(4.4,4.6,2.2,1))
plot(sf, col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, mark.time=FALSE,
     xlab="Days since ICU admission", ylab="Cumulative survival", cex.lab=1.05,
     cex.axis=0.95, las=1)
legend("bottomleft", legend=paste0(labs[levels(dd$grp)], " (n=", as.numeric(table(dd$grp)), ")"),
       col=c("#4d4d4d","#4393c3","#d6604d","#b2182b"), lwd=2, bty="n", cex=0.8)
dev.off()

## Fig4 forest
fr <- data.frame(
  label = c("Main (72 h, hybrid)","Landmark 72 h","S1 findings-first","S2 unknown as negative",
            "S4 excluding heart failure","S5 frontal films only","S6 24-h fluid window",
            "S9 output complete","S10 unknown as category","S11 in-hospital death","S12 strict definition"),
  OR = c(1.62,1.67,1.61,1.62,2.32,1.59,1.14,1.47,1.61,1.73,1.88),
  lcl= c(1.12,1.13,1.11,1.12,1.34,1.09,0.78,1.00,1.11,1.08,1.16),
  ucl= c(2.34,2.46,2.33,2.35,4.01,2.30,1.66,2.17,2.32,2.77,3.03))
fr$label <- factor(fr$label, levels=rev(fr$label))
p4 <- ggplot(fr, aes(OR, label)) +
  geom_vline(xintercept=1, linetype="dashed", colour="grey50") +
  geom_errorbar(aes(xmin=lcl, xmax=ucl), width=0.18, colour="#2166ac") +
  geom_point(size=2.6, colour="#2166ac") +
  scale_x_log10(breaks=c(0.75,1,1.5,2,3,4), labels=c("0.75","1.0","1.5","2.0","3.0","4.0")) +
  labs(x="Odds ratio (group C vs A, log scale)", y=NULL,
       title="Discordant congestion and 30-day mortality: primary and sensitivity analyses") +
  theme_bw(base_size=10) +
  theme(plot.title=element_text(size=9.5, face="bold"), panel.grid.minor=element_blank())
ggsave("figures/Fig4_forest.pdf", p4, width=6.8, height=4.4)
ggsave("figures/Fig4_forest.png", p4, width=6.8, height=4.4, dpi=300)

cat("done\n"); print(list.files("figures"))
