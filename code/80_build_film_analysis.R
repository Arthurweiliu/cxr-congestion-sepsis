setwd("F:/openclaw_workspace/CXR_congestion")
f <- read.csv("data/final_with_lac.csv")
fb <- read.csv("data/fb_film.csv")[, c("stay_id","fb_film_mlkg")]
m <- merge(f, fb, by = "stay_id", all.x = TRUE)
m$fb72_mlkg <- m$fb_film_mlkg
m$grp <- factor(ifelse(m$cong_hybrid == 1, ifelse(m$fb72_mlkg > 0, "D", "C"),
                       ifelse(m$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
m$fb_film_mlkg <- NULL
write.csv(m, "data/film_analysis.csv", row.names = FALSE)
cat("rows:", nrow(m), " missing balance:", sum(is.na(m$fb72_mlkg)), "\n")
print(table(m$grp))
