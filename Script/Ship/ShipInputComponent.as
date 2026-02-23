// ============================================================
//  ShipInputComponent.as
//  Pure state holder — the ShipPlayerController pushes input
//  values into HorizontalInput and bBoostPressed via BindKey
//  callbacks. This component feeds those values to sibling
//  components every tick.
//  No UInputComponent or axis/action mappings needed here.
// ============================================================

class UShipInputComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Input state (written by ShipPlayerController) ------

    UPROPERTY(BlueprintReadOnly, Category = "Input")
    float HorizontalInput = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Input")
    bool bBoostPressed = false;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        FeedToLateral();

        if (bShowDebug)
            DebugDrawInputState();
    }

    // ---- Feed to sibling components -------------------------

    private void FeedToLateral()
    {
        ULateralMovementComponent Lateral = ULateralMovementComponent::Get(GetOwner());
        if (Lateral != nullptr)
            Lateral.SetInput(HorizontalInput);
    }

    private void DebugDrawInputState()
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr) return;

        FVector pos = OwnerActor.ActorLocation + FVector(0.0, 0.0, 250.0);
        FString inputText = f"Input H:{HorizontalInput:.2f} Boost:{bBoostPressed}";
        System::DrawDebugString(pos, inputText, nullptr, FLinearColor::Yellow, 0.0);
    }
}
