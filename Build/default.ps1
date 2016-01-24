properties {
	$testMessage = 'Executed Test!'
	$compileMessage = 'Executed Compile!'
	$cleanMessage = 'Executed Clean!'

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName # $solutionFile is set in build.ps1 (the bootstrapper)
	$outputDirectory = "$solutionDirectory\.build"
	$tempOutputDirectory = "$solutionDirectory\temp"
	$buildConfiguration = "Release"
	$buildPlatform = "Any CPU"
}

FormatTaskName "`r`n`r`n-------- Executing {0} Task --------"

task default -depends Test

task Init -description "Initializes the build by removing previous artifacts and creating output directories" `
		  -requiredVariables outputDirectory, tempOutputDirectory {

	Assert -conditionToCheck ("Debug", "Release" -contains $buildConfiguration) `
		   -failureMessage "Invalud build configuration '$buildConfiguration'. Valid values are 'Debug' or 'Release'"

	Assert -conditionToCheck ("x86", "x64", "Any CPU" -contains $buildPlatform) `
		   -failureMessage "Invalud build configuration '$buildPlatform'. Valid values are 'x86', 'x64' or 'Any CPU'"

	# Remove previous build results
	if (Test-Path $outputDirectory) {
		Write-Host "Removing output directory located at $outputDirectory"
		Remove-Item $outputDirectory -Force -Recurse
	}

	if (Test-Path $tempOutputDirectory) {
		Write-Host "Removing temp output directory located at $tempOutputDirectory"
		Remove-Item $tempOutputDirectory -Force -Recurse
	}

	Write-Host "Creating output directory located at $outputDirectory"
	New-Item $outputDirectory -ItemType Directory | Out-Null # Out-Null supresses outputted messages

	Write-Host "Creating temp directory located at $tempOutputDirectory"
	New-Item $tempOutputDirectory -ItemType Directory | Out-Null
}

task Compile -depends Init `
			 -description "Compile the code" `
			 -requiredVariables solutionFile, buildConfiguration, buildPlatform, tempOutputDirectory {
	Write-Host "Building solution $solutionFile"
	Exec { # Exec ensures that build fails correctly (checks the return code of external tasks)
		msbuild $SolutionFile "/p:Configuration=$buildConfiguration;Platform=$buildPlatform;OutDir=$tempOutputDirectory"
	}
}

task Clean -description "Remove temporary files" {
	Write-Host $cleanMessage
}

task Test -depends Compile, Clean -description "Run unit tests" {
	Write-Host $testMessage
}

## Invoke-psake -docs # Prints an overview of the script using strings specified with -description