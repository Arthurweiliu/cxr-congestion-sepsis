setwd("F:/openclaw_workspace/CXR_congestion")
f <- read.csv("data/final_with_lac.csv")
fb <- read.csv("data/fb_film.csv")[, c("stay_id","fb_film_mlkg","intake","output")]
m <- merge(f, fb, by = "stay_id", all.x = TRUE)
names(m)[names(m) == "intake"] <- "fb_intake"
names(m)[names(m) == "output"] <- "fb_output"
# an empty film-anchored window means the film chart time could not be recovered;
# the film-anchored balance is then not calculable, not zero
nodata <- is.na(m$fb_intake) | (m$fb_intake == 0 & m$fb_output == 0)
cat("film-anchored window empty (set to NA):", sum(nodata), "\n")
m$fb72_mlkg <- ifelse(nodata, NA, m$fb_film_mlkg)
m$fb_film_mlkg <- NULL
m$fb_intake <- NULL
m$fb_output <- NULL
# plausibility screen applied to the analysis variable
m <- m[!is.na(m$fb72_mlkg) & m$fb72_mlkg >= -100 & m$fb72_mlkg <= 300, ]
m$grp <- factor(ifelse(m$cong_hybrid == 1, ifelse(m$fb72_mlkg > 0, "D", "C"),
                       ifelse(m$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))
write.csv(m, "data/film_analysis.csv", row.names = FALSE)
cat("rows:", nrow(m), " deaths:", sum(m$death30), "\n")
print(table(m$grp))
