// ============================================================
//  GameData.as
//  Core enums and shared data structures for the entire game.
// ============================================================

// ---- Game flow phases --------------------------------------

enum EGamePhase
{
    Boot,
    Menu,
    Intro,
    Playing,
    Paused,
    GameOver,
}

// ---- Object identity tags ----------------------------------

enum EObjectTag
{
    Untagged,
    Obstacle,
    Collectible,
    EnemyShip,
    PowerUp,
}

// ---- Power-up types ----------------------------------------

enum EPowerUpType
{
    Shield,
    SpeedBoost,
    MagnetCollector,
    Boost,
}

// ---- Spawnable object config (replaces Unity SpawnableObjectSO) --

struct FSpawnableObjectConfig
{
    UPROPERTY(EditAnywhere, Category = "Spawnable")
    TSubclassOf<AActor> ActorClass;

    UPROPERTY(EditAnywhere, Category = "Spawnable")
    EObjectTag ObjectTag = EObjectTag::Untagged;

    // Probability of this object spawning per segment [0..1].
    UPROPERTY(EditAnywhere, Category = "Spawnable")
    float SpawnRate = 0.5;

    // Vertical placement range (cm above ground).
    UPROPERTY(EditAnywhere, Category = "Spawnable")
    float HeightMin = 150.0;

    UPROPERTY(EditAnywhere, Category = "Spawnable")
    float HeightMax = 500.0;

    // Random scale range per axis.
    UPROPERTY(EditAnywhere, Category = "Spawnable")
    FVector SizeMin = FVector(1.0, 1.0, 1.0);

    UPROPERTY(EditAnywhere, Category = "Spawnable")
    FVector SizeMax = FVector(1.0, 1.0, 1.0);
}

// ---- Power-up effect config (replaces Unity PowerUpEffectSO) --

struct FPowerUpEffectConfig
{
    UPROPERTY(EditAnywhere, Category = "PowerUp")
    EPowerUpType Type = EPowerUpType::Shield;

    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float Duration = 5.0;

    // Speed multiplier (for SpeedBoost type).
    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float SpeedMultiplier = 1.5;

    // Magnet attraction radius (cm).
    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float AttractionRadius = 1500.0;

    // Magnet attraction speed.
    UPROPERTY(EditAnywhere, Category = "PowerUp")
    float AttractionSpeed = 800.0;
}

// ---- Audio event names (constants) -------------------------

namespace AudioEvents
{
    const FName ArtifactCollected = n"ArtifactCollected";
    const FName PlayerShipEngine = n"PlayerShipEngine";
    const FName EnemyShipPassby = n"EnemyShipPassby";
    const FName Explosion = n"Explosion";
    const FName GameOver = n"GameOver";
    const FName NearMiss = n"NearMiss";
}
