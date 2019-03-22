* load main data
use "`rawDir'/`hhold'", clear

* creat flag for when cases should be considered complete
gen interviewComplete = (`completedInterview' )

keep 								///
	interview__id interview__key	/// case identifiers
	interview__status 				/// SuSo statuts
	interviewComplete 				/// user-defined "complete"

save "`constructedDir'/casesToReview.dta", replace
