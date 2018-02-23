$swis = Connect-Swis -Hostname VBMPRMON843.cbn.local -Username NTD1\dscoop -Password '$%RTFGVB45rtfgvb'
$propertyName = 'Owning_Team'
$existingProperty = Get-SwisData $swis "SELECT Description, MaxLength FROM Orion.CustomProperty WHERE Table='VolumesCustomProperties' AND Field=@property'" @{property=$propertyName}
$values = Get-SwisData $swis "SELECT Value FROM Orion.CustomPropertyValues WHERE Table='VolumesCustomProperties' AND Field=@property" @{property=$propertyName}
$values += 'Purple'
Invoke-SwisVerb $swis Orion.NodesCustomProperties ModifyCustomProperty @($propertyName, $existingProperty.Description, $existingProperty.MaxLength, [string[]]$values)