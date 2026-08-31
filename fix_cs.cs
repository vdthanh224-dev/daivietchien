using System;
using System.IO;

class Program
{
    static void Main()
    {
        string path = "Assets/Scripts/Battle2v2UI.cs";
        string content = File.ReadAllText(path);

        string search = @"else if ((actType.StartsWith(""PLAY_"") || actType == ""EQUIP"" || actType == ""DELAYED_SCROLL_ATTACHED"") && !string.IsNullOrEmpty(act.cardId))
                    {
                        var casterGen = GetGeneralBySeat(act.casterSeat);
                            var targetGen = GetGeneralBySeat(act.targetSeat);
                            var card = CardDatabase.GetCardById(act.cardId);
                            if (casterGen != null && card != null)
                            {
                                if (actType == ""EQUIP"")
                                    ShowCardAtCenter(card, casterGen, targetGen, $""Trang bị [{card.cardName]"");
                                else
                                    ShowCardAtCenter(card, casterGen, targetGen);
                            }
                        }
                    }";
        
        string replace = @"else if ((actType.StartsWith(""PLAY_"") || actType == ""EQUIP"" || actType == ""DELAYED_SCROLL_ATTACHED"") && !string.IsNullOrEmpty(act.cardId))
                    {
                        var casterGen = GetGeneralBySeat(act.casterSeat);
                        var targetGen = GetGeneralBySeat(act.targetSeat);
                        var card = CardDatabase.GetCardById(act.cardId);
                        if (casterGen != null && card != null)
                        {
                            if (actType == ""EQUIP"")
                                ShowCardAtCenter(card, casterGen, targetGen, $""Trang bị [{card.cardName}]"");
                            else
                                ShowCardAtCenter(card, casterGen, targetGen);
                        }
                    }";
                    
        content = content.Replace(search, replace);
        
        File.WriteAllText(path, content);
    }
}
