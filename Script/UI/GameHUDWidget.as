// ============================================================
//  GameHUDWidget.as
//  Designer-friendly in-game HUD. Create a Blueprint child
//  (WBP_GameHUD) and design in UMG. Place widgets with
//  the exact names below for auto-binding.
//
//  REFERENCE LAYOUT (mobile, top bar + bottom controls):
//  ┌──────────────────────────────────┐
//  │ SCORE     DISTANCE    ARTIFACTS  │
//  │ 132,142   1.24M km    ⬡ 320     │
//  │           ▶ 4,360 km/s           │
//  │ SHIELD ██76% MAGNET ██58% BOOST ██82% │
//  │                                  │
//  │        (gameplay area)           │
//  │                                  │
//  │   ◀ TURN L   ⏸   TURN R ▶     │
//  └──────────────────────────────────┘
// ============================================================

class UGameHUDWidget : UUserWidget
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- BindWidget references (top stats bar) ----------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Score")
    UTextBlock TXT_Score;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Score")
    UTextBlock TXT_Distance;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Score")
    UTextBlock TXT_Speed;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Score")
    UTextBlock TXT_Artifacts;

    // ---- Power-up / ability bars ------------------------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UProgressBar PB_Shield;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UTextBlock TXT_ShieldPercent;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UWidget Panel_Shield;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UProgressBar PB_Magnet;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UTextBlock TXT_MagnetPercent;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UWidget Panel_Magnet;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UProgressBar PB_Boost;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Bars")
    UTextBlock TXT_BoostPercent;

    // ---- Multiplier overlay -----------------------------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Multiplier")
    UTextBlock TXT_Multiplier;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Multiplier")
    UWidget Panel_Multiplier;

    // ---- Bottom touch controls (optional, mobile) -------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Controls")
    UButton BTN_TurnLeft;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Controls")
    UButton BTN_Pause;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Controls")
    UButton BTN_TurnRight;

    // ---- Internal state ---------------------------------------

    private UScoreSubsystem ScoreSubRef;
    private AShipActor TrackedShip;
    private float CurrentScore = 0.0;
    private int ArtifactsCollected = 0;
    private float ScoreMultiplier = 1.0;

    // ---- Lifecycle --------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        ScoreSubRef = UScoreSubsystem::Get();
        if (ScoreSubRef != nullptr)
        {
            ScoreSubRef.OnScoreChanged.AddUFunction(this, n"OnScoreChanged");
            ScoreSubRef.OnArtifactsChanged.AddUFunction(this, n"OnArtifactsChanged");
            ScoreSubRef.OnMultiplierChanged.AddUFunction(this, n"OnMultiplierChanged");

            CurrentScore = ScoreSubRef.CurrentScore;
            ArtifactsCollected = ScoreSubRef.ArtifactsCollected;
            ScoreMultiplier = ScoreSubRef.ScoreMultiplier;
        }

        // Bind bottom buttons
        if (BTN_Pause != nullptr)
            BTN_Pause.OnClicked.AddUFunction(this, n"HandlePauseClicked");

        // Hide optional panels by default
        if (Panel_Shield != nullptr)
            Panel_Shield.SetVisibility(ESlateVisibility::Collapsed);
        if (Panel_Magnet != nullptr)
            Panel_Magnet.SetVisibility(ESlateVisibility::Collapsed);
        if (Panel_Multiplier != nullptr)
            Panel_Multiplier.SetVisibility(ESlateVisibility::Collapsed);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(FGeometry MyGeometry, float DeltaTime)
    {
        if (TrackedShip == nullptr)
        {
            TArray<AShipActor> ships;
            GetAllActorsOfClass(ships);
            if (ships.Num() > 0)
                TrackedShip = ships[0];
            else
                return;
        }

        UpdateScoreDisplay();
        UpdateDistanceDisplay();
        UpdateSpeedDisplay();
        UpdateArtifactsDisplay();
        UpdateBoostBar();
        UpdateShieldBar();
        UpdateMagnetBar();
        UpdateMultiplier();
    }

    // ---- Event Handlers ---------------------------------------

    UFUNCTION()
    private void OnScoreChanged(float NewScore)
    {
        CurrentScore = NewScore;
    }

    UFUNCTION()
    private void OnArtifactsChanged(int NewArtifacts)
    {
        ArtifactsCollected = NewArtifacts;
    }

    UFUNCTION()
    private void OnMultiplierChanged(float NewMultiplier)
    {
        ScoreMultiplier = NewMultiplier;
    }

    UFUNCTION()
    private void HandlePauseClicked()
    {
        UGameFlowSubsystem GameFlow = UGameFlowSubsystem::Get();
        if (GameFlow != nullptr)
            GameFlow.TogglePause();
    }

    // ---- Update Functions -------------------------------------

    private void UpdateScoreDisplay()
    {
        if (TXT_Score != nullptr)
            TXT_Score.SetText(FText::FromString(f"{CurrentScore:.0f}"));
    }

    private void UpdateDistanceDisplay()
    {
        if (TXT_Distance == nullptr)
            return;
        float dist = TrackedShip.DistanceTraveled;
        if (dist >= 1000000.0)
            TXT_Distance.SetText(FText::FromString(f"{dist / 1000000.0:.2f}M km"));
        else if (dist >= 1000.0)
            TXT_Distance.SetText(FText::FromString(f"{dist / 1000.0:.1f}K km"));
        else
            TXT_Distance.SetText(FText::FromString(f"{dist:.0f} km"));
    }

    private void UpdateSpeedDisplay()
    {
        if (TXT_Speed == nullptr)
            return;
        UForwardMovementComponent Forward = UForwardMovementComponent::Get(TrackedShip);
        if (Forward != nullptr)
            TXT_Speed.SetText(FText::FromString(f"{Forward.CurrentSpeed:.0f} km/s"));
    }

    private void UpdateArtifactsDisplay()
    {
        if (TXT_Artifacts != nullptr)
            TXT_Artifacts.SetText(FText::FromString(f"{ArtifactsCollected}"));
    }

    private void UpdateBoostBar()
    {
        UBoostComponent Boost = UBoostComponent::Get(TrackedShip);
        if (Boost == nullptr) return;

        float percent = 0.0;
        if (Boost.bIsBoosting)
        {
            percent = (Boost.Duration > 0.0) ? Boost.BoostTimeRemaining / Boost.Duration : 0.0;
        }
        else if (Boost.bOnCooldown)
        {
            percent = (Boost.Cooldown > 0.0) ? 1.0 - (Boost.CooldownRemaining / Boost.Cooldown) : 1.0;
        }
        else
        {
            percent = 1.0;
        }

        if (PB_Boost != nullptr)
            PB_Boost.SetPercent(percent);
        if (TXT_BoostPercent != nullptr)
            TXT_BoostPercent.SetText(FText::FromString(f"{percent * 100.0:.0f}%"));
    }

    private void UpdateShieldBar()
    {
        UPowerUpComponent PowerUp = UPowerUpComponent::Get(TrackedShip);
        if (PowerUp == nullptr || !PowerUp.bShieldActive)
        {
            if (Panel_Shield != nullptr)
                Panel_Shield.SetVisibility(ESlateVisibility::Collapsed);
            return;
        }

        if (Panel_Shield != nullptr)
            Panel_Shield.SetVisibility(ESlateVisibility::Visible);

        float percent = (PowerUp.ShieldDuration > 0.0) ? PowerUp.ShieldTimeRemaining / PowerUp.ShieldDuration : 0.0;
        if (PB_Shield != nullptr)
            PB_Shield.SetPercent(percent);
        if (TXT_ShieldPercent != nullptr)
            TXT_ShieldPercent.SetText(FText::FromString(f"{percent * 100.0:.0f}%"));
    }

    private void UpdateMagnetBar()
    {
        UPowerUpComponent PowerUp = UPowerUpComponent::Get(TrackedShip);
        if (PowerUp == nullptr || !PowerUp.bMagnetActive)
        {
            if (Panel_Magnet != nullptr)
                Panel_Magnet.SetVisibility(ESlateVisibility::Collapsed);
            return;
        }

        if (Panel_Magnet != nullptr)
            Panel_Magnet.SetVisibility(ESlateVisibility::Visible);

        float percent = (PowerUp.MagnetDuration > 0.0) ? PowerUp.MagnetTimeRemaining / PowerUp.MagnetDuration : 0.0;
        if (PB_Magnet != nullptr)
            PB_Magnet.SetPercent(percent);
        if (TXT_MagnetPercent != nullptr)
            TXT_MagnetPercent.SetText(FText::FromString(f"{percent * 100.0:.0f}%"));
    }

    private void UpdateMultiplier()
    {
        if (ScoreMultiplier > 1.0)
        {
            if (Panel_Multiplier != nullptr)
                Panel_Multiplier.SetVisibility(ESlateVisibility::Visible);
            if (TXT_Multiplier != nullptr)
                TXT_Multiplier.SetText(FText::FromString(f"x{ScoreMultiplier:.1f}"));
        }
        else
        {
            if (Panel_Multiplier != nullptr)
                Panel_Multiplier.SetVisibility(ESlateVisibility::Collapsed);
        }
    }

    // ---- Helper Functions (for Blueprint binding) ------------

    UFUNCTION(BlueprintPure)
    FText GetScoreText() const
    {
        return FText::FromString(f"{CurrentScore:.0f}");
    }

    UFUNCTION(BlueprintPure)
    FText GetArtifactsText() const
    {
        return FText::FromString(f"{ArtifactsCollected}");
    }
}
