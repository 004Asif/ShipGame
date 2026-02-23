// ============================================================
//  NearMissComponent.as
//  Detects near-misses when the player barely avoids obstacles.
//  Uses a sphere overlap check each frame. When an obstacle is
//  inside the detection zone but the ship isn't dead, it counts
//  as a near-miss and awards bonus points via ScoreSubsystem.
// ============================================================

event void FOnNearMiss(AActor NearActor);

class UNearMissComponent : UActorComponent
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Configuration --------------------------------------

    UPROPERTY(EditAnywhere, Category = "NearMiss")
    float DetectionRadius = 250.0;

    UPROPERTY(EditAnywhere, Category = "NearMiss")
    float Cooldown = 0.5;

    UPROPERTY(EditAnywhere, Category = "NearMiss")
    int BonusPoints = 5;

    // ---- Events ---------------------------------------------

    UPROPERTY()
    FOnNearMiss OnNearMiss;

    // ---- Internal -------------------------------------------

    private float LastNearMissTime = -10.0;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        AActor OwnerActor = GetOwner();
        if (OwnerActor == nullptr)
            return;

        // Don't detect if ship is dying
        AShipActor Ship = Cast<AShipActor>(OwnerActor);
        if (Ship != nullptr && Ship.bIsDying)
            return;

        float currentTime = System::GameTimeInSeconds;
        if (currentTime - LastNearMissTime < Cooldown)
            return;

        CheckNearMisses(OwnerActor, currentTime);

        if (bShowDebug)
        {
            // Draw detection sphere (cyan wireframe)
            System::DrawDebugSphere(OwnerActor.ActorLocation, DetectionRadius, 16,
                FLinearColor(0.0, 1.0, 1.0, 0.4), 0.0, 0.5);
        }
    }

    // ---- Internal -------------------------------------------

    private void CheckNearMisses(AActor OwnerActor, float CurrentTime)
    {
        FVector origin = OwnerActor.GetActorLocation();

        // Sphere overlap for obstacles and enemies
        TArray<AActor> overlappingActors;
        TArray<AActor> ignoreActors;
        ignoreActors.Add(OwnerActor);

        bool bFound = System::SphereOverlapActors(
            origin,
            DetectionRadius,
            TArray<EObjectTypeQuery>(),
            AActor,
            ignoreActors,
            overlappingActors
        );

        if (!bFound)
            return;

        for (int i = 0; i < overlappingActors.Num(); i++)
        {
            AActor other = overlappingActors[i];
            if (other == nullptr)
                continue;

            bool bIsObstacle = other.ActorHasTag(n"Obstacle");
            bool bIsEnemy = other.ActorHasTag(n"EnemyShip");

            if (bIsObstacle || bIsEnemy)
            {
                LastNearMissTime = CurrentTime;

                // Award bonus
                UScoreSubsystem ScoreSub = UScoreSubsystem::Get();
                if (ScoreSub != nullptr)
                    ScoreSub.AddNearMissBonus(BonusPoints);

                OnNearMiss.Broadcast(other);

                if (bShowDebug)
                {
                    Print(f"[NearMiss] Near miss with {other.Name}! +{BonusPoints}pts");
                    // Flash sphere red on near miss
                    System::DrawDebugSphere(OwnerActor.ActorLocation, DetectionRadius, 16,
                        FLinearColor::Red, 0.3, 2.0);
                }
                return;
            }
        }
    }
}
