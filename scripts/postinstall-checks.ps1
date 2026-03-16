param(
    [switch]$SkipNpmCiIfNodeModules,
    [switch]$KeepInfraUp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$StarterDefinitions = @(
    [pscustomobject]@{ Id = "agentic-clean-backend"; Key = "backend"; Path = "app/backend" },
    [pscustomobject]@{ Id = "agentic-dotnet-backend"; Key = "backend"; Path = "app/backend" },
    [pscustomobject]@{ Id = "agentic-react-spa"; Key = "web"; Path = "app/web" },
    [pscustomobject]@{ Id = "agentic-angular-spa"; Key = "web"; Path = "app/web" },
    [pscustomobject]@{ Id = "agentic-flutter-client"; Key = "client"; Path = "app/client" },
    [pscustomobject]@{ Id = "agentic-api-contracts-api"; Key = "contracts"; Path = "app/contracts" },
    [pscustomobject]@{ Id = "agentic-postgres-dev"; Key = "infra"; Path = "app/infra" },
    [pscustomobject]@{ Id = "agentic-fullstack-composition"; Key = "composition"; Path = "app/composition" }
)

$CheckResults = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Starter,
        [string]$Check,
        [ValidateSet("PASS","FAIL","SKIP")]
        [string]$Status,
        [string]$Details
    )

    $entry = [pscustomobject]@{
        Starter = $Starter
        Check = $Check
        Status = $Status
        Details = $Details
    }

    $CheckResults.Add($entry) | Out-Null
    Write-Host ("[{0}] {1} :: {2} - {3}" -f $Status, $Starter, $Check, $Details)
}

function Test-CommandAvailable {
    param([string]$Name)
    return $null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function Invoke-Step {
    param(
        [string]$Starter,
        [string]$Check,
        [string]$WorkingDirectory,
        [string]$Command,
        [string[]]$Arguments
    )

    Push-Location $WorkingDirectory
    try {
        $output = & $Command @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }

        if ($exitCode -eq 0) {
            Add-Result -Starter $Starter -Check $Check -Status "PASS" -Details "Command succeeded: $Command $($Arguments -join ' ')"
            return $true
        }

        $preview = @($output | Select-Object -Last 3) -join " | "
        Add-Result -Starter $Starter -Check $Check -Status "FAIL" -Details "Exit code $exitCode. $preview"
        return $false
    }
    catch {
        Add-Result -Starter $Starter -Check $Check -Status "FAIL" -Details ("Exception: " + $_.Exception.Message)
        return $false
    }
    finally {
        Pop-Location
    }
}

function Read-JsonFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return $null
    }
}

function Test-NpmScript {
    param(
        [object]$PackageJson,
        [string]$ScriptName
    )

    if ($null -eq $PackageJson) { return $false }
    if ($null -eq $PackageJson.scripts) { return $false }

    $names = @($PackageJson.scripts.PSObject.Properties.Name)
    return $names -contains $ScriptName
}

function Test-PackageDependency {
    param(
        [object]$PackageJson,
        [string]$DependencyName
    )

    if ($null -eq $PackageJson) { return $false }

    $deps = @()
    if ($null -ne $PackageJson.dependencies) {
        $deps += @($PackageJson.dependencies.PSObject.Properties.Name)
    }
    if ($null -ne $PackageJson.devDependencies) {
        $deps += @($PackageJson.devDependencies.PSObject.Properties.Name)
    }

    return $deps -contains $DependencyName
}

function Get-BootstrapInfo {
    $candidatePaths = @(
        (Join-Path $RepoRoot "PROJECT-BOOTSTRAP.yaml"),
        (Join-Path $RepoRoot "PROJECT-BOOTSTRAP.example.yaml")
    )

    foreach ($path in $candidatePaths) {
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $starters = @{}
        $inStarters = $false

        foreach ($line in (Get-Content -LiteralPath $path)) {
            if ($line -match "^\s*starters\s*:\s*$") {
                $inStarters = $true
                continue
            }

            if ($inStarters -and $line -match "^\S") {
                break
            }

            if ($inStarters -and $line -match "^\s+([a-zA-Z0-9_-]+)\s*:\s*(.*?)\s*$") {
                $k = $matches[1]
                $v = $matches[2]
                $starters[$k] = $v
            }
        }

        return [pscustomobject]@{
            Source = $path
            Starters = $starters
        }
    }

    return $null
}

function Test-StarterSelected {
    param(
        [object]$BootstrapInfo,
        [string]$StarterKey
    )

    if ($null -eq $BootstrapInfo) {
        return $false
    }
    if (-not $BootstrapInfo.Starters.ContainsKey($StarterKey)) {
        return $false
    }

    $raw = "$($BootstrapInfo.Starters[$StarterKey])".Trim()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $false }

    $normalized = $raw.Trim().Trim("'").Trim('"')
    if ($normalized -in @("null","~","false","False","FALSE")) {
        return $false
    }

    return $true
}

function Get-ComposeFiles {
    param([string]$Path)

    $names = @(
        "docker-compose.yml",
        "docker-compose.yaml",
        "compose.yml",
        "compose.yaml"
    )

    $files = @(
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $names -contains $_.Name.ToLowerInvariant() } |
            Select-Object -ExpandProperty FullName
    )

    return @($files | Sort-Object -Unique)
}

function Validate-JsStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    $packageJsonPath = Join-Path $StarterPath "package.json"
    if (-not (Test-Path -LiteralPath $packageJsonPath)) {
        Add-Result -Starter $StarterId -Check "package.json" -Status "SKIP" -Details "No package.json found"
        return
    }
    Add-Result -Starter $StarterId -Check "package.json" -Status "PASS" -Details "Found"

    $hasNode = Test-CommandAvailable -Name "node"
    $hasNpm = Test-CommandAvailable -Name "npm"

    if ($hasNode) {
        Add-Result -Starter $StarterId -Check "node availability" -Status "PASS" -Details "node detected"
    } else {
        Add-Result -Starter $StarterId -Check "node availability" -Status "SKIP" -Details "node not detected"
    }

    if ($hasNpm) {
        Add-Result -Starter $StarterId -Check "npm availability" -Status "PASS" -Details "npm detected"
    } else {
        Add-Result -Starter $StarterId -Check "npm availability" -Status "SKIP" -Details "npm not detected"
    }

    if (-not ($hasNode -and $hasNpm)) {
        Add-Result -Starter $StarterId -Check "npm checks" -Status "SKIP" -Details "Node/npm not fully available"
        return
    }

    $nodeModules = Join-Path $StarterPath "node_modules"
    if ($SkipNpmCiIfNodeModules -and (Test-Path -LiteralPath $nodeModules)) {
        Add-Result -Starter $StarterId -Check "npm ci" -Status "SKIP" -Details "Skipped due to -SkipNpmCiIfNodeModules and existing node_modules"
    } else {
        [void](Invoke-Step -Starter $StarterId -Check "npm ci" -WorkingDirectory $StarterPath -Command "npm" -Arguments @("ci","--no-audit","--fund=false"))
    }

    $pkg = Read-JsonFile -Path $packageJsonPath
    if ($null -eq $pkg) {
        Add-Result -Starter $StarterId -Check "package.json parsing" -Status "SKIP" -Details "Could not parse JSON; skipping script discovery"
        return
    }

    $scriptCandidates = @("build","test","smoke","lint","typecheck")
    foreach ($scriptName in $scriptCandidates) {
        if (Test-NpmScript -PackageJson $pkg -ScriptName $scriptName) {
            [void](Invoke-Step -Starter $StarterId -Check ("npm run " + $scriptName) -WorkingDirectory $StarterPath -Command "npm" -Arguments @("run",$scriptName))
        } else {
            Add-Result -Starter $StarterId -Check ("npm run " + $scriptName) -Status "SKIP" -Details "Script not defined"
        }
    }
}

function Validate-DotnetStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    if (-not (Test-CommandAvailable -Name "dotnet")) {
        Add-Result -Starter $StarterId -Check "dotnet availability" -Status "SKIP" -Details "dotnet CLI not found"
        return
    }
    Add-Result -Starter $StarterId -Check "dotnet availability" -Status "PASS" -Details "dotnet detected"

    $solution = Get-ChildItem -LiteralPath $StarterPath -Filter "*.sln" -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1

    $project = Get-ChildItem -LiteralPath $StarterPath -Filter "*.csproj" -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1

    $targetPath = $null
    if ($null -ne $solution) {
        $targetPath = $solution.FullName
        Add-Result -Starter $StarterId -Check "dotnet target discovery" -Status "PASS" -Details ("Using solution: " + $solution.Name)
    } elseif ($null -ne $project) {
        $targetPath = $project.FullName
        Add-Result -Starter $StarterId -Check "dotnet target discovery" -Status "PASS" -Details ("Using project: " + $project.Name)
    } else {
        Add-Result -Starter $StarterId -Check "dotnet target discovery" -Status "SKIP" -Details "No .sln or .csproj file found"
        return
    }

    [void](Invoke-Step -Starter $StarterId -Check "dotnet restore" -WorkingDirectory $StarterPath -Command "dotnet" -Arguments @("restore",$targetPath))
    [void](Invoke-Step -Starter $StarterId -Check "dotnet build" -WorkingDirectory $StarterPath -Command "dotnet" -Arguments @("build",$targetPath,"--no-restore"))

    $testProjects = @(
        Get-ChildItem -LiteralPath $StarterPath -Filter "*.csproj" -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match "(?i)test" -or $_.FullName -match "(?i)[\\/]tests?[\\/]" }
    )

    if (@($testProjects).Count -gt 0) {
        [void](Invoke-Step -Starter $StarterId -Check "dotnet test" -WorkingDirectory $StarterPath -Command "dotnet" -Arguments @("test",$targetPath,"--no-build"))
    } else {
        Add-Result -Starter $StarterId -Check "dotnet test" -Status "SKIP" -Details "No test project discovered"
    }
}

function Validate-ContractsStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    $specs = @(
        Get-ChildItem -LiteralPath $StarterPath -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.Extension -in @(".yaml",".yml",".json")) -and
                ($_.Name -match "(?i)(openapi|swagger)")
            } |
            Select-Object -ExpandProperty FullName
    )

    if (@($specs).Count -eq 0) {
        Add-Result -Starter $StarterId -Check "OpenAPI spec discovery" -Status "SKIP" -Details "No OpenAPI/Swagger spec found"
        return
    }
    Add-Result -Starter $StarterId -Check "OpenAPI spec discovery" -Status "PASS" -Details ("Found " + @($specs).Count + " file(s)")

    $packageJsonPath = Join-Path $StarterPath "package.json"
    $pkg = Read-JsonFile -Path $packageJsonPath
    $hasNode = Test-CommandAvailable -Name "node"
    $hasNpm = Test-CommandAvailable -Name "npm"

    $npmValidationScripts = @("validate:api","validate:contracts","lint:contracts","lint","validate")
    $selectedScript = $null
    foreach ($candidate in $npmValidationScripts) {
        if (Test-NpmScript -PackageJson $pkg -ScriptName $candidate) {
            $selectedScript = $candidate
            break
        }
    }

    if ($null -ne $selectedScript -and $hasNode -and $hasNpm) {
        [void](Invoke-Step -Starter $StarterId -Check ("npm run " + $selectedScript) -WorkingDirectory $StarterPath -Command "npm" -Arguments @("run",$selectedScript))
        return
    }

    $hasSpectral = Test-CommandAvailable -Name "spectral"
    if ($hasSpectral) {
        foreach ($spec in $specs) {
            [void](Invoke-Step -Starter $StarterId -Check ("spectral lint " + (Split-Path -Leaf $spec)) -WorkingDirectory $StarterPath -Command "spectral" -Arguments @("lint",$spec))
        }
        return
    }

    $hasNpx = Test-CommandAvailable -Name "npx"
    $spectralDeclared = Test-PackageDependency -PackageJson $pkg -DependencyName "@stoplight/spectral-cli"
    if ($hasNode -and $hasNpx -and $spectralDeclared) {
        foreach ($spec in $specs) {
            [void](Invoke-Step -Starter $StarterId -Check ("npx spectral lint " + (Split-Path -Leaf $spec)) -WorkingDirectory $StarterPath -Command "npx" -Arguments @("--no-install","spectral","lint",$spec))
        }
        return
    }

    Add-Result -Starter $StarterId -Check "Contracts validation tooling" -Status "SKIP" -Details "Spec found, but no safely discoverable validator is available"
}

function Validate-ComposeStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath,
        [switch]$RunLifecycle
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    if (-not (Test-CommandAvailable -Name "docker")) {
        Add-Result -Starter $StarterId -Check "docker availability" -Status "SKIP" -Details "docker CLI not found"
        return
    }
    Add-Result -Starter $StarterId -Check "docker availability" -Status "PASS" -Details "docker detected"

    $dockerInfoExit = 1
    Push-Location $StarterPath
    try {
        & docker info *> $null 2>&1
        $dockerInfoExit = $LASTEXITCODE
        if ($null -eq $dockerInfoExit) { $dockerInfoExit = 1 }
    }
    finally {
        Pop-Location
    }

    if ($dockerInfoExit -ne 0) {
        Add-Result -Starter $StarterId -Check "docker daemon" -Status "SKIP" -Details "docker daemon unreachable"
        return
    }
    Add-Result -Starter $StarterId -Check "docker daemon" -Status "PASS" -Details "docker daemon reachable"

    $composeFiles = Get-ComposeFiles -Path $StarterPath
    if (@($composeFiles).Count -eq 0) {
        Add-Result -Starter $StarterId -Check "compose file discovery" -Status "SKIP" -Details "No compose file found"
        return
    }
    Add-Result -Starter $StarterId -Check "compose file discovery" -Status "PASS" -Details ("Found " + @($composeFiles).Count + " file(s)")

    foreach ($composeFile in $composeFiles) {
        [void](Invoke-Step -Starter $StarterId -Check ("docker compose config: " + (Split-Path -Leaf $composeFile)) -WorkingDirectory $StarterPath -Command "docker" -Arguments @("compose","-f",$composeFile,"config","-q"))
    }

    if (-not $RunLifecycle) {
        Add-Result -Starter $StarterId -Check "compose lifecycle checks" -Status "SKIP" -Details "Not enabled for this starter"
        return
    }

    $primary = $composeFiles[0]
    [void](Invoke-Step -Starter $StarterId -Check "docker compose up -d" -WorkingDirectory $StarterPath -Command "docker" -Arguments @("compose","-f",$primary,"up","-d"))
    [void](Invoke-Step -Starter $StarterId -Check "docker compose ps" -WorkingDirectory $StarterPath -Command "docker" -Arguments @("compose","-f",$primary,"ps"))

    if ($KeepInfraUp) {
        Add-Result -Starter $StarterId -Check "docker compose down" -Status "SKIP" -Details "Skipped due to -KeepInfraUp"
    } else {
        [void](Invoke-Step -Starter $StarterId -Check "docker compose down" -WorkingDirectory $StarterPath -Command "docker" -Arguments @("compose","-f",$primary,"down","--remove-orphans"))
    }
}

function Validate-FlutterStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    $pubspecPath = Join-Path $StarterPath "pubspec.yaml"
    if (-not (Test-Path -LiteralPath $pubspecPath)) {
        Add-Result -Starter $StarterId -Check "Flutter project discovery" -Status "SKIP" -Details "pubspec.yaml not found"
        return
    }
    Add-Result -Starter $StarterId -Check "Flutter project discovery" -Status "PASS" -Details "pubspec.yaml found"

    $hasFlutter = Test-CommandAvailable -Name "flutter"
    $hasDart = Test-CommandAvailable -Name "dart"

    if (-not $hasFlutter -and -not $hasDart) {
        Add-Result -Starter $StarterId -Check "Flutter/Dart availability" -Status "SKIP" -Details "Neither flutter nor dart detected"
        return
    }

    if ($hasFlutter) {
        [void](Invoke-Step -Starter $StarterId -Check "flutter --version" -WorkingDirectory $StarterPath -Command "flutter" -Arguments @("--version"))

        $pkgConfig = Join-Path $StarterPath ".dart_tool/package_config.json"
        if (Test-Path -LiteralPath $pkgConfig) {
            [void](Invoke-Step -Starter $StarterId -Check "flutter analyze" -WorkingDirectory $StarterPath -Command "flutter" -Arguments @("analyze"))
        } else {
            Add-Result -Starter $StarterId -Check "flutter analyze" -Status "SKIP" -Details "Dependencies not restored (.dart_tool/package_config.json missing)"
        }
    } else {
        [void](Invoke-Step -Starter $StarterId -Check "dart --version" -WorkingDirectory $StarterPath -Command "dart" -Arguments @("--version"))
        Add-Result -Starter $StarterId -Check "Flutter-specific checks" -Status "SKIP" -Details "flutter not detected"
    }
}

function Get-StarterOverallStatus {
    param([string]$StarterId)

    $rows = @($CheckResults | Where-Object { $_.Starter -eq $StarterId })
    if (@($rows).Count -eq 0) { return "SKIP" }

    $fails = @($rows | Where-Object { $_.Status -eq "FAIL" }).Count
    if ($fails -gt 0) { return "FAIL" }

    $passes = @($rows | Where-Object { $_.Status -eq "PASS" }).Count
    if ($passes -gt 0) { return "PASS" }

    return "SKIP"
}

Write-Host "============================================================"
Write-Host "Template Post-Install Validation"
Write-Host "Repository: $RepoRoot"
Write-Host "SkipNpmCiIfNodeModules: $SkipNpmCiIfNodeModules"
Write-Host "KeepInfraUp: $KeepInfraUp"
Write-Host "============================================================"

$bootstrapInfo = Get-BootstrapInfo
if ($null -ne $bootstrapInfo) {
    Write-Host ("Bootstrap source detected: " + $bootstrapInfo.Source)
} else {
    Write-Host "No bootstrap file detected. Falling back to path discovery only."
}

foreach ($starter in $StarterDefinitions) {
    $starterPath = Join-Path $RepoRoot $starter.Path
    $pathExists = Test-Path -LiteralPath $starterPath
    $selected = Test-StarterSelected -BootstrapInfo $bootstrapInfo -StarterKey $starter.Key

    if (-not $selected -and -not $pathExists) {
        Add-Result -Starter $starter.Id -Check "starter selection/install state" -Status "SKIP" -Details "Not selected in bootstrap and canonical path not found"
        continue
    }

    if ($selected -and -not $pathExists) {
        Add-Result -Starter $starter.Id -Check "starter selection/install state" -Status "SKIP" -Details "Selected in bootstrap but canonical path not found"
        continue
    }

    switch ($starter.Id) {
        "agentic-clean-backend" {
            Validate-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-dotnet-backend" {
            Validate-DotnetStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-react-spa" {
            Validate-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-angular-spa" {
            Validate-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-flutter-client" {
            Validate-FlutterStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-api-contracts-api" {
            Validate-ContractsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-postgres-dev" {
            Validate-ComposeStarter -StarterId $starter.Id -StarterPath $starterPath -RunLifecycle
        }
        "agentic-fullstack-composition" {
            Validate-ComposeStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        default {
            Add-Result -Starter $starter.Id -Check "starter dispatch" -Status "SKIP" -Details "No validator registered"
        }
    }
}

Write-Host ""
Write-Host "======================== Per-Starter Summary ========================"
$summaryRows = @()
foreach ($starter in $StarterDefinitions) {
    $rows = @($CheckResults | Where-Object { $_.Starter -eq $starter.Id })
    $summaryRows += [pscustomobject]@{
        Starter = $starter.Id
        PASS = @($rows | Where-Object { $_.Status -eq "PASS" }).Count
        FAIL = @($rows | Where-Object { $_.Status -eq "FAIL" }).Count
        SKIP = @($rows | Where-Object { $_.Status -eq "SKIP" }).Count
        FinalStatus = Get-StarterOverallStatus -StarterId $starter.Id
    }
}
$summaryRows | Format-Table -AutoSize

$totalPass = @($CheckResults | Where-Object { $_.Status -eq "PASS" }).Count
$totalFail = @($CheckResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalSkip = @($CheckResults | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host ""
Write-Host "=========================== Overall Result ==========================="
Write-Host ("PASS: {0}  FAIL: {1}  SKIP: {2}" -f $totalPass, $totalFail, $totalSkip)

if ($totalFail -gt 0) {
    Write-Host "OVERALL: FAIL"
    exit 1
}

Write-Host "OVERALL: PASS (no FAIL results)"
exit 0