using System.Linq;
using UnityEngine;

public class BattleController : MonoBehaviour
{
    public int mySeat = 1;
    private GameNetworkController _networkController;

    private void Start()
    {
        _networkController = FindObjectOfType<GameNetworkController>();
        
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnStateChanged += UpdateUI;
            GameStateManager.Instance.OnError += ShowError;
            GameStateManager.Instance.OnActionRejected += ShowError;
        }
        else
        {
            Debug.LogError("[BattleController] GameStateManager.Instance not found!");
        }
    }

    private void UpdateUI(GameStateData state)
    {
        if (state == null) return;

        Debug.Log($"[UI] --- STATE UPDATE ---");
        Debug.Log($"[UI] Phase: {state.phase} | Turn Seat: {state.turnSeat} | Timer: {state.turnTimer}s");
        
        var myPlayer = GetMyPlayer(state);
        if (myPlayer != null)
        {
            var hand = myPlayer.hand ?? new System.Collections.Generic.List<CardData>();
            Debug.Log($"[UI] My HP: {myPlayer.hp}/{myPlayer.maxHp} | Hand: {hand.Count} cards");
            foreach (var card in hand)
            {
                if (card != null) Debug.Log($"   - {card.name} (ID: {card.id})");
            }
        }

        // Handle Prompts based on Phase
        if (state.waitingTargetSeat == mySeat && state.waitingTimer > 0)
        {
            Debug.Log($"[UI] ⚠️ SERVER IS WAITING FOR YOU! Phase: {state.phase} | Required: {state.waitingReactionType}");
            // TODO: Highlight valid cards in UI and show countdown timer
        }
        
        if (state.phase == "PLAY" && state.turnSeat == mySeat)
        {
            Debug.Log("[UI] 👉 It's your turn! Play cards or click End Turn.");
        }
    }

    // --- UI Button Callbacks (To be linked to Unity UI Buttons) ---

    public void OnCardClicked(string cardId)
    {
        var stateManager = GameStateManager.Instance;
        var state = stateManager != null ? stateManager.CurrentState : null;
        if (state == null || state.turnSeat != mySeat || state.phase != "PLAY") 
        {
            Debug.LogWarning("[UI] Not your turn or invalid phase to play a card.");
            return;
        }

        var myPlayer = GetMyPlayer(state);
        var card = myPlayer?.hand?.Find(c => c != null && c.id == cardId);
        int targetSeat = mySeat; // Default to self (Peach, Equipment, Wine)

        if (card != null)
        {
            // SubTypes 0, 1, 2 are Slashes (Normal, Fire, Thunder)
            if (card.subType == 0 || card.subType == 1 || card.subType == 2) 
            {
                var enemy = state.players.FirstOrDefault(p => p.isAlly != myPlayer.isAlly && p.hp > 0);
                if (enemy != null) targetSeat = enemy.seat;
            }
        }

        if (_networkController != null)
            _networkController.SendPlayCard(cardId, targetSeat);
    }

    public void OnRespondClicked(bool accepted, string cardId = "")
    {
        if (_networkController != null)
            _networkController.SendRespond(accepted, cardId);
    }

    public void OnEndTurnClicked()
    {
        if (_networkController != null)
            _networkController.SendEndTurn();
    }

    private PlayerData GetMyPlayer(GameStateData state)
    {
        return state?.players?.FirstOrDefault(p => p.seat == mySeat);
    }

    private void ShowError(string error)
    {
        Debug.LogError($"[UI] ❌ Error/Rejected: {error}");
    }

    private void OnDestroy()
    {
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.OnStateChanged -= UpdateUI;
            GameStateManager.Instance.OnError -= ShowError;
            GameStateManager.Instance.OnActionRejected -= ShowError;
        }
    }
}
