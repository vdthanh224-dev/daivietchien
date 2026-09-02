using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Hệ Thống Giao Diện Hợp Nhất Toàn Game (Unified Theme UI System - Đại Việt Chiến)
/// - Chủ đạo: VÀNG HOÀNG KIM (#FFD700) & TRẮNG BẠCH KIM (#FFFFFF)
/// - Cỡ chữ to, rõ ràng, dễ đọc, không bị nhỏ (Typography Hierarchy chuẩn hóa)
/// - Tự động đổ bóng / viền tương phản cao giúp mọi chữ đều sắc nét trên mọi hình nền
/// - Factory tạo Nút, Bảng, Modal, Huy Hiệu, Thanh Thông Tin đồng bộ phong cách Vàng - Trắng Đế Vương
/// </summary>
public static class ThemeUI
{
    #region 1. CHUẨN CỠ CHỮ & FONT (DỄ ĐỌC, RÕ RÀNG, KHÔNG BỊ NHỎ)
    public const int SizeTitleHuge = 28;      // Tiêu đề lớn màn hình, Đại Thắng / Thất Bại (28pt)
    public const int SizeTitleLarge = 24;     // Tiêu đề Modal, Header khu vực chính (24pt)
    public const int SizeTitleMedium = 20;    // Tiêu đề danh mục, Tên tướng, Subtitle (20pt)
    public const int SizeBodyLarge = 18;      // Nút bấm hành động, Nhãn chính, Tên bài (18pt)
    public const int SizeBody = 16;           // Mô tả tác dụng lá bài, Nội dung văn bản (16pt)
    public const int SizeButton = 18;         // Chữ trên nút bấm hành động (18pt)
    public const int SizeBadge = 16;          // Số đếm ngược ⏳40, Huy hiệu ghế, Thống kê (16pt)
    public const int SizeMicro = 14;          // Cỡ chữ tối thiểu sàn toàn game (14pt)

    private static Font cachedFont;
    public static Font FontMain
    {
        get
        {
            if (cachedFont == null)
            {
                cachedFont = Resources.Load<Font>("Fonts/GameFont");
                if (cachedFont == null) cachedFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                if (cachedFont == null) cachedFont = Resources.GetBuiltinResource<Font>("Arial.ttf");
            }
            return cachedFont;
        }
    }
    #endregion

    #region 2. BẢNG MÀU CHỦ ĐẠO VÀNG - TRẮNG HOÀNG GIA (IMPERIAL GOLD & WHITE)
    // Vàng Hoàng Kim (Imperial Gold)
    public static readonly Color GoldPrimary   = new Color(1.00f, 0.84f, 0.20f, 1.0f); // #FFD700
    public static readonly Color GoldHighlight = new Color(1.00f, 0.95f, 0.60f, 1.0f); // #FFF299
    public static readonly Color GoldDeep      = new Color(0.85f, 0.65f, 0.15f, 1.0f); // #D9A626
    public static readonly Color GoldLight     = new Color(1.00f, 0.96f, 0.80f, 1.0f); // #FFF5CC

    // Trắng Bạch Kim & Sứ Hoàng Cung (Platinum & Ivory White)
    public static readonly Color WhitePure     = new Color(1.00f, 1.00f, 1.00f, 1.0f); // #FFFFFF
    public static readonly Color WhiteIvory    = new Color(0.98f, 0.97f, 0.94f, 1.0f); // #FAF7F0
    public static readonly Color WhiteCardBg   = new Color(0.96f, 0.95f, 0.92f, 0.98f);
    public static readonly Color WhiteTranslucent = new Color(1.00f, 1.00f, 1.00f, 0.92f);

    // Lam Long & Đồng Minh (Azure Dragon & Ally)
    public static readonly Color CyanPrimary   = new Color(0.33f, 0.78f, 1.00f, 1.0f); // #55C7FF
    public static readonly Color AllyBlue      = new Color(0.23f, 0.51f, 0.96f, 1.0f); // #3B82F6
    public static readonly Color AllyBorder    = new Color(1.00f, 0.84f, 0.20f, 0.95f); // Viền vàng hoàng gia

    // Huyết Đỏ & Đối Thủ (Blood Crimson & Enemy)
    public static readonly Color CrimsonRed    = new Color(0.90f, 0.22f, 0.27f, 1.0f); // #E63946
    public static readonly Color EnemyRed      = new Color(0.94f, 0.27f, 0.27f, 1.0f); // #EF4444
    public static readonly Color EnemyBorder   = new Color(1.00f, 0.84f, 0.20f, 0.95f); // Viền vàng hoàng gia

    // Ngọc Bích & Cứu Trợ (Lotus Jade & Relief)
    public static readonly Color JadeGreen     = new Color(0.18f, 0.72f, 0.42f, 1.0f); // #2EB86B
    public static readonly Color JadeBright    = new Color(0.35f, 1.00f, 0.45f, 1.0f); // #59FF73

    // Màu Chữ & Tương Phản (Typography Contrast)
    public static readonly Color TextWhite     = new Color(1.00f, 1.00f, 1.00f, 1.0f); // #FFFFFF
    public static readonly Color TextGold      = new Color(1.00f, 0.88f, 0.35f, 1.0f); // #FFE059
    public static readonly Color TextMuted     = new Color(0.92f, 0.90f, 0.82f, 0.95f); // #EBE6D1
    public static readonly Color TextDark      = new Color(0.12f, 0.10f, 0.08f, 1.0f); // #1F1A14

    // Nền Bảng & Panel (Imperial Lacquer & Gold Trims)
    public static readonly Color BgDeepNavy    = new Color(0.06f, 0.05f, 0.04f, 0.98f); // Nền sơn mài ấm
    public static readonly Color BgCardDark    = new Color(0.09f, 0.07f, 0.05f, 0.98f); // #17120D
    public static readonly Color BgModalDark   = new Color(0.06f, 0.05f, 0.04f, 0.96f);
    public static readonly Color BgOverlay     = new Color(0.03f, 0.02f, 0.02f, 0.90f);
    #endregion

    #region 3. FACTORY TẠO TEXT CHUẨN CÓ BÓNG / VIỀN (HIGH READABILITY)
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
        txt.horizontalOverflow = HorizontalWrapMode.Overflow;
        txt.verticalOverflow = VerticalWrapMode.Overflow;

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
        s.effectColor = shadowColor ?? new Color(0f, 0f, 0f, 0.90f);
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
        White,     // Trắng Sứ Viền Vàng (Thứ cấp, Thanh lịch)
        Jade,      // Xanh Lục (Cứu viện, Xác nhận an toàn)
        Crimson,   // Đỏ Huyết (Tấn công, Bỏ bài, Từ chối)
        Dark,      // Nâu Tối Hoàng Gia (Menu phụ)
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
            ButtonTheme.Gold => new Color(1.00f, 0.80f, 0.20f, 1.0f),
            ButtonTheme.White => new Color(0.96f, 0.96f, 0.96f, 1.0f),
            ButtonTheme.Jade => new Color(0.20f, 0.78f, 0.38f, 1.0f),
            ButtonTheme.Crimson => new Color(0.88f, 0.25f, 0.22f, 1.0f),
            ButtonTheme.Dark => new Color(0.24f, 0.20f, 0.16f, 1.0f),
            ButtonTheme.Disabled => new Color(0.45f, 0.45f, 0.48f, 0.85f),
            _ => GoldPrimary
        };

        var rt = btnGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;

        // Viền vàng sắc sảo 2 lớp
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(btnGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LoadSprite("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = GoldPrimary;
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1.5f, -1.5f), new Vector2(1.5f, 1.5f));

        Color labelColor = theme == ButtonTheme.White ? TextDark : TextWhite;
        var txt = CreateText(btnGo.transform, "Label", label, fontSize, labelColor, FontStyle.Bold, TextAnchor.MiddleCenter, true);
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
        var bgSprite = LoadSprite("UI/auth_card_bg");
        if (bgSprite != null) { pImg.sprite = bgSprite; pImg.type = Image.Type.Sliced; }
        pImg.color = BgCardDark;

        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = size;
        pRt.anchoredPosition = Vector2.zero;
        contentRt = pRt;

        // Khung Viền Vàng Hoàng Kim 2 Lớp Sắc Nét
        var borderGo = new GameObject("OuterBorder", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(panelGo.transform, false);
        borderGo.transform.SetAsFirstSibling();
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LoadSprite("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = GoldPrimary;
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-3, -3), new Vector2(3, 3));

        // Thanh Tiêu Đề (Header Banner)
        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var bSpr = LoadSprite("UI/badge_faction");
        if (bSpr != null) { hImg.sprite = bSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = headerColor ?? new Color(0.18f, 0.14f, 0.08f, 0.98f);

        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 24f, 52f), new Vector2(0, -10f));

        var titleTxt = CreateText(headerGo.transform, "TitleText", title, SizeTitleLarge, GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(titleTxt.rectTransform);

        return overlayGo;
    }

    public static Button CreateCloseButton(Transform parent, Action onClose)
    {
        var btnGo = new GameObject("CloseButton", typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(parent, false);
        btnGo.transform.SetAsLastSibling();

        var img = btnGo.GetComponent<Image>();
        var slotSpr = LoadSprite("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.75f, 0.20f, 0.20f, 0.98f);

        var rt = btnGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(1f, 1f);
        rt.sizeDelta = new Vector2(40f, 40f);
        rt.anchoredPosition = new Vector2(-12f, -12f);

        var border = new GameObject("Border", typeof(RectTransform), typeof(Image));
        border.transform.SetParent(btnGo.transform, false);
        var bImg = border.GetComponent<Image>();
        var fSpr = LoadSprite("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = GoldPrimary;
        bImg.raycastTarget = false;
        Fill(border.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var txt = CreateText(btnGo.transform, "Txt", "✕", SizeTitleMedium, WhitePure, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(txt.rectTransform);

        var btn = btnGo.GetComponent<Button>();
        if (onClose != null) btn.onClick.AddListener(() => onClose.Invoke());
        return btn;
    }
    #endregion

    #region 6. ĐỊNH DẠNG THẺ BÀI CHUẨN VIỆT HÓA (DỄ ĐỌC)
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
            CardSuit.Spade => "<color=#FFFFFF>♠</color>",
            CardSuit.Heart => "<color=#FF5555>♥</color>",
            CardSuit.Club => "<color=#FFFFFF>♣</color>",
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
