const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

// There are compilation errors about `GeneralCardUI` not containing `Data`.
// Let's check `GeneralCardUI.cs` to see what the actual name is.
