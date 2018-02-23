######################################################################################################
# 
#
# Created by Billy Smith
#
# This script will connect you to Office 365 and and migrate a list of users from a csv Commented out.
#
# Please update below with any changes made.
#
# Changes
# 09/12 - 03/10/2012
# Prompts for User for credentials .
# Read csv and acts on the data within it.
# 10/10/12
# Changed csv format
#Added more explanations 
#24/10/2012
#Removed Blackberry Script to a new script as the object has to be moved for this to complete
#26/10/2012
#Added browse for csv
######################################################################################################


#Loads msonline Powershell Module
Import-Module MSOnline

#Stop on Error
$ErrorActionPreference = 'Stop'

# Get required accounts
Clear
Write-Host "This command will connect you to the Microsoft Office 365 Powershell Instance"
Write-Host ""
Write-Host "Enter your   ea account details in eaaccount@domain.com format." 
$LiveCred = get-credential -message 'Enter ea.......@domain.com'
#Create a session in the cloud
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://pod51049psh.outlook.com/powershell-liveid?PSVersion=4.0 -Credential $LiveCred -Authentication Basic -AllowRedirection
connect-msolservice -credential $LiveCred
#Import the powershell commands from the cloud
Import-PSSession $Session -AllowClobber

#Functions
#function round( $value, [MidpointRounding]$mode = 'AwayFromZero' ) {
#  [Math]::Round( $value, $mode )
#}

#function Select-FileDialog
#{
 #     param([string]$Title,[string]$Directory,[string]$Filter="All Files (*.*)|*.*")
 #     [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
 #     $objForm = New-Object System.Windows.Forms.OpenFileDialog
 #     $objForm.InitialDirectory = $Directory
 #     $objForm.Filter = $Filter
 #     $objForm.Title = $Title
 #     $Show = $objForm.ShowDialog()
 #     If ($Show -eq "OK")
 #     {
 #           Return $objForm.FileName
 #     }
 #     Else
 #     {
 #           Write-Error "Operation cancelled by user."
 #          Break
 #     }
#}

#Get csv file
#$csv_file = Select-FileDialog -Title "User Migration CSV - Select File to import"

#Variable Definition
#$csvdata = IMPORT-CSV $csv_File
#$Domain = "@Domain.com"

#For every user in the csv file perform the operation
#foreach ( $User in $csvdata){
#      #Data Manipulation
#      $FullName = $($User.Name)     
#      $BadItems = $($User.TotalItems)
#      $badcount = $BadItems / 10 # 10% of TotalItems, this is required for an error check. 
#      $BadFinal = round ($badcount) # Round up or down
#      #$FName = $FullName -replace " ", "." # Remove spaces
#      #$FinalName = $FName + $Domain # add two strings together
#      #End Data Manipulation
      
	  #Write-Host $FullName
      #This performs the move
#      New-MoveRequest -Identity "$FullName" -BadItemLimit $BadFinal -AcceptLargeDataLoss -Remote -RemoteHostName 'hybrid.domain.com' -TargetDeliveryDomain 'williamgrant.mail.onmicrosoft.com' -RemoteCredential $Cred -Suspend -SuspendComment 'Migrate when over to 2010'
      #New-MoveRequest -Identity "$FullName" -Remote -RemoteHostName 'hybrid.domain.com' -TargetDeliveryDomain 'Tenant.mail.onmicrosoft.com' -RemoteCredential $Cred
      #End worker
#}

#Show move requests
# Get-MoveRequest

# resume failed move requests
# Get-MoveRequest -MoveStatus Failed | Resume-Mov

#Detail from above
# get-moverequeststatistics -ID 'User' -IncludeReport # where users is inprogress users from above to list out more details.

# Remove Move requests
# Remove-MoveRequest -Identity 'Users'

#Grants right to administrate all mailboxes
#To Create
# New-ManagementRoleAssignment -Name "PolicyPatrolSignatures" -Role ApplicationImpersonation -User easmithb@domain.com
#To Add
# Set-ManagementRoleAssignment -ID "PolicyPatrolSignatures"

#Get Office 365 Mailbox Statistics
# Get-MailboxStatistics username -includemovehistory | fl

#get mailbox permissions
# Get-MailboxPermissions User
#Remove Mailbox permisssions
# Remove-MailboxPermissions -Identity user -AccessRights right -Trustee User -Confirm:$false
#Add Mailbox permissions
# Add-NailboxPermission -Identity user -AccessRights sendas -Trustee user -Confirm:$false

#Get open Sessions
# Get-PSSession

#From above Close
# Remove-PSSession -Id 1 # where the ID is from above 

#Quick and Dirty Close Session (DO NOT USE On Exchange Server)
# get-pssession | Remove-PSSession 

#To cleanup deleted users from Office 365, Run the following 
# Connect-msolservice -cred $livecred
#To delete cloud only users
#  Remove-MsolUser -UserPrincipalName 'UPN'
#List affected objects
# Get-MSolUser -ReturnDeletedUsers |Select Displayname, ObjectId
#Remove *-*-*-* with objectID from above
# Remove-MsolUser -ObjectId *-*-*-* -RemoveFromRecycleBin
# Remove-MsolUser -ObjectId objectid-from-previous-step -RemoveFromRecycleBin

#To find Errors on the following object use
# Connect-msolservice -cred $livecred
# Get-MsolUser -All | Where {$_.Errors –ne $null } | Select ObjectID, DisplayName
# Get-MsolContact -All | Where {$_.Errors –ne $null } | Select ObjectID, DisplayName
# Get-MsolGroup -All| Where {$_.Errors –ne $null } | Select ObjectID, DisplayName
