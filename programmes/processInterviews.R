# -----------------------------------------------------------------------------
# Load necessary packages
# -----------------------------------------------------------------------------

# packages needed for this program 
packagesNeeded <- c(
	"haven", 	# to injest Stata data
	"dplyr" 	# to perform basic data wrangling
)

# identify and install those packages that are not already installed
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]
if(length(packagesToInstall)) install.packages(packagesToInstall, quiet = TRUE, repos = 'https://cloud.r-project.org/', dep = TRUE)

# load all needed packages
lapply(packagesNeeded, library, character.only = TRUE)

# -----------------------------------------------------------------------------
# Confirm that there are interview that can be processed
# -----------------------------------------------------------------------------

# read cases to review into memory
casesToReviewPath <- paste0(constructedDir, casesToReviewDta)

# filter down to those that are "rejectable"
casesToReview <- read_stata(casesToReviewPath) %>%

# !!!!!! FOR TESTING ONLY; REMOVE AFTERWARD !!!!!
		mutate(interview__status = if_else(row_number()%%2 == 0, 100, 120)) %>%
		head(100) %>%
# !!!!!! FOR TESTING ONLY; REMOVE AFTERWARD !!!!!

		select(interview__id, interview__key, 	# interview identifiers
			interview__status, 					# interview status
			interviewComplete 					# user-defined flag for "complete" interviews
			) %>%
		filter(
			(interview__status %in% statusesToReject) &
			(interviewComplete == 1))

# contine only if there is 1 or more
if (nrow(casesToReview) >=1) {

# -----------------------------------------------------------------------------
# Check interviews for comments
# -----------------------------------------------------------------------------

source(paste0(progDir, "checkForComments.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Get interview statistics
# -----------------------------------------------------------------------------

source(paste0(progDir, "getInterviewStats.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Decide what actions to take for each interview
# -----------------------------------------------------------------------------

source(paste0(progDir, "decideAction.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Make rejection messages
# -----------------------------------------------------------------------------

source(paste0(progDir, "makeRejectMsgs.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Post comments
# -----------------------------------------------------------------------------

source(paste0(progDir, "postComments.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Reject interviews
# -----------------------------------------------------------------------------

source(paste0(progDir, "rejectInterviews.R"))

} else if (nrow(casesToReview) == 0) {
	print("Currently no interviews to process that can be rejected")
} 
