// ============================================================
//  ShipGameMode.as
//  The main game mode. Set this as the GameMode Override in
//  your level's World Settings.
//
//  Responsibilities:
//   1. Spawns the ship pawn at a spawn point
//   2. Sets up the chase camera
//   3. Finds the TerrainManager in the level
//   4. Wires everything together via GameFlowSubsystem
//   5. Auto-starts the game for quick testing
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

    // Menu widgets (assign in BP defaults)
    UPROPERTY(EditAnywhere, Category = "ShipGame|Menu")
    TSubclassOf<UUserWidget> MainMenuWidgetClass;

    UPROPERTY(EditAnywhere, Category = "ShipGame|Menu")
    TSubclassOf<UUserWidget> PauseMenuWidgetClass;

    // HUD widget (assign in BP defaults)
    UPROPERTY(EditAnywhere, Category = "ShipGame|HUD")
    TSubclassOf<UUserWidget> GameHUDWidgetClass;

    // ---- Internal -------------------------------------------

    private AActor MenuCameraActor;
    private APlayerController CachedPC;
    private UUserWidget SpawnedMainMenuWidget;
    private UUserWidget SpawnedPauseMenuWidget;
    private UUserWidget SpawnedGameHUD;
    private UGameFlowSubsystem GameFlowRef;

    // ---- Lifecycle ------------------------------------------

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
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

        // Get GameFlow subsystem
        GameFlowRef = UGameFlowSubsystem::Get();

        if (bShowDebug)
        {
            Print(f"[GameMode] BeginPlay. ShipClass={ShipClass != nullptr} AutoStart={bAutoStartGame}");
            if (ShipClass == nullptr)
                Print("[GameMode] WARNING: ShipClass is null! Assign in BP defaults.", Duration = 10.0);
        }

        // Create main menu widget
        CreateMainMenu();

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

        // Hide main menu
        if (SpawnedMainMenuWidget != nullptr)
            SpawnedMainMenuWidget.SetVisibility(ESlateVisibility::Collapsed);

        // Create pause menu for later
        CreatePauseMenu();

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
            SpawnedPauseMenuWidget.SetVisibility(ESlateVisibility::Visible);
            if (GameFlowRef != nullptr)
                GameFlowRef.TogglePause(); // Pause
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

        UGameFlowSubsystem GameFlow = UGameFlowSubsystem::Get();
        if (GameFlow != nullptr)
            GameFlow.GoToMenu();

        // Hide HUD and show main menu
        HideGameHUD();
        if (SpawnedMainMenuWidget != nullptr)
            SpawnedMainMenuWidget.SetVisibility(ESlateVisibility::Visible);

        SpawnedShip = nullptr;

        // Re-create menu camera
        if (CachedPC != nullptr)
            SetupMenuCamera(CachedPC);
    }

    // ---- Timer callbacks ------------------------------------

    UFUNCTION()
    private void AutoStart()
    {
        StartNewGame();
    }

    // ---- Internal -------------------------------------------

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
        if (GameHUDWidgetClass == nullptr || CachedPC == nullptr)
            return;

        UUserWidget Widget = WidgetBlueprint::CreateWidget(GameHUDWidgetClass, CachedPC);
        if (Widget != nullptr)
        {
            Widget.AddToViewport(50);  // Below menus (100, 200)
            Widget.SetVisibility(ESlateVisibility::Collapsed);  // Hidden until game starts
            SpawnedGameHUD = Widget;
            if (bShowDebug)
                Print("[GameMode] Game HUD created");
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
