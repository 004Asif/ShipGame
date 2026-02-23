// ============================================================
//  HoverComponent.as
//  Multi-point physics-driven hover for any actor.
//  Attach to ships, enemies, obstacles, collectibles to make
//  them float above surfaces. Reads config from FShipData or
//  local overrides.
// ============================================================

event void FOnGroundedChanged(bool bNewGrounded);

class UHoverComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration (override per-instance in BP) --------

    UPROPERTY(EditAnywhere, Category = "Hover")
    float HoverHeight = 150.0;

    UPROPERTY(EditAnywhere, Category = "Hover")
    float SpringForce = 80.0;

    UPROPERTY(EditAnywhere, Category = "Hover")
    float Damping = 10.0;

    UPROPERTY(EditAnywhere, Category = "Hover")
    float RaycastDistance = 1000.0;

    // Visual bob settings
    UPROPERTY(EditAnywhere, Category = "Hover|Bob")
    bool bEnableBob = true;

    UPROPERTY(EditAnywhere, Category = "Hover|Bob")
    float BobAmplitude = 15.0;

    UPROPERTY(EditAnywhere, Category = "Hover|Bob")
    float BobFrequency = 1.5;

    // Local-space ray offsets. If empty, uses a single center ray.
    UPROPERTY(EditAnywhere, Category = "Hover|Rays")
    TArray<FVector> RayOffsets;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnGroundedChanged OnGroundedChanged;

    // ---- Read-only state ------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "Hover")
    bool bIsGrounded = false;

    UPROPERTY(BlueprintReadOnly, Category = "Hover")
    float CurrentGroundHeight = 0.0;

    UPROPERTY(BlueprintReadOnly, Category = "Hover")
    FVector TerrainNormal = FVector(0.0, 0.0, 1.0);

    UPROPERTY(BlueprintReadOnly, Category = "Hover")
    int GroundedRayCount = 0;

    // ---- Internal -------------------------------------------

    private float BobPhase = 0.0;
    private UPrimitiveComponent PrimitiveRoot;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        BobPhase = Math::RandRange(0.0, PI * 2.0);

        // Default ray offsets if none specified
        if (RayOffsets.Num() == 0)
        {
            RayOffsets.Add(FVector(0.0, 0.0, 0.0));
            RayOffsets.Add(FVector(50.0, -40.0, 0.0));
            RayOffsets.Add(FVector(50.0, 40.0, 0.0));
            RayOffsets.Add(FVector(-50.0, -40.0, 0.0));
            RayOffsets.Add(FVector(-50.0, 40.0, 0.0));
        }

        // Cache primitive root for AddForce
        AActor OwnerActor = GetOwner();
        if (OwnerActor != nullptr)
        {
            PrimitiveRoot = Cast<UPrimitiveComponent>(OwnerActor.GetRootComponent());
        }

        if (bShowDebug)
            Print(f"[Hover] BeginPlay. Rays={RayOffsets.Num()} Height={HoverHeight:.0f} Spring={SpringForce:.0f}");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if (PrimitiveRoot == nullptr)
            return;

        if (!PrimitiveRoot.IsSimulatingPhysics())
            return;

        ApplyHover(DeltaSeconds);
    }

    // ---- Hover logic ----------------------------------------

    private void ApplyHover(float DeltaSeconds)
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr)
            return;

        FTransform ActorTransform = OwnerActor.GetActorTransform();
        int pointCount = RayOffsets.Num();
        int groundedCount = 0;
        FVector normalSum = FVector(0.0, 0.0, 0.0);
        float groundHeightSum = 0.0;
        float forceSum = 0.0;

        // Visual bob offset
        float bobOffset = 0.0;
        if (bEnableBob)
        {
            bobOffset = Math::Sin(System::GameTimeInSeconds * BobFrequency * PI * 2.0 + BobPhase) * BobAmplitude;
        }
        float targetHeight = HoverHeight + bobOffset;

        for (int i = 0; i < pointCount; i++)
        {
            FVector worldOrigin = ActorTransform.TransformPosition(RayOffsets[i]);
            FVector traceEnd = worldOrigin - FVector(0.0, 0.0, RaycastDistance);

            FHitResult Hit;
            TArray<AActor> IgnoreActors;
            IgnoreActors.Add(OwnerActor);

            bool bHit = System::LineTraceSingle(
                worldOrigin,
                traceEnd,
                ETraceTypeQuery::Visibility,
                false,
                IgnoreActors,
                EDrawDebugTrace::None,
                Hit,
                true
            );

            if (bHit)
            {
                groundedCount++;
                float groundY = Hit.ImpactPoint.Z;
                FVector hitNormal = Hit.ImpactNormal;

                groundHeightSum += groundY;
                normalSum += hitNormal;

                float currentHeight = worldOrigin.Z - groundY;
                float heightError = targetHeight - currentHeight;

                float spring = heightError * SpringForce;
                FVector vel = PrimitiveRoot.GetPhysicsLinearVelocity();
                float damping = -vel.Z * Damping;

                forceSum += spring + damping;

                if (bShowDebug)
                {
                    // Green line for hit ray
                    System::DrawDebugLine(worldOrigin, Hit.ImpactPoint,
                        FLinearColor::Green, 0.0, 1.0);
                    // Small point at impact
                    System::DrawDebugPoint(Hit.ImpactPoint, 8.0,
                        FLinearColor::Green, 0.0);
                }
            }
            else if (bShowDebug)
            {
                // Red line for missed ray
                System::DrawDebugLine(worldOrigin, traceEnd,
                    FLinearColor::Red, 0.0, 1.0);
            }
        }

        bool bWasGrounded = bIsGrounded;
        bIsGrounded = groundedCount > 0;
        GroundedRayCount = groundedCount;

        if (bIsGrounded != bWasGrounded)
            OnGroundedChanged.Broadcast(bIsGrounded);

        if (bIsGrounded)
        {
            CurrentGroundHeight = groundHeightSum / groundedCount;
            TerrainNormal = (normalSum / groundedCount).GetSafeNormal();

            float avgForce = forceSum / groundedCount;
            PrimitiveRoot.AddForce(TerrainNormal * avgForce, NAME_None, true);

            if (bShowDebug)
            {
                FVector actorPos = OwnerActor.ActorLocation;
                // Terrain normal arrow (blue)
                FVector normalStart = FVector(actorPos.X, actorPos.Y, CurrentGroundHeight);
                System::DrawDebugArrow(normalStart, normalStart + TerrainNormal * 200.0, 15.0,
                    FLinearColor::Blue, 0.0, 2.0);

                // Hover height line (yellow) from ground to target height
                FVector hoverTarget = FVector(actorPos.X, actorPos.Y, CurrentGroundHeight + targetHeight);
                System::DrawDebugLine(normalStart, hoverTarget,
                    FLinearColor::Yellow, 0.0, 1.5);

                // State text
                FString hoverText = f"Hover: {groundedCount}/{pointCount} rays  Force:{avgForce:.0f}";
                System::DrawDebugString(actorPos + FVector(0.0, 0.0, 200.0), hoverText,
                    nullptr, FLinearColor::Green, 0.0);
            }
        }
        else
        {
            TerrainNormal = Math::VInterpTo(TerrainNormal, FVector(0.0, 0.0, 1.0), DeltaSeconds, 2.0);
            // Slow fall when no ground detected (30% anti-gravity)
            PrimitiveRoot.AddForce(FVector(0.0, 0.0, 980.0 * 0.3), NAME_None, true);

            if (bShowDebug)
            {
                FVector actorPos = OwnerActor.ActorLocation;
                FString hoverText = f"Hover: AIRBORNE (0/{pointCount} rays)";
                System::DrawDebugString(actorPos + FVector(0.0, 0.0, 200.0), hoverText,
                    nullptr, FLinearColor::Red, 0.0);
            }
        }
    }
}
