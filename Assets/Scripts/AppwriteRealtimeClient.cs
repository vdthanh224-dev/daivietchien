using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class AppwriteRealtimeClient : MonoBehaviour
{
    private const string WsEndpoint = "wss://sgp.cloud.appwrite.io/v1/realtime?project=6a885457002da3f3d47e&channels[]=databases.game.collections.matchmaking_queue.documents";
    
    public static AppwriteRealtimeClient Instance { get; private set; }

    public static bool IsConnected => Instance != null && Instance.wsClient != null && Instance.wsClient.State == WebSocketState.Open;

    public static event Action<AppwriteMatchmaking.BattleActionPacket> OnBattleActionReceived;
    public static event Action<AppwriteMatchmaking.DraftPlayerActionPacket> OnDraftPlayerActionReceived;
    public static event Action<AppwriteMatchmaking.DraftHostStatePacket> OnDraftHostStateReceived;
    public static event Action<AppwriteMatchmaking.RoomStatePacket> OnRoomStateReceived;
    public static event Action<AppwriteMatchmaking.ServerGameState> OnServerGameStateReceived;
    public static event Action<bool> OnConnectionStateChanged;

    private ClientWebSocket wsClient;
    private CancellationTokenSource cts;
    private readonly ConcurrentQueue<Action> mainThreadQueue = new ConcurrentQueue<Action>();
    private bool isRunning = false;
    private float reconnectDelay = 2.0f;
    private float lastHeartbeatTime = 0f;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void AutoInitialize()
    {
        if (Instance == null)
        {
            var go = new GameObject("AppwriteRealtimeClient");
            DontDestroyOnLoad(go);
            Instance = go.AddComponent<AppwriteRealtimeClient>();
        }
    }

    private void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private void Start() => StartClient();

    public void StartClient()
    {
        if (isRunning) return;
        isRunning = true;
        cts = new CancellationTokenSource();
        Task.Run(() => ConnectAndReceiveLoop(cts.Token));
    }

    public void StopClient()
    {
        isRunning = false;
        try { cts?.Cancel(); wsClient?.Abort(); wsClient?.Dispose(); wsClient = null; } catch { }
    }

    private void Update()
    {
        while (mainThreadQueue.TryDequeue(out var action))
        {
            try { action?.Invoke(); } catch (Exception ex) { Debug.LogWarning($"[AppwriteRealtime] MainThread: {ex.Message}"); }
        }
        if (IsConnected && Time.unscaledTime - lastHeartbeatTime > 20.0f)
        {
            lastHeartbeatTime = Time.unscaledTime;
            SendPingAsync();
        }
    }

    private async Task ConnectAndReceiveLoop(CancellationToken token)
    {
        while (isRunning && !token.IsCancellationRequested)
        {
            try
            {
                wsClient = new ClientWebSocket();
                wsClient.Options.KeepAliveInterval = TimeSpan.FromSeconds(20);
                await wsClient.ConnectAsync(new Uri(WsEndpoint), token);
                mainThreadQueue.Enqueue(() => {
                    Debug.Log("<color=#00FF88>⚡ [AppwriteRealtime] Da ket noi WebSocket Realtime thanh cong!</color>");
                    OnConnectionStateChanged?.Invoke(true);
                });
                reconnectDelay = 2.0f;
                var buffer = new byte[16384];
                var messageBuilder = new StringBuilder();
                while (wsClient.State == WebSocketState.Open && !token.IsCancellationRequested)
                {
                    var result = await wsClient.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await wsClient.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", token);
                        break;
                    }
                    messageBuilder.Append(Encoding.UTF8.GetString(buffer, 0, result.Count));
                    if (result.EndOfMessage)
                    {
                        string completeMessage = messageBuilder.ToString();
                        messageBuilder.Clear();
                        ProcessRawWebSocketMessage(completeMessage);
                    }
                }
            }
            catch
            {
                if (isRunning && !token.IsCancellationRequested)
                    mainThreadQueue.Enqueue(() => OnConnectionStateChanged?.Invoke(false));
            }
            finally { wsClient?.Dispose(); wsClient = null; }
            if (isRunning && !token.IsCancellationRequested)
            {
                await Task.Delay((int)(reconnectDelay * 1000), token);
                reconnectDelay = Mathf.Min(reconnectDelay * 1.5f, 15.0f);
            }
        }
    }

    private void ProcessRawWebSocketMessage(string rawJson)
    {
        if (string.IsNullOrEmpty(rawJson)) return;
        try
        {
            var wsMsg = JsonUtility.FromJson<AppwriteRealtimeMessage>(rawJson);
            if (wsMsg != null && wsMsg.data != null && wsMsg.data.payload != null)
            {
                var payload = wsMsg.data.payload;
                string uId = payload.userId;
                string uName = payload.userName;
                if (string.IsNullOrEmpty(uName)) return;

                if (uId == "BATTLE_ACT" || uName.StartsWith("BACT:"))
                {
                    var act = AppwriteMatchmaking.DecodeBattleActionString(uName, payload.timestamp);
                    if (act != null) mainThreadQueue.Enqueue(() => OnBattleActionReceived?.Invoke(act));
                }
                else if (uName.StartsWith("DACT:"))
                {
                    string[] parts = uName.Split(':');
                    if (parts.Length >= 5)
                    {
                        int pSeq = (parts.Length >= 6) ? AppwriteMatchmaking.SafeParseInt(parts[2], 0) : 0;
                        string sUid = (parts.Length >= 6) ? AppwriteMatchmaking.SafeUnescape(parts[3]) : AppwriteMatchmaking.SafeUnescape(parts[2]);
                        int sNum = (parts.Length >= 6) ? AppwriteMatchmaking.SafeParseInt(parts[4], 1) : AppwriteMatchmaking.SafeParseInt(parts[3], 1);
                        int hId = (parts.Length >= 6) ? AppwriteMatchmaking.SafeParseInt(parts[5], 0) : AppwriteMatchmaking.SafeParseInt(parts[4], 0);
                        var dAct = new AppwriteMatchmaking.DraftPlayerActionPacket {
                            roomId = AppwriteMatchmaking.SafeUnescape(parts[1]), seq = pSeq, senderUserId = sUid, seatNumber = sNum, requestedHeroId = hId, timestamp = payload.timestamp
                        };
                        mainThreadQueue.Enqueue(() => OnDraftPlayerActionReceived?.Invoke(dAct));
                    }
                }
                else if (uName.StartsWith("DHST:"))
                {
                    var dHost = AppwriteMatchmaking.DecodeDraftHostStateString(uName, payload.timestamp);
                    if (dHost != null) mainThreadQueue.Enqueue(() => OnDraftHostStateReceived?.Invoke(dHost));
                }
                else if (uId == "ROOM_WAITING" || uName.StartsWith("ROOM:"))
                {
                    var room = AppwriteMatchmaking.DecodeRoomString(uName, payload.timestamp, payload.rankPoints);
                    if (room != null) mainThreadQueue.Enqueue(() => OnRoomStateReceived?.Invoke(room));
                }
                else if (uId == "GAME_STATE" && uName.StartsWith("{"))
                {
                    var sState = JsonUtility.FromJson<AppwriteMatchmaking.ServerGameState>(uName);
                    if (sState != null && !string.IsNullOrEmpty(sState.roomId)) mainThreadQueue.Enqueue(() => OnServerGameStateReceived?.Invoke(sState));
                }
            }
        }
        catch (Exception ex) { Debug.LogWarning($"[AppwriteRealtime] Error: {ex.Message}"); }
    }

    private async void SendPingAsync()
    {
        try {
            if (wsClient != null && wsClient.State == WebSocketState.Open) {
                var bytes = Encoding.UTF8.GetBytes("{\"type\":\"ping\"}");
                await wsClient.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
            }
        } catch { }
    }

    private void OnDestroy() => StopClient();
    private void OnApplicationQuit() => StopClient();

    [Serializable] private class AppwriteRealtimeMessage { public string type; public AppwriteRealtimeData data; }
    [Serializable] private class AppwriteRealtimeData { public List<string> events; public List<string> channels; public string timestamp; public AppwriteRealtimePayload payload; }
    [Serializable] private class AppwriteRealtimePayload { public string _id; public string userId; public string userName; public int rankPoints; public long timestamp; }
}
