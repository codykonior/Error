<#

.SYNOPSIS
Recurses an error or exception for detail.

.DESCRIPTION
Loops through information caught in catch blocks; from an ErrorRecord (and its InvocationInfo), 
to Exception, and InnerException.

.PARAMETER ErrorRecord
An error record or exception. By default the last error is used.

.PARAMETER AsString
Return an array of strings for printable output. By default we return an array of objects.

.PARAMETER Reverse
Returns items from outermost to innermost. By default we return items innermost to outermost.

.INPUTS
By default the last error; otherwise any error record or exception can be passed in by pipeline 
or first parameter.

.OUTPUTS
An array of objects, or an array of strings.

.EXAMPLE
Resolve-Error

Returns an array of nested objects describing the last error.

.EXAMPLE
$_ | Resolve-Error -AsString

Returns an array of strings describing the error in $_.

#>

function Resolve-Error {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $null,
        [switch] $AsString,
        [switch] $Reverse
    )

	if (!$ErrorRecord) {
        $ErrorRecord = (Get-Variable -Name Error -Scope 2).Value | Select -First 1
	}

    $records = @()
    
    if ($ErrorRecord.psobject.Properties["InnerException"] -and $ErrorRecord.InnerException) {
        $records += Resolve-Error $ErrorRecord.InnerException
    }
    if ($ErrorRecord.psobject.Properties["Exception"] -and $ErrorRecord.Exception) {
        $records += Resolve-Error $ErrorRecord.Exception
    }
    if ($ErrorRecord.psobject.Properties["InvocationInfo"] -and $ErrorRecord.InvocationInfo) {
        $records += Resolve-Error $ErrorRecord.InvocationInfo
    }
    $records += $ErrorRecord

    if ($Reverse) {
        $records = [Array]::Reverse($records)
    }
    if (!$AsString) {
        $records
    } else {
        $records | %{
            "*" * 40
            $_ | Select * | Out-String
        }
    }
}