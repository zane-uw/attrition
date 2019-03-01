
# Helper functions --------------------------------------------------------

# TODO add these to my EDWHelpers package or elsewhere as appropriate

# Keeping naming convention of dbDoStuff rather than my preferred do.stuff() b/c this is primarily
# a wrapper for using dbExistsTable to clean up temp tables along the way
# this is sorta necessary b/c dbExistsTable and dbRemoveTable (and dbWriteTable) understand schemas differently
# and dbExistsTable needs help to see that a temp table exists in tempdb rather than the current working db
dbRmTemp <- function(connection, target.temp.table){
  if (dbExistsTable(connection, DBI::SQL(target.temp.table))) dbRemoveTable(connection, target.temp.table) else
    print("Table doesn't exist (yet)")
}

# convert text grades to compatible numbers
grade.2.num <- function(grades){
  recode(grades,
         "A"  = "40",
         "A-" = "38",
         "B+" = "34",
         "B"  = "31",
         "B-" = "28",
         "C+" = "24",
         "C"  = "21",
         "C-" = "18",
         "D+" = "14",
         "D"  = "11",
         "D-" = "08",
         "E"  = "00")
}
