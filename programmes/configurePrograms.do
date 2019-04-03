/*=============================================================================
CONFIGURATION PARAMETERS
=============================================================================*/

set more 1

/*-----------------------------------------------------------------------------
How to call R
-----------------------------------------------------------------------------*/

local howCallR 	""	// values: rcall, shell
local rPath 	"" // values: blank or path to R.exe

/*-----------------------------------------------------------------------------
Server details
-----------------------------------------------------------------------------*/

local server 		= 	"" 	// server prefix (e.g., "demo" for "demo.mysurvey.solutions")
local login			= 	"" 	// login for API user or admin
local password		= 	"" 	// password for user whose login is provided above
local nomMasque 	=	"" 	// questionnaire title--that is, title, not questionnaire variable
local exportType 	=	"STATA" 	//
local serverType 	= 	"cloud" 	// values: "cloud", "local"

/*-----------------------------------------------------------------------------
Identify interviews to process
-----------------------------------------------------------------------------*/

* by Survey Solutions status
local statusesToReject "100, 120"	// enter as a comma-separated list of numeric codes

	// possible values listed here: 
	// 100	Completed
	// 120	ApprovedBySupervisor
	// read here for more: // https://support.mysurvey.solutions/headquarters/export/system-generated---export-file-anatomy/#coding_status

* by expression that indicated a "complete" interview
# delim ;
local completedInterview "

 	inlist(s00q08, 1, 2)

 	& 

 	(visite1 == 1 & visite2 == 2 & visite3 == 3)

";
#delim cr

/*-----------------------------------------------------------------------------
Construct file paths
-----------------------------------------------------------------------------*/

* construct paths relative to projet root
local downloadDir 		"`projDir'/donnees/telechargees/"
local rawDir 			"`projDir'/donnees/fusionnees/"
local constructedDir 	"`projDir'/donnees/derivees/"
local resourceDir 		"`projDir'/donnees/ressources/"
local progDir 			"`projDir'/programmes/"
local resultsDir 		"`projDir'/resultats/"
local logDir 			"`projDir'/logs/"

* make paths R-friendly
local filePaths "downloadDir rawDir constructedDir resourceDir progDir resultsDir logDir"

foreach filePath of local filePaths {

	* replace backslashes with slashes
	local `filePath' = subinstr("``filePath''", "\", "/", .)
	
	* ensure path has a terminal slash
	capture assert substr("``filePath''", -1, 1) == "/"
	if _rc != 0 {
		local `filePath' = "``filePath''" + "/"
	}

} 

* ensure R.exe file path has slashes instead of backslashes
local rPath = subinstr("`rPath'", "\", "/", .)

/*-----------------------------------------------------------------------------
Calorie computation data and variables
-----------------------------------------------------------------------------*/

* conversion factors (country-specific)
local factorsDta 		"" 					// name of conversion factors file
local factorsByGeo		"" 				// whether factors reported by geo: "true" or "false"
local geoIDs 			""		// geographic ID variables common to conversion factors and hhold data
local prodID_fctrCurr 	"produitID" 		// current product ID
local prodID_fctrNew 	"productID" 		// new productID
local unitIDs_fctrCurr 	"" 	// current unit IDs in factors file
local unitIDs_fctrNew 	"s07Bq03b s07Bq03c" // new unit IDs in factors file
local factorVar 		"" // variable name for conversion factor

* calories (project-specific)
local caloriesDta 		"calories.dta"
local prodID_calCurr 	"produitID"
local prodID_calNew 	"productID"
local caloriesVar		"kiloCalories"		// variable name for calories per 100g
local edibleVar			"refuseDeflator" 	// variable names for % edible

* hhold (project-specific)
local memberList 		"NOM_PRENOMS" 		// variable name of list of hhold members

* food consumption (project-specific)
local consoDta 			"foodConsumption.dta" // name of the combined food consumption data set
local quantityVar 		"s07Bq03a" 			// total quantity in combined food data set

* output (project-specific)
local outputDir 		"`constructedDir'" 	// folder where calories files should be saved

/*-----------------------------------------------------------------------------
Raw data
-----------------------------------------------------------------------------*/

local hhold 			"menage.dta" 
local members 			"membres.dta"
local parcels 			"champs.dta"
local plots 			"parcelles.dta" 	
local livestock 		"elevage.dta"
local enterprises 		"enterprises.dta"
local equipAgric 		"equipements.dta" 	
local safetyNets 		"filets_securite.dta" 	

/*-----------------------------------------------------------------------------
Generated data
-----------------------------------------------------------------------------*/

local attributes 		"attributes.dta"
local issues			"issues.dta"
local combinedFood 		"foodConsumption.dta"
local caloriesTot 		"totCalories.dta"
local caloriesByItem 	"caloriesByItem.dta"

/*-----------------------------------------------------------------------------
Construct full paths for select files
-----------------------------------------------------------------------------*/

local attributesPath 	"`constructedDir'/`attributes'"
local issuesPath 		"`constructedDir'/`issues'"

/*-----------------------------------------------------------------------------
Consumption data and variables
-----------------------------------------------------------------------------*/

#delim ;

* data files names ;
local consoRosterList "
cereales
viandes
poissons
huiles
laitier
fruits
legumes
legtub
sucreries
epices
boissons
";

* variable names ;
local consoVarList "
s07Bq03a
s07Bq03b
s07Bq03c
s07Bq04
s07Bq05
s07Bq06
s07Bq07a
s07Bq07b
s07Bq07c
s07Bq08
";
#delim cr

/*=============================================================================
PASS PARAMETERS TO R
=============================================================================*/

/*-----------------------------------------------------------------------------
Server details
-----------------------------------------------------------------------------*/

file open  serverDetails using "`progDir'/serverDetails.R", write replace
file write serverDetails `"server 	<- "`server'""' 	_n
file write serverDetails `"login 	<- "`login'""' 		_n
file write serverDetails `"password <- "`password'""' 	_n
file write serverDetails `"serverType 	<- "`serverType'""' _n
file close serverDetails

/*-----------------------------------------------------------------------------
Location of files and folders
-----------------------------------------------------------------------------*/

* capture Stata version ; fix ceiling at 14 for R's purposes (because of haven)
local stataVersion = c(version)
local stataVersion = int(`stataVersion') 
if (`stataVersion' >= 14) {
	local stataVersion "14"
}

file open filePaths using "`progDir'/filePaths.R", write replace
file write filePaths "# folders" 										_n
file write filePaths `"downloadDir 		<- "`downloadDir'""'			_n
file write filePaths `"rawDir 			<- "`rawDir'""'					_n
file write filePaths `"constructedDir 	<- "`constructedDir'""'			_n
file write filePaths `"progDir 			<- "`progDir'""' 				_n
file write filePaths `"logDir 			<- "`logDir'""' 				_n
file write filePaths `"resultsDir 		<- "`resultsDir'""'				_n
file write filePaths "" 												_n
file write filePaths "# files" 											_n
file write filePaths `"commentsDta 		<- "interview__comments.dta""' 	_n
file write filePaths `"issuesDta 		<- "issues.dta""' 				_n
file write filePaths `"casesToReviewDta <- "casesToReview.dta""' 		_n
file write filePaths `"interviewStatsDta <- "interviewStats.dta""' 		_n
file write filePaths "" 												_n
file write filePaths `"# parameters"' 									_n
file write filePaths `"serverDetails 	<- "serverDetails.R""' 			_n
file write filePaths `"stataVersion 	<- `stataVersion'"'				_n
file write filePaths `"statusesToReject <- c(`statusesToReject')"' 		_n
file write filePaths `"pattern 			<- "`nomMasque'""' 				_n
file write filePaths `"export_type 		<- 	"`exportType'""' 			_n
file close filePaths
