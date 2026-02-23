using UnityEngine;
using System.Collections.Generic;

public class ObjectPool
{
    private GameObject prefab;
    private List<GameObject> availableObjects;

    public ObjectPool(GameObject prefab, int initialSize)
    {
        this.prefab = prefab;
        availableObjects = new List<GameObject>(initialSize);

        for (int i = 0; i < initialSize; i++)
        {
            GameObject obj = Object.Instantiate(prefab);
            obj.SetActive(false);
            availableObjects.Add(obj);
        }
    }

    public GameObject Get()
    {
        GameObject obj = null;

        // Keep checking for an object until we find a valid one or the pool is empty.
        while (availableObjects.Count > 0)
        {
            // Get the last object from the list.
            obj = availableObjects[availableObjects.Count - 1];
            availableObjects.RemoveAt(availableObjects.Count - 1);

            // In Unity, a destroyed GameObject reference doesn't become truly null,
            // but it will evaluate to null in a boolean context.
            if (obj != null)
            {
                // We found a valid, non-destroyed object. Break the loop.
                break;
            }
            // If obj was null, the loop continues and tries the next one.
            Debug.LogWarning($"Found a destroyed object in pool for prefab '{prefab.name}'. Discarding it.");
        }

        // If we exhausted the pool of valid objects, or it was empty to begin with, create a new one.
        if (obj == null)
        {
            obj = Object.Instantiate(prefab);
        }

        obj.SetActive(true);
        return obj;
    }

    public void Release(GameObject obj)
    {
        obj.SetActive(false);
        availableObjects.Add(obj);
    }
}