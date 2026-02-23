// Replace the entire content of ExplosionEffect.cs
using UnityEngine;
using System.Collections;

public class ExplosionEffect : MonoBehaviour
{
    public ParticleSystem explosionParticles;
    public float explosionDuration = 2f;

    private void OnEnable()
    {
        // Play particles when the object is enabled from the pool
        if (explosionParticles != null)
        {
            explosionParticles.Play();
        }
        StartCoroutine(ReturnToPoolAfterDelay());
    }

    private IEnumerator ReturnToPoolAfterDelay()
    {
        yield return new WaitForSeconds(explosionDuration);
        // Release this object back to the pool
        PoolManager.Instance.Release(gameObject);
    }
}