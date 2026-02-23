using UnityEngine;

public class ShipEngineParticles : MonoBehaviour
{
    [Header("Required Components")]
    [SerializeField] private ShipController shipController;
    [SerializeField] private ShipDataSO shipData; // ADDED: Reference to the Ship Data SO
    [SerializeField] private ParticleSystem engineParticles;
    
    [Header("Particle Settings")]
    [SerializeField] private float minEmissionRate = 10f;
    [SerializeField] private float maxEmissionRate = 50f;
    [SerializeField] private float minStartSpeed = 0.5f;
    [SerializeField] private float maxStartSpeed = 2f;

    private ParticleSystem.EmissionModule emissionModule;
    private ParticleSystem.MainModule mainModule;

    private void Start()
    {
        if (engineParticles == null)
        {
            engineParticles = GetComponent<ParticleSystem>();
        }

        if (shipController == null)
        {
            shipController = GetComponentInParent<ShipController>();
        }

        emissionModule = engineParticles.emission;
        mainModule = engineParticles.main;

        SetupParticleSystem();
    }

    private void Update()
    {
        if (shipController == null || shipData == null) return;
        UpdateParticleSystem();
    }


    private void SetupParticleSystem()
    {
        mainModule.startLifetime = 0.5f;
        mainModule.startSize = 0.2f;
        mainModule.startColor = new ParticleSystem.MinMaxGradient(Color.yellow, new Color(1f, 0.5f, 0f));

        var shapeModule = engineParticles.shape;
        shapeModule.shapeType = ParticleSystemShapeType.Cone;
        shapeModule.angle = 15f;

        var colorOverLifetime = engineParticles.colorOverLifetime;
        colorOverLifetime.enabled = true;
        Gradient gradient = new Gradient();
        gradient.SetKeys(
            new GradientColorKey[] { new GradientColorKey(Color.yellow, 0.0f), new GradientColorKey(new Color(1f, 0.5f, 0f), 0.5f), new GradientColorKey(Color.red, 1.0f) },
            new GradientAlphaKey[] { new GradientAlphaKey(1.0f, 0.0f), new GradientAlphaKey(0.5f, 0.5f), new GradientAlphaKey(0.0f, 1.0f) }
        );
        colorOverLifetime.color = gradient;

        var sizeOverLifetime = engineParticles.sizeOverLifetime;
        sizeOverLifetime.enabled = true;
        sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f, 0f);
    }

   private void UpdateParticleSystem()
    {
        // CORRECTED: Get maxVisualSpeed from shipData, not shipController
        float speedRatio = Mathf.Clamp01(shipController.CurrentVisualSpeed / shipData.maxVisualSpeed);
        float currentEmissionRate = Mathf.Lerp(minEmissionRate, maxEmissionRate, speedRatio);
        float currentStartSpeed = Mathf.Lerp(minStartSpeed, maxStartSpeed, speedRatio);

        emissionModule.rateOverTime = currentEmissionRate;
        mainModule.startSpeed = currentStartSpeed;
    }
}