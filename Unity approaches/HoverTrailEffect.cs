using UnityEngine;

/// <summary>
/// Creates a dust/spark particle trail below the ship that reacts to hover height.
/// Closer to ground = more particles, faster speed, larger size.
/// Attach to the player ship. Creates a child ParticleSystem at runtime if none assigned.
/// </summary>
public class HoverTrailEffect : MonoBehaviour
{
    #region Serialized Fields
    [Header("Particle Reference")]
    [SerializeField, Tooltip("Assign an existing ParticleSystem, or leave null to auto-create one")]
    private ParticleSystem m_TrailParticles;

    [Header("Height Response")]
    [SerializeField, Tooltip("Below this height, particles are at full intensity")]
    private float m_MinHeight = 0.5f;
    [SerializeField, Tooltip("Above this height, particles fade to zero")]
    private float m_MaxHeight = 3f;

    [Header("Emission")]
    [SerializeField] private float m_MaxEmissionRate = 80f;
    [SerializeField] private float m_MaxStartSpeed = 3f;
    [SerializeField] private float m_MaxStartSize = 0.3f;

    [Header("Raycast")]
    [SerializeField] private LayerMask m_GroundMask = ~0;
    [SerializeField] private float m_RaycastDistance = 10f;
    #endregion

    #region Private Fields
    private ParticleSystem.EmissionModule m_Emission;
    private ParticleSystem.MainModule m_Main;
    private RaycastHit m_HitInfo;
    private bool m_IsGrounded;
    #endregion

    #region Unity Lifecycle
    private void Start()
    {
        if (m_TrailParticles == null)
        {
            CreateDefaultParticleSystem();
        }

        m_Emission = m_TrailParticles.emission;
        m_Main = m_TrailParticles.main;
    }

    private void Update()
    {
        m_IsGrounded = Physics.Raycast(transform.position, Vector3.down, out m_HitInfo, m_RaycastDistance, m_GroundMask, QueryTriggerInteraction.Ignore);

        if (m_IsGrounded)
        {
            float currentHeight = transform.position.y - m_HitInfo.point.y;
            float t = 1f - Mathf.InverseLerp(m_MinHeight, m_MaxHeight, currentHeight);

            m_Emission.rateOverTime = t * m_MaxEmissionRate;
            m_Main.startSpeed = t * m_MaxStartSpeed;
            m_Main.startSize = Mathf.Lerp(0.05f, m_MaxStartSize, t);

            // Position particles at the ground hit point
            m_TrailParticles.transform.position = m_HitInfo.point + Vector3.up * 0.05f;

            if (!m_TrailParticles.isPlaying && t > 0.01f)
                m_TrailParticles.Play();
        }
        else
        {
            m_Emission.rateOverTime = 0f;
            if (m_TrailParticles.isPlaying)
                m_TrailParticles.Stop(true, ParticleSystemStopBehavior.StopEmitting);
        }
    }
    #endregion

    #region Private Methods
    private void CreateDefaultParticleSystem()
    {
        GameObject particleObj = new GameObject("HoverTrail");
        particleObj.transform.SetParent(transform, false);
        particleObj.transform.localPosition = Vector3.down * 0.5f;

        m_TrailParticles = particleObj.AddComponent<ParticleSystem>();

        // Configure main module
        var main = m_TrailParticles.main;
        main.startLifetime = 0.6f;
        main.startSpeed = 1f;
        main.startSize = 0.15f;
        main.startColor = new Color(0.8f, 0.7f, 0.5f, 0.4f);
        main.simulationSpace = ParticleSystemSimulationSpace.World;
        main.maxParticles = 200;
        main.gravityModifier = -0.2f;

        // Shape: small cone pointing down
        var shape = m_TrailParticles.shape;
        shape.shapeType = ParticleSystemShapeType.Cone;
        shape.angle = 25f;
        shape.radius = 0.3f;
        shape.rotation = new Vector3(90f, 0f, 0f);

        // Emission
        var emission = m_TrailParticles.emission;
        emission.rateOverTime = 0f;

        // Size over lifetime: shrink
        var sizeOverLifetime = m_TrailParticles.sizeOverLifetime;
        sizeOverLifetime.enabled = true;
        AnimationCurve sizeCurve = new AnimationCurve();
        sizeCurve.AddKey(0f, 1f);
        sizeCurve.AddKey(1f, 0f);
        sizeOverLifetime.size = new ParticleSystem.MinMaxCurve(1f, sizeCurve);

        // Color over lifetime: fade out
        var colorOverLifetime = m_TrailParticles.colorOverLifetime;
        colorOverLifetime.enabled = true;
        Gradient gradient = new Gradient();
        gradient.SetKeys(
            new GradientColorKey[] { new GradientColorKey(Color.white, 0f), new GradientColorKey(Color.white, 1f) },
            new GradientAlphaKey[] { new GradientAlphaKey(0.5f, 0f), new GradientAlphaKey(0f, 1f) }
        );
        colorOverLifetime.color = gradient;

        // Use default particle material (additive)
        var renderer = particleObj.GetComponent<ParticleSystemRenderer>();
        renderer.material = new Material(Shader.Find("Particles/Standard Unlit"));
        renderer.material.SetFloat("_Mode", 1); // Additive
    }
    #endregion
}
