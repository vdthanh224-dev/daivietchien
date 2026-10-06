extends Control

# Theme Palette: Imperial Dark Lacquer & Royal Gold
const COLOR_WHITE_BASE = Color(0.11, 0.08, 0.14, 0.90) # Regal Dark Lacquer base
const COLOR_WHITE_HOVER = Color(0.18, 0.13, 0.22, 0.95)
const COLOR_WHITE_PRESSED = Color(0.07, 0.05, 0.09, 0.98)

const COLOR_GOLD_PRIMARY = Color(0.92, 0.75, 0.26, 1.0)
const COLOR_GOLD_ACCENT = Color(1.0, 0.88, 0.38, 1.0)
const COLOR_GOLD_BORDER = Color(0.85, 0.68, 0.22, 0.85)
const COLOR_GOLD_DARK = Color(0.60, 0.44, 0.10, 1.0)

const COLOR_TEXT_DARK = Color(0.98, 0.95, 0.88, 1.0) # Crisp golden-white text
const COLOR_TEXT_MUTED = Color(0.78, 0.74, 0.66, 1.0)
const COLOR_TEXT_GOLD = Color(0.96, 0.82, 0.32, 1.0)

const COLOR_SHADOW = Color(0.0, 0.0, 0.0, 0.45)
const COLOR_SHADOW_DEEP = Color(0.0, 0.0, 0.0, 0.65)

var bg_rect: TextureRect
var dark_overlay: ColorRect
var embers_layer: Control

# Header Controls
var player_name_label: Label
var level_badge_label: Label
var rank_label: Label
var exp_bar: ProgressBar
var exp_text_label: Label
var silver_label: Label
var gold_label: Label

# Modal Controls
var modal_overlay: ColorRect
var modal_panel: PanelContainer
var modal_title_label: Label
var modal_scroll: ScrollContainer
var modal_content_container: VBoxContainer

# Player State
var current_silver: int = 5000
var current_gold: int = 0
var current_hero_tickets: int = 0
var current_rp: int = 1200
var current_military_points: int = 350
var ticket_label: Label = null
var _fullscreen_than_dien_panel: Control = null
var _gacha_reveal_layer: Control = null
var _than_dien_selected_hero_id: int = 3
var _leaderboard_current_tab: int = 0
var _leaderboard_cached_players: Array = []
var _leaderboard_is_loading: bool = false

# Matchmaking 2v2 State
var is_matchmaking_active: bool = false
var mm_is_cancelled: bool = false
var mm_active_room_id: String = ""
var mm_is_host: bool = false
var mm_current_room: Dictionary = {}
var mm_session_user_id: String = ""
var mm_search_started_at_ms: int = 0

# Embers particle pool
var ember_particles: Array = []
var levelup_overlay: Control = null
var _fullscreen_heroes_panel: Control = null
var _heroes_gallery_scroll: ScrollContainer = null
var _heroes_swipe_active: bool = false
var _heroes_swipe_last_y: float = 0.0

# Hero Stage & Tactical Command Controls
var hero_stage_container: Control = null
var hero_sprite: TextureRect = null
var hero_dialogue_bubble: PanelContainer = null
var hero_dialogue_label: Label = null
var current_selected_mode: String = "2v2" # "2v2", "dynasty_5", "dynasty_8"
var mode_selector_btn: Button = null
var mode_drawer_panel: PanelContainer = null
var mode_title_lbl: Label = null
var battle_cta_btn: Button = null
var quest_nav_btn: Button = null

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_ui()
	_load_user_data()
	if AuthManager:
		AuthManager.profile_updated.connect(_load_user_data)
	if DailyQuestSystem:
		if DailyQuestSystem.has_signal("quests_updated") and not DailyQuestSystem.quests_updated.is_connected(_update_quest_nav_indicator):
			DailyQuestSystem.quests_updated.connect(_update_quest_nav_indicator)
		if DailyQuestSystem.has_method("ensure_today_quests"):
			DailyQuestSystem.ensure_today_quests()
	_update_quest_nav_indicator()
	_start_ambient_effects()

	# Check for automated screenshot argument
	var args = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	if "--screenshot" in args:
		_run_automated_screenshot(false)
	elif "--screenshot-modal" in args:
		_run_automated_screenshot(true)
	elif "--screenshot-levelup" in args:
		_run_automated_screenshot_levelup()
	elif "--screenshot-exp" in args:
		_run_automated_screenshot_exp()
	elif "--screenshot-matchmaking" in args:
		_run_automated_screenshot_matchmaking()
	elif "--screenshot-matchmaking-filled" in args:
		_run_automated_screenshot_matchmaking_filled()
	elif "--screenshot-profile" in args:
		_run_automated_screenshot_profile()
	elif "--screenshot-quests" in args:
		_run_automated_screenshot_quests()
	elif "--screenshot-inventory" in args:
		_run_automated_screenshot_inventory()
	else:
		_check_pending_exp_gain()

func _build_ui() -> void:
	# 1. Background
	bg_rect = TextureRect.new()
	bg_rect.name = "Background"
	bg_rect.set_anchors_preset(PRESET_FULL_RECT)
	bg_rect.size = Vector2(1280, 720)
	bg_rect.custom_minimum_size = Vector2(1280, 720)
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var bg_tex = load("res://assets/ui/home_background.png")
	if bg_tex == null:
		bg_tex = load("res://assets/ui/login_background.png")
	bg_rect.texture = bg_tex
	bg_rect.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg_rect)

	# 2. Dark Overlay for high contrast & atmosphere
	dark_overlay = ColorRect.new()
	dark_overlay.name = "DarkOverlay"
	dark_overlay.set_anchors_preset(PRESET_FULL_RECT)
	dark_overlay.size = Vector2(1280, 720)
	dark_overlay.color = Color(0.02, 0.03, 0.05, 0.22)
	dark_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(dark_overlay)

	# 3. Embers layer
	embers_layer = Control.new()
	embers_layer.anchors_preset = PRESET_FULL_RECT
	embers_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(embers_layer)

	# 4. Top Header Bar (0 to 66px)
	_build_top_header()

	# 5. Center: 4 Major Game Mode Cards (Y: 76px to 644px)
	_build_four_game_modes()

	# 6. Bottom Navigation Dock (Y: 656px to 720px)
	_build_bottom_nav_dock()

	# 7. Modal Overlay Layer
	_build_modal_layer()

func _build_top_header() -> void:
	var header_panel = Panel.new()
	header_panel.custom_minimum_size = Vector2(1280, 66)
	header_panel.set_anchors_preset(PRESET_TOP_WIDE)
	header_panel.offset_bottom = 66

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.06, 0.04, 0.08, 0.92) # Regal Dark Lacquer
	header_style.border_width_bottom = 2
	header_style.border_color = COLOR_GOLD_PRIMARY
	header_style.shadow_color = COLOR_SHADOW_DEEP
	header_style.shadow_size = 8
	header_style.shadow_offset = Vector2(0, 3)
	header_panel.add_theme_stylebox_override("panel", header_style)
	add_child(header_panel)

	# Sub-HBox spanning full width
	var header_hbox = HBoxContainer.new()
	header_hbox.set_anchors_preset(PRESET_FULL_RECT)
	header_hbox.offset_left = 20
	header_hbox.offset_right = -20
	header_hbox.offset_top = 8
	header_hbox.offset_bottom = -8
	header_hbox.add_theme_constant_override("separation", 16)
	header_panel.add_child(header_hbox)

	# --- Left: Profile Section ---
	var profile_btn = Button.new()
	profile_btn.custom_minimum_size = Vector2(280, 50)
	_style_white_gold_button(profile_btn, 8, 4, Vector2(0, 2))
	profile_btn.pressed.connect(_on_profile_clicked)

	var p_hbox = HBoxContainer.new()
	p_hbox.set_anchors_preset(PRESET_FULL_RECT)
	p_hbox.offset_left = 8
	p_hbox.offset_right = -8
	p_hbox.offset_top = 4
	p_hbox.offset_bottom = -4
	p_hbox.add_theme_constant_override("separation", 10)
	profile_btn.add_child(p_hbox)

	# Avatar frame
	var avatar_frame = PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(42, 42)
	var af_style = StyleBoxFlat.new()
	af_style.bg_color = Color(0.12, 0.16, 0.24, 1.0)
	af_style.border_width_left = 2
	af_style.border_width_top = 2
	af_style.border_width_right = 2
	af_style.border_width_bottom = 2
	af_style.border_color = COLOR_GOLD_PRIMARY
	af_style.corner_radius_top_left = 21
	af_style.corner_radius_top_right = 21
	af_style.corner_radius_bottom_right = 21
	af_style.corner_radius_bottom_left = 21
	avatar_frame.add_theme_stylebox_override("panel", af_style)

	var av_img = TextureRect.new()
	av_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var av_tex = load("res://assets/ui/ly_thuong_kiet.png")
	if av_tex != null:
		av_img.texture = av_tex
	avatar_frame.add_child(av_img)
	p_hbox.add_child(avatar_frame)

	# Name + Rank VBox
	var p_vbox = VBoxContainer.new()
	p_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	p_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_vbox.add_theme_constant_override("separation", 2)

	var name_hbox = HBoxContainer.new()
	name_hbox.add_theme_constant_override("separation", 6)

	player_name_label = Label.new()
	player_name_label.text = "LÝ THƯỜNG KIỆT"
	player_name_label.add_theme_font_size_override("font_size", 13)
	player_name_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	name_hbox.add_child(player_name_label)

	var level_badge = PanelContainer.new()
	var lb_style = StyleBoxFlat.new()
	lb_style.bg_color = Color(0.68, 0.12, 0.08, 0.95)
	lb_style.border_width_left = 1
	lb_style.border_width_top = 1
	lb_style.border_width_right = 1
	lb_style.border_width_bottom = 1
	lb_style.border_color = COLOR_GOLD_PRIMARY
	lb_style.corner_radius_top_left = 4
	lb_style.corner_radius_top_right = 4
	lb_style.corner_radius_bottom_right = 4
	lb_style.corner_radius_bottom_left = 4
	level_badge.add_theme_stylebox_override("panel", lb_style)

	level_badge_label = Label.new()
	level_badge_label.text = " CẤP 1 "
	level_badge_label.add_theme_font_size_override("font_size", 10)
	level_badge_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	level_badge.add_child(level_badge_label)
	name_hbox.add_child(level_badge)
	p_vbox.add_child(name_hbox)

	var rank_hbox = HBoxContainer.new()
	rank_hbox.add_theme_constant_override("separation", 6)

	rank_label = Label.new()
	rank_label.text = "🔰 Tân Binh (50/100đ)"
	rank_label.add_theme_font_size_override("font_size", 11)
	rank_label.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	rank_hbox.add_child(rank_label)

	exp_bar = ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(65, 8)
	exp_bar.size_flags_vertical = SIZE_SHRINK_CENTER
	exp_bar.value = 0
	exp_bar.show_percentage = false
	var exp_bg = StyleBoxFlat.new()
	exp_bg.bg_color = Color(0.20, 0.15, 0.22, 1.0)
	exp_bg.corner_radius_top_left = 4
	exp_bg.corner_radius_top_right = 4
	exp_bg.corner_radius_bottom_right = 4
	exp_bg.corner_radius_bottom_left = 4
	var exp_fill = StyleBoxFlat.new()
	exp_fill.bg_color = COLOR_GOLD_PRIMARY
	exp_fill.corner_radius_top_left = 4
	exp_fill.corner_radius_top_right = 4
	exp_fill.corner_radius_bottom_right = 4
	exp_fill.corner_radius_bottom_left = 4
	exp_bar.add_theme_stylebox_override("background", exp_bg)
	exp_bar.add_theme_stylebox_override("fill", exp_fill)
	rank_hbox.add_child(exp_bar)

	exp_text_label = Label.new()
	exp_text_label.text = "0/20 EXP"
	exp_text_label.add_theme_font_size_override("font_size", 10)
	exp_text_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	rank_hbox.add_child(exp_text_label)

	p_vbox.add_child(rank_hbox)
	p_hbox.add_child(p_vbox)
	header_hbox.add_child(profile_btn)

	# --- Center: Game Title Plaque ---
	var center_spacer1 = Control.new()
	center_spacer1.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hbox.add_child(center_spacer1)

	var title_panel = PanelContainer.new()
	title_panel.custom_minimum_size = Vector2(280, 48)
	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color(0.08, 0.06, 0.11, 0.85)
	tp_style.border_width_left = 2
	tp_style.border_width_top = 2
	tp_style.border_width_right = 2
	tp_style.border_width_bottom = 2
	tp_style.border_color = COLOR_GOLD_PRIMARY
	tp_style.corner_radius_top_left = 8
	tp_style.corner_radius_top_right = 8
	tp_style.corner_radius_bottom_right = 8
	tp_style.corner_radius_bottom_left = 8
	tp_style.shadow_color = COLOR_SHADOW_DEEP
	tp_style.shadow_size = 8
	tp_style.shadow_offset = Vector2(0, 3)
	title_panel.add_theme_stylebox_override("panel", tp_style)

	var title_lbl = Label.new()
	title_lbl.text = "👑 ĐẠI VIỆT CHIẾN"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 21)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 1)
	title_panel.add_child(title_lbl)
	header_hbox.add_child(title_panel)

	var center_spacer2 = Control.new()
	center_spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hbox.add_child(center_spacer2)

	# --- Right: Currencies & Quick Icons ---
	# Silver Capsule
	var silver_btn = Button.new()
	silver_btn.custom_minimum_size = Vector2(130, 44)
	_style_white_gold_button(silver_btn, 8, 4, Vector2(0, 2))
	silver_btn.pressed.connect(func(): _show_modal("TRÂN BẢO CÁC", _build_shop_content()))

	var s_hbox = HBoxContainer.new()
	s_hbox.set_anchors_preset(PRESET_FULL_RECT)
	s_hbox.offset_left = 8
	s_hbox.offset_right = -8
	s_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	s_hbox.add_theme_constant_override("separation", 6)

	var s_icon = TextureRect.new()
	s_icon.custom_minimum_size = Vector2(22, 22)
	s_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var s_tex = load("res://assets/ui/icon_silver.png")
	if s_tex: s_icon.texture = s_tex
	s_hbox.add_child(s_icon)

	silver_label = Label.new()
	silver_label.text = _format_number(current_silver)
	silver_label.add_theme_font_size_override("font_size", 14)
	silver_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	s_hbox.add_child(silver_label)

	var s_plus = Label.new()
	s_plus.text = "+"
	s_plus.add_theme_font_size_override("font_size", 15)
	s_plus.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	s_hbox.add_child(s_plus)

	silver_btn.add_child(s_hbox)
	header_hbox.add_child(silver_btn)

	# Gold Capsule
	var gold_btn = Button.new()
	gold_btn.custom_minimum_size = Vector2(120, 44)
	_style_white_gold_button(gold_btn, 8, 4, Vector2(0, 2))
	gold_btn.pressed.connect(func(): _show_modal("TRÂN BẢO CÁC", _build_shop_content()))

	var g_hbox = HBoxContainer.new()
	g_hbox.set_anchors_preset(PRESET_FULL_RECT)
	g_hbox.offset_left = 8
	g_hbox.offset_right = -8
	g_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	g_hbox.add_theme_constant_override("separation", 6)

	var g_icon = TextureRect.new()
	g_icon.custom_minimum_size = Vector2(22, 22)
	g_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var g_tex = load("res://assets/ui/icon_gold.png")
	if g_tex: g_icon.texture = g_tex
	g_hbox.add_child(g_icon)

	gold_label = Label.new()
	gold_label.text = _format_number(current_gold)
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", Color(0.70, 0.48, 0.05, 1.0))
	g_hbox.add_child(gold_label)

	var g_plus = Label.new()
	g_plus.text = "+"
	g_plus.add_theme_font_size_override("font_size", 15)
	g_plus.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	g_hbox.add_child(g_plus)

	gold_btn.add_child(g_hbox)
	header_hbox.add_child(gold_btn)

	# Mail Button (✉️)
	var mail_btn = Button.new()
	mail_btn.custom_minimum_size = Vector2(44, 44)
	mail_btn.text = "✉️"
	mail_btn.add_theme_font_size_override("font_size", 18)
	_style_white_gold_button(mail_btn, 8, 4, Vector2(0, 2))
	mail_btn.pressed.connect(func(): _show_modal("HÒM THƯ TRIỀU ĐÌNH", _build_mail_content()))
	header_hbox.add_child(mail_btn)

	# Settings Button (⚙️)
	var settings_btn = Button.new()
	settings_btn.custom_minimum_size = Vector2(44, 44)
	settings_btn.text = "⚙️"
	settings_btn.add_theme_font_size_override("font_size", 18)
	_style_white_gold_button(settings_btn, 8, 4, Vector2(0, 2))
	settings_btn.pressed.connect(func(): _show_modal("THIẾT LẬP CHIẾN TRƯỜNG", _build_settings_content()))
	header_hbox.add_child(settings_btn)

func _build_four_game_modes() -> void:
	# Sảnh Chính: Chiến Lệnh Đài và Thông Báo
	_build_tactical_command_dock()
	_build_event_notice_banner()

func _build_hero_stage() -> void:
	pass

func _build_tactical_command_dock() -> void:
	var cmd_container = Control.new()
	cmd_container.anchors_preset = PRESET_FULL_RECT
	cmd_container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(cmd_container)

	# 1. Thẻ chọn Chế độ chơi (Mode Selector Pill)
	mode_selector_btn = Button.new()
	mode_selector_btn.custom_minimum_size = Vector2(310, 54)
	mode_selector_btn.position = Vector2(930, 455)
	_style_white_gold_button(mode_selector_btn, 12, 6, Vector2(0, 3))
	mode_selector_btn.pressed.connect(_toggle_mode_drawer)

	var p_hbox = HBoxContainer.new()
	p_hbox.set_anchors_preset(PRESET_FULL_RECT)
	p_hbox.offset_left = 12
	p_hbox.offset_right = -12
	p_hbox.offset_top = 4
	p_hbox.offset_bottom = -4
	p_hbox.add_theme_constant_override("separation", 10)
	p_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var m_icon = Label.new()
	m_icon.name = "ModeIcon"
	m_icon.text = "⚔️"
	m_icon.add_theme_font_size_override("font_size", 22)
	p_hbox.add_child(m_icon)

	var m_vbox = VBoxContainer.new()
	m_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	m_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	m_vbox.add_theme_constant_override("separation", 1)

	var mode_subtitle = Label.new()
	mode_subtitle.text = "CHIẾN TRƯỜNG ĐANG CHỌN"
	mode_subtitle.add_theme_font_size_override("font_size", 9)
	mode_subtitle.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	m_vbox.add_child(mode_subtitle)

	mode_title_lbl = Label.new()
	mode_title_lbl.name = "ModeTitle"
	mode_title_lbl.text = "ĐẤU TRƯỜNG 2v2 (XẾP HẠNG)"
	mode_title_lbl.add_theme_font_size_override("font_size", 13)
	mode_title_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	m_vbox.add_child(mode_title_lbl)
	p_hbox.add_child(m_vbox)

	var arrow_lbl = Label.new()
	arrow_lbl.text = "▾"
	arrow_lbl.add_theme_font_size_override("font_size", 16)
	arrow_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	p_hbox.add_child(arrow_lbl)

	mode_selector_btn.add_child(p_hbox)
	cmd_container.add_child(mode_selector_btn)

	# 2. Nút "XUẤT TRẬN" Trống Đồng 3D cực đại (Thumb Zone góc ngón cái phải)
	battle_cta_btn = Button.new()
	battle_cta_btn.custom_minimum_size = Vector2(310, 84)
	battle_cta_btn.position = Vector2(930, 524)
	_style_bronze_drum_cta(battle_cta_btn)
	battle_cta_btn.pressed.connect(_on_battle_cta_pressed)

	var b_hbox = HBoxContainer.new()
	b_hbox.set_anchors_preset(PRESET_FULL_RECT)
	b_hbox.offset_left = 18
	b_hbox.offset_right = -18
	b_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	b_hbox.add_theme_constant_override("separation", 14)

	var drum_icon = Label.new()
	drum_icon.text = "🥁"
	drum_icon.add_theme_font_size_override("font_size", 34)
	b_hbox.add_child(drum_icon)

	var b_vbox = VBoxContainer.new()
	b_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	b_vbox.add_theme_constant_override("separation", 2)

	var sub_cta = Label.new()
	sub_cta.text = "ĐẠI VIỆT XUẤT QUÂN"
	sub_cta.add_theme_font_size_override("font_size", 11)
	sub_cta.add_theme_color_override("font_color", Color(1.0, 0.88, 0.40, 1.0))
	b_vbox.add_child(sub_cta)

	var main_cta = Label.new()
	main_cta.text = "XUẤT TRẬN"
	main_cta.add_theme_font_size_override("font_size", 24)
	main_cta.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
	main_cta.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	main_cta.add_theme_constant_override("shadow_offset_y", 2)
	b_vbox.add_child(main_cta)

	b_hbox.add_child(b_vbox)
	battle_cta_btn.add_child(b_hbox)
	cmd_container.add_child(battle_cta_btn)

	# 3. Khay chọn chế độ cuộn lụa (Mode Drawer, ẩn mặc định)
	mode_drawer_panel = PanelContainer.new()
	mode_drawer_panel.custom_minimum_size = Vector2(310, 230)
	mode_drawer_panel.position = Vector2(930, 215)
	mode_drawer_panel.visible = false

	var d_style = StyleBoxFlat.new()
	d_style.bg_color = Color(0.08, 0.06, 0.10, 0.96)
	d_style.border_width_left = 2
	d_style.border_width_top = 2
	d_style.border_width_right = 2
	d_style.border_width_bottom = 2
	d_style.border_color = COLOR_GOLD_PRIMARY
	d_style.corner_radius_top_left = 12
	d_style.corner_radius_top_right = 12
	d_style.corner_radius_bottom_right = 12
	d_style.corner_radius_bottom_left = 12
	d_style.shadow_color = Color(0, 0, 0, 0.75)
	d_style.shadow_size = 18
	d_style.shadow_offset = Vector2(0, 6)
	mode_drawer_panel.add_theme_stylebox_override("panel", d_style)

	var d_vbox = VBoxContainer.new()
	d_vbox.set_anchors_preset(PRESET_FULL_RECT)
	d_vbox.offset_left = 10
	d_vbox.offset_right = -10
	d_vbox.offset_top = 10
	d_vbox.offset_bottom = -10
	d_vbox.add_theme_constant_override("separation", 6)

	var drawer_hdr = Label.new()
	drawer_hdr.text = "CHỌN CHIẾN TRƯỜNG TRANH HÙNG"
	drawer_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drawer_hdr.add_theme_font_size_override("font_size", 11)
	drawer_hdr.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	d_vbox.add_child(drawer_hdr)

	var d_div = ColorRect.new()
	d_div.custom_minimum_size = Vector2(0, 1)
	d_div.color = Color(COLOR_GOLD_PRIMARY.r, COLOR_GOLD_PRIMARY.g, COLOR_GOLD_PRIMARY.b, 0.4)
	d_vbox.add_child(d_div)

	var modes_list = [
		{"id": "2v2", "icon": "⚔️", "title": "Đấu Trường 2v2", "sub": "Xếp Hạng"},
		{"id": "dynasty_5", "icon": "👑", "title": "Vương Triều 5 người", "sub": "(Chưa làm xong)"},
		{"id": "dynasty_8", "icon": "👑", "title": "Vương Triều 8 người", "sub": "(Chưa làm xong)"}
	]

	for m in modes_list:
		var m_btn = Button.new()
		m_btn.custom_minimum_size = Vector2(0, 38)
		m_btn.text = "%s  %s — %s" % [m["icon"], m["title"], m["sub"]]
		m_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_secondary_mode_button(m_btn)
		var mode_id = m["id"]
		var m_icon_str = m["icon"]
		var m_title_str = m["title"]
		m_btn.pressed.connect(func():
			_select_mode(mode_id, m_icon_str, m_title_str)
		)
		d_vbox.add_child(m_btn)

	mode_drawer_panel.add_child(d_vbox)
	cmd_container.add_child(mode_drawer_panel)

func _build_event_notice_banner() -> void:
	var banner = PanelContainer.new()
	banner.custom_minimum_size = Vector2(250, 175)
	banner.position = Vector2(24, 82)

	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.08, 0.06, 0.10, 0.88)
	b_style.border_width_left = 1
	b_style.border_width_top = 1
	b_style.border_width_right = 1
	b_style.border_width_bottom = 1
	b_style.border_color = Color(0.85, 0.70, 0.22, 0.6)
	b_style.corner_radius_top_left = 10
	b_style.corner_radius_top_right = 10
	b_style.corner_radius_bottom_right = 10
	b_style.corner_radius_bottom_left = 10
	b_style.shadow_color = Color(0, 0, 0, 0.5)
	b_style.shadow_size = 10
	b_style.shadow_offset = Vector2(0, 4)
	banner.add_theme_stylebox_override("panel", b_style)

	var b_vbox = VBoxContainer.new()
	b_vbox.set_anchors_preset(PRESET_FULL_RECT)
	b_vbox.offset_left = 12
	b_vbox.offset_right = -12
	b_vbox.offset_top = 10
	b_vbox.offset_bottom = -10
	b_vbox.add_theme_constant_override("separation", 6)

	var hdr = Label.new()
	hdr.text = "📜 BINH THƯ YẾU LƯỢC"
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	b_vbox.add_child(hdr)

	var ev1 = Button.new()
	ev1.custom_minimum_size = Vector2(0, 34)
	ev1.text = "⭐ Điểm danh 7 ngày"
	_style_secondary_mode_button(ev1)
	ev1.pressed.connect(func():
		AudioManager.play_card_select()
		_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
	)
	b_vbox.add_child(ev1)

	var ev2 = Button.new()
	ev2.custom_minimum_size = Vector2(0, 34)
	ev2.text = "🎁 Trân bảo ngập tràn"
	_style_secondary_mode_button(ev2)
	ev2.pressed.connect(func(): _show_modal("TRÂN BẢO CÁC", _build_shop_content()))
	b_vbox.add_child(ev2)

	var ev3 = Button.new()
	ev3.custom_minimum_size = Vector2(0, 34)
	ev3.text = "🏆 Đua Top Hoàng Triều"
	_style_secondary_mode_button(ev3)
	ev3.pressed.connect(func(): _show_modal("BẢNG PHONG THẦN", _build_leaderboard_content()))
	b_vbox.add_child(ev3)

	banner.add_child(b_vbox)
	add_child(banner)

func _style_bronze_drum_cta(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.70, 0.12, 0.08, 0.96) # Rich royal vermilion
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.86, 0.35, 1.0) # Bright gold
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_right = 18
	normal.corner_radius_bottom_left = 18
	normal.shadow_color = Color(0.68, 0.10, 0.05, 0.65)
	normal.shadow_size = 14
	normal.shadow_offset = Vector2(0, 5)

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.82, 0.16, 0.10, 1.0)
	hover.border_color = Color(1.0, 0.95, 0.55, 1.0)
	hover.shadow_size = 20
	hover.shadow_offset = Vector2(0, 6)

	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.55, 0.08, 0.05, 1.0)
	pressed.shadow_size = 4
	pressed.shadow_offset = Vector2(0, 2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

func _toggle_mode_drawer() -> void:
	AudioManager.play_card_select()
	if is_instance_valid(mode_drawer_panel):
		mode_drawer_panel.visible = not mode_drawer_panel.visible

func _select_mode(mode_id: String, icon_str: String, title_str: String) -> void:
	AudioManager.play_card_select()
	current_selected_mode = mode_id
	if is_instance_valid(mode_title_lbl):
		mode_title_lbl.text = title_str.to_upper()
	if is_instance_valid(mode_selector_btn):
		var icon_node = mode_selector_btn.find_child("ModeIcon", true, false) as Label
		if icon_node:
			icon_node.text = icon_str
	if is_instance_valid(mode_drawer_panel):
		mode_drawer_panel.visible = false

func _on_battle_cta_pressed() -> void:
	AudioManager.play_slash()
	match current_selected_mode:
		"2v2":
			_start_mode_2v2()
		"dynasty_5":
			_start_mode_dynasty()
		"dynasty_8":
			_start_mode_dynasty()
		_:
			_start_mode_2v2()

func _trigger_hero_interaction() -> void:
	AudioManager.play_skill()
	if is_instance_valid(hero_dialogue_bubble):
		hero_dialogue_bubble.visible = true
		hero_dialogue_bubble.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(hero_dialogue_bubble, "scale", Vector2(1.05, 1.05), 0.15)
		tw.tween_property(hero_dialogue_bubble, "scale", Vector2(1.0, 1.0), 0.15)
		tw.tween_interval(3.5)
		tw.tween_property(hero_dialogue_bubble, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): hero_dialogue_bubble.visible = false)

func _style_secondary_mode_button(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.09, 0.15, 0.92)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.85, 0.70, 0.22, 0.6)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.20, 0.15, 0.25, 1.0)
	hover.border_color = COLOR_GOLD_ACCENT
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", normal)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1.0))
	btn.add_theme_font_size_override("font_size", 12)

func _build_bottom_nav_dock() -> void:
	var dock_panel = Panel.new()
	dock_panel.custom_minimum_size = Vector2(1280, 64)
	dock_panel.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock_panel.offset_top = -64

	var dock_style = StyleBoxFlat.new()
	dock_style.bg_color = Color(0.06, 0.04, 0.08, 0.94) # Regal Dark Lacquer
	dock_style.border_width_top = 2
	dock_style.border_color = COLOR_GOLD_PRIMARY
	dock_style.shadow_color = COLOR_SHADOW_DEEP
	dock_style.shadow_size = 8
	dock_style.shadow_offset = Vector2(0, -3)
	dock_panel.add_theme_stylebox_override("panel", dock_style)
	add_child(dock_panel)

	var dock_hbox = HBoxContainer.new()
	dock_hbox.set_anchors_preset(PRESET_FULL_RECT)
	dock_hbox.offset_left = 32
	dock_hbox.offset_right = -32
	dock_hbox.offset_top = 8
	dock_hbox.offset_bottom = -8
	dock_hbox.add_theme_constant_override("separation", 14)
	dock_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	dock_panel.add_child(dock_hbox)

	var nav_items = [
		{"icon": "🎖️", "title": "DANH TƯỚNG", "action": func(): _show_fullscreen_heroes()},
		{"icon": "⛩️", "title": "THẦN ĐIỆN", "action": func(): _show_fullscreen_than_dien()},
		{"icon": "🏆", "title": "BẢNG VÀNG", "action": func(): _show_modal("BẢNG PHONG THẦN", _build_leaderboard_content())},
		{"icon": "📜", "title": "NHIỆM VỤ", "is_quest": true, "action": func(): _open_quests_modal()},
		{"icon": "🎒", "title": "TÚI ĐỒ", "action": func(): _open_inventory_modal()},
	]

	for item in nav_items:
		var btn = Button.new()
		btn.size_flags_horizontal = SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(180, 44)
		btn.text = "%s  %s" % [item["icon"], item["title"]]
		_style_white_gold_button(btn, 8, 5, Vector2(0, 3))
		btn.pressed.connect(func():
			AudioManager.play_card_select()
			item["action"].call()
		)
		if item.get("is_quest", false):
			quest_nav_btn = btn
		dock_hbox.add_child(btn)
	_update_quest_nav_indicator()

func _build_modal_layer() -> void:
	modal_overlay = ColorRect.new()
	modal_overlay.set_anchors_preset(PRESET_FULL_RECT)
	modal_overlay.color = Color(0.02, 0.04, 0.08, 0.75)
	modal_overlay.visible = false
	add_child(modal_overlay)

	# Click outside to close
	modal_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if is_matchmaking_active:
				return
			if is_instance_valid(modal_panel):
				var rect = modal_panel.get_global_rect()
				if rect.has_point(event.global_position):
					return
			_hide_modal()
	)

	modal_panel = PanelContainer.new()
	modal_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_panel.custom_minimum_size = Vector2(840, 530)
	modal_panel.set_anchors_preset(PRESET_CENTER)
	modal_panel.grow_horizontal = GROW_DIRECTION_BOTH
	modal_panel.grow_vertical = GROW_DIRECTION_BOTH

	var mp_style = StyleBoxFlat.new()
	mp_style.bg_color = Color(0.08, 0.06, 0.11, 0.98) # Regal dark lacquer modal
	mp_style.border_width_left = 3
	mp_style.border_width_top = 3
	mp_style.border_width_right = 3
	mp_style.border_width_bottom = 3
	mp_style.border_color = COLOR_GOLD_PRIMARY
	mp_style.corner_radius_top_left = 14
	mp_style.corner_radius_top_right = 14
	mp_style.corner_radius_bottom_right = 14
	mp_style.corner_radius_bottom_left = 14
	mp_style.shadow_color = Color(0, 0, 0, 0.75)
	mp_style.shadow_size = 24
	mp_style.shadow_offset = Vector2(0, 10)
	modal_panel.add_theme_stylebox_override("panel", mp_style)
	modal_overlay.add_child(modal_panel)

	var m_vbox = VBoxContainer.new()
	m_vbox.set_anchors_preset(PRESET_FULL_RECT)
	m_vbox.offset_left = 18
	m_vbox.offset_right = -18
	m_vbox.offset_top = 16
	m_vbox.offset_bottom = -16
	m_vbox.add_theme_constant_override("separation", 10)
	modal_panel.add_child(m_vbox)

	# Modal Header
	var m_hdr = HBoxContainer.new()
	modal_title_label = Label.new()
	modal_title_label.text = "THÔNG TIN CHI TIẾT"
	modal_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	modal_title_label.add_theme_font_size_override("font_size", 20)
	modal_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38, 1.0))
	m_hdr.add_child(modal_title_label)

	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.text = "✖"
	_style_white_gold_button(close_btn, 8, 4, Vector2(0, 2))
	close_btn.pressed.connect(_hide_modal)
	m_hdr.add_child(close_btn)
	m_vbox.add_child(m_hdr)

	var m_div = ColorRect.new()
	m_div.custom_minimum_size = Vector2(0, 2)
	m_div.color = COLOR_GOLD_PRIMARY
	m_vbox.add_child(m_div)

	# Modal Scroll Container for content
	modal_scroll = ScrollContainer.new()
	modal_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	modal_content_container = VBoxContainer.new()
	modal_content_container.size_flags_horizontal = SIZE_EXPAND_FILL
	modal_content_container.add_theme_constant_override("separation", 10)
	modal_scroll.add_child(modal_content_container)
	m_vbox.add_child(modal_scroll)

# --- Button Styling Helpers with Prominent Shadows ---
func _style_white_gold_button(btn: Button, corner_radius: int = 8, shadow_size: int = 5, shadow_offset: Vector2 = Vector2(0, 3)) -> void:
	# Normal StyleBox
	var normal = StyleBoxFlat.new()
	normal.bg_color = COLOR_WHITE_BASE
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = COLOR_GOLD_BORDER
	normal.corner_radius_top_left = corner_radius
	normal.corner_radius_top_right = corner_radius
	normal.corner_radius_bottom_right = corner_radius
	normal.corner_radius_bottom_left = corner_radius
	normal.shadow_color = COLOR_SHADOW
	normal.shadow_size = shadow_size
	normal.shadow_offset = shadow_offset
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4

	# Hover StyleBox
	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_WHITE_HOVER
	hover.border_color = COLOR_GOLD_ACCENT
	hover.shadow_color = COLOR_SHADOW_DEEP
	hover.shadow_size = shadow_size + 3
	hover.shadow_offset = shadow_offset + Vector2(0, 1)

	# Pressed StyleBox
	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = COLOR_WHITE_PRESSED
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

	btn.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.45, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.85, 0.70, 0.25, 1.0))
	btn.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)

func _style_white_gold_action_button(btn: Button) -> void:
	# Prominent CTA Button on Mode Cards
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.96, 0.80, 0.28, 1.0) # Radiant Gold fill
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.72, 0.54, 0.12, 1.0)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.shadow_color = COLOR_SHADOW_DEEP
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 4)

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(1.0, 0.88, 0.38, 1.0)
	hover.shadow_size = 8
	hover.shadow_offset = Vector2(0, 5)

	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.88, 0.72, 0.22, 1.0)
	pressed.shadow_size = 2
	pressed.shadow_offset = Vector2(0, 1)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

	btn.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", Color(0.18, 0.12, 0.02, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.06, 0.04, 0.01, 1.0))
	btn.add_theme_font_size_override("font_size", 14)

func _format_number(num: int) -> String:
	var s = str(abs(num))
	var res = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	if num < 0:
		res = "-" + res
	return res

# --- Data Loading ---
func _refresh_user_profile_ui() -> void:
	_load_user_data()

func _load_user_data() -> void:
	if AuthManager:
		var name_str = AuthManager.current_user_name
		if name_str == "" or name_str == "Đại Tướng Quân":
			if AuthManager.current_user_email != "":
				name_str = AuthManager.current_user_email.split("@")[0].to_upper()
			else:
				name_str = "LÝ THƯỜNG KIỆT"
		if is_instance_valid(player_name_label):
			player_name_label.text = name_str

		if is_instance_valid(level_badge_label):
			level_badge_label.text = " CẤP %d " % AuthManager.current_level

		var mil_info = AuthManager.get_military_rank_info()
		if is_instance_valid(rank_label):
			rank_label.text = "%s (%d/%dđ)" % [mil_info["full_name"], mil_info["points"], mil_info["next_min"]]

		var next_exp = AuthManager.get_exp_to_next_level()
		if is_instance_valid(exp_bar):
			exp_bar.max_value = next_exp
			exp_bar.value = AuthManager.current_exp
		if is_instance_valid(exp_text_label):
			exp_text_label.text = "%d/%d EXP" % [AuthManager.current_exp, next_exp]

		current_silver = AuthManager.current_silver
		current_gold = AuthManager.current_gold
		current_hero_tickets = AuthManager.current_hero_tickets
		if is_instance_valid(silver_label):
			silver_label.text = _format_number(current_silver)
		if is_instance_valid(gold_label):
			gold_label.text = _format_number(current_gold)
		if is_instance_valid(ticket_label):
			ticket_label.text = "%s Vé" % _format_number(current_hero_tickets)

		# Cập nhật ảnh Danh Tướng trung tâm theo tướng sở hữu/chọn
		if is_instance_valid(hero_sprite):
			var active_slug = "tran_hung_dao"
			if AuthManager.current_generals.size() > 0:
				active_slug = str(AuthManager.current_generals[0]).to_lower()
			var hero_trans_path = "res://assets/heroes_transparent/%s.png" % active_slug
			if ResourceLoader.exists(hero_trans_path):
				hero_sprite.texture = load(hero_trans_path)
			elif ResourceLoader.exists("res://assets/ui/%s.png" % active_slug):
				hero_sprite.texture = load("res://assets/ui/%s.png" % active_slug)
		_update_quest_nav_indicator()
		_refresh_inventory_content()

# --- Ambient Particle Embers ---
func _start_ambient_effects() -> void:
	for i in range(16):
		var ember = ColorRect.new()
		var s = randf_range(3.0, 6.0)
		ember.custom_minimum_size = Vector2(s, s)
		ember.color = Color(1.0, randf_range(0.7, 0.9), 0.3, randf_range(0.3, 0.7))
		ember.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		ember.set_meta("speed_y", randf_range(20.0, 50.0))
		ember.set_meta("drift_x", randf_range(-15.0, 15.0))
		embers_layer.add_child(ember)
		ember_particles.append(ember)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(_fullscreen_heroes_panel) or not is_instance_valid(_heroes_gallery_scroll):
		return
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		_heroes_swipe_active = event.pressed
		_heroes_swipe_last_y = event.position.y
		return
	if event is InputEventScreenDrag and _heroes_swipe_active:
		var delta_y: float = event.position.y - _heroes_swipe_last_y
		_heroes_swipe_last_y = event.position.y
		if abs(delta_y) >= 0.5:
			_heroes_gallery_scroll.scroll_vertical = maxi(0, int(_heroes_gallery_scroll.scroll_vertical - delta_y))

func _process(delta: float) -> void:
	for p in ember_particles:
		var pos = p.position
		pos.y -= p.get_meta("speed_y") * delta
		pos.x += p.get_meta("drift_x") * delta * sin(Time.get_ticks_msec() * 0.002)
		if pos.y < -10:
			pos.y = 730
			pos.x = randf_range(0, 1280)
		p.position = pos

# --- Scene Navigation ---
func _start_mode_practice() -> void:
	print("[Home] Chuyển cảnh vào Tập Kích Sơn Tặc (Tutorial Battle)...")
	get_tree().change_scene_to_file("res://scenes/tutorial_battle.tscn")

func _start_mode_dynasty() -> void:
	_start_2v2_matchmaking(current_selected_mode)

func _start_mode_2v2() -> void:
	_start_2v2_matchmaking()

func _start_mode_national_war() -> void:
	_show_modal("QUỐC CHIẾN BỐN CÕI", _build_national_war_content())

func _on_profile_clicked() -> void:
	AudioManager.play_card_select()
	_show_modal("HỒ SƠ TƯỚNG QUÂN", _build_profile_content())

# --- Modal System ---
func _cancel_matchmaking_internal() -> void:
	mm_is_cancelled = true
	is_matchmaking_active = false
	var my_uid = mm_session_user_id
	if my_uid.is_empty() and AppwriteMatchmaking:
		my_uid = AppwriteMatchmaking.my_session_user_id
	if my_uid.is_empty() and AuthManager:
		my_uid = AuthManager.current_user_id
	if mm_is_host and mm_active_room_id != "":
		AppwriteMatchmaking.delete_room(mm_active_room_id)
	elif mm_active_room_id != "" and my_uid != "":
		AppwriteMatchmaking.leave_room_slot(mm_active_room_id, my_uid)

func _show_modal(title_text: String, content_node: Node) -> void:
	if is_matchmaking_active and not title_text.begins_with("⚔️ TÌM TRẬN"):
		_cancel_matchmaking_internal()

	AudioManager.play_card_draw()
	if is_instance_valid(modal_title_label):
		modal_title_label.text = title_text

	# Clear previous content
	if is_instance_valid(modal_content_container):
		for child in modal_content_container.get_children():
			child.queue_free()

		if content_node:
			modal_content_container.add_child(content_node)

	if is_instance_valid(modal_overlay):
		modal_overlay.visible = true
	if is_instance_valid(modal_panel):
		if title_text.begins_with("⚔️ TÌM TRẬN"):
			modal_panel.custom_minimum_size = Vector2(580, 310)
			if is_instance_valid(modal_scroll):
				modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		elif title_text == "HỒ SƠ TƯỚNG QUÂN":
			modal_panel.custom_minimum_size = Vector2(600, 470)
			if is_instance_valid(modal_scroll):
				modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		elif title_text == "BẢNG PHONG THẦN":
			modal_panel.custom_minimum_size = Vector2(880, 560)
			if is_instance_valid(modal_scroll):
				modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		elif title_text == "QUÂN LỆNH TRIỀU ĐÌNH":
			modal_panel.custom_minimum_size = Vector2(880, 560)
			if is_instance_valid(modal_scroll):
				modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		else:
			modal_panel.custom_minimum_size = Vector2(840, 530)
			if is_instance_valid(modal_scroll):
				modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		modal_panel.scale = Vector2(0.9, 0.9)
		modal_panel.modulate.a = 0.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(modal_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(modal_panel, "modulate:a", 1.0, 0.15)

func _hide_modal() -> void:
	if is_matchmaking_active:
		_cancel_matchmaking_internal()

	AudioManager.play_card_select()
	if is_instance_valid(modal_panel):
		var tw = create_tween().set_parallel(true)
		tw.tween_property(modal_panel, "scale", Vector2(0.9, 0.9), 0.15)
		tw.tween_property(modal_panel, "modulate:a", 0.0, 0.15)
		await tw.finished
		modal_panel.custom_minimum_size = Vector2(840, 530)
		if is_instance_valid(modal_scroll):
			modal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	if is_instance_valid(modal_overlay):
		modal_overlay.visible = false
	if is_instance_valid(modal_content_container):
		for child in modal_content_container.get_children():
			child.queue_free()

# --- EXP Animation & Level Up System ---
func _check_pending_exp_gain() -> void:
	if AuthManager and not AuthManager.pending_exp_gain.is_empty():
		var p_gain = AuthManager.pending_exp_gain.duplicate()
		AuthManager.pending_exp_gain.clear()
		await get_tree().create_timer(0.4).timeout
		if p_gain.get("show_modal", false):
			_show_level_up_modal(p_gain.get("old_level", 1), p_gain.get("new_level", 2))

func gain_exp_animated(amount: int, on_finished: Callable = Callable()) -> void:
	if not AuthManager:
		if on_finished.is_valid(): on_finished.call()
		return
	var start_lvl = AuthManager.current_level
	var start_exp = AuthManager.current_exp
	_run_exp_animation_loop(start_lvl, start_exp, amount, on_finished)

func _run_exp_animation_loop(lvl: int, cur_exp: int, remaining: int, on_finished: Callable = Callable()) -> void:
	var req = AuthManager.get_exp_required_for_level(lvl + 1)
	if is_instance_valid(exp_bar):
		exp_bar.max_value = req
		exp_bar.value = cur_exp
	if is_instance_valid(exp_text_label):
		exp_text_label.text = "%d/%d EXP" % [cur_exp, req]
	if is_instance_valid(level_badge_label):
		level_badge_label.text = " CẤP %d " % lvl

	var target_exp = cur_exp + remaining
	if target_exp < req:
		var last_tick = cur_exp
		var tw = create_tween()
		var fill_dur = clampf(float(remaining) * 0.05, 0.4, 1.2)
		tw.tween_method(func(val: float):
			if is_instance_valid(exp_bar): exp_bar.value = val
			var int_v = int(val)
			if is_instance_valid(exp_text_label): exp_text_label.text = "%d/%d EXP" % [int_v, req]
			if int_v > last_tick:
				last_tick = int_v
				var progress = float(int_v) / float(req)
				AudioManager.play_exp_tick(lerpf(1.0, 1.45, progress), -2.0)
		, float(cur_exp), float(target_exp), fill_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tw.tween_callback(func():
			AuthManager.current_level = lvl
			AuthManager.current_exp = target_exp
			AuthManager.save_session()
			AuthManager.save_profile_to_appwrite()
			_load_user_data()
			if on_finished.is_valid(): on_finished.call()
		)
	else:
		var last_tick = cur_exp
		var tw = create_tween()
		var to_full = req - cur_exp
		var fill_dur = clampf(float(to_full) * 0.045, 0.4, 1.0)
		tw.tween_method(func(val: float):
			if is_instance_valid(exp_bar): exp_bar.value = val
			var int_v = int(val)
			if is_instance_valid(exp_text_label): exp_text_label.text = "%d/%d EXP" % [int_v, req]
			if int_v > last_tick:
				last_tick = int_v
				var progress = float(int_v) / float(req)
				AudioManager.play_exp_tick(lerpf(1.0, 1.5, progress), -2.0)
		, float(cur_exp), float(req), fill_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		tw.tween_callback(func():
			if is_instance_valid(exp_bar):
				var flash_tw = create_tween()
				flash_tw.tween_property(exp_bar, "modulate", Color(1.8, 1.6, 0.8, 1.0), 0.15)
				flash_tw.tween_property(exp_bar, "modulate", Color.WHITE, 0.15)

			AudioManager.play_levelup()

			_show_level_up_modal(lvl, lvl + 1, func():
				var leftover = remaining - to_full
				var next_lvl = lvl + 1
				AuthManager.current_level = next_lvl
				AuthManager.current_exp = 0
				AuthManager.save_session()
				AuthManager.save_profile_to_appwrite()

				if is_instance_valid(level_badge_label):
					level_badge_label.text = " CẤP %d " % next_lvl
					var bounce_tw = create_tween()
					bounce_tw.tween_property(level_badge_label, "scale", Vector2(1.35, 1.35), 0.15)
					bounce_tw.tween_property(level_badge_label, "scale", Vector2(1.0, 1.0), 0.15)

				if leftover > 0:
					_run_exp_animation_loop(next_lvl, 0, leftover, on_finished)
				else:
					var next_req = AuthManager.get_exp_required_for_level(next_lvl + 1)
					if is_instance_valid(exp_bar):
						exp_bar.max_value = next_req
						exp_bar.value = 0
					if is_instance_valid(exp_text_label):
						exp_text_label.text = "0/%d EXP" % next_req
					_load_user_data()
					if on_finished.is_valid(): on_finished.call()
			)
		)

func _show_level_up_modal(old_lvl: int, new_lvl: int, on_close: Callable = Callable()) -> void:
	if levelup_overlay != null and is_instance_valid(levelup_overlay):
		levelup_overlay.queue_free()

	levelup_overlay = Control.new()
	levelup_overlay.set_anchors_preset(PRESET_FULL_RECT)
	levelup_overlay.z_index = 120
	add_child(levelup_overlay)

	# 1. Dark Vignette Background
	var bg_dim = ColorRect.new()
	bg_dim.set_anchors_preset(PRESET_FULL_RECT)
	bg_dim.color = Color(0.01, 0.02, 0.04, 0.82)
	levelup_overlay.add_child(bg_dim)

	# 2. Rotating Imperial Sunburst Rays behind modal
	var rays_center = Control.new()
	rays_center.position = Vector2(640, 360)
	levelup_overlay.add_child(rays_center)

	var num_rays = 16
	for i in range(num_rays):
		var ray = Line2D.new()
		var angle = (float(i) / float(num_rays)) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		ray.points = PackedVector2Array([Vector2.ZERO, dir * 550])
		ray.width = 48.0
		ray.default_color = Color(1.0, 0.85, 0.35, 0.07 if i % 2 == 0 else 0.03)
		rays_center.add_child(ray)

	var rays_tw = rays_center.create_tween().set_loops()
	rays_tw.tween_property(rays_center, "rotation", TAU, 24.0).as_relative()

	# 3. Floating Golden Sparkle Particles
	for i in range(20):
		var sp = Label.new()
		sp.text = "✦" if i % 3 == 0 else ("✨" if i % 3 == 1 else "★")
		sp.add_theme_font_size_override("font_size", randi_range(12, 20))
		sp.add_theme_color_override("font_color", Color(1.0, randf_range(0.8, 0.95), randf_range(0.3, 0.6), randf_range(0.5, 0.9)))
		sp.position = Vector2(randf_range(300, 980), randf_range(150, 600))
		levelup_overlay.add_child(sp)

		var float_tw = sp.create_tween().set_loops()
		var dur = randf_range(2.0, 4.0)
		float_tw.tween_property(sp, "position:y", sp.position.y - randf_range(60, 120), dur)
		float_tw.parallel().tween_property(sp, "modulate:a", 0.1, dur)
		float_tw.tween_property(sp, "position:y", sp.position.y, 0.01)
		float_tw.tween_property(sp, "modulate:a", 1.0, 0.01)

	# 4. Main Imperial Celebration Box
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(620, 470)
	box.set_anchors_preset(PRESET_CENTER)
	box.grow_horizontal = GROW_DIRECTION_BOTH
	box.grow_vertical = GROW_DIRECTION_BOTH

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.98, 0.97, 0.93, 0.98)
	box_style.border_width_left = 3
	box_style.border_width_top = 3
	box_style.border_width_right = 3
	box_style.border_width_bottom = 3
	box_style.border_color = Color(0.88, 0.72, 0.22, 1.0)
	box_style.corner_radius_top_left = 14
	box_style.corner_radius_top_right = 14
	box_style.corner_radius_bottom_right = 14
	box_style.corner_radius_bottom_left = 14
	box_style.shadow_color = Color(0, 0, 0, 0.65)
	box_style.shadow_size = 28
	box_style.shadow_offset = Vector2(0, 10)
	box.add_theme_stylebox_override("panel", box_style)
	levelup_overlay.add_child(box)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 22
	vbox.offset_right = -22
	vbox.offset_top = 18
	vbox.offset_bottom = -18
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(vbox)

	# Header Crown & Title
	var crown_lbl = Label.new()
	crown_lbl.text = "👑  TRIỀU ĐÌNH ĐẠI VIỆT SẮC PHONG  👑"
	crown_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown_lbl.add_theme_font_size_override("font_size", 12)
	crown_lbl.add_theme_color_override("font_color", Color(0.72, 0.52, 0.10, 1.0))
	vbox.add_child(crown_lbl)

	var title_lbl = Label.new()
	title_lbl.text = "🎉  THĂNG CẤP HOÀNG TRIỀU  🎉"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(0.68, 0.44, 0.04, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(1.0, 0.88, 0.45, 0.7))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title_lbl)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.88, 0.72, 0.22, 0.8)
	vbox.add_child(div)

	# Centerpiece: Level Upgrade Transition (CẤP X ➔➔➔ CẤP Y)
	var trans_hbox = HBoxContainer.new()
	trans_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	trans_hbox.add_theme_constant_override("separation", 18)

	# Old Level Badge
	var old_badge = PanelContainer.new()
	old_badge.custom_minimum_size = Vector2(100, 48)
	var ob_style = StyleBoxFlat.new()
	ob_style.bg_color = Color(0.90, 0.89, 0.85, 1.0)
	ob_style.border_width_left = 1
	ob_style.border_width_top = 1
	ob_style.border_width_right = 1
	ob_style.border_width_bottom = 1
	ob_style.border_color = Color(0.70, 0.68, 0.62, 1.0)
	ob_style.corner_radius_top_left = 8
	ob_style.corner_radius_top_right = 8
	ob_style.corner_radius_bottom_right = 8
	ob_style.corner_radius_bottom_left = 8
	old_badge.add_theme_stylebox_override("panel", ob_style)

	var old_lbl = Label.new()
	old_lbl.text = "CẤP %d" % old_lvl
	old_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	old_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	old_lbl.add_theme_font_size_override("font_size", 16)
	old_lbl.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38, 1.0))
	old_badge.add_child(old_lbl)
	trans_hbox.add_child(old_badge)

	# Glowing Golden Arrow
	var arrow_lbl = Label.new()
	arrow_lbl.text = "➔➔➔"
	arrow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow_lbl.add_theme_font_size_override("font_size", 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.96, 0.65, 0.05, 1.0))
	trans_hbox.add_child(arrow_lbl)

	# New Level Radiant Golden Medal
	var new_badge = PanelContainer.new()
	new_badge.custom_minimum_size = Vector2(130, 56)
	var nb_style = StyleBoxFlat.new()
	nb_style.bg_color = Color(0.98, 0.85, 0.30, 1.0)
	nb_style.border_width_left = 2
	nb_style.border_width_top = 2
	nb_style.border_width_right = 2
	nb_style.border_width_bottom = 2
	nb_style.border_color = Color(0.72, 0.52, 0.08, 1.0)
	nb_style.corner_radius_top_left = 10
	nb_style.corner_radius_top_right = 10
	nb_style.corner_radius_bottom_right = 10
	nb_style.corner_radius_bottom_left = 10
	nb_style.shadow_color = Color(0, 0, 0, 0.35)
	nb_style.shadow_size = 8
	nb_style.shadow_offset = Vector2(0, 3)
	new_badge.add_theme_stylebox_override("panel", nb_style)

	var nb_vbox = VBoxContainer.new()
	nb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	nb_vbox.add_theme_constant_override("separation", 0)

	var nb_sub = Label.new()
	nb_sub.text = "⭐ TIẾN CẤP ⭐"
	nb_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb_sub.add_theme_font_size_override("font_size", 9)
	nb_sub.add_theme_color_override("font_color", Color(0.45, 0.30, 0.02, 1.0))
	nb_vbox.add_child(nb_sub)

	var new_lbl = Label.new()
	new_lbl.text = "CẤP %d" % new_lvl
	new_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_lbl.add_theme_font_size_override("font_size", 22)
	new_lbl.add_theme_color_override("font_color", Color(0.12, 0.08, 0.02, 1.0))
	nb_vbox.add_child(new_lbl)

	new_badge.add_child(nb_vbox)
	trans_hbox.add_child(new_badge)
	vbox.add_child(trans_hbox)

	# Congratulatory Speech Plaque
	var speech_panel = PanelContainer.new()
	var sp_style = StyleBoxFlat.new()
	sp_style.bg_color = Color(0.95, 0.94, 0.89, 1.0)
	sp_style.border_width_left = 2
	sp_style.border_color = Color(0.85, 0.70, 0.22, 0.9)
	sp_style.corner_radius_top_left = 6
	sp_style.corner_radius_top_right = 6
	sp_style.corner_radius_bottom_right = 6
	sp_style.corner_radius_bottom_left = 6
	speech_panel.add_theme_stylebox_override("panel", sp_style)

	var speech_hbox = HBoxContainer.new()
	speech_hbox.offset_left = 10
	speech_hbox.offset_right = -10
	speech_hbox.offset_top = 8
	speech_hbox.offset_bottom = -8
	speech_hbox.add_theme_constant_override("separation", 10)

	var hero_av = TextureRect.new()
	hero_av.custom_minimum_size = Vector2(40, 40)
	hero_av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var h_tex = load("res://assets/ui/ly_thuong_kiet.png")
	if h_tex: hero_av.texture = h_tex
	speech_hbox.add_child(hero_av)

	var s_lbl = Label.new()
	s_lbl.text = "“Trảm tướng đoạt kỳ, uy danh vang dội non sông! Triều đình đặc cách phong tước và ban phát bổng lộc hoàng triều cho Tướng Quân!”"
	s_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s_lbl.add_theme_font_size_override("font_size", 11)
	s_lbl.add_theme_color_override("font_color", Color(0.20, 0.16, 0.08, 1.0))
	speech_hbox.add_child(s_lbl)

	speech_panel.add_child(speech_hbox)
	vbox.add_child(speech_panel)

	# 3 Reward & Perk Cards (Đã xóa Khí Lực và không tặng Vàng free)
	var perk_hbox = HBoxContainer.new()
	perk_hbox.add_theme_constant_override("separation", 10)
	perk_hbox.custom_minimum_size = Vector2(0, 95)

	var perks = [
		{"icon": "🔓", "title": "MỞ KHÓA TÍNH NĂNG", "desc": "Đấu Trường 2v2 Xếp Hạng\nVương Triều Tranh Bá", "c": Color(0.75, 0.35, 0.15, 1.0)},
		{"icon": "🥈", "title": "BỔNG LỘC TRIỀU ĐÌNH", "desc": "+1,000 BẠC\nQuân lương triều đình phong thưởng", "c": Color(0.25, 0.45, 0.70, 1.0)},
		{"icon": "🎖️", "title": "QUÂN CÔNG THĂNG TRẬT", "desc": "Uy Danh Vang Dội Tứ Hải\nTriều Đình Đặc Cách Gia Phong", "c": Color(0.20, 0.55, 0.25, 1.0)}
	]

	for p in perks:
		var p_card = PanelContainer.new()
		p_card.size_flags_horizontal = SIZE_EXPAND_FILL
		var pc_style = StyleBoxFlat.new()
		pc_style.bg_color = Color(0.96, 0.95, 0.91, 1.0)
		pc_style.border_width_left = 1
		pc_style.border_width_top = 1
		pc_style.border_width_right = 1
		pc_style.border_width_bottom = 1
		pc_style.border_color = Color(0.85, 0.70, 0.22, 0.7)
		pc_style.corner_radius_top_left = 6
		pc_style.corner_radius_top_right = 6
		pc_style.corner_radius_bottom_right = 6
		pc_style.corner_radius_bottom_left = 6
		pc_style.shadow_color = Color(0, 0, 0, 0.20)
		pc_style.shadow_size = 4
		pc_style.shadow_offset = Vector2(0, 2)
		p_card.add_theme_stylebox_override("panel", pc_style)

		var pv = VBoxContainer.new()
		pv.offset_left = 6
		pv.offset_right = -6
		pv.offset_top = 6
		pv.offset_bottom = -6
		pv.alignment = BoxContainer.ALIGNMENT_CENTER
		pv.add_theme_constant_override("separation", 2)

		var p_icon = Label.new()
		p_icon.text = "%s %s" % [p["icon"], p["title"]]
		p_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p_icon.add_theme_font_size_override("font_size", 10)
		p_icon.add_theme_color_override("font_color", p["c"])
		pv.add_child(p_icon)

		var p_desc = Label.new()
		p_desc.text = p["desc"]
		p_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p_desc.add_theme_font_size_override("font_size", 10)
		p_desc.add_theme_color_override("font_color", Color(0.18, 0.15, 0.10, 1.0))
		pv.add_child(p_desc)

		p_card.add_child(pv)
		perk_hbox.add_child(p_card)

	vbox.add_child(perk_hbox)

	# Action Button
	var confirm_btn = Button.new()
	confirm_btn.custom_minimum_size = Vector2(340, 44)
	confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	confirm_btn.text = "TIẾP NHẬN BỔNG LỘC & TIẾP TỤC ➜"
	_style_white_gold_action_button(confirm_btn)

	confirm_btn.pressed.connect(func():
		confirm_btn.release_focus()
		confirm_btn.disabled = true
		AudioManager.play_card_select()

		if AuthManager:
			AuthManager.current_silver += 1000
			AuthManager.save_session()
			AuthManager.save_profile_to_appwrite()
			_load_user_data()

		var close_tw = create_tween().set_parallel(true)
		close_tw.tween_property(box, "scale", Vector2(0.8, 0.8), 0.2)
		close_tw.tween_property(levelup_overlay, "modulate:a", 0.0, 0.2)
		await close_tw.finished
		levelup_overlay.queue_free()
		levelup_overlay = null

		if on_close.is_valid():
			on_close.call()
	)
	vbox.add_child(confirm_btn)

	# Pop-in Animation
	box.scale = Vector2(0.65, 0.65)
	box.modulate.a = 0.0
	var pop_tw = create_tween().set_parallel(true)
	pop_tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tw.tween_property(box, "modulate:a", 1.0, 0.25)

# --- Fullscreen Danh Tướng Gallery ---
func _show_fullscreen_heroes() -> void:
	if is_instance_valid(_fullscreen_heroes_panel):
		_fullscreen_heroes_panel.queue_free()
		_fullscreen_heroes_panel = null

	var fs = Control.new()
	fs.name = "FullscreenHeroesPanel"
	fs.set_anchors_preset(PRESET_FULL_RECT)
	fs.z_index = 85
	_fullscreen_heroes_panel = fs
	add_child(fs)

	# Fullscreen dark royal background
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.045, 0.055, 0.08, 0.985)
	fs.add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	fs.add_child(main_vbox)

	# 1. Top Header Bar
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 64)
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	hp_style.border_width_bottom = 2
	hp_style.border_color = Color(0.85, 0.72, 0.32, 0.5)
	hp_style.content_margin_left = 28
	hp_style.content_margin_right = 28
	hp_style.content_margin_top = 8
	hp_style.content_margin_bottom = 8
	header_panel.add_theme_stylebox_override("panel", hp_style)
	main_vbox.add_child(header_panel)

	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header_hbox)

	# Title & Subtitle on left
	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "📜 KHO DANH TƯỚNG ĐẠI VIỆT"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	title_vbox.add_child(title_lbl)

	# Đếm số lượng tướng sở hữu và ưu tiên sắp xếp tướng đã sở hữu hiển thị trước, tiếp theo là ID tăng dần
	var all_heroes: Array[Dictionary] = HeroDatabase.get_all_heroes().duplicate() if HeroDatabase else []
	var owned_map: Dictionary = {}
	var owned_count: int = 0
	for h in all_heroes:
		var hid: int = int(h.get("id", 0))
		var is_owned: bool = HeroDatabase.is_hero_owned(hid) if HeroDatabase else false
		owned_map[hid] = is_owned
		if is_owned:
			owned_count += 1

	all_heroes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id: int = int(a.get("id", 0))
		var b_id: int = int(b.get("id", 0))
		var a_owned: bool = owned_map.get(a_id, false)
		var b_owned: bool = owned_map.get(b_id, false)
		if a_owned != b_owned:
			return a_owned
		return a_id < b_id
	)

	var count_lbl = Label.new()
	count_lbl.text = "Bách Tướng Đại Việt • Đã chiêu mộ: %d / %d danh tướng" % [owned_count, all_heroes.size()]
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 0.7, 1.0))
	title_vbox.add_child(count_lbl)

	# Spacer pushing close button to the far right
	var spacer = Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hbox.add_child(spacer)

	# Close Button on the far right
	var close_btn = Button.new()
	close_btn.text = "✕ ĐÓNG"
	close_btn.custom_minimum_size = Vector2(110, 42)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var cb_normal = StyleBoxFlat.new()
	cb_normal.bg_color = Color(0.42, 0.11, 0.14, 0.95)
	cb_normal.border_color = Color(0.95, 0.45, 0.48, 1.0)
	cb_normal.border_width_left = 1
	cb_normal.border_width_top = 1
	cb_normal.border_width_right = 1
	cb_normal.border_width_bottom = 1
	cb_normal.corner_radius_top_left = 8
	cb_normal.corner_radius_top_right = 8
	cb_normal.corner_radius_bottom_right = 8
	cb_normal.corner_radius_bottom_left = 8
	var cb_hover = cb_normal.duplicate()
	cb_hover.bg_color = Color(0.62, 0.16, 0.20, 1.0)
	close_btn.add_theme_stylebox_override("normal", cb_normal)
	close_btn.add_theme_stylebox_override("hover", cb_hover)
	close_btn.add_theme_stylebox_override("pressed", cb_hover)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.95, 1.0))

	var close_action = func():
		AudioManager.play_card_select()
		if is_instance_valid(fs):
			var tw = fs.create_tween()
			tw.tween_property(fs, "modulate:a", 0.0, 0.15)
			tw.tween_callback(func():
				if is_instance_valid(fs):
					fs.queue_free()
				_fullscreen_heroes_panel = null
			)

	close_btn.pressed.connect(close_action)
	header_hbox.add_child(close_btn)

	# 2. Body Scroll Container
	var scroll = ScrollContainer.new()
	_heroes_gallery_scroll = scroll
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)

	var scroll_margin = MarginContainer.new()
	scroll_margin.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 32)
	scroll_margin.add_theme_constant_override("margin_right", 32)
	scroll_margin.add_theme_constant_override("margin_top", 20)
	scroll_margin.add_theme_constant_override("margin_bottom", 36)
	scroll.add_child(scroll_margin)

	var grid = GridContainer.new()
	grid.columns = 6
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 16)
	scroll_margin.add_child(grid)

	# Grayscale Shader Material for unowned heroes (Black & White)
	var gray_shader = Shader.new()
	gray_shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.72), col.a);
}
"""
	var gray_mat = ShaderMaterial.new()
	gray_mat.shader = gray_shader

	for h in all_heroes:
		var hid = int(h.get("id", 0))
		var is_owned = owned_map.get(hid, false)
		var hname = str(h.get("name", "Vô Danh"))
		var faction = str(h.get("faction", "Đại Việt"))
		var max_hp = int(h.get("maxHp", 4))
		var avatar_path = str(h.get("avatarPath", ""))

		# Card Container
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(175, 235)
		card.size_flags_horizontal = SIZE_EXPAND_FILL

		var card_style = StyleBoxFlat.new()
		if is_owned:
			card_style.bg_color = Color(0.10, 0.13, 0.19, 0.95)
			card_style.border_color = Color(0.85, 0.72, 0.32, 0.8)
			card_style.border_width_left = 1
			card_style.border_width_top = 1
			card_style.border_width_right = 1
			card_style.border_width_bottom = 1
			card_style.shadow_color = Color(0.85, 0.72, 0.32, 0.15)
			card_style.shadow_size = 4
		else:
			card_style.bg_color = Color(0.06, 0.07, 0.09, 0.95)
			card_style.border_color = Color(0.32, 0.34, 0.40, 0.45)
			card_style.border_width_left = 1
			card_style.border_width_top = 1
			card_style.border_width_right = 1
			card_style.border_width_bottom = 1
			card_style.shadow_size = 0
		card_style.corner_radius_top_left = 8
		card_style.corner_radius_top_right = 8
		card_style.corner_radius_bottom_right = 8
		card_style.corner_radius_bottom_left = 8
		card_style.content_margin_left = 8
		card_style.content_margin_right = 8
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_style)

		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		# Top row: ID and Faction
		var top_row = HBoxContainer.new()
		var id_lbl = Label.new()
		id_lbl.text = "#%02d" % hid
		id_lbl.add_theme_font_size_override("font_size", 11)
		id_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.9) if is_owned else Color(0.55, 0.58, 0.65, 0.8))
		top_row.add_child(id_lbl)

		var top_spacer = Control.new()
		top_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
		top_row.add_child(top_spacer)

		var fac_lbl = Label.new()
		fac_lbl.text = faction
		fac_lbl.add_theme_font_size_override("font_size", 10)
		fac_lbl.add_theme_color_override("font_color", Color(0.8, 0.75, 0.55, 0.8) if is_owned else Color(0.45, 0.48, 0.52, 0.7))
		top_row.add_child(fac_lbl)
		cv.add_child(top_row)

		# Portrait image
		var img_box = PanelContainer.new()
		img_box.custom_minimum_size = Vector2(0, 120)
		img_box.clip_contents = true
		var ib_style = StyleBoxFlat.new()
		ib_style.bg_color = Color(0.04, 0.05, 0.07, 0.8)
		ib_style.corner_radius_top_left = 6
		ib_style.corner_radius_top_right = 6
		ib_style.corner_radius_bottom_right = 6
		ib_style.corner_radius_bottom_left = 6
		img_box.add_theme_stylebox_override("panel", ib_style)

		var card_bg = TextureRect.new()
		card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_bg.texture = preload("res://assets/ui/hero_backgrounds/bg_hero_white.png")
		if not is_owned:
			card_bg.material = gray_mat
		img_box.add_child(card_bg)

		var img = TextureRect.new()
		img.custom_minimum_size = Vector2(0, 120)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var tex = HeroDatabase.get_avatar_texture(avatar_path)
		if tex:
			img.texture = tex
		if not is_owned:
			img.material = gray_mat
		img_box.add_child(img)
		cv.add_child(img_box)

		# Name
		var name_lbl = Label.new()
		name_lbl.text = hname
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0) if is_owned else Color(0.70, 0.72, 0.76, 0.9))
		cv.add_child(name_lbl)

		# HP Row
		var hp_lbl = Label.new()
		hp_lbl.text = "🪷 %d Máu" % max_hp
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_lbl.add_theme_font_size_override("font_size", 11)
		hp_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 0.9) if is_owned else Color(0.5, 0.55, 0.6, 0.7))
		cv.add_child(hp_lbl)

		# Status Badge Pill
		var status_panel = PanelContainer.new()
		var sp_style = StyleBoxFlat.new()
		if is_owned:
			sp_style.bg_color = Color(0.08, 0.28, 0.16, 0.85)
			sp_style.border_color = Color(0.35, 0.85, 0.55, 0.7)
		else:
			sp_style.bg_color = Color(0.12, 0.14, 0.17, 0.8)
			sp_style.border_color = Color(0.35, 0.38, 0.44, 0.5)
		sp_style.border_width_left = 1
		sp_style.border_width_top = 1
		sp_style.border_width_right = 1
		sp_style.border_width_bottom = 1
		sp_style.corner_radius_top_left = 4
		sp_style.corner_radius_top_right = 4
		sp_style.corner_radius_bottom_right = 4
		sp_style.corner_radius_bottom_left = 4
		sp_style.content_margin_left = 4
		sp_style.content_margin_right = 4
		sp_style.content_margin_top = 2
		sp_style.content_margin_bottom = 2
		status_panel.add_theme_stylebox_override("panel", sp_style)

		var status_lbl = Label.new()
		status_lbl.text = "✅ ĐÃ SỞ HỮU" if is_owned else "🔒 CHƯA SỞ HỮU"
		status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_lbl.add_theme_font_size_override("font_size", 10)
		status_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.75, 1.0) if is_owned else Color(0.65, 0.68, 0.72, 0.8))
		status_panel.add_child(status_lbl)
		cv.add_child(status_panel)

		# Clickable Button overlay
		var click_btn = Button.new()
		click_btn.set_anchors_preset(PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var captured_hero = h
		var captured_owned = is_owned
		click_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_show_hero_detail_popup(captured_hero, captured_owned, fs)
		)
		card.add_child(click_btn)

		grid.add_child(card)

	# Fade in animation
	fs.modulate.a = 0.0
	var tw = fs.create_tween()
	tw.tween_property(fs, "modulate:a", 1.0, 0.18)

# --- Hero Detail Popup (Opened from Fullscreen Gallery) ---
func _show_hero_detail_popup(hero: Dictionary, is_owned: bool, parent_layer: Control) -> void:
	if not is_instance_valid(parent_layer):
		return

	var existing = parent_layer.get_node_or_null("HeroDetailPopup")
	if is_instance_valid(existing):
		existing.queue_free()

	var popup = Control.new()
	popup.name = "HeroDetailPopup"
	popup.set_anchors_preset(PRESET_FULL_RECT)
	popup.z_index = 95
	parent_layer.add_child(popup)

	# Dim background
	var mask = ColorRect.new()
	mask.set_anchors_preset(PRESET_FULL_RECT)
	mask.color = Color(0.02, 0.03, 0.05, 0.82)
	popup.add_child(mask)

	var close_popup = func():
		AudioManager.play_card_select()
		if is_instance_valid(popup):
			var tw = popup.create_tween()
			tw.tween_property(popup, "modulate:a", 0.0, 0.12)
			tw.tween_callback(popup.queue_free)

	mask.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close_popup.call()
	)

	# Center Modal Box
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(820, 580)
	box.set_anchors_preset(PRESET_CENTER)
	box.grow_horizontal = GROW_DIRECTION_BOTH
	box.grow_vertical = GROW_DIRECTION_BOTH

	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	box_style.border_color = Color(0.85, 0.72, 0.32, 0.9)
	box_style.border_width_left = 2
	box_style.border_width_top = 2
	box_style.border_width_right = 2
	box_style.border_width_bottom = 2
	box_style.corner_radius_top_left = 12
	box_style.corner_radius_top_right = 12
	box_style.corner_radius_bottom_right = 12
	box_style.corner_radius_bottom_left = 12
	box_style.shadow_color = Color(0, 0, 0, 0.6)
	box_style.shadow_size = 16
	box_style.content_margin_left = 20
	box_style.content_margin_right = 20
	box_style.content_margin_top = 16
	box_style.content_margin_bottom = 16
	box.add_theme_stylebox_override("panel", box_style)
	popup.add_child(box)

	var bv = VBoxContainer.new()
	bv.add_theme_constant_override("separation", 12)
	box.add_child(bv)

	# 1. Header
	var hdr = HBoxContainer.new()
	var h_title = Label.new()
	h_title.text = "📜 CHI TIẾT DANH TƯỚNG #%d" % int(hero.get("id", 0))
	h_title.add_theme_font_size_override("font_size", 20)
	h_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	hdr.add_child(h_title)

	var h_spacer = Control.new()
	h_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hdr.add_child(h_spacer)

	var h_close = Button.new()
	h_close.text = "✕"
	h_close.custom_minimum_size = Vector2(36, 36)
	h_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	h_close.pressed.connect(close_popup)
	hdr.add_child(h_close)
	bv.add_child(hdr)

	# 2. Main Content HBox (Left Column: Portrait & Stats, Right Column: Skills)
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	content_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 18)
	bv.add_child(content_hbox)

	# --- LEFT COLUMN ---
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(250, 0)
	left_col.add_theme_constant_override("separation", 8)
	content_hbox.add_child(left_col)

	var portrait_box = PanelContainer.new()
	portrait_box.custom_minimum_size = Vector2(250, 260)
	portrait_box.clip_contents = true
	var pb_style = StyleBoxFlat.new()
	pb_style.bg_color = Color(0.05, 0.06, 0.09, 0.9)
	pb_style.border_color = Color(0.85, 0.72, 0.32, 0.6) if is_owned else Color(0.35, 0.38, 0.45, 0.5)
	pb_style.border_width_left = 1
	pb_style.border_width_top = 1
	pb_style.border_width_right = 1
	pb_style.border_width_bottom = 1
	pb_style.corner_radius_top_left = 8
	pb_style.corner_radius_top_right = 8
	pb_style.corner_radius_bottom_right = 8
	pb_style.corner_radius_bottom_left = 8
	portrait_box.add_theme_stylebox_override("panel", pb_style)

	var popup_bg = TextureRect.new()
	popup_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	popup_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	popup_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_bg.texture = preload("res://assets/ui/hero_backgrounds/bg_hero_white.png")
	if not is_owned:
		var gray_shader_bg = Shader.new()
		gray_shader_bg.code = """
shader_type canvas_item;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.75), col.a);
}
"""
		var gray_mat_bg = ShaderMaterial.new()
		gray_mat_bg.shader = gray_shader_bg
		popup_bg.material = gray_mat_bg
	portrait_box.add_child(popup_bg)

	var big_img = TextureRect.new()
	big_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var tex = HeroDatabase.get_avatar_texture(str(hero.get("avatarPath", "")))
	if tex:
		big_img.texture = tex
	if not is_owned:
		var gray_shader = Shader.new()
		gray_shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray * 0.75), col.a);
}
"""
		var gray_mat = ShaderMaterial.new()
		gray_mat.shader = gray_shader
		big_img.material = gray_mat
	portrait_box.add_child(big_img)
	left_col.add_child(portrait_box)

	var name_lbl = Label.new()
	name_lbl.text = str(hero.get("name", "Vô Danh"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0) if is_owned else Color(0.75, 0.78, 0.82, 1.0))
	left_col.add_child(name_lbl)

	var faction_lbl = Label.new()
	faction_lbl.text = "Triều đại: %s" % str(hero.get("faction", "Đại Việt"))
	faction_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	faction_lbl.add_theme_font_size_override("font_size", 13)
	faction_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.8))
	left_col.add_child(faction_lbl)

	# Lotus Blossoms
	var max_hp = int(hero.get("maxHp", 4))
	var lotus_str = ""
	for i in range(max_hp):
		lotus_str += "🪷 "
	var hp_icons_lbl = Label.new()
	hp_icons_lbl.text = lotus_str.strip_edges()
	hp_icons_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_icons_lbl.add_theme_font_size_override("font_size", 16)
	left_col.add_child(hp_icons_lbl)

	var hp_text_lbl = Label.new()
	hp_text_lbl.text = "%d Máu tối đa" % max_hp
	hp_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text_lbl.add_theme_font_size_override("font_size", 12)
	hp_text_lbl.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6, 0.9))
	left_col.add_child(hp_text_lbl)

	# Ownership Pill
	var own_panel = PanelContainer.new()
	var op_style = StyleBoxFlat.new()
	if is_owned:
		op_style.bg_color = Color(0.08, 0.28, 0.16, 0.95)
		op_style.border_color = Color(0.35, 0.88, 0.58, 0.9)
	else:
		op_style.bg_color = Color(0.16, 0.18, 0.22, 0.95)
		op_style.border_color = Color(0.45, 0.48, 0.55, 0.6)
	op_style.border_width_left = 1
	op_style.border_width_top = 1
	op_style.border_width_right = 1
	op_style.border_width_bottom = 1
	op_style.corner_radius_top_left = 6
	op_style.corner_radius_top_right = 6
	op_style.corner_radius_bottom_right = 6
	op_style.corner_radius_bottom_left = 6
	op_style.content_margin_top = 4
	op_style.content_margin_bottom = 4
	own_panel.add_theme_stylebox_override("panel", op_style)

	var own_lbl = Label.new()
	own_lbl.text = "✅ ĐÃ SỞ HỮU" if is_owned else "🔒 CHƯA SỞ HỮU"
	own_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	own_lbl.add_theme_font_size_override("font_size", 11)
	own_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.8, 1.0) if is_owned else Color(0.72, 0.75, 0.8, 0.85))
	own_panel.add_child(own_lbl)
	left_col.add_child(own_panel)

	# --- RIGHT COLUMN (Skills List) ---
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = SIZE_EXPAND_FILL
	right_col.size_flags_vertical = SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 10)
	content_hbox.add_child(right_col)

	var skill_sec_title = Label.new()
	skill_sec_title.text = "⚔️ KỸ NĂNG VÕ TƯỚNG"
	skill_sec_title.add_theme_font_size_override("font_size", 16)
	skill_sec_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	right_col.add_child(skill_sec_title)

	var skill_scroll = ScrollContainer.new()
	skill_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	skill_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	skill_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_col.add_child(skill_scroll)

	var skill_list = VBoxContainer.new()
	skill_list.size_flags_horizontal = SIZE_EXPAND_FILL
	skill_list.add_theme_constant_override("separation", 10)
	skill_scroll.add_child(skill_list)

	var skills = hero.get("skills", [])
	if skills is Array and not skills.is_empty():
		for sk in skills:
			if not (sk is Dictionary):
				continue
			var sk_name = str(sk.get("name", "Kỹ năng"))
			var sk_desc = str(sk.get("desc", ""))

			var sk_card = PanelContainer.new()
			sk_card.size_flags_horizontal = SIZE_EXPAND_FILL
			var sc_style = StyleBoxFlat.new()
			sc_style.bg_color = Color(0.06, 0.07, 0.11, 0.95)
			sc_style.border_color = Color(0.85, 0.72, 0.32, 0.6)
			sc_style.border_width_left = 2
			sc_style.border_width_top = 1
			sc_style.border_width_right = 1
			sc_style.border_width_bottom = 1
			sc_style.corner_radius_top_left = 8
			sc_style.corner_radius_top_right = 8
			sc_style.corner_radius_bottom_right = 8
			sc_style.corner_radius_bottom_left = 8
			sc_style.content_margin_left = 14
			sc_style.content_margin_right = 14
			sc_style.content_margin_top = 10
			sc_style.content_margin_bottom = 10
			sk_card.add_theme_stylebox_override("panel", sc_style)

			var sk_vbox = VBoxContainer.new()
			sk_vbox.add_theme_constant_override("separation", 6)
			sk_card.add_child(sk_vbox)

			var sk_hdr = HBoxContainer.new()
			var name_tag = Label.new()
			name_tag.text = "❖  " + sk_name
			name_tag.add_theme_font_size_override("font_size", 15)
			name_tag.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
			sk_hdr.add_child(name_tag)

			var sk_spacer = Control.new()
			sk_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
			sk_hdr.add_child(sk_spacer)

			# Skill type pill
			var lower_desc = (sk_name + " " + sk_desc).to_lower()
			var type_text = "BỊ ĐỘNG"
			if "bật:" in lower_desc or "trong giai đoạn" in lower_desc or "một lần mỗi lượt" in lower_desc or "có thể dùng" in lower_desc or "bỏ 1 lá" in lower_desc or "đổi 2 lá" in lower_desc:
				type_text = "CHỦ ĐỘNG"
			elif "khi rơi vào" in lower_desc or "khi mất máu" in lower_desc or "khi bị" in lower_desc or "sau khi" in lower_desc or "khi đánh ra" in lower_desc or "khi bạn dùng" in lower_desc or "khi bạn gây" in lower_desc or "khi người khác" in lower_desc:
				type_text = "KÍCH HOẠT"

			var type_lbl = Label.new()
			type_lbl.text = "〔 %s 〕" % type_text
			type_lbl.add_theme_font_size_override("font_size", 11)
			type_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0, 0.9))
			sk_hdr.add_child(type_lbl)
			sk_vbox.add_child(sk_hdr)

			var desc_lbl = Label.new()
			desc_lbl.text = sk_desc
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
			desc_lbl.add_theme_font_size_override("font_size", 13)
			desc_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95, 0.95))
			sk_vbox.add_child(desc_lbl)

			skill_list.add_child(sk_card)

	# 3. Footer
	var ftr = HBoxContainer.new()
	var ftr_spacer = Control.new()
	ftr_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	ftr.add_child(ftr_spacer)

	var ftr_close = Button.new()
	ftr_close.text = "ĐÓNG"
	ftr_close.custom_minimum_size = Vector2(100, 36)
	ftr_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ftr_close.pressed.connect(close_popup)
	ftr.add_child(ftr_close)
	bv.add_child(ftr)

	# Pop animation
	box.scale = Vector2(0.92, 0.92)
	box.pivot_offset = Vector2(410, 290)
	popup.modulate.a = 0.0
	var tw = popup.create_tween().set_parallel(true)
	tw.tween_property(popup, "modulate:a", 1.0, 0.16)
	tw.tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _build_heroes_content() -> Control:
	call_deferred("_show_fullscreen_heroes")
	var dummy = Control.new()
	dummy.custom_minimum_size = Vector2(1, 1)
	return dummy

# --- QUÀ 7 NGÀY ĐIỂM DANH ---
func _build_7day_rewards_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 14)

	var desc_lbl = Label.new()
	desc_lbl.text = "Triều đình ban thưởng mỗi ngày đăng nhập! Nhận Vé Quay Tướng để hiệu triệu 28 Hào Kiệt Đại Việt tại Thần Điện."
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	container.add_child(desc_lbl)

	var claimed_count: int = AuthManager.checkin_7day_claimed.size() if AuthManager else 0
	var can_claim_today: bool = AuthManager.can_claim_checkin_today() if AuthManager else false
	var next_day: int = AuthManager.get_next_checkin_day() if AuthManager else 1

	var status_panel = PanelContainer.new()
	var sp_style = StyleBoxFlat.new()
	sp_style.bg_color = Color(0.12, 0.14, 0.20, 0.95)
	sp_style.border_width_left = 2
	sp_style.border_color = COLOR_GOLD_PRIMARY
	sp_style.corner_radius_top_left = 6
	sp_style.corner_radius_bottom_left = 6
	sp_style.content_margin_left = 12
	sp_style.content_margin_right = 12
	sp_style.content_margin_top = 8
	sp_style.content_margin_bottom = 8
	status_panel.add_theme_stylebox_override("panel", sp_style)

	var status_hbox = HBoxContainer.new()
	var prog_lbl = Label.new()
	prog_lbl.text = "⭐ Tiến trình: %d/7 Ngày" % claimed_count
	prog_lbl.add_theme_font_size_override("font_size", 13)
	prog_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	status_hbox.add_child(prog_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_hbox.add_child(spacer)

	var state_lbl = Label.new()
	if claimed_count >= 7:
		state_lbl.text = "👑 ĐÃ HOÀN THÀNH 7 NGÀY ĐIỂM DANH"
		state_lbl.add_theme_color_override("font_color", Color(0.2, 0.85, 0.3, 1.0))
	elif can_claim_today:
		state_lbl.text = "⚡ CÓ THỂ NHẬN QUÀ NGÀY %d!" % next_day
		state_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		state_lbl.text = "⏰ ĐÃ ĐIỂM DANH HÔM NAY (HẸN GẶP LẠI NGÀY MAI)"
		state_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8, 1.0))
	state_lbl.add_theme_font_size_override("font_size", 12)
	status_hbox.add_child(state_lbl)

	status_panel.add_child(status_hbox)
	container.add_child(status_panel)

	# Grid: Ngày 1-4 hàng trên, Ngày 5-7 hàng dưới
	var grid_top = HBoxContainer.new()
	grid_top.add_theme_constant_override("separation", 10)
	container.add_child(grid_top)

	var grid_bot = HBoxContainer.new()
	grid_bot.add_theme_constant_override("separation", 10)
	container.add_child(grid_bot)

	var rewards_list = AuthManager.SEVEN_DAY_REWARDS if AuthManager else [
		{"day": 1, "tickets": 1, "silver": 1000},
		{"day": 2, "tickets": 2, "silver": 2000},
		{"day": 3, "tickets": 3, "silver": 3000},
		{"day": 4, "tickets": 4, "silver": 4000},
		{"day": 5, "tickets": 5, "silver": 5000},
		{"day": 6, "tickets": 6, "silver": 6000},
		{"day": 7, "tickets": 7, "silver": 7000}
	]

	for day_data in rewards_list:
		var d_num: int = int(day_data["day"])
		var tickets: int = int(day_data["tickets"])
		var silver: int = int(day_data["silver"])
		var is_claimed: bool = AuthManager.is_checkin_day_claimed(d_num) if AuthManager else false
		var is_claimable: bool = (d_num == next_day and can_claim_today)

		var card = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 130)

		var cs = StyleBoxFlat.new()
		if is_claimed:
			cs.bg_color = Color(0.10, 0.12, 0.16, 0.95)
			cs.border_color = Color(0.3, 0.5, 0.4, 0.6)
			cs.border_width_left = 1
			cs.border_width_right = 1
			cs.border_width_top = 1
			cs.border_width_bottom = 1
		elif is_claimable:
			cs.bg_color = Color(0.20, 0.12, 0.08, 0.98)
			cs.border_color = COLOR_GOLD_PRIMARY
			cs.border_width_left = 2
			cs.border_width_right = 2
			cs.border_width_top = 2
			cs.border_width_bottom = 2
			cs.shadow_color = Color(0.9, 0.6, 0.1, 0.4)
			cs.shadow_size = 8
		else:
			cs.bg_color = Color(0.08, 0.09, 0.13, 0.95)
			cs.border_color = Color(0.25, 0.28, 0.35, 0.5)
			cs.border_width_left = 1
			cs.border_width_right = 1
			cs.border_width_top = 1
			cs.border_width_bottom = 1

		cs.corner_radius_top_left = 8
		cs.corner_radius_top_right = 8
		cs.corner_radius_bottom_right = 8
		cs.corner_radius_bottom_left = 8
		cs.content_margin_left = 10
		cs.content_margin_right = 10
		cs.content_margin_top = 10
		cs.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", cs)

		var card_vbox = VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 6)

		# Day Header
		var day_hdr = Label.new()
		if d_num == 7:
			day_hdr.text = "👑 NGÀY 7"
			day_hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		else:
			day_hdr.text = "NGÀY %d" % d_num
			day_hdr.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY if not is_claimed else Color(0.6, 0.6, 0.6, 1.0))
		day_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_hdr.add_theme_font_size_override("font_size", 13)
		card_vbox.add_child(day_hdr)

		# Reward line
		var reward_hbox = HBoxContainer.new()
		reward_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		reward_hbox.add_theme_constant_override("separation", 8)

		var t_lbl = Label.new()
		t_lbl.text = "📜 %d Vé" % tickets
		t_lbl.add_theme_font_size_override("font_size", 13)
		t_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35, 1.0))
		reward_hbox.add_child(t_lbl)

		var s_lbl = Label.new()
		s_lbl.text = "🥈 +%s" % _format_number(silver)
		s_lbl.add_theme_font_size_override("font_size", 13)
		s_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45, 1.0))
		reward_hbox.add_child(s_lbl)
		card_vbox.add_child(reward_hbox)

		# Claim Button
		var claim_btn = Button.new()
		claim_btn.custom_minimum_size = Vector2(0, 32)
		if is_claimed:
			claim_btn.text = "✓ ĐÃ NHẬN"
			claim_btn.disabled = true
			_style_white_gold_button(claim_btn, 6, 1, Vector2.ZERO)
		elif is_claimable:
			claim_btn.text = "🎁 NHẬN NGAY"
			_style_bronze_drum_cta(claim_btn)
			claim_btn.pressed.connect(func():
				if AuthManager:
					AuthManager.claim_7day_reward(d_num)
				AudioManager.play_victory()
				_refresh_user_profile_ui()
				_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
			)
		else:
			claim_btn.text = "🔒 CHƯA MỞ"
			claim_btn.disabled = true
			_style_white_gold_button(claim_btn, 6, 1, Vector2.ZERO)
		card_vbox.add_child(claim_btn)

		card.add_child(card_vbox)

		if d_num <= 4:
			grid_top.add_child(card)
		else:
			grid_bot.add_child(card)

	# Developer / Tester Helper Bar
	if AuthManager and AuthManager.is_dev_machine():
		var dev_bar = HBoxContainer.new()
		dev_bar.alignment = BoxContainer.ALIGNMENT_CENTER
		dev_bar.add_theme_constant_override("separation", 10)

		var test_lbl = Label.new()
		test_lbl.text = "⚡ Tester Tools:"
		test_lbl.add_theme_font_size_override("font_size", 11)
		test_lbl.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1.0))
		dev_bar.add_child(test_lbl)

		var btn_adv = Button.new()
		btn_adv.text = "⏩ Mở ngày tiếp theo"
		btn_adv.add_theme_font_size_override("font_size", 11)
		_style_white_gold_button(btn_adv, 4, 1, Vector2.ZERO)
		btn_adv.pressed.connect(func():
			AuthManager.dev_advance_checkin_day()
			_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
		)
		dev_bar.add_child(btn_adv)

		var btn_rst = Button.new()
		btn_rst.text = "🔄 Reset chu kỳ 7 ngày"
		btn_rst.add_theme_font_size_override("font_size", 11)
		_style_white_gold_button(btn_rst, 4, 1, Vector2.ZERO)
		btn_rst.pressed.connect(func():
			AuthManager.dev_reset_7day_checkin()
			_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
		)
		dev_bar.add_child(btn_rst)

		var btn_tickets = Button.new()
		btn_tickets.text = "📜 +10 Vé Quay"
		btn_tickets.add_theme_font_size_override("font_size", 11)
		_style_white_gold_button(btn_tickets, 4, 1, Vector2.ZERO)
		btn_tickets.pressed.connect(func():
			AuthManager.add_hero_tickets(10)
			_refresh_user_profile_ui()
			_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
		)
		dev_bar.add_child(btn_tickets)

		container.add_child(dev_bar)

	return container

# --- THẦN ĐIỆN (SANCTUARY / GACHA) BUTTON STYLES ---
func _style_than_dien_summon_1_btn(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.70, 0.12, 0.08, 0.96) # Royal lacquer scarlet
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.86, 0.35, 1.0) # Bright gold
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.shadow_color = Color(0.68, 0.10, 0.05, 0.55)
	normal.shadow_size = 12
	normal.shadow_offset = Vector2(0, 4)

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.82, 0.16, 0.10, 1.0)
	hover.border_color = Color(1.0, 0.95, 0.55, 1.0)
	hover.shadow_size = 18
	hover.shadow_offset = Vector2(0, 5)

	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.55, 0.08, 0.05, 1.0)
	pressed.shadow_size = 4
	pressed.shadow_offset = Vector2(0, 2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

func _style_than_dien_summon_5_btn(btn: Button) -> void:
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.82, 0.54, 0.08, 0.96) # Imperial radiant gold
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.95, 0.55, 1.0) # Bright celestial gold
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.shadow_color = Color(0.92, 0.65, 0.10, 0.55)
	normal.shadow_size = 14
	normal.shadow_offset = Vector2(0, 4)

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.92, 0.62, 0.10, 1.0)
	hover.border_color = Color(1.0, 1.0, 0.75, 1.0)
	hover.shadow_size = 20
	hover.shadow_offset = Vector2(0, 5)

	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.65, 0.40, 0.05, 1.0)
	pressed.shadow_size = 4
	pressed.shadow_offset = Vector2(0, 2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)

# --- THẦN ĐIỆN (SANCTUARY / GACHA) ---
func _show_fullscreen_than_dien() -> void:
	if is_instance_valid(_fullscreen_than_dien_panel):
		_fullscreen_than_dien_panel.queue_free()
		_fullscreen_than_dien_panel = null

	var fs = Control.new()
	fs.name = "FullscreenThanDienPanel"
	fs.set_anchors_preset(PRESET_FULL_RECT)
	fs.z_index = 85
	_fullscreen_than_dien_panel = fs
	add_child(fs)

	# 1. Dark royal backdrop with temple atmosphere
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.045, 0.075, 0.985)
	fs.add_child(bg)

	var bg_img = TextureRect.new()
	bg_img.set_anchors_preset(PRESET_FULL_RECT)
	bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_img.modulate = Color(0.4, 0.4, 0.5, 0.22)
	var t_bg = load("res://assets/ui/home_background.png")
	if t_bg: bg_img.texture = t_bg
	fs.add_child(bg_img)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0)
	fs.add_child(main_vbox)

	# 2. Top Header Bar
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 64)
	var hp_style = StyleBoxFlat.new()
	hp_style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	hp_style.border_width_bottom = 2
	hp_style.border_color = Color(0.85, 0.72, 0.32, 0.5)
	hp_style.content_margin_left = 28
	hp_style.content_margin_right = 28
	hp_style.content_margin_top = 8
	hp_style.content_margin_bottom = 8
	header_panel.add_theme_stylebox_override("panel", hp_style)
	main_vbox.add_child(header_panel)

	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header_hbox)

	var title_vbox = VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 2)
	header_hbox.add_child(title_vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⛩️ THẦN ĐIỆN HIỆU TRIỆU"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	title_vbox.add_child(title_lbl)

	var sub_title = Label.new()
	sub_title.text = "Hiệu triệu 28 Hào Kiệt Đại Việt (Tướng 1 ➔ 28) • Trùng tướng nhận 1,000 Bạc"
	sub_title.add_theme_font_size_override("font_size", 12)
	sub_title.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	title_vbox.add_child(sub_title)

	var h_spacer = Control.new()
	h_spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	header_hbox.add_child(h_spacer)

	# Right Utilities in Header: Tickets, Silver, 7-Day gifts button, Close button
	var ticket_pill = PanelContainer.new()
	ticket_pill.custom_minimum_size = Vector2(140, 38)
	var tps = StyleBoxFlat.new()
	tps.bg_color = Color(0.18, 0.08, 0.08, 0.95)
	tps.border_color = Color(0.95, 0.40, 0.25, 0.85)
	tps.border_width_left = 1
	tps.border_width_right = 1
	tps.border_width_top = 1
	tps.border_width_bottom = 1
	tps.corner_radius_top_left = 8
	tps.corner_radius_top_right = 8
	tps.corner_radius_bottom_right = 8
	tps.corner_radius_bottom_left = 8
	tps.content_margin_left = 10
	tps.content_margin_right = 10
	ticket_pill.add_theme_stylebox_override("panel", tps)

	var tp_lbl = Label.new()
	tp_lbl.text = "📜 %d Vé Hiệu Triệu" % (AuthManager.current_hero_tickets if AuthManager else 0)
	tp_lbl.add_theme_font_size_override("font_size", 13)
	tp_lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.45, 1.0))
	ticket_pill.add_child(tp_lbl)
	header_hbox.add_child(ticket_pill)

	var silver_pill = PanelContainer.new()
	silver_pill.custom_minimum_size = Vector2(140, 38)
	var sps = StyleBoxFlat.new()
	sps.bg_color = Color(0.10, 0.14, 0.20, 0.95)
	sps.border_color = Color(0.40, 0.70, 0.90, 0.85)
	sps.border_width_left = 1
	sps.border_width_right = 1
	sps.border_width_top = 1
	sps.border_width_bottom = 1
	sps.corner_radius_top_left = 8
	sps.corner_radius_top_right = 8
	sps.corner_radius_bottom_right = 8
	sps.corner_radius_bottom_left = 8
	sps.content_margin_left = 10
	sps.content_margin_right = 10
	silver_pill.add_theme_stylebox_override("panel", sps)

	var sp_lbl = Label.new()
	sp_lbl.text = "🥈 %s Bạc" % _format_number(AuthManager.current_silver if AuthManager else 0)
	sp_lbl.add_theme_font_size_override("font_size", 13)
	sp_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.50, 1.0))
	silver_pill.add_child(sp_lbl)
	header_hbox.add_child(silver_pill)

	var btn_7d = Button.new()
	btn_7d.custom_minimum_size = Vector2(130, 38)
	btn_7d.text = "🎁 Quà 7 Ngày"
	_style_white_gold_button(btn_7d, 6, 2, Vector2(0, 1))
	btn_7d.pressed.connect(func():
		AudioManager.play_card_select()
		_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
	)
	header_hbox.add_child(btn_7d)

	var close_btn = Button.new()
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.text = "✖"
	close_btn.add_theme_font_size_override("font_size", 18)
	_style_white_gold_button(close_btn, 8, 3, Vector2(0, 2))
	close_btn.pressed.connect(func():
		AudioManager.play_card_select()
		if is_instance_valid(_fullscreen_than_dien_panel):
			_fullscreen_than_dien_panel.queue_free()
			_fullscreen_than_dien_panel = null
	)
	header_hbox.add_child(close_btn)

	# 3. Center Altar Main Stage (Balanced Two-Wing Temple Layout)
	var stage_margin = MarginContainer.new()
	stage_margin.size_flags_vertical = SIZE_EXPAND_FILL
	stage_margin.size_flags_horizontal = SIZE_EXPAND_FILL
	stage_margin.add_theme_constant_override("margin_left", 28)
	stage_margin.add_theme_constant_override("margin_right", 28)
	stage_margin.add_theme_constant_override("margin_top", 10)
	stage_margin.add_theme_constant_override("margin_bottom", 10)
	main_vbox.add_child(stage_margin)

	var stage_hbox = HBoxContainer.new()
	stage_hbox.set_anchors_preset(PRESET_FULL_RECT)
	stage_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	stage_hbox.size_flags_vertical = SIZE_EXPAND_FILL
	stage_hbox.add_theme_constant_override("separation", 20)
	stage_margin.add_child(stage_hbox)

	# --- WING 1: FEATURED HERO SPOTLIGHT ALTAR (LEFT, ~460px) ---
	var featured_ids = [3, 9, 22, 1, 4, 5, 10, 18]
	if not (_than_dien_selected_hero_id in featured_ids):
		_than_dien_selected_hero_id = 3

	var current_spotlight_hero = HeroDatabase.get_hero(_than_dien_selected_hero_id) if HeroDatabase else {}
	var is_spotlight_owned = HeroDatabase.is_hero_owned(_than_dien_selected_hero_id) if HeroDatabase else false

	var spotlight_panel = PanelContainer.new()
	spotlight_panel.custom_minimum_size = Vector2(460, 0)
	spotlight_panel.size_flags_vertical = SIZE_EXPAND_FILL

	var sp_style = StyleBoxFlat.new()
	sp_style.bg_color = Color(0.07, 0.08, 0.12, 0.96)
	sp_style.border_width_left = 2
	sp_style.border_width_top = 2
	sp_style.border_width_right = 2
	sp_style.border_width_bottom = 2
	sp_style.border_color = Color(0.85, 0.72, 0.32, 0.85)
	sp_style.corner_radius_top_left = 12
	sp_style.corner_radius_top_right = 12
	sp_style.corner_radius_bottom_right = 12
	sp_style.corner_radius_bottom_left = 12
	sp_style.shadow_color = Color(0, 0, 0, 0.55)
	sp_style.shadow_size = 12
	sp_style.content_margin_left = 14
	sp_style.content_margin_right = 14
	sp_style.content_margin_top = 10
	sp_style.content_margin_bottom = 10
	spotlight_panel.add_theme_stylebox_override("panel", sp_style)
	stage_hbox.add_child(spotlight_panel)

	var sp_vbox = VBoxContainer.new()
	sp_vbox.set_anchors_preset(PRESET_FULL_RECT)
	sp_vbox.add_theme_constant_override("separation", 6)
	spotlight_panel.add_child(sp_vbox)

	# Spotlight Header row
	var sp_top_row = HBoxContainer.new()
	sp_top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_vbox.add_child(sp_top_row)

	var sp_faction_pill = PanelContainer.new()
	var sfp_style = StyleBoxFlat.new()
	var faction_str = str(current_spotlight_hero.get("faction", "Đại Việt"))
	sfp_style.bg_color = HeroDatabase.get_faction_color(faction_str) if HeroDatabase else Color(0.2, 0.6, 0.4)
	sfp_style.bg_color.a = 0.25
	sfp_style.border_color = HeroDatabase.get_faction_color(faction_str) if HeroDatabase else Color(0.4, 0.9, 0.6)
	sfp_style.border_width_left = 1
	sfp_style.border_width_top = 1
	sfp_style.border_width_right = 1
	sfp_style.border_width_bottom = 1
	sfp_style.corner_radius_top_left = 4
	sfp_style.corner_radius_top_right = 4
	sfp_style.corner_radius_bottom_right = 4
	sfp_style.corner_radius_bottom_left = 4
	sfp_style.content_margin_left = 6
	sfp_style.content_margin_right = 6
	sfp_style.content_margin_top = 2
	sfp_style.content_margin_bottom = 2
	sp_faction_pill.add_theme_stylebox_override("panel", sfp_style)

	var sp_fac_lbl = Label.new()
	sp_fac_lbl.text = "〔 %s 〕" % faction_str
	sp_fac_lbl.add_theme_font_size_override("font_size", 11)
	sp_fac_lbl.add_theme_color_override("font_color", HeroDatabase.get_faction_color(faction_str) if HeroDatabase else Color.WHITE)
	sp_faction_pill.add_child(sp_fac_lbl)
	sp_top_row.add_child(sp_faction_pill)

	var sp_title_lbl = Label.new()
	sp_title_lbl.text = "⭐ DANH TƯỚNG TIÊU BIỂU ⭐"
	sp_title_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	sp_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_title_lbl.add_theme_font_size_override("font_size", 12)
	sp_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	sp_top_row.add_child(sp_title_lbl)

	var sp_id_lbl = Label.new()
	sp_id_lbl.text = "#%02d" % _than_dien_selected_hero_id
	sp_id_lbl.add_theme_font_size_override("font_size", 12)
	sp_id_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	sp_top_row.add_child(sp_id_lbl)

	# Spotlight Visual Center Area (Rotating Lotus Halo + Hero Transparent Art + Navigation Arrows)
	var sp_visual_ctrl = Control.new()
	sp_visual_ctrl.custom_minimum_size = Vector2(0, 245)
	sp_visual_ctrl.size_flags_vertical = SIZE_EXPAND_FILL
	sp_vbox.add_child(sp_visual_ctrl)

	# Rotating Halo in background of portrait
	var sp_halo = TextureRect.new()
	sp_halo.custom_minimum_size = Vector2(250, 250)
	sp_halo.size = Vector2(250, 250)
	sp_halo.set_anchors_preset(PRESET_CENTER)
	sp_halo.pivot_offset = Vector2(125, 125)
	sp_halo.grow_horizontal = GROW_DIRECTION_BOTH
	sp_halo.grow_vertical = GROW_DIRECTION_BOTH
	sp_halo.modulate = Color(1.0, 0.85, 0.3, 0.26)
	sp_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp_halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var h_tex = load("res://assets/ui/lotus_halo.png")
	if h_tex: sp_halo.texture = h_tex
	sp_visual_ctrl.add_child(sp_halo)

	var sp_halo_tw = sp_visual_ctrl.create_tween().set_loops()
	sp_halo_tw.tween_property(sp_halo, "rotation", TAU, 22.0).from(0.0)

	# Hero Transparent Texture
	var sp_hero_img = TextureRect.new()
	sp_hero_img.set_anchors_preset(PRESET_FULL_RECT)
	sp_hero_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sp_hero_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var sp_avatar_path = str(current_spotlight_hero.get("avatarPath", ""))
	var sp_slug = str(current_spotlight_hero.get("slug", ""))
	var sp_hero_tex: Texture2D = null
	if HeroDatabase and sp_avatar_path != "":
		sp_hero_tex = HeroDatabase.get_avatar_texture(sp_avatar_path)
	if not sp_hero_tex and sp_slug != "":
		var p1 = "res://assets/heroes_transparent/%s.png" % sp_slug
		if ResourceLoader.exists(p1):
			sp_hero_tex = load(p1)
	if not sp_hero_tex and ResourceLoader.exists("res://assets/ui/game_avatar.png"):
		sp_hero_tex = load("res://assets/ui/game_avatar.png")
	if sp_hero_tex:
		sp_hero_img.texture = sp_hero_tex
	sp_visual_ctrl.add_child(sp_hero_img)

	# Left/Right navigation arrows to browse featured heroes
	var btn_prev_hero = Button.new()
	btn_prev_hero.text = "◀"
	btn_prev_hero.custom_minimum_size = Vector2(34, 52)
	btn_prev_hero.set_anchors_preset(PRESET_CENTER_LEFT)
	btn_prev_hero.grow_vertical = GROW_DIRECTION_BOTH
	btn_prev_hero.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_white_gold_button(btn_prev_hero, 6, 2, Vector2.ZERO)
	btn_prev_hero.pressed.connect(func():
		AudioManager.play_card_select()
		var curr_idx = featured_ids.find(_than_dien_selected_hero_id)
		var next_idx = (curr_idx - 1 + featured_ids.size()) % featured_ids.size()
		_than_dien_selected_hero_id = featured_ids[next_idx]
		_show_fullscreen_than_dien()
	)
	sp_visual_ctrl.add_child(btn_prev_hero)

	var btn_next_hero = Button.new()
	btn_next_hero.text = "▶"
	btn_next_hero.custom_minimum_size = Vector2(34, 52)
	btn_next_hero.set_anchors_preset(PRESET_CENTER_RIGHT)
	btn_next_hero.grow_vertical = GROW_DIRECTION_BOTH
	btn_next_hero.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_white_gold_button(btn_next_hero, 6, 2, Vector2.ZERO)
	btn_next_hero.pressed.connect(func():
		AudioManager.play_card_select()
		var curr_idx = featured_ids.find(_than_dien_selected_hero_id)
		var next_idx = (curr_idx + 1) % featured_ids.size()
		_than_dien_selected_hero_id = featured_ids[next_idx]
		_show_fullscreen_than_dien()
	)
	sp_visual_ctrl.add_child(btn_next_hero)

	# Hero Name & Lotus HP Row
	var sp_name_lbl = Label.new()
	sp_name_lbl.text = str(current_spotlight_hero.get("name", "Hào Kiệt"))
	sp_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_name_lbl.add_theme_font_size_override("font_size", 20)
	sp_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
	sp_vbox.add_child(sp_name_lbl)

	var sp_hp = int(current_spotlight_hero.get("maxHp", 4))
	var lotus_text = ""
	for i in range(sp_hp):
		lotus_text += "🪷 "
	var sp_hp_lbl = Label.new()
	sp_hp_lbl.text = "%s (%d Máu Tối Đa)" % [lotus_text.strip_edges(), sp_hp]
	sp_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_hp_lbl.add_theme_font_size_override("font_size", 12)
	sp_hp_lbl.add_theme_color_override("font_color", Color(0.4, 0.92, 0.60, 0.95))
	sp_vbox.add_child(sp_hp_lbl)

	# Hero Skill Details Card
	var sp_skills = current_spotlight_hero.get("skills", [])
	var sp_sk_name = "Võ Công"
	var sp_sk_desc = "Hiệu triệu danh tướng để kích hoạt thần lực trên chiến trường."
	if sp_skills is Array and not sp_skills.is_empty() and sp_skills[0] is Dictionary:
		sp_sk_name = str(sp_skills[0].get("name", "Võ Công"))
		sp_sk_desc = str(sp_skills[0].get("desc", ""))

	var sp_skill_card = PanelContainer.new()
	var spsc_style = StyleBoxFlat.new()
	spsc_style.bg_color = Color(0.05, 0.06, 0.09, 0.92)
	spsc_style.border_color = Color(0.85, 0.72, 0.32, 0.5)
	spsc_style.border_width_left = 1
	spsc_style.border_width_top = 1
	spsc_style.border_width_right = 1
	spsc_style.border_width_bottom = 1
	spsc_style.corner_radius_top_left = 6
	spsc_style.corner_radius_top_right = 6
	spsc_style.corner_radius_bottom_right = 6
	spsc_style.corner_radius_bottom_left = 6
	spsc_style.content_margin_left = 8
	spsc_style.content_margin_right = 8
	spsc_style.content_margin_top = 6
	spsc_style.content_margin_bottom = 6
	sp_skill_card.add_theme_stylebox_override("panel", spsc_style)

	var sp_sk_vbox = VBoxContainer.new()
	sp_sk_vbox.add_theme_constant_override("separation", 2)
	sp_skill_card.add_child(sp_sk_vbox)

	var sp_sk_title = Label.new()
	sp_sk_title.text = "❖ %s" % sp_sk_name
	sp_sk_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_sk_title.add_theme_font_size_override("font_size", 13)
	sp_sk_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	sp_sk_vbox.add_child(sp_sk_title)

	var sp_sk_desc_lbl = Label.new()
	sp_sk_desc_lbl.text = sp_sk_desc
	sp_sk_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sp_sk_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_sk_desc_lbl.add_theme_font_size_override("font_size", 11)
	sp_sk_desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 0.95))
	sp_sk_vbox.add_child(sp_sk_desc_lbl)
	sp_vbox.add_child(sp_skill_card)

	# Ownership Pill
	var sp_owned_panel = PanelContainer.new()
	var spop_style = StyleBoxFlat.new()
	if is_spotlight_owned:
		spop_style.bg_color = Color(0.08, 0.28, 0.16, 0.95)
		spop_style.border_color = Color(0.35, 0.88, 0.58, 0.9)
	else:
		spop_style.bg_color = Color(0.20, 0.14, 0.08, 0.95)
		spop_style.border_color = Color(1.0, 0.75, 0.25, 0.9)
	spop_style.border_width_left = 1
	spop_style.border_width_top = 1
	spop_style.border_width_right = 1
	spop_style.border_width_bottom = 1
	spop_style.corner_radius_top_left = 6
	spop_style.corner_radius_top_right = 6
	spop_style.corner_radius_bottom_right = 6
	spop_style.corner_radius_bottom_left = 6
	spop_style.content_margin_top = 4
	spop_style.content_margin_bottom = 4
	sp_owned_panel.add_theme_stylebox_override("panel", spop_style)

	var sp_owned_lbl = Label.new()
	sp_owned_lbl.text = "✓ ĐÃ SỞ HỮU" if is_spotlight_owned else "✨ CÓ THỂ HIỆU TRIỆU (Xác suất 1/28)"
	sp_owned_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_owned_lbl.add_theme_font_size_override("font_size", 11)
	sp_owned_lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.8, 1.0) if is_spotlight_owned else Color(1.0, 0.88, 0.4, 1.0))
	sp_owned_panel.add_child(sp_owned_lbl)
	sp_vbox.add_child(sp_owned_panel)

	# --- WING 2: SACRED SHRINE TABLET & POOL SHOWCASE (RIGHT, ~700px) ---
	var tablet_panel = PanelContainer.new()
	tablet_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	tablet_panel.size_flags_vertical = SIZE_EXPAND_FILL

	var tp_style = StyleBoxFlat.new()
	tp_style.bg_color = Color(0.06, 0.07, 0.11, 0.96)
	tp_style.border_width_left = 2
	tp_style.border_width_top = 2
	tp_style.border_width_right = 2
	tp_style.border_width_bottom = 2
	tp_style.border_color = Color(0.85, 0.72, 0.32, 0.80)
	tp_style.corner_radius_top_left = 12
	tp_style.corner_radius_top_right = 12
	tp_style.corner_radius_bottom_right = 12
	tp_style.corner_radius_bottom_left = 12
	tp_style.shadow_color = Color(0, 0, 0, 0.5)
	tp_style.shadow_size = 12
	tp_style.content_margin_left = 16
	tp_style.content_margin_right = 16
	tp_style.content_margin_top = 10
	tp_style.content_margin_bottom = 10
	tablet_panel.add_theme_stylebox_override("panel", tp_style)
	stage_hbox.add_child(tablet_panel)

	var tp_vbox = VBoxContainer.new()
	tp_vbox.set_anchors_preset(PRESET_FULL_RECT)
	tp_vbox.add_theme_constant_override("separation", 10)
	tablet_panel.add_child(tp_vbox)

	# Section 1: Collection Progress Tablet ("Bách Tướng Đồ")
	var owned_count_28 = 0
	for hid in range(1, 29):
		if HeroDatabase and HeroDatabase.is_hero_owned(hid):
			owned_count_28 += 1

	var prog_header = HBoxContainer.new()
	tp_vbox.add_child(prog_header)

	var prog_title = Label.new()
	prog_title.text = "📜 BÁCH TƯỚNG BẢNG (TIẾN ĐỘ THU THẬP TƯỚNG 1 ➔ 28)"
	prog_title.add_theme_font_size_override("font_size", 13)
	prog_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	prog_header.add_child(prog_title)

	var prog_sp = Control.new()
	prog_sp.size_flags_horizontal = SIZE_EXPAND_FILL
	prog_header.add_child(prog_sp)

	var prog_num_lbl = Label.new()
	var pct = int((float(owned_count_28) / 28.0) * 100.0)
	prog_num_lbl.text = "%d / 28 Danh Tướng (%d%%)" % [owned_count_28, pct]
	prog_num_lbl.add_theme_font_size_override("font_size", 13)
	prog_num_lbl.add_theme_color_override("font_color", Color(0.4, 0.92, 0.6, 1.0))
	prog_header.add_child(prog_num_lbl)

	# Progress Bar
	var pbar = ProgressBar.new()
	pbar.custom_minimum_size = Vector2(0, 12)
	pbar.max_value = 28
	pbar.value = owned_count_28
	pbar.show_percentage = false

	var pb_bg = StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.08, 0.10, 0.15, 0.95)
	pb_bg.corner_radius_top_left = 6
	pb_bg.corner_radius_top_right = 6
	pb_bg.corner_radius_bottom_right = 6
	pb_bg.corner_radius_bottom_left = 6

	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.85, 0.70, 0.22, 1.0)
	pb_fill.corner_radius_top_left = 6
	pb_fill.corner_radius_top_right = 6
	pb_fill.corner_radius_bottom_right = 6
	pb_fill.corner_radius_bottom_left = 6

	pbar.add_theme_stylebox_override("background", pb_bg)
	pbar.add_theme_stylebox_override("fill", pb_fill)
	tp_vbox.add_child(pbar)

	# Section 2: Pool Showcase Roster (4 Mini Hero Cards)
	var pool_hdr = Label.new()
	pool_hdr.text = "⭐ MỘT SỐ HÀO KIỆT NỔI BẬT ĐANG CÓ MẶT TRONG BỂ HIỆU TRIỆU:"
	pool_hdr.add_theme_font_size_override("font_size", 12)
	pool_hdr.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	tp_vbox.add_child(pool_hdr)

	var pool_cards_hbox = HBoxContainer.new()
	pool_cards_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pool_cards_hbox.add_theme_constant_override("separation", 10)
	tp_vbox.add_child(pool_cards_hbox)

	var sample_pool_ids = [1, 4, 9, 22] # Cao Lỗ, Lê Chân, Triệu Thị Trinh, Ngô Quyền
	for hid in sample_pool_ids:
		var hero_item = HeroDatabase.get_hero(hid) if HeroDatabase else {}
		var is_item_owned = HeroDatabase.is_hero_owned(hid) if HeroDatabase else false

		var mc = PanelContainer.new()
		mc.size_flags_horizontal = SIZE_EXPAND_FILL
		mc.custom_minimum_size = Vector2(0, 160)

		var mc_style = StyleBoxFlat.new()
		mc_style.bg_color = Color(0.08, 0.09, 0.14, 0.95)
		mc_style.border_color = Color(0.85, 0.72, 0.32, 0.7) if hid == _than_dien_selected_hero_id else Color(0.35, 0.40, 0.50, 0.5)
		mc_style.border_width_left = 2 if hid == _than_dien_selected_hero_id else 1
		mc_style.border_width_top = 2 if hid == _than_dien_selected_hero_id else 1
		mc_style.border_width_right = 2 if hid == _than_dien_selected_hero_id else 1
		mc_style.border_width_bottom = 2 if hid == _than_dien_selected_hero_id else 1
		mc_style.corner_radius_top_left = 8
		mc_style.corner_radius_top_right = 8
		mc_style.corner_radius_bottom_right = 8
		mc_style.corner_radius_bottom_left = 8
		mc_style.content_margin_left = 6
		mc_style.content_margin_right = 6
		mc_style.content_margin_top = 6
		mc_style.content_margin_bottom = 6
		mc.add_theme_stylebox_override("panel", mc_style)

		var mcv = VBoxContainer.new()
		mcv.add_theme_constant_override("separation", 3)
		mc.add_child(mcv)

		# Top mini tag
		var m_top = HBoxContainer.new()
		var m_id = Label.new()
		m_id.text = "#%02d" % hid
		m_id.add_theme_font_size_override("font_size", 10)
		m_id.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
		m_top.add_child(m_id)

		var m_sp = Control.new()
		m_sp.size_flags_horizontal = SIZE_EXPAND_FILL
		m_top.add_child(m_sp)

		var m_fac = Label.new()
		m_fac.text = str(hero_item.get("faction", "Đại Việt"))
		m_fac.add_theme_font_size_override("font_size", 9)
		m_fac.add_theme_color_override("font_color", HeroDatabase.get_faction_color(m_fac.text) if HeroDatabase else Color.WHITE)
		m_top.add_child(m_fac)
		mcv.add_child(m_top)

		# Mini Portrait
		var m_img = TextureRect.new()
		m_img.custom_minimum_size = Vector2(0, 90)
		m_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		m_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var m_av = str(hero_item.get("avatarPath", ""))
		var m_tex: Texture2D = null
		if HeroDatabase and m_av != "":
			m_tex = HeroDatabase.get_avatar_texture(m_av)
		if not m_tex and ResourceLoader.exists("res://assets/ui/game_avatar.png"):
			m_tex = load("res://assets/ui/game_avatar.png")
		if m_tex: m_img.texture = m_tex
		mcv.add_child(m_img)

		# Name
		var m_name = Label.new()
		m_name.text = str(hero_item.get("name", "Võ Tướng"))
		m_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m_name.add_theme_font_size_override("font_size", 12)
		m_name.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
		mcv.add_child(m_name)

		# Ownership Pill
		var m_own = Label.new()
		m_own.text = "✓ Sở Hữu" if is_item_owned else "🔒 Chưa Có"
		m_own.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		m_own.add_theme_font_size_override("font_size", 10)
		m_own.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4, 1.0) if is_item_owned else Color(0.7, 0.75, 0.85, 0.8))
		mcv.add_child(m_own)

		# Clickable button overlay to switch spotlight
		var m_btn = Button.new()
		m_btn.set_anchors_preset(PRESET_FULL_RECT)
		m_btn.flat = true
		m_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var captured_id = hid
		m_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_than_dien_selected_hero_id = captured_id
			_show_fullscreen_than_dien()
		)
		mc.add_child(m_btn)

		pool_cards_hbox.add_child(mc)

	# Section 3: Sacred Shrine Guarantees & Duplicate Conversion
	var rules_panel = PanelContainer.new()
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = Color(0.09, 0.11, 0.16, 0.95)
	rp_style.border_color = Color(0.85, 0.72, 0.32, 0.5)
	rp_style.border_width_left = 1
	rp_style.border_width_top = 1
	rp_style.border_width_right = 1
	rp_style.border_width_bottom = 1
	rp_style.corner_radius_top_left = 8
	rp_style.corner_radius_top_right = 8
	rp_style.corner_radius_bottom_right = 8
	rp_style.corner_radius_bottom_left = 8
	rp_style.content_margin_left = 12
	rp_style.content_margin_right = 12
	rp_style.content_margin_top = 8
	rp_style.content_margin_bottom = 8
	rules_panel.add_theme_stylebox_override("panel", rp_style)
	tp_vbox.add_child(rules_panel)

	var rpv = VBoxContainer.new()
	rpv.add_theme_constant_override("separation", 4)
	rules_panel.add_child(rpv)

	var r_title = Label.new()
	r_title.text = "⚖️ QUY TẮC HIỆU TRIỆU & BẢO HIỂM TRÙNG LẶP:"
	r_title.add_theme_font_size_override("font_size", 12)
	r_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.42, 1.0))
	rpv.add_child(r_title)

	var r1 = Label.new()
	r1.text = "• Bể Hiệu Triệu gồm toàn bộ 28 Hào Kiệt Đại Việt lịch sử đầu tiên (ID từ 1 đến 28)."
	r1.add_theme_font_size_override("font_size", 11)
	r1.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 0.95))
	rpv.add_child(r1)

	var r2 = Label.new()
	r2.text = "• Khi quay trúng Danh Tướng đã sở hữu ➔ Tự động quy đổi thành +1,000 BẠC 🥈 nạp ngay vào ngân khố!"
	r2.add_theme_font_size_override("font_size", 11)
	r2.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
	rpv.add_child(r2)

	var r3 = Label.new()
	r3.text = "• Nhận thêm Vé Triệu Hồi và Bạc miễn phí mỗi ngày tại Quà 7 Ngày Điểm Danh!"
	r3.add_theme_font_size_override("font_size", 11)
	r3.add_theme_color_override("font_color", Color(0.4, 0.92, 0.6, 0.95))
	rpv.add_child(r3)

	# 4. Bottom Command Altar Bar (Summon Buttons)
	var bottom_panel = PanelContainer.new()
	bottom_panel.custom_minimum_size = Vector2(0, 108)
	var bp_style = StyleBoxFlat.new()
	bp_style.bg_color = Color(0.06, 0.07, 0.11, 0.98)
	bp_style.border_width_top = 2
	bp_style.border_color = Color(0.85, 0.72, 0.32, 0.5)
	bottom_panel.add_theme_stylebox_override("panel", bp_style)
	main_vbox.add_child(bottom_panel)

	var bottom_vbox = VBoxContainer.new()
	bottom_vbox.set_anchors_preset(PRESET_FULL_RECT)
	bottom_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_vbox.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_vbox)

	var summon_hbox = HBoxContainer.new()
	summon_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	summon_hbox.add_theme_constant_override("separation", 32)
	bottom_vbox.add_child(summon_hbox)

	# Button Quay 1 Lần
	var btn_roll_1 = Button.new()
	btn_roll_1.custom_minimum_size = Vector2(280, 56)
	btn_roll_1.text = "⛩️ HIỆU TRIỆU 1 LẦN\n(Tiêu hao: 1 Vé Quay)"
	_style_than_dien_summon_1_btn(btn_roll_1)
	btn_roll_1.pressed.connect(func():
		AudioManager.play_card_select()
		_execute_gacha_summon(1)
	)
	summon_hbox.add_child(btn_roll_1)

	# Button Quay 5 Lần
	var btn_roll_5 = Button.new()
	btn_roll_5.custom_minimum_size = Vector2(280, 56)
	btn_roll_5.text = "🌟 HIỆU TRIỆU 5 LẦN\n(Tiêu hao: 5 Vé Quay)"
	_style_than_dien_summon_5_btn(btn_roll_5)
	btn_roll_5.pressed.connect(func():
		AudioManager.play_card_select()
		_execute_gacha_summon(5)
	)
	summon_hbox.add_child(btn_roll_5)

	var note_lbl = Label.new()
	note_lbl.text = "• Bể hiệu triệu gồm 28 Danh Tướng • Tự động bồi hoàn 1,000 Bạc khi trùng lặp"
	note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_lbl.add_theme_font_size_override("font_size", 11)
	note_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	bottom_vbox.add_child(note_lbl)

func _execute_gacha_summon(count: int) -> void:
	if not AuthManager:
		return

	if AuthManager.current_hero_tickets < count:
		AudioManager.play_parry()
		_show_modal("THÔNG BÁO VÉ QUAY TƯỚNG", _build_insufficient_tickets_content(count))
		return

	# Deduct tickets
	AuthManager.consume_hero_tickets(count)

	var results: Array[Dictionary] = []
	for i in range(count):
		# Pool: heroes 1 -> 28
		var rolled_id = randi_range(1, 28)
		var hero = HeroDatabase.get_hero(rolled_id) if HeroDatabase else {}
		var is_owned = HeroDatabase.is_hero_owned(rolled_id) if HeroDatabase else false

		if is_owned:
			# Quy đổi thành 1000 Bạc
			AuthManager.current_silver += 1000
			results.append({
				"hero": hero,
				"id": rolled_id,
				"is_new": false,
				"silver_gain": 1000
			})
		else:
			var slug = hero.get("slug", "")
			if slug != "":
				AuthManager.add_general(slug)
			else:
				AuthManager.add_general(str(rolled_id))
			results.append({
				"hero": hero,
				"id": rolled_id,
				"is_new": true,
				"silver_gain": 0
			})

	AuthManager.save_session()
	AuthManager.save_profile_to_appwrite()
	AuthManager.profile_updated.emit()
	_refresh_user_profile_ui()

	_play_gacha_reveal_animation(results, count)

func _build_gacha_card(res: Dictionary, is_small: bool) -> Control:
	var hero: Dictionary = res.get("hero", {})
	var is_new: bool = res.get("is_new", false)
	var silver_gain: int = res.get("silver_gain", 0)

	var card = PanelContainer.new()
	var card_size = Vector2(215, 380) if is_small else Vector2(340, 510)
	card.custom_minimum_size = card_size
	card.pivot_offset = card_size / 2.0

	var cs = StyleBoxFlat.new()
	if is_new:
		cs.bg_color = Color(0.12, 0.08, 0.05, 0.98)
		cs.border_color = Color(1.0, 0.88, 0.35, 1.0)
		cs.border_width_left = 3
		cs.border_width_right = 3
		cs.border_width_top = 3
		cs.border_width_bottom = 3
		cs.shadow_color = Color(1.0, 0.75, 0.2, 0.5)
		cs.shadow_size = 14
	else:
		cs.bg_color = Color(0.08, 0.10, 0.16, 0.98)
		cs.border_color = Color(0.45, 0.72, 0.92, 0.8)
		cs.border_width_left = 2
		cs.border_width_right = 2
		cs.border_width_top = 2
		cs.border_width_bottom = 2
		cs.shadow_color = Color(0.2, 0.5, 0.8, 0.35)
		cs.shadow_size = 8

	cs.corner_radius_top_left = 12
	cs.corner_radius_top_right = 12
	cs.corner_radius_bottom_right = 12
	cs.corner_radius_bottom_left = 12
	card.add_theme_stylebox_override("panel", cs)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# 1. Top Status Badge
	var tag_panel = PanelContainer.new()
	var ts = StyleBoxFlat.new()
	if is_new:
		ts.bg_color = Color(0.85, 0.20, 0.10, 0.95)
		ts.border_color = Color(1.0, 0.90, 0.40, 1.0)
	else:
		ts.bg_color = Color(0.15, 0.30, 0.45, 0.95)
		ts.border_color = Color(0.40, 0.80, 1.0, 0.8)
	ts.border_width_left = 1
	ts.border_width_right = 1
	ts.border_width_top = 1
	ts.border_width_bottom = 1
	ts.corner_radius_top_left = 6
	ts.corner_radius_top_right = 6
	ts.corner_radius_bottom_right = 6
	ts.corner_radius_bottom_left = 6
	tag_panel.add_theme_stylebox_override("panel", ts)

	var tag_lbl = Label.new()
	tag_lbl.text = "✨ TÂN TƯỚNG GIA NHẬP! ✨" if is_new else "♻️ ĐÃ SỞ HỮU"
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 12 if is_small else 14)
	tag_lbl.add_theme_color_override("font_color", Color.WHITE)
	tag_panel.add_child(tag_lbl)
	vbox.add_child(tag_panel)

	# 2. Hero Avatar Portrait
	var avatar_wrap = Control.new()
	avatar_wrap.custom_minimum_size = Vector2(0, 170 if is_small else 240)
	avatar_wrap.size_flags_vertical = SIZE_EXPAND_FILL

	var tex_rect = TextureRect.new()
	tex_rect.set_anchors_preset(PRESET_FULL_RECT)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var avatar_path = str(hero.get("avatarPath", ""))
	var slug = str(hero.get("slug", ""))
	var hero_tex: Texture2D = null
	if HeroDatabase and avatar_path != "":
		hero_tex = HeroDatabase.get_avatar_texture(avatar_path)
	if not hero_tex and slug != "":
		var p1 = "res://assets/heroes_transparent/%s.png" % slug
		if ResourceLoader.exists(p1):
			hero_tex = load(p1)
	if not hero_tex and avatar_path != "" and ResourceLoader.exists(avatar_path):
		hero_tex = load(avatar_path)
	if not hero_tex and ResourceLoader.exists("res://assets/ui/game_avatar.png"):
		hero_tex = load("res://assets/ui/game_avatar.png")
	if hero_tex:
		tex_rect.texture = hero_tex
	avatar_wrap.add_child(tex_rect)
	vbox.add_child(avatar_wrap)

	# 3. Hero Name & Faction
	var name_lbl = Label.new()
	name_lbl.text = str(hero.get("name", "Danh Tướng"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15 if is_small else 20)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
	vbox.add_child(name_lbl)

	var max_hp = int(hero.get("maxHp", 4))
	var fact_lbl = Label.new()
	fact_lbl.text = "%s  •  🪷 %d Máu" % [hero.get("faction", "Đại Việt"), max_hp]
	fact_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fact_lbl.add_theme_font_size_override("font_size", 11 if is_small else 13)
	fact_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(fact_lbl)

	# 4. Skill or Duplicate Silver Conversion
	var skills = hero.get("skills", [])
	var sk_name = "Võ Công"
	var sk_desc = ""
	if skills is Array and not skills.is_empty() and skills[0] is Dictionary:
		sk_name = str(skills[0].get("name", "Võ Công"))
		sk_desc = str(skills[0].get("desc", ""))

	if is_new:
		var sk_lbl = Label.new()
		if is_small:
			sk_lbl.text = "⚡ %s" % sk_name
		else:
			sk_lbl.text = "⚡ %s: %s" % [sk_name, sk_desc]
			sk_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sk_lbl.add_theme_font_size_override("font_size", 11 if is_small else 12)
		sk_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0, 0.95))
		vbox.add_child(sk_lbl)
	else:
		var conv_panel = PanelContainer.new()
		var cps = StyleBoxFlat.new()
		cps.bg_color = Color(0.18, 0.22, 0.32, 0.95)
		cps.border_color = Color(0.95, 0.85, 0.35, 0.9)
		cps.border_width_left = 1
		cps.border_width_right = 1
		cps.border_width_top = 1
		cps.border_width_bottom = 1
		cps.corner_radius_top_left = 6
		cps.corner_radius_top_right = 6
		cps.corner_radius_bottom_right = 6
		cps.corner_radius_bottom_left = 6
		conv_panel.add_theme_stylebox_override("panel", cps)

		var conv_lbl = Label.new()
		conv_lbl.text = "+1,000 BẠC 🥈"
		conv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		conv_lbl.add_theme_font_size_override("font_size", 13 if is_small else 15)
		conv_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35, 1.0))
		conv_panel.add_child(conv_lbl)
		vbox.add_child(conv_panel)

	return card

func _play_gacha_reveal_animation(results: Array, count: int) -> void:
	if is_instance_valid(_gacha_reveal_layer):
		_gacha_reveal_layer.queue_free()
		_gacha_reveal_layer = null

	var rev = Control.new()
	rev.name = "GachaRevealLayer"
	rev.set_anchors_preset(PRESET_FULL_RECT)
	rev.z_index = 120
	_gacha_reveal_layer = rev
	add_child(rev)

	# Deep mystical dark backdrop
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.025, 0.05, 0.97)
	rev.add_child(bg)

	# Central Rotating Sunburst / Lotus Halo
	var halo = TextureRect.new()
	halo.custom_minimum_size = Vector2(500, 500)
	halo.size = Vector2(500, 500)
	halo.set_anchors_preset(PRESET_CENTER)
	halo.pivot_offset = Vector2(250, 250)
	halo.grow_horizontal = GROW_DIRECTION_BOTH
	halo.grow_vertical = GROW_DIRECTION_BOTH
	halo.modulate = Color(1.0, 0.85, 0.3, 0.35)
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var halo_tex = load("res://assets/ui/lotus_halo.png")
	if halo_tex:
		halo.texture = halo_tex
	rev.add_child(halo)

	# Halo Continuous Rotation
	var halo_tw = rev.create_tween().set_loops()
	halo_tw.tween_property(halo, "rotation", TAU, 16.0).from(0.0)

	# Flash Shockwave Effect
	var flash = ColorRect.new()
	flash.set_anchors_preset(PRESET_FULL_RECT)
	flash.color = Color(1.0, 0.95, 0.7, 0.75)
	rev.add_child(flash)
	var flash_tw = rev.create_tween()
	flash_tw.tween_property(flash, "color:a", 0.0, 0.35).set_ease(Tween.EASE_OUT)
	flash_tw.tween_callback(flash.queue_free)

	# Sound
	AudioManager.play_skill()

	# Main VBox
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.offset_left = 32
	main_vbox.offset_right = -32
	main_vbox.offset_top = 24
	main_vbox.offset_bottom = -24
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 16)
	rev.add_child(main_vbox)

	# Header Title
	var title_lbl = Label.new()
	title_lbl.text = "⛩️ THẦN ĐIỆN HIỆU TRIỆU THÀNH CÔNG"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.45, 1.0))
	main_vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Khí thiêng sông núi hội tụ, Hào Kiệt giáng thế phù trợ nghĩa quân!"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	main_vbox.add_child(sub_lbl)

	# Cards Center Container
	var cards_center = HBoxContainer.new()
	cards_center.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_center.add_theme_constant_override("separation", 14)
	main_vbox.add_child(cards_center)

	var is_single = (count == 1)

	for i in range(results.size()):
		var res_item = results[i]
		var card_ctrl = _build_gacha_card(res_item, not is_single)
		card_ctrl.scale = Vector2(0.1, 0.1)
		card_ctrl.modulate.a = 0.0
		cards_center.add_child(card_ctrl)

		var delay = i * 0.18 if not is_single else 0.05
		var card_tw = rev.create_tween()
		card_tw.tween_interval(delay)
		card_tw.tween_callback(func():
			if res_item.get("is_new", false):
				AudioManager.play_victory()
			else:
				AudioManager.play_card_draw()
		)
		card_tw.set_parallel(true)
		card_tw.tween_property(card_ctrl, "scale", Vector2(1.06, 1.06), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tw.tween_property(card_ctrl, "modulate:a", 1.0, 0.20)
		card_tw.chain().tween_property(card_ctrl, "scale", Vector2.ONE, 0.12)

	# Summary Bar
	var new_count = results.filter(func(r): return r.get("is_new", false)).size()
	var total_silver = results.filter(func(r): return not r.get("is_new", false)).size() * 1000

	var sum_lbl = Label.new()
	sum_lbl.text = "🎉 Thu được: %d Danh Tướng Mới  |  Quy đổi +%s Bạc" % [new_count, _format_number(total_silver)]
	sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_lbl.add_theme_font_size_override("font_size", 14)
	sum_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.50, 1.0))
	main_vbox.add_child(sum_lbl)

	# Action Buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 18)
	main_vbox.add_child(btn_hbox)

	var btn_again_1 = Button.new()
	btn_again_1.custom_minimum_size = Vector2(190, 44)
	btn_again_1.text = "Quay Tiếp 1 Lần (1 Vé)"
	_style_white_gold_button(btn_again_1, 8, 3, Vector2(0, 2))
	btn_again_1.pressed.connect(func():
		AudioManager.play_card_select()
		_execute_gacha_summon(1)
	)
	btn_hbox.add_child(btn_again_1)

	var btn_again_5 = Button.new()
	btn_again_5.custom_minimum_size = Vector2(190, 44)
	btn_again_5.text = "Quay Tiếp 5 Lần (5 Vé)"
	_style_white_gold_button(btn_again_5, 8, 3, Vector2(0, 2))
	btn_again_5.pressed.connect(func():
		AudioManager.play_card_select()
		_execute_gacha_summon(5)
	)
	btn_hbox.add_child(btn_again_5)

	var btn_close = Button.new()
	btn_close.custom_minimum_size = Vector2(140, 44)
	btn_close.text = "XÁC NHẬN"
	_style_bronze_drum_cta(btn_close)
	btn_close.pressed.connect(func():
		AudioManager.play_card_select()
		if is_instance_valid(_gacha_reveal_layer):
			var tw_c = _gacha_reveal_layer.create_tween()
			tw_c.tween_property(_gacha_reveal_layer, "modulate:a", 0.0, 0.2)
			tw_c.tween_callback(func():
				if is_instance_valid(_gacha_reveal_layer):
					_gacha_reveal_layer.queue_free()
					_gacha_reveal_layer = null
			)
		if is_instance_valid(_fullscreen_than_dien_panel):
			_show_fullscreen_than_dien()
	)
	btn_hbox.add_child(btn_close)

func _build_insufficient_tickets_content(needed: int) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 14)
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_l = Label.new()
	icon_l.text = "⛩️"
	icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_l.add_theme_font_size_override("font_size", 42)
	container.add_child(icon_l)

	var msg_l = Label.new()
	msg_l.text = "Bạn không đủ Vé Quay Tướng!\nCần: %d Vé  |  Hiện có: %d Vé\n\nHãy nhận ngay Quà Điểm Danh 7 Ngày để thu thập thêm Vé Quay Tướng hoàn toàn miễn phí!" % [
		needed, AuthManager.current_hero_tickets if AuthManager else 0
	]
	msg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_l.add_theme_font_size_override("font_size", 14)
	msg_l.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	container.add_child(msg_l)

	var btn_claim = Button.new()
	btn_claim.text = "🎁 MỞ QUÀ 7 NGÀY ĐIỂM DANH"
	btn_claim.custom_minimum_size = Vector2(240, 42)
	btn_claim.size_flags_horizontal = SIZE_SHRINK_CENTER
	_style_bronze_drum_cta(btn_claim)
	btn_claim.pressed.connect(func():
		_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
	)
	container.add_child(btn_claim)

	return container

func _show_28_heroes_modal() -> void:
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(850, 460)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = SIZE_EXPAND_FILL

	for hid in range(1, 29):
		var h = HeroDatabase.get_hero(hid) if HeroDatabase else {}
		var is_owned = HeroDatabase.is_hero_owned(hid) if HeroDatabase else false

		var p = PanelContainer.new()
		p.custom_minimum_size = Vector2(195, 140)
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.12, 0.14, 0.20, 0.95) if is_owned else Color(0.07, 0.08, 0.11, 0.95)
		ps.border_color = Color(1.0, 0.85, 0.35, 0.8) if is_owned else Color(0.3, 0.35, 0.45, 0.5)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.corner_radius_top_left = 8
		ps.corner_radius_top_right = 8
		ps.corner_radius_bottom_right = 8
		ps.corner_radius_bottom_left = 8
		ps.content_margin_left = 8
		ps.content_margin_right = 8
		ps.content_margin_top = 6
		ps.content_margin_bottom = 6
		p.add_theme_stylebox_override("panel", ps)

		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)

		# Top row: ID + Name
		var top_row = HBoxContainer.new()
		var h_name = Label.new()
		h_name.text = "#%02d %s" % [hid, h.get("name", "Tướng")]
		h_name.add_theme_font_size_override("font_size", 12)
		h_name.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38, 1.0) if is_owned else Color(0.7, 0.7, 0.7, 1.0))
		top_row.add_child(h_name)

		var h_sp = Control.new()
		h_sp.size_flags_horizontal = SIZE_EXPAND_FILL
		top_row.add_child(h_sp)

		var h_fact = Label.new()
		h_fact.text = str(h.get("faction", "Đại Việt"))
		h_fact.add_theme_font_size_override("font_size", 10)
		h_fact.add_theme_color_override("font_color", HeroDatabase.get_faction_color(h_fact.text) if HeroDatabase else Color.WHITE)
		top_row.add_child(h_fact)
		v.add_child(top_row)

		# Middle: mini avatar + HP
		var mid_hbox = HBoxContainer.new()
		mid_hbox.add_theme_constant_override("separation", 6)

		var mini_av = TextureRect.new()
		mini_av.custom_minimum_size = Vector2(48, 56)
		mini_av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mini_av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var m_tex = HeroDatabase.get_avatar_texture(str(h.get("avatarPath", ""))) if HeroDatabase else null
		if m_tex: mini_av.texture = m_tex
		mid_hbox.add_child(mini_av)

		var mid_vbox = VBoxContainer.new()
		mid_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		mid_vbox.add_theme_constant_override("separation", 2)

		var max_hp = int(h.get("maxHp", 4))
		var h_hp = Label.new()
		h_hp.text = "🪷 %d Máu" % max_hp
		h_hp.add_theme_font_size_override("font_size", 11)
		h_hp.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 0.9))
		mid_vbox.add_child(h_hp)

		var skills = h.get("skills", [])
		var sk_name = "Võ Công"
		if skills is Array and not skills.is_empty() and skills[0] is Dictionary:
			sk_name = str(skills[0].get("name", "Võ Công"))
		var h_sk = Label.new()
		h_sk.text = "⚡ %s" % sk_name
		h_sk.add_theme_font_size_override("font_size", 11)
		h_sk.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.95))
		mid_vbox.add_child(h_sk)

		mid_hbox.add_child(mid_vbox)
		v.add_child(mid_hbox)

		# Bottom: Ownership tag
		var status_tag = Label.new()
		if is_owned:
			status_tag.text = "✓ ĐÃ SỞ HỮU"
			status_tag.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4, 1.0))
		else:
			status_tag.text = "🔒 CHƯA SỞ HỮU"
			status_tag.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.7))
		status_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_tag.add_theme_font_size_override("font_size", 10)
		v.add_child(status_tag)

		p.add_child(v)

		# Click card to show detail popup
		var click_btn = Button.new()
		click_btn.set_anchors_preset(PRESET_FULL_RECT)
		click_btn.flat = true
		click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var captured_hero = h
		var captured_owned = is_owned
		click_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_show_hero_detail_popup(captured_hero, captured_owned, scroll.get_parent())
		)
		p.add_child(click_btn)

		grid.add_child(p)

	scroll.add_child(grid)
	_show_modal("DANH SÁCH 28 HÀO KIỆT THẦN ĐIỆN", scroll)

func _build_equipment_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var items = [
		{"type": "Vũ Khí", "name": "Kiếm Thuận Thiên", "desc": "Tầm đánh +3. Khi Trảm trúng đích hồi phục 1 sinh mệnh."},
		{"type": "Vũ Khí", "name": "Nỏ Thần Kim Quy", "desc": "Bỏ qua khoảng cách mục tiêu. Không giới hạn số lần dùng Trảm."},
		{"type": "Phòng Cụ", "name": "Khiên Mây Bện", "desc": "Khi bị Trảm, phán xét lá trên cùng nếu chất ĐỎ tự động tính là ĐỠ."},
		{"type": "Phòng Cụ", "name": "Áo Bào Hoàng Tộc", "desc": "Chặn tối đa 2 sát thương, rồi bị hủy."},
		{"type": "Thú Cưỡi", "name": "Voi Chiến Đại Việt", "desc": "Ngựa Thủ (+1): Tăng khoảng cách kẻ địch nhắm vào mình lên 1."},
		{"type": "Bảo Vật", "name": "Ngọc Tỷ Truyền Quốc", "desc": "Mỗi lượt cho phép rút thêm 1 lá bài cẩm nang hoàng triều."},
	]

	for it in items:
		var panel = PanelContainer.new()
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.96, 0.95, 0.91, 1.0)
		ps.border_width_left = 2
		ps.border_color = COLOR_GOLD_PRIMARY
		ps.corner_radius_top_left = 6
		ps.corner_radius_bottom_left = 6
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 4
		ps.shadow_offset = Vector2(0, 2)
		panel.add_theme_stylebox_override("panel", ps)

		var row = HBoxContainer.new()
		row.offset_left = 12
		row.offset_right = -12
		row.offset_top = 8
		row.offset_bottom = -8
		row.add_theme_constant_override("separation", 12)

		var badge = Label.new()
		badge.text = "[%s]" % it["type"]
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		row.add_child(badge)

		var name_l = Label.new()
		name_l.text = it["name"]
		name_l.custom_minimum_size = Vector2(160, 0)
		name_l.add_theme_font_size_override("font_size", 13)
		name_l.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		row.add_child(name_l)

		var desc_l = Label.new()
		desc_l.text = it["desc"]
		desc_l.size_flags_horizontal = SIZE_EXPAND_FILL
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.add_theme_font_size_override("font_size", 12)
		desc_l.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		row.add_child(desc_l)

		panel.add_child(row)
		container.add_child(panel)

	return container

# --- Leaderboard System (Bảng Vàng / Bảng Phong Thần) ---
func _build_leaderboard_content() -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 10)

	# 1. Top Bar: Tabs & Refresh Button
	var top_bar = HBoxContainer.new()
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_theme_constant_override("separation", 10)

	var tab_btn_0 = Button.new()
	tab_btn_0.text = "⚔️ XẾP HẠNG 2v2"
	tab_btn_0.custom_minimum_size = Vector2(200, 40)
	_style_leaderboard_tab_button(tab_btn_0, _leaderboard_current_tab == 0)

	var tab_btn_1 = Button.new()
	tab_btn_1.text = "🎖️ QUÂN HÀM TRIỀU ĐÌNH"
	tab_btn_1.custom_minimum_size = Vector2(220, 40)
	_style_leaderboard_tab_button(tab_btn_1, _leaderboard_current_tab == 1)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 Làm Mới"
	refresh_btn.custom_minimum_size = Vector2(100, 40)
	_style_secondary_mode_button(refresh_btn)

	top_bar.add_child(tab_btn_0)
	top_bar.add_child(tab_btn_1)
	top_bar.add_child(spacer)
	top_bar.add_child(refresh_btn)
	container.add_child(top_bar)

	# 2. Server Status & Tab Subtitle Banner
	var sub_bar = HBoxContainer.new()
	sub_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var desc_label = Label.new()
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	_update_leaderboard_subtitle(desc_label)
	sub_bar.add_child(desc_label)

	var server_status_lbl = Label.new()
	server_status_lbl.add_theme_font_size_override("font_size", 11)
	server_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
	server_status_lbl.text = "🔄 Đang kết nối máy chủ Appwrite Singapore..."
	sub_bar.add_child(server_status_lbl)

	container.add_child(sub_bar)

	# 3. Table Rows Container
	var table_rows_container = VBoxContainer.new()
	table_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table_rows_container.add_theme_constant_override("separation", 6)
	container.add_child(table_rows_container)

	# 4. Bottom Pin Container (Thẻ Vị Trí Của Bạn)
	var bottom_pin_container = PanelContainer.new()
	bottom_pin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(bottom_pin_container)

	# Tab click events
	tab_btn_0.pressed.connect(func():
		if _leaderboard_current_tab != 0:
			_leaderboard_current_tab = 0
			_style_leaderboard_tab_button(tab_btn_0, true)
			_style_leaderboard_tab_button(tab_btn_1, false)
			_update_leaderboard_subtitle(desc_label)
			_render_leaderboard_rows(table_rows_container, bottom_pin_container)
	)

	tab_btn_1.pressed.connect(func():
		if _leaderboard_current_tab != 1:
			_leaderboard_current_tab = 1
			_style_leaderboard_tab_button(tab_btn_0, false)
			_style_leaderboard_tab_button(tab_btn_1, true)
			_update_leaderboard_subtitle(desc_label)
			_render_leaderboard_rows(table_rows_container, bottom_pin_container)
	)

	refresh_btn.pressed.connect(func():
		_fetch_and_render_leaderboard(table_rows_container, bottom_pin_container, server_status_lbl, refresh_btn)
	)

	# Tự động đẩy thông tin mới nhất của người chơi hiện tại lên Appwrite
	if AuthManager and AuthManager.is_logged_in:
		AuthManager.sync_leaderboard_entry()

	# Render danh sách tạm
	_render_leaderboard_rows(table_rows_container, bottom_pin_container)

	# Tự động gửi HTTP GET trực tiếp tới Appwrite Singapore ngay khi mở bảng
	_fetch_and_render_leaderboard(table_rows_container, bottom_pin_container, server_status_lbl, refresh_btn)

	return container

func _update_leaderboard_subtitle(desc_label: Label) -> void:
	if not is_instance_valid(desc_label):
		return
	if _leaderboard_current_tab == 0:
		desc_label.text = "⚔️ Bảng Phong Thần xếp hạng theo Bậc Đấu, Số Sao và Điểm Tích Lũy Đấu Trường 2v2."
	else:
		desc_label.text = "🎖️ Bảng Binh Lực Hoàng Triều xếp hạng theo Quân Hàm và Danh Tướng Sở Hữu (5 điểm / Tướng)."

func _style_leaderboard_tab_button(btn: Button, is_active: bool) -> void:
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_radius_bottom_left = 6
	if is_active:
		sb.bg_color = COLOR_GOLD_PRIMARY
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = COLOR_GOLD_ACCENT
		btn.add_theme_color_override("font_color", Color(0.10, 0.07, 0.02, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.10, 0.07, 0.02, 1.0))
	else:
		sb.bg_color = Color(0.14, 0.11, 0.18, 0.90)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.40, 0.32, 0.20, 0.60)
		btn.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD_ACCENT)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _fetch_and_render_leaderboard(table_rows_container: VBoxContainer, bottom_pin_container: PanelContainer, server_status_lbl: Label = null, refresh_btn: Button = null) -> void:
	if not is_instance_valid(table_rows_container):
		return
	_leaderboard_is_loading = true
	if is_instance_valid(refresh_btn):
		refresh_btn.text = "⏳ Đang tải..."
		refresh_btn.disabled = true
	if is_instance_valid(server_status_lbl):
		server_status_lbl.text = "🔄 Đang tải số liệu từ Appwrite Singapore..."
		server_status_lbl.add_theme_color_override("font_color", Color(0.95, 0.8, 0.3))

	if AuthManager and AuthManager.has_method("fetch_leaderboard_players"):
		AuthManager.fetch_leaderboard_players(func(players: Array):
			_leaderboard_is_loading = false
			if is_instance_valid(refresh_btn):
				refresh_btn.text = "🔄 Làm Mới"
				refresh_btn.disabled = false
			if not is_instance_valid(table_rows_container):
				return
			if not players.is_empty():
				_leaderboard_cached_players = players
			if is_instance_valid(server_status_lbl):
				var count_real = _leaderboard_cached_players.size()
				server_status_lbl.text = "🟢• %s" % [count_real, Time.get_time_string_from_system()]
				server_status_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.45))
			_render_leaderboard_rows(table_rows_container, bottom_pin_container)
		)
	else:
		_leaderboard_is_loading = false
		if is_instance_valid(refresh_btn):
			refresh_btn.text = "🔄 Làm Mới"
			refresh_btn.disabled = false

func _render_leaderboard_rows(table_rows_container: VBoxContainer, bottom_pin_container: PanelContainer) -> void:
	if not is_instance_valid(table_rows_container):
		return

	# Clear previous rows
	for child in table_rows_container.get_children():
		child.queue_free()

	# 1. Header Row
	var header = _create_leaderboard_header_row()
	table_rows_container.add_child(header)

	# 2. Prepare & Sort Players
	var players = _prepare_leaderboard_players(_leaderboard_cached_players)
	_sort_leaderboard_players(players, _leaderboard_current_tab)

	# 3. Build Player Rows
	if players.is_empty():
		var empty_panel = PanelContainer.new()
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.11, 0.08, 0.14, 0.85)
		ps.corner_radius_top_left = 6
		ps.corner_radius_top_right = 6
		ps.corner_radius_bottom_right = 6
		ps.corner_radius_bottom_left = 6
		empty_panel.add_theme_stylebox_override("panel", ps)
		var empty_lbl = Label.new()
		empty_lbl.text = "🔄 Đang tải số liệu từ máy chủ Appwrite Singapore..." if _leaderboard_is_loading else "Chưa có dữ liệu người chơi trên máy chủ."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		empty_panel.add_child(empty_lbl)
		table_rows_container.add_child(empty_panel)
		return

	var my_rank_pos = -1
	var my_player_dict = {}

	var my_uid = AuthManager.current_user_id if AuthManager else ""
	var my_email = AuthManager.current_user_email.to_lower() if AuthManager else ""
	var my_name = AuthManager.current_user_name if AuthManager else ""

	for i in range(players.size()):
		var p = players[i]
		var p_uid = str(p.get("user_id", ""))
		var p_email = str(p.get("email", "")).to_lower()
		var p_name = str(p.get("name", ""))

		var is_self = false
		if not my_uid.is_empty() and p_uid == my_uid:
			is_self = true
		elif not my_email.is_empty() and p_email == my_email:
			is_self = true
		elif my_uid.is_empty() and my_email.is_empty() and not my_name.is_empty() and p_name == my_name:
			is_self = true

		if is_self and my_rank_pos == -1:
			my_rank_pos = i + 1
			my_player_dict = p

		var row = _create_leaderboard_player_row(i + 1, p, is_self)
		table_rows_container.add_child(row)

	# 4. Render Bottom Pin Card
	if is_instance_valid(bottom_pin_container):
		for child in bottom_pin_container.get_children():
			child.queue_free()
		var pin_card = _create_my_position_card(my_rank_pos, my_player_dict)
		bottom_pin_container.add_child(pin_card)

func _create_leaderboard_header_row() -> PanelContainer:
	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.06, 0.10, 0.95)
	ps.border_width_left = 1
	ps.border_width_right = 1
	ps.border_width_top = 1
	ps.border_width_bottom = 2
	ps.border_color = Color(0.40, 0.32, 0.18, 0.8)
	ps.corner_radius_top_left = 6
	ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_right = 6
	ps.corner_radius_bottom_left = 6
	panel.add_theme_stylebox_override("panel", ps)

	var hbox = HBoxContainer.new()
	hbox.offset_left = 14
	hbox.offset_right = -14
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 14)

	var h_rank = Label.new()
	h_rank.text = "HẠNG"
	h_rank.custom_minimum_size = Vector2(55, 0)
	h_rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h_rank.add_theme_font_size_override("font_size", 12)
	h_rank.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	hbox.add_child(h_rank)

	var h_name = Label.new()
	h_name.text = "TƯỚNG QUÂN"
	h_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_name.add_theme_font_size_override("font_size", 12)
	h_name.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	hbox.add_child(h_name)

	if _leaderboard_current_tab == 0:
		var h_tier = Label.new()
		h_tier.text = "BẬC XẾP HẠNG"
		h_tier.custom_minimum_size = Vector2(160, 0)
		h_tier.add_theme_font_size_override("font_size", 12)
		h_tier.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_tier)

		var h_stars = Label.new()
		h_stars.text = "SAO & TÍCH LŨY"
		h_stars.custom_minimum_size = Vector2(170, 0)
		h_stars.add_theme_font_size_override("font_size", 12)
		h_stars.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_stars)

		var h_stat = Label.new()
		h_stat.text = "THẮNG / BẠI"
		h_stat.custom_minimum_size = Vector2(130, 0)
		h_stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h_stat.add_theme_font_size_override("font_size", 12)
		h_stat.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_stat)
	else:
		var h_mil = Label.new()
		h_mil.text = "QUÂN HÀM"
		h_mil.custom_minimum_size = Vector2(170, 0)
		h_mil.add_theme_font_size_override("font_size", 12)
		h_mil.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_mil)

		var h_pts = Label.new()
		h_pts.text = "BINH ĐIỂM"
		h_pts.custom_minimum_size = Vector2(140, 0)
		h_pts.add_theme_font_size_override("font_size", 12)
		h_pts.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_pts)

		var h_gen = Label.new()
		h_gen.text = "SỞ HỮU TƯỚNG"
		h_gen.custom_minimum_size = Vector2(150, 0)
		h_gen.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h_gen.add_theme_font_size_override("font_size", 12)
		h_gen.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hbox.add_child(h_gen)

	panel.add_child(hbox)
	return panel

func _create_leaderboard_player_row(rank_num: int, player: Dictionary, is_self: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.corner_radius_top_left = 6
	ps.corner_radius_top_right = 6
	ps.corner_radius_bottom_right = 6
	ps.corner_radius_bottom_left = 6

	if is_self:
		ps.bg_color = Color(0.22, 0.17, 0.08, 0.95)
		ps.border_width_left = 2
		ps.border_width_right = 2
		ps.border_width_top = 2
		ps.border_width_bottom = 2
		ps.border_color = COLOR_GOLD_PRIMARY
		ps.shadow_color = Color(0.9, 0.7, 0.2, 0.25)
		ps.shadow_size = 5
	elif rank_num == 1:
		ps.bg_color = Color(0.20, 0.16, 0.06, 0.92)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.border_color = Color(1.0, 0.84, 0.2, 0.9)
		ps.shadow_color = Color(0.8, 0.6, 0.1, 0.2)
		ps.shadow_size = 4
	elif rank_num == 2:
		ps.bg_color = Color(0.15, 0.15, 0.18, 0.92)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.border_color = Color(0.82, 0.85, 0.90, 0.8)
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 3
	elif rank_num == 3:
		ps.bg_color = Color(0.18, 0.13, 0.09, 0.92)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.border_color = Color(0.85, 0.55, 0.30, 0.8)
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 3
	else:
		ps.bg_color = Color(0.11, 0.08, 0.14, 0.85)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.border_color = Color(0.30, 0.24, 0.36, 0.40)
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 2

	panel.add_theme_stylebox_override("panel", ps)

	var hbox = HBoxContainer.new()
	hbox.offset_left = 14
	hbox.offset_right = -14
	hbox.offset_top = 8
	hbox.offset_bottom = -8
	hbox.add_theme_constant_override("separation", 14)

	# Column 1: Rank Position
	var r_lbl = Label.new()
	r_lbl.custom_minimum_size = Vector2(55, 0)
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if rank_num == 1:
		r_lbl.text = "🥇 1"
		r_lbl.add_theme_font_size_override("font_size", 16)
		r_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	elif rank_num == 2:
		r_lbl.text = "🥈 2"
		r_lbl.add_theme_font_size_override("font_size", 15)
		r_lbl.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	elif rank_num == 3:
		r_lbl.text = "🥉 3"
		r_lbl.add_theme_font_size_override("font_size", 15)
		r_lbl.add_theme_color_override("font_color", Color(0.92, 0.62, 0.35))
	else:
		r_lbl.text = "#%d" % rank_num
		r_lbl.add_theme_font_size_override("font_size", 13)
		r_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	hbox.add_child(r_lbl)

	# Column 2: Player Name & Level Badge
	var name_box = VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_theme_constant_override("separation", 2)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)

	var n_lbl = Label.new()
	var display_name = str(player.get("name", "Đại Tướng Quân")).strip_edges()
	if display_name.contains("@"):
		display_name = display_name.split("@")[0]
	if display_name.is_empty():
		display_name = "Đại Tướng Quân"
	n_lbl.text = display_name
	n_lbl.add_theme_font_size_override("font_size", 14)
	if is_self:
		n_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	else:
		n_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	name_row.add_child(n_lbl)

	var lvl = int(player.get("level", 1))
	var lvl_lbl = Label.new()
	lvl_lbl.text = "Lv.%d" % lvl
	lvl_lbl.add_theme_font_size_override("font_size", 11)
	lvl_lbl.add_theme_color_override("font_color", Color(0.70, 0.85, 0.98))
	name_row.add_child(lvl_lbl)

	if is_self:
		var self_tag = Label.new()
		self_tag.text = "(Bạn)"
		self_tag.add_theme_font_size_override("font_size", 11)
		self_tag.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
		name_row.add_child(self_tag)

	name_box.add_child(name_row)

	hbox.add_child(name_box)

	# Tab-specific columns
	if _leaderboard_current_tab == 0:
		# --- TAB 0: RANK 2v2 ---
		var rank_idx = int(player.get("rank_index", 0))
		var rank_name = str(player.get("rank_name", "Dân Binh"))
		var stars = int(player.get("rank_stars", 0))
		var acc_pts = int(player.get("rank_acc", 0))
		var wins = int(player.get("wins", 0))
		var losses = int(player.get("losses", 0))

		var rank_info = {}
		if RankSystem:
			rank_info = RankSystem.get_rank_info(rank_idx)

		var tier_badge = str(rank_info.get("badge", "🛡️"))
		var tier_color: Color = rank_info.get("color", Color(0.8, 0.8, 0.8))

		# BẬC ĐẤU
		var tier_lbl = Label.new()
		tier_lbl.text = "%s %s" % [tier_badge, rank_name]
		tier_lbl.custom_minimum_size = Vector2(160, 0)
		tier_lbl.add_theme_font_size_override("font_size", 13)
		tier_lbl.add_theme_color_override("font_color", tier_color)
		hbox.add_child(tier_lbl)

		# SAO & TÍCH LŨY
		var star_box = VBoxContainer.new()
		star_box.custom_minimum_size = Vector2(170, 0)
		star_box.add_theme_constant_override("separation", 2)

		var star_lbl = Label.new()
		if rank_idx >= 11:
			star_lbl.text = "👑 %d★ (Hoàng Tộc)" % stars
			star_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
		else:
			var star_str = ""
			for s in range(5):
				if s < stars:
					star_str += "★ "
				else:
					star_str += "☆ "
			star_lbl.text = star_str.strip_edges()
			star_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		star_lbl.add_theme_font_size_override("font_size", 13)
		star_box.add_child(star_lbl)

		var acc_lbl = Label.new()
		acc_lbl.text = "(%d/100 Điểm Tích Lũy)" % acc_pts
		acc_lbl.add_theme_font_size_override("font_size", 10)
		acc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		star_box.add_child(acc_lbl)

		hbox.add_child(star_box)

		# THẮNG / BẠI
		var stat_box = VBoxContainer.new()
		stat_box.custom_minimum_size = Vector2(130, 0)
		stat_box.add_theme_constant_override("separation", 2)

		var total_games = wins + losses
		var winrate = int(float(wins) / float(total_games) * 100.0) if total_games > 0 else 0

		var win_lbl = Label.new()
		win_lbl.text = "%dT - %dB" % [wins, losses]
		win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		win_lbl.add_theme_font_size_override("font_size", 13)
		win_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		stat_box.add_child(win_lbl)

		var wr_lbl = Label.new()
		wr_lbl.text = "Tỉ lệ: %d%%" % winrate
		wr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		wr_lbl.add_theme_font_size_override("font_size", 10)
		wr_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5) if winrate >= 50 else COLOR_TEXT_MUTED)
		stat_box.add_child(wr_lbl)

		hbox.add_child(stat_box)

	else:
		# --- TAB 1: QUÂN HÀM TRIỀU ĐÌNH ---
		var mil_pts = int(player.get("military_points", 0))
		var gen_cnt = int(player.get("generals_count", 1))
		var mil_tier_name = str(player.get("military_name", "Tân Binh"))
		var mil_badge = str(player.get("military_badge", "🔰"))

		if mil_tier_name.is_empty() or mil_tier_name == "Tân Binh":
			var m_info = _get_military_info_for_points(mil_pts)
			mil_tier_name = m_info["name"]
			mil_badge = m_info["badge"]

		# QUÂN HÀM
		var m_lbl = Label.new()
		m_lbl.text = "%s %s" % [mil_badge, mil_tier_name]
		m_lbl.custom_minimum_size = Vector2(170, 0)
		m_lbl.add_theme_font_size_override("font_size", 13)
		m_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		hbox.add_child(m_lbl)

		# BINH ĐIỂM
		var pts_box = VBoxContainer.new()
		pts_box.custom_minimum_size = Vector2(140, 0)
		pts_box.add_theme_constant_override("separation", 2)

		var pts_lbl = Label.new()
		pts_lbl.text = "⭐ %d Điểm" % mil_pts
		pts_lbl.add_theme_font_size_override("font_size", 13)
		pts_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
		pts_box.add_child(pts_lbl)

		var pts_sub = Label.new()
		pts_sub.text = "(5đ / Tướng)"
		pts_sub.add_theme_font_size_override("font_size", 10)
		pts_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		pts_box.add_child(pts_sub)

		hbox.add_child(pts_box)

		# SỞ HỮU TƯỚNG
		var gen_box = VBoxContainer.new()
		gen_box.custom_minimum_size = Vector2(150, 0)
		gen_box.add_theme_constant_override("separation", 2)

		var gen_lbl = Label.new()
		gen_lbl.text = "👥 %d / 28 Tướng" % gen_cnt
		gen_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gen_lbl.add_theme_font_size_override("font_size", 13)
		gen_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		gen_box.add_child(gen_lbl)

		var pct = int(float(gen_cnt) / 28.0 * 100.0)
		var pct_lbl = Label.new()
		pct_lbl.text = "%d%% Danh Tướng" % pct
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct_lbl.add_theme_font_size_override("font_size", 10)
		pct_lbl.add_theme_color_override("font_color", Color(0.85, 0.70, 0.3))
		gen_box.add_child(pct_lbl)

		hbox.add_child(gen_box)

	panel.add_child(hbox)
	return panel

func _create_my_position_card(my_pos: int, my_data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.18, 0.13, 0.06, 0.98)
	ps.border_width_left = 2
	ps.border_width_right = 2
	ps.border_width_top = 2
	ps.border_width_bottom = 2
	ps.border_color = COLOR_GOLD_PRIMARY
	ps.corner_radius_top_left = 8
	ps.corner_radius_top_right = 8
	ps.corner_radius_bottom_right = 8
	ps.corner_radius_bottom_left = 8
	ps.shadow_color = Color(0.9, 0.7, 0.1, 0.3)
	ps.shadow_size = 6
	panel.add_theme_stylebox_override("panel", ps)

	var hbox = HBoxContainer.new()
	hbox.offset_left = 16
	hbox.offset_right = -16
	hbox.offset_top = 10
	hbox.offset_bottom = -10
	hbox.add_theme_constant_override("separation", 16)

	var left_box = VBoxContainer.new()
	left_box.custom_minimum_size = Vector2(180, 0)
	left_box.add_theme_constant_override("separation", 2)

	var title_lbl = Label.new()
	title_lbl.text = "👑 THỨ HẠNG CỦA BẠN"
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	left_box.add_child(title_lbl)

	var pos_lbl = Label.new()
	if my_pos > 0:
		pos_lbl.text = "HẠNG #%d TOÀN SERVER" % my_pos
	else:
		pos_lbl.text = "CHƯA XẾP HẠNG"
	pos_lbl.add_theme_font_size_override("font_size", 15)
	pos_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65))
	left_box.add_child(pos_lbl)

	hbox.add_child(left_box)

	var center_box = VBoxContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.add_theme_constant_override("separation", 2)

	if _leaderboard_current_tab == 0:
		var r_idx = int(my_data.get("rank_index", 0)) if not my_data.is_empty() else (AuthManager.current_2v2_rank_index if AuthManager else 0)
		var r_stars = int(my_data.get("rank_stars", 0)) if not my_data.is_empty() else (AuthManager.current_2v2_stars if AuthManager else 0)
		var r_acc = int(my_data.get("rank_acc", 0)) if not my_data.is_empty() else (AuthManager.current_2v2_accumulation_points if AuthManager else 0)
		var r_name = RankSystem.get_rank_name(r_idx) if RankSystem else "Dân Binh"
		var r_info = RankSystem.get_rank_info(r_idx) if RankSystem else {}
		var badge = str(r_info.get("badge", "🛡️"))

		var stat_lbl = Label.new()
		stat_lbl.text = "%s %s • %d★ (%d/100 Điểm Tích Lũy)" % [badge, r_name, r_stars, r_acc]
		stat_lbl.add_theme_font_size_override("font_size", 13)
		stat_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		center_box.add_child(stat_lbl)

		var wins = int(my_data.get("wins", 0)) if not my_data.is_empty() else (AuthManager.current_wins if AuthManager else 0)
		var losses = int(my_data.get("losses", 0)) if not my_data.is_empty() else (AuthManager.current_losses if AuthManager else 0)
		var tot = wins + losses
		var wr = int(float(wins) / float(tot) * 100.0) if tot > 0 else 0

		var sub_lbl = Label.new()
		sub_lbl.text = "Chiến tích: %d Thắng - %d Bại (Tỉ lệ thắng: %d%%)" % [wins, losses, wr]
		sub_lbl.add_theme_font_size_override("font_size", 11)
		sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		center_box.add_child(sub_lbl)
	else:
		var m_pts = int(my_data.get("military_points", 0)) if not my_data.is_empty() else (AuthManager.get_military_points() if AuthManager else 5)
		var gen_cnt = int(my_data.get("generals_count", 1)) if not my_data.is_empty() else (AuthManager.current_generals.size() if AuthManager else 1)
		var m_info = _get_military_info_for_points(m_pts)

		var stat_lbl = Label.new()
		stat_lbl.text = "%s %s • %d Điểm Quân Hàm (5đ/Tướng)" % [m_info.get("badge", "🔰"), m_info.get("name", "Tân Binh"), m_pts]
		stat_lbl.add_theme_font_size_override("font_size", 13)
		stat_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		center_box.add_child(stat_lbl)

		var sub_lbl = Label.new()
		sub_lbl.text = "Đã chiêu mộ: %d / 28 Danh Tướng (%d%% Bộ Sưu Tập)" % [gen_cnt, int(float(gen_cnt) / 28.0 * 100.0)]
		sub_lbl.add_theme_font_size_override("font_size", 11)
		sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		center_box.add_child(sub_lbl)

	hbox.add_child(center_box)

	var right_box = VBoxContainer.new()
	right_box.custom_minimum_size = Vector2(160, 0)
	right_box.add_theme_constant_override("separation", 2)

	var inspire_lbl = Label.new()
	if _leaderboard_current_tab == 0:
		inspire_lbl.text = "⚔️ Đấu Trận 2v2 Để Leo Top!"
	else:
		inspire_lbl.text = "⛩️ Chiêu Mộ Tướng Tại Thần Điện!"
	inspire_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inspire_lbl.add_theme_font_size_override("font_size", 11)
	inspire_lbl.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	right_box.add_child(inspire_lbl)

	hbox.add_child(right_box)

	panel.add_child(hbox)
	return panel

func _get_military_info_for_points(pts: int) -> Dictionary:
	if AuthManager:
		for i in range(AuthManager.MILITARY_TIERS.size() - 1, -1, -1):
			if pts >= AuthManager.MILITARY_TIERS[i]["min"]:
				return AuthManager.MILITARY_TIERS[i]
	return {"tier": 1, "name": "Tân Binh", "badge": "🔰"}

func _prepare_leaderboard_players(fetched_players: Array) -> Array:
	var list: Array = []
	var seen_keys = {}

	# 1. First, insert all real fetched players from Appwrite
	for p in fetched_players:
		if not (p is Dictionary):
			continue
		var uid = str(p.get("user_id", ""))
		var email = str(p.get("email", "")).to_lower()
		var name = str(p.get("name", ""))
		var key = uid if not uid.is_empty() else (email if not email.is_empty() else name)
		if key.is_empty() or seen_keys.has(key):
			continue
		seen_keys[key] = true
		list.append(p)

	# 2. Ensure current local user is present and has latest live stats
	if AuthManager:
		var my_data = AuthManager.get_leaderboard_player_data()
		var my_uid = str(my_data.get("user_id", ""))
		var my_email = str(my_data.get("email", "")).to_lower()
		var my_key = my_uid if not my_uid.is_empty() else (my_email if not my_email.is_empty() else str(my_data.get("name", "")))
		var found_my_entry = false
		for i in range(list.size()):
			var p = list[i]
			var p_uid = str(p.get("user_id", ""))
			var p_email = str(p.get("email", "")).to_lower()
			if (not my_uid.is_empty() and p_uid == my_uid) or (not my_email.is_empty() and p_email == my_email):
				list[i] = my_data
				found_my_entry = true
				break
		if not found_my_entry and not my_key.is_empty():
			list.append(my_data)
			seen_keys[my_key] = true

	return list

func _sort_leaderboard_players(players: Array, tab: int) -> void:
	if tab == 0:
		# ⚔️ XẾP HẠNG 2v2:
		# 1. rank_index DESC (Tier 11 Hoàng Đế -> 0 Dân Binh)
		# 2. rank_stars DESC
		# 3. rank_acc DESC
		# 4. wins DESC
		# 5. rank_points DESC
		players.sort_custom(func(a, b):
			var r_a = int(a.get("rank_index", 0))
			var r_b = int(b.get("rank_index", 0))
			if r_a != r_b: return r_a > r_b
			var s_a = int(a.get("rank_stars", 0))
			var s_b = int(b.get("rank_stars", 0))
			if s_a != s_b: return s_a > s_b
			var acc_a = int(a.get("rank_acc", 0))
			var acc_b = int(b.get("rank_acc", 0))
			if acc_a != acc_b: return acc_a > acc_b
			var w_a = int(a.get("wins", 0))
			var w_b = int(b.get("wins", 0))
			if w_a != w_b: return w_a > w_b
			return int(a.get("rank_points", 0)) > int(b.get("rank_points", 0))
		)
	else:
		# 🎖️ QUÂN HÀM HOÀNG TRIỀU:
		# 1. military_points DESC (5đ/tướng)
		# 2. generals_count DESC
		# 3. level DESC
		# 4. exp DESC
		players.sort_custom(func(a, b):
			var m_a = int(a.get("military_points", 0))
			var m_b = int(b.get("military_points", 0))
			if m_a != m_b: return m_a > m_b
			var g_a = int(a.get("generals_count", 0))
			var g_b = int(b.get("generals_count", 0))
			if g_a != g_b: return g_a > g_b
			var l_a = int(a.get("level", 0))
			var l_b = int(b.get("level", 0))
			if l_a != l_b: return l_a > l_b
			return int(a.get("exp", 0)) > int(b.get("exp", 0))
		)



func _open_quests_modal() -> void:
	if DailyQuestSystem and DailyQuestSystem.has_method("ensure_today_quests"):
		DailyQuestSystem.ensure_today_quests()
	_show_modal("QUÂN LỆNH TRIỀU ĐÌNH", _build_quests_content())

func _update_quest_nav_indicator() -> void:
	if not is_instance_valid(quest_nav_btn):
		return
	var has_unclaimed: bool = false
	if DailyQuestSystem and DailyQuestSystem.has_method("has_unclaimed_rewards"):
		has_unclaimed = DailyQuestSystem.has_unclaimed_rewards()
	quest_nav_btn.text = "📜  NHIỆM VỤ 🔴" if has_unclaimed else "📜  NHIỆM VỤ"

func _refresh_quests_content() -> void:
	if is_instance_valid(modal_title_label) and modal_title_label.text == "QUÂN LỆNH TRIỀU ĐÌNH":
		if is_instance_valid(modal_content_container):
			for child in modal_content_container.get_children():
				child.queue_free()
			modal_content_container.add_child(_build_quests_content())
	_update_quest_nav_indicator()

func _build_quests_content() -> Control:
	if DailyQuestSystem and DailyQuestSystem.has_method("ensure_today_quests"):
		DailyQuestSystem.ensure_today_quests()

	var container = VBoxContainer.new()
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 14)

	var cur_pts: int = 0
	if DailyQuestSystem and DailyQuestSystem.has_method("get_activity_points"):
		cur_pts = DailyQuestSystem.get_activity_points()
	elif AuthManager and AuthManager.daily_quests_data is Dictionary:
		cur_pts = int(AuthManager.daily_quests_data.get("activity_points", 0))

	var claimed_milestones: Array = []
	if DailyQuestSystem and DailyQuestSystem.has_method("get_claimed_milestones"):
		claimed_milestones = DailyQuestSystem.get_claimed_milestones()
	elif AuthManager and AuthManager.daily_quests_data is Dictionary:
		var raw_arr = AuthManager.daily_quests_data.get("claimed_milestones", [])
		if raw_arr is Array:
			claimed_milestones = raw_arr

	var has_unclaimed: bool = false
	if DailyQuestSystem and DailyQuestSystem.has_method("has_unclaimed_rewards"):
		has_unclaimed = DailyQuestSystem.has_unclaimed_rewards()

	# ==========================================
	# 1. BẢNG MỐC NĂNG ĐỘNG & RƯƠNG THƯỞNG (0 -> 100)
	# ==========================================
	var top_panel = PanelContainer.new()
	var top_style = StyleBoxFlat.new()
	top_style.bg_color = Color(0.12, 0.09, 0.16, 0.95)
	top_style.border_width_left = 2
	top_style.border_width_top = 2
	top_style.border_width_right = 2
	top_style.border_width_bottom = 2
	top_style.border_color = COLOR_GOLD_PRIMARY
	top_style.corner_radius_top_left = 10
	top_style.corner_radius_top_right = 10
	top_style.corner_radius_bottom_right = 10
	top_style.corner_radius_bottom_left = 10
	top_style.shadow_color = COLOR_SHADOW_DEEP
	top_style.shadow_size = 8
	top_style.shadow_offset = Vector2(0, 3)
	top_panel.add_theme_stylebox_override("panel", top_style)

	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_right", 16)
	top_margin.add_theme_constant_override("margin_top", 12)
	top_margin.add_theme_constant_override("margin_bottom", 12)
	top_panel.add_child(top_margin)

	var top_vbox = VBoxContainer.new()
	top_vbox.add_theme_constant_override("separation", 10)
	top_margin.add_child(top_vbox)

	# Hàng 1: Thông tin điểm năng động & Nút Nhận Tất Cả
	var header_hbox = HBoxContainer.new()
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var points_hbox = HBoxContainer.new()
	points_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	points_hbox.add_theme_constant_override("separation", 8)

	var star_icon = Label.new()
	star_icon.text = "🌟"
	star_icon.add_theme_font_size_override("font_size", 18)
	points_hbox.add_child(star_icon)

	var pts_title = Label.new()
	pts_title.text = "NĂNG ĐỘNG HÔM NAY:"
	pts_title.add_theme_font_size_override("font_size", 14)
	pts_title.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	points_hbox.add_child(pts_title)

	var pts_val = Label.new()
	pts_val.text = "%d / 100" % [cur_pts]
	pts_val.add_theme_font_size_override("font_size", 16)
	pts_val.add_theme_color_override("font_color", Color(1.0, 0.95, 0.55, 1.0))
	points_hbox.add_child(pts_val)

	var pts_sub = Label.new()
	pts_sub.text = "(Làm mới mỗi ngày lúc 00:00)"
	pts_sub.add_theme_font_size_override("font_size", 11)
	pts_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	points_hbox.add_child(pts_sub)

	header_hbox.add_child(points_hbox)

	var claim_all_btn = Button.new()
	claim_all_btn.custom_minimum_size = Vector2(170, 36)
	claim_all_btn.text = "🎁  NHẬN TẤT CẢ"
	if has_unclaimed:
		var active_style = StyleBoxFlat.new()
		active_style.bg_color = Color(0.92, 0.75, 0.22, 1.0)
		active_style.border_width_left = 1
		active_style.border_width_top = 1
		active_style.border_width_right = 1
		active_style.border_width_bottom = 1
		active_style.border_color = Color(1.0, 0.92, 0.6, 1.0)
		active_style.corner_radius_top_left = 8
		active_style.corner_radius_top_right = 8
		active_style.corner_radius_bottom_right = 8
		active_style.corner_radius_bottom_left = 8
		active_style.shadow_color = Color(0.92, 0.75, 0.22, 0.5)
		active_style.shadow_size = 6
		claim_all_btn.add_theme_stylebox_override("normal", active_style)
		claim_all_btn.add_theme_stylebox_override("hover", active_style)
		claim_all_btn.add_theme_color_override("font_color", Color(0.12, 0.08, 0.02, 1.0))
		claim_all_btn.disabled = false
	else:
		_style_white_gold_button(claim_all_btn, 8, 3, Vector2(0, 2))
		claim_all_btn.disabled = true
		claim_all_btn.modulate = Color(0.6, 0.6, 0.6, 0.7)

	claim_all_btn.pressed.connect(func():
		AudioManager.play_victory()
		var res = DailyQuestSystem.claim_all_available() if (DailyQuestSystem and DailyQuestSystem.has_method("claim_all_available")) else {}
		_load_user_data()
		_refresh_quests_content()
	)
	header_hbox.add_child(claim_all_btn)
	top_vbox.add_child(header_hbox)

	# Hàng 2: Thanh tiến trình năng động ProgressBar
	var pbar = ProgressBar.new()
	pbar.min_value = 0
	pbar.max_value = 100
	pbar.value = clamp(cur_pts, 0, 100)
	pbar.show_percentage = false
	pbar.custom_minimum_size = Vector2(0, 12)

	var pbar_bg = StyleBoxFlat.new()
	pbar_bg.bg_color = Color(0.06, 0.05, 0.08, 1.0)
	pbar_bg.border_width_left = 1
	pbar_bg.border_width_top = 1
	pbar_bg.border_width_right = 1
	pbar_bg.border_width_bottom = 1
	pbar_bg.border_color = Color(0.4, 0.35, 0.25, 0.8)
	pbar_bg.corner_radius_top_left = 6
	pbar_bg.corner_radius_top_right = 6
	pbar_bg.corner_radius_bottom_right = 6
	pbar_bg.corner_radius_bottom_left = 6
	pbar.add_theme_stylebox_override("background", pbar_bg)

	var pbar_fill = StyleBoxFlat.new()
	pbar_fill.bg_color = Color(0.95, 0.78, 0.22, 1.0)
	pbar_fill.corner_radius_top_left = 6
	pbar_fill.corner_radius_top_right = 6
	pbar_fill.corner_radius_bottom_right = 6
	pbar_fill.corner_radius_bottom_left = 6
	pbar.add_theme_stylebox_override("fill", pbar_fill)
	top_vbox.add_child(pbar)

	# Hàng 3: 5 Mốc Rương Năng Động (20, 40, 60, 80, 100)
	var chests_hbox = HBoxContainer.new()
	chests_hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	chests_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	chests_hbox.add_theme_constant_override("separation", 10)

	var milestones = DailyQuestSystem.MILESTONES if (DailyQuestSystem and "MILESTONES" in DailyQuestSystem) else [
		{"points": 20, "silver": 50, "tickets": 0, "name": "Rương Tiền Đồn"},
		{"points": 40, "silver": 100, "tickets": 0, "name": "Rương Quân Nhu"},
		{"points": 60, "silver": 150, "tickets": 0, "name": "Rương Tướng Hiệu"},
		{"points": 80, "silver": 250, "tickets": 0, "name": "Rương Đô Đốc"},
		{"points": 100, "silver": 350, "tickets": 1, "name": "Đại Rương Khải Hoàn"}
	]
	for m in milestones:
		var m_pts: int = int(m["points"])
		var m_silver: int = int(m["silver"])
		var m_tickets: int = int(m["tickets"])
		var m_name: String = str(m["name"])
		var is_claimed: bool = false
		if DailyQuestSystem and DailyQuestSystem.has_method("is_milestone_claimed"):
			is_claimed = DailyQuestSystem.is_milestone_claimed(m_pts)
		elif m_pts in claimed_milestones:
			is_claimed = true
		elif AuthManager and AuthManager.daily_quests_data is Dictionary:
			var raw_arr = AuthManager.daily_quests_data.get("claimed_milestones", [])
			is_claimed = int(m_pts) in raw_arr
		var is_unlocked: bool = cur_pts >= m_pts and not is_claimed

		var m_card = PanelContainer.new()
		m_card.size_flags_horizontal = SIZE_EXPAND_FILL
		var mc_style = StyleBoxFlat.new()
		if is_unlocked:
			mc_style.bg_color = Color(0.24, 0.18, 0.10, 0.95)
			mc_style.border_color = Color(1.0, 0.85, 0.35, 1.0)
		elif is_claimed:
			mc_style.bg_color = Color(0.09, 0.08, 0.11, 0.7)
			mc_style.border_color = Color(0.35, 0.35, 0.35, 0.5)
		else:
			mc_style.bg_color = Color(0.10, 0.08, 0.13, 0.9)
			mc_style.border_color = Color(0.45, 0.40, 0.30, 0.6)
		mc_style.border_width_left = 1
		mc_style.border_width_top = 1
		mc_style.border_width_right = 1
		mc_style.border_width_bottom = 1
		mc_style.corner_radius_top_left = 8
		mc_style.corner_radius_top_right = 8
		mc_style.corner_radius_bottom_right = 8
		mc_style.corner_radius_bottom_left = 8
		m_card.add_theme_stylebox_override("panel", mc_style)

		var mc_margin = MarginContainer.new()
		mc_margin.add_theme_constant_override("margin_left", 8)
		mc_margin.add_theme_constant_override("margin_right", 8)
		mc_margin.add_theme_constant_override("margin_top", 8)
		mc_margin.add_theme_constant_override("margin_bottom", 8)
		m_card.add_child(mc_margin)

		var mc_vbox = VBoxContainer.new()
		mc_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		mc_vbox.add_theme_constant_override("separation", 4)
		mc_margin.add_child(mc_vbox)

		# Điểm mốc
		var badge = Label.new()
		badge.text = "%d Điểm" % m_pts
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY if is_unlocked else (Color(0.5, 0.8, 0.5, 1.0) if is_claimed else COLOR_TEXT_MUTED))
		mc_vbox.add_child(badge)

		# Nút mở rương
		var c_btn = Button.new()
		c_btn.custom_minimum_size = Vector2(0, 32)
		if is_claimed:
			c_btn.text = "✓ ĐÃ MỞ"
			c_btn.disabled = true
			_style_white_gold_button(c_btn, 6, 0, Vector2.ZERO)
			c_btn.modulate = Color(0.6, 0.6, 0.6, 0.7)
		elif is_unlocked:
			c_btn.text = "🎁 MỞ"
			var ob_style = StyleBoxFlat.new()
			ob_style.bg_color = Color(0.95, 0.75, 0.20, 1.0)
			ob_style.corner_radius_top_left = 6
			ob_style.corner_radius_top_right = 6
			ob_style.corner_radius_bottom_right = 6
			ob_style.corner_radius_bottom_left = 6
			ob_style.shadow_color = Color(1.0, 0.8, 0.2, 0.6)
			ob_style.shadow_size = 6
			c_btn.add_theme_stylebox_override("normal", ob_style)
			c_btn.add_theme_stylebox_override("hover", ob_style)
			c_btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02, 1.0))
			c_btn.pressed.connect(func():
				AudioManager.play_victory()
				var res = DailyQuestSystem.claim_milestone(m_pts) if (DailyQuestSystem and DailyQuestSystem.has_method("claim_milestone")) else {}
				_load_user_data()
				_refresh_quests_content()
			)
		else:
			c_btn.text = "🔒 KHÓA"
			c_btn.disabled = true
			_style_white_gold_button(c_btn, 6, 0, Vector2.ZERO)
			c_btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		mc_vbox.add_child(c_btn)

		# Phần thưởng
		var rew_lbl = Label.new()
		var rew_text = "🥈 %d Bạc" % [m_silver]
		if m_tickets > 0:
			rew_text += "\n📜 +%d Vé" % m_tickets
		rew_lbl.text = rew_text
		rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rew_lbl.add_theme_font_size_override("font_size", 11)
		rew_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0) if is_unlocked else COLOR_TEXT_MUTED)
		mc_vbox.add_child(rew_lbl)

		chests_hbox.add_child(m_card)

	top_vbox.add_child(chests_hbox)
	container.add_child(top_panel)

	# ==========================================
	# 2. DANH SÁCH 7 NHIỆM VỤ NGÀY
	# ==========================================
	var list_header = Label.new()
	list_header.text = "📜 DANH SÁCH QUÂN LỆNH TRIỀU ĐÌNH"
	list_header.add_theme_font_size_override("font_size", 14)
	list_header.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	container.add_child(list_header)

	var quests_list = DailyQuestSystem.get_quests_list() if (DailyQuestSystem and DailyQuestSystem.has_method("get_quests_list")) else []
	for q in quests_list:
		var q_id: String = str(q["id"])
		var q_name: String = str(q["name"])
		var q_desc: String = str(q["desc"])
		var q_icon: String = str(q["icon"])
		var q_prog: int = int(q["progress"])
		var q_target: int = int(q["target"])
		var q_pts: int = int(q["points"])
		var q_claimed: bool = bool(q["claimed"])
		var is_ready_to_claim: bool = (not q_claimed and q_prog >= q_target)

		var q_panel = PanelContainer.new()
		var qs = StyleBoxFlat.new()
		if is_ready_to_claim:
			qs.bg_color = Color(0.20, 0.16, 0.12, 0.95)
			qs.border_color = Color(1.0, 0.85, 0.35, 1.0)
			qs.border_width_left = 3
		elif q_claimed:
			qs.bg_color = Color(0.09, 0.08, 0.11, 0.75)
			qs.border_color = Color(0.3, 0.3, 0.3, 0.4)
			qs.border_width_left = 2
		else:
			qs.bg_color = Color(0.12, 0.10, 0.16, 0.95)
			qs.border_color = Color(0.45, 0.40, 0.30, 0.6)
			qs.border_width_left = 2
		qs.border_width_top = 1
		qs.border_width_right = 1
		qs.border_width_bottom = 1
		qs.corner_radius_top_left = 8
		qs.corner_radius_top_right = 8
		qs.corner_radius_bottom_right = 8
		qs.corner_radius_bottom_left = 8
		qs.shadow_color = COLOR_SHADOW
		qs.shadow_size = 4
		qs.shadow_offset = Vector2(0, 2)
		q_panel.add_theme_stylebox_override("panel", qs)

		var q_margin = MarginContainer.new()
		q_margin.add_theme_constant_override("margin_left", 14)
		q_margin.add_theme_constant_override("margin_right", 14)
		q_margin.add_theme_constant_override("margin_top", 8)
		q_margin.add_theme_constant_override("margin_bottom", 8)
		q_panel.add_child(q_margin)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		q_margin.add_child(row)

		# Icon
		var icon_lbl = Label.new()
		icon_lbl.text = q_icon
		icon_lbl.add_theme_font_size_override("font_size", 24)
		icon_lbl.custom_minimum_size = Vector2(36, 0)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(icon_lbl)

		# Name & Description
		var text_vbox = VBoxContainer.new()
		text_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)

		var title_lbl = Label.new()
		title_lbl.text = q_name
		title_lbl.add_theme_font_size_override("font_size", 14)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70, 1.0) if is_ready_to_claim else (COLOR_TEXT_MUTED if q_claimed else COLOR_TEXT_DARK))
		text_vbox.add_child(title_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = q_desc
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		text_vbox.add_child(desc_lbl)
		row.add_child(text_vbox)

		# Reward Points Badge
		var rew_badge = Label.new()
		rew_badge.text = "🌟 +%d Điểm" % q_pts
		rew_badge.custom_minimum_size = Vector2(100, 0)
		rew_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rew_badge.add_theme_font_size_override("font_size", 13)
		rew_badge.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		row.add_child(rew_badge)

		# Progress Label
		var prog_lbl = Label.new()
		prog_lbl.text = "%d / %d" % [q_prog, q_target]
		prog_lbl.custom_minimum_size = Vector2(65, 0)
		prog_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prog_lbl.add_theme_font_size_override("font_size", 13)
		if q_prog >= q_target:
			prog_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 1.0))
		else:
			prog_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		row.add_child(prog_lbl)

		# Action Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110, 34)
		if q_claimed:
			btn.text = "✓ ĐÃ NHẬN"
			btn.disabled = true
			_style_white_gold_button(btn, 6, 0, Vector2.ZERO)
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		elif is_ready_to_claim:
			btn.text = "🎁 NHẬN"
			var r_style = StyleBoxFlat.new()
			r_style.bg_color = Color(0.92, 0.75, 0.22, 1.0)
			r_style.corner_radius_top_left = 6
			r_style.corner_radius_top_right = 6
			r_style.corner_radius_bottom_right = 6
			r_style.corner_radius_bottom_left = 6
			r_style.shadow_color = Color(0.92, 0.75, 0.22, 0.4)
			r_style.shadow_size = 5
			btn.add_theme_stylebox_override("normal", r_style)
			btn.add_theme_stylebox_override("hover", r_style)
			btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02, 1.0))
			btn.pressed.connect(func():
				AudioManager.play_victory()
				var res = DailyQuestSystem.claim_quest(q_id) if (DailyQuestSystem and DailyQuestSystem.has_method("claim_quest")) else {}
				_load_user_data()
				_refresh_quests_content()
			)
		else:
			btn.text = "TIẾP TỤC"
			_style_white_gold_button(btn, 6, 3, Vector2(0, 2))
			btn.pressed.connect(func():
				AudioManager.play_card_select()
				_hide_modal()
			)
		row.add_child(btn)

		container.add_child(q_panel)

	return container

func _open_inventory_modal() -> void:
	_show_modal("TÚI ĐỒ TƯỚNG QUÂN", _build_inventory_content())

func _refresh_inventory_content() -> void:
	if is_instance_valid(modal_title_label) and modal_title_label.text == "TÚI ĐỒ TƯỚNG QUÂN":
		if is_instance_valid(modal_content_container):
			for child in modal_content_container.get_children():
				child.queue_free()
			modal_content_container.add_child(_build_inventory_content())

func _build_inventory_content() -> Control:
	var container = VBoxContainer.new()
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 14)

	# 1. Khung Tiêu Đề & Thông Tin Hành Trang
	var top_panel = PanelContainer.new()
	var top_style = StyleBoxFlat.new()
	top_style.bg_color = Color(0.12, 0.09, 0.16, 0.95)
	top_style.border_width_left = 2
	top_style.border_width_top = 2
	top_style.border_width_right = 2
	top_style.border_width_bottom = 2
	top_style.border_color = COLOR_GOLD_PRIMARY
	top_style.corner_radius_top_left = 10
	top_style.corner_radius_top_right = 10
	top_style.corner_radius_bottom_right = 10
	top_style.corner_radius_bottom_left = 10
	top_style.shadow_color = COLOR_SHADOW
	top_style.shadow_size = 6
	top_style.shadow_offset = Vector2(0, 3)
	top_panel.add_theme_stylebox_override("panel", top_style)

	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 16)
	top_margin.add_theme_constant_override("margin_right", 16)
	top_margin.add_theme_constant_override("margin_top", 12)
	top_margin.add_theme_constant_override("margin_bottom", 12)
	top_panel.add_child(top_margin)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 14)
	top_margin.add_child(top_hbox)

	var bag_icon = Label.new()
	bag_icon.text = "🎒"
	bag_icon.add_theme_font_size_override("font_size", 28)
	top_hbox.add_child(bag_icon)

	var bag_title_vbox = VBoxContainer.new()
	bag_title_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	bag_title_vbox.add_theme_constant_override("separation", 2)

	var b_title = Label.new()
	b_title.text = "KHO HÀNH TRANG QUÂN CƠ"
	b_title.add_theme_font_size_override("font_size", 16)
	b_title.add_theme_color_override("font_color", COLOR_GOLD_PRIMARY)
	bag_title_vbox.add_child(b_title)

	var b_sub = Label.new()
	b_sub.text = "Quản lý các loại lệnh bài, vé triệu hồi hào kiệt và bảo vật trong hành trang của Tướng Quân."
	b_sub.add_theme_font_size_override("font_size", 11)
	b_sub.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	bag_title_vbox.add_child(b_sub)
	top_hbox.add_child(bag_title_vbox)

	container.add_child(top_panel)

	# 2. Danh Sách Vật Phẩm
	var tickets: int = AuthManager.current_hero_tickets if AuthManager else current_hero_tickets
	var has_items: bool = false

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 320)
	scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	items_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(items_vbox)

	# Nếu có vé hiệu triệu (>0)
	if tickets > 0:
		has_items = true
		var item_card = PanelContainer.new()
		item_card.custom_minimum_size = Vector2(0, 84)
		item_card.size_flags_horizontal = SIZE_EXPAND_FILL
		var cs = StyleBoxFlat.new()
		cs.bg_color = Color(0.14, 0.11, 0.18, 0.95)
		cs.border_width_left = 2
		cs.border_width_top = 1
		cs.border_width_right = 1
		cs.border_width_bottom = 1
		cs.border_color = Color(0.95, 0.80, 0.30, 0.8)
		cs.corner_radius_top_left = 10
		cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_right = 10
		cs.corner_radius_bottom_left = 10
		cs.shadow_color = COLOR_SHADOW
		cs.shadow_size = 4
		cs.shadow_offset = Vector2(0, 2)
		item_card.add_theme_stylebox_override("panel", cs)

		var item_margin = MarginContainer.new()
		item_margin.add_theme_constant_override("margin_left", 14)
		item_margin.add_theme_constant_override("margin_right", 14)
		item_margin.add_theme_constant_override("margin_top", 10)
		item_margin.add_theme_constant_override("margin_bottom", 10)
		item_card.add_child(item_margin)

		var item_hbox = HBoxContainer.new()
		item_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		item_hbox.add_theme_constant_override("separation", 14)
		item_margin.add_child(item_hbox)

		# Icon Container
		var icon_box = PanelContainer.new()
		icon_box.custom_minimum_size = Vector2(60, 60)
		var ib_style = StyleBoxFlat.new()
		ib_style.bg_color = Color(0.22, 0.16, 0.10, 0.95)
		ib_style.border_width_left = 2
		ib_style.border_width_top = 2
		ib_style.border_width_right = 2
		ib_style.border_width_bottom = 2
		ib_style.border_color = Color(1.0, 0.85, 0.35, 1.0)
		ib_style.corner_radius_top_left = 8
		ib_style.corner_radius_top_right = 8
		ib_style.corner_radius_bottom_right = 8
		ib_style.corner_radius_bottom_left = 8
		icon_box.add_theme_stylebox_override("panel", ib_style)

		var icon_inner = VBoxContainer.new()
		icon_inner.alignment = BoxContainer.ALIGNMENT_CENTER
		var i_lbl = Label.new()
		i_lbl.text = "📜"
		i_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		i_lbl.add_theme_font_size_override("font_size", 28)
		icon_inner.add_child(i_lbl)
		icon_box.add_child(icon_inner)
		item_hbox.add_child(icon_box)

		# Info VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
		info_vbox.add_theme_constant_override("separation", 3)

		var name_hbox = HBoxContainer.new()
		name_hbox.add_theme_constant_override("separation", 8)

		var name_lbl = Label.new()
		name_lbl.text = "Vé Hiệu Triệu"
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.40, 1.0))
		name_hbox.add_child(name_lbl)

		var tag_lbl = Label.new()
		tag_lbl.text = " [Lệnh Bài Thần Điện] "
		tag_lbl.add_theme_font_size_override("font_size", 11)
		tag_lbl.add_theme_color_override("font_color", Color(0.75, 0.65, 0.95, 1.0))
		name_hbox.add_child(tag_lbl)
		info_vbox.add_child(name_hbox)

		var desc_lbl = Label.new()
		desc_lbl.text = "Lệnh bài triệu hồi truyền thừa từ Thần Điện. Dùng để chiêu mộ và triệu hồi các bậc Danh Tướng, Hào Kiệt Đại Việt vào quân ngũ."
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_vbox.add_child(desc_lbl)
		item_hbox.add_child(info_vbox)

		# Số lượng badge
		var qty_vbox = VBoxContainer.new()
		qty_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		qty_vbox.custom_minimum_size = Vector2(90, 0)
		qty_vbox.add_theme_constant_override("separation", 2)

		var qty_title = Label.new()
		qty_title.text = "SỐ LƯỢNG"
		qty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_title.add_theme_font_size_override("font_size", 10)
		qty_title.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		qty_vbox.add_child(qty_title)

		var qty_val = Label.new()
		qty_val.text = "x%d" % tickets
		qty_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_val.add_theme_font_size_override("font_size", 18)
		qty_val.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		qty_vbox.add_child(qty_val)
		item_hbox.add_child(qty_vbox)

		# Action Buttons Container
		var act_vbox = VBoxContainer.new()
		act_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		act_vbox.add_theme_constant_override("separation", 6)

		# 1. Nút Chiêu Mộ 1 Vé
		var summon_1_btn = Button.new()
		summon_1_btn.custom_minimum_size = Vector2(140, 34)
		summon_1_btn.text = "⛩️ DÙNG (QUAY 1)"
		var s1_style = StyleBoxFlat.new()
		s1_style.bg_color = Color(0.92, 0.75, 0.22, 1.0)
		s1_style.corner_radius_top_left = 6
		s1_style.corner_radius_top_right = 6
		s1_style.corner_radius_bottom_right = 6
		s1_style.corner_radius_bottom_left = 6
		s1_style.shadow_color = Color(0.92, 0.75, 0.22, 0.4)
		s1_style.shadow_size = 4
		summon_1_btn.add_theme_stylebox_override("normal", s1_style)
		summon_1_btn.add_theme_stylebox_override("hover", s1_style)
		summon_1_btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02, 1.0))
		summon_1_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_execute_gacha_summon(1)
		)
		act_vbox.add_child(summon_1_btn)

		# 2. Nếu có >= 5 vé, thêm nút Quay 5
		if tickets >= 5:
			var summon_5_btn = Button.new()
			summon_5_btn.custom_minimum_size = Vector2(140, 30)
			summon_5_btn.text = "🌟 QUAY 5 VÉ"
			var s5_style = StyleBoxFlat.new()
			s5_style.bg_color = Color(0.85, 0.35, 0.20, 1.0)
			s5_style.corner_radius_top_left = 6
			s5_style.corner_radius_top_right = 6
			s5_style.corner_radius_bottom_right = 6
			s5_style.corner_radius_bottom_left = 6
			s5_style.shadow_color = Color(0.85, 0.35, 0.20, 0.4)
			s5_style.shadow_size = 4
			summon_5_btn.add_theme_stylebox_override("normal", s5_style)
			summon_5_btn.add_theme_stylebox_override("hover", s5_style)
			summon_5_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			summon_5_btn.pressed.connect(func():
				AudioManager.play_card_select()
				_execute_gacha_summon(5)
			)
			act_vbox.add_child(summon_5_btn)

		# 3. Nút Đến Thần Điện (cho ai muốn xem toàn cảnh Thần Điện)
		var goto_td_btn = Button.new()
		goto_td_btn.custom_minimum_size = Vector2(140, 28)
		goto_td_btn.text = "ĐẾN THẦN ĐIỆN ➜"
		_style_white_gold_button(goto_td_btn, 6, 2, Vector2(0, 1))
		goto_td_btn.pressed.connect(func():
			AudioManager.play_card_select()
			if is_instance_valid(modal_overlay):
				modal_overlay.visible = false
			_show_fullscreen_than_dien()
		)
		act_vbox.add_child(goto_td_btn)

		item_hbox.add_child(act_vbox)

		items_vbox.add_child(item_card)

	# Nếu không có vật phẩm nào (hoặc vé = 0)
	if not has_items:
		var empty_panel = PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(0, 220)
		empty_panel.size_flags_horizontal = SIZE_EXPAND_FILL
		var es = StyleBoxFlat.new()
		es.bg_color = Color(0.08, 0.07, 0.11, 0.85)
		es.border_width_left = 1
		es.border_width_top = 1
		es.border_width_right = 1
		es.border_width_bottom = 1
		es.border_color = Color(0.4, 0.35, 0.3, 0.5)
		es.corner_radius_top_left = 10
		es.corner_radius_top_right = 10
		es.corner_radius_bottom_right = 10
		es.corner_radius_bottom_left = 10
		empty_panel.add_theme_stylebox_override("panel", es)

		var ev = VBoxContainer.new()
		ev.alignment = BoxContainer.ALIGNMENT_CENTER
		ev.add_theme_constant_override("separation", 10)

		var e_icon = Label.new()
		e_icon.text = "🎒"
		e_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_icon.add_theme_font_size_override("font_size", 42)
		e_icon.modulate = Color(0.6, 0.6, 0.6, 0.7)
		ev.add_child(e_icon)

		var e_title = Label.new()
		e_title.text = "Túi đồ hiện đang trống"
		e_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_title.add_theme_font_size_override("font_size", 16)
		e_title.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		ev.add_child(e_title)

		var e_desc = Label.new()
		e_desc.text = "Tướng quân hiện chưa có vật phẩm hoặc Vé Hiệu Triệu nào trong túi đồ.\nHãy hoàn thành Quân Lệnh Triều Đình hoặc Điểm Danh 7 Ngày để nhận thêm vé và bổng lộc!"
		e_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		e_desc.add_theme_font_size_override("font_size", 12)
		e_desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.9))
		ev.add_child(e_desc)

		var btn_hbox = HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_hbox.add_theme_constant_override("separation", 12)

		var q_btn = Button.new()
		q_btn.custom_minimum_size = Vector2(160, 36)
		q_btn.text = "📜 NHIỆM VỤ NGÀY"
		_style_white_gold_button(q_btn, 6, 2, Vector2(0, 1))
		q_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_open_quests_modal()
		)
		btn_hbox.add_child(q_btn)

		var c_btn = Button.new()
		c_btn.custom_minimum_size = Vector2(160, 36)
		c_btn.text = "🎁 QUÀ 7 NGÀY"
		_style_white_gold_button(c_btn, 6, 2, Vector2(0, 1))
		c_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_show_modal("QUÀ ĐIỂM DANH 7 NGÀY", _build_7day_rewards_content())
		)
		btn_hbox.add_child(c_btn)

		var s_btn = Button.new()
		s_btn.custom_minimum_size = Vector2(160, 36)
		s_btn.text = "🛒 TRÂN BẢO CÁC"
		_style_white_gold_button(s_btn, 6, 2, Vector2(0, 1))
		s_btn.pressed.connect(func():
			AudioManager.play_card_select()
			_show_modal("TRÂN BẢO CÁC", _build_shop_content())
		)
		btn_hbox.add_child(s_btn)

		ev.add_child(btn_hbox)
		empty_panel.add_child(ev)
		items_vbox.add_child(empty_panel)

	container.add_child(scroll)
	return container

func _build_shop_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)

	var packs = [
		{"name": "Túi Bạc Tân Thủ", "icon": "🪙", "val": "10,000 Bạc", "price": "💎 100 Vàng"},
		{"name": "Rương Binh Khí Hiếm", "icon": "🎒", "val": "Khiên Mây + Nỏ Thần", "price": "💎 350 Vàng"},
		{"name": "Gói Triệu Hồi Danh Tướng", "icon": "🎖️", "val": "Tướng 4 Sao Ngẫu Nhiên", "price": "💎 500 Vàng"},
	]

	for p in packs:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(230, 160)
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.96, 0.95, 0.91, 1.0)
		ps.border_width_left = 2
		ps.border_width_top = 2
		ps.border_width_right = 2
		ps.border_width_bottom = 2
		ps.border_color = COLOR_GOLD_PRIMARY
		ps.corner_radius_top_left = 8
		ps.corner_radius_top_right = 8
		ps.corner_radius_bottom_right = 8
		ps.corner_radius_bottom_left = 8
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 5
		ps.shadow_offset = Vector2(0, 3)
		panel.add_theme_stylebox_override("panel", ps)

		var pv = VBoxContainer.new()
		pv.offset_left = 10
		pv.offset_right = -10
		pv.offset_top = 10
		pv.offset_bottom = -10
		pv.add_theme_constant_override("separation", 6)
		pv.alignment = BoxContainer.ALIGNMENT_CENTER

		var ic = Label.new()
		ic.text = p["icon"]
		ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic.add_theme_font_size_override("font_size", 30)
		pv.add_child(ic)

		var pn = Label.new()
		pn.text = p["name"]
		pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pn.add_theme_font_size_override("font_size", 14)
		pn.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		pv.add_child(pn)

		var pv_lbl = Label.new()
		pv_lbl.text = p["val"]
		pv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv_lbl.add_theme_font_size_override("font_size", 12)
		pv_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		pv.add_child(pv_lbl)

		var buy_btn = Button.new()
		buy_btn.text = "MUA (%s)" % p["price"]
		_style_white_gold_button(buy_btn, 6, 3, Vector2(0, 2))
		buy_btn.pressed.connect(func():
			AudioManager.play_parry()
			buy_btn.text = "✔ THÀNH CÔNG"
		)
		pv.add_child(buy_btn)

		panel.add_child(pv)
		grid.add_child(panel)

	container.add_child(grid)
	return container

func _build_mail_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)

	var letters = [
		{"from": "Triều Đình Đại Việt", "sub": "Chiếu chỉ ban tặng bổng lộc tân chiến tướng", "gift": "🥈 5,000 Bạc"},
		{"from": "Hệ Thống 2v2", "sub": "Thưởng mùa giải Hoàng Triều Khởi Đấu", "gift": "🥈 2,000 Bạc"},
	]

	for l in letters:
		var panel = PanelContainer.new()
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.96, 0.95, 0.91, 1.0)
		ps.border_width_left = 2
		ps.border_color = COLOR_GOLD_PRIMARY
		ps.corner_radius_top_left = 6
		ps.corner_radius_bottom_left = 6
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 4
		ps.shadow_offset = Vector2(0, 2)
		panel.add_theme_stylebox_override("panel", ps)

		var row = HBoxContainer.new()
		row.offset_left = 14
		row.offset_right = -14
		row.offset_top = 8
		row.offset_bottom = -8
		row.add_theme_constant_override("separation", 12)

		var icon = Label.new()
		icon.text = "✉️"
		icon.add_theme_font_size_override("font_size", 18)
		row.add_child(icon)

		var v = VBoxContainer.new()
		v.size_flags_horizontal = SIZE_EXPAND_FILL

		var sub_lbl = Label.new()
		sub_lbl.text = l["sub"]
		sub_lbl.add_theme_font_size_override("font_size", 13)
		sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		v.add_child(sub_lbl)

		var from_lbl = Label.new()
		from_lbl.text = "Gửi từ: %s | Phần thưởng: %s" % [l["from"], l["gift"]]
		from_lbl.add_theme_font_size_override("font_size", 11)
		from_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		v.add_child(from_lbl)
		row.add_child(v)

		var r_btn = Button.new()
		r_btn.custom_minimum_size = Vector2(100, 34)
		r_btn.text = "NHẬN ➜"
		_style_white_gold_button(r_btn, 6, 3, Vector2(0, 2))
		r_btn.pressed.connect(func():
			AudioManager.play_parry()
			r_btn.text = "ĐÃ NHẬN"
			r_btn.disabled = true
		)
		row.add_child(r_btn)

		panel.add_child(row)
		container.add_child(panel)

	return container

func _build_settings_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 16)

	# Audio Sliders
	var sliders = [
		{"name": "Âm lượng Nhạc Nền (BGM)", "bus": "Master", "val": 80},
		{"name": "Âm lượng Hiệu Ứng (SFX)", "bus": "Master", "val": 90},
		{"name": "Âm lượng Giọng Nói Tướng (Voice)", "bus": "Master", "val": 95},
	]

	for s in sliders:
		var v = VBoxContainer.new()
		var l = Label.new()
		l.text = s["name"]
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		v.add_child(l)

		var hslider = HSlider.new()
		hslider.min_value = 0
		hslider.max_value = 100
		hslider.value = s["val"]
		v.add_child(hslider)
		container.add_child(v)

	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 1)
	div.color = COLOR_GOLD_PRIMARY
	container.add_child(div)

	# UI Scale Section
	var scale_v = VBoxContainer.new()
	scale_v.add_theme_constant_override("separation", 8)
	var scale_lbl = Label.new()
	scale_lbl.text = "📱 TỈ LỆ CHỮ & GIAO DIỆN (UI SCALE):"
	scale_lbl.add_theme_font_size_override("font_size", 13)
	scale_lbl.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	scale_v.add_child(scale_lbl)

	var scale_hbox = HBoxContainer.new()
	scale_hbox.add_theme_constant_override("separation", 8)

	var scale_options = [
		{"label": "Chuẩn PC (100%)", "scale": 1.0},
		{"label": "Mobile (125%)", "scale": 1.25},
		{"label": "Chữ Lớn (135%)", "scale": 1.35},
	]

	var current_s = UIScaleManager.current_scale if is_instance_valid(UIScaleManager) else 1.0
	for opt in scale_options:
		var btn = Button.new()
		btn.text = opt["label"]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_size_override("font_size", 11)
		var is_active = is_equal_approx(current_s, opt["scale"])
		_style_leaderboard_tab_button(btn, is_active)
		var target_scale = opt["scale"]
		btn.pressed.connect(func():
			if is_instance_valid(UIScaleManager):
				UIScaleManager.set_scale_factor(target_scale)
				_show_modal("THIẾT LẬP CHIẾN TRƯỜNG", _build_settings_content())
		)
		scale_hbox.add_child(btn)

	scale_v.add_child(scale_hbox)
	container.add_child(scale_v)

	var div_scale = ColorRect.new()
	div_scale.custom_minimum_size = Vector2(0, 1)
	div_scale.color = COLOR_GOLD_PRIMARY
	container.add_child(div_scale)

	# Realtime match and draft state always use the shared online server.
	var srv_v = VBoxContainer.new()
	srv_v.add_theme_constant_override("separation", 6)
	var srv_lbl = Label.new()
	srv_lbl.text = "🌐"
	srv_lbl.add_theme_font_size_override("font_size", 13)
	srv_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	srv_v.add_child(srv_lbl)

	var srv_value = Label.new()
	srv_value.text = "Khởi Nguyên Studio: Đại Việt Chiến"
	srv_value.add_theme_font_size_override("font_size", 12)
	srv_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	srv_v.add_child(srv_value)
	container.add_child(srv_v)

	var div2 = ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = COLOR_GOLD_PRIMARY
	container.add_child(div2)

	# Logout Button
	var logout_btn = Button.new()
	logout_btn.custom_minimum_size = Vector2(0, 42)
	logout_btn.text = "🚪 ĐĂNG XUẤT TÀI KHOẢN"
	_style_white_gold_button(logout_btn, 8, 4, Vector2(0, 2))
	logout_btn.pressed.connect(func():
		AudioManager.play_card_select()
		if AuthManager:
			AuthManager.delete_current_session(func():
				get_tree().change_scene_to_file("res://scenes/auth_login.tscn")
			)
		else:
			get_tree().change_scene_to_file("res://scenes/auth_login.tscn")
	)
	container.add_child(logout_btn)

	return container

func _build_profile_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	# --- BANNER TÊN CHIẾN TƯỚNG ---
	var name_panel = PanelContainer.new()
	var np_style = StyleBoxFlat.new()
	np_style.bg_color = Color(0.04, 0.06, 0.10, 0.95)
	np_style.border_width_left = 1
	np_style.border_width_top = 1
	np_style.border_width_right = 1
	np_style.border_width_bottom = 1
	np_style.border_color = Color(0.85, 0.70, 0.25, 0.6)
	np_style.corner_radius_top_left = 8
	np_style.corner_radius_top_right = 8
	np_style.corner_radius_bottom_right = 8
	np_style.corner_radius_bottom_left = 8
	name_panel.add_theme_stylebox_override("panel", np_style)

	var np_margin = MarginContainer.new()
	np_margin.add_theme_constant_override("margin_top", 6)
	np_margin.add_theme_constant_override("margin_bottom", 6)
	np_margin.add_theme_constant_override("margin_left", 14)
	np_margin.add_theme_constant_override("margin_right", 14)
	name_panel.add_child(np_margin)

	var name_hbox = HBoxContainer.new()
	name_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	name_hbox.add_theme_constant_override("separation", 8)
	np_margin.add_child(name_hbox)

	var user_name_str = player_name_label.text if is_instance_valid(player_name_label) else "ĐẠI TƯỚNG QUÂN"
	if AuthManager and AuthManager.current_user_name != "":
		user_name_str = AuthManager.current_user_name

	var name_lbl = Label.new()
	name_lbl.text = "👑 " + user_name_str.to_upper()
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_hbox.add_child(name_lbl)

	var title_tag = Label.new()
	title_tag.text = "• CHIẾN TƯỚNG ĐẠI VIỆT"
	title_tag.add_theme_font_size_override("font_size", 12)
	title_tag.add_theme_color_override("font_color", Color(0.70, 0.78, 0.88, 0.85))
	name_hbox.add_child(title_tag)

	container.add_child(name_panel)

	# --- 1. MỤC CẤP ĐỘ ---
	var lvl = AuthManager.current_level if AuthManager else 1
	var exp_c = AuthManager.current_exp if AuthManager else 0
	var exp_req = AuthManager.get_exp_to_next_level() if AuthManager else 20
	var exp_pct = int(clampf(float(exp_c) / max(1, exp_req) * 100.0, 0.0, 100.0))

	var exp_vbox = VBoxContainer.new()
	exp_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	exp_vbox.add_theme_constant_override("separation", 3)

	var exp_lbl = Label.new()
	exp_lbl.text = "Tiến độ: %d / %d EXP (%d%%)" % [exp_c, exp_req, exp_pct]
	exp_lbl.add_theme_font_size_override("font_size", 11)
	exp_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	exp_vbox.add_child(exp_lbl)

	var exp_pbar = ProgressBar.new()
	exp_pbar.custom_minimum_size = Vector2(0, 10)
	exp_pbar.max_value = exp_req
	exp_pbar.value = exp_c
	exp_pbar.show_percentage = false
	var p_bg = StyleBoxFlat.new()
	p_bg.bg_color = Color(0.08, 0.11, 0.18, 0.9)
	p_bg.corner_radius_top_left = 5
	p_bg.corner_radius_top_right = 5
	p_bg.corner_radius_bottom_right = 5
	p_bg.corner_radius_bottom_left = 5
	var p_fg = StyleBoxFlat.new()
	p_fg.bg_color = Color(0.25, 0.75, 0.95, 1.0)
	p_fg.corner_radius_top_left = 5
	p_fg.corner_radius_top_right = 5
	p_fg.corner_radius_bottom_right = 5
	p_fg.corner_radius_bottom_left = 5
	exp_pbar.add_theme_stylebox_override("background", p_bg)
	exp_pbar.add_theme_stylebox_override("fill", p_fg)
	exp_vbox.add_child(exp_pbar)

	var lvl_icon = Label.new()
	lvl_icon.text = "⭐"
	lvl_icon.add_theme_font_size_override("font_size", 20)
	lvl_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	container.add_child(_create_profile_card_row(
		lvl_icon,
		"CẤP ĐỘ CHIẾN TƯỚNG",
		"CẤP %d" % lvl,
		Color(1.0, 0.90, 0.35),
		exp_vbox
	))

	# --- 2. MỤC QUÂN HÀM ---
	var mil_info = AuthManager.get_military_rank_info() if AuthManager else {"badge": "🔰", "name": "Tân Binh", "tier": 1, "points": 5, "next_min": 100}
	var mil_pts = mil_info.get("points", 0)
	var mil_next = max(1, mil_info.get("next_min", 100))
	var mil_pct = int(clampf(float(mil_pts) / float(mil_next) * 100.0, 0.0, 100.0))

	var mil_vbox = VBoxContainer.new()
	mil_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mil_vbox.add_theme_constant_override("separation", 3)

	var mil_lbl = Label.new()
	mil_lbl.text = "Chiến công: %d / %d điểm (%d%%)" % [mil_pts, mil_next, mil_pct]
	mil_lbl.add_theme_font_size_override("font_size", 11)
	mil_lbl.add_theme_color_override("font_color", Color(0.88, 0.82, 0.70))
	mil_vbox.add_child(mil_lbl)

	var mil_pbar = ProgressBar.new()
	mil_pbar.custom_minimum_size = Vector2(0, 10)
	mil_pbar.max_value = mil_next
	mil_pbar.value = mil_pts
	mil_pbar.show_percentage = false
	var m_fg = StyleBoxFlat.new()
	m_fg.bg_color = Color(0.90, 0.70, 0.22, 1.0)
	m_fg.corner_radius_top_left = 5
	m_fg.corner_radius_top_right = 5
	m_fg.corner_radius_bottom_right = 5
	m_fg.corner_radius_bottom_left = 5
	mil_pbar.add_theme_stylebox_override("background", p_bg)
	mil_pbar.add_theme_stylebox_override("fill", m_fg)
	mil_vbox.add_child(mil_pbar)

	var mil_icon = Label.new()
	mil_icon.text = mil_info.get("badge", "🔰")
	mil_icon.add_theme_font_size_override("font_size", 20)
	mil_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	container.add_child(_create_profile_card_row(
		mil_icon,
		"QUÂN HÀM TRIỀU ĐÌNH",
		"%s (BẬC %d/12)" % [mil_info.get("name", "Tân Binh").to_upper(), mil_info.get("tier", 1)],
		Color(0.95, 0.85, 0.45),
		mil_vbox
	))

	# --- 3. MỤC TỈ LỆ THẮNG ---
	var wins = 0
	var losses = 0
	if AuthManager:
		wins = AuthManager.current_wins
		losses = AuthManager.current_losses
	var total_matches = wins + losses
	var rate_val = (float(wins) / float(total_matches) * 100.0) if total_matches > 0 else 0.0

	var win_vbox = VBoxContainer.new()
	win_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	win_vbox.add_theme_constant_override("separation", 3)

	var win_lbl = Label.new()
	if total_matches > 0:
		win_lbl.text = "%d Thắng  •  %d Bại (Tổng: %d trận)" % [wins, losses, total_matches]
	else:
		win_lbl.text = "Chưa tham gia đấu trận (0/0)"
	win_lbl.add_theme_font_size_override("font_size", 11)
	win_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	win_vbox.add_child(win_lbl)

	var win_pbar = ProgressBar.new()
	win_pbar.custom_minimum_size = Vector2(0, 10)
	win_pbar.max_value = 100.0
	win_pbar.value = rate_val if total_matches > 0 else 0.0
	win_pbar.show_percentage = false
	var w_bg = StyleBoxFlat.new()
	w_bg.bg_color = Color(0.65, 0.20, 0.20, 0.85) if total_matches > 0 else Color(0.08, 0.11, 0.18, 0.9)
	w_bg.corner_radius_top_left = 5
	w_bg.corner_radius_top_right = 5
	w_bg.corner_radius_bottom_right = 5
	w_bg.corner_radius_bottom_left = 5
	var w_fg = StyleBoxFlat.new()
	w_fg.bg_color = Color(0.20, 0.85, 0.40, 1.0)
	w_fg.corner_radius_top_left = 5
	w_fg.corner_radius_top_right = 5
	w_fg.corner_radius_bottom_right = 5
	w_fg.corner_radius_bottom_left = 5
	win_pbar.add_theme_stylebox_override("background", w_bg)
	win_pbar.add_theme_stylebox_override("fill", w_fg)
	win_vbox.add_child(win_pbar)

	var win_icon = Label.new()
	win_icon.text = "⚔️"
	win_icon.add_theme_font_size_override("font_size", 20)
	win_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	container.add_child(_create_profile_card_row(
		win_icon,
		"TỈ LỆ THẮNG TRẬN",
		"%.1f%%" % rate_val if total_matches > 0 else "0.0%",
		Color(0.35, 0.95, 0.45) if rate_val >= 50.0 else Color(1.0, 0.45, 0.45),
		win_vbox
	))

	# --- 4. MỤC HẠNG 2v2 ---
	var rank_idx = AuthManager.current_2v2_rank_index if AuthManager else 0
	var rank_stars = AuthManager.current_2v2_stars if AuthManager else 0
	var rank_acc = AuthManager.current_2v2_accumulation_points if AuthManager else 0
	var rank_info = RankSystem.get_rank_info(rank_idx) if RankSystem else {}
	var r_color = rank_info.get("color", Color(1.0, 0.85, 0.4))

	var badge_tex = TextureRect.new()
	badge_tex.custom_minimum_size = Vector2(36, 36)
	badge_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var r_path = RankSystem.get_rank_icon_path(rank_idx) if RankSystem else ""
	if ResourceLoader.exists(r_path):
		badge_tex.texture = load(r_path)

	var rank_vbox = VBoxContainer.new()
	rank_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_vbox.add_theme_constant_override("separation", 2)

	var stars_hbox = HBoxContainer.new()
	stars_hbox.add_theme_constant_override("separation", 3)
	for s in range(5):
		var s_lbl = Label.new()
		s_lbl.text = "★"
		s_lbl.add_theme_font_size_override("font_size", 15)
		if s < rank_stars:
			s_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
			s_lbl.add_theme_color_override("font_shadow_color", Color(0.9, 0.6, 0.1, 0.7))
		else:
			s_lbl.add_theme_color_override("font_color", Color(0.25, 0.28, 0.38, 0.8))
		stars_hbox.add_child(s_lbl)

	var s_count = Label.new()
	s_count.text = "  %d/5 Sao" % rank_stars
	s_count.add_theme_font_size_override("font_size", 11)
	s_count.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	stars_hbox.add_child(s_count)
	rank_vbox.add_child(stars_hbox)

	var acc_lbl = Label.new()
	acc_lbl.text = "Tích lũy dũng cảm: %d/100đ" % rank_acc
	acc_lbl.add_theme_font_size_override("font_size", 11)
	acc_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	rank_vbox.add_child(acc_lbl)

	container.add_child(_create_profile_card_row(
		badge_tex,
		"ĐẤU TRƯỜNG 2v2 XẾP HẠNG",
		RankSystem.get_rank_name(rank_idx).to_upper() if RankSystem else "DÂN BINH",
		r_color,
		rank_vbox
	))

	return container

func _create_profile_card_row(icon_node: Control, title_text: String, main_val_text: String, main_val_color: Color, sub_widget: Control) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 68)
	var cs = StyleBoxFlat.new()
	cs.bg_color = Color(0.06, 0.08, 0.14, 0.95)
	cs.border_width_left = 1
	cs.border_width_top = 1
	cs.border_width_right = 1
	cs.border_width_bottom = 1
	cs.border_color = Color(0.85, 0.70, 0.25, 0.35)
	cs.corner_radius_top_left = 10
	cs.corner_radius_top_right = 10
	cs.corner_radius_bottom_right = 10
	cs.corner_radius_bottom_left = 10
	cs.shadow_color = Color(0, 0, 0, 0.5)
	cs.shadow_size = 4
	cs.shadow_offset = Vector2(0, 2)
	card.add_theme_stylebox_override("panel", cs)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)

	# 1. Khung Icon bên trái
	var icon_box = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(44, 44)
	var ib_style = StyleBoxFlat.new()
	ib_style.bg_color = Color(0.12, 0.15, 0.22, 0.9)
	ib_style.border_width_left = 1
	ib_style.border_width_top = 1
	ib_style.border_width_right = 1
	ib_style.border_width_bottom = 1
	ib_style.border_color = Color(0.9, 0.75, 0.3, 0.5)
	ib_style.corner_radius_top_left = 8
	ib_style.corner_radius_top_right = 8
	ib_style.corner_radius_bottom_right = 8
	ib_style.corner_radius_bottom_left = 8
	icon_box.add_theme_stylebox_override("panel", ib_style)

	icon_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_box.add_child(icon_node)
	hbox.add_child(icon_box)

	# 2. Thông tin chính ở giữa
	var mid_vbox = VBoxContainer.new()
	mid_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_vbox.add_theme_constant_override("separation", 2)
	mid_vbox.custom_minimum_size = Vector2(175, 0)

	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85, 0.9))
	mid_vbox.add_child(t_lbl)

	var v_lbl = Label.new()
	v_lbl.text = main_val_text
	v_lbl.add_theme_font_size_override("font_size", 15)
	v_lbl.add_theme_color_override("font_color", main_val_color)
	v_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	v_lbl.add_theme_constant_override("shadow_offset_y", 1)
	mid_vbox.add_child(v_lbl)

	hbox.add_child(mid_vbox)

	# Vách ngăn dọc
	var sep = VSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.4, 0.5, 0.65, 0.25)
	sep_style.vertical = true
	sep.add_theme_stylebox_override("separator", sep_style)
	hbox.add_child(sep)

	# 3. Widget chi tiết bên phải
	sub_widget.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sub_widget)

	return card

func _build_2v2_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var lbl = Label.new()
	lbl.text = "Sảnh Ghép Đội Đấu Trường 2v2 Xếp Hạng:"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	container.add_child(lbl)

	var desc = Label.new()
	desc.text = "Hệ thống sẽ ghép ngẫu nhiên 4 danh tướng chia làm 2 phe đối đầu theo luật bài tiêu chuẩn Đại Việt."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	container.add_child(desc)

	var play_btn = Button.new()
	play_btn.custom_minimum_size = Vector2(0, 48)
	play_btn.text = "⚔️ TÌM TRẬN 2v2 XẾP HẠNG"
	_style_white_gold_action_button(play_btn)
	play_btn.pressed.connect(func():
		_start_2v2_matchmaking()
	)
	container.add_child(play_btn)

	return container

# --- 2v2 Real-Player Matchmaking System (Appwrite Singapore) ---
func _mode_player_count(mode_id: String) -> int:
	return 5 if mode_id == "dynasty_5" else (8 if mode_id == "dynasty_8" else 4)

func _start_2v2_matchmaking(mode_id: String = "2v2") -> void:
	_cancel_matchmaking_internal()
	var target_player_count := _mode_player_count(mode_id)
	var mode_title := "VƯƠNG TRIỀU %d NGƯỜI" % target_player_count if target_player_count > 4 else "2v2 XẾP HẠNG"

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 18)

	# Lấy thông tin Rank và Số Sao của người chơi
	var rank_idx = 0
	var rank_stars = 0
	if AuthManager:
		rank_idx = AuthManager.current_2v2_rank_index
		rank_stars = AuthManager.current_2v2_stars

	var rank_name = "Dân Binh"
	var rank_icon_path = "res://assets/ui/ranks/dan_binh.png"
	var rank_color = Color(1.0, 0.85, 0.4)
	if RankSystem:
		var rank_info = RankSystem.get_rank_info(rank_idx)
		rank_name = RankSystem.get_rank_name(rank_idx)
		rank_icon_path = RankSystem.get_rank_icon_path(rank_idx)
		rank_color = rank_info.get("color", Color(1.0, 0.85, 0.4))

	# 1. Matchmaking Status Card (Bên trái: Rank & Sao & Chức vị; Bên phải: Đang tìm trận & Số giây)
	var search_card = PanelContainer.new()
	search_card.custom_minimum_size = Vector2(500, 160)
	var sc_style = StyleBoxFlat.new()
	sc_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
	sc_style.border_width_left = 1
	sc_style.border_width_top = 1
	sc_style.border_width_right = 1
	sc_style.border_width_bottom = 1
	sc_style.border_color = COLOR_GOLD_PRIMARY
	sc_style.corner_radius_top_left = 12
	sc_style.corner_radius_top_right = 12
	sc_style.corner_radius_bottom_right = 12
	sc_style.corner_radius_bottom_left = 12
	sc_style.shadow_color = Color(0, 0, 0, 0.5)
	sc_style.shadow_size = 6
	sc_style.shadow_offset = Vector2(0, 3)
	search_card.add_theme_stylebox_override("panel", sc_style)

	var sc_margin = MarginContainer.new()
	sc_margin.add_theme_constant_override("margin_left", 24)
	sc_margin.add_theme_constant_override("margin_right", 24)
	sc_margin.add_theme_constant_override("margin_top", 16)
	sc_margin.add_theme_constant_override("margin_bottom", 16)
	search_card.add_child(sc_margin)

	var main_hbox = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_theme_constant_override("separation", 28)
	sc_margin.add_child(main_hbox)

	# --- CỘT TRÁI: HÌNH RANK -> SỐ SAO (SÁNG / TỐI) -> TÊN CHỨC RANK ---
	var rank_col = VBoxContainer.new()
	rank_col.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_col.custom_minimum_size = Vector2(160, 0)
	rank_col.add_theme_constant_override("separation", 6)
	main_hbox.add_child(rank_col)

	# 1. Hình của rank tương ứng
	var rank_icon_rect = TextureRect.new()
	rank_icon_rect.custom_minimum_size = Vector2(88, 88)
	rank_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rank_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rank_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(rank_icon_path):
		rank_icon_rect.texture = load(rank_icon_path)
	rank_col.add_child(rank_icon_rect)

	# 2. Số sao bên dưới hình (Ví dụ 3/5 sao thì 3 sao sáng, 2 sao tối)
	var stars_hbox = HBoxContainer.new()
	stars_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_hbox.add_theme_constant_override("separation", 4)
	if rank_idx >= 11:
		# Bậc Hoàng Đế (vô hạn sao)
		var star_lbl = Label.new()
		star_lbl.text = "★"
		star_lbl.add_theme_font_size_override("font_size", 20)
		star_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
		stars_hbox.add_child(star_lbl)
		var count_lbl = Label.new()
		count_lbl.text = "x %d" % rank_stars
		count_lbl.add_theme_font_size_override("font_size", 16)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
		stars_hbox.add_child(count_lbl)
	else:
		var max_stars = 5
		for s in range(max_stars):
			var star_lbl = Label.new()
			star_lbl.text = "★"
			star_lbl.add_theme_font_size_override("font_size", 20)
			if s < rank_stars:
				# Sao sáng (màu vàng kim rực rỡ)
				star_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
				star_lbl.add_theme_color_override("font_shadow_color", Color(0.9, 0.6, 0.1, 0.7))
				star_lbl.add_theme_constant_override("shadow_offset_x", 0)
				star_lbl.add_theme_constant_override("shadow_offset_y", 1)
			else:
				# Sao tối (màu xám tối)
				star_lbl.add_theme_color_override("font_color", Color(0.25, 0.28, 0.38, 0.8))
			stars_hbox.add_child(star_lbl)
	rank_col.add_child(stars_hbox)

	# 3. Ghi chức của rank bên dưới
	var rank_name_lbl = Label.new()
	rank_name_lbl.text = rank_name.to_upper()
	rank_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_name_lbl.add_theme_font_size_override("font_size", 16)
	rank_name_lbl.add_theme_color_override("font_color", rank_color)
	rank_name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	rank_name_lbl.add_theme_constant_override("shadow_offset_x", 0)
	rank_name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	rank_col.add_child(rank_name_lbl)

	# --- ĐƯỜNG PHÂN CÁCH DỌC ---
	var sep = VSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(0.4, 0.48, 0.6, 0.3)
	sep_style.vertical = true
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	sep.custom_minimum_size = Vector2(1, 110)
	main_hbox.add_child(sep)

	# --- CỘT PHẢI: HIỆN ĐANG TÌM TRẬN VÀ SỐ GIÂY ---
	var status_col = VBoxContainer.new()
	status_col.alignment = BoxContainer.ALIGNMENT_CENTER
	status_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_col.add_theme_constant_override("separation", 14)
	main_hbox.add_child(status_col)

	var status_lbl = Label.new()
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.text = "🔍 Đang tìm trận..."
	status_lbl.add_theme_font_size_override("font_size", 18)
	status_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	status_col.add_child(status_lbl)

	var timer_badge = PanelContainer.new()
	timer_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.04, 0.07, 0.12, 0.95)
	tb_style.border_width_left = 1
	tb_style.border_width_top = 1
	tb_style.border_width_right = 1
	tb_style.border_width_bottom = 1
	tb_style.border_color = Color(0.35, 0.75, 0.95, 0.8)
	tb_style.corner_radius_top_left = 6
	tb_style.corner_radius_top_right = 6
	tb_style.corner_radius_bottom_right = 6
	tb_style.corner_radius_bottom_left = 6
	timer_badge.add_theme_stylebox_override("panel", tb_style)

	var tb_margin = MarginContainer.new()
	tb_margin.add_theme_constant_override("margin_left", 24)
	tb_margin.add_theme_constant_override("margin_right", 24)
	tb_margin.add_theme_constant_override("margin_top", 6)
	tb_margin.add_theme_constant_override("margin_bottom", 6)
	timer_badge.add_child(tb_margin)

	var timer_lbl = Label.new()
	timer_lbl.text = "⏳ 00:00"
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_lbl.add_theme_font_size_override("font_size", 22)
	timer_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1.0))
	tb_margin.add_child(timer_lbl)
	status_col.add_child(timer_badge)

	container.add_child(search_card)

	# 2. Cancel Button
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(btn_hbox)

	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(260, 44)
	cancel_btn.text = "✕ HỦY TÌM TRẬN"
	_style_cancel_red_button(cancel_btn)
	cancel_btn.pressed.connect(func():
		AudioManager.play_card_select()
		_cancel_2v2_matchmaking()
	)
	btn_hbox.add_child(cancel_btn)

	var slot_nodes: Array = []

	_show_modal("⚔️ TÌM TRẬN %s" % mode_title, container)

	is_matchmaking_active = true
	mm_is_cancelled = false
	mm_search_started_at_ms = Time.get_ticks_msec()
	mm_active_room_id = ""
	mm_is_host = false
	mm_current_room = {}
	mm_session_user_id = ""
	if AppwriteMatchmaking:
		AppwriteMatchmaking.current_room = {}
		AppwriteMatchmaking.my_session_user_id = ""
		AppwriteMatchmaking.my_session_user_name = ""

	_run_2v2_matchmaking_loop(status_lbl, timer_lbl, slot_nodes, mode_id, target_player_count)
	_update_matchmaking_timer(timer_lbl)

func _update_matchmaking_timer(timer_lbl: Label) -> void:
	while is_matchmaking_active and not mm_is_cancelled and is_instance_valid(timer_lbl):
		var elapsed = max(0, int((Time.get_ticks_msec() - mm_search_started_at_ms) / 1000))
		timer_lbl.text = "⏳ %02d:%02d" % [elapsed / 60, elapsed % 60]
		await get_tree().create_timer(1.0).timeout

func _style_cancel_red_button(btn: Button) -> void:
	var norm = StyleBoxFlat.new()
	norm.bg_color = Color(0.80, 0.20, 0.22, 1.0)
	norm.border_width_left = 2
	norm.border_width_top = 2
	norm.border_width_right = 2
	norm.border_width_bottom = 2
	norm.border_color = Color(1.0, 0.85, 0.35, 0.9)
	norm.corner_radius_top_left = 8
	norm.corner_radius_top_right = 8
	norm.corner_radius_bottom_right = 8
	norm.corner_radius_bottom_left = 8
	norm.shadow_color = Color(0, 0, 0, 0.4)
	norm.shadow_size = 5
	norm.shadow_offset = Vector2(0, 3)

	var hov = norm.duplicate()
	hov.bg_color = Color(0.92, 0.26, 0.28, 1.0)
	hov.border_color = Color(1.0, 0.95, 0.6, 1.0)

	var press = norm.duplicate()
	press.bg_color = Color(0.68, 0.15, 0.18, 1.0)

	btn.add_theme_stylebox_override("normal", norm)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", press)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 14)

func _cancel_2v2_matchmaking() -> void:
	_cancel_matchmaking_internal()
	_hide_modal()

func _update_matchmaking_status_count(status_lbl: Label, room: Dictionary, _time_remaining: float = -1.0) -> void:
	if not is_instance_valid(status_lbl):
		return
	var count = 1
	var slots = room.get("slots", [])
	if slots is Array and not slots.is_empty():
		var non_empty = 0
		for s in slots:
			if s is Dictionary and not s.get("isEmpty", false) and s.get("userId", "") != "" and s.get("userId", "") != "empty":
				non_empty += 1
		count = clampi(non_empty, 1, maxi(4, slots.size()))
	var target_count = maxi(4, slots.size())
	if count >= target_count:
		status_lbl.text = "⚔️ Đã tìm thấy trận đấu! Đang vào trận..."
		status_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
	else:
		status_lbl.text = "🔍 Đang tìm trận..."
		status_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))

func _update_matchmaking_slots_visual(room: Dictionary, my_user_id: String, slot_nodes: Array) -> void:
	if room.is_empty():
		return
	var slots = room.get("slots", [])
	for i in range(slot_nodes.size()):
		if i >= slot_nodes.size():
			break
		var node_dict = slot_nodes[i]
		var sp_style: StyleBoxFlat = node_dict.get("style", null)
		var name_l: Label = node_dict.get("name_lbl", null)
		var status_l: Label = node_dict.get("status_lbl", null)
		var rank_l: Label = node_dict.get("rank_lbl", null)
		var t_badge: Label = node_dict.get("team_badge", null)

		if not is_instance_valid(name_l) or not is_instance_valid(status_l) or not is_instance_valid(rank_l) or not is_instance_valid(sp_style):
			continue

		if i < slots.size():
			var s = slots[i]
			if not (s is Dictionary):
				continue
			var is_empty = bool(s.get("isEmpty", false)) or s.get("userId", "") == "" or s.get("userId", "") == "empty"
			var is_drag = bool(s.get("isDragon", (i == 0 or i == 2)))
			var is_ai = bool(s.get("isAI", false))
			var my_user_name = AuthManager.current_user_name if AuthManager else ""
			var is_me = false
			if AppwriteMatchmaking:
				is_me = AppwriteMatchmaking.is_same_user(s.get("userId", ""), s.get("userName", ""), my_user_id, my_user_name)
			else:
				is_me = (s.get("userId", "") == my_user_id)

			if is_empty:
				name_l.text = "Ghế %d: Đang tìm người chơi..." % (i + 1)
				name_l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75, 1.0))
				status_l.text = "⏳ Đang tìm kiếm..."
				status_l.add_theme_color_override("font_color", Color(0.45, 0.52, 0.65, 1.0))
				rank_l.text = ""
				sp_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
				sp_style.border_color = Color(0.2, 0.28, 0.4, 0.7)
			else:
				# Hiển thị tên người chơi rõ ràng
				var uname = s.get("userName", "").strip_edges()
				if is_me:
					name_l.text = "BẠN (%s)" % (uname if not uname.is_empty() else "Tôi")
					name_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
					sp_style.bg_color = Color(0.1, 0.22, 0.38, 0.95)
					sp_style.border_color = COLOR_GOLD_PRIMARY
				elif is_drag:
					name_l.text = uname if not uname.is_empty() else ("Người chơi %d" % (i + 1))
					name_l.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0, 1.0))
					sp_style.bg_color = Color(0.07, 0.16, 0.26, 0.95)
					sp_style.border_color = Color(0.25, 0.65, 0.95, 0.8)
				else:
					name_l.text = uname if not uname.is_empty() else ("Người chơi %d" % (i + 1))
					name_l.add_theme_color_override("font_color", Color(1.0, 0.75, 0.8, 1.0))
					sp_style.bg_color = Color(0.22, 0.08, 0.12, 0.95)
					sp_style.border_color = Color(0.9, 0.35, 0.45, 0.8)

				status_l.text = "✅ ĐÃ SẴN SÀNG"
				status_l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
				rank_l.text = ""

func _sync_my_seat_from_room(room_data: Dictionary, my_uid: String, my_name: String) -> void:
	if not NetworkClient or room_data.is_empty():
		return
	var slots = room_data.get("slots", [])
	for idx in range(slots.size()):
		var sl = slots[idx]
		if AppwriteMatchmaking and AppwriteMatchmaking.is_same_user(str(sl.get("userId", "")), str(sl.get("userName", "")), my_uid, my_name):
			NetworkClient.my_seat = idx + 1
			NetworkClient.update_debug_window_title(my_name)
			return

func _run_2v2_matchmaking_loop(status_lbl: Label, timer_lbl: Label, slot_nodes: Array, mode_id: String = "2v2", target_player_count: int = 4) -> void:
	var base_uid = AuthManager.current_user_id if AuthManager and AuthManager.current_user_id != "" else ""
	var pid_suffix = str(OS.get_process_id())
	var my_user_id = base_uid
	if OS.is_debug_build() or base_uid.is_empty():
		my_user_id = (base_uid if not base_uid.is_empty() else "guest") + "_" + pid_suffix
	mm_session_user_id = my_user_id

	var my_user_name = AuthManager.current_user_name if AuthManager and AuthManager.current_user_name != "" else ""
	if (my_user_name == "" or my_user_name == "Đại Tướng Quân") and AuthManager and AuthManager.current_user_email != "":
		my_user_name = AuthManager.current_user_email.split("@")[0].to_upper()
	var my_rank_points = (AuthManager.current_2v2_rank_index * 6 + AuthManager.current_2v2_stars) if AuthManager else 0
	var is_debug_match = OS.is_debug_build() or OS.has_feature("editor")
	var rank_diff = 999999 if is_debug_match else 12

	if AppwriteMatchmaking:
		AppwriteMatchmaking.my_session_user_id = my_user_id
		AppwriteMatchmaking.my_session_user_name = my_user_name
		# A previous cancelled search can leave this user's old room behind.
		# Remove it before publishing the new room so a returning player cannot
		# match against their own stale room.
		await AppwriteMatchmaking.cleanup_user_waiting_rooms(my_user_id)

	var inst_idx = NetworkClient.auto_instance_index if NetworkClient else 1
	var own_room_id = "room_" + str(randi()).md5_text().substr(0, 8)
	var own_team_seats = range(1, target_player_count + 1)
	own_team_seats.shuffle()
	var own_dragon_seats = own_team_seats.slice(0, 2)
	var own_room = {
		"roomId": own_room_id,
		"modeId": mode_id,
		"hostUserId": my_user_id,
		"status": "WAITING",
		"version": 1,
		"hostRankPoints": my_rank_points,
		"slots": []
	}
	for seat in range(1, target_player_count + 1):
		own_room["slots"].append({"seatNumber": seat, "isDragon": own_dragon_seats.has(seat), "isAI": false, "userId": my_user_id if seat == 1 else "", "userName": my_user_name if seat == 1 else "", "rankPoints": my_rank_points if seat == 1 else 0, "isEmpty": seat != 1})
	var own_created = await AppwriteMatchmaking.create_waiting_room(own_room)
	if not own_created:
		if is_instance_valid(status_lbl):
			status_lbl.text = "❌ Không thể tham gia hàng chờ. Vui lòng thử lại."
		return
	mm_current_room = own_room
	mm_active_room_id = own_room_id
	mm_is_host = true
	if AppwriteMatchmaking:
		AppwriteMatchmaking.is_host = true
	if NetworkClient:
		NetworkClient.my_seat = inst_idx
		NetworkClient.update_debug_window_title(my_user_name)

	# Include our own room in this first election. If every client excludes its
	# own host room, the smallest two rooms can make a cycle (A joins B while B
	# joins A). A shared smallest-room tie-break gives all clients one anchor.
	var found_room = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points, rank_diff, my_user_name, own_room_id, mode_id)
	if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	var saw_waiting_room = not found_room.is_empty()
	if not found_room.is_empty():
		var target_real_count = 0
		for target_slot in found_room.get("slots", []):
			if not target_slot.get("isEmpty", false) and not target_slot.get("isAI", false) and target_slot.get("userId", "") != "":
				target_real_count += 1
		# Merge into the best candidate immediately. The finder already applies
		# the fullest-room and stable roomId tie-break, so every client converges
		# on the same room instead of waiting for a second pass.
		var should_merge = str(found_room.get("roomId", "")) != own_room_id
		if not should_merge:
			# Our room won the deterministic election. Keep it as the host anchor;
			# clearing it here made the later race retry treat the same room as a
			# fresh join and could leave every client without a host.
			print("[Matchmaking] Giữ phòng neo %s." % own_room_id)
		else:
			var old_room_id = mm_active_room_id
			var joined = await AppwriteMatchmaking.join_room_slot(found_room, my_user_id, my_user_name, my_rank_points, inst_idx)
			if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
				return
			if not joined.is_empty():
				mm_current_room = joined
				mm_active_room_id = joined.get("roomId", "")
				mm_is_host = false
				_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)
				if old_room_id != mm_active_room_id:
					AppwriteMatchmaking.retire_merged_room(old_room_id)
				if AppwriteMatchmaking:
					AppwriteMatchmaking.is_host = false
			else:
				found_room = {}
				# Room may have changed while joining. Re-scan instead of creating a
				# second room and splitting clients.
				for retry in range(10):
					if mm_is_cancelled:
						return
					await get_tree().create_timer(0.5).timeout
					var retry_room = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points, rank_diff, my_user_name, mm_active_room_id, mode_id)
					if retry_room.is_empty():
						continue
					var retry_joined = await AppwriteMatchmaking.join_room_slot(retry_room, my_user_id, my_user_name, my_rank_points, inst_idx)
					if retry_joined.is_empty():
						continue
					mm_current_room = retry_joined
					mm_active_room_id = retry_joined.get("roomId", "")
					mm_is_host = false
					found_room = retry_joined
					_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)
					if AppwriteMatchmaking:
						AppwriteMatchmaking.is_host = false
					break

	# A candidate can become full while this client is joining. Keep the
	# client's own room alive and let the merge loop retry on the next poll.
	if found_room.is_empty() and saw_waiting_room and is_instance_valid(status_lbl):
		status_lbl.text = "🔍 Đang tìm trận..."

	# Several clients can press the button at the same time. Give the first
	# client time to publish its waiting room before creating another room.
	if found_room.is_empty() and mm_active_room_id.is_empty() and not mm_is_cancelled:
		for race_retry in range(6):
			await get_tree().create_timer(0.5).timeout
			if mm_is_cancelled:
				return
			var race_room = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points, rank_diff, my_user_name, mm_active_room_id, mode_id)
			if race_room.is_empty():
				continue
			var race_joined = await AppwriteMatchmaking.join_room_slot(race_room, my_user_id, my_user_name, my_rank_points, inst_idx)
			if race_joined.is_empty():
				continue
			mm_current_room = race_joined
			mm_active_room_id = race_joined.get("roomId", "")
			mm_is_host = false
			found_room = race_joined
			_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)
			if AppwriteMatchmaking:
				AppwriteMatchmaking.is_host = false
			break

	# The client already published its own room before the election. If that
	# room wins the stable tie-break, keep it; never create a second room.
	if found_room.is_empty() and mm_active_room_id.is_empty() and not mm_is_cancelled:
		if is_instance_valid(status_lbl):
			status_lbl.text = "🔍 Đang tìm trận..."
		var new_room_id = "room_" + str(randi()).md5_text().substr(0, 8)
		var random_team_seats = range(1, target_player_count + 1)
		random_team_seats.shuffle()
		var dragon_seats = random_team_seats.slice(0, 2)
		var new_room = {
			"roomId": new_room_id,
			"modeId": mode_id,
			"hostUserId": my_user_id,
			"status": "WAITING",
			"version": 1,
			"hostRankPoints": my_rank_points,
			"slots": []
		}
		for seat in range(1, target_player_count + 1):
			new_room["slots"].append({"seatNumber": seat, "isDragon": dragon_seats.has(seat), "isAI": false, "userId": my_user_id if seat == 1 else "", "userName": my_user_name if seat == 1 else "", "rankPoints": my_rank_points if seat == 1 else 0, "isEmpty": seat != 1})
		var created = await AppwriteMatchmaking.create_waiting_room(new_room)
		if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
			return

		mm_current_room = new_room
		mm_active_room_id = new_room_id
		mm_is_host = true
		if AppwriteMatchmaking:
			AppwriteMatchmaking.is_host = true
		if not created:
			print("[Matchmaking] Appwrite notice: Đang ở chế độ dự phòng ghép bot...")

	if mm_is_cancelled or mm_current_room.is_empty() or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)
	_update_matchmaking_status_count(status_lbl, mm_current_room)

	var is_fast_test = "--screenshot-matchmaking-filled" in OS.get_cmdline_user_args() or "--screenshot-matchmaking-filled" in OS.get_cmdline_args()
	# Đúng thời gian kể từ người cuối cùng ghép vào phòng, nếu chưa đủ 4 người thì bổ sung AI và vào trận luôn
	# Khi debug/editor tăng lên 45s để kịp click cả 4 cửa sổ; online thường là 25s
	var bot_fill_timeout: float = 1.0 if is_fast_test else (45.0 if (OS.is_debug_build() or OS.has_feature("editor")) else 25.0)
	var bot_fill_timer: float = 0.0
	var last_real_player_at_ms: int = Time.get_ticks_msec()
	var heartbeat_timer: float = 0.0
	var poll_timer: float = 0.0 # Thăm dò Appwrite mỗi 2.0 giây
	var last_real_player_count: int = 0
	var guest_wait_timer: float = 0.0
	for initial_slot in mm_current_room.get("slots", []):
		if initial_slot is Dictionary and not initial_slot.get("isEmpty", false) and not initial_slot.get("isAI", false) and initial_slot.get("userId", "") != "":
			last_real_player_count += 1
	# This timestamp is the authoritative start of the current room's wait.
	# It is independent of how long the first Appwrite request takes.
	last_real_player_at_ms = Time.get_ticks_msec()

	_update_matchmaking_status_count(status_lbl, mm_current_room, bot_fill_timeout)

	while not mm_is_cancelled:
		if not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
			return

		bot_fill_timer = float(Time.get_ticks_msec() - last_real_player_at_ms) / 1000.0
		heartbeat_timer -= 0.5
		poll_timer -= 0.5
		guest_wait_timer = bot_fill_timer

		# Do not enter a slow Appwrite request after the deadline. The old
		# half-second counter kept running only after each request returned,
		# which made a 15s wait visibly become 22-23s on a slow network.
		var wait_remaining := bot_fill_timeout - bot_fill_timer
		if last_real_player_count < target_player_count and wait_remaining <= 0.0:
			if not mm_is_host:
				print("[Matchmaking] Hết đúng %.0fs kể từ người cuối cùng, chuyển quyền chủ phòng để bổ sung AI." % bot_fill_timeout)
				mm_is_host = true
				AppwriteMatchmaking.is_host = true
			break
		if last_real_player_count >= target_player_count:
			break
		if last_real_player_count < target_player_count and wait_remaining < 0.75 and not is_fast_test:
			await get_tree().create_timer(0.1).timeout
			continue

		if poll_timer <= 0.0 or is_fast_test:
			poll_timer = 2.0 # Đặt lại chu kỳ 2s

			# Keep consolidating rooms while they are waiting. Every client moves
			# toward a room with more real players; ties use roomId for stability.
			var merge_candidate = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points, rank_diff, my_user_name, mm_active_room_id, mode_id)
			if not merge_candidate.is_empty() and str(merge_candidate.get("roomId", "")) != mm_active_room_id:
				var current_count = 0
				for current_slot in mm_current_room.get("slots", []):
					if not current_slot.get("isEmpty", false) and not current_slot.get("isAI", false) and current_slot.get("userId", "") != "":
						current_count += 1
				var candidate_count = 0
				for candidate_slot in merge_candidate.get("slots", []):
					if not candidate_slot.get("isEmpty", false) and not candidate_slot.get("isAI", false) and candidate_slot.get("userId", "") != "":
						candidate_count += 1
				print("[Matchmaking] Bầu phòng hiện tại=%s/%d ứng viên=%s/%d" % [mm_active_room_id, current_count, str(merge_candidate.get("roomId", "")), candidate_count])
				var should_merge_live = candidate_count > current_count or (candidate_count == current_count and str(merge_candidate.get("roomId", "")) < mm_active_room_id)
				if should_merge_live:
					var previous_room_id = mm_active_room_id
					var merged_room = await AppwriteMatchmaking.join_room_slot(merge_candidate, my_user_id, my_user_name, my_rank_points, inst_idx)
					if not merged_room.is_empty():
						mm_current_room = merged_room
						mm_active_room_id = merged_room.get("roomId", "")
						mm_is_host = false
						AppwriteMatchmaking.is_host = false
						_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)
						if previous_room_id != mm_active_room_id:
							AppwriteMatchmaking.retire_merged_room(previous_room_id)
							last_real_player_at_ms = Time.get_ticks_msec()
							guest_wait_timer = 0.0
							last_real_player_count = candidate_count + 1
							print("[Matchmaking] Gộp phòng %s vào %s (%d -> %d người thật)." % [previous_room_id, mm_active_room_id, current_count, candidate_count + 1])

			if mm_is_host:
				if heartbeat_timer <= 0.0:
					heartbeat_timer = 4.0
					AppwriteMatchmaking.send_host_heartbeat(mm_active_room_id)

				var polled = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
				if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
					return
				if not polled.is_empty():
					mm_current_room = polled

				var current_real_count = 0
				for s in mm_current_room.get("slots", []):
					if not (s is Dictionary):
						continue
					if not s.get("isEmpty", false) and not s.get("isAI", false) and s.get("userId", "") != "":
						current_real_count += 1

				# Cứ có người chơi mới vào phòng -> reset 15s đếm ngầm lại từ đầu
				if current_real_count > last_real_player_count:
					last_real_player_at_ms = Time.get_ticks_msec()
					bot_fill_timer = 0.0
					last_real_player_count = current_real_count
					print("[Matchmaking] Có người mới tham gia (%d/%d)! Đặt lại 15s đếm ngầm từ đầu." % [current_real_count, target_player_count])
				elif current_real_count < last_real_player_count:
					last_real_player_count = current_real_count

				_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)
				bot_fill_timer = float(Time.get_ticks_msec() - last_real_player_at_ms) / 1000.0
				var host_time_left = maxf(0.0, bot_fill_timeout - bot_fill_timer)
				_update_matchmaking_status_count(status_lbl, mm_current_room, host_time_left)

				# Đủ 4 người thật hoặc đã hết 15s kể từ người cuối cùng ghép vào -> bắt đầu ngay
				if current_real_count >= target_player_count or (current_real_count < target_player_count and bot_fill_timer >= bot_fill_timeout):
					break
			else:
				var polled = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
				if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
					return
				if not polled.is_empty():
					mm_current_room = polled

				if not mm_current_room.is_empty():
					var current_real_count = 0
					for s in mm_current_room.get("slots", []):
						if not (s is Dictionary):
							continue
						if not s.get("isEmpty", false) and not s.get("isAI", false) and s.get("userId", "") != "":
							current_real_count += 1
					if current_real_count > last_real_player_count:
						last_real_player_at_ms = Time.get_ticks_msec()
						guest_wait_timer = 0.0
						last_real_player_count = current_real_count
						print("[Matchmaking] (Khách) Có người mới tham gia (%d/%d)! Đặt lại 15s từ đầu." % [current_real_count, target_player_count])
					elif current_real_count < last_real_player_count:
						last_real_player_count = current_real_count

					_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)
					var guest_time_left = maxf(0.0, bot_fill_timeout - guest_wait_timer)
					_update_matchmaking_status_count(status_lbl, mm_current_room, guest_time_left)

					if mm_current_room.get("status") == "STARTED":
						break
					if mm_current_room.get("status") != "WAITING":
						# The room host may have merged this room into another one.
						# Re-scan immediately so this client cannot wait forever on a
						# retired room.
						var replacement = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points, rank_diff, my_user_name, mm_active_room_id, mode_id)
						if not replacement.is_empty():
							var replacement_joined = await AppwriteMatchmaking.join_room_slot(replacement, my_user_id, my_user_name, my_rank_points, inst_idx)
							if not replacement_joined.is_empty():
								mm_current_room = replacement_joined
								mm_active_room_id = replacement_joined.get("roomId", "")
								mm_is_host = false
								AppwriteMatchmaking.is_host = false
								guest_wait_timer = 0.0
								_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)
								_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)
								_update_matchmaking_status_count(status_lbl, mm_current_room, bot_fill_timeout)

					# Trường hợp chủ phòng mất kết nối cũng dùng chung mốc 15 giây.
					if guest_wait_timer >= bot_fill_timeout:
						print("[Matchmaking] Hết 15s và chủ phòng không phản hồi, tự động thăng cấp thành chủ phòng để bổ sung AI và vào chọn tướng.")
						mm_is_host = true
						AppwriteMatchmaking.is_host = true
						break

				if guest_wait_timer > 120.0:
					if is_instance_valid(status_lbl):
						status_lbl.text = "❌ Mất kết nối với chủ phòng!"
						status_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
					await get_tree().create_timer(2.0).timeout
					_hide_modal()
					return

		bot_fill_timer = float(Time.get_ticks_msec() - last_real_player_at_ms) / 1000.0
		if mm_is_host and (bot_fill_timer >= bot_fill_timeout):
			break

		await get_tree().create_timer(0.5).timeout

	if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	if mm_is_host:
		var fresh = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
		if not fresh.is_empty():
			mm_current_room = fresh

		var used_names: Array = [my_user_name]
		for s in mm_current_room.get("slots", []):
			if not (s is Dictionary):
				continue
			if not s.get("isEmpty", false) and s.get("userName", "") != "":
				used_names.append(s.get("userName"))

		var bot_seed_base = AppwriteMatchmaking.get_deterministic_hash_code(mm_active_room_id)
		var slots = mm_current_room.get("slots", [])
		for i in range(slots.size()):
			var s = slots[i]
			if not (s is Dictionary):
				continue
			if s.get("isEmpty", false):
				var bot_name = AppwriteMatchmaking.get_realistic_gamer_name(bot_seed_base + i * 17, used_names)
				used_names.append(bot_name)
				s["userId"] = "bot_" + str(randi()).md5_text().substr(0, 6)
				s["userName"] = bot_name
				s["rankPoints"] = maxi(20, my_rank_points + randi_range(-15, 15))
				s["isAI"] = true
				s["isEmpty"] = false

		mm_current_room["status"] = "STARTED"
		await AppwriteMatchmaking.update_room_state(mm_current_room)

	if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	is_matchmaking_active = false
	if is_instance_valid(status_lbl):
		status_lbl.text = "⚔️ ĐÃ TÌM THẤY TRẬN ĐẤU! Bắt đầu vào trận..."
		status_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
	if is_instance_valid(timer_lbl):
		timer_lbl.text = "⚔️ SẴN SÀNG VÀO TRẬN!"
		timer_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
	AudioManager.play_victory()
	_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)

	# Cập nhật ghế chính xác và tiêu đề cửa sổ debug trước khi vào chọn tướng
	_sync_my_seat_from_room(mm_current_room, my_user_id, my_user_name)

	# Lưu phòng vào AppwriteMatchmaking để hero_select.tscn có thể hiển thị chính xác tên 4 người
	if AppwriteMatchmaking:
		AppwriteMatchmaking.current_room = mm_current_room
		AppwriteMatchmaking.is_host = mm_is_host

	await get_tree().create_timer(1.2).timeout
	if mm_is_cancelled:
		return
	_hide_modal()
	get_tree().change_scene_to_file("res://scenes/hero_select.tscn")

func _build_national_war_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var lbl = Label.new()
	lbl.text = "Chiến Trường Bốn Cõi Phân Tranh:"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	container.add_child(lbl)

	var desc = Label.new()
	desc.text = "Chọn thế lực đại diện để tham gia viễn chinh công thành và tích lũy bổng lộc quân công!"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	container.add_child(desc)

	var war_btn = Button.new()
	war_btn.custom_minimum_size = Vector2(0, 48)
	war_btn.text = "🚩 THAM GIA XUẤT QUÂN"
	_style_white_gold_action_button(war_btn)
	war_btn.pressed.connect(func():
		_hide_modal()
		if AppwriteMatchmaking:
			AppwriteMatchmaking.is_host = true
			AppwriteMatchmaking.current_room = {}
		get_tree().change_scene_to_file("res://scenes/hero_select.tscn")
	)
	container.add_child(war_btn)

	return container

# --- Automated Verification Screenshot Helper ---
func _run_automated_screenshot(show_modal_test: bool) -> void:
	if show_modal_test:
		print("[Home] Mở modal Danh Tướng để kiểm thử...")
		_show_modal("KHO DANH TƯỚNG ĐẠI VIỆT", _build_heroes_content())

	print("[Home] Chế độ chụp ảnh kiểm thử được kích hoạt. Chờ 0.6 giây để dựng hình...")
	await get_tree().create_timer(0.6).timeout

	var img = get_viewport().get_texture().get_image()
	var screenshot_path = "res://home_modal_screenshot.png" if show_modal_test else "res://home_screenshot.png"
	var err = img.save_png(screenshot_path)
	if err == OK:
		print("[Home] Đã lưu ảnh chụp thành công tại: ", screenshot_path)
	else:
		print("[Home] Lỗi lưu ảnh chụp: ", err)

	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _run_automated_screenshot_levelup() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Thăng Cấp...")
	_show_level_up_modal(1, 2)
	await get_tree().create_timer(0.6).timeout
	var img = get_viewport().get_texture().get_image()
	var path = "res://home_levelup_screenshot.png"
	var err = img.save_png(path)
	if err == OK:
		print("[Home] Đã lưu ảnh chụp Thăng Cấp tại: ", path)
	else:
		print("[Home] Lỗi lưu ảnh chụp Thăng Cấp: ", err)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _run_automated_screenshot_exp() -> void:
	print("[Home] Kích hoạt kiểm thử chạy thanh Kinh Nghiệm...")
	gain_exp_animated(20)
	await get_tree().create_timer(0.5).timeout
	var img = get_viewport().get_texture().get_image()
	var path = "res://home_exp_fill_screenshot.png"
	var err = img.save_png(path)
	if err == OK:
		print("[Home] Đã lưu ảnh chụp Thanh Kinh Nghiệm tại: ", path)
	else:
		print("[Home] Lỗi lưu ảnh chụp: ", err)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _run_automated_screenshot_matchmaking() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Tìm Trận 2v2...")
	_start_2v2_matchmaking()
	await get_tree().create_timer(4.0).timeout
	var img = get_viewport().get_texture().get_image()
	var path = "res://home_matchmaking_screenshot.png"
	var err = img.save_png(path)
	if err == OK:
		print("[Home] Đã lưu ảnh chụp Tìm Trận 2v2 tại: ", path)
	else:
		print("[Home] Lỗi lưu ảnh chụp: ", err)
	_cancel_2v2_matchmaking()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _run_automated_screenshot_matchmaking_filled() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Tìm Trận 2v2 (Đầy 4 ghế)...")
	_start_2v2_matchmaking()
	var wait_limit = 10.0
	while wait_limit > 0.0:
		await get_tree().create_timer(0.5).timeout
		wait_limit -= 0.5
		if mm_current_room.get("status") == "STARTED":
			break
	await get_tree().create_timer(0.5).timeout
	var img = get_viewport().get_texture().get_image()
	var path = "res://home_matchmaking_filled_screenshot.png"
	var err = img.save_png(path)
	if err == OK:
		print("[Home] Đã lưu ảnh chụp 4 ghế Tìm Trận 2v2 tại: ", path)
	else:
		print("[Home] Lỗi lưu ảnh chụp: ", err)
	_cancel_2v2_matchmaking()
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

func _run_automated_screenshot_profile() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Hồ Sơ Tướng Quân...")
	_on_profile_clicked()
	await get_tree().create_timer(0.8).timeout
	var img = get_viewport().get_texture().get_image()
	if img:
		var path = "res://home_profile_screenshot.png"
		var err = img.save_png(path)
		if err == OK:
			print("[Home] Đã lưu ảnh chụp Hồ Sơ Tướng Quân tại: ", path)
	get_tree().quit()

func _run_automated_screenshot_quests() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Quân Lệnh Triều Đình (Nhiệm Vụ Ngày)...")
	_open_quests_modal()
	await get_tree().create_timer(0.8).timeout
	var img = get_viewport().get_texture().get_image()
	if img:
		var path = "res://home_quests_screenshot.png"
		var err = img.save_png(path)
		if err == OK:
			print("[Home] Đã lưu ảnh chụp Quân Lệnh Triều Đình tại: ", path)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _run_automated_screenshot_inventory() -> void:
	print("[Home] Kích hoạt kiểm thử Modal Túi Đồ Tướng Quân...")
	_open_inventory_modal()
	await get_tree().create_timer(0.8).timeout
	var img = get_viewport().get_texture().get_image()
	if img:
		var path = "res://home_inventory_screenshot.png"
		var err = img.save_png(path)
		if err == OK:
			print("[Home] Đã lưu ảnh chụp Túi Đồ Tướng Quân tại: ", path)
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
