# =============================================================================
# 					DESCRIPTION OF PROGRAM
# 					------------------------
#
# DESCRIPTION:	Decides action for each interview: reject, review, or approve
# 				- To reject interviews have: 1 or more major issue but no 
#				(potentially) explanatory comments on variables that are inputs 
#				into the issues
#				- To review interview have: 1 or more issues but with some
#				(potentially) explanatory comments on issue variables; or 
#				any comments on any variables or the interview itself; or
#				any SuSo validation errors
#				- To approve interviews have: no issues, no comments
# AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
# =============================================================================

# =============================================================================
# Load necessary libraries
# =============================================================================

# packages needed for this program 
packagesNeeded <- c(
	"dplyr",	# for convenient data wrangling
	"haven"  	# for loading Stata data
)								

# identify and install those packages that are not already installed
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]
if(length(packagesToInstall)) install.packages(packagesToInstall, quiet = TRUE, repos = 'https://cloud.r-project.org/', dep = TRUE)

# load all needed packages
lapply(packagesNeeded, library, character.only = TRUE)

# =============================================================================
# Confirm inputs exist
# =============================================================================

# inteview statistics
interviewStatsPath <- paste0(constructedDir, interviewStatsDta)
if (!file.exists(interviewStatsPath)) {
	stop("Interview stats file cannot be found")
}

# interview issues
if (!exists("issues")) {
	stop("Interview issues not loaded. If needed, read the file from storage.")
}

if (!exists("casesToReview")) {
	stop("Cases to review not loaded. If needed, read the file from storage.")
}

if (!exists("interview_hasComments")) {
	stop("Interviews with comments cannot be loaded. If needed, re-run checkForComments.R")
}

# =============================================================================
# Determine whether has rejectable attribute
# =============================================================================

# has at least 1 major issue
interview_hasIssues <- 
	issues %>% filter(issueType == 1) %>%
	distinct(interview__id, interview__key) %>%
	inner_join(casesToReview, by = c("interview__id", "interview__key"))

# has at least N question(s) unanswered
interviewStats <- 
	read_stata(paste0(constructedDir, interviewStatsDta), encoding = "UTF-8")

interview_hasUnanswered <-
	interviewStats %>%
	filter(NotAnswered > 1) %>%	# TODO: Make this a parameter
	select(interview__id)

# =============================================================================
# Reject
# =============================================================================

# identify interviews to reject
toReject <- 

	casesToReview %>%

	# has at least 1 major issue, but no comments
	semi_join(
		setdiff(					
			interview_hasIssues, 	
			interview_hasComments),
		by = "interview__id") %>%

	# or has at least N unanswered questions
	full_join(interview_hasUnanswered, by = "interview__id") %>%

	distinct(interview__id) %>%
	left_join(casesToReview, by = "interview__id") %>%
	select(interview__id, interview__status)

# write list to disk as a Stata file
write_dta(data = toReject, path = paste0(resultsDir, "toReject.dta"), version = stataVersion)

# create an issue for each interview with unanswered questions
issues_hasUnanswered <- 
	interviewStats %>%
	filter(NotAnswered > 1) %>%	# TODO: Make this a parameter
	mutate(
		issueType = 1, 
		issueDesc = "Question(s) laissées sans réponse",
		issueComment = paste0("ERREUR: ", NotAnswered, " questions ont été laissées sans réponse")
		) %>%
	left_join(casesToReview, by = "interview__id") %>%
	select(interview__id, interview__key, issueType, issueDesc, issueComment)

# add these issues has issues data base
issues <- full_join(issues, issues_hasUnanswered, by = c("interview__id", "interview__key", "issueType", "issueDesc", "issueComment"))
	# bind_rows(issues, issues_hasUnanswered)

# =============================================================================
# Review
# =============================================================================

# identify interviews to review
toReview <- 

	casesToReview %>%
	
	# has both 1+ major issue and 1+ comments on an issue var
	semi_join(
		intersect(
			interview_hasIssues, 
			interview_hasComments),
		by = "interview__id") %>%

	# or has at least 1 comment or validation error
	full_join(
		interviewStats %>% 
			filter(Invalid >= 1 | WithComments >= 1), 
		by = "interview__id") %>%

	# and not on reject list
	anti_join(toReject, by = "interview__id") %>%

	distinct(interview__id) %>%
	left_join(interviewStats, by = "interview__id") %>%
	mutate(numInvalid = Invalid, numComments = WithComments) %>%
	select(interview__id, numComments, numInvalid) %>%
	left_join(casesToReview, by = "interview__id") %>%  
	select(interview__id, interview__key, interview__status, numComments, numInvalid)
	
# create an issue for each interview with unanswered questions
# issues_hasUnanswered <- 
# 	interviewStats %>%
# 	filter(NotAnswered > 1) %>%	# TODO: Make this a parameter
# 	mutate(
# 		issueType = 1, 
# 		issueDesc = "Question(s) laissées sans réponse",
# 		issueComment = paste0("ERREUR: ", NotAnswered, " questions ont été laissées sans réponse")
# 		) %>%
# 	select(interview__id, issueType, issueDesc, issueComment) %>%
# 	left_join(casesToReview, by = "interview__id") %>%  
# 	select(interview__id, interview__key, issueType, issueDesc, issueComment)	

# create an issue for each validation error
errors <- read_stata(paste0(rawDir, "interview__errors.dta"), encoding = "UTF-8")
issues_hasInvalid <-
	interviewStats %>%
	filter(Invalid > 0) %>%
	left_join(errors, by = "interview__id") %>%
	mutate(
		issueType = 3,
		issueDesc = "Erreur de validation", 
		issueComment = message,
		issueVars = variable
		) %>%
	left_join(casesToReview, by = c("interview__id", "interview__key")) %>%  
	select(interview__id, interview__key, issueType, issueDesc, issueComment, issueVars)	

# add these issues has issues data base
issues <- full_join(issues, issues_hasInvalid, by = c("interview__id", "interview__key", "issueType", "issueDesc", "issueComment", "issueVars"))
	# bind_rows(issues, issues_hasUnanswered, issues_hasInvalid)

# write list to disk as a Stata file
write_dta(data = toReview, path = paste0(resultsDir, "toReview.dta"), version = stataVersion)

# !!! FOR TESTING - DELETE AFTERWARDS
# write_dta(data = issues, path = paste0(constructedDir, "issues_expanded.dta"), version = stataVersion)
# !!! FOR TESTING - DELETE AFTERWARDS

# =============================================================================
# Approve
# =============================================================================

# identify interviews to approve
toApprove <- 

	casesToReview %>%

	# has no comments, no unanswered questions, and no validation errors
	inner_join(interviewStats, by = "interview__id") %>%
	filter(WithComments == 0 & NotAnswered == 0 & Invalid == 0) %>%
	
	# has no issues
	anti_join(interview_hasIssues, by = "interview__id") %>%

	select(interview__id) %>%
	left_join(casesToReview, by = "interview__id") %>%
	select(interview__id, interview__status)

# write list to disk as a Stata file
# write_dta(data = toApprove, path = paste0(resultsDir, "toApprove.dta"), version = stataVersion)

# =============================================================================
# Confirm outputs created
# =============================================================================

# to reject
if (!exists("toReject")) {
	stop("List of interviews to reject was not created.")
}

# to review
if (!exists("toReview")) {
	stop("List of interviews to review was not created.")
}

# to approve
if (!exists("toApprove")) {
	stop("List of interviews to approve was not created.")
}
