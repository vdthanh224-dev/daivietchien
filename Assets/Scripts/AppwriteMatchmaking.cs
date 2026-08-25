using System;
using System.Collections;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Hệ thống Tìm Trận 2v2 Thời Gian Thực Trực Tiếp Trên Appwrite Database
/// Database ID: game
/// Collection ID: matchmaking_queue
/// </summary>
public static class AppwriteMatchmaking
{
    private const string Endpoint = "https://sgp.cloud.appwrite.io/v1";
    private const string ProjectId = "6a885457002da3f3d47e";
    private const string DatabaseId = "game";
    private const string CollectionId = "matchmaking_queue";

    [Serializable]
    public class PlayerQueuePacket
    {
        public string userId;
        public string userName;
        public int rankPoints;
        public long timestamp;
    }

    [Serializable]
    public class AppwriteDocument
    {
        public string userId;
        public string userName;
        public int rankPoints;
        public long timestamp;
    }

    [Serializable]
    public class AppwriteDocumentList
    {
        public int total;
        public List<AppwriteDocument> documents;
    }

    private static void AddAppwriteHeaders(UnityWebRequest req)
    {
        req.SetRequestHeader("X-Appwrite-Project", ProjectId);
        string cookie = PlayerPrefs.GetString("auth_session_cookie", "");
        if (!string.IsNullOrEmpty(cookie))
        {
            req.SetRequestHeader("Cookie", cookie);
        }
    }

    /// <summary>
    /// Đăng ký / Cập nhật người chơi vào hàng chờ trên Appwrite
    /// </summary>
    public static IEnumerator UpsertPlayerPresence(string myDocId, string userId, string userName, int rankPoints, Action<string> onCreated = null)
    {
        long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        // Thử cập nhật trước nếu đã có docId
        if (!string.IsNullOrEmpty(myDocId))
        {
            string patchUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{myDocId}";
            string patchBody = "{\"data\":{\"userId\":\"" + EscapeJson(userId) + "\",\"userName\":\"" + EscapeJson(userName) + "\",\"rankPoints\":" + rankPoints + ",\"timestamp\":" + now + "}}";

            using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
            {
                patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchBody));
                patchReq.downloadHandler = new DownloadHandlerBuffer();
                patchReq.SetRequestHeader("Content-Type", "application/json");
                AddAppwriteHeaders(patchReq);
                patchReq.timeout = 5;
                yield return patchReq.SendWebRequest();

                if (patchReq.result == UnityWebRequest.Result.Success)
                {
                    onCreated?.Invoke(myDocId);
                    yield break;
                }
            }
        }

        // Tạo tài liệu mới trên Appwrite
        string postUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";
        string postBody = "{\"documentId\":\"unique()\",\"data\":{\"userId\":\"" + EscapeJson(userId) + "\",\"userName\":\"" + EscapeJson(userName) + "\",\"rankPoints\":" + rankPoints + ",\"timestamp\":" + now + "}}";

        using (var postReq = new UnityWebRequest(postUrl, "POST"))
        {
            postReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(postBody));
            postReq.downloadHandler = new DownloadHandlerBuffer();
            postReq.SetRequestHeader("Content-Type", "application/json");
            AddAppwriteHeaders(postReq);
            postReq.timeout = 5;
            yield return postReq.SendWebRequest();

            if (postReq.result == UnityWebRequest.Result.Success)
            {
                string text = postReq.downloadHandler.text;
                string newDocId = ExtractDocIdFromJson(text);
                if (!string.IsNullOrEmpty(newDocId))
                {
                    onCreated?.Invoke(newDocId);
                }
            }
        }
    }

    /// <summary>
    /// Quét tìm danh sách các người chơi thực khác đang cùng ở trong hàng chờ Appwrite
    /// </summary>
    public static IEnumerator PollActivePlayers(string myUserId, Action<List<PlayerQueuePacket>> onResult)
    {
        var activePlayers = new List<PlayerQueuePacket>();
        string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";

        using (var req = UnityWebRequest.Get(getUrl))
        {
            AddAppwriteHeaders(req);
            req.timeout = 5;
            yield return req.SendWebRequest();

            if (req.result == UnityWebRequest.Result.Success)
            {
                string json = req.downloadHandler.text;
                if (!string.IsNullOrWhiteSpace(json))
                {
                    var docList = JsonUtility.FromJson<AppwriteDocumentList>(json);
                    if (docList != null && docList.documents != null)
                    {
                        long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                        var seenUsers = new HashSet<string>();

                        foreach (var doc in docList.documents)
                        {
                            if (doc != null && !string.IsNullOrWhiteSpace(doc.userId))
                            {
                                // Lọc bỏ bản thân và người chơi đã quá hạn 15s
                                if (doc.userId != myUserId && !seenUsers.Contains(doc.userId))
                                {
                                    if (now - doc.timestamp < 15000)
                                    {
                                        seenUsers.Add(doc.userId);
                                        activePlayers.Add(new PlayerQueuePacket
                                        {
                                            userId = doc.userId,
                                            userName = !string.IsNullOrWhiteSpace(doc.userName) ? doc.userName : "Chiến Tướng",
                                            rankPoints = doc.rankPoints,
                                            timestamp = doc.timestamp
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        onResult?.Invoke(activePlayers);
    }

    /// <summary>
    /// Rút khỏi hàng chờ trên Appwrite khi vào trận hoặc hủy tìm trận
    /// </summary>
    public static IEnumerator RemovePlayerFromQueue(string docId)
    {
        if (string.IsNullOrEmpty(docId)) yield break;

        string delUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";
        using (var req = new UnityWebRequest(delUrl, "DELETE"))
        {
            req.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(req);
            req.timeout = 4;
            yield return req.SendWebRequest();
        }
    }

    private static string ExtractDocIdFromJson(string json)
    {
        if (string.IsNullOrEmpty(json)) return null;
        int idx = json.IndexOf("\"$id\":\"", StringComparison.OrdinalIgnoreCase);
        if (idx >= 0)
        {
            int start = idx + 8;
            int end = json.IndexOf("\"", start);
            if (end > start)
            {
                return json.Substring(start, end - start);
            }
        }
        return null;
    }

    private static string EscapeJson(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        return s.Replace("\\", "\\\\").Replace("\"", "\\\"");
    }
}
