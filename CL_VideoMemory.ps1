# Copyright © 2008, Microsoft Corporation. All rights reserved.


# constant variable
[double]$script:targetFramesPerSecond = 30.0
[double]$script:fltEpsilon = 0.0000001
[double]$script:gpuBudget = 0.65
[double]$script:assumedAspectRatio = 4.0 / 3.0
[int]$script:bytesPerPixel = 4
[int]$script:numFullScreenBuffersForTransparent = 3
[int]$script:numFullScreenBuffersForOpaque = 3
[int]$script:numSingleMonitorBuffersForTransparent = 2
[int]$script:numSingleMonitorBuffersForOpaque = 0
[double]$script:allowedMemoryBudgetFraction = 0.50
[Array]$script:dragMovePolynomials = (0.4594, 18.783, 196),(0.4594, 1538.1, 196),(0.7061, 23.377, 196),(0.7061, 1922.5, 196)

#variable
[int]$script:largestMonitorWidth = 0
[int]$script:largestMonitorHeight = 0
[int]$script:numMonitors = 1
[int]$script:totalPixelArea = 0

#Initiatie resolution data
function InitiateResolutionData([int]$priMonWidth = $(throw "No primary monitor resolution is specified"), [int]$priMonHeight = $(throw "No primary monitor resolution is specified"), [int]$secMonWidth = 0, [int]$secMonHeight = 0)
{
    #compute the data of resolutin
    [int]$priTotalPixels = $priMonWidth * $priMonHeight
    [int]$secTotalPixels = $secMonWidth * $secMonHeight
    $script:totalPixelArea = $priTotalPixels + $secTotalPixels

    if ($priTotalPixels -gt $secTotalPixels)
    {
        $script:largestMonitorHeight = $priMonHeight
        $script:largestMonitorWidth = $priMonWidth
    }
    else
    {
        $script:largestMonitorHeight = $secMonHeight;
        $script:largestMonitorWidth = $secMonWidth;
    }

    if ($secTotalPixels -eq 0)
    {
        $script:numMonitors = 1
    }
    else
    {
        $script:numMonitors = 2
    }
}

#According to Aero Model coefficiants compute the pixel required
function Evaluate([Array]$dragMovePolynomials, [int]$longerEdge )
{
    return $dragMovePolynomials[0] * $longerEdge * $longerEdge + $dragMovePolynomials[1] * $longerEdge + $dragMovePolynomials[2]
}

#Check if two double values are effectivly equal
function IsCloseDouble([double]$a, [double]$b)
{
    return ([System.Math]::Abs($a - $b) -lt $script:fltEpsilon * 100)
}

#Check the performance requirements
function CheckPerformance([bool]$transparency, [double]$pVideoMemoryBandwidth)
{
    [double]$longerEdge = 0
    [double]$shorterEdge = 0
    if ($script:largestMonitorWidth -gt $script:largestMonitorHeight)
    {
        $longerEdge = $script:largestMonitorWidth
        $shorterEdge = $script:largestMonitorHeight
    }
    else
    {
        $longerEdge = $script:largestMonitorHeight
        $shorterEdge = $script:largestMonitorWidth
    }

    if (-not (IsCloseDouble ($shorterEdge * $script:assumedAspectRatio) $longerEdge))

    {
        [double]$area = $longerEdge * $shorterEdge
        $longerEdge = [System.Math]::Sqrt($area * $script:assumedAspectRatio)
        $shorterEdge = $longerEdge / $script:assumedAspectRatio
    }

    [int]$idx = 0
    if ($script:numMonitors -gt 1 -and $transparency)
    {
        $idx = 3
    }
    elseif($script:numMonitors -gt 1 -and -not $transparency)
    {
        $idx = 2
    }
    elseif($script:numMonitors -eq 1 -and $transparency)
    {
        $idx = 1
    }
    [double]$pixelsRequired = Evaluate $script:dragMovePolynomials[$idx] $longerEdge
    [double]$gpuTimePerFrame = ($script:bytesPerPixel * $pixelsRequired) / $pVideoMemoryBandwidth
    [double]$gpuTimePerSecond = $gpuTimePerFrame * $script:targetFramesPerSecond
    return $gpuTimePerSecond -le $script:gpuBudget
}

#Compute the lowest passing performance value
function ComputeForLowestPassingPerformance([bool]$transparency)
{
    [long]$top = 5000
    [long]$bottom = 0

    do
    {
        [double]$douVal = ($bottom + ($top - $bottom) / 2) * 1024 * 1024
        #$perf = CheckPerformance $transparency $douVal
        if (CheckPerformance $transparency $douVal)
        {
             $top = $top - (($top - $bottom) / 2)
        }
        else
        {
            $bottom = $bottom + (($top - $bottom) / 2)
        }
    } while (($top - $bottom) -gt 1);
    return $top;
}

#Check the video memory requirements
function CheckVideoMemory([bool]$transparency, [double]$pTotalVideoMemory)
{
    [int]$numFullScreenBuffers = 0
    if ($transparency)
    {
        $numFullScreenBuffers = $script:numFullScreenBuffersForTransparent
    }
    else
    {
        $numFullScreenBuffers = $script:numFullScreenBuffersForOpaque
    }
    [int]$bufferPixels = $script:totalPixelArea * $numFullScreenBuffers

    [int]$numSingleMonitorBuffers = 0
    if ($transparency)
    {
        $numSingleMonitorBuffers= $script:numSingleMonitorBuffersForTransparent
    }
    else
    {
        $numSingleMonitorBuffers= $script:numSingleMonitorBuffersForOpaque
    }
    [int]$largestMonitorArea = $largestMonitorWidth * $largestMonitorHeight
    $bufferPixels += $largestMonitorArea * $numSingleMonitorBuffers

    [int]$bytesNeeded = $bufferPixels * $script:bytesPerPixel

    [double]$bytesBudget = $pTotalVideoMemory * $script:allowedMemoryBudgetFraction;

    return $bytesNeeded -le $bytesBudget
}

#Compute the lowest passing memory size
function ComputeForLowestPassingMemSize([bool]$transparency)
{
    [int]$top = 1024;
    [int]$bottom = 0

    do {
	    [double]$douVal = ($bottom + ($top - $bottom) / 2) * 1024 * 1024
        if (CheckVideoMemory $transparency $douVal)
        {
            $top = $top - (($top - $bottom) / 2)
        }
        else
        {
            $bottom = $bottom + (($top - $bottom) / 2)
        }
    } while(($top - $bottom) -gt 1);

    return $top
}
