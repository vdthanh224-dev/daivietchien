const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/Battle2v2UI.cs', 'utf8');

code = code.replace(
  'private int lastAppliedStateVersion = -1;',
  'private int lastAppliedStateVersion = -1;\n    private int lastProcessedActionSeq = 0;'
);

const regex = /void ApplyServerStateDelta\(AppwriteMatchmaking\.GameStateDelta delta\)[\s\S]*?actionInProgress = false;/;
const replaceStr = `void ApplyServerStateDelta(AppwriteMatchmaking.GameStateDelta delta)
    {
        if (delta == null) return;
        if (delta.version < lastAppliedStateVersion) return;
        // Do NOT update lastAppliedStateVersion here so ApplyServerGameState can still run!
        currentAuthoritativePhase = delta.phase ?? "";
        currentAuthoritativeWaitingSeat = delta.waitingTargetSeat;
        currentAuthoritativeTurnSeat = delta.turnSeat;
        slashesUsedThisTurn = delta.slashesUsedThisTurn;
        actionInProgress = false;

        if (delta.actionSeq > lastProcessedActionSeq)
        {
            lastProcessedActionSeq = delta.actionSeq;
            ProcessServerActionAnimation(delta);
        }`;

code = code.replace(regex, replaceStr);

const appendMethod = `
    private void ProcessServerActionAnimation(AppwriteMatchmaking.GameStateDelta delta)
    {
        if (delta == null || string.IsNullOrEmpty(delta.type)) return;
        
        string type = delta.type;
        var actCard = delta.activeCard;
        
        // Cố gắng tìm card model tương ứng để lấy âm thanh và hình ảnh
        CardModel cm = null;
        GeneralCardUI caster = null;
        GeneralCardUI target = null;

        if (actCard != null) {
            cm = CardDatabase.GetCardById(actCard.cardId);
            if (cm == null && !string.IsNullOrEmpty(actCard.cardId)) {
                CardSuit s = CardSuit.Heart;
                Enum.TryParse(actCard.suit, out s);
                cm = new CardModel { id = actCard.cardId, cardName = actCard.cardName, suit = s };
            }
            caster = GetGeneralBySeat(actCard.casterSeat);
            target = GetGeneralBySeat(actCard.targetSeat);
        }
        
        if (type == "PLAY_SLASH" && cm != null && caster != null) {
            StartCoroutine(AnimateSlashAttack(cm, caster, target));
        } else if (type == "PLAY_PEACH" || type == "PLAY_WINE" || type == "EQUIP" || type.StartsWith("PLAY_")) {
            if (cm != null && caster != null) {
                ShowCardAtCenter(cm, caster, target);
            }
        } else if (type == "NULLIFY_PLAYED" || type == "RESCUE_SUCCESS" || type == "DUEL_RESPOND" || type == "AOE_DEFENDED" || type == "KHIEN_MAY_SUCCESS") {
            // These usually don't have activeCard in delta because activeCard is the original card.
            // But we can just play a sound based on the type.
            if (type == "NULLIFY_PLAYED") AudioManager.Instance.PlaySkill();
            if (type == "RESCUE_SUCCESS") AudioManager.Instance.PlayHeal();
            if (type == "AOE_DEFENDED" || type == "KHIEN_MAY_SUCCESS") AudioManager.Instance.PlayParry();
        }
    }
`;

// Insert the method right before `private IEnumerator StartDiscardPhase`
code = code.replace(/private IEnumerator StartDiscardPhase/, appendMethod + '\n    private IEnumerator StartDiscardPhase');

fs.writeFileSync('Assets/Scripts/Battle2v2UI.cs', code);
console.log("Patched action animations");
