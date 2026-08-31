const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

const regex = /var titleTxt = AddText\(panelGo\.transform, "Title", promptTitle, 24, ThemeUI\.GoldHighlight, FontStyle\.Bold, TextAnchor\.MiddleCenter\);[\s\S]*?titleTxt\.resizeTextMaxSize = 30;/;

const replaceStr = `var titleTxt = AddText(panelGo.transform, "Title", "🛡️ ĐẾN LƯỢT BẠN PHẢN HỒI", 26, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(600f, 38f), new Vector2(0, -10f));

        var qTxt = AddText(panelGo.transform, "Question", $"<i>{promptTitle}</i>", 22, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(qTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(850f, 160f), new Vector2(0, -100f)); 
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap; 
        qTxt.verticalOverflow = VerticalWrapMode.Overflow;
        qTxt.resizeTextForBestFit = true;
        qTxt.resizeTextMinSize = 14;
        qTxt.resizeTextMaxSize = 28;`;

if (regex.test(code)) {
    code = code.replace(regex, replaceStr);
    fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
    console.log("Patched CounterPromptModal text format");
} else {
    console.log("Target not found");
}
