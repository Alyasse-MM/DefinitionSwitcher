# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
$targets = @{
    DefinitionSwitcher = @{
        AppName      = "DefinitionSwitcher"
        AppVersion   = "1.0.0"
        ProjectDir   = "$PSScriptRoot\"
        BuildDir     = "$PSScriptRoot\build\"
    }
    InnoSetup = @{
        TemplateFile = "$PSScriptRoot\tools\installer\template.iss"
    }
}

# ---------------------------------------------------------
# TASKS
# ---------------------------------------------------------
task clean {
    Write-Build Cyan "Cleaning build directory..."
    Remove-Item $target.DefinitionSwitcher.BuildDir -Recurse -Force -ErrorAction SilentlyContinue
}

task build {
    Write-Build Cyan "Compiling $($Conf.AppName).exe..."
    $DefinitionSwitcher=$targets.DefinitionSwitcher
    
    # Ensure build dir exists
    if (-not (Test-Path $DefinitionSwitcher.BuildDir)) {
        New-Item -ItemType Directory -Force -Path $DefinitionSwitcher.BuildDir | Out-Null
    }

    $OutputFile = "$($DefinitionSwitcher.BuildDir)\$($DefinitionSwitcher.AppName).exe"

    Invoke-PS2EXE `
        -InputFile "$PSScriptRoot\DefinitionSwitcher.ps1" `
        -OutputFile $OutputFile `
        -noConsole `
        -ErrorAction Stop
    
    Write-Build Green "Build Success: $OutputFile"
}

task innosetup {
    Write-Build Cyan "Generating Installer..."
    $DefinitionSwitcher=$targets.DefinitionSwitcher
    $InnoSetup=$targets.InnoSetup

    $IssContent = Get-Content -Path $InnoSetup.TemplateFile -Raw

    foreach ($Key in $DefinitionSwitcher.Keys) {
        $Placeholder = '{$'+$Key+'}'
        $Value = $DefinitionSwitcher[$Key]
        
        if ($null -ne $Value) {
            $IssContent = $IssContent.Replace($Placeholder, $Value)
        }
    }
    
    $TempIssFile = "$($DefinitionSwitcher.BuildDir)\$($DefinitionSwitcher.AppName).iss"

    Set-Content -Path $TempIssFile -Value $IssContent

    exec { ISCC $TempIssFile }
    
    Write-Build Green "Installer Created Successfully."
}

# Default
task . InnoSetup