const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const targetStr = `        pRt.sizeDelta = new Vector2(900f, 320f);
        pRt.anchoredPosition = new Vector2(-80f, 120f);

        var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        fGo.transform.SetParent(panelGo.transform, false);
        var fImg = fGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = ThemeUI.GoldPrimary;
        fImg.raycastTarget = false;
        Fill(fGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

                var titleTxt = AddText(panelGo.transform, "Title", "🛡️ ĐẾN LƯỢT BẠN PHẢN HỒI", 26, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(600f, 38f), new Vector2(0, -10f));

        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 26, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 160f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 16;
        qTxt.resizeTextMaxSize = 26;

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s để quyết định...", 24, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400f, 32f), new Vector2(0, -200f));

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

        var useBtnGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
        useBtnGo.transform.SetParent(panelGo.transform, false);
        var uImg = useBtnGo.GetComponent<Image>();
        if (btnSpr != null) { uImg.sprite = btnSpr; uImg.type = Image.Type.Sliced; }

        bool hasCounterCard = counterCard != null;
        uImg.color = hasCounterCard ? ThemeUI.JadeGreen : new Color(0.35f, 0.38f, 0.45f, 0.7f);
        var uRt = useBtnGo.GetComponent<RectTransform>();
        SetRect(uRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(270f, 42f), new Vector2(-140f, 24f));

        var uTxt = AddText(useBtnGo.transform, "Txt", hasCounterCard ? "🛡️ DÙNG DIỆU KẾ PHÁ MƯU" : "🛡️ KHÔNG CÓ DIỆU KẾ", 18, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(uTxt.rectTransform);

        var passBtnGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passBtnGo.transform.SetParent(panelGo.transform, false);
        var paImg = passBtnGo.GetComponent<Image>();
        if (btnSpr != null) { paImg.sprite = btnSpr; paImg.type = Image.Type.Sliced; }
        paImg.color = new Color(0.55f, 0.45f, 0.25f, 1f);
        var paRt = passBtnGo.GetComponent<RectTransform>();
        SetRect(paRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(230f, 42f), new Vector2(150f, 16f));`;

const replacement = `        pRt.sizeDelta = new Vector2(950f, 380f);
        pRt.anchoredPosition = new Vector2(-80f, 120f);

        var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        fGo.transform.SetParent(panelGo.transform, false);
        var fImg = fGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = ThemeUI.GoldPrimary;
        fImg.raycastTarget = false;
        Fill(fGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var titleTxt = AddText(panelGo.transform, "Title", "🛡️ ĐẾN LƯỢT BẠN PHẢN HỒI", 26, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(600f, 38f), new Vector2(0, -15f));

        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 30, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(900f, 200f), new Vector2(0, -140f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 18;
        qTxt.resizeTextMaxSize = 30;

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s để quyết định...", 24, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(400f, 32f), new Vector2(0, 95f));

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

        var useBtnGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
        useBtnGo.transform.SetParent(panelGo.transform, false);
        var uImg = useBtnGo.GetComponent<Image>();
        if (btnSpr != null) { uImg.sprite = btnSpr; uImg.type = Image.Type.Sliced; }

        bool hasCounterCard = counterCard != null;
        uImg.color = hasCounterCard ? ThemeUI.JadeGreen : new Color(0.35f, 0.38f, 0.45f, 0.7f);
        var uRt = useBtnGo.GetComponent<RectTransform>();
        SetRect(uRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(300f, 50f), new Vector2(-160f, 30f));

        var uTxt = AddText(useBtnGo.transform, "Txt", hasCounterCard ? "🛡️ DÙNG DIỆU KẾ PHÁ MƯU" : "🛡️ KHÔNG CÓ DIỆU KẾ", 18, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(uTxt.rectTransform);

        var passBtnGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passBtnGo.transform.SetParent(panelGo.transform, false);
        var paImg = passBtnGo.GetComponent<Image>();
        if (btnSpr != null) { paImg.sprite = btnSpr; paImg.type = Image.Type.Sliced; }
        paImg.color = new Color(0.55f, 0.45f, 0.25f, 1f);
        var paRt = passBtnGo.GetComponent<RectTransform>();
        SetRect(paRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(250f, 50f), new Vector2(150f, 30f));`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: FIXED Nullify UI Layout (PromptPlayerCounterScroll)');
} else {
    console.log('FAILED TO FIND Nullify Layout');
}
