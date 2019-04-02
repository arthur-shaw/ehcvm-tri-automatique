/*=============================================================================
Project settings
=============================================================================*/

local projDir ""

include "`projDir'/programmes/configurePrograms.do"

/*=============================================================================
Load all necessary Stata programs
=============================================================================*/

#delim ;
local programsNeeded "
unzipAll.do
appendAll.do
combineConsumption.do
computeCalories.do
";
#delim cr

local progLoc = "`projDir'/programmes/"

foreach programNeeded of local programsNeeded {

	* check whether program exists
	capture confirm file "`progLoc'/`programNeeded'"
	
	* if not, issue show an error and stop execution
	if _rc != 0 {
		di as error "Program missing"
		di as error "Expected program: `programNeeded'"
		di as error "Expected location: `progLoc'"
		error 1
	}

	* if so, load the program definition
	else if _rc == 0 {
		include "`progLoc'/`programNeeded'"
	}

}

/*=============================================================================
Delete files from previous runs
=============================================================================*/

local repertoires "downloadDir rawDir constructedDir"

foreach repertoire of local repertoires {

	! rmdir "``repertoire''/" /s /q
	! mkdir "``repertoire''/"

}

/*=============================================================================
Download data
=============================================================================*/

* download data with R
if ("`howCallR'" == "rcall") {
	rcall sync : rm(list = ls()) 								// delete prior R session info
	rcall sync : source(paste0("`progDir'", "filePaths.R")) 	// pass parameters and file paths to R
	rcall sync : source(paste0("`progDir'", "downloadData.R")) 	// download data
}
else if ("`howCallR'" == "shell") {
	cd "`progDir'"
	shell "`rPath'" CMD BATCH filePaths.R
	shell "`rPath'" CMD BATCH downloadData.R
}

* confirm that files actually downloaded
local zipList : dir "`downloadDir'" files "*.zip" , nofail respectcase
local zipList : list clean zipList
if ("`zipList'" == "") {
	di as error "No data files downloaded from the server. Please try again."
	di as error "If this error persists, check the following: "
	di as error "1. Internet connection. "
	di as error "2. Server details--that is, the server, login, and password provided in configurePrograms.do"
	di as error "3. Server health. Navigate to the server, log in, and attempt to download a data file manually."
	di as error "4. Failure"
	error 1
}

/*=============================================================================
Combine data
=============================================================================*/

/*-----------------------------------------------------------------------------
Unzip
-----------------------------------------------------------------------------*/

* unzip files downloaded from the server
unzipAll, folder("`downloadDir'")

* confirm that zip files unzipped
local dirList : dir "`downloadDir'" dirs "*" , nofail respectcase
local dirList : list clean dirList
if ("`dirList'" == "") {
	di as error "Failure to create destination folder for zipped files"
	error 1
}

* confirm that folder contains .dta files
local firstDir : word 1 of `dirList'
local firstDir = "`downloadDir'" + "`firstDir'/"
local dtaList : dir "`firstDir'" files "*.dta" , nofail respectcase
local dtaList : list clean dtaList
if ("`dtaList'" == "") {
	di as error "Folders created by unzipping do not contain any .dta files"
	error 1
}

/*-----------------------------------------------------------------------------
Append
-----------------------------------------------------------------------------*/

* append together same-named files from different template versions
appendAll, 							///
	inputDir("`downloadDir'") 		///	où chercher les données téléchargées
	outputDir("`rawDir'")			/// où sauvegarder la concatination

* confirm that necessary files have appended version
#delim ;
local necessaryFiles = "
hhold
members
parcels
plots
livestock
enterprises
equipAgric
safetyNets
";
#delim cr

local missingFiles ""

* look for missing non-consumption files
foreach necessaryFile of local necessaryFilesF {
	
	capture confirm file "`rawDir'/`necessaryFile'"
	if _rc != 0 {
		local missingFiles "`missingFiles' `necessaryFile'"
	}

}

* look for missing food consumption files
foreach consoRoster of local consoRosterList {

	capture confirm file "`rawDir'/`consoRoster'.dta"
	if _rc != 0 {
		local missingFiles "`missingFiles' `consoRoster'.dta"
	}

}

* error if any of the above files are missing
if ("`missingFiles'" != "") {
	di as error "The following necessary fles are missing"
	di as error "Expected location : `rawDir'"
	di as error "Expected files : `missingFiles'"
	error 1
}

/*-----------------------------------------------------------------------------
Combine consumption
-----------------------------------------------------------------------------*/

combineConsumption , 					/// 
	rosterDtaList("`consoRosterList'") 	/// list of food consumption files
	varList("`consoVarList'") 			/// list of variables in consumption files
	inputDir("`rawDir'") 				/// where input files can be found
	outputDir("`constructedDir'") 		/// where output file should be saved
	outputDta("`combinedFood'") 		/// name of the output file
	outputID("productID") 				/// name of product ID variable in file

/*=============================================================================
Process data
=============================================================================*/

/*-----------------------------------------------------------------------------
Identify cases to be reviewed for rejection/approval
-----------------------------------------------------------------------------*/

include "`progDir'/identifyCasesToReview.do"

/*-----------------------------------------------------------------------------
Compute calories
-----------------------------------------------------------------------------*/

computeCalories ,							///
	 /// --- CONVERSION FACTORS ---
	factorsDta("`resourceDir'/`factorsDta'") /// file path for conversion factors
	factorsByGeo(`factorsByGeo')			/// whether factors are broken down by geo
	geoIDs(`geoIDs') 						/// list of geo IDs
	prodID_fctrCurr(`prodID_fctrCurr') 		/// current product ID var in factors file
	prodID_fctrNew(`prodID_fctrNew') 		/// new var name for product ID
	unitIDs_fctrCurr(`unitIDs_fctrCurr') 	/// current unit ID vars in factors file
	unitIDs_fctrNew(`unitIDs_fctrNew') 		/// new var name for unit ID vars
	factorVar(`factorVar') 					/// conversion factor var
	 /// -- CALORIES ---
	caloriesDta("`resourceDir'/`caloriesDta'") /// file path for calories per product
	prodID_calCurr(`prodID_calCurr') 		/// current product ID var in calories file
	prodID_calNew(`prodID_calNew') 			/// new var name for product ID
	caloriesVar(`caloriesVar') 				/// calories per 100g in calories
	edibleVar(`edibleVar') 					/// edible portion variable in calories
	 /// --- HOUSEHOLD-LEVEL ---
	hholdDta("`rawDir'/`hhold'") 			/// file path for household-level file
	memberList(`memberList')				/// stub name for list variable (i.e., varname in Designer)
	 /// --- FOOD CONSUMPTION ---
	consoDta("`constructedDir'/`combinedFood'") /// file path for combined food consumption file
	quantityVar(`quantityVar') 				/// total quantity consumed var
	 /// --- OUTPUT ---
	outputDir("`constructedDir'") 			/// where to save output files: calories by item, total calories

/*-----------------------------------------------------------------------------
Compile interview attributes
-----------------------------------------------------------------------------*/

include "`progDir'/compileAttributes.do"

/*-----------------------------------------------------------------------------
Compile interview issues
-----------------------------------------------------------------------------*/

include "`progDir'/compileIssues.do"

/*=============================================================================
Decide how to process interviews
=============================================================================*/

/*-----------------------------------------------------------------------------
Run R programs to:

- Check interviews for comments
- Get interview statistics
- Decide what actions to take for each interview
- Make rejection messages
- Post comments
- Reject interviews
-----------------------------------------------------------------------------*/

if ("`howCallR'" == "rcall") {
	rcall sync : source(paste0("`progDir'", "filePaths.R"), echo = TRUE)
	rcall sync : source(paste0("`progDir'", "processInterviews.R"), echo=TRUE)
}
else if ("`howCallR'" == "shell") {
	cd "`progDir'"
	shell "`rPath'" CMD BATCH filePaths.R
	shell "`rPath'" CMD BATCH processInterviews.R
}

