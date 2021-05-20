
function Get-SqlPassword {
    param(
        [Parameter(Mandatory=$true)]
        [string] $EnvFile
    )

    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*SQL_SA_PASSWORD\s*=\s*([^\s]+)') {
            return $matches[1]
        }
    }

    return ""
}

$scripts_dir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")
$repo_root_dir = [System.IO.Path]::GetFullPath("$PSScriptRoot\..\..")

# Initialize environment variables file
if (-not $(Test-Path -Path "$repo_root_dir\.env")) {
    & "$scripts_dir\init-dot-env.ps1" -TemplateFile "$PSScriptRoot\env-template" | Out-File  "$repo_root_dir\.env" -Encoding ascii
}

# # Ensure local copy of the env file in the webapi project folder
Copy-Item -Path "$repo_root_dir\.env" -Destination "$repo_root_dir\services\webapi\src\development.env" -Force

# Start SQL Server
& docker-compose --env-file "$repo_root_dir\.env" -f "$repo_root_dir\services\db\docker-compose-db.yml" up -d

$sql_password = Get-SqlPassword "$repo_root_dir\.env"
if (!$sql_password) {
    throw "SQL Server password not found in environment file"
}

$connected = $false
foreach ($_ in 1..10) {
    & sqlcmd -S localhost -U sa -P $sql_password -d master -Q 'select * from sys.databases' | Out-Null
    if ($?) {
        Write-Host "SQL Server ready"
        $connected = $true
        break
    }
    else {
        Write-Host "SQL Server not ready yet..."
        Start-Sleep -Seconds 5
    }
}

if (! $connected) {
    throw "Could not connect to SQL Server"
}

& sqlcmd -S localhost -U sa -P $sql_password -i "$scripts_dir\webapi\create-structure.sql"
& sqlcmd -S localhost -U sa -P $sql_password -d webapidb -i "$scripts_dir\webapi\sample-data.sql"
