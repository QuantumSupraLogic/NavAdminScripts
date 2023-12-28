# TODO insert only if not exists
# TODO ask for overwrite
# TODO tables from config
# TODO Change Cronus AG
param (
    [Parameter(Mandatory)]
    [string] $userId
)

function Main {
    if (-not (Get-Module PsLibConfigurationManager)) {
        Import-Module PsLibConfigurationManager
    }
    if (-not (Get-Module PsLibSqlTools)) {
        Import-Module PsLibSqlTools
    }

    $config = Get-Configuration -configurationFile "$PSScriptRoot\config\Copy-NavProdUserToTest_config.json"

    $sqlParams = @{}
    $sqlParams.Add('userId', $userId)
    $queryResult = 'SELECT [User Security ID] as UserSid FROM [User] WHERE [User Name] = @userId' | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
    $userSid = $queryResult[0].UserSid.ToString()
        
    $sqlParams.Add('userSid', $queryResult[0].UserSid)
    $queryResult = 'SELECT [Salespers__Purch_ Code] as SalespersonCode FROM [Cronus AG$User Setup] WHERE [User ID] = @userId' | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
    $salespersonCode = $queryResult[0].SalespersonCode
    $sqlParams.Clear()
    
    $script:sourceSystemIdentifier = $config.SourceSystem.DataSource + '.' + $config.SourceSystem.DatabaseName
    foreach ($DestinationSystem in $config.DestinationSystem) { 
        $script:destinationSystemIdentifier = $DestinationSystem.DataSource + '.' + $DestinationSystem.DatabaseName
        
        $sqlParams.Clear()
        
        $tableName = 'User'
        $sqlParams.Add('whereField', '[User Name]')
        $sqlParams.Add('whereValue', $userId)
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName

        $sqlParams['whereField'] = '[User ID]'
        $sqlParams['whereValue'] = $userId
        $tableName = 'Cronus AG$User Setup'
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName
        $tableName = 'Cronus AG$User Setup'
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName

        $sqlParams['whereField'] = '[User Security ID]'
        $sqlParams['whereValue'] = $userSid
        $tableName = 'Access Control'
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName
        
        $sqlParams['whereField'] = '[User Security ID]'
        $sqlParams['whereValue'] = "$userSid"
        $tableName = 'User Group Member'
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName
        
        $sqlParams['whereField'] = '[User SID]'
        $sqlParams['whereValue'] = "$userSid"
        $tableName = 'User Personalization'
        CopyTableToProd -tableName $tableName | Invoke-SqlQuery -dataSource $config.SourceSystem.DataSource -databaseName $config.SourceSystem.DatabaseName -parameters $sqlParams
        SelectInsertedRecords -tableName $tableName | Invoke-SqlQuery -dataSource $DestinationSystem.DataSource -databaseName $DestinationSystem.DatabaseName -parameters $sqlParams | PrintResult -tableName $tableName

    }
}
function CopyTableToProd {
    param(
        [string] $tableName
    )    
    $sql = "
                DECLARE @columnsToSkip varchar(max) = 'timestamp'
                DECLARE @columns varchar(max)
        
                SELECT @columns = ISNULL(@columns + ', ','') + QUOTENAME(COLUMN_NAME)
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = '$tableName' AND COLUMN_NAME <> @columnsToSkip
                ORDER BY ORDINAL_POSITION
                
                EXEC ('INSERT INTO $script:destinationSystemIdentifier.dbo.[$tableName] (' + @columns + ') SELECT ' + @columns + ' FROM $script:sourceSystemIdentifier.dbo.[$tableName] WHERE ' + @whereField + ' = ''' + @whereValue + '''')
            "
        
    return $sql
}

function PrintResult {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [object] $queryResult,
        [string] $tableName
    )
    Write-Host "Datensätze angelegt in Table $tableName : " $queryResult[0].count " in System $script:destinationSystemIdentifier"
}

function SelectInsertedRecords {
    param(
        [string] $tableName
    )
    $sql = "
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
        SELECT COUNT(*) as count FROM [$TableName] WHERE @whereField = @whereValue
    "
    return $sql
}

Main
