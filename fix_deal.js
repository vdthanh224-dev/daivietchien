const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(
  /int diff = myServerData\.hand\.Count - playerHandCards\.Count;\s*if \(diff > 0\)\s*\{\s*StartCoroutine\(AnimateMultipleDealtCards\(playerCard, diff\)\);\s*\}/,
  'int diff = myServerData.hand.Count - playerHandCards.Count;\n                        if (diff > 0)\n                        {\n                            var newDealtCards = new System.Collections.Generic.List<CardModel>();\n                            for (int i = playerHandCards.Count; i < myServerData.hand.Count; i++) {\n                                var sc = myServerData.hand[i];\n                                if (sc != null && sc.id != "HIDDEN") {\n                                    var cm = ConvertGameStateCardToCardModel(sc);\n                                    if (cm != null) newDealtCards.Add(cm);\n                                }\n                            }\n                            StartCoroutine(AnimateMultipleDealtCards(playerCard, diff, newDealtCards));\n                        }'
);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
