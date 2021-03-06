﻿<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.136
     Generated on:       4/3/2017 2:52 PM
     Generated by:       wamonr
    --------------------------------------------------------------------------------
    .DESCRIPTION
        Script generated by PowerShell Studio 2017
#>


<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.136
	 Created on:   	4/3/2017 2:44 PM
	 Created by:   	wamonr
	 Organization: 	
	 Filename:     	CbnOffice365Alerts.psm1
	-------------------------------------------------------------------------
	 Module Name: CbnOffice365Alerts
	===========================================================================
#>

function Get-Office365Events {
    param (
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,

        [ValidateSet('ServiceIncident','Maintenance','Message','All')]
        [string[]]$Type = 'All'
    )

    # Specify the base url
    # This url is universal for all tenants, but is defined here
    # to easily modify should it change in the future.
    $baseUri = "https://api.admin.microsoftonline.com/shdtenantcommunications.svc"

    # Get the authorization cookie
    $getCookie = @{
        'ContentType' = 'application/json'
        'Method' = 'Post'
        'Uri' = "$baseUri/Register"
        'Body' = (@{userName=$Credential.UserName;password=$Credential.GetNetworkCredential().Password;} | ConvertTo-Json).ToString()
    }
    $cookie = (Invoke-RestMethod @getCookie -ErrorAction Stop).RegistrationCookie
    
    # Get the event types
    $eventTypes = @()
    if ($Type -contains 'ServiceIncident' -or $Type -contains 'All') {
        $eventTypes += 0
    }
    if ($Type -contains 'Maintenance' -or $Type -contains 'All') {
        $eventTypes += 1
    }
    if ($Type -contains 'Message' -or $Type -contains 'All') {
        $eventTypes += 2
    }
    
    # Get and output the events
    $getEvents = @{
        'ContentType' = 'application/json'
        'Method' = 'Post'
        'Uri' = "$baseUri/GetEvents"
        'Body' = (@{lastCookie=$cookie;locale="en-US";preferredEventTypes=$eventTypes} | ConvertTo-Json).ToString()
    }
    (Invoke-RestMethod @getEvents -ErrorAction Stop).Events | Write-Output
}

function Get-Office365ServiceHealth {
    param (
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential
    )

    # Get active service incident events
    $events = Get-Office365Events -Type ServiceIncident -Credential $Credential -ErrorAction Stop |
        Where-Object {-not $_.EndTime}
    
    # Parse through, put together, and output service incident events    
    foreach ($event in $events) {

        # Gather known properties
        # We'll gather Title, NextUpdate, and UserImpact later so those
        # are set to null for now.
        $properties = [ordered]@{
            'Id' = $event.Id
            'Title' = $null
            'Service' = $event.AffectedServiceHealthStatus.ServiceName
            'Status' = $event.Status
            'LastUpdate' = $event.LastUpdatedTime.ToLocalTime()
            'NextUpdate' = 'Unknown'
            'StartTime' = $event.StartTime.ToLocalTime()
            'UserImpact' = $null
            'LatestMessage' = $event.Messages[$event.Messages.Count-1].MessageText
        }

        # Get title
        # Microsoft updates the title of alerts as they learn more, so we parse
        # through the messages newest to oldest looking for the latest title.
        for ($i=$event.Messages.Count-1; $i -ge 0; $i--) {
            if ($event.Messages[$i].MessageText -match '\bTitle:\s+(?<Title>.+)') {
                $properties.Title = $Matches['Title']
                break
            }
        }

        # Get next update
        # Microsoft updates the next update of alerts as they publish each alert, so we
        # parse through the messages newest to oldest looking for the latest info.
        for ($i=$event.Messages.Count-1; $i -ge 0; $i--) {
            if ($event.Messages[$i].MessageText -match '\bNext update by:\s+(?<NextUpdate>.+)') {
                $properties.NextUpdate = $Matches['NextUpdate'] -replace ';.*', '' -replace ', at ', ' ' -replace 'UTC', '-0000' -as [datetime]
                break
            }
        }

        # Get user impact
        # Microsoft updates the user impact as they learn more, so we parse through
        # the messages newest to oldest looking for the latest info.
        for ($i=$event.Messages.Count-1; $i -ge 0; $i--) {
            if ($event.Messages[$i].MessageText -match '\bUser Impact:\s+(?<UserImpact>.+)') {
                $properties.UserImpact = $Matches['UserImpact']
                break
            }
        }

        # Output event
        New-Object -TypeName psobject -Property $properties
    }
}

function Get-Office365Messages {
    param (
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential
    )

    # Get message center messages
    $messages = Get-Office365Events -Type Message -Credential $Credential -ErrorAction Stop
    
    # Parse through, put together, and output message center messages
    foreach ($message in $messages) {

        # Gather known properties
        $properties = [ordered]@{
            'Id' = $message.Id
            'ActBy' = $null
            'Category' = $message.Category
            'Title' = $message.Title
            'PublishedOn' = $null
            'ExpiresOn' = $null
            'Body' = $message.Messages[0].MessageText
            'ExternalLink' = $message.ExternalLink
        }

        # Get act by date (if available)
        if ($message.ActionRequiredByDate) {
            $properties.ActBy = $message.ActionRequiredByDate.ToLocalTime()
        }

        # Get published on date (if available)
        if ($message.StartTime) {
            $properties.PublishedOn = $message.StartTime.ToLocalTime()
        }

        # Get expires on date (if available)
        if ($message.EndTime) {
            $properties.ExpiresOn = $message.EndTime.ToLocalTime()
        }

        # Output message
        New-Object -TypeName psobject -Property $properties
    }
}


Export-ModuleMember -Function Get-Office365Events,
					Get-Office365ServiceHealth,
					Get-Office365Messages