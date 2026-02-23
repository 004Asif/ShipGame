// ============================================================
//  CollectibleActor.as
//  Artifact collectible. Spins in place, collected on overlap
//  with the player. Awards score via ScoreSubsystem.
// ============================================================

class ACollectibleActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent CollisionSphere;
    default CollisionSphere.SetSphereRadius(50.0);
    default CollisionSphere.SetCollisionProfileName(n"OverlapAllDynamic");
    default CollisionSphere.SetGenerateOverlapEvents(true);

    UPROPERTY(DefaultComponent, Attach = CollisionSphere)
    UStaticMeshComponent Mesh;
    default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
    default Mesh.SetCastShadow(false);

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Collectible")
    float RotationSpeed = 120.0;

    UPROPERTY(EditAnywhere, Category = "Collectible")
    float BobAmplitude = 20.0;

    UPROPERTY(EditAnywhere, Category = "Collectible")
    float BobFrequency = 2.0;

    // ---- Internal -------------------------------------------

    private float BobPhase = 0.0;
    private float BaseZ = 0.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Tags.Add(n"Collectible");
        BobPhase = Math::RandRange(0.0, PI * 2.0);
        BaseZ = GetActorLocation().Z;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Spin
        FRotator rot = GetActorRotation();
        rot.Yaw += RotationSpeed * DeltaSeconds;
        SetActorRotation(rot);

        // Bob up/down
        float t = System::GameTimeInSeconds * BobFrequency * PI * 2.0 + BobPhase;
        float newZ = BaseZ + Math::Sin(t) * BobAmplitude;
        FVector pos = GetActorLocation();
        pos.Z = newZ;
        SetActorLocation(pos);
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (OtherActor == nullptr)
            return;

        if (OtherActor.IsA(AShipActor))
        {
            if (bShowDebug)
                Print(f"[Collectible] Collected at {GetActorLocation()}");

            UScoreSubsystem ScoreSub = UScoreSubsystem::Get();
            if (ScoreSub != nullptr)
                ScoreSub.HandleArtifactCollected();

            SetActorHiddenInGame(true);
            SetActorEnableCollision(false);
        }
    }
}
