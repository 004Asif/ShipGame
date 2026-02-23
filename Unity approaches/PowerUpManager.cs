using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class PowerUpManager : MonoBehaviour
{
    #region Serialized Fields
    [Header("Event Channel to Listen to")]
    [SerializeField] private PowerUpGameEvent onPowerUpCollected;
    #endregion

    #region Private Fields
    private ShipController m_ShipController;
    private Dictionary<PowerUpType, Coroutine> m_ActivePowerUps = new Dictionary<PowerUpType, Coroutine>();
    private Coroutine m_MagnetCoroutine;

    // Cached array to avoid per-frame allocation in magnet
    private static readonly Collider[] s_MagnetResults = new Collider[32];
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        m_ShipController = GetComponent<ShipController>();
    }

    private void OnEnable()
    {
        if (onPowerUpCollected != null)
        {
            onPowerUpCollected.OnEventRaised += ActivatePowerUp;
        }
    }

    private void OnDisable()
    {
        if (onPowerUpCollected != null)
        {
            onPowerUpCollected.OnEventRaised -= ActivatePowerUp;
        }
    }
    #endregion

    #region Public Methods
    public void ActivatePowerUp(PowerUpEffectSO _powerUpEffect)
    {
        if (_powerUpEffect == null) return;

        // If this type is already active, stop it and restart with fresh duration
        if (m_ActivePowerUps.TryGetValue(_powerUpEffect.type, out Coroutine existing))
        {
            StopCoroutine(existing);
            DeactivateEffect(_powerUpEffect);
            m_ActivePowerUps.Remove(_powerUpEffect.type);
        }

        Coroutine powerUpCoroutine = StartCoroutine(PowerUpCoroutine(_powerUpEffect));
        m_ActivePowerUps[_powerUpEffect.type] = powerUpCoroutine;
    }

    public bool IsPowerUpActive(PowerUpType _type)
    {
        return m_ActivePowerUps.ContainsKey(_type);
    }
    #endregion

    #region Private Methods
    private IEnumerator PowerUpCoroutine(PowerUpEffectSO _effect)
    {
        ActivateEffect(_effect);
        yield return new WaitForSeconds(_effect.duration);
        DeactivateEffect(_effect);
        m_ActivePowerUps.Remove(_effect.type);
    }

    private void ActivateEffect(PowerUpEffectSO _effect)
    {
        if (m_ShipController == null) return;

        switch (_effect.type)
        {
            case PowerUpType.Shield:
                m_ShipController.SetShieldActive(true);
                break;

            case PowerUpType.SpeedBoost:
                m_ShipController.SetSpeed(m_ShipController.CurrentSpeed * _effect.speedMultiplier);
                break;

            case PowerUpType.MagnetCollector:
                if (m_MagnetCoroutine != null) StopCoroutine(m_MagnetCoroutine);
                m_MagnetCoroutine = StartCoroutine(MagnetCollectorRoutine(_effect));
                break;

            case PowerUpType.Boost:
                m_ShipController.ActivateBoost();
                break;
        }

        HapticFeedback.MediumVibration();
    }

    private void DeactivateEffect(PowerUpEffectSO _effect)
    {
        if (m_ShipController == null) return;

        switch (_effect.type)
        {
            case PowerUpType.Shield:
                m_ShipController.SetShieldActive(false);
                break;

            case PowerUpType.SpeedBoost:
                m_ShipController.ResetToDefaultSpeed();
                break;

            case PowerUpType.MagnetCollector:
                if (m_MagnetCoroutine != null)
                {
                    StopCoroutine(m_MagnetCoroutine);
                    m_MagnetCoroutine = null;
                }
                break;

            case PowerUpType.Boost:
                // Boost handles its own duration via ShipController
                break;
        }
    }

    private IEnumerator MagnetCollectorRoutine(PowerUpEffectSO _effect)
    {
        float elapsedTime = 0f;
        while (elapsedTime < _effect.duration)
        {
            AttractNearbyCollectibles(_effect.attractionRadius, _effect.attractionSpeed);
            elapsedTime += Time.deltaTime;
            yield return null;
        }
        m_MagnetCoroutine = null;
    }

    private void AttractNearbyCollectibles(float _radius, float _speed)
    {
        int count = Physics.OverlapSphereNonAlloc(transform.position, _radius, s_MagnetResults);

        for (int i = 0; i < count; i++)
        {
            Collider col = s_MagnetResults[i];
            if (col == null || !col.gameObject.activeInHierarchy) continue;
            if (!col.CompareTag("Collectible")) continue;

            Transform collectibleTransform = col.transform;
            Vector3 direction = (transform.position - collectibleTransform.position);
            float distance = direction.magnitude;

            if (distance < 0.5f)
            {
                // Close enough — collect it
                ShipController sc = m_ShipController;
                if (sc != null)
                {
                    col.gameObject.SendMessage("OnMagnetCollected", SendMessageOptions.DontRequireReceiver);
                }
                PoolManager.Instance.Release(col.gameObject);
            }
            else
            {
                // Pull collectible toward ship using physics forces
                Rigidbody collectibleRb = col.attachedRigidbody;
                if (collectibleRb != null && !collectibleRb.isKinematic)
                {
                    // Force increases as collectible gets closer (inverse distance)
                    float pullStrength = _speed * (1f + (_radius - distance) / _radius);
                    Vector3 pullForce = direction.normalized * pullStrength;
                    collectibleRb.AddForce(pullForce, ForceMode.Acceleration);
                }
                else
                {
                    // Fallback for kinematic collectibles — move directly
                    float pullStrength = _speed * (1f + (_radius - distance) / _radius);
                    collectibleTransform.position = Vector3.MoveTowards(
                        collectibleTransform.position,
                        transform.position,
                        pullStrength * Time.deltaTime
                    );
                }
            }
        }
    }
    #endregion

    #region Debug Gizmos
#if UNITY_EDITOR
    private void OnDrawGizmos()
    {
        Vector3 pos = transform.position;

        // --- Active power-ups label ---
        if (m_ActivePowerUps != null && m_ActivePowerUps.Count > 0)
        {
            string activeList = "";
            foreach (var kvp in m_ActivePowerUps)
            {
                activeList += kvp.Key.ToString() + "\n";
            }
            UnityEditor.Handles.color = Color.green;
            UnityEditor.Handles.Label(pos + Vector3.up * 3.5f, $"PowerUps:\n{activeList}");
        }

        // --- Magnet attraction radius ---
        if (m_MagnetCoroutine != null)
        {
            Gizmos.color = new Color(1f, 0f, 1f, 0.15f);
            Gizmos.DrawWireSphere(pos, 15f);
            Gizmos.color = new Color(1f, 0f, 1f, 0.05f);
            Gizmos.DrawSphere(pos, 15f);
        }

        // --- Shield indicator ---
        if (m_ActivePowerUps != null && m_ActivePowerUps.ContainsKey(PowerUpType.Shield))
        {
            Gizmos.color = new Color(0f, 0.8f, 1f, 0.2f);
            Gizmos.DrawWireSphere(pos, 1.5f);
        }
    }
#endif
    #endregion
}