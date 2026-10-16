extends Control

## Shared lobby / match chat. Match chat starts folded to keep the table clear.
signal player_profile_requested(player_data: Dictionary)

var channel: String = "lobby"
var panel: PanelContainer
var toggle_button: Button
var messages_view: RichTextLabel
var input: LineEdit
var send_button: Button
var status_label: Label
var unread_count: int = 0
var _history_requested: bool = false
var _pending_text: String = ""
var _send_started_at: int = 0
var _network_ready: bool = false

func _ready() -> void:
	name = "ChatPanel"
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_ui()
	if not _connect_network():
		return
	_on_connected()
	_render_messages()

func _connect_network() -> bool:
	# An already-running Godot instance can retain the autoload from before
	# chat was added. Check the API before connecting or calling chat methods.
	var bindings: Dictionary = {
		"chat_message_received": _on_message,
		"chat_history_received": _on_history,
		"chat_error": _on_error,
		"connection_established": _on_connected,
		"connection_closed": _on_disconnected,
	}
	if channel == "battle":
		bindings["game_state_updated"] = _on_battle_state
	for signal_name in bindings:
		if not NetworkClient.has_signal(signal_name):
			_show_restart_required()
			return false
	for method_name in ["get_chat_messages", "request_chat_history", "send_chat_message", "register_social_profile", "send_json"]:
		if not NetworkClient.has_method(method_name):
			_show_restart_required()
			return false
	for signal_name in bindings:
		if not NetworkClient.is_connected(signal_name, bindings[signal_name]):
			NetworkClient.connect(signal_name, bindings[signal_name])
	_network_ready = true
	return true

func _show_restart_required() -> void:
	status_label.text = "Khởi động lại game để cập nhật chat."
	status_label.tooltip_text = status_label.text
	messages_view.add_text("Dừng game rồi chạy lại để nạp phần trò chuyện mới.")
	input.editable = true
	send_button.disabled = true

func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _style(Color(0.08, 0.12, 0.18, 0.98), Color(0.62, 0.48, 0.22)))
	button.add_theme_stylebox_override("hover", _style(Color(0.16, 0.20, 0.26), Color(0.96, 0.80, 0.36)))
	button.add_theme_stylebox_override("pressed", _style(Color(0.05, 0.08, 0.12), Color(0.96, 0.80, 0.36)))
	button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.54))
	button.add_theme_font_size_override("font_size", 12)
	button.focus_mode = FOCUS_NONE
	button.mouse_default_cursor_shape = CURSOR_POINTING_HAND

func _build_ui() -> void:
	toggle_button = Button.new()
	toggle_button.name = "ChatToggle"
	_style_button(toggle_button)
	add_child(toggle_button)
	if channel == "battle":
		toggle_button.position = Vector2(222, 18)
		toggle_button.size = Vector2(160, 40)
	else:
		toggle_button.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
		toggle_button.offset_left = 24
		toggle_button.offset_right = 228
		toggle_button.offset_top = -66
		toggle_button.offset_bottom = -24
	toggle_button.pressed.connect(func(): _set_open(not panel.visible))

	panel = PanelContainer.new()
	panel.name = "ChatWindow"
	panel.set_anchors_and_offsets_preset(PRESET_BOTTOM_LEFT)
	panel.offset_left = 18 if channel == "battle" else 24
	panel.offset_right = 288 if channel == "battle" else 464
	panel.offset_top = -238 if channel == "battle" else -284
	panel.offset_bottom = -18 if channel == "battle" else -24
	panel.add_theme_stylebox_override("panel", _style(Color(0.035, 0.045, 0.075, 0.96), Color(0.69, 0.55, 0.27, 0.9)))
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "CHAT TRẬN" if channel == "battle" else "TRÒ CHUYỆN · SẢNH CHUNG"
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.98, 0.83, 0.45))
	header.add_child(title)
	var collapse := Button.new()
	collapse.text = "−"
	collapse.tooltip_text = "Thu gọn trò chuyện"
	collapse.custom_minimum_size = Vector2(36, 32)
	_style_button(collapse)
	header.add_child(collapse)
	collapse.pressed.connect(func(): _set_open(false))
	messages_view = RichTextLabel.new()
	messages_view.name = "Messages"
	messages_view.size_flags_vertical = SIZE_EXPAND_FILL
	messages_view.custom_minimum_size = Vector2(0, 64)
	messages_view.bbcode_enabled = true
	messages_view.scroll_following = true
	messages_view.selection_enabled = true
	messages_view.meta_clicked.connect(_on_meta_clicked)
	messages_view.add_theme_font_size_override("normal_font_size", 12)
	messages_view.add_theme_color_override("default_color", Color(0.90, 0.92, 0.96))
	content.add_child(messages_view)
	status_label = Label.new()
	status_label.text = "Đang kết nối trò chuyện..."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if channel == "battle":
		status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		status_label.clip_text = true
		status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color(0.66, 0.72, 0.80))
	content.add_child(status_label)
	var composer := HBoxContainer.new()
	composer.add_theme_constant_override("separation", 6)
	content.add_child(composer)
	input = LineEdit.new()
	input.name = "ChatInput"
	input.size_flags_horizontal = SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 40)
	input.max_length = 280
	input.editable = true
	input.placeholder_text = "Nhập tin nhắn..."
	input.add_theme_font_size_override("font_size", 12)
	input.add_theme_stylebox_override("normal", _style(Color(0.02, 0.03, 0.05), Color(0.28, 0.34, 0.44)))
	input.add_theme_stylebox_override("focus", _style(Color(0.04, 0.06, 0.09), Color(0.96, 0.80, 0.36)))
	composer.add_child(input)
	input.text_submitted.connect(func(_text: String): _send_message())
	send_button = Button.new()
	send_button.text = "Gửi"
	send_button.disabled = true
	send_button.custom_minimum_size = Vector2(48, 40)
	_style_button(send_button)
	composer.add_child(send_button)
	send_button.pressed.connect(_send_message)
	_set_open(channel == "lobby")

func _set_open(open: bool) -> void:
	panel.visible = open
	toggle_button.visible = channel == "battle" or not open
	if open:
		unread_count = 0
	else:
		input.release_focus()
	_update_toggle()
	if channel == "battle" and get_parent().has_method("_relayout_hand_cards"):
		get_parent().call_deferred("_relayout_hand_cards")

func set_battle_seat_count(seat_count: int) -> void:
	# Eight-player tables have an extra avatar at the bottom left.
	panel.offset_left = 234 if seat_count >= 8 else 18
	panel.offset_right = panel.offset_left + 270

func _update_toggle() -> void:
	toggle_button.text = "CHAT TRẬN" if channel == "battle" else "TRÒ CHUYỆN"
	if unread_count > 0:
		toggle_button.text += " (%d)" % mini(unread_count, 99)
	toggle_button.tooltip_text = "Mở / thu gọn trò chuyện"

func _on_connected() -> void:
	_history_requested = false
	if not NetworkClient.is_connected_to_server:
		_on_disconnected()
		return
	input.editable = true
	send_button.disabled = false
	status_label.text = "Đang đồng bộ trò chuyện..."
	if channel == "lobby":
		NetworkClient.register_social_profile()
		_request_history()

func _on_disconnected() -> void:
	_history_requested = false
	_pending_text = ""
	input.editable = true
	send_button.disabled = true
	status_label.text = "Chưa kết nối. Bạn có thể nhập trước."
	status_label.tooltip_text = status_label.text

func _on_battle_state(_state: Dictionary) -> void:
	if NetworkClient.is_connected_to_server and not _history_requested and not NetworkClient.room_id.is_empty():
		_request_history()

func _request_history() -> void:
	_history_requested = true
	NetworkClient.request_chat_history(channel)

func _on_history(received_channel: String, target_room: String) -> void:
	if received_channel != channel or (channel == "battle" and target_room != NetworkClient.room_id):
		return
	_history_requested = true
	input.editable = true
	send_button.disabled = false
	status_label.text = "Mọi người trong trận đều đọc được" if channel == "battle" else "Trò chuyện cùng người chơi trực tuyến"
	_render_messages()

func _on_meta_clicked(meta: Variant) -> void:
	var p_data: Dictionary = {}
	if meta is String:
		var parsed = JSON.parse_string(meta)
		if parsed is Dictionary:
			p_data = parsed
	elif meta is Dictionary:
		p_data = meta
	if not p_data.is_empty():
		player_profile_requested.emit(p_data)

func _render_messages() -> void:
	messages_view.clear()
	var messages := NetworkClient.get_chat_messages(channel)
	if messages.is_empty():
		messages_view.add_text("Chưa có tin nhắn. Hãy gửi lời chào!")
		return
	for message in messages:
		var sender_raw: String = str(message.get("userName", "Người chơi")).strip_edges()
		if sender_raw.is_empty():
			sender_raw = "Người chơi"
		var sender_disp = sender_raw
		if channel == "battle":
			sender_disp = "Ghế %d · %s" % [int(message.get("seat", 0)), sender_raw]
		var title_id: String = str(message.get("title", "")).strip_edges().to_lower()
		var player_meta = {
			"user_id": str(message.get("userId", "")),
			"name": sender_raw,
			"title": title_id,
			"profile_bg": int(message.get("profileBg", message.get("profile_bg", 0))),
			"level": int(message.get("level", 1)),
			"rank_index": int(message.get("rankIndex", 0))
		}
		var meta_str = JSON.stringify(player_meta)
		# Tên người chơi có link để click xem hồ sơ
		messages_view.append_text("[url=%s][b][color=#fadb72]%s[/color][/b][/url]" % [meta_str, sender_disp])
		# Danh hiệu bên cạnh tên (ví dụ: ADMIN 7 sắc cầu vồng nhấp nháy neon)
		if title_id == "admin":
			messages_view.append_text(" [url=%s][rainbow freq=0.6 sat=1.0 val=1.0][b]ADMIN[/b][/rainbow][/url]" % meta_str)
		elif not title_id.is_empty():
			messages_view.append_text(" [url=%s][b][color=#e0b0ff][%s][/color][/b][/url]" % [meta_str, title_id.to_upper()])
		messages_view.append_text(": ")
		# add_text bảo vệ tin nhắn của người chơi tránh bị tiêm BBCode
		messages_view.add_text(str(message.get("text", "")) + "\n")

func _on_message(message: Dictionary) -> void:
	if str(message.get("channel", "")) != channel:
		return
	if channel == "battle" and str(message.get("roomId", "")) != NetworkClient.room_id:
		return
	var own: bool = int(message.get("seat", -1)) == NetworkClient.my_seat if channel == "battle" else str(message.get("userId", "")) == AuthManager.current_user_id
	if own and not _pending_text.is_empty():
		if input.text.strip_edges() == _pending_text:
			input.clear()
		_pending_text = ""
		status_label.text = "Mọi người trong trận đều đọc được" if channel == "battle" else "Trò chuyện cùng người chơi trực tuyến"
	if not panel.visible and not own:
		unread_count += 1
		_update_toggle()
	_render_messages()

func _on_error(received_channel: String, message: String) -> void:
	if received_channel != channel:
		return
	_pending_text = ""
	status_label.text = message
	status_label.tooltip_text = message

func _send_message() -> void:
	if not _network_ready:
		return
	if not _pending_text.is_empty() and Time.get_ticks_msec() - _send_started_at < 5000:
		return
	var text := input.text.strip_edges()
	if text.is_empty():
		return
	if NetworkClient.send_chat_message(channel, text):
		_pending_text = text
		_send_started_at = Time.get_ticks_msec()
		status_label.text = "Đang gửi..."

func _exit_tree() -> void:
	if _network_ready and channel == "lobby" and NetworkClient.is_connected_to_server:
		NetworkClient.send_json({"action": "CHAT_UNSUBSCRIBE", "channel": channel})
