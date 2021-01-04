# Script root
$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

# Read configuration file
function Get-IniContent ($filePath)
{
    $ini = @{}
    switch -regex -file $FilePath
    {
        "^\[(.+)\]$" # Section
        {
            $section = $matches[1]
            $ini[$section] = @{}
            $CommentCount = 0
        }
        "^(;.*)$" # Comment
        {
            if (!($section))
            {
                $section = "No-Section"
                $ini[$section] = @{}
            }
            $value = $matches[1]
            $CommentCount = $CommentCount + 1
            $name = "Comment" + $CommentCount
            $ini[$section][$name] = $value
        }
        "(.+?)\s*=\s*(.*)" # Key
        {
            if (!($section))
            {
                $section = "No-Section"
                $ini[$section] = @{}
            }
            $name,$value = $matches[1..2]
            $ini[$section][$name] = $value
        }
    }
    return $ini
}

$buildConfig = Get-IniContent(Join-Path $PSScriptRoot "cake.config")

# Make sure tools folder exists
$ToolPath =  $buildConfig["Paths"]["Tools"]
if (!(Test-Path $ToolPath)) {
    Write-Verbose "Creating tools directory..."
    New-Item -Path $ToolPath -Type directory | out-null
}

Push-Location
Set-Location build\source

Write-Host "Preparing Cake.Frosting build runner..."
Invoke-Expression "dotnet restore"
if($LASTEXITCODE -ne 0) {
    Pop-Location;
    exit $LASTEXITCODE;
}

Write-Host "Running Cake.Frosting build runner..."
Write-Host "dotnet run -- $args"
Invoke-Expression "dotnet run -- $args"
if($LASTEXITCODE -ne 0) {
    Pop-Location;
    exit $LASTEXITCODE;
}

Pop-Location
