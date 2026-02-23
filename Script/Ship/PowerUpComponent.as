// ============================================================
//  PowerUpComponent.as
//  Manages active power-ups on the ship (Shield, Magnet, etc).
//  Listens for power-up pickup events and applies effects with
//  timers. Broadcasts events for HUD and VFX systems.
// ============================================================

event void FOnPowerUpActivated(EPowerUpType Type, float Duration);
event void FOnPowerUpExpired(EPowerUpType Type);

class UPowerUpComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Active Power-Up State --------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Shield")
    bool bShieldActive = false;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Shield")
    float ShieldTimeRemaining = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Shield")
    float ShieldDuration = 5.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Magnet")
    bool bMagnetActive = false;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Magnet")
    float MagnetTimeRemaining = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Magnet")
    float MagnetDuration = 5.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Magnet")
    float MagnetRadius = 1500.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|Magnet")
    float MagnetSpeed = 800.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|SpeedBoost")
    bool bSpeedBoostActive = false;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|SpeedBoost")
    float SpeedBoostTimeRemaining = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|SpeedBoost")
    float SpeedBoostDuration = 5.0;

    UPROPERTY(BlueprintReadOnly, Category = "PowerUp|SpeedBoost")
    float SpeedBoostMultiplier = 1.5;

    // ---- Events -----------------------------------------------

    UPROPERTY()
    FOnPowerUpActivated OnPowerUpActivated;

    UPROPERTY()
    FOnPowerUpExpired OnPowerUpExpired;

    // ---- Lifecycle --------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Listen for power-up pickups in the world
        TArray<APowerUpPickupActor> pickups;
        GetAllActorsOfClass(pickups);
        for (int i = 0; i < pickups.Num(); i++)
        {
            pickups[i].OnPowerUpPickedUp.AddUFunction(this, n"OnPowerUpPickedUp");
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Update shield timer
        if (bShieldActive)
        {
            ShieldTimeRemaining -= DeltaSeconds;
            if (ShieldTimeRemaining <= 0.0)
                DeactivateShield();
        }

        // Update magnet timer and attract collectibles
        if (bMagnetActive)
        {
            MagnetTimeRemaining -= DeltaSeconds;
            if (MagnetTimeRemaining <= 0.0)
                DeactivateMagnet();
            else
                UpdateMagnetAttraction(DeltaSeconds);
        }

        // Update speed boost timer
        if (bSpeedBoostActive)
        {
            SpeedBoostTimeRemaining -= DeltaSeconds;
            if (SpeedBoostTimeRemaining <= 0.0)
                DeactivateSpeedBoost();
        }
    }

    // ---- Event Handlers ---------------------------------------

    UFUNCTION()
    private void OnPowerUpPickedUp(FPowerUpEffectConfig Effect)
    {
        if (bShowDebug)
            Print(f"[PowerUp] Picked up {Effect.Type}");

        if (Effect.Type == EPowerUpType::Shield)
            ActivateShield(Effect.Duration);
        else if (Effect.Type == EPowerUpType::MagnetCollector)
            ActivateMagnet(Effect.Duration, Effect.AttractionRadius, Effect.AttractionSpeed);
        else if (Effect.Type == EPowerUpType::SpeedBoost)
            ActivateSpeedBoost(Effect.Duration, Effect.SpeedMultiplier);
        else if (Effect.Type == EPowerUpType::Boost)
        {
            // Trigger ship's boost component
            UBoostComponent Boost = UBoostComponent::Get(Owner);
            if (Boost != nullptr)
                Boost.ActivateBoost();
        }
    }

    // ---- Shield -----------------------------------------------

    UFUNCTION()
    void ActivateShield(float Duration)
    {
        bShieldActive = true;
        ShieldTimeRemaining = Duration;
        ShieldDuration = Duration;

        OnPowerUpActivated.Broadcast(EPowerUpType::Shield, Duration);

        if (bShowDebug)
            Print(f"[PowerUp] Shield activated for {Duration:.1f}s");
    }

    private void DeactivateShield()
    {
        bShieldActive = false;
        ShieldTimeRemaining = 0.0;

        OnPowerUpExpired.Broadcast(EPowerUpType::Shield);

        if (bShowDebug)
            Print("[PowerUp] Shield expired");
    }

    UFUNCTION(BlueprintPure)
    bool HasShield() const
    {
        return bShieldActive;
    }

    // ---- Magnet -----------------------------------------------

    UFUNCTION()
    void ActivateMagnet(float Duration, float Radius, float Speed)
    {
        bMagnetActive = true;
        MagnetTimeRemaining = Duration;
        MagnetDuration = Duration;
        MagnetRadius = Radius;
        MagnetSpeed = Speed;

        OnPowerUpActivated.Broadcast(EPowerUpType::MagnetCollector, Duration);

        if (bShowDebug)
            Print(f"[PowerUp] Magnet activated for {Duration:.1f}s (radius={Radius:.0f})");
    }

    private void DeactivateMagnet()
    {
        bMagnetActive = false;
        MagnetTimeRemaining = 0.0;

        OnPowerUpExpired.Broadcast(EPowerUpType::MagnetCollector);

        if (bShowDebug)
            Print("[PowerUp] Magnet expired");
    }

    private void UpdateMagnetAttraction(float DeltaSeconds)
    {
        FVector shipLoc = Owner.ActorLocation;

        // Find all collectibles in range
        TArray<ACollectibleActor> collectibles;
        GetAllActorsOfClass(collectibles);

        for (int i = 0; i < collectibles.Num(); i++)
        {
            ACollectibleActor collectible = collectibles[i];
            if (collectible == nullptr)
                continue;

            FVector collectibleLoc = collectible.ActorLocation;
            float dist = (collectibleLoc - shipLoc).Size();

            if (dist < MagnetRadius && dist > 50.0)
            {
                // Pull collectible toward ship
                FVector direction = (shipLoc - collectibleLoc).GetSafeNormal();
                FVector newLoc = collectibleLoc + direction * MagnetSpeed * DeltaSeconds;
                collectible.SetActorLocation(newLoc);
            }
        }
    }

    // ---- Speed Boost ------------------------------------------

    UFUNCTION()
    void ActivateSpeedBoost(float Duration, float Multiplier)
    {
        bSpeedBoostActive = true;
        SpeedBoostTimeRemaining = Duration;
        SpeedBoostDuration = Duration;
        SpeedBoostMultiplier = Multiplier;

        // Apply speed multiplier to forward movement
        UForwardMovementComponent Forward = UForwardMovementComponent::Get(Owner);
        if (Forward != nullptr)
        {
            Forward.MaxSpeed *= Multiplier;
        }

        OnPowerUpActivated.Broadcast(EPowerUpType::SpeedBoost, Duration);

        if (bShowDebug)
            Print(f"[PowerUp] SpeedBoost activated for {Duration:.1f}s (x{Multiplier:.1f})");
    }

    private void DeactivateSpeedBoost()
    {
        // Restore normal speed
        UForwardMovementComponent Forward = UForwardMovementComponent::Get(Owner);
        if (Forward != nullptr)
        {
            Forward.MaxSpeed /= SpeedBoostMultiplier;
        }

        bSpeedBoostActive = false;
        SpeedBoostTimeRemaining = 0.0;

        OnPowerUpExpired.Broadcast(EPowerUpType::SpeedBoost);

        if (bShowDebug)
            Print("[PowerUp] SpeedBoost expired");
    }
}
