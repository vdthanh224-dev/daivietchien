using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Màn hình Chiến Trận Hướng Dẫn (Tutorial Battle Screen)
/// Kịch bản hướng dẫn chuẩn xác & trực quan:
/// 1. Hướng dẫn Sinh mệnh (Hoa sen) & Điều kiện thắng/thua.
/// 2. Hướng dẫn Giai đoạn Rút bài: Lượt đầu bốc 1 lá, các lượt sau bốc 2 lá.
/// 3. Hướng dẫn Giai đoạn Ra bài: Cách chọn lá TRẢM và nhắm mục tiêu để tấn công.
/// 4. Hướng dẫn Quy tắc: Mỗi turn chỉ được dùng tối đa 1 lá TRẢM (trừ Nỏ Thần).
/// 5. Hướng dẫn Phòng thủ: Khi Sơn Tặc dùng Trảm, hướng dẫn dùng lá ĐỠ (Né) để triệt tiêu đòn đánh.
/// 6. Hoàn thành tân thủ & Mở khóa tự do thực chiến.
/// </summary>
public class TutorialBattleUI : MonoBehaviour
{
    public enum TutorialStep
    {
        HealthIntro,          // Bước 1: Máu hoa sen
        InitialDealing,       // Chia 4 lá khởi đầu
        DrawTwoAtTurnStart,   // Bước 2: Đầu lượt tự động bốc 2 lá
        PlaySlashLesson,      // Bước 3: Dùng Trảm tấn công Sơn Tặc
        OneSlashPerTurnRule,  // Bước 4: Mỗi turn chỉ được dùng 1 lá Trảm
        SkillTienThoaiLesson, // Bước 4.5: Kỹ năng Tiến Thoái của Lý Thường Kiệt
        DiscardPhaseLesson,   // Bước 4.8: Giai đoạn bỏ bài để số bài <= số máu
        BossTurnAndDodge,     // Bước 5: Sơn Tặc ra Trảm -> Dùng Đỡ né
        FreeBattleUnlocked    // Bước 6: Tự do thực chiến
    }

    private GeneralCardUI playerCard;
    private GeneralCardUI bossCard;
    private PlayerHandUI playerHandUI;
    private CardDeckManager deckManager;

    private Text dialogText;
    private Text deckInfoText;
    private Text cardDescBar;

    private GameObject spotlightOverlay;
    private RectTransform arrowBossRt;
    private RectTransform arrowPlayerRt;
    private Vector2 arrowBossBasePos;
    private Vector2 arrowPlayerBasePos;

    private GameObject deckHudGo;
    private GameObject historyOverlayGo;
    private ScrollRect historyScrollRect;

    // Overlay hướng dẫn từng bước
    private GameObject tutorialStepOverlay;
    private GameObject tutorialMaskGo;
    private Text tutorialPromptText;
    private GameObject tutorialActionBtn;
    private Text tutorialActionBtnText;
    private RectTransform tutorialArrowRt;
    private Vector2 tutorialArrowBasePos;
    private Text tutorialArrowLabel;
    private Image tutorialTargetBorder;
    private Image tutorialBorderLight;
    private GameObject tutorialTargetHitbox;

    private readonly List<string> actionHistory = new List<string>();
    private TutorialStep currentStep = TutorialStep.HealthIntro;
    private int slashesUsedThisTurn = 0;
    private bool isPlayerTurn = true;
    private bool isAwaitingDodge = false;
    private bool isWineBuffActive = false;
    private bool duelResponseActive = false;
    // Trầm Ảo locks only the player's play phase; ending the turn remains allowed.
    private bool playerPlayPhaseLocked = false;
    // A separate guard is needed while the mandatory judgement/draw phases
    // are resolving: Trầm Ảo may leave the play phase locked, but the player
    // must still be allowed to end that turn afterward.
    private bool playerTurnStartResolving = false;
    // Prevent a second active card from starting while the current card's
    // animation, reaction window, or modal is still being resolved.
    private bool playerActionResolving = false;
    private bool gameFinished = false;
    private bool playerRescuePending = false;
    private bool counterPromptActive = false;
    private CardModel pendingBossSlash = null;
    private GameObject bossIncomingCardGo = null;
    private GameObject currentCenterCardGo = null;

    private bool slashDefenseActive = false;
    private bool globalDefenseActive = false;
    private CardSubType? currentGlobalDefType = null;
    private Action<CardUI> onCurrentReactionCardSelected = null;
    private bool freePlayDiscardPhaseActive = false;

    private void SetPlayerTurn(bool active)
    {
        isPlayerTurn = active;
        if (!active)
        {
            freePlayDiscardPhaseActive = false;
        }
        if (freePlayEndTurnBtnGo != null)
        {
            freePlayEndTurnBtnGo.SetActive(active && currentStep == TutorialStep.FreeBattleUnlocked && !gameFinished);
        }
        if (!active && freePlayActionBtnGo != null)
        {
            freePlayActionBtnGo.SetActive(false);
        }
    }
    private Coroutine centerCardDismissCoroutine = null;
    // Keep card-pick modals tied to the action coroutine that opened them.
    private GameObject activeCardPickModal = null;
    private readonly List<CardModel> bossHandCards = new List<CardModel>();

    private enum TargetCardZone
    {
        Hand,
        Equipment,
        Delayed
    }

    // Result of a defensive reaction.  Keeping this separate from the UI
    // coroutine lets weapon follow-up effects run for either defender.
    private enum SlashDefenseResult
    {
        Hit,
        Dodged,
        Negated
    }

    private sealed class TargetCardOption
    {
        public CardModel Card;
        public TargetCardZone Zone;
        public EquipmentType EquipmentType;
        public CardSubType DelayedType;
        public string Label;
    }

    private void BossAddHandCard(CardModel card)
    {
        if (card == null) return;
        bossHandCards.Add(card);
        bossCard.SetHandCardCount(bossHandCards.Count);
    }

    private CardModel BossPopHandCard(Predicate<CardModel> predicate = null)
    {
        if (bossHandCards.Count == 0) return null;
        int idx = (predicate != null) ? bossHandCards.FindIndex(predicate) : 0;
        if (idx < 0) return null;
        var c = bossHandCards[idx];
        bossHandCards.RemoveAt(idx);
        bossCard.SetHandCardCount(bossHandCards.Count);
        return c;
    }

    private bool BossRemoveSpecificCard(CardModel card)
    {
        if (card == null) return false;
        int index = bossHandCards.FindIndex(c => ReferenceEquals(c, card));
        if (index < 0 && !string.IsNullOrEmpty(card.id))
        {
            index = bossHandCards.FindIndex(c => c != null && c.id == card.id);
        }
        if (index < 0) return false;
        bossHandCards.RemoveAt(index);
        bossCard.SetHandCardCount(bossHandCards.Count);
        return true;
    }

    /// <summary>
    /// Picks a legal Dodge for a Slash. Súng Thần Công forbids only the
    /// matching-suit Dodge; forbidden cards remain in the hand.
    /// </summary>
    private CardModel BossPopLegalDodge(CardModel slashCard, GeneralCardUI attacker)
    {
        for (int i = 0; i < bossHandCards.Count; i++)
        {
            var candidate = bossHandCards[i];
            if (!IsDodgeCard(candidate)) continue;
            if (attacker != null && attacker.HasEquipment(EquipmentType.Weapon, "Súng Thần Công") &&
                slashCard != null && candidate.suit == slashCard.suit)
            {
                continue;
            }

            bossHandCards.RemoveAt(i);
            bossCard.SetHandCardCount(bossHandCards.Count);
            return candidate;
        }

        return null;
    }

    private IEnumerator BossDrawCardsFromDeck(int count = 1)
    {
        for (int i = 0; i < count; i++)
        {
            var card = deckManager.DrawCard();
            if (card != null)
            {
                yield return AnimateDealtCard(false);
                BossAddHandCard(card);
                yield return new WaitForSeconds(0.1f);
            }
        }
    }

    // Các thành phần điều khiển thực chiến tự do
    private GameObject freePlayActionBtnGo;
    private Text freePlayActionBtnText;
    private GameObject freePlayEndTurnBtnGo;
    private GeneralCardUI currentTargetCard;
    private GameObject freePlayBossTargetBorder;
    private GameObject freePlayBossHitbox;

    public GeneralCardUI PlayerCard => playerCard;
    public GeneralCardUI BossCard => bossCard;
    public PlayerHandUI HandUI => playerHandUI;
    public TutorialStep CurrentStep => currentStep;

    private Action onTutorialComplete;

    public static TutorialBattleUI Create(Transform parent = null, Action onComplete = null)
    {
        // Xóa bất kỳ TutorialBattleUI cũ nào nếu đang tồn tại
        var existing = FindFirstObjectByType<TutorialBattleUI>();
        if (existing != null) Destroy(existing.gameObject);

        GameObject go;
        if (parent == null)
        {
            go = new GameObject("TutorialBattleUI", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = go.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 50;

            var scaler = go.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280, 720);
            scaler.matchWidthOrHeight = 0.5f;
        }
        else
        {
            go = new GameObject("TutorialBattleUI", typeof(RectTransform));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
        }

        var battleUI = go.AddComponent<TutorialBattleUI>();
        battleUI.onTutorialComplete = onComplete;
        return battleUI;
    }

    private void Start()
    {
        deckManager = gameObject.AddComponent<CardDeckManager>();
        deckManager.InitializeDeck(52); // Bộ bài 1: 52 lá chuẩn

        BuildBattlefield();
        BuildDeckStatusHUD();
        BuildPlayerHand();

        // Khởi động nhạc nền
        AudioManager.Instance.PlayBGM();

        // Bước 1: Hiển thị bảng hướng dẫn Máu Hoa Sen & Quy tắc Sinh Tử
        BuildHealthSpotlightTutorial();
    }

    private void Update()
    {
        // Hiệu ứng nhấp nhô mũi tên hướng dẫn máu
        if (spotlightOverlay != null && spotlightOverlay.activeSelf)
        {
            float bob = Mathf.Sin(Time.time * 6f) * 8f;
            if (arrowBossRt != null)
                arrowBossRt.anchoredPosition = arrowBossBasePos + new Vector2(-bob, 0);
            if (arrowPlayerRt != null)
                arrowPlayerRt.anchoredPosition = arrowPlayerBasePos + new Vector2(-bob, 0);
        }

        // Hiệu ứng nhấp nhô mũi tên hướng dẫn thao tác
        if (tutorialStepOverlay != null && tutorialStepOverlay.activeSelf && tutorialArrowRt != null)
        {
            float bob = Mathf.Sin(Time.time * 6f) * 8f;
            tutorialArrowRt.anchoredPosition = tutorialArrowBasePos + new Vector2(-bob, 0);

            if (tutorialTargetBorder != null)
            {
                float pulse = 0.65f + 0.35f * (0.5f + 0.5f * Mathf.Sin(Time.time * 5f));
                tutorialTargetBorder.color = new Color(1f, 0.78f, 0.16f, pulse);
            }
        }
    }

    #region 1. BATTLEFIELD SETUP
    private void BuildBattlefield()
    {
        var font = ThemeUI.FontMain;

        // 1. Nền chiến trường
        var bgGo = new GameObject("BattleBackground", typeof(RectTransform), typeof(RawImage));
        bgGo.transform.SetParent(transform, false);
        var bgImg = bgGo.GetComponent<RawImage>();
        var bgTex = Resources.Load<Texture2D>("UI/login_background");
        if (bgTex != null) bgImg.texture = bgTex;
        bgImg.color = new Color(0.35f, 0.35f, 0.4f, 1f);
        var bgRt = bgGo.GetComponent<RectTransform>();
        Fill(bgRt);

        // 2. THỦ LĨNH SƠN TẶC: Top Center, 3 Máu (80% kích thước = 184x245)
        var bossSize = new Vector2(184, 245);
        bossCard = GeneralCardUI.Create(transform, bossSize, "Thủ Lĩnh Sơn Tặc", "Sơn Tặc", 3, 3, "UI/thu_linh_son_tac");
        bossCard.SetFaction("Sơn Tặc", new Color(0.65f, 0.25f, 0.15f, 0.95f));
        bossCard.SetHandCardCount(0);
        bossCard.SetJudgementZonePlacement(true, new Vector2(8f, 0f));
        var bossRt = bossCard.GetComponent<RectTransform>();
        bossRt.anchorMin = new Vector2(0.5f, 1f);
        bossRt.anchorMax = new Vector2(0.5f, 1f);
        bossRt.pivot = new Vector2(0.5f, 1f);
        bossRt.sizeDelta = bossSize;
        bossRt.anchoredPosition = new Vector2(50f, -14f);

        // 3. LÝ THƯỜNG KIỆT (NGƯỜI CHƠI): Bottom Right, 4 Máu (80% kích thước = 184x245)
        var playerSize = new Vector2(184, 245);
        playerCard = GeneralCardUI.Create(transform, playerSize, "Lý Thường Kiệt", "Khác", 4, 4, "UI/ly_thuong_kiet");
        playerCard.SetFaction("Khác", new Color(0.52f, 0.18f, 0.62f, 0.95f));
        playerCard.SetHandCardCount(0);
        playerCard.SetSkill("⚡ TIẾN THOÁI", OnPlayerSkillTienThoaiClicked);
        playerCard.SetJudgementZonePlacement(false, new Vector2(0f, 6f));
        var playerRt = playerCard.GetComponent<RectTransform>();
        playerRt.anchorMin = new Vector2(1f, 0f);
        playerRt.anchorMax = new Vector2(1f, 0f);
        playerRt.pivot = new Vector2(1f, 0f);
        playerRt.sizeDelta = playerSize;
        playerRt.anchoredPosition = new Vector2(-18f, 18f);

        // 4. Bảng Lịch sử dùng bài
        BuildActionHistoryPanel(font);

        // Đăng ký sự kiện click chọn mục tiêu trên các Tướng
        bossCard.OnGeneralClicked += OnGeneralCardClicked;
        playerCard.OnGeneralClicked += OnGeneralCardClicked;
    }

    private void BuildDeckStatusHUD()
    {
        var font = ThemeUI.FontMain;

        deckHudGo = new GameObject("DeckStatusHUD", typeof(RectTransform));
        deckHudGo.transform.SetParent(transform, false);
        var rt = deckHudGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(1f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.pivot = new Vector2(1f, 1f);
        rt.sizeDelta = new Vector2(68f, 92f);
        rt.anchoredPosition = new Vector2(-18f, -18f);

        // Lớp bóng đổ / đáy xấp bài (Layer 1 - Offset 4px)
        var shadowCardGo = new GameObject("DeckShadow", typeof(RectTransform), typeof(Image));
        shadowCardGo.transform.SetParent(deckHudGo.transform, false);
        var sImg = shadowCardGo.GetComponent<Image>();
        var bgCardSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_back_bg");
        if (bgCardSpr != null) { sImg.sprite = bgCardSpr; sImg.type = Image.Type.Sliced; }
        sImg.color = new Color(0.04f, 0.06f, 0.1f, 0.75f);
        var sRt = shadowCardGo.GetComponent<RectTransform>();
        sRt.anchorMin = Vector2.zero; sRt.anchorMax = Vector2.one;
        sRt.offsetMin = new Vector2(-4f, -4f); sRt.offsetMax = new Vector2(-4f, -4f);

        // Lớp thân giữa xấp bài (Layer 2 - Offset 2px)
        var midCardGo = new GameObject("DeckMid", typeof(RectTransform), typeof(Image));
        midCardGo.transform.SetParent(deckHudGo.transform, false);
        var mImg = midCardGo.GetComponent<Image>();
        if (bgCardSpr != null) { mImg.sprite = bgCardSpr; mImg.type = Image.Type.Sliced; }
        mImg.color = new Color(0.12f, 0.18f, 0.3f, 0.95f);
        var mRt = midCardGo.GetComponent<RectTransform>();
        mRt.anchorMin = Vector2.zero; mRt.anchorMax = Vector2.one;
        mRt.offsetMin = new Vector2(-2f, -2f); mRt.offsetMax = new Vector2(-2f, -2f);

        // Lớp bài trên cùng (Top Card)
        var topCardGo = new GameObject("DeckTop", typeof(RectTransform), typeof(Image));
        topCardGo.transform.SetParent(deckHudGo.transform, false);
        var topImg = topCardGo.GetComponent<Image>();
        if (bgCardSpr != null) { topImg.sprite = bgCardSpr; topImg.type = Image.Type.Sliced; }
        topImg.color = Color.white;
        Fill(topCardGo.GetComponent<RectTransform>());

        // Viền hoàng kim cho lá bài trên cùng
        var frameGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        frameGo.transform.SetParent(topCardGo.transform, false);
        var fImg = frameGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        Fill(frameGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        // Bảng số lượng bài còn lại ở chân chồng bài
        var plaqueGo = new GameObject("Plaque", typeof(RectTransform), typeof(Image));
        plaqueGo.transform.SetParent(deckHudGo.transform, false);
        var pImg = plaqueGo.GetComponent<Image>();
        var pSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (pSpr != null) { pImg.sprite = pSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.06f, 0.09f, 0.16f, 0.96f);
        var pRt = plaqueGo.GetComponent<RectTransform>();
        pRt.anchorMin = new Vector2(0f, 0f); pRt.anchorMax = new Vector2(1f, 0f);
        pRt.pivot = new Vector2(0.5f, 0f);
        pRt.sizeDelta = new Vector2(0f, 22f);
        pRt.anchoredPosition = new Vector2(0f, 0f);

        var pFrameGo = new GameObject("PFrame", typeof(RectTransform), typeof(Image));
        pFrameGo.transform.SetParent(plaqueGo.transform, false);
        var pfImg = pFrameGo.GetComponent<Image>();
        if (fSpr != null) { pfImg.sprite = fSpr; pfImg.type = Image.Type.Sliced; }
        pfImg.color = new Color(1f, 0.85f, 0.35f, 0.8f);
        Fill(pFrameGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var txtGo = new GameObject("DeckText", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(plaqueGo.transform, false);
        deckInfoText = txtGo.GetComponent<Text>();
        deckInfoText.font = font;
        deckInfoText.fontSize = 12;
        deckInfoText.fontStyle = FontStyle.Bold;
        deckInfoText.color = new Color(1f, 0.88f, 0.35f, 1f);
        deckInfoText.alignment = TextAnchor.MiddleCenter;
        Fill(txtGo.GetComponent<RectTransform>());

        deckManager.OnDeckCountsChanged += UpdateDeckHUD;
        deckManager.OnDeckReshuffled += HandleDeckReshuffled;
        UpdateDeckHUD(deckManager.DrawPileCount, deckManager.DiscardPileCount);
        deckHudGo.SetActive(true);
    }

    private void UpdateDeckHUD(int drawCount, int discardCount)
    {
        if (deckInfoText != null)
        {
            deckInfoText.text = $"🎴 {drawCount}";
        }
    }

    private void HandleDeckReshuffled()
    {
        SetLog("🔄 <color=#FFD700><b>KHO BÀI ĐÃ ĐƯỢC XÁO LẠI!</b></color> Xấp bài đã dùng được xáo lại.");
    }

    private void BuildPlayerHand()
    {
        var handGo = new GameObject("PlayerHand", typeof(RectTransform), typeof(PlayerHandUI));
        handGo.transform.SetParent(transform, false);
        playerHandUI = handGo.GetComponent<PlayerHandUI>();
        playerHandUI.BindHeroCard(playerCard);

        var rt = handGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0.5f, 0f);
        rt.anchorMax = new Vector2(0.5f, 0f);
        rt.pivot = new Vector2(0.5f, 0f);
        rt.sizeDelta = new Vector2(620, 170);
        rt.anchoredPosition = new Vector2(-70f, 20f);

        playerHandUI.OnCardPlayed += HandleCardPlayed;
        playerHandUI.OnCardSelected += HandleCardSelected;
        playerHandUI.OnSelectionChanged += HandleSelectionChanged;

        BuildCardDescBar();
    }

    private void BuildCardDescBar()
    {
        var font = ThemeUI.FontMain;

        var barGo = new GameObject("CardDescBar", typeof(RectTransform), typeof(Image));
        barGo.transform.SetParent(transform, false);
        var barImg = barGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSprite != null) { barImg.sprite = bgSprite; barImg.type = Image.Type.Sliced; }
        barImg.color = new Color(0.07f, 0.11f, 0.19f, 0.93f);

        var barRt = barGo.GetComponent<RectTransform>();
        barRt.anchorMin = new Vector2(0.5f, 0f);
        barRt.anchorMax = new Vector2(0.5f, 0f);
        barRt.pivot = new Vector2(0.5f, 0f);
        barRt.sizeDelta = new Vector2(680, 30);
        barRt.anchoredPosition = new Vector2(-70f, 198f);

        var txtGo = new GameObject("DescText", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(barGo.transform, false);
        cardDescBar = txtGo.GetComponent<Text>();
        cardDescBar.font = font;
        cardDescBar.fontSize = 12;
        cardDescBar.fontStyle = FontStyle.Bold;
        cardDescBar.color = new Color(0.92f, 0.95f, 1f, 1f);
        cardDescBar.alignment = TextAnchor.MiddleLeft;
        cardDescBar.raycastTarget = false;
        cardDescBar.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng...";
        var txtRt = txtGo.GetComponent<RectTransform>();
        Fill(txtRt, new Vector2(14, 0), new Vector2(-14, 0));
    }

    private void HandleCardSelected(CardUI cardUI)
    {
        ShowCardDescription(cardUI);

        if (playerRescuePending)
            return;

        if (playerActionResolving && currentStep == TutorialStep.FreeBattleUnlocked &&
            !duelResponseActive)
            return;

        // Duel response owns card selection while active; do not also open
        // the normal free-play target/action controls underneath it.
        if (duelResponseActive)
            return;

        // Xử lý trong chế độ hướng dẫn
        if (currentStep == TutorialStep.PlaySlashLesson)
        {
            if (cardUI != null && IsSlashCard(cardUI.Data))
            {
                PromptSelectBossTargetForSlash();
            }
        }
        else if (currentStep == TutorialStep.DiscardPhaseLesson)
        {
            UpdateTutorialDiscardButtonState();
        }
        else if (currentStep == TutorialStep.BossTurnAndDodge)
        {
            if (cardUI != null && CanActAsDodge(playerCard, cardUI.Data))
            {
                ActivateDodgeButton();
            }
        }
        else if (currentStep == TutorialStep.FreeBattleUnlocked)
        {
            if (freePlayDiscardPhaseActive)
            {
                UpdateFreePlayDiscardActionBtn();
            }
            else if (!playerHandUI.IsMultiSelectMode)
            {
                HandleFreePlayCardSelected(cardUI);
            }
        }
    }

    private void HandleSelectionChanged(List<CardUI> selectedList)
    {
        if (currentStep == TutorialStep.DiscardPhaseLesson)
        {
            UpdateTutorialDiscardButtonState();
        }
        else if (currentStep == TutorialStep.FreeBattleUnlocked && freePlayDiscardPhaseActive)
        {
            UpdateFreePlayDiscardActionBtn();
        }
    }

    private void ShowCardDescription(CardUI cardUI)
    {
        if (cardDescBar == null) return;
        if (cardUI == null || cardUI.Data == null)
        {
            cardDescBar.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng...";
            return;
        }
        var d = cardUI.Data;
        string catColor = d.category switch
        {
            CardCategory.Equipment => "#A0D8FF",
            CardCategory.InstantScroll => "#FFD700",
            CardCategory.DelayedScroll => "#FFA0C0",
            _ => "#FFFFFF"
        };
        cardDescBar.text = $"<color={catColor}><b>[{d.cardName} {d.GetSuitSymbol()}{d.GetRankString()} {d.GetCategoryName()}]</b></color> {d.description}";
    }
    #endregion

    #region 2. BƯỚC 1: HƯỚNG DẪN MÁU HOA SEN
    private void BuildHealthSpotlightTutorial()
    {
        var font = ThemeUI.FontMain;

        spotlightOverlay = new GameObject("HealthSpotlightOverlay", typeof(RectTransform));
        spotlightOverlay.transform.SetParent(transform, false);
        Fill(spotlightOverlay.GetComponent<RectTransform>());

        var darkMask = AddImage(spotlightOverlay.transform, "DarkMask", new Color(0.02f, 0.03f, 0.06f, 0.72f));
        darkMask.raycastTarget = true;
        Fill(darkMask.rectTransform);

        // 1. Nâng các bông Máu Hoa Sen của cả 2 bên lên trên màn tối để phát sáng rực rỡ
        if (bossCard != null && bossCard.HealthUI != null)
        {
            var bossCanvas = bossCard.HealthUI.gameObject.AddComponent<Canvas>();
            bossCanvas.overrideSorting = true;
            bossCanvas.sortingOrder = 60;
            bossCard.HealthUI.gameObject.AddComponent<GraphicRaycaster>();
            AddLotusGlowHalo(bossCard.HealthUI.transform);
        }

        if (playerCard != null && playerCard.HealthUI != null)
        {
            var playerCanvas = playerCard.HealthUI.gameObject.AddComponent<Canvas>();
            playerCanvas.overrideSorting = true;
            playerCanvas.sortingOrder = 60;
            playerCard.HealthUI.gameObject.AddComponent<GraphicRaycaster>();
            AddLotusGlowHalo(playerCard.HealthUI.transform);
        }

        // Mũi tên 1: Máu Sơn Tặc (chỉ thẳng vào hoa sen của Sơn Tặc)
        var arrow1Go = new GameObject("ArrowBossHealth", typeof(RectTransform), typeof(Image));
        arrow1Go.transform.SetParent(spotlightOverlay.transform, false);
        var arrow1Img = arrow1Go.GetComponent<Image>();
        arrow1Img.sprite = LotusHealthUI.LoadSpriteFromResources("UI/tutorial_arrow");
        arrow1Img.preserveAspect = true;
        arrow1Img.raycastTarget = false;
        arrowBossRt = arrow1Go.GetComponent<RectTransform>();
        arrowBossRt.anchorMin = new Vector2(0.5f, 1f);
        arrowBossRt.anchorMax = new Vector2(0.5f, 1f);
        arrowBossRt.pivot = new Vector2(1f, 0.5f);
        arrowBossRt.sizeDelta = new Vector2(64, 40);
        arrowBossBasePos = new Vector2(-60f, -104f);
        arrowBossRt.anchoredPosition = arrowBossBasePos;

        var tagBossGo = new GameObject("TagBoss", typeof(RectTransform), typeof(Text));
        tagBossGo.transform.SetParent(arrow1Go.transform, false);
        var tagBossTxt = tagBossGo.GetComponent<Text>();
        tagBossTxt.font = font;
        tagBossTxt.fontSize = 13;
        tagBossTxt.fontStyle = FontStyle.Bold;
        tagBossTxt.text = "MÁU SƠN TẶC";
        tagBossTxt.color = new Color(1f, 0.45f, 0.45f, 1f);
        tagBossTxt.alignment = TextAnchor.MiddleRight;
        var tagBossRt = tagBossGo.GetComponent<RectTransform>();
        tagBossRt.anchorMin = new Vector2(0f, 1f);
        tagBossRt.anchorMax = new Vector2(0f, 1f);
        tagBossRt.pivot = new Vector2(1f, 0f);
        tagBossRt.sizeDelta = new Vector2(150, 24);
        tagBossRt.anchoredPosition = new Vector2(-6, 4);
        AddTextShadow(tagBossTxt);

        // Mũi tên 2: Máu Người chơi (chỉ thẳng vào hoa sen của Lý Thường Kiệt)
        var arrow2Go = new GameObject("ArrowPlayerHealth", typeof(RectTransform), typeof(Image));
        arrow2Go.transform.SetParent(spotlightOverlay.transform, false);
        var arrow2Img = arrow2Go.GetComponent<Image>();
        arrow2Img.sprite = LotusHealthUI.LoadSpriteFromResources("UI/tutorial_arrow");
        arrow2Img.preserveAspect = true;
        arrow2Img.raycastTarget = false;
        arrowPlayerRt = arrow2Go.GetComponent<RectTransform>();
        arrowPlayerRt.anchorMin = new Vector2(1f, 0f);
        arrowPlayerRt.anchorMax = new Vector2(1f, 0f);
        arrowPlayerRt.pivot = new Vector2(1f, 0.5f);
        arrowPlayerRt.sizeDelta = new Vector2(64, 40);
        arrowPlayerBasePos = new Vector2(-220f, 172f);
        arrowPlayerRt.anchoredPosition = arrowPlayerBasePos;

        var tagPlayerGo = new GameObject("TagPlayer", typeof(RectTransform), typeof(Text));
        tagPlayerGo.transform.SetParent(arrow2Go.transform, false);
        var tagPlayerTxt = tagPlayerGo.GetComponent<Text>();
        tagPlayerTxt.font = font;
        tagPlayerTxt.fontSize = 13;
        tagPlayerTxt.fontStyle = FontStyle.Bold;
        tagPlayerTxt.text = "MÁU CỦA BẠN";
        tagPlayerTxt.color = new Color(0.45f, 0.95f, 0.55f, 1f);
        tagPlayerTxt.alignment = TextAnchor.MiddleRight;
        var tagPlayerRt = tagPlayerGo.GetComponent<RectTransform>();
        tagPlayerRt.anchorMin = new Vector2(0f, 1f);
        tagPlayerRt.anchorMax = new Vector2(0f, 1f);
        tagPlayerRt.pivot = new Vector2(1f, 0f);
        tagPlayerRt.sizeDelta = new Vector2(150, 24);
        tagPlayerRt.anchoredPosition = new Vector2(-6, 4);
        AddTextShadow(tagPlayerTxt);

        // Hộp hướng dẫn sinh mệnh ở giữa
        var dialogBoxGo = new GameObject("HealthGuideBox", typeof(RectTransform), typeof(Image));
        dialogBoxGo.transform.SetParent(spotlightOverlay.transform, false);
        var boxImg = dialogBoxGo.GetComponent<Image>();
        var cardBgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (cardBgSprite != null) { boxImg.sprite = cardBgSprite; boxImg.type = Image.Type.Sliced; }
        else boxImg.color = new Color(0.08f, 0.12f, 0.2f, 0.96f);

        var boxRt = dialogBoxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = new Vector2(0.5f, 0.5f);
        boxRt.anchorMax = new Vector2(0.5f, 0.5f);
        boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = new Vector2(580, 310);
        boxRt.anchoredPosition = new Vector2(-60f, -20f);

        var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(dialogBoxGo.transform, false);
        var title = titleGo.GetComponent<Text>();
        title.font = font;
        title.fontSize = 20;
        title.fontStyle = FontStyle.Bold;
        title.text = "💮 HƯỚNG DẪN SINH MỆNH (HOA SEN)";
        title.alignment = TextAnchor.MiddleCenter;
        title.color = GameTheme.GoldBright;
        var titleRt = titleGo.GetComponent<RectTransform>();
        titleRt.anchorMin = new Vector2(0, 1);
        titleRt.anchorMax = new Vector2(1, 1);
        titleRt.pivot = new Vector2(0.5f, 1);
        titleRt.sizeDelta = new Vector2(0, 36);
        titleRt.anchoredPosition = new Vector2(0, -18);
        AddTextShadow(title);

        var divGo = new GameObject("Divider", typeof(RectTransform), typeof(Image));
        divGo.transform.SetParent(dialogBoxGo.transform, false);
        var divImg = divGo.GetComponent<Image>();
        divImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        var divRt = divGo.GetComponent<RectTransform>();
        divRt.anchorMin = new Vector2(0.5f, 1);
        divRt.anchorMax = new Vector2(0.5f, 1);
        divRt.pivot = new Vector2(0.5f, 1);
        divRt.sizeDelta = new Vector2(320, 14);
        divRt.anchoredPosition = new Vector2(0, -56);

        var bodyGo = new GameObject("BodyText", typeof(RectTransform), typeof(Text));
        bodyGo.transform.SetParent(dialogBoxGo.transform, false);
        var bodyTxt = bodyGo.GetComponent<Text>();
        bodyTxt.font = font;
        bodyTxt.fontSize = 14;
        bodyTxt.color = new Color(0.92f, 0.95f, 1f, 1f);
        bodyTxt.lineSpacing = 1.4f;
        bodyTxt.text = "• Mỗi tướng sở hữu các cục sinh mệnh hình <color=#FFA0C0><b>Hoa Sen</b></color> nằm bên trái.\n" +
                       "• Khi trúng đòn mất máu, hoa sen sẽ <color=#9E9E9E><b>chuyển sang tối màu</b></color>.\n" +
                       "• ⚠️ <color=#FF5555><b>QUY TẮC SINH TỬ:</b></color> Nếu lượng máu tụt về <b>0</b>, tướng sẽ <color=#FF3333><b>TỬ TRẬN</b></color> và thua cuộc!\n" +
                       "• Hãy cùng học cách rút bài, dùng Trảm và Đỡ để chiến thắng!";
        var bodyRt = bodyGo.GetComponent<RectTransform>();
        bodyRt.anchorMin = Vector2.zero;
        bodyRt.anchorMax = Vector2.one;
        bodyRt.pivot = new Vector2(0.5f, 0.5f);
        bodyRt.offsetMin = new Vector2(26, 70);
        bodyRt.offsetMax = new Vector2(-26, -75);

        var continueBtnGo = new GameObject("ContinueBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        continueBtnGo.transform.SetParent(dialogBoxGo.transform, false);
        var btnImg = continueBtnGo.GetComponent<Image>();
        var btnSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSprite != null) { btnImg.sprite = btnSprite; btnImg.type = Image.Type.Sliced; }
        else btnImg.color = GameTheme.Gold;

        var btn = continueBtnGo.GetComponent<Button>();
        btn.onClick.AddListener(CloseHealthSpotlightAndStartGame);

        var btnRt = continueBtnGo.GetComponent<RectTransform>();
        btnRt.anchorMin = new Vector2(0.5f, 0f);
        btnRt.anchorMax = new Vector2(0.5f, 0f);
        btnRt.pivot = new Vector2(0.5f, 0f);
        btnRt.sizeDelta = new Vector2(240, 44);
        btnRt.anchoredPosition = new Vector2(0, 18);

        var btnTxtGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        btnTxtGo.transform.SetParent(continueBtnGo.transform, false);
        var btnTxt = btnTxtGo.GetComponent<Text>();
        btnTxt.font = font;
        btnTxt.fontSize = 15;
        btnTxt.fontStyle = FontStyle.Bold;
        btnTxt.text = "VÀO TRẬN ĐẤU ➜";
        btnTxt.color = new Color(0.12f, 0.08f, 0.02f, 1f);
        btnTxt.alignment = TextAnchor.MiddleCenter;
        Fill(btnTxtGo.GetComponent<RectTransform>());
    }

    private void AddLotusGlowHalo(Transform target)
    {
        var haloGo = new GameObject("LotusSpotlightHalo", typeof(RectTransform), typeof(Image));
        haloGo.transform.SetParent(target, false);
        haloGo.transform.SetAsFirstSibling();
        var img = haloGo.GetComponent<Image>();
        img.sprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        img.color = new Color(1f, 0.85f, 0.25f, 0.95f);
        img.raycastTarget = false;
        var rt = haloGo.GetComponent<RectTransform>();
        Fill(rt, new Vector2(-12, -12), new Vector2(12, 12));
    }

    private void CloseHealthSpotlightAndStartGame()
    {
        if (spotlightOverlay != null) Destroy(spotlightOverlay);
        if (deckHudGo != null) deckHudGo.SetActive(true);

        // Gỡ bỏ Canvas và hào quang tạm thời trên cột Máu Hoa Sen
        if (bossCard != null && bossCard.HealthUI != null)
        {
            var halo = bossCard.HealthUI.transform.Find("LotusSpotlightHalo");
            if (halo != null) Destroy(halo.gameObject);
            var gr = bossCard.HealthUI.GetComponent<GraphicRaycaster>();
            if (gr != null) Destroy(gr);
            var c = bossCard.HealthUI.GetComponent<Canvas>();
            if (c != null) Destroy(c);
        }

        if (playerCard != null && playerCard.HealthUI != null)
        {
            var halo = playerCard.HealthUI.transform.Find("LotusSpotlightHalo");
            if (halo != null) Destroy(halo.gameObject);
            var gr = playerCard.HealthUI.GetComponent<GraphicRaycaster>();
            if (gr != null) Destroy(gr);
            var c = playerCard.HealthUI.GetComponent<Canvas>();
            if (c != null) Destroy(c);
        }

        // Bắt đầu chia 4 lá bài ban đầu (đảm bảo người chơi có 1 Trảm và 1 Đỡ)
        StartCoroutine(SequenceInitialDealing());
    }
    #endregion

    #region 3. CHIA BÀI BAN ĐẦU & BƯỚC 2: RÚT LÁ ĐẦU LƯỢT
    private IEnumerator SequenceInitialDealing()
    {
        currentStep = TutorialStep.InitialDealing;
        bossHandCards.Clear();

        // Tutorial opening hand: all four player cards are real Trảm cards;
        // the Dodge lesson adds a real Đỡ later if needed.
        for (int playerPosition = 0; playerPosition < 4; playerPosition++)
            deckManager.SwapCardToPosition(playerPosition * 2, IsSlashCard);

        // Chia xen kẽ 4 lá cho Player và 4 lá cho Boss từ đầu xấp rút cố định
        for (int i = 0; i < 8; i++)
        {
            bool toPlayer = (i % 2 == 0);
            var card = deckManager.DrawCard();
            if (card == null) break;

            yield return AnimateDealtCard(toPlayer);

            if (toPlayer)
            {
                var ui = playerHandUI.AddCard(card);
                if (ui != null) StartCoroutine(AnimateCardAppear(ui.transform));
            }
            else
            {
                BossAddHandCard(card);
            }

            yield return new WaitForSeconds(0.08f);
        }

        yield return new WaitForSeconds(0.4f);

        // Bắt đầu Bước 2: Hướng dẫn lượt đầu tự động bốc 1 lá bài
        StartCoroutine(SequenceDrawTwoLesson());
    }

    private IEnumerator SequenceDrawTwoLesson()
    {
        currentStep = TutorialStep.DrawTwoAtTurnStart;
        isPlayerTurn = true;
        slashesUsedThisTurn = 0;

        EnsureTutorialOverlay();

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "📜 <color=#FFD700><b>GIAI ĐOẠN 1: RÚT BÀI ĐẦU LƯỢT</b></color>\n" +
                                      "Người đầu tiên chơi sẽ <color=#55FF55><b>BỐC 1 LÁ BÀI</b></color>; các lượt sau tự động bốc 2 lá từ kho bài!";
        }

        SetLog("📜 LƯỢT ĐẦU CỦA BẠN: Người đầu tiên chơi chỉ rút 1 lá bài.");

        yield return new WaitForSeconds(0.8f);

        // Người đầu tiên chơi chỉ rút 1 lá; lượt sau mới rút 2 lá.
        for (int k = 0; k < 1; k++)
        {
            var card = deckManager.DrawCard();
            if (card != null)
            {
                yield return AnimateDealtCard(true);
                var ui = playerHandUI.AddCard(card);
                if (ui != null) StartCoroutine(AnimateCardAppear(ui.transform));
                yield return new WaitForSeconds(0.1f);
            }
        }

        yield return new WaitForSeconds(0.5f);

        // Nút chuyển sang Giai đoạn Ra bài
        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            tutorialActionBtnText.text = "VÀO GIAI ĐOẠN RA BÀI ➜";
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(() =>
            {
                tutorialActionBtn.SetActive(false);
                StartPlaySlashLesson();
            });
        }
    }
    #endregion

    #region 4. BƯỚC 3: HƯỚNG DẪN DÙNG TRẢM TẤN CÔNG
    private void StartPlaySlashLesson()
    {
        currentStep = TutorialStep.PlaySlashLesson;

        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "⚔️ <color=#FFD700><b>GIAI ĐOẠN 2: RA BÀI (DÙNG TRẢM)</b></color>\n" +
                                      "Hãy chạm chọn lá bài <color=#FF5555><b>TRẢM</b></color> đang phát sáng trên tay!";
        }

        SetLog("Hãy click chọn 1 lá TRẢM trên tay để chuẩn bị tấn công.");

        // Làm sáng DUY NHẤT các lá Trảm trên tay, các lá khác tự động tối mờ đi
        playerHandUI.HighlightOnlyMatching(IsSlashCard);

        CardUI firstSlash = null;
        foreach (var card in playerHandUI.Cards)
        {
            if (card != null && IsSlashCard(card.Data))
            {
                if (firstSlash == null) firstSlash = card;
            }
        }

        if (firstSlash != null)
        {
            PositionTutorialArrowAt(firstSlash.GetComponent<RectTransform>(), "CHỌN TRẢM", new Vector2(-46f, 0f));
            if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(true);
        }

        if (tutorialActionBtn != null) tutorialActionBtn.SetActive(false);
    }

    private void PromptSelectBossTargetForSlash()
    {
        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🎯 Hãy chạm chọn <color=#FF5555><b>THỦ LĨNH SƠN TẶC</b></color> trên bàn đấu làm mục tiêu!";
        }

        SetLog("Đã chọn lá Trảm. Hãy click chạm chọn Thủ Lĩnh Sơn Tặc trên bàn đấu làm mục tiêu tấn công.");

        // Mũi tên chuyển sang chỉ vào Sơn Tặc
        var bossAvatar = bossCard.transform.Find("Avatar") as RectTransform;
        PositionTutorialArrowInside(bossAvatar != null ? bossAvatar : bossCard.GetComponent<RectTransform>(), "CHỌN MỤC TIÊU");

        // Nút Dùng Bài hiện ở trạng thái chờ chọn mục tiêu (màu xám / chưa bấm được)
        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.interactable = false;
            tutorialActionBtn.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
            tutorialActionBtnText.text = "🎯 HÃY CHỌN MỤC TIÊU SƠN TẶC";
        }
    }

    private void OnGeneralCardClicked(GeneralCardUI general)
    {
        if (general == null || gameFinished || playerRescuePending) return;

        if (currentStep == TutorialStep.PlaySlashLesson)
        {
            if (general == bossCard && playerHandUI.SelectedCard != null && IsSlashCard(playerHandUI.SelectedCard.Data))
            {
                OnBossTargetSelectedForSlashLesson();
            }
        }
        else if (currentStep == TutorialStep.FreeBattleUnlocked)
        {
            OnGeneralTargetSelectedForFreePlay(general);
        }
    }

    private void OnBossTargetSelectedForSlashLesson()
    {
        AudioManager.Instance.PlayCardSelect();

        // Tạo viền sáng mục tiêu trên Boss
        if (tutorialTargetBorder != null) Destroy(tutorialTargetBorder.gameObject);
        AddTutorialGlow(bossCard.transform);

        tutorialTargetBorder = new GameObject("TutorialTargetBorder", typeof(RectTransform), typeof(Image)).GetComponent<Image>();
        tutorialTargetBorder.transform.SetParent(bossCard.transform, false);
        tutorialTargetBorder.transform.SetAsLastSibling();
        tutorialTargetBorder.sprite = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        tutorialTargetBorder.type = Image.Type.Sliced;
        tutorialTargetBorder.raycastTarget = false;
        Fill(tutorialTargetBorder.rectTransform, new Vector2(-6, -6), new Vector2(6, 6));

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🎯 Đã nhắm mục tiêu Sơn Tặc! Nhấn nút <color=#FFD700><b>[⚔️ DÙNG BÀI]</b></color> để tấn công!";
        }

        SetLog("🎯 Đã chọn mục tiêu [Thủ Lĩnh Sơn Tặc]! Nhấn nút [DÙNG BÀI] để xuất chiêu.");

        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.interactable = true;
            tutorialActionBtn.GetComponent<Image>().color = GameTheme.Gold;
            tutorialActionBtnText.text = "⚔️ DÙNG BÀI ➜ SƠN TẶC";
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(ExecuteTutorialSlash);

            // Chuyển mũi tên chỉ vào nút Dùng Bài
            PositionTutorialArrowAt(tutorialActionBtn.GetComponent<RectTransform>(), "TẤN CÔNG", new Vector2(-46f, 0f));
        }
    }

    private void ExecuteTutorialSlash()
    {
        var selected = playerHandUI.SelectedCard;
        if (selected == null || !IsSlashCard(selected.Data)) return;

        var cardData = selected.Data;
        var screenPos = RectTransformUtility.WorldToScreenPoint(null, selected.transform.position);

        deckManager.DiscardCard(cardData);
        playerHandUI.RemoveCard(selected);
        slashesUsedThisTurn++;

        ClearTutorialVisuals();

        // AnimateSlashAttack owns the center-card presentation for a Slash;
        // avoid creating a second overlapping copy here.
        StartCoroutine(AnimateSlashAttack(cardData, bossCard, screenPos, () =>
        {
            bossCard.TakeDamage(1);
            AudioManager.Instance.PlayDamage();
            CheckBossDefeat();
            if (gameFinished) return;
            SetLog("⚔️ Bạn đã dùng TRẢM! Thủ Lĩnh Sơn Tặc trúng đòn mất 1 hoa sen máu.");
            // Chuyển sang Bước 4: Hướng dẫn quy tắc mỗi turn chỉ được 1 Trảm
            StartCoroutine(SequenceOneSlashRuleLesson());
        }));
    }
    #endregion

    #region 5. BƯỚC 4: HƯỚNG DẪN MỖI TURN CHỈ ĐƯỢC 1 LÁ TRẢM
    private IEnumerator SequenceOneSlashRuleLesson()
    {
        currentStep = TutorialStep.OneSlashPerTurnRule;
        yield return new WaitForSeconds(0.4f);

        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "⚠️ <color=#FFD700><b>QUY TẮC: MỖI TURN CHỈ ĐƯỢC DÙNG 1 LÁ TRẢM</b></color>\n" +
                                      "Trong cùng một lượt, mỗi người chơi chỉ được ra <color=#FF5555><b>TỐI ĐA 1 LÁ TRẢM</b></color> " +
                                      "(trừ khi trang bị <i>Nỏ Thần Kim Quy</i>)!\n" +
                                      "Bây giờ, hãy tìm hiểu kỹ năng độc quyền của tướng.";
        }

        SetLog("⚠️ Lưu ý: Mỗi turn chỉ được dùng tối đa 1 lá Trảm.");

        // Nút chuyển sang Bước Kỹ Năng
        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            tutorialActionBtnText.text = "TÌM HIỂU KỸ NĂNG TƯỚNG ➜";
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(() =>
            {
                tutorialActionBtn.SetActive(false);
                StartCoroutine(SequenceSkillTienThoaiLesson());
            });
        }
    }
    #endregion

    #region 5.5 BƯỚC 4.5: HƯỚNG DẪN KỸ NĂNG TIẾN THOÁI
    private IEnumerator SequenceSkillTienThoaiLesson()
    {
        currentStep = TutorialStep.SkillTienThoaiLesson;
        yield return new WaitForSeconds(0.3f);

        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "⚡ <color=#FFD700><b>KỸ NĂNG ĐẶC BIỆT: [TIẾN THOÁI]</b></color>\n" +
                                      "Tướng <b>Lý Thường Kiệt</b> sở hữu tuyệt kỹ <color=#FFD700><b>TIẾN THOÁI</b></color>:\n" +
                                      "Hoán chuyển tất cả lá <color=#FF5555><b>TRẢM</b></color> trên tay thành <color=#55AAFF><b>ĐỠ</b></color>, " +
                                      "và tất cả <color=#55AAFF><b>ĐỠ</b></color> thành <color=#FF5555><b>TRẢM</b></color>!\n" +
                                      "Hãy click nút <color=#FFD700><b>[⚡ TIẾN THOÁI]</b></color> bên trái tướng để biến đổi bài.";
        }

        SetLog("⚡ Hướng dẫn: Click nút [⚡ TIẾN THOÁI] bên trái avatar Lý Thường Kiệt.");

        // Đảm bảo có ít nhất 1 lá Trảm trên tay để người chơi thấy rõ sự biến đổi thành Đỡ
        bool hasSlash = false;
        foreach (var c in playerHandUI.Cards)
        {
            if (c != null && IsSlashCard(c.Data)) { hasSlash = true; break; }
        }
        if (!hasSlash)
        {
            var slashCard = deckManager.DrawMatching(IsSlashCard);
            if (slashCard == null) slashCard = new CardModel { cardName = "Trảm Thường", category = CardCategory.Basic, subType = CardSubType.AttackNormal, description = "Gây 1 sát thương cho mục tiêu." };
            playerHandUI.AddCard(slashCard);
        }

        // Mũi tên chỉ vào nút Tiến Thoái của Lý Thường Kiệt
        if (playerCard != null && playerCard.SkillButtonGo != null)
        {
            var btnRt = playerCard.SkillButtonGo.GetComponent<RectTransform>();
            PositionTutorialArrowAt(btnRt, "BẤM TIẾN THOÁI", new Vector2(-46f, 0f));
            if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(true);
        }

        if (tutorialActionBtn != null) tutorialActionBtn.SetActive(false);
    }

    private void OnPlayerSkillTienThoaiClicked()
    {
        if (gameFinished || playerRescuePending || playerTurnStartResolving)
            return;

        // Trong bước hướng dẫn kỹ năng hoặc khi đang chiến đấu tự do, luôn kích hoạt mượt mà
        if (currentStep == TutorialStep.SkillTienThoaiLesson)
        {
            // Được phép thực thi ngay!
        }
        else
        {
            if (isPlayerTurn && playerPlayPhaseLocked)
            {
                SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Không thể dùng kỹ năng trong lượt bị bỏ qua Giai đoạn Ra bài.");
                return;
            }

            bool isDefending = isAwaitingDodge || slashDefenseActive || duelResponseActive || globalDefenseActive;

            if (!isPlayerTurn && !isDefending && currentStep < TutorialStep.FreeBattleUnlocked)
            {
                SetLog("⏳ Chưa tới lượt của bạn hoặc không trong tình huống cần xuất chiêu.");
                return;
            }

            if (playerActionResolving && !isDefending)
            {
                return;
            }
        }

        playerCard.AnimateSkillTrigger("TIẾN THOÁI");
        AudioManager.Instance.PlaySkill();
        int transformed = playerHandUI.TransformSlashAndDodge();
        SetLog($"✨ <color=#FFD700><b>LÝ THƯỜNG KIỆT THI TRIỂN [TIẾN THOÁI]!</b></color> Đã hoán chuyển {transformed} lá Trảm ⟷ Đỡ trên tay!");

        // Refresh highlights & card selection depending on active defensive state
        if (slashDefenseActive || isAwaitingDodge || (globalDefenseActive && currentGlobalDefType == CardSubType.ArrowRain))
        {
            playerHandUI.HighlightOnlyMatching(IsDodgeCard);
            onCurrentReactionCardSelected?.Invoke(playerHandUI.SelectedCard);
        }
        else if (duelResponseActive || (globalDefenseActive && currentGlobalDefType == CardSubType.BarbarianInvasion))
        {
            playerHandUI.HighlightOnlyMatching(IsSlashCard);
            onCurrentReactionCardSelected?.Invoke(playerHandUI.SelectedCard);
        }
        else
        {
            playerHandUI.ResetAllCardsVisuals();
        }

        if (currentStep == TutorialStep.SkillTienThoaiLesson)
        {
            ClearTutorialVisuals();
            StartCoroutine(SequenceSkillCompletedLesson());
        }
    }

    private IEnumerator SequenceSkillCompletedLesson()
    {
        yield return new WaitForSeconds(0.4f);
        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🎉 <color=#55AAFF><b>BIẾN ĐỔI THÀNH CÔNG!</b></color>\n" +
                                      "Toàn bộ lá Trảm trên tay đã hóa thành lá <color=#55AAFF><b>ĐỠ (NÉ)</b></color> sẵn sàng phòng thủ!\n" +
                                      "Bạn đã dùng xong bài trong lượt. Hãy nhấn <color=#FFD700><b>[KẾT THÚC LƯỢT]</b></color>!";
        }

        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.interactable = true;
            tutorialActionBtn.GetComponent<Image>().color = GameTheme.Gold;
            tutorialActionBtnText.text = "KẾT THÚC LƯỢT ➜";
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(() =>
            {
                tutorialActionBtn.SetActive(false);
                StartCoroutine(SequenceDiscardPhaseLesson());
            });
        }
    }

    private IEnumerator SequenceDiscardPhaseLesson()
    {
        currentStep = TutorialStep.DiscardPhaseLesson;
        yield return new WaitForSeconds(0.3f);

        int handCount = playerHandUI.Cards.Count;
        int maxHp = playerCard.CurrentHp;

        if (handCount <= maxHp)
        {
            // Không bị thừa bài -> Tự động sang lượt Sơn Tặc
            StartCoroutine(SequenceBossTurnAndDodgeLesson());
            yield break;
        }

        int excess = handCount - maxHp;

        // Bật chế độ chọn nhiều lá bài cùng một lúc và giới hạn tối đa đúng số lá thừa
        playerHandUI.IsMultiSelectMode = true;
        playerHandUI.MaxSelectableCards = excess;
        playerHandUI.ClearSelection();

        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🗑️ <color=#FFD700><b>GIAI ĐOẠN 3: BỎ BÀI CUỐI LƯỢT (DISCARD PHASE)</b></color>\n" +
                                      $"• <color=#FFD700><b>QUY TẮC:</b></color> Khi kết thúc lượt, số bài trên tay tối đa chỉ được <color=#FFA0C0><b>BẰNG SỐ MÁU ({maxHp} Máu)</b></color>!\n" +
                                      $"• Hiện tại bạn có <color=#FF5555><b>{handCount} lá bài</b></color> (vượt quá <color=#FF5555><b>{excess} lá bài thừa</b></color>).\n" +
                                      $"Hãy chạm chọn đúng <color=#FFD700><b>{excess} lá bài thừa</b></color> rồi nhấn <color=#FFD700><b>[BỎ BÀI]</b></color>!";
        }

        SetLog($"🗑️ Giai đoạn Bỏ Bài: Số bài trên tay ({handCount}) > Số máu ({maxHp}). Cần bỏ {excess} lá bài thừa (chỉ được chọn tối đa {excess} lá).");

        // Chỉ mũi tên vào bài trên tay
        if (playerHandUI.Cards.Count > 0)
        {
            var firstCard = playerHandUI.Cards[0];
            if (firstCard != null)
            {
                PositionTutorialArrowAt(firstCard.GetComponent<RectTransform>(), "CHỌN LÁ ĐỂ BỎ", new Vector2(-46f, 0f));
                if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(true);
            }
        }

        UpdateTutorialDiscardButtonState();
    }

    private void UpdateTutorialDiscardButtonState()
    {
        if (tutorialActionBtn == null) return;
        int excess = playerHandUI.Cards.Count - playerCard.CurrentHp;
        if (excess <= 0)
        {
            tutorialActionBtn.SetActive(false);
            return;
        }

        playerHandUI.MaxSelectableCards = excess;
        tutorialActionBtn.SetActive(true);
        var btn = tutorialActionBtn.GetComponent<Button>();
        var btnImg = tutorialActionBtn.GetComponent<Image>();
        int selectedCount = playerHandUI.SelectedCount;

        if (selectedCount == 0)
        {
            btn.interactable = false;
            btnImg.color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
            tutorialActionBtnText.text = $"🗑️ HÃY CHỌN LÁ ĐỂ BỎ ({excess} lá thừa)";
        }
        else
        {
            btn.interactable = true;
            btnImg.color = new Color(0.88f, 0.35f, 0.18f, 1f);
            tutorialActionBtnText.text = (selectedCount == 1)
                ? $"🗑️ BỎ LÁ [{playerHandUI.SelectedCard.Data.cardName.ToUpper()}] ({excess} lá thừa)"
                : $"🗑️ BỎ {selectedCount} LÁ ĐÃ CHỌN ({excess} lá thừa)";

            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(ExecuteTutorialDiscard);

            PositionTutorialArrowAt(tutorialActionBtn.GetComponent<RectTransform>(), "XÁC NHẬN BỎ", new Vector2(-46f, 0f));
        }
    }

    private void ExecuteTutorialDiscard()
    {
        var selectedList = new List<CardUI>(playerHandUI.SelectedCards);
        if (selectedList.Count == 0) return;

        int excessNow = playerHandUI.Cards.Count - playerCard.CurrentHp;
        if (excessNow > 0 && selectedList.Count > excessNow)
        {
            selectedList = selectedList.GetRange(0, excessNow);
        }

        foreach (var c in selectedList)
        {
            if (c != null && c.Data != null)
            {
                deckManager.DiscardCard(c.Data);
            }
        }
        playerHandUI.RemoveCards(selectedList);
        AudioManager.Instance.PlayCardSelect();

        int remaining = playerHandUI.Cards.Count;
        int maxHp = playerCard.CurrentHp;

        ClearTutorialVisuals();

        if (remaining > maxHp)
        {
            int excess = remaining - maxHp;
            playerHandUI.MaxSelectableCards = excess;
            SetLog($"🗑️ Đã bỏ {selectedList.Count} lá bài. Vẫn còn thừa {excess} lá bài ({remaining}/{maxHp}). Hãy chọn tiếp {excess} lá nữa để bỏ.");

            if (tutorialPromptText != null)
            {
                tutorialPromptText.text = $"🗑️ <color=#FFD700><b>VẪN CÒN THỪA {excess} LÁ BÀI!</b></color>\n" +
                                          $"Số bài trên tay hiện tại là <color=#FF5555><b>{remaining} lá</b></color> (Máu: {maxHp}).\n" +
                                          $"Hãy chạm chọn tiếp <color=#FF5555><b>{excess} lá bài thừa</b></color> (có thể chọn nhiều lá) rồi nhấn BỎ BÀI!";
            }

            if (playerHandUI.Cards.Count > 0)
            {
                var firstCard = playerHandUI.Cards[0];
                if (firstCard != null)
                {
                    PositionTutorialArrowAt(firstCard.GetComponent<RectTransform>(), "CHỌN LÁ ĐỂ BỎ", new Vector2(-46f, 0f));
                    if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(true);
                }
            }

            UpdateTutorialDiscardButtonState();
        }
        else
        {
            // Đã cân bằng (remaining <= maxHp) -> Hoàn tất và tự động chuyển lượt cho Sơn Tặc
            playerHandUI.IsMultiSelectMode = false;
            SetLog($"✅ <color=#55FF55><b>HOÀN TẤT BỎ BÀI!</b></color> Số bài trên tay: {remaining}/{maxHp}. Tự động chuyển lượt sang Thủ Lĩnh Sơn Tặc.");

            if (tutorialPromptText != null)
            {
                tutorialPromptText.text = $"✅ <color=#55FF55><b>HOÀN TẤT BỎ BÀI!</b></color>\n" +
                                          $"Số bài trên tay ({remaining}/{maxHp}) đã cân bằng với số máu!\n" +
                                          "Đang chuyển lượt sang Thủ Lĩnh Sơn Tặc...";
            }

            if (tutorialActionBtn != null) tutorialActionBtn.SetActive(false);

            StartCoroutine(TransitionToBossTurnAfterDiscard());
        }
    }

    private IEnumerator TransitionToBossTurnAfterDiscard()
    {
        yield return new WaitForSeconds(1.0f);
        StartCoroutine(SequenceBossTurnAndDodgeLesson());
    }
    #endregion

    #region 6. BƯỚC 5: LƯỢT SƠN TẶC & HƯỚNG DẪN DÙNG ĐỠ (NÉ)
    private IEnumerator SequenceBossTurnAndDodgeLesson()
    {
        currentStep = TutorialStep.BossTurnAndDodge;
        isPlayerTurn = false;

        ClearTutorialVisuals();
        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "👺 <color=#FF5555><b>ĐẾN LƯỢT THỦ LĨNH SƠN TẶC!</b></color>\n" +
                                      "Sơn Tặc tự động rút 2 lá bài và chuẩn bị ra đòn...";
        }

        SetLog("👺 Đến lượt Thủ Lĩnh Sơn Tặc.");
        yield return new WaitForSeconds(1.0f);

        // Sơn Tặc rút 2 lá bài
        for (int k = 0; k < 2; k++)
        {
            var dealt = deckManager.DrawCard();
            if (dealt != null)
            {
                yield return AnimateDealtCard(false);
                BossAddHandCard(dealt);
            }
            yield return new WaitForSeconds(0.1f);
        }

        yield return new WaitForSeconds(0.6f);

        // Sơn Tặc tung Trảm vào người chơi
        pendingBossSlash = BossPopHandCard(IsSlashCard);
        if (pendingBossSlash == null)
        {
            pendingBossSlash = deckManager.DrawMatching(IsSlashCard);
        }
        if (pendingBossSlash == null)
            pendingBossSlash = new CardModel { cardName = "Trảm Thường", category = CardCategory.Basic, subType = CardSubType.AttackNormal };
        SetLog("💥 Sơn Tặc vung đao tung chiêu [TRẢM] nhắm thẳng vào bạn!");

        // Hiển thị lá Trảm của Sơn Tặc ở chính giữa màn hình và bắn tia vàng nhắm vào người chơi
        ShowCardAtCenter(pendingBossSlash, bossCard, playerCard);

        // Kích hoạt chế độ phòng thủ: Yêu cầu người chơi dùng Đỡ (Né)
        isAwaitingDodge = true;

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🛡️ <color=#FF5555><b>CẢNH BÁO BỊ TẤN CÔNG!</b></color>\n" +
                                      "Sơn Tặc vừa tung đòn <b>TRẢM</b>! Hãy chọn lá <color=#55AAFF><b>ĐỠ (NÉ)</b></color> trên tay để vô hiệu hóa đòn đánh!";
        }

        // Đảm bảo người chơi có lá Đỡ trên tay
        CardUI dodgeCardUI = null;
        foreach (var c in playerHandUI.Cards)
        {
            if (c != null && IsDodgeCard(c.Data))
            {
                dodgeCardUI = c;
                break;
            }
        }

        if (dodgeCardUI == null)
        {
            // Nếu chưa có, cấp ngay 1 lá Đỡ vào tay
            var dodgeCard = deckManager.DrawMatching(IsDodgeCard);
            if (dodgeCard == null) dodgeCard = new CardModel { cardName = "Đỡ", category = CardCategory.Basic, subType = CardSubType.Dodge, description = "Hóa giải hoàn toàn 1 đòn Trảm." };
            dodgeCardUI = playerHandUI.AddCard(dodgeCard);
        }

        // Làm sáng DUY NHẤT lá Đỡ trên tay, các lá khác tự động tối mờ đi
        playerHandUI.HighlightOnlyMatching(IsDodgeCard);

        if (dodgeCardUI != null)
        {
            PositionTutorialArrowAt(dodgeCardUI.GetComponent<RectTransform>(), "CHỌN ĐỠ", new Vector2(-46f, 0f));
            if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(true);
        }
    }

    private void ActivateDodgeButton()
    {
        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "Nhấn nút <color=#55AAFF><b>[DÙNG ĐỠ ĐỂ NÉ]</b></color> để triệt tiêu đòn Trảm!";
        }

        if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(false);

        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            tutorialActionBtnText.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)";
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(ExecuteTutorialDodge);
        }
    }

    private void ExecuteTutorialDodge()
    {
        var selected = playerHandUI.SelectedCard;
        if (selected == null || !IsDodgeCard(selected.Data)) return;

        var dodgeData = selected.Data;
        var dodgeScreenPos = RectTransformUtility.WorldToScreenPoint(null, selected.transform.position);

        deckManager.DiscardCard(dodgeData);
        playerHandUI.RemoveCard(selected);
        if (pendingBossSlash != null)
        {
            deckManager.DiscardCard(pendingBossSlash);
            pendingBossSlash = null;
        }
        isAwaitingDodge = false;

        ClearTutorialVisuals();

        // Hiển thị lá Đỡ đè lên giữa màn hình
        ShowCardAtCenter(dodgeData, playerCard);

        StartCoroutine(AnimateDodgeParry(dodgeData, dodgeScreenPos, () =>
        {
            SetLog("🛡️ HOÁ GIẢI THÀNH CÔNG! Bạn đã dùng Đỡ né hoàn toàn đòn Trảm của Sơn Tặc!");
            StartCoroutine(SequenceBossDiscardPhaseAfterDodge());
        }));
    }

    private IEnumerator SequenceBossDiscardPhaseAfterDodge()
    {
        yield return new WaitForSeconds(0.4f);

        // Cuối lượt của Sơn Tặc -> Sơn Tặc phải bỏ bài nếu số bài > số máu (5 bài > 3 máu)
        int bossHand = bossHandCards.Count;
        int bossHp = bossCard.CurrentHp;
        if (bossHand > bossHp)
        {
            int bossExcess = bossHand - bossHp;
            SetLog($"🗑️ <color=#FFD700><b>[SƠN TẶC BỎ BÀI CUỐI LƯỢT]</b></color>: Sơn Tặc có {bossHand} lá bài nhưng chỉ còn {bossHp} Máu. Sơn Tặc tự động bỏ {bossExcess} lá bài thừa vào xấp xả!");
            yield return new WaitForSeconds(0.4f);

            for (int d = 0; d < bossExcess; d++)
            {
                var discardedCard = BossPopHandCard();
                if (discardedCard != null) deckManager.DiscardCard(discardedCard);
                yield return AnimateDiscardFlying(bossCard.transform.position);
                yield return new WaitForSeconds(0.18f);
            }
            yield return new WaitForSeconds(0.5f);
        }

        // Chuyển sang Bước 6: Hoàn thành Tân thủ
        StartCoroutine(SequenceFreeBattleUnlocked());
    }
    #endregion

    #region 7. BƯỚC 6: HOÀN THÀNH TÂN THỦ & MỞ KHÓA TỰ DO
    private IEnumerator SequenceFreeBattleUnlocked()
    {
        currentStep = TutorialStep.FreeBattleUnlocked;
        isPlayerTurn = true;
        slashesUsedThisTurn = 0;

        yield return new WaitForSeconds(0.4f);

        EnsureTutorialOverlay();
        SetTutorialMask(true);

        if (tutorialPromptText != null)
        {
            tutorialPromptText.text = "🎉 <color=#FFD700><b>CHÚC MỪNG! BẠN ĐÃ NẮM TRỌN QUY TẮC!</b></color>\n" +
                                      "• <b>Đầu lượt:</b> Lượt đầu rút 1 lá, các lượt sau rút 2 lá.\n" +
                                      "• <b>Tấn công:</b> Mỗi turn dùng tối đa 1 lá Trảm.\n" +
                                      "• <b>Phòng thủ:</b> Dùng Đỡ để né đòn Trảm của đối phương.\n" +
                                      "Hãy tự do chiến đấu để tiêu diệt Thủ Lĩnh Sơn Tặc!";
        }

        SetLog("🎉 Bạn đã hoàn thành hướng dẫn tân thủ! Bắt đầu thực chiến.");

        if (tutorialActionBtn != null)
        {
            tutorialActionBtn.SetActive(true);
            tutorialActionBtnText.text = "BẮT ĐẦU THỰC CHIẾN ⚔️";
            var btn = tutorialActionBtn.GetComponent<Button>();
            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(() =>
            {
                ClearTutorialVisuals();
                if (tutorialStepOverlay != null) Destroy(tutorialStepOverlay);

                // Khôi phục sorting cho Boss, Player và Hand
                if (bossCard != null)
                {
                    var bc = bossCard.GetComponent<Canvas>();
                    if (bc != null) bc.overrideSorting = false;
                }
                if (playerCard != null)
                {
                    var pc = playerCard.GetComponent<Canvas>();
                    if (pc != null) pc.overrideSorting = false;
                }
                if (playerHandUI != null)
                {
                    var hc = playerHandUI.GetComponent<Canvas>();
                    if (hc != null) hc.overrideSorting = false;
                }

                // Mở thanh nút lệnh tự do
                var font = ThemeUI.FontMain;
                BuildActionControls(font);
                // Đầu lượt mới: Rút 2 lá bài
                StartCoroutine(PlayerTurnStartFreePlay());
            });
        }
    }

    private IEnumerator PlayerTurnStartFreePlay()
    {
        if (gameFinished) yield break;
        SetPlayerTurn(true);
        slashesUsedThisTurn = 0;
        isWineBuffActive = false;
        playerTurnStartResolving = true;
        // Judgement and draw resolve before the player may select or use a
        // card. Keep the play phase locked until those phases finish.
        playerPlayPhaseLocked = true;
        currentTargetCard = null;
        if (playerHandUI != null) playerHandUI.ClearSelection();
        ClearFreePlayTargetVisuals();
        if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
        SetLog("=== LƯỢT MỚI CỦA BẠN ===");

        bool skipDrawPhase = false;
        bool skipPlayPhase = false;

        // --- GIAI ĐOẠN 1: PHÁN XÉT CỦA NGƯỜI CHƠI ---
        // 1. Thần Sấm Báo Ứng
        if (playerCard.HasDelayedScroll(CardSubType.Lightning))
        {
            var delayed = playerCard.GetDelayedScroll(CardSubType.Lightning);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, bossCard, playerCard, result => isCanceled = result);
            if (gameFinished)
            {
                playerTurnStartResolving = false;
                yield break;
            }

            if (isCanceled)
            {
                playerCard.RemoveDelayedScroll(CardSubType.Lightning);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, playerCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Thần Sấm Báo Ứng đã bị Diệu Kế Phá Mưu giải trừ trước khi phán xét!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("⚡ [PHÁN XÉT THẦN SẤM]: Đang lật bài phán xét Thần Sấm Báo Ứng...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool hit = (judgeCard.suit == CardSuit.Spade && (int)judgeCard.rank >= 2 && (int)judgeCard.rank <= 9);
                    yield return AnimateJudgementResult(
                        playerCard,
                        bossCard,
                        CardSubType.Lightning,
                        "Thần Sấm Báo Ứng",
                        judgeCard,
                        hit,
                        "bị sét đánh trúng MẤT 3 MÁU!",
                        "thoát sấm an toàn, chuyển sấm sang Sơn Tặc");

                    if (hit)
                    {
                        playerCard.TakeDamage(3);
                        yield return ResolvePlayerNearDeath();
                        if (gameFinished)
                        {
                            playerTurnStartResolving = false;
                            yield break;
                        }
                    }
                }
            }
        }

        // 2. Cắt Đường Lương (Supply Shortage)
        if (playerCard.HasDelayedScroll(CardSubType.SupplyShortage))
        {
            var delayed = playerCard.GetDelayedScroll(CardSubType.SupplyShortage);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, bossCard, playerCard, result => isCanceled = result);
            if (gameFinished)
            {
                playerTurnStartResolving = false;
                yield break;
            }

            if (isCanceled)
            {
                playerCard.RemoveDelayedScroll(CardSubType.SupplyShortage);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, playerCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Cắt Đường Lương đã bị Diệu Kế Phá Mưu giải trừ trước khi phán xét!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("🌾 [PHÁN XÉT CẮT ĐƯỜNG LƯƠNG]: Đang lật bài phán xét lương thảo...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool trapped = (judgeCard.suit != CardSuit.Club);
                    if (trapped) skipDrawPhase = true;

                    yield return AnimateJudgementResult(
                        playerCard,
                        bossCard,
                        CardSubType.SupplyShortage,
                        "Cắt Đường Lương",
                        judgeCard,
                        trapped,
                        "bị Cắt Đường Lương, BỎ QUA RÚT BÀI",
                        "thoát khỏi Cắt Đường Lương");
                }
            }
        }

        // 3. Trầm Ảo Sa Bẫy (Acedia)
        if (playerCard.HasDelayedScroll(CardSubType.Acedia))
        {
            var delayed = playerCard.GetDelayedScroll(CardSubType.Acedia);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, bossCard, playerCard, result => isCanceled = result);
            if (gameFinished)
            {
                playerTurnStartResolving = false;
                yield break;
            }

            if (isCanceled)
            {
                playerCard.RemoveDelayedScroll(CardSubType.Acedia);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, playerCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Trầm Ảo Sa Bẫy đã bị Diệu Kế Phá Mưu giải trừ trước khi phán xét!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("🕸️ [PHÁN XÉT TRẦM ẢO]: Đang lật bài phán xét mê hồn trận...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool trapped = (judgeCard.suit != CardSuit.Heart);
                    if (trapped) skipPlayPhase = true;

                    yield return AnimateJudgementResult(
                        playerCard,
                        bossCard,
                        CardSubType.Acedia,
                        "Trầm Ảo Sa Bẫy",
                        judgeCard,
                        trapped,
                        "sa bẫy Trầm Ảo, BỎ QUA GIAI ĐOẠN RA BÀI",
                        "thoát khỏi Trầm Ảo Sa Bẫy");
                }
            }
        }

        // --- GIAI ĐOẠN 2: RÚT BÀI ĐẦU LƯỢT ---
        if (!skipDrawPhase)
        {
            for (int i = 0; i < 2; i++)
            {
                var card = deckManager.DrawCard();
                if (card != null)
                {
                    yield return AnimateDealtCard(true);
                    playerHandUI.AddCard(card);
                    yield return new WaitForSeconds(0.1f);
                }
            }
        }
        else
        {
            SetLog("🌾 Bạn bị Cắt Đường Lương: Bỏ qua giai đoạn rút bài!");
        }

        if (skipPlayPhase)
        {
            playerPlayPhaseLocked = true;
            currentTargetCard = null;
            ClearFreePlayTargetVisuals();
            if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
            SetLog("🕸️ Bạn sa bẫy Trầm Ảo: Bỏ qua giai đoạn ra bài!");
        }
        else
        {
            playerPlayPhaseLocked = false;
            SetLog("✅ Giai đoạn phán xét/rút bài hoàn tất. Bạn có thể ra bài.");
        }

        playerTurnStartResolving = false;
    }
    #endregion

    #region 8. LOGIC DÙNG BÀI TỰ DO & THỐNG NHẤT
    private static bool RequiresTarget(CardModel card)
    {
        if (card == null) return false;
        if (IsSlashCard(card)) return true;
        return card.subType == CardSubType.Duel ||
               card.subType == CardSubType.Snatch ||
               card.subType == CardSubType.Dismantle ||
               card.subType == CardSubType.SupplyShortage ||
               card.subType == CardSubType.Acedia ||
               card.subType == CardSubType.FlawlessDefense;
    }

    private bool IsSlashLimitReached(CardModel card)
    {
        if (!IsSlashCard(card)) return false;
        // Nếu có Nỏ Thần Kim Quy thì bỏ giới hạn 1 Trảm/lượt
        if (playerCard != null && playerCard.HasEquipment(EquipmentType.Weapon, "Nỏ Thần")) return false;
        return slashesUsedThisTurn >= 1;
    }

    private void HandleFreePlayCardSelected(CardUI cardUI)
    {
        ClearFreePlayTargetVisuals();

        if (gameFinished || playerRescuePending || playerActionResolving || counterPromptActive)
        {
            if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
            return;
        }

        if (cardUI == null || cardUI.Data == null)
        {
            currentTargetCard = null;
            if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
            return;
        }

        if (!isPlayerTurn)
        {
            SetLog("⏳ Đang trong lượt của đối phương, vui lòng đợi...");
            if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
            return;
        }

        if (playerPlayPhaseLocked)
        {
            currentTargetCard = null;
            if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
            SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Bạn đã bị bỏ qua Giai đoạn Ra bài trong lượt này.");
            return;
        }

        var card = cardUI.Data;

        // Lá Đỡ là bài phản ứng, không thể đánh ra chủ động trong lượt (chỉ dùng khi bị tấn công hoặc dùng kỹ năng Tiến Thoái)
        if (card.subType == CardSubType.Dodge)
        {
            currentTargetCard = null;
            if (freePlayActionBtnGo != null)
            {
                freePlayActionBtnGo.SetActive(true);
                var btn = freePlayActionBtnGo.GetComponent<Button>();
                btn.interactable = false;
                var btnImg = freePlayActionBtnGo.GetComponent<Image>();
                btnImg.color = new Color(0.4f, 0.45f, 0.55f, 0.9f);
                freePlayActionBtnText.text = "🛡️ LÁ PHẢN ỨNG (DÙNG KHI BỊ TẤN CÔNG)";
            }
            SetLog("🛡️ [Đỡ]: Lá này chỉ dùng khi bạn bị đối phương tấn công (Trảm / Mưa Tên) hoặc bấm kỹ năng [⚡ TIẾN THOÁI] trên avatar tướng để đổi thành Trảm!");
            return;
        }

        // Bánh Chưng không thể ăn khi máu đã đầy
        if (card.subType == CardSubType.Peach && playerCard.CurrentHp >= playerCard.MaxHp)
        {
            currentTargetCard = null;
            if (freePlayActionBtnGo != null)
            {
                freePlayActionBtnGo.SetActive(true);
                var btn = freePlayActionBtnGo.GetComponent<Button>();
                btn.interactable = false;
                var btnImg = freePlayActionBtnGo.GetComponent<Image>();
                btnImg.color = new Color(0.4f, 0.45f, 0.55f, 0.9f);
                freePlayActionBtnText.text = "💮 MÁU ĐÃ ĐẦY (KHÔNG THỂ HỒI)";
            }
            SetLog($"💮 Máu của bạn đã đầy ({playerCard.CurrentHp}/{playerCard.MaxHp}), không thể sử dụng thêm Bánh Chưng!");
            return;
        }

        if (RequiresTarget(card))
        {
            // Kiểm tra quy tắc: 1 Trảm / lượt (trừ Nỏ Thần)
            if (IsSlashLimitReached(card))
            {
                SetLog("❌ <color=#FF5555>Bạn đã dùng 1 lá Trảm trong lượt này rồi!</color> (Trang bị [Nỏ Thần] để bỏ giới hạn).");
                if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
                return;
            }

            currentTargetCard = null; // Chờ người chơi nhấp chọn mục tiêu

            // Hiện nút ở trạng thái chờ chọn mục tiêu (màu xám / nhắc chọn mục tiêu)
            if (freePlayActionBtnGo != null)
            {
                freePlayActionBtnGo.SetActive(true);
                var btn = freePlayActionBtnGo.GetComponent<Button>();
                btn.interactable = false;
                var btnImg = freePlayActionBtnGo.GetComponent<Image>();
                btnImg.color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
                freePlayActionBtnText.text = "🎯 HÃY CHỌN MỤC TIÊU";
            }
            SetLog($"🎯 Đã chọn [{card.cardName}]. Hãy click chọn mục tiêu trên bàn để nhắm đòn!");
        }
        else
        {
            // Các lá bài không cần chọn mục tiêu (Trang Bị, Bánh Chưng, Rượu, Cẩm nang diện rộng/tự dùng)
            currentTargetCard = playerCard;
            if (freePlayActionBtnGo != null)
            {
                freePlayActionBtnGo.SetActive(true);
                var btn = freePlayActionBtnGo.GetComponent<Button>();
                btn.interactable = true;
                var btnImg = freePlayActionBtnGo.GetComponent<Image>();
                btnImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);

                if (card.category == CardCategory.Equipment)
                    freePlayActionBtnText.text = $"🛡️ TRANG BỊ [{card.cardName.ToUpper()}]";
                else if (card.subType == CardSubType.Peach)
                    freePlayActionBtnText.text = "💮 HỒI 1 HOA SEN MÁU";
                else if (card.subType == CardSubType.Wine)
                    freePlayActionBtnText.text = "🍶 UỐNG HỦ RƯỢU (+1 CÔNG)";
                else if (card.subType == CardSubType.ExNihilo)
                    freePlayActionBtnText.text = "📜 RÚT 2 LÁ BÀI (DỤNG BINH)";
                else if (card.subType == CardSubType.Harvest)
                    freePlayActionBtnText.text = "🍚 MỞ KHO CỨU TẾ (RÚT 1 LÁ)";
                else if (card.subType == CardSubType.BarbarianInvasion)
                    freePlayActionBtnText.text = "🪵 BÃI CỌC NGẦM (TẤT CẢ ĐỐI THỦ)";
                else if (card.subType == CardSubType.ArrowRain)
                    freePlayActionBtnText.text = "🏹 MƯA TÊN LIÊN CHÂU (TẤT CẢ ĐỐI THỦ)";
                else if (card.subType == CardSubType.Lightning)
                    freePlayActionBtnText.text = "⚡ GÀI THẦN SẤM BÁO ỨNG";
                else
                    freePlayActionBtnText.text = $"🃏 DÙNG [{card.cardName.ToUpper()}]";
            }
            SetLog($"💡 Nhấn nút [{freePlayActionBtnText.text}] để sử dụng lá bài.");
        }
    }

    public int CalculateDistance(GeneralCardUI from, GeneralCardUI to)
    {
        if (from == null || to == null || from == to) return 0;
        int baseDist = 1;
        int defMod = to.GetDefensiveDistanceModifier();
        int offMod = from.GetOffensiveDistanceModifier();
        return Mathf.Max(1, baseDist + defMod + offMod);
    }

    public bool IsTargetInAttackRange(GeneralCardUI attacker, GeneralCardUI target, CardModel card = null)
    {
        if (attacker == null || target == null) return false;
        int distance = CalculateDistance(attacker, target);
        if ((attacker.GeneralName.Contains("Đào Hãn") || attacker.GeneralName.Contains("Nồi Hầu")) && (card == null || IsSlashCard(card)))
        {
            distance = Mathf.Max(1, distance - 2); // Kỹ năng Xạ Thuẫn: Giảm 2 cự ly khi dùng Trảm
        }
        int range = attacker.GetAttackRange();
        return range >= distance;
    }

    private void OnGeneralTargetSelectedForFreePlay(GeneralCardUI general)
    {
        if (!isPlayerTurn || playerPlayPhaseLocked || playerActionResolving || gameFinished || counterPromptActive) return;
        var selected = playerHandUI.SelectedCard;
        if (selected == null || selected.Data == null)
        {
            SetLog($"ℹ️ {general.GeneralName}: {general.CurrentHp}/{general.MaxHp} Máu, {general.HandCardCount} bài trên tay.");
            return;
        }

        var card = selected.Data;
        if (RequiresTarget(card))
        {
            if (general == playerCard || general.CurrentHp <= 0)
            {
                currentTargetCard = null;
                ClearFreePlayTargetVisuals();
                if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
                SetLog("❌ Lá này chỉ được nhắm vào một tướng đối phương còn sống.");
                return;
            }
            currentTargetCard = general;
            AudioManager.Instance.PlayCardSelect();

            HighlightGeneralAsTargetForFreePlay(general);

            if (freePlayActionBtnGo != null)
            {
                freePlayActionBtnGo.SetActive(true);
                var btn = freePlayActionBtnGo.GetComponent<Button>();
                bool inRange = true;
                if (IsSlashCard(card) && !IsTargetInAttackRange(playerCard, general)) inRange = false;
                if (card.subType == CardSubType.Snatch && CalculateDistance(playerCard, general) > 1) inRange = false;
                if (card.subType == CardSubType.SupplyShortage && CalculateDistance(playerCard, general) > 1) inRange = false;

                btn.interactable = inRange;
                var btnImg = freePlayActionBtnGo.GetComponent<Image>();
                if (inRange)
                {
                    btnImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);
                    freePlayActionBtnText.text = $"⚔️ DÙNG [{card.cardName.ToUpper()}] ➜ {general.GeneralName.ToUpper()}";
                }
                else
                {
                    btnImg.color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
                    int dist = CalculateDistance(playerCard, general);
                    freePlayActionBtnText.text = $"❌ NGOÀI TẦM TÁC CHIẾN (CỰ LY {dist})";
                }
            }
            SetLog($"🎯 Đã chọn mục tiêu [{general.GeneralName}]! Nhấn nút [{freePlayActionBtnText.text}] để xuất chiêu.");
        }
    }

    private void HighlightGeneralAsTargetForFreePlay(GeneralCardUI target)
    {
        ClearFreePlayTargetVisuals();

        freePlayBossTargetBorder = new GameObject("FreePlayTargetBorder", typeof(RectTransform), typeof(Image));
        freePlayBossTargetBorder.transform.SetParent(target.transform, false);
        freePlayBossTargetBorder.transform.SetAsLastSibling();
        var img = freePlayBossTargetBorder.GetComponent<Image>();
        img.sprite = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        img.type = Image.Type.Sliced;
        img.color = new Color(1f, 0.85f, 0.2f, 0.95f);
        img.raycastTarget = false;
        Fill(freePlayBossTargetBorder.GetComponent<RectTransform>(), new Vector2(-6, -6), new Vector2(6, 6));
    }

    private void ClearFreePlayTargetVisuals()
    {
        if (freePlayBossTargetBorder != null) Destroy(freePlayBossTargetBorder);
        if (freePlayBossHitbox != null) Destroy(freePlayBossHitbox);
    }

    private void HandleCardPlayed(CardUI cardUI)
    {
        if (cardUI == null) return;
        if (gameFinished || playerRescuePending || playerActionResolving || counterPromptActive || !isPlayerTurn || playerPlayPhaseLocked)
        {
            if (playerPlayPhaseLocked)
                SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Bạn đã bị bỏ qua Giai đoạn Ra bài trong lượt này.");
            return;
        }
        if (RequiresTarget(cardUI.Data) && currentTargetCard == null)
        {
            SetLog($"🎯 Vui lòng chạm chọn một mục tiêu trên bàn đấu trước khi dùng [{cardUI.Data.cardName}]!");
            return;
        }
        var target = currentTargetCard != null ? currentTargetCard : playerCard;
        ExecutePlayCard(cardUI, target);
    }

    private void ExecutePlayCard(CardUI cardUI, GeneralCardUI target)
    {
        if (cardUI == null || cardUI.Data == null) return;
        if (gameFinished || playerRescuePending || playerActionResolving || counterPromptActive || !isPlayerTurn || playerPlayPhaseLocked)
        {
            if (playerPlayPhaseLocked)
                SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Bạn đã bị bỏ qua Giai đoạn Ra bài trong lượt này.");
            return;
        }
        var card = cardUI.Data;

        if (RequiresTarget(card) && target == null)
        {
            SetLog($"🎯 Vui lòng chạm chọn một mục tiêu trên bàn đấu trước khi dùng [{card.cardName}]!");
            return;
        }

        if (RequiresTarget(card) && (target == playerCard || target.CurrentHp <= 0))
        {
            SetLog("❌ Lá này chỉ được nhắm vào một tướng đối phương còn sống.");
            return;
        }

        if (IsSlashCard(card))
        {
            if (IsSlashLimitReached(card))
            {
                SetLog("❌ <color=#FF5555>Bạn đã dùng 1 lá Trảm trong lượt này rồi!</color> (Trang bị [Nỏ Thần] để bỏ giới hạn).");
                return;
            }

            if (!IsTargetInAttackRange(playerCard, target))
            {
                int dist = CalculateDistance(playerCard, target);
                int range = playerCard.GetAttackRange();
                SetLog($"❌ <color=#FF5555>Mục tiêu ở Cự ly {dist} vượt quá Tầm đánh {range} của bạn!</color> (Trang bị Vũ khí tầm xa hoặc Ngựa công [-1]).");
                return;
            }
            slashesUsedThisTurn++;
        }

        if (card.subType == CardSubType.Dodge)
        {
            if (!CanActAsSlash(playerCard, card))
            {
                SetLog("🛡️ [Đỡ]: Lá này là bài phản ứng, chỉ dùng khi bạn bị đối phương tấn công (hoặc bấm kỹ năng [⚡ TIẾN THOÁI] để đổi thành Trảm)!");
                return;
            }
        }

        if (card.subType == CardSubType.Peach && playerCard.CurrentHp >= playerCard.MaxHp)
        {
            SetLog($"💮 Máu của bạn đã đầy ({playerCard.CurrentHp}/{playerCard.MaxHp}), không thể sử dụng thêm Bánh Chưng!");
            return;
        }

        if (card.subType == CardSubType.Snatch && CalculateDistance(playerCard, target) > 1)
        {
            int dist = CalculateDistance(playerCard, target);
            SetLog($"❌ <color=#FF5555>Đột Kích Trộm Lương chỉ tác dụng ở Cự ly 1! (Hiện tại cự ly là {dist}).</color> Trang bị Ngựa công [-1] để giảm cự ly.");
            return;
        }

        if (card.subType == CardSubType.SupplyShortage && CalculateDistance(playerCard, target) > 1)
        {
            int dist = CalculateDistance(playerCard, target);
            SetLog($"❌ <color=#FF5555>Cắt Đường Lương chỉ gài ở Cự ly 1 (hiện tại {dist}).</color>");
            return;
        }

        if ((card.subType == CardSubType.Dismantle ||
             card.subType == CardSubType.Snatch ||
             card.subType == CardSubType.FlawlessDefense) &&
            BuildTargetCardOptions(target, card.subType != CardSubType.Dismantle).Count == 0)
        {
            SetLog($"ℹ️ {target.GeneralName} không có lá bài hợp lệ để [{card.cardName}] tác động.");
            return;
        }

        // Do not consume a delayed scroll when the destination already has one.
        if (card.category == CardCategory.DelayedScroll)
        {
            GeneralCardUI delayedTarget = card.subType == CardSubType.Lightning ? playerCard : target;
            if (delayedTarget == null || delayedTarget.HasDelayedScroll(card.subType))
            {
                SetLog($"⚠️ {delayedTarget?.GeneralName ?? "Mục tiêu"} đã có [{card.cardName}] trong vùng Phán Xét.");
                return;
            }
        }

        playerActionResolving = true;
        var screenPos = RectTransformUtility.WorldToScreenPoint(null, cardUI.transform.position);
        playerHandUI.RemoveCard(cardUI);
        if (card.category != CardCategory.Equipment && card.category != CardCategory.DelayedScroll)
        {
            deckManager.DiscardCard(card);
        }

        // Slash cards use the hand-to-center animation below. Other cards get
        // the persistent center presentation immediately.
        if (!IsSlashCard(card))
        {
            GeneralCardUI centerTarget = (RequiresTarget(card) && target != null && target != playerCard) ? target : null;
            ShowCardAtCenter(card, playerCard, centerTarget);
        }

        if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
        ClearFreePlayTargetVisuals();

        // If the card is an Instant Scroll, resolve via ResolvePlayerScrollAction
        // which first checks the bidirectional Diệu Kế Phá Mưu nullification chain!
        if (card.category == CardCategory.InstantScroll)
        {
            StartCoroutine(ResolvePlayerScrollAction(card, target));
            return;
        }
        else if (card.category == CardCategory.DelayedScroll)
        {
            StartCoroutine(ResolvePlayerDelayedScrollPlacement(card, target));
            return;
        }

        switch (card.category)
        {
            case CardCategory.Basic:
                if (CanActAsSlash(playerCard, card))
                {
                    int dmg = isWineBuffActive ? 2 : 1;
                    string wineLog = isWineBuffActive ? " (kèm hiệu ứng Hủ Rượu: +1 Sát thương!)" : "";
                    isWineBuffActive = false;

                    StartCoroutine(ResolvePlayerSlashAction(card, target, screenPos, dmg, wineLog));
                    return;
                }
                else if (card.subType == CardSubType.Dodge)
                {
                    SetLog("🛡️ Lá Đỡ chỉ dùng để hóa giải đòn Trảm của đối phương (hoặc dùng [TIẾN THOÁI] đổi thành Trảm)!");
                }
                else if (card.subType == CardSubType.Peach)
                {
                    playerCard.Heal(1);
                    AudioManager.Instance.PlayHeal();
                    SetLog($"💮 Bạn dùng [{card.cardName}] hồi 1 hoa sen máu! (HP: {playerCard.CurrentHp}/{playerCard.MaxHp})");
                }
                else if (card.subType == CardSubType.Wine)
                {
                    isWineBuffActive = true;
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🍶 Bạn uống [{card.cardName}]: Đòn Trảm kế tiếp trong lượt này sẽ gây +1 sát thương (+2 Sát thương tổng)! ");
                }
                break;

            case CardCategory.Equipment:
                AudioManager.Instance.PlaySkill();
                if (!playerCard.TryEquip(card, out var replacedEquipment))
                {
                    // Keep an invalid equipment card available instead of silently losing it.
                    playerHandUI.AddCard(card);
                    SetLog($"❌ Không thể trang bị [{card.cardName}].");
                    break;
                }
                if (replacedEquipment != null) deckManager.DiscardCard(replacedEquipment);
                SetLog($"🛡️ Đã trang bị [{card.cardName}]: {card.description}");
                break;
        }

        FinishPlayerAction();
    }

    private IEnumerator ResolvePlayerScrollAction(CardModel card, GeneralCardUI target)
    {
        bool isCanceled = false;
        yield return ResolveNullificationChain(card, playerCard, target, result => isCanceled = result);
        if (gameFinished)
        {
            FinishPlayerAction();
            yield break;
        }

        if (isCanceled)
        {
            if (card.category == CardCategory.DelayedScroll)
                deckManager.DiscardCard(card);
            SetLog($"🛡️ Lá cẩm nang [{card.cardName}] đã bị Diệu Kế Phá Mưu triệt tiêu, không có tác dụng!");
            FinishPlayerAction();
            yield break;
        }

        switch (card.category)
        {
            case CardCategory.InstantScroll:
                if (card.subType == CardSubType.ExNihilo)
                {
                    for (int k = 0; k < 2; k++)
                    {
                        var drawn = deckManager.DrawCard();
                        if (drawn != null)
                        {
                            yield return AnimateDealtCard(true);
                            playerHandUI.AddCard(drawn);
                        }
                        yield return new WaitForSeconds(0.12f);
                    }
                    AudioManager.Instance.PlayCardDraw();
                    SetLog("📜 [Dụng Binh Như Thần]: Rút 2 lá bài từ bộ bài vào tay!");
                }
                else if (card.subType == CardSubType.Harvest)
                {
                    yield return ResolveHarvest(card, playerCard);
                }
                else if (card.subType == CardSubType.Duel)
                {
                    yield return ResolveDuel(playerCard, target);
                }
                else if (card.subType == CardSubType.BarbarianInvasion || card.subType == CardSubType.ArrowRain)
                {
                    yield return ResolveGlobalScroll(card, playerCard);
                }
                else if (card.subType == CardSubType.Dismantle)
                {
                    bool opened = ShowCardStealOrDestroyModal(target, false, "🏚️ VƯỜN KHÔNG NHÀ TRỐNG: CHỌN 1 LÁ ĐỂ PHÁ HỦY", (discardedCard) =>
                    {
                        deckManager.DiscardCard(discardedCard);
                        ShowCardAtCenter(discardedCard, target, null, $"Lá [{discardedCard.cardName}] bị phá hủy");
                        AudioManager.Instance.PlaySkill();
                        SetLog($"🏚️ [Vườn Không Nhà Trống]: Đã phá hủy lá [{discardedCard.cardName}] của Sơn Tặc!");
                        FinishPlayerAction();
                    });
                    if (!opened) FinishPlayerAction();
                    else yield break;
                }
                else if (card.subType == CardSubType.Snatch)
                {
                    bool opened = ShowCardStealOrDestroyModal(target, true, "🌾 ĐỘT KÍCH TRỘM LƯƠNG: CHỌN 1 LÁ ĐỂ CƯỚP VỀ TAY", (stolenCard) =>
                    {
                        playerHandUI.AddCard(stolenCard);
                        AudioManager.Instance.PlayCardDraw();
                        SetLog($"🌾 [Đột Kích Trộm Lương]: Bạn đã cướp thành công 1 lá bài từ khu vực của Sơn Tặc về tay!");
                        FinishPlayerAction();
                    });
                    if (!opened) FinishPlayerAction();
                    else yield break;
                }
                else if (card.subType == CardSubType.FlawlessDefense)
                {
                    bool opened = ShowCardStealOrDestroyModal(target, false, "🛡️ DIỆU KẾ PHÁ MƯU: CHỌN 1 LÁ ĐỂ HỦY BỎ", (discardedCard) =>
                    {
                        deckManager.DiscardCard(discardedCard);
                        ShowCardAtCenter(discardedCard, target, null, $"Lá [{discardedCard.cardName}] bị hủy");
                        AudioManager.Instance.PlaySkill();
                        SetLog($"🛡️ [Diệu Kế Phá Mưu]: Bạn đã thi triển Diệu Kế Phá Mưu, hủy lá [{discardedCard.cardName}] của Sơn Tặc!");
                        FinishPlayerAction();
                    });
                    if (!opened) FinishPlayerAction();
                    else yield break;
                }
                break;
        }

        FinishPlayerAction();
    }

    private IEnumerator ResolvePlayerDelayedScrollPlacement(CardModel card, GeneralCardUI target)
    {
        AudioManager.Instance.PlaySkill();
        if (card.subType == CardSubType.Lightning)
        {
            if (playerCard.AddDelayedScroll(card))
            {
                ShowCardAtCenter(card, playerCard);
                SetLog("⚡ [Thần Sấm Báo Ứng]: Đã đặt Thần Sấm Báo Ứng vào vùng Phán Xét của bạn!");
            }
            else
            {
                playerHandUI.AddCard(card);
            }
        }
        else if (card.subType == CardSubType.SupplyShortage)
        {
            if (target.AddDelayedScroll(card))
            {
                ShowCardAtCenter(card, playerCard, target);
                SetLog("🌾 [Cắt Đường Lương]: Đã gài Cắt Đường Lương vào vùng Phán Xét của Sơn Tặc!");
            }
            else
            {
                playerHandUI.AddCard(card);
            }
        }
        else if (card.subType == CardSubType.Acedia)
        {
            if (target.AddDelayedScroll(card))
            {
                ShowCardAtCenter(card, playerCard, target);
                SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Đã gài Trầm Ảo Sa Bẫy vào vùng Phán Xét của Sơn Tặc!");
            }
            else
            {
                playerHandUI.AddCard(card);
            }
        }
        yield return new WaitForSeconds(0.4f);
        FinishPlayerAction();
    }

    private void FinishPlayerAction()
    {
        playerActionResolving = false;
        if (gameFinished && activeCardPickModal != null)
        {
            Destroy(activeCardPickModal);
            activeCardPickModal = null;
        }
    }

    private IEnumerator ResolvePlayerEffect(IEnumerator effect)
    {
        if (effect != null)
            yield return StartCoroutine(effect);
        FinishPlayerAction();
    }

    private IEnumerator ResolvePlayerSlashAction(
        CardModel slashCard,
        GeneralCardUI target,
        Vector2 sourceScreenPosition,
        int damage,
        string wineLog)
    {
        yield return AnimateSlashAttack(slashCard, target, sourceScreenPosition, null);
        yield return ResolveSlashDefense(slashCard, playerCard, target, damage, wineLog);
        FinishPlayerAction();
    }

    private bool ShowCardStealOrDestroyModal(GeneralCardUI target, bool isSteal, string actionTitle, Action<CardModel> onCardSelected)
    {
        if (target == null)
        {
            SetLog("❌ Không tìm thấy mục tiêu để chọn bài.");
            return false;
        }

        // Vườn Không Nhà Trống/Thương Ngâu chỉ tác động tay hoặc trang bị;
        // Đột Kích được phép lấy thêm lá trì hoãn, còn Diệu Kế có thể hủy
        // bất kỳ lá nào đang nằm trên bàn.
        bool allowDelayed = isSteal || actionTitle.IndexOf("DIỆU KẾ", StringComparison.OrdinalIgnoreCase) >= 0;
        var options = BuildTargetCardOptions(target, allowDelayed);
        if (options.Count == 0)
        {
            SetLog($"ℹ️ {target.GeneralName} không có lá bài hợp lệ trong tay, vùng trang bị hoặc vùng trì hoãn.");
            return false;
        }

        var font = ThemeUI.FontMain;
        var modalGo = new GameObject("CardPickModal", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        modalGo.transform.SetParent(transform, false);
        modalGo.transform.SetAsLastSibling();
        activeCardPickModal = modalGo;

        // 1. Nền mờ phía sau modal (tối sẫm high-contrast)
        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(modalGo.GetComponent<RectTransform>());

        // 2. Khung Container chính
        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(760f, 450f);
        panelRt.anchoredPosition = Vector2.zero;

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.08f, 0.11f, 0.20f, 0.98f); // Nền xanh tím sẫm hoàng gia sắc nét

        // Viền hào quang vàng phát sáng cực kỳ nổi bật xung quanh panel
        var outerBorderGo = new GameObject("OuterBorder", typeof(RectTransform), typeof(Image));
        outerBorderGo.transform.SetParent(panelGo.transform, false);
        outerBorderGo.transform.SetAsFirstSibling();
        var obImg = outerBorderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { obImg.sprite = frameSpr; obImg.type = Image.Type.Sliced; }
        obImg.color = new Color(1f, 0.85f, 0.28f, 0.98f);
        obImg.raycastTarget = false;
        Fill(outerBorderGo.GetComponent<RectTransform>(), new Vector2(-5, -5), new Vector2(5, 5));

        // 3. Header Banner Tiêu Đề Rõ Nét
        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSpr != null) { hImg.sprite = badgeSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = isSteal 
            ? new Color(0.12f, 0.45f, 0.85f, 0.98f)   // Trộm Lương: Xanh lam tươi
            : new Color(0.85f, 0.25f, 0.15f, 0.98f);  // Phá Mưu / Vườn Không Nhà Trống: Đỏ tươi

        var hRt = headerGo.GetComponent<RectTransform>();
        hRt.anchorMin = new Vector2(0.5f, 1f);
        hRt.anchorMax = new Vector2(0.5f, 1f);
        hRt.pivot = new Vector2(0.5f, 1f);
        hRt.sizeDelta = new Vector2(700f, 48f);
        hRt.anchoredPosition = new Vector2(0, -12f);

        var titleGo = new GameObject("TitleText", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(headerGo.transform, false);
        var tText = titleGo.GetComponent<Text>();
        tText.font = font;
        tText.fontSize = 17;
        tText.fontStyle = FontStyle.Bold;
        tText.alignment = TextAnchor.MiddleCenter;
        tText.color = new Color(1f, 0.94f, 0.55f, 1f);
        tText.text = actionTitle;
        AddTextShadow(tText);
        Fill(titleGo.GetComponent<RectTransform>());

        // Subtitle dòng nhắc nhở
        var subTitleGo = new GameObject("SubTitle", typeof(RectTransform), typeof(Text));
        subTitleGo.transform.SetParent(panelGo.transform, false);
        var subRt = subTitleGo.GetComponent<RectTransform>();
        subRt.anchorMin = new Vector2(0.5f, 1f);
        subRt.anchorMax = new Vector2(0.5f, 1f);
        subRt.pivot = new Vector2(0.5f, 1f);
        subRt.sizeDelta = new Vector2(700f, 24f);
        subRt.anchoredPosition = new Vector2(0, -66f);
        var subTxt = subTitleGo.GetComponent<Text>();
        subTxt.font = font;
        subTxt.fontSize = 12;
        subTxt.alignment = TextAnchor.MiddleCenter;
        subTxt.color = new Color(0.9f, 0.93f, 1f, 1f);
        subTxt.text = $"💡 Chạm chọn 1 lá thật của tướng [{target.GeneralName}] ({options.Count} lựa chọn):";

        // 4. Viewport cuộn ngang để mọi lá thật trong tay/trang bị/trì hoãn
        // đều có thể chọn, thay vì tạo lá úp giả rồi rút nhầm từ bộ bài.
        var viewportGo = new GameObject("CardsViewport", typeof(RectTransform), typeof(Image), typeof(Mask), typeof(ScrollRect));
        viewportGo.transform.SetParent(panelGo.transform, false);
        var viewportRt = viewportGo.GetComponent<RectTransform>();
        viewportRt.anchorMin = viewportRt.anchorMax = viewportRt.pivot = new Vector2(0.5f, 0.5f);
        viewportRt.sizeDelta = new Vector2(710f, 250f);
        viewportRt.anchoredPosition = new Vector2(0f, -42f);
        var viewportImg = viewportGo.GetComponent<Image>();
        viewportImg.color = new Color(0.02f, 0.04f, 0.09f, 0.35f);
        var mask = viewportGo.GetComponent<Mask>();
        mask.showMaskGraphic = false;

        var cardsContainerGo = new GameObject("CardsContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        cardsContainerGo.transform.SetParent(viewportGo.transform, false);
        var contentRt = cardsContainerGo.GetComponent<RectTransform>();
        contentRt.anchorMin = new Vector2(0f, 0.5f);
        contentRt.anchorMax = new Vector2(0f, 0.5f);
        contentRt.pivot = new Vector2(0f, 0.5f);
        contentRt.sizeDelta = new Vector2(Mathf.Max(710f, options.Count * 132f), 190f);
        contentRt.anchoredPosition = new Vector2(10f, 0f);
        var hlg = cardsContainerGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 14f;
        hlg.padding = new RectOffset(4, 4, 12, 12);
        hlg.childAlignment = TextAnchor.MiddleLeft;
        hlg.childControlWidth = false;
        hlg.childControlHeight = false;
        hlg.childForceExpandWidth = false;
        hlg.childForceExpandHeight = false;

        var scroll = viewportGo.GetComponent<ScrollRect>();
        scroll.viewport = viewportRt;
        scroll.content = contentRt;
        scroll.horizontal = true;
        scroll.vertical = false;
        scroll.movementType = ScrollRect.MovementType.Clamped;
        scroll.scrollSensitivity = 45f;

        int handIndex = 1;
        foreach (var option in options)
        {
            if (option == null || option.Card == null) continue;
            var selectedOption = option;

            GameObject cardItemGo;

            if (selectedOption.Zone == TargetCardZone.Hand)
            {
                // Lá bài trên tay của đối phương: PHẢI LÀ LÁ ÚP (Ẩn thông tin bài, chỉ hiện biểu tượng mặt lưng bài và số thứ tự)
                cardItemGo = CreateFaceDownCardItem(cardsContainerGo.transform, new Vector2(118f, 162f), $"LÁ BÀI #{handIndex}", font);
                handIndex++;
            }
            else
            {
                // Lá Trang Bị hoặc Cẩm Nang Trì Hoãn: LÁ NGỬA (Hiện rõ tên và loại trang bị)
                var cardUI = CardUI.Create(cardsContainerGo.transform, selectedOption.Card, new Vector2(118f, 162f));
                if (cardUI == null) continue;
                cardItemGo = cardUI.gameObject;
            }

            AddTargetZoneLabel(cardItemGo.transform, selectedOption.Label, font);

            void HandleOptionClick()
            {
                if (!TryRemoveTargetCardOption(target, selectedOption))
                {
                    SetLog("⚠️ Lá bài này không còn ở vùng mục tiêu (có thể đã được dùng). Hãy chọn lá khác.");
                    return;
                }

                AudioManager.Instance.PlayCardSelect();
                if (activeCardPickModal == modalGo) activeCardPickModal = null;
                Destroy(modalGo);
                onCardSelected?.Invoke(selectedOption.Card);
            }

            var btn = cardItemGo.GetComponent<Button>();
            if (btn != null)
            {
                btn.onClick.AddListener(HandleOptionClick);
            }
            else
            {
                var cardUI = cardItemGo.GetComponent<CardUI>();
                if (cardUI != null)
                {
                    cardUI.OnCardClicked += _ => HandleOptionClick();
                }
            }
        }

        return true;
    }

    private GameObject CreateFaceDownCardItem(Transform parent, Vector2 size, string label, Font font)
    {
        var go = new GameObject("FaceDownCardItem", typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var rt = go.GetComponent<RectTransform>();
        rt.sizeDelta = size;

        var img = go.GetComponent<Image>();
        var backSprite = LotusHealthUI.LoadSpriteFromResources("UI/card_back");
        if (backSprite != null)
        {
            img.sprite = backSprite;
            img.type = Image.Type.Sliced;
            img.color = Color.white;
        }
        else
        {
            img.color = new Color(0.14f, 0.18f, 0.28f, 0.98f);
        }

        // Khung viền
        var borderGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.95f, 0.8f, 0.3f, 0.9f);
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>());

        // Biểu tượng mặt lưng bài và số thứ tự
        var txtGo = new GameObject("CenterText", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(go.transform, false);
        var txt = txtGo.GetComponent<Text>();
        txt.font = font;
        txt.fontSize = 15;
        txt.fontStyle = FontStyle.Bold;
        txt.alignment = TextAnchor.MiddleCenter;
        txt.lineSpacing = 1.3f;
        txt.text = $"🎴\n<size=12><color=#FFD700>{label}</color></size>";
        txt.color = Color.white;
        AddTextShadow(txt);
        Fill(txtGo.GetComponent<RectTransform>(), new Vector2(6, 6), new Vector2(-6, -6));

        return go;
    }

    private List<TargetCardOption> BuildTargetCardOptions(GeneralCardUI target, bool allowDelayed)
    {
        var options = new List<TargetCardOption>();

        if (target == playerCard && playerHandUI != null)
        {
            foreach (var cardUI in playerHandUI.Cards)
            {
                if (cardUI == null || cardUI.Data == null) continue;
                options.Add(new TargetCardOption
                {
                    Card = cardUI.Data,
                    Zone = TargetCardZone.Hand,
                    Label = "TRÊN TAY"
                });
            }
        }
        else if (target == bossCard)
        {
            foreach (var card in bossHandCards)
            {
                if (card == null) continue;
                options.Add(new TargetCardOption
                {
                    Card = card,
                    Zone = TargetCardZone.Hand,
                    Label = "TRÊN TAY"
                });
            }
        }

        var equipmentTypes = new[]
        {
            EquipmentType.Weapon,
            EquipmentType.Armor,
            EquipmentType.OffensiveMount,
            EquipmentType.DefensiveMount,
            EquipmentType.Treasure
        };
        foreach (var equipmentType in equipmentTypes)
        {
            var card = target.GetEquippedCard(equipmentType);
            if (card == null) continue;
            options.Add(new TargetCardOption
            {
                Card = card,
                Zone = TargetCardZone.Equipment,
                EquipmentType = equipmentType,
                Label = "TRANG BỊ"
            });
        }

        if (!allowDelayed) return options;

        foreach (var card in target.DelayedScrolls)
        {
            if (card == null) continue;
            options.Add(new TargetCardOption
            {
                Card = card,
                Zone = TargetCardZone.Delayed,
                DelayedType = card.subType,
                Label = "TRÌ HOÃN"
            });
        }

        return options;
    }

    private void AddTargetZoneLabel(Transform cardTransform, string zoneLabel, Font font)
    {
        if (cardTransform == null || string.IsNullOrEmpty(zoneLabel)) return;
        var labelGo = new GameObject("TargetZoneLabel", typeof(RectTransform), typeof(Text));
        labelGo.transform.SetParent(cardTransform, false);
        var label = labelGo.GetComponent<Text>();
        label.font = font;
        label.fontSize = 9;
        label.fontStyle = FontStyle.Bold;
        label.alignment = TextAnchor.MiddleCenter;
        label.color = new Color(1f, 0.85f, 0.35f, 1f);
        label.text = zoneLabel;
        label.raycastTarget = false;
        var rt = labelGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 0f);
        rt.anchorMax = new Vector2(1f, 0f);
        rt.pivot = new Vector2(0.5f, 0f);
        rt.sizeDelta = new Vector2(0f, 18f);
        rt.anchoredPosition = new Vector2(0f, 2f);
        AddTextShadow(label);
    }

    private bool TryRemoveTargetCardOption(GeneralCardUI target, TargetCardOption option)
    {
        if (target == null || option == null || option.Card == null) return false;

        switch (option.Zone)
        {
            case TargetCardZone.Hand:
                if (target == playerCard && playerHandUI != null)
                {
                    foreach (var cardUI in playerHandUI.Cards)
                    {
                        if (cardUI != null && SameCard(cardUI.Data, option.Card))
                        {
                            return playerHandUI.RemoveCard(cardUI);
                        }
                    }
                    return false;
                }

                if (target == bossCard)
                {
                    return BossRemoveSpecificCard(option.Card);
                }
                return false;

            case TargetCardZone.Equipment:
                var currentEquipment = target.GetEquippedCard(option.EquipmentType);
                if (!SameCard(currentEquipment, option.Card)) return false;
                if (!target.TryUnequip(option.EquipmentType, out var removedEquipment)) return false;
                return SameCard(removedEquipment, option.Card);

            case TargetCardZone.Delayed:
                var delayed = target.GetDelayedScroll(option.DelayedType);
                if (!SameCard(delayed, option.Card)) return false;
                return target.RemoveDelayedScroll(option.DelayedType);

            default:
                return false;
        }
    }

    private static bool SameCard(CardModel left, CardModel right)
    {
        if (ReferenceEquals(left, right)) return true;
        if (left == null || right == null || string.IsNullOrEmpty(left.id) || string.IsNullOrEmpty(right.id)) return false;
        return string.Equals(left.id, right.id, StringComparison.Ordinal);
    }


    private IEnumerator ResolveSlashDefense(
        CardModel slashCard,
        GeneralCardUI attacker,
        GeneralCardUI defender,
        int damage,
        string wineLog,
        bool allowWeaponFollowup = true)
    {
        defender.SetAwaitingReaction(true); // Nhấp nháy avatar tướng phòng thủ
        // 1. Kiểm tra Giáp Đồng Sơn Vi (Bronze Armor)
        if (defender.HasEquipment(EquipmentType.Armor, "Giáp Đồng") && slashCard.subType == CardSubType.AttackNormal)
        {
            AudioManager.Instance.PlayParry();
            SetLog($"🛡️ <color=#70D8FF><b>[GIÁP ĐỒNG SƠN VI]</b></color>: Giáp Đồng vô hiệu hóa hoàn toàn đòn [{slashCard.cardName}] không thuộc tính của {attacker.GeneralName}!");
            yield break;
        }

        // 2. Xử lý phản ứng Đỡ của Defender (Boss hoặc Player).
        // Khiên Mây is intentionally not checked here: it only reacts to
        // offensive global scrolls (Bãi Cọc/Mưa Tên), not Trảm.
        var defenseResult = SlashDefenseResult.Hit;
        if (defender == bossCard)
        {
            yield return new WaitForSeconds(0.4f);
            var dodgeCard = BossPopLegalDodge(slashCard, attacker);

            if (dodgeCard != null)
            {
                deckManager.DiscardCard(dodgeCard);
                ShowCardAtCenter(dodgeCard, bossCard);
                AudioManager.Instance.PlayParry();
                SetLog($"🛡️ Sơn Tặc đánh ra lá [{dodgeCard.cardName}] né đòn Trảm!");
                defenseResult = SlashDefenseResult.Dodged;
            }
            else if (attacker.HasEquipment(EquipmentType.Weapon, "Súng Thần Công"))
            {
                SetLog($"💥 <color=#FF5555><b>[SÚNG THẦN CÔNG HỒ TRIỀU]</b></color>: Sơn Tặc không có lá Đỡ hợp lệ cùng quy tắc chất!");
            }
        }
        else if (defender == playerCard)
        {
            yield return AwaitForPlayerSlashDefense(slashCard, damage, result => defenseResult = result);
        }

        if (defenseResult == SlashDefenseResult.Negated)
            yield break;

        // 3. Nếu bị Đỡ: kiểm tra kỹ năng vũ khí của attacker.
        if (defenseResult == SlashDefenseResult.Dodged)
        {
            if (allowWeaponFollowup)
            {
                yield return ResolveWeaponAfterDodge(attacker, defender);
            }
            yield break;
        }

        // 4. Trúng đòn: Áo Bào giảm toàn bộ sát thương Trảm đi 1 (sàn 0).
        int finalDamage = damage;
        if (defender.HasEquipment(EquipmentType.Armor, "Áo Bào"))
        {
            int reducedDamage = Mathf.Max(0, finalDamage - 1);
            SetLog($"🛡️ <color=#FFD700><b>[ÁO BÀO HOÀNG TỘC]</b></color>: Áo Bào giảm sát thương từ {finalDamage} xuống còn {reducedDamage}!");
            finalDamage = reducedDamage;
        }

        if (finalDamage > 0)
        {
            defender.TakeDamage(finalDamage);
            AudioManager.Instance.PlayDamage();
        }
        SetLog($"⚔️ {attacker.GeneralName} tung chiêu [{slashCard.cardName}]{wineLog}! {defender.GeneralName} trúng đòn mất {finalDamage} máu.");
        if (defender == bossCard)
            CheckBossDefeat();
        else if (defender == playerCard)
            yield return ResolvePlayerNearDeath();

        if (gameFinished) yield break;

        // 6. Sau khi gây sát thương: Kiểm tra Thương Ngâu Lãng Bạc (phá 1 bài của mục tiêu)
        // Thương Ngâu only triggers after the Trảm actually deals damage.
        // Áo Bào can reduce a 1-damage attack to zero, which is not a
        // successful hit for the weapon's discard effect.
        if (finalDamage > 0 && attacker.HasEquipment(EquipmentType.Weapon, "Thương Ngâu") && defender.CurrentHp > 0)
        {
            yield return new WaitForSeconds(0.4f);
            if (BuildTargetCardOptions(defender, false).Count == 0)
            {
                SetLog($"🔱 [Thương Ngâu Lãng Bạc]: {defender.GeneralName} không còn lá trên tay hoặc trang bị để hủy.");
                yield break;
            }

            if (attacker == playerCard)
            {
                bool selectionResolved = false;
                bool modalOpened = ShowCardStealOrDestroyModal(defender, false, "🔱 THƯƠNG NGÂU LÃNG BẠC: HỦY 1 LÁ CỦA MỤC TIÊU", (discardedCard) =>
                {
                    deckManager.DiscardCard(discardedCard);
                    ShowCardAtCenter(discardedCard, defender, null, $"Lá [{discardedCard.cardName}] bị phá hủy");
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🔱 [Thương Ngâu Lãng Bạc]: Đòn đâm xé giáp phá hủy lá [{discardedCard.cardName}] của Sơn Tặc!");
                    selectionResolved = true;
                });

                // The weapon effect is part of the current Slash resolution.
                // Keep the action locked until the player has picked a card.
                while (modalOpened && !selectionResolved && !gameFinished)
                    yield return null;
            }
            else
            {
                if (TryRemoveBossTargetOption(false, out var destroyedOption))
                {
                    deckManager.DiscardCard(destroyedOption.Card);
                    ShowCardAtCenter(destroyedOption.Card, playerCard, null, $"Lá [{destroyedOption.Card.cardName}] bị phá hủy");
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🔱 [Thương Ngâu Lãng Bạc]: Sơn Tặc đâm thương phá hủy [{destroyedOption.Card.cardName}] của bạn!");
                }
            }
        }
    }

    private IEnumerator ResolveWeaponAfterDodge(GeneralCardUI attacker, GeneralCardUI defender)
    {
        if (attacker == null || defender == null) yield break;

        if (attacker.HasEquipment(EquipmentType.Weapon, "Song Cung"))
        {
            if (attacker == playerCard && playerHandUI.Cards.Count >= 2)
            {
                yield return PromptPlayerSongCungTrigger(defender);
            }
            else if (attacker == bossCard && bossHandCards.Count >= 2)
            {
                yield return ResolveBossSongCungTrigger(defender);
            }

            yield break;
        }

        if (!attacker.HasEquipment(EquipmentType.Weapon, "Trường Đao"))
            yield break;

        if (attacker == playerCard)
        {
            bool hasExtraSlash = false;
            foreach (var card in playerHandUI.Cards)
            {
                if (card != null && IsSlashCard(card.Data))
                {
                    hasExtraSlash = true;
                    break;
                }
            }

            if (hasExtraSlash)
                yield return PromptPlayerTruongDaoTrigger(defender);
        }
        else if (attacker == bossCard)
        {
            yield return ResolveBossTruongDaoTrigger(defender);
        }
    }

    private IEnumerator ResolveBossSongCungTrigger(GeneralCardUI target)
    {
        yield return new WaitForSeconds(0.25f);
        if (target == null || bossHandCards.Count < 2) yield break;

        for (int i = 0; i < 2; i++)
        {
            var discarded = BossPopHandCard();
            if (discarded != null) deckManager.DiscardCard(discarded);
        }

        target.TakeDamage(1);
        AudioManager.Instance.PlayDamage();
        SetLog($"🏹 Sơn Tặc kích hoạt [Song Cung Mường Nhạ]: Bỏ 2 lá, ép {target.GeneralName} mất 1 máu!");
        if (target == bossCard) CheckBossDefeat();
        else if (target == playerCard) yield return ResolvePlayerNearDeath();
    }

    private IEnumerator ResolveBossTruongDaoTrigger(GeneralCardUI target)
    {
        yield return new WaitForSeconds(0.25f);
        var extraSlash = BossPopHandCard(c => IsSlashCard(c));
        if (extraSlash == null) yield break;

        deckManager.DiscardCard(extraSlash);
        ShowCardAtCenter(extraSlash, bossCard, target);
        AudioManager.Instance.PlaySlash();
        SetLog("⚔️ Sơn Tặc kích hoạt [Trường Đao Nam Sơn], ra thêm 1 lá Trảm ép đối phương phải Đỡ lần nữa!");

        // The extra card is a fresh Trảm; the previous Hủ Rượu bonus is not
        // carried over to this follow-up attack.
        yield return ResolveSlashDefense(extraSlash, bossCard, target, 1, string.Empty, false);
    }

    private IEnumerator PromptPlayerSongCungTrigger(GeneralCardUI target)
    {
        bool decided = false;
        bool targetNeedsRescue = false;
        var panelGo = new GameObject("SongCungPanel", typeof(RectTransform));
        panelGo.transform.SetParent(transform, false);
        var rRt = panelGo.GetComponent<RectTransform>();
        rRt.anchorMin = rRt.anchorMax = rRt.pivot = new Vector2(0.5f, 0f);
        rRt.sizeDelta = new Vector2(680f, 48f);
        rRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;

        // Nút kích hoạt
        var triggerBtnGo = new GameObject("Btn_Trigger", typeof(RectTransform), typeof(Image), typeof(Button));
        triggerBtnGo.transform.SetParent(panelGo.transform, false);
        triggerBtnGo.GetComponent<Image>().color = new Color(0.85f, 0.45f, 0.12f, 1f);
        var tRt = triggerBtnGo.GetComponent<RectTransform>();
        tRt.anchorMin = tRt.anchorMax = tRt.pivot = new Vector2(0.5f, 0.5f);
        tRt.sizeDelta = new Vector2(300f, 42f);
        tRt.anchoredPosition = new Vector2(-120f, 0);

        var tTxt = new GameObject("Text", typeof(RectTransform), typeof(Text)).GetComponent<Text>();
        tTxt.transform.SetParent(triggerBtnGo.transform, false);
        tTxt.font = font;
        tTxt.fontSize = 12;
        tTxt.fontStyle = FontStyle.Bold;
        tTxt.text = "🏹 BỎ 2 LÁ (SONG CUNG GÂY 1 MÁU)";
        tTxt.color = Color.white;
        tTxt.alignment = TextAnchor.MiddleCenter;
        Fill(tTxt.rectTransform);

        // Nút bỏ qua
        var passBtnGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passBtnGo.transform.SetParent(panelGo.transform, false);
        passBtnGo.GetComponent<Image>().color = new Color(0.45f, 0.45f, 0.5f, 1f);
        var pRt = passBtnGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = new Vector2(160f, 42f);
        pRt.anchoredPosition = new Vector2(140f, 0);

        var pTxt = new GameObject("Text", typeof(RectTransform), typeof(Text)).GetComponent<Text>();
        pTxt.transform.SetParent(passBtnGo.transform, false);
        pTxt.font = font;
        pTxt.fontSize = 12;
        pTxt.fontStyle = FontStyle.Bold;
        pTxt.text = "BỎ QUA";
        pTxt.color = Color.white;
        pTxt.alignment = TextAnchor.MiddleCenter;
        Fill(pTxt.rectTransform);

        var triggerButton = triggerBtnGo.GetComponent<Button>();
        triggerButton.interactable = false;
        triggerBtnGo.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);

        SetLog("🏹 [Song Cung Mường Nhạ]: Đòn Trảm bị Đỡ! Bạn có thể chọn đúng 2 lá bài trên tay để bỏ, ép Sơn Tặc mất 1 máu xuyên Đỡ.");

        bool previousMultiSelectMode = playerHandUI.IsMultiSelectMode;
        playerHandUI.IsMultiSelectMode = true;
        playerHandUI.MaxSelectableCards = 2;
        playerHandUI.ClearSelection();
        playerHandUI.ResetAllCardsVisuals();
        playerHandUI.HighlightOnlyMatching(_ => true);

        Action<List<CardUI>> onSongCungSelectionChanged = selected =>
        {
            bool hasExactlyTwo = selected != null && selected.Count == 2;
            triggerButton.interactable = hasExactlyTwo;
            triggerBtnGo.GetComponent<Image>().color = hasExactlyTwo
                ? new Color(0.85f, 0.45f, 0.12f, 1f)
                : new Color(0.5f, 0.5f, 0.5f, 0.9f);
            int count = selected != null ? selected.Count : 0;
            tTxt.text = hasExactlyTwo
                ? "🏹 BỎ 2 LÁ ĐÃ CHỌN (GÂY 1 MÁU XUYÊN ĐỠ)"
                : $"🏹 HÃY CHỌN 2 LÁ TRÊN TAY ({count}/2)";
        };
        playerHandUI.OnSelectionChanged += onSongCungSelectionChanged;

        triggerButton.onClick.AddListener(() =>
        {
            var selected = new List<CardUI>(playerHandUI.SelectedCards);
            if (selected.Count == 2)
            {
                foreach (var selectedCard in selected)
                {
                    if (selectedCard == null) continue;
                    var data = selectedCard.Data;
                    playerHandUI.RemoveCard(selectedCard);
                    if (data != null) deckManager.DiscardCard(data);
                }
                AudioManager.Instance.PlayCardSelect();
                target.TakeDamage(1);
                AudioManager.Instance.PlayDamage();
                SetLog($"🏹 Bạn kích hoạt [Song Cung Mường Nhạ]: Bỏ 2 lá bài trên tay, ép {target.GeneralName} mất 1 máu xuyên Đỡ!");
                if (target == bossCard)
                    CheckBossDefeat();
                else if (target == playerCard)
                    targetNeedsRescue = true;
            }
            decided = true;
        });

        passBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            decided = true;
        });

        while (!decided)
        {
            yield return null;
        }

        playerHandUI.OnSelectionChanged -= onSongCungSelectionChanged;
        playerHandUI.ClearSelection();
        playerHandUI.IsMultiSelectMode = previousMultiSelectMode;
        playerHandUI.ResetAllCardsVisuals();
        if (panelGo != null) Destroy(panelGo);
        if (targetNeedsRescue)
            yield return ResolvePlayerNearDeath();
    }

    private IEnumerator PromptPlayerTruongDaoTrigger(GeneralCardUI target)
    {
        bool decided = false;
        CardModel triggeredSlash = null;
        CardUI chosenSlash = null;

        var panelGo = new GameObject("TruongDaoPanel", typeof(RectTransform));
        panelGo.transform.SetParent(transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0f);
        panelRt.sizeDelta = new Vector2(680f, 48f);
        panelRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;

        var triggerGo = new GameObject("Btn_Trigger", typeof(RectTransform), typeof(Image), typeof(Button));
        triggerGo.transform.SetParent(panelGo.transform, false);
        triggerGo.GetComponent<Image>().color = new Color(0.85f, 0.45f, 0.12f, 1f);
        var triggerRt = triggerGo.GetComponent<RectTransform>();
        triggerRt.anchorMin = triggerRt.anchorMax = triggerRt.pivot = new Vector2(0.5f, 0.5f);
        triggerRt.sizeDelta = new Vector2(360f, 42f);
        triggerRt.anchoredPosition = new Vector2(-90f, 0f);

        var triggerTextGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        triggerTextGo.transform.SetParent(triggerGo.transform, false);
        var triggerText = triggerTextGo.GetComponent<Text>();
        triggerText.font = font;
        triggerText.fontSize = 12;
        triggerText.fontStyle = FontStyle.Bold;
        triggerText.text = "⚔️ BỎ 1 TRẢM ÉP ĐỠ LẦN NỮA";
        triggerText.color = Color.white;
        triggerText.alignment = TextAnchor.MiddleCenter;
        Fill(triggerText.rectTransform);

        var passGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passGo.transform.SetParent(panelGo.transform, false);
        passGo.GetComponent<Image>().color = new Color(0.45f, 0.45f, 0.5f, 1f);
        var passRt = passGo.GetComponent<RectTransform>();
        passRt.anchorMin = passRt.anchorMax = passRt.pivot = new Vector2(0.5f, 0.5f);
        passRt.sizeDelta = new Vector2(160f, 42f);
        passRt.anchoredPosition = new Vector2(180f, 0f);

        var passTextGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        passTextGo.transform.SetParent(passGo.transform, false);
        var passText = passTextGo.GetComponent<Text>();
        passText.font = font;
        passText.fontSize = 12;
        passText.fontStyle = FontStyle.Bold;
        passText.text = "BỎ QUA";
        passText.color = Color.white;
        passText.alignment = TextAnchor.MiddleCenter;
        Fill(passText.rectTransform);

        var triggerButton = triggerGo.GetComponent<Button>();
        triggerButton.interactable = false;
        triggerGo.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);

        Action<CardUI> onCardSelected = cardUI =>
        {
            if (cardUI != null && IsSlashCard(cardUI.Data))
            {
                chosenSlash = cardUI;
                triggerButton.interactable = true;
                triggerGo.GetComponent<Image>().color = new Color(0.85f, 0.45f, 0.12f, 1f);
                SetLog($"⚔️ Đã chọn lá [{cardUI.Data.cardName}] cho [Trường Đao]. Nhấn nút để ép Đỡ lần nữa.");
            }
            else
            {
                chosenSlash = null;
                triggerButton.interactable = false;
                triggerGo.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
            }
        };

        playerHandUI.OnCardSelected += onCardSelected;
        if (playerHandUI.SelectedCard != null && IsSlashCard(playerHandUI.SelectedCard.Data))
            onCardSelected(playerHandUI.SelectedCard);

        triggerButton.onClick.AddListener(() =>
        {
            if (chosenSlash == null) return;
            var extraSlash = chosenSlash.Data;
            playerHandUI.RemoveCard(chosenSlash);
            deckManager.DiscardCard(extraSlash);
            triggeredSlash = extraSlash;
            decided = true;
        });

        passGo.GetComponent<Button>().onClick.AddListener(() => decided = true);

        SetLog("⚔️ [Trường Đao Nam Sơn]: Trảm vừa bị Đỡ. Bạn có thể bỏ thêm 1 lá Trảm để ép đối phương Đỡ lần nữa.");
        while (!decided)
            yield return null;

        playerHandUI.OnCardSelected -= onCardSelected;
        if (panelGo != null) Destroy(panelGo);

        if (triggeredSlash != null)
        {
            // The second attack cannot chain Trường Đao again.
            ShowCardAtCenter(triggeredSlash, playerCard, target);
            yield return ResolveSlashDefense(triggeredSlash, playerCard, target, 1, string.Empty, false);
        }
    }

    private IEnumerator AwaitForPlayerSlashDefense(
        CardModel slashCard,
        int damage,
        Action<SlashDefenseResult> onResolved)
    {
        // 1. Kiểm tra Giáp Đồng Sơn Vi của người chơi
        if (playerCard.HasEquipment(EquipmentType.Armor, "Giáp Đồng") && slashCard.subType == CardSubType.AttackNormal)
        {
            AudioManager.Instance.PlayParry();
            SetLog($"🛡️ <color=#70D8FF><b>[GIÁP ĐỒNG SƠN VI]</b></color>: Giáp Đồng bảo hộ bạn, vô hiệu hóa hoàn toàn đòn [{slashCard.cardName}] không thuộc tính!");
            onResolved?.Invoke(SlashDefenseResult.Negated);
            yield break;
        }

        bool defenseResolved = false;
        var result = SlashDefenseResult.Hit;

        SetLog("⚠️ <color=#FF5555><b>SƠN TẶC TUNG ĐÒN TRẢM VÀO BẠN!</b></color> Hãy chạm chọn lá [ĐỠ] trên tay để hóa giải hoặc bấm [KHÔNG NÉ].");

        var reactionGo = new GameObject("SlashReactionPanel", typeof(RectTransform));
        reactionGo.transform.SetParent(transform, false);
        var rRt = reactionGo.GetComponent<RectTransform>();
        rRt.anchorMin = new Vector2(0.5f, 0f);
        rRt.anchorMax = new Vector2(0.5f, 0f);
        rRt.pivot = new Vector2(0.5f, 0f);
        rRt.sizeDelta = new Vector2(680f, 48f);
        rRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;

        // Nút Né Đòn
        var dodgeBtnGo = new GameObject("Btn_Dodge", typeof(RectTransform), typeof(Image), typeof(Button));
        dodgeBtnGo.transform.SetParent(reactionGo.transform, false);
        var dImg = dodgeBtnGo.GetComponent<Image>();
        var dRt = dodgeBtnGo.GetComponent<RectTransform>();
        dRt.anchorMin = dRt.anchorMax = dRt.pivot = new Vector2(0.5f, 0.5f);
        dRt.sizeDelta = new Vector2(260f, 42f);
        dRt.anchoredPosition = new Vector2(-100f, 0);

        var dTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        dTxtGo.transform.SetParent(dodgeBtnGo.transform, false);
        var dTxt = dTxtGo.GetComponent<Text>();
        dTxt.font = font;
        dTxt.fontSize = 13;
        dTxt.fontStyle = FontStyle.Bold;
        dTxt.text = "🛡️ ĐÁNH [ĐỠ] ĐỂ HÓA GIẢI";
        dTxt.color = Color.white;
        dTxt.alignment = TextAnchor.MiddleCenter;
        Fill(dTxtGo.GetComponent<RectTransform>());

        var dBtn = dodgeBtnGo.GetComponent<Button>();
        dBtn.interactable = false;
        dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);

        // Nút Không Né
        var noDodgeBtnGo = new GameObject("Btn_NoDodge", typeof(RectTransform), typeof(Image), typeof(Button));
        noDodgeBtnGo.transform.SetParent(reactionGo.transform, false);
        var ndImg = noDodgeBtnGo.GetComponent<Image>();
        ndImg.color = new Color(0.85f, 0.25f, 0.2f, 1f);
        var ndRt = noDodgeBtnGo.GetComponent<RectTransform>();
        ndRt.anchorMin = ndRt.anchorMax = ndRt.pivot = new Vector2(0.5f, 0.5f);
        ndRt.sizeDelta = new Vector2(210f, 42f);
        ndRt.anchoredPosition = new Vector2(170f, 0);

        var ndTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        ndTxtGo.transform.SetParent(noDodgeBtnGo.transform, false);
        var ndTxt = ndTxtGo.GetComponent<Text>();
        ndTxt.font = font;
        ndTxt.fontSize = 13;
        ndTxt.fontStyle = FontStyle.Bold;
        ndTxt.text = "❌ KHÔNG NÉ (CHỊU MÁU)";
        ndTxt.color = Color.white;
        ndTxt.alignment = TextAnchor.MiddleCenter;
        Fill(ndTxtGo.GetComponent<RectTransform>());

        CardUI chosenDodgeUI = null;

        bool bossHasCannon = bossCard.HasEquipment(EquipmentType.Weapon, "Súng Thần Công");

        Action<CardUI> onCardSelectedDuringReaction = (cardUI) =>
        {
            if (cardUI != null && CanActAsDodge(playerCard, cardUI.Data))
            {
                // Kiểm tra nếu Boss có Súng Thần Công Hồ Triều: Cấm tuyệt đối Đỡ cùng chất với Trảm
                if (bossHasCannon && cardUI.Data.suit == slashCard.suit)
                {
                    chosenDodgeUI = null;
                    dBtn.interactable = false;
                    dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
                    playerHandUI.DeselectCard(cardUI);
                    AudioManager.Instance.PlayError();
                    SetLog($"🚫 <color=#FF5555><b>[SÚNG THẦN CÔNG HỒ TRIỀU]</b></color>: CẤM dùng lá Đỡ chất [{cardUI.Data.GetSuitSymbol()}] cùng chất với đòn Trảm! Đã tự động thu bài lại.");
                    return;
                }

                chosenDodgeUI = cardUI;
                dBtn.interactable = true;
                dImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                SetLog($"🛡️ Đã chọn lá [{cardUI.Data.cardName}]. Nhấn nút [ĐÁNH ĐỠ ĐỂ HÓA GIẢI]!");
            }
            else
            {
                chosenDodgeUI = null;
                dBtn.interactable = false;
                dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
            }
        };

        slashDefenseActive = true;
        onCurrentReactionCardSelected = onCardSelectedDuringReaction;
        playerHandUI.HighlightOnlyMatching(c => c != null && CanActAsDodge(playerCard, c) && (!bossHasCannon || c.suit != slashCard.suit));

        playerHandUI.OnCardSelected += onCardSelectedDuringReaction;

        if (playerHandUI.SelectedCard != null && IsDodgeCard(playerHandUI.SelectedCard.Data))
        {
            onCardSelectedDuringReaction(playerHandUI.SelectedCard);
        }

        dBtn.onClick.AddListener(() =>
        {
            if (chosenDodgeUI != null)
            {
                var pos = RectTransformUtility.WorldToScreenPoint(null, chosenDodgeUI.transform.position);
                var dodgeData = chosenDodgeUI.Data;
                playerHandUI.RemoveCard(chosenDodgeUI);
                deckManager.DiscardCard(dodgeData);
                ShowCardAtCenter(dodgeData, playerCard);
                StartCoroutine(AnimateDodgeParry(dodgeData, pos, null));
                SetLog("🛡️ Bạn đã tự tay đánh ra lá [ĐỠ] hóa giải hoàn toàn đòn Trảm của Sơn Tặc!");
                result = SlashDefenseResult.Dodged;
                defenseResolved = true;
            }
        });

        noDodgeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            result = SlashDefenseResult.Hit;
            defenseResolved = true;
        });

        while (!defenseResolved)
        {
            yield return null;
        }

        playerHandUI.OnCardSelected -= onCardSelectedDuringReaction;
        slashDefenseActive = false;
        onCurrentReactionCardSelected = null;
        playerHandUI.ResetAllCardsVisuals();
        if (reactionGo != null) Destroy(reactionGo);
        onResolved?.Invoke(result);
    }

    /// <summary>
    /// Resolves Thách Đấu. The challenged player answers first, then both
    /// sides alternate Trảm cards until one side cannot continue.
    /// Duel cards are not normal attacks: no range, Dodge, armor, or weapon
    /// triggers are evaluated for the exchanged Trảm cards.
    /// </summary>
    private IEnumerator ResolveDuel(GeneralCardUI initiator, GeneralCardUI challenged)
    {
        if (initiator == null || challenged == null) yield break;

        var responder = challenged;
        SetLog($"⚔️ [Thách Đấu]: {challenged.GeneralName} phải ra Trảm trước, sau đó hai bên luân phiên!");

        while (responder != null && responder.CurrentHp > 0)
        {
            CardModel slash = null;
            if (responder == playerCard)
            {
                yield return AwaitForPlayerDuelSlash(card => slash = card);
            }
            else if (responder == bossCard)
            {
                yield return new WaitForSeconds(0.35f);
                slash = BossPopHandCard(c => IsSlashCard(c));
            }

            if (slash == null)
            {
                responder.TakeDamage(1);
                AudioManager.Instance.PlayDamage();
                SetLog($"⚔️ [Thách Đấu]: {responder.GeneralName} không ra được Trảm tiếp theo, chịu 1 sát thương!");
                if (responder == bossCard)
                    CheckBossDefeat();
                else if (responder == playerCard)
                    yield return ResolvePlayerNearDeath();
                yield break;
            }

            deckManager.DiscardCard(slash);
            ShowCardAtCenter(slash, responder);
            AudioManager.Instance.PlaySlash();
            SetLog($"⚔️ [Thách Đấu]: {responder.GeneralName} ra [{slash.cardName}]! Đến lượt đối thủ đáp trả.");

            responder = responder == playerCard ? bossCard : playerCard;
            yield return new WaitForSeconds(0.35f);
        }
    }

    private IEnumerator AwaitForPlayerDuelSlash(Action<CardModel> onResolved)
    {
        duelResponseActive = true;
        bool decided = false;
        CardUI chosenSlash = null;

        // Highlight các lá Trảm trên tay
        playerHandUI.HighlightOnlyMatching(IsSlashCard);

        bool hasSlash = false;
        foreach (var c in playerHandUI.Cards)
        {
            if (c != null && IsSlashCard(c.Data))
            {
                hasSlash = true;
                break;
            }
        }

        var panelGo = new GameObject("DuelReactionPanel", typeof(RectTransform));
        panelGo.transform.SetParent(transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0f);
        panelRt.sizeDelta = new Vector2(680f, 48f);
        panelRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;
        var slashGo = new GameObject("Btn_Slash", typeof(RectTransform), typeof(Image), typeof(Button));
        slashGo.transform.SetParent(panelGo.transform, false);
        slashGo.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
        var slashRt = slashGo.GetComponent<RectTransform>();
        slashRt.anchorMin = slashRt.anchorMax = slashRt.pivot = new Vector2(0.5f, 0.5f);
        slashRt.sizeDelta = new Vector2(340f, 42f);
        slashRt.anchoredPosition = new Vector2(-100f, 0f);

        var slashTextGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        slashTextGo.transform.SetParent(slashGo.transform, false);
        var slashText = slashTextGo.GetComponent<Text>();
        slashText.font = font;
        slashText.fontSize = 12;
        slashText.fontStyle = FontStyle.Bold;
        slashText.text = "⚔️ RA TRẢM ĐÁNH TRẢ";
        slashText.color = Color.white;
        slashText.alignment = TextAnchor.MiddleCenter;
        Fill(slashText.rectTransform);

        var passGo = new GameObject("Btn_Concede", typeof(RectTransform), typeof(Image), typeof(Button));
        passGo.transform.SetParent(panelGo.transform, false);
        passGo.GetComponent<Image>().color = new Color(0.6f, 0.25f, 0.25f, 1f);
        var passRt = passGo.GetComponent<RectTransform>();
        passRt.anchorMin = passRt.anchorMax = passRt.pivot = new Vector2(0.5f, 0.5f);
        passRt.sizeDelta = new Vector2(210f, 42f);
        passRt.anchoredPosition = new Vector2(190f, 0f);

        var passTextGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        passTextGo.transform.SetParent(passGo.transform, false);
        var passText = passTextGo.GetComponent<Text>();
        passText.font = font;
        passText.fontSize = 12;
        passText.fontStyle = FontStyle.Bold;
        passText.text = hasSlash ? "⛔ KHÔNG RA TRẢM (CHỊU ĐÒN)" : "⛔ KHÔNG CÓ TRẢM (CHỊU ĐÒN)";
        passText.color = Color.white;
        passText.alignment = TextAnchor.MiddleCenter;
        Fill(passText.rectTransform);

        var slashButton = slashGo.GetComponent<Button>();
        slashButton.interactable = false;

        Action<CardUI> onCardSelected = cardUI =>
        {
            if (cardUI != null && IsSlashCard(cardUI.Data))
            {
                chosenSlash = cardUI;
                slashButton.interactable = true;
                slashGo.GetComponent<Image>().color = new Color(0.85f, 0.45f, 0.12f, 1f);
                slashText.text = $"⚔️ DÙNG [{cardUI.Data.cardName.ToUpper()}] ĐÁNH TRẢ";
                SetLog($"⚔️ Đã chọn [{cardUI.Data.cardName}] để đáp trả Thách Đấu. Hãy nhấn nút để xuất chiêu!");
            }
            else
            {
                chosenSlash = null;
                slashButton.interactable = false;
                slashGo.GetComponent<Image>().color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
                slashText.text = "⚔️ RA TRẢM ĐÁNH TRẢ";
            }
        };

        onCurrentReactionCardSelected = onCardSelected;
        playerHandUI.OnCardSelected += onCardSelected;
        if (playerHandUI.SelectedCard != null)
            onCardSelected(playerHandUI.SelectedCard);

        slashButton.onClick.AddListener(() =>
        {
            if (chosenSlash == null) return;
            var result = chosenSlash.Data;
            playerHandUI.RemoveCard(chosenSlash);
            decided = true;
            onResolved?.Invoke(result);
        });
        passGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            decided = true;
            onResolved?.Invoke(null);
        });

        SetLog(hasSlash
            ? "⚔️ [Thách Đấu]: Đến lượt bạn! Hãy chọn 1 lá Trảm trên tay để đánh trả hoặc nhấn KHÔNG RA TRẢM để nhận 1 sát thương."
            : "⚔️ [Thách Đấu]: Bạn không có lá Trảm nào trên tay để đánh trả! Hãy nhấn nút để nhận 1 sát thương.");

        while (!decided && !gameFinished)
            yield return null;

        playerHandUI.OnCardSelected -= onCardSelected;
        onCurrentReactionCardSelected = null;
        playerHandUI.ResetAllCardsVisuals();
        duelResponseActive = false;
        if (panelGo != null) Destroy(panelGo);
    }

    private List<GeneralCardUI> GetOtherGenerals(GeneralCardUI caster)
    {
        var list = new List<GeneralCardUI>();
        // Theo thứ tự lượt chơi trên bàn (loại trừ người sử dụng)
        if (caster == playerCard)
        {
            if (bossCard != null && bossCard.CurrentHp > 0) list.Add(bossCard);
        }
        else
        {
            if (playerCard != null && playerCard.CurrentHp > 0) list.Add(playerCard);
        }
        return list;
    }

    private List<GeneralCardUI> GetLivingPlayersInTurnOrder(GeneralCardUI caster)
    {
        var list = new List<GeneralCardUI>();
        if (caster == null) return list;

        // Bắt đầu từ người sử dụng Cẩm Nang
        if (caster.CurrentHp > 0) list.Add(caster);

        var others = GetOtherGenerals(caster);
        foreach (var p in others)
        {
            if (p != null && p.CurrentHp > 0 && !list.Contains(p))
            {
                list.Add(p);
            }
        }
        return list;
    }

    private IEnumerator ResolveHarvest(CardModel harvestCard, GeneralCardUI caster)
    {
        if (gameFinished || harvestCard == null || caster == null || caster.CurrentHp <= 0)
            yield break;

        // 1. Lấy danh sách người chơi còn sống trên bàn đấu theo thứ tự lượt bắt đầu từ người dùng
        var turnOrder = GetLivingPlayersInTurnOrder(caster);
        int totalPlayers = turnOrder.Count;
        if (totalPlayers == 0) yield break;

        // 2. Rút N lá bài từ bộ bài tương ứng với số người còn sống
        var revealedCards = deckManager.DrawCards(totalPlayers);
        if (revealedCards == null || revealedCards.Count == 0) yield break;

        SetLog($"🍚 [{caster.GeneralName}] mở kho cứu tế! Lật {revealedCards.Count} lá bài công khai cho cả bàn đấu cùng xem.");

        // 3. Khởi tạo Modal Mở Kho Cứu Tế
        var font = ThemeUI.FontMain;
        var modalGo = new GameObject("HarvestModal", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        modalGo.transform.SetParent(transform, false);
        modalGo.transform.SetAsLastSibling();

        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(modalGo.GetComponent<RectTransform>());

        // Panel Container (Width 740, Height 400)
        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(740f, 400f);
        panelRt.anchoredPosition = Vector2.zero;

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.06f, 0.14f, 0.12f, 0.98f); // Nền xanh ngọc bích kho cứu tế

        // Viền hào quang vàng phát sáng
        var outerBorderGo = new GameObject("OuterBorder", typeof(RectTransform), typeof(Image));
        outerBorderGo.transform.SetParent(panelGo.transform, false);
        outerBorderGo.transform.SetAsFirstSibling();
        var obImg = outerBorderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { obImg.sprite = frameSpr; obImg.type = Image.Type.Sliced; }
        obImg.color = new Color(0.35f, 0.9f, 0.45f, 0.98f);
        obImg.raycastTarget = false;
        Fill(outerBorderGo.GetComponent<RectTransform>(), new Vector2(-5, -5), new Vector2(5, 5));

        // Header Banner Tiêu Đề
        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSpr != null) { hImg.sprite = badgeSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.15f, 0.58f, 0.32f, 0.98f); // Xanh lục cứu tế

        var hRt = headerGo.GetComponent<RectTransform>();
        hRt.anchorMin = new Vector2(0.5f, 1f);
        hRt.anchorMax = new Vector2(0.5f, 1f);
        hRt.pivot = new Vector2(0.5f, 1f);
        hRt.sizeDelta = new Vector2(680f, 48f);
        hRt.anchoredPosition = new Vector2(0, -12f);

        var titleGo = new GameObject("TitleText", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(headerGo.transform, false);
        var tText = titleGo.GetComponent<Text>();
        tText.font = font;
        tText.fontSize = 18;
        tText.fontStyle = FontStyle.Bold;
        tText.alignment = TextAnchor.MiddleCenter;
        tText.color = new Color(1f, 0.95f, 0.6f, 1f);
        tText.text = $"🍚 MỞ KHO CỨU TẾ - LẬT {revealedCards.Count} LÁ BÀI CÔNG KHAI";
        AddTextShadow(tText);
        Fill(titleGo.GetComponent<RectTransform>());

        // Subtitle dòng trạng thái
        var subTitleGo = new GameObject("SubTitle", typeof(RectTransform), typeof(Text));
        subTitleGo.transform.SetParent(panelGo.transform, false);
        var subRt = subTitleGo.GetComponent<RectTransform>();
        subRt.anchorMin = new Vector2(0.5f, 1f);
        subRt.anchorMax = new Vector2(0.5f, 1f);
        subRt.pivot = new Vector2(0.5f, 1f);
        subRt.sizeDelta = new Vector2(680f, 26f);
        subRt.anchoredPosition = new Vector2(0, -66f);
        var subTxt = subTitleGo.GetComponent<Text>();
        subTxt.font = font;
        subTxt.fontSize = 13;
        subTxt.fontStyle = FontStyle.Bold;
        subTxt.alignment = TextAnchor.MiddleCenter;
        subTxt.color = new Color(0.9f, 1f, 0.92f, 1f);

        // Container các lá bài công khai
        var cardsContainerGo = new GameObject("CardsContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        cardsContainerGo.transform.SetParent(panelGo.transform, false);
        var cRt = cardsContainerGo.GetComponent<RectTransform>();
        cRt.anchorMin = new Vector2(0.5f, 0.5f);
        cRt.anchorMax = new Vector2(0.5f, 0.5f);
        cRt.pivot = new Vector2(0.5f, 0.5f);
        cRt.sizeDelta = new Vector2(700f, 220f);
        cRt.anchoredPosition = new Vector2(0, -22f);
        var hlg = cardsContainerGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 16f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = false;
        hlg.childControlHeight = false;

        // Render toàn bộ các lá bài được lật ngửa mặt công khai cho cả bàn xem
        var cardUiMap = new Dictionary<CardModel, GameObject>();

        foreach (var cData in revealedCards)
        {
            var cardUI = CardUI.Create(cardsContainerGo.transform, cData, new Vector2(118f, 162f));
            cardUiMap[cData] = cardUI.gameObject;
        }

        // 4. Luân phiên từng người chọn bài theo thứ tự (bắt đầu từ người sử dụng lá Cẩm nang)
        foreach (var picker in turnOrder)
        {
            if (gameFinished) break;
            if (picker == null || picker.CurrentHp <= 0) continue;
            if (revealedCards.Count == 0) break;

            if (picker == playerCard)
            {
                // Lượt người chơi chọn
                subTxt.text = $"👉 <color=#FFD700><b>LƯỢT CỦA BẠN:</b></color> Chạm chọn 1 lá bài công khai dưới đây vào tay!";
                SetLog("👉 [Mở Kho Cứu Tế]: Đang tới lượt bạn chọn 1 lá bài...");

                CardModel playerPicked = null;

                // Gán sự kiện click chọn cho từng lá bài còn lại
                foreach (var kvp in cardUiMap)
                {
                    var cData = kvp.Key;
                    var cGo = kvp.Value;
                    if (cGo == null) continue;

                    var btn = cGo.GetComponent<Button>();
                    if (btn == null) btn = cGo.AddComponent<Button>();
                    btn.onClick.RemoveAllListeners();
                    btn.onClick.AddListener(() =>
                    {
                        playerPicked = cData;
                    });
                }

                // Chờ người chơi bấm chọn bài
                while (playerPicked == null && !gameFinished)
                {
                    yield return null;
                }

                if (gameFinished) break;

                // Nhận bài vào tay người chơi
                playerHandUI.AddCard(playerPicked);
                AudioManager.Instance.PlayCardDraw();
                SetLog($"🍚 Bạn đã chọn lá [{playerPicked.cardName}] từ Kho Cứu Tế!");

                // Xóa lá đã chọn khỏi modal
                revealedCards.Remove(playerPicked);
                if (cardUiMap.TryGetValue(playerPicked, out var pickedGo) && pickedGo != null)
                {
                    Destroy(pickedGo);
                    cardUiMap.Remove(playerPicked);
                }
            }
            else
            {
                // Lượt Boss (AI) chọn bài
                subTxt.text = $"⏳ <color=#FFA0A0><b>LƯỢT CỦA {picker.GeneralName.ToUpper()}:</b></color> Đang suy nghĩ chọn bài...";
                SetLog($"⏳ [Mở Kho Cứu Tế]: {picker.GeneralName} đang chọn bài...");

                yield return new WaitForSeconds(0.8f); // Delay suy nghĩ mượt mà

                if (gameFinished) break;

                // Boss chọn lá bài ưu tiên (Peach/Wine nếu mất máu, hoặc lá đầu tiên)
                CardModel bossPicked = revealedCards.Find(c => c.subType == CardSubType.Peach || c.subType == CardSubType.Wine);
                if (bossPicked == null) bossPicked = revealedCards[0];

                // Keep the revealed CardModel in the actual hand, not only in the HUD count.
                if (picker == bossCard)
                    BossAddHandCard(bossPicked);
                else if (picker == playerCard)
                    playerHandUI.AddCard(bossPicked);
                else
                    picker.SetHandCardCount(picker.HandCardCount + 1);
                AudioManager.Instance.PlayCardDraw();
                SetLog($"🍚 {picker.GeneralName} đã chọn lá [{bossPicked.cardName}] từ Kho Cứu Tế!");

                // Xóa lá đã chọn khỏi modal
                revealedCards.Remove(bossPicked);
                if (cardUiMap.TryGetValue(bossPicked, out var pickedGo) && pickedGo != null)
                {
                    Destroy(pickedGo);
                    cardUiMap.Remove(bossPicked);
                }
            }

            yield return new WaitForSeconds(0.4f);
        }

        // Return any revealed cards that no living picker could claim to the
        // discard pile instead of silently deleting them from the deck.
        if (revealedCards.Count > 0)
            deckManager.DiscardCards(revealedCards);

        yield return new WaitForSeconds(0.4f);
        Destroy(modalGo);
        SetLog("✅ <color=#55FF55><b>HOÀN TẤT MỞ KHO CỨU TẾ!</b></color> Tất cả các lá bài đã được chia đều.");
    }

    private IEnumerator ResolveRattanShieldAgainstScroll(
        CardModel scrollCard,
        GeneralCardUI target,
        Action<bool> onNegated)
    {
        bool negated = false;
        if (target != null && target.HasEquipment(EquipmentType.Armor, "Khiên Mây") &&
            scrollCard != null &&
            (scrollCard.subType == CardSubType.BarbarianInvasion || scrollCard.subType == CardSubType.ArrowRain))
        {
            yield return TryKhienMayDefenseTutorial(target, scrollCard.cardName, (success) =>
            {
                negated = success;
            });
        }

        onNegated?.Invoke(negated);
    }

    private IEnumerator TryKhienMayDefenseTutorial(GeneralCardUI defender, string attackName, Action<bool> callback)
    {
        if (defender == null || !defender.HasEquipment(EquipmentType.Armor, "Khiên Mây"))
        {
            callback?.Invoke(false);
            yield break;
        }

        yield return new WaitForSeconds(0.3f);

        // 1. Phát âm thanh tuyệt kỹ và đọc voice "Khiên Mây Bện"
        AudioManager.Instance.PlaySkill();
        AudioManager.Instance.PlayCardVoice("Khiên Mây Bện");

        SetLog($"🛡️ <b>{defender.GeneralName}</b> kích hoạt <color=#55DDFF><b>[KHIÊN MÂY BỆN]</b></color>: Đang lật bài phán xét né {attackName}...");

        yield return AnimateDealtCard(defender == playerCard);
        var judgeCard = deckManager.DrawCard();
        if (judgeCard == null)
        {
            callback?.Invoke(false);
            yield break;
        }

        bool isRed = (judgeCard.suit == CardSuit.Heart || judgeCard.suit == CardSuit.Diamond);
        string suitSym = judgeCard.GetSuitSymbol();
        string rankStr = judgeCard.GetRankString();

        // 2. Tạo hoạt cảnh phán xét trung tâm với TICK ✔ / X ✖
        var judgeCardGo = CardUI.Create(transform, judgeCard, new Vector2(110f, 150f)).gameObject;
        judgeCardGo.transform.SetAsLastSibling();

        var rt = judgeCardGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = new Vector2(0, 30f);
        judgeCardGo.transform.localScale = Vector3.one * 0.6f;

        float el = 0f;
        while (el < 0.22f)
        {
            el += Time.deltaTime;
            judgeCardGo.transform.localScale = Vector3.one * Mathf.Lerp(0.6f, 1.15f, el / 0.22f);
            yield return null;
        }
        judgeCardGo.transform.localScale = Vector3.one * 1.15f;

        // Tiêu đề phía trên
        var titleBoxGo = new GameObject("JudgementTitle", typeof(RectTransform), typeof(Image));
        titleBoxGo.transform.SetParent(judgeCardGo.transform, false);
        var tbImg = titleBoxGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { tbImg.sprite = slotSpr; tbImg.type = Image.Type.Sliced; }
        tbImg.color = new Color(0.04f, 0.07f, 0.14f, 0.95f);
        var tbRt = titleBoxGo.GetComponent<RectTransform>();
        tbRt.anchorMin = new Vector2(0.5f, 1f); tbRt.anchorMax = new Vector2(0.5f, 1f);
        tbRt.pivot = new Vector2(0.5f, 0f);
        tbRt.sizeDelta = new Vector2(240f, 28f);
        tbRt.anchoredPosition = new Vector2(0f, 6f);

        var font = ThemeUI.FontMain;
        var titleTxt = titleBoxGo.AddComponent<Text>();
        titleTxt.font = font;
        titleTxt.fontSize = 11;
        titleTxt.fontStyle = FontStyle.Bold;
        titleTxt.alignment = TextAnchor.MiddleCenter;
        titleTxt.text = "🛡️ PHÁN XÉT KHIÊN MÂY BỆN";
        titleTxt.color = new Color(1f, 0.88f, 0.35f, 1f);
        Fill(titleTxt.rectTransform);

        // Huy hiệu TICK / X ở giữa
        var badgeGo = new GameObject("JudgementBadge", typeof(RectTransform), typeof(Image));
        badgeGo.transform.SetParent(judgeCardGo.transform, false);
        var badgeRt = badgeGo.GetComponent<RectTransform>();
        badgeRt.anchorMin = badgeRt.anchorMax = badgeRt.pivot = new Vector2(0.5f, 0.5f);
        badgeRt.sizeDelta = new Vector2(140f, 140f);
        badgeRt.anchoredPosition = Vector2.zero;

        var bImg = badgeGo.GetComponent<Image>();
        bImg.color = new Color(0.04f, 0.06f, 0.12f, 0.75f);

        var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Text));
        iconGo.transform.SetParent(badgeGo.transform, false);
        var iconTxt = iconGo.GetComponent<Text>();
        iconTxt.font = font;
        iconTxt.fontSize = isRed ? 78 : 72;
        iconTxt.fontStyle = FontStyle.Bold;
        iconTxt.alignment = TextAnchor.MiddleCenter;
        iconTxt.text = isRed ? "<color=#44FF55>✔</color>" : "<color=#FF4444>✖</color>";
        AddTextShadow(iconTxt);
        Fill(iconGo.GetComponent<RectTransform>());

        // Nhãn kết quả bên dưới
        var labelGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        labelGo.transform.SetParent(judgeCardGo.transform, false);
        var lTxt = labelGo.GetComponent<Text>();
        lTxt.font = font;
        lTxt.fontSize = 13;
        lTxt.fontStyle = FontStyle.Bold;
        lTxt.alignment = TextAnchor.MiddleCenter;
        lTxt.text = isRed
            ? $"<color=#44FF55><b>✔ PHÁN XÉT THÀNH CÔNG (CHẤT ĐỎ {suitSym} {rankStr})</b></color>\n<size=11>Đã hóa giải đòn đánh của đối phương!</size>"
            : $"<color=#FF5555><b>✖ PHÁN XÉT THẤT BẠI (CHẤT ĐEN {suitSym} {rankStr})</b></color>\n<size=11>Tiếp tục phòng thủ bằng bài trên tay.</size>";
        AddTextShadow(lTxt);
        var lRt = labelGo.GetComponent<RectTransform>();
        lRt.anchorMin = lRt.anchorMax = new Vector2(0.5f, 0f);
        lRt.pivot = new Vector2(0.5f, 1f);
        lRt.sizeDelta = new Vector2(300f, 44f);
        lRt.anchoredPosition = new Vector2(0, -8f);

        if (isRed)
        {
            AudioManager.Instance.PlayParry();
            SetLog($"🛡️ <color=#55FF55><b>[KHIÊN MÂY BỆN - THÀNH CÔNG ✔]</b></color>: Lá phán xét là chất ĐỎ [{suitSym} {rankStr}]. <b>{defender.GeneralName}</b> hóa giải đòn đánh thành công!");
        }
        else
        {
            AudioManager.Instance.PlayDamage();
            SetLog($"🛡️ <color=#CBD5E1>[Khiên Mây Bện - Thất Bại ✖]</color>: Lá phán xét là chất ĐEN [{suitSym} {rankStr}]. Phán xét thất bại, tiếp tục phòng thủ.");
        }

        yield return new WaitForSeconds(1.4f);

        Destroy(judgeCardGo);
        deckManager.DiscardCard(judgeCard);

        callback?.Invoke(isRed);
    }

    private IEnumerator ResolveGlobalScroll(CardModel scrollCard, GeneralCardUI caster)
    {
        var targets = GetOtherGenerals(caster);
        string scrollName = scrollCard.cardName;

        SetLog($"🌪️ [{scrollName}]: Thi triển lên từng người chơi trên bàn theo thứ tự (không bao gồm {caster.GeneralName})!");

        foreach (var target in targets)
        {
            if (target == null || target.CurrentHp <= 0) continue;

            // Hiển thị lá bài ở giữa và bắn tia vàng nhắm vào mục tiêu hiện tại
            ShowCardAtCenter(scrollCard, caster, target);
            yield return new WaitForSeconds(0.4f);

            bool negatedByShield = false;
            yield return ResolveRattanShieldAgainstScroll(scrollCard, target, result => negatedByShield = result);
            if (negatedByShield)
            {
                yield return new WaitForSeconds(0.35f);
                continue;
            }

            if (scrollCard.subType == CardSubType.BarbarianInvasion)
            {
                // BÃI CỌC NGẦM: Mục tiêu cần ra 1 lá TRẢM
                if (target == playerCard)
                {
                    yield return AwaitForPlayerBarbarianDefense(scrollCard);
                }
                else
                {
                    yield return ResolveBossBarbarianDefense();
                }
            }
            else if (scrollCard.subType == CardSubType.ArrowRain)
            {
                // MƯA TÊN LIÊN CHÂU: Mục tiêu cần ra 1 lá ĐỠ
                if (target == playerCard)
                {
                    yield return AwaitForPlayerArrowRainDefense(scrollCard);
                }
                else
                {
                    yield return ResolveBossArrowRainDefense();
                }
            }

            if (gameFinished) yield break;

            yield return new WaitForSeconds(0.5f);
        }
    }

    private IEnumerator AwaitForPlayerBarbarianDefense(CardModel scrollCard)
    {
        bool defenseResolved = false;

        SetLog("🪵 <color=#FF5555><b>BÃI CỌC NGẦM NHẮM VÀO BẠN!</b></color> Hãy chạm chọn lá [TRẢM] trên tay để phá cọc hoặc bấm [CHỊU ĐÒN].");

        var reactionGo = new GameObject("BarbarianReactionPanel", typeof(RectTransform));
        reactionGo.transform.SetParent(transform, false);
        var rRt = reactionGo.GetComponent<RectTransform>();
        rRt.anchorMin = new Vector2(0.5f, 0f);
        rRt.anchorMax = new Vector2(0.5f, 0f);
        rRt.pivot = new Vector2(0.5f, 0f);
        rRt.sizeDelta = new Vector2(680f, 48f);
        rRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;

        // Nút Đánh Trảm
        var slashBtnGo = new GameObject("Btn_Slash", typeof(RectTransform), typeof(Image), typeof(Button));
        slashBtnGo.transform.SetParent(reactionGo.transform, false);
        var sImg = slashBtnGo.GetComponent<Image>();
        var sRt = slashBtnGo.GetComponent<RectTransform>();
        sRt.anchorMin = sRt.anchorMax = sRt.pivot = new Vector2(0.5f, 0.5f);
        sRt.sizeDelta = new Vector2(260f, 42f);
        sRt.anchoredPosition = new Vector2(-100f, 0);

        var sTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        sTxtGo.transform.SetParent(slashBtnGo.transform, false);
        var sTxt = sTxtGo.GetComponent<Text>();
        sTxt.font = font;
        sTxt.fontSize = 13;
        sTxt.fontStyle = FontStyle.Bold;
        sTxt.text = "⚔️ ĐÁNH [TRẢM] ĐỂ PHÁ CỌC";
        sTxt.color = Color.white;
        sTxt.alignment = TextAnchor.MiddleCenter;
        Fill(sTxtGo.GetComponent<RectTransform>());

        var sBtn = slashBtnGo.GetComponent<Button>();
        sBtn.interactable = false;
        sImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);

        // Nút Chịu Sát Thương
        var dmgBtnGo = new GameObject("Btn_Damage", typeof(RectTransform), typeof(Image), typeof(Button));
        dmgBtnGo.transform.SetParent(reactionGo.transform, false);
        var dImg = dmgBtnGo.GetComponent<Image>();
        dImg.color = new Color(0.85f, 0.25f, 0.2f, 1f);
        var dRt = dmgBtnGo.GetComponent<RectTransform>();
        dRt.anchorMin = dRt.anchorMax = dRt.pivot = new Vector2(0.5f, 0.5f);
        dRt.sizeDelta = new Vector2(210f, 42f);
        dRt.anchoredPosition = new Vector2(170f, 0);

        var dTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        dTxtGo.transform.SetParent(dmgBtnGo.transform, false);
        var dTxt = dTxtGo.GetComponent<Text>();
        dTxt.font = font;
        dTxt.fontSize = 13;
        dTxt.fontStyle = FontStyle.Bold;
        dTxt.text = "❌ CHỊU ĐÒN (MẤT 1 MÁU)";
        dTxt.color = Color.white;
        dTxt.alignment = TextAnchor.MiddleCenter;
        Fill(dTxtGo.GetComponent<RectTransform>());

        CardUI chosenSlashUI = null;

        Action<CardUI> onCardSelected = (cardUI) =>
        {
            if (cardUI != null && IsSlashCard(cardUI.Data))
            {
                chosenSlashUI = cardUI;
                sBtn.interactable = true;
                sImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                SetLog($"⚔️ Đã chọn lá [{cardUI.Data.cardName}]. Nhấn nút [ĐÁNH TRẢM ĐỂ PHÁ CỌC]!");
            }
            else
            {
                chosenSlashUI = null;
                sBtn.interactable = false;
                sImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
            }
        };

        globalDefenseActive = true;
        currentGlobalDefType = CardSubType.BarbarianInvasion;
        onCurrentReactionCardSelected = onCardSelected;
        playerHandUI.HighlightOnlyMatching(IsSlashCard);

        playerHandUI.OnCardSelected += onCardSelected;
        if (playerHandUI.SelectedCard != null && IsSlashCard(playerHandUI.SelectedCard.Data))
        {
            onCardSelected(playerHandUI.SelectedCard);
        }

        sBtn.onClick.AddListener(() =>
        {
            if (chosenSlashUI != null)
            {
                var slashData = chosenSlashUI.Data;
                playerHandUI.RemoveCard(chosenSlashUI);
                deckManager.DiscardCard(slashData);
                ShowCardAtCenter(slashData, playerCard);
                AudioManager.Instance.PlaySlash();
                SetLog("⚔️ Bạn đã đánh ra lá [TRẢM] phá tan bãi cọc ngầm an toàn!");
                defenseResolved = true;
            }
        });

        dmgBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            playerCard.TakeDamage(1);
            AudioManager.Instance.PlayDamage();
            SetLog("💥 Bạn không có Trảm phá cọc, trúng Bãi Cọc Ngầm mất 1 hoa sen máu!");
            defenseResolved = true;
        });

        while (!defenseResolved)
        {
            yield return null;
        }

        playerHandUI.OnCardSelected -= onCardSelected;
        globalDefenseActive = false;
        currentGlobalDefType = null;
        onCurrentReactionCardSelected = null;
        playerHandUI.ResetAllCardsVisuals();
        if (reactionGo != null) Destroy(reactionGo);
        yield return ResolvePlayerNearDeath();
    }

    private IEnumerator AwaitForPlayerArrowRainDefense(CardModel scrollCard)
    {
        bool defenseResolved = false;

        SetLog("🏹 <color=#FF5555><b>MƯA TÊN LIÊN CHÂU BẮN TỚI!</b></color> Hãy chạm chọn lá [ĐỠ] trên tay để khiên chắn hoặc bấm [CHỊU ĐÒN].");

        var reactionGo = new GameObject("ArrowRainReactionPanel", typeof(RectTransform));
        reactionGo.transform.SetParent(transform, false);
        var rRt = reactionGo.GetComponent<RectTransform>();
        rRt.anchorMin = new Vector2(0.5f, 0f);
        rRt.anchorMax = new Vector2(0.5f, 0f);
        rRt.pivot = new Vector2(0.5f, 0f);
        rRt.sizeDelta = new Vector2(680f, 48f);
        rRt.anchoredPosition = new Vector2(-70f, 238f);

        var font = ThemeUI.FontMain;

        // Nút Đánh Đỡ
        var dodgeBtnGo = new GameObject("Btn_Dodge", typeof(RectTransform), typeof(Image), typeof(Button));
        dodgeBtnGo.transform.SetParent(reactionGo.transform, false);
        var dImg = dodgeBtnGo.GetComponent<Image>();
        var dRt = dodgeBtnGo.GetComponent<RectTransform>();
        dRt.anchorMin = dRt.anchorMax = dRt.pivot = new Vector2(0.5f, 0.5f);
        dRt.sizeDelta = new Vector2(260f, 42f);
        dRt.anchoredPosition = new Vector2(-100f, 0);

        var dTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        dTxtGo.transform.SetParent(dodgeBtnGo.transform, false);
        var dTxt = dTxtGo.GetComponent<Text>();
        dTxt.font = font;
        dTxt.fontSize = 13;
        dTxt.fontStyle = FontStyle.Bold;
        dTxt.text = "🛡️ ĐÁNH [ĐỠ] ĐỂ CHẮN TÊN";
        dTxt.color = Color.white;
        dTxt.alignment = TextAnchor.MiddleCenter;
        Fill(dTxtGo.GetComponent<RectTransform>());

        var dBtn = dodgeBtnGo.GetComponent<Button>();
        dBtn.interactable = false;
        dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);

        // Nút Chịu Sát Thương
        var dmgBtnGo = new GameObject("Btn_Damage", typeof(RectTransform), typeof(Image), typeof(Button));
        dmgBtnGo.transform.SetParent(reactionGo.transform, false);
        var dmgImg = dmgBtnGo.GetComponent<Image>();
        dmgImg.color = new Color(0.85f, 0.25f, 0.2f, 1f);
        var dmgRt = dmgBtnGo.GetComponent<RectTransform>();
        dmgRt.anchorMin = dmgRt.anchorMax = dmgRt.pivot = new Vector2(0.5f, 0.5f);
        dmgRt.sizeDelta = new Vector2(210f, 42f);
        dmgRt.anchoredPosition = new Vector2(170f, 0);

        var dmgTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        dmgTxtGo.transform.SetParent(dmgBtnGo.transform, false);
        var dmgTxt = dmgTxtGo.GetComponent<Text>();
        dmgTxt.font = font;
        dmgTxt.fontSize = 13;
        dmgTxt.fontStyle = FontStyle.Bold;
        dmgTxt.text = "❌ CHỊU ĐÒN (MẤT 1 MÁU)";
        dmgTxt.color = Color.white;
        dmgTxt.alignment = TextAnchor.MiddleCenter;
        Fill(dmgTxtGo.GetComponent<RectTransform>());

        CardUI chosenDodgeUI = null;

        Action<CardUI> onCardSelected = (cardUI) =>
        {
            if (cardUI != null && CanActAsDodge(playerCard, cardUI.Data))
            {
                chosenDodgeUI = cardUI;
                dBtn.interactable = true;
                dImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                SetLog($"🛡️ Đã chọn lá [{cardUI.Data.cardName}]. Nhấn nút [ĐÁNH ĐỠ ĐỂ CHẮN TÊN]!");
            }
            else
            {
                chosenDodgeUI = null;
                dBtn.interactable = false;
                dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
            }
        };

        globalDefenseActive = true;
        currentGlobalDefType = CardSubType.ArrowRain;
        onCurrentReactionCardSelected = onCardSelected;
        playerHandUI.HighlightOnlyMatching(IsDodgeCard);

        playerHandUI.OnCardSelected += onCardSelected;
        if (playerHandUI.SelectedCard != null && IsDodgeCard(playerHandUI.SelectedCard.Data))
        {
            onCardSelected(playerHandUI.SelectedCard);
        }

        dBtn.onClick.AddListener(() =>
        {
            if (chosenDodgeUI != null)
            {
                var dodgeData = chosenDodgeUI.Data;
                playerHandUI.RemoveCard(chosenDodgeUI);
                deckManager.DiscardCard(dodgeData);
                ShowCardAtCenter(dodgeData, playerCard);
                AudioManager.Instance.PlayParry();
                SetLog("🛡️ Bạn đã đánh ra lá [ĐỠ] khiên chắn thành công đợt Mưa Tên Liên Châu!");
                defenseResolved = true;
            }
        });

        dmgBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            playerCard.TakeDamage(1);
            AudioManager.Instance.PlayDamage();
            SetLog("💥 Bạn không có Đỡ che chắn, trúng Mưa Tên Liên Châu mất 1 hoa sen máu!");
            defenseResolved = true;
        });

        while (!defenseResolved)
        {
            yield return null;
        }

        playerHandUI.OnCardSelected -= onCardSelected;
        globalDefenseActive = false;
        currentGlobalDefType = null;
        onCurrentReactionCardSelected = null;
        playerHandUI.ResetAllCardsVisuals();
        if (reactionGo != null) Destroy(reactionGo);
        yield return ResolvePlayerNearDeath();
    }

    private IEnumerator ResolveBossBarbarianDefense()
    {
        yield return new WaitForSeconds(0.4f);
        var slashCard = BossPopHandCard(c => IsSlashCard(c));
        if (slashCard != null)
        {
            deckManager.DiscardCard(slashCard);
            ShowCardAtCenter(slashCard, bossCard);
            AudioManager.Instance.PlaySlash();
            SetLog($"⚔️ Sơn Tặc ra lá [{slashCard.cardName}] trên tay để phá tan bãi cọc ngầm!");
        }
        else
        {
            bossCard.TakeDamage(1);
            AudioManager.Instance.PlayDamage();
            SetLog("💥 Sơn Tặc không có Trảm phá cọc, trúng Bãi Cọc Ngầm mất 1 hoa sen máu!");
            CheckBossDefeat();
        }
    }

    private IEnumerator ResolveBossArrowRainDefense()
    {
        yield return new WaitForSeconds(0.4f);
        var dodgeCard = BossPopHandCard(c => IsDodgeCard(c));
        if (dodgeCard != null)
        {
            deckManager.DiscardCard(dodgeCard);
            ShowCardAtCenter(dodgeCard, bossCard);
            AudioManager.Instance.PlayParry();
            SetLog($"🛡️ Sơn Tặc ra lá [{dodgeCard.cardName}] trên tay che chắn an toàn cơn mưa tên!");
        }
        else
        {
            bossCard.TakeDamage(1);
            AudioManager.Instance.PlayDamage();
            SetLog("💥 Sơn Tặc không có Đỡ che chắn, trúng Mưa Tên mất 1 hoa sen máu!");
            CheckBossDefeat();
        }
    }

    private bool TryRescueBossIfNeeded()
    {
        if (bossCard == null || bossCard.CurrentHp > 0) return false;

        var rescue = BossPopHandCard(c => c.subType == CardSubType.Peach || c.subType == CardSubType.Wine);
        if (rescue == null) return false;

        deckManager.DiscardCard(rescue);
        ShowCardAtCenter(rescue, bossCard);
        bossCard.Heal(1);
        AudioManager.Instance.PlayHeal();
        SetLog($"💮 [SƠN TẶC CẬN TỬ]: Sơn Tặc dùng 1 lá [{rescue.cardName}] trên tay để tự cứu mạng! (Còn {bossHandCards.Count} lá trên tay).");
        return true;
    }

    private void FinishPlayerDefeat()
    {
        if (gameFinished) return;
        gameFinished = true;
        isPlayerTurn = false;
        playerPlayPhaseLocked = true;
        if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
        if (freePlayEndTurnBtnGo != null) freePlayEndTurnBtnGo.SetActive(false);
        AudioManager.Instance.PlayDamage();
        SetLog("💀 <color=#FF5555><b>BẠN ĐÃ TỬ TRẬN!</b></color> Không còn Bánh Chưng hoặc Hủ Rượu để cứu Cận Tử.");
    }

    private IEnumerator ResolvePlayerNearDeath()
    {
        if (playerCard == null || playerCard.CurrentHp > 0 || gameFinished) yield break;
        if (playerRescuePending)
        {
            while (playerRescuePending) yield return null;
            yield break;
        }

        var rescueCards = new List<CardUI>();
        foreach (var cardUI in playerHandUI.Cards)
        {
            if (cardUI != null && cardUI.Data != null &&
                (cardUI.Data.subType == CardSubType.Peach || cardUI.Data.subType == CardSubType.Wine))
            {
                rescueCards.Add(cardUI);
            }
        }

        if (rescueCards.Count == 0)
        {
            FinishPlayerDefeat();
            yield break;
        }

        playerRescuePending = true;
        bool resolved = false;
        bool rescued = false;

        var panelGo = new GameObject("NearDeathRescuePanel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(transform, false);
        panelGo.transform.SetAsLastSibling();
        var panelImg = panelGo.GetComponent<Image>();
        panelImg.color = new Color(0.04f, 0.02f, 0.06f, 0.96f);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(560f, 150f);
        panelRt.anchoredPosition = new Vector2(-70f, 120f);

        var font = ThemeUI.FontMain;
        var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(panelGo.transform, false);
        var title = titleGo.GetComponent<Text>();
        title.font = font;
        title.fontSize = 16;
        title.fontStyle = FontStyle.Bold;
        title.alignment = TextAnchor.MiddleCenter;
        title.color = new Color(1f, 0.85f, 0.35f, 1f);
        title.text = "💀 CẬN TỬ - CHỌN BÀI CỨU MẠNG";
        Fill(title.rectTransform, new Vector2(12f, 92f), new Vector2(-12f, -8f));

        var buttonRow = new GameObject("Buttons", typeof(RectTransform));
        buttonRow.transform.SetParent(panelGo.transform, false);
        var rowRt = buttonRow.GetComponent<RectTransform>();
        rowRt.anchorMin = new Vector2(0.5f, 0f);
        rowRt.anchorMax = new Vector2(0.5f, 0f);
        rowRt.pivot = new Vector2(0.5f, 0f);
        rowRt.sizeDelta = new Vector2(520f, 58f);
        rowRt.anchoredPosition = new Vector2(0f, 18f);

        void AddRescueButton(CardUI cardUI, int index)
        {
            var go = new GameObject("Rescue_" + index, typeof(RectTransform), typeof(Image), typeof(Button));
            go.transform.SetParent(buttonRow.transform, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(220f, 46f);
            rt.anchoredPosition = new Vector2((index - (rescueCards.Count - 1) * 0.5f) * 235f, 0f);
            go.GetComponent<Image>().color = new Color(0.2f, 0.65f, 0.3f, 1f);
            var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(go.transform, false);
            var txt = txtGo.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 13;
            txt.fontStyle = FontStyle.Bold;
            txt.alignment = TextAnchor.MiddleCenter;
            txt.color = Color.white;
            txt.text = cardUI.Data.subType == CardSubType.Peach ? "💮 DÙNG BÁNH CHƯNG (+1 MÁU)" : "🍶 DÙNG HỦ RƯỢU (+1 MÁU)";
            Fill(txt.rectTransform);
            go.GetComponent<Button>().onClick.AddListener(() =>
            {
                if (resolved || cardUI == null) return;
                var data = cardUI.Data;
                if (!playerHandUI.RemoveCard(cardUI)) return;
                deckManager.DiscardCard(data);
                playerCard.Heal(1);
                rescued = true;
                resolved = true;
                AudioManager.Instance.PlayHeal();
                SetLog($"💮 Bạn dùng [{data.cardName}] ở trạng thái Cận Tử và hồi lại 1 Máu!");
            });
        }

        for (int i = 0; i < rescueCards.Count; i++) AddRescueButton(rescueCards[i], i);
        SetLog("💀 Bạn đang ở trạng thái Cận Tử. Chọn Bánh Chưng hoặc Hủ Rượu để tự cứu!");

        while (!resolved) yield return null;

        if (panelGo != null) Destroy(panelGo);
        playerRescuePending = false;
        if (!rescued) FinishPlayerDefeat();
    }

    private void CheckBossDefeat()
    {
        if (bossCard == null || bossCard.CurrentHp > 0 || gameFinished) return;
        if (TryRescueBossIfNeeded()) return;

        gameFinished = true;
        isPlayerTurn = false;
        if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
        if (freePlayEndTurnBtnGo != null) freePlayEndTurnBtnGo.SetActive(false);
        AudioManager.Instance.PlayVictory();
        SetLog("🏆 <color=#FFD700><b>THẮNG LỢI VANG DỘI!</b></color> Thủ Lĩnh Sơn Tặc đã cạn máu và TỬ TRẬN!");
        ShowVictoryModal();
    }

    private void ShowVictoryModal()
    {
        var modalGo = new GameObject("VictoryModal", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        modalGo.transform.SetParent(transform, false);
        modalGo.transform.SetAsLastSibling();

        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.08f, 0.85f);
        Fill(modalGo.GetComponent<RectTransform>());

        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(modalGo.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        else bImg.color = new Color(0.08f, 0.12f, 0.2f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = new Vector2(580f, 320f);
        boxRt.anchoredPosition = Vector2.zero;

        var font = ThemeUI.FontMain;

        // Tiêu đề chiến thắng
        var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(boxGo.transform, false);
        var title = titleGo.GetComponent<Text>();
        title.font = font;
        title.fontSize = 24;
        title.fontStyle = FontStyle.Bold;
        title.text = "🏆 CHIẾN THẮNG VANG DỘI!";
        title.alignment = TextAnchor.MiddleCenter;
        title.color = GameTheme.GoldBright;
        var titleRt = titleGo.GetComponent<RectTransform>();
        titleRt.anchorMin = new Vector2(0, 1);
        titleRt.anchorMax = new Vector2(1, 1);
        titleRt.pivot = new Vector2(0.5f, 1);
        titleRt.sizeDelta = new Vector2(0, 40);
        titleRt.anchoredPosition = new Vector2(0, -20);
        AddTextShadow(title);

        var divGo = new GameObject("Divider", typeof(RectTransform), typeof(Image));
        divGo.transform.SetParent(boxGo.transform, false);
        var divImg = divGo.GetComponent<Image>();
        divImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/divider_gold");
        var divRt = divGo.GetComponent<RectTransform>();
        divRt.anchorMin = new Vector2(0.5f, 1);
        divRt.anchorMax = new Vector2(0.5f, 1);
        divRt.pivot = new Vector2(0.5f, 1);
        divRt.sizeDelta = new Vector2(340, 14);
        divRt.anchoredPosition = new Vector2(0, -62);

        var bodyGo = new GameObject("BodyText", typeof(RectTransform), typeof(Text));
        bodyGo.transform.SetParent(boxGo.transform, false);
        var bodyTxt = bodyGo.GetComponent<Text>();
        bodyTxt.font = font;
        bodyTxt.fontSize = 14;
        bodyTxt.color = new Color(0.92f, 0.96f, 1f, 1f);
        bodyTxt.lineSpacing = 1.4f;
        bodyTxt.alignment = TextAnchor.MiddleCenter;
        bodyTxt.text = "⚔️ <b>Thủ Lĩnh Sơn Tặc đã bị tiêu diệt hoàn toàn!</b>\n" +
                       "Bạn đã nắm vững toàn bộ quy tắc giao chiến trong <b>Đại Việt Chiến</b>.\n\n" +
                       "🎁 Hãy trở về Trang Chủ để nhận thưởng: <b>Tướng Lý Thường Kiệt</b> và <b>1.000 Bạc</b>!";
        var bodyRt = bodyGo.GetComponent<RectTransform>();
        bodyRt.anchorMin = new Vector2(0.08f, 0.28f);
        bodyRt.anchorMax = new Vector2(0.92f, 0.76f);
        bodyRt.pivot = new Vector2(0.5f, 0.5f);
        bodyRt.offsetMin = bodyRt.offsetMax = Vector2.zero;

        var returnBtnGo = new GameObject("ReturnBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        returnBtnGo.transform.SetParent(boxGo.transform, false);
        var btnImg = returnBtnGo.GetComponent<Image>();
        var btnSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSprite != null) { btnImg.sprite = btnSprite; btnImg.type = Image.Type.Sliced; }
        else btnImg.color = GameTheme.Gold;

        var btnRt = returnBtnGo.GetComponent<RectTransform>();
        btnRt.anchorMin = new Vector2(0.5f, 0f);
        btnRt.anchorMax = new Vector2(0.5f, 0f);
        btnRt.pivot = new Vector2(0.5f, 0f);
        btnRt.sizeDelta = new Vector2(300, 46);
        btnRt.anchoredPosition = new Vector2(0, 22);

        var btnTxtGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        btnTxtGo.transform.SetParent(returnBtnGo.transform, false);
        var btnTxt = btnTxtGo.GetComponent<Text>();
        btnTxt.font = font;
        btnTxt.fontSize = 15;
        btnTxt.fontStyle = FontStyle.Bold;
        btnTxt.text = "🎁 VỀ TRANG CHỦ NHẬN THƯỞNG ➜";
        btnTxt.color = new Color(0.12f, 0.08f, 0.02f, 1f);
        btnTxt.alignment = TextAnchor.MiddleCenter;
        Fill(btnTxtGo.GetComponent<RectTransform>());

        returnBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            var action = onTutorialComplete;
            Destroy(gameObject);
            if (action != null)
            {
                action.Invoke();
            }
            else
            {
                var auth = FindFirstObjectByType<AuthUI>();
                if (auth != null)
                {
                    auth.CheckAndShowTutorialReward();
                }
                else
                {
                    HomeUI.Open();
                }
            }
        });
    }

    private void BuildActionControls(Font font)
    {
        var actionPanelGo = new GameObject("ActionPanel", typeof(RectTransform));
        actionPanelGo.transform.SetParent(transform, false);
        var apRt = actionPanelGo.GetComponent<RectTransform>();
        apRt.anchorMin = new Vector2(0.5f, 0f);
        apRt.anchorMax = new Vector2(0.5f, 0f);
        apRt.pivot = new Vector2(0.5f, 0f);
        apRt.sizeDelta = new Vector2(680, 44);
        apRt.anchoredPosition = new Vector2(-70f, 238f);

        // 1. NÚT DÙNG BÀI (Chính giữa, xuất hiện khi chọn bài & chọn mục tiêu)
        freePlayActionBtnGo = new GameObject("Btn_PlayCard", typeof(RectTransform), typeof(Image), typeof(Button));
        freePlayActionBtnGo.transform.SetParent(actionPanelGo.transform, false);
        var playImg = freePlayActionBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { playImg.sprite = btnSpr; playImg.type = Image.Type.Sliced; }
        else playImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);

        var playRt = freePlayActionBtnGo.GetComponent<RectTransform>();
        playRt.anchorMin = playRt.anchorMax = playRt.pivot = new Vector2(0.5f, 0.5f);
        playRt.sizeDelta = new Vector2(280, 42);
        playRt.anchoredPosition = new Vector2(-40f, 0);

        var playTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        playTxtGo.transform.SetParent(freePlayActionBtnGo.transform, false);
        freePlayActionBtnText = playTxtGo.GetComponent<Text>();
        freePlayActionBtnText.font = font;
        freePlayActionBtnText.fontSize = 13;
        freePlayActionBtnText.fontStyle = FontStyle.Bold;
        freePlayActionBtnText.text = "⚔️ DÙNG BÀI";
        freePlayActionBtnText.color = new Color(0.12f, 0.08f, 0.02f, 1f);
        freePlayActionBtnText.alignment = TextAnchor.MiddleCenter;
        Fill(playTxtGo.GetComponent<RectTransform>());

        RestoreFreePlayActionButtonListener();
        freePlayActionBtnGo.SetActive(false);

        // 2. DUY NHẤT NÚT: KẾT THÚC LƯỢT (Nằm bên phải)
        freePlayEndTurnBtnGo = new GameObject("Btn_EndTurn", typeof(RectTransform), typeof(Image), typeof(Button));
        freePlayEndTurnBtnGo.transform.SetParent(actionPanelGo.transform, false);
        var endImg = freePlayEndTurnBtnGo.GetComponent<Image>();
        endImg.color = new Color(0.85f, 0.38f, 0.12f, 1f);

        var endRt = freePlayEndTurnBtnGo.GetComponent<RectTransform>();
        endRt.anchorMin = endRt.anchorMax = endRt.pivot = new Vector2(0.5f, 0.5f);
        endRt.sizeDelta = new Vector2(170, 42);
        endRt.anchoredPosition = new Vector2(200f, 0);

        var endTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        endTxtGo.transform.SetParent(freePlayEndTurnBtnGo.transform, false);
        var endTxt = endTxtGo.GetComponent<Text>();
        endTxt.font = font;
        endTxt.fontSize = 13;
        endTxt.fontStyle = FontStyle.Bold;
        endTxt.text = "KẾT THÚC LƯỢT ➜";
        endTxt.color = Color.white;
        endTxt.alignment = TextAnchor.MiddleCenter;
        Fill(endTxtGo.GetComponent<RectTransform>());

        freePlayEndTurnBtnGo.SetActive(isPlayerTurn && currentStep == TutorialStep.FreeBattleUnlocked && !gameFinished);

        freePlayEndTurnBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (!isPlayerTurn || gameFinished || playerRescuePending) return;
            if (playerTurnStartResolving)
            {
                SetLog("⏳ Đang hoàn tất giai đoạn phán xét/rút bài đầu lượt, hãy chờ một chút...");
                return;
            }
            if (playerActionResolving)
            {
                SetLog("⏳ Đang xử lý lá bài hiện tại, hãy chờ hiệu ứng kết thúc...");
                return;
            }

            // Kiểm tra quy tắc Bỏ Bài Cuối Lượt: Số bài trên tay tối đa bằng số máu hiện tại
            int currentCards = playerHandUI.Cards.Count;
            int currentHp = playerCard.CurrentHp;
            if (currentCards > currentHp)
            {
                int excess = currentCards - currentHp;
                freePlayDiscardPhaseActive = true;
                playerHandUI.IsMultiSelectMode = true;
                playerHandUI.MaxSelectableCards = excess;
                playerHandUI.ClearSelection();
                SetLog($"⚠️ <color=#FF5555><b>GIAI ĐOẠN BỎ BÀI:</b> Số bài trên tay ({currentCards}) nhiều hơn số máu ({currentHp})!</color> Vui lòng chọn đúng {excess} lá bài thừa rồi nhấn BỎ BÀI.");
                UpdateFreePlayDiscardActionBtn();
                return;
            }

            freePlayDiscardPhaseActive = false;
            playerHandUI.IsMultiSelectMode = false;
            // Do not carry a selected card into the opponent's turn (or the
            // next draw phase), where it could trigger a stale action.
            playerHandUI.ClearSelection();
            playerPlayPhaseLocked = false;
            SetPlayerTurn(false);
            ClearFreePlayTargetVisuals();
            StartCoroutine(BossTurnFreePlay());
        });
    }

    /// <summary>
    /// Rebinds the normal play action after discard mode temporarily replaces
    /// the same button's listener with a discard callback.
    /// </summary>
    private void RestoreFreePlayActionButtonListener()
    {
        if (freePlayActionBtnGo == null) return;

        var button = freePlayActionBtnGo.GetComponent<Button>();
        if (button == null) return;

        button.onClick.RemoveAllListeners();
        button.onClick.AddListener(() =>
        {
            if (playerHandUI == null || playerHandUI.SelectedCard == null) return;
            var cardUI = playerHandUI.SelectedCard;
            var target = currentTargetCard != null ? currentTargetCard : bossCard;
            ExecutePlayCard(cardUI, target);
        });
    }

    private void UpdateFreePlayDiscardActionBtn()
    {
        if (freePlayActionBtnGo == null) return;
        int currentCards = playerHandUI.Cards.Count;
        int currentHp = playerCard.CurrentHp;
        int excess = currentCards - currentHp;

        if (excess <= 0)
        {
            freePlayDiscardPhaseActive = false;
            playerHandUI.IsMultiSelectMode = false;
            RestoreFreePlayActionButtonListener();
            freePlayActionBtnGo.SetActive(false);
            return;
        }

        playerHandUI.IsMultiSelectMode = true;
        playerHandUI.MaxSelectableCards = excess;

        freePlayActionBtnGo.SetActive(true);
        var btn = freePlayActionBtnGo.GetComponent<Button>();
        var btnImg = freePlayActionBtnGo.GetComponent<Image>();
        int selectedCount = playerHandUI.SelectedCount;

        if (selectedCount == 0)
        {
            btn.interactable = false;
            btnImg.color = new Color(0.5f, 0.5f, 0.5f, 0.9f);
            freePlayActionBtnText.text = $"🗑️ CHỌN LÁ ĐỂ BỎ ({excess} lá thừa)";
        }
        else
        {
            btn.interactable = true;
            btnImg.color = new Color(0.85f, 0.35f, 0.15f, 1f);
            freePlayActionBtnText.text = (selectedCount == 1)
                ? $"🗑️ BỎ LÁ [{playerHandUI.SelectedCard.Data.cardName.ToUpper()}] ({excess} lá thừa)"
                : $"🗑️ BỎ {selectedCount} LÁ ĐÃ CHỌN ({excess} lá thừa)";

            btn.onClick.RemoveAllListeners();
            btn.onClick.AddListener(() =>
            {
                var toDiscard = new List<CardUI>(playerHandUI.SelectedCards);
                if (toDiscard.Count == 0) return;

                int excessNow = playerHandUI.Cards.Count - currentHp;
                if (excessNow > 0 && toDiscard.Count > excessNow)
                {
                    toDiscard = toDiscard.GetRange(0, excessNow);
                }

                foreach (var c in toDiscard)
                {
                    if (c != null && c.Data != null)
                    {
                        deckManager.DiscardCard(c.Data);
                    }
                }
                playerHandUI.RemoveCards(toDiscard);
                AudioManager.Instance.PlayCardSelect();

                int newCards = playerHandUI.Cards.Count;
                int newExcess = newCards - currentHp;

                if (newExcess <= 0)
                {
                    if (gameFinished) return;
                    freePlayDiscardPhaseActive = false;
                    playerHandUI.IsMultiSelectMode = false;
                    RestoreFreePlayActionButtonListener();
                    if (freePlayActionBtnGo != null) freePlayActionBtnGo.SetActive(false);
                    SetLog($"✅ <color=#55FF55><b>HOÀN TẤT BỎ BÀI!</b></color> Số bài trên tay: {newCards}/{currentHp}. Tự động chuyển lượt sang Thủ Lĩnh Sơn Tặc.");
                    SetPlayerTurn(false);
                    ClearFreePlayTargetVisuals();
                    StartCoroutine(BossTurnFreePlay());
                }
                else
                {
                    playerHandUI.MaxSelectableCards = newExcess;
                    SetLog($"🗑️ Đã bỏ {toDiscard.Count} lá. Vẫn còn thừa {newExcess} lá bài ({newCards}/{currentHp}). Hãy chọn tiếp {newExcess} lá để bỏ.");
                    UpdateFreePlayDiscardActionBtn();
                }
            });
        }
    }

    private IEnumerator BossTurnFreePlay()
    {
        if (gameFinished) yield break;
        SetPlayerTurn(false);
        SetLog("=== LƯỢT CỦA THỦ LĨNH SƠN TẶC ===");

        // --- GIAI ĐOẠN 1: PHÁN XÉT (JUDGEMENT PHASE) ---
        bool skipDrawPhase = false;
        bool skipPlayPhase = false;

        // 1. Phán xét Thần Sấm Báo Ứng
        if (bossCard.HasDelayedScroll(CardSubType.Lightning))
        {
            var delayed = bossCard.GetDelayedScroll(CardSubType.Lightning);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, playerCard, bossCard, result => isCanceled = result);
            if (gameFinished) yield break;

            if (isCanceled)
            {
                bossCard.RemoveDelayedScroll(CardSubType.Lightning);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, bossCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Sơn Tặc đã dùng Diệu Kế Phá Mưu giải trừ Thần Sấm Báo Ứng trước khi phán xét!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("⚡ [PHÁN XÉT THẦN SẤM]: Sơn Tặc lật bài phán xét Thần Sấm Báo Ứng...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool hit = (judgeCard.suit == CardSuit.Spade && (int)judgeCard.rank >= 2 && (int)judgeCard.rank <= 9);
                    yield return AnimateJudgementResult(
                        bossCard,
                        playerCard,
                        CardSubType.Lightning,
                        "Thần Sấm Báo Ứng",
                        judgeCard,
                        hit,
                        "bị sét đánh trúng MẤT 3 MÁU!",
                        "thoát sấm an toàn, chuyển sấm sang Bạn");

                    if (hit)
                    {
                        bossCard.TakeDamage(3);
                        CheckBossDefeat();
                        if (bossCard.CurrentHp <= 0) yield break;
                    }
                }
            }
        }

        // 2. Phán xét Cắt Đường Lương (Supply Shortage)
        if (bossCard.HasDelayedScroll(CardSubType.SupplyShortage))
        {
            var delayed = bossCard.GetDelayedScroll(CardSubType.SupplyShortage);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, playerCard, bossCard, result => isCanceled = result);
            if (gameFinished) yield break;

            if (isCanceled)
            {
                bossCard.RemoveDelayedScroll(CardSubType.SupplyShortage);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, bossCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Bạn đã dùng Diệu Kế Phá Mưu giải cứu Cắt Đường Lương cho Sơn Tặc!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("🌾 [PHÁN XÉT CẮT ĐƯỜNG LƯƠNG]: Sơn Tặc phán xét lương thảo...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool trapped = (judgeCard.suit != CardSuit.Club);
                    if (trapped) skipDrawPhase = true;

                    yield return AnimateJudgementResult(
                        bossCard,
                        playerCard,
                        CardSubType.SupplyShortage,
                        "Cắt Đường Lương",
                        judgeCard,
                        trapped,
                        "bị Cắt Đường Lương, BỎ QUA RÚT BÀI",
                        "thoát khỏi Cắt Đường Lương");
                }
            }
        }

        // 3. Phán xét Trầm Ảo Sa Bẫy (Acedia)
        if (bossCard.HasDelayedScroll(CardSubType.Acedia))
        {
            var delayed = bossCard.GetDelayedScroll(CardSubType.Acedia);
            bool isCanceled = false;
            yield return ResolveNullificationChain(delayed, playerCard, bossCard, result => isCanceled = result);
            if (gameFinished) yield break;

            if (isCanceled)
            {
                bossCard.RemoveDelayedScroll(CardSubType.Acedia);
                deckManager.DiscardCard(delayed);
                ShowCardAtCenter(delayed, bossCard, null, $"🛡️ Đã giải [{delayed.cardName}]");
                SetLog("🛡️ [Diệu Kế Phá Mưu]: Bạn đã dùng Diệu Kế Phá Mưu giải trừ Trầm Ảo Sa Bẫy!");
                yield return new WaitForSeconds(0.6f);
            }
            else
            {
                SetLog("🕸️ [PHÁN XÉT TRẦM ẢO]: Sơn Tặc phán xét mê hồn trận...");
                yield return new WaitForSeconds(0.5f);
                var judgeCard = deckManager.DrawCard();
                if (judgeCard != null)
                {
                    bool trapped = (judgeCard.suit != CardSuit.Heart);
                    if (trapped) skipPlayPhase = true;

                    yield return AnimateJudgementResult(
                        bossCard,
                        playerCard,
                        CardSubType.Acedia,
                        "Trầm Ảo Sa Bẫy",
                        judgeCard,
                        trapped,
                        "sa bẫy Trầm Ảo, BỎ QUA GIAI ĐOẠN RA BÀI",
                        "thoát khỏi Trầm Ảo Sa Bẫy");
                }
            }
        }

        // --- GIAI ĐOẠN 2: RÚT BÀI ---
        if (!skipDrawPhase)
        {
            SetLog("📜 [LƯỢT SƠN TẶC - RÚT BÀI]: Sơn Tặc bắt đầu rút 2 lá bài từ bộ bài vào tay.");
            yield return BossDrawCardsFromDeck(2);
            SetLog($"📜 [LƯỢT SƠN TẶC]: Sơn Tặc đã rút xong 2 lá bài. (Hiện có {bossHandCards.Count} lá trên tay).");
        }

        yield return new WaitForSeconds(0.6f);

        // --- GIAI ĐOẠN 3: RA BÀI (Nếu không bị bỏ qua) ---
        if (!skipPlayPhase)
        {
            // 1. Sơn Tặc dùng Bánh Chưng nếu bị thương (CurrentHp < MaxHp)
            while (bossCard.CurrentHp < bossCard.MaxHp)
            {
                var peach = BossPopHandCard(c => c.subType == CardSubType.Peach);
                if (peach == null) break;
                deckManager.DiscardCard(peach);
                ShowCardAtCenter(peach, bossCard);
                bossCard.Heal(1);
                AudioManager.Instance.PlayHeal();
                SetLog($"💮 [SƠN TẶC DÙNG BÁNH CHƯNG]: Sơn Tặc dùng 1 lá [{peach.cardName}] trên tay để hồi 1 Máu! (HP: {bossCard.CurrentHp}/{bossCard.MaxHp} - Còn {bossHandCards.Count} lá trên tay).");
                yield return new WaitForSeconds(0.6f);
            }

            // 2. Sơn Tặc trang bị các lá trang bị trên tay (Vũ khí, Giáp, Ngựa)
            while (bossHandCards.Exists(c => c != null && c.category == CardCategory.Equipment))
            {
                var equipCard = BossPopHandCard(c => c.category == CardCategory.Equipment);
                if (equipCard == null) break;
                if (bossCard.TryEquip(equipCard, out var replacedEquip))
                {
                    if (replacedEquip != null) deckManager.DiscardCard(replacedEquip);
                    ShowCardAtCenter(equipCard, bossCard);
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🛡️ [SƠN TẶC TRANG BỊ]: Sơn Tặc vừa trang bị [{equipCard.cardName}]!");
                    yield return new WaitForSeconds(0.6f);
                }
                else
                {
                    // Trả lại bài nếu không hợp lệ
                    BossAddHandCard(equipCard);
                    break;
                }
            }

            // 3. Sơn Tặc thi triển các Cẩm Nang Chủ Động (Instant Scrolls)
            // 3.1 Dụng Binh Như Thần (Rút 2 lá)
            while (true)
            {
                var exNihilo = BossPopHandCard(c => c.subType == CardSubType.ExNihilo);
                if (exNihilo == null) break;
                deckManager.DiscardCard(exNihilo);
                ShowCardAtCenter(exNihilo, bossCard);
                bool exCanceled = false;
                yield return ResolveNullificationChain(exNihilo, bossCard, playerCard, result => exCanceled = result);
                if (gameFinished) yield break;
                if (exCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                SetLog("📜 [Dụng Binh Như Thần]: Sơn Tặc thi triển Dụng Binh Như Thần, rút 2 lá bài từ bộ bài!");
                yield return BossDrawCardsFromDeck(2);
                yield return new WaitForSeconds(0.6f);
            }

            // 3.2 Mở Kho Cứu Tế: the revealed card must enter the real hand.
            while (true)
            {
                var harvest = BossPopHandCard(c => c.subType == CardSubType.Harvest);
                if (harvest == null) break;
                deckManager.DiscardCard(harvest);
                ShowCardAtCenter(harvest, bossCard);
                bool harvestCanceled = false;
                yield return ResolveNullificationChain(harvest, bossCard, playerCard, result => harvestCanceled = result);
                if (gameFinished) yield break;
                if (harvestCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                SetLog("🌾 [Mở Kho Cứu Tế]: Sơn Tặc phát lệnh Mở Kho Cứu Tế chia lương!");
                yield return ResolveHarvest(harvest, bossCard);
                if (gameFinished) yield break;
                yield return new WaitForSeconds(0.6f);
            }

            // 3.3 Diệu Kế Phá Mưu: when no pending scroll can be cancelled,
            // destroy one real card from the opponent's zones.
            while (bossHandCards.Exists(c => c != null && c.subType == CardSubType.FlawlessDefense) &&
                   BuildTargetCardOptions(playerCard, true).Count > 0)
            {
                var flawless = BossPopHandCard(c => c.subType == CardSubType.FlawlessDefense);
                if (flawless == null) break;
                deckManager.DiscardCard(flawless);
                ShowCardAtCenter(flawless, bossCard, playerCard);
                bool flawlessCanceled = false;
                yield return ResolveNullificationChain(flawless, bossCard, playerCard, result => flawlessCanceled = result);
                if (gameFinished) yield break;
                if (flawlessCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                yield return BossExecuteFlawlessDefense();
                yield return new WaitForSeconds(0.6f);
            }

            // 3.4 Vườn Không Nhà Trống (Phá 1 lá của người chơi)
            while (bossHandCards.Exists(c => c != null && c.subType == CardSubType.Dismantle) &&
                   BuildTargetCardOptions(playerCard, false).Count > 0)
            {
                var dismantle = BossPopHandCard(c => c.subType == CardSubType.Dismantle);
                if (dismantle == null) break;
                deckManager.DiscardCard(dismantle);
                ShowCardAtCenter(dismantle, bossCard, playerCard);
                bool dismantleCanceled = false;
                yield return ResolveNullificationChain(dismantle, bossCard, playerCard, result => dismantleCanceled = result);
                if (gameFinished) yield break;
                if (dismantleCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                yield return BossExecuteDismantle();
                yield return new WaitForSeconds(0.6f);
            }

            // 3.5 Đột Kích Trộm Lương (Cướp 1 lá của người chơi nếu cự ly <= 1)
            while (CalculateDistance(bossCard, playerCard) <= 1 &&
                   bossHandCards.Exists(c => c != null && c.subType == CardSubType.Snatch) &&
                   BuildTargetCardOptions(playerCard, true).Count > 0)
            {
                var snatch = BossPopHandCard(c => c.subType == CardSubType.Snatch);
                if (snatch == null) break;
                deckManager.DiscardCard(snatch);
                ShowCardAtCenter(snatch, bossCard, playerCard);
                bool snatchCanceled = false;
                yield return ResolveNullificationChain(snatch, bossCard, playerCard, result => snatchCanceled = result);
                if (gameFinished) yield break;
                if (snatchCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                yield return BossExecuteSnatch();
                yield return new WaitForSeconds(0.6f);
            }

            // 3.6 Bãi Cọc Ngầm / Mưa Tên Liên Châu (Diện rộng)
            while (true)
            {
                var globalScroll = BossPopHandCard(c => c.subType == CardSubType.BarbarianInvasion || c.subType == CardSubType.ArrowRain);
                if (globalScroll == null) break;
                deckManager.DiscardCard(globalScroll);
                ShowCardAtCenter(globalScroll, bossCard);
                bool globalCanceled = false;
                yield return ResolveNullificationChain(globalScroll, bossCard, playerCard, result => globalCanceled = result);
                if (gameFinished) yield break;
                if (globalCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                yield return ResolveGlobalScroll(globalScroll, bossCard);
                if (gameFinished) yield break;
                yield return new WaitForSeconds(0.6f);
            }

            // 3.7 Thách Đấu
            while (true)
            {
                var duel = BossPopHandCard(c => c.subType == CardSubType.Duel);
                if (duel == null) break;
                deckManager.DiscardCard(duel);
                ShowCardAtCenter(duel, bossCard, playerCard);
                bool duelCanceled = false;
                yield return ResolveNullificationChain(duel, bossCard, playerCard, result => duelCanceled = result);
                if (gameFinished) yield break;
                if (duelCanceled)
                {
                    yield return new WaitForSeconds(0.4f);
                    continue;
                }
                SetLog("⚔️ [Thách Đấu]: Sơn Tặc phát lệnh Thách Đấu với bạn!");
                yield return ResolveDuel(bossCard, playerCard);
                if (gameFinished) yield break;
                yield return new WaitForSeconds(0.6f);
            }

            // 4. Sơn Tặc gài Cẩm Nang Trì Hoãn vào vùng Phán Xét của Người chơi / Bản thân.
            // Snapshot the cards first so an illegal card returned to the hand cannot
            // make a pop/re-add loop spin forever.
            var delayedCards = new List<CardModel>(bossHandCards.FindAll(c => c != null && c.category == CardCategory.DelayedScroll));
            foreach (var delayed in delayedCards)
            {
                if (gameFinished) yield break;
                if (!BossRemoveSpecificCard(delayed)) continue;

                if (delayed.subType == CardSubType.Lightning)
                {
                    if (bossCard.HasDelayedScroll(CardSubType.Lightning))
                    {
                        BossAddHandCard(delayed);
                        continue;
                    }

                    ShowCardAtCenter(delayed, bossCard);
                    if (!bossCard.AddDelayedScroll(delayed))
                    {
                        BossAddHandCard(delayed);
                        continue;
                    }
                    SetLog("⚡ Sơn Tặc gài [Thần Sấm Báo Ứng] vào Vùng Phán Xét của mình!");
                    yield return new WaitForSeconds(0.6f);
                    continue;
                }

                if (delayed.subType == CardSubType.SupplyShortage && CalculateDistance(bossCard, playerCard) > 1)
                {
                    // Ngoài cự ly 1 không gài Cắt Đường Lương được -> Trả lại bài
                    BossAddHandCard(delayed);
                    continue;
                }

                if (playerCard.HasDelayedScroll(delayed.subType))
                {
                    // Đã có cùng loại bẫy -> Trả lại bài
                    BossAddHandCard(delayed);
                    continue;
                }

                ShowCardAtCenter(delayed, bossCard, playerCard);
                if (!playerCard.AddDelayedScroll(delayed))
                {
                    BossAddHandCard(delayed);
                    continue;
                }
                SetLog($"🕸️ Sơn Tặc gài bẫy [{delayed.cardName}] vào Vùng Phán Xét của bạn!");
                yield return new WaitForSeconds(0.6f);
            }

            // 5. Sơn Tặc tấn công bằng Trảm (NẾU CÓ TRẢM TRÊN TAY)
            if (IsTargetInAttackRange(bossCard, playerCard))
            {
                yield return BossAttackWithAvailableSlashes();
                if (gameFinished) yield break;
            }
            else
            {
                int dist = CalculateDistance(bossCard, playerCard);
                int range = bossCard.GetAttackRange();
                SetLog($"🛡️ Bạn đang ở Cự ly {dist} (vượt quá Tầm đánh {range} của Sơn Tặc). Sơn Tặc không thể tấn công tới bạn!");
            }
        }
        else
        {
            SetLog("💤 Sơn Tặc bị trúng hiệu ứng khống chế, kết thúc lượt mà không thể ra đòn!");
        }

        yield return new WaitForSeconds(0.4f);
        if (gameFinished) yield break;

        // --- GIAI ĐOẠN 4: SƠN TẶC BỎ BÀI CUỐI LƯỢT (DISCARD PHASE) ---
        int bossHand = bossHandCards.Count;
        int bossHp = bossCard.CurrentHp;
        if (bossHand > bossHp)
        {
            int bossExcess = bossHand - bossHp;
            SetLog($"🗑️ <color=#FFD700><b>[SƠN TẶC BỎ BÀI]</b></color>: Số bài trên tay ({bossHand}) > Máu ({bossHp}). Sơn Tặc tự động bỏ {bossExcess} lá bài thừa vào xấp xả.");
            yield return new WaitForSeconds(0.4f);

            for (int d = 0; d < bossExcess; d++)
            {
                if (gameFinished) yield break;
                var discardedCard = BossPopHandCard();
                if (discardedCard != null) deckManager.DiscardCard(discardedCard);
                yield return AnimateDiscardFlying(bossCard.transform.position);
                yield return new WaitForSeconds(0.18f);
            }
            yield return new WaitForSeconds(0.5f);
        }

        yield return new WaitForSeconds(0.4f);
        if (!gameFinished)
            StartCoroutine(PlayerTurnStartFreePlay());
    }

    private IEnumerator BossAttackWithAvailableSlashes()
    {
        int slashCount = 0;
        bool unlimited = bossCard.HasEquipment(EquipmentType.Weapon, "Nỏ Thần");

        while (IsTargetInAttackRange(bossCard, playerCard) && (unlimited || slashCount < 1))
        {
            var slashCard = BossPopHandCard(c => IsSlashCard(c));
            if (slashCard == null) yield break;

            bool bossUsedWine = false;
            var wineCard = BossPopHandCard(c => c.subType == CardSubType.Wine);
            if (wineCard != null)
            {
                bossUsedWine = true;
                deckManager.DiscardCard(wineCard);
                ShowCardAtCenter(wineCard, bossCard);
                AudioManager.Instance.PlaySkill();
                SetLog("🍶 Sơn Tặc uống [Hủ Rượu]: Đòn Trảm tiếp theo gây +1 sát thương (+2 Sát thương tổng)!");
                yield return new WaitForSeconds(0.6f);
            }

            int dmg = bossUsedWine ? 2 : 1;
            string wineLog = bossUsedWine ? " (kèm Hủ Rượu: 2 Sát thương!)" : "";
            deckManager.DiscardCard(slashCard);
            ShowCardAtCenter(slashCard, bossCard, playerCard);
            yield return ResolveSlashDefense(slashCard, bossCard, playerCard, dmg, wineLog);
            slashCount++;

            if (gameFinished || playerCard.CurrentHp <= 0 || bossCard.CurrentHp <= 0)
                yield break;
            yield return new WaitForSeconds(0.35f);
        }
    }

    private TargetCardOption ChooseBossTargetOption(bool allowDelayed)
    {
        var options = BuildTargetCardOptions(playerCard, allowDelayed);
        if (options.Count == 0) return null;

        // Prefer an equipped card when available; otherwise take the first real
        // hand/delayed card.  The important part is that the selected CardModel
        // is removed from its actual zone.
        var equipped = options.Find(o => o != null && o.Zone == TargetCardZone.Equipment);
        return equipped ?? options[0];
    }

    private bool TryRemoveBossTargetOption(bool allowDelayed, out TargetCardOption option)
    {
        option = ChooseBossTargetOption(allowDelayed);
        return option != null && TryRemoveTargetCardOption(playerCard, option);
    }

    private IEnumerator BossExecuteFlawlessDefense()
    {
        if (TryRemoveBossTargetOption(true, out var option))
        {
            deckManager.DiscardCard(option.Card);
            ShowCardAtCenter(option.Card, playerCard, null, $"Lá [{option.Card.cardName}] bị hủy");
            AudioManager.Instance.PlaySkill();
            SetLog($"🛡️ [Diệu Kế Phá Mưu]: Sơn Tặc hủy [{option.Card.cardName}] của bạn.");
        }
        yield return new WaitForSeconds(0.4f);
    }

    /// <summary>
    /// Bidirectional Nullification (Diệu Kế Phá Mưu) resolution loop.
    /// When any scroll is played, the opposing side is asked if they want to play Diệu Kế Phá Mưu.
    /// If played, the original caster can counter-nullify with their own Diệu Kế Phá Mưu, etc.
    /// </summary>
    private IEnumerator ResolveNullificationChain(CardModel rootScroll, GeneralCardUI caster, GeneralCardUI target, Action<bool> onResult)
    {
        if (rootScroll == null || (rootScroll.category != CardCategory.InstantScroll && rootScroll.category != CardCategory.DelayedScroll))
        {
            onResult?.Invoke(false);
            yield break;
        }

        bool isCurrentlyCanceled = false;
        GeneralCardUI currentAffected = (caster == playerCard) ? bossCard : playerCard;
        CardModel currentTargetScroll = rootScroll;

        while (true)
        {
            if (gameFinished)
            {
                onResult?.Invoke(isCurrentlyCanceled);
                yield break;
            }

            // Who has the incentive to nullify right now?
            // If !isCurrentlyCanceled: the defender of rootScroll wants to nullify it.
            // If isCurrentlyCanceled: the original caster wants to counter-nullify to restore rootScroll.
            GeneralCardUI sideToAsk = isCurrentlyCanceled ? caster : currentAffected;

            if (sideToAsk == playerCard)
            {
                bool playerUsedNullification = false;
                string promptTitle = isCurrentlyCanceled
                    ? $"🛡️ Sơn Tặc dùng [Diệu Kế] hủy [{rootScroll.cardName}]. Dùng Diệu Kế để chống lại?"
                    : $"🛡️ Sơn Tặc dùng [{rootScroll.cardName}]. Dùng Diệu Kế để hóa giải?";

                yield return PromptPlayerCounterScroll(currentTargetScroll, promptTitle, result => playerUsedNullification = result);

                if (playerUsedNullification)
                {
                    isCurrentlyCanceled = !isCurrentlyCanceled;
                    yield return new WaitForSeconds(0.4f);
                    // Now the other side (Boss) gets a chance to respond!
                    continue;
                }
                else
                {
                    // Player chose not to nullify, chain ends here.
                    break;
                }
            }
            else if (sideToAsk == bossCard)
            {
                // Boss AI decision
                yield return new WaitForSeconds(0.35f);
                var bossFlawless = BossPopHandCard(c => c != null && c.subType == CardSubType.FlawlessDefense);
                if (bossFlawless != null)
                {
                    deckManager.DiscardCard(bossFlawless);
                    ShowCardAtCenter(bossFlawless, bossCard, playerCard);
                    AudioManager.Instance.PlaySkill();
                    string bossMsg = isCurrentlyCanceled
                        ? $"🛡️ [Sơn Tặc]: Sơn Tặc tung [Diệu Kế Phá Mưu] để bảo vệ mưu kế!"
                        : $"🛡️ [Sơn Tặc]: Sơn Tặc tung [Diệu Kế Phá Mưu] để hóa giải [{rootScroll.cardName}] của bạn!";
                    SetLog(bossMsg);
                    isCurrentlyCanceled = !isCurrentlyCanceled;
                    currentTargetScroll = bossFlawless;
                    yield return new WaitForSeconds(0.4f);
                    // Player gets a chance to counter Boss's Diệu Kế!
                    continue;
                }
                else
                {
                    // Boss has no Diệu Kế or chooses not to, chain ends here.
                    break;
                }
            }
        }

        onResult?.Invoke(isCurrentlyCanceled);
    }

    private IEnumerator PromptPlayerCounterScroll(CardModel scrollCard, Action<bool> onResolved)
    {
        yield return PromptPlayerCounterScroll(scrollCard, $"🛡️ [DIỆU KẾ] Hóa giải [{scrollCard?.cardName}] của Sơn Tặc?", onResolved);
    }

    private IEnumerator PromptPlayerCounterScroll(CardModel scrollCard, string customTitle, Action<bool> onResolved)
    {
        if (gameFinished || scrollCard == null || scrollCard.category == CardCategory.Basic ||
            playerHandUI == null)
        {
            onResolved?.Invoke(false);
            yield break;
        }

        CardUI counterCard = null;
        foreach (var cardUI in playerHandUI.Cards)
        {
            if (cardUI != null && cardUI.Data != null && cardUI.Data.subType == CardSubType.FlawlessDefense)
            {
                counterCard = cardUI;
                break;
            }
        }

        if (counterCard == null)
        {
            onResolved?.Invoke(false);
            yield break;
        }

        counterPromptActive = true;
        playerHandUI.ClearSelection();
        playerHandUI.HighlightOnlyMatching(c => c != null && c.subType == CardSubType.FlawlessDefense);

        bool decided = false;
        bool canceled = false;
        var font = ThemeUI.FontMain;
        var panelGo = new GameObject("CounterScrollPrompt", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(transform, false);
        panelGo.transform.SetAsLastSibling();
        var panelImg = panelGo.GetComponent<Image>();
        panelImg.color = new Color(0.04f, 0.02f, 0.08f, 0.97f);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(580f, 130f);
        panelRt.anchoredPosition = new Vector2(-70f, 122f);

        var titleGo = new GameObject("Title", typeof(RectTransform), typeof(Text));
        titleGo.transform.SetParent(panelGo.transform, false);
        var title = titleGo.GetComponent<Text>();
        title.font = font;
        title.fontSize = 14;
        title.fontStyle = FontStyle.Bold;
        title.alignment = TextAnchor.MiddleCenter;
        title.color = new Color(1f, 0.85f, 0.35f, 1f);
        title.text = string.IsNullOrEmpty(customTitle) ? $"🛡️ [DIỆU KẾ] Hóa giải [{scrollCard.cardName}] của Sơn Tặc?" : customTitle;
        Fill(title.rectTransform, new Vector2(12f, 76f), new Vector2(-12f, -8f));

        GameObject MakeButton(string name, string label, Vector2 position, Color color)
        {
            var buttonGo = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            buttonGo.transform.SetParent(panelGo.transform, false);
            var buttonRt = buttonGo.GetComponent<RectTransform>();
            buttonRt.anchorMin = buttonRt.anchorMax = buttonRt.pivot = new Vector2(0.5f, 0.5f);
            buttonRt.sizeDelta = new Vector2(240f, 42f);
            buttonRt.anchoredPosition = position;
            buttonGo.GetComponent<Image>().color = color;
            var txtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtGo.transform.SetParent(buttonGo.transform, false);
            var txt = txtGo.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 12;
            txt.fontStyle = FontStyle.Bold;
            txt.alignment = TextAnchor.MiddleCenter;
            txt.color = Color.white;
            txt.text = label;
            Fill(txt.rectTransform);
            return buttonGo;
        }

        var cancelGo = MakeButton("Cancel", "🛡️ DÙNG DIỆU KẾ PHÁ MƯU", new Vector2(-130f, -28f), new Color(0.15f, 0.58f, 0.32f, 1f));
        var passGo = MakeButton("Pass", "BỎ QUA / KHÔNG DÙNG", new Vector2(130f, -28f), new Color(0.42f, 0.42f, 0.48f, 1f));

        cancelGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (counterCard == null || !playerHandUI.RemoveCard(counterCard)) return;
            deckManager.DiscardCard(counterCard.Data);
            ShowCardAtCenter(counterCard.Data, playerCard, bossCard);
            AudioManager.Instance.PlaySkill();
            SetLog($"🛡️ [Diệu Kế Phá Mưu]: Bạn đã dùng Diệu Kế Phá Mưu để hóa giải mưu kế!");
            canceled = true;
            decided = true;
        });
        passGo.GetComponent<Button>().onClick.AddListener(() => decided = true);

        while (!decided && !gameFinished)
            yield return null;

        playerHandUI.ResetAllCardsVisuals();
        if (panelGo != null) Destroy(panelGo);
        counterPromptActive = false;
        onResolved?.Invoke(canceled);
    }

    private IEnumerator BossExecuteDismantle()
    {
        if (TryRemoveBossTargetOption(false, out var option))
        {
            deckManager.DiscardCard(option.Card);
            ShowCardAtCenter(option.Card, playerCard, null, $"Lá [{option.Card.cardName}] bị phá hủy");
            AudioManager.Instance.PlaySkill();
            SetLog($"🏚️ [Vườn Không Nhà Trống]: Sơn Tặc phá hủy [{option.Card.cardName}] của bạn.");
        }
        yield return new WaitForSeconds(0.4f);
    }

    private IEnumerator BossExecuteSnatch()
    {
        if (TryRemoveBossTargetOption(true, out var option))
        {
            BossAddHandCard(option.Card);
            AudioManager.Instance.PlayCardDraw();
            string cardDesc = option.Zone == TargetCardZone.Hand ? "1 lá bài trên tay" : $"lá [{option.Card.cardName}]";
            SetLog($"🌾 [Đột Kích Trộm Lương]: Sơn Tặc cướp {cardDesc} từ khu vực {option.Label.ToLowerInvariant()} của bạn!");
        }
        yield return new WaitForSeconds(0.4f);
    }
    #endregion

    #region 9. UI HELPERS & ANIMATIONS
    private void EnsureTutorialOverlay()
    {
        if (tutorialStepOverlay != null) return;

        var font = ThemeUI.FontMain;

        tutorialStepOverlay = new GameObject("TutorialStepOverlay", typeof(RectTransform));
        tutorialStepOverlay.transform.SetParent(transform, false);
        tutorialStepOverlay.transform.SetAsLastSibling();
        Fill(tutorialStepOverlay.GetComponent<RectTransform>());

        // Hộp thông điệp hướng dẫn ở giữa trên
        var promptGo = new GameObject("PromptBox", typeof(RectTransform), typeof(Image));
        promptGo.transform.SetParent(tutorialStepOverlay.transform, false);
        var pImg = promptGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSprite != null) { pImg.sprite = bgSprite; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.08f, 0.12f, 0.22f, 0.96f);
        pImg.raycastTarget = false;

        var promptBoxRt = promptGo.GetComponent<RectTransform>();
        promptBoxRt.anchorMin = promptBoxRt.anchorMax = promptBoxRt.pivot = new Vector2(0.5f, 0.5f);
        promptBoxRt.sizeDelta = new Vector2(620, 95);
        promptBoxRt.anchoredPosition = new Vector2(-60, 20);

        var txtGo = new GameObject("PromptText", typeof(RectTransform), typeof(Text));
        txtGo.transform.SetParent(promptGo.transform, false);
        tutorialPromptText = txtGo.GetComponent<Text>();
        tutorialPromptText.font = font;
        tutorialPromptText.fontSize = 14;
        tutorialPromptText.fontStyle = FontStyle.Bold;
        tutorialPromptText.color = Color.white;
        tutorialPromptText.alignment = TextAnchor.MiddleCenter;
        tutorialPromptText.lineSpacing = 1.3f;
        Fill(txtGo.GetComponent<RectTransform>(), new Vector2(16, 8), new Vector2(-16, -8));
        AddTextShadow(tutorialPromptText);

        // Mũi tên chỉ dẫn
        var arrowGo = new GameObject("TutorialArrow", typeof(RectTransform), typeof(Image));
        arrowGo.transform.SetParent(tutorialStepOverlay.transform, false);
        var arrowImg = arrowGo.GetComponent<Image>();
        arrowImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/tutorial_arrow");
        arrowImg.preserveAspect = true;
        arrowImg.raycastTarget = false;
        tutorialArrowRt = arrowGo.GetComponent<RectTransform>();
        tutorialArrowRt.anchorMin = tutorialArrowRt.anchorMax = tutorialArrowRt.pivot = new Vector2(0.5f, 0.5f);
        tutorialArrowRt.sizeDelta = new Vector2(72, 44);

        var arrowTagGo = new GameObject("ArrowLabel", typeof(RectTransform), typeof(Text));
        arrowTagGo.transform.SetParent(arrowGo.transform, false);
        tutorialArrowLabel = arrowTagGo.GetComponent<Text>();
        tutorialArrowLabel.font = font;
        tutorialArrowLabel.fontSize = 13;
        tutorialArrowLabel.fontStyle = FontStyle.Bold;
        tutorialArrowLabel.text = "";
        tutorialArrowLabel.color = new Color(1f, 0.82f, 0.25f, 1f);
        tutorialArrowLabel.alignment = TextAnchor.MiddleCenter;
        var arrowTagRt = arrowTagGo.GetComponent<RectTransform>();
        arrowTagRt.anchorMin = new Vector2(0.5f, 1f);
        arrowTagRt.anchorMax = new Vector2(0.5f, 1f);
        arrowTagRt.pivot = new Vector2(0.5f, 0f);
        arrowTagRt.sizeDelta = new Vector2(190, 26);
        arrowTagRt.anchoredPosition = new Vector2(-22, 5);
        AddTextShadow(tutorialArrowLabel);
        arrowGo.SetActive(false);

        // Nút hành động chính
        tutorialActionBtn = new GameObject("TutorialActionBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        tutorialActionBtn.transform.SetParent(tutorialStepOverlay.transform, false);
        var brt = tutorialActionBtn.GetComponent<RectTransform>();
        brt.anchorMin = brt.anchorMax = brt.pivot = new Vector2(0.5f, 0f);
        brt.sizeDelta = new Vector2(240, 44);
        brt.anchoredPosition = new Vector2(-60, 238);
        var actionImg = tutorialActionBtn.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { actionImg.sprite = btnSpr; actionImg.type = Image.Type.Sliced; }
        else actionImg.color = GameTheme.Gold;

        var btnTxtGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        btnTxtGo.transform.SetParent(tutorialActionBtn.transform, false);
        tutorialActionBtnText = btnTxtGo.GetComponent<Text>();
        tutorialActionBtnText.font = font;
        tutorialActionBtnText.fontSize = 15;
        tutorialActionBtnText.fontStyle = FontStyle.Bold;
        tutorialActionBtnText.alignment = TextAnchor.MiddleCenter;
        tutorialActionBtnText.color = new Color(0.12f, 0.08f, 0.02f, 1f);
        Fill(btnTxtGo.GetComponent<RectTransform>());
        tutorialActionBtn.SetActive(false);
    }

    private void SetTutorialMask(bool active)
    {
        if (tutorialStepOverlay == null) return;

        if (tutorialMaskGo == null)
        {
            tutorialMaskGo = new GameObject("TutorialDimMask", typeof(RectTransform), typeof(Image));
            tutorialMaskGo.transform.SetParent(tutorialStepOverlay.transform, false);
            tutorialMaskGo.transform.SetAsFirstSibling();
            var maskImage = tutorialMaskGo.GetComponent<Image>();
            maskImage.color = new Color(0.01f, 0.02f, 0.05f, 0.72f);
            // Let clicks pass through to the highlighted card/avatar below.
            maskImage.raycastTarget = false;
            Fill(tutorialMaskGo.GetComponent<RectTransform>());
        }

        tutorialMaskGo.SetActive(active);
    }

    private void ClearTutorialVisuals()
    {
        if (tutorialArrowRt != null) tutorialArrowRt.gameObject.SetActive(false);
        if (tutorialTargetBorder != null) Destroy(tutorialTargetBorder.gameObject);

        if (playerHandUI != null)
        {
            playerHandUI.ResetAllCardsVisuals();
            playerHandUI.RearrangeHand();
        }

        if (bossCard != null)
        {
            var bossGlow = bossCard.transform.Find("TutorialGlow");
            if (bossGlow != null) Destroy(bossGlow.gameObject);
        }
    }

    private void PositionTutorialArrowAt(RectTransform target, string label, Vector2 offset)
    {
        if (tutorialArrowRt == null || target == null) return;
        Canvas.ForceUpdateCanvases();
        var overlayRt = tutorialStepOverlay.GetComponent<RectTransform>();
        var corners = new Vector3[4];
        target.GetWorldCorners(corners);
        Vector3 leftCenterWorld = (corners[0] + corners[1]) * 0.5f;
        Vector3 leftCenter = overlayRt.InverseTransformPoint(leftCenterWorld);
        tutorialArrowBasePos = new Vector2(leftCenter.x, leftCenter.y) + offset;
        tutorialArrowRt.anchoredPosition = tutorialArrowBasePos;
        if (tutorialArrowLabel != null) tutorialArrowLabel.text = label;
        tutorialArrowRt.gameObject.SetActive(true);
    }

    private void PositionTutorialArrowInside(RectTransform target, string label)
    {
        if (tutorialArrowRt == null || target == null) return;
        Canvas.ForceUpdateCanvases();
        var overlayRt = tutorialStepOverlay.GetComponent<RectTransform>();
        Vector3 aimWorld = target.TransformPoint(new Vector3(target.rect.center.x, Mathf.Lerp(target.rect.yMin, target.rect.yMax, 0.62f), 0f));
        Vector3 aimLocal = overlayRt.InverseTransformPoint(aimWorld);
        tutorialArrowBasePos = new Vector2(aimLocal.x - 60f, aimLocal.y);
        tutorialArrowRt.anchoredPosition = tutorialArrowBasePos;
        if (tutorialArrowLabel != null) tutorialArrowLabel.text = label;
        tutorialArrowRt.gameObject.SetActive(true);
    }

    private void AddTutorialGlow(Transform target)
    {
        var glowGo = new GameObject("TutorialGlow", typeof(RectTransform), typeof(Image));
        glowGo.transform.SetParent(target, false);
        glowGo.transform.SetAsFirstSibling();
        var glow = glowGo.GetComponent<Image>();
        glow.sprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        glow.color = new Color(1f, 0.82f, 0.2f, 0.72f);
        glow.raycastTarget = false;
        Fill(glowGo.GetComponent<RectTransform>(), new Vector2(-8, -8), new Vector2(8, 8));
    }

    private IEnumerator AnimateJudgementResult(
        GeneralCardUI general,
        GeneralCardUI nextGeneral,
        CardSubType scrollType,
        string scrollName,
        CardModel judgeCard,
        bool isTrapped,
        string trapMessage,
        string escapeMessage)
    {
        // 1. Hiển thị lá bài phán xét lật ngửa ở giữa màn hình
        var judgeCardGo = CardUI.Create(transform, judgeCard, new Vector2(110f, 150f)).gameObject;
        var rt = judgeCardGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = new Vector2(0, 30f);
        judgeCardGo.transform.localScale = Vector3.one * 0.6f;

        // Hoạt cảnh phóng to xuất hiện
        float el = 0f;
        while (el < 0.22f)
        {
            el += Time.deltaTime;
            judgeCardGo.transform.localScale = Vector3.one * Mathf.Lerp(0.6f, 1.12f, el / 0.22f);
            yield return null;
        }
        judgeCardGo.transform.localScale = Vector3.one * 1.12f;

        // 2. Banner biểu tượng kết quả (TICK ✔ nếu bị giam / trúng sấm, X ✖ nếu thoát bẫy / an toàn)
        var font = ThemeUI.FontMain;

        var badgeGo = new GameObject("JudgementBadge", typeof(RectTransform), typeof(Image));
        badgeGo.transform.SetParent(judgeCardGo.transform, false);
        var badgeRt = badgeGo.GetComponent<RectTransform>();
        badgeRt.anchorMin = new Vector2(0.5f, 0.5f);
        badgeRt.anchorMax = new Vector2(0.5f, 0.5f);
        badgeRt.pivot = new Vector2(0.5f, 0.5f);
        badgeRt.sizeDelta = new Vector2(160f, 160f);
        badgeRt.anchoredPosition = Vector2.zero;

        var bImg = badgeGo.GetComponent<Image>();
        bImg.color = new Color(0.04f, 0.06f, 0.12f, 0.68f);

        var iconGo = new GameObject("Icon", typeof(RectTransform), typeof(Text));
        iconGo.transform.SetParent(badgeGo.transform, false);
        var iconTxt = iconGo.GetComponent<Text>();
        iconTxt.font = font;
        iconTxt.fontSize = isTrapped ? 76 : 72;
        iconTxt.fontStyle = FontStyle.Bold;
        iconTxt.alignment = TextAnchor.MiddleCenter;
        // TICK (✔) màu xanh lá nếu bị giam / trúng sấm, X (✖) màu đỏ nếu thoát
        iconTxt.text = isTrapped ? "<color=#44FF55>✔</color>" : "<color=#FF4444>✖</color>";
        AddTextShadow(iconTxt);
        Fill(iconGo.GetComponent<RectTransform>());

        var labelGo = new GameObject("Label", typeof(RectTransform), typeof(Text));
        labelGo.transform.SetParent(judgeCardGo.transform, false);
        var lTxt = labelGo.GetComponent<Text>();
        lTxt.font = font;
        lTxt.fontSize = 13;
        lTxt.fontStyle = FontStyle.Bold;
        lTxt.alignment = TextAnchor.MiddleCenter;
        lTxt.text = isTrapped
            ? $"<color=#44FF55><b>✔ {(scrollType == CardSubType.Lightning ? "TRÚNG SẤM NỔ!" : "BỊ GIAM!")}</b></color>\n<size=11>{trapMessage}</size>"
            : $"<color=#FF5555><b>✖ {(scrollType == CardSubType.Lightning ? "AN TOÀN!" : "THOÁT BẪY!")}</b></color>\n<size=11>{escapeMessage}</size>";
        AddTextShadow(lTxt);
        var lRt = labelGo.GetComponent<RectTransform>();
        lRt.anchorMin = new Vector2(0.5f, 0f);
        lRt.anchorMax = new Vector2(0.5f, 0f);
        lRt.pivot = new Vector2(0.5f, 1f);
        lRt.sizeDelta = new Vector2(260f, 44f);
        lRt.anchoredPosition = new Vector2(0, -8f);

        if (isTrapped)
        {
            AudioManager.Instance.PlayDamage();
            SetLog($"✔ <color=#FF5555><b>[PHÁN XÉT {scrollName.ToUpper()} - TRÚNG ĐÒN]</b></color>: Lá bài là [{judgeCard.GetSuitSymbol()}{judgeCard.GetRankString()}]. {general.GeneralName} {trapMessage}!");
        }
        else
        {
            AudioManager.Instance.PlayParry();
            SetLog($"✖ <color=#55FF55><b>[PHÁN XÉT {scrollName.ToUpper()} - THOÁT NẠN]</b></color>: Lá bài là [{judgeCard.GetSuitSymbol()}{judgeCard.GetRankString()}]. {general.GeneralName} {escapeMessage}!");
        }

        // Chờ hiển thị rõ ràng 1.4s để người chơi thấy rõ lá phán xét và biểu tượng
        yield return new WaitForSeconds(1.4f);

        // Xóa hoạt cảnh
        Destroy(judgeCardGo);

        // Xử lý di chuyển hoặc hủy lá bài phán xét:
        var scrollCard = general.GetDelayedScroll(scrollType);
        general.RemoveDelayedScroll(scrollType);
        deckManager.DiscardCard(judgeCard);

        if (scrollType == CardSubType.Lightning)
        {
            if (isTrapped)
            {
                // Trúng sấm: Bị nổ tung và xả lá bài Thần Sấm vào xấp xả
                if (scrollCard != null) deckManager.DiscardCard(scrollCard);
            }
            else
            {
                // Thoát sấm: Chuyển sang Vùng Phán Xét của người tiếp theo
                var transferTarget = nextGeneral;
                if (transferTarget == null || transferTarget.CurrentHp <= 0)
                {
                    transferTarget = general == playerCard ? bossCard : playerCard;
                }

                if (scrollCard != null && transferTarget != null && transferTarget.CurrentHp > 0 &&
                    transferTarget.AddDelayedScroll(scrollCard))
                {
                    SetLog($"⚡ <color=#FFD700>[THẦN SẤM BÁO ỨNG]</color> chuyển sang Vùng Phán Xét của <color=#55FF55><b>{transferTarget.GeneralName}</b></color> chờ phán xét lượt sau!");
                }
                else if (scrollCard != null)
                {
                    // A duplicate delayed slot or no living recipient must not
                    // leave the card in limbo.
                    deckManager.DiscardCard(scrollCard);
                }
            }
        }
        else
        {
            // Các bẫy Cắt Lương, Trầm Ảo sau khi phán xét xong thì xả bài
            if (scrollCard != null) deckManager.DiscardCard(scrollCard);
        }

        yield return new WaitForSeconds(0.3f);
    }

    private bool CanActAsSlash(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        if (IsSlashCard(c)) return true;
        if (g != null && g.GeneralName.Contains("Lý Thường Kiệt") && c.subType == CardSubType.Dodge) return true;
        return false;
    }

    private bool CanActAsDodge(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        if (c.subType == CardSubType.Dodge) return true;
        if (g != null && g.GeneralName.Contains("Lý Thường Kiệt") && IsSlashCard(c)) return true;
        return false;
    }

    private static bool IsSlashCard(CardModel card)
    {
        return card != null && card.category == CardCategory.Basic &&
            (card.subType == CardSubType.AttackNormal || card.subType == CardSubType.AttackFire || card.subType == CardSubType.AttackThunder);
    }

    private static bool IsDodgeCard(CardModel card)
    {
        return card != null && card.category == CardCategory.Basic && card.subType == CardSubType.Dodge;
    }

    private void BuildActionHistoryPanel(Font font)
    {
        // Overlay toàn màn hình (Độ mờ thấp ~0.38f) để click ra ngoài là tự tắt popup
        historyOverlayGo = new GameObject("HistoryPopupOverlay", typeof(RectTransform), typeof(Image), typeof(Button));
        historyOverlayGo.transform.SetParent(transform, false);
        Fill(historyOverlayGo.GetComponent<RectTransform>());
        var ovImg = historyOverlayGo.GetComponent<Image>();
        ovImg.color = new Color(0f, 0f, 0f, 0.38f);
        historyOverlayGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            historyOverlayGo.SetActive(false);
        });
        historyOverlayGo.SetActive(false);

        // Khung Popup chính ở GIỮA MÀN HÌNH (580 x 380)
        var guideGo = new GameObject("ActionHistoryModal", typeof(RectTransform), typeof(Image));
        guideGo.transform.SetParent(historyOverlayGo.transform, false);
        var img = guideGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSprite != null) { img.sprite = bgSprite; img.type = Image.Type.Sliced; }
        img.color = new Color(0.07f, 0.10f, 0.18f, 0.98f);
        img.raycastTarget = true; // Chặn click xuyên qua overlay

        var rt = guideGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(580f, 380f);
        rt.anchoredPosition = Vector2.zero;

        // Viền hào quang vàng
        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(guideGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.95f, 0.8f, 0.3f, 0.9f);
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>());

        // Nút mở lịch sử ở góc dưới bên trái
        var toggleGo = new GameObject("HistoryButton", typeof(RectTransform), typeof(Image), typeof(Button));
        toggleGo.transform.SetParent(transform, false);
        var toggleRt = toggleGo.GetComponent<RectTransform>();
        toggleRt.anchorMin = toggleRt.anchorMax = toggleRt.pivot = new Vector2(0f, 0f);
        toggleRt.sizeDelta = new Vector2(128f, 34f);
        toggleRt.anchoredPosition = new Vector2(18f, 18f);
        toggleGo.GetComponent<Image>().color = new Color(0.18f, 0.3f, 0.48f, 0.96f);
        toggleGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            historyOverlayGo.SetActive(true);
            historyOverlayGo.transform.SetAsLastSibling();
            if (historyScrollRect != null) historyScrollRect.verticalNormalizedPosition = 0f;
        });

        var toggleTxt = new GameObject("Label", typeof(RectTransform), typeof(Text)).GetComponent<Text>();
        toggleTxt.transform.SetParent(toggleGo.transform, false);
        toggleTxt.font = font;
        toggleTxt.fontSize = 12;
        toggleTxt.fontStyle = FontStyle.Bold;
        toggleTxt.text = "📜 LỊCH SỬ";
        toggleTxt.color = Color.white;
        toggleTxt.alignment = TextAnchor.MiddleCenter;
        Fill(toggleTxt.rectTransform);

        // Tiêu đề Popup
        var titleTxt = new GameObject("GuideTitle", typeof(RectTransform), typeof(Text)).GetComponent<Text>();
        titleTxt.transform.SetParent(guideGo.transform, false);
        titleTxt.font = font;
        titleTxt.fontSize = 16;
        titleTxt.fontStyle = FontStyle.Bold;
        titleTxt.text = "📜 LỊCH SỬ CHIẾN TRẬN";
        titleTxt.color = GameTheme.GoldBright;
        titleTxt.alignment = TextAnchor.MiddleCenter;
        var titleRt = titleTxt.rectTransform;
        titleRt.anchorMin = new Vector2(0, 1);
        titleRt.anchorMax = new Vector2(1, 1);
        titleRt.pivot = new Vector2(0.5f, 1);
        titleRt.sizeDelta = new Vector2(-60, 36);
        titleRt.anchoredPosition = new Vector2(0, -10);
        AddTextShadow(titleTxt);

        // Nút đóng X ở góc trên phải của popup
        var closeBtnGo = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        closeBtnGo.transform.SetParent(guideGo.transform, false);
        var cbImg = closeBtnGo.GetComponent<Image>();
        cbImg.color = new Color(0.85f, 0.25f, 0.25f, 0.95f);
        var cbRt = closeBtnGo.GetComponent<RectTransform>();
        cbRt.anchorMin = cbRt.anchorMax = cbRt.pivot = new Vector2(1f, 1f);
        cbRt.sizeDelta = new Vector2(30f, 30f);
        cbRt.anchoredPosition = new Vector2(-10f, -10f);
        closeBtnGo.GetComponent<Button>().onClick.AddListener(() => historyOverlayGo.SetActive(false));

        var closeTxt = new GameObject("Text", typeof(RectTransform), typeof(Text)).GetComponent<Text>();
        closeTxt.transform.SetParent(closeBtnGo.transform, false);
        closeTxt.font = font;
        closeTxt.fontSize = 15;
        closeTxt.fontStyle = FontStyle.Bold;
        closeTxt.text = "✕";
        closeTxt.color = Color.white;
        closeTxt.alignment = TextAnchor.MiddleCenter;
        Fill(closeTxt.rectTransform);

        // Scroll view chứa nội dung log lịch sử
        var descGo = new GameObject("GuideText", typeof(RectTransform), typeof(Text));
        dialogText = descGo.GetComponent<Text>();
        dialogText.font = font;
        dialogText.fontSize = 13;
        dialogText.color = new Color(0.92f, 0.95f, 1f, 1f);
        dialogText.lineSpacing = 1.35f;
        dialogText.text = "Chưa có hành động nào.";
        dialogText.alignment = TextAnchor.UpperLeft;
        dialogText.verticalOverflow = VerticalWrapMode.Overflow;
        var descRt = descGo.GetComponent<RectTransform>();
        descRt.anchorMin = new Vector2(0f, 1f);
        descRt.anchorMax = new Vector2(1f, 1f);
        descRt.pivot = new Vector2(0.5f, 1f);
        descRt.sizeDelta = new Vector2(0, 800);
        descRt.anchoredPosition = Vector2.zero;

        var scrollGo = new GameObject("HistoryScroll", typeof(RectTransform), typeof(ScrollRect), typeof(Image), typeof(Mask));
        scrollGo.transform.SetParent(guideGo.transform, false);
        var sImg = scrollGo.GetComponent<Image>();
        sImg.color = new Color(0.02f, 0.04f, 0.08f, 0.55f);
        var mask = scrollGo.GetComponent<Mask>();
        mask.showMaskGraphic = false;

        descGo.transform.SetParent(scrollGo.transform, false);
        var scrollRt = scrollGo.GetComponent<RectTransform>();
        scrollRt.anchorMin = Vector2.zero;
        scrollRt.anchorMax = Vector2.one;
        scrollRt.offsetMin = new Vector2(16, 16);
        scrollRt.offsetMax = new Vector2(-16, -50);
        historyScrollRect = scrollGo.GetComponent<ScrollRect>();
        historyScrollRect.horizontal = false;
        historyScrollRect.vertical = true;
        historyScrollRect.viewport = scrollRt;
        historyScrollRect.content = descRt;
    }

    private void SetLog(string text)
    {
        if (dialogText == null) return;
        actionHistory.Add(text);
        if (actionHistory.Count > 40) actionHistory.RemoveAt(0);
        dialogText.text = string.Join("\n", actionHistory);
        if (historyScrollRect != null)
        {
            Canvas.ForceUpdateCanvases();
            historyScrollRect.verticalNormalizedPosition = 0f;
        }
    }

    // Hoạt cảnh chia bài
    private IEnumerator AnimateDealtCard(bool toPlayer)
    {
        AudioManager.Instance.PlayCardDraw();

        var flyingGo = new GameObject("DealingCard", typeof(RectTransform), typeof(Image));
        flyingGo.transform.SetParent(transform, false);
        flyingGo.transform.SetAsLastSibling();
        var image = flyingGo.GetComponent<Image>();
        image.sprite = LotusHealthUI.LoadSpriteFromResources("UI/card_back_bg");
        image.type = Image.Type.Sliced;
        image.raycastTarget = false;

        var flyingRt = flyingGo.GetComponent<RectTransform>();
        flyingRt.anchorMin = flyingRt.anchorMax = flyingRt.pivot = new Vector2(0.5f, 0.5f);
        flyingRt.sizeDelta = new Vector2(58, 80);

        var rootRt = GetComponent<RectTransform>();
        Vector2 start;
        if (deckHudGo != null && deckHudGo.activeInHierarchy)
        {
            var sourceRt = deckHudGo.GetComponent<RectTransform>();
            Vector2 sourceScreen = RectTransformUtility.WorldToScreenPoint(null, sourceRt.position);
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, sourceScreen, null, out start);
        }
        else
        {
            start = new Vector2(rootRt.rect.width * 0.5f - 50f, rootRt.rect.height * 0.5f - 50f);
        }

        var targetRt = (toPlayer ? playerCard : bossCard).GetComponent<RectTransform>();
        Vector2 targetScreen = RectTransformUtility.WorldToScreenPoint(null, targetRt.position);
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, targetScreen, null, out var end);

        float elapsed = 0f;
        const float duration = 0.22f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / duration));
            flyingRt.anchoredPosition = Vector2.Lerp(start, end, t);
            flyingRt.localRotation = Quaternion.Euler(0, 0, Mathf.Lerp(-15f, 10f, t));
            yield return null;
        }
        Destroy(flyingGo);
    }

    private IEnumerator AnimateCardAppear(Transform cardTransform)
    {
        cardTransform.localScale = Vector3.zero;
        float elapsed = 0f;
        while (elapsed < 0.08f)
        {
            elapsed += Time.deltaTime;
            cardTransform.localScale = Vector3.one * Mathf.Clamp01(elapsed / 0.08f);
            yield return null;
        }
        cardTransform.localScale = Vector3.one;
    }

    // Hoạt cảnh tấn công bằng Trảm (Kích thước chuẩn 80%: 94x130, vị trí Vector2.zero ở giữa màn hình)
    private IEnumerator AnimateSlashAttack(CardModel card, GeneralCardUI target, Vector2 sourceScreenPosition, System.Action onComplete)
    {
        var usedCard = CardUI.Create(transform, card, new Vector2(94, 130));
        var rt = usedCard.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        var rootRt = GetComponent<RectTransform>();
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, sourceScreenPosition, null, out var start);
        rt.anchoredPosition = start;
        usedCard.transform.localScale = Vector3.one * 0.45f;

        float elapsed = 0f;
        const float flyDuration = 0.25f;
        while (elapsed < flyDuration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / flyDuration));
            rt.anchoredPosition = Vector2.Lerp(start, Vector2.zero, t);
            usedCard.transform.localScale = Vector3.one * Mathf.Lerp(0.45f, 1f, t);
            yield return null;
        }

        yield return new WaitForSeconds(0.15f);
        AudioManager.Instance.PlaySlash();
        AudioManager.Instance.PlayCardVoice(card);
        yield return AnimateAttackBeam(rt, target.GetComponent<RectTransform>());

        yield return new WaitForSeconds(0.2f);

        if (usedCard != null) Destroy(usedCard.gameObject);
        onComplete?.Invoke();
    }

    private IEnumerator AnimateBossCardToCenter(CardModel card)
    {
        AudioManager.Instance.PlayCardDraw();
        AudioManager.Instance.PlayCardVoice(card);
        var cardUI = CardUI.Create(transform, card, new Vector2(94, 130));
        bossIncomingCardGo = cardUI.gameObject;
        var rt = cardUI.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);

        var rootRt = GetComponent<RectTransform>();
        var bossRt = bossCard.GetComponent<RectTransform>();
        Vector2 bossScreen = RectTransformUtility.WorldToScreenPoint(null, bossRt.position);
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, bossScreen, null, out var start);

        rt.anchoredPosition = start;
        cardUI.transform.localScale = Vector3.one * 0.5f;

        float elapsed = 0f;
        const float duration = 0.3f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / duration));
            rt.anchoredPosition = Vector2.Lerp(start, Vector2.zero, t);
            cardUI.transform.localScale = Vector3.one * Mathf.Lerp(0.5f, 1f, t);
            yield return null;
        }
    }

    // Hoạt cảnh dùng Đỡ hóa giải Trảm
    private IEnumerator AnimateDodgeParry(CardModel dodgeCard, Vector2 sourceScreenPosition, System.Action onComplete)
    {
        var usedDodge = CardUI.Create(transform, dodgeCard, new Vector2(94, 130));
        var rt = usedDodge.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        var rootRt = GetComponent<RectTransform>();
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, sourceScreenPosition, null, out var start);
        rt.anchoredPosition = start;
        usedDodge.transform.localScale = Vector3.one * 0.5f;

        // Lá Đỡ bay lên va chạm với lá Trảm của Sơn Tặc ở chính giữa màn hình (Vector2.zero)
        float elapsed = 0f;
        const float flyDuration = 0.25f;
        while (elapsed < flyDuration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / flyDuration));
            rt.anchoredPosition = Vector2.Lerp(start, Vector2.zero, t);
            usedDodge.transform.localScale = Vector3.one * Mathf.Lerp(0.5f, 1.02f, t);
            yield return null;
        }

        // Kích hoạt âm thanh Keng Keng đỡ đòn!
        AudioManager.Instance.PlayParry();

        // Hiệu ứng phát sáng va chạm triệt tiêu
        yield return new WaitForSeconds(0.35f);

        if (bossIncomingCardGo != null) Destroy(bossIncomingCardGo);
        if (usedDodge != null) Destroy(usedDodge.gameObject);

        onComplete?.Invoke();
    }

    private IEnumerator AnimateAttackBeam(RectTransform source, RectTransform target)
    {
        var beamGo = new GameObject("SlashAttackBeam", typeof(RectTransform), typeof(Image));
        beamGo.transform.SetParent(transform, false);
        beamGo.transform.SetAsLastSibling();
        var beam = beamGo.GetComponent<Image>();
        beam.sprite = LotusHealthUI.LoadSpriteFromResources("UI/tutorial_arrow");
        beam.color = new Color(1f, 0.78f, 0.18f, 0.95f);
        beam.raycastTarget = false;
        var beamRt = beamGo.GetComponent<RectTransform>();
        beamRt.anchorMin = beamRt.anchorMax = new Vector2(0.5f, 0.5f);
        beamRt.pivot = new Vector2(0f, 0.5f);
        var rootRt = GetComponent<RectTransform>();
        Vector2 start = source.anchoredPosition;
        var targetAvatar = target.transform.Find("Avatar") as RectTransform;
        Vector3 targetWorld = target.position;
        if (targetAvatar != null)
            targetWorld = targetAvatar.TransformPoint(new Vector3(0f, targetAvatar.rect.height * 0.18f, 0f));
        var targetScreen = RectTransformUtility.WorldToScreenPoint(null, targetWorld);
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, targetScreen, null, out var end);
        Vector2 delta = end - start;
        beamRt.anchoredPosition = start;
        beamRt.sizeDelta = new Vector2(0, 28);
        beamRt.localRotation = Quaternion.Euler(0, 0, Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg);
        float elapsed = 0f;
        const float duration = 0.22f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            beamRt.sizeDelta = new Vector2(delta.magnitude * Mathf.Clamp01(elapsed / duration), 28);
            yield return null;
        }
        yield return new WaitForSeconds(0.12f);
        Destroy(beamGo);
    }

    /// <summary>
    /// Hiển thị lá bài đang được sử dụng ở chính giữa màn hình (Center of Battlefield, trùng với vị trí ra đòn).
    /// Kích thước bằng 80% lá bài bình thường (94x130).
    /// Bắn tia vàng nếu có mục tiêu. Tự động biến mất sau 2 giây (hoặc bị đè lên bởi lá bài mới).
    /// </summary>
    public void ShowCardAtCenter(CardModel card, GeneralCardUI caster, GeneralCardUI target = null, string customTag = null)
    {
        if (card == null) return;
        AudioManager.Instance.PlayCardVoice(card);

        // Nếu đang có coroutine đếm 2s của lá trước -> dừng lại
        if (centerCardDismissCoroutine != null)
        {
            StopCoroutine(centerCardDismissCoroutine);
            centerCardDismissCoroutine = null;
        }

        // Hủy lá bài cũ đang nằm ở giữa để lá mới đè lên
        if (currentCenterCardGo != null)
        {
            Destroy(currentCenterCardGo);
            currentCenterCardGo = null;
        }

        // Khởi tạo container lá bài trung tâm (Kích thước 80% lá bình thường: 94 x 130)
        var centerContainer = new GameObject("CenterPlayedCard", typeof(RectTransform), typeof(CanvasGroup));
        centerContainer.transform.SetParent(transform, false);
        centerContainer.transform.SetAsLastSibling();

        var rt = centerContainer.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(94, 130);
        rt.anchoredPosition = Vector2.zero; // Trùng khớp hoàn toàn với vị trí xuất chiêu ở giữa

        currentCenterCardGo = centerContainer;

        // Tạo CardUI đầy đủ (Kích thước 94x130)
        var cardUI = CardUI.Create(centerContainer.transform, card, new Vector2(94, 130));
        var cardRt = cardUI.GetComponent<RectTransform>();
        cardRt.anchorMin = Vector2.zero;
        cardRt.anchorMax = Vector2.one;
        cardRt.offsetMin = cardRt.offsetMax = Vector2.zero;

        // Thêm viền hào quang phát sáng
        var haloGo = new GameObject("CenterGlow", typeof(RectTransform), typeof(Image));
        haloGo.transform.SetParent(centerContainer.transform, false);
        haloGo.transform.SetAsFirstSibling();
        var haloImg = haloGo.GetComponent<Image>();
        haloImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        haloImg.color = new Color(1f, 0.88f, 0.35f, 0.9f);
        haloImg.raycastTarget = false;
        var hRt = haloGo.GetComponent<RectTransform>();
        Fill(hRt, new Vector2(-12, -12), new Vector2(12, 12));

        // Nhãn người vừa sử dụng hoặc thông báo bài bị hủy ở phía dưới
        if (!string.IsNullOrEmpty(customTag) || caster != null)
        {
            var font = ThemeUI.FontMain;
            var tagGo = new GameObject("CasterTag", typeof(RectTransform), typeof(Image));
            tagGo.transform.SetParent(centerContainer.transform, false);
            var tImg = tagGo.GetComponent<Image>();
            tImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
            tImg.type = Image.Type.Sliced;
            tImg.color = (caster == playerCard) ? new Color(0.15f, 0.45f, 0.85f, 0.95f) : new Color(0.85f, 0.25f, 0.15f, 0.95f);
            var tRt = tagGo.GetComponent<RectTransform>();
            tRt.anchorMin = new Vector2(0.5f, 0f);
            tRt.anchorMax = new Vector2(0.5f, 0f);
            tRt.pivot = new Vector2(0.5f, 1f);
            tRt.sizeDelta = new Vector2(160, 22);
            tRt.anchoredPosition = new Vector2(0, -4f);

            var tagTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
            tagTxtGo.transform.SetParent(tagGo.transform, false);
            var tTxt = tagTxtGo.GetComponent<Text>();
            tTxt.font = font;
            tTxt.fontSize = 10;
            tTxt.fontStyle = FontStyle.Bold;
            tTxt.alignment = TextAnchor.MiddleCenter;
            tTxt.color = Color.white;
            tTxt.text = !string.IsNullOrEmpty(customTag) ? customTag : $"{caster.GeneralName} vừa dùng";
            Fill(tagTxtGo.GetComponent<RectTransform>());
        }

        // Hiệu ứng scale pop-in
        StartCoroutine(AnimateCenterCardPopIn(centerContainer.transform));

        // Bắn tia vàng nếu có mục tiêu (tuyệt đối không bắn tia vào người dùng lá bài - caster)
        if (target != null && target != caster)
        {
            StartCoroutine(AnimateAttackBeam(rt, target.GetComponent<RectTransform>()));
        }

        // Đếm 2s rồi tự động mờ dần và biến mất (giữ đúng 2s giữa màn hình)
        centerCardDismissCoroutine = StartCoroutine(DismissCenterCardAfterDelay(centerContainer, 2.0f));
    }

    private IEnumerator AnimateCenterCardPopIn(Transform t)
    {
        if (t == null) yield break;
        t.localScale = Vector3.one * 0.7f;
        float elapsed = 0f;
        const float dur = 0.15f;
        while (elapsed < dur)
        {
            elapsed += Time.deltaTime;
            float s = Mathf.Lerp(0.7f, 1.05f, elapsed / dur);
            if (t != null) t.localScale = Vector3.one * s;
            yield return null;
        }
        if (t != null) t.localScale = Vector3.one;
    }

    private IEnumerator DismissCenterCardAfterDelay(GameObject cardGo, float delay)
    {
        yield return new WaitForSeconds(delay);
        if (cardGo == null) yield break;

        var cg = cardGo.GetComponent<CanvasGroup>();
        if (cg != null)
        {
            float elapsed = 0f;
            const float fadeDur = 0.25f;
            while (elapsed < fadeDur)
            {
                elapsed += Time.deltaTime;
                if (cg != null) cg.alpha = Mathf.Lerp(1f, 0f, elapsed / fadeDur);
                yield return null;
            }
        }

        if (cardGo == currentCenterCardGo)
        {
            currentCenterCardGo = null;
            centerCardDismissCoroutine = null;
        }
        Destroy(cardGo);
    }

    private IEnumerator AnimateDiscardFlying(Vector3 fromWorldPos)
    {
        AudioManager.Instance.PlayCardDiscard();
        var flyingGo = new GameObject("DiscardingCard", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        flyingGo.transform.SetParent(transform, false);
        flyingGo.transform.SetAsLastSibling();
        var image = flyingGo.GetComponent<Image>();
        var backSprite = LotusHealthUI.LoadSpriteFromResources("UI/card_back");
        if (backSprite != null)
        {
            image.sprite = backSprite;
            image.type = Image.Type.Sliced;
        }
        else
        {
            image.color = new Color(0.18f, 0.22f, 0.32f, 1f);
        }
        image.raycastTarget = false;

        var cg = flyingGo.GetComponent<CanvasGroup>();

        var flyingRt = flyingGo.GetComponent<RectTransform>();
        flyingRt.anchorMin = flyingRt.anchorMax = flyingRt.pivot = new Vector2(0.5f, 0.5f);
        flyingRt.sizeDelta = new Vector2(64, 88);

        var rootRt = GetComponent<RectTransform>();
        var sourceScreen = RectTransformUtility.WorldToScreenPoint(null, fromWorldPos);
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, sourceScreen, null, out var start);
        var end = new Vector2(0, 0); // Vùng trung tâm chiến trường (Khu Xấp Xả / Discard Area)

        float randomRot = UnityEngine.Random.Range(-35f, 35f);
        float elapsed = 0f;
        const float duration = 0.32f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.Clamp01(elapsed / duration);
            float ease = Mathf.SmoothStep(0f, 1f, t);
            flyingRt.anchoredPosition = Vector2.Lerp(start, end, ease);
            flyingRt.localScale = Vector3.one * Mathf.Lerp(1f, 0.55f, ease);
            flyingRt.localRotation = Quaternion.Euler(0, 0, Mathf.Lerp(0, randomRot, ease));
            if (cg != null) cg.alpha = Mathf.Lerp(1f, 0.15f, ease);
            yield return null;
        }
        Destroy(flyingGo);
    }

    private static void Fill(RectTransform rect, Vector2 offsetMin = default, Vector2 offsetMax = default)
    {
        rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.pivot = new Vector2(0.5f, 0.5f); rect.offsetMin = offsetMin; rect.offsetMax = offsetMax;
    }

    private static Image AddImage(Transform parent, string name, Color color)
    {
        var go = new GameObject(name, typeof(Image));
        go.transform.SetParent(parent, false);
        var img = go.GetComponent<Image>();
        img.color = color;
        return img;
    }

    private static void AddTextShadow(Text text)
    {
        var shadow = text.gameObject.AddComponent<Shadow>();
        shadow.effectColor = new Color(0, 0, 0, 0.95f);
        shadow.effectDistance = new Vector2(1.5f, -1.5f);
    }
    #endregion
}
