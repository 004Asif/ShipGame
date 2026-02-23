// ============================================================
//  ShipActor.as
//  Thin pawn container — all behaviour lives in components.
//  Create a Blueprint child and assign the mesh + materials.
// ============================================================

event void FOnShipDied();
event void FOnArtifactCollected(AActor Artifact);

class AShipActor : APawn
{
    // ---- Components ----------------------------------------

    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent CollisionRoot;
    default CollisionRoot.SetSimulatePhysics(true);
    default CollisionRoot.SetEnableGravity(true);
    default CollisionRoot.SetCollisionProfileName(n"Pawn");
    default CollisionRoot.SetLinearDamping(0.5);
    default CollisionRoot.SetAngularDamping(2.0);
    default CollisionRoot.SphereRadius = 120.0;

    UPROPERTY(DefaultComponent, Attach = CollisionRoot)
    UStaticMeshComponent ShipMesh;
    default ShipMesh.SetSimulatePhysics(false);
    default ShipMesh.SetCollisionProfileName(n"NoCollision");

    UPROPERTY(DefaultComponent)
    UHoverComponent Hover;

    UPROPERTY(DefaultComponent)
    UForwardMovementComponent ForwardMovement;

    UPROPERTY(DefaultComponent)
    ULateralMovementComponent LateralMovement;

    UPROPERTY(DefaultComponent)
    UShipInputComponent ShipInput;

    UPROPERTY(DefaultComponent)
    UBoostComponent Boost;

    UPROPERTY(DefaultComponent)
    UNearMissComponent NearMiss;

    UPROPERTY(DefaultComponent)
    UPowerUpComponent PowerUp;

    // ---- Camera (SpringArm + Camera on the pawn) ------------

    UPROPERTY(DefaultComponent, Attach = CollisionRoot)
    USpringArmComponent SpringArm;

    UPROPERTY(DefaultComponent, Attach = SpringArm)
    UCameraComponent ShipCamera;

    UPROPERTY(DefaultComponent)
    UCameraFollowComponent CameraFollow;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events --------------------------------------------

    UPROPERTY()
    FOnShipDied OnShipDied;

    UPROPERTY()
    FOnArtifactCollected OnArtifactCollected;

    // ---- Configuration -------------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship")
    FShipData ShipConfig;

    // ---- State ---------------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Ship")
    bool bIsDying = false;

    UPROPERTY(BlueprintReadOnly, Category = "Ship")
    float DistanceTraveled = 0.0;

    private FVector LastPosition;

    // ---- Lifecycle -----------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Disconnect visual mesh and camera from physics tumbling
        ShipMesh.SetAbsolute(false, true, false);
        SpringArm.SetAbsolute(false, true, false);

        LastPosition = GetActorLocation();
        ApplyShipConfig();

        if (bShowDebug)
            Print(f"[Ship] BeginPlay at {LastPosition}. Physics={CollisionRoot.IsSimulatingPhysics()}");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        UpdateDistanceTraveled();

        if (bShowDebug)
            DebugDrawShipState();
    }

    // ---- Public API ----------------------------------------

    // Called by GameFlowSubsystem to trigger death.
    UFUNCTION()
    void TriggerDeathSequence()
    {
        if (bIsDying)
            return;

        bIsDying = true;
        OnShipDied.Broadcast();

        if (CameraFollow != nullptr)
        {
            CameraFollow.Shake(40.0, 0.8);
        }

        if (bShowDebug)
            Print(f"[Ship] DIED at {GetActorLocation()} dist={DistanceTraveled:.0f}");

        // Disable physics and hide
        CollisionRoot.SetSimulatePhysics(false);
        SetActorHiddenInGame(true);
        SetActorEnableCollision(false);
    }

    // Enable physics for gameplay (called after intro animation).
    UFUNCTION()
    void EnableGameplayPhysics()
    {
        CollisionRoot.SetSimulatePhysics(true);
        CollisionRoot.SetEnableGravity(true);

        // Give a gentle forward impulse so the ship doesn't stall
        CollisionRoot.AddImpulse(FVector(ShipConfig.InitialForwardSpeed * 0.5, 0.0, 0.0), NAME_None, true);

        if (bShowDebug)
            Print(f"[Ship] Physics ENABLED. Impulse={ShipConfig.InitialForwardSpeed * 0.5:.0f}");
    }

    // Disable physics for intro animation (kinematic mode).
    UFUNCTION()
    void SetKinematicMode()
    {
        CollisionRoot.SetSimulatePhysics(false);
        CollisionRoot.SetEnableGravity(false);
    }

    // ---- Collision -----------------------------------------

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (bIsDying)
            return;

        // Check tags on overlapping actor for game logic
        if (OtherActor.ActorHasTag(n"Collectible"))
        {
            if (bShowDebug) Print(f"[Ship] Collected artifact: {OtherActor.Name}");
            OnArtifactCollected.Broadcast(OtherActor);
            OtherActor.SetActorHiddenInGame(true);
            OtherActor.SetActorEnableCollision(false);
        }
        else if (OtherActor.ActorHasTag(n"Obstacle") || OtherActor.ActorHasTag(n"EnemyShip"))
        {
            if (bShowDebug) Print(f"[Ship] HIT obstacle/enemy: {OtherActor.Name}");
            TriggerDeathSequence();
        }
    }

    UFUNCTION(BlueprintOverride)
    void Hit(
        UPrimitiveComponent MyComp,
        AActor Other,
        UPrimitiveComponent OtherComp,
        bool bSelfMoved,
        FVector HitLocation,
        FVector HitNormal,
        FVector NormalImpulse,
        const FHitResult&in HitResult)
    {
        if (bIsDying)
            return;

        if (Other != nullptr && Other.ActorHasTag(n"Obstacle"))
        {
            TriggerDeathSequence();
        }
    }

    // ---- Internal ------------------------------------------

    private void ApplyShipConfig()
    {
        // Push config values down to components
        Hover.HoverHeight = ShipConfig.HoverHeight;
        Hover.SpringForce = ShipConfig.HoverSpringForce;
        Hover.Damping = ShipConfig.HoverDamping;
        Hover.RaycastDistance = ShipConfig.HoverRaycastDistance;

        ForwardMovement.InitialSpeed = ShipConfig.InitialForwardSpeed;
        ForwardMovement.MaxSpeed = ShipConfig.MaxForwardSpeed;
        ForwardMovement.AccelerationRate = ShipConfig.AccelerationRate;
        ForwardMovement.ForwardThrust = ShipConfig.ForwardThrust;

        LateralMovement.LateralThrust = ShipConfig.LateralThrust;
        LateralMovement.LateralDrag = ShipConfig.LateralDrag;
        LateralMovement.InputSensitivity = ShipConfig.ButtonInputSensitivity;
        LateralMovement.SpeedThrustScaling = ShipConfig.SpeedThrustScaling;
        LateralMovement.SpeedForMaxThrust = ShipConfig.SpeedForMaxThrust;
        LateralMovement.MinThrustMultiplier = ShipConfig.MinThrustMultiplier;
        LateralMovement.SpeedInputResponsiveness = ShipConfig.SpeedInputResponsiveness;
        LateralMovement.MaxBankAngle = ShipConfig.MaxBankAngle;
        LateralMovement.SpeedBankScaling = ShipConfig.SpeedBankScaling;
        LateralMovement.TerrainAlignSpeed = ShipConfig.TerrainAlignSpeed;
        LateralMovement.NumberOfLanes = ShipConfig.NumberOfLanes;
        LateralMovement.LaneWidth = ShipConfig.LaneWidth;
        LateralMovement.EdgeSpringForce = ShipConfig.EdgeSpringForce;

        Boost.SpeedMultiplier = ShipConfig.BoostSpeedMultiplier;
        Boost.Duration = ShipConfig.BoostDuration;

        CollisionRoot.SetLinearDamping(ShipConfig.LinearDrag);
        CollisionRoot.SetAngularDamping(ShipConfig.AngularDrag);
    }

    private void UpdateDistanceTraveled()
    {
        FVector currentPos = GetActorLocation();
        float frameDist = (currentPos - LastPosition).Size();
        DistanceTraveled += frameDist;
        LastPosition = currentPos;
    }

    private void DebugDrawShipState()
    {
        FVector pos = GetActorLocation();
        FVector vel = CollisionRoot.GetPhysicsLinearVelocity();

        // Velocity arrow (green = forward, cyan = full velocity)
        System::DrawDebugArrow(pos, pos + FVector(vel.X * 0.1, 0.0, 0.0), 20.0,
            FLinearColor::Green, 0.0, 2.0);
        System::DrawDebugArrow(pos, pos + vel * 0.1, 15.0,
            FLinearColor(0.0, 1.0, 1.0, 1.0), 0.0, 1.0);

        // Ship state text above the ship
        FVector textPos = pos + FVector(0.0, 0.0, 350.0);
        FString stateText = f"Spd:{vel.Size():.0f} Dist:{DistanceTraveled:.0f} Dying:{bIsDying}";
        System::DrawDebugString(textPos, stateText, nullptr, FLinearColor::White, 0.0);
    }
}
