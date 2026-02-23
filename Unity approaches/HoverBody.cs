using UnityEngine;

/// <summary>
/// Multi-point physics-driven hover for any object.
/// Attach to enemies, obstacles, collectibles, etc. to make them float above surfaces.
/// Requires a Rigidbody (added automatically). Uses multiple raycasts per FixedUpdate
/// for stable, tilt-aware hovering.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class HoverBody : MonoBehaviour
{
    #region Serialized Fields
    [Header("Hover Settings")]
    [SerializeField, Range(0.5f, 10f)] private float m_HoverHeight = 1.5f;
    [SerializeField, Range(10f, 300f)] private float m_SpringForce = 80f;
    [SerializeField, Range(1f, 30f)] private float m_Damping = 10f;
    [SerializeField, Range(2f, 30f)] private float m_RaycastDistance = 10f;
    [SerializeField] private LayerMask m_GroundMask = ~0;

    [Header("Multi-Point Rays (local-space offsets)")]
    [Tooltip("Leave empty for a single center ray. Add offsets for multi-point hover.")]
    [SerializeField] private Vector3[] m_RayOffsets = new Vector3[]
    {
        new Vector3( 0.0f, 0.0f,  0.0f),   // Center
        new Vector3(-0.4f, 0.0f,  0.5f),   // Front-left
        new Vector3( 0.4f, 0.0f,  0.5f),   // Front-right
        new Vector3(-0.4f, 0.0f, -0.5f),   // Rear-left
        new Vector3( 0.4f, 0.0f, -0.5f),   // Rear-right
    };

    [Header("Visual Bob (optional)")]
    [SerializeField] private bool m_EnableBob = true;
    [SerializeField, Range(0f, 0.5f)] private float m_BobAmplitude = 0.15f;
    [SerializeField, Range(0.5f, 4f)] private float m_BobFrequency = 1.5f;
    #endregion

    #region Private Fields
    private Rigidbody m_Rigidbody;
    private RaycastHit[] m_HoverHits;
    private bool[] m_HoverGrounded;
    private bool m_IsGrounded;
    private int m_GroundedCount;
    private float m_BobPhase;
    #endregion

    #region Public Properties
    public bool IsGrounded => m_IsGrounded;
    public float HoverHeight { get => m_HoverHeight; set => m_HoverHeight = value; }
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        m_Rigidbody = GetComponent<Rigidbody>();
        m_Rigidbody.isKinematic = false;
        m_Rigidbody.useGravity = true;
        m_Rigidbody.interpolation = RigidbodyInterpolation.Interpolate;
        m_Rigidbody.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;
        m_Rigidbody.linearDamping = 0.5f;

        // Randomize bob phase so objects don't bob in sync
        m_BobPhase = Random.Range(0f, Mathf.PI * 2f);

        // Initialize hover arrays
        int count = (m_RayOffsets != null && m_RayOffsets.Length > 0) ? m_RayOffsets.Length : 1;
        m_HoverHits = new RaycastHit[count];
        m_HoverGrounded = new bool[count];
    }

    private void FixedUpdate()
    {
        ApplyHover();
    }
    #endregion

    #region Hover Logic
    private void ApplyHover()
    {
        Vector3[] offsets = m_RayOffsets;
        if (offsets == null || offsets.Length == 0)
        {
            offsets = new Vector3[] { Vector3.zero };
        }

        int pointCount = offsets.Length;
        m_GroundedCount = 0;

        // Optional visual bob offset
        float bobOffset = 0f;
        if (m_EnableBob)
        {
            bobOffset = Mathf.Sin(Time.time * m_BobFrequency * Mathf.PI * 2f + m_BobPhase) * m_BobAmplitude;
        }

        float targetHeight = m_HoverHeight + bobOffset;

        float forceSum = 0f;

        for (int i = 0; i < pointCount; i++)
        {
            Vector3 worldOrigin = transform.TransformPoint(offsets[i]);

            m_HoverGrounded[i] = Physics.Raycast(
                worldOrigin, Vector3.down, out m_HoverHits[i],
                m_RaycastDistance, m_GroundMask,
                QueryTriggerInteraction.Ignore
            );

            if (m_HoverGrounded[i])
            {
                m_GroundedCount++;

                // Height-error spring: push toward target hover height
                float currentHeight = worldOrigin.y - m_HoverHits[i].point.y;
                float heightError = targetHeight - currentHeight;

                float spring = heightError * m_SpringForce;
                float damping = -m_Rigidbody.linearVelocity.y * m_Damping;

                forceSum += spring + damping;
            }
        }

        m_IsGrounded = m_GroundedCount > 0;

        if (m_IsGrounded)
        {
            // Apply averaged force at center of mass — no unwanted torque
            float avgForce = forceSum / m_GroundedCount;
            m_Rigidbody.AddForce(Vector3.up * avgForce, ForceMode.Acceleration);
        }
        else
        {
            // Slow the fall when no ground is detected (30% anti-gravity)
            m_Rigidbody.AddForce(Vector3.up * -Physics.gravity.y * 0.3f, ForceMode.Acceleration);
        }
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        Vector3 pos = transform.position;
        Vector3[] offsets = m_RayOffsets;
        if (offsets == null || offsets.Length == 0)
        {
            offsets = new Vector3[] { Vector3.zero };
        }

        for (int i = 0; i < offsets.Length; i++)
        {
            Vector3 worldOrigin = Application.isPlaying
                ? transform.TransformPoint(offsets[i])
                : pos + offsets[i];

            bool hit = Application.isPlaying && m_HoverGrounded != null && i < m_HoverGrounded.Length && m_HoverGrounded[i];

            // Ray line
            Gizmos.color = hit ? Color.green : Color.red;
            Gizmos.DrawLine(worldOrigin, worldOrigin + Vector3.down * m_RaycastDistance);
            Gizmos.DrawWireSphere(worldOrigin, 0.06f);

            if (hit && m_HoverHits != null)
            {
                // Ground hit point
                Gizmos.color = Color.yellow;
                Gizmos.DrawWireSphere(m_HoverHits[i].point, 0.08f);

                // Per-point normal
                Gizmos.color = Color.cyan;
                Gizmos.DrawLine(m_HoverHits[i].point, m_HoverHits[i].point + m_HoverHits[i].normal * 0.8f);
            }
        }

        // Hover target height
        if (m_IsGrounded || !Application.isPlaying)
        {
            Gizmos.color = new Color(0f, 1f, 0.5f, 0.5f);
            float targetY = pos.y; // approximate in edit mode
            if (Application.isPlaying && m_IsGrounded && m_HoverHits != null && m_HoverHits.Length > 0)
            {
                float avgGround = 0f;
                int count = 0;
                for (int i = 0; i < m_HoverGrounded.Length; i++)
                {
                    if (m_HoverGrounded[i]) { avgGround += m_HoverHits[i].point.y; count++; }
                }
                if (count > 0) targetY = avgGround / count + m_HoverHeight;
            }
            Vector3 hoverTarget = new Vector3(pos.x, targetY, pos.z);
            Gizmos.DrawLine(hoverTarget + Vector3.left * 0.4f, hoverTarget + Vector3.right * 0.4f);
        }
    }
#endif
    #endregion
}
