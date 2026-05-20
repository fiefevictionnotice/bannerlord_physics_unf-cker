# bannerlord_physics_unf-cker

Unf*cks the broken physics shape for `module_wall_plank_a` and `module_wall_plank_b` by replacing them with an identically sized prefab with working colliders. You will need to break the prefab in the editor afterwards for it to work correctly in native MP for other players.

**Replacements:**
- `module_wall_plank_a` → `module_wall_plank_a_unfucked_by_fief`
- `module_wall_plank_b` → `module_wall_plank_b_unfucked_by_fief`

Position, rotation, and scale are preserved exactly.

---

## Bundle contents

Keep these two files in the same folder:

```
bannerlord_physics_unf-cker.ps1
Fief_NativeEntitySwaps.xml
```

---

## Prerequisites

- Windows (PowerShell is built in — no install needed)
- Bannerlord installed via Steam (standard path auto-detected; see `-BannerlordPath` below for non-standard installs)
- Your scene must be in your own module, not in Native

---

## Step 1 — First-time PowerShell setup

Open PowerShell and run this once to allow scripts to run:

```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## Step 2 — Run the script

Open PowerShell in the folder containing the two bundle files, then:

**Fix a single scene:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "C:\path\to\YourMod\SceneObj\your_scene\scene.xscene"
```

**Fix all scenes in a module folder at once:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "C:\path\to\YourMod\SceneObj" -Recurse
```

**Non-standard Bannerlord install location:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "..." -BannerlordPath "D:\Games\Mount & Blade II Bannerlord"
```

**Dry run — see what would change without touching any files:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "C:\path\to\scene.xscene" -WhatIf
```

The script will:
1. Copy `Fief_NativeEntitySwaps.xml` into your `SandBoxCore\Prefabs` folder so the game can resolve the replacement prefabs. Skipped automatically if already up to date.
2. Rewrite your scene file(s), swapping every `module_wall_plank_a/b` for its fixed counterpart.
3. Create a `scene.xscene.bak` backup beside every modified file. Pass `-NoBackup` to skip this.

---

## Step 3 — Break the prefab in the editor

After running the script, open your scene in the Bannerlord editor. For each replaced entity:

1. Select the entity in the scene
2. Right-click → **Break Prefab**
3. Save the scene

This converts the replacement prefab's child entities into standalone objects, which is required for the physics to work correctly for other players in native MP who don't have the prefab file.

---

## Output example

```
[Prefabs] Installed Fief_NativeEntitySwaps.xml -> ...\SandBoxCore\Prefabs

C:\...\YourMod\SceneObj\your_scene\scene.xscene
  module_wall_plank_a : 6 replacement(s)
  module_wall_plank_b : 2 replacement(s)
  Written.

=========================================
  Files scanned  : 1
  Files modified  : 1
  module_wall_plank_a replaced : 6
  module_wall_plank_b replaced : 2
  Total replacements           : 8
=========================================
```

---

## Additional options

| Flag | Description |
|---|---|
| `-Recurse` | Search subdirectories for scene files |
| `-BannerlordPath` | Manually specify Bannerlord install root |
| `-SkipPrefabInstall` | Skip copying `Fief_NativeEntitySwaps.xml` (if already installed) |
| `-WhatIf` | Dry run — no files modified |
| `-NoBackup` | Skip creating `.bak` backups |
| `-Verbose` | Show skipped files and backup paths |
