extends Control

const OnboardingModalScene = preload("res://scenes/components/onboarding_modal.tscn")

# Background & VFX
@onready var background_img: TextureRect = $BackgroundLayer/BackgroundImage
@onready var embers_particles: CPUParticles2D = $BackgroundLayer/EmbersParticles
@onready var sunburst_rays_center: Control = $TitleBrandCenter/SunburstRaysCenter
@onready var crest_icon: TextureRect = $TitleBrandCenter/CrestIcon

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

	# 2. Kết nối nút thao tác chính
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
	_setup_sunburst_rays()
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
	tw.tween_property(crest_icon, "scale", Vector2(1.06, 1.06), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(crest_icon, "position:y", crest_icon.position.y - 3.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(crest_icon, "scale", Vector2(1.0, 1.0), 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(crest_icon, "position:y", crest_icon.position.y, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_sunburst_rays() -> void:
	if not sunburst_rays_center:
		return
	var num_rays = 16
	for i in range(num_rays):
		var ray = Line2D.new()
		var angle = (float(i) / float(num_rays)) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		ray.points = PackedVector2Array([Vector2.ZERO, dir * 360.0])
		ray.width = 30.0
		ray.default_color = Color(1.0, 0.85, 0.35, 0.06 if i % 2 == 0 else 0.025)
		sunburst_rays_center.add_child(ray)

	var rays_tw = sunburst_rays_center.create_tween().set_loops()
	rays_tw.tween_property(sunburst_rays_center, "rotation", TAU, 30.0).as_relative()

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
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(func():
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
	_set_status("🎧 Tổng đài CSKH: vdthanh1998@gmail.com | Hotline: 0961 705 592", Color("#FFD700"))
	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -4.0)

# --- AUTH LOGIC & FORM ---

func set_register_mode(register: bool) -> void:
	if is_register_mode == register and tab_highlight.size.x > 10:
		return
	is_register_mode = register
	_update_tab_highlight_position(register, true)

	if is_register_mode:
		submit_btn.text = "TẠO TÀI KHOẢN MỚI"
		tab_register_btn.add_theme_color_override("font_color", Color("#FFD700"))
		tab_login_btn.add_theme_color_override("font_color", Color("#C8BEAA"))

		name_group.visible = true
		name_group.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(name_group, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		name_input.grab_focus()
	else:
		submit_btn.text = "⚔️ XÁC NHẬN VÀO TRẬN"
		tab_login_btn.add_theme_color_override("font_color", Color("#FFD700"))
		tab_register_btn.add_theme_color_override("font_color", Color("#C8BEAA"))

		var tw = create_tween()
		tw.tween_property(name_group, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func(): name_group.visible = false)
		email_input.grab_focus()

	if AudioManager:
		AudioManager.play_sfx("sfx_card_select", -5.0)

func _init_tab_highlight() -> void:
	await get_tree().process_frame
	tab_login_btn.add_theme_color_override("font_color", Color("#FFD700"))
	tab_register_btn.add_theme_color_override("font_color", Color("#C8BEAA"))
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
