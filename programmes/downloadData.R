# =============================================================================
#              DESCRIPTION OF PROGRAM
#              ------------------------
#
# DESCRIPTION: Download data for all questionnaires whose title matches the
#              a user-provided pattern
#              - Loads server details and API user authentication
#              - Loads functions for needed for the download process
#              - Downloads data with dl_similar.R
#
# AUTHORS:     Arthur Shaw, jshaw@worldbank.org (downloadData.R)
#              Lena Nguyen, Arthur Shaw (https://github.com/l2nguyen/SuSoAPI)   
# =============================================================================

# check that progDir exists
if (!exists("progDir")) {
	stop("The folder progDir doesn't exist in R")
}

# set working directory to programs folder
setwd(paste0(progDir, "/downloadData/"))

# load function definitions for downloading
source(paste0(progDir,"serverDetails.R"))
source(paste0(progDir, "/downloadData/get_qx.R"))
source(paste0(progDir, "/downloadData/get_qx_id.R"))
source(paste0(progDir, "/downloadData/get_details.R"))
source(paste0(progDir, "/downloadData/dl_one.R"))
source(paste0(progDir, "/downloadData/dl_allvers.R"))
source(paste0(progDir, "/downloadData/dl_similar.R"))

# override pattern defition for Guinée-Bissau ; Portuguese accents don't match in str_detect
pattern = "QUESTIONÁRIO AO AGREGADO FAMILIAR"

# run function to download data for templates whose names matches `pattern`
dl_similar(
   pattern = pattern, 	
   exclude = NULL, 		
   ignore.case = FALSE,  
   export_type = export_type, 
   folder = downloadDir,   
   unzip = FALSE,
   server = server,
   user = login,  		
   password = password, 
   tries = 100)
