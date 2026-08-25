using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Hệ Thống Giao Diện Hợp Nhất Toàn Game (Unified Theme UI System - Đại Việt Chiến)
/// - Cỡ chữ to, rõ ràng, dễ đọc, không bị nhỏ (Typography Hierarchy chuẩn hóa)
/// - Phong cách Hoàng Gia Đại Việt: Vàng Hoàng Kim (#FFD700), Nền Sơn Mài Lam Đậm (#070B14), Sen Hồng & Xanh Ngọc
/// - Tự động đổ bóng / viền tương phản cao giúp mọi chữ đều sắc nét trên mọi hình nền
/// - Factory tạo Nút, Bảng, Modal, Huy Hiệu, Thanh Thông Tin đồng bộ xuyên suốt toàn bộ dự án
/// </summary>
public static class ThemeUI
{
    #region 1. CHUẨN CỠ CHỮ & FONT (DỄ ĐỌC, RÕ RÀNG)
    public const int SizeTitleHuge = 22;      // Tiêu đề màn hình, Đại Thắng / Thất Bại
    public const int SizeTitleLarge = 20;     // Tiêu đề Modal, Header khu vực
    public const int SizeTitleMedium = 18;    // Dòng chú thích lá bài, Trạng thái lượt (18pt)
    public const int SizeBodyLarge = 18;      // Nút bấm hành động & phản ứng (18pt)
    public const int SizeBody = 16;           // Tên lá bài (16pt)
    public const int SizeButton = 18;         // Chữ trên nút bấm hành động (18pt)
    public const int SizeBadge = 17;          // Số đếm ngược ⏳40 & Huy hiệu ghế (17pt)
    public const int SizeMicro = 11;          // Cỡ chữ tối thiểu sàn (11pt)

    private static Font cachedFont;
    public static Font FontMain
    {
        get
        {
            if (cachedFont == null)
            {
                cachedFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                if (cachedFont == null) cachedFont = Resources.Load<Font>("Fonts/LegacyRuntime");
            }
            return cachedFont;
        }
    }
    #endregion

    #region 2. BẢNG MÀU HOÀNG GIA ĐẠI VIỆT
    // Vàng Hoàng Kim
    public static readonly Color GoldPrimary   = new Color(1.00f, 0.84f, 0.00f, 1.0f); // #FFD700
    public static readonly Color GoldHighlight = new Color(1.00f, 0.94f, 0.45f, 1.0f); // #FFF073
    public static readonly Color GoldDeep      = new Color(0.78f, 0.55f, 0.12f, 1.0f); // #C68C1E

    // Lam Ngọc & Đồng Minh
    public static readonly Color CyanPrimary   = new Color(0.33f, 0.87f, 1.00f, 1.0f); // #55DDFF
    public static readonly Color AllyBlue      = new Color(0.22f, 0.74f, 0.97f, 1.0f); // #38BDF8
    public static readonly Color AllyBorder    = new Color(0.25f, 0.75f, 1.00f, 0.95f);

    // Huyết Đỏ & Đối Thủ
    public static readonly Color CrimsonRed    = new Color(0.95f, 0.28f, 0.28f, 1.0f); // #F24747
    public static readonly Color EnemyRed      = new Color(0.97f, 0.44f, 0.44f, 1.0f); // #F87171
    public static readonly Color EnemyBorder   = new Color(1.00f, 0.38f, 0.38f, 0.95f);

    // Lục Bảo & Cứu Trợ
    public static readonly Color JadeGreen     = new Color(0.15f, 0.78f, 0.40f, 1.0f); // #26C766

    // Màu Chữ & Tương Phản
    public static readonly Color TextWhite     = new Color(0.98f, 0.99f, 1.00f, 1.0f);
    public static readonly Color TextMuted     = new Color(0.80f, 0.85f, 0.92f, 0.9f);
    public static readonly Color TextDark      = new Color(0.08f, 0.06f, 0.04f, 1.0f);

    // Nền Bảng & Panel
    public static readonly Color BgDeepNavy    = new Color(0.04f, 0.07f, 0.14f, 0.98f);
    public static readonly Color BgCardDark    = new Color(0.06f, 0.09f, 0.18f, 0.98f);
    public static readonly Color BgModalDark   = new Color(0.03f, 0.05f, 0.09f, 0.92f);
    public static readonly Color BgOverlay     = new Color(0.02f, 0.03f, 0.07f, 0.88f);
    #endregion

    #region 3. FACTORY TẠO TEXT CHUẨN CÓ BÓNG / VIỀN (HIGH READABILITY)
    /// <summary>
    /// Tạo đối tượng Text có cỡ chữ to, rõ ràng và tự động gắn Shadow/Outline để luôn đọc tốt.
    /// </summary>
    public static Text CreateText(
        Transform parent,
        string name,
        string content,
        int fontSize = SizeBody,
        Color? color = null,
        FontStyle style = FontStyle.Normal,
        TextAnchor align = TextAnchor.MiddleLeft,
        bool withShadow = true)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(parent, false);

        var txt = go.GetComponent<Text>();
        txt.font = FontMain;
        txt.fontSize = Mathf.Max(SizeMicro, fontSize);
        txt.text = content;
        txt.color = color ?? TextWhite;
        txt.fontStyle = style;
        txt.alignment = align;
        txt.raycastTarget = false;

        if (withShadow)
        {
            AddTextShadow(txt);
        }

        return txt;
    }

    public static void AddTextShadow(Text text, Color? shadowColor = null, Vector2? distance = null)
    {
        if (text == null) return;
        var s = text.GetComponent<Shadow>();
        if (s == null) s = text.gameObject.AddComponent<Shadow>();
        s.effectColor = shadowColor ?? new Color(0f, 0f, 0f, 0.85f);
        s.effectDistance = distance ?? new Vector2(1.5f, -1.5f);
        s.useGraphicAlpha = true;
    }

    public static void AddTextOutline(Text text, Color? outlineColor = null, Vector2? distance = null)
    {
        if (text == null) return;
        var o = text.GetComponent<Outline>();
        if (o == null) o = text.gameObject.AddComponent<Outline>();
        o.effectColor = outlineColor ?? new Color(0f, 0f, 0f, 0.95f);
        o.effectDistance = distance ?? new Vector2(1.2f, -1.2f);
        o.useGraphicAlpha = true;
    }
    #endregion

    #region 4. FACTORY TẠO NÚT BẤM (BUTTONS) ĐỒNG BỘ
    public enum ButtonTheme
    {
        Gold,      // Vàng Hoàng Kim (Chính)
        Jade,      // Xanh Lục (Cứu viện, Xác nhận an toàn)
        Crimson,   // Đỏ Huyết (Tấn công, Bỏ bài, Từ chối)
        Dark,      // Lam Tối (Thứ cấp, Menu phụ)
        Disabled   // Xám (Vô hiệu hóa)
    }

    public static Button CreateButton(
        Transform parent,
        string name,
        string label,
        Vector2 size,
        Vector2 pos,
        Action onClick,
        ButtonTheme theme = ButtonTheme.Gold,
        int fontSize = SizeButton)
    {
        var btnGo = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(parent, false);

        var img = btnGo.GetComponent<Image>();
        var spr = LoadSprite("UI/btn_gold");
        if (spr != null) { img.sprite = spr; img.type = Image.Type.Sliced; }

        img.color = theme switch
        {
            ButtonTheme.Gold => new Color(0.95f, 0.72f, 0.18f, 1.0f),
            ButtonTheme.Jade => new Color(0.20f, 0.78f, 0.38f, 1.0f),
            ButtonTheme.Crimson => new Color(0.88f, 0.25f, 0.22f, 1.0f),
            ButtonTheme.Dark => new Color(0.22f, 0.28f, 0.40f, 1.0f),
            ButtonTheme.Disabled => new Color(0.45f, 0.48f, 0.55f, 0.85f),
            _ => GoldPrimary
        };

        var rt = btnGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;

        var txt = CreateText(btnGo.transform, "Label", label, fontSize, TextWhite, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(txt.rectTransform);

        var btn = btnGo.GetComponent<Button>();
        if (theme == ButtonTheme.Disabled)
        {
            btn.interactable = false;
        }

        if (onClick != null)
        {
            btn.onClick.AddListener(() =>
            {
                if (AudioManager.Instance != null) AudioManager.Instance.PlayCardSelect();
                onClick.Invoke();
            });
        }

        return btn;
    }
    #endregion

    #region 5. FACTORY TẠO PANEL & MODAL HOÀNG GIA ĐỒNG BỘ
    /// <summary>
    /// Tạo một Modal chuẩn có Nền đen mờ toàn màn hình, Khung viền Vàng Hoàng Kim và Thanh Tiêu Đề sắc nét.
    /// </summary>
    public static GameObject CreateModal(
        Transform parent,
        string name,
        string title,
        Vector2 size,
        out RectTransform contentRt,
        Color? headerColor = null)
    {
        var overlayGo = new GameObject("ModalOverlay_" + name, typeof(RectTransform), typeof(Image));
        overlayGo.transform.SetParent(parent, false);
        overlayGo.transform.SetAsLastSibling();

        var ovImg = overlayGo.GetComponent<Image>();
        ovImg.color = BgOverlay;
        Fill(overlayGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(overlayGo.transform, false);

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LoadSprite("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = BgCardDark;

        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = size;
        pRt.anchoredPosition = Vector2.zero;
        contentRt = pRt;

        // Khung Viền Vàng Phát Sáng
        var borderGo = new GameObject("OuterBorder", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(panelGo.transform, false);
        borderGo.transform.SetAsFirstSibling();
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LoadSprite("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = GoldPrimary;
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // Thanh Tiêu Đề (Header Banner)
        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var bSpr = LoadSprite("UI/badge_faction");
        if (bSpr != null) { hImg.sprite = bSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = headerColor ?? new Color(0.12f, 0.35f, 0.65f, 0.98f);

        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 30f, 44f), new Vector2(0, -10f));

        var titleTxt = CreateText(headerGo.transform, "TitleText", title, SizeTitleLarge, GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(titleTxt.rectTransform);

        return overlayGo;
    }
    #endregion

    #region 6. ĐỊNH DẠNG THẺ BÀI CHUẨN VIỆT HÓA (DỄ ĐỌC)
    /// <summary>
    /// Định dạng dòng thông tin lá bài ngắn gọn, to rõ (Ví dụ: [ĐỘT KÍCH TRỘM LƯƠNG] (Cẩm Nang Tức Thời • ♥ K): ...)
    /// </summary>
    public static string FormatCardDescription(CardModel card)
    {
        if (card == null) return "";

        string catStr = card.category switch
        {
            CardCategory.Basic => "Bài Cơ Bản",
            CardCategory.Equipment => card.subType switch
            {
                CardSubType.Weapon => "Trang Bị - Vũ Khí",
                CardSubType.Armor => "Trang Bị - Áo Giáp",
                CardSubType.OffensiveHorse => "Trang Bị - Ngựa Công",
                CardSubType.DefensiveHorse => "Trang Bị - Ngựa Thủ",
                _ => "Trang Bị"
            },
            CardCategory.InstantScroll => "Cẩm Nang Tức Thời",
            CardCategory.DelayedScroll => "Cẩm Nang Trì Hoãn",
            _ => "Thẻ Bài"
        };

        string suitSymbol = card.suit switch
        {
            CardSuit.Spade => "<color=#E2E8F0>♠</color>",
            CardSuit.Heart => "<color=#FF5555>♥</color>",
            CardSuit.Club => "<color=#E2E8F0>♣</color>",
            CardSuit.Diamond => "<color=#FF5555>♦</color>",
            _ => ""
        };

        string rankStr = card.rank switch
        {
            CardRank.Ace => "A",
            CardRank.Jack => "J",
            CardRank.Queen => "Q",
            CardRank.King => "K",
            _ => ((int)card.rank).ToString()
        };

        return $"🎴 <b><size={SizeBodyLarge}><color=#FFD700>[{card.cardName.ToUpper()}]</color></size></b> <color=#55DDFF>({catStr} • {suitSymbol} {rankStr})</color>: {card.description}";
    }
    #endregion

    #region 7. HELPER UTILITIES
    private static readonly Dictionary<string, Sprite> spriteCache = new Dictionary<string, Sprite>();

    public static Sprite LoadSprite(string path)
    {
        if (string.IsNullOrEmpty(path)) return null;
        if (spriteCache.TryGetValue(path, out var s) && s != null) return s;

        var loaded = Resources.Load<Sprite>(path);
        if (loaded == null)
        {
            var tex = Resources.Load<Texture2D>(path);
            if (tex != null)
            {
                loaded = Sprite.Create(tex, new Rect(0, 0, tex.width, tex.height), new Vector2(0.5f, 0.5f));
            }
        }

        if (loaded != null) spriteCache[path] = loaded;
        return loaded;
    }

    public static void Fill(RectTransform rt, Vector2? minOffset = null, Vector2? maxOffset = null)
    {
        if (rt == null) return;
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.offsetMin = minOffset ?? Vector2.zero;
        rt.offsetMax = maxOffset ?? Vector2.zero;
    }

    public static void SetRect(RectTransform rt, Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 size, Vector2 pos)
    {
        if (rt == null) return;
        rt.anchorMin = aMin;
        rt.anchorMax = aMax;
        rt.pivot = pivot;
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;
    }
    #endregion
}
