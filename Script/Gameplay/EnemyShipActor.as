// ============================================================
//  EnemyShipActor.as
//  AI enemy ship with lane-based movement and a simple
//  state machine: Cruising (forward) / Avoiding (lane change).
//  Uses HoverComponent for floating. Mirrors Unity's EnemyShip.
// ============================================================

enum EEnemyState
{
    Cruising,
    Avoiding,
}

class AEnemyShipActor : AActor
{
    // ---- Components ----------------------------------------

    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent ShipMesh;
    default ShipMesh.SetSimulatePhysics(true);
    default ShipMesh.SetEnableGravity(true);
    default ShipMesh.SetCollisionProfileName(n"BlockAll");
    default ShipMesh.SetLinearDamping(0.8);
    default ShipMesh.SetAngularDamping(4.0);

    UPROPERTY(DefaultComponent)
    UHoverComponent Hover;
    default Hover.HoverHeight = 130.0;
    default Hover.SpringForce = 65.0;
    default Hover.Damping = 9.0;
    default Hover.bEnableBob = true;
    default Hover.BobAmplitude = 8.0;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Enemy|Movement")
    float ForwardSpeed = 800.0;

    UPROPERTY(EditAnywhere, Category = "Enemy|Movement")
    float ForwardThrust = 30.0;

    UPROPERTY(EditAnywhere, Category = "Enemy|Movement")
    float LateralThrust = 50.0;

    UPROPERTY(EditAnywhere, Category = "Enemy|Movement")
    float LateralDrag = 6.0;

    // ---- Lane config ----------------------------------------

    UPROPERTY(EditAnywhere, Category = "Enemy|Lanes")
    int NumberOfLanes = 5;

    UPROPERTY(EditAnywhere, Category = "Enemy|Lanes")
    float LaneWidth = 200.0;

    // ---- Avoidance ------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Enemy|Avoidance")
    float DetectionRange = 500.0;

    UPROPERTY(EditAnywhere, Category = "Enemy|Avoidance")
    float LaneChangeSpeed = 40.0;

    UPROPERTY(EditAnywhere, Category = "Enemy|Avoidance")
    float AvoidanceCooldown = 2.0;

    // ---- State ----------------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Enemy")
    EEnemyState CurrentState = EEnemyState::Cruising;

    UPROPERTY(BlueprintReadOnly, Category = "Enemy")
    int CurrentLane = 2;

    UPROPERTY(BlueprintReadOnly, Category = "Enemy")
    int TargetLane = 2;

    // ---- Internal -------------------------------------------

    private float AvoidanceCooldownTimer = 0.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Tags.Add(n"EnemyShip");

        // Start in a random lane
        CurrentLane = Math::RandRange(0, NumberOfLanes - 1);
        TargetLane = CurrentLane;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!ShipMesh.IsSimulatingPhysics())
            return;

        UpdateAvoidanceCooldown(DeltaSeconds);
        UpdateState();
        ApplyForwardThrust();
        ApplyLaneMovement();
        ApplyLateralDrag();

        if (bShowDebug)
            DebugDrawEnemyState();
    }

    // ---- State machine --------------------------------------

    private void UpdateState()
    {
        switch (CurrentState)
        {
            case EEnemyState::Cruising:
                CheckForObstacles();
                break;
            case EEnemyState::Avoiding:
                CheckLaneReached();
                break;
        }
    }

    private void CheckForObstacles()
    {
        if (AvoidanceCooldownTimer > 0.0)
            return;

        // Forward ray to detect obstacles ahead
        FVector origin = GetActorLocation();
        FVector traceEnd = origin + FVector(DetectionRange, 0.0, 0.0);

        FHitResult hit;
        TArray<AActor> ignoreActors;
        ignoreActors.Add(this);

        bool bHit = System::LineTraceSingle(
            origin, traceEnd,
            ETraceTypeQuery::Visibility,
            false, ignoreActors,
            EDrawDebugTrace::None,
            hit, true
        );

        if (bHit && hit.Actor != nullptr)
        {
            if (hit.Actor.ActorHasTag(n"Obstacle") || hit.Actor.ActorHasTag(n"EnemyShip"))
            {
                StartAvoidance();
            }
        }
    }

    private void StartAvoidance()
    {
        CurrentState = EEnemyState::Avoiding;

        // Pick a lane to dodge to (prefer away from edges)
        if (CurrentLane <= 0)
            TargetLane = CurrentLane + 1;
        else if (CurrentLane >= NumberOfLanes - 1)
            TargetLane = CurrentLane - 1;
        else
            TargetLane = (Math::RandRange(0.0, 1.0) > 0.5) ? CurrentLane + 1 : CurrentLane - 1;

        AvoidanceCooldownTimer = AvoidanceCooldown;
    }

    private void CheckLaneReached()
    {
        float targetY = GetLaneYPosition(TargetLane);
        float currentY = GetActorLocation().Y;

        if (Math::Abs(currentY - targetY) < 20.0)
        {
            CurrentLane = TargetLane;
            CurrentState = EEnemyState::Cruising;
        }
    }

    private void UpdateAvoidanceCooldown(float DeltaSeconds)
    {
        if (AvoidanceCooldownTimer > 0.0)
            AvoidanceCooldownTimer -= DeltaSeconds;
    }

    // ---- Movement -------------------------------------------

    private void ApplyForwardThrust()
    {
        FVector vel = ShipMesh.GetPhysicsLinearVelocity();
        float speedError = ForwardSpeed - vel.X;

        if (speedError > 0.1)
        {
            float thrust = speedError * ForwardThrust;
            ShipMesh.AddForce(FVector(thrust, 0.0, 0.0), NAME_None, true);
        }
    }

    private void ApplyLaneMovement()
    {
        float targetY = GetLaneYPosition(TargetLane);
        float currentY = GetActorLocation().Y;
        float error = targetY - currentY;

        if (Math::Abs(error) > 5.0)
        {
            float force = error * LaneChangeSpeed;
            ShipMesh.AddForce(FVector(0.0, force, 0.0), NAME_None, true);
        }
    }

    private void ApplyLateralDrag()
    {
        FVector vel = ShipMesh.GetPhysicsLinearVelocity();
        float dampY = -vel.Y * LateralDrag;
        ShipMesh.AddForce(FVector(0.0, dampY, 0.0), NAME_None, true);
    }

    // ---- Helpers --------------------------------------------

    private float GetLaneYPosition(int LaneIndex) const
    {
        return (LaneIndex - (NumberOfLanes - 1) / 2.0) * LaneWidth;
    }

    private void DebugDrawEnemyState()
    {
        FVector pos = GetActorLocation();

        // Forward detection ray (red)
        FVector rayEnd = pos + FVector(DetectionRange, 0.0, 0.0);
        System::DrawDebugLine(pos, rayEnd, FLinearColor::Red, 0.0, 1.0);

        // Lane target line (yellow)
        float targetY = GetLaneYPosition(TargetLane);
        FVector laneStart = FVector(pos.X, targetY, pos.Z);
        FVector laneEnd = FVector(pos.X + 300.0, targetY, pos.Z);
        System::DrawDebugLine(laneStart, laneEnd, FLinearColor::Yellow, 0.0, 2.0);

        // State text
        FString stateStr = (CurrentState == EEnemyState::Cruising) ? "Cruise" : "Avoid";
        FString enemyText = f"Enemy:{stateStr} Lane:{CurrentLane}->{TargetLane}";
        System::DrawDebugString(pos + FVector(0.0, 0.0, 200.0), enemyText,
            nullptr, FLinearColor::Red, 0.0);
    }
}
