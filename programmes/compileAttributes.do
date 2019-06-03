/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Compile "attributes" for each interview. These "attributes"
				are indicators or counts that are used in either reports
				or the reject/review/approve decision--or both.

DEPENDENCIES:	createAttribute.do

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

/*=============================================================================
LOAD DATA FRAME AND HELPER FUNCTIONS
=============================================================================*/

/*-----------------------------------------------------------------------------
Initialise attributes data set
-----------------------------------------------------------------------------*/

clear
capture erase "`attributesPath'"
gen interview__id = ""
gen interview__key = ""
gen attribName = ""
gen attribVal = .
gen attribVars = ""
order interview__id interview__key attribName attribVal attribVars
save "`attributesPath'", replace

/*-----------------------------------------------------------------------------
Load helper functions
-----------------------------------------------------------------------------*/

include "`progDir'/helper/createAttribute.do"

/*=============================================================================
IDENTIFY CASES TO REVIEW
=============================================================================*/

use "`constructedDir'/casesToReview.dta", clear
tempfile casesToReview
save "`casesToReview'"

/*=============================================================================
CREATE ATTRIBUTES
=============================================================================*/

/*-----------------------------------------------------------------------------
MENAGE
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:1 interview__id interview__key using "`rawDir'/`hhold'", nogen

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
STATUT
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* statut de l'entretien
createAttribute using "`attributesPath'", ///
	extractAttrib(interview__status) ///
	attribName(interviewStatus) ///

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
7A, 7B : CONSOMMATION ALIMENTAIRE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* en dehors du ménage, consommation par le ménage en entier (section 7A)
createAttribute using "`attributesPath'", ///
	anyVars(s07Aq01b s07Aq04b s07Aq07b s07Aq10b s07Aq13b s07Aq16b s07Aq19b) ///
	varVals(1 2 3) ///
	attribName(repasHorsMenage_men) ///
	attribVars(s07Aq01b|s07Aq04b|s07Aq07b|s07Aq10b|s07Aq13b|s07Aq16b|s07Aq19b)

* au sein du ménage (section 7B)

// dicter comment identifier les variables à compter
// s'il y a des variables "autre" au niveau ménage, employer cet algorithme

capture confirm variable s07Bq02_autre_cereales
if (_rc == 0) {

	qui : d s07Bq02_*, varlist
	local yesNoVars = r(varlist)
	qui : d s07Bq02_autre_*, varlist
	local otherVars = r(varlist)
	local yesNoVars : list yesNoVars - otherVars

} 

// sinon, employer celui-ci

else if (_rc != 0) {

	qui : d s07Bq02_*, varlist
	local yesNoVars = r(varlist)

}

createAttribute using "`attributesPath'", ///
	countVars(`yesNoVars') 			///
	varVals(1) 					///
	attribName(numProdAlim) ///
	attribVars(^s07Bq02_)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
9A à 9F : CONSOMMATION NON-ALIMENTAIRE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* fêtes
createAttribute using "`attributesPath'", ///
	countVars(s09Aq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_fetes) ///
	attribVars(^s09Aq02)

* 7 jours
createAttribute using "`attributesPath'", ///
	countVars(s09Bq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_7j) ///
	attribVars(^s09Bq02)

* 30 jours
createAttribute using "`attributesPath'", ///
	countVars(s09Cq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_30j) ///
	attribVars(^s09Cq02)

* 3 mois
createAttribute using "`attributesPath'", ///
	countVars(s09Dq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_3m) ///
	attribVars(^s09Dq02)

* 6 mois
createAttribute using "`attributesPath'", ///
	countVars(s09Eq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_6m) ///
	attribVars(^s09Eq02)

* 12 mois
createAttribute using "`attributesPath'", ///
	countVars(s09Fq02*) 		///
	varVals(1) 					///
	attribName(numProdNonAlim_12m) ///
	attribVars(^s09Fq02)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
10: ENTREPRISES NON-AGRICOLES
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* nombre d'entreprises
createAttribute using "`attributesPath'", ///
	countList(s10q12a) 			///
	listMiss("##N/A##") 		///
	attribName(numEntreprises) 	///
	attribVars(s10q12a)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
11 : LOGEMENT
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* entreprise localisée au domicile
createAttribute using "`attributesPath'", ///
	genAttrib(s11q18 == 1) 				///
	attribName(entrepriseAuDomicile) 	///
	attribVars(s11q18)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
13A : TRANSFERTS REÇUS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* si un transfert reçu
createAttribute using "`attributesPath'", ///
	anyVars(s13Aq01 s13Aq02 s13Aq03) 		///
	varVals(1) 					///
	attribName(recuTransferts) 	///
	attribVars(s13Aq01|s13Aq02|s13Aq03)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
15 : FILETS DE SECURITE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* si un bénéfice reçu d'un filet de sécurité
createAttribute using "`attributesPath'", ///
	countVars(s15q02*) 			///
	varVals(1) 					///
	attribName(recuBenefices) 	///
	attribVars(^s15q02)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
16A : AGRICULTURE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* pratique l'agriculture
createAttribute using "`attributesPath'", 	///
	genAttrib(s16Aq00 == 1) 			///
	attribName(pratiqueAgriculture) 	///
	attribVars(s16Aq00)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
17 : ELEVAGE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* pratique l'élevage
createAttribute using "`attributesPath'", ///
	genAttrib(s17q00 == 1) ///
	attribName(pratiqueElevage) ///
	attribVars(s17q00)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
18 : PECHE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* pratique la pêche
createAttribute using "`attributesPath'", ///
	genAttrib(s18q01 == 1) ///
	attribName(pratiquePeche) ///
	attribVars(s18q01)

/*-----------------------------------------------------------------------------
MEMBRES
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`members'", nogen

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
1A : CARACTERISTIQUES DEMOGRAPHIQUES
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* nombre de chef de ménage
createAttribute using "`attributesPath'", ///
	countWhere(s01q02 == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(numChefs) ///
	attribVars(s01q02)

* taille du ménage
local memberID = subinstr("`members'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`memberID')) ///
	byGroup(interview__id interview__key) ///
	attribName(numMembres) ///
	attribVars(^NOM_PRENOMS)

* nombre de membres sous l'âge de 5
createAttribute using "`attributesPath'", ///
	countWhere(AgeAnnee < 5) ///
	byGroup(interview__id interview__key) ///
	attribName(numMemSous5) ///
	attribVars(s01q03[abc]|s01q04a)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
4A à 4B : EMPLOI
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* chercher dans l'emploi primiare et secondaire des indications d'une
* entreprise non-agricole, ou des activités agricoles, d'élevage, ou de pêche

local typeEmployeur		"3, 4"				// type d'employeur
local categSocioProf	"8, 9, 10"			// catégorie socio-professionnelle
local activiteAg 		"1, 23"				// branche d'activité
local activiteElevage	"31, 36" 			// activité d'élevage
local activitePeche		"51, 53" 			// activité de pêche
local activitePublique	"751, 752" 			// activité de fonction publique

// ag
gen travailAgric = (						/// -- EMPLOI PRINCIPAL -- 
(inrange(s04q30d, `activiteAg') &			/// branche d'activité
inlist(s04q31, `typeEmployeur') & 			/// type d'employeur
inlist(s04q39, `categSocioProf'))			/// catégorie socio-professionnelle
|											/// -- EMPLOI SECONDAIRE --
(inrange(s04q52d, `activiteAg') &			/// branche d'activité
inlist(s04q53, `typeEmployeur') & 			/// type d'employeur
inlist(s04q57, `categSocioProf'))			/// catégorie socio-professionnelle
)

// elevage
gen travailElevage = (						/// -- EMPLOI PRINCIPAL -- 
(inrange(s04q30d, `activiteElevage') &		/// branche d'activité
inlist(s04q31, `typeEmployeur') & 			/// type d'employeur
inlist(s04q39, `categSocioProf'))			/// catégorie socio-professionnelle
|											/// -- EMPLOI SECONDAIRE --
(inrange(s04q52d, `activiteElevage') &		/// branche d'activité
inlist(s04q53, `typeEmployeur') & 			/// type d'employeur
inlist(s04q57, `categSocioProf'))			/// catégorie socio-professionnelle
)

// peche
gen travailPeche = (						/// -- EMPLOI PRINCIPAL -- 
(inrange(s04q30d, `activitePeche') &		/// branche d'activité
inlist(s04q31, `typeEmployeur') & 			/// type d'employeur
inlist(s04q39, `categSocioProf'))			/// catégorie socio-professionnelle
|											/// -- EMPLOI SECONDAIRE --
(inrange(s04q52d, `activitePeche') &		/// branche d'activité
inlist(s04q53, `typeEmployeur') & 			/// type d'employeur
inlist(s04q57, `categSocioProf'))			/// catégorie socio-professionnelle
)

// non-ag
gen travailEntNonAgric = (					/// -- EMPLOI PRINCIPAL -- 
((!(inrange(s04q30d, `activiteAg') | 		/// branche d'activité
	inrange(s04q30d, `activiteElevage') | 	///
	inrange(s04q30d, `activitePeche') |		///
	inrange(s04q30d, `activitePublique'))	///
	) &										///
inlist(s04q31, `typeEmployeur') & 			/// type d'employeur
inlist(s04q39, `categSocioProf'))			/// catégorie socio-professionnelle
|											///
											/// -- EMPLOI SECONDAIRE --
((!(inrange(s04q52d, `activiteAg') | 		/// branche d'activité
	inrange(s04q52d, `activiteElevage') | 	///
	inrange(s04q52d, `activitePeche') |		///
	inrange(s04q52d, `activitePublique'))	///
	) &										///
inlist(s04q53, `typeEmployeur') &			/// type d'employeur
inlist(s04q57, `categSocioProf'))			/// catégorie socio-professionnelle
)

* revenu de l'emploi
createAttribute using "`attributesPath'", ///
	anyWhere((s04q43 > 0 & !mi(s04q43)) | (s04q58 > 0 & !mi(s04q58))) ///
	byGroup(interview__id interview__key) ///
	attribName(revenuEmploi) ///
	attribVars(s04q43|s04q58)

* travaille dans une entreprise non-agricole familiale
createAttribute using "`attributesPath'", ///
	anyWhere(travailEntNonAgric == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(travailEntNonAgric) ///
	attribVars(s04q30d|s04q31|s04q39|s04q52d|s04q53|s04q57)

* travaille dans l'agriculture familiale
createAttribute using "`attributesPath'", ///
	anyWhere(travailAgric == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(travailAgric) ///
	attribVars(s04q30d|s04q31|s04q39|s04q52d|s04q53|s04q57)

* travaille dans l'élevage familial
createAttribute using "`attributesPath'", ///
	anyWhere(travailElevage == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(travailElevage) ///
	attribVars(s04q30d|s04q31|s04q39|s04q52d|s04q53|s04q57)

* travaille dans la pêche familiale
createAttribute using "`attributesPath'", ///
	anyWhere(travailPeche == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(travailPeche) ///
	attribVars(s04q30d|s04q31|s04q39|s04q52d|s04q53|s04q57)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
5 : REVENU HORS EMPLOI
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

* revenu hors emploi
egen revenuHorsEmploi = anymatch(s05q01 s05q03 s05q05 s05q07 s05q09 s05q11 s05q13), values(1)
createAttribute using "`attributesPath'", ///
	anyWhere(revenuHorsEmploi == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(revenuHorsEmploi) ///
	attribVars(s05q01|s05q03|s05q05|s05q07|s05q09|s05q11|s05q13)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
7A : REPAS HORS MENAGE
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

egen repasHorsMenage_indiv = anymatch(s07Aq01 s07Aq04 s07Aq07 s07Aq10 s07Aq13 s07Aq16 s07Aq19), values(1 2 3)
createAttribute using "`attributesPath'", ///
	anyWhere(repasHorsMenage_indiv == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(repasHorsMenage_indiv) ///
	attribVars(s07Aq01|s07Aq04|s07Aq07|s07Aq10|s07Aq13|s07Aq16|s07Aq19)

/*-----------------------------------------------------------------------------
8B: REPAS AVEC DES PERSONNES NON MEMBRES DU MÉNAGE
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/repas_non_membre.dta", nogen

createAttribute using "`attributesPath'", ///
	anyWhere(s08Bq06 > 0 & !mi(s08Bq06)) ///
	byGroup(interview__id interview__key) ///
	attribName(repasPartages) ///
	attribVars(s08Bq06|s08Bq06)

/*-----------------------------------------------------------------------------
16A: CHAMPS
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`parcels'", nogen

local parcelID = subinstr("`parcels'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`parcelID')) ///
	byGroup(interview__id interview__key) ///
	attribName(numChamps) ///
	attribVars(^s16A01a)

/*-----------------------------------------------------------------------------
16A: PARCELLES
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`plots'", nogen

local plotID = subinstr("`plots'", ".dta", "__id", .)
createAttribute using "`attributesPath'", ///
	countWhere(!mi(`plotID')) ///
	byGroup(interview__id interview__key) ///
	attribName(numParcelles) ///
	attribVars(^s16Aa01b)

createAttribute using "`attributesPath'", ///
	countWhere(s16Aq45 != 1 ) ///
	byGroup(interview__id interview__key) ///
	attribName(numParcellesNotMeasured) ///
	attribVars(^s16Aq45)

/*-----------------------------------------------------------------------------
19 : ÉQUIPEMENTS AGRICOLES
-----------------------------------------------------------------------------*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`rawDir'/`equipAgric'", nogen

* perçoit un revenu de location d'équipement
createAttribute using "`attributesPath'", ///
	anyWhere(s19q09 >0 & !mi(s19q09)) ///
	byGroup(interview__id interview__key) ///
	attribName(locationEquipement) ///
	attribVars(s19q09)

/*-----------------------------------------------------------------------------
BASES DÉRIVÉES
-----------------------------------------------------------------------------*/

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
CALORIES TOTALES
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`constructedDir'/`caloriesTot'", nogen

* niveau de calories par personne par jour
createAttribute using "`attributesPath'", ///
	extractAttrib(totCalories) ///
	attribName(caloriesTotales) ///
	attribVars(^s07Bq02_|^s07Bq03a_|^s07Bq03b_|^s07Bq03c_)

* trop de calories
createAttribute using "`attributesPath'", ///
	extractAttrib(caloriesTooHigh) ///
	attribName(caloriesTropElevees) ///
	attribVars(^s07Bq02_|^s07Bq03a_|^s07Bq03b_|^s07Bq03c_)

* trop peu de calories
createAttribute using "`attributesPath'", ///
	extractAttrib(caloriesTooLow) ///
	attribName(caloriesTropFaibles) ///
	attribVars(^s07Bq02_|^s07Bq03a_|^s07Bq03b_|^s07Bq03c_)

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
CALORIES PAR ITEM
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -*/

use "`casesToReview'", clear
merge 1:m interview__id interview__key using "`constructedDir'/`caloriesByItem'", nogen

* trop de calories déclarée pour un seul item
createAttribute using "`attributesPath'", ///
	anyWhere(highItemCalories == 1) ///
	byGroup(interview__id interview__key) ///
	attribName(caloriesItemElevees) ///
	attribVars(^s07Bq03a_|^s07Bq03b_|^s07Bq03c_)
