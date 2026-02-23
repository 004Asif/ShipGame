# Enhanced Terrain System Guide

## Overview

The terrain system has been completely overhauled with mobile-friendly features:

1. **Designer-Friendly Terrain Shapes** - 6 preset terrain types (Flat, Rolling, Dunes, Valleys, Ridged, Chaotic)
2. **Water Bodies with Simulation** - Dynamic water with waves and ripples when ship hovers
3. **Dynamic Materials** - Runtime material blending during biome transitions
4. **Atmosphere System** - Smooth fog, lighting, and sky color transitions
5. **Mobile Optimization** - Instancing, LOD support, simplified shaders

## Input System

✅ **Pause Menu Input Already Configured**
- The pause action is already set up in `ShipPlayerController.as`
- Mapped to: **Escape** key and **Gamepad Special Right** button
- Calls `GameFlowSubsystem.TogglePause()` automatically

## New Files Created

### Core Systems
- `Script/Terrain/WaterSimulationComponent.as` - Water wave and ripple simulation
- `Script/Terrain/AtmosphereSubsystem.as` - Dynamic atmosphere transitions

### Enhanced Files
- `Script/Terrain/TerrainData.as` - Added terrain shape types, water simulation params, dynamic material settings
- `Script/Terrain/TerrainChunk.as` - Dynamic material instances, water simulation integration
- `Script/Terrain/TerrainGeneratorSubsystem.as` - Enhanced noise functions with shape types
- `Script/Terrain/TerrainManager.as` - Atmosphere subsystem integration

## Setup Instructions

### 1. Level Setup

Place these actors in your level:
- **TerrainManager** (already exists)
- **ExponentialHeightFog** (for fog effects)
- **DirectionalLight** (for sun)
- **SkyLight** (for ambient lighting)

### 2. Material Setup

Create materials with these parameters for dynamic blending:

#### Ground/Hill Material Parameters:
```
- BiomeBlend (Scalar) - Blend between biomes (0-1)
- TerrainColor (Vector) - Base terrain color
- TextureTiling (Scalar) - UV tiling multiplier
```

#### Water Material Parameters:
```
- WaveTime (Scalar) - Animated wave time
- WaveAmplitude (Scalar) - Wave height
- WaveFrequency (Scalar) - Wave frequency
- RippleCount (Scalar) - Number of active ripples
- RippleLocation0-3 (Vector) - Ripple positions (X,Y,Z,Age)
- RippleStrength0-3 (Scalar) - Ripple intensity
```

### 3. Biome Configuration

In `BP_TerrainManager` defaults, configure each biome:

#### Terrain Shape Settings
```
TerrainShape: Choose from dropdown
  - Flat: Minimal variation (good for racing sections)
  - Rolling: Gentle hills (default, balanced)
  - Dunes: Sand dune-like asymmetric waves
  - Valleys: Deep valleys with high peaks
  - Ridged: Sharp ridges and canyons
  - Chaotic: Mixed extreme variations

TerrainAmplitude: 150.0 (height variation)
TerrainFrequency: 0.08 (how often terrain changes)
Flatness: 0.3 (0=full noise, 1=completely flat)
DetailAmplitude: 50.0 (secondary detail layer)
DetailFrequency: 0.3 (detail layer frequency)
```

#### Water Settings
```
WaterLevel: -100.0 (world Z of water surface)
WaterMaterial: Assign your water material
bEnableWaterSimulation: true/false
WaveAmplitude: 10.0
WaveFrequency: 0.5
WaveSpeed: 100.0
RippleStrength: 50.0 (intensity when ship hovers)
RippleRadius: 300.0 (ripple spread distance)
```

#### Atmosphere Settings
```
FogColor: RGB color of fog
FogDensity: 0.02 (fog thickness)
FogStartDistance: 1000.0 (where fog begins)
FogFalloff: 0.5 (fog gradient)
AmbientColor: RGB ambient light color
SkyColor: RGB sky light color
Brightness: 1.0 (overall brightness multiplier)
```

#### Lighting Settings
```
SunColor: RGB sun color
SunIntensity: 3.0
SunRotation: (Pitch, Yaw, Roll) - sun angle
```

#### Dynamic Material Settings
```
PrimaryTerrainColor: Ground color
SecondaryTerrainColor: Hill color
TextureTiling: 1.0 (UV scale)
```

#### Mobile Optimization
```
bUseMobileFriendlyShaders: true (recommended)
MeshCullDistance: 10000.0 (when to hide distant chunks)
bEnableMeshInstancing: true (batch rendering)
```

## Example Biome Configurations

### Desert Biome (Dunes)
```
TerrainShape: Dunes
TerrainAmplitude: 200.0
TerrainFrequency: 0.05
Flatness: 0.1
WaterLevel: -500.0 (no water visible)
FogColor: (0.8, 0.7, 0.5, 1.0) - sandy haze
SunColor: (1.0, 0.9, 0.7, 1.0) - warm sun
PrimaryTerrainColor: (0.8, 0.7, 0.5, 1.0) - sand
```

### Ocean Biome (Flat with Water)
```
TerrainShape: Flat
TerrainAmplitude: 50.0
WaterLevel: 100.0 (water visible)
bEnableWaterSimulation: true
WaveAmplitude: 20.0
WaveFrequency: 0.3
FogColor: (0.3, 0.5, 0.7, 1.0) - ocean mist
SkyColor: (0.4, 0.6, 0.9, 1.0) - blue sky
```

### Mountain Biome (Valleys)
```
TerrainShape: Valleys
TerrainAmplitude: 400.0
TerrainFrequency: 0.03
Ridgedness: 0.8
HillHeightMultiplier: 5.0
FogColor: (0.6, 0.6, 0.7, 1.0) - mountain fog
PrimaryTerrainColor: (0.4, 0.4, 0.45, 1.0) - rock
```

### Canyon Biome (Ridged)
```
TerrainShape: Ridged
TerrainAmplitude: 300.0
TerrainFrequency: 0.06
Ridgedness: 0.9
FogColor: (0.7, 0.5, 0.4, 1.0) - dusty
SunIntensity: 5.0 (harsh sunlight)
```

## Mobile Performance Tips

1. **Texture Atlasing**: Combine terrain textures into atlases to reduce draw calls
2. **Material Complexity**: Keep shader instructions under 100 for mobile
3. **Cull Distances**: Set aggressive cull distances (5000-10000 units)
4. **LOD Meshes**: Create 3-4 LOD levels for hills/props
5. **Water Ripples**: Limited to 4 simultaneous ripples for performance
6. **Instancing**: Enabled by default for side props and repeated meshes

## Water Simulation Details

The water system uses **material-based simulation** (not vertex manipulation) for mobile performance:

- **Waves**: Sine-based animation via material parameters
- **Ripples**: Up to 4 simultaneous ripples tracked per chunk
- **Ship Detection**: Automatically detects ship hovering within 200 units of water surface
- **Ripple Decay**: Ripples fade over 1 second (configurable via `RippleDecayRate`)

## Atmosphere Transition System

Atmosphere changes smoothly between biomes:

- **Transition Duration**: Set per-biome (default 3 seconds)
- **Interpolation**: Smoothstep for natural transitions
- **Affected Elements**: Fog, directional light, sky light, sun rotation
- **Real-time**: All changes happen during gameplay without hitches

## Debugging

Enable debug visualization:
```
TerrainManager.bShowDebug = true
TerrainChunk.bShowDebug = true
WaterSimulationComponent.bShowDebug = true
AtmosphereSubsystem.bShowDebug = true
```

Debug output shows:
- Chunk activation/deactivation
- Terrain height values
- Water ripple creation
- Atmosphere transition progress
- Biome changes

## Material Shader Example (Pseudocode)

```hlsl
// Ground Material
float3 BaseColor = lerp(TerrainColor1, TerrainColor2, BiomeBlend);
float2 UV = TexCoord * TextureTiling;
float3 Texture = SampleTexture(UV);
float3 FinalColor = BaseColor * Texture;

// Water Material
float Wave = sin(WorldPosition.x * WaveFrequency + WaveTime) * WaveAmplitude;
float3 Normal = CalculateWaveNormal(Wave);

// Add ripples
for (int i = 0; i < RippleCount; i++) {
    float Dist = distance(WorldPosition.xy, RippleLocation[i].xy);
    float Ripple = sin(Dist * 10.0 - RippleLocation[i].w * 5.0) * RippleStrength[i];
    Wave += Ripple * (1.0 - RippleLocation[i].w);
}

WorldPositionOffset = float3(0, 0, Wave);
```

## Troubleshooting

### Water not animating
- Check `bEnableWaterSimulation = true` in biome config
- Ensure water material has required parameters
- Verify `WaterSimulationComponent` is on chunk

### Atmosphere not changing
- Ensure level has ExponentialHeightFog, DirectionalLight, SkyLight
- Check biome `StartDistance` values are ascending
- Verify `AtmosphereSubsystem` is initialized

### Terrain looks flat
- Increase `TerrainAmplitude` (try 200-400)
- Decrease `Flatness` (try 0.0-0.3)
- Try different `TerrainShape` types

### Performance issues on mobile
- Enable `bUseMobileFriendlyShaders`
- Reduce `MeshCullDistance` to 5000
- Decrease `DetailAmplitude` and `DetailFrequency`
- Disable water simulation for distant biomes

## Next Steps

1. **Create Materials**: Build ground, hill, and water materials with required parameters
2. **Configure Biomes**: Set up 3-5 distinct biomes with varied terrain shapes
3. **Test Transitions**: Play through and verify smooth atmosphere/terrain transitions
4. **Optimize**: Profile on target mobile device and adjust settings
5. **Polish**: Add particle effects, sound effects for water/atmosphere changes

## API Reference

### TerrainChunk
```angelscript
void SetMaterialBlend(float BlendValue) // Update biome blend (0-1)
```

### WaterSimulationComponent
```angelscript
void CreateRipple(FVector WorldLocation) // Manually create ripple
void SetWaterParameters(...) // Update water settings at runtime
```

### AtmosphereSubsystem
```angelscript
void SetBiomeAtmosphere(FBiomeConfig, bool bInstant) // Change atmosphere
void StartTransition(FBiomeConfig) // Begin smooth transition
bool IsTransitioning() // Check if transition active
float GetTransitionProgress() // Get 0-1 progress
```

### TerrainGeneratorSubsystem
```angelscript
EBiomeType GetCurrentBiome() // Get active biome
FBiomeConfig GetCurrentBiomeConfig() // Get full config
float GetLaneXPosition(int LaneIndex) // Get lane Y position
```
