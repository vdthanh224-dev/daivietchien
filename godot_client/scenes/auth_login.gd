extends Control

const OnboardingModalScene = preload("res://scenes/components/onboarding_modal.tscn")

# Theme Palette: Imperial Dark Lacquer & Royal Gold (Synced with home.gd)
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
const COLOR_SHADOW_DEEP = Color(0.0, 0.0, 0.0, 0.75)

# Background & VFX
@onready var background_img: TextureRect = $BackgroundLayer/BackgroundImage
@onready var embers_particles: CPUParticles2D = $BackgroundLayer/EmbersParticles
@onready var crest_icon: TextureRect = $CenterAuthCard/VBox/DrumHeader/DrumEmblem

# Top Bar Utilities
@onready var ping_label: Label = $TopBarUtilities/LeftGroup/PingBadge/Label
@onready var notice_btn: Button = $TopBarUtilities/RightGroup/NoticeBtn
@onready var support_btn: Button = $TopBarUtilities/RightGroup/SupportBtn
@onready var dev_tester_btn: Button = $TopBarUtilities/RightGroup/DevTesterBtn
@onready var user_account_btn: Button = $TopBarUtilities/RightGroup/UserAccountBtn

# Center Auth Card
@onready var center_auth_card: PanelContainer = $CenterAuthCard
@onready var tab_track: PanelContainer = $CenterAuthCard/VBox/TabTrack
@onready var tab_highlight: Panel = $CenterAuthCard/VBox/TabTrack/TabHighlight
@onready var tab_login_btn: Button = $CenterAuthCard/VBox/TabTrack/TabBar/TabLoginBtn
@onready var tab_register_btn: Button = $CenterAuthCard/VBox/TabTrack/TabBar/TabRegisterBtn
@onready var name_group: VBoxContainer = $CenterAuthCard/VBox/Form/NameGroup
@onready var name_input: LineEdit = $CenterAuthCard/VBox/Form/NameGroup/Box/HBox/NameInput
@onready var email_input: LineEdit = $CenterAuthCard/VBox/Form/EmailGroup/Box/HBox/EmailInput
@onready var pass_input: LineEdit = $CenterAuthCard/VBox/Form/PassGroup/Box/HBox/PassInput
@onready var toggle_pass_btn: Button = $CenterAuthCard/VBox/Form/PassGroup/Box/HBox/TogglePassBtn
@onready var status_lbl: Label = $CenterAuthCard/VBox/StatusLabel
@onready var submit_btn: Button = $CenterAuthCard/VBox/SubmitBtn
@onready var quick_guest_btn: Button = $CenterAuthCard/VBox/GuestHBox/QuickGuestBtn

# Modals Layer
@onready var modals_layer: Control = $ModalsLayer
@onready var dim_backdrop: ColorRect = $ModalsLayer/DimBackdrop
@onready var notice_modal: PanelContainer = $ModalsLayer/NoticeModal
@onready var close_notice_btn: Button = $ModalsLayer/NoticeModal/VBox/Header/CloseNoticeBtn
@onready var notice_confirm_btn: Button = $ModalsLayer/NoticeModal/VBox/NoticeConfirmBtn
@onready var dev_tester_drawer: PanelContainer = $ModalsLayer/DevTesterDrawer
@onready var dev_grid: GridContainer = $ModalsLayer/DevTesterDrawer/VBox/Grid
@onready var btn_tutorial_direct: Button = $ModalsLayer/DevTesterDrawer/VBox/BtnTutorialDirect

var is_register_mode: bool = false
var is_password_visible: bool = false
var active_tester_index: int = 1
var tab_tween: Tween = null

func _ready() -> void:
	# 1. Ẩn tất cả modals lúc ban đầu
	_hide_all_modals()

	# 2. Áp dụng phong cách Imperial Dark Lacquer & Royal Gold chuẩn home.gd
	_apply_royal_home_styling()

	# 3. Kết nối nút thao tác chính
	submit_btn.pressed.connect(_on_submit_pressed)
	quick_guest_btn.pressed.connect(_on_guest_pressed)
	toggle_pass_btn.pressed.connect(_on_toggle_password)
	tab_login_btn.pressed.connect(func(): set_register_mode(false))
	tab_register_btn.pressed.connect(func(): set_register_mode(true))
	notice_btn.pressed.connect(_open_notice_modal)
	support_btn.pressed.connect(_on_support_pressed)
	user_account_btn.pressed.connect(func():
		email_input.grab_focus()
	)

	# 3. Kết nối nút đóng Modal
	close_notice_btn.pressed.connect(_hide_all_modals)
	notice_confirm_btn.pressed.connect(_hide_all_modals)
	dim_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			_hide_all_modals()
	)

	# 4. Thiết lập Dev Tester
	var is_dev = is_dev_machine()
	print("[AuthLogin] Machine Unique ID: %s | Cho phép mục Tester: %s" % [OS.get_unique_id(), is_dev])
	dev_tester_btn.visible = is_dev
	if is_dev:
		dev_tester_btn.pressed.connect(_toggle_dev_drawer)
		for i in range(1, 10):
			var q_btn = dev_grid.get_node_or_null("Quick" + str(i))
			if q_btn:
				var num = i
				q_btn.pressed.connect(func(): _on_quick_login(num))
				_setup_micro_hover(q_btn)

		if btn_tutorial_direct:
			btn_tutorial_direct.pressed.connect(func():
				get_tree().change_scene_to_file("res://scenes/tutorial_battle.tscn")
			)
			_setup_micro_hover(btn_tutorial_direct)

	# 5. Hiệu ứng động học sống động
	_setup_background_motion()
	_setup_crest_motion()
	_setup_hover_effects()

	# 6. Lắng nghe AuthManager & NetworkClient Ping
	AuthManager.login_succeeded.connect(_on_login_succeeded)
	AuthManager.login_failed.connect(_on_login_failed)
	if NetworkClient:
		NetworkClient.ping_updated.connect(_update_ping_display)
		_update_ping_display(NetworkClient.current_ping)

	# 7. Khởi tạo tài khoản & Dev instance
	if is_dev and NetworkClient and NetworkClient.auto_instance_index >= 1 and NetworkClient.auto_instance_index <= 9:
		active_tester_index = NetworkClient.auto_instance_index
		dev_tester_btn.text = "🛠️ TESTER: Tướng %d ▾" % active_tester_index
		user_account_btn.text = "👤 Tester %d ▾" % active_tester_index
		email_input.text = "vdthanh22%d@gmail.com" % active_tester_index
		pass_input.text = "matkhau123"
		_set_status("🎯 Ghế %d: Đã chọn sẵn Tester %d. Nhấn xác nhận để vào game!" % [active_tester_index, active_tester_index], Color("#FFD700"))
	elif AuthManager.is_logged_in:
		user_account_btn.text = "👤 %s ▾" % AuthManager.current_user_name
		email_input.text = AuthManager.current_user_email
		_set_status("✨ Chào mừng Tướng Quân %s trở lại!" % AuthManager.current_user_name, Color("#10B981"))
	else:
		user_account_btn.text = "⚡ Đăng Nhập ▾"
		_set_status("Nhập tài khoản chiến tướng để tiến vào sa trường", Color("#E2CE98"))

	call_deferred("_init_tab_highlight")

	# 8. Phát nhạc nền
	if AudioManager:
		AudioManager.call_deferred("play_bgm", "bgm_battle")

	# 9. Chụp màn hình tự động kiểm thử
	if "--screenshot" in OS.get_cmdline_user_args() or "--screenshot" in OS.get_cmdline_args():
		await get_tree().create_timer(1.2).timeout
		var tex = get_viewport().get_texture()
		var img = tex.get_image() if tex else null
		if img: img.save_png("res://auth_screenshot.png")

		_open_notice_modal()
		await get_tree().create_timer(0.4).timeout
		var tex_notice = get_viewport().get_texture()
		var img_notice = tex_notice.get_image() if tex_notice else null
		if img_notice: img_notice.save_png("res://auth_screenshot_notice.png")

		print("[Screenshot] Đã lưu auth_screenshot.png, auth_screenshot_notice.png!")
		get_tree().quit()

# --- ANIMATION & LIVING MOTION ---

func _setup_background_motion() -> void:
	if not background_img:
		return
	background_img.pivot_offset = Vector2(640, 360)
	var tw = create_tween().set_loops()
	tw.tween_property(background_img, "scale", Vector2(1.035, 1.035), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(background_img, "position", Vector2(-6, -6), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(background_img, "scale", Vector2(1.0, 1.0), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(background_img, "position", Vector2(0, 0), 11.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_crest_motion() -> void:
	if not crest_icon:
		return
	crest_icon.pivot_offset = crest_icon.custom_minimum_size * 0.5
	var tw = create_tween().set_loops()
	tw.tween_property(crest_icon, "scale", Vector2(1.05, 1.05), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(crest_icon, "scale", Vector2(1.0, 1.0), 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_hover_effects() -> void:
	_setup_micro_hover(quick_guest_btn)
	_setup_micro_hover(notice_btn)
	_setup_micro_hover(support_btn)
	_setup_micro_hover(dev_tester_btn)
	_setup_micro_hover(user_account_btn)
	_setup_micro_hover(notice_confirm_btn)
	_setup_micro_hover(submit_btn)

func _setup_micro_hover(btn: Button) -> void:
	if not btn:
		return
	btn.mouse_entered.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if AudioManager:
			AudioManager.play_sfx("sfx_card_select", -8.0)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)

# --- MODAL CONTROLLER ---

func _hide_all_modals() -> void:
	dim_backdrop.visible = false
	notice_modal.visible = false
	dev_tester_drawer.visible = false

func _show_modal(m: Control) -> void:
	_hide_all_modals()
	dim_backdrop.visible = true
	dim_backdrop.modulate.a = 0.0
	m.visible = true
	m.modulate.a = 0.0
	m.scale = Vector2(0.88, 0.88)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(dim_backdrop, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if AudioManager:
		AudioManager.play_sfx("sfx_parry", -4.0)

func _open_notice_modal() -> void:
	_show_modal(notice_modal)

func _toggle_dev_drawer() -> void:
	dev_tester_drawer.visible = not dev_tester_drawer.visible
	if dev_tester_drawer.visible:
		dim_backdrop.visible = true
		dev_tester_drawer.modulate.a = 0.0
		dev_tester_drawer.position.y -= 10.0
		var tw = create_tween().set_parallel(true)
		tw.tween_property(dev_tester_drawer, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(dev_tester_drawer, "position:y", dev_tester_drawer.position.y + 10.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		dim_backdrop.visible = false
	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -6.0)

func _on_support_pressed() -> void:
	_set_status("🎧 Tổng đài CSKH: vdthanh1998@gmail.com | Hotline: 0961 705 592", COLOR_GOLD_ACCENT)
	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -4.0)

# --- AUTH LOGIC & FORM ---

func set_register_mode(register: bool) -> void:
	if is_register_mode == register and tab_highlight.size.x > 10:
		return
	is_register_mode = register
	_update_tab_highlight_position(register, true)

	if is_register_mode:
		submit_btn.text = "✨ TẠO TÀI KHOẢN MỚI"
		tab_register_btn.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		tab_login_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

		name_group.visible = true
		name_group.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(name_group, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		name_input.grab_focus()
	else:
		submit_btn.text = "⚔️ XÁC NHẬN VÀO TRẬN"
		tab_login_btn.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
		tab_register_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

		var tw = create_tween()
		tw.tween_property(name_group, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): name_group.visible = false)
		email_input.grab_focus()

	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -5.0)

func _init_tab_highlight() -> void:
	await get_tree().process_frame
	tab_login_btn.add_theme_color_override("font_color", COLOR_GOLD_ACCENT)
	tab_register_btn.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	_update_tab_highlight_position(false, false)

func _update_tab_highlight_position(is_reg: bool, animate: bool = true) -> void:
	if not tab_highlight or not tab_track:
		return

	var target_btn: Button = tab_register_btn if is_reg else tab_login_btn
	if not target_btn:
		return

	var target_x = target_btn.position.x
	var target_w = target_btn.size.x
	if target_w <= 1.0:
		target_w = (tab_track.size.x - 8.0) * 0.5
		target_x = target_w if is_reg else 4.0

	tab_highlight.size.y = max(30.0, tab_track.size.y - 6.0)
	tab_highlight.position.y = (tab_track.size.y - tab_highlight.size.y) * 0.5

	if tab_tween and tab_tween.is_valid():
		tab_tween.kill()

	if animate:
		tab_tween = create_tween().set_parallel(true)
		tab_tween.tween_property(tab_highlight, "position:x", target_x, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tab_tween.tween_property(tab_highlight, "size:x", target_w, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		tab_highlight.position.x = target_x
		tab_highlight.size.x = target_w

func _on_toggle_password() -> void:
	is_password_visible = not is_password_visible
	pass_input.secret = not is_password_visible
	toggle_pass_btn.text = "ẨN" if is_password_visible else "HIỆN"
	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -6.0)

# --- USER ACTIONS & NETWORKING ---

func _on_submit_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = pass_input.text

	if is_register_mode:
		var n = name_input.text.strip_edges()
		if n.is_empty():
			_set_status("⚠️ Vui lòng nhập danh xưng chiến tướng!", Color("#F59E0B"))
			name_input.grab_focus()
			return
		_set_status("⏳ Đang lập danh xưng chiến tướng...", Color("#FFD700"))
		submit_btn.disabled = true
		quick_guest_btn.disabled = true
		AuthManager.register_email(email, password, n)
	else:
		_set_status("⏳ Đang xác thực thông tin chiến tướng...", Color("#FFD700"))
		submit_btn.disabled = true
		quick_guest_btn.disabled = true
		AuthManager.login_email(email, password)

	if AudioManager:
		AudioManager.play_sfx("sfx_parry", -2.0)

func _on_guest_pressed() -> void:
	_set_status("⏳ Đang khởi tạo phiên chơi khách...", Color("#FFD700"))
	submit_btn.disabled = true
	quick_guest_btn.disabled = true
	AuthManager.login_anonymous()
	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -2.0)

func _on_quick_login(num: int) -> void:
	active_tester_index = num
	dev_tester_btn.text = "🛠️ TESTER: Tướng %d ▾" % num
	user_account_btn.text = "👤 Tester %d ▾" % num
	dev_tester_drawer.visible = false
	dim_backdrop.visible = false
	_set_status("⚡ Đang đăng nhập Tester %d..." % num, Color("#FFD700"))
	submit_btn.disabled = true
	quick_guest_btn.disabled = true
	email_input.text = "vdthanh22%d@gmail.com" % num
	pass_input.text = "matkhau123"
	AuthManager.quick_login(num)
	if AudioManager:
		AudioManager.play_sfx("sfx_parry", -2.0)

func _on_login_succeeded(user_data: Dictionary) -> void:
	submit_btn.disabled = false
	quick_guest_btn.disabled = false
	# Đợi prefs Appwrite đồng bộ xong trước khi quyết định có hiện tập huấn hay không.
	if AuthManager and AuthManager.has_signal("profile_loaded"):
		await AuthManager.profile_loaded
	if AudioManager:
		AudioManager.play_sfx("sfx_levelup", 0.0)

	user_account_btn.text = "👤 %s ▾" % AuthManager.current_user_name
	_set_status("🎉 Xác thực thành công! Đang tiến vào sa trường...", Color("#10B981"))

	if AuthManager.should_show_onboarding():
		_show_onboarding_modal()
	else:
		await get_tree().create_timer(0.3).timeout
		_execute_entry_transition()

func _execute_entry_transition() -> void:
	submit_btn.disabled = true
	quick_guest_btn.disabled = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(background_img, "scale", Vector2(1.08, 1.08), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(center_auth_card, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC)
	tw.chain().tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/home.tscn")
	)

func _show_onboarding_modal() -> void:
	var modal = OnboardingModalScene.instantiate()
	add_child(modal)
	modal.tutorial_chosen.connect(func():
		is_register_mode = false
		AuthManager.set_onboarding_done()
		get_tree().change_scene_to_file("res://scenes/tutorial_battle.tscn")
	)
	modal.veteran_chosen.connect(func():
		is_register_mode = false
		AuthManager.mark_played_before()
		_execute_entry_transition()
	)

func _on_login_failed(err_msg: String) -> void:
	_set_status("❌ " + err_msg, Color("#EF4444"))
	submit_btn.disabled = false
	quick_guest_btn.disabled = false
	if AudioManager:
		AudioManager.play_sfx("sfx_damage", -4.0)

func _set_status(msg: String, col: Color) -> void:
	if status_lbl:
		status_lbl.text = msg
		status_lbl.add_theme_color_override("font_color", col)

# Backward-compatible helper aliases
func _set_gateway_status(msg: String, col: Color) -> void:
	_set_status(msg, col)

func _set_modal_status(msg: String, col: Color) -> void:
	_set_status(msg, col)

func _update_ping_display(ping_ms: int) -> void:
	if not ping_label:
		return
	if ping_ms < 0:
		if NetworkClient and NetworkClient.is_connected_to_server:
			ping_label.text = "📶 Đang đo..."
			ping_label.add_theme_color_override("font_color", Color("#94A3B8"))
		elif NetworkClient and NetworkClient.is_connecting():
			ping_label.text = "📶 Đang kết nối..."
			ping_label.add_theme_color_override("font_color", Color("#FBBF24"))
		else:
			ping_label.text = "📶 Mất mạng"
			ping_label.add_theme_color_override("font_color", Color("#EF4444"))
	elif ping_ms < 60:
		ping_label.text = "📶 %dms" % ping_ms
		ping_label.add_theme_color_override("font_color", Color("#4ADE80"))
	elif ping_ms < 150:
		ping_label.text = "📶 %dms" % ping_ms
		ping_label.add_theme_color_override("font_color", Color("#FBBF24"))
	else:
		ping_label.text = "📶 %dms" % ping_ms
		ping_label.add_theme_color_override("font_color", Color("#EF4444"))

# --- DEV HELPERS ---

# ID duy nhất của laptop nhà phát triển (OS.get_unique_id())
const DEV_LAPTOP_MACHINE_IDS: Array[String] = [
	"87b3fe32-b39f-11f0-abd7-806e6f6e6963",
	"{87b3fe32-b39f-11f0-abd7-806e6f6e6963}"
]

func is_dev_machine() -> bool:
	var raw_id = OS.get_unique_id().strip_edges().to_lower()
	var clean_id = raw_id.replace("{", "").replace("}", "")
	var is_dev = (raw_id in DEV_LAPTOP_MACHINE_IDS or clean_id in DEV_LAPTOP_MACHINE_IDS)
	return is_dev

func _unhandled_input(event: InputEvent) -> void:
	if not is_dev_machine():
		return
	if email_input.has_focus() or pass_input.has_focus() or name_input.has_focus():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1: _on_quick_login(1)
			KEY_2, KEY_KP_2: _on_quick_login(2)
			KEY_3, KEY_KP_3: _on_quick_login(3)
			KEY_4, KEY_KP_4: _on_quick_login(4)
			KEY_5, KEY_KP_5: _on_quick_login(5)
			KEY_6, KEY_KP_6: _on_quick_login(6)
			KEY_7, KEY_KP_7: _on_quick_login(7)
			KEY_8, KEY_KP_8: _on_quick_login(8)
			KEY_9, KEY_KP_9: _on_quick_login(9)

# --- ROYAL HOME STYLING HELPERS (Chuẩn Theme Hoàng Cung home.gd) ---

func _style_glass_action_button(btn: Button, radius: int = 14, border_col: Color = Color(0.85, 0.68, 0.22, 0.75)) -> void:
	if not btn: return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.10, 0.16, 0.88)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = border_col
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_right = radius
	normal.corner_radius_bottom_left = radius
	normal.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.25)
	normal.shadow_size = 6
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.14, 0.18, 0.28, 0.95)
	hover.border_color = COLOR_GOLD_ACCENT
	hover.shadow_size = 10
	hover.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.5)

	var pressed = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.05, 0.07, 0.11, 0.98)
	pressed.shadow_size = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85, 1.0))
	btn.add_theme_font_size_override("font_size", 11)

func _style_bronze_drum_cta(btn: Button) -> void:
	if not btn: return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.70, 0.12, 0.08, 0.96)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(1.0, 0.86, 0.35, 1.0)
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_right = 12
	normal.corner_radius_bottom_left = 12
	normal.shadow_color = Color(0.68, 0.10, 0.05, 0.65)
	normal.shadow_size = 14
	normal.shadow_offset = Vector2(0, 5)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

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
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))

func _style_white_gold_button(btn: Button, corner_radius: int = 8, shadow_size: int = 5, shadow_offset: Vector2 = Vector2(0, 3)) -> void:
	if not btn: return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal = StyleBoxFlat.new()
	normal.bg_color = COLOR_WHITE_BASE
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
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

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_WHITE_HOVER
	hover.border_color = COLOR_GOLD_ACCENT
	hover.shadow_color = COLOR_SHADOW_DEEP
	hover.shadow_size = shadow_size + 3
	hover.shadow_offset = shadow_offset + Vector2(0, 1)

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

func _style_cancel_red_button(btn: Button) -> void:
	if not btn: return
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.48, 0.12, 0.10, 0.92)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.85, 0.35, 0.25, 0.85)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6

	var hover = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.65, 0.15, 0.12, 1.0)
	hover.border_color = Color(1.0, 0.50, 0.40, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.95, 1.0))

func _setup_form_input_styling(group: Control, line_edit: LineEdit) -> void:
	if not group: return
	var lbl = group.get_node_or_null("Label") as Label
	if lbl:
		lbl.add_theme_color_override("font_color", COLOR_TEXT_GOLD)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		lbl.add_theme_constant_override("shadow_offset_y", 1)

	var box = group.get_node_or_null("Box") as PanelContainer
	if box:
		var normal_box = StyleBoxFlat.new()
		normal_box.bg_color = Color(0.06, 0.05, 0.09, 0.92)
		normal_box.border_width_left = 1
		normal_box.border_width_top = 1
		normal_box.border_width_right = 1
		normal_box.border_width_bottom = 1
		normal_box.border_color = Color(0.70, 0.55, 0.22, 0.7)
		normal_box.corner_radius_top_left = 8
		normal_box.corner_radius_top_right = 8
		normal_box.corner_radius_bottom_right = 8
		normal_box.corner_radius_bottom_left = 8
		normal_box.content_margin_left = 12
		normal_box.content_margin_right = 10
		normal_box.content_margin_top = 6
		normal_box.content_margin_bottom = 6
		box.add_theme_stylebox_override("panel", normal_box)

		if line_edit:
			line_edit.focus_entered.connect(func():
				var focus_box = normal_box.duplicate() as StyleBoxFlat
				focus_box.bg_color = Color(0.09, 0.07, 0.13, 0.98)
				focus_box.border_color = COLOR_GOLD_ACCENT
				focus_box.shadow_color = Color(0.92, 0.75, 0.26, 0.35)
				focus_box.shadow_size = 6
				box.add_theme_stylebox_override("panel", focus_box)
			)
			line_edit.focus_exited.connect(func():
				box.add_theme_stylebox_override("panel", normal_box)
			)

	if line_edit:
		line_edit.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		line_edit.add_theme_color_override("font_placeholder_color", Color(0.55, 0.50, 0.42, 0.8))
		line_edit.add_theme_font_size_override("font_size", 13)

func _apply_royal_home_styling() -> void:
	# 1. Background image & Dark Overlay
	var home_bg_tex = load("res://assets/ui/home_background.png")
	if home_bg_tex != null and background_img:
		background_img.texture = home_bg_tex
		background_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	var bg_layer = get_node_or_null("BackgroundLayer")
	if bg_layer:
		var dark_ov = bg_layer.get_node_or_null("DarkOverlay")
		if not dark_ov:
			dark_ov = ColorRect.new()
			dark_ov.name = "DarkOverlay"
			dark_ov.set_anchors_preset(PRESET_FULL_RECT)
			dark_ov.color = Color(0.02, 0.03, 0.05, 0.32)
			dark_ov.mouse_filter = MOUSE_FILTER_IGNORE
			bg_layer.add_child(dark_ov)
			bg_layer.move_child(dark_ov, 1)

	# 2. Top Bar Header Panel (matching home.gd top bar)
	var top_header = get_node_or_null("TopHeaderBar")
	if not top_header:
		top_header = Panel.new()
		top_header.name = "TopHeaderBar"
		top_header.set_anchors_preset(PRESET_TOP_WIDE)
		top_header.custom_minimum_size = Vector2(1280, 64)
		top_header.offset_bottom = 64
		var hs = StyleBoxFlat.new()
		hs.bg_color = Color(0.04, 0.05, 0.09, 0.82)
		hs.border_width_bottom = 1
		hs.border_color = Color(0.20, 0.30, 0.50, 0.40)
		top_header.add_theme_stylebox_override("panel", hs)
		top_header.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(top_header)
		var top_utils = get_node_or_null("TopBarUtilities")
		if top_utils:
			move_child(top_header, top_utils.get_index())

	# 3. Top Bar Utilities Pills
	var v_badge = get_node_or_null("TopBarUtilities/LeftGroup/VersionBadge") as PanelContainer
	if v_badge:
		var vs = StyleBoxFlat.new()
		vs.bg_color = Color(0.08, 0.10, 0.16, 0.88)
		vs.border_width_left = 1
		vs.border_width_top = 1
		vs.border_width_right = 1
		vs.border_width_bottom = 1
		vs.border_color = Color(0.3, 0.45, 0.65, 0.6)
		vs.corner_radius_top_left = 12
		vs.corner_radius_top_right = 12
		vs.corner_radius_bottom_right = 12
		vs.corner_radius_bottom_left = 12
		vs.content_margin_left = 12
		vs.content_margin_right = 12
		vs.content_margin_top = 5
		vs.content_margin_bottom = 5
		v_badge.add_theme_stylebox_override("panel", vs)

	var p_badge = get_node_or_null("TopBarUtilities/LeftGroup/PingBadge") as PanelContainer
	if p_badge:
		var ps = StyleBoxFlat.new()
		ps.bg_color = Color(0.08, 0.10, 0.16, 0.88)
		ps.border_width_left = 1
		ps.border_width_top = 1
		ps.border_width_right = 1
		ps.border_width_bottom = 1
		ps.border_color = Color(0.3, 0.45, 0.65, 0.6)
		ps.corner_radius_top_left = 12
		ps.corner_radius_top_right = 12
		ps.corner_radius_bottom_right = 12
		ps.corner_radius_bottom_left = 12
		ps.content_margin_left = 12
		ps.content_margin_right = 12
		ps.content_margin_top = 5
		ps.content_margin_bottom = 5
		p_badge.add_theme_stylebox_override("panel", ps)

	# Utility Buttons on Top Right
	_style_glass_action_button(notice_btn, 14, Color(0.85, 0.68, 0.22, 0.75))
	_style_glass_action_button(support_btn, 14, Color(0.85, 0.68, 0.22, 0.75))
	_style_glass_action_button(dev_tester_btn, 14, Color(0.30, 0.75, 0.95, 0.8))
	_style_glass_action_button(user_account_btn, 14, Color(0.85, 0.68, 0.22, 0.75))

	# 4. Title Brand Center Styling
	var logo_text = get_node_or_null("TitleBrandCenter/LogoText") as Label
	if logo_text:
		logo_text.text = "ĐẠI VIỆT CHIẾN"
		logo_text.add_theme_color_override("font_color", Color(1.0, 0.86, 0.28, 1.0))
		logo_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
		logo_text.add_theme_color_override("font_outline_color", Color(0.28, 0.14, 0.03, 1.0))
		logo_text.add_theme_constant_override("outline_size", 6)
		logo_text.add_theme_constant_override("shadow_offset_y", 3)
		logo_text.add_theme_font_size_override("font_size", 34)

	var sub_text = get_node_or_null("TitleBrandCenter/Subtitle") as Label
	if sub_text:
		sub_text.add_theme_color_override("font_color", Color(0.92, 0.82, 0.60, 1.0))
		sub_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		sub_text.add_theme_font_size_override("font_size", 11)

	# 5. Center Auth Card Styling (Imperial Dark Lacquer with Golden Royal Border)
	if center_auth_card:
		center_auth_card.custom_minimum_size = Vector2(460, 530)
		var card_s = StyleBoxFlat.new()
		card_s.bg_color = Color(0.08, 0.06, 0.11, 0.97)
		card_s.border_width_left = 2
		card_s.border_width_top = 2
		card_s.border_width_right = 2
		card_s.border_width_bottom = 2
		card_s.border_color = COLOR_GOLD_PRIMARY
		card_s.corner_radius_top_left = 16
		card_s.corner_radius_top_right = 16
		card_s.corner_radius_bottom_right = 16
		card_s.corner_radius_bottom_left = 16
		card_s.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
		card_s.shadow_size = 32
		card_s.shadow_offset = Vector2(0, 10)
		card_s.content_margin_left = 26
		card_s.content_margin_right = 26
		card_s.content_margin_top = 20
		card_s.content_margin_bottom = 20
		center_auth_card.add_theme_stylebox_override("panel", card_s)

	# 6. Drum Emblem Ring / Frame
	var drum_hdr = get_node_or_null("CenterAuthCard/VBox/DrumHeader")
	if drum_hdr and crest_icon:
		var existing_frame = crest_icon.get_parent()
		if existing_frame.name != "EmblemFrame":
			var frame = PanelContainer.new()
			frame.name = "EmblemFrame"
			frame.custom_minimum_size = Vector2(88, 88)
			frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var fs = StyleBoxFlat.new()
			fs.bg_color = Color(0.14, 0.10, 0.18, 0.95)
			fs.border_width_left = 2
			fs.border_width_top = 2
			fs.border_width_right = 2
			fs.border_width_bottom = 2
			fs.border_color = Color(1.0, 0.85, 0.35, 1.0)
			fs.corner_radius_top_left = 44
			fs.corner_radius_top_right = 44
			fs.corner_radius_bottom_right = 44
			fs.corner_radius_bottom_left = 44
			fs.shadow_color = Color(0.92, 0.75, 0.26, 0.35)
			fs.shadow_size = 12
			frame.add_theme_stylebox_override("panel", fs)

			var old_idx = crest_icon.get_index()
			drum_hdr.remove_child(crest_icon)
			frame.add_child(crest_icon)
			crest_icon.custom_minimum_size = Vector2(80, 80)
			drum_hdr.add_child(frame)
			drum_hdr.move_child(frame, old_idx)

		if not drum_hdr.has_node("CardTitle"):
			var c_title = Label.new()
			c_title.name = "CardTitle"
			c_title.text = "CHIẾN ĐÌNH KHỞI SỰ"
			c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			c_title.add_theme_font_size_override("font_size", 16)
			c_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.38, 1.0))
			c_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			drum_hdr.add_child(c_title)

	# 7. Tab Track & Highlight
	if tab_track:
		var ts = StyleBoxFlat.new()
		ts.bg_color = Color(0.05, 0.04, 0.08, 0.95)
		ts.border_width_left = 1
		ts.border_width_top = 1
		ts.border_width_right = 1
		ts.border_width_bottom = 1
		ts.border_color = Color(0.45, 0.35, 0.20, 0.6)
		ts.corner_radius_top_left = 10
		ts.corner_radius_top_right = 10
		ts.corner_radius_bottom_right = 10
		ts.corner_radius_bottom_left = 10
		ts.content_margin_left = 4
		ts.content_margin_right = 4
		ts.content_margin_top = 3
		ts.content_margin_bottom = 3
		tab_track.add_theme_stylebox_override("panel", ts)

	if tab_highlight:
		var ths = StyleBoxFlat.new()
		ths.bg_color = Color(0.68, 0.12, 0.08, 0.96)
		ths.border_width_left = 1
		ths.border_width_top = 1
		ths.border_width_right = 1
		ths.border_width_bottom = 1
		ths.border_color = Color(1.0, 0.85, 0.35, 1.0)
		ths.corner_radius_top_left = 8
		ths.corner_radius_top_right = 8
		ths.corner_radius_bottom_right = 8
		ths.corner_radius_bottom_left = 8
		ths.shadow_color = Color(0.68, 0.10, 0.05, 0.5)
		ths.shadow_size = 6
		tab_highlight.add_theme_stylebox_override("panel", ths)

	if tab_login_btn:
		tab_login_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab_login_btn.add_theme_font_size_override("font_size", 12)
	if tab_register_btn:
		tab_register_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab_register_btn.add_theme_font_size_override("font_size", 12)

	# 8. Form Inputs (Name, Email, Pass)
	_setup_form_input_styling(name_group, name_input)
	_setup_form_input_styling(get_node_or_null("CenterAuthCard/VBox/Form/EmailGroup"), email_input)
	_setup_form_input_styling(get_node_or_null("CenterAuthCard/VBox/Form/PassGroup"), pass_input)

	if toggle_pass_btn:
		_style_white_gold_button(toggle_pass_btn, 4, 2, Vector2(0, 1))
		toggle_pass_btn.add_theme_font_size_override("font_size", 10)
		toggle_pass_btn.custom_minimum_size = Vector2(46, 26)

	# 9. Submit & Quick Guest Buttons
	if submit_btn:
		_style_bronze_drum_cta(submit_btn)
		submit_btn.custom_minimum_size = Vector2(0, 46)

	if quick_guest_btn:
		_style_white_gold_button(quick_guest_btn, 10, 6, Vector2(0, 3))
		quick_guest_btn.custom_minimum_size = Vector2(0, 38)
		quick_guest_btn.add_theme_font_size_override("font_size", 12)
		quick_guest_btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.60, 1.0))

	# 10. Modals Styling (Notice Modal & Dev Tester Drawer)
	if notice_modal:
		var nms = StyleBoxFlat.new()
		nms.bg_color = Color(0.08, 0.06, 0.11, 0.98)
		nms.border_width_left = 2
		nms.border_width_top = 2
		nms.border_width_right = 2
		nms.border_width_bottom = 2
		nms.border_color = COLOR_GOLD_PRIMARY
		nms.corner_radius_top_left = 14
		nms.corner_radius_top_right = 14
		nms.corner_radius_bottom_right = 14
		nms.corner_radius_bottom_left = 14
		nms.shadow_color = Color(0, 0, 0, 0.92)
		nms.shadow_size = 36
		nms.shadow_offset = Vector2(0, 12)
		nms.content_margin_left = 22
		nms.content_margin_right = 22
		nms.content_margin_top = 20
		nms.content_margin_bottom = 20
		notice_modal.add_theme_stylebox_override("panel", nms)

	if close_notice_btn:
		_style_cancel_red_button(close_notice_btn)

	if notice_confirm_btn:
		_style_bronze_drum_cta(notice_confirm_btn)
		notice_confirm_btn.custom_minimum_size = Vector2(0, 42)

	if dev_tester_drawer:
		var dds = StyleBoxFlat.new()
		dds.bg_color = Color(0.08, 0.06, 0.11, 0.98)
		dds.border_width_left = 2
		dds.border_width_top = 2
		dds.border_width_right = 2
		dds.border_width_bottom = 2
		dds.border_color = COLOR_GOLD_BORDER
		dds.corner_radius_top_left = 12
		dds.corner_radius_top_right = 12
		dds.corner_radius_bottom_right = 12
		dds.corner_radius_bottom_left = 12
		dds.shadow_color = Color(0, 0, 0, 0.85)
		dds.shadow_size = 24
		dds.content_margin_left = 14
		dds.content_margin_right = 14
		dds.content_margin_top = 12
		dds.content_margin_bottom = 12
		dev_tester_drawer.add_theme_stylebox_override("panel", dds)

	# 11. Footer Disclaimer Styling
	var badge_18 = get_node_or_null("FooterDisclaimer/Badge18Plus") as PanelContainer
	if badge_18:
		var b18_s = StyleBoxFlat.new()
		b18_s.bg_color = Color(0.70, 0.10, 0.08, 0.95)
		b18_s.border_width_left = 1
		b18_s.border_width_top = 1
		b18_s.border_width_right = 1
		b18_s.border_width_bottom = 1
		b18_s.border_color = Color(1.0, 0.80, 0.30, 0.85)
		b18_s.corner_radius_top_left = 4
		b18_s.corner_radius_top_right = 4
		b18_s.corner_radius_bottom_right = 4
		b18_s.corner_radius_bottom_left = 4
		b18_s.content_margin_left = 6
		b18_s.content_margin_right = 6
		b18_s.content_margin_top = 2
		b18_s.content_margin_bottom = 2
		badge_18.add_theme_stylebox_override("panel", b18_s)

	var notice_text = get_node_or_null("FooterDisclaimer/NoticeText") as Label
	if notice_text:
		notice_text.add_theme_color_override("font_color", Color(0.75, 0.70, 0.62, 0.8))
		notice_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		notice_text.add_theme_font_size_override("font_size", 10)
