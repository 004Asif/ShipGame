// ============================================================
//  MainMenuWidget.as
//  Designer-friendly main menu. Create a Blueprint child
//  (WBP_MainMenu) and design freely in UMG. Place widgets
//  with the EXACT names listed below so BindWidget connects
//  them automatically. Any widget you don't need can be
//  left out — the code null-checks everything.
//
//  REFERENCE LAYOUT (mobile portrait):
//  ┌──────────────────────────────────┐
//  │ GameTitle    PlayerName  ⚙       │
//  │ ShipName / ShipClass / Tier      │
//  │        < [ShipPreview] >         │
//  │ Speed ██  Shield ██  Thrust ██   │
//  │ BestRun   TotalRuns  Artifacts   │
//  │ ┌─HANGAR──────┐  ┌─STORE─┐      │
//  │ └─────────────┘  └───────┘      │
//  │ Season   SeasonName    ● LIVE    │
//  │ ┌──────── ▶ RUN ────────┐       │
//  │ └───────────────────────┘       │
//  │ ┌──────── GIVE UP ──────┐       │
//  │ └───────────────────────┘       │
//  └──────────────────────────────────┘
// ============================================================

class UMainMenuWidget : UUserWidget
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- BindWidget references --------------------------------
    // Place widgets with these exact names in UMG designer.
    // All are optional — code null-checks everything.

    // Header
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Header")
    UTextBlock TXT_GameTitle;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Header")
    UTextBlock TXT_PlayerName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Header")
    UButton BTN_Settings;

    // Ship display
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UTextBlock TXT_ShipName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UTextBlock TXT_ShipClass;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UImage IMG_ShipPreview;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UButton BTN_PrevShip;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UButton BTN_NextShip;

    // Ship stat bars
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UProgressBar PB_Speed;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_SpeedValue;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UProgressBar PB_Shield;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_ShieldValue;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UProgressBar PB_Thrust;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_ThrustValue;

    // Player stats row
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|PlayerStats")
    UTextBlock TXT_BestRun;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|PlayerStats")
    UTextBlock TXT_TotalRuns;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|PlayerStats")
    UTextBlock TXT_Artifacts;

    // Buttons
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Hangar;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Store;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Run;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_GiveUp;

    // Optional panels for showing/hiding sections
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Panels")
    UWidget Panel_GiveUp;

    // ---- Internal -------------------------------------------

    int CurrentShipIndex = 0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        // Bind button clicks
        if (BTN_Run != nullptr)
            BTN_Run.OnClicked.AddUFunction(this, n"HandleRunClicked");

        if (BTN_GiveUp != nullptr)
            BTN_GiveUp.OnClicked.AddUFunction(this, n"HandleGiveUpClicked");

        if (BTN_Hangar != nullptr)
            BTN_Hangar.OnClicked.AddUFunction(this, n"HandleHangarClicked");

        if (BTN_Store != nullptr)
            BTN_Store.OnClicked.AddUFunction(this, n"HandleStoreClicked");

        if (BTN_Settings != nullptr)
            BTN_Settings.OnClicked.AddUFunction(this, n"HandleSettingsClicked");

        if (BTN_PrevShip != nullptr)
            BTN_PrevShip.OnClicked.AddUFunction(this, n"HandlePrevShipClicked");

        if (BTN_NextShip != nullptr)
            BTN_NextShip.OnClicked.AddUFunction(this, n"HandleNextShipClicked");

        // Hide give up by default (only show during active run)
        if (Panel_GiveUp != nullptr)
            Panel_GiveUp.SetVisibility(ESlateVisibility::Collapsed);

        // Refresh display
        RefreshShipDisplay();
        RefreshPlayerStats();
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void RefreshShipDisplay()
    {
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Registry == nullptr)
            return;

        FShipDefinition ShipDef = Registry.GetShipByIndex(CurrentShipIndex);

        if (TXT_ShipName != nullptr)
            TXT_ShipName.SetText(FText::FromString(ShipDef.DisplayName));

        if (TXT_ShipClass != nullptr)
            TXT_ShipClass.SetText(FText::FromString(f"{ShipDef.ShipClassName} · Tier {ShipDef.Tier}"));

        if (IMG_ShipPreview != nullptr && ShipDef.PreviewTexture != nullptr)
            IMG_ShipPreview.SetBrushFromTexture(ShipDef.PreviewTexture, true);

        // Stat bars (normalize to 0-1 based on max 100)
        if (PB_Speed != nullptr)
            PB_Speed.SetPercent(ShipDef.BaseStats.SpeedRating / 100.0);
        if (TXT_SpeedValue != nullptr)
            TXT_SpeedValue.SetText(FText::FromString(f"{ShipDef.BaseStats.SpeedRating:.0f}"));

        if (PB_Shield != nullptr)
            PB_Shield.SetPercent(ShipDef.BaseStats.ShieldRating / 100.0);
        if (TXT_ShieldValue != nullptr)
            TXT_ShieldValue.SetText(FText::FromString(f"{ShipDef.BaseStats.ShieldRating:.0f}"));

        if (PB_Thrust != nullptr)
            PB_Thrust.SetPercent(ShipDef.BaseStats.ThrustRating / 100.0);
        if (TXT_ThrustValue != nullptr)
            TXT_ThrustValue.SetText(FText::FromString(f"{ShipDef.BaseStats.ThrustRating:.0f}"));
    }

    UFUNCTION()
    void RefreshPlayerStats()
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        if (Progress == nullptr)
            return;

        if (TXT_BestRun != nullptr)
            TXT_BestRun.SetText(FText::FromString(Progress.GetBestRunText()));

        if (TXT_TotalRuns != nullptr)
            TXT_TotalRuns.SetText(FText::FromString(f"{Progress.TotalRuns}"));

        if (TXT_Artifacts != nullptr)
            TXT_Artifacts.SetText(FText::FromString(f"{Progress.Artifacts}"));
    }

    // Show the give up button (called by GameMode during active run)
    UFUNCTION()
    void ShowGiveUpOption()
    {
        if (Panel_GiveUp != nullptr)
            Panel_GiveUp.SetVisibility(ESlateVisibility::Visible);
    }

    UFUNCTION()
    void HideGiveUpOption()
    {
        if (Panel_GiveUp != nullptr)
            Panel_GiveUp.SetVisibility(ESlateVisibility::Collapsed);
    }

    // ---- Button handlers ------------------------------------

    UFUNCTION()
    private void HandleRunClicked()
    {
        if (bShowDebug)
            Print("[MainMenu] RUN clicked");

        AShipGameMode GameMode = Cast<AShipGameMode>(Gameplay::GetGameMode());
        if (GameMode != nullptr)
            GameMode.OnMainMenuPlayClicked();
    }

    UFUNCTION()
    private void HandleGiveUpClicked()
    {
        if (bShowDebug)
            Print("[MainMenu] GIVE UP clicked");

        AShipGameMode GameMode = Cast<AShipGameMode>(Gameplay::GetGameMode());
        if (GameMode != nullptr)
            GameMode.ReturnToMenu();
    }

    UFUNCTION()
    private void HandleHangarClicked()
    {
        if (bShowDebug)
            Print("[MainMenu] HANGAR clicked");

        AShipGameMode GameMode = Cast<AShipGameMode>(Gameplay::GetGameMode());
        if (GameMode != nullptr)
            GameMode.ShowHangar();
    }

    UFUNCTION()
    private void HandleStoreClicked()
    {
        if (bShowDebug)
            Print("[MainMenu] STORE clicked");
        // Opens store screen — extend in Blueprint
    }

    UFUNCTION()
    private void HandleSettingsClicked()
    {
        if (bShowDebug)
            Print("[MainMenu] SETTINGS clicked");
        // Opens settings — extend in Blueprint
    }

    UFUNCTION()
    private void HandlePrevShipClicked()
    {
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Registry == nullptr)
            return;

        int count = Registry.GetShipCount();
        if (count == 0) return;

        CurrentShipIndex = (CurrentShipIndex - 1 + count) % count;
        RefreshShipDisplay();

        if (bShowDebug)
            Print(f"[MainMenu] PrevShip -> index {CurrentShipIndex}");
    }

    UFUNCTION()
    private void HandleNextShipClicked()
    {
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Registry == nullptr)
            return;

        int count = Registry.GetShipCount();
        if (count == 0) return;

        CurrentShipIndex = (CurrentShipIndex + 1) % count;
        RefreshShipDisplay();

        if (bShowDebug)
            Print(f"[MainMenu] NextShip -> index {CurrentShipIndex}");
    }
}
