// ============================================================
//  ShipDefinition.as
//  Data structures for the modular ship system.
//  Ships are defined by a base definition + upgrade slots.
//  Designers add new ships by creating FShipDefinition entries
//  in the ShipRegistrySubsystem (via TerrainManager or GameMode BP).
//
//  Upgrade slots: Base, Engines, Armaments, Wings
//  Each slot has a tier and modifies ship stats.
// ============================================================

// ---- Upgrade slot types ------------------------------------

enum EUpgradeSlot
{
    Base,
    Engines,
    Armaments,
    Wings,
}

// ---- Ship stat ratings (0-100 scale for UI display) --------

struct FShipStatRatings
{
    UPROPERTY(EditAnywhere, Category = "Stats")
    float SpeedRating = 50.0;

    UPROPERTY(EditAnywhere, Category = "Stats")
    float ShieldRating = 50.0;

    UPROPERTY(EditAnywhere, Category = "Stats")
    float ThrustRating = 50.0;

    UPROPERTY(EditAnywhere, Category = "Stats")
    float AgilityRating = 50.0;

    UPROPERTY(EditAnywhere, Category = "Stats")
    float BoostRating = 50.0;
}

// ---- Upgrade definition ------------------------------------

struct FUpgradeDefinition
{
    UPROPERTY(EditAnywhere, Category = "Upgrade|Identity")
    FName UpgradeId = n"default";

    UPROPERTY(EditAnywhere, Category = "Upgrade|Identity")
    FString DisplayName = "Default Upgrade";

    UPROPERTY(EditAnywhere, Category = "Upgrade|Identity")
    FString Description = "";

    UPROPERTY(EditAnywhere, Category = "Upgrade|Identity")
    EUpgradeSlot Slot = EUpgradeSlot::Base;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Identity")
    int Tier = 1;

    // Cost in artifacts to purchase
    UPROPERTY(EditAnywhere, Category = "Upgrade|Economy")
    int ArtifactCost = 100;

    // Preview image for UI
    UPROPERTY(EditAnywhere, Category = "Upgrade|Visual")
    UTexture2D PreviewTexture;

    // Mesh to swap onto the ship (optional — null means no mesh change)
    UPROPERTY(EditAnywhere, Category = "Upgrade|Visual")
    UStaticMesh UpgradeMesh;

    // ---- Stat modifiers (additive to base ship stats) ------

    UPROPERTY(EditAnywhere, Category = "Upgrade|Stats")
    float SpeedModifier = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Stats")
    float ShieldModifier = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Stats")
    float ThrustModifier = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Stats")
    float AgilityModifier = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Stats")
    float BoostModifier = 0.0;

    // ---- Physics tuning overrides (applied on top of base) --

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float ForwardSpeedBonus = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float LateralThrustBonus = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float BoostMultiplierBonus = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float BoostDurationBonus = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float HoverHeightBonus = 0.0;

    UPROPERTY(EditAnywhere, Category = "Upgrade|Physics")
    float ShieldDurationBonus = 0.0;
}

// ---- Ship definition (one per ship type) -------------------

struct FShipDefinition
{
    UPROPERTY(EditAnywhere, Category = "Ship|Identity")
    FName ShipId = n"default_ship";

    UPROPERTY(EditAnywhere, Category = "Ship|Identity")
    FString DisplayName = "Vanguard";

    UPROPERTY(EditAnywhere, Category = "Ship|Identity")
    FString ShipClassName = "Interceptor";

    UPROPERTY(EditAnywhere, Category = "Ship|Identity")
    int Tier = 1;

    UPROPERTY(EditAnywhere, Category = "Ship|Identity")
    FString Description = "A balanced starter ship.";

    // Blueprint class to spawn (must inherit from AShipActor)
    UPROPERTY(EditAnywhere, Category = "Ship|Setup")
    TSubclassOf<AShipActor> ShipBlueprint;

    // Preview texture for UI
    UPROPERTY(EditAnywhere, Category = "Ship|Visual")
    UTexture2D PreviewTexture;

    // Base stat ratings (0-100 for UI)
    UPROPERTY(EditAnywhere, Category = "Ship|Stats")
    FShipStatRatings BaseStats;

    // Base physics tuning (overrides FShipData defaults)
    UPROPERTY(EditAnywhere, Category = "Ship|Physics")
    FShipData BasePhysics;

    // Cost to unlock (0 = free/starter ship)
    UPROPERTY(EditAnywhere, Category = "Ship|Economy")
    int UnlockCost = 0;

    // Available upgrades per slot (designer fills these arrays)
    UPROPERTY(EditAnywhere, Category = "Ship|Upgrades")
    TArray<FUpgradeDefinition> BaseUpgrades;

    UPROPERTY(EditAnywhere, Category = "Ship|Upgrades")
    TArray<FUpgradeDefinition> EngineUpgrades;

    UPROPERTY(EditAnywhere, Category = "Ship|Upgrades")
    TArray<FUpgradeDefinition> ArmamentUpgrades;

    UPROPERTY(EditAnywhere, Category = "Ship|Upgrades")
    TArray<FUpgradeDefinition> WingUpgrades;
}

// ---- Equipped loadout (what the player has selected) --------

struct FShipLoadout
{
    UPROPERTY(EditAnywhere, Category = "Loadout")
    FName ShipId = n"default_ship";

    UPROPERTY(EditAnywhere, Category = "Loadout")
    FName EquippedBase = n"";

    UPROPERTY(EditAnywhere, Category = "Loadout")
    FName EquippedEngines = n"";

    UPROPERTY(EditAnywhere, Category = "Loadout")
    FName EquippedArmaments = n"";

    UPROPERTY(EditAnywhere, Category = "Loadout")
    FName EquippedWings = n"";
}
