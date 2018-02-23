# Copyright © 2008, Microsoft Corporation. All rights reserved.

trap { break }

# Load Common Library
. .\CL_Utility.ps1
. .\CL_RunDiagnosticScript.ps1

# Main diagnostic flow
RunDiagnosticScript .\TS_Deprecated.ps1

