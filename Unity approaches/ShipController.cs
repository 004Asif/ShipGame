using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Rigidbody))]
public class ShipController : MonoBehaviour
{
    #region Serialized Fields
    [Header("Configuration")]
    [SerializeField] private ShipDataSO shipData;
    [SerializeField] private Material shieldMaterial;

    [Header("Data Variables")]
    [SerializeField] private Vector2Variable playerInput;

    [Header("Data Variables")]
    [SerializeField] private FloatVariable boostEnergy;
    [SerializeField] private PlayerProfileSO playerProfileData;

    [Header("Game Events")]
    [SerializeField] private GameEvent onPlayerDied;
    [SerializeField] private GameEvent onStarCollected;

    [Header("Dependencies")]
    public StarCollectionParticleSystem starCollectionParticleSystem;
    public ExplosionEffect explosionPrefab;
    public ParticleSystem boostParticles;

    [Header("Hover Raycast")]
    [SerializeField] private LayerMask hoverRaycastMask = ~0;
    #endregion

    #region Public Properties
    public float CurrentSpeed { get; private set; }
    public float CurrentVisualSpeed => shipData != null ? Mathf.Min(CurrentSpeed, shipData.maxVisualSpeed) : CurrentSpeed;
    #endregion

    #region Private Fields
    private Rigidbody m_Rigidbody;
    private float m_DistanceTraveled = 0f;
    private Vector3 m_LastPosition;
    private bool m_IsDying = false;
    private PowerUpManager m_PowerUpManager;
    private AudioSource m_EngineAudioSource;
    private float m_TargetRotation = 0f;
    private float m_HorizontalInput = 0f;
    private float m_SmoothedInput = 0f;
    private bool m_IsBoosting = false;
    private bool m_IsGrounded = false;
    private float m_CurrentGroundHeight = 0f;
    private Vector3 m_TerrainNormal = Vector3.up;

    private Renderer m_ShipRenderer;
    private Material m_OriginalMaterial;

    // Multi-point hover data
    private RaycastHit[] m_HoverHits;
    private bool[] m_HoverGrounded;
    private int m_GroundedCount = 0;

    // Cached camera for screen shake
    private CameraFollow m_CameraFollow;

    // New Input System handler
    private ShipInputHandler m_InputHandler;
    #endregion

    #region Unity Lifecycle
    private void Start()
    {
        if (shipData == null)
        {
            Debug.LogError("ShipController: shipData (ShipDataSO) is not assigned! Disabling controller.", this);
            enabled = false;
            return;
        }

        InitializeComponents();
        InitializeAudio();
        InitializeHoverPoints();

        CurrentSpeed = shipData.initialForwardSpeed;
        m_LastPosition = transform.position;
        if (boostEnergy != null) boostEnergy.value = 0;

        m_ShipRenderer = GetComponentInChildren<Renderer>();
        if (m_ShipRenderer != null) m_OriginalMaterial = m_ShipRenderer.material;

        if (explosionPrefab != null)
        {
            PoolManager.Instance.CreatePool(explosionPrefab.gameObject, 2);
        }

        // Find CameraFollow on the main camera for screen shake
        Camera mainCam = Camera.main;
        if (mainCam != null) mainCam.TryGetComponent(out m_CameraFollow);

        // Try to find the new Input System handler
        TryGetComponent(out m_InputHandler);
    }

    private void Update()
    {
        UpdateSpeed();
        HandleInput();
        UpdateEnvironment();
        UpdateEngineSound();
        UpdateDistanceTraveled();
    }

    private void FixedUpdate()
    {
        ApplyHoverForce();
        ApplyMovement();
        ApplyRotation();
        ConstrainShipPosition();
    }
    #endregion

    #region Hover Physics
    private void InitializeHoverPoints()
    {
        int count = shipData.hoverRayOffsets != null ? shipData.hoverRayOffsets.Length : 1;
        m_HoverHits = new RaycastHit[count];
        m_HoverGrounded = new bool[count];
    }

    private void ApplyHoverForce()
    {
        Vector3[] offsets = shipData.hoverRayOffsets;
        if (offsets == null || offsets.Length == 0)
        {
            offsets = new Vector3[] { Vector3.zero };
        }

        int pointCount = offsets.Length;
        m_GroundedCount = 0;
        Vector3 normalSum = Vector3.zero;
        float groundHeightSum = 0f;
        float forceSum = 0f;
        float rayLen = shipData.hoverRaycastDistance;

        for (int i = 0; i < pointCount; i++)
        {
            Vector3 worldOrigin = transform.TransformPoint(offsets[i]);

            m_HoverGrounded[i] = Physics.Raycast(
                worldOrigin, Vector3.down, out m_HoverHits[i],
                rayLen, hoverRaycastMask,
                QueryTriggerInteraction.Ignore
            );

            if (m_HoverGrounded[i])
            {
                m_GroundedCount++;
                float groundY = m_HoverHits[i].point.y;
                Vector3 hitNormal = m_HoverHits[i].normal;

                groundHeightSum += groundY;
                normalSum += hitNormal;

                // Height-error spring: push toward target hover height
                float currentHeight = worldOrigin.y - groundY;
                float heightError = shipData.hoverHeight - currentHeight;

                float spring = heightError * shipData.hoverSpringForce;

                // Strong velocity damping — prevents oscillation/jitter
                float damping = -m_Rigidbody.linearVelocity.y * shipData.hoverDamping;

                forceSum += spring + damping;
            }
        }

        m_IsGrounded = m_GroundedCount > 0;

        if (m_IsGrounded)
        {
            m_CurrentGroundHeight = groundHeightSum / m_GroundedCount;
            m_TerrainNormal = (normalSum / m_GroundedCount).normalized;

            // Apply averaged hover force at center of mass
            float avgForce = forceSum / m_GroundedCount;
            m_Rigidbody.AddForce(m_TerrainNormal * avgForce, ForceMode.Acceleration);
        }
        else
        {
            m_TerrainNormal = Vector3.Lerp(m_TerrainNormal, Vector3.up, Time.fixedDeltaTime * 2f);
            m_Rigidbody.AddForce(Vector3.up * -Physics.gravity.y * 0.3f, ForceMode.Acceleration);
        }
    }
    #endregion

    #region Movement and Rotation
    private void ApplyMovement()
    {
        // --- Forward thrust: accelerate toward target speed using forces ---
        float currentForwardSpeed = m_Rigidbody.linearVelocity.z;
        float speedError = CurrentSpeed - currentForwardSpeed;
        if (speedError > 0.1f)
        {
            float thrustZ = speedError * shipData.forwardThrust;
            m_Rigidbody.AddForce(Vector3.forward * thrustZ, ForceMode.Acceleration);
        }

        // --- Lateral thrust from input ---
        float lateralForce = m_HorizontalInput * shipData.lateralThrust;
        m_Rigidbody.AddForce(Vector3.right * lateralForce, ForceMode.Acceleration);

        // --- Lateral drag: dampen sideways velocity so the ship doesn't slide forever ---
        Vector3 vel = m_Rigidbody.linearVelocity;
        float lateralDampForce = -vel.x * shipData.lateralDrag;
        m_Rigidbody.AddForce(Vector3.right * lateralDampForce, ForceMode.Acceleration);
    }

    private void ApplyRotation()
    {
        // Smooth the input for banking so it doesn't snap
        m_SmoothedInput = Mathf.Lerp(m_SmoothedInput, m_HorizontalInput, Time.fixedDeltaTime * 12f);

        // Terrain alignment: tilt to match ground slope
        Vector3 forward = Vector3.ProjectOnPlane(Vector3.forward, m_TerrainNormal);
        if (forward.sqrMagnitude < 0.001f) forward = Vector3.forward;
        Quaternion terrainAlign = Quaternion.LookRotation(forward.normalized, m_TerrainNormal);

        // Bank/roll from smoothed horizontal input
        float bankAngle = -m_SmoothedInput * shipData.maxRotationAngle;
        Quaternion bankQuat = Quaternion.Euler(0f, 0f, bankAngle);
        Quaternion targetQuat = terrainAlign * bankQuat;

        // Fast, responsive rotation — high interpolation speed
        float rotSpeed = shipData.terrainAlignSpeed * Time.fixedDeltaTime;
        rotSpeed = Mathf.Clamp01(rotSpeed);
        m_Rigidbody.MoveRotation(Quaternion.Slerp(
            transform.rotation,
            targetQuat,
            rotSpeed
        ));
    }

    private void ConstrainShipPosition()
    {
        float mapHalfWidth = shipData.laneWidth * ((shipData.numberOfLanes - 1) / 2f) + shipData.laneWidth * 0.5f;
        Vector3 pos = m_Rigidbody.position;
        float overshoot = 0f;

        if (pos.x < -mapHalfWidth)
            overshoot = -mapHalfWidth - pos.x; // positive = push right
        else if (pos.x > mapHalfWidth)
            overshoot = mapHalfWidth - pos.x;  // negative = push left

        if (Mathf.Abs(overshoot) > 0.01f)
        {
            // Spring force pushes ship back toward playable area
            float springForce = overshoot * shipData.edgeSpringForce;
            m_Rigidbody.AddForce(Vector3.right * springForce, ForceMode.Acceleration);

            // Subtle screen shake (only trigger once per edge contact)
            if (m_CameraFollow != null && Mathf.Abs(overshoot) > 0.05f)
            {
                m_CameraFollow.Shake(shipData.edgeShakeIntensity, shipData.edgeShakeDuration);
            }

            // Light haptic on edge bounce
            if (Mathf.Abs(overshoot) > 0.05f)
            {
                HapticFeedback.LightVibration();
            }
        }
    }

    private void UpdateSpeed()
    {
        // Don't override speed during boost — the coroutine controls it
        if (m_IsBoosting) return;
        CurrentSpeed = Mathf.Min(CurrentSpeed + shipData.accelerationRate * Time.deltaTime, shipData.maxForwardSpeed);
    }

    private void HandleInput()
    {
        float inputX = 0f;

        // Use new Input System handler if available
        if (m_InputHandler != null)
        {
            inputX = m_InputHandler.HorizontalInput;
        }
        else
        {
            // Fallback to legacy Input Manager
            inputX = Input.GetAxis("Horizontal");

            if (playerInput != null && playerInput.value.x != 0)
            {
                inputX = playerInput.value.x;
            }
        }

        m_HorizontalInput = inputX * shipData.buttonInputSensitivity;
        m_TargetRotation = m_HorizontalInput * shipData.maxRotationAngle;
    }
    #endregion

    #region Collision and Trigger Logic
    private void OnCollisionEnter(Collision _collision)
    {
        if (_collision.gameObject.CompareTag("Obstacle") && !m_IsDying)
        {
            TriggerDeathSequence();
        }
    }

    private void OnTriggerEnter(Collider _other)
    {
        if (_other.CompareTag("Collectible"))
        {
            CollectStar(_other.gameObject);
        }
        else if (_other.CompareTag("Obstacle") || _other.CompareTag("EnemyShip"))
        {
            if (m_PowerUpManager != null && !m_PowerUpManager.IsPowerUpActive(PowerUpType.Shield))
            {
                TriggerDeathSequence();
            }
        }
    }

    private void CollectStar(GameObject _star)
    {
        if (onStarCollected != null)
        {
            onStarCollected.Raise();
        }

        if (starCollectionParticleSystem != null)
        {
            starCollectionParticleSystem.Play(_star.transform.position);
        }

        PoolManager.Instance.Release(_star);
    }
    #endregion

    #region Death Sequence and Boost
    public void TriggerDeathSequence()
    {
        if (m_IsDying) return;
        StartCoroutine(DeathSequence());
    }

    private IEnumerator DeathSequence()
    {
        m_IsDying = true;

        // Heavy haptic on death
        HapticFeedback.HeavyVibration();

        if (explosionPrefab != null)
        {
            GameObject explosionObj = PoolManager.Instance.Get(explosionPrefab.name);
            if (explosionObj != null) explosionObj.transform.position = transform.position;
        }

        if (onPlayerDied != null)
        {
            onPlayerDied.Raise();
        }

        gameObject.SetActive(false);

        yield return null;
    }

    private IEnumerator BoostCoroutine()
    {
        m_IsBoosting = true;
        float originalSpeed = CurrentSpeed;
        float boostSpeed = originalSpeed * shipData.boostSpeedMultiplier;

        if (boostParticles != null)
        {
            boostParticles.Play();
        }

        boostEnergy.value = 0f;

        // Smooth ramp UP over 0.5 seconds
        float rampTime = 0.5f;
        float elapsed = 0f;
        while (elapsed < rampTime)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, elapsed / rampTime);
            CurrentSpeed = Mathf.Lerp(originalSpeed, boostSpeed, t);
            yield return null;
        }
        CurrentSpeed = boostSpeed;

        // Hold boost speed for remaining duration
        yield return new WaitForSeconds(shipData.boostDuration - rampTime * 2f);

        // Smooth ramp DOWN over 0.5 seconds
        elapsed = 0f;
        while (elapsed < rampTime)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, elapsed / rampTime);
            CurrentSpeed = Mathf.Lerp(boostSpeed, originalSpeed, t);
            yield return null;
        }
        CurrentSpeed = originalSpeed;

        if (boostParticles != null)
        {
            boostParticles.Stop();
        }

        m_IsBoosting = false;
    }
    #endregion

    #region Public Methods
    public bool CanActivateBoost() => boostEnergy != null && boostEnergy.value >= ShipDataSO.maxBoostEnergy;
    public void AddBoostEnergy(float _amount) => boostEnergy.value = Mathf.Clamp(boostEnergy.value + _amount, 0f, ShipDataSO.maxBoostEnergy);

    public void ActivateBoost()
    {
        if (CanActivateBoost())
        {
            StartCoroutine(BoostCoroutine());
        }
    }
    public void SetMovementInput(float _input) => m_HorizontalInput = _input * shipData.buttonInputSensitivity;
    public void SetSpeed(float _speed) => CurrentSpeed = _speed;

    public void SetShieldActive(bool _isActive)
    {
        if (m_ShipRenderer == null) return;
        m_ShipRenderer.material = _isActive ? shieldMaterial : m_OriginalMaterial;
    }

    public void ResetToDefaultSpeed()
    {
        CurrentSpeed = shipData.initialForwardSpeed;
    }
    #endregion

    #region Private Methods
    private void InitializeComponents()
    {
        m_Rigidbody = GetComponent<Rigidbody>();
        m_Rigidbody.isKinematic = false;
        m_Rigidbody.useGravity = true;
        m_Rigidbody.interpolation = RigidbodyInterpolation.Interpolate;
        m_Rigidbody.collisionDetectionMode = CollisionDetectionMode.ContinuousDynamic;
        m_Rigidbody.constraints = RigidbodyConstraints.FreezeRotation;
        m_Rigidbody.linearDamping = shipData.linearDrag;
        m_Rigidbody.angularDamping = shipData.angularDrag;

        // PowerUpManager should be on the prefab so serialized fields are assigned
        if (!TryGetComponent(out m_PowerUpManager))
        {
            m_PowerUpManager = gameObject.AddComponent<PowerUpManager>();
        }
    }

    private void InitializeAudio()
    {
        if (AudioManager.Instance != null)
        {
            m_EngineAudioSource = AudioManager.Instance.GetAudioSource(AudioEvents.PlayerShipEngine);
            if (m_EngineAudioSource != null) m_EngineAudioSource.Play();
        }
    }

    private void UpdateEngineSound()
    {
        if (m_EngineAudioSource == null) return;
        float speedRatio = CurrentSpeed / shipData.maxForwardSpeed;
        m_EngineAudioSource.pitch = Mathf.Lerp(0.5f, 1.5f, speedRatio);
        m_EngineAudioSource.volume = Mathf.Lerp(0.2f, 1f, speedRatio);
    }

    private void UpdateDistanceTraveled()
    {
        float distanceThisFrame = Vector3.Distance(transform.position, m_LastPosition);
        m_DistanceTraveled += distanceThisFrame;
        m_LastPosition = transform.position;
        if (playerProfileData != null) playerProfileData.AddDistance(distanceThisFrame / 1000f);
    }

    private void UpdateEnvironment()
    {
        if (EnvironmentTransitionManager.Instance != null)
            EnvironmentTransitionManager.Instance.CheckForTransition(m_DistanceTraveled);
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        if (shipData == null) return;

        Vector3 pos = transform.position;
        Vector3[] offsets = shipData.hoverRayOffsets;

        // --- Multi-point hover rays ---
        if (offsets != null && offsets.Length > 0)
        {
            for (int i = 0; i < offsets.Length; i++)
            {
                Vector3 worldOrigin = Application.isPlaying
                    ? transform.TransformPoint(offsets[i])
                    : pos + offsets[i];

                bool hit = Application.isPlaying && m_HoverGrounded != null && i < m_HoverGrounded.Length && m_HoverGrounded[i];

                // Ray line
                Gizmos.color = hit ? Color.green : Color.red;
                Gizmos.DrawLine(worldOrigin, worldOrigin + Vector3.down * shipData.hoverRaycastDistance);

                // Ray origin marker
                Gizmos.DrawWireSphere(worldOrigin, 0.08f);

                if (hit && m_HoverHits != null)
                {
                    // Ground hit point
                    Gizmos.color = Color.yellow;
                    Gizmos.DrawWireSphere(m_HoverHits[i].point, 0.12f);

                    // Per-point normal
                    Gizmos.color = Color.cyan;
                    Gizmos.DrawLine(m_HoverHits[i].point, m_HoverHits[i].point + m_HoverHits[i].normal * 1.0f);
                }
            }
        }

        // --- Averaged terrain normal ---
        if (m_IsGrounded)
        {
            Gizmos.color = new Color(0f, 1f, 1f, 0.8f);
            Gizmos.DrawLine(pos, pos + m_TerrainNormal * 2f);

            // Hover target height line
            Gizmos.color = new Color(0f, 1f, 0.5f, 0.5f);
            Vector3 hoverTarget = new Vector3(pos.x, m_CurrentGroundHeight + shipData.hoverHeight, pos.z);
            Gizmos.DrawLine(hoverTarget + Vector3.left * 1f, hoverTarget + Vector3.right * 1f);
        }

        // --- Velocity arrow ---
        if (m_Rigidbody != null)
        {
            Gizmos.color = Color.blue;
            Gizmos.DrawLine(pos, pos + m_Rigidbody.linearVelocity.normalized * 3f);
            Gizmos.DrawWireSphere(pos + m_Rigidbody.linearVelocity.normalized * 3f, 0.1f);
        }

        // --- Forward direction ---
        Gizmos.color = Color.white;
        Gizmos.DrawLine(pos, pos + transform.forward * 4f);

        // --- Lane edge boundaries (map half-width) ---
        float mapHalfWidth = shipData.laneWidth * ((shipData.numberOfLanes - 1) / 2f) + shipData.laneWidth * 0.5f;
        Gizmos.color = new Color(1f, 0.3f, 0.3f, 0.6f);
        Vector3 leftEdge = new Vector3(-mapHalfWidth, pos.y, pos.z);
        Vector3 rightEdge = new Vector3(mapHalfWidth, pos.y, pos.z);
        Gizmos.DrawLine(leftEdge + Vector3.forward * 10f, leftEdge + Vector3.back * 5f);
        Gizmos.DrawLine(rightEdge + Vector3.forward * 10f, rightEdge + Vector3.back * 5f);

        // --- Speed / state label ---
        UnityEditor.Handles.color = Color.white;
        string label = $"Speed: {CurrentSpeed:F1}\nInput: {m_HorizontalInput:F2}\nGrounded: {m_IsGrounded} ({m_GroundedCount}/{(offsets != null ? offsets.Length : 0)})";
        UnityEditor.Handles.Label(pos + Vector3.up * 2.5f, label);
    }
#endif
    #endregion
}