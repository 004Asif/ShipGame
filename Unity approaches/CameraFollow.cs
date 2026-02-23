using UnityEngine;

/// <summary>
/// Camera controller that supports two modes:
/// 1. Menu mode — camera sits at a fixed anchor position/rotation.
/// 2. Chase mode — camera follows the player ship with offset + screen shake.
/// Smooth transitions between modes for the intro swoop.
/// </summary>
public class CameraFollow : MonoBehaviour
{
    #region Enums
    private enum CameraMode { Menu, Transitioning, Chase }
    #endregion

    #region Serialized Fields
    [Header("Chase Settings")]
    public Vector3 offset = new Vector3(0, 6, -12);
    public float smoothSpeed = 10f;
    [Tooltip("Extra follow speed per unit of distance error — prevents camera losing the ship")]
    public float catchUpFactor = 2f;

    [Header("Screen Shake")]
    #pragma warning disable CS0414
    [SerializeField] private float m_ShakeDecay = 5f;
    #pragma warning restore CS0414
    #endregion

    #region Private Fields
    private Transform m_Target;
    private CameraMode m_Mode = CameraMode.Menu;

    // Screen shake
    private float m_ShakeIntensity = 0f;
    private float m_ShakeTimer = 0f;
    private float m_ShakeDuration = 0f;

    // Menu mode
    private Transform m_MenuAnchor;

    // Transition
    private Vector3 m_TransitionStartPos;
    private Quaternion m_TransitionStartRot;
    private float m_TransitionDuration;
    private float m_TransitionElapsed;
    #endregion

    #region Unity Lifecycle
    private void LateUpdate()
    {
        switch (m_Mode)
        {
            case CameraMode.Menu:
                UpdateMenuMode();
                break;

            case CameraMode.Transitioning:
                UpdateTransition();
                break;

            case CameraMode.Chase:
                UpdateChaseMode();
                break;
        }
    }
    #endregion

    #region Mode Updates
    private void UpdateMenuMode()
    {
        if (m_MenuAnchor == null) return;
        transform.position = m_MenuAnchor.position;
        transform.rotation = m_MenuAnchor.rotation;
    }

    private void UpdateTransition()
    {
        m_TransitionElapsed += Time.deltaTime;
        float t = Mathf.Clamp01(m_TransitionElapsed / m_TransitionDuration);

        // Smooth ease-in-out
        float smoothT = t * t * (3f - 2f * t);

        // Target position is the chase position
        Vector3 chasePos = (m_Target != null) ? m_Target.position + offset : m_TransitionStartPos;
        Quaternion chaseRot = (m_Target != null) ? Quaternion.LookRotation(m_Target.position - chasePos) : m_TransitionStartRot;

        transform.position = Vector3.Lerp(m_TransitionStartPos, chasePos, smoothT);
        transform.rotation = Quaternion.Slerp(m_TransitionStartRot, chaseRot, smoothT);

        if (t >= 1f)
        {
            m_Mode = CameraMode.Chase;
        }
    }

    private void UpdateChaseMode()
    {
        if (m_Target == null) return;

        Vector3 desiredPosition = m_Target.position + offset;

        // Speed-adaptive follow: the further behind, the faster we catch up
        float dist = Vector3.Distance(transform.position, desiredPosition);
        float adaptiveSpeed = smoothSpeed + dist * catchUpFactor;
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, Time.deltaTime * adaptiveSpeed);

        // Apply screen shake offset
        if (m_ShakeTimer > 0f)
        {
            m_ShakeTimer -= Time.deltaTime;
            float currentIntensity = m_ShakeIntensity * (m_ShakeTimer / m_ShakeDuration);
            Vector3 shakeOffset = new Vector3(
                Random.Range(-currentIntensity, currentIntensity),
                Random.Range(-currentIntensity, currentIntensity) * 0.5f,
                0f
            );
            smoothedPosition += shakeOffset;
        }

        transform.position = smoothedPosition;
    }
    #endregion

    #region Public Methods
    public void SetTarget(Transform _newTarget)
    {
        m_Target = _newTarget;
    }

    /// <summary>
    /// Snap camera to a fixed menu anchor. No target following.
    /// </summary>
    public void SetMenuMode(Transform _menuAnchor)
    {
        m_MenuAnchor = _menuAnchor;
        m_Target = null;
        m_Mode = CameraMode.Menu;

        if (_menuAnchor != null)
        {
            transform.position = _menuAnchor.position;
            transform.rotation = _menuAnchor.rotation;
        }
    }

    /// <summary>
    /// Smoothly transition from current position to chase mode behind the target.
    /// Used for the intro swoop animation.
    /// </summary>
    public void TransitionToChaseMode(Transform _target, float _duration)
    {
        m_Target = _target;
        m_TransitionStartPos = transform.position;
        m_TransitionStartRot = transform.rotation;
        m_TransitionDuration = Mathf.Max(_duration, 0.1f);
        m_TransitionElapsed = 0f;
        m_Mode = CameraMode.Transitioning;
    }

    /// <summary>
    /// Trigger a screen shake. Intensity is in world units, duration in seconds.
    /// </summary>
    public void Shake(float _intensity, float _duration)
    {
        m_ShakeIntensity = _intensity;
        m_ShakeDuration = _duration;
        m_ShakeTimer = _duration;
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        // --- Camera to target line ---
        if (m_Target != null)
        {
            Gizmos.color = new Color(0f, 1f, 0f, 0.4f);
            Gizmos.DrawLine(transform.position, m_Target.position);
            Gizmos.DrawWireSphere(m_Target.position, 0.3f);

            // --- Desired chase position ---
            Vector3 desiredPos = m_Target.position + offset;
            Gizmos.color = new Color(0f, 0.5f, 1f, 0.4f);
            Gizmos.DrawWireCube(desiredPos, Vector3.one * 0.4f);
            Gizmos.DrawLine(desiredPos, m_Target.position);
        }

        // --- Menu anchor ---
        if (m_MenuAnchor != null && m_Mode == CameraMode.Menu)
        {
            Gizmos.color = new Color(1f, 0f, 1f, 0.3f);
            Gizmos.DrawWireCube(m_MenuAnchor.position, Vector3.one * 0.5f);
        }

        // --- Shake indicator ---
        if (m_ShakeTimer > 0f)
        {
            Gizmos.color = Color.red;
            Gizmos.DrawWireSphere(transform.position, m_ShakeIntensity);
        }

        // --- Label ---
        string modeName = m_Mode.ToString();
        string shakeInfo = m_ShakeTimer > 0f ? $"\nShake: {m_ShakeTimer:F2}s" : "";
        UnityEditor.Handles.color = Color.white;
        UnityEditor.Handles.Label(transform.position + Vector3.up * 1.5f, $"Cam [{modeName}]{shakeInfo}");
    }
#endif
    #endregion
}