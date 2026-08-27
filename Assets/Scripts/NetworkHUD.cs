using UnityEngine;

/// <summary>
/// NetworkHUD: Cung cấp giao diện Start Host / Start Client / Start Server nhanh chóng.
/// Hỗ trợ cả 2 cách:
/// 1. OnGUI Overlay (Hiển thị góc trên trái màn hình khi test trong Scene).
/// 2. uGUI Button Events (Gắn vào OnClick() của Button trong Canvas).
/// </summary>
public class NetworkHUD : MonoBehaviour
{
    [Header("Giao diện OnGUI")]
    [SerializeField] private bool showOnGUI = true;
    [SerializeField] private Vector2 guiPosition = new Vector2(20, 20);
    [SerializeField] private Vector2 guiSize = new Vector2(220, 240);

    private void OnGUI()
    {
        if (!showOnGUI) return;

        GUILayout.BeginArea(new Rect(guiPosition.x, guiPosition.y, guiSize.x, guiSize.y));
        
#if UNITY_NETCODE_GAMEOBJECTS || NETCODE_AVAILABLE
        if (Unity.Netcode.NetworkManager.Singleton == null)
        {
            GUILayout.Label("<b>⚠️ Chưa có NetworkManager trong Scene!</b>");
            if (GUILayout.Button("Tạo NetworkManager", GUILayout.Height(35)))
            {
                var go = new GameObject("NetworkManager", typeof(Unity.Netcode.NetworkManager));
            }
        }
        else if (!Unity.Netcode.NetworkManager.Singleton.IsClient && !Unity.Netcode.NetworkManager.Singleton.IsServer)
        {
            if (GUILayout.Button("👑 Start Host", GUILayout.Height(40))) 
                StartHost();
                
            if (GUILayout.Button("👥 Start Client", GUILayout.Height(40))) 
                StartClient();
                
            if (GUILayout.Button("🖥️ Start Server", GUILayout.Height(40))) 
                StartServer();
        }
        else
        {
            string mode = Unity.Netcode.NetworkManager.Singleton.IsHost ? "👑 Host (Chủ phòng)" : (Unity.Netcode.NetworkManager.Singleton.IsServer ? "🖥️ Server" : "👥 Client");
            GUILayout.Label($"<b>Trạng thái:</b> {mode}");
            GUILayout.Label($"<b>Kết nối:</b> {Unity.Netcode.NetworkManager.Singleton.ConnectedClientsList.Count} người");
            
            if (GUILayout.Button("❌ Disconnect", GUILayout.Height(40))) 
                Disconnect();
        }
#else
        GUILayout.Label("<b>🎮 Network HUD</b>");
        if (GUILayout.Button("👑 Start Host", GUILayout.Height(40))) StartHost();
        if (GUILayout.Button("👥 Start Client", GUILayout.Height(40))) StartClient();
        if (GUILayout.Button("🖥️ Start Server", GUILayout.Height(40))) StartServer();
#endif

        GUILayout.EndArea();
    }

    public void StartHost()
    {
#if UNITY_NETCODE_GAMEOBJECTS || NETCODE_AVAILABLE
        if (Unity.Netcode.NetworkManager.Singleton != null) Unity.Netcode.NetworkManager.Singleton.StartHost();
#endif
        Debug.Log("[NetworkHUD] StartHost triggered.");
    }

    public void StartClient()
    {
#if UNITY_NETCODE_GAMEOBJECTS || NETCODE_AVAILABLE
        if (Unity.Netcode.NetworkManager.Singleton != null) Unity.Netcode.NetworkManager.Singleton.StartClient();
#endif
        Debug.Log("[NetworkHUD] StartClient triggered.");
    }

    public void StartServer()
    {
#if UNITY_NETCODE_GAMEOBJECTS || NETCODE_AVAILABLE
        if (Unity.Netcode.NetworkManager.Singleton != null) Unity.Netcode.NetworkManager.Singleton.StartServer();
#endif
        Debug.Log("[NetworkHUD] StartServer triggered.");
    }

    public void Disconnect()
    {
#if UNITY_NETCODE_GAMEOBJECTS || NETCODE_AVAILABLE
        if (Unity.Netcode.NetworkManager.Singleton != null) Unity.Netcode.NetworkManager.Singleton.Shutdown();
#endif
        Debug.Log("[NetworkHUD] Disconnect triggered.");
    }
}
