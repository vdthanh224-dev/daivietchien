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
var draft_slots: Array = []
var my_session_user_id: String = ""
var my_session_user_name: String = ""
var is_host: bool = true

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
	if not uid1.is_empty() and not uid2.is_empty():
		return uid1 == uid2
	if not name1.is_empty() and not name2.is_empty():
		return name1 == name2
	return false

# --- Encoding & Decoding Room State ---
func encode_room_string(room: Dictionary) -> String:
	var r_id = sanitize(room.get("roomId", ""), 18)
	var h_uid = sanitize(room.get("hostUserId", ""), 60)
	var st = sanitize(room.get("status", "WAITING"), 10)
	var ver = int(room.get("version", 1))
	var mode_id = sanitize(room.get("modeId", "2v2"), 16)
	var slots = room.get("slots", [])
	var slot_count = maxi(4, slots.size())
	var parts: Array[String] = ["ROOMV2", r_id, h_uid, st, str(ver), mode_id, str(slot_count)]

	for i in range(slot_count):
		if i < slots.size():
			var s = slots[i]
			var is_empty = bool(s.get("isEmpty", false)) or s.get("userId", "") == "" or s.get("userId", "") == "empty"
			var uid = "empty" if is_empty else sanitize(s.get("userId", ""), 60)
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
	if raw_str.is_empty():
		return {}
	var parts = raw_str.split("|")
	if parts.size() < 8 or (parts[0] != "ROOM4" and parts[0] != "ROOMV2"):
		return {}

	var ver = 0
	var mode_id = "2v2"
	var slot_start_idx = 5
	var slot_count = 4
	if parts[0] == "ROOMV2":
		ver = int(parts[4]) if parts[4].is_valid_int() else 0
		mode_id = parts[5] if parts.size() > 5 else "2v2"
		slot_count = maxi(4, int(parts[6]) if parts.size() > 6 and parts[6].is_valid_int() else 4)
		slot_start_idx = 7
	elif parts.size() >= 9 and parts[4].is_valid_int():
		ver = int(parts[4])
		slot_start_idx = 5
	else:
		slot_start_idx = 4

	var room: Dictionary = {
		"roomId": parts[1],
		"hostUserId": parts[2],
		"status": parts[3],
		"version": ver,
		"modeId": mode_id,
		"hostTimestamp": doc_timestamp,
		"updateTimestamp": doc_timestamp,
		"hostRankPoints": host_rp,
		"slots": []
	}

	for i in range(slot_start_idx, mini(parts.size(), slot_start_idx + slot_count)):
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
func find_best_waiting_room(my_user_id: String, my_rank_points: int, max_rank_diff: int = 12, my_user_name: String = "", include_room_id: String = "", mode_id: String = "") -> Dictionary:
	var q_equal = "{\"method\":\"equal\",\"attribute\":\"userId\",\"values\":[\"ROOM_WAITING\"]}".uri_encode()
	var q_order = "{\"method\":\"orderDesc\",\"attribute\":\"$createdAt\"}".uri_encode()
	var q_limit = "{\"method\":\"limit\",\"values\":[100]}".uri_encode()
	var get_url = "%s/databases/%s/collections/%s/documents?queries[0]=%s&queries[1]=%s&queries[2]=%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, q_equal, q_order, q_limit]
	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] != 200 or res["data"] == null:
		return {}
	var now = get_now_ms()
	var best_room: Dictionary = {}
	var best_real_count = -1
	for doc in res["data"].get("documents", []):
		if not (doc is Dictionary):
			continue
		var doc_time = int(doc.get("timestamp", 0))
		if now - doc_time > 180000:
			if doc.get("$id", "") != "":
				_delete_document_async(doc.get("$id", ""))
			continue
		var room = decode_room_string(str(doc.get("userName", "")), doc_time, int(doc.get("rankPoints", 0)))
		if room.is_empty() or room.get("status") != "WAITING":
			continue
		if not mode_id.is_empty() and str(room.get("modeId", "2v2")) != mode_id:
			continue
		var is_requested_room = str(room.get("roomId", "")) == include_room_id and not include_room_id.is_empty()
		if not is_requested_room and is_same_user(str(room.get("hostUserId", "")), "", my_user_id, my_user_name):
			continue
		var present = false
		var has_empty = false
		var real_count = 0
		for slot in room.get("slots", []):
			if slot.get("isEmpty", false):
				has_empty = true
			elif is_same_user(str(slot.get("userId", "")), str(slot.get("userName", "")), my_user_id, my_user_name):
				present = true
				# When evaluating our own published room, count our slot too.
				# Otherwise every client treats its own room as empty and hosts can
				# elect different rooms at the same time.
				if is_requested_room:
					real_count += 1
			elif not slot.get("isAI", false) and slot.get("userId", "") != "":
				real_count += 1
		if (present and not is_requested_room) or not has_empty:
			continue
		var diff = abs(int(room.get("hostRankPoints", 0)) - my_rank_points)
		var room_id = str(room.get("roomId", ""))
		var best_room_id = str(best_room.get("roomId", "~"))
		var rank_ok = (OS.is_debug_build() or OS.has_feature("editor") or max_rank_diff >= 9999 or diff <= max_rank_diff)
		if rank_ok:
			if real_count > best_real_count or (real_count == best_real_count and (best_room.is_empty() or room_id < best_room_id)):
				best_real_count = real_count
				best_room = room
	return best_room

func cleanup_user_waiting_rooms(my_user_id: String) -> void:
	if my_user_id.is_empty():
		return
	var q_equal = "{\"method\":\"equal\",\"attribute\":\"userId\",\"values\":[\"ROOM_WAITING\"]}".uri_encode()
	var q_limit = "{\"method\":\"limit\",\"values\":[100]}".uri_encode()
	var get_url = "%s/databases/%s/collections/%s/documents?queries[0]=%s&queries[1]=%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, q_equal, q_limit]
	var res = await _send_http_request(get_url, HTTPClient.METHOD_GET)
	if res["code"] != 200 or res["data"] == null:
		return
	for doc in res["data"].get("documents", []):
		if not (doc is Dictionary):
			continue
		var room = decode_room_string(str(doc.get("userName", "")), int(doc.get("timestamp", 0)), int(doc.get("rankPoints", 0)))
		if room.is_empty() or room.get("status") != "WAITING":
			continue
		var owns_room = str(room.get("hostUserId", "")) == my_user_id
		# Chỉ chủ phòng mới được phép xóa phòng. Khách không được xóa phòng của chủ!
		if owns_room and str(doc.get("$id", "")) != "":
			await _send_http_request("%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc.get("$id", "")], HTTPClient.METHOD_DELETE)

# --- 2. Create Waiting Room ---
func create_waiting_room(room: Dictionary) -> bool:
	var now = get_now_ms()
	room["updateTimestamp"] = now
	room["version"] = 1
	var doc_id = get_deterministic_doc_id("r_", room.get("roomId", ""))
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]
	var payload = {"documentId": doc_id, "data": {"userId": "ROOM_WAITING", "userName": encode_room_string(room), "rankPoints": int(room.get("hostRankPoints", 0)), "timestamp": now}, "permissions": PUBLIC_DOC_PERMISSIONS}
	var res = await _send_http_request(docs_url, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if res["code"] == 409:
		res = await _send_http_request(docs_url + "/" + doc_id, HTTPClient.METHOD_PATCH, JSON.stringify({"data": payload["data"], "permissions": PUBLIC_DOC_PERMISSIONS}))
	return res["code"] == 201 or res["code"] == 200

func _match_lock_doc_id(room_id: String) -> String:
	return get_deterministic_doc_id("lock_", room_id)

func _acquire_room_lock(room_id: String, user_id: String) -> bool:
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]
	var lock_id = _match_lock_doc_id(room_id)
	var now = get_now_ms()
	var payload = {"documentId": lock_id, "data": {"userId": "MATCH_LOCK", "userName": user_id, "rankPoints": 0, "timestamp": now}, "permissions": PUBLIC_DOC_PERMISSIONS}
	for attempt in range(8):
		var res = await _send_http_request(docs_url, HTTPClient.METHOD_POST, JSON.stringify(payload))
		print("[AppwriteMatchmaking] LOCK room=%s code=%d attempt=%d" % [room_id, int(res["code"]), attempt + 1])
		if res["code"] == 201 or res["code"] == 200:
			return true
		if res["code"] == 409:
			var current = await _send_http_request(docs_url + "/" + lock_id, HTTPClient.METHOD_GET)
			var lock_data = current.get("data", {})
			if current["code"] == 200 and get_now_ms() - int(lock_data.get("timestamp", 0)) > 5000:
				await _send_http_request(docs_url + "/" + lock_id, HTTPClient.METHOD_DELETE)
			else:
				await get_tree().create_timer(0.15 + attempt * 0.1).timeout
	return false

func _release_room_lock(room_id: String) -> void:
	var docs_url = "%s/databases/%s/collections/%s/documents" % [ENDPOINT, DATABASE_ID, COLLECTION_ID]
	await _send_http_request(docs_url + "/" + _match_lock_doc_id(room_id), HTTPClient.METHOD_DELETE)

# --- 3. Join Room Slot ---
func join_room_slot(room: Dictionary, my_user_id: String, my_user_name: String, my_rank_points: int, desired_seat: int = 0) -> Dictionary:
	if room.is_empty():
		return {}

	var room_id = str(room.get("roomId", ""))
	# Re-read and verify after every write. Appwrite does not expose a compare
	# and swap update here, so a lost concurrent write is retried safely.
	for attempt in range(6):
		# Spread simultaneous joins slightly so each client reads the newest
		# document after the previous slot claim has reached Appwrite.
		if attempt == 0:
			var join_jitter = float(abs(my_user_id.hash()) % 350) / 1000.0
			if join_jitter > 0.0:
				await get_tree().create_timer(join_jitter).timeout
		if not await _acquire_room_lock(room_id, my_user_id):
			continue
		var latest_room = await poll_room_state(room_id)
		if latest_room.is_empty() or latest_room.get("status") != "WAITING":
			await _release_room_lock(room_id)
			return {}
		for existing_slot in latest_room.get("slots", []):
			if is_same_user(str(existing_slot.get("userId", "")), str(existing_slot.get("userName", "")), my_user_id, my_user_name):
				await _release_room_lock(room_id)
				return latest_room
		var target_index = -1
		if desired_seat >= 1 and desired_seat <= latest_room.get("slots", []).size():
			if latest_room["slots"][desired_seat - 1].get("isEmpty", false):
				target_index = desired_seat - 1
		if target_index < 0:
			for idx in range(latest_room.get("slots", []).size()):
				if latest_room["slots"][idx].get("isEmpty", false):
					target_index = idx
					break
		if target_index < 0:
			await _release_room_lock(room_id)
			return {}
		# Dictionary.merge does not overwrite existing keys by default. Empty
		# slots already contain userId="empty", so use overwrite=true or the
		# successful PATCH would still serialize an empty slot.
		latest_room["slots"][target_index].merge({"userId": my_user_id, "userName": my_user_name, "rankPoints": my_rank_points, "isAI": false, "isEmpty": false}, true)
		latest_room["version"] = int(latest_room.get("version", 1)) + 1
		var doc_id = get_deterministic_doc_id("r_", room_id)
		var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
		var now = get_now_ms()
		var res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify({"data": {"userId": "ROOM_WAITING", "userName": encode_room_string(latest_room), "rankPoints": int(latest_room.get("hostRankPoints", 0)), "timestamp": now}, "permissions": PUBLIC_DOC_PERMISSIONS}))
		print("[AppwriteMatchmaking] JOIN PATCH room=%s code=%d attempt=%d" % [room_id, int(res["code"]), attempt + 1])
		if res["code"] == 200:
			# The room lock serializes slot claims. Do not immediately read the
			# document again: Appwrite can briefly return an older replica, which
			# made a successful join look failed and caused a stale retry to erase
			# the previous player's slot.
			await _release_room_lock(room_id)
			return latest_room
		await _release_room_lock(room_id)

		if attempt < 5:
			await get_tree().create_timer(0.08 + float(attempt) * 0.04).timeout

	return {}

# --- 4. Poll Room State ---
func poll_room_state(room_id: String) -> Dictionary:
	if room_id.is_empty():
		return {}

	var doc_id = get_deterministic_doc_id("r_", room_id)
	var res = await _send_http_request("%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id], HTTPClient.METHOD_GET)
	if res["code"] == 200 and res["data"] != null:
		var doc = res["data"]
		return decode_room_string(str(doc.get("userName", "")), int(doc.get("timestamp", 0)), int(doc.get("rankPoints", 0)))
	return {}

# --- 5. Update Room State ---
func update_room_state(room: Dictionary) -> bool:
	var now = get_now_ms()
	room["updateTimestamp"] = now
	room["version"] = int(room.get("version", 1)) + 1
	var room_id = str(room.get("roomId", ""))
	if room_id.is_empty():
		return false
	var doc_id = get_deterministic_doc_id("r_", room_id)
	var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	var st = room.get("status", "WAITING")
	var user_type = "ROOM_STARTED" if st == "STARTED" else ("ROOM_FINISHED" if st == "FINISHED" else "ROOM_WAITING")
	var res = await _send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify({"data": {"userId": user_type, "userName": encode_room_string(room), "rankPoints": int(room.get("hostRankPoints", 0)), "timestamp": now}, "permissions": PUBLIC_DOC_PERMISSIONS}))
	return (res["code"] == 200)

# --- 6. Send Host Heartbeat ---
func send_host_heartbeat(room_id: String) -> void:
	if room_id.is_empty():
		return
	var room = await poll_room_state(room_id)
	if not room.is_empty():
		room["updateTimestamp"] = get_now_ms()
		var doc_id = get_deterministic_doc_id("r_", room_id)
		var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
		_send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify({"data": {"timestamp": room["updateTimestamp"]}, "permissions": PUBLIC_DOC_PERMISSIONS}))

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
	var doc_id = get_deterministic_doc_id("r_", room_id)
	_delete_document_async(doc_id)

func retire_merged_room(room_id: String) -> void:
	if room_id.is_empty():
		return
	var room = await poll_room_state(room_id)
	if room.is_empty():
		return
	var doc_id = get_deterministic_doc_id("r_", room_id)
	var patch_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	room["status"] = "MERGED"
	room["updateTimestamp"] = get_now_ms()
	var payload = {"data": {"userId": "ROOM_MERGED", "userName": encode_room_string(room), "rankPoints": int(room.get("hostRankPoints", 0)), "timestamp": room["updateTimestamp"]}, "permissions": PUBLIC_DOC_PERMISSIONS}
	_send_http_request(patch_url, HTTPClient.METHOD_PATCH, JSON.stringify(payload))

func _delete_document_async(doc_id: String) -> void:
	var delete_url = "%s/databases/%s/collections/%s/documents/%s" % [ENDPOINT, DATABASE_ID, COLLECTION_ID, doc_id]
	_send_http_request(delete_url, HTTPClient.METHOD_DELETE)

# --- 9. Draft & Battle State Protocols (Đã hủy Appwrite trong trận, chuyển 100% sang WebSocket Render Cloud) ---
func send_draft_host_state(_state: Dictionary) -> bool:
	return true

func poll_draft_host_state(_room_id: String) -> Dictionary:
	return {}

func send_draft_player_action(_act: Dictionary) -> bool:
	return true

func poll_draft_player_action_for_seat(_room_id: String, _seat: int) -> Dictionary:
	return {}

func poll_draft_player_actions(_room_id: String) -> Array:
	return []

func send_battle_action(_act: Dictionary) -> bool:
	return true

func poll_battle_actions(_room_id: String) -> Array:
	return []
