# Script: 05_DeleteCreatedOUs.ps1
# Purpose: Delete all OUs created in 00_CreateOrganizationalUnits.ps1 (departments and offices only)
# Domain: tupt.edu.ph

Import-Module ActiveDirectory

$DC1 = "DC=tupt,DC=edu,DC=ph"

# Academic Departments
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

# Delete Academic Department OUs
foreach ($dept in $academicDepartments) {
    $deptPath = "OU=$dept,OU=Academic,$DC1"
    try {
        Remove-ADOrganizationalUnit -Identity $deptPath -Recursive -Confirm:$false
        Write-Host "Deleted Academic Department OU: $deptPath"
    } catch {
        Write-Warning "Failed to delete Academic Department OU: $deptPath. $_"
    }
}

# Delete Administrative Office OUs
foreach ($office in $adminOffices) {
    $officePath = "OU=$office,OU=Administrative,$DC1"
    try {
        Remove-ADOrganizationalUnit -Identity $officePath -Recursive -Confirm:$false
        Write-Host "Deleted Administrative Office OU: $officePath"
    } catch {
        Write-Warning "Failed to delete Administrative Office OU: $officePath. $_"
    }
}

Write-Host "OU deletion process completed."
