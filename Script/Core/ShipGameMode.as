// ============================================================
//  ShipGameMode.as
//  The main game mode. Set this as the GameMode Override in
//  your level's World Settings.
//
//  Responsibilities:
//   1. Registers default ship(s) in ShipRegistrySubsystem
//   2. Spawns the ship pawn with computed physics from loadout
//   3. Sets up the chase camera
//   4. Finds the TerrainManager in the level
//   5. Wires all systems: GameFlow, Score, Progress, Menus
//   6. Saves progress on game over
//
//  To use: Create a Blueprint child (BP_ShipGameMode) and
//  assign ShipClass in its defaults.
// ============================================================

class AShipGameMode : AGameModeBase
{
    // ---- Configuration (assign in BP defaults) ---------------

    UPROPERTY(EditAnywhere, Category = "ShipGame|Setup")
    TSubclassOf<AShipActor> ShipClass;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Setup")
    FVector ShipSpawnLocation = FVector(2000.0, 0.0, 1000.0);

    UPROPERTY(EditAnywhere, Category = "ShipGame|Debug")
    bool bAutoStartGame = false;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Debug")
    bool bShowDebug = false;

    // ---- Menu camera (before ship is spawned) ----------------

    UPROPERTY(EditAnywhere, Category = "ShipGame|Camera")
    FVector MenuCameraLocation = FVector(-500.0, 0.0, 800.0);

    UPROPERTY(EditAnywhere, Category = "ShipGame|Camera")
    FRotator MenuCameraRotation = FRotator(-20.0, 0.0, 0.0);

    // ---- References ------------------------------------------

    UPROPERTY(BlueprintReadOnly, Category = "ShipGame")
    AShipActor SpawnedShip;

    UPROPERTY(BlueprintReadOnly, Category = "ShipGame")
    ATerrainManager FoundTerrainManager;

    // Widget classes (assign in BP defaults)
    UPROPERTY(EditAnywhere, Category = "ShipGame|Widgets")
    TSubclassOf<UUserWidget> MainMenuWidgetClass;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Widgets")
    TSubclassOf<UUserWidget> PauseMenuWidgetClass;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Widgets")
    TSubclassOf<UUserWidget> GameHUDWidgetClass;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Widgets")
    TSubclassOf<UUserWidget> HangarWidgetClass;

    // ---- Internal -------------------------------------------

    private AActor MenuCameraActor;
    private APlayerController CachedPC;
    private UUserWidget SpawnedMainMenuWidget;
    private UUserWidget SpawnedPauseMenuWidget;
    private UUserWidget SpawnedGameHUD;
    private UUserWidget SpawnedHangarWidget;
    private UGameFlowSubsystem GameFlowRef;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Register default ship(s) in the registry
        RegisterDefaultShips();

        // Auto-find the TerrainManager placed in the level
        TArray<ATerrainManager> terrainManagers;
        GetAllActorsOfClass(terrainManagers);
        if (terrainManagers.Num() > 0)
        {
            FoundTerrainManager = terrainManagers[0];
            if (bShowDebug)
                Print(f"[GameMode] Found TerrainManager at {FoundTerrainManager.ActorLocation}");
        }
        else
            Print("ShipGameMode: No ATerrainManager in level! Place one.", Duration = 10.0);

        // Get GameFlow subsystem and listen for phase changes
        GameFlowRef = UGameFlowSubsystem::Get();
        if (GameFlowRef != nullptr)
            GameFlowRef.OnPhaseChanged.AddUFunction(this, n"OnPhaseChanged");

        if (bShowDebug)
        {
            Print(f"[GameMode] BeginPlay. ShipClass={ShipClass != nullptr} AutoStart={bAutoStartGame}");
            if (ShipClass == nullptr)
                Print("[GameMode] WARNING: ShipClass is null! Assign in BP defaults.", Duration = 10.0);
        }

        // Create all widgets
        CreateMainMenu();
        CreatePauseMenu();
        CreateHangarWidget();

        if (bAutoStartGame)
            System::SetTimer(this, n"AutoStart", 0.5, false);
    }

    UFUNCTION(BlueprintOverride)
    void OnPostLogin(APlayerController NewPlayer)
    {
        CachedPC = NewPlayer;
        if (bShowDebug)
            Print(f"[GameMode] OnPostLogin: {NewPlayer.Name}");
        SetupMenuCamera(NewPlayer);
    }

    // ---- Menu Management ------------------------------------

    private void CreateMainMenu()
    {
        if (MainMenuWidgetClass == nullptr || CachedPC == nullptr)
            return;

        UUserWidget Widget = WidgetBlueprint::CreateWidget(MainMenuWidgetClass, CachedPC);
        if (Widget != nullptr)
        {
            Widget.AddToViewport(100);
            SpawnedMainMenuWidget = Widget;
            if (bShowDebug)
                Print("[GameMode] Main menu created");
        }
    }

    private void CreatePauseMenu()
    {
        if (PauseMenuWidgetClass == nullptr || CachedPC == nullptr)
            return;

        UUserWidget Widget = WidgetBlueprint::CreateWidget(PauseMenuWidgetClass, CachedPC);
        if (Widget != nullptr)
        {
            Widget.AddToViewport(200);
            Widget.SetVisibility(ESlateVisibility::Collapsed);
            SpawnedPauseMenuWidget = Widget;
            if (bShowDebug)
                Print("[GameMode] Pause menu created");
        }
    }

    UFUNCTION()
    void OnMainMenuPlayClicked()
    {
        if (bShowDebug)
            Print("[GameMode] OnMainMenuPlayClicked");

        // Sync selected ship from main menu
        UMainMenuWidget MainMenu = Cast<UMainMenuWidget>(SpawnedMainMenuWidget);
        if (MainMenu != nullptr)
        {
            UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
            UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
            if (Registry != nullptr && Progress != nullptr)
            {
                FShipDefinition SelectedDef = Registry.GetShipByIndex(MainMenu.CurrentShipIndex);
                Progress.SelectShip(SelectedDef.ShipId);
            }
        }

        // Hide main menu
        if (SpawnedMainMenuWidget != nullptr)
            SpawnedMainMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        // Create HUD
        CreateGameHUD();

        // Start the game
        StartNewGame();
    }

    UFUNCTION()
    void OnPauseMenuResumeClicked()
    {
        if (bShowDebug)
            Print("[GameMode] OnPauseMenuResumeClicked");

        if (SpawnedPauseMenuWidget != nullptr)
            SpawnedPauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        if (GameFlowRef != nullptr)
            GameFlowRef.TogglePause();
    }

    UFUNCTION()
    void OnPauseMenuQuitClicked()
    {
        if (bShowDebug)
            Print("[GameMode] OnPauseMenuQuitClicked");

        ReturnToMenu();
    }

    UFUNCTION()
    void TogglePauseMenu()
    {
        if (SpawnedPauseMenuWidget == nullptr)
            return;

        bool bIsVisible = SpawnedPauseMenuWidget.GetVisibility() == ESlateVisibility::Visible;
        
        if (bIsVisible)
        {
            SpawnedPauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);
            if (GameFlowRef != nullptr)
                GameFlowRef.TogglePause(); // Unpause
        }
        else
        {
            // Refresh pause menu stats before showing
            UPauseMenuWidget PauseMenu = Cast<UPauseMenuWidget>(SpawnedPauseMenuWidget);
            if (PauseMenu != nullptr)
                PauseMenu.RefreshDisplay();

            SpawnedPauseMenuWidget.SetVisibility(ESlateVisibility::Visible);
            if (GameFlowRef != nullptr)
                GameFlowRef.TogglePause(); // Pause
        }
    }

    // Open/close hangar from main menu
    UFUNCTION()
    void ShowHangar()
    {
        if (SpawnedHangarWidget != nullptr)
        {
            UHangarWidget Hangar = Cast<UHangarWidget>(SpawnedHangarWidget);
            if (Hangar != nullptr)
                Hangar.RefreshAll();
            SpawnedHangarWidget.SetVisibility(ESlateVisibility::Visible);
        }
    }

    UFUNCTION()
    void HideHangar()
    {
        if (SpawnedHangarWidget != nullptr)
            SpawnedHangarWidget.SetVisibility(ESlateVisibility::Collapsed);

        // Refresh main menu to show updated stats after upgrades
        UMainMenuWidget MainMenu = Cast<UMainMenuWidget>(SpawnedMainMenuWidget);
        if (MainMenu != nullptr)
        {
            MainMenu.RefreshShipDisplay();
            MainMenu.RefreshPlayerStats();
        }
    }

    // ---- Public API -----------------------------------------

    UFUNCTION()
    void StartNewGame()
    {
        if (ShipClass == nullptr)
        {
            Print("ShipGameMode: ShipClass not set!", Duration = 10.0);
            return;
        }

        if (CachedPC == nullptr)
        {
            Print("ShipGameMode: No PlayerController yet!", Duration = 10.0);
            return;
        }

        FRotator spawnRot = FRotator(0.0, 0.0, 0.0);
        SpawnedShip = Cast<AShipActor>(SpawnActor(ShipClass, ShipSpawnLocation, spawnRot));

        if (SpawnedShip == nullptr)
        {
            Print("ShipGameMode: Failed to spawn ship!", Duration = 10.0);
            return;
        }

        // Apply computed physics from registry + loadout
        ApplyLoadoutToShip(SpawnedShip);

        // Possess the ship — player auto-views through the pawn's camera
        if (bShowDebug)
            Print(f"[GameMode] Ship spawned at {ShipSpawnLocation}. Possessing...");
        CachedPC.Possess(SpawnedShip);

        // Start intro camera swoop on the ship's CameraFollowComponent
        UCameraFollowComponent CamFollow = UCameraFollowComponent::Get(SpawnedShip);
        if (CamFollow != nullptr)
            CamFollow.StartIntroSwoop(2.0);

        // Wire terrain tracking to ship
        if (FoundTerrainManager != nullptr)
            FoundTerrainManager.SetTrackedActor(SpawnedShip);

        // Reset score
        UScoreSubsystem ScoreSub = UScoreSubsystem::Get();
        if (ScoreSub != nullptr)
            ScoreSub.ResetScore();

        // Start game flow
        UGameFlowSubsystem GameFlow = UGameFlowSubsystem::Get();
        if (GameFlow != nullptr)
            GameFlow.StartGame(SpawnedShip, FoundTerrainManager);

        // Show HUD
        ShowGameHUD();

        // Destroy the menu camera — no longer needed
        if (MenuCameraActor != nullptr)
        {
            MenuCameraActor.DestroyActor();
            MenuCameraActor = nullptr;
        }

        Print(f"ShipGameMode: Game started! Ship at {ShipSpawnLocation}");

        if (bShowDebug)
        {
            Print(f"[GameMode] CamFollow={UCameraFollowComponent::Get(SpawnedShip) != nullptr}");
            Print(f"[GameMode] TerrainMgr={FoundTerrainManager != nullptr} Score={UScoreSubsystem::Get() != nullptr}");
        }
    }

    UFUNCTION()
    void ReturnToMenu()
    {
        if (bShowDebug)
            Print("[GameMode] ReturnToMenu");

        // Save run results before cleaning up
        SaveRunResults();

        UGameFlowSubsystem GameFlow = UGameFlowSubsystem::Get();
        if (GameFlow != nullptr)
            GameFlow.GoToMenu();

        // Hide HUD and pause menu
        HideGameHUD();
        if (SpawnedPauseMenuWidget != nullptr)
            SpawnedPauseMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        // Show and refresh main menu
        if (SpawnedMainMenuWidget != nullptr)
        {
            SpawnedMainMenuWidget.SetVisibility(ESlateVisibility::Visible);
            UMainMenuWidget MainMenu = Cast<UMainMenuWidget>(SpawnedMainMenuWidget);
            if (MainMenu != nullptr)
            {
                MainMenu.RefreshShipDisplay();
                MainMenu.RefreshPlayerStats();
                MainMenu.HideGiveUpOption();
            }
        }

        SpawnedShip = nullptr;

        // Re-create menu camera
        if (CachedPC != nullptr)
            SetupMenuCamera(CachedPC);
    }

    // ---- Phase change listener --------------------------------

    UFUNCTION()
    private void OnPhaseChanged(EGamePhase NewPhase, EGamePhase OldPhase)
    {
        if (bShowDebug)
            Print(f"[GameMode] Phase: {OldPhase} -> {NewPhase}");

        if (NewPhase == EGamePhase::GameOver)
            HandleGameOver();
    }

    private void HandleGameOver()
    {
        // Save run results
        SaveRunResults();

        // Auto-return to menu after delay
        System::SetTimer(this, n"DelayedReturnToMenu", 2.0, false);
    }

    UFUNCTION()
    private void DelayedReturnToMenu()
    {
        ReturnToMenu();
    }

    // ---- Timer callbacks ------------------------------------

    UFUNCTION()
    private void AutoStart()
    {
        StartNewGame();
    }

    // ---- Internal -------------------------------------------

    private void RegisterDefaultShips()
    {
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        if (Registry == nullptr || Registry.GetShipCount() > 0)
            return;

        // Register starter ship
        FShipDefinition starter;
        starter.ShipId = n"vanguard";
        starter.DisplayName = "Vanguard";
        starter.ShipClassName = "Interceptor";
        starter.Tier = 1;
        starter.UnlockCost = 0;
        starter.ShipBlueprint = ShipClass;
        starter.Description = "A balanced starter ship. Reliable in all conditions.";
        starter.BaseStats.SpeedRating = 55.0;
        starter.BaseStats.ShieldRating = 45.0;
        starter.BaseStats.ThrustRating = 50.0;
        starter.BaseStats.AgilityRating = 50.0;
        starter.BaseStats.BoostRating = 50.0;

        // Add some starter upgrades
        FUpgradeDefinition eng1;
        eng1.UpgradeId = n"ion_thrusters";
        eng1.DisplayName = "Ion Thrusters";
        eng1.Slot = EUpgradeSlot::Engines;
        eng1.Tier = 2;
        eng1.ArtifactCost = 300;
        eng1.SpeedModifier = 10.0;
        eng1.ThrustModifier = 8.0;
        eng1.ForwardSpeedBonus = 300.0;
        starter.EngineUpgrades.Add(eng1);

        FUpgradeDefinition wing1;
        wing1.UpgradeId = n"swept_wings";
        wing1.DisplayName = "Swept Wings";
        wing1.Slot = EUpgradeSlot::Wings;
        wing1.Tier = 2;
        wing1.ArtifactCost = 250;
        wing1.AgilityModifier = 12.0;
        wing1.LateralThrustBonus = 300.0;
        starter.WingUpgrades.Add(wing1);

        FUpgradeDefinition base1;
        base1.UpgradeId = n"reinforced_hull";
        base1.DisplayName = "Reinforced Hull";
        base1.Slot = EUpgradeSlot::Base;
        base1.Tier = 2;
        base1.ArtifactCost = 200;
        base1.ShieldModifier = 15.0;
        base1.ShieldDurationBonus = 2.0;
        starter.BaseUpgrades.Add(base1);

        FUpgradeDefinition arm1;
        arm1.UpgradeId = n"pulse_emitter";
        arm1.DisplayName = "Pulse Emitter";
        arm1.Slot = EUpgradeSlot::Armaments;
        arm1.Tier = 2;
        arm1.ArtifactCost = 350;
        arm1.BoostModifier = 10.0;
        arm1.BoostMultiplierBonus = 0.3;
        arm1.BoostDurationBonus = 1.0;
        starter.ArmamentUpgrades.Add(arm1);

        Registry.RegisterShip(starter);

        if (bShowDebug)
            Print(f"[GameMode] Registered default ship: {starter.DisplayName}");
    }

    private void ApplyLoadoutToShip(AShipActor Ship)
    {
        UShipRegistrySubsystem Registry = UShipRegistrySubsystem::Get();
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        if (Registry == nullptr || Progress == nullptr || Ship == nullptr)
            return;

        FShipLoadout loadout = Progress.GetSelectedLoadout();
        FShipData finalPhysics = Registry.ComputeFinalPhysics(Progress.SelectedShipId, loadout);

        // Override the ship's config and re-apply to components
        Ship.ShipConfig = finalPhysics;
        Ship.ApplyShipConfig();

        if (bShowDebug)
            Print(f"[GameMode] Applied loadout for {Progress.SelectedShipId}. MaxSpeed={finalPhysics.MaxForwardSpeed:.0f}");
    }

    private void SaveRunResults()
    {
        UPlayerProgressSubsystem Progress = UPlayerProgressSubsystem::Get();
        UScoreSubsystem ScoreSub = UScoreSubsystem::Get();
        if (Progress == nullptr || ScoreSub == nullptr)
            return;

        float distance = 0.0;
        if (SpawnedShip != nullptr)
            distance = SpawnedShip.DistanceTraveled;

        int artifactsFromRun = ScoreSub.ArtifactsCollected;
        Progress.RecordRunEnd(distance, artifactsFromRun);

        if (bShowDebug)
            Print(f"[GameMode] Run saved. Dist={distance:.0f} Artifacts={artifactsFromRun}");
    }

    private void SetupMenuCamera(APlayerController PC)
    {
        MenuCameraActor = SpawnActor(AActor, MenuCameraLocation, MenuCameraRotation);
        if (MenuCameraActor == nullptr)
            return;

        UCameraComponent::Create(MenuCameraActor, n"MenuCamera");
        PC.SetViewTargetWithBlend(MenuCameraActor, 0.5);
    }

    private void CreateGameHUD()
    {
        if (SpawnedGameHUD != nullptr)
            return; // Already created

        if (GameHUDWidgetClass == nullptr || CachedPC == nullptr)
            return;

        UUserWidget Widget = WidgetBlueprint::CreateWidget(GameHUDWidgetClass, CachedPC);
        if (Widget != nullptr)
        {
            Widget.AddToViewport(50);
            Widget.SetVisibility(ESlateVisibility::Collapsed);
            SpawnedGameHUD = Widget;
            if (bShowDebug)
                Print("[GameMode] Game HUD created");
        }
    }

    private void CreateHangarWidget()
    {
        if (HangarWidgetClass == nullptr || CachedPC == nullptr)
            return;

        UUserWidget Widget = WidgetBlueprint::CreateWidget(HangarWidgetClass, CachedPC);
        if (Widget != nullptr)
        {
            Widget.AddToViewport(150);
            Widget.SetVisibility(ESlateVisibility::Collapsed);
            SpawnedHangarWidget = Widget;
            if (bShowDebug)
                Print("[GameMode] Hangar widget created");
        }
    }

    private void ShowGameHUD()
    {
        if (SpawnedGameHUD != nullptr)
            SpawnedGameHUD.SetVisibility(ESlateVisibility::Visible);
    }

    private void HideGameHUD()
    {
        if (SpawnedGameHUD != nullptr)
            SpawnedGameHUD.SetVisibility(ESlateVisibility::Collapsed);
    }
}
