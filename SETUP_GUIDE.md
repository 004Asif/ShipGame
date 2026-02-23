# ShipGame — Complete Setup Guide

Complete step-by-step instructions for every system in the project.
Covers basic setup, UI widgets, ship/upgrade system, physics tuning, terrain, and Git.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Project File Structure](#2-project-file-structure)
3. [Basic Level Setup](#3-basic-level-setup)
4. [Blueprint Creation](#4-blueprint-creation)
5. [Widget Setup (Designer-Friendly UI)](#5-widget-setup-designer-friendly-ui)
6. [Ship & Upgrade System](#6-ship--upgrade-system)
7. [Artifact Economy](#7-artifact-economy)
8. [Physics Tuning Guide](#8-physics-tuning-guide)
9. [Terrain System](#9-terrain-system)
10. [Gameplay Objects](#10-gameplay-objects)
11. [Adding New Content](#11-adding-new-content)
12. [Troubleshooting](#12-troubleshooting)
13. [Git & Version Control](#13-git--version-control)

---

## 1. Prerequisites

- Unreal Engine 5 with the AngelScript plugin installed
- This project opened in the UE5 editor
- All `.as` files in the `Script/` folder (they compile automatically)

---

## 2. Project File Structure

```
Script/
├── Core/
│   ├── GameData.as                 # Enums, structs, audio event constants
│   ├── GameFlowSubsystem.as       # Game phase state machine
│   ├── ScoreSubsystem.as          # Score, artifacts, multipliers
│   ├── ShipGameMode.as            # Main game mode, UI management
│   ├── ShipPlayerController.as    # Input binding (Enhanced Input)
│   ├── ShipRegistrySubsystem.as   # Ship catalog, upgrade lookup, stat computation
│   └── PlayerProgressSubsystem.as # Persistent player data, purchases, loadouts
├── Ship/
│   ├── ShipDefinition.as          # FShipDefinition, FUpgradeDefinition, FShipLoadout
│   ├── ShipData.as                # FShipData physics tuning struct
│   ├── ShipActor.as               # Main ship pawn (component container)
│   ├── ForwardMovementComponent.as
│   ├── LateralMovementComponent.as  # Speed-dependent turning
│   ├── HoverComponent.as
│   ├── BoostComponent.as
│   ├── NearMissComponent.as
│   ├── ShipInputComponent.as
│   └── PowerUpComponent.as
├── Camera/
│   └── CameraFollowComponent.as   # Intro swoop, chase cam, screen shake
├── Terrain/
│   ├── TerrainData.as             # Biome configs, chunk state, prop configs
│   ├── TerrainChunk.as            # Poolable ground segment
│   ├── TerrainGeneratorSubsystem.as  # Chunk pool, difficulty scaling, spawning
│   ├── TerrainManager.as          # Level actor that configures the subsystem
│   ├── WaterSimulationComponent.as
│   └── AtmosphereSubsystem.as     # Dynamic fog, lighting, sky transitions
├── Gameplay/
│   ├── CollectibleActor.as        # Artifact pickup
│   ├── DynamicObstacleActor.as
│   ├── EnemyShipActor.as
│   ├── PowerUpPickupActor.as
│   └── ExplosionEffectActor.as
└── UI/
    ├── MainMenuWidget.as          # Main menu (BindWidget)
    ├── GameHUDWidget.as           # In-game HUD (BindWidget)
    ├── PauseMenuWidget.as         # Pause overlay (BindWidget)
    ├── HangarWidget.as            # Upgrade/hangar screen (BindWidget)
    └── GameMenuSubsystem.as       # Menu state management
```

---

## 3. Basic Level Setup

1. **File → New Level → Empty Level** (or use the existing map)
2. Save as `Content/Maps/GameLevel`
3. Add to the level:
   - **Directional Light** (sun)
   - **Sky Atmosphere** + **Sky Light** (ambient lighting)
   - **Exponential Height Fog** (for biome atmosphere transitions)

---

## 4. Blueprint Creation

### 4a: BP_Ship (Player Ship)

1. Content Browser → right-click → **Blueprint Class** → parent: `ShipActor`
2. Name: `BP_Ship`
3. Open and set:
   - **ShipMesh** → assign a Static Mesh (use `Cube` for testing, scale `(2, 1, 0.5)`)
   - **ShipConfig** → all physics tuning values are here (leave defaults to start)
4. Compile & Save

### 4b: BP_TerrainChunk

1. Blueprint Class → parent: `TerrainChunk`
2. Name: `BP_TerrainChunk`
3. Open: assign `Engine/BasicShapes/Plane` to **GroundMesh**
4. Hills and water meshes are set at runtime from biome config

### 4c: Enhanced Input Assets

1. Create 4 Input Actions: `IA_MoveLeft`, `IA_MoveRight`, `IA_Boost`, `IA_Pause`
2. Create Input Mapping Context `IMC_Ship` with key bindings:
   - A/Left → `IA_MoveLeft`, D/Right → `IA_MoveRight`
   - Space → `IA_Boost`, Escape → `IA_Pause`

### 4d: BP_ShipPlayerController

1. Blueprint Class → parent: `ShipPlayerController`
2. Assign all input assets in Class Defaults

### 4e: BP_ShipGameMode

1. Blueprint Class → parent: `ShipGameMode`
2. Set: **Ship Class** → `BP_Ship`, **Player Controller Class** → `BP_ShipPlayerController`
3. Set **Default Pawn Class** → `None`

### 4f: Place TerrainManager

1. Drag `ATerrainManager` into the level at `(0, 0, 0)`
2. Set **ChunkClass** → `BP_TerrainChunk`
3. Add at least one biome in **BiomeConfigs** (see Section 9)
4. Add spawn lists for obstacles and collectibles

### 4g: Assign GameMode

1. **Window → World Settings** → **GameMode Override** → `BP_ShipGameMode`
2. Or set globally in **Project Settings → Maps & Modes**

---

## 5. Widget Setup (Designer-Friendly UI)

All widgets use the **BindWidget** pattern:

1. Create a **Widget Blueprint** child of the AngelScript class
2. In UMG Designer, add widgets with the **exact names** from the tables below
3. Code auto-binds them — any omitted widget is null-checked (no crash)
4. Style however you want: fonts, colors, backgrounds, animations

### 5a: Main Menu (`WBP_MainMenu`)

Parent class: `UMainMenuWidget`

| Widget Name | Type | Purpose |
|---|---|---|
| `TXT_GameTitle` | TextBlock | Game title |
| `TXT_PlayerName` | TextBlock | Player name |
| `BTN_Settings` | Button | Opens settings |
| `TXT_ShipName` | TextBlock | Current ship name |
| `TXT_ShipClass` | TextBlock | Ship class + tier |
| `IMG_ShipPreview` | Image | Ship preview texture |
| `BTN_PrevShip` / `BTN_NextShip` | Button | Cycle ships |
| `PB_Speed` / `PB_Shield` / `PB_Thrust` | ProgressBar | Stat bars (0-1) |
| `TXT_SpeedValue` / `TXT_ShieldValue` / `TXT_ThrustValue` | TextBlock | Stat numbers |
| `TXT_BestRun` / `TXT_TotalRuns` / `TXT_Artifacts` | TextBlock | Player stats |
| `BTN_Hangar` | Button | Opens hangar |
| `BTN_Store` | Button | Opens store |
| `BTN_Run` | Button | Starts a run |
| `BTN_GiveUp` | Button | Quit current run |
| `Panel_GiveUp` | Widget | Give-up container (hidden by default) |

### 5b: Game HUD (`WBP_GameHUD`)

Parent class: `UGameHUDWidget`

| Widget Name | Type | Purpose |
|---|---|---|
| `TXT_Score` | TextBlock | Current score |
| `TXT_Distance` | TextBlock | Distance traveled |
| `TXT_Speed` | TextBlock | Current speed |
| `TXT_Artifacts` | TextBlock | Artifacts this run |
| `PB_Shield` / `TXT_ShieldPercent` / `Panel_Shield` | ProgressBar/TextBlock/Widget | Shield bar (auto-hidden) |
| `PB_Magnet` / `TXT_MagnetPercent` / `Panel_Magnet` | ProgressBar/TextBlock/Widget | Magnet bar (auto-hidden) |
| `PB_Boost` / `TXT_BoostPercent` | ProgressBar/TextBlock | Boost bar |
| `TXT_Multiplier` / `Panel_Multiplier` | TextBlock/Widget | Multiplier (auto-hidden) |
| `BTN_TurnLeft` / `BTN_Pause` / `BTN_TurnRight` | Button | Mobile controls |

### 5c: Pause Menu (`WBP_PauseMenu`)

Parent class: `UPauseMenuWidget`

| Widget Name | Type | Purpose |
|---|---|---|
| `TXT_Title` | TextBlock | "PAUSED" |
| `TXT_Score` / `TXT_Distance` / `TXT_Artifacts` | TextBlock | Run stats |
| `BTN_Resume` / `BTN_Options` / `BTN_Quit` | Button | Actions |

### 5d: Hangar (`WBP_Hangar`)

Parent class: `UHangarWidget`

| Widget Name | Type | Purpose |
|---|---|---|
| `BTN_Back` | Button | Return to menu |
| `IMG_ShipPreview` / `TXT_ShipName` / `TXT_ShipClass` | Image/TextBlock | Ship info |
| `TXT_BaseName` / `TXT_BaseCost` / `BTN_BaseAction` / `TXT_BaseActionLabel` | TextBlock/Button | Base slot |
| Same pattern for `Engines`, `Armaments`, `Wings` | | Other slots |
| `TXT_ArtifactBalance` | TextBlock | Current artifacts |

### Widget Setup Steps

1. Content Browser → right-click → **User Interface → Widget Blueprint**
2. Set parent class (e.g. `UMainMenuWidget`)
3. Name it (e.g. `WBP_MainMenu`)
4. Open designer, add widgets with exact names from tables
5. In `BP_ShipGameMode`, set `MainMenuWidgetClass`, `PauseMenuWidgetClass`, `HUDWidgetClass` to your WBPs

---

## 6. Ship & Upgrade System

### 6a: How Ships Are Defined

Each ship = `FShipDefinition` struct with:
- **Identity**: `ShipId`, `DisplayName`, `ShipClassName`, `Tier`
- **Visual**: `ShipBlueprint` (BP class to spawn), `PreviewTexture`
- **Stats**: `BaseStats` (Speed/Shield/Thrust/Agility/Boost on 0-100 scale)
- **Physics**: `BasePhysics` (FShipData — actual physics values)
- **Economy**: `UnlockCost` (artifacts to unlock, 0 = starter)
- **Upgrades**: `BaseUpgrades`, `EngineUpgrades`, `ArmamentUpgrades`, `WingUpgrades`

### 6b: Registering Ships

In your GameMode or startup Blueprint:

```angelscript
FShipDefinition ship;
ship.ShipId = n"vanguard";
ship.DisplayName = "Vanguard";
ship.ShipClassName = "Interceptor";
ship.Tier = 1;
ship.UnlockCost = 0;
ship.BaseStats.SpeedRating = 60.0;
ship.BaseStats.ShieldRating = 40.0;
ship.BaseStats.ThrustRating = 55.0;
UShipRegistrySubsystem::Get().RegisterShip(ship);
```

### 6c: Upgrade Slots

| Slot | Affects | Example Upgrades |
|---|---|---|
| **Base** | Hull, shield | Reinforced Hull, Titanium Frame |
| **Engines** | Speed, acceleration | Ion Thrusters, Quantum Drive |
| **Armaments** | Weapons | Pulse Cannons, Missile Array |
| **Wings** | Agility, turning | Swept Wings, Delta Wings |

### 6d: Defining an Upgrade

```angelscript
FUpgradeDefinition eng;
eng.UpgradeId = n"ion_thrusters";
eng.DisplayName = "Ion Thrusters";
eng.Slot = EUpgradeSlot::Engines;
eng.Tier = 2;
eng.ArtifactCost = 500;
eng.SpeedModifier = 15.0;       // +15 speed rating
eng.ForwardSpeedBonus = 400.0;  // +400 cm/s max speed
eng.LateralThrustBonus = 200.0; // +200 lateral thrust
ship.EngineUpgrades.Add(eng);
```

### 6e: Computing Final Stats

```angelscript
UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
FShipData finalPhysics = Registry.ComputeFinalPhysics(shipId, loadout);
FShipStatRatings finalStats = Registry.ComputeFinalStats(shipId, loadout);
```

This applies all equipped upgrade bonuses to the base ship.

---

## 7. Artifact Economy

- **Earning**: Artifacts are collected during runs. At run end, `PlayerProgressSubsystem.RecordRunEnd()` adds them to the persistent balance.
- **Spending**: `PurchaseUpgrade()` and `UnlockShip()` deduct from balance.
- **Checking**: `CanAfford(cost)` returns true/false.
- **Persistence**: All data in `UPlayerProgressSubsystem` — connect to `USaveGame` for disk persistence.

Key API:
```angelscript
UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
Progress.AddArtifacts(50);                           // Grant artifacts
Progress.PurchaseUpgrade(shipId, slot, upgradeId, cost); // Buy upgrade
Progress.EquipUpgrade(shipId, slot, upgradeId);      // Equip owned upgrade
Progress.UnlockShip(shipId, cost);                   // Unlock new ship
Progress.SelectShip(shipId);                          // Set active ship
Progress.RecordRunEnd(distance, artifactsFromRun);   // End of run
```

---

## 8. Physics Tuning Guide

### 8a: Speed-Dependent Turning (NEW)

The ship now turns **faster at higher speeds**. Key parameters in `FShipData`:

| Parameter | Default | Description |
|---|---|---|
| `SpeedThrustScaling` | 0.6 | How much lateral thrust scales with speed |
| `SpeedForMaxThrust` | 3000 | Forward speed where max scaling kicks in |
| `MinThrustMultiplier` | 0.5 | Minimum thrust at zero speed |
| `SpeedInputResponsiveness` | 1.5 | How much faster input smoothing gets at speed |
| `SpeedBankScaling` | 0.3 | How much bank angle increases with speed |

**Formula**: `effectiveThrust = LateralThrust × lerp(MinThrustMultiplier, 1 + SpeedThrustScaling, speedRatio)`

### 8b: Core Physics Values

| Parameter | Default | Description |
|---|---|---|
| `InitialForwardSpeed` | 1500 | Starting speed |
| `MaxForwardSpeed` | 4000 | Max achievable speed |
| `AccelerationRate` | 50 | How fast speed ramps up |
| `ForwardThrust` | 60 | Force multiplier |
| `LateralThrust` | 2200 | Base sideways push force |
| `LateralDrag` | 14 | Sideways velocity damping |
| `HoverHeight` | 180 | Target hover altitude |
| `HoverSpringForce` | 100 | Spring strength |
| `HoverDamping` | 12 | Hover oscillation damping |
| `BoostSpeedMultiplier` | 2.0 | Speed × during boost |
| `BoostDuration` | 3.5 | Boost time (seconds) |
| `MaxBankAngle` | 35 | Max roll when turning |

### 8c: Tuning Tips

- **Ship turns too slow at speed** → increase `SpeedThrustScaling` or `LateralThrust`
- **Ship slides too much** → increase `LateralDrag`
- **Ship bounces** → increase `HoverDamping`, decrease `HoverSpringForce`
- **Ship feels floaty** → decrease `HoverHeight`, increase `LinearDrag`
- **Boost too fast/slow** → adjust `BoostSpeedMultiplier`
- All values are per-ship in `ShipConfig` on the Blueprint

---

## 9. Terrain System

### 9a: Overview

Infinite runner using a **chunk pool**:
- `ATerrainManager` → place one in level, configure everything
- `UTerrainGeneratorSubsystem` → manages chunk pool and spawning
- `ATerrainChunk` → poolable actor (ground + hills + water)
- `UAtmosphereSubsystem` → fog, lighting, sky transitions between biomes

### 9b: Biome Configuration

Each biome (`FBiomeConfig`) has:
- **Terrain shape** (`ETerrainShapeType`): Flat, Rolling, Dunes, Valleys, Ridged, Chaotic
- **Amplitude/Frequency**: terrain undulation intensity
- **Atmosphere**: fog color/density, sun color/intensity, sky color
- **Hills**: side mesh, width, height multiplier
- **Water**: level, material, wave parameters
- **Difficulty**: `SpawnRateMultiplier`, `MaxObstaclesPerChunk`
- **Biome-specific spawns**: `BiomeObstacles`, `BiomeCollectibles` (override globals)

### 9c: Difficulty Scaling (NEW)

Difficulty scales automatically with distance:
- `MaxDifficultyDistance` (100,000): where difficulty maxes out
- `DifficultySpawnMultiplier` (2.5): spawn rates increase up to 2.5× at max
- `DifficultyTerrainMultiplier` (1.5): terrain amplitude grows 50% more extreme
- Uses **quadratic curve** (slow ramp early, steep later)

### 9d: Height Smoothing (NEW)

Chunks interpolate ground height from previous chunk (60% blend) to avoid jarring vertical steps.

### 9e: TerrainManager Setup

1. Place `ATerrainManager` in level
2. Set **ChunkClass** → `BP_TerrainChunk`
3. Add biomes to **BiomeConfigs** (sorted by `StartDistance`)
4. Add spawn lists: **StaticObstacles**, **Collectibles**, **EnemyShips**, **PowerUps**
5. Manager auto-initializes on BeginPlay
6. `ShipGameMode` calls `SetTrackedActor(ship)` to tell it what to follow

---

## 10. Gameplay Objects

| Actor | Tag | Behavior |
|---|---|---|
| `ACollectibleActor` | `Collectible` | Spins/bobs, awards artifacts on overlap |
| `ADynamicObstacleActor` | `Obstacle` | Physics hover, sinusoidal drift |
| `AEnemyShipActor` | `EnemyShip` | AI lane-switching, obstacle avoidance |
| `APowerUpPickupActor` | `PowerUp` | Shield, SpeedBoost, MagnetCollector, Boost |
| `AExplosionEffectActor` | — | Niagara FX + auto-destroy |

---

## 11. Adding New Content

### New Ship
1. Create `BP_Ship_X` inheriting `AShipActor`
2. Set mesh, tweak `ShipConfig`
3. Create `FShipDefinition`, register with `UShipRegistrySubsystem::Get().RegisterShip(def)`

### New Upgrade
1. Create `FUpgradeDefinition` with unique `UpgradeId`
2. Set `Slot`, `ArtifactCost`, stat/physics modifiers
3. Add to the ship's upgrade arrays

### New Biome
1. Add entry to `ATerrainManager.BiomeConfigs`
2. Set `StartDistance` (e.g. 50000 for second biome)
3. Configure terrain shape, atmosphere, materials, difficulty
4. Optionally add `BiomeObstacles` / `BiomeCollectibles`

### New Power-Up
1. Add to `EPowerUpType` in `GameData.as`
2. Add handling in `PowerUpComponent.as`
3. Create pickup BP inheriting `APowerUpPickupActor`

### New Widget
1. Create Widget BP with AngelScript parent class
2. Add named widgets matching `BindWidget` properties
3. Style freely — code handles all logic

---

## 12. Troubleshooting

### Ship falls through ground
- Ground mesh needs collision (`Plane` has it by default)
- Ship must spawn ABOVE ground (Z = 500+)
- Check `HoverRaycastDistance` (default 1200)

### Ship doesn't move
- `CollisionRoot` must have `SetSimulatePhysics(true)` — it's the default
- Custom meshes need **Simple Collision**

### No input
- Verify Enhanced Input assets: `IMC_Ship`, `IA_MoveLeft/Right/Boost/Pause`
- `BP_ShipPlayerController` must have all assets assigned
- `BP_ShipGameMode` must use `BP_ShipPlayerController`

### Ship turns too slow
- Increase `SpeedThrustScaling` (default 0.6) or `LateralThrust` (default 2200)
- Check `SpeedForMaxThrust` — should be near your typical forward speed

### No terrain visible
- `ATerrainManager` must be in level with `ChunkClass` set
- At least one biome config required

### Camera stuck
- Check `BP_Ship` has **SpringArm** and **ShipCamera** components
- `CameraFollowComponent` handles intro swoop

### AngelScript errors
- **Window → Developer Tools → AngelScript Log** for details

---

## 13. Git & Version Control

### Create .gitignore

Create a `.gitignore` in the project root:

```
# UE5 generated files
Binaries/
Intermediate/
DerivedDataCache/
Saved/
.vs/
*.sln
*.vcxproj*
*.vsconfig
```

### Initial Setup

```bash
cd "C:\Users\Administrator\Documents\Unreal Projects\ShipGame"
git init
git add -A
git commit -m "Initial commit: ShipGame overhaul"
```

### Push to GitHub

```bash
git remote add origin https://github.com/YOUR_USERNAME/ShipGame.git
git branch -M main
git push -u origin main
```

---

## System Flow Reference

```
Game Boot
  └→ ShipGameMode.BeginPlay()
       ├→ Register ships in ShipRegistrySubsystem
       ├→ Create MainMenuWidget (WBP_MainMenu)
       ├→ Find/setup TerrainManager
       └→ GameFlowSubsystem → EGamePhase::Menu

Player taps RUN
  └→ GameFlowSubsystem → EGamePhase::Intro
       ├→ Spawn ship (selected from registry + loadout)
       ├→ Apply computed physics from base + upgrades
       ├→ CameraFollowComponent intro swoop
       └→ GameFlowSubsystem → EGamePhase::Playing

During Gameplay
  ├→ ForwardMovement: auto +X thrust with acceleration
  ├→ LateralMovement: speed-dependent turning + banking
  ├→ HoverComponent: physics hover over terrain
  ├→ TerrainGenerator: chunk recycling + difficulty scaling
  ├→ CollectibleActor → ScoreSubsystem.HandleArtifactCollected()
  ├→ GameHUDWidget: live BindWidget updates
  └→ BoostComponent: timed speed boost

Game Over
  └→ ShipActor.TriggerDeathSequence()
       ├→ GameFlowSubsystem → EGamePhase::GameOver
       ├→ PlayerProgressSubsystem.RecordRunEnd(distance, artifacts)
       └→ Return to menu with updated stats
```
