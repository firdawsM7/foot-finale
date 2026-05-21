# Smoke test API - MAS de Fès Club Foot
$ErrorActionPreference = "Continue"
$BaseUrl = "http://localhost:8084/api"
$Results = @()

function Test-Api {
    param(
        [string]$Name,
        [string]$Method = "GET",
        [string]$Path,
        [string]$Token = $null,
        [object]$Body = $null,
        [int[]]$ExpectedStatus = @(200)
    )
    $headers = @{ "Content-Type" = "application/json" }
    if ($Token) { $headers["Authorization"] = "Bearer $Token" }
    $uri = "$BaseUrl$Path"
    try {
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $headers
            UseBasicParsing = $true
            TimeoutSec = 15
        }
        if ($Body) { $params["Body"] = ($Body | ConvertTo-Json -Compress) }
        $resp = Invoke-WebRequest @params
        $ok = $ExpectedStatus -contains $resp.StatusCode
        $script:Results += [PSCustomObject]@{
            Test = $Name
            Status = if ($ok) { "OK" } else { "FAIL" }
            Code = $resp.StatusCode
            Detail = ""
        }
    } catch {
        $code = 0
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        $ok = $ExpectedStatus -contains $code
        $script:Results += [PSCustomObject]@{
            Test = $Name
            Status = if ($ok) { "OK" } else { "FAIL" }
            Code = $code
            Detail = $_.Exception.Message
        }
    }
}

function Get-Token {
    param([string]$Email, [string]$Password = "password")
    $r = Invoke-WebRequest -Uri "$BaseUrl/auth/login" -Method POST `
        -ContentType "application/json" `
        -Body (@{ email = $Email; password = $Password } | ConvertTo-Json) `
        -UseBasicParsing
    ($r.Content | ConvertFrom-Json).token
}

Write-Host "=== Smoke test API ($BaseUrl) ===" -ForegroundColor Cyan

# Auth
Test-Api "Login admin" POST "/auth/login" -Body @{ email = "admin@gmail.com"; password = "password" }
$adminToken = Get-Token "admin@gmail.com"
Test-Api "Auth /me (admin)" GET "/auth/me" -Token $adminToken

Test-Api "Login encadrant" POST "/auth/login" -Body @{ email = "coach.gamondi@gmail.com"; password = "password" }
$encToken = Get-Token "coach.gamondi@gmail.com"

Test-Api "Login adherent" POST "/auth/login" -Body @{ email = "member@gmail.com"; password = "password" }
$adhToken = Get-Token "member@gmail.com"

Test-Api "Login joueur" POST "/auth/login" -Body @{ email = "joueur1@gmail.com"; password = "password" }
$jouToken = Get-Token "joueur1@gmail.com"

# Admin
Test-Api "Admin equipes" GET "/admin/equipes" -Token $adminToken
Test-Api "Admin joueurs" GET "/admin/joueurs" -Token $adminToken
Test-Api "Admin entrainements" GET "/admin/entrainements" -Token $adminToken
Test-Api "Admin matchs" GET "/admin/matchs" -Token $adminToken
Test-Api "Admin cotisations" GET "/admin/cotisations" -Token $adminToken
Test-Api "Admin users list" GET "/admin/users" -Token $adminToken
Test-Api "Admin dashboard" GET "/admin/dashboard/stats" -Token $adminToken
Test-Api "Admin messages" GET "/admin/messages" -Token $adminToken
Test-Api "Admin messages stats" GET "/admin/messages/stats" -Token $adminToken

# Encadrant
Test-Api "Encadrant equipes" GET "/encadrant/equipes" -Token $encToken
Test-Api "Encadrant joueurs" GET "/encadrant/joueurs" -Token $encToken
Test-Api "Encadrant entrainements" GET "/encadrant/entrainements" -Token $encToken
Test-Api "Encadrant matchs" GET "/encadrant/matchs" -Token $encToken
Test-Api "Encadrant cotisations" GET "/encadrant/cotisations" -Token $encToken

# Adherent
Test-Api "Adherent equipes" GET "/adherent/equipes" -Token $adhToken
Test-Api "Adherent joueurs" GET "/adherent/joueurs" -Token $adhToken
Test-Api "Adherent entrainements" GET "/adherent/entrainements" -Token $adhToken
Test-Api "Adherent matchs" GET "/adherent/matchs" -Token $adhToken
Test-Api "Adherent cotisations" GET "/adherent/cotisations" -Token $adhToken

# Joueur (adherent paths)
Test-Api "Joueur cotisations" GET "/adherent/cotisations" -Token $jouToken

# Notifications
Test-Api "Notifications" GET "/notifications" -Token $adhToken
Test-Api "Notifications unread" GET "/notifications/unread-count" -Token $adhToken

# User messages
Test-Api "Messages announcements" GET "/messages/announcements" -Token $adhToken

# Security: encadrant cannot access admin
Test-Api "Encadrant blocked from admin" GET "/admin/users" -Token $encToken -ExpectedStatus @(403,401)

# Register -> ADHERENT (not INSCRIT)
$testEmail = "smoke.test.$(Get-Date -Format 'yyyyMMddHHmmss')@test.local"
Test-Api "Register new user" POST "/auth/register" -Body @{
    email = $testEmail
    password = "password123"
    nom = "Smoke"
    prenom = "Test"
    telephone = "0600000099"
} -ExpectedStatus @(200)

# Role filter: no INSCRIT in admin users
try {
    $usersResp = Invoke-WebRequest -Uri "$BaseUrl/admin/users" -Headers @{ Authorization = "Bearer $adminToken" } -UseBasicParsing
    $users = $usersResp.Content | ConvertFrom-Json
    $inscritCount = @($users | Where-Object { $_.role -eq "INSCRIT" }).Count
    $script:Results += [PSCustomObject]@{
        Test = "No INSCRIT users in API"
        Status = if ($inscritCount -eq 0) { "OK" } else { "FAIL" }
        Code = 200
        Detail = "Found $inscritCount INSCRIT"
    }
} catch {
    $script:Results += [PSCustomObject]@{ Test = "No INSCRIT users in API"; Status = "FAIL"; Code = 0; Detail = $_.Exception.Message }
}

Write-Host ""
$ok = ($Results | Where-Object { $_.Status -eq "OK" }).Count
$fail = ($Results | Where-Object { $_.Status -eq "FAIL" }).Count
$Results | Format-Table -AutoSize
Write-Host "Resultat: $ok OK, $fail ECHEC(s)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
if ($fail -gt 0) { exit 1 }
