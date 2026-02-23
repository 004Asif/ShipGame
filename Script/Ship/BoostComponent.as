// ============================================================
//  BoostComponent.as
//  Timed speed boost for the player ship. Listens for boost
//  input from ShipInputComponent and applies a speed multiplier
//  to ForwardMovementComponent for a configured duration.
// ============================================================

event void FOnBoostStarted();
event void FOnBoostEnded();

class UBoostComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Boost")
    float SpeedMultiplier = 1.8;

    UPROPERTY(EditAnywhere, Category = "Boost")
    float Duration = 3.0;

    // Cooldown between boosts (seconds).
    UPROPERTY(EditAnywhere, Category = "Boost")
    float Cooldown = 5.0;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnBoostStarted OnBoostStarted;

    UPROPERTY()
    FOnBoostEnded OnBoostEnded;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Boost")
    bool bIsBoosting = false;

    UPROPERTY(BlueprintReadOnly, Category = "Boost")
    bool bOnCooldown = false;

    UPROPERTY(BlueprintReadOnly, Category = "Boost")
    float BoostTimeRemaining = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Boost")
    float CooldownRemaining = 0.0;

    // ---- Internal -------------------------------------------

    private float PreBoostSpeed = 0.0;
    private float TargetBoostSpeed = 0.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        // Check for boost input from sibling ShipInputComponent
        UShipInputComponent Input = UShipInputComponent::Get(GetOwner());
        if (Input != nullptr && Input.bBoostPressed && !bIsBoosting && !bOnCooldown)
        {
            ActivateBoost();
        }

        // Update timers and smooth speed
        if (bIsBoosting)
        {
            UForwardMovementComponent Forward = UForwardMovementComponent::Get(GetOwner());
            if (Forward != nullptr)
            {
                Forward.SetSpeedInterpolated(TargetBoostSpeed, DeltaSeconds, 4.0);
            }

            // Continuous rumble while boosting
            UCameraFollowComponent CameraFollow = UCameraFollowComponent::Get(GetOwner());
            if (CameraFollow != nullptr)
            {
                // Re-trigger small shake every tick to simulate engine rumble
                CameraFollow.Shake(8.0, 0.2);
            }

            BoostTimeRemaining -= DeltaSeconds;
            if (BoostTimeRemaining <= 0.0)
                DeactivateBoost();
        }

        if (bOnCooldown)
        {
            CooldownRemaining -= DeltaSeconds;
            if (CooldownRemaining <= 0.0)
                bOnCooldown = false;
        }
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void ActivateBoost()
    {
        if (bIsBoosting)
            return;

        UForwardMovementComponent Forward = UForwardMovementComponent::Get(GetOwner());
        if (Forward == nullptr)
            return;

        PreBoostSpeed = Forward.CurrentSpeed;
        Forward.bIsBoosting = true;
        
        // Boost is handled gracefully in Tick now so it smooths into the target speed
        TargetBoostSpeed = PreBoostSpeed * SpeedMultiplier;

        bIsBoosting = true;
        BoostTimeRemaining = Duration;

        OnBoostStarted.Broadcast();

        UCameraFollowComponent CameraFollow = UCameraFollowComponent::Get(GetOwner());
        if (CameraFollow != nullptr)
        {
            // Add a small initial punch shake for the boost
            CameraFollow.Shake(20.0, 0.4);
        }

        if (bShowDebug)
            Print(f"[Boost] ACTIVATED! {PreBoostSpeed:.0f} x{SpeedMultiplier:.1f} = {TargetBoostSpeed:.0f} for {Duration:.1f}s");
    }

    // ---- Internal -------------------------------------------

    private void DeactivateBoost()
    {
        UForwardMovementComponent Forward = UForwardMovementComponent::Get(GetOwner());
        if (Forward != nullptr)
        {
            Forward.bIsBoosting = false;
            // Let the UpdateSpeed logic gracefully handle slowing down to MaxSpeed
        }

        bIsBoosting = false;
        bOnCooldown = true;
        CooldownRemaining = Cooldown;

        OnBoostEnded.Broadcast();

        if (bShowDebug)
            Print(f"[Boost] ENDED! Cooldown={Cooldown:.1f}s");
    }
}
