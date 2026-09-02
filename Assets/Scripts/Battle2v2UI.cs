using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

/// <summary>
/// Trình Điều Khiển Chiến Trường Đấu 2v2 Xếp Hạng Độc Lập (Đại Việt Chiến)
/// - Đồng bộ 100% đầy đủ 8 tính năng nâng cấp chuẩn thực chiến:
///   1. Mở Kho Cứu Tế chuẩn Tutorial (Modal hiển thị N lá bài, luân phiên từng người tự chọn 1 lá vào tay).
///   2. Dòng chú thích chuyển lên cao không che bài, Việt hóa toàn bộ chất & bậc số (♠ Bích 8, ♥ Cơ A (Át), ♣ Chuồn J (Bồi)...).
///   3. Thách Đấu do người chơi tự chọn lá Trảm trên tay để đáp trả (kèm bảng chọn [⚔️ ĐÁP TRẢ] / [❌ CHỊU MÁU]).
///   4. Mục tiêu đang chọn có khung viền dày 6px màu vàng Neon rực rỡ kèm huy hiệu [🎯 MỤC TIÊU ĐANG CHỌN].
///   5. Cận Tử (0 Máu) hỏi từng người theo vòng bắt đầu từ người gây sát thương; người tử trận bị xám tối toàn bộ thẻ bài [☠️ ĐÃ TỬ TRẬN].
///   6. Nút Kết Thúc Lượt chỉ hiện khi đang trong lượt ra bài của người chơi, ẩn hoàn toàn khi đang lượt người khác.
///   7. Chọn mượt mà 100% Trang Bị, Cẩm Nang Trì Hoãn và Bài Trên Tay trong Modal Vườn Không, Đột Kích, Diệu Kế.
///   8. Mục tiêu không lưu lại: mỗi lần dùng lá bài cần mục tiêu đều phải chạm chọn lại mục tiêu mới.
/// </summary>
public class Battle2v2UI : MonoBehaviour
    {
    private int lastProcessedActionSeq = 0;
    private List<GeneralCardUI> pendingDealTargets = new List<GeneralCardUI>();
    private List<int> pendingDealCounts = new List<int>();
    private List<List<CardModel>> pendingDealMyCards = new List<List<CardModel>>();

    public static Battle2v2UI Instance { get; private set; }

    [Header("UI Canvas & Layout")]
    private GameObject canvasGo;
    private CanvasScaler scaler;
    private Font font;

    [Header("Draft / Hero Pick Phase State")]
    private GameObject draftScreenGo;
    private Text draftTurnStatusText;
    private Text draftTimerText;
    private Image draftTimerFill;
    private float draftTimer = 40.0f;
    private bool isDraftTimerRunning = false;
    private int currentDraftPickerIndex = 0; // 0..3
    private HeroDatabase100.HeroData inspectingHero = null;
    private Button draftConfirmBtn;
    private Text draftConfirmBtnText;
    private GameObject draftInspectPanelGo;

    // Inspect Elements Cache
    private Text inspectTitleText;
    private Text inspectSubText;
    private Image inspectAvatarImg;
    private Text inspectSkillTitleText;
    private Text inspectSkillDescText;
    private Transform inspectLotusContainer;

    private readonly List<DraftSlot> draftSlots = new List<DraftSlot>();
    private readonly HashSet<int> selectedHeroIds = new HashSet<int>();
    private HashSet<int> weeklyFreeHeroIds = new HashSet<int>();
    private List<HeroDatabase100.HeroData> availableHeroes = new List<HeroDatabase100.HeroData>();
    private readonly Dictionary<int, GameObject> heroGridItems = new Dictionary<int, GameObject>();

    [System.Serializable]
    public class MatchmakingSlotInfo
    {
        public int seatNumber;
        public string userId;
        public string playerName;
        public bool isPlayer;
        public bool isAlly;
        public bool isDragon;
        public bool isAI;
        public int rankPoints;
    }

    private class DraftSlot
    {
        public int seatNumber;        // 1..4
        public string playerTitle;    // "BẠN", "ĐỒNG MINH", "ĐỐI THỦ 1", "ĐỐI THỦ 2"
        public string userId;
        public bool isPlayer;
        public bool isAlly;
        public bool isDragon;
        public bool isAI;
        public HeroDatabase100.HeroData chosenHero;
        public GameObject slotGo;
        public Text statusText;
        public Text heroNameText;
        public Image frameImg;
        public Image avatarImg;
    }

    [Header("Generals (4 Vị Trí Trận Đấu)")]
    private GeneralCardUI playerCard;     // Người chơi (Dưới Cùng Bên Phải)
    private GeneralCardUI allyCard;       // AI Đồng Đội (Đồng Minh)
    private GeneralCardUI enemy1Card;     // AI Địch 1 (Đối Thủ)
    private GeneralCardUI enemy2Card;     // AI Địch 2 (Đối Thủ)

    private readonly List<GeneralCardUI> allGenerals = new List<GeneralCardUI>();
    private readonly List<GeneralCardUI> turnOrderGenerals = new List<GeneralCardUI>();

    [Header("Hand Cards & Decks")]
    private CardDeckManager deckManager;
    private PlayerHandUI playerHandUI;
    private readonly List<CardModel> playerHandCards = new List<CardModel>();
    private readonly List<CardModel> allyHandCards = new List<CardModel>();
    private readonly List<CardModel> enemy1HandCards = new List<CardModel>();
    private readonly List<CardModel> enemy2HandCards = new List<CardModel>();

    [Header("Battle Turn & Timer State")]
    private int currentTurnIndex = 0; // 0..3 trong turnOrderGenerals
    private Coroutine currentTurnCoroutine = null;
    private bool isFirstTurnOfMatch = true;
    private float turnTimer = 40.0f;
    private bool isTimerRunning = false;
    private bool isDiscardPhaseActive = false;
    private int discardExcessRequired = 0;
    private readonly List<CardUI> selectedDiscardCards = new List<CardUI>();

    private GameObject battleRootGo;
    private Text globalTurnText;
    private Text logText;
    private GameObject historyOverlayGo;
    private ScrollRect historyScrollRect;
    private Text historyContentText;
    private readonly List<string> battleLogHistory = new List<string>();
    private Button endTurnBtn;
    private Text endTurnBtnText;
    private Button discardConfirmBtn;
    private Text discardConfirmBtnText;

    // Nút Dùng Bài Hành Động 2 Bước chuẩn Tutorial
    private GameObject actionBtnGo;
    private Text actionBtnText;
    private CardUI currentSelectedCardUI;

    // Hộp Mô Tả Chi Tiết Lá Bài Khi Chạm Chọn
    private GameObject cardDescBoxGo;
    private Text cardDescBodyText;

    [Header("Combat Modifiers & State")]
    private bool isWineBuffActive = false;
    private int slashesUsedThisTurn = 0;
    private bool isAwaitingSlashDefense = false;
    private bool playerPlayPhaseLocked = false;
    private bool playerDrawPhaseLocked = false;
    private bool isPlayerTurnActive = false;

    [Header("Draw Deck Pile HUD")]
    private GameObject deckHudGo;
    private Text deckInfoText;

    [Header("Center Presentation & Action")]
    private GameObject currentCenterCardGo;
    private Coroutine centerCardDismissCoroutine;
    private bool actionInProgress = false;
    private bool battleFinished = false;
    private bool isWaitingForTrieuDangTarget = false;
    private GeneralCardUI currentSelectedTarget = null;
    private GameObject targetHighlightGo;
    private GameObject activeCardPickModal = null;

    private Action onExitCallback;

    public enum TargetCardZone
    {
        Hand,
        Equipment,
        Delayed
    }

    public sealed class TargetCardOption
    {
        public CardModel Card;
        public TargetCardZone Zone;
        public EquipmentType EquipmentType;
        public CardSubType DelayedType;
        public string Label;
    }

    public enum SlashDefenseResult
    {
        Hit,
        Dodged,
        Negated
    }

    private static List<MatchmakingSlotInfo> pendingMatchedSlots = null;
    private static string pendingRoomId = null;
    private static bool pendingIsHost = true;

    private string currentRoomId;
    private bool isRoomHost = true;
    private readonly HashSet<long> processedActionTimestamps = new HashSet<long>();

    public static Battle2v2UI Create(Transform parent = null, Action onExit = null)
    {
        return CreateWithSlots(null, null, true, parent, onExit);
    }

    public static Battle2v2UI CreateWithSlots(List<MatchmakingSlotInfo> slots, Transform parent = null, Action onExit = null)
    {
        return CreateWithSlots(slots, null, true, parent, onExit);
    }

    public static Battle2v2UI CreateWithSlots(List<MatchmakingSlotInfo> slots, string roomId, bool isHost, Transform parent = null, Action onExit = null)
    {
        pendingMatchedSlots = slots;
        pendingRoomId = roomId;
        pendingIsHost = isHost;
        if (Instance != null)
        {
            Destroy(Instance.gameObject);
        }

        var go = new GameObject("Battle2v2UI", typeof(Battle2v2UI));
        if (parent != null) go.transform.SetParent(parent, false);
        var ui = go.GetComponent<Battle2v2UI>();
        ui.onExitCallback = onExit;
        return ui;
    }

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    private static void AutoInitInBattleScene()
    {
        var scene = SceneManager.GetActiveScene();
        if (scene.name == "Battle2v2Scene" && Instance == null)
        {
            Create();
        }
    }

    private void Awake()
    {
        Application.runInBackground = true;
        Instance = this;
        currentRoomId = pendingRoomId;
        isRoomHost = pendingIsHost;
    }

    private void OnEnable()
    {
        AppwriteRealtimeClient.OnServerGameStateReceived += HandleRealtimeServerGameState;
        DenoGameClient.OnGameStateUpdated += HandleDenoGameStateUpdated;
        DenoGameClient.OnErrorMessage += HandleDenoErrorMessage;
    }

    private void OnDisable()
    {
        AppwriteRealtimeClient.OnServerGameStateReceived -= HandleRealtimeServerGameState;
        DenoGameClient.OnGameStateUpdated -= HandleDenoGameStateUpdated;
        DenoGameClient.OnErrorMessage -= HandleDenoErrorMessage;
    }

    private void HandleDenoErrorMessage(string message)
    {
        if (string.IsNullOrEmpty(message)) return;
        isAwaitingSlashDefense = false;
        isAwaitingServerAoE = false;
        isAwaitingServerDuel = false;
        isAwaitingServerNearDeath = false;
        isAwaitingServerSongCung = false;
        isAwaitingServerNamSon = false;
        isDiscardPhaseActive = false;
        actionInProgress = false;
        lastHandledPhaseVersion = -1;
        lastHandledPromptKey = "";
        serverTargetCardSelectionInFlight = false;
        EnableServerTargetCardButtons(true);
        Debug.LogWarning($"[DenoGameClient] Server rejected action: {message}");
        SetLog($"⚠️ Máy chủ: {message}");
    }

    private void Start()
    {
        font = ThemeUI.FontMain;
        weeklyFreeHeroIds = HeroDatabase100.GetWeeklyFreeHeroIds();
        availableHeroes = HeroDatabase100.GetAvailablePickHeroes();

        deckManager = gameObject.AddComponent<CardDeckManager>();
        int roomSeed = string.IsNullOrEmpty(currentRoomId) ? 0 : AppwriteMatchmaking.GetDeterministicHashCode(currentRoomId);
        deckManager.InitializeDeck(80, roomSeed);

        BuildMainCanvas();
        StartCoroutine(StartDraftPhaseSequence());
    }

    private void Update()
    {
        if (battleFinished) return;

        // Đếm giờ chọn tướng (Draft Phase - chỉ cập nhật thanh hiển thị)
        if (isDraftTimerRunning && draftTimer > 0f)
        {
            if (isRoomHost)
            {
                draftTimer -= Time.unscaledDeltaTime;
            }
            UpdateDraftTimerVisual();
        }

        // Bỏ return ở đây để Client tự tính được turnTimer kể cả khi chơi Online
        // Đếm giờ trong trận đấu (Battle Phase)
        if (isTimerRunning && turnTimer > 0f)
        {
            turnTimer -= Time.unscaledDeltaTime;

            // Cập nhật timer trên các modal đang mở (nếu có)
            string[] modalNames = { "CounterPromptModal", "CounterWaitingModal", "AoEPromptModal", "DuelPromptModal", "SlashDefensePromptModal", "NearDeathPromptModal", "RescueAllyPromptModal", "SongCungPromptModal", "NamSonPromptModal", "DiscardModal", "HarvestModal" };
            foreach (var mName in modalNames) {
                var mGo = GameObject.Find(mName);
                if (mGo != null) {
                    var tTxt = mGo.transform.Find("Timer")?.GetComponent<UnityEngine.UI.Text>();
                    if (tTxt != null) {
                        if (tTxt.text.Contains("Còn")) {
                            tTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(turnTimer))}s để quyết định...";
                        } else if (tTxt.text.Contains("chờ phản hồi")) {
                            tTxt.text = $"⏳ Đang chờ phản hồi ({Mathf.Max(0, Mathf.CeilToInt(turnTimer))}s)...";
                        }
                    }
                }
            }

                        var activeGen = GetGeneralBySeat(currentAuthoritativeTurnSeat);
            var waitingGen = currentAuthoritativeWaitingSeat > 0 ? GetGeneralBySeat(currentAuthoritativeWaitingSeat) : null;
            {
                if (waitingGen != null && waitingGen.CurrentHp > 0)
                {
                    waitingGen.UpdateHeadTimer(Mathf.CeilToInt(turnTimer));
                }
                else if (activeGen != null && activeGen.CurrentHp > 0)
                {
                    activeGen.UpdateHeadTimer(Mathf.CeilToInt(turnTimer));
                }
                else if (turnOrderGenerals.Count > currentTurnIndex)
                {
                    activeGen = turnOrderGenerals[currentTurnIndex];
                    if (activeGen != null)
                    {
                        activeGen.UpdateHeadTimer(Mathf.CeilToInt(turnTimer));
                    }
                }
            }

            if (turnTimer <= 0f)
            {
                turnTimer = 0f;
                OnTimerExpired();
            }
        }
    }

    public void PauseTurnTimer()
    {
        isTimerRunning = false;
        if (turnOrderGenerals != null && currentTurnIndex >= 0 && currentTurnIndex < turnOrderGenerals.Count)
        {
            var activeGen = turnOrderGenerals[currentTurnIndex];
            if (activeGen != null) activeGen.HideHeadTimer();
        }
    }

    public void ResumeTurnTimer()
    {
        if (!battleFinished && !isDiscardPhaseActive)
        {
            isTimerRunning = true;
            // Dùng turnSeat từ server nếu có, thay vì currentTurnIndex cục bộ dễ lệch
            var activeGen = GetGeneralBySeat(currentAuthoritativeTurnSeat);
            if (activeGen != null && activeGen.CurrentHp > 0)
            {
                activeGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
            }
            else if (turnOrderGenerals != null && currentTurnIndex >= 0 && currentTurnIndex < turnOrderGenerals.Count)
            {
                activeGen = turnOrderGenerals[currentTurnIndex];
                if (activeGen != null && activeGen.CurrentHp > 0)
                {
                    activeGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
                }
            }
        }
    }

    #region SERVERLESS GAME STATE SYNCHRONIZER
    private long lastAppliedStateVersion = -1;
    private long lastAppliedActionSeq = 0;
    private long lastHandledPhaseVersion = -1;
    private int lastHandledWaitingSeat = -1;
    private string lastHandledPromptKey = "";
    private Coroutine gameStateSyncCoroutine = null;
    private Coroutine activeCounterPromptCoroutine = null;
    private bool isAwaitingServerAoE = false;
    private bool isAwaitingServerDuel = false;
    private bool isAwaitingServerNearDeath = false;
    private bool isAwaitingServerSongCung = false;
    private bool isAwaitingServerNamSon = false;
    private string currentAuthoritativePhase = "";
    private int currentAuthoritativeWaitingSeat = 0;
    private int currentAuthoritativeTurnSeat = 0;
    private GameObject activeServerTargetCardModal = null;
    private long lastServerTargetCardPromptVersion = -1;
    private string lastServerTargetCardPromptKey = "";
    private bool serverTargetCardSelectionInFlight = false;

    private void StartGameStateSync()
    {
        if (gameStateSyncCoroutine != null) StopCoroutine(gameStateSyncCoroutine);
        if (!string.IsNullOrEmpty(currentRoomId))
        {
            gameStateSyncCoroutine = StartCoroutine(SyncServerGameStateLoop());
        }
    }

    private void HandleRealtimeServerGameState(AppwriteMatchmaking.ServerGameState state)
    {
        if (state == null) return;
        if (!string.IsNullOrEmpty(currentRoomId) && state.roomId != currentRoomId) return;
        if (!string.IsNullOrEmpty(currentRoomId)) return;

        if (state.version > lastAppliedStateVersion)
        {
            ApplyServerGameState(state);
        }
    }

    private void HandleDenoGameStateUpdated(AppwriteMatchmaking.ServerGameState state, AppwriteMatchmaking.GameStateDelta delta)
    {
        pendingDealTargets.Clear();
        pendingDealCounts.Clear();
        pendingDealMyCards.Clear();
        // A cancelled reconnect can still deliver one queued snapshot from
        // the previous room. Never let that packet mutate this battle UI.
        if (state != null && !string.IsNullOrEmpty(currentRoomId)
            && !string.Equals(state.roomId, currentRoomId, StringComparison.Ordinal))
        {
            return;
        }

        if (delta != null && delta.version >= lastAppliedStateVersion)
        {
            ApplyServerStateDelta(delta);
        }

        if (state != null && state.version >= lastAppliedStateVersion)
        {
            if (delta != null) state.delta = delta;
            ApplyServerGameState(state);
        }
    }

    private void DispatchGameEngineAction(AppwriteMatchmaking.GameActionPayload actionPayload, Action<AppwriteMatchmaking.ServerGameState> onFallbackResult = null)
    {
        if (actionPayload == null) return;
        if (!string.IsNullOrEmpty(currentRoomId) && DenoGameClient.IsConnected)
        {
            DenoGameClient.Instance.SendGameAction(actionPayload);
        }
        else
        {
            if (!string.IsNullOrEmpty(currentRoomId))
                Debug.LogWarning("[Battle2v2UI] DenoGameClient chưa kết nối; dùng REST authoritative fallback.");
            StartCoroutine(AppwriteMatchmaking.ExecuteGameEngineAction(actionPayload, onFallbackResult));
        }

    }
    
    private IEnumerator GlobalDealRoutine(List<GeneralCardUI> targets, List<int> counts, List<List<CardModel>> newCardsList) {
        int maxCount = 0;
        foreach (var c in counts) if (c > maxCount) maxCount = c;
        
        for (int i = 0; i < maxCount; i++) {
            for (int t = 0; t < targets.Count; t++) {
                if (i < counts[t]) {
                    var target = targets[t];
                    yield return AnimateDealtCard(target);
                    if (target == playerCard && newCardsList[t] != null && i < newCardsList[t].Count) {
                        playerHandUI.AddCard(newCardsList[t][i]);
                        UpdateHandCountsVisual();
                    }
                }
            }
        }
    }

    private void ApplyServerStateDelta(AppwriteMatchmaking.GameStateDelta delta)
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
        }

        // 1. Cập nhật vi phân Máu, Wine Buff & Số bài trên tay
        if (delta.playerDeltas != null)
        {
            foreach (var p in delta.playerDeltas)
            {
                var g = GetGeneralBySeat(p.seat);
                if (g != null)
                {
                    int maxHp = p.maxHp > 0 ? p.maxHp : g.MaxHp;
                    
                    if (p.hp < g.CurrentHp) {
                          int dmg = g.CurrentHp - p.hp;
                          AudioManager.Instance.PlayDamage();
                          StartCoroutine(ShakeCard(g));
                          StartCoroutine(ShowFloatingDamage(g, dmg));
                      }
                    g.SetHealth(p.hp, maxHp);
                    bool pendingDeath = string.Equals(delta.phase, "AWAIT_NEAR_DEATH", StringComparison.Ordinal)
                        && delta.nearDeathVictimSeat == p.seat;
                    g.SetDeadVisual(p.hp <= 0 && !pendingDeath);
                    g.IsWineBuffActive = p.isWineBuffActive;
                    ApplyServerLoadout(g, new AppwriteMatchmaking.GameStatePlayer
                    {
                        seat = p.seat,
                        hp = p.hp,
                        maxHp = maxHp,
                        aoBaoCharges = p.aoBaoCharges,
                        equipments = p.equipments,
                        judgements = p.judgements,
                        activeSkillsKeys = p.activeSkillsKeys,
                        usedSkillsKeys = p.usedSkillsKeys,
                        usedSkillsValues = p.usedSkillsValues,
                        activeSkillsValues = p.activeSkillsValues
                    });
                    
                    g.ActiveSkillsKeys = p.activeSkillsKeys;
                    g.UsedSkillsKeys = p.usedSkillsKeys;
                    g.UsedSkillsValues = p.usedSkillsValues;
                    g.ActiveSkillsValues = p.activeSkillsValues;
                    if (g == playerCard) {
                        UpdatePlayerSkillButtonState();
                    }

                    if (g != playerCard && p.handCount >= 0)
                    {
                        var hand = GetHandOfGeneral(g);
                        int newCards = p.handCount - hand.Count;
                        if (newCards > 0) {
                            pendingDealTargets.Add(g);
                            pendingDealCounts.Add(newCards);
                            pendingDealMyCards.Add(null);
                            for (int i = 0; i < newCards; i++) {
                                hand.Add(new CardModel { id = "HIDDEN", cardName = "Ẩn" });
                            }
                        }
                        while (hand.Count > p.handCount && hand.Count > 0) hand.RemoveAt(0);
                    }
                }
            }
            UpdateHandCountsVisual();
            if (string.Equals(delta.status, "FINISHED", StringComparison.Ordinal))
            {
                ApplyAuthoritativeGameFinished();
            }
        }
        


        // 2. Cập nhật Head Timers
        if (delta.waitingTargetSeat > 0)
        {
            var targetGen = GetGeneralBySeat(delta.waitingTargetSeat);
            if (targetGen != null && targetGen.CurrentHp > 0)
            {
                turnTimer = delta.waitingTimer > 0 ? delta.waitingTimer : 40.0f;
                isTimerRunning = true;
                if (currentAuthoritativePhase != "AWAIT_NULLIFY" && currentAuthoritativePhase != "AWAIT_JUDGEMENT") targetGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
            }
            var casterGen = GetGeneralBySeat(delta.turnSeat);
            if (casterGen != null && casterGen != targetGen)
            {
                casterGen.HideHeadTimer();
            }
        }
        else if (delta.turnSeat > 0)
        {
            var turnGen = GetGeneralBySeat(delta.turnSeat);
            if (turnGen != null && turnGen.CurrentHp > 0)
            {
                turnTimer = delta.turnTimer > 0 ? delta.turnTimer : 40.0f;
                isTimerRunning = true;
                if (currentAuthoritativePhase != "AWAIT_JUDGEMENT") turnGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
            }
            for (int s = 1; s <= 4; s++)
            {
                if (s != delta.turnSeat)
                {
                    var other = GetGeneralBySeat(s);
                    if (other != null) other.HideHeadTimer();
                }
            }
        }

        // 3. Nhật ký trận đấu vi phân
        if (!string.IsNullOrEmpty(delta.description))
        {
            SetLog(delta.description);
        }

        var promptState = new AppwriteMatchmaking.ServerGameState
        {
            version = delta.version,
            roomId = currentRoomId,
            status = delta.status ?? "PLAYING",
            turnSeat = delta.turnSeat,
            phase = delta.phase,
            turnTimer = delta.turnTimer > 0 ? delta.turnTimer : 40,
            waitingTargetSeat = delta.waitingTargetSeat,
            waitingReactionType = delta.waitingReactionType,
            waitingTimer = delta.waitingTimer,
            nearDeathVictimSeat = delta.nearDeathVictimSeat,
            nearDeathAskerQueue = delta.nearDeathAskerQueue,
            aoeVictimsQueue = delta.aoeVictimsQueue,
            harvestPickers = delta.harvestPickers,
            slashesUsedThisTurn = delta.slashesUsedThisTurn,
            activeCard = delta.activeCard,
            nullifyChain = delta.nullifyChain,
            targetCardSelection = delta.targetCardSelection,
            harvestPool = delta.harvestPool
        };
        HandleServerPhasePrompt(promptState);
    }

    private IEnumerator SyncServerGameStateLoop()
    {
        while (!battleFinished)
        {
            if (DenoGameClient.IsConnected)
            {
                // Khi Deno WebSocket kết nối trực tiếp trên RAM, tạm dừng poll Appwrite REST để tránh xung đột dữ liệu
                yield return new WaitForSeconds(2.0f);
                continue;
            }

            if (!string.IsNullOrEmpty(currentRoomId))
            {
                yield return AppwriteMatchmaking.PollServerGameState(currentRoomId, (serverState) =>
                {
                    if (serverState != null && serverState.version > lastAppliedStateVersion)
                    {
                        ApplyServerGameState(serverState);
                    }
                }, playerCard != null ? playerCard.SeatNumber : 1);
            }
            yield return new WaitForSeconds(AppwriteRealtimeClient.IsConnected ? 2.5f : 0.4f);
        }
    }

    public static string GetDefaultCardDescription(CardSubType subType, string cardName = "")
    {
        switch (subType)
        {
            case CardSubType.AttackNormal:
                return "Tấn công 1 mục tiêu trong tầm đánh. Đối phương phải Đỡ hoặc mất 1 máu.";
            case CardSubType.AttackFire:
                return "Tấn công 1 sát thương Hỏa. Lan truyền khi mục tiêu bị Xích Liên Hoàn.";
            case CardSubType.AttackThunder:
                return "Tấn công gây 1 sát thương Lôi trong tầm đánh.";
            case CardSubType.Dodge:
                return "Hóa giải hoàn toàn 1 đòn Trảm đánh vào bản thân.";
            case CardSubType.Peach:
                return "Hồi phục 1 Máu cho bản thân HOẶC cứu bất kỳ người chơi nào vừa rơi vào trạng thái Cận Tử.";
            case CardSubType.Wine:
                return "Dùng trước khi Trảm: Trúng đòn gây +1 sát thương HOẶC tự cứu khi 0 máu.";
            case CardSubType.FlawlessDefense:
                return "Vô hiệu hóa 1 Cẩm Nang bất kỳ vừa đánh ra HOẶC hủy 1 lá bài bất kỳ.";
            case CardSubType.Dismantle:
                return "Người tấn công chọn 1 mục tiêu, rồi chọn 1 lá trên tay hoặc 1 trang bị của mục tiêu để hủy.";
            case CardSubType.Snatch:
                return "Cướp 1 lá bài trên tay, vùng trang bị hoặc vùng trì hoãn của mục tiêu cự ly 1.";
            case CardSubType.ExNihilo:
                return "Đánh ra để rút ngay 2 lá bài từ kho bài rút.";
            case CardSubType.Duel:
                return "Quyết đấu với 1 người. Luân phiên ra Trảm, bên nào không ra được chịu 1 sát thương.";
            case CardSubType.Harvest:
                return "Lật số lá bằng số người còn sống, mỗi người luân phiên chọn lấy 1 lá.";
            case CardSubType.BarbarianInvasion:
                return "Diện rộng. Từng người chơi khác trên bàn (trừ người dùng) phải đánh ra 1 Trảm HOẶC chịu 1 sát thương.";
            case CardSubType.ArrowRain:
                return "Diện rộng. Từng người chơi khác trên bàn (trừ người dùng) phải đánh ra 1 Đỡ HOẶC chịu 1 sát thương.";
            case CardSubType.Lightning:
                return "Gài vào vùng phán xét. Đến lượt người đang giữ, lật bài: Bích 2-9 chịu 3 sát thương Lôi; ngược lại chuyển sang người kế tiếp.";
            case CardSubType.SupplyShortage:
                return "Chỉ gài mục tiêu cự ly 1. Trì hoãn: nếu phán xét KHÔNG PHẢI Chuồn (♣) -> Bỏ qua Giai đoạn Rút bài.";
            case CardSubType.Acedia:
                return "Trì hoãn. Kiểm tra: nếu KHÔNG PHẢI Cơ (♥) -> Bỏ qua Giai đoạn Ra bài.";
            case CardSubType.Weapon:
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Nỏ Thần")) return "Tầm 1. Bỏ giới hạn lượt: Có thể ra không giới hạn số lá Trảm trong cùng một lượt.";
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Kiếm Thuận Thiên")) return "Tầm 2. Thanh bảo kiếm hộ quốc của Bình Định Vương.";
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Song Cung")) return "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài trên tay ép mục tiêu mất 1 máu.";
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Trường Đao")) return "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 Trảm ép đối phương phải Đỡ thêm lần nữa.";
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Súng Thần Công")) return "Tầm 5. Mục tiêu không được dùng Đỡ có cùng chất với Trảm của bạn.";
                return "Trang bị vũ khí tăng tầm đánh và kích hoạt kỹ năng đặc biệt.";
            case CardSubType.Armor:
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Giáp Đồng")) return "Áo giáp. Vô hiệu hóa toàn bộ Trảm Thường (không mang thuộc tính Hỏa/Lôi).";
                if (!string.IsNullOrEmpty(cardName) && cardName.Contains("Khiên Mây")) return "Áo giáp (Bát Quái). Khi cần Đỡ, lật bài phán xét: nếu chất ĐỎ (♥, ♦) coi như đã Đỡ.";
                return "Trang bị phòng thủ giảm hoặc vô hiệu hóa sát thương.";
            case CardSubType.OffensiveHorse:
                return "Giảm -1 khoảng cách từ bạn tới tất cả người chơi khác (Ngựa công).";
            case CardSubType.DefensiveHorse:
                return "Tăng +1 khoảng cách từ người khác tới bạn (Ngựa thủ phòng ngự).";
            default:
                return "Thẻ bài trong Đại Việt Chiến.";
        }
    }

    public static string GetDefaultIconPath(CardSubType subType)
    {
        switch (subType)
        {
            case CardSubType.AttackNormal: return "UI/icon_slash";
            case CardSubType.AttackFire: return "UI/icon_slash_fire";
            case CardSubType.AttackThunder: return "UI/icon_slash_thunder";
            case CardSubType.Dodge: return "UI/icon_dodge";
            case CardSubType.Peach: return "UI/icon_banh_chung";
            case CardSubType.Wine: return "UI/icon_wine";
            case CardSubType.FlawlessDefense: return "UI/icon_flawless";
            case CardSubType.Dismantle: return "UI/icon_dismantle";
            case CardSubType.Snatch: return "UI/icon_snatch";
            case CardSubType.ExNihilo: return "UI/icon_ex_nihilo";
            case CardSubType.Duel: return "UI/icon_duel";
            case CardSubType.Harvest: return "UI/icon_harvest";
            case CardSubType.BarbarianInvasion: return "UI/icon_barbarian";
            case CardSubType.ArrowRain: return "UI/icon_arrow_rain";
            case CardSubType.Lightning: return "UI/icon_lightning";
            case CardSubType.SupplyShortage: return "UI/icon_supply_shortage";
            case CardSubType.Acedia: return "UI/icon_acedia";
            case CardSubType.Weapon: return "UI/icon_weapon";
            case CardSubType.Armor: return "UI/icon_armor";
            case CardSubType.OffensiveHorse: return "UI/icon_mount_offense";
            case CardSubType.DefensiveHorse: return "UI/icon_mount_defense";
            default: return "";
        }
    }

    private CardModel ConvertGameStateCardToCardModel(AppwriteMatchmaking.GameStateCard sc)
    {
        if (sc == null || sc.id == "HIDDEN") return null;
        var cm = CardDatabase.GetCardById(sc.id);
        if (cm != null)
        {
            if (string.IsNullOrEmpty(cm.description))
            {
                cm.description = !string.IsNullOrEmpty(sc.desc) ? sc.desc : GetDefaultCardDescription(cm.subType, cm.cardName);
            }
            if (string.IsNullOrEmpty(cm.iconPath))
            {
                cm.iconPath = GetDefaultIconPath(cm.subType);
            }
                        if (playerCard != null && playerCard.HeroId == "1") {
                bool isCheNo = playerCard.IsSkillActive("Chế Nỏ");
                if (isCheNo && cm.suit == CardSuit.Spade && cm.subType != CardSubType.Weapon) {
                    return new CardModel { 
                        id = cm.id, 
                        cardName = "Nỏ Thần Kim Quy", 
                        suit = cm.suit, 
                        rank = cm.rank, 
                        subType = CardSubType.Weapon, 
                        category = CardCategory.Equipment, 
                        iconPath = "UI/icon_weapon", 
                        description = "Tầm 1. Không giới hạn số Trảm trong lượt" 
                    };
                }
            }
            return cm;
        }

        CardSuit suit = CardSuit.Spade;
        if (!string.IsNullOrEmpty(sc.suit))
        {
            Enum.TryParse(sc.suit, true, out suit);
        }

        var subType = (CardSubType)sc.subType;
        string desc = !string.IsNullOrEmpty(sc.desc) ? sc.desc : GetDefaultCardDescription(subType, sc.name);
        string icon = GetDefaultIconPath(subType);

        return CardDatabase.CreateCard(
            sc.id,
            sc.name,
            suit,
            (CardRank)sc.rank,
            1,
            (CardCategory)sc.category,
            subType,
            desc,
            icon,
            sc.attackRange > 0 ? sc.attackRange : (sc.range > 0 ? sc.range : 1),
            sc.distMod
        );
    }

    // The Unity catalogue uses numeric hero IDs, while the authoritative
    // Deno engine addresses its supported heroes by stable string slugs.
    private static string NormalizeHeroKey(string value)
    {
        if (string.IsNullOrWhiteSpace(value)) return string.Empty;

        string decomposed = value.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(decomposed.Length);
        foreach (char c in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                builder.Append(c);
        }

        return builder.ToString()
            .Normalize(NormalizationForm.FormC)
            .ToUpperInvariant()
            .Replace('Đ', 'D')
            .Replace('Ð', 'D')
            .Replace('_', ' ');
    }

    private static string ToDenoHeroSlug(HeroDatabase100.HeroData hero)
    {
        if (hero == null) return string.Empty;

        switch (hero.id)
        {
            case 47: return "LY_THUONG_KIET";
            case 53: return "TRAN_HUNG_DAO"; // Unity catalogue alias for Trần Hưng Đạo
            case 56: return "TRAN_QUOC_TOAN";
            case 86: return "LE_LOI";
            case 87: return "NGUYEN_TRAI";
        }

        return $"HERO_{hero.id}";
    }

    private static string GetDenoHeroId(string generalName)
    {
        string key = NormalizeHeroKey(generalName);
        if (key.Contains("NGUYEN HUE")) return "NGUYEN_HUE";
        if (key.Contains("TRAN HUNG DAO") || key.Contains("TRAN QUOC TUAN")) return "TRAN_HUNG_DAO";
        if (key.Contains("LY THUONG KIET")) return "LY_THUONG_KIET";
        if (key.Contains("TRAN QUOC TOAN")) return "TRAN_QUOC_TOAN";
        if (key.Contains("LE LOI")) return "LE_LOI";
        if (key.Contains("NGUYEN TRAI")) return "NGUYEN_TRAI";

        // Resolve catalogue aliases only after checking the explicit server
        // names, and verify the returned name. GetHeroByName intentionally
        // falls back to a default hero for misses, so never trust that
        // fallback as an implicit match.
        var resolved = string.IsNullOrWhiteSpace(generalName)
            ? null
            : HeroDatabase100.GetHeroByName(generalName);
        if (resolved != null && key.Contains(NormalizeHeroKey(resolved.name)))
            return ToDenoHeroSlug(resolved);

        // As a final catalogue fallback, match only an entry that is present
        // in the supplied display name; this avoids accidental defaulting.
        foreach (var candidate in HeroDatabase100.AllHeroes)
        {
            if (candidate == null) continue;
            string candidateKey = NormalizeHeroKey(candidate.name);
            if (!string.IsNullOrEmpty(candidateKey) && key.Contains(candidateKey))
                return ToDenoHeroSlug(candidate);
        }

        // An empty value makes the server apply its explicit default instead
        // of misinterpreting a Unity-only numeric ID as a different hero.
        return string.Empty;
    }

    private void ApplyServerGameState(AppwriteMatchmaking.ServerGameState state)
    {
        if (state == null) return;
        if (!string.IsNullOrEmpty(currentRoomId)
            && !string.Equals(state.roomId, currentRoomId, StringComparison.Ordinal)) return;
        
        // Cập nhật lại số timer để tránh bị lệch, nhưng NẾU là phiên bản cũ thì đừng cày lại timer từ đầu (tránh reset đồng hồ liên tục)
        if (state.version <= lastAppliedStateVersion && state.version > 0) 
        {
            return;
        }
        lastAppliedStateVersion = state.version;
        currentAuthoritativePhase = state.phase ?? "";
        currentAuthoritativeWaitingSeat = state.waitingTargetSeat;
        currentAuthoritativeTurnSeat = state.turnSeat;
        actionInProgress = false;

        // 1. Đồng bộ Máu 4 Tướng & Trạng thái sống/chết tuyệt đối
        if (state.players != null)
        {
            foreach (var p in state.players)
            {
                var g = GetGeneralBySeat(p.seat);
                if (g != null)
                {
                    
                    if (p.hp < g.CurrentHp) {
                          int dmg = g.CurrentHp - p.hp;
                          AudioManager.Instance.PlayDamage();
                          StartCoroutine(ShakeCard(g));
                          StartCoroutine(ShowFloatingDamage(g, dmg));
                      }
                    g.SetHealth(p.hp, p.maxHp);
                    bool pendingDeath = string.Equals(state.phase, "AWAIT_NEAR_DEATH", StringComparison.Ordinal)
                        && state.nearDeathVictimSeat == p.seat;
                    g.SetDeadVisual(p.hp <= 0 && !pendingDeath);
                    g.IsWineBuffActive = p.isWineBuffActive;
                    ApplyServerLoadout(g, p);
                    g.ActiveSkillsKeys = p.activeSkillsKeys;
                    g.UsedSkillsKeys = p.usedSkillsKeys;
                    g.UsedSkillsValues = p.usedSkillsValues;
                    g.ActiveSkillsValues = p.activeSkillsValues;
                    if (g == playerCard) {
                        UpdatePlayerSkillButtonState();
                    }
                }
            }
            if (string.Equals(state.status, "FINISHED", StringComparison.Ordinal))
            {
                ApplyAuthoritativeGameFinished();
            }
        }

        // 2. Đồng bộ Danh sách Bài Thật trên tay của chính mình từ Server (Authoritative Hand)
        if (state.players != null && playerCard != null)
        {
            var myServerData = state.players.Find(p => p.seat == playerCard.SeatNumber);
            if (myServerData != null && myServerData.hand != null)
            {
                var newCards = new System.Collections.Generic.List<CardModel>();
                foreach (var sc in myServerData.hand)
                {
                    if (sc != null && sc.id != "HIDDEN")
                    {
                        var cm = ConvertGameStateCardToCardModel(sc);
                        if (cm != null) newCards.Add(cm);
                    }
                }

                bool handChanged = playerHandCards.Count != newCards.Count;
                if (!handChanged)
                {
                    for (int i = 0; i < playerHandCards.Count; i++)
                    {
                        if (playerHandCards[i].id != newCards[i].id)
                        {
                            handChanged = true;
                            break;
                        }
                    }
                }

                if (handChanged)
                {
                    playerHandCards.Clear();
                    playerHandCards.AddRange(newCards);
                    if (playerHandUI != null)
                    {
                        playerHandUI.ClearHand();
                        playerHandUI.AddCards(playerHandCards);
                    }
                }
            }
        }

        if (state.deckCount >= 0)
        {
            UpdateDeckHUD(state.deckCount, state.discardCount);
        }

        // 3. Đồng bộ số lượng bài trên tay của các đối thủ (Card Backs)
        if (state.players != null)
        {
            foreach (var p in state.players)
            {
                var g = GetGeneralBySeat(p.seat);
                if (g != null && g != playerCard)
                {
                    var hand = GetHandOfGeneral(g);
                    if (hand.Count != p.handCount)
                    {
                        hand.Clear();
                        for (int i = 0; i < p.handCount; i++)
                        {
                            hand.Add(new CardModel { id = "HIDDEN", cardName = "Ẩn" });
                        }
                    }
                }
            }
            UpdateHandCountsVisual();
        }

        // 4. Đồng bộ Lượt đánh Authoritative, Vòng sáng Tướng và Bộ đếm thời gian từ Server
        if (state.waitingTargetSeat > 0)
        {
            var targetGen = GetGeneralBySeat(state.waitingTargetSeat);
            if (targetGen != null && targetGen.CurrentHp > 0)
            {
                turnTimer = state.waitingTimer > 0 ? state.waitingTimer : 40.0f;
                isTimerRunning = true;
                
                // Show timer on the waiting target
                if (currentAuthoritativePhase != "AWAIT_NULLIFY" && currentAuthoritativePhase != "AWAIT_JUDGEMENT") targetGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
            }
            
            // Xoá timer của tất cả những người không liên quan
            for (int s = 1; s <= 4; s++)
            {
                if (s != state.waitingTargetSeat)
                {
                    var other = GetGeneralBySeat(s);
                    if (other != null) other.HideHeadTimer();
                }
            }
        }
        else if (state.turnSeat > 0 && !battleFinished)
        {
            var turnGen = GetGeneralBySeat(state.turnSeat);
            if (turnGen != null && turnGen.CurrentHp > 0)
            {
                turnTimer = state.turnTimer > 0 ? state.turnTimer : 40.0f;
                isTimerRunning = true;
                if (currentAuthoritativePhase != "AWAIT_JUDGEMENT") turnGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
            }
            for (int s = 1; s <= 4; s++)
            {
                if (s != state.turnSeat)
                {
                    var other = GetGeneralBySeat(s);
                    if (other != null) other.HideHeadTimer();
                }
            }

            if (allGenerals != null)
            {
                foreach (var g in allGenerals)
                {
                    if (g != null) g.SetTurnActive(g.SeatNumber == state.turnSeat);
                }
            }

            if (turnGen != null && globalTurnText != null)
            {
                string teamLabel = turnGen.IsAlly ? "<color=#55DDFF>[ĐỒNG MINH]</color>" : "<color=#FF5555>[ĐỐI THỦ]</color>";
                globalTurnText.text = $"LƯỢT #{turnGen.SeatNumber}: {teamLabel} {turnGen.GeneralName}";
            }
        }

        // 5. Đồng bộ Nhật ký trận đấu
        if (state.actionHistory != null && state.actionHistory.Count > 0)
        {
            // Duyệt qua tất cả các action mới chưa xử lý
            foreach (var act in state.actionHistory)
            {
                if (act.timestamp > lastAppliedActionSeq)
                {
                    lastAppliedActionSeq = act.timestamp; // Dùng seq thay vì timestamp vì có thể trùng lặp
                    if (!string.IsNullOrEmpty(act.description))
                    {
                        SetLog(act.description);
                    }
                    
                    string actType = act.type;
                    if ((actType == "DODGE_SUCCESS" || actType == "NULLIFY_PLAYED" || actType == "DUEL_RESPOND" || actType == "AOE_DEFENDED") && !string.IsNullOrEmpty(act.cardId))
                    {
                        var responderSeat = act.casterSeat;
                        if (actType == "AOE_DEFENDED" || actType == "DODGE_SUCCESS") responderSeat = act.targetSeat;
                        
                        var responder = GetGeneralBySeat(responderSeat);
                        var card = CardDatabase.GetCardById(act.cardId);
                        if (responder != null && card != null)
                        {
                            Vector2 startPos = new Vector2(0, 0);
                            var casterRt = responder.GetComponent<RectTransform>();
                            if (casterRt != null)
                            {
                                Vector2 casterScreen = RectTransformUtility.WorldToScreenPoint(null, casterRt.position);
                                RectTransformUtility.ScreenPointToLocalPointInRectangle(battleRootGo != null ? battleRootGo.GetComponent<RectTransform>() : canvasGo.GetComponent<RectTransform>(), casterScreen, null, out startPos);
                            }
                            StartCoroutine(ShowResponseCardAnimation(card, startPos));
                        }
                    }
                    else if ((actType.StartsWith("PLAY_") || actType == "EQUIP" || actType == "DELAYED_SCROLL_ATTACHED") && !string.IsNullOrEmpty(act.cardId))
                    {
                        var casterGen = GetGeneralBySeat(act.casterSeat);
                        var targetGen = GetGeneralBySeat(act.targetSeat);
                        var card = CardDatabase.GetCardById(act.cardId);
                        if (casterGen != null && card != null)
                        {
                            if (actType == "PLAY_SLASH" && targetGen != null)
                            {
                                StartCoroutine(AnimateSlashAttack(card, casterGen, targetGen));
                            }
                            else if (actType == "EQUIP")
                            {
                                ShowCardAtCenter(card, casterGen, targetGen, $"Trang bị {GetFormattedCardName(card)}");
                            }
                            else
                            {
                                ShowCardAtCenter(card, casterGen, targetGen);
                            }
                        }
                    }
                    // Hiệu ứng phán xét từ Server
                    else if (actType == "LIGHTNING_HIT" || actType == "LIGHTNING_PASSED" || actType == "SUPPLY_SHORTAGE_TRIGGERED" || actType == "SUPPLY_SHORTAGE_PASSED" || actType == "ACEDIA_TRIGGERED" || actType == "ACEDIA_PASSED")
                    {
                        var targetGen = GetGeneralBySeat(act.targetSeat);
                        var judgeCard = CardDatabase.GetCardById(act.cardId);
                        if (judgeCard != null && targetGen != null)
                        {
                            string title = "PHÁN XÉT";
                            if (actType.StartsWith("LIGHTNING")) title = "PHÁN XÉT THẦN SẤM";
                            else if (actType.StartsWith("SUPPLY")) title = "PHÁN XÉT CẮT LƯƠNG";
                            else if (actType.StartsWith("ACEDIA")) title = "PHÁN XÉT SA BẪY";
                            
                            bool success = actType.EndsWith("PASSED");
                            StartCoroutine(ServerJudgementAnimation(judgeCard, targetGen, title, success));
                        }
                    }
                }
            }
        }

        // 6. Đồng bộ Phase chờ phản hồi từ Server (Server-Phase Synchronization)
        if (state.phase == "PLAY" || state.phase == "FINISHED")
        {
            isAwaitingSlashDefense = false;
            isAwaitingServerAoE = false;
            isAwaitingServerDuel = false;
            isAwaitingServerNearDeath = false;
            isAwaitingServerSongCung = false;
            isAwaitingServerNamSon = false;
            isDiscardPhaseActive = false;
            var orphanSlashPanel = GameObject.Find("SlashReactionPanel");
            if (orphanSlashPanel != null) Destroy(orphanSlashPanel);
            var orphanAoEPanel = GameObject.Find("AoEReactionPanel");
            if (orphanAoEPanel != null) Destroy(orphanAoEPanel);
            var orphanDuelPanel = GameObject.Find("DuelReactionPanel");
            if (orphanDuelPanel != null) Destroy(orphanDuelPanel);
            var orphanCounterPrompt = GameObject.Find("CounterPromptModal");
            if (orphanCounterPrompt != null) Destroy(orphanCounterPrompt);
            var orphanCounterWait = GameObject.Find("CounterWaitingModal");
            if (orphanCounterWait != null) Destroy(orphanCounterWait);
            var orphanHarvest = GameObject.Find("HarvestModal");
            if (orphanHarvest != null) Destroy(orphanHarvest);
            DestroyServerPromptObject("ServerRescuePromptModal");
            DestroyServerPromptObject("ServerSongCungPromptModal");
            DestroyServerPromptObject("ServerNamSonPromptModal");
            CloseServerTargetCardModal();
            lastHandledPhaseVersion = -1;
            lastHandledWaitingSeat = -1;
            lastHandledPromptKey = "";
            lastServerTargetCardPromptVersion = -1;
            lastServerTargetCardPromptKey = "";
            serverTargetCardSelectionInFlight = false;

    
        
        // Bật/tắt tương tác lượt của người chơi theo Server
            if (playerCard != null)
            {
                bool isMyTurn = (state.turnSeat == playerCard.SeatNumber && state.status == "PLAYING");
                isPlayerTurnActive = isMyTurn;
                if (endTurnBtn != null)
                {
                    endTurnBtn.gameObject.SetActive(isMyTurn);
                    endTurnBtn.interactable = isMyTurn;
                }
                if (!isMyTurn)
                {
                    if (actionBtnGo != null) actionBtnGo.SetActive(false);
                    ClearSelectedTarget();
                }
            }
        }
        else if (!string.IsNullOrEmpty(state.phase))
        {
            isPlayerTurnActive = false;
            if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(false);
            if (actionBtnGo != null) actionBtnGo.SetActive(false);
            if (playerCard != null && state.turnSeat != playerCard.SeatNumber)
            {
                ClearSelectedTarget();
            }
            HandleServerPhasePrompt(state);
        }
    }

    private void ApplyServerLoadout(GeneralCardUI general, AppwriteMatchmaking.GameStatePlayer serverPlayer)
    {
        if (general == null || serverPlayer == null) return;

        general.ClearAllEquipment();
        if (serverPlayer.equipments != null)
        {
            foreach (var serverCard in serverPlayer.equipments)
            {
                var equipment = ConvertGameStateCardToCardModel(serverCard);
                if (equipment != null) general.Equip(equipment);
            }
        }

        general.ClearDelayedScrolls();
        if (serverPlayer.judgements != null)
        {
            foreach (var serverCard in serverPlayer.judgements)
            {
                var judgement = ConvertGameStateCardToCardModel(serverCard);
                if (judgement != null) general.AddDelayedScroll(judgement);
            }
        }
        general.SetAoBaoCharges(serverPlayer.aoBaoCharges);
    }

    private void DestroyServerPromptObject(string objectName)
    {
        var prompt = GameObject.Find(objectName);
        if (prompt != null) Destroy(prompt);
    }

    private string GetServerPromptKey(AppwriteMatchmaking.ServerGameState state)
    {
        if (state == null) return "";
        var key = new StringBuilder(256);
        key.Append(state.phase ?? "").Append('|')
            .Append(state.waitingTargetSeat).Append('|')
            .Append(state.waitingReactionType ?? "").Append('|')
            .Append(state.nearDeathVictimSeat).Append('|')
            .Append(state.nearDeathAskerQueue != null ? string.Join(",", state.nearDeathAskerQueue) : "").Append('|')
            .Append(state.harvestPickers != null ? string.Join(",", state.harvestPickers) : "").Append('|')
            .Append(state.aoeVictimsQueue != null ? string.Join(",", state.aoeVictimsQueue) : "").Append('|');

        var card = state.activeCard;
        if (card != null)
        {
            key.Append(card.cardId).Append('|')
                .Append(card.cardName).Append('|')
                .Append(card.casterSeat).Append('|')
                .Append(card.targetSeat).Append('|')
                .Append(card.damage).Append('|')
                .Append(card.isWineBuff).Append('|')
                .Append(card.suit).Append('|')
                .Append(card.reqType).Append('|')
                .Append(card.reqName).Append('|')
                .Append(card.namSonFollowUp).Append('|')
                .Append(card.selectionOperation).Append('|')
                .Append(card.nullifyRound).Append('|')
                .Append(card.nullifyBySeat);
        }
        key.Append('|');

        var chain = state.nullifyChain;
        if (chain != null)
        {
            key.Append(chain.isCanceled).Append('|')
                .Append(chain.currentIdx).Append('|')
                .Append(chain.whoUsedLast).Append('|')
                .Append(chain.querySeats != null ? string.Join(",", chain.querySeats) : "");
        }
        key.Append('|');

        var selection = state.targetCardSelection;
        if (selection != null)
        {
            key.Append(selection.chooserSeat).Append('|')
                .Append(selection.targetSeat).Append('|')
                .Append(selection.operation).Append('|')
                .Append(selection.effectType).Append('|')
                .Append(selection.cardId).Append('|');
            if (selection.options != null)
            {
                foreach (var option in selection.options)
                {
                    if (option == null) continue;
                    key.Append(option.token).Append(':')
                        .Append(option.zone).Append(':')
                        .Append(option.card != null ? option.card.id : "").Append(';');
                }
            }
        }
        key.Append('|');
        if (state.harvestPool != null)
        {
            foreach (var harvestCard in state.harvestPool)
                key.Append(harvestCard != null ? harvestCard.id : "").Append(';');
        }
        return key.ToString();
    }


    private void HandleServerPhasePrompt(AppwriteMatchmaking.ServerGameState state)
    {
        if (battleFinished || playerCard == null) return;

        string promptKey = GetServerPromptKey(state);
        bool promptChanged = !string.Equals(lastHandledPromptKey, promptKey, StringComparison.Ordinal);
        if (promptChanged)
        {
            lastHandledPromptKey = promptKey;
            lastHandledWaitingSeat = state.waitingTargetSeat;

            // A new server prompt invalidates every older local modal. Timer
            // ticks keep the same key and therefore do not rebuild the UI.
            DestroyServerPromptObject("CounterPromptModal");
            DestroyServerPromptObject("CounterWaitingModal");
            DestroyServerPromptObject("HarvestModal");
            DestroyServerPromptObject("ServerRescuePromptModal");
            DestroyServerPromptObject("ServerSongCungPromptModal");
            DestroyServerPromptObject("ServerNamSonPromptModal");
            DestroyServerPromptObject("ServerAoEReactionModal");
            DestroyServerPromptObject("ServerDuelReactionModal");
            DestroyServerPromptObject("SlashReactionPanel");
            DestroyServerPromptObject("AoEReactionPanel");
            DestroyServerPromptObject("DuelReactionPanel");
            CloseServerTargetCardModal();
            if (activeCounterPromptCoroutine != null)
            {
                StopCoroutine(activeCounterPromptCoroutine);
                activeCounterPromptCoroutine = null;
            }
            isAwaitingSlashDefense = false;
            isAwaitingServerAoE = false;
            isAwaitingServerDuel = false;
            isAwaitingServerNearDeath = false;
            isAwaitingServerSongCung = false;
            isAwaitingServerNamSon = false; serverTargetCardSelectionInFlight = false; 
            if (state.phase != "DISCARD") {
                isDiscardPhaseActive = false; 
                if (playerHandUI != null) { 
                    playerHandUI.IsMultiSelectMode = false; 
                    playerHandUI.ClearSelection(); 
                    playerHandUI.OnSelectionChanged -= OnDiscardSelectionChanged;
                } 
            }
        }

        switch (state.phase)
        {
            case "AWAIT_NULLIFY":
                if (state.activeCard != null)
                {
                    var rootCard = CardDatabase.GetCardById(state.activeCard.cardId);

                    if (rootCard == null) rootCard = new CardModel { id = state.activeCard.cardId, cardName = state.activeCard.cardName };
                    var targetGen = GetGeneralBySeat(state.activeCard.targetSeat);
                    string targetDesc = "";
                    if (targetGen != null) {
                        if (rootCard.subType == CardSubType.Harvest) targetDesc = $" việc chia bài cho #{targetGen.SeatNumber} ({targetGen.GeneralName})";
                        else targetDesc = $" lên #{targetGen.SeatNumber} ({targetGen.GeneralName})";
                    }
                    var casterGen = GetGeneralBySeat(state.activeCard.casterSeat);
                    string casterDesc = casterGen != null ? $"#{casterGen.SeatNumber} ({casterGen.GeneralName}) thực thi " : "thực thi ";
                    bool isCurrentlyCanceled = state.activeCard.isCanceled;
                    string qText = !isCurrentlyCanceled
                        ? $"Có dùng Diệu Kế Phá Mưu để ngăn chặn\n{casterDesc}{GetFormattedCardName(rootCard)}{targetDesc} không?"
                        : $"Có dùng Diệu Kế Phá Mưu để phá giải Diệu Kế của Ghế {state.nullifyChain.whoUsedLast}\nnhằm vào {GetFormattedCardName(rootCard)}{targetDesc} không?";
                    if (state.waitingTargetSeat == playerCard.SeatNumber)
                    {
                        // Xóa modal chờ cũ (nếu có)
                        var orphanWait = GameObject.Find("CounterWaitingModal");
                        if (orphanWait != null) Destroy(orphanWait);

                        var counterCards = playerHandCards.FindAll(c => c != null && (c.subType == CardSubType.FlawlessDefense || (!string.IsNullOrEmpty(c.cardName) && c.cardName.Contains("Diệu Kế"))));
                        if (counterCards.Count == 0)
                        {
                            // Người chơi không có Diệu Kế -> Tự động bỏ qua ngay lập tức, không hiện modal hỏi!
                            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                            {
                                action = "RESPOND_ACTION",
                                roomId = currentRoomId,
                                seat = playerCard.SeatNumber,
                                accepted = false,
                                cardId = ""
                            }, (s) => { if (s != null) ApplyServerGameState(s); });
                            break;
                        }

                        var existingPrompt = GameObject.Find("CounterPromptModal");
                        if (existingPrompt == null || promptChanged)
                        {
                            lastHandledWaitingSeat = state.waitingTargetSeat;
                            if (existingPrompt != null) Destroy(existingPrompt);
                            if (activeCounterPromptCoroutine != null) StopCoroutine(activeCounterPromptCoroutine);

                            Debug.Log($"[NullifyPrompt] Tạo CounterPromptModal cho ghế {playerCard.SeatNumber} với {counterCards.Count} lá Diệu Kế");
                            activeCounterPromptCoroutine = StartCoroutine(PromptPlayerCounterScroll(rootCard, qText, counterCards, (didUse, chosenCard) =>
                            {
                                activeCounterPromptCoroutine = null;
                                DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                                {
                                    action = "RESPOND_ACTION",
                                    roomId = currentRoomId,
                                    seat = playerCard.SeatNumber,
                                    accepted = didUse,
                                    cardId = chosenCard != null ? chosenCard.id : ""
                                }, (s) => { if (s != null) ApplyServerGameState(s); });
                            }));
                        }
                    }
                    else
                    {
                        // Xóa CounterPromptModal (nếu có - trường hợp lượt hỏi đã chuyển sang người khác)
                        var orphanPrompt = GameObject.Find("CounterPromptModal");
                        if (orphanPrompt != null) Destroy(orphanPrompt);
                        if (activeCounterPromptCoroutine != null) { StopCoroutine(activeCounterPromptCoroutine); activeCounterPromptCoroutine = null; }

                        var queriedGen = GetGeneralBySeat(state.waitingTargetSeat);
                        if (queriedGen != null)
                        {
                            if (promptChanged || lastHandledWaitingSeat != state.waitingTargetSeat)
                            {
                                lastHandledWaitingSeat = state.waitingTargetSeat;
                                // Xóa modal chờ cũ trước khi tạo mới
                                var oldWait = GameObject.Find("CounterWaitingModal");
                                if (oldWait != null) Destroy(oldWait);
                                Debug.Log($"[NullifyPrompt] Tạo CounterWaitingModal cho ghế {playerCard.SeatNumber} - đang chờ ghế {state.waitingTargetSeat}");
                                var waitingModalGo = ShowWaitingCounterScrollModal(queriedGen, qText);
                                StartCoroutine(UpdateCounterWaitingModalTimer(waitingModalGo, queriedGen));
                            }
                        }
                    }
                }
                break;

            case "AWAIT_HARVEST":
                var existingHarvest = GameObject.Find("HarvestModal");
                if (existingHarvest == null || promptChanged)
                {
                    lastHandledWaitingSeat = state.waitingTargetSeat;
                    if (existingHarvest != null) Destroy(existingHarvest);

                    var poolCards = new List<CardModel>();
                    if (state.harvestPool != null)
                    {
                        foreach (var c in state.harvestPool)
                        {
                            var cm = CardDatabase.GetCardById(c.id);
                            if (cm == null)
                            {
                                CardSuit s = CardSuit.Heart;
                                Enum.TryParse(c.suit, out s);
                                cm = new CardModel { id = c.id, cardName = c.name, suit = s, rank = (CardRank)c.rank };
                            }
                            poolCards.Add(cm);
                        }
                    }
                    ShowServerHarvestModal(poolCards, state.waitingTargetSeat == playerCard.SeatNumber, state.waitingTargetSeat);
                }
                break;

            case "AWAIT_TARGET_CARD":
                HandleServerTargetCardPrompt(state);
                break;

            case "AWAIT_SLASH_DEFENSE":
                Debug.Log($"[SlashDefense] waitingSeat={state.waitingTargetSeat} mySeat={playerCard.SeatNumber} isAwaitingSlashDefense={isAwaitingSlashDefense} activeCard={state.activeCard?.cardId}");
                if (state.waitingTargetSeat == playerCard.SeatNumber && state.activeCard != null && !isAwaitingSlashDefense)
                {
                    var slashCard = CardDatabase.GetCardById(state.activeCard.cardId);
                    if (slashCard == null) slashCard = new CardModel { id = state.activeCard.cardId, cardName = state.activeCard.cardName, subType = CardSubType.AttackNormal };
                    int dmg = state.activeCard.damage > 0 ? state.activeCard.damage : 1;
                    var attacker = GetGeneralBySeat(state.activeCard.casterSeat);
                    bool hasHolyCannon = attacker != null && attacker.HasEquipment(EquipmentType.Weapon, "Súng Thần Công");
                    Debug.Log($"[SlashDefense] → Gọi AwaitForPlayerSlashDefense dmg={dmg}");
                    StartCoroutine(AwaitForPlayerSlashDefense(slashCard, dmg, hasHolyCannon, (res) => {}));
                }
                break;

            case "AWAIT_SONG_CUNG_FOLLOW_UP":
                if (state.waitingTargetSeat == playerCard.SeatNumber && !isAwaitingServerSongCung)
                {
                    StartCoroutine(ResolveServerSongCungFollowUp(state));
                }
                break;

            case "AWAIT_NAM_SON_FOLLOW_UP":
                if (state.waitingTargetSeat == playerCard.SeatNumber && !isAwaitingServerNamSon)
                {
                    StartCoroutine(ResolveServerNamSonFollowUp(state));
                }
                break;

            case "AWAIT_AOE":
                if (state.waitingTargetSeat == playerCard.SeatNumber && state.activeCard != null && !isAwaitingServerAoE)
                {
                    bool needSlash = state.waitingReactionType == "SLASH";
                    string aoeName = state.activeCard.cardName;
                    string reqName = needSlash ? "Trảm" : "Né";
                    StartCoroutine(ResolveServerAoERequirement(needSlash, aoeName, reqName));
                }
                break;

            case "AWAIT_DUEL":
                if (state.waitingTargetSeat == playerCard.SeatNumber && state.activeCard != null && !isAwaitingServerDuel)
                {
                    var caster = GetGeneralBySeat(state.activeCard.casterSeat);
                    if (caster != null) StartCoroutine(ResolveServerDuel(caster, playerCard));
                }
                break;

            case "AWAIT_NEAR_DEATH":
                if (state.waitingTargetSeat == playerCard.SeatNumber && !isAwaitingServerNearDeath)
                {
                    StartCoroutine(ResolveServerNearDeath(state));
                }
                break;

            case "DISCARD":
                if (state.turnSeat == playerCard.SeatNumber && !isDiscardPhaseActive)
                {
                    StartCoroutine(StartDiscardPhase(playerCard));
                }
                break;
        }
    }

    private void HandleServerTargetCardPrompt(AppwriteMatchmaking.ServerGameState state)
    {
        var selection = state != null ? state.targetCardSelection : null;
        if (selection == null || playerCard == null || state.waitingTargetSeat != playerCard.SeatNumber)
        {
            CloseServerTargetCardModal();
            serverTargetCardSelectionInFlight = false;
            return;
        }

        var target = GetGeneralBySeat(selection.targetSeat);
        if (target == null || selection.options == null || selection.options.Count == 0)
        {
            CloseServerTargetCardModal();
            return;
        }

        string promptKey = GetServerPromptKey(state);
        if (activeServerTargetCardModal != null && lastServerTargetCardPromptKey == promptKey)
            return;

        CloseServerTargetCardModal();
        lastServerTargetCardPromptKey = promptKey;
        lastServerTargetCardPromptVersion = state.version;
        serverTargetCardSelectionInFlight = false;
        ShowServerTargetCardModal(selection, target, state.waitingTimer);
    }

    private void CloseServerTargetCardModal()
    {
        if (activeServerTargetCardModal != null)
        {
            Destroy(activeServerTargetCardModal);
            activeServerTargetCardModal = null;
        }

        var orphan = GameObject.Find("ServerTargetCardModal");
        if (orphan != null) Destroy(orphan);
    }

    private void EnableServerTargetCardButtons(bool enabled)
    {
        if (activeServerTargetCardModal == null) return;
        foreach (var button in activeServerTargetCardModal.GetComponentsInChildren<Button>(true))
        {
            if (button != null) button.interactable = enabled;
        }
    }

    private void ShowServerTargetCardModal(
        AppwriteMatchmaking.GameStateTargetCardSelection selection,
        GeneralCardUI target,
        int waitingTimer)
    {
        var modalGo = new GameObject("ServerTargetCardModal", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        modalGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modalGo.transform.SetAsLastSibling();
        activeServerTargetCardModal = modalGo;

        var modalImage = modalGo.GetComponent<Image>();
        modalImage.color = new Color(0.02f, 0.03f, 0.07f, 0.9f);
        Fill(modalGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(820f, 490f);

        var panelImage = panelGo.GetComponent<Image>();
        var panelSprite = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (panelSprite != null) { panelImage.sprite = panelSprite; panelImage.type = Image.Type.Sliced; }
        panelImage.color = new Color(0.08f, 0.11f, 0.2f, 0.99f);

        string operationText = selection.operation == "STEAL" ? "CƯỚP" : "HỦY";
        string icon = selection.operation == "STEAL" ? "🌾" : "🏚️";
        var title = AddText(panelGo.transform, "Title",
            $"{icon} {operationText} 1 LÁ CỦA {target.GeneralName.ToUpper()}",
            ThemeUI.SizeTitleLarge, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(780f, 38f), new Vector2(0f, -14f));

        var timer = AddText(panelGo.transform, "Timer",
            $"⏳ Chọn bài trong {Mathf.Max(0, waitingTimer)}s · Lá trên tay được úp",
            ThemeUI.SizeBodyLarge, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timer.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(760f, 28f), new Vector2(0f, -52f));

        var targetText = AddText(panelGo.transform, "Target",
            $"Mục tiêu: <b>{target.GeneralName}</b> · Chạm chọn lá cần {operationText.ToLowerInvariant()}",
            ThemeUI.SizeBody, ThemeUI.TextMuted, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(targetText.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(760f, 26f), new Vector2(0f, -80f));

        var viewportGo = new GameObject("CardsViewport", typeof(RectTransform), typeof(Image), typeof(RectMask2D), typeof(ScrollRect));
        viewportGo.transform.SetParent(panelGo.transform, false);
        var viewportRt = viewportGo.GetComponent<RectTransform>();
        SetRect(viewportRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(770f, 280f), new Vector2(0f, -30f));
        viewportGo.GetComponent<Image>().color = new Color(0.02f, 0.04f, 0.09f, 0.35f);

        var cardsContainerGo = new GameObject("CardsContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        cardsContainerGo.transform.SetParent(viewportGo.transform, false);
        var contentRt = cardsContainerGo.GetComponent<RectTransform>();
        contentRt.anchorMin = new Vector2(0f, 0.5f);
        contentRt.anchorMax = new Vector2(0f, 0.5f);
        contentRt.pivot = new Vector2(0f, 0.5f);
        contentRt.sizeDelta = new Vector2(Mathf.Max(735f, selection.options.Count * 132f), 195f);
        contentRt.anchoredPosition = new Vector2(10f, 0f);

        var layout = cardsContainerGo.GetComponent<HorizontalLayoutGroup>();
        layout.spacing = 14f;
        layout.padding = new RectOffset(4, 4, 12, 12);
        layout.childAlignment = TextAnchor.MiddleLeft;
        layout.childControlWidth = layout.childControlHeight = false;

        var scroll = viewportGo.GetComponent<ScrollRect>();
        scroll.viewport = viewportRt;
        scroll.content = contentRt;
        scroll.horizontal = true;
        scroll.vertical = false;
        scroll.movementType = ScrollRect.MovementType.Clamped;

        int handIndex = 1;
        foreach (var option in selection.options)
        {
            if (option == null || string.IsNullOrEmpty(option.token)) continue;
            var selectedOption = option;
            GameObject cardItemGo;
            if (string.Equals(option.zone, "HAND", StringComparison.OrdinalIgnoreCase))
            {
                cardItemGo = CreateFaceDownCardItem(cardsContainerGo.transform, new Vector2(118f, 162f), $"LÁ ÚP #{handIndex++}", font);
            }
            else
            {
                var cardModel = ConvertGameStateCardToCardModel(option.card);
                cardItemGo = cardModel != null
                    ? CardUI.Create(cardsContainerGo.transform, cardModel, new Vector2(118f, 162f)).gameObject
                    : CreateFaceDownCardItem(cardsContainerGo.transform, new Vector2(118f, 162f), "LÁ BÀI", font);
            }

            var button = cardItemGo.GetComponent<Button>();
            if (button == null)
            {
                var overlay = new GameObject("OverlayBtn", typeof(RectTransform), typeof(Image), typeof(Button));
                overlay.transform.SetParent(cardItemGo.transform, false);
                overlay.transform.SetAsLastSibling();
                overlay.GetComponent<Image>().color = new Color(1f, 1f, 1f, 0.001f);
                Fill(overlay.GetComponent<RectTransform>());
                button = overlay.GetComponent<Button>();
            }

            button.onClick.AddListener(() =>
            {
                if (serverTargetCardSelectionInFlight) return;
                serverTargetCardSelectionInFlight = true;
                EnableServerTargetCardButtons(false);
                AudioManager.Instance.PlayCardSelect();
                DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                {
                    action = "RESPOND_ACTION",
                    roomId = currentRoomId,
                    seat = playerCard.SeatNumber,
                    accepted = true,
                    targetCardId = selectedOption.token
                }, (s) =>
                {
                    serverTargetCardSelectionInFlight = false;
                    if (s != null) ApplyServerGameState(s);
                });
            });
            AddTargetZoneLabel(cardItemGo.transform, option.label, font);
        }
    }

    private IEnumerator ResolveServerAoERequirement(bool needSlash, string aoeName, string reqName)
    {
        isAwaitingServerAoE = true;
        yield return ShowAuthoritativeAoEPrompt(needSlash, aoeName, reqName);
        isAwaitingServerAoE = false;
    }

    private IEnumerator ResolveServerDuel(GeneralCardUI caster, GeneralCardUI target)
    {
        isAwaitingServerDuel = true;
        yield return ShowAuthoritativeDuelPrompt(caster, target);
        isAwaitingServerDuel = false;
    }

    private IEnumerator ResolveServerNearDeath(AppwriteMatchmaking.ServerGameState state)
    {
        isAwaitingServerNearDeath = true;
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        var victim = GetGeneralBySeat(state.nearDeathVictimSeat);
        var rescueCard = playerHandCards.Find(card =>
            card != null && (card.subType == CardSubType.Peach
                || (card.subType == CardSubType.Wine && victim == playerCard)));

        if (victim == null || rescueCard == null)
        {
            SetLog(rescueCard == null
                ? "🆘 Bạn không có Bánh Chưng/Hủ Rượu hợp lệ để cứu."
                : "🆘 Không xác định được người đang Cận Tử.");
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = false,
                cardId = ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
            isAwaitingServerNearDeath = false;
            yield break;
        }

        bool decided = false;
        bool useRescue = false;
        float timer = 40f;
        var modal = new GameObject("ServerRescuePromptModal", typeof(RectTransform), typeof(Image));
        modal.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modal.transform.SetAsLastSibling();
        var modalImage = modal.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { modalImage.sprite = bgSprite; modalImage.type = Image.Type.Sliced; }
        modalImage.color = new Color(0.08f, 0.04f, 0.06f, 0.98f);
        var modalRect = modal.GetComponent<RectTransform>();
        modalRect.anchorMin = modalRect.anchorMax = modalRect.pivot = new Vector2(0.5f, 0.5f);
        modalRect.sizeDelta = new Vector2(620f, 155f);
        modalRect.anchoredPosition = new Vector2(-80f, 120f);

        var title = AddText(modal.transform, "Title",
            rescueCard.subType == CardSubType.Wine
                ? "🍶 UỐNG HỦ RƯỢU TỰ CỨU CẬN TỬ?"
                : $"💮 DÙNG BÁNH CHƯNG CỨU {victim.GeneralName}?",
            13, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(580f, 38f), new Vector2(0, -10f));
        var timerText = AddText(modal.transform, "Timer", "⏳ Còn 40s", 12, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerText.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(250f, 22f), new Vector2(0, -46f));

        var buttonSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        var useButtonGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
        useButtonGo.transform.SetParent(modal.transform, false);
        var useImage = useButtonGo.GetComponent<Image>();
        if (buttonSprite != null) { useImage.sprite = buttonSprite; useImage.type = Image.Type.Sliced; }
        useImage.color = new Color(0.2f, 0.75f, 0.35f, 1f);
        SetRect(useButtonGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(270f, 38f), new Vector2(-135f, 16f));
        var useText = AddText(useButtonGo.transform, "Txt",
            rescueCard.subType == CardSubType.Wine ? "🍶 UỐNG HỦ RƯỢU TỰ CỨU" : "💮 DÙNG BÁNH CHƯNG CỨU",
            11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(useText.rectTransform);

        var passButtonGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passButtonGo.transform.SetParent(modal.transform, false);
        var passImage = passButtonGo.GetComponent<Image>();
        if (buttonSprite != null) { passImage.sprite = buttonSprite; passImage.type = Image.Type.Sliced; }
        passImage.color = new Color(0.5f, 0.55f, 0.65f, 1f);
        SetRect(passButtonGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(200f, 38f), new Vector2(145f, 16f));
        var passText = AddText(passButtonGo.transform, "Txt", "❌ KHÔNG CỨU", 11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(passText.rectTransform);

        useButtonGo.GetComponent<Button>().onClick.AddListener(() => { useRescue = true; decided = true; });
        passButtonGo.GetComponent<Button>().onClick.AddListener(() => { useRescue = false; decided = true; });
        playerCard.ShowHeadTimer(40);
        while (!decided && !battleFinished && (!serverControlled || IsAuthoritativePromptActive("AWAIT_NEAR_DEATH")))
        {
            if (serverControlled) timer = turnTimer;
            timer -= Time.unscaledDeltaTime;
            playerCard.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(timer)));
            if (timerText != null) timerText.text = $"⏳ Còn {Mathf.CeilToInt(timer)}s";
            
            if (!serverControlled && timer <= 0f) decided = true;
            yield return null;
        }

        playerCard.HideHeadTimer();
        if (modal != null) Destroy(modal);
        if (!serverControlled || (decided && IsAuthoritativePromptActive("AWAIT_NEAR_DEATH")))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = useRescue,
                cardId = useRescue ? rescueCard.id : ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }
        isAwaitingServerNearDeath = false;
    }

    private IEnumerator PromptPlayerSongCungDiscard(GeneralCardUI caster, GeneralCardUI target, Action<bool, List<CardModel>> onResolved)
    {
        bool decided = false;
        bool accepted = false;
        var chosenCards = new List<CardModel>();
        float promptTimer = 40.0f;

        caster.ShowHeadTimer(40);

        var modal = new GameObject("SongCungPromptModal", typeof(RectTransform), typeof(Image));
        modal.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modal.transform.SetAsLastSibling();

        var modalImage = modal.GetComponent<Image>();
        var bg = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bg != null) { modalImage.sprite = bg; modalImage.type = Image.Type.Sliced; }
        modalImage.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);

        var modalRect = modal.GetComponent<RectTransform>();
        modalRect.anchorMin = modalRect.anchorMax = modalRect.pivot = new Vector2(0.5f, 0.5f);
        modalRect.sizeDelta = new Vector2(740f, 190f);
        modalRect.anchoredPosition = new Vector2(0f, 65f);

        var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        fGo.transform.SetParent(modal.transform, false);
        var fImg = fGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = ThemeUI.GoldPrimary;
        fImg.raycastTarget = false;
        Fill(fGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var title = AddText(modal.transform, "Title", "🏹 KÍCH HOẠT SONG CUNG MƯỜNG NHẠ", 18, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(title.rectTransform, new Vector2(0f, 1f), new Vector2(0.7f, 1f), new Vector2(0f, 1f), new Vector2(0, 28f), new Vector2(24f, -12f));

        var timerTxt = AddText(modal.transform, "Timer", "⏳ Còn 40s...", 16, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleRight);
        SetRect(timerTxt.rectTransform, new Vector2(0.7f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(0, 28f), new Vector2(-24f, -12f));

        string targetName = target != null ? target.GeneralName : "mục tiêu";
        var message = AddText(modal.transform, "Message", $"Đòn Trảm bị Đỡ! Hãy chọn đúng 2 lá trên tay (0/2) để ép <b>{targetName}</b> vẫn phải chịu 1 sát thương xuyên Đỡ.", 15, new Color(0.9f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        message.lineSpacing = 1.2f;
        message.horizontalOverflow = HorizontalWrapMode.Wrap;
        message.verticalOverflow = VerticalWrapMode.Truncate;
        SetRect(message.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(-48f, 50f), new Vector2(0f, -44f));

        var buttonSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        var useGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
        useGo.transform.SetParent(modal.transform, false);
        var useImage = useGo.GetComponent<Image>();
        if (buttonSprite != null) { useImage.sprite = buttonSprite; useImage.type = Image.Type.Sliced; }
        useImage.color = new Color(0.35f, 0.4f, 0.5f, 0.7f);
        SetRect(useGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(300f, 44f), new Vector2(-125f, 16f));
        var useText = AddText(useGo.transform, "Text", "🏹 BỎ 2 LÁ ÉP MẤT MÁU", 15, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(useText.rectTransform);

        var passGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passGo.transform.SetParent(modal.transform, false);
        var passImage = passGo.GetComponent<Image>();
        if (buttonSprite != null) { passImage.sprite = buttonSprite; passImage.type = Image.Type.Sliced; }
        passImage.color = new Color(0.40f, 0.44f, 0.52f, 1f);
        SetRect(passGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(200f, 44f), new Vector2(155f, 16f));
        var passText = AddText(passGo.transform, "Text", "❌ BỎ QUA", 15, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(passText.rectTransform);

        Action<List<CardUI>> onSelectionChanged = selected =>
        {
            chosenCards.Clear();
            if (selected != null)
            {
                foreach (var cardUI in selected)
                {
                    if (cardUI != null && cardUI.Data != null) chosenCards.Add(cardUI.Data);
                }
            }
            bool isEnough = chosenCards.Count == 2;
            useGo.GetComponent<Button>().interactable = isEnough;
            useImage.color = isEnough ? ThemeUI.JadeGreen : new Color(0.35f, 0.4f, 0.5f, 0.7f);
            message.text = isEnough
                ? $"<color=#55FF55><b>Đã chọn đủ 2 lá bài!</b></color> Nhấn nút [BỎ 2 LÁ ÉP MẤT MÁU] để kích hoạt."
                : $"Đòn Trảm bị Đỡ! Hãy chọn đúng 2 lá trên tay ({chosenCards.Count}/2) để ép <b>{targetName}</b> chịu 1 sát thương.";
        };

        playerHandUI.IsMultiSelectMode = true;
        playerHandUI.MaxSelectableCards = 2;
        playerHandUI.ClearSelection();
        playerHandUI.HighlightOnlyMatching(_ => true);
        playerHandUI.OnSelectionChanged += onSelectionChanged;

        useGo.GetComponent<Button>().interactable = false;
        useGo.GetComponent<Button>().onClick.AddListener(() => { accepted = true; decided = true; });
        passGo.GetComponent<Button>().onClick.AddListener(() => { accepted = false; decided = true; });

        while (!decided && !battleFinished)
        {
            promptTimer -= Time.unscaledDeltaTime;
            caster.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(promptTimer)));
            if (timerTxt != null) timerTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(promptTimer))}s...";

            if (promptTimer <= 0f)
            {
                decided = true;
            }
            yield return null;
        }

        playerHandUI.OnSelectionChanged -= onSelectionChanged;
        playerHandUI.ClearSelection();
        playerHandUI.IsMultiSelectMode = false;
        playerHandUI.ClearHighlights();
        caster.HideHeadTimer();
        if (modal != null) Destroy(modal);

        onResolved?.Invoke(accepted && chosenCards.Count == 2, chosenCards);
    }

    private IEnumerator AwaitRemoteSongCungFollowUp(GeneralCardUI caster, GeneralCardUI target, Action<bool, List<CardModel>> onResolved)
    {
        bool remoteDecided = false;
        bool wantsFollowUp = false;
        var chosenCards = new List<CardModel>();
        float waitTimer = 40.0f;

        caster.ShowHeadTimer(40);
        SetLog($"⏳ Đang đợi <b>{caster.GeneralName}</b> chọn có kích hoạt [Song Cung Mường Nhạ] ép đối phương chịu sát thương không... (40s)");

        while (waitTimer > 0f && !remoteDecided && !battleFinished)
        {
            waitTimer -= Time.unscaledDeltaTime;
            caster.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

            yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
            {
                foreach (var act in actions)
                {
                    if (act.casterSeat == caster.SeatNumber && act.actionType == "SONG_CUNG_TRIGGERED" && !processedActionTimestamps.Contains(act.timestamp))
                    {
                        processedActionTimestamps.Add(act.timestamp);
                        remoteDecided = true;
                        wantsFollowUp = act.accepted;
                        if (wantsFollowUp && !string.IsNullOrEmpty(act.cardId))
                        {
                            var ids = act.cardId.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                            foreach (var cid in ids)
                            {
                                var trimmed = cid.Trim();
                                var cm = CardDatabase.GetCardById(trimmed) ?? new CardModel { id = trimmed, cardName = "Bài Bỏ" };
                                chosenCards.Add(cm);
                            }
                        }
                    }
                }
            });

            if (remoteDecided) break;
            yield return null;
        }

        caster.HideHeadTimer();
        onResolved?.Invoke(wantsFollowUp && chosenCards.Count == 2, chosenCards);
    }

    private IEnumerator ResolveServerSongCungFollowUp(AppwriteMatchmaking.ServerGameState state)
    {
        isAwaitingServerSongCung = true;
        var target = state != null && state.activeCard != null
            ? GetGeneralBySeat(state.activeCard.targetSeat)
            : null;

        yield return PromptPlayerSongCungDiscard(playerCard, target, (accepted, chosenCards) =>
        {
            var selectedIds = new List<string>();
            if (chosenCards != null)
            {
                foreach (var c in chosenCards) selectedIds.Add(c.id);
            }

            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = accepted,
                cardIds = accepted ? new List<string>(selectedIds) : new List<string>()
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        });

        isAwaitingServerSongCung = false;
    }

    private IEnumerator ResolveServerNamSonFollowUp(AppwriteMatchmaking.ServerGameState state)
    {
        isAwaitingServerNamSon = true;
        var caster = state != null && state.activeCard != null
            ? GetGeneralBySeat(state.activeCard.casterSeat)
            : playerCard;
        var target = state != null && state.activeCard != null
            ? GetGeneralBySeat(state.activeCard.targetSeat)
            : null;

        if (caster == null || target == null)
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = false
            }, (s) => { if (s != null) ApplyServerGameState(s); });
            isAwaitingServerNamSon = false;
            yield break;
        }

        yield return PromptPlayerNamSonFollowUp(caster, target, null);
        isAwaitingServerNamSon = false;
    }

    private bool IsAuthoritativePromptActive(string phase)
    {
        return !battleFinished && playerCard != null
            && string.Equals(currentAuthoritativePhase, phase, StringComparison.Ordinal)
            && currentAuthoritativeWaitingSeat == playerCard.SeatNumber;
    }

    private IEnumerator ShowAuthoritativeAoEPrompt(bool needSlash, string aoeName, string reqName)
    {
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        var modal = new GameObject("ServerAoEReactionModal", typeof(RectTransform), typeof(Image));
        modal.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modal.transform.SetAsLastSibling();
        var image = modal.GetComponent<Image>();
        var bg = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bg != null) { image.sprite = bg; image.type = Image.Type.Sliced; }
        image.color = new Color(0.04f, 0.08f, 0.12f, 0.98f);
        var rect = modal.GetComponent<RectTransform>();
        rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(650f, 165f);
        rect.anchoredPosition = new Vector2(0f, 110f);

        var title = AddText(modal.transform, "Title", $"⚠️ {aoeName.ToUpperInvariant()}", 14,
            ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f),
            new Vector2(0.5f, 1f), new Vector2(620f, 30f), new Vector2(0f, -10f));
        var message = AddText(modal.transform, "Message",
            $"Bạn phải đánh [{reqName}] để hóa giải, hoặc chịu 1 sát thương.", 11,
            Color.white, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(message.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
            new Vector2(0.5f, 0.5f), new Vector2(660f, 80f), new Vector2(0f, 40f)); message.horizontalOverflow = HorizontalWrapMode.Wrap; message.verticalOverflow = VerticalWrapMode.Overflow;
        var timerTxt = AddText(modal.transform, "Timer", "⏳ Còn 40s để quyết định...", 13, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(300f, 24f), new Vector2(0f, -5f));

        var buttonSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        var useGo = new GameObject("Btn_Respond", typeof(RectTransform), typeof(Image), typeof(Button));
        useGo.transform.SetParent(modal.transform, false);
        var useImage = useGo.GetComponent<Image>();
        if (buttonSprite != null) { useImage.sprite = buttonSprite; useImage.type = Image.Type.Sliced; }
        useImage.color = new Color(0.2f, 0.75f, 0.35f, 1f);
        SetRect(useGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f), new Vector2(300f, 40f), new Vector2(-160f, 14f));
        var useText = AddText(useGo.transform, "Text", $"⚔️ ĐÁNH [{reqName.ToUpperInvariant()}]", 11,
            Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(useText.rectTransform);

        var passGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passGo.transform.SetParent(modal.transform, false);
        var passImage = passGo.GetComponent<Image>();
        if (buttonSprite != null) { passImage.sprite = buttonSprite; passImage.type = Image.Type.Sliced; }
        passImage.color = ThemeUI.CrimsonRed;
        SetRect(passGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f), new Vector2(210f, 40f), new Vector2(155f, 14f));
        var passText = AddText(passGo.transform, "Text", "❌ CHỊU 1 SÁT THƯƠNG", 10,
            Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(passText.rectTransform);

        CardUI selectedCard = null;
        bool decided = false;
        bool accepted = false;
        Action<CardUI> onCardSelected = cardUI =>
        {
            bool valid = cardUI != null && cardUI.Data != null
                && (needSlash ? IsSlashCard(cardUI.Data) : cardUI.Data.subType == CardSubType.Dodge);
            selectedCard = valid ? cardUI : null;
            useGo.GetComponent<Button>().interactable = selectedCard != null;
            useImage.color = selectedCard != null
                ? new Color(0.2f, 0.75f, 0.35f, 1f)
                : new Color(0.4f, 0.44f, 0.52f, 0.85f);
        };
        playerHandUI.HighlightOnlyMatching(c => c != null
            && (needSlash ? IsSlashCard(c) : c.subType == CardSubType.Dodge));
        playerHandUI.OnCardSelected += onCardSelected;
        useGo.GetComponent<Button>().interactable = false;
        useGo.GetComponent<Button>().onClick.AddListener(() => { accepted = true; decided = true; });
        passGo.GetComponent<Button>().onClick.AddListener(() => { accepted = false; decided = true; });

        float promptTimer = 40.0f;
        while (!decided && !battleFinished && IsAuthoritativePromptActive("AWAIT_AOE"))
        {
            
            promptTimer -= Time.unscaledDeltaTime;
            playerCard.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(promptTimer)));
            if (timerTxt != null) timerTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(promptTimer))}s để quyết định...";
            if (promptTimer <= 0f) decided = true;
            yield return null;
        }

        playerHandUI.OnCardSelected -= onCardSelected;
        playerHandUI.ClearHighlights();
        if (modal != null) Destroy(modal);
        if (decided && IsAuthoritativePromptActive("AWAIT_AOE"))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = accepted,
                cardId = accepted && selectedCard != null ? selectedCard.Data.id : ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }
    }

    private IEnumerator ShowAuthoritativeDuelPrompt(GeneralCardUI caster, GeneralCardUI target)
    {
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        var modal = new GameObject("ServerDuelReactionModal", typeof(RectTransform), typeof(Image));
        modal.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modal.transform.SetAsLastSibling();
        var image = modal.GetComponent<Image>();
        var bg = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bg != null) { image.sprite = bg; image.type = Image.Type.Sliced; }
        image.color = new Color(0.08f, 0.04f, 0.02f, 0.98f);
        var rect = modal.GetComponent<RectTransform>();
        rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0.5f, 0.5f);
        rect.sizeDelta = new Vector2(650f, 165f);
        rect.anchoredPosition = new Vector2(0f, 110f);

        var title = AddText(modal.transform, "Title", "⚔️ THÁCH ĐẤU", 14,
            ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(title.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f),
            new Vector2(0.5f, 1f), new Vector2(620f, 30f), new Vector2(0f, -10f));
        var message = AddText(modal.transform, "Message",
            $"{(caster != null ? caster.GeneralName : "Đối phương")} yêu cầu bạn ra 1 lá Trảm.", 11,
            Color.white, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(message.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f),
            new Vector2(0.5f, 0.5f), new Vector2(660f, 80f), new Vector2(0f, 40f)); message.horizontalOverflow = HorizontalWrapMode.Wrap; message.verticalOverflow = VerticalWrapMode.Overflow;
        var timerTxt = AddText(modal.transform, "Timer", "⏳ Còn 40s để quyết định...", 13, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(timerTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(300f, 24f), new Vector2(0f, -5f));

        var buttonSprite = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        var useGo = new GameObject("Btn_Respond", typeof(RectTransform), typeof(Image), typeof(Button));
        useGo.transform.SetParent(modal.transform, false);
        var useImage = useGo.GetComponent<Image>();
        if (buttonSprite != null) { useImage.sprite = buttonSprite; useImage.type = Image.Type.Sliced; }
        useImage.color = new Color(0.2f, 0.75f, 0.35f, 1f);
        SetRect(useGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f), new Vector2(300f, 40f), new Vector2(-160f, 14f));
        var useText = AddText(useGo.transform, "Text", "⚔️ ĐÁP TRẢ BẰNG TRẢM", 11,
            Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(useText.rectTransform);

        var passGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passGo.transform.SetParent(modal.transform, false);
        var passImage = passGo.GetComponent<Image>();
        if (buttonSprite != null) { passImage.sprite = buttonSprite; passImage.type = Image.Type.Sliced; }
        passImage.color = ThemeUI.CrimsonRed;
        SetRect(passGo.GetComponent<RectTransform>(), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f),
            new Vector2(0.5f, 0f), new Vector2(210f, 40f), new Vector2(155f, 14f));
        var passText = AddText(passGo.transform, "Text", "❌ NHẬN THUA (MẤT 1 MÁU)", 10,
            Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(passText.rectTransform);

        CardUI selectedCard = null;
        bool decided = false;
        bool accepted = false;
        Action<CardUI> onCardSelected = cardUI =>
        {
            selectedCard = cardUI != null && cardUI.Data != null && IsSlashCard(cardUI.Data) ? cardUI : null;
            useGo.GetComponent<Button>().interactable = selectedCard != null;
            useImage.color = selectedCard != null
                ? new Color(0.2f, 0.75f, 0.35f, 1f)
                : new Color(0.4f, 0.44f, 0.52f, 0.85f);
        };
        playerHandUI.HighlightOnlyMatching(IsSlashCard);
        playerHandUI.OnCardSelected += onCardSelected;
        useGo.GetComponent<Button>().interactable = false;
        useGo.GetComponent<Button>().onClick.AddListener(() => { accepted = true; decided = true; });
        passGo.GetComponent<Button>().onClick.AddListener(() => { accepted = false; decided = true; });

        float promptTimer = 40.0f;
        while (!decided && !battleFinished && IsAuthoritativePromptActive("AWAIT_DUEL"))
        {
            
            promptTimer -= Time.unscaledDeltaTime;
            playerCard.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(promptTimer)));
            if (promptTimer <= 0f) decided = true;
            yield return null;
        }

        playerHandUI.OnCardSelected -= onCardSelected;
        playerHandUI.ClearHighlights();
        if (modal != null) Destroy(modal);
        if (decided && IsAuthoritativePromptActive("AWAIT_DUEL"))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = accepted,
                cardId = accepted && selectedCard != null ? selectedCard.Data.id : ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }
    }

    private void ShowServerHarvestModal(List<CardModel> revealedCards, bool isMyTurn, int pickerSeat)
    {
        var existingModal = GameObject.Find("HarvestModal");
        if (existingModal != null) Destroy(existingModal);

        var modalGo = new GameObject("HarvestModal", typeof(RectTransform), typeof(Image));
        modalGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modalGo.transform.SetAsLastSibling();

        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(modalGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(780f, 460f);
        panelRt.anchoredPosition = Vector2.zero;

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.06f, 0.14f, 0.12f, 0.98f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(panelGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.35f, 0.9f, 0.45f, 0.98f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSpr != null) { hImg.sprite = badgeSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.15f, 0.58f, 0.32f, 0.98f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(720f, 52f), new Vector2(0, -12f));

        var titleTxt = AddText(headerGo.transform, "Title", $"🍚 MỞ KHO CỨU TẾ - LẬT {revealedCards.Count} LÁ BÀI CÔNG KHAI", ThemeUI.SizeTitleLarge, new Color(1f, 0.95f, 0.6f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(titleTxt.rectTransform);

        var pickerGen = GetGeneralBySeat(pickerSeat);
        string subMessage = isMyTurn
            ? "👉 <color=#FFD700><b>LƯỢT CỦA BẠN:</b></color> Chạm chọn 1 lá bài công khai dưới đây vào tay!"
            : $"⏳ <color=#55DDFF><b>[{pickerGen?.GeneralName ?? ("Ghế " + pickerSeat)}]</b></color> đang chọn 1 lá bài...";

        var subTxt = AddText(panelGo.transform, "SubTitle", subMessage, ThemeUI.SizeBodyLarge, new Color(0.9f, 1f, 0.92f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(720f, 32f), new Vector2(0, -72f));

        var cardsContainerGo = new GameObject("CardsContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        cardsContainerGo.transform.SetParent(panelGo.transform, false);
        var cRt = cardsContainerGo.GetComponent<RectTransform>();
        SetRect(cRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(740f, 240f), new Vector2(0, -22f));
        var hlg = cardsContainerGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 16f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = hlg.childControlHeight = false;

        foreach (var cData in revealedCards)
        {
            var cardUI = CardUI.Create(cardsContainerGo.transform, cData, new Vector2(118f, 162f));
            if (isMyTurn)
            {
                var overlayBtn = new GameObject("ClickOverlay", typeof(RectTransform), typeof(Image), typeof(Button));
                overlayBtn.transform.SetParent(cardUI.transform, false);
                overlayBtn.transform.SetAsLastSibling();
                var oImg = overlayBtn.GetComponent<Image>();
                oImg.color = new Color(1f, 1f, 1f, 0.001f);
                Fill(overlayBtn.GetComponent<RectTransform>());

                overlayBtn.GetComponent<Button>().onClick.AddListener(() =>
                {
                    Destroy(modalGo);
                    DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                    {
                        action = "RESPOND_ACTION",
                        roomId = currentRoomId,
                        seat = playerCard.SeatNumber,
                        accepted = true,
                        cardId = cData.id
                    });
                });
            }
        }
    }

    private void OnDestroy()
    {
        if (gameStateSyncCoroutine != null)
        {
            StopCoroutine(gameStateSyncCoroutine);
            gameStateSyncCoroutine = null;
        }
        if (DenoGameClient.Instance != null)
        {
            DenoGameClient.Instance.StopConnection();
        }
    }
    #endregion

    #region 1. KHỞI TẠO CANVAS CHÍNH
    private void BuildMainCanvas()
    {
        Screen.orientation = ScreenOrientation.LandscapeRight;
        Screen.autorotateToPortrait = false;
        Screen.autorotateToPortraitUpsideDown = false;
        Screen.autorotateToLandscapeLeft = true;
        Screen.autorotateToLandscapeRight = true;

        canvasGo = new GameObject("Battle2v2Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
        canvasGo.transform.SetParent(transform, false);
        var canvas = canvasGo.GetComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        canvas.sortingOrder = 20;

        scaler = canvasGo.GetComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1280, 720);
        scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
        scaler.matchWidthOrHeight = 0.5f;

        // Hình Nền Chiến Trường
        var bgGo = new GameObject("Background", typeof(RectTransform), typeof(RawImage));
        bgGo.transform.SetParent(canvasGo.transform, false);
        var bgImg = bgGo.GetComponent<RawImage>();
        var bgTex = Resources.Load<Texture2D>("UI/home_background");
        if (bgTex == null) bgTex = Resources.Load<Texture2D>("UI/login_background");
        if (bgTex != null) bgImg.texture = bgTex;
        var bgRt = bgGo.GetComponent<RectTransform>();
        Fill(bgRt, new Vector2(-30, -20), new Vector2(30, 20));

        var shadeGo = new GameObject("Shade", typeof(RectTransform), typeof(Image));
        shadeGo.transform.SetParent(canvasGo.transform, false);
        var shadeImg = shadeGo.GetComponent<Image>();
        shadeImg.color = new Color(0.02f, 0.04f, 0.08f, 0.65f);
        shadeImg.raycastTarget = false;
        Fill(shadeGo.GetComponent<RectTransform>());
    }
    #endregion

    #region 2. GIAI ĐOẠN CHỌN TƯỚNG (HERO DRAFT PHASE 1 -> 4)
    private IEnumerator StartDraftPhaseSequence()
    {
        draftSlots.Clear();

        if (pendingMatchedSlots != null && pendingMatchedSlots.Count == 4)
        {
            foreach (var s in pendingMatchedSlots)
            {
                bool seatIsAlly = IsTeamOneSeat(s.seatNumber);
                string title = s.isPlayer ? $"👤 {s.playerName} (BẠN)" : (seatIsAlly ? $"👤 {s.playerName} (ĐỒNG MINH)" : $"👤 {s.playerName} (ĐỐI THỦ)");
                draftSlots.Add(new DraftSlot
                {
                    seatNumber = s.seatNumber,
                    playerTitle = title,
                    userId = s.userId,
                    isPlayer = s.isPlayer,
                    isAlly = seatIsAlly,
                    isDragon = seatIsAlly,
                    isAI = s.isAI
                });
            }
            pendingMatchedSlots = null;
        }
        else
        {
            var seats = new List<int> { 1, 2, 3, 4 };
            string pName = !string.IsNullOrWhiteSpace(AuthUI.CurrentUserName) ? AuthUI.CurrentUserName : "Đại Tướng Quân";
            var usedNames = new HashSet<string> { pName };

            string allyName = AppwriteMatchmaking.GetRealisticGamerName(101, usedNames);
            string e1Name = AppwriteMatchmaking.GetRealisticGamerName(202, usedNames);
            string e2Name = AppwriteMatchmaking.GetRealisticGamerName(303, usedNames);

            draftSlots.Add(new DraftSlot { seatNumber = 1, playerTitle = $"👤 {pName} (BẠN)", isPlayer = true, isAlly = true, isDragon = true, isAI = false });
            draftSlots.Add(new DraftSlot { seatNumber = 2, playerTitle = $"👤 {allyName} (ĐỐI THỦ)", isPlayer = false, isAlly = false, isDragon = false, isAI = true });
            draftSlots.Add(new DraftSlot { seatNumber = 3, playerTitle = $"👤 {e1Name} (ĐỒNG MINH)", isPlayer = false, isAlly = true, isDragon = true, isAI = true });
            draftSlots.Add(new DraftSlot { seatNumber = 4, playerTitle = $"👤 {e2Name} (ĐỐI THỦ)", isPlayer = false, isAlly = false, isDragon = false, isAI = true });
        }

        draftSlots.Sort((a, b) => a.seatNumber.CompareTo(b.seatNumber));

        selectedHeroIds.Clear();
        BuildDraftScreenUI();

        var defaultInspect = availableHeroes.Count > 0 ? availableHeroes[0] : HeroDatabase100.GetHero(47);
        InspectHero(defaultInspect);

        yield return new WaitForSecondsRealtime(0.6f);

        if (isRoomHost)
        {
            // ═══════════════════════════════════════════════════════════════
            // [A] MÁY CHỦ TRUNG TÂM (HOST): ĐIỀU PHỐI ĐỒNG HỒ VÀ LƯỢT 1 -> 4
            // ═══════════════════════════════════════════════════════════════
            int[] lockedHeroIds = new int[4] { 0, 0, 0, 0 };

            for (int i = 0; i < draftSlots.Count; i++)
            {
                currentDraftPickerIndex = i;
                var slot = draftSlots[i];
                draftTimer = 40.0f;
                isDraftTimerRunning = true;
                UpdateDraftTurnStatus();

                // Phát sóng trạng thái khởi đầu của lượt này
                StartCoroutine(AppwriteMatchmaking.SendDraftHostState(new AppwriteMatchmaking.DraftHostStatePacket
                {
                    roomId = currentRoomId,
                    phase = "PICKING",
                    currentPickerIndex = i,
                    currentSeatNumber = slot.seatNumber,
                    timerLeft = draftTimer,
                    heroId1 = lockedHeroIds[0],
                    heroId2 = lockedHeroIds[1],
                    heroId3 = lockedHeroIds[2],
                    heroId4 = lockedHeroIds[3]
                }));

                float syncBroadcastTimer = 0f;

                int hostDraftSeq = 0;
                while (lockedHeroIds[i] == 0 && draftTimer > 0f)
                {
                    syncBroadcastTimer += 0.35f;
                    UpdateDraftTimerVisual();

                    // Đồng bộ đồng hồ tuần tự sang máy khách mỗi 0.7 giây
                    if (syncBroadcastTimer >= 0.7f)
                    {
                        syncBroadcastTimer = 0f;
                        yield return AppwriteMatchmaking.SendDraftHostState(new AppwriteMatchmaking.DraftHostStatePacket
                        {
                            roomId = currentRoomId,
                            seq = ++hostDraftSeq,
                            phase = "PICKING",
                            currentPickerIndex = i,
                            currentSeatNumber = slot.seatNumber,
                            timerLeft = draftTimer,
                            heroId1 = lockedHeroIds[0],
                            heroId2 = lockedHeroIds[1],
                            heroId3 = lockedHeroIds[2],
                            heroId4 = lockedHeroIds[3]
                        });
                    }

                    if (slot.isPlayer)
                    {
                        // 1. Lượt của Host (Người chơi chính trên máy chủ)
                        if (slot.chosenHero != null)
                        {
                            lockedHeroIds[i] = slot.chosenHero.id;
                            break;
                        }
                    }
                    else if (!slot.isAI)
                    {
                        // 2. Lượt của Guest (Người chơi khách trên máy khác): Host lắng nghe yêu cầu khóa tướng
                        if (!string.IsNullOrEmpty(currentRoomId))
                        {
                            yield return AppwriteMatchmaking.PollDraftPlayerActions(currentRoomId, (actions) =>
                            {
                                foreach (var act in actions)
                                {
                                    if (act.seatNumber == slot.seatNumber && act.requestedHeroId > 0 && !selectedHeroIds.Contains(act.requestedHeroId))
                                    {
                                        var h = HeroDatabase100.GetHero(act.requestedHeroId);
                                        if (h != null)
                                        {
                                            lockedHeroIds[i] = h.id;
                                            ChooseHeroForSlot(slot, h);
                                        }
                                    }
                                }
                            });
                        }
                        if (lockedHeroIds[i] > 0) break;
                    }
                    else
                    {
                        // 3. Lượt của Bot (AI): Host suy nghĩ 1.5s rồi tự động chọn
                        if (draftTimer <= 38.0f)
                        {
                            var aiPick = GetFirstAvailableCandidate();
                            lockedHeroIds[i] = aiPick.id;
                            ChooseHeroForSlot(slot, aiPick);
                            break;
                        }
                    }

                    yield return new WaitForSecondsRealtime(0.35f);
                }

                // Fallback nếu hết giờ mà chưa chọn
                if (lockedHeroIds[i] == 0)
                {
                    var fallbackPick = (inspectingHero != null && !selectedHeroIds.Contains(inspectingHero.id)) ? inspectingHero : GetFirstAvailableCandidate();
                    lockedHeroIds[i] = fallbackPick.id;
                    ChooseHeroForSlot(slot, fallbackPick);
                }

                isDraftTimerRunning = false;
                UpdateDraftTurnStatus();

                // Phát sóng trạng thái đã chọn của lượt này
                StartCoroutine(AppwriteMatchmaking.SendDraftHostState(new AppwriteMatchmaking.DraftHostStatePacket
                {
                    roomId = currentRoomId,
                    phase = "PICKING",
                    currentPickerIndex = i,
                    currentSeatNumber = slot.seatNumber,
                    timerLeft = 0f,
                    heroId1 = lockedHeroIds[0],
                    heroId2 = lockedHeroIds[1],
                    heroId3 = lockedHeroIds[2],
                    heroId4 = lockedHeroIds[3]
                }));

                yield return new WaitForSecondsRealtime(0.8f);
            }

            // [HOST PHASE 2]: ĐẾM NGƯỢC 5 GIÂY ĐỒNG BỘ CÙNG MÁY KHÁCH
            AudioManager.Instance.PlayVictory();

            for (int c = 5; c >= 1; c--)
            {
                StartCoroutine(AppwriteMatchmaking.SendDraftHostState(new AppwriteMatchmaking.DraftHostStatePacket
                {
                    roomId = currentRoomId,
                    phase = "COUNTDOWN",
                    currentPickerIndex = 3,
                    currentSeatNumber = 4,
                    timerLeft = 0f,
                    countdownSec = c,
                    heroId1 = lockedHeroIds[0],
                    heroId2 = lockedHeroIds[1],
                    heroId3 = lockedHeroIds[2],
                    heroId4 = lockedHeroIds[3]
                }));

                if (draftTurnStatusText != null)
                {
                    draftTurnStatusText.text = $"⚔️ CẢ 4 CHIẾN TƯỚNG ĐÃ SẴN SÀNG! VÀO TRẬN SAU <color=#FFD700><b>{c}s</b></color>...";
                }
                if (draftTimerText != null)
                {
                    draftTimerText.text = $"⚔️ {c}s";
                }
                if (draftTimerFill != null)
                {
                    draftTimerFill.rectTransform.anchorMax = new Vector2(c / 5.0f, 1f);
                }
                yield return new WaitForSecondsRealtime(1.0f);
            }

            // Phát lệnh bắt đầu trận đấu
            StartCoroutine(AppwriteMatchmaking.SendDraftHostState(new AppwriteMatchmaking.DraftHostStatePacket
            {
                roomId = currentRoomId,
                phase = "START_BATTLE",
                currentPickerIndex = 3,
                currentSeatNumber = 4,
                timerLeft = 0f,
                countdownSec = 0,
                heroId1 = lockedHeroIds[0],
                heroId2 = lockedHeroIds[1],
                heroId3 = lockedHeroIds[2],
                heroId4 = lockedHeroIds[3]
            }));
        }
        else
        {
            // ═══════════════════════════════════════════════════════════════
            // [B] MÁY KHÁCH (GUEST): ĐỒNG BỘ 100% THEO ĐỒNG HỒ & TRẠNG THÁI HOST
            // ═══════════════════════════════════════════════════════════════
            bool battleStarted = false;

            while (!battleStarted)
            {
                if (!string.IsNullOrEmpty(currentRoomId))
                {
                    yield return AppwriteMatchmaking.PollDraftHostState(currentRoomId, (hostState) =>
                    {
                        if (hostState != null && hostState.roomId == currentRoomId)
                        {
                            // 1. Cập nhật 4 tướng từ Host
                            int[] hIds = new int[] { hostState.heroId1, hostState.heroId2, hostState.heroId3, hostState.heroId4 };
                            for (int k = 0; k < 4 && k < draftSlots.Count; k++)
                            {
                                if (hIds[k] > 0 && (draftSlots[k].chosenHero == null || draftSlots[k].chosenHero.id != hIds[k]))
                                {
                                    var h = HeroDatabase100.GetHero(hIds[k]);
                                    if (h != null)
                                    {
                                        if (draftSlots[k].chosenHero != null) selectedHeroIds.Remove(draftSlots[k].chosenHero.id);
                                        ChooseHeroForSlot(draftSlots[k], h);
                                    }
                                }
                            }

                            // 2. Xử lý Phase từ Host
                            if (hostState.phase == "PICKING")
                            {
                                currentDraftPickerIndex = hostState.currentPickerIndex;
                                draftTimer = hostState.timerLeft;
                                isDraftTimerRunning = (draftTimer > 0f);
                                UpdateDraftTurnStatus();
                                UpdateDraftTimerVisual();
                            }
                            else if (hostState.phase == "COUNTDOWN")
                            {
                                isDraftTimerRunning = false;
                                int c = hostState.countdownSec;
                                if (draftTurnStatusText != null)
                                {
                                    draftTurnStatusText.text = $"⚔️ CẢ 4 CHIẾN TƯỚNG ĐÃ SẴN SÀNG! VÀO TRẬN SAU <color=#FFD700><b>{c}s</b></color>...";
                                }
                                if (draftTimerText != null)
                                {
                                    draftTimerText.text = $"⚔️ {c}s";
                                }
                                if (draftTimerFill != null)
                                {
                                    draftTimerFill.rectTransform.anchorMax = new Vector2(c / 5.0f, 1f);
                                }
                            }
                            else if (hostState.phase == "START_BATTLE")
                            {
                                battleStarted = true;
                            }
                        }
                    });
                }

                if (battleStarted) break;
                yield return new WaitForSecondsRealtime(0.25f);
            }
        }

        if (draftTurnStatusText != null)
        {
            draftTurnStatusText.text = "⚔️ XUẤT TRẬN!";
        }
        yield return new WaitForSecondsRealtime(0.4f);

        if (draftScreenGo != null) Destroy(draftScreenGo);
        StartBattleWithChosenHeroes();
    }

    private HeroDatabase100.HeroData GetFirstAvailableCandidate()
    {
        foreach (var h in availableHeroes)
        {
            if (!selectedHeroIds.Contains(h.id)) return h;
        }
        foreach (var h in HeroDatabase100.AllHeroes)
        {
            if (!selectedHeroIds.Contains(h.id)) return h;
        }
        return HeroDatabase100.GetHero(47);
    }

    private void EnsureAllSlotsHaveHeroes()
    {
        for (int k = 0; k < draftSlots.Count; k++)
        {
            if (draftSlots[k].chosenHero == null)
            {
                var pick = GetFirstAvailableCandidate();
                ChooseHeroForSlot(draftSlots[k], pick);
            }
        }
    }

    private void UnpackAllHeroesFromSync(string allHeroesJson)
    {
        if (string.IsNullOrEmpty(allHeroesJson)) return;
        try
        {
            string[] ids = allHeroesJson.Split(',');
            for (int k = 0; k < ids.Length && k < draftSlots.Count; k++)
            {
                if (int.TryParse(ids[k].Trim(), out int hId) && hId > 0)
                {
                    if (draftSlots[k].chosenHero == null || draftSlots[k].chosenHero.id != hId)
                    {
                        var hero = HeroDatabase100.GetHero(hId);
                        if (hero != null)
                        {
                            if (draftSlots[k].chosenHero != null) selectedHeroIds.Remove(draftSlots[k].chosenHero.id);
                            ChooseHeroForSlot(draftSlots[k], hero);
                        }
                    }
                }
            }
        }
        catch { }
    }

    private void BuildDraftScreenUI()
    {
        draftScreenGo = new GameObject("DraftScreenRoot", typeof(RectTransform));
        draftScreenGo.transform.SetParent(canvasGo.transform, false);
        Fill(draftScreenGo.GetComponent<RectTransform>());

        var headerGo = new GameObject("DraftHeader", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(draftScreenGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        hImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 56f), Vector2.zero);

        var titleTxt = AddText(headerGo.transform, "Title", "👑 ĐẠI VIỆT CHIẾN • CHỌN TƯỚNG 2v2", 18, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(titleTxt.rectTransform, new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(0f, 0.5f), new Vector2(340f, 36f), new Vector2(16f, 0f));

        draftTurnStatusText = AddText(headerGo.transform, "Status", "⏳ Đang chuẩn bị lượt chọn 1..4...", 17, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleCenter);
        draftTurnStatusText.horizontalOverflow = HorizontalWrapMode.Wrap;
        draftTurnStatusText.verticalOverflow = VerticalWrapMode.Truncate;
        SetRect(draftTurnStatusText.rectTransform, new Vector2(0.28f, 0.5f), new Vector2(0.82f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0f, 36f), Vector2.zero);

        var timerBoxGo = new GameObject("TimerBox", typeof(RectTransform), typeof(Image));
        timerBoxGo.transform.SetParent(headerGo.transform, false);
        var tbImg = timerBoxGo.GetComponent<Image>();
        tbImg.color = new Color(0.08f, 0.12f, 0.22f, 0.95f);
        var tbRt = timerBoxGo.GetComponent<RectTransform>();
        SetRect(tbRt, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(170f, 38f), new Vector2(-16f, 0f));

        var fillGo = new GameObject("Fill", typeof(RectTransform), typeof(Image));
        fillGo.transform.SetParent(timerBoxGo.transform, false);
        draftTimerFill = fillGo.GetComponent<Image>();
        draftTimerFill.color = new Color(1f, 0.8f, 0.2f, 1f);
        var fRt = fillGo.GetComponent<RectTransform>();
        fRt.anchorMin = Vector2.zero; fRt.anchorMax = Vector2.one;
        fRt.pivot = new Vector2(0f, 0.5f);
        fRt.offsetMin = fRt.offsetMax = Vector2.zero;

        var tTxtGo = new GameObject("Text", typeof(RectTransform), typeof(Text));
        tTxtGo.transform.SetParent(timerBoxGo.transform, false);
        draftTimerText = tTxtGo.GetComponent<Text>();
        draftTimerText.font = font;
        draftTimerText.fontSize = ThemeUI.SizeBodyLarge;
        draftTimerText.fontStyle = FontStyle.Bold;
        draftTimerText.alignment = TextAnchor.MiddleCenter;
        draftTimerText.color = Color.white;
        Fill(tTxtGo.GetComponent<RectTransform>());

        BuildDraftSlotsLeftColumn();
        BuildHeroGridCenterColumn();
        BuildHeroInspectRightColumn();
    }

    private void BuildDraftSlotsLeftColumn()
    {
        var leftColGo = new GameObject("LeftSlotsCol", typeof(RectTransform));
        leftColGo.transform.SetParent(draftScreenGo.transform, false);
        var lcRt = leftColGo.GetComponent<RectTransform>();
        SetRect(lcRt, new Vector2(0f, 0f), new Vector2(0f, 1f), new Vector2(0f, 0.5f), new Vector2(250f, -64f), new Vector2(16f, -32f));

        var titleTxt = AddText(leftColGo.transform, "Title", "⚔️ THỨ TỰ CHỌN (#1 ➜ #4):", ThemeUI.SizeBody, new Color(1f, 0.88f, 0.45f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(titleTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 26f), new Vector2(0f, -4f));

        float startY = -34f;
        for (int i = 0; i < draftSlots.Count; i++)
        {
            var slot = draftSlots[i];
            var sGo = new GameObject("Slot_" + i, typeof(RectTransform), typeof(Image));
            sGo.transform.SetParent(leftColGo.transform, false);
            var sImg = sGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { sImg.sprite = slotSpr; sImg.type = Image.Type.Sliced; }
            sImg.color = new Color(0.06f, 0.09f, 0.16f, 0.95f);

            var sRt = sGo.GetComponent<RectTransform>();
            SetRect(sRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 134f), new Vector2(0f, startY));
            startY -= 142f;

            slot.slotGo = sGo;

            var frameGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
            frameGo.transform.SetParent(sGo.transform, false);
            slot.frameImg = frameGo.GetComponent<Image>();
            var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (fSpr != null) { slot.frameImg.sprite = fSpr; slot.frameImg.type = Image.Type.Sliced; }
            slot.frameImg.color = slot.isAlly ? new Color(0.25f, 0.72f, 1f, 1f) : new Color(1f, 0.38f, 0.38f, 1f);
            var fRt = frameGo.GetComponent<RectTransform>();
            Fill(fRt, new Vector2(-1, -1), new Vector2(1, 1));

            var badgeTxt = AddText(sGo.transform, "Seat", $"#{slot.seatNumber}", ThemeUI.SizeBodyLarge, new Color(1f, 0.9f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft);
            SetRect(badgeTxt.rectTransform, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(50f, 26f), new Vector2(8f, -4f));

            string teamTag = slot.isDragon ? "<color=#55DDFF>[RỒNG]</color>" : "<color=#FF6666>[PHƯỢNG]</color>";
            var nameTxt = AddText(sGo.transform, "Title", $"{teamTag} {slot.playerTitle}", ThemeUI.SizeMicro, Color.white, FontStyle.Bold, TextAnchor.MiddleLeft);
            SetRect(nameTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-60f, 26f), new Vector2(50f, -4f));

            var avGo = new GameObject("Avatar", typeof(RectTransform), typeof(Image));
            avGo.transform.SetParent(sGo.transform, false);
            slot.avatarImg = avGo.GetComponent<Image>();
            slot.avatarImg.sprite = HeroDatabase100.GetAvatarSprite("UI/ly_thuong_kiet");
            slot.avatarImg.color = new Color(1f, 1f, 1f, 0.35f);
            var avRt = avGo.GetComponent<RectTransform>();
            SetRect(avRt, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(72f, 95f), new Vector2(8f, 8f));

            slot.heroNameText = AddText(sGo.transform, "HeroName", "Chưa chọn...", ThemeUI.SizeBodyLarge, new Color(1f, 0.88f, 0.4f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft);
            SetRect(slot.heroNameText.rectTransform, new Vector2(0f, 0.5f), new Vector2(1f, 0.5f), new Vector2(0f, 0.5f), new Vector2(-90f, 26f), new Vector2(88f, 12f));

            slot.statusText = AddText(sGo.transform, "Status", "Đang chờ lượt...", ThemeUI.SizeMicro, new Color(0.7f, 0.8f, 0.9f, 0.85f), FontStyle.Italic, TextAnchor.MiddleLeft);
            SetRect(slot.statusText.rectTransform, new Vector2(0f, 0.5f), new Vector2(1f, 0.5f), new Vector2(0f, 0.5f), new Vector2(-90f, 22f), new Vector2(88f, -14f));
        }
    }

    private void BuildHeroGridCenterColumn()
    {
        var centerColGo = new GameObject("CenterGridCol", typeof(RectTransform));
        centerColGo.transform.SetParent(draftScreenGo.transform, false);
        var ccRt = centerColGo.GetComponent<RectTransform>();
        SetRect(ccRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), new Vector2(-640f, -68f), new Vector2(-30f, -28f));

        var subTxt = AddText(centerColGo.transform, "Sub", $"🎴 <b>DANH TƯỚNG KHẢ DỤNG ({availableHeroes.Count} TƯỚNG SỞ HỮU & FREE TUẦN)</b> • Chạm thẻ để xem tuyệt kỹ:", ThemeUI.SizeBody, new Color(0.9f, 0.95f, 1f, 0.95f), FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(subTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(0f, 26f), new Vector2(0f, 0f));

        var scrollGo = new GameObject("HeroesScrollView", typeof(RectTransform), typeof(Image), typeof(RectMask2D), typeof(ScrollRect));
        scrollGo.transform.SetParent(centerColGo.transform, false);
        var sRt = scrollGo.GetComponent<RectTransform>();
        SetRect(sRt, new Vector2(0f, 0f), new Vector2(1f, 1f), new Vector2(0.5f, 0.5f), new Vector2(0f, -32f), new Vector2(0f, -16f));

        var sImg = scrollGo.GetComponent<Image>();
        sImg.color = new Color(0.02f, 0.04f, 0.08f, 0.5f);

        var scroll = scrollGo.GetComponent<ScrollRect>();
        scroll.horizontal = false;
        scroll.vertical = true;
        scroll.movementType = ScrollRect.MovementType.Clamped;
        scroll.scrollSensitivity = 35f;

        var contentGo = new GameObject("Content", typeof(RectTransform), typeof(GridLayoutGroup), typeof(ContentSizeFitter));
        contentGo.transform.SetParent(scrollGo.transform, false);
        var cRt = contentGo.GetComponent<RectTransform>();
        cRt.anchorMin = new Vector2(0f, 1f);
        cRt.anchorMax = new Vector2(1f, 1f);
        cRt.pivot = new Vector2(0.5f, 1f);
        cRt.offsetMin = cRt.offsetMax = Vector2.zero;

        var glg = contentGo.GetComponent<GridLayoutGroup>();
        glg.cellSize = new Vector2(142f, 190f);
        glg.spacing = new Vector2(10f, 10f);
        glg.padding = new RectOffset(6, 6, 6, 6);
        glg.childAlignment = TextAnchor.UpperLeft;

        var csf = contentGo.GetComponent<ContentSizeFitter>();
        csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

        scroll.viewport = sRt;
        scroll.content = cRt;

        heroGridItems.Clear();
        foreach (var hero in availableHeroes)
        {
            var hCardGo = CreateCombatStyleHeroCardItem(contentGo.transform, hero);
            heroGridItems[hero.id] = hCardGo;
        }
    }

    private GameObject CreateCombatStyleHeroCardItem(Transform parent, HeroDatabase100.HeroData hero)
    {
        var cardGo = new GameObject("HeroCard_" + hero.id, typeof(RectTransform), typeof(Image), typeof(Button));
        cardGo.transform.SetParent(parent, false);

        var cImg = cardGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSpr != null) { cImg.sprite = bgSpr; cImg.type = Image.Type.Sliced; }
        cImg.color = new Color(0.06f, 0.09f, 0.16f, 0.98f);

        bool isFree = weeklyFreeHeroIds.Contains(hero.id);

        var frameGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        frameGo.transform.SetParent(cardGo.transform, false);
        var fImg = frameGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = isFree ? new Color(1f, 0.85f, 0.35f, 1f) : new Color(0.35f, 0.7f, 0.95f, 0.9f);
        Fill(frameGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var avGo = new GameObject("Avatar", typeof(RectTransform), typeof(Image));
        avGo.transform.SetParent(cardGo.transform, false);
        var avImg = avGo.GetComponent<Image>();
        avImg.sprite = HeroDatabase100.GetAvatarSprite(hero.avatarPath);
        avImg.preserveAspect = true;
        Fill(avGo.GetComponent<RectTransform>(), new Vector2(4, 4), new Vector2(-4, -4));

        var gradBottom = new GameObject("GradBottom", typeof(RectTransform), typeof(Image));
        gradBottom.transform.SetParent(cardGo.transform, false);
        var gbImg = gradBottom.GetComponent<Image>();
        gbImg.color = new Color(0.02f, 0.04f, 0.08f, 0.85f);
        var gbRt = gradBottom.GetComponent<RectTransform>();
        SetRect(gbRt, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0.5f, 0f), new Vector2(0f, 48f), Vector2.zero);

        var gradTop = new GameObject("GradTop", typeof(RectTransform), typeof(Image));
        gradTop.transform.SetParent(cardGo.transform, false);
        var gtImg = gradTop.GetComponent<Image>();
        gtImg.color = new Color(0.02f, 0.04f, 0.08f, 0.85f);
        var gtRt = gradTop.GetComponent<RectTransform>();
        SetRect(gtRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 26f), Vector2.zero);

        var npGo = new GameObject("NamePlaque", typeof(RectTransform), typeof(Image));
        npGo.transform.SetParent(cardGo.transform, false);
        var npImg = npGo.GetComponent<Image>();
        var npSpr = LotusHealthUI.LoadSpriteFromResources("UI/name_plaque");
        if (npSpr != null) { npImg.sprite = npSpr; npImg.type = Image.Type.Sliced; }
        npImg.color = new Color(0.12f, 0.08f, 0.05f, 0.95f);
        var npRt = npGo.GetComponent<RectTransform>();
        SetRect(npRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(-12f, 24f), new Vector2(0f, -4f));

        var nameTxt = AddText(npGo.transform, "Name", hero.name, ThemeUI.SizeMicro, new Color(1f, 0.92f, 0.45f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(nameTxt.rectTransform);

        var hpContainer = new GameObject("LotusHpRow", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        hpContainer.transform.SetParent(cardGo.transform, false);
        var hpRt = hpContainer.GetComponent<RectTransform>();
        SetRect(hpRt, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(60f, 18f), new Vector2(-6f, -28f));
        var hlg = hpContainer.GetComponent<HorizontalLayoutGroup>();
        hlg.childAlignment = TextAnchor.MiddleRight;
        hlg.spacing = 2f;
        hlg.childControlWidth = hlg.childControlHeight = false;

        var lotusSpr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_full");
        for (int i = 0; i < hero.maxHp; i++)
        {
            var lGo = new GameObject("Lotus_" + i, typeof(RectTransform), typeof(Image));
            lGo.transform.SetParent(hpContainer.transform, false);
            var lImg = lGo.GetComponent<Image>();
            if (lotusSpr != null) lImg.sprite = lotusSpr;
            lImg.color = new Color(1f, 0.45f, 0.65f, 1f);
            var lRt = lGo.GetComponent<RectTransform>();
            lRt.sizeDelta = new Vector2(14f, 14f);
        }

        var facGo = new GameObject("FactionBadge", typeof(RectTransform), typeof(Image));
        facGo.transform.SetParent(cardGo.transform, false);
        var fbgImg = facGo.GetComponent<Image>();
        var facSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (facSpr != null) { fbgImg.sprite = facSpr; fbgImg.type = Image.Type.Sliced; }
        fbgImg.color = new Color(0.1f, 0.2f, 0.35f, 0.95f);
        var facRt = facGo.GetComponent<RectTransform>();
        SetRect(facRt, new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(0f, 0f), new Vector2(68f, 20f), new Vector2(6f, 26f));

        var facTxt = AddText(facGo.transform, "Txt", hero.faction, ThemeUI.SizeMicro, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(facTxt.rectTransform);

        var skillBarGo = new GameObject("SkillBar", typeof(RectTransform), typeof(Image));
        skillBarGo.transform.SetParent(cardGo.transform, false);
        var sbImg = skillBarGo.GetComponent<Image>();
        if (bgSpr != null) { sbImg.sprite = bgSpr; sbImg.type = Image.Type.Sliced; }
        sbImg.color = new Color(0.08f, 0.14f, 0.24f, 0.95f);
        var sbRt = skillBarGo.GetComponent<RectTransform>();
        SetRect(sbRt, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0.5f, 0f), new Vector2(-12f, 22f), new Vector2(0f, 4f));

        var skillTxt = AddText(skillBarGo.transform, "Skill", $"⚡ {hero.skillName}", ThemeUI.SizeMicro, new Color(0.4f, 0.92f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(skillTxt.rectTransform);

        if (isFree)
        {
            var freeBadgeGo = new GameObject("FreeWeekBadge", typeof(RectTransform), typeof(Image));
            freeBadgeGo.transform.SetParent(cardGo.transform, false);
            var fbImg = freeBadgeGo.GetComponent<Image>();
            if (bgSpr != null) { fbImg.sprite = bgSpr; fbImg.type = Image.Type.Sliced; }
            fbImg.color = new Color(0.75f, 0.55f, 0.1f, 0.98f);
            var fbRt = freeBadgeGo.GetComponent<RectTransform>();
            SetRect(fbRt, new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(1f, 0f), new Vector2(50f, 20f), new Vector2(-6f, 26f));

            var fbTxt = AddText(freeBadgeGo.transform, "Txt", "FREE", ThemeUI.SizeMicro, new Color(1f, 0.92f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(fbTxt.rectTransform);
        }

        var btn = cardGo.GetComponent<Button>();
        btn.onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            InspectHero(hero);
        });

        return cardGo;
    }

    private void BuildHeroInspectRightColumn()
    {
        draftInspectPanelGo = new GameObject("RightInspectCol", typeof(RectTransform), typeof(Image));
        draftInspectPanelGo.transform.SetParent(draftScreenGo.transform, false);
        var ipImg = draftInspectPanelGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSpr != null) { ipImg.sprite = bgSpr; ipImg.type = Image.Type.Sliced; }
        ipImg.color = new Color(0.06f, 0.1f, 0.18f, 0.98f);

        var ipRt = draftInspectPanelGo.GetComponent<RectTransform>();
        SetRect(ipRt, new Vector2(1f, 0f), new Vector2(1f, 1f), new Vector2(1f, 0.5f), new Vector2(340f, -68f), new Vector2(-16f, -28f));

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(draftInspectPanelGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.35f, 1f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        inspectTitleText = AddText(draftInspectPanelGo.transform, "Title", "LÝ THƯỜNG KIỆT", ThemeUI.SizeTitleLarge, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(inspectTitleText.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(310f, 32f), new Vector2(0f, -12f));

        inspectSubText = AddText(draftInspectPanelGo.transform, "Sub", "Thế Lực: Thời Lý • Máu: 4 đóa sen", ThemeUI.SizeBody, new Color(0.8f, 0.9f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(inspectSubText.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(310f, 24f), new Vector2(0f, -44f));

        var avGo = new GameObject("InspectAvatar", typeof(RectTransform), typeof(Image));
        avGo.transform.SetParent(draftInspectPanelGo.transform, false);
        inspectAvatarImg = avGo.GetComponent<Image>();
        inspectAvatarImg.sprite = HeroDatabase100.GetAvatarSprite("UI/ly_thuong_kiet");
        inspectAvatarImg.preserveAspect = true;
        var avRt = avGo.GetComponent<RectTransform>();
        SetRect(avRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(120f, 155f), new Vector2(0f, -70f));

        var avFrame = new GameObject("AvFrame", typeof(RectTransform), typeof(Image));
        avFrame.transform.SetParent(avGo.transform, false);
        var avfImg = avFrame.GetComponent<Image>();
        if (fSpr != null) { avfImg.sprite = fSpr; avfImg.type = Image.Type.Sliced; }
        avfImg.color = new Color(1f, 0.85f, 0.35f, 0.9f);
        Fill(avFrame.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var hpRowGo = new GameObject("LotusContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        hpRowGo.transform.SetParent(draftInspectPanelGo.transform, false);
        var hrRt = hpRowGo.GetComponent<RectTransform>();
        SetRect(hrRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(180f, 24f), new Vector2(0f, -232f));
        var hlg = hpRowGo.GetComponent<HorizontalLayoutGroup>();
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.spacing = 6f;
        hlg.childControlWidth = hlg.childControlHeight = false;
        inspectLotusContainer = hpRowGo.transform;

        var skillBoxGo = new GameObject("SkillBox", typeof(RectTransform), typeof(Image));
        skillBoxGo.transform.SetParent(draftInspectPanelGo.transform, false);
        var sbImg = skillBoxGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { sbImg.sprite = slotSpr; sbImg.type = Image.Type.Sliced; }
        sbImg.color = new Color(0.04f, 0.07f, 0.14f, 0.95f);
        var sbRt = skillBoxGo.GetComponent<RectTransform>();
        SetRect(sbRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(315f, 290f), new Vector2(0f, -260f));

        inspectSkillTitleText = AddText(skillBoxGo.transform, "SkillTitle", "⚡ TUYỆT KỸ: [TIẾN THOÁI]", ThemeUI.SizeTitleMedium, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(inspectSkillTitleText.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0f, 1f), new Vector2(-16f, 30f), new Vector2(10f, -8f));

        inspectSkillDescText = AddText(skillBoxGo.transform, "SkillDesc", "Bạn có thể sử dụng lá Trảm như lá Đỡ, và sử dụng lá Đỡ như lá Trảm.", ThemeUI.SizeBody, new Color(0.9f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.UpperLeft);
        inspectSkillDescText.lineSpacing = 1.35f;
        Fill(inspectSkillDescText.rectTransform, new Vector2(10f, 8f), new Vector2(-10f, -38f));

        var confirmBtnGo = new GameObject("DraftConfirmBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        confirmBtnGo.transform.SetParent(draftInspectPanelGo.transform, false);
        var cbImg = confirmBtnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { cbImg.sprite = btnSpr; cbImg.type = Image.Type.Sliced; }
        cbImg.color = new Color(0.9f, 0.65f, 0.15f, 1f);

        var cbRt = confirmBtnGo.GetComponent<RectTransform>();
        SetRect(cbRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(300f, 52f), new Vector2(0f, 18f));

        draftConfirmBtn = confirmBtnGo.GetComponent<Button>();
        draftConfirmBtnText = AddText(confirmBtnGo.transform, "Txt", "👑 XÁC NHẬN CHỌN TƯỚNG", ThemeUI.SizeTitleMedium, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(draftConfirmBtnText.rectTransform);

        draftConfirmBtn.onClick.AddListener(() =>
        {
            if (currentDraftPickerIndex < draftSlots.Count && draftSlots[currentDraftPickerIndex].isPlayer)
            {
                var slot = draftSlots[currentDraftPickerIndex];
                if (slot.chosenHero == null && inspectingHero != null && !selectedHeroIds.Contains(inspectingHero.id))
                {
                    AudioManager.Instance.PlayCardSelect();
                    if (isRoomHost)
                    {
                        // Host tự ghi nhận trực tiếp
                        ChooseHeroForSlot(slot, inspectingHero);
                        InspectHero(inspectingHero);
                        UpdateDraftTurnStatus();
                    }
                    else
                    {
                        // Guest gửi yêu cầu khóa tướng lên cho Host xử lý
                        draftConfirmBtn.interactable = false;
                        draftConfirmBtnText.text = "⏳ ĐANG GỬI KHÓA TƯỚNG...";
                        if (!string.IsNullOrEmpty(currentRoomId))
                        {
                            StartCoroutine(AppwriteMatchmaking.SendDraftPlayerAction(new AppwriteMatchmaking.DraftPlayerActionPacket
                            {
                                roomId = currentRoomId,
                                senderUserId = AuthUI.CurrentUserEmail,
                                seatNumber = slot.seatNumber,
                                requestedHeroId = inspectingHero.id
                            }));
                        }
                    }
                }
            }
        });
    }

    private void InspectHero(HeroDatabase100.HeroData hero)
    {
        if (hero == null || draftInspectPanelGo == null) return;
        inspectingHero = hero;

        if (inspectTitleText != null) inspectTitleText.text = hero.name.ToUpper();

        string freeTag = weeklyFreeHeroIds.Contains(hero.id) ? " <color=#FFD700>[🌟 FREE TUẦN]</color>" : " <color=#55DDFF>[ĐÃ SỞ HỮU]</color>";
        if (inspectSubText != null) inspectSubText.text = $"Thế Lực: <b>{hero.faction}</b> • Máu: <b>{hero.maxHp} đóa sen</b>{freeTag}";

        if (inspectAvatarImg != null) inspectAvatarImg.sprite = HeroDatabase100.GetAvatarSprite(hero.avatarPath);

        if (inspectLotusContainer != null)
        {
            for (int i = inspectLotusContainer.childCount - 1; i >= 0; i--)
            {
                Destroy(inspectLotusContainer.GetChild(i).gameObject);
            }
            var lotusSpr = LotusHealthUI.LoadSpriteFromResources("UI/lotus_full");
            for (int i = 0; i < hero.maxHp; i++)
            {
                var lGo = new GameObject("Lotus_" + i, typeof(RectTransform), typeof(Image));
                lGo.transform.SetParent(inspectLotusContainer, false);
                var lImg = lGo.GetComponent<Image>();
                if (lotusSpr != null) lImg.sprite = lotusSpr;
                lImg.color = new Color(1f, 0.45f, 0.65f, 1f);
                var lRt = lGo.GetComponent<RectTransform>();
                lRt.sizeDelta = new Vector2(16f, 16f);
            }
        }

        if (inspectSkillTitleText != null) inspectSkillTitleText.text = $"⚡ TUYỆT KỸ: [{hero.skillName.ToUpper()}]";
        if (inspectSkillDescText != null) inspectSkillDescText.text = hero.skillDesc;

        bool isCurrentTurnMyTurn = (currentDraftPickerIndex < draftSlots.Count && draftSlots[currentDraftPickerIndex].isPlayer);
        bool isHeroAlreadyTaken = selectedHeroIds.Contains(hero.id);
        bool myHeroAlreadyLocked = (draftSlots.Exists(s => s.isPlayer && s.chosenHero != null));

        if (draftConfirmBtn != null)
        {
            if (myHeroAlreadyLocked)
            {
                var mySlot = draftSlots.Find(s => s.isPlayer);
                draftConfirmBtn.interactable = false;
                draftConfirmBtnText.text = $"✅ BẠN ĐÃ KHÓA: {mySlot?.chosenHero?.name?.ToUpper()}";
            }
            else if (isHeroAlreadyTaken)
            {
                draftConfirmBtn.interactable = false;
                draftConfirmBtnText.text = "🔒 TƯỚNG NÀY ĐÃ ĐƯỢC CHỌN";
            }
            else if (!isCurrentTurnMyTurn)
            {
                draftConfirmBtn.interactable = false;
                int currentSeat = (currentDraftPickerIndex < draftSlots.Count) ? draftSlots[currentDraftPickerIndex].seatNumber : 1;
                draftConfirmBtnText.text = $"⏳ ĐANG ĐỢI GHẾ #{currentSeat} CHỌN TƯỚNG...";
            }
            else
            {
                draftConfirmBtn.interactable = true;
                draftConfirmBtnText.text = "👑 XÁC NHẬN CHỌN TƯỚNG";
            }
        }
    }

    private void ChooseHeroForSlot(DraftSlot slot, HeroDatabase100.HeroData hero)
    {
        if (slot == null || hero == null || selectedHeroIds.Contains(hero.id)) return;

        slot.chosenHero = hero;
        selectedHeroIds.Add(hero.id);

        if (slot.heroNameText != null) slot.heroNameText.text = $"👑 {hero.name}";
        if (slot.statusText != null) slot.statusText.text = $"Đã chọn ({hero.maxHp}💮)";
        if (slot.avatarImg != null)
        {
            slot.avatarImg.sprite = HeroDatabase100.GetAvatarSprite(hero.avatarPath);
            slot.avatarImg.color = Color.white;
        }

        if (heroGridItems.TryGetValue(hero.id, out var itemGo) && itemGo != null)
        {
            var overlayGo = new GameObject("ChosenOverlay", typeof(RectTransform), typeof(Image));
            overlayGo.transform.SetParent(itemGo.transform, false);
            var oImg = overlayGo.GetComponent<Image>();
            oImg.color = new Color(0.04f, 0.05f, 0.08f, 0.78f);
            Fill(overlayGo.GetComponent<RectTransform>());

            var btn = itemGo.GetComponent<Button>();
            if (btn != null) btn.interactable = false;

            var chosenTag = AddText(overlayGo.transform, "ChosenTag", "🔒 ĐÃ CHỌN", 12, new Color(1f, 0.35f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(chosenTag.rectTransform);
        }

        if (inspectingHero != null && inspectingHero.id == hero.id)
        {
            InspectHero(hero);
        }
    }

    private void UpdateDraftTurnStatus()
    {
        if (currentDraftPickerIndex >= draftSlots.Count) return;
        var activeSlot = draftSlots[currentDraftPickerIndex];

        for (int i = 0; i < draftSlots.Count; i++)
        {
            var s = draftSlots[i];
            if (s.chosenHero != null)
            {
                if (s.statusText != null)
                {
                    s.statusText.text = $"✅ Đã chọn: {s.chosenHero.name}";
                    s.statusText.color = new Color(0.4f, 1f, 0.4f, 1f);
                }
            }
            else
            {
                if (s == activeSlot)
                {
                    if (s.statusText != null)
                    {
                        s.statusText.text = s.isPlayer ? "<color=#FFFF55>👉 Bạn đang chọn...</color>" : "<color=#FFFF55>👉 Đang chọn tướng...</color>";
                        s.statusText.color = new Color(1f, 0.95f, 0.4f, 1f);
                    }
                }
                else
                {
                    if (s.statusText != null)
                    {
                        s.statusText.text = "Chờ đến lượt...";
                        s.statusText.color = new Color(0.6f, 0.7f, 0.85f, 0.8f);
                    }
                }
            }
        }

        if (draftTurnStatusText != null)
        {
            string pickerName = activeSlot.isPlayer ? "<color=#FFFF55>BẠN (Người Chơi)</color>" : activeSlot.playerTitle;
            draftTurnStatusText.text = $"👑 LƯỢT #{activeSlot.seatNumber}: {pickerName} ĐANG CHỌN TƯỚNG!";
        }

        if (inspectingHero != null) InspectHero(inspectingHero);
    }

    private void UpdateDraftTimerVisual()
    {
        float ratio = Mathf.Clamp01(draftTimer / 40.0f);
        if (draftTimerFill != null) draftTimerFill.rectTransform.anchorMax = new Vector2(ratio, 1f);
        if (draftTimerText != null) draftTimerText.text = $"⏳ {draftTimer:0.0}s / 40s";
    }

    private void OnDraftTimerExpired()
    {
        if (currentDraftPickerIndex < draftSlots.Count)
        {
            var slot = draftSlots[currentDraftPickerIndex];
            if (slot.chosenHero == null)
            {
                HeroDatabase100.HeroData pick = null;
                if (inspectingHero != null && !selectedHeroIds.Contains(inspectingHero.id))
                {
                    pick = inspectingHero;
                }
                else
                {
                    foreach (var h in availableHeroes)
                    {
                        if (!selectedHeroIds.Contains(h.id))
                        {
                            pick = h;
                            break;
                        }
                    }
                }
                if (pick != null) ChooseHeroForSlot(slot, pick);
            }
        }
    }
    #endregion

    #region 3. KHỞI TẠO BÀN CHIẾN ĐẤU 2v2 VỚI TƯỚNG ĐÃ CHỌN
    private void StartBattleWithChosenHeroes()
    {
        battleRootGo = new GameObject("Battle2v2BattleRoot", typeof(RectTransform));
        battleRootGo.transform.SetParent(canvasGo.transform, false);
        Fill(battleRootGo.GetComponent<RectTransform>());

        BuildHeaderBar();
        BuildFourGenerals();
        BuildPlayerHandArea();
        BuildLogAndStatusArea();
        BuildDeckStatusHUD();

        StartGameStateSync();
        StartCoroutine(StartBattleCardDealSequence());
    }

    private void BuildHeaderBar()
    {
        var headerGo = new GameObject("HeaderBar", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(battleRootGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        hImg.color = new Color(0.04f, 0.07f, 0.14f, 0.95f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(0f, 48f), Vector2.zero);

        var homeBtnGo = new GameObject("HomeBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        homeBtnGo.transform.SetParent(headerGo.transform, false);
        var hbImg = homeBtnGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { hbImg.sprite = slotSpr; hbImg.type = Image.Type.Sliced; }
        hbImg.color = new Color(0.2f, 0.12f, 0.08f, 0.95f);
        var hbRt = homeBtnGo.GetComponent<RectTransform>();
        hbRt.anchorMin = hbRt.anchorMax = hbRt.pivot = new Vector2(0f, 0.5f);
        hbRt.sizeDelta = new Vector2(160f, 38f);
        hbRt.anchoredPosition = new Vector2(12f, 0f);

        var hbTxt = AddText(homeBtnGo.transform, "Txt", "🏠 VỀ TRANG CHỦ", ThemeUI.SizeMicro, new Color(1f, 0.88f, 0.4f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(hbTxt.rectTransform);
        homeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            ConfirmExitBattle();
        });

        var titleTxt = AddText(headerGo.transform, "Title", "🛡️ ĐẤU TRƯỜNG 2v2 XẾP HẠNG (PHỐI HỢP ĐỒNG MINH)", ThemeUI.SizeTitleMedium, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(560f, 32f), Vector2.zero);

        var turnTxt = AddText(headerGo.transform, "GlobalTurn", "⏳ Đang chuẩn bị chia bài...", ThemeUI.SizeBody, new Color(0.6f, 0.9f, 1f, 1f), FontStyle.Bold, TextAnchor.MiddleRight);
        SetRect(turnTxt.rectTransform, new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(1f, 0.5f), new Vector2(300f, 32f), new Vector2(-16f, 0f));
        globalTurnText = turnTxt;
    }

    private static bool IsTeamOneSeat(int seat)
    {
        return seat == 1 || seat == 3;
    }

    private static bool IsSameTeamSeat(int leftSeat, int rightSeat)
    {
        return IsTeamOneSeat(leftSeat) == IsTeamOneSeat(rightSeat);
    }

    private void BuildFourGenerals()
    {
        var genContainer = new GameObject("GeneralsContainer", typeof(RectTransform));
        genContainer.transform.SetParent(battleRootGo.transform, false);
        Fill(genContainer.GetComponent<RectTransform>());

        Vector2 cardSize = new Vector2(190f, 252f);

        DraftSlot pSlot = draftSlots.Find(s => s.isPlayer) ?? draftSlots[0];
        int mySeat = pSlot.seatNumber;
        bool pIsDragon = IsTeamOneSeat(mySeat);

        // Team identity is authoritative by seat: 1/3 versus 2/4.
        DraftSlot aSlot = draftSlots.Find(s => IsSameTeamSeat(s.seatNumber, mySeat) && s.seatNumber != mySeat)
            ?? draftSlots.Find(s => s.seatNumber != mySeat);
        int allySeat = aSlot.seatNumber;
        bool aIsDragon = IsTeamOneSeat(allySeat);

        // The other two seats are always opponents in 2v2.
        var enemySlots = draftSlots.FindAll(s => !IsSameTeamSeat(s.seatNumber, mySeat));
        DraftSlot e1Slot = enemySlots.Count > 0 ? enemySlots[0] : draftSlots[2];
        DraftSlot e2Slot = enemySlots.Count > 1 ? enemySlots[1] : draftSlots[3];

        HeroDatabase100.HeroData pHero = pSlot.chosenHero ?? HeroDatabase100.GetHero(47);
        HeroDatabase100.HeroData aHero = aSlot.chosenHero ?? HeroDatabase100.GetHero(53);
        HeroDatabase100.HeroData e1Hero = e1Slot.chosenHero ?? HeroDatabase100.GetHero(1);
        HeroDatabase100.HeroData e2Hero = e2Slot.chosenHero ?? HeroDatabase100.GetHero(2);

        bool e1IsDragon = IsTeamOneSeat(e1Slot.seatNumber);
        bool e2IsDragon = IsTeamOneSeat(e2Slot.seatNumber);

        // 1. NGƯỜI CHƠI (BẠN)
        playerCard = GeneralCardUI.Create(genContainer.transform, cardSize, pHero.name, pIsDragon ? "PHE RỒNG" : "PHE PHƯỢNG", pHero.maxHp, 4, pHero.avatarPath);
        var pRt = playerCard.GetComponent<RectTransform>();
        pRt.anchorMin = new Vector2(1f, 0f);
        pRt.anchorMax = new Vector2(1f, 0f);
        pRt.pivot = new Vector2(1f, 0f);
        pRt.sizeDelta = cardSize;
        pRt.anchoredPosition = new Vector2(-18f, 18f);
        playerCard.SetTeamVisual(pIsDragon);
        playerCard.SetSeatBadge(mySeat);
        playerCard.IsPlayer = true;
        playerCard.IsAlly = IsSameTeamSeat(mySeat, mySeat);
        playerCard.IsAI = false;
        playerCard.UserId = pSlot.userId;
        playerCard.HeroId = pHero.id.ToString();
        playerCard.GeneralName = pHero.name;
        playerCard.OnGeneralClicked += OnGeneralTargetClicked;

        // 2. ĐỒNG ĐỘI
        allyCard = GeneralCardUI.Create(genContainer.transform, cardSize, aHero.name, aIsDragon ? "PHE RỒNG" : "PHE PHƯỢNG", aHero.maxHp, 4, aHero.avatarPath);
        allyCard.SetTeamVisual(aIsDragon);
        allyCard.SetSeatBadge(allySeat);
        allyCard.IsPlayer = false;
        allyCard.IsAlly = IsSameTeamSeat(allySeat, mySeat);
        allyCard.IsAI = aSlot.isAI;
        allyCard.UserId = aSlot.userId;
        allyCard.HeroId = aHero.id.ToString();
        allyCard.GeneralName = aHero.name;
        allyCard.OnGeneralClicked += OnGeneralTargetClicked;

        // 3. ĐỐI THỦ 1
        enemy1Card = GeneralCardUI.Create(genContainer.transform, cardSize, e1Hero.name, e1IsDragon ? "PHE RỒNG" : "PHE PHƯỢNG", e1Hero.maxHp, 4, e1Hero.avatarPath);
        enemy1Card.SetTeamVisual(e1IsDragon);
        enemy1Card.SetSeatBadge(e1Slot.seatNumber);
        enemy1Card.IsPlayer = false;
        enemy1Card.IsAlly = IsSameTeamSeat(e1Slot.seatNumber, mySeat);
        enemy1Card.IsAI = e1Slot.isAI;
        enemy1Card.UserId = e1Slot.userId;
        enemy1Card.HeroId = e1Hero.id.ToString();
        enemy1Card.GeneralName = e1Hero.name;
        enemy1Card.OnGeneralClicked += OnGeneralTargetClicked;

        // 4. ĐỐI THỦ 2
        enemy2Card = GeneralCardUI.Create(genContainer.transform, cardSize, e2Hero.name, e2IsDragon ? "PHE RỒNG" : "PHE PHƯỢNG", e2Hero.maxHp, 4, e2Hero.avatarPath);
        enemy2Card.SetTeamVisual(e2IsDragon);
        enemy2Card.SetSeatBadge(e2Slot.seatNumber);
        enemy2Card.IsPlayer = false;
        enemy2Card.IsAlly = IsSameTeamSeat(e2Slot.seatNumber, mySeat);
        enemy2Card.IsAI = e2Slot.isAI;
        enemy2Card.UserId = e2Slot.userId;
        enemy2Card.HeroId = e2Hero.id.ToString();
        enemy2Card.GeneralName = e2Hero.name;
        enemy2Card.OnGeneralClicked += OnGeneralTargetClicked;

        allGenerals.Clear();
        allGenerals.Add(playerCard);
        allGenerals.Add(allyCard);
        allGenerals.Add(enemy1Card);
        allGenerals.Add(enemy2Card);

        int playerSeat = playerCard.SeatNumber;
        foreach (var g in allGenerals)
        {
            if (g == playerCard) continue;

            int offset = (g.SeatNumber - playerSeat + 4) % 4;
            var gRt = g.GetComponent<RectTransform>();
            gRt.anchorMin = new Vector2(0.5f, 0.5f);
            gRt.anchorMax = new Vector2(0.5f, 0.5f);
            gRt.pivot = new Vector2(0.5f, 0.5f);
            gRt.sizeDelta = cardSize;

            if (offset == 1)
            {
                gRt.anchoredPosition = new Vector2(360f, 185f);
            }
            else if (offset == 2)
            {
                gRt.anchoredPosition = new Vector2(-80f, 185f);
            }
            else
            {
                gRt.anchoredPosition = new Vector2(-510f, -40f);
            }
        }
    }

    private void BuildPlayerHandArea()
    {
        var handRootGo = new GameObject("HandAreaRoot", typeof(RectTransform));
        handRootGo.transform.SetParent(battleRootGo.transform, false);
        var hrRt = handRootGo.GetComponent<RectTransform>();
        hrRt.anchorMin = new Vector2(0.5f, 0f);
        hrRt.anchorMax = new Vector2(0.5f, 0f);
        hrRt.pivot = new Vector2(0.5f, 0f);
        hrRt.sizeDelta = new Vector2(1280f, 260f);
        hrRt.anchoredPosition = Vector2.zero;

        var phGo = new GameObject("PlayerHandUI", typeof(RectTransform), typeof(PlayerHandUI));
        phGo.transform.SetParent(handRootGo.transform, false);
        playerHandUI = phGo.GetComponent<PlayerHandUI>();
        playerHandUI.BindHeroCard(playerCard);
        var phRt = phGo.GetComponent<RectTransform>();
        phRt.anchorMin = new Vector2(0.5f, 0f);
        phRt.anchorMax = new Vector2(0.5f, 0f);
        phRt.pivot = new Vector2(0.5f, 0f);
        phRt.sizeDelta = new Vector2(640f, 175f);
        phRt.anchoredPosition = new Vector2(-80f, 18f);
        playerHandUI.OnCardSelected += HandlePlayerCardSelected;

        // 1. Hộp Mô Tả Chi Tiết Lá Bài (Nằm cao ở y = 198f để không bao giờ che bài trên tay)
        cardDescBoxGo = new GameObject("CardDescBox", typeof(RectTransform), typeof(Image));
        cardDescBoxGo.transform.SetParent(handRootGo.transform, false);
        var cdImg = cardDescBoxGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (bgSpr != null) { cdImg.sprite = bgSpr; cdImg.type = Image.Type.Sliced; }
        cdImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);
        var cdRt = cardDescBoxGo.GetComponent<RectTransform>();
        SetRect(cdRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(680f, 58f), new Vector2(-80f, 198f));

        var cdFrame = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        cdFrame.transform.SetParent(cardDescBoxGo.transform, false);
        var cdfImg = cdFrame.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { cdfImg.sprite = fSpr; cdfImg.type = Image.Type.Sliced; }
        cdfImg.color = new Color(1f, 0.85f, 0.35f, 0.9f);
        Fill(cdFrame.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var cdTxtGo = new GameObject("DescText", typeof(RectTransform), typeof(Text));
        cdTxtGo.transform.SetParent(cardDescBoxGo.transform, false);
        cardDescBodyText = cdTxtGo.GetComponent<Text>();
        cardDescBodyText.font = font;
        cardDescBodyText.fontSize = ThemeUI.SizeBody; // Cỡ chữ 16pt chuẩn rõ nét
        cardDescBodyText.color = new Color(0.95f, 0.98f, 1f, 1f);
        cardDescBodyText.alignment = TextAnchor.MiddleLeft;
        cardDescBodyText.horizontalOverflow = HorizontalWrapMode.Wrap; // Hỗ trợ hiển thị 2 dòng
        cardDescBodyText.verticalOverflow = VerticalWrapMode.Truncate;
        cardDescBodyText.lineSpacing = 1.3f;
        Fill(cdTxtGo.GetComponent<RectTransform>(), new Vector2(12, 4), new Vector2(-12, -4));
        cardDescBoxGo.SetActive(false);

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

        // 2. Nút Dùng Bài Hành Động 2 Bước (y = 258f)
        actionBtnGo = new GameObject("ActionPlayBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        actionBtnGo.transform.SetParent(handRootGo.transform, false);
        var abImg = actionBtnGo.GetComponent<Image>();
        if (btnSpr != null) { abImg.sprite = btnSpr; abImg.type = Image.Type.Sliced; }
        abImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);
        var abRt = actionBtnGo.GetComponent<RectTransform>();
        SetRect(abRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(260f, 46f), new Vector2(-80f, 258f));

        var abTxt = AddText(actionBtnGo.transform, "Txt", "🃏 DÙNG LÁ BÀI", ThemeUI.SizeBodyLarge, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(abTxt.rectTransform);
        actionBtnText = abTxt;

        actionBtnGo.GetComponent<Button>().onClick.AddListener(OnPlayerActionBtnClicked);
        actionBtnGo.SetActive(false);

        // 3. Nút Kết Thúc Lượt (Mặc định ẩn, chỉ hiện trong lượt của người chơi)
        var etBtnGo = new GameObject("EndTurnBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        etBtnGo.transform.SetParent(handRootGo.transform, false);
        var etImg = etBtnGo.GetComponent<Image>();
        if (btnSpr != null) { etImg.sprite = btnSpr; etImg.type = Image.Type.Sliced; }
        etImg.color = new Color(0.9f, 0.6f, 0.15f, 1f);
        var etRt = etBtnGo.GetComponent<RectTransform>();
        SetRect(etRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(170f, 44f), new Vector2(220f, 258f));

        endTurnBtn = etBtnGo.GetComponent<Button>();
        endTurnBtnText = AddText(etBtnGo.transform, "Txt", "KẾT THÚC LƯỢT ➜", ThemeUI.SizeBody, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(endTurnBtnText.rectTransform);
        endTurnBtn.onClick.AddListener(OnPlayerEndTurnClicked);
        etBtnGo.SetActive(false);

        // 4. Nút Bỏ Bài Thừa (Khi kết thúc lượt thừa bài)
        var dcBtnGo = new GameObject("DiscardConfirmBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        dcBtnGo.transform.SetParent(handRootGo.transform, false);
        var dcImg = dcBtnGo.GetComponent<Image>();
        if (btnSpr != null) { dcImg.sprite = btnSpr; dcImg.type = Image.Type.Sliced; }
        dcImg.color = new Color(0.85f, 0.25f, 0.25f, 1f);
        var dcRt = dcBtnGo.GetComponent<RectTransform>();
        SetRect(dcRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(170f, 44f), new Vector2(-350f, 258f));

        discardConfirmBtn = dcBtnGo.GetComponent<Button>();
        discardConfirmBtnText = AddText(dcBtnGo.transform, "Txt", "BỎ BÀI (0/0)", ThemeUI.SizeBody, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(discardConfirmBtnText.rectTransform);
        discardConfirmBtn.onClick.AddListener(OnPlayerConfirmDiscardClicked);
        dcBtnGo.SetActive(false);
    }

    private void BuildLogAndStatusArea()
    {
        // 1. NÚT [📜 LỊCH SỬ] Ở GÓC DƯỚI CÙNG BÊN TRÁI
        var histBtnGo = new GameObject("HistoryButton", typeof(RectTransform), typeof(Image), typeof(Button));
        histBtnGo.transform.SetParent(battleRootGo.transform, false);
        var hbImg = histBtnGo.GetComponent<Image>();
        var slotSpr = ThemeUI.LoadSprite("UI/slot_bg");
        if (slotSpr != null) { hbImg.sprite = slotSpr; hbImg.type = Image.Type.Sliced; }
        hbImg.color = new Color(0.08f, 0.14f, 0.25f, 0.95f);

        var hbRt = histBtnGo.GetComponent<RectTransform>();
        hbRt.anchorMin = Vector2.zero;
        hbRt.anchorMax = Vector2.zero;
        hbRt.pivot = Vector2.zero;
        hbRt.sizeDelta = new Vector2(150f, 46f);
        hbRt.anchoredPosition = new Vector2(16f, 16f);

        var hbFrame = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        hbFrame.transform.SetParent(histBtnGo.transform, false);
        var hbfImg = hbFrame.GetComponent<Image>();
        var fSpr = ThemeUI.LoadSprite("UI/card_frame");
        if (fSpr != null) { hbfImg.sprite = fSpr; hbfImg.type = Image.Type.Sliced; }
        hbfImg.color = new Color(1f, 0.85f, 0.35f, 0.95f);
        hbfImg.raycastTarget = false;
        Fill(hbFrame.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

        var hbTxt = ThemeUI.CreateText(histBtnGo.transform, "Txt", "📜 LỊCH SỬ", ThemeUI.SizeBodyLarge, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(hbTxt.rectTransform);

        histBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            if (historyOverlayGo != null)
            {
                historyOverlayGo.SetActive(true);
                historyOverlayGo.transform.SetAsLastSibling();
                if (historyScrollRect != null)
                {
                    Canvas.ForceUpdateCanvases();
                    historyScrollRect.verticalNormalizedPosition = 0f;
                }
            }
        });

        // 2. POPUP MODAL LỊCH SỬ TRẬN ĐẤU (CHUẨN TUTORIAL)
        historyOverlayGo = new GameObject("HistoryModalOverlay", typeof(RectTransform), typeof(Image));
        historyOverlayGo.transform.SetParent(battleRootGo.transform, false);
        historyOverlayGo.transform.SetAsLastSibling();
        var ovImg = historyOverlayGo.GetComponent<Image>();
        ovImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(historyOverlayGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(historyOverlayGo.transform, false);
        var pImg = panelGo.GetComponent<Image>();
        var bgSpr = ThemeUI.LoadSprite("UI/auth_card_bg");
        if (bgSpr != null) { pImg.sprite = bgSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.06f, 0.09f, 0.18f, 0.98f);

        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = new Vector2(740f, 480f);
        pRt.anchoredPosition = Vector2.zero;

        var pBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        pBorder.transform.SetParent(panelGo.transform, false);
        var pbImg = pBorder.GetComponent<Image>();
        if (fSpr != null) { pbImg.sprite = fSpr; pbImg.type = Image.Type.Sliced; }
        pbImg.color = ThemeUI.GoldPrimary;
        pbImg.raycastTarget = false;
        Fill(pBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        var headerGo = new GameObject("Header", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var bSpr = ThemeUI.LoadSprite("UI/badge_faction");
        if (bSpr != null) { hImg.sprite = bSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.12f, 0.35f, 0.65f, 0.98f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(700f, 48f), new Vector2(0f, -12f));

        var titleTxt = ThemeUI.CreateText(headerGo.transform, "Title", "📜 LỊCH SỬ TRẬN ĐẤU (DIỄN BIẾN CHIẾN TRƯỜNG)", ThemeUI.SizeTitleLarge, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(titleTxt.rectTransform);

        // Nút Đóng [❌]
        var closeBtnGo = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        closeBtnGo.transform.SetParent(panelGo.transform, false);
        var clImg = closeBtnGo.GetComponent<Image>();
        var btnSpr = ThemeUI.LoadSprite("UI/btn_gold");
        if (btnSpr != null) { clImg.sprite = btnSpr; clImg.type = Image.Type.Sliced; }
        clImg.color = new Color(0.85f, 0.25f, 0.25f, 1f);
        var clRt = closeBtnGo.GetComponent<RectTransform>();
        SetRect(clRt, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(40f, 40f), new Vector2(-16f, -16f));

        var clTxt = ThemeUI.CreateText(closeBtnGo.transform, "Txt", "❌", ThemeUI.SizeButton, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter, true);
        Fill(clTxt.rectTransform);
        closeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            historyOverlayGo.SetActive(false);
        });

        // ScrollView Chứa Nội Dung Lịch Sử
        var scrollGo = new GameObject("HistoryScroll", typeof(RectTransform), typeof(ScrollRect), typeof(Image), typeof(Mask));
        scrollGo.transform.SetParent(panelGo.transform, false);
        var sImg = scrollGo.GetComponent<Image>();
        sImg.color = new Color(0.02f, 0.04f, 0.08f, 0.55f);
        var mask = scrollGo.GetComponent<Mask>();
        mask.showMaskGraphic = false;

        var scrollRt = scrollGo.GetComponent<RectTransform>();
        scrollRt.anchorMin = Vector2.zero;
        scrollRt.anchorMax = Vector2.one;
        scrollRt.offsetMin = new Vector2(20f, 20f);
        scrollRt.offsetMax = new Vector2(-20f, -66f);

        var contentGo = new GameObject("Content", typeof(RectTransform), typeof(Text), typeof(ContentSizeFitter));
        contentGo.transform.SetParent(scrollGo.transform, false);
        var contentRt = contentGo.GetComponent<RectTransform>();
        contentRt.anchorMin = new Vector2(0f, 1f);
        contentRt.anchorMax = new Vector2(1f, 1f);
        contentRt.pivot = new Vector2(0.5f, 1f);
        contentRt.offsetMin = new Vector2(12f, 0f);
        contentRt.offsetMax = new Vector2(-12f, 0f);

        var csf = contentGo.GetComponent<ContentSizeFitter>();
        csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

        historyContentText = contentGo.GetComponent<Text>();
        historyContentText.font = font;
        historyContentText.fontSize = ThemeUI.SizeBody;
        historyContentText.color = new Color(0.95f, 0.98f, 1f, 1f);
        historyContentText.lineSpacing = 1.3f;
        historyContentText.alignment = TextAnchor.UpperLeft;
        ThemeUI.AddTextShadow(historyContentText);

        historyScrollRect = scrollGo.GetComponent<ScrollRect>();
        historyScrollRect.horizontal = false;
        historyScrollRect.vertical = true;
        historyScrollRect.viewport = scrollRt;
        historyScrollRect.content = contentRt;
        historyScrollRect.scrollSensitivity = 40f;

        historyOverlayGo.SetActive(false);

        battleLogHistory.Clear();
        SetLog("⚔️ Trận đấu 2v2 chính thức bắt đầu!");
    }

    private IEnumerator StartBattleCardDealSequence()
    {
        turnOrderGenerals.Clear();
        for (int s = 1; s <= 4; s++)
        {
            foreach (var g in allGenerals)
            {
                if (g.SeatNumber == s)
                {
                    turnOrderGenerals.Add(g);
                    break;
                }
            }
        }

        isFirstTurnOfMatch = true;

        // Xoá sạch bài trên tay mọi tướng trước khi bắt đầu chia
        playerHandCards.Clear();
        if (playerHandUI != null) playerHandUI.ClearHand();
        foreach (var g in allGenerals)
        {
            if (g != null) GetHandOfGeneral(g).Clear();
        }
        UpdateHandCountsVisual();

        SetLog("🎴 Kết nối Máy Chủ Authoritative để chia bài và bắt đầu trận đấu...");
        var initPlayers = BuildInitialServerPlayers();
        if (DenoGameClient.Instance != null && !string.IsNullOrEmpty(currentRoomId))
        {
            DenoGameClient.Instance.ConnectToServer(currentRoomId, playerCard != null ? playerCard.SeatNumber : 1, initPlayers);
        }

        float waitTimer = 0f;
        while (waitTimer < 4.0f && lastAppliedStateVersion == 0)
        {
            waitTimer += 0.1f;
            yield return new WaitForSecondsRealtime(0.1f);
        }

        if (lastAppliedStateVersion > 0)
        {
            SetLog("👑 Trận đấu bắt đầu! Máy chủ đã chia 4 lá bài ban đầu và mở lượt.");
            AudioManager.Instance.PlayCardDraw();
            yield break;
        }

        SetLog("🎴 Phát 4 lá bài ban đầu cho toàn thể chiến tướng...");
        AudioManager.Instance.PlayCardDraw();

        // Đồng bộ tuyệt đối: Phát bài theo thứ tự Ghế tuyệt đối (Ghế 1 -> Ghế 2 -> Ghế 3 -> Ghế 4)
        var seatOrderedGenerals = new List<GeneralCardUI>(allGenerals);
        seatOrderedGenerals.Sort((a, b) => a.SeatNumber.CompareTo(b.SeatNumber));

        for (int round = 0; round < 4; round++)
        {
            foreach (var g in seatOrderedGenerals)
            {
                var card = deckManager.DrawCard();
                if (card != null)
                {
                    yield return AnimateDealtCard(g);
                    AddCardsToGeneral(g, card);
                }
                UpdateHandCountsVisual();
                yield return new WaitForSeconds(0.04f);
            }
        }

        UpdateHandCountsVisual();
        yield return new WaitForSeconds(1.0f);

        currentTurnIndex = 0;
        if (currentTurnCoroutine != null) StopCoroutine(currentTurnCoroutine);
        currentTurnCoroutine = StartCoroutine(ExecuteCurrentTurn());
    }

    private List<AppwriteMatchmaking.GameStatePlayer> BuildInitialServerPlayers()
    {
        var players = new List<AppwriteMatchmaking.GameStatePlayer>();
        for (int seat = 1; seat <= 4; seat++)
        {
            var g = GetGeneralBySeat(seat);
            if (g == null) continue;

            players.Add(new AppwriteMatchmaking.GameStatePlayer
            {
                seat = seat,
                userId = g.UserId,
                heroId = GetDenoHeroId(g.GeneralName),
                generalName = g.GeneralName,
                maxHp = g.MaxHp,
                hp = g.MaxHp,
                isAlly = IsTeamOneSeat(seat),
                isAI = g.IsAI,
                handCount = 0,
                hand = new List<AppwriteMatchmaking.GameStateCard>()
            });
        }
        return players;
    }

    private bool IsAIController()
    {
        if (isRoomHost) return true;
        if (playerCard != null && allGenerals != null && allGenerals.Count > 0)
        {
            int lowestHumanSeat = 99;
            foreach (var g in allGenerals)
            {
                if (g != null && !g.IsAI && g.SeatNumber < lowestHumanSeat)
                {
                    lowestHumanSeat = g.SeatNumber;
                }
            }
            if (playerCard.SeatNumber == lowestHumanSeat) return true;
        }
        return false;
    }

    private void BuildDeckStatusHUD()
    {
        var font = ThemeUI.FontMain;

        deckHudGo = new GameObject("DeckStatusHUD", typeof(RectTransform));
        deckHudGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        var rt = deckHudGo.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(1f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.pivot = new Vector2(1f, 1f);
        rt.sizeDelta = new Vector2(68f, 92f);
        rt.anchoredPosition = new Vector2(-16f, -54f);

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
        SetLog("🔄 <color=#FFD700><b>KHO BÀI ĐÃ ĐƯỢC XÁO LẠI!</b></color> Toàn bộ xấp bài đã dùng được xáo lại.");
    }

    private IEnumerator AnimateInitialDeal()
 {
 for (int i = 0; i < 4; i++)
 {
 foreach (var g in turnOrderGenerals)
 {
 if (g != null && g.CurrentHp > 0)
 {
 yield return AnimateDealtCard(g);
 yield return new WaitForSeconds(0.05f);
 }
 }
 }
 }
 
 private IEnumerator AnimateMultipleDealtCards(GeneralCardUI targetGeneral, int count, System.Collections.Generic.List<CardModel> myNewCards = null)
    {
        for (int i = 0; i < count; i++)
        {
            yield return AnimateDealtCard(targetGeneral);
            if (myNewCards != null && i < myNewCards.Count && targetGeneral.SeatNumber == (playerCard != null ? playerCard.SeatNumber : -1)) {
                playerHandUI.AddCard(myNewCards[i]);
            }
            yield return new WaitForSeconds(0.05f);
        }
        if (myNewCards != null && count > 0 && targetGeneral.SeatNumber == (playerCard != null ? playerCard.SeatNumber : -1)) {
            UpdateHandCountsVisual();
        }
    }

    private IEnumerator AnimateDealtCard(GeneralCardUI targetGeneral)
    {
        if (targetGeneral == null) yield break;
        AudioManager.Instance.PlayCardDraw();

        var flyingGo = new GameObject("DealingCard", typeof(RectTransform), typeof(Image));
        flyingGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        flyingGo.transform.SetAsLastSibling();
        var image = flyingGo.GetComponent<Image>();
        image.sprite = LotusHealthUI.LoadSpriteFromResources("UI/card_back_bg");
        image.type = Image.Type.Sliced;
        image.raycastTarget = false;

        var flyingRt = flyingGo.GetComponent<RectTransform>();
        flyingRt.anchorMin = flyingRt.anchorMax = flyingRt.pivot = new Vector2(0.5f, 0.5f);
        flyingRt.sizeDelta = new Vector2(58, 80);

        var rootRt = canvasGo.GetComponent<RectTransform>();
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

        var targetRt = targetGeneral.GetComponent<RectTransform>();
        Vector2 targetScreen = RectTransformUtility.WorldToScreenPoint(null, targetRt.position);
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, targetScreen, null, out var end);

        float elapsed = 0f;
        const float duration = 0.2f;
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

    private void UpdateHandCountsVisual()
    {
        playerCard.SetHandCardCount(playerHandCards.Count);
        allyCard.SetHandCardCount(allyHandCards.Count);
        enemy1Card.SetHandCardCount(enemy1HandCards.Count);
        enemy2Card.SetHandCardCount(enemy2HandCards.Count);
    }
    #endregion

    #region 4. CỰ LY & TẦM ĐÁNH CHUẨN TUTORIAL
    public int CalculateDistance(GeneralCardUI from, GeneralCardUI to)
    {
        if (from == null || to == null || from == to) return 0;

        // Lấy danh sách toàn bộ các chiến tướng CÒN SỐNG theo vòng ghế
        var livingGenerals = new List<GeneralCardUI>();
        for (int s = 1; s <= 4; s++)
        {
            foreach (var g in allGenerals)
            {
                if (g.SeatNumber == s && g.CurrentHp > 0)
                {
                    livingGenerals.Add(g);
                    break;
                }
            }
        }

        if (!livingGenerals.Contains(from) || !livingGenerals.Contains(to)) return 99;

        int N = livingGenerals.Count;
        if (N <= 1) return 1;

        int i = livingGenerals.IndexOf(from);
        int j = livingGenerals.IndexOf(to);

        // Tính cự ly theo 2 hướng: Hướng Phải (Theo chiều kim đồng hồ) và Hướng Trái (Ngược chiều kim đồng hồ)
        int distRight = (j - i + N) % N;
        int distLeft = (i - j + N) % N;
        int baseDist = Mathf.Min(distRight, distLeft);

        int defMod = to.GetDefensiveDistanceModifier();  // Ngựa thủ (+1)
        int offMod = from.GetOffensiveDistanceModifier(); // Ngựa công (-1)

        return Mathf.Max(1, baseDist + defMod + offMod);
    }

    public bool IsTargetInAttackRange(GeneralCardUI attacker, GeneralCardUI target, CardModel card = null)
    {
        if (attacker == null || target == null) return false;
        int dist = CalculateDistance(attacker, target);
        if (attacker.HeroId == "2") dist -= 2;
        int range = attacker.GetAttackRange();
        return range >= dist;
    }

    private bool IsSlashLimitReached(GeneralCardUI caster, CardModel card)
    {
        if (caster.HasEquipment(EquipmentType.Weapon, "Nỏ Thần")) return false;
        return slashesUsedThisTurn > 0;
    }
    #endregion

    #region 5. VÒNG LẶP LƯỢT & GIAI ĐOẠN PHÁN XÉT
    private IEnumerator ExecuteCurrentTurn()
    {
        if (battleFinished) yield break;
        if (DenoGameClient.IsConnected)
        {
            // Khi máy chủ Deno WebSocket đang kết nối: Máy chủ chịu trách nhiệm điều phối lượt
            yield break;
        }

        var currentGeneral = turnOrderGenerals[currentTurnIndex];

        if (currentGeneral.CurrentHp <= 0)
        {
            AdvanceToNextTurn();
            yield break;
        }

        // Ẩn nút kết thúc lượt nếu không phải lượt người chơi
        if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(currentGeneral == playerCard);

        foreach (var g in allGenerals) g.SetTurnActive(g == currentGeneral);

        string teamLabel = currentGeneral.IsAlly ? "<color=#55DDFF>[ĐỒNG MINH]</color>" : "<color=#FF5555>[ĐỐI THỦ]</color>";
        globalTurnText.text = $"LƯỢT #{currentGeneral.SeatNumber}: {teamLabel} {currentGeneral.GeneralName}";
        SetLog($"⚔️ Bắt đầu lượt của <b>{currentGeneral.GeneralName}</b> (Ghế #{currentGeneral.SeatNumber})!");

        slashesUsedThisTurn = 0;
        isWineBuffActive = false;
        playerPlayPhaseLocked = false;
        playerDrawPhaseLocked = false;
        ClearSelectedTarget();

        // 1. GIAI ĐOẠN PHÁN XÉT
        yield return ResolveJudgementPhase(currentGeneral);
        if (currentGeneral.CurrentHp <= 0 || battleFinished)
        {
            AdvanceToNextTurn();
            yield break;
        }

        // 2. GIAI ĐOẠN RÚT BÀI (Yêu cầu 1: Người đi đầu tiên chỉ bốc 1 lá)
        if (!playerDrawPhaseLocked)
        {
            int drawCount = isFirstTurnOfMatch ? 1 : 2;
            if (isFirstTurnOfMatch)
            {
                SetLog($"🎴 <color=#FFD700><b>[LƯỢT ĐẦU TIÊN]</b></color>: <b>{currentGeneral.GeneralName}</b> đi đầu tiên trong trận nên chỉ được rút <b>1 lá bài</b>!");
                isFirstTurnOfMatch = false;
            }

            for (int i = 0; i < drawCount; i++)
            {
                var d = deckManager.DrawCard();
                if (d != null)
                {
                    yield return AnimateDealtCard(currentGeneral);
                    AddCardsToGeneral(currentGeneral, d);
                }
            }
            UpdateHandCountsVisual();
            yield return new WaitForSeconds(0.4f);
        }
        else
        {
            SetLog($"🌾 <b>{currentGeneral.GeneralName}</b> bị [Cắt Đường Lương] tước quyền rút bài!");
            yield return new WaitForSeconds(1.0f);
        }

        // 3. GIAI ĐOẠN RA BÀI
        if (!playerPlayPhaseLocked)
        {
            if (currentGeneral == playerCard || currentGeneral.IsPlayer)
            {
                yield return StartPlayerPlayPhase();
            }
            else if (!currentGeneral.IsAI)
            {
                // NGƯỜI CHƠI THẬT TRÊN THIẾT BỊ KHÁC (REAL-TIME REMOTE TURN)
                yield return StartRemotePlayerPlayPhase(currentGeneral);
            }
            else
            {
                // BOT TỰ ĐỘNG (Host/Controller ra lệnh và phát sóng; Guest nhận lệnh đồng bộ)
                if (IsAIController())
                {
                    yield return StartAIPlayPhase(currentGeneral);
                }
                else
                {
                    yield return StartRemotePlayerPlayPhase(currentGeneral);
                }
            }
        }
        else
        {
            SetLog($"🕸️ <b>{currentGeneral.GeneralName}</b> bị [Trầm Ảo Sa Bẫy] giam giữ, mất Giai đoạn Ra bài!");
            yield return new WaitForSeconds(1.0f);
        }

        // 4. GIAI ĐOẠN BỎ BÀI
        yield return StartDiscardPhase(currentGeneral);

        AdvanceToNextTurn();
    }

    private IEnumerator ResolveJudgementPhase(GeneralCardUI g)
    {
        if (g.HasDelayedScroll(CardSubType.Lightning))
        {
            SetLog($"⚡ [Phán Xét Thần Sấm]: Đang lật bài phán xét cho {g.GeneralName}...");
            yield return new WaitForSeconds(1.0f);
            yield return AnimateDealtCard(g); // Hiệu ứng bay bài phán xét
            var judgeCard = deckManager.DrawCard();
            if (judgeCard != null)
            {
                ShowCardAtCenter(judgeCard, g, null, "PHÁN XÉT THẦN SẤM");
                bool struck = (judgeCard.suit == CardSuit.Spade && (int)judgeCard.rank >= 2 && (int)judgeCard.rank <= 9);
                yield return ShowJudgementMark(struck ? false : true);
                deckManager.DiscardCard(judgeCard);

                if (struck)
                {
                    SetLog($"⚡ <color=#FF5555>THẦN SẤM GIÁNG TRÚNG!</color> {g.GeneralName} chịu 3 sát thương Sấm Sét!");
                    g.RemoveDelayedScroll(CardSubType.Lightning);
                    g.TakeDamage(3); AudioManager.Instance.PlayDamage(); StartCoroutine(ShakeCard(g)); StartCoroutine(ShowFloatingDamage(g, 3));
                    yield return CheckNearDeath(g, null);
                }
                else
                {
                    SetLog($"✨ Phán xét an toàn! Chuyển Thần Sấm Báo Ứng sang người kế tiếp.");
                    g.RemoveDelayedScroll(CardSubType.Lightning);
                    var nextGen = GetNextAliveGeneral(g);
                    if (nextGen != null && !nextGen.HasDelayedScroll(CardSubType.Lightning))
                    {
                        var lightCard = new CardModel
                        {
                            id = "D1_S_LIGHTNING",
                            cardName = "Thần Sấm Báo Ứng",
                            suit = CardSuit.Spade,
                            rank = CardRank.Ace,
                            category = CardCategory.DelayedScroll,
                            subType = CardSubType.Lightning,
                            iconPath = "UI/icon_lightning"
                        };
                        nextGen.AddDelayedScroll(lightCard);
                    }
                }
                yield return new WaitForSeconds(1.2f);
            }
        }

        if (g.HasDelayedScroll(CardSubType.SupplyShortage))
        {
            SetLog($"🌾 [Phán Xét Cắt Đường Lương]: Lật bài chất Chuồn (♣) để rút bài bình thường...");
            yield return new WaitForSeconds(1.0f);
            yield return AnimateDealtCard(g); // Hiệu ứng bay bài phán xét
            var judgeCard = deckManager.DrawCard();
            if (judgeCard != null)
            {
                ShowCardAtCenter(judgeCard, g, null, "PHÁN XÉT CẮT LƯƠNG");
                bool pass = (judgeCard.suit == CardSuit.Club);
                yield return ShowJudgementMark(pass);
                deckManager.DiscardCard(judgeCard);
                g.RemoveDelayedScroll(CardSubType.SupplyShortage);

                if (!pass)
                {
                    playerDrawPhaseLocked = true;
                    SetLog($"🚫 Phán xét thất bại! {g.GeneralName} bị mất lượt rút bài.");
                }
                else
                {
                    SetLog($"✨ Phán xét thành công! {g.GeneralName} giải trừ Cắt Đường Lương.");
                }
                yield return new WaitForSeconds(1.0f);
            }
        }

        if (g.HasDelayedScroll(CardSubType.Acedia))
        {
            SetLog($"🕸️ [Phán Xét Trầm Ảo Sa Bẫy]: Lật bài chất Cơ (♥) để thoát bẫy...");
            yield return new WaitForSeconds(1.0f);
            yield return AnimateDealtCard(g); // Hiệu ứng bay bài phán xét
            var judgeCard = deckManager.DrawCard();
            if (judgeCard != null)
            {
                ShowCardAtCenter(judgeCard, g, null, "PHÁN XÉT SA BẪY");
                bool pass = (judgeCard.suit == CardSuit.Heart);
                yield return ShowJudgementMark(pass);
                deckManager.DiscardCard(judgeCard);
                g.RemoveDelayedScroll(CardSubType.Acedia);

                if (!pass)
                {
                    playerPlayPhaseLocked = true;
                    SetLog($"🕸️ Phán xét thất bại! {g.GeneralName} bị giam cầm, bỏ qua Giai đoạn Ra bài.");
                }
                else
                {
                    SetLog($"✨ Phán xét thành công! {g.GeneralName} thoát khỏi Trầm Ảo Sa Bẫy.");
                }
                yield return new WaitForSeconds(1.0f);
            }
        }
    }

    
    private IEnumerator ServerJudgementAnimation(CardModel judgeCard, GeneralCardUI g, string title, bool success)
    {
        if (currentCenterCardGo != null)
        {
            Destroy(currentCenterCardGo);
            currentCenterCardGo = null;
        }

        var centerContainer = new GameObject("ServerJudgementAnim", typeof(RectTransform));
        centerContainer.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        centerContainer.transform.SetAsLastSibling();
        
        var rt = centerContainer.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(94, 130);
        
        
        // Hoạt cảnh lật bài phán xét từ xấp bài (Deck) ra giữa màn hình
        AudioManager.Instance.PlayCardDraw();
        var flyingGo = new GameObject("DealingJudgeCard", typeof(RectTransform), typeof(UnityEngine.UI.Image));
        flyingGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        flyingGo.transform.SetAsLastSibling();
        var image = flyingGo.GetComponent<UnityEngine.UI.Image>();
        image.sprite = LotusHealthUI.LoadSpriteFromResources("UI/card_back_bg");
        image.type = UnityEngine.UI.Image.Type.Sliced;
        image.raycastTarget = false;

        var flyingRt = flyingGo.GetComponent<RectTransform>();
        flyingRt.anchorMin = flyingRt.anchorMax = flyingRt.pivot = new Vector2(0.5f, 0.5f);
        flyingRt.sizeDelta = new Vector2(58, 80);

        var rootRt = canvasGo != null ? canvasGo.GetComponent<RectTransform>() : null;
        Vector2 startPosDeck = Vector2.zero;
        if (rootRt != null && deckHudGo != null && deckHudGo.activeInHierarchy) {
            Vector2 screenP = RectTransformUtility.WorldToScreenPoint(null, deckHudGo.transform.position);
            RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, screenP, null, out startPosDeck);
        } else {
            startPosDeck = new Vector2(400, -200); // Tạm góc phải dưới
        }
        flyingRt.anchoredPosition = startPosDeck;

        Vector2 endPosCenter = new Vector2(-80f, 20f);
        float flyElapsed = 0f;
        float flyDuration = 0.35f;
        while (flyElapsed < flyDuration) {
            flyElapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, flyElapsed / flyDuration);
            flyingRt.anchoredPosition = Vector2.Lerp(startPosDeck, endPosCenter, t);
            flyingRt.localScale = Vector3.one * Mathf.Lerp(1f, 1.2f, t);
            yield return null;
        }
        Destroy(flyingGo);

        // Hoạt cảnh pop out lá bài từ tâm màn hình
        Vector2 startPos = new Vector2(-80f, 20f);
        rt.anchoredPosition = startPos;
        rt.localScale = Vector3.one * 0.1f;
        StartCoroutine(PopOutCard(rt, startPos, new Vector2(-80f, 20f), 1.15f));

        currentCenterCardGo = centerContainer;

        // Render card
        var cardUI = CardUI.Create(centerContainer.transform, judgeCard, new Vector2(94, 130));
        var cardRt = cardUI.GetComponent<RectTransform>();
        cardRt.anchorMin = Vector2.zero; cardRt.anchorMax = Vector2.one;
        cardRt.offsetMin = cardRt.offsetMax = Vector2.zero;
        
        if (!string.IsNullOrEmpty(title)) {
            var txtValue = AddText(centerContainer.transform, "Title", title, 14, Color.white, FontStyle.Bold, TextAnchor.UpperCenter);
            SetRect(txtValue.rectTransform, new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, 30), new Vector2(0, 5));
        }

        AudioManager.Instance.PlayCardSelect();
        yield return new WaitForSeconds(0.25f);
        
        // Hộp tiêu đề phán xét phía trên lá bài
        var titleBoxGo = new GameObject("JudgementTitle", typeof(RectTransform), typeof(Image));
        titleBoxGo.transform.SetParent(centerContainer.transform, false);
        var titleBg = titleBoxGo.GetComponent<Image>();
        titleBg.color = new Color(0, 0, 0, 0.8f);
        var titleRt = titleBoxGo.GetComponent<RectTransform>();
        titleRt.anchorMin = new Vector2(0, 1);
        titleRt.anchorMax = new Vector2(1, 1);
        titleRt.pivot = new Vector2(0.5f, 0);
        titleRt.sizeDelta = new Vector2(0, 30f);
        titleRt.anchoredPosition = new Vector2(0, 5f);
        
        var titleTxt = AddText(titleBoxGo.transform, "Text", title, 14, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, Vector2.zero, Vector2.one, new Vector2(0.5f, 0.5f), Vector2.zero, Vector2.zero);

        yield return new WaitForSeconds(0.3f);
        yield return ShowJudgementMark(success);
        
        yield return new WaitForSeconds(3.0f);
        if (currentCenterCardGo == centerContainer)
        {
            Destroy(currentCenterCardGo);
            currentCenterCardGo = null;
        }
    }

    private IEnumerator ShowJudgementMark(bool success)
    {
        if (currentCenterCardGo == null) yield break;
        
        var badgeGo = new GameObject("JudgementBadge", typeof(RectTransform), typeof(UnityEngine.UI.Text));
        badgeGo.transform.SetParent(currentCenterCardGo.transform, false);
        var iconTxt = badgeGo.GetComponent<UnityEngine.UI.Text>();
        iconTxt.font = Resources.GetBuiltinResource<UnityEngine.Font>("LegacyRuntime.ttf");
        iconTxt.fontSize = success ? 78 : 72;
        iconTxt.fontStyle = UnityEngine.FontStyle.Bold;
        iconTxt.alignment = UnityEngine.TextAnchor.MiddleCenter;
        iconTxt.text = success ? "<color=#44FF55>✔</color>" : "<color=#FF4444>✖</color>";
        var icShadow = badgeGo.AddComponent<UnityEngine.UI.Shadow>();
        icShadow.effectColor = new Color(0, 0, 0, 0.95f);
        icShadow.effectDistance = new Vector2(2f, -2f);
        Fill(badgeGo.GetComponent<RectTransform>());

        var rt = badgeGo.GetComponent<RectTransform>();
        rt.localScale = Vector3.one * 0.1f;

        float elapsed = 0f;
        while (elapsed < 0.2f)
        {
            elapsed += Time.deltaTime;
            rt.localScale = Vector3.one * Mathf.Lerp(0.1f, 1f, elapsed / 0.2f);
            yield return null;
        }
        rt.localScale = Vector3.one;

        // Chờ người chơi nhìn thấy kết quả
        yield return new WaitForSeconds(0.8f);
    }

    private GeneralCardUI GetNextAliveGeneral(GeneralCardUI current)
    {
        int idx = turnOrderGenerals.IndexOf(current);
        for (int i = 1; i < turnOrderGenerals.Count; i++)
        {
            int nextIdx = (idx + i) % turnOrderGenerals.Count;
            if (turnOrderGenerals[nextIdx].CurrentHp > 0) return turnOrderGenerals[nextIdx];
        }
        return null;
    }

    private void AdvanceToNextTurn()
    {
        if (battleFinished) return;

        currentTurnIndex = (currentTurnIndex + 1) % turnOrderGenerals.Count;
        if (currentTurnCoroutine != null) StopCoroutine(currentTurnCoroutine);
        currentTurnCoroutine = StartCoroutine(ExecuteCurrentTurn());
    }

    private void AddCardsToGeneral(GeneralCardUI g, params CardModel[] cards)
    {
        foreach (var c in cards)
        {
            if (c == null) continue;
            if (g == playerCard) { playerHandCards.Add(c); playerHandUI.AddCard(c); }
            else if (g == allyCard) allyHandCards.Add(c);
            else if (g == enemy1Card) enemy1HandCards.Add(c);
            else if (g == enemy2Card) enemy2HandCards.Add(c);
        }
    }
    #endregion

    #region 6. GIAI ĐOẠN RA BÀI CỦA NGƯỜI CHƠI (CHÚ THÍCH THUẦN VIỆT, KHÔNG LƯU MỤC TIÊU CŨ)
    private IEnumerator StartPlayerPlayPhase()
    {
        isPlayerTurnActive = true;
        turnTimer = 40.0f;
        isTimerRunning = true;
        playerCard.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
        if (endTurnBtn != null)
        {
            endTurnBtn.gameObject.SetActive(true);
            endTurnBtn.interactable = true;
        }

        SetLog("👉 <b>Lượt của bạn!</b> Chạm lá bài -> Chạm chọn mục tiêu -> Nhấn nút [DÙNG BÀI]!");

        while (isPlayerTurnActive && !battleFinished)
        {
            yield return null;
        }

        isTimerRunning = false;
        playerCard.HideHeadTimer();
        if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(false);
        if (actionBtnGo != null) actionBtnGo.SetActive(false);
        HideCardDescription();
    }

    private void OnPlayerEndTurnClicked()
    {
        if (!isPlayerTurnActive || actionInProgress) return;
        actionInProgress = true;
        if (actionBtnGo != null) actionBtnGo.SetActive(false);
        HideCardDescription();
        currentSelectedCardUI = null;
        ClearSelectedTarget();
        AudioManager.Instance.PlayCardSelect();
        if (!string.IsNullOrEmpty(currentRoomId))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "END_TURN",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }
        else
        {
            actionInProgress = false;
        }
        isPlayerTurnActive = false;
    }

    private string GetVietnameseCardDetail(CardModel card)
    {
        if (card == null) return "";

        string catStr = card.category switch
        {
            CardCategory.Basic => "Bài Cơ Bản",
            CardCategory.Equipment => card.subType switch
            {
                CardSubType.Weapon => "Trang Bị - Vũ Khí",
                CardSubType.Armor => "Trang Bị - Áo Giáp",
                CardSubType.OffensiveHorse => "Trang Bị - Ngựa Công",
                CardSubType.DefensiveHorse => "Trang Bị - Ngựa Thủ",
                _ => "Trang Bị"
            },
            CardCategory.InstantScroll => "Cẩm Nang Tức Thời",
            CardCategory.DelayedScroll => "Cẩm Nang Trì Hoãn",
            _ => "Thẻ Bài"
        };

        string suitSymbol = card.suit switch
        {
            CardSuit.Spade => "♠",
            CardSuit.Heart => "♥",
            CardSuit.Club => "♣",
            CardSuit.Diamond => "♦",
            _ => ""
        };

        string rankStr = card.rank switch
        {
            CardRank.Ace => "A",
            CardRank.Jack => "J",
            CardRank.Queen => "Q",
            CardRank.King => "K",
            _ => ((int)card.rank).ToString()
        };

        string desc = !string.IsNullOrEmpty(card.description)
            ? card.description
            : GetDefaultCardDescription(card.subType, card.cardName);

        return $"🎴 <b><color=#FFD700>[{card.cardName.ToUpper()}]</color></b> <color=#55DDFF>({catStr} • {suitSymbol} {rankStr})</color>\n<color=#E2E8F0>{desc}</color>";
    }


    private void ShowCardDescription(CardModel card)
    {
        if (cardDescBoxGo == null || cardDescBodyText == null || card == null) return;
        cardDescBodyText.text = GetVietnameseCardDetail(card);
        cardDescBoxGo.SetActive(true);
    }

    private void HideCardDescription()
    {
        if (cardDescBoxGo != null) cardDescBoxGo.SetActive(false);
    }

    private void HandlePlayerCardSelected(CardUI cardUI)
    {
        if (cardUI == null || cardUI.Data == null)
        {
            currentSelectedCardUI = null;
            if (actionBtnGo != null) actionBtnGo.SetActive(false);
            HideCardDescription();
            return;
        }

        // Luôn hiển thị bảng mô tả chi tiết tác dụng của lá bài khi người chơi chạm/click vào bài
        ShowCardDescription(cardUI.Data);

        if (isDiscardPhaseActive)
        {
            return;
        }

        if (!isPlayerTurnActive || actionInProgress || battleFinished)
        {
            if (actionBtnGo != null) actionBtnGo.SetActive(false);
            // Không ẩn mô tả để người chơi vẫn đọc được tác dụng của lá bài
            return;
        }

        if (playerPlayPhaseLocked)
        {
            SetLog("🕸️ [Trầm Ảo Sa Bẫy]: Bạn đã bị bỏ qua Giai đoạn Ra bài trong lượt này.");
            if (actionBtnGo != null) actionBtnGo.SetActive(false);
            return;
        }

        // Mỗi lần chọn lá bài mới -> Xóa mục tiêu cũ đã chọn trước đó
        ClearSelectedTarget();
        currentSelectedCardUI = cardUI;
        UpdateActionButtonState();
    }

    public void UpdatePlayerSkillButtonState()
    {
        if (playerCard == null || playerCard.SkillButtonGo == null) return;
        
        string heroName = !string.IsNullOrEmpty(playerCard.GeneralName) ? playerCard.GeneralName : "";
        string hId = !string.IsNullOrEmpty(playerCard.HeroId) ? playerCard.HeroId : "";
        if (string.IsNullOrEmpty(hId))
        {
            var hData = HeroDatabase100.GetHeroByName(heroName);
            if (hData != null) { hId = hData.id.ToString(); playerCard.HeroId = hId; }
        }

        // 1. TƯỚNG 1: CAO LỖ (CHẾ NỎ - CHỦ ĐỘNG BIẾN CHẤT ♠ THÀNH NỎ THẦN)
        if (hId == "1" || heroName.Contains("Cao Lỗ"))
        {
            bool isSkillActive = playerCard.IsSkillActive("Chế Nỏ");
            bool hasSpade = false;
            if (playerHandCards != null) {
                foreach(var c in playerHandCards) {
                    if (c != null && c.suit == CardSuit.Spade && c.subType != CardSubType.Weapon) {
                        hasSpade = true;
                        break;
                    }
                }
            }

            playerCard.SkillButtonGo.SetActive(true);
            playerCard.SetSkill(isSkillActive ? "HỦY CHẾ NỎ" : "⚡ CHẾ NỎ", OnPlayerSkillCheNoClicked);
            playerCard.SetSkillState(hasSpade || isSkillActive);
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) {
                btnImg.color = isSkillActive ? new UnityEngine.Color(0.9f, 0.25f, 0.2f, 1f) : (hasSpade ? new UnityEngine.Color(1f, 0.75f, 0.2f, 1f) : new UnityEngine.Color(0.12f, 0.16f, 0.24f, 0.7f));
            }
        }
        // 2. TƯỚNG 2: ĐÀO HÃN (XẠ THUẪN - BỊ ĐỘNG CỰ LY -2 KHI DÙNG TRẢM)
        else if (hId == "2" || heroName.Contains("Đào Hãn"))
        {
            playerCard.SkillButtonGo.SetActive(true);
            playerCard.SetSkill("⚡ XẠ THUẪN", () =>
            {
                SetLog("🏹 <color=#FFD700><b>[Xạ Thuẫn]</b></color> (Bị động): Khoảng cách khi bạn dùng Trảm lên mọi kẻ địch luôn được giảm 2 cự ly!");
            });
            playerCard.SetSkillState(true);
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) btnImg.color = new UnityEngine.Color(0.15f, 0.55f, 0.35f, 0.95f);
        }
        // 3. TƯỚNG 3: THI SÁCH (HỊCH NGHĨA - BỊ ĐỘNG RÚT 2 BÀI KHI THOÁT CẬN TỬ)
        else if (hId == "3" || heroName.Contains("Thi Sách"))
        {
            playerCard.SkillButtonGo.SetActive(true);
            playerCard.SetSkill("⚡ HỊCH NGHĨA", () =>
            {
                SetLog("✨ <color=#FFD700><b>[Hịch Nghĩa]</b></color> (Bị động): Khi bạn rơi vào trạng thái Cận Tử và được cứu sống, bạn lập tức rút ngay 2 lá bài!");
            });
            playerCard.SetSkillState(true);
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null) btnImg.color = new UnityEngine.Color(0.55f, 0.30f, 0.85f, 0.95f);
        }
        // 4. TƯỚNG 4: LÊ CHÂN (TRIỀU DÂNG - CHỦ ĐỘNG HỦY 1 TRANG BỊ CỦA NGƯỜI KHÁC)
        else if (hId == "4" || heroName.Contains("Lê Chân"))
        {
            bool hasUsed = playerCard.HasUsedSkill("Triều Dâng");
            bool isMyTurn = (currentAuthoritativePhase == "PLAY" && currentAuthoritativeTurnSeat == playerCard.SeatNumber) 
                || (string.IsNullOrEmpty(currentRoomId) && turnOrderGenerals != null && currentTurnIndex >= 0 && currentTurnIndex < turnOrderGenerals.Count && turnOrderGenerals[currentTurnIndex] == playerCard);
            
            playerCard.SkillButtonGo.SetActive(true);
            playerCard.SetSkill(hasUsed ? "ĐÃ DÙNG" : "🌊 TRIỀU DÂNG", OnPlayerSkillTrieuDangClicked);
            playerCard.SetSkillState(isMyTurn && !hasUsed);
            var btnImg = playerCard.SkillButtonGo.GetComponent<UnityEngine.UI.Image>();
            if (btnImg != null)
            {
                btnImg.color = (isMyTurn && !hasUsed) ? new UnityEngine.Color(0.15f, 0.55f, 0.95f, 1f) : new UnityEngine.Color(0.12f, 0.16f, 0.24f, 0.7f);
            }
        }
        else
        {
            var h = HeroDatabase100.GetHeroByName(heroName);
            if (h != null && !string.IsNullOrEmpty(h.skillName))
            {
                playerCard.SkillButtonGo.SetActive(true);
                playerCard.SetSkill($"⚡ {h.skillName.ToUpper()}", () =>
                {
                    SetLog($"⚡ <color=#FFD700><b>[{h.skillName}]</b></color>: {h.skillDesc}");
                });
                playerCard.SetSkillState(true);
            }
            else
            {
                playerCard.SkillButtonGo.SetActive(false);
            }
        }
    }

    private void UpdateActionButtonState()
    {
        UpdatePlayerSkillButtonState();
        if (actionBtnGo == null || currentSelectedCardUI == null || currentSelectedCardUI.Data == null)
        {
            if (actionBtnGo != null) actionBtnGo.SetActive(false);
            return;
        }

        var card = currentSelectedCardUI.Data;
        var btn = actionBtnGo.GetComponent<Button>();
        var btnImg = actionBtnGo.GetComponent<Image>();

        actionBtnGo.SetActive(true);

        if (card.subType == CardSubType.Dodge)
        {
            if (!CanActAsSlash(playerCard, card))
            {
                btn.interactable = false;
                btnImg.color = new Color(0.4f, 0.45f, 0.55f, 0.9f);
                actionBtnText.text = "🛡️ LÁ PHẢN ỨNG (DÙNG KHI BỊ TẤN CÔNG)";
                SetLog("🛡️ [Đỡ]: Lá này chỉ dùng để hóa giải đòn tấn công khi bị Trảm.");
                return;
            }
        }

        if (card.subType == CardSubType.FlawlessDefense || (!string.IsNullOrEmpty(card.cardName) && card.cardName.Contains("Diệu Kế")))
        {
            btn.interactable = false;
            btnImg.color = new Color(0.4f, 0.45f, 0.55f, 0.9f);
            actionBtnText.text = "🛡️ LÁ PHẢN ỨNG (HÓA GIẢI CẨM NANG)";
            SetLog("🛡️ [Diệu Kế Phá Mưu]: Lá này tự động kích hoạt qua bảng hỏi khi có Cẩm nang được tung ra trên bàn đấu.");
            return;
        }

        if (card.subType == CardSubType.Peach && playerCard.CurrentHp >= playerCard.MaxHp)
        {
            btn.interactable = false;
            btnImg.color = new Color(0.4f, 0.45f, 0.55f, 0.9f);
            actionBtnText.text = "💮 MÁU ĐÃ ĐẦY (KHÔNG THỂ HỒI)";
            SetLog($"💮 Máu của bạn đã đầy ({playerCard.CurrentHp}/{playerCard.MaxHp}), không thể sử dụng thêm Bánh Chưng!");
            return;
        }

        if (CanActAsSlash(playerCard, card) && IsSlashLimitReached(playerCard, card))
        {
            btn.interactable = false;
            btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
            actionBtnText.text = "❌ ĐÃ DÙNG 1 TRẢM TRONG LƯỢT";
            SetLog("❌ <color=#FF5555>Bạn đã dùng 1 lá Trảm trong lượt này rồi!</color>");
            return;
        }

        if (RequiresTarget(card))
        {
            if (currentSelectedTarget == null || currentSelectedTarget == playerCard || currentSelectedTarget.CurrentHp <= 0)
            {
                btn.interactable = false;
                btnImg.color = new Color(0.45f, 0.5f, 0.55f, 0.95f);
                actionBtnText.text = "🎯 HÃY CHỌN MỤC TIÊU";
                SetLog($"🎯 Đã chọn {GetFormattedCardName(card)}. Hãy chạm chọn 1 mục tiêu trên bàn đấu!");
                return;
            }

            if (IsSameTeamSeat(playerCard.SeatNumber, currentSelectedTarget.SeatNumber))
            {
                btn.interactable = false;
                btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
                actionBtnText.text = "❌ KHÔNG THỂ NHẮM ĐỒNG MINH";
                SetLog("❌ Chỉ được chọn tướng đối phương làm mục tiêu.");
                return;
            }

            if (CanActAsSlash(playerCard, card) && !IsTargetInAttackRange(playerCard, currentSelectedTarget, card))
            {
                int dist = CalculateDistance(playerCard, currentSelectedTarget);
                if (playerCard.HeroId == "2") dist -= 2;
                int range = playerCard.GetAttackRange();
                btn.interactable = false;
                btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
                actionBtnText.text = $"❌ NGOÀI TẦM ĐÁNH (CỰ LY {dist} > TẦM {range})";
                SetLog($"❌ Mục tiêu [{currentSelectedTarget.GeneralName}] ở Cự ly {dist} vượt quá Tầm đánh {range} của bạn!");
                return;
            }

            if (card.subType == CardSubType.Snatch && CalculateDistance(playerCard, currentSelectedTarget) > 1)
            {
                int dist = CalculateDistance(playerCard, currentSelectedTarget);
                btn.interactable = false;
                btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
                actionBtnText.text = $"❌ CỰ LY QUÁ XA (CỰ LY {dist} > 1)";
                SetLog($"❌ [Đột Kích Trộm Lương] chỉ tác dụng ở Cự ly 1 (Hiện tại là {dist})!");
                return;
            }

            if (card.subType == CardSubType.SupplyShortage && CalculateDistance(playerCard, currentSelectedTarget) > 1)
            {
                int dist = CalculateDistance(playerCard, currentSelectedTarget);
                btn.interactable = false;
                btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
                actionBtnText.text = $"❌ CỰ LY QUÁ XA (CỰ LY {dist} > 1)";
                SetLog($"❌ [Cắt Đường Lương] chỉ gài ở Cự ly 1 (Hiện tại là {dist})!");
                return;
            }

            if (card.subType == CardSubType.Snatch || card.subType == CardSubType.Dismantle)
            {
                var targetOptions = BuildTargetCardOptions(currentSelectedTarget, true);
                if (targetOptions == null || targetOptions.Count == 0)
                {
                    btn.interactable = false;
                    btnImg.color = new Color(0.55f, 0.25f, 0.25f, 0.9f);
                    actionBtnText.text = "❌ MỤC TIÊU KHÔNG CÒN BÀI";
                    SetLog($"❌ Mục tiêu [{currentSelectedTarget.GeneralName}] không còn lá bài nào trên tay, trang bị hay phán xét để cướp/hủy!");
                    return;
                }
            }

            btn.interactable = true;
            btnImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);

            if (CanActAsSlash(playerCard, card)) actionBtnText.text = $"⚔️ TRẢM [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.Snatch) actionBtnText.text = $"🌾 TRỘM LƯƠNG [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.Dismantle) actionBtnText.text = $"🏚️ PHÁ HỦY BÀI [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.FlawlessDefense) actionBtnText.text = $"🛡️ HỦY BÀI [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.Duel) actionBtnText.text = $"⚔️ THÁCH ĐẤU [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.IronChain) actionBtnText.text = $"⛓️ KHÓA/GỠ XÍCH [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.SupplyShortage) actionBtnText.text = $"🌾 GÀI CẮT LƯƠNG [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else if (card.subType == CardSubType.Acedia) actionBtnText.text = $"🕸️ GÀI TRẦM ẢO [{currentSelectedTarget.GeneralName.ToUpper()}]";
            else actionBtnText.text = $"🃏 DÙNG LÊN [{currentSelectedTarget.GeneralName.ToUpper()}]";

            SetLog($"💡 Nhấn nút [{actionBtnText.text}] để thi triển!");
        }
        else
        {
            btn.interactable = true;
            btnImg.color = new Color(0.92f, 0.65f, 0.15f, 1f);

            if (card.category == CardCategory.Equipment)
                actionBtnText.text = $"🛡️ TRANG BỊ [{card.cardName.ToUpper()}]";
            else if (card.subType == CardSubType.Peach)
                actionBtnText.text = "💮 HỒI 1 HOA SEN MÁU";
            else if (card.subType == CardSubType.Wine)
                actionBtnText.text = "🍶 UỐNG HỦ RƯỢU (+1 CÔNG)";
            else if (card.subType == CardSubType.ExNihilo)
                actionBtnText.text = "📜 RÚT 2 LÁ BÀI (DỤNG BINH)";
            else if (card.subType == CardSubType.Harvest)
                actionBtnText.text = "🍚 MỞ KHO CỨU TẾ (CHIA ĐỀU BÀI)";
            else if (card.subType == CardSubType.BarbarianInvasion)
                    actionBtnText.text = "🪵 BÃI CỌC NGẦM (TẤT CẢ NGƯỜI KHÁC)";
            else if (card.subType == CardSubType.ArrowRain)
                    actionBtnText.text = "🏹 MƯA TÊN LIÊN CHÂU (TẤT CẢ NGƯỜI KHÁC)";
            else if (card.subType == CardSubType.Lightning)
                actionBtnText.text = "⚡ GÀI THẦN SẤM BÁO ỨNG";
            else
                actionBtnText.text = $"🃏 DÙNG [{card.cardName.ToUpper()}]";

            SetLog($"💡 Nhấn nút [{actionBtnText.text}] để sử dụng lá bài.");
        }
    }

    private void OnPlayerActionBtnClicked()
    {
        if (currentSelectedCardUI == null || currentSelectedCardUI.Data == null || !isPlayerTurnActive || actionInProgress) return;
        var cardUI = currentSelectedCardUI;
        var target = currentSelectedTarget != null ? currentSelectedTarget : playerCard;

        if (actionBtnGo != null) actionBtnGo.SetActive(false);
        HideCardDescription();
        StartCoroutine(ExecutePlayerCardPlay(cardUI, target));
    }

    private IEnumerator ExecutePlayerCardPlay(CardUI cardUI, GeneralCardUI target)
    {
        actionInProgress = true;
        var card = cardUI.Data;

        if (RequiresTarget(card) && (target == null || target == playerCard))
        {
            target = null;
        }

        if (DenoGameClient.IsConnected)
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "PLAY_CARD",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                cardId = card.id,
                targetSeat = target != null ? target.SeatNumber : 0
            }, (s) => { if (s != null) ApplyServerGameState(s); });

            currentSelectedCardUI = null;
            playerHandUI.ClearSelection();
            HideCardDescription();
            ClearSelectedTarget();
            yield break;
        }

        turnTimer = 40.0f;

        playerHandCards.Remove(card);
        playerHandUI.RemoveCard(cardUI);
        currentSelectedCardUI = null;
        HideCardDescription();
        UpdateHandCountsVisual();

        if (card.category != CardCategory.Equipment && card.category != CardCategory.DelayedScroll)
        {
            deckManager.DiscardCard(card);
        }

        bool isSlash = IsSlashCard(card);
        int outgoingDamage = 1;
        bool isWine = false;
        if (isSlash)
        {
            isWine = playerCard.IsWineBuffActive || isWineBuffActive;
            outgoingDamage = isWine ? 2 : 1;
        }

        yield return ResolveFullCardEffect(card, playerCard, target, outgoingDamage);

        ClearSelectedTarget();
        actionInProgress = false;
        ResumeTurnTimer(); // Khôi phục lại đếm ngược lượt của người chơi sau khi xử lý xong bài
    }

    private void ClearSelectedTarget()
    {
        currentSelectedTarget = null;
        if (targetHighlightGo != null)
        {
            targetHighlightGo.SetActive(false);
        }
    }
    #endregion

    private GeneralCardUI GetGeneralBySeat(int seat)
    {
        if (allGenerals != null)
        {
            foreach (var g in allGenerals)
            {
                if (g != null && g.SeatNumber == seat) return g;
            }
        }
        return null;
    }

    #region GIAI ĐOẠN RA BÀI CỦA NGƯỜI CHƠI THẬT TỪ XA (REAL-TIME REMOTE TURN)
    private IEnumerator StartRemotePlayerPlayPhase(GeneralCardUI remoteGen)
    {
        if (!string.IsNullOrEmpty(currentRoomId))
        {
            yield break;
        }

        turnTimer = 40.0f;
        isTimerRunning = true;
        remoteGen.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
        if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(false);

        SetLog($"👉 <b>Lượt của {remoteGen.GeneralName}!</b> Đang chờ người chơi ra bài... (Thời gian: 40s)");

        bool remoteTurnActive = true;

        Action<AppwriteMatchmaking.BattleActionPacket> onRemoteAction = (act) =>
        {
            if (act != null && act.casterSeat == remoteGen.SeatNumber)
            {
                if (act.actionType == "END_TURN")
                {
                    SetLog($"👑 <b>{remoteGen.GeneralName}</b> đã kết thúc lượt ra bài.");
                    remoteTurnActive = false;
                }
                else if (act.actionType != "END_TURN" && !string.IsNullOrEmpty(act.cardId) && !processedActionTimestamps.Contains(act.timestamp))
                {
                    processedActionTimestamps.Add(act.timestamp);
                    var playedCard = CardDatabase.GetCardById(act.cardId);
                    if (playedCard == null)
                    {
                        playedCard = CardDatabase.CreateCard(
                            act.cardId,
                            act.cardName,
                            (CardSuit)act.cardSuit,
                            (CardRank)act.cardRank,
                            1,
                            (CardCategory)act.cardCategory,
                            (CardSubType)act.cardSubType,
                            "",
                            "",
                            act.attackRange
                        );
                    }

                    var target = GetGeneralBySeat(act.targetSeat);
                    if (target == null || (target == remoteGen && RequiresTarget(playedCard)))
                    {
                        target = GetAliveOpponent(remoteGen);
                    }
                    var rHand = GetHandOfGeneral(remoteGen);
                    int removed = rHand.RemoveAll(c => c.id == act.cardId || c.cardName == act.cardName);
                    if (removed == 0 && rHand.Count > 0) rHand.RemoveAt(0);
                    UpdateHandCountsVisual();

                    turnTimer = 40.0f;
                    StartCoroutine(ExecuteRemoteCardPlay(playedCard, remoteGen, target, act.damage));
                }
            }
        };

        AppwriteRealtimeClient.OnBattleActionReceived += onRemoteAction;

        float nextPollTime = 0f;

        while (remoteTurnActive && turnTimer > 0f && remoteGen.CurrentHp > 0 && !battleFinished)
        {
            if (Time.unscaledTime >= nextPollTime && !string.IsNullOrEmpty(currentRoomId))
            {
                nextPollTime = Time.unscaledTime + 1.2f;
                StartCoroutine(AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                {
                    foreach (var act in actions)
                    {
                        onRemoteAction(act);
                    }
                }));
            }

            yield return null;
        }

        AppwriteRealtimeClient.OnBattleActionReceived -= onRemoteAction;

        if (turnTimer <= 0f)
        {
            SetLog($"⏰ <b>{remoteGen.GeneralName}</b> hết thời gian lượt đấu.");
        }

        isTimerRunning = false;
        remoteGen.HideHeadTimer();
    }

    private IEnumerator ExecuteRemoteCardPlay(CardModel card, GeneralCardUI caster, GeneralCardUI target, int explicitDamage = 0)
    {
        if (!string.IsNullOrEmpty(currentRoomId))
        {
            ShowCardAtCenter(card, caster, target);
            AudioManager.Instance.PlayCardSelect();
            yield return new WaitForSeconds(0.6f);
            actionInProgress = false;
            ResumeTurnTimer();
            yield break;
        }

        actionInProgress = true;
        if (card.category != CardCategory.Equipment && card.category != CardCategory.DelayedScroll)
        {
            deckManager.DiscardCard(card);
        }
        yield return ResolveFullCardEffect(card, caster, target, explicitDamage);
        actionInProgress = false;
        ResumeTurnTimer(); // Khôi phục lại đếm ngược lượt khi xử lý xong bài
    }
    #endregion

    #region 7. GIAI ĐOẠN RA BÀI CỦA AI (CÁCH NHAU 2 GIÂY ĐỂ KỊP NHÌN)
    private IEnumerator StartAIPlayPhase(GeneralCardUI aiGeneral)
    {
        if (!string.IsNullOrEmpty(currentRoomId))
        {
            yield break;
        }

        turnTimer = 40.0f;
        isTimerRunning = true;
        aiGeneral.ShowHeadTimer(Mathf.CeilToInt(turnTimer));
        if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(false);

        var hand = GetHandOfGeneral(aiGeneral);

        SetLog($"🤖 <b>{aiGeneral.GeneralName}</b> đang suy tính chiến thuật...");
        yield return new WaitForSeconds(1.0f);

        bool acted = true;
        int maxPlays = 6;

        while (acted && maxPlays > 0 && aiGeneral.CurrentHp > 0 && turnTimer > 0f && !battleFinished)
        {
            acted = false;
            maxPlays--;

            CardModel cardToPlay = null;
            GeneralCardUI target = null;

            if (aiGeneral.CurrentHp < aiGeneral.MaxHp)
            {
                cardToPlay = hand.Find(c => c.subType == CardSubType.Peach);
                if (cardToPlay != null) target = aiGeneral;
            }

            if (cardToPlay == null)
            {
                cardToPlay = hand.Find(c => c.category == CardCategory.Equipment);
                if (cardToPlay != null) target = aiGeneral;
            }

            if (cardToPlay == null)
            {
                cardToPlay = hand.Find(c => c.subType == CardSubType.ExNihilo || c.subType == CardSubType.Harvest);
                if (cardToPlay != null) target = aiGeneral;
            }

            if (cardToPlay == null)
            {
                var opponent = GetAliveOpponent(aiGeneral);
                if (opponent != null)
                {
                    var snatchCard = hand.Find(c => c.subType == CardSubType.Snatch);
                    if (snatchCard != null && CalculateDistance(aiGeneral, opponent) <= 1 && BuildTargetCardOptions(opponent, true).Count > 0)
                    {
                        cardToPlay = snatchCard;
                        target = opponent;
                    }
                }
            }

            if (cardToPlay == null)
            {
                var opponent = GetAliveOpponent(aiGeneral);
                if (opponent != null)
                {
                    var dismantleCard = hand.Find(c => c.subType == CardSubType.Dismantle && BuildTargetCardOptions(opponent, false).Count > 0);
                    if (dismantleCard != null)
                    {
                        cardToPlay = dismantleCard;
                        target = opponent;
                    }
                }
            }

            if (cardToPlay == null)
            {
                var duelCard = hand.Find(c => c.subType == CardSubType.Duel);
                if (duelCard != null)
                {
                    cardToPlay = duelCard;
                    target = GetAliveOpponent(aiGeneral);
                }
            }

            if (cardToPlay == null)
            {
                cardToPlay = hand.Find(c => c.subType == CardSubType.BarbarianInvasion || c.subType == CardSubType.ArrowRain);
                if (cardToPlay != null) target = aiGeneral;
            }

            if (cardToPlay == null)
            {
                var wine = hand.Find(c => c.subType == CardSubType.Wine);
                var slash = hand.Find(c => IsSlashCard(c));
                var opponent = GetAliveOpponent(aiGeneral);
                if (wine != null && slash != null && !aiGeneral.IsWineBuffActive && opponent != null && IsTargetInAttackRange(aiGeneral, opponent))
                {
                    cardToPlay = wine;
                    target = aiGeneral;
                }
            }

            if (cardToPlay == null)
            {
                if (!IsSlashLimitReached(aiGeneral, null))
                {
                    var slash = hand.Find(c => IsSlashCard(c));
                    if (slash != null)
                    {
                        foreach (var g in allGenerals)
                        {
                            if (g.IsAlly != aiGeneral.IsAlly && g.CurrentHp > 0 && IsTargetInAttackRange(aiGeneral, g))
                            {
                                cardToPlay = slash;
                                target = g;
                                break;
                            }
                        }
                    }
                }
            }

            if (cardToPlay != null)
            {
                acted = true;
                hand.Remove(cardToPlay);
                UpdateHandCountsVisual();

                if (cardToPlay.category != CardCategory.Equipment && cardToPlay.category != CardCategory.DelayedScroll)
                {
                    deckManager.DiscardCard(cardToPlay);
                }

                bool isAISlash = IsSlashCard(cardToPlay);
                int aiOutgoingDmg = 1;
                bool isAIWine = false;
                if (isAISlash)
                {
                    isAIWine = aiGeneral.IsWineBuffActive;
                    aiOutgoingDmg = isAIWine ? 2 : 1;
                }

                if (!string.IsNullOrEmpty(currentRoomId))
                {

                    if (IsAIController())
                    {
                        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                        {
                            action = "PLAY_CARD",
                            roomId = currentRoomId,
                            seat = aiGeneral.SeatNumber,
                            cardId = cardToPlay.id,
                            damage = aiOutgoingDmg,
                            isWineBuff = isAIWine,
                            targetSeat = target != null ? target.SeatNumber : 0
                        }, (s) => { if (s != null) ApplyServerGameState(s); });
                    }
                }

                yield return ResolveFullCardEffect(cardToPlay, aiGeneral, target, aiOutgoingDmg);

                // Đánh lá mới lại có lại 40s suy nghĩ
                turnTimer = 40.0f;
                ResumeTurnTimer();

                // Tăng thời gian dùng bài của AI lên 3s để người chơi kịp theo dõi
                yield return new WaitForSeconds(3.0f);
            }
        }

        isTimerRunning = false;
        aiGeneral.HideHeadTimer();

        if (!string.IsNullOrEmpty(currentRoomId))
        {

            if (IsAIController())
            {
                DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                {
                    action = "END_TURN",
                    roomId = currentRoomId,
                    seat = aiGeneral.SeatNumber
                }, (s) => { if (s != null) ApplyServerGameState(s); });
            }
        }
    }

    private GeneralCardUI GetAliveOpponent(GeneralCardUI self)
    {
        var enemies = new List<GeneralCardUI>();
        foreach (var g in allGenerals)
        {
            if (g.IsAlly != self.IsAlly && g.CurrentHp > 0)
            {
                enemies.Add(g);
            }
        }
        if (enemies.Count == 0) return null;
        return enemies[UnityEngine.Random.Range(0, enemies.Count)];
    }
    #endregion

    #region 8. ENGINE XỬ LÝ TOÀN BỘ TÁC DỤNG THẺ BÀI CHUẨN TUTORIAL
    private IEnumerator ResolveFullCardEffect(CardModel card, GeneralCardUI caster, GeneralCardUI target, int explicitDamage = 0)
    {
        if (card == null || caster == null || battleFinished) yield break;

        if (DenoGameClient.IsConnected)
        {
            ShowCardAtCenter(card, caster, target);
            AudioManager.Instance.PlayCardSelect();
            yield return new WaitForSeconds(0.6f);
            yield break;
        }

        switch (card.category)
        {
            case CardCategory.Basic:
                if (CanActAsSlash(caster, card))
                {
                    slashesUsedThisTurn++;
                    yield return ResolveSlashAttack(card, caster, target, explicitDamage);
                }
                else if (card.subType == CardSubType.Peach)
                {
                    ShowCardAtCenter(card, caster, null, "Hồi 1 đóa sen máu");
                    caster.Heal(1);
                    AudioManager.Instance.PlayHeal();
                    SetLog($"💮 <b>{caster.GeneralName}</b> dùng [Bánh Chưng] hồi 1 đóa sen máu! ({caster.CurrentHp}/{caster.MaxHp})");
                }
                else if (card.subType == CardSubType.Wine)
                {
                    ShowCardAtCenter(card, caster, null, "Tăng +1 công đòn Trảm kế tiếp");
                    caster.IsWineBuffActive = true;
                    isWineBuffActive = true;
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🍶 <b>{caster.GeneralName}</b> uống [Hủ Rượu]: Đòn Trảm kế tiếp gây +1 sát thương (+2 tổng)! ");
                }
                break;

            case CardCategory.Equipment:
                ShowCardAtCenter(card, caster, null, $"Trang bị {GetFormattedCardName(card)}");
                AudioManager.Instance.PlaySkill();
                if (caster.TryEquip(card, out var replaced))
                {
                    if (replaced != null) deckManager.DiscardCard(replaced);
                    SetLog($"🛡️ <b>{caster.GeneralName}</b> trang bị {GetFormattedCardName(card)}: {card.description}");
                }
                break;

            case CardCategory.InstantScroll:
                yield return ResolveInstantScroll(card, caster, target);
                break;

            case CardCategory.DelayedScroll:
                yield return ResolveDelayedScrollPlacement(card, caster, target);
                break;
        }

        yield return new WaitForSeconds(0.4f);
    }

    /// <summary>
    /// Xử lý sát thương có tính toán Áo Bào Hoàng Tộc: Giảm 1 điểm sát thương (sàn 0), tối đa 3 lần.
    /// Khi hết 3 lần, Áo Bào tiêu biến.
    /// </summary>
    private int ApplyDamageMitigation(GeneralCardUI victim, int rawDamage, string sourceName)
    {
        if (victim == null || rawDamage <= 0) return rawDamage;

        if (victim.HasEquipment(EquipmentType.Armor, "Áo Bào"))
        {
            if (victim.AoBaoCharges > 0)
            {
                victim.TryConsumeAoBaoCharge();
                int finalDamage = Mathf.Max(0, rawDamage - 1);
                SetLog($"🛡️ <color=#FFD700><b>[ÁO BÀO HOÀNG TỘC]</b></color>: Giảm 1 sát thương từ {sourceName} (còn {victim.AoBaoCharges}/3 lần)! Nhận {finalDamage} sát thương.");

                if (victim.AoBaoCharges == 0)
                {
                    if (victim.TryUnequip(EquipmentType.Armor, out var unequipped))
                    {
                        if (unequipped != null) deckManager.DiscardCard(unequipped);
                        SetLog($"🛡️ <b>{victim.GeneralName}</b>: [Áo Bào Hoàng Tộc] đã cản đủ 3 lần và tiêu biến!");
                    }
                }
                return finalDamage;
            }
        }

        return rawDamage;
    }

    /// <summary>
    /// Kỹ năng Khiên Mây Bện (Bát Quái Trận): Mỗi khi cần đánh lá [Đỡ], lật 1 lá bài phán xét.
    /// Nếu là chất ĐỎ (♥, ♦) -> Coi như đã đánh 1 lá [Đỡ] thành công!
    /// </summary>
    private IEnumerator TryKhienMayDefense(GeneralCardUI defender, string attackName, Action<bool> callback)
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

        // Rút lá bài phán xét (có hiệu ứng bay từ cọc bài rút)
        yield return AnimateDealtCard(defender);
        var judgeCard = deckManager.DrawCard();
        if (judgeCard == null)
        {
            callback?.Invoke(false);
            yield break;
        }

        bool isRed = (judgeCard.suit == CardSuit.Heart || judgeCard.suit == CardSuit.Diamond);
        string suitSym = judgeCard.GetSuitSymbol();
        string rankStr = judgeCard.GetRankString();

        // 2. Tạo hoạt cảnh phán xét trung tâm với lá bài và biểu tượng TICK ✔ / X ✖
        var parentTransform = battleRootGo != null ? battleRootGo.transform : canvasGo.transform;
        var judgeCardGo = CardUI.Create(parentTransform, judgeCard, new Vector2(110f, 150f)).gameObject;
        judgeCardGo.transform.SetAsLastSibling();

        var rt = judgeCardGo.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = new Vector2(-80f, 20f);
        judgeCardGo.transform.localScale = Vector3.one * 0.6f;

        // Phóng to lá bài mượt mà bằng PopOut
        judgeCardGo.transform.localScale = Vector3.one * 0.1f;
        yield return PopOutCard(rt, new Vector2(-80f, 20f), new Vector2(-80f, 20f), 1.15f);

        // Hộp tiêu đề phán xét phía trên lá bài
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

        var titleTxt = AddText(titleBoxGo.transform, "Txt", "🛡️ PHÁN XÉT KHIÊN MÂY BỆN", 11, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(titleTxt.rectTransform);

        // Huy hiệu TICK ✔ (Xanh lá) hoặc X ✖ (Đỏ) ở giữa lá bài
        var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
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
        var icShadow = iconGo.AddComponent<Shadow>();
        icShadow.effectColor = new Color(0, 0, 0, 0.95f);
        icShadow.effectDistance = new Vector2(2f, -2f);
        Fill(iconGo.GetComponent<RectTransform>());

        // Nhãn kết quả bên dưới lá bài
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
        var lShadow = labelGo.AddComponent<Shadow>();
        lShadow.effectColor = new Color(0, 0, 0, 0.95f);
        lShadow.effectDistance = new Vector2(1f, -1f);
        var lRt = labelGo.GetComponent<RectTransform>();
        lRt.anchorMin = lRt.anchorMax = new Vector2(0.5f, 0f);
        lRt.pivot = new Vector2(0.5f, 1f);
        lRt.sizeDelta = new Vector2(300f, 44f);
        lRt.anchoredPosition = new Vector2(0, -8f);

        // Âm thanh và nhật ký
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

        // Chờ 1.4s để người chơi nhìn rõ kết quả phán xét
        yield return new WaitForSeconds(1.4f);

        Destroy(judgeCardGo);
        deckManager.DiscardCard(judgeCard);

        callback?.Invoke(isRed);
    }

    private IEnumerator ResolveSlashAttack(CardModel card, GeneralCardUI caster, GeneralCardUI target, int explicitDamage = 0)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        if (target == null || target.CurrentHp <= 0) yield break;

        yield return AnimateSlashAttack(card, caster, target);

        bool isWine = (explicitDamage >= 2) || caster.IsWineBuffActive || isWineBuffActive;
        int damage = (explicitDamage > 0) ? explicitDamage : (isWine ? 2 : 1);
        string wineLog = isWine ? " <color=#FFD700><b>(kèm hiệu ứng Hủ Rượu: +1 Sát thương -> 2 Tổng!)</b></color>" : "";
        caster.IsWineBuffActive = false;
        isWineBuffActive = false;

        SetLog($"⚔️ <b>{caster.GeneralName}</b> tung chiêu {GetFormattedCardName(card)}{wineLog} nhắm vào <b>{target.GeneralName}</b>!");
        yield return new WaitForSeconds(0.4f);

        if (target.HasEquipment(EquipmentType.Armor, "Giáp Đồng") && card.subType == CardSubType.AttackNormal)
        {
            AudioManager.Instance.PlayParry();
            SetLog($"🛡️ <color=#70D8FF><b>[GIÁP ĐỒNG SƠN VI]</b></color>: Giáp Đồng vô hiệu hóa hoàn toàn đòn {GetFormattedCardName(card)} của {caster.GeneralName}!");
            yield break;
        }

        bool dodged = false;
        bool hasHolyCannon = caster.HasEquipment(EquipmentType.Weapon, "Súng Thần Công");

        PauseTurnTimer(); // Tạm dừng và ẩn bộ đếm của người ra bài trong lúc chờ mục tiêu phản ứng
        target.SetAwaitingReaction(true); // Nhấp nháy nhẹ avatar khi cần phản ứng né đòn

        // 1. Kiểm tra Khiên Mây Bện (Phán xét Bát Quái né Trảm)
        if (target.HasEquipment(EquipmentType.Armor, "Khiên Mây"))
        {
            yield return TryKhienMayDefense(target, "đòn Trảm", (success) =>
            {
                if (success) dodged = true;
            });
        }

        // 2. Nếu Khiên Mây chưa né được thì mới xét bài Đỡ trên tay
        if (!dodged)
        {
            if (target == playerCard)
            {
                yield return AwaitForPlayerSlashDefense(card, damage, hasHolyCannon, (res) =>
                {
                    if (res == SlashDefenseResult.Dodged) dodged = true;
                });

                if (!string.IsNullOrEmpty(currentRoomId))
                {
                }
            }
            else if (!target.IsAI && !string.IsNullOrEmpty(currentRoomId))
            {
                // Người chơi thật khác bị Trảm -> Đợi phản hồi Đỡ từ máy của họ (40s)
                SetLog($"⏳ Đang đợi <b>{target.GeneralName}</b> phản ứng (Đỡ hoặc Chịu sát thương)... (40s)");
                target.ShowHeadTimer(40);
                bool remoteResolved = false;
                float waitTimer = 40.0f;

                while (!remoteResolved && waitTimer > 0f && !battleFinished)
                {
                    waitTimer -= 0.35f;
                    target.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                    yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                    {
                        foreach (var act in actions)
                        {
                            if (act.casterSeat == target.SeatNumber && act.actionType == "RESPONSE_SLASH" && !processedActionTimestamps.Contains(act.timestamp))
                            {
                                processedActionTimestamps.Add(act.timestamp);
                                remoteResolved = true;
                                if (act.accepted)
                                {
                                    dodged = true;
                                    var tHand = GetHandOfGeneral(target);
                                    if (tHand.Count > 0) tHand.RemoveAt(0);
                                    UpdateHandCountsVisual();
                                    AudioManager.Instance.PlayParry();
                                    SetLog($"🛡️ <b>{target.GeneralName}</b> đã dùng [ĐỠ] hóa giải đòn Trảm!");
                                }
                                else
                                {
                                    dodged = false;
                                }
                            }
                        }
                    });

                    if (remoteResolved) break;
                    yield return new WaitForSecondsRealtime(0.35f);
                }

                if (!remoteResolved && waitTimer <= 0f)
                {
                    SetLog($"⏰ <b>{target.GeneralName}</b> đã hết 40s phản ứng, tự động chịu sát thương.");
                    dodged = false;
                }

                target.HideHeadTimer();
            }
            else
            {
                target.ShowHeadTimer(40);
                target.UpdateHeadTimer(40);
                yield return new WaitForSeconds(1.0f);
                var hand = GetHandOfGeneral(target);
                var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit == card.suit));
                if (legalDodge != null)
                {
                    hand.Remove(legalDodge);
                    deckManager.DiscardCard(legalDodge);
                    UpdateHandCountsVisual();
                    ShowCardAtCenter(legalDodge, target, caster, "Hóa giải đòn đánh");
                    AudioManager.Instance.PlayParry();
                    SetLog($"🛡️ <b>{target.GeneralName}</b> đánh ra {GetFormattedCardName(legalDodge)} né đòn Trảm!");
                    dodged = true;
                    yield return new WaitForSeconds(0.8f);
                }
                else if (hasHolyCannon)
                {
                    SetLog($"💥 <color=#FF5555><b>[SÚNG THẦN CÔNG HỒ TRIỀU]</b></color>: {target.GeneralName} không thể dùng Đỡ cùng chất!");
                }
                target.HideHeadTimer();
            }
        }

        target.SetAwaitingReaction(false); // Dừng nhấp nháy sau khi đã phản ứng xong

        // 2.5. HIỆU ỨNG SONG CUNG MƯỜNG NHẠ: KHI BỊ ĐỠ, HỎI CASTER CÓ BỎ 2 LÁ BÀI BẤT KỲ TRÊN TAY ÉP MỤC TIÊU CHỊU SÁT THƯƠNG KHÔNG
        if (dodged && caster.HasEquipment(EquipmentType.Weapon, "Song Cung") && !battleFinished)
        {
            var casterHand = GetHandOfGeneral(caster);
            if (casterHand != null && casterHand.Count >= 2)
            {
                bool casterWantsSongCung = false;
                List<CardModel> chosenCards = null;

                if (caster == playerCard)
                {
                    yield return PromptPlayerSongCungDiscard(caster, target, (wants, cards) =>
                    {
                        casterWantsSongCung = wants;
                        chosenCards = cards;
                    });
                }
                else if (caster.IsAI)
                {
                    yield return new WaitForSeconds(1.0f);
                    casterWantsSongCung = (UnityEngine.Random.value < 0.80f);
                    if (casterWantsSongCung && casterHand.Count >= 2)
                    {
                        chosenCards = new List<CardModel> { casterHand[0], casterHand[1] };
                    }
                }
                else
                {
                    yield return AwaitRemoteSongCungFollowUp(caster, target, (wants, cards) =>
                    {
                        casterWantsSongCung = wants;
                        chosenCards = cards;
                    });
                }

                if (casterWantsSongCung && chosenCards != null && chosenCards.Count == 2)
                {
                    foreach (var c in chosenCards)
                    {
                        casterHand.Remove(c);
                        deckManager.DiscardCard(c);
                    }
                    if (caster == playerCard)
                    {
                        playerHandUI.ClearHand();
                        playerHandUI.AddCards(playerHandCards);
                    }
                    UpdateHandCountsVisual();

                    AudioManager.Instance.PlaySkill();
                    ShowCardAtCenter(chosenCards[0], caster, target, "Song Cung Mường Nhạ");
                    SetLog($"🏹 <color=#FFD700><b>[SONG CUNG MƯỜNG NHẠ]</b></color>: <b>{caster.GeneralName}</b> bỏ 2 lá bài ép <b>{target.GeneralName}</b> vẫn phải chịu 1 sát thương!");

                    dodged = false; // Bỏ qua né đòn, ép trúng đích!
                }
            }
        }

        // 2.6. VÒNG LẶP TRƯỜNG ĐAO NAM SƠN: KHI BỊ ĐỠ, HỎI CASTER CÓ BỎ 1 LÁ TRẢM TIẾP TỤC TRUY KÍCH KHÔNG
        while (dodged && caster.HasEquipment(EquipmentType.Weapon, "Trường Đao") && !battleFinished)
        {
            var casterHand = GetHandOfGeneral(caster);
            var slashInHand = casterHand != null ? casterHand.Find(c => IsSlashCard(c)) : null;

            if (slashInHand == null)
            {
                // Caster không còn lá Trảm nào trên tay để bồi thêm
                break;
            }

            bool casterWantsFollowUp = false;
            CardModel chosenSlashCard = null;

            if (caster == playerCard)
            {
                yield return PromptPlayerNamSonFollowUp(caster, target, (wants, cardChosen) =>
                {
                    casterWantsFollowUp = wants;
                    chosenSlashCard = cardChosen;
                });
            }
            else if (caster.IsAI)
            {
                yield return new WaitForSeconds(1.0f);
                casterWantsFollowUp = (UnityEngine.Random.value < 0.85f);
                chosenSlashCard = slashInHand;
            }
            else
            {
                yield return AwaitRemoteNamSonFollowUp(caster, target, (wants, cardChosen) =>
                {
                    casterWantsFollowUp = wants;
                    chosenSlashCard = cardChosen;
                });
            }

            if (!casterWantsFollowUp || chosenSlashCard == null)
            {
                SetLog($"🛡️ <b>{caster.GeneralName}</b> từ chối dùng thêm Trảm. <b>{target.GeneralName}</b> đã né đòn thành công!");
                break;
            }

            // Caster chấp nhận bỏ 1 lá Trảm để tiếp tục truy kích!
            casterHand.Remove(chosenSlashCard);
            deckManager.DiscardCard(chosenSlashCard);
            if (caster == playerCard) { playerHandUI.ClearHand(); playerHandUI.AddCards(playerHandCards); }
            UpdateHandCountsVisual();

            AudioManager.Instance.PlaySkill();
            ShowCardAtCenter(chosenSlashCard, caster, target, "Trường Đao - Trảm Bồi");
            SetLog($"🗡️ <color=#FFD700><b>[TRƯỜNG ĐAO NAM SƠN]</b></color>: <b>{caster.GeneralName}</b> bỏ thêm 1 lá [<b>{chosenSlashCard.cardName}</b>] tiếp tục truy kích <b>{target.GeneralName}</b>!");

            yield return new WaitForSeconds(0.8f);

            // MỤC TIÊU LẠI PHẢI ĐỠ TIẾP (40s)
            dodged = false;
            target.SetAwaitingReaction(true);

            // Kiểm tra Khiên Mây
            if (target.HasEquipment(EquipmentType.Armor, "Khiên Mây"))
            {
                yield return TryKhienMayDefense(target, "đòn Trảm truy kích", (success) =>
                {
                    if (success) dodged = true;
                });
            }

            if (!dodged)
            {
                if (target == playerCard)
                {
                    yield return AwaitForPlayerSlashDefense(chosenSlashCard, damage, hasHolyCannon, (res) =>
                    {
                        if (res == SlashDefenseResult.Dodged) dodged = true;
                    });
                }
                else if (!target.IsAI && !string.IsNullOrEmpty(currentRoomId))
                {
                    SetLog($"⏳ Đang đợi <b>{target.GeneralName}</b> phản ứng đòn Trảm truy kích... (40s)");
                    target.ShowHeadTimer(40);
                    bool remoteResolved = false;
                    float waitTimer = 40.0f;

                    while (!remoteResolved && waitTimer > 0f && !battleFinished)
                    {
                        waitTimer -= 0.35f;
                        target.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                        yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                        {
                            foreach (var act in actions)
                            {
                                if (act.casterSeat == target.SeatNumber && act.actionType == "RESPONSE_SLASH" && !processedActionTimestamps.Contains(act.timestamp))
                                {
                                    processedActionTimestamps.Add(act.timestamp);
                                    remoteResolved = true;
                                    if (act.accepted)
                                    {
                                        dodged = true;
                                        var tHand = GetHandOfGeneral(target);
                                        if (tHand.Count > 0) tHand.RemoveAt(0);
                                        UpdateHandCountsVisual();
                                        AudioManager.Instance.PlayParry();
                                        SetLog($"🛡️ <b>{target.GeneralName}</b> đã dùng [ĐỠ] hóa giải đòn Trảm truy kích!");
                                    }
                                    else
                                    {
                                        dodged = false;
                                    }
                                }
                            }
                        });

                        if (remoteResolved) break;
                        yield return new WaitForSecondsRealtime(0.35f);
                    }

                    if (!remoteResolved && waitTimer <= 0f)
                    {
                        SetLog($"⏰ <b>{target.GeneralName}</b> đã hết 40s phản ứng, tự động chịu sát thương.");
                        dodged = false;
                    }

                    target.HideHeadTimer();
                }
                else
                {
                    target.ShowHeadTimer(40);
                    target.UpdateHeadTimer(40);
                    yield return new WaitForSeconds(1.0f);
                    var hand = GetHandOfGeneral(target);
                    var legalDodge = hand.Find(c => c.subType == CardSubType.Dodge && (!hasHolyCannon || c.suit == chosenSlashCard.suit));
                    if (legalDodge != null)
                    {
                        hand.Remove(legalDodge);
                        deckManager.DiscardCard(legalDodge);
                        UpdateHandCountsVisual();
                        ShowCardAtCenter(legalDodge, target, caster, "Hóa giải đòn đánh");
                        AudioManager.Instance.PlayParry();
                        SetLog($"🛡️ <b>{target.GeneralName}</b> đánh ra {GetFormattedCardName(legalDodge)} né đòn Trảm truy kích!");
                        dodged = true;
                        yield return new WaitForSeconds(0.8f);
                    }
                    target.HideHeadTimer();
                }
            }

            target.SetAwaitingReaction(false);
        }

        if (dodged)
        {
            yield break;
        }

        // 3. Áp dụng giảm sát thương Áo Bào Hoàng Tộc (tối đa 3 lần)
        int finalDamage = ApplyDamageMitigation(target, damage, "đòn Trảm");

        if (finalDamage > 0)
        {
            target.TakeDamage(finalDamage); AudioManager.Instance.PlayDamage(); StartCoroutine(ShakeCard(target)); StartCoroutine(ShowFloatingDamage(target, finalDamage));
            SetLog($"💥 <b>{target.GeneralName}</b> trúng đòn mất {finalDamage} máu! ({target.CurrentHp}/{target.MaxHp})");
            yield return CheckNearDeath(target, caster);
        }

        if (finalDamage > 0 && caster.HasEquipment(EquipmentType.Weapon, "Thương Ngâu") && target.CurrentHp > 0)
        {
            yield return new WaitForSeconds(0.4f);
            if (caster == playerCard)
            {
                bool chosen = false;
                ShowCardStealOrDestroyModal(target, false, "🔱 THƯƠNG NGÂU LÃNG BẠC: PHÁ HỦY 1 LÁ CỦA MỤC TIÊU", (discarded) =>
                {
                    deckManager.DiscardCard(discarded);
                    ShowCardAtCenter(discarded, target, null, "Bị phá hủy bởi Thương Ngâu");
                    AudioManager.Instance.PlaySkill();
                    SetLog($"🔱 [Thương Ngâu Lãng Bạc]: Bạn đã phá hủy lá {GetFormattedCardName(discarded)} của {target.GeneralName}!");
                    chosen = true;
                });
                while (!chosen && !battleFinished) yield return null;
            }
            else
            {
                var tHand = GetHandOfGeneral(target);
                if (tHand.Count > 0)
                {
                    var destroyed = tHand[0];
                    tHand.RemoveAt(0);
                    deckManager.DiscardCard(destroyed);
                    UpdateHandCountsVisual();
                    SetLog($"🔱 [Thương Ngâu Lãng Bạc]: {caster.GeneralName} phá hủy 1 lá bài của {target.GeneralName}!");
                }
            }
        }
    }

    private IEnumerator AwaitForPlayerSlashDefense(CardModel slashCard, int damage, bool hasHolyCannon, Action<SlashDefenseResult> onResolved)
    {
        if (isAwaitingSlashDefense)
        {
            yield break;
        }
        isAwaitingSlashDefense = true;
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;

        var existingPanel = GameObject.Find("SlashReactionPanel");
        if (existingPanel != null) Destroy(existingPanel);

        bool defenseResolved = false;
        var result = SlashDefenseResult.Hit;
        float reactionTimer = 40.0f;

        // Bật đếm ngược 40s bên trái avatar của người chơi bị đánh
        playerCard.ShowHeadTimer(40);

        SetLog("⚠️ <color=#FF5555><b>BẠN BỊ TẤN CÔNG BẰNG ĐÒN TRẢM!</b></color> " + (hasHolyCannon ? "[Súng Thần Công] KHÔNG được Đỡ bằng chất [{slashCard?.GetSuitSymbol()}]" : "Hãy chọn lá [ĐỠ] hoặc bấm [KHÔNG NÉ].") + " (Thời gian: 40s)");

        var reactionGo = new GameObject("SlashReactionPanel", typeof(RectTransform));
        reactionGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        var rRt = reactionGo.GetComponent<RectTransform>();
        SetRect(rRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(700f, 56f), new Vector2(-70f, 258f));

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

        var dodgeBtnGo = new GameObject("Btn_Dodge", typeof(RectTransform), typeof(Image), typeof(Button));
        dodgeBtnGo.transform.SetParent(reactionGo.transform, false);
        var dImg = dodgeBtnGo.GetComponent<Image>();
        if (btnSpr != null) { dImg.sprite = btnSpr; dImg.type = Image.Type.Sliced; }
        var dRt = dodgeBtnGo.GetComponent<RectTransform>();
        SetRect(dRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(300f, 48f), new Vector2(-120f, 0));

        string dodgeActionStr = "🛡️ ĐÁNH [ĐỠ] ĐỂ HÓA GIẢI";
        if (hasHolyCannon) dodgeActionStr = $"🛡️ ĐỠ KHÁC CHẤT {slashCard.GetSuitSymbol()}";
        var dTxt = AddText(dodgeBtnGo.transform, "Txt", dodgeActionStr, ThemeUI.SizeBodyLarge, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(dTxt.rectTransform);

        var dBtn = dodgeBtnGo.GetComponent<Button>();
        dBtn.interactable = false;
        dImg.color = new Color(0.40f, 0.44f, 0.52f, 0.85f);

        var noDodgeBtnGo = new GameObject("Btn_NoDodge", typeof(RectTransform), typeof(Image), typeof(Button));
        noDodgeBtnGo.transform.SetParent(reactionGo.transform, false);
        var ndImg = noDodgeBtnGo.GetComponent<Image>();
        if (btnSpr != null) { ndImg.sprite = btnSpr; ndImg.type = Image.Type.Sliced; }
        ndImg.color = ThemeUI.CrimsonRed;
        var ndRt = noDodgeBtnGo.GetComponent<RectTransform>();
        SetRect(ndRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(250f, 48f), new Vector2(175f, 0));

        var ndTxt = AddText(noDodgeBtnGo.transform, "Txt", "❌ KHÔNG NÉ (CHỊU MÁU)", ThemeUI.SizeBody, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(ndTxt.rectTransform);

        CardUI chosenDodgeUI = null;

        Action<CardUI> onCardSelectedReaction = (cardUI) =>
        {
            if (cardUI != null && cardUI.Data != null && CanActAsDodge(playerCard, cardUI.Data))
            {
                if (hasHolyCannon && cardUI.Data.suit == slashCard.suit)
                {
                    chosenDodgeUI = null;
                    dBtn.interactable = false;
                    dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
                    SetLog($"❌ [Súng Thần Công]: Không thể dùng lá Đỡ cùng chất [{cardUI.Data.GetSuitSymbol()}] với Trảm!");
                    return;
                }

                chosenDodgeUI = cardUI;
                dBtn.interactable = true;
                dImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                SetLog($"🛡️ Đã chọn {GetFormattedCardName(cardUI.Data)}. Nhấn nút [ĐÁNH ĐỠ ĐỂ HÓA GIẢI]!");
            }
            else
            {
                chosenDodgeUI = null;
                dBtn.interactable = false;
                dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
            }
        };

        playerHandUI.HighlightOnlyMatching(c => c != null && CanActAsDodge(playerCard, c) && (!hasHolyCannon || c.suit == slashCard.suit));
        playerHandUI.OnCardSelected += onCardSelectedReaction;

        if (playerHandUI.SelectedCard != null && playerHandUI.SelectedCard.Data != null && CanActAsDodge(playerCard, playerHandUI.SelectedCard.Data))
        {
            onCardSelectedReaction(playerHandUI.SelectedCard);
        }

        dBtn.onClick.AddListener(() =>
        {
            if (chosenDodgeUI != null)
            {
                var dodgeData = chosenDodgeUI.Data;
                if (!serverControlled)
                {
                    playerHandCards.Remove(dodgeData);
                    playerHandUI.RemoveCard(chosenDodgeUI);
                    deckManager.DiscardCard(dodgeData);
                    UpdateHandCountsVisual();
                }

                ShowCardAtCenter(dodgeData, playerCard, null, "Hóa giải đòn đánh");
                AudioManager.Instance.PlayParry();
                SetLog($"🛡️ <color=#55FF55><b>BẠN ĐÃ DÙNG [ĐỠ] HÓA GIẢI ĐÒN ĐÁNH!</b></color>");

                result = SlashDefenseResult.Dodged;
                defenseResolved = true;
            }
        });

        noDodgeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            result = SlashDefenseResult.Hit;
            defenseResolved = true;
        });

        while (!defenseResolved && !battleFinished && (!serverControlled || IsAuthoritativePromptActive("AWAIT_SLASH_DEFENSE")))
        {
            if (!serverControlled)
            {
                if (!string.IsNullOrEmpty(currentRoomId)) reactionTimer = turnTimer;
                reactionTimer -= Time.unscaledDeltaTime;
                playerCard.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(reactionTimer)));

                if (reactionTimer <= 0f)
                {
                    SetLog("⏰ <b>Đã hết 40s phản ứng!</b> Tự động không dùng Đỡ.");
                    result = SlashDefenseResult.Hit;
                    defenseResolved = true;
                    break;
                }
            }

            yield return null;
        }

        isAwaitingSlashDefense = false;
        playerCard.HideHeadTimer();
        playerHandUI.OnCardSelected -= onCardSelectedReaction;
        playerHandUI.ClearHighlights();
        if (reactionGo != null) Destroy(reactionGo);

        // Gửi phản hồi phòng thủ lên phòng đấu online
        if (serverControlled && defenseResolved && IsAuthoritativePromptActive("AWAIT_SLASH_DEFENSE"))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = (result == SlashDefenseResult.Dodged),
                cardId = result == SlashDefenseResult.Dodged && chosenDodgeUI != null && chosenDodgeUI.Data != null
                    ? chosenDodgeUI.Data.id : ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }

        onResolved?.Invoke(result);
    }

    private IEnumerator ResolveNullificationChain(CardModel rootScroll, GeneralCardUI caster, GeneralCardUI target, Action<bool> onResult)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        if (rootScroll == null || (rootScroll.category != CardCategory.InstantScroll && rootScroll.category != CardCategory.DelayedScroll))
        {
            onResult?.Invoke(false);
            yield break;
        }

        bool isCurrentlyCanceled = false;
        int startSeat = caster != null ? caster.SeatNumber : 1;

        long promptChainStartTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() - 1000;
        var nullifyActionsPerSeat = new Dictionary<int, AppwriteMatchmaking.BattleActionPacket>();
        Action<AppwriteMatchmaking.BattleActionPacket> onGlobalNullifyAction = (act) =>
        {
            if (act != null && act.actionType == "RESPONSE_NULLIFY" && act.casterSeat >= 1 && act.casterSeat <= 4 && act.timestamp >= promptChainStartTime)
            {
                nullifyActionsPerSeat[act.casterSeat] = act;
            }
        };
        AppwriteRealtimeClient.OnBattleActionReceived += onGlobalNullifyAction;

        while (!battleFinished)
        {
            bool someoneUsedInThisRound = false;
            GeneralCardUI whoUsedThisRound = null;

            // Xây dựng danh sách 4 ghế theo thứ tự ngược chiều kim đồng hồ bắt đầu từ startSeat
            // Ghế 1 -> Ghế 2 -> Ghế 3 -> Ghế 4 -> Ghế 1
            List<int> querySeats = new List<int>();
            for (int i = 0; i < 4; i++)
            {
                int s = ((startSeat - 1 + i) % 4) + 1;
                querySeats.Add(s);
            }

            foreach (int seatNum in querySeats)
            {
                if (battleFinished) break;
                var currentGen = GetGeneralBySeat(seatNum);
                if (currentGen == null || currentGen.CurrentHp <= 0) continue;

                // Mở Kho Cứu Tế doesn't target just one, but we process per target
                string targetDescText = "";
                if (target != null) {
                    if (rootScroll.subType == CardSubType.Harvest) targetDescText = $" việc chia bài cho #{target.SeatNumber} ({target.GeneralName})";
                    else targetDescText = $" lên #{target.SeatNumber} ({target.GeneralName})";
                }
                string casterDesc = (caster != null) ? $"{caster.GeneralName} dùng " : "Thực thi ";
                string questionText = !isCurrentlyCanceled
                    ? (rootScroll.subType == CardSubType.Harvest 
                        ? $"Có dùng Diệu Kế Phá Mưu để ngăn chặn {casterDesc}{GetFormattedCardName(rootScroll)}{targetDescText} không?" 
                        : $"Có dùng Diệu Kế Phá Mưu để ngăn chặn {casterDesc}{GetFormattedCardName(rootScroll)}{targetDescText} không?")
                    : $"Có dùng Diệu Kế Phá Mưu để phá giải Diệu Kế của đối phương\nnhằm vào {GetFormattedCardName(rootScroll)}{targetDescText} không?";
                currentGen.ShowHeadTimer(40);
                SetLog($"⏳ Đang hỏi <b>{currentGen.GeneralName}</b> (Ghế {currentGen.SeatNumber}): <i>\"{questionText}\"</i>");

                bool decisionMade = false;
                bool usedCard = false;
                CardModel usedCounterCard = null;

                // 1. NẾU LÀ NGƯỜI CHƠI TRÊN THIẾT BỊ NÀY
                if (currentGen == playerCard)
                {
                    var myCounterCards = playerHandCards.FindAll(c => c != null && (c.subType == CardSubType.FlawlessDefense || (!string.IsNullOrEmpty(c.cardName) && c.cardName.Contains("Diệu Kế"))));
                    if (myCounterCards.Count == 0)
                    {
                        // Người chơi KHÔNG CÓ Diệu Kế Phá Mưu -> BỎ QUA HOÀN TOÀN, KHÔNG HIỆN BẢNG HỎI!
                        if (!string.IsNullOrEmpty(currentRoomId))
                        {
                            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                            {
                                action = "RESPOND_ACTION",
                                roomId = currentRoomId,
                                seat = playerCard.SeatNumber,
                                accepted = false,
                                cardId = ""
                            }, (s) => { if (s != null) ApplyServerGameState(s); });
                        }
                        continue;
                    }

                    yield return PromptPlayerCounterScroll(rootScroll, questionText, myCounterCards, (didUse, chosenCard) =>
                    {
                        usedCard = didUse;
                        usedCounterCard = chosenCard;
                        decisionMade = true;
                    });

                    // LUÔN LUÔN BẮN GÓI TIN ĐỒNG BỘ DÙ LÀ DÙNG HAY TỪ CHỐI ĐỂ CÁC CLIENT KHÁC BIẾT VÀ CHUYỂN GHẾ!
                    if (!string.IsNullOrEmpty(currentRoomId))
                    {

                        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                        {
                            action = "RESPOND_ACTION",
                            roomId = currentRoomId,
                            seat = playerCard.SeatNumber,
                            accepted = usedCard,
                            cardId = usedCounterCard != null ? usedCounterCard.id : ""
                        }, (s) => { if (s != null) ApplyServerGameState(s); });
                    }
                }
                // 2. NẾU LÀ BOT AI ĐƯỢC ĐIỀU KHIỂN BỞI CLIENT NÀY
                else if (currentGen.IsAI && IsAIController())
                {
                    var aiHand = GetHandOfGeneral(currentGen);
                    var aiCounters = aiHand != null ? aiHand.FindAll(c => c != null && (c.subType == CardSubType.FlawlessDefense || (!string.IsNullOrEmpty(c.cardName) && c.cardName.Contains("Diệu Kế")))) : null;
                    if (aiCounters == null || aiCounters.Count == 0)
                    {
                        // AI không có Diệu Kế -> Bỏ qua luôn!
                        continue;
                    }
                    var aiCounter = aiCounters[0];

                    var waitingModalGo = ShowWaitingCounterScrollModal(currentGen, questionText);
                    var timerTxt = waitingModalGo != null ? waitingModalGo.transform.Find("Timer")?.GetComponent<UnityEngine.UI.Text>() : null;

                    float aiWaitTime = UnityEngine.Random.Range(2.0f, 3.5f);
                    float aiTimer = 40.0f;
                    float elapsed = 0f;

                    bool aiWantsToUse = false;
                    if (aiCounter != null)
                    {
                        if (!isCurrentlyCanceled)
                        {
                            if (currentGen.IsAlly != caster.IsAlly) aiWantsToUse = UnityEngine.Random.value < 0.80f;
                        }
                        else
                        {
                            if (currentGen.IsAlly == caster.IsAlly) aiWantsToUse = UnityEngine.Random.value < 0.85f;
                        }
                    }

                    while (elapsed < aiWaitTime && !battleFinished)
                    {
                        elapsed += Time.unscaledDeltaTime;
                        aiTimer -= Time.unscaledDeltaTime;
                        currentGen.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(aiTimer)));
                        if (timerTxt != null) timerTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(aiTimer))}s... (Đang chờ phản hồi)";
                        yield return null;
                    }

                    if (aiWantsToUse && aiCounter != null)
                    {
                        aiHand.Remove(aiCounter);
                        deckManager.DiscardCard(aiCounter);
                        UpdateHandCountsVisual();
                        ShowCardAtCenter(aiCounter, currentGen, null, "Hóa giải mưu kế!");
                        AudioManager.Instance.PlaySkill();
                        usedCard = true;
                        usedCounterCard = aiCounter;
                    }
                    decisionMade = true;

                    // HOST BẮN GÓI TIN QUYẾT ĐỊNH CỦA AI CHO TẤT CẢ CLIENT KHÁC
                    if (!string.IsNullOrEmpty(currentRoomId))
                    {

                        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                        {
                            action = "RESPOND_ACTION",
                            roomId = currentRoomId,
                            seat = currentGen.SeatNumber,
                            accepted = usedCard,
                            cardId = usedCounterCard != null ? usedCounterCard.id : ""
                        }, (s) => { if (s != null) ApplyServerGameState(s); });
                    }

                    if (waitingModalGo != null) Destroy(waitingModalGo);
                }
                // 3. NẾU LÀ NGƯỜI CHƠI ONLINE KHÁC (HOẶC AI DO HOST KHÁC ĐIỀU KHIỂN)
                else
                {
                    // Chỉ chấp nhận phản hồi mới trong phiên hỏi hiện tại
                    if (nullifyActionsPerSeat.TryGetValue(currentGen.SeatNumber, out var preAct) && preAct.timestamp >= promptChainStartTime)
                    {
                        usedCard = preAct.accepted;
                        if (preAct.accepted)
                        {
                            var rHand = GetHandOfGeneral(currentGen);
                            if (rHand != null && rHand.Count > 0) rHand.RemoveAt(0);
                            UpdateHandCountsVisual();
                            AudioManager.Instance.PlaySkill();
                        }
                        decisionMade = true;
                    }
                    else
                    {
                        var waitingModalGo = ShowWaitingCounterScrollModal(currentGen, questionText);
                        var timerTxt = waitingModalGo != null ? waitingModalGo.transform.Find("Timer")?.GetComponent<UnityEngine.UI.Text>() : null;

                        float startTime = Time.unscaledTime;
                        float nextPollTime = 0f;

                        while (!decisionMade && (Time.unscaledTime - startTime < 40.0f) && !battleFinished)
                        {
                            float elapsed = Time.unscaledTime - startTime;
                            float remaining = Mathf.Max(0f, 40.0f - elapsed);
                            currentGen.UpdateHeadTimer(Mathf.CeilToInt(remaining));
                            if (timerTxt != null) timerTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(remaining))}s... (Đang chờ phản hồi)";

                            if (nullifyActionsPerSeat.TryGetValue(currentGen.SeatNumber, out var liveAct) && liveAct.timestamp >= promptChainStartTime)
                            {
                                usedCard = liveAct.accepted;
                                if (liveAct.accepted)
                                {
                                    var rHand = GetHandOfGeneral(currentGen);
                                    if (rHand != null && rHand.Count > 0) rHand.RemoveAt(0);
                                    UpdateHandCountsVisual();
                                    AudioManager.Instance.PlaySkill();
                                }
                                decisionMade = true;
                                break;
                            }

                            // Quét HTTP định kỳ không đồng bộ ở background nếu mất kết nối Realtime
                            if (Time.unscaledTime >= nextPollTime && !string.IsNullOrEmpty(currentRoomId))
                            {
                                nextPollTime = Time.unscaledTime + 1.2f;
                                StartCoroutine(AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                                {
                                    foreach (var act in actions)
                                    {
                                        if (act.actionType == "RESPONSE_NULLIFY" && act.casterSeat == currentGen.SeatNumber && act.timestamp >= promptChainStartTime)
                                        {
                                            nullifyActionsPerSeat[act.casterSeat] = act;
                                            usedCard = act.accepted;
                                            if (act.accepted)
                                            {
                                                var rHand = GetHandOfGeneral(currentGen);
                                                if (rHand != null && rHand.Count > 0) rHand.RemoveAt(0);
                                                UpdateHandCountsVisual();
                                                AudioManager.Instance.PlaySkill();
                                            }
                                            decisionMade = true;
                                        }
                                    }
                                }));
                            }

                            yield return null;
                        }

                        if (waitingModalGo != null) Destroy(waitingModalGo);
                    }
                }

                currentGen.HideHeadTimer();

                // XỬ LÝ NẾU CÓ NGƯỜI DÙNG DIỆU KẾ
                if (usedCard)
                {
                    isCurrentlyCanceled = !isCurrentlyCanceled;
                    someoneUsedInThisRound = true;
                    whoUsedThisRound = currentGen;

                    SetLog($"🛡️ <b>{currentGen.GeneralName}</b> đã tung <color=#55FF55><b>[Diệu Kế Phá Mưu]</b></color>! Trạng thái mưu kế {GetFormattedCardName(rootScroll)}: {(isCurrentlyCanceled ? "<color=#FF5555>BỊ VÔ HIỆU HÓA</color>" : "<color=#55FF55>ĐƯỢC BẢO VỆ THÀNH CÔNG</color>")}.");

                    promptChainStartTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds(); // Làm mới timestamp cho vòng sau!
                    nullifyActionsPerSeat.Clear(); // Xóa bộ nhớ cache để chuẩn bị cho VÒNG HỎI MỚI!
                    yield return new WaitForSeconds(1.0f);
                    break; // Ngắt vòng lặp hiện tại để bắt đầu VÒNG HỎI MỚI!
                }
                else
                {
                    SetLog($"⏭️ <b>{currentGen.GeneralName}</b> không dùng Diệu Kế Phá Mưu.");
                }
            }

            // Nếu trong cả vòng hỏi 4 người, KHÔNG CÓ AI dùng Diệu Kế -> Kết thúc chuỗi!
            if (!someoneUsedInThisRound)
            {
                break;
            }
            else
            {
                // Bắt đầu vòng hỏi mới từ người bên phải của người vừa tung Diệu Kế
                if (whoUsedThisRound != null)
                {
                    startSeat = ((whoUsedThisRound.SeatNumber) % 4) + 1;
                }
            }
        }

        AppwriteRealtimeClient.OnBattleActionReceived -= onGlobalNullifyAction;

        // KHI KẾT THÚC TOÀN BỘ CHUỖI DIỆU KẾ:
        // Trả lại bộ đếm 40s đầy đủ cho người đang có lượt (Caster)
        if (caster != null)
        {
            turnTimer = 40.0f;
            caster.ShowHeadTimer(40);
            if (caster == playerCard)
            {
                SetLog($"🎯 <color=#FFD700><b>Lượt của bạn có 40s trở lại</b></color> để tiếp tục điều khiển bàn đấu!");
            }
            else
            {
                SetLog($"🎯 <color=#55FF55><b>Lượt của {caster.GeneralName} có 40s trở lại</b></color>.");
            }
        }

        if (isCurrentlyCanceled)
        {
            SetLog($"🚫 Lá {GetFormattedCardName(rootScroll)} đã bị [Diệu Kế Phá Mưu] vô hiệu hóa hoàn toàn! Không có tác dụng.");
        }
        else
        {
            SetLog($"✨ Lá {GetFormattedCardName(rootScroll)} không bị ngăn chặn, bắt đầu thực thi hiệu ứng!");
        }

        onResult?.Invoke(isCurrentlyCanceled);
    }

    private IEnumerator PromptPlayerNamSonFollowUp(GeneralCardUI caster, GeneralCardUI target, Action<bool, CardModel> onResolved)
    {
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        var slashCard = playerHandCards.Find(c => IsSlashCard(c));
        if (slashCard == null || battleFinished)
        {
            onResolved?.Invoke(false, null);
            yield break;
        }

        bool decided = false;
        bool wantsFollowUp = false;
        CardModel chosenSlash = slashCard;
        float promptTimer = 40.0f;

        caster.ShowHeadTimer(40);

        var panelGo = new GameObject("NamSonPromptModal", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        panelGo.transform.SetAsLastSibling();

        var pImg = panelGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSpr != null) { pImg.sprite = bgSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.1f, 0.08f, 0.04f, 0.96f);

        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = new Vector2(0.5f, 0.5f);
        pRt.anchorMax = new Vector2(0.5f, 0.5f);
        pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = new Vector2(460f, 210f);
        pRt.anchoredPosition = new Vector2(0f, 30f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(panelGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { bImg.sprite = slotSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(1f, 0.85f, 0.25f, 0.8f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4f, -4f), new Vector2(4f, 4f));

        var titleTxt = AddText(panelGo.transform, "Title", "🗡️ TRƯỜNG ĐAO NAM SƠN (TRUY KÍCH)", 14, new Color(1f, 0.85f, 0.25f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(440f, 32f), new Vector2(0f, -8f));

        var msgTxt = AddText(panelGo.transform, "Msg", $"Đối phương <b>{target.GeneralName}</b> vừa dùng [ĐỠ] hóa giải!\nBạn có muốn dùng thêm 1 lá [TRẢM] ({chosenSlash.cardName}) để tiếp tục chém ép đối phương phải Đỡ tiếp không?", 12, Color.white, FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(msgTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(430f, 60f), new Vector2(0f, 15f));

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/button_brown_bg");

        var useBtnGo = new GameObject("UseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        useBtnGo.transform.SetParent(panelGo.transform, false);
        var uImg = useBtnGo.GetComponent<Image>();
        if (btnSpr != null) { uImg.sprite = btnSpr; uImg.type = Image.Type.Sliced; }
        uImg.color = new Color(0.15f, 0.7f, 0.25f, 1f);
        var uRt = useBtnGo.GetComponent<RectTransform>();
        SetRect(uRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(200f, 38f), new Vector2(-105f, 16f));
        var uTxt = AddText(useBtnGo.transform, "Txt", $"🗡️ DÙNG {GetFormattedCardName(chosenSlash)}", 11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(uTxt.rectTransform);

        var passBtnGo = new GameObject("PassBtn", typeof(RectTransform), typeof(Image), typeof(Button));
        passBtnGo.transform.SetParent(panelGo.transform, false);
        var passImg = passBtnGo.GetComponent<Image>();
        if (btnSpr != null) { passImg.sprite = btnSpr; passImg.type = Image.Type.Sliced; }
        passImg.color = new Color(0.6f, 0.2f, 0.2f, 1f);
        var passRt = passBtnGo.GetComponent<RectTransform>();
        SetRect(passRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(180f, 38f), new Vector2(110f, 16f));
        var passTxt = AddText(passBtnGo.transform, "Txt", "❌ TỪ CHỐI (BỎ QUA)", 11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(passTxt.rectTransform);

        Action<CardUI> onCardSelectedSlash = (cardUI) =>
        {
            if (cardUI != null && cardUI.Data != null && IsSlashCard(cardUI.Data))
            {
                chosenSlash = cardUI.Data;
                uTxt.text = $"🗡️ DÙNG {GetFormattedCardName(chosenSlash)}";
                msgTxt.text = $"Đối phương <b>{target.GeneralName}</b> vừa dùng [ĐỠ] hóa giải!\nBạn có muốn dùng thêm 1 lá [TRẢM] ({chosenSlash.cardName}) để tiếp tục chém ép đối phương phải Đỡ tiếp không?";
            }
        };
        playerHandUI.OnCardSelected += onCardSelectedSlash;

        playerHandUI.HighlightOnlyMatching(c => IsSlashCard(c));

        useBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            decided = true;
            wantsFollowUp = true;
        });

        passBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            decided = true;
            wantsFollowUp = false;
        });

        while (!decided && !battleFinished && (!serverControlled || IsAuthoritativePromptActive("AWAIT_NAM_SON_FOLLOW_UP")))
        {
            if (!serverControlled)
            {
                
            promptTimer -= Time.unscaledDeltaTime;
            caster.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(promptTimer)));
                if (promptTimer <= 0f)
                {
                    SetLog("⏰ <b>Đã hết 40s!</b> Tự động bỏ qua không dùng thêm Trảm.");
                    decided = true;
                    wantsFollowUp = false;
                    break;
                }
            }
            yield return null;
        }

        caster.HideHeadTimer();
        playerHandUI.OnCardSelected -= onCardSelectedSlash;
        playerHandUI.ClearHighlights();
        if (panelGo != null) Destroy(panelGo);

        if (serverControlled && decided && IsAuthoritativePromptActive("AWAIT_NAM_SON_FOLLOW_UP"))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "RESPOND_ACTION",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                accepted = wantsFollowUp,
                cardId = wantsFollowUp && chosenSlash != null ? chosenSlash.id : ""
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }

        onResolved?.Invoke(wantsFollowUp, wantsFollowUp ? chosenSlash : null);
    }

    private IEnumerator AwaitRemoteNamSonFollowUp(GeneralCardUI caster, GeneralCardUI target, Action<bool, CardModel> onResolved)
    {
        bool remoteDecided = false;
        bool wantsFollowUp = false;
        CardModel followUpCard = null;
        float waitTimer = 40.0f;

        caster.ShowHeadTimer(40);
        SetLog($"⏳ Đang đợi <b>{caster.GeneralName}</b> chọn có dùng thêm [Trảm] từ [Trường Đao Nam Sơn] để truy kích không... (40s)");

        while (waitTimer > 0f && !remoteDecided && !battleFinished)
        {
            waitTimer -= Time.unscaledDeltaTime;
            caster.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

            yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
            {
                foreach (var act in actions)
                {
                    if (act.casterSeat == caster.SeatNumber && act.actionType == "NAM_SON_FOLLOW_UP" && !processedActionTimestamps.Contains(act.timestamp))
                    {
                        processedActionTimestamps.Add(act.timestamp);
                        remoteDecided = true;
                        wantsFollowUp = act.accepted;
                        if (wantsFollowUp)
                        {
                            followUpCard = CardDatabase.GetCardById(act.cardId) ?? CardDatabase.CreateCard(act.cardId, act.cardName, CardSuit.Spade, CardRank.Eight, 1, CardCategory.Basic, CardSubType.AttackNormal, "Trảm Thường", "UI/icon_slash", 1);
                        }
                    }
                }
            });

            if (remoteDecided) break;
            yield return null;
        }

        caster.HideHeadTimer();
        if (!remoteDecided)
        {
            SetLog($"⏰ <b>{caster.GeneralName}</b> hết 40s, tự động không dùng thêm Trảm.");
        }

        onResolved?.Invoke(wantsFollowUp, followUpCard);
    }

    private IEnumerator PromptPlayerCounterScroll(CardModel scrollCard, string promptTitle, List<CardModel> counterCards, Action<bool, CardModel> onResolved)
    {
        if (counterCards == null || counterCards.Count == 0)
        {
            onResolved?.Invoke(false, null);
            yield break;
        }

        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        bool decided = false;
        bool used = false;
        float promptTimer = 40.0f;
        CardModel selectedCounterCard = counterCards[0];

        playerCard.ShowHeadTimer(40);

        var panelGo = new GameObject("CounterPromptModal", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        panelGo.transform.SetAsLastSibling();

        var pImg = panelGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSpr != null) { pImg.sprite = bgSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);

        float panelH = (counterCards.Count > 1) ? 260f : 210f;
        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = new Vector2(780f, panelH);
        pRt.anchoredPosition = new Vector2(0f, 65f);

        var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        fGo.transform.SetParent(panelGo.transform, false);
        var fImg = fGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = ThemeUI.GoldPrimary;
        fImg.raycastTarget = false;
        Fill(fGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        // 1. Dòng Tiêu đề (y = -12f)
        var titleTxt = AddText(panelGo.transform, "Title", "🛡️ ĐẾN LƯỢT BẠN PHẢN HỒI DIỆU KẾ", 19, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(titleTxt.rectTransform, new Vector2(0f, 1f), new Vector2(0.7f, 1f), new Vector2(0f, 1f), new Vector2(0, 28f), new Vector2(24f, -12f));

        // 2. Timer đếm ngược góc phải đỉnh (y = -12f)
        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Còn 40s...", 16, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleRight);
        SetRect(timerTxt.rectTransform, new Vector2(0.7f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(0, 28f), new Vector2(-24f, -12f));

        // 3. Câu hỏi cẩm nang ở giữa (y = -44f, không bị đè bởi bất cứ thành phần nào)
        var qTxt = AddText(panelGo.transform, "Question", promptTitle, 16, new Color(0.92f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        qTxt.lineSpacing = 1.25f;
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        qTxt.verticalOverflow = VerticalWrapMode.Truncate;
        SetRect(qTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(-48f, 54f), new Vector2(0f, -44f));

        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");

        var useBtnGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
        useBtnGo.transform.SetParent(panelGo.transform, false);
        var uImg = useBtnGo.GetComponent<Image>();
        if (btnSpr != null) { uImg.sprite = btnSpr; uImg.type = Image.Type.Sliced; }
        uImg.color = ThemeUI.JadeGreen;
        var uRt = useBtnGo.GetComponent<RectTransform>();
        SetRect(uRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(340f, 46f), new Vector2(-125f, 18f));

        var uBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
        uBorder.transform.SetParent(useBtnGo.transform, false);
        var ubImg = uBorder.GetComponent<Image>();
        if (fSpr != null) { ubImg.sprite = fSpr; ubImg.type = Image.Type.Sliced; }
        ubImg.color = ThemeUI.GoldHighlight;
        Fill(uBorder.GetComponent<RectTransform>(), new Vector2(-1.5f, -1.5f), new Vector2(1.5f, 1.5f));

        var uTxt = AddText(useBtnGo.transform, "Txt", $"🛡️ DÙNG {GetFormattedCardName(selectedCounterCard)}", 16, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(uTxt.rectTransform);

        var passBtnGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
        passBtnGo.transform.SetParent(panelGo.transform, false);
        var paImg = passBtnGo.GetComponent<Image>();
        if (btnSpr != null) { paImg.sprite = btnSpr; paImg.type = Image.Type.Sliced; }
        paImg.color = new Color(0.40f, 0.44f, 0.52f, 1f);
        var paRt = passBtnGo.GetComponent<RectTransform>();
        SetRect(paRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(210f, 46f), new Vector2(165f, 18f));

        var paTxt = AddText(passBtnGo.transform, "Txt", "❌ BỎ QUA / KHÔNG DÙNG", 16, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(paTxt.rectTransform);

        // 4. Nếu có từ 2 lá Diệu Kế trở lên -> Hiện dải chọn thẻ bài ở giữa
        if (counterCards.Count > 1)
        {
            var cardsRowGo = new GameObject("CardsRow", typeof(RectTransform), typeof(HorizontalLayoutGroup));
            cardsRowGo.transform.SetParent(panelGo.transform, false);
            var crRt = cardsRowGo.GetComponent<RectTransform>();
            SetRect(crRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(720f, 48f), new Vector2(0f, 72f));
            var hlg = cardsRowGo.GetComponent<HorizontalLayoutGroup>();
            hlg.spacing = 12f;
            hlg.childAlignment = TextAnchor.MiddleCenter;
            hlg.childControlWidth = false;
            hlg.childControlHeight = false;

            var cardBorders = new List<Image>();
            var cardImgs = new List<Image>();

            void UpdateSelectionVisuals(CardModel chosen)
            {
                selectedCounterCard = chosen;
                uTxt.text = $"🛡️ DÙNG {GetFormattedCardName(selectedCounterCard)}";
                for (int i = 0; i < counterCards.Count; i++)
                {
                    bool isSel = counterCards[i].id == selectedCounterCard.id;
                    if (i < cardBorders.Count && cardBorders[i] != null)
                    {
                        cardBorders[i].color = isSel ? ThemeUI.GoldHighlight : new Color(0.4f, 0.5f, 0.65f, 0.5f);
                    }
                    if (i < cardImgs.Count && cardImgs[i] != null)
                    {
                        cardImgs[i].color = isSel ? new Color(0.12f, 0.32f, 0.22f, 0.98f) : new Color(0.06f, 0.10f, 0.18f, 0.90f);
                    }
                }
            }

            for (int i = 0; i < counterCards.Count; i++)
            {
                var c = counterCards[i];
                var cBtnGo = new GameObject("CardBtn_" + i, typeof(RectTransform), typeof(Image), typeof(Button));
                cBtnGo.transform.SetParent(cardsRowGo.transform, false);
                var cbRt = cBtnGo.GetComponent<RectTransform>();
                cbRt.sizeDelta = new Vector2(210f, 44f);

                var cbImg = cBtnGo.GetComponent<Image>();
                if (slotSpr != null) { cbImg.sprite = slotSpr; cbImg.type = Image.Type.Sliced; }
                cardImgs.Add(cbImg);

                var cbBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
                cbBorder.transform.SetParent(cBtnGo.transform, false);
                var cbbImg = cbBorder.GetComponent<Image>();
                if (fSpr != null) { cbbImg.sprite = fSpr; cbbImg.type = Image.Type.Sliced; }
                Fill(cbBorder.GetComponent<RectTransform>(), new Vector2(-1.5f, -1.5f), new Vector2(1.5f, 1.5f));
                cardBorders.Add(cbbImg);

                string suitColor = (c.suit == CardSuit.Heart || c.suit == CardSuit.Diamond) ? "#FF5555" : "#FFFFFF";
                var cbTxt = AddText(cBtnGo.transform, "Txt", $"<color={suitColor}><b>{c.GetSuitSymbol()}{c.GetRankString()}</b></color>  {c.cardName}", 15, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
                Fill(cbTxt.rectTransform);

                var bComponent = cBtnGo.GetComponent<Button>();
                bComponent.onClick.AddListener(() =>
                {
                    AudioManager.Instance.PlayCardSelect();
                    UpdateSelectionVisuals(c);
                });
            }

            UpdateSelectionVisuals(selectedCounterCard);
        }

        useBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            if (!serverControlled)
            {
                playerHandCards.Remove(selectedCounterCard);
                playerHandUI.ClearHand();
                playerHandUI.AddCards(playerHandCards);
                deckManager.DiscardCard(selectedCounterCard);
                UpdateHandCountsVisual();
            }

            ShowCardAtCenter(selectedCounterCard, playerCard, null, "Hóa giải mưu kế!");
            AudioManager.Instance.PlaySkill();
            SetLog($"🛡️ <color=#55FF55><b>[DIỆU KẾ PHÁ MƯU]</b></color>: Bạn đã tung {GetFormattedCardName(selectedCounterCard)} để hóa giải!");
            used = true;
            decided = true;
        });

        passBtnGo.GetComponent<Button>().onClick.AddListener(() =>
        {
            used = false;
            decided = true;
        });

        Action<CardUI> onHandCardSelected = (cUI) =>
        {
            if (cUI != null && cUI.Data != null)
            {
                var matched = counterCards.Find(c => c.id == cUI.Data.id);
                if (matched != null)
                {
                    AudioManager.Instance.PlayCardSelect();
                    selectedCounterCard = matched;
                    uTxt.text = $"🛡️ DÙNG {GetFormattedCardName(selectedCounterCard)}";
                }
            }
        };
        if (playerHandUI != null) playerHandUI.OnCardSelected += onHandCardSelected;

        while (!decided && !battleFinished && (!serverControlled || IsAuthoritativePromptActive("AWAIT_NULLIFY")))
        {
            promptTimer -= Time.unscaledDeltaTime;
            playerCard.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(promptTimer)));
            if (timerTxt != null) timerTxt.text = $"⏳ Còn {Mathf.Max(0, Mathf.CeilToInt(promptTimer))}s...";

            if (!serverControlled && promptTimer <= 0f)
            {
                decided = true;
            }
            yield return null;
        }

        if (playerHandUI != null) playerHandUI.OnCardSelected -= onHandCardSelected;
        playerCard.HideHeadTimer();
        if (panelGo != null) Destroy(panelGo);
        if (!serverControlled || decided)
        {
            onResolved?.Invoke(used, selectedCounterCard);
        }
    }

        private IEnumerator UpdateCounterWaitingModalTimer(GameObject modalGo, GeneralCardUI targetGen)
    {
        var timerTxt = modalGo != null ? modalGo.transform.Find("Timer")?.GetComponent<UnityEngine.UI.Text>() : null;
        float promptTimer = 40.0f;
        while (modalGo != null && !battleFinished)
        {
            promptTimer = turnTimer;
            /* hidden for nullify */
            if (timerTxt != null) timerTxt.text = $"⏳ Đang chờ phản hồi ({Mathf.Max(0, Mathf.CeilToInt(promptTimer))}s)...";
            yield return null;
        }
    }

    private GameObject ShowWaitingCounterScrollModal(GeneralCardUI targetGen, string questionText)
    {
        var existing = GameObject.Find("CounterWaitingModal");
        if (existing != null) Destroy(existing);

        var panelGo = new GameObject("CounterWaitingModal", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        panelGo.transform.SetAsLastSibling();

        var pImg = panelGo.GetComponent<Image>();
        var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSpr != null) { pImg.sprite = bgSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.04f, 0.07f, 0.14f, 0.98f);

        var pRt = panelGo.GetComponent<RectTransform>();
        pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
        pRt.sizeDelta = new Vector2(740f, 160f);
        pRt.anchoredPosition = new Vector2(0f, 65f);

        var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        fGo.transform.SetParent(panelGo.transform, false);
        var fImg = fGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
        fImg.color = ThemeUI.AllyBorder;
        fImg.raycastTarget = false;
        Fill(fGo.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

        string targetName = targetGen != null ? targetGen.GeneralName : "ĐỐI THỦ";
        var titleTxt = AddText(panelGo.transform, "Title", $"🛡️ ĐANG HỎI {targetName.ToUpper()}...", 18, ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleLeft);
        SetRect(titleTxt.rectTransform, new Vector2(0f, 1f), new Vector2(0.7f, 1f), new Vector2(0f, 1f), new Vector2(0, 28f), new Vector2(24f, -12f));

        var timerTxt = AddText(panelGo.transform, "Timer", "⏳ Đang chờ (40s)...", 16, ThemeUI.CyanPrimary, FontStyle.Bold, TextAnchor.MiddleRight);
        SetRect(timerTxt.rectTransform, new Vector2(0.7f, 1f), new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(0, 28f), new Vector2(-24f, -12f));

        var qTxt = AddText(panelGo.transform, "Question", questionText, 15, new Color(0.85f, 0.9f, 0.98f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        qTxt.lineSpacing = 1.25f;
        qTxt.horizontalOverflow = HorizontalWrapMode.Wrap;
        qTxt.verticalOverflow = VerticalWrapMode.Truncate;
        SetRect(qTxt.rectTransform, new Vector2(0f, 1f), new Vector2(1f, 1f), new Vector2(0.5f, 1f), new Vector2(-48f, 60f), new Vector2(0f, -44f));

        var waitBadge = AddText(panelGo.transform, "Badge", "<i>Đối phương đang suy nghĩ có nên thi triển Diệu Kế Phá Mưu hay không...</i>", 13, new Color(0.6f, 0.7f, 0.85f, 0.8f), FontStyle.Italic, TextAnchor.MiddleCenter);
        SetRect(waitBadge.rectTransform, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0.5f, 0f), new Vector2(0, 28f), new Vector2(0f, 10f));

        return panelGo;
    }

    private IEnumerator ResolveInstantScroll(CardModel card, GeneralCardUI caster, GeneralCardUI target)
    {
        if (DenoGameClient.IsConnected) yield break;
        bool isCanceled = false;
        yield return ResolveNullificationChain(card, caster, target, res => isCanceled = res);
        if (isCanceled)
        {
            SetLog($"🛡️ <color=#55FF55><b>[DIỆU KẾ PHÁ MƯU]</b></color> đã hóa giải mưu kế {GetFormattedCardName(card)}!");
            yield break;
        }

        switch (card.subType)
        {
            case CardSubType.ExNihilo:
                ShowCardAtCenter(card, caster, null, "Rút 2 lá bài vào tay");
                var d1 = deckManager.DrawCard();
                var d2 = deckManager.DrawCard();
                AddCardsToGeneral(caster, d1, d2);
                UpdateHandCountsVisual();
                AudioManager.Instance.PlayCardDraw();
                SetLog($"📜 <b>{caster.GeneralName}</b> thi triển [Dụng Binh Như Thần] rút thêm 2 lá bài vào tay!");
                break;

            case CardSubType.Snatch:
                if (target != null)
                {
                    ShowCardAtCenter(card, caster, target, "Cướp 1 lá bài");
                    if (caster == playerCard)
                    {
                        bool chosen = false;
                        ShowCardStealOrDestroyModal(target, true, "🌾 ĐỘT KÍCH TRỘM LƯƠNG: CHỌN 1 LÁ ĐỂ CƯỚP", (stolen) =>
                        {
                            playerHandCards.Add(stolen);
                            playerHandUI.AddCard(stolen);
                            UpdateHandCountsVisual();
                            AudioManager.Instance.PlayCardDraw();
                            SetLog($"🌾 [Đột Kích Trộm Lương]: Bạn đã cướp thành công lá {GetFormattedCardName(stolen)} từ {target.GeneralName}!");
                            chosen = true;
                        });
                        while (!chosen && !battleFinished) yield return null;
                    }
                    else
                    {
                        var options = BuildTargetCardOptions(target, true);
                        if (options.Count > 0)
                        {
                            var opt = options[UnityEngine.Random.Range(0, options.Count)];
                            if (TryRemoveTargetCardOption(target, opt))
                            {
                                AddCardsToGeneral(caster, opt.Card);
                                UpdateHandCountsVisual();
                                AudioManager.Instance.PlayCardDraw();
                                SetLog($"🌾 <b>{caster.GeneralName}</b> dùng [Đột Kích Trộm Lương] cướp 1 lá bài từ <b>{target.GeneralName}</b>!");
                            }
                        }
                    }
                }
                break;

            case CardSubType.Dismantle:
                if (target != null)
                {
                    ShowCardAtCenter(card, caster, target, "Phá hủy 1 lá bài");
                    if (caster == playerCard)
                    {
                        bool chosen = false;
                        ShowCardStealOrDestroyModal(target, false, "🏚️ VƯỜN KHÔNG NHÀ TRỐNG: CHỌN 1 LÁ ĐỂ PHÁ HỦY", (discarded) =>
                        {
                            deckManager.DiscardCard(discarded);
                            ShowCardAtCenter(discarded, target, null, "Lá bài bị phá hủy");
                            AudioManager.Instance.PlayCardDiscard();
                            SetLog($"🏚️ [Vườn Không Nhà Trống]: Bạn đã phá hủy lá {GetFormattedCardName(discarded)} của {target.GeneralName}!");
                            chosen = true;
                        });
                        while (!chosen && !battleFinished) yield return null;
                    }
                    else
                    {
                        var options = BuildTargetCardOptions(target, false);
                        if (options.Count > 0)
                        {
                            var opt = options[UnityEngine.Random.Range(0, options.Count)];
                            if (TryRemoveTargetCardOption(target, opt))
                            {
                                deckManager.DiscardCard(opt.Card);
                                UpdateHandCountsVisual();
                                AudioManager.Instance.PlayCardDiscard();
                                SetLog($"🏚️ <b>{caster.GeneralName}</b> dùng [Vườn Không Nhà Trống] phá hủy 1 lá bài của <b>{target.GeneralName}</b>!");
                            }
                        }
                    }
                }
                break;

            case CardSubType.Duel:
                if (target != null)
                {
                    yield return ResolveDuel(caster, target);
                }
                break;

            case CardSubType.FlawlessDefense:
                if (target != null)
                {
                    ShowCardAtCenter(card, caster, target, "Diệu Kế Phá Mưu: Hủy 1 lá của đối phương");
                    if (caster == playerCard)
                    {
                        bool chosen = false;
                        ShowCardStealOrDestroyModal(target, false, "🛡️ DIỆU KẾ PHÁ MƯU: CHỌN 1 LÁ ĐỂ HỦY BỎ", (discarded) =>
                        {
                            deckManager.DiscardCard(discarded);
                            ShowCardAtCenter(discarded, target, null, "Lá bài bị hủy");
                            AudioManager.Instance.PlaySkill();
                            SetLog($"🛡️ [Diệu Kế Phá Mưu]: Bạn đã thi triển Diệu Kế Phá Mưu, hủy lá {GetFormattedCardName(discarded)} của {target.GeneralName}!");
                            chosen = true;
                        });
                        while (!chosen && !battleFinished) yield return null;
                    }
                    else
                    {
                        var options = BuildTargetCardOptions(target, true);
                        if (options.Count > 0)
                        {
                            var opt = options[UnityEngine.Random.Range(0, options.Count)];
                            if (TryRemoveTargetCardOption(target, opt))
                            {
                                deckManager.DiscardCard(opt.Card);
                                UpdateHandCountsVisual();
                                AudioManager.Instance.PlaySkill();
                                SetLog($"🛡️ <b>{caster.GeneralName}</b> dùng [Diệu Kế Phá Mưu] hủy lá [{opt.Card.cardName}] của <b>{target.GeneralName}</b>!");
                            }
                        }
                    }
                }
                break;

            case CardSubType.BarbarianInvasion:
                ShowCardAtCenter(card, caster, null, "Bãi Cọc Ngầm: Toàn sân cần Trảm");
                SetLog($"🏹 <b>{caster.GeneralName}</b> phát động [BÃI CỌC NGẦM]! Toàn bộ người chơi khác phải đánh 1 lá Trảm hoặc mất 1 Máu!");
                {
                    var aoeOrder = GetLivingGeneralsStartingRightOf(caster);
                    foreach (var g in aoeOrder)
                    {
                        if (g != caster && g.CurrentHp > 0 && !battleFinished)
                        {
                            yield return ResolveAoERequirement(g, true, "Bãi Cọc Ngầm", "Trảm");
                        }
                    }
                }
                break;

            case CardSubType.ArrowRain:
                ShowCardAtCenter(card, caster, null, "Mưa Tên Liên Châu: Toàn sân cần Đỡ");
                SetLog($"🏹 <b>{caster.GeneralName}</b> thi triển [MƯA TÊN LIÊN CHÂU]! Toàn bộ người chơi khác phải đánh 1 lá Đỡ hoặc mất 1 Máu!");
                {
                    var aoeOrder = GetLivingGeneralsStartingRightOf(caster);
                    foreach (var g in aoeOrder)
                    {
                        if (g != caster && g.CurrentHp > 0 && !battleFinished)
                        {
                            yield return ResolveAoERequirement(g, false, "Mưa Tên Liên Châu", "Đỡ");
                        }
                    }
                }
                break;

            case CardSubType.IronChain:
                ShowCardAtCenter(card, caster, null, "Xích Tâm Tỏa: Nối / Gỡ Xích Liên Hoàn");
                if (caster == playerCard)
                {
                    bool done = false;
                    ShowIronChainSelectionModal(caster, (chosenGenerals) =>
                    {
                        if (chosenGenerals != null && chosenGenerals.Count > 0)
                        {
                            foreach (var g in chosenGenerals)
                            {
                                g.SetChained(!g.IsChained);
                                if (g.IsChained)
                                    SetLog($"⛓️ <color=#FFD700><b>[XÍCH TÂM TỎA]</b></color>: Trói <b>{g.GeneralName}</b> vào Xích Liên Hoàn!");
                                else
                                    SetLog($"⛓️ <color=#FFD700><b>[XÍCH TÂM TỎA]</b></color>: Đã gỡ xích cho <b>{g.GeneralName}</b>!");
                            }
                            AudioManager.Instance.PlaySkill();
                        }
                        else
                        {
                            SetLog($"⛓️ [Xích Tâm Tỏa]: Không chọn mục tiêu nào để thay đổi xích.");
                        }
                        done = true;
                    });
                    while (!done && !battleFinished) yield return null;
                }
                else
                {
                    var candidateTargets = new List<GeneralCardUI>();
                    foreach (var g in allGenerals)
                    {
                        if (g != null && g.CurrentHp > 0)
                        {
                            bool isEnemy = !IsSameTeamSeat(caster.SeatNumber, g.SeatNumber);
                            if (isEnemy && !g.IsChained) candidateTargets.Add(g);
                            else if (!isEnemy && g.IsChained) candidateTargets.Add(g);
                        }
                    }
                    if (candidateTargets.Count == 0)
                    {
                        foreach (var g in allGenerals)
                        {
                            if (g != null && g.CurrentHp > 0 && !IsSameTeamSeat(caster.SeatNumber, g.SeatNumber))
                                candidateTargets.Add(g);
                        }
                    }

                    int countToChain = Mathf.Min(2, candidateTargets.Count);
                    for (int i = 0; i < countToChain; i++)
                    {
                        var g = candidateTargets[i];
                        g.SetChained(!g.IsChained);
                        if (g.IsChained)
                            SetLog($"⛓️ <color=#FFD700><b>[XÍCH TÂM TỎA]</b></color>: <b>{caster.GeneralName}</b> trói <b>{g.GeneralName}</b> vào Xích Liên Hoàn!");
                        else
                            SetLog($"⛓️ <color=#FFD700><b>[XÍCH TÂM TỎA]</b></color>: <b>{caster.GeneralName}</b> gỡ xích cho <b>{g.GeneralName}</b>!");
                    }
                    AudioManager.Instance.PlaySkill();
                }
                break;

            case CardSubType.Harvest:
                yield return ResolveHarvest(card, caster);
                break;
        }
    }

    /// <summary>
    /// Mở Kho Cứu Tế: Hiển thị Modal lật N lá bài tương ứng số người còn sống, luân phiên từng người tự tay chọn 1 lá.
    /// </summary>
    private IEnumerator ResolveHarvest(CardModel harvestCard, GeneralCardUI caster)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        ShowCardAtCenter(harvestCard, caster, null, "Mở Kho Cứu Tế: Chia đều bài công khai");
        SetLog("🌾 [Mở Kho Cứu Tế]: Đang mở kho lương, lật bài công khai cho cả bàn đấu cùng chọn!");

        var livingTurnOrder = new List<GeneralCardUI>();
        int startIdx = turnOrderGenerals.IndexOf(caster);
        for (int i = 0; i < turnOrderGenerals.Count; i++)
        {
            int gIdx = (startIdx + i) % turnOrderGenerals.Count;
            if (turnOrderGenerals[gIdx].CurrentHp > 0)
            {
                livingTurnOrder.Add(turnOrderGenerals[gIdx]);
            }
        }

        int totalCount = livingTurnOrder.Count;
        var revealedCards = new List<CardModel>();
        for (int i = 0; i < totalCount; i++)
        {
            var c = deckManager.DrawCard();
            if (c != null) revealedCards.Add(c);
        }

        yield return new WaitForSeconds(0.6f);

        var modalGo = new GameObject("HarvestModal", typeof(RectTransform), typeof(Image));
        modalGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modalGo.transform.SetAsLastSibling();

        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(modalGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(740f, 400f);
        panelRt.anchoredPosition = Vector2.zero;

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.06f, 0.14f, 0.12f, 0.98f);

        var borderGo = new GameObject("Border", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(panelGo.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (fSpr != null) { bImg.sprite = fSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.35f, 0.9f, 0.45f, 0.98f);
        Fill(borderGo.GetComponent<RectTransform>(), new Vector2(-4, -4), new Vector2(4, 4));

        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSpr != null) { hImg.sprite = badgeSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = new Color(0.15f, 0.58f, 0.32f, 0.98f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(680f, 48f), new Vector2(0, -12f));

        var titleTxt = AddText(headerGo.transform, "Title", $"🍚 MỞ KHO CỨU TẾ - LẬT {revealedCards.Count} LÁ BÀI CÔNG KHAI", 16, new Color(1f, 0.95f, 0.6f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(titleTxt.rectTransform);

        var subTxt = AddText(panelGo.transform, "SubTitle", "Đang chia bài...", 13, new Color(0.9f, 1f, 0.92f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(680f, 26f), new Vector2(0, -66f));

        var cardsContainerGo = new GameObject("CardsContainer", typeof(RectTransform), typeof(HorizontalLayoutGroup));
        cardsContainerGo.transform.SetParent(panelGo.transform, false);
        var cRt = cardsContainerGo.GetComponent<RectTransform>();
        SetRect(cRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(700f, 220f), new Vector2(0, -22f));
        var hlg = cardsContainerGo.GetComponent<HorizontalLayoutGroup>();
        hlg.spacing = 16f;
        hlg.childAlignment = TextAnchor.MiddleCenter;
        hlg.childControlWidth = hlg.childControlHeight = false;

        var cardUiMap = new Dictionary<CardModel, GameObject>();
        foreach (var cData in revealedCards)
        {
            var cardUI = CardUI.Create(cardsContainerGo.transform, cData, new Vector2(118f, 162f));
            cardUiMap[cData] = cardUI.gameObject;
        }

        foreach (var picker in livingTurnOrder)
        {
            if (battleFinished || cardUiMap.Count == 0) break;

            if (picker == playerCard)
            {
                subTxt.text = $"👉 <color=#FFD700><b>LƯỢT CỦA BẠN:</b></color> Chạm chọn 1 lá bài công khai dưới đây vào tay!";
                SetLog("👉 [Mở Kho Cứu Tế]: Đang tới lượt bạn chọn 1 lá bài...");

                CardModel playerPicked = null;

                foreach (var kvp in cardUiMap)
                {
                    var cData = kvp.Key;
                    var cGo = kvp.Value;
                    if (cGo == null) continue;

                    var overlayBtn = new GameObject("ClickOverlay", typeof(RectTransform), typeof(Image), typeof(Button));
                    overlayBtn.transform.SetParent(cGo.transform, false);
                    overlayBtn.transform.SetAsLastSibling();
                    var oImg = overlayBtn.GetComponent<Image>();
                    oImg.color = new Color(1f, 1f, 1f, 0.001f);
                    Fill(overlayBtn.GetComponent<RectTransform>());

                    overlayBtn.GetComponent<Button>().onClick.AddListener(() =>
                    {
                        playerPicked = cData;
                    });
                }

                while (playerPicked == null && !battleFinished)
                {
                    yield return null;
                }

                if (playerPicked != null)
                {
                    playerHandCards.Add(playerPicked);
                    playerHandUI.AddCard(playerPicked);
                    UpdateHandCountsVisual();

                    if (cardUiMap.TryGetValue(playerPicked, out var pickedGo) && pickedGo != null)
                    {
                        Destroy(pickedGo);
                    }
                    cardUiMap.Remove(playerPicked);

                    AudioManager.Instance.PlayCardDraw();
                    SetLog($"🍚 Bạn đã chọn lá {GetFormattedCardName(playerPicked)} từ Kho Cứu Tế!");
                    yield return new WaitForSeconds(0.6f);
                }
            }
            else
            {
                subTxt.text = $"⏳ <color=#55DDFF><b>[{picker.GeneralName}]</b></color> đang chọn 1 lá bài...";
                yield return new WaitForSeconds(1.2f);

                var remaining = new List<CardModel>(cardUiMap.Keys);
                if (remaining.Count > 0)
                {
                    var aiPick = remaining[UnityEngine.Random.Range(0, remaining.Count)];
                    AddCardsToGeneral(picker, aiPick);
                    UpdateHandCountsVisual();

                    if (cardUiMap.TryGetValue(aiPick, out var aiGo) && aiGo != null)
                    {
                        Destroy(aiGo);
                    }
                    cardUiMap.Remove(aiPick);

                    AudioManager.Instance.PlayCardDraw();
                    SetLog($"🍚 <b>{picker.GeneralName}</b> đã lấy lá {GetFormattedCardName(aiPick)}!");
                    yield return new WaitForSeconds(0.6f);
                }
            }
        }

        if (modalGo != null) Destroy(modalGo);
    }

    private List<GeneralCardUI> GetLivingGeneralsStartingRightOf(GeneralCardUI caster)
    {
        var list = new List<GeneralCardUI>();
        int startIdx = turnOrderGenerals.IndexOf(caster);
        if (startIdx < 0) startIdx = 0;

        for (int i = 1; i <= turnOrderGenerals.Count; i++)
        {
            int idx = (startIdx + i) % turnOrderGenerals.Count;
            var g = turnOrderGenerals[idx];
            if (g != null && g.CurrentHp > 0 && g != caster)
            {
                list.Add(g);
            }
        }
        return list;
    }

    private IEnumerator ResolveAoERequirement(GeneralCardUI victim, bool needSlash, string aoeName, string reqName)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        if (victim == null || victim.CurrentHp <= 0 || battleFinished) yield break;

        PauseTurnTimer(); // Tạm dừng và ẩn bộ đếm của người ra bài trong lúc chờ mục tiêu phản ứng
        victim.SetAwaitingReaction(true); // Nhấp nháy avatar tướng đang cần ra bài né cẩm nang diện rộng
        victim.ShowHeadTimer(40); // Bật đếm ngược 40s bên trái avatar của Victim
        SetLog($"👉 <b>[{aoeName}]</b>: Đang kiểm tra <b>{victim.GeneralName}</b> (Cần đánh lá [{reqName}] - 40s)...");

        bool satisfied = false;

        // Kiểm tra Khiên Mây Bện nếu cần Đỡ (Mưa Tên Liên Châu)
        if (string.IsNullOrEmpty(currentRoomId) && !needSlash && victim.HasEquipment(EquipmentType.Armor, "Khiên Mây"))
        {
            yield return TryKhienMayDefense(victim, aoeName, (success) =>
            {
                if (success) satisfied = true;
            });
        }

        if (satisfied)
        {
            victim.HideHeadTimer();
            victim.SetAwaitingReaction(false);
            yield break;
        }

        if (victim == playerCard)
        {
            // Bảng Phản Hồi Cho Người Chơi Chọn Ra Bài Hoặc Chịu Mất Máu
            bool decided = false;
            float reactionTimer = 40.0f;

            var reactionGo = new GameObject("AoEReactionPanel", typeof(RectTransform));
            reactionGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
            var rRt = reactionGo.GetComponent<RectTransform>();
            SetRect(rRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(680f, 52f), new Vector2(-70f, 238f));

            var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

            var respBtnGo = new GameObject("Btn_Respond", typeof(RectTransform), typeof(Image), typeof(Button));
            respBtnGo.transform.SetParent(reactionGo.transform, false);
            var dImg = respBtnGo.GetComponent<Image>();
            if (btnSpr != null) { dImg.sprite = btnSpr; dImg.type = Image.Type.Sliced; }
            var dRt = respBtnGo.GetComponent<RectTransform>();
            SetRect(dRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(270f, 44f), new Vector2(-100f, 0));

            string actionLabel = needSlash ? "⚔️ ĐÁNH [TRẢM] ĐỂ NÉ" : "🛡️ ĐÁNH [ĐỠ] ĐỂ NÉ";
            var dTxt = AddText(respBtnGo.transform, "Txt", actionLabel, 14, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(dTxt.rectTransform);

            var dBtn = respBtnGo.GetComponent<Button>();
            dBtn.interactable = false;
            dImg.color = new Color(0.40f, 0.44f, 0.52f, 0.85f);

            var noDodgeBtnGo = new GameObject("Btn_NoCard", typeof(RectTransform), typeof(Image), typeof(Button));
            noDodgeBtnGo.transform.SetParent(reactionGo.transform, false);
            var ndImg = noDodgeBtnGo.GetComponent<Image>();
            if (btnSpr != null) { ndImg.sprite = btnSpr; ndImg.type = Image.Type.Sliced; }
            ndImg.color = ThemeUI.CrimsonRed;
            var ndRt = noDodgeBtnGo.GetComponent<RectTransform>();
            SetRect(ndRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(230f, 44f), new Vector2(170f, 0));

            var ndTxt = AddText(noDodgeBtnGo.transform, "Txt", "❌ KHÔNG RA BÀI (MẤT 1 MÁU)", 13, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(ndTxt.rectTransform);

            CardUI chosenCardUI = null;

            Action<CardUI> onCardSelectedReaction = (cardUI) =>
            {
                bool match = (cardUI != null && cardUI.Data != null && (needSlash ? IsSlashCard(cardUI.Data) : cardUI.Data.subType == CardSubType.Dodge));
                if (match)
                {
                    chosenCardUI = cardUI;
                    dBtn.interactable = true;
                    dImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                    SetLog($"🛡️ Đã chọn {GetFormattedCardName(cardUI.Data)}. Nhấn nút [{actionLabel}]!");
                }
                else
                {
                    chosenCardUI = null;
                    dBtn.interactable = false;
                    dImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
                }
            };

            playerHandUI.HighlightOnlyMatching(c => c != null && (needSlash ? IsSlashCard(c) : c.subType == CardSubType.Dodge));
            playerHandUI.OnCardSelected += onCardSelectedReaction;

            dBtn.onClick.AddListener(() =>
            {
                if (chosenCardUI != null)
                {
                    var cardData = chosenCardUI.Data;
                    playerHandCards.Remove(cardData);
                    playerHandUI.RemoveCard(chosenCardUI);
                    deckManager.DiscardCard(cardData);
                    UpdateHandCountsVisual();

                    ShowCardAtCenter(cardData, playerCard, null, "Hóa giải diện rộng");
                    AudioManager.Instance.PlayParry();
                    SetLog($"🛡️ Bạn đã đánh ra {GetFormattedCardName(cardData)} để hóa giải [{aoeName}]!");

                    satisfied = true;
                    decided = true;
                }
            });

            noDodgeBtnGo.GetComponent<Button>().onClick.AddListener(() =>
            {
                satisfied = false;
                decided = true;
            });

            while (!decided && !battleFinished)
            {
                if (!string.IsNullOrEmpty(currentRoomId)) reactionTimer = turnTimer;
                reactionTimer -= Time.unscaledDeltaTime;
                victim.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(reactionTimer)));

                if (reactionTimer <= 0f)
                {
                    SetLog($"⏰ <b>Hết 40s phản ứng!</b> Tự động không ra bài.");
                    satisfied = false;
                    decided = true;
                    break;
                }

                yield return null;
            }

            playerHandUI.OnCardSelected -= onCardSelectedReaction;
            playerHandUI.ClearHighlights();
            if (reactionGo != null) Destroy(reactionGo);

            if (!string.IsNullOrEmpty(currentRoomId))
            {

                DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                {
                    action = "RESPOND_ACTION",
                    roomId = currentRoomId,
                    seat = playerCard.SeatNumber,
                    accepted = satisfied,
                    cardId = (chosenCardUI != null && chosenCardUI.Data != null) ? chosenCardUI.Data.id : ""
                }, (s) => { if (s != null) ApplyServerGameState(s); });

                victim.HideHeadTimer();
                victim.SetAwaitingReaction(false);
                yield break;
            }
        }
        else if (!victim.IsAI && !string.IsNullOrEmpty(currentRoomId))
        {
            // Người chơi thật từ xa phản ứng AoE (Chờ tối đa 40s)
            SetLog($"⏳ Đang đợi <b>{victim.GeneralName}</b> phản ứng diện rộng... (40s)");
            float waitTimer = 40.0f;
            bool remoteDecided = false;

            while (waitTimer > 0f && !remoteDecided && !battleFinished)
            {
                waitTimer -= 0.35f;
                victim.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                {
                    foreach (var act in actions)
                    {
                        if (act.casterSeat == victim.SeatNumber && act.actionType == "RESPONSE_AOE" && !processedActionTimestamps.Contains(act.timestamp))
                        {
                            processedActionTimestamps.Add(act.timestamp);
                            satisfied = act.accepted;
                            remoteDecided = true;
                            if (satisfied)
                            {
                                var vHand = GetHandOfGeneral(victim);
                                if (vHand.Count > 0) vHand.RemoveAt(0);
                                UpdateHandCountsVisual();
                                AudioManager.Instance.PlayParry();
                                SetLog($"🛡️ <b>{victim.GeneralName}</b> đã né đòn diện rộng thành công!");
                            }
                        }
                    }
                });
                if (remoteDecided) break;
                yield return new WaitForSecondsRealtime(0.35f);
            }

            if (!remoteDecided && waitTimer <= 0f)
            {
                SetLog($"⏰ <b>{victim.GeneralName}</b> đã hết 40s phản ứng diện rộng, tự động chịu sát thương.");
                satisfied = false;
            }
        }
        else
        {
            // AI Xử lý lần lượt
            yield return new WaitForSeconds(1.0f);
            var hand = GetHandOfGeneral(victim);
            var matched = hand.Find(c => needSlash ? IsSlashCard(c) : c.subType == CardSubType.Dodge);
            if (matched != null)
            {
                hand.Remove(matched);
                deckManager.DiscardCard(matched);
                UpdateHandCountsVisual();
                satisfied = true;
                ShowCardAtCenter(matched, victim, null, "Hóa giải diện rộng");
                AudioManager.Instance.PlayParry();
                SetLog($"🛡️ <b>{victim.GeneralName}</b> đánh ra {GetFormattedCardName(matched)} để hóa giải [{aoeName}]!");
            }
        }

        victim.HideHeadTimer();

        if (!satisfied)
        {
            int aoeDamage = ApplyDamageMitigation(victim, 1, aoeName);
            if (aoeDamage > 0)
            {
                victim.TakeDamage(aoeDamage); AudioManager.Instance.PlayDamage(); StartCoroutine(ShakeCard(victim)); StartCoroutine(ShowFloatingDamage(victim, aoeDamage));
                SetLog($"💥 <b>{victim.GeneralName}</b> không ra [{reqName}], bị mất {aoeDamage} đóa sen máu!");
                yield return CheckNearDeath(victim, null);
            }
        }

        victim.SetAwaitingReaction(false); // Dừng nhấp nháy khi đã xử lý xong
        yield return new WaitForSeconds(0.6f);
    }

    /// <summary>
    /// Thách Đấu: Người chơi tự tay chọn lá Trảm để đáp trả hoặc chấp nhận thua mất 1 máu.
    /// </summary>
    private IEnumerator ResolveDuel(GeneralCardUI caster, GeneralCardUI target)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        PauseTurnTimer(); // Tạm dừng và ẩn bộ đếm của người ra bài trong lúc hai bên thách đấu
        ShowCardAtCenter(CardDatabase.CreateDeck(52).Find(c => c.subType == CardSubType.Duel), caster, target, "Đấu kiếm đối kháng");
        SetLog($"⚔️ <b>THÁCH ĐẤU PHÁT ĐỘNG!</b> {caster.GeneralName} ⚔️ {target.GeneralName}");
        yield return new WaitForSeconds(1.0f);

        GeneralCardUI currentDuelist = target;
        GeneralCardUI nextDuelist = caster;
        bool duelEnded = false;

        while (!duelEnded && !battleFinished)
        {
            bool playedSlash = false;
            currentDuelist.SetAwaitingReaction(true); // Nhấp nháy avatar tướng đang đến lượt đáp trả trong Thách Đấu
            currentDuelist.ShowHeadTimer(40); // Bật đếm ngược 40s trên avatar của Duelist

            if (currentDuelist == playerCard)
            {
                // Người chơi tự tay chọn Trảm
                bool playerDecided = false;
                float duelTimer = 40.0f;
                SetLog("⚔️ <color=#FF5555><b>ĐẾN LƯỢT BẠN ĐÁP TRẢ TRẢM TRONG THÁCH ĐẤU!</b></color> (Thời gian: 40s)");

                var panelGo = new GameObject("DuelReactionPanel", typeof(RectTransform));
                panelGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
                var rRt = panelGo.GetComponent<RectTransform>();
                SetRect(rRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(680f, 52f), new Vector2(-70f, 238f));

                var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

                var slashBtnGo = new GameObject("Btn_Slash", typeof(RectTransform), typeof(Image), typeof(Button));
                slashBtnGo.transform.SetParent(panelGo.transform, false);
                var sImg = slashBtnGo.GetComponent<Image>();
                if (btnSpr != null) { sImg.sprite = btnSpr; sImg.type = Image.Type.Sliced; }
                var sRt = slashBtnGo.GetComponent<RectTransform>();
                SetRect(sRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(270f, 44f), new Vector2(-100f, 0));

                var sTxt = AddText(slashBtnGo.transform, "Txt", "⚔️ ĐÁP TRẢ BẰNG [TRẢM]", 14, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
                Fill(sTxt.rectTransform);

                var sBtn = slashBtnGo.GetComponent<Button>();
                sBtn.interactable = false;
                sImg.color = new Color(0.40f, 0.44f, 0.52f, 0.85f);

                var giveUpBtnGo = new GameObject("Btn_GiveUp", typeof(RectTransform), typeof(Image), typeof(Button));
                giveUpBtnGo.transform.SetParent(panelGo.transform, false);
                var gImg = giveUpBtnGo.GetComponent<Image>();
                if (btnSpr != null) { gImg.sprite = btnSpr; gImg.type = Image.Type.Sliced; }
                gImg.color = ThemeUI.CrimsonRed;
                var gRt = giveUpBtnGo.GetComponent<RectTransform>();
                SetRect(gRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(230f, 44f), new Vector2(170f, 0));

                var gTxt = AddText(giveUpBtnGo.transform, "Txt", "❌ NHẬN THUA (MẤT 1 MÁU)", 13, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
                Fill(gTxt.rectTransform);

                CardUI chosenSlashUI = null;

                Action<CardUI> onDuelCardSelected = (cardUI) =>
                {
                    if (cardUI != null && cardUI.Data != null && IsSlashCard(cardUI.Data))
                    {
                        chosenSlashUI = cardUI;
                        sBtn.interactable = true;
                        sImg.color = new Color(0.2f, 0.75f, 0.3f, 1f);
                        SetLog($"⚔️ Đã chọn {GetFormattedCardName(cardUI.Data)}. Bấm nút [ĐÁP TRẢ BẰNG TRẢM]!");
                    }
                    else
                    {
                        chosenSlashUI = null;
                        sBtn.interactable = false;
                        sImg.color = new Color(0.5f, 0.5f, 0.5f, 0.8f);
                    }
                };

                playerHandUI.HighlightOnlyMatching(IsSlashCard);
                playerHandUI.OnCardSelected += onDuelCardSelected;

                sBtn.onClick.AddListener(() =>
                {
                    if (chosenSlashUI != null)
                    {
                        var sData = chosenSlashUI.Data;
                        playerHandCards.Remove(sData);
                        playerHandUI.RemoveCard(chosenSlashUI);
                        deckManager.DiscardCard(sData);
                        UpdateHandCountsVisual();

                        ShowCardAtCenter(sData, playerCard, null, "Đáp trả Thách Đấu");
                        AudioManager.Instance.PlaySlash();
                        SetLog($"⚔️ Bạn đáp trả 1 lá {GetFormattedCardName(sData)}!");

                        playedSlash = true;
                        playerDecided = true;
                    }
                });

                giveUpBtnGo.GetComponent<Button>().onClick.AddListener(() =>
                {
                    playedSlash = false;
                    playerDecided = true;
                });

                while (!playerDecided && !battleFinished)
                {
                    if (!string.IsNullOrEmpty(currentRoomId)) duelTimer = turnTimer;
                    duelTimer -= Time.unscaledDeltaTime;
                    currentDuelist.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(duelTimer)));

                    if (duelTimer <= 0f)
                    {
                        SetLog("⏰ <b>Hết 40s đáp trả Thách Đấu!</b> Tự động nhận thua.");
                        playedSlash = false;
                        playerDecided = true;
                        break;
                    }

                    yield return null;
                }

                playerHandUI.OnCardSelected -= onDuelCardSelected;
                playerHandUI.ClearHighlights();
                if (panelGo != null) Destroy(panelGo);

                if (!string.IsNullOrEmpty(currentRoomId))
                {

                    DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                    {
                        action = "RESPOND_ACTION",
                        roomId = currentRoomId,
                        seat = playerCard.SeatNumber,
                        accepted = playedSlash,
                        cardId = (chosenSlashUI != null && chosenSlashUI.Data != null) ? chosenSlashUI.Data.id : ""
                    }, (s) => { if (s != null) ApplyServerGameState(s); });

                    yield break;
                }
            }
            else if (!currentDuelist.IsAI && !string.IsNullOrEmpty(currentRoomId))
            {
                // Người chơi thật từ xa đáp trả Thách Đấu (Chờ tối đa 40s)
                SetLog($"⏳ Đang đợi <b>{currentDuelist.GeneralName}</b> đáp trả Thách Đấu... (40s)");
                float waitTimer = 40.0f;
                bool remoteDecided = false;

                while (waitTimer > 0f && !remoteDecided && !battleFinished)
                {
                    waitTimer -= 0.35f;
                    currentDuelist.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                    yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                    {
                        foreach (var act in actions)
                        {
                            if (act.casterSeat == currentDuelist.SeatNumber && act.actionType == "RESPONSE_DUEL" && !processedActionTimestamps.Contains(act.timestamp))
                            {
                                processedActionTimestamps.Add(act.timestamp);
                                playedSlash = act.accepted;
                                remoteDecided = true;
                                if (playedSlash)
                                {
                                    var dHand = GetHandOfGeneral(currentDuelist);
                                    if (dHand.Count > 0) dHand.RemoveAt(0);
                                    UpdateHandCountsVisual();
                                    AudioManager.Instance.PlaySlash();
                                    SetLog($"⚔️ <b>{currentDuelist.GeneralName}</b> đáp trả 1 lá [TRẢM] trong Thách Đấu!");
                                }
                            }
                        }
                    });
                    if (remoteDecided) break;
                    yield return new WaitForSecondsRealtime(0.35f);
                }

                if (!remoteDecided && waitTimer <= 0f)
                {
                    SetLog($"⏰ <b>{currentDuelist.GeneralName}</b> hết 40s đáp trả Thách Đấu, nhận thất bại.");
                    playedSlash = false;
                }
            }
            else
            {
                // AI đáp trả
                yield return new WaitForSeconds(1.0f);
                var hand = GetHandOfGeneral(currentDuelist);
                var s = hand.Find(c => IsSlashCard(c));
                if (s != null)
                {
                    hand.Remove(s);
                    deckManager.DiscardCard(s);
                    UpdateHandCountsVisual();
                    playedSlash = true;
                    ShowCardAtCenter(s, currentDuelist, null, "Đáp trả Thách Đấu");
                    AudioManager.Instance.PlaySlash();
                    SetLog($"⚔️ <b>{currentDuelist.GeneralName}</b> đáp trả 1 lá [Trảm]!");
                }
            }

            currentDuelist.HideHeadTimer();
            currentDuelist.SetAwaitingReaction(false);

            yield return new WaitForSeconds(0.8f);

            if (playedSlash)
            {
                var temp = currentDuelist;
                currentDuelist = nextDuelist;
                nextDuelist = temp;
            }
            else
            {
                duelEnded = true;
                currentDuelist.TakeDamage(1); AudioManager.Instance.PlayDamage(); StartCoroutine(ShakeCard(currentDuelist)); StartCoroutine(ShowFloatingDamage(currentDuelist, 1));
                SetLog($"💥 <b>{currentDuelist.GeneralName}</b> hết Trảm đáp trả, thất bại trong Thách Đấu và mất 1 Máu!");
                yield return CheckNearDeath(currentDuelist, nextDuelist);
            }
        }
    }

    private IEnumerator ResolveDelayedScrollPlacement(CardModel card, GeneralCardUI caster, GeneralCardUI target)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        GeneralCardUI placeTarget = (card.subType == CardSubType.Lightning) ? caster : target;
        if (placeTarget != null)
        {
            if (placeTarget.AddDelayedScroll(card))
            {
                ShowCardAtCenter(card, caster, placeTarget, "Gài vào vùng Phán Xét");
                AudioManager.Instance.PlaySkill();
                SetLog($"⏳ Đã gài {GetFormattedCardName(card)} vào vùng Phán Xét của <b>{placeTarget.GeneralName}</b>!");
            }
            else
            {
                if (caster == playerCard)
                {
                    playerHandCards.Add(card);
                    playerHandUI.AddCard(card);
                }
                else
                {
                    var hand = GetHandOfGeneral(caster);
                    hand.Add(card);
                }
                UpdateHandCountsVisual();
                SetLog($"⚠️ <b>{placeTarget.GeneralName}</b> đã có cẩm nang cùng loại! {GetFormattedCardName(card)} được trả về tay.");
            }
        }
        yield break;
    }
    #endregion

    #region 9. MODAL CHỌN BÀI CƯỚP HOẶC PHÁ HỦY (HỖ TRỢ 100% TRANG BỊ & PHÁN XÉT)

    private void ShowIronChainSelectionModal(GeneralCardUI caster, Action<List<GeneralCardUI>> onConfirmed)
    {
        var overlayGo = ThemeUI.CreateModal(canvasGo.transform, "IronChainModal", "⛓️ XÍCH TÂM TỎA: CHỌN TỐI ĐA 2 TƯỚNG", new Vector2(740f, 440f), out var contentRt, new Color(0.18f, 0.12f, 0.05f, 0.98f));

        var subTxt = ThemeUI.CreateText(contentRt, "Sub", "Chọn 1 hoặc 2 tướng để trói vào Xích Liên Hoàn (hoặc gỡ xích). Sát thương Hỏa/Lôi sẽ truyền qua xích!", ThemeUI.SizeBody, ThemeUI.GoldHighlight, FontStyle.Normal, TextAnchor.MiddleCenter, true);
        ThemeUI.SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(700f, 40f), new Vector2(0f, -65f));

        var gridGo = new GameObject("Grid", typeof(RectTransform), typeof(GridLayoutGroup));
        gridGo.transform.SetParent(contentRt, false);
        var glg = gridGo.GetComponent<GridLayoutGroup>();
        glg.cellSize = new Vector2(160f, 210f);
        glg.spacing = new Vector2(16f, 0f);
        glg.childAlignment = TextAnchor.MiddleCenter;
        var gRt = gridGo.GetComponent<RectTransform>();
        ThemeUI.SetRect(gRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(700f, 220f), new Vector2(0f, -10f));

        var selectedGenerals = new HashSet<GeneralCardUI>();
        var buttonImages = new Dictionary<GeneralCardUI, Image>();
        var checkTexts = new Dictionary<GeneralCardUI, Text>();

        var livingGenerals = new List<GeneralCardUI>();
        if (allGenerals != null)
        {
            foreach (var g in allGenerals)
            {
                if (g != null && g.CurrentHp > 0) livingGenerals.Add(g);
            }
        }

        foreach (var g in livingGenerals)
        {
            var cardBtnGo = new GameObject("Gen_" + g.SeatNumber, typeof(RectTransform), typeof(Image), typeof(Button));
            cardBtnGo.transform.SetParent(gridGo.transform, false);
            var cImg = cardBtnGo.GetComponent<Image>();
            cImg.color = new Color(0.12f, 0.16f, 0.24f, 0.95f);
            buttonImages[g] = cImg;

            var bBorder = new GameObject("Border", typeof(RectTransform), typeof(Image));
            bBorder.transform.SetParent(cardBtnGo.transform, false);
            var bbImg = bBorder.GetComponent<Image>();
            var fSpr = ThemeUI.LoadSprite("UI/card_frame");
            if (fSpr != null) { bbImg.sprite = fSpr; bbImg.type = Image.Type.Sliced; }
            bbImg.color = g.IsChained ? new Color(1f, 0.4f, 0.4f, 1f) : ThemeUI.GoldPrimary;
            ThemeUI.Fill(bBorder.GetComponent<RectTransform>(), new Vector2(-2, -2), new Vector2(2, 2));

            var nameTxt = ThemeUI.CreateText(cardBtnGo.transform, "Name", $"#{g.SeatNumber} {g.GeneralName}", ThemeUI.SizeBody, ThemeUI.WhitePure, FontStyle.Bold, TextAnchor.UpperCenter, true);
            ThemeUI.SetRect(nameTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(150f, 30f), new Vector2(0f, -10f));

            var hpTxt = ThemeUI.CreateText(cardBtnGo.transform, "Hp", $"❤️ {g.CurrentHp}/{g.MaxHp} máu", ThemeUI.SizeMicro, new Color(0.55f, 0.9f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter, true);
            ThemeUI.SetRect(hpTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(150f, 24f), new Vector2(0f, 15f));

            string currentStatus = g.IsChained ? "⛓️ Đang Xích" : "🔓 Tự do";
            var statusTxt = ThemeUI.CreateText(cardBtnGo.transform, "Status", currentStatus, ThemeUI.SizeMicro, g.IsChained ? new Color(1f, 0.5f, 0.5f, 1f) : ThemeUI.GoldHighlight, FontStyle.Bold, TextAnchor.MiddleCenter, true);
            ThemeUI.SetRect(statusTxt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(150f, 24f), new Vector2(0f, -15f));

            var checkTxt = ThemeUI.CreateText(cardBtnGo.transform, "Check", "☐ CHỌN", ThemeUI.SizeBody, ThemeUI.TextMuted, FontStyle.Bold, TextAnchor.LowerCenter, true);
            ThemeUI.SetRect(checkTxt.rectTransform, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(150f, 32f), new Vector2(0f, 8f));
            checkTexts[g] = checkTxt;

            var targetGen = g;
            cardBtnGo.GetComponent<Button>().onClick.AddListener(() =>
            {
                AudioManager.Instance.PlayCardSelect();
                if (selectedGenerals.Contains(targetGen))
                {
                    selectedGenerals.Remove(targetGen);
                    cImg.color = new Color(0.12f, 0.16f, 0.24f, 0.95f);
                    checkTxt.text = "☐ CHỌN";
                    checkTxt.color = ThemeUI.TextMuted;
                }
                else
                {
                    if (selectedGenerals.Count >= 2)
                    {
                        SetLog("⚠️ Chỉ được chọn tối đa 2 mục tiêu cho Xích Tâm Tỏa!");
                        return;
                    }
                    selectedGenerals.Add(targetGen);
                    cImg.color = new Color(0.35f, 0.25f, 0.08f, 0.98f);
                    checkTxt.text = "☑ ĐÃ CHỌN";
                    checkTxt.color = ThemeUI.GoldHighlight;
                }
            });
        }

        var btnGroup = new GameObject("BtnGroup", typeof(RectTransform));
        btnGroup.transform.SetParent(contentRt, false);
        var bgRt = btnGroup.GetComponent<RectTransform>();
        ThemeUI.SetRect(bgRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(480f, 48f), new Vector2(0f, 28f));

        ThemeUI.CreateButton(btnGroup.transform, "ConfirmBtn", "⛓️ XÁC NHẬN XÍCH", new Vector2(220f, 44f), new Vector2(120f, 0f), () =>
        {
            Destroy(overlayGo);
            onConfirmed?.Invoke(new List<GeneralCardUI>(selectedGenerals));
        }, ThemeUI.ButtonTheme.Gold);

        ThemeUI.CreateButton(btnGroup.transform, "CancelBtn", "✕ HỦY BỎ", new Vector2(180f, 44f), new Vector2(-120f, 0f), () =>
        {
            Destroy(overlayGo);
            onConfirmed?.Invoke(new List<GeneralCardUI>());
        }, ThemeUI.ButtonTheme.Dark);
    }

    private bool ShowCardStealOrDestroyModal(GeneralCardUI target, bool isSteal, string actionTitle, Action<CardModel> onCardSelected)
    {
        if (target == null) return false;

        bool allowDelayed = isSteal;
        var options = BuildTargetCardOptions(target, allowDelayed);
        if (options.Count == 0)
        {
            SetLog($"ℹ️ {target.GeneralName} không có lá bài hợp lệ trong tay, vùng trang bị hoặc vùng trì hoãn.");
            return false;
        }

        var modalGo = new GameObject("CardPickModal", typeof(RectTransform), typeof(CanvasGroup), typeof(Image));
        modalGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        modalGo.transform.SetAsLastSibling();
        activeCardPickModal = modalGo;

        var mImg = modalGo.GetComponent<Image>();
        mImg.color = new Color(0.02f, 0.03f, 0.07f, 0.88f);
        Fill(modalGo.GetComponent<RectTransform>());

        var panelGo = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        panelGo.transform.SetParent(modalGo.transform, false);
        var panelRt = panelGo.GetComponent<RectTransform>();
        panelRt.anchorMin = panelRt.anchorMax = panelRt.pivot = new Vector2(0.5f, 0.5f);
        panelRt.sizeDelta = new Vector2(760f, 450f);
        panelRt.anchoredPosition = Vector2.zero;

        var pImg = panelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { pImg.sprite = slotSpr; pImg.type = Image.Type.Sliced; }
        pImg.color = new Color(0.08f, 0.11f, 0.20f, 0.98f);

        var headerGo = new GameObject("HeaderBanner", typeof(RectTransform), typeof(Image));
        headerGo.transform.SetParent(panelGo.transform, false);
        var hImg = headerGo.GetComponent<Image>();
        var badgeSpr = LotusHealthUI.LoadSpriteFromResources("UI/badge_faction");
        if (badgeSpr != null) { hImg.sprite = badgeSpr; hImg.type = Image.Type.Sliced; }
        hImg.color = isSteal ? new Color(0.12f, 0.45f, 0.85f, 0.98f) : new Color(0.85f, 0.25f, 0.15f, 0.98f);
        var hRt = headerGo.GetComponent<RectTransform>();
        SetRect(hRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(700f, 48f), new Vector2(0, -12f));

        var titleTxt = AddText(headerGo.transform, "Title", actionTitle, 16, new Color(1f, 0.94f, 0.55f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(titleTxt.rectTransform);

        var subTxt = AddText(panelGo.transform, "SubTitle", $"💡 Chạm chọn 1 lá bài của tướng [{target.GeneralName}] ({options.Count} lựa chọn):", 12, new Color(0.9f, 0.93f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        SetRect(subTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(700f, 24f), new Vector2(0, -66f));

        var viewportGo = new GameObject("CardsViewport", typeof(RectTransform), typeof(Image), typeof(RectMask2D), typeof(ScrollRect));
        viewportGo.transform.SetParent(panelGo.transform, false);
        var viewportRt = viewportGo.GetComponent<RectTransform>();
        SetRect(viewportRt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(710f, 250f), new Vector2(0f, -42f));
        var viewportImg = viewportGo.GetComponent<Image>();
        viewportImg.color = new Color(0.02f, 0.04f, 0.09f, 0.35f);

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
        hlg.childControlWidth = hlg.childControlHeight = false;

        var scroll = viewportGo.GetComponent<ScrollRect>();
        scroll.viewport = viewportRt;
        scroll.content = contentRt;
        scroll.horizontal = true;
        scroll.vertical = false;
        scroll.movementType = ScrollRect.MovementType.Clamped;

        int handIndex = 1;
        foreach (var option in options)
        {
            if (option == null || option.Card == null) continue;
            var selectedOption = option;
            GameObject cardItemGo;

            void HandleOptionClick()
            {
                if (!TryRemoveTargetCardOption(target, selectedOption))
                {
                    SetLog("⚠️ Lá bài này không còn ở vùng mục tiêu. Hãy chọn lá khác.");
                    return;
                }

                AudioManager.Instance.PlayCardSelect();
                if (activeCardPickModal == modalGo) activeCardPickModal = null;
                Destroy(modalGo);
                onCardSelected?.Invoke(selectedOption.Card);
            }

            if (selectedOption.Zone == TargetCardZone.Hand)
            {
                cardItemGo = CreateFaceDownCardItem(cardsContainerGo.transform, new Vector2(118f, 162f), $"LÁ BÀI #{handIndex}", font);
                handIndex++;
                var btn = cardItemGo.GetComponent<Button>();
                if (btn != null) btn.onClick.AddListener(HandleOptionClick);
            }
            else
            {
                var cardUI = CardUI.Create(cardsContainerGo.transform, selectedOption.Card, new Vector2(118f, 162f));
                cardItemGo = cardUI.gameObject;
                cardUI.OnCardClicked += (c) => HandleOptionClick();

                var overlayBtn = new GameObject("OverlayBtn", typeof(RectTransform), typeof(Image), typeof(Button));
                overlayBtn.transform.SetParent(cardItemGo.transform, false);
                overlayBtn.transform.SetAsLastSibling();
                var oImg = overlayBtn.GetComponent<Image>();
                oImg.color = new Color(1f, 1f, 1f, 0.001f);
                Fill(overlayBtn.GetComponent<RectTransform>());
                overlayBtn.GetComponent<Button>().onClick.AddListener(HandleOptionClick);
            }

            AddTargetZoneLabel(cardItemGo.transform, selectedOption.Label, font);
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
        if (backSprite != null) { img.sprite = backSprite; img.type = Image.Type.Sliced; }
        else img.color = new Color(0.14f, 0.18f, 0.28f, 0.98f);

        var borderGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
        borderGo.transform.SetParent(go.transform, false);
        var bImg = borderGo.GetComponent<Image>();
        var frameSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
        if (frameSpr != null) { bImg.sprite = frameSpr; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.95f, 0.8f, 0.3f, 0.9f);
        bImg.raycastTarget = false;
        Fill(borderGo.GetComponent<RectTransform>());

        var txt = AddText(go.transform, "CenterText", $"🎴\n<size=12><color=#FFD700>{label}</color></size>", 15, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        txt.lineSpacing = 1.3f;
        Fill(txt.rectTransform, new Vector2(6, 6), new Vector2(-6, -6));

        return go;
    }

    private void AddTargetZoneLabel(Transform parent, string zoneLabel, Font font)
    {
        var labelGo = new GameObject("ZoneBadge", typeof(RectTransform), typeof(Image));
        labelGo.transform.SetParent(parent, false);
        labelGo.transform.SetAsLastSibling();
        var img = labelGo.GetComponent<Image>();
        var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
        if (slotSpr != null) { img.sprite = slotSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.04f, 0.07f, 0.14f, 0.95f);

        var label = AddText(labelGo.transform, "Txt", zoneLabel, 9, new Color(1f, 0.85f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        var rt = labelGo.GetComponent<RectTransform>();
        SetRect(rt, new Vector2(0f, 0f), new Vector2(1f, 0f), new Vector2(0.5f, 0f), new Vector2(0f, 18f), new Vector2(0f, 2f));
        Fill(label.rectTransform);
    }

    private List<TargetCardOption> BuildTargetCardOptions(GeneralCardUI target, bool allowDelayed)
    {
        var options = new List<TargetCardOption>();
        var hand = GetHandOfGeneral(target);

        foreach (var c in hand)
        {
            if (c == null) continue;
            options.Add(new TargetCardOption
            {
                Card = c,
                Zone = TargetCardZone.Hand,
                Label = "TRÊN TAY"
            });
        }

        foreach (EquipmentType eqType in Enum.GetValues(typeof(EquipmentType)))
        {
            var eq = target.GetEquippedCard(eqType);
            if (eq != null)
            {
                string eqName = eqType switch
                {
                    EquipmentType.Weapon => "Vũ Khí",
                    EquipmentType.Armor => "Áo Giáp",
                    EquipmentType.OffensiveMount => "Ngựa Công",
                    EquipmentType.DefensiveMount => "Ngựa Thủ",
                    _ => "Trang Bị"
                };

                options.Add(new TargetCardOption
                {
                    Card = eq,
                    Zone = TargetCardZone.Equipment,
                    EquipmentType = eqType,
                    Label = $"TRANG BỊ ({eqName})"
                });
            }
        }

        if (allowDelayed)
        {
            var delayTypes = new[] { CardSubType.SupplyShortage, CardSubType.Acedia, CardSubType.Lightning };
            foreach (var dt in delayTypes)
            {
                var del = target.GetDelayedScroll(dt);
                if (del != null)
                {
                    options.Add(new TargetCardOption
                    {
                        Card = del,
                        Zone = TargetCardZone.Delayed,
                        DelayedType = dt,
                        Label = "PHÁN XÉT"
                    });
                }
            }
        }

        return options;
    }

    private bool TryRemoveTargetCardOption(GeneralCardUI target, TargetCardOption option)
    {
        if (target == null || option == null || option.Card == null) return false;

        switch (option.Zone)
        {
            case TargetCardZone.Hand:
                var hand = GetHandOfGeneral(target);
                if (hand.Contains(option.Card))
                {
                    hand.Remove(option.Card);
                    if (target == playerCard) { playerHandUI.ClearHand(); playerHandUI.AddCards(playerHandCards); }
                    UpdateHandCountsVisual();
                    return true;
                }
                return false;

            case TargetCardZone.Equipment:
                if (target.TryUnequip(option.EquipmentType, out _))
                {
                    return true;
                }
                return false;

            case TargetCardZone.Delayed:
                return target.RemoveDelayedScroll(option.DelayedType);

            default:
                return false;
        }
    }
    #endregion

    #region 10. GIAI ĐOẠN BỎ BÀI 40S
    
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

    private IEnumerator StartDiscardPhase(GeneralCardUI g)
    {
        bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
        int handCount = GetHandCountOf(g);
        int hp = g.CurrentHp;
        int excess = handCount - hp;

        if (excess <= 0 || hp <= 0 || battleFinished) yield break;

        g.ShowHeadTimer(40);

        if (g == playerCard)
        {
            isDiscardPhaseActive = true; 
            discardExcessRequired = excess; 
            selectedDiscardCards.Clear(); 
            if (playerHandUI != null) 
            { 
                playerHandUI.IsMultiSelectMode = true;
                playerHandUI.MaxSelectableCards = discardExcessRequired; 
                playerHandUI.MaxSelectableCards = discardExcessRequired; 
                playerHandUI.ClearSelection(); 
                playerHandUI.ClearHighlights(); 
                playerHandUI.OnSelectionChanged += OnDiscardSelectionChanged;
            } 
            turnTimer = 40.0f; 
            isTimerRunning = true;

            discardConfirmBtn.gameObject.SetActive(true);
            discardConfirmBtn.interactable = false;
            discardConfirmBtnText.text = $"BỎ BÀI (0/{discardExcessRequired})";

            SetLog($"⚠️ <b>Giai đoạn Bỏ Bài:</b> Bạn có {handCount} lá trên tay nhưng chỉ còn {hp} máu. Hãy chọn bỏ {excess} lá thừa (Thời gian: 40s)!");

            while (isDiscardPhaseActive && !battleFinished
                && (!serverControlled || IsAuthoritativePromptActive("DISCARD")))
            {
                yield return null;
            }

            isTimerRunning = false;
            g.HideHeadTimer();
            discardConfirmBtn.gameObject.SetActive(false);
        }
        else if (!g.IsAI && !string.IsNullOrEmpty(currentRoomId))
        {
            // NGƯỜI CHƠI ONLINE BỎ BÀI (Chờ tối đa 40s để họ chọn bỏ bài thừa)
            float waitTimer = 40.0f;
            isTimerRunning = false;
            g.ShowHeadTimer(40);
            SetLog($"⏳ Đang đợi <b>{g.GeneralName}</b> bỏ {excess} lá bài thừa... (Thời gian: 40s)");

            bool remoteDiscardFinished = false;

            while (!remoteDiscardFinished && waitTimer > 0f && !battleFinished)
            {
                waitTimer -= Time.unscaledDeltaTime;
                g.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                int currentHCount = GetHandCountOf(g);
                if (currentHCount <= g.CurrentHp)
                {
                    remoteDiscardFinished = true;
                    break;
                }

                yield return null;
            }

            if (!remoteDiscardFinished && waitTimer <= 0f)
            {
                SetLog($"⏰ <b>{g.GeneralName}</b> hết 40s bỏ bài! Hệ thống tự động bỏ các lá bài thừa.");
                var hand = GetHandOfGeneral(g);
                while (hand.Count > g.CurrentHp && hand.Count > 0)
                {
                    var discarded = hand[0];
                    hand.RemoveAt(0);
                    deckManager.DiscardCard(discarded);
                }
                UpdateHandCountsVisual();
            }

            g.HideHeadTimer();
        }
        else
        {
            // BOT AI BỎ BÀI
            g.ShowHeadTimer(40);
            SetLog($"📦 <b>{g.GeneralName}</b> đang chọn bỏ {excess} lá bài thừa...");
            yield return new WaitForSeconds(3.0f);
            var hand = GetHandOfGeneral(g);
            for (int i = 0; i < excess && hand.Count > 0; i++)
            {
                var discarded = hand[0];
                hand.RemoveAt(0);
                deckManager.DiscardCard(discarded);
            }
            UpdateHandCountsVisual();
            g.HideHeadTimer();
        }
    }

    private void OnDiscardSelectionChanged(List<CardUI> selectedCards)
    {
        if (!isDiscardPhaseActive) return;
        selectedDiscardCards.Clear();
        if (selectedCards != null)
        {
            selectedDiscardCards.AddRange(selectedCards);
        }
        discardConfirmBtnText.text = $"BỎ BÀI ({selectedDiscardCards.Count}/{discardExcessRequired})";
        discardConfirmBtn.interactable = selectedDiscardCards.Count == discardExcessRequired;
    }

    private void OnPlayerConfirmDiscardClicked()
    {
        if (!isDiscardPhaseActive || selectedDiscardCards.Count < discardExcessRequired) return;

        var discardedCardIds = new List<string>();
        foreach (var cardUI in selectedDiscardCards)
        {
            if (cardUI != null && cardUI.Data != null)
            {
                discardedCardIds.Add(cardUI.Data.id);
                if (string.IsNullOrEmpty(currentRoomId))
                {
                    playerHandCards.Remove(cardUI.Data);
                    deckManager.DiscardCard(cardUI.Data);
                    playerHandUI.RemoveCard(cardUI);
                }
            }
        }

        if (!string.IsNullOrEmpty(currentRoomId))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "DISCARD_CARDS",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                cardIds = discardedCardIds
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }

        selectedDiscardCards.Clear(); if (playerHandUI != null) { playerHandUI.IsMultiSelectMode = false; playerHandUI.ClearSelection(); playerHandUI.OnSelectionChanged -= OnDiscardSelectionChanged; } AudioManager.Instance.PlayCardDiscard();
        UpdateHandCountsVisual();
        if (string.IsNullOrEmpty(currentRoomId))
        {
            isDiscardPhaseActive = false;
        }
        else if (discardConfirmBtn != null)
        {
            discardConfirmBtn.interactable = false;
        }
    }

    private void OnTimerExpired()
    {
        if (!string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected)
        {
            return;
        }

        if (isDiscardPhaseActive)
        {
            SetLog("⏰ Hết 40s! Hệ thống tự động bỏ các lá bài thừa về đúng số máu.");
            while (playerHandCards.Count > playerCard.CurrentHp)
            {
                var card = playerHandCards[playerHandCards.Count - 1];
                playerHandCards.RemoveAt(playerHandCards.Count - 1);
                deckManager.DiscardCard(card);
            }
            playerHandUI.ClearHand();
            playerHandUI.AddCards(playerHandCards);
            selectedDiscardCards.Clear(); if (playerHandUI != null) { playerHandUI.IsMultiSelectMode = false; playerHandUI.ClearSelection(); playerHandUI.OnSelectionChanged -= OnDiscardSelectionChanged; } AudioManager.Instance.PlayCardDiscard();
            UpdateHandCountsVisual();
            isDiscardPhaseActive = false;
        }
        else if (isPlayerTurnActive)
        {
            SetLog("⏰ Hết 40s suy nghĩ! Tự động kết thúc lượt ra bài.");
            isPlayerTurnActive = false;
        }
    }
    #endregion

    #region 11. CỨU VIỆN CẬN TỬ & KẾT THÚC TRẬN ĐẤU (HỎI LẦN LƯỢT TỪNG NGƯỜI)
    private IEnumerator CheckNearDeath(GeneralCardUI victim, GeneralCardUI killer)
    {
        if (!string.IsNullOrEmpty(currentRoomId)) yield break;
        if (victim.CurrentHp > 0) yield break;

        PauseTurnTimer(); // Tạm dừng đồng hồ của người ra bài trong lúc xử lý cứu viện

        SetLog($"💔 <color=#FF5555><b>{victim.GeneralName} ĐANG TRONG TRẠNG THÁI CẬN TỬ (0 MÁU)!</b></color>");

        bool saved = false;

        var askOrder = new List<GeneralCardUI>();
        // Người trong lượt trước (currentTurnIndex), sau đó đến người kế bên phải (chiều kim đồng hồ) cho đến hết vòng
        int startIdx = (currentTurnIndex >= 0 && currentTurnIndex < turnOrderGenerals.Count) ? currentTurnIndex : 0;

        for (int i = 0; i < turnOrderGenerals.Count; i++)
        {
            int idx = (startIdx + i) % turnOrderGenerals.Count;
            var g = turnOrderGenerals[idx];
            if (g.CurrentHp > 0 || g == victim)
            {
                askOrder.Add(g);
            }
        }

        foreach (var asker in askOrder)
        {
            if (victim.CurrentHp > 0)
            {
                saved = true;
                break;
            }

            if (asker == playerCard)
            {
                bool serverControlled = !string.IsNullOrEmpty(currentRoomId) || DenoGameClient.IsConnected;
                // Ưu tiên dùng Hủ Rượu nếu là tự cứu bản thân, hoặc Bánh Chưng
                var rescueCard = playerHandCards.Find(c => (asker == victim && c.subType == CardSubType.Wine) || c.subType == CardSubType.Peach);
                if (rescueCard != null)
                {
                    bool isSelfRescue = (victim == playerCard);
                    bool isWine = (rescueCard.subType == CardSubType.Wine);

                    bool decided = false;
                    bool usedRescue = false;
                    float timer = 40.0f;

                    asker.ShowHeadTimer(40);

                    var rescueModalGo = new GameObject("RescuePromptModal", typeof(RectTransform), typeof(Image));
                    rescueModalGo.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
                    rescueModalGo.transform.SetAsLastSibling();

                    var pImg = rescueModalGo.GetComponent<Image>();
                    var bgSpr = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
                    if (bgSpr != null) { pImg.sprite = bgSpr; pImg.type = Image.Type.Sliced; }
                    pImg.color = new Color(0.08f, 0.04f, 0.06f, 0.98f);

                    var pRt = rescueModalGo.GetComponent<RectTransform>();
                    pRt.anchorMin = pRt.anchorMax = pRt.pivot = new Vector2(0.5f, 0.5f);
                    pRt.sizeDelta = new Vector2(620f, 155f);
                    pRt.anchoredPosition = new Vector2(-80f, 120f);

                    var fGo = new GameObject("Frame", typeof(RectTransform), typeof(Image));
                    fGo.transform.SetParent(rescueModalGo.transform, false);
                    var fImg = fGo.GetComponent<Image>();
                    var fSpr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
                    if (fSpr != null) { fImg.sprite = fSpr; fImg.type = Image.Type.Sliced; }
                    fImg.color = isWine ? new Color(1f, 0.75f, 0.2f, 1f) : new Color(1f, 0.4f, 0.4f, 1f);
                    Fill(fGo.GetComponent<RectTransform>(), new Vector2(-1, -1), new Vector2(1, 1));

                    string titleStr = isWine
                        ? "🍶 TỰ CỨU CẬN TỬ: Uống [Hủ Rượu] tự cứu bản thân?"
                        : (isSelfRescue
                            ? "💮 CỨU CẬN TỬ: Dùng [Bánh Chưng] tự cứu bản thân?"
                            : $"💮 CỨU CẬN TỬ: Dùng [Bánh Chưng] cứu [{victim.GeneralName}]?");

                    var titleTxt = AddText(rescueModalGo.transform, "Title", titleStr, 13, new Color(1f, 0.9f, 0.4f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
                    SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(580f, 40f), new Vector2(0, -10f));

                    var timerTxt = AddText(rescueModalGo.transform, "Timer", "⏳ 40s", 12, new Color(1f, 0.7f, 0.7f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
                    SetRect(timerTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(250f, 22f), new Vector2(0, -46f));

                    var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");

                    var useBtnGo = new GameObject("Btn_Use", typeof(RectTransform), typeof(Image), typeof(Button));
                    useBtnGo.transform.SetParent(rescueModalGo.transform, false);
                    var uImg = useBtnGo.GetComponent<Image>();
                    if (btnSpr != null) { uImg.sprite = btnSpr; uImg.type = Image.Type.Sliced; }
                    uImg.color = isWine ? new Color(0.95f, 0.65f, 0.15f, 1f) : new Color(0.2f, 0.75f, 0.35f, 1f);
                    var uRt = useBtnGo.GetComponent<RectTransform>();
                    SetRect(uRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(260f, 38f), new Vector2(-135f, 16f));

                    string btnLabel = isWine
                        ? "🍶 UỐNG HỦ RƯỢU TỰ CỨU"
                        : (isSelfRescue ? "💮 DÙNG BÁNH CHƯNG TỰ CỨU" : $"💮 DÙNG BÁNH CHƯNG CỨU");

                    var uTxt = AddText(useBtnGo.transform, "Txt", btnLabel, 11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
                    Fill(uTxt.rectTransform);

                    var passBtnGo = new GameObject("Btn_Pass", typeof(RectTransform), typeof(Image), typeof(Button));
                    passBtnGo.transform.SetParent(rescueModalGo.transform, false);
                    var paImg = passBtnGo.GetComponent<Image>();
                    if (btnSpr != null) { paImg.sprite = btnSpr; paImg.type = Image.Type.Sliced; }
                    paImg.color = new Color(0.5f, 0.55f, 0.65f, 1f);
                    var paRt = passBtnGo.GetComponent<RectTransform>();
                    SetRect(paRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(200f, 38f), new Vector2(145f, 16f));

                    string passLabel = isSelfRescue ? "❌ KHÔNG TỰ CỨU" : "❌ KHÔNG CỨU";
                    var paTxt = AddText(passBtnGo.transform, "Txt", passLabel, 11, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
                    Fill(paTxt.rectTransform);

                    useBtnGo.GetComponent<Button>().onClick.AddListener(() =>
                    {
                        usedRescue = true;
                        decided = true;
                    });

                    passBtnGo.GetComponent<Button>().onClick.AddListener(() =>
                    {
                        usedRescue = false;
                        decided = true;
                    });

                    while (!decided && timer > 0f && !battleFinished)
                    {
                        if (serverControlled) timer = turnTimer;
            timer -= Time.unscaledDeltaTime;
            asker.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(timer)));
                        string waitingLabel = isWine ? $"⏳ Còn {Mathf.CeilToInt(timer)}s để uống Hủ Rượu tự cứu..." : $"⏳ Còn {Mathf.CeilToInt(timer)}s để cứu...";
                        if (timerTxt != null) timerTxt.text = waitingLabel;
                        yield return null;
                    }

                    asker.HideHeadTimer();
                    if (rescueModalGo != null) Destroy(rescueModalGo);

                    if (!string.IsNullOrEmpty(currentRoomId))
                    {

                        DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                        {
                            action = "RESPOND_ACTION",
                            roomId = currentRoomId,
                            seat = playerCard.SeatNumber,
                            targetSeat = victim.SeatNumber,
                            accepted = usedRescue,
                            cardId = (rescueCard != null) ? rescueCard.id : ""
                        }, (s) => { if (s != null) ApplyServerGameState(s); });
                    }

                    if (usedRescue)
                    {
                        playerHandCards.Remove(rescueCard);
                        playerHandUI.ClearHand();
                        playerHandUI.AddCards(playerHandCards);
                        deckManager.DiscardCard(rescueCard);
                        UpdateHandCountsVisual();

                        victim.Heal(1);
                        saved = true;

                        if (isWine)
                        {
                            ShowCardAtCenter(rescueCard, playerCard, victim, $"Bạn uống {GetFormattedCardName(rescueCard)} tự cứu sống");
                            AudioManager.Instance.PlayHeal();
                            SetLog($"🍶 <b>Bạn</b> đã kịp thời uống {GetFormattedCardName(rescueCard)} tự cứu sống bản thân!");
                        }
                        else
                        {
                            string centerTag = isSelfRescue ? $"Bạn dùng {GetFormattedCardName(rescueCard)} tự cứu sống" : $"Bạn dùng {GetFormattedCardName(rescueCard)} cứu sống";
                            ShowCardAtCenter(rescueCard, playerCard, victim, centerTag);
                            AudioManager.Instance.PlayHeal();
                            string logMsg = isSelfRescue
                                ? $"💮 <b>Bạn</b> đã kịp thời dùng {GetFormattedCardName(rescueCard)} tự cứu sống bản thân!"
                                : $"💮 <b>Bạn</b> đã kịp thời dùng {GetFormattedCardName(rescueCard)} cứu sống {victim.GeneralName}!";
                            SetLog(logMsg);
                        }

                        yield return new WaitForSeconds(1.0f);
                        break;
                    }
                }
            }
            else if (!asker.IsAI && !string.IsNullOrEmpty(currentRoomId))
            {
                if (asker.CurrentHp > 0)
                {
                    // Lắng nghe phản hồi Cứu Cận Tử từ người chơi thật từ xa (Chờ tối đa 40s)
                    SetLog($"⏳ Đang đợi <b>{asker.GeneralName}</b> phản ứng cứu viện Cận Tử... (40s)");
                    asker.ShowHeadTimer(40);
                    float waitTimer = 40.0f;
                    bool remoteAnswered = false;
                    bool remoteRescued = false;

                    while (waitTimer > 0f && !remoteAnswered && !battleFinished)
                    {
                        waitTimer -= 0.35f;
                        asker.UpdateHeadTimer(Mathf.Max(0, Mathf.CeilToInt(waitTimer)));

                        yield return AppwriteMatchmaking.PollBattleActions(currentRoomId, (actions) =>
                        {
                            foreach (var act in actions)
                            {
                                if (act.casterSeat == asker.SeatNumber && act.actionType == "RESPONSE_RESCUE" && !processedActionTimestamps.Contains(act.timestamp))
                                {
                                    processedActionTimestamps.Add(act.timestamp);
                                    remoteAnswered = true;
                                    remoteRescued = act.accepted;
                                }
                            }
                        });
                        if (remoteAnswered) break;
                        yield return new WaitForSecondsRealtime(0.35f);
                    }

                    asker.HideHeadTimer();

                    if (remoteRescued)
                    {
                        var rHand = GetHandOfGeneral(asker);
                        if (rHand.Count > 0) rHand.RemoveAt(0);
                        UpdateHandCountsVisual();

                        victim.Heal(1);
                        saved = true;

                        AudioManager.Instance.PlayHeal();
                        SetLog($"💮 <b>{asker.GeneralName}</b> từ xa đã kịp thời dùng bài cứu sống <b>{victim.GeneralName}</b>!");
                        yield return new WaitForSeconds(1.0f);
                        break;
                    }
                }
            }
            else
            {
                if (asker.CurrentHp > 0)
                {
                    var hand = GetHandOfGeneral(asker);
                    var rescueCard = hand.Find(c => (asker == victim && c.subType == CardSubType.Wine) || c.subType == CardSubType.Peach);
                    if (rescueCard != null)
                    {
                        hand.Remove(rescueCard);
                        deckManager.DiscardCard(rescueCard);
                        UpdateHandCountsVisual();

                        victim.Heal(1);
                        saved = true;

                        if (rescueCard.subType == CardSubType.Wine)
                        {
                            ShowCardAtCenter(rescueCard, asker, victim, $"{asker.GeneralName} uống [Hủ Rượu] tự cứu sống");
                            AudioManager.Instance.PlayHeal();
                            SetLog($"🍶 <b>{asker.GeneralName}</b> kịp thời uống [Hủ Rượu] tự cứu sống bản thân!");
                        }
                        else
                        {
                            string rescueDesc = (asker == victim)
                                ? $"{asker.GeneralName} dùng [Bánh Chưng] tự cứu sống"
                                : $"{asker.GeneralName} dùng [Bánh Chưng] cứu sống";
                            ShowCardAtCenter(rescueCard, asker, victim, rescueDesc);
                            AudioManager.Instance.PlayHeal();
                            SetLog($"💮 <b>{asker.GeneralName}</b> kịp thời dùng [Bánh Chưng] cứu sống {victim.GeneralName}!");
                        }

                        yield return new WaitForSeconds(1.0f);

                        // KỸ NĂNG THI SÁCH (ID 3): HỊCH NGHĨA - RÚT 2 LÁ KHI ĐƯỢC CỨU SỐNG TỪ CẬN TỬ
                        if (victim.HeroId == "3" || (!string.IsNullOrEmpty(victim.GeneralName) && victim.GeneralName.Contains("Thi Sách")))
                        {
                            SetLog($"✨ <b>{victim.GeneralName}</b> kích hoạt <color=#FFD700><b>[Hịch Nghĩa]</b></color>: Rút ngay 2 lá bài khi thoát khỏi Cận Tử!");
                            AudioManager.Instance.PlaySkill();
                            for (int d = 0; d < 2; d++)
                            {
                                var extraCard = deckManager.DrawCard();
                                if (extraCard != null)
                                {
                                    yield return AnimateDealtCard(victim);
                                    AddCardsToGeneral(victim, extraCard);
                                }
                            }
                            UpdateHandCountsVisual();
                        }
                        break;
                    }
                }
            }
        }

        if (!saved && victim.CurrentHp <= 0)
        {
            SetLog($"☠️ <color=#FF3333><b>{victim.GeneralName} ĐÃ TỬ TRẬN!</b></color>");
            victim.SetDeadVisual(true);

            // Bỏ toàn bộ bài trên tay của nạn nhân
            var vHand = GetHandOfGeneral(victim);
            while (vHand.Count > 0)
            {
                var c = vHand[0];
                vHand.RemoveAt(0);
                deckManager.DiscardCard(c);
            }
            if (victim == playerCard) playerHandUI.ClearHand();
            UpdateHandCountsVisual();

            // YÊU CẦU 2: Khi đồng minh tử trận được bốc 1 lá
            GeneralCardUI survivingAlly = null;
            if (victim.IsAlly)
            {
                survivingAlly = (victim == playerCard) ? allyCard : playerCard;
            }
            else
            {
                survivingAlly = (victim == enemy1Card) ? enemy2Card : enemy1Card;
            }

            if (survivingAlly != null && survivingAlly.CurrentHp > 0)
            {
                var reinforcementCard = deckManager.DrawCard();
                if (reinforcementCard != null)
                {
                    yield return AnimateDealtCard(survivingAlly);
                    AddCardsToGeneral(survivingAlly, reinforcementCard);
                    UpdateHandCountsVisual();
                    SetLog($"💮 <color=#55FF55><b>[TIẾP VIỆN ĐỒNG MINH]</b></color>: Khi đồng minh <b>{victim.GeneralName}</b> tử trận, <b>{survivingAlly.GeneralName}</b> được rút <b>1 lá bài</b> tiếp viện!");
                }
            }

            CheckGameOver();
        }
    }

    private void ApplyAuthoritativeGameFinished()
    {
        if (battleFinished) return;

        battleFinished = true;
        isPlayerTurnActive = false;
        isTimerRunning = false;
        actionInProgress = false;
        if (endTurnBtn != null) endTurnBtn.gameObject.SetActive(false);
        if (actionBtnGo != null) actionBtnGo.SetActive(false);

        bool ownTeamAlive = false;
        if (playerCard != null && allGenerals != null)
        {
            foreach (var general in allGenerals)
            {
                if (general != null && general.CurrentHp > 0
                    && IsSameTeamSeat(general.SeatNumber, playerCard.SeatNumber))
                {
                    ownTeamAlive = true;
                    break;
                }
            }
        }

        StartCoroutine(ownTeamAlive ? ShowVictoryModal() : ShowDefeatModal());
    }

    private void CheckGameOver()
    {
        bool enemiesDead = enemy1Card.CurrentHp <= 0 && enemy2Card.CurrentHp <= 0;
        bool alliesDead = playerCard.CurrentHp <= 0 && allyCard.CurrentHp <= 0;

        if (enemiesDead)
        {
            battleFinished = true;
            StartCoroutine(ShowVictoryModal());
        }
        else if (alliesDead)
        {
            battleFinished = true;
            StartCoroutine(ShowDefeatModal());
        }
    }

    private IEnumerator ShowVictoryModal()
    {
        yield return new WaitForSeconds(0.8f);
        AudioManager.Instance.PlayVictory();

        AuthUI.Current2v2Points += 25;
        AuthUI.CurrentSilver += 150;
        PlayerPrefs.SetInt("auth_rank2v2_points", AuthUI.Current2v2Points);
        PlayerPrefs.SetInt("auth_silver", AuthUI.CurrentSilver);
        PlayerPrefs.Save();
        StartCoroutine(AuthUI.SaveUserProfileToAppwrite());

        var tier = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        var modal = CreateBaseModal("👑 ĐẠI THẮNG ĐẤU TRƯỜNG 2v2", new Vector2(780f, 480f));
        var txt = AddText(modal.transform, "Content",
            $"<size=22><b>CHÚC MỪNG CHIẾN THẮNG 2v2!</b></size>\n\n" +
            $"Bạn và đồng đội đã xuất sắc phối hợp quét sạch quân địch.\n\n" +
            $"⭐ <b>Điểm Xếp Hạng 2v2:</b> <color=#55FF55>+25 RP</color> (Tổng: {AuthUI.Current2v2Points} RP)\n" +
            $"🏆 <b>Bậc Rank 2v2 Hiện Tại:</b> <color={tier.ColorHex}>{tier.badge} {tier.name}</color> ({tier.subtitle})\n" +
            $"🪙 <b>Chiến Lợi Phẩm:</b> <color=#FFD700>+150 Bạc</color>",
            ThemeUI.SizeBodyLarge, new Color(0.9f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        txt.lineSpacing = 1.35f;
        SetRect(txt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(700f, 240f), new Vector2(0f, 25f));

        var retBtn = CreateButton(modal.transform, "ReturnBtn", "🏠 VỀ TRANG CHỦ", new Vector2(0f, -175f), new Vector2(280f, 52f), () =>
        {
            ConfirmExitBattle();
        });
    }

    private IEnumerator ShowDefeatModal()
    {
        yield return new WaitForSeconds(0.8f);

        AuthUI.Current2v2Points = Mathf.Max(0, AuthUI.Current2v2Points - 15);
        PlayerPrefs.SetInt("auth_rank2v2_points", AuthUI.Current2v2Points);
        PlayerPrefs.Save();
        StartCoroutine(AuthUI.SaveUserProfileToAppwrite());

        var tier = Ranked2v2System.GetTier(AuthUI.Current2v2Points);

        var modal = CreateBaseModal("💔 THẤT BẠI TRẬN CHIẾN", new Vector2(780f, 480f));
        var txt = AddText(modal.transform, "Content",
            $"<size=22><b>TRẬN CHIẾN KẾT THÚC!</b></size>\n\n" +
            $"Cả hai chiến tướng phe ta đã anh dũng ngã xuống.\n\n" +
            $"⭐ <b>Điểm Xếp Hạng 2v2:</b> <color=#FF5555>-15 RP</color> (Hiện tại: {AuthUI.Current2v2Points} RP)\n" +
            $"🏆 <b>Bậc Rank:</b> <color={tier.ColorHex}>{tier.badge} {tier.name}</color>",
            ThemeUI.SizeBodyLarge, new Color(0.9f, 0.95f, 1f, 1f), FontStyle.Normal, TextAnchor.MiddleCenter);
        txt.lineSpacing = 1.35f;
        SetRect(txt.rectTransform, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(700f, 240f), new Vector2(0f, 25f));

        var retBtn = CreateButton(modal.transform, "ReturnBtn", "🏠 VỀ TRANG CHỦ", new Vector2(0f, -175f), new Vector2(280f, 52f), () =>
        {
            ConfirmExitBattle();
        });
    }

    private void ConfirmExitBattle()
    {
        if (isRoomHost && !string.IsNullOrEmpty(currentRoomId))
        {
            AppwriteMatchmaking.Coroutiner.Start(AppwriteMatchmaking.DeleteRoom(currentRoomId));
        }

        var callback = onExitCallback;
        if (Instance == this) Instance = null;

        if (canvasGo != null)
        {
            canvasGo.SetActive(false);
            Destroy(canvasGo);
        }

        Destroy(gameObject);

        if (callback != null)
        {
            callback.Invoke();
        }
        else if (HomeUI.Instance != null)
        {
            HomeUI.Instance.Show();
        }
        else
        {
            if (SceneUtility.GetBuildIndexByScenePath("Assets/Scenes/HomeScene.unity") >= 0 || SceneManager.GetSceneByName("HomeScene").isLoaded)
            {
                SceneManager.LoadScene("HomeScene");
            }
        }
    }
    #endregion

    #region 12. HOẠT CẢNH & ANIMATIONS CHUẨN TUTORIAL
    private IEnumerator AnimateSlashAttack(CardModel card, GeneralCardUI caster, GeneralCardUI target)
    {
        AudioManager.Instance.PlaySlash();
        AudioManager.Instance.PlayCardVoice(card);

        var cardUI = CardUI.Create(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, card, new Vector2(94, 130));
        var rt = cardUI.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);

        Vector2 casterScreen = RectTransformUtility.WorldToScreenPoint(null, caster.transform.position);
        var rootRt = canvasGo.GetComponent<RectTransform>();
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt, casterScreen, null, out var startPos);

        rt.anchoredPosition = startPos;
        cardUI.transform.localScale = Vector3.one * 0.5f;

        float elapsed = 0f;
        const float flyDuration = 0.25f;
        while (elapsed < flyDuration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / flyDuration));
            rt.anchoredPosition = Vector2.Lerp(startPos, new Vector2(-80f, 0f), t);
            cardUI.transform.localScale = Vector3.one * Mathf.Lerp(0.5f, 1f, t);
            yield return null;
        }

        // 🌟 BẮN TIA SÁNG TỪ LÁ TRẢM HƯỚNG ĐẾN TƯỚNG MỤC TIÊU (CHUẨN TUTORIAL)
        if (target != null)
        {
            yield return AnimateAttackBeam(rt, target.GetComponent<RectTransform>(), card);
        }

        yield return new WaitForSeconds(0.2f);
        if (cardUI != null) Destroy(cardUI.gameObject);
    }

    
    private IEnumerator ShowFloatingDamage(GeneralCardUI target, int damage)
    {
        if (target == null) yield break;
        var go = new GameObject("FloatingDmg", typeof(RectTransform), typeof(UnityEngine.UI.Text));
        go.transform.SetParent(target.transform, false);
        var t = go.GetComponent<UnityEngine.UI.Text>();
        t.font = ThemeUI.FontMain;
        t.fontSize = 64;
        t.fontStyle = FontStyle.Bold;
        t.color = Color.red;
        t.text = $"-{damage}";
        t.alignment = TextAnchor.MiddleCenter;
        
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.anchoredPosition = new Vector2(0, 0);

        float elapsed = 0f;
        float duration = 1.0f;
        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            rt.anchoredPosition += new Vector2(0, 60f * Time.deltaTime);
            t.color = new Color(1f, 0f, 0f, 1f - (elapsed / duration));
            yield return null;
        }
        Destroy(go);
    }

    private IEnumerator ShakeCard(GeneralCardUI target)
    {
        if (target == null) yield break;
        var rt = target.GetComponent<RectTransform>();
        Vector2 originalPos = rt.anchoredPosition;

        float elapsed = 0f;
        const float duration = 0.35f;
        const float magnitude = 7f;

        while (elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float xOffset = UnityEngine.Random.Range(-magnitude, magnitude);
            float yOffset = UnityEngine.Random.Range(-magnitude, magnitude);
            rt.anchoredPosition = originalPos + new Vector2(xOffset, yOffset);
            yield return null;
        }

        rt.anchoredPosition = originalPos;
    }

    
    private string GetFormattedCardName(CardModel card)
    {
        if (card == null) return "[]";
        if ((int)card.suit == 0 && (int)card.rank == 0) return $"[{card.cardName}]";
        string colorTag = card.IsRed ? "<color=#FF5555>" : "<color=#BBBBBB>";
        return $"[{card.cardName} ({colorTag}{card.GetSuitSymbol()}</color> {card.GetRankString()})]";
    }

public void ShowCardAtCenter(CardModel card, GeneralCardUI caster, GeneralCardUI target = null, string customLabel = null)
    {
        if (card == null) return;
        AudioManager.Instance.PlayCardVoice(card);

        if (card.category == CardCategory.Basic)
        {
            if (card.subType == CardSubType.AttackNormal || card.subType == CardSubType.AttackFire || card.subType == CardSubType.AttackThunder)
                AudioManager.Instance.PlaySlash();
            else if (card.subType == CardSubType.Dodge)
                AudioManager.Instance.PlayParry();
            else if (card.subType == CardSubType.Peach)
                AudioManager.Instance.PlayHeal();
            else if (card.subType == CardSubType.Wine)
                AudioManager.Instance.PlaySkill();
        }
        else if (card.category == CardCategory.InstantScroll || card.category == CardCategory.DelayedScroll || card.category == CardCategory.Equipment)
        {
            AudioManager.Instance.PlaySkill();
        }

        if (centerCardDismissCoroutine != null)
        {
            StopCoroutine(centerCardDismissCoroutine);
            centerCardDismissCoroutine = null;
        }

        if (currentCenterCardGo != null)
        {
            Destroy(currentCenterCardGo);
            currentCenterCardGo = null;
        }

        var centerContainer = new GameObject("CenterPlayedCard", typeof(RectTransform), typeof(CanvasGroup));
        centerContainer.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        centerContainer.transform.SetAsLastSibling();

        var rt = centerContainer.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(94, 130);
        
        // Hoạt cảnh pop out lá bài từ người đánh ra (hoặc từ tâm màn hình)
        Vector2 startPos = new Vector2(-80f, 0f);
        if (caster != null)
        {
            var casterRt = caster.GetComponent<RectTransform>();
            Vector2 casterScreen = RectTransformUtility.WorldToScreenPoint(null, casterRt.position);
            RectTransformUtility.ScreenPointToLocalPointInRectangle(battleRootGo != null ? battleRootGo.GetComponent<RectTransform>() : canvasGo.GetComponent<RectTransform>(), casterScreen, null, out startPos);
        }
        
        rt.anchoredPosition = startPos;
        rt.localScale = Vector3.one * 0.1f;
        StartCoroutine(PopOutCard(rt, startPos, new Vector2(-80f, 0f), 1f));
        if (target != null)
        {
            StartCoroutine(AnimateAttackBeam(rt, target.GetComponent<RectTransform>(), card));
        }

        currentCenterCardGo = centerContainer;

        var cardUI = CardUI.Create(centerContainer.transform, card, new Vector2(94, 130));
        var cardRt = cardUI.GetComponent<RectTransform>();
        cardRt.anchorMin = Vector2.zero; cardRt.anchorMax = Vector2.one;
        cardRt.offsetMin = cardRt.offsetMax = Vector2.zero;

        var haloGo = new GameObject("CenterGlow", typeof(RectTransform), typeof(Image));
        haloGo.transform.SetParent(centerContainer.transform, false);
        haloGo.transform.SetAsFirstSibling();
        var haloImg = haloGo.GetComponent<Image>();
        haloImg.sprite = LotusHealthUI.LoadSpriteFromResources("UI/lotus_halo");
        haloImg.color = new Color(1f, 0.88f, 0.35f, 0.9f);
        haloImg.raycastTarget = false;
        var hRt = haloGo.GetComponent<RectTransform>();
        Fill(hRt, new Vector2(-12, -12), new Vector2(12, 12));

        if (!string.IsNullOrEmpty(customLabel))
        {
            var labelBoxGo = new GameObject("LabelBox", typeof(RectTransform), typeof(Image));
            labelBoxGo.transform.SetParent(centerContainer.transform, false);
            var lbImg = labelBoxGo.GetComponent<Image>();
            var slotSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (slotSpr != null) { lbImg.sprite = slotSpr; lbImg.type = Image.Type.Sliced; }
            lbImg.color = new Color(0.04f, 0.07f, 0.14f, 0.95f);
            var lbRt = labelBoxGo.GetComponent<RectTransform>();
            SetRect(lbRt, new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(0.5f, 0f), new Vector2(180f, 22f), new Vector2(0f, -26f));

            var lbl = AddText(labelBoxGo.transform, "Txt", customLabel, 10, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(lbl.rectTransform);
        }

        // 🌟 TIA SÁNG TỪ LÁ BÀI ĐI ĐẾN MỤC TIÊU (giống Tutorial)
        if (target != null)
        {
            StartCoroutine(AnimateAttackBeam(rt, target.GetComponent<RectTransform>(), card));
        }

        centerCardDismissCoroutine = StartCoroutine(DismissCenterCardAfterDelay(centerContainer, 2.0f));
    }

    /// <summary>
    /// Vẽ tia sáng từ lá bài ở giữa đi đến mục tiêu rồi mờ dần (giống Tutorial).
    /// Màu tia thay đổi theo loại lá bài: Vàng (Trảm), Xanh (Đỡ), Đỏ (Thách Đấu), Xanh Lá (Hồi Máu).
    /// </summary>
    
    private IEnumerator ShowResponseCardAnimation(CardModel card, Vector2 startPos)
    {
        var container = new GameObject("ResponseCardAnim", typeof(RectTransform));
        container.transform.SetParent(battleRootGo != null ? battleRootGo.transform : canvasGo.transform, false);
        container.transform.SetAsLastSibling();
        
        var rt = container.GetComponent<RectTransform>();
        rt.anchorMin = rt.anchorMax = rt.pivot = new Vector2(0.5f, 0.5f);
        rt.sizeDelta = new Vector2(94, 130);
        rt.anchoredPosition = startPos;
        rt.localScale = Vector3.one * 0.1f;
        
        // Render card
        var cardUI = CardUI.Create(container.transform, card, new Vector2(94, 130));
        var cardRt = cardUI.GetComponent<RectTransform>();
        cardRt.anchorMin = Vector2.zero; cardRt.anchorMax = Vector2.one;
        cardRt.offsetMin = cardRt.offsetMax = Vector2.zero;
        
        AudioManager.Instance.PlayCardSelect();
        
        // Pop out ra giữa màn hình
        yield return PopOutCard(rt, startPos, new Vector2(80f, 0f), 1f);
        
        // Dừng 1 giây để user đọc
        yield return new WaitForSeconds(1.0f);
        
        // Mờ dần rồi xoá
        var cg = container.AddComponent<CanvasGroup>();
        float elapsed = 0f;
        while (elapsed < 0.3f && container != null)
        {
            elapsed += Time.deltaTime;
            cg.alpha = 1f - (elapsed / 0.3f);
            yield return null;
        }
        
        if (container != null) Destroy(container);
    }

    private IEnumerator PopOutCard(RectTransform rt, Vector2 start, Vector2 end, float targetScale = 1f)
    {
        float elapsed = 0f;
        const float duration = 0.25f;
        while (elapsed < duration && rt != null)
        {
            elapsed += Time.deltaTime;
            float t = elapsed / duration;
            // Easing out overshoot
            float ease = --t * t * ((1.70158f + 1f) * t + 1.70158f) + 1f;
            
            rt.anchoredPosition = Vector2.Lerp(start, end, ease);
            rt.localScale = Vector3.one * Mathf.Lerp(0.1f, targetScale, ease);
            yield return null;
        }
        if (rt != null)
        {
            rt.anchoredPosition = end;
            rt.localScale = Vector3.one * targetScale;
        }
    }

    private IEnumerator AnimateAttackBeam(RectTransform source, RectTransform target, CardModel card = null)
    {
        if (source == null || target == null) yield break;

        var beamGo = new GameObject("CardAttackBeam", typeof(RectTransform), typeof(Image));
        var beamRoot = battleRootGo != null ? battleRootGo.transform : canvasGo.transform;
        beamGo.transform.SetParent(beamRoot, false);
        beamGo.transform.SetAsLastSibling();

        var beam = beamGo.GetComponent<Image>();
        var arrowSpr = ThemeUI.LoadSprite("UI/tutorial_arrow");
        if (arrowSpr != null) { beam.sprite = arrowSpr; beam.type = Image.Type.Sliced; }
        beam.raycastTarget = false;

        // Màu tia theo loại lá bài
        Color beamColor = card != null ? card.subType switch
        {
            CardSubType.Dodge             => new Color(0.35f, 0.85f, 1f,    0.95f), // Xanh lam - Đỡ
            CardSubType.Peach             => new Color(0.35f, 1f,    0.55f, 0.95f), // Xanh lá  - Bánh Chưng
            CardSubType.Duel              => new Color(1f,    0.25f, 0.25f, 0.95f), // Đỏ        - Thách Đấu
            CardSubType.FlawlessDefense   => new Color(0.55f, 0.35f, 1f,    0.95f), // Tím       - Diệu Kế
            CardSubType.Snatch            => new Color(1f,    0.65f, 0.2f,  0.95f), // Cam       - Đột Kích
            CardSubType.Dismantle         => new Color(1f,    0.4f,  0.4f,  0.95f), // Đỏ nhạt  - Vườn Không
            CardSubType.ArrowRain         => new Color(0.9f,  0.55f, 0.1f,  0.95f), // Cam đậm  - Mưa Tên
            CardSubType.BarbarianInvasion => new Color(0.9f,  0.3f,  0.1f,  0.95f), // Đỏ cam   - Bãi Cọc
            CardSubType.AttackFire        => new Color(1f,    0.4f,  0.1f,  0.95f), // Cam lửa  - Hỏa Trảm
            CardSubType.AttackThunder     => new Color(0.7f,  0.4f,  1f,    0.95f), // Tím điện - Lôi Trảm
            _                             => new Color(1f,    0.78f, 0.18f, 0.95f)  // Vàng HK  - mặc định
        } : new Color(1f, 0.78f, 0.18f, 0.95f);

        beam.color = beamColor;

        var beamRt = beamGo.GetComponent<RectTransform>();
        beamRt.anchorMin = beamRt.anchorMax = new Vector2(0.5f, 0.5f);
        beamRt.pivot = new Vector2(0f, 0.5f);

        var rootRt = beamRoot.GetComponent<RectTransform>();

        // Điểm xuất phát: tâm lá bài ở giữa màn hình
        Vector3 sourceWorld = source.position;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt,
            RectTransformUtility.WorldToScreenPoint(null, sourceWorld), null, out var start);

        // Điểm đến: avatar của mục tiêu (offset 18% chiều cao từ dưới lên)
        var targetAvatar = target.transform.Find("Avatar") as RectTransform;
        Vector3 targetWorld = target.position;
        if (targetAvatar != null)
            targetWorld = targetAvatar.TransformPoint(new Vector3(0f, targetAvatar.rect.height * 0.18f, 0f));
        RectTransformUtility.ScreenPointToLocalPointInRectangle(rootRt,
            RectTransformUtility.WorldToScreenPoint(null, targetWorld), null, out var end);

        Vector2 delta = end - start;
        beamRt.anchoredPosition = start;
        beamRt.sizeDelta = new Vector2(0f, 30f);
        beamRt.localRotation = Quaternion.Euler(0f, 0f, Mathf.Atan2(delta.y, delta.x) * Mathf.Rad2Deg);

        // Tia sáng vươn dài từ 0 đến độ dài đầy đủ trong 0.22s
        float elapsed = 0f;
        const float duration = 0.22f;
        while (elapsed < duration && beamRt != null)
        {
            elapsed += Time.deltaTime;
            beamRt.sizeDelta = new Vector2(delta.magnitude * Mathf.Clamp01(elapsed / duration), 30f);
            yield return null;
        }

        // Giữ hiện thêm 0.12s
        yield return new WaitForSeconds(0.12f);

        // Mờ dần trong 0.15s
        float fadeElapsed = 0f;
        const float fadeDur = 0.15f;
        while (fadeElapsed < fadeDur && beam != null)
        {
            fadeElapsed += Time.deltaTime;
            var c = beamColor;
            c.a = Mathf.Lerp(0.95f, 0f, fadeElapsed / fadeDur);
            beam.color = c;
            yield return null;
        }

        if (beamGo != null) Destroy(beamGo);
    }

    private IEnumerator DismissCenterCardAfterDelay(GameObject cardGo, float delay)
    {
        yield return new WaitForSeconds(delay);
        if (cardGo != null) Destroy(cardGo);
    }

    private void OnGeneralTargetClicked(GeneralCardUI clicked)
    {
        if (clicked == null || clicked.CurrentHp <= 0) return;
        if (playerCard != null && clicked != playerCard
            && IsSameTeamSeat(playerCard.SeatNumber, clicked.SeatNumber)
            && currentSelectedCardUI != null
            && RequiresTarget(currentSelectedCardUI.Data))
        {
            SetLog("🎯 Chỉ được chọn tướng đối phương làm mục tiêu.");
            ClearSelectedTarget();
            UpdateActionButtonState();
            return;
        }
        currentSelectedTarget = clicked;
        AudioManager.Instance.PlayCardSelect();

        // Kích hoạt Triều Dâng luôn nếu đang bật mode
        if (isWaitingForTrieuDangTarget) {
            isWaitingForTrieuDangTarget = false;
            OnPlayerSkillTrieuDangClicked();
            return;
        }

        if (targetHighlightGo == null)
        {
            targetHighlightGo = new GameObject("TargetHighlight", typeof(RectTransform), typeof(Image));
            var tImg = targetHighlightGo.GetComponent<Image>();
            var spr = LotusHealthUI.LoadSpriteFromResources("UI/card_frame");
            if (spr != null) { tImg.sprite = spr; tImg.type = Image.Type.Sliced; }
            tImg.color = new Color(1f, 0.95f, 0.15f, 1f);
            tImg.raycastTarget = false;

            var tagGo = new GameObject("TargetTag", typeof(RectTransform), typeof(Image));
            tagGo.transform.SetParent(targetHighlightGo.transform, false);
            var tgImg = tagGo.GetComponent<Image>();
            var sSpr = LotusHealthUI.LoadSpriteFromResources("UI/slot_bg");
            if (sSpr != null) { tgImg.sprite = sSpr; tgImg.type = Image.Type.Sliced; }
            tgImg.color = new Color(0.85f, 0.2f, 0.2f, 0.98f);
            var tgRt = tagGo.GetComponent<RectTransform>();
            SetRect(tgRt, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(140f, 22f), new Vector2(0f, 14f));

            var tagTxt = AddText(tagGo.transform, "Txt", "🎯 MỤC TIÊU ĐANG CHỌN", 9, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
            Fill(tagTxt.rectTransform);
        }

        targetHighlightGo.transform.SetParent(clicked.transform, false);
        targetHighlightGo.transform.SetAsLastSibling();
        var hRt = targetHighlightGo.GetComponent<RectTransform>();
        hRt.anchorMin = Vector2.zero; hRt.anchorMax = Vector2.one;
        hRt.offsetMin = new Vector2(-8, -8); hRt.offsetMax = new Vector2(8, 8);
        targetHighlightGo.SetActive(true);

        SetLog($"🎯 Đã chọn mục tiêu: <b>{clicked.GeneralName}</b> ({clicked.FactionName}) - Cự ly từ bạn: <b>{CalculateDistance(playerCard, clicked)}</b>");
        UpdateActionButtonState();
    }

    private void OnPlayerSkillClicked()
    {
        return;
    }

    private void OnPlayerSkillCheNoClicked()
    {
        if (playerCard == null) return;

        bool currentActive = playerCard.IsSkillActive("Chế Nỏ");
        bool nextActive = !currentActive;

        if (playerCard.ActiveSkillsKeys == null) {
            playerCard.ActiveSkillsKeys = new string[] { "Chế Nỏ" };
            playerCard.ActiveSkillsValues = new bool[] { nextActive };
        } else {
            bool found = false;
            for (int i = 0; i < playerCard.ActiveSkillsKeys.Length; i++) {
                if (playerCard.ActiveSkillsKeys[i] == "Chế Nỏ") {
                    playerCard.ActiveSkillsValues[i] = nextActive;
                    found = true;
                    break;
                }
            }
            if (!found) {
                var kList = new List<string>(playerCard.ActiveSkillsKeys) { "Chế Nỏ" };
                var vList = new List<bool>(playerCard.ActiveSkillsValues) { nextActive };
                playerCard.ActiveSkillsKeys = kList.ToArray();
                playerCard.ActiveSkillsValues = vList.ToArray();
            }
        }

        UpdatePlayerSkillButtonState();
        if (nextActive) {
            SetLog("🏹 <color=#FFD700><b>[Chế Nỏ] KÍCH HOẠT</b></color>: Mọi lá bài chất Bích (♠) trên tay bạn có thể dùng như lá trang bị [Nỏ Thần Kim Quy]!");
            AudioManager.Instance.PlaySkill();
        } else {
            SetLog("🏹 <color=#8899AA><b>[Chế Nỏ] ĐÃ TẮT</b></color>.");
        }

        if (!string.IsNullOrEmpty(currentRoomId))
        {
            DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
            {
                action = "TOGGLE_SKILL",
                roomId = currentRoomId,
                seat = playerCard.SeatNumber,
                skillId = "Chế Nỏ"
            }, (s) => { if (s != null) ApplyServerGameState(s); });
        }
    }

    void OnPlayerSkillTrieuDangClicked()
    {
        if (playerCard == null) return;

        bool hasUsed = playerCard.HasUsedSkill("Triều Dâng");
        if (hasUsed)
        {
            SetLog("⚠️ Kỹ năng [Triều Dâng] mỗi lượt chỉ được sử dụng 1 lần.");
            return;
        }

        // Tìm tất cả các tướng đang có trang bị
        List<GeneralCardUI> targetsWithEquip = new List<GeneralCardUI>();
        foreach (var g in new GeneralCardUI[] { enemy1Card, enemy2Card, allyCard })
        {
            if (g != null && g.CurrentHp > 0 && g.HasAnyEquipment())
            {
                targetsWithEquip.Add(g);
            }
        }

        if (targetsWithEquip.Count == 0)
        {
            SetLog("⚠️ Không có người chơi nào khác trên bàn đang mang trang bị để kích hoạt [Triều Dâng].");
            return;
        }

        if (currentSelectedTarget == null || !targetsWithEquip.Contains(currentSelectedTarget))
        {
            isWaitingForTrieuDangTarget = true;
            SetLog("🌊 <color=#55DDFF><b>[Triều Dâng]</b></color>: Hãy chạm chọn 1 tướng có trang bị trên bàn đấu để phá hủy trang bị!");
            return;
        }

        ExecuteTrieuDangOnTarget(currentSelectedTarget);
    }

    private void ExecuteTrieuDangOnTarget(GeneralCardUI target)
    {
        if (target == null) return;
        if (!target.HasAnyEquipment())
        {
            SetLog($"⚠️ Tướng <b>{target.GeneralName}</b> không mang trang bị nào!");
            return;
        }

        ShowCardStealOrDestroyModal(target, false, "🌊 TRIỀU DÂNG: CHỌN 1 TRANG BỊ ĐỂ HỦY", (discarded) =>
        {
            if (discarded != null)
            {
                SetLog($"🌊 <color=#55DDFF><b>[Triều Dâng]</b></color>: Bạn đã phá hủy trang bị {GetFormattedCardName(discarded)} của <b>{target.GeneralName}</b>!");
                AudioManager.Instance.PlaySkill();

                // Đánh dấu đã dùng skill
                if (playerCard.UsedSkillsKeys == null) {
                    playerCard.UsedSkillsKeys = new string[] { "Triều Dâng" };
                    playerCard.UsedSkillsValues = new bool[] { true };
                } else {
                    bool found = false;
                    for (int i = 0; i < playerCard.UsedSkillsKeys.Length; i++) {
                        if (playerCard.UsedSkillsKeys[i] == "Triều Dâng") {
                            playerCard.UsedSkillsValues[i] = true;
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        var kList = new List<string>(playerCard.UsedSkillsKeys) { "Triều Dâng" };
                        var vList = new List<bool>(playerCard.UsedSkillsValues) { true };
                        playerCard.UsedSkillsKeys = kList.ToArray();
                        playerCard.UsedSkillsValues = vList.ToArray();
                    }
                }
                UpdatePlayerSkillButtonState();

                if (!string.IsNullOrEmpty(currentRoomId))
                {
                    DispatchGameEngineAction(new AppwriteMatchmaking.GameActionPayload
                    {
                        action = "USE_SKILL",
                        roomId = currentRoomId,
                        seat = playerCard.SeatNumber,
                        skillId = "Triều Dâng",
                        targetSeat = target.SeatNumber,
                        cardId = discarded.id
                    }, (s) => { if (s != null) ApplyServerGameState(s); });
                }
            }
        });
    }

    private void OnPlayerSkillTienThoaiClicked()
    {
        return;
    }

    private void SetLog(string msg)
    {
        if (string.IsNullOrEmpty(msg)) return;

        battleLogHistory.Add(msg);
        if (battleLogHistory.Count > 60)
        {
            battleLogHistory.RemoveAt(0);
        }

        if (historyContentText != null)
        {
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < battleLogHistory.Count; i++)
            {
                if (i > 0) sb.AppendLine();
                bool isLatest = (i == battleLogHistory.Count - 1);
                if (isLatest)
                {
                    sb.Append("<color=#FFD700><b>[").Append(i + 1).Append("]</b></color> <color=#FFFFFF>▶ ").Append(battleLogHistory[i]).Append("</color>");
                }
                else
                {
                    sb.Append("<color=#64748B>[").Append(i + 1).Append("]</color> <color=#CBD5E1>• ").Append(battleLogHistory[i]).Append("</color>");
                }
            }
            historyContentText.text = sb.ToString();
        }
    }

    private List<CardModel> GetHandOfGeneral(GeneralCardUI g)
    {
        if (g == playerCard) return playerHandCards;
        if (g == allyCard) return allyHandCards;
        if (g == enemy1Card) return enemy1HandCards;
        return enemy2HandCards;
    }

    private int GetHandCountOf(GeneralCardUI g)
    {
        return GetHandOfGeneral(g).Count;
    }

    private bool CanActAsSlash(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        return IsSlashCard(c);
    }

    private bool CanActAsDodge(GeneralCardUI g, CardModel c)
    {
        if (c == null) return false;
        return c.subType == CardSubType.Dodge;
    }

    private static bool IsSlashCard(CardModel c)
    {
        return c != null && (c.subType == CardSubType.AttackNormal || c.subType == CardSubType.AttackThunder || c.subType == CardSubType.AttackFire);
    }

    private bool RequiresTarget(CardModel c)
    {
        if (c == null) return false;
        return CanActAsSlash(playerCard, c) || c.subType == CardSubType.Duel || c.subType == CardSubType.Snatch || c.subType == CardSubType.Dismantle || c.subType == CardSubType.SupplyShortage || c.subType == CardSubType.Acedia;
    }

    private GameObject CreateBaseModal(string title, Vector2 size)
    {
        var modalRoot = new GameObject("Modal_" + title, typeof(RectTransform), typeof(Image));
        modalRoot.transform.SetParent(canvasGo.transform, false);
        modalRoot.transform.SetAsLastSibling();

        var bgImg = modalRoot.GetComponent<Image>();
        bgImg.color = new Color(0.02f, 0.04f, 0.08f, 0.85f);
        Fill(modalRoot.GetComponent<RectTransform>());

        var boxGo = new GameObject("Box", typeof(RectTransform), typeof(Image));
        boxGo.transform.SetParent(modalRoot.transform, false);
        var bImg = boxGo.GetComponent<Image>();
        var bgSprite = LotusHealthUI.LoadSpriteFromResources("UI/auth_card_bg");
        if (bgSprite != null) { bImg.sprite = bgSprite; bImg.type = Image.Type.Sliced; }
        bImg.color = new Color(0.08f, 0.12f, 0.22f, 0.98f);

        var boxRt = boxGo.GetComponent<RectTransform>();
        boxRt.anchorMin = boxRt.anchorMax = boxRt.pivot = new Vector2(0.5f, 0.5f);
        boxRt.sizeDelta = size;
        boxRt.anchoredPosition = Vector2.zero;

        var titleTxt = AddText(boxGo.transform, "Title", title, 16, new Color(1f, 0.88f, 0.35f, 1f), FontStyle.Bold, TextAnchor.MiddleCenter);
        SetRect(titleTxt.rectTransform, new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(0.5f, 1f), new Vector2(size.x - 40f, 36f), new Vector2(0, -14));

        return boxGo;
    }

    private Button CreateButton(Transform parent, string name, string label, Vector2 pos, Vector2 size, Action onClick)
    {
        var btnGo = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
        btnGo.transform.SetParent(parent, false);
        var img = btnGo.GetComponent<Image>();
        var btnSpr = LotusHealthUI.LoadSpriteFromResources("UI/btn_gold");
        if (btnSpr != null) { img.sprite = btnSpr; img.type = Image.Type.Sliced; }
        img.color = new Color(0.9f, 0.65f, 0.15f, 1f);

        var rt = btnGo.GetComponent<RectTransform>();
        SetRect(rt, new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), new Vector2(0.5f, 0.5f), size, pos);

        var txt = AddText(btnGo.transform, "Txt", label, 12, Color.white, FontStyle.Bold, TextAnchor.MiddleCenter);
        Fill(txt.rectTransform);

        var btn = btnGo.GetComponent<Button>();
        btn.onClick.AddListener(() =>
        {
            AudioManager.Instance.PlayCardSelect();
            onClick?.Invoke();
        });
        return btn;
    }

    private Text AddText(Transform parent, string name, string content, int fontSize, Color color, FontStyle style, TextAnchor align)
    {
        int scaledSize = Mathf.Max(ThemeUI.SizeMicro, fontSize);
        var t = ThemeUI.CreateText(parent, name, content, scaledSize, color, style, align, true);
        return t;
    }

    private static void Fill(RectTransform rt, Vector2? minOffset = null, Vector2? maxOffset = null)
    {
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.pivot = new Vector2(0.5f, 0.5f);
        rt.offsetMin = minOffset ?? Vector2.zero;
        rt.offsetMax = maxOffset ?? Vector2.zero;
    }

    private static void SetRect(RectTransform rt, Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 size, Vector2 pos)
    {
        rt.anchorMin = aMin;
        rt.anchorMax = aMax;
        rt.pivot = pivot;
        rt.sizeDelta = size;
        rt.anchoredPosition = pos;
    }
    #endregion
}











































