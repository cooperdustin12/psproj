﻿<#
    .NOTES
    --------------------------------------------------------------------------------
     Code generated by:  SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
     Generated on:       10/20/2016 9:39 PM
     Generated by:       Alex Monroe
     Organization:       SignPost Coffee, LLC
    --------------------------------------------------------------------------------
    .DESCRIPTION
        Script generated by PowerShell Studio 2016
#>

	<#	
		===========================================================================
		 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
		 Created on:   	10/20/2016 2:54 PM
		 Created by:   	Alex Monroe
		 Organization: 	The Christian Broadcasting Network, Inc.
		 Filename:     	CbnDfs.psm1
		-------------------------------------------------------------------------
		 Module Name: CbnDfs
		===========================================================================
	#>
	
	function Get-CbnDfsrStats {
	    [CmdletBinding(PositionalBinding=$false)]
	    param (
	        [Parameter(Position=2)]
	        [string[]]
	        $ComputerName = '*',
	        
	        [Parameter(Position=1)]
	        [string[]]
	        $FolderName = '*',
	
	        [Parameter(Position=0,ValueFromPipeline=$true)]
	        [string[]]
	        $GroupName = '*'
	    )
	
	    begin {}
	
	    process {
	
	        # Process each GroupName specified
	
	        # here we start with a string or an array of strings specifying
	        # the group name(s) to process, wildcards are supported
	
	        foreach ($name in $GroupName) {
	
	            Write-Verbose "Processing group '$name'"
	            
	            $memberships = Get-DfsrMembership -GroupName $name -ComputerName $ComputerName | Where-Object {$_.Enabled}
	
	            # Process through each membership
	            foreach ($membership in $memberships) {
	
	                Write-Verbose "... Processing $($membership.ComputerName)[$($membership.FolderName)]"
	
	                # Create a PSSession and gather details on the folder sizes
	                # we are doing this to compare to the quotas established
	
	                $session = $null
	
	                try {
	                    $session = New-PSSession -ComputerName $membership.ComputerName -ErrorAction Stop
	
	                    $size = Invoke-Command -Session $session -ArgumentList $membership.StagingPath, $membership.ConflictAndDeletedPath -ErrorAction Stop {
	                        param ($StagingPath, $ConflictPath)
	
	                        $stagingSize = 0
	                        $conflictSize = 0
	                        
	                        $stagingSize = Get-ChildItem -Path $StagingPath -Recurse -ErrorAction SilentlyContinue | 
	                            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
	
	                        $conflictSize = Get-ChildItem -Path $ConflictPath -Recurse -ErrorAction SilentlyContinue |
	                            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
	
	                        if (-not $stagingSize) { $stagingSize = 0 }
	                        if (-not $conflictSize) { $conflictSize = 0 }
	
	                        New-Object -TypeName psobject -Property @{
	                            'StagingSize' = [decimal]::Round($stagingSize.Sum / 1MB)
	                            'ConflictSize' = [decimal]::Round($conflictSize.Sum / 1MB)
	                        }
	                    }
	
	                } catch {
	                    $size = New-Object -TypeName psobject -Property @{
	                        'StagingSize' = $null
	                        'ConflictSize' = $null
	                    }
	                }
	
	                if ($session) {$session | Remove-PSSession}
	
	                # Put together the hash table to select the data
	                $stagingSize = @{
	                    Name = 'StagingPathSizeInMB'
	                    Expression = {$size.StagingSize}
	                }
	
	                $conflictSize = @{
	                    Name = 'ConflictAndDeletedSizeInMB'
	                    Expression = {$size.ConflictSize}
	                }
	
	                # Select the data and output
	                $membership |
	                    Select-Object GroupName, ComputerName, FolderName, ContentPath, StagingPath, $stagingSize, StagingPathQuotaInMB, `
	                        $conflictSize, ConflictAndDeletedQuotaInMB, Enabled, State
	
	                Write-Debug "Results gathered for $($membership.ComputerName)[$($membership.FolderName)]"
	            
	            } # =end=> foreach ($membership in $memberships)
	
	        } # =end=> foreach ($name in $GroupName)
	
	    } # =end=> process
	
	    end { }
	}
	
	function Get-CbnDfsrBacklog {
	    [CmdletBinding(DefaultParameterSetName='ByName',PositionalBinding=$false)]
	    param (
	        [Parameter(Position=3)]
	        [string[]]
	        $DestinationComputerName = '*',
	
	        [Parameter(Position=2)]
	        [string[]]
	        $SourceComputerName = '*',
	
	        [Parameter(Position=1)]
	        [string[]]
	        $FolderName = '*',
	
	        [Parameter(Position=0,ValueFromPipeline=$true)]
	        [string[]]
	        $GroupName = '*'
	    )
	
	    begin { }
	
	    process {
	
	        # Process each GroupName specified
	
	        # here we start with a string or an array of strings specifying
	        # the group name(s) to process, wildcards are supported
	
	        foreach ($name in $GroupName) {
	            
	            # Gather the actual groups associated with the specified group name
	
	            # because wildcards are supported this could return multiple group
	            # objects, do to this we have to use a loop to process the results
	
	            $groups = Get-DfsReplicationGroup -GroupName $name
	
	            foreach ($group in $groups) {
	
	                Write-Verbose "Processing group '$($group.GroupName)'"
	                
	                # Get the folders associated with the group
	
	                # multiple folders can get gathered, but those are processed per
	                # source computer => destination computer pair and you will see this
	                # logic later on
	
	                $folders = Get-DfsReplicatedFolder -GroupName $group.GroupName -FolderName $FolderName
	
	                # Get source and destination computers specified and associated with the group
	
	                # wildcards are supported again and multiples can be returned for both source and
	                # destination computers; multiple loops are used below to process through each
	                # source computer => destination computer pair
	
	                $srcComputers = Get-DfsrMember -GroupName $group.GroupName -ComputerName $SourceComputerName
	                $destComputers = Get-DfsrMember -GroupName $group.GroupName -ComputerName $DestinationComputerName
	                
	                # Process through each source computer
	                foreach ($srcComputer in $srcComputers) {
	
	                    # Process through each destination computer
	                    foreach ($destComputer in $destComputers) {
	                        
	                        # Process only if the source and destination computer are not the same
	                        if ($srcComputer.ComputerName -ne $destComputer.ComputerName) {
	
	                            Write-Verbose "... Processing connection '$($srcComputer.ComputerName)=>$($destComputer.ComputerName)'"
	
	                            # Process through each folder in the group
	                            foreach ($folder in $folders) {
	
	                                Write-Verbose "... Processing folder '$($folder.FolderName)'"
	                                
	                                # Get information on source to destination relationship
	
	                                # the replicaiton folder information objects are obtained below from both the source and 
	                                # destination computers to compare the information and obtain the backlog information
	                                # for each folder
	
	                                $srcFolderSettings = $srcComputerSettings | Where-Object {$_.FolderName -eq $folder.FolderName}
	
	                                $wmiQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '$($group.Identifier)' AND ReplicatedFolderName = '$($folder.FolderName)'" 
	                                $inboundPartnerWmi = Get-WmiObject -ComputerName $destComputer.ComputerName -Namespace "root\MicrosoftDFS" -Query $wmiQuery 
	                                     
	                                $wmiQuery = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID = '$($group.Identifier)' AND ReplicatedFolderName = '$($folder.FolderName)'" 
	                                $partnerFolderConfig = Get-WmiObject -ComputerName $srcComputer.ComputerName -Namespace "root\MicrosoftDFS" -Query $wmiQuery
	                                     
	                                # Get the backlogcount from outbound partner 
	                                if ($partnerFolderConfig.Enabled) {
	                                    $wmiQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '$($group.Identifier)' AND ReplicatedFolderName = '$($folder.FolderName)'" 
	                                    $outboundPartnerWmi = Get-WmiObject -ComputerName $srcComputer.ComputerName -Namespace "root\MicrosoftDFS" -Query $wmiQuery 
	
	                                    $vectorVersion = $inboundPartnerWmi.GetVersionVector().VersionVector                                    
	                                    
	                                    $backlogCount = $outboundPartnerWmi.GetOutboundBacklogFileCount($vectorVersion).BacklogFileCount
	                                    $backlogFiles = @($outboundPartnerWmi.GetOutboundBacklogFileIdRecords($vectorVersion).BacklogIdRecords |
	                                        Where-Object {$_.FullPathName} | Select-Object -ExpandProperty FullPathName)
	                                } else {
	                                    $backlogCount = $null
	                                    $backlogFiles = @()
	                                }
	
	                                # Put together data
	                                $properties = [ordered]@{
	                                    'Group' = $group.GroupName
	                                    'SourceComputer' = $srcComputer.ComputerName
	                                    'DestinationComputer' = $destComputer.ComputerName
	                                    'Folder' = $folder.FolderName
	                                    'BacklogCount' = $backlogCount
	                                    'BacklogFiles' = $backlogFiles
	                                }
	
	                                New-Object -TypeName psobject -Property $properties
	
	                                Write-Debug "Results gathered for $($srcComputer.ComputerName)=>$($destComputer.ComputerName) [$($folder.FolderName)]"
	
	                            } # =end=> foreach ($folder in $folders)
	
	                        } # =end=> if ($srcComputer.ComputerName -ne $destComputer.ComputerName)
	
	                    } # =end=> foreach ($destComputer in $destComputers)
	
	                } # =end=> foreach ($srcComputer in $srcComputers)
	
	            } #=end=> foreach ($group in $groups)
	
	        } # =end=> foreach ($name in $GroupName)
	
	    } # =end=> process
	
	    end { }
	
	}
	
	
	Export-ModuleMember -Function Get-CbnDfsrStats, Get-CbnDfsrBacklog
	