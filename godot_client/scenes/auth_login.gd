extends Control

@onready var tab_login_btn: Button = $AuthCard/Margin/VBox/TabBar/TabLoginBtn
@onready var tab_register_btn: Button = $AuthCard/Margin/VBox/TabBar/TabRegisterBtn
@onready var tab_login_line: ColorRect = $AuthCard/Margin/VBox/TabBar/TabLoginBtn/ActiveLine
@onready var tab_register_line: ColorRect = $AuthCard/Margin/VBox/TabBar/TabRegisterBtn/ActiveLine

@onready var name_group: VBoxContainer = $AuthCard/Margin/VBox/Form/NameGroup
@onready var name_input: LineEdit = $AuthCard/Margin/VBox/Form/NameGroup/NameInput
@onready var email_input: LineEdit = $AuthCard/Margin/VBox/Form/EmailGroup/EmailInput
@onready var pass_input: LineEdit = $AuthCard/Margin/VBox/Form/PassGroup/PassInput

@onready var submit_btn: Button = $AuthCard/Margin/VBox/SubmitBtn
@onready var guest_btn: Button = $AuthCard/Margin/VBox/GuestBtn
@onready var status_lbl: Label = $AuthCard/Margin/VBox/StatusLabel

@onready var quick_login_bar: PanelContainer = $QuickLoginBar
@onready var quick_hbox: HBoxContainer = $QuickLoginBar/Margin/HBox

var is_register_mode: bool = false

func _ready() -> void:
	tab_login_btn.pressed.connect(func(): set_register_mode(false))
	tab_register_btn.pressed.connect(func(): set_register_mode(true))
	submit_btn.pressed.connect(_on_submit_pressed)
	guest_btn.pressed.connect(_on_guest_pressed)

	# Kiểm tra quyền: Chỉ hiển thị thanh Tester 1-9 trên máy dev của bạn
	var is_dev = is_dev_machine()
	quick_login_bar.visible = is_dev

	if is_dev:
		for i in range(1, 10):
			var btn = quick_hbox.get_node_or_null("Quick" + str(i))
			if btn:
				var num = i
				btn.pressed.connect(func(): _on_quick_login(num))

	AuthManager.login_succeeded.connect(_on_login_succeeded)
	AuthManager.login_failed.connect(_on_login_failed)

	# Điền sẵn email cũ nếu đã lưu
	if AuthManager.current_user_email != "":
		email_input.text = AuthManager.current_user_email

	set_register_mode(false)
	status_lbl.text = ""

	if "--screenshot" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://auth_screenshot.png")
		print("[Screenshot] Đã lưu auth_screenshot.png!")
		get_tree().quit()

func is_dev_machine() -> bool:
	var u = OS.get_environment("USERNAME").strip_edges().to_lower()
	if u == "ph laptop" or u == "phlaptop":
		return true
	if FileAccess.file_exists("res://.dev_machine"):
		return true
	if OS.is_debug_build() or OS.has_feature("editor"):
		return true
	return false

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

func set_register_mode(register: bool) -> void:
	is_register_mode = register
	name_group.visible = register

	if is_register_mode:
		tab_register_line.visible = true
		tab_login_line.visible = false
		submit_btn.text = "🎖️ ĐĂNG KÝ TÀI KHOẢN MỚI"
		tab_register_btn.modulate = Color(1, 1, 1, 1)
		tab_login_btn.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		tab_login_line.visible = true
		tab_register_line.visible = false
		submit_btn.text = "⚔️ ĐĂNG NHẬP CHIẾN TƯỚNG"
		tab_login_btn.modulate = Color(1, 1, 1, 1)
		tab_register_btn.modulate = Color(0.7, 0.7, 0.7, 1)

func _on_submit_pressed() -> void:
	var email = email_input.text.strip_edges()
	var password = pass_input.text

	if is_register_mode:
		var n = name_input.text.strip_edges()
		_set_status("Đang lập danh xưng chiến tướng...", Color("#D4AF37"))
		submit_btn.disabled = true
		AuthManager.register_email(email, password, n)
	else:
		_set_status("Đang xác thực thông tin chiến tướng...", Color("#D4AF37"))
		submit_btn.disabled = true
		AuthManager.login_email(email, password)

func _on_guest_pressed() -> void:
	_set_status("Đang khởi tạo phiên chơi khách...", Color("#D4AF37"))
	submit_btn.disabled = true
	AuthManager.login_anonymous()

func _on_quick_login(num: int) -> void:
	_set_status("Đang đăng nhập nhanh Tài khoản Tester %d..." % num, Color("#D4AF37"))
	submit_btn.disabled = true
	email_input.text = "vdthanh22%d@gmail.com" % num
	pass_input.text = "matkhau123"
	AuthManager.quick_login(num)

func _on_login_succeeded(user_data: Dictionary) -> void:
	_set_status("🎉 Đăng nhập thành công! Đang vào chiến trường...", Color("#10B981"))
	submit_btn.disabled = false
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_login_failed(err_msg: String) -> void:
	_set_status("❌ " + err_msg, Color("#EF4444"))
	submit_btn.disabled = false

func _set_status(msg: String, col: Color) -> void:
	status_lbl.text = msg
	status_lbl.modulate = col
