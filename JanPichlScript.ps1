<#PSScriptInfo

.COMPANYNAME I&C Energo a.s.

.AUTHOR Jan Pichl

.GUID e2f9c313-4c7e-4702-ae74-bd2ee0e6ddfa

.VERSION 1.0.0
#>

<#
.SYNOPSIS
Tento script vyhledá v zadaném adresáři všechny soubory s požadovanou příponou. Provede jejich zálohu a z původního souboru odstraní všechny výskyty zadaného znaku. 

.DESCRIPTION
    Aby script pracoval je potřeba zadat parametr
    -folderPath cesta k adresáři ve kterém bude provedena záměna

.EXAMPLE
    JanPichlScript.ps1 c:\1a -removeByte '26' -fileType '.txt','*.cpp','.php' -backupExtension 'bck' -recursive $true 

.PARAMETER folderPath
    Parametr určuje cestu k adresáři ve kterém budou vyhledány soubory.

.PARAMETER removeByte
    Parametr určuje dekadickou hodnotu Bytu v ASCII tabulce, který má být odstraněn

.PARAMETER fileType
    Parametr určuje typ/příponu souborů, které mají být vyhledány

.PARAMETER backupExtension
    Parametr určuje příponu která bude nastavena záložním souborům

.PARAMETER recursive
    Parametr určuje zda budou soubory hledány i v podadresářích zadaného adresáře

#>

    Param
    (
    [Parameter(Mandatory = $true)]
    [string] $folderPath,

    [Parameter(Mandatory = $false)]
    [byte] $removeByte = 26,

    [Parameter(Mandatory = $false)]
    [string[]] $fileType = '*.txt',

    [Parameter(Mandatory = $false)]
    [string] $backupExtension = '.bck',

    [Parameter(Mandatory = $false)]
    [bool] $recursive = $false
    )

    Clear-Host
    
    $progresStep=0;

    $fileType =  $fileType | ForEach-Object{ '.' + $_.TrimStart('*').TrimStart('.') }
    $backupExtension =  $backupExtension | ForEach-Object{ '.' + $_.TrimStart('*').TrimStart('.') }
    
    if ( -not ( Test-Path $folderPath -PathType Container  ) )
    {
        Write-Host "Directory dont exist:" $folderPath
        Break Script
    }

    if ( $recursive ) 
    {
        $Files = Get-ChildItem  $folderPath -Recurse  | Where-Object {$_.Extension -in $fileType} | ForEach-Object {$_.FullName}
    }
    else 
    {
        $Files = Get-ChildItem  $folderPath | Where-Object {$_.Extension -in $fileType} | ForEach-Object {$_.FullName}
    }

    $countOfFile = ( $Files | Measure-Object ).Count
    
    Write-Host "Searched $countOfFile count of files in directory $folderPath and filetype $fileType, recursive=$recursive"
    Write-Host 

    if ( $countOfFile -lt 1 )
    {
        Write-Host "Break"

        Break Script
    }

    Foreach ( $i in $Files )
    {
        $backupPath = $i + $backupExtension

        $progresStep += 1
        
        if ( Test-Path $backupPath -PathType Leaf )
        {
            # Záloha již existuje, soubor proto přeskočíme.

            Write-Host "$progresStep  Any backup file is exist. Changing be skipped $backupPath"
        }
        else
        {
            # Záloha zatím není vytvořena, soubor zpracujeme.

            Copy-Item $i -Destination $backupPath
            
            Write-Host "$progresStep  Backup created now $backupPath"
            
            ( Get-Content $i -Encoding Byte ) | Where-Object { $_ –ne $removeByte } |  Set-Content $i  -Encoding Byte
        }

        <# Případné zobrazení progress baru #>

        #$percentComplete = [math]::Round(100 / $countOfFile * $progresStep )
        #Write-Progress -Activity "Processed" -Status "$percentComplete% Complete:" -PercentComplete $percentComplete 
        #start-Sleep (1)
    }  

    Write-Host 
