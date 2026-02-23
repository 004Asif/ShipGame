// ============================================================
//  LateralMovementComponent.as
//  Lateral (Y-axis) movement from player input + banking rotation.
//  Also constrains the ship within the playable corridor.
// ============================================================

event void FOnEdgeHit(float Overshoot);

class ULateralMovementComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Lateral")
    float LateralThrust = 1500.0;

    UPROPERTY(EditAnywhere, Category = "Lateral")
    float LateralDrag = 12.0;

    UPROPERTY(EditAnywhere, Category = "Lateral")
    float InputSensitivity = 1.0;

    // ---- Speed-dependent turning -----------------------------

    // How much lateral thrust scales with forward speed (0 = no scaling, 1 = full)
    UPROPERTY(EditAnywhere, Category = "Lateral|SpeedScaling")
    float SpeedThrustScaling = 0.6;

    // Forward speed at which max thrust scaling is reached (cm/s)
    UPROPERTY(EditAnywhere, Category = "Lateral|SpeedScaling")
    float SpeedForMaxThrust = 3000.0;

    // Minimum thrust multiplier at zero speed
    UPROPERTY(EditAnywhere, Category = "Lateral|SpeedScaling")
    float MinThrustMultiplier = 0.5;

    // How much faster input smoothing becomes at high speed
    UPROPERTY(EditAnywhere, Category = "Lateral|SpeedScaling")
    float SpeedInputResponsiveness = 1.5;

    // ---- Banking --------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Lateral|Banking")
    float MaxBankAngle = 35.0;

    UPROPERTY(EditAnywhere, Category = "Lateral|Banking")
    float TerrainAlignSpeed = 8.0;

    // Bank angle also scales with speed for a sportier feel
    UPROPERTY(EditAnywhere, Category = "Lateral|Banking")
    float SpeedBankScaling = 0.3;

    // ---- Corridor constraints -------------------------------

    UPROPERTY(EditAnywhere, Category = "Lateral|Constraints")
    int NumberOfLanes = 5;

    UPROPERTY(EditAnywhere, Category = "Lateral|Constraints")
    float LaneWidth = 200.0;

    UPROPERTY(EditAnywhere, Category = "Lateral|Constraints")
    float EdgeSpringForce = 100.0;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnEdgeHit OnEdgeHit;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Lateral")
    float HorizontalInput = 0.0;

    // ---- Internal -------------------------------------------

    private UPrimitiveComponent PrimitiveRoot;
    private float SmoothedInput = 0.0;
    private FVector CachedTerrainNormal = FVector(0.0, 0.0, 1.0);

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor != nullptr)
            PrimitiveRoot = Cast<UPrimitiveComponent>(OwnerActor.GetRootComponent());
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (PrimitiveRoot == nullptr)
            return;

        if (!PrimitiveRoot.IsSimulatingPhysics())
            return;

        // Read terrain normal from hover component if available
        UHoverComponent Hover = UHoverComponent::Get(GetOwner());
        if (Hover != nullptr)
            CachedTerrainNormal = Hover.TerrainNormal;

        ApplyLateralForces();
        ApplyRotation(DeltaSeconds);
        ConstrainPosition();

        if (bShowDebug)
            DebugDrawLateralState();
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void SetInput(float Input)
    {
        HorizontalInput = Input * InputSensitivity;
    }

    UFUNCTION(BlueprintPure)
    float GetMapHalfWidth() const
    {
        return LaneWidth * ((NumberOfLanes - 1) / 2.0) + LaneWidth * 0.5;
    }

    UFUNCTION(BlueprintPure)
    float GetLaneXPosition(int LaneIndex) const
    {
        return (LaneIndex - (NumberOfLanes - 1) / 2.0) * LaneWidth;
    }

    // ---- Internal -------------------------------------------

    private void ApplyLateralForces()
    {
        FVector vel = PrimitiveRoot.GetPhysicsLinearVelocity();
        float forwardSpeed = Math::Abs(vel.X);

        // Speed-dependent thrust: faster ship = stronger turning
        float speedRatio = Math::Clamp(forwardSpeed / Math::Max(SpeedForMaxThrust, 1.0), 0.0, 1.0);
        float thrustMultiplier = Math::Lerp(MinThrustMultiplier, 1.0 + SpeedThrustScaling, speedRatio);
        float effectiveThrust = LateralThrust * thrustMultiplier;

        // Lateral thrust from input
        float lateralForce = HorizontalInput * effectiveThrust;
        PrimitiveRoot.AddForce(FVector(0.0, lateralForce, 0.0), NAME_None, true);

        // Speed-adaptive drag: slightly more drag at high speed to prevent runaway
        float effectiveDrag = LateralDrag * (1.0 + speedRatio * 0.3);
        float dampForce = -vel.Y * effectiveDrag;
        PrimitiveRoot.AddForce(FVector(0.0, dampForce, 0.0), NAME_None, true);
    }

    private void ApplyRotation(float DeltaSeconds)
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr)
            return;

        AShipActor Ship = Cast<AShipActor>(OwnerActor);
        if (Ship == nullptr)
            return;

        // Speed-adaptive input smoothing: faster response at higher speed
        FVector vel = PrimitiveRoot.GetPhysicsLinearVelocity();
        float forwardSpeed = Math::Abs(vel.X);
        float speedRatio = Math::Clamp(forwardSpeed / Math::Max(SpeedForMaxThrust, 1.0), 0.0, 1.0);
        float smoothRate = 12.0 * (1.0 + speedRatio * SpeedInputResponsiveness);
        SmoothedInput = Math::Lerp(SmoothedInput, HorizontalInput, DeltaSeconds * smoothRate);

        // Terrain alignment pitch from ground normal
        float terrainPitch = Math::RadiansToDegrees(Math::Atan2(CachedTerrainNormal.X, CachedTerrainNormal.Z));

        // Bank/roll from smoothed input, with speed scaling
        float effectiveBankAngle = MaxBankAngle * (1.0 + speedRatio * SpeedBankScaling);
        float bankAngle = SmoothedInput * effectiveBankAngle;

        // Add slight yaw visual rotation for immersion (visual only)
        float yawOffset = SmoothedInput * 5.0 * speedRatio;

        FRotator targetRot = FRotator(terrainPitch, yawOffset, bankAngle);

        // Smooth rotation interpolation on the visual mesh only
        FRotator currentRot = Ship.ShipMesh.GetWorldRotation();
        float effectiveAlignSpeed = TerrainAlignSpeed * (1.0 + speedRatio * 0.5);
        FRotator newRot = Math::RInterpTo(currentRot, targetRot, DeltaSeconds, effectiveAlignSpeed);
        
        Ship.ShipMesh.SetWorldRotation(newRot);
    }

    private void ConstrainPosition()
    {
        float mapHalfWidth = GetMapHalfWidth();
        FVector pos = PrimitiveRoot.GetWorldLocation();
        float overshoot = 0.0;

        if (pos.Y < -mapHalfWidth)
            overshoot = -mapHalfWidth - pos.Y;
        else if (pos.Y > mapHalfWidth)
            overshoot = mapHalfWidth - pos.Y;

        if (Math::Abs(overshoot) > 1.0)
        {
            float springForce = overshoot * EdgeSpringForce;
            PrimitiveRoot.AddForce(FVector(0.0, springForce, 0.0), NAME_None, true);

            if (Math::Abs(overshoot) > 5.0)
                OnEdgeHit.Broadcast(overshoot);
        }
    }

    private void DebugDrawLateralState()
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr) return;

        FVector pos = OwnerActor.ActorLocation;
        float mapHalfWidth = GetMapHalfWidth();
        float drawLen = 600.0;

        // Corridor bounds (orange vertical lines)
        FLinearColor orange = FLinearColor(1.0, 0.5, 0.0, 1.0);
        FVector leftWallBase = FVector(pos.X, -mapHalfWidth, pos.Z - 100.0);
        FVector leftWallTop = FVector(pos.X, -mapHalfWidth, pos.Z + 300.0);
        FVector rightWallBase = FVector(pos.X, mapHalfWidth, pos.Z - 100.0);
        FVector rightWallTop = FVector(pos.X, mapHalfWidth, pos.Z + 300.0);
        System::DrawDebugLine(leftWallBase, leftWallTop, orange, 0.0, 3.0);
        System::DrawDebugLine(rightWallBase, rightWallTop, orange, 0.0, 3.0);

        // Lane center lines (dim white)
        FLinearColor dimWhite = FLinearColor(0.5, 0.5, 0.5, 0.5);
        for (int i = 0; i < NumberOfLanes; i++)
        {
            float laneY = GetLaneXPosition(i);
            FVector laneStart = FVector(pos.X - drawLen, laneY, pos.Z - 50.0);
            FVector laneEnd = FVector(pos.X + drawLen, laneY, pos.Z - 50.0);
            System::DrawDebugLine(laneStart, laneEnd, dimWhite, 0.0, 0.5);
        }

        // Lateral input arrow (yellow)
        if (Math::Abs(HorizontalInput) > 0.01)
        {
            FVector inputEnd = pos + FVector(0.0, HorizontalInput * 200.0, 0.0);
            System::DrawDebugArrow(pos, inputEnd, 20.0,
                FLinearColor::Yellow, 0.0, 2.0);
        }
    }
}
