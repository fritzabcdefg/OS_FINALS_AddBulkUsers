Import-Module ActiveDirectory

# Domain configuration
$DomainUPN   = "bsit.com"
$Container   = "OU=Students,DC=bsit,DC=com"

# Create master gender groups
$bsitMaleGroupName = "BSIT Male"
$bsitFemaleGroupName = "BSIT Female"

if (-not (Get-ADGroup -Filter "Name -eq '$bsitMaleGroupName'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $bsitMaleGroupName -GroupCategory Security -GroupScope Global -Path $Container -ErrorAction SilentlyContinue
    Write-Host "Created group: $bsitMaleGroupName"
}
if (-not (Get-ADGroup -Filter "Name -eq '$bsitFemaleGroupName'" -ErrorAction SilentlyContinue)) {
    New-ADGroup -Name $bsitFemaleGroupName -GroupCategory Security -GroupScope Global -Path $Container -ErrorAction SilentlyContinue
    Write-Host "Created group: $bsitFemaleGroupName"
}

# Get all BSIT student files from Desktop
$files = Get-ChildItem "C:\Users\Administrator\Desktop\*.txt"
$studentFiles = $files | Where-Object { $_.BaseName -like 'BSIT-*' -and $_.BaseName -notmatch 'M-and-F' }

foreach ($file in $studentFiles) {
    $SectionName = $file.BaseName
    Write-Host "Processing file: $($file.Name)"

    # Create male and female groups if they don't exist
    $maleGroupName = "$SectionName-Male"
    $femaleGroupName = "$SectionName-Female"
    
    if (-not (Get-ADGroup -Filter "Name -eq '$maleGroupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $maleGroupName -GroupCategory Security -GroupScope Global -Path $Container -ErrorAction SilentlyContinue
        Write-Host "Created group: $maleGroupName"
    }
    if (-not (Get-ADGroup -Filter "Name -eq '$femaleGroupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $femaleGroupName -GroupCategory Security -GroupScope Global -Path $Container -ErrorAction SilentlyContinue
        Write-Host "Created group: $femaleGroupName"
    }

    # Read student file and add users to gender groups
    $students = Get-Content $file.FullName
    $maleCount = 0
    $femaleCount = 0
    $notFoundCount = 0

    foreach ($line in $students) {
        if (-not $line -or $line.Trim() -eq "") {
            continue
        }

        # Parse: LASTNAME, FIRSTNAME..., M/F
        $parts = $line -split ','
        if ($parts.Count -lt 3) {
            continue
        }

        $lastName = $parts[0].Trim()
        $firstNameFull = $parts[1].Trim()
        $gender = $parts[$parts.Count - 1].Trim()
        $firstNameOnly = $firstNameFull.Split(' ')[0]

        # Build samAccountName pattern to search for user
        $samPattern = ($firstNameOnly + "." + $lastName).ToLower()

        try {
            $user = Get-ADUser -Filter "SamAccountName -like '$samPattern*'" -ErrorAction SilentlyContinue
            
            if ($user) {
                if ($gender -eq "M") {
                    Add-ADGroupMember -Identity $maleGroupName -Members $user.SamAccountName -ErrorAction SilentlyContinue
                    Add-ADGroupMember -Identity $bsitMaleGroupName -Members $user.SamAccountName -ErrorAction SilentlyContinue
                    Write-Host "Added $($user.SamAccountName) to $maleGroupName and $bsitMaleGroupName"
                    $maleCount++
                }
                elseif ($gender -eq "F") {
                    Add-ADGroupMember -Identity $femaleGroupName -Members $user.SamAccountName -ErrorAction SilentlyContinue
                    Add-ADGroupMember -Identity $bsitFemaleGroupName -Members $user.SamAccountName -ErrorAction SilentlyContinue
                    Write-Host "Added $($user.SamAccountName) to $femaleGroupName and $bsitFemaleGroupName"
                    $femaleCount++
                }
            }
            else {
                Write-Host "User not found: $lastName, $firstNameOnly"
                $notFoundCount++
            }
        }
        catch {
            Write-Host "Error processing user: $_"
        }
    }

    Write-Host "Section Summary for $SectionName: Male=$maleCount, Female=$femaleCount, NotFound=$notFoundCount"
}

# Display master group summary
$bsitMaleMembers = (Get-ADGroupMember -Identity $bsitMaleGroupName -ErrorAction SilentlyContinue).Count
$bsitFemaleMembers = (Get-ADGroupMember -Identity $bsitFemaleGroupName -ErrorAction SilentlyContinue).Count
Write-Host "Master Groups Summary:"
Write-Host "$bsitMaleGroupName: $bsitMaleMembers members"
Write-Host "$bsitFemaleGroupName: $bsitFemaleMembers members"
