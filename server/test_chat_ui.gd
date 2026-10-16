extends SceneTree

# Run from godot_client with --script ../server/test_chat_ui.gd -- --screenshot-chat-check
var failures: int = 0
var network: Node

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func packet(data: Dictionary) -> void:
	network._handle_server_message(JSON.stringify(data))

func screenshot(file_name: String) -> void:
	var output := OS.get_environment("CHAT_SCREENSHOT_DIR")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(file_name))

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		root.size = Vector2i(1280, 720)
	network = root.get_node("NetworkClient")
	network.set_process(false)
	network.auto_reconnect = false
	network.socket.close()
	network.is_connected_to_server = false
	var auth := root.get_node("AuthManager")
	auth.disable_session_save = true
	auth.pending_exp_gain = {}
	auth.current_user_id = "chat-ui-test"
	auth.current_user_name = "Tướng Quân"
	var home = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	current_scene = home
	await create_timer(0.7).timeout
	home.modal_overlay.visible = false
	var lobby = home.get_node("ChatPanel")
	check(lobby.panel.visible, "Lobby chat should start open")
	check(lobby.input.editable, "Lobby input must accept a draft before history arrives")
	await _type_into_chat(lobby)
	packet({"type": "CHAT_HISTORY", "channel": "lobby", "roomId": "", "messages": [
		{"id": "lobby-1", "userId": "other", "userName": "Đại Tướng", "text": "Chào mọi người, cùng tìm trận nào!"},
		{"id": "lobby-2", "userId": "chat-ui-test", "userName": "Tướng Quân", "text": "Sẵn sàng xuất trận!"},
	]})
	await process_frame
	check(lobby.messages_view.get_parsed_text().contains("Chào mọi người"), "Lobby history should render")
	check(lobby.panel.get_global_rect().end.x < 810, "Lobby chat should not cover the battle menu")
	print("Lobby layout: viewport=", root.get_visible_rect(), " panel=", lobby.panel.get_global_rect(), " min=", lobby.panel.get_combined_minimum_size())
	check(lobby.panel.get_global_rect().end.y <= root.get_visible_rect().end.y, "Lobby chat should fit the viewport")
	await screenshot("chat_home.png")
	lobby._set_open(false)
	packet({"type": "CHAT_MESSAGE", "channel": "lobby", "id": "lobby-3", "userId": "other", "userName": "Đại Tướng", "text": "[b]Giữ nguyên văn bản[/b]"})
	check(lobby.unread_count == 1, "Folded lobby chat should count unread messages")
	check(lobby.messages_view.get_parsed_text().contains("[b]Giữ nguyên văn bản[/b]"), "Chat must not execute player BBCode")
	packet({"type": "CHAT_MESSAGE", "channel": "lobby", "id": "lobby-3", "text": "Duplicate"})
	check(network.get_chat_messages("lobby").size() == 3, "Duplicate messages should be ignored")
	lobby._set_open(true)
	check(lobby.unread_count == 0, "Opening chat should reset unread count")
	lobby.input.text = "Bản nháp"
	lobby._on_disconnected()
	check(lobby.input.editable and lobby.send_button.disabled, "Offline chat should allow drafts and disable sending")
	await _type_into_chat(lobby)
	lobby.input.text = "Bản nháp"
	lobby._on_history("lobby", "")
	check(lobby.input.text == "Bản nháp", "Reconnect should retain the draft")
	lobby._pending_text = "Bản nháp"
	packet({"type": "CHAT_MESSAGE", "channel": "lobby", "id": "lobby-4", "userId": "chat-ui-test", "userName": "Tướng Quân", "text": "Bản nháp"})
	check(lobby.input.text.is_empty(), "Only the server acknowledgment should clear a sent draft")
	var game_errors: Array = []
	var capture_error := func(message: String): game_errors.append(message)
	network.error_received.connect(capture_error)
	network._pending_chat_channels.append("lobby")
	lobby.input.text = "Tin chưa gửi"
	packet({"type": "ERROR", "error": "Hành động không hợp lệ"})
	check(lobby.input.editable and lobby.input.text == "Tin chưa gửi", "An old server must not lock or discard the draft")
	check(lobby.status_label.text.contains("Máy chủ chưa cập nhật chat"), "An old server should show the actual chat availability")
	check(game_errors.is_empty(), "An unsupported chat request must not raise a gameplay error")
	network.error_received.disconnect(capture_error)
	home.queue_free()
	await process_frame
	network.room_id = "chat-ui-battle"
	network.my_seat = 1
	var battle = load("res://scenes/battle_2v2.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	await create_timer(0.4).timeout
	var chat = battle.get_node("ChatPanel")
	check(chat.input.editable, "Battle input must accept a draft before history arrives")
	for _index in range(12):
		battle._add_card_to_player_hand(battle._draw_card_from_pile())
	await create_timer(0.5).timeout
	check(not chat.panel.visible, "Battle chat should start folded")
	packet({"type": "CHAT_HISTORY", "channel": "battle", "roomId": network.room_id, "messages": []})
	packet({"type": "CHAT_MESSAGE", "channel": "battle", "roomId": "other-room", "id": "wrong-room", "text": "Private"})
	check(network.get_chat_messages("battle").is_empty(), "Another room's messages should be ignored")
	packet({"type": "CHAT_MESSAGE", "channel": "battle", "roomId": network.room_id, "id": "battle-1", "seat": 2, "userName": "Đại Tướng", "text": "Xin chào các tướng quân!"})
	check(chat.unread_count == 1, "Battle chat should show unread count while folded")
	await screenshot("chat_battle_folded.png")
	chat.toggle_button.pressed.emit()
	await create_timer(0.2).timeout
	check(chat.panel.visible and chat.unread_count == 0, "Chat toggle should open and clear unread count")
	await _type_into_chat(chat)
	check(not chat.panel.get_global_rect().intersects(battle.hand_container.get_global_rect()), "Chat should leave the hand unobstructed")
	check(not chat.panel.get_global_rect().intersects(battle.end_turn_btn.get_global_rect()), "Chat should leave the end-turn button unobstructed")
	check(not chat.panel.get_global_rect().intersects(battle.get_node("TableTop/CardDescBar").get_global_rect()), "Chat should leave the card description unobstructed")
	check(battle.get_node("TableTop/CardDescBar").get_global_rect().end.x <= battle.generals_data[battle.my_seat]["avatar_node"].get_global_rect().position.x, "Card description should stay clear of the local avatar")
	print("Battle layout: viewport=", root.get_visible_rect(), " panel=", chat.panel.get_global_rect(), " min=", chat.panel.get_combined_minimum_size())
	check(chat.panel.get_global_rect().end.y <= root.get_visible_rect().end.y, "Battle chat should fit the viewport")
	await screenshot("chat_battle_open.png")
	# Resizing the viewport should keep the chat inside the playable surface.
	root.size = Vector2i(1600, 720)
	await process_frame
	check(chat.panel.get_global_rect().end.y <= root.get_visible_rect().end.y, "Chat should fit a wide viewport")
	packet({"type": "CHAT_ERROR", "channel": "battle", "error": "Vui lòng chờ 1 giây"})
	check(chat.status_label.text == "Vui lòng chờ 1 giây", "Chat errors should stay in the chat panel")
	battle.queue_free()
	await process_frame
	root.size = Vector2i(1280, 720)
	await _verify_extra_table("dynasty_5", 5)
	await _verify_extra_table("dynasty_8", 8)
	await _verify_chat_transport()
	await _verify_legacy_network()
	print("Chat typing, Enter/WebSocket/ack, old server handling, cache and layout: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _verify_extra_table(mode_id: String, seats: int) -> void:
	var matchmaking := root.get_node("AppwriteMatchmaking")
	matchmaking.current_room = {"modeId": mode_id}
	matchmaking.draft_slots = []
	var battle = load("res://scenes/battle_2v2.tscn").instantiate()
	root.add_child(battle)
	current_scene = battle
	var chat = battle.get_node("ChatPanel")
	for _index in range(12):
		battle._add_card_to_player_hand(battle._draw_card_from_pile())
	chat._set_open(true)
	await create_timer(0.5).timeout
	check(battle.battle_seat_count == seats, "Table should use the expected seat count")
	check(not chat.panel.get_global_rect().intersects(battle.hand_container.get_global_rect()), "Chat should leave the hand clear at %d seats" % seats)
	check(not chat.panel.get_global_rect().intersects(battle.get_node("TableTop/CardDescBar").get_global_rect()), "Chat should leave the card description clear at %d seats" % seats)
	check(battle.get_node("TableTop/CardDescBar").get_global_rect().end.x <= battle.generals_data[battle.my_seat]["avatar_node"].get_global_rect().position.x, "Card description should stay clear of the local avatar at %d seats" % seats)
	for seat in battle.battle_seat_nodes:
		var avatar: Control = battle.battle_seat_nodes[seat]
		check(not chat.panel.get_global_rect().intersects(avatar.get_global_rect()), "Chat should leave seat %d clear at %d seats" % [seat, seats])
	await screenshot("chat_battle_%d.png" % seats)
	battle.queue_free()
	await process_frame

func _verify_legacy_network() -> void:
	# Reproduce the reported runtime: NetworkClient is a Node whose loaded
	# script has no chat signals yet, as with an instance started before this edit.
	var current_script: Script = network.get_script()
	var legacy_script := GDScript.new()
	legacy_script.source_code = "extends Node\n"
	check(legacy_script.reload() == OK, "Legacy script fixture should compile")
	network.set_script(legacy_script)
	var chat = load("res://scenes/components/chat_panel.gd").new()
	root.add_child(chat)
	await process_frame
	check(not chat._network_ready, "Chat should detect an autoload without chat signals")
	check(chat.status_label.text.contains("Khởi động lại"), "An old autoload should show a restart instruction")
	check(chat.input.editable and chat.send_button.disabled, "Chat should allow a draft with an old autoload")
	chat._send_message()
	chat.queue_free()
	await process_frame
	network.set_script(current_script)

func _type_into_chat(chat: Control) -> void:
	chat.input.clear()
	chat.input.release_focus()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = chat.input.get_global_rect().get_center()
	root.push_input(click, true)
	click = click.duplicate()
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	check(chat.input.has_focus(), "Clicking the chat input must focus it")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_H
	key.unicode = "h".unicode_at(0)
	root.push_input(key, true)
	await process_frame
	check(chat.input.text == "h", "Chat must accept an actual keyboard event")
	chat.input.clear()

func _verify_chat_transport() -> void:
	# Use a local socket fixture to exercise Enter -> wire packet -> server ack.
	# Production server discovery/configuration is untouched.
	var listener := TCPServer.new()
	if listener.listen(0, "127.0.0.1") != OK:
		check(false, "Chat transport fixture should listen")
		return
	var client := WebSocketPeer.new()
	var server := WebSocketPeer.new()
	client.connect_to_url("ws://127.0.0.1:%d" % listener.get_local_port())
	var accepted: bool = false
	var deadline: int = Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < deadline:
		client.poll()
		if not accepted and listener.is_connection_available():
			accepted = server.accept_stream(listener.take_connection()) == OK
		server.poll()
		if client.get_ready_state() == WebSocketPeer.STATE_OPEN and server.get_ready_state() == WebSocketPeer.STATE_OPEN:
			break
		await process_frame
	if client.get_ready_state() != WebSocketPeer.STATE_OPEN:
		check(false, "Chat transport fixture should connect")
		listener.stop()
		return
	var original_socket: WebSocketPeer = network.socket
	network.socket = client
	network.is_connected_to_server = true
	network._chat_unavailable = false
	network._pending_chat_channels.clear()
	var chat = load("res://scenes/components/chat_panel.gd").new()
	root.add_child(chat)
	await _pump_chat_socket(server)
	while server.get_available_packet_count() > 0:
		server.get_packet()
	check(chat.input.editable and not chat.send_button.disabled, "Connected chat should allow typing before history arrives")
	await _type_into_chat(chat)
	chat.input.text = "Tin kiểm thử gửi bằng Enter"
	var enter := InputEventKey.new()
	enter.pressed = true
	enter.keycode = KEY_ENTER
	enter.unicode = 13
	root.push_input(enter, true)
	await _pump_chat_socket(server)
	var sent: Dictionary = {}
	while server.get_available_packet_count() > 0:
		var data = JSON.parse_string(server.get_packet().get_string_from_utf8())
		if data is Dictionary and data.get("action", "") == "CHAT_SEND":
			sent = data
	check(sent.get("text", "") == "Tin kiểm thử gửi bằng Enter", "Enter should send the typed message over WebSocket")
	check(not chat.input.text.is_empty(), "Sending must retain the draft until acknowledgment")
	server.send_text(JSON.stringify({"type": "CHAT_MESSAGE", "channel": "lobby", "id": "transport-ack", "userId": "chat-ui-test", "userName": "Tướng Quân", "text": sent.get("text", "")}))
	await _pump_chat_socket(server)
	check(chat.input.text.is_empty(), "A real socket acknowledgment should clear the sent draft")
	chat.queue_free()
	await process_frame
	client.close()
	server.close()
	listener.stop()
	network.socket = original_socket
	network.is_connected_to_server = false

func _pump_chat_socket(server: WebSocketPeer) -> void:
	for _frame in range(8):
		server.poll()
		network._process(0.0)
		await process_frame
