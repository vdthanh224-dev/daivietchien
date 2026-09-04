extends Node

## Hệ thống Tìm Trận 2v2 Thời Gian Thực trên Appwrite Database Singapore
## Tương thích 100% với giao thức Unity AppwriteMatchmaking.cs:
## Bounded Document Slots, FNV-1a Hash, Safe Compact Serialization.

const ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
const PROJECT_ID = "6a885457002da3f3d47e"
const DATABASE_ID = "game"
const COLLECTION_ID = "matchmaking_queue"

const PUBLIC_DOC_PERMISSIONS = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"]

var current_room: Dictionary = {}

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

func is_same_user(uid1: String, name1: String, uid2: String, name2: String) -> bool:
	if uid1.is_empty() and uid2.is_empty() and name1.is_empty() and name2.is_empty():
		return false
	if uid1 != "" and uid2 != "" and uid1 == uid2:
		return true
	if uid1 != "" and uid2 != "":
		# So khớp tiền tố nếu 1 bên bị cắt ngắn xuống 24 ký tự theo chuẩn ROOM4
		if uid1.length() >= 20 and uid2.begins_with(uid1):
			return true
		if uid2.length() >= 20 and uid1.begins_with(uid2):
			return true
	if name1 != "" and name2 != "" and name1.strip_edges().to_lower() == name2.strip_edges().to_lower():
		return true
	return false

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

	print("[AppwriteMatchmaking] HTTP %d -> Code: %d (%s)" % [method, response_code, url.substr(0, 80)])

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
func find_best_waiting_room(my_user_id: String, my_rank_points: int, max_rank_diff: int = 500, my_user_name: String = "") -> Dictionary:
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

		# Only consider active rooms waiting within 25s
		if age > 25000:
			continue

		var r = decode_room_string(user_name_val, doc_time, int(doc.get("rankPoints", 0)))
		if r.is_empty() or r.get("status") != "WAITING":
			continue

		# Host cannot be self
		if is_same_user(r.get("hostUserId", ""), "", my_user_id, my_user_name):
			continue

		# Self cannot already occupy any slot in this room
		var already_present = false
		for s in r.get("slots", []):
			if not s.get("isEmpty", false):
				if is_same_user(s.get("userId", ""), s.get("userName", ""), my_user_id, my_user_name):
					already_present = true
					break
		if already_present:
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
	# Prevent duplicate self joining
	for s in slots:
		if not s.get("isEmpty", false):
			if is_same_user(s.get("userId", ""), s.get("userName", ""), my_user_id, my_user_name):
				print("[AppwriteMatchmaking] Self already in room, aborting duplicate join")
				return {}

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

# --- 9. Draft State Protocol (Sync 40s Draft between Host and Guests) ---
func send_draft_host_state(state: Dictionary) -> bool:
	var room_id = state.get("roomId", "")
	if room_id.is_empty():
		return false
	var now = get_now_ms()
	var doc_id = get_deterministic_doc_id("ds_", room_id)
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]

	var timer_str = "%.1f" % float(state.get("timerLeft", 40.0))
	var h1 = int(state.get("heroId1", 0))
	var h2 = int(state.get("heroId2", 0))
	var h3 = int(state.get("heroId3", 0))
	var h4 = int(state.get("heroId4", 0))
	var heroes_str = "%d,%d,%d,%d" % [h1, h2, h3, h4]

	var compact_state = "DSTATE:%s:%d:%s:%d:%d:%s:%d:%s" % [
		sanitize(room_id, 18),
		int(state.get("seq", 0)),
		sanitize(state.get("phase", "PICKING"), 14),
		int(state.get("currentPickerIndex", 0)),
		int(state.get("currentSeatNumber", 1)),
		timer_str,
		int(state.get("countdownSec", 0)),
		heroes_str
	]

	var payload = {
		"documentId": doc_id,
		"data": {
			"userId": "DRAFT_STATE",
			"userName": compact_state,
			"rankPoints": int(state.get("currentPickerIndex", 0)),
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}

	var patch_url = "%s/%s" % [docs_url, doc_id]
	var patch_payload = {
		"data": payload["data"],
		"permissions": PUBLIC_DOC_PERMISSIONS
	}
	var p_res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(patch_payload))
	if p_res["code"] == 200:
		return true

	var res = await _send_http_request(docs_url, HTTPClient.METHOD_POST, JSON.stringify(payload))
	return (res["code"] == 201 or res["code"] == 200)

func poll_draft_host_state(room_id: String) -> Dictionary:
	if room_id.is_empty():
		return {}
	var doc_id = get_deterministic_doc_id("ds_", room_id)
	var get_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] == 200 and res["data"] != null:
		var doc = res["data"]
		var uname = doc.get("userName", "")
		if uname.begins_with("DSTATE:"):
			var parts = uname.split(":")
			if parts.size() >= 8:
				var r_id = parts[1]
				if r_id == room_id:
					var p_seq = 0
					var ph = ""
					var p_idx = 0
					var s_num = 1
					var t_left = 40.0
					var c_sec = 0
					var h_str = ""

					if parts.size() >= 9 and parts[2].is_valid_int():
						p_seq = int(parts[2])
						ph = parts[3]
						p_idx = int(parts[4]) if parts[4].is_valid_int() else 0
						s_num = int(parts[5]) if parts[5].is_valid_int() else 1
						t_left = float(parts[6]) if parts[6].is_valid_float() else 40.0
						c_sec = int(parts[7]) if parts[7].is_valid_int() else 0
						h_str = parts[8]
					else:
						ph = parts[2]
						p_idx = int(parts[3]) if parts[3].is_valid_int() else 0
						s_num = int(parts[4]) if parts[4].is_valid_int() else 1
						t_left = float(parts[5]) if parts[5].is_valid_float() else 40.0
						c_sec = int(parts[6]) if parts[6].is_valid_int() else 0
						h_str = parts[7]

					var h_ids = h_str.split(",")
					var hero_ids = [0, 0, 0, 0]
					for k in range(mini(4, h_ids.size())):
						if h_ids[k].is_valid_int():
							hero_ids[k] = int(h_ids[k])

					return {
						"roomId": r_id,
						"seq": p_seq,
						"phase": ph,
						"currentPickerIndex": p_idx,
						"currentSeatNumber": s_num,
						"timerLeft": t_left,
						"countdownSec": c_sec,
						"heroIds": hero_ids,
						"timestamp": int(doc.get("timestamp", 0))
					}
	return {}

func send_draft_player_action(act: Dictionary) -> bool:
	var room_id = act.get("roomId", "")
	var seat_num = int(act.get("seatNumber", 1))
	if room_id.is_empty():
		return false
	var now = get_now_ms()
	var doc_id = get_deterministic_doc_id("da_", "%s_%d" % [room_id, seat_num])
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]

	var compact_act = "DACT:%s:%d:%s:%d:%d" % [
		sanitize(room_id, 18),
		int(act.get("seq", 0)),
		sanitize(act.get("senderUserId", ""), 24),
		seat_num,
		int(act.get("requestedHeroId", 0))
	]

	var payload = {
		"documentId": doc_id,
		"data": {
			"userId": "DRAFT_ACT",
			"userName": compact_act,
			"rankPoints": int(act.get("requestedHeroId", 0)),
			"timestamp": now
		},
		"permissions": PUBLIC_DOC_PERMISSIONS
	}

	var patch_url = "%s/%s" % [docs_url, doc_id]
	var patch_payload = {
		"data": payload["data"],
		"permissions": PUBLIC_DOC_PERMISSIONS
	}
	var p_res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(patch_payload))
	if p_res["code"] == 200:
		return true

	var res = await _send_http_request(docs_url, HTTPClient.METHOD_POST, JSON.stringify(payload))
	return (res["code"] == 201 or res["code"] == 200)

func poll_draft_player_action_for_seat(room_id: String, seat: int) -> Dictionary:
	if room_id.is_empty():
		return {}
	var doc_id = get_deterministic_doc_id("da_", "%s_%d" % [room_id, seat])
	var get_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] == 200 and res["data"] != null:
		var doc = res["data"]
		var uname = doc.get("userName", "")
		if uname.begins_with("DACT:"):
			var parts = uname.split(":")
			if parts.size() >= 5:
				var r_id = parts[1]
				if r_id == room_id:
					var p_seq = int(parts[2]) if parts.size() >= 6 and parts[2].is_valid_int() else 0
					var s_uid = parts[3] if parts.size() >= 6 else parts[2]
					var s_num = int(parts[4]) if parts.size() >= 6 and parts[4].is_valid_int() else (int(parts[3]) if parts[3].is_valid_int() else seat)
					var h_id = int(parts[5]) if parts.size() >= 6 and parts[5].is_valid_int() else (int(parts[4]) if parts[4].is_valid_int() else 0)
					return {
						"roomId": r_id,
						"seq": p_seq,
						"senderUserId": s_uid,
						"seatNumber": s_num,
						"requestedHeroId": h_id,
						"timestamp": int(doc.get("timestamp", 0))
					}
	return {}
