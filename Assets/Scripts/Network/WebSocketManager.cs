using System;
using System.Collections.Concurrent;
using System.IO;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

public class WebSocketManager : MonoBehaviour
{
    public static WebSocketManager Instance;
    private ClientWebSocket _webSocket;
    private CancellationTokenSource _cts;
    private readonly SemaphoreSlim _sendGate = new SemaphoreSlim(1, 1);
    
    private ConcurrentQueue<string> _messageQueue = new ConcurrentQueue<string>();

    public event Action<string> OnMessageReceived;
    public event Action OnConnected;
    public event Action OnDisconnected;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void Update()
    {
        // Đẩy message từ background thread xuống Main Thread của Unity để xử lý UI
        while (_messageQueue.TryDequeue(out var msg))
        {
            OnMessageReceived?.Invoke(msg);
        }
    }

    public async void Connect(string url)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            Debug.LogError("[WebSocket] Empty server URL");
            return;
        }

        // Tear down a previous connection before replacing its socket/token.
        _cts?.Cancel();
        _webSocket?.Abort();
        _webSocket?.Dispose();
        var connectionCts = new CancellationTokenSource();
        var connectionSocket = new ClientWebSocket();
        _cts = connectionCts;
        _webSocket = connectionSocket;

        try
        {
            await connectionSocket.ConnectAsync(new Uri(url), connectionCts.Token);
            Debug.Log("[WebSocket] Connected to " + url);
            OnConnected?.Invoke();
            await Receive(connectionSocket, connectionCts.Token);
        }
        catch (Exception ex)
        {
            if (!connectionCts.IsCancellationRequested && ReferenceEquals(_cts, connectionCts))
            {
                Debug.LogError("[WebSocket] Connection error: " + ex.Message);
                OnDisconnected?.Invoke();
            }
        }
        finally
        {
            if (ReferenceEquals(_webSocket, connectionSocket))
            {
                _webSocket = null;
                _cts = null;
            }
            connectionSocket.Dispose();
            connectionCts.Dispose();
        }
    }

    private async Task Receive(ClientWebSocket socket, CancellationToken token)
    {
        var buffer = new byte[1024 * 16];
        while (socket.State == WebSocketState.Open && !token.IsCancellationRequested)
        {
            try
            {
                using (var message = new MemoryStream())
                {
                    WebSocketReceiveResult result;
                    do
                    {
                        result = await socket.ReceiveAsync(new ArraySegment<byte>(buffer), token);
                        if (result.MessageType == WebSocketMessageType.Close)
                        {
                            if (socket.State == WebSocketState.Open || socket.State == WebSocketState.CloseReceived)
                            {
                                await socket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
                            }
                            if (ReferenceEquals(_webSocket, socket)) OnDisconnected?.Invoke();
                            return;
                        }

                        if (result.Count > 0) message.Write(buffer, 0, result.Count);
                    }
                    while (!result.EndOfMessage);

                    _messageQueue.Enqueue(Encoding.UTF8.GetString(message.ToArray()));
                }
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                if (!token.IsCancellationRequested)
                {
                    Debug.LogError("[WebSocket] Receive error: " + ex.Message);
                    if (ReferenceEquals(_webSocket, socket)) OnDisconnected?.Invoke();
                }
                break;
            }
        }
    }

    public async Task Send(string message)
    {
        var socket = _webSocket;
        var tokenSource = _cts;
        if (socket != null && tokenSource != null && socket.State == WebSocketState.Open)
        {
            try
            {
                await _sendGate.WaitAsync(tokenSource.Token);
                try
                {
                    if (!ReferenceEquals(_webSocket, socket) || socket.State != WebSocketState.Open) return;
                    var buffer = Encoding.UTF8.GetBytes(message ?? string.Empty);
                    await socket.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, tokenSource.Token);
                }
                finally
                {
                    _sendGate.Release();
                }
            }
            catch (OperationCanceledException)
            {
                // Disconnect/reconnect cancels queued sends; this is an
                // expected shutdown path, not an unobserved task failure.
            }
            catch (ObjectDisposedException)
            {
                // The socket can be disposed while a fire-and-forget send is
                // waiting for the connection replacement to finish.
            }
        }
    }

    private async void OnDestroy()
    {
        _cts?.Cancel();
        if (_webSocket != null && _webSocket.State == WebSocketState.Open)
        {
            try {
                await _webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, string.Empty, CancellationToken.None);
            } catch {}
        }
        _webSocket?.Dispose();
        _cts?.Dispose();
        // Leave the gate alive for any in-flight Send continuation; disposing
        // it here can turn a normal shutdown into an unobserved exception.
    }
}
