// ============================================================
//  PowerUpPickupActor.as
//  Trigger pickup that applies a power-up effect to the ship.
//  Spins and bobs like a collectible. On overlap with the
//  player, broadcasts an event so PowerUpComponent can handle.
// ============================================================

event void FOnPowerUpPickedUp(FPowerUpEffectConfig Effect);

class APowerUpPickupActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USphereComponent CollisionSphere;
    default CollisionSphere.SetSphereRadius(60.0);
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

    UPROPERTY(EditAnywhere, Category = "PowerUp")
    FPowerUpEffectConfig PowerUpEffect;

    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float RotationSpeed = 180.0;

    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float BobAmplitude = 25.0;

    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float BobFrequency = 1.5;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnPowerUpPickedUp OnPowerUpPickedUp;

    // ---- Internal -------------------------------------------

    private float BobPhase = 0.0;
    private float BaseZ = 0.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Tags.Add(n"PowerUp");
        BobPhase = Math::RandRange(0.0, PI * 2.0);
        BaseZ = GetActorLocation().Z;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        FRotator rot = GetActorRotation();
        rot.Yaw += RotationSpeed * DeltaSeconds;
        SetActorRotation(rot);

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
                Print(f"[PowerUp] Picked up at {GetActorLocation()}");

            OnPowerUpPickedUp.Broadcast(PowerUpEffect);

            SetActorHiddenInGame(true);
            SetActorEnableCollision(false);
        }
    }
}
