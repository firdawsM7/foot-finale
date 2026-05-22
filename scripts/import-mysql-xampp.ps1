# Importe une sauvegarde MySQL (XAMPP/phpMyAdmin) dans MySQL Docker
# Usage :
#   1. Exporter depuis XAMPP : phpMyAdmin → clubdb → Exporter → SQL
#   2. .\scripts\import-mysql-xampp.ps1 -SqlFile "C:\chemin\clubdb.sql"

param(
    [Parameter(Mandatory = $true)]
    [string]$SqlFile
)

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $SqlFile)) {
    Write-Error "Fichier introuvable : $SqlFile"
    exit 1
}

$password = (Get-Content .env | Where-Object { $_ -match '^MYSQL_ROOT_PASSWORD=' }) -replace 'MYSQL_ROOT_PASSWORD=', ''
if (-not $password) { $password = 'club_root_change_me' }

Write-Host "Import de $SqlFile vers club-mysql (clubdb)..."
Get-Content $SqlFile -Raw | docker exec -i club-mysql mysql -uroot "-p$password" clubdb

if ($LASTEXITCODE -eq 0) {
    Write-Host "Import terminé. Redémarrez le backend : docker compose restart backend"
} else {
    Write-Error "Échec de l'import."
}
