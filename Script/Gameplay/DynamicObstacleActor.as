// ============================================================
//  DynamicObstacleActor.as
//  Physics-driven obstacle that hovers and drifts sideways.
//  Uses HoverComponent for floating + sinusoidal lateral drift.
//  Mirrors Unity's DynamicObstacle.
// ============================================================

class ADynamicObstacleActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent ObstacleMesh;
    default ObstacleMesh.SetSimulatePhysics(true);
    default ObstacleMesh.SetEnableGravity(true);
    default ObstacleMesh.SetCollisionProfileName(n"BlockAll");
    default ObstacleMesh.SetLinearDamping(1.0);
    default ObstacleMesh.SetAngularDamping(3.0);

    UPROPERTY(DefaultComponent)
    UHoverComponent Hover;
    default Hover.HoverHeight = 120.0;
    default Hover.SpringForce = 60.0;
    default Hover.Damping = 8.0;
    default Hover.bEnableBob = false;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    // Lateral drift force amplitude.
    UPROPERTY(EditAnywhere, Category = "Obstacle")
    float DriftForce = 20.0;

    // Drift oscillation frequency (Hz).
    UPROPERTY(EditAnywhere, Category = "Obstacle")
    float DriftFrequency = 0.4;

    // Lateral drag to limit max drift speed.
    UPROPERTY(EditAnywhere, Category = "Obstacle")
    float LateralDrag = 4.0;

    // ---- Internal -------------------------------------------

    private float DriftPhase = 0.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Tags.Add(n"Obstacle");
        DriftPhase = Math::RandRange(0.0, PI * 2.0);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (!ObstacleMesh.IsSimulatingPhysics())
            return;

        // Sinusoidal lateral drift
        float t = System::GameTimeInSeconds * DriftFrequency * PI * 2.0 + DriftPhase;
        float lateralForce = Math::Sin(t) * DriftForce;
        ObstacleMesh.AddForce(FVector(0.0, lateralForce, 0.0), NAME_None, true);

        // Lateral drag
        FVector vel = ObstacleMesh.GetPhysicsLinearVelocity();
        float dampY = -vel.Y * LateralDrag;
        ObstacleMesh.AddForce(FVector(0.0, dampY, 0.0), NAME_None, true);

        if (bShowDebug)
        {
            FVector pos = GetActorLocation();
            // Drift direction arrow
            System::DrawDebugArrow(pos, pos + FVector(0.0, lateralForce * 5.0, 0.0), 15.0,
                FLinearColor(1.0, 0.3, 0.0, 1.0), 0.0, 1.5);
            System::DrawDebugString(pos + FVector(0.0, 0.0, 150.0), "Obstacle",
                nullptr, FLinearColor(1.0, 0.3, 0.0, 1.0), 0.0);
        }
    }
}
