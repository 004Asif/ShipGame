using UnityEngine;
using UnityEngine.EventSystems;

public class MovementButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
{
    [Header("Input Data")]
    [Tooltip("The ScriptableObject that holds the player's input vector.")]
    [SerializeField] private Vector2Variable playerInput;

    [Header("Button Configuration")]
    [Tooltip("The direction this button will push the input towards.")]
    [SerializeField] private float direction = 1f; // Use 1 for Right, -1 for Left

    public void OnPointerDown(PointerEventData eventData)
    {
        if (playerInput != null)
        {
            // When pressed, set the x value of our input asset.
            playerInput.value.x = direction;
        }
    }

    public void OnPointerUp(PointerEventData eventData)
    {
        if (playerInput != null)
        {
            // When released, reset the input to zero if it's still moving in our direction.
            if (Mathf.Approximately(playerInput.value.x, direction))
            {
                playerInput.value.x = 0;
            }
        }
    }
}