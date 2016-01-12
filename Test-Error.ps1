<#

.SYNOPSIS
Recurses an error and runs tests for a true/false result.

.DESCRIPTION
Loops through information caught in catch blocks; from an ErrorRecord (and its InvocationInfo), 
to Exception, and InnerException.

Each of these is then compared to either a provided type (e.g. an Exception type) or a hash
table with a series of Name/Value property pairs.

.PARAMETER ErrorRecord
An error record or exception. By default the last error is used.

.PARAMETER Type
A type to compare against. If any item in the exploded ErrorRecord entry matches this type
then a $true result is returned.

.PARAMETER Test
A hash table with a series of Name/Value property pairs. If all of these exist on any item
in the exploded ErrorRecord entry then a $true result is returned.

.OUTPUTS
$true or $false.

.EXAMPLE
Test-Error Microsoft.SqlServer.Management.Sdk.Sfc.InvalidVersionEnumeratorException

Tests whether the ErrorRecord, Exception, InnerException, and so forth are this specific
type of Exception. When providing this do not put it into string quotes.

.EXAMPLE
Test-Error @{ Number = 954; Class = 14; State = 1 }

Tests whether the ErrorRecord, Exception, InnerException, and so forth have an item with
all 3 properties which match these conditions. In this case we are detecting a specific
kind of SqlError Exception that has a generic type.

#>

function Test-Error {
    [CmdletBinding(DefaultParameterSetName = "Type")]
    param (
        [Parameter(ValueFromPipeline = $true, ParameterSetName = "Type")]
        [Parameter(ValueFromPipeline = $true, ParameterSetName = "Test")]
        $ErrorRecord = $null,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Type")]
        [type] $Type,
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Test")]
        [hashtable] $Test
    )

	if (!$ErrorRecord) {
        $ErrorRecord = (Get-Variable -Name Error -Scope 2).Value | Select -First 1
	}

    $records = Resolve-Error $ErrorRecord
    
    switch ($PSCmdlet.ParameterSetName) {
        "Type" {
            if ($records | Where { $_ -is $Type }) {
                return $true
            }
        }

        "Test" {
            foreach ($record in $records) {
                $match = $true

                foreach ($thisTest in $Test.GetEnumerator()) {
                    if (!$record.psobject.Properties[$thisTest.Name] -or $record.$($thisTest.Name) -ne $thisTest.Value) {
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
