extends Control

@onready var player_avatar = $TableTop/PlayerArea/PlayerAvatar
@onready var boss_avatar = $TableTop/BossArea/BossAvatar
@onready var hand_container = $TableTop/HandCards
@onready var deck_label: Label = $TableTop/DeckHUD/DeckPlaque/DeckLabel
@onready var log_text: RichTextLabel = $TableTop/LogPanel/Margin/VBox/Scroll/LogText
@onready var desc_text: Label = $TableTop/CardDescBar/Margin/DescText

@onready var banner: PanelContainer = $TutorialBanner
@onready var banner_title: Label = $TutorialBanner/Margin/VBox/StepTitle
@onready var banner_desc: Label = $TutorialBanner/Margin/VBox/StepDesc
@onready var action_btn: Button = $TutorialBanner/Margin/VBox/HBox/ActionBtn

@onready var arrow_node: Control = $TutorialArrow
@onready var arrow_label: Label = $TutorialArrow/ArrowLabel

@onready var center_showcase = $CenterArea/CardShowcase
@onready var showcase_label = $CenterArea/CardShowcase/ShowcaseName

@onready var spotlight_overlay = $HealthSpotlightOverlay
@onready var start_tutorial_btn = $HealthSpotlightOverlay/HealthGuideBox/Margin/VBox/StartTutorialBtn

@onready var reward_modal = $RewardModal
@onready var claim_reward_btn = $RewardModal/Dim/Box/Margin/VBox/ClaimBtn

const CardUIScene = preload("res://scenes/components/card_ui.tscn")

var current_step: int = 1
var player_hp: int = 4
var boss_hp: int = 3
var deck_count: int = 52
var selected_card_ui: Control = null
var boss_targeted: bool = false
var arrow_target_pos: Vector2 = Vector2.ZERO
var arrow_time: float = 0.0

func _ready() -> void:
	# 1. Khởi tạo Tướng Lý Thường Kiệt (Người chơi - Góc dưới phải)
	player_avatar.setup_general("ly_thuong_kiet", "Lý Thường Kiệt", "Khác", 4, 4, "BẠN")
	player_avatar.set_skill("⚡ TIẾN THOÁI")
	player_avatar.skill_clicked.connect(_on_player_skill_clicked)

	# 2. Khởi tạo Tướng Thủ Lĩnh Sơn Tặc (Boss - Trên cùng giữa)
	boss_avatar.setup_general("thu_linh_son_tac", "Thủ Lĩnh Sơn Tặc", "Sơn Tặc", 3, 3, "ĐỐI THỦ")
	boss_avatar.clicked.connect(_on_boss_avatar_clicked)

	# 3. Kết nối các nút
	start_tutorial_btn.pressed.connect(_on_close_health_spotlight)
	action_btn.pressed.connect(_on_action_btn_clicked)
	claim_reward_btn.pressed.connect(_on_claim_reward_clicked)

	# 4. Hiển thị Bước 1: Máu hoa sen
	spotlight_overlay.visible = true
	reward_modal.visible = false
	arrow_node.visible = false
	center_showcase.visible = false

	_add_log("• Trận chiến huấn luyện khởi động.")

	if "--screenshot" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-step2" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_gameplay_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_gameplay_screenshot.png!")
		get_tree().quit()

func _process(delta: float) -> void:
	# Hiệu ứng nhấp nhô mũi tên hướng dẫn
	if arrow_node and arrow_node.visible:
		arrow_time += delta * 6.0
		var bob = sin(arrow_time) * 6.0
		arrow_node.position = arrow_target_pos + Vector2(bob, 0)

func _add_log(msg: String) -> void:
	log_text.text += "\n" + msg

func _on_close_health_spotlight() -> void:
	spotlight_overlay.visible = false
	_add_log("💮 Hoàn thành tìm hiểu Sinh mệnh Hoa sen.")
	_start_step_2_draw()

func _start_step_2_draw() -> void:
	current_step = 2
	banner_title.text = "📜 GIAI ĐOẠN 1: RÚT BÀI ĐẦU LƯỢT"
	banner_desc.text = "Người đầu tiên chơi sẽ BỐC 1 LÁ BÀI; các lượt sau tự động bốc 2 lá từ kho bài!"
	action_btn.text = "VÀO GIAI ĐOẠN RA BÀI ➜"
	action_btn.disabled = false

	# Chia 4 lá ban đầu + 1 lá rút đầu lượt
	_spawn_initial_cards()
	deck_count -= 5
	deck_label.text = "🎴 %d" % deck_count
	_add_log("📜 LƯỢT ĐẦU: Rút 1 lá bài từ kho bài vào tay.")

func _spawn_initial_cards() -> void:
	for c in hand_container.get_children():
		c.queue_free()

	var cards_data = [
		{"name": "Trảm Thường", "rank": "A", "suit": "Spade", "cat": 0, "desc": "Tấn công gây 1 sát thương."},
		{"name": "Trảm Thường", "rank": "2", "suit": "Spade", "cat": 0, "desc": "Tấn công gây 1 sát thương."},
		{"name": "Đỡ", "rank": "3", "suit": "Diamond", "cat": 0, "desc": "Hóa giải 1 đòn Trảm."},
		{"name": "Bánh Chưng", "rank": "4", "suit": "Heart", "cat": 0, "desc": "Hồi phục 1 Máu."},
		{"name": "Khiên Mây Bện", "rank": "K", "suit": "Diamond", "cat": 1, "desc": "Phán xét Đỏ tự động Đỡ."}
	]

	for data in cards_data:
		var card_node = CardUIScene.instantiate()
		hand_container.add_child(card_node)
		card_node.setup_card_data("card_" + data["name"], data["name"], data["rank"], data["suit"], data["cat"], data["desc"])
		card_node.card_selected_state_changed.connect(_on_card_selected_state_changed)
		card_node.mouse_entered.connect(func(): _on_card_hovered(card_node))

func _on_card_hovered(c_ui: Control) -> void:
	if c_ui and c_ui.card_data:
		var d = c_ui.card_data
		desc_text.text = "💡 [%s %s %s] %s" % [d.card_name, d.get_suit_symbol() + str(d.rank), d.get_category_name(), d.description]

func _on_card_selected_state_changed(card_ui: Control, is_sel: bool) -> void:
	if is_sel:
		if selected_card_ui and selected_card_ui != card_ui:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_ui
		_on_card_hovered(card_ui)
		_handle_card_selected(card_ui)
	else:
		if selected_card_ui == card_ui:
			selected_card_ui = null
			desc_text.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng..."

func _handle_card_selected(c_ui: Control) -> void:
	if current_step == 3:
		if "Trảm" in c_ui.card_name:
			banner_desc.text = "🎯 Hãy chạm chọn THỦ LĨNH SƠN TẶC trên bàn đấu làm mục tiêu tấn công!"
			_show_arrow(boss_avatar.global_position + Vector2(180, 80), "CHỌN MỤC TIÊU")
			action_btn.disabled = true
			action_btn.text = "🎯 HÃY CHỌN MỤC TIÊU SƠN TẶC"
	elif current_step == 5:
		if "Đỡ" in c_ui.card_name:
			banner_desc.text = "Nhấn nút [🛡️ DÙNG ĐỠ (NÉ ĐÒN)] để triệt tiêu đòn Trảm của Sơn Tặc!"
			action_btn.disabled = false
			action_btn.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)"
			_show_arrow(action_btn.global_position + Vector2(-90, 10), "XÁC NHẬN NÉ")

func _on_boss_avatar_clicked() -> void:
	if current_step == 3 and selected_card_ui and "Trảm" in selected_card_ui.card_name:
		boss_targeted = true
		boss_avatar.set_target_highlight(true)
		banner_desc.text = "🎯 Đã nhắm mục tiêu Sơn Tặc! Nhấn nút [⚔️ DÙNG BÀI ➜ SƠN TẶC] để tấn công!"
		action_btn.disabled = false
		action_btn.text = "⚔️ DÙNG BÀI ➜ SƠN TẶC"
		_show_arrow(action_btn.global_position + Vector2(-90, 10), "TẤN CÔNG")

func _on_action_btn_clicked() -> void:
	match current_step:
		2:
			_start_step_3_slash()
		3:
			if boss_targeted and selected_card_ui:
				_execute_slash()
		4:
			_start_step_4_5_skill()
		41: # Sau khi thi triển kỹ năng
			_start_step_5_boss_turn()
		5:
			_execute_dodge()

func _start_step_3_slash() -> void:
	current_step = 3
	boss_targeted = false
	banner_title.text = "⚔️ GIAI ĐOẠN 2: RA BÀI (DÙNG TRẢM)"
	banner_desc.text = "Hãy chạm chọn lá bài [TRẢM THƯỜNG] đang phát sáng trên tay!"
	action_btn.text = "⚔️ CHỌN LÁ TRẢM"
	action_btn.disabled = true

	# Chỉ mũi tên vào lá Trảm đầu tiên
	if hand_container.get_child_count() > 0:
		var first_card = hand_container.get_child(0)
		_show_arrow(first_card.global_position + Vector2(40, -40), "CHỌN TRẢM")

func _execute_slash() -> void:
	boss_avatar.set_target_highlight(false)
	arrow_node.visible = false
	selected_card_ui.queue_free()
	selected_card_ui = null

	boss_hp -= 1
	boss_avatar.update_hp(boss_hp, 3)

	_show_center_card("Trảm Thường", "Lý Thường Kiệt")
	_add_log("⚔️ Bạn đã dùng TRẢM! Thủ Lĩnh Sơn Tặc trúng đòn mất 1 máu (%d/3)." % boss_hp)

	current_step = 4
	banner_title.text = "⚠️ QUY TẮC: MỖI TURN CHỈ ĐƯỢC DÙNG 1 LÁ TRẢM"
	banner_desc.text = "Trong cùng một lượt, mỗi người chơi chỉ được ra TỐI ĐA 1 LÁ TRẢM (trừ khi trang bị Nỏ Thần Kim Quy)!\nBây giờ, hãy tìm hiểu kỹ năng độc quyền của tướng."
	action_btn.disabled = false
	action_btn.text = "TÌM HIỂU KỸ NĂNG TƯỚNG ➜"

func _start_step_4_5_skill() -> void:
	current_step = 40
	banner_title.text = "⚡ KỸ NĂNG ĐẶC BIỆT: [TIẾN THOÁI]"
	banner_desc.text = "Tướng Lý Thường Kiệt sở hữu tuyệt kỹ TIẾN THOÁI:\nHoán chuyển tất cả lá TRẢM trên tay thành ĐỠ, và tất cả ĐỠ thành TRẢM!\nHãy click nút [⚡ TIẾN THOÁI] bên cạnh tướng để biến đổi bài."
	action_btn.visible = false

	# Chỉ mũi tên vào nút Tiến Thoái của Lý Thường Kiệt
	_show_arrow(player_avatar.global_position + Vector2(-110, 50), "BẤM TIẾN THOÁI")

func _on_player_skill_clicked() -> void:
	if current_step == 40:
		arrow_node.visible = false
		# Biến đổi Trảm thành Đỡ trên tay
		var count = 0
		for c in hand_container.get_children():
			if "Trảm" in c.card_name:
				c.setup_card_data(c.card_data.id, "Đỡ", "A", "Spade", 0, "Hóa giải 1 đòn Trảm.")
				count += 1

		_add_log("✨ LÝ THƯỜNG KIỆT THI TRIỂN [TIẾN THOÁI]! Đã hoán chuyển %d lá Trảm ⟷ Đỡ trên tay!" % count)

		current_step = 41
		banner_title.text = "🎉 BIẾN ĐỔI THÀNH CÔNG!"
		banner_desc.text = "Toàn bộ lá Trảm trên tay đã hóa thành lá ĐỠ (NÉ) sẵn sàng phòng thủ!\nBạn đã dùng xong bài trong lượt. Hãy nhấn [KẾT THÚC LƯỢT]!"
		action_btn.visible = true
		action_btn.disabled = false
		action_btn.text = "KẾT THÚC LƯỢT ➜"

func _start_step_5_boss_turn() -> void:
	current_step = 5
	action_btn.visible = true
	action_btn.disabled = true
	banner_title.text = "👺 ĐẾN LƯỢT THỦ LĨNH SƠN TẶC!"
	banner_desc.text = "Sơn Tặc tự động rút 2 lá bài và chuẩn bị ra đòn..."
	_add_log("👺 Đến lượt Thủ Lĩnh Sơn Tặc.")

	deck_count -= 2
	deck_label.text = "🎴 %d" % deck_count
	await get_tree().create_timer(1.2).timeout

	_show_center_card("Trảm Hung Bạo", "Thủ Lĩnh Sơn Tặc")
	_add_log("💥 Sơn Tặc vung đao tung chiêu [TRẢM] nhắm thẳng vào bạn!")

	banner_title.text = "🛡️ CẢNH BÁO BỊ TẤN CÔNG!"
	banner_desc.text = "Sơn Tặc vừa tung đòn TRẢM! Hãy chọn lá [ĐỠ] trên tay để vô hiệu hóa đòn đánh!"

	# Tìm lá Đỡ trên tay và chỉ mũi tên vào
	for c in hand_container.get_children():
		if "Đỡ" in c.card_name:
			_show_arrow(c.global_position + Vector2(40, -40), "CHỌN ĐỠ")
			break

func _execute_dodge() -> void:
	arrow_node.visible = false
	if selected_card_ui:
		selected_card_ui.queue_free()
		selected_card_ui = null

	_show_center_card("Đỡ", "Lý Thường Kiệt")
	_add_log("🛡️ HOÁ GIẢI THÀNH CÔNG! Bạn đã dùng Đỡ né hoàn toàn đòn Trảm của Sơn Tặc! Sinh mệnh 4/4 của bạn được bảo toàn.")

	await get_tree().create_timer(1.2).timeout
	_show_reward_modal()

func _show_reward_modal() -> void:
	arrow_node.visible = false
	reward_modal.visible = true
	banner.visible = false
	_add_log("🏆 CHÚC MỪNG HOÀN THÀNH HUẤN LUYỆN TÂN THỦ!")
	var box = reward_modal.get_node("Dim/Box")
	var tw = create_tween()
	tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.25).from(Vector2(0.7, 0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_arrow(pos: Vector2, text: String) -> void:
	arrow_target_pos = pos
	arrow_label.text = text
	arrow_node.position = pos
	arrow_node.visible = true
	arrow_time = 0.0

func _show_center_card(c_name: String, source: String) -> void:
	showcase_label.text = "%s dùng [%s]!" % [source, c_name]
	center_showcase.visible = true
	var tw = create_tween()
	tw.tween_property(center_showcase, "scale", Vector2(1.15, 1.15), 0.15).from(Vector2(0.8, 0.8))
	tw.tween_property(center_showcase, "scale", Vector2(1.0, 1.0), 0.1)
	await get_tree().create_timer(1.2).timeout
	center_showcase.visible = false

func _on_claim_reward_clicked() -> void:
	AuthManager.set_onboarding_done()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
