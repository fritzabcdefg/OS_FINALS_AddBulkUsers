#================================================================
# TUPT Active Directory - Delete Organizational Unit Structure
# Domain: tupt.com
# WARNING: This will delete all OUs created by 00_CreateOrganizationalUnits.ps1
#================================================================

Import-Module ActiveDirectory

# Domain Configuration
$Domain = "tupt.com"
$DC1 = "DC=tupt,DC=com"

# Color-coded output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error-Msg { Write-Host $args -ForegroundColor Red }

Write-Warning "============================================================"
Write-Warning "WARNING: This script will DELETE all organizational units!"
Write-Warning "============================================================"
Write-Info ""
Write-Info "The following will be deleted:"
Write-Info "  • Academic Department OUs and all child OUs"
Write-Info "  • Administrative Office OUs"
Write-Info "  • Workstations OU"
Write-Info "  • All users in those OUs"
Write-Info "  • All security groups"
Write-Info ""
Write-Warning "This action CANNOT be undone!"
Write-Info ""
$confirmation = Read-Host "Type 'DELETE' to confirm deletion, or press Enter to cancel"

if ($confirmation -ne "DELETE") {
    Write-Info "Deletion cancelled."
    exit 0
}

Write-Info ""
Write-Info "Starting deletion process..."
Write-Info ""

# Function to delete OU recursively
function Delete-OURecursive {
    param(
        [string]$OUPath
    )
    
    try {
        $ou = Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction SilentlyContinue
        if ($ou) {
            # Get all child OUs
            $childOUs = Get-ADOrganizationalUnit -Filter * -SearchBase $OUPath -SearchScope OneLevel -ErrorAction SilentlyContinue
            
            # Recursively delete child OUs first
            foreach ($childOU in $childOUs) {
                Delete-OURecursive -OUPath $childOU.DistinguishedName
            }
            
            # Get all users in this OU
            $users = Get-ADUser -Filter * -SearchBase $OUPath -SearchScope OneLevel -ErrorAction SilentlyContinue
            foreach ($user in $users) {
                try {
                    Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false
                    Write-Success "  [OK] Deleted user: $($user.Name)"
                }
                catch {
                    Write-Error-Msg "  [FAIL] Failed to delete user $($user.Name): $_"
                }
            }
            
            # Get all groups in this OU
            $groups = Get-ADGroup -Filter * -SearchBase $OUPath -SearchScope OneLevel -ErrorAction SilentlyContinue
            foreach ($group in $groups) {
                try {
                    Remove-ADGroup -Identity $group.DistinguishedName -Confirm:$false
                    Write-Success "  [OK] Deleted group: $($group.Name)"
                }
                catch {
                    Write-Error-Msg "  [FAIL] Failed to delete group $($group.Name): $_"
                }
            }
            
            # Delete the OU itself
            Set-ADOrganizationalUnit -Identity $OUPath -ProtectedFromAccidentalDeletion $false -Confirm:$false
            Remove-ADOrganizationalUnit -Identity $OUPath -Confirm:$false
            Write-Success "[OK] Deleted OU: $($ou.Name)"
        }
    }
    catch {
        Write-Error-Msg "[FAIL] Error deleting OU $OUPath : $_"
    }
}

# Delete Academic OUs
Write-Info "Deleting Academic Department Structure..."
Delete-OURecursive -OUPath "OU=Academic,$DC1"
Write-Info ""

# Delete Administrative OUs
Write-Info "Deleting Administrative Department Structure..."
Delete-OURecursive -OUPath "OU=Administrative,$DC1"
Write-Info ""

# Delete Workstations OU
Write-Info "Deleting Workstations OU..."
Delete-OURecursive -OUPath "OU=Workstations,$DC1"
Write-Info ""

Write-Info "============================================================"
Write-Success "[OK] Organizational unit deletion completed!"
Write-Info "============================================================"
Write-Info ""
