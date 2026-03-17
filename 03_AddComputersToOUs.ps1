# Script: 03_AddComputersToOUs.ps1
# Purpose: Add Windows XP and Windows 7 computer accounts to each department/office OU (academic and administrative)
# Domain: tupt.edu.ph

# Import Active Directory module
Import-Module ActiveDirectory

# Define OUs for departments and offices with abbreviation mappings
$ouMappings = @{
    # Academic OUs
    "OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=edu,DC=ph" = "BASD"
    "OU=Electrical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph" = "EAAD"
    "OU=Mechanical-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph" = "MAAD"
    "OU=Civil-Allied,OU=Academic,DC=tupt,DC=edu,DC=ph" = "CAAD"
    # Administrative OUs
    "OU=Registrars-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "REG"
    "OU=Directors-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "DIR"
    "OU=Research-Extension,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "RES"
    "OU=HR-Management-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "HR"
    "OU=Finance-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "FIN"
    "OU=Supply-Procurement,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "SUP"
    "OU=Records-Office,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "REC"
    "OU=Library-Services,OU=Administrative,DC=tupt,DC=edu,DC=ph" = "LIB"
}

# Function to add computers to an OU
function Add-ComputersToOU {
    param (
        [string]$OUPath,
        [string]$Prefix
    )
    # Add Windows XP computer
    New-ADComputer -Name "$Prefix-XP" -Path $OUPath -Enabled $true
    # Add Windows 7 computer
    New-ADComputer -Name "$Prefix-7" -Path $OUPath -Enabled $true
}

# Add computers to all OUs
foreach ($ou in $ouMappings.Keys) {
    $prefix = $ouMappings[$ou]
    Add-ComputersToOU -OUPath $ou -Prefix $prefix
}

Write-Host "Computers added to department and office OUs in tupt.edu.ph domain."
