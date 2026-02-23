using UnityEngine;

/// <summary>
/// Lightweight game manager — no scene loading, no DontDestroyOnLoad.
/// Lives in the single scene. Delegates flow to GameFlowController.
/// Keeps GameState enum for backward compatibility with AudioManager and other listeners.
/// </summary>
public class GameManager : MonoBehaviour
{
    #region Singleton
    public static GameManager Instance { get; private set; }
    #endregion

    #region Enums
    public enum GameState { MainMenu, Playing, Paused, GameOver }
    #endregion

    #region Public Properties
    public GameState CurrentState { get; private set; }
    public float FinalScore { get; private set; }
    #endregion

    #region Serialized Fields
    [Header("Data & Managers")]
    [SerializeField] private PlayerProfileSO playerProfileData;
    [SerializeField] private PlayerProfile playerProfileManager;
    [SerializeField] private bool testMode = false;
    #endregion

    #region Private Fields
    private const string c_FirstTimePlayKey = "FirstTimePlay";
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
            return;
        }

        if (playerProfileManager == null)
        {
            playerProfileManager = FindAnyObjectByType<PlayerProfile>();
        }
    }

    private void OnEnable()
    {
        GameFlowController.OnPhaseChanged += HandlePhaseChanged;
    }

    private void OnDisable()
    {
        GameFlowController.OnPhaseChanged -= HandlePhaseChanged;
    }

    private void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
    #endregion

    #region Phase → GameState Bridge
    /// <summary>
    /// Maps GameFlowController phases to the legacy GameState enum
    /// so AudioManager and other listeners keep working unchanged.
    /// </summary>
    private void HandlePhaseChanged(GameFlowController.GamePhase _phase)
    {
        switch (_phase)
        {
            case GameFlowController.GamePhase.Boot:
            case GameFlowController.GamePhase.Menu:
                SetGameState(GameState.MainMenu);
                break;

            case GameFlowController.GamePhase.Intro:
            case GameFlowController.GamePhase.Playing:
                SetGameState(GameState.Playing);
                break;

            case GameFlowController.GamePhase.Paused:
                SetGameState(GameState.Paused);
                break;

            case GameFlowController.GamePhase.GameOver:
                SetGameState(GameState.GameOver);
                break;
        }
    }
    #endregion

    #region Public API — called by GameEvent listeners (backward compatible)
    /// <summary>Called by the EndGameEvent listener (e.g. onPlayerDied).</summary>
    public void OnGameEnded()
    {
        if (GameFlowController.Instance != null)
        {
            GameFlowController.Instance.TriggerGameOver();
        }
    }

    /// <summary>Called by the StartGameEvent listener (e.g. Play button or Play Again).</summary>
    public void OnGameStarted()
    {
        if (GameFlowController.Instance == null) return;

        // If we're in GameOver, this is a "Play Again" — use RestartGame
        if (GameFlowController.Instance.CurrentPhase == GameFlowController.GamePhase.GameOver)
        {
            GameFlowController.Instance.RestartGame();
        }
        else
        {
            GameFlowController.Instance.StartGame();
        }
    }

    /// <summary>Called by the ReturnToMainMenuEvent listener.</summary>
    public void OnReturnToMainMenu()
    {
        if (GameFlowController.Instance != null)
        {
            GameFlowController.Instance.ReturnToMenu();
        }
    }

    public void TogglePause()
    {
        if (GameFlowController.Instance != null)
        {
            GameFlowController.Instance.TogglePause();
        }
    }
    #endregion

    #region State Management
    private void SetGameState(GameState _newState)
    {
        CurrentState = _newState;

        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.HandleGameStateChange(_newState);
        }

        switch (_newState)
        {
            case GameState.GameOver:
                if (ScoreManager.Instance != null)
                {
                    FinalScore = ScoreManager.Instance.GetCurrentScore();
                }
                else
                {
                    FinalScore = 0;
                }
                UpdatePlayerProfileData();
                break;
        }
    }
    #endregion

    #region Profile Data
    private void UpdatePlayerProfileData()
    {
        if (playerProfileData != null)
        {
            playerProfileData.AddScore(Mathf.FloorToInt(FinalScore));
        }

        if (playerProfileManager != null)
        {
            playerProfileManager.SaveData();
        }
        else
        {
            Debug.LogError("PlayerProfile Manager is not assigned in GameManager. Cannot save data.");
        }
    }
    #endregion

    #region First Time Play
    public bool IsFirstTimePlay()
    {
        return testMode || !PlayerPrefs.HasKey(c_FirstTimePlayKey);
    }

    public void SetFirstTimePlayComplete()
    {
        if (!testMode)
        {
            PlayerPrefs.SetInt(c_FirstTimePlayKey, 1);
            PlayerPrefs.Save();
        }
    }

    public void ToggleTestMode()
    {
        testMode = !testMode;
        Debug.Log($"Test Mode: {(testMode ? "Enabled" : "Disabled")}");
    }
    #endregion
}