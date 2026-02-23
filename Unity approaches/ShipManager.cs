using UnityEngine;
using System.Collections.Generic;

public class ShipManager : MonoBehaviour
{
    public static ShipManager Instance { get; private set; }

    [System.Serializable]
    public class ShipModel
    {
        public string name;
        public GameObject prefab;
        public int cost;
        public bool isUnlocked;
    }

    public List<ShipModel> availableShips = new List<ShipModel>();
    public int CurrentShipIndex { get; private set; }

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            InitializeShips();
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

    public void InitializeShips()
    {
        for (int i = 0; i < availableShips.Count; i++)
        {
            string key = $"Ship_{i}_Unlocked";
            availableShips[i].isUnlocked = PlayerPrefs.GetInt(key, i == 0 ? 1 : 0) == 1;
        }
        CurrentShipIndex = PlayerPrefs.GetInt("CurrentShipIndex", 0);
        Debug.Log($"Ships initialized. Current ship index: {CurrentShipIndex}");
    }

    public ShipModel GetCurrentShip()
    {
        if (CurrentShipIndex >= 0 && CurrentShipIndex < availableShips.Count)
            return availableShips[CurrentShipIndex];
        return null;
    }

    public void ChangeShip(int direction)
    {
        CurrentShipIndex = (CurrentShipIndex + direction + availableShips.Count) % availableShips.Count;
    }

    public bool UnlockShip(int index, int availableStars)
    {
        if (index < 0 || index >= availableShips.Count)
            return false;

        if (availableStars >= availableShips[index].cost)
        {
            availableShips[index].isUnlocked = true;
            return true;
        }
        return false;
    }

    public void SaveShipData()
    {
        for (int i = 0; i < availableShips.Count; i++)
        {
            string key = $"Ship_{i}_Unlocked";
            PlayerPrefs.SetInt(key, availableShips[i].isUnlocked ? 1 : 0);
        }
        PlayerPrefs.SetInt("CurrentShipIndex", CurrentShipIndex);
        PlayerPrefs.Save();
    }
}