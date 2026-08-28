using System;
using System.Collections.Generic;
using UnityEngine;

public class GameNetworkController : MonoBehaviour
{
    public string serverUrl = "ws://localhost:8080";
    public string roomId = "test_room_01";
    public int mySeat = 1;

    private void Start()
    {
        if (WebSocketManager.Instance != null)
        {
            WebSocketManager.Instance.OnConnected += OnConnected;
            WebSocketManager.Instance.OnMessageReceived += OnMessageReceived;
            WebSocketManager.Instance.OnDisconnected += OnDisconnected;
            
            Debug.Log("[GameNetwork] Đang kết nối tới Deno Server...");
            WebSocketManager.Instance.Connect(serverUrl);
        }
        else
        {
            Debug.LogError("[GameNetwork] Không tìm thấy WebSocketManager.Instance! Hãy đảm bảo nó có trong Scene.");
        }
    }

    private void OnConnected()
    {
        Debug.Log("[GameNetwork] Đã kết nối! Đang gửi yêu cầu tham gia phòng...");
        // Serialize through JsonUtility so room/user values cannot break the
        // JSON envelope (the server requires all four players on first join).
        SendAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "JOIN_ROOM",
            roomId = roomId,
            seat = mySeat,
            players = new List<AppwriteMatchmaking.GameStatePlayer>
            {
                new AppwriteMatchmaking.GameStatePlayer { userId = "p1", heroId = "TRAN_HUNG_DAO", isAI = false },
                new AppwriteMatchmaking.GameStatePlayer { userId = "p2", heroId = "LY_THUONG_KIET", isAI = true },
                new AppwriteMatchmaking.GameStatePlayer { userId = "p3", heroId = "NGUYEN_HUE", isAI = true },
                new AppwriteMatchmaking.GameStatePlayer { userId = "p4", heroId = "LE_LOI", isAI = true }
            }
        });
    }

    private void OnMessageReceived(string message)
    {
        Debug.Log("[GameNetwork] Nhận từ Server: " + message);
    }

    private void OnDisconnected()
    {
        Debug.Log("[GameNetwork] Đã ngắt kết nối.");
    }
    
    private void OnDestroy()
    {
        if (WebSocketManager.Instance != null)
        {
            WebSocketManager.Instance.OnConnected -= OnConnected;
            WebSocketManager.Instance.OnMessageReceived -= OnMessageReceived;
            WebSocketManager.Instance.OnDisconnected -= OnDisconnected;
        }
    }

    // Các hàm tiện ích để UI gọi khi người chơi click
    public void SendPlayCard(string cardId, int targetSeat)
    {
        SendAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "PLAY_CARD", roomId = roomId, seat = mySeat,
            cardId = cardId, targetSeat = targetSeat
        });
    }

    public void SendRespond(bool accepted, string cardId)
    {
        SendAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "RESPOND_ACTION", roomId = roomId, seat = mySeat,
            accepted = accepted, cardId = cardId ?? string.Empty
        });
    }

    public void SendEndTurn()
    {
        SendAction(new AppwriteMatchmaking.GameActionPayload
        {
            action = "END_TURN", roomId = roomId, seat = mySeat
        });
    }

    private void SendAction(AppwriteMatchmaking.GameActionPayload payload)
    {
        if (WebSocketManager.Instance == null || payload == null) return;
        var currentState = GameStateManager.Instance != null ? GameStateManager.Instance.CurrentState : null;
        if (currentState != null && string.Equals(currentState.roomId, payload.roomId, StringComparison.Ordinal))
        {
            payload.expectedVersion = currentState.version;
        }
        _ = WebSocketManager.Instance.Send(JsonUtility.ToJson(payload));
    }
}
