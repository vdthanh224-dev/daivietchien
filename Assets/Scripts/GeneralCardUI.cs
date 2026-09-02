using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Giao diện thẻ Tướng Đại Việt Chiến có thể tái sử dụng (Reusable General Card UI).
/// - Avatar tỉ lệ 3x4
/// - Máu dạng từng cục hoa sen (sáng khi đầy, tối khi mất máu)
/// - 5 dòng trang bị (Vũ khí, Giáp, Ngựa công, Ngựa thủ, Bảo vật) để sẵn tinh tế, không ghi chữ thô
    /// - Tên phe ở góc dưới bên trái (ví dụ: "Khác", "Đại Việt", "Trần"...)
/// - Tên tướng ở trên giữa (ví dụ: "Lý Thường Kiệt")
/// - Số bài trên tay ở góc dưới bên phải
/// </summary>
[SelectionBase]
[DisallowMultipleComponent]
public class GeneralCardUI : MonoBehaviour, UnityEngine.EventSystems.IPointerClickHandler
{
    public event Action<GeneralCardUI> OnGeneralClicked;

    
    private string customHeroId = "";
    public string HeroId
    {
        get 
        { 
            if (!string.IsNullOrEmpty(customHeroId)) return customHeroId;
            var heroData = HeroDatabase100.GetHeroByName(generalName);
            return heroData != null ? heroData.id.ToString() : "";
        }
        set { customHeroId = value; }
    }

    public void OnPointerClick(UnityEngine.EventSystems.PointerEventData eventData)
    {
        OnGeneralClicked?.Invoke(this);
    }

    [Header("General Data & Configuration")]
    [SerializeField] private string generalName = "Lý Thường Kiệt";
    [SerializeField] private string factionName = "Khác";
    [SerializeField] private Sprite avatarSprite;
    [SerializeField] private int maxHp = 4;
    [SerializeField] private int currentHp = 4;
    [SerializeField] private int handCardCount = 4;

    [Header("UI References")]
    [SerializeField] private Image avatarImage;
    [SerializeField] private RawImage avatarRawImage;
    [SerializeField] private Image cardFrameImage;
    [SerializeField] private Text generalNameText;
    [SerializeField] private Text factionText;
    [SerializeField] private Image factionBadgeImage;
    [SerializeField] private Image namePlaqueImage;
    [SerializeField] private LotusHealthUI lotusHealthUI;

    [Header("Hand Cards (Góc dưới phải)")]
    [SerializeField] private GameObject handCardsBadgeGo;
    [SerializeField] private Text handCardsText;

    [Header("Skill Button (Bên trái avatar)")]
    [SerializeField] private GameObject skillButtonGo;
    [SerializeField] private Button skillButton;
    [SerializeField] private Text skillButtonText;
    [SerializeField] private Image skillBtnImg;
    [SerializeField] private Image skillBorderImg;
    [SerializeField] private GameObject skillHaloGo;

    [Header("Reaction Awaiting Blink Indicator")]
    private GameObject reactionHaloGo;
    private Coroutine reactionBlinkCoroutine;

    [Header("Judgement Zone (Vùng Phán Xét / Trì Hoãn)")]
    [SerializeField] private GameObject judgementZoneGo;

    [Header("Equipment Slots (5 dòng trang bị)")]
    [SerializeField] private EquipmentSlotUI weaponSlot;
    [SerializeField] private EquipmentSlotUI armorSlot;
    [SerializeField] private EquipmentSlotUI offensiveMountSlot;
    [SerializeField] private EquipmentSlotUI defensiveMountSlot;
    [SerializeField] private EquipmentSlotUI treasureSlot;

    private readonly Dictionary<EquipmentType, EquipmentSlotUI> slotMap = new Dictionary<EquipmentType, EquipmentSlotUI>();

    public string GeneralName
    {
        get => generalName;
        set => generalName = value;
    }
    public string FactionName => factionName;
    public int MaxHp => maxHp;
    public int CurrentHp => currentHp;
    public int HandCardCount => handCardCount;
    public LotusHealthUI HealthUI => lotusHealthUI;
    public GameObject SkillButtonGo => skillButtonGo;
    public Button SkillButton => skillButton;

    public bool HasAnyEquipment()
    {
        if (equippedCards != null)
        {
            foreach (var kv in equippedCards)
            {
                if (kv.Value != null) return true;
            }
        }
        if (slotMap != null)
        {
            foreach (var slot in slotMap.Values)
            {
                if (slot != null && slot.IsEquipped) return true;
            }
        }
        return false;
    }

    public void SetSkill(string skillName, Action onClick)
    {
        if (skillButtonGo != null)
        {
            skillButtonGo.SetActive(true);
            if (skillButtonText != null) skillButtonText.text = skillName;
            if (skillButton != null)
            {
                skillButton.onClick.RemoveAllListeners();
                if (onClick != null) skillButton.onClick.AddListener(() => onClick());
                skillButton.interactable = true;
            }
            SetSkillState(true);
        }
    }

    public string[] ActiveSkillsKeys;
    public bool[] ActiveSkillsValues;
    public string[] UsedSkillsKeys;
    public bool[] UsedSkillsValues;
    
    public bool HasUsedSkill(string skillId)
    {
        if (UsedSkillsKeys == null || UsedSkillsValues == null) return false;
        for (int i = 0; i < UsedSkillsKeys.Length; i++)
        {
            if (UsedSkillsKeys[i] == skillId) return i < UsedSkillsValues.Length && UsedSkillsValues[i];
        }
        return false;
    }

    public bool IsSkillActive(string skillId)
    {
        if (ActiveSkillsKeys == null || ActiveSkillsValues == null) return false;
        for (int i = 0; i < ActiveSkillsKeys.Length; i++)
        {
            if (ActiveSkillsKeys[i] == skillId) return i < ActiveSkillsValues.Length && ActiveSkillsValues[i];
        }
        return false;
    }

    public void SetSkillState(bool isUsable)
    {
        if (skillButtonGo == null) return;

        if (isUsable)
        {
            // SÁNG RỰC KHI DÙNG ĐƯỢC (Vàng cam phát sáng & Hào quang)
            if (skillBtnImg != null) skillBtnImg.color = new Color(0.85f, 0.45f, 0.1f, 1f);
            if (skillBorderImg != null) skillBorderImg.color = new Color(1f, 0.95f, 0.45f, 1f);
            if (skillButtonText != null) skillButtonText.color = new Color(1f, 1f, 0.88f, 1f);
            if (skillHaloGo != null) skillHaloGo.SetActive(true);
            if (skillButton != null) skillButton.interactable = true;
        }
        else
        {
            // TỐI MÀU KHI KHÔNG DÙNG ĐƯỢC (Vẫn cho phép bấm để hiển thị thông báo)
            if (skillBtnImg != null) skillBtnImg.color = new Color(0.08f, 0.10f, 0.14f, 0.65f);
            if (skillBorderImg != null) skillBorderImg.color = new Color(0.25f, 0.30f, 0.38f, 0.45f);
            if (skillButtonText != null) skillButtonText.color = new Color(0.42f, 0.48f, 0.55f, 0.7f);
            if (skillHaloGo != null) skillHaloGo.SetActive(false);
            if (skillButton != null) skillButton.interactable = true;
        }
    }

    private void Awake()
    {
        CacheSlotMap();
    }

    private void Start()
    {
        // Tự động nạp avatar mặc định nếu chưa gán
        if (avatarSprite == null && avatarImage != null && avatarImage.sprite == null && (avatarRawImage == null || avatarRawImage.texture == null))
        {
            var defaultTex = Resources.Load<Texture2D>("UI/ly_thuong_kiet");
            if (defaultTex != null)
            {
                SetAvatar(defaultTex);
            }
        }

        RefreshUI();
    }

    private void CacheSlotMap()
    {
        slotMap.Clear();
        if (weaponSlot != null) slotMap[EquipmentType.Weapon] = weaponSlot;
        if (armorSlot != null) slotMap[EquipmentType.Armor] = armorSlot;
        if (offensiveMountSlot != null) slotMap[EquipmentType.OffensiveMount] = offensiveMountSlot;
        if (defensiveMountSlot != null) slotMap[EquipmentType.DefensiveMount] = defensiveMountSlot;
        if (treasureSlot != null) slotMap[EquipmentType.Treasure] = treasureSlot;
    }

    /// <summary>
    /// Khởi tạo thẻ tướng với GeneralData.
    /// </summary>
    public void Setup(GeneralData data)
    {
        if (data == null) return;

        generalName = data.generalName;
        factionName = data.faction;
        maxHp = data.maxHp;
        currentHp = data.currentHp;
        handCardCount = data.handCardCount;

        if (data.avatarSprite != null)
            SetAvatar(data.avatarSprite);
        else if (data.avatarTexture != null)
            SetAvatar(data.avatarTexture);

        RefreshUI();

        // Setup có thể được gọi lại trên cùng một card; dọn state cũ trước
        // khi nạp các trang bị ban đầu để tránh giữ nhầm dữ liệu gameplay.
        ClearAllEquipment();

        // Trang bị ban đầu nếu có
        if (!string.IsNullOrEmpty(data.initialWeapon)) Equip(EquipmentType.Weapon, data.initialWeapon);
        if (!string.IsNullOrEmpty(data.initialArmor)) Equip(EquipmentType.Armor, data.initialArmor);
        if (!string.IsNullOrEmpty(data.initialOffensiveMount)) Equip(EquipmentType.OffensiveMount, data.initialOffensiveMount);
        if (!string.IsNullOrEmpty(data.initialDefensiveMount)) Equip(EquipmentType.DefensiveMount, data.initialDefensiveMount);
        if (!string.IsNullOrEmpty(data.initialTreasure)) Equip(EquipmentType.Treasure, data.initialTreasure);
    }

    /// <summary>
    /// Cập nhật tên tướng ở trên giữa.
    /// </summary>
    public void SetGeneralName(string name)
    {
        generalName = name;
        if (generalNameText != null) generalNameText.text = generalName;
    }

    /// <summary>
    /// Cập nhật tên phe ở góc dưới bên trái.
    /// </summary>
    public void SetFaction(string faction, Color? badgeColor = null)
    {
        factionName = faction;
        if (factionText != null) factionText.text = factionName;
        if (factionBadgeImage != null && badgeColor.HasValue)
        {
            factionBadgeImage.color = badgeColor.Value;
        }
    }

    /// <summary>
    /// Cập nhật số bài trên tay ở góc dưới bên phải.
    /// </summary>
    public void SetHandCardCount(int count)
    {
        handCardCount = Mathf.Max(0, count);
        if (handCardsText != null)
        {
            handCardsText.text = handCardCount.ToString();
        }
    }

    /// <summary>
    /// Gán avatar tướng (Sprite).
    /// </summary>
    public void SetAvatar(Sprite sprite)
    {
        avatarSprite = sprite;
        if (avatarImage != null)
        {
            avatarImage.gameObject.SetActive(true);
            avatarImage.sprite = sprite;
        }
        if (avatarRawImage != null && sprite != null)
        {
            avatarRawImage.gameObject.SetActive(false);
        }
    }

    /// <summary>
    /// Gán avatar tướng (Texture2D).
    /// </summary>
    public void SetAvatar(Texture2D texture)
    {
        if (texture == null) return;

        if (avatarRawImage != null)
        {
            avatarRawImage.gameObject.SetActive(true);
            avatarRawImage.texture = texture;
            if (avatarImage != null) avatarImage.gameObject.SetActive(false);
        }
        else if (avatarImage != null)
        {
            var spr = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0.5f, 0.5f), 100f);
            SetAvatar(spr);
        }
    }

    /// <summary>
    /// Cập nhật máu.
    /// </summary>
    public void SetHealth(int current, int max)
    {
        maxHp = Mathf.Max(1, max);
        currentHp = Mathf.Clamp(current, 0, maxHp);
        if (lotusHealthUI != null)
        {
            lotusHealthUI.Setup(currentHp, maxHp);
        }
    }

    public void TakeDamage(int damage = 1)
    {
        currentHp = Mathf.Clamp(currentHp - damage, 0, maxHp);
        if (lotusHealthUI != null) lotusHealthUI.SetCurrentHp(currentHp);
    }

    public void Heal(int amount = 1)
    {
        currentHp = Mathf.Clamp(currentHp + amount, 0, maxHp);
        if (lotusHealthUI != null) lotusHealthUI.SetCurrentHp(currentHp);
    }

    public void SetHpDirectly(int hp)
    {
        currentHp = Mathf.Clamp(hp, 0, maxHp);
        if (lotusHealthUI != null) lotusHealthUI.SetCurrentHp(currentHp);
    }

    [Header("2v2 Team & Seat Properties")]
    public int SeatNumber { get; set; } = 1;
    public bool IsAlly { get; set; } = true;
    public bool IsPlayer { get; set; } = false;
    public bool IsAI { get; set; } = true;
    public string UserId { get; set; } = "";
    public bool IsWineBuffActive { get; set; } = false;
    private GameObject seatBadgeGo;
    private Text seatBadgeText;
    private GameObject turnHaloGo;
    private Color normalFrameColor = Color.white;
    private bool deadVisualActive;

    /// <summary>
    /// Đổi màu viền khung thẻ bài.
    /// </summary>
    public void SetFrameColor(Color color)
    {
        normalFrameColor = color;
        if (cardFrameImage != null)
        {
            cardFrameImage.color = deadVisualActive
                ? new Color(0.35f, 0.35f, 0.35f, 0.8f)
                : color;
        }
    }

    /// <summary>
    /// Thiết lập số thứ tự lượt (Ghế 1, 2, 3, 4).
    /// </summary>
    public void SetSeatBadge(int seat)
    {
        SeatNumber = seat;
        if (seatBadgeGo == null)
        {
            var font = ThemeUI.FontMain;
            seatBadgeGo = new GameObject("SeatBadge", typeof(RectTransform), typeof(Image));
            seatBadgeGo.transform.SetParent(transform, false);
            var bImg = seatBadgeGo.GetComponent<Image>();
            var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (badgeSpr != null) { bImg.sprite = badgeSpr; bImg.type = Image.Type.Sliced; }
            bImg.color = new Color(0.08f, 0.12f, 0.22f, 0.98f);

            var sRt = seatBadgeGo.GetComponent<RectTransform>();
            sRt.anchorMin = sRt.anchorMax = sRt.pivot = new Vector2(0f, 1f);
            sRt.sizeDelta = new Vector2(34f, 26f);
            sRt.anchoredPosition = new Vector2(4f, -38f);

            // Viền vàng
            var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
            borderGo.transform.SetParent(seatBadgeGo.transform, false);
            var borImg = borderGo.GetComponent<Image>();
            var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (fSpr != null) { borImg.sprite = fSpr; borImg.type = Image.Type.Sliced; }
            borImg.color = new Color(1f, 0.85f, 0.35f, 1f);
            var bRt = borderGo.GetComponent<RectTransform>();
            bRt.anchorMin = Vector2.zero; bRt.anchorMax = Vector2.one;
            bRt.offsetMin = new Vector2(-1, -1); bRt.offsetMax = new Vector2(1, 1);

            var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(seatBadgeGo.transform, false);
            seatBadgeText = txtGo.GetComponent<Text>();
            seatBadgeText.font = font;
            seatBadgeText.fontSize = 17;
            seatBadgeText.fontStyle = FontStyle.Bold;
            seatBadgeText.alignment = TextAnchor.MiddleCenter;
            seatBadgeText.color = new Color(1f, 0.9f, 0.4f, 1f);
            var tRt = txtGo.GetComponent<RectTransform>();
            tRt.anchorMin = Vector2.zero; tRt.anchorMax = Vector2.one;
            tRt.offsetMin = tRt.offsetMax = Vector2.zero;
        }

        if (seatBadgeText != null)
        {
            seatBadgeText.text = $"#{seat}";
        }
    }

    /// <summary>
    /// Đồng bộ màu sắc viền và huy hiệu phe 2v2 (Đồng Minh vs Đối Thủ).
    /// </summary>
    public void SetTeamVisual(bool ally)
    {
        IsAlly = ally;
        if (ally)
        {
            SetFaction("PHE RỒNG", new Color(0.12f, 0.45f, 0.85f, 0.95f));
            SetFrameColor(new Color(0.25f, 0.72f, 1f, 1f));
        }
        else
        {
            SetFaction("PHE PHƯỢNG", new Color(0.85f, 0.22f, 0.22f, 0.95f));
            SetFrameColor(new Color(1f, 0.38f, 0.38f, 1f));
        }
    }

    /// <summary>
    /// Hiển thị hào quang sáng khi đang trong lượt của tướng này.
    /// </summary>
    private GameObject turnOrbitRootGo;
    private RectTransform[] orbitLightStreaks;
    private Coroutine orbitCoroutine;

    private GameObject headTimerBadgeGo;
    private Text headTimerText;
    private Image headTimerFrameImg;

    public void SetTurnActive(bool active)
    {
        if (turnHaloGo == null && active)
        {
            turnHaloGo = new GameObject("TurnHalo", typeof(RectTransform), typeof(Image));
            turnHaloGo.transform.SetParent(transform, false);
            turnHaloGo.transform.SetAsFirstSibling();
            var hImg = turnHaloGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
            if (spr != null) hImg.sprite = spr;
            hImg.color = IsAlly ? new Color(0.3f, 0.85f, 1f, 0.9f) : new Color(1f, 0.5f, 0.2f, 0.9f);
            hImg.raycastTarget = false;
            var hRt = turnHaloGo.GetComponent<RectTransform>();
            hRt.anchorMin = Vector2.zero; hRt.anchorMax = Vector2.one;
            hRt.offsetMin = new Vector2(-16, -16); hRt.offsetMax = new Vector2(16, 16);
        }

        if (turnHaloGo != null)
        {
            turnHaloGo.SetActive(active);
        }

        // 3 ĐƯỜNG SÁNG CHẠY QUANH THẺ TƯỚNG (3 Orbiting Light Streaks)
        if (active)
        {
            StartTurnOrbitLights();
            ShowHeadTimer(40);
        }
        else
        {
            StopTurnOrbitLights();
            HideHeadTimer();
        }
    }

    private void StartTurnOrbitLights()
    {
        if (turnOrbitRootGo == null)
        {
            turnOrbitRootGo = new GameObject("TurnOrbitRoot", typeof(RectTransform));
            turnOrbitRootGo.transform.SetParent(transform, false);
            var rootRt = turnOrbitRootGo.GetComponent<RectTransform>();
            rootRt.anchorMin = Vector2.zero; rootRt.anchorMax = Vector2.one;
            rootRt.offsetMin = rootRt.offsetMax = Vector2.zero;

            orbitLightStreaks = new RectTransform[3];
            var haloSpr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");

            for (int i = 0; i < 3; i++)
            {
                var sGo = new GameObject("OrbitStreak_" + i, typeof(RectTransform), typeof(Image));
                sGo.transform.SetParent(turnOrbitRootGo.transform, false);
                var img = sGo.GetComponent<Image>();
                if (haloSpr != null) img.sprite = haloSpr;
                img.color = IsAlly ? new Color(0.4f, 0.95f, 1f, 0.95f) : new Color(1f, 0.85f, 0.3f, 0.95f);
                img.raycastTarget = false;

                var rt = sGo.GetComponent<RectTransform>();
                rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
                rt.sizeDelta = new Vector2(28f, 28f);
                orbitLightStreaks[i] = rt;
            }
        }

        turnOrbitRootGo.SetActive(true);
        if (orbitCoroutine != null) StopCoroutine(orbitCoroutine);
        orbitCoroutine = StartCoroutine(AnimateOrbitLightStreaks());
    }

    private void StopTurnOrbitLights()
    {
        if (orbitCoroutine != null)
        {
            StopCoroutine(orbitCoroutine);
            orbitCoroutine = null;
        }
        if (turnOrbitRootGo != null) turnOrbitRootGo.SetActive(false);
    }

    private IEnumerator AnimateOrbitLightStreaks()
    {
        var rt = GetComponent<RectTransform>();
        float w = rt.rect.width > 0 ? rt.rect.width / 2f : 92f;
        float h = rt.rect.height > 0 ? rt.rect.height / 2f : 122.5f;
        float W = w * 2f;
        float H = h * 2f;
        float P = 2f * (W + H); // Tổng chu vi viền thẻ tướng (858px)

        float currentDist = 0f;
        float speed = 290f; // Tốc độ chạy vù vù quanh viền

        while (true)
        {
            currentDist = (currentDist + Time.deltaTime * speed) % P;

            for (int i = 0; i < 3; i++)
            {
                if (orbitLightStreaks[i] == null) continue;
                float d = (currentDist + (i * P / 3f)) % P;
                Vector2 pos = CalculatePerimeterPosition(d, w, h, W, H);
                orbitLightStreaks[i].anchoredPosition = pos;

                // Hiệu ứng nhấp nháy nhẹ tăng độ huyền ảo
                float pulse = 1f + 0.2f * Mathf.Sin(Time.time * 8f + i);
                orbitLightStreaks[i].localScale = Vector3.one * pulse;
            }
            yield return null;
        }
    }

    private Vector2 CalculatePerimeterPosition(float d, float w, float h, float W, float H)
    {
        // 1. Cạnh Trên (Trái -> Phải)
        if (d < W)
        {
            return new Vector2(-w + d, h);
        }
        d -= W;

        // 2. Cạnh Phải (Trên -> Dưới)
        if (d < H)
        {
            return new Vector2(w, h - d);
        }
        d -= H;

        // 3. Cạnh Dưới (Phải -> Trái)
        if (d < W)
        {
            return new Vector2(w - d, -h);
        }
        d -= W;

        // 4. Cạnh Trái (Dưới -> Trên)
        return new Vector2(-w, -h + d);
    }

    /// <summary>
    /// Hiển thị huy hiệu đếm ngược thời gian ở bên trái avatar tướng (40s, 39s, ..., 1s).
    /// </summary>
    public void ShowHeadTimer(int seconds)
    {
        if (headTimerBadgeGo == null)
        {
            headTimerBadgeGo = new GameObject("HeadTimerBadge", typeof(RectTransform), typeof(Image));
            headTimerBadgeGo.transform.SetParent(transform, false);
            headTimerBadgeGo.transform.SetAsLastSibling();

            var bgImg = headTimerBadgeGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { bgImg.sprite = slotSpr; bgImg.type = Image.Type.Sliced; }
            bgImg.color = new Color(0.04f, 0.08f, 0.16f, 0.98f);

            var rt = headTimerBadgeGo.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0f, 0.5f);
            rt.anchorMax = new Vector2(0f, 0.5f);
            rt.pivot = new Vector2(1f, 0.5f);
            rt.sizeDelta = new Vector2(68f, 28f);
            rt.anchoredPosition = new Vector2(-6f, 62f); // Nằm bên trái avatar, phía trên máu hoa sen

            var frameGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
            frameGo.transform.SetParent(headTimerBadgeGo.transform, false);
            headTimerFrameImg = frameGo.GetComponent<Image>();
            var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (fSpr != null) { headTimerFrameImg.sprite = fSpr; headTimerFrameImg.type = Image.Type.Sliced; }
            headTimerFrameImg.color = new Color(1f, 0.85f, 0.35f, 1f);
            var fRt = frameGo.GetComponent<RectTransform>();
            fRt.anchorMin = Vector2.zero; fRt.anchorMax = Vector2.one;
            fRt.offsetMin = new Vector2(-1, -1); fRt.offsetMax = new Vector2(1, 1);

            var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(headTimerBadgeGo.transform, false);
            headTimerText = txtGo.GetComponent<Text>();
            headTimerText.font = ThemeUI.FontMain;
            headTimerText.fontSize = ThemeUI.SizeBody;
            headTimerText.fontStyle = FontStyle.Bold;
            headTimerText.alignment = TextAnchor.MiddleCenter;
            headTimerText.color = new Color(1f, 0.9f, 0.35f, 1f);
            var tRt = txtGo.GetComponent<RectTransform>();
            tRt.anchorMin = Vector2.zero; tRt.anchorMax = Vector2.one;
            tRt.offsetMin = tRt.offsetMax = Vector2.zero;
        }

        headTimerBadgeGo.SetActive(true);
        UpdateHeadTimer(seconds);
    }

    public void UpdateHeadTimer(int seconds)
    {
        if (headTimerText == null || headTimerBadgeGo == null || !headTimerBadgeGo.activeSelf) return;

        headTimerText.text = $"⏳ {seconds}s";
        if (seconds <= 10)
        {
            headTimerText.color = new Color(1f, 0.35f, 0.35f, 1f);
            if (headTimerFrameImg != null) headTimerFrameImg.color = new Color(1f, 0.3f, 0.3f, 1f);
        }
        else
        {
            headTimerText.color = new Color(1f, 0.9f, 0.35f, 1f);
            if (headTimerFrameImg != null) headTimerFrameImg.color = new Color(1f, 0.85f, 0.35f, 1f);
        }
    }

    public void HideHeadTimer()
    {
        if (headTimerBadgeGo != null) headTimerBadgeGo.SetActive(false);
    }

    private GameObject deadOverlayGo;

    /// <summary>
    /// Hiển thị trạng thái tử trận: Toàn bộ vị trí thẻ tướng bị xám tối và phủ bia tử trận.
    /// </summary>
    /// <summary>
    /// Hiển thị hiệu ứng kích hoạt kỹ năng tướng phát sáng hào quang và hiện banner kỹ năng
    /// </summary>
    public void AnimateSkillTrigger(string skillName)
    {
        StartCoroutine(AnimateSkillTriggerCoroutine(skillName));
    }

    private IEnumerator AnimateSkillTriggerCoroutine(string skillName)
    {
        if (transform == null) yield break;

        var bannerGo = new GameObject("SkillTriggerBanner", typeof(RectTransform), typeof(Image));
        bannerGo.transform.SetParent(transform, false);
        bannerGo.transform.SetAsLastSibling();

        var bImg = bannerGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSpr != null) { bImg.sprite = bgSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.95f, 0.65f, 0.12f, 0.95f);

        var bRt = bannerGo.GetComponent<RectTransform>();
        bRt.anchorMin = bRt.anchorMax = bRt.pivot = new Vector2(0.5f, 0.5f);
        bRt.sizeDelta = new Vector2(160f, 32f);
        bRt.anchoredPosition = new Vector2(0f, 20f);

        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        var txtGo = new GameObject("Txt", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(bannerGo.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 12;
        txt.fontStyle = FontStyle.Bold;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.text = $"✨ {skillName} ✨";
        txt.color = Color.white;
        FillRect(txtGo.GetComponent<RectTransform>());

        var shadow = txtGo.AddComponent<Shadow>();
        shadow.effectColor = new Color(0, 0, 0, 0.9f);
        shadow.effectDistance = new Vector2(1, -1);

        float elapsed = 0f;
        float dur = 1.2f;
        Vector3 initialScale = Vector3.one * 0.7f;
        Vector3 targetScale = Vector3.one * 1.15f;

        while (elapsed < dur)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / dur;
            if (bannerGo == null) yield break;
            bannerGo.transform.localScale = Vector3.Lerp(initialScale, targetScale, Mathf.SmoothStep(0f, 1f, t));
            bRt.anchoredPosition = new Vector2(0f, Mathf.Lerp(15f, 45f, t));
            if (t > 0.6f)
            {
                float a = Mathf.Lerp(1f, 0f, (t - 0.6f) / 0.4f);
                bImg.color = new Color(0.95f, 0.65f, 0.12f, a * 0.95f);
                txt.color = new Color(1f, 1f, 1f, a);
            }
            yield return null;
        }

        if (bannerGo != null) Destroy(bannerGo);
    }

    public void SetAwaitingReaction(bool awaiting)
    {
        if (reactionBlinkCoroutine != null)
        {
            StopCoroutine(reactionBlinkCoroutine);
            reactionBlinkCoroutine = null;
        }

        if (reactionHaloGo == null && transform != null)
        {
            reactionHaloGo = new GameObject("ReactionHalo", typeof(RectTransform), typeof(Image));
            reactionHaloGo.transform.SetParent(transform, false);
            reactionHaloGo.transform.SetAsLastSibling();
            var img = reactionHaloGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (spr != null) { img.sprite = spr; img.type = Image.Type.Sliced; }
            img.color = new Color(1f, 0.88f, 0.25f, 0.95f);
            img.raycastTarget = false;
            FillRect(reactionHaloGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));
        }

        if (awaiting)
        {
            if (reactionHaloGo != null) reactionHaloGo.SetActive(true);
            reactionBlinkCoroutine = StartCoroutine(AnimateReactionBlink());
        }
        else
        {
            if (reactionHaloGo != null) reactionHaloGo.SetActive(false);
            if (avatarRawImage != null) avatarRawImage.color = Color.white;
            if (cardFrameImage != null) cardFrameImage.color = normalFrameColor;
        }
    }

    private IEnumerator AnimateReactionBlink()
    {
        var haloImg = reactionHaloGo != null ? reactionHaloGo.GetComponent<Image>() : null;
        float timer = 0f;

        while (true)
        {
            timer += Time.deltaTime * 4.2f; // Nhịp nhấp nháy nhẹ nhàng êm ái
            float sine = (Mathf.Sin(timer) + 1f) * 0.5f; // Dao động mượt [0..1]

            float alpha = Mathf.Lerp(0.35f, 1.0f, sine);
            if (haloImg != null)
            {
                haloImg.color = new Color(1f, 0.88f, 0.25f, alpha);
            }
            if (avatarRawImage != null)
            {
                float b = Mathf.Lerp(0.80f, 1.20f, sine);
                avatarRawImage.color = new Color(b, b, b, 1f);
            }
            yield return null;
        }
    }

    public void SetDeadVisual(bool isDead)
    {
        deadVisualActive = isDead;
        if (deadOverlayGo == null && isDead)
        {
            deadOverlayGo = new GameObject("DeadOverlay", typeof(RectTransform), typeof(Image));
            deadOverlayGo.transform.SetParent(transform, false);
            deadOverlayGo.transform.SetAsLastSibling();

            var img = deadOverlayGo.GetComponent<Image>();
            img.color = new Color(0.02f, 0.03f, 0.05f, 0.82f);
            var rt = deadOverlayGo.GetComponent<RectTransform>();
            rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
            rt.offsetMin = rt.offsetMax = Vector2.zero;

            var txtGo = new GameObject("DeadText", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(deadOverlayGo.transform, false);
            var txt = txtGo.GetComponent<Text>();
            txt.font = ThemeUI.FontMain;
            txt.fontSize = 14;
            txt.fontStyle = FontStyle.Bold;
            txt.alignment = TextAnchor.MiddleCenter;
            txt.color = new Color(0.85f, 0.35f, 0.35f, 1f);
            txt.text = "☠️\nĐÃ TỬ TRẬN";
            txt.lineSpacing = 1.3f;
            var tRt = txtGo.GetComponent<RectTransform>();
            tRt.anchorMin = Vector2.zero; tRt.anchorMax = Vector2.one;
            tRt.offsetMin = tRt.offsetMax = Vector2.zero;
        }

        if (deadOverlayGo != null)
        {
            deadOverlayGo.SetActive(isDead);
        }

        if (isDead)
        {
            SetTurnActive(false);
            if (avatarImage != null) avatarImage.color = new Color(0.3f, 0.3f, 0.3f, 0.6f);
            if (avatarRawImage != null) avatarRawImage.color = new Color(0.3f, 0.3f, 0.3f, 0.6f);
            if (cardFrameImage != null) cardFrameImage.color = new Color(0.35f, 0.35f, 0.35f, 0.8f);
        }
        else
        {
            if (avatarImage != null) avatarImage.color = Color.white;
            if (avatarRawImage != null) avatarRawImage.color = Color.white;
            if (cardFrameImage != null) cardFrameImage.color = normalFrameColor;
        }
    }

    /// <summary>
    /// Cập nhật thời gian đếm ngược (đồng bộ trên huy hiệu bên trái avatar, không dùng cột vàng).
    /// </summary>
    public void SetTimerVisual(float remaining, float max = 40f, bool visible = true)
    {
        if (visible && remaining > 0f)
        {
            ShowHeadTimer(Mathf.CeilToInt(remaining));
        }
        else
        {
            HideHeadTimer();
        }
    }

    [Header("Equipped Cards Data")]
    private readonly Dictionary<EquipmentType, CardModel> equippedCards = new Dictionary<EquipmentType, CardModel>();

    public CardModel GetEquippedCard(EquipmentType type)
    {
        return equippedCards.TryGetValue(type, out var card) ? card : null;
    }

    /// <summary>
    /// Trang bị một lá và trả lại lá cũ (nếu có) để bên quản lý tay/bộ bài
    /// có thể xử lý việc thay thế mà không làm mất dữ liệu.
    /// </summary>
    public bool TryEquip(CardModel card, out CardModel replacedCard)
    {
        replacedCard = null;
        if (card == null || card.category != CardCategory.Equipment) return false;

        if (!TryGetEquipmentType(card, out var eqType)) return false;
        equippedCards.TryGetValue(eqType, out replacedCard);
        equippedCards[eqType] = card;

        string suitSymbol = card.GetSuitSymbol();
        string rankStr = card.GetRankString();
        string suitRankPrefix = "";
        if (!string.IsNullOrEmpty(suitSymbol) && !string.IsNullOrEmpty(rankStr) && suitSymbol != "?")
        {
            string colorHex = card.IsRed ? "#FF4D4D" : "#E2E8F0";
            suitRankPrefix = $"<color={colorHex}>{suitSymbol}{rankStr}</color> ";
        }

        string displayName = card.subType switch
        {
            CardSubType.Weapon => $"{suitRankPrefix}{card.cardName} (Tầm {card.attackRange})",
            CardSubType.OffensiveHorse => $"{suitRankPrefix}{card.cardName} (-1)",
            CardSubType.DefensiveHorse => $"{suitRankPrefix}{card.cardName} (+1)",
            _ => $"{suitRankPrefix}{card.cardName}"
        };
        var iconSprite = !string.IsNullOrEmpty(card.iconPath) ? LotusHealthUI.LoadSpriteFromResources(card.iconPath) : null;
        RenderEquipment(eqType, displayName, iconSprite);

        if (eqType == EquipmentType.Armor && card != null && card.cardName.Contains("Áo Bào"))
        {
            ResetAoBaoCharges();
        }
        return true;
    }

    [Header("Armor Charges")]
    private int aoBaoCharges = 3;
    public int AoBaoCharges => aoBaoCharges;
    public void ResetAoBaoCharges() => aoBaoCharges = 3;
    public void SetAoBaoCharges(int charges) => aoBaoCharges = Mathf.Clamp(charges, 0, 3);
    public bool TryConsumeAoBaoCharge()
    {
        if (aoBaoCharges > 0)
        {
            aoBaoCharges--;
            return true;
        }
        return false;
    }

    /// <summary>
    /// Gắn trang bị bằng CardModel và cập nhật đầy đủ dữ liệu, icon, và chỉ số.
    /// </summary>
    public void Equip(CardModel card)
    {
        TryEquip(card, out _);
    }

    /// <summary>
    /// Gỡ trang bị theo loại và trả về lá CardModel tương ứng.
    /// </summary>
    public CardModel UnequipCard(EquipmentType type)
    {
        return TryUnequip(type, out var removedCard) ? removedCard : null;
    }

    /// <summary>
    /// Gỡ trang bị an toàn, đồng bộ cả dữ liệu CardModel lẫn ô hiển thị.
    /// Không phát sinh hiệu ứng hồi máu khi tháo/thay Áo Bào Hoàng Tộc.
    /// </summary>
    public bool TryUnequip(EquipmentType type, out CardModel removedCard)
    {
        if (!equippedCards.TryGetValue(type, out removedCard) || removedCard == null)
        {
            removedCard = null;
            UnequipSlot(type);
            return false;
        }

        equippedCards.Remove(type);
        UnequipSlot(type);
        return true;
    }

    /// <summary>
    /// Tầm đánh hiện tại (Mặc định tay không tầm 1, hoặc theo tầm của Vũ khí).
    /// </summary>
    public int GetAttackRange()
    {
        if (equippedCards.TryGetValue(EquipmentType.Weapon, out var weapon) && weapon != null)
        {
            return Mathf.Max(1, weapon.attackRange);
        }
        return 1;
    }

    /// <summary>
    /// Độ lệch khoảng cách tấn công (Ngựa công: -1).
    /// </summary>
    public int GetOffensiveDistanceModifier()
    {
        if (equippedCards.TryGetValue(EquipmentType.OffensiveMount, out var horse) && horse != null)
        {
            return -1;
        }
        return 0;
    }

    /// <summary>
    /// Độ lệch khoảng cách phòng thủ (Ngựa thủ: +1).
    /// </summary>
    public int GetDefensiveDistanceModifier()
    {
        if (equippedCards.TryGetValue(EquipmentType.DefensiveMount, out var horse) && horse != null)
        {
            return 1;
        }
        return 0;
    }

    /// <summary>
    /// Gắn trang bị vào 1 trong 5 dòng.
    /// </summary>
    public void Equip(EquipmentType type, string itemName, Sprite icon = null)
    {
        // Overload này chỉ nhận dữ liệu hiển thị (ví dụ GeneralData/demo),
        // nên xóa CardModel cũ để không giữ lại trạng thái gameplay lỗi thời.
        equippedCards.Remove(type);
        RenderEquipment(type, itemName, icon);
    }

    /// <summary>
    /// Gỡ trang bị khỏi dòng tương ứng.
    /// </summary>
    public void Unequip(EquipmentType type)
    {
        equippedCards.Remove(type);
        UnequipSlot(type);
    }

    private void RenderEquipment(EquipmentType type, string itemName, Sprite icon = null)
    {
        if (slotMap.TryGetValue(type, out var slot) && slot != null)
        {
            slot.Equip(itemName, icon);
        }
    }

    private void UnequipSlot(EquipmentType type)
    {
        if (slotMap.TryGetValue(type, out var slot) && slot != null)
        {
            slot.ClearEquipment();
        }
    }

    private static bool TryGetEquipmentType(CardModel card, out EquipmentType equipmentType)
    {
        equipmentType = card.subType switch
        {
            CardSubType.Weapon => EquipmentType.Weapon,
            CardSubType.Armor => EquipmentType.Armor,
            CardSubType.OffensiveHorse => EquipmentType.OffensiveMount,
            CardSubType.DefensiveHorse => EquipmentType.DefensiveMount,
            _ => (EquipmentType)(-1)
        };

        return equipmentType >= EquipmentType.Weapon && equipmentType <= EquipmentType.Treasure;
    }

    /// <summary>
    /// Kiểm tra tướng có đang trang bị loại trang bị tương ứng hay không.
    /// </summary>
    public bool HasEquipment(EquipmentType type, string keyword = "")
    {
        // CardModel là nguồn dữ liệu chính; fallback vào slot để hỗ trợ
        // GeneralData/demo chỉ cung cấp tên hiển thị.
        if (equippedCards.TryGetValue(type, out var card) && card != null)
        {
            if (string.IsNullOrEmpty(keyword)) return true;
            return !string.IsNullOrEmpty(card.cardName) && card.cardName.Contains(keyword, StringComparison.OrdinalIgnoreCase);
        }

        if (slotMap.TryGetValue(type, out var slot) && slot != null && slot.IsEquipped)
        {
            if (string.IsNullOrEmpty(keyword)) return true;
            return slot.CurrentItemName != null && slot.CurrentItemName.IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0;
        }
        return false;
    }

    [Header("Judgement Zone (Vùng Phán Xét / Cẩm Nang Trì Hoãn)")]
    private readonly List<CardModel> delayedScrolls = new List<CardModel>();

    public IReadOnlyList<CardModel> DelayedScrolls => delayedScrolls;

    public bool AddDelayedScroll(CardModel scrollCard)
    {
        // Một số luồng/tutorial tạo CardModel tối giản chỉ có subType, vì vậy
        // không khóa theo category ở đây; caller chịu trách nhiệm phân loại lá.
        if (scrollCard == null) return false;
        if (HasDelayedScroll(scrollCard.subType)) return false;

        delayedScrolls.Add(scrollCard);
        RefreshJudgementZoneUI();
        return true;
    }

    /// <summary>
    /// Tên rõ nghĩa cho các caller cần biết việc gài trì hoãn có thành công không.
    /// </summary>
    public bool TryAddDelayedScroll(CardModel scrollCard)
    {
        return AddDelayedScroll(scrollCard);
    }

    public bool RemoveDelayedScroll(CardSubType subType)
    {
        int idx = delayedScrolls.FindIndex(c => c.subType == subType);
        if (idx >= 0)
        {
            delayedScrolls.RemoveAt(idx);
            RefreshJudgementZoneUI();
            return true;
        }
        return false;
    }

    public bool HasDelayedScroll(CardSubType subType)
    {
        return delayedScrolls.Exists(c => c.subType == subType);
    }

    public CardModel GetDelayedScroll(CardSubType subType)
    {
        return delayedScrolls.Find(c => c.subType == subType);
    }

    public void ClearDelayedScrolls()
    {
        delayedScrolls.Clear();
        RefreshJudgementZoneUI();
    }

    public void SetJudgementZonePlacement(bool isRightSide, Vector2? customOffset = null)
    {
        if (judgementZoneGo == null) return;
        var jRt = judgementZoneGo.GetComponent<RectTransform>();

        // Xóa cả hai layout group cũ trước (dùng DestroyImmediate vì Destroy chỉ xóa cuối frame)
        var oldVlg = judgementZoneGo.GetComponent<VerticalLayoutGroup>();
        if (oldVlg != null) DestroyImmediate(oldVlg);
        var oldHlg = judgementZoneGo.GetComponent<HorizontalLayoutGroup>();
        if (oldHlg != null) DestroyImmediate(oldHlg);

        if (isRightSide)
        {
            // Đặt dọc bên phải thẻ tướng
            jRt.anchorMin = new Vector2(1f, 0.5f);
            jRt.anchorMax = new Vector2(1f, 0.5f);
            jRt.pivot = new Vector2(0f, 0.5f);
            jRt.sizeDelta = new Vector2(110f, 160f);
            jRt.anchoredPosition = customOffset ?? new Vector2(8f, 0f);
            var vlg = judgementZoneGo.AddComponent<VerticalLayoutGroup>();
            vlg.spacing = 6f;
            vlg.childAlignment = TextAnchor.MiddleLeft;
            vlg.childControlWidth = false;
            vlg.childControlHeight = false;
        }
        else
        {
            // Đặt ngang phía trên thẻ tướng
            jRt.anchorMin = new Vector2(0f, 1f);
            jRt.anchorMax = new Vector2(1f, 1f);
            jRt.pivot = new Vector2(0.5f, 0f);
            jRt.sizeDelta = new Vector2(0, 32f);
            jRt.anchoredPosition = customOffset ?? new Vector2(0, 6f);
            var hlg = judgementZoneGo.AddComponent<HorizontalLayoutGroup>();
            hlg.spacing = 6f;
            hlg.childAlignment = TextAnchor.MiddleCenter;
            hlg.childControlWidth = false;
            hlg.childControlHeight = false;
        }
    }

    private void RefreshJudgementZoneUI()
    {
        if (judgementZoneGo == null) return;
        foreach (Transform child in judgementZoneGo.transform)
        {
            Destroy(child.gameObject);
        }

        var font = ThemeUI.FontMain;

        foreach (var scroll in delayedScrolls)
        {
            var badgeGo = new GameObject("Scroll_" + scroll.subType, typeof(RectTransform), typeof(Image));
            badgeGo.transform.SetParent(judgementZoneGo.transform, false);
            var bImg = badgeGo.GetComponent<Image>();
            var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
            if (bgSpr != null) { bImg.sprite = bgSpr; bImg.type = Image.Type.Sliced; }
            bImg.color = scroll.subType switch
            {
                CardSubType.Lightning => new Color(0.48f, 0.15f, 0.65f, 1f),
                CardSubType.SupplyShortage => new Color(0.72f, 0.45f, 0.12f, 1f),
                CardSubType.Acedia => new Color(0.15f, 0.38f, 0.65f, 1f),
                _ => new Color(0.25f, 0.25f, 0.25f, 1f)
            };

            var bRt = badgeGo.GetComponent<RectTransform>();
            bRt.sizeDelta = new Vector2(104f, 28f);

            var txtGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(badgeGo.transform, false);
            var txt = txtGo.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 11;
            txt.fontStyle = FontStyle.Bold;
            txt.alignment = TextAnchor.MiddleCenter;
            txt.color = Color.white;
            txt.text = scroll.subType switch
            {
                CardSubType.Lightning => "⚡ THẦN SẤM",
                CardSubType.SupplyShortage => "🌾 CẮT LƯƠNG",
                CardSubType.Acedia => "🕸️ TRẦM ẢO",
                _ => scroll.cardName
            };
            var shadow = txtGo.AddComponent<Shadow>();
            shadow.effectColor = new Color(0, 0, 0, 0.95f);
            shadow.effectDistance = new Vector2(1f, -1f);
            FillRect(txtGo.GetComponent<RectTransform>());
        }
    }

    /// <summary>
    /// Gỡ toàn bộ 5 dòng trang bị.
    /// </summary>
    public void ClearAllEquipment()
    {
        equippedCards.Clear();
        foreach (var slot in slotMap.Values)
        {
            if (slot != null) slot.ClearEquipment();
        }
    }

    public void RefreshUI()
    {
        SetGeneralName(generalName);
        SetFaction(factionName);
        SetHandCardCount(handCardCount);
        if (lotusHealthUI != null) lotusHealthUI.Setup(currentHp, maxHp);
    }

    #region Procedural Factory / Runtime Builder
    /// <summary>
    /// Tạo nhanh một GeneralCardUI hoàn chỉnh bằng code, tỉ lệ 3x4 chuẩn.
    /// </summary>
    public static GeneralCardUI Create(Transform parent, Vector2 cardSize, string name = "Lý Thường Kiệt", string faction = "Khác", int hp = 4, int handCards = 4, string avatarResourcePath = "UI/ly_thuong_kiet")
    {
        // Kích thước chuẩn 3x4: ví dụ 270x360 hoặc 300x400
        var root = new GameObject("GeneralCard_" + name, typeof(RectTransform));
        root.transform.SetParent(parent, false);

        var rootRect = root.GetComponent<RectTransform>();
        rootRect.sizeDelta = cardSize;

        var card = root.AddComponent<GeneralCardUI>();
        card.BuildHierarchy(cardSize);
        card.SetGeneralName(name);
        card.SetFaction(faction);
        card.SetHealth(hp, hp);
        card.SetHandCardCount(handCards);

        if (!string.IsNullOrEmpty(avatarResourcePath))
        {
            var tex = Resources.Load<Texture2D>(avatarResourcePath);
            if (tex != null) card.SetAvatar(tex);
        }

        return card;
    }

    public void BuildHierarchy(Vector2 cardSize)
    {
        var rootTransform = transform;
        var font = ThemeUI.FontMain;

        var rootImg = GetComponent<Image>();
        if (rootImg == null) rootImg = gameObject.AddComponent<Image>();
        rootImg.color = new Color(1f, 1f, 1f, 0.001f);
        rootImg.raycastTarget = true;

        // 1. Nền Card & Avatar Tỉ lệ 3:4
        var avatarGo = new GameObject("Avatar", typeof(RectTransform), typeof(RawImage));
        avatarGo.transform.SetParent(rootTransform, false);
        avatarRawImage = avatarGo.GetComponent<RawImage>();
        avatarRawImage.raycastTarget = true;
        var avatarRt = avatarGo.GetComponent<RectTransform>();
        FillRect(avatarRt);

        // Nền bóng mờ phía sau
        var shadowGo = new GameObject("CardShadow", typeof(RectTransform), typeof(Image));
        shadowGo.transform.SetParent(rootTransform, false);
        shadowGo.transform.SetAsFirstSibling();
        var shadowImg = shadowGo.GetComponent<Image>();
        shadowImg.color = new Color(0, 0, 0, 0.4f);
        var shadowRt = shadowGo.GetComponent<RectTransform>();
        FillRect(shadowRt, new Vector2(-6, -6), new Vector2(6, 6));

        // 2. Card Frame viền vàng cổ điển
        var frameGo = new GameObject("CardFrame", typeof(RectTransform), typeof(Image));
        frameGo.transform.SetParent(rootTransform, false);
        cardFrameImage = frameGo.GetComponent<Image>();
        var frameSprite = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSprite != null)
        {
            cardFrameImage.sprite = frameSprite;
            cardFrameImage.type = Image.Type.Sliced;
        }
        cardFrameImage.color = Color.white;
        cardFrameImage.raycastTarget = false;
        var frameRt = frameGo.GetComponent<RectTransform>();
        FillRect(frameRt, new Vector2(-2, -2), new Vector2(2, 2));

        // 3. Thanh tên tướng (Top Center)
        var plaqueGo = new GameObject("NamePlaque", typeof(RectTransform), typeof(Image));
        plaqueGo.transform.SetParent(rootTransform, false);
        namePlaqueImage = plaqueGo.GetComponent<Image>();
        var plaqueSprite = LotusHealthUI.LoadSpriteFromResources("UI/name_plaque");
        if (plaqueSprite != null)
        {
            namePlaqueImage.sprite = plaqueSprite;
            namePlaqueImage.type = Image.Type.Sliced;
        }
        else
        {
            namePlaqueImage.color = new Color(0.08f, 0.1f, 0.16f, 0.95f);
        }
        var plaqueRt = plaqueGo.GetComponent<RectTransform>();
        plaqueRt.anchorMin = new Vector2(0.5f, 1f);
        plaqueRt.anchorMax = new Vector2(0.5f, 1f);
        plaqueRt.pivot = new Vector2(0.5f, 1f);
        plaqueRt.sizeDelta = new Vector2(cardSize.x * 0.9f, 32f);
        // Giữ bảng tên đúng tâm theo chiều ngang của avatar.
        plaqueRt.anchoredPosition = new Vector2(0f, -4f);

        var nameTextGo = new GameObject("NameText", typeof(RectTransform), typeof(Text));
        nameTextGo.transform.SetParent(plaqueGo.transform, false);
        generalNameText = nameTextGo.GetComponent<Text>();
        generalNameText.font = font;
        generalNameText.fontSize = ThemeUI.SizeBodyLarge;
        generalNameText.fontStyle = FontStyle.Bold;
        generalNameText.alignment = TextAnchor.MiddleCenter;
        generalNameText.color = new Color(1f, 0.88f, 0.45f, 1f);
        generalNameText.raycastTarget = false;
        generalNameText.horizontalOverflow = HorizontalWrapMode.Overflow;
        generalNameText.verticalOverflow = VerticalWrapMode.Overflow;
        var nameShadow = nameTextGo.AddComponent<Shadow>();
        nameShadow.effectColor = new Color(0, 0, 0, 0.95f);
        nameShadow.effectDistance = new Vector2(1.5f, -1.5f);
        FillRect(nameTextGo.GetComponent<RectTransform>());

        plaqueGo.transform.SetAsLastSibling();

        // 4. Huy hiệu Phe (Bottom Left)
        var factionBadgeGo = new GameObject("FactionBadge", typeof(RectTransform), typeof(Image));
        factionBadgeGo.transform.SetParent(rootTransform, false);
        factionBadgeImage = factionBadgeGo.GetComponent<Image>();
        var badgeSprite = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSprite != null)
        {
            factionBadgeImage.sprite = badgeSprite;
            factionBadgeImage.type = Image.Type.Sliced;
        }
        else
        {
            factionBadgeImage.color = new Color(0.55f, 0.12f, 0.12f, 0.95f);
        }
        var badgeRt = factionBadgeGo.GetComponent<RectTransform>();
        badgeRt.anchorMin = new Vector2(0f, 0f);
        badgeRt.anchorMax = new Vector2(0f, 0f);
        badgeRt.pivot = new Vector2(0f, 0f);
        badgeRt.sizeDelta = new Vector2(74f, 30f);
        badgeRt.anchoredPosition = new Vector2(4f, 4f);

        var factionTextGo = new GameObject("FactionText", typeof(RectTransform), typeof(Text));
        factionTextGo.transform.SetParent(factionBadgeGo.transform, false);
        factionText = factionTextGo.GetComponent<Text>();
        factionText.font = font;
        factionText.fontSize = ThemeUI.SizeMicro;
        factionText.fontStyle = FontStyle.Bold;
        factionText.alignment = TextAnchor.MiddleCenter;
        factionText.color = new Color(1f, 0.95f, 0.85f, 1f);
        factionText.raycastTarget = false;
        factionText.horizontalOverflow = HorizontalWrapMode.Overflow;
        factionText.verticalOverflow = VerticalWrapMode.Overflow;
        var factionShadow = factionTextGo.AddComponent<Shadow>();
        factionShadow.effectColor = new Color(0, 0, 0, 0.95f);
        factionShadow.effectDistance = new Vector2(1f, -1f);
        FillRect(factionTextGo.GetComponent<RectTransform>());

        factionBadgeGo.transform.SetAsLastSibling();
        factionShadow.effectDistance = new Vector2(1f, -1f);
        FillRect(factionTextGo.GetComponent<RectTransform>());

        // 4.5 Nút Thông Tin Dấu Chấm Than [!] trên Avatar Tướng
        var infoBtnGo = new GameObject("InfoButton", typeof(RectTransform), typeof(Image), typeof(Button));
        infoBtnGo.transform.SetParent(rootTransform, false);
        infoBtnGo.transform.SetAsLastSibling();
        var infoImg = infoBtnGo.GetComponent<Image>();
        var infoSlotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (infoSlotSpr != null) { infoImg.sprite = infoSlotSpr; infoImg.type = Image.Type.Sliced; }
        infoImg.color = new Color(0.12f, 0.18f, 0.32f, 0.96f);

        var infoRt = infoBtnGo.GetComponent<RectTransform>();
        infoRt.anchorMin = new Vector2(1f, 1f);
        infoRt.anchorMax = new Vector2(1f, 1f);
        infoRt.pivot = new Vector2(1f, 1f);
        infoRt.sizeDelta = new Vector2(28f, 28f);
        infoRt.anchoredPosition = new Vector2(-4f, -38f);

        var infoBorderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        infoBorderGo.transform.SetParent(infoBtnGo.transform, false);
        var ibImg = infoBorderGo.GetComponent<Image>();
        var ibSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (ibSpr != null) { ibImg.sprite = ibSpr; ibImg.type = Image.Type.Sliced; }
        ibImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        FillRect(infoBorderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var markGo = new GameObject("Mark", typeof(RectTransform), typeof(Text));
        markGo.transform.SetParent(infoBtnGo.transform, false);
        var markTxt = markGo.GetComponent<Text>();
        markTxt.font = font;
        markTxt.fontSize = 17;
        markTxt.fontStyle = FontStyle.Bold;
        markTxt.alignment = TextAnchor.MiddleCenter;
        markTxt.text = "!";
        markTxt.color = new Color(1f, 0.88f, 0.35f, 1f);
        var markShadow = markGo.AddComponent<Shadow>();
        markShadow.effectColor = new Color(0, 0, 0, 0.9f);
        markShadow.effectDistance = new Vector2(1f, -1f);
        FillRect(markGo.GetComponent<RectTransform>());

        infoBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            ShowGeneralInfoModal();
        });

        // 5. Cột Máu Hoa Sen (Lotus Health) - Đặt bên trái avatar, sát avatar, tách rời không trùng lên avatar
        var healthGo = new GameObject("LotusHealth", typeof(RectTransform), typeof(LotusHealthUI));
        healthGo.transform.SetParent(rootTransform, false);
        lotusHealthUI = healthGo.GetComponent<LotusHealthUI>();
        var healthRt = healthGo.GetComponent<RectTransform>();
        healthRt.anchorMin = new Vector2(0f, 0.5f);
        healthRt.anchorMax = new Vector2(0f, 0.5f);
        healthRt.pivot = new Vector2(1f, 0.5f);
        healthRt.anchoredPosition = new Vector2(-6f, 2f); // Hạ thấp máu xuống để cân đối và thoáng mắt

        // 5.5 Nút Kỹ Năng Tướng (Bên trái avatar, ngay dưới cột máu hoa sen)
        skillButtonGo = new GameObject("SkillButton", typeof(RectTransform), typeof(Image), typeof(Button));
        skillButtonGo.transform.SetParent(rootTransform, false);
        skillBtnImg = skillButtonGo.GetComponent<Image>();
        var skillBgSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (skillBgSpr != null) { skillBtnImg.sprite = skillBgSpr; skillBtnImg.type = Image.Type.Sliced; }
        skillBtnImg.color = new Color(0.08f, 0.10f, 0.14f, 0.65f);
        skillButton = skillButtonGo.GetComponent<Button>();

        var sRt = skillButtonGo.GetComponent<RectTransform>();
        sRt.anchorMin = new Vector2(0f, 0.5f);
        sRt.anchorMax = new Vector2(0f, 0.5f);
        sRt.pivot = new Vector2(1f, 0.5f);
        sRt.sizeDelta = new Vector2(84f, 36f);
        sRt.anchoredPosition = new Vector2(-6f, -65f);

        // Hào quang phát sáng khi dùng được
        skillHaloGo = new GameObject("SkillHalo", typeof(RectTransform), typeof(Image));
        skillHaloGo.transform.SetParent(skillButtonGo.transform, false);
        var shImg = skillHaloGo.GetComponent<Image>();
        var haloSpr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        if (haloSpr != null) { shImg.sprite = haloSpr; }
        shImg.color = new Color(1f, 0.85f, 0.2f, 0.85f);
        shImg.raycastTarget = false;
        FillRect(skillHaloGo.GetComponent<RectTransform>(), new Vector2(-8, -8), new Vector2(8, 8));
        skillHaloGo.SetActive(false);

        // Viền nút kỹ năng
        var sBorderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        sBorderGo.transform.SetParent(skillButtonGo.transform, false);
        skillBorderImg = sBorderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { skillBorderImg.sprite = frameSpr; skillBorderImg.type = Image.Type.Sliced; }
        skillBorderImg.color = new Color(0.25f, 0.30f, 0.38f, 0.45f);
        skillBorderImg.raycastTarget = false;
        FillRect(sBorderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var sTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        sTxtGo.transform.SetParent(skillButtonGo.transform, false);
        skillButtonText = sTxtGo.GetComponent<Text>();
        skillButtonText.font = font;
        skillButtonText.fontSize = ThemeUI.SizeMicro;
        skillButtonText.fontStyle = FontStyle.Bold;
        skillButtonText.text = "⚡ KỸ NĂNG";
        skillButtonText.color = new Color(0.42f, 0.48f, 0.55f, 0.7f);
        skillButtonText.alignment = TextAnchor.MiddleCenter;
        var sShadow = sTxtGo.AddComponent<Shadow>();
        sShadow.effectColor = new Color(0, 0, 0, 0.95f);
        sShadow.effectDistance = new Vector2(1f, -1f);
        FillRect(sTxtGo.GetComponent<RectTransform>());
        skillButtonGo.SetActive(false);

        // 5.8 Vùng Phán Xét / Cẩm Nang Trì Hoãn (Judgement Zone)
        judgementZoneGo = new GameObject("JudgementZone", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        judgementZoneGo.transform.SetParent(rootTransform, false);
        var jRt = judgementZoneGo.GetComponent<RectTransform>();
        jRt.anchorMin = new Vector2(0f, 1f);
        jRt.anchorMax = new Vector2(1f, 1f);
        jRt.pivot = new Vector2(0.5f, 0f);
        jRt.sizeDelta = new Vector2(0, 24f);
        jRt.anchoredPosition = new Vector2(0, 4f);
        var hlg = judgementZoneGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 4f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = false;
        hlg.childControlHeight = false;
        hlg.childForceExpandWidth = false;
        hlg.childForceExpandHeight = false;

        // 6. 5 Dòng Trang Bị (Kéo dài toàn bộ khung avatar, cỡ chữ 1.5x to rõ)
        var eqContainerGo = new GameObject("EquipmentSlots", typeof(RectTransform));
        eqContainerGo.transform.SetParent(rootTransform, false);
        var eqRt = eqContainerGo.GetComponent<RectTransform>();
        eqRt.anchorMin = new Vector2(0f, 0f);
        eqRt.anchorMax = new Vector2(1f, 1f);
        eqRt.pivot = new Vector2(0.5f, 0.5f);
        eqRt.offsetMin = new Vector2(6f, 32f);
        eqRt.offsetMax = new Vector2(-6f, -38f);

        float slotHeight = 26f;
        float slotSpacing = 3f;
        float startY = -42f;

        weaponSlot = CreateSlot(eqContainerGo.transform, EquipmentType.Weapon, "WeaponSlot", new Vector2(0, startY), slotHeight, font);
        armorSlot = CreateSlot(eqContainerGo.transform, EquipmentType.Armor, "ArmorSlot", new Vector2(0, startY - (slotHeight + slotSpacing)), slotHeight, font);
        offensiveMountSlot = CreateSlot(eqContainerGo.transform, EquipmentType.OffensiveMount, "OffensiveMountSlot", new Vector2(0, startY - 2 * (slotHeight + slotSpacing)), slotHeight, font);
        defensiveMountSlot = CreateSlot(eqContainerGo.transform, EquipmentType.DefensiveMount, "DefensiveMountSlot", new Vector2(0, startY - 3 * (slotHeight + slotSpacing)), slotHeight, font);
        treasureSlot = CreateSlot(eqContainerGo.transform, EquipmentType.Treasure, "TreasureSlot", new Vector2(0, startY - 4 * (slotHeight + slotSpacing)), slotHeight, font);

        // 7. Huy hiệu Số Bài Trên Tay (Góc dưới bên phải)
        handCardsBadgeGo = new GameObject("HandCardsBadge", typeof(RectTransform), typeof(Image));
        handCardsBadgeGo.transform.SetParent(rootTransform, false);
        var badgeImg = handCardsBadgeGo.GetComponent<Image>();
        var badgeBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (badgeBgSprite != null)
        {
            badgeImg.sprite = badgeBgSprite;
            badgeImg.type = Image.Type.Sliced;
        }
        badgeImg.color = new Color(0.08f, 0.12f, 0.2f, 0.88f);

        var hcRt = handCardsBadgeGo.GetComponent<RectTransform>();
        hcRt.anchorMin = new Vector2(1f, 0f);
        hcRt.anchorMax = new Vector2(1f, 0f);
        hcRt.pivot = new Vector2(1f, 0f);
        hcRt.sizeDelta = new Vector2(58f, 28f);
        hcRt.anchoredPosition = new Vector2(-6f, 6f);

        // Icon lá bài
        var iconCardGo = new GameObject("CardIcon", typeof(RectTransform), typeof(Image));
        iconCardGo.transform.SetParent(handCardsBadgeGo.transform, false);
        var cardIconImg = iconCardGo.GetComponent<Image>();
        cardIconImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/icon_hand_cards");
        cardIconImg.preserveAspect = true;
        cardIconImg.raycastTarget = false;
        var iconRt = iconCardGo.GetComponent<RectTransform>();
        iconRt.anchorMin = new Vector2(0f, 0.5f);
        iconRt.anchorMax = new Vector2(0f, 0.5f);
        iconRt.pivot = new Vector2(0f, 0.5f);
        iconRt.sizeDelta = new Vector2(20f, 20f);
        iconRt.anchoredPosition = new Vector2(4f, 0);

        // Số bài trên tay
        var countTextGo = new GameObject("CountText", typeof(RectTransform), typeof(Text));
        countTextGo.transform.SetParent(handCardsBadgeGo.transform, false);
        handCardsText = countTextGo.GetComponent<Text>();
        handCardsText.font = font;
        handCardsText.fontSize = ThemeUI.SizeBody;
        handCardsText.fontStyle = FontStyle.Bold;
        handCardsText.alignment = TextAnchor.MiddleCenter;
        handCardsText.color = new Color(1f, 0.92f, 0.65f, 1f);
        handCardsText.text = handCardCount.ToString();
        handCardsText.raycastTarget = false;
        var countShadow = countTextGo.AddComponent<Shadow>();
        countShadow.effectColor = new Color(0, 0, 0, 0.95f);
        countShadow.effectDistance = new Vector2(1, -1);
        var countRt = countTextGo.GetComponent<RectTransform>();
        countRt.anchorMin = new Vector2(0f, 0f);
        countRt.anchorMax = new Vector2(1f, 1f);
        countRt.pivot = new Vector2(0.5f, 0.5f);
        countRt.offsetMin = new Vector2(24f, 0);
        countRt.offsetMax = new Vector2(-2f, 0);

        CacheSlotMap();
    }

    private EquipmentSlotUI CreateSlot(Transform parent, EquipmentType type, string objectName, Vector2 pos, float height, Font font)
    {
        var slotGo = new GameObject(objectName, typeof(RectTransform), typeof(Image), typeof(EquipmentSlotUI));
        slotGo.transform.SetParent(parent, false);

        var rt = slotGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.pivot = new Vector2(0f, 1f);
        rt.sizeDelta = new Vector2(0, height);
        rt.anchoredPosition = pos;

        var img = slotGo.GetComponent<Image>();
        var slotBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotBgSprite != null)
        {
            img.sprite = slotBgSprite;
            img.type = Image.Type.Sliced;
        }
        img.color = new Color(0.06f, 0.08f, 0.14f, 0.45f);

        // Category Icon (Weapon/Armor/Mount/Treasure subtle icon)
        var catGo = new GameObject("CategoryIcon", typeof(RectTransform), typeof(Image));
        catGo.transform.SetParent(slotGo.transform, false);
        var catImg = catGo.GetComponent<Image>();
        catImg.raycastTarget = false;
        catImg.preserveAspect = true;
        var catRt = catGo.GetComponent<RectTransform>();
        catRt.anchorMin = new Vector2(0f, 0.5f);
        catRt.anchorMax = new Vector2(0f, 0.5f);
        catRt.pivot = new Vector2(0f, 0.5f);
        catRt.sizeDelta = new Vector2(height - 4f, height - 4f);
        catRt.anchoredPosition = new Vector2(4f, 0);

        var textGo = new GameObject("ItemNameText", typeof(RectTransform), typeof(Text));
        textGo.transform.SetParent(slotGo.transform, false);
        var txt = textGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 17;
        txt.fontStyle = FontStyle.Bold;
        txt.alignment = TextAnchor.MiddleLeft;
        txt.color = new Color(1f, 0.94f, 0.72f, 1f);
        txt.raycastTarget = false;
        txt.supportRichText = true;
        txt.resizeTextForBestFit = true;
        txt.resizeTextMinSize = 13;
        txt.resizeTextMaxSize = 17;
        var txtShadow = textGo.AddComponent<Shadow>();
        txtShadow.effectColor = new Color(0, 0, 0, 0.95f);
        txtShadow.effectDistance = new Vector2(1, -1);
        var txtRt = textGo.GetComponent<RectTransform>();
        txtRt.anchorMin = new Vector2(0f, 0f);
        txtRt.anchorMax = new Vector2(1f, 1f);
        txtRt.pivot = new Vector2(0f, 0.5f);
        txtRt.offsetMin = new Vector2(height + 2f, 0);
        txtRt.offsetMax = new Vector2(-4f, 0);
        textGo.SetActive(false);

        var slotUI = slotGo.GetComponent<EquipmentSlotUI>();
        slotUI.Init(type);
        return slotUI;
    }

    private static void FillRect(RectTransform rt, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.offsetMin = offsetMin;
        rt.offsetMax = offsetMax;
    }

    private GameObject currentInfoModal;

    public void ShowGeneralInfoModal()
    {
        if (currentInfoModal != null) Destroy(currentInfoModal);

        var canvas = GetComponentInParent<Canvas>();
        if (canvas == null) return;

        var font = ThemeUI.FontMain;

        // Modal Root
        var modalRoot = new GameObject("GeneralInfoModal", typeof(RectTransform), typeof(Image));
        modalRoot.transform.SetParent(canvas.transform, false);
        modalRoot.transform.SetAsLastSibling();
        currentInfoModal = modalRoot;

        var bgImg = modalRoot.GetComponent<Image>();
        bgImg.color = new Color(0.02f, 0.04f, 0.08f, 0.85f);
        FillRect(modalRoot.GetComponent<RectTransform>());

        // Box chính giữa
        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(modalRoot.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.08f, 0.12f, 0.22f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = new Vector2(860f, 580f);
        boxRt.anchoredPosition = Vector2.zero;

        // Viền vàng phát sáng
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(boxGo.transform, false);
        var borImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        FillRect(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        string generalName = generalNameText != null ? generalNameText.text : "Chiến Tướng";
        string factionStr = factionText != null ? factionText.text : "Khác";

        // Tiêu đề modal (1.5x: 25pt)
        var titleTxt = AddModalText(boxGo.transform, "Title", $"🎖️ THÔNG TIN TƯỚNG & TRANG BỊ: {generalName.ToUpper()}", 25, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, font);
        SetModalRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(760f, 38f), new Vector2(0, -12f));

        var div = new GameObject("Divider", typeof(RectTransform), typeof(Image));
        div.transform.SetParent(boxGo.transform, false);
        var dImg = div.GetComponent<Image>();
        var dSpr = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        if (dSpr != null) dImg.sprite = dSpr;
        dImg.color = new Color(1f, 0.85f, 0.35f, 0.9f);
        var dRt = div.GetComponent<RectTransform>();
        dRt.anchorMin = dRt.anchorMax = dRt.pivot = new Vector2(0.5f, 1f);
        dRt.sizeDelta = new Vector2(480f, 10f);
        dRt.anchoredPosition = new Vector2(0, -50f);

        // Nút Đóng [X] (1.5x: 20pt)
        var closeBtnGo = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        closeBtnGo.transform.SetParent(boxGo.transform, false);
        var cImg = closeBtnGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { cImg.sprite = slotSpr; cImg.type = Image.Type.Sliced; }
        cImg.color = new Color(0.6f, 0.15f, 0.15f, 0.95f);

        var cRt = closeBtnGo.GetComponent<RectTransform>();
        cRt.anchorMin = cRt.anchorMax = cRt.pivot = new Vector2(1f, 1f);
        cRt.sizeDelta = new Vector2(40f, 40f);
        cRt.anchoredPosition = new Vector2(-12f, -12f);

        var xTxt = AddModalText(closeBtnGo.transform, "X", "✕", 20, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, font);
        FillRect(xTxt.rectTransform);
        closeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            Destroy(modalRoot);
        });

        // BÊN TRÁI: Avatar & Chỉ Số Cơ Bản
        var leftCol = new GameObject("LeftCol", typeof(RectTransform));
        leftCol.transform.SetParent(boxGo.transform, false);
        var lcRt = leftCol.GetComponent<RectTransform>();
        lcRt.anchorMin = new Vector2(0f, 0f);
        lcRt.anchorMax = new Vector2(0.32f, 1f);
        lcRt.offsetMin = new Vector2(20f, 20f);
        lcRt.offsetMax = new Vector2(0f, -60f);

        // Avatar Tướng
        var avGo = new GameObject("Avatar", typeof(RectTransform), typeof(RawImage));
        avGo.transform.SetParent(leftCol.transform, false);
        var avRaw = avGo.GetComponent<RawImage>();
        if (avatarRawImage != null) avRaw.texture = avatarRawImage.texture;
        var avRt = avGo.GetComponent<RectTransform>();
        avRt.anchorMin = avRt.anchorMax = avRt.pivot = new Vector2(0.5f, 0.72f);
        avRt.sizeDelta = new Vector2(180f, 235f);

        var avFrame = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        avFrame.transform.SetParent(avGo.transform, false);
        var afImg = avFrame.GetComponent<Image>();
        if (frameSpr != null) { afImg.sprite = frameSpr; afImg.type = Image.Type.Sliced; }
        afImg.color = new Color(1f, 0.85f, 0.35f, 1f);
        FillRect(avFrame.GetComponent<RectTransform>(), new Vector2(-3, -3), new Vector2(3, 3));

        // Thông tin tóm tắt bên dưới avatar (1.5x: 18pt)
        var genInfoTxt = AddModalText(leftCol.transform, "GeneralInfo",
            $"<b>Máu:</b> <color=#FF5555>{currentHp}/{maxHp} Đóa Sen</color>\n" +
            $"<b>Phe Phái:</b> <color=#55FF55>{factionStr}</color>\n" +
            $"<b>Số Bài Trên Tay:</b> <color=#FFD700>{handCardCount} lá</color>",
            18, new Color(0.9f, 0.94f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, font);
        genInfoTxt.lineSpacing = 1.25f;
        SetModalRect(genInfoTxt.rectTransform, new Vector2(0.5f, 0.12f), new Vector2(0.5f, 0.12f), new Vector2(0.5f, 0.5f), new Vector2(250f, 95f), Vector2.zero);

        // BÊN PHẢI: KỸ NĂNG TƯỚNG & KỸ NĂNG TRANG BỊ ĐANG MANG
        var rightCol = new GameObject("RightCol", typeof(RectTransform));
        rightCol.transform.SetParent(boxGo.transform, false);
        var rcRt = rightCol.GetComponent<RectTransform>();
        rcRt.anchorMin = new Vector2(0.32f, 0f);
        rcRt.anchorMax = new Vector2(1f, 1f);
        rcRt.offsetMin = new Vector2(10f, 20f);
        rcRt.offsetMax = new Vector2(-20f, -60f);

        // 1. Khối Kỹ Năng Tướng
        var skillBox = new GameObject("SkillBox", typeof(RectTransform), typeof(Image));
        skillBox.transform.SetParent(rightCol.transform, false);
        var sbImg = skillBox.GetComponent<Image>();
        if (slotSpr != null) { sbImg.sprite = slotSpr; sbImg.type = Image.Type.Sliced; }
        sbImg.color = new Color(0.12f, 0.16f, 0.26f, 0.95f);
        var sbRt = skillBox.GetComponent<RectTransform>();
        sbRt.anchorMin = new Vector2(0f, 1f);
        sbRt.anchorMax = new Vector2(1f, 1f);
        sbRt.pivot = new Vector2(0.5f, 1f);
        sbRt.sizeDelta = new Vector2(0f, 120f);
        sbRt.anchoredPosition = Vector2.zero;

        // Lấy đúng kỹ năng và thông tin của vị tướng đang dùng từ HeroDatabase100
        var heroData = HeroDatabase100.GetHeroByName(generalName);
        string skillName = heroData != null && !string.IsNullOrEmpty(heroData.skillName) ? heroData.skillName : "Tiến Thoái";
        string skillDesc = heroData != null && !string.IsNullOrEmpty(heroData.skillDesc) ? heroData.skillDesc : "Kỹ năng chiến đấu của danh tướng Đại Việt.";
        string skillTitle = $"⚡ TUYỆT KỸ TƯỚNG: [{skillName.ToUpper()}] (Nội tại / Tuyệt kỹ)";

        if (heroData != null && !string.IsNullOrEmpty(heroData.faction))
        {
            factionStr = heroData.faction;
        }

        if (generalName.Contains("Sơn Tặc") || generalName.Contains("Thổ Phỉ"))
        {
            skillTitle = "🗡️ TUYỆT KỸ TƯỚNG: [CƯỚP BÓC] (Bị động)";
            skillDesc = "Khi bắt đầu lượt rút bài, thủ lĩnh Sơn Tặc có thể cướp lấy 1 lá bài trên tay hoặc trang bị của đối phương thay vì rút từ bộ bài.";
        }

        // 1.5x: 18pt
        var sbTitleTxt = AddModalText(skillBox.transform, "Title", skillTitle, 18, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, font);
        SetModalRect(sbTitleTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-24f, 28f), new Vector2(14f, -6f));

        // 1.5x: 16pt
        var sbDescTxt = AddModalText(skillBox.transform, "Desc", skillDesc, 16, new Color(0.88f, 0.93f, 1f, 0.95f), FontStyle.Normal, TextAnchor.UpperLeft, font);
        sbDescTxt.lineSpacing = 1.25f;
        SetModalRect(sbDescTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0f, 0f), new Vector2(-28f, -38f), new Vector2(14f, 6f));

        // 2. Khối Kỹ Năng Các Trang Bị Đang Mang (1.5x: 18pt)
        var eqHeaderTxt = AddModalText(rightCol.transform, "EqHeader", "🛡️ KỸ NĂNG & HIỆU ỨNG TRANG BỊ ĐANG MANG:", 18, new Color(0.55f, 0.88f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, font);
        SetModalRect(eqHeaderTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(0f, 26f), new Vector2(4f, -130f));

        // Danh sách 5 slot trang bị
        var eqList = new[]
        {
            (EquipmentType.Weapon, "Vũ Khí", "UI/icon_weapon"),
            (EquipmentType.Armor, "Giáp Phòng Thủ", "UI/icon_armor"),
            (EquipmentType.OffensiveMount, "Ngựa Tấn Công (-1)", "UI/icon_mount_offense"),
            (EquipmentType.DefensiveMount, "Ngựa Phòng Thủ (+1)", "UI/icon_mount_defense"),
            (EquipmentType.Treasure, "Bảo Vật", "UI/icon_treasure")
        };

        float eqStartY = -162f;
        float eqRowHeight = 62f;

        for (int i = 0; i < eqList.Length; i++)
        {
            var eqItem = eqList[i];
            float rowY = eqStartY - i * (eqRowHeight + 6f);

            var rowGo = new GameObject("EqRow_" + i, typeof(RectTransform), typeof(Image));
            rowGo.transform.SetParent(rightCol.transform, false);
            var rImg = rowGo.GetComponent<Image>();
            if (slotSpr != null) { rImg.sprite = slotSpr; rImg.type = Image.Type.Sliced; }
            rImg.color = new Color(0.06f, 0.09f, 0.16f, 0.9f);

            var rRt = rowGo.GetComponent<RectTransform>();
            rRt.anchorMin = new Vector2(0f, 1f);
            rRt.anchorMax = new Vector2(1f, 1f);
            rRt.pivot = new Vector2(0.5f, 1f);
            rRt.sizeDelta = new Vector2(0f, eqRowHeight);
            rRt.anchoredPosition = new Vector2(0f, rowY);

            // Icon Slot
            var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Image));
            iconGo.transform.SetParent(rowGo.transform, false);
            var icImg = iconGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources(eqItem.Item3);
            if (spr != null) icImg.sprite = spr;
            icImg.preserveAspect = true;
            var icRt = iconGo.GetComponent<RectTransform>();
            icRt.anchorMin = icRt.anchorMax = icRt.pivot = new Vector2(0f, 0.5f);
            icRt.sizeDelta = new Vector2(44f, 44f);
            icRt.anchoredPosition = new Vector2(8f, 0f);

            // Kiểm tra xem slot có card không
            CardModel card = GetEquippedCard(eqItem.Item1);
            string eqNameStr = "";
            string eqSkillDesc = "";

            if (card != null)
            {
                string suitSymbol = card.GetSuitSymbol();
                string rankStr = card.GetRankString();
                string colorHex = card.IsRed ? "#FF4D4D" : "#E2E8F0";
                eqNameStr = $"<color={colorHex}>{suitSymbol}{rankStr}</color> <color=#FFD700>{card.cardName}</color>";
                eqSkillDesc = GetEquipmentSkillDescription(card);
            }
            else
            {
                // Fallback check slot map
                if (slotMap.TryGetValue(eqItem.Item1, out var slot) && slot != null && slot.IsEquipped)
                {
                    eqNameStr = $"<color=#FFD700>{slot.CurrentItemName}</color>";
                    eqSkillDesc = "Trang bị đang kích hoạt hiệu ứng chiến đấu.";
                }
                else
                {
                    eqNameStr = $"<color=#8899AA>{eqItem.Item2}</color>";
                    eqSkillDesc = "<i>(Hiện chưa có trang bị trong slot này)</i>";
                    icImg.color = new Color(1f, 1f, 1f, 0.4f);
                }
            }

            // 1.5x: 16pt
            var nTxt = AddModalText(rowGo.transform, "Name", eqNameStr, 16, Color.white, FontStyle.Bold, TextAnchor.MiddleLeft, font);
            SetModalRect(nTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-70f, 26f), new Vector2(60f, -4f));

            // 1.5x: 15pt
            var dTxt = AddModalText(rowGo.transform, "Desc", eqSkillDesc, 15, new Color(0.85f, 0.92f, 1f, 0.9f), FontStyle.Normal, TextAnchor.MiddleLeft, font);
            SetModalRect(dTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0f, 0f), new Vector2(-70f, -28f), new Vector2(60f, 4f));
        }
    }

    private string GetEquipmentSkillDescription(CardModel card)
    {
        if (card == null) return "";
        if (!string.IsNullOrEmpty(card.description)) return card.description;

        string name = card.cardName;
        if (name.Contains("Song Cung") || name.Contains("Mường Nhạ"))
            return "Vũ Khí (Tầm 2) — Khi Trảm bị Đỡ, có thể bỏ thêm 2 lá bài ép mục tiêu mất 1 máu.";
        if (name.Contains("Kiếm Thuận Thiên"))
            return "Vũ Khí (Tầm 2) — Linh kiếm tích tụ vượng khí Đại Việt, công thủ toàn diện.";
        if (name.Contains("Giáp Đồng") || name.Contains("Sơn Vi"))
            return "Giáp Phòng Thủ — Vô hiệu hóa hoàn toàn mọi đòn Trảm Thường không có thuộc tính.";
        if (name.Contains("Khiên Mây") || name.Contains("Khiên"))
            return "Giáp Phòng Thủ — Khi bị nhắm bởi Mưa Tên hoặc Bãi Cọc, lật phán xét Đỏ để né hoàn toàn.";
        if (name.Contains("Xích Thố"))
            return "Ngựa Tấn Công — Giảm cự ly đến mọi người chơi khác đi 1 khoảng cách.";
        if (name.Contains("Phi Lực"))
            return "Ngựa Phòng Thủ — Tăng cự ly người khác nhắm vào bản thân thêm 1 khoảng cách.";

        return $"Kích hoạt kỹ năng trang bị đặc biệt của {card.cardName}.";
    }

    private static Text AddModalText(Transform parent, string name, string text, int fontSize, Color color, FontStyle style, TextAnchor align, Font font)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(parent, false);
        var t = go.GetComponent<Text>();
        t.font = font;
        t.fontSize = fontSize;
        t.color = color;
        t.fontStyle = style;
        t.alignment = align;
        t.text = text;
        t.supportRichText = true;
        t.raycastTarget = false;
        return t;
    }

    private static void SetModalRect(RectTransform rt, Vector2 min, Vector2 max, Vector2 pivot, Vector2 size, Vector2 pos)
    {
        rt.anchorMin = min;
        rt.anchorMax = max;
        rt.pivot = pivot;
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;
    }
    #endregion
}
