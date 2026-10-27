setwd("F:/openclaw_workspace/CXR_congestion")
d <- read.csv("data/base.csv", stringsAsFactors = FALSE)
d$female <- as.integer(d$gender == "F"); d$lac <- d$lac_any
d$has_film <- d$has_film %in% c("t","TRUE","True",TRUE)
d$has_note <- d$has_note %in% c("t","TRUE","True",TRUE)

a <- d[!is.na(d$cong_hybrid) & !is.na(d$fb72_mlkg) & !is.na(d$death30), ]
a$grp <- factor(ifelse(a$cong_hybrid == 1, ifelse(a$fb72_mlkg > 0, "D", "C"),
                       ifelse(a$fb72_mlkg > 0, "B", "A")), levels = c("A","B","C","D"))

fmt_med <- function(x) sprintf("%.1f (%.1f-%.1f)", median(x, na.rm=TRUE),
                               quantile(x,.25,na.rm=TRUE), quantile(x,.75,na.rm=TRUE))
fmt_p <- function(x) sprintf("%.1f", 100*mean(x==1, na.rm=TRUE))

vars_num <- c("age","sofa_score","lac","fb72_mlkg")
vars_bin <- c("female","vent24","vaso24","hf","ckd","death30","death_hosp")

lines <- c("# Table 1. 基线特征（按四组）", "",
           sprintf("N = %d；30 天死亡 %d (%.1f%%)", nrow(a), sum(a$death30), 100*mean(a$death30)), "",
           "| 变量 | A 影像−/负平衡 (n=503) | B 影像−/正平衡 (n=2358) | C 影像+/负平衡 (n=471) | D 影像+/正平衡 (n=1020) |",
           "|---|---|---|---|---|")
for (v in vars_num) {
  lines <- c(lines, sprintf("| %s | %s | %s | %s | %s |", v,
    fmt_med(a[[v]][a$grp=="A"]), fmt_med(a[[v]][a$grp=="B"]),
    fmt_med(a[[v]][a$grp=="C"]), fmt_med(a[[v]][a$grp=="D"])))
}
for (v in vars_bin) {
  lines <- c(lines, sprintf("| %s (%%=1) | %s | %s | %s | %s |", v,
    fmt_p(a[[v]][a$grp=="A"]), fmt_p(a[[v]][a$grp=="B"]),
    fmt_p(a[[v]][a$grp=="C"]), fmt_p(a[[v]][a$grp=="D"])))
}
writeLines(lines, "tables/T1_baseline_by_group.md")

n_film <- sum(d$has_film); n_note <- sum(d$has_note)
n_class <- sum(!is.na(d$cong_hybrid)); n_fb <- nrow(a)
tb <- table(a$cong_hybrid, as.integer(a$fb72_mlkg > 0))
dead <- tapply(a$death30, list(a$cong_hybrid, as.integer(a$fb72_mlkg>0)), mean)
flow <- c("# 流程图数字（STROBE）", "",
  sprintf("- Sepsis-3 ICU 住院（全部）: 32,971"),
  sprintf("- 首次 ICU 住院且 ≥18 岁: %d", nrow(d)),
  sprintf("- 入科 ±24h 内有胸片: %d", n_film),
  sprintf("- 匹配到胸片报告: %d", n_note),
  sprintf("- 影像淤血可分类: %d (%.1f%%)", n_class, 100*n_class/nrow(d)),
  sprintf("- 液体平衡可计算: %d", n_fb),
  "",
  "## 2×2（n, 死亡率）",
  "| | FB ≤ 0 | FB > 0 |", "|---|---|---|",
  sprintf("| 影像淤血 + | %d, %.1f%% | %d, %.1f%% |", tb[2,1], 100*dead[2,1], tb[2,2], 100*dead[2,2]),
  sprintf("| 影像淤血 − | %d, %.1f%% | %d, %.1f%% |", tb[1,1], 100*dead[1,1], tb[1,2], 100*dead[1,2]))
writeLines(flow, "tables/T2_flow_and_2x2.md")
cat("written T1, T2\n")
print(tb); print(round(100*dead, 1))
