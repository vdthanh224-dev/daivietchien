extends Control

# Theme Palette: Imperial White & Gold
const COLOR_WHITE_BASE = Color(0.97, 0.96, 0.92, 1.0)
const COLOR_WHITE_HOVER = Color(1.0, 0.99, 0.96, 1.0)
const COLOR_WHITE_PRESSED = Color(0.91, 0.89, 0.83, 1.0)

const COLOR_GOLD_PRIMARY = Color(0.85, 0.70, 0.22, 1.0)
const COLOR_GOLD_ACCENT = Color(0.98, 0.82, 0.28, 1.0)
const COLOR_GOLD_BORDER = Color(0.80, 0.63, 0.18, 1.0)
const COLOR_GOLD_DARK = Color(0.55, 0.40, 0.08, 1.0)

const COLOR_TEXT_DARK = Color(0.11, 0.09, 0.04, 1.0)
const COLOR_TEXT_MUTED = Color(0.35, 0.32, 0.25, 1.0)
const COLOR_TEXT_GOLD = Color(0.72, 0.52, 0.08, 1.0)

const COLOR_SHADOW = Color(0.0, 0.0, 0.0, 0.35)
const COLOR_SHADOW_DEEP = Color(0.0, 0.0, 0.0, 0.45)

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
var modal_content_container: VBoxContainer

# Player State
var current_silver: int = 5000
var current_gold: int = 0
var current_rp: int = 1200
var current_military_points: int = 350

# Matchmaking 2v2 State
var is_matchmaking_active: bool = false
var mm_is_cancelled: bool = false
var mm_active_room_id: String = ""
var mm_is_host: bool = false
var mm_current_room: Dictionary = {}

# Embers particle pool
var ember_particles: Array = []
var levelup_overlay: Control = null

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_ui()
	_load_user_data()
	if AuthManager:
		AuthManager.profile_updated.connect(_load_user_data)
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
	else:
		_check_pending_exp_gain()

func _build_ui() -> void:
	# 1. Background
	bg_rect = TextureRect.new()
	bg_rect.anchors_preset = PRESET_FULL_RECT
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
	dark_overlay.anchors_preset = PRESET_FULL_RECT
	dark_overlay.color = Color(0.02, 0.04, 0.08, 0.42)
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
	header_style.bg_color = Color(0.97, 0.96, 0.93, 0.96)
	header_style.border_width_bottom = 2
	header_style.border_color = COLOR_GOLD_PRIMARY
	header_style.shadow_color = COLOR_SHADOW
	header_style.shadow_size = 6
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
	lb_style.bg_color = Color(0.96, 0.80, 0.28, 1.0)
	lb_style.border_width_left = 1
	lb_style.border_width_top = 1
	lb_style.border_width_right = 1
	lb_style.border_width_bottom = 1
	lb_style.border_color = Color(0.72, 0.54, 0.12, 1.0)
	lb_style.corner_radius_top_left = 4
	lb_style.corner_radius_top_right = 4
	lb_style.corner_radius_bottom_right = 4
	lb_style.corner_radius_bottom_left = 4
	level_badge.add_theme_stylebox_override("panel", lb_style)

	level_badge_label = Label.new()
	level_badge_label.text = " CẤP 1 "
	level_badge_label.add_theme_font_size_override("font_size", 10)
	level_badge_label.add_theme_color_override("font_color", Color(0.12, 0.08, 0.02, 1.0))
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
	exp_bg.bg_color = Color(0.85, 0.83, 0.77, 1.0)
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
	tp_style.bg_color = Color(0.98, 0.97, 0.94, 1.0)
	tp_style.border_width_left = 2
	tp_style.border_width_top = 2
	tp_style.border_width_right = 2
	tp_style.border_width_bottom = 2
	tp_style.border_color = COLOR_GOLD_PRIMARY
	tp_style.corner_radius_top_left = 8
	tp_style.corner_radius_top_right = 8
	tp_style.corner_radius_bottom_right = 8
	tp_style.corner_radius_bottom_left = 8
	tp_style.shadow_color = COLOR_SHADOW
	tp_style.shadow_size = 5
	tp_style.shadow_offset = Vector2(0, 3)
	title_panel.add_theme_stylebox_override("panel", tp_style)

	var title_lbl = Label.new()
	title_lbl.text = "👑 ĐẠI VIỆT CHIẾN"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 21)
	title_lbl.add_theme_color_override("font_color", Color(0.68, 0.48, 0.05, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(1.0, 0.88, 0.40, 0.85))
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
	var modes_hbox = HBoxContainer.new()
	modes_hbox.set_anchors_preset(PRESET_FULL_RECT)
	modes_hbox.offset_left = 28
	modes_hbox.offset_right = -28
	modes_hbox.offset_top = 78
	modes_hbox.offset_bottom = -74
	modes_hbox.add_theme_constant_override("separation", 16)
	modes_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(modes_hbox)

	# 1. Card 2v2 Ranked
	_create_game_mode_card(
		modes_hbox,
		"🛡️",
		"ĐẤU TRƯỜNG 2v2",
		"Xếp Hạng Hoàng Triều (1,200 RP)",
		"res://assets/ui/tran_hung_dao.png",
		"Hiệp lực cùng đồng minh tranh tài đối kháng 2v2 đỉnh cao. Tích lũy RP để vươn lên đỉnh Bảng Vàng!",
		"VÀO ĐẤU 2v2 ➜",
		func(): _start_mode_2v2()
	)

	# 2. Card Vương Triều
	_create_game_mode_card(
		modes_hbox,
		"👑",
		"VƯƠNG TRIỀU",
		"Hoàng Tộc Tranh Bá (4-8 Người)",
		"res://assets/ui/dinh_bo_linh.png",
		"Tranh đoạt ngọc tỷ hoàng gia. Phân định vai trò bí mật: Chúa Công, Trung Thần, Phản Tặc, Gian Hùng!",
		"VÀO VƯƠNG TRIỀU ➜",
		func(): _start_mode_dynasty()
	)

	# 3. Card Quốc Chiến
	_create_game_mode_card(
		modes_hbox,
		"⚔️",
		"QUỐC CHIẾN",
		"Bốn Cõi Phân Tranh",
		"res://assets/ui/ngo_quyen.png",
		"Bốn phe đại thế: Tiền Lê, Lý, Trần, Hậu Lê. Chiếm cứ thành lũy hiểm yếu, mở mang bờ cõi Đại Việt!",
		"XUẤT QUÂN ➜",
		func(): _start_mode_national_war()
	)

	# 4. Card Luyện Tập / AI Practice (Tập Kích Sơn Tặc)
	_create_game_mode_card(
		modes_hbox,
		"🏹",
		"TẬP KÍCH SƠN TẶC",
		"Huấn Luyện & Thực Chiến AI",
		"res://assets/ui/thu_linh_son_tac.png",
		"Tập kích sào huyệt Sơn Tặc. Rèn luyện kỹ năng danh tướng, trải nghiệm chiến thuật và làm quen luật bài!",
		"LUYỆN TẬP ➜",
		func(): _start_mode_practice()
	)

func _create_game_mode_card(
	parent: Container,
	icon_str: String,
	title: String,
	subtitle: String,
	image_path: String,
	desc: String,
	btn_text: String,
	on_click: Callable
) -> void:
	var card = PanelContainer.new()
	card.size_flags_horizontal = SIZE_EXPAND_FILL
	card.size_flags_vertical = SIZE_EXPAND_FILL

	# Imperial White Card with Rich Gold Border & Drop Shadow
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.98, 0.97, 0.94, 0.97)
	card_style.border_width_left = 2
	card_style.border_width_top = 2
	card_style.border_width_right = 2
	card_style.border_width_bottom = 2
	card_style.border_color = COLOR_GOLD_PRIMARY
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.shadow_color = COLOR_SHADOW_DEEP
	card_style.shadow_size = 10
	card_style.shadow_offset = Vector2(0, 5)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.offset_left = 12
	vbox.offset_right = -12
	vbox.offset_top = 12
	vbox.offset_bottom = -12
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# 1. Header Icon & Title
	var title_hbox = HBoxContainer.new()
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 8)

	var icon_lbl = Label.new()
	icon_lbl.text = icon_str
	icon_lbl.add_theme_font_size_override("font_size", 22)
	title_hbox.add_child(icon_lbl)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	title_hbox.add_child(title_lbl)
	vbox.add_child(title_hbox)

	# 2. Subtitle
	var sub_lbl = Label.new()
	sub_lbl.text = subtitle
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	vbox.add_child(sub_lbl)

	# 3. Gold Line Divider
	var div = ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.85, 0.70, 0.22, 0.6)
	vbox.add_child(div)

	# 4. Mode Artwork Banner
	var img_panel = PanelContainer.new()
	img_panel.custom_minimum_size = Vector2(0, 210)
	img_panel.size_flags_vertical = SIZE_EXPAND_FILL

	var ip_style = StyleBoxFlat.new()
	ip_style.bg_color = Color(0.08, 0.11, 0.16, 0.95)
	ip_style.border_width_left = 1
	ip_style.border_width_top = 1
	ip_style.border_width_right = 1
	ip_style.border_width_bottom = 1
	ip_style.border_color = Color(0.85, 0.70, 0.22, 0.7)
	ip_style.corner_radius_top_left = 8
	ip_style.corner_radius_top_right = 8
	ip_style.corner_radius_bottom_right = 8
	ip_style.corner_radius_bottom_left = 8
	img_panel.add_theme_stylebox_override("panel", ip_style)

	var art_img = TextureRect.new()
	art_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load(image_path)
	if tex != null:
		art_img.texture = tex
	img_panel.add_child(art_img)
	vbox.add_child(img_panel)

	# 5. Description
	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.custom_minimum_size = Vector2(0, 68)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	vbox.add_child(desc_lbl)

	# 6. Action Button (White & Gold with prominent Shadow)
	var action_btn = Button.new()
	action_btn.custom_minimum_size = Vector2(0, 46)
	action_btn.text = btn_text
	_style_white_gold_action_button(action_btn)
	action_btn.pressed.connect(func():
		AudioManager.play_slash()
		on_click.call()
	)
	vbox.add_child(action_btn)

	parent.add_child(card)

func _build_bottom_nav_dock() -> void:
	var dock_panel = Panel.new()
	dock_panel.custom_minimum_size = Vector2(1280, 64)
	dock_panel.set_anchors_preset(PRESET_BOTTOM_WIDE)
	dock_panel.offset_top = -64

	var dock_style = StyleBoxFlat.new()
	dock_style.bg_color = Color(0.97, 0.96, 0.93, 0.96)
	dock_style.border_width_top = 2
	dock_style.border_color = COLOR_GOLD_PRIMARY
	dock_style.shadow_color = COLOR_SHADOW
	dock_style.shadow_size = 6
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
		{"icon": "🎖️", "title": "DANH TƯỚNG", "action": func(): _show_modal("KHO DANH TƯỚNG ĐẠI VIỆT", _build_heroes_content())},
		{"icon": "🎒", "title": "BINH KHÍ", "action": func(): _show_modal("BINH KHÍ KHỐ", _build_equipment_content())},
		{"icon": "🏆", "title": "BẢNG VÀNG", "action": func(): _show_modal("BẢNG PHONG THẦN", _build_leaderboard_content())},
		{"icon": "📜", "title": "NHIỆM VỤ", "action": func(): _show_modal("QUÂN LỆNH TRIỀU ĐÌNH", _build_quests_content())},
		{"icon": "🛒", "title": "TRÂN BẢO", "action": func(): _show_modal("TRÂN BẢO CÁC", _build_shop_content())},
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
		dock_hbox.add_child(btn)

func _build_modal_layer() -> void:
	modal_overlay = ColorRect.new()
	modal_overlay.set_anchors_preset(PRESET_FULL_RECT)
	modal_overlay.color = Color(0.02, 0.04, 0.08, 0.65)
	modal_overlay.visible = false
	add_child(modal_overlay)

	# Click outside to close
	modal_overlay.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			if is_matchmaking_active:
				return
			_hide_modal()
	)

	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(820, 520)
	modal_panel.set_anchors_preset(PRESET_CENTER)
	modal_panel.grow_horizontal = GROW_DIRECTION_BOTH
	modal_panel.grow_vertical = GROW_DIRECTION_BOTH

	var mp_style = StyleBoxFlat.new()
	mp_style.bg_color = Color(0.98, 0.97, 0.94, 0.98)
	mp_style.border_width_left = 3
	mp_style.border_width_top = 3
	mp_style.border_width_right = 3
	mp_style.border_width_bottom = 3
	mp_style.border_color = COLOR_GOLD_PRIMARY
	mp_style.corner_radius_top_left = 14
	mp_style.corner_radius_top_right = 14
	mp_style.corner_radius_bottom_right = 14
	mp_style.corner_radius_bottom_left = 14
	mp_style.shadow_color = Color(0, 0, 0, 0.55)
	mp_style.shadow_size = 18
	mp_style.shadow_offset = Vector2(0, 8)
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
	modal_title_label.add_theme_color_override("font_color", COLOR_TEXT_DARK)
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
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	modal_content_container = VBoxContainer.new()
	modal_content_container.size_flags_horizontal = SIZE_EXPAND_FILL
	modal_content_container.add_theme_constant_override("separation", 10)
	scroll.add_child(modal_content_container)
	m_vbox.add_child(scroll)

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
	btn.add_theme_color_override("font_hover_color", Color(0.20, 0.14, 0.02, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.06, 0.02, 1.0))
	btn.add_theme_color_override("font_shadow_color", Color(1.0, 0.85, 0.35, 0.5))
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
		if is_instance_valid(silver_label):
			silver_label.text = _format_number(current_silver)
		if is_instance_valid(gold_label):
			gold_label.text = _format_number(current_gold)

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
	print("[Home] Chuyển cảnh vào Vương Triều (Main Game)...")
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

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
	var my_uid = AuthManager.current_user_id if AuthManager else ""
	if mm_is_host and mm_active_room_id != "":
		AppwriteMatchmaking.delete_room(mm_active_room_id)
	elif mm_active_room_id != "" and my_uid != "":
		AppwriteMatchmaking.leave_room_slot(mm_active_room_id, my_uid)

func _show_modal(title_text: String, content_node: Node) -> void:
	if is_matchmaking_active:
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
		{"icon": "🔓", "title": "MỞ KHÓA TÍNH NĂNG", "desc": "Đấu Trường 2v2 Hoàng Triều\nVương Triều Tranh Bá", "c": Color(0.75, 0.35, 0.15, 1.0)},
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

# --- Modal Content Builders ---
func _build_heroes_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var intro = Label.new()
	intro.text = "Danh sách danh tướng nước Đại Việt qua các triều đại hào hùng:"
	intro.add_theme_font_size_override("font_size", 14)
	intro.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	container.add_child(intro)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)

	var heroes = [
		{"name": "Lý Thường Kiệt", "role": "Tiên Phong / Công", "img": "res://assets/ui/ly_thuong_kiet.png"},
		{"name": "Trần Hưng Đạo", "role": "Thống Soái / Phòng", "img": "res://assets/ui/tran_hung_dao.png"},
		{"name": "Ngô Quyền", "role": "Hải Vương / Công", "img": "res://assets/ui/ngo_quyen.png"},
		{"name": "Lê Lợi", "role": "Bình Định / Cứu Viện", "img": "res://assets/ui/le_loi.png"},
		{"name": "Bà Triệu", "role": "Nộ Chiến / Trảm", "img": "res://assets/ui/ba_trieu.png"},
		{"name": "Đinh Bộ Lĩnh", "role": "Vạn Thắng / Điều Khiển", "img": "res://assets/ui/dinh_bo_linh.png"},
		{"name": "Trần Quốc Toản", "role": "Phá Lỗ / Tốc Chiến", "img": "res://assets/ui/tran_quoc_toan.png"},
		{"name": "Yết Kiêu", "role": "Thần Thủy / Tàng Hình", "img": "res://assets/ui/yet_kieu.png"},
	]

	for h in heroes:
		var hero_card = PanelContainer.new()
		hero_card.custom_minimum_size = Vector2(180, 160)
		var h_style = StyleBoxFlat.new()
		h_style.bg_color = Color(0.95, 0.94, 0.90, 1.0)
		h_style.border_width_left = 1
		h_style.border_width_top = 1
		h_style.border_width_right = 1
		h_style.border_width_bottom = 1
		h_style.border_color = COLOR_GOLD_PRIMARY
		h_style.corner_radius_top_left = 8
		h_style.corner_radius_top_right = 8
		h_style.corner_radius_bottom_right = 8
		h_style.corner_radius_bottom_left = 8
		h_style.shadow_color = COLOR_SHADOW
		h_style.shadow_size = 4
		h_style.shadow_offset = Vector2(0, 2)
		hero_card.add_theme_stylebox_override("panel", h_style)

		var hv = VBoxContainer.new()
		hv.offset_left = 6
		hv.offset_right = -6
		hv.offset_top = 6
		hv.offset_bottom = -6
		hv.add_theme_constant_override("separation", 4)

		var himg = TextureRect.new()
		himg.custom_minimum_size = Vector2(0, 100)
		himg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		himg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var ht = load(h["img"])
		if ht: himg.texture = ht
		hv.add_child(himg)

		var hname = Label.new()
		hname.text = h["name"]
		hname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hname.add_theme_font_size_override("font_size", 13)
		hname.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		hv.add_child(hname)

		var hrole = Label.new()
		hrole.text = h["role"]
		hrole.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hrole.add_theme_font_size_override("font_size", 11)
		hrole.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		hv.add_child(hrole)

		hero_card.add_child(hv)
		grid.add_child(hero_card)

	container.add_child(grid)
	return container

func _build_equipment_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var items = [
		{"type": "Vũ Khí", "name": "Kiếm Thuận Thiên", "desc": "Tầm đánh +3. Khi Trảm trúng đích hồi phục 1 sinh mệnh."},
		{"type": "Vũ Khí", "name": "Nỏ Thần Kim Quy", "desc": "Bỏ qua khoảng cách mục tiêu. Không giới hạn số lần dùng Trảm."},
		{"type": "Phòng Cụ", "name": "Khiên Mây Bện", "desc": "Khi bị Trảm, phán xét lá trên cùng nếu chất ĐỎ tự động tính là ĐỠ."},
		{"type": "Phòng Cụ", "name": "Áo Bào Hoàng Tộc", "desc": "Vô hiệu hóa sát thương Lôi và Hỏa của đối phương."},
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

func _build_leaderboard_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)

	var ranks = [
		{"rank": "🥇 1", "name": "Vua Quang Trung", "title": "Đại Tướng Quân", "rp": "3,450 RP"},
		{"rank": "🥈 2", "name": "Bình Định Vương", "title": "Chánh Tướng", "rp": "3,210 RP"},
		{"rank": "🥉 3", "name": "Tiết Chế Hưng Đạo", "title": "Chánh Tướng", "rp": "2,980 RP"},
		{"rank": "4", "name": "Lý Thường Kiệt (Bạn)", "title": "Chánh Tướng", "rp": "1,200 RP"},
		{"rank": "5", "name": "Bố Cái Đại Vương", "title": "Phó Tướng", "rp": "1,150 RP"},
		{"rank": "6", "name": "Triệu Quang Phục", "title": "Phó Tướng", "rp": "1,040 RP"},
	]

	for r in ranks:
		var panel = PanelContainer.new()
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.96, 0.95, 0.91, 1.0)
		ps.border_width_left = 1
		ps.border_width_right = 1
		ps.border_width_top = 1
		ps.border_width_bottom = 1
		ps.border_color = COLOR_GOLD_PRIMARY if "Bạn" in r["name"] else Color(0.85, 0.70, 0.22, 0.4)
		ps.corner_radius_top_left = 6
		ps.corner_radius_top_right = 6
		ps.corner_radius_bottom_right = 6
		ps.corner_radius_bottom_left = 6
		ps.shadow_color = COLOR_SHADOW
		ps.shadow_size = 4
		ps.shadow_offset = Vector2(0, 2)
		panel.add_theme_stylebox_override("panel", ps)

		var row = HBoxContainer.new()
		row.offset_left = 16
		row.offset_right = -16
		row.offset_top = 8
		row.offset_bottom = -8
		row.add_theme_constant_override("separation", 20)

		var r_lbl = Label.new()
		r_lbl.text = r["rank"]
		r_lbl.custom_minimum_size = Vector2(50, 0)
		r_lbl.add_theme_font_size_override("font_size", 14)
		r_lbl.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		row.add_child(r_lbl)

		var n_lbl = Label.new()
		n_lbl.text = r["name"]
		n_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		n_lbl.add_theme_font_size_override("font_size", 13)
		n_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		row.add_child(n_lbl)

		var t_lbl = Label.new()
		t_lbl.text = r["title"]
		t_lbl.custom_minimum_size = Vector2(140, 0)
		t_lbl.add_theme_font_size_override("font_size", 12)
		t_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		row.add_child(t_lbl)

		var rp_lbl = Label.new()
		rp_lbl.text = r["rp"]
		rp_lbl.custom_minimum_size = Vector2(100, 0)
		rp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rp_lbl.add_theme_font_size_override("font_size", 13)
		rp_lbl.add_theme_color_override("font_color", Color(0.70, 0.48, 0.05, 1.0))
		row.add_child(rp_lbl)

		panel.add_child(row)
		container.add_child(panel)

	return container

func _build_quests_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	var quests = [
		{"name": "Đánh thắng 1 trận Luyện Tập", "prog": "1/1", "done": true, "reward": "🥈 500 Bạc"},
		{"name": "Dùng thành công 3 lá Trảm", "prog": "2/3", "done": false, "reward": "🥈 300 Bạc"},
		{"name": "Phán xét Khiên Mây Bện thành công", "prog": "1/1", "done": true, "reward": "🥈 600 Bạc"},
		{"name": "Tham gia 1 trận Đấu Trường 2v2", "prog": "0/1", "done": false, "reward": "🥈 1,000 Bạc"},
	]

	for q in quests:
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
		row.offset_left = 16
		row.offset_right = -16
		row.offset_top = 8
		row.offset_bottom = -8
		row.add_theme_constant_override("separation", 14)

		var q_lbl = Label.new()
		q_lbl.text = q["name"]
		q_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
		q_lbl.add_theme_font_size_override("font_size", 13)
		q_lbl.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		row.add_child(q_lbl)

		var p_lbl = Label.new()
		p_lbl.text = q["prog"]
		p_lbl.custom_minimum_size = Vector2(60, 0)
		p_lbl.add_theme_font_size_override("font_size", 12)
		p_lbl.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
		row.add_child(p_lbl)

		var r_lbl = Label.new()
		r_lbl.text = q["reward"]
		r_lbl.custom_minimum_size = Vector2(100, 0)
		r_lbl.add_theme_font_size_override("font_size", 12)
		r_lbl.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		row.add_child(r_lbl)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110, 34)
		btn.text = "ĐÃ NHẬN" if q["done"] else "TIẾP TỤC"
		btn.disabled = q["done"]
		_style_white_gold_button(btn, 6, 3, Vector2(0, 2))
		row.add_child(btn)

		panel.add_child(row)
		container.add_child(panel)

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
	container.add_theme_constant_override("separation", 12)

	var p_panel = PanelContainer.new()
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
	p_panel.add_theme_stylebox_override("panel", ps)

	var hbox = HBoxContainer.new()
	hbox.offset_left = 16
	hbox.offset_right = -16
	hbox.offset_top = 16
	hbox.offset_bottom = -16
	hbox.add_theme_constant_override("separation", 16)

	var av = TextureRect.new()
	av.custom_minimum_size = Vector2(90, 90)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var tex = load("res://assets/ui/ly_thuong_kiet.png")
	if tex: av.texture = tex
	hbox.add_child(av)

	var v = VBoxContainer.new()
	v.size_flags_horizontal = SIZE_EXPAND_FILL

	var n = Label.new()
	n.text = player_name_label.text
	n.add_theme_font_size_override("font_size", 18)
	n.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	v.add_child(n)

	var mil_info = AuthManager.get_military_rank_info() if AuthManager else {"full_name": "🔰 Tân Binh", "tier": 1, "points": 50, "next_min": 100}
	var lvl = AuthManager.current_level if AuthManager else 1
	var exp_c = AuthManager.current_exp if AuthManager else 0
	var exp_req = AuthManager.get_exp_to_next_level() if AuthManager else 20
	var num_generals = AuthManager.current_generals.size() if AuthManager else 1

	var r = Label.new()
	r.text = "Cấp độ: Cấp %d (%d/%d EXP) | Quân hàm: %s (Bậc %d/12)" % [lvl, exp_c, exp_req, mil_info["full_name"], mil_info["tier"]]
	r.add_theme_font_size_override("font_size", 13)
	r.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
	v.add_child(r)

	var gen_lbl = Label.new()
	gen_lbl.text = "Danh tướng sở hữu: %d tướng (Cứ 1 tướng sở hữu +50 Exp Quân hàm = %dđ)" % [num_generals, mil_info["points"]]
	gen_lbl.add_theme_font_size_override("font_size", 12)
	gen_lbl.add_theme_color_override("font_color", Color(0.18, 0.50, 0.20, 1.0))
	v.add_child(gen_lbl)

	var win = Label.new()
	win.text = "Thành tích: 48 Thắng / 12 Bại (Tỉ lệ: 80.0%)"
	win.add_theme_font_size_override("font_size", 13)
	win.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	v.add_child(win)

	var rp = Label.new()
	rp.text = "Điểm 2v2 RP: %d | Bạc: %s | Vàng: %s" % [
		AuthManager.current_2v2_points if AuthManager else 1200,
		_format_number(current_silver),
		_format_number(current_gold)
	]
	rp.add_theme_font_size_override("font_size", 13)
	rp.add_theme_color_override("font_color", Color(0.70, 0.48, 0.05, 1.0))
	v.add_child(rp)

	var test_btn = Button.new()
	test_btn.custom_minimum_size = Vector2(0, 36)
	test_btn.text = "⭐ NHẬN +20 EXP & LÊN CẤP (HIỆU ỨNG & ÂM THANH)"
	_style_white_gold_action_button(test_btn)
	test_btn.pressed.connect(func():
		_hide_modal()
		await get_tree().create_timer(0.25).timeout
		gain_exp_animated(20)
	)
	v.add_child(test_btn)

	hbox.add_child(v)
	p_panel.add_child(hbox)
	container.add_child(p_panel)

	return container

func _build_2v2_content() -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 12)

	var lbl = Label.new()
	lbl.text = "Sảnh Ghép Đội Đấu Trường 2v2 Hoàng Triều:"
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
	play_btn.text = "⚔️ TÌM TRẬN ĐẤU 2v2 NGAY"
	_style_white_gold_action_button(play_btn)
	play_btn.pressed.connect(func():
		_start_2v2_matchmaking()
	)
	container.add_child(play_btn)

	return container

# --- 2v2 Real-Player Matchmaking System (Appwrite Singapore) ---
func _start_2v2_matchmaking() -> void:
	is_matchmaking_active = true
	mm_is_cancelled = false
	mm_active_room_id = ""
	mm_is_host = false
	mm_current_room = {}

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 10)

	# 1. Subtitle & Server Status Bar
	var status_bar = PanelContainer.new()
	status_bar.custom_minimum_size = Vector2(0, 44)
	var sb_style = StyleBoxFlat.new()
	sb_style.bg_color = Color(0.08, 0.12, 0.18, 0.95)
	sb_style.border_width_left = 1
	sb_style.border_width_top = 1
	sb_style.border_width_right = 1
	sb_style.border_width_bottom = 1
	sb_style.border_color = COLOR_GOLD_PRIMARY
	sb_style.corner_radius_top_left = 6
	sb_style.corner_radius_top_right = 6
	sb_style.corner_radius_bottom_right = 6
	sb_style.corner_radius_bottom_left = 6
	status_bar.add_theme_stylebox_override("panel", sb_style)

	var sb_margin = MarginContainer.new()
	sb_margin.add_theme_constant_override("margin_left", 12)
	sb_margin.add_theme_constant_override("margin_right", 12)
	status_bar.add_child(sb_margin)

	var sb_hbox = HBoxContainer.new()
	sb_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sb_margin.add_child(sb_hbox)

	var status_lbl = Label.new()
	status_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	status_lbl.text = "👑 Đang kết nối máy chủ Singapore..."
	status_lbl.add_theme_font_size_override("font_size", 13)
	status_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	sb_hbox.add_child(status_lbl)

	var timer_badge = PanelContainer.new()
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.05, 0.08, 0.14, 0.9)
	tb_style.border_width_left = 1
	tb_style.border_width_top = 1
	tb_style.border_width_right = 1
	tb_style.border_width_bottom = 1
	tb_style.border_color = Color(0.35, 0.75, 0.95, 0.8)
	tb_style.corner_radius_top_left = 4
	tb_style.corner_radius_top_right = 4
	tb_style.corner_radius_bottom_right = 4
	tb_style.corner_radius_bottom_left = 4
	timer_badge.add_theme_stylebox_override("panel", tb_style)

	var tb_margin = MarginContainer.new()
	tb_margin.add_theme_constant_override("margin_left", 8)
	tb_margin.add_theme_constant_override("margin_right", 8)
	tb_margin.add_theme_constant_override("margin_top", 2)
	tb_margin.add_theme_constant_override("margin_bottom", 2)
	timer_badge.add_child(tb_margin)

	var timer_lbl = Label.new()
	timer_lbl.text = "⏳ 00:00"
	timer_lbl.add_theme_font_size_override("font_size", 13)
	timer_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0, 1.0))
	tb_margin.add_child(timer_lbl)
	sb_hbox.add_child(timer_badge)

	container.add_child(status_bar)

	# 2. 4 Seat Slots Container
	var slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 8)
	container.add_child(slots_vbox)

	var slot_nodes: Array = []
	var my_name = AuthManager.current_user_name if AuthManager else "Đại Tướng Quân"
	var my_rp = AuthManager.current_2v2_points if AuthManager else 1200

	for i in range(4):
		var s_panel = PanelContainer.new()
		s_panel.custom_minimum_size = Vector2(0, 52)
		var sp_style = StyleBoxFlat.new()
		sp_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
		sp_style.border_width_left = 1.5
		sp_style.border_width_top = 1.5
		sp_style.border_width_right = 1.5
		sp_style.border_width_bottom = 1.5
		sp_style.border_color = Color(0.2, 0.28, 0.4, 0.7)
		sp_style.corner_radius_top_left = 8
		sp_style.corner_radius_top_right = 8
		sp_style.corner_radius_bottom_right = 8
		sp_style.corner_radius_bottom_left = 8
		s_panel.add_theme_stylebox_override("panel", sp_style)

		var s_margin = MarginContainer.new()
		s_margin.add_theme_constant_override("margin_left", 12)
		s_margin.add_theme_constant_override("margin_right", 12)
		s_margin.add_theme_constant_override("margin_top", 6)
		s_margin.add_theme_constant_override("margin_bottom", 6)
		s_panel.add_child(s_margin)

		var s_hbox = HBoxContainer.new()
		s_hbox.add_theme_constant_override("separation", 12)
		s_margin.add_child(s_hbox)

		# Team Badge
		var t_badge = Label.new()
		t_badge.custom_minimum_size = Vector2(76, 26)
		t_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t_badge.add_theme_font_size_override("font_size", 11)
		var is_drag = (i == 0 or i == 2)
		var tb_s = StyleBoxFlat.new()
		tb_s.corner_radius_top_left = 4
		tb_s.corner_radius_top_right = 4
		tb_s.corner_radius_bottom_right = 4
		tb_s.corner_radius_bottom_left = 4
		if is_drag:
			tb_s.bg_color = Color(0.08, 0.42, 0.72, 0.95)
			t_badge.text = "[RỒNG]"
			t_badge.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0, 1.0))
		else:
			tb_s.bg_color = Color(0.72, 0.18, 0.25, 0.95)
			t_badge.text = "[PHƯỢNG]"
			t_badge.add_theme_color_override("font_color", Color(1.0, 0.8, 0.85, 1.0))
		t_badge.add_theme_stylebox_override("normal", tb_s)
		s_hbox.add_child(t_badge)

		# Avatar Texture
		var av_rect = TextureRect.new()
		av_rect.custom_minimum_size = Vector2(36, 36)
		av_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		av_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var av_tex = load("res://assets/ui/game_avatar.png")
		if av_tex: av_rect.texture = av_tex
		s_hbox.add_child(av_rect)

		# Info VBox (Name + Status)
		var info_v = VBoxContainer.new()
		info_v.size_flags_horizontal = SIZE_EXPAND_FILL
		info_v.add_theme_constant_override("separation", 2)
		s_hbox.add_child(info_v)

		var name_l = Label.new()
		name_l.add_theme_font_size_override("font_size", 13)
		info_v.add_child(name_l)

		var status_l = Label.new()
		status_l.add_theme_font_size_override("font_size", 11)
		info_v.add_child(status_l)

		var rank_l = Label.new()
		rank_l.add_theme_font_size_override("font_size", 12)
		rank_l.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		s_hbox.add_child(rank_l)

		var seat_l = Label.new()
		seat_l.text = "GHẾ %d" % (i + 1)
		seat_l.add_theme_font_size_override("font_size", 11)
		seat_l.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
		s_hbox.add_child(seat_l)

		slots_vbox.add_child(s_panel)

		# Initial slot visual
		if i == 0:
			name_l.text = "%s (BẠN)" % my_name
			name_l.add_theme_color_override("font_color", Color.WHITE)
			status_l.text = "✅ ĐÃ SẴN SÀNG"
			status_l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
			rank_l.text = "• %d RP" % my_rp
			sp_style.border_color = COLOR_GOLD_PRIMARY
			sp_style.bg_color = Color(0.1, 0.18, 0.32, 0.95)
		else:
			name_l.text = "Ghế %d: Đang tìm tướng lĩnh..." % (i + 1)
			name_l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75, 1.0))
			status_l.text = "⏳ Đang tìm kiếm trên máy chủ..."
			status_l.add_theme_color_override("font_color", Color(0.45, 0.52, 0.65, 1.0))
			rank_l.text = ""

		slot_nodes.append({
			"panel": s_panel,
			"style": sp_style,
			"team_badge": t_badge,
			"avatar_rect": av_rect,
			"name_lbl": name_l,
			"status_lbl": status_l,
			"rank_lbl": rank_l,
			"seat_lbl": seat_l
		})

	# 3. Cancel Button
	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(btn_hbox)

	var cancel_btn = Button.new()
	cancel_btn.custom_minimum_size = Vector2(280, 44)
	cancel_btn.text = "✕ HỦY TÌM TRẬN"
	_style_cancel_red_button(cancel_btn)
	cancel_btn.pressed.connect(func():
		AudioManager.play_card_select()
		_cancel_2v2_matchmaking()
	)
	btn_hbox.add_child(cancel_btn)

	_show_modal("⚔️ TÌM TRẬN 2v2 HOÀNG TRIỀU", container)
	_run_2v2_matchmaking_loop(status_lbl, timer_lbl, slot_nodes)

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

func _update_matchmaking_slots_visual(room: Dictionary, my_user_id: String, slot_nodes: Array) -> void:
	if room.is_empty():
		return
	var slots = room.get("slots", [])
	for i in range(4):
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
			var is_empty = bool(s.get("isEmpty", false)) or s.get("userId", "") == "" or s.get("userId", "") == "empty"
			var is_drag = bool(s.get("isDragon", (i == 0 or i == 2)))
			var is_ai = bool(s.get("isAI", false))
			var is_me = (s.get("userId", "") == my_user_id)

			if is_empty:
				name_l.text = "Ghế %d: Đang tìm tướng lĩnh..." % (i + 1)
				name_l.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75, 1.0))
				status_l.text = "⏳ Đang tìm kiếm trên máy chủ..."
				status_l.add_theme_color_override("font_color", Color(0.45, 0.52, 0.65, 1.0))
				rank_l.text = ""
				sp_style.bg_color = Color(0.06, 0.09, 0.15, 0.95)
				sp_style.border_color = Color(0.2, 0.28, 0.4, 0.7)
			else:
				var uname = s.get("userName", "Chiến Tướng")
				var role_str = " (BẠN)" if is_me else (" (AI)" if is_ai else " (NGƯỜI THẬT)")
				name_l.text = "%s%s" % [uname, role_str]
				if is_me:
					name_l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
					sp_style.bg_color = Color(0.1, 0.22, 0.38, 0.95)
					sp_style.border_color = COLOR_GOLD_PRIMARY
				elif is_drag:
					name_l.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0, 1.0))
					sp_style.bg_color = Color(0.07, 0.16, 0.26, 0.95)
					sp_style.border_color = Color(0.25, 0.65, 0.95, 0.8)
				else:
					name_l.add_theme_color_override("font_color", Color(1.0, 0.75, 0.8, 1.0))
					sp_style.bg_color = Color(0.22, 0.08, 0.12, 0.95)
					sp_style.border_color = Color(0.9, 0.35, 0.45, 0.8)

				status_l.text = "✅ ĐÃ SẴN SÀNG"
				status_l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.5, 1.0))
				rank_l.text = "• %d RP" % int(s.get("rankPoints", 0))

func _run_2v2_matchmaking_loop(status_lbl: Label, timer_lbl: Label, slot_nodes: Array) -> void:
	var my_user_id = AuthManager.current_user_id if AuthManager and AuthManager.current_user_id != "" else ("user_" + str(randi()).md5_text().substr(0, 8))
	var my_user_name = AuthManager.current_user_name if AuthManager and AuthManager.current_user_name != "" else "Đại Tướng Quân"
	var my_rank_points = AuthManager.current_2v2_points if AuthManager else 1200

	if is_instance_valid(status_lbl):
		status_lbl.text = "🔍 Đang quét tìm phòng thi đấu trên máy chủ Singapore..."

	var found_room = await AppwriteMatchmaking.find_best_waiting_room(my_user_id, my_rank_points)
	if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	if not found_room.is_empty():
		if is_instance_valid(status_lbl):
			status_lbl.text = "🌐 Đã tìm thấy phòng [%s]. Đang tham gia..." % found_room.get("roomId", "")
		var joined = await AppwriteMatchmaking.join_room_slot(found_room, my_user_id, my_user_name, my_rank_points)
		if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
			return
		if not joined.is_empty():
			mm_current_room = joined
			mm_active_room_id = joined.get("roomId", "")
			mm_is_host = false
		else:
			found_room = {}

	if found_room.is_empty() and not mm_is_cancelled:
		if is_instance_valid(status_lbl):
			status_lbl.text = "👑 Đang tạo phòng thi đấu mới trên máy chủ..."
		var new_room_id = "room_" + str(randi()).md5_text().substr(0, 8)
		var new_room = {
			"roomId": new_room_id,
			"hostUserId": my_user_id,
			"status": "WAITING",
			"version": 1,
			"hostRankPoints": my_rank_points,
			"slots": [
				{ "seatNumber": 1, "isDragon": true, "isAI": false, "userId": my_user_id, "userName": my_user_name, "rankPoints": my_rank_points, "isEmpty": false },
				{ "seatNumber": 2, "isDragon": false, "isAI": false, "userId": "", "userName": "", "rankPoints": 0, "isEmpty": true },
				{ "seatNumber": 3, "isDragon": true, "isAI": false, "userId": "", "userName": "", "rankPoints": 0, "isEmpty": true },
				{ "seatNumber": 4, "isDragon": false, "isAI": false, "userId": "", "userName": "", "rankPoints": 0, "isEmpty": true }
			]
		}
		var created = await AppwriteMatchmaking.create_waiting_room(new_room)
		if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
			return
		if created:
			mm_current_room = new_room
			mm_active_room_id = new_room_id
			mm_is_host = true

	if mm_is_cancelled or mm_current_room.is_empty() or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
		return

	_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)

	var elapsed_timer: float = 0.0
	var is_fast_test = "--screenshot-matchmaking-filled" in OS.get_cmdline_user_args() or "--screenshot-matchmaking-filled" in OS.get_cmdline_args()
	var host_hidden_timer: float = 1.0 if is_fast_test else 15.0
	var heartbeat_timer: float = 0.0
	var last_real_player_count: int = 1
	var guest_wait_timer: float = 0.0

	while not mm_is_cancelled:
		if not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
			return

		elapsed_timer += 0.5
		host_hidden_timer -= 0.5
		heartbeat_timer -= 0.5
		guest_wait_timer += 0.5

		var sec = int(elapsed_timer)
		if is_instance_valid(timer_lbl):
			timer_lbl.text = "⏳ %02d:%02d" % [sec / 60, sec % 60]

		if mm_is_host:
			if heartbeat_timer <= 0.0:
				heartbeat_timer = 2.0
				AppwriteMatchmaking.send_host_heartbeat(mm_active_room_id)

			var polled = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
			if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
				return
			if not polled.is_empty():
				mm_current_room = polled

			var current_real_count = 0
			for s in mm_current_room.get("slots", []):
				if not s.get("isEmpty", false) and not s.get("isAI", false) and s.get("userId", "") != "":
					current_real_count += 1

			if current_real_count > last_real_player_count:
				host_hidden_timer = 15.0
				last_real_player_count = current_real_count
				if is_instance_valid(status_lbl):
					status_lbl.text = "⚔️ Có thêm người chơi thực tham gia! Đang đợi tiếp..."

			_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)

			if current_real_count >= 4 or host_hidden_timer <= 0.0:
				var fresh = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
				if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
					return
				if not fresh.is_empty():
					mm_current_room = fresh

				var used_names: Array = [my_user_name]
				for s in mm_current_room.get("slots", []):
					if not s.get("isEmpty", false) and s.get("userName", "") != "":
						used_names.append(s.get("userName"))

				var bot_seed_base = AppwriteMatchmaking.get_deterministic_hash_code(mm_active_room_id)
				var slots = mm_current_room.get("slots", [])
				for i in range(slots.size()):
					var s = slots[i]
					if s.get("isEmpty", false):
						s["userId"] = "bot_" + str(randi()).md5_text().substr(0, 6)
						s["userName"] = AppwriteMatchmaking.get_realistic_gamer_name(bot_seed_base + i * 17, used_names)
						s["rankPoints"] = maxi(20, my_rank_points + randi_range(-15, 15))
						s["isAI"] = true
						s["isEmpty"] = false

				# Deterministic shuffle
				var rng = RandomNumberGenerator.new()
				rng.seed = bot_seed_base
				for i in range(slots.size() - 1, 0, -1):
					var k = rng.randi_range(0, i)
					var tmp = slots[i]
					slots[i] = slots[k]
					slots[k] = tmp

				for i in range(slots.size()):
					slots[i]["seatNumber"] = i + 1

				mm_current_room["status"] = "STARTED"
				await AppwriteMatchmaking.update_room_state(mm_current_room)
				if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
					return

				if is_instance_valid(status_lbl):
					status_lbl.text = "⚔️ ĐÃ KẾT NỐI ĐỦ 4 CHIẾN TƯỚNG! Bắt đầu vào trận..."
					status_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
				if is_instance_valid(timer_lbl):
					timer_lbl.text = "⚔️ SẴN SÀNG!"
					timer_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
				AudioManager.play_victory()
				_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)
				break
		else:
			var polled = await AppwriteMatchmaking.poll_room_state(mm_active_room_id)
			if mm_is_cancelled or not is_instance_valid(status_lbl) or not is_instance_valid(timer_lbl):
				return
			if not polled.is_empty():
				mm_current_room = polled

			if not mm_current_room.is_empty():
				_update_matchmaking_slots_visual(mm_current_room, my_user_id, slot_nodes)

				if mm_current_room.get("status") == "STARTED":
					if is_instance_valid(status_lbl):
						status_lbl.text = "⚔️ PHÒNG ĐÃ BẮT ĐẦU! Đang vào màn thi đấu..."
						status_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
					if is_instance_valid(timer_lbl):
						timer_lbl.text = "⚔️ SẴN SÀNG!"
						timer_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.45, 1.0))
					AudioManager.play_victory()
					break

			if guest_wait_timer > 35.0:
				if is_instance_valid(status_lbl):
					status_lbl.text = "❌ Mất kết nối với chủ phòng!"
					status_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
				await get_tree().create_timer(2.0).timeout
				_hide_modal()
				return

		await get_tree().create_timer(0.5).timeout

	if mm_is_cancelled:
		return

	await get_tree().create_timer(1.2).timeout
	if mm_is_cancelled:
		return
	_hide_modal()
	is_matchmaking_active = false
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

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
		get_tree().change_scene_to_file("res://scenes/main_game.tscn")
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
	await get_tree().create_timer(1.2).timeout
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
	await get_tree().create_timer(2.4).timeout
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
