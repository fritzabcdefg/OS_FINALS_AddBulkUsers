#================================================================
# TUPT Active Directory - Create Academic Department Users
# Domain: tupt.edu.ph
# Distributes 317 IT students equally across 19 academic programs
#================================================================

Import-Module ActiveDirectory

# Ensure the script runs from its own folder (so relative paths work)
Set-Location -Path (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)

# Configuration
$Domain = "tupt.edu.ph"
$DefaultPassword = "TuptStudent@2024"
$SecurePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force
$StudentsFile = "Reference Data\ALL_STUDENTS.txt"
$LogFile = "Logs\AcademicUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Ensure log directory exists
if (-not (Test-Path "Logs")) {
    New-Item -ItemType Directory -Path "Logs" | Out-Null
}

function Write-Success { Write-Host $args -ForegroundColor Green; Add-Content $LogFile "SUCCESS: $args" }
function Write-Error-Log { Write-Host $args -ForegroundColor Red; Add-Content $LogFile "ERROR: $args" }
function Write-Info { Write-Host $args -ForegroundColor Cyan; Add-Content $LogFile "INFO: $args" }
function Write-Warning { Write-Host $args -ForegroundColor Yellow; Add-Content $LogFile "WARNING: $args" }

Write-Info "=========================================="
Write-Info "Creating Academic Department Users"
Write-Info "Domain: $Domain"
Write-Info "=========================================="

# Academic Departments and Programs Structure
$academicPrograms = @(
    # Basic Art and Sciences Department
    @{ 
        Dept = "Basic-Art-Sciences"; 
        Program = "BTVTE-Electrical"; 
        OUPath = "OU=BTVTE-Electrical,OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BTVTE-Electrical-Users"
    },
    @{ 
        Dept = "Basic-Art-Sciences"; 
        Program = "BTVTE-Electronics"; 
        OUPath = "OU=BTVTE-Electronics,OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BTVTE-Electronics-Users"
    },
    @{ 
        Dept = "Basic-Art-Sciences"; 
        Program = "BTVTE-Computer-Hardware"; 
        OUPath = "OU=BTVTE-Computer-Hardware,OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BTVTE-Computer-Hardware-Users"
    },
    @{ 
        Dept = "Basic-Art-Sciences"; 
        Program = "BTVTE-Computer-Software"; 
        OUPath = "OU=BTVTE-Computer-Software,OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BTVTE-Computer-Software-Users"
    },
    
    # Electrical and Allied Department
    @{ 
        Dept = "Electrical-Allied"; 
        Program = "Information-Technology"; 
        OUPath = "OU=Information-Technology,OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "IT-Users"
    },
    @{ 
        Dept = "Electrical-Allied"; 
        Program = "Electrical-Engineering"; 
        OUPath = "OU=Electrical-Engineering,OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Electrical-Engineering-Users"
    },
    @{ 
        Dept = "Electrical-Allied"; 
        Program = "Electronics-Engineering"; 
        OUPath = "OU=Electronics-Engineering,OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Electronics-Engineering-Users"
    },
    @{ 
        Dept = "Electrical-Allied"; 
        Program = "Instrumentation-Control-Tech"; 
        OUPath = "OU=Instrumentation-Control-Tech,OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Instrumentation-Control-Users"
    },
    @{ 
        Dept = "Electrical-Allied"; 
        Program = "BET-Mechatronics"; 
        OUPath = "OU=BET-Mechatronics,OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BET-Mechatronics-Users"
    },
    
    # Mechanical and Allied Department
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "Mechanical-Engineering-Tech"; 
        OUPath = "OU=Mechanical-Engineering-Tech,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Mechanical-Engineering-Users"
    },
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "RAC-Engineering-Tech"; 
        OUPath = "OU=RAC-Engineering-Tech,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "RAC-Engineering-Users"
    },
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "Non-Destructive-Engineering-Tech"; 
        OUPath = "OU=Non-Destructive-Engineering-Tech,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Non-Destructive-Engineering-Users"
    },
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "Electromechanical-Engineering-Tech"; 
        OUPath = "OU=Electromechanical-Engineering-Tech,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Electromechanical-Engineering-Users"
    },
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "Automotive-Engineering-Tech"; 
        OUPath = "OU=Automotive-Engineering-Tech,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Automotive-Engineering-Users"
    },
    @{ 
        Dept = "Mechanical-Allied"; 
        Program = "BET-ElectroMechanical"; 
        OUPath = "OU=BET-ElectroMechanical,OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "BET-ElectroMechanical-Users"
    },
    
    # Civil and Allied Department
    @{ 
        Dept = "Civil-Allied"; 
        Program = "Civil-Engineering"; 
        OUPath = "OU=Civil-Engineering,OU=Civil-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Civil-Engineering-Users"
    },
    @{ 
        Dept = "Civil-Allied"; 
        Program = "Civil-Engineering-Tech"; 
        OUPath = "OU=Civil-Engineering-Tech,OU=Civil-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Civil-Engineering-Tech-Users"
    },
    @{ 
        Dept = "Civil-Allied"; 
        Program = "Environmental-Science"; 
        OUPath = "OU=Environmental-Science,OU=Civil-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Environmental-Science-Users"
    },
    @{ 
        Dept = "Civil-Allied"; 
        Program = "Chemical-Engineering-Tech"; 
        OUPath = "OU=Chemical-Engineering-Tech,OU=Civil-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph"; 
        GroupName = "Chemical-Engineering-Tech-Users"
    }
)

Write-Info ""
Write-Info "Loading students from: $StudentsFile"

# Read and parse student file
$allLines = @(Get-Content $StudentsFile)
$students = @()

foreach ($line in $allLines) {
    if ($line.Trim() -ne "") {
        $students += $line.Trim()
    }
}

Write-Info "Total students loaded: $($students.Count)"
Write-Info "Total academic programs: $($academicPrograms.Count)"
Write-Info ""

# Split students: first 250 for academic programs, remaining for administrative offices
$academicStudentCount = 250
if ($students.Count -gt $academicStudentCount) {
    $adminStudents = @($students[$academicStudentCount..($students.Count - 1)])
    $students = @($students[0..($academicStudentCount - 1)])
    Write-Info "Splitting students:"
    Write-Info "  Academic: $($students.Count) students"
    Write-Info "  Administrative: $($adminStudents.Count) students"
    
    # Save admin students to file for 02_CreateAdministrativeUsers.ps1
    $adminStudentsFile = "Reference Data\ADMIN_STUDENTS.txt"
    $adminStudents | Out-File -FilePath $adminStudentsFile -Encoding UTF8
    Write-Info "  Saved admin students to: $adminStudentsFile"
}
else {
    Write-Warning "Total students ($($students.Count)) is less than or equal to $academicStudentCount."
    Write-Warning "All students will be assigned to academic programs."
}
Write-Info ""

if ($students.Count -le $reservedForAdmins) {
    Write-Warning "Not enough students to reserve $reservedForAdmins for administrators; reserving 0."
    $reservedForAdmins = 0
}

$adminStudentsFile = "Reference Data\ADMIN_STUDENTS.txt"

if ($reservedForAdmins -gt 0) {
    $adminStudents = $students[-$reservedForAdmins..-1]
    $students = $students[0..($students.Count - $reservedForAdmins - 1)]
    $adminStudents | Set-Content -Path $adminStudentsFile -Encoding UTF8
    Write-Info "Reserved $reservedForAdmins students for administrative accounts (written to $adminStudentsFile)"
} else {
    Remove-Item -Path $adminStudentsFile -ErrorAction SilentlyContinue
}

# Calculate students per program
$studentsPerProgram = [Math]::Ceiling($students.Count / $academicPrograms.Count)
Write-Info "Distributing approximately $studentsPerProgram students per program"
Write-Info ""

# Create security groups for each program
Write-Info "Creating security groups..."
foreach ($prog in $academicPrograms) {
    $groupExists = Get-ADGroup -Filter "Name -eq '$($prog.GroupName)'" -ErrorAction SilentlyContinue
    if (-not $groupExists) {
        try {
            New-ADGroup -Name $prog.GroupName -GroupCategory Security -GroupScope Global -Path "OU=Academic,DC=tupt,DC=edu,DC=ph" -Description "Users for $($prog.Program)"
            Write-Success "  Created group: $($prog.GroupName)"
        }
        catch {
            Write-Warning "  ! Group creation failed: $($prog.GroupName) - $_"
        }
    }
}

Write-Info ""
Write-Info "Creating users and assigning to programs..."
Write-Info "=============================================="
Write-Info ""

# Distribute students to programs
$studentIndex = 0
$usersCreated = 0
$usersFailed = 0

for ($progIndex = 0; $progIndex -lt $academicPrograms.Count; $progIndex++) {
    $program = $academicPrograms[$progIndex]
    $count = 0
    $maxStudents = $studentsPerProgram
    
    # Distribute remaining students more evenly
    $remainingPrograms = $academicPrograms.Count - $progIndex
    $remainingStudents = $students.Count - $studentIndex
    if ($remainingStudents -gt 0) {
        $maxStudents = [Math]::Ceiling($remainingStudents / $remainingPrograms)
    }
    
    Write-Info "Program: $($program.Program)"
    
    while ($count -lt $maxStudents -and $studentIndex -lt $students.Count) {
        $studentLine = $students[$studentIndex]
        $studentIndex++
        
        # Parse student line: LastName(s), FirstName(s) MiddleName(s), Gender
        $parts = $studentLine -split ','
        if ($parts.Count -lt 3) {
            Write-Warning "  ! Skipping malformed line: $studentLine"
            continue
        }
        
        $lastName = $parts[0].Trim()
        $fullName = $parts[1].Trim()
        $gender = $parts[2].Trim()
        
        # Extract first name only for username
        $firstNameArray = $fullName -split ' '
        $firstName = $firstNameArray[0]
        
        # Create UPN and SAM Account Name
        $samAccountName = "$firstName.$lastName".ToLower() -replace '[^a-z0-9._-]', ''
        $userPrincipalName = "$samAccountName@$Domain"
        
        # Check for duplicate username
        $counter = 1
        $originalSam = $samAccountName
        while (Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue) {
            $samAccountName = "$originalSam$counter"
            $counter++
        }
        
        try {
            # Create user
            New-ADUser `
                -SamAccountName $samAccountName `
                -UserPrincipalName $userPrincipalName `
                -Name $fullName `
                -GivenName $firstName `
                -Surname $lastName `
                -DisplayName $fullName `
                -Path $program.OUPath `
                -AccountPassword $SecurePassword `
                -Enabled $true `
                -PasswordNotRequired $false `
                -CannotChangePassword $false
            
            # Add user to program group
            Add-ADGroupMember -Identity $program.GroupName -Members $samAccountName -ErrorAction SilentlyContinue
            
            Write-Success "  Created: $fullName ($samAccountName) [$gender]"
            $usersCreated++
        }
        catch {
            Write-Error-Log "  ! Failed to create user $fullName - $_"
            $usersFailed++
        }
        
        $count++
    }
    
    Write-Info "  - Assigned $count students to this program"
    Write-Info ""
}

Write-Info "=============================================="
Write-Info "Summary:"
Write-Info "  Total Users Created: $usersCreated"
Write-Info "  Failed: $usersFailed"
Write-Info "  Log file: $LogFile"
Write-Info "=============================================="
Write-Info ""
Write-Success "Academic users created successfully!"
