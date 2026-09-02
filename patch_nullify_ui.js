const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const targetStr = `        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 30, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 220f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = false;
        qTxt.resizeTextMaxSize = 28;

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s để quyết định...", 24, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400f, 32f), new Vector2(0, -200f));`;

const replacement = `        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 26, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 160f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 16;
        qTxt.resizeTextMaxSize = 26;

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s để quyết định...", 24, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(400f, 32f), new Vector2(0, -200f));`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: FIXED Nullify UI Layout');
} else {
    console.log('FAILED TO FIND Nullify Layout');
}
