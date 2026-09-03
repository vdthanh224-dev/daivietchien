extends Control

@onready var player_avatar = $TableTop/PlayerArea/PlayerAvatar
@onready var boss_avatar = $TableTop/BossArea/BossAvatar
@onready var hand_container = $TableTop/HandCards
@onready var banner_title: Label = $TutorialBanner/Margin/VBox/StepTitle
@onready var banner_desc: Label = $TutorialBanner/Margin/VBox/StepDesc
@onready var next_step_btn: Button = $TutorialBanner/Margin/VBox/HBox/NextStepBtn
@onready var skip_btn: Button = $TutorialBanner/Margin/VBox/HBox/SkipBtn

@onready var btn_play: Button = $ActionPanel/BtnPlay
@onready var btn_end_turn: Button = $ActionPanel/BtnEndTurn
@onready var center_showcase = $CenterArea/CardShowcase
@onready var showcase_label = $CenterArea/CardShowcase/Margin/VBox/ShowcaseName

const CardUIScene = preload("res://scenes/components/card_ui.tscn")

var step_index: int = 1
var selected_card_ui: Control = null
var boss_hp: int = 4
var player_hp: int = 4

func _ready() -> void:
	# Khởi tạo tướng người chơi và boss bằng Reusable GeneralAvatarUI
	player_avatar.setup_general("tran_hung_dao", "Trần Hưng Đạo", "Trần", 4, 4, "BẠN")
	boss_avatar.setup_general("thu_linh_son_tac", "Thủ Lĩnh Sơn Tặc", "Sơn Tặc", 4, 4, "ĐỐI THỦ")

	next_step_btn.pressed.connect(_on_next_step_clicked)
	skip_btn.pressed.connect(_on_skip_clicked)
	btn_play.pressed.connect(_on_play_card_clicked)
	btn_end_turn.pressed.connect(_on_end_turn_clicked)

	_spawn_tutorial_cards()
	_apply_step(1)

	if "--screenshot" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_screenshot.png!")
		get_tree().quit()

func _spawn_tutorial_cards() -> void:
	for c in hand_container.get_children():
		c.queue_free()

	var cards_data = [
		{"name": "Trảm Thường", "rank": "A", "suit": "Spade", "cat": 0, "desc": "Tấn công gây 1 sát thương"},
		{"name": "Đỡ", "rank": "2", "suit": "Diamond", "cat": 0, "desc": "Hóa giải 1 đòn Trảm"},
		{"name": "Bánh Chưng", "rank": "3", "suit": "Heart", "cat": 0, "desc": "Hồi phục 1 đóa sen Máu"},
		{"name": "Khiên Mây Bện", "rank": "K", "suit": "Diamond", "cat": 1, "desc": "Phán xét Đỏ tự động Đỡ"}
	]

	for data in cards_data:
		var card_node = CardUIScene.instantiate()
		hand_container.add_child(card_node)
		card_node.setup_card_data("card_" + data["name"], data["name"], data["rank"], data["suit"], data["cat"], data["desc"])
		card_node.card_selected_state_changed.connect(_on_card_selected_state_changed)

func _on_card_selected_state_changed(card_ui: Control, is_sel: bool) -> void:
	if is_sel:
		if selected_card_ui and selected_card_ui != card_ui:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_ui
		btn_play.disabled = false
	else:
		if selected_card_ui == card_ui:
			selected_card_ui = null
			btn_play.disabled = true

func _apply_step(step: int) -> void:
	step_index = step
	match step:
		1:
			banner_title.text = "🌟 BƯỚC 1: LÀM QUEN TƯỚNG & MÁU HOA SEN"
			banner_desc.text = "Sinh mệnh của chiến tướng thể hiện qua các đóa hoa sen 🌸. Khi hết máu, tướng sẽ rơi vào trạng thái Hấp Hối.\nBên phải là 5 ô trang bị (Vũ khí, Giáp, Ngựa công, Ngựa thủ, Bảo vật)."
			next_step_btn.text = "TIẾP TỤC ➜"
			next_step_btn.visible = true
			btn_play.disabled = true
			btn_end_turn.disabled = true
		2:
			banner_title.text = "⚔️ BƯỚC 2: TẬP KÍCH TRẢM TẤN CÔNG"
			banner_desc.text = "Mỗi lượt bạn được dùng 1 lá TRẢM. Hãy nhấp chọn lá [Trảm Thường] trên tay và bấm nút [⚔️ ĐÁNH BÀI] để tấn công Sơn Tặc!"
			next_step_btn.visible = false
			btn_play.disabled = (selected_card_ui == null)
			btn_end_turn.disabled = true
		3:
			banner_title.text = "🛡️ BƯỚC 3: PHÒNG THỦ & HÓA GIẢI ĐÒN ĐÁNH"
			banner_desc.text = "Sơn Tặc phản công bằng một lá [Trảm] hung bạo!\nHãy nhấp chọn lá [Đỡ] trên tay bạn và bấm [⚔️ ĐÁNH BÀI] để triệt tiêu đòn đánh!"
			next_step_btn.visible = false
			btn_play.disabled = (selected_card_ui == null)
			btn_end_turn.disabled = true
		4:
			banner_title.text = "🎉 BƯỚC 4: HOÀN THÀNH HUẤN LUYỆN TÂN THỦ!"
			banner_desc.text = "Tuyệt vời! Bạn đã nắm vững các quy tắc cốt lõi: Ra chiêu, Phòng thủ và Quản lý sinh mệnh.\nChiến trường Đại Việt 2v2 đang chờ lệnh xuất chinh của bạn!"
			next_step_btn.text = "XUẤT CHINH VÀO CHIẾN TRƯỜNG ➜"
			next_step_btn.visible = true
			btn_play.disabled = true
			btn_end_turn.disabled = true

func _on_next_step_clicked() -> void:
	if step_index == 1:
		_apply_step(2)
	elif step_index == 4:
		_finish_tutorial()

func _on_play_card_clicked() -> void:
	if not selected_card_ui:
		return

	var card_name = selected_card_ui.card_name

	if step_index == 2:
		if "Trảm" in card_name:
			# Đánh Trảm thành công
			show_card_play(card_name, "Trần Hưng Đạo")
			boss_hp -= 1
			boss_avatar.update_hp(boss_hp, 4)
			selected_card_ui.queue_free()
			selected_card_ui = null
			btn_play.disabled = true

			banner_title.text = "💥 TẤN CÔNG THÀNH CÔNG!"
			banner_desc.text = "Sơn Tặc bị trúng 1 đòn Trảm và mất 1 đóa sen máu!\nChuẩn bị bước sang lượt phòng thủ..."
			await get_tree().create_timer(1.2).timeout
			_boss_counter_attack()
		else:
			banner_desc.text = "⚠️ Ở bước này bạn cần chọn lá [Trảm Thường] để tấn công!"

	elif step_index == 3:
		if "Đỡ" in card_name:
			show_card_play(card_name, "Trần Hưng Đạo")
			selected_card_ui.queue_free()
			selected_card_ui = null
			btn_play.disabled = true

			banner_title.text = "🛡️ NÉ TRÁNH THÀNH CÔNG!"
			banner_desc.text = "Bạn đã dùng lá [Đỡ] hóa giải hoàn toàn đòn đánh của Sơn Tặc! Máu của bạn được bảo toàn nguyên vẹn."
			await get_tree().create_timer(1.2).timeout
			_apply_step(4)
		else:
			banner_desc.text = "⚠️ Sơn Tặc đang chém Trảm tới! Bạn hãy chọn lá [Đỡ] để né tránh!"

func _boss_counter_attack() -> void:
	show_card_play("Trảm Hung Bạo", "Thủ Lĩnh Sơn Tặc")
	_apply_step(3)

func show_card_play(c_name: String, source: String) -> void:
	showcase_label.text = "%s dùng [%s]!" % [source, c_name]
	center_showcase.visible = true
	var tw = create_tween()
	tw.tween_property(center_showcase, "scale", Vector2(1.15, 1.15), 0.15).from(Vector2(0.8, 0.8))
	tw.tween_property(center_showcase, "scale", Vector2(1.0, 1.0), 0.1)
	await get_tree().create_timer(1.0).timeout
	center_showcase.visible = false

func _on_end_turn_clicked() -> void:
	pass

func _on_skip_clicked() -> void:
	_finish_tutorial()

func _finish_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
