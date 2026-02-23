// ============================================================
//  TerrainChunk.as
//  A single poolable ground segment with side hills and water.
//  The subsystem spawns a fixed pool and recycles them as the
//  player moves forward (+X axis).
//
//  Layout per chunk (Y axis is lateral):
//    [ Left Hill | Ground Track | Right Hill ]
//    [ --------------- Water --------------- ]
//
//  The ground mesh sits at a noise-driven Z offset.
//  Side hills are scaled cubes/rocks at varying heights.
//  Water plane is a flat mesh at a fixed Z (biome WaterLevel).
// ============================================================

class ATerrainChunk : AActor
{
    // ---- Components ----------------------------------------

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent GroundMesh;
    default GroundMesh.SetCollisionProfileName(n"BlockAll");
    default GroundMesh.SetCastShadow(false);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent LeftHillMesh;
    default LeftHillMesh.SetCollisionProfileName(n"BlockAll");
    default LeftHillMesh.SetCastShadow(true);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent RightHillMesh;
    default RightHillMesh.SetCollisionProfileName(n"BlockAll");
    default RightHillMesh.SetCastShadow(true);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent WaterMesh;
    default WaterMesh.SetCollisionProfileName(n"NoCollision");
    default WaterMesh.SetCastShadow(false);

    UPROPERTY(DefaultComponent)
    UWaterSimulationComponent WaterSimulation;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    // How many lanes exist across the track
    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    int NumberOfLanes = 5;

    // Width of each lane in cm
    UPROPERTY(EditAnywhere, Category = "Terrain|Lanes")
    float LaneWidth = 200.0;

    // ---- Runtime state (set by subsystem on recycle) --------

    UPROPERTY(BlueprintReadOnly, Category = "Terrain")
    FChunkState ChunkState;

    UPROPERTY(BlueprintReadOnly, Category = "Terrain")
    bool bIsActive = false;

    // Dynamic material instances for runtime blending
    private UMaterialInstanceDynamic GroundMaterialInstance;
    private UMaterialInstanceDynamic LeftHillMaterialInstance;
    private UMaterialInstanceDynamic RightHillMaterialInstance;
    private UMaterialInstanceDynamic WaterMaterialInstance;

    // ---- Pool API ------------------------------------------

    UFUNCTION()
    void ActivateChunk(FChunkState InState, FBiomeConfig InBiome,
                       float ChunkLength, float TrackWidth)
    {
        ChunkState = InState;
        bIsActive = true;

        // Position the chunk root at the start position with ground height offset
        FVector rootPos = InState.StartPosition;
        rootPos.Z += InState.GroundHeight;
        SetActorLocation(rootPos);
        SetActorHiddenInGame(false);
        SetActorEnableCollision(true);

        if (bShowDebug)
            Print(f"[Chunk] Activate #{InState.ChunkIndex} at X={rootPos.X:.0f} GroundZ={InState.GroundHeight:.0f} Hills L={InState.LeftHillHeight:.0f} R={InState.RightHillHeight:.0f}");

        // ---- Ground mesh ----
        if (InBiome.ChunkMesh != nullptr)
            GroundMesh.SetStaticMesh(InBiome.ChunkMesh);
        if (InBiome.GroundMaterial != nullptr)
        {
            // Create dynamic material instance for runtime parameter control
            GroundMaterialInstance = GroundMesh.CreateDynamicMaterialInstance(0, InBiome.GroundMaterial);
            if (GroundMaterialInstance != nullptr)
            {
                // Set biome-specific material parameters
                GroundMaterialInstance.SetVectorParameterValue(InBiome.TerrainColorParameterName, InBiome.PrimaryTerrainColor);
                GroundMaterialInstance.SetScalarParameterValue(n"TextureTiling", InBiome.TextureTiling);
            }
        }

        // Scale: base mesh is 100x100x1 cm (standard UE plane).
        float scaleX = ChunkLength / 100.0;
        float scaleY = TrackWidth / 100.0;
        GroundMesh.SetRelativeScale3D(FVector(scaleX, scaleY, 1.0));
        
        // Shift ground mesh so it pivots from the bottom-center edge
        // A 100x100 plane centered at 0,0 needs to move forward by half its scaled length
        GroundMesh.SetRelativeLocation(FVector(ChunkLength * 0.5, 0.0, 0.0));

        // Setup left hill
        SetupHill(LeftHillMesh, InBiome, ChunkLength, TrackWidth,
                  InState.LeftHillHeight, -1.0);
        // Setup right hill
        SetupHill(RightHillMesh, InBiome, ChunkLength, TrackWidth,
                  InState.RightHillHeight, 1.0);

        // ---- Water plane ----
        SetupWater(InBiome, ChunkLength, TrackWidth, InState);
    }

    UFUNCTION()
    void DeactivateChunk()
    {
        if (bShowDebug)
            Print(f"[Chunk] Deactivate #{ChunkState.ChunkIndex}");

        bIsActive = false;
        SetActorHiddenInGame(true);
        SetActorEnableCollision(false);
        SetActorLocation(FVector(0.0, 0.0, -100000.0));
    }

    // ---- Lifecycle -----------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        DeactivateChunk();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (bShowDebug && bIsActive)
            DebugDrawChunkBounds();
    }

    // ---- Internal ------------------------------------------

    private void SetupHill(UStaticMeshComponent HillMesh, FBiomeConfig InBiome,
                           float ChunkLength, float TrackWidth,
                           float HillHeight, float SideMult)
    {
        if (InBiome.HillMesh != nullptr)
            HillMesh.SetStaticMesh(InBiome.HillMesh);
        if (InBiome.HillMaterial != nullptr)
        {
            // Create dynamic material instance
            UMaterialInstanceDynamic HillMatInst = HillMesh.CreateDynamicMaterialInstance(0, InBiome.HillMaterial);
            if (HillMatInst != nullptr)
            {
                HillMatInst.SetVectorParameterValue(InBiome.TerrainColorParameterName, InBiome.SecondaryTerrainColor);
                HillMatInst.SetScalarParameterValue(n"TextureTiling", InBiome.TextureTiling * 0.5);
            }
            
            // Cache the instance
            if (SideMult < 0.0)
                LeftHillMaterialInstance = HillMatInst;
            else
                RightHillMaterialInstance = HillMatInst;
        }

        // Scale hill to match chunk length and configured width/height
        float scaleX = ChunkLength / 100.0;
        float scaleY = InBiome.HillWidth / 100.0;
        float scaleZ = HillHeight / 100.0;
        HillMesh.SetRelativeScale3D(FVector(scaleX, scaleY, scaleZ));

        // Position hill at the side of the track, shifted forward by half chunk length
        float halfTrack = TrackWidth * 0.5;
        float halfHill = InBiome.HillWidth * 0.5;
        float yPos = (halfTrack + halfHill) * SideMult;

        HillMesh.SetRelativeLocation(FVector(ChunkLength * 0.5, yPos, 0.0));
    }

    private void SetupWater(FBiomeConfig InBiome, float ChunkLength, float TrackWidth, FChunkState InState)
    {
        if (InBiome.WaterMaterial == nullptr)
        {
            WaterMesh.SetHiddenInGame(true);
            WaterSimulation.bEnableSimulation = false;
            return;
        }

        WaterMesh.SetHiddenInGame(false);
        
        // Create dynamic material instance for water
        WaterMaterialInstance = WaterMesh.CreateDynamicMaterialInstance(0, InBiome.WaterMaterial);
        
        // Configure water simulation
        if (InBiome.bEnableWaterSimulation)
        {
            WaterSimulation.SetWaterParameters(
                InBiome.WaveAmplitude,
                InBiome.WaveFrequency,
                InBiome.WaveSpeed,
                InBiome.RippleStrength,
                InBiome.RippleRadius
            );
            WaterSimulation.bEnableSimulation = true;
        }
        else
        {
            WaterSimulation.bEnableSimulation = false;
        }

        // Make water slightly wider than track
        float waterWidth = TrackWidth + 2000.0;
        float scaleX = ChunkLength / 100.0;
        float scaleY = waterWidth / 100.0;
        WaterMesh.SetRelativeScale3D(FVector(scaleX, scaleY, 1.0));

        // Water level is absolute Z relative to the chunk root, shifted forward by half chunk length
        float zOffset = InBiome.WaterLevel - InState.GroundHeight;
        WaterMesh.SetRelativeLocation(FVector(ChunkLength * 0.5, 0.0, zOffset));
    }

    // ---- Dynamic Material Blending -------------------------

    UFUNCTION()
    void SetMaterialBlend(float BlendValue)
    {
        // Update blend parameter on all material instances
        if (GroundMaterialInstance != nullptr)
            GroundMaterialInstance.SetScalarParameterValue(n"BiomeBlend", BlendValue);
        if (LeftHillMaterialInstance != nullptr)
            LeftHillMaterialInstance.SetScalarParameterValue(n"BiomeBlend", BlendValue);
        if (RightHillMaterialInstance != nullptr)
            RightHillMaterialInstance.SetScalarParameterValue(n"BiomeBlend", BlendValue);
        if (WaterMaterialInstance != nullptr)
            WaterMaterialInstance.SetScalarParameterValue(n"BiomeBlend", BlendValue);
    }

    private void DebugDrawChunkBounds()
    {
        FVector start = ChunkState.StartPosition;
        FVector end = ChunkState.EndPosition;
        float z = GetActorLocation().Z;

        // Chunk boundary lines (white)
        FLinearColor col = ChunkState.bIsSafeZone
            ? FLinearColor(0.0, 1.0, 0.0, 1.0)
            : FLinearColor(1.0, 1.0, 1.0, 1.0);

        System::DrawDebugLine(start + FVector(0, -2000, 100), start + FVector(0, 2000, 100), col, 0.0, 5.0);
        System::DrawDebugLine(start + FVector(0, 0, 100), end + FVector(0, 0, 100), col, 0.0, 2.0);
        
        // Draw lane lines across this chunk
        float mapHalfWidth = LaneWidth * ((NumberOfLanes - 1) / 2.0) + LaneWidth * 0.5;
        FLinearColor laneCol = FLinearColor(0.2, 0.2, 0.8, 0.5); // Dim blue
        
        // Draw outer bounds
        System::DrawDebugLine(start + FVector(0, -mapHalfWidth, 100), end + FVector(0, -mapHalfWidth, 100), FLinearColor::Red, 0.0, 5.0);
        System::DrawDebugLine(start + FVector(0, mapHalfWidth, 100), end + FVector(0, mapHalfWidth, 100), FLinearColor::Red, 0.0, 5.0);

        // Draw individual lanes
        for (int i = 0; i < NumberOfLanes; i++)
        {
            float laneY = (i - (NumberOfLanes - 1) / 2.0) * LaneWidth;
            System::DrawDebugLine(start + FVector(0, laneY, 50), end + FVector(0, laneY, 50), laneCol, 0.0, 2.0);
            
            // Draw text at the start of each lane for this chunk
            System::DrawDebugString(start + FVector(0, laneY, 150), f"Lane {i}", nullptr, FLinearColor::Yellow, 0.0);
        }

        // Text
        FVector textPos = start + FVector(0.0, -1000.0, 300.0);
        System::DrawDebugString(textPos, f"Chunk {ChunkState.ChunkIndex}", nullptr, FLinearColor::White, 0.0);
    }
}
