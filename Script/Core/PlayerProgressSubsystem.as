// ============================================================
//  PlayerProgressSubsystem.as
//  Game-instance subsystem tracking persistent player progress:
//   - Artifacts (currency)
//   - Unlocked ships & upgrades
//   - Run statistics (best run, total runs)
//   - Current loadout per ship
//
//  Uses SaveGame for persistence. Call Save() after mutations.
//  Designers can reset progress or grant artifacts via BP.
// ============================================================

event void FOnArtifactsUpdated(int NewTotal);
event void FOnUpgradePurchased(FName ShipId, EUpgradeSlot Slot, FName UpgradeId);
event void FOnShipUnlocked(FName ShipId);

class UPlayerProgressSubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events -----------------------------------------------

    UPROPERTY()
    FOnArtifactsUpdated OnArtifactsUpdated;

    UPROPERTY()
    FOnUpgradePurchased OnUpgradePurchased;

    UPROPERTY()
    FOnShipUnlocked OnShipUnlocked;

    // ---- Player data ------------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Progress|Currency")
    int Artifacts = 0;

    UPROPERTY(BlueprintReadOnly, Category = "Progress|Stats")
    float BestRunDistance = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Progress|Stats")
    int TotalRuns = 0;

    UPROPERTY(BlueprintReadOnly, Category = "Progress|Stats")
    int TotalArtifactsEverCollected = 0;

    // Unlocked ship IDs
    UPROPERTY(BlueprintReadOnly, Category = "Progress|Unlocks")
    TArray<FName> UnlockedShipIds;

    // Purchased upgrade IDs (stored as "ShipId.Slot.UpgradeId")
    UPROPERTY(BlueprintReadOnly, Category = "Progress|Unlocks")
    TArray<FName> PurchasedUpgradeKeys;

    // Current loadout per ship
    UPROPERTY(BlueprintReadOnly, Category = "Progress|Loadout")
    TArray<FShipLoadout> ShipLoadouts;

    // Currently selected ship
    UPROPERTY(BlueprintReadOnly, Category = "Progress|Selection")
    FName SelectedShipId = n"default_ship";

    // ---- Initialization ---------------------------------------

    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        // Default: first ship is always unlocked
        if (UnlockedShipIds.Num() == 0)
            UnlockedShipIds.Add(n"default_ship");

        if (bShowDebug)
            Print(f"[Progress] Init. Artifacts={Artifacts} Ships={UnlockedShipIds.Num()} Runs={TotalRuns}");
    }

    // ---- Currency API -----------------------------------------

    UFUNCTION()
    void AddArtifacts(int Amount)
    {
        Artifacts += Amount;
        TotalArtifactsEverCollected += Amount;
        OnArtifactsUpdated.Broadcast(Artifacts);

        if (bShowDebug)
            Print(f"[Progress] +{Amount} artifacts. Total={Artifacts}");
    }

    UFUNCTION()
    bool SpendArtifacts(int Amount)
    {
        if (Artifacts < Amount)
            return false;

        Artifacts -= Amount;
        OnArtifactsUpdated.Broadcast(Artifacts);

        if (bShowDebug)
            Print(f"[Progress] Spent {Amount} artifacts. Remaining={Artifacts}");
        return true;
    }

    UFUNCTION(BlueprintPure)
    bool CanAfford(int Amount) const
    {
        return Artifacts >= Amount;
    }

    // ---- Ship unlock API --------------------------------------

    UFUNCTION()
    bool UnlockShip(FName ShipId, int Cost)
    {
        if (IsShipUnlocked(ShipId))
            return true;

        if (!SpendArtifacts(Cost))
            return false;

        UnlockedShipIds.Add(ShipId);
        OnShipUnlocked.Broadcast(ShipId);

        if (bShowDebug)
            Print(f"[Progress] Unlocked ship: {ShipId}");
        return true;
    }

    UFUNCTION(BlueprintPure)
    bool IsShipUnlocked(FName ShipId) const
    {
        return UnlockedShipIds.Contains(ShipId);
    }

    UFUNCTION()
    void SelectShip(FName ShipId)
    {
        SelectedShipId = ShipId;
        if (bShowDebug)
            Print(f"[Progress] Selected ship: {ShipId}");
    }

    // ---- Upgrade purchase API ---------------------------------

    UFUNCTION()
    bool PurchaseUpgrade(FName ShipId, EUpgradeSlot Slot, FName UpgradeId, int Cost)
    {
        FName key = MakeUpgradeKey(ShipId, Slot, UpgradeId);
        if (IsUpgradePurchased(ShipId, Slot, UpgradeId))
            return true;

        if (!SpendArtifacts(Cost))
            return false;

        PurchasedUpgradeKeys.Add(key);
        OnUpgradePurchased.Broadcast(ShipId, Slot, UpgradeId);

        if (bShowDebug)
            Print(f"[Progress] Purchased upgrade: {key}");
        return true;
    }

    UFUNCTION(BlueprintPure)
    bool IsUpgradePurchased(FName ShipId, EUpgradeSlot Slot, FName UpgradeId) const
    {
        FName key = MakeUpgradeKey(ShipId, Slot, UpgradeId);
        return PurchasedUpgradeKeys.Contains(key);
    }

    // ---- Loadout API ------------------------------------------

    UFUNCTION()
    void EquipUpgrade(FName ShipId, EUpgradeSlot Slot, FName UpgradeId)
    {
        FShipLoadout Loadout = GetLoadout(ShipId);

        if (Slot == EUpgradeSlot::Base)
            Loadout.EquippedBase = UpgradeId;
        else if (Slot == EUpgradeSlot::Engines)
            Loadout.EquippedEngines = UpgradeId;
        else if (Slot == EUpgradeSlot::Armaments)
            Loadout.EquippedArmaments = UpgradeId;
        else if (Slot == EUpgradeSlot::Wings)
            Loadout.EquippedWings = UpgradeId;

        SetLoadout(ShipId, Loadout);

        if (bShowDebug)
            Print(f"[Progress] Equipped {UpgradeId} in {Slot} on {ShipId}");
    }

    UFUNCTION(BlueprintPure)
    FShipLoadout GetLoadout(FName ShipId) const
    {
        for (int i = 0; i < ShipLoadouts.Num(); i++)
        {
            if (ShipLoadouts[i].ShipId == ShipId)
                return ShipLoadouts[i];
        }
        // Return default loadout for this ship
        FShipLoadout Default;
        Default.ShipId = ShipId;
        return Default;
    }

    UFUNCTION(BlueprintPure)
    FShipLoadout GetSelectedLoadout() const
    {
        return GetLoadout(SelectedShipId);
    }

    // ---- Run tracking -----------------------------------------

    UFUNCTION()
    void RecordRunEnd(float Distance, int ArtifactsFromRun)
    {
        TotalRuns++;
        AddArtifacts(ArtifactsFromRun);

        if (Distance > BestRunDistance)
            BestRunDistance = Distance;

        if (bShowDebug)
            Print(f"[Progress] Run #{TotalRuns} ended. Dist={Distance:.0f} Artifacts={ArtifactsFromRun} Best={BestRunDistance:.0f}");
    }

    // ---- Display helpers --------------------------------------

    UFUNCTION(BlueprintPure)
    FString GetBestRunText() const
    {
        if (BestRunDistance >= 1000000.0)
            return f"{BestRunDistance / 1000000.0:.1f}M km";
        else if (BestRunDistance >= 1000.0)
            return f"{BestRunDistance / 1000.0:.1f}K km";
        else
            return f"{BestRunDistance:.0f} km";
    }

    // ---- Reset (for testing) ----------------------------------

    UFUNCTION()
    void ResetAllProgress()
    {
        Artifacts = 0;
        BestRunDistance = 0.0;
        TotalRuns = 0;
        TotalArtifactsEverCollected = 0;
        UnlockedShipIds.Empty();
        UnlockedShipIds.Add(n"default_ship");
        PurchasedUpgradeKeys.Empty();
        ShipLoadouts.Empty();
        SelectedShipId = n"default_ship";

        OnArtifactsUpdated.Broadcast(Artifacts);
    }

    // ---- Internal ---------------------------------------------

    private void SetLoadout(FName ShipId, FShipLoadout InLoadout)
    {
        for (int i = 0; i < ShipLoadouts.Num(); i++)
        {
            if (ShipLoadouts[i].ShipId == ShipId)
            {
                ShipLoadouts[i] = InLoadout;
                return;
            }
        }
        ShipLoadouts.Add(InLoadout);
    }

    private FName MakeUpgradeKey(FName ShipId, EUpgradeSlot Slot, FName UpgradeId) const
    {
        FString slotStr = "";
        if (Slot == EUpgradeSlot::Base) slotStr = "Base";
        else if (Slot == EUpgradeSlot::Engines) slotStr = "Engines";
        else if (Slot == EUpgradeSlot::Armaments) slotStr = "Armaments";
        else if (Slot == EUpgradeSlot::Wings) slotStr = "Wings";

        return FName(f"{ShipId}.{slotStr}.{UpgradeId}");
    }
}
