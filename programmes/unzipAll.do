
/*=============================================================================
					DESCRIPTION OF PROGRAM
					------------------------

DESCRIPTION:	Unzips all .zip  files in target folder
				- Creates a new folder for the zip file's contents whose name
					matches that of the file
				- Reacts to existing folders with desired name
				- Copies the zip file from the target folder to newly created folders

DEPENDENCIES:	

INPUTS:			

OUTPUTS:		

SIDE EFFECTS:	Unzips files, creates directories

AUTHOR: 		Arthur Shaw, jshaw@worldbank.org
=============================================================================*/

capture program drop unzipAll
program define unzipAll
syntax ,							///
	folder(string)					///
	[dirExistErr(string)]			/// values: true or false. If true, say that folder exists and exit. If false, delete without confirmation. By default, set to false.

	* set directory existenc message to false if parameter not provided 
	if missing("`dirExistErr'") {
		local dirExistErr "false"
	}

	* collect names of all zip files
	local zipFiles: dir "`folder'" files "*.zip", respectcase
	local zipFiles: list clean zipFiles

	* unzip each file into a sub-folder with the name of the file (minus the ".zip" extension)
	foreach zipFile of local zipFiles {

		* construct full path of the destination folder
		local subFolder = subinstr("`zipFile'",".zip","",.)		// strip .zip from file name
		local filePath = "`folder'" + "/" + "`subFolder'" + "/"		// concatenate folder and file name

		* if the folder already exists, delete it and its contents without confirmation
		quietly capture cd `"`filePath'"'
		if _rc == 0 {
			if "`dirExistErr'" ==  "true" {
				di as error "ERROR: A subfolder with this name already exists: `subfolder'"
				di as error "Please move this folder elsewhere and run this program again."
			}
			else if inlist("`dirExistErr'", "false") {
				! rmdir "`filePath'" /s /q	
			}
		}

		* create the destination folder folder
		mkdir "`filePath'"

		* copy current zip file into destination folder
		copy "`folder'/`zipFile'" "`filePath'/`zipFile'"

		* unpack zip file's contents into destination folder
		qui : cd "`filePath'"
		qui : unzipfile  "`filePath'/`zipFile'", replace	


	}

end
