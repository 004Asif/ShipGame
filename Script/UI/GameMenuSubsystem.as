// ============================================================
//  GameMenuSubsystem.as
//  World subsystem managing menu state and transitions.
//  Handles showing/hiding main menu and pause menu widgets.
// ============================================================

event void FOnMenuStateChanged(EGameMenuState NewState);

enum EGameMenuState
{
    None,
    MainMenu,
    Playing,
    Paused,
    Hangar,
    Store,
    Settings,
}

class UGameMenuSubsystem : UScriptWorldSubsystem
{
    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnMenuStateChanged OnMenuStateChanged;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Menu")
    EGameMenuState CurrentState = EGameMenuState::None;

    // ---- Widget references (set from Blueprint) -------------

    UPROPERTY()
    UUserWidget MainMenuWidget;

    UPROPERTY()
    UUserWidget PauseMenuWidget;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Menu")
    bool bShowDebug = false;

    // ---- Initialization -------------------------------------

    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        // Start at main menu
        ShowMainMenu();
    }

    // ---- Menu State -----------------------------------------

    UFUNCTION()
    void ShowMainMenu()
    {
        if (bShowDebug)
            Print("[Menu] ShowMainMenu");

        // Hide pause menu if visible
        if (PauseMenuWidget != nullptr)
            PauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        // Show main menu
        if (MainMenuWidget != nullptr)
            MainMenuWidget.SetVisibility(ESlateVisibility::Visible);

        CurrentState = EGameMenuState::MainMenu;
        OnMenuStateChanged.Broadcast(CurrentState);
    }

    UFUNCTION()
    void StartGame()
    {
        if (bShowDebug)
            Print("[Menu] StartGame");

        // Hide main menu
        if (MainMenuWidget != nullptr)
            MainMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        CurrentState = EGameMenuState::Playing;
        OnMenuStateChanged.Broadcast(CurrentState);
    }

    UFUNCTION()
    void ShowPauseMenu()
    {
        if (bShowDebug)
            Print("[Menu] ShowPauseMenu");

        // Show pause menu
        if (PauseMenuWidget != nullptr)
            PauseMenuWidget.SetVisibility(ESlateVisibility::Visible);

        CurrentState = EGameMenuState::Paused;
        OnMenuStateChanged.Broadcast(CurrentState);
    }

    UFUNCTION()
    void HidePauseMenu()
    {
        if (bShowDebug)
            Print("[Menu] HidePauseMenu");

        // Hide pause menu
        if (PauseMenuWidget != nullptr)
            PauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        CurrentState = EGameMenuState::Playing;
        OnMenuStateChanged.Broadcast(CurrentState);
    }

    UFUNCTION()
    void TogglePause()
    {
        if (CurrentState == EGameMenuState::Playing)
            ShowPauseMenu();
        else if (CurrentState == EGameMenuState::Paused)
            HidePauseMenu();
    }

    UFUNCTION()
    void QuitToMain()
    {
        if (bShowDebug)
            Print("[Menu] QuitToMain");

        // Hide pause menu
        if (PauseMenuWidget != nullptr)
            PauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        ShowMainMenu();
    }

    // ---- Helpers --------------------------------------------

    UFUNCTION(BlueprintPure)
    bool IsInMenu() const
    {
        return CurrentState == EGameMenuState::MainMenu;
    }

    UFUNCTION(BlueprintPure)
    bool IsPaused() const
    {
        return CurrentState == EGameMenuState::Paused;
    }

    UFUNCTION(BlueprintPure)
    bool IsPlaying() const
    {
        return CurrentState == EGameMenuState::Playing;
    }
}
