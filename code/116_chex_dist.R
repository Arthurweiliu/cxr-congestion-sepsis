setwd("F:/openclaw_workspace/CXR_congestion")
u <- read.csv("data/unknown_set.csv", stringsAsFactors = FALSE)
cat("rows:", nrow(u), "\n")
cat("cls_imp x chex_edema (never-described reports only):\n")
print(table(u$cls_imp, u$chex_edema, useNA = "ifany"))
sil <- u[u$cls_imp == "unknown", ]
cat("\nsilent reports n =", nrow(sil), "\n")
cat("chex_edema in silent: pos", sum(sil$chex_edema == 1, na.rm=TRUE),
    " neg", sum(sil$chex_edema == 0, na.rm=TRUE),
    " unsure", sum(sil$chex_edema == -1, na.rm=TRUE),
    " blank", sum(is.na(sil$chex_edema)), "\n")
