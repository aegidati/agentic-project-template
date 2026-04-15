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
    [pscustomobject]@{ Id = "agentic-react-native"; Key = "client"; Path = "app/client" },
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

function Test-InstallStarterHardening {
    $installScriptPath = Join-Path $ScriptDir "install-starters.ps1"

    if (-not (Test-Path -LiteralPath $installScriptPath)) {
        Add-Result -Starter "bootstrap-step-02" -Check "official install script" -Status "FAIL" -Details "scripts/install-starters.ps1 not found"
        return
    }

    $content = Get-Content -LiteralPath $installScriptPath -Raw

    if ($content -match "Test-Path\s+-LiteralPath") {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup uses Test-Path -LiteralPath" -Status "PASS" -Details "Found Test-Path -LiteralPath"
    } else {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup uses Test-Path -LiteralPath" -Status "FAIL" -Details "Missing Test-Path -LiteralPath usage in scripts/install-starters.ps1"
    }

    if ($content -match "Remove-Item\s+-LiteralPath") {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup uses Remove-Item -LiteralPath" -Status "PASS" -Details "Found Remove-Item -LiteralPath"
    } else {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup uses Remove-Item -LiteralPath" -Status "FAIL" -Details "Missing Remove-Item -LiteralPath usage in scripts/install-starters.ps1"
    }

    if ($content -match "finally\s*\{[\s\S]*?Test-Path\s+-LiteralPath[\s\S]*?Remove-Item\s+-LiteralPath") {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup finally block" -Status "PASS" -Details "Found finally block with literal-path cleanup"
    } else {
        Add-Result -Starter "bootstrap-step-02" -Check "temp cleanup finally block" -Status "FAIL" -Details "Missing finally block with literal-path cleanup in scripts/install-starters.ps1"
    }

    if (
        ($content -match 'Target slot exists and is not empty') -and
        ($content -match 'Result "SKIP"') -and
        ($content -match 'Collision "yes"')
    ) {
        Add-Result -Starter "bootstrap-step-02" -Check "non-destructive collision classification" -Status "PASS" -Details "Found SKIP collision=yes classification"
    } else {
        Add-Result -Starter "bootstrap-step-02" -Check "non-destructive collision classification" -Status "FAIL" -Details "Missing non-destructive collision classification in scripts/install-starters.ps1"
    }
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
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $output = @(& $Command @Arguments 2>&1 | ForEach-Object { $_.ToString() })
        $ErrorActionPreference = $previousErrorActionPreference
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
        $ErrorActionPreference = "Stop"
        Pop-Location
    }
}

function Invoke-DockerComposeStep {
    param(
        [string]$Starter,
        [string]$Check,
        [string]$WorkingDirectory,
        [string]$ComposeFile,
        [string[]]$ComposeArguments
    )

    if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { $WorkingDirectory = $RepoRoot }
    try {
        Push-Location $WorkingDirectory
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $output = @(& docker compose -f $ComposeFile @ComposeArguments 2>&1 | ForEach-Object { $_.ToString() })
        $ErrorActionPreference = $previousErrorActionPreference

        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }

        if ($exitCode -eq 0) {
            Add-Result -Starter $Starter -Check $Check -Status "PASS" -Details "Command succeeded: docker compose -f $ComposeFile $($ComposeArguments -join ' ')"
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
        $ErrorActionPreference = "Stop"
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
    $bootstrapPath = Join-Path $RepoRoot "PROJECT-BOOTSTRAP.yaml"
    if (-not (Test-Path -LiteralPath $bootstrapPath)) {
        return $null
    }

    function Resolve-RepoValue {
        param([string]$Value)

        if ($null -eq $Value) { return $null }
        $normalized = $Value.Trim()
        if ($normalized -match "^(.*?)(\s+#.*)?$") {
            $normalized = $matches[1].Trim()
        }
        $normalized = $normalized.Trim("'").Trim('"')
        if ([string]::IsNullOrWhiteSpace($normalized)) { return $null }
        if ($normalized -in @("null","~","false","False","FALSE")) { return $null }
        return $normalized
    }

    $lines = @(Get-Content -LiteralPath $bootstrapPath)
    $activeProfile = $null

    foreach ($line in $lines) {
        if ($line -match "^\s*profile\s*:\s*([a-zA-Z0-9_-]+)") {
            $activeProfile = $matches[1]
            break
        }
    }

    $manualStarters = @{}
    $inManualStarters = $false
    $currentManualKey = $null

    foreach ($line in $lines) {
        if ($line -match "^\s*starters\s*:\s*$") {
            $inManualStarters = $true
            $currentManualKey = $null
            continue
        }

        if ($inManualStarters -and $line -match "^\S") {
            break
        }

        if ($inManualStarters -and $line -match "^\s{2}([a-zA-Z0-9_-]+)\s*:\s*$") {
            $currentManualKey = $matches[1]
            continue
        }

        if ($inManualStarters -and $null -ne $currentManualKey -and $line -match "^\s{4}repo\s*:\s*(.*?)\s*$") {
            $manualStarters[$currentManualKey] = Resolve-RepoValue -Value $matches[1]
        }
    }

    $profileStarters = @{}
    if (-not [string]::IsNullOrWhiteSpace($activeProfile)) {
        $profileHeaderRegex = "^\s{2}" + [regex]::Escape($activeProfile) + "\s*:\s*$"
        $profileStart = -1

        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match $profileHeaderRegex) {
                $profileStart = $i
                break
            }
        }

        if ($profileStart -ge 0) {
            $inProfileStarters = $false
            $currentProfileKey = $null

            for ($j = $profileStart + 1; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]

                if ($line -match "^\s{2}[a-zA-Z0-9_-]+\s*:\s*$") {
                    break
                }

                if (-not $inProfileStarters -and $line -match "^\s{4}starters\s*:\s*$") {
                    $inProfileStarters = $true
                    continue
                }

                if ($inProfileStarters -and $line -match "^\s{4}[a-zA-Z0-9_-]+\s*:\s*$") {
                    break
                }

                if ($inProfileStarters -and $line -match "^\s{6}([a-zA-Z0-9_-]+)\s*:\s*$") {
                    $currentProfileKey = $matches[1]
                    continue
                }

                if ($inProfileStarters -and $null -ne $currentProfileKey -and $line -match "^\s{8}repo\s*:\s*(.*?)\s*$") {
                    $profileStarters[$currentProfileKey] = Resolve-RepoValue -Value $matches[1]
                }
            }
        }
    }

    $resolvedStarters = @{}
    $allKeys = @("backend","web","client","contracts","infra","composition")
    foreach ($key in $allKeys) {
        $value = $null
        if ($profileStarters.ContainsKey($key)) {
            $value = $profileStarters[$key]
        }
        if ($manualStarters.ContainsKey($key) -and $null -ne $manualStarters[$key]) {
            $value = $manualStarters[$key]
        }
        $resolvedStarters[$key] = $value
    }

    return [pscustomobject]@{
        Source = $bootstrapPath
        Profile = $activeProfile
        ProfileStarters = $profileStarters
        ManualStarters = $manualStarters
        ResolvedStarters = $resolvedStarters
    }
}

function Test-StarterSelected {
    param(
        [object]$BootstrapInfo,
        [string]$StarterKey
    )

    if ($null -eq $BootstrapInfo) {
        return $false
    }

    if (-not $BootstrapInfo.ResolvedStarters.ContainsKey($StarterKey)) {
        return $false
    }

    return $null -ne $BootstrapInfo.ResolvedStarters[$StarterKey]
}

function Test-StarterApplied {
    param(
        [object]$BootstrapInfo,
        [object]$StarterDefinition
    )

    if ($null -eq $BootstrapInfo) {
        return $false
    }

    if (-not $BootstrapInfo.ResolvedStarters.ContainsKey($StarterDefinition.Key)) {
        return $false
    }

    $resolvedRepo = $BootstrapInfo.ResolvedStarters[$StarterDefinition.Key]
    if ($null -eq $resolvedRepo) {
        return $false
    }

    return $resolvedRepo -eq $StarterDefinition.Id
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

function Test-JsStarter {
    param(
        [string]$StarterId,
        [string]$StarterPath
    )

    Add-Result -Starter $StarterId -Check "Path exists" -Status "PASS" -Details $StarterPath

    $packageJsonCandidates = @(
        (Join-Path $StarterPath "package.json"),
        (Join-Path $StarterPath "app\package.json")
    )
    $packageJsonPath = $null
    foreach ($candidate in $packageJsonCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $packageJsonPath = $candidate
            break
        }
    }

    if (-not (Test-Path -LiteralPath $packageJsonPath)) {
        Add-Result -Starter $StarterId -Check "package.json" -Status "SKIP" -Details "No package.json found"
        return
    }
    $packageDir = Split-Path -Parent $packageJsonPath
    Add-Result -Starter $StarterId -Check "package.json" -Status "PASS" -Details ("Found: " + $packageJsonPath)

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

    $nodeModules = Join-Path $packageDir "node_modules"
    if ($SkipNpmCiIfNodeModules -and (Test-Path -LiteralPath $nodeModules)) {
        Add-Result -Starter $StarterId -Check "npm ci" -Status "SKIP" -Details "Skipped due to -SkipNpmCiIfNodeModules and existing node_modules"
    } else {
        [void](Invoke-Step -Starter $StarterId -Check "npm ci" -WorkingDirectory $packageDir -Command "npm" -Arguments @("ci","--no-audit","--fund=false"))
    }

    $pkg = Read-JsonFile -Path $packageJsonPath
    if ($null -eq $pkg) {
        Add-Result -Starter $StarterId -Check "package.json parsing" -Status "SKIP" -Details "Could not parse JSON; skipping script discovery"
        return
    }

    $scriptCandidates = @("build","test","smoke","lint","typecheck")
    foreach ($scriptName in $scriptCandidates) {
        if (Test-NpmScript -PackageJson $pkg -ScriptName $scriptName) {
            [void](Invoke-Step -Starter $StarterId -Check ("npm run " + $scriptName) -WorkingDirectory $packageDir -Command "npm" -Arguments @("run",$scriptName))
        } else {
            Add-Result -Starter $StarterId -Check ("npm run " + $scriptName) -Status "SKIP" -Details "Script not defined"
        }
    }
}

function Test-DotnetStarter {
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

function Test-ContractsStarter {
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

    $validateScriptPath = Join-Path $StarterPath "app\scripts\validate.sh"
    if (Test-Path -LiteralPath $validateScriptPath) {
        $isWindowsOs = $env:OS -eq "Windows_NT"
        if ((-not $isWindowsOs) -and (Test-CommandAvailable -Name "bash")) {
            $validateOk = Invoke-Step -Starter $StarterId -Check "contracts validate.sh" -WorkingDirectory $StarterPath -Command "bash" -Arguments @("./app/scripts/validate.sh")
            if ($validateOk) {
                return
            }
        }
    }

    $primarySpec = @($specs | Select-Object -First 1)[0]
    if ($null -ne $primarySpec -and (Test-Path -LiteralPath $primarySpec)) {
        $hasOpenApiField = @(
            Get-Content -LiteralPath $primarySpec -ErrorAction SilentlyContinue |
                Where-Object { $_ -match "^\s*openapi\s*:\s*" } |
                Select-Object -First 1
        ).Count -gt 0

        if ($hasOpenApiField) {
            Add-Result -Starter $StarterId -Check "OpenAPI basic fallback validation" -Status "PASS" -Details ("Found required openapi field in " + (Split-Path -Leaf $primarySpec))
            return
        }

        Add-Result -Starter $StarterId -Check "OpenAPI basic fallback validation" -Status "FAIL" -Details ("Missing required openapi field in " + (Split-Path -Leaf $primarySpec))
        return
    }

    Add-Result -Starter $StarterId -Check "Contracts validation tooling" -Status "SKIP" -Details "Spec found, but no safely discoverable validator is available"
}

function Test-ComposeStarter {
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

    $composeFiles = @(Get-ComposeFiles -Path $StarterPath)
    if (@($composeFiles).Count -eq 0) {
        Add-Result -Starter $StarterId -Check "compose file discovery" -Status "SKIP" -Details "No compose file found"
        return
    }
    Add-Result -Starter $StarterId -Check "compose file discovery" -Status "PASS" -Details ("Found " + @($composeFiles).Count + " file(s)")

    $repoRootFull = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\\')

    function Get-ComposeFileArgument {
        param([string]$AbsolutePath)

        $absoluteFull = [System.IO.Path]::GetFullPath($AbsolutePath)
        if ($absoluteFull.StartsWith($repoRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePart = $absoluteFull.Substring($repoRootFull.Length).TrimStart('\\')
            return (".\\" + $relativePart)
        }
        return $absoluteFull
    }

    foreach ($composeFile in $composeFiles) {
        $composeName = Split-Path -Leaf $composeFile
        $composeRelative = Get-ComposeFileArgument -AbsolutePath $composeFile
        [void](Invoke-DockerComposeStep -Starter $StarterId -Check ("docker compose config: " + $composeName) -WorkingDirectory $RepoRoot -ComposeFile $composeRelative -ComposeArguments @("config","-q"))
    }

    if (-not $RunLifecycle) {
        Add-Result -Starter $StarterId -Check "compose lifecycle checks" -Status "SKIP" -Details "Not enabled for this starter"
        return
    }

    $primary = @($composeFiles | Select-Object -First 1)[0]
    $primaryRelative = Get-ComposeFileArgument -AbsolutePath $primary
    [void](Invoke-DockerComposeStep -Starter $StarterId -Check "docker compose up -d" -WorkingDirectory $RepoRoot -ComposeFile $primaryRelative -ComposeArguments @("up","-d"))
    [void](Invoke-DockerComposeStep -Starter $StarterId -Check "docker compose ps" -WorkingDirectory $RepoRoot -ComposeFile $primaryRelative -ComposeArguments @("ps"))

    if ($KeepInfraUp) {
        Add-Result -Starter $StarterId -Check "docker compose down" -Status "SKIP" -Details "Skipped due to -KeepInfraUp"
    } else {
        [void](Invoke-DockerComposeStep -Starter $StarterId -Check "docker compose down" -WorkingDirectory $RepoRoot -ComposeFile $primaryRelative -ComposeArguments @("down","--remove-orphans"))
    }
}

function Test-FlutterStarter {
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

function Test-ActionableSkip {
    param([object]$Row)

    if ($Row.Status -ne "SKIP") { return $false }

    $knownNonActionablePatterns = @(
        "Slot not selected by resolved profile",
        "Alternative starter in same slot not selected by resolved profile",
        "Skipped due to -SkipNpmCiIfNodeModules and existing node_modules",
        "Script not defined"
    )

    foreach ($pattern in $knownNonActionablePatterns) {
        if ($Row.Details -like ("*" + $pattern + "*")) {
            return $false
        }
    }

    return $true
}

Write-Host "============================================================"
Write-Host "Template Post-Install Validation"
Write-Host "Repository: $RepoRoot"
Write-Host "SkipNpmCiIfNodeModules: $SkipNpmCiIfNodeModules"
Write-Host "KeepInfraUp: $KeepInfraUp"
Write-Host "============================================================"

Test-InstallStarterHardening

$requiredBootstrapPath = Join-Path $RepoRoot "PROJECT-BOOTSTRAP.yaml"
if (-not (Test-Path -LiteralPath $requiredBootstrapPath)) {
    Add-Result -Starter "bootstrap" -Check "bootstrap manifest" -Status "FAIL" -Details "PROJECT-BOOTSTRAP.yaml not found"
    Write-Host ""
    Write-Host "=========================== Overall Result ==========================="
    Write-Host "PASS: 0  FAIL: 1  SKIP: 0"
    Write-Host "OVERALL: FAIL"
    exit 1
}

$bootstrapInfo = Get-BootstrapInfo
if ($null -ne $bootstrapInfo) {
    Write-Host ("Bootstrap source detected: " + $bootstrapInfo.Source)
} else {
    Add-Result -Starter "bootstrap" -Check "bootstrap manifest" -Status "FAIL" -Details "Unable to load PROJECT-BOOTSTRAP.yaml"
    Write-Host ""
    Write-Host "=========================== Overall Result ==========================="
    Write-Host "PASS: 0  FAIL: 1  SKIP: 0"
    Write-Host "OVERALL: FAIL"
    exit 1
}

foreach ($starter in $StarterDefinitions) {
    $starterPath = Join-Path $RepoRoot $starter.Path
    $pathExists = Test-Path -LiteralPath $starterPath
    $selected = Test-StarterSelected -BootstrapInfo $bootstrapInfo -StarterKey $starter.Key
    $applied = Test-StarterApplied -BootstrapInfo $bootstrapInfo -StarterDefinition $starter

    if (-not $selected) {
        Add-Result -Starter $starter.Id -Check "starter selection/install state" -Status "SKIP" -Details "Slot not selected by resolved profile"
        continue
    }

    if ($selected -and -not $applied) {
        Add-Result -Starter $starter.Id -Check "starter selection/install state" -Status "SKIP" -Details "Alternative starter in same slot not selected by resolved profile"
        continue
    }

    if ($selected -and $applied -and -not $pathExists) {
        Add-Result -Starter $starter.Id -Check "starter selection/install state" -Status "SKIP" -Details "Selected in bootstrap but canonical path not found"
        continue
    }

    switch ($starter.Id) {
        "agentic-clean-backend" {
            Test-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-dotnet-backend" {
            Test-DotnetStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-react-spa" {
            Test-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-angular-spa" {
            Test-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-flutter-client" {
            Test-FlutterStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-react-native" {
            Test-JsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-api-contracts-api" {
            Test-ContractsStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        "agentic-postgres-dev" {
            Test-ComposeStarter -StarterId $starter.Id -StarterPath $starterPath -RunLifecycle
        }
        "agentic-fullstack-composition" {
            Test-ComposeStarter -StarterId $starter.Id -StarterPath $starterPath
        }
        default {
            Add-Result -Starter $starter.Id -Check "starter dispatch" -Status "SKIP" -Details "No validator registered"
        }
    }
}

Write-Host ""
Write-Host "================== Per-Starter Summary (Applied Only) ================"

$appliedStarterIds = @(
    $StarterDefinitions |
        Where-Object { Test-StarterApplied -BootstrapInfo $bootstrapInfo -StarterDefinition $_ } |
        Select-Object -ExpandProperty Id
)

$notApplicableStarterIds = @(
    $StarterDefinitions |
        Where-Object { -not (Test-StarterApplied -BootstrapInfo $bootstrapInfo -StarterDefinition $_) } |
        Select-Object -ExpandProperty Id
)

$summaryRows = @()
foreach ($starter in $StarterDefinitions) {
    if (-not ($appliedStarterIds -contains $starter.Id)) {
        continue
    }

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

Write-Host ""
Write-Host "====================== Not Applicable Starters ======================="
if (@($notApplicableStarterIds).Count -eq 0) {
    Write-Host "(none)"
} else {
    foreach ($starterId in $notApplicableStarterIds) {
        Write-Host ("- " + $starterId)
    }
}

$actionableSkipRows = @(
    $CheckResults |
        Where-Object {
            ($appliedStarterIds -contains $_.Starter) -and (Test-ActionableSkip -Row $_)
        }
)

Write-Host ""
Write-Host "======================== Actionable SKIP Checks ======================"
if (@($actionableSkipRows).Count -eq 0) {
    Write-Host "(none)"
} else {
    foreach ($row in $actionableSkipRows) {
        Write-Host ("- " + $row.Starter + " :: " + $row.Check + " -> " + $row.Details)
    }
}

$appliedRows = @(
    $CheckResults |
        Where-Object {
            ($appliedStarterIds -contains $_.Starter) -or ($_.Starter -eq "bootstrap-step-02")
        }
)
$totalPass = @($appliedRows | Where-Object { $_.Status -eq "PASS" }).Count
$totalFail = @($appliedRows | Where-Object { $_.Status -eq "FAIL" }).Count
$totalSkip = @($appliedRows | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host ""
Write-Host "=========================== Overall Result ==========================="
Write-Host ("PASS: {0}  FAIL: {1}  SKIP: {2}" -f $totalPass, $totalFail, $totalSkip)

if ($totalFail -gt 0) {
    Write-Host "OVERALL: FAIL"
    exit 1
}

Write-Host "OVERALL: PASS (no FAIL results)"
exit 0