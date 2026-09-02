const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const t2 = `                var qTxt = AddText(panelGo.transform, "Question", $"<i>{questionText}</i>", 28, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 220f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = false;`;

const r2 = `                var qTxt = AddText(panelGo.transform, "Question", $"<i>{questionText}</i>", 24, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 160f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 16;
        qTxt.resizeTextMaxSize = 24;`;

let nCode = code.replace(/\r\n/g, '\n');
let nT2 = t2.replace(/\r\n/g, '\n');

if (nCode.includes(nT2)) {
    nCode = nCode.replace(nT2, r2);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: FIXED Nullify Wait UI Layout');
} else {
    console.log('FAILED TO FIND Nullify Wait Layout');
}
