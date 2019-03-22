# =============================================================================
# 					DESCRIPTION OF PROGRAM
# 					------------------------
#
# DESCRIPTION:	Determines whether interview cases being reviewed have comments
# 				on questions relavant to the approve/reject decision
#
# AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
# =============================================================================

# =============================================================================
# Load necessary libraries
# =============================================================================

# packages needed for this program 
packagesNeeded <- c(
	"dplyr",	# to do basic data wrangling
	"haven", 	# to injest input Stata file, write output Stata files
	"stringr", 	# to identify @@Complete, @@Reject, events
	"fuzzyjoin" # to check whether comments posted for variables in issues
)

# identify and install those packages that are not already installed
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]
if(length(packagesToInstall)) 
	install.packages(packagesToInstall, quiet = TRUE, 
		repos = 'https://cloud.r-project.org/', dep = TRUE)

# load all needed packages
lapply(packagesNeeded, library, character.only = TRUE)

# =============================================================================
# Injest data sets
# =============================================================================

# interview comments
commentsPath <- paste0(rawDir, commentsDta)
if (file.exists(commentsPath)) {
	comments <- read_stata(paste0(rawDir, commentsDta), encoding = "UTF-8") 
} else {
	stop(paste0("Comments file cannot be found at expected location: ", commentsPath))
}

# interview issues
issuesPath <- paste0(constructedDir, issuesDta)
if (file.exists(issuesPath)) {
	issues <- read_stata(paste0(issuesPath), encoding = "UTF-8")
} else {
	stop(paste0("Issues file cannot be found at expected location: ", issuesPath))
}

# =============================================================================
# Identify comments relevant for rejection decision
# =============================================================================

# -----------------------------------------------------------------------------
# Comments on issue variables
# -----------------------------------------------------------------------------

# create set of unique issue variables (regex patterns)
uniqueIssueVars <- issues %>% distinct(issueVars)

# filter to interviews with any comments at all
commentsForCasesToReview <- comments %>%
	semi_join(casesToReview, by = "interview__id")

# filter to comments left by the interviewer that are the last in their comment string
lastCommentIsFromInt <- commentsForCasesToReview %>% 
	filter(!str_detect(string = variable, pattern = "^@@")) %>% 	# remove Complete/Reject/Approve comments
	group_by(interview__id, variable, id1, id2, id3) %>% 			# group by interview-variable-row
	filter(row_number() == n()) %>% 								# keep last comment within group
	filter(role == "Interviewer") %>% 								# retain only Interviewer comments
	ungroup()

# filter to comments concerning variables used in identifying issues
commentsOnIssueVars <- lastCommentIsFromInt  %>%
	regex_semi_join(uniqueIssueVars, by = c("variable" = "issueVars")) %>%
	select(interview__id)

# -----------------------------------------------------------------------------
# Comments on interview overall
# -----------------------------------------------------------------------------

# filter to overall comments
commentsOverall <- commentsForCasesToReview %>%
	filter(variable == "@@Completed") %>%
	group_by(interview__id) %>%
	filter(row_number() == n()) %>%
	ungroup()  %>%
	select(interview__id)

# =============================================================================
# Identify interviews with and without comments on issue variables
# =============================================================================

# interviews with comments
interview_hasComments <- casesToReview %>%
	semi_join(
		union(commentsOnIssueVars, commentsOverall) %>%
		distinct(interview__id),
	by = "interview__id")
