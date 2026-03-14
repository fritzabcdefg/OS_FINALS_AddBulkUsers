#================================================================
# TUPT Active Directory - Create Administrative Department Users
# Domain: tupt.com
# Creates office structure and administrative users
#================================================================

Import-Module ActiveDirectory

# Configuration
$Domain = "tupt.com"
$DefaultPassword = "TuptAdmin@2024"
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
        OUPath = "OU=Registrars-Office,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Registrars-Office-Users";
        Description = "Registrar's Office Personnel"
    },
    @{
        OfficeName = "Directors-Office";
        DisplayName = "Director's Office";
        OUPath = "OU=Directors-Office,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Directors-Office-Users";
        Description = "Director's Office Personnel"
    },
    @{
        OfficeName = "Research-Extension";
        DisplayName = "Research and Extension";
        OUPath = "OU=Research-Extension,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Research-Extension-Users";
        Description = "Research and Extension Personnel"
    },
    @{
        OfficeName = "HR-Management-Office";
        DisplayName = "Human Resource and Management Office";
        OUPath = "OU=HR-Management-Office,OU=Administrative,DC=tupt,DC=com";
        GroupName = "HR-Management-Users";
        Description = "HR and Management Office Personnel"
    },
    @{
        OfficeName = "Finance-Office";
        DisplayName = "Finance Office";
        OUPath = "OU=Finance-Office,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Finance-Office-Users";
        Description = "Finance Office Personnel"
    },
    @{
        OfficeName = "Supply-Procurement";
        DisplayName = "Supply and Procurement";
        OUPath = "OU=Supply-Procurement,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Supply-Procurement-Users";
        Description = "Supply and Procurement Personnel"
    },
    @{
        OfficeName = "Records-Office";
        DisplayName = "Records Office";
        OUPath = "OU=Records-Office,OU=Administrative,DC=tupt,DC=com";
        GroupName = "Records-Office-Users";
        Description = "Records Office Personnel"
    },
    @{
        OfficeName = "Library-Services";
        DisplayName = "Library Services";
        OUPath = "OU=Library-Services,OU=Administrative,DC=tupt,DC=com";
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
                -Path "OU=Administrative,DC=tupt,DC=com" `
                -Description $office.Description
            Write-Success "  ✓ Created group: $($office.GroupName)"
        }
        catch {
            Write-Warning "  ! Group creation failed: $($office.GroupName) - $_"
        }
    }
}

Write-Info ""
Write-Info "=========================================="
Write-Info "Administrative User Creation Instructions"
Write-Info "=========================================="
Write-Info ""
Write-Info "OPTION 1: Create Sample Administrative Users"
Write-Info "Uncomment the function call at the end of this script"
Write-Info ""
Write-Info "OPTION 2: Import from CSV file"
Write-Info "Create a CSV file with columns: LastName, FirstName, MiddleName, Office, Gender"
Write-Info "Then run the CSV import function below"
Write-Info ""

# Function to create sample administrative users
function Create-SampleAdministrativeUsers {
    Write-Info "Creating sample administrative users..."
    
    # Sample administrative staff data
    $sampleUsers = @(
        @{ LastName = "SMITH"; FirstName = "JOHN"; Office = "Registrars-Office"; Gender = "M" },
        @{ LastName = "GARCIA"; FirstName = "MARIA"; Office = "Registrars-Office"; Gender = "F" },
        @{ LastName = "SANTOS"; FirstName = "CARLOS"; Office = "Directors-Office"; Gender = "M" },
        @{ LastName = "REYES"; FirstName = "ISABEL"; Office = "Directors-Office"; Gender = "F" },
        @{ LastName = "RIVERA"; FirstName = "JUAN"; Office = "Research-Extension"; Gender = "M" },
        @{ LastName = "TORRES"; FirstName = "LUNA"; Office = "Research-Extension"; Gender = "F" },
        @{ LastName = "TORRES"; FirstName = "MARK"; Office = "HR-Management-Office"; Gender = "M" },
        @{ LastName = "FERNANDEZ"; FirstName = "ROSA"; Office = "HR-Management-Office"; Gender = "F" },
        @{ LastName = "GONZALES"; FirstName = "ANTONIO"; Office = "Finance-Office"; Gender = "M" },
        @{ LastName = "Lopez"; FirstName = "ANNA"; Office = "Finance-Office"; Gender = "F" },
        @{ LastName = "MARTINEZ"; FirstName = "JOSE"; Office = "Supply-Procurement"; Gender = "M" },
        @{ LastName = "HERNANDEZ"; FirstName = "MONICA"; Office = "Supply-Procurement"; Gender = "F" },
        @{ LastName = "CRUZ"; FirstName = "RAFAEL"; Office = "Records-Office"; Gender = "M" },
        @{ LastName = "NAVARRO"; FirstName = "CLARA"; Office = "Records-Office"; Gender = "F" },
        @{ LastName = "VELASCO"; FirstName = "DANIEL"; Office = "Library-Services"; Gender = "M" },
        @{ LastName = "MORALES"; FirstName = "SOFIA"; Office = "Library-Services"; Gender = "F" }
    )
    
    $usersCreated = 0
    $usersFailed = 0
    
    foreach ($user in $sampleUsers) {
        $office = $adminOffices | Where-Object { $_.OfficeName -eq $user.Office }
        
        $fullName = "$($user.FirstName) $($user.LastName)"
        $samAccountName = "$($user.FirstName.Substring(0,1)).$($user.LastName)".ToLower() -replace '[^a-z0-9._-]', ''
        $userPrincipalName = "$samAccountName@$Domain"
        
        # Check for duplicate username
        $counter = 1
        $originalSam = $samAccountName
        while (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue) {
            $samAccountName = "$originalSam$counter"
            $counter++
        }
        
        try {
            New-ADUser `
                -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -Name $fullName `
                -GivenName $user.FirstName `
                -Surname $user.LastName `
                -DisplayName $fullName `
                -Path $office.OUPath `
                -AccountPassword $SecurePassword `
                -Enabled $true `
                -PasswordNotRequired $false `
                -CannotChangePassword $false
            
            # Add to office group
            Add-ADGroupMember -Identity $office.GroupName -Members $samAccountName -ErrorAction SilentlyContinue
            
            Write-Success "  ✓ Created: $fullName ($samAccountName) [$($user.Gender)]"
            $usersCreated++
        }
        catch {
            Write-Error-Log "  ! Failed to create user $fullName - $_"
            $usersFailed++
        }
    }
    
    Write-Info ""
    Write-Info "Sample Users Summary:"
    Write-Info "  Total Created: $usersCreated"
    Write-Info "  Failed: $usersFailed"
}

# Function to import users from CSV file
function Import-AdministrativeUsersFromCSV {
    param(
        [string]$CSVPath
    )
    
    if (-not (Test-Path $CSVPath)) {
        Write-Warning "CSV file not found: $CSVPath"
        return
    }
    
    Write-Info "Importing users from CSV: $CSVPath"
    
    $csvUsers = Import-Csv -Path $CSVPath
    $usersCreated = 0
    $usersFailed = 0
    
    foreach ($user in $csvUsers) {
        $office = $adminOffices | Where-Object { $_.OfficeName -eq $user.Office }
        
        if (-not $office) {
            Write-Warning "  ! Office not found: $($user.Office)"
            continue
        }
        
        $fullName = "$($user.FirstName) $($user.LastName)"
        $samAccountName = "$($user.FirstName.Substring(0,1)).$($user.LastName)".ToLower() -replace '[^a-z0-9._-]', ''
        $userPrincipalName = "$samAccountName@$Domain"
        
        # Check for duplicate username
        $counter = 1
        $originalSam = $samAccountName
        while (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue) {
            $samAccountName = "$originalSam$counter"
            $counter++
        }
        
        try {
            New-ADUser `
                -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -Name $fullName `
                -GivenName $user.FirstName `
                -Surname $user.LastName `
                -DisplayName $fullName `
                -Path $office.OUPath `
                -AccountPassword $SecurePassword `
                -Enabled $true
            
            Add-ADGroupMember -Identity $office.GroupName -Members $samAccountName -ErrorAction SilentlyContinue
            
            Write-Success "  ✓ Created: $fullName"
            $usersCreated++
        }
        catch {
            Write-Error-Log "  ! Failed to create: $fullName - $_"
            $usersFailed++
        }
    }
    
    Write-Info "CSV Import Summary:"
    Write-Info "  Total Created: $usersCreated"
    Write-Info "  Failed: $usersFailed"
}

Write-Info ""
Write-Info "=========================================="
Write-Info "CREATING SAMPLE ADMINISTRATIVE USERS"
Write-Info "=========================================="
Write-Info ""

# Uncomment the line below to create sample users
Create-SampleAdministrativeUsers

Write-Info ""
Write-Info "=========================================="
Write-Success "✓ Administrative infrastructure created!"
Write-Info "=========================================="
Write-Info ""
Write-Info "To import additional users from CSV, use:"
Write-Info "  Import-AdministrativeUsersFromCSV -CSVPath 'path\to\adminusers.csv'"
Write-Info ""
Write-Info "CSV Format Required:"
Write-Info "  LastName,FirstName,MiddleName,Office,Gender"
Write-Info "  SMITH,JOHN,PAUL,Registrars-Office,M"
Write-Info ""
Write-Info "Log file: $LogFile"
