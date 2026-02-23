// ============================================================
//  TerrainData.as
//  Shared data structures for the terrain generation system.
//  Biomes, chunk state, side-prop configs, and terrain params.
// ============================================================

// ---- Biome identity ----------------------------------------

enum EBiomeType
{
    Nebula,
    AsteroidField,
    IonStorm,
    DeepVoid,
    CrystalCavern,
}

// ---- Terrain shape types (for varied landscape) -----------

enum ETerrainShapeType
{
    Flat,           // Minimal height variation
    Rolling,        // Gentle hills and valleys
    Dunes,          // Sand dune-like formations
    Valleys,        // Deep valleys with high peaks
    Ridged,         // Sharp ridges and canyons
    Chaotic,        // Mixed extreme variations
}

// ---- Side prop config (decorative objects beside the track) --

struct FBiomePropConfig
{
    UPROPERTY(EditAnywhere, Category = "Prop")
    TSubclassOf<AActor> PropClass;

    // Probability this prop spawns per spacing interval [0..1].
    UPROPERTY(EditAnywhere, Category = "Prop")
    float SpawnChance = 0.3;

    // Lateral offset range from the track edge (cm).
    UPROPERTY(EditAnywhere, Category = "Prop")
    float MinOffsetX = 100.0;

    UPROPERTY(EditAnywhere, Category = "Prop")
    float MaxOffsetX = 800.0;

    // Vertical offset range (cm).
    UPROPERTY(EditAnywhere, Category = "Prop")
    float MinOffsetZ = 0.0;

    UPROPERTY(EditAnywhere, Category = "Prop")
    float MaxOffsetZ = 200.0;

    // Scale range.
    UPROPERTY(EditAnywhere, Category = "Prop")
    float MinScale = 0.8;

    UPROPERTY(EditAnywhere, Category = "Prop")
    float MaxScale = 1.5;

    // Randomize yaw rotation.
    UPROPERTY(EditAnywhere, Category = "Prop")
    bool bRandomYRotation = true;
}

// ---- Per-biome visual / gameplay config --------------------

struct FBiomeConfig
{
    UPROPERTY(EditAnywhere, Category = "Biome|Identity")
    EBiomeType BiomeType;

    UPROPERTY(EditAnywhere, Category = "Biome|Identity")
    FName BiomeName = n"Default";

    // ---- Ground visuals ------------------------------------

    // Mesh used for the ground chunk. Assign in BP defaults.
    UPROPERTY(EditAnywhere, Category = "Biome|Ground")
    UStaticMesh ChunkMesh;

    UPROPERTY(EditAnywhere, Category = "Biome|Ground")
    UMaterialInterface GroundMaterial;

    // ---- Terrain shape parameters (procedural noise) -------

    // Terrain shape preset (designer-friendly)
    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    ETerrainShapeType TerrainShape = ETerrainShapeType::Rolling;

    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float TerrainAmplitude = 150.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float TerrainFrequency = 0.08;

    // 0 = no flattening, 1 = completely flat.
    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float Flatness = 0.3;

    // 0 = no ridges, 1 = all ridged.
    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float Ridgedness = 0.2;

    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float DomainWarpStrength = 0.35;

    // Secondary noise layer for detail (mobile-friendly)
    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float DetailAmplitude = 50.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Terrain")
    float DetailFrequency = 0.3;

    // ---- Atmosphere ----------------------------------------

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    FLinearColor FogColor = FLinearColor(0.05, 0.05, 0.1, 1.0);

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    float FogDensity = 0.02;

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    float FogStartDistance = 1000.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    float FogFalloff = 0.5;

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    FLinearColor AmbientColor = FLinearColor(0.1, 0.05, 0.2, 1.0);

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    FLinearColor SkyColor = FLinearColor(0.02, 0.02, 0.05, 1.0);

    UPROPERTY(EditAnywhere, Category = "Biome|Atmosphere")
    float Brightness = 1.0;

    // ---- Directional light ---------------------------------

    UPROPERTY(EditAnywhere, Category = "Biome|Light")
    FLinearColor SunColor = FLinearColor(1.0, 0.95, 0.8, 1.0);

    UPROPERTY(EditAnywhere, Category = "Biome|Light")
    float SunIntensity = 3.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Light")
    FRotator SunRotation = FRotator(-45.0, 0.0, 0.0);

    // ---- Transition ----------------------------------------

    // Seconds to blend from the previous biome to this one.
    UPROPERTY(EditAnywhere, Category = "Biome|Transition")
    float TransitionDuration = 3.0;

    // Distance from world origin at which this biome starts.
    // Biomes are sorted ascending by this value.
    UPROPERTY(EditAnywhere, Category = "Biome|Transition")
    float StartDistance = 0.0;

    // ---- Hills & Water --------------------------------------

    // Mesh used for side hills (e.g. a simple cube or rock mesh).
    UPROPERTY(EditAnywhere, Category = "Biome|Hills")
    UStaticMesh HillMesh;

    UPROPERTY(EditAnywhere, Category = "Biome|Hills")
    UMaterialInterface HillMaterial;

    // Hill width in cm (how wide each side hill strip is).
    UPROPERTY(EditAnywhere, Category = "Biome|Hills")
    float HillWidth = 2000.0;

    // Multiplier on TerrainAmplitude for hill height.
    UPROPERTY(EditAnywhere, Category = "Biome|Hills")
    float HillHeightMultiplier = 3.0;

    // World-Z of the water surface. Ground/hills below this appear submerged.
    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float WaterLevel = -100.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    UMaterialInterface WaterMaterial;

    // Enable water simulation (ripples, waves)
    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    bool bEnableWaterSimulation = false;

    // Water wave parameters
    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float WaveAmplitude = 10.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float WaveFrequency = 0.5;

    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float WaveSpeed = 100.0;

    // Ripple effect when ship hovers over water
    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float RippleStrength = 50.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Water")
    float RippleRadius = 300.0;

    // ---- Difficulty scaling ---------------------------------

    // Multiplier on spawn rates as distance increases (1.0 = no scaling)
    UPROPERTY(EditAnywhere, Category = "Biome|Difficulty")
    float SpawnRateMultiplier = 1.0;

    // Max number of obstacles per chunk in this biome
    UPROPERTY(EditAnywhere, Category = "Biome|Difficulty")
    int MaxObstaclesPerChunk = 3;

    // Biome-specific spawnable overrides (if empty, uses global lists)
    UPROPERTY(EditAnywhere, Category = "Biome|Spawning")
    TArray<FSpawnableObjectConfig> BiomeObstacles;

    UPROPERTY(EditAnywhere, Category = "Biome|Spawning")
    TArray<FSpawnableObjectConfig> BiomeCollectibles;

    // ---- Side props ----------------------------------------

    UPROPERTY(EditAnywhere, Category = "Biome|Props")
    TArray<FBiomePropConfig> SideProps;

    // ---- Dynamic Material Parameters -----------------------

    // Material parameter names for runtime blending
    UPROPERTY(EditAnywhere, Category = "Biome|Materials")
    FName MaterialBlendParameterName = n"BiomeBlend";

    UPROPERTY(EditAnywhere, Category = "Biome|Materials")
    FName TerrainColorParameterName = n"TerrainColor";

    UPROPERTY(EditAnywhere, Category = "Biome|Materials")
    FLinearColor PrimaryTerrainColor = FLinearColor(0.3, 0.25, 0.2, 1.0);

    UPROPERTY(EditAnywhere, Category = "Biome|Materials")
    FLinearColor SecondaryTerrainColor = FLinearColor(0.2, 0.2, 0.25, 1.0);

    // Texture tiling for ground material
    UPROPERTY(EditAnywhere, Category = "Biome|Materials")
    float TextureTiling = 1.0;

    // Mobile optimization: use simpler shaders
    UPROPERTY(EditAnywhere, Category = "Biome|Optimization")
    bool bUseMobileFriendlyShaders = true;

    // LOD settings for this biome
    UPROPERTY(EditAnywhere, Category = "Biome|Optimization")
    float MeshCullDistance = 10000.0;

    UPROPERTY(EditAnywhere, Category = "Biome|Optimization")
    bool bEnableMeshInstancing = true;
}

// ---- Per-chunk runtime state --------------------------------

struct FChunkState
{
    UPROPERTY()
    FVector StartPosition;

    UPROPERTY()
    FVector EndPosition;

    UPROPERTY()
    EBiomeType Biome;

    UPROPERTY()
    int ChunkIndex = 0;

    // Whether this chunk is in the initial safe zone (no obstacles).
    UPROPERTY()
    bool bIsSafeZone = false;

    // Difficulty level at this distance (0.0 = easy, 1.0 = max)
    UPROPERTY()
    float DifficultyLevel = 0.0;

    // Procedural terrain heights (set by subsystem noise).
    UPROPERTY()
    float GroundHeight = 0.0;

    UPROPERTY()
    float LeftHillHeight = 0.0;

    UPROPERTY()
    float RightHillHeight = 0.0;
}
