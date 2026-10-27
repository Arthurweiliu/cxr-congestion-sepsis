setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/final_with_lac.csv", stringsAsFactors = FALSE)
d$fbpos <- as.integer(d$fb72_mlkg > 0)

agree <- function(x, y, label) {
  tb <- table(factor(x, levels = c(0,1)), factor(y, levels = c(0,1)))
  n <- sum(tb)
  a <- tb[2,2]; b <- tb[2,1]; c <- tb[1,2]; dd <- tb[1,1]
  po <- (a + dd) / n
  pe <- (sum(tb[2,]) * sum(tb[,2]) + sum(tb[1,]) * sum(tb[,1])) / n^2
  kappa <- (po - pe) / (1 - pe)
  pabak <- 2 * po - 1
  ppos <- 2 * a / (2 * a + b + c)
  pneg <- 2 * dd / (2 * dd + b + c)
  data.frame(definition = label, n = n, observed = round(po, 3), expected = round(pe, 3),
             kappa = round(kappa, 3), PABAK = round(pabak, 3),
             Ppos = round(ppos, 3), Pneg = round(pneg, 3))
}

rows <- rbind(
  agree(d$cong_hybrid, d$fbpos, "Hybrid (primary)"),
  agree(d$cong_s1, d$fbpos, "Findings-first"),
  agree(d$cong_primary, d$fbpos, "Strict impression-only")
)
print(rows, row.names = FALSE)

lines <- c("# Table S2. Agreement between radiographic congestion and 72-h fluid balance", "",
  "κ = Cohen's kappa; PABAK = prevalence-adjusted bias-adjusted kappa (2·Po − 1);",
  "Ppos/Pneg = positive and negative agreement (Byrt et al.).", "",
  "| Definition | n | Observed agreement | Expected agreement | κ | PABAK | Ppos | Pneg |",
  "|---|---:|---:|---:|---:|---:|---:|---:|")
for (i in seq_len(nrow(rows))) {
  lines <- c(lines, sprintf("| %s | %d | %.3f | %.3f | %.3f | **%.3f** | %.3f | %.3f |",
    rows$definition[i], rows$n[i], rows$observed[i], rows$expected[i],
    rows$kappa[i], rows$PABAK[i], rows$Ppos[i], rows$Pneg[i]))
}
lines <- c(lines, "",
  "**Interpretation.** Observed agreement is lower than expected by chance under all three definitions.",
  "Because positive balance is common (77%), κ is depressed by prevalence imbalance; PABAK corrects for this",
  "and remains strongly negative, indicating that the low agreement is not an artefact of prevalence alone.",
  "Positive and negative agreement differ (Ppos > Pneg), showing that the two measures concur more often when",
  "both are positive than when both are negative.")
writeLines(enc2utf8(lines), con = file("tables/S2_agreement.md", "w", encoding = "UTF-8"))
cat("\nwritten tables/S2_agreement.md\n")
