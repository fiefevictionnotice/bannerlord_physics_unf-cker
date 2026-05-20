<#
.SYNOPSIS
    Installs the Fief fixed-prefab file and replaces broken module_wall_plank_a/b entities in .xscene files.

.DESCRIPTION
    module_wall_plank_a and module_wall_plank_b ship with broken physics shapes in native Bannerlord.
    This script:
      1. Copies Fief_NativeEntitySwaps.xml (bundled alongside this script) into your
         SandBoxCore\Prefabs folder so the game can resolve the replacement prefabs.
      2. Rewrites every scene.xscene you point it at, swapping each broken entity for its
         fixed counterpart while preserving position, rotation, and all other entity data.

    The fixed prefabs are:
      module_wall_plank_a  ->  module_wall_plank_a_unfucked_by_fief
      module_wall_plank_b  ->  module_wall_plank_b_unfucked_by_fief

.PARAMETER Path
    One or more .xscene files or directories containing scene.xscene files.
    Defaults to the current directory.

.PARAMETER Recurse
    When Path is a directory, search subdirectories recursively.

.PARAMETER BannerlordPath
    Root of your Bannerlord install. Auto-detected from common Steam paths if omitted.

.PARAMETER SkipPrefabInstall
    Skip copying Fief_NativeEntitySwaps.xml — use this if you have already installed it.

.PARAMETER WhatIf
    Show what would change without modifying any files.

.PARAMETER NoBackup
    Skip creating a .bak backup before modifying each scene file.

.EXAMPLE
    .\bannerlord_physics_unf-cker.ps1 -Path "C:\...\YourMod\SceneObj\your_scene\scene.xscene"

.EXAMPLE
    .\bannerlord_physics_unf-cker.ps1 -Path "C:\...\YourMod\SceneObj" -Recurse

.EXAMPLE
    .\bannerlord_physics_unf-cker.ps1 -Path "C:\...\scene.xscene" -WhatIf
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string[]]$Path,

    [switch]$Recurse,

    [string]$BannerlordPath,

    [switch]$SkipPrefabInstall,

    [switch]$NoBackup
)

begin {
    # -------------------------------------------------------------------------
    # Step 1 — install Fief_NativeEntitySwaps.xml into SandBoxCore\Prefabs
    # -------------------------------------------------------------------------

    $prefabFileName = 'Fief_NativeEntitySwaps.xml'
    $scriptDir      = Split-Path -Parent $MyInvocation.MyCommand.Path
    $bundledPrefab  = Join-Path $scriptDir $prefabFileName

    $candidatePaths = @(
        'C:\Program Files (x86)\Steam\steamapps\common\Mount & Blade II Bannerlord',
        'C:\Program Files\Steam\steamapps\common\Mount & Blade II Bannerlord',
        'D:\Steam\steamapps\common\Mount & Blade II Bannerlord',
        'D:\SteamLibrary\steamapps\common\Mount & Blade II Bannerlord',
        'E:\Steam\steamapps\common\Mount & Blade II Bannerlord',
        'E:\SteamLibrary\steamapps\common\Mount & Blade II Bannerlord'
    )

    if (-not $SkipPrefabInstall) {
        if (-not (Test-Path $bundledPrefab)) {
            Write-Warning "Bundled prefab file not found at: $bundledPrefab"
            Write-Warning "Place $prefabFileName alongside this script, or use -SkipPrefabInstall."
            Write-Warning "Continuing with scene replacements only — make sure the prefabs are installed manually."
        } else {
            # Resolve Bannerlord root
            $resolvedRoot = $null

            if ($BannerlordPath) {
                if (Test-Path $BannerlordPath) {
                    $resolvedRoot = $BannerlordPath
                } else {
                    Write-Warning "Specified -BannerlordPath not found: $BannerlordPath"
                }
            }

            if (-not $resolvedRoot) {
                foreach ($candidate in $candidatePaths) {
                    if (Test-Path $candidate) {
                        $resolvedRoot = $candidate
                        break
                    }
                }
            }

            if (-not $resolvedRoot) {
                Write-Warning "Could not detect Bannerlord install. Tried common Steam paths."
                Write-Warning "Use -BannerlordPath to specify it, or -SkipPrefabInstall to skip."
                Write-Warning "Continuing with scene replacements only."
            } else {
                $targetDir    = Join-Path $resolvedRoot 'Modules\SandBoxCore\Prefabs'
                $targetFile   = Join-Path $targetDir $prefabFileName

                if (-not (Test-Path $targetDir)) {
                    Write-Warning "SandBoxCore\Prefabs not found at: $targetDir"
                    Write-Warning "Continuing with scene replacements only."
                } else {
                    $install = $true

                    if (Test-Path $targetFile) {
                        $existingHash = (Get-FileHash $targetFile   -Algorithm MD5).Hash
                        $bundledHash  = (Get-FileHash $bundledPrefab -Algorithm MD5).Hash
                        if ($existingHash -eq $bundledHash) {
                            Write-Host "[Prefabs] $prefabFileName already up to date in SandBoxCore\Prefabs. Skipping install."
                            $install = $false
                        } else {
                            Write-Host "[Prefabs] Existing $prefabFileName differs from bundle — will overwrite."
                        }
                    }

                    if ($install) {
                        if ($WhatIfPreference) {
                            Write-Host "[Prefabs] [WhatIf] Would copy $prefabFileName -> $targetDir"
                        } elseif ($PSCmdlet.ShouldProcess($targetFile, "Install $prefabFileName")) {
                            Copy-Item -LiteralPath $bundledPrefab -Destination $targetFile -Force
                            Write-Host "[Prefabs] Installed $prefabFileName -> $targetDir"
                        }
                    }
                }
            }
        }
    }

    # -------------------------------------------------------------------------
    # Step 2 — scene file replacements
    # -------------------------------------------------------------------------

    $replacementMap = @{
        'module_wall_plank_a' = 'module_wall_plank_a_unfucked_by_fief'
        'module_wall_plank_b' = 'module_wall_plank_b_unfucked_by_fief'
    }

    $pattern = 'prefab="(module_wall_plank_[ab])"'

    $totalA       = 0
    $totalB       = 0
    $filesModified = 0
    $filesScanned  = 0

    function Resolve-SceneFiles {
        param([string[]]$InputPaths, [bool]$DoRecurse)
        $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        foreach ($p in $InputPaths) {
            if (Test-Path $p -PathType Leaf) {
                $files.Add((Get-Item $p))
            } elseif (Test-Path $p -PathType Container) {
                $params = @{ Path = $p; Filter = 'scene.xscene'; File = $true }
                if ($DoRecurse) { $params['Recurse'] = $true }
                Get-ChildItem @params | ForEach-Object { $files.Add($_) }
            } else {
                Get-Item $p -ErrorAction SilentlyContinue | ForEach-Object { $files.Add($_) }
            }
        }
        return $files
    }

}

process {
    # If no path given, scan the script's own directory for dropped map folders
    $resolvedPath = $Path
    if (-not $resolvedPath) {
        Write-Host "[Auto] No path specified — scanning script folder for map folders..."
        $resolvedPath = Get-ChildItem $scriptDir -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName 'scene.xscene') } |
            ForEach-Object { $_.FullName }
        if ($resolvedPath) {
            Write-Host "[Auto] Found: $($resolvedPath -join ', ')"
        } else {
            Write-Warning "No map folders found in script directory and no -Path specified."
            Write-Warning "Drop a map folder (containing scene.xscene) alongside the script, or use -Path."
            return
        }
    }

    $sceneFiles = Resolve-SceneFiles -InputPaths $resolvedPath -DoRecurse $Recurse.IsPresent

    if ($sceneFiles.Count -eq 0) {
        Write-Warning "No scene.xscene files found under: $($resolvedPath -join ', ')"
        return
    }

    foreach ($file in $sceneFiles) {
        $filesScanned++
        $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)

        $fileCountA = ([regex]::Matches($content, 'prefab="module_wall_plank_a"')).Count
        $fileCountB = ([regex]::Matches($content, 'prefab="module_wall_plank_b"')).Count
        $fileTotal  = $fileCountA + $fileCountB

        if ($fileTotal -eq 0) {
            Write-Verbose "  (no targets)  $($file.FullName)"
            continue
        }

        Write-Host "`n$($file.FullName)"
        Write-Host "  module_wall_plank_a : $fileCountA replacement(s)"
        Write-Host "  module_wall_plank_b : $fileCountB replacement(s)"

        if ($WhatIfPreference) {
            Write-Host "  [WhatIf] No changes written."
            $totalA += $fileCountA
            $totalB += $fileCountB
            continue
        }

        if ($PSCmdlet.ShouldProcess($file.FullName, "Replace $fileTotal broken wall-plank prefab(s)")) {
            if (-not $NoBackup) {
                Copy-Item -LiteralPath $file.FullName -Destination ($file.FullName + '.bak') -Force
                Write-Verbose "  Backup: $($file.FullName).bak"
            }

            $newContent = [regex]::Replace($content, $pattern, {
                param($m)
                $replacement = $replacementMap[$m.Groups[1].Value]
                "prefab=""$replacement"""
            })

            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
            Write-Host "  Written."

            $totalA += $fileCountA
            $totalB += $fileCountB
            $filesModified++
        }
    }
}

end {
    $grandTotal = $totalA + $totalB
    Write-Host "`n========================================="
    Write-Host "  Files scanned  : $filesScanned"
    if (-not $WhatIfPreference) {
        Write-Host "  Files modified  : $filesModified"
    }
    Write-Host "  module_wall_plank_a replaced : $totalA"
    Write-Host "  module_wall_plank_b replaced : $totalB"
    Write-Host "  Total replacements           : $grandTotal"
    Write-Host "========================================="
}
