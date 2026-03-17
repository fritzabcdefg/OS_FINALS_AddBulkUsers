#================================================================
# TUPT Active Directory - Create Organizational Unit Structure
# Domain: tupt.edu.ph
# Author: System Administrator
# Date: 2026
#================================================================

Import-Module ActiveDirectory

# Domain Configuration
$Domain = "tupt.edu.ph"
$DC1 = "DC=tupt,DC=edu,DC=ph"

# Color-coded output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }

Write-Info "================================================"
Write-Info "Creating TUPT Active Directory Structure"
Write-Info "Domain: $Domain"
Write-Info "================================================"
Write-Info ""

# Create root OUs
$rootOUs = @(
    @{ Name = "Academic"; Path = $DC1 },
    @{ Name = "Administrative"; Path = $DC1 },
    @{ Name = "Workstations"; Path = $DC1 }
)

foreach ($ouObj in $rootOUs) {
    $ouExists = Get-ADOrganizationalUnit -Filter "Name -eq '$($ouObj.Name)' -and DistinguishedName -eq 'OU=$($ouObj.Name),$($ouObj.Path)'" -ErrorAction SilentlyContinue
    if (-not $ouExists) {
        try {
            New-ADOrganizationalUnit -Name $ouObj.Name -Path $ouObj.Path
            Write-Success "✓ Created OU: $($ouObj.Name)"
        }
        catch {
            Write-Warning "! OU may already exist: $($ouObj.Name)"
        }
    }
}

Write-Info ""
Write-Info "Creating Academic Department OUs..."
Write-Info ""

# Academic Departments Structure
$academicDepartments = @(
    @{
        Name = "Basic-Art-Sciences";
        DisplayName = "Basic Art and Sciences Department";
        Path = "OU=Academic,$DC1";
        Programs = @(
            "BTVTE-Electrical",
            "BTVTE-Electronics", 
            "BTVTE-Computer-Hardware",
            "BTVTE-Computer-Software"
        )
    },
    @{
        Name = "Electrical-Allied";
        DisplayName = "Electrical and Allied Department";
        Path = "OU=Academic,$DC1";
        Programs = @(
            "Information-Technology",
            "Electrical-Engineering",
            "Electronics-Engineering",
            "Instrumentation-Control-Tech",
            "BET-Mechatronics"
        )
    },
    @{
        Name = "Mechanical-Allied";
        DisplayName = "Mechanical and Allied Department";
        Path = "OU=Academic,$DC1";
        Programs = @(
            "Mechanical-Engineering-Tech",
            "RAC-Engineering-Tech",
            "Non-Destructive-Engineering-Tech",
            "Electromechanical-Engineering-Tech",
            "Automotive-Engineering-Tech",
            "BET-ElectroMechanical"
        )
    },
    @{
        Name = "Civil-Allied";
        DisplayName = "Civil and Allied Department";
        Path = "OU=Academic,$DC1";
        Programs = @(
            "Civil-Engineering",
            "Civil-Engineering-Tech",
            "Environmental-Science",
            "Chemical-Engineering-Tech"
        )
    }
)

foreach ($dept in $academicDepartments) {
    $deptPath = "OU=$($dept.Name),OU=Academic,$DC1"
    $deptExists = Get-ADOrganizationalUnit -Filter "Name -eq '$($dept.Name)'" -ErrorAction SilentlyContinue
    
    if (-not $deptExists) {
        try {
            New-ADOrganizationalUnit -Name $dept.Name -Path $dept.Path
            Write-Success "  ✓ Created Department: $($dept.DisplayName)"
        }
        catch {
            Write-Warning "  ! Department may already exist: $($dept.Name)"
        }
    }
    
    # Create Program OUs under each Department
    foreach ($program in $dept.Programs) {
        $progExists = Get-ADOrganizationalUnit -Filter "Name -eq '$program' -and DistinguishedName -eq 'OU=$program,$deptPath'" -ErrorAction SilentlyContinue
        
        if (-not $progExists) {
            try {
                New-ADOrganizationalUnit -Name $program -Path $deptPath
                Write-Success "      ✓ Created Program: $program"
            }
            catch {
                Write-Warning "      ! Program may already exist: $program"
            }
        }
    }
}

Write-Info ""
Write-Info "Creating Administrative Department OUs..."
Write-Info ""

# Administrative Department Structure
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

$adminPath = "OU=Administrative,$DC1"

foreach ($office in $adminOffices) {
    $officeExists = Get-ADOrganizationalUnit -Filter "Name -eq '$office'" -ErrorAction SilentlyContinue
    
    if (-not $officeExists) {
        try {
            New-ADOrganizationalUnit -Name $office -Path $adminPath
            Write-Success "  ✓ Created Office: $office"
        }
        catch {
            Write-Warning "  ! Office may already exist: $office"
        }
    }
}

Write-Info ""
Write-Info "Creating Security Groups..."
Write-Info ""

# Create parent groups
$groupPath = "OU=Academic,$DC1"
$groups = @(
    @{ Name = "TUPT-Faculty"; Description = "All faculty members"; GroupScope = "Global"; GroupCategory = "Security" },
    @{ Name = "TUPT-Staff"; Description = "All staff members"; GroupScope = "Global"; GroupCategory = "Security" },
    @{ Name = "TUPT-All-Users"; Description = "All domain users"; GroupScope = "Global"; GroupCategory = "Security" }
)

foreach ($group in $groups) {
    $groupExists = Get-ADGroup -Filter "Name -eq '$($group.Name)'" -ErrorAction SilentlyContinue
    
    if (-not $groupExists) {
        try {
            New-ADGroup -Name $group.Name -GroupCategory $group.GroupCategory -GroupScope $group.GroupScope -Path $groupPath -Description $group.Description
            Write-Success "  ✓ Created Group: $($group.Name)"
        }
        catch {
            Write-Warning "  ! Group may already exist: $($group.Name)"
        }
    }
}

Write-Info ""
Write-Info "================================================"
Write-Success "✓ Organizational Unit Structure Created Successfully!"
Write-Info "================================================"
Write-Info ""
Write-Info "Next Steps:"
Write-Info "  1. Run: 01_CreateAcademicUsers.ps1 (Creates academic users)"
Write-Info "  2. Run: 02_CreateAdministrativeUsers.ps1 (Creates admin users)"
Write-Info ""
