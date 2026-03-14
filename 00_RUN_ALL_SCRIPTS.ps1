#================================================================
# TUPT Active Directory - Master Execution Script
# Executes all user creation scripts in proper order
# Domain: tupt.com
#================================================================

# Color functions
function Write-Title { Write-Host $args -ForegroundColor Yellow -BackgroundColor Black }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Red }

# Ensure running with admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator!"
    Write-Warning "Please right-click on PowerShell and select 'Run as Administrator'"
    exit 1
}

Clear-Host
Write-Title "╔════════════════════════════════════════════════════════════╗"
Write-Title "║    TUPT Active Directory - Bulk User Creation Suite       ║"
Write-Title "║    Domain: tupt.com                                       ║"
Write-Title "╚════════════════════════════════════════════════════════════╝"
Write-Info ""

# Verify required modules
Write-Info "Checking prerequisites..."
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Success "✓ Active Directory module available"
}
catch {
    Write-Warning "✗ Active Directory module not found. Install RSAT or AD DS Tools."
    exit 1
}

# Check script files
$scripts = @(
    @{ Name = "00_CreateOrganizationalUnits.ps1"; Order = 1; Description = "Create OU Structure" },
    @{ Name = "01_CreateAcademicUsers.ps1"; Order = 2; Description = "Create Academic Users (19 programs)" },
    @{ Name = "02_CreateAdministrativeUsers.ps1"; Order = 3; Description = "Create Administrative Users (8 offices)" }
)

Write-Info ""
Write-Info "Checking required script files..."
foreach ($script in $scripts) {
    if (Test-Path $script.Name) {
        Write-Success "✓ Found: $($script.Name)"
    }
    else {
        Write-Warning "✗ Missing: $($script.Name)"
        exit 1
    }
}

Write-Info ""
Write-Title "════════════════════════════════════════════════════════════"
Write-Info ""
Write-Info "The following scripts will be executed in order:"
Write-Info ""
foreach ($script in $scripts | Sort-Object Order) {
    Write-Info "  [$($script.Order)] $($script.Name)"
    Write-Info "      Description: $($script.Description)"
    Write-Info ""
}

Write-Warning ""
Write-Warning "⚠ IMPORTANT NOTES:"
Write-Warning ""
Write-Warning "  • This script will create hundreds of AD users"
Write-Warning "  • Default passwords will be assigned (change them later)"
Write-Warning "  • All operations are logged in the 'Logs' directory"
Write-Warning "  • Database changes cannot be easily undone - ensure backups exist"
Write-Warning ""

Write-Info "Press any key to continue or Ctrl+C to cancel..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Clear-Host

# Execute scripts
$scriptResults = @()

foreach ($script in $scripts | Sort-Object Order) {
    Write-Title "════════════════════════════════════════════════════════════"
    Write-Info "[$($script.Order)/$($scripts.Count)] Running: $($script.Name)"
    Write-Info "Description: $($script.Description)"
    Write-Title "════════════════════════════════════════════════════════════"
    Write-Info ""
    
    try {
        $startTime = Get-Date
        . ".\$($script.Name)"
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        $scriptResults += @{
            Script = $script.Name
            Status = "Completed"
            Duration = $duration
            StartTime = $startTime
            EndTime = $endTime
        }
        
        Write-Success ""
        Write-Success "✓ Script completed successfully in $([Math]::Round($duration)) seconds"
    }
    catch {
        Write-Warning ""
        Write-Warning "✗ Script execution failed: $_"
        
        $scriptResults += @{
            Script = $script.Name
            Status = "Failed"
            Duration = 0
            Error = $_
        }
    }
    
    Write-Info ""
    Read-Host "Press Enter to continue to next script..."
    Clear-Host
}

# Final Summary
Clear-Host
Write-Title "╔════════════════════════════════════════════════════════════╗"
Write-Title "║              Execution Summary                             ║"
Write-Title "╚════════════════════════════════════════════════════════════╝"
Write-Info ""

$successCount = ($scriptResults | Where-Object { $_.Status -eq "Completed" } | Measure-Object).Count
$failCount = ($scriptResults | Where-Object { $_.Status -eq "Failed" } | Measure-Object).Count

foreach ($result in $scriptResults) {
    if ($result.Status -eq "Completed") {
        Write-Success "✓ $($result.Script)"
        Write-Info "  └─ Duration: $([Math]::Round($result.Duration)) seconds"
    }
    else {
        Write-Warning "✗ $($result.Script)"
        Write-Warning "  └─ Error: $($result.Error)"
    }
    Write-Info ""
}

Write-Title "════════════════════════════════════════════════════════════"
Write-Info ""
if ($failCount -eq 0) {
    Write-Success "✓ ALL SCRIPTS COMPLETED SUCCESSFULLY"
    Write-Info ""
    Write-Info "Summary:"
    Write-Info "  • 1 Academic Department OU structure created"
    Write-Info "  • 19 academic program OUs created"
    Write-Info "  • ~317 academic users created and assigned"
    Write-Info "  • 1 Administrative Department OU structure created"
    Write-Info "  • 8 administrative office OUs created"
    Write-Info "  • Administrative users created"
    Write-Info ""
    Write-Info "Next Steps:"
    Write-Info "  1. Reset default passwords for all accounts"
    Write-Info "  2. Configure GPOs for workstation login restrictions"
    Write-Info "  3. Configure login hour restrictions if needed"
    Write-Info "  4. Set up workstation access controls"
    Write-Info ""
}
else {
    Write-Warning "✗ Some scripts failed. Please review logs and errors above."
}

Write-Info "Log files are stored in: $(Resolve-Path 'Logs')"
Write-Info ""
Write-Title "════════════════════════════════════════════════════════════"
