// ============================================================
//  WaterSimulationComponent.as
//  Mobile-friendly water simulation for terrain chunks.
//  Handles wave animation and ripple effects when ship hovers.
//  Uses material parameters instead of vertex manipulation for
//  mobile performance.
// ============================================================

event void FOnShipHoverOverWater(FVector HoverLocation, float HoverHeight);

class UWaterSimulationComponent : UActorComponent
{
    // ---- Configuration -------------------------------------

    UPROPERTY(EditAnywhere, Category = "Water")
    bool bEnableSimulation = true;

    UPROPERTY(EditAnywhere, Category = "Water|Waves")
    float WaveAmplitude = 10.0;

    UPROPERTY(EditAnywhere, Category = "Water|Waves")
    float WaveFrequency = 0.5;

    UPROPERTY(EditAnywhere, Category = "Water|Waves")
    float WaveSpeed = 100.0;

    UPROPERTY(EditAnywhere, Category = "Water|Ripples")
    float RippleStrength = 50.0;

    UPROPERTY(EditAnywhere, Category = "Water|Ripples")
    float RippleRadius = 300.0;

    UPROPERTY(EditAnywhere, Category = "Water|Ripples")
    float RippleDecayRate = 2.0;

    UPROPERTY(EditAnywhere, Category = "Water|Debug")
    bool bShowDebug = false;

    // ---- Events --------------------------------------------

    UPROPERTY()
    FOnShipHoverOverWater OnShipHoverOverWater;

    // ---- References ----------------------------------------

    UPROPERTY()
    UStaticMeshComponent WaterMesh;

    UPROPERTY()
    UMaterialInstanceDynamic WaterMaterialInstance;

    // ---- Runtime state -------------------------------------

    private float WaveTime = 0.0;
    private TArray<FVector> ActiveRipples;
    private TArray<float> RippleAges;
    private float CheckShipTimer = 0.0;

    // ---- Lifecycle -----------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Find water mesh on owner
        WaterMesh = UStaticMeshComponent::Get(Owner);
        if (WaterMesh == nullptr)
        {
            if (bShowDebug)
                Print("[WaterSim] WARNING: No StaticMeshComponent found on owner!");
            return;
        }

        // Create dynamic material instance
        UMaterialInterface BaseMat = WaterMesh.GetMaterial(0);
        if (BaseMat != nullptr)
        {
            WaterMaterialInstance = WaterMesh.CreateDynamicMaterialInstance(0, BaseMat);
            if (bShowDebug)
                Print("[WaterSim] Created dynamic material instance");
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!bEnableSimulation || WaterMaterialInstance == nullptr)
            return;

        // Update wave animation
        WaveTime += DeltaSeconds * WaveSpeed;
        UpdateWaveParameters();

        // Update ripples
        UpdateRipples(DeltaSeconds);

        // Check for ship hovering over water
        CheckShipTimer += DeltaSeconds;
        if (CheckShipTimer >= 0.1)
        {
            CheckShipTimer = 0.0;
            CheckForShipHover();
        }
    }

    // ---- Public API ----------------------------------------

    UFUNCTION()
    void SetWaterParameters(float InWaveAmplitude, float InWaveFrequency, 
                           float InWaveSpeed, float InRippleStrength, float InRippleRadius)
    {
        WaveAmplitude = InWaveAmplitude;
        WaveFrequency = InWaveFrequency;
        WaveSpeed = InWaveSpeed;
        RippleStrength = InRippleStrength;
        RippleRadius = InRippleRadius;
    }

    UFUNCTION()
    void CreateRipple(FVector WorldLocation)
    {
        if (!bEnableSimulation)
            return;

        ActiveRipples.Add(WorldLocation);
        RippleAges.Add(0.0);

        OnShipHoverOverWater.Broadcast(WorldLocation, 0.0);

        if (bShowDebug)
            Print(f"[WaterSim] Ripple created at {WorldLocation}");
    }

    // ---- Internal ------------------------------------------

    private void UpdateWaveParameters()
    {
        if (WaterMaterialInstance == nullptr)
            return;

        // Set wave time for shader animation
        WaterMaterialInstance.SetScalarParameterValue(n"WaveTime", WaveTime);
        WaterMaterialInstance.SetScalarParameterValue(n"WaveAmplitude", WaveAmplitude);
        WaterMaterialInstance.SetScalarParameterValue(n"WaveFrequency", WaveFrequency);
    }

    private void UpdateRipples(float DeltaSeconds)
    {
        // Age and remove old ripples
        for (int i = RippleAges.Num() - 1; i >= 0; i--)
        {
            RippleAges[i] += DeltaSeconds * RippleDecayRate;
            if (RippleAges[i] > 1.0)
            {
                ActiveRipples.RemoveAt(i);
                RippleAges.RemoveAt(i);
            }
        }

        // Update material with ripple data (up to 4 ripples for mobile performance)
        if (WaterMaterialInstance != nullptr)
        {
            int numRipples = Math::Min(ActiveRipples.Num(), 4);
            WaterMaterialInstance.SetScalarParameterValue(n"RippleCount", numRipples);

            for (int i = 0; i < numRipples; i++)
            {
                FVector rippleLoc = ActiveRipples[i];
                float rippleAge = RippleAges[i];
                
                WaterMaterialInstance.SetVectorParameterValue(
                    FName(f"RippleLocation{i}"), 
                    FLinearColor(rippleLoc.X, rippleLoc.Y, rippleLoc.Z, rippleAge));
                WaterMaterialInstance.SetScalarParameterValue(
                    FName(f"RippleStrength{i}"), 
                    RippleStrength * (1.0 - rippleAge));
            }
        }
    }

    private void CheckForShipHover()
    {
        // Find ship actor in world
        TArray<AShipActor> ships;
        GetAllActorsOfClass(ships);
        if (ships.Num() == 0)
            return;

        AShipActor ship = ships[0];
        FVector shipLoc = ship.ActorLocation;
        FVector waterLoc = Owner.ActorLocation;

        // Check if ship is near water surface
        float waterZ = waterLoc.Z;
        float shipZ = shipLoc.Z;
        float heightAboveWater = shipZ - waterZ;

        // If ship is hovering low over water (within 200 units)
        if (heightAboveWater > 0.0 && heightAboveWater < 200.0)
        {
            // Check if ship is within XY bounds of this water chunk
            FVector waterExtent = WaterMesh.Bounds.BoxExtent;
            float distX = Math::Abs(shipLoc.X - waterLoc.X);
            float distY = Math::Abs(shipLoc.Y - waterLoc.Y);

            if (distX < waterExtent.X && distY < waterExtent.Y)
            {
                // Create ripple at ship location
                CreateRipple(FVector(shipLoc.X, shipLoc.Y, waterZ));
            }
        }
    }
}
