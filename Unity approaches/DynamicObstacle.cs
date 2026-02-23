using UnityEngine;

/// <summary>
/// Dynamic obstacle that hovers via HoverBody and drifts sideways using Rigidbody forces.
/// Attach HoverBody component to the same GameObject for floating.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
[RequireComponent(typeof(HoverBody))]
public class DynamicObstacle : MonoBehaviour
{
    #region Serialized Fields
    [Header("Behaviour")]
    public float rotateSpeed = 50f;
    public Vector3 moveDirection = Vector3.right;
    public float movementRange = 5f;
    public float driftSpeed = 2f;

    [Header("Physics Forces")]
    [Tooltip("Thrust to chase the drift target position")]
    public float driftThrust = 20f;
    [Tooltip("Damping on lateral velocity")]
    public float lateralDrag = 4f;
    #endregion

    #region Private Fields
    private Rigidbody m_Rigidbody;
    private float m_StartX;
    private float m_DriftPhase;
    #endregion

    #region Unity Lifecycle
    private void Start()
    {
        m_Rigidbody = GetComponent<Rigidbody>();
        m_Rigidbody.isKinematic = false;
        m_Rigidbody.useGravity = true;
        m_Rigidbody.constraints = RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationZ;
        m_Rigidbody.linearDamping = 0.5f;

        m_StartX = transform.position.x;
        m_DriftPhase = Random.Range(0f, Mathf.PI * 2f);
    }

    private void FixedUpdate()
    {
        // --- Sideways drift via forces (Y is controlled by HoverBody) ---
        float targetX = m_StartX + Mathf.Sin(Time.time * driftSpeed + m_DriftPhase) * movementRange;
        float diffX = targetX - m_Rigidbody.position.x;

        // Proportional thrust toward target X
        float driftForce = diffX * driftThrust;
        m_Rigidbody.AddForce(Vector3.right * driftForce, ForceMode.Acceleration);

        // Lateral drag to prevent overshooting
        float dampForce = -m_Rigidbody.linearVelocity.x * lateralDrag;
        m_Rigidbody.AddForce(Vector3.right * dampForce, ForceMode.Acceleration);

        // Brake forward/back drift — obstacles should stay in place on Z
        float zBrake = -m_Rigidbody.linearVelocity.z * 5f;
        m_Rigidbody.AddForce(Vector3.forward * zBrake, ForceMode.Acceleration);

        // --- Spin via torque ---
        m_Rigidbody.AddTorque(Vector3.up * rotateSpeed * Mathf.Deg2Rad, ForceMode.Acceleration);
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        Vector3 pos = transform.position;
        float startX = Application.isPlaying ? m_StartX : pos.x;

        // --- Drift range ---
        Gizmos.color = new Color(1f, 0.6f, 0f, 0.3f);
        Vector3 leftLimit = new Vector3(startX - movementRange, pos.y, pos.z);
        Vector3 rightLimit = new Vector3(startX + movementRange, pos.y, pos.z);
        Gizmos.DrawLine(leftLimit, rightLimit);
        Gizmos.DrawWireSphere(leftLimit, 0.15f);
        Gizmos.DrawWireSphere(rightLimit, 0.15f);

        // --- Current drift target ---
        if (Application.isPlaying)
        {
            float targetX = startX + Mathf.Sin(Time.time * driftSpeed + m_DriftPhase) * movementRange;
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(new Vector3(targetX, pos.y, pos.z), 0.2f);
        }

        // --- Velocity arrow ---
        if (Application.isPlaying && m_Rigidbody != null)
        {
            Gizmos.color = Color.magenta;
            Gizmos.DrawLine(pos, pos + m_Rigidbody.linearVelocity.normalized * 2f);
        }

        // --- Label ---
        UnityEditor.Handles.color = Color.yellow;
        UnityEditor.Handles.Label(pos + Vector3.up * 1.5f, $"DynObs\nRange: {movementRange:F1}");
    }
#endif
    #endregion
}