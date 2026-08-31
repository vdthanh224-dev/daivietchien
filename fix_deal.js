const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

// First replace the player hand update logic
code = code.replace(
  playerHandUI.ClearHand();\n                        playerHandUI.AddCards(playerHandCards);,
  playerHandUI.ClearHand();\n                        if (diff <= 0) playerHandUI.AddCards(playerHandCards);
);

// Then modify AnimateMultipleDealtCards to add cards for the player
code = code.replace(
  private IEnumerator AnimateMultipleDealtCards(GeneralCardUI targetGeneral, int count)\n    {\n        for (int i = 0; i < count; i++)\n        {\n            yield return AnimateDealtCard(targetGeneral);\n            yield return new WaitForSeconds(0.05f);\n        }\n    },
  private IEnumerator AnimateMultipleDealtCards(GeneralCardUI targetGeneral, int count, List<CardModel> myNewCards = null)\n    {\n        for (int i = 0; i < count; i++)\n        {\n            yield return AnimateDealtCard(targetGeneral);\n            if (myNewCards != null && i < myNewCards.Count && targetGeneral.SeatNumber == (playerCard != null ? playerCard.SeatNumber : -1)) {\n                playerHandUI.AddCard(myNewCards[i]);\n            }\n            yield return new WaitForSeconds(0.05f);\n        }\n        if (myNewCards != null && count > 0 && targetGeneral.SeatNumber == (playerCard != null ? playerCard.SeatNumber : -1)) {\n            UpdateHandCountsVisual();\n        }\n    }
);

// Then update the call to AnimateMultipleDealtCards for the player
code = code.replace(
  if (myServerData.hand.Count > playerHandCards.Count)\n                        {\n                            int diff = myServerData.hand.Count - playerHandCards.Count;\n                            StartCoroutine(AnimateMultipleDealtCards(playerCard, diff));\n                        },
  List<CardModel> newDealtCards = null;\n                        if (myServerData.hand.Count > playerHandCards.Count)\n                        {\n                            int diff = myServerData.hand.Count - playerHandCards.Count;\n                            newDealtCards = new List<CardModel>();\n                            for (int i = playerHandCards.Count; i < myServerData.hand.Count; i++) {\n                                var sc = myServerData.hand[i];\n                                if (sc != null && sc.id != \"HIDDEN\") {\n                                    var cm = ConvertGameStateCardToCardModel(sc);\n                                    if (cm != null) newDealtCards.Add(cm);\n                                }\n                            }\n                            StartCoroutine(AnimateMultipleDealtCards(playerCard, diff, newDealtCards));\n                        }
);

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
