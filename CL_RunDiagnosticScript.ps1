# Copyright © 2008, Microsoft Corporation. All rights reserved.


function RunDiagnosticScript([string]$scriptPath = $(throw "No diagnostic script is specified"))
{
    if(-not (Test-Path $scriptPath))
    {
        throw "Can't find diagnostic script"
    }

    $result = &($scriptPath)
    if($result -is [bool])
    {
        return [bool]$result
    }
    else
    {
        return $false
    }
}
