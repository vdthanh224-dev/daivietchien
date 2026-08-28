using UnityEngine;
using UnityEngine.UI;
using TMPro;

// Keep the lightweight network prototype separate from the production CardUI
// in Assets/Scripts/CardUI.cs. Both scripts are imported by Unity.
namespace DaiViet.NetworkUI
{
    public class CardUI : MonoBehaviour
    {
        public TextMeshProUGUI nameText;
        public TextMeshProUGUI descText;
        public Image backgroundImage;
        
        private CardData _cardData;
        private System.Action<string> _onCardClicked;

        public void Setup(CardData data, System.Action<string> onClickCallback)
        {
            _cardData = data;
            _onCardClicked = onClickCallback;
            
            if (nameText != null) nameText.text = data != null ? data.name : string.Empty;
            if (descText != null) descText.text = data != null ? data.desc : string.Empty;
            
            if (backgroundImage != null && data != null)
            {
                switch (data.category)
                {
                    case 0: backgroundImage.color = new Color(1f, 1f, 1f); break; // Basic
                    case 1: backgroundImage.color = new Color(1f, 0.92f, 0.016f); break; // Equipment
                    case 2: backgroundImage.color = new Color(0f, 1f, 1f); break; // Instant
                    case 3: backgroundImage.color = new Color(1f, 0f, 1f); break; // Delayed
                }
            }
        }

        public void OnClick()
        {
            if (_cardData != null) _onCardClicked?.Invoke(_cardData.id);
        }
    }
}
