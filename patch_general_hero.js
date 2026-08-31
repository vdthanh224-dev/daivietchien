const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/GeneralCardUI.cs', 'utf8');

const insertPoint = code.indexOf('public void OnPointerClick(');
const insertCode = `
    public string HeroId
    {
        get 
        { 
            var heroData = HeroDatabase100.GetHeroByName(generalName);
            return heroData != null ? heroData.id : "";
        }
    }
`;

code = code.substring(0, insertPoint) + insertCode + code.substring(insertPoint);
fs.writeFileSync('Assets/Scripts/GeneralCardUI.cs', code);
console.log("Added HeroId to GeneralCardUI");
