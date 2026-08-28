using System;
using System.Collections.Generic;
using UnityEngine;

// Data Models matching Deno Server's sanitizeGameStateForClient
[Serializable]
public class CardData {
    public string id;
    public string name;
    public string suit;
    public int rank;
    public int category;
    public int subType;
    public string desc;
    // The authoritative server calls this field `attackRange` in a player's
    // hand, while older REST payloads used `range`. Keep both wire names so
    // this lightweight client can consume either protocol version.
    public int attackRange;
    public int range;
    public int distMod;
}

[Serializable]
public class PlayerData {
    public int seat;
    public string userId;
    public string heroId;
    public string generalName;
    public int maxHp;
    public int hp;
    public bool isAlly;
    public bool isAI;
    public bool isWineBuffActive;
    public int handCount;
    public List<CardData> hand = new List<CardData>();
    public List<CardData> equipments = new List<CardData>();
    public List<CardData> judgements = new List<CardData>();
    public List<string> skills = new List<string>();
}

[Serializable]
public class ActionData {
    public int seq;
    public string type;
    public int casterSeat;
    public int targetSeat;
    public string cardId;
    public string cardName;
    public int damage;
    public bool isWineBuff;
    public string description;
    public long timestamp;
}

[Serializable]
public class ActiveCardData {
    public string cardId;
    public string cardName;
    public int casterSeat;
    public int targetSeat;
    public int damage;
    public bool isWineBuff;
    public string reqType;
    public string reqName;
}

[Serializable]
public class NullifyChainData {
    public CardData rootCard;
    public int casterSeat;
    public int targetSeat;
    public bool isCanceled;
    public List<int> querySeats = new List<int>();
    public int currentIdx;
    public int whoUsedLast;
}

[Serializable]
public class GameStateDelta {
    public int version;
    public int actionSeq;
    public string type;
    public string description;
    public int turnSeat;
    public string phase;
    public int waitingTargetSeat;
    public string waitingReactionType;
    public int waitingTimer;
    public ActiveCardData activeCard;
    public int deckCount;
    public int discardCount;
    public CardData discardTop;
    public string status;
    public List<CardData> harvestPool = new List<CardData>();
    public NullifyChainData nullifyChain;
    public List<PlayerDataDelta> playerDeltas = new List<PlayerDataDelta>();
}

[Serializable]
public class PlayerDataDelta {
    public int seat;
    public int hp;
    public int maxHp;
    public int handCount;
    public bool isWineBuffActive;
    public List<CardData> equipments = new List<CardData>();
}

[Serializable]
public class GameStateData {
    public int version;
    public string roomId;
    public string status;
    public int turnSeat;
    public string phase;
    public int turnTimer;
    public int waitingTargetSeat;
    public string waitingReactionType;
    public int waitingTimer;
    public ActiveCardData activeCard;
    public List<CardData> harvestPool = new List<CardData>();
    public NullifyChainData nullifyChain;
    public ActionData lastAction;
    public List<ActionData> actionHistory = new List<ActionData>();
    public CardData discardTop;
    public int deckCount;
    public int discardCount;
    public List<PlayerData> players = new List<PlayerData>();
    public GameStateDelta delta;
}

[Serializable]
public class ServerMessage {
    public string type; // STATE_SNAPSHOT, STATE_UPDATE, ACTION_REJECTED, ERROR, CONFLICT, PLAYER_JOINED, PONG
    public GameStateData state;
    public GameStateDelta delta;
    public string error;
    public string code;
    public string action;
    public int seat;
    public int version;
}

public class GameStateManager : MonoBehaviour {
    public static GameStateManager Instance;

    public GameStateData CurrentState { get; private set; }
    private int _lastAppliedVersion = -1;
    
    public event Action<GameStateData> OnStateChanged;
    public event Action<string> OnError;
    public event Action<string> OnActionRejected;

    private void Awake() {
        if (Instance == null) {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        } else {
            Destroy(gameObject);
        }
    }

    private void OnEnable() {
        SubscribeToSocket();
    }

    private void Start() {
        // WebSocketManager may be instantiated by another scene object after
        // OnEnable; retry once on Start so the first snapshot is not missed.
        SubscribeToSocket();
    }

    private void SubscribeToSocket() {
        if (WebSocketManager.Instance != null) {
            WebSocketManager.Instance.OnMessageReceived -= HandleMessage;
            WebSocketManager.Instance.OnMessageReceived += HandleMessage;
        }
    }

    private void OnDisable() {
        if (WebSocketManager.Instance != null) {
            WebSocketManager.Instance.OnMessageReceived -= HandleMessage;
        }
    }

    private void HandleMessage(string json) {
        try {
            // Using Unity's built-in JsonUtility. For production, Newtonsoft.Json is recommended for complex dictionaries.
            ServerMessage msg = JsonUtility.FromJson<ServerMessage>(json);
            
            if (msg == null) return;

            if (msg.type == "STATE_SNAPSHOT" || msg.type == "STATE_UPDATE" || msg.type == "CONFLICT" || msg.type == "ACTION_REJECTED") {
                if (msg.state != null && ShouldApplyState(msg.state)) {
                    // The server carries the delta both at the envelope level
                    // and, for some REST snapshots, nested in `state`.
                    if (msg.delta != null) msg.state.delta = msg.delta;
                    CurrentState = msg.state;
                    _lastAppliedVersion = msg.state.version;
                    OnStateChanged?.Invoke(CurrentState);
                    Debug.Log($"[GameState] Updated to Phase: {CurrentState.phase} | Turn: {CurrentState.turnSeat}");
                }
            }

            if (msg.type == "ACTION_REJECTED") {
                OnActionRejected?.Invoke(msg.error);
                Debug.LogWarning($"[GameState] Action Rejected: {msg.error}");
            }
            else if (msg.type == "CONFLICT") {
                OnError?.Invoke(msg.error);
                Debug.LogWarning($"[GameState] Version conflict: {msg.error}");
            }
            else if (msg.type == "ERROR") {
                OnError?.Invoke(msg.error);
                Debug.LogError($"[GameState] Server Error: {msg.error}");
            }
        } catch (Exception e) {
            Debug.LogError($"[GameState] Failed to parse JSON: {e.Message}\nRaw: {json}");
        }
    }

    private bool ShouldApplyState(GameStateData incoming) {
        if (incoming == null) return false;
        // A reconnect can switch rooms; versions are only comparable within
        // one room. Otherwise reject delayed packets that would roll the UI
        // back to an older authoritative snapshot.
        if (CurrentState == null || !string.Equals(CurrentState.roomId, incoming.roomId, StringComparison.Ordinal)) {
            return true;
        }
        return incoming.version >= _lastAppliedVersion;
    }

    public PlayerData GetMyPlayer(int mySeat) {
        if (CurrentState == null || CurrentState.players == null) return null;
        return CurrentState.players.Find(p => p.seat == mySeat);
    }
}
