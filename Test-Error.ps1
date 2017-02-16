<#

.SYNOPSIS
Recurses an error record or exception object and returns true/false if a match is found.

.DESCRIPTION
Loops through information caught in catch blocks; from an ErrorRecord (and its InvocationInfo), to Exception, and InnerException.

These are then compared to a specific type, or, a hash table with a set of desired properties and settings.

.PARAMETER ErrorRecord
An error record or exception. By default the last error is used.

.PARAMETER Type
A type to compare against. If any item in the expanded ErrorRecord entry matches this typethen a $true result is returned.

.PARAMETER Property
A hash table with a series of Name/Value property pairs. If all of these exist on any object in the expanded ErrorRecord entry then a $true result is returned.

.OUTPUTS
$true or $false.

.EXAMPLE
Test-Error Microsoft.SqlServer.Management.Sdk.Sfc.InvalidVersionEnumeratorException

Tests whether the ErrorRecord, Exception, InnerException, and so forth are this specific type of Exception. When providing this do not put it into string quotes.

.EXAMPLE
Test-Error @{ Number = 954; Class = 14; State = 1; }

Tests whether the ErrorRecord, Exception, InnerException, and so forth have an item with all 3 properties which match these conditions.

#>

function Test-Error {
    [CmdletBinding(DefaultParameterSetName = "Type")]
    [OutputType("System.Boolean")]
    param (
        [Parameter(ValueFromPipeline = $true, ParameterSetName = "Type")]
        [Parameter(ValueFromPipeline = $true, ParameterSetName = "Property")]
        $ErrorRecord = $null,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Type")]
        [type] $Type,
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Property")]
        [hashtable] $Property
    )

	if (!$ErrorRecord) {
        $ErrorRecord = (Get-Variable -Name Error -Scope 2).Value | Select-Object -First 1
	}

    $expandedErrorRecord = Resolve-Error $ErrorRecord
    
    switch ($PSCmdlet.ParameterSetName) {
        "Type" {
            if ($expandedErrorRecord | Where-Object { $_ -is $Type }) {
                return $true
            }
        }

        "Property" {
            foreach ($record in $expandedErrorRecord) {
                $match = $true

                foreach ($thisProperty in $Property.GetEnumerator()) {
                    if (!$record.psobject.Properties[$thisProperty.Name] -or !$record.$($thisProperty.Name) -or $record.$($thisProperty.Name).ToString() -ne $thisProperty.Value) {
                        $match = $false
                        break
                    }
                }

                if ($match) {
                    return $true
                }
            }
        }
    }

    return $false
}
