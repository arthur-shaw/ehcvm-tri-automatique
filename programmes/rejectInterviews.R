
# =============================================================================
# Program parameters
# =============================================================================

# location and name of input data
# rejectDir		<- 	""
# rejectList 	<- 	"toReject.dta"

# set project and data directories
# projDir 		<- "C:/Users/Arthur/Desktop/UEMOA/rejet automatique/"
# setwd(projDir)

# packages needed for this program 
packagesNeeded <- c(
	"httr", 	# to communicate with API
	"RCurl", 	# to check that server exists
	"haven", 	# to injest Stata data
	"dplyr" 	# to perform basic data wrangling
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
if (!exists("toReject")) {
	stop("List of interview to reject not found.")
}

# confirm that server details exist in workspace ; load them if not
# if (!exists(serverDetails)) {
# 	source(paste0(progDir, "serverDetails.R"))
# }

# =============================================================================
# Connect program's parameters to those set outside program
# =============================================================================

rejectDir 	<- resultsDir
rejectList 	<- "toReject.dta"

# error log
logDir 	<- logDir
logFile <- "failed_rejectInterviews.csv"
logPath <- paste0(logDir, logFile)

# =============================================================================
# Check set-up
# =============================================================================

# reinitialize error log
if ( file.exists(logPath) ) {
	file.remove(logPath)
}

# confirm that expected folders exist 
if (!dir.exists(rejectDir)) {
	stop("Data folder does not exist in the expected location: ", rejectDir)
}

# confirm that input data exists in expected location
if (!file.exists(paste0(rejectDir, rejectList))) {
	stop("Data set with list of interviews to reject does not exist in expected location: ", paste0(rejectDir, rejectList))
}

# confirm that server exists
if (serverType == "cloud") {
	serverToCheck <- paste0("https://", server, ".mysurvey.solutions/")
} else if (serverType == "local") {
	serverToCheck <- server
}
serverCheck <- url.exists(serverToCheck)
if (serverCheck == FALSE) {
	stop("The following server does not exist. Please correct this program's server parameter", "\n", serverToCheck)
}

# check that server, login, and password are non-missing
if (nchar(server) == 0) {
	stop("The following parameter is not specified in the program: server")
}
if (nchar(login) == 0) {
	stop("The following parameter is not specified in the program: login")
}
if (nchar(password) == 0) {
	stop("The following parameter is not specified in the program: password")
}

# check that logins are valid for server
if (serverType == "cloud") {
	loginsToCheck <- paste0("https://", server, ".mysurvey.solutions/api/v1/questionnaires")
} else if (serverType == "local") {
	loginsToCheck <- paste0(server, "/api/v1/questionnaires")
}
loginsOK <- GET(
		loginsToCheck, 
		accept_json(), 
		authenticate(login, password), 
		query = list(limit=40, offset=1)
	)
if (status_code(loginsOK) != 200) {
	stop("The login and/or password provided are incorrect. Please correct in program parameters", "\n", 
		"Login : ", login, "\n", 
		"Password : ", password, "\n"
	)
}

# =============================================================================
# Read file into
# =============================================================================

# read in data produced by Stata program
interviewsToReject <- read_stata(paste0(rejectDir, "/", rejectList))
	# , encoding = "UTF-8" may be needed as second argument of read_stata when user has version 14

# confirm that input data frame contains all expected columns
expectedColumns <- c("interview__id", "interview__status", "rejectMessage")
if (!all(expectedColumns %in% colnames(interviewsToReject))) {
	stop(paste0("Interviews to reject should should the following columns: ", 
		paste(expectedColumns, collapse = ", ")))
}

# filter down to cases that can be rejected
interviewsToReject <- filter(interviewsToReject, interview__status %in% statusesToReject)

# =============================================================================
# Reject interviews, posting comments on errors
# =============================================================================

# count number of interviews to reject
numToProcess <- nrow(interviewsToReject)

# continue only if there is at least 1 interview to reject
if (numToProcess >= 1) {

	print(paste0("Starting process to reject ", numToProcess, "interviews"))

	# initialize counter
	currentInterview 	<- 1
	listFailedRejections <- list()

	while (currentInterview <= numToProcess) {

		print(paste0("Counter value at beginning of loop : ", currentInterview))

		# extract parameters needed for rejection
		interviewId		<- interviewsToReject$interview__id[currentInterview]
		currStatus 		<- interviewsToReject$interview__status[currentInterview]
		errorMsg 		<- interviewsToReject$rejectMessage[currentInterview]

		# print process
		print(paste0("Interview being rejected: ", interviewId))
		print(paste0("Status : ", currStatus))
		print(paste0("Reason(s) for rejection : ", errorMsg))

		# if interview with the supervisor, use supervisor rejection
		if (currStatus == 100) { # Completed
			if (serverType == "cloud") {
				rejectEndpoint <- paste0("https://", server, ".mysurvey.solutions/api/v1/interviews/", interviewId, "/reject","?comment=", curlPercentEncode(errorMsg))
			} else if (serverType == "local") {
				rejectEndpoint <- paste0(server, "/api/v1/interviews/", interviewId, "/reject","?comment=", curlPercentEncode(errorMsg))
			}
			rejectInterview <- PATCH(rejectEndpoint, 
				accept_json(), 
				encode = "json",
				authenticate(login, password))

		# if interview with HQ, use HQ rejection
		} else if (currStatus == 120) { # ApprovedBySupervisor
			if (serverType == "cloud") {
				rejectEndpoint <- paste0("https://", server, ".mysurvey.solutions/api/v1/interviews/", interviewId,"/hqreject","?comment=", curlPercentEncode(errorMsg))
			} else if (serverType == "local") {
				rejectEndpoint <- paste0(server, "/api/v1/interviews/", interviewId,"/hqreject","?comment=", curlPercentEncode(errorMsg))
			}
			rejectInterview <- PATCH(rejectEndpoint, 
				accept_json(), 
				encode = "json",				
				authenticate(login, password))
		}

		# capture errors if server returns a non-200 code	
		httpStatuts <- status_code(rejectInterview)
		print(paste0("HTTP return code of rejection request : ", httpStatuts))
		if (status_code(rejectInterview) != 200) {

			# write error to log
			serverMsg <- content(rejectInterview)$Message
			listFailedRejections [[currentInterview]] = c(
				as.character(interviewId),
				serverMsg)

			# print error to screen
			print(paste0("Problem with interview: ", interviewId))
			print(serverMsg)

		}

		# increment counter to progress to next interview to reject
		currentInterview <- currentInterview + 1
		print(paste0("Counter value at end of loop : ", currentInterview))
		print("")

	}

	print("End of reject requests to the server")

} else if (numToProcess == 0) {
	print("No interviews to reject")
}

# create a csv file containing failed rejections and reason for failure
if (length(listFailedRejections) > 0 ) {

	# merge lists of failed exports together into a data frame
	failedRejections <- do.call(rbind, listFailedRejections)

	# give data frame columns names
	colnames(failedRejections) <- c("Interview ID", "Why rejection failed") 
	
	# write results to disk in a CSV file
	print("Saving failed rejections to local storage")
	write.csv(failedRejections, file = logPath, col.names = TRUE, row.names = FALSE, append = FALSE)

}
print("End of rejectInterviews.R")
