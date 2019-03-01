rm(list = ls())
gc()

library(tidyverse)
library(dbplyr)
library(odbc)
library(edwHelpers)

setwd(rstudioapi::getActiveProject())

source("src/config.R")
source("src/helper-funs.R")

sdb <- dbConnect(odbc(), config$dns, Database = config$db[1], UID = config$uid, PWD = rstudioapi::askForPassword())
ai <- dbConnect(odbc(), config$dns, Database = config$db[2], UID = config$uid, PWD = rstudioapi::askForPassword())


# Fetch -------------------------------------------------------------------

# note - I use an rstudio snippet:
# snippet get.table
  # tbl(${1:con}, in_schema("sec", "${2:table}")) %>% ${3}

# There are actually some annoyances around this that I'm not going to deal with right now
# # get last yrq from system (reduce magic numbers)
# s <- Sys.Date()
# end.yrq <- tbl(sdb, in_schema("sec", "sys_tbl_39_calendar")) %>%
#   filter(between(s, first_day, last_day_exams)) %>%
#   collect()


# non-transfer students who enrolled between fall 2000 and spring 2012
# get id's and first yrq
yrq1 <- tbl(ai, in_schema("sec", "IV_UndergraduateGraduationRetention")) %>%
  filter(AcademicCareerEntryQtrKeyId >= 20004,
         AcademicCareerEntryQtrKeyId <= 20122,
         AcademicCareerLevel == "UG",
         EntryTransferStudentFlag == 0,
         EntrySeattleStudentInd == "Y") %>%
  select(system_key = SDBSrcSystemKey,
         first.yrq = AcademicCareerEntryQtrKeyId,
         cohort.yrq = StudentCohortQtrKeyId,
         degree.yrq = DegreeGrantedQtrKeyId,
         grad = GraduatedFlag,
         starts_with("Retained"),
         starts_with("GraduatedByYear"),
         time.to.degree.terms = TimeToDegreeInTerms,
         time.to.degree.mo = TimeToDegreeInMonths) %>%
  collect()

# use those system_keys as a filter for the other files
dbRmTemp(sdb, "##temp_keys")
vals <- data.frame(system_key = yrq1$system_key)
dbWriteTable(sdb, name = '##temp_keys', value = vals, row.names = FALSE)
vals <- tbl(sdb, "##temp_keys")

tran.courses <- tbl(sdb, in_schema("sec", "transcript_courses_taken")) %>%
  mutate(tran.yrq = tran_yr*10 + tran_qtr) %>%
  filter(tran.yrq >= 20004,
         tran.yrq <= 20122,
         tran_qtr != 3,
         deductible == 0,
         !(grade %in% c("S", "NS", "CR", "NC", "W", "HW")),
         grade_system == 0) %>%
  select(system_key, tran.yrq, index1, dept_abbrev, course_number, section_id, course_credits,
         course_branch, grade_system, college, grade, deductible, honor_course, incomplete, repeat_course) %>%
  inner_join(vals, by = "system_key") %>%
  collect()

tran.quarterly <- tbl(sdb, in_schema("sec", "transcript")) %>%
  mutate(tran.yrq = tran_yr*10 + tran_qtr,
         # qtr.gr.pts = pmax(qtr_grade_points, over_qtr_grade_pt),
         # qtr.gr.attmp = pmax(qtr_graded_attmp, over_qtr_grade_at),
         # qtr.nongrd = pmax(qtr_nongrd_earned, over_qtr_nongrd),
         # qtr.deduct = pmax(qtr_deductible, over_qtr_deduct),
         fulltime = if_else(tenth_day_credits >= 12, 1, 0)) %>%
  filter(tran.yrq >= 20004,
         tran.yrq <= 20122,
         tran.yrq != 3) %>%
  select(system_key, tran.yrq, resident, veteran, class, honors_program, num_courses, tenth_day_credits,
         enroll_status, add_to_cum, fulltime, starts_with('qtr_'), starts_with('over_qtr')) %>%
  inner_join(vals, by = "system_key") %>%
  collect()
#
# # more mutations:
# tran.quarterly <- tran.quarterly %>%
#   mutate(qtr.gr.pts = pmax(qtr_grade_points, over_qtr_grade_pt),
#          qtr.gr.attmp = pmax(qtr_graded_attmp, over_qtr_grade_at),
#          qtr.nongrd = pmax(qtr_nongrd_earned, over_qtr_nongrd),
#          qtr.deduct = pmax(qtr_deductible, over_qtr_deduct)) %>%

