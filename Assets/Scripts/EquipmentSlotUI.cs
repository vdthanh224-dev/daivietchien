using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Quản lý 1 dòng trang bị trên tướng (Vũ khí, Giáp, Ngựa công, Ngựa thủ, Bảo vật).
/// Khi chưa trang bị: để trống tinh tế, không ghi chữ lung tung làm xấu card.
/// Khi đã trang bị: hiển thị tên trang bị và biểu tượng trang bị rõ ràng.
/// </summary>
public class EquipmentSlotUI : MonoBehaviour
{
    [Header("Slot Configuration")]
    [SerializeField] private EquipmentType slotType;
    [SerializeField] private Image slotBackground;
    [SerializeField] private Image slotCategoryIcon;
    [SerializeField] private Image equippedItemIcon;
    [SerializeField] private Text itemNameText;

    [Header("Category Sprites")]
    [SerializeField] private Sprite defaultCategorySprite;

    private bool isEquipped = false;
    private string currentItemName = "";

    public EquipmentType SlotType => slotType;
    public bool IsEquipped => isEquipped;
    public string CurrentItemName => currentItemName;

    private void Awake()
    {
        EnsureComponents();
        ClearEquipment();
    }

    public void Init(EquipmentType type)
    {
        slotType = type;
        EnsureComponents();
        LoadDefaultCategorySprite();
        ClearEquipment();
    }

    private void EnsureComponents()
    {
        if (slotBackground == null)
            slotBackground = GetComponent<Image>();

        if (slotCategoryIcon == null)
        {
            var catGo = transform.Find("CategoryIcon");
            if (catGo != null) slotCategoryIcon = catGo.GetComponent<Image>();
        }

        if (equippedItemIcon == null)
        {
            var eqGo = transform.Find("EquippedIcon");
            if (eqGo != null) equippedItemIcon = eqGo.GetComponent<Image>();
        }

        if (itemNameText == null)
        {
            var txtGo = transform.Find("ItemNameText");
            if (txtGo != null) itemNameText = txtGo.GetComponent<Text>();
        }
    }

    private void LoadDefaultCategorySprite()
    {
        if (defaultCategorySprite != null) return;

        string spritePath = slotType switch
        {
            EquipmentType.Weapon => "UI/icon_weapon",
            EquipmentType.Armor => "UI/icon_armor",
            EquipmentType.OffensiveMount => "UI/icon_mount_offense",
            EquipmentType.DefensiveMount => "UI/icon_mount_defense",
            EquipmentType.Treasure => "UI/icon_treasure",
            _ => "UI/icon_weapon"
        };

        defaultCategorySprite = LotusHealthUI.LoadSpriteFromResources(spritePath);
        if (slotCategoryIcon != null && defaultCategorySprite != null)
        {
            slotCategoryIcon.sprite = defaultCategorySprite;
        }
    }

    /// <summary>
    /// Gắn trang bị vào ô slot.
    /// </summary>
    public void Equip(string itemName, Sprite itemIcon = null)
    {
        if (string.IsNullOrWhiteSpace(itemName))
        {
            ClearEquipment();
            return;
        }

        isEquipped = true;
        currentItemName = itemName;

        if (itemNameText != null)
        {
            itemNameText.gameObject.SetActive(true);
            itemNameText.text = itemName;
        }

        if (equippedItemIcon != null)
        {
            if (itemIcon != null)
            {
                equippedItemIcon.gameObject.SetActive(true);
                equippedItemIcon.sprite = itemIcon;
            }
            else
            {
                equippedItemIcon.gameObject.SetActive(false);
            }
        }

        if (slotCategoryIcon != null)
        {
            slotCategoryIcon.color = new Color(1f, 0.9f, 0.5f, 1f); // Sáng màu khi có đồ
        }

        if (slotBackground != null)
        {
            slotBackground.color = new Color(0.12f, 0.16f, 0.24f, 0.92f);
        }
    }

    /// <summary>
    /// Gỡ trang bị: Đưa về trạng thái trống tinh tế, không hiển thị chữ thừa.
    /// </summary>
    public void ClearEquipment()
    {
        isEquipped = false;
        currentItemName = "";

        if (itemNameText != null)
        {
            itemNameText.text = "";
            itemNameText.gameObject.SetActive(false);
        }

        if (equippedItemIcon != null)
        {
            equippedItemIcon.gameObject.SetActive(false);
        }

        if (slotCategoryIcon != null)
        {
            // Icon mờ tinh tế khi chưa trang bị
            slotCategoryIcon.color = new Color(0.7f, 0.7f, 0.75f, 0.35f);
        }

        if (slotBackground != null)
        {
            slotBackground.color = new Color(0.05f, 0.07f, 0.12f, 0.45f);
        }
    }
}
