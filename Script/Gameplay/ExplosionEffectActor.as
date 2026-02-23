// ============================================================
//  ExplosionEffectActor.as
//  Spawns a particle effect and auto-destroys after duration.
//  Spawn at the death location of a ship or obstacle.
// ============================================================

class AExplosionEffectActor : AActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UNiagaraComponent ExplosionFX;

    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Explosion")
    float Lifetime = 2.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        if (ExplosionFX != nullptr)
            ExplosionFX.Activate(true);

        if (bShowDebug)
        {
            Print(f"[Explosion] Spawned at {GetActorLocation()} Lifetime={Lifetime:.1f}s");
            System::DrawDebugSphere(GetActorLocation(), 200.0, 12,
                FLinearColor(1.0, 0.5, 0.0, 1.0), Lifetime, 2.0);
        }

        System::SetTimer(this, n"OnLifetimeExpired", Lifetime, false);
    }

    UFUNCTION()
    private void OnLifetimeExpired()
    {
        DestroyActor();
    }
}
