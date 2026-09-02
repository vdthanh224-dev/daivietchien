const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const targetStr = `                var qTxt = AddText(panelGo.transform, "Question", $"<i>{questionText}</i>", 20, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 220f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 14;`;

const replacement = `                var qTxt = AddText(panelGo.transform, "Question", $"<i>{questionText}</i>", 28, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 220f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = false;`;

let nCode = code.replace(/\r\n/g, '\n');
let nTarget = targetStr.replace(/\r\n/g, '\n');

if (nCode.includes(nTarget)) {
    nCode = nCode.replace(nTarget, replacement);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', nCode, 'utf8');
    console.log('SUCCESS: Nullify Wait font fix');
} else {
    console.log('FAILED TO FIND Nullify Wait font string');
}
