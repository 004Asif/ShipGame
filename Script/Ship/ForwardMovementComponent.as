// ============================================================
//  ForwardMovementComponent.as
//  Automatic forward acceleration along +X axis.
//  Reads tuning from FShipData on the owning actor.
// ============================================================

event void FOnSpeedChanged(float NewSpeed, float MaxSpeed);

class UForwardMovementComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Forward")
    float InitialSpeed = 1200.0;

    UPROPERTY(EditAnywhere, Category = "Forward")
    float MaxSpeed = 3000.0;

    UPROPERTY(EditAnywhere, Category = "Forward")
    float AccelerationRate = 30.0;

    UPROPERTY(EditAnywhere, Category = "Forward")
    float ForwardThrust = 40.0;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnSpeedChanged OnSpeedChanged;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Forward")
    float CurrentSpeed = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Forward")
    bool bIsBoosting = false;

    // ---- Internal -------------------------------------------

    private UPrimitiveComponent PrimitiveRoot;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CurrentSpeed = InitialSpeed;

        AActor OwnerActor = GetOwner();
        if (OwnerActor != nullptr)
            PrimitiveRoot = Cast<UPrimitiveComponent>(OwnerActor.GetRootComponent());

        if (bShowDebug)
            Print(f"[Forward] BeginPlay. InitialSpeed={InitialSpeed:.0f} MaxSpeed={MaxSpeed:.0f}");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (PrimitiveRoot == nullptr)
            return;

        if (!PrimitiveRoot.IsSimulatingPhysics())
            return;

        UpdateSpeed(DeltaSeconds);
        ApplyForwardThrust();

        if (bShowDebug)
            DebugDrawForwardState();
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void SetSpeed(float NewSpeed)
    {
        CurrentSpeed = NewSpeed;
        OnSpeedChanged.Broadcast(CurrentSpeed, MaxSpeed);
    }

    UFUNCTION()
    void ResetToDefaultSpeed()
    {
        // Don't hardcode to InitialSpeed here, we want it to gracefully slow down 
        // back to the normal MaxSpeed or whatever it was before the boost.
        // It's better to let UpdateSpeed handle the deceleration.
    }

    UFUNCTION()
    void SetSpeedInterpolated(float TargetSpeed, float DeltaSeconds, float InterpSpeed)
    {
        CurrentSpeed = Math::FInterpTo(CurrentSpeed, TargetSpeed, DeltaSeconds, InterpSpeed);
        OnSpeedChanged.Broadcast(CurrentSpeed, MaxSpeed);
    }

    UFUNCTION(BlueprintPure)
    float GetSpeedRatio() const
    {
        return (MaxSpeed > 0.0) ? Math::Clamp(CurrentSpeed / MaxSpeed, 0.0, 1.0) : 0.0;
    }

    // ---- Internal -------------------------------------------

    private void UpdateSpeed(float DeltaSeconds)
    {
        if (bIsBoosting)
            return;

        float prevSpeed = CurrentSpeed;
        
        // If we are above MaxSpeed (e.g. just finished boosting), smoothly decelerate
        if (CurrentSpeed > MaxSpeed)
        {
            CurrentSpeed = Math::FInterpTo(CurrentSpeed, MaxSpeed, DeltaSeconds, 2.0);
        }
        else
        {
            // Normal acceleration up to MaxSpeed
            CurrentSpeed = Math::Min(CurrentSpeed + AccelerationRate * DeltaSeconds, MaxSpeed);
        }

        if (Math::Abs(CurrentSpeed - prevSpeed) > 0.1)
            OnSpeedChanged.Broadcast(CurrentSpeed, MaxSpeed);
    }

    private void ApplyForwardThrust()
    {
        FVector vel = PrimitiveRoot.GetPhysicsLinearVelocity();
        float currentForwardSpeed = vel.X;
        float speedError = CurrentSpeed - currentForwardSpeed;

        if (speedError > 0.1)
        {
            float thrustX = speedError * ForwardThrust;
            PrimitiveRoot.AddForce(FVector(thrustX, 0.0, 0.0), NAME_None, true);
        }
    }

    private void DebugDrawForwardState()
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr) return;

        FVector pos = OwnerActor.ActorLocation;
        FVector vel = PrimitiveRoot.GetPhysicsLinearVelocity();
        float ratio = GetSpeedRatio();

        // Speed bar color: green→yellow→red based on ratio
        FLinearColor barColor = FLinearColor(ratio, 1.0 - ratio * 0.5, 0.0, 1.0);

        // Forward thrust arrow
        System::DrawDebugArrow(pos, pos + FVector(CurrentSpeed * 0.15, 0.0, 0.0), 25.0,
            barColor, 0.0, 2.5);

        FString fwdText = f"Fwd: {vel.X:.0f}/{CurrentSpeed:.0f} ({ratio * 100.0:.0f}%) Boost:{bIsBoosting}";
        System::DrawDebugString(pos + FVector(0.0, 0.0, 300.0), fwdText,
            nullptr, barColor, 0.0);
    }
}
