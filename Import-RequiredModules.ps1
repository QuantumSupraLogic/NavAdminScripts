$sourceDir = 'C:\Users\sd78438\Documents\source\GitHub'

#$modules = @("PsLibSqlTools", "PsLibConfigurationManager", "PsLibConsoleMenu", "PsLibCustomOutput", "PsLibGitTools", "PsLibNavTools", "PsLibPowerShellTools", "PsLibSqlQueries")
$modules = @("PsLibSqlQueries", "PsLibSqlTools")
ForEach ($module in $modules) 
{
    $User = $true
    if ($User) {
        $destination = "$HOME\Documents\WindowsPowerShell\Modules" 
    }
    else
    {
        $destination = "$Env:ProgramFiles\WindowsPowerShell\Modules" 
    }
    if (Get-Module $module) {
        Remove-Module $module
    }
    Join-Path $sourceDir "$module\$module" | Copy-Item -Destination $destination -Recurse -Force -Verbose

    Import-Module -Name $destination\$module 
    
    Get-Command -Module $module
}
