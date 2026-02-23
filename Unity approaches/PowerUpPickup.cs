using UnityEngine;

public class PowerUpPickup : MonoBehaviour
{
    [Header("Configuration")]
    [SerializeField] private PowerUpEffectSO powerUpEffect;

    [Header("Event Channel to Raise")]
    [SerializeField] private PowerUpGameEvent onPowerUpCollected; // Changed to our new event type

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            if (onPowerUpCollected != null)
            {
                // We call the Raise method directly on the event asset.
                onPowerUpCollected.Raise(powerUpEffect);
            }
            // Using the pool manager is better than Destroy
            PoolManager.Instance.Release(gameObject);
        }
    }
}
