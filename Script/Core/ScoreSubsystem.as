// ============================================================
//  ScoreSubsystem.as
//  World subsystem for score tracking, artifact collection,
//  multipliers, and near-miss bonuses.
//  Mirrors Unity's ScoreManager as a subsystem.
// ============================================================

event void FOnScoreChanged(float NewScore);
event void FOnArtifactsChanged(int NewArtifacts);
event void FOnMultiplierChanged(float NewMultiplier);

class UScoreSubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnScoreChanged OnScoreChanged;

    UPROPERTY()
    FOnArtifactsChanged OnArtifactsChanged;

    UPROPERTY()
    FOnMultiplierChanged OnMultiplierChanged;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Score")
    int PointsPerArtifact = 10;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Score")
    float CurrentScore = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Score")
    int ArtifactsCollected = 0;

    UPROPERTY(BlueprintReadOnly, Category = "Score")
    float ScoreMultiplier = 1.0;

    // ---- Internal -------------------------------------------

    private FTimerHandle MultiplierTimerHandle;

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void HandleArtifactCollected()
    {
        ArtifactsCollected++;
        OnArtifactsChanged.Broadcast(ArtifactsCollected);

        CurrentScore += PointsPerArtifact * ScoreMultiplier;
        OnScoreChanged.Broadcast(CurrentScore);

        if (bShowDebug)
            Print(f"[Score] Artifact! +{PointsPerArtifact * ScoreMultiplier:.0f}pts  Total:{CurrentScore:.0f} Artifacts:{ArtifactsCollected}");
    }

    UFUNCTION()
    void AddNearMissBonus(int BonusPoints)
    {
        CurrentScore += BonusPoints * ScoreMultiplier;
        OnScoreChanged.Broadcast(CurrentScore);

        if (bShowDebug)
            Print(f"[Score] NearMiss! +{BonusPoints * ScoreMultiplier:.0f}pts  Total:{CurrentScore:.0f}");
    }

    UFUNCTION()
    void AddScore(float Points)
    {
        CurrentScore += Points * ScoreMultiplier;
        OnScoreChanged.Broadcast(CurrentScore);
    }

    UFUNCTION()
    void ActivateScoreMultiplier(float Multiplier, float Duration)
    {
        ScoreMultiplier = Multiplier;
        OnMultiplierChanged.Broadcast(ScoreMultiplier);

        if (bShowDebug)
            Print(f"[Score] Multiplier x{Multiplier:.1f} for {Duration:.1f}s");

        // Reset after duration
        System::SetTimer(this, n"OnMultiplierExpired", Duration, false);
    }

    UFUNCTION()
    void ResetScore()
    {
        CurrentScore = 0.0;
        ArtifactsCollected = 0;
        ScoreMultiplier = 1.0;

        OnScoreChanged.Broadcast(CurrentScore);
        OnArtifactsChanged.Broadcast(ArtifactsCollected);
        OnMultiplierChanged.Broadcast(ScoreMultiplier);

        if (bShowDebug)
            Print("[Score] Reset to 0");
    }

    UFUNCTION(BlueprintPure)
    float GetCurrentScore() const
    {
        return CurrentScore;
    }

    UFUNCTION(BlueprintPure)
    int GetArtifactsCollected() const
    {
        return ArtifactsCollected;
    }

    // ---- Timer callbacks ------------------------------------

    UFUNCTION()
    private void OnMultiplierExpired()
    {
        ScoreMultiplier = 1.0;
        OnMultiplierChanged.Broadcast(ScoreMultiplier);
    }
}
