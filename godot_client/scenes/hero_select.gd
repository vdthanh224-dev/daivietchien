extends Control

# Màn Chọn Tướng 2v2 (Draft Phase) - Chuẩn Unity Battle2v2UI.cs
# - Tướng xoay tua Thứ 2 hàng tuần (10 tướng Free tuần)
# - Tướng người chơi đã sở hữu (Appwrite / AuthManager)
# - Bố cục 3 cột: 4 Ghế bên trái, Lưới thẻ tướng ở giữa, Soi tuyệt kỹ & Khóa tướng bên phải

# Palette Màu Hoàng Triều
const COLOR_GOLD_PRIMARY = Color(0.85, 0.70, 0.25, 1.0)
const COLOR_GOLD_ACCENT  = Color(1.00, 0.88, 0.40, 1.0)
const COLOR_BG_DARK      = Color(0.04, 0.07, 0.12, 1.0)
const COLOR_PANEL_BG     = Color(0.06, 0.10, 0.18, 0.95)
const COLOR_DRAGON_CYAN  = Color(0.35, 0.78, 1.00, 1.0)
const COLOR_PHOENIX_RED  = Color(1.00, 0.38, 0.45, 1.0)
const COLOR_TEXT_MUTED   = Color(0.65, 0.72, 0.82, 1.0)

# Trạng thái phòng & lượt chọn
var room_data: Dictionary = {}
var draft_slots: Array[Dictionary] = []
var available_heroes: Array[Dictionary] = []
var selected_hero_ids: Array[int] = []
var inspecting_hero: Dictionary = {}
var current_picker_index: int = 0
var turn_timer: float = 40.0
var is_draft_active: bool = true
var is_player_locked: bool = false
var current_room_id: String = ""
var is_host: bool = false
var is_network_mode: bool = false
var _draft_joined: bool = false
var _pending_pick_hero_id: int = 0
var _pending_pick_seat: int = 0
# Drop delayed draft snapshots so a late packet cannot roll a client back.
var _last_draft_revision: int = 0

# UI References
var draft_status_lbl: Label
var turn_timer_lbl: Label
var left_slot_nodes: Array[Dictionary] = []
var hero_card_nodes: Dictionary = {} # hero_id -> card Node
var right_inspect_panel: Control
var inspect_title_lbl: Label
var inspect_sub_lbl: Label
var inspect_avatar_rect: TextureRect
var inspect_lotus_container: HBoxContainer
var inspect_skill_title_lbl: Label
var inspect_skill_desc_lbl: Label
var lock_in_btn: Button
var lock_in_btn_lbl: Label

func _ready() -> void:
	var current_room = AppwriteMatchmaking.current_room if AppwriteMatchmaking else {}
	current_room_id = current_room.get("roomId", "")
	if current_room_id.is_empty():
		current_room_id = "room_1"
	var args = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if "--guest-test" in args and AppwriteMatchmaking:
		AppwriteMatchmaking.is_host = false

	if AppwriteMatchmaking and ("is_host" in AppwriteMatchmaking):
		is_host = AppwriteMatchmaking.is_host
	else:
		var my_uid = AppwriteMatchmaking.my_session_user_id if AppwriteMatchmaking and not AppwriteMatchmaking.my_session_user_id.is_empty() else (AuthManager.current_user_id if AuthManager else "")
		var host_uid = current_room.get("hostUserId", "")
		if host_uid.is_empty() or host_uid == my_uid:
			is_host = true
		elif AppwriteMatchmaking:
			is_host = AppwriteMatchmaking.is_same_user(host_uid, "", my_uid, "")
		else:
			is_host = false
	print("[HeroSelect] Vai trò phòng: %s (Room ID: %s)" % ["MÁY CHỦ (HOST)" if is_host else "MÁY KHÁCH (GUEST)", current_room_id])
	print("[HeroSelect] Draft room status=%s slots=%d network_url=%s" % [str(current_room.get("status", "")), int(current_room.get("slots", []).size()), NetworkClient.active_server_url if NetworkClient else "NONE"])

	# Khởi tạo dữ liệu tướng khả dụng từ HeroDatabase
	if HeroDatabase:
		available_heroes = HeroDatabase.get_available_pick_heroes()
	else:
		available_heroes = []

	_setup_draft_slots()
	_build_ui()

	if not available_heroes.is_empty():
		_inspect_hero(available_heroes[0])

	_connect_network_draft()

	# Kiểm tra kết nối máy chủ WebSocket Deno
	if NetworkClient:
		# A scene transition can land while the autoload is between reconnect
		# attempts. Start the cloud connection here instead of failing before
		# NetworkClient's next heartbeat gets a chance to run.
		if not NetworkClient.is_connected_to_server:
			NetworkClient.connect_to_server()
			var wait_t := 0.0
			var retry_t := 0.0
			while wait_t < 15.0 and not NetworkClient.is_connected_to_server:
				await get_tree().create_timer(0.1).timeout
				wait_t += 0.1
				retry_t += 0.1
				if retry_t >= 1.0 and not NetworkClient.is_connecting():
					retry_t = 0.0
					NetworkClient.connect_to_server()
		is_network_mode = NetworkClient.is_connected_to_server
	else:
		is_network_mode = false

	if "--screenshot-hero-select" in args:
		_run_automated_screenshot()
		return

	if _requires_network_draft() and not is_network_mode:
		_show_no_server_modal("Phòng có nhiều người chơi nhưng chưa kết nối được máy chủ chọn tướng. Vui lòng kiểm tra máy chủ rồi thử lại.")
		return
	_start_draft_sequence()

func _requires_network_draft() -> bool:
	var current_room = AppwriteMatchmaking.current_room if AppwriteMatchmaking else {}
	var slots = current_room.get("slots", []) if current_room is Dictionary else []
	# A matched room is authoritative even when it currently has bots. Letting
	# one client switch to local draft makes its picker state diverge from peers.
	if current_room is Dictionary and slots is Array and slots.size() == 4 and str(current_room.get("status", "")) == "STARTED":
		return true
	var human_count := 0
	for slot in slots:
		if not (slot is Dictionary) or bool(slot.get("isEmpty", false)):
			continue
		var uid := str(slot.get("userId", "")).to_lower()
		if not bool(slot.get("isAI", false)) and not uid.begins_with("bot_"):
			human_count += 1
	return human_count >= 2

func _setup_draft_slots() -> void:
	draft_slots.clear()
	var current_room = AppwriteMatchmaking.current_room if AppwriteMatchmaking else {}
	var slots = current_room.get("slots", [])

	var my_name = ""
	var my_uid = ""
	if AppwriteMatchmaking and not AppwriteMatchmaking.my_session_user_id.is_empty():
		my_uid = AppwriteMatchmaking.my_session_user_id
		my_name = AppwriteMatchmaking.my_session_user_name
	if my_uid.is_empty() and AuthManager:
		my_uid = AuthManager.current_user_id
	if my_name.is_empty() and AuthManager and AuthManager.current_user_name != "":
		my_name = AuthManager.current_user_name
	if my_name.is_empty():
		my_name = "Đại Tướng Quân"

	# Dùng UID/tên khi duy nhất; UID trùng trong debug phải giữ ghế riêng của cửa sổ.
	var my_seat_idx = -1
	if slots.size() == 4:
		if NetworkClient and NetworkClient.seat_is_explicit and NetworkClient.my_seat in [1, 2, 3, 4]:
			# Explicit debug seats must win over the shared local UID/name.
			my_seat_idx = NetworkClient.my_seat - 1
		else:
			var identity_matches: Array[int] = []
			for i in range(4):
				var s = slots[i]
				if not bool(s.get("isEmpty", false)):
					var slot_uid = str(s.get("userId", "")).strip_edges()
					var slot_name = str(s.get("userName", "")).strip_edges()
					if (not my_uid.is_empty() and slot_uid == my_uid) or (not my_name.is_empty() and slot_name.to_lower() == my_name.to_lower()):
						identity_matches.append(i)
			if identity_matches.size() == 1:
				my_seat_idx = identity_matches[0]
		# Cuối cùng mới chọn ghế người thật đầu tiên.
		if my_seat_idx == -1:
			for i in range(4):
				var s = slots[i]
				if not bool(s.get("isAI", false)) and not bool(s.get("isEmpty", false)):
					my_seat_idx = i
					break
	if my_seat_idx == -1 and slots.size() != 4 and NetworkClient and NetworkClient.my_seat in [1, 2, 3, 4]:
		my_seat_idx = NetworkClient.my_seat - 1

	if my_seat_idx == -1:
		my_seat_idx = 0

	var my_seat_num = my_seat_idx + 1
	if NetworkClient:
		NetworkClient.my_seat = my_seat_num
	print("[HeroSelect] Xác định ghế của bạn: Ghế %d (UID: %s, Tên: %s)" % [my_seat_num, my_uid, my_name])

	var used_names: Array = []

	if slots.size() == 4:
		for i in range(4):
			var s = slots[i]
			var s_num = int(s.get("seatNumber", i + 1))
			var is_me = (i == my_seat_idx)

			var uname = ""
			if is_me:
				uname = my_name
			else:
				uname = s.get("userName", "").strip_edges()
				if uname.is_empty() or uname in used_names:
					if AppwriteMatchmaking:
						uname = AppwriteMatchmaking.get_realistic_gamer_name(s_num * 101 + 42, used_names)
					else:
						uname = "Chiến Tướng %d" % s_num

			used_names.append(uname)

			var is_drag = bool(s.get("isDragon", s_num == 1 or s_num == 3))
			var role_tag = "[RỒNG]" if is_drag else "[PHƯỢNG]"
			var is_ai = false if is_me else bool(s.get("isAI", true))

			draft_slots.append({
				"seatNumber": s_num,
				"userId": s.get("userId", ""),
				"userName": uname,
				"roleTag": role_tag,
				"isPlayer": is_me,
				"isDragon": is_drag,
				"isAI": is_ai,
				"chosenHero": null,
				"isLocked": false
			})
	else:
		# Mặc định 4 ghế chuẩn 2v2 với ghế tương ứng với cửa sổ client
		var local_seat = NetworkClient.my_seat if NetworkClient and NetworkClient.my_seat in [1, 2, 3, 4] else 1
		var random_team_seats = [1, 2, 3, 4]
		random_team_seats.shuffle()
		var dragon_seats = random_team_seats.slice(0, 2)
		draft_slots = []
		for s_num in range(1, 5):
			var is_me = (s_num == local_seat)
			var uname = my_name if is_me else ("Chiến Tướng %d" % s_num)
			var is_drag = dragon_seats.has(s_num)
			var role_tag = "[RỒNG]" if is_drag else "[PHƯỢNG]"
			draft_slots.append({
				"seatNumber": s_num,
				"userName": uname,
				"roleTag": role_tag,
				"isPlayer": is_me,
				"isDragon": is_drag,
				"isAI": not is_me,
				"chosenHero": null,
				"isLocked": false
			})

func _get_anonymous_slot_name(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= draft_slots.size():
		return "Người chơi"
	var s = draft_slots[slot_idx]
	var my_seat_num = NetworkClient.my_seat if NetworkClient and NetworkClient.my_seat in [1, 2, 3, 4] else 1
	var s_num = int(s.get("seatNumber", slot_idx + 1))
	var is_me = bool(s.get("isPlayer", false)) or (s_num == my_seat_num)
	if is_me:
		return "BẠN (Đồng minh 1)"

	# Phe của người chơi
	var my_is_dragon = true
	for local_s in draft_slots:
		if bool(local_s.get("isPlayer", false)) or int(local_s.get("seatNumber", 0)) == my_seat_num:
			my_is_dragon = bool(local_s.get("isDragon", true))
			break

	var is_ally = (bool(s.get("isDragon", true)) == my_is_dragon)
	if is_ally:
		return "Đồng minh 2"

	var enemy_count = 1
	for j in range(slot_idx):
		var prev_s = draft_slots[j]
		var prev_is_ally = (bool(prev_s.get("isDragon", true)) == my_is_dragon)
		var prev_is_me = bool(prev_s.get("isPlayer", false)) or (int(prev_s.get("seatNumber", 0)) == my_seat_num)
		if not prev_is_ally and not prev_is_me:
			enemy_count += 1
	return "Đối thủ %d" % enemy_count

func _build_ui() -> void:
	# 1. Nền màn hình chính
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = COLOR_BG_DARK
	add_child(bg)

	# 2. Header Bar (y: 0..56)
	_build_header()

	# 3. Thân 3 Cột (y: 64..710)
	var body_hbox = HBoxContainer.new()
	body_hbox.set_anchors_preset(PRESET_FULL_RECT)
	body_hbox.offset_left = 16
	body_hbox.offset_right = -16
	body_hbox.offset_top = 64
	body_hbox.offset_bottom = -12
	body_hbox.add_theme_constant_override("separation", 14)
	add_child(body_hbox)

	# Cột Trái: 4 Ghế Thi Đấu (width: 250px)
	var left_col = _build_left_slots_column()
	left_col.custom_minimum_size = Vector2(250, 0)
	body_hbox.add_child(left_col)

	# Cột Giữa: Lưới Danh Tướng Khả Dụng (Expand)
	var center_col = _build_center_grid_column()
	center_col.size_flags_horizontal = SIZE_EXPAND_FILL
	body_hbox.add_child(center_col)

	# Cột Phải: Soi Tuyệt Kỹ & Khóa Tướng (width: 320px)
	var right_col = _build_right_inspect_column()
	right_col.custom_minimum_size = Vector2(320, 0)
	body_hbox.add_child(right_col)

func _build_header() -> void:
	var header = PanelContainer.new()
	header.set_anchors_preset(PRESET_TOP_WIDE)
	header.offset_bottom = 56
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color(0.03, 0.05, 0.10, 0.98)
	h_style.border_width_bottom = 1
	h_style.border_color = Color(0.85, 0.70, 0.25, 0.6)
	header.add_theme_stylebox_override("panel", h_style)
	add_child(header)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	header.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	# Tiêu đề game
	var title = Label.new()
	title.text = "👑 ĐẠI VIỆT CHIẾN • CHỌN TƯỚNG 2v2 XẾP HẠNG"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	hbox.add_child(title)

	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(spacer1)

	# Trạng thái lượt chọn
	draft_status_lbl = Label.new()
	draft_status_lbl.text = "⏳ Đang chuẩn bị lượt chọn tướng 1..4..."
	draft_status_lbl.add_theme_font_size_override("font_size", 14)
	draft_status_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN)
	draft_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(draft_status_lbl)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(spacer2)

	# Đồng hồ đếm ngược lượt chọn
	var timer_box = PanelContainer.new()
	timer_box.custom_minimum_size = Vector2(140, 36)
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.08, 0.12, 0.22, 0.95)
	tb_style.border_width_left = 1
	tb_style.border_width_top = 1
	tb_style.border_width_right = 1
	tb_style.border_width_bottom = 1
	tb_style.border_color = COLOR_GOLD_PRIMARY
	tb_style.corner_radius_top_left = 6
	tb_style.corner_radius_top_right = 6
	tb_style.corner_radius_bottom_right = 6
	tb_style.corner_radius_bottom_left = 6
	timer_box.add_theme_stylebox_override("panel", tb_style)
	hbox.add_child(timer_box)

	var tb_hbox = HBoxContainer.new()
	tb_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_box.add_child(tb_hbox)

	turn_timer_lbl = Label.new()
	turn_timer_lbl.text = "⏳ 40s"
	turn_timer_lbl.add_theme_font_size_override("font_size", 14)
	turn_timer_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	tb_hbox.add_child(turn_timer_lbl)

	# Nút Rời Phòng / Hủy
	var exit_btn = Button.new()
	exit_btn.custom_minimum_size = Vector2(36, 36)
	exit_btn.text = "✕"
	exit_btn.tooltip_text = "Rời phòng chọn tướng"
	_style_cancel_small_btn(exit_btn)
	exit_btn.pressed.connect(_on_exit_pressed)
	hbox.add_child(exit_btn)

func _build_left_slots_column() -> Control:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var title = Label.new()
	title.text = "⚔️ THỨ TỰ CHỌN (#1 ➜ #4):"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	col.add_child(title)

	left_slot_nodes.clear()
	for i in range(draft_slots.size()):
		var slot_data = draft_slots[i]
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(0, 134)

		var sp_style = StyleBoxFlat.new()
		sp_style.bg_color = Color(0.06, 0.09, 0.16, 0.95)
		sp_style.border_width_left = 2
		sp_style.border_width_top = 2
		sp_style.border_width_right = 2
		sp_style.border_width_bottom = 2
		sp_style.border_color = COLOR_DRAGON_CYAN if slot_data["isDragon"] else COLOR_PHOENIX_RED
		sp_style.corner_radius_top_left = 6
		sp_style.corner_radius_top_right = 6
		sp_style.corner_radius_bottom_right = 6
		sp_style.corner_radius_bottom_left = 6
		slot_panel.add_theme_stylebox_override("panel", sp_style)
		col.add_child(slot_panel)

		var s_margin = MarginContainer.new()
		s_margin.add_theme_constant_override("margin_left", 8)
		s_margin.add_theme_constant_override("margin_right", 8)
		s_margin.add_theme_constant_override("margin_top", 8)
		s_margin.add_theme_constant_override("margin_bottom", 8)
		slot_panel.add_child(s_margin)

		var s_vbox = VBoxContainer.new()
		s_vbox.add_theme_constant_override("separation", 4)
		s_margin.add_child(s_vbox)

		# Row 1: Team tag + Seat + Player title
		var r1_hbox = HBoxContainer.new()
		s_vbox.add_child(r1_hbox)

		var team_lbl = Label.new()
		team_lbl.text = slot_data.get("roleTag", "[RỒNG]" if slot_data["isDragon"] else "[PHƯỢNG]")
		team_lbl.add_theme_font_size_override("font_size", 12)
		team_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if slot_data["isDragon"] else COLOR_PHOENIX_RED)
		r1_hbox.add_child(team_lbl)

		var seat_lbl = Label.new()
		seat_lbl.text = _get_anonymous_slot_name(i)
		seat_lbl.add_theme_font_size_override("font_size", 12)
		seat_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0) if slot_data["isPlayer"] else Color.WHITE)
		seat_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		r1_hbox.add_child(seat_lbl)

		# Row 2: Avatar + Hero Name + Status
		var r2_hbox = HBoxContainer.new()
		r2_hbox.add_theme_constant_override("separation", 8)
		s_vbox.add_child(r2_hbox)

		var av_panel = PanelContainer.new()
		av_panel.custom_minimum_size = Vector2(56, 72)
		var av_style = StyleBoxFlat.new()
		av_style.bg_color = Color(0, 0, 0, 0)
		av_style.corner_radius_top_left = 6
		av_style.corner_radius_top_right = 6
		av_style.corner_radius_bottom_right = 6
		av_style.corner_radius_bottom_left = 6
		av_panel.add_theme_stylebox_override("panel", av_style)
		av_panel.clip_contents = true

		var av_bg = TextureRect.new()
		av_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		av_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		av_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av_bg.texture = preload("res://assets/ui/hero_backgrounds/bg_hero_green.png") if slot_data["isDragon"] else preload("res://assets/ui/hero_backgrounds/bg_hero_red.png")
		av_panel.add_child(av_bg)

		var av_rect = TextureRect.new()
		av_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		av_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		av_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var def_tex = HeroDatabase.get_avatar_texture("") if HeroDatabase else null
		if def_tex: av_rect.texture = def_tex
		av_rect.modulate = Color(1.0, 1.0, 1.0, 0.4)
		av_panel.add_child(av_rect)
		r2_hbox.add_child(av_panel)

		var info_v = VBoxContainer.new()
		info_v.size_flags_horizontal = SIZE_EXPAND_FILL
		info_v.alignment = BoxContainer.ALIGNMENT_CENTER
		r2_hbox.add_child(info_v)

		var hero_name_l = Label.new()
		hero_name_l.text = "Chưa chọn..."
		hero_name_l.add_theme_font_size_override("font_size", 13)
		hero_name_l.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		info_v.add_child(hero_name_l)

		var status_l = Label.new()
		status_l.text = "⏳ Chờ lượt..."
		status_l.add_theme_font_size_override("font_size", 11)
		status_l.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		info_v.add_child(status_l)

		left_slot_nodes.append({
			"panel": slot_panel,
			"style": sp_style,
			"team": team_lbl,
			"player": seat_lbl,
			"avatar": av_rect,
			"bg": av_bg,
			"hero_name": hero_name_l,
			"status": status_l,
			"data": slot_data
		})

	return col

func _build_center_grid_column() -> Control:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)

	var count_str = str(available_heroes.size())
	var title = Label.new()
	title.text = "🎴 DANH TƯỚNG KHẢ DỤNG (%s TƯỚNG SỞ HỮU & FREE TUẦN) • Chạm thẻ để xem tuyệt kỹ:" % count_str
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.95))
	col.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(grid)

	hero_card_nodes.clear()
	for hero in available_heroes:
		var card = _create_hero_grid_card(hero)
		grid.add_child(card)
		hero_card_nodes[hero["id"]] = card

	return col

func _create_hero_grid_card(hero: Dictionary) -> Control:
	var hid = int(hero.get("id", 1))
	var is_free = bool(hero.get("is_weekly_free", false))

	var card_btn = Button.new()
	card_btn.custom_minimum_size = Vector2(144, 196)
	card_btn.pivot_offset = Vector2(72, 98)
	card_btn.focus_mode = Control.FOCUS_NONE

	# Base Panel Style
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.06, 0.09, 0.16, 0.98)
	base_style.border_width_left = 1
	base_style.border_width_top = 1
	base_style.border_width_right = 1
	base_style.border_width_bottom = 1
	base_style.border_color = COLOR_GOLD_PRIMARY if is_free else Color(0.30, 0.65, 0.90, 0.85)
	base_style.corner_radius_top_left = 6
	base_style.corner_radius_top_right = 6
	base_style.corner_radius_bottom_right = 6
	base_style.corner_radius_bottom_left = 6
	var hover_style = base_style.duplicate() as StyleBoxFlat
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = COLOR_GOLD_ACCENT
	hover_style.shadow_color = Color(0.95, 0.75, 0.22, 0.35)
	hover_style.shadow_size = 6
	card_btn.add_theme_stylebox_override("normal", base_style)
	card_btn.add_theme_stylebox_override("hover", hover_style)
	card_btn.add_theme_stylebox_override("pressed", base_style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_btn.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# 1. Top Bar: Tên tướng + Sen Máu
	var top_hbox = HBoxContainer.new()
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_hbox)

	var name_lbl = Label.new()
	name_lbl.text = hero.get("name", "")
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	name_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	top_hbox.add_child(name_lbl)

	var lotus_hbox = HBoxContainer.new()
	lotus_hbox.add_theme_constant_override("separation", 1)
	top_hbox.add_child(lotus_hbox)

	var hp_count = int(hero.get("maxHp", 4))
	var lotus_tex = load("res://assets/ui/lotus_full.png") if ResourceLoader.exists("res://assets/ui/lotus_full.png") else null
	for i in range(hp_count):
		var l_rect = TextureRect.new()
		l_rect.custom_minimum_size = Vector2(11, 11)
		l_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		l_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if lotus_tex: l_rect.texture = lotus_tex
		lotus_hbox.add_child(l_rect)

	# 2. Avatar Container
	var av_container = Control.new()
	av_container.custom_minimum_size = Vector2(0, 115)
	av_container.size_flags_vertical = SIZE_EXPAND_FILL
	av_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(av_container)

	var av_rect = TextureRect.new()
	av_rect.set_anchors_preset(PRESET_FULL_RECT)
	av_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex = HeroDatabase.get_avatar_texture(hero.get("avatarPath", "")) if HeroDatabase else null
	if tex: av_rect.texture = tex
	av_container.add_child(av_rect)

	# Huy hiệu Free Tuần (Góc trên trái avatar)
	if is_free:
		var free_badge = PanelContainer.new()
		free_badge.offset_left = 2
		free_badge.offset_top = 2
		free_badge.custom_minimum_size = Vector2(44, 16)
		var fb_s = StyleBoxFlat.new()
		fb_s.bg_color = Color(0.85, 0.65, 0.12, 0.95)
		fb_s.corner_radius_top_left = 3
		fb_s.corner_radius_top_right = 3
		fb_s.corner_radius_bottom_right = 3
		fb_s.corner_radius_bottom_left = 3
		free_badge.add_theme_stylebox_override("panel", fb_s)
		av_container.add_child(free_badge)

		var fb_lbl = Label.new()
		fb_lbl.text = "FREE"
		fb_lbl.add_theme_font_size_override("font_size", 9)
		fb_lbl.add_theme_color_override("font_color", Color(0.1, 0.05, 0.0, 1.0))
		fb_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		free_badge.add_child(fb_lbl)

	# 3. Bottom Bar: Thế Lực + Kỹ Năng trên thanh riêng
	var fac_lbl = Label.new()
	var fac_code = hero.get("faction", "")
	fac_lbl.text = "🏛️ %s" % fac_code
	fac_lbl.add_theme_font_size_override("font_size", 10)
	if HeroDatabase:
		fac_lbl.add_theme_color_override("font_color", HeroDatabase.get_faction_color(fac_code))
	else:
		fac_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
	vbox.add_child(fac_lbl)

	var skill_bar = PanelContainer.new()
	skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb_s = StyleBoxFlat.new()
	sb_s.bg_color = Color(0.08, 0.14, 0.24, 0.95)
	sb_s.corner_radius_top_left = 3
	sb_s.corner_radius_top_right = 3
	sb_s.corner_radius_bottom_right = 3
	sb_s.corner_radius_bottom_left = 3
	skill_bar.add_theme_stylebox_override("panel", sb_s)
	vbox.add_child(skill_bar)

	var skill_lbl = Label.new()
	skill_lbl.text = "⚡ %s" % HeroDatabase.get_skill_summary(int(hero.get("id", 0)))
	skill_lbl.add_theme_font_size_override("font_size", 10)
	skill_lbl.add_theme_color_override("font_color", Color(0.4, 0.92, 1.0, 1.0))
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_bar.add_child(skill_lbl)

	# Sự kiện bấm chọn soi tướng
	card_btn.pressed.connect(func():
		AudioManager.play_card_select()
		var tween = card_btn.create_tween()
		tween.tween_property(card_btn, "scale", Vector2(1.04, 1.04), 0.08)
		tween.tween_property(card_btn, "scale", Vector2.ONE, 0.12)
		_inspect_hero(hero)
	)
	card_btn.mouse_entered.connect(func():
		card_btn.create_tween().tween_property(card_btn, "scale", Vector2(1.025, 1.025), 0.12)
	)
	card_btn.mouse_exited.connect(func():
		card_btn.create_tween().tween_property(card_btn, "scale", Vector2.ONE, 0.12)
	)

	return card_btn

func _build_right_inspect_column() -> Control:
	var panel = PanelContainer.new()
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = COLOR_PANEL_BG
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 2
	p_style.border_color = COLOR_GOLD_PRIMARY
	p_style.corner_radius_top_left = 8
	p_style.corner_radius_top_right = 8
	p_style.corner_radius_bottom_right = 8
	p_style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", p_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# 1. Tên tướng lớn
	inspect_title_lbl = Label.new()
	inspect_title_lbl.text = "LÝ THƯỜNG KIỆT"
	inspect_title_lbl.add_theme_font_size_override("font_size", 18)
	inspect_title_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	inspect_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(inspect_title_lbl)

	# 2. Phụ đề thế lực & tag
	inspect_sub_lbl = Label.new()
	inspect_sub_lbl.text = "Thế Lực: Thời Lý • Máu: 4 đóa sen [ĐÃ SỞ HỮU]"
	inspect_sub_lbl.add_theme_font_size_override("font_size", 12)
	inspect_sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	inspect_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(inspect_sub_lbl)

	# 3. Avatar lớn
	var av_center = CenterContainer.new()
	vbox.add_child(av_center)

	var av_frame = PanelContainer.new()
	av_frame.custom_minimum_size = Vector2(130, 165)
	var af_s = StyleBoxFlat.new()
	af_s.bg_color = Color(0.02, 0.04, 0.08, 0.9)
	af_s.border_width_left = 2
	af_s.border_width_top = 2
	af_s.border_width_right = 2
	af_s.border_width_bottom = 2
	af_s.border_color = COLOR_GOLD_PRIMARY
	af_s.corner_radius_top_left = 6
	af_s.corner_radius_top_right = 6
	af_s.corner_radius_bottom_right = 6
	af_s.corner_radius_bottom_left = 6
	av_frame.add_theme_stylebox_override("panel", af_s)
	av_center.add_child(av_frame)

	inspect_avatar_rect = TextureRect.new()
	inspect_avatar_rect.set_anchors_preset(PRESET_FULL_RECT)
	inspect_avatar_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inspect_avatar_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_frame.add_child(inspect_avatar_rect)

	# 4. Hàng Sen Máu Lớn
	inspect_lotus_container = HBoxContainer.new()
	inspect_lotus_container.alignment = BoxContainer.ALIGNMENT_CENTER
	inspect_lotus_container.add_theme_constant_override("separation", 4)
	vbox.add_child(inspect_lotus_container)

	# 5. Khung Tuyệt Kỹ
	var skill_panel = PanelContainer.new()
	skill_panel.size_flags_vertical = SIZE_EXPAND_FILL
	var sp_s = StyleBoxFlat.new()
	sp_s.bg_color = Color(0.03, 0.06, 0.12, 0.95)
	sp_s.border_width_left = 1
	sp_s.border_width_top = 1
	sp_s.border_width_right = 1
	sp_s.border_width_bottom = 1
	sp_s.border_color = Color(0.2, 0.35, 0.55, 0.8)
	sp_s.corner_radius_top_left = 6
	sp_s.corner_radius_top_right = 6
	sp_s.corner_radius_bottom_right = 6
	sp_s.corner_radius_bottom_left = 6
	skill_panel.add_theme_stylebox_override("panel", sp_s)
	vbox.add_child(skill_panel)

	var sp_margin = MarginContainer.new()
	sp_margin.add_theme_constant_override("margin_left", 10)
	sp_margin.add_theme_constant_override("margin_right", 10)
	sp_margin.add_theme_constant_override("margin_top", 8)
	sp_margin.add_theme_constant_override("margin_bottom", 8)
	skill_panel.add_child(sp_margin)

	var sp_vbox = VBoxContainer.new()
	sp_vbox.add_theme_constant_override("separation", 6)
	sp_margin.add_child(sp_vbox)

	inspect_skill_title_lbl = Label.new()
	inspect_skill_title_lbl.text = "⚡ TUYỆT KỸ: [TIẾN THOÁI]"
	inspect_skill_title_lbl.add_theme_font_size_override("font_size", 13)
	inspect_skill_title_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	sp_vbox.add_child(inspect_skill_title_lbl)

	inspect_skill_desc_lbl = Label.new()
	inspect_skill_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_skill_desc_lbl.add_theme_font_size_override("font_size", 12)
	inspect_skill_desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.9))
	inspect_skill_desc_lbl.size_flags_vertical = SIZE_EXPAND_FILL
	sp_vbox.add_child(inspect_skill_desc_lbl)

	# 6. Nút Khóa Tướng Lớn
	lock_in_btn = Button.new()
	lock_in_btn.custom_minimum_size = Vector2(0, 48)
	lock_in_btn.focus_mode = Control.FOCUS_NONE
	lock_in_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_in_btn.text = "👑 XÁC NHẬN CHỌN TƯỚNG"
	lock_in_btn.add_theme_font_size_override("font_size", 14)
	lock_in_btn.add_theme_color_override("font_color", Color.WHITE)
	lock_in_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.9, 1.0))
	lock_in_btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.7, 1.0))
	lock_in_btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.65, 0.7, 0.8))
	_style_gold_confirm_btn(lock_in_btn)
	vbox.add_child(lock_in_btn)

	lock_in_btn.pressed.connect(_on_confirm_pick_pressed)

	return panel

func _set_lock_in_text(txt: String) -> void:
	if lock_in_btn and is_instance_valid(lock_in_btn):
		lock_in_btn.text = txt

func _inspect_hero(hero: Dictionary) -> void:
	if not (hero is Dictionary) or hero.is_empty():
		return
	inspecting_hero = hero

	var hid = int(hero.get("id", 1))
	var hname = hero.get("name", "")
	var is_free = bool(hero.get("is_weekly_free", false))
	var tag = "[🌟 FREE TUẦN]" if is_free else "[ĐÃ SỞ HỮU]"

	var fac = hero.get("faction", "")
	inspect_title_lbl.text = hname.to_upper()
	inspect_sub_lbl.text = "Thế Lực: %s • Máu: %d đóa sen %s" % [fac, hero.get("maxHp", 4), tag]

	var tex = HeroDatabase.get_avatar_texture(hero.get("avatarPath", "")) if HeroDatabase else null
	if tex: inspect_avatar_rect.texture = tex

	# Cập nhật sen máu inspect
	for child in inspect_lotus_container.get_children():
		child.queue_free()

	var hp_count = int(hero.get("maxHp", 4))
	var lotus_tex = load("res://assets/ui/lotus_full.png") if ResourceLoader.exists("res://assets/ui/lotus_full.png") else null
	for i in range(hp_count):
		var l_rect = TextureRect.new()
		l_rect.custom_minimum_size = Vector2(18, 18)
		l_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		l_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if lotus_tex: l_rect.texture = lotus_tex
		inspect_lotus_container.add_child(l_rect)

	inspect_skill_title_lbl.text = "⚡ TUYỆT KỸ: [%s]" % HeroDatabase.get_skill_summary(int(hero.get("id", 0))).to_upper()
	inspect_skill_desc_lbl.text = HeroDatabase.get_skill_details(int(hero.get("id", 0)))

	_update_lock_in_button_state()

func _is_my_turn() -> bool:
	if current_picker_index >= 0 and current_picker_index < draft_slots.size():
		return draft_slots[current_picker_index].get("isPlayer", false)
	return false

func _update_lock_in_button_state() -> void:
	if not is_draft_active:
		lock_in_btn.disabled = true
		_set_lock_in_text("⚔️ TRẬN ĐẤU SẴN SÀNG")
		return
	if _pending_pick_hero_id > 0:
		lock_in_btn.disabled = true
		_set_lock_in_text("⏳ ĐANG CHỜ MÁY CHỦ XÁC NHẬN...")
		return

	if _is_my_turn():
		if is_player_locked:
			lock_in_btn.disabled = true
			_set_lock_in_text("✅ BẠN ĐÃ KHÓA TƯỚNG")
		else:
			var hid = int(inspecting_hero.get("id", 0))
			if hid in selected_hero_ids:
				lock_in_btn.disabled = true
				_set_lock_in_text("⚠️ TƯỚNG NÀY ĐÃ ĐƯỢC CHỌN")
			else:
				lock_in_btn.disabled = false
				_set_lock_in_text("👑 XÁC NHẬN CHỌN TƯỚNG")
	else:
		lock_in_btn.disabled = true
		if is_player_locked:
			_set_lock_in_text("⏳ ĐANG CHỜ CÁC TƯỚNG KHÁC...")
		else:
			_set_lock_in_text("⏳ ĐANG CHỜ GHẾ #%d CHỌN..." % (current_picker_index + 1))

# --- Luồng Chọn Tướng Theo Lượt (Turn-based Draft Sequence chuẩn Unity) ---
func _show_no_server_modal(message: String = "") -> void:
	is_draft_active = false
	var dim = ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 240)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.35, 0.35, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚠️ KHÔNG TÌM THẤY MÁY CHỦ TRẬN ĐẤU"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = message if message != "" else "Không thể kết nối đến Máy Chủ Deno (Cloud hoặc Local 8080).\nTrận đấu không thể tiếp tục khi không có máy chủ."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(desc_lbl)

	var btn = Button.new()
	btn.text = "↩️ QUAY VỀ SẢNH CHÍNH"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.25, 0.35, 1.0)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/home.tscn")
	)
	vbox.add_child(btn)

var _server_state_received: bool = false

# --- Luồng Chọn Tướng Theo Lượt (chỉ qua Deno Cloud) ---
func _start_draft_sequence() -> void:
	current_picker_index = 0
	if not is_network_mode:
		_show_no_server_modal("Chưa kết nối được Deno Cloud. Không thể bắt đầu chọn tướng khi thiếu máy chủ online.")
		return
	draft_status_lbl.text = "⚡ Đang đồng bộ tiến trình chọn tướng từ Deno Cloud..."
	draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	_start_network_draft_watchdog()

func _start_network_draft_watchdog() -> void:
	_server_state_received = false
	for retry in range(3):
		await get_tree().create_timer(3.0).timeout
		if _server_state_received or not is_draft_active or not is_network_mode:
			return
		if NetworkClient and NetworkClient.is_connected_to_server and not _draft_joined:
			print("[HeroSelect] 🔁 Gửi lại JOIN_DRAFT lần %d." % (retry + 1))
			_on_network_connected_for_draft()

	if not _server_state_received and is_draft_active and is_network_mode:
		print("[HeroSelect] ⚠️ Máy chủ không phản hồi lượt chọn tướng.")
		_show_no_server_modal("Deno Cloud chưa gửi trạng thái chọn tướng. Vui lòng kết nối lại để mọi người dùng cùng một phòng online.")

func _run_local_draft_loop() -> void:
	print("[HeroSelect] ⚙️ Đang chạy chọn tướng chế độ Cục Bộ (Local Draft)...")
	draft_status_lbl.text = "🎮 Chọn Tướng Cục Bộ (Local vs AI)..."
	draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)

	var locked_hero_ids = [0, 0, 0, 0]

	for slot_idx in range(draft_slots.size()):
		if not is_draft_active:
			return

		current_picker_index = slot_idx
		var slot = draft_slots[slot_idx]
		turn_timer = 40.0
		_highlight_active_picker(slot_idx)
		_update_lock_in_button_state()

		var is_bot = bool(slot.get("isAI", false))
		var is_player = bool(slot.get("isPlayer", false))

		if is_player:
			draft_status_lbl.text = "👑 ĐẾN LƯỢT BẠN CHỌN TƯỚNG! (Bạn có 40 giây)"
			draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		else:
			draft_status_lbl.text = "⏳ %s đang suy nghĩ..." % _get_anonymous_slot_name(slot_idx)
			draft_status_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if slot["isDragon"] else COLOR_PHOENIX_RED)

		while locked_hero_ids[slot_idx] == 0 and turn_timer > 0.0 and is_draft_active:
			turn_timer = maxf(0.0, turn_timer - 0.5)
			turn_timer_lbl.text = "⏳ %ds" % maxi(0, int(ceilf(turn_timer)))

			if is_player:
				if slot.get("isLocked", false) and slot.has("chosenHero") and (slot["chosenHero"] is Dictionary):
					locked_hero_ids[slot_idx] = int(slot["chosenHero"].get("id", 0))
					break
			else:
				# Bot suy nghĩ 1.5 giây rồi tự chọn tướng
				if turn_timer <= 38.5:
					var bot_pick = _choose_bot_hero()
					locked_hero_ids[slot_idx] = int(bot_pick.get("id", 1))
					_lock_hero_for_slot(slot, bot_pick)
					break

			await get_tree().create_timer(0.5).timeout

		# Hết thời gian mà chưa khóa thì tự lấy tướng đầu tiên hợp lệ
		if locked_hero_ids[slot_idx] == 0 and is_draft_active:
			var fallback_pick = _get_first_available_candidate()
			locked_hero_ids[slot_idx] = int(fallback_pick.get("id", 1))
			_lock_hero_for_slot(slot, fallback_pick)

		await get_tree().create_timer(0.5).timeout

	# Đếm ngược 3 giây vào trận
	AudioManager.play_victory()
	for c in range(3, 0, -1):
		if not is_draft_active:
			break
		draft_status_lbl.text = "⚔️ CẢ 4 CHIẾN TƯỚNG ĐÃ SẴN SÀNG! VÀO TRẬN SAU %ds..." % c
		draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		turn_timer_lbl.text = "⚔️ %ds" % c
		await get_tree().create_timer(1.0).timeout

	_on_draft_completed()

func _highlight_active_picker(idx: int) -> void:
	for i in range(left_slot_nodes.size()):
		var node = left_slot_nodes[i]
		var is_current = (i == idx)
		var sp_style: StyleBoxFlat = node["style"]
		var status_l: Label = node["status"]
		var slot_data = node["data"]

		if is_current:
			sp_style.border_color = Color(1.0, 0.95, 0.4, 1.0)
			sp_style.bg_color = Color(0.12, 0.18, 0.32, 0.98)
			status_l.text = "⏳ Đang chọn..."
			status_l.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		elif slot_data["isLocked"]:
			sp_style.border_color = COLOR_DRAGON_CYAN if slot_data["isDragon"] else COLOR_PHOENIX_RED
			sp_style.bg_color = Color(0.06, 0.10, 0.16, 0.95)
			status_l.text = "✅ ĐÃ KHÓA"
			status_l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
		else:
			sp_style.border_color = Color(0.2, 0.28, 0.4, 0.6)
			sp_style.bg_color = Color(0.04, 0.06, 0.10, 0.9)
			status_l.text = "Chờ lượt..."
			status_l.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _lock_hero_for_slot(slot: Dictionary, hero: Dictionary) -> void:
	var hid = int(hero.get("id", 1))
	if not hid in selected_hero_ids:
		selected_hero_ids.append(hid)
	slot["chosenHero"] = hero
	slot["isLocked"] = true

	if slot["isPlayer"]:
		is_player_locked = true

	AudioManager.play_card_select()

	# Cập nhật slot visual bên trái
	for node in left_slot_nodes:
		if node["data"]["seatNumber"] == slot["seatNumber"]:
			var av: TextureRect = node["avatar"]
			var hname_l: Label = node["hero_name"]
			var status_l: Label = node["status"]

			var tex = HeroDatabase.get_avatar_texture(hero.get("avatarPath", "")) if HeroDatabase else null
			if tex: av.texture = tex
			av.modulate = Color.WHITE

			hname_l.text = hero.get("name", "")
			hname_l.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)

			status_l.text = "✅ ĐÃ KHÓA"
			status_l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))

	# Làm mờ thẻ tướng đã chọn trong grid
	if hero_card_nodes.has(hid):
		var card = hero_card_nodes[hid]
		card.modulate = Color(0.4, 0.4, 0.4, 0.8)

	_update_lock_in_button_state()

func _choose_bot_hero() -> Dictionary:
	var pool = available_heroes.duplicate()
	pool.shuffle()
	for h in pool:
		var hid = int(h.get("id", 0))
		if not hid in selected_hero_ids:
			return h
	return _get_first_available_candidate()

func _get_first_available_candidate() -> Dictionary:
	for h in available_heroes:
		var hid = int(h.get("id", 0))
		if not hid in selected_hero_ids:
			return h
	if HeroDatabase:
		for h in HeroDatabase.all_heroes:
			var hid = int(h.get("id", 0))
			if not hid in selected_hero_ids:
				return h
	return HeroDatabase.get_hero(47) if HeroDatabase else {}

func _get_locked_hero_id(idx: int) -> int:
	if idx >= 0 and idx < draft_slots.size():
		var h = draft_slots[idx].get("chosenHero", null)
		if h is Dictionary and not h.is_empty():
			return int(h.get("id", 0))
	return 0

func _find_draft_slot_index(seat_number: int) -> int:
	if seat_number <= 0:
		return -1
	for i in range(draft_slots.size()):
		if int(draft_slots[i].get("seatNumber", i + 1)) == seat_number:
			return i
	return -1

func _on_confirm_pick_pressed() -> void:
	if _is_my_turn() and not is_player_locked:
		if not (inspecting_hero is Dictionary) or inspecting_hero.is_empty():
			return
		if current_picker_index < 0 or current_picker_index >= draft_slots.size():
			return
		var slot = draft_slots[current_picker_index]
		var hid = int(inspecting_hero.get("id", 0))
		var hname = inspecting_hero.get("name", "")

		if NetworkClient and NetworkClient.is_connected_to_server:
			# Network draft is authoritative. Keep the pick pending until the next
			# server snapshot, so an older broadcast cannot show a false lock.
			_pending_pick_hero_id = hid
			_pending_pick_seat = int(slot.get("seatNumber", current_picker_index + 1))
			lock_in_btn.disabled = true
			_set_lock_in_text("⏳ ĐANG GỬI LỰA CHỌN...")
			NetworkClient.send_pick_hero(hid, hname)
		else:
			is_player_locked = true
			_lock_hero_for_slot(slot, inspecting_hero)
			lock_in_btn.disabled = true
			_set_lock_in_text("✅ BẠN ĐÃ KHÓA TƯỚNG")

func _rollback_pending_pick() -> void:
	if _pending_pick_hero_id <= 0:
		return
	for slot in draft_slots:
		if int(slot.get("seatNumber", 0)) == _pending_pick_seat:
			var hero = slot.get("chosenHero", {})
			if hero is Dictionary and int(hero.get("id", 0)) == _pending_pick_hero_id:
				slot["chosenHero"] = null
				slot["isLocked"] = false
				break
	selected_hero_ids.erase(_pending_pick_hero_id)
	_pending_pick_hero_id = 0
	_pending_pick_seat = 0
	is_player_locked = false
	_highlight_active_picker(current_picker_index)
	_update_lock_in_button_state()

# --- Kết Nối Đồng Bộ Deno Server (Authoritative Draft Phase) ---
func _connect_network_draft() -> void:
	if not NetworkClient:
		return
	if not NetworkClient.draft_state_updated.is_connected(_on_server_draft_state_updated):
		NetworkClient.draft_state_updated.connect(_on_server_draft_state_updated)
	if not NetworkClient.draft_completed.is_connected(_on_server_draft_completed):
		NetworkClient.draft_completed.connect(_on_server_draft_completed)
	if not NetworkClient.draft_joined.is_connected(_on_network_draft_joined):
		NetworkClient.draft_joined.connect(_on_network_draft_joined)
	if not NetworkClient.connection_closed.is_connected(_on_network_draft_closed):
		NetworkClient.connection_closed.connect(_on_network_draft_closed)
	if not NetworkClient.connection_established.is_connected(_on_network_connected_for_draft):
		NetworkClient.connection_established.connect(_on_network_connected_for_draft)
	if not NetworkClient.error_received.is_connected(_on_network_draft_error):
		NetworkClient.error_received.connect(_on_network_draft_error)

	if NetworkClient.is_connected_to_server:
		is_network_mode = true
		_on_network_connected_for_draft()

func _on_network_connected_for_draft() -> void:
	if _draft_joined or not NetworkClient:
		return
	is_network_mode = true
	# A reconnect must accept the server's current revision as the new baseline.
	_last_draft_revision = 0
	var my_seat_num = NetworkClient.my_seat if NetworkClient and NetworkClient.my_seat in [1, 2, 3, 4] else 1
	var my_uid = AuthManager.current_user_id if AuthManager else ""
	var my_name = AuthManager.current_user_name if AuthManager else "Đại Tướng Quân"
	if AppwriteMatchmaking and not AppwriteMatchmaking.my_session_user_id.is_empty():
		my_uid = AppwriteMatchmaking.my_session_user_id
		my_name = AppwriteMatchmaking.my_session_user_name

	var slots_data: Array = []
	for s in draft_slots:
			slots_data.append({
				"seatNumber": int(s.get("seatNumber", 1)),
				"userId": str(s.get("userId", "")),
				"userName": str(s.get("userName", "")),
				"isAI": bool(s.get("isAI", false)),
				"isDragon": bool(s.get("isDragon", false))
			})

	print("[HeroSelect] Gửi JOIN_DRAFT: room=%s, seat=%d, user=%s" % [current_room_id, my_seat_num, my_name])
	NetworkClient.send_join_draft(current_room_id, my_seat_num, my_uid, my_name, slots_data)

func _on_network_draft_joined(assigned_seat: int) -> void:
	_draft_joined = true
	if assigned_seat >= 1 and assigned_seat <= 4 and NetworkClient:
		NetworkClient.my_seat = assigned_seat
		for slot in draft_slots:
			slot["isPlayer"] = int(slot.get("seatNumber", 0)) == assigned_seat
		_update_lock_in_button_state()

func _on_network_draft_error(message: String) -> void:
	if not is_draft_active or _pending_pick_hero_id <= 0:
		return
	print("[HeroSelect] Server từ chối chọn tướng: %s" % message)
	_rollback_pending_pick()
	if NetworkClient and NetworkClient.is_connected_to_server:
		_draft_joined = false
		_on_network_connected_for_draft()

func _on_network_draft_closed() -> void:
	if not is_draft_active:
		return
	_draft_joined = false
	_server_state_received = false
	draft_status_lbl.text = "⚠️ Mất kết nối máy chủ chọn tướng, đang kết nối lại..."

func _apply_authoritative_draft_slots(server_slots: Array) -> void:
	if server_slots.is_empty():
		return
	for s_info in server_slots:
		if not (s_info is Dictionary):
			continue
		var s_num = int(s_info.get("seatNumber", s_info.get("seat", 0)))
		for local_s in draft_slots:
			if int(local_s.get("seatNumber", local_s.get("seat", 0))) != s_num:
				continue
			var was_locked = bool(local_s.get("isLocked", false))
			var old_hero = local_s.get("chosenHero", {})
			var old_hid = int(old_hero.get("id", 0)) if old_hero is Dictionary else 0
			local_s["userId"] = s_info.get("userId", local_s.get("userId", ""))
			local_s["userName"] = s_info.get("userName", local_s.get("userName", ""))
			local_s["isDragon"] = bool(s_info.get("isDragon", local_s.get("isDragon", false)))
			local_s["roleTag"] = "[RỒNG]" if local_s["isDragon"] else "[PHƯỢNG]"
			local_s["isAI"] = bool(s_info.get("isAI", local_s.get("isAI", false)))
			var hid = int(s_info.get("heroId", 0))
			var is_locked = bool(s_info.get("isLocked", false)) and hid > 0
			if is_locked:
				var hero = HeroDatabase.get_hero(hid) if HeroDatabase else {}
				if not (hero is Dictionary) or hero.is_empty():
					hero = {"id": hid, "name": s_info.get("heroName", "Tướng %d" % hid), "maxHp": int(s_info.get("maxHp", 4))}
				local_s["chosenHero"] = hero
				if not was_locked or old_hid != hid:
					local_s["isLocked"] = false
					_lock_hero_for_slot(local_s, hero)
				else:
					local_s["isLocked"] = true
			else:
				local_s["chosenHero"] = null
				local_s["isLocked"] = false
				if local_s.get("isPlayer", false) and _pending_pick_hero_id <= 0:
					is_player_locked = false
			for node in left_slot_nodes:
				if node.get("data") != local_s:
					continue
				var team_lbl = node.get("team")
				if team_lbl and is_instance_valid(team_lbl):
					team_lbl.text = "[RỒNG]" if local_s.get("isDragon", true) else "[PHƯỢNG]"
					team_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if local_s["isDragon"] else COLOR_PHOENIX_RED)
				var av_bg = node.get("bg")
				if av_bg and is_instance_valid(av_bg):
					av_bg.texture = preload("res://assets/ui/hero_backgrounds/bg_hero_green.png") if local_s.get("isDragon", true) else preload("res://assets/ui/hero_backgrounds/bg_hero_red.png")
				var seat_lbl = node.get("player")
				if seat_lbl and is_instance_valid(seat_lbl):
					seat_lbl.text = _get_anonymous_slot_name(draft_slots.find(local_s))
				break
			break
	selected_hero_ids.clear()
	for local_s in draft_slots:
		if local_s.get("isLocked", false):
			selected_hero_ids.append(int(local_s.get("chosenHero", {}).get("id", 0)))
	if _pending_pick_hero_id > 0:
		var pending_confirmed := false
		for local_s in draft_slots:
			if int(local_s.get("seatNumber", 0)) == _pending_pick_seat:
				var pending_hero = local_s.get("chosenHero", {})
				pending_confirmed = bool(local_s.get("isLocked", false)) and pending_hero is Dictionary and int(pending_hero.get("id", 0)) == _pending_pick_hero_id
				break
		if pending_confirmed:
			_pending_pick_hero_id = 0
			_pending_pick_seat = 0
			is_player_locked = true

func _on_server_draft_state_updated(data: Dictionary) -> void:
	if not is_draft_active:
		return
	_server_state_received = true
	var revision := int(data.get("revision", 0))
	if revision > 0 and revision <= _last_draft_revision:
		return
	if revision > 0:
		_last_draft_revision = revision

	var phase = data.get("phase", "PICKING")
	var t = int(data.get("timer", 0))
	turn_timer = float(t)

	if phase == "COUNTDOWN":
		draft_status_lbl.text = "⚔️ ĐÃ KHÓA ĐỦ 4 CHIẾN TƯỚNG! TẤT CẢ VÀO 2v2 TRONG %d..." % t
		draft_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
		turn_timer_lbl.text = "⚔️ %ds" % t
		return

	# The server publishes a seat and a canonical index. Resolve by seat locally
	# because matchmaking snapshots can arrive with slots in a different order.
	var server_current_seat := int(data.get("currentSeat", 0))
	var local_picker_index := _find_draft_slot_index(server_current_seat)
	if local_picker_index >= 0:
		current_picker_index = local_picker_index
	else:
		current_picker_index = int(data.get("currentPickerIndex", 0))
	turn_timer_lbl.text = "⏳ %ds" % t
	var server_seat = NetworkClient.my_seat if NetworkClient and NetworkClient.my_seat in [1, 2, 3, 4] else 1
	for local_s in draft_slots:
		local_s["isPlayer"] = int(local_s.get("seatNumber", local_s.get("seat", 0))) == server_seat

	# Đồng bộ trạng thái khóa và phe từ Server.
	var server_slots = data.get("slots", [])
	if server_slots is Array:
		_apply_authoritative_draft_slots(server_slots)

	_highlight_active_picker(current_picker_index)
	_update_lock_in_button_state()

	# Cập nhật nhãn trạng thái theo lượt
	var active_slot = draft_slots[current_picker_index] if current_picker_index < draft_slots.size() else {}
	if _is_my_turn():
		draft_status_lbl.text = "👑 ĐẾN LƯỢT BẠN CHỌN TƯỚNG! (Còn %d giây)" % t
		draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	else:
		var anon_n = _get_anonymous_slot_name(current_picker_index)
		draft_status_lbl.text = "⏳ %s đang chọn (%ds)..." % [anon_n, t]
		draft_status_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if active_slot.get("isDragon", true) else COLOR_PHOENIX_RED)

func _on_server_draft_completed(data: Dictionary) -> void:
	if is_draft_active:
		var server_slots = data.get("slots", [])
		if server_slots is Array:
			_apply_authoritative_draft_slots(server_slots)
		current_picker_index = draft_slots.size()
		_on_draft_completed()

func _on_draft_completed() -> void:
	if not is_draft_active:
		return
	is_draft_active = false
	turn_timer_lbl.text = "⚔️ SẴN SÀNG!"
	draft_status_lbl.text = "⚔️ TẤT CẢ XUẤT TRẬN 2v2!"
	draft_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
	AudioManager.play_victory()

	# Đảm bảo tất cả các ghế đều đã có tướng hợp lệ
	for slot in draft_slots:
		if not slot.get("isLocked", false) or not slot.has("chosenHero"):
			var cand = _get_first_available_candidate()
			_lock_hero_for_slot(slot, cand)

	# Lưu danh sách 4 tướng đã chọn vào AppwriteMatchmaking để battle_2v2.tscn sử dụng
	if AppwriteMatchmaking:
		if AppwriteMatchmaking.current_room is Dictionary:
			AppwriteMatchmaking.current_room["draft_slots"] = draft_slots
		AppwriteMatchmaking.draft_slots = draft_slots

	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file("res://scenes/battle_2v2.tscn")

func _show_battle_launch_dialog() -> void:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.04, 0.08, 0.85)
	add_child(overlay)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 360)
	panel.set_anchors_preset(PRESET_CENTER)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.12, 0.22, 0.98)
	p_style.border_width_left = 2
	p_style.border_width_top = 2
	p_style.border_width_right = 2
	p_style.border_width_bottom = 2
	p_style.border_color = COLOR_GOLD_PRIMARY
	p_style.corner_radius_top_left = 10
	p_style.corner_radius_top_right = 10
	p_style.corner_radius_bottom_right = 10
	p_style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", p_style)
	overlay.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "👑 ĐỘI HÌNH XUẤT QUÂN 2v2 ĐÃ SẴN SÀNG"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var teams_vbox = VBoxContainer.new()
	teams_vbox.add_theme_constant_override("separation", 8)
	vbox.add_child(teams_vbox)

	for i in range(draft_slots.size()):
		var s = draft_slots[i]
		if not (s is Dictionary):
			continue
		var hero = s.get("chosenHero", {})
		if not (hero is Dictionary):
			hero = {}
		var hname = hero.get("name", "Vô Danh Tướng")
		var is_drag = bool(s.get("isDragon", true))

		var row = HBoxContainer.new()
		var team_tag = Label.new()
		team_tag.text = "[RỒNG]" if is_drag else "[PHƯỢNG]"
		team_tag.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if is_drag else COLOR_PHOENIX_RED)
		team_tag.add_theme_font_size_override("font_size", 13)
		row.add_child(team_tag)

		var p_lbl = Label.new()
		p_lbl.text = "%s ➜ Tướng: %s" % [_get_anonymous_slot_name(i), hname]
		p_lbl.add_theme_font_size_override("font_size", 13)
		p_lbl.add_theme_color_override("font_color", Color.WHITE)
		row.add_child(p_lbl)

		teams_vbox.add_child(row)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_hbox)

	var home_btn = Button.new()
	home_btn.custom_minimum_size = Vector2(200, 44)
	home_btn.text = "🏠 VỀ ĐẠI SẢNH"
	_style_cancel_small_btn(home_btn)
	home_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/home.tscn")
	)
	btn_hbox.add_child(home_btn)

func _on_exit_pressed() -> void:
	AudioManager.play_card_select()
	is_draft_active = false
	get_tree().change_scene_to_file("res://scenes/home.tscn")

# --- Button Styling Helpers ---
func _style_gold_confirm_btn(btn: Button) -> void:
	var norm = StyleBoxFlat.new()
	norm.bg_color = Color(0.85, 0.65, 0.15, 1.0)
	norm.border_width_left = 1
	norm.border_width_top = 1
	norm.border_width_right = 1
	norm.border_width_bottom = 2
	norm.border_color = Color(1.0, 0.9, 0.45, 1.0)
	norm.corner_radius_top_left = 6
	norm.corner_radius_top_right = 6
	norm.corner_radius_bottom_right = 6
	norm.corner_radius_bottom_left = 6

	var hov = norm.duplicate()
	hov.bg_color = Color(0.95, 0.75, 0.22, 1.0)

	var press = norm.duplicate()
	press.bg_color = Color(0.70, 0.52, 0.10, 1.0)

	var dis = norm.duplicate()
	dis.bg_color = Color(0.2, 0.25, 0.35, 0.8)
	dis.border_color = Color(0.3, 0.35, 0.45, 0.6)

	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_stylebox_override("disabled", dis)

func _style_cancel_small_btn(btn: Button) -> void:
	var norm = StyleBoxFlat.new()
	norm.bg_color = Color(0.35, 0.10, 0.14, 0.9)
	norm.border_width_left = 1
	norm.border_width_top = 1
	norm.border_width_right = 1
	norm.border_width_bottom = 1
	norm.border_color = Color(0.8, 0.25, 0.3, 0.8)
	norm.corner_radius_top_left = 6
	norm.corner_radius_top_right = 6
	norm.corner_radius_bottom_right = 6
	norm.corner_radius_bottom_left = 6

	var hov = norm.duplicate()
	hov.bg_color = Color(0.50, 0.15, 0.20, 1.0)

	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", norm)
	btn.add_theme_color_override("font_color", Color.WHITE)

# --- Automated Verification Helper ---
func _run_automated_screenshot() -> void:
	print("[HeroSelect] Chờ dựng hình giao diện Chọn Tướng...")
	await get_tree().create_timer(0.6).timeout
	var tex = get_viewport().get_texture()
	if tex:
		var img = tex.get_image()
		if img:
			var path = "res://hero_select_screenshot.png"
			var err = img.save_png(path)
			if err == OK:
				print("[HeroSelect] Đã lưu ảnh chụp Chọn Tướng tại: ", path)
			else:
				print("[HeroSelect] Lỗi lưu ảnh chụp: ", err)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
