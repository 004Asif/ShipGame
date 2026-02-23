// ============================================================
//  GameFlowSubsystem.as
//  World subsystem managing the game phase state machine:
//    Boot → Menu → Intro → Playing → Paused → GameOver
//  Mirrors Unity's GameFlowController as a subsystem.
//  Other systems listen to OnPhaseChanged to react.
// ============================================================

event void FOnPhaseChanged(EGamePhase NewPhase, EGamePhase OldPhase);

class UGameFlowSubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnPhaseChanged OnPhaseChanged;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "GameFlow")
    EGamePhase CurrentPhase = EGamePhase::Boot;

    UPROPERTY(BlueprintReadOnly, Category = "GameFlow")
    EGamePhase PreviousPhase = EGamePhase::Boot;

    // References set by whoever spawns the ship/terrain
    UPROPERTY(BlueprintReadOnly, Category = "GameFlow")
    AShipActor CurrentShip;

    UPROPERTY(BlueprintReadOnly, Category = "GameFlow")
    ATerrainManager TerrainManager;

    // ---- Configuration (seconds) ----------------------------

    UPROPERTY(EditAnywhere, Category = "GameFlow|Timing")
    float IntroDuration = 2.0;

    UPROPERTY(EditAnywhere, Category = "GameFlow|Timing")
    float GameOverDelay = 1.5;

    // ---- Internal -------------------------------------------

    private FTimerHandle IntroTimerHandle;
    private FTimerHandle GameOverTimerHandle;

    // ---- Phase transitions ----------------------------------

    UFUNCTION()
    void GoToMenu()
    {
        SetPhase(EGamePhase::Menu);

        // Clean up any previous run
        if (CurrentShip != nullptr)
        {
            CurrentShip.DestroyActor();
            CurrentShip = nullptr;
        }

        if (TerrainManager != nullptr)
            TerrainManager.ResetTerrain();
    }

    // Call to start a new game run from the menu.
    UFUNCTION()
    void StartGame(AShipActor InShip, ATerrainManager InTerrainManager)
    {
        if (bShowDebug)
            Print(f"[GameFlow] StartGame. Ship={InShip != nullptr} Terrain={InTerrainManager != nullptr}");

        CurrentShip = InShip;
        TerrainManager = InTerrainManager;

        if (CurrentShip != nullptr)
        {
            CurrentShip.SetKinematicMode();

            // Listen for death
            CurrentShip.OnShipDied.AddUFunction(this, n"OnShipDied");
        }

        if (TerrainManager != nullptr)
            TerrainManager.SetTrackedActor(CurrentShip);

        SetPhase(EGamePhase::Intro);

        // After intro duration, transition to Playing
        System::SetTimer(this, n"OnIntroFinished", IntroDuration, false);
    }

    UFUNCTION()
    void TogglePause()
    {
        if (bShowDebug)
            Print(f"[GameFlow] TogglePause from {CurrentPhase}");

        if (CurrentPhase == EGamePhase::Playing)
        {
            SetPhase(EGamePhase::Paused);
        }
        else if (CurrentPhase == EGamePhase::Paused)
        {
            SetPhase(EGamePhase::Playing);
        }
    }

    UFUNCTION()
    void ReturnToMenu()
    {
        GoToMenu();
    }

    // ---- Timer callbacks ------------------------------------

    UFUNCTION()
    private void OnIntroFinished()
    {
        if (CurrentPhase != EGamePhase::Intro)
            return;

        // Enable ship physics for gameplay
        if (CurrentShip != nullptr)
            CurrentShip.EnableGameplayPhysics();

        SetPhase(EGamePhase::Playing);
    }

    UFUNCTION()
    private void OnShipDied()
    {
        if (CurrentPhase == EGamePhase::GameOver)
            return;

        if (bShowDebug)
            Print("[GameFlow] Ship died! -> GameOver");

        SetPhase(EGamePhase::GameOver);
    }

    UFUNCTION()
    private void OnGameOverDelayFinished()
    {
        // Could auto-return to menu or show UI
        // For now, just stays in GameOver until GoToMenu is called
    }

    // ---- Internal -------------------------------------------

    private void SetPhase(EGamePhase NewPhase)
    {
        if (NewPhase == CurrentPhase)
            return;

        PreviousPhase = CurrentPhase;
        CurrentPhase = NewPhase;
        OnPhaseChanged.Broadcast(NewPhase, PreviousPhase);

        Print(f"GameFlow: {PreviousPhase} → {NewPhase}");
    }
}
