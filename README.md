# Table des matières

- [Présentation rapide](#présentation-rapide)
- [Installation](#installation)
    - [Télécharger ce répositoire](#télécharger-ce-répositoire)
    - [Installer R](#installer-r)
    - [Installer RStudio](#installer-rstudio)
    - [Installer rcall](#installer-rcall)
- [Paramétrage](#paramétrage)
    - [Mettre en place les bases](#mettre-en-place-les-bases)
    - [Modifier les paramètres](#modifier-les-paramètres)
- [Mode d'emploi](#mode-demploi)
    - [Rejet automatique](#rejet-automatique)
    - [Consulter avant de rejeter](#consulter-avant-de-rejeter)
    - [Ajouter des observations avant de rejeter](#ajouter-des-observations-avant-de-rejeter)
- [Dépannage](#dépannage)
    - [Problèmes connus](#problèmes-connus)
    - [Problèmes particuliers](#problèmes-particuliers)
    - [Problèmes généraux / requêtes de fonctionnalité](#problèmes-généraux--requêtes-de-fonctionnalité)

# Présentation rapide

Ce système de programmes a vocation d'automatiser la validation des entretiens de l'Enquête Harmonisée sur les Conditions des Vie des Ménages (EHCVM), notamment:

- Télécharger les données depuis le serveur
- Préparer les données pour validation
- Créer des bases auxiliares (e.g., consommation, calories)
- Recommender l'action à prendre pour chaque entretien:
    - Rejetter
    - Regarder de plus près
    - Approuver
- Automatiser le rejet
- Créer un rapport sur les rejets (À VENIR BIENTÔT)

Comme produit secondaire, ce programme crée plusieurs bases utiles:

- Liste d'entretiens selon l'action à prendre (dans le répertoire `/resultats/`)
    - toReject.dta. Les entretiens (à) rejetés. Ces entretiens ont au moins une erreur grave.
    - toReview.dta. Les entretiens à regarder de plus près. Ces entretiens l'un des attributs suivants: une erreur grave mais avec un commentaire (potentiellement) explicatif au niveau d'une variable impliquée dans l'erreur; un commentaire quelconque sur une variable ou sur l'entretien dans son ensemble; ou une erreur de validation de Survey Solutions.
- Calories par produit alimentaire. La base `caloriesByItem.dta` sera sauvegardée dans le dossier `/donnees/derivees/`.
- Calories totales . La base `totCalories.dta` sera sauvegardée dans le dossier `/donnees/derivees/`.
- Consommation alimentaire dans un seul roster. La base `foodConsumption.dta` sera sauvegardée dans `/donnees/derivees/`

# Installation

## Télécharger ce répositoire

- Cliquer sur le bouton `Clone or download`
- Cliquer sur l'option `Download ZIP`
- Télécharger dans le dossier sur votre machine où vous voulez héberger ce projet

## Installer R

Que ce soit pour installer R pour la première fois ou mettre le programme à jour:

- Suivre [ce lien](https://cran.rstudio.com/)
- Cliquer sur le lien approprié pour votre système d'exploitation
- Cliquer sur `base`
- Télécharger et installer

## Installer RStudio

Bien que RStudio n'est pas strictement requis, il est néanmoins fortement conseillé de l'installer, comme il facilite l'utilisation de R.

- Suivre [ce lien](https://www.rstudio.com/products/rstudio/download/)
- Sélectionner RStudio Desktop Open Source License
- Cliquer sur le lien approprié pour votre système d'exploitation
- Télécharger et installer

## Installer rcall

Que vous ayiez `rcall` déjà sur votre machine ou non, suivre ces instructions pour installer la plus récente version.

Avant d'installer `rcall`, installer l'ado Stata `github`. L'auteur de cet ado donne les instructions d'installation [ici](https://www.rstudio.com/products/rstudio/download/). Mais les étapes, en plus de détails, sont:

- Ouvrir Stata
- Exécuter la commande suivante: `net install github, from("https://haghish.github.io/github/")`

Après avoir installé l'ado `github`, installer `rcall` en suivant les instructions de l'auteur [ici](https://github.com/haghish/rcall#1-installation).

Si vous rencontrez une erreur de Stata, veuillez essayer de télécharger en dehors du bureau. Parfois, certaines structures bloque certaines addresses ou certaines activités. Donc, il est possible que vous ne puissiez pas installer `github` ou `rcall` au bureau, mais l'installation sur un autre réseau marche bien.

Pour confirmer l'installation, exécuter la commande suivante en Stata:

```
rcall sync : print("Bonjours")
```

Si l'on voit `[1] "Bonjours"`, `rcall` est bien paramétré.

Si l'on voit un message d'erreur, `rcall` ne sais pas où retrouver votre installation de R, et il faut lui indiquer le chemin manuellement.

Par défaut, `rcall` cherche R sur l’ordinateur à un certain endroit. Si l’ordinateur ne le repère pas à cet endroit, il faut indiquer l’adresse où se trouve R. Pour ce faire, suivre le processus suivant :

- Ouvrir RStudio
- Sélectionner « Global options » à partir du menu « Tools »
- Cliquer sur l’onglet « General », et copier l’adresse indiquée sous « R version », le chemin vers l’installation de R utilisée par RStudio
- Construire un chemin complet en copiant cette adresse, en ajoutant « /bin/R.exe » à la fin, et en s’assurant que l’adresse utilise des slashs (au lieu d’anti-slashs)
- Rouvrir Stata
- Lancer la commande suivante, où  [CHEMIN] est remplacé par le chemin construit ci-haut : `rcall setpath "[CHEMIN]"`
- Tester rcall à nouveau pour s’assurer que le paramétrage est bien fait. Voir plus haut le processus pour tester `rcall`.

Si `rcall` ne marche pas après plusieurs tentatives, lancer R par cmd. Voir [cette section](#how-to-call-r) pour plus de détails.

# Paramétrage 

## Mettre en place les bases

Ce système de programmes puise dans deux bases de données:

- `calories.dta`, distribué avec ce répositoire
- facteurs de conversion

Mettre la base des facteurs de conversation dans le dossier: `/donnees/ressources/`.

## Modifier les paramètres

Ces programmes ont plusieurs paramètres. Certains sont à modifier. D'autres sont à ne pas modifier.

Voici les paramètres à modifier par programme.

### configurePrograms.do

Comme son nom l'indique, ce programme rassemble la majeur partie des paramètres.

#### How to call R

Le programme présente deux choix pour lancer R:

1. `rcall`. C'est à dire avec l'ado `rcall`
2. cmd. C'est à dire avec la fenête de commande du système d'exploitation.

Voici les paramètres à renseigner:

- `howCallR`. Renseigner la valeur selon la méthode souhaitée pour lancer R: `rcall`, si par l'ado `rcall`; `shell`, si par la fenêtre de commande. Les deux options sont bonnes, mais la seconde est légèrement préférée, comme elle affiche aussi bien dans la fenêtre de commande du système d'exploitation que dans Stata le processus et les résultats des programmes R.
- `rPath`. Nécessaire seulement pour l'option de lancer R depuis la fenêtre de commande. Chemin du fichier `exe` responsable de lancer R. Pour construire ce chemin:
    + Ouvrir RStudio
    + Sélectionner "Global options" à partir du menu « Tools »
    + Cliquer sur l’onglet "General", et copier l’adresse indiquée sous "R version", le chemin vers l’installation de R utilisée par R Studio
    + Construire un chemin complet en copiant cette adresse et en ajoutant « /bin/R.exe » à la fin

#### Server details

A partir de la ligne 8, indiquer les paramètres suivants:

- `server`. Pour clarifier, pour les serveurs cloud, "demo" serait la valeur de `server` pour un serveur à l'adresse suivante "demo.mysurvey.solutions". Pour le serveur local, mettre l'adresse complète (e.g. `https://192.123.456`).
- `login`. Nom d'utilisateur pour un utilisateur de type API ou admin.
- `password`. Mot de passe de cet utilisateur.
- `nomMasque`. Titre du questionnaire. Indiquer le nom du masque tel qu’il apparait sur le serveur (hormis les numéros de versions). S’il y a plusieurs versions du même masque qui ont des nom différents, utiliser un nom qui identifie ces deux masques. Par exemple, si les masques sont « Questionnaire ménage UEMOA – Septembre 2018 » et « Questionnaire ménage UEMOA – Octobre 2018 », prendre la « racine » des deux : « Questionnaire ménage UEMOA ». Si souhaité, on peut également employer des expressions régulières. Par exemple, si l'on a des questionnaires `Questionnaire - octobre 2019` et `Questionnaire novembre 2019`, on peut utiliser l'expression régulière suivante pour désigner les deux à la fois: `Questionnaire - [a-z]+bre 2019`, puisque ces deux mois se termine en `bre`. Si le nom du masque comporte des caractères avec des accents (e.g., ç, é, À, Ü, etc.), on doit les remplacer avec `\\w`. Par exemple, `Questionnaire ménage` doit devenir `Questionnaire m\\wnage`.
- `exportType`. Ne toucher pas. Ce programme a besoin de données Stata pour fonctionner.
- `serverType`. Si le serveur est hébergé par la Banque Mondiale, laisser la valeur `"cloud"`. Si le serveur est hébergé localement, mettre `"local"`.

Pour créer un utilisateur de type API, se connecter au serveur en tant qu’admin, cliquer sur « Equipes et rôles », sélectionner « Utilisateurs de l’API », créer un compte, et utiliser le login et mot de passe, respectivement, pour les paramètres `login` et `password` décrits plus haut.

#### Identify interviews to process

A partir de la ligne 18, indiquer le statut(s) d'entretiens à valider. Si un seul statut est visé, renseigner le code entre guillemets. Si plusieurs statuts sont visés, renseigner ces codes comme une liste délimité par vigule.

Les options sont:

- Achevé par l'enquêteur. Chez SuSo, `Completed`. Renseigner le code `100`.
- Approuvé par le chef d'équipe. Chez SuSo, `ApprovedBySupervisor`. Renseigner le code `120`.

Voici quelques exemples avec explication:

Exemple 1: 

```
local statusesToReject "120"
```

Paramétré dans ce sens, le programme ne valide que les entretiens approuvés par le superviseur. Ainsi, le programme se limite au rôle de quartier général, validant le travail envoyé à son niveau.

Exemple 2:

```
local statusesToReject "100, 120"
```

Paramétré avec ces deux codes, le programme valide aussi bien les entretiens approuvés par le superviseur que les entretiens achevés par les enquêteurs. Ainsi, le programme agit simultanément à deux niveaux: premièrement, se subsituant aux chef d'équipe en contrôlant les entretiens achevés avant eux; deuxièmement, validant tout entretien approuvé par un chef d'équipe.

#### Calorie computation data and variables

A partir de la ligne 67, il faut décrire les fichiers impliqués dans le calcul de calories.

Pour les facteurs de conversion, il faut indiquer:

- `factorsDta`. Nom de la base des facteurs de conversion.
- `factorsByGeo`. Si les facteurs de conversion sont rangés par groupement géographique (e.g., région, strate, etc.). Si oui, mettre `"true"`. Sinon, mettre `"false"`.
- `geoIDs`. Deux cas de figure: 
    - Si les facteurs sont rangés par groupement géographique, indiquer la liste des variables géographiques qui identifent ces groupements. Notez que la liste est délimitée par les espaces (e.g., `s00q01 s00q04`). Notez également que le noms de ces variables doivent s'accorder avec ces mêmes variables dans la base ménage. 
    - Si les facteurs sont rangés simplement par produit-unité-taille, supprimer cette ligne.
- `prodID_fctrCurr`. Actuel mom de variable pour l'identifiant produit dans la base.
- `prodID_fctrNew`. Nouveau nom de variable à adopter pour l'identifiant produit. Pour le projet EHCVM, laisser ce paramètre tel quel: `"productID"`.
- `unitIDs_fctrCurr`. Actuels noms des variables pour identifier les unités-tailles dans la base.
- `unitIDs_fctrNew`. Nouveaux noms de variable pour ces identifiants. Notez que ces noms doivent s'accorder avec les noms dans la base consommation. Pour le projet EHCVM, laisser ce paramètre tel quel: `"s07Bq03b s07Bq03c"`.
- `factorVar`. Nom de variable pour le facteur de conversion.

Pour les autres paramètres de cette section, il faut les laisser tels quels pour le projet EHCVM.

Ceci dit, voici une description brève de ce qui est attendu par base.

Pour la base des calories par produit:

- `caloriesDta`. Nom de la base calories.
- `prodID_calCurr`. Actuel nom de l'identifiant produit.
- `prodID_calNew`. Nouveau nom de l'identifant produit à adopter. Notez que le nom de variable doit s'accorder avec celui des bases calorie et consommation.
- `caloriesVar`. Nom de la variable calories.
- `edibleVar`. Nom de la variable de la part consommable du produit.

Pour la base ménage:

`memberList`. La variable qui capte le nom des membres du ménage tel qu'il apparait dans Designer.

Pour la base de consommation:

`consoDta`. Nom de la base de consommation.
`quantityVar`. Nom de variable qui capte la quantité de consommation totale de chaque produit.

Pour le dossier de sortie:

`outputDir`. Dossier où souvegarder les sorties du calcul de calories.

### runAll.do

#### Chemin du projet

A la ligne 5, copier et coller le chemin d'accès au dossier projet--c'est à dire là où vous avez téléchargé et décomprimé ce répositoire. Notez: aucun besoin de modifier le chemin pour anticiper les besoins de R. Le programme s'en occupe.

#### computeCalories

Si les facteurs de conversion ne sont pas rangés par groupements géographiques, supprimer (uniquement) la ligne 188. Sinon, laisser la ligne telle quelle, ainsi que toutes les autres lignes dans ce bloc de code.

# Mode d'emploi

Voici les modes d'emploi possible et les instructions pour s'en acquitter.

## Rejeter automatique

Par défaut, le programme s'occupe de toutes les activités du rejet: obtention des données, préparation des données, prise de décision sur les rejets, et envoi de rejets par le serveur.

Pour ce faire, il suffit de lancer le programme `runAll.do` depuis Stata. Ce programme exécute tous les programme, R comme Stata, qui font partie du processus de rejet.

## Consulter avant de rejeter

<font color="red">!!! ATTENTION: Ceci sera simplifié dans l'avenir prôche !!!</font>

Si l'on souhaite voir les recommandations du programme et les passer en revue avant de rejeter, il faut arrêter l'exécution avant que les rejets sont communiqués au serveur.

Pour ce faire, avant de lancer `runAll.do`, ouvrir `processInterviews.R` (dans un éditeur de texte quelconque), mettre `# ` devant les lignes 66, 72, et 78, et sauvegarder `processInterviews.R`. Autrement dit, faire les ajustements ci-dessous:

```
# -----------------------------------------------------------------------------
# Decide what actions to take for each interview
# -----------------------------------------------------------------------------

source(paste0(progDir, "decideAction.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Make rejection messages
# -----------------------------------------------------------------------------

# source(paste0(progDir, "makeRejectMsgs.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Post comments
# -----------------------------------------------------------------------------

# source(paste0(progDir, "postComments.R"), echo = TRUE)

# -----------------------------------------------------------------------------
# Reject interviews
# -----------------------------------------------------------------------------

# source(paste0(progDir, "rejectInterviews.R"))
```

Ensuite, lancer `runAll.do` normalement. Ceci aura l'effet de créer la base `toReject.dta` -- c'est à dire la liste des entretiens à rejeter et les motifs du rejet.

Une fois que vous êtes prêt à rejeter ces entretiens:

- Ouvrir RStudio
- Ouvrir les programmes suivants: `filePath.R`,  `makeRejectMsgs.R`, `postComments.R`, et `rejectInterviews.R`
- Lancer les programmes individuellement dans l'ordre indiqué immédiatement ci-dessus, attendant que `postComments.R` se termine avant de lancer `rejectInterviews.R`.

## Ajouter des observations avant de rejeter

<font color="red">!!! ATTENTION: Ceci sera simplifié dans l'avenir prôche !!!</font>

Le programme rejette sur la base des observations compilées dans la base `/donnees/derivees/issues.dta`. 

On peut donc ajouter aux observations envoyées dans les entretiens rejetés en ajoutant des lignes dans cette base. 

Voici les colonnes qu'il faut renseigner pour les observations supplémentaires:

-  `interview__id`. L'identifiant de 32 caractères de Survey Solutions.
-  `interview__key`. L'identifiant de 8 chiffres de Survey Solutions.
-  `issueType`. Un code 1 ou 2. Le code 1 désigne un motif de rejet, et le message afférant fera partie du message de rejet global. Le code 2 désigne un commentaire à mettre au niveau de la variable concernée.
-  `issueDesc`. Une description très courte du problème. Maximum 5 mots. Ceci ne sera pas vu par l'enquêteur, mais paraîtra plutôt dans les rapports de rejet de quartier général.
-  `issueComment`. Une description détaillée du problème. C'est le message qui sera vu par l'enquêteur. Si `issueType == 1`, il intègre le message de rejet global. Si `issueType == 2`, il sert de commentaire au niveau d'une question dans l'entretien.
-  `issueVars`. Si `issueType == 1`, possible d'omettre. Si `issueType == 2`, c'est la variable à laquelle associer le commentaire.
-  `issueLoc`. Si `issueType == 2` et la variable est dans un roster, ligne de roster où afficher le commentaire. Si `issueType == 2` et la variable n'est pas dans un roster, mettre `null`. Si `issueType == 1`, omettre.

Voici la démarche pour faire appliquer ces observations:

Avant de lancer le programme, désactiver les programmes directement impliqués dans la décision du rejet et dans la communication vers le serveur des observations:

- Ouvrir `processInterviews.R` (dans un éditeur de texte quelconque)
- Mettre `# ` devant les lignes 60, 66, 72, et 79 -- autrement dit devant les programmes `decideAction.R`, `makeRejectMsgs.R`, `postComments.R`, `rejectInterviews.R`.
- Sauvegarder `processInterviews.R`.

Ayant modifié le programme:

- Lancer `runAll.do`
- Ajouter des observations supplémentaires à `/donnees/derivees/issues.dta` sans toucher aux autres observations
- Sauvegarder `issues.dta`
- Ouvrir RStudio
- Ouvrir les programmes suivants: `filePath.R`, `decideAction.R`, `makeRejectMsgs.R`, `postComments.R`, et `rejectInterviews.R`
- Lancer les programmes individuellement dans l'ordre indiqué immédiatement ci-dessus, attendant que `postComments.R` se termine avant de lancer `rejectInterviews.R`.

# Dépannage

## Problèmes connus

### Erreur à la fin de l'exécution

A la fin de l'exécution du programme `runAll.do`, Stata affiche un message d'erreur du style:

```
invalid '"interview__status' 
r(198);
```

Ceci n'empêche nullement l'exécution du programme et l'accomplissement de sa tâche. Mais, il faut le dire, c'est bizarre et ça soulève des questions.

### Absence de package requis

En principe, le programme doit installer tous les packages R requis. Si jamais un message d'erreur s'affiche indiquant l'abence d'un package, installer tous les packages en :

- Ouvrant RStudio
- Copiant, collant, et exécutant la syntaxe suivante

```
packagesNeeded <- c("httr", "RCurl", "dplyr", "haven", "stringr", "fuzzyjoin")
install.packages(packagesNeeded, 
    repos = 'https://cloud.r-project.org/', dep = TRUE)
```

## Problèmes particuliers

Veuillez vous approcher de votre membre d'appui de l'équipe CAPI de la Banque Mondiale / l'UEMOA.

## Problèmes généraux / requêtes de fonctionnalité

Veuillez décrire le problème sur ce répositoire.

### Processus

- Créer un compte GitHub. C'est facile et gratuit.
- Se connecter au site GitHub avec votre compte.
- Naviguer vers ce répositoire
- Cliquer sur l'onglet `Issues`
- Cliquer sur le bouton `New issue` 
- Regarder les consignes concernant le contentu [ici-bas](#contenu)
- Remplir le formulaire. 
- (Ne partager pas de données par GitHub comme ce répositoire est une plateforme publique.)

### Contenu

Pour les problèmes, donner une description qui permette de reproduire le problème. Au minimum, donner les étapes à suivre, le résultat obtenu, et le résultat escompté. Les captures d'écran--au pluriel--sont les bienvenues. Mieux encore, essayer de repèrer le problème, d'identifier les causes probables, et de proposer une solution.

Pour les requêtes de fonctionnalités, donner une description du comportement voulu, et de comment celui-ce se situe dans votre flux de travail habituel.

