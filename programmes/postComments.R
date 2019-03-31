# =============================================================================
#              DESCRIPTION OF PROGRAM
#              ------------------------
#
# DESCRIPTION: Post comments to questions. Comments come from issues that
#				should result in a comment. The variable, location, and 
#				text of the content come from the issues created by
#
# AUTHORS:     Arthur Shaw, jshaw@worldbank.org
# =============================================================================

# =============================================================================
# Load necessary libraries
# =============================================================================

# packages needed for this program 
packagesNeeded <- c(
	"httr", 	# for API communication
	"dplyr"		# for convenient data wrangling
)								

# identify and install those packages that are not already installed
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]
if(length(packagesToInstall)) install.packages(packagesToInstall, quiet = TRUE, repos = 'https://cloud.r-project.org/', dep = TRUE)

# load all needed packages
lapply(packagesNeeded, library, character.only = TRUE)

# =============================================================================
# Confirm inputs exist
# =============================================================================

# issues
if (!exists("issues")) {
	stop("List of interview issues not found.")
}

# confirm that server details exist in workspace ; load them if not
if (!exists("serverDetails")) {
	source(paste0(progDir, "serverDetails.R"))
}

# =============================================================================
# Connect program's parameters to those set outside program
# =============================================================================

# error log
logDir 	<- logDir
logFile <- "failed_postComments.csv"

# =============================================================================
# Check whether there are comments to post
# =============================================================================

# filter issues to comments for posting
commentsToPost <- 
	casesToReview %>%
	left_join(issues, by = c("interview__id", "interview__key")) %>%
	filter(issueType == 2)

# terminate program if there are no comments to post
if (nrow(commentsToPost) >= 1) {

	# confirm that server details exist in workspace ; load them if not
	if (!exists(serverDetails)) {
		source(paste0(progDir, "serverDetails.R"))
	}

	# TODO: Figure out how best to end program: code above or code commented bleow
	# # compute number of rows
	# numComments <- nrow(commentsToPost)

	# # exit R session if no observations
	# if (numComments ==  0) {
	# 	quit()
	# }

# =============================================================================
# Post comments
# =============================================================================

	listfailedComments <- list()

	# post comments going row by row
	for (i in 1:nrow(commentsToPost)) {

		# extract paramaters from ith row
		interviewID 	<- commentsToPost$interview__id[i]
		interviewKey 	<- commentsToPost$interview__key[i]
		varName 		<- commentsToPost$issueVars[i]
		rowCode 		<- commentsToPost$issueLoc[i]
		comment 		<- commentsToPost$issueComment[i]

		# construct comment endpoint address
		if (serverType == "cloud") {
			baseAddress <- paste0("https://", server, ".mysurvey.solutions")
		} else if (serverType == "local") {
			baseAddress <- serverType
		}
		commentAPI <- paste0(
			baseAddress, 							# domain
			"/api/v1/interviews/", interviewID, 	# interview
			"/comment-by-variable/", varName, 		# variable
			"?comment=", curlPercentEncode(comment) # comment
			)


		# post comment
		postComment <- httr::POST(
			url = commentAPI, 
			authenticate(user = login, password = password),
			accept_json(),
			content_type_json(),
			body = paste0("[", rowCode, "]")
			)

		# react to server response
		# if issue successfully posted, move to next issue
		if (status_code(postComment) == 200) {
			next
		# if issue failed for some reason, capture details about failure
		} else {

			# write error to log
			serverMsg <- content(postComment)$Message
			listfailedComments[[i]] = c(
				as.character(interviewKey),
				serverMsg,
				varName,
				rowCode,
				comment)

			# print error to screen
			print(paste0("Problem with interview: ", interviewID))
			print(serverMsg)

		}	

	}

# =============================================================================
# If comments failed to post, record failed attempts to a log file
# =============================================================================

	# create a csv file containing failed rejections and reason for failure
	if (length(listfailedComments) > 0 ) {

		# merge lists of failed exports together into a data frame
		failedComments <- do.call(rbind, listfailedComments)

		# give data frame columns names
		colnames(failedComments) <- c(
			"Interview key", 
			"Why comment failed",
			"Variable",
			"Row code",
			"Comment to post"
			) 
		
		# write results to disk in a CSV file
		write.csv(failedComments, file = paste0(logDir, logFile), col.names = TRUE, row.names = FALSE, append = FALSE)

	}

}
