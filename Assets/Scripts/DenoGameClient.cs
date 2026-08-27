using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

/// <summary>
/// Deno Dedicated Game Server WebSocket Client cho Unity
/// Kết nối 2 chiều trực tiếp tới máy chủ Deno Deploy / VPS
/// Xử lý 100% logic trận đấu trên RAM siêu tốc (<15ms)
/// </summary>
public class DenoGameClient : MonoBehaviour
{
    public static DenoGameClient Instance { get; private set; }

    public static string ServerEndpoint = "wss://dai-viet-chien-server.vdthanh.deno.net"; // Đổi thành ws://localhost:8080 khi test máy local
    public static bool IsConnected => Instance != null && Instance.wsClient != null && Instance.wsClient.State == WebSocketState.Open;

    public static event Action<AppwriteMatchmaking.ServerGameState, AppwriteMatchmaking.GameStateDelta> OnGameStateUpdated;
    public static event Action<bool> OnConnectionStateChanged;
    public static event Action<string> OnErrorMessage;

    private ClientWebSocket wsClient;
    private CancellationTokenSource cts;
    private readonly ConcurrentQueue<Action> mainThreadQueue = new ConcurrentQueue<Action>();
    private bool isRunning = false;
    private float lastHeartbeatTime = 0f;
    private string activeRoomId = "";
    private int activeSeat = 1;

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.BeforeSceneLoad)]
    private static void AutoInitialize()
    {
        if (Instance == null)
        {
            var go = new GameObject("DenoGameClient");
            DontDestroyOnLoad(go);
            Instance = go.AddComponent<DenoGameClient>();
        }
    }

    private void Awake()
    {
        if (Instance != null && Instance != this) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    public void ConnectToServer(string roomId, int seat, List<AppwriteMatchmaking.GameStatePlayer> initialPlayers = null)
    {
        activeRoomId = roomId;
        activeSeat = seat;
        if (isRunning) StopConnection();

        isRunning = true;
        cts = new CancellationTokenSource();
        Task.Run(() => ConnectAndLoop(cts.Token, initialPlayers));
    }

    public void StopConnection()
    {
        isRunning = false;
        try { cts?.Cancel(); wsClient?.Abort(); wsClient?.Dispose(); wsClient = null; } catch { }
    }

    public void SendGameAction(AppwriteMatchmaking.GameActionPayload actionPayload)
    {
        if (!IsConnected || actionPayload == null) return;
        string json = JsonUtility.ToJson(actionPayload);
        SendRawMessageAsync(json);
    }

    private void Update()
    {
        while (mainThreadQueue.TryDequeue(out var action))
        {
            try { action?.Invoke(); } catch (Exception ex) { Debug.LogWarning($"[DenoGameClient] MainThread: {ex.Message}"); }
        }

        if (IsConnected && Time.unscaledTime - lastHeartbeatTime > 15.0f)
        {
            lastHeartbeatTime = Time.unscaledTime;
            SendRawMessageAsync("{\"action\":\"PING\"}");
        }
    }

    static DenoGameClient()
    {
        try
        {
            System.Net.ServicePointManager.SecurityProtocol = System.Net.SecurityProtocolType.Tls12 | System.Net.SecurityProtocolType.Tls11 | System.Net.SecurityProtocolType.Tls;
            System.Net.ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
        }
        catch { }
    }

    private async Task ConnectAndLoop(CancellationToken token, List<AppwriteMatchmaking.GameStatePlayer> initialPlayers)
    {
        float reconnectDelay = 2.0f;
        while (isRunning && !token.IsCancellationRequested)
        {
            try
            {
                wsClient = new ClientWebSocket();
                wsClient.Options.KeepAliveInterval = TimeSpan.FromSeconds(15);
                var uri = new Uri(ServerEndpoint);
                await wsClient.ConnectAsync(uri, token);

                mainThreadQueue.Enqueue(() =>
                {
                    Debug.Log($"<color=#00FF88>⚡ [DenoGameClient] Đã kết nối Deno Game Server thành công ({ServerEndpoint})!</color>");
                    OnConnectionStateChanged?.Invoke(true);
                });

                reconnectDelay = 2.0f;

                // Gửi lệnh JOIN_ROOM / INIT_GAME ngay sau khi kết nối
                var joinPayload = new AppwriteMatchmaking.GameActionPayload
                {
                    action = "JOIN_ROOM",
                    roomId = activeRoomId,
                    seat = activeSeat,
                    players = initialPlayers
                };
                await SendRawDirectAsync(JsonUtility.ToJson(joinPayload));

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
                        ProcessServerMessage(completeMessage);
                    }
                }
            }
            catch (Exception ex)
            {
                if (isRunning && !token.IsCancellationRequested)
                {
                    mainThreadQueue.Enqueue(() =>
                    {
                        Debug.LogWarning($"[DenoGameClient] Đang kết nối lại Deno Server sau {reconnectDelay}s ({ex.Message})");
                        OnConnectionStateChanged?.Invoke(false);
                    });
                }
            }
            finally
            {
                wsClient?.Dispose();
                wsClient = null;
            }

            if (isRunning && !token.IsCancellationRequested)
            {
                try { await Task.Delay((int)(reconnectDelay * 1000), token); } catch { break; }
                reconnectDelay = Mathf.Min(reconnectDelay * 1.5f, 10.0f);
            }
        }
    }

    private void ProcessServerMessage(string rawJson)
    {
        if (string.IsNullOrEmpty(rawJson)) return;
        try
        {
            var msg = JsonUtility.FromJson<DenoServerMessageWrapper>(rawJson);
            if (msg != null)
            {
                if (msg.type == "STATE_UPDATE" || msg.type == "STATE_SNAPSHOT" || msg.type == "CONFLICT")
                {
                    if (msg.state != null)
                    {
                        mainThreadQueue.Enqueue(() => OnGameStateUpdated?.Invoke(msg.state, msg.delta));
                    }
                }
                else if (msg.type == "ERROR" || msg.type == "ACTION_REJECTED")
                {
                    mainThreadQueue.Enqueue(() => OnErrorMessage?.Invoke(msg.error));
                }
            }
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"[DenoGameClient] Lỗi parse JSON: {ex.Message}");
        }
    }

    private async void SendRawMessageAsync(string json)
    {
        try
        {
            await SendRawDirectAsync(json);
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"[DenoGameClient] Gửi tin thất bại: {ex.Message}");
        }
    }

    private async Task SendRawDirectAsync(string json)
    {
        if (wsClient != null && wsClient.State == WebSocketState.Open)
        {
            var bytes = Encoding.UTF8.GetBytes(json);
            await wsClient.SendAsync(new ArraySegment<byte>(bytes), WebSocketMessageType.Text, true, CancellationToken.None);
        }
    }

    private void OnDestroy() => StopConnection();
    private void OnApplicationQuit() => StopConnection();

    [Serializable]
    private class DenoServerMessageWrapper
    {
        public string type;
        public string error;
        public string code;
        public int version;
        public AppwriteMatchmaking.ServerGameState state;
        public AppwriteMatchmaking.GameStateDelta delta;
    }
}
