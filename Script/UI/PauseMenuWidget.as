// ============================================================
//  PauseMenuWidget.as
//  Designer-friendly pause menu. Create a Blueprint child
//  (WBP_PauseMenu) and design in UMG. Place widgets with
//  the exact names below for auto-binding.
//
//  LAYOUT:
//  ┌──────────────────────────────┐
//  │          PAUSED              │
//  │  Score: 132,142  Dist: 1.2M  │
//  │  Artifacts: 320              │
//  │                              │
//  │  ┌──── RESUME ────┐         │
//  │  ┌──── OPTIONS ───┐         │
//  │  ┌──── QUIT ──────┐         │
//  └──────────────────────────────┘
// ============================================================

class UPauseMenuWidget : UUserWidget
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- BindWidget references --------------------------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI")
    UTextBlock TXT_Title;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_Score;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_Distance;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Stats")
    UTextBlock TXT_Artifacts;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Resume;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Options;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Buttons")
    UButton BTN_Quit;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        if (BTN_Resume != nullptr)
            BTN_Resume.OnClicked.AddUFunction(this, n"HandleResumeClicked");

        if (BTN_Options != nullptr)
            BTN_Options.OnClicked.AddUFunction(this, n"HandleOptionsClicked");

        if (BTN_Quit != nullptr)
            BTN_Quit.OnClicked.AddUFunction(this, n"HandleQuitClicked");
    }

    // Called when pause menu becomes visible — refresh stats
    UFUNCTION()
    void RefreshDisplay()
    {
        UScoreSubsystem ScoreSub = UScoreSubsystem::Get();
        if (ScoreSub != nullptr)
        {
            if (TXT_Score != nullptr)
                TXT_Score.SetText(FText::FromString(f"{ScoreSub.CurrentScore:.0f}"));
            if (TXT_Artifacts != nullptr)
                TXT_Artifacts.SetText(FText::FromString(f"{ScoreSub.ArtifactsCollected}"));
        }

        // Get distance from ship
        TArray<AShipActor> ships;
        GetAllActorsOfClass(ships);
        if (ships.Num() > 0 && TXT_Distance != nullptr)
        {
            float dist = ships[0].DistanceTraveled;
            if (dist >= 1000000.0)
                TXT_Distance.SetText(FText::FromString(f"{dist / 1000000.0:.2f}M km"));
            else if (dist >= 1000.0)
                TXT_Distance.SetText(FText::FromString(f"{dist / 1000.0:.1f}K km"));
            else
                TXT_Distance.SetText(FText::FromString(f"{dist:.0f} km"));
        }
    }

    // ---- Button handlers ------------------------------------

    UFUNCTION()
    private void HandleResumeClicked()
    {
        if (bShowDebug)
            Print("[PauseMenu] Resume");

        AShipGameMode GameMode = Cast<AShipGameMode>(Gameplay::GetGameMode());
        if (GameMode != nullptr)
            GameMode.OnPauseMenuResumeClicked();
    }

    UFUNCTION()
    private void HandleOptionsClicked()
    {
        if (bShowDebug)
            Print("[PauseMenu] Options");
    }

    UFUNCTION()
    private void HandleQuitClicked()
    {
        if (bShowDebug)
            Print("[PauseMenu] Quit");

        AShipGameMode GameMode = Cast<AShipGameMode>(Gameplay::GetGameMode());
        if (GameMode != nullptr)
            GameMode.OnPauseMenuQuitClicked();
    }
}
