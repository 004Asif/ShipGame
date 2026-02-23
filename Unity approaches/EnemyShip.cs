using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// Enemy ship with physics-driven hover (via HoverBody) and Rigidbody movement.
/// Attach HoverBody component to the same GameObject for floating.
/// </summary>
[RequireComponent(typeof(Rigidbody))]
[RequireComponent(typeof(HoverBody))]
public class EnemyShip : MonoBehaviour
{
    #region Serialized Fields
    [Header("Movement")]
    public float speed = 10f;
    public float lifetime = 15f;
    public float laneWidth = 2f;
    public int numberOfLanes = 5;
    public float laneChangeSpeed = 5f;

    [Header("Physics Forces")]
    [Tooltip("Thrust applied to reach target forward speed")]
    public float forwardThrust = 30f;
    [Tooltip("Thrust applied during lane changes")]
    public float laneChangeThrust = 25f;
    [Tooltip("Damping on lateral velocity to prevent overshooting lanes")]
    public float lateralDrag = 5f;

    [Header("Effects")]
    public ParticleSystem engineEffect;

    [Header("Audio")]
    [SerializeField] private float maxPassByDistance = 10f;
    #endregion

    #region Private Fields
    private Rigidbody m_Rigidbody;
    private int m_CurrentLane;
    private float m_TargetX;
    private bool m_IsChangingLane = false;
    private IEnemyShipState m_CurrentState;
    private List<IEnemyShipObserver> m_Observers = new List<IEnemyShipObserver>();
    private AudioSource m_PassByAudioSource;
    private Transform m_PlayerTransform;
    private Coroutine m_LifetimeCoroutine;
    #endregion

    #region Unity Lifecycle
    private void OnEnable()
    {
        m_IsChangingLane = false;
        m_LifetimeCoroutine = StartCoroutine(LifetimeCoroutine());
    }

    private void OnDisable()
    {
        if (m_LifetimeCoroutine != null)
        {
            StopCoroutine(m_LifetimeCoroutine);
            m_LifetimeCoroutine = null;
        }
    }

    private void Start()
    {
        m_Rigidbody = GetComponent<Rigidbody>();
        m_Rigidbody.isKinematic = false;
        m_Rigidbody.useGravity = true;
        m_Rigidbody.constraints = RigidbodyConstraints.FreezeRotation;
        m_Rigidbody.linearDamping = 0.5f;
        m_Rigidbody.angularDamping = 2f;

        SetInitialLane();
        if (engineEffect) engineEffect.Play();
        SetState(new CruisingState(this));

        InitializeAudio();
        FindPlayer();
    }

    private void Update()
    {
        m_CurrentState.Update();
        UpdatePassBySound();
    }

    private void FixedUpdate()
    {
        ApplyMovement();
    }
    #endregion

    #region Movement
    private void ApplyMovement()
    {
        // --- Forward thrust: accelerate toward target speed using forces ---
        float currentForwardSpeed = m_Rigidbody.linearVelocity.z;
        float speedError = -speed - currentForwardSpeed; // negative Z = toward player
        float thrustZ = speedError * forwardThrust;
        m_Rigidbody.AddForce(Vector3.forward * thrustZ, ForceMode.Acceleration);

        // --- Lane change via forces ---
        if (m_IsChangingLane)
        {
            float diff = m_TargetX - m_Rigidbody.position.x;
            if (Mathf.Abs(diff) < 0.1f && Mathf.Abs(m_Rigidbody.linearVelocity.x) < 0.5f)
            {
                m_IsChangingLane = false;
            }
            else
            {
                float laneForce = diff * laneChangeThrust;
                m_Rigidbody.AddForce(Vector3.right * laneForce, ForceMode.Acceleration);
            }
        }

        // --- Lateral drag to prevent overshooting ---
        float lateralDampForce = -m_Rigidbody.linearVelocity.x * lateralDrag;
        m_Rigidbody.AddForce(Vector3.right * lateralDampForce, ForceMode.Acceleration);
    }

    public void MoveForward()
    {
        // Movement is handled in FixedUpdate via Rigidbody
        NotifyObservers();
    }

    public void ChangeLane(int _direction)
    {
        int targetLane = Mathf.Clamp(m_CurrentLane + _direction, 0, numberOfLanes - 1);
        if (targetLane != m_CurrentLane)
        {
            m_CurrentLane = targetLane;
            m_TargetX = (m_CurrentLane - (numberOfLanes - 1) / 2f) * laneWidth;
            m_IsChangingLane = true;
        }
    }

    private void SetInitialLane()
    {
        m_CurrentLane = Random.Range(0, numberOfLanes);
        m_TargetX = (m_CurrentLane - (numberOfLanes - 1) / 2f) * laneWidth;
        Vector3 pos = transform.position;
        pos.x = m_TargetX;
        transform.position = pos;
    }

    public void SetInitialRotation()
    {
        transform.rotation = Quaternion.Euler(0, 0, 0);
    }
    #endregion

    #region State Machine
    public void SetState(IEnemyShipState _newState)
    {
        m_CurrentState = _newState;
    }
    #endregion

    #region Observer Pattern
    public void AddObserver(IEnemyShipObserver _observer) => m_Observers.Add(_observer);
    public void RemoveObserver(IEnemyShipObserver _observer) => m_Observers.Remove(_observer);

    private void NotifyObservers()
    {
        foreach (var observer in m_Observers)
        {
            observer.OnEnemyShipMoved(this);
        }
    }
    #endregion

    #region Collision
    private void OnCollisionEnter(Collision _collision)
    {
        if (_collision.gameObject.CompareTag("Player"))
        {
            if (_collision.gameObject.TryGetComponent(out ShipController playerShip))
            {
                if (playerShip.TryGetComponent(out PowerUpManager powerUpManager) && !powerUpManager.IsPowerUpActive(PowerUpType.Shield))
                {
                    playerShip.TriggerDeathSequence();
                }
            }
            ReturnToPool();
        }
    }

    private void OnTriggerEnter(Collider _other)
    {
        if (_other.CompareTag("Obstacle"))
        {
            SetState(new AvoidingState(this));
        }
    }
    #endregion

    #region Audio
    private void InitializeAudio()
    {
        if (AudioManager.Instance == null) return;

        AudioSource originalSource = AudioManager.Instance.GetAudioSource(AudioEvents.EnemyShipPassby);
        if (originalSource != null)
        {
            m_PassByAudioSource = gameObject.AddComponent<AudioSource>();
            m_PassByAudioSource.clip = originalSource.clip;
            m_PassByAudioSource.volume = originalSource.volume;
            m_PassByAudioSource.pitch = originalSource.pitch;
            m_PassByAudioSource.spatialBlend = 1f;
            m_PassByAudioSource.maxDistance = maxPassByDistance;
            m_PassByAudioSource.rolloffMode = AudioRolloffMode.Linear;
        }
    }

    private void FindPlayer()
    {
        GameObject playerObject = GameObject.FindGameObjectWithTag("Player");
        if (playerObject != null) m_PlayerTransform = playerObject.transform;
    }

    private void UpdatePassBySound()
    {
        if (m_PassByAudioSource == null || m_PlayerTransform == null) return;

        float distanceToPlayer = Vector3.Distance(transform.position, m_PlayerTransform.position);
        if (distanceToPlayer <= maxPassByDistance)
        {
            if (!m_PassByAudioSource.isPlaying) m_PassByAudioSource.Play();
            m_PassByAudioSource.volume = 1f - (distanceToPlayer / maxPassByDistance);
        }
        else
        {
            m_PassByAudioSource.Stop();
        }
    }

    private IEnumerator LifetimeCoroutine()
    {
        yield return new WaitForSeconds(lifetime);
        ReturnToPool();
    }

    private void ReturnToPool()
    {
        if (m_PassByAudioSource != null) m_PassByAudioSource.Stop();
        PoolManager.Instance.Release(gameObject);
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        Vector3 pos = transform.position;

        // --- Velocity arrow ---
        if (m_Rigidbody != null)
        {
            Gizmos.color = Color.red;
            Vector3 vel = m_Rigidbody.linearVelocity;
            Gizmos.DrawLine(pos, pos + vel.normalized * 3f);
            Gizmos.DrawWireSphere(pos + vel.normalized * 3f, 0.1f);
        }

        // --- Lane target X ---
        Gizmos.color = m_IsChangingLane ? Color.yellow : Color.green;
        Vector3 laneTarget = new Vector3(m_TargetX, pos.y, pos.z);
        Gizmos.DrawWireSphere(laneTarget, 0.3f);
        if (m_IsChangingLane)
        {
            Gizmos.DrawLine(pos, laneTarget);
        }

        // --- Pass-by audio range ---
        Gizmos.color = new Color(1f, 0.5f, 0f, 0.15f);
        Gizmos.DrawWireSphere(pos, maxPassByDistance);

        // --- Forward direction ---
        Gizmos.color = new Color(1f, 0.3f, 0.3f, 0.8f);
        Gizmos.DrawLine(pos, pos + Vector3.back * 4f);

        // --- State label ---
        string stateName = m_CurrentState != null ? m_CurrentState.GetType().Name : "null";
        UnityEditor.Handles.color = Color.red;
        UnityEditor.Handles.Label(pos + Vector3.up * 2f, $"State: {stateName}\nLane: {m_CurrentLane}\nSpeed: {speed:F1}");
    }
#endif
    #endregion
}

#region Enemy Ship State Machine & Observer Interfaces
public interface IEnemyShipState
{
    void Update();
}

public class CruisingState : IEnemyShipState
{
    private EnemyShip m_EnemyShip;

    public CruisingState(EnemyShip _ship)
    {
        m_EnemyShip = _ship;
    }

    public void Update()
    {
        m_EnemyShip.MoveForward();
    }
}

public class AvoidingState : IEnemyShipState
{
    private EnemyShip m_EnemyShip;
    private float m_AvoidanceTimer;

    public AvoidingState(EnemyShip _ship)
    {
        m_EnemyShip = _ship;
        m_AvoidanceTimer = 0.5f;
        int direction = Random.value < 0.5f ? -1 : 1;
        m_EnemyShip.ChangeLane(direction);
    }

    public void Update()
    {
        m_EnemyShip.MoveForward();
        m_AvoidanceTimer -= Time.deltaTime;
        if (m_AvoidanceTimer <= 0)
        {
            m_EnemyShip.SetState(new CruisingState(m_EnemyShip));
        }
    }
}

public interface IEnemyShipObserver
{
    void OnEnemyShipMoved(EnemyShip _ship);
}
#endregion
