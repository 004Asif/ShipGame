using UnityEngine;

public class StarCollectionParticleSystem : MonoBehaviour
{
    private ParticleSystem starParticleSystem;
    public float duration = 0.5f;

    private void Awake()
    {
        starParticleSystem = GetComponent<ParticleSystem>();
        if (starParticleSystem == null)
        {
            Debug.LogError("ParticleSystem component not found on " + gameObject.name);
        }
    }

    public void Play(Vector3 position)
    {
        if (starParticleSystem != null)
        {
            transform.position = position;
            starParticleSystem.Play();
            Invoke("Stop", duration);
        }
    }

    private void Stop()
    {
        if (starParticleSystem != null)
        {
            starParticleSystem.Stop();
        }
    }
}