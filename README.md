# TUPT Active Directory - Bulk User Creation Suite
## Windows Server 2008 Configuration Guide

**Domain:** tupt.com  
**Date Created:** 2026  
**Total Students:** 317 (IT Programs)  
**Total Programs:** 19 academic + 8 administrative = 27 units

---

## 📋 Overview

This comprehensive suite automates the creation of domain users and organizational units in Windows Server 2008 Active Directory for TUPT (Technological University of the Philippines). Students from IT programs are distributed equally across 19 academic programs in 4 departments, with separate administrative office structure.

---

## 📁 File Structure

```
AddBulkUsers/
├── 00_RUN_ALL_SCRIPTS.ps1                    [MASTER SCRIPT - Run this first]
├── 00_CreateOrganizationalUnits.ps1          [Creates OU structure]
├── 01_CreateAcademicUsers.ps1                [Creates ~317 academic users]
├── 02_CreateAdministrativeUsers.ps1          [Creates admin users]
│
├── Reference Codes/
│   ├── AddUsersToGenderGroups.ps1
│   ├── CreateUsers_Students.txt
│   └── powershell cmds.txt
│
├── Reference Data/
│   ├── ALL_STUDENTS.txt                      [All 317 IT student names]
│   ├── BSIT-1A-T.txt
│   ├── BSIT-1B-T.txt
│   ├── BSIT-M-and-F.txt
│   ├── BSIT-NS-2A-T.txt
│   ├── BSIT-NS-3A-T.txt
│   ├── BSIT-NS-4A-T.txt
│   ├── BSIT-S-2A-T.txt
│   ├── BSIT-S-3A-T.txt
│   └── BSIT-S-4A-T.txt
│
├── Logs/                                      [Auto-created, contains execution logs]
│   ├── OrganizationalUnits_*.log
│   ├── AcademicUsers_*.log
│   └── AdministrativeUsers_*.log
│
└── README.md                                  [This file]
```

---

## 🏛️ Organizational Structure

### Academic Departments (4 total)

#### 1. **Basic Art and Sciences Department**
- BTVTE Electrical
- BTVTE Electronics
- BTVTE Computer Hardware
- BTVTE Computer Software

#### 2. **Electrical and Allied Department**
- Information Technology
- Electrical Engineering
- Electronics Engineering
- Instrumentation and Control Technology
- BET Mechatronics

#### 3. **Mechanical and Allied Department**
- Mechanical Engineering Technology
- RAC Engineering Technology
- Non-Destructive Engineering Technology
- Electromechanical Engineering Technology
- Automotive Engineering Technology
- BET ElectroMechanical

#### 4. **Civil and Allied Department**
- Civil Engineering
- Civil Engineering Technology
- Environmental Science
- Chemical Engineering Technology

### Administrative Department (8 total)

1. Registrar's Office
2. Director's Office
3. Research and Extension
4. Human Resource and Management Office
5. Finance Office
6. Supply and Procurement
7. Records Office
8. Library Services

---

## 📊 User Distribution

- **Total IT Students:** 317
- **Academic Programs:** 19
- **Students per program:** ~17 (range 16-17)
- **Administrative Personnel:** Sample data (16 users)

**Distribution Calculation:**
```
317 students ÷ 19 programs = 16.68 students/program
Distributed as approximately 16-17 per program
```

---

## 🚀 Quick Start Guide

### Prerequisites

1. **Windows Server 2008** with Active Directory installed
2. **PowerShell 2.0+** (included with Server 2008 R2)
3. **Active Directory Module for Windows PowerShell**
   - Install via: Add Roles → Active Directory Domain Services Tools
4. **Administrative Rights** on the domain controller
5. **Domain Created:** tupt.com must already exist

### Step 1: Verify Prerequisites

Run PowerShell as Administrator and check:
```powershell
Import-Module ActiveDirectory
Get-ADDomain
```

If these commands fail, install Active Directory Tools before proceeding.

### Step 2: Run Master Script

Open PowerShell as Administrator and navigate to the script directory:

```powershell
cd "C:\Users\leoma\OneDrive\Documents\OPERATING SYSTEMS\AddBulkUsers"
.\00_RUN_ALL_SCRIPTS.ps1
```

This will:
1. Execute 00_CreateOrganizationalUnits.ps1
2. Execute 01_CreateAcademicUsers.ps1
3. Execute 02_CreateAdministrativeUsers.ps1

### Step 3: Run Individual Scripts (If Needed)

If you need to run scripts individually:

```powershell
# Create OUs only
.\00_CreateOrganizationalUnits.ps1

# Create academic users only
.\01_CreateAcademicUsers.ps1

# Create administrative users only
.\02_CreateAdministrativeUsers.ps1
```

---

## 🔐 User Account Details

### Academic Users
- **Username Format:** FirstName.LastName (lowercase)
  - Example: `john.smith`
- **Full Name:** FirstName MiddleName(s) LastName
- **Email:** username@tupt.com
- **Default Password:** `TuptStudent@2024`
- **Location:** `OU=Program,OU=Department,OU=Academic,DC=tupt,DC=com`
- **Group Membership:** Program-specific security group

### Administrative Users
- **Username Format:** InitialLastName (lowercase)
  - Example: `j.smith`
- **Full Name:** FirstName LastName
- **Email:** username@tupt.com
- **Default Password:** `TuptAdmin@2024`
- **Location:** `OU=Office,OU=Administrative,DC=tupt,DC=com`
- **Group Membership:** Office-specific security group

---

## 🔒 Password Policy

### Default Passwords
- **Academic Users:** `TuptStudent@2024`
- **Administrative Users:** `TuptAdmin@2024`

### ⚠️ IMPORTANT: Change Passwords

After user creation, you MUST:

1. **Force password change on next logon:**
   ```powershell
   Get-ADUser -Filter "Department -eq 'IT'" | Set-ADUser -ChangePasswordAtLogon $true
   ```

2. **Or set new passwords via GPO:**
   - Create Group Policy forcing Windows Server 2008 password requirements

3. **Or manually reset via ADUC:**
   - Right-click user → Reset Password

---

## 📝 Script Details

### 00_CreateOrganizationalUnits.ps1

Creates the complete OU hierarchy:
- **Root OUs:** Academic, Administrative, Workstations
- **Department OUs:** All 4 academic departments
- **Program OUs:** All 19 programs under departments
- **Office OUs:** All 8 administrative offices
- **Security Groups:** Program-specific and office-specific groups

**Execution Time:** ~2-5 minutes

### 01_CreateAcademicUsers.ps1

Creates and distributes 317 IT student users:
- Reads from `Reference Data\ALL_STUDENTS.txt`
- Skips empty lines automatically
- Distributes students equally across 19 programs
- Creates users with proper AD attributes
- Adds users to program security groups
- Creates detailed execution log

**Features:**
- Duplicate username detection and auto-incrementing
- Gender tracking (M/F)
- Proper name parsing (handles multiple middle names)
- Error handling and reporting

**Execution Time:** ~5-15 minutes (depending on server performance)

**Output:**
- ~317 user accounts created
- Security groups populated
- Log file: `Logs\AcademicUsers_[timestamp].log`

### 02_CreateAdministrativeUsers.ps1

Creates administrative office structure and users:
- Creates office OUs (if not already created)
- Creates office security groups
- Includes sample administrative users (16 total)
- Provides function to import from CSV

**Features:**
- Sample data included for demonstration
- CSV import capability for custom staff
- Different password policy for admin accounts
- Office-specific group assignment

**Execution Time:** ~1-3 minutes

---

## 🎯 Login Restrictions Configuration

### Workstation Assignment

As per requirements: **"All users can only log on to workstations (XP Class A network, 7 Class B network)"**

#### Implementation Steps:

1. **Create Workstation OUs:**
   - OU=XP-Class-A
   - OU=Class-B-Network

2. **Apply Group Policies:**

   **For Academic Users - XP Class A:**
   ```
   Group Policy Name: Academic-Workstation-Logon
   Computer Configuration > Admin Templates > System > Logon
   Restrict users to specific workstations: [List all XP Class A workstations]
   ```

   **For Administrative - Class B Network:**
   ```
   Group Policy Name: Admin-Workstation-Logon
   Computer Configuration > Admin Templates > System > Logon
   Restrict users to specific workstations: [List all Class B workstations]
   ```

3. **Alternative: Logon Hours (using user properties):**
   ```powershell
   # Example: Restrict user logon hours
   Set-ADUser -Identity "john.smith" -Replace @{
       logonWorkstations = "XP-Workstation-01;XP-Workstation-02"
   }
   ```

---

## 🐛 Troubleshooting

### Common Issues

#### Issue: "Active Directory module not found"
**Solution:**
```powershell
# Install Active Directory Tools
Add-WindowsFeature RSAT-AD-Tools
```

#### Issue: "Access Denied" when creating users
**Solution:**
- Run PowerShell as Administrator (right-click → Run as Administrator)
- Ensure your account has permission to create users in AD
- Check Domain Admin Group membership

#### Issue: "OU already exists"
**Solution:**
- The script will skip existing OUs
- If you need to recreate, delete the OU structure first or modify the script

#### Issue: "Duplicate usernames"
**Solution:**
- Automatic conflict resolution applies numeric suffix
- john.smith → john.smith1 → john.smith2, etc.

#### Issue: "User creation stops midway"
**Solution:**
- Check Active Directory availability
- Review log file for specific errors:
  ```powershell
  Get-Content "Logs\AcademicUsers_*.log" -Tail 50
  ```

---

## 📊 Verification Checklist

After script execution, verify:

- [ ] All OUs created in AD Users and Computers
  ```powershell
  Get-ADOrganizationalUnit -Filter * | Select Name, DistinguishedName | FT
  ```

- [ ] User counts correct
  ```powershell
  Get-ADUser -Filter "Department -eq 'IT'" | Measure-Object
  ```

- [ ] Security groups created and populated
  ```powershell
  Get-ADGroup -Filter "Name -like '*-Users'" | ForEach {
      Write-Host "$($_.Name):"
      Get-ADGroupMember $_ | Measure-Object
  }
  ```

- [ ] Users can be found
  ```powershell
  Get-ADUser -Filter "GivenName -like 'JOHN*'"
  ```

- [ ] Log files generated without errors
  ```powershell
  Get-Content "Logs\*.log" | Select-String "ERROR"
  ```

---

## 🔄 Additional Operations

### Resetting All Passwords

```powershell
$NewPassword = ConvertTo-SecureString "NewPassword@2024" -AsPlainText -Force
Get-ADUser -Filter "Department -eq 'IT'" | Set-ADAccountPassword -NewPassword $NewPassword -Reset
```

### Enabling All Users

```powershell
Get-ADUser -Filter "Department -eq 'IT'" | Enable-ADAccount
```

### Exporting User List

```powershell
Get-ADUser -Filter "Department -eq 'IT'" -Properties DisplayName,Mail,Department | Export-Csv "AcademicUsers.csv" -NoTypeInformation
```

### Adding Users to Workstation Restrictions

```powershell
Get-ADUser -Filter "Department -eq 'IT'" | Set-ADUser -LogonWorkstations "XP-WORKSTATION-01;XP-WORKSTATION-02"
```

---

## 📚 Additional Resources

### Active Directory PowerShell Commands Reference

- `Get-ADUser` - Get user information
- `New-ADUser` - Create new user
- `Get-ADGroup` - Get group information
- `New-ADGroup` - Create new group
- `Add-ADGroupMember` - Add user to group
- `New-ADOrganizationalUnit` - Create new OU
- `Get-ADOrganizationalUnit` - List OUs

### Useful Links

- [Active Directory PowerShell Module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)
- [Windows Server 2008 Administration](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-supported-editions)
- [Group Policy Administration](https://learn.microsoft.com/en-us/windows-server/identity/group-policy/group-policy-overview)

---

## 📞 Support & Maintenance

### Pre-Deployment Checklist

- [ ] Backup Active Directory database
- [ ] Test scripts in lab environment first
- [ ] Verify all domain controllers are online
- [ ] Ensure adequate disk space on DC
- [ ] Schedule during maintenance window

### Post-Deployment Tasks

1. **Day 1:** Verify all users can log on successfully
2. **Day 2-3:** Test workstation restrictions
3. **Week 1:** Review log files for any anomalies
4. **Week 2:** Implement workstation login policies
5. **Week 3:** Configure login hours if needed
6. **Ongoing:** Monitor AD replication and performance

### Rollback Procedure

If you need to undo user creation:

```powershell
# Delete users from specific program
Get-ADUser -Filter "AnEldoradoOU -like '*BTVTE-Electrical*'" | Remove-ADUser -Confirm

# Delete OUs (careful: must remove users first)
Get-ADOrganizationalUnit -Filter "Name -like '*BTVTE*'" | Remove-ADOrganizationalUnit -Confirm
```

---

## ✅ Summary

This solution provides:
- ✓ Automated user creation for 317 IT students
- ✓ Proper OU structure for 27 units (19 academic + 8 admin)
- ✓ Security group management and assignment
- ✓ Duplicate name handling
- ✓ Comprehensive logging
- ✓ Easy scalability for future users
- ✓ Administrator-friendly interface
- ✓ Error recovery mechanisms

---

**Version:** 1.0  
**Last Updated:** March 2026  
**Created for:** TUPT Active Directory Migration  
**Domain:** tupt.com  
