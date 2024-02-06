Set-StrictMode -Version 3.0

Write-Host 'Bitte geben Sie die User ID inkl. Domäne an von dem User, der aus dem Henri Produktivsystem in alle Testsysteme kopiert werden soll.'
$userId = Read-Host '> '

.\Copy-NavProdUserToTest\Copy-NavProdUserToTest.ps1 -userId $userId 


