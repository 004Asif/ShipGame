using UnityEngine;

/// <summary>
/// Generates a procedural ground mesh with Perlin noise height variation.
/// Attach to an empty GameObject — mesh, collider, and renderer are created at runtime.
/// Call Generate() to build/rebuild the mesh for a given Z offset and noise seed.
/// </summary>
[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshCollider))]
public class ProceduralGroundTile : MonoBehaviour
{
    #region Private Fields
    private MeshFilter m_MeshFilter;
    private MeshCollider m_MeshCollider;
    private Mesh m_Mesh;

    // Per-tile biome shape overrides (set each Generate call)
    private float m_Flatness = 0.3f;
    private float m_Ridgedness = 0.2f;
    private float m_WarpStrength = 0.35f;
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        m_MeshFilter = GetComponent<MeshFilter>();
        m_MeshCollider = GetComponent<MeshCollider>();
        m_Mesh = new Mesh();
        m_Mesh.name = "ProceduralGround";
        m_MeshFilter.mesh = m_Mesh;
    }
    #endregion

    #region Public Methods
    /// <summary>
    /// Generate or regenerate the ground tile mesh.
    /// </summary>
    /// <param name="_width">Total width of the tile (X axis)</param>
    /// <param name="_length">Total length of the tile (Z axis)</param>
    /// <param name="_resX">Vertex resolution along X</param>
    /// <param name="_resZ">Vertex resolution along Z</param>
    /// <param name="_noiseScale">Perlin noise frequency (smaller = broader hills)</param>
    /// <param name="_noiseAmplitude">Max height displacement</param>
    /// <param name="_seedOffsetZ">Z-world offset used as noise seed so tiles connect seamlessly</param>
    /// <summary>Overload that accepts biome terrain shape parameters.</summary>
    public void Generate(float _width, float _length, int _resX, int _resZ,
                         float _noiseScale, float _noiseAmplitude, float _seedOffsetZ,
                         float _flatness, float _ridgedness, float _warpStrength)
    {
        m_Flatness = _flatness;
        m_Ridgedness = _ridgedness;
        m_WarpStrength = _warpStrength;
        GenerateInternal(_width, _length, _resX, _resZ, _noiseScale, _noiseAmplitude, _seedOffsetZ);
    }

    /// <summary>Legacy overload — uses default shape values.</summary>
    public void Generate(float _width, float _length, int _resX, int _resZ,
                         float _noiseScale, float _noiseAmplitude, float _seedOffsetZ)
    {
        m_Flatness = 0.3f;
        m_Ridgedness = 0.2f;
        m_WarpStrength = 0.35f;
        GenerateInternal(_width, _length, _resX, _resZ, _noiseScale, _noiseAmplitude, _seedOffsetZ);
    }

    private void GenerateInternal(float _width, float _length, int _resX, int _resZ,
                                   float _noiseScale, float _noiseAmplitude, float _seedOffsetZ)
    {
        int vertCountX = _resX + 1;
        int vertCountZ = _resZ + 1;
        int vertCount = vertCountX * vertCountZ;

        Vector3[] vertices = new Vector3[vertCount];
        Vector2[] uvs = new Vector2[vertCount];
        int[] triangles = new int[_resX * _resZ * 6];

        float halfWidth = _width * 0.5f;

        // Build vertices with multi-octave fractal noise for varied terrain
        for (int z = 0; z < vertCountZ; z++)
        {
            for (int x = 0; x < vertCountX; x++)
            {
                int index = z * vertCountX + x;

                float xPos = -halfWidth + (x / (float)_resX) * _width;
                float zPos = (z / (float)_resZ) * _length;

                // World-space noise coordinates for seamless tiling
                float worldZ = _seedOffsetZ + zPos;
                float height = SampleTerrain(xPos, worldZ, _noiseScale, _noiseAmplitude,
                                              m_Flatness, m_Ridgedness, m_WarpStrength);

                vertices[index] = new Vector3(xPos, height, zPos);
                uvs[index] = new Vector2(x / (float)_resX, z / (float)_resZ);
            }
        }

        // Build triangle indices
        int triIndex = 0;
        for (int z = 0; z < _resZ; z++)
        {
            for (int x = 0; x < _resX; x++)
            {
                int bottomLeft = z * vertCountX + x;
                int bottomRight = bottomLeft + 1;
                int topLeft = (z + 1) * vertCountX + x;
                int topRight = topLeft + 1;

                triangles[triIndex++] = bottomLeft;
                triangles[triIndex++] = topLeft;
                triangles[triIndex++] = bottomRight;

                triangles[triIndex++] = bottomRight;
                triangles[triIndex++] = topLeft;
                triangles[triIndex++] = topRight;
            }
        }

        m_Mesh.Clear();
        m_Mesh.vertices = vertices;
        m_Mesh.uv = uvs;
        m_Mesh.triangles = triangles;
        m_Mesh.RecalculateNormals();
        m_Mesh.RecalculateBounds();

        // Update collider to match new mesh
        m_MeshCollider.sharedMesh = null;
        m_MeshCollider.sharedMesh = m_Mesh;
    }
    #endregion

    #region Terrain Sampling
    // ─────────────────────────────────────────────────────────────
    // CONSTANTS — tweak these to change the overall terrain feel
    // ─────────────────────────────────────────────────────────────
    private const int   c_FbmOctaves       = 5;
    private const float c_Lacunarity       = 2.13f;   // frequency multiplier per octave
    private const float c_Gain             = 0.48f;   // amplitude multiplier per octave
    private const int   c_RidgedOctaves    = 4;
    private const float c_RidgedOffset     = 1.0f;    // inversion offset for ridged noise

    /// <summary>
    /// Advanced terrain height sampler combining:
    ///   1. Domain-warped fBm for organic rolling hills
    ///   2. Ridged multifractal for sharp ridge features
    ///   3. Terrain-type blending (flat plains ↔ hills ↔ ridges)
    ///   4. Optional terracing for plateau-like flat areas
    ///   5. Valley carving for gentle dips
    /// </summary>
    private static float SampleTerrain(float _x, float _z, float _baseFreq, float _amplitude,
                                       float _flatBias, float _ridgeBias, float _warpStr)
    {
        // Offset to avoid Perlin symmetry at origin
        float ox = _x + 1000f;
        float oz = _z + 500f;

        // ── 1. Domain Warping ──────────────────────────────────
        // Warp the input coordinates with low-frequency noise so
        // terrain features curve and meander organically instead
        // of looking grid-aligned.
        float warpScale = _baseFreq * 0.4f;
        float warpX = Noise(ox * warpScale + 50f,  oz * warpScale + 50f)  * _amplitude * _warpStr;
        float warpZ = Noise(ox * warpScale + 150f, oz * warpScale + 150f) * _amplitude * _warpStr;
        float wx = ox + warpX;
        float wz = oz + warpZ;

        // ── 2. Terrain-type selector ───────────────────────────
        // A very slow noise decides which terrain style dominates
        // at this world position. Biome flatness/ridgedness bias
        // the weights so deserts stay flat, mountains stay ridged.
        float typeNoise = Noise(ox * _baseFreq * 0.15f + 300f,
                                oz * _baseFreq * 0.15f + 300f);
        // Base weights from noise
        float rawFlat   = Mathf.SmoothStep(1f, 0f, Mathf.InverseLerp(0.20f, 0.45f, typeNoise));
        float rawRidged = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.60f, 0.85f, typeNoise));
        // Bias by biome parameters
        float flatWeight   = Mathf.Clamp01(rawFlat   + _flatBias * 0.5f);
        float ridgedWeight = Mathf.Clamp01(rawRidged + _ridgeBias * 0.5f);
        // Normalise so weights sum to 1
        float totalW = flatWeight + ridgedWeight + 0.001f;
        flatWeight   /= totalW;
        ridgedWeight /= totalW;
        float hillWeight = Mathf.Clamp01(1f - flatWeight - ridgedWeight);

        // ── 3. fBm (fractal Brownian motion) ───────────────────
        float fbm = FBM(wx, wz, _baseFreq, c_FbmOctaves, c_Lacunarity, c_Gain);

        // ── 4. Ridged Multifractal ─────────────────────────────
        float ridged = RidgedMultifractal(wx, wz, _baseFreq,
                                          c_RidgedOctaves, c_Lacunarity, c_Gain, c_RidgedOffset);

        // ── 5. Blend terrain types ─────────────────────────────
        float blended = flatWeight   * (fbm * 0.15f)      // plains: nearly flat, tiny undulations
                      + hillWeight   * fbm                 // hills:  full fBm
                      + ridgedWeight * ridged;             // ridges: sharp peaks

        float h = blended * _amplitude;

        // ── 6. Terracing / Plateaus ────────────────────────────
        // Quantise height into steps then smooth-blend back for
        // natural-looking flat plateaus between slopes.
        // Stronger in biomes with high flatness.
        float terraceCount = Mathf.Lerp(3f, 8f, _flatBias);
        if (terraceCount > 0f && _amplitude > 0.01f)
        {
            float terraceBlend = Mathf.SmoothStep(0f, 1f, flatWeight * 1.5f);
            if (terraceBlend > 0.01f)
            {
                float normalised = h / _amplitude;
                float stepped = Mathf.Round(normalised * terraceCount) / terraceCount;
                h = Mathf.Lerp(h, stepped * _amplitude, terraceBlend * 0.6f);
            }
        }

        // ── 7. Valley carving ──────────────────────────────────
        // Occasional gentle dips below the baseline driven by a
        // separate slow noise layer.
        float valleyNoise = Noise(ox * _baseFreq * 0.35f + 400f,
                                  oz * _baseFreq * 0.35f + 400f);
        if (valleyNoise < 0.25f)
        {
            float depth = Mathf.InverseLerp(0.25f, 0.0f, valleyNoise);
            h -= depth * _amplitude * 0.4f;
        }

        return h;
    }

    // ─────────────────────────────────────────────────────────────
    // NOISE PRIMITIVES
    // ─────────────────────────────────────────────────────────────

    /// <summary>Perlin noise remapped from [0,1] to [-1,1].</summary>
    private static float Noise(float _x, float _z)
    {
        return Mathf.PerlinNoise(_x, _z) * 2f - 1f;
    }

    /// <summary>
    /// Classic fractal Brownian motion — sum of octaves with
    /// increasing frequency (lacunarity) and decreasing amplitude (gain).
    /// Returns a value roughly in [-1, 1].
    /// </summary>
    private static float FBM(float _x, float _z, float _freq,
                              int _octaves, float _lacunarity, float _gain)
    {
        float sum = 0f;
        float amp = 1f;
        float freq = _freq;
        float maxAmp = 0f;

        for (int i = 0; i < _octaves; i++)
        {
            sum += Noise(_x * freq + i * 31.7f,
                         _z * freq + i * 17.3f) * amp;
            maxAmp += amp;
            freq *= _lacunarity;
            amp  *= _gain;
        }

        return sum / maxAmp; // normalise to roughly [-1, 1]
    }

    /// <summary>
    /// Ridged multifractal noise (Musgrave).
    /// Takes the absolute value of signed noise, inverts it, and
    /// squares the result to create sharp ridge-like peaks.
    /// Each octave's amplitude is weighted by the previous octave's
    /// signal for heterogeneous detail (more detail on ridges).
    /// Returns a value roughly in [0, 1].
    /// </summary>
    private static float RidgedMultifractal(float _x, float _z, float _freq,
                                             int _octaves, float _lacunarity,
                                             float _gain, float _offset)
    {
        float sum = 0f;
        float freq = _freq;
        float amp = 0.5f;
        float prev = 1f;

        for (int i = 0; i < _octaves; i++)
        {
            float n = Noise(_x * freq + i * 43.1f,
                            _z * freq + i * 67.9f);
            n = Mathf.Abs(n);           // create creases
            n = _offset - n;            // invert so creases become ridges
            n = n * n;                  // sharpen ridges

            sum += n * amp * prev;      // weight by previous signal
            prev = Mathf.Clamp01(n * 2f);

            freq *= _lacunarity;
            amp  *= _gain;
        }

        return sum;
    }
    #endregion
}
