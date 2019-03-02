rm(list = ls())
gc()

library(tidyverse)

load("data/raw/transcripts-and-first-yrq_raw.RData")

#
# # more mutations:
# tran.quarterly <- tran.quarterly %>%
#   mutate(qtr.gr.pts = pmax(qtr_grade_points, over_qtr_grade_pt),
#          qtr.gr.attmp = pmax(qtr_graded_attmp, over_qtr_grade_at),
#          qtr.nongrd = pmax(qtr_nongrd_earned, over_qtr_nongrd),
#          qtr.deduct = pmax(qtr_deductible, over_qtr_deduct)) %>%