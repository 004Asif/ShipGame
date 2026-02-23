// Replace the entire content of PlayerProfile.cs
using UnityEngine;

public class PlayerProfile : MonoBehaviour
{
    [SerializeField] private PlayerProfileSO playerProfileData;
    private const string PlayerNameKey = "PlayerName";
    private const string TotalScoreKey = "TotalScore";
    private const string StarsCollectedKey = "StarsCollected";
    private const string TotalDistanceKey = "TotalDistance";

    private void Start()
    {
        LoadData();
    }

    private void OnApplicationQuit()
    {
        SaveData();
    }

    public void LoadData()
    {
        if (playerProfileData == null) return;

        playerProfileData.playerName = PlayerPrefs.GetString(PlayerNameKey, "New Pilot");
        playerProfileData.totalScore = PlayerPrefs.GetInt(TotalScoreKey, 0);
        playerProfileData.starsCollected = PlayerPrefs.GetInt(StarsCollectedKey, 0);
        playerProfileData.totalDistance = PlayerPrefs.GetFloat(TotalDistanceKey, 0f);
    }

    public void SaveData()
    {
        if (playerProfileData == null) return;

        PlayerPrefs.SetString(PlayerNameKey, playerProfileData.playerName);
        PlayerPrefs.SetInt(TotalScoreKey, playerProfileData.totalScore);
        PlayerPrefs.SetInt(StarsCollectedKey, playerProfileData.starsCollected);
        PlayerPrefs.SetFloat(TotalDistanceKey, playerProfileData.totalDistance);
        PlayerPrefs.Save();
    }
}