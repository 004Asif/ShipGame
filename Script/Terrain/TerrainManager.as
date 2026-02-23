// ============================================================
//  TerrainManager.as
//  Place ONE instance in your level. Configure biomes, chunk
//  settings, lane layout, and spawn lists in BP defaults.
//  Drives the TerrainGeneratorSubsystem each frame.
// ============================================================

class ATerrainManager : AActor
{
    // ---- Components ----------------------------------------

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    // ---- Chunk setup ---------------------------------------

    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    TSubclassOf<ATerrainChunk> ChunkClass;

    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    float ChunkLength = 5000.0;

    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    int ChunksAhead = 6;

    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    int ChunksBehind = 2;

    // Total track width in cm (ground mesh is scaled to this).
    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    float TrackWidth = 1000.0;

    // Distance from origin where no obstacles spawn.
    UPROPERTY(EditAnywhere, Category = "Terrain|Setup")
    float SafeZoneLength = 15000.0;

    // ---- Lane layout ---------------------------------------

    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    int NumberOfLanes = 5;

    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    float LaneWidth = 200.0;

    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    int MinClearLanes = 2;

    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    int MaxObjectsPerLane = 1;

    // ---- Biome configs (sorted by StartDistance ascending) --

    UPROPERTY(EditAnywhere, Category = "Terrain|Biomes")
    TArray<FBiomeConfig> BiomeConfigs;

    // ---- Spawn lists (global, apply to all biomes) ----------

    UPROPERTY(EditAnywhere, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> StaticObstacles;

    UPROPERTY(EditAnywhere, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> Collectibles;

    UPROPERTY(EditAnywhere, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> EnemyShips;

    UPROPERTY(EditAnywhere, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> PowerUps;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Runtime -------------------------------------------

    UPROPERTY(EditInstanceOnly, Category = "Terrain|Runtime")
    AActor TrackedActor;

    private UTerrainGeneratorSubsystem TerrainSubsystem;
    private UAtmosphereSubsystem AtmosphereSubsystem;
    private bool bTerrainReady = false;
    private int LastBiomeIndex = -1;

    // ---- Lifecycle -----------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TerrainSubsystem = UTerrainGeneratorSubsystem::Get();
        if (TerrainSubsystem == nullptr)
        {
            Print("TerrainManager: Could not find TerrainGeneratorSubsystem!", Duration = 10.0);
            return;
        }

        AtmosphereSubsystem = UAtmosphereSubsystem::Get();
        if (AtmosphereSubsystem == nullptr)
        {
            Print("TerrainManager: Could not find AtmosphereSubsystem!", Duration = 10.0);
            return;
        }

        if (ChunkClass == nullptr)
        {
            Print("TerrainManager: ChunkClass not set!", Duration = 10.0);
            return;
        }

        if (bShowDebug)
        {
            Print(f"[TerrainMgr] BeginPlay. Biomes={BiomeConfigs.Num()} ChunkLen={ChunkLength:.0f} TrackW={TrackWidth:.0f}");
            Print(f"[TerrainMgr] Ahead={ChunksAhead} Behind={ChunksBehind} Lanes={NumberOfLanes} LaneW={LaneWidth:.0f}");
            Print(f"[TerrainMgr] Obstacles={StaticObstacles.Num()} Collectibles={Collectibles.Num()} Enemies={EnemyShips.Num()} PowerUps={PowerUps.Num()}");
        }

        // Ensure at least one biome config exists (white-box fallback)
        if (BiomeConfigs.Num() == 0)
        {
            FBiomeConfig defaultBiome;
            defaultBiome.BiomeType = EBiomeType::Nebula;
            defaultBiome.BiomeName = n"DefaultNebula";
            BiomeConfigs.Add(defaultBiome);
        }

        FVector startPos = GetActorLocation();

        TerrainSubsystem.InitializeTerrain(
            BiomeConfigs,
            ChunkLength,
            TrackWidth,
            ChunksAhead,
            ChunksBehind,
            SafeZoneLength,
            NumberOfLanes,
            LaneWidth,
            ChunkClass,
            startPos,
            StaticObstacles,
            Collectibles,
            EnemyShips,
            PowerUps,
            MinClearLanes,
            MaxObjectsPerLane
        );

        bTerrainReady = true;

        // Set initial atmosphere
        if (BiomeConfigs.Num() > 0)
        {
            AtmosphereSubsystem.SetBiomeAtmosphere(BiomeConfigs[0], true);
            LastBiomeIndex = 0;
        }

        // Listen for biome changes
        TerrainSubsystem.OnBiomeChanged.AddUFunction(this, n"OnBiomeChanged");

        if (bShowDebug)
            Print(f"[TerrainMgr] Terrain initialized from {GetActorLocation()}");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bTerrainReady)
            return;

        TerrainSubsystem.UpdateTrackedPosition(GetTrackPosition());
        
        // Update atmosphere transitions
        if (AtmosphereSubsystem != nullptr)
            AtmosphereSubsystem.UpdateTransition(DeltaSeconds);
    }

    // ---- Public API ----------------------------------------

    UFUNCTION()
    void SetTrackedActor(AActor InActor)
    {
        TrackedActor = InActor;
        if (bShowDebug)
        {
            if (InActor != nullptr)
                Print(f"[TerrainMgr] Tracking actor: {InActor.Name}");
            else
                Print("[TerrainMgr] Tracking actor: null");
        }
    }

    UFUNCTION(BlueprintPure)
    EBiomeType GetCurrentBiome() const
    {
        if (TerrainSubsystem == nullptr)
            return EBiomeType::Nebula;
        return TerrainSubsystem.GetCurrentBiome();
    }

    UFUNCTION()
    void ResetTerrain()
    {
        if (bShowDebug)
            Print("[TerrainMgr] ResetTerrain");
        if (TerrainSubsystem != nullptr)
            TerrainSubsystem.ResetTerrain();
        
        // Reset atmosphere to first biome
        if (AtmosphereSubsystem != nullptr && BiomeConfigs.Num() > 0)
        {
            AtmosphereSubsystem.SetBiomeAtmosphere(BiomeConfigs[0], true);
            LastBiomeIndex = 0;
        }
        
        bTerrainReady = false;
    }

    // ---- Event Handlers ------------------------------------

    UFUNCTION()
    private void OnBiomeChanged(EBiomeType NewBiome, int BiomeIndex)
    {
        if (bShowDebug)
            Print(f"[TerrainMgr] Biome changed to {NewBiome} (index {BiomeIndex})");

        // Trigger atmosphere transition
        if (AtmosphereSubsystem != nullptr && BiomeIndex >= 0 && BiomeIndex < BiomeConfigs.Num())
        {
            AtmosphereSubsystem.StartTransition(BiomeConfigs[BiomeIndex]);
            LastBiomeIndex = BiomeIndex;
        }
    }

    // ---- Internal ------------------------------------------

    private FVector GetTrackPosition() const
    {
        if (TrackedActor != nullptr)
            return TrackedActor.GetActorLocation();
        return GetActorLocation();
    }
}
