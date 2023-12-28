if (-not (Get-Module PsLibConfigurationManager)) {
    Import-Module PsLibConfigurationManager
}

Write-Host 'Aus welcher Datenbank sollen Objekte exportiert werden?'
$i = 0
foreach ($SourceSystem in $config.SourceSystem) {
    $i += 1
    Write-Host $i ': ' $SourceDisplayName
}
Write-Host 'Strg-C : Abbruch'

Write-Host ' '
Write-Host 'Welche Objekte sollen exportiert werden?'
$i = 0
foreach ($ObjectGroup in $config.ObjectGroup) {
    $i += 1
    Write-Host $i ': ' $ObjectGroupDisplayName
}

