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

const CANDIDATE_SERVERS: Array[Dictionary] = [
	{ "type": "LOCAL", "name": "Server Local (127.0.0.1)", "url": "ws://127.0.0.1:8080" },
	{ "type": "LOCAL_FALLBACK", "name": "Server Local (localhost)", "url": "ws://localhost:8080" },
	{ "type": "DENO_CLOUD", "name": "Server Deno Cloud", "url": "wss://dai-viet-chien.vdthanh.deno.net" },
	{ "type": "DENO_CLOUD_OLD", "name": "Server Deno Cloud (Server)", "url": "wss://dai-viet-chien-server.vdthanh.deno.net" }
]

const CANDIDATE_CONNECT_TIMEOUT: float = 2.0

@export var server_url: String = "ws://127.0.0.1:8080"
@export var auto_reconnect: bool = true

var socket: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var room_id: String = ""
var my_seat: int = 1
var seat_is_explicit: bool = false
var last_state: Dictionary = {}
var last_heartbeat_time: float = 0.0
var last_processed_action_seq: int = -1

var active_server_type: String = "NONE" # "DENO_CLOUD", "LOCAL", "APPWRITE_FALLBACK"
var active_server_name: String = ""
var active_server_url: String = ""
var candidate_index: int = 0
var is_scanning_candidates: bool = false
var candidate_timer: float = 0.0
var has_custom_cli_url: bool = false

const CONFIG_FILE: String = "user://server_config.json"

var _instance_lock_server: TCPServer = null
var auto_instance_index: int = 1

func _detect_instance_index() -> int:
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if arg.begins_with("--seat="):
			var s = arg.trim_prefix("--seat=").to_int()
			if s >= 1 and s <= 4:
				seat_is_explicit = true
				return s
		if arg.begins_with("--tester="):
			var t = arg.trim_prefix("--tester=").to_int()
			if t >= 1 and t <= 4:
				seat_is_explicit = true
				return t

	# Tự động nhận diện cửa sổ 1, 2, 3, 4 khi chạy nhiều instance (Godot Run Multiple Instances)
	for s in range(1, 5):
		var srv = TCPServer.new()
		var err = srv.listen(6010 + s, "127.0.0.1")
		if err == OK:
			_instance_lock_server = srv
			return s
	return 1

func _ready() -> void:
	auto_instance_index = _detect_instance_index()
	my_seat = auto_instance_index
	print("[NetworkClient] Khởi động... Cửa sổ: Ghế %d (Tester %d)" % [my_seat, my_seat])
	if OS.is_debug_build() or OS.has_feature("editor"):
		DisplayServer.window_set_title("Đại Việt Chiến - [CỬA SỔ %d - GHẾ %d]" % [my_seat, my_seat])
	_load_server_config()
	if has_custom_cli_url:
		connect_to_server(server_url)
	else:
		_start_priority_connection()

func is_connecting() -> bool:
	if is_scanning_candidates:
		return true
	if socket and socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		return true
	return false

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
		print("[NetworkClient] ❌ Tất cả WebSocket Server (Deno Cloud & Local) đều không kết nối được! Không sử dụng Appwrite cho trận đấu.")
		error_received.emit("Không thể kết nối đến Máy Chủ Trận Đấu (Deno Cloud hoặc Local 8080)!")
		return

	candidate_index = index
	is_scanning_candidates = true
	candidate_timer = 0.0
	var cand = CANDIDATE_SERVERS[index]
	server_url = cand["url"]
	print("[NetworkClient] 🔍 [Ưu tiên %d/%d] Đang thử kết nối %s (%s)..." % [index + 1, CANDIDATE_SERVERS.size(), cand["name"], cand["url"]])

	socket.close()
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(server_url)
	if err != OK:
		print("[NetworkClient] ❌ Lỗi gọi connect_to_url: %d" % err)
		_on_candidate_failed("Mã lỗi kết nối: %d" % err)

func _on_candidate_failed(reason: String) -> void:
	var cand = CANDIDATE_SERVERS[candidate_index] if candidate_index < CANDIDATE_SERVERS.size() else {}
	print("[NetworkClient] ❌ Kết nối tới %s thất bại: %s. Chuyển sang ưu tiên tiếp theo..." % [cand.get("name", "Server"), reason])
	_try_candidate(candidate_index + 1)

func _load_server_config() -> void:
	# 1. Đọc từ đối số dòng lệnh nếu có (ví dụ: --server-url=ws://192.168.1.102:8080)
	var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for arg in all_args:
		if arg.begins_with("--server-url="):
			server_url = arg.trim_prefix("--server-url=").strip_edges()
			has_custom_cli_url = true
			print("[NetworkClient] Đọc server_url từ CLI: ", server_url)
			return

	# 2. Đọc từ file cấu hình user://server_config.json nếu có
	if FileAccess.file_exists(CONFIG_FILE):
		var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var json = JSON.parse_string(text)
			if json is Dictionary and json.has("server_url"):
				var saved_url = str(json["server_url"]).strip_edges()
				if saved_url != "":
					server_url = saved_url
					has_custom_cli_url = true
					print("[NetworkClient] Đọc server_url từ cấu hình user: ", server_url)

func save_server_url(new_url: String) -> void:
	server_url = new_url.strip_edges()
	has_custom_cli_url = true
	var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"server_url": server_url}))
		file.close()
	connect_to_server(server_url)

func connect_to_server(url: String = "") -> void:
	if url != "":
		server_url = url
		has_custom_cli_url = true
	if not has_custom_cli_url:
		_start_priority_connection()
		return

	is_scanning_candidates = false
	print("[NetworkClient] Đang kết nối trực tiếp tới: ", server_url)
	socket.close()
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(server_url)
	if err != OK:
		print("[NetworkClient] Kết nối thất bại, mã lỗi: ", err)

func _process(delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			is_scanning_candidates = false
			if candidate_index < CANDIDATE_SERVERS.size() and not has_custom_cli_url:
				var cand = CANDIDATE_SERVERS[candidate_index]
				active_server_type = cand["type"]
				active_server_name = cand["name"]
				active_server_url = cand["url"]
			else:
				active_server_type = "CUSTOM"
				active_server_name = "Custom Server"
				active_server_url = server_url
			print("[NetworkClient] ⚡ Đã kết nối thành công tới %s (%s)!" % [active_server_name, active_server_url])
			connection_established.emit()

		# Nhịp đập Heartbeat PING mỗi 15s chuẩn Unity DenoGameClient
		last_heartbeat_time += delta
		if last_heartbeat_time >= 15.0:
			last_heartbeat_time = 0.0
			if not room_id.is_empty():
				send_json({
					"action": "PING",
					"roomId": room_id,
					"seat": my_seat
				})

		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var msg_text = packet.get_string_from_utf8()
			_handle_server_message(msg_text)

	elif state == WebSocketPeer.STATE_CONNECTING:
		if is_scanning_candidates:
			candidate_timer += delta
			if candidate_timer >= CANDIDATE_CONNECT_TIMEOUT:
				_on_candidate_failed("Quá thời gian kết nối (Timeout 2.5s)")

	elif state == WebSocketPeer.STATE_CLOSED:
		if is_scanning_candidates:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			_on_candidate_failed("Đóng kết nối (Code %d, Reason: %s)" % [code, reason])
		elif is_connected_to_server:
			is_connected_to_server = false
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("[NetworkClient] Mất kết nối tới server. Code: %d, Reason: %s" % [code, reason])
			connection_closed.emit()
			if auto_reconnect:
				if reason == "Seat reconnected":
					print("[NetworkClient] 🛑 Ghế này đã được kết nối từ một cửa sổ/thiết bị khác (%s). Dừng tự động kết nối lại để tránh xung đột." % reason)
					return
				await get_tree().create_timer(2.0).timeout
				if has_custom_cli_url:
					connect_to_server(server_url)
				else:
					_start_priority_connection()

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

	if msg_type == "DRAFT_COMPLETED":
		draft_completed.emit(data)

	if msg_type == "ERROR" or msg_type == "ACTION_REJECTED":
		var err_msg = str(data.get("error", "Lỗi không xác định"))
		print("[NetworkClient] Server phản hồi lỗi: ", err_msg)
		error_received.emit(err_msg)

	if msg_type in ["STATE_SYNC", "STATE_SNAPSHOT", "STATE_UPDATE"] or (data.has("state") and data["state"] != null):
		var state_obj = data.get("state", data)
		if state_obj is Dictionary and not state_obj.is_empty():
			last_state = state_obj
			game_state_updated.emit(state_obj)

	if data.has("delta") and data["delta"] != null:
		var delta_obj = data["delta"]
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
		var json_str = JSON.stringify(dict)
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
	if seat_is_explicit:
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
