# bannerlord_physics_unf-cker

Unf*cks the broken physics shape for `module_wall_plank_a` and `module_wall_plank_b` by replacing them with an identically sized prefab with working colliders. You will need to break the prefab in the editor afterwards for it to work correctly in native MP for other players.

## The bug

`module_wall_plank_a` and `module_wall_plank_b` ship in native Bannerlord with an inverted physics shape. In practice **you can walk straight into the pole, but once inside you cannot walk back out**. Players clip into the geometry and get stuck. This makes both entities a potential trap anywhere they appear in a scene.

This bug has been reported on the TaleWorlds forums: https://forums.taleworlds.com/index.php?threads/module_wall_plank_a-and-module_wall_plank_b-have-had-broken-physics-shapes-for-years.467778/

TaleWorlds appears to have been aware of this prior to it being publicly reported. In the native **Town Outskirts** map, every `module_wall_plank_b` entity has had its physics shape manually deleted and replaced with invisible editor collision cubes - a workaround that only applies to that one map without fixing the underlying entity's broken physics shape. 

**Replacements:**
- `module_wall_plank_a` → `module_wall_plank_a_unfucked_by_fief`
- `module_wall_plank_b` → `module_wall_plank_b_unfucked_by_fief`

Position, rotation, and scale are preserved.

---

## Bundle contents

Keep these two files in the same folder:

```
bannerlord_physics_unf-cker.ps1
Fief_NativeEntitySwaps.xml
```

---

## Prerequisites

- Windows (PowerShell is built in - no install needed)
- Bannerlord installed via Steam (standard path auto-detected; see `-BannerlordPath` below for non-standard installs)

---

## Step 1 - First-time PowerShell setup

Open PowerShell and run this once to allow scripts to run:

```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
Alternatively, use this in each session:
```
Set-ExecutionPolicy -Scope Process RemoteSigned; .\bannerlord—physics_unf-cker.ps1
```

---

## Step 2 - Run the script

Open PowerShell in the folder containing the two bundle files, then:

**Option A - Drop your map folder in and run with no arguments:**

Copy your map folder (the one containing `scene.xscene`) into the same folder as the script, then just run:
```
.\bannerlord_physics_unf-cker.ps1
```
The script will detect any map folders sitting alongside it automatically. Works with any map - Native, Multiplayer module, your own mod, anything.

**Option B - Point it at any scene directly:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "C:\path\to\any\map_folder\scene.xscene"
```

**Option C - Point it at a folder and fix everything inside:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "C:\path\to\Multiplayer\SceneObj" -Recurse
```

**Non-standard Bannerlord install location:**
```
.\bannerlord_physics_unf-cker.ps1 -Path "..." -BannerlordPath "D:\Games\Mount & Blade II Bannerlord"
```

**Dry run - see what would change without touching any files:**
```
.\bannerlord_physics_unf-cker.ps1 -WhatIf
```

The script will:
1. Copy `Fief_NativeEntitySwaps.xml` into your `SandBoxCore\Prefabs` folder so the game can resolve the replacement prefabs. Skipped automatically if already up to date.
2. Rewrite your scene file(s), swapping every `module_wall_plank_a/b` for its fixed counterpart.
3. Create a `scene.xscene.bak` backup beside every modified file. Pass `-NoBackup` to skip this.

---

## Step 3 - Break the prefabs in the editor

After running the script, open your scene in the Bannerlord editor:

1. In the entity search box, search for `_by_fief`
2. Select all results (Ctrl+A)
3. Right-click → **Break Prefab**
4. Save the scene

This bakes the prefab's child entities into the scene as standalone objects. Without this step, anyone loading the scene needs the prefab file loaded in a module - breaking it means the fix is self-contained in the scene with no external dependency.

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
| `-WhatIf` | Dry run - no files modified |
| `-NoBackup` | Skip creating `.bak` backups |
| `-Verbose` | Show skipped files and backup paths |
