using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Script demo và kiểm thử trực quan giao diện thẻ Tướng Đại Việt Chiến.
/// Có sẵn các nút bấm điều khiển để test ngay trong Play Mode:
/// - Mất máu / Hồi máu (hoa sen sáng / tối màu)
/// - Gắn / Gỡ 5 dòng trang bị (Vũ khí, Giáp, Ngựa công, Ngựa thủ, Bảo vật)
/// - Đổi tên tướng & Đổi phe
/// </summary>
public class GeneralCardDemo : MonoBehaviour
{
    private GeneralCardUI heroCard;
    private int factionIndex = 0;
    private readonly string[] factions = new[] { "Khác", "Đại Việt", "Trần", "Lê", "Lý", "Nguyễn" };
    private readonly Color[] factionColors = new[]
    {
        new Color(0.48f, 0.22f, 0.65f, 0.95f), // Khác: Tím hoàng gia
        new Color(0.85f, 0.15f, 0.15f, 0.95f), // Đại Việt: Đỏ thắm
        new Color(0.18f, 0.52f, 0.88f, 0.95f), // Trần: Lam biển
        new Color(0.18f, 0.72f, 0.38f, 0.95f), // Lê: Lục bảo
        new Color(0.92f, 0.68f, 0.12f, 0.95f), // Lý: Hoàng kim
        new Color(0.85f, 0.38f, 0.18f, 0.95f), // Nguyễn: Cam son
    };

    private void Start()
    {
        BuildDemoScene();
    }

    private void BuildDemoScene()
    {
        // 1. Tìm hoặc tạo Canvas
        var canvas = FindFirstObjectByType<Canvas>();
        if (canvas == null)
        {
            var canvasGo = new GameObject("DemoCanvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280, 720);
            scaler.matchWidthOrHeight = 0.5f;
        }

        // 2. Tạo thẻ Tướng tỉ lệ 3:4 (270 x 360)
        heroCard = GeneralCardUI.Create(canvas.transform, new Vector2(270, 360), "Lý Thường Kiệt", "Khác", 4);
        var cardRt = heroCard.GetComponent<RectTransform>();
        cardRt.anchorMin = new Vector2(0.5f, 0.5f);
        cardRt.anchorMax = new Vector2(0.5f, 0.5f);
        cardRt.pivot = new Vector2(0.5f, 0.5f);
        cardRt.anchoredPosition = new Vector2(-160, 0);

        // 3. Panel điều khiển Test bên phải
        BuildControlPanel(canvas.transform);
    }

    private void BuildControlPanel(Transform parent)
    {
        var panelGo = new GameObject("TestControlPanel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(parent, false);

        var panelImg = panelGo.GetComponent<Image>();
        panelImg.color = new Color(0.08f, 0.11f, 0.18f, 0.92f);

        var rt = panelGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 0.5f);
        rt.anchorMax = new Vector2(0.5f, 0.5f);
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(340, 460);
        rt.anchoredPosition = new Vector2(200, 0);

        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        // Tiêu đề
        var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(panelGo.transform, false);
        var title = titleGo.GetComponent<Text>();
        title.font = font;
        title.fontSize = 18;
        title.fontStyle = FontStyle.Bold;
        title.text = "BẢNG ĐIỀU KHIỂN TƯỚNG";
        title.alignment = TextAnchor.MiddleCenter;
        title.color = new Color(1f, 0.82f, 0.3f, 1f);
        var titleRt = titleGo.GetComponent<RectTransform>();
        titleRt.anchorMin = new Vector2(0, 1);
        titleRt.anchorMax = new Vector2(1, 1);
        titleRt.pivot = new Vector2(0.5f, 1);
        titleRt.sizeDelta = new Vector2(0, 40);
        titleRt.anchoredPosition = new Vector2(0, -10);

        float btnY = -60f;
        float btnHeight = 34f;
        float spacing = 8f;

        CreateBtn(panelGo.transform, "Mất 1 Máu (Hoa Sen Tối)", new Vector2(0, btnY), new Color(0.7f, 0.2f, 0.2f, 1f), font, () => heroCard.TakeDamage(1));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Hồi 1 Máu (Hoa Sen Sáng)", new Vector2(0, btnY), new Color(0.2f, 0.6f, 0.3f, 1f), font, () => heroCard.Heal(1));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Đổi Phe Tướng", new Vector2(0, btnY), new Color(0.3f, 0.4f, 0.7f, 1f), font, CycleFaction);
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Trang Bị Vũ Khí (Bảo Đao)", new Vector2(0, btnY), new Color(0.65f, 0.5f, 0.15f, 1f), font, () => heroCard.Equip(EquipmentType.Weapon, "Long Uyên Đao"));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Trang Bị Giáp (Minh Quang Giáp)", new Vector2(0, btnY), new Color(0.35f, 0.45f, 0.65f, 1f), font, () => heroCard.Equip(EquipmentType.Armor, "Minh Quang Giáp"));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Trang Bị Ngựa Công (-1 Xích Thố)", new Vector2(0, btnY), new Color(0.75f, 0.35f, 0.2f, 1f), font, () => heroCard.Equip(EquipmentType.OffensiveMount, "Xích Thố (-1)"));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Trang Bị Ngựa Thủ (+1 Tuyệt Ảnh)", new Vector2(0, btnY), new Color(0.25f, 0.55f, 0.65f, 1f), font, () => heroCard.Equip(EquipmentType.DefensiveMount, "Tuyệt Ảnh (+1)"));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Tăng 1 Bài Trên Tay", new Vector2(0, btnY), new Color(0.2f, 0.5f, 0.65f, 1f), font, () => heroCard.SetHandCardCount(heroCard.HandCardCount + 1));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Giảm 1 Bài Trên Tay", new Vector2(0, btnY), new Color(0.5f, 0.35f, 0.4f, 1f), font, () => heroCard.SetHandCardCount(heroCard.HandCardCount - 1));
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "Gỡ Hết Trang Bị (Làm Sạch)", new Vector2(0, btnY), new Color(0.3f, 0.3f, 0.35f, 1f), font, () => heroCard.ClearAllEquipment());
        btnY -= (btnHeight + spacing);

        CreateBtn(panelGo.transform, "⚔️ MỞ TUTORIAL TRẬN CHIẾN", new Vector2(0, btnY), new Color(0.85f, 0.3f, 0.15f, 1f), font, () => {
            panelGo.SetActive(false);
            heroCard.gameObject.SetActive(false);
            TutorialBattleUI.Create(null);
        });
    }

    private void CycleFaction()
    {
        factionIndex = (factionIndex + 1) % factions.Length;
        heroCard.SetFaction(factions[factionIndex], factionColors[factionIndex]);
    }

    private Button CreateBtn(Transform parent, string label, Vector2 pos, Color btnColor, Font font, UnityEngine.Events.UnityAction onClick)
    {
        var btnGo = new GameObject("Btn_" + label, typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(parent, false);

        var img = btnGo.GetComponent<Image>();
        img.color = btnColor;

        var btn = btnGo.GetComponent<Button>();
        btn.onClick.AddListener(onClick);

        var rt = btnGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 1f);
        rt.anchorMax = new Vector2(0.5f, 1f);
        rt.pivot = new Vector2(0.5f, 1f);
        rt.sizeDelta = new Vector2(300, 32);
        rt.anchoredPosition = pos;

        var txtGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(btnGo.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 13;
        txt.fontStyle = FontStyle.Bold;
        txt.text = label;
        txt.color = Color.white;
        txt.alignment = TextAnchor.MiddleCenter;

        var txtRt = txtGo.GetComponent<RectTransform>();
        txtRt.anchorMin = Vector2.zero;
        txtRt.anchorMax = Vector2.one;
        txtRt.pivot = new Vector2(0.5f, 0.5f);
        txtRt.offsetMin = Vector2.zero;
        txtRt.offsetMax = Vector2.zero;

        return btn;
    }
}
