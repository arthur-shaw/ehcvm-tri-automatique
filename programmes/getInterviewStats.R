# =============================================================================
#              DESCRIPTION OF PROGRAM
#              ------------------------
#
# DESCRIPTION: Fetches interviews statistics from the server. These include,
#				among others: number of unanswered questions, number of
#				validation errors
#
# AUTHOR:     Arthur Shaw, jshaw@worldbank.org
# =============================================================================

# =============================================================================
# Load all necessary programs
# =============================================================================

# packages needed for this program 
packagesNeeded <- c(
	"httr", 	# for API communication
	"RCurl", 	# for checking whether site exists
	"haven",  	# for loading Stata data
	"dplyr"		# for convenient subsetting and column selection
)								

# identify and install those packages that are not already installed
packagesToInstall <- packagesNeeded[!(packagesNeeded %in% installed.packages()[,"Package"])]
if(length(packagesToInstall)) install.packages(packagesToInstall, quiet = TRUE, repos = 'https://cloud.r-project.org/', dep = TRUE)

# load all needed packages
lapply(packagesNeeded, library, character.only = TRUE)

# =============================================================================
# Program parameters
# =============================================================================

# confirm that server details exist in workspace ; load them if not
if (!exists(serverDetails)) {
	source(paste0(progDir, "serverDetails.R"))
}

# connect program's parameters to those set outside program

# input
# inputDir <- constructedDir
# inputDta <- casesToReviewDta
inputData <- casesToReview

# output
outputDir <- constructedDir
outputDta <-  interviewStatsDta

# error log
logDir 	<- logDir
logFile <- "failed_getInterviewStats"

# target version for exported Stata file
stataVersion	<- 	stataVersion

# =============================================================================
# Check set-up
# =============================================================================

# reinitialize error log, deleting it if it already exists
failedToGetStats <- "failedToGetStats.csv"
if ( file.exists(paste0(logDir, failedToGetStats))) {
	file.remove(paste0(logDir, failedToGetStats))
}

# confirm that expected folders exist 
# if (!dir.exists(inputDir)) {
# 	stop("Data folder does not exist in the expected location: ", inputDir)
# }
if (!dir.exists(outputDir)) {
	stop("Data folder does not exist in the expected location: ", outputDir)
}

# confirm that server exists
serverToCheck <- paste0("https://", server, ".mysurvey.solutions/")
serverCheck <- url.exists(serverToCheck)
if (serverCheck == FALSE) {
	stop("The following server does not exist. Please correct this program's server parameter ", "\n", serverToCheck)
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
loginsToCheck <- paste0("https://", server, ".mysurvey.solutions/api/v1/questionnaires")
loginsOK <- GET(
		loginsToCheck, 
		accept_json(), 
		authenticate(login, password), 
		query = list(limit=40, offset=1))

if (status_code(loginsOK) != 200) {
	stop("The login and/or password provided are incorrect. Please correct in program parameters", "\n", 
		"Login : ", login, "\n", 
		"Password : ", password, "\n"
	)
}

# =============================================================================
# Load input data
# =============================================================================

# read in data produced by Stata program
interviewsToCheck <- casesToReview
	# read_stata(paste0(inputDir, inputDta))
	# , encoding = "UTF-8" may be needed as second argument of read_stata when user has version 14

# filter down to cases to be processed
interviewsToCheck <- interviewsToCheck %>%
	filter(
		(interview__status %in% statusesToReject) &
		(interviewComplete == 1)
		) %>%
	select(interview__id)

# =============================================================================
# Fetch statistics for each interview
# =============================================================================

# count number of interviews whose details are needed
numToProcess <- nrow(interviewsToCheck)

# initialize counter
currentInterview 	<- 1
returnedDetails 	<- list()
failedToGetStats 	<- list()

while (currentInterview <= numToProcess) {

	# extract parameters needed for processing
	interviewId		<- interviewsToCheck$interview__id[currentInterview]

	# print process
	print(paste0("Statistics being sought for interview__id: ", interviewId))

	# make request
	detailsEndpoint <- paste0("https://", server, ".mysurvey.solutions/api/v1/interviews/", interviewId, "/stats")
	getIntDetails <- GET(detailsEndpoint, 
		accept_json(), 
		encode = "json",
		authenticate(login, password))

	# capture and manage and failed responses
	if (status_code(getIntDetails) != 200) {
		
		# record errors
		failedToGetStats[[currentInterview]] = c(
			interview__id = interviewId,
			statusCode = status_code(getIntDetails))
		
		# increment counter
		currentInterview <- currentInterview + 1
		
		next

	}

	# create list of data frames that each contain a segment of the total questionnaire list
	returnedDetails[[currentInterview]] <- content(getIntDetails)
	returnedDetails[[currentInterview]]$interview__id <- interviewId

	# increment current interview counter
	currentInterview <- currentInterview + 1

}

# =============================================================================
# Write to file: interview details, any failed requests
# =============================================================================

# merge together all reponses into a data frame
returnedDetails_all <- do.call(rbind.data.frame, returnedDetails)
returnedDetails_all <- returnedDetails_all

# make interview__id into a string rather than a factor
returnedDetails_all$interview__id <- as.character(returnedDetails_all$interview__id)

# save merged responses in Stata format
write_dta(data = returnedDetails_all, path = paste0(outputDir, outputDta), version = stataVersion)

if (length(failedToGetStats) > 0) {

	# merge lists of failed exports together into a data frame
	failedExports <- do.call(rbind, listFailedExports)

	# write results to disk in a CSV file
	write.csv(failedToGetStats, file = paste0(logDir, logFile), col.names = TRUE, append = FALSE)

}
