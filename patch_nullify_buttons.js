const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const t2 = `        var uRt = useBtnGo.GetComponent<RectTransform>();
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

const r2 = `        var uRt = useBtnGo.GetComponent<RectTransform>();
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
let nT2 = t2.replace(/\r\n/g, '\n');

if (nCode.includes(nT2)) {
    nCode = nCode.replace(nT2, r2);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: Nullify prompt Button setup fixed');
} else {
    console.log('FAILED TO FIND Nullify prompt Button setup');
}
