# UI System Guide - Mobile HUD & Menus

## Overview

Complete UI system with mobile-friendly HUD, main menu, and pause menu. All systems are wired and ready to use.

## Code Audit Results

### ✅ Redundancies Eliminated

**Problem Found:** Duplicate menu management between `GameMenuSubsystem` and `ShipGameMode`
- `GameMenuSubsystem` had menu state logic but widgets weren't assigned
- `ShipGameMode` manually managed widgets with duplicate visibility logic

**Solution Implemented:**
- Consolidated menu widget management in `ShipGameMode`
- `GameMenuSubsystem` kept for state tracking (can be used for future expansion)
- All menu button handlers now properly wired to GameMode

### ✅ Missing Implementations Added

1. **PowerUpComponent** - Created complete power-up system
2. **GameHUDWidget** - Mobile-friendly HUD with all indicators
3. **Menu Button Wiring** - All buttons now call correct functions

## New Files Created

### UI Components
- `Script/UI/GameHUDWidget.as` - Main gameplay HUD
- `Script/Ship/PowerUpComponent.as` - Power-up effect manager

### Updated Files
- `Script/UI/MainMenuWidget.as` - Wired button handlers
- `Script/UI/PauseMenuWidget.as` - Wired button handlers
- `Script/Core/ShipGameMode.as` - Added HUD management
- `Script/Ship/ShipActor.as` - Added PowerUpComponent

---

## Mobile HUD System

### Features

**Score Display:**
- Current score (large, prominent)
- Stars collected count with icon
- Score multiplier indicator (shows "x2.0" when active)

**Boost Meter:**
- Progress bar showing boost duration
- Color-coded states:
  - 🟢 Green = Ready to use
  - 🟡 Gold = Active (draining)
  - ⚪ Gray = Cooling down
- Cooldown progress indicator

**Power-Up Indicators:**
- **Magnet** - Shows when active with countdown timer and progress bar
- **Shield** - Shows when active with countdown timer and progress bar
- Auto-hide when not active (minimal screen clutter)

**Speed Display (Optional):**
- Current speed vs max speed
- Can be hidden for cleaner mobile UI

### HUD Data Binding

All HUD properties are `BlueprintReadOnly` and update automatically:

```angelscript
// Score
float CurrentScore
int StarsCollected
float ScoreMultiplier

// Boost
bool bBoostActive
float BoostProgress (0-1)
bool bBoostOnCooldown
float BoostCooldownProgress (0-1)

// Magnet
bool bMagnetActive
float MagnetTimeRemaining
float MagnetDuration

// Shield
bool bShieldActive
float ShieldTimeRemaining
float ShieldDuration
```

### Helper Functions for Blueprint

Use these in your Blueprint HUD to bind text and visibility:

```angelscript
// Text Formatting
FText GetScoreText()           // "12450"
FText GetStarsText()           // "23"
FText GetMultiplierText()      // "x2.0" or ""
FText GetMagnetTimeText()      // "3.2s"
FText GetShieldTimeText()      // "4.5s"

// Progress Bars (0-1)
float GetBoostProgressPercent()
float GetBoostCooldownPercent()
float GetMagnetProgressPercent()
float GetShieldProgressPercent()

// Visibility
ESlateVisibility GetMultiplierVisibility()  // Show only when > 1.0
ESlateVisibility GetMagnetVisibility()      // Show only when active
ESlateVisibility GetShieldVisibility()      // Show only when active

// Colors
FLinearColor GetBoostColor()  // Green/Gold/Gray based on state
```

---

## Blueprint Setup Guide

### 1. Create Blueprint Widgets

#### BP_GameHUD (Parent: GameHUDWidget)

**Recommended Mobile Layout:**

```
┌─────────────────────────────────────┐
│ ⭐ 23        SCORE: 12450      x2.0 │ ← Top bar
├─────────────────────────────────────┤
│                                     │
│         [Gameplay Area]             │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ [Boost] 🛡️ 3.2s  🧲 4.5s          │ ← Bottom bar
└─────────────────────────────────────┘
```

**Widget Hierarchy:**
```
Canvas Panel
├─ Top Bar (Horizontal Box)
│  ├─ Star Icon + Text (bind to GetStarsText)
│  ├─ Spacer
│  ├─ Score Text (bind to GetScoreText)
│  └─ Multiplier Text (bind to GetMultiplierText, GetMultiplierVisibility)
│
└─ Bottom Bar (Horizontal Box)
   ├─ Boost Progress Bar
   │  └─ Bind Percent to GetBoostProgressPercent
   │  └─ Bind Color to GetBoostColor
   │
   ├─ Shield Indicator (Horizontal Box)
   │  ├─ Shield Icon
   │  ├─ Progress Bar (bind to GetShieldProgressPercent)
   │  └─ Time Text (bind to GetShieldTimeText)
   │  └─ Bind Visibility to GetShieldVisibility
   │
   └─ Magnet Indicator (Horizontal Box)
      ├─ Magnet Icon
      ├─ Progress Bar (bind to GetMagnetProgressPercent)
      └─ Time Text (bind to GetMagnetTimeText)
      └─ Bind Visibility to GetMagnetVisibility
```

**Mobile Optimization Tips:**
- Use **large touch targets** (minimum 44x44 pixels)
- **High contrast** colors for readability in sunlight
- **Minimal text** - use icons where possible
- **Safe area margins** - 50px from screen edges
- **Anchors** - Top-left for stars, Top-right for score, Bottom for boost

#### BP_MainMenuWidget (Parent: MainMenuWidget)

**Buttons to Create:**
1. **Play Button** → OnClicked → Call `HandlePlayClicked()`
2. **Options Button** → OnClicked → Call `HandleOptionsClicked()`
3. **Quit Button** → OnClicked → Call `HandleQuitClicked()` (or hide for mobile)

#### BP_PauseMenuWidget (Parent: PauseMenuWidget)

**Buttons to Create:**
1. **Resume Button** → OnClicked → Call `HandleResumeClicked()`
2. **Options Button** → OnClicked → Call `HandleOptionsClicked()`
3. **Quit to Main Button** → OnClicked → Call `HandleQuitToMainClicked()`

### 2. Assign Widget Classes in BP_ShipGameMode

Open `BP_ShipGameMode` defaults:
- **MainMenuWidgetClass** → BP_MainMenuWidget
- **PauseMenuWidgetClass** → BP_PauseMenuWidget
- **GameHUDWidgetClass** → BP_GameHUD

### 3. Configure Power-Up Pickups

In `BP_PowerUpPickup` (create from PowerUpPickupActor):

```
PowerUpEffect:
  Type: Shield / MagnetCollector / SpeedBoost / Boost
  Duration: 5.0
  SpeedMultiplier: 1.5 (for SpeedBoost)
  AttractionRadius: 1500.0 (for Magnet)
  AttractionSpeed: 800.0 (for Magnet)
```

---

## Power-Up System

### Available Power-Ups

**Shield** (`EPowerUpType::Shield`)
- Protects ship from one collision
- Duration: 5 seconds (configurable)
- Visual: Shield icon with countdown

**Magnet Collector** (`EPowerUpType::MagnetCollector`)
- Auto-attracts nearby collectibles (stars)
- Radius: 1500 cm (configurable)
- Speed: 800 cm/s (configurable)
- Duration: 5 seconds

**Speed Boost** (`EPowerUpType::SpeedBoost`)
- Multiplies max speed by 1.5x (configurable)
- Duration: 5 seconds
- Different from regular boost (this is a power-up)

**Instant Boost** (`EPowerUpType::Boost`)
- Triggers ship's boost component immediately
- Uses boost's own duration/cooldown settings

### Power-Up Events

Listen to these events for VFX/audio:

```angelscript
PowerUpComponent.OnPowerUpActivated  // (EPowerUpType, Duration)
PowerUpComponent.OnPowerUpExpired    // (EPowerUpType)
```

### Checking Active Power-Ups

```angelscript
UPowerUpComponent PowerUp = UPowerUpComponent::Get(Ship);
if (PowerUp.HasShield())
{
    // Ship is protected
}
```

---

## Menu Flow

### Game Start Flow
1. `ShipGameMode.BeginPlay()` → Creates main menu
2. Player clicks **Play** → `OnMainMenuPlayClicked()`
3. Main menu hidden, pause menu created (hidden), HUD created (hidden)
4. Ship spawned, camera switched
5. HUD shown, game starts

### Pause Flow
1. Player presses **Escape** / **Gamepad Menu**
2. `ShipPlayerController.OnPauseStarted()` → `GameFlowSubsystem.TogglePause()`
3. `ShipGameMode.TogglePauseMenu()` → Shows pause menu
4. Player clicks **Resume** → Hides pause menu, unpauses

### Quit to Main Flow
1. Player clicks **Quit to Main** in pause menu
2. `OnPauseMenuQuitClicked()` → `ReturnToMenu()`
3. HUD hidden, main menu shown
4. Camera switched back to menu camera
5. Ship destroyed, terrain reset

---

## Mobile-Specific Considerations

### Performance
- HUD updates every frame via `Tick()` - optimized for mobile
- Only active power-up indicators are visible (reduces overdraw)
- Progress bars use simple fills (no complex shaders)

### Touch Input
- No on-screen buttons needed (handled by `ShipPlayerController`)
- Boost can be triggered via touch if you add a button
- Pause via hardware back button (Android) or menu button

### Screen Sizes
- Use **anchors** for responsive layout
- Test on multiple aspect ratios (16:9, 18:9, 19.5:9)
- Safe area insets for notched devices

### Battery Optimization
- HUD only ticks when ship exists
- Subsystems cache references (no repeated searches)
- Minimal string formatting (only when displayed)

---

## Debugging

Enable debug output:
```
GameHUDWidget.bShowDebug = true
PowerUpComponent.bShowDebug = true
ShipGameMode.bShowDebug = true
```

Debug output shows:
- HUD ship tracking
- Power-up activation/expiration
- Menu state changes
- Widget creation

---

## Example: Adding a New Power-Up

1. **Add to enum** in `GameData.as`:
```angelscript
enum EPowerUpType
{
    Shield,
    SpeedBoost,
    MagnetCollector,
    Boost,
    Invincibility,  // NEW
}
```

2. **Add state to PowerUpComponent**:
```angelscript
UPROPERTY(BlueprintReadOnly)
bool bInvincibilityActive = false;

UPROPERTY(BlueprintReadOnly)
float InvincibilityTimeRemaining = 0.0;
```

3. **Add activation logic**:
```angelscript
UFUNCTION()
void ActivateInvincibility(float Duration)
{
    bInvincibilityActive = true;
    InvincibilityTimeRemaining = Duration;
    OnPowerUpActivated.Broadcast(EPowerUpType::Invincibility, Duration);
}
```

4. **Add to Tick** for countdown
5. **Add to HUD** for display
6. **Create pickup** with `Type = Invincibility`

---

## Troubleshooting

### HUD not showing
- Check `GameHUDWidgetClass` is assigned in BP_ShipGameMode
- Verify HUD is shown in `StartNewGame()` (should call `ShowGameHUD()`)
- Check viewport layer (should be 50, below menus at 100/200)

### Power-ups not working
- Ensure `PowerUpComponent` is on `ShipActor` (already added)
- Check pickup has `OnPowerUpPickedUp` event wired
- Verify power-up effect config is set

### Boost meter not updating
- Ship must have `BoostComponent` (already added)
- HUD must find ship in `Tick()` (check debug output)
- Verify progress bar is bound to `GetBoostProgressPercent()`

### Menus not responding
- Check button OnClicked events call Handle* functions
- Verify GameMode is `BP_ShipGameMode` (not base class)
- Check widget classes are assigned in GameMode defaults

---

## API Reference

### GameHUDWidget
```angelscript
// Automatically updates from subsystems
void Construct()                    // Initialize, bind to events
void Tick(FGeometry, float)         // Update all displays

// Blueprint helpers
FText GetScoreText()
FText GetStarsText()
FText GetMultiplierText()
float GetBoostProgressPercent()
ESlateVisibility GetMagnetVisibility()
FLinearColor GetBoostColor()
```

### PowerUpComponent
```angelscript
void ActivateShield(float Duration)
void ActivateMagnet(float Duration, float Radius, float Speed)
void ActivateSpeedBoost(float Duration, float Multiplier)
bool HasShield()                    // Check if protected
```

### ShipGameMode
```angelscript
void OnMainMenuPlayClicked()        // Start game
void OnPauseMenuResumeClicked()     // Resume from pause
void OnPauseMenuQuitClicked()       // Return to main menu
void TogglePauseMenu()              // Show/hide pause
```

---

## Next Steps

1. **Design HUD in UMG** - Create BP_GameHUD with layout above
2. **Style for Mobile** - Large fonts, high contrast, minimal clutter
3. **Add Icons** - Import star, shield, magnet, boost icons
4. **Test on Device** - Verify readability and performance
5. **Add Animations** - Subtle pulses for active power-ups
6. **Sound Effects** - Power-up pickup, boost activate, etc.

All systems are wired and ready to use!
