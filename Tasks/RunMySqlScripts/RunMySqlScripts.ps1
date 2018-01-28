﻿[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Write-Output "Starting RunMySqlScripts"
Trace-VstsEnteringInvocation $MyInvocation

try {
	Import-VstsLocStrings -LiteralPath "$PSScriptRoot/task.json"

	[string]$serverHost = Get-VstsInput -Name serverHost -Require
	[string]$serverPort = Get-VstsInput -Name serverPort -Require
	[bool]$executeOnDbLvl = Get-VstsInput -Name executeOnDbLvl -AsBool
	[string]$databaseName = Get-VstsInput -Name databaseName
	[string]$connectionTimeout = Get-VstsInput -Name connectionTimeout
	[string]$serverUserName = Get-VstsInput -Name serverUsername -Require
	[string]$serverPassword = Get-VstsInput -Name serverPassword -Require
	[string]$mysqlScripts = Get-VstsInput -Name mysqlScripts -Require

	Import-Module "$PSScriptRoot\ps_modules\MySql\MySql.psm1"

	if ($executeOnDbLvl) {
		Connect-MySqlServer -Server $serverHost -Port $serverPort -Username $serverUserName -Password $serverPassword -Database $databaseName -Timeout $connectionTimeout
		Write-Output "Running MySQL scripts on database: $databaseName"
	}
	else {
		Connect-MySqlServer -Server $serverHost -Port $serverPort -Username $serverUserName -Password $serverPassword -Timeout $connectionTimeout
		Write-Output "Running MySQL scripts on server: $serverHost"
	}

	foreach ($mysqlScript in Get-ChildItem -Path "$mysqlScripts" -Filter "*.sql" | Sort-Object)
	{
		Write-Output "Running script: $($mysqlScript.Name)"
		$mysqlCommand = Get-Content -Path $mysqlScript.FullName -Raw
		Invoke-MySqlQuery -Query $mysqlCommand -Verbose
	}
	
	Disconnect-MySqlServer -Verbose

	Write-Output "Finished"
}
catch {
	Write-Error "Error running MySQL scripts: $_"
}
finally {
	Trace-VstsLeavingInvocation $MyInvocation
}

Write-Output "Ending RunMySqlScripts"