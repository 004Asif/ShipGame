// ============================================================
//  ShipPlayerController.as
//  Custom player controller using the Enhanced Input System.
//  Uses UEnhancedInputComponent + UInputMappingContext +
//  UInputAction assets for fully data-driven input.
//
//  Setup (in Content Browser):
//   1. Create Input Actions (right-click → Input → Input Action):
//      IA_MoveLeft   (Value Type: Digital/Bool)
//      IA_MoveRight  (Value Type: Digital/Bool)
//      IA_Boost      (Value Type: Digital/Bool)
//      IA_Pause      (Value Type: Digital/Bool)
//   2. Create Input Mapping Context (right-click → Input → Input Mapping Context):
//      IMC_Ship — add mappings:
//        IA_MoveRight → D, Right, Gamepad_LeftStick_Right
//        IA_MoveLeft  → A, Left, Gamepad_LeftStick_Left
//        IA_Boost     → SpaceBar, Gamepad_FaceButton_Bottom
//        IA_Pause     → Escape, Gamepad_Special_Right
//   3. Create BP_ShipPlayerController (parent: ShipPlayerController).
//      Assign the 4 IA_ assets and IMC_Ship in Class Defaults.
//   4. Set BP_ShipPlayerController as PlayerControllerClass
//      on BP_ShipGameMode.
// ============================================================

class AShipPlayerController : APlayerController
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Enhanced Input assets (assign in BP defaults) -------

    UPROPERTY(Category = "Input")
    UInputMappingContext ShipMappingContext;

    UPROPERTY(Category = "Input")
    UInputAction MoveLeftAction;

    UPROPERTY(Category = "Input")
    UInputAction MoveRightAction;

    UPROPERTY(Category = "Input")
    UInputAction BoostAction;

    UPROPERTY(Category = "Input")
    UInputAction PauseAction;

    // ---- Internal -------------------------------------------

    UEnhancedInputComponent EnhancedInput;
    private bool bRightHeld = false;
    private bool bLeftHeld = false;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Create and push an Enhanced Input component
        EnhancedInput = UEnhancedInputComponent::Create(this);
        PushInputComponent(EnhancedInput);

        if (bShowDebug)
            Print("[ShipPC] EnhancedInputComponent created and pushed.");

        // Register the mapping context
        UEnhancedInputLocalPlayerSubsystem InputSub = UEnhancedInputLocalPlayerSubsystem::Get(this);
        if (InputSub != nullptr && ShipMappingContext != nullptr)
        {
            InputSub.AddMappingContext(ShipMappingContext, 0, FModifyContextOptions());
            if (bShowDebug)
                Print("[ShipPC] MappingContext registered.");
        }
        else if (bShowDebug)
        {
            if (InputSub == nullptr)
                Print("[ShipPC] WARNING: EnhancedInputLocalPlayerSubsystem is null!", Duration = 10.0);
            if (ShipMappingContext == nullptr)
                Print("[ShipPC] WARNING: ShipMappingContext is null! Assign in BP defaults.", Duration = 10.0);
        }

        // Validate action assets
        if (bShowDebug)
        {
            if (MoveRightAction == nullptr) Print("[ShipPC] WARNING: MoveRightAction is null!", Duration = 10.0);
            if (MoveLeftAction == nullptr) Print("[ShipPC] WARNING: MoveLeftAction is null!", Duration = 10.0);
            if (BoostAction == nullptr) Print("[ShipPC] WARNING: BoostAction is null!", Duration = 10.0);
            if (PauseAction == nullptr) Print("[ShipPC] WARNING: PauseAction is null!", Duration = 10.0);
        }

        // Bind movement actions
        if (MoveRightAction != nullptr)
        {
            EnhancedInput.BindAction(MoveRightAction, ETriggerEvent::Triggered,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnMoveRightTriggered"));
            EnhancedInput.BindAction(MoveRightAction, ETriggerEvent::Completed,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnMoveRightCompleted"));
        }

        if (MoveLeftAction != nullptr)
        {
            EnhancedInput.BindAction(MoveLeftAction, ETriggerEvent::Triggered,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnMoveLeftTriggered"));
            EnhancedInput.BindAction(MoveLeftAction, ETriggerEvent::Completed,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnMoveLeftCompleted"));
        }

        // Bind boost
        if (BoostAction != nullptr)
        {
            EnhancedInput.BindAction(BoostAction, ETriggerEvent::Triggered,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnBoostTriggered"));
            EnhancedInput.BindAction(BoostAction, ETriggerEvent::Completed,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnBoostCompleted"));
        }

        // Bind pause (Started = single press, not held)
        if (PauseAction != nullptr)
        {
            EnhancedInput.BindAction(PauseAction, ETriggerEvent::Started,
                FEnhancedInputActionHandlerDynamicSignature(this, n"OnPauseStarted"));
        }
    }

    // ---- Input callbacks ------------------------------------

    UFUNCTION()
    void OnMoveRightTriggered(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        bRightHeld = true;
        PushHorizontalInput();
        if (bShowDebug) Print("[ShipPC] MoveRight TRIGGERED");
    }

    UFUNCTION()
    void OnMoveRightCompleted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        bRightHeld = false;
        PushHorizontalInput();
        if (bShowDebug) Print("[ShipPC] MoveRight COMPLETED");
    }

    UFUNCTION()
    void OnMoveLeftTriggered(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        bLeftHeld = true;
        PushHorizontalInput();
        if (bShowDebug) Print("[ShipPC] MoveLeft TRIGGERED");
    }

    UFUNCTION()
    void OnMoveLeftCompleted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        bLeftHeld = false;
        PushHorizontalInput();
        if (bShowDebug) Print("[ShipPC] MoveLeft COMPLETED");
    }

    UFUNCTION()
    void OnBoostTriggered(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        UShipInputComponent Input = FindShipInput();
        if (Input != nullptr)
            Input.bBoostPressed = true;
        if (bShowDebug) Print("[ShipPC] Boost TRIGGERED");
    }

    UFUNCTION()
    void OnBoostCompleted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        UShipInputComponent Input = FindShipInput();
        if (Input != nullptr)
            Input.bBoostPressed = false;
        if (bShowDebug) Print("[ShipPC] Boost COMPLETED");
    }

    UFUNCTION()
    void OnPauseStarted(FInputActionValue ActionValue, float32 ElapsedTime, float32 TriggeredTime, UInputAction SourceAction)
    {
        if (bShowDebug) Print("[ShipPC] Pause STARTED");
        UGameFlowSubsystem GameFlow = UGameFlowSubsystem::Get();
        if (GameFlow != nullptr)
            GameFlow.TogglePause();
    }

    // ---- Helpers --------------------------------------------

    private void PushHorizontalInput()
    {
        float horizontal = 0.0;
        if (bRightHeld) horizontal += 1.0;
        if (bLeftHeld) horizontal -= 1.0;

        UShipInputComponent Input = FindShipInput();
        if (Input != nullptr)
            Input.HorizontalInput = horizontal;
    }

    private UShipInputComponent FindShipInput()
    {
        APawn Pawn = GetControlledPawn();
        if (Pawn == nullptr)
            return nullptr;
        return UShipInputComponent::Get(Pawn);
    }
}
