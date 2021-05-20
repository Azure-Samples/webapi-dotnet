
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $TemplateFile
)

$random_vals = @{}
$lcase = ([byte][char]'a'..[byte][char]'z') 
$ucase = ([byte][char]'A'..[byte][char]'Z') 
$numbers = ([byte][char]'0'..[byte][char]'9')

function getRandomVal {
    param (
        [string] $name
    )
    if ($random_vals.ContainsKey($name)) {
        return $random_vals[$name]
    }
    else {
        $randval = -join (
            @($lcase | Get-Random -Count 5 | ForEach-Object {[char]$_}) +
            @($ucase | Get-Random -Count 5 | ForEach-Object {[char]$_}) +
            @($numbers | Get-Random -Count 4 | ForEach-Object {[char]$_})
        )
        $randval = ($randval.ToCharArray() | Get-Random -Count $randval.Length) -join ''
        $random_vals[$name] = $randval
        return $randval
    }
}

Get-Content $TemplateFile | ForEach-Object {
    if ($_ -match '^\s*(\w+)=(.+)$') {
        $envvar_name = $matches[1]
        $envvar_value = $matches[2]

        if ($envvar_value -match '__Random\((\w+)\)') {
            $random_tag = $matches[0]
            $random_name = $matches[1]
            $random_val = getRandomVal $random_name

            $envvar_value_final = $envvar_value.Replace($random_tag, $random_val)
            Write-Output ('{0}={1}' -f @($envvar_name, $envvar_value_final))
        }
        else {
            Write-Output $_
        }
    }
    else {
        Write-Output $_
    }
}