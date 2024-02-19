if (-not (Get-Module PsLibConfigurationManager)) {
    Import-Module PsLibConfigurationManager
}

$config = Get-Configuration -configurationFile "$PSScriptRoot\config\Export-NavObjects_Config.json"

Write-Host 'Aus welcher Datenbank sollen Objekte exportiert werden?'
$i = 0
foreach ($SourceSystem in $config.SourceSystem) {
    $i += 1
    Write-Host $i ': ' $SourceSystem.DisplayName
}
Write-Host 'Strg-C : Abbruch'

$choice = Read-Host '> '
if ($choice -notin 1..$i) {
    throw "Ungueltige Auswahl: $choice. Abbruch."
}
$srcSystem = $config.SourceSystem[$choice - 1]


Write-Host ' '
Write-Host 'Welche Objekte sollen exportiert werden?'
$i = 0
foreach ($ObjectGroup in $config.ObjectGroup) {
    $i += 1
    Write-Host $i ': ' $ObjectGroup.DisplayName
}
Write-Host 'Strg-C : Abbruch'

$choice = Read-Host '> '
if ($choice -notin 1..$i) {
    throw "Ungueltige Auswahl: $choice. Abbruch."
}
$objGrp = $config.ObjectGroup[$choice - 1]

.\Export-NavObjects\Export-NavObjects.ps1 -DataSource $srcSystem.DataSource -DatabaseName $srcSystem.DatabaseName -Path $objGrp.Path -ObjectFilter $objGrp.ObjectFilter -RevealInFileExplorer