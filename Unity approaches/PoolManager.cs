// Create a new C# script: PoolManager.cs
using UnityEngine;
using System.Collections.Generic;

public class PoolManager : MonoBehaviour
{
    public static PoolManager Instance { get; private set; }

    private Dictionary<string, ObjectPool> pools = new Dictionary<string, ObjectPool>();
    private Dictionary<int, string> objectIdToPoolKey = new Dictionary<int, string>();

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

    public void CreatePool(GameObject prefab, int initialSize)
    {
        if (prefab == null || pools.ContainsKey(prefab.name))
        {
            return;
        }

        ObjectPool newPool = new ObjectPool(prefab, initialSize);
        pools.Add(prefab.name, newPool);
    }

    public GameObject Get(string poolKey)
    {
        if (!pools.ContainsKey(poolKey))
        {
            Debug.LogError($"Pool with key '{poolKey}' does not exist.");
            return null;
        }

        GameObject obj = pools[poolKey].Get();
        objectIdToPoolKey.Add(obj.GetInstanceID(), poolKey);
        return obj;
    }

    public void Release(GameObject obj)
    {
        if (obj == null) return;

        // Immediately disable to prevent lingering collisions
        obj.SetActive(false);

        if (!objectIdToPoolKey.ContainsKey(obj.GetInstanceID()))
        {
            Destroy(obj);
            return;
        }

        string poolKey = objectIdToPoolKey[obj.GetInstanceID()];
        objectIdToPoolKey.Remove(obj.GetInstanceID());
        pools[poolKey].Release(obj);
    }
}
