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
@onready var btn_dodge_response: Button = $ActionPanel/BtnDodgeResponse

@onready var center_showcase = $CenterArea/CardShowcase
@onready var showcase_label = $CenterArea/CardShowcase/Margin/VBox/ShowcaseName

@onready var reward_modal = $RewardModal
@onready var claim_reward_btn = $RewardModal/Dim/Box/Margin/VBox/ClaimBtn

const CardUIScene = preload("res://scenes/components/card_ui.tscn")

var step_index: int = 1
var selected_card_ui: Control = null
var boss_hp: int = 4
var player_hp: int = 4
var has_slashed_this_turn: bool = false

func _ready() -> void:
	player_avatar.setup_general("tran_hung_dao", "Trần Hưng Đạo", "Trần", 4, 4, "BẠN")
	boss_avatar.setup_general("thu_linh_son_tac", "Thủ Lĩnh Sơn Tặc", "Sơn Tặc", 4, 4, "ĐỐI THỦ")

	next_step_btn.pressed.connect(_on_next_step_clicked)
	skip_btn.pressed.connect(_on_skip_clicked)
	btn_play.pressed.connect(_on_play_card_clicked)
	btn_end_turn.pressed.connect(_on_end_turn_clicked)
	btn_dodge_response.pressed.connect(_on_dodge_response_clicked)
	claim_reward_btn.pressed.connect(_on_claim_reward_clicked)

	reward_modal.visible = false
	btn_dodge_response.visible = false

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
		{"name": "Trảm Thường", "rank": "A", "suit": "Spade", "cat": 0, "desc": "Tấn công gây 1 sát thương."},
		{"name": "Đỡ", "rank": "2", "suit": "Diamond", "cat": 0, "desc": "Hóa giải 1 đòn Trảm."},
		{"name": "Bánh Chưng", "rank": "3", "suit": "Heart", "cat": 0, "desc": "Hồi phục 1 Máu."},
		{"name": "Khiên Mây Bện", "rank": "K", "suit": "Diamond", "cat": 1, "desc": "Phán xét Đỏ tự động Đỡ."}
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
			banner_title.text = "🌸 BƯỚC 1: SINH MỆNH HOA SEN & 5 DÒNG TRANG BỊ"
			banner_desc.text = "Mỗi đóa hoa sen 🌸 đại diện cho 1 điểm máu. Khi hết máu, tướng sẽ rơi vào trạng thái Hấp Hối.\nBên hông là 5 vị trí trang bị (Vũ khí, Giáp, Ngựa công, Ngựa thủ, Bảo vật)."
			next_step_btn.text = "BƯỚC 2: RÚT BÀI & TẤN CÔNG ➜"
			next_step_btn.visible = true
			btn_play.visible = true
			btn_play.disabled = true
			btn_end_turn.visible = true
			btn_end_turn.disabled = true
			btn_dodge_response.visible = false
		2:
			banner_title.text = "⚔️ BƯỚC 2: TẬP KÍCH TRẢM VÀO SƠN TẶC"
			banner_desc.text = "Đầu lượt bạn được rút bài. Hãy nhấp chọn lá [TRẢM THƯỜNG] trên tay và bấm nút [⚔️ ĐÁNH BÀI] để tấn công Sơn Tặc!"
			next_step_btn.visible = false
			btn_play.visible = true
			btn_play.disabled = (selected_card_ui == null)
			btn_end_turn.disabled = true
			btn_dodge_response.visible = false
		3:
			banner_title.text = "🛑 BƯỚC 3: QUY TẮC 1 TRẢM MỖI LƯỢT"
			banner_desc.text = "Trong mỗi lượt, bạn chỉ được dùng tối đa 1 lá Trảm (trừ khi có Nỏ Thần).\nBạn đã dùng Trảm rồi nên không thể đánh tiếp. Hãy bấm nút [🛑 KẾT THÚC LƯỢT] để nhường lượt cho đối phương!"
			next_step_btn.visible = false
			btn_play.disabled = true
			btn_end_turn.disabled = false
			btn_dodge_response.visible = false
		4:
			banner_title.text = "🛡️ BƯỚC 4: SƠN TẶC PHẢN CÔNG - DÙNG ĐỠ NÉ TRÁNH!"
			banner_desc.text = "⚠️ NGUY HIỂM! Sơn Tặc dùng [Trảm Hung Bạo] chém bạn!\nHãy nhấp chọn lá [ĐỠ] trên tay và bấm nút [🛡️ DÙNG ĐỠ NÉ TRÁNH] để triệt tiêu đòn đánh!"
			next_step_btn.visible = false
			btn_play.visible = false
			btn_end_turn.visible = false
			btn_dodge_response.visible = true
			btn_dodge_response.disabled = false
		5:
			banner_title.text = "🎉 HOÀN THÀNH XUẤT SẮC KHÓA TÂN THỦ!"
			banner_desc.text = "Bạn đã nắm vững toàn bộ quy tắc cốt lõi: Ra chiêu, Quy tắc lượt đấu, và Phòng thủ né đòn!"
			next_step_btn.visible = false
			btn_play.visible = false
			btn_end_turn.visible = false
			btn_dodge_response.visible = false
			_show_reward_modal()

func _on_next_step_clicked() -> void:
	if step_index == 1:
		_apply_step(2)

func _on_play_card_clicked() -> void:
	if not selected_card_ui:
		return

	var c_name = selected_card_ui.card_name

	if step_index == 2:
		if "Trảm" in c_name:
			has_slashed_this_turn = true
			show_card_play(c_name, "Trần Hưng Đạo")
			boss_hp -= 1
			boss_avatar.update_hp(boss_hp, 4)
			selected_card_ui.queue_free()
			selected_card_ui = null
			btn_play.disabled = true

			banner_title.text = "💥 TẤN CÔNG THÀNH CÔNG!"
			banner_desc.text = "Sơn Tặc bị trúng Trảm và mất 1 đóa hoa sen máu!\nChuẩn bị tìm hiểu quy tắc kết thúc lượt..."
			await get_tree().create_timer(1.2).timeout
			_apply_step(3)
		else:
			banner_desc.text = "⚠️ Ở bước này bạn cần chọn lá [Trảm Thường] có hình thanh kiếm để tấn công!"

func _on_end_turn_clicked() -> void:
	if step_index == 3:
		btn_end_turn.disabled = true
		banner_title.text = "⏳ ĐẾN LƯỢT CỦA SƠN TẶC..."
		banner_desc.text = "Sơn Tặc rút 2 lá bài và chuẩn bị xuất chiêu..."
		await get_tree().create_timer(1.2).timeout
		show_card_play("Trảm Hung Bạo", "Thủ Lĩnh Sơn Tặc")
		await get_tree().create_timer(0.8).timeout
		_apply_step(4)

func _on_dodge_response_clicked() -> void:
	if step_index == 4:
		# Kiểm tra xem người chơi đã chọn lá Đỡ chưa
		var dodge_card: Control = null
		if selected_card_ui and "Đỡ" in selected_card_ui.card_name:
			dodge_card = selected_card_ui
		else:
			# Tìm lá Đỡ trên tay
			for c in hand_container.get_children():
				if "Đỡ" in c.card_name:
					dodge_card = c
					break

		if dodge_card:
			show_card_play("Đỡ", "Trần Hưng Đạo")
			dodge_card.queue_free()
			selected_card_ui = null
			banner_title.text = "🛡️ NÉ TRÁNH THÀNH CÔNG!"
			banner_desc.text = "Bạn đã dùng lá [Đỡ] hóa giải hoàn toàn đòn đánh của Sơn Tặc! Sinh mệnh 4/4 của bạn được bảo toàn."
			await get_tree().create_timer(1.4).timeout
			_apply_step(5)
		else:
			banner_desc.text = "⚠️ Hãy chọn lá [Đỡ] có biểu tượng khiên trên tay bạn!"

func _show_reward_modal() -> void:
	reward_modal.visible = true
	var box = reward_modal.get_node("Dim/Box")
	var tw = create_tween()
	tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.25).from(Vector2(0.7, 0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_claim_reward_clicked() -> void:
	AuthManager.set_onboarding_done()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_skip_clicked() -> void:
	AuthManager.set_onboarding_done()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func show_card_play(c_name: String, source: String) -> void:
	showcase_label.text = "%s dùng [%s]!" % [source, c_name]
	center_showcase.visible = true
	var tw = create_tween()
	tw.tween_property(center_showcase, "scale", Vector2(1.15, 1.15), 0.15).from(Vector2(0.8, 0.8))
	tw.tween_property(center_showcase, "scale", Vector2(1.0, 1.0), 0.1)
	await get_tree().create_timer(1.0).timeout
	center_showcase.visible = false
