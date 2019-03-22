
rm(list = ls())
projDir       <-  "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/programmes/"

# get microdata
dataDir               <-      "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/donnees/download/"
pattern       <-      "Questionnaire UEMOA - SN"
dataType      <-      "STATA"

# convert from tab to Stata
mainDataDir <- "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/donnees/download/"

# get interview details
inputDir      <-      "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/donnees/temp/"
inputData     <-      "entretiensAValider.dta"
outputDir     <-      "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/donnees/temp/"
outputData <- "interviewDetails.dta"
stataVer <- 13

# reject
rejectDir     <- "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/donnees/temp/"
rejectList    <- "entretiens_aRejetter.dta"
