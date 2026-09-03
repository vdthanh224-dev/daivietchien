using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

/// <summary>
/// Hệ thống Tìm Trận 2v2 Thời Gian Thực, Đồng Bộ Chọn Tướng & Đấu Bài
/// Chạy 100% trên Appwrite Singapore Database Server (Độ trễ <200ms)
/// Kiến trúc: Bounded Document Slots (Tối đa 10 slots/phòng), FNV-1a Deterministic Hash, Safe Serialization.
/// </summary>
public static class AppwriteMatchmaking
{
    private const string Endpoint = "https://sgp.cloud.appwrite.io/v1";
    private const string ProjectId = "6a885457002da3f3d47e";
    private const string DatabaseId = "game";
    private const string CollectionId = "matchmaking_queue";

    #region Data Packets
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

    [Serializable]
    public class RoomSlotData
    {
        public int seatNumber;
        public string userId;
        public string userName;
        public int rankPoints;
        public bool isPlayer;
        public bool isAlly;
        public bool isDragon;
        public bool isAI;
        public int chosenHeroId;
        public bool isEmpty => string.IsNullOrEmpty(userId) || userId == "empty";
    }

    [Serializable]
    public class RoomStatePacket
    {
        public string roomId;
        public string hostUserId;
        public long hostTimestamp;
        public string status; // "WAITING", "STARTED", "FINISHED"
        public List<RoomSlotData> slots = new List<RoomSlotData>();
        public long updateTimestamp;
        public int hostRankPoints;
        public int version;
    }

    [Serializable]
    public class DraftHostStatePacket
    {
        public string roomId;
        public int seq;
        public string phase; // "PICKING", "COUNTDOWN", "START_BATTLE"
        public int currentPickerIndex; // 0, 1, 2, 3
        public int currentSeatNumber; // 1, 2, 3, 4
        public float timerLeft;
        public int countdownSec;
        public int heroId1;
        public int heroId2;
        public int heroId3;
        public int heroId4;
        public long timestamp;
    }

    [Serializable]
    public class DraftPlayerActionPacket
    {
        public string roomId;
        public int seq;
        public string senderUserId;
        public int seatNumber;
        public int requestedHeroId;
        public long timestamp;
    }

    [Serializable]
    public class BattleActionPacket
    {
        public string roomId;
        public int seq;
        public string senderUserId;
        public int casterSeat;
        public int targetSeat;
        public string actionType;
        public string cardId;
        public string cardName;
        public int cardCategory;
        public int cardSubType;
        public int cardSuit;
        public int cardRank;
        public int attackRange;
        public int damage;
        public bool isWineBuff;
        public bool accepted;
        public string nonce;
        public long timestamp;
    }

    [Serializable]
    public class GameStateCard
    {
        public string id;
        public string name;
        public string suit;
        public int rank;
        public int category;
        public int subType;
        // Optional fields emitted by the authoritative Deno deck. Keeping
        // them here lets clients render cards that are not in CardDatabase.
        public string desc;
        // Deno's WebSocket sanitizer uses `attackRange`; the REST fallback
        // historically used `range`, so both names are intentionally kept.
        public int attackRange;
        public int range;
        public int distMod;
    }

    [Serializable]
    public class GameStatePlayer
    {
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
        public List<GameStateCard> hand = new List<GameStateCard>();
        public List<GameStateCard> equipments = new List<GameStateCard>();
        public List<GameStateCard> judgements = new List<GameStateCard>();
        public int aoBaoCharges;
        public List<string> skills = new List<string>();
        public string[] activeSkillsKeys;
        public bool[] activeSkillsValues;
        public string[] usedSkillsKeys;
        public bool[] usedSkillsValues;
    }

    [Serializable]
    public class GameStateActiveCard
    {
        public string cardId;
        public string cardName;
        public int casterSeat;
        public int targetSeat;
        public int targetSeat2;
        public int[] targetSeats;
        public int damage;
        public bool isWineBuff;
        public string suit;
        public string reqType;
        public string reqName;
        public bool isCanceled;
        public bool namSonFollowUp;
        public string selectionOperation;
        public int nullifyRound;
        public int nullifyBySeat;
    }

    [Serializable]
    public class GameStateTargetCardOption
    {
        public string token;
        public string zone;
        public string label;
        public GameStateCard card;
    }

    [Serializable]
    public class GameStateTargetCardSelection
    {
        public int chooserSeat;
        public int targetSeat;
        public string operation;
        public string effectType;
        public string cardId;
        public string cardName;
        public List<GameStateTargetCardOption> options = new List<GameStateTargetCardOption>();
    }

    [Serializable]
    public class GameStateNullifyChain
    {
        public bool isCanceled;
        public int currentIdx;
        public int whoUsedLast;
        public List<int> querySeats = new List<int>();
    }

    [Serializable]
    public class GameStateLastAction
    {
        public string type;
        public int casterSeat;
        public int targetSeat;
        public string cardId;
        public string cardName;
        public int damage;
        public bool isWineBuff;
        public string description;
        public long timestamp;
        public int seq;
    }

    [Serializable]
    public class GameStatePlayerDelta
    {
        public int seat;
        public int hp;
        public int maxHp;
        public int handCount;
        public bool isWineBuffActive;
        public int aoBaoCharges;
        public List<GameStateCard> equipments = new List<GameStateCard>();
        public List<GameStateCard> judgements = new List<GameStateCard>();
        public string[] activeSkillsKeys;
        public bool[] activeSkillsValues;
        public string[] usedSkillsKeys;
        public bool[] usedSkillsValues;
    }

    [Serializable]
    public class GameStateDelta
    {
        public int version;
        public int actionSeq;
        public string type;
        public string description;
        public int turnSeat;
        public string phase;
        public int turnTimer;
        public int waitingTargetSeat;
        public string waitingReactionType;
        public int waitingTimer;
        public int nearDeathVictimSeat;
        public List<int> nearDeathAskerQueue = new List<int>();
        public List<int> aoeVictimsQueue = new List<int>();
        public List<int> harvestPickers = new List<int>();
        public int slashesUsedThisTurn;
        public int duelCasterSeat;
        public int duelTargetSeat;
        public GameStateActiveCard activeCard;
        public GameStateTargetCardSelection targetCardSelection;
        public GameStateNullifyChain nullifyChain;
        public int deckCount;
        public int discardCount;
        public GameStateCard discardTop;
        public string status;
        public List<GameStateCard> harvestPool = new List<GameStateCard>();
        public List<GameStatePlayerDelta> playerDeltas = new List<GameStatePlayerDelta>();
    }

    [Serializable]
    public class ServerGameState
    {
        public int version;
        public string roomId;
        public string status; // "PLAYING", "FINISHED"
        public int turnSeat;
        public string phase; // "PLAY", "AWAIT_NULLIFY", "AWAIT_TARGET_CARD", "AWAIT_SLASH_DEFENSE", "AWAIT_HARVEST", "AWAIT_AOE", "AWAIT_DUEL", "AWAIT_NEAR_DEATH", "AWAIT_SONG_CUNG_FOLLOW_UP", "AWAIT_NAM_SON_FOLLOW_UP", "DISCARD"
        public int turnTimer;
        public int waitingTargetSeat;
        public string waitingReactionType;
        public int waitingTimer;
        public int nearDeathVictimSeat;
        public List<int> nearDeathAskerQueue = new List<int>();
        public List<int> aoeVictimsQueue = new List<int>();
        public List<int> harvestPickers = new List<int>();
        public int slashesUsedThisTurn;
        public GameStateActiveCard activeCard;
        public int duelCasterSeat;
        public int duelTargetSeat;
        public GameStateTargetCardSelection targetCardSelection;
        public GameStateNullifyChain nullifyChain;
        public List<GameStateCard> harvestPool = new List<GameStateCard>();
        public GameStateLastAction lastAction;
        public List<GameStateLastAction> actionHistory = new List<GameStateLastAction>();
        public GameStateCard discardTop;
        public int deckCount;
        public int discardCount;
        public List<GameStatePlayer> players = new List<GameStatePlayer>();
        public GameStateDelta delta;
    }

    [Serializable]
    public class GameActionPayload
    {
        public string action;
        public string skillId;
        public string roomId;
        public int seat;
        public string cardId;
        public string targetCardId;
        public int targetSeat;
        public int targetSeat2;
        public int[] targetSeats;
        public int damage;
        public bool isWineBuff;
        public bool accepted;
        public List<string> cardIds;
        public List<GameStatePlayer> players;
        public int expectedVersion;
    }
    #endregion

    #region Security & Header Helpers
    private static void AddAppwriteHeaders(UnityWebRequest req)
    {
        req.SetRequestHeader("X-Appwrite-Project", ProjectId);
        req.SetRequestHeader("Content-Type", "application/json");
        if (req.uploadHandler != null)
        {
            req.uploadHandler.contentType = "application/json";
        }
        string secret = PlayerPrefs.GetString("auth_session_secret", "");
        if (!string.IsNullOrEmpty(secret))
        {
            req.SetRequestHeader("X-Appwrite-Session", secret);
        }
        string cookie = PlayerPrefs.GetString("auth_session_cookie", "");
        if (!string.IsNullOrEmpty(cookie))
        {
#if !UNITY_WEBGL || UNITY_EDITOR
            req.SetRequestHeader("Cookie", cookie);
#endif
        }
    }

    /// <summary>
    /// Thuật toán băm FNV-1a 32-bit: Đảm bảo 100% cùng 1 chuỗi ra đúng cùng 1 số integer trên mọi máy và tiến trình.
    /// Khắc phục triệt để lỗi string.GetHashCode() không đồng nhất giữa các thiết bị.
    /// </summary>
    public static int GetDeterministicHashCode(string str)
    {
        if (string.IsNullOrEmpty(str)) return 0;
        unchecked
        {
            uint hash = 2166136261;
            for (int i = 0; i < str.Length; i++)
            {
                hash ^= (uint)str[i];
                hash *= 16777619;
            }
            return (int)(hash & 0x7FFFFFFF); // Luôn là số dương
        }
    }

    public static string GetDeterministicDocId(string prefix, string rawId)
    {
        if (string.IsNullOrEmpty(rawId)) rawId = Guid.NewGuid().ToString("N");
        using (var md5 = MD5.Create())
        {
            byte[] hash = md5.ComputeHash(Encoding.UTF8.GetBytes(rawId));
            var sb = new StringBuilder();
            for (int i = 0; i < hash.Length; i++) sb.Append(hash[i].ToString("x2"));
            string hex = sb.ToString();
            string p = string.IsNullOrEmpty(prefix) ? "u_" : prefix;
            return (p + hex).Substring(0, Math.Min(32, p.Length + hex.Length));
        }
    }

    public static string Sanitize(string str, int maxLen = 24)
    {
        if (string.IsNullOrEmpty(str)) return "";
        string clean = str.Replace("|", " ").Replace(",", " ").Trim();
        if (clean.Length > maxLen) clean = clean.Substring(0, maxLen);
        return clean;
    }

    public static string SafeEscape(string str)
    {
        if (string.IsNullOrEmpty(str)) return "";
        return Uri.EscapeDataString(str);
    }

    public static string SafeUnescape(string str)
    {
        if (string.IsNullOrEmpty(str)) return "";
        if (str.Contains("%"))
        {
            try { return Uri.UnescapeDataString(str); }
            catch { return str; }
        }
        return str;
    }

    public static int SafeParseInt(string str, int defaultVal = 0)
    {
        if (int.TryParse(str, out int val)) return val;
        return defaultVal;
    }

    public static float SafeParseFloat(string str, float defaultVal = 0f)
    {
        if (float.TryParse(str, NumberStyles.Float, CultureInfo.InvariantCulture, out float val)) return val;
        return defaultVal;
    }

    public static DraftHostStatePacket DecodeDraftHostStateString(string raw, long docTimestamp)
    {
        if (string.IsNullOrEmpty(raw) || !raw.StartsWith("DHST:")) return null;
        string[] parts = raw.Split(':');
        if (parts.Length < 10) return null;

        return new DraftHostStatePacket
        {
            roomId = SafeUnescape(parts[1]),
            seq = SafeParseInt(parts[2], 0),
            phase = SafeUnescape(parts[3]),
            currentPickerIndex = SafeParseInt(parts[4], 0),
            currentSeatNumber = SafeParseInt(parts[5], 1),
            timerLeft = SafeParseFloat(parts[6], 40f),
            heroId1 = SafeParseInt(parts[7], 0),
            heroId2 = SafeParseInt(parts[8], 0),
            heroId3 = SafeParseInt(parts[9], 0),
            heroId4 = (parts.Length > 10) ? SafeParseInt(parts[10], 0) : 0,
            timestamp = docTimestamp
        };
    }

    public static BattleActionPacket DecodeBattleActionString(string raw, long docTimestamp)
    {
        if (string.IsNullOrEmpty(raw) || !raw.StartsWith("BACT:")) return null;
        string[] parts = raw.Split(':');
        if (parts.Length < 8) return null;

        return new BattleActionPacket
        {
            roomId = SafeUnescape(parts[1]),
            seq = SafeParseInt(parts[2], 0),
            casterSeat = SafeParseInt(parts[3], 1),
            targetSeat = SafeParseInt(parts[4], 0),
            actionType = SafeUnescape(parts[5]),
            cardId = SafeUnescape(parts[6]),
            accepted = (parts[7] == "1"),
            nonce = (parts.Length >= 9) ? SafeUnescape(parts[8]) : "",
            senderUserId = (parts.Length >= 10) ? SafeUnescape(parts[9]) : "",
            timestamp = docTimestamp
        };
    }

    

    [Serializable]
    private class AppwriteCreateDocPayload
    {
        public string documentId;
        public AppwriteDocData data;
        public string[] permissions;
    }

    [Serializable]
    private class AppwritePatchDocPayload
    {
        public AppwriteDocData data;
        public string[] permissions;
    }

    [Serializable]
    private class AppwriteDocData
    {
        public string userId;
        public string userName;
        public int rankPoints;
        public long timestamp;
    }

    private static readonly string[] PublicDocPermissions = new string[] { "read(\"any\")", "update(\"any\")", "delete(\"any\")" };

    private static string BuildCreateJson(string docId, string userId, string userName, int rankPoints, long timestamp)
    {
        var payload = new AppwriteCreateDocPayload
        {
            documentId = docId,
            data = new AppwriteDocData
            {
                userId = userId,
                userName = userName,
                rankPoints = rankPoints,
                timestamp = timestamp
            },
            permissions = PublicDocPermissions
        };
        return JsonUtility.ToJson(payload);
    }

    private static string BuildPatchJson(string userId, string userName, int rankPoints, long timestamp)
    {
        var payload = new AppwritePatchDocPayload
        {
            data = new AppwriteDocData
            {
                userId = userId,
                userName = userName,
                rankPoints = rankPoints,
                timestamp = timestamp
            },
            permissions = PublicDocPermissions
        };
        return JsonUtility.ToJson(payload);
    }

    private static string JsonEscape(string s)
    {
        if (s == null) return "\"\"";
        return "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r") + "\"";
    }
    #endregion

    #region 1. DYNAMIC ROOM MATCHMAKING (RANK PRIORITY, ATOMIC JOIN, HEARTBEAT & CLEANUP)

    public static string EncodeRoomString(RoomStatePacket room)
    {
        // Format an toàn, gọn gàng < 200 ký tự (chống vượt ngưỡng 255 chars của Appwrite)
        var sb = new StringBuilder();
        string rId = Sanitize(room.roomId, 18);
        string hUid = Sanitize(room.hostUserId, 24);
        string st = Sanitize(room.status, 10);
        sb.Append($"ROOM4|{rId}|{hUid}|{st}|{room.version}");
        for (int i = 0; i < 4; i++)
        {
            if (i < room.slots.Count)
            {
                var s = room.slots[i];
                string uid = s.isEmpty ? "empty" : Sanitize(s.userId, 24);
                string uname = string.IsNullOrEmpty(s.userName) ? "" : Sanitize(s.userName, 14);
                sb.Append($"|{uid},{uname},{s.rankPoints},{(s.isDragon ? 1 : 0)},{(s.isAI ? 1 : 0)}");
            }
            else
            {
                bool isDrag = (i == 0 || i == 2);
                sb.Append($"|empty,,0,{(isDrag ? 1 : 0)},0");
            }
        }
        return sb.ToString();
    }

    public static RoomStatePacket DecodeRoomString(string rawStr, long docTimestamp = 0, int hostRp = 0)
    {
        if (string.IsNullOrEmpty(rawStr) || !rawStr.StartsWith("ROOM4|")) return null;
        string[] parts = rawStr.Split('|');
        if (parts.Length < 8) return null;

        int ver = 0;
        int slotStartIndex = 5;
        if (parts.Length >= 9 && int.TryParse(parts[4], out ver))
        {
            slotStartIndex = 5;
        }
        else
        {
            slotStartIndex = 4;
        }

        var room = new RoomStatePacket
        {
            roomId = SafeUnescape(parts[1]),
            hostUserId = SafeUnescape(parts[2]),
            status = SafeUnescape(parts[3]),
            version = ver,
            hostTimestamp = docTimestamp,
            updateTimestamp = docTimestamp,
            hostRankPoints = hostRp
        };

        for (int i = slotStartIndex; i < parts.Length && i < slotStartIndex + 4; i++)
        {
            string[] sub = parts[i].Split(',');
            string uid = sub.Length > 0 ? SafeUnescape(sub[0]) : "empty";
            string uname = sub.Length > 1 ? SafeUnescape(sub[1]) : "";
            int rp = (sub.Length > 2) ? SafeParseInt(sub[2], 0) : 0;
            int seatIdx = i - slotStartIndex + 1;
            bool isDrag = (seatIdx == 1 || seatIdx == 3);
            if (sub.Length > 3) isDrag = (sub[3] == "1");
            bool isAI = (sub.Length > 4 && sub[4] == "1");

            room.slots.Add(new RoomSlotData
            {
                seatNumber = seatIdx,
                userId = uid,
                userName = uname,
                rankPoints = rp,
                isDragon = isDrag,
                isAI = isAI
            });
        }

        return room;
    }

    /// <summary>
    /// Tìm phòng đang tuyển người (ROOM_WAITING) có điểm rank gần với bản thân nhất và còn slot trống.
    /// Tự động phân trang với ?limit=100 và thực thi dọn dẹp các document cũ > 45s.
    /// </summary>
    public static IEnumerator FindBestWaitingRoom(string myUserId, int myRankPoints, Action<RoomStatePacket> onFound, int maxRankDiff = 500)
    {
        string qEqual = Uri.EscapeDataString("{\"method\":\"equal\",\"attribute\":\"userId\",\"values\":[\"ROOM_WAITING\"]}");
        string qOrder = Uri.EscapeDataString("{\"method\":\"orderDesc\",\"attribute\":\"$createdAt\"}");
        string qLimit = Uri.EscapeDataString("{\"method\":\"limit\",\"values\":[100]}");
        string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents?queries[0]={qEqual}&queries[1]={qOrder}&queries[2]={qLimit}";
        long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        RoomStatePacket bestRoom = null;
        int minRankDiff = int.MaxValue;

        using (var req = UnityWebRequest.Get(getUrl))
        {
            AddAppwriteHeaders(req);
            req.timeout = 3;
            yield return req.SendWebRequest();

            if (req.result == UnityWebRequest.Result.Success)
            {
                var docList = JsonUtility.FromJson<AppwriteDocumentList>(req.downloadHandler.text);
                if (docList != null && docList.documents != null)
                {
                    foreach (var doc in docList.documents)
                    {
                        if (doc == null) continue;

                        // Tính tuổi document an toàn (không dùng Math.Abs tránh lệch đồng hồ giữa các thiết bị)
                        long age = now - doc.timestamp;

                        // Tự động dọn dẹp các document cũ > 180 giây (3 phút) để giải phóng collection
                        if (age > 180000 && !string.IsNullOrEmpty(doc.userName))
                        {
                            string staleDocId = "";
                            if (doc.userName.StartsWith("ROOM4|"))
                            {
                                var parts = doc.userName.Split('|');
                                if (parts.Length > 1) staleDocId = GetDeterministicDocId("r_", SafeUnescape(parts[1]));
                            }
                            else if (doc.userName.StartsWith("DSTATE:"))
                            {
                                var parts = doc.userName.Split(':');
                                if (parts.Length > 1) staleDocId = GetDeterministicDocId("ds_", SafeUnescape(parts[1]));
                            }
                            else if (doc.userName.StartsWith("DACT:"))
                            {
                                var parts = doc.userName.Split(':');
                                if (parts.Length > 4) staleDocId = GetDeterministicDocId("da_", SafeUnescape(parts[1]) + "_" + parts[4]);
                            }
                            else if (doc.userName.StartsWith("BACT:"))
                            {
                                var parts = doc.userName.Split(':');
                                if (parts.Length > 3) staleDocId = GetDeterministicDocId("ba_", SafeUnescape(parts[1]) + "_" + parts[3]);
                            }

                            if (!string.IsNullOrEmpty(staleDocId))
                            {
                                Coroutiner.Start(DeleteDocumentAsync(staleDocId));
                            }
                            continue;
                        }

                        // Phòng còn hợp lệ nếu tuổi < 120 giây (hoặc doc.timestamp ở tương lai do lệch đồng hồ)
                        if (doc.userId == "ROOM_WAITING" && !string.IsNullOrWhiteSpace(doc.userName) && age < 120000)
                        {
                            var r = DecodeRoomString(doc.userName, doc.timestamp, doc.rankPoints);
                            if (r != null && r.status == "WAITING")
                            {
                                if (r.hostUserId == myUserId) continue;

                                bool hasEmptySlot = false;
                                foreach (var s in r.slots)
                                {
                                    if (s.isEmpty) { hasEmptySlot = true; break; }
                                }

                                if (hasEmptySlot)
                                {
                                    int diff = Math.Abs(doc.rankPoints - myRankPoints);
                                    if (diff <= maxRankDiff && diff < minRankDiff)
                                    {
                                        minRankDiff = diff;
                                        bestRoom = r;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        onFound?.Invoke(bestRoom);
    }

    private static IEnumerator DeleteDocumentAsync(string docId)
    {
        if (string.IsNullOrEmpty(docId)) yield break;
        string delUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";
        using (var delReq = new UnityWebRequest(delUrl, "DELETE"))
        {
            AddAppwriteHeaders(delReq);
            delReq.timeout = 2;
            yield return delReq.SendWebRequest();
        }
    }

    /// <summary>
    /// Chủ phòng (Host) tạo phòng mới trên Appwrite. Kiểm tra và trả về kết quả onCreated rõ ràng.
    /// </summary>
    public static IEnumerator CreateWaitingRoom(RoomStatePacket room, Action<bool> onCreated = null)
    {
        room.updateTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        room.version = 1;
        string docId = GetDeterministicDocId("r_", room.roomId);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";
        string compactStr = EncodeRoomString(room);

        // 1. Tạo mới bằng POST trực tiếp (JsonUtility serialized)
        string createJson = BuildCreateJson(docId, "ROOM_WAITING", compactStr, room.hostRankPoints, room.updateTimestamp);
        using (var postReq = new UnityWebRequest(docsUrl, "POST"))
        {
            postReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(createJson));
            postReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(postReq);
            postReq.timeout = 5;
            yield return postReq.SendWebRequest();

            if (postReq.result == UnityWebRequest.Result.Success)
            {
                onCreated?.Invoke(true);
                yield break;
            }

            // Nếu phòng đã tồn tại (HTTP 409 Conflict) -> Ghi đè bằng PATCH
            if (postReq.responseCode == 409)
            {
                string patchUrl = $"{docsUrl}/{docId}";
                string patchJson = BuildPatchJson("ROOM_WAITING", compactStr, room.hostRankPoints, room.updateTimestamp);
                using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
                {
                    patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
                    patchReq.downloadHandler = new DownloadHandlerBuffer();
                    AddAppwriteHeaders(patchReq);
                    patchReq.timeout = 5;
                    yield return patchReq.SendWebRequest();
                    if (patchReq.result == UnityWebRequest.Result.Success)
                    {
                        onCreated?.Invoke(true);
                        yield break;
                    }
                }
            }

            Debug.LogError($"[AppwriteMatchmaking] CreateWaitingRoom FAILED: HTTP {postReq.responseCode} - {postReq.error} - {postReq.downloadHandler?.text}");
            onCreated?.Invoke(false);
        }
    }

    /// <summary>
    /// Heartbeat định kỳ của Host: Cập nhật timestamp để phòng luôn active trong mắt Guest.
    /// </summary>
    public static IEnumerator SendHostHeartbeat(RoomStatePacket room)
    {
        if (room == null || string.IsNullOrEmpty(room.roomId)) yield break;
        yield return UpdateRoomState(room);
    }

    public static IEnumerator SendHostHeartbeat(string roomId)
    {
        if (string.IsNullOrEmpty(roomId)) yield break;
        long now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        string docId = GetDeterministicDocId("r_", roomId);
        string patchUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";
        
        // Chỉ gửi cập nhật timestamp, không ghi đè userName để tránh làm mất người chơi thứ 2, 3
        string patchJson = $"{{\"data\":{{\"timestamp\":{now}}},\"permissions\":[\"read(\\\"any\\\")\",\"update(\\\"any\\\")\",\"delete(\\\"any\\\")]}}";
        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 2;
            yield return patchReq.SendWebRequest();
        }
    }

    /// <summary>
    /// Người chơi (Guest) tham gia vào slot trống đầu tiên với cơ chế xác nhận Optimistic Lock.
    /// </summary>
    public static IEnumerator JoinRoomSlot(RoomStatePacket room, string myUserId, string myUserName, int myRankPoints, Action<RoomStatePacket> onJoined)
    {
        if (room == null || room.slots == null)
        {
            onJoined?.Invoke(null);
            yield break;
        }

        // Đọc lại snapshot mới nhất của phòng trước khi tham gia
        RoomStatePacket latestRoom = null;
        yield return PollRoomState(room.roomId, (fresh) => { latestRoom = fresh; });

        if (latestRoom == null || latestRoom.status != "WAITING")
        {
            onJoined?.Invoke(null);
            yield break;
        }

        // Tìm slot trống: Slot 2 (Phượng đối thủ) -> Slot 3 (Rồng đồng đội) -> Slot 4 (Phượng)
        RoomSlotData targetSlot = null;
        for (int i = 0; i < latestRoom.slots.Count; i++)
        {
            if (latestRoom.slots[i].isEmpty)
            {
                targetSlot = latestRoom.slots[i];
                targetSlot.userId = myUserId;
                targetSlot.userName = myUserName;
                targetSlot.rankPoints = myRankPoints;
                targetSlot.isAI = false;
                break;
            }
        }

        if (targetSlot == null)
        {
            onJoined?.Invoke(null); // Phòng đã đầy
            yield break;
        }

        latestRoom.version++;
        latestRoom.updateTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        string docId = GetDeterministicDocId("r_", latestRoom.roomId);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";
        string compactStr = EncodeRoomString(latestRoom);

        string patchUrl = $"{docsUrl}/{docId}";
        string patchJson = BuildPatchJson("ROOM_WAITING", compactStr, latestRoom.hostRankPoints, latestRoom.updateTimestamp);

        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 3;
            yield return patchReq.SendWebRequest();

            if (patchReq.result == UnityWebRequest.Result.Success)
            {
                onJoined?.Invoke(latestRoom);
            }
            else
            {
                onJoined?.Invoke(null);
            }
        }
    }

    /// <summary>
    /// Guest hủy tìm trận: Xóa slot của mình trên phòng để không để lại slot ma.
    /// </summary>
    public static IEnumerator LeaveRoomSlot(string roomId, string myUserId, Action<bool> onLeft = null)
    {
        if (string.IsNullOrEmpty(roomId) || string.IsNullOrEmpty(myUserId))
        {
            onLeft?.Invoke(false);
            yield break;
        }

        RoomStatePacket currentRoom = null;
        yield return PollRoomState(roomId, (fresh) => { currentRoom = fresh; });

        if (currentRoom != null && currentRoom.status == "WAITING")
        {
            bool modified = false;
            foreach (var s in currentRoom.slots)
            {
                if (s.userId == myUserId)
                {
                    s.userId = "empty";
                    s.userName = "";
                    s.rankPoints = 0;
                    s.isAI = false;
                    modified = true;
                }
            }

            if (modified)
            {
                currentRoom.version++;
                currentRoom.updateTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                string docId = GetDeterministicDocId("r_", roomId);
                string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";
                string compactStr = EncodeRoomString(currentRoom);

                string patchUrl = $"{docsUrl}/{docId}";
                string patchJson = BuildPatchJson("ROOM_WAITING", compactStr, currentRoom.hostRankPoints, currentRoom.updateTimestamp);

                using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
                {
                    patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
                    patchReq.downloadHandler = new DownloadHandlerBuffer();
                    AddAppwriteHeaders(patchReq);
                    patchReq.timeout = 2;
                    yield return patchReq.SendWebRequest();
                    onLeft?.Invoke(patchReq.result == UnityWebRequest.Result.Success);
                    yield break;
                }
            }
        }

        onLeft?.Invoke(true);
    }

    public static IEnumerator PollRoomState(string roomId, Action<RoomStatePacket> onState)
    {
        if (string.IsNullOrEmpty(roomId))
        {
            onState?.Invoke(null);
            yield break;
        }

        string docId = GetDeterministicDocId("r_", roomId);
        string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";

        using (var req = UnityWebRequest.Get(getUrl))
        {
            AddAppwriteHeaders(req);
            req.timeout = 3;
            yield return req.SendWebRequest();

            if (req.result == UnityWebRequest.Result.Success)
            {
                var doc = JsonUtility.FromJson<AppwriteDocument>(req.downloadHandler.text);
                if (doc != null && !string.IsNullOrWhiteSpace(doc.userName))
                {
                    var r = DecodeRoomString(doc.userName, doc.timestamp, doc.rankPoints);
                    onState?.Invoke(r);
                    yield break;
                }
            }
        }

        onState?.Invoke(null);
    }

    public static IEnumerator UpdateRoomState(RoomStatePacket room, Action<bool> onUpdated = null)
    {
        room.updateTimestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        room.version++;
        string docId = GetDeterministicDocId("r_", room.roomId);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";
        string compactStr = EncodeRoomString(room);
        string userType = (room.status == "STARTED") ? "ROOM_STARTED" : ((room.status == "FINISHED") ? "ROOM_FINISHED" : "ROOM_WAITING");

        string patchUrl = $"{docsUrl}/{docId}";
        string patchJson = BuildPatchJson(userType, compactStr, room.hostRankPoints, room.updateTimestamp);

        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 3;
            yield return patchReq.SendWebRequest();

            onUpdated?.Invoke(patchReq.result == UnityWebRequest.Result.Success);
        }
    }

    /// <summary>
    /// Xóa toàn bộ 10 document slots của phòng đấu để giải phóng cơ sở dữ liệu.
    /// </summary>
    public static IEnumerator DeleteRoom(string roomId)
    {
        if (string.IsNullOrEmpty(roomId)) yield break;
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";

        // 1. Xóa room doc
        string rDocId = GetDeterministicDocId("r_", roomId);
        Coroutiner.Start(DeleteDocumentAsync(rDocId));

        // 2. Xóa draft state doc
        string dsDocId = GetDeterministicDocId("ds_", roomId);
        Coroutiner.Start(DeleteDocumentAsync(dsDocId));

        // 3. Xóa 4 draft action docs & 4 battle action docs
        for (int seat = 1; seat <= 4; seat++)
        {
            string daDocId = GetDeterministicDocId("da_", roomId + "_" + seat);
            Coroutiner.Start(DeleteDocumentAsync(daDocId));

            string baDocId = GetDeterministicDocId("ba_", roomId + "_" + seat);
            Coroutiner.Start(DeleteDocumentAsync(baDocId));
        }

        yield return new WaitForSecondsRealtime(0.2f);
    }
    #endregion

    #region 2. DRAFT AUTHORITATIVE HOST PROTOCOL (40S DRAFT, SEQUENTIAL SYNC)
    public static IEnumerator SendDraftHostState(DraftHostStatePacket state, Action<bool> onSent = null)
    {
        state.timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        string docId = GetDeterministicDocId("ds_", state.roomId);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";

        // Định dạng chuẩn: DSTATE:{roomId}:{seq}:{phase}:{pickerIdx}:{seat}:{timer}:{countdown}:{h1},{h2},{h3},{h4}
        string timerStr = state.timerLeft.ToString("0.0", CultureInfo.InvariantCulture);
        string heroesStr = $"{state.heroId1},{state.heroId2},{state.heroId3},{state.heroId4}";
        string compactState = $"DSTATE:{SafeEscape(state.roomId)}:{state.seq}:{SafeEscape(state.phase)}:{state.currentPickerIndex}:{state.currentSeatNumber}:{timerStr}:{state.countdownSec}:{heroesStr}";

        string patchUrl = $"{docsUrl}/{docId}";
        string patchJson = BuildPatchJson("DRAFT_STATE", compactState, state.currentPickerIndex, state.timestamp);

        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 2;
            yield return patchReq.SendWebRequest();

            if (patchReq.result == UnityWebRequest.Result.Success)
            {
                onSent?.Invoke(true);
                yield break;
            }
        }

        string createJson = BuildCreateJson(docId, "DRAFT_STATE", compactState, state.currentPickerIndex, state.timestamp);
        using (var postReq = new UnityWebRequest(docsUrl, "POST"))
        {
            postReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(createJson));
            postReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(postReq);
            postReq.timeout = 2;
            yield return postReq.SendWebRequest();
            onSent?.Invoke(postReq.result == UnityWebRequest.Result.Success);
        }
    }

    public static IEnumerator PollDraftHostState(string roomId, Action<DraftHostStatePacket> onState)
    {
        if (string.IsNullOrEmpty(roomId)) { onState?.Invoke(null); yield break; }
        string docId = GetDeterministicDocId("ds_", roomId);
        string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";

        using (var req = UnityWebRequest.Get(getUrl))
        {
            AddAppwriteHeaders(req);
            req.timeout = 3;
            yield return req.SendWebRequest();

            if (req.result == UnityWebRequest.Result.Success)
            {
                var doc = JsonUtility.FromJson<AppwriteDocument>(req.downloadHandler.text);
                if (doc != null && !string.IsNullOrWhiteSpace(doc.userName) && doc.userName.StartsWith("DSTATE:"))
                {
                    string[] parts = doc.userName.Split(':');
                    if (parts.Length >= 8)
                    {
                                                string rId = SafeUnescape(parts[1]);
                        int packetSeq = 0;
                        string ph = "";
                        int pIdx = 0;
                        int sNum = 0;
                        float tLeft = 0f;
                        int cSec = 0;
                        string hStr = "";

                        if (parts.Length >= 9 && int.TryParse(parts[2], out packetSeq))
                        {
                            ph = SafeUnescape(parts[3]);
                            pIdx = SafeParseInt(parts[4], 0);
                            sNum = SafeParseInt(parts[5], 1);
                            tLeft = SafeParseFloat(parts[6], 40f);
                            cSec = SafeParseInt(parts[7], 0);
                            hStr = parts[8];
                        }
                        else
                        {
                            ph = SafeUnescape(parts[2]);
                            pIdx = SafeParseInt(parts[3], 0);
                            sNum = SafeParseInt(parts[4], 1);
                            tLeft = SafeParseFloat(parts[5], 40f);
                            cSec = SafeParseInt(parts[6], 0);
                            hStr = parts[7];
                        }

                        if (rId == roomId)
                        {
                            var state = new DraftHostStatePacket
                            {
                                roomId = rId,
                                seq = packetSeq,
                                phase = ph,
                                currentPickerIndex = pIdx,
                                currentSeatNumber = sNum,
                                timerLeft = tLeft,
                                countdownSec = cSec,
                                timestamp = doc.timestamp
                            };
                            string[] hIds = hStr.Split(',');
                            if (hIds.Length >= 4)
                            {
                                state.heroId1 = SafeParseInt(hIds[0], 0);
                                state.heroId2 = SafeParseInt(hIds[1], 0);
                                state.heroId3 = SafeParseInt(hIds[2], 0);
                                state.heroId4 = SafeParseInt(hIds[3], 0);
                            }
                            onState?.Invoke(state);
                            yield break;
                        }
                    }
                }
            }
        }
        onState?.Invoke(null);
    }

    public static IEnumerator SendDraftPlayerAction(DraftPlayerActionPacket act, Action<bool> onSent = null)
    {
        act.timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        string docId = GetDeterministicDocId("da_", act.roomId + "_" + act.seatNumber);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";

        // Format: DACT:{roomId}:{seq}:{senderUserId}:{seatNumber}:{requestedHeroId}
        string compactAct = $"DACT:{SafeEscape(act.roomId)}:{act.seq}:{SafeEscape(act.senderUserId)}:{act.seatNumber}:{act.requestedHeroId}";

        string patchUrl = $"{docsUrl}/{docId}";
        string patchJson = BuildPatchJson("DRAFT_ACT", compactAct, act.requestedHeroId, act.timestamp);

        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 2;
            yield return patchReq.SendWebRequest();

            if (patchReq.result == UnityWebRequest.Result.Success)
            {
                onSent?.Invoke(true);
                yield break;
            }
        }

        string createJson = BuildCreateJson(docId, "DRAFT_ACT", compactAct, act.requestedHeroId, act.timestamp);
        using (var postReq = new UnityWebRequest(docsUrl, "POST"))
        {
            postReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(createJson));
            postReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(postReq);
            postReq.timeout = 2;
            yield return postReq.SendWebRequest();
            onSent?.Invoke(postReq.result == UnityWebRequest.Result.Success);
        }
    }

    public static IEnumerator PollDraftPlayerActions(string roomId, Action<List<DraftPlayerActionPacket>> onActions)
    {
        var actions = new List<DraftPlayerActionPacket>();
        if (string.IsNullOrEmpty(roomId)) { onActions?.Invoke(actions); yield break; }

        for (int seat = 1; seat <= 4; seat++)
        {
            string docId = GetDeterministicDocId("da_", roomId + "_" + seat);
            string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";

            using (var req = UnityWebRequest.Get(getUrl))
            {
                AddAppwriteHeaders(req);
                req.timeout = 2;
                yield return req.SendWebRequest();

                if (req.result == UnityWebRequest.Result.Success)
                {
                    var doc = JsonUtility.FromJson<AppwriteDocument>(req.downloadHandler.text);
                    if (doc != null && !string.IsNullOrWhiteSpace(doc.userName) && doc.userName.StartsWith("DACT:"))
                    {
                        string[] parts = doc.userName.Split(':');
                        if (parts.Length >= 5)
                        {
                            string rId = SafeUnescape(parts[1]);
                            if (rId == roomId)
                            {
                                int pSeq = (parts.Length >= 6) ? SafeParseInt(parts[2], 0) : 0;
                                string sUid = (parts.Length >= 6) ? SafeUnescape(parts[3]) : SafeUnescape(parts[2]);
                                int sNum = (parts.Length >= 6) ? SafeParseInt(parts[4], seat) : SafeParseInt(parts[3], seat);
                                int hId = (parts.Length >= 6) ? SafeParseInt(parts[5], 0) : SafeParseInt(parts[4], 0);

                                actions.Add(new DraftPlayerActionPacket
                                {
                                    roomId = rId,
                                    seq = pSeq,
                                    senderUserId = sUid,
                                    seatNumber = sNum,
                                    requestedHeroId = hId,
                                    timestamp = doc.timestamp
                                });
                            }
                        }
                    }
                }
            }
        }

        onActions?.Invoke(actions);
    }
    #endregion

    #region 3. BATTLE ACTIONS SYNCHRONIZATION (BOUNDED FIXED SLOTS, FULL METADATA)
    public static IEnumerator SendBattleAction(BattleActionPacket act, Action<bool> onSent = null)
    {
        act.timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        if (string.IsNullOrEmpty(act.nonce)) act.nonce = Guid.NewGuid().ToString("N").Substring(0, 6);
        string docId = GetDeterministicDocId("ba_", act.roomId + "_" + act.casterSeat);
        string docsUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents";

        // Định dạng đầy đủ metadata: BACT:{roomId}:{seq}:{casterSeat}:{targetSeat}:{actionType}:{cardId}:{accepted}:{nonce}:{senderUserId}
        string compactBact = $"BACT:{SafeEscape(act.roomId)}:{act.seq}:{act.casterSeat}:{act.targetSeat}:{SafeEscape(act.actionType)}:{SafeEscape(act.cardId)}:{(act.accepted ? 1 : 0)}:{SafeEscape(act.nonce)}:{SafeEscape(act.senderUserId)}";

        string patchUrl = $"{docsUrl}/{docId}";
        string patchJson = BuildPatchJson("BATTLE_ACT", compactBact, act.casterSeat, act.timestamp);

        using (var patchReq = new UnityWebRequest(patchUrl, "PATCH"))
        {
            patchReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(patchJson));
            patchReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(patchReq);
            patchReq.timeout = 2;
            yield return patchReq.SendWebRequest();

            if (patchReq.result == UnityWebRequest.Result.Success)
            {
                onSent?.Invoke(true);
                yield break;
            }
        }

        string createJson = BuildCreateJson(docId, "BATTLE_ACT", compactBact, act.casterSeat, act.timestamp);
        using (var postReq = new UnityWebRequest(docsUrl, "POST"))
        {
            postReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(createJson));
            postReq.downloadHandler = new DownloadHandlerBuffer();
            AddAppwriteHeaders(postReq);
            postReq.timeout = 2;
            yield return postReq.SendWebRequest();
            onSent?.Invoke(postReq.result == UnityWebRequest.Result.Success);
        }
    }

    public static IEnumerator PollBattleActions(string roomId, Action<List<BattleActionPacket>> onActions)
    {
        return PollBattleActions(roomId, 0, onActions);
    }

    public static IEnumerator PollBattleActions(string roomId, long sinceTimestamp, Action<List<BattleActionPacket>> onActions)
    {
        var actions = new List<BattleActionPacket>();
        if (string.IsNullOrEmpty(roomId)) { onActions?.Invoke(actions); yield break; }

        for (int seat = 1; seat <= 4; seat++)
        {
            string docId = GetDeterministicDocId("ba_", roomId + "_" + seat);
            string getUrl = $"{Endpoint}/databases/{DatabaseId}/collections/{CollectionId}/documents/{docId}";

            using (var req = UnityWebRequest.Get(getUrl))
            {
                AddAppwriteHeaders(req);
                req.timeout = 2;
                yield return req.SendWebRequest();

                if (req.result == UnityWebRequest.Result.Success)
                {
                    var doc = JsonUtility.FromJson<AppwriteDocument>(req.downloadHandler.text);
                    if (doc != null && !string.IsNullOrWhiteSpace(doc.userName) && doc.userName.StartsWith("BACT:") && doc.timestamp > sinceTimestamp)
                    {
                        string[] parts = doc.userName.Split(':');
                        if (parts.Length >= 8)
                        {
                            string rId = SafeUnescape(parts[1]);
                            if (rId == roomId)
                            {
                                int bSeq = SafeParseInt(parts[2], 0);
                                int cSeat = SafeParseInt(parts[3], seat);
                                int tSeat = SafeParseInt(parts[4], 0);
                                string aType = SafeUnescape(parts[5]);
                                string cId = SafeUnescape(parts[6]);
                                bool acc = (parts[7] == "1");
                                string nce = (parts.Length >= 9) ? SafeUnescape(parts[8]) : "";
                                string sUid = (parts.Length >= 10) ? SafeUnescape(parts[9]) : "";

                                actions.Add(new BattleActionPacket
                                {
                                    roomId = rId,
                                    seq = bSeq,
                                    casterSeat = cSeat,
                                    targetSeat = tSeat,
                                    actionType = aType,
                                    cardId = cId,
                                    accepted = acc,
                                    nonce = nce,
                                    senderUserId = sUid,
                                    timestamp = doc.timestamp
                                });
                            }
                        }
                    }
                }
            }
        }

        onActions?.Invoke(actions);
    }
    #endregion

    #region 4. SERVERLESS GAME ENGINE & STATE SYNC
    public const string GameEngineFunctionId = "game-engine";
    public const string DenoEndpoint = "https://dai-viet-chien-server.vdthanh.deno.net";

    /// <summary>
    /// Legacy shim: game state is server-owned and must never be written by Unity.
    /// </summary>
    public static IEnumerator SaveServerGameState(string roomId, ServerGameState state, Action<bool> onSaved = null)
    {
        onSaved?.Invoke(false);
        yield break;
    }

    /// <summary>
    /// Đọc GameState qua authoritative Deno/Appwrite Function, never from the
    /// private persistence document.
    /// </summary>
    public static IEnumerator PollServerGameState(string roomId, Action<ServerGameState> onState, int requestingSeat = 0)
    {
        if (string.IsNullOrEmpty(roomId)) { onState?.Invoke(null); yield break; }
        yield return ExecuteGameEngineAction(new GameActionPayload
        {
            action = "GET_STATE",
            roomId = roomId,
            seat = requestingSeat
        }, onState);
    }

    public static int currentServerStateVersion = 0;

    /// <summary>
    /// Gửi Action lên Appwrite Cloud Function (hoặc fallback sang DB Document nếu Function chưa setup)
    /// </summary>
    public static IEnumerator ExecuteGameEngineAction(GameActionPayload actionPayload, Action<ServerGameState> onResult)
{
    if (actionPayload == null || string.IsNullOrEmpty(actionPayload.roomId)) { onResult?.Invoke(null); yield break; }

    // Version check bypassed to avoid conflict with SERVER_TICK

    string actionBody = JsonUtility.ToJson(actionPayload);

    // 1. Thử các Deno Engine Endpoints (Active Connected, Localhost, Cloud)
    List<string> candidateDenoUrls = new List<string>();
    if (!string.IsNullOrEmpty(DenoGameClient.ActiveConnectedEndpoint))
    {
        string baseEp = DenoGameClient.ActiveConnectedEndpoint.Replace("wss://", "https://").Replace("ws://", "http://");
        candidateDenoUrls.Add($"{baseEp}/api/game-engine");
    }
    if (!candidateDenoUrls.Contains("http://127.0.0.1:8082/api/game-engine"))
    {
        candidateDenoUrls.Add("http://127.0.0.1:8082/api/game-engine");
    }
    if (!string.IsNullOrEmpty(DenoEndpoint) && !candidateDenoUrls.Contains($"{DenoEndpoint}/api/game-engine"))
    {
        candidateDenoUrls.Add($"{DenoEndpoint}/api/game-engine");
    }

    foreach (var denoUrl in candidateDenoUrls)
    {
        using (var denoReq = new UnityWebRequest(denoUrl, "POST"))
        {
            denoReq.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(actionBody));
            denoReq.downloadHandler = new DownloadHandlerBuffer();
            denoReq.SetRequestHeader("Content-Type", "application/json");
            denoReq.timeout = 2; // Timeout 2s nhanh để kịp fallback
            yield return denoReq.SendWebRequest();

            if (denoReq.result == UnityWebRequest.Result.Success && !string.IsNullOrEmpty(denoReq.downloadHandler?.text))
            {
                string respText = denoReq.downloadHandler.text.Trim();
                if (respText.StartsWith("{") && respText.EndsWith("}"))
                {
                    try
                    {
                        var stateResp = JsonUtility.FromJson<GameEngineResponseWrapper>(respText);
                        if (stateResp != null)
                        {
                            if (stateResp.code == "VERSION_CONFLICT")
                            {
                                Debug.LogWarning($"[OptimisticLocking] Version conflict! Server v{stateResp.state?.version}");
                            }
                            if (stateResp.state != null)
                            {
                                currentServerStateVersion = stateResp.state.version;
                                onResult?.Invoke(stateResp.state);
                                yield break;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.LogWarning($"[Deno] Parse error: {ex.Message}. Falling back to Appwrite.");
                    }
                }
            }
        }
    }

    // 2. Fallback: Gửi Appwrite Cloud Function nếu Deno lỗi / mất kết nối
    string functionExecUrl = $"{Endpoint}/functions/{GameEngineFunctionId}/executions";
    string execJson = $"{{\"body\":{JsonEscape(actionBody)},\"async\":false}}";

    using (var req = new UnityWebRequest(functionExecUrl, "POST"))
    {
        req.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(execJson));
        req.downloadHandler = new DownloadHandlerBuffer();
        AddAppwriteHeaders(req);
        req.timeout = 4;
        yield return req.SendWebRequest();

        if (req.result == UnityWebRequest.Result.Success && !string.IsNullOrEmpty(req.downloadHandler?.text))
        {
            string respText = req.downloadHandler.text.Trim();
            if (respText.StartsWith("{") && respText.EndsWith("}"))
            {
                try
                {
                    var execResp = JsonUtility.FromJson<AppwriteFunctionExecutionResponse>(respText);
                    if (execResp != null && !string.IsNullOrEmpty(execResp.responseBody))
                    {
                        string bodyText = execResp.responseBody.Trim();
                        if (bodyText.StartsWith("{") && bodyText.EndsWith("}"))
                        {
                            var stateResp = JsonUtility.FromJson<GameEngineResponseWrapper>(bodyText);
                            if (stateResp != null && stateResp.state != null)
                            {
                                currentServerStateVersion = stateResp.state.version;
                                onResult?.Invoke(stateResp.state);
                                yield break;
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogWarning($"[Appwrite Function] Parse error: {ex.Message}");
                }
            }
        }
    }

    // Do not read the private persistence document from the client. A missing
    // authoritative endpoint is a connection failure, not permission to trust
    // a client-visible database snapshot.
    onResult?.Invoke(null);
}

    [Serializable]
    private class AppwriteFunctionExecutionResponse
    {
        public string responseBody;
        public int responseStatusCode;
    }

    [Serializable]
    private class GameEngineResponseWrapper
    {
        public bool success;
        public string error;
        public string code;
        public ServerGameState state;
        public GameStateDelta delta;
    }
    #endregion

    #region Coroutine Runner Helper
    public class Coroutiner : MonoBehaviour
    {
        private static Coroutiner _instance;
        public static void Start(IEnumerator coroutine)
        {
            if (_instance == null)
            {
                var go = new GameObject("Appwrite_Coroutiner");
                UnityEngine.Object.DontDestroyOnLoad(go);
                _instance = go.AddComponent<Coroutiner>();
            }
            _instance.StartCoroutine(coroutine);
        }
    }
    #endregion

    #region Realistic Gamer Names Pool
    private static readonly string[] RealisticGamerNames = new string[]
    {
        "⚡Hắc_Bạch_Vô_Song⚡",
        "Sát_Thủ_Vô_Tình",
        "Nguyễn_Dương_Pro",
        "Bá_Đạo_Tổng_Tài",
        "Lữ_Bố_Tái_Thế",
        "Thần_Kiếm_888",
        "Bảo_Bối_Cute",
        "Phong_Thần_2004",
        "Trọng_Nghĩa_SG",
        "Hải_Quay_Xe",
        "Cửu_Vĩ_Hồ",
        "Vô_Danh_Cư_Sĩ",
        "Long_Thần_Bất_Bại",
        "Tiểu_Long_Nữ_03",
        "Phượng_Hoàng_Lửa",
        "Bất_Khả_Chiến_Bại",
        "Vương_Gia_99",
        "Độc_Cô_Cầu_Bại",
        "Gia_Cát_Lượng_VN",
        "Bóng_Đêm_Tử_Thần",
        "Triệu_Vân_Tái_Thế",
        "Thánh_Kiếm_Đại_Việt",
        "Hiệp_Sĩ_Mù",
        "Cố_Nhân_Tình",
        "Bạch_Mã_Hoàng_Tử",
        "Tiểu_Muội_Dễ_Thương",
        "Chiến_Thần_Hà_Nội",
        "Vô_Cực_Kiếm",
        "Đao_Kiếm_Vô_Tình",
        "Chân_Mệnh_Thiên_Tử",
        "Hào_Khí_Đông_A",
        "Sơn_Hà_Xã_Tắc",
        "Ngọa_Long_Tiên_Sinh",
        "Kiếm_Vương_Vô_Song",
        "Nhất_Kích_Tất_Sát",
        "Bạch_Hổ_Tướng_Quân",
        "Thần_Điêu_Đại_Hiệp",
        "Ngũ_Hổ_Tướng",
        "Thiên_Hạ_Đệ_Nhất",
        "Trấn_Bắc_Vương"
    };

    public static string GetRealisticGamerName(int seed, HashSet<string> excludeNames = null)
    {
        var rng = new System.Random(seed);
        var shuffled = new List<string>(RealisticGamerNames);
        for (int i = shuffled.Count - 1; i > 0; i--)
        {
            int k = rng.Next(i + 1);
            var temp = shuffled[i];
            shuffled[i] = shuffled[k];
            shuffled[k] = temp;
        }

        foreach (var name in shuffled)
        {
            if (excludeNames == null || !excludeNames.Contains(name))
            {
                excludeNames?.Add(name);
                return name;
            }
        }
        return "Chiến Tướng " + rng.Next(100, 999);
    }
    #endregion
}



