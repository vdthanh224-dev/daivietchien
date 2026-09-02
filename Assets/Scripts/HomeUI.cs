using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// GIAO DIỆN SẢNH CHÍNH (MAIN LOBBY) ĐẠI VIỆT CHIẾN
/// - Bố cục cân đối, hiện đại, thoáng đãng
/// - 4 Thẻ Chế Độ Chơi lớn trải đều trung tâm (2v2 Xếp Hạng, Vương Triều, Quốc Chiến, Luyện Tập AI)
/// - Chữ hiển thị gọn gàng, rõ nét, không bị tràn khung
/// - Đỉnh: Header hoàng gia (Avatar, Tên, Quân Hàm, Bạc, Vàng, Hòm Thư, Cài Đặt)
/// - Đáy: Dock 5 phím điều hướng ngọc ấn hoàng gia
/// </summary>
public sealed class HomeUI : MonoBehaviour
{
    private static HomeUI instance;
    public static HomeUI Instance => instance;

    private CanvasScaler scaler;
    private GameObject homeCanvasGo;
    private RectTransform bgRt;
    private RawImage bgRaw;

    // Top Header Elements
    private Text playerNameText;
    private Text playerRankText;
    private Text playerExpText;
    private RectTransform expBarFillRt;
    private Text silverText;
    private Text goldText;

    private GameObject currentActiveModal = null;
    private Coroutine backgroundAnimCoroutine;
    private Coroutine embersCoroutine;

    public static void Open(string userEmail = "")
    {
        if (instance == null)
        {
            var go = new GameObject("HomeUI");
            DontDestroyOnLoad(go);
            instance = go.AddComponent<HomeUI>();
        }

        instance.Show(userEmail);
    }

    public static void Close()
    {
        if (instance != null)
        {
            instance.Hide();
        }
    }

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Destroy(gameObject);
            return;
        }
        instance = this;
    }

    public void Show(string userEmail = "")
    {
        if (!string.IsNullOrEmpty(userEmail))
        {
            AuthUI.CurrentUserEmail = userEmail;
        }

        if (homeCanvasGo == null)
        {
            BuildUI();
        }
        else
        {
            homeCanvasGo.SetActive(true);
            RefreshUserData();
        }

        StartDynamicEffects();
        AudioManager.Instance.PlayCardDraw();
    }

    public void Hide()
    {
        StopDynamicEffects();
        if (homeCanvasGo != null)
        {
            homeCanvasGo.SetActive(false);
        }
    }

    public void RefreshUserData()
    {
        // 1. Tên người chơi
        if (playerNameText != null)
        {
            string displayName = AuthUI.CurrentUserName;
            if (string.IsNullOrWhiteSpace(displayName) || displayName == "Đại Tướng Quân")
            {
                if (!string.IsNullOrEmpty(AuthUI.CurrentUserEmail) && AuthUI.CurrentUserEmail.Contains("@"))
                {
                    displayName = AuthUI.CurrentUserEmail.Split('@')[0];
                }
                else
                {
                    displayName = "Lý Thường Kiệt";
                }
            }
            if (displayName.Length > 24) displayName = displayName.Substring(0, 24) + "...";
            playerNameText.text = displayName;
        }

        // 2. Quân Hàm 12 Bậc từ MilitaryRankSystem
        var milTier = MilitaryRankSystem.GetTier(AuthUI.CurrentMilitaryPoints);
        if (playerRankText != null)
        {
            playerRankText.text = $"{milTier.badge} <color={milTier.ColorHex}>{milTier.name}</color>";
        }

        // 3. Thanh Tiến Độ Quân Công 12 Bậc
        var nextMilTier = MilitaryRankSystem.GetNextTier(AuthUI.CurrentMilitaryPoints);
        float milProgress = MilitaryRankSystem.GetProgress(AuthUI.CurrentMilitaryPoints);
        if (playerExpText != null)
        {
            if (milTier.tierIndex >= 12)
                playerExpText.text = $"{AuthUI.CurrentMilitaryPoints}đ (Tối Cao)";
            else
                playerExpText.text = $"{AuthUI.CurrentMilitaryPoints}/{nextMilTier.minPoints}đ";
        }
        if (expBarFillRt != null)
        {
            expBarFillRt.anchorMax = new Vector2(milProgress, 1f);
        }

        // 4. Bạc & Vàng từ Appwrite
        if (silverText != null)
        {
            silverText.text = $"{AuthUI.CurrentSilver:N0}";
        }
        if (goldText != null)
        {
            goldText.text = $"{AuthUI.CurrentGold:N0}";
        }
    }

    public void AddSilver(int amount)
    {
        AuthUI.CurrentSilver += amount;
        PlayerPrefs.SetInt("user_silver_" + (string.IsNullOrEmpty(AuthUI.CurrentUserEmail) ? "default" : AuthUI.CurrentUserEmail), AuthUI.CurrentSilver);
        PlayerPrefs.Save();
        StartCoroutine(AuthUI.SaveUserProfileToAppwrite());
        RefreshUserData();
    }

    public void AddExp(int amount)
    {
        AuthUI.CurrentExp += amount;
        int maxExp = Mathf.Max(1, AuthUI.CurrentLevel) * 1000;
        if (AuthUI.CurrentExp >= maxExp)
        {
            AuthUI.CurrentLevel++;
            AuthUI.CurrentExp -= maxExp;
        }
        StartCoroutine(AuthUI.SaveUserProfileToAppwrite());
        RefreshUserData();
    }

    private void BuildUI()
    {
        Screen.orientation = ScreenOrientation.LandscapeRight;
        Screen.autorotateToPortrait = false;
        Screen.autorotateToPortraitUpsideDown = false;
        Screen.autorotateToLandscapeLeft = true;
        Screen.autorotateToLandscapeRight = true;

        homeCanvasGo = new GameObject("HomeCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        homeCanvasGo.transform.SetParent(transform, false);
        var canvas = homeCanvasGo.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 10;

        scaler = homeCanvasGo.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1280, 720);
        scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
        scaler.matchWidthOrHeight = 0.5f;

        var font = ThemeUI.FontMain;

        // 1. Hình nền hoàng cung đại điện lộng lẫy (Home Background)
        var bgGo = new GameObject("Background", typeof(RectTransform), typeof(RawImage));
        bgGo.transform.SetParent(homeCanvasGo.transform, false);
        bgRaw = bgGo.GetComponent<RawImage>();
        bgRaw.color = Color.white;
        var bgTex = Resources.Load<Texture2D>("UI/home_background");
        if (bgTex == null) bgTex = Resources.Load<Texture2D>("UI/login_background");
        if (bgTex != null) bgRaw.texture = bgTex;
        bgRt = bgGo.GetComponent<RectTransform>();
        Fill(bgRt, new Vector2(-40, -30), new Vector2(40, 30));

        // Lớp phủ tối mờ trang nhã
        var shadeGo = new GameObject("Shade", typeof(RectTransform), typeof(Image));
        shadeGo.transform.SetParent(homeCanvasGo.transform, false);
        var shadeImg = shadeGo.GetComponent<Image>();
        shadeImg.color = new Color(0.02f, 0.04f, 0.08f, 0.50f);
        shadeImg.raycastTarget = false;
        Fill(shadeGo.GetComponent<RectTransform>());

        // 2. Container cho hiệu ứng tàn lửa vàng bay
        var embersContainer = new GameObject("EmbersContainer", typeof(RectTransform));
        embersContainer.transform.SetParent(homeCanvasGo.transform, false);
        Fill(embersContainer.GetComponent<RectTransform>());

        // 3. Header Bar đỉnh (Top Status Bar)
        BuildTopHeader(homeCanvasGo.transform, font);

        // 4. Trung Tâm: 4 Thẻ Chế Độ Chơi Lớn Cân Đối
        BuildFourGameModes(homeCanvasGo.transform, font);

        // 5. Dock Menu điều hướng đáy
        BuildBottomNavBar(homeCanvasGo.transform, font);

        RefreshUserData();
    }

    #region Dynamic Background & Particle Effects
    private void StartDynamicEffects()
    {
        StopDynamicEffects();
        if (gameObject.activeInHierarchy)
        {
            backgroundAnimCoroutine = StartCoroutine(AnimateBackground());
            embersCoroutine = StartCoroutine(SpawnEmbersLoop());
        }
    }

    private void StopDynamicEffects()
    {
        if (backgroundAnimCoroutine != null) StopCoroutine(backgroundAnimCoroutine);
        if (embersCoroutine != null) StopCoroutine(embersCoroutine);
    }

    private IEnumerator AnimateBackground()
    {
        float timer = 0f;
        while (true)
        {
            timer += Time.deltaTime * 0.35f;
            if (bgRt != null)
            {
                float scale = 1.02f + Mathf.Sin(timer) * 0.02f;
                bgRt.localScale = new Vector3(scale, scale, 1f);
                float offsetX = Mathf.Cos(timer * 0.6f) * 10f;
                float offsetY = Mathf.Sin(timer * 0.4f) * 6f;
                bgRt.anchoredPosition = new Vector2(offsetX, offsetY);
            }
            yield return null;
        }
    }

    private IEnumerator SpawnEmbersLoop()
    {
        var container = homeCanvasGo != null ? homeCanvasGo.transform.Find("EmbersContainer") : null;
        if (container == null) yield break;

        var emberSprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");

        while (true)
        {
            yield return new WaitForSeconds(0.45f);
            if (container == null || !container.gameObject.activeInHierarchy) continue;
            StartCoroutine(AnimateSingleEmber(container, emberSprite));
        }
    }

    private IEnumerator AnimateSingleEmber(Transform parent, Sprite sprite)
    {
        var emberGo = new GameObject("Ember", typeof(RectTransform), typeof(Image));
        emberGo.transform.SetParent(parent, false);
        var img = emberGo.GetComponent<Image>();
        if (sprite != null) img.sprite = sprite;
        img.raycastTarget = false;

        float size = UnityEngine.Random.Range(12f, 24f);
        var rt = emberGo.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(size, size);

        float startX = UnityEngine.Random.Range(-600f, 600f);
        float startY = UnityEngine.Random.Range(-360f, -200f);
        float endY = startY + UnityEngine.Random.Range(450f, 750f);
        float speed = UnityEngine.Random.Range(40f, 80f);
        float driftFrequency = UnityEngine.Random.Range(1.5f, 3f);
        float driftAmplitude = UnityEngine.Random.Range(20f, 40f);

        Color goldColor = UnityEngine.Random.value > 0.3f 
            ? new Color(1f, 0.85f, 0.35f, 0f) 
            : new Color(1f, 0.55f, 0.2f, 0f);

        float currentY = startY;
        float elapsed = 0f;
        float totalDist = endY - startY;

        while (currentY < endY)
        {
            elapsed += Time.deltaTime;
            currentY += speed * Time.deltaTime;
            float progress = (currentY - startY) / totalDist;
            float currentX = startX + Mathf.Sin(elapsed * driftFrequency) * driftAmplitude;
            rt.anchoredPosition = new Vector2(currentX, currentY);

            float alpha = 0f;
            if (progress < 0.2f) alpha = progress / 0.2f * 0.75f;
            else if (progress < 0.7f) alpha = 0.75f;
            else alpha = (1f - progress) / 0.3f * 0.75f;

            img.color = new Color(goldColor.r, goldColor.g, goldColor.b, alpha);
            yield return null;
        }

        Destroy(emberGo);
    }
    #endregion

    #region 1. TOP HEADER BAR
    private void BuildTopHeader(Transform parent, Font font)
    {
        var headerGo = new GameObject("TopHeader", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(parent, false);
        var hImg = headerGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { hImg.sprite = slotSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.04f, 0.06f, 0.12f, 0.96f);

        var hRt = headerGo.GetComponent<RectTransform>();
        hRt.anchorMin = new Vector2(0f, 1f);
        hRt.anchorMax = new Vector2(1f, 1f);
        hRt.pivot = new Vector2(0.5f, 1f);
        hRt.sizeDelta = new Vector2(0f, 64f);
        hRt.anchoredPosition = Vector2.zero;

        // Viền vàng sắc nét dưới Header
        var lineGo = new GameObject("GoldLine", typeof(RectTransform), typeof(Image));
        lineGo.transform.SetParent(headerGo.transform, false);
        var lineImg = lineGo.GetComponent<Image>();
        lineImg.color = ThemeUI.GoldPrimary;
        var lRt = lineGo.GetComponent<RectTransform>();
        lRt.anchorMin = new Vector2(0f, 0f);
        lRt.anchorMax = new Vector2(1f, 0f);
        lRt.pivot = new Vector2(0.5f, 0f);
        lRt.sizeDelta = new Vector2(0f, 2f);
        lRt.anchoredPosition = Vector2.zero;

        // --- GÓC TRÁI: HỒ SƠ TƯỚNG QUÂN ---
        var playerProfileGo = new GameObject("PlayerProfile", typeof(RectTransform), typeof(Button));
        playerProfileGo.transform.SetParent(headerGo.transform, false);
        var ppRt = playerProfileGo.GetComponent<RectTransform>();
        ppRt.anchorMin = new Vector2(0f, 0.5f);
        ppRt.anchorMax = new Vector2(0f, 0.5f);
        ppRt.pivot = new Vector2(0f, 0.5f);
        ppRt.sizeDelta = new Vector2(320f, 54f);
        ppRt.anchoredPosition = new Vector2(16f, 0f);

        playerProfileGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            ShowHeroDetailModal();
        });

        // Khung Avatar tròn mạ vàng 48x48
        var avatarGo = new GameObject("Avatar", typeof(RectTransform), typeof(Image));
        avatarGo.transform.SetParent(playerProfileGo.transform, false);
        var avImg = avatarGo.GetComponent<Image>();
        var avSprite = LotusHealthUI.LoadSpriteFromResources("UI/ly_thuong_kiet");
        if (avSprite != null) avImg.sprite = avSprite;
        avImg.preserveAspect = true;
        var avRt = avatarGo.GetComponent<RectTransform>();
        avRt.anchorMin = avRt.anchorMax = avRt.pivot = new Vector2(0f, 0.5f);
        avRt.sizeDelta = new Vector2(48f, 48f);
        avRt.anchoredPosition = new Vector2(4f, 0f);

        var avBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        avBorder.transform.SetParent(avatarGo.transform, false);
        var bImg = avBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = ThemeUI.GoldPrimary;
        Fill(avBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // Tên Tướng Quân
        playerNameText = ThemeUI.CreateText(playerProfileGo.transform, "PlayerName", "ĐẠI TƯỚNG QUÂN", 19, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft, true);
        var nameRt = playerNameText.rectTransform;
        nameRt.anchorMin = nameRt.anchorMax = nameRt.pivot = new Vector2(0f, 1f);
        nameRt.sizeDelta = new Vector2(250f, 24f);
        nameRt.anchoredPosition = new Vector2(60f, -4f);

        // Quân Hàm & Tiến độ
        playerRankText = ThemeUI.CreateText(playerProfileGo.transform, "PlayerRank", "⭐ Chánh Tướng", 14, new Color(0.6f, 0.88f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, true);
        var rankRt = playerRankText.rectTransform;
        rankRt.anchorMin = rankRt.anchorMax = rankRt.pivot = new Vector2(0f, 0f);
        rankRt.sizeDelta = new Vector2(150f, 18f);
        rankRt.anchoredPosition = new Vector2(60f, 14f);

        var barBg = new GameObject("MilBarBg", typeof(RectTransform), typeof(Image));
        barBg.transform.SetParent(playerProfileGo.transform, false);
        var bbImg = barBg.GetComponent<Image>();
        bbImg.color = new Color(0.04f, 0.08f, 0.16f, 0.95f);
        var bbRt = barBg.GetComponent<RectTransform>();
        bbRt.anchorMin = bbRt.anchorMax = bbRt.pivot = new Vector2(0f, 0f);
        bbRt.sizeDelta = new Vector2(140f, 8f);
        bbRt.anchoredPosition = new Vector2(60f, 4f);

        var barFill = new GameObject("Fill", typeof(RectTransform), typeof(Image));
        barFill.transform.SetParent(barBg.transform, false);
        var bfImg = barFill.GetComponent<Image>();
        bfImg.color = ThemeUI.GoldHighlight;
        expBarFillRt = barFill.GetComponent<RectTransform>();
        expBarFillRt.anchorMin = Vector2.zero;
        expBarFillRt.anchorMax = new Vector2(0.5f, 1f);
        expBarFillRt.pivot = new Vector2(0f, 0.5f);
        expBarFillRt.offsetMin = expBarFillRt.offsetMax = Vector2.zero;

        playerExpText = ThemeUI.CreateText(playerProfileGo.transform, "ExpText", "0/1000", 12, new Color(1f, 0.9f, 0.5f, 0.9f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
        var peRt = playerExpText.rectTransform;
        peRt.anchorMin = peRt.anchorMax = peRt.pivot = new Vector2(0f, 0f);
        peRt.sizeDelta = new Vector2(120f, 14f);
        peRt.anchoredPosition = new Vector2(208f, 1f);

        // --- TRUNG TÂM: QUỐC HIỆU ---
        var titleGo = new GameObject("GameTitleBadge", typeof(RectTransform));
        titleGo.transform.SetParent(headerGo.transform, false);
        var titleRt = titleGo.GetComponent<RectTransform>();
        titleRt.anchorMin = titleRt.anchorMax = titleRt.pivot = new Vector2(0.5f, 0.5f);
        titleRt.sizeDelta = new Vector2(260f, 36f);
        titleRt.anchoredPosition = Vector2.zero;

        var titleTxt = ThemeUI.CreateText(titleGo.transform, "Title", "👑 ĐẠI VIỆT CHIẾN", 24, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(titleTxt.rectTransform);

        // --- GÓC PHẢI: KHỐ BẠC, VÀNG & CÀI ĐẶT ---
        var rightGroupGo = new GameObject("RightGroup", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        rightGroupGo.transform.SetParent(headerGo.transform, false);
        var rgRt = rightGroupGo.GetComponent<RectTransform>();
        rgRt.anchorMin = rgRt.anchorMax = rgRt.pivot = new Vector2(1f, 0.5f);
        rgRt.sizeDelta = new Vector2(440f, 46f);
        rgRt.anchoredPosition = new Vector2(-16f, 0f);
        var rHlg = rightGroupGo.GetComponent<HorizontalLayoutGroup>();
        rHlg.spacing = 10f;
        rHlg.childAlignment = TextAnchor.MiddleRight;
        rHlg.childControlWidth = false;
        rHlg.childControlHeight = false;

        // 1. Khối Bạc
        CreateResourceCapsule(rightGroupGo.transform, "SilverCapsule", "🪙", "0", new Color(0.90f, 0.94f, 1f, 1f), font, out silverText, () => ShowShopModal());

        // 2. Khối Vàng
        CreateResourceCapsule(rightGroupGo.transform, "GoldCapsule", "💎", "0", ThemeUI.GoldHighlight, font, out goldText, () => ShowShopModal());

        // 3. Nút Thư Tín (40x40)
        CreateIconButton(rightGroupGo.transform, "BtnMail", "✉️", new Vector2(40, 40), 20, font, () => ShowMailModal());

        // 4. Nút Cài Đặt (40x40)
        CreateIconButton(rightGroupGo.transform, "BtnSettings", "⚙️", new Vector2(40, 40), 20, font, () => ShowSettingsModal());
    }

    private void CreateResourceCapsule(Transform parent, string name, string icon, string value, Color valColor, Font font, out Text outText, Action onAdd)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.06f, 0.09f, 0.16f, 0.98f);

        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(120f, 36f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.65f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var iconTxt = ThemeUI.CreateText(go.transform, "Icon", icon, 16, Color.white, FontStyle.Normal, TextAnchor.MiddleCenter, false);
        var iRt = iconTxt.rectTransform;
        iRt.anchorMin = iRt.anchorMax = iRt.pivot = new Vector2(0f, 0.5f);
        iRt.sizeDelta = new Vector2(26f, 26f);
        iRt.anchoredPosition = new Vector2(6f, 0f);

        outText = ThemeUI.CreateText(go.transform, "Val", value, 15, valColor, FontStyle.Bold, TextAnchor.MiddleLeft, true);
        var vRt = outText.rectTransform;
        vRt.anchorMin = new Vector2(0f, 0f);
        vRt.anchorMax = new Vector2(1f, 1f);
        vRt.pivot = new Vector2(0f, 0.5f);
        vRt.offsetMin = new Vector2(32f, 0f);
        vRt.offsetMax = new Vector2(-22f, 0f);

        var plusTxt = ThemeUI.CreateText(go.transform, "Plus", "+", 16, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        var pRt = plusTxt.rectTransform;
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(1f, 0.5f);
        pRt.sizeDelta = new Vector2(18f, 18f);
        pRt.anchoredPosition = new Vector2(-5f, 0f);

        go.GetComponent<Button>().onClick.AddListener(() => onAdd?.Invoke());
    }

    private void CreateIconButton(Transform parent, string name, string icon, Vector2 size, int fontSize, Font font, Action onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.12f, 0.18f, 0.28f, 0.95f);

        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = size;

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = ThemeUI.GoldPrimary;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var txt = ThemeUI.CreateText(go.transform, "Icon", icon, fontSize, Color.white, FontStyle.Normal, TextAnchor.MiddleCenter, false);
        Fill(txt.rectTransform);

        go.GetComponent<Button>().onClick.AddListener(() => onClick?.Invoke());
    }
    #endregion

    #region 2. 4 GAME MODES CARDS (4 Thẻ Chế Độ Chơi Lớn Cân Đối)
    private void BuildFourGameModes(Transform parent, Font font)
    {
        var modesContainer = new GameObject("GameModesContainer", typeof(RectTransform));
        modesContainer.transform.SetParent(parent, false);
        var mcRt = modesContainer.GetComponent<RectTransform>();
        mcRt.anchorMin = new Vector2(0f, 0f);
        mcRt.anchorMax = new Vector2(1f, 1f);
        mcRt.pivot = new Vector2(0.5f, 0.5f);
        mcRt.offsetMin = new Vector2(24f, 74f);
        mcRt.offsetMax = new Vector2(-24f, -72f);

        var hlg = modesContainer.AddComponent<HorizontalLayoutGroup>();
        hlg.spacing = 16f;
        hlg.padding = new RectOffset(0, 0, 0, 0);
        hlg.childControlWidth = true;
        hlg.childControlHeight = true;
        hlg.childForceExpandWidth = true;
        hlg.childForceExpandHeight = true;

        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        // 1. THẺ 2v2 XẾP HẠNG
        CreateMajorModeCard(
            modesContainer.transform,
            "Mode_2v2Ranked",
            "🛡️",
            "ĐẤU TRƯỜNG 2v2",
            $"Xếp Hạng: {r2v2.badge} {r2v2.name} ({AuthUI.Current2v2Points} RP)",
            "Hiệp lực cùng đồng minh 2v2 leo bảng phong thần Đại Việt.\nThắng: +25 RP | Thua: -15 RP.",
            "VÀO ĐẤU 2v2 ➜",
            ThemeUI.GoldPrimary,
            font,
            () => ShowRanked2v2Modal()
        );

        // 2. THẺ VƯƠNG TRIỀU
        CreateMajorModeCard(
            modesContainer.transform,
            "Mode_Dynasty",
            "👑",
            "VƯƠNG TRIỀU",
            "Hoàng Tộc Tranh Bá",
            "Tranh đoạt ngọc tỷ và vương miện hoàng triều Đại Việt. Hệ thống tự động ghép phòng ngẫu nhiên.",
            "VÀO VƯƠNG TRIỀU ➜",
            new Color(0.95f, 0.65f, 0.15f, 1f),
            font,
            () => StartDynastyMode()
        );

        // 3. THẺ QUỐC CHIẾN
        CreateMajorModeCard(
            modesContainer.transform,
            "Mode_NationalWar",
            "⚔️",
            "QUỐC CHIẾN",
            "Bốn Cõi Phân Tranh",
            "Chiếm cứ thành trì hiểm yếu, mở rộng bờ cõi gấm vóc và tích lũy điểm Quân Công toàn quốc.",
            "XUẤT QUÂN ➜",
            new Color(0.85f, 0.25f, 0.22f, 1f),
            font,
            () => StartNationalWarMode()
        );

        // 4. THẺ LUYỆN TẬP
        CreateMajorModeCard(
            modesContainer.transform,
            "Mode_Practice",
            "🏹",
            "LUYỆN TẬP AI",
            "Tập Kích Sơn Tặc",
            "Giao chiến với Thủ Lĩnh Sơn Tặc để thử nghiệm tuyệt kỹ danh tướng và combo cẩm nang mới.",
            "LUYỆN TẬP ➜",
            new Color(0.25f, 0.65f, 0.95f, 1f),
            font,
            () => StartPracticeTutorial()
        );
    }

    private void CreateMajorModeCard(
        Transform parent,
        string name,
        string icon,
        string title,
        string subtitle,
        string description,
        string btnText,
        Color themeColor,
        Font font,
        Action onClick)
    {
        var cardGo = new GameObject(name, typeof(RectTransform), typeof(Image));
        cardGo.transform.SetParent(parent, false);
        var cImg = cardGo.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { cImg.sprite = choiceBg; cImg.type = Image.Type.Sliced; }
        cImg.color = new Color(0.06f, 0.09f, 0.16f, 0.98f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(cardGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = themeColor;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-2.5f, -2.5f), new Vector2(2.5f, 2.5f));

        // Icon lớn (Top Center)
        var iconTxt = ThemeUI.CreateText(cardGo.transform, "Icon", icon, 52, Color.white, FontStyle.Normal, TextAnchor.MiddleCenter, false);
        SetRect(iconTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(100f, 65f), new Vector2(0f, -12f));

        // Title lớn (22pt Bold)
        var tTxt = ThemeUI.CreateText(cardGo.transform, "Title", title, 22, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(tTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(260f, 32f), new Vector2(0f, -80f));

        // Subtitle (15pt Bold)
        var stTxt = ThemeUI.CreateText(cardGo.transform, "Sub", subtitle, 15, themeColor, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(stTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(260f, 26f), new Vector2(0f, -114f));

        // Description (14pt, Wrapped gọn gàng)
        var dTxt = ThemeUI.CreateText(cardGo.transform, "Desc", description, 14, new Color(0.85f, 0.90f, 0.96f, 0.95f), FontStyle.Normal, TextAnchor.UpperLeft, true);
        dTxt.lineSpacing = 1.3f;
        dTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        dTxt.verticalOverflow = VerticalWrapMode.Truncate;
        SetRect(dTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        dTxt.rectTransform.offsetMin = new Vector2(16f, 72f);
        dTxt.rectTransform.offsetMax = new Vector2(-16f, -145f);

        // Action Button (Bottom)
        var btnGo = new GameObject("ActionBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(cardGo.transform, false);
        var btnImg = btnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { btnImg.sprite = btnSpr; btnImg.type = Image.Type.Sliced; }
        btnImg.color = ThemeUI.GoldPrimary;

        var btnRt = btnGo.GetComponent<RectTransform>();
        SetRect(btnRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(240f, 48f), new Vector2(0f, 16f));

        var bBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        bBorder.transform.SetParent(btnGo.transform, false);
        var bbImg = bBorder.GetComponent<Image>();
        if (frameSpr != null) { bbImg.sprite = frameSpr; bbImg.type = Image.Type.Sliced; }
        bbImg.color = ThemeUI.GoldHighlight;
        Fill(bBorder.GetComponent<RectTransform>(), new Vector2(-1.5f, -1.5f), new Vector2(1.5f, 1.5f));

        var bTxt = ThemeUI.CreateText(btnGo.transform, "Txt", btnText, 17, new Color(0.12f, 0.08f, 0.02f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, false);
        Fill(bTxt.rectTransform);

        btnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlaySlash();
            onClick?.Invoke();
        });
    }
    #endregion

    #region 3. BOTTOM NAVIGATION DOCK (Dock Menu Ngọc Ấn Đáy)
    private void BuildBottomNavBar(Transform parent, Font font)
    {
        var navGo = new GameObject("BottomNavDock", typeof(RectTransform), typeof(Image));
        navGo.transform.SetParent(parent, false);
        var nImg = navGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { nImg.sprite = slotSpr; nImg.type = Image.Type.Sliced; }
        nImg.color = new Color(0.04f, 0.06f, 0.12f, 0.98f);

        var nRt = navGo.GetComponent<RectTransform>();
        nRt.anchorMin = new Vector2(0f, 0f);
        nRt.anchorMax = new Vector2(1f, 0f);
        nRt.pivot = new Vector2(0.5f, 0f);
        nRt.sizeDelta = new Vector2(0f, 62f);
        nRt.anchoredPosition = Vector2.zero;

        // Viền vàng trên thanh Bottom Nav
        var lineGo = new GameObject("GoldLine", typeof(RectTransform), typeof(Image));
        lineGo.transform.SetParent(navGo.transform, false);
        var lineImg = lineGo.GetComponent<Image>();
        lineImg.color = ThemeUI.GoldPrimary;
        var lRt = lineGo.GetComponent<RectTransform>();
        lRt.anchorMin = new Vector2(0f, 1f);
        lRt.anchorMax = new Vector2(1f, 1f);
        lRt.pivot = new Vector2(0.5f, 1f);
        lRt.sizeDelta = new Vector2(0f, 2f);
        lRt.anchoredPosition = Vector2.zero;

        var hlgGo = new GameObject("ButtonsHlg", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        hlgGo.transform.SetParent(navGo.transform, false);
        Fill(hlgGo.GetComponent<RectTransform>(), new Vector2(24, 6), new Vector2(-24, -6));
        var hlg = hlgGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 14f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = true;
        hlg.childControlHeight = true;
        hlg.childForceExpandWidth = true;
        hlg.childForceExpandHeight = true;

        CreateNavButton(hlgGo.transform, "NavHeroes", "🎖️", "DANH TƯỚNG", font, () => ShowHeroDetailModal());
        CreateNavButton(hlgGo.transform, "NavInventory", "🎒", "BINH KHÍ KHỐ", font, () => ShowInventoryModal());
        CreateNavButton(hlgGo.transform, "NavRanking", "🏆", "BẢNG VÀNG", font, () => ShowLeaderboardModal());
        CreateNavButton(hlgGo.transform, "NavQuest", "📜", "NHIỆM VỤ", font, () => ShowQuestModal());
        CreateNavButton(hlgGo.transform, "NavShop", "🛒", "TRÂN BẢO CÁC", font, () => ShowShopModal());
    }

    private void CreateNavButton(Transform parent, string name, string icon, string label, Font font, Action onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { img.sprite = choiceBg; img.type = Image.Type.Sliced; }
        img.color = new Color(0.08f, 0.12f, 0.22f, 0.95f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.5f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var txt = ThemeUI.CreateText(go.transform, "Text", $"{icon} {label}", 16, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(txt.rectTransform);

        go.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });
    }
    #endregion

    #region 4. GAME LAUNCH & MODALS
    private void StartPracticeTutorial()
    {
        AudioManager.Instance.PlaySlash();
        Hide();
        TutorialBattleUI.Create(null, () =>
        {
            Show(AuthUI.CurrentUserEmail);
        });
    }

    public void LaunchBattle2v2(List<Battle2v2UI.MatchmakingSlotInfo> slots = null)
    {
        Hide();
        Battle2v2UI.CreateWithSlots(slots, null, () =>
        {
            Show(AuthUI.CurrentUserEmail);
        });
    }

    private void StartDynastyMode()
    {
        ShowInfoDialog(
            "👑 CHẾ ĐỘ VƯƠNG TRIỀU",
            "Đấu trường hoàng tộc tranh bá đỉnh cao!\n\nHệ thống đang sẵn sàng ghép phòng thi đấu vương triều 2v2. Chiến tướng có muốn vào màn Chọn Tướng và thi đấu ngay?",
            "VÀO CHỌN TƯỚNG & CHIẾN ĐẤU",
            () => LaunchBattle2v2()
        );
    }

    private void StartNationalWarMode()
    {
        ShowInfoDialog(
            "⚔️ CHẾ ĐỘ QUỐC CHIẾN",
            "Chiến trường bang hội tranh đoạt 4 cõi non sông Đại Việt!\n\nHãy xuất trận ngay để cùng đồng đội tranh đoạt lãnh thổ và tích lũy quân công.",
            "VÀO CHỌN TƯỚNG & CHIẾN ĐẤU",
            () => LaunchBattle2v2()
        );
    }

    private void ShowRanked2v2Modal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🛡️ ĐẤU TRƯỜNG 2v2 XẾP HẠNG", new Vector2(1060f, 640f), font);

        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);
        var nextTier = Ranked2v2System.GetNextTier(AuthUI.Current2v2Points);
        float progress = Ranked2v2System.GetProgress(AuthUI.Current2v2Points);

        // Cột Trái (420px): Card Rank & Nút Tìm Trận
        var leftCol = new GameObject("LeftCol", typeof(RectTransform));
        leftCol.transform.SetParent(box.transform, false);
        var lcRt = leftCol.GetComponent<RectTransform>();
        lcRt.anchorMin = new Vector2(0f, 0f);
        lcRt.anchorMax = new Vector2(0.40f, 1f);
        lcRt.offsetMin = new Vector2(25f, 25f);
        lcRt.offsetMax = new Vector2(0f, -65f);

        var rankCard = new GameObject("RankCard", typeof(RectTransform), typeof(Image));
        rankCard.transform.SetParent(leftCol.transform, false);
        var rcImg = rankCard.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { rcImg.sprite = choiceBg; rcImg.type = Image.Type.Sliced; }
        rcImg.color = new Color(0.08f, 0.14f, 0.24f, 0.98f);
        var rcRt = rankCard.GetComponent<RectTransform>();
        SetRect(rcRt, new Vector2(0f, 0.18f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

        var rcBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        rcBorder.transform.SetParent(rankCard.transform, false);
        var rcbImg = rcBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { rcbImg.sprite = frameSpr; rcbImg.type = Image.Type.Sliced; }
        rcbImg.color = r2v2.color;
        Fill(rcBorder.GetComponent<RectTransform>(), new Vector2(-3, -3), new Vector2(3, 3));

        var badgeTxt = ThemeUI.CreateText(rankCard.transform, "Badge", r2v2.badge, 64, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(badgeTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(180f, 75f), new Vector2(0f, -8f));

        var nameTxt = ThemeUI.CreateText(rankCard.transform, "Name", r2v2.name, 28, r2v2.color, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(nameTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(380f, 38f), new Vector2(0f, -85f));

        var subTxt = ThemeUI.CreateText(rankCard.transform, "Sub", $"<b>{r2v2.subtitle}</b> • <color=#FFD700>{AuthUI.Current2v2Points} RP</color>", 20, new Color(0.9f, 0.94f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
        SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(380f, 30f), new Vector2(0f, -125f));

        // Thanh tiến độ Rank
        var barBg = new GameObject("BarBg", typeof(RectTransform), typeof(Image));
        barBg.transform.SetParent(rankCard.transform, false);
        var bbImg = barBg.GetComponent<Image>();
        bbImg.color = new Color(0.04f, 0.07f, 0.12f, 0.95f);
        var bbRt = barBg.GetComponent<RectTransform>();
        SetRect(bbRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(320f, 16f), new Vector2(0f, -165f));

        var barFill = new GameObject("Fill", typeof(RectTransform), typeof(Image));
        barFill.transform.SetParent(barBg.transform, false);
        var bfImg = barFill.GetComponent<Image>();
        bfImg.color = r2v2.color;
        var bfRt = barFill.GetComponent<RectTransform>();
        bfRt.anchorMin = Vector2.zero;
        bfRt.anchorMax = new Vector2(progress, 1f);
        bfRt.pivot = new Vector2(0f, 0.5f);
        bfRt.offsetMin = bfRt.offsetMax = Vector2.zero;

        string progLabel = r2v2.tierIndex >= 12 ? "ĐÃ ĐẠT BẬC TỐI CAO" : $"{AuthUI.Current2v2Points} / {nextTier.minPoints} RP";
        var progTxt = ThemeUI.CreateText(rankCard.transform, "ProgTxt", progLabel, 18, new Color(1f, 1f, 1f, 0.95f), FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(progTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(350f, 24f), new Vector2(0f, -190f));

        var descTxt = ThemeUI.CreateText(rankCard.transform, "Desc", r2v2.description, 17, new Color(0.85f, 0.92f, 1f, 0.95f), FontStyle.Italic, TextAnchor.MiddleCenter, true);
        descTxt.lineSpacing = 1.3f;
        descTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        SetRect(descTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(360f, 75f), new Vector2(0f, 15f));

        // Nút Tìm Trận Ghép Đội
        var matchBtnGo = new GameObject("MatchmakingBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        matchBtnGo.transform.SetParent(leftCol.transform, false);
        var mbImg = matchBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { mbImg.sprite = btnSpr; mbImg.type = Image.Type.Sliced; }
        mbImg.color = ThemeUI.GoldPrimary;
        var mbRt = matchBtnGo.GetComponent<RectTransform>();
        SetRect(mbRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(360f, 56f), new Vector2(0f, 6f));

        var mbTxt = ThemeUI.CreateText(matchBtnGo.transform, "Txt", "⚔️ BẮT ĐẦU TÌM TRẬN ➜", 20, new Color(0.12f, 0.08f, 0.02f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, false);
        Fill(mbTxt.rectTransform);

        matchBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlaySlash();
            StartCoroutine(StartAppwriteMatchmakingFlow());
        });

        // Cột Phải: Lộ Trình 12 Bậc Rank
        var rightCol = new GameObject("RightCol", typeof(RectTransform));
        rightCol.transform.SetParent(box.transform, false);
        var rrcRt = rightCol.GetComponent<RectTransform>();
        rrcRt.anchorMin = new Vector2(0.40f, 0f);
        rrcRt.anchorMax = new Vector2(1f, 1f);
        rrcRt.offsetMin = new Vector2(20f, 20f);
        rrcRt.offsetMax = new Vector2(-25f, -65f);

        var rTitle = ThemeUI.CreateText(rightCol.transform, "Title", "🏆 LỘ TRÌNH 12 BẬC RANK 2v2 ĐỒNG ĐỘI", 22, new Color(0.55f, 0.85f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, true);
        SetRect(rTitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(0f, 30f), new Vector2(5f, -2f));

        float startY = -36f;
        float rowH = 38f;
        float spacing = 2f;
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");

        for (int i = Ranked2v2System.Tiers.Length - 1; i >= 0; i--)
        {
            var tier = Ranked2v2System.Tiers[i];
            int displayIdx = 11 - i;
            float rowY = startY - displayIdx * (rowH + spacing);

            var rowGo = new GameObject("TierRow_" + i, typeof(RectTransform), typeof(Image));
            rowGo.transform.SetParent(rightCol.transform, false);
            var rowImg = rowGo.GetComponent<Image>();
            if (slotSpr != null) { rowImg.sprite = slotSpr; rowImg.type = Image.Type.Sliced; }

            bool isCurrent = tier.tierIndex == r2v2.tierIndex;
            rowImg.color = isCurrent ? new Color(0.22f, 0.32f, 0.52f, 0.98f) : new Color(0.05f, 0.08f, 0.14f, 0.85f);

            var rowRt = rowGo.GetComponent<RectTransform>();
            SetRect(rowRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, rowH), new Vector2(0f, rowY));

            if (isCurrent)
            {
                var curBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
                curBorder.transform.SetParent(rowGo.transform, false);
                var cbImg = curBorder.GetComponent<Image>();
                if (frameSpr != null) { cbImg.sprite = frameSpr; cbImg.type = Image.Type.Sliced; }
                cbImg.color = ThemeUI.GoldPrimary;
                Fill(curBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));
            }

            string currentTag = isCurrent ? " <color=#FFD700>[BẬC BẠN]</color>" : "";
            var rowName = ThemeUI.CreateText(rowGo.transform, "Name", $"{tier.badge} <color={tier.ColorHex}>{tier.name}</color>{currentTag}", 18, Color.white, isCurrent ? FontStyle.Bold : FontStyle.Normal, TextAnchor.MiddleLeft, true);
            SetRect(rowName.rectTransform, new Vector2(0f, 0f), new Vector2(0.68f, 1f), new Vector2(0f, 0.5f), Vector2.zero, Vector2.zero);
            rowName.rectTransform.offsetMin = new Vector2(14f, 0f);

            string ptRange = tier.tierIndex >= 12 ? $"{tier.minPoints}+ RP" : $"{tier.minPoints} - {tier.maxPoints} RP";
            var rowPts = ThemeUI.CreateText(rowGo.transform, "Pts", ptRange, 16, isCurrent ? ThemeUI.GoldHighlight : new Color(0.75f, 0.85f, 0.95f, 0.9f), FontStyle.Normal, TextAnchor.MiddleRight, true);
            SetRect(rowPts.rectTransform, new Vector2(0.68f, 0f), new Vector2(1f, 1f), new Vector2(1f, 0.5f), Vector2.zero, Vector2.zero);
            rowPts.rectTransform.offsetMax = new Vector2(-14f, 0f);
        }
    }

    private IEnumerator StartAppwriteMatchmakingFlow()
    {
        if (currentActiveModal != null) Destroy(currentActiveModal);

        string myUserId = !string.IsNullOrWhiteSpace(AuthUI.CurrentUserEmail) ? AuthUI.CurrentUserEmail : ("guest_" + SystemInfo.deviceUniqueIdentifier.Substring(0, 8));
        string myUserName = !string.IsNullOrWhiteSpace(AuthUI.CurrentUserName) ? AuthUI.CurrentUserName : "Đại Tướng Quân";
        int myRankPoints = AuthUI.Current2v2Points;
        var font = ThemeUI.FontMain;

        var modalRoot = new GameObject("Modal_Matchmaking2v2", typeof(RectTransform), typeof(Image));
        modalRoot.transform.SetParent(homeCanvasGo.transform, false);
        modalRoot.transform.SetAsLastSibling();
        currentActiveModal = modalRoot;

        var bgImg = modalRoot.GetComponent<Image>();
        bgImg.color = new Color(0.02f, 0.04f, 0.08f, 0.90f);
        Fill(modalRoot.GetComponent<RectTransform>());

        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(modalRoot.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.08f, 0.12f, 0.22f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = new Vector2(680f, 530f);
        boxRt.anchoredPosition = Vector2.zero;

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(boxGo.transform, false);
        var borImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = ThemeUI.GoldPrimary;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var titleTxt = ThemeUI.CreateText(boxGo.transform, "Title", "⚔️ ĐANG TÌM TRẬN ĐẤU XẾP HẠNG 2v2", 24, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(620f, 40f), new Vector2(0f, -16f));

        var timerBoxGo = new GameObject("TimerBox", typeof(RectTransform), typeof(Image));
        timerBoxGo.transform.SetParent(boxGo.transform, false);
        var tbImg = timerBoxGo.GetComponent<Image>();
        tbImg.color = new Color(0.04f, 0.08f, 0.16f, 0.95f);
        var tbRt = timerBoxGo.GetComponent<RectTransform>();
        SetRect(tbRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(200f, 44f), new Vector2(0f, -58f));

        var timerTxt = ThemeUI.CreateText(timerBoxGo.transform, "TimerTxt", "⏳ 0s", 24, ThemeUI.GoldPrimary, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(timerTxt.rectTransform);

        var statusTxt = ThemeUI.CreateText(boxGo.transform, "StatusTxt", "🌐 Đang quét tìm các phòng đấu trên máy chủ...", 18, new Color(0.6f, 0.88f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
        SetRect(statusTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(620f, 30f), new Vector2(0f, -108f));

        var slotsContainer = new GameObject("Slots", typeof(RectTransform));
        slotsContainer.transform.SetParent(boxGo.transform, false);
        var scRt = slotsContainer.GetComponent<RectTransform>();
        SetRect(scRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(620f, 240f), new Vector2(0f, -15f));

        var slotTexts = new Text[4];
        var slotImgs = new Image[4];
        for (int i = 0; i < 4; i++)
        {
            var sGo = new GameObject("Slot_" + i, typeof(RectTransform), typeof(Image));
            sGo.transform.SetParent(slotsContainer.transform, false);
            slotImgs[i] = sGo.GetComponent<Image>();
            var sSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (sSpr != null) { slotImgs[i].sprite = sSpr; slotImgs[i].type = Image.Type.Sliced; }
            slotImgs[i].color = new Color(0.04f, 0.08f, 0.16f, 0.95f);

            var sRt = sGo.GetComponent<RectTransform>();
            float sY = 85f - (i * 56f);
            SetRect(sRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(580f, 48f), new Vector2(0f, sY));

            string teamTag = (i == 0 || i == 2) ? "<color=#55DDFF>[RỒNG]</color>" : "<color=#FF6666>[PHƯỢNG]</color>";
            string defaultLabel = (i == 0)
                ? $"<b>Ghế 1 ({teamTag} - BẠN):</b> <color=#FFD700>{myUserName}</color> • {myRankPoints} RP"
                : $"<b>Ghế {i + 1} ({teamTag}):</b> <color=#8899AA>Đang chờ tướng lĩnh...</color>";

            slotTexts[i] = ThemeUI.CreateText(sGo.transform, "Text", defaultLabel, 18, Color.white, FontStyle.Normal, TextAnchor.MiddleLeft, true);
            SetRect(slotTexts[i].rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0f, 0.5f), Vector2.zero, Vector2.zero);
            slotTexts[i].rectTransform.offsetMin = new Vector2(18f, 0f);
        }

        // Nút Hủy Tìm Trận
        var cancelBtnGo = new GameObject("CancelBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        cancelBtnGo.transform.SetParent(boxGo.transform, false);
        var cBtnImg = cancelBtnGo.GetComponent<Image>();
        var btnSpr2 = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr2 != null) { cBtnImg.sprite = btnSpr2; cBtnImg.type = Image.Type.Sliced; }
        cBtnImg.color = new Color(0.85f, 0.25f, 0.2f, 1f);

        var cBtnRt = cancelBtnGo.GetComponent<RectTransform>();
        SetRect(cBtnRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(280f, 50f), new Vector2(0f, 20f));

        var cBtnTxt = ThemeUI.CreateText(cancelBtnGo.transform, "Text", "✕ HỦY TÌM TRẬN", 19, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(cBtnTxt.rectTransform);

        bool isCancelled = false;
        cancelBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            isCancelled = true;
            if (currentActiveModal != null) Destroy(currentActiveModal);
        });

        float timer = 0f;
        while (!isCancelled && timer < 2.5f)
        {
            timer += Time.deltaTime;
            if (timerTxt != null) timerTxt.text = $"⏳ {Mathf.FloorToInt(timer)}s";
            yield return null;
        }

        if (!isCancelled)
        {
            if (currentActiveModal != null) Destroy(currentActiveModal);
            LaunchBattle2v2();
        }
    }

    private void ShowHeroDetailModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🎖️ THÔNG TIN DANH TƯỚNG ĐẠI VIỆT", new Vector2(860f, 540f), font);

        string activeHeroName = "Lý Thường Kiệt";
        if (!string.IsNullOrEmpty(AuthUI.CurrentGenerals))
        {
            string[] gens = AuthUI.CurrentGenerals.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
            if (gens.Length > 0)
            {
                var h = HeroDatabase100.GetHeroByName(gens[0]);
                if (h != null) activeHeroName = h.name;
            }
        }
        var hero = HeroDatabase100.GetHeroByName(activeHeroName);
        if (hero == null) hero = HeroDatabase100.GetHero(47);

        // Portrait bên trái
        var avGo = new GameObject("HeroAvatar", typeof(RectTransform), typeof(Image));
        avGo.transform.SetParent(box.transform, false);
        var avImg = avGo.GetComponent<Image>();
        var spr = LotusHealthUI.LoadSpriteFromResources(!string.IsNullOrEmpty(hero.avatarPath) ? hero.avatarPath : "UI/ly_thuong_kiet");
        if (spr != null) avImg.sprite = spr;
        avImg.preserveAspect = true;
        var avRt = avGo.GetComponent<RectTransform>();
        SetRect(avRt, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(250f, 340f), new Vector2(28f, -10f));

        var avBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        avBorder.transform.SetParent(avGo.transform, false);
        var bImg = avBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = ThemeUI.GoldPrimary;
        Fill(avBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var milTier = MilitaryRankSystem.GetTier(AuthUI.CurrentMilitaryPoints);
        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        var infoTxt = ThemeUI.CreateText(box.transform, "InfoPanel",
            $"<b>Danh Tướng:</b> <color=#FFD700>{hero.name.ToUpper()}</color>\n" +
            "<b>Trạng thái:</b> <color=#55FF55>Đã mở khóa & Đồng bộ Appwrite</color>\n" +
            $"<b>Quân Hàm:</b> <color={milTier.ColorHex}>{milTier.badge} {milTier.name}</color> ({AuthUI.CurrentMilitaryPoints}đ • {milTier.subtitle})\n" +
            $"<b>Rank 2v2:</b> <color={r2v2.ColorHex}>{r2v2.badge} {r2v2.name}</color> ({AuthUI.Current2v2Points} RP)\n" +
            $"<b>Sinh Mệnh:</b> <color=#FF5555>{hero.maxHp} Đóa Sen Máu</color>  |  <b>Phe Phái:</b> <color=#55FF55>{hero.faction}</color>\n\n" +
            $"<b>⚡ Tuyệt Kỹ [{hero.skillName.ToUpper()}]:</b>\n" +
            $"{hero.skillDesc}",
            17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.UpperLeft, true);
        infoTxt.lineSpacing = 1.35f;
        infoTxt.horizontalOverflow = HorizontalWrapMode.Wrap;

        var iRt = infoTxt.rectTransform;
        SetRect(iRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        iRt.offsetMin = new Vector2(300f, 30f);
        iRt.offsetMax = new Vector2(-28f, -65f);
    }

    private void ShowInventoryModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🎒 BINH KHÍ KHỐ (TÚI ĐỒ & BẢO VẬT)", new Vector2(860f, 540f), font);

        var items = new[]
        {
            ("UI/icon_weapon", "♠2 Song Cung Mường Nhạ", "Vũ Khí (Tầm 2)\nKhi Trảm bị Đỡ, có thể bỏ 2 lá bài ép mục tiêu mất 1 máu."),
            ("UI/icon_weapon", "♠A Kiếm Thuận Thiên", "Vũ Khí (Tầm 2)\nThanh kiếm thần tích tụ linh khí ngàn năm."),
            ("UI/icon_armor", "♠2 Giáp Đồng Sơn Vi", "Giáp Phòng Thủ\nVô hiệu hóa hoàn toàn mọi đòn Trảm Thường không thuộc tính."),
            ("UI/icon_armor", "♣2 Khiên Mây Bện", "Giáp Phòng Thủ\nLật phán xét Đỏ để vô hiệu hóa Mưa Tên & Bãi Cọc."),
            ("UI/icon_mount_offense", "♦K Xích Thố (-1)", "Ngựa Tấn Công\nGiảm cự ly khi tấn công kẻ địch đi 1 khoảng cách."),
            ("UI/icon_mount_defense", "♥K Phi Lực (+1)", "Ngựa Phòng Thủ\nTăng cự ly kẻ địch nhắm vào bản thân thêm 1 khoảng cách.")
        };

        float startY = -75f;
        for (int i = 0; i < items.Length; i++)
        {
            var it = items[i];
            float colX = (i % 2 == 0) ? -200f : 200f;
            float rowY = startY - (i / 2) * 135f;

            var cardGo = new GameObject("ItemCard_" + i, typeof(RectTransform), typeof(Image));
            cardGo.transform.SetParent(box.transform, false);
            var cImg = cardGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { cImg.sprite = slotSpr; cImg.type = Image.Type.Sliced; }
            cImg.color = new Color(0.05f, 0.08f, 0.16f, 0.95f);

            var cRt = cardGo.GetComponent<RectTransform>();
            SetRect(cRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(380f, 120f), new Vector2(colX, rowY));

            var cBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
            cBorder.transform.SetParent(cardGo.transform, false);
            var cbImg = cBorder.GetComponent<Image>();
            var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (frameSpr != null) { cbImg.sprite = frameSpr; cbImg.type = Image.Type.Sliced; }
            cbImg.color = ThemeUI.GoldPrimary;
            Fill(cBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

            var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Image));
            iconGo.transform.SetParent(cardGo.transform, false);
            var icImg = iconGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources(it.Item1);
            if (spr != null) icImg.sprite = spr;
            icImg.preserveAspect = true;
            var icRt = iconGo.GetComponent<RectTransform>();
            SetRect(icRt, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(60f, 60f), new Vector2(14f, 0f));

            var nTxt = ThemeUI.CreateText(cardGo.transform, "Name", it.Item2, 17, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft, true);
            SetRect(nTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-85f, 26f), new Vector2(82f, -10f));

            var dTxt = ThemeUI.CreateText(cardGo.transform, "Desc", it.Item3, 14, new Color(0.85f, 0.92f, 1f, 0.95f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
            dTxt.lineSpacing = 1.25f;
            dTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
            SetRect(dTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0f, 0f), new Vector2(-85f, -38f), new Vector2(82f, 8f));
        }
    }

    private void ShowLeaderboardModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🏆 BẢNG VÀNG QUÂN CÔNG & XẾP HẠNG 12 BẬC", new Vector2(860f, 540f), font);

        var contentGo = new GameObject("ContentArea", typeof(RectTransform));
        contentGo.transform.SetParent(box.transform, false);
        var caRt = contentGo.GetComponent<RectTransform>();
        SetRect(caRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        caRt.offsetMin = new Vector2(35f, 25f);
        caRt.offsetMax = new Vector2(-35f, -70f);

        string userName = string.IsNullOrEmpty(AuthUI.CurrentUserName) ? "Lý Thường Kiệt" : AuthUI.CurrentUserName;
        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        var leadTxt = ThemeUI.CreateText(contentGo.transform, "Content",
            "<b>BẢNG PHONG THẦN XẾP HẠNG 2v2 ĐỒNG ĐỘI (12 BẬC RANK):</b>\n\n" +
            "🥇 <b>1. Cặp Đôi Long Vân: Hưng Đạo & Dã Tượng</b> — 8.800 RP  [🌌 Thần Thoại Quân Vương • Bậc 12/12]\n" +
            "🥈 <b>2. Song Hào Kiệt: Quang Trung & Ngô Thì Nhậm</b> — 6.500 RP  [🌌 Thần Thoại Quân Vương • Bậc 12/12]\n" +
            "🥉 <b>3. Thiết Giáp Vệ: Hai Bà Trưng</b> — 5.400 RP  [⚡ Vô Song Hào Kiệt • Bậc 11/12]\n" +
            "   <b>4. Tương Trợ Song Sư: Trần Khánh Dư & Yết Kiêu</b> — 4.600 RP  [👑 Vương Giả • Bậc 10/12]\n" +
            "   <b>5. Hùng Sư Trấn Quốc: Đinh Bộ Lĩnh & Đinh Điền</b> — 3.800 RP  [🏆 Hùng Sư • Bậc 9/12]\n\n" +
            $"⭐ <b>VỊ TRÍ CỦA BẠN:</b> <color=#55FF55>{userName}</color> — <b>{AuthUI.Current2v2Points} RP</b>  [{r2v2.badge} {r2v2.name} • {r2v2.subtitle}]",
            17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.UpperLeft, true);
        leadTxt.lineSpacing = 1.4f;
        leadTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        Fill(leadTxt.rectTransform);
    }

    private void ShowQuestModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("📜 NHIỆM VỤ CHIẾN TƯỚNG HÀNG NGÀY", new Vector2(780f, 480f), font);

        var questTxt = ThemeUI.CreateText(box.transform, "Content",
            "<b>DANH SÁCH NHIỆM VỤ:</b>\n\n" +
            "✅ <b>Khai Môn Tân Thủ:</b> Hoàn tất hướng dẫn cơ bản. (<color=#55FF55>Đã nhận: 1.000 Bạc & Tướng Lý Thường Kiệt</color>)\n\n" +
            "⏳ <b>Bách Chiến Bách Thắng:</b> Tham gia 3 trận đấu xếp hạng 2v2. (Tiến độ: 1/3)\n\n" +
            "⏳ <b>Thần Xạ Thủ:</b> Kích hoạt kỹ năng Song Cung Mường Nhạ 1 lần. (Tiến độ: 0/1)\n\n" +
            "⏳ <b>Tuyệt Kỹ Biến Ảo:</b> Dùng kỹ năng danh tướng 2 lần trong một ván đấu. (Tiến độ: 0/2)",
            17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
        questTxt.lineSpacing = 1.4f;
        questTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        SetRect(questTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        questTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        questTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private void ShowShopModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🛒 TRÂN BẢO CÁC (CỬA HÀNG)", new Vector2(780f, 480f), font);

        var shopTxt = ThemeUI.CreateText(box.transform, "Content",
            "<b>TRÂN BẢO CÁC ĐẠI VIỆT CHIẾN:</b>\n\n" +
            "🪙 <b>Túi 500 Bạc:</b> Đổi bằng 50 Vàng.\n" +
            "🪙 <b>Rương 2.000 Bạc:</b> Đổi bằng 180 Vàng.\n" +
            "🎁 <b>Gói Tướng Tân Thủ:</b> Sở hữu trọn bộ thẻ tướng & trang bị độc quyền.\n\n" +
            "<i>(Tính năng giao thương đang tiếp tục được cập nhật ở phiên bản tiếp theo!)</i>",
            17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
        shopTxt.lineSpacing = 1.4f;
        shopTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        SetRect(shopTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        shopTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        shopTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private void ShowMailModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("✉️ THƯ TÍN QUÂN ĐOÀN", new Vector2(780f, 480f), font);

        var mailTxt = ThemeUI.CreateText(box.transform, "Content",
            "<b>HÒM THƯ QUÂN ĐOÀN ĐẠI VIỆT:</b>\n\n" +
            "📩 <b>[Quà Khai Môn Tân Thủ]:</b> Chúc mừng chiến tướng đã gia nhập Đại Việt Chiến! Phần thưởng <b>1.000 Bạc</b> và <b>Tướng Lý Thường Kiệt</b> đã được đồng bộ trực tiếp vào tài khoản Appwrite của bạn.\n\n" +
            "📩 <b>[Hịch Tướng Sĩ]:</b> Sẵn sàng tham gia 3 đại chiến trường: <b>Vương Triều</b>, <b>Quốc Chiến</b> và <b>Đấu 2v2 Xếp Hạng</b>!",
            17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
        mailTxt.lineSpacing = 1.35f;
        mailTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        SetRect(mailTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        mailTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        mailTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private void ShowSettingsModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("⚙️ CÀI ĐẶT TRÒ CHƠI", new Vector2(660f, 420f), font);

        var desc = ThemeUI.CreateText(box.transform, "Desc", "Âm thanh & Tùy chọn tài khoản:", 18, new Color(0.88f, 0.94f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft, true);
        SetRect(desc.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(540, 30), new Vector2(0, -70));

        var logoutBtnGo = new GameObject("LogoutBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        logoutBtnGo.transform.SetParent(box.transform, false);
        var lImg = logoutBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { lImg.sprite = btnSpr; lImg.type = Image.Type.Sliced; }
        lImg.color = new Color(0.88f, 0.25f, 0.18f, 1f);

        var lRt = logoutBtnGo.GetComponent<RectTransform>();
        SetRect(lRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(280f, 50f), new Vector2(0f, 35f));

        var lBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        lBorder.transform.SetParent(logoutBtnGo.transform, false);
        var lbImg = lBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { lbImg.sprite = frameSpr; lbImg.type = Image.Type.Sliced; }
        lbImg.color = ThemeUI.GoldPrimary;
        Fill(lBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var lTxt = ThemeUI.CreateText(logoutBtnGo.transform, "Label", "🚪 ĐĂNG XUẤT", 19, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(lTxt.rectTransform);

        logoutBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (currentActiveModal != null) Destroy(currentActiveModal);
            Hide();
            var auth = FindFirstObjectByType<AuthUI>();
            if (auth != null)
            {
                auth.PerformLogout();
            }
        });
    }

    private void ShowInfoDialog(string title, string content, string actionLabel, Action onConfirm)
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal(title, new Vector2(720f, 420f), font);

        var cTxt = ThemeUI.CreateText(box.transform, "Content", content, 17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
        cTxt.lineSpacing = 1.35f;
        cTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        SetRect(cTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(640, 140), new Vector2(0, 18));

        var actBtnGo = new GameObject("ConfirmBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        actBtnGo.transform.SetParent(box.transform, false);
        var aImg = actBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { aImg.sprite = btnSpr; aImg.type = Image.Type.Sliced; }
        aImg.color = new Color(0.88f, 0.48f, 0.12f, 1f);

        var aRt = actBtnGo.GetComponent<RectTransform>();
        SetRect(aRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(300f, 50f), new Vector2(0f, 26f));

        var aBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        aBorder.transform.SetParent(actBtnGo.transform, false);
        var abImg = aBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { abImg.sprite = frameSpr; abImg.type = Image.Type.Sliced; }
        abImg.color = ThemeUI.GoldPrimary;
        Fill(aBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var aTxt = ThemeUI.CreateText(actBtnGo.transform, "Label", actionLabel, 19, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(aTxt.rectTransform);

        actBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (currentActiveModal != null) Destroy(currentActiveModal);
            onConfirm?.Invoke();
        });
    }

    private GameObject CreateBaseModal(string title, Vector2 size, Font font)
    {
        if (currentActiveModal != null) Destroy(currentActiveModal);

        var modalRoot = new GameObject("Modal_" + title, typeof(RectTransform), typeof(Image));
        modalRoot.transform.SetParent(homeCanvasGo.transform, false);
        modalRoot.transform.SetAsLastSibling();
        currentActiveModal = modalRoot;

        var bgImg = modalRoot.GetComponent<Image>();
        bgImg.color = new Color(0.02f, 0.04f, 0.08f, 0.88f);
        Fill(modalRoot.GetComponent<RectTransform>());

        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(modalRoot.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.08f, 0.12f, 0.22f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        SetRect(boxRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), size, Vector2.zero);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(boxGo.transform, false);
        var borImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = ThemeUI.GoldPrimary;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var titleTxt = ThemeUI.CreateText(boxGo.transform, "Title", title, 24, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 90f, 40f), new Vector2(0, -14));

        var closeBtnGo = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        closeBtnGo.transform.SetParent(boxGo.transform, false);
        var cImg = closeBtnGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { cImg.sprite = slotSpr; cImg.type = Image.Type.Sliced; }
        cImg.color = new Color(0.7f, 0.18f, 0.18f, 0.98f);

        var cRt = closeBtnGo.GetComponent<RectTransform>();
        SetRect(cRt, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(38f, 38f), new Vector2(-12f, -12f));

        var cBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        cBorder.transform.SetParent(closeBtnGo.transform, false);
        var cbImg = cBorder.GetComponent<Image>();
        if (frameSpr != null) { cbImg.sprite = frameSpr; cbImg.type = Image.Type.Sliced; }
        cbImg.color = ThemeUI.GoldPrimary;
        Fill(cBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var xTxt = ThemeUI.CreateText(closeBtnGo.transform, "X", "✕", 18, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(xTxt.rectTransform);
        closeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (currentActiveModal != null) Destroy(currentActiveModal);
        });

        return boxGo;
    }
    #endregion

    #region Helper Utilities
    private static void Fill(RectTransform rt, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        if (rt == null) return;
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.offsetMin = offsetMin;
        rt.offsetMax = offsetMax;
    }

    private static void SetRect(RectTransform rt, Vector2 min, Vector2 max, Vector2 pivot, Vector2 size, Vector2 pos)
    {
        if (rt == null) return;
        rt.anchorMin = min;
        rt.anchorMax = max;
        rt.pivot = pivot;
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;
    }
    #endregion
}
