using UnityEngine;

public class FrameRateLimiter : MonoBehaviour
{
    [SerializeField] private int targetFrameRate = 60;

    private void Awake()
    {
        QualitySettings.vSyncCount = 0;  // VSync must be disabled
        Application.targetFrameRate = targetFrameRate;
    }

    private void Update()
    {
        if (Application.targetFrameRate != targetFrameRate)
        {
            Application.targetFrameRate = targetFrameRate;
        }
    }
}