using System.Collections.Generic;
using UnityEngine;

namespace DaiViet.NetworkUI
{
    public class HandUI : MonoBehaviour
    {
        public GameObject cardPrefab;
        public Transform cardContainer;
        
        private List<CardUI> _currentCards = new List<CardUI>();
        private BattleController _battleController;

        private void Start()
        {
            _battleController = FindObjectOfType<BattleController>();
            if (GameStateManager.Instance != null)
            {
                GameStateManager.Instance.OnStateChanged += UpdateHand;
                // A snapshot may arrive before this component's Start method;
                // render the already-authoritative hand immediately.
                UpdateHand(GameStateManager.Instance.CurrentState);
            }
        }

        private void UpdateHand(GameStateData state)
        {
            if (state == null || state.players == null || _battleController == null) return;
            var myPlayer = state.players.Find(p => p.seat == _battleController.mySeat);
            if (myPlayer == null) return;

            foreach (var card in _currentCards)
            {
                if (card != null) Destroy(card.gameObject);
            }
            _currentCards.Clear();

            if (cardPrefab != null && cardContainer != null && myPlayer.hand != null)
            {
                foreach (var cardData in myPlayer.hand)
                {
                    if (cardData == null || cardData.id == "HIDDEN") continue;
                    
                    var cardObj = Instantiate(cardPrefab, cardContainer);
                    var cardUI = cardObj.GetComponent<CardUI>();
                    if (cardUI != null)
                    {
                        cardUI.Setup(cardData, _battleController.OnCardClicked);
                        _currentCards.Add(cardUI);
                    }
                    else
                    {
                        // Do not leave untracked instances behind when a
                        // scene uses a prefab without the network CardUI.
                        Destroy(cardObj);
                    }
                }
            }
        }

        private void OnDestroy()
        {
            if (GameStateManager.Instance != null)
            {
                GameStateManager.Instance.OnStateChanged -= UpdateHand;
            }
        }
    }
}
