using UnityEngine;
using System.Collections;

public class ScoreManager : MonoBehaviour
{
    #region Singleton
    public static ScoreManager Instance { get; private set; }
    #endregion

    #region Serialized Fields
    [Header("Data Variables")]
    [SerializeField] private FloatVariable currentScore;
    [SerializeField] private IntVariable starsCollected;

    [Header("Scoring Settings")]
    [SerializeField] private int pointsPerStar = 10;
    #endregion

    #region Private Fields
    private float m_ScoreMultiplier = 1f;
    private Coroutine m_MultiplierCoroutine;
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
    #endregion

    #region Public Methods
    public void HandleStarCollected()
    {
        if (starsCollected != null) starsCollected.value++;
        if (currentScore != null) currentScore.value += pointsPerStar * m_ScoreMultiplier;

        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.Play(AudioEvents.StarCollected);
        }
    }

    public void ResetScore()
    {
        if (currentScore != null) currentScore.value = 0;
        if (starsCollected != null) starsCollected.value = 0;
        m_ScoreMultiplier = 1f;

        if (m_MultiplierCoroutine != null)
        {
            StopCoroutine(m_MultiplierCoroutine);
            m_MultiplierCoroutine = null;
        }
    }

    public float GetCurrentScore()
    {
        return currentScore != null ? currentScore.value : 0f;
    }

    public void AddNearMissBonus(int _points)
    {
        if (currentScore != null) currentScore.value += _points * m_ScoreMultiplier;
    }

    public void ActivateScoreMultiplier(float _multiplier, float _duration)
    {
        if (m_MultiplierCoroutine != null)
        {
            StopCoroutine(m_MultiplierCoroutine);
        }
        m_MultiplierCoroutine = StartCoroutine(ScoreMultiplierCoroutine(_multiplier, _duration));
    }
    #endregion

    #region Private Methods
    private IEnumerator ScoreMultiplierCoroutine(float _multiplier, float _duration)
    {
        m_ScoreMultiplier = _multiplier;
        yield return new WaitForSeconds(_duration);
        m_ScoreMultiplier = 1f;
        m_MultiplierCoroutine = null;
    }
    #endregion
}





