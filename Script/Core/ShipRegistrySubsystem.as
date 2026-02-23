// ============================================================
//  ShipRegistrySubsystem.as
//  Game-instance subsystem that holds ALL ship definitions and
//  upgrade catalogs. Designers populate these arrays via a
//  Blueprint child or by calling Register functions at startup.
//
//  This is the single source of truth for:
//   - Which ships exist in the game
//   - What upgrades are available for each slot
//   - Computing final ship stats from base + upgrades
// ============================================================

event void FOnShipRegistryChanged();

class UShipRegistrySubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events -----------------------------------------------

    UPROPERTY()
    FOnShipRegistryChanged OnRegistryChanged;

    // ---- Ship catalog (populate from TerrainManager or GameMode BP) --

    UPROPERTY(EditAnywhere, Category = "Registry|Ships")
    TArray<FShipDefinition> Ships;

    // ---- Public API -------------------------------------------

    UFUNCTION()
    void RegisterShip(FShipDefinition InShip)
    {
        Ships.Add(InShip);
        OnRegistryChanged.Broadcast();
        if (bShowDebug)
            Print(f"[Registry] Registered ship: {InShip.DisplayName} (id={InShip.ShipId})");
    }

    UFUNCTION(BlueprintPure)
    int GetShipCount() const
    {
        return Ships.Num();
    }

    UFUNCTION(BlueprintPure)
    FShipDefinition GetShipByIndex(int Index) const
    {
        if (Index >= 0 && Index < Ships.Num())
            return Ships[Index];
        FShipDefinition Default;
        return Default;
    }

    UFUNCTION(BlueprintPure)
    FShipDefinition GetShipById(FName ShipId) const
    {
        for (int i = 0; i < Ships.Num(); i++)
        {
            if (Ships[i].ShipId == ShipId)
                return Ships[i];
        }
        FShipDefinition Default;
        return Default;
    }

    UFUNCTION(BlueprintPure)
    int GetShipIndexById(FName ShipId) const
    {
        for (int i = 0; i < Ships.Num(); i++)
        {
            if (Ships[i].ShipId == ShipId)
                return i;
        }
        return -1;
    }

    // ---- Upgrade lookup ---------------------------------------

    UFUNCTION(BlueprintPure)
    FUpgradeDefinition GetUpgrade(FName ShipId, EUpgradeSlot Slot, FName UpgradeId) const
    {
        FShipDefinition ShipDef = GetShipById(ShipId);
        TArray<FUpgradeDefinition> upgrades = GetUpgradesForSlot(ShipDef, Slot);

        for (int i = 0; i < upgrades.Num(); i++)
        {
            if (upgrades[i].UpgradeId == UpgradeId)
                return upgrades[i];
        }
        FUpgradeDefinition Default;
        return Default;
    }

    UFUNCTION(BlueprintPure)
    TArray<FUpgradeDefinition> GetUpgradesForSlot(FShipDefinition ShipDef, EUpgradeSlot Slot) const
    {
        if (Slot == EUpgradeSlot::Base)
            return ShipDef.BaseUpgrades;
        else if (Slot == EUpgradeSlot::Engines)
            return ShipDef.EngineUpgrades;
        else if (Slot == EUpgradeSlot::Armaments)
            return ShipDef.ArmamentUpgrades;
        else if (Slot == EUpgradeSlot::Wings)
            return ShipDef.WingUpgrades;

        TArray<FUpgradeDefinition> Empty;
        return Empty;
    }

    // ---- Compute final stats with loadout ---------------------

    UFUNCTION(BlueprintPure)
    FShipStatRatings ComputeFinalStats(FName ShipId, FShipLoadout Loadout) const
    {
        FShipDefinition ShipDef = GetShipById(ShipId);
        FShipStatRatings result = ShipDef.BaseStats;

        // Apply each equipped upgrade's modifiers
        ApplyUpgradeModifiers(result, ShipDef, EUpgradeSlot::Base, Loadout.EquippedBase);
        ApplyUpgradeModifiers(result, ShipDef, EUpgradeSlot::Engines, Loadout.EquippedEngines);
        ApplyUpgradeModifiers(result, ShipDef, EUpgradeSlot::Armaments, Loadout.EquippedArmaments);
        ApplyUpgradeModifiers(result, ShipDef, EUpgradeSlot::Wings, Loadout.EquippedWings);

        // Clamp all ratings to 0-100
        result.SpeedRating = Math::Clamp(result.SpeedRating, 0.0, 100.0);
        result.ShieldRating = Math::Clamp(result.ShieldRating, 0.0, 100.0);
        result.ThrustRating = Math::Clamp(result.ThrustRating, 0.0, 100.0);
        result.AgilityRating = Math::Clamp(result.AgilityRating, 0.0, 100.0);
        result.BoostRating = Math::Clamp(result.BoostRating, 0.0, 100.0);

        return result;
    }

    // Compute the final FShipData physics config with all upgrades applied
    UFUNCTION(BlueprintPure)
    FShipData ComputeFinalPhysics(FName ShipId, FShipLoadout Loadout) const
    {
        FShipDefinition ShipDef = GetShipById(ShipId);
        FShipData result = ShipDef.BasePhysics;

        // Apply physics bonuses from each upgrade
        ApplyUpgradePhysics(result, ShipDef, EUpgradeSlot::Base, Loadout.EquippedBase);
        ApplyUpgradePhysics(result, ShipDef, EUpgradeSlot::Engines, Loadout.EquippedEngines);
        ApplyUpgradePhysics(result, ShipDef, EUpgradeSlot::Armaments, Loadout.EquippedArmaments);
        ApplyUpgradePhysics(result, ShipDef, EUpgradeSlot::Wings, Loadout.EquippedWings);

        return result;
    }

    // ---- Internal ---------------------------------------------

    private void ApplyUpgradeModifiers(FShipStatRatings&out Stats, FShipDefinition ShipDef, EUpgradeSlot Slot, FName UpgradeId) const
    {
        if (UpgradeId == n"")
            return;

        TArray<FUpgradeDefinition> upgrades = GetUpgradesForSlot(ShipDef, Slot);
        for (int i = 0; i < upgrades.Num(); i++)
        {
            if (upgrades[i].UpgradeId == UpgradeId)
            {
                Stats.SpeedRating += upgrades[i].SpeedModifier;
                Stats.ShieldRating += upgrades[i].ShieldModifier;
                Stats.ThrustRating += upgrades[i].ThrustModifier;
                Stats.AgilityRating += upgrades[i].AgilityModifier;
                Stats.BoostRating += upgrades[i].BoostModifier;
                return;
            }
        }
    }

    private void ApplyUpgradePhysics(FShipData&out Data, FShipDefinition ShipDef, EUpgradeSlot Slot, FName UpgradeId) const
    {
        if (UpgradeId == n"")
            return;

        TArray<FUpgradeDefinition> upgrades = GetUpgradesForSlot(ShipDef, Slot);
        for (int i = 0; i < upgrades.Num(); i++)
        {
            if (upgrades[i].UpgradeId == UpgradeId)
            {
                Data.MaxForwardSpeed += upgrades[i].ForwardSpeedBonus;
                Data.LateralThrust += upgrades[i].LateralThrustBonus;
                Data.BoostSpeedMultiplier += upgrades[i].BoostMultiplierBonus;
                Data.BoostDuration += upgrades[i].BoostDurationBonus;
                Data.HoverHeight += upgrades[i].HoverHeightBonus;
                return;
            }
        }
    }
}
