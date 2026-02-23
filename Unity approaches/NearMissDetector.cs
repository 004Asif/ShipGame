using UnityEngine;

/// <summary>
/// Detects near-misses when the player barely avoids obstacles/enemies.
/// Uses a slightly larger trigger collider around the ship. When an obstacle enters
/// the trigger zone but the player doesn't die, it counts as a near-miss.
/// Attach to the player ship — requires a child trigger collider.
/// </summary>
public class NearMissDetector : MonoBehaviour
{
    #region Serialized Fields
    [Header("Detection")]
    [SerializeField, Tooltip("Radius of the near-miss detection zone around the ship")]
    private float m_DetectionRadius = 2.5f;
    [SerializeField, Tooltip("Cooldown between near-miss triggers to prevent spam")]
    private float m_Cooldown = 0.5f;
    [SerializeField] private LayerMask m_ObstacleMask = ~0;

    [Header("Rewards")]
    [SerializeField] private int m_BonusPoints = 5;

    [Header("Events")]
    [SerializeField] private GameEvent onNearMiss;
    #endregion

    #region Private Fields
    private float m_LastNearMissTime = -10f;
    private SphereCollider m_TriggerCollider;
    private ShipController m_ShipController;
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        // Create a child object with a trigger sphere for near-miss detection
        GameObject detectorChild = new GameObject("NearMissZone");
        detectorChild.transform.SetParent(transform, false);
        detectorChild.layer = gameObject.layer;

        m_TriggerCollider = detectorChild.AddComponent<SphereCollider>();
        m_TriggerCollider.isTrigger = true;
        m_TriggerCollider.radius = m_DetectionRadius;

        // Add the relay component to forward trigger events back to us
        NearMissTriggerRelay relay = detectorChild.AddComponent<NearMissTriggerRelay>();
        relay.Initialize(this);

        // Need a Rigidbody on the child for trigger detection (kinematic, no physics effect)
        Rigidbody childRb = detectorChild.AddComponent<Rigidbody>();
        childRb.isKinematic = true;

        m_ShipController = GetComponent<ShipController>();
    }
    #endregion

    #region Public Methods
    /// <summary>
    /// Called by the relay when something enters the near-miss zone.
    /// </summary>
    public void OnNearMissZoneEnter(Collider _other)
    {
        if (Time.time - m_LastNearMissTime < m_Cooldown) return;

        // Only count obstacles and enemy ships
        if (!_other.CompareTag("Obstacle") && !_other.CompareTag("EnemyShip")) return;

        // If the ship is dying, this isn't a near-miss
        if (m_ShipController == null) return;

        m_LastNearMissTime = Time.time;

        // Award bonus points
        if (ScoreManager.Instance != null)
        {
            ScoreManager.Instance.AddNearMissBonus(m_BonusPoints);
        }

        // Play audio cue
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.Play(AudioEvents.NearMiss);
        }

        // Raise event for UI feedback, etc.
        if (onNearMiss != null)
        {
            onNearMiss.Raise();
        }
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        // --- Near-miss detection sphere ---
        bool onCooldown = Application.isPlaying && (Time.time - m_LastNearMissTime < m_Cooldown);
        Gizmos.color = onCooldown ? new Color(1f, 1f, 0f, 0.2f) : new Color(0f, 1f, 1f, 0.2f);
        Gizmos.DrawWireSphere(transform.position, m_DetectionRadius);

        Gizmos.color = onCooldown ? new Color(1f, 1f, 0f, 0.06f) : new Color(0f, 1f, 1f, 0.06f);
        Gizmos.DrawSphere(transform.position, m_DetectionRadius);

        UnityEditor.Handles.color = Color.cyan;
        UnityEditor.Handles.Label(transform.position + Vector3.up * (m_DetectionRadius + 0.5f),
            onCooldown ? "NearMiss [COOLDOWN]" : "NearMiss [READY]");
    }
#endif
    #endregion
}

/// <summary>
/// Relay component placed on the near-miss trigger child object.
/// Forwards OnTriggerEnter events to the parent NearMissDetector.
/// </summary>
public class NearMissTriggerRelay : MonoBehaviour
{
    private NearMissDetector m_Detector;

    public void Initialize(NearMissDetector _detector)
    {
        m_Detector = _detector;
    }

    private void OnTriggerEnter(Collider _other)
    {
        if (m_Detector != null)
        {
            m_Detector.OnNearMissZoneEnter(_other);
        }
    }
}
