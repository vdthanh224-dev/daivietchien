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
	var my_uid = AuthManager.current_user_id if AuthManager else ""
	var my_name = AuthManager.current_user_name if AuthManager else ""
	if AppwriteMatchmaking:
		is_host = AppwriteMatchmaking.is_same_user(current_room.get("hostUserId", ""), "", my_uid, my_name)
	else:
		is_host = (current_room.get("hostUserId", "") == my_uid)

	# Khởi tạo dữ liệu tướng khả dụng từ HeroDatabase
	if HeroDatabase:
		available_heroes = HeroDatabase.get_available_pick_heroes()
	else:
		available_heroes = []

	_setup_draft_slots()
	_build_ui()

	if not available_heroes.is_empty():
		_inspect_hero(available_heroes[0])

	_start_draft_sequence()

	# Kiểm thử tự động nếu có cờ dòng lệnh
	var args = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if "--screenshot-hero-select" in args:
		_run_automated_screenshot()

func _setup_draft_slots() -> void:
	draft_slots.clear()
	var current_room = AppwriteMatchmaking.current_room if AppwriteMatchmaking else {}
	var slots = current_room.get("slots", [])

	var my_name = AuthManager.current_user_name if AuthManager and AuthManager.current_user_name != "" else "Đại Tướng Quân"
	var my_uid = AuthManager.current_user_id if AuthManager and AuthManager.current_user_id != "" else ""

	# Xác định chính xác vị trí ghế thực tế của người chơi
	var my_seat_idx = -1
	if slots.size() == 4:
		# 1. So khớp người chơi qua is_same_user (khớp userId nguyên bản/24 ký tự hoặc userName)
		for i in range(4):
			var s = slots[i]
			if not bool(s.get("isEmpty", false)):
				if AppwriteMatchmaking and AppwriteMatchmaking.is_same_user(s.get("userId", ""), s.get("userName", ""), my_uid, my_name):
					my_seat_idx = i
					break
				elif s.get("userId", "") == my_uid or (my_name != "" and s.get("userName", "").to_lower() == my_name.to_lower()):
					my_seat_idx = i
					break
		# 2. Nếu vẫn không thấy slot nào khớp, tìm ghế đầu tiên không phải AI
		if my_seat_idx == -1:
			for i in range(4):
				var s = slots[i]
				if not bool(s.get("isAI", false)) and not bool(s.get("isEmpty", false)):
					my_seat_idx = i
					break
		# 3. Fallback mặc định là ghế 0 (ghế 1)
		if my_seat_idx == -1:
			my_seat_idx = 0

	var my_seat_num = my_seat_idx + 1
	var my_is_dragon = (my_seat_num == 1 or my_seat_num == 3)

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

			var is_drag = (s_num == 1 or s_num == 3)
			var is_ally = (is_drag == my_is_dragon)
			var role_tag = "(BẠN)" if is_me else ("(ĐỒNG MINH)" if is_ally else "(ĐỐI THỦ)")
			var is_ai = false if is_me else bool(s.get("isAI", true))

			draft_slots.append({
				"seatNumber": s_num,
				"userName": uname,
				"roleTag": role_tag,
				"isPlayer": is_me,
				"isDragon": is_drag,
				"isAI": is_ai,
				"chosenHero": null,
				"isLocked": false
			})
	else:
		# Mặc định 4 ghế chuẩn 2v2 với 3 tên AI ngẫu nhiên không trùng lặp
		used_names.append(my_name)
		var b1 = AppwriteMatchmaking.get_realistic_gamer_name(101, used_names) if AppwriteMatchmaking else "Chiến Tướng 2"
		used_names.append(b1)
		var b2 = AppwriteMatchmaking.get_realistic_gamer_name(202, used_names) if AppwriteMatchmaking else "Chiến Tướng 3"
		used_names.append(b2)
		var b3 = AppwriteMatchmaking.get_realistic_gamer_name(303, used_names) if AppwriteMatchmaking else "Chiến Tướng 4"

		draft_slots = [
			{"seatNumber": 1, "userName": my_name, "roleTag": "(BẠN)", "isPlayer": true, "isDragon": true, "isAI": false, "chosenHero": null, "isLocked": false},
			{"seatNumber": 2, "userName": b1, "roleTag": "(ĐỐI THỦ)", "isPlayer": false, "isDragon": false, "isAI": true, "chosenHero": null, "isLocked": false},
			{"seatNumber": 3, "userName": b2, "roleTag": "(ĐỒNG MINH)", "isPlayer": false, "isDragon": true, "isAI": true, "chosenHero": null, "isLocked": false},
			{"seatNumber": 4, "userName": b3, "roleTag": "(ĐỐI THỦ)", "isPlayer": false, "isDragon": false, "isAI": true, "chosenHero": null, "isLocked": false}
		]

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
	title.text = "👑 ĐẠI VIỆT CHIẾN • CHỌN TƯỚNG 2v2"
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
		team_lbl.text = "[RỒNG]" if slot_data["isDragon"] else "[PHƯỢNG]"
		team_lbl.add_theme_font_size_override("font_size", 12)
		team_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if slot_data["isDragon"] else COLOR_PHOENIX_RED)
		r1_hbox.add_child(team_lbl)

		var seat_lbl = Label.new()
		seat_lbl.text = "#%d %s %s" % [slot_data["seatNumber"], slot_data["userName"], slot_data["roleTag"]]
		seat_lbl.add_theme_font_size_override("font_size", 11)
		seat_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0) if slot_data["isPlayer"] else Color.WHITE)
		seat_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		r1_hbox.add_child(seat_lbl)

		# Row 2: Avatar + Hero Name + Status
		var r2_hbox = HBoxContainer.new()
		r2_hbox.add_theme_constant_override("separation", 8)
		s_vbox.add_child(r2_hbox)

		var av_rect = TextureRect.new()
		av_rect.custom_minimum_size = Vector2(56, 72)
		av_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var def_tex = HeroDatabase.get_avatar_texture("") if HeroDatabase else null
		if def_tex: av_rect.texture = def_tex
		av_rect.modulate = Color(1.0, 1.0, 1.0, 0.4)
		r2_hbox.add_child(av_rect)

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
			"avatar": av_rect,
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
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
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
	card_btn.custom_minimum_size = Vector2(152, 206)
	card_btn.focus_mode = Control.FOCUS_NONE

	# Base Panel Style
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.06, 0.09, 0.16, 0.98)
	base_style.border_width_left = 2
	base_style.border_width_top = 2
	base_style.border_width_right = 2
	base_style.border_width_bottom = 2
	base_style.border_color = COLOR_GOLD_PRIMARY if is_free else Color(0.30, 0.65, 0.90, 0.85)
	base_style.corner_radius_top_left = 6
	base_style.corner_radius_top_right = 6
	base_style.corner_radius_bottom_right = 6
	base_style.corner_radius_bottom_left = 6
	card_btn.add_theme_stylebox_override("normal", base_style)
	card_btn.add_theme_stylebox_override("hover", base_style)
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
	fac_lbl.text = hero.get("faction", "")
	fac_lbl.add_theme_font_size_override("font_size", 10)
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
	skill_lbl.text = "⚡ %s" % hero.get("skillName", "")
	skill_lbl.add_theme_font_size_override("font_size", 10)
	skill_lbl.add_theme_color_override("font_color", Color(0.4, 0.92, 1.0, 1.0))
	skill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_bar.add_child(skill_lbl)

	# Sự kiện bấm chọn soi tướng
	card_btn.pressed.connect(func():
		AudioManager.play_card_select()
		_inspect_hero(hero)
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
	_style_gold_confirm_btn(lock_in_btn)
	vbox.add_child(lock_in_btn)

	lock_in_btn_lbl = Label.new()
	lock_in_btn_lbl.set_anchors_preset(PRESET_FULL_RECT)
	lock_in_btn_lbl.text = "👑 XÁC NHẬN CHỌN TƯỚNG"
	lock_in_btn_lbl.add_theme_font_size_override("font_size", 14)
	lock_in_btn_lbl.add_theme_color_override("font_color", Color.WHITE)
	lock_in_btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_in_btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lock_in_btn.add_child(lock_in_btn_lbl)

	lock_in_btn.pressed.connect(_on_confirm_pick_pressed)

	return panel

func _inspect_hero(hero: Dictionary) -> void:
	if hero.is_empty():
		return
	inspecting_hero = hero

	var hid = int(hero.get("id", 1))
	var hname = hero.get("name", "")
	var is_free = bool(hero.get("is_weekly_free", false))
	var tag = "[🌟 FREE TUẦN]" if is_free else "[ĐÃ SỞ HỮU]"

	inspect_title_lbl.text = hname.to_upper()
	inspect_sub_lbl.text = "Thế Lực: %s • Máu: %d đóa sen %s" % [hero.get("faction", ""), hero.get("maxHp", 4), tag]

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

	inspect_skill_title_lbl.text = "⚡ TUYỆT KỸ: [%s]" % hero.get("skillName", "").to_upper()
	inspect_skill_desc_lbl.text = hero.get("skillDesc", "")

	_update_lock_in_button_state()

func _is_my_turn() -> bool:
	if current_picker_index >= 0 and current_picker_index < draft_slots.size():
		return draft_slots[current_picker_index].get("isPlayer", false)
	return false

func _update_lock_in_button_state() -> void:
	if not is_draft_active:
		lock_in_btn.disabled = true
		lock_in_btn_lbl.text = "⚔️ TRẬN ĐẤU SẴN SÀNG"
		return

	if _is_my_turn():
		if is_player_locked:
			lock_in_btn.disabled = true
			lock_in_btn_lbl.text = "✅ BẠN ĐÃ KHÓA TƯỚNG"
		else:
			var hid = int(inspecting_hero.get("id", 0))
			if hid in selected_hero_ids:
				lock_in_btn.disabled = true
				lock_in_btn_lbl.text = "⚠️ TƯỚNG NÀY ĐÃ ĐƯỢC CHỌN"
			else:
				lock_in_btn.disabled = false
				lock_in_btn_lbl.text = "👑 XÁC NHẬN CHỌN TƯỚNG"
	else:
		lock_in_btn.disabled = true
		if is_player_locked:
			lock_in_btn_lbl.text = "⏳ ĐANG CHỜ CÁC TƯỚNG KHÁC..."
		else:
			lock_in_btn_lbl.text = "⏳ ĐANG CHỜ GHẾ #%d CHỌN..." % (current_picker_index + 1)

# --- Luồng Chọn Tướng Theo Lượt (Turn-based Draft Sequence) ---
func _start_draft_sequence() -> void:
	current_picker_index = 0
	_run_draft_loop()

func _run_draft_loop() -> void:
	for slot_idx in range(draft_slots.size()):
		if not is_draft_active:
			return

		current_picker_index = slot_idx
		var slot = draft_slots[slot_idx]
		_highlight_active_picker(slot_idx)
		_update_lock_in_button_state()

		var is_bot = bool(slot.get("isAI", false))
		var is_player = bool(slot.get("isPlayer", false))

		if is_player:
			# ══════════════════════════════════════════════════════════════
			# 1. LƯỢT CỦA BẠN (NGƯỜI THẬT TRÊN MÁY NÀY): ĐỂ ĐỦ 40 GIÂY!
			# Tuyệt đối không tự chọn thay bạn khi đồng hồ còn đang chạy!
			# ══════════════════════════════════════════════════════════════
			turn_timer = 40.0
			turn_timer_lbl.text = "⏳ 40s"
			draft_status_lbl.text = "👑 ĐẾN LƯỢT BẠN CHỌN TƯỚNG (#%d)! (Bạn có 40 giây)" % slot["seatNumber"]
			draft_status_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)

			if is_host and not current_room_id.is_empty() and AppwriteMatchmaking:
				AppwriteMatchmaking.send_draft_host_state({
					"roomId": current_room_id,
					"phase": "PICKING",
					"currentPickerIndex": slot_idx,
					"currentSeatNumber": slot["seatNumber"],
					"timerLeft": turn_timer,
					"heroId1": _get_locked_hero_id(0),
					"heroId2": _get_locked_hero_id(1),
					"heroId3": _get_locked_hero_id(2),
					"heroId4": _get_locked_hero_id(3)
				})

			var host_sync_timer = 0.0
			while turn_timer > 0.0 and not slot["isLocked"] and is_draft_active:
				turn_timer -= 0.5
				host_sync_timer += 0.5
				turn_timer_lbl.text = "⏳ %ds" % maxi(0, int(ceilf(turn_timer)))

				# Host đồng bộ thời gian còn lại sang máy khách mỗi 1 giây
				if is_host and host_sync_timer >= 1.0 and not current_room_id.is_empty() and AppwriteMatchmaking:
					host_sync_timer = 0.0
					AppwriteMatchmaking.send_draft_host_state({
						"roomId": current_room_id,
						"phase": "PICKING",
						"currentPickerIndex": slot_idx,
						"currentSeatNumber": slot["seatNumber"],
						"timerLeft": turn_timer,
						"heroId1": _get_locked_hero_id(0),
						"heroId2": _get_locked_hero_id(1),
						"heroId3": _get_locked_hero_id(2),
						"heroId4": _get_locked_hero_id(3)
					})

				await get_tree().create_timer(0.5).timeout

			# CHỈ KHI HẾT SẠCH 40s mà người chơi vẫn chưa bấm "XÁC NHẬN CHỌN TƯỚNG",
			# mới tự động khóa tướng đang soi (hoặc tướng đầu tiên khả dụng) làm dự phòng timeout
			if not slot["isLocked"] and is_draft_active:
				var candidate = inspecting_hero
				var cid = int(candidate.get("id", 0))
				if cid == 0 or cid in selected_hero_ids:
					candidate = _get_first_available_candidate()
				_lock_hero_for_slot(slot, candidate)
				_send_pick_action_if_needed(slot["seatNumber"], int(candidate.get("id", 0)))

		elif not is_bot:
			# ══════════════════════════════════════════════════════════════
			# 2. LƯỢT CỦA NGƯỜI THẬT KHÁC (ĐỒNG ĐỘI / ĐỐI THỦ LÀ NGƯỜI CHƠI KHÁCH):
			# Để đủ 40 giây cho người thật đó tự suy nghĩ và chọn tướng!
			# Tuyệt đối KHÔNG tự chọn cho họ sau 1-2s!
			# ══════════════════════════════════════════════════════════════
			turn_timer = 40.0
			turn_timer_lbl.text = "⏳ 40s"
			var seat_num = slot["seatNumber"]
			var role_name = slot.get("roleTag", "")
			draft_status_lbl.text = "⏳ Ghế #%d %s: %s (Người thật) đang suy nghĩ và chọn tướng (40s)..." % [seat_num, role_name, slot["userName"]]
			draft_status_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if slot["isDragon"] else COLOR_PHOENIX_RED)

			var poll_timer = 0.0
			while turn_timer > 0.0 and not slot["isLocked"] and is_draft_active:
				turn_timer -= 0.5
				poll_timer += 0.5
				turn_timer_lbl.text = "⏳ %ds" % maxi(0, int(ceilf(turn_timer)))

				# Lắng nghe xem người thật đó đã chọn tướng qua mạng chưa
				if poll_timer >= 0.8 and not current_room_id.is_empty() and AppwriteMatchmaking:
					poll_timer = 0.0
					if is_host:
						# Host kiểm tra xem Guest có gửi DACT chọn tướng lên không
						var act = await AppwriteMatchmaking.poll_draft_player_action_for_seat(current_room_id, seat_num)
						var req_id = int(act.get("requestedHeroId", 0))
						if req_id > 0 and not req_id in selected_hero_ids:
							var h = HeroDatabase.get_hero(req_id) if HeroDatabase else {}
							if not h.is_empty():
								_lock_hero_for_slot(slot, h)
								break
					else:
						# Guest kiểm tra xem Host đã đồng bộ heroId cho slot này chưa
						var h_state = await AppwriteMatchmaking.poll_draft_host_state(current_room_id)
						var h_ids = h_state.get("heroIds", [0, 0, 0, 0])
						if slot_idx < h_ids.size() and h_ids[slot_idx] > 0 and not h_ids[slot_idx] in selected_hero_ids:
							var h = HeroDatabase.get_hero(h_ids[slot_idx]) if HeroDatabase else {}
							if not h.is_empty():
								_lock_hero_for_slot(slot, h)
								break

				await get_tree().create_timer(0.5).timeout

			# Nếu hết sạch 40s mà người thật kia vẫn chưa khóa (hoặc rớt mạng), tự động chọn tướng dự phòng
			if not slot["isLocked"] and is_draft_active:
				var candidate = _get_first_available_candidate()
				_lock_hero_for_slot(slot, candidate)

		else:
			# ══════════════════════════════════════════════════════════════
			# 3. LƯỢT CỦA AI BOT: Suy nghĩ 2.0 - 3.5s rồi tự động chọn
			# ══════════════════════════════════════════════════════════════
			turn_timer = 15.0
			var seat_num = slot["seatNumber"]
			var role_name = slot.get("roleTag", "")
			draft_status_lbl.text = "⏳ Ghế #%d (AI: %s) đang suy nghĩ..." % [seat_num, slot["userName"]]
			draft_status_lbl.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if slot["isDragon"] else COLOR_PHOENIX_RED)

			var think_time = randf_range(2.0, 3.5)
			while think_time > 0.0 and is_draft_active:
				think_time -= 0.5
				turn_timer -= 0.5
				turn_timer_lbl.text = "⏳ %ds" % maxi(0, int(ceilf(turn_timer)))
				await get_tree().create_timer(0.5).timeout

			if is_draft_active and not slot["isLocked"]:
				var bot_pick = _choose_bot_hero()
				_lock_hero_for_slot(slot, bot_pick)

		# Cập nhật phát sóng trạng thái sau mỗi lượt
		if is_host and not current_room_id.is_empty() and AppwriteMatchmaking:
			AppwriteMatchmaking.send_draft_host_state({
				"roomId": current_room_id,
				"phase": "PICKING",
				"currentPickerIndex": slot_idx,
				"currentSeatNumber": slot["seatNumber"],
				"timerLeft": 0.0,
				"heroId1": _get_locked_hero_id(0),
				"heroId2": _get_locked_hero_id(1),
				"heroId3": _get_locked_hero_id(2),
				"heroId4": _get_locked_hero_id(3)
			})

		await get_tree().create_timer(0.4).timeout

	# Hoàn tất chọn tướng cho cả 4 ghế
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

func _send_pick_action_if_needed(seat_num: int, hero_id: int) -> void:
	if not current_room_id.is_empty() and AppwriteMatchmaking:
		if not is_host:
			AppwriteMatchmaking.send_draft_player_action({
				"roomId": current_room_id,
				"seatNumber": seat_num,
				"senderUserId": AuthManager.current_user_id if AuthManager else "",
				"requestedHeroId": hero_id,
				"seq": 1
			})
		else:
			AppwriteMatchmaking.send_draft_host_state({
				"roomId": current_room_id,
				"phase": "PICKING",
				"currentPickerIndex": current_picker_index,
				"currentSeatNumber": seat_num,
				"timerLeft": turn_timer,
				"heroId1": _get_locked_hero_id(0),
				"heroId2": _get_locked_hero_id(1),
				"heroId3": _get_locked_hero_id(2),
				"heroId4": _get_locked_hero_id(3)
			})

func _on_confirm_pick_pressed() -> void:
	if _is_my_turn() and not is_player_locked:
		var slot = draft_slots[current_picker_index]
		_lock_hero_for_slot(slot, inspecting_hero)
		_send_pick_action_if_needed(slot["seatNumber"], int(inspecting_hero.get("id", 0)))

func _on_draft_completed() -> void:
	is_draft_active = false
	turn_timer_lbl.text = "⚔️ SẴN SÀNG!"
	AudioManager.play_victory()

	if is_host and not current_room_id.is_empty() and AppwriteMatchmaking:
		AppwriteMatchmaking.send_draft_host_state({
			"roomId": current_room_id,
			"phase": "COUNTDOWN",
			"currentPickerIndex": 3,
			"currentSeatNumber": 4,
			"timerLeft": 0.0,
			"countdownSec": 3,
			"heroId1": _get_locked_hero_id(0),
			"heroId2": _get_locked_hero_id(1),
			"heroId3": _get_locked_hero_id(2),
			"heroId4": _get_locked_hero_id(3)
		})

	# Đếm ngược 3 giây vào trận
	for count in [3, 2, 1]:
		draft_status_lbl.text = "⚔️ ĐÃ KHÓA ĐỦ 4 CHIẾN TƯỚNG! VÀO TRẬN TRONG %d..." % count
		draft_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
		await get_tree().create_timer(1.0).timeout

	draft_status_lbl.text = "⚔️ XUẤT TRẬN ĐẠI VIỆT!"
	_show_battle_launch_dialog()

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

	for s in draft_slots:
		var hero = s.get("chosenHero", {})
		var hname = hero.get("name", "Vô Danh Tướng")
		var is_drag = s["isDragon"]

		var row = HBoxContainer.new()
		var team_tag = Label.new()
		team_tag.text = "[RỒNG]" if is_drag else "[PHƯỢNG]"
		team_tag.add_theme_color_override("font_color", COLOR_DRAGON_CYAN if is_drag else COLOR_PHOENIX_RED)
		team_tag.add_theme_font_size_override("font_size", 13)
		row.add_child(team_tag)

		var p_lbl = Label.new()
		p_lbl.text = "Ghế #%d: %s %s ➜ Tướng: %s" % [s["seatNumber"], s["userName"], s["roleTag"], hname]
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
	var img = get_viewport().get_texture().get_image()
	var path = "res://hero_select_screenshot.png"
	var err = img.save_png(path)
	if err == OK:
		print("[HeroSelect] Đã lưu ảnh chụp Chọn Tướng tại: ", path)
	else:
		print("[HeroSelect] Lỗi lưu ảnh chụp: ", err)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
