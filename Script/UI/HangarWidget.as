// ============================================================
//  HangarWidget.as
//  Designer-friendly hangar/upgrade screen. Create a Blueprint
//  child (WBP_Hangar) and design in UMG. Place widgets with
//  the exact names below for auto-binding.
//
//  Shows the selected ship's upgrade slots (Base, Engines,
//  Armaments, Wings) with purchase/equip buttons.
//
//  REFERENCE LAYOUT:
//  ┌──────────────────────────────────┐
//  │ ← BACK          HANGAR          │
//  │                                  │
//  │  [ShipPreview]     ShipName     │
//  │                    ShipClass    │
//  │                                  │
//  │  ┌─BASE──────────────────────┐  │
//  │  │ Name  Tier  [BUY/EQUIP]  │  │
//  │  └───────────────────────────┘  │
//  │  ┌─ENGINES───────────────────┐  │
//  │  │ Name  Tier  [BUY/EQUIP]  │  │
//  │  └───────────────────────────┘  │
//  │  ┌─ARMAMENTS─────────────────┐  │
//  │  │ Name  Tier  [BUY/EQUIP]  │  │
//  │  └───────────────────────────┘  │
//  │  ┌─WINGS─────────────────────┐  │
//  │  │ Name  Tier  [BUY/EQUIP]  │  │
//  │  └───────────────────────────┘  │
//  │                                  │
//  │  Artifacts: ⬡ 1,240             │
//  └──────────────────────────────────┘
// ============================================================

class UHangarWidget : UUserWidget
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- BindWidget references --------------------------------

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Header")
    UButton BTN_Back;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UImage IMG_ShipPreview;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UTextBlock TXT_ShipName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Ship")
    UTextBlock TXT_ShipClass;

    // ---- Upgrade slot panels ----------------------------------
    // Each slot has: label, current upgrade name, cost text, action button

    // Base slot
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Base")
    UTextBlock TXT_BaseName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Base")
    UTextBlock TXT_BaseCost;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Base")
    UButton BTN_BaseAction;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Base")
    UTextBlock TXT_BaseActionLabel;

    // Engines slot
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Engines")
    UTextBlock TXT_EnginesName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Engines")
    UTextBlock TXT_EnginesCost;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Engines")
    UButton BTN_EnginesAction;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Engines")
    UTextBlock TXT_EnginesActionLabel;

    // Armaments slot
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Armaments")
    UTextBlock TXT_ArmamentsName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Armaments")
    UTextBlock TXT_ArmamentsCost;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Armaments")
    UButton BTN_ArmamentsAction;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Armaments")
    UTextBlock TXT_ArmamentsActionLabel;

    // Wings slot
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Wings")
    UTextBlock TXT_WingsName;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Wings")
    UTextBlock TXT_WingsCost;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Wings")
    UButton BTN_WingsAction;

    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Slots|Wings")
    UTextBlock TXT_WingsActionLabel;

    // Artifact balance
    UPROPERTY(BindWidget, BlueprintReadOnly, Category = "UI|Economy")
    UTextBlock TXT_ArtifactBalance;

    // ---- Internal state ---------------------------------------

    // Index into the upgrade list for each slot (for cycling through available upgrades)
    private int BaseUpgradeIndex = 0;
    private int EnginesUpgradeIndex = 0;
    private int ArmamentsUpgradeIndex = 0;
    private int WingsUpgradeIndex = 0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Construct()
    {
        if (BTN_Back != nullptr)
            BTN_Back.OnClicked.AddUFunction(this, n"HandleBackClicked");

        if (BTN_BaseAction != nullptr)
            BTN_BaseAction.OnClicked.AddUFunction(this, n"HandleBaseActionClicked");
        if (BTN_EnginesAction != nullptr)
            BTN_EnginesAction.OnClicked.AddUFunction(this, n"HandleEnginesActionClicked");
        if (BTN_ArmamentsAction != nullptr)
            BTN_ArmamentsAction.OnClicked.AddUFunction(this, n"HandleArmamentsActionClicked");
        if (BTN_WingsAction != nullptr)
            BTN_WingsAction.OnClicked.AddUFunction(this, n"HandleWingsActionClicked");

        RefreshAll();
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void RefreshAll()
    {
        RefreshShipInfo();
        RefreshSlot(EUpgradeSlot::Base);
        RefreshSlot(EUpgradeSlot::Engines);
        RefreshSlot(EUpgradeSlot::Armaments);
        RefreshSlot(EUpgradeSlot::Wings);
        RefreshBalance();
    }

    // ---- Internal -------------------------------------------

    private void RefreshShipInfo()
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Progress == nullptr || Registry == nullptr)
            return;

        FShipDefinition ShipDef = Registry.GetShipById(Progress.SelectedShipId);

        if (TXT_ShipName != nullptr)
            TXT_ShipName.SetText(FText::FromString(ShipDef.DisplayName));
        if (TXT_ShipClass != nullptr)
            TXT_ShipClass.SetText(FText::FromString(f"{ShipDef.ShipClassName} · Tier {ShipDef.Tier}"));
        if (IMG_ShipPreview != nullptr && ShipDef.PreviewTexture != nullptr)
            IMG_ShipPreview.SetBrushFromTexture(ShipDef.PreviewTexture, true);
    }

    private void RefreshSlot(EUpgradeSlot Slot)
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Progress == nullptr || Registry == nullptr)
            return;

        FShipDefinition ShipDef = Registry.GetShipById(Progress.SelectedShipId);
        TArray<FUpgradeDefinition> upgrades = Registry.GetUpgradesForSlot(ShipDef, Slot);
        FShipLoadout loadout = Progress.GetSelectedLoadout();

        int upgradeIdx = GetUpgradeIndex(Slot);
        if (upgradeIdx >= upgrades.Num())
            upgradeIdx = 0;

        UTextBlock nameText = GetNameText(Slot);
        UTextBlock costText = GetCostText(Slot);
        UTextBlock actionLabel = GetActionLabel(Slot);

        if (upgrades.Num() == 0)
        {
            if (nameText != nullptr) nameText.SetText(FText::FromString("No upgrades available"));
            if (costText != nullptr) costText.SetText(FText::FromString(""));
            if (actionLabel != nullptr) actionLabel.SetText(FText::FromString("—"));
            return;
        }

        FUpgradeDefinition upg = upgrades[upgradeIdx];
        FName equippedId = GetEquippedId(loadout, Slot);
        bool bOwned = Progress.IsUpgradePurchased(Progress.SelectedShipId, Slot, upg.UpgradeId);
        bool bEquipped = (equippedId == upg.UpgradeId);

        if (nameText != nullptr)
            nameText.SetText(FText::FromString(f"{upg.DisplayName} (T{upg.Tier})"));

        if (bEquipped)
        {
            if (costText != nullptr) costText.SetText(FText::FromString("EQUIPPED"));
            if (actionLabel != nullptr) actionLabel.SetText(FText::FromString("EQUIPPED"));
        }
        else if (bOwned)
        {
            if (costText != nullptr) costText.SetText(FText::FromString("OWNED"));
            if (actionLabel != nullptr) actionLabel.SetText(FText::FromString("EQUIP"));
        }
        else
        {
            if (costText != nullptr) costText.SetText(FText::FromString(f"{upg.ArtifactCost} Artifacts"));
            if (actionLabel != nullptr) actionLabel.SetText(FText::FromString("BUY"));
        }
    }

    private void RefreshBalance()
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        if (Progress != nullptr && TXT_ArtifactBalance != nullptr)
            TXT_ArtifactBalance.SetText(FText::FromString(f"{Progress.Artifacts}"));
    }

    // ---- Action logic ---------------------------------------

    private void HandleSlotAction(EUpgradeSlot Slot)
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Progress == nullptr || Registry == nullptr)
            return;

        FShipDefinition ShipDef = Registry.GetShipById(Progress.SelectedShipId);
        TArray<FUpgradeDefinition> upgrades = Registry.GetUpgradesForSlot(ShipDef, Slot);
        int upgradeIdx = GetUpgradeIndex(Slot);
        if (upgradeIdx >= upgrades.Num())
            return;

        FUpgradeDefinition upg = upgrades[upgradeIdx];
        bool bOwned = Progress.IsUpgradePurchased(Progress.SelectedShipId, Slot, upg.UpgradeId);

        if (!bOwned)
        {
            // Try to purchase
            bool bSuccess = Progress.PurchaseUpgrade(Progress.SelectedShipId, Slot, upg.UpgradeId, upg.ArtifactCost);
            if (bSuccess)
            {
                Progress.EquipUpgrade(Progress.SelectedShipId, Slot, upg.UpgradeId);
                if (bShowDebug) Print(f"[Hangar] Purchased & equipped {upg.DisplayName}");
            }
            else
            {
                if (bShowDebug) Print(f"[Hangar] Cannot afford {upg.DisplayName} (need {upg.ArtifactCost})");
            }
        }
        else
        {
            // Equip owned upgrade
            Progress.EquipUpgrade(Progress.SelectedShipId, Slot, upg.UpgradeId);
            if (bShowDebug) Print(f"[Hangar] Equipped {upg.DisplayName}");
        }

        RefreshAll();
    }

    // ---- Button handlers ------------------------------------

    UFUNCTION()
    private void HandleBackClicked()
    {
        if (bShowDebug) Print("[Hangar] Back");
        SetVisibility(ESlateVisibility::Collapsed);
    }

    UFUNCTION()
    private void HandleBaseActionClicked()      { HandleSlotAction(EUpgradeSlot::Base); }

    UFUNCTION()
    private void HandleEnginesActionClicked()   { HandleSlotAction(EUpgradeSlot::Engines); }

    UFUNCTION()
    private void HandleArmamentsActionClicked() { HandleSlotAction(EUpgradeSlot::Armaments); }

    UFUNCTION()
    private void HandleWingsActionClicked()     { HandleSlotAction(EUpgradeSlot::Wings); }

    // ---- Helpers --------------------------------------------

    private int GetUpgradeIndex(EUpgradeSlot Slot)
    {
        if (Slot == EUpgradeSlot::Base) return BaseUpgradeIndex;
        if (Slot == EUpgradeSlot::Engines) return EnginesUpgradeIndex;
        if (Slot == EUpgradeSlot::Armaments) return ArmamentsUpgradeIndex;
        if (Slot == EUpgradeSlot::Wings) return WingsUpgradeIndex;
        return 0;
    }

    private UTextBlock GetNameText(EUpgradeSlot Slot)
    {
        if (Slot == EUpgradeSlot::Base) return TXT_BaseName;
        if (Slot == EUpgradeSlot::Engines) return TXT_EnginesName;
        if (Slot == EUpgradeSlot::Armaments) return TXT_ArmamentsName;
        if (Slot == EUpgradeSlot::Wings) return TXT_WingsName;
        return nullptr;
    }

    private UTextBlock GetCostText(EUpgradeSlot Slot)
    {
        if (Slot == EUpgradeSlot::Base) return TXT_BaseCost;
        if (Slot == EUpgradeSlot::Engines) return TXT_EnginesCost;
        if (Slot == EUpgradeSlot::Armaments) return TXT_ArmamentsCost;
        if (Slot == EUpgradeSlot::Wings) return TXT_WingsCost;
        return nullptr;
    }

    private UTextBlock GetActionLabel(EUpgradeSlot Slot)
    {
        if (Slot == EUpgradeSlot::Base) return TXT_BaseActionLabel;
        if (Slot == EUpgradeSlot::Engines) return TXT_EnginesActionLabel;
        if (Slot == EUpgradeSlot::Armaments) return TXT_ArmamentsActionLabel;
        if (Slot == EUpgradeSlot::Wings) return TXT_WingsActionLabel;
        return nullptr;
    }

    private FName GetEquippedId(FShipLoadout Loadout, EUpgradeSlot Slot)
    {
        if (Slot == EUpgradeSlot::Base) return Loadout.EquippedBase;
        if (Slot == EUpgradeSlot::Engines) return Loadout.EquippedEngines;
        if (Slot == EUpgradeSlot::Armaments) return Loadout.EquippedArmaments;
        if (Slot == EUpgradeSlot::Wings) return Loadout.EquippedWings;
        return n"";
    }
}
