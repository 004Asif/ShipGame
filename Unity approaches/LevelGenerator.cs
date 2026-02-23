using UnityEngine;
using System.Collections.Generic;

public class LevelGenerator : MonoBehaviour
{
    #region Serialized Fields
    [Header("Generation Settings")]
    public GameObject groundPrefab;
    public float groundLength = 20f;
    public float preGenerateDistance = 100f;
    public int numberOfLanes = 5;
    public float laneWidth = 2f;
    public float safeZoneLength = 50f;

    [Header("Terrain Variation")]
    [Tooltip("Use procedural mesh ground instead of flat prefab")]
    public bool useProceduralGround = true;
    [Tooltip("Vertex resolution per tile axis (higher = smoother hills, more verts)")]
    public int terrainResolution = 20;
    [Tooltip("Perlin noise frequency — smaller = broader hills")]
    [Range(0.01f, 0.5f)] public float terrainNoiseScale = 0.06f;
    [Tooltip("Max height displacement from Perlin noise")]
    [Range(0f, 8f)] public float terrainNoiseAmplitude = 2.5f;
    [Tooltip("Material to apply to procedural ground tiles")]
    public Material groundMaterial;

    [Header("Spawnable Object Lists")]
    public List<SpawnableObjectSO> staticObstacles;
    public List<SpawnableObjectSO> dynamicObstacles;
    public List<SpawnableObjectSO> collectibles;
    public List<SpawnableObjectSO> enemyShips;
    public List<SpawnableObjectSO> powerUps;

    [Header("Spawn Rules")]
    [Tooltip("Max objects that can occupy the same lane in one segment")]
    public int maxObjectsPerLane = 1;
    [Tooltip("Always keep at least this many lanes clear for the player")]
    public int minClearLanes = 2;

    [Header("Pooling Settings")]
    public int initialPoolSize = 10;
    #endregion

    #region Private Fields
    private float m_NextGenerationZ = 0f;
    private List<GameObject> m_ActiveGameObjects = new List<GameObject>();
    private List<GameObject> m_ActiveGroundTiles = new List<GameObject>();
    private Queue<GameObject> m_GroundTilePool = new Queue<GameObject>();
    private Transform m_PlayerTransform;
    private bool m_IsReadyToGenerate = false;
    private float m_MapWidth;

    // Per-segment lane occupancy tracking (reused each segment, no allocation)
    private int[] m_LaneOccupancy;
    #endregion

    #region Unity Lifecycle
    private void Start()
    {
        m_LaneOccupancy = new int[numberOfLanes];
        m_MapWidth = numberOfLanes * laneWidth;
        InitializePools();
        PrewarmGroundTilePool();
    }

    private void Update()
    {
        if (!m_IsReadyToGenerate || m_PlayerTransform == null) return;

        while (m_NextGenerationZ < m_PlayerTransform.position.z + preGenerateDistance)
        {
            GenerateSegment(isSafeZone: false);
        }

        CleanUpObjects();
        CleanUpGroundTiles();
    }
    #endregion

    #region Public Methods
    public void SetPlayerAndStart(Transform _player)
    {
        m_PlayerTransform = _player;
        m_IsReadyToGenerate = true;

        // Wire up the environment manager with the player for side prop spawning
        if (EnvironmentTransitionManager.Instance != null)
        {
            EnvironmentTransitionManager.Instance.SetPlayer(_player, GetMapHalfWidth());
        }

        while (m_NextGenerationZ < safeZoneLength)
        {
            GenerateSegment(isSafeZone: true);
        }
    }

    /// <summary>
    /// Returns the world X position for a given lane index (0-based, centered around 0).
    /// </summary>
    public float GetLaneXPosition(int _laneIndex)
    {
        return (_laneIndex - (numberOfLanes - 1) / 2f) * laneWidth;
    }

    /// <summary>
    /// Returns the total map half-width (from center to edge).
    /// </summary>
    public float GetMapHalfWidth()
    {
        return laneWidth * ((numberOfLanes - 1) / 2f) + laneWidth * 0.5f;
    }
    #endregion

    #region Ground Tile Pool
    private void PrewarmGroundTilePool()
    {
        if (!useProceduralGround) return;

        int poolSize = Mathf.CeilToInt(preGenerateDistance / groundLength) + 5;
        for (int i = 0; i < poolSize; i++)
        {
            GameObject tile = CreateProceduralTileObject();
            tile.SetActive(false);
            m_GroundTilePool.Enqueue(tile);
        }
    }

    private GameObject CreateProceduralTileObject()
    {
        GameObject tile = new GameObject("ProceduralGroundTile");
        tile.layer = LayerMask.NameToLayer("Default");
        tile.AddComponent<MeshFilter>();
        MeshRenderer renderer = tile.AddComponent<MeshRenderer>();
        tile.AddComponent<MeshCollider>();
        tile.AddComponent<ProceduralGroundTile>();

        tile.transform.SetParent(transform);
        return tile;
    }

    private GameObject GetGroundTile()
    {
        GameObject tile;
        if (m_GroundTilePool.Count > 0)
        {
            tile = m_GroundTilePool.Dequeue();
            tile.SetActive(true);
        }
        else
        {
            tile = CreateProceduralTileObject();
        }
        return tile;
    }

    private void ReturnGroundTile(GameObject _tile)
    {
        _tile.SetActive(false);
        m_GroundTilePool.Enqueue(_tile);
    }
    #endregion

    #region Generation
    private void InitializePools()
    {
        CreatePoolsForList(staticObstacles);
        CreatePoolsForList(dynamicObstacles);
        CreatePoolsForList(collectibles);
        CreatePoolsForList(enemyShips);
        CreatePoolsForList(powerUps);

        if (!useProceduralGround && groundPrefab != null)
        {
            PoolManager.Instance.CreatePool(groundPrefab, Mathf.CeilToInt(preGenerateDistance / groundLength) + 5);
        }
    }

    private void CreatePoolsForList(List<SpawnableObjectSO> _list)
    {
        foreach (var so in _list)
        {
            if (so.prefab != null)
            {
                PoolManager.Instance.CreatePool(so.prefab, initialPoolSize);
            }
        }
    }

    private void GenerateSegment(bool isSafeZone)
    {
        // Reset lane occupancy for this segment
        for (int i = 0; i < m_LaneOccupancy.Length; i++)
            m_LaneOccupancy[i] = 0;

        // Spawn ground tile
        SpawnGroundTile(isSafeZone);

        // Always spawn collectibles and power-ups
        GenerateObjectsInSegment(collectibles);
        GenerateObjectsInSegment(powerUps);

        if (!isSafeZone)
        {
            GenerateObjectsInSegment(staticObstacles);
            GenerateObjectsInSegment(dynamicObstacles);
            GenerateObjectsInSegment(enemyShips);
        }

        m_NextGenerationZ += groundLength;
    }

    private void SpawnGroundTile(bool _isSafeZone)
    {
        if (useProceduralGround)
        {
            GameObject tile = GetGroundTile();
            tile.transform.position = new Vector3(0f, 0f, m_NextGenerationZ);
            tile.transform.rotation = Quaternion.identity;

            // Read terrain params from the current biome if available, else use Inspector defaults
            float amplitude = terrainNoiseAmplitude;
            float frequency = terrainNoiseScale;
            Material biomeMat = groundMaterial;
            float flatness = 0.3f;
            float ridgedness = 0.2f;
            float warpStrength = 0.35f;

            if (EnvironmentTransitionManager.Instance != null)
            {
                amplitude = EnvironmentTransitionManager.Instance.CurrentTerrainAmplitude;
                frequency = EnvironmentTransitionManager.Instance.CurrentTerrainFrequency;
                flatness = EnvironmentTransitionManager.Instance.CurrentFlatness;
                ridgedness = EnvironmentTransitionManager.Instance.CurrentRidgedness;
                warpStrength = EnvironmentTransitionManager.Instance.CurrentDomainWarpStrength;
                Material biomeGround = EnvironmentTransitionManager.Instance.CurrentGroundMaterial;
                if (biomeGround != null) biomeMat = biomeGround;
            }

            if (_isSafeZone)
            {
                amplitude *= 0.3f;
                flatness = Mathf.Max(flatness, 0.7f); // safe zones are mostly flat
            }

            // Apply biome ground material to this tile
            MeshRenderer tileRenderer = tile.GetComponent<MeshRenderer>();
            if (tileRenderer != null && biomeMat != null)
            {
                tileRenderer.sharedMaterial = biomeMat;
            }

            ProceduralGroundTile proceduralTile = tile.GetComponent<ProceduralGroundTile>();
            proceduralTile.Generate(
                m_MapWidth,
                groundLength,
                terrainResolution,
                terrainResolution,
                frequency,
                amplitude,
                m_NextGenerationZ,
                flatness,
                ridgedness,
                warpStrength
            );

            m_ActiveGroundTiles.Add(tile);
        }
        else
        {
            GameObject ground = PoolManager.Instance.Get(groundPrefab.name);
            ground.transform.position = new Vector3(0, 0, m_NextGenerationZ);
            ground.transform.rotation = Quaternion.identity;
            ground.transform.SetParent(transform);
            m_ActiveGameObjects.Add(ground);
        }
    }

    private void GenerateObjectsInSegment(List<SpawnableObjectSO> _objectList)
    {
        foreach (SpawnableObjectSO so in _objectList)
        {
            if (Random.value < so.spawnRate)
            {
                SpawnObject(so);
            }
        }
    }

    private void SpawnObject(SpawnableObjectSO _so)
    {
        // Count how many lanes are still clear
        int clearLanes = 0;
        for (int i = 0; i < numberOfLanes; i++)
        {
            if (m_LaneOccupancy[i] < maxObjectsPerLane) clearLanes++;
        }

        // Don't spawn if we'd block too many lanes
        if (clearLanes <= minClearLanes) return;

        // Pick a random lane that isn't full
        int attempts = 0;
        int lane;
        do
        {
            lane = Random.Range(0, numberOfLanes);
            attempts++;
        }
        while (m_LaneOccupancy[lane] >= maxObjectsPerLane && attempts < 10);

        if (m_LaneOccupancy[lane] >= maxObjectsPerLane) return;

        // Mark lane as occupied
        m_LaneOccupancy[lane]++;

        GameObject obj = PoolManager.Instance.Get(_so.prefab.name);

        float xPosition = GetLaneXPosition(lane);
        float height = Random.Range(_so.heightMin, _so.heightMax);
        float zPosition = m_NextGenerationZ + Random.Range(0f, groundLength);

        obj.transform.position = new Vector3(xPosition, height, zPosition);
        obj.transform.rotation = Quaternion.identity;
        obj.transform.SetParent(transform);

        obj.transform.localScale = new Vector3(
            Random.Range(_so.sizeMin.x, _so.sizeMax.x),
            Random.Range(_so.sizeMin.y, _so.sizeMax.y),
            Random.Range(_so.sizeMin.z, _so.sizeMax.z)
        );

        // Apply the tag defined in the SpawnableObjectSO (safe — skips if tag not registered)
        if (_so.objectTag != ObjectTag.Untagged)
        {
            string tagName = _so.objectTag.ToString();
            try
            {
                obj.tag = tagName;
            }
            catch (UnityException)
            {
                Debug.LogWarning($"Tag '{tagName}' is not defined in the Tag Manager. " +
                    "Add it via Edit > Project Settings > Tags and Layers, or run ShipShip > Register Tags.");
            }
        }

        // Collectibles and PowerUps must use trigger colliders so the ship
        // passes through them instead of physically colliding (getting stuck).
        if (_so.objectTag == ObjectTag.Collectible || _so.objectTag == ObjectTag.PowerUp)
        {
            Collider col = obj.GetComponent<Collider>();
            if (col != null) col.isTrigger = true;

            // Disable Rigidbody physics on pickups so they don't fall or push the ship
            Rigidbody rb = obj.GetComponent<Rigidbody>();
            if (rb != null) rb.isKinematic = true;
        }

        m_ActiveGameObjects.Add(obj);
    }
    #endregion

    #region Cleanup
    private void CleanUpObjects()
    {
        float cleanupThreshold = m_PlayerTransform.position.z - 20f;
        m_ActiveGameObjects.RemoveAll(obj =>
        {
            if (obj == null) return true;

            if (obj.transform.position.z < cleanupThreshold)
            {
                PoolManager.Instance.Release(obj);
                return true;
            }
            return false;
        });
    }

    private void CleanUpGroundTiles()
    {
        float cleanupThreshold = m_PlayerTransform.position.z - groundLength - 10f;
        m_ActiveGroundTiles.RemoveAll(tile =>
        {
            if (tile == null) return true;

            if (tile.transform.position.z + groundLength < cleanupThreshold)
            {
                ReturnGroundTile(tile);
                return true;
            }
            return false;
        });
    }

    /// <summary>
    /// Returns ALL active objects and ground tiles to their pools and stops generation.
    /// Called by GameFlowController when returning to the menu.
    /// </summary>
    public void ResetAndStop()
    {
        m_IsReadyToGenerate = false;
        m_PlayerTransform = null;
        m_NextGenerationZ = 0f;

        // Return all spawned objects to pools
        foreach (GameObject obj in m_ActiveGameObjects)
        {
            if (obj != null)
            {
                PoolManager.Instance.Release(obj);
            }
        }
        m_ActiveGameObjects.Clear();

        // Return all ground tiles to pool
        foreach (GameObject tile in m_ActiveGroundTiles)
        {
            if (tile != null)
            {
                ReturnGroundTile(tile);
            }
        }
        m_ActiveGroundTiles.Clear();

        // Reset environment to first biome
        if (EnvironmentTransitionManager.Instance != null)
        {
            EnvironmentTransitionManager.Instance.ResetEnvironment();
        }
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        float halfWidth = GetMapHalfWidth();
        float playerZ = m_PlayerTransform != null ? m_PlayerTransform.position.z : 0f;
        float drawStart = playerZ - 10f;
        float drawEnd = playerZ + preGenerateDistance;

        // --- Lane dividers ---
        Gizmos.color = new Color(1f, 1f, 1f, 0.15f);
        for (int i = 0; i < numberOfLanes; i++)
        {
            float x = GetLaneXPosition(i);
            Gizmos.DrawLine(new Vector3(x, 0.1f, drawStart), new Vector3(x, 0.1f, drawEnd));
        }

        // --- Map edge boundaries ---
        Gizmos.color = new Color(1f, 0.2f, 0.2f, 0.5f);
        Gizmos.DrawLine(new Vector3(-halfWidth, 0.2f, drawStart), new Vector3(-halfWidth, 0.2f, drawEnd));
        Gizmos.DrawLine(new Vector3(halfWidth, 0.2f, drawStart), new Vector3(halfWidth, 0.2f, drawEnd));

        // --- Safe zone ---
        if (m_PlayerTransform == null)
        {
            Gizmos.color = new Color(0f, 1f, 0f, 0.1f);
            Gizmos.DrawCube(
                new Vector3(0f, 0f, safeZoneLength * 0.5f),
                new Vector3(halfWidth * 2f, 0.05f, safeZoneLength));
        }

        // --- Next generation Z line ---
        Gizmos.color = new Color(0f, 0.8f, 1f, 0.4f);
        Gizmos.DrawLine(new Vector3(-halfWidth, 0.3f, m_NextGenerationZ), new Vector3(halfWidth, 0.3f, m_NextGenerationZ));

        // --- Generation horizon ---
        Gizmos.color = new Color(1f, 0.5f, 0f, 0.3f);
        float horizon = playerZ + preGenerateDistance;
        Gizmos.DrawLine(new Vector3(-halfWidth, 0.3f, horizon), new Vector3(halfWidth, 0.3f, horizon));

        // --- Label ---
        if (m_PlayerTransform != null)
        {
            UnityEditor.Handles.color = Color.white;
            UnityEditor.Handles.Label(new Vector3(halfWidth + 1f, 1f, playerZ),
                $"NextGenZ: {m_NextGenerationZ:F0}\nActive: {m_ActiveGameObjects.Count}\nTiles: {m_ActiveGroundTiles.Count}");
        }
    }
#endif
    #endregion
}