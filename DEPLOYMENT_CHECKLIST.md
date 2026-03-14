# TUPT Active Directory - Deployment Checklist
## Complete Implementation Guide

---

## 📋 Pre-Deployment Checklist

### Infrastructure Verification
- [ ] Windows Server 2008 (or 2008 R2) is installed and running
- [ ] Active Directory is installed and domain "tupt.com" exists
- [ ] Domain Controllers are online and replicating
- [ ] Network connectivity verified to all DCs
- [ ] Adequate disk space available on DC (~500 MB minimum)

### Software Requirements
- [ ] PowerShell 2.0 or higher installed
- [ ] Active Directory Module for PowerShell available
  ```powershell
  # Check with:
  Import-Module ActiveDirectory
  ```
- [ ] RSAT (Remote Server Administration Tools) installed if remote administration
  ```powershell
  # Install if needed (Windows Server 2008):
  Add-WindowsFeature RSAT-AD-Tools
  ```

### Account Permissions
- [ ] Current user is Domain Admin or Enterprise Admin
- [ ] Current user has rights to create OUs
- [ ] Current user has rights to create users
- [ ] Current user has rights to create groups

### Data Preparation
- [ ] ALL_STUDENTS.txt contains 317 student names (verified: ✓ 317 lines)
- [ ] Student file format is correct: `LastName, FirstName MiddleNames, Gender`
- [ ] No file encoding issues (UTF-8 recommended)

### Backup & Recovery
- [ ] FULL backup of Active Directory taken
  ```powershell
  # On DC, verify backup:
  wbadmin get versions
  ```
- [ ] System State backup executed
- [ ] Recovery procedure documented and tested
- [ ] Rollback plan reviewed and ready

### Environment & Scheduling
- [ ] Maintenance window scheduled (ideally low-traffic period)
- [ ] All stakeholders notified of the deployment
- [ ] Test lab verification completed (if available)
- [ ] Network monitoring enabled for deployment
- [ ] Help desk staff alerted and on standby

---

## 🚀 Deployment Execution

### Phase 1: Pre-Execution (5 minutes)

- [ ] Close all other applications
- [ ] Open PowerShell as Administrator
  ```powershell
  # Verify admin rights (should not show error):
  [Security.Principal.WindowsPrincipal]::GetCurrent()
  ```
- [ ] Navigate to script directory
  ```powershell
  cd "C:\Users\leoma\OneDrive\Documents\OPERATING SYSTEMS\AddBulkUsers"
  ```
- [ ] Verify all script files exist
  ```powershell
  Get-ChildItem *.ps1
  ```
- [ ] Verify ALL_STUDENTS.txt is readable
  ```powershell
  Get-Content "Reference Data\ALL_STUDENTS.txt" | Measure-Object -Line
  ```

### Phase 2: Execute Master Script (20-30 minutes)

```powershell
# START THE DEPLOYMENT
.\00_RUN_ALL_SCRIPTS.ps1
```

**What the script does automatically:**
1. ✓ Validates prerequisites
2. ✓ Creates root OUs (Academic, Administrative, Workstations)
3. ✓ Creates 4 academic department OUs
4. ✓ Creates 19 academic program OUs
5. ✓ Creates 8 administrative office OUs
6. ✓ Creates security groups for all programs/offices
7. ✓ Creates 317 student users from ALL_STUDENTS.txt
8. ✓ Distributes students equally (~17 per program)
9. ✓ Creates administrative users (16 sample)
10. ✓ Logs all operations

**Do NOT interrupt or close the window during execution.**

### Phase 3: Verification (10 minutes)

```powershell
# Run these commands to verify successful deployment:

# 1. Check total users created
$academicUsers = @(Get-ADUser -Filter "Path -like '*Academic*'").Count
$adminUsers = @(Get-ADUser -Filter "Path -like '*Administrative*'").Count
Write-Host "Academic Users: $academicUsers"
Write-Host "Administrative Users: $adminUsers"
Write-Host "Total Users: $($academicUsers + $adminUsers)"

# Expected: Academic: 317, Administrative: 16, Total: 333

# 2. Check OUs created
$ouCount = @(Get-ADOrganizationalUnit -Filter "Name -like '*' -and Path -like '*Academic*' -or Path -like '*Administrative*'").Count
Write-Host "OUs Created: $ouCount"
# Expected: 27 (19 academic program OUs + 8 administrative office OUs + 2 parent OUs)

# 3. Check security groups
$groupCount = @(Get-ADGroup -Filter "GroupCategory -eq 'Security' -and Name -like '*-Users'").Count
Write-Host "Security Groups Created: $groupCount"
# Expected: 27 groups (one per program/office)

# 4. Sample user verification
Get-ADUser -Filter "SamAccountName -eq 'cristine.aurella'" -Properties Mail, DisplayName

# Expected output shows user with correct attributes
```

### Phase 4: Log Review (5 minutes)

```powershell
# Navigate to Logs directory
cd Logs

# Check for errors
Select-String "ERROR" *.log

# If no errors found, deployment is successful
# If errors found, review specific log files
```

---

## 🔐 Post-Deployment: Password Management (Immediate)

### URGENT: Reset Default Passwords

**Default Test Passwords (DO NOT USE IN PRODUCTION):**
- Academic: `TuptStudent@2024`
- Administrative: `TuptAdmin@2024`

### Option 1: Force Password Change on Next Logon (✓ RECOMMENDED)

```powershell
# For ALL academic users
Get-ADUser -Filter "Path -like '*,OU=Basic-Art-Sciences*' -or Path -like '*,OU=Electrical-Allied*' -or Path -like '*,OU=Mechanical-Allied*' -or Path -like '*,OU=Civil-Allied*'" | Set-ADUser -ChangePasswordAtLogon $true

# For ALL administrative users
Get-ADUser -Filter "Path -like '*,OU=HR-Management-Office*' -or Path -like '*,OU=Directors-Office*' -or Path -like '*,OU=Registrars-Office*' -or Path -like '*,OU=Finance-Office*' -or Path -like '*,OU=Supply-Procurement*' -or Path -like '*,OU=Research-Extension*' -or Path -like '*,OU=Records-Office*' -or Path -like '*,OU=Library-Services*'" | Set-ADUser -ChangePasswordAtLogon $true

# Verify the setting was applied
Get-ADUser -Filter "Path -like '*Academic*'" -Properties PasswordExpired | Select Name, PasswordExpired | Head
```

### Option 2: Implement Group Policy Password Policy

**Location:** 
```
Group Policy Editor → Computer Configuration → Policies → 
Windows Settings → Security Settings → Account Policies → 
Password Policy
```

**Minimum Requirements:**
- Minimum password length: 8 characters
- Password must meet complexity requirements
- Maximum password age: 90 days
- Password history: 16 passwords remembered

### Option 3: Set Initial Passwords via GPO (Domain-wide)

```powershell
# Create Group Policy for password change notification
New-GPO -Name "Password-Change-Notification" | Set-GPLink -Target "DC=tupt,DC=com" -LinkEnabled Yes
```

---

## 👤 User Activation (Per User/Group)

### Academic Users Activation

```powershell
# 1. All accounts are created as ENABLED=true (good!)
# 2. Verify accounts are active
Get-ADUser -Filter "Path -like '*Academic*'" -Properties Enabled | Select Name, Enabled | Head -10

# 3. Test login on a student workstation with format:
#    Username: firstname.lastname (e.g., john.smith)
#    Password: [What they set via change on next logon]

# 4. If any account needs to be disabled:
Disable-ADAccount -Identity "john.smith"

# 5. If any account needs to be enabled:
Enable-ADAccount -Identity "john.smith"
```

### Administrative Users Activation

```powershell
# Same as above, but for Administrative path
Get-ADUser -Filter "Path -like '*Administrative*'" | Enable-ADAccount
```

---

## 🖥️ Workstation Restriction Setup (Next 24 Hours)

### Requirement
**"All users can only log on to workstations (XP Class A network, 7 Class B network)"**

### Implementation: Create Workstation OUs and Groups

```powershell
# Create Workstation OUs
New-ADOrganizationalUnit -Name "XP-Class-A" -Path "OU=Workstations,DC=tupt,DC=com"
New-ADOrganizationalUnit -Name "Class-B-Network" -Path "OU=Workstations,DC=tupt,DC=com"

# Create computer groups
New-ADGroup -Name "XP-Class-A-Computers" -GroupCategory Security -GroupScope Global -Path "OU=XP-Class-A,OU=Workstations,DC=tupt,DC=com"
New-ADGroup -Name "Class-B-Computers" -GroupCategory Security -GroupScope Global -Path "OU=Class-B-Network,OU=Workstations,DC=tupt,DC=com"

# Add workstations to their respective groups
# Example: Move XP-WORKSTATION-01 to XP-Class-A and add to group
```

### Implementation: Group Policy - Logon Restrictions

**For Academic Users (XP Class A Network):**

```
Name: Academic-XP-Workstation-Logon
Scope: OU=Academic,DC=tupt,DC=com

Computer Configuration > Policies > Windows Settings > 
Security Settings > Local Policies > User Rights Assignment

    Logon locally: [Add XP Class A Computers group or specific workstations]
```

**For Administrative Users (Class B Network):**

```
Name: Administrative-Class-B-Logon
Scope: OU=Administrative,DC=tupt,DC=com

Computer Configuration > Policies > Windows Settings > 
Security Settings > Local Policies > User Rights Assignment

    Logon locally: [Add Class B Network Computers group or specific workstations]
```

### Alternative: PowerShell Assignment (Per User)

```powershell
# Example: Restrict john.smith to specific workstations
Set-ADUser -Identity "john.smith" -LogonWorkstations "XP-WS-01;XP-WS-02;XP-WS-03"

# Verify setting
Get-ADUser -Identity "john.smith" -Properties LogonWorkstations | Select LogonWorkstations
```

---

## 📞 Day 1-3 Post-Deployment Tasks

### Day 1: User Acceptance Testing

- [ ] Select 5 sample academic users and test login
- [ ] Verify users exist in correct OUs
- [ ] Test group membership (check shared folder access)
- [ ] Verify password change on next logon works
- [ ] Check AD replication to all DCs

```powershell
# Replication check
Get-ADReplicationPartnerMetadata -Target * | Select Server,NumConsecutiveFailures | Where {$_.NumConsecutiveFailures -gt 0}
# Should show 0 failures
```

### Day 1: Communication

- [ ] Notify IT department of user creation status
- [ ] Provide credentials securely to students/staff (separate task)
- [ ] Alert help desk about expected password change requests
- [ ] Document any issues encountered

### Day 2: Security Implementation

- [ ] Implement workstation logon restrictions via GPO
- [ ] Configure login hours if needed
- [ ] Setup account lockout policies
- [ ] Configure password complexity requirements
- [ ] Enable audit logging for user logons

```powershell
# Enable logon audit
auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable
```

### Day 3: Documentation & Training

- [ ] Generate complete user/group list (export to CSV)
- [ ] Create quick reference for IT staff
- [ ] Update Active Directory documentation
- [ ] Train help desk on password reset procedures
- [ ] Schedule regular AD health checks

---

## 🔍 Quality Assurance Verification

### User Distribution Verification

```powershell
# Verify students are evenly distributed across programs
$programs = @(
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

foreach ($prog in $programs) {
    $count = @(Get-ADUser -Filter "DistinguishedName -like '*OU=$prog*'").Count
    Write-Host "$prog`: $count users"
}
# Expected: Each program should have approximately 16-17 users
```

### Group Membership Verification

```powershell
# Verify all users are in their program groups
$groups = Get-ADGroup -Filter "Name -like '*-Users'"
$usersNotInGroup = 0

foreach ($group in $groups) {
    $members = @(Get-ADGroupMember -Identity $group)
    if ($members.Count -eq 0) {
        Write-Warning "$($group.Name) has NO members!"
        $usersNotInGroup++
    }
}

if ($usersNotInGroup -eq 0) {
    Write-Host "✓ All groups have members successfully assigned"
}
```

### Email/UPN Verification

```powershell
# Verify all users have proper UPN
Get-ADUser -Filter "Path -like '*Academic*'" -Properties UserPrincipalName | 
  Where {$_.UserPrincipalName -notlike "*@tupt.com"} | 
  Measure-Object

# Should return 0 (all users must have @tupt.com UPN)
```

---

## 🆘 Troubleshooting Reference

### If User Creation Failed Partially

```powershell
# Find which users were NOT created (should be none if successful)
$allLines = Get-Content "Reference Data\ALL_STUDENTS.txt"
$createdUsers = Get-ADUser -Filter "Path -like '*Academic*'" -Properties GivenName,Surname

foreach ($line in $allLines) {
    $parts = $line -split ','
    if ($parts.Count -ge 2) {
        $givenName = ($parts[1].Trim() -split ' ')[0]
        $surname = $parts[0].Trim()
        
        $exists = $createdUsers | Where {$_.GivenName -eq $givenName -and $_.Surname -like "*$surname*"}
        if (-not $exists) {
            Write-Warning "NOT FOUND: $line"
        }
    }
}
```

### If OUs Not Created

```powershell
# Manually create missing OUs
New-ADOrganizationalUnit -Name "BTVTE-Electrical" -Path "OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=com"
New-ADOrganizationalUnit -Name "BTVTE-Electronics" -Path "OU=Basic-Art-Sciences,OU=Academic,DC=tupt,DC=com"
# ... etc for each missing OU
```

### If Scripts Won't Run

```powershell
# Check execution policy
Get-ExecutionPolicy
# Should show: RemoteSigned or Unrestricted

# If Restricted, change it
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

---

## 📊 Post-Deployment Report Template

```
DEPLOYMENT REPORT - TUPT Active Directory User Creation
Domain: tupt.com
Date: [Deployment Date]
Time: [Start Time] - [End Time]
Administrator: [Your Name]

SUMMARY:
--------
Total Users Created: _____ (Expected: 333)
Organizational Units Created: _____ (Expected: 27)
Security Groups Created: _____ (Expected: 27)
Total Errors: _____ (Expected: 0)
Total Warnings: _____ (Expected: <5)

ACADEMIC USERS:
- BTVTE-Electrical: _____ (Expected: ~17)
- BTVTE-Electronics: _____ (Expected: ~17)
- ... [continue for all 19 programs]

ADMINISTRATIVE USERS:
- Registrar's Office: _____ (Expected: ~2)
- Director's Office: _____ (Expected: ~2)
- ... [continue for all 8 offices]

ISSUES ENCOUNTERED:
[List any issues]

RESOLUTION:
[How were issues resolved]

VERIFICATION COMPLETED:
- [ ] User counts verified
- [ ] OU structure verified
- [ ] Group memberships verified
- [ ] Sample logins tested
- [ ] All logs reviewed

SIGN-OFF:
Date: _____________
Signature: ________________
```

---

## 📞 Support & Resources

### Internal Resources
- **Script Location:** `C:\Users\leoma\OneDrive\Documents\OPERATING SYSTEMS\AddBulkUsers`
- **Log Files:** `Logs` subfolder
- **Documentation:** README.md (comprehensive), QUICKSTART.md (quick reference)
- **Sample Templates:** administrative_users_template.csv

### Microsoft Resources
- [Active Directory PowerShell Module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)
- [Windows Server 2008 Admin Guide](https://learn.microsoft.com/en-us/windows-server/)
- [Group Policy Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/group-policy/)

### Emergency Contacts
- **AD Admin:** [Your Name/Contact]
- **Domain Administrator:** [Contact Info]
- **IT Manager:** [Contact Info]

---

## ✅ All Done!

Once you've completed this checklist, your TUPT Active Directory deployment is complete with:

✓ 317 academic users distributed across 19 programs  
✓ 16 administrative users in 8 offices  
✓ Proper OU structure for delegation  
✓ Security groups for access management  
✓ Complete logging and audit trails  
✓ Workstation restriction capability  
✓ Group Policy ready for deployment  

**Congratulations on successful deployment!** 🎉
