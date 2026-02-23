using UnityEngine;
using UnityEngine.InputSystem;

/// <summary>
/// Bridges the new Input System with ShipController and existing UI buttons.
/// Reads from InputActions for keyboard/gamepad, and from Vector2Variable for touch UI buttons.
/// Attach to the player ship alongside ShipController.
/// </summary>
public class ShipInputHandler : MonoBehaviour
{
    #region Serialized Fields
    [Header("Input Actions Asset")]
    [SerializeField] private InputActionAsset m_InputActions;

    [Header("Touch UI Fallback")]
    [SerializeField, Tooltip("Existing Vector2Variable from UI buttons — still works alongside new Input System")]
    private Vector2Variable m_TouchInput;
    #endregion

    #region Private Fields
    private InputAction m_MoveAction;
    private InputAction m_BoostAction;
    private ShipController m_ShipController;
    #endregion

    #region Public Properties
    /// <summary>
    /// Combined horizontal input from all sources (keyboard, gamepad, touch UI).
    /// </summary>
    public float HorizontalInput { get; private set; }
    public bool BoostPressed { get; private set; }
    #endregion

    #region Unity Lifecycle
    private void Awake()
    {
        m_ShipController = GetComponent<ShipController>();

        if (m_InputActions != null)
        {
            var shipMap = m_InputActions.FindActionMap("Ship", throwIfNotFound: true);
            m_MoveAction = shipMap.FindAction("Move", throwIfNotFound: true);
            m_BoostAction = shipMap.FindAction("Boost", throwIfNotFound: true);
        }
    }

    private void OnEnable()
    {
        m_MoveAction?.Enable();
        m_BoostAction?.Enable();

        if (m_BoostAction != null)
        {
            m_BoostAction.performed += OnBoostPerformed;
        }
    }

    private void OnDisable()
    {
        if (m_BoostAction != null)
        {
            m_BoostAction.performed -= OnBoostPerformed;
        }

        m_MoveAction?.Disable();
        m_BoostAction?.Disable();
    }

    private void Update()
    {
        ReadInput();
    }
    #endregion

    #region Input Reading
    private void ReadInput()
    {
        float inputX = 0f;

        // Priority 1: Touch UI buttons (Vector2Variable from MovementButton.cs)
        if (m_TouchInput != null && m_TouchInput.value.x != 0f)
        {
            inputX = m_TouchInput.value.x;
        }
        // Priority 2: New Input System (keyboard/gamepad)
        else if (m_MoveAction != null)
        {
            Vector2 moveValue = m_MoveAction.ReadValue<Vector2>();
            inputX = moveValue.x;
        }

        HorizontalInput = inputX;
    }

    private void OnBoostPerformed(InputAction.CallbackContext _context)
    {
        if (m_ShipController != null)
        {
            m_ShipController.ActivateBoost();
        }
    }
    #endregion
}
