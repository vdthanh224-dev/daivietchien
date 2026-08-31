using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.Networking;
using UnityEngine.UI;

/// <summary>
/// Giao diện Đăng nhập / Đăng ký và Câu hỏi Tân thủ phong cách Đại Việt Chiến.
/// - Thiết kế sơn mài cổ trang hoàng kim
/// - Tab chuyển đổi mượt mà giữa Đăng Nhập và Đăng Ký
/// - Modal Tân Thủ 2 lựa chọn trực quan: Tân Thủ Nhập Môn & Kỳ Cựu Xuất Thế
/// </summary>
public sealed class AuthUI : MonoBehaviour
{
    private const string Endpoint = "https://sgp.cloud.appwrite.io/v1";
    private const string ProjectId = "6a885457002da3f3d47e";
    private const string RecoveryUrl = "https://localhost/reset-password";

    private CanvasScaler scaler;
    private RectTransform authCardRt;
    private GameObject brandRoot;
    private GameObject authCardRoot;
    private GameObject onboardingModalRoot;

    // Tabs & Form Fields
    private Button tabLoginBtn, tabRegisterBtn;
    private Image tabLoginLine, tabRegisterLine;
    private Text tabLoginText, tabRegisterText;

    private GameObject nameGroup, emailGroup, passwordGroup;
    private InputField nameInput, emailInput, passwordInput;
    private Button submitButton, forgotButton;
    private Text submitButtonText, messageText;

    private bool registerMode = false;
    private string signedInEmail;
    private string sessionCookie;
    private string sessionSecret;
    private bool activeSessionError;
    private bool restoringSession;

    public static AuthUI Instance { get; private set; }

    public static string CurrentUserName = "Đại Tướng Quân";
    public static string CurrentUserEmail = "";
    public static List<string> CurrentUserLabels = new List<string>();
    public static bool IsAdmin => CurrentUserLabels != null && CurrentUserLabels.Exists(l => l.Equals("admin", StringComparison.OrdinalIgnoreCase));
    public static int CurrentSilver = 0;
    public static int CurrentGold = 0;
    public static int CurrentLevel = 1;
    public static int CurrentExp = 0;
    public static int CurrentMilitaryPoints = 0; // Điểm Quân Công (Rank Toàn Cục 12 Bậc - 0đ)
    public static int Current2v2Points = 0;      // Điểm Xếp Hạng 2v2 (Rank 2v2 12 Bậc - 0 RP)
    public static string CurrentGenerals = "ly_thuong_kiet";
    public static bool IsRewardClaimed = false;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void Bootstrap()
    {
        if (FindFirstObjectByType<AuthUI>() != null) return;
        var root = new GameObject("AuthenticationUI");
        DontDestroyOnLoad(root);
        root.AddComponent<AuthUI>();
    }

    private void Awake()
    {
        Application.runInBackground = true;
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    
    private void Update()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_WIN
        if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha1)) QuickLogin(1);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha2)) QuickLogin(2);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha3)) QuickLogin(3);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha4)) QuickLogin(4);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha5)) QuickLogin(5);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha6)) QuickLogin(6);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha7)) QuickLogin(7);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha8)) QuickLogin(8);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha9)) QuickLogin(9);
#endif
    }

    private void QuickLogin(int num)
    {
        if (emailInput != null) emailInput.text = "vdthanh22" + num + "@gmail.com";
        if (passwordInput != null) passwordInput.text = "matkhau123";
        SetRegisterMode(false);
        Submit();
    }

    private void Start()
    {
        EnsureEventSystem();
        sessionCookie = PlayerPrefs.GetString("auth_session_cookie", "");
        sessionSecret = PlayerPrefs.GetString("auth_session_secret", "");
        signedInEmail = PlayerPrefs.GetString("auth_last_email", "");
        CurrentUserName = PlayerPrefs.GetString("auth_user_name", "Đại Tướng Quân");
        CurrentMilitaryPoints = PlayerPrefs.GetInt("auth_military_points", 0);
        Current2v2Points = PlayerPrefs.GetInt("auth_rank2v2_points", 0);
        BuildUI();
        StartCoroutine(RestoreSession());
    }

    private void BuildUI()
    {
        Screen.orientation = ScreenOrientation.LandscapeRight;
        Screen.autorotateToPortrait = false;
        Screen.autorotateToPortraitUpsideDown = false;
        Screen.autorotateToLandscapeLeft = true;
        Screen.autorotateToLandscapeRight = true;

        var canvasGo = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        canvasGo.transform.SetParent(transform, false);
        var canvas = canvasGo.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        scaler = canvasGo.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1280, 720);
        scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
        scaler.matchWidthOrHeight = 0.5f;

        // 1. Hình nền & Lớp phủ đọc tốt
        var bg = AddRawImage(canvasGo.transform, "Background", new Color(0.08f, 0.1f, 0.15f, 1f));
        bg.raycastTarget = false;
        Fill(bg.rectTransform);
        var bgTex = Resources.Load<Texture2D>("UI/login_background");
        if (bgTex != null) bgImg(bg, bgTex);

        var shade = AddImage(canvasGo.transform, "ReadabilityShade", new Color(0.02f, 0.04f, 0.08f, 0.65f));
        shade.raycastTarget = false;
        Fill(shade.rectTransform);

        // 2. Cột thương hiệu bên trái (Brand Column)
        BuildBrandColumn(canvasGo.transform);

        // 3. Khung Đăng nhập / Đăng ký bên phải (Auth Card)
        BuildAuthCard(canvasGo.transform);

        // Áp dụng trạng thái ban đầu
        SetRegisterMode(false);
    }

    private void bgImg(RawImage img, Texture2D tex)
    {
        img.texture = tex;
        img.color = new Color(0.85f, 0.85f, 0.9f, 1f);
    }

    private void BuildBrandColumn(Transform parent)
    {
        brandRoot = new GameObject("Brand");
        brandRoot.transform.SetParent(parent, false);
        var rt = brandRoot.AddComponent<RectTransform>();
        SetRect(rt, new Vector2(0.24f, 0.5f), new Vector2(0.24f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(430, 520), Vector2.zero);

        // Tấm nền mờ phía sau Brand
        var plate = AddImage(brandRoot.transform, "BrandPlate", new Color(0.04f, 0.06f, 0.1f, 0.85f));
        var cardBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (cardBgSprite != null) { plate.sprite = cardBgSprite; plate.type = Image.Type.Sliced; }
        SetRect(plate.rectTransform, Center(), Center(), Center(), new Vector2(410, 490), Vector2.zero);

        // Khung viền hoàng kim
        var border = AddImage(brandRoot.transform, "Border", Color.white);
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { border.sprite = frameSpr; border.type = Image.Type.Sliced; }
        border.color = new Color(1f, 0.85f, 0.35f, 0.9f);
        SetRect(border.rectTransform, Center(), Center(), Center(), new Vector2(416, 496), Vector2.zero);

        // Emblem Trống Đồng / Avatar lớn (120x120)
        var emblem = AddRawImage(brandRoot.transform, "Emblem", Color.white);
        SetRect(emblem.rectTransform, new Vector2(0.5f, 0.77f), new Vector2(0.5f, 0.77f), Center(), new Vector2(120, 120), Vector2.zero);
        var emblemTex = Resources.Load<Texture2D>("UI/game_avatar");
        if (emblemTex != null) emblem.texture = emblemTex;

        // Tiêu đề game hoàng kim lớn (48pt)
        var logo = AddText(brandRoot.transform, "Logo", "ĐẠI VIỆT CHIẾN", 48, GameTheme.GoldBright, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(logo.rectTransform, new Vector2(0.5f, 0.53f), new Vector2(0.5f, 0.53f), Center(), new Vector2(390, 52), Vector2.zero);
        AddTextShadow(logo);

        // Divider vàng
        var divider = AddImage(brandRoot.transform, "Divider", Color.white);
        var divSprite = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        if (divSprite != null) divider.sprite = divSprite;
        SetRect(divider.rectTransform, new Vector2(0.5f, 0.44f), new Vector2(0.5f, 0.44f), Center(), new Vector2(290, 16), Vector2.zero);

        // Khẩu hiệu lớn (24pt)
        var tagline = AddText(brandRoot.transform, "Tagline", "THAO LƯỢC TRANH HÙNG", 24, new Color(1f, 0.95f, 0.8f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(tagline.rectTransform, new Vector2(0.5f, 0.36f), new Vector2(0.5f, 0.36f), Center(), new Vector2(390, 30), Vector2.zero);
        AddTextShadow(tagline);

        // Mô tả lớn (20pt, line spacing rộng rãi)
        var description = AddText(brandRoot.transform, "Description", "Mỗi lá bài, một tương lai.\nBảo vệ non sông, kiến tạo đại nghiệp.", 20, new Color(0.85f, 0.90f, 0.98f, 0.98f), FontStyle.Normal, TextAnchor.MiddleCenter);
        description.lineSpacing = 1.35f;
        SetRect(description.rectTransform, new Vector2(0.5f, 0.19f), new Vector2(0.5f, 0.19f), Center(), new Vector2(380, 56), Vector2.zero);
    }

    private void BuildAuthCard(Transform parent)
    {
        authCardRoot = new GameObject("AuthCard");
        authCardRoot.transform.SetParent(parent, false);
        authCardRt = authCardRoot.AddComponent<RectTransform>();
        SetRect(authCardRt, new Vector2(0.72f, 0.5f), new Vector2(0.72f, 0.5f), Center(), new Vector2(520, 590), Vector2.zero);

        var cardBg = authCardRoot.AddComponent<Image>();
        var cardBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (cardBgSprite != null)
        {
            cardBg.sprite = cardBgSprite;
            cardBg.type = Image.Type.Sliced;
        }
        cardBg.color = Color.white;

        // Khung viền vàng Auth Card
        var borderGo = new GameObject("OuterBorder", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(authCardRoot.transform, false);
        borderGo.transform.SetAsFirstSibling();
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var font = ThemeUI.FontMain;

        // 1. Tab Bar: [ ĐĂNG NHẬP ] | [ ĐĂNG KÝ ] (Cỡ chữ 26pt to rõ)
        var tabBarGo = new GameObject("TabBar", typeof(RectTransform));
        tabBarGo.transform.SetParent(authCardRoot.transform, false);
        var tabRt = tabBarGo.GetComponent<RectTransform>();
        SetRect(tabRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(460, 56), new Vector2(0, -18));

        tabLoginBtn = CreateTabButton(tabBarGo.transform, "TabLogin", "ĐĂNG NHẬP", new Vector2(-115, 0), out tabLoginText, out tabLoginLine, font, () => SetRegisterMode(false));
        tabRegisterBtn = CreateTabButton(tabBarGo.transform, "TabRegister", "ĐĂNG KÝ", new Vector2(115, 0), out tabRegisterText, out tabRegisterLine, font, () => SetRegisterMode(true));

        // 2. Input Fields (Rộng rãi 440px x 74px)
        float startY = -90f;
        float spacingY = 78f;

        nameGroup = CreateInputFieldGroup(authCardRoot.transform, "NameGroup", "TÊN CHIẾN TƯỚNG", "Nhập tên hiển thị của bạn...", "UI/icon_input_user", new Vector2(0, startY), font, false, out nameInput);
        emailGroup = CreateInputFieldGroup(authCardRoot.transform, "EmailGroup", "ĐỊA CHỈ EMAIL", "you@example.com", "UI/icon_input_mail", new Vector2(0, startY - spacingY), font, false, out emailInput);
        passwordGroup = CreateInputFieldGroup(authCardRoot.transform, "PasswordGroup", "MẬT THƯ (MẬT KHẨU)", "Nhập mật khẩu (tối thiểu 8 ký tự)...", "UI/icon_input_lock", new Vector2(0, startY - 2 * spacingY), font, true, out passwordInput);

        // 3. Nút Đăng nhập / Đăng ký chính (Golden Button lớn 440x56, chữ 26pt)
        var submitBtnGo = new GameObject("SubmitButton", typeof(RectTransform), typeof(Image), typeof(Button));
        submitBtnGo.transform.SetParent(authCardRoot.transform, false);
        var submitImg = submitBtnGo.GetComponent<Image>();
        var btnGoldSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnGoldSprite != null)
        {
            submitImg.sprite = btnGoldSprite;
            submitImg.type = Image.Type.Sliced;
        }
        else submitImg.color = GameTheme.Gold;

        submitButton = submitBtnGo.GetComponent<Button>();
        submitButton.onClick.AddListener(Submit);
        var subRt = submitBtnGo.GetComponent<RectTransform>();
        SetRect(subRt, Center(), Center(), Center(), new Vector2(440, 56), new Vector2(0, -115));

        // Viền nút Submit
        var subBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        subBorder.transform.SetParent(submitBtnGo.transform, false);
        var sbbImg = subBorder.GetComponent<Image>();
        if (frameSpr != null) { sbbImg.sprite = frameSpr; sbbImg.type = Image.Type.Sliced; }
        sbbImg.color = new Color(1f, 0.92f, 0.45f, 0.95f);
        sbbImg.raycastTarget = false;
        Fill(subBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var subTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        subTxtGo.transform.SetParent(submitBtnGo.transform, false);
        submitButtonText = subTxtGo.GetComponent<Text>();
        submitButtonText.font = font;
        submitButtonText.fontSize = 26;
        submitButtonText.fontStyle = FontStyle.Bold;
        submitButtonText.text = "XÁC NHẬN ĐĂNG NHẬP";
        submitButtonText.color = new Color(0.10f, 0.06f, 0.02f, 1f);
        submitButtonText.alignment = TextAnchor.MiddleCenter;
        Fill(subTxtGo.GetComponent<RectTransform>());
        AddShadow(subTxtGo);

        // 4. Link phụ: Quên mật khẩu (20pt)
        forgotButton = AddButton(authCardRoot.transform, "Quên mật thư?", Color.clear, true);
        forgotButton.onClick.AddListener(TriggerForgotPassword);
        var fbTxt = forgotButton.GetComponentInChildren<Text>();
        if (fbTxt != null) { fbTxt.fontSize = 20; fbTxt.color = new Color(0.55f, 0.85f, 1f, 1f); }
        SetRect(forgotButton.GetComponent<RectTransform>(), Center(), Center(), Center(), new Vector2(440, 30), new Vector2(0, -162));

        // 5. Dòng thông báo / Lỗi (20pt)
        var msgGo = new GameObject("MessageText", typeof(RectTransform), typeof(Text));
        msgGo.transform.SetParent(authCardRoot.transform, false);
        messageText = msgGo.GetComponent<Text>();
        messageText.font = font;
        messageText.fontSize = 20;
        messageText.fontStyle = FontStyle.Bold;
        messageText.alignment = TextAnchor.MiddleCenter;
        messageText.horizontalOverflow = HorizontalWrapMode.Wrap;
        messageText.color = GameTheme.GoldBright;
        var msgRt = msgGo.GetComponent<RectTransform>();
        SetRect(msgRt, Center(), Center(), Center(), new Vector2(460, 44), new Vector2(0, -205));
    }

    private Button CreateTabButton(Transform parent, string name, string label, Vector2 pos, out Text outText, out Image outLine, Font font, UnityEngine.Events.UnityAction onClick)
    {
        var go = new GameObject(name, typeof(RectTransform), typeof(Button));
        go.transform.SetParent(parent, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 0.5f);
        rt.anchorMax = new Vector2(0.5f, 0.5f);
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(210, 48);
        rt.anchoredPosition = pos;

        var btn = go.GetComponent<Button>();
        btn.onClick.AddListener(onClick);

        var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(go.transform, false);
        outText = txtGo.GetComponent<Text>();
        outText.font = font;
        outText.fontSize = 26;
        outText.fontStyle = FontStyle.Bold;
        outText.text = label;
        outText.alignment = TextAnchor.MiddleCenter;
        outText.color = GameTheme.Muted;
        Fill(txtGo.GetComponent<RectTransform>());
        AddShadow(txtGo);

        var lineGo = new GameObject("ActiveLine", typeof(RectTransform), typeof(Image));
        lineGo.transform.SetParent(go.transform, false);
        outLine = lineGo.GetComponent<Image>();
        outLine.color = GameTheme.GoldBright;
        var lineRt = lineGo.GetComponent<RectTransform>();
        lineRt.anchorMin = new Vector2(0.1f, 0f);
        lineRt.anchorMax = new Vector2(0.9f, 0f);
        lineRt.pivot = new Vector2(0.5f, 0f);
        lineRt.sizeDelta = new Vector2(0, 4);
        lineRt.anchoredPosition = Vector2.zero;

        return btn;
    }

    private GameObject CreateInputFieldGroup(Transform parent, string groupName, string labelStr, string placeholderStr, string iconPath, Vector2 pos, Font font, bool isPassword, out InputField outInput)
    {
        var group = new GameObject(groupName, typeof(RectTransform));
        group.transform.SetParent(parent, false);
        var grpRt = group.GetComponent<RectTransform>();
        grpRt.anchorMin = new Vector2(0.5f, 1f);
        grpRt.anchorMax = new Vector2(0.5f, 1f);
        grpRt.pivot = new Vector2(0.5f, 1f);
        grpRt.sizeDelta = new Vector2(440, 74);
        grpRt.anchoredPosition = pos;

        // Label lớn, sắc nét (20pt Bold)
        var lblGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        lblGo.transform.SetParent(group.transform, false);
        var lbl = lblGo.GetComponent<Text>();
        lbl.font = font;
        lbl.fontSize = 20;
        lbl.fontStyle = FontStyle.Bold;
        lbl.text = labelStr;
        lbl.color = new Color(1f, 0.88f, 0.45f, 1f);
        var lblRt = lblGo.GetComponent<RectTransform>();
        lblRt.anchorMin = new Vector2(0, 1);
        lblRt.anchorMax = new Vector2(1, 1);
        lblRt.pivot = new Vector2(0, 1);
        lblRt.sizeDelta = new Vector2(0, 22);
        lblRt.anchoredPosition = new Vector2(6, 0);
        AddShadow(lblGo);

        // Input Box lớn (440 x 48)
        var inputBgGo = new GameObject("InputBox", typeof(RectTransform), typeof(Image), typeof(InputField));
        inputBgGo.transform.SetParent(group.transform, false);
        var inputImg = inputBgGo.GetComponent<Image>();
        var inputBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/input_bg");
        if (inputBgSprite != null)
        {
            inputImg.sprite = inputBgSprite;
            inputImg.type = Image.Type.Sliced;
        }
        else inputImg.color = GameTheme.Field;

        var boxRt = inputBgGo.GetComponent<RectTransform>();
        boxRt.anchorMin = new Vector2(0, 0);
        boxRt.anchorMax = new Vector2(1, 1);
        boxRt.pivot = new Vector2(0.5f, 0);
        boxRt.offsetMin = new Vector2(0, 0);
        boxRt.offsetMax = new Vector2(0, -24);

        // Viền tinh tế cho InputBox
        var inBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        inBorder.transform.SetParent(inputBgGo.transform, false);
        var inbImg = inBorder.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { inbImg.sprite = frameSpr; inbImg.type = Image.Type.Sliced; }
        inbImg.color = new Color(0.85f, 0.72f, 0.35f, 0.65f);
        inbImg.raycastTarget = false;
        Fill(inBorder.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        outInput = inputBgGo.GetComponent<InputField>();
        outInput.targetGraphic = inputImg;
        outInput.contentType = isPassword ? InputField.ContentType.Password : InputField.ContentType.Standard;
        outInput.lineType = InputField.LineType.SingleLine;
        outInput.characterLimit = 60;

        // Icon lớn (26x26)
        var icoGo = new GameObject("Icon", typeof(RectTransform), typeof(Image));
        icoGo.transform.SetParent(inputBgGo.transform, false);
        var icoImg = icoGo.GetComponent<Image>();
        icoImg.sprite = LotusHealthUI.LoadSpriteFromResources(iconPath);
        icoImg.preserveAspect = true;
        icoImg.raycastTarget = false;
        var icoRt = icoGo.GetComponent<RectTransform>();
        icoRt.anchorMin = new Vector2(0, 0.5f);
        icoRt.anchorMax = new Vector2(0, 0.5f);
        icoRt.pivot = new Vector2(0, 0.5f);
        icoRt.sizeDelta = new Vector2(26, 26);
        icoRt.anchoredPosition = new Vector2(14, 0);

        // Text nhập vào lớn (22pt)
        var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(inputBgGo.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 22;
        txt.color = Color.white;
        txt.alignment = TextAnchor.MiddleLeft;
        var txtRt = txtGo.GetComponent<RectTransform>();
        Fill(txtRt, new Vector2(46, 0), new Vector2(-14, 0));
        outInput.textComponent = txt;

        // Placeholder lớn (20pt)
        var phGo = new GameObject("Placeholder", typeof(RectTransform), typeof(Text));
        phGo.transform.SetParent(inputBgGo.transform, false);
        var ph = phGo.GetComponent<Text>();
        ph.font = font;
        ph.fontSize = 20;
        ph.fontStyle = FontStyle.Italic;
        ph.color = new Color(0.55f, 0.65f, 0.78f, 0.85f);
        ph.text = placeholderStr;
        ph.alignment = TextAnchor.MiddleLeft;
        var phRt = phGo.GetComponent<RectTransform>();
        Fill(phRt, new Vector2(46, 0), new Vector2(-14, 0));
        outInput.placeholder = ph;

        return group;
    }

    private void SetRegisterMode(bool isRegister)
    {
        registerMode = isRegister;

        // Cập nhật tab
        tabLoginText.color = !registerMode ? GameTheme.GoldBright : GameTheme.Muted;
        tabLoginLine.gameObject.SetActive(!registerMode);

        tabRegisterText.color = registerMode ? GameTheme.GoldBright : GameTheme.Muted;
        tabRegisterLine.gameObject.SetActive(registerMode);

        submitButtonText.text = registerMode ? "TẠO TÀI KHOẢN MỚI" : "ĐĂNG NHẬP CHIẾN TRƯỜNG";
        forgotButton.gameObject.SetActive(!registerMode);

        // Bố trí lại vị trí các trường thoáng đãng
        if (registerMode)
        {
            nameGroup.SetActive(true);
            SetFieldY(nameGroup, -84f);
            SetFieldY(emailGroup, -162f);
            SetFieldY(passwordGroup, -240f);
            SetRect(submitButton.GetComponent<RectTransform>(), Center(), Center(), Center(), new Vector2(440, 56), new Vector2(0, -135f));
            SetRect(messageText.rectTransform, Center(), Center(), Center(), new Vector2(460, 42), new Vector2(0, -195f));
        }
        else
        {
            nameGroup.SetActive(false);
            SetFieldY(emailGroup, -100f);
            SetFieldY(passwordGroup, -188f);
            SetRect(submitButton.GetComponent<RectTransform>(), Center(), Center(), Center(), new Vector2(440, 56), new Vector2(0, -100f));
            SetRect(forgotButton.GetComponent<RectTransform>(), Center(), Center(), Center(), new Vector2(440, 30), new Vector2(0, -155f));
            SetRect(messageText.rectTransform, Center(), Center(), Center(), new Vector2(460, 42), new Vector2(0, -200f));
        }

        SetMessage("");
    }

    private void SetFieldY(GameObject go, float y)
    {
        var rt = go.GetComponent<RectTransform>();
        rt.anchoredPosition = new Vector2(0, y);
    }

    #region Onboarding Question (Modal Tân Thủ Trực Quan)
    /// <summary>
    /// Hiển thị câu hỏi Tân Thủ với 2 Card lựa chọn trực quan & hiệu ứng hoàng kim (Chữ lớn, dễ đọc)
    /// </summary>
    private void ShowOnboarding()
    {
        if (authCardRoot != null) authCardRoot.SetActive(false);
        if (brandRoot != null) brandRoot.SetActive(false);

        var canvas = transform.Find("Canvas");
        if (canvas == null) return;

        onboardingModalRoot = new GameObject("OnboardingModal", typeof(RectTransform));
        onboardingModalRoot.transform.SetParent(canvas, false);
        Fill(onboardingModalRoot.GetComponent<RectTransform>());

        // Nền tối mờ toàn màn hình
        var dimBg = AddImage(onboardingModalRoot.transform, "DimBackground", new Color(0, 0, 0, 0.85f));
        Fill(dimBg.rectTransform);

        // Khung Modal chính lớn (840 x 520)
        var modalBox = AddImage(onboardingModalRoot.transform, "ModalBox", Color.white);
        var cardBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (cardBgSprite != null)
        {
            modalBox.sprite = cardBgSprite;
            modalBox.type = Image.Type.Sliced;
        }
        var modalRt = modalBox.rectTransform;
        SetRect(modalRt, Center(), Center(), Center(), new Vector2(840, 520), Vector2.zero);

        // Khung viền vàng
        var border = new GameObject("Border", typeof(RectTransform), typeof(Image));
        border.transform.SetParent(modalBox.transform, false);
        var bImg = border.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(border.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var font = ThemeUI.FontMain;

        // Tiêu đề Modal (30pt Bold)
        var title = AddText(modalBox.transform, "Title", "CHÀO MỪNG TÂN CHIẾN TƯỚNG", 30, GameTheme.GoldBright, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(780, 42), new Vector2(0, -22));
        AddTextShadow(title);

        var divider = AddImage(modalBox.transform, "Divider", Color.white);
        divider.sprite = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        SetRect(divider.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400, 16), new Vector2(0, -66));

        var sub = AddText(modalBox.transform, "Subtitle", "Bạn đã từng tham gia chiến trường Đại Việt Chiến bao giờ chưa?", 20, new Color(1f, 0.95f, 0.85f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(sub.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(780, 30), new Vector2(0, -90));

        // 2 Thẻ Lựa Chọn Lớn (360x360): Tân Thủ Nhập Môn vs Kỳ Cựu Xuất Thế
        CreateOnboardingCard(modalBox.transform, new Vector2(-190, -28), "🌟 TÂN THỦ NHẬP MÔN", "CHƯA TỪNG CHƠI", "• Làm quen giao diện tướng\n• Tìm hiểu máu hoa sen & 5 dòng trang bị\n• Tập kích trận đầu với Sơn Tặc", "HƯỚNG DẪN TÔI ➜", true, font, ShowTutorial);

        CreateOnboardingCard(modalBox.transform, new Vector2(190, -28), "⚔️ KỲ CỰU XUẤT THẾ", "ĐÃ TỪNG CHƠI", "• Đã nắm vững quy tắc chiến đấu\n• Bỏ qua phần luyện tập cơ bản\n• Sẵn sàng tiến thẳng vào chiến trường", "VÀO TRÒ CHƠI ➜", false, font, () => FinishOnboarding(modalBox.gameObject));
    }

    private void CreateOnboardingCard(Transform parent, Vector2 pos, string tag, string titleStr, string descStr, string btnStr, bool isGold, Font font, UnityEngine.Events.UnityAction onClick)
    {
        var cardGo = new GameObject("ChoiceCard_" + titleStr, typeof(RectTransform), typeof(Image));
        cardGo.transform.SetParent(parent, false);
        var cardImg = cardGo.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null)
        {
            cardImg.sprite = choiceBg;
            cardImg.type = Image.Type.Sliced;
        }
        else cardImg.color = new Color(0.1f, 0.14f, 0.22f, 0.95f);

        var rt = cardGo.GetComponent<RectTransform>();
        SetRect(rt, Center(), Center(), Center(), new Vector2(360, 350), pos);

        // Viền thẻ
        var border = new GameObject("Border", typeof(RectTransform), typeof(Image));
        border.transform.SetParent(cardGo.transform, false);
        var bImg = border.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = isGold ? new Color(1f, 0.85f, 0.35f, 0.95f) : new Color(0.45f, 0.75f, 1f, 0.9f);
        Fill(border.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // Tag lớn (16pt Bold)
        var tagTxt = AddText(cardGo.transform, "Tag", tag, 16, isGold ? GameTheme.GoldBright : new Color(0.45f, 0.75f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(tagTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(340, 28), new Vector2(0, -14));

        // Title lớn (24pt Bold)
        var titleTxt = AddText(cardGo.transform, "Title", titleStr, 24, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(340, 34), new Vector2(0, -44));
        AddShadow(titleTxt.gameObject);

        // Description lớn (18pt, line spacing 1.4)
        var descTxt = AddText(cardGo.transform, "Desc", descStr, 18, new Color(0.88f, 0.92f, 0.98f, 0.98f), FontStyle.Normal, TextAnchor.UpperLeft);
        descTxt.lineSpacing = 1.4f;
        SetRect(descTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), Center(), new Vector2(310, 130), new Vector2(0, -12));

        // Button lớn (310 x 50, chữ 22pt)
        var btnGo = new GameObject("ActionBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(cardGo.transform, false);
        var btnImg = btnGo.GetComponent<Image>();
        var btnSprite = LotusHealthUI.LoadSpriteFromResources(isGold ? "UI/btn_gold" : "UI/btn_dark");
        if (btnSprite != null)
        {
            btnImg.sprite = btnSprite;
            btnImg.type = Image.Type.Sliced;
        }
        else btnImg.color = isGold ? GameTheme.Gold : new Color(0.2f, 0.25f, 0.35f, 1f);

        var btn = btnGo.GetComponent<Button>();
        btn.onClick.AddListener(onClick);
        var btnRt = btnGo.GetComponent<RectTransform>();
        SetRect(btnRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(310, 50), new Vector2(0, 18));

        var label = AddText(btnGo.transform, "Label", btnStr, 20, isGold ? new Color(0.10f, 0.06f, 0.02f, 1f) : Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(label.rectTransform);
        AddShadow(label.gameObject);
    }


    private string RewardKey() => "tutorial_reward_claimed_" + (string.IsNullOrEmpty(signedInEmail) ? "default" : signedInEmail);
    private string SilverKey() => "user_silver_" + (string.IsNullOrEmpty(signedInEmail) ? "default" : signedInEmail);

    public int GetSilver() => PlayerPrefs.GetInt(SilverKey(), 0);

    private void FinishOnboarding(GameObject modalBox)
    {
        PlayerPrefs.SetInt(OnboardingKey(signedInEmail), 2);
        PlayerPrefs.Save();
        StartCoroutine(SaveOnboardingComplete());
        if (onboardingModalRoot != null) Destroy(onboardingModalRoot);
        CheckAndShowTutorialReward();
    }

    private void ShowTutorial()
    {
        PlayerPrefs.SetInt(OnboardingKey(signedInEmail), 2);
        PlayerPrefs.Save();
        StartCoroutine(SaveOnboardingComplete());

        if (onboardingModalRoot != null) Destroy(onboardingModalRoot);

        var canvas = transform.Find("Canvas");
        if (canvas != null) canvas.gameObject.SetActive(false);

        TutorialBattleUI.Create(null, () =>
        {
            CheckAndShowTutorialReward();
        });
    }

    public void CheckAndShowTutorialReward()
    {
        var canvas = transform.Find("Canvas");
        if (canvas != null) canvas.gameObject.SetActive(true);
        if (authCardRoot != null) authCardRoot.SetActive(false);
        if (brandRoot != null) brandRoot.SetActive(false);

        if (IsRewardClaimed || PlayerPrefs.GetInt(RewardKey(), 0) == 1)
        {
            if (canvas != null) canvas.gameObject.SetActive(false);
            HomeUI.Open(signedInEmail);
            return;
        }

        var font = ThemeUI.FontMain;

        var rewardModalGo = new GameObject("RewardModalRoot", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        rewardModalGo.transform.SetParent(canvas != null ? canvas.transform : transform, false);
        rewardModalGo.transform.SetAsLastSibling();

        var bgImg = rewardModalGo.GetComponent<Image>();
        bgImg.color = new Color(0.02f, 0.03f, 0.08f, 0.88f);
        Fill(rewardModalGo.GetComponent<RectTransform>());

        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(rewardModalGo.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        else bImg.color = new Color(0.08f, 0.12f, 0.2f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = new Vector2(840f, 530f);
        boxRt.anchoredPosition = Vector2.zero;

        // Viền vàng phát sáng
        var border = new GameObject("Border", typeof(RectTransform), typeof(Image));
        border.transform.SetParent(boxGo.transform, false);
        var borImg = border.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { borImg.sprite = frameSpr; borImg.type = Image.Type.Sliced; }
        borImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(border.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        // Tiêu đề lớn (30pt Bold)
        var title = AddText(boxGo.transform, "Title", "🎉 PHẦN THƯỞNG KHAI MÔN TÂN THỦ", 30, GameTheme.GoldBright, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(780, 42), new Vector2(0, -20));
        AddTextShadow(title);

        var div = AddImage(boxGo.transform, "Divider", Color.white);
        div.sprite = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        SetRect(div.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400, 16), new Vector2(0, -64));

        var sub = AddText(boxGo.transform, "Subtitle", "Chúc mừng chiến tướng đã sẵn sàng! Nhận ngay tướng lĩnh & ngân lượng khởi đầu:", 20, new Color(1f, 0.95f, 0.85f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(sub.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(780, 30), new Vector2(0, -88));

        // 2 Khung Phần Thưởng Lớn (350 x 330): Tướng Lý Thường Kiệt và 1000 Bạc
        // 1. TƯỚNG LÝ THƯỜNG KIỆT
        CreateRewardCard(boxGo.transform, new Vector2(-185, -24), "🎖️ TƯỚNG KHỞI ĐẦU", "LÝ THƯỜNG KIỆT", "UI/ly_thuong_kiet", "Máu: 4 đóa sen (Phe Khác)\n⚡ Tuyệt kỹ: [Tiến Thoái]\nĐổi Trảm ⮂ Đỡ trên tay", font);

        // 2. 1000 BẠC
        CreateRewardCard(boxGo.transform, new Vector2(185, -24), "🪙 NGÂN LƯỢNG", "1.000 BẠC", "UI/btn_gold", "Tài nguyên giá trị dùng để:\n• Chiêu mộ thêm chiến tướng\n• Mua sắm vật phẩm & bảo vật", font);

        // Nút Nhận Thưởng lớn (380 x 54, chữ 22pt)
        var claimBtnGo = new GameObject("ClaimBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        claimBtnGo.transform.SetParent(boxGo.transform, false);
        var claimImg = claimBtnGo.GetComponent<Image>();
        var btnSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSprite != null) { claimImg.sprite = btnSprite; claimImg.type = Image.Type.Sliced; }
        else claimImg.color = GameTheme.Gold;

        var claimRt = claimBtnGo.GetComponent<RectTransform>();
        claimRt.anchorMin = new Vector2(0.5f, 0f);
        claimRt.anchorMax = new Vector2(0.5f, 0f);
        claimRt.pivot = new Vector2(0.5f, 0f);
        claimRt.sizeDelta = new Vector2(380f, 54f);
        claimRt.anchoredPosition = new Vector2(0, 18);

        // Viền nút
        var clBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        clBorder.transform.SetParent(claimBtnGo.transform, false);
        var clbImg = clBorder.GetComponent<Image>();
        if (frameSpr != null) { clbImg.sprite = frameSpr; clbImg.type = Image.Type.Sliced; }
        clbImg.color = new Color(1f, 0.92f, 0.45f, 0.95f);
        Fill(clBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var claimTxt = AddText(claimBtnGo.transform, "Label", "🎁 NHẬN THƯỞNG VÀ VỀ TRANG CHỦ", 22, new Color(0.10f, 0.06f, 0.02f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(claimTxt.rectTransform);
        AddShadow(claimTxt.gameObject);

        claimBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            CurrentSilver += 1000;
            IsRewardClaimed = true;
            if (!CurrentGenerals.Contains("ly_thuong_kiet"))
            {
                CurrentGenerals = string.IsNullOrEmpty(CurrentGenerals) ? "ly_thuong_kiet" : CurrentGenerals + ",ly_thuong_kiet";
            }
            PlayerPrefs.SetInt(SilverKey(), CurrentSilver);
            PlayerPrefs.SetInt(RewardKey(), 1);
            PlayerPrefs.Save();

            StartCoroutine(SaveUserProfileToAppwrite());

            AudioManager.Instance.PlayVictory();
            Destroy(rewardModalGo);

            if (canvas != null) canvas.gameObject.SetActive(false);
            HomeUI.Open(signedInEmail);
        });
    }

    private void CreateRewardCard(Transform parent, Vector2 pos, string tag, string titleStr, string iconResource, string descStr, Font font)
    {
        var cardGo = new GameObject("RewardCard_" + titleStr, typeof(RectTransform), typeof(Image));
        cardGo.transform.SetParent(parent, false);
        var cardImg = cardGo.GetComponent<Image>();
        var choiceBg = LotusHealthUI.LoadSpriteFromResources("UI/choice_card_bg");
        if (choiceBg != null) { cardImg.sprite = choiceBg; cardImg.type = Image.Type.Sliced; }
        else cardImg.color = new Color(0.1f, 0.14f, 0.22f, 0.95f);

        var rt = cardGo.GetComponent<RectTransform>();
        SetRect(rt, Center(), Center(), Center(), new Vector2(350, 330), pos);

        // Viền thẻ
        var border = new GameObject("Border", typeof(RectTransform), typeof(Image));
        border.transform.SetParent(cardGo.transform, false);
        var bImg = border.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(border.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // Tag (16pt Bold)
        var tagTxt = AddText(cardGo.transform, "Tag", tag, 16, GameTheme.GoldBright, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(tagTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(330, 26), new Vector2(0, -12));

        // Icon Avatar / Resource lớn (100x100)
        var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Image));
        iconGo.transform.SetParent(cardGo.transform, false);
        var iconImg = iconGo.GetComponent<Image>();
        var spr = LotusHealthUI.LoadSpriteFromResources(iconResource);
        if (spr != null) iconImg.sprite = spr;
        iconImg.preserveAspect = true;
        var iconRt = iconGo.GetComponent<RectTransform>();
        SetRect(iconRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(100, 100), new Vector2(0, -42));

        // Title lớn (24pt Bold)
        var titleTxt = AddText(cardGo.transform, "Title", titleStr, 24, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(330, 32), new Vector2(0, -148));
        AddShadow(titleTxt.gameObject);

        // Description lớn (18pt, line spacing 1.35)
        var descTxt = AddText(cardGo.transform, "Desc", descStr, 18, new Color(0.88f, 0.92f, 1f, 0.98f), FontStyle.Normal, TextAnchor.MiddleCenter);
        descTxt.lineSpacing = 1.35f;
        SetRect(descTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(320, 110), new Vector2(0, 14));
    }

    #endregion

    #region Appwrite API & Session Handling
    private void Submit()
    {
        if (restoringSession) { SetMessage("Đang kiểm tra phiên đăng nhập..."); return; }
        if (registerMode) StartCoroutine(Register()); else StartCoroutine(Login());
    }

    private void TriggerForgotPassword() => StartCoroutine(ForgotPassword());

    private IEnumerator Register()
    {
        if (string.IsNullOrWhiteSpace(emailInput.text) || passwordInput.text.Length < 8)
        {
            SetMessage("Email hợp lệ và mật thư tối thiểu 8 ký tự.", true);
            yield break;
        }

        string targetEmail = emailInput.text.Trim();
        string targetPass = passwordInput.text;
        string targetName = nameInput != null ? nameInput.text.Trim() : "Đại Tướng Quân";

        SetAuthInteractable(false);
        SetMessage("Đang lập danh xưng chiến tướng...");

        // Hủy phiên cũ nếu có trên Appwrite
        using (var delReq = new UnityWebRequest(Endpoint + "/account/sessions/current", "DELETE"))
        {
            delReq.downloadHandler = new DownloadHandlerBuffer();
            delReq.SetRequestHeader("X-Appwrite-Project", ProjectId);
            string savedCookie = sessionCookie;
            if (string.IsNullOrEmpty(savedCookie)) savedCookie = PlayerPrefs.GetString("auth_session_cookie", "");
            if (!string.IsNullOrEmpty(savedCookie)) delReq.SetRequestHeader("Cookie", savedCookie);
            yield return delReq.SendWebRequest();
        }
        sessionCookie = "";
        PlayerPrefs.DeleteKey("auth_session_cookie");
        PlayerPrefs.Save();
        yield return new WaitForSecondsRealtime(0.2f);

        var body = JsonUtility.ToJson(new RegisterRequest { userId = Guid.NewGuid().ToString("N"), email = targetEmail, password = targetPass, name = targetName });
        signedInEmail = targetEmail;
        var accountCreated = false;
        yield return Request("/account", body, "Đăng ký thành công!", false, success => accountCreated = success);
        if (!accountCreated)
        {
            SetAuthInteractable(true);
            yield break;
        }

        PlayerPrefs.SetInt(OnboardingKey(signedInEmail), 1);
        PlayerPrefs.Save();

        var loginPayload = JsonUtility.ToJson(new LoginRequest { email = signedInEmail, password = targetPass });
        yield return Request("/account/sessions/email", loginPayload, "Đăng nhập thành công!", true);
        SetAuthInteractable(true);
    }

    private IEnumerator Login()
    {
        if (string.IsNullOrWhiteSpace(emailInput.text) || string.IsNullOrEmpty(passwordInput.text))
        {
            SetMessage("Vui lòng nhập email và mật thư.", true);
            yield break;
        }

        string targetEmail = emailInput.text.Trim();
        string targetPass = passwordInput.text;

        SetAuthInteractable(false);
        SetMessage("Đang xác thực thông tin chiến tướng...");

        // 1. Kiểm tra xem hiện tại trên máy chủ có phiên đăng nhập nào đang mở không
        string activeEmail = null;
        using (var checkReq = UnityWebRequest.Get(Endpoint + "/account"))
        {
            checkReq.SetRequestHeader("X-Appwrite-Project", ProjectId);
            string savedCookie = sessionCookie;
            if (string.IsNullOrEmpty(savedCookie)) savedCookie = PlayerPrefs.GetString("auth_session_cookie", "");
            if (!string.IsNullOrEmpty(savedCookie)) checkReq.SetRequestHeader("Cookie", savedCookie);

            yield return checkReq.SendWebRequest();
            if (checkReq.result == UnityWebRequest.Result.Success)
            {
                var acc = JsonUtility.FromJson<AccountResponse>(checkReq.downloadHandler.text);
                if (acc != null && !string.IsNullOrWhiteSpace(acc.email))
                {
                    activeEmail = acc.email.Trim();
                }
            }
        }

        // 2. Nếu đang có phiên của tài khoản khác -> Hủy phiên cũ đó trên Appwrite
        if (!string.IsNullOrEmpty(activeEmail))
        {
            if (string.Equals(activeEmail, targetEmail, StringComparison.OrdinalIgnoreCase))
            {
                // Đúng tài khoản đang active -> Khôi phục và vào thẳng game
                signedInEmail = targetEmail;
                CurrentUserEmail = targetEmail;
                var shouldAsk = PlayerPrefs.GetInt(OnboardingKey(signedInEmail), 0) != 2;
                yield return ResolveOnboardingAndShow(shouldAsk, true);
                SetAuthInteractable(true);
                yield break;
            }
            else
            {
                // Tài khoản khác -> Đóng phiên cũ
                SetMessage("Đang chuyển đổi tài khoản...");
                using (var delReq = new UnityWebRequest(Endpoint + "/account/sessions/current", "DELETE"))
                {
                    delReq.downloadHandler = new DownloadHandlerBuffer();
                    delReq.SetRequestHeader("X-Appwrite-Project", ProjectId);
                    string savedCookie = sessionCookie;
                    if (string.IsNullOrEmpty(savedCookie)) savedCookie = PlayerPrefs.GetString("auth_session_cookie", "");
                    if (!string.IsNullOrEmpty(savedCookie)) delReq.SetRequestHeader("Cookie", savedCookie);
                    yield return delReq.SendWebRequest();
                }
                sessionCookie = "";
                PlayerPrefs.DeleteKey("auth_session_cookie");
                PlayerPrefs.Save();
                yield return new WaitForSecondsRealtime(0.2f);
            }
        }

        // 3. Đăng nhập tài khoản mới
        signedInEmail = targetEmail;
        var askOnboarding = PlayerPrefs.GetInt(OnboardingKey(signedInEmail), 0) != 2;
        var loginPayload = JsonUtility.ToJson(new LoginRequest { email = targetEmail, password = targetPass });

        yield return Request("/account/sessions/email", loginPayload, "Đăng nhập thành công!", askOnboarding);
        SetAuthInteractable(true);
    }

    private IEnumerator ForgotPassword()
    {
        if (string.IsNullOrWhiteSpace(emailInput.text)) { SetMessage("Nhập email để nhận liên kết khôi phục.", true); yield break; }
        yield return Request("/account/recovery", JsonUtility.ToJson(new RecoveryRequest { email = emailInput.text.Trim(), url = RecoveryUrl }), "Đã gửi liên kết khôi phục đến email của bạn.");
    }

    private IEnumerator RestoreSession()
    {
        restoringSession = true;
        SetAuthInteractable(false);
        SetMessage("Đang kiểm tra phiên đăng nhập...");
        using (var request = UnityWebRequest.Get(Endpoint + "/account"))
        {
            AddSessionHeaders(request);
            yield return request.SendWebRequest();
            CaptureSessionCookie(request);
            if (request.result != UnityWebRequest.Result.Success)
            {
                if (request.responseCode == 401)
                {
                    sessionCookie = "";
                    PlayerPrefs.DeleteKey("auth_session_cookie");
                    PlayerPrefs.Save();
                }
                restoringSession = false;
                SetAuthInteractable(true);
                SetMessage("Chào mừng trở lại! Vui lòng đăng nhập.");
                yield break;
            }

            var account = JsonUtility.FromJson<AccountResponse>(request.downloadHandler.text);
            if (!string.IsNullOrWhiteSpace(account.email)) signedInEmail = account.email.Trim();
            else if (string.IsNullOrWhiteSpace(signedInEmail)) signedInEmail = PlayerPrefs.GetString("auth_last_email", "");

            CurrentUserEmail = signedInEmail;
            if (!string.IsNullOrWhiteSpace(account.name))
            {
                CurrentUserName = account.name.Trim();
                PlayerPrefs.SetString("auth_user_name", CurrentUserName);
            }
            else
            {
                CurrentUserName = PlayerPrefs.GetString("auth_user_name", "");
                if (string.IsNullOrWhiteSpace(CurrentUserName) && !string.IsNullOrWhiteSpace(signedInEmail))
                {
                    CurrentUserName = signedInEmail.Split('@')[0];
                }
            }

            CurrentUserLabels.Clear();
            if (account.labels != null && account.labels.Length > 0)
            {
                CurrentUserLabels.AddRange(account.labels);
                PlayerPrefs.SetString("auth_user_labels", string.Join(",", account.labels));
            }
            else
            {
                PlayerPrefs.DeleteKey("auth_user_labels");
            }
            PlayerPrefs.Save();
            Debug.Log($"[Auth] Account loaded: {CurrentUserName} ({CurrentUserEmail}) - Labels: [{string.Join(", ", CurrentUserLabels)}] - IsAdmin: {IsAdmin}");

            SaveSessionState();
            if (HomeUI.Instance != null) HomeUI.Instance.RefreshUserData();
            var shouldAsk = !string.IsNullOrWhiteSpace(signedInEmail) && PlayerPrefs.GetInt(OnboardingKey(signedInEmail), 0) != 2;
            yield return ResolveOnboardingAndShow(shouldAsk, true);
            restoringSession = false;
        }
    }

    private void SetAuthInteractable(bool value)
    {
        if (submitButton != null) submitButton.interactable = value;
        if (forgotButton != null) forgotButton.interactable = value;
        if (tabLoginBtn != null) tabLoginBtn.interactable = value;
        if (tabRegisterBtn != null) tabRegisterBtn.interactable = value;
    }

    private void ShowSignedIn()
    {
        var canvas = transform.Find("Canvas");
        if (canvas != null) canvas.gameObject.SetActive(false);
        HomeUI.Open(signedInEmail);
    }

    private IEnumerator Request(string path, string body, string success, bool showOnboarding = false, Action<bool> completed = null)
    {
        SetMessage("Đang kết nối thần điện...");
        using (var request = new UnityWebRequest(Endpoint + path, "POST"))
        {
            request.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(body));
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");
            request.SetRequestHeader("X-Appwrite-Project", ProjectId);
            AddSessionHeaders(request);
            yield return request.SendWebRequest();
            CaptureSessionCookie(request);
            Debug.Log("[Auth] " + path + " -> HTTP " + request.responseCode + " (" + request.result + ")");
            if (request.result == UnityWebRequest.Result.Success)
            {
                SaveSessionState();
            if (HomeUI.Instance != null) HomeUI.Instance.RefreshUserData();
                if (path == "/account/sessions/email")
                    yield return ResolveOnboardingAndShow(showOnboarding, false);
                else
                    SetMessage(success);
                completed?.Invoke(true);
            }
            else
            {
                string respText = request.downloadHandler != null ? request.downloadHandler.text : "";
                Debug.LogWarning("[Auth Error] " + respText + " | " + request.error);

                bool isActiveSession = respText.IndexOf("session is active", StringComparison.OrdinalIgnoreCase) >= 0;
                if (isActiveSession && path == "/account/sessions/email")
                {
                    SetMessage("Đang làm mới phiên làm việc...");
                    yield return DeleteCurrentSession();
                    yield return new WaitForSecondsRealtime(0.3f);

                    // Thử đăng nhập lại lần 2
                    using (var retryReq = new UnityWebRequest(Endpoint + path, "POST"))
                    {
                        retryReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(body));
                        retryReq.downloadHandler = new DownloadHandlerBuffer();
                        retryReq.SetRequestHeader("Content-Type", "application/json");
                        retryReq.SetRequestHeader("X-Appwrite-Project", ProjectId);
                        yield return retryReq.SendWebRequest();
                        CaptureSessionCookie(retryReq);

                        if (retryReq.result == UnityWebRequest.Result.Success)
                        {
                            SaveSessionState();
            if (HomeUI.Instance != null) HomeUI.Instance.RefreshUserData();
                            yield return ResolveOnboardingAndShow(showOnboarding, false);
                            completed?.Invoke(true);
                            yield break;
                        }
                        else
                        {
                            string retryErr = retryReq.downloadHandler != null ? retryReq.downloadHandler.text : "";
                            SetMessage(ParseError(retryErr, retryReq.error), true);
                            completed?.Invoke(false);
                            yield break;
                        }
                    }
                }

                SetMessage(ParseError(respText, request.error), true);
                completed?.Invoke(false);
            }
        }
    }

    private IEnumerator ResolveOnboardingAndShow(bool localFallback, bool automatic)
    {
        // First, ensure we have account info
        using (var accReq = UnityWebRequest.Get(Endpoint + "/account"))
        {
            AddSessionHeaders(accReq);
            yield return accReq.SendWebRequest();
            if (accReq.result == UnityWebRequest.Result.Success)
            {
                var acc = JsonUtility.FromJson<AccountResponse>(accReq.downloadHandler.text);
                if (!string.IsNullOrWhiteSpace(acc.name))
                {
                    CurrentUserName = acc.name.Trim();
                    PlayerPrefs.SetString("auth_user_name", CurrentUserName);
                }
                if (!string.IsNullOrWhiteSpace(acc.email))
                {
                    signedInEmail = acc.email.Trim();
                    CurrentUserEmail = signedInEmail;
                }
                CurrentUserLabels.Clear();
                if (acc.labels != null && acc.labels.Length > 0)
                {
                    CurrentUserLabels.AddRange(acc.labels);
                    PlayerPrefs.SetString("auth_user_labels", string.Join(",", acc.labels));
                }
                else
                {
                    PlayerPrefs.DeleteKey("auth_user_labels");
                }
                PlayerPrefs.Save();
                Debug.Log($"[Auth] Onboarding Account: {CurrentUserName} ({CurrentUserEmail}) - Labels: [{string.Join(", ", CurrentUserLabels)}] - IsAdmin: {IsAdmin}");
            }
        }

        var shouldAsk = localFallback;
        using (var request = UnityWebRequest.Get(Endpoint + "/account/prefs"))
        {
            AddSessionHeaders(request);
            yield return request.SendWebRequest();
            if (request.result == UnityWebRequest.Result.Success)
            {
                var prefs = JsonUtility.FromJson<PreferencesResponse>(request.downloadHandler.text);
                shouldAsk = !prefs.onboardingComplete;
                CurrentSilver = prefs.silver;
                CurrentGold = prefs.gold;
                CurrentLevel = prefs.level > 0 ? prefs.level : 1;
                CurrentExp = prefs.exp;
                CurrentMilitaryPoints = prefs.militaryPoints;
                Current2v2Points = prefs.rank2v2Points;
                CurrentGenerals = !string.IsNullOrEmpty(prefs.generals) ? prefs.generals : "ly_thuong_kiet";
                IsRewardClaimed = prefs.tutorialRewardClaimed;

                PlayerPrefs.SetInt(SilverKey(), CurrentSilver);
                PlayerPrefs.SetInt(RewardKey(), IsRewardClaimed ? 1 : 0);
                PlayerPrefs.SetInt("auth_military_points", CurrentMilitaryPoints);
                PlayerPrefs.SetInt("auth_rank2v2_points", Current2v2Points);
                PlayerPrefs.Save();
            }
            else
            {
                Debug.LogWarning("[Auth] Preferences unavailable; showing onboarding as a safe fallback. HTTP " + request.responseCode);
                shouldAsk = localFallback;
            }
        }
        yield return ShowAuthenticationResult(shouldAsk, automatic);
    }

    private IEnumerator ShowAuthenticationResult(bool shouldAskOnboarding, bool automatic)
    {
        SetAuthInteractable(false);
        SetMessage(automatic ? "Tự động đăng nhập thành công!" : "Đăng nhập thành công!");
        yield return new WaitForSecondsRealtime(0.6f);
        if (shouldAskOnboarding) ShowOnboarding();
        else ShowSignedIn();
    }

    public void Show()
    {
        var canvas = transform.Find("Canvas");
        if (canvas != null) canvas.gameObject.SetActive(true);
        if (authCardRoot != null) authCardRoot.SetActive(true);
        if (brandRoot != null) brandRoot.SetActive(true);
        SetAuthInteractable(true);
    }

    private void SetMessage(string value, bool error = false)
    {
        if (messageText == null) return;
        messageText.text = value;
        messageText.color = error ? GameTheme.Danger : GameTheme.GoldBright;
    }

    private string ParseError(string json, string fallback)
    {
        try
        {
            var error = JsonUtility.FromJson<ErrorResponse>(json);
            if (!string.IsNullOrEmpty(error.message))
            {
                string msg = error.message;
                if (msg.IndexOf("Invalid credentials", StringComparison.OrdinalIgnoreCase) >= 0)
                    return "Mật thư hoặc email không chính xác. Vui lòng kiểm tra lại.";
                if (msg.IndexOf("already exists", StringComparison.OrdinalIgnoreCase) >= 0)
                    return "Email này đã được đăng ký. Vui lòng chọn tab Đăng Nhập.";
                if (msg.IndexOf("Password must be between", StringComparison.OrdinalIgnoreCase) >= 0)
                    return "Mật thư phải có từ 8 ký tự trở lên.";
                if (msg.IndexOf("Invalid email", StringComparison.OrdinalIgnoreCase) >= 0)
                    return "Địa chỉ email không đúng định dạng.";
                return msg;
            }
        }
        catch { }
        return fallback;
    }

    private void AddSessionHeaders(UnityWebRequest request)
    {
        request.SetRequestHeader("X-Appwrite-Project", ProjectId);
        // Không đính kèm cookie cũ khi đang gửi request tạo session mới hoặc đăng ký
        if (request.method == "POST" && request.url.Contains("/account/sessions/email"))
        {
            return;
        }
        string secret = PlayerPrefs.GetString("auth_session_secret", sessionSecret);
        if (!string.IsNullOrEmpty(secret))
        {
            request.SetRequestHeader("X-Appwrite-Session", secret);
        }
        if (!string.IsNullOrEmpty(sessionCookie))
        {
#if !UNITY_WEBGL || UNITY_EDITOR
            request.SetRequestHeader("Cookie", sessionCookie);
#endif
        }
    }

    public static IEnumerator SaveUserProfileToAppwrite(Action onComplete = null)
    {
        var prefs = new PreferencesResponse
        {
            onboardingComplete = true,
            silver = CurrentSilver,
            gold = CurrentGold,
            level = CurrentLevel,
            exp = CurrentExp,
            militaryPoints = CurrentMilitaryPoints,
            rank2v2Points = Current2v2Points,
            generals = CurrentGenerals,
            tutorialRewardClaimed = IsRewardClaimed
        };
        var payload = JsonUtility.ToJson(new PreferencesUpdateRequest { prefs = prefs });
        using (var request = new UnityWebRequest(Endpoint + "/account/prefs", "PATCH"))
        {
            request.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(payload));
            request.downloadHandler = new DownloadHandlerBuffer();
            request.SetRequestHeader("Content-Type", "application/json");
            request.SetRequestHeader("X-Appwrite-Project", ProjectId);
            string secret = PlayerPrefs.GetString("auth_session_secret", "");
            if (!string.IsNullOrEmpty(secret)) request.SetRequestHeader("X-Appwrite-Session", secret);
            string cookie = PlayerPrefs.GetString("auth_session_cookie", "");
            if (!string.IsNullOrEmpty(cookie))
            {
#if !UNITY_WEBGL || UNITY_EDITOR
                request.SetRequestHeader("Cookie", cookie);
#endif
            }
            yield return request.SendWebRequest();
            if (request.result == UnityWebRequest.Result.Success)
            {
                Debug.Log("[Appwrite] Profile prefs synced successfully!");
            }
            onComplete?.Invoke();
        }
    }

    private IEnumerator SaveOnboardingComplete()
    {
        yield return SaveUserProfileToAppwrite();
    }

    private void CaptureSessionCookie(UnityWebRequest request)
    {
        var headers = request.GetResponseHeaders();
        if (headers != null)
        {
            string cookie = null;
            foreach (var header in headers)
            {
                if (string.Equals(header.Key, "Set-Cookie", StringComparison.OrdinalIgnoreCase))
                {
                    cookie = header.Value;
                    break;
                }
            }
            if (!string.IsNullOrEmpty(cookie))
            {
                var end = cookie.IndexOf(';');
                sessionCookie = end >= 0 ? cookie.Substring(0, end) : cookie;
            }
        }

        if (request.downloadHandler != null && !string.IsNullOrEmpty(request.downloadHandler.text))
        {
            string text = request.downloadHandler.text;
            int secretIdx = text.IndexOf("\"secret\":\"", StringComparison.OrdinalIgnoreCase);
            if (secretIdx >= 0)
            {
                int start = secretIdx + 10;
                int end = text.IndexOf("\"", start);
                if (end > start)
                {
                    sessionSecret = text.Substring(start, end - start);
                }
            }
        }

        SaveSessionState();
    }

    private void SaveSessionState()
    {
        PlayerPrefs.SetString("auth_session_cookie", sessionCookie);
        if (!string.IsNullOrEmpty(sessionSecret)) PlayerPrefs.SetString("auth_session_secret", sessionSecret);
        if (!string.IsNullOrWhiteSpace(signedInEmail)) PlayerPrefs.SetString("auth_last_email", signedInEmail);
        PlayerPrefs.Save();
    }

    private static string OnboardingKey(string email) => "auth_onboarding_done_" + email.ToLowerInvariant();
    private static Vector2 Center() => new Vector2(0.5f, 0.5f);
    private static void Fill(RectTransform rect, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = Center(); rect.offsetMin = offsetMin; rect.offsetMax = offsetMax;
    }

    private static void SetRect(RectTransform rect, Vector2 anchorMin, Vector2 anchorMax, Vector2 pivot, Vector2 size, Vector2 position)
    {
        rect.anchorMin = anchorMin; rect.anchorMax = anchorMax; rect.pivot = pivot; rect.sizeDelta = size; rect.anchoredPosition = position;
    }

    private Text AddText(Transform parent, string objectName, string value, int size, Color color, FontStyle style, TextAnchor alignment)
    {
        var go = new GameObject(objectName, typeof(Text));
        go.transform.SetParent(parent, false);
        var text = go.GetComponent<Text>();
        text.font = ThemeUI.FontMain;
        text.text = value;
        text.fontSize = size;
        text.color = color;
        text.fontStyle = style;
        text.alignment = alignment;
        text.raycastTarget = false;
        text.horizontalOverflow = HorizontalWrapMode.Wrap;
        text.verticalOverflow = VerticalWrapMode.Overflow;
        return text;
    }

    public void PerformLogout()
    {
        StartCoroutine(LogoutRoutine());
    }

    private IEnumerator LogoutRoutine()
    {
        yield return DeleteCurrentSession();
        CurrentUserEmail = "";
        CurrentUserName = "";
        signedInEmail = "";
        PlayerPrefs.DeleteKey("auth_session_cookie");
        PlayerPrefs.DeleteKey("auth_session_secret");
        PlayerPrefs.DeleteKey("auth_user_name");
        PlayerPrefs.DeleteKey("auth_user_labels");
        PlayerPrefs.Save();
        Show();
        SetMessage("Đã đăng xuất thành công!");
    }

    private IEnumerator DeleteCurrentSession()
    {
        using (var req = new UnityWebRequest(Endpoint + "/account/sessions/current", "DELETE"))
        {
            req.downloadHandler = new DownloadHandlerBuffer();
            req.SetRequestHeader("X-Appwrite-Project", ProjectId);
            AddSessionHeaders(req);
            yield return req.SendWebRequest();
        }
        sessionCookie = null;
        sessionSecret = null;
        PlayerPrefs.DeleteKey("auth_session_cookie");
        PlayerPrefs.DeleteKey("auth_session_secret");
        PlayerPrefs.Save();
    }

    private static void AddShadow(GameObject go)
    {
        var shadow = go.AddComponent<Shadow>();
        shadow.effectColor = new Color(0f, 0f, 0f, 0.95f);
        shadow.effectDistance = new Vector2(1.5f, -1.5f);
    }

    private static void AddTextShadow(Text text)
    {
        var shadow = text.gameObject.AddComponent<Shadow>();
        shadow.effectColor = new Color(0, 0, 0, 0.95f);
        shadow.effectDistance = new Vector2(2, -2);
    }

    private static Image AddImage(Transform parent, string objectName, Color color)
    {
        var go = new GameObject(objectName, typeof(Image));
        go.transform.SetParent(parent, false);
        var image = go.GetComponent<Image>();
        image.color = color;
        return image;
    }

    private static RawImage AddRawImage(Transform parent, string objectName, Color color)
    {
        var go = new GameObject(objectName, typeof(RawImage));
        go.transform.SetParent(parent, false);
        var image = go.GetComponent<RawImage>();
        image.color = color;
        return image;
    }

    private Button AddButton(Transform parent, string label, Color color, bool linkStyle)
    {
        var image = AddImage(parent, "Button_" + label, linkStyle ? new Color(0, 0, 0, 0) : color);
        var button = image.gameObject.AddComponent<Button>();
        button.targetGraphic = image;
        var text = AddText(image.transform, "ButtonLabel", label, linkStyle ? 13 : 15, linkStyle ? GameTheme.GoldBright : GameTheme.Ink, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(text.rectTransform);
        return button;
    }

    private static void EnsureEventSystem()
    {
        var eventSystem = FindFirstObjectByType<EventSystem>();
        if (eventSystem != null)
        {
            var module = eventSystem.GetComponent<InputSystemUIInputModule>();
            if (module == null) module = eventSystem.gameObject.AddComponent<InputSystemUIInputModule>();
            module.AssignDefaultActions();
            return;
        }
        var root = new GameObject("EventSystem", typeof(EventSystem), typeof(InputSystemUIInputModule));
        root.GetComponent<InputSystemUIInputModule>().AssignDefaultActions();
        DontDestroyOnLoad(root);
    }

    [Serializable] public class RegisterRequest { public string userId, email, password, name; }
    [Serializable] public class LoginRequest { public string email, password; }
    [Serializable] public class RecoveryRequest { public string email, url; }
    [Serializable] public class ErrorResponse { public string message; }
    [Serializable] public class AccountResponse { public string name; public string email; public string[] labels; }
    [Serializable] public class PreferencesResponse 
    { 
        public bool onboardingComplete; 
        public int silver; 
        public int gold; 
        public int level = 1; 
        public int exp = 0; 
        public int militaryPoints = 0; 
        public int rank2v2Points = 0; 
        public string generals = "ly_thuong_kiet"; 
        public bool tutorialRewardClaimed; 
    }
    [Serializable] public class PreferencesUpdateRequest { public PreferencesResponse prefs; }
    #endregion
}

public static class GameTheme
{
    public static readonly Color Ink = new Color(0.025f, 0.04f, 0.075f, 1f);
    public static readonly Color Card = new Color(0.075f, 0.09f, 0.14f, 0.99f);
    public static readonly Color Field = new Color(0.11f, 0.14f, 0.2f, 1f);
    public static readonly Color Gold = new Color(1f, 0.61f, 0.12f, 1f);
    public static readonly Color GoldBright = new Color(1f, 0.78f, 0.26f, 1f);
    public static readonly Color Muted = new Color(0.68f, 0.72f, 0.8f, 1f);
    public static readonly Color Danger = new Color(1f, 0.42f, 0.42f, 1f);
}
