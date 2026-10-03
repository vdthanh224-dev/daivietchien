extends Node

signal connection_established()
signal connection_closed()
signal game_state_updated(state: Dictionary)
signal action_received(delta: Dictionary)
signal log_received(text: String)
signal player_joined(seat: int, active_seats: Array)
signal error_received(message: String)
signal draft_state_updated(draft_data: Dictionary)
signal draft_completed(battle_data: Dictionary)
signal draft_joined(assigned_seat: int)
signal draft_hover_updated(seat: int, hero_id: int, hero_name: String)
signal ping_updated(ping_ms: int)

const CANDIDATE_SERVERS: Array[Dictionary] = [
	# Draft and battle state must use one shared online authority. There is no
	# localhost/LAN fallback because separate local processes do not share rooms.
	# Deno Deploy can need several seconds to wake an idle isolate and finish TLS.
	{ "type": "DENO_CLOUD", "name": "Máy Chủ Đám Mây (Deno Cloud)", "url": "wss://dai-viet-chien-server.vdthanh.deno.net", "timeout": 25.0 }
]

const CLOUD_SERVER_URL: String = "wss://dai-viet-chien-server.vdthanh.deno.net"
@export var server_url: String = CLOUD_SERVER_URL
@export var auto_reconnect: bool = true

var socket: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var room_id: String = ""
var my_seat: int = 1
var seat_is_explicit: bool = false
var last_state: Dictionary = {}
var last_heartbeat_time: float = 0.0
var last_processed_action_seq: int = -1

var current_ping: int = -1
var _ping_timer: float = 2.5
var _last_ping_send_time: int = 0
var _ping_awaiting_pong: bool = false

var active_server_type: String = "NONE" # "DENO_CLOUD"
var active_server_name: String = ""
var active_server_url: String = ""
var candidate_index: int = 0
var is_scanning_candidates: bool = false
var candidate_timer: float = 0.0
var _reconnect_timer: float = 0.0

var _instance_lock_server: TCPServer = null
var auto_instance_index: int = 1

func _detect_instance_index() -> int:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if arg.begins_with("--seat=") or arg.begins_with("--tester="):
			var value = arg.substr(arg.find("=") + 1).to_int()
			if value >= 1 and value <= 4:
				seat_is_explicit = true
				return value

	# Tự động nhận diện cửa sổ 1, 2, 3, 4 khi chạy nhiều instance (Godot Run Multiple Instances)
	for s in range(1, 5):
		var srv = TCPServer.new()
		var err = srv.listen(6010 + s, "127.0.0.1")
		if err == OK:
			_instance_lock_server = srv
			seat_is_explicit = true
			return s

	seat_is_explicit = false
	return 1

func _ready() -> void:
	auto_instance_index = _detect_instance_index()
	my_seat = auto_instance_index
	print("[NetworkClient] Khởi động... Cửa sổ: Ghế %d (Tester %d)" % [my_seat, my_seat])
	if OS.is_debug_build() or OS.has_feature("editor"):
		DisplayServer.window_set_title("Đại Việt Chiến - [CỬA SỔ %d - GHẾ %d]" % [my_seat, my_seat])
	_load_server_config()
	_start_priority_connection()

func is_connecting() -> bool:
	if is_scanning_candidates:
		return true
	if socket and socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		return true
	return false

func get_ping_ms() -> int:
	return current_ping

func _start_priority_connection() -> void:
	candidate_index = 0
	_try_candidate(0)

func _try_candidate(index: int) -> void:
	if index >= CANDIDATE_SERVERS.size():
		is_scanning_candidates = false
		is_connected_to_server = false
		active_server_type = "NONE"
		active_server_name = "Không có máy chủ"
		active_server_url = ""
		current_ping = -1
		_ping_awaiting_pong = false
		ping_updated.emit(-1)
		if socket:
			socket.close()
		_reconnect_timer = 0.0
		print("[NetworkClient] ❌ Chưa kết nối được Deno Cloud; sẽ tự động thử lại...")
		error_received.emit("Không thể kết nối đến Máy Chủ Trận Đấu online.")
		return

	candidate_index = index
	is_scanning_candidates = true
	candidate_timer = 0.0
	var cand = CANDIDATE_SERVERS[index]
	server_url = cand["url"]
	print("[NetworkClient] 🔍 [Ưu tiên %d/%d] Đang thử kết nối %s (%s)..." % [index + 1, CANDIDATE_SERVERS.size(), cand["name"], cand["url"]])

	if socket:
		socket.close()
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(server_url)
	if err != OK:
		print("[NetworkClient] ❌ Lỗi gọi connect_to_url: %d" % err)
		_on_candidate_failed("Mã lỗi kết nối: %d" % err)

func _on_candidate_failed(reason: String) -> void:
	current_ping = -1
	_ping_awaiting_pong = false
	ping_updated.emit(-1)
	if socket:
		socket.close()
	var cand = CANDIDATE_SERVERS[candidate_index] if candidate_index < CANDIDATE_SERVERS.size() else {}
	print("[NetworkClient] ❌ Kết nối tới %s thất bại: %s. Chuyển sang ưu tiên tiếp theo..." % [cand.get("name", "Server"), reason])
	_try_candidate(candidate_index + 1)

func _load_server_config() -> void:
	# Ignore old user:// settings and --server-url overrides. They can point
	# different clients at different authorities and split a draft room.
	server_url = CLOUD_SERVER_URL

func save_server_url(new_url: String) -> void:
	# Kept for compatibility with older UI scripts. The client is cloud-only.
	server_url = CLOUD_SERVER_URL
	print("[NetworkClient] Bỏ qua địa chỉ server tùy chỉnh; chỉ dùng Deno Cloud.")
	connect_to_server(CLOUD_SERVER_URL)

func connect_to_server(url: String = "") -> void:
	# Always normalize callers (including old saved settings) to cloud.
	server_url = CLOUD_SERVER_URL
	if is_connected_to_server:
		return
	if is_connecting():
		# Nếu đã kết nối đang diễn ra nhưng bị treo quá 5s, buộc reset và kết nối lại
		if candidate_timer > 5.0:
			if socket:
				socket.close()
			is_scanning_candidates = false
		else:
			return
	_start_priority_connection()
	return

func _process(delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			is_scanning_candidates = false
			_ping_timer = 0.0
			candidate_timer = 0.0
			if candidate_index < CANDIDATE_SERVERS.size():
				var cand = CANDIDATE_SERVERS[candidate_index]
				active_server_type = cand["type"]
				active_server_name = cand["name"]
				active_server_url = cand["url"]
			print("[NetworkClient] ⚡ Đã kết nối thành công tới %s (%s)!" % [active_server_name, active_server_url])
			print("[NetworkClient] DRAFT authority: server=%s" % active_server_url)
			connection_established.emit()
			_send_ping()

		# Nhịp đập Heartbeat PING & Đo độ trễ thời gian thực mỗi 3 giây
		_ping_timer += delta
		if _ping_timer >= 3.0:
			_ping_timer = 0.0
			_send_ping()

		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var msg_text = packet.get_string_from_utf8()
			_handle_server_message(msg_text)

	elif state == WebSocketPeer.STATE_CONNECTING:
		candidate_timer += delta
		if is_scanning_candidates:
			var max_to = 12.0
			if candidate_index < CANDIDATE_SERVERS.size():
				max_to = float(CANDIDATE_SERVERS[candidate_index].get("timeout", 2.5))
			if candidate_timer >= max_to:
				_on_candidate_failed("Quá thời gian kết nối (Timeout %.1fs)" % max_to)

	elif state == WebSocketPeer.STATE_CLOSED:
		candidate_timer = 0.0
		if is_scanning_candidates:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			_on_candidate_failed("Đóng kết nối (Code %d, Reason: %s)" % [code, reason])
		elif is_connected_to_server:
			is_connected_to_server = false
			current_ping = -1
			_ping_awaiting_pong = false
			ping_updated.emit(-1)
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("[NetworkClient] Mất kết nối tới server. Code: %d, Reason: %s" % [code, reason])
			connection_closed.emit()
			_reconnect_timer = 0.0
		else:
			current_ping = -1
			_ping_awaiting_pong = false
			ping_updated.emit(-1)
			if auto_reconnect and not is_scanning_candidates:
				_reconnect_timer += delta
				if _reconnect_timer >= 2.5:
					_reconnect_timer = 0.0
					_start_priority_connection()

func _send_ping() -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_last_ping_send_time = Time.get_ticks_msec()
	_ping_awaiting_pong = true
	var ping_payload: Dictionary = {
		"action": "PING",
		"clientTime": _last_ping_send_time
	}
	if not room_id.is_empty():
		ping_payload["roomId"] = room_id
		ping_payload["seat"] = my_seat
	send_json(ping_payload)

func _handle_server_message(raw_json: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(raw_json)
	if parse_result != OK:
		print("[NetworkClient] Lỗi parse JSON từ server: ", json.get_error_message())
		return

	var data = json.get_data()
	if not data is Dictionary:
		return

	var msg_type = data.get("type", "")

	if msg_type == "PONG":
		var now = Time.get_ticks_msec()
		var client_time = int(data.get("clientTime", 0))
		if client_time > 0:
			current_ping = max(1, now - client_time)
		elif _last_ping_send_time > 0:
			current_ping = max(1, now - _last_ping_send_time)
		_ping_awaiting_pong = false
		ping_updated.emit(current_ping)
		return

	if msg_type == "ERROR" and _ping_awaiting_pong:
		var err_str = str(data.get("error", ""))
		if err_str == "Thiếu roomId" or err_str == "Kết nối chưa tham gia phòng":
			var now = Time.get_ticks_msec()
			current_ping = max(1, now - _last_ping_send_time)
			_ping_awaiting_pong = false
			ping_updated.emit(current_ping)
			return

	if msg_type == "DRAFT_JOINED":
		var assigned_seat = int(data.get("assignedSeat", data.get("seat", 0)))
		if assigned_seat >= 1 and assigned_seat <= 4:
			my_seat = assigned_seat
			print("[NetworkClient] Server cấp ghế chọn tướng: Ghế %d" % my_seat)
			draft_joined.emit(my_seat)

	if msg_type == "PLAYER_JOINED":
		var j_seat = int(data.get("seat", 0))
		var active_s = data.get("activeSeats", [])
		player_joined.emit(j_seat, active_s)

	if msg_type == "DRAFT_STATE_UPDATE":
		draft_state_updated.emit(data)

	if msg_type == "DRAFT_HOVER_UPDATE":
		draft_hover_updated.emit(int(data.get("seat", 0)), int(data.get("heroId", 0)), str(data.get("heroName", "")))

	if msg_type == "DRAFT_COMPLETED":
		draft_completed.emit(data)

	if msg_type == "ERROR" or msg_type == "ACTION_REJECTED":
		var err_msg = str(data.get("error", "Lỗi không xác định"))
		print("[NetworkClient] Server phản hồi lỗi: ", err_msg)
		error_received.emit(err_msg)

	var state_obj = data.get("state", data)
	if msg_type in ["STATE_SYNC", "STATE_SNAPSHOT", "STATE_UPDATE"] or (data.has("state") and data["state"] != null):
		if state_obj is Dictionary and not state_obj.is_empty():
			last_state = state_obj
			game_state_updated.emit(state_obj)

	var delta_obj = data.get("delta", null)
	if delta_obj == null and state_obj is Dictionary:
		delta_obj = state_obj.get("delta", null)
	if delta_obj != null:
		if delta_obj is Dictionary:
			var seq = int(delta_obj.get("actionSeq", -1))
			if seq > 0 and seq == last_processed_action_seq:
				pass # Đã xử lý action này trước đó, bỏ qua để chống lặp lại âm thanh / hành động
			else:
				if seq > 0:
					last_processed_action_seq = seq
				action_received.emit(delta_obj)
				if delta_obj.has("description"):
					log_received.emit(delta_obj["description"])

	if data.has("description"):
		log_received.emit(data["description"])

func send_json(dict: Dictionary) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var payload := dict.duplicate(true)
		var json_str = JSON.stringify(payload)
		socket.send_text(json_str)
	else:
		print("[NetworkClient] Cảnh báo: Socket chưa sẵn sàng để gửi!")

func send_join_draft(target_room: String, seat: int, user_id: String, user_name: String, slots_data: Array = []) -> void:
	room_id = target_room
	my_seat = seat
	last_processed_action_seq = -1
	var payload = {
		"action": "JOIN_DRAFT",
		"roomId": target_room,
		"seat": seat,
		"userId": user_id,
		"userName": user_name
	}
	if not slots_data.is_empty():
		payload["slots"] = slots_data
	if seat_is_explicit or OS.is_debug_build() or OS.has_feature("editor"):
		# Debug windows may share one local auth session; keep their requested seats distinct.
		payload["debugSeat"] = my_seat
	send_json(payload)

func send_pick_hero(hero_id: int, hero_name: String = "") -> void:
	send_json({
		"action": "PICK_HERO",
		"roomId": room_id,
		"seat": my_seat,
		"heroId": hero_id,
		"heroName": hero_name
	})

func send_hover_hero(hero_id: int, hero_name: String = "") -> void:
	if not is_connected_to_server or room_id.is_empty():
		return
	send_json({
		"action": "HOVER_HERO",
		"roomId": room_id,
		"seat": my_seat,
		"heroId": hero_id,
		"heroName": hero_name
	})

func update_debug_window_title(display_name: String = "") -> void:
	if not (OS.is_debug_build() or OS.has_feature("editor")):
		return
	var name_part = (" | " + display_name) if not display_name.is_empty() else ""
	DisplayServer.window_set_title("Đại Việt Chiến - [CỬA SỔ %d - GHẾ %d%s]" % [auto_instance_index, my_seat, name_part])

func leave_room() -> void:
	room_id = ""
	last_processed_action_seq = -1
	last_state = {}

func send_join_room(target_room: String, seat: int, players_data: Array = []) -> void:
	room_id = target_room
	my_seat = seat
	last_processed_action_seq = -1
	var payload = {
		"action": "JOIN_ROOM",
		"roomId": target_room,
		"seat": seat,
		"heroId": "1"
	}
	if not players_data.is_empty():
		payload["players"] = players_data
	send_json(payload)

func send_get_state() -> void:
	if room_id.is_empty():
		return
	send_json({
		"action": "GET_STATE",
		"roomId": room_id,
		"seat": my_seat
	})

func send_play_card(card_id: String, target_seat: int = 0) -> void:
	send_play_card_for_seat(my_seat, card_id, target_seat)

func send_play_card_for_seat(seat_num: int, card_id: String, target_seat: int = 0, target_seat2: int = 0, target_seats: Array = [], recast: bool = false, lien_chau_card_id: String = "") -> void:
	var payload = {
		"action": "PLAY_CARD",
		"roomId": room_id,
		"seat": seat_num,
		"cardId": card_id,
		"targetSeat": target_seat
	}
	if target_seat2 > 0:
		payload["targetSeat2"] = target_seat2
	if not target_seats.is_empty():
		payload["targetSeats"] = target_seats
	if recast:
		payload["recast"] = true
	if not lien_chau_card_id.is_empty():
		payload["lienChauCardId"] = lien_chau_card_id
	send_json(payload)

func send_use_skill(skill_id: String, target_seat: int = 0, card_id: String = "") -> void:
	var payload = {
		"action": "USE_SKILL",
		"roomId": room_id,
		"seat": my_seat,
		"skillId": skill_id,
		"targetSeat": target_seat
	}
	if not card_id.is_empty():
		payload["cardId"] = card_id
	send_json(payload)

func send_toggle_skill(skill_id: String) -> void:
	send_json({
		"action": "TOGGLE_SKILL",
		"roomId": room_id,
		"seat": my_seat,
		"skillId": skill_id
	})

func send_respond_action(accepted: bool, card_id: String = "", target_card_id: String = "", card_ids: Array = []) -> void:
	var payload = {
		"action": "RESPOND_ACTION",
		"roomId": room_id,
		"seat": my_seat,
		"accepted": accepted,
		"cardId": card_id
	}
	if target_card_id != "":
		payload["targetCardId"] = target_card_id
	if not card_ids.is_empty():
		payload["cardIds"] = card_ids
	send_json(payload)

func send_discard_cards(card_ids: Array) -> void:
	send_json({
		"action": "DISCARD_CARDS",
		"roomId": room_id,
		"seat": my_seat,
		"cardIds": card_ids
	})

func send_end_turn() -> void:
	send_end_turn_for_seat(my_seat)

func send_end_turn_for_seat(seat_num: int) -> void:
	send_json({
		"action": "END_TURN",
		"roomId": room_id,
		"seat": seat_num
	})
