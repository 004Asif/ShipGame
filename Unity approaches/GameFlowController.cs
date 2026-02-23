using UnityEngine;
using System;
using System.Collections;

/// <summary>
/// Single-scene game flow orchestrator (Subway Surfers style).
/// Manages all game phases: Boot → Menu → Intro → Playing → GameOver → Menu.
/// Place on a root GameObject in the single scene alongside all managers.
/// </summary>
public class GameFlowController : MonoBehaviour
{
    #region Singleton
    public static GameFlowController Instance { get; private set; }
    #endregion

    #region Enums
    public enum GamePhase { Boot, Menu, Intro, Playing, Paused, GameOver }
    #endregion

    #region Events
    /// <summary>Fired whenever the phase changes. Subscribe from UI panels, managers, etc.</summary>
    public static event Action<GamePhase> OnPhaseChanged;
    #endregion

    #region Serialized Fields
    [Header("Phase Timing")]
    [SerializeField, Tooltip("How long the boot/splash screen stays visible")]
    private float m_BootDuration = 2f;
    [SerializeField, Tooltip("Duration of the intro camera swoop before gameplay starts")]
    private float m_IntroDuration = 2f;
    [SerializeField, Tooltip("Delay after death before showing game-over panel")]
    private float m_GameOverDelay = 1.5f;

    [Header("UI Panels — assign in Inspector")]
    [SerializeField] private GameObject m_BootPanel;
    [SerializeField] private GameObject m_MainMenuPanel;
    [SerializeField] private GameObject m_EndGamePanel;
    [SerializeField] private GameObject m_GameHUDPanel;
    [SerializeField] private GameObject m_PausePanel;

    [Header("Camera")]
    [SerializeField] private CameraFollow m_CameraFollow;
    [SerializeField, Tooltip("Camera position/rotation when in menu (world space)")]
    private Transform m_MenuCameraAnchor;

    [Header("References")]
    [SerializeField] private ShipSpawner m_ShipSpawner;
    [SerializeField] private LevelGenerator m_LevelGenerator;
    #endregion

    #region Public Properties
    public GamePhase CurrentPhase { get; private set; } = GamePhase.Boot;
    #endregion

    #region Private Fields
    private Coroutine m_ActiveTransition;
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
    }

    private void Start()
    {
        // Start the boot sequence
        EnterPhase(GamePhase.Boot);
    }

    private void OnDestroy()
    {
        if (Instance == this) Instance = null;
    }
    #endregion

    #region Public API
    /// <summary>Called by "Play" button on the main menu.</summary>
    public void StartGame()
    {
        if (CurrentPhase != GamePhase.Menu) return;
        EnterPhase(GamePhase.Intro);
    }

    /// <summary>Called by GameManager when the player dies.</summary>
    public void TriggerGameOver()
    {
        if (CurrentPhase != GamePhase.Playing) return;
        EnterPhase(GamePhase.GameOver);
    }

    /// <summary>Called by "Play Again" button on the game-over panel.</summary>
    public void RestartGame()
    {
        if (CurrentPhase != GamePhase.GameOver && CurrentPhase != GamePhase.Menu) return;
        CleanUpGameplay();
        EnterPhase(GamePhase.Intro);
    }

    /// <summary>Called by "Main Menu" button on game-over or pause panels.</summary>
    public void ReturnToMenu()
    {
        CleanUpGameplay();
        Time.timeScale = 1f;
        EnterPhase(GamePhase.Menu);
    }

    /// <summary>Toggle pause during gameplay.</summary>
    public void TogglePause()
    {
        if (CurrentPhase == GamePhase.Playing)
        {
            EnterPhase(GamePhase.Paused);
        }
        else if (CurrentPhase == GamePhase.Paused)
        {
            EnterPhase(GamePhase.Playing);
        }
    }
    #endregion

    #region Phase Management
    private void EnterPhase(GamePhase _newPhase)
    {
        // Stop any running transition coroutine
        if (m_ActiveTransition != null)
        {
            StopCoroutine(m_ActiveTransition);
            m_ActiveTransition = null;
        }

        CurrentPhase = _newPhase;

        // Update all UI panels
        SetPanelStates(_newPhase);

        switch (_newPhase)
        {
            case GamePhase.Boot:
                m_ActiveTransition = StartCoroutine(BootSequence());
                break;

            case GamePhase.Menu:
                OnEnterMenu();
                break;

            case GamePhase.Intro:
                m_ActiveTransition = StartCoroutine(IntroSequence());
                break;

            case GamePhase.Playing:
                OnEnterPlaying();
                break;

            case GamePhase.Paused:
                Time.timeScale = 0f;
                break;

            case GamePhase.GameOver:
                m_ActiveTransition = StartCoroutine(GameOverSequence());
                break;
        }

        // Notify listeners
        OnPhaseChanged?.Invoke(_newPhase);

        Debug.Log($"[GameFlow] Phase → {_newPhase}");
    }

    private void SetPanelStates(GamePhase _phase)
    {
        if (m_BootPanel != null) m_BootPanel.SetActive(_phase == GamePhase.Boot);
        if (m_MainMenuPanel != null) m_MainMenuPanel.SetActive(_phase == GamePhase.Menu);
        if (m_EndGamePanel != null) m_EndGamePanel.SetActive(_phase == GamePhase.GameOver);
        if (m_GameHUDPanel != null) m_GameHUDPanel.SetActive(_phase == GamePhase.Playing || _phase == GamePhase.Paused);
        if (m_PausePanel != null) m_PausePanel.SetActive(_phase == GamePhase.Paused);
    }
    #endregion

    #region Phase Sequences
    private IEnumerator BootSequence()
    {
        // Position camera at menu anchor during boot
        if (m_MenuCameraAnchor != null && m_CameraFollow != null)
        {
            m_CameraFollow.SetMenuMode(m_MenuCameraAnchor);
        }

        // Wait for boot duration (splash screen, data loading, ad SDK init)
        yield return new WaitForSeconds(m_BootDuration);

        m_ActiveTransition = null;
        EnterPhase(GamePhase.Menu);
    }

    private void OnEnterMenu()
    {
        Time.timeScale = 1f;

        // Camera goes to menu position
        if (m_MenuCameraAnchor != null && m_CameraFollow != null)
        {
            m_CameraFollow.SetMenuMode(m_MenuCameraAnchor);
        }
    }

    private IEnumerator IntroSequence()
    {
        // 1. Spawn ship (kinematic, no gravity, controller disabled)
        if (m_ShipSpawner != null)
        {
            m_ShipSpawner.SpawnShip();
        }

        // Wait a frame for ship to be instantiated
        yield return null;

        // 2. Start level generation (safe zone first)
        if (m_LevelGenerator != null && m_ShipSpawner != null && m_ShipSpawner.CurrentShip != null)
        {
            m_LevelGenerator.SetPlayerAndStart(m_ShipSpawner.CurrentShip.transform);
        }

        // 3. Begin smooth ship descent animation (kinematic lerp to hover height)
        if (m_ShipSpawner != null && m_ShipSpawner.CurrentShip != null)
        {
            m_ShipSpawner.BeginIntroAnimation(m_IntroDuration);
        }

        // 4. Camera swoops from menu position to behind-ship chase position
        if (m_CameraFollow != null && m_ShipSpawner != null && m_ShipSpawner.CurrentShip != null)
        {
            m_CameraFollow.TransitionToChaseMode(m_ShipSpawner.CurrentShip.transform, m_IntroDuration);
        }

        // 5. Wait for the intro animation to finish
        yield return new WaitForSeconds(m_IntroDuration);

        m_ActiveTransition = null;

        // 6. Enable gameplay
        EnterPhase(GamePhase.Playing);
    }

    private void OnEnterPlaying()
    {
        Time.timeScale = 1f;

        // Transition ship from kinematic intro to full physics gameplay
        if (m_ShipSpawner != null)
        {
            m_ShipSpawner.EnableShipPhysics();
        }
    }

    private IEnumerator GameOverSequence()
    {
        // Wait a moment for explosion/death to play out
        yield return new WaitForSeconds(m_GameOverDelay);

        m_ActiveTransition = null;

        // Show end game panel (already done by SetPanelStates, but we delayed)
        if (m_EndGamePanel != null) m_EndGamePanel.SetActive(true);
    }
    #endregion

    #region Cleanup
    private void CleanUpGameplay()
    {
        // Destroy the ship
        if (m_ShipSpawner != null)
        {
            m_ShipSpawner.DestroyShip();
        }

        // Reset level generator — return all objects and tiles to pools
        if (m_LevelGenerator != null)
        {
            m_LevelGenerator.ResetAndStop();
        }

        // Reset score
        if (ScoreManager.Instance != null)
        {
            ScoreManager.Instance.ResetScore();
        }
    }
    #endregion
}
