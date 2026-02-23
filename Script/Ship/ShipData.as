// ============================================================
//  ShipData.as
//  Ship tuning configuration. Create a Blueprint child of the
//  ship actor and fill these values in the defaults panel,
//  or use as a struct on the ShipActor directly.
// ============================================================

struct FShipData
{
    // ---- Forward movement -----------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Forward")
    float InitialForwardSpeed = 1500.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Forward")
    float MaxForwardSpeed = 4000.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Forward")
    float AccelerationRate = 50.0;

    // Force multiplier to reach target forward speed.
    UPROPERTY(EditAnywhere, Category = "Ship|Forward")
    float ForwardThrust = 60.0;

    // ---- Lateral movement -----------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Lateral")
    float LateralThrust = 2200.0;

    // Damping on sideways velocity to prevent infinite sliding.
    UPROPERTY(EditAnywhere, Category = "Ship|Lateral")
    float LateralDrag = 14.0;

    // Input sensitivity multiplier for touch/button input.
    UPROPERTY(EditAnywhere, Category = "Ship|Lateral")
    float ButtonInputSensitivity = 1.0;

    // ---- Speed-dependent turning (passed to LateralMovementComponent) --

    UPROPERTY(EditAnywhere, Category = "Ship|Lateral|SpeedScaling")
    float SpeedThrustScaling = 0.6;

    UPROPERTY(EditAnywhere, Category = "Ship|Lateral|SpeedScaling")
    float SpeedForMaxThrust = 3000.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Lateral|SpeedScaling")
    float MinThrustMultiplier = 0.5;

    UPROPERTY(EditAnywhere, Category = "Ship|Lateral|SpeedScaling")
    float SpeedInputResponsiveness = 1.5;

    // ---- Rotation / banking ---------------------------------

    // Max bank/roll angle (degrees) when turning.
    UPROPERTY(EditAnywhere, Category = "Ship|Rotation")
    float MaxBankAngle = 35.0;

    // Bank angle scaling with speed (sportier feel at speed)
    UPROPERTY(EditAnywhere, Category = "Ship|Rotation")
    float SpeedBankScaling = 0.3;

    // How fast the ship aligns to terrain normal.
    UPROPERTY(EditAnywhere, Category = "Ship|Rotation")
    float TerrainAlignSpeed = 8.0;

    // ---- Hover physics --------------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Hover")
    float HoverHeight = 180.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Hover")
    float HoverSpringForce = 100.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Hover")
    float HoverDamping = 12.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Hover")
    float HoverRaycastDistance = 1200.0;

    // ---- Physics tuning -------------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Physics")
    float LinearDrag = 0.3;

    UPROPERTY(EditAnywhere, Category = "Ship|Physics")
    float AngularDrag = 3.0;

    // ---- Lane constraints -----------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Lanes")
    int NumberOfLanes = 5;

    UPROPERTY(EditAnywhere, Category = "Ship|Lanes")
    float LaneWidth = 200.0;

    // Spring force pushing ship back into playable area.
    UPROPERTY(EditAnywhere, Category = "Ship|Lanes")
    float EdgeSpringForce = 100.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Lanes")
    float EdgeShakeIntensity = 3.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Lanes")
    float EdgeShakeDuration = 0.15;

    // ---- Boost ----------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Boost")
    float BoostSpeedMultiplier = 2.0;

    UPROPERTY(EditAnywhere, Category = "Ship|Boost")
    float BoostDuration = 3.5;

    // ---- Visual speed cap for particles ---------------------

    UPROPERTY(EditAnywhere, Category = "Ship|Visual")
    float MaxVisualSpeed = 2500.0;

    // ---- Hover ray offsets (local space) --------------------
    // Filled via Blueprint defaults. If empty, a single center ray is used.
}
