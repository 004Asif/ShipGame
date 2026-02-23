// ============================================================
//  AtmosphereSubsystem.as
//  Manages dynamic atmosphere transitions between biomes.
//  Controls fog, lighting, sky color, and ambient settings.
//  Mobile-friendly with smooth interpolation.
// ============================================================

event void FOnAtmosphereChanged(EBiomeType NewBiome);

class UAtmosphereSubsystem : UScriptWorldSubsystem
{
    // ---- Debug ------------------------------------------------

    UPROPERTY(EditAnywhere, Category = "Debug")
    bool bShowDebug = false;

    // ---- Events -----------------------------------------------

    UPROPERTY()
    FOnAtmosphereChanged OnAtmosphereChanged;

    // ---- References -------------------------------------------

    private AExponentialHeightFog FogActor;
    private ADirectionalLight SunActor;
    private ASkyLight SkyLightActor;

    // ---- Transition state -------------------------------------

    private FBiomeConfig CurrentBiomeConfig;
    private FBiomeConfig TargetBiomeConfig;
    private bool bIsTransitioning = false;
    private float TransitionProgress = 0.0;
    private float TransitionDuration = 3.0;

    // ---- Lifecycle --------------------------------------------

    UFUNCTION(BlueprintOverride)
    void Initialize()
    {
        FindAtmosphereActors();
    }

    // ---- Public API -------------------------------------------

    UFUNCTION()
    void SetBiomeAtmosphere(FBiomeConfig InBiomeConfig, bool bInstant = false)
    {
        if (bInstant)
        {
            CurrentBiomeConfig = InBiomeConfig;
            ApplyAtmosphereImmediate(InBiomeConfig);
            OnAtmosphereChanged.Broadcast(InBiomeConfig.BiomeType);
        }
        else
        {
            StartTransition(InBiomeConfig);
        }
    }

    UFUNCTION()
    void StartTransition(FBiomeConfig InTargetBiome)
    {
        TargetBiomeConfig = InTargetBiome;
        TransitionDuration = InTargetBiome.TransitionDuration;
        TransitionProgress = 0.0;
        bIsTransitioning = true;

        if (bShowDebug)
            Print(f"[Atmosphere] Starting transition to {InTargetBiome.BiomeName} over {TransitionDuration:.1f}s");
    }

    UFUNCTION()
    void UpdateTransition(float DeltaSeconds)
    {
        if (!bIsTransitioning)
            return;

        TransitionProgress += DeltaSeconds / TransitionDuration;
        
        if (TransitionProgress >= 1.0)
        {
            TransitionProgress = 1.0;
            bIsTransitioning = false;
            CurrentBiomeConfig = TargetBiomeConfig;
            OnAtmosphereChanged.Broadcast(CurrentBiomeConfig.BiomeType);
            
            if (bShowDebug)
                Print(f"[Atmosphere] Transition complete to {CurrentBiomeConfig.BiomeName}");
        }

        // Smooth interpolation using smoothstep
        float alpha = TransitionProgress * TransitionProgress * (3.0 - 2.0 * TransitionProgress);
        ApplyAtmosphereBlended(CurrentBiomeConfig, TargetBiomeConfig, alpha);
    }

    UFUNCTION(BlueprintPure)
    bool IsTransitioning() const
    {
        return bIsTransitioning;
    }

    UFUNCTION(BlueprintPure)
    float GetTransitionProgress() const
    {
        return TransitionProgress;
    }

    // ---- Internal ---------------------------------------------

    private void FindAtmosphereActors()
    {
        // Find exponential height fog
        TArray<AExponentialHeightFog> fogs;
        GetAllActorsOfClass(fogs);
        if (fogs.Num() > 0)
        {
            FogActor = fogs[0];
            if (bShowDebug)
                Print("[Atmosphere] Found ExponentialHeightFog");
        }
        else if (bShowDebug)
            Print("[Atmosphere] WARNING: No ExponentialHeightFog in level!");

        // Find directional light (sun)
        TArray<ADirectionalLight> lights;
        GetAllActorsOfClass(lights);
        if (lights.Num() > 0)
        {
            SunActor = lights[0];
            if (bShowDebug)
                Print("[Atmosphere] Found DirectionalLight");
        }
        else if (bShowDebug)
            Print("[Atmosphere] WARNING: No DirectionalLight in level!");

        // Find sky light
        TArray<ASkyLight> skyLights;
        GetAllActorsOfClass(skyLights);
        if (skyLights.Num() > 0)
        {
            SkyLightActor = skyLights[0];
            if (bShowDebug)
                Print("[Atmosphere] Found SkyLight");
        }
        else if (bShowDebug)
            Print("[Atmosphere] WARNING: No SkyLight in level!");
    }

    private void ApplyAtmosphereImmediate(FBiomeConfig Config)
    {
        // Apply fog settings
        if (FogActor != nullptr)
        {
            UExponentialHeightFogComponent FogComp = UExponentialHeightFogComponent::Get(FogActor);
            if (FogComp != nullptr)
            {
                FogComp.FogInscatteringColor = Config.FogColor;
                FogComp.FogDensity = Config.FogDensity;
                FogComp.StartDistance = Config.FogStartDistance;
                FogComp.DirectionalInscatteringExponent = Config.FogFalloff;
            }
        }

        // Apply sun settings
        if (SunActor != nullptr)
        {
            UDirectionalLightComponent LightComp = UDirectionalLightComponent::Get(SunActor);
            if (LightComp != nullptr)
            {
                LightComp.SetLightColor(Config.SunColor);
                LightComp.SetIntensity(Config.SunIntensity);
            }
            SunActor.SetActorRotation(Config.SunRotation);
        }

        // Apply sky light settings
        if (SkyLightActor != nullptr)
        {
            USkyLightComponent SkyComp = USkyLightComponent::Get(SkyLightActor);
            if (SkyComp != nullptr)
            {
                SkyComp.SetLightColor(Config.SkyColor);
                SkyComp.SetIntensity(Config.Brightness);
            }
        }
    }

    private void ApplyAtmosphereBlended(FBiomeConfig FromConfig, FBiomeConfig ToConfig, float Alpha)
    {
        // Blend fog settings
        if (FogActor != nullptr)
        {
            UExponentialHeightFogComponent FogComp = UExponentialHeightFogComponent::Get(FogActor);
            if (FogComp != nullptr)
            {
                FogComp.FogInscatteringColor = LerpColor(FromConfig.FogColor, ToConfig.FogColor, Alpha);
                FogComp.FogDensity = Math::Lerp(FromConfig.FogDensity, ToConfig.FogDensity, Alpha);
                FogComp.StartDistance = Math::Lerp(FromConfig.FogStartDistance, ToConfig.FogStartDistance, Alpha);
                FogComp.DirectionalInscatteringExponent = Math::Lerp(FromConfig.FogFalloff, ToConfig.FogFalloff, Alpha);
            }
        }

        // Blend sun settings
        if (SunActor != nullptr)
        {
            UDirectionalLightComponent LightComp = UDirectionalLightComponent::Get(SunActor);
            if (LightComp != nullptr)
            {
                LightComp.SetLightColor(LerpColor(FromConfig.SunColor, ToConfig.SunColor, Alpha));
                LightComp.SetIntensity(Math::Lerp(FromConfig.SunIntensity, ToConfig.SunIntensity, Alpha));
            }
            
            FRotator blendedRot = LerpRotator(FromConfig.SunRotation, ToConfig.SunRotation, Alpha);
            SunActor.SetActorRotation(blendedRot);
        }

        // Blend sky light settings
        if (SkyLightActor != nullptr)
        {
            USkyLightComponent SkyComp = USkyLightComponent::Get(SkyLightActor);
            if (SkyComp != nullptr)
            {
                SkyComp.SetLightColor(LerpColor(FromConfig.SkyColor, ToConfig.SkyColor, Alpha));
                SkyComp.SetIntensity(Math::Lerp(FromConfig.Brightness, ToConfig.Brightness, Alpha));
            }
        }
    }

    private FLinearColor LerpColor(FLinearColor A, FLinearColor B, float Alpha)
    {
        return FLinearColor(
            Math::Lerp(A.R, B.R, Alpha),
            Math::Lerp(A.G, B.G, Alpha),
            Math::Lerp(A.B, B.B, Alpha),
            Math::Lerp(A.A, B.A, Alpha)
        );
    }

    private FRotator LerpRotator(FRotator A, FRotator B, float Alpha)
    {
        return FRotator(
            Math::Lerp(A.Pitch, B.Pitch, Alpha),
            Math::Lerp(A.Yaw, B.Yaw, Alpha),
            Math::Lerp(A.Roll, B.Roll, Alpha)
        );
    }
}
