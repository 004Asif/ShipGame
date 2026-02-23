using UnityEngine;
using System.Collections;

/// <summary>
/// Spawns and manages the player ship. No DontDestroyOnLoad, no scene listeners.
/// Called directly by GameFlowController during the Intro phase.
/// Ships spawn kinematic (no gravity) and smoothly descend to hover height
/// before physics are enabled for gameplay.
/// </summary>
public class ShipSpawner : MonoBehaviour
{
    #region Singleton
    public static ShipSpawner Instance { get; private set; }
    #endregion

    #region Serialized Fields
    [Header("Spawning Configuration")]
    [Tooltip("The player ship prefab to spawn.")]
    [SerializeField] private GameObject m_ShipPrefab;

    [SerializeField, Tooltip("Spawn position offset from world origin")]
    private Vector3 m_SpawnOffset = new Vector3(0f, 4f, 5f);

    [Header("Intro Animation")]
    [SerializeField, Tooltip("Final hover height the ship settles to")]
    private float m_TargetHoverHeight = 1.5f;
    [SerializeField, Tooltip("How long the descent animation takes")]
    private float m_DescentDuration = 1.5f;
    [SerializeField, Tooltip("Forward speed during intro descent")]
    private float m_IntroForwardSpeed = 3f;
    #endregion

    #region Public Properties
    public GameObject CurrentShip { get; private set; }
    #endregion

    #region Private Fields
    private Coroutine m_IntroCoroutine;
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
    #endregion

    #region Public Methods
    /// <summary>
    /// Spawns the ship at the spawn position as KINEMATIC (no gravity, no drop).
    /// Controller is disabled. Call BeginIntroAnimation() to start the smooth descent.
    /// </summary>
    public void SpawnShip()
    {
        if (m_ShipPrefab == null)
        {
            Debug.LogError("Ship Prefab is not assigned on the ShipSpawner!", this);
            return;
        }

        if (CurrentShip != null)
        {
            Destroy(CurrentShip);
        }

        // Use ShipManager to get the selected ship if available
        GameObject prefabToSpawn = m_ShipPrefab;
        if (ShipManager.Instance != null)
        {
            ShipManager.ShipModel selectedShip = ShipManager.Instance.GetCurrentShip();
            if (selectedShip != null && selectedShip.prefab != null)
            {
                prefabToSpawn = selectedShip.prefab;
            }
        }

        CurrentShip = Instantiate(prefabToSpawn, m_SpawnOffset, Quaternion.identity);
        CurrentShip.tag = "Player";

        // Spawn as kinematic — no gravity, no physics drop
        Rigidbody rb = CurrentShip.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = true;
            rb.useGravity = false;
        }

        // Disable controller — GameFlowController enables it when Playing phase starts
        ShipController controller = CurrentShip.GetComponent<ShipController>();
        if (controller != null)
        {
            controller.enabled = false;
        }

        Debug.Log($"[ShipSpawner] Ship spawned (kinematic): {prefabToSpawn.name}");
    }

    /// <summary>
    /// Smoothly descends the ship from spawn height to hover height over the given duration.
    /// Also gently moves forward during descent for a cinematic feel.
    /// Call this after SpawnShip() during the intro phase.
    /// </summary>
    public void BeginIntroAnimation(float _duration = -1f)
    {
        if (CurrentShip == null) return;
        float dur = _duration > 0f ? _duration : m_DescentDuration;
        if (m_IntroCoroutine != null) StopCoroutine(m_IntroCoroutine);
        m_IntroCoroutine = StartCoroutine(IntroDescentCoroutine(dur));
    }

    /// <summary>
    /// Transitions the ship from kinematic intro to full physics gameplay.
    /// Called by GameFlowController when entering the Playing phase.
    /// </summary>
    public void EnableShipPhysics()
    {
        if (CurrentShip == null) return;

        // Stop any running intro animation
        if (m_IntroCoroutine != null)
        {
            StopCoroutine(m_IntroCoroutine);
            m_IntroCoroutine = null;
        }

        Rigidbody rb = CurrentShip.GetComponent<Rigidbody>();
        if (rb != null)
        {
            rb.isKinematic = false;
            rb.useGravity = true;
            // Give a gentle forward impulse so the ship doesn't stall
            rb.AddForce(Vector3.forward * m_IntroForwardSpeed, ForceMode.VelocityChange);
        }

        // Enable the ship controller for gameplay
        ShipController controller = CurrentShip.GetComponent<ShipController>();
        if (controller != null)
        {
            controller.enabled = true;
        }
    }

    /// <summary>
    /// Destroys the current ship. Called by GameFlowController during cleanup.
    /// </summary>
    public void DestroyShip()
    {
        if (m_IntroCoroutine != null)
        {
            StopCoroutine(m_IntroCoroutine);
            m_IntroCoroutine = null;
        }

        if (CurrentShip != null)
        {
            Destroy(CurrentShip);
            CurrentShip = null;
        }
    }
    #endregion

    #region Private Methods
    private IEnumerator IntroDescentCoroutine(float _duration)
    {
        Transform shipTransform = CurrentShip.transform;
        Rigidbody rb = CurrentShip.GetComponent<Rigidbody>();

        // During intro the ship is kinematic, so we use transform-based descent
        // but apply smooth physics-like easing for a natural feel
        if (rb != null && rb.isKinematic)
        {
            Vector3 startPos = shipTransform.position;
            Vector3 targetPos = new Vector3(startPos.x, m_TargetHoverHeight, startPos.z);
            float elapsed = 0f;

            while (elapsed < _duration)
            {
                elapsed += Time.deltaTime;
                float t = Mathf.Clamp01(elapsed / _duration);

                // Smooth ease-out curve (fast start, gentle settle)
                float smoothT = 1f - (1f - t) * (1f - t);

                // Descend smoothly + drift forward
                Vector3 pos = Vector3.Lerp(startPos, targetPos, smoothT);
                pos.z += m_IntroForwardSpeed * elapsed;
                shipTransform.position = pos;

                // Gentle nose-down tilt during descent, leveling out at the end
                float tiltAngle = Mathf.Lerp(8f, 0f, smoothT);
                shipTransform.rotation = Quaternion.Euler(tiltAngle, 0f, 0f);

                yield return null;
            }

            // Snap to final position
            Vector3 finalPos = shipTransform.position;
            finalPos.y = m_TargetHoverHeight;
            shipTransform.position = finalPos;
            shipTransform.rotation = Quaternion.identity;
        }

        m_IntroCoroutine = null;
    }
    #endregion
}