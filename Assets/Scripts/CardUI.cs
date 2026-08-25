using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

/// <summary>
/// Giao diện lá bài có thể tái sử dụng (Reusable Interactive Card UI).
/// - Tên lá bài lớn gấp rưỡi (Font size 18) nổi bật trên thanh tiêu đề.
/// - Số và chất nhích xuống dưới tên, lớn gấp rưỡi (Font size 19-20).
/// - Khung tranh biểu tượng sắc nét.
/// - Hiệu ứng rê chuột nhô lên (Hover Elevation) & Click chọn/đánh bài.
/// </summary>
[RequireComponent(typeof(RectTransform))]
public class CardUI : MonoBehaviour, IPointerClickHandler
{
    [Header("Card Data")]
    [SerializeField] private CardModel cardData;

    [Header("UI Components")]
    [SerializeField] private Image cardBackground;
    [SerializeField] private Text cardNameText;
    [SerializeField] private Text suitRankText;
    [SerializeField] private Text categoryText;
    [SerializeField] private Image artworkIcon;
    [SerializeField] private GameObject highlightGlow;

    private RectTransform rectTransform;
    private Vector2 baseAnchoredPosition;
    private Vector3 baseScale = Vector3.one;
    private bool isSelected = false;

    public CardModel Data => cardData;
    public bool IsSelected => isSelected;

    public event Action<CardUI> OnCardClicked;

    private void Awake()
    {
        rectTransform = GetComponent<RectTransform>();
    }

    /// <summary>
    /// Gán dữ liệu cho lá bài và cập nhật hiển thị.
    /// </summary>
    public void Setup(CardModel data)
    {
        cardData = data;
        EnsureUIComponents();
        RefreshVisuals();
    }

    public void RefreshVisuals()
    {
        if (cardData == null) return;

        // 1. Tên lá bài (Chữ lớn gấp rưỡi)
        if (cardNameText != null)
        {
            cardNameText.text = cardData.cardName;
        }

        // 2. Số và Chất (Chữ lớn gấp rưỡi, nhích xuống phía dưới tên)
        if (suitRankText != null)
        {
            suitRankText.text = $"{cardData.GetSuitSymbol()} {cardData.GetRankString()}";
            suitRankText.color = cardData.GetSuitColor();
        }

        // 3. Phân loại (Cơ bản / Vũ khí / Cẩm nang...)
        if (categoryText != null)
        {
            categoryText.text = cardData.GetCategoryName();
        }

        // 4. Icon minh họa
        if (artworkIcon != null)
        {
            if (!string.IsNullOrEmpty(cardData.iconPath))
            {
                var spr = LotusHealthUI.LoadSpriteFromResources(cardData.iconPath);
                if (spr != null)
                {
                    artworkIcon.sprite = spr;
                    artworkIcon.color = Color.white;
                    artworkIcon.gameObject.SetActive(true);
                }
                else
                {
                    artworkIcon.gameObject.SetActive(false);
                }
            }
            else
            {
                artworkIcon.gameObject.SetActive(false);
            }
        }
    }

    private CanvasGroup canvasGroup;

    private bool isTutorialHighlighted = false;

    public void SetDimmed(bool dimmed)
    {
        if (canvasGroup == null) canvasGroup = gameObject.GetComponent<CanvasGroup>();
        if (canvasGroup == null) canvasGroup = gameObject.AddComponent<CanvasGroup>();

        canvasGroup.alpha = dimmed ? 0.35f : 1f;
        canvasGroup.interactable = !dimmed;
        canvasGroup.blocksRaycasts = !dimmed;
    }

    public void SetGlow(bool active)
    {
        if (highlightGlow != null)
        {
            highlightGlow.SetActive(active);
        }
    }

    public void SetTutorialHighlight(bool highlight)
    {
        isTutorialHighlighted = highlight;

        var canvas = GetComponent<Canvas>();
        var raycaster = GetComponent<GraphicRaycaster>();
        if (highlight)
        {
            if (canvas == null) canvas = gameObject.AddComponent<Canvas>();
            canvas.overrideSorting = true;
            canvas.sortingOrder = 65;
            if (raycaster == null) raycaster = gameObject.AddComponent<GraphicRaycaster>();

            SetGlow(true);
            SetDimmed(false);
        }
        else
        {
            if (raycaster != null) Destroy(raycaster);
            if (canvas != null) Destroy(canvas);

            SetGlow(isSelected);
        }
        UpdatePosition();
    }

    public void SetSelected(bool selected)
    {
        isSelected = selected;
        if (highlightGlow != null)
        {
            highlightGlow.SetActive(isSelected || isTutorialHighlighted);
        }
        if (isSelected)
        {
            transform.SetAsLastSibling();
        }
        UpdatePosition();
    }

    public void SetBasePosition(Vector2 pos)
    {
        baseAnchoredPosition = pos;
        UpdatePosition();
    }

    private void UpdatePosition()
    {
        if (rectTransform == null) return;
        float yOffset = (isSelected || isTutorialHighlighted) ? 22f : 0f;

        rectTransform.anchoredPosition = baseAnchoredPosition + new Vector2(0, yOffset);
        rectTransform.localScale = (isSelected || isTutorialHighlighted) ? baseScale * 1.08f : baseScale;
    }

    public void OnPointerClick(PointerEventData eventData)
    {
        // Chạm / Click để chọn hoặc bỏ chọn bài (chuẩn mobile)
        OnCardClicked?.Invoke(this);
    }

    #region Procedural Factory
    public static CardUI Create(Transform parent, CardModel card, Vector2 size)
    {
        var go = new GameObject("Card_" + (card != null ? card.cardName : "Empty"), typeof(RectTransform), typeof(CardUI));
        go.transform.SetParent(parent, false);

        var cardUI = go.GetComponent<CardUI>();
        cardUI.BuildHierarchy(size);
        if (card != null)
        {
            cardUI.Setup(card);
        }
        return cardUI;
    }

    private void EnsureUIComponents()
    {
        if (rectTransform == null) rectTransform = GetComponent<RectTransform>();
    }

    private void BuildHierarchy(Vector2 size)
    {
        rectTransform = GetComponent<RectTransform>();
        rectTransform.sizeDelta = size;
        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        // Đảm bảo Root GameObject có Image để bắt click qua IPointerClickHandler
        var rootImg = GetComponent<Image>();
        if (rootImg == null) rootImg = gameObject.AddComponent<Image>();
        rootImg.color = new Color(1f, 1f, 1f, 0.001f);
        rootImg.raycastTarget = true;

        var btn = GetComponent<Button>();
        if (btn != null) Destroy(btn);

        // 1. Khung nền thẻ bài (9-slice parchment)
        var bgGo = new GameObject("CardBackground", typeof(RectTransform), typeof(Image));
        bgGo.transform.SetParent(transform, false);
        cardBackground = bgGo.GetComponent<Image>();
        cardBackground.raycastTarget = false;
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/card_front_bg");
        if (bgSprite != null)
        {
            cardBackground.sprite = bgSprite;
            cardBackground.type = Image.Type.Sliced;
        }
        else
        {
            cardBackground.color = new Color(0.96f, 0.94f, 0.88f, 1f);
        }
        var bgRt = bgGo.GetComponent<RectTransform>();
        Fill(bgRt);

        // 2. Viền phát sáng khi chọn (Highlight Glow)
        var glowGo = new GameObject("HighlightGlow", typeof(RectTransform), typeof(Image));
        glowGo.transform.SetParent(transform, false);
        glowGo.transform.SetAsFirstSibling();
        var glowImg = glowGo.GetComponent<Image>();
        var glowSprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        if (glowSprite != null) glowImg.sprite = glowSprite;
        glowImg.color = new Color(1f, 0.85f, 0.25f, 0.95f);
        glowImg.raycastTarget = false;
        var glowRt = glowGo.GetComponent<RectTransform>();
        Fill(glowRt, new Vector2(-12, -12), new Vector2(12, 12));
        glowGo.SetActive(false);
        highlightGlow = glowGo;

        // 3. TÊN LÁ BÀI (NameBanner chuẩn tỷ lệ, BestFit chống tràn)
        var nameBannerGo = new GameObject("NameBanner", typeof(RectTransform), typeof(Image));
        nameBannerGo.transform.SetParent(transform, false);
        var nbImg = nameBannerGo.GetComponent<Image>();
        nbImg.color = new Color(0.1f, 0.14f, 0.22f, 0.95f);
        nbImg.raycastTarget = false;
        var nbRt = nameBannerGo.GetComponent<RectTransform>();
        nbRt.anchorMin = new Vector2(0.04f, 0.81f);
        nbRt.anchorMax = new Vector2(0.96f, 0.96f);
        nbRt.pivot = new Vector2(0.5f, 0.5f);
        nbRt.offsetMin = nbRt.offsetMax = Vector2.zero;

        var nameGo = new GameObject("CardNameText", typeof(RectTransform), typeof(Text));
        nameGo.transform.SetParent(nameBannerGo.transform, false);
        cardNameText = nameGo.GetComponent<Text>();
        cardNameText.font = font;
        cardNameText.fontSize = 16;
        cardNameText.fontStyle = FontStyle.Bold;
        cardNameText.alignment = TextAnchor.MiddleCenter;
        cardNameText.color = new Color(1f, 0.92f, 0.55f, 1f);
        cardNameText.resizeTextForBestFit = true;
        cardNameText.resizeTextMinSize = 9;
        cardNameText.resizeTextMaxSize = 16;
        cardNameText.raycastTarget = false;
        var nameShadow = nameGo.AddComponent<Shadow>();
        nameShadow.effectColor = new Color(0, 0, 0, 0.9f);
        nameShadow.effectDistance = new Vector2(1, -1);
        Fill(nameGo.GetComponent<RectTransform>(), new Vector2(4, 2), new Vector2(-4, -2));

        // 4. SỐ VÀ CHẤT & PHÂN LOẠI (SubHeader chuẩn tỷ lệ)
        var subHeaderGo = new GameObject("SubHeader", typeof(RectTransform));
        subHeaderGo.transform.SetParent(transform, false);
        var shRt = subHeaderGo.GetComponent<RectTransform>();
        shRt.anchorMin = new Vector2(0.06f, 0.67f);
        shRt.anchorMax = new Vector2(0.94f, 0.79f);
        shRt.pivot = new Vector2(0.5f, 0.5f);
        shRt.offsetMin = shRt.offsetMax = Vector2.zero;

        // Số & Chất (bên trái SubHeader)
        var suitRankGo = new GameObject("SuitRankText", typeof(RectTransform), typeof(Text));
        suitRankGo.transform.SetParent(subHeaderGo.transform, false);
        suitRankText = suitRankGo.GetComponent<Text>();
        suitRankText.font = font;
        suitRankText.fontSize = 24;
        suitRankText.fontStyle = FontStyle.Bold;
        suitRankText.alignment = TextAnchor.MiddleLeft;
        suitRankText.resizeTextForBestFit = true;
        suitRankText.resizeTextMinSize = 12;
        suitRankText.resizeTextMaxSize = 24;
        suitRankText.raycastTarget = false;
        var srRt = suitRankGo.GetComponent<RectTransform>();
        srRt.anchorMin = new Vector2(0f, 0f);
        srRt.anchorMax = new Vector2(0.48f, 1f);
        srRt.pivot = new Vector2(0f, 0.5f);
        srRt.offsetMin = srRt.offsetMax = Vector2.zero;
        var srShadow = suitRankGo.AddComponent<Shadow>();
        srShadow.effectColor = new Color(1, 1, 1, 0.4f);
        srShadow.effectDistance = new Vector2(0.5f, -0.5f);

        // Phân loại (bên phải SubHeader)
        var catGo = new GameObject("CategoryText", typeof(RectTransform), typeof(Text));
        catGo.transform.SetParent(subHeaderGo.transform, false);
        categoryText = catGo.GetComponent<Text>();
        categoryText.font = font;
        categoryText.fontSize = 11;
        categoryText.fontStyle = FontStyle.Bold;
        categoryText.alignment = TextAnchor.MiddleRight;
        categoryText.color = new Color(0.42f, 0.32f, 0.18f, 1f);
        categoryText.resizeTextForBestFit = true;
        categoryText.resizeTextMinSize = 8;
        categoryText.resizeTextMaxSize = 11;
        categoryText.raycastTarget = false;
        var catRt = catGo.GetComponent<RectTransform>();
        catRt.anchorMin = new Vector2(0.48f, 0f);
        catRt.anchorMax = new Vector2(1f, 1f);
        catRt.pivot = new Vector2(1f, 0.5f);
        catRt.offsetMin = catRt.offsetMax = Vector2.zero;

        // 5. Artwork / Icon chính giữa lá bài (Chuẩn tỷ lệ khung 60% thân thẻ, PreserveAspect tự động vừa khít 100%)
        var artGo = new GameObject("ArtworkIcon", typeof(RectTransform), typeof(Image));
        artGo.transform.SetParent(transform, false);
        artworkIcon = artGo.GetComponent<Image>();
        artworkIcon.preserveAspect = true;
        artworkIcon.raycastTarget = false;
        artworkIcon.color = Color.white;
        var artRt = artGo.GetComponent<RectTransform>();
        artRt.anchorMin = new Vector2(0.08f, 0.05f);
        artRt.anchorMax = new Vector2(0.92f, 0.65f);
        artRt.pivot = new Vector2(0.5f, 0.5f);
        artRt.offsetMin = artRt.offsetMax = Vector2.zero;
    }

    private static void Fill(RectTransform rect, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(0.5f, 0.5f); rect.offsetMin = offsetMin; rect.offsetMax = offsetMax;
    }
    #endregion
}
