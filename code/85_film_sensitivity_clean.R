setwd("F:/openclaw_workspace/CXR_congestion")
.libPaths(c("F:/openclaw_workspace/Rlibs", "F:/openclaw_workspace/R_lib", .libPaths()))
suppressPackageStartupMessages(library(mice))

f <- read.csv("data/film_analysis.csv", stringsAsFactors = FALSE)
f$intime <- as.POSIXct(f$intime, tz = "UTC")
f <- merge(f, read.csv("data/fb24_film.csv"), by = "stay_id", all.x = TRUE)

# lactate fallback: nearest value in -24..+72 h
L <- read.csv("lac.csv", stringsAsFactors = FALSE)
L$charttime <- as.POSIXct(L$charttime, tz = "UTC")
L <- L[!is.na(L$valuenum) & L$valuenum >= 0.1 & L$valuenum <= 30, c("subject_id","charttime","valuenum")]
mm <- merge(f[, c("stay_id","subject_id","intime")], L, by = "subject_id", allow.cartesian = TRUE)
mm$dt <- as.numeric(difftime(mm$charttime, mm$intime, units = "hours"))
s2 <- mm[mm$dt >= -24 & mm$dt <= 72, ]; s2$absdt <- abs(s2$dt)
s2 <- s2[order(s2$stay_id, s2$absdt), ]
L2 <- setNames(s2$valuenum[!duplicated(s2$stay_id)], s2$stay_id[!duplicated(s2$stay_id)])
f$lacL2 <- ifelse(is.na(f$lac), as.numeric(L2[as.character(f$stay_id)]), f$lac)

mk <- function(df, cong = "cong_hybrid", fb = "fb72_mlkg") {
  df <- df[!is.na(df[[cong]]) & !is.na(df[[fb]]), ]
  g <- ifelse(df[[cong]] == 1, ifelse(df[[fb]] > 0, "D", "C"), ifelse(df[[fb]] > 0, "B", "A"))
  df$grp <- droplevels(factor(g, levels = c("A","B","C","D")))
  df
}

runMI <- function(dat, lacvar = "lac", m = 20, seed = 20261023) {
  dd <- data.frame(death30 = dat$death30, grp = dat$grp, age = dat$age, female = dat$female,
                   sofa = dat$sofa_score, lac = dat[[lacvar]], vent = dat$vent24,
                   vaso = dat$vaso24, hf = dat$hf, ckd = dat$ckd)
  dd <- dd[complete.cases(dd[, c("death30","grp","age","female","sofa","vent","vaso","hf","ckd")]), ]
  set.seed(seed)
  imp <- mice(dd, m = m, printFlag = FALSE)
  fits <- lapply(1:m, function(i) glm(death30 ~ grp + age + female + sofa + lac + vent + vaso + hf + ckd,
                                      data = complete(imp, i), family = binomial))
  B <- sapply(fits, coef); b <- rowMeans(B)
  T <- Reduce("+", lapply(fits, vcov))/m + (1 + 1/m)*cov(t(B)); se <- sqrt(diag(T))
  idx <- grep("^grp", names(b))
  W <- as.numeric(t(b[idx]) %*% solve(T[idx, idx]) %*% b[idx])
  data.frame(term = names(b)[idx], OR = exp(b[idx]), lcl = exp(b[idx]-1.96*se[idx]),
             ucl = exp(b[idx]+1.96*se[idx]), n = nrow(dd), deaths = sum(dd$death30),
             pjoint = pchisq(W, length(idx), lower.tail = FALSE))
}

rows <- list()
add <- function(lbl, r) {
  stopifnot(nrow(r) == 3, all(is.finite(r$OR)), all(r$OR > 0.2 & r$OR < 20))
  rows[[length(rows)+1]] <<- sprintf("| %s | %d | %d | %.2f (%.2f-%.2f) | **%.2f (%.2f-%.2f)** | %.2f (%.2f-%.2f) | %.2g |",
    lbl, r$n[1], r$deaths[1], r$OR[1], r$lcl[1], r$ucl[1], r$OR[2], r$lcl[2], r$ucl[2], r$OR[3], r$lcl[3], r$ucl[3], r$pjoint[1])
  cat("ok:", lbl, "\n")
}

add("Main analysis", runMI(mk(f)))
add("S1 Findings-first definition", runMI(mk(f, "cong_s1")))
add("S3 Landmark at 72 h", {
  dt <- suppressWarnings(as.POSIXct(ifelse(is.na(f$deathtime) | f$deathtime == "", NA, f$deathtime), tz = "UTC"))
  runMI(mk(f[is.na(dt) | dt > f$intime + 3*86400, ]))
})
add("S4 Excluding heart failure", runMI(mk(f[f$hf == 0, ])))
add("S5 Frontal radiographs only", runMI(mk(f[f$frontal == 1, ])))
add("S6 Film-anchored 24-h balance", runMI(mk(f, "cong_hybrid", "fb24_film")))
add("S9 Complete output recording", runMI(mk(f[f$output_complete == 1, ])))
add("S12 Strict impression-only", {
  s <- f[f$cls_imp != "unknown", ]
  s$cong_strict <- as.integer(s$cls_imp == "pos_explicit")
  runMI(mk(s, "cong_strict"))
})
add("S11 In-hospital mortality", { g <- f; g$death30 <- g$death_hosp; runMI(mk(g)) })
add("S15 Lactate fallback hierarchy", runMI(mk(f), lacvar = "lacL2"))

hdr <- c("# Table S3. Sensitivity analyses (film-anchored exposure)", "",
  "Exposure: radiographic congestion on the index film, and fluid balance accrued over the 72 h after that film.",
  "Multiple imputation (m = 20); adjusted for age, sex, SOFA, lactate, ventilation, vasopressors, heart failure and chronic kidney disease.", "",
  "| Specification | N | Deaths | B | C | D | Joint p |", "|---|---:|---:|---|---|---|---:|")
writeLines(enc2utf8(c(hdr, unlist(rows))), "v4/film/S3.md")
cat("\nwritten v4/film/S3.md\n")
