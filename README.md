# Error PowerShell Module by Cody Konior

There is no logo yet.

[![Build status](https://ci.appveyor.com/api/projects/status/9hnd4hyqaaq10s0i?svg=true)](https://ci.appveyor.com/project/codykonior/error)

Read the [CHANGELOG][3]

## Description

PowerShell provides a simple try { } catch (type) { } exception handling mechanic, but
due to the way exceptions are often wrapped in other exceptions and error records, it
is often the case that these will be missed.

Furthermore when catching SQL Server exceptions these have an object nested at an
arbitrary depth with important properties to indicate what kind of exception it is
(such as severity, error number, message, state).

Together these two things lead to extremely long and complex catch blocks. To address
this a Test-Error function is provided.

- Test-Error -Type to identify an exception based on a type; matching not just the
    top object type but other common objects nested within it.
- Test-Error -Property to identify an exception based on a hash table of matching
    properties on any single nested object within the error.

Another function, Resolve-Error, either returns an expanded view of nested objects
in an exception, and optionally, converts this into a verbose (but almost readable)
string output suitable for use in stack traces.

## Installation

- `Install-Module Error`

## Major functions

- `Resolve-Error`

## Examples

``` powershell
    try {
        $ErrorActionPreference = "Stop"
        Invoke-Sqlcmd -ServerInstance C1N1 -Query "Select 1/0" -IncludeSqlUserErrors
    } catch [System.Data.SqlClient.SqlException] {
        "Caught"
    }
```

No output. This is because that exception type, despite being thrown, was buried.

``` powershell
try {
    $ErrorActionPreference = "Stop"
    Invoke-Sqlcmd -ServerInstance C1N1 -Query "Select 1/0" -IncludeSqlUserErrors
} catch {
    if (Test-Error System.Data.SqlClient.SqlException) {
        "Caught"
    } else {
        "Not caught"
    }
}
```

Results in a Caught output because we successfully matched a nested exception.

``` powershell
try {
    $ErrorActionPreference = "Stop"
    Invoke-Sqlcmd -ServerInstance C1N1 -Query "Select 1/0" -IncludeSqlUserErrors
} catch {
    if (Test-Error @{ Class = 16; Number = 8134; }) {
        "Caught"
    } else {
        "Not caught"
    }
}
```

Results in a Caught output because we successfully matched a set of properties.

``` powershell
try {
    $ErrorActionPreference = "Stop"
    Invoke-Sqlcmd -ServerInstance C1N1 -Query "Select 1/0" -IncludeSqlUserErrors
} catch {
    Resolve-Error $_ -AsString
}
```

A detailed string-style expansion of exceptions, error records, and the stack trace.

[1]: Images/errpr.ai.svg
[2]: Images/error.gif
[3]: CHANGELOG.md
