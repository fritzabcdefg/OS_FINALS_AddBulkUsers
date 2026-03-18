#================================================================
# TUPT Active Directory - Create Administrative Department Users
# Domain: tupt.edu.ph
# Creates office structure and administrative users
#================================================================

Import-Module ActiveDirectory

# Ensure the script runs from its own folder (so relative paths work)
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)

# Configuration
$Domain = "tupt.edu.ph"
$DefaultPassword = "TuptAdmin@2026"
$SecurePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force
$LogFile = "Logs\AdministrativeUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Ensure log directory exists
if (-not (Test-Path "Logs")) {
    New-Item -ItemType Directory -Path "Logs" | Out-Null
}

function Write-Success { Write-Host $args -ForegroundColor Green; Add-Content $LogFile "SUCCESS: $args" }
function Write-Error-Log { Write-Host $args -ForegroundColor Red; Add-Content $LogFile "ERROR: $args" }
function Write-Info { Write-Host $args -ForegroundColor Cyan; Add-Content $LogFile "INFO: $args" }
function Write-Warning { Write-Host $args -ForegroundColor Yellow; Add-Content $LogFile "WARNING: $args" }

Write-Info "=========================================="
Write-Info "Creating Administrative Department Users"
Write-Info "Domain: $Domain"
Write-Info "=========================================="

# Administrative Offices Structure
$adminOffices = @(
    @{
        OfficeName = "Registrars-Office";
        DisplayName = "Registrar's Office";
        OUPath = "OU=Registrars-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Registrars-Office-Users";
        Description = "Registrar's Office Personnel"
    },
    @{
        OfficeName = "Directors-Office";
        DisplayName = "Director's Office";
        OUPath = "OU=Directors-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Directors-Office-Users";
        Description = "Director's Office Personnel"
    },
    @{
        OfficeName = "Research-Extension";
        DisplayName = "Research and Extension";
        OUPath = "OU=Research-Extension,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Research-Extension-Users";
        Description = "Research and Extension Personnel"
    },
    @{
        OfficeName = "HR-Management-Office";
        DisplayName = "Human Resource and Management Office";
        OUPath = "OU=HR-Management-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "HR-Management-Users";
        Description = "HR and Management Office Personnel"
    },
    @{
        OfficeName = "Finance-Office";
        DisplayName = "Finance Office";
        OUPath = "OU=Finance-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Finance-Office-Users";
        Description = "Finance Office Personnel"
    },
    @{
        OfficeName = "Supply-Procurement";
        DisplayName = "Supply and Procurement";
        OUPath = "OU=Supply-Procurement,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Supply-Procurement-Users";
        Description = "Supply and Procurement Personnel"
    },
    @{
        OfficeName = "Records-Office";
        DisplayName = "Records Office";
        OUPath = "OU=Records-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Records-Office-Users";
        Description = "Records Office Personnel"
    },
    @{
        OfficeName = "Library-Services";
        DisplayName = "Library Services";
        OUPath = "OU=Library-Services,OU=Administrative,DC=tupt,DC=edu,DC=ph";
        GroupName = "Library-Services-Users";
        Description = "Library Services Personnel"
    }
)

Write-Info ""
Write-Info "Creating security groups for administrative offices..."

foreach ($office in $adminOffices) {
    $groupExists = Get-ADGroup -Filter "Name -eq '$($office.GroupName)'" -ErrorAction SilentlyContinue
    if (-not $groupExists) {
        try {
            New-ADGroup `
                -Name $office.GroupName `
                -GroupCategory Security `
                -GroupScope Global `
                -Path "OU=Administrative,DC=tupt,DC=edu,DC=ph" `
                -Description $office.Description
            Write-Success "  Created group: $($office.GroupName)"
        }
        catch {
            Write-Warning "  ! Group creation failed: $($office.GroupName) - $_"
        }
    }
}

$AdminStudentsFile = "ADMIN_STUDENTS.txt"

function Create-AdministrativeUsersFromStudentLines {
    param(
        [string[]]$StudentLines
    )

    if (-not $StudentLines -or $StudentLines.Count -eq 0) {
        Write-Warning "No administrative student entries found."
        return
    }

    Write-Info "Creating administrative users from student list ($($StudentLines.Count) entries)..."

    $officeIndex = 0
    $usersCreated = 0
    $usersFailed = 0

    # Ensure StudentLines is always an array
    $studentArray = @()
    foreach ($line in $StudentLines) {
        if ($line -and $line.Trim().Length -gt 0) {
            $studentArray += $line.Trim()
        }
    }

    if ($studentArray.Count -eq 0) {
        Write-Warning "No valid student entries found after filtering."
        return
    }

    foreach ($line in $studentArray) {
        $parts = $line -split ','
        if ($parts.Count -lt 3) {
            Write-Warning "  ! Skipping malformed line: $line"
            continue
        }

        $lastName = $parts[0].Trim()
        $fullName = $parts[1].Trim()
        $gender = $parts[2].Trim()

        $firstName = ($fullName -split ' ')[0]
        $samAccountName = "$($firstName.Substring(0,1)).$lastName".ToLower() -replace '[^a-z0-9._-]', ''
        $userPrincipalName = "$samAccountName@$Domain"
        $office = $adminOffices[$officeIndex % $adminOffices.Count]
        $officeIndex++

        # Check for duplicate username
        $counter = 1
        $originalSam = $samAccountName
        while (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue) {
            $samAccountName = "$originalSam$counter"
            $counter++
        }

        try {
            # Create the user in the administrative office OU
            New-ADUser `
                -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -Name $fullName `
                -GivenName $firstName `
                -Surname $lastName `
                -DisplayName $fullName `
                -Path $office.OUPath `
                -AccountPassword $SecurePassword `
                -Enabled $true `
                -ErrorAction Stop

            Write-Success "  Created: $fullName ($samAccountName) [$gender] in $($office.OfficeName)"
            
            # Add user to the office security group
            try {
                Add-ADGroupMember -Identity $office.GroupName -Members $samAccountName -ErrorAction Stop
                Write-Info "    Added to group: $($office.GroupName)"
            }
            catch {
                Write-Warning "    ! Failed to add to group - $_"
            }
            
            $usersCreated++
        }
        catch {
            Write-Error-Log "  ! Failed to create user $fullName - $_"
            $usersFailed++
        }
    }

    Write-Info ""
    Write-Info "Administrative users summary:"
    Write-Info "  Created: $usersCreated"
    Write-Info "  Failed: $usersFailed"
}

Write-Info ""
Write-Info "=========================================="
Write-Info "Administrative User Creation Instructions"
Write-Info "=========================================="
Write-Info ""
Write-Info "AUTOMATIC WORKFLOW (recommended):"
Write-Info "  1. Run 01_CreateAcademicUsers.ps1 first"
Write-Info "     - Creates 250 academic users"
Write-Info "     - Saves remaining ~67 students to ADMIN_STUDENTS.txt"
Write-Info ""
Write-Info "  2. Run this script (02_CreateAdministrativeUsers.ps1)"
Write-Info "     - Automatically creates admin users from ADMIN_STUDENTS.txt"
Write-Info "     - Distributes ~8-9 users per office (67 / 8 offices)"
Write-Info ""


# Function to create sample administrative users
# (Removed - using automatic student data instead)


Write-Info ""
Write-Info "=========================================="
Write-Info "Administrative infrastructure created!"
Write-Info "=========================================="

Write-Info ""
Write-Info "Log file: $LogFile"

# Automatically create admin users from the split student list (created by 01_CreateAcademicUsers.ps1)
Write-Info ""
Write-Info "=========================================="
Write-Info "Creating administrative users from student list"
Write-Info "=========================================="
Write-Info ""

# First, try to use ADMIN_STUDENTS.txt if it exists (created by 01_CreateAcademicUsers.ps1)
if (Test-Path $AdminStudentsFile) {
    Write-Info "Reading administrative students from: $AdminStudentsFile"
    $adminLines = @(Get-Content $AdminStudentsFile)
    if ($adminLines -and $adminLines.Count -gt 0) {
        Create-AdministrativeUsersFromStudentLines $adminLines
    }
    else {
        Write-Warning "No student records found in $AdminStudentsFile"
    }
}
else {
    Write-Warning "Admin student file not found: $AdminStudentsFile"
    Write-Info "Attempting alternate approach: Using remaining students from ALL_STUDENTS.txt..."
    
    # Fallback: Read from ALL_STUDENTS.txt and use the last portion for admin users
    $AllStudentsFile = "ALL_STUDENTS.txt"
    if (Test-Path $AllStudentsFile) {
        $allStudentsLines = @(Get-Content $AllStudentsFile)
        if ($allStudentsLines -and $allStudentsLines.Count -gt 0) {
            Write-Info "Total students in ALL_STUDENTS.txt: $($allStudentsLines.Count)"
            
            # Reserve students for administrative accounts (typically 10-20% of total or a fixed number)
            $totalStudents = $allStudentsLines.Count
            $academicStudentCount = [Math]::Ceiling($totalStudents * 0.8) # 80% for academic
            $reservedForAdmins = $totalStudents - $academicStudentCount
            
            if ($reservedForAdmins -gt 0) {
                # Get the last N students for administrative use
                $adminStudents = @($allStudentsLines[(-$reservedForAdmins)..-1])
                Write-Info "Reserved $reservedForAdmins students for administrative assignment"
                Create-AdministrativeUsersFromStudentLines $adminStudents
            }
            else {
                Write-Warning "Not enough students to reserve for administrative accounts."
            }
        }
        else {
            Write-Error-Log "ALL_STUDENTS.txt is empty or unreadable"
        }
    }
    else {
        Write-Error-Log "Neither admin student file nor all students file found!"
        Write-Info "Please run 00_CreateOrganizationalUnits.ps1 first, then 01_CreateAcademicUsers.ps1"
    }
}