<#

.SYNOPSIS
Recurses an error record or exception object to flatten nested objects.

.DESCRIPTION
Loops through information caught in catch blocks; from an ErrorRecord (and its InvocationInfo), to Exception, and InnerException.

.PARAMETER ErrorRecord
An error record or exception. By default the last error is used.

.PARAMETER AsString
Return an array of strings for printable output. By default we return an array of objects.

.PARAMETER Reverse
Returns items from outermost to innermost. By default we return items innermost to outermost.

.INPUTS
By default the last error; otherwise any error record or exception can be passed in by pipeline or first parameter.

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
        # This is a bit iffy, if it's a nested module it needs $_ as $Error will not be populated yet.
        # If it's not a nested module then it needs a Get-Variable -Scope 2 
        $ErrorRecord = (Get-Variable -Name Error -Scope 2).Value | Select-Object -First 1
        <#
        if ($Error.Count -gt 0) {
            $ErrorRecord = $Error[0]
        } else {
            $ErrorRecord = $_
        }
        #>
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
        $string = @()
        $first = $true

        $records | ForEach-Object {
            if ($first) {
                $string += "=" * 40
                $first = $false
            } else {
                $string += "*" * 5
            }
            $string += $_ | Select-Object * | Out-String
        }

        $string += ""

        $stack = Get-PSCallStack
        for ($i = $stack.Count - 1; $i -ge 1; $i--) { 
            $string += "-" * 5
            $string += "Depth:     $i"
            $string += "Function:  $($stack[$i].FunctionName)"
            # In some highly threaded contexts this doesn't appear?
            if ($stack[$i].PSObject.Properties["Arguments"]) {
                try {
                    $lines = $stack[$i].Arguments -split [Environment]::NewLine
                    if ($lines.Count -gt 9) {
                        $lines = $lines[0..8] -join [Environment]::NewLine
                    } else {
                        $lines = $lines -join [Environment]::NewLine
                    }
                    $string += "Arguments: $lines"
                } catch {
                    # It wasn't meant to be
                }
            }
            $string += "Line:      $($stack[$i].ScriptLineNumber)"
            try {
                [array] $lines = $stack[$i].Position.Text -split [Environment]::NewLine
                $firstLine = ($stack[$i].ScriptLineNumber - 4) - 1
                $lastLine = ($stack[$i].ScriptLineNumber + 4) - 1
                if ($firstLine -le 0) {
                    $firstLine = 0
                }
                if ($lastLine -gt ($lines.Count - 1)) {
                    $lastLine = $lines.Count - 1
                }
                $lines = $lines[$firstLine..$lastLine] 
                $lines = $lines -join [Environment]::NewLine
                $string += "Command:   $lines"
            } catch {
                # It wasn't meant to be
            }
        }
        $string += ""
        $string += ""

        $string += "=" * 40
        $string -join [System.Environment]::NewLine
    }
}