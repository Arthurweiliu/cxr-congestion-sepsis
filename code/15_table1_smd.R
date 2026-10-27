setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F")
d$lac <- d$lac_any
a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

smd_cont <- function(x, g, ref) {
  m1 <- mean(x[g], na.rm=TRUE); m0 <- mean(x[ref], na.rm=TRUE)
  s1 <- sd(x[g], na.rm=TRUE);   s0 <- sd(x[ref], na.rm=TRUE)
  (m1 - m0) / sqrt((s1^2 + s0^2)/2)
}
smd_bin <- function(x, g, ref) {
  p1 <- mean(x[g] == 1, na.rm=TRUE); p0 <- mean(x[ref] == 1, na.rm=TRUE)
  (p1 - p0) / sqrt((p1*(1-p1) + p0*(1-p0))/2)
}
med_iqr <- function(x) sprintf("%.1f (%.1f–%.1f)", median(x, na.rm=TRUE),
                               quantile(x,.25,na.rm=TRUE), quantile(x,.75,na.rm=TRUE))
mean_sd <- function(x) sprintf("%.1f ± %.1f", mean(x, na.rm=TRUE), sd(x, na.rm=TRUE))
pct <- function(x) sprintf("%d (%.1f)", sum(x==1, na.rm=TRUE), 100*mean(x==1, na.rm=TRUE))

idx <- lapply(c("A","B","C","D"), function(g) which(a$grp == g)); names(idx) <- c("A","B","C","D")
ref <- idx[["A"]]

cont <- c("age","sofa_score","lac","fb72_mlkg")
bin  <- c("female","vent24","vaso24","hf","ckd")
labels <- c(age="Age, years", sofa_score="SOFA score", lac="Lactate, mmol/L (max, day 1)",
            fb72_mlkg="72-h fluid balance, mL/kg", female="Female sex",
            vent24="Invasive ventilation, day 1", vaso24="Vasopressor use, day 1",
            hf="History of heart failure", ckd="Chronic kidney disease")

lines <- c("# Table 1. Baseline characteristics by group", "",
  sprintf("Analytic cohort n = %d; 30-day deaths %d (%.1f%%)", nrow(a), sum(a$death30), 100*mean(a$death30)), "",
  sprintf("Groups: A = no radiographic congestion / balance ≤0 (n=%d); B = no congestion / balance >0 (n=%d); C = congestion / balance ≤0 (n=%d); D = congestion / balance >0 (n=%d)",
          length(idx$A), length(idx$B), length(idx$C), length(idx$D)), "",
  "| Variable | A (n=503) | B (n=2358) | C (n=471) | D (n=1020) | SMD B vs A | SMD C vs A | SMD D vs A |",
  "|---|---|---|---|---|---:|---:|---:|")

for (v in cont) {
  vals <- sapply(idx, function(i) med_iqr(a[[v]][i]))
  sm <- sapply(c("B","C","D"), function(g) sprintf("%.2f", smd_cont(a[[v]], idx[[g]], ref)))
  lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", labels[[v]],
                            vals[1], vals[2], vals[3], vals[4], sm[1], sm[2], sm[3]))
}
for (v in bin) {
  vals <- sapply(idx, function(i) pct(a[[v]][i]))
  sm <- sapply(c("B","C","D"), function(g) sprintf("%.2f", smd_bin(a[[v]], idx[[g]], ref)))
  lines <- c(lines, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s |", labels[[v]],
                            vals[1], vals[2], vals[3], vals[4], sm[1], sm[2], sm[3]))
}
vals <- sapply(idx, function(i) pct(a$death30[i]))
sm <- sapply(c("B","C","D"), function(g) sprintf("%.2f", smd_bin(a$death30, idx[[g]], ref)))
lines <- c(lines, sprintf("| **30-day mortality** | %s | %s | %s | %s | %s | %s | %s |", vals[1], vals[2], vals[3], vals[4], sm[1], sm[2], sm[3]))

writeLines(enc2utf8(lines), con = file("tables/T1_baseline_by_group.md", "w", encoding = "UTF-8"))
cat(paste(lines, collapse="\n"), "\n")
