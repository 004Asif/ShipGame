using UnityEngine;

public class ScoreMultiplierZone : MonoBehaviour
{
    #region Serialized Fields
    [SerializeField, Range(1f, 5f)] private float m_Multiplier = 2f;
    [SerializeField] private float m_Duration = 5f;
    [SerializeField] private Color m_ActiveColor = Color.green;
    #endregion

    #region Private Fields
    private Renderer m_Renderer;
    private Color m_OriginalColor;
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        m_Renderer = GetComponent<Renderer>();
        if (m_Renderer != null) m_OriginalColor = m_Renderer.material.color;
    }

    private void OnTriggerEnter(Collider _other)
    {
        if (_other.CompareTag("Player"))
        {
            if (ScoreManager.Instance != null)
            {
                ScoreManager.Instance.ActivateScoreMultiplier(m_Multiplier, m_Duration);
            }

            if (m_Renderer != null) m_Renderer.material.color = m_ActiveColor;
            Invoke(nameof(ResetColor), m_Duration);
        }
    }
    #endregion

    #region Private Methods
    private void ResetColor()
    {
        if (m_Renderer != null) m_Renderer.material.color = m_OriginalColor;
    }
    #endregion
}