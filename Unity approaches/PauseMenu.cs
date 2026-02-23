using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Pause menu — no scene loading. Delegates to GameFlowController for pause/resume/menu.
/// Panel visibility is managed by GameFlowController via SetPanelStates,
/// but we also listen to Escape key for convenience.
/// </summary>
public class PauseMenu : MonoBehaviour
{
    #region Serialized Fields
    public Button resumeButton;
    public Button mainMenuButton;
    #endregion

    #region Unity Lifecycle
    private void Start()
    {
        if (resumeButton != null) resumeButton.onClick.AddListener(ResumeGame);
        if (mainMenuButton != null) mainMenuButton.onClick.AddListener(ReturnToMainMenu);
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            TogglePause();
        }
    }

    private void OnDestroy()
    {
        if (resumeButton != null) resumeButton.onClick.RemoveListener(ResumeGame);
        if (mainMenuButton != null) mainMenuButton.onClick.RemoveListener(ReturnToMainMenu);
    }
    #endregion

    #region Private Methods
    private void TogglePause()
    {
        if (GameFlowController.Instance != null)
        {
            GameFlowController.Instance.TogglePause();
        }
    }

    private void ResumeGame()
    {
        TogglePause();
    }

    private void ReturnToMainMenu()
    {
        if (GameFlowController.Instance != null)
        {
            GameFlowController.Instance.ReturnToMenu();
        }
    }
    #endregion
}