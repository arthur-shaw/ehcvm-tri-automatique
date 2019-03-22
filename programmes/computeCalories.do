
/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Compute calories per item consumed as well as total calories.
				This involves several steps: 
				1. Input data sets must be prepared for use (e.g., rename 
				variables, confirm contents, etc.).
				2. Convert reported units into standard grams
				3. Compute calories per food item
				4. Compute total calories
				Note: calories are in per person per day terms.

DEPENDENCIES:	

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

capture program drop computeCalories
program define computeCalories
syntax ,					///
	 /// --- CONVERSION FACTORS ---
	factorsDta(string) 		///
	factorsByGeo(string) 	/// whether factors reported by geo: "true" or "false"
	[geoIDs(string)]		/// list of geo IDs common to factors and household file
	prodID_fctrCurr(string) /// current product ID var in factors file
	prodID_fctrNew(string) 	/// new var name for product ID
	unitIDs_fctrCurr(string) /// current unit ID vars in factors file
	unitIDs_fctrNew(string) ///  new var names for unit ID vars
	factorVar(string) 		/// conversion factor var
	 /// -- CALORIES ---
	caloriesDta(string) 	/// file path for calories per product
	prodID_calCurr(string) 	/// current product ID var in calories file
	prodID_calNew(string) 	/// new var name for product ID
	caloriesVar(string) 	/// calories per 100g in calories
	edibleVar(string) 		/// edible portion variable in caloroes
	 /// --- HOUSEHOLD-LEVEL ---
	hholdDta(string) 		/// file path for household-level file
	memberList(string)		/// stub name for list variable (i.e., varname in Designer)
	 /// --- FOOD CONSUMPTION ---
	consoDta(string) 		/// file path for combined food consumption file
	quantityVar(string) 	/// total quantity consumed var
	 /// --- OUTPUT ---
	outputDir(string) 		/// where to save output files: calories by item, total calories

	/*=============================================================================
	Confirm that objects in parameters exist
	=============================================================================*/

	/*-----------------------------------------------------------------------------
	check files
	-----------------------------------------------------------------------------*/

	* NSU conversion factors
	capture confirm file "`factorsDta'"
	if _rc != 0 {

		di as error "ERROR: Non-standard unit conversion factors file missing, or invalid file path in factorsDta()"
		error 1

	}

	* calorie conversion factors
	capture confirm file "`caloriesDta'"
	if _rc != 0 {

		di as error "ERROR: Calorie conversion factor file missing, or invalid file path in caloriesDta()"
		error 1

	}

	* household-level data
	capture confirm file "`hholdDta'"
	if _rc != 0 {

		di as error "ERROR: household-level data file missing, or invalid file path in hholdDta()"
		error 1

	}

	/*-----------------------------------------------------------------------------
	check folder
	-----------------------------------------------------------------------------*/

	capture cd "`outputDir'"
	if _rc != 0 {

		di as error "ERROR: Output directory in outputDir() does not exist."

	}

	/*=============================================================================
	Prepare data
	=============================================================================*/

	/*-----------------------------------------------------------------------------
	nsu conversion factors
	-----------------------------------------------------------------------------*/

	use "`factorsDta'", clear

	* define variables to check as a function of whether factors are reported by product-unit-geo
	if ("`factorsByGeo'" == "true") {
		local varsToCheck "`geoIDs' `prodID_fctrCurr' `unitIDs_fctrCurr' `factorVar'"
	}
	else if ("`factorsByGeo'" == "false") {
		local varsToCheck "`prodID_fctrCurr' `unitIDs_fctrCurr' `factorVar'"
	}

	* check that required variables are present
	local missingVars ""
	foreach varToCheck of local varsToCheck {

		capture confirm variable `varToCheck'
		if _rc != 0 {

			local missingVars = "`missingVars' `varToCheck'"

		}

		if ("`missingVars'" != "") {

			di as error "ERROR: The converson factors file is missing the following required variables: "
			di as error "`missingVars'"
			error 1

		}

	}	

	* drop duplicates, if any exist
	drop if (`factorVar' == .) 				// remove obs with missing factors values
	duplicates drop `varsToCheck', force 	// so that non-missing factors not removed if there is a duplicate pair with non-missing and missing values

	* retain only necessary variables
	keep `varsToCheck'

	* rename product ID from old name to new name
	rename `prodID_fctrCurr' `prodID_fctrNew'

	* rename unit variables from old names to new names
	rename (`unitIDs_fctrCurr') (`unitIDs_fctrNew')

	* factors at most detailed level (e.g., by strata)
	tempfile factors
	save "`factors'"

	* factors at unit level (e.g., national)
	bysort `prodID_fctrNew' `unitIDs_fctrNew': egen factorForUnit = median(`factorVar')

		collapse (first) factorForUnit, by(`prodID_fctrNew' `unitIDs_fctrNew')	

	tempfile factorsByUnit
	save "`factorsByUnit'"

	/*-----------------------------------------------------------------------------
	calories
	-----------------------------------------------------------------------------*/
	
	use "`caloriesDta'", clear

	* check that required variables are present
	local varsToCheck "`prodID_calCurr' `caloriesVar' `edibleVar'"
	local missingVars ""
	foreach varToCheck of local varsToCheck {

		capture confirm variable `varToCheck'
		if _rc != 0 {

			local missingVars = "`missingVars' `varToCheck'"

		}

		if ("`missingVars'" != "") {

			di as error "ERROR: The calories file is missing the following required variables: "
			di as error "`missingVars'"
			error 1

		}

	}

	* drop duplicates, if any exist
	drop if (`caloriesVar' == . | `edibleVar' == .) // remove obs with missing
	duplicates drop `prodID_calCurr'  				/// so that non-missing not removed if there is a duplicate pair with non-missing and missing values
		`caloriesVar' `edibleVar', force

	* retain only necessary variables
	keep `varsToCheck'

	* rename product variable from curren to new name
	rename `prodID_calCurr' `prodID_calNew'

	tempfile calories
	save "`calories'"

	/*-----------------------------------------------------------------------------
	household-level data
	-----------------------------------------------------------------------------*/
	
	use "`hholdDta'", clear

	* define variables to check as a function of whether factors are reported by product-unit-geo
	if ("`factorsByGeo'" == "true") {
		local varsToCheck "`geoIDs' `memberList'__0"
	}
	else if ("`factorsByGeo'" == "false") {
		local varsToCheck "`memberList'__0"	
	}

	* check that required variables are present
	local missingVars ""
	foreach varToCheck of local varsToCheck {

		capture confirm variable `varToCheck'
		if _rc != 0 {

			local missingVars = "`missingVars' `varToCheck'"

		}

		if ("`missingVars'" != "") {

			di as error "ERROR: The household-level file is missing the following required variables: "
			di as error "`missingVars'"
			error 1

		}

	}

	* compute household size
	qui : d `memberList'*, varlist
	local memberList = r(varlist)

	foreach member of local memberList {

		replace `member' = "" if (`member' == "##N/A##")

	}

	egen hhsize = rownonmiss(`memberList'), strok

	* retain only necessary variables
	if ("`factorsByGeo'" == "true") {
		local varsToKeep "interview__id `geoIDs' hhsize"
	}
	else if ("`factorsByGeo'" == "false") {
		local varsToKeep "interview__id hhsize"
	}
	keep `varsToKeep'

	tempfile hhold
	save "`hhold'"

	/*-----------------------------------------------------------------------------
	food consumption
	-----------------------------------------------------------------------------*/
	
	use "`consoDta'", clear

	* check that required variables are present
	local varsToCheck "`prodID_fctrNew' `unitIDs_fctrNew' `quantityVar'"
	local missingVars ""
	foreach varToCheck of local varsToCheck {

		capture confirm variable `varToCheck'
		if _rc != 0 {

			local missingVars = "`missingVars' `varToCheck'"

		}

		if ("`missingVars'" != "") {

			di as error "ERROR: The combined food consumption file is missing the following required variables: "
			di as error "`missingVars'"
			error 1

		}

	}

	* define variables to merge as a function of whether factors are reported by product-unit-geo
	if ("`factorsByGeo'" == "true") {
		local varsToMerge "`geoIDs' hhsize"
	}
	else if ("`factorsByGeo'" == "false") {
		local varsToMerge "hhsize"
	}

	* merge in household size and, potentially, geo IDs
	merge m:1 interview__id using "`hhold'", 	///
		keepusing(`varsToMerge')				/// include household size
		keep(3) nogenerate						/// only keep households under consideration with consumption

	tempfile consumption
	save "`consumption'"

	/*=============================================================================
	Caculate calories
	=============================================================================*/

	use "`consumption'", clear

	/*-----------------------------------------------------------------------------
	Convert from reported units to grams (g)
	-----------------------------------------------------------------------------*/

	* add conversion factor column
	if ("`factorsByGeo'" == "true") {
		local mergeVars = "`geoIDs' `prodID_fctrNew' `unitIDs_fctrNew'"
	}
	else if ("`factorsByGeo'" == "false") {
		local mergeVars = "`prodID_fctrNew' `unitIDs_fctrNew'"
	}

	merge m:1 `mergeVars' using "`factors'", ///
		keep(1 3) keepusing(`factorVar') nogen

	* compute weight in grams
	
	gen weightInG = .
	
	// using most local factors possible
	replace weightInG = `factorVar' * `quantityVar' if !mi(`factorVar', `quantityVar')

	// using national factors if local factors not available
	qui: count if (`quantityVar' != . & `factorVar' == .)		// count cases where unit-level factors could be useful
	local numMissingFactors = r(N)
	if (`numMissingFactors' > 0) {
		merge m:1 `prodID_fctrNew' `unitIDs_fctrNew' using "`factorsByUnit'", keep(1 3) nogen
		replace weightInG = factorForUnit * `quantityVar' ///
			if (`quantityVar' != . & `factorVar' == .)

	}

	/*-----------------------------------------------------------------------------
	Convert from grams (g) to calories (kcal)
	-----------------------------------------------------------------------------*/

	* add calories and edible portion columns
	merge m:1 `prodID_fctrNew' using "`calories'", keep(1 3) nogen

	* weight of the consumable portion
	gen weightInGConso = weightInG * `edibleVar'

	* number of 100g units, since kcal is reported by 100g units
	gen weightConso100g = weightInGConso/100

	/*-----------------------------------------------------------------------------
	Compute calories by item
	-----------------------------------------------------------------------------*/

	* calories by day
	gen caloriesByItem = (weightConso100g * `caloriesVar')/(7 * hhsize)
	label variable caloriesByItem "Calories per food item"

	* too many calories for a single item
	gen highItemCalories = (caloriesByItem > 1500) & !mi(caloriesByItem)
	label variable highItemCalories "Calories > 1500 for a given item"

	* keep output variables
	keep interview__id interview__key `prodID_fctrNew' `quantityVar' `unitIDs_fctrNew' ///
		caloriesByItem highItemCalories

	qui: save "`outputDir'/caloriesByItem.dta", replace

	* confirm that calories by item file saved successfully
	capture confirm file "`outputDir'/caloriesByItem.dta"
	if _rc != 0 {

		di as error "ERROR: Problem saving caloriesByItem.dta in `outputDir'"
		error 1

	}

	/*-----------------------------------------------------------------------------
	Compute total calories
	-----------------------------------------------------------------------------*/

	* total calories
	collapse (sum) totCalories = caloriesByItem , by(interview__id interview__key)
	replace totCalories = . if mi(totCalories)

	* too high
	gen caloriesTooHigh = (totCalories > 4000) & !mi(totCalories)
	label variable caloriesTooHigh "Calories > 4000 per day per person"

	* too low
	gen caloriesTooLow = (totCalories <= 800) & !mi(totCalories)
	label variable caloriesTooLow "Calories < 800 per day per person"

	save "`outputDir'/totCalories.dta", replace

	* confirm that calories by item file saved successfully
	capture confirm file "`outputDir'/caloriesByItem.dta"
	if _rc != 0 {

		di as error "ERROR: Problem saving caloriesByItem.dta in `outputDir'"
		error 1

	}

end
