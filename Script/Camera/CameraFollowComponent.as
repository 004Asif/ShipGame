// ============================================================
//  CameraFollowComponent.as
//  Lightweight camera helper that lives on the ShipActor.
//  The heavy lifting is done by USpringArmComponent + UCameraComponent
//  which are also on the pawn.
//  This component handles:
//    - Intro swoop (animates spring arm from cinematic to chase)
//    - Screen shake (temporary offset on the camera component)
//    - Dynamic arm length based on speed
// ============================================================

enum ECameraMode
{
    Idle,
    IntroSwoop,
    Chase,
}

class UCameraFollowComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Chase spring arm targets (from defaults) -----------
    private float DefaultArmLength;
    private FRotator DefaultArmRotation;
    private FVector DefaultSocketOffset;

    // ---- Intro swoop ----------------------------------------

    UPROPERTY(EditAnywhere, Category = "Camera|Intro")
    float IntroArmLength = 2500.0;

    UPROPERTY(EditAnywhere, Category = "Camera|Intro")
    FRotator IntroArmRotation = FRotator(-35.0, 15.0, 0.0);

    // ---- Speed-adaptive arm length --------------------------

    UPROPERTY(EditAnywhere, Category = "Camera|Dynamic")
    bool bSpeedAdaptiveLength = true;

    // Multiplier for arm length at max speed
    UPROPERTY(EditAnywhere, Category = "Camera|Dynamic")
    float MaxArmLengthMultiplier = 1.5;

    UPROPERTY(EditAnywhere, Category = "Camera|Dynamic")
    float SpeedForMaxArm = 2500.0;

    // ---- Screen shake ---------------------------------------

    UPROPERTY(EditAnywhere, Category = "Camera|Shake")
    float ShakeDecay = 5.0;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Camera")
    ECameraMode CurrentMode = ECameraMode::Idle;

    // ---- Internal -------------------------------------------

    private USpringArmComponent SpringArmRef;
    private UCameraComponent CameraRef;

    // Intro
    private float IntroDuration = 2.0;
    private float IntroElapsed = 0.0;

    // Screen shake
    private float ShakeIntensity = 0.0;
    private float ShakeTimer = 0.0;
    private float ShakeDuration = 0.0;
    private FVector BaseSocketOffset;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SpringArmRef = USpringArmComponent::Get(GetOwner());
        CameraRef = UCameraComponent::Get(GetOwner());
        
        if (SpringArmRef != nullptr)
        {
            DefaultArmLength = SpringArmRef.TargetArmLength;
            DefaultArmRotation = SpringArmRef.GetRelativeRotation();
            DefaultSocketOffset = SpringArmRef.SocketOffset;
            BaseSocketOffset = SpringArmRef.SocketOffset;
        }

        if (bShowDebug)
        {
            Print(f"[Camera] BeginPlay. SpringArm={SpringArmRef != nullptr} Camera={CameraRef != nullptr}");
            if (SpringArmRef == nullptr)
                Print("[Camera] WARNING: No SpringArmComponent on owner!", Duration = 10.0);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        switch (CurrentMode)
        {
            case ECameraMode::IntroSwoop:
                UpdateIntroSwoop(DeltaSeconds);
                break;
            case ECameraMode::Chase:
                UpdateChaseMode(DeltaSeconds);
                break;
            default:
                break;
        }

        UpdateScreenShake(DeltaSeconds);

        if (bShowDebug)
            DebugDrawCameraState();
    }

    // ---- Public API -----------------------------------------

    // Start the cinematic intro swoop — call when the game begins.
    UFUNCTION()
    void StartIntroSwoop(float Duration)
    {
        if (SpringArmRef == nullptr)
            return;

        // Start zoomed out and angled
        SpringArmRef.TargetArmLength = IntroArmLength;
        SpringArmRef.SetRelativeRotation(IntroArmRotation);

        IntroDuration = Math::Max(Duration, 0.1);
        IntroElapsed = 0.0;
        CurrentMode = ECameraMode::IntroSwoop;

        if (bShowDebug)
            Print(f"[Camera] IntroSwoop started. Duration={Duration:.1f} ArmLen={IntroArmLength:.0f}");
    }

    // Immediately enter chase mode (skip intro).
    UFUNCTION()
    void EnterChaseMode()
    {
        if (SpringArmRef != nullptr)
        {
            SpringArmRef.TargetArmLength = DefaultArmLength;
            SpringArmRef.SetRelativeRotation(DefaultArmRotation);
            SpringArmRef.SocketOffset = DefaultSocketOffset;
        }
        CurrentMode = ECameraMode::Chase;

        if (bShowDebug)
            Print(f"[Camera] Chase mode entered. ArmLen={DefaultArmLength:.0f}");
    }

    // Trigger a screen shake.
    UFUNCTION()
    void Shake(float Intensity, float Duration)
    {
        ShakeIntensity = Intensity;
        ShakeDuration = Duration;
        ShakeTimer = Duration;

        if (bShowDebug)
            Print(f"[Camera] Shake! Intensity={Intensity:.1f} Duration={Duration:.2f}");
    }

    // ---- Mode updates ---------------------------------------

    private void UpdateIntroSwoop(float DeltaSeconds)
    {
        if (SpringArmRef == nullptr)
            return;

        IntroElapsed += DeltaSeconds;
        float t = Math::Clamp(IntroElapsed / IntroDuration, 0.0, 1.0);
        float smoothT = t * t * (3.0 - 2.0 * t);

        // Interpolate arm length from intro → default chase
        float targetLength = Math::Lerp(IntroArmLength, DefaultArmLength, smoothT);
        SpringArmRef.TargetArmLength = targetLength;

        // Interpolate rotation
        FRotator targetRot = Math::RInterpTo(IntroArmRotation, DefaultArmRotation, smoothT, 1.0);
        SpringArmRef.SetRelativeRotation(targetRot);

        if (t >= 1.0)
        {
            CurrentMode = ECameraMode::Chase;
            if (bShowDebug)
                Print("[Camera] IntroSwoop finished -> Chase");
        }
    }

    private void UpdateChaseMode(float DeltaSeconds)
    {
        if (SpringArmRef == nullptr)
            return;

        // Speed-adaptive arm length
        if (bSpeedAdaptiveLength)
        {
            float currentSpeed = SpringArmRef.GetOwner().GetVelocity().Size();
            float speedRatio = Math::Clamp(currentSpeed / SpeedForMaxArm, 0.0, 1.0);

            float targetLen = Math::Lerp(DefaultArmLength, DefaultArmLength * MaxArmLengthMultiplier, speedRatio);
            SpringArmRef.TargetArmLength = Math::FInterpTo(SpringArmRef.TargetArmLength, targetLen, DeltaSeconds, 2.0);
        }
    }

    private void UpdateScreenShake(float DeltaSeconds)
    {
        if (SpringArmRef == nullptr)
            return;

        if (ShakeTimer > 0.0)
        {
            ShakeTimer -= DeltaSeconds;
            float normalizedTime = Math::Clamp(ShakeTimer / Math::Max(ShakeDuration, 0.01), 0.0, 1.0);
            float currentIntensity = ShakeIntensity * normalizedTime;
            FVector shakeOffset = FVector(
                0.0,
                Math::RandRange(-currentIntensity, currentIntensity),
                Math::RandRange(-currentIntensity, currentIntensity) * 0.5
            );
            SpringArmRef.SocketOffset = DefaultSocketOffset + shakeOffset;
        }
        else if (ShakeIntensity > 0.0)
        {
            // Reset after shake finishes
            SpringArmRef.SocketOffset = DefaultSocketOffset;
            ShakeIntensity = 0.0;
        }
    }

    private void DebugDrawCameraState()
    {
        if (SpringArmRef == nullptr || CameraRef == nullptr)
            return;

        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr) return;

        FVector shipPos = OwnerActor.ActorLocation;
        FVector camPos = CameraRef.WorldLocation;

        // Line from ship to camera (magenta)
        System::DrawDebugLine(shipPos, camPos,
            FLinearColor(1.0, 0.0, 1.0, 1.0), 0.0, 1.5);

        // Camera position point
        System::DrawDebugPoint(camPos, 12.0,
            FLinearColor(1.0, 0.0, 1.0, 1.0), 0.0);

        // State text at camera
        FString modeStr = "Idle";
        if (CurrentMode == ECameraMode::IntroSwoop) modeStr = "IntroSwoop";
        else if (CurrentMode == ECameraMode::Chase) modeStr = "Chase";

        FString camText = f"Cam:{modeStr} Arm:{SpringArmRef.TargetArmLength:.0f}";
        System::DrawDebugString(camPos + FVector(0.0, 0.0, 50.0), camText,
            nullptr, FLinearColor(1.0, 0.0, 1.0, 1.0), 0.0);
    }
}
