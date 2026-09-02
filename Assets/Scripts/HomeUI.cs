using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Giao diện Trang Chủ (Main Menu / Lobby) phong cách Đại Việt Chiến.
/// - Hình nền động hoàng cung đại điện lộng lẫy với hiệu ứng chuyển động thở và tàn lửa vàng bay
/// - Thông tin người chơi, quân hàm, cấp độ và kinh nghiệm liên kết trực tiếp với Appwrite
/// - Ngân lượng (Bạc) và Vàng (mặc định 0) đồng bộ Appwrite (không còn thể lực)
/// - 3 Chế độ chơi chính: 👑 Vương Triều, ⚔️ Quốc Chiến, 🛡️ Đấu 2v2 Xếp Hạng
/// - Nút lá thư góc phải lớn hơn với chấm đỏ thông báo
/// - Thanh điều hướng dưới cùng: Tướng Lĩnh, Binh Khí Khố, Bảng Vàng, Nhiệm Vụ, Trân Bảo Các
/// - Popup thông tin Tướng, Túi Đồ, Cài Đặt âm thanh và Đăng xuất
/// </summary>
public sealed class HomeUI : MonoBehaviour
{
    private static HomeUI instance;
    public static HomeUI Instance => instance;

    private CanvasScaler scaler;
    private GameObject homeCanvasGo;
    private RectTransform bgRt;
    private RawImage bgRaw;

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
        // 1. Tên người chơi từ Appwrite
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
            if (displayName.Length > 60) displayName = displayName.Substring(0, 60);
            playerNameText.text = displayName;
        }

        // 2. Quân Hàm 12 Bậc từ MilitaryRankSystem
        var milTier = MilitaryRankSystem.GetTier(AuthUI.CurrentMilitaryPoints);
        if (playerRankText != null)
        {
            playerRankText.text = $"{milTier.badge} <color={milTier.ColorHex}>{milTier.name}</color> • {AuthUI.CurrentMilitaryPoints}đ ({milTier.subtitle})";
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
            silverText.text = $"{AuthUI.CurrentSilver:N0} Bạc";
        }
        if (goldText != null)
        {
            goldText.text = $"{AuthUI.CurrentGold:N0} Vàng";
        }
    }

    private string GetRankTitle(int level)
    {
        if (level >= 50) return "Đại Nguyên Soái";
        if (level >= 30) return "Thượng Tướng Quân";
        if (level >= 20) return "Đại Tướng Quân";
        if (level >= 10) return "Trung Tướng Quân";
        if (level >= 5) return "Thiếu Tướng Quân";
        return "Chánh Tướng";
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

        // Lớp phủ màu mờ sẫm nhẹ để đọc tốt chữ và nút
        var shadeGo = new GameObject("Shade", typeof(RectTransform), typeof(Image));
        shadeGo.transform.SetParent(homeCanvasGo.transform, false);
        var shadeImg = shadeGo.GetComponent<Image>();
        shadeImg.color = new Color(0.03f, 0.05f, 0.1f, 0.45f);
        shadeImg.raycastTarget = false;
        Fill(shadeGo.GetComponent<RectTransform>());

        // 2. Container cho hiệu ứng tàn lửa vàng bay (Embers Container)
        var embersContainer = new GameObject("EmbersContainer", typeof(RectTransform));
        embersContainer.transform.SetParent(homeCanvasGo.transform, false);
        Fill(embersContainer.GetComponent<RectTransform>());

        // 3. Header Bar (Thanh Đầu Trang)
        BuildTopHeader(homeCanvasGo.transform, font);

        // 4. Trung Tâm: 3 Chế Độ Chơi (Vương Triều, Quốc Chiến, Đấu 2v2 Xếp Hạng) & Nút Luyện Tập
        BuildThreeGameModes(homeCanvasGo.transform, font);

        // 5. Bottom Navigation Bar (Thanh Menu Dưới Cùng)
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
            timer += Time.deltaTime * 0.4f;
            if (bgRt != null)
            {
                // Hiệu ứng thở nhẹ (Breathing camera scale)
                float scale = 1.02f + Mathf.Sin(timer) * 0.025f;
                bgRt.localScale = new Vector3(scale, scale, 1f);

                // Chuyển động lia máy ảnh tinh tế (Subtle Pan)
                float offsetX = Mathf.Cos(timer * 0.7f) * 15f;
                float offsetY = Mathf.Sin(timer * 0.5f) * 10f;
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
            yield return new WaitForSeconds(0.4f);
            if (container == null || !container.gameObject.activeInHierarchy) continue;

            // Tạo một đốm sáng vàng bay lên
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

        float size = UnityEngine.Random.Range(10f, 26f);
        var rt = emberGo.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(size, size);

        float startX = UnityEngine.Random.Range(-600f, 600f);
        float startY = UnityEngine.Random.Range(-360f, -200f);
        float endY = startY + UnityEngine.Random.Range(450f, 750f);
        float speed = UnityEngine.Random.Range(45f, 90f);
        float driftFrequency = UnityEngine.Random.Range(1.5f, 3.5f);
        float driftAmplitude = UnityEngine.Random.Range(20f, 50f);

        Color goldColor = UnityEngine.Random.value > 0.3f 
            ? new Color(1f, 0.88f, 0.35f, 0f) 
            : new Color(1f, 0.6f, 0.2f, 0f);

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

            // Fade in ở 20% đầu, giữ sáng ở giữa, fade out ở 30% cuối
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

    #region Top Header Bar
    private void BuildTopHeader(Transform parent, Font font)
    {
        var headerGo = new GameObject("TopHeader", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(parent, false);
        var hImg = headerGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { hImg.sprite = slotSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);

        var hRt = headerGo.GetComponent<RectTransform>();
        hRt.anchorMin = new Vector2(0f, 1f);
        hRt.anchorMax = new Vector2(1f, 1f);
        hRt.pivot = new Vector2(0.5f, 1f);
        hRt.sizeDelta = new Vector2(0f, 74f);
        hRt.anchoredPosition = Vector2.zero;

        // Viền vàng dưới header
        var lineGo = new GameObject("GoldLine", typeof(RectTransform), typeof(Image));
        lineGo.transform.SetParent(headerGo.transform, false);
        var lineImg = lineGo.GetComponent<Image>();
        lineImg.color = new Color(0.92f, 0.78f, 0.32f, 0.95f);
        var lRt = lineGo.GetComponent<RectTransform>();
        lRt.anchorMin = new Vector2(0f, 0f);
        lRt.anchorMax = new Vector2(1f, 0f);
        lRt.pivot = new Vector2(0.5f, 0f);
        lRt.sizeDelta = new Vector2(0f, 3f);
        lRt.anchoredPosition = Vector2.zero;

        // --- GÓC TRÁI: THÔNG TIN NGƯỜI CHƠI (TÊN, CẤP, EXP LIÊN KẾT APPWRITE) ---
        var playerProfileGo = new GameObject("PlayerProfile", typeof(RectTransform));
        playerProfileGo.transform.SetParent(headerGo.transform, false);
        var ppRt = playerProfileGo.GetComponent<RectTransform>();
        ppRt.anchorMin = new Vector2(0f, 0.5f);
        ppRt.anchorMax = new Vector2(0f, 0.5f);
        ppRt.pivot = new Vector2(0f, 0.5f);
        ppRt.sizeDelta = new Vector2(380f, 64f);
        ppRt.anchoredPosition = new Vector2(18f, 0f);

        // Avatar khung tròn & Nút bấm lớn (56x56)
        var avatarGo = new GameObject("Avatar", typeof(RectTransform), typeof(Image), typeof(Button));
        avatarGo.transform.SetParent(playerProfileGo.transform, false);
        var avImg = avatarGo.GetComponent<Image>();
        var avSprite = LotusHealthUI.LoadSpriteFromResources("UI/ly_thuong_kiet");
        if (avSprite != null) avImg.sprite = avSprite;
        var avRt = avatarGo.GetComponent<RectTransform>();
        avRt.anchorMin = avRt.anchorMax = avRt.pivot = new Vector2(0f, 0.5f);
        avRt.sizeDelta = new Vector2(56f, 56f);
        avRt.anchoredPosition = new Vector2(4f, 0f);

        // Khung viền avatar vàng
        var avBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        avBorder.transform.SetParent(avatarGo.transform, false);
        var bImg = avBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 1f);
        Fill(avBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        avatarGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            ShowHeroDetailModal();
        });

        // Tên người chơi lớn (26pt Bold)
        var nameGo = new GameObject("PlayerName", typeof(RectTransform), typeof(Text));
        nameGo.transform.SetParent(playerProfileGo.transform, false);
        playerNameText = nameGo.GetComponent<Text>();
        playerNameText.font = font;
        playerNameText.fontSize = 26;
        playerNameText.horizontalOverflow = HorizontalWrapMode.Overflow;
        playerNameText.fontStyle = FontStyle.Bold;
        playerNameText.color = new Color(1f, 0.95f, 0.75f, 1f);
        var nameRt = nameGo.GetComponent<RectTransform>();
        nameRt.anchorMin = nameRt.anchorMax = nameRt.pivot = new Vector2(0f, 1f);
        nameRt.sizeDelta = new Vector2(440f, 32f);
        nameRt.anchoredPosition = new Vector2(70f, -4f);
        AddShadow(nameGo);

        // Quân hàm & Cấp độ lớn (22pt Bold)
        var rankGo = new GameObject("PlayerRank", typeof(RectTransform), typeof(Text));
        rankGo.transform.SetParent(playerProfileGo.transform, false);
        playerRankText = rankGo.GetComponent<Text>();
        playerRankText.font = font;
        playerRankText.fontSize = 22;
        playerRankText.color = new Color(0.6f, 0.88f, 1f, 1f);
        playerRankText.text = "⭐ Chánh Tướng • Cấp 1";
        var rankRt = rankGo.GetComponent<RectTransform>();
        rankRt.anchorMin = rankRt.anchorMax = rankRt.pivot = new Vector2(0f, 1f);
        rankRt.sizeDelta = new Vector2(440f, 26f);
        rankRt.anchoredPosition = new Vector2(70f, -32f);

        // Thanh tiến độ EXP từ Appwrite
        var expBgGo = new GameObject("ExpBarBg", typeof(RectTransform), typeof(Image));
        expBgGo.transform.SetParent(playerProfileGo.transform, false);
        var expBgImg = expBgGo.GetComponent<Image>();
        expBgImg.color = new Color(0.1f, 0.14f, 0.22f, 0.95f);
        var expBgRt = expBgGo.GetComponent<RectTransform>();
        expBgRt.anchorMin = expBgRt.anchorMax = expBgRt.pivot = new Vector2(0f, 0f);
        expBgRt.sizeDelta = new Vector2(180f, 10f);
        expBgRt.anchoredPosition = new Vector2(70f, 4f);

        var expFillGo = new GameObject("Fill", typeof(RectTransform), typeof(Image));
        expFillGo.transform.SetParent(expBgGo.transform, false);
        var expFillImg = expFillGo.GetComponent<Image>();
        expFillImg.color = new Color(0.2f, 0.85f, 0.45f, 1f);
        expBarFillRt = expFillGo.GetComponent<RectTransform>();
        expBarFillRt.anchorMin = Vector2.zero;
        expBarFillRt.anchorMax = new Vector2(0.2f, 1f);
        expBarFillRt.pivot = new Vector2(0f, 0.5f);
        expBarFillRt.offsetMin = expBarFillRt.offsetMax = Vector2.zero;

        var expTxtGo = new GameObject("ExpText", typeof(RectTransform), typeof(Text));
        expTxtGo.transform.SetParent(playerProfileGo.transform, false);
        playerExpText = expTxtGo.GetComponent<Text>();
        playerExpText.font = font;
        playerExpText.fontSize = 18;
        playerExpText.fontStyle = FontStyle.Bold;
        playerExpText.color = new Color(0.85f, 0.95f, 1f, 0.95f);
        playerExpText.text = "EXP: 0/1.000";
        var etRt = expTxtGo.GetComponent<RectTransform>();
        etRt.anchorMin = etRt.anchorMax = etRt.pivot = new Vector2(0f, 0f);
        etRt.sizeDelta = new Vector2(120f, 16f);
        etRt.anchoredPosition = new Vector2(258f, 2f);

        // --- TRUNG TÂM: QUỐC HIỆU LỚN (36pt Bold) ---
        var titleGo = new GameObject("GameTitle", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(headerGo.transform, false);
        var titleTxt = titleGo.GetComponent<Text>();
        titleTxt.font = font;
        titleTxt.fontSize = 36;
        titleTxt.fontStyle = FontStyle.Bold;
        titleTxt.alignment = TextAnchor.MiddleCenter;
        titleTxt.color = new Color(1f, 0.88f, 0.32f, 1f);
        titleTxt.text = "👑 ĐẠI VIỆT CHIẾN";
        var titleRt = titleGo.GetComponent<RectTransform>();
        titleRt.anchorMin = titleRt.anchorMax = titleRt.pivot = new Vector2(0.5f, 0.5f);
        titleRt.sizeDelta = new Vector2(340f, 42f);
        titleRt.anchoredPosition = Vector2.zero;
        AddShadow(titleGo);

        // --- GÓC PHẢI: KHỐ TÀI NGUYÊN (BẠC, VÀNG) & NÚT THƯ LỚN & CÀI ĐẶT ---
        var rightGroupGo = new GameObject("RightGroup", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        rightGroupGo.transform.SetParent(headerGo.transform, false);
        var rgRt = rightGroupGo.GetComponent<RectTransform>();
        rgRt.anchorMin = rgRt.anchorMax = rgRt.pivot = new Vector2(1f, 0.5f);
        rgRt.sizeDelta = new Vector2(520f, 56f);
        rgRt.anchoredPosition = new Vector2(-16f, 0f);
        var rHlg = rightGroupGo.GetComponent<HorizontalLayoutGroup>();
        rHlg.spacing = 14f;
        rHlg.childAlignment = TextAnchor.MiddleRight;
        rHlg.childControlWidth = false;
        rHlg.childControlHeight = false;

        // 1. Khối Bạc lớn (155 x 44)
        CreateResourceBadge(rightGroupGo.transform, "SilverBadge", "🪙", $"{AuthUI.CurrentSilver:N0} Bạc", new Color(0.90f, 0.94f, 1f, 1f), font, out silverText, () => ShowShopModal());

        // 2. Khối Vàng lớn (155 x 44)
        CreateResourceBadge(rightGroupGo.transform, "GoldBadge", "💎", $"{AuthUI.CurrentGold:N0} Vàng", new Color(1f, 0.88f, 0.35f, 1f), font, out goldText, () => ShowShopModal());

        // 3. Nút Lá Thư lớn (52x52) với Chấm Đỏ thông báo
        CreateProminentMailButton(rightGroupGo.transform, font, () => ShowMailModal());

        // 4. Nút Cài Đặt lớn (48x48)
        CreateIconButton(rightGroupGo.transform, "BtnSettings", "⚙️", new Vector2(48, 48), 24, font, () => ShowSettingsModal());
    }

    private void CreateResourceBadge(Transform parent, string name, string icon, string value, Color valColor, Font font, out Text outText, Action onAddClicked)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.04f, 0.07f, 0.13f, 0.98f);

        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(155f, 44f);

        // Viền badge
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.85f, 0.72f, 0.35f, 0.8f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Text));
        iconGo.transform.SetParent(go.transform, false);
        var iconTxt = iconGo.GetComponent<Text>();
        iconTxt.font = font;
        iconTxt.fontSize = 22;
        iconTxt.alignment = TextAnchor.MiddleCenter;
        iconTxt.text = icon;
        var iRt = iconGo.GetComponent<RectTransform>();
        iRt.anchorMin = iRt.anchorMax = iRt.pivot = new Vector2(0f, 0.5f);
        iRt.sizeDelta = new Vector2(34f, 34f);
        iRt.anchoredPosition = new Vector2(6f, 0f);

        var valGo = new GameObject("Val", typeof(RectTransform), typeof(Text));
        valGo.transform.SetParent(go.transform, false);
        outText = valGo.GetComponent<Text>();
        outText.font = font;
        outText.fontSize = 18;
        outText.fontStyle = FontStyle.Bold;
        outText.alignment = TextAnchor.MiddleLeft;
        outText.color = valColor;
        outText.text = value;
        var vRt = valGo.GetComponent<RectTransform>();
        vRt.anchorMin = new Vector2(0f, 0f);
        vRt.anchorMax = new Vector2(1f, 1f);
        vRt.pivot = new Vector2(0f, 0.5f);
        vRt.offsetMin = new Vector2(42f, 0f);
        vRt.offsetMax = new Vector2(-28f, 0f);

        if (onAddClicked != null)
        {
            var addBtnGo = new GameObject("AddBtn", typeof(RectTransform), typeof(Button), typeof(Text));
            addBtnGo.transform.SetParent(go.transform, false);
            var aTxt = addBtnGo.GetComponent<Text>();
            aTxt.font = font;
            aTxt.fontSize = 20;
            aTxt.fontStyle = FontStyle.Bold;
            aTxt.color = new Color(1f, 0.88f, 0.35f, 1f);
            aTxt.alignment = TextAnchor.MiddleCenter;
            aTxt.text = "+";
            var aRt = addBtnGo.GetComponent<RectTransform>();
            aRt.anchorMin = aRt.anchorMax = aRt.pivot = new Vector2(1f, 0.5f);
            aRt.sizeDelta = new Vector2(24f, 24f);
            aRt.anchoredPosition = new Vector2(-6f, 0f);
            addBtnGo.GetComponent<Button>().onClick.AddListener(() => onAddClicked());
        }
    }

    private void CreateProminentMailButton(Transform parent, Font font, Action onClick)
    {
        var go = new GameObject("BtnMail", typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.18f, 0.24f, 0.38f, 0.98f);

        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = new Vector2(52f, 52f);

        // Viền vàng nút thư
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var txtGo = new GameObject("Icon", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(go.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 26;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.text = "✉️";
        txt.color = Color.white;
        Fill(txtGo.GetComponent<RectTransform>());

        // Chấm đỏ thông báo thư mới
        var redDotGo = new GameObject("RedDot", typeof(RectTransform), typeof(Image));
        redDotGo.transform.SetParent(go.transform, false);
        var rdImg = redDotGo.GetComponent<Image>();
        rdImg.color = new Color(1f, 0.25f, 0.25f, 1f);
        var rdRt = redDotGo.GetComponent<RectTransform>();
        rdRt.anchorMin = rdRt.anchorMax = rdRt.pivot = new Vector2(1f, 1f);
        rdRt.sizeDelta = new Vector2(14f, 14f);
        rdRt.anchoredPosition = new Vector2(-4f, -4f);

        go.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });
    }

    private void CreateIconButton(Transform parent, string name, string icon, Vector2 size, int fontSize, Font font, Action onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.14f, 0.18f, 0.28f, 0.98f);

        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = size;

        // Viền nút
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.85f, 0.72f, 0.35f, 0.85f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var txtGo = new GameObject("Icon", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(go.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = fontSize;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.text = icon;
        txt.color = Color.white;
        Fill(txtGo.GetComponent<RectTransform>());

        go.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });
    }
    #endregion

    #region Center: 3 Grand Game Modes (Vương Triều, Quốc Chiến, Đấu 2v2 Xếp Hạng)
    private void BuildThreeGameModes(Transform parent, Font font)
    {
        var modesContainerGo = new GameObject("ThreeGameModes", typeof(RectTransform));
        modesContainerGo.transform.SetParent(parent, false);
        var mcRt = modesContainerGo.GetComponent<RectTransform>();
        mcRt.anchorMin = new Vector2(0.5f, 0.5f);
        mcRt.anchorMax = new Vector2(0.5f, 0.5f);
        mcRt.pivot = new Vector2(0.5f, 0.5f);
        mcRt.sizeDelta = new Vector2(1220f, 490f);
        mcRt.anchoredPosition = new Vector2(0f, 4f);

        // Nút phụ trên góc phải: Luyện tập với AI lớn (270x44)
        var practiceBtnGo = new GameObject("PracticeBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        practiceBtnGo.transform.SetParent(modesContainerGo.transform, false);
        var pbImg = practiceBtnGo.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { pbImg.sprite = choiceBg; pbImg.type = Image.Type.Sliced; }
        pbImg.color = new Color(0.08f, 0.16f, 0.12f, 0.98f);

        var pbRt = practiceBtnGo.GetComponent<RectTransform>();
        pbRt.anchorMin = pbRt.anchorMax = pbRt.pivot = new Vector2(1f, 1f);
        pbRt.sizeDelta = new Vector2(270f, 44f);
        pbRt.anchoredPosition = new Vector2(-16f, -2f);

        var pbBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        pbBorder.transform.SetParent(practiceBtnGo.transform, false);
        var pbbImg = pbBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { pbbImg.sprite = frameSpr; pbbImg.type = Image.Type.Sliced; }
        pbbImg.color = new Color(0.3f, 0.85f, 0.45f, 0.95f);
        Fill(pbBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var pbTxt = AddText(practiceBtnGo.transform, "Label", "🏹 ĐẤU TẬP VỚI SƠN TẶC (AI)", 16, new Color(0.7f, 1f, 0.8f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(pbTxt.rectTransform);
        AddShadow(pbTxt.gameObject);

        practiceBtnGo.GetComponent<Button>().onClick.AddListener(() => StartPracticeTutorial());

        // 3 THẺ CHẾ ĐỘ CHƠI HOÀNG GIA ĐẶT NGANG NHAU (Lớn 380 x 420, chữ to rõ ràng)
        float cardWidth = 380f;
        float cardHeight = 415f;
        float spacingX = 395f;

        // 1. 👑 VƯƠNG TRIỀU
        CreateMajorModeCard(
            modesContainerGo.transform,
            new Vector2(-spacingX, -22f),
            new Vector2(cardWidth, cardHeight),
            "👑 VƯƠNG TRIỀU",
            "🔥 HOÀNG TỘC TRANH BÁ",
            "Đấu trường cung đình tối cao. Khẳng định tài mưu lược quân thần, tranh đoạt ngọc tỷ và vương miện hoàng triều Đại Việt.",
            "👑 VÀO VƯƠNG TRIỀU ➜",
            new Color(0.95f, 0.65f, 0.15f, 1f),
            new Color(0.18f, 0.12f, 0.05f, 0.98f),
            font,
            () => StartDynastyMode()
        );

        // 2. ⚔️ QUỐC CHIẾN
        CreateMajorModeCard(
            modesContainerGo.transform,
            new Vector2(0f, -22f),
            new Vector2(cardWidth, cardHeight),
            "⚔️ QUỐC CHIẾN",
            "🚩 THẾ LỰC TRANH HÙNG",
            "Bang hội phân tranh lãnh thổ 4 cõi. Chiếm cứ thành trì hiểm yếu, mở rộng non sông gấm vóc và xưng bá thiên hạ.",
            "⚔️ VÀO QUỐC CHIẾN ➜",
            new Color(0.85f, 0.28f, 0.22f, 1f),
            new Color(0.18f, 0.06f, 0.06f, 0.98f),
            font,
            () => StartNationalWarMode()
        );

        // 3. 🛡️ ĐẤU 2v2 XẾP HẠNG
        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);
        CreateMajorModeCard(
            modesContainerGo.transform,
            new Vector2(spacingX, -22f),
            new Vector2(cardWidth, cardHeight),
            "🛡️ ĐẤU 2v2 XẾP HẠNG",
            $"⭐ RANK: {r2v2.badge} {r2v2.name.ToUpper()}",
            $"Hiệp lực đồng đội 2v2 leo bảng phong thần Đại Việt.\n\n<b>Bậc hiện tại:</b> <color={r2v2.ColorHex}>{r2v2.badge} {r2v2.name}</color> ({AuthUI.Current2v2Points} RP)\n<i>(+25 RP khi thắng, -15 RP khi thua)</i>",
            "🛡️ VÀO ĐẤU 2v2 ➜",
            new Color(0.2f, 0.65f, 0.95f, 1f),
            new Color(0.06f, 0.12f, 0.2f, 0.98f),
            font,
            () => ShowRanked2v2Modal()
        );
    }

    private void CreateMajorModeCard(
        Transform parent,
        Vector2 pos,
        Vector2 size,
        string title,
        string tag,
        string desc,
        string btnLabel,
        Color themeColor,
        Color cardBgColor,
        Font font,
        Action onAction)
    {
        var cardGo = new GameObject("Card_" + title, typeof(RectTransform), typeof(Image));
        cardGo.transform.SetParent(parent, false);
        var img = cardGo.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { img.sprite = choiceBg; img.type = Image.Type.Sliced; }
        img.color = cardBgColor;

        var rt = cardGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;

        // Viền hoàng kim phát sáng
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(cardGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = themeColor;
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        // Hào quang hoa sen phát sáng mờ phía trên thẻ
        var haloGo = new GameObject("Halo", typeof(RectTransform), typeof(Image));
        haloGo.transform.SetParent(cardGo.transform, false);
        var hImg = haloGo.GetComponent<Image>();
        var haloSpr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        if (haloSpr != null) hImg.sprite = haloSpr;
        hImg.color = new Color(themeColor.r, themeColor.g, themeColor.b, 0.35f);
        hImg.raycastTarget = false;
        var hRt = haloGo.GetComponent<RectTransform>();
        hRt.anchorMin = hRt.anchorMax = hRt.pivot = new Vector2(0.5f, 0.74f);
        hRt.sizeDelta = new Vector2(240f, 240f);

        // Biểu tượng trung tâm lớn (80pt)
        var iconGo = new GameObject("BigIcon", typeof(RectTransform), typeof(Text));
        iconGo.transform.SetParent(cardGo.transform, false);
        var icTxt = iconGo.GetComponent<Text>();
        icTxt.font = font;
        icTxt.fontSize = 80;
        icTxt.alignment = TextAnchor.MiddleCenter;
        icTxt.text = title.Split(' ')[0]; // lấy icon đầu tiên
        var icRt = iconGo.GetComponent<RectTransform>();
        icRt.anchorMin = icRt.anchorMax = icRt.pivot = new Vector2(0.5f, 0.74f);
        icRt.sizeDelta = new Vector2(110f, 110f);

        // Tag danh hiệu nhỏ lớn (16pt Bold)
        var tagTxt = AddText(cardGo.transform, "Tag", tag, 16, themeColor, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(tagTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 30f, 26f), new Vector2(0, -16));

        // Tiêu đề chế độ lớn (26pt Bold)
        var titleTxt = AddText(cardGo.transform, "Title", title, 26, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 0.46f), new Vector2(0.5f, 0.46f), new Vector2(0.5f, 0.5f), new Vector2(size.x - 30f, 36f), Vector2.zero);
        AddShadow(titleTxt.gameObject);

        // Đường kẻ ngăn cách vàng
        var divGo = new GameObject("Divider", typeof(RectTransform), typeof(Image));
        divGo.transform.SetParent(cardGo.transform, false);
        var divImg = divGo.GetComponent<Image>();
        var divSpr = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        if (divSpr != null) divImg.sprite = divSpr;
        divImg.color = themeColor;
        var dRt = divGo.GetComponent<RectTransform>();
        dRt.anchorMin = dRt.anchorMax = dRt.pivot = new Vector2(0.5f, 0.39f);
        dRt.sizeDelta = new Vector2(240f, 12f);

        // Mô tả chi tiết lớn (18pt, line spacing 1.35)
        var descTxt = AddText(cardGo.transform, "Desc", desc, 18, new Color(0.88f, 0.94f, 1f, 0.98f), FontStyle.Normal, TextAnchor.MiddleCenter);
        descTxt.lineSpacing = 1.35f;
        SetRect(descTxt.rectTransform, new Vector2(0.5f, 0.24f), new Vector2(0.5f, 0.24f), new Vector2(0.5f, 0.5f), new Vector2(size.x - 40f, 75f), Vector2.zero);

        // Nút hành động lớn bên dưới (330 x 54, chữ 22pt Bold)
        var btnGo = new GameObject("ActionBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(cardGo.transform, false);
        var bImage = btnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { bImage.sprite = btnSpr; bImage.type = Image.Type.Sliced; }
        bImage.color = themeColor;

        var bRt = btnGo.GetComponent<RectTransform>();
        bRt.anchorMin = bRt.anchorMax = bRt.pivot = new Vector2(0.5f, 0f);
        bRt.sizeDelta = new Vector2(size.x - 50f, 54f);
        bRt.anchoredPosition = new Vector2(0f, 20f);

        var btnBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        btnBorder.transform.SetParent(btnGo.transform, false);
        var bnbImg = btnBorder.GetComponent<Image>();
        if (frameSpr != null) { bnbImg.sprite = frameSpr; bnbImg.type = Image.Type.Sliced; }
        bnbImg.color = new Color(1f, 0.95f, 0.6f, 0.95f);
        Fill(btnBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var btnText = AddText(btnGo.transform, "Label", btnLabel, 22, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(btnText.rectTransform);
        AddShadow(btnText.gameObject);

        btnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onAction?.Invoke();
        });
    }
    #endregion

    #region Bottom Navigation Bar
    private void BuildBottomNavBar(Transform parent, Font font)
    {
        var navGo = new GameObject("BottomNav", typeof(RectTransform), typeof(Image));
        navGo.transform.SetParent(parent, false);
        var nImg = navGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { nImg.sprite = slotSpr; nImg.type = Image.Type.Sliced; }
        nImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);

        var nRt = navGo.GetComponent<RectTransform>();
        nRt.anchorMin = new Vector2(0f, 0f);
        nRt.anchorMax = new Vector2(1f, 0f);
        nRt.pivot = new Vector2(0.5f, 0f);
        nRt.sizeDelta = new Vector2(0f, 70f);
        nRt.anchoredPosition = Vector2.zero;

        // Viền vàng trên thanh Bottom Nav
        var lineGo = new GameObject("GoldLine", typeof(RectTransform), typeof(Image));
        lineGo.transform.SetParent(navGo.transform, false);
        var lineImg = lineGo.GetComponent<Image>();
        lineImg.color = new Color(0.92f, 0.78f, 0.32f, 0.95f);
        var lRt = lineGo.GetComponent<RectTransform>();
        lRt.anchorMin = new Vector2(0f, 1f);
        lRt.anchorMax = new Vector2(1f, 1f);
        lRt.pivot = new Vector2(0.5f, 1f);
        lRt.sizeDelta = new Vector2(0f, 3f);
        lRt.anchoredPosition = Vector2.zero;

        var hlgGo = new GameObject("ButtonsHlg", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        hlgGo.transform.SetParent(navGo.transform, false);
        Fill(hlgGo.GetComponent<RectTransform>(), new Vector2(20, 6), new Vector2(-20, -6));
        var hlg = hlgGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 16f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = true;
        hlg.childControlHeight = true;
        hlg.childForceExpandWidth = true;
        hlg.childForceExpandHeight = true;

        CreateNavButton(hlgGo.transform, "NavHome", "🏠", "TRANG CHỦ", true, font, () => { });
        CreateNavButton(hlgGo.transform, "NavHeroes", "🎖️", "TƯỚNG LĨNH", false, font, () => ShowHeroDetailModal());
        CreateNavButton(hlgGo.transform, "NavInventory", "🎒", "BINH KHÍ KHỐ", false, font, () => ShowInventoryModal());
        CreateNavButton(hlgGo.transform, "NavQuest", "📜", "NHIỆM VỤ", false, font, () => ShowQuestModal());
        CreateNavButton(hlgGo.transform, "NavRanking", "🏆", "BẢNG VÀNG", false, font, () => ShowLeaderboardModal());
        CreateNavButton(hlgGo.transform, "NavShop", "🛒", "TRÂN BẢO CÁC", false, font, () => ShowShopModal());
    }

    private void CreateNavButton(Transform parent, string name, string icon, string label, bool isActive, Font font, Action onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { img.sprite = choiceBg; img.type = Image.Type.Sliced; }
        img.color = isActive ? new Color(0.24f, 0.18f, 0.06f, 0.98f) : new Color(0.08f, 0.12f, 0.2f, 0.85f);

        var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(go.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 18;
        txt.fontStyle = FontStyle.Bold;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.color = isActive ? new Color(1f, 0.88f, 0.35f, 1f) : new Color(0.85f, 0.90f, 0.98f, 0.95f);
        txt.text = $"{icon} {label}";
        Fill(txtGo.GetComponent<RectTransform>());
        AddShadow(txtGo);

        if (isActive)
        {
            var haloGo = new GameObject("ActiveGlow", typeof(RectTransform), typeof(Image));
            haloGo.transform.SetParent(go.transform, false);
            haloGo.transform.SetAsFirstSibling();
            var hImg = haloGo.GetComponent<Image>();
            var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (frameSpr != null) { hImg.sprite = frameSpr; hImg.type = Image.Type.Sliced; }
            hImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
            Fill(haloGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));
        }

        go.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });
    }
    #endregion


    #region Action Handlers & Game Modes
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

    private void StartRanked2v2Mode()
    {
        ShowRanked2v2Modal();
    }

    private void ShowRanked2v2Modal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🛡️ ĐẤU TRƯỜNG 2v2 XẾP HẠNG", new Vector2(1060f, 650f), font);

        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);
        var nextTier = Ranked2v2System.GetNextTier(AuthUI.Current2v2Points);
        float progress = Ranked2v2System.GetProgress(AuthUI.Current2v2Points);

        // --- CỘT TRÁI (410px): BẬC RANK HIỆN TẠI & NÚT TÌM TRẬN ---
        var leftCol = new GameObject("LeftCol", typeof(RectTransform));
        leftCol.transform.SetParent(box.transform, false);
        var lcRt = leftCol.GetComponent<RectTransform>();
        lcRt.anchorMin = new Vector2(0f, 0f);
        lcRt.anchorMax = new Vector2(0.40f, 1f);
        lcRt.offsetMin = new Vector2(25f, 25f);
        lcRt.offsetMax = new Vector2(0f, -65f);

        // Card Rank Hiện Tại
        var rankCard = new GameObject("RankCard", typeof(RectTransform), typeof(Image));
        rankCard.transform.SetParent(leftCol.transform, false);
        var rcImg = rankCard.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { rcImg.sprite = choiceBg; rcImg.type = Image.Type.Sliced; }
        rcImg.color = new Color(0.08f, 0.14f, 0.24f, 0.98f);
        var rcRt = rankCard.GetComponent<RectTransform>();
        SetRect(rcRt, new Vector2(0f, 0.18f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

        // Viền hoàng kim
        var rcBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        rcBorder.transform.SetParent(rankCard.transform, false);
        var rcbImg = rcBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { rcbImg.sprite = frameSpr; rcbImg.type = Image.Type.Sliced; }
        rcbImg.color = r2v2.color;
        Fill(rcBorder.GetComponent<RectTransform>(), new Vector2(-3, -3), new Vector2(3, 3));

        // Huy hiệu lớn (76pt)
        var badgeTxt = ThemeUI.CreateText(rankCard.transform, "Badge", r2v2.badge, 76, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(badgeTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(180f, 85f), new Vector2(0f, -8f));

        // Tên Rank lớn (34pt Bold)
        var nameTxt = ThemeUI.CreateText(rankCard.transform, "Name", r2v2.name, 34, r2v2.color, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(nameTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(380f, 42f), new Vector2(0f, -95f));

        // Subtitle & Điểm lớn (26pt Bold)
        var subTxt = ThemeUI.CreateText(rankCard.transform, "Sub", $"<b>{r2v2.subtitle}</b> • <color=#FFD700>{AuthUI.Current2v2Points} RP</color>", 26, new Color(0.9f, 0.94f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
        SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(380f, 36f), new Vector2(0f, -140f));

        // Thanh tiến độ Rank 2v2
        var barBg = new GameObject("BarBg", typeof(RectTransform), typeof(Image));
        barBg.transform.SetParent(rankCard.transform, false);
        var bbImg = barBg.GetComponent<Image>();
        bbImg.color = new Color(0.04f, 0.07f, 0.12f, 0.95f);
        var bbRt = barBg.GetComponent<RectTransform>();
        SetRect(bbRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(320f, 20f), new Vector2(0f, -182f));

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
        var progTxt = ThemeUI.CreateText(rankCard.transform, "ProgTxt", progLabel, 22, new Color(1f, 1f, 1f, 0.95f), FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(progTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(350f, 28f), new Vector2(0f, -210f));

        // Mô tả bậc lớn (22pt Italic)
        var descTxt = ThemeUI.CreateText(rankCard.transform, "Desc", r2v2.description, 22, new Color(0.85f, 0.92f, 1f, 0.95f), FontStyle.Italic, TextAnchor.MiddleCenter, true);
        descTxt.lineSpacing = 1.3f;
        SetRect(descTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(360f, 85f), new Vector2(0f, 15f));

        // Nút Tìm Trận Ghép Đội 2v2 lớn (360 x 66, chữ 26pt Bold)
        var matchBtnGo = new GameObject("MatchmakingBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        matchBtnGo.transform.SetParent(leftCol.transform, false);
        var mbImg = matchBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { mbImg.sprite = btnSpr; mbImg.type = Image.Type.Sliced; }
        mbImg.color = new Color(0.95f, 0.72f, 0.18f, 1.0f);
        var mbRt = matchBtnGo.GetComponent<RectTransform>();
        SetRect(mbRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(360f, 66f), new Vector2(0f, 6f));

        // Viền phát sáng cho nút Tìm trận
        var mbBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        mbBorder.transform.SetParent(matchBtnGo.transform, false);
        var mbbImg = mbBorder.GetComponent<Image>();
        if (frameSpr != null) { mbbImg.sprite = frameSpr; mbbImg.type = Image.Type.Sliced; }
        mbbImg.color = new Color(1f, 0.92f, 0.45f, 0.95f);
        mbbImg.raycastTarget = false;
        Fill(mbBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var mbTxt = ThemeUI.CreateText(matchBtnGo.transform, "Label", "⚔️ BẮT ĐẦU TÌM TRẬN 2v2", 26, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(mbTxt.rectTransform);

        matchBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            StartCoroutine(SimulateMatchmaking(mbTxt, matchBtnGo.GetComponent<Button>()));
        });

        // --- CỘT PHẢI (580px): BẢNG LỘ TRÌNH 12 BẬC RANK 2v2 ---
        var rightCol = new GameObject("RightCol", typeof(RectTransform));
        rightCol.transform.SetParent(box.transform, false);
        var rrcRt = rightCol.GetComponent<RectTransform>();
        rrcRt.anchorMin = new Vector2(0.40f, 0f);
        rrcRt.anchorMax = new Vector2(1f, 1f);
        rrcRt.offsetMin = new Vector2(20f, 20f);
        rrcRt.offsetMax = new Vector2(-25f, -65f);

        var rTitle = ThemeUI.CreateText(rightCol.transform, "Title", "🏆 LỘ TRÌNH 12 BẬC RANK 2v2 ĐỒNG ĐỘI", 28, new Color(0.55f, 0.85f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, true);
        SetRect(rTitle.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(0f, 34f), new Vector2(5f, -2f));

        // Grid of 12 tiers (Row Height 40px, Spacing 2px)
        float startY = -40f;
        float rowH = 40f;
        float spacing = 2f;

        for (int i = Ranked2v2System.Tiers.Length - 1; i >= 0; i--)
        {
            var tier = Ranked2v2System.Tiers[i];
            int displayIdx = 11 - i;
            float rowY = startY - displayIdx * (rowH + spacing);

            var rowGo = new GameObject("TierRow_" + i, typeof(RectTransform), typeof(Image));
            rowGo.transform.SetParent(rightCol.transform, false);
            var rowImg = rowGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
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
                cbImg.color = new Color(1f, 0.88f, 0.35f, 1f);
                Fill(curBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));
            }

            // Badge & Name (22pt Bold)
            string currentTag = isCurrent ? " <color=#FFD700>[BẬC BẠN]</color>" : "";
            var rowName = ThemeUI.CreateText(rowGo.transform, "Name", $"{tier.badge} <color={tier.ColorHex}>{tier.name}</color>{currentTag}", 22, Color.white, isCurrent ? FontStyle.Bold : FontStyle.Normal, TextAnchor.MiddleLeft, true);
            SetRect(rowName.rectTransform, new Vector2(0f, 0f), new Vector2(0.68f, 1f), new Vector2(0f, 0.5f), Vector2.zero, Vector2.zero);
            rowName.rectTransform.offsetMin = new Vector2(14f, 0f);

            // Points Range (20pt Bold)
            string ptRange = tier.tierIndex >= 12 ? $"{tier.minPoints}+ RP" : $"{tier.minPoints} - {tier.maxPoints} RP";
            var rowPts = ThemeUI.CreateText(rowGo.transform, "Pts", ptRange, 20, isCurrent ? new Color(1f, 0.88f, 0.35f, 1f) : new Color(0.75f, 0.85f, 0.95f, 0.9f), FontStyle.Normal, TextAnchor.MiddleRight, true);
            SetRect(rowPts.rectTransform, new Vector2(0.68f, 0f), new Vector2(1f, 1f), new Vector2(1f, 0.5f), Vector2.zero, Vector2.zero);
            rowPts.rectTransform.offsetMax = new Vector2(-14f, 0f);
        }
    }

    private IEnumerator SimulateMatchmaking(Text btnText, Button btn)
    {
        if (currentActiveModal != null) Destroy(currentActiveModal);
        yield return StartAppwriteMatchmakingFlow();
    }

    private IEnumerator StartAppwriteMatchmakingFlow()
    {
        string myUserId = !string.IsNullOrWhiteSpace(AuthUI.CurrentUserEmail) ? AuthUI.CurrentUserEmail : ("guest_" + SystemInfo.deviceUniqueIdentifier.Substring(0, 8));
        string myUserName = !string.IsNullOrWhiteSpace(AuthUI.CurrentUserName) ? AuthUI.CurrentUserName : "Đại Tướng Quân";
        int myRankPoints = AuthUI.Current2v2Points;
        var font = ThemeUI.FontMain;

        // Tạo Modal Tìm Trận Lớn, Sang Trọng (680 x 530)
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

        // Viền Hoàng Kim
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(boxGo.transform, false);
        var borImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        // Tiêu Đề lớn (24pt Bold)
        var titleTxt = ThemeUI.CreateText(boxGo.transform, "Title", "⚔️ ĐANG TÌM TRẬN ĐẤU XẾP HẠNG 2v2", 24, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, true);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(620f, 40f), new Vector2(0f, -16f));

        // Đồng Hồ Đếm Thời Gian Tăng Dần lớn (200x44, chữ 26pt)
        var timerBoxGo = new GameObject("TimerBox", typeof(RectTransform), typeof(Image));
        timerBoxGo.transform.SetParent(boxGo.transform, false);
        var tbImg = timerBoxGo.GetComponent<Image>();
        tbImg.color = new Color(0.04f, 0.08f, 0.16f, 0.95f);
        var tbRt = timerBoxGo.GetComponent<RectTransform>();
        SetRect(tbRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(200f, 44f), new Vector2(0f, -58f));

        var tbBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        tbBorder.transform.SetParent(timerBoxGo.transform, false);
        var tbbImg = tbBorder.GetComponent<Image>();
        if (frameSpr != null) { tbbImg.sprite = frameSpr; tbbImg.type = Image.Type.Sliced; }
        tbbImg.color = new Color(1f, 0.85f, 0.35f, 0.75f);
        Fill(tbBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var timerTxt = ThemeUI.CreateText(timerBoxGo.transform, "TimerTxt", "⏳ 0s", 26, new Color(1f, 0.82f, 0.2f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(timerTxt.rectTransform);

        // Trạng Thái Tìm Kiếm lớn (20pt Bold)
        var statusTxt = ThemeUI.CreateText(boxGo.transform, "StatusTxt", "🌐 Đang quét tìm các phòng đấu có sẵn trên máy chủ...", 20, new Color(0.6f, 0.88f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
        SetRect(statusTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(620f, 30f), new Vector2(0f, -108f));

        // Khung 4 Ghế Người Chơi (Spacious: Height 52px each, chữ 20pt)
        var slotsContainer = new GameObject("Slots", typeof(RectTransform));
        slotsContainer.transform.SetParent(boxGo.transform, false);
        var scRt = slotsContainer.GetComponent<RectTransform>();
        SetRect(scRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(620f, 240f), new Vector2(0f, -15f));

        Image[] slotImgs = new Image[4];
        Text[] slotTexts = new Text[4];

        for (int i = 0; i < 4; i++)
        {
            var sGo = new GameObject("Slot_" + (i + 1), typeof(RectTransform), typeof(Image));
            sGo.transform.SetParent(slotsContainer.transform, false);
            var sImg = sGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { sImg.sprite = slotSpr; sImg.type = Image.Type.Sliced; }
            sImg.color = new Color(0.05f, 0.09f, 0.18f, 0.95f);
            slotImgs[i] = sImg;

            var sRt = sGo.GetComponent<RectTransform>();
            float yPos = 85f - (i * 56f);
            SetRect(sRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(600f, 50f), new Vector2(0f, yPos));

            var sBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
            sBorder.transform.SetParent(sGo.transform, false);
            var sbImg = sBorder.GetComponent<Image>();
            if (frameSpr != null) { sbImg.sprite = frameSpr; sbImg.type = Image.Type.Sliced; }
            sbImg.color = new Color(0.4f, 0.6f, 0.85f, 0.45f);
            Fill(sBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

            var sTxt = ThemeUI.CreateText(sGo.transform, "Txt", $"⏳ Đang chờ người chơi ghế #{i + 1}...", 20, new Color(0.7f, 0.8f, 0.95f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft, true);
            Fill(sTxt.rectTransform);
            sTxt.rectTransform.offsetMin = new Vector2(18f, 0f);
            slotTexts[i] = sTxt;
        }

        // Nút Hủy Tìm Trận lớn (280 x 52, chữ 22pt)
        bool cancelled = false;
        string activeRoomId = "";
        bool isHost = false;

        var cancelBtnGo = new GameObject("CancelBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        cancelBtnGo.transform.SetParent(boxGo.transform, false);
        var cbImg = cancelBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { cbImg.sprite = btnSpr; cbImg.type = Image.Type.Sliced; }
        cbImg.color = new Color(0.88f, 0.25f, 0.22f, 1f);
        var cbRt = cancelBtnGo.GetComponent<RectTransform>();
        SetRect(cbRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(280f, 52f), new Vector2(0f, 18f));

        var cbBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        cbBorder.transform.SetParent(cancelBtnGo.transform, false);
        var cbbImg = cbBorder.GetComponent<Image>();
        if (frameSpr != null) { cbbImg.sprite = frameSpr; cbbImg.type = Image.Type.Sliced; }
        cbbImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(cbBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var cbTxt = ThemeUI.CreateText(cancelBtnGo.transform, "Txt", "❌ HỦY TÌM TRẬN", 22, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(cbTxt.rectTransform);

        cancelBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            cancelled = true;
            if (!string.IsNullOrEmpty(activeRoomId))
            {
                if (isHost)
                {
                    StartCoroutine(AppwriteMatchmaking.DeleteRoom(activeRoomId));
                }
                else
                {
                    StartCoroutine(AppwriteMatchmaking.LeaveRoomSlot(activeRoomId, myUserId));
                }
            }
            if (currentActiveModal != null) Destroy(currentActiveModal);
        });

        // ═══════════════════════════════════════════════════════════════
        // LUỒNG TÌM TRẬN: TÌM PHÒNG CÓ SẴN -> ƯU TIÊN RANK -> VÀO SLOT / TỰ TẠO PHÒNG
        // ═══════════════════════════════════════════════════════════════
        float realElapsedTimer = 0f;
        AppwriteMatchmaking.RoomStatePacket currentRoom = null;

        // Bước 1: Quét tìm phòng còn slot gần điểm rank nhất
        yield return AppwriteMatchmaking.FindBestWaitingRoom(myUserId, myRankPoints, (found) =>
        {
            currentRoom = found;
        });

        if (cancelled) yield break;

        // Retry 1 lần sau 1.5s để tránh race condition (2 nick bấm tìm cùng lúc) hoặc Appwrite delay
        if (currentRoom == null)
        {
            yield return new WaitForSecondsRealtime(1.5f);
            if (!cancelled)
            {
                yield return AppwriteMatchmaking.FindBestWaitingRoom(myUserId, myRankPoints, (found) =>
                {
                    currentRoom = found;
                });
            }
        }

        if (cancelled) yield break;

        if (currentRoom != null)
        {
            // ─── GUEST: THAM GIA VÀO PHÒNG CÓ SẴN ───
            isHost = false;
            activeRoomId = currentRoom.roomId;
            statusTxt.text = $"⚔️ <color=#55FF55>ĐÃ TÌM THẤY PHÒNG ĐẤU!</color> Đang tham gia...";

            bool joinSuccess = false;
            yield return AppwriteMatchmaking.JoinRoomSlot(currentRoom, myUserId, myUserName, myRankPoints, (joined) =>
            {
                if (joined != null)
                {
                    currentRoom = joined;
                    joinSuccess = true;
                }
            });

            if (cancelled) yield break;

            if (!joinSuccess)
            {
                // Nếu Join thất bại (phòng vừa bị người khác chiếm slot) -> Chuyển sang làm Host
                statusTxt.text = "⚠️ Phòng vừa đủ người. Đang tự khởi tạo phòng mới...";
                currentRoom = null;
            }
            else
            {
                // Vòng lặp lắng nghe của Guest
                float guestWaitTimer = 0f;
                while (!cancelled)
                {
                    realElapsedTimer += 0.5f;
                    guestWaitTimer += 0.5f;
                    timerTxt.text = $"⏳ {Mathf.FloorToInt(realElapsedTimer)}s";

                    yield return AppwriteMatchmaking.PollRoomState(activeRoomId, (latestRoom) =>
                    {
                        if (latestRoom != null)
                        {
                            currentRoom = latestRoom;
                            guestWaitTimer = 0f; // Nhận được cập nhật -> Reset wait timer
                        }
                    });

                    if (currentRoom != null)
                    {
                        UpdateMatchmakingSlotsVisual(currentRoom, myUserId, slotImgs, slotTexts);

                        if (currentRoom.status == "STARTED")
                        {
                            statusTxt.text = "⚔️ <color=#55FF55>ĐÃ KẾT NỐI ĐỦ 4 CHIẾN TƯỚNG!</color> Bắt đầu chọn tướng...";
                            timerTxt.text = "⚔️ SẴN SÀNG!";
                            timerTxt.color = new Color(0.4f, 1f, 0.4f, 1f);
                            break;
                        }
                    }
                    else if (guestWaitTimer > 15.0f)
                    {
                        // Quá 15s không nhận được tín hiệu từ Chủ phòng -> Thông báo và thoát
                        statusTxt.text = "❌ <color=#FF5555>Mất kết nối với Chủ Phòng!</color>";
                        yield return new WaitForSecondsRealtime(2.0f);
                        if (currentActiveModal != null) Destroy(currentActiveModal);
                        yield break;
                    }

                    yield return new WaitForSecondsRealtime(0.5f);
                }
            }
        }

        if (currentRoom == null && !cancelled)
        {
            // ─── HOST: TỰ TẠO PHÒNG MỚI LÀM CHỦ PHÒNG ───
            isHost = true;
            int hostSeed = AppwriteMatchmaking.GetDeterministicHashCode(myUserId + "_" + DateTimeOffset.UtcNow.ToUnixTimeMilliseconds());
            activeRoomId = "room_" + hostSeed.ToString("X8");
            currentRoom = new AppwriteMatchmaking.RoomStatePacket
            {
                roomId = activeRoomId,
                hostUserId = myUserId,
                hostRankPoints = myRankPoints,
                status = "WAITING",
                version = 1
            };

            // Slot 1: Host (Phe Rồng)
            // Slot 2: Empty (Phe Phượng - Đối thủ)
            // Slot 3: Empty (Phe Rồng - Đồng đội)
            // Slot 4: Empty (Phe Phượng - Đối thủ 2)
            currentRoom.slots.Add(new AppwriteMatchmaking.RoomSlotData { seatNumber = 1, userId = myUserId, userName = myUserName, rankPoints = myRankPoints, isDragon = true, isAI = false });
            currentRoom.slots.Add(new AppwriteMatchmaking.RoomSlotData { seatNumber = 2, userId = "empty", userName = "", rankPoints = 0, isDragon = false, isAI = false });
            currentRoom.slots.Add(new AppwriteMatchmaking.RoomSlotData { seatNumber = 3, userId = "empty", userName = "", rankPoints = 0, isDragon = true, isAI = false });
            currentRoom.slots.Add(new AppwriteMatchmaking.RoomSlotData { seatNumber = 4, userId = "empty", userName = "", rankPoints = 0, isDragon = false, isAI = false });

            bool roomCreated = false;
            yield return AppwriteMatchmaking.CreateWaitingRoom(currentRoom, (ok) => roomCreated = ok);

            if (cancelled) yield break;

            if (!roomCreated)
            {
                statusTxt.text = "❌ <color=#FF5555>Lỗi kết nối máy chủ khi tạo phòng. Vui lòng thử lại!</color>";
                yield return new WaitForSecondsRealtime(2.0f);
                if (currentActiveModal != null) Destroy(currentActiveModal);
                yield break;
            }

            statusTxt.text = "👑 Bạn là Chủ Phòng. Đang đợi các chiến tướng khác tham gia...";
            UpdateMatchmakingSlotsVisual(currentRoom, myUserId, slotImgs, slotTexts);

            float hostHiddenTimer = 15.0f; // Đếm lùi ngầm 15 giây
            int lastRealPlayerCount = 1;
            float heartbeatTimer = 0f;

            while (!cancelled)
            {
                realElapsedTimer += 0.5f;
                hostHiddenTimer -= 0.5f;
                heartbeatTimer += 0.5f;
                timerTxt.text = $"⏳ {Mathf.FloorToInt(realElapsedTimer)}s";

                // Gửi heartbeat định kỳ mỗi 4.0 giây
                if (heartbeatTimer >= 4.0f)
                {
                    heartbeatTimer = 0f;
                    if (currentRoom != null) StartCoroutine(AppwriteMatchmaking.SendHostHeartbeat(currentRoom));
                }

                // Poll cập nhật phòng
                yield return AppwriteMatchmaking.PollRoomState(activeRoomId, (latestRoom) =>
                {
                    if (latestRoom != null) currentRoom = latestRoom;
                });

                if (currentRoom != null)
                {
                    // Đếm số người thật hiện có trong phòng
                    int currentRealCount = 0;
                    foreach (var s in currentRoom.slots)
                    {
                        if (!s.isEmpty && !s.isAI) currentRealCount++;
                    }

                    // NẾU CHỈ CÓ MỘT MÌNH HOST (chưa có ai vào) -> Thử quét xem có phòng nào khác để gộp vào không!
                    if (currentRealCount == 1 && realElapsedTimer >= 1.5f && Mathf.FloorToInt(realElapsedTimer) % 2 == 0)
                    {
                        AppwriteMatchmaking.RoomStatePacket otherRoom = null;
                        yield return AppwriteMatchmaking.FindBestWaitingRoom(myUserId, myRankPoints, (fRoom) => { otherRoom = fRoom; });

                        if (otherRoom != null && otherRoom.roomId != activeRoomId && otherRoom.status == "WAITING")
                        {
                            // Tìm thấy phòng khác -> Hủy phòng trống hiện tại và vào phòng đó làm Guest!
                            StartCoroutine(AppwriteMatchmaking.DeleteRoom(activeRoomId));
                            activeRoomId = otherRoom.roomId;
                            isHost = false;
                            statusTxt.text = $"⚔️ <color=#55FF55>ĐÃ TÌM THẤY PHÒNG ĐẤU!</color> Đang tham gia...";

                            bool mergeSuccess = false;
                            yield return AppwriteMatchmaking.JoinRoomSlot(otherRoom, myUserId, myUserName, myRankPoints, (joined) =>
                            {
                                if (joined != null) { currentRoom = joined; mergeSuccess = true; }
                            });

                            if (mergeSuccess)
                            {
                                // Chuyển hẳn sang luồng chờ của Guest
                                float gWaitTimer = 0f;
                                while (!cancelled)
                                {
                                    realElapsedTimer += 0.5f;
                                    gWaitTimer += 0.5f;
                                    timerTxt.text = $"⏳ {Mathf.FloorToInt(realElapsedTimer)}s";

                                    yield return AppwriteMatchmaking.PollRoomState(activeRoomId, (lRoom) =>
                                    {
                                        if (lRoom != null) { currentRoom = lRoom; gWaitTimer = 0f; }
                                    });

                                    if (currentRoom != null)
                                    {
                                        UpdateMatchmakingSlotsVisual(currentRoom, myUserId, slotImgs, slotTexts);
                                        if (currentRoom.status == "STARTED")
                                        {
                                            statusTxt.text = "⚔️ <color=#55FF55>ĐÃ KẾT NỐI ĐỦ 4 CHIẾN TƯỚNG!</color> Bắt đầu chọn tướng...";
                                            timerTxt.text = "⚔️ SẴN SÀNG!";
                                            timerTxt.color = new Color(0.4f, 1f, 0.4f, 1f);
                                            break;
                                        }
                                    }
                                    else if (gWaitTimer > 15.0f)
                                    {
                                        statusTxt.text = "❌ <color=#FF5555>Mất kết nối với Chủ Phòng!</color>";
                                        yield return new WaitForSecondsRealtime(2.0f);
                                        if (currentActiveModal != null) Destroy(currentActiveModal);
                                        yield break;
                                    }
                                    yield return new WaitForSecondsRealtime(0.5f);
                                }
                                break;
                            }
                        }
                    }

                    // NẾU CÓ NGƯỜI THẬT MỚI VÀO -> TÍNH LẠI 15S NGẦM TỪ ĐẦU!
                    if (currentRealCount > lastRealPlayerCount)
                    {
                        hostHiddenTimer = 15.0f; // Reset ngầm lại 15s!
                        lastRealPlayerCount = currentRealCount;
                        statusTxt.text = $"⚔️ <color=#55FF55>Có thêm người chơi thực tham gia!</color> Đang đợi tiếp...";
                    }

                    UpdateMatchmakingSlotsVisual(currentRoom, myUserId, slotImgs, slotTexts);

                    // Đủ 4 người thật HOẶC hết 15s ngầm -> Bắt đầu vào chọn tướng
                    if (currentRealCount >= 4 || hostHiddenTimer <= 0f)
                    {
                        // Quét lại snapshot mới nhất tuyệt đối từ máy chủ trước khi chốt danh sách
                        yield return AppwriteMatchmaking.PollRoomState(activeRoomId, (fresh) =>
                        {
                            if (fresh != null) currentRoom = fresh;
                        });

                        // Điền AI / Bot vào các slot còn trống
                        var usedNames = new HashSet<string> { myUserName };
                        foreach (var s in currentRoom.slots)
                        {
                            if (!s.isEmpty && !string.IsNullOrEmpty(s.userName)) usedNames.Add(s.userName);
                        }

                        int botSeedBase = AppwriteMatchmaking.GetDeterministicHashCode(activeRoomId);
                        for (int i = 0; i < currentRoom.slots.Count; i++)
                        {
                            var s = currentRoom.slots[i];
                            if (s.isEmpty)
                            {
                                s.userId = "bot_" + Guid.NewGuid().ToString("N").Substring(0, 6);
                                s.userName = AppwriteMatchmaking.GetRealisticGamerName(botSeedBase + i * 17, usedNames);
                                s.rankPoints = Mathf.Max(20, myRankPoints + UnityEngine.Random.Range(-15, 16));
                                s.isAI = true;
                            }
                        }

                        // Xáo trộn ngẫu nhiên thứ tự ghế 1..4 bằng Deterministic Hash Code
                        int roomSeed = AppwriteMatchmaking.GetDeterministicHashCode(activeRoomId);
                        CardDeckManager.ShuffleList(currentRoom.slots, roomSeed);
                        for (int i = 0; i < currentRoom.slots.Count; i++)
                        {
                            currentRoom.slots[i].seatNumber = i + 1;
                        }

                        currentRoom.status = "STARTED";
                        yield return AppwriteMatchmaking.UpdateRoomState(currentRoom);

                        statusTxt.text = "⚔️ <color=#55FF55>ĐÃ KẾT NỐI ĐỦ 4 CHIẾN TƯỚNG!</color> Bắt đầu chọn tướng...";
                        timerTxt.text = "⚔️ SẴN SÀNG!";
                        timerTxt.color = new Color(0.4f, 1f, 0.4f, 1f);
                        UpdateMatchmakingSlotsVisual(currentRoom, myUserId, slotImgs, slotTexts);
                        break;
                    }
                }

                yield return new WaitForSecondsRealtime(0.5f);
            }
        }

        if (cancelled) yield break;

        yield return new WaitForSecondsRealtime(1.5f);

        if (currentActiveModal != null) Destroy(currentActiveModal);
        Hide();

        // Chuyển đổi danh sách slot sang MatchmakingSlotInfo cho Battle2v2UI
        var matchedSlots = new List<Battle2v2UI.MatchmakingSlotInfo>();
        var mySlotInRoom = currentRoom.slots.Find(s => s.userId == myUserId);
        bool myIsDragon = mySlotInRoom != null ? mySlotInRoom.isDragon : true;

        foreach (var s in currentRoom.slots)
        {
            bool isMe = (s.userId == myUserId);
            bool isMyAlly = (s.isDragon == myIsDragon);
            matchedSlots.Add(new Battle2v2UI.MatchmakingSlotInfo
            {
                seatNumber = s.seatNumber,
                userId = s.userId,
                playerName = s.userName,
                isPlayer = isMe,
                isAlly = isMyAlly,
                isDragon = s.isDragon,
                isAI = s.isAI,
                rankPoints = s.rankPoints
            });
        }

        matchedSlots.Sort((a, b) => a.seatNumber.CompareTo(b.seatNumber));
        Battle2v2UI.CreateWithSlots(matchedSlots, activeRoomId, isHost, null, () => { Show(); });
    }

    private void UpdateMatchmakingSlotsVisual(AppwriteMatchmaking.RoomStatePacket room, string myUserId, Image[] slotImgs, Text[] slotTexts)
    {
        if (room == null || room.slots == null) return;
        for (int i = 0; i < 4 && i < room.slots.Count; i++)
        {
            var s = room.slots[i];
            if (s.isEmpty)
            {
                slotTexts[i].text = $"⏳ Đang tìm {(s.isDragon ? "đồng đội Phe Rồng" : "đối thủ Phe Phượng")}...";
                slotTexts[i].color = new Color(0.65f, 0.75f, 0.9f, 1f);
                slotImgs[i].color = new Color(0.05f, 0.09f, 0.18f, 0.95f);
            }
            else
            {
                bool isMe = (s.userId == myUserId);
                string factionName = s.isDragon ? "PHE RỒNG" : "PHE PHƯỢNG";
                string roleTag = isMe ? " <color=#FFD700>[BẠN]</color>" : (s.isAI ? " [AI]" : "");
                slotTexts[i].text = $"👤 <b>{s.userName}</b>{roleTag} • <color={(s.isDragon ? "#55DDFF" : "#FF6666")}>{factionName}</color> ({s.rankPoints} RP) ✅";

                if (isMe)
                {
                    slotTexts[i].color = new Color(0.95f, 0.98f, 1f, 1f);
                    slotImgs[i].color = new Color(0.14f, 0.32f, 0.52f, 0.98f);
                }
                else if (s.isDragon)
                {
                    slotTexts[i].color = new Color(0.85f, 0.95f, 1f, 1f);
                    slotImgs[i].color = new Color(0.08f, 0.22f, 0.38f, 0.95f);
                }
                else
                {
                    slotTexts[i].color = new Color(1f, 0.85f, 0.85f, 1f);
                    slotImgs[i].color = new Color(0.38f, 0.12f, 0.12f, 0.95f);
                }
            }
        }
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
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = size;
        boxRt.anchoredPosition = Vector2.zero;

        // Viền vàng phát sáng
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(boxGo.transform, false);
        var borImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        // Header Title lớn (26pt Bold)
        var titleTxt = AddText(boxGo.transform, "Title", title, 26, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 90f, 42f), new Vector2(0, -14));
        AddShadow(titleTxt.gameObject);

        // Nút đóng [X] lớn (40x40)
        var closeBtnGo = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        closeBtnGo.transform.SetParent(boxGo.transform, false);
        var cImg = closeBtnGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { cImg.sprite = slotSpr; cImg.type = Image.Type.Sliced; }
        cImg.color = new Color(0.7f, 0.18f, 0.18f, 0.98f);

        var cRt = closeBtnGo.GetComponent<RectTransform>();
        cRt.anchorMin = cRt.anchorMax = cRt.pivot = new Vector2(1f, 1f);
        cRt.sizeDelta = new Vector2(40f, 40f);
        cRt.anchoredPosition = new Vector2(-12f, -12f);

        var cBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        cBorder.transform.SetParent(closeBtnGo.transform, false);
        var cbImg = cBorder.GetComponent<Image>();
        if (frameSpr != null) { cbImg.sprite = frameSpr; cbImg.type = Image.Type.Sliced; }
        cbImg.color = new Color(1f, 0.85f, 0.35f, 0.85f);
        Fill(cBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var xTxt = AddText(closeBtnGo.transform, "X", "✕", 20, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(xTxt.rectTransform);
        closeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            Destroy(modalRoot);
        });

        return boxGo;
    }


    private void ShowHeroDetailModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🎖️ THÔNG TIN DANH TƯỚNG ĐẠI VIỆT", new Vector2(840f, 520f), font);

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
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(avBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // Thông tin bên phải lớn (18pt, line spacing 1.4)
        var infoGo = new GameObject("InfoPanel", typeof(RectTransform), typeof(Text));
        infoGo.transform.SetParent(box.transform, false);
        var infoTxt = infoGo.GetComponent<Text>();
        infoTxt.font = font;
        infoTxt.fontSize = 18;
        infoTxt.color = new Color(0.92f, 0.95f, 1f, 1f);
        infoTxt.lineSpacing = 1.4f;

        var milTier = MilitaryRankSystem.GetTier(AuthUI.CurrentMilitaryPoints);
        var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        infoTxt.text =
            $"<b>Tướng Sở Hữu:</b> <color=#FFD700>{hero.name.ToUpper()}</color>\n" +
            "<b>Trạng thái Appwrite:</b> <color=#55FF55>Đã mở khóa & Đồng bộ thành công</color>\n" +
            $"<b>Quân Hàm Toàn Cục:</b> <color={milTier.ColorHex}>{milTier.badge} {milTier.name}</color> ({AuthUI.CurrentMilitaryPoints}đ • {milTier.subtitle})\n" +
            $"<b>Xếp Hạng 2v2:</b> <color={r2v2.ColorHex}>{r2v2.badge} {r2v2.name}</color> ({AuthUI.Current2v2Points} RP • {r2v2.subtitle})\n" +
            $"<b>Máu:</b> <color=#FF5555>{hero.maxHp} Đóa Sen</color>  |  <b>Phe phái:</b> <color=#55FF55>{hero.faction}</color>\n\n" +
            $"<b>⚡ Tuyệt Kỹ [{hero.skillName.ToUpper()}]:</b>\n" +
            $"{hero.skillDesc}";

        var iRt = infoGo.GetComponent<RectTransform>();
        SetRect(iRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        iRt.offsetMin = new Vector2(295f, 30f);
        iRt.offsetMax = new Vector2(-28f, -65f);
    }

    private void ShowInventoryModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🎒 BINH KHÍ KHỐ (TÚI ĐỒ & TRANG BỊ)", new Vector2(840f, 540f), font);

        var subTxt = AddText(box.transform, "Sub", "Danh sách các trang bị và bảo vật đã mở khóa trong kho:", 18, new Color(0.88f, 0.94f, 1f, 0.95f), FontStyle.Normal, TextAnchor.MiddleLeft);
        SetRect(subTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-60f, 26f), new Vector2(35f, -60f));

        var items = new[]
        {
            ("UI/icon_weapon", "♠2 Song Cung Mường Nhạ", "Vũ Khí (Tầm 2)\nKhi Trảm bị Đỡ, có thể bỏ 2 lá bài ép mục tiêu mất 1 máu."),
            ("UI/icon_weapon", "♠A Kiếm Thuận Thiên", "Vũ Khí (Tầm 2)\nThanh kiếm thần tích tụ linh khí ngàn năm."),
            ("UI/icon_armor", "♠2 Giáp Đồng Sơn Vi", "Giáp Phòng Thủ\nVô hiệu hóa hoàn toàn mọi đòn Trảm Thường không thuộc tính."),
            ("UI/icon_armor", "♣2 Khiên Mây Bện", "Giáp Phòng Thủ\nLật phán xét Đỏ để vô hiệu hóa Mưa Tên & Bãi Cọc."),
            ("UI/icon_mount_offense", "♦K Xích Thố (-1)", "Ngựa Tấn Công\nGiảm cự ly khi tấn công kẻ địch đi 1 khoảng cách."),
            ("UI/icon_mount_defense", "♥K Phi Lực (+1)", "Ngựa Phòng Thủ\nTăng cự ly kẻ địch nhắm vào bản thân thêm 1 khoảng cách.")
        };

        float startY = -95f;
        for (int i = 0; i < items.Length; i++)
        {
            var it = items[i];
            float colX = (i % 2 == 0) ? -195f : 195f;
            float rowY = startY - (i / 2) * 125f;

            var cardGo = new GameObject("ItemCard_" + i, typeof(RectTransform), typeof(Image));
            cardGo.transform.SetParent(box.transform, false);
            var cImg = cardGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { cImg.sprite = slotSpr; cImg.type = Image.Type.Sliced; }
            cImg.color = new Color(0.05f, 0.08f, 0.16f, 0.95f);

            var cRt = cardGo.GetComponent<RectTransform>();
            cRt.anchorMin = cRt.anchorMax = cRt.pivot = new Vector2(0.5f, 1f);
            cRt.sizeDelta = new Vector2(370f, 112f);
            cRt.anchoredPosition = new Vector2(colX, rowY);

            // Viền card
            var cBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
            cBorder.transform.SetParent(cardGo.transform, false);
            var cbImg = cBorder.GetComponent<Image>();
            var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (frameSpr != null) { cbImg.sprite = frameSpr; cbImg.type = Image.Type.Sliced; }
            cbImg.color = new Color(0.4f, 0.6f, 0.85f, 0.45f);
            Fill(cBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

            // Icon lớn (56x56)
            var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Image));
            iconGo.transform.SetParent(cardGo.transform, false);
            var icImg = iconGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources(it.Item1);
            if (spr != null) icImg.sprite = spr;
            icImg.preserveAspect = true;
            var icRt = iconGo.GetComponent<RectTransform>();
            icRt.anchorMin = icRt.anchorMax = icRt.pivot = new Vector2(0f, 0.5f);
            icRt.sizeDelta = new Vector2(56f, 56f);
            icRt.anchoredPosition = new Vector2(12f, 0f);

            // Tên lớn (18pt Bold)
            var nTxt = AddText(cardGo.transform, "Name", it.Item2, 18, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft);
            SetRect(nTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-80f, 26f), new Vector2(76f, -8f));

            // Mô tả lớn (15pt)
            var dTxt = AddText(cardGo.transform, "Desc", it.Item3, 15, new Color(0.85f, 0.92f, 1f, 0.95f), FontStyle.Normal, TextAnchor.MiddleLeft);
            dTxt.lineSpacing = 1.25f;
            SetRect(dTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0f, 0f), new Vector2(-80f, -36f), new Vector2(76f, 8f));
        }
    }

    private void ShowQuestModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("📜 NHIỆM VỤ CHIẾN TƯỚNG", new Vector2(760f, 480f), font);

        var questTxt = AddText(box.transform, "Content",
            "<b>Nhiệm Vụ Hàng Ngày:</b>\n\n" +
            "✅ <b>Khai Môn Tân Thủ:</b> Hoàn tất hướng dẫn cơ bản. (<color=#55FF55>Đã hoàn thành</color> - 1.000 Bạc & Tướng Lý Thường Kiệt)\n\n" +
            "⏳ <b>Bách Chiến Bách Thắng:</b> Tham gia 3 trận đấu luyện tập với AI. (Tiến độ: 1/3)\n\n" +
            "⏳ <b>Thần Xạ Thủ:</b> Kích hoạt thành công kỹ năng Song Cung Mường Nhạ 1 lần. (Tiến độ: 0/1)\n\n" +
            "⏳ <b>Tuyệt Kỹ Biến Ảo:</b> Dùng kỹ năng [Tiến Thoái] 2 lần trong một ván đấu. (Tiến độ: 0/2)",
            18, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft);
        questTxt.lineSpacing = 1.4f;
        SetRect(questTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        questTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        questTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private int currentLeaderboardTab = 0; // 0 = Military Rank, 1 = 2v2 Rank

    private void ShowLeaderboardModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🏆 BẢNG VÀNG QUÂN CÔNG & XẾP HẠNG (12 BẬC)", new Vector2(820f, 540f), font);

        // Tab Switcher
        var tabContainer = new GameObject("TabContainer", typeof(RectTransform));
        tabContainer.transform.SetParent(box.transform, false);
        var tcRt = tabContainer.GetComponent<RectTransform>();
        SetRect(tcRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(740f, 44f), new Vector2(0f, -58f));

        var tabMilBtn = CreateTabButton(tabContainer.transform, "TabMil", "🎖️ BẢNG QUÂN CÔNG TOÀN QUỐC", new Vector2(-185f, 0f), currentLeaderboardTab == 0, font, () =>
        {
            currentLeaderboardTab = 0;
            ShowLeaderboardModal();
        });

        var tab2v2Btn = CreateTabButton(tabContainer.transform, "Tab2v2", "🛡️ BẢNG XẾP HẠNG 2v2 ĐỒNG ĐỘI", new Vector2(185f, 0f), currentLeaderboardTab == 1, font, () =>
        {
            currentLeaderboardTab = 1;
            ShowLeaderboardModal();
        });

        // Content Area
        var contentGo = new GameObject("ContentArea", typeof(RectTransform));
        contentGo.transform.SetParent(box.transform, false);
        var caRt = contentGo.GetComponent<RectTransform>();
        SetRect(caRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        caRt.offsetMin = new Vector2(40f, 25f);
        caRt.offsetMax = new Vector2(-40f, -112f);

        string userName = string.IsNullOrEmpty(AuthUI.CurrentUserName) ? "Lý Thường Kiệt" : AuthUI.CurrentUserName;

        if (currentLeaderboardTab == 0)
        {
            var milTier = MilitaryRankSystem.GetTier(AuthUI.CurrentMilitaryPoints);
            var leadTxt = AddText(contentGo.transform, "Content",
                "<b>BẢNG VINH DANH QUÂN CÔNG ĐẠI VIỆT (12 BẬC QUÂN HÀM):</b>\n\n" +
                "🥇 <b>1. Hưng Đạo Đại Vương</b> — 9.999đ Quân Công  [🔥 Đại Nguyên Soái • Bậc 12/12]\n" +
                "🥈 <b>2. Bình Định Vương</b> — 8.850đ Quân Công  [🔥 Đại Nguyên Soái • Bậc 12/12]\n" +
                "🥉 <b>3. Quang Trung Hoàng Đế</b> — 7.950đ Quân Công  [🦅 Đại Tướng Quân • Bậc 11/12]\n" +
                "   <b>4. Lý Thường Kiệt</b> — 6.400đ Quân Công  [👑 Trung Tướng • Bậc 10/12]\n" +
                "   <b>5. Triệu Quang Phục</b> — 5.100đ Quân Công  [🌟 Thiếu Tướng • Bậc 9/12]\n\n" +
                $"⭐ <b>VỊ TRÍ CỦA BẠN:</b> <color=#FFD700>{userName}</color> — <b>{AuthUI.CurrentMilitaryPoints}đ Quân Công</b>  [{milTier.badge} {milTier.name} • {milTier.subtitle}]",
                17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.UpperLeft);
            leadTxt.lineSpacing = 1.4f;
            Fill(leadTxt.rectTransform);
        }
        else
        {
            var r2v2 = Ranked2v2System.GetTier(AuthUI.Current2v2Points);
            var leadTxt = AddText(contentGo.transform, "Content",
                "<b>BẢNG PHONG THẦN XẾP HẠNG 2v2 ĐỒNG ĐỘI (12 BẬC RANK):</b>\n\n" +
                "🥇 <b>1. Cặp Đôi Long Vân: Hưng Đạo & Dã Tượng</b> — 8.800 RP  [🌌 Thần Thoại Quân Vương • Bậc 12/12]\n" +
                "🥈 <b>2. Song Hào Kiệt: Quang Trung & Ngô Thì Nhậm</b> — 6.500 RP  [🌌 Thần Thoại Quân Vương • Bậc 12/12]\n" +
                "🥉 <b>3. Thiết Giáp Vệ: Hai Bà Trưng</b> — 5.400 RP  [⚡ Vô Song Hào Kiệt • Bậc 11/12]\n" +
                "   <b>4. Tương Trợ Song Sư: Trần Khánh Dư & Yết Kiêu</b> — 4.600 RP  [👑 Vương Giả • Bậc 10/12]\n" +
                "   <b>5. Hùng Sư Trấn Quốc: Đinh Bộ Lĩnh & Đinh Điền</b> — 3.800 RP  [🏆 Hùng Sư • Bậc 9/12]\n\n" +
                $"⭐ <b>VỊ TRÍ CỦA BẠN:</b> <color=#55FF55>{userName}</color> — <b>{AuthUI.Current2v2Points} RP</b>  [{r2v2.badge} {r2v2.name} • {r2v2.subtitle}]",
                17, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.UpperLeft);
            leadTxt.lineSpacing = 1.4f;
            Fill(leadTxt.rectTransform);
        }
    }

    private GameObject CreateTabButton(Transform parent, string name, string label, Vector2 pos, bool active, Font font, Action onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = active ? new Color(0.24f, 0.18f, 0.06f, 0.98f) : new Color(0.07f, 0.1f, 0.18f, 0.85f);

        var rt = go.GetComponent<RectTransform>();
        SetRect(rt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(350f, 42f), pos);

        if (active)
        {
            var bGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
            bGo.transform.SetParent(go.transform, false);
            var bImg = bGo.GetComponent<Image>();
            var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
            bImg.color = new Color(1f, 0.88f, 0.35f, 1f);
            Fill(bGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));
        }

        var tGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        tGo.transform.SetParent(go.transform, false);
        var txt = tGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 17;
        txt.fontStyle = FontStyle.Bold;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.color = active ? new Color(1f, 0.88f, 0.35f, 1f) : new Color(0.80f, 0.88f, 0.96f, 0.88f);
        txt.text = label;
        Fill(tGo.GetComponent<RectTransform>());
        AddShadow(tGo);

        go.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });

        return go;
    }

    private void ShowShopModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("🛒 TRÂN BẢO CÁC (CỬA HÀNG)", new Vector2(760f, 480f), font);

        var shopTxt = AddText(box.transform, "Content",
            "<b>TRÂN BẢO CÁC ĐẠI VIỆT CHIẾN:</b>\n\n" +
            "🪙 <b>Túi 500 Bạc:</b> Đổi bằng 50 Vàng.\n" +
            "🪙 <b>Rương 2.000 Bạc:</b> Đổi bằng 180 Vàng.\n" +
            "🎁 <b>Gói Tướng Tân Thủ:</b> Sở hữu trọn bộ thẻ tướng & trang bị độc quyền.\n\n" +
            "<i>(Tính năng giao thương đang tiếp tục được cập nhật ở phiên bản tiếp theo!)</i>",
            18, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft);
        shopTxt.lineSpacing = 1.45f;
        SetRect(shopTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        shopTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        shopTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private void ShowMailModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("✉️ THƯ TÍN QUÂN ĐOÀN", new Vector2(760f, 480f), font);

        var mailTxt = AddText(box.transform, "Content",
            "<b>HÒM THƯ QUÂN ĐOÀN ĐẠI VIỆT:</b>\n\n" +
            "📩 <b>[Quà Khai Môn Tân Thủ]:</b> Chúc mừng chiến tướng đã gia nhập Đại Việt Chiến! Phần thưởng <b>1.000 Bạc</b> và <b>Tướng Lý Thường Kiệt</b> đã được đồng bộ trực tiếp vào tài khoản Appwrite của bạn.\n\n" +
            "📩 <b>[Hịch Tướng Sĩ]:</b> Sẵn sàng tham gia 3 đại chiến trường: <b>Vương Triều</b>, <b>Quốc Chiến</b> và <b>Đấu 2v2 Xếp Hạng</b>!",
            18, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft);
        mailTxt.lineSpacing = 1.4f;
        SetRect(mailTxt.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);
        mailTxt.rectTransform.offsetMin = new Vector2(40f, 30f);
        mailTxt.rectTransform.offsetMax = new Vector2(-40f, -65f);
    }

    private void ShowSettingsModal()
    {
        var font = ThemeUI.FontMain;
        var box = CreateBaseModal("⚙️ CÀI ĐẶT TRÒ CHƠI", new Vector2(640f, 400f), font);

        var desc = AddText(box.transform, "Desc", "Âm thanh & Tùy chọn tài khoản:", 18, new Color(0.88f, 0.94f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleLeft);
        SetRect(desc.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(540, 30), new Vector2(0, -70));

        // Nút Đăng Xuất lớn (280 x 52, chữ 20pt Bold)
        var logoutBtnGo = new GameObject("LogoutBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        logoutBtnGo.transform.SetParent(box.transform, false);
        var lImg = logoutBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { lImg.sprite = btnSpr; lImg.type = Image.Type.Sliced; }
        lImg.color = new Color(0.88f, 0.25f, 0.18f, 1f);

        var lRt = logoutBtnGo.GetComponent<RectTransform>();
        lRt.anchorMin = lRt.anchorMax = lRt.pivot = new Vector2(0.5f, 0f);
        lRt.sizeDelta = new Vector2(280f, 52f);
        lRt.anchoredPosition = new Vector2(0f, 35f);

        var lBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        lBorder.transform.SetParent(logoutBtnGo.transform, false);
        var lbImg = lBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { lbImg.sprite = frameSpr; lbImg.type = Image.Type.Sliced; }
        lbImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(lBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var lTxt = AddText(logoutBtnGo.transform, "Label", "🚪 ĐĂNG XUẤT", 20, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(lTxt.rectTransform);
        AddShadow(lTxt.gameObject);

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

        var cTxt = AddText(box.transform, "Content", content, 18, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        cTxt.lineSpacing = 1.4f;
        SetRect(cTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(640, 140), new Vector2(0, 18));

        var actBtnGo = new GameObject("ConfirmBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        actBtnGo.transform.SetParent(box.transform, false);
        var aImg = actBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { aImg.sprite = btnSpr; aImg.type = Image.Type.Sliced; }
        aImg.color = new Color(0.88f, 0.48f, 0.12f, 1f);

        var aRt = actBtnGo.GetComponent<RectTransform>();
        aRt.anchorMin = aRt.anchorMax = aRt.pivot = new Vector2(0.5f, 0f);
        aRt.sizeDelta = new Vector2(300f, 52f);
        aRt.anchoredPosition = new Vector2(0f, 26f);

        var aBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        aBorder.transform.SetParent(actBtnGo.transform, false);
        var abImg = aBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { abImg.sprite = frameSpr; abImg.type = Image.Type.Sliced; }
        abImg.color = new Color(1f, 0.88f, 0.35f, 0.95f);
        Fill(aBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var aTxt = AddText(actBtnGo.transform, "Label", actionLabel, 20, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(aTxt.rectTransform);
        AddShadow(aTxt.gameObject);

        actBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (currentActiveModal != null) Destroy(currentActiveModal);
            onConfirm?.Invoke();
        });
    }
    #endregion


    #region UI Helper Utilities
    private static Text AddText(Transform parent, string name, string text, int fontSize, Color color, FontStyle style, TextAnchor align)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Text));
        go.transform.SetParent(parent, false);
        var t = go.GetComponent<Text>();
        t.font = ThemeUI.FontMain;
        t.fontSize = fontSize;
        t.color = color;
        t.fontStyle = style;
        t.alignment = align;
        t.text = text;
        t.raycastTarget = false;
        return t;
    }

    private static void AddShadow(GameObject go)
    {
        var shadow = go.AddComponent<Shadow>();
        shadow.effectColor = new Color(0f, 0f, 0f, 0.95f);
        shadow.effectDistance = new Vector2(1f, -1f);
    }

    private static void Fill(RectTransform rt, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.offsetMin = offsetMin;
        rt.offsetMax = offsetMax;
    }

    private static void SetRect(RectTransform rt, Vector2 min, Vector2 max, Vector2 pivot, Vector2 size, Vector2 pos)
    {
        rt.anchorMin = min;
        rt.anchorMax = max;
        rt.pivot = pivot;
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;
    }
    #endregion
}
