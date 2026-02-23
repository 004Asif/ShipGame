// Replace the entire content of InstructionText.cs
using UnityEngine;
using TMPro;
using System.Collections;

public class InstructionText : MonoBehaviour
{
    public TextMeshProUGUI instructionText;
    public float displayDuration = 5f;
    public float fadeDuration = 1f;

    private void Start()
    {
        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(false);
        }
    }

    public void ShowInstructions()
    {
        // First, make sure the text object is active.
        if (instructionText != null)
        {
            instructionText.gameObject.SetActive(true);
            // Then, start the coroutine on this active object.
            StartCoroutine(DisplayInstructions());
        }
    }

    private IEnumerator DisplayInstructions()
    {
        instructionText.alpha = 1f;

        yield return new WaitForSeconds(displayDuration);

        float elapsedTime = 0f;
        Color startColor = instructionText.color;

        while (elapsedTime < fadeDuration)
        {
            float alpha = Mathf.Lerp(1f, 0f, elapsedTime / fadeDuration);
            instructionText.color = new Color(startColor.r, startColor.g, startColor.b, alpha);
            elapsedTime += Time.deltaTime;
            yield return null;
        }

        instructionText.gameObject.SetActive(false);
    }
}