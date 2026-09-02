const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const t2 = `                var titleTxt = AddText(panelGo.transform, "Title", "🛡️ ĐẾN LƯỢT BẠN PHẢN HỒI", 26, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(600f, 38f), new Vector2(0, -10f));

        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 26, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 160f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 16;
        qTxt.resizeTextMaxSize = 26;

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s để quyết định...", 24, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400f, 32f), new Vector2(0, -200f));`;

const r2 = `        pRt.sizeDelta = new Vector2(950f, 380f);

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
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(400f, 32f), new Vector2(0, 95f));`;

let nCode = code.replace(/\r\n/g, '\n');
let nT2 = t2.replace(/\r\n/g, '\n');

if (nCode.includes(nT2)) {
    nCode = nCode.replace(nT2, r2);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: Nullify prompt Text setup fixed');
} else {
    console.log('FAILED TO FIND Nullify prompt Text setup');
}
