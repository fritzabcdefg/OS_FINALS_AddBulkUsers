# Quick Start Guide - TUPT AD User Creation

## 🚀 35-Second Quick Start

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to the script directory
cd "C:\Users\leoma\OneDrive\Documents\OPERATING SYSTEMS\AddBulkUsers"

# 3. Run the master script (does everything automatically)
.\00_RUN_ALL_SCRIPTS.ps1
```

That's it! The script will:
1. ✓ Create all organizational units
2. ✓ Create all 317 users (distributed across 19 academic programs)
3. ✓ Create administrative users
4. ✓ Create security groups
5. ✓ Log all operations

---

## 📋 What Gets Created

### Organizational Units (27 total)
```
└── Academic
    ├── Basic-Art-Sciences
    │   ├── BTVTE-Electrical
    │   ├── BTVTE-Electronics
    │   ├── BTVTE-Computer-Hardware
    │   └── BTVTE-Computer-Software
    ├── Electrical-Allied
    │   ├── Information-Technology
    │   ├── Electrical-Engineering
    │   ├── Electronics-Engineering
    │   ├── Instrumentation-Control-Tech
    │   └── BET-Mechatronics
    ├── Mechanical-Allied
    │   ├── Mechanical-Engineering-Tech
    │   ├── RAC-Engineering-Tech
    │   ├── Non-Destructive-Engineering-Tech
    │   ├── Electromechanical-Engineering-Tech
    │   ├── Automotive-Engineering-Tech
    │   └── BET-ElectroMechanical
    └── Civil-Allied
        ├── Civil-Engineering
        ├── Civil-Engineering-Tech
        ├── Environmental-Science
        └── Chemical-Engineering-Tech

└── Administrative
    ├── Registrars-Office
    ├── Directors-Office
    ├── Research-Extension
    ├── HR-Management-Office
    ├── Finance-Office
    ├── Supply-Procurement
    ├── Records-Office
    └── Library-Services

└── Workstations [For future workstation OU structure]
```

### User Accounts

#### Academic Users (317 total)
- **Source:** ALL_STUDENTS.txt
- **Distribution:** ~17 per program
- **Username:** firstname.lastname (lowercase)
- **Example:** john.smith
- **Password:** TuptStudent@2026
- **Location:** OU=Program,OU=Department,OU=Academic,DC=tupt,DC=edu,DC=ph

#### Administrative Users (16 sample)
- **Source:** Sample data (included template.csv to add more)
- **Username:** initials.lastname (lowercase)
- **Example:** j.smith
- **Password:** TuptAdmin@2026
- **Location:** OU=Office,OU=Administrative,DC=tupt,DC=edu,DC=ph

---

## 🎯 Scripts Explained

| Script | Purpose | Time | Status |
|--------|---------|------|--------|
| 00_RUN_ALL_SCRIPTS.ps1 | Master orchestrator - runs everything | 20-30 min | **Use this** |
| 00_CreateOrganizationalUnits.ps1 | Creates OUs, Groups, structure | 2-5 min | Automatic |
| 01_CreateAcademicUsers.ps1 | Creates 317 student users | 5-15 min | Automatic |
| 02_CreateAdministrativeUsers.ps1 | Creates admin office users | 1-3 min | Automatic |

---

## ⚠️ Before Running

- [ ] Windows Server 2008 with AD installed
- [ ] PowerShell 2.0+ (usually built-in)
- [ ] Run as **Administrator**
- [ ] Domain **tupt.com** exists
- [ ] Active Directory Module available
- [ ] Backup your AD database (just in case)

---

## 🔐 Default Passwords

**CHANGE THESE IMMEDIATELY AFTER CREATION**

| User Type | Default Password | Command to Change |
|-----------|------------------|-------------------|
| Academic (Students) | TuptStudent@2024 | See below |
| Administrative (Staff) | TuptAdmin@2024 | See below |

### Force All Users to Change Password on Next Logon

```powershell
# For academic users
Get-ADUser -Filter "Path -like '*Academic*'" | Set-ADUser -ChangePasswordAtLogon $true

# For administrative users  
Get-ADUser -Filter "Path -like '*Administrative*'" | Set-ADUser -ChangePasswordAtLogon $true
```

---

## ✅ After Running Scripts

### 1. Verify Creation (run these commands)

```powershell
# Count created users
Get-ADUser -Filter "Path -like '*Academic*'" | Measure-Object
Get-ADUser -Filter "Path -like '*Administrative*'" | Measure-Object

# List all OUs
Get-ADOrganizationalUnit -Filter * | Select Name | Sort Name

# Check security groups
Get-ADGroup -Filter "Name -like '*Users'" | Measure-Object
```

### 2. Test User Login

- Log in to a workstation: **username: john.smith**
- Password: **TuptStudent@2024** (or whatever you see in script output)

### 3. Configure Workstation Restrictions (Next Step)

Since requirement is "users can only log on to XP Class A or Class B networks":

**Option A: Group Policy (Recommended)**
1. Open Group Policy Editor
2. Create policy: "Academic-Workstation-Logon"
3. Computer Config → Admin Templates → System → Logon
4. Set "Restrict users to specific workstations"

**Option B: PowerShell**
```powershell
# Example: Restrict john.smith to specific workstations
Set-ADUser -Identity "john.smith" -LogonWorkstations "XP-WS-01;XP-WS-02"
```

---

## 🔍 Finding & Troubleshooting

### Find a user

```powershell
# Find by name
Get-ADUser -Filter "Name -like '*John*'"

# Find by department
Get-ADUser -Filter "Department -eq 'IT'"

# Find and reset password
Get-ADUser -Filter "SamAccountName -eq 'john.smith'" | Set-ADAccountPassword -NewPassword (ConvertTo-SecureString "NewPassword@2024" -AsPlainText -Force) -Reset
```

### View logs

```powershell
# Show recent logs
Get-ChildItem "Logs" | Sort-Object LastWriteTime -Descending | Select-Object -First 3

# View specific log
Get-Content "Logs\AcademicUsers_20260314_120000.log" | Head -50

# Search for errors
Get-Content "Logs\*.log" | Select-String "ERROR"
```

### Common Issues & Solutions

| Problem | Solution |
|---------|----------|
| "Active Directory module not found" | Restart PowerShell or install RSAT-AD-Tools |
| "Access Denied" | Run as Administrator (Right-click → Run as Administrator) |
| "User already exists" | Script will auto-increment: john.smith1, john.smith2 |
| "OU creation fails" | Script will skip if already exists (harmless) |
| "No output seen" | Check Logs folder - all operations are logged |

---

## 📞 Important Notes

### Username Format Rules

The scripts will:
- Remove special characters from names
- Convert to lowercase
- Handle duplicate names automatically
- Skip empty lines in source files

**Examples:**
- `SANTOS, CARLOS LUIS` → `carlos.santos`
- `DE LEON, JUAN` → `juan.de`
- `SANTOS, CARLOS LUIS` (2nd) → `carlos.santos1`

### Active Directory Locations

All users are placed in proper OUs:
```
Academic:       OU=Program,OU=Department,OU=Academic,DC=tupt,DC=com
Administrative: OU=Office,OU=Administrative,DC=tupt,DC=com
```

This allows for:
- ✓ Group Policy assignment per department
- ✓ Delegation of admin rights per OU
- ✓ Easy user management by program/office
- ✓ Workstation restriction implementation

---

## 🎁 What's Included

```
AddBulkUsers/
├── 00_RUN_ALL_SCRIPTS.ps1                  ← START HERE
├── 00_CreateOrganizationalUnits.ps1
├── 01_CreateAcademicUsers.ps1
├── 02_CreateAdministrativeUsers.ps1
├── README.md                               (Detailed guide)
├── QUICKSTART.md                           (This file)
├── administrative_users_template.csv       (For adding more admin staff)
│
├── Reference Data/
│   ├── ALL_STUDENTS.txt                   (317 student names)
│   └── [other student files]
│
├── Reference Codes/
│   └── [original example scripts]
│
└── Logs/                                   (Auto-created after running)
    └── [execution logs]
```

---

## 🏁 Summary

| Step | What | Time |
|------|------|------|
| 1 | Open PowerShell as Admin | 1 min |
| 2 | Navigate to script folder | 1 min |
| 3 | Run `00_RUN_ALL_SCRIPTS.ps1` | 20-30 min |
| 4 | Verify in Active Directory | 5 min |
| 5 | Change default passwords | 10 min |
| 6 | Configure workstation policies | 15 min |
| **Total** | **Complete AD Setup** | **~1 hour** |

---

## 📟 Command Cheat Sheet

```powershell
# Quick commands you'll need

# Run the master script
.\00_RUN_ALL_SCRIPTS.ps1

# Force password change on next logon
Get-ADUser -Filter "Path -like '*Academic*'" | Set-ADUser -ChangePasswordAtLogon $true

# Count users created
(Get-ADUser -Filter "Path -like '*Academic*'" | Measure-Object).Count

# Find a user
Get-ADUser -Filter "DisplayName -like '*john*'" | Select Name, SamAccountName

# Export all users to CSV
Get-ADUser -Filter "Department -eq 'IT'" -Properties * | Export-Csv "users.csv" -NoTypeInformation

# View recent logs
Get-Content (Get-ChildItem "Logs" | Sort LastWriteTime -Desc | Select -First 1) | Tail -30
```

---

## ✨ You're Ready!

Run this command to get started:

```powershell
.\00_RUN_ALL_SCRIPTS.ps1
```

All the rest happens automatically! 🎉
