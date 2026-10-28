setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))

u <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
u$intime <- as.POSIXct(u$intime, tz = "UTC")
u$female <- as.integer(u$gender == "F")

L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
mm <- merge(u[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
h <- mm$charttime >= mm$intime - 6*3600 & mm$charttime < mm$intime + 24*3600
s <- tapply(mm$valuenum[h], mm$stay_id[h], max)
u$lac <- as.numeric(s[as.character(u$stay_id)])
u$lac[u$lac < 0.5 | u$lac > 20] <- NA
cat("lac coverage:", sum(!is.na(u$lac)), sprintf("(%.1f%%)\n", 100*mean(!is.na(u$lac))))

d <- merge(u, read.csv("data/fb_film_unknown.csv")[, c("stay_id","fb72_film")], by = "stay_id", all.x = TRUE)
d$unknown <- as.integer(is.na(d$cong_hybrid))
d$cong2 <- ifelse(is.na(d$cong_hybrid), 0, d$cong_hybrid)

mk <- function(df, cong, fbcol = "fb72_film") {
  g <- ifelse(df[[cong]] == 1, ifelse(df[[fbcol]] > 0, "D", "C"), ifelse(df[[fbcol]] > 0, "B", "A"))
  df$grp <- factor(g, levels = c("A","B","C","D")); df
}

runMI <- function(dat, ex = "grp", m = 20, seed = 20261023) {
  dd <- data.frame(death30 = dat$death30, ex = dat[[ex]], age = dat$age, female = dat$female,
                   sofa = dat$sofa_score, lac = dat$lac, vent = dat$vent24,
                   vaso = dat$vaso24, hf = dat$hf, ckd = dat$ckd)
  dd <- dd[complete.cases(dd[, c("death30","ex","age","female","sofa","vent","vaso","hf","ckd")]), ]
  dd$ex <- droplevels(factor(dd$ex))
  set.seed(seed)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ ex + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B)); se <- sqrt(diag(T))
  idx <- grep("^ex", names(b))
  W <- as.numeric(t(b[idx]) %*% solve(T[idx, idx]) %*% b[idx])
  data.frame(term = names(b)[idx], OR = exp(b[idx]), lcl = exp(b[idx]-1.96*se[idx]),
             ucl = exp(b[idx]+1.96*se[idx]), n = nrow(dd), deaths = sum(dd$death30),
             pjoint = pchisq(W, length(idx), lower.tail = FALSE))
}

cat("\nS2 unknown as negative\n")
s2 <- runMI(mk(d, "cong2")); print(s2, digits = 3, row.names = FALSE)

cat("\nS10 unknown as separate category\n")
d$exposure <- ifelse(d$unknown == 1, "U",
  ifelse(d$cong_hybrid == 1, ifelse(d$fb72_film > 0, "D", "C"), ifelse(d$fb72_film > 0, "B", "A")))
d$exposure <- factor(d$exposure, levels = c("A","B","C","D","U"))
s10 <- runMI(d, "exposure"); print(s10, digits = 3, row.names = FALSE)

Lout <- c("# Table S3 (extended). Analyses that include unclassifiable reports", "",
  sprintf("S2: unknown reports classified as negative (n = %d). S10: unknown reports as a separate category.", nrow(d)),
  "Film-anchored 72-h balance; multiple imputation (m = 20); covariates as in the main model.", "",
  "| Analysis | N | Deaths | B | C | D | U | Joint p |", "|---|---:|---:|---|---|---|---|---:|",
  sprintf("| S2 unknown as negative | %d | %d | %.2f (%.2f-%.2f) | %.2f (%.2f-%.2f) | %.2f (%.2f-%.2f) | - | %.2g |",
    s2$n[1], s2$deaths[1], s2$OR[1], s2$lcl[1], s2$ucl[1], s2$OR[2], s2$lcl[2], s2$ucl[2], s2$OR[3], s2$lcl[3], s2$ucl[3], s2$pjoint[1]),
  sprintf("| S10 unknown as separate category | %d | %d | %.2f (%.2f-%.2f) | %.2f (%.2f-%.2f) | %.2f (%.2f-%.2f) | %.2f (%.2f-%.2f) | %.2g |",
    s10$n[1], s10$deaths[1], s10$OR[1], s10$lcl[1], s10$ucl[1], s10$OR[2], s10$lcl[2], s10$ucl[2], s10$OR[3], s10$lcl[3], s10$ucl[3], s10$OR[4], s10$lcl[4], s10$ucl[4], s10$pjoint[1]))
writeLines(enc2utf8(Lout), "v4/film/S3_extended.md")
cat("\nwritten v4/film/S3_extended.md\n")
