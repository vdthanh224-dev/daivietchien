extends Node

## Hệ thống Tìm Trận 2v2 Thời Gian Thực trên Appwrite Database Singapore
## Tương thích 100% với giao thức Unity AppwriteMatchmaking.cs:
## Bounded Document Slots, FNV-1a Hash, Safe Compact Serialization.

const ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
const PROJECT_ID = "6a885457002da3f3d47e"
const DATABASE_ID = "game"
const COLLECTION_ID = "matchmaking_queue"

const PUBLIC_DOC_PERMISSIONS = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"]

const REALISTIC_GAMER_NAMES = [
	"Bá_Đạo_Tổng_Tài", "Lữ_Bố_Tái_Thế", "Thần_Kiếm_888", "Bảo_Bối_Cute",
	"Phong_Thần_2004", "Trọng_Nghĩa_SG", "Hải_Quay_Xe", "Cửu_Vĩ_Hồ",
	"Vô_Danh_Cư_Sĩ", "Long_Thần_Bất_Bại", "Tiểu_Long_Nữ_03", "Phượng_Hoàng_Lửa",
	"Bất_Khả_Chiến_Bại", "Vương_Gia_99", "Độc_Cô_Cầu_Bại", "Gia_Cát_Lượng_VN",
	"Bóng_Đêm_Tử_Thần", "Triệu_Vân_Tái_Thế", "Thánh_Kiếm_Đại_Việt", "Hiệp_Sĩ_Mù",
	"Cố_Nhân_Tình", "Bạch_Mã_Hoàng_Tử", "Tiểu_Muội_Dễ_Thương", "Chiến_Thần_Hà_Nội",
	"Vô_Cực_Kiếm", "Đao_Kiếm_Vô_Tình", "Chân_Mệnh_Thiên_Tử", "Hào_Khí_Đông_A",
	"Sơn_Hà_Xã_Tắc", "Ngọa_Long_Tiên_Sinh", "Kiếm_Vương_Vô_Song", "Nhất_Kích_Tất_Sát",
	"Bạch_Hổ_Tướng_Quân", "Thần_Điêu_Đại_Hiệp", "Ngũ_Hổ_Tướng", "Thiên_Hạ_Đệ_Nhất",
	"Trấn_Bắc_Vương"
]

func get_now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

func get_deterministic_doc_id(prefix: String, raw_id: String) -> String:
	if raw_id.is_empty():
		raw_id = str(randi())
	var md5_str = raw_id.md5_text()
	var p = "u_" if prefix.is_empty() else prefix
	var full_id = p + md5_str
	return full_id.substr(0, mini(32, full_id.length()))

func sanitize(text: String, max_len: int = 24) -> String:
	if text.is_empty():
		return ""
	var clean = text.replace("|", "_").replace(":", "_").replace(",", "_").strip_edges()
	if clean.length() > max_len:
		return clean.substr(0, max_len)
	return clean

func get_deterministic_hash_code(s: String) -> int:
	if s.is_empty():
		return 0
	var hash_val: int = 2166136261
	var bytes = s.to_utf8_buffer()
	for b in bytes:
		hash_val = ((hash_val ^ b) * 16777619) & 0x7FFFFFFF
	return hash_val

func get_realistic_gamer_name(seed_val: int, exclude_names: Array = []) -> String:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var names = REALISTIC_GAMER_NAMES.duplicate()
	# Fisher-Yates shuffle
	for i in range(names.size() - 1, 0, -1):
		var k = rng.randi_range(0, i)
		var tmp = names[i]
		names[i] = names[k]
		names[k] = tmp

	for n in names:
		if not exclude_names.has(n):
			exclude_names.append(n)
			return n
	return "Chiến Tướng %d" % rng.randi_range(100, 999)

# --- Encoding & Decoding Room State ---
func encode_room_string(room: Dictionary) -> String:
	var r_id = sanitize(room.get("roomId", ""), 18)
	var h_uid = sanitize(room.get("hostUserId", ""), 24)
	var st = sanitize(room.get("status", "WAITING"), 10)
	var ver = int(room.get("version", 1))

	var parts: Array[String] = ["ROOM4", r_id, h_uid, st, str(ver)]
	var slots = room.get("slots", [])

	for i in range(4):
		if i < slots.size():
			var s = slots[i]
			var is_empty = bool(s.get("isEmpty", false)) or s.get("userId", "") == "" or s.get("userId", "") == "empty"
			var uid = "empty" if is_empty else sanitize(s.get("userId", ""), 24)
			var uname = "" if is_empty else sanitize(s.get("userName", ""), 14)
			var rp = int(s.get("rankPoints", 0))
			var is_drag = 1 if bool(s.get("isDragon", (i == 0 or i == 2))) else 0
			var is_ai = 1 if bool(s.get("isAI", false)) else 0
			parts.append("%s,%s,%d,%d,%d" % [uid, uname, rp, is_drag, is_ai])
		else:
			var is_drag = 1 if (i == 0 or i == 2) else 0
			parts.append("empty,,0,%d,0" % is_drag)

	return "|".join(parts)

func decode_room_string(raw_str: String, doc_timestamp: int = 0, host_rp: int = 0) -> Dictionary:
	if raw_str.is_empty() or not raw_str.begins_with("ROOM4|"):
		return {}
	var parts = raw_str.split("|")
	if parts.size() < 8:
		return {}

	var ver = 0
	var slot_start_idx = 5
	if parts.size() >= 9 and parts[4].is_valid_int():
		ver = int(parts[4])
		slot_start_idx = 5
	else:
		slot_start_idx = 4

	var room: Dictionary = {
		"roomId": parts[1],
		"hostUserId": parts[2],
		"status": parts[3],
		"version": ver,
		"hostTimestamp": doc_timestamp,
		"updateTimestamp": doc_timestamp,
		"hostRankPoints": host_rp,
		"slots": []
	}

	for i in range(slot_start_idx, mini(parts.size(), slot_start_idx + 4)):
		var sub = parts[i].split(",")
		var uid = sub[0] if sub.size() > 0 else "empty"
		var uname = sub[1] if sub.size() > 1 else ""
		var rp = int(sub[2]) if sub.size() > 2 and sub[2].is_valid_int() else 0
		var seat_idx = i - slot_start_idx + 1
		var is_drag = (seat_idx == 1 or seat_idx == 3)
		if sub.size() > 3:
			is_drag = (sub[3] == "1")
		var is_ai = (sub.size() > 4 and sub[4] == "1")
		var is_empty = (uid == "" or uid == "empty")

		room["slots"].append({
			"seatNumber": seat_idx,
			"userId": uid,
			"userName": uname,
			"rankPoints": rp,
			"isDragon": is_drag,
			"isAI": is_ai,
			"isEmpty": is_empty
		})

	return room

# --- HTTP Request Coroutine Helpers ---
func _send_http_request(url: String, method: int, body_json: String = "") -> Dictionary:
	var http = HTTPRequest.new()
	add_child(http)

	var headers = PackedStringArray([
		"Content-Type: application/json",
		"X-Appwrite-Project: " + PROJECT_ID
	])
	if AuthManager:
		if AuthManager.session_secret != "":
			headers.append("X-Appwrite-Session: " + AuthManager.session_secret)
		if AuthManager.session_cookie != "":
			headers.append("Cookie: " + AuthManager.session_cookie)

	var err = http.request(url, headers, method, body_json)
	if err != OK:
		http.queue_free()
		return {"code": 0, "data": null, "raw": ""}

	var resp = await http.request_completed
	http.queue_free()

	var response_code = resp[1]
	var resp_body_bytes: PackedByteArray = resp[3]
	var raw_text = resp_body_bytes.get_string_from_utf8()

	var data = null
	if raw_text.length() > 0:
		var json = JSON.new()
		if json.parse(raw_text) == OK:
			data = json.get_data()

	return {
		"code": response_code,
		"data": data,
		"raw": raw_text
	}

# --- 1. Find Best Waiting Room ---
func find_best_waiting_room(my_user_id: String, my_rank_points: int, max_rank_diff: int = 500) -> Dictionary:
	var q_equal = "{\"method\":\"equal\",\"attribute\":\"userId\",\"values\":[\"ROOM_WAITING\"]}".uri_encode()
	var q_order = "{\"method\":\"orderDesc\",\"attribute\":\"$createdAt\"}".uri_encode()
	var q_limit = "{\"method\":\"limit\",\"values\":[100]}".uri_encode()
	var get_url = "%s/databases/%s/collections/%s/documents?queries[0]=%s&queries[1]=%s&queries[2]=%s" % [
		ENDPOINT, DATABASE_ID, COLLECTION_ID, q_equal, q_order, q_limit
	]

	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] != 200 or res["data"] == null:
		return {}

	var doc_list = res["data"].get("documents", [])
	var now = get_now_ms()
	var best_room: Dictionary = {}
	var min_diff = 999999

	for doc in doc_list:
		if doc == null:
			continue
		var doc_time = int(doc.get("timestamp", 0))
		var age = now - doc_time
		var user_name_val = doc.get("userName", "")

		# Clean up dead documents older than 3 minutes (180s)
		if age > 180000 and user_name_val.length() > 0:
			var doc_id = doc.get("$id", "")
			if not doc_id.is_empty():
				_delete_document_async(doc_id)
			continue

		# Only consider active rooms waiting within 45s
		if age > 45000:
			continue

		var r = decode_room_string(user_name_val, doc_time, int(doc.get("rankPoints", 0)))
		if r.is_empty() or r.get("status") != "WAITING":
			continue

		# Host cannot be self
		if r.get("hostUserId") == my_user_id:
			continue

		# Must have empty slot
		var has_empty = false
		for s in r.get("slots", []):
			if s.get("isEmpty", false):
				has_empty = true
				break

		if has_empty:
			var diff = abs(int(r.get("hostRankPoints", 0)) - my_rank_points)
			if diff < min_diff and diff <= max_rank_diff:
				min_diff = diff
				best_room = r

	return best_room

# --- 2. Create Waiting Room ---
func create_waiting_room(room: Dictionary) -> bool:
	var now = get_now_ms()
	room["updateTimestamp"] = now
	room["version"] = 1
	var doc_id = get_deterministic_doc_id("r_", room.get("roomId", ""))
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]
	var compact_str = encode_room_string(room)

	var payload = {
		"documentId": doc_id,
		"data": {
			"userId": "ROOM_WAITING",
			"userName": compact_str,
			"rankPoints": int(room.get("hostRankPoints", 0)),
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}

	var res = await _send_http_request(docs_url, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if res["code"] == 201 or res["code"] == 200:
		return true

	# If already exists (409 conflict), fallback to patch
	if res["code"] == 409:
		var patch_url = docs_url + "/" + doc_id
		var patch_payload = {
			"data": payload["data"],
			"permissions": PUBLIC_DOC_PERMISSIONS
		}
		var p_res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(patch_payload))
		return (p_res["code"] == 200)

	return false

# --- 3. Join Room Slot ---
func join_room_slot(room: Dictionary, my_user_id: String, my_user_name: String, my_rank_points: int) -> Dictionary:
	if room.is_empty():
		return {}

	# Read fresh snapshot
	var latest_room = await poll_room_state(room.get("roomId", ""))
	if latest_room.is_empty() or latest_room.get("status") != "WAITING":
		return {}

	var slots = latest_room.get("slots", [])
	var target_slot: Dictionary = {}
	for s in slots:
		if s.get("isEmpty", false):
			target_slot = s
			s["userId"] = my_user_id
			s["userName"] = my_user_name
			s["rankPoints"] = my_rank_points
			s["isAI"] = false
			s["isEmpty"] = false
			break

	if target_slot.is_empty():
		return {} # Room is full

	latest_room["version"] = int(latest_room.get("version", 1)) + 1
	var now = get_now_ms()
	latest_room["updateTimestamp"] = now

	var doc_id = get_deterministic_doc_id("r_", latest_room.get("roomId", ""))
	var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var compact_str = encode_room_string(latest_room)

	var payload = {
		"data": {
			"userId": "ROOM_WAITING",
			"userName": compact_str,
			"rankPoints": int(latest_room.get("hostRankPoints", 0)),
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}

	var res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(payload))
	if res["code"] == 200:
		return latest_room
	return {}

# --- 4. Poll Room State ---
func poll_room_state(room_id: String) -> Dictionary:
	if room_id.is_empty():
		return {}

	var doc_id = get_deterministic_doc_id("r_", room_id)
	var get_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]

	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] == 200 and res["data"] != null:
		var doc = res["data"]
		var uname = doc.get("userName", "")
		if uname.length() > 0:
			return decode_room_string(uname, int(doc.get("timestamp", 0)), int(doc.get("rankPoints", 0)))

	return {}

# --- 5. Update Room State ---
func update_room_state(room: Dictionary) -> bool:
	var now = get_now_ms()
	room["updateTimestamp"] = now
	room["version"] = int(room.get("version", 1)) + 1

	var doc_id = get_deterministic_doc_id("r_", room.get("roomId", ""))
	var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var compact_str = encode_room_string(room)

	var st = room.get("status", "WAITING")
	var user_type = "ROOM_STARTED" if st == "STARTED" else ("ROOM_FINISHED" if st == "FINISHED" else "ROOM_WAITING")

	var payload = {
		"data": {
			"userId": user_type,
			"userName": compact_str,
			"rankPoints": int(room.get("hostRankPoints", 0)),
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}

	var res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(payload))
	return (res["code"] == 200)

# --- 6. Send Host Heartbeat ---
func send_host_heartbeat(room_id: String) -> void:
	if room_id.is_empty():
		return
	var now = get_now_ms()
	var doc_id = get_deterministic_doc_id("r_", room_id)
	var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var payload = {
		"data": {
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}
	_send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(payload))

# --- 7. Leave Room Slot (Guest cancel) ---
func leave_room_slot(room_id: String, my_user_id: String) -> bool:
	if room_id.is_empty() or my_user_id.is_empty():
		return false

	var current_room = await poll_room_state(room_id)
	if not current_room.is_empty() and current_room.get("status") == "WAITING":
		var modified = false
		for s in current_room.get("slots", []):
			if s.get("userId") == my_user_id:
				s["userId"] = "empty"
				s["userName"] = ""
				s["rankPoints"] = 0
				s["isAI"] = false
				s["isEmpty"] = true
				modified = true

		if modified:
			return await update_room_state(current_room)

	return true

# --- 8. Delete Room (Host cancel or finish) ---
func delete_room(room_id: String) -> void:
	if room_id.is_empty():
		return
	var r_doc_id = get_deterministic_doc_id("r_", room_id)
	_delete_document_async(r_doc_id)

	var ds_doc_id = get_deterministic_doc_id("ds_", room_id)
	_delete_document_async(ds_doc_id)

	for seat in range(1, 5):
		var da_doc_id = get_deterministic_doc_id("da_", "%s_%d" % [room_id, seat])
		_delete_document_async(da_doc_id)
		var ba_doc_id = get_deterministic_doc_id("ba_", "%s_%d" % [room_id, seat])
		_delete_document_async(ba_doc_id)

func _delete_document_async(doc_id: String) -> void:
	var delete_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	_send_http_request(delete_url, HTTPClient.METHOD_DELETE)
