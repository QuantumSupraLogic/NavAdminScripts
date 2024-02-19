#Requires -Version 5.1

param (
    # Specifies the computer name where the sql database resides
    [Parameter(Mandatory)]
    [string]
    $DataSource,
    # Specifies the database name of the
    [Parameter(Mandatory)]
    [string]
    $DatabaseName,
    # Specifies a path to store the objects. If a relative path is specified, $PSScriptRoot will be used as root
    [Parameter()]
    [string]
    $Path,
    # Specifies a filter on the version list of the objects to export
    [Parameter()]
    [string]
    $ObjectFilter,
    # Specifies if file explorer should be openend after exporting the objects
    [Parameter()]
    [switch]
    $RevealInFileExplorer
    
    )
    # NAV cmdlets are only compatible with powershell version 5.1
    if ($PSVersionTable.PSEdition -ne 'Desktop') {
    # Re-launch as version 5 if we're not already
    if ($RevealInFileExplorer) {
        powershell -Version 5.1 -File $MyInvocation.MyCommand.Definition -DataSource $dataSource -DatabaseName $databaseName -Path $path -ObjectFilter $ObjectFilter -RevealInFileExplorer
    } else {
        powershell -Version 5.1 -File $MyInvocation.MyCommand.Definition -DataSource $dataSource -DatabaseName $databaseName -Path $path -ObjectFilter $ObjectFilter 
    }

    exit
}
Set-StrictMode -Version 3.0
$env:PSModulePath = $env:PSModulePath.Replace(";$HOME\Documents\PowerShell\Modules", '')
$env:PSModulePath += ";$HOME\Documents\PowerShell\Modules"

if (-not (Get-Module PsLibNavTools)) {
    Import-Module PsLibNavTools
}
if (-not (Get-Module PsLibPowerShellTools)) {
    Import-Module PsLibPowerShellTools
}

function main {
    $DestinationDirectory
    
    if ([System.IO.Path]::IsPathRooted($Path)) {
        $DestinationDirectory = $Path
    } else {
        $TempFolder = New-TemporaryDirectory
        $DestinationDirectory = Join-Path -Path $TempFolder $Path
    }

    Write-Verbose 'Exporting objects'
    $tempFile = [IO.Path]::GetTempFileName() | Rename-Item -NewName { $_ -replace 'tmp$', 'txt' } -PassThru
    Export-NavApplicationObjectsAsTxt -dataSource $dataSource -databaseName $databaseName -exportFile $tempFile -filter $ObjectFilter

    Write-Verbose 'Splitting objects'
    Split-NavApplicationObjectsTxt -sourceFile $tempFile -destinationDirectory $DestinationDirectory

    Remove-Item $tempFile

    if ($revealInFileExplorer) {
        Set-Location $DestinationDirectory
        Invoke-Item .
    }
    return $DestinationDirectory
}

main