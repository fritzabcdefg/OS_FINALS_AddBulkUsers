# Script: 04_DeleteCreatedOUs.ps1
# Purpose: Delete ALL created objects - users, computers, groups, and OUs
# Domain: tupt.edu.ph
# This script removes everything created by the bulk user creation scripts

Import-Module ActiveDirectory

# Ensure the script runs from its own folder
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)

$DC1 = "DC=tupt,DC=edu,DC=ph"
$LogFile = "Logs\DeletedObjects_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Ensure log directory exists
if (-not (Test-Path "Logs")) {
    New-Item -ItemType Directory -Path "Logs" | Out-Null
}

function Write-Success { Write-Host $args -ForegroundColor Green; Add-Content $LogFile "SUCCESS: $args" }
function Write-Error-Log { Write-Host $args -ForegroundColor Red; Add-Content $LogFile "ERROR: $args" }
function Write-Info { Write-Host $args -ForegroundColor Cyan; Add-Content $LogFile "INFO: $args" }
function Write-Warning { Write-Host $args -ForegroundColor Yellow; Add-Content $LogFile "WARNING: $args" }

Write-Info "=========================================="
Write-Info "Starting Deletion of All Created Objects"
Write-Info "Domain: tupt.edu.ph"
Write-Info "=========================================="

# Academic Departments and Programs
$academicPrograms = @(
    "BTVTE-Electrical",
    "BTVTE-Electronics", 
    "BTVTE-Computer-Hardware",
    "BTVTE-Computer-Software",
    "Information-Technology",
    "Electrical-Engineering",
    "Electronics-Engineering",
    "Instrumentation-Control-Tech",
    "BET-Mechatronics",
    "Mechanical-Engineering-Tech",
    "RAC-Engineering-Tech",
    "Non-Destructive-Engineering-Tech",
    "Electromechanical-Engineering-Tech",
    "Automotive-Engineering-Tech",
    "BET-ElectroMechanical",
    "Civil-Engineering",
    "Civil-Engineering-Tech",
    "Environmental-Science",
    "Chemical-Engineering-Tech"
)

$academicDepartments = @(
    "Basic-Art-Sciences",
    "Electrical-Allied",
    "Mechanical-Allied",
    "Civil-Allied"
)

# Administrative Offices
$adminOffices = @(
    "Registrars-Office",
    "Directors-Office",
    "Research-Extension",
    "HR-Management-Office",
    "Finance-Office",
    "Supply-Procurement",
    "Records-Office",
    "Library-Services"
)

# ============================================================================
# STEP 1: Delete all users in academic programs
# ============================================================================
Write-Info ""
Write-Info "STEP 1: Deleting Academic Users..."
Write-Info ""

foreach ($dept in $academicDepartments) {
    foreach ($program in $academicPrograms) {
        $ouPath = "OU=$program,OU=$dept,OU=Academic,$DC1"
        $users = @(Get-ADUser -Filter * -SearchBase $ouPath -ErrorAction SilentlyContinue 2>$null)
        foreach ($user in $users) {
            if ($user) {
                Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
                Write-Success "  Deleted user: $($user.Name)"
            }
        }
    }
}

# ============================================================================
# STEP 2: Delete all users in administrative offices
# ============================================================================
Write-Info ""
Write-Info "STEP 2: Deleting Administrative Users..."
Write-Info ""

foreach ($office in $adminOffices) {
    $ouPath = "OU=$office,OU=Administrative,$DC1"
    $users = @(Get-ADUser -Filter * -SearchBase $ouPath -ErrorAction SilentlyContinue 2>$null)
    foreach ($user in $users) {
        if ($user) {
            Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
            Write-Success "  Deleted user: $($user.Name)"
        }
    }
}

# ============================================================================
# STEP 3: Delete all computers
# ============================================================================
Write-Info ""
Write-Info "STEP 3: Deleting Computer Objects..."
Write-Info ""

$computerOUPath = "OU=Workstations,$DC1"
$computers = @(Get-ADComputer -Filter * -SearchBase $computerOUPath -ErrorAction SilentlyContinue 2>$null)
foreach ($computer in $computers) {
    if ($computer) {
        Remove-ADComputer -Identity $computer.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
        Write-Success "  Deleted computer: $($computer.Name)"
    }
}

# ============================================================================
# STEP 4: Delete all security groups
# ============================================================================
Write-Info ""
Write-Info "STEP 4: Deleting Security Groups..."
Write-Info ""

# Delete academic program groups
foreach ($program in $academicPrograms) {
    $groupName = "$program-Users"
    $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue 2>$null
    if ($group) {
        Remove-ADGroup -Identity $group.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
        Write-Success "  Deleted group: $groupName"
    }
}

# Delete administrative office groups
foreach ($office in $adminOffices) {
    $groupName = "$office-Users"
    $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue 2>$null
    if ($group) {
        Remove-ADGroup -Identity $group.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
        Write-Success "  Deleted group: $groupName"
    }
}

# Delete main groups
$mainGroups = @("TUPT-Faculty", "TUPT-Staff", "TUPT-All-Users")
foreach ($groupName in $mainGroups) {
    $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue 2>$null
    if ($group) {
        Remove-ADGroup -Identity $group.DistinguishedName -Confirm:$false -ErrorAction SilentlyContinue 2>$null
        Write-Success "  Deleted group: $groupName"
    }
}

# ============================================================================
# STEP 5: Remove OU protection and delete OUs (recursively)
# ============================================================================
Write-Info ""
Write-Info "STEP 5: Deleting Organizational Units..."
Write-Info ""

function Remove-OU { 
    param(
        [string]$DistinguishedName,
        [string]$Label
    )

    # Remove protection from accidental deletion (silently ignore if OU doesn't exist)
    Set-ADOrganizationalUnit -Identity $DistinguishedName -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue 2>$null

    # Try to delete the OU (silently ignore if already deleted or doesn't exist)
    Remove-ADOrganizationalUnit -Identity $DistinguishedName -Recursive -Confirm:$false -ErrorAction SilentlyContinue 2>$null
    Write-Success "  Deleted OU: $Label"
}

# Delete Academic Department OUs (includes all program OUs underneath)
Write-Info "  Deleting Academic Department OUs..."
foreach ($dept in $academicDepartments) {
    $deptPath = "OU=$dept,OU=Academic,$DC1"
    Remove-OU -DistinguishedName $deptPath -Label "Academic/$dept"
}

# Delete Administrative Office OUs
Write-Info "  Deleting Administrative Office OUs..."
foreach ($office in $adminOffices) {
    $officePath = "OU=$office,OU=Administrative,$DC1"
    Remove-OU -DistinguishedName $officePath -Label "Administrative/$office"
}

# Delete parent OUs
Write-Info "  Deleting parent OUs..."
Remove-OU -DistinguishedName "OU=Academic,$DC1" -Label "Academic"
Remove-OU -DistinguishedName "OU=Administrative,$DC1" -Label "Administrative"
Remove-OU -DistinguishedName "OU=Workstations,$DC1" -Label "Workstations"

Write-Info ""
Write-Info "=========================================="
Write-Success "Deletion process completed!"
Write-Info "=========================================="
Write-Info ""
Write-Info "Log file: $LogFile"
