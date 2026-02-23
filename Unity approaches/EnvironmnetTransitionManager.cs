using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Manages procedural environment transitions as the player travels.
/// Designers configure biomes via EnvironmentBiomeSO ScriptableObjects and
/// assign them in the Inspector sorted by startDistance.
/// Handles smooth blending of skybox, fog, ambient light, sun, and ground material.
/// Also spawns/despawns decorative side props per biome.
/// </summary>
public class EnvironmentTransitionManager : MonoBehaviour
{
    #region Singleton
    public static EnvironmentTransitionManager Instance { get; private set; }
    #endregion

    #region Serialized Fields
    [Header("Biome Configuration")]
    [Tooltip("Biomes sorted by startDistance (ascending). First biome is the initial environment.")]
    [SerializeField] private List<EnvironmentBiomeSO> m_Biomes = new List<EnvironmentBiomeSO>();

    [Header("Directional Light")]
    [Tooltip("The scene's main directional light — rotated and recolored per biome")]
    [SerializeField] private Light m_DirectionalLight;

    [Header("Side Prop Settings")]
    [Tooltip("How far ahead of the player to spawn side props")]
    [SerializeField] private float m_PropSpawnAhead = 80f;
    [Tooltip("How far behind the player to despawn side props")]
    [SerializeField] private float m_PropDespawnBehind = 30f;
    [Tooltip("Z spacing between prop spawn attempts")]
    [SerializeField] private float m_PropSpacing = 10f;
    #endregion

    #region Public Properties
    /// <summary>Current active biome index.</summary>
    public int CurrentBiomeIndex => m_CurrentBiomeIndex;
    /// <summary>Current active biome SO (null if no biomes configured).</summary>
    public EnvironmentBiomeSO CurrentBiome => m_CurrentBiomeIndex >= 0 && m_CurrentBiomeIndex < m_Biomes.Count
        ? m_Biomes[m_CurrentBiomeIndex] : null;
    /// <summary>Ground material of the current biome (for LevelGenerator to read).</summary>
    public Material CurrentGroundMaterial => m_CurrentGroundMat;
    /// <summary>Terrain amplitude of the current biome.</summary>
    public float CurrentTerrainAmplitude => CurrentBiome != null ? CurrentBiome.terrainAmplitude : 1.5f;
    /// <summary>Terrain frequency of the current biome.</summary>
    public float CurrentTerrainFrequency => CurrentBiome != null ? CurrentBiome.terrainFrequency : 0.08f;
    /// <summary>Flatness bias of the current biome (0 = none, 1 = all flat).</summary>
    public float CurrentFlatness => CurrentBiome != null ? CurrentBiome.flatness : 0.3f;
    /// <summary>Ridgedness of the current biome (0 = none, 1 = all ridges).</summary>
    public float CurrentRidgedness => CurrentBiome != null ? CurrentBiome.ridgedness : 0.2f;
    /// <summary>Domain warp strength of the current biome.</summary>
    public float CurrentDomainWarpStrength => CurrentBiome != null ? CurrentBiome.domainWarpStrength : 0.35f;
    #endregion

    #region Private Fields
    private int m_CurrentBiomeIndex = -1;
    private Material m_CurrentSkyboxMat;
    private Material m_CurrentGroundMat;
    private Coroutine m_TransitionCoroutine;

    // Side props
    private float m_NextPropZ = 0f;
    private float m_MapHalfWidth = 5f;
    private List<GameObject> m_ActiveProps = new List<GameObject>();
    private Transform m_PlayerTransform;
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }

    private void Start()
    {
        if (m_Biomes.Count > 0)
        {
            ApplyBiomeImmediate(m_Biomes[0]);
            m_CurrentBiomeIndex = 0;
        }
    }

    private void Update()
    {
        if (m_PlayerTransform == null) return;

        SpawnSideProps();
        DespawnSideProps();
    }
    #endregion

    #region Public Methods
    /// <summary>
    /// Called by ShipController.UpdateEnvironment() each frame with the player's total distance.
    /// Checks if the next biome threshold has been reached and starts a transition.
    /// </summary>
    public void CheckForTransition(float _playerDistance)
    {
        int nextIndex = m_CurrentBiomeIndex + 1;
        if (nextIndex >= m_Biomes.Count) return;

        if (_playerDistance >= m_Biomes[nextIndex].startDistance)
        {
            TransitionToBiome(nextIndex);
        }
    }

    /// <summary>
    /// Sets the player transform for prop spawning. Called by LevelGenerator or GameFlowController.
    /// </summary>
    public void SetPlayer(Transform _player, float _mapHalfWidth)
    {
        m_PlayerTransform = _player;
        m_MapHalfWidth = _mapHalfWidth;
        m_NextPropZ = _player != null ? _player.position.z : 0f;
    }

    /// <summary>
    /// Resets the environment to the first biome. Called when returning to menu.
    /// </summary>
    public void ResetEnvironment()
    {
        if (m_TransitionCoroutine != null)
        {
            StopCoroutine(m_TransitionCoroutine);
            m_TransitionCoroutine = null;
        }

        // Despawn all props
        foreach (GameObject prop in m_ActiveProps)
        {
            if (prop != null) Destroy(prop);
        }
        m_ActiveProps.Clear();
        m_NextPropZ = 0f;
        m_PlayerTransform = null;

        if (m_Biomes.Count > 0)
        {
            ApplyBiomeImmediate(m_Biomes[0]);
            m_CurrentBiomeIndex = 0;
        }
    }
    #endregion

    #region Biome Transitions
    private void TransitionToBiome(int _index)
    {
        if (_index < 0 || _index >= m_Biomes.Count) return;
        if (_index == m_CurrentBiomeIndex) return;

        if (m_TransitionCoroutine != null)
        {
            StopCoroutine(m_TransitionCoroutine);
        }

        m_TransitionCoroutine = StartCoroutine(BiomeTransitionCoroutine(m_Biomes[_index]));
        m_CurrentBiomeIndex = _index;
    }

    /// <summary>
    /// Instantly applies a biome without blending. Used for initial setup and reset.
    /// </summary>
    private void ApplyBiomeImmediate(EnvironmentBiomeSO _biome)
    {
        if (_biome == null) return;

        // Skybox
        if (_biome.skyboxMaterial != null)
        {
            m_CurrentSkyboxMat = new Material(_biome.skyboxMaterial);
            RenderSettings.skybox = m_CurrentSkyboxMat;
        }

        // Fog
        RenderSettings.fog = true;
        RenderSettings.fogColor = _biome.fogColor;
        RenderSettings.fogDensity = _biome.fogDensity;

        // Ambient
        RenderSettings.ambientLight = _biome.ambientColor;

        // Ground material cache
        if (_biome.groundMaterial != null)
        {
            m_CurrentGroundMat = _biome.groundMaterial;
        }

        // Directional light
        ApplyLightSettings(_biome);
    }

    private IEnumerator BiomeTransitionCoroutine(EnvironmentBiomeSO _targetBiome)
    {
        if (_targetBiome == null) yield break;

        float duration = _targetBiome.transitionDuration;
        float elapsed = 0f;

        // Snapshot current state
        Color startFogColor = RenderSettings.fogColor;
        float startFogDensity = RenderSettings.fogDensity;
        Color startAmbient = RenderSettings.ambientLight;

        Material startSkybox = m_CurrentSkyboxMat;
        Material targetSkybox = _targetBiome.skyboxMaterial;

        // Light snapshots
        Color startLightColor = m_DirectionalLight != null ? m_DirectionalLight.color : Color.white;
        float startLightIntensity = m_DirectionalLight != null ? m_DirectionalLight.intensity : 1f;
        Quaternion startLightRot = m_DirectionalLight != null ? m_DirectionalLight.transform.rotation : Quaternion.identity;
        Quaternion targetLightRot = Quaternion.Euler(_targetBiome.sunRotation);

        // Create transition skybox material
        Material transitionSkybox = null;
        if (startSkybox != null && targetSkybox != null)
        {
            transitionSkybox = new Material(startSkybox);
            RenderSettings.skybox = transitionSkybox;
        }

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / duration);
            float smoothT = t * t * (3f - 2f * t); // Smooth ease-in-out

            // Fog
            RenderSettings.fogColor = Color.Lerp(startFogColor, _targetBiome.fogColor, smoothT);
            RenderSettings.fogDensity = Mathf.Lerp(startFogDensity, _targetBiome.fogDensity, smoothT);

            // Ambient
            RenderSettings.ambientLight = Color.Lerp(startAmbient, _targetBiome.ambientColor, smoothT);

            // Skybox
            if (transitionSkybox != null)
            {
                transitionSkybox.Lerp(startSkybox, targetSkybox, smoothT);
            }

            // Directional light
            if (m_DirectionalLight != null)
            {
                m_DirectionalLight.color = Color.Lerp(startLightColor, _targetBiome.sunColor, smoothT);
                m_DirectionalLight.intensity = Mathf.Lerp(startLightIntensity, _targetBiome.sunIntensity, smoothT);
                m_DirectionalLight.transform.rotation = Quaternion.Slerp(startLightRot, targetLightRot, smoothT);
            }

            yield return null;
        }

        // Finalize
        ApplyBiomeImmediate(_targetBiome);
        m_TransitionCoroutine = null;
    }

    private void ApplyLightSettings(EnvironmentBiomeSO _biome)
    {
        if (m_DirectionalLight == null || _biome == null) return;
        m_DirectionalLight.color = _biome.sunColor;
        m_DirectionalLight.intensity = _biome.sunIntensity;
        m_DirectionalLight.transform.rotation = Quaternion.Euler(_biome.sunRotation);
    }
    #endregion

    #region Side Props
    private void SpawnSideProps()
    {
        if (m_PlayerTransform == null) return;

        EnvironmentBiomeSO biome = CurrentBiome;
        if (biome == null || biome.sideProps == null || biome.sideProps.Length == 0) return;

        float targetZ = m_PlayerTransform.position.z + m_PropSpawnAhead;

        while (m_NextPropZ < targetZ)
        {
            foreach (BiomeProp prop in biome.sideProps)
            {
                if (prop.prefab == null) continue;
                if (Random.value > prop.spawnChance) continue;

                // Spawn on both sides of the track
                for (int side = -1; side <= 1; side += 2)
                {
                    if (Random.value > 0.5f) continue; // 50% chance per side

                    float offsetX = Random.Range(prop.minOffsetX, prop.maxOffsetX);
                    float x = side * (m_MapHalfWidth + offsetX);
                    float y = Random.Range(prop.minOffsetY, prop.maxOffsetY);
                    float z = m_NextPropZ + Random.Range(-m_PropSpacing * 0.3f, m_PropSpacing * 0.3f);

                    Vector3 pos = new Vector3(x, y, z);
                    Quaternion rot = prop.randomYRotation
                        ? Quaternion.Euler(0f, Random.Range(0f, 360f), 0f)
                        : Quaternion.identity;

                    GameObject instance = Instantiate(prop.prefab, pos, rot, transform);
                    float scale = Random.Range(prop.minScale, prop.maxScale);
                    instance.transform.localScale = Vector3.one * scale;

                    m_ActiveProps.Add(instance);
                }
            }

            m_NextPropZ += m_PropSpacing;
        }
    }

    private void DespawnSideProps()
    {
        if (m_PlayerTransform == null) return;

        float threshold = m_PlayerTransform.position.z - m_PropDespawnBehind;

        m_ActiveProps.RemoveAll(prop =>
        {
            if (prop == null) return true;
            if (prop.transform.position.z < threshold)
            {
                Destroy(prop);
                return true;
            }
            return false;
        });
    }
    #endregion
}
