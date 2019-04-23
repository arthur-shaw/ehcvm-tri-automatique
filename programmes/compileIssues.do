
/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Create "issues" for each interview. Issues are of three types:
				those that warrant rejection, those that are comments (to be
				posted to rejected interviews), and those that are SuSo
				validation errors. Issues are used in the reject/review/approve
				decision.

DEPENDENCIES:	createSimpleIssue.do, createComplexIssue.do

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

/*=============================================================================
LOAD DATA FRAME AND HELPER FUNCTIONS
=============================================================================*/

/*-----------------------------------------------------------------------------
Initialise issues data frame
-----------------------------------------------------------------------------*/

clear
capture erase "`issuesPath'"
gen interview__id = ""
gen interview__key = ""
gen issueType = .
label define types 1 "Critical error" 2 "Comment" 3 "SuSo validation error" 4 "Needs review"
label values issueType types
gen issueDesc = ""
gen issueComment = ""
gen issueLoc = ""
gen issueVars = ""
save "`issuesPath'", replace


/*-----------------------------------------------------------------------------
Load helper functions
-----------------------------------------------------------------------------*/

include "`progDir'/helper/createSimpleIssue.do"

include "`progDir'/helper/createComplexIssue.do"

/*=============================================================================
CREATE ISSUES
=============================================================================*/

/*-----------------------------------------------------------------------------
MEMBERS
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
DEMOGRAPHICS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* more than 1 head
createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numChefs) ///
	issueCondit(numChefs > 1) ///
	issueType(1) ///
	issueDesc("Plus d'un chef") ///
	issueComm("ERREUR: Ménage avec plus d'un chef.")

* no head
createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numChefs) ///
	issueCondit(numChefs == 0) ///	
	issueType(1) ///
	issueDesc("Aucun chef") ///
	issueComm("ERREUR: Ménage sans chef. Tout ménage doit avoir un chef")

/*-----------------------------------------------------------------------------
CONSUMPTION
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* no food consumption
createComplexIssue , 	///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(numProdAlim repasHorsMenage_men repasHorsMenage_indiv) ///
	issueCondit(numProdAlim == 0 & repasHorsMenage_men == 0 & repasHorsMenage_indiv == 0) ///	
	issueType(1) ///
	issueDesc("Aucune consommation alimentaire") ///
	issueComm("ERREUR: Aucune consommation alimentaire déclarée, que ce soit au domicile (7B) ou hors domicile (7A)")

* calories too high, with non-members sharing hhold's meals
local tropCaloriesRepasPartCom = ///
"ERREUR: La consommation alimentaire déclarée est trop élevée (7B), et " +	///
"le ménage a partagé quelques repas avec des personnes non-membres du ménage (8B). " + ///
"D'abord, confirmer que la consommation dans 7B n'inclut pas celle du personnes " + ///
"non-membre du ménage. Ensuite, vérifier les quantités et unités déclarées pour " + ///
"chaque produit dans 7B. Puis, confirmer que les déclarations concernent " + ///
"la consommation et non pas l'acquisition."

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTropElevees repasPartages) ///
	issueCondit(caloriesTropElevees == 1 & repasPartages == 1) ///
	issueType(1) ///
	issueDesc("Calories trop élevées, repas partagés") ///
	issueComm("`tropCaloriesRepasPartCom'")

* calories too high overall, with no non-members sharing hhold's meals
local tropCaloriesCom = ///
"ERREUR: La consommation alimentaire déclarée est trop élevée. " +	///
"D'abord, vérifier les quantités et les unités déclarées " + ///
"pour chaque produit dans 7B2. " + ///
"Ensuite, confirmer que les déclarations concernent la consommation " + ///
"et non pas l'acquisition."

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTropElevees repasPartages) ///
	issueCondit(caloriesTropElevees == 1 & repasPartages == 0) ///
	issueType(1) ///
	issueDesc("Calories trop élevées, aucun repas partagé") ///
	issueComm("`tropCaloriesCom'")

* calories too low overall
local peuCaloriesCom = ///
"ERREUR: La consommation alimentaire déclarée est trop faible. "	+	///
"D'abord, confirmer que tous les produits consommés ont été renseignés. " + ///
"Ensuite, vérifier que les quantités et unités de consommation sont correctes"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTropFaibles repasHorsMenage_men repasHorsMenage_indiv) ///
	issueCondit(caloriesTropFaibles == 1 & (repasHorsMenage_men == 0 & repasHorsMenage_indiv == 0)) ///
	issueType(1) ///
	issueDesc("Calories trop faibles") ///
	issueComm("`peuCaloriesCom'")

* calories too low, but did eat outside of the home
local peuCalMaisRepas = ///
"ERREUR: La consommation alimentaire déclarée est trop faible, mais " + ///
"il y a une consommation en dehors du ménage. D'abord, confirmer que " + ///
"tous les produits consommés ont été renseignés. Ensuite, vérifier que " + /// 
"les quantités et  unités de consommation sont correctes. Enfin, voir " + ///
"la consommation en dehors du ménage."

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesTropFaibles repasHorsMenage_men repasHorsMenage_indiv) ///
	issueCondit(caloriesTropFaibles == 1 & (repasHorsMenage_men == 1 | repasHorsMenage_indiv == 1)) ///
	issueType(4) ///
	issueDesc("Calories faibles, mais repas externes") ///
	issueComm("`peuCalMaisRepas'")

* calories too high for one item
local caloriesItemComm = ///
"ERREUR. Trop de calories tirées d'un seul produit. D'abord, chercher le " + ///
"produit avec la plus grande quantité ou la plus grande unité de " + ///
"consommation. " + ///
"Ensuite, confirmer la consommation de celui-ci."

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(caloriesItemElevees) ///
	issueCondit(caloriesItemElevees == 1) ///
	issueType(1) ///
	issueDesc("Calories trop élevées pour un item") ///
	issueComm("`caloriesItemComm'")

* items for which calories are too high

// range of product IDs by food group
local cereales "1, 22"
local viandes "23, 34"
local poissons "35, 43"
local laitier "44, 52"
local huiles "53, 59"
local fruits "60, 71"
local legumes "72, 91"
local legtub "92, 113"
local sucreries "114, 117"
local epices "118, 128"
local boissons "129, 138"

// names of food groups
#delim ;
local produits = "
cereales
viandes
poissons
laitier
huiles
fruits
legumes
legtub
sucreries
epices
boissons";
#delim cr

use "`constructedDir'/`caloriesByItem'", clear

// create a comment for each food item with too many calories per item
foreach produit of local produits {

	createSimpleIssue using "`issuesPath'", ///
		flagWhere(highItemCalories == 1 & inrange(productID, ``produit'')) ///
		issueType(2) ///
		issueDesc("Calories trop élevées pour un item") ///
		issueComm("Calories trop élevées pour cet item") ///
		issueLocIDs(productID) ///
		issueVar(s07Bq03a_`produit')

}

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
NON-FOOD CONSUMPTION
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* no non-food consumption
#delim ;
local nonFoodVars "
numProdNonAlim_fetes
numProdNonAlim_7j
numProdNonAlim_30j
numProdNonAlim_3m
numProdNonAlim_6m
numProdNonAlim_12m
";

local nonFoodCondit "
numProdNonAlim_fetes== 0	&
numProdNonAlim_7j 	== 0	&
numProdNonAlim_30j 	== 0	&
numProdNonAlim_3m 	== 0	&
numProdNonAlim_6m 	== 0	&
numProdNonAlim_12m 	== 0
";
#delim cr

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(`nonFoodVars') ///
	issueCondit(`nonFoodCondit') ///
	issueType(1) ///
	issueDesc("Aucune consommation non-alimentaire") ///
	issueComm("ERREUR: Aucune consommation non-alimentaire déclarée (9A à 9F)")

/*-----------------------------------------------------------------------------
INCOME
-----------------------------------------------------------------------------*/

* no income
#delim ;
local incomeVars "
revenuEmploi
revenuHorsEmploi
pratiqueAgriculture
pratiqueElevage
pratiquePeche
numEntreprises
recuTransferts
recuBenefices
locationEquipement
";

local incomeCondit "
revenuEmploi 		== 0 &
revenuHorsEmploi 	== 0 &
pratiqueAgriculture == 0 &
pratiqueElevage 	== 0 &
pratiquePeche 		== 0 &
numEntreprises 		== 0 &
recuTransferts 		== 0 &
recuBenefices 		== 0 &
locationEquipement 	== 0
";
#delim cr

local incomeComm = 															///
"ERREUR: Aucune source de revenu déclarée pour le ménage: " + 				///
"aucun revenu d'emploi (4A à 4C), aucun revenu hors emploi (5), " + 		///
"aucun transfert reçu (13A), aucun revenu d'une activité rémunerative" + 	///
"(10, 16, 17, 18) aucun bénéfice des filets de sécurité (15), " + 			///
"aucun revenu de location (19).)"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(`incomeVars') ///
	issueCondit(`incomeCondit') ///
	issueType(1) ///
	issueDesc("Aucun revenu") ///
	issueComm("`incomeComm'")


/*-----------------------------------------------------------------------------
CRITICAL INCONSISTENCIES
-----------------------------------------------------------------------------*/

* travaille dans une entrepise, sans en déclarer une
local entrepriseComm = ///
"ERREUR: Un membre du ménage ou plus exerce une activité non-agricole " + 	///
"à son propre compte (4B, 4C), mais aucune entreprise n'est déclarée"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(travailEntNonAgric numEntreprises) ///
	issueCondit(travailEntNonAgric == 1 & numEntreprises == 0) ///
	issueType(1) ///
	issueDesc("Travaille en entrepise, sans en déclarer une") ///
	issueComm("`entrepriseComm'")

* travaille dans l'agriculture, sans déclarer une activité agricole
local agricComm = 															///
"ERREUR: Un membre du ménage ou plus exerce une activité agricole " + 		///
"à son propre compte (4B, 4C), mais le ménage déclare ne pas "		+		///
"pratiquer l'agriculture (16A)"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(travailAgric pratiqueAgriculture) ///
	issueCondit(travailAgric == 1 & pratiqueAgriculture == 0) ///
	issueType(1) ///
	issueDesc("Travaille en agriculture, sans déclarer une activité agricole") ///
	issueComm("`agricComm'")

* travaille dans l'élevage, sans déclarer une activité d'élevage
local elevageComm = 														///
"ERREUR: Un membre du ménage ou plus exerce une activité dans l'élevage " +	///
"à son propre compte (4B, 4C), mais le ménage déclare ne pas " +			///
"pratiquer l'élevage (17)"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(travailElevage pratiqueElevage) ///
	issueType(1) ///
	issueCondit(travailElevage == 1 & pratiqueElevage == 0) ///
	issueDesc("Travaille dans l'élevage, sans déclarer une activité d'élevage") ///
	issueComm("`elevageComm'")

* travaille dans la pêche, sans déclarer une activité piscicole
local pecheComm = 															///
"ERREUR: Un membre du ménage ou plus exerce une activité dans la pêche " + 	///
"à son propre compte (4B, 4C), mais le ménage déclare ne pas " +			///
"pratiquer la pêche (18)"

createComplexIssue , ///
	attributesFile(`attributesPath') ///
	issuesFile(`issuesPath') ///
	whichAttributes(travailPeche pratiquePeche) ///
	issueType(1) ///
	issueCondit(travailPeche == 1 & pratiquePeche == 0) ///
	issueDesc("Travaille dans la pêche, sans déclarer une activité piscicole") ///
	issueComm("`pecheComm'")

