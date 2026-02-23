// Create a new C# script: SpawnableObjectSO.cs
using UnityEngine;

// An enum to define the type of object, which will help in setting its tag
public enum ObjectTag { Untagged, Obstacle, Collectible, EnemyShip, PowerUp }

[CreateAssetMenu(menuName = "Game Architecture/Spawnable Object", fileName = "New Spawnable Object")]
public class SpawnableObjectSO : ScriptableObject
{
    [Header("Spawning Properties")]
    public GameObject prefab;
    [Range(0f, 1f)] public float spawnRate = 0.5f;
    public ObjectTag objectTag = ObjectTag.Untagged;

    [Header("Placement Properties")]
    public float heightMin = 1f;
    public float heightMax = 5f;

    [Header("Variation Properties")]
    public Vector3 sizeMin = new Vector3(1f, 1f, 1f);
    public Vector3 sizeMax = new Vector3(1f, 1f, 1f);
}