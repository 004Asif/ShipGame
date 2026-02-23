// Replace the entire content of PlayerProfileUI.cs
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class PlayerProfileUI : MonoBehaviour
{
    [Header("Data Source")]
    [SerializeField] private PlayerProfileSO playerProfileData;

    [Header("UI Elements")]
    public TextMeshProUGUI playerNameText;
    public TextMeshProUGUI totalScoreText;
    public TextMeshProUGUI starsCollectedText;
    public TextMeshProUGUI totalDistanceText;
    // Other UI elements like ship selection would be refactored similarly

    private void OnEnable()
    {
        UpdateUI();
    }

    public void UpdateUI()
    {
        if (playerProfileData == null) return;

        if (playerNameText != null) playerNameText.text = $"Name: {playerProfileData.playerName}";
        if (totalScoreText != null) totalScoreText.text = $"Total Score: {playerProfileData.totalScore}";
        if (starsCollectedText != null) starsCollectedText.text = $"Stars: {playerProfileData.starsCollected}";
        if (totalDistanceText != null) totalDistanceText.text = $"Distance: {playerProfileData.totalDistance:F2} km";
    }
}