// ============================================================
//  TerrainGeneratorSubsystem.as
//  World subsystem that owns the chunk pool and drives
//  infinite-runner terrain generation along the +X axis.
//  Uses distance-based biome transitions and lane-aware
//  object spawning (matching Unity LevelGenerator design).
// ============================================================

event void FOnChunkActivated(ATerrainChunk Chunk, FChunkState State);
event void FOnChunkRecycled(ATerrainChunk Chunk, FChunkState State);
event void FOnBiomeChanged(EBiomeType NewBiome, int BiomeIndex);

class UTerrainGeneratorSubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Public events -------------------------------------

    UPROPERTY()
    FOnChunkActivated OnChunkActivated;

    UPROPERTY()
    FOnChunkRecycled OnChunkRecycled;

    UPROPERTY()
    FOnBiomeChanged OnBiomeChanged;

    // ---- Configuration -------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    int ChunksAhead = 6;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    int ChunksBehind = 2;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    float ChunkLength = 5000.0;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    float TrackWidth = 1000.0;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    float SafeZoneLength = 15000.0;

    // ---- Difficulty scaling ----------------------------------

    // Distance at which difficulty reaches maximum
    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Difficulty")
    float MaxDifficultyDistance = 100000.0;

    // How much spawn rates increase at max difficulty (multiplier)
    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Difficulty")
    float DifficultySpawnMultiplier = 2.5;

    // How much ground height variation increases with difficulty
    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Difficulty")
    float DifficultyTerrainMultiplier = 1.5;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    int NumberOfLanes = 5;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    float LaneWidth = 200.0;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Config")
    int PoolSize = 10;

    // ---- Biome configs (sorted by StartDistance ascending) --

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Biomes")
    TArray<FBiomeConfig> BiomeConfigs;

    // ---- Spawn lists (global, all biomes) -------------------

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> StaticObstacles;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> Collectibles;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> EnemyShips;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    TArray<FSpawnableObjectConfig> PowerUps;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    int MinClearLanes = 2;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain|Spawning")
    int MaxObjectsPerLane = 1;

    // ---- Runtime state -------------------------------------

    private TArray<ATerrainChunk> ChunkPool;
    private TArray<int> ActiveChunkIndices;
    private int NextChunkSequenceIndex = 0;
    private FVector NextSpawnPosition;
    private FVector TrackedPosition;
    private bool bInitialized = false;

    // Biome tracking (distance-based like Unity)
    private int CurrentBiomeIndex = 0;
    private EBiomeType CurrentBiomeType = EBiomeType::Nebula;

    // Height smoothing between chunks
    private float PreviousGroundHeight = 0.0;

    // Spawned gameplay objects tracking
    private TArray<AActor> ActiveSpawnedObjects;

    // ---- Public API ----------------------------------------

    UFUNCTION()
    void InitializeTerrain(
        TArray<FBiomeConfig> InBiomeConfigs,
        float InChunkLength, float InTrackWidth,
        int InChunksAhead, int InChunksBehind,
        float InSafeZoneLength,
        int InNumberOfLanes, float InLaneWidth,
        TSubclassOf<ATerrainChunk> ChunkClass,
        FVector StartPosition,
        TArray<FSpawnableObjectConfig> InStaticObstacles,
        TArray<FSpawnableObjectConfig> InCollectibles,
        TArray<FSpawnableObjectConfig> InEnemyShips,
        TArray<FSpawnableObjectConfig> InPowerUps,
        int InMinClearLanes, int InMaxObjectsPerLane)
    {
        if (bInitialized)
            return;

        BiomeConfigs     = InBiomeConfigs;
        ChunkLength      = InChunkLength;
        TrackWidth       = InTrackWidth;
        ChunksAhead      = InChunksAhead;
        ChunksBehind     = InChunksBehind;
        SafeZoneLength   = InSafeZoneLength;
        NumberOfLanes    = InNumberOfLanes;
        LaneWidth        = InLaneWidth;
        PoolSize         = InChunksAhead + InChunksBehind + 2;
        NextSpawnPosition = StartPosition;
        TrackedPosition   = StartPosition;
        StaticObstacles  = InStaticObstacles;
        Collectibles     = InCollectibles;
        EnemyShips       = InEnemyShips;
        PowerUps         = InPowerUps;
        MinClearLanes    = InMinClearLanes;
        MaxObjectsPerLane = InMaxObjectsPerLane;

        if (BiomeConfigs.Num() > 0)
        {
            CurrentBiomeIndex = 0;
            CurrentBiomeType = BiomeConfigs[0].BiomeType;
        }

        SpawnPool(ChunkClass);
        SeedInitialChunks();

        bInitialized = true;

        if (bShowDebug)
            Print(f"[TerrainGen] Initialized. Pool={ChunkPool.Num()} Biomes={BiomeConfigs.Num()} SafeZone={SafeZoneLength:.0f}");
    }

    UFUNCTION()
    void UpdateTrackedPosition(FVector InPosition)
    {
        if (!bInitialized)
            return;

        TrackedPosition = InPosition;
        CheckBiomeTransition();
        RecycleTrailingChunks();
        SpawnLeadingChunks();
        CleanUpSpawnedObjects();
    }

    UFUNCTION(BlueprintPure)
    EBiomeType GetCurrentBiome() const
    {
        return CurrentBiomeType;
    }

    UFUNCTION(BlueprintPure)
    int GetCurrentBiomeIndex() const
    {
        return CurrentBiomeIndex;
    }

    UFUNCTION(BlueprintPure)
    FBiomeConfig GetCurrentBiomeConfig() const
    {
        if (CurrentBiomeIndex >= 0 && CurrentBiomeIndex < BiomeConfigs.Num())
            return BiomeConfigs[CurrentBiomeIndex];
        FBiomeConfig Default;
        return Default;
    }

    UFUNCTION(BlueprintPure)
    float GetLaneXPosition(int LaneIndex) const
    {
        return (LaneIndex - (NumberOfLanes - 1) / 2.0) * LaneWidth;
    }

    UFUNCTION(BlueprintPure)
    float GetMapHalfWidth() const
    {
        return LaneWidth * ((NumberOfLanes - 1) / 2.0) + LaneWidth * 0.5;
    }

    // Reset everything — called when returning to menu.
    UFUNCTION()
    void ResetTerrain()
    {
        // Deactivate all chunks
        for (int i = 0; i < ActiveChunkIndices.Num(); i++)
        {
            int idx = ActiveChunkIndices[i];
            if (idx >= 0 && idx < ChunkPool.Num())
                ChunkPool[idx].DeactivateChunk();
        }
        ActiveChunkIndices.Empty();

        // Destroy spawned objects
        for (int i = 0; i < ActiveSpawnedObjects.Num(); i++)
        {
            if (ActiveSpawnedObjects[i] != nullptr)
                ActiveSpawnedObjects[i].DestroyActor();
        }
        ActiveSpawnedObjects.Empty();

        NextChunkSequenceIndex = 0;
        NextSpawnPosition = FVector(0.0, 0.0, 0.0);
        TrackedPosition = FVector(0.0, 0.0, 0.0);
        CurrentBiomeIndex = 0;
        if (BiomeConfigs.Num() > 0)
            CurrentBiomeType = BiomeConfigs[0].BiomeType;

        bInitialized = false;
    }

    // ---- Internal: pool management -------------------------

    private void SpawnPool(TSubclassOf<ATerrainChunk> ChunkClass)
    {
        ChunkPool.Empty();
        ActiveChunkIndices.Empty();

        FVector hiddenLoc = FVector(0.0, 0.0, -100000.0);
        FRotator zeroRot = FRotator(0.0, 0.0, 0.0);

        for (int i = 0; i < PoolSize; i++)
        {
            ATerrainChunk chunk = Cast<ATerrainChunk>(
                SpawnActor(ChunkClass, hiddenLoc, zeroRot));
            if (chunk != nullptr)
                ChunkPool.Add(chunk);
        }
    }

    private void SeedInitialChunks()
    {
        for (int i = 0; i < ChunksAhead + 1; i++)
            ActivateNextChunk();
    }

    private ATerrainChunk GetPooledChunk()
    {
        for (int i = 0; i < ChunkPool.Num(); i++)
        {
            if (!ChunkPool[i].bIsActive)
                return ChunkPool[i];
        }
        return nullptr;
    }

    private void ActivateNextChunk()
    {
        ATerrainChunk chunk = GetPooledChunk();
        if (chunk == nullptr)
            return;

        FBiomeConfig config = GetCurrentBiomeConfig();

        bool bSafe = NextSpawnPosition.X < SafeZoneLength;

        // Calculate difficulty level based on distance
        float distanceRatio = Math::Clamp(NextSpawnPosition.X / Math::Max(MaxDifficultyDistance, 1.0), 0.0, 1.0);
        float difficultyLevel = distanceRatio * distanceRatio; // Quadratic curve for gradual ramp

        FChunkState state;
        state.StartPosition = NextSpawnPosition;
        state.EndPosition   = NextSpawnPosition + FVector(ChunkLength, 0.0, 0.0);
        state.Biome         = CurrentBiomeType;
        state.ChunkIndex    = NextChunkSequenceIndex;
        state.bIsSafeZone   = bSafe;
        state.DifficultyLevel = difficultyLevel;

        // Generate procedural terrain heights with difficulty-scaled amplitude
        float chunkCenterX = NextSpawnPosition.X + ChunkLength * 0.5;
        float diffAmplitude = config.TerrainAmplitude * (1.0 + difficultyLevel * (DifficultyTerrainMultiplier - 1.0));
        float rawGroundHeight = TerrainNoiseWithShape(chunkCenterX, config.TerrainShape,
                                                      config.TerrainFrequency, diffAmplitude,
                                                      config.Flatness, config.DetailAmplitude, config.DetailFrequency);

        // Smooth transition from previous chunk height to avoid jarring steps
        state.GroundHeight = Math::Lerp(PreviousGroundHeight, rawGroundHeight, 0.6);
        PreviousGroundHeight = state.GroundHeight;
        state.LeftHillHeight = TerrainNoiseWithShape(chunkCenterX + 1234.5, config.TerrainShape,
                                                     config.TerrainFrequency * 0.7,
                                                     config.TerrainAmplitude * config.HillHeightMultiplier,
                                                     config.Ridgedness, config.DetailAmplitude * 0.5, config.DetailFrequency * 1.2);
        state.RightHillHeight = TerrainNoiseWithShape(chunkCenterX + 5678.9, config.TerrainShape,
                                                      config.TerrainFrequency * 0.6,
                                                      config.TerrainAmplitude * config.HillHeightMultiplier,
                                                      config.Ridgedness, config.DetailAmplitude * 0.5, config.DetailFrequency * 1.3);

        // Ensure hills are always positive height (above ground)
        state.LeftHillHeight  = Math::Max(state.LeftHillHeight + config.TerrainAmplitude * config.HillHeightMultiplier, 50.0);
        state.RightHillHeight = Math::Max(state.RightHillHeight + config.TerrainAmplitude * config.HillHeightMultiplier, 50.0);

        chunk.ActivateChunk(state, config, ChunkLength, TrackWidth);

        int poolIndex = ChunkPool.FindIndex(chunk);
        ActiveChunkIndices.Add(poolIndex);

        // Spawn gameplay objects in this segment
        SpawnObjectsInSegment(state);

        NextSpawnPosition += FVector(ChunkLength, 0.0, 0.0);
        NextChunkSequenceIndex++;

        OnChunkActivated.Broadcast(chunk, state);

        if (bShowDebug)
            Print(f"[TerrainGen] Chunk#{state.ChunkIndex} at X={state.StartPosition.X:.0f} GndH={state.GroundHeight:.0f} Safe={state.bIsSafeZone}");
    }

    // ---- Terrain noise (layered sine approximation) --------

    private float TerrainNoise(float x, float frequency, float amplitude, float flatness)
    {
        // Layered sine waves for varied terrain without Perlin library
        float noise = Math::Sin(x * frequency) * 1.0
                    + Math::Sin(x * frequency * 2.17 + 1.7) * 0.5
                    + Math::Sin(x * frequency * 4.31 + 3.14) * 0.25;

        // Normalize to roughly [-1, 1] range
        noise /= 1.75;

        // Apply flatness (0 = full noise, 1 = completely flat)
        noise *= (1.0 - flatness);

        return noise * amplitude;
    }

    // Enhanced terrain noise with shape types
    private float TerrainNoiseWithShape(float x, ETerrainShapeType Shape, float frequency, 
                                       float amplitude, float flatness, float detailAmp, float detailFreq)
    {
        float baseNoise = 0.0;

        if (Shape == ETerrainShapeType::Flat)
        {
            // Minimal variation
            baseNoise = Math::Sin(x * frequency * 0.3) * 0.2;
        }
        else if (Shape == ETerrainShapeType::Rolling)
        {
            // Gentle hills
            baseNoise = Math::Sin(x * frequency) * 0.7
                      + Math::Sin(x * frequency * 1.5 + 2.1) * 0.3;
        }
        else if (Shape == ETerrainShapeType::Dunes)
        {
            // Sand dune-like asymmetric waves
            float wave = Math::Sin(x * frequency);
            baseNoise = Math::Pow(Math::Abs(wave), 0.6) * Math::Sign(wave);
        }
        else if (Shape == ETerrainShapeType::Valleys)
        {
            // Deep valleys with high peaks
            float wave = Math::Sin(x * frequency);
            baseNoise = wave * wave * wave; // Cubic for sharper valleys
        }
        else if (Shape == ETerrainShapeType::Ridged)
        {
            // Sharp ridges
            float wave = Math::Sin(x * frequency);
            baseNoise = 1.0 - Math::Abs(wave); // Inverted absolute for ridges
        }
        else if (Shape == ETerrainShapeType::Chaotic)
        {
            // Mixed extreme variations
            baseNoise = Math::Sin(x * frequency) * 1.0
                      + Math::Sin(x * frequency * 3.7 + 1.2) * 0.6
                      + Math::Sin(x * frequency * 7.3 + 4.5) * 0.4;
        }
        else
        {
            // Default rolling
            baseNoise = Math::Sin(x * frequency);
        }

        // Add detail layer (mobile-friendly - single octave)
        float detail = Math::Sin(x * detailFreq) * detailAmp / amplitude;
        baseNoise += detail * 0.3;

        // Normalize
        baseNoise = Math::Clamp(baseNoise, -1.0, 1.0);

        // Apply flatness
        baseNoise *= (1.0 - flatness);

        return baseNoise * amplitude;
    }

    // ---- Biome transitions (distance-based) ----------------

    private void CheckBiomeTransition()
    {
        int nextIndex = CurrentBiomeIndex + 1;
        if (nextIndex >= BiomeConfigs.Num())
            return;

        float playerDistance = TrackedPosition.X;
        if (playerDistance >= BiomeConfigs[nextIndex].StartDistance)
        {
            CurrentBiomeIndex = nextIndex;
            CurrentBiomeType = BiomeConfigs[nextIndex].BiomeType;
            OnBiomeChanged.Broadcast(CurrentBiomeType, CurrentBiomeIndex);

            if (bShowDebug)
                Print(f"[TerrainGen] Biome changed to #{CurrentBiomeIndex} ({CurrentBiomeType}) at dist={playerDistance:.0f}");
        }
    }

    // ---- Object spawning (lane-based) ----------------------

    private void SpawnObjectsInSegment(FChunkState InState)
    {
        FBiomeConfig config = GetCurrentBiomeConfig();

        // Use biome-specific lists if available, otherwise global
        TArray<FSpawnableObjectConfig> obstacleList = (config.BiomeObstacles.Num() > 0) ? config.BiomeObstacles : StaticObstacles;
        TArray<FSpawnableObjectConfig> collectibleList = (config.BiomeCollectibles.Num() > 0) ? config.BiomeCollectibles : Collectibles;

        // Difficulty-scaled spawn rate multiplier
        float diffMultiplier = 1.0 + InState.DifficultyLevel * (DifficultySpawnMultiplier - 1.0);
        diffMultiplier *= config.SpawnRateMultiplier;

        // Always spawn collectibles and power-ups
        SpawnFromListScaled(collectibleList, InState, diffMultiplier);
        SpawnFromListScaled(PowerUps, InState, 1.0); // Power-ups don't scale with difficulty

        // Only spawn obstacles and enemies outside safe zone
        if (!InState.bIsSafeZone)
        {
            SpawnFromListScaled(obstacleList, InState, diffMultiplier);
            SpawnFromListScaled(EnemyShips, InState, diffMultiplier * 0.5); // Enemies scale slower
        }
    }

    private void SpawnFromListScaled(TArray<FSpawnableObjectConfig> InList, FChunkState InState, float RateMultiplier)
    {
        for (int i = 0; i < InList.Num(); i++)
        {
            float scaledRate = Math::Clamp(InList[i].SpawnRate * RateMultiplier, 0.0, 0.95);
            if (Math::RandRange(0.0, 1.0) < scaledRate)
            {
                SpawnSingleObject(InList[i], InState);
            }
        }
    }

    private void SpawnSingleObject(FSpawnableObjectConfig InConfig, FChunkState InState)
    {
        if (InConfig.ActorClass == nullptr)
            return;

        // Pick a random lane
        int lane = Math::RandRange(0, NumberOfLanes - 1);
        float yPos = GetLaneXPosition(lane);
        float height = Math::RandRange(InConfig.HeightMin, InConfig.HeightMax) + InState.GroundHeight;
        float xPos = InState.StartPosition.X + Math::RandRange(0.0, ChunkLength);

        FVector spawnLoc = FVector(xPos, yPos, height);
        FRotator spawnRot = FRotator(0.0, 0.0, 0.0);

        AActor spawned = SpawnActor(InConfig.ActorClass, spawnLoc, spawnRot);
        if (spawned != nullptr)
        {
            // Apply random scale
            float scaleX = Math::RandRange(InConfig.SizeMin.X, InConfig.SizeMax.X);
            float scaleY = Math::RandRange(InConfig.SizeMin.Y, InConfig.SizeMax.Y);
            float scaleZ = Math::RandRange(InConfig.SizeMin.Z, InConfig.SizeMax.Z);
            spawned.SetActorScale3D(FVector(scaleX, scaleY, scaleZ));

            // Apply object tag
            if (InConfig.ObjectTag == EObjectTag::Obstacle)
                spawned.Tags.Add(n"Obstacle");
            else if (InConfig.ObjectTag == EObjectTag::Collectible)
                spawned.Tags.Add(n"Collectible");
            else if (InConfig.ObjectTag == EObjectTag::EnemyShip)
                spawned.Tags.Add(n"EnemyShip");
            else if (InConfig.ObjectTag == EObjectTag::PowerUp)
                spawned.Tags.Add(n"PowerUp");

            ActiveSpawnedObjects.Add(spawned);
        }
    }

    // ---- Cleanup -------------------------------------------

    private void RecycleTrailingChunks()
    {
        float recycleThreshold = TrackedPosition.X - (ChunksBehind * ChunkLength);

        TArray<int> toRemove;
        for (int i = 0; i < ActiveChunkIndices.Num(); i++)
        {
            int poolIdx = ActiveChunkIndices[i];
            ATerrainChunk chunk = ChunkPool[poolIdx];
            if (chunk.ChunkState.EndPosition.X < recycleThreshold)
            {
                OnChunkRecycled.Broadcast(chunk, chunk.ChunkState);
                chunk.DeactivateChunk();
                toRemove.Add(i);
            }
        }

        for (int i = toRemove.Num() - 1; i >= 0; i--)
            ActiveChunkIndices.RemoveAt(toRemove[i]);
    }

    private void SpawnLeadingChunks()
    {
        float spawnThreshold = TrackedPosition.X + (ChunksAhead * ChunkLength);
        while (NextSpawnPosition.X < spawnThreshold)
            ActivateNextChunk();
    }

    private void CleanUpSpawnedObjects()
    {
        float cleanupThreshold = TrackedPosition.X - ChunkLength * 2.0;

        for (int i = ActiveSpawnedObjects.Num() - 1; i >= 0; i--)
        {
            AActor obj = ActiveSpawnedObjects[i];
            if (obj == nullptr)
            {
                ActiveSpawnedObjects.RemoveAt(i);
                continue;
            }
            if (obj.GetActorLocation().X < cleanupThreshold)
            {
                obj.DestroyActor();
                ActiveSpawnedObjects.RemoveAt(i);
            }
        }
    }
}
