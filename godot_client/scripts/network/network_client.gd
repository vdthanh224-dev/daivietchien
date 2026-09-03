extends Node

signal connection_established()
signal connection_closed()
signal game_state_updated(state: Dictionary)
signal action_received(delta: Dictionary)
signal log_received(text: String)

@export var server_url: String = "ws://127.0.0.1:8080"
@export var auto_reconnect: bool = true

var socket: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_server: bool = false
var room_id: String = ""
var my_seat: int = 1
var last_state: Dictionary = {}

func _ready() -> void:
	print("[NetworkClient] Khởi động...")
	connect_to_server()

func connect_to_server(url: String = "") -> void:
	if url != "":
		server_url = url
	print("[NetworkClient] Đang kết nối tới: ", server_url)
	var err = socket.connect_to_url(server_url)
	if err != OK:
		print("[NetworkClient] Kết nối thất bại, mã lỗi: ", err)

func _process(_delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not is_connected_to_server:
			is_connected_to_server = true
			print("[NetworkClient] Đã kết nối thành công tới Server!")
			connection_established.emit()
			# Gửi yêu cầu tham gia phòng mặc định
			send_join_room("room_1", my_seat)

		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			var msg_text = packet.get_string_from_utf8()
			_handle_server_message(msg_text)

	elif state == WebSocketPeer.STATE_CLOSED:
		if is_connected_to_server:
			is_connected_to_server = false
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			print("[NetworkClient] Mất kết nối tới server. Code: %d, Reason: %s" % [code, reason])
			connection_closed.emit()
			if auto_reconnect:
				await get_tree().create_timer(2.0).timeout
				connect_to_server()

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

	if msg_type == "STATE_SYNC" or data.has("state"):
		var state_obj = data.get("state", data)
		last_state = state_obj
		game_state_updated.emit(state_obj)

	if data.has("delta"):
		var delta_obj = data["delta"]
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

func send_join_room(target_room: String, seat: int) -> void:
	room_id = target_room
	my_seat = seat
	send_json({
		"action": "JOIN_ROOM",
		"roomId": target_room,
		"seat": seat,
		"heroId": "1"
	})

func send_play_card(card_id: String, target_seat: int = 0) -> void:
	send_json({
		"action": "PLAY_CARD",
		"roomId": room_id,
		"seat": my_seat,
		"cardId": card_id,
		"targetSeat": target_seat
	})

func send_respond_action(accepted: bool, card_id: String = "") -> void:
	send_json({
		"action": "RESPOND_ACTION",
		"roomId": room_id,
		"seat": my_seat,
		"accepted": accepted,
		"cardId": card_id
	})

func send_end_turn() -> void:
	send_json({
		"action": "END_TURN",
		"roomId": room_id,
		"seat": my_seat
	})
