// Create a new C# script: UIValueDisplay.cs
using UnityEngine;
using TMPro;

public class UIValueDisplay : MonoBehaviour
{
    [Header("Data")]
    [SerializeField] private FloatVariable floatValue;
    [SerializeField] private IntVariable intValue;

    [Header("UI")]
    [SerializeField] private TextMeshProUGUI displayText;
    [SerializeField] private string prefix = "";
    [SerializeField] private string format = "F0"; // F0 for float as integer, N0 for thousands separators

    private void Update()
    {
        if (floatValue != null)
        {
            
            displayText.text = prefix + floatValue.value.ToString(format);
        }
        else if (intValue != null)
        {
            
            displayText.text = prefix + intValue.value.ToString();
        }
    }
}
