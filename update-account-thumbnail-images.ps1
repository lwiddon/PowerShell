<#
.SYNOPSIS
.DESCRIPTION
    Processes all jpg's in a directory, checks and updates a users image in Active Directory.
.PARAMETER
.INPUTS
.OUTPUTS
.NOTES
    Version       : 1.0
    Author        : 
    Creation Date : 
    Purpose/Change:
            v1.0  - Original script.
.EXAMPLE
#>

#------------------------------------------------------------------------------
# IMPORT MODULES
#------------------------------------------------------------------------------
Import-Module ActiveDirectory

#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

$updateAD = $true
$deleteFile = $true

$extension = '.jpg'
$maxFileSizeKB = 100

$path = "<INSERT PATH HERE>"

$arrayOfStaff = @()

# Set variables for SMTP.
$smtpMessage = @{
    To         = '<INSERT EMAIL ADDRESS HERE>'
    From       = (($env:computerName) + '@<INSERT DOMAIN HERE>')
    Subject    = 'User Account Thumbnails'    
    SmtpServer = '<INSERT SMTP FQDN HERE>'    
    BodyAsHtml = $true
    Body       = ''
}
# HTML.
$htmlHead = '<html><style>
			body{align: left; font-family: Arial; font-size: 10pt;}
            .ps{font-family: Courier;}
			h1{font-size: 14px;}
			table{border: 1px solid black; border-collapse: collapse; font-size: 11px;}
			th{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
			td{border: 1px solid black; padding: 5px; }
            td.error{background: #ffa500;}
			</style>
			<body>'
$htmlBody = ''
$htmlTail = '</body></html>'
$htmlReport = ''

#------------------------------------------------------------------------------
# FUNCTIONS
#------------------------------------------------------------------------------

# Send SMTP message.
Function SendSmtpMessage {
    $smtpMessage.Set_Item('Body',($htmlHead + $htmlBody + $htmlTail))
    Send-MailMessage @smtpMessage
}

#------------------------------------------------------------------------------
# START OF SCRIPT
#------------------------------------------------------------------------------

try {
    # Get all active directory user accounts.
    $arrayOfStaff = Get-ADUser -Filter * -Properties thumbnailPhoto

    if (Test-Path $path) {
        # Get a list of all thumbnail image files.
        $arrayOfFiles = Get-ChildItem -Path $path

        $counter=0
        foreach ($file in $arrayOfFiles) {
            $counter++
            Write-Progress -Activity 'Processing Photos' -CurrentOperation $file -PercentComplete (($counter / $arrayOfFiles.count) * 100)
            
            if ($file.Name -ilike "*.jpg") {
                
                # Active directory thumbnails cannot be larger than 100KB.
                if (($file.length / 1KB) -ge $maxFileSizeKB) {
                    Write-Host -ForegroundColor Red "[Oversize] $($file.FullName)"
                }
                else {
                    # Must set to lower case for the array IndexOf function to work correctly. 
                    $userName = ($file.Name.Split('.')[0]).toLower()

                    if ($arrayOfStaff.SamAccountName -icontains $userName) {
                        $index = [array]::IndexOf($arrayOfStaff.SamAccountName,$userName)

                        $photo = [byte[]](Get-Content $file.FullName -Encoding byte)
                        if (-not ($arrayOfStaff[$index].thumbnailPhoto) -or (Compare-Object -ReferenceObject $arrayOfStaff[$index].thumbnailPhoto -DifferenceObject $photo)) {
                            mspaint.exe $file.FullName
                            if ($updateAD) {
                                Set-ADUser $arrayOfStaff[$index].samAccountName -Replace @{thumbnailPhoto=$photo}
                            }
                            Write-Host -ForegroundColor Green "[Updating] $($file.FullName)"
                        }
                        else {
                            #Write-Host -ForegroundColor Yellow "[OK      ] $($file.FullName)"
                        }
                    }
                    else {
                        if ($deleteFile) {
                            Remove-Item $file.FullName
                        }
                        Write-Host -ForegroundColor Cyan "[Deleting] $($file.FullName)"
                    }
                }
            }
            else {
                if ($deleteFile) {
                    Remove-Item $file.FullName
                }
                Write-Host -ForegroundColor Cyan "[Deleting] $($file.FullName)"
            }
        }
    }
    else {}
}
catch {}

#------------------------------------------------------------------------------
# END OF SCRIPT
#------------------------------------------------------------------------------
