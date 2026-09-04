extends Control

@onready var player_avatar = $TableTop/PlayerArea/PlayerAvatar
@onready var boss_avatar = $TableTop/BossArea/BossAvatar
@onready var hand_container = $TableTop/HandCards
@onready var deck_label: Label = $TableTop/DeckHUD/DeckPlaque/DeckLabel
@onready var log_text: RichTextLabel = $TableTop/LogPanel/Margin/VBox/Scroll/LogText
@onready var desc_text: Label = $TableTop/CardDescBar/Margin/DescText
@onready var card_play_btn: Button = $TableTop/CardPlayBtn
@onready var end_turn_btn: Button = $TableTop/EndTurnBtn

@onready var banner: PanelContainer = $TutorialBanner
@onready var banner_title: Label = $TutorialBanner/Margin/VBox/StepTitle
@onready var banner_desc: Label = $TutorialBanner/Margin/VBox/StepDesc
@onready var action_btn: Button = $TutorialBanner/Margin/VBox/HBox/ActionBtn

@onready var arrow_node: Control = $TutorialArrow
@onready var arrow_label: Label = $TutorialArrow/ArrowLabel

@onready var center_showcase = $CenterArea/CardShowcase
@onready var showcase_card_slot = $CenterArea/CardShowcase/CardSlot
@onready var showcase_label = $CenterArea/CardShowcase/ActionBanner/ShowcaseName

var showcase_tween: Tween = null

@onready var spotlight_overlay = $HealthSpotlightOverlay
@onready var start_tutorial_btn = $HealthSpotlightOverlay/HealthGuideBox/Margin/VBox/StartTutorialBtn

@onready var reward_modal = $RewardModal
@onready var claim_reward_btn = $RewardModal/Dim/Box/Margin/VBox/ClaimBtn

@onready var general_info_modal = $GeneralInfoModal
@onready var info_close_x_btn = $GeneralInfoModal/Dim/Box/Margin/VBox/HeaderHBox/CloseXBtn
@onready var info_close_btn = $GeneralInfoModal/Dim/Box/Margin/VBox/CloseModalBtn
@onready var info_modal_title = $GeneralInfoModal/Dim/Box/Margin/VBox/HeaderHBox/ModalTitle
@onready var info_portrait_thumb = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitThumb
@onready var info_hero_name = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/LeftCol/HeroName
@onready var info_hero_stats = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/LeftCol/HeroStats
@onready var info_skill_title = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/SkillBox/Margin/VBox/SkillTitle
@onready var info_skill_desc = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/SkillBox/Margin/VBox/SkillDesc
@onready var info_eq_weapon = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/EqList/EqWeapon
@onready var info_eq_armor = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/EqList/EqArmor
@onready var info_eq_off_mount = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/EqList/EqOffMount
@onready var info_eq_def_mount = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/EqList/EqDefMount
@onready var info_eq_treasure = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/EqList/EqTreasure

const CardUIScene = preload("res://scenes/components/card_ui.tscn")

var current_step: int = 1
var player_hp: int = 4
var boss_hp: int = 3
var deck_count: int = 52
var selected_card_ui: Control = null
var boss_targeted: bool = false
var arrow_target_pos: Vector2 = Vector2.ZERO
var arrow_time: float = 0.0

# Chế độ thực chiến tự do (Free Play)
var is_free_battle: bool = false
var slashes_used_this_turn: int = 0
var is_player_turn: bool = true
var is_waiting_dodge_reaction: bool = false
var is_in_free_discard_phase: bool = false

func _ready() -> void:
	# Bắt đầu phát nhạc nền chiến trận hào hùng
	AudioManager.play_bgm("bgm_battle")

	# 1. Khởi tạo Tướng Lý Thường Kiệt (Người chơi - Góc dưới phải)
	player_avatar.setup_general("ly_thuong_kiet", "Lý Thường Kiệt", "Khác", 4, 4, "BẠN")
	player_avatar.set_skill("⚡ TIẾN THOÁI")
	player_avatar.skill_clicked.connect(_on_player_skill_clicked)
	player_avatar.info_clicked.connect(func(): _show_general_info_modal("player"))

	# 2. Khởi tạo Tướng Thủ Lĩnh Sơn Tặc (Boss - Trên cùng giữa)
	boss_avatar.setup_general("thu_linh_son_tac", "Thủ Lĩnh Sơn Tặc", "Sơn Tặc", 3, 3, "ĐỐI THỦ")
	boss_avatar.clicked.connect(_on_boss_avatar_clicked)
	boss_avatar.info_clicked.connect(func(): _show_general_info_modal("boss"))

	# 3. Kết nối các nút
	start_tutorial_btn.pressed.connect(_on_close_health_spotlight)
	action_btn.pressed.connect(_on_action_btn_clicked)
	card_play_btn.pressed.connect(_on_card_play_btn_clicked)
	end_turn_btn.pressed.connect(_on_end_turn_btn_clicked)
	claim_reward_btn.pressed.connect(_on_claim_reward_clicked)
	info_close_x_btn.pressed.connect(_hide_general_info_modal)
	info_close_btn.pressed.connect(_hide_general_info_modal)

	# 4. Hiển thị Bước 1: Máu hoa sen
	spotlight_overlay.visible = true
	reward_modal.visible = false
	general_info_modal.visible = false
	arrow_node.visible = false
	center_showcase.visible = false
	card_play_btn.visible = false
	end_turn_btn.visible = false

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
	elif "--screenshot-target" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		if hand_container.get_child_count() > 0:
			var c = hand_container.get_child(0)
			c.set_selected(true)
			_on_boss_avatar_clicked()
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_target_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_target_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-showcase" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		_show_center_card("Trảm Thường", "Lý Thường Kiệt", "A", "Spade", 0, "Tấn công gây 1 sát thương.")
		await get_tree().create_timer(0.35).timeout
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_showcase_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_showcase_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-equip" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		player_avatar.set_equipment("weapon", "Kiếm Thuận Thiên", "♦A")
		player_avatar.set_equipment("armor", "Khiên Mây Bện", "♦K")
		player_avatar.set_equipment("offensive_mount", "Ngựa Trắng", "♠5")
		player_avatar.set_equipment("defensive_mount", "Voi Chiến", "♥K")
		player_avatar.set_equipment("treasure", "Bảo Vật Quốc Gia", "♥Q")
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_equip_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_equip_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-modal" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		player_avatar.set_equipment("weapon", "Kiếm Thuận Thiên", "♦A")
		player_avatar.set_equipment("armor", "Khiên Mây Bện", "♦K")
		player_avatar.set_equipment("defensive_mount", "Voi Chiến", "♥K")
		player_avatar.set_equipment("offensive_mount", "Ngựa Trắng", "♠5")
		player_avatar.set_equipment("treasure", "Bảo Vật Quốc Gia", "♥Q")
		_show_general_info_modal("player")
		await get_tree().create_timer(0.3).timeout
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_modal_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_modal_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-banh-chung" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_free_battle_mode()
		for c in hand_container.get_children():
			if "Bánh Chưng" in c.card_name:
				c.set_selected(true)
				break
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_banh_chung_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_banh_chung_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-dodge-no-dodge" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_free_battle_mode()
		# Remove any existing Đỡ cards from hand to test "no dodge" scenario
		for c in hand_container.get_children():
			if "Đỡ" in c.card_name:
				c.setup_card_data(c.card_data.id, "Trảm Thường", "2", "Club", 0, "Tấn công gây 1 sát thương.")
		_prompt_player_dodge_reaction()
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_dodge_prompt_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_dodge_prompt_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-dodge-after-skill" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_free_battle_mode()
		for c in hand_container.get_children():
			if "Đỡ" in c.card_name:
				c.setup_card_data(c.card_data.id, "Trảm Thường", "2", "Club", 0, "Tấn công gây 1 sát thương.")
		_prompt_player_dodge_reaction()
		# Player clicks skill Tiến Thoái!
		_on_player_skill_clicked()
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_dodge_after_skill_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_dodge_after_skill_screenshot.png!")
		get_tree().quit()
	elif "--test-click-info-btn" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_3_slash()
		player_avatar.set_equipment("weapon", "Kiếm Thuận Thiên", "♦A")
		player_avatar.set_equipment("armor", "Khiên Mây Bện", "♦K")
		player_avatar.set_equipment("defensive_mount", "Voi Chiến", "♥K")
		player_avatar.set_equipment("offensive_mount", "Ngựa Trắng", "♠5")
		player_avatar.set_equipment("treasure", "Bảo Vật Quốc Gia", "♥Q")
		await get_tree().process_frame
		player_avatar.info_btn.emit_signal("pressed")
		await get_tree().create_timer(0.3).timeout
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_info_btn_clicked_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_info_btn_clicked_screenshot.png! Modal visible: ", general_info_modal.visible)
		get_tree().quit()
	elif "--screenshot-discard" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		_start_step_4_8_discard_lesson()
		await get_tree().process_frame
		if hand_container.get_child_count() > 0:
			hand_container.get_child(0).set_selected(true)
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_discard_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_discard_screenshot.png!")
		get_tree().quit()
	elif "--screenshot-avatar-slots" in OS.get_cmdline_user_args():
		_on_close_health_spotlight()
		player_avatar.set_equipment("weapon", "Kiếm Thuận Thiên", "♦A")
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://tutorial_avatar_slots_screenshot.png")
		print("[Screenshot] Đã lưu tutorial_avatar_slots_screenshot.png!")
		get_tree().quit()

func _process(delta: float) -> void:
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
	action_btn.visible = true
	action_btn.text = "VÀO GIAI ĐOẠN RA BÀI ➜"
	action_btn.disabled = false
	card_play_btn.visible = false

	# Chia 4 lá ban đầu + 1 lá rút đầu lượt
	_spawn_initial_cards()
	deck_count -= 5
	deck_label.text = "🎴 %d" % deck_count
	AudioManager.play_card_draw()
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
		_create_card_in_hand(data["name"], data["rank"], data["suit"], data["cat"], data["desc"])

func _create_card_in_hand(c_name: String, c_rank: String, c_suit: String, c_cat: int, c_desc: String) -> Control:
	var card_node = CardUIScene.instantiate()
	hand_container.add_child(card_node)
	card_node.setup_card_data("card_" + c_name, c_name, c_rank, c_suit, c_cat, c_desc)
	card_node.card_selected_state_changed.connect(_on_card_selected_state_changed)
	card_node.mouse_entered.connect(func(): _on_card_hovered(card_node))
	return card_node

func _on_card_hovered(c_ui: Control) -> void:
	if c_ui and c_ui.card_data:
		var d = c_ui.card_data
		desc_text.text = "💡 [%s %s %s] %s" % [d.card_name, d.get_suit_symbol() + str(d.rank), d.get_category_name(), d.description]

func _on_card_selected_state_changed(card_ui: Control, is_sel: bool) -> void:
	AudioManager.play_card_select()
	if is_sel:
		if selected_card_ui and selected_card_ui != card_ui:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_ui
		_on_card_hovered(card_ui)
		_handle_card_selected(card_ui)
	else:
		if selected_card_ui == card_ui:
			selected_card_ui = null
			if is_waiting_dodge_reaction:
				_update_dodge_reaction_ui()
			elif is_in_free_discard_phase:
				_update_free_discard_ui()
			elif current_step == 42:
				action_btn.disabled = true
				action_btn.text = "🗑️ HÃY CHỌN LÁ ĐỂ BỎ (1 LÁ THỪA)"
				desc_text.text = "🗑️ Hãy chọn 1 lá bài thừa trên tay để bỏ..."
				if hand_container.get_child_count() > 0:
					_show_arrow(hand_container.get_child(0).global_position + Vector2(-15, 80), "CHỌN LÁ ĐỂ BỎ")
			else:
				desc_text.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng..."
				card_play_btn.visible = false

func _handle_card_selected(c_ui: Control) -> void:
	if is_waiting_dodge_reaction:
		if "Đỡ" in c_ui.card_name:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)"
			desc_text.text = "🛡️ Đã chọn lá [%s]. Nhấn [🛡️ DÙNG ĐỠ (NÉ ĐÒN)] để hóa giải đòn Trảm!" % c_ui.card_name
		else:
			card_play_btn.visible = true
			card_play_btn.disabled = true
			card_play_btn.text = "🛡️ CẦN LÁ ĐỠ"
			desc_text.text = "⚠️ Bạn đang bị Sơn Tặc tấn công! Hãy chọn lá [ĐỠ] hoặc bấm [💔 CHỊU ĐÒN (-1)]."
		return

	if current_step == 42:
		action_btn.disabled = false
		action_btn.text = "🗑️ BỎ LÁ [%s] (1 LÁ THỪA)" % c_ui.card_name.to_upper()
		desc_text.text = "🗑️ Đã chọn lá [%s]. Nhấn nút [BỎ BÀI] ở góc trên để loại bỏ lá bài thừa!" % c_ui.card_name
		_show_arrow(action_btn.global_position + Vector2(-15, 21), "XÁC NHẬN BỎ")
		return

	if is_free_battle:
		_handle_free_battle_card_selected(c_ui)
		return

	if "Bánh Chưng" in c_ui.card_name and player_hp >= 4:
		desc_text.text = "⚠️ Máu của bạn đã đầy (4/4 đóa sen), không thể sử dụng Bánh Chưng!"
		card_play_btn.visible = true
		card_play_btn.disabled = true
		card_play_btn.text = "💮 MÁU ĐÃ ĐẦY (KHÔNG THỂ HỒI)"
		return

	if current_step == 3:
		if "Trảm" in c_ui.card_name:
			banner_desc.text = "🎯 Hãy chạm chọn THỦ LĨNH SƠN TẶC trên bàn đấu làm mục tiêu tấn công!"
			_show_arrow(boss_avatar.global_position + Vector2(-15, 115), "CHỌN MỤC TIÊU")
			card_play_btn.visible = true
			card_play_btn.disabled = true
			card_play_btn.text = "🎯 CHỌN MỤC TIÊU SƠN TẶC"
	elif current_step == 5:
		if "Đỡ" in c_ui.card_name:
			banner_desc.text = "Nhấn nút [🛡️ DÙNG ĐỠ (NÉ ĐÒN)] sát trên thanh mô tả để triệt tiêu đòn Trảm!"
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)"
			await get_tree().process_frame
			_show_arrow(card_play_btn.global_position + Vector2(-15, 21), "XÁC NHẬN NÉ")

func _handle_free_battle_card_selected(c_ui: Control) -> void:
	if is_waiting_dodge_reaction:
		if "Đỡ" in c_ui.card_name:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)"
			desc_text.text = "🛡️ Đã chọn lá [%s]. Nhấn [🛡️ DÙNG ĐỠ (NÉ ĐÒN)] để hóa giải đòn Trảm!" % c_ui.card_name
		else:
			card_play_btn.visible = true
			card_play_btn.disabled = true
			card_play_btn.text = "🛡️ CẦN LÁ ĐỠ"
			desc_text.text = "⚠️ Bạn đang bị Sơn Tặc tấn công! Hãy chọn lá [ĐỠ] hoặc bấm [💔 CHỊU ĐÒN (-1)]."
		return

	if is_in_free_discard_phase:
		var excess = hand_container.get_child_count() - player_hp
		if excess > 0:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "🗑️ BỎ LÁ [%s]" % c_ui.card_name.to_upper()
			desc_text.text = "🗑️ Đã chọn [%s]. Nhấn [BỎ BÀI] để loại bỏ (Cần bỏ %d lá thừa)." % [c_ui.card_name, excess]
		else:
			is_in_free_discard_phase = false
			card_play_btn.visible = false
		return

	if not is_player_turn:
		card_play_btn.visible = false
		return

	var c_name = c_ui.card_name
	if "Trảm" in c_name:
		if slashes_used_this_turn >= 1:
			desc_text.text = "⚠️ Mỗi lượt chỉ được dùng tối đa 1 lá Trảm (Đã dùng %d/1)!" % slashes_used_this_turn
			card_play_btn.visible = false
		else:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "⚔️ DÙNG BÀI ➜ SƠN TẶC"
	elif "Bánh Chưng" in c_name:
		if player_hp >= 4:
			desc_text.text = "⚠️ Máu của bạn đã đầy (4/4 đóa sen), không thể sử dụng Bánh Chưng!"
			card_play_btn.visible = true
			card_play_btn.disabled = true
			card_play_btn.text = "💮 MÁU ĐÃ ĐẦY (KHÔNG THỂ HỒI)"
		else:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "❤️ DÙNG BÁNH CHƯNG (+1 MÁU)"
	elif "Khiên" in c_name:
		card_play_btn.visible = true
		card_play_btn.disabled = false
		card_play_btn.text = "🛡️ TRANG BỊ KHIÊN MÂY"
	elif "Đỡ" in c_name:
		desc_text.text = "💡 Lá [ĐỠ] dùng khi bị tấn công để né đòn Trảm của đối phương!"
		card_play_btn.visible = false
	else:
		card_play_btn.visible = true
		card_play_btn.disabled = false
		card_play_btn.text = "🃏 DÙNG LÁ NÀY"

func _on_boss_avatar_clicked() -> void:
	if current_step == 3 and selected_card_ui and "Trảm" in selected_card_ui.card_name:
		boss_targeted = true
		boss_avatar.set_target_highlight(true)
		banner_desc.text = "🎯 Đã nhắm mục tiêu Sơn Tặc! Nhấn nút [⚔️ DÙNG BÀI ➜ SƠN TẶC] sát trên thanh mô tả để tấn công!"
		card_play_btn.visible = true
		card_play_btn.disabled = false
		card_play_btn.text = "⚔️ DÙNG BÀI ➜ SƠN TẶC"
		await get_tree().process_frame
		_show_arrow(card_play_btn.global_position + Vector2(-15, 21), "BẤM DÙNG BÀI")
	elif is_free_battle and selected_card_ui and "Trảm" in selected_card_ui.card_name:
		if slashes_used_this_turn < 1:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "⚔️ DÙNG BÀI ➜ SƠN TẶC"

func _on_card_play_btn_clicked() -> void:
	card_play_btn.release_focus()
	if is_waiting_dodge_reaction:
		_execute_free_play_dodge()
		return

	if is_in_free_discard_phase:
		_execute_free_play_discard()
		return

	if is_free_battle:
		_execute_free_card_play()
		return

	match current_step:
		3:
			if boss_targeted and selected_card_ui:
				_execute_slash()
		5:
			_execute_dodge()

func _on_action_btn_clicked() -> void:
	action_btn.release_focus()
	match current_step:
		2:
			_start_step_3_slash()
		4:
			_start_step_4_5_skill()
		41:
			_start_step_4_8_discard_lesson()
		42:
			_execute_tutorial_discard()
		6: # Bấm nút "BẮT ĐẦU THỰC CHIẾN ⚔️"
			_start_free_battle_mode()

func _start_step_3_slash() -> void:
	current_step = 3
	boss_targeted = false
	banner_title.text = "⚔️ GIAI ĐOẠN 2: RA BÀI (DÙNG TRẢM)"
	banner_desc.text = "Hãy chạm chọn lá bài [TRẢM THƯỜNG] đang có trên tay!"
	action_btn.visible = false
	card_play_btn.visible = false

	if hand_container.get_child_count() > 0:
		var first_card = hand_container.get_child(0)
		_show_arrow(first_card.global_position + Vector2(-15, 80), "CHỌN TRẢM")

func _execute_slash() -> void:
	boss_avatar.set_target_highlight(false)
	arrow_node.visible = false
	card_play_btn.visible = false

	# Âm thanh: Voice "Trảm" + Tiếng vung kiếm chém + Tiếng sát thương trúng đích
	AudioManager.play_voice("Trảm")
	AudioManager.play_slash()
	AudioManager.play_damage()

	# Hiệu ứng bài bay lên giữa bàn
	if selected_card_ui:
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null

	# Hiệu ứng đường chém vát chéo
	_play_slash_effect(boss_avatar.global_position + Vector2(87, 119))

	# Phản ứng mục tiêu (chớp đỏ + rung giật + số sát thương)
	boss_avatar.play_damage_effect()
	boss_avatar.spawn_damage_number(1)

	boss_hp -= 1
	boss_avatar.update_hp(boss_hp, 3)

	_show_center_card("Trảm Thường", "Lý Thường Kiệt", "A", "Spade", 0, "Tấn công gây 1 sát thương.")
	_add_log("⚔️ Bạn đã dùng TRẢM! Thủ Lĩnh Sơn Tặc trúng đòn mất 1 máu (%d/3)." % boss_hp)

	current_step = 4
	banner.visible = true
	banner_title.text = "⚠️ QUY TẮC: MỖI TURN CHỈ ĐƯỢC DÙNG 1 LÁ TRẢM"
	banner_desc.text = "Trong cùng một lượt, mỗi người chơi chỉ được ra TỐI ĐA 1 LÁ TRẢM (trừ khi trang bị Nỏ Thần Kim Quy)!\nBây giờ, hãy tìm hiểu kỹ năng độc quyền của tướng."
	action_btn.visible = true
	action_btn.disabled = false
	action_btn.text = "TÌM HIỂU KỸ NĂNG TƯỚNG ➜"

func _start_step_4_5_skill() -> void:
	current_step = 40
	banner_title.text = "⚡ KỸ NĂNG ĐẶC BIỆT: [TIẾN THOÁI]"
	banner_desc.text = "Tướng Lý Thường Kiệt sở hữu tuyệt kỹ TIẾN THOÁI:\nHoán chuyển tất cả lá TRẢM trên tay thành ĐỠ, và tất cả ĐỠ thành TRẢM!\nHãy click nút [⚡ TIẾN THOÁI] ở góc dưới bên trái tướng để biến đổi bài."
	action_btn.visible = false

	_show_arrow(player_avatar.global_position + Vector2(-115, 215), "BẤM TIẾN THOÁI")

func _on_player_skill_clicked() -> void:
	# Âm thanh: Voice "Tiến Thoái" + SFX Skill ngân vang
	AudioManager.play_voice("Tiến Thoái")
	AudioManager.play_skill()

	var count_tram = 0
	var count_do = 0
	for c in hand_container.get_children():
		if "Trảm" in c.card_name:
			c.setup_card_data(c.card_data.id, "Đỡ", c.card_data.get_rank_string(), c.card_data.suit, 0, "Hóa giải 1 đòn Trảm.")
			count_tram += 1
		elif "Đỡ" in c.card_name:
			c.setup_card_data(c.card_data.id, "Trảm Thường", c.card_data.get_rank_string(), c.card_data.suit, 0, "Tấn công gây 1 sát thương.")
			count_do += 1

	_add_log("✨ LÝ THƯỜNG KIỆT [TIẾN THOÁI]! Đã hoán chuyển %d Trảm ➜ Đỡ và %d Đỡ ➜ Trảm trên tay!" % [count_tram, count_do])

	if is_waiting_dodge_reaction:
		_update_dodge_reaction_ui()
	elif selected_card_ui:
		_handle_card_selected(selected_card_ui)

	if current_step == 40:
		arrow_node.visible = false
		current_step = 41
		banner_title.text = "🎉 BIẾN ĐỔI THÀNH CÔNG!"
		banner_desc.text = "Toàn bộ lá Trảm trên tay đã hóa thành ĐỠ, và ĐỠ hóa thành TRẢM!\nBạn đã dùng xong bài trong lượt. Hãy nhấn [KẾT THÚC LƯỢT]!"
		action_btn.visible = true
		action_btn.disabled = false
		action_btn.text = "KẾT THÚC LƯỢT ➜"

func _start_step_4_8_discard_lesson() -> void:
	current_step = 42

	# Đảm bảo bài trên tay nhiều hơn số máu để minh họa bài học Bỏ Bài Thừa
	var hand_count = hand_container.get_child_count()
	if hand_count <= player_hp:
		# Rút thêm 1 lá để thừa bài (5 lá trên tay > 4 Máu)
		_create_card_in_hand("Trảm Thường", "7", "Club", 0, "Tấn công gây 1 sát thương.")
		deck_count -= 1
		deck_label.text = "🎴 %d" % deck_count
		AudioManager.play_card_draw()
		hand_count = hand_container.get_child_count()

	var excess = hand_count - player_hp
	banner.visible = true
	banner_title.text = "🗑️ GIAI ĐOẠN 3: BỎ BÀI CUỐI LƯỢT (DISCARD PHASE)"
	banner_desc.text = "• QUY TẮC: Khi kết thúc lượt, số bài trên tay tối đa chỉ được BẰNG SỐ MÁU (%d Máu)!\n• Hiện tại bạn có %d lá bài (vượt quá %d lá bài thừa).\nHãy chạm chọn đúng %d lá bài thừa rồi nhấn [BỎ BÀI]!" % [player_hp, hand_count, excess, excess]
	_add_log("🗑️ Giai đoạn Bỏ Bài: Số bài trên tay (%d) > Số máu (%d). Cần bỏ %d lá bài thừa." % [hand_count, player_hp, excess])

	action_btn.visible = true
	action_btn.disabled = true
	action_btn.text = "🗑️ HÃY CHỌN LÁ ĐỂ BỎ (%d LÁ THỪA)" % excess
	card_play_btn.visible = false

	if hand_container.get_child_count() > 0:
		var first_card = hand_container.get_child(0)
		_show_arrow(first_card.global_position + Vector2(-15, 80), "CHỌN LÁ ĐỂ BỎ")

func _execute_tutorial_discard() -> void:
	if not selected_card_ui:
		return

	var c_name = selected_card_ui.card_name
	_animate_card_play_to_center(selected_card_ui)
	selected_card_ui = null
	AudioManager.play_card_select()

	var remaining = hand_container.get_child_count()
	arrow_node.visible = false
	action_btn.visible = false

	_add_log("🗑️ Đã bỏ lá [%s]. Số bài trên tay (%d/%d) đã cân bằng với số máu!" % [c_name, remaining, player_hp])
	banner_title.text = "✅ HOÀN TẤT BỎ BÀI!"
	banner_desc.text = "Số bài trên tay (%d/%d) đã cân bằng với số máu!\nĐang chuyển lượt sang Thủ Lĩnh Sơn Tặc..." % [remaining, player_hp]

	await get_tree().create_timer(1.6).timeout
	_start_step_5_boss_turn()

func _start_step_5_boss_turn() -> void:
	current_step = 5
	action_btn.visible = false
	card_play_btn.visible = false
	banner_title.text = "👺 ĐẾN LƯỢT THỦ LĨNH SƠN TẶC!"
	banner_desc.text = "Sơn Tặc tự động rút 2 lá bài và chuẩn bị ra đòn..."
	_add_log("👺 Đến lượt Thủ Lĩnh Sơn Tặc.")

	deck_count -= 2
	deck_label.text = "🎴 %d" % deck_count
	AudioManager.play_card_draw()
	await get_tree().create_timer(1.2).timeout

	AudioManager.play_voice("Trảm")
	AudioManager.play_slash()
	_show_center_card("Trảm Hung Bạo", "Thủ Lĩnh Sơn Tặc", "8", "Spade", 0, "Đòn đánh hung bạo.")
	_play_slash_effect(player_avatar.global_position + Vector2(87, 119))
	_add_log("💥 Sơn Tặc vung đao tung chiêu [TRẢM] nhắm thẳng vào bạn!")

	banner_title.text = "🛡️ CẢNH BÁO BỊ TẤN CÔNG!"
	banner_desc.text = "Sơn Tặc vừa tung đòn TRẢM! Hãy chọn lá [ĐỠ] trên tay để vô hiệu hóa đòn đánh!"

	for c in hand_container.get_children():
		if "Đỡ" in c.card_name:
			_show_arrow(c.global_position + Vector2(-15, 80), "CHỌN ĐỠ")
			break

func _execute_dodge() -> void:
	arrow_node.visible = false
	card_play_btn.visible = false

	# Âm thanh: Voice "Đỡ" + Tiếng kim loại ngân vang đỡ đòn
	AudioManager.play_voice("Đỡ")
	AudioManager.play_parry()

	if selected_card_ui:
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null

	_show_center_card("Đỡ", "Lý Thường Kiệt", "3", "Diamond", 0, "Hóa giải 1 đòn Trảm.")
	_add_log("🛡️ HOÁ GIẢI THÀNH CÔNG! Bạn đã dùng Đỡ né hoàn toàn đòn Trảm của Sơn Tặc! Sinh mệnh 4/4 của bạn được bảo toàn.")

	await get_tree().create_timer(1.2).timeout
	_show_free_battle_unlocked_banner()

func _show_free_battle_unlocked_banner() -> void:
	current_step = 6
	banner.visible = true
	banner_title.text = "🎉 CHÚC MỪNG! BẠN ĐÃ NẮM TRỌN QUY TẮC!"
	banner_desc.text = "• Đầu lượt: Tự động rút 2 lá bài từ kho bài.\n• Tấn công: Mỗi lượt dùng tối đa 1 lá Trảm.\n• Phòng thủ: Dùng Đỡ né đòn, Bánh Chưng hồi phục Máu!\nHãy tự do chiến đấu để tiêu diệt Thủ Lĩnh Sơn Tặc!"
	action_btn.visible = true
	action_btn.disabled = false
	action_btn.text = "BẮT ĐẦU THỰC CHIẾN ⚔️"

func _start_free_battle_mode() -> void:
	is_free_battle = true
	banner.visible = false
	end_turn_btn.visible = true
	_add_log("══════════════════════════════════")
	_add_log("⚔️ MỞ KHÓA THỰC CHIẾN TỰ DO! HÃY HẠ GỤC SƠN TẶC!")
	_add_log("══════════════════════════════════")
	_player_turn_start_free_play()

func _player_turn_start_free_play() -> void:
	is_player_turn = true
	is_in_free_discard_phase = false
	slashes_used_this_turn = 0
	card_play_btn.visible = false
	end_turn_btn.disabled = false
	end_turn_btn.text = "KẾT THÚC LƯỢT ➜"
	desc_text.text = "💡 Lượt của bạn! Chọn lá bài trên tay để sử dụng hoặc nhấn Kết thúc lượt."
	_add_log("=== LƯỢT MỚI CỦA BẠN ===")

	# Rút 2 lá đầu lượt
	deck_count -= 2
	deck_label.text = "🎴 %d" % max(0, deck_count)
	AudioManager.play_card_draw()

	var new_cards = [
		{"name": "Trảm Thường", "rank": "7", "suit": "Spade", "cat": 0, "desc": "Tấn công gây 1 sát thương."},
		{"name": "Bánh Chưng", "rank": "8", "suit": "Heart", "cat": 0, "desc": "Hồi phục 1 Máu."}
	]
	for data in new_cards:
		_create_card_in_hand(data["name"], data["rank"], data["suit"], data["cat"], data["desc"])

	_add_log("🎴 Bạn đã rút 2 lá bài vào tay.")

func _execute_free_card_play() -> void:
	if not selected_card_ui:
		return

	var c_name = selected_card_ui.card_name
	card_play_btn.visible = false

	if "Trảm" in c_name:
		slashes_used_this_turn += 1
		AudioManager.play_voice("Trảm")
		AudioManager.play_slash()
		AudioManager.play_damage()

		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null

		_play_slash_effect(boss_avatar.global_position + Vector2(87, 119))
		boss_avatar.play_damage_effect()
		boss_avatar.spawn_damage_number(1)

		boss_hp -= 1
		boss_avatar.update_hp(boss_hp, 3)
		_show_center_card(c_name, "Lý Thường Kiệt")
		_add_log("⚔️ Bạn ra đòn [TRẢM]! Sơn Tặc mất 1 Máu (Còn %d/3)." % boss_hp)

		if boss_hp <= 0:
			await get_tree().create_timer(1.0).timeout
			_on_boss_defeated()
			return

	elif "Bánh Chưng" in c_name:
		if player_hp >= 4:
			desc_text.text = "⚠️ Máu của bạn đã đầy (4/4 đóa sen), không thể sử dụng Bánh Chưng!"
			_add_log("💮 Máu của bạn đã đầy (4/4), không thể sử dụng thêm Bánh Chưng!")
			return

		AudioManager.play_voice("Bánh Chưng")
		AudioManager.play_sfx("sfx_skill")
		_show_center_card("Bánh Chưng", "Lý Thường Kiệt", "4", "Heart", 0, "Hồi phục 1 Máu.")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null

		player_hp = min(4, player_hp + 1)
		player_avatar.update_hp(player_hp, 4)
		_add_log("❤️ Bạn đã dùng BÁNH CHƯNG! Hồi phục 1 Máu (%d/4)." % player_hp)

	elif "Khiên" in c_name or "Giáp" in c_name or "Áo Bào" in c_name:
		var eq_sr = "%s%s" % [selected_card_ui.card_data.get_suit_symbol(), selected_card_ui.card_data.get_rank_string()] if selected_card_ui and selected_card_ui.card_data else ""
		AudioManager.play_voice("Khiên Mây Bện")
		AudioManager.play_parry()
		_show_center_card(c_name, "Lý Thường Kiệt", "K", "Diamond", 1, "Phán xét Đỏ tự động Đỡ.")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		player_avatar.set_equipment("armor", c_name, eq_sr)
		_add_log("🛡️ Bạn đã trang bị [%s] vào ô [GIÁP PHÒNG THỦ]!" % c_name)

	elif "Kiếm" in c_name or "Đao" in c_name or "Cung" in c_name or "Nỏ" in c_name:
		var eq_sr = "%s%s" % [selected_card_ui.card_data.get_suit_symbol(), selected_card_ui.card_data.get_rank_string()] if selected_card_ui and selected_card_ui.card_data else ""
		AudioManager.play_parry()
		_show_center_card(c_name, "Lý Thường Kiệt", "A", "Diamond", 1, "Vũ khí trang bị.")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		player_avatar.set_equipment("weapon", c_name, eq_sr)
		_add_log("🗡️ Bạn đã trang bị [%s] vào ô [VŨ KHÍ]!" % c_name)

	elif "Voi" in c_name or "Tuyệt Ảnh" in c_name or "+1" in c_name:
		var eq_sr = "%s%s" % [selected_card_ui.card_data.get_suit_symbol(), selected_card_ui.card_data.get_rank_string()] if selected_card_ui and selected_card_ui.card_data else ""
		_show_center_card(c_name, "Lý Thường Kiệt", "K", "Heart", 1, "Ngựa phòng thủ (+1).")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		player_avatar.set_equipment("defensive_mount", c_name, eq_sr)
		_add_log("🐘🛡️ Bạn đã trang bị [%s] vào ô [NGỰA THỦ (+1)]!" % c_name)

	elif "Ngựa" in c_name or "Xích Thố" in c_name or "-1" in c_name:
		var eq_sr = "%s%s" % [selected_card_ui.card_data.get_suit_symbol(), selected_card_ui.card_data.get_rank_string()] if selected_card_ui and selected_card_ui.card_data else ""
		_show_center_card(c_name, "Lý Thường Kiệt", "5", "Spade", 1, "Ngựa tấn công (-1).")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		player_avatar.set_equipment("offensive_mount", c_name, eq_sr)
		_add_log("🐎⚔️ Bạn đã trang bị [%s] vào ô [NGỰA CÔNG (-1)]!" % c_name)

	elif "Bảo Vật" in c_name or "Ngọc" in c_name:
		var eq_sr = "%s%s" % [selected_card_ui.card_data.get_suit_symbol(), selected_card_ui.card_data.get_rank_string()] if selected_card_ui and selected_card_ui.card_data else ""
		_show_center_card(c_name, "Lý Thường Kiệt", "Q", "Heart", 1, "Bảo vật hoàng gia.")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		player_avatar.set_equipment("treasure", c_name, eq_sr)
		_add_log("👑 Bạn đã trang bị [%s] vào ô [BẢO VẬT]!" % c_name)

	else:
		_show_center_card(c_name, "Lý Thường Kiệt")
		_animate_card_play_to_center(selected_card_ui)
		selected_card_ui = null
		_add_log("🃏 Bạn đã ra lá [%s]!" % c_name)

	desc_text.text = "💡 Chọn lá bài khác trên tay hoặc nhấn Kết thúc lượt."

func _update_free_discard_ui() -> void:
	var excess = hand_container.get_child_count() - player_hp
	if excess <= 0:
		is_in_free_discard_phase = false
		card_play_btn.visible = false
		desc_text.text = "✅ Số bài trên tay đã cân bằng với số máu! Nhấn [KẾT THÚC LƯỢT] để kết thúc lượt."
		return

	card_play_btn.visible = true
	if selected_card_ui:
		card_play_btn.disabled = false
		card_play_btn.text = "🗑️ BỎ LÁ [%s]" % selected_card_ui.card_name.to_upper()
		desc_text.text = "🗑️ Đã chọn [%s]. Nhấn [BỎ BÀI] để loại bỏ (Cần bỏ %d lá thừa)." % [selected_card_ui.card_name, excess]
	else:
		card_play_btn.disabled = true
		card_play_btn.text = "🗑️ CHỌN LÁ ĐỂ BỎ (%d THỪA)" % excess
		desc_text.text = "⚠️ Hãy chọn lá bài thừa trên tay để bỏ (Còn %d lá thừa)..." % excess

func _execute_free_play_discard() -> void:
	if not selected_card_ui:
		return

	var c_name = selected_card_ui.card_name
	_animate_card_play_to_center(selected_card_ui)
	selected_card_ui = null
	AudioManager.play_card_select()

	var remaining = hand_container.get_child_count()
	var excess = remaining - player_hp
	if excess > 0:
		_add_log("🗑️ Đã bỏ lá [%s]. Vẫn còn thừa %d lá bài (%d/%d)." % [c_name, excess, remaining, player_hp])
		_update_free_discard_ui()
	else:
		is_in_free_discard_phase = false
		card_play_btn.visible = false
		_add_log("✅ Đã bỏ xong bài thừa (%d/%d). Bạn có thể bấm [KẾT THÚC LƯỢT]!" % [remaining, player_hp])
		desc_text.text = "✅ Số bài trên tay đã cân bằng với số máu! Nhấn [KẾT THÚC LƯỢT] để kết thúc lượt."

func _on_end_turn_btn_clicked() -> void:
	end_turn_btn.release_focus()
	if is_waiting_dodge_reaction:
		is_waiting_dodge_reaction = false
		card_play_btn.visible = false
		end_turn_btn.text = "KẾT THÚC LƯỢT ➜"
		_player_take_boss_damage()
		return

	if not is_player_turn:
		return

	# Kiểm tra quy tắc Bỏ Bài Cuối Lượt: Số bài trên tay tối đa bằng số máu hiện tại
	var current_cards = hand_container.get_child_count()
	if current_cards > player_hp:
		var excess = current_cards - player_hp
		is_in_free_discard_phase = true
		_add_log("⚠️ GIAI ĐOẠN BỎ BÀI: Số bài trên tay (%d) > Số máu (%d). Cần bỏ %d lá bài thừa!" % [current_cards, player_hp, excess])
		_update_free_discard_ui()
		return

	is_in_free_discard_phase = false
	is_player_turn = false
	end_turn_btn.disabled = true
	card_play_btn.visible = false
	_add_log("⌛ Bạn đã kết thúc lượt.")
	_boss_turn_free_play()

func _boss_turn_free_play() -> void:
	_add_log("👺 Đến lượt Thủ Lĩnh Sơn Tặc...")
	desc_text.text = "👺 Thủ Lĩnh Sơn Tặc đang suy tính hành động..."

	deck_count -= 2
	deck_label.text = "🎴 %d" % max(0, deck_count)
	AudioManager.play_card_draw()

	await get_tree().create_timer(1.2).timeout

	if boss_hp > 0:
		# Sơn Tặc tấn công
		AudioManager.play_voice("Trảm")
		AudioManager.play_slash()
		_show_center_card("Trảm Hung Hãn", "Thủ Lĩnh Sơn Tặc", "7", "Club", 0, "Tấn công gây 1 sát thương.")
		_play_slash_effect(player_avatar.global_position + Vector2(87, 119))
		_add_log("💥 Sơn Tặc vung đao tung chiêu [TRẢM] nhắm thẳng vào bạn!")

		_prompt_player_dodge_reaction()

func _prompt_player_dodge_reaction() -> void:
	is_waiting_dodge_reaction = true
	_update_dodge_reaction_ui()

func _update_dodge_reaction_ui() -> void:
	if not is_waiting_dodge_reaction:
		return

	var has_dodge = false
	var dodge_count = 0
	for c in hand_container.get_children():
		if "Đỡ" in c.card_name:
			has_dodge = true
			dodge_count += 1

	var has_slash = false
	for c in hand_container.get_children():
		if "Trảm" in c.card_name:
			has_slash = true
			break

	card_play_btn.visible = true
	end_turn_btn.visible = true
	end_turn_btn.disabled = false
	end_turn_btn.text = "💔 CHỊU ĐÒN (-1)"

	if has_dodge:
		card_play_btn.disabled = false
		card_play_btn.text = "🛡️ DÙNG ĐỠ (NÉ ĐÒN)"
		desc_text.text = "⚠️ SƠN TẶC VỪA TẤN CÔNG BẠN! Bạn có %d lá [ĐỠ]. Hãy bấm [🛡️ DÙNG ĐỠ (NÉ ĐÒN)] hoặc [💔 CHỊU ĐÒN (-1)]!" % dodge_count
	else:
		card_play_btn.disabled = true
		card_play_btn.text = "🛡️ CHƯA CÓ ĐỠ"
		if has_slash:
			desc_text.text = "⚠️ Bạn chưa có [ĐỠ], nhưng có thể bấm [⚡ TIẾN THOÁI] đổi Trảm ➜ Đỡ, hoặc bấm [💔 CHỊU ĐÒN (-1)]!"
		else:
			desc_text.text = "⚠️ Trên tay không có lá [ĐỠ]! Bạn hãy bấm nút [💔 CHỊU ĐÒN (-1)] để tiếp tục trận đấu."

func _execute_free_play_dodge() -> void:
	is_waiting_dodge_reaction = false
	card_play_btn.visible = false
	end_turn_btn.text = "KẾT THÚC LƯỢT ➜"

	# Tiêu hao 1 lá Đỡ trên tay:
	var target_dodge: Control = null
	if selected_card_ui and "Đỡ" in selected_card_ui.card_name:
		target_dodge = selected_card_ui
	else:
		for c in hand_container.get_children():
			if "Đỡ" in c.card_name:
				target_dodge = c
				break

	if target_dodge:
		var c_rank = target_dodge.card_data.get_rank_string() if target_dodge.card_data else "3"
		var c_suit = target_dodge.card_data.suit if target_dodge.card_data else "Diamond"
		_animate_card_play_to_center(target_dodge)
		selected_card_ui = null
		_show_center_card("Đỡ", "Lý Thường Kiệt", c_rank, c_suit, 0, "Hóa giải 1 đòn Trảm.")

	AudioManager.play_voice("Đỡ")
	AudioManager.play_parry()
	_add_log("🛡️ BẠN ĐÃ TỰ DÙNG [ĐỠ]! Hóa giải hoàn toàn đòn Trảm của Sơn Tặc, bảo toàn sinh mệnh!")

	await get_tree().create_timer(1.2).timeout
	_player_turn_start_free_play()

func _player_take_boss_damage() -> void:
	player_hp = max(1, player_hp - 1)
	player_avatar.play_damage_effect()
	player_avatar.spawn_damage_number(1)
	player_avatar.update_hp(player_hp, 4)
	_add_log("💥 Bạn trúng đòn Trảm của Sơn Tặc! Mất 1 Máu (Còn %d/4)." % player_hp)

	await get_tree().create_timer(1.2).timeout
	_player_turn_start_free_play()

func _on_boss_defeated() -> void:
	is_free_battle = false
	end_turn_btn.visible = false
	card_play_btn.visible = false
	arrow_node.visible = false

	# Âm thanh chiến thắng hào hùng
	AudioManager.play_victory()

	# Hiệu ứng tiêu diệt Boss
	boss_avatar.play_damage_effect()
	var tw = create_tween()
	tw.tween_property(boss_avatar, "modulate:a", 0.3, 0.8)

	_add_log("👑 THỦ LĨNH SƠN TẶC ĐÃ BỊ TIÊU DIỆT HOÀN TOÀN!")
	_add_log("🏆 BẠN ĐÃ CHIẾN THẮNG TRẬN ĐẤU TẬP HUẤN!")

	await get_tree().create_timer(1.0).timeout
	_show_reward_modal()

func _show_reward_modal() -> void:
	reward_modal.visible = true
	banner.visible = false
	var box = reward_modal.get_node("Dim/Box")
	var tw = create_tween()
	tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.25).from(Vector2(0.7, 0.7)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _get_equipment_description(item_name: String) -> String:
	var name_lower = item_name.to_lower()
	if "thuận thiên" in name_lower or "thuan thien" in name_lower:
		return "Tầm 2. Thanh bảo kiếm hộ quốc của Bình Định Vương, công thủ toàn diện."
	elif "song cung" in name_lower or "mường nhạ" in name_lower:
		return "Tầm 2. Khi Trảm bị Đỡ, có thể bỏ 2 bài trên tay ép mục tiêu chịu 1 sát thương."
	elif "nỏ thần" in name_lower or "kim quy" in name_lower:
		return "Tầm 3. Không giới hạn số lá Trảm được đánh ra trong cùng một lượt."
	elif "trường đao" in name_lower or "nam sơn" in name_lower:
		return "Tầm 3. Khi Trảm bị Đỡ, có thể bỏ thêm 1 lá Trảm ép đối phương Đỡ lần nữa."
	elif "đại đao" in name_lower:
		return "Tầm 2. Vũ khí hung hãn của thảo khấu sơn lâm, tăng sát thương công phá."
	elif "giáp đồng" in name_lower or "sơn vi" in name_lower:
		return "Vô hiệu hóa toàn bộ mọi đòn Trảm Thường không có thuộc tính."
	elif "khiên mây" in name_lower:
		return "Khi cần Đỡ, lật phán xét chất Đỏ (Cơ/Rô) tự động tính là Đỡ thành công."
	elif "áo bào" in name_lower:
		return "Tất cả sát thương nhận vào giảm 1 (tối đa 3 lần)."
	elif "voi chiến" in name_lower:
		return "Tăng +1 khoảng cách phòng thủ từ tất cả người khác nhắm tới bạn."
	elif "ngựa trắng" in name_lower or "thuần nông" in name_lower:
		return "Giảm -1 khoảng cách tấn công từ bạn tới tất cả người khác."
	elif "bảo vật" in name_lower or "quốc gia" in name_lower or "hoàng gia" in name_lower:
		return "Bảo vật gia truyền ban phúc lành hộ mệnh, gia tăng phòng hộ và sĩ khí."
	elif item_name.strip_edges() == "":
		return "Chưa trang bị"
	else:
		return "Trang bị đặc biệt kích hoạt hiệu ứng bảo hộ trong trận đấu."

func _format_equipment_info(slot_icon: String, slot_name: String, equip_str: String, default_color: String) -> String:
	var clean_str = equip_str.strip_edges()
	if clean_str == "" or clean_str == "(Chưa trang bị)":
		return "[b][color=#7A8B9E]• %s %s:[/color][/b] [color=#607185](Chưa trang bị)[/color]" % [slot_icon, slot_name]

	var parts = clean_str.split(" ", false, 1)
	var suit_rank_part = ""
	var item_name_part = clean_str

	if parts.size() >= 2 and (parts[0].begins_with("♠") or parts[0].begins_with("♥") or parts[0].begins_with("♦") or parts[0].begins_with("♣")):
		suit_rank_part = parts[0]
		item_name_part = parts[1]

	var name_formatted = ""
	if suit_rank_part != "":
		var is_red = ("♥" in suit_rank_part or "♦" in suit_rank_part)
		var color_hex = "#FF4D4D" if is_red else "#E2E8F0"
		name_formatted = "[color=%s][b]%s[/b][/color] [color=%s][b]%s[/b][/color]" % [color_hex, suit_rank_part, default_color, item_name_part]
	else:
		name_formatted = "[color=%s][b]%s[/b][/color]" % [default_color, item_name_part]

	var desc = _get_equipment_description(item_name_part)
	return "[b][color=%s]• %s %s:[/color][/b] %s\n  [color=#8EB6DB]↳ %s[/color]" % [default_color, slot_icon, slot_name, name_formatted, desc]

func _show_general_info_modal(target: String) -> void:
	if target == "player":
		info_modal_title.text = "🎖️ THÔNG TIN TƯỚNG: LÝ THƯỜNG KIỆT"
		info_portrait_thumb.texture = player_avatar.portrait_rect.texture
		info_hero_name.text = "Lý Thường Kiệt (BẠN)"
		info_hero_stats.text = "Máu: 🌸 %d/4 | Bài: 🎴 %d" % [player_hp, hand_container.get_child_count()]
		info_skill_title.text = "⚡ TUYỆT KỸ: [TIẾN THOÁI] (Chủ Động)"
		info_skill_desc.text = "Hoán chuyển toàn bộ lá Trảm trên tay thành Đỡ, và toàn bộ lá Đỡ thành Trảm! Giúp danh tướng linh hoạt chuyển đổi giữa công và thủ trong trận chiến."

		var w = player_avatar.equipped_items.get("weapon", "")
		var a = player_avatar.equipped_items.get("armor", "")
		var dm = player_avatar.equipped_items.get("defensive_mount", "")
		var om = player_avatar.equipped_items.get("offensive_mount", "")
		var tr = player_avatar.equipped_items.get("treasure", "")

		info_eq_weapon.text = _format_equipment_info("🗡️", "Vũ Khí", w, "#FFD700")
		info_eq_armor.text = _format_equipment_info("🛡️", "Giáp Phòng Thủ", a, "#65D8FF")
		info_eq_def_mount.text = _format_equipment_info("🐘", "Ngựa Thủ (+1)", dm, "#65F5AF")
		info_eq_off_mount.text = _format_equipment_info("🐎", "Ngựa Công (-1)", om, "#FFA585")
		info_eq_treasure.text = _format_equipment_info("👑", "Bảo Vật", tr, "#E0B5FF")

	else:
		info_modal_title.text = "👺 THÔNG TIN ĐỐI THỦ: THỦ LĨNH SƠN TẶC"
		info_portrait_thumb.texture = boss_avatar.portrait_rect.texture
		info_hero_name.text = "Thủ Lĩnh Sơn Tặc (ĐỐI THỦ)"
		info_hero_stats.text = "Máu: 🌸 %d/3 | Bài: 🎴 4" % boss_hp
		info_skill_title.text = "🗡️ TUYỆT KỸ: [CƯỚP BÓC] (Bị Động)"
		info_skill_desc.text = "Đầu mỗi lượt, thủ lĩnh sơn tặc tự động rút thêm 2 lá bài từ kho bài và vung đại đao tung chiêu Trảm hung bạo nhắm vào đối thủ."

		var w = boss_avatar.equipped_items.get("weapon", "♦8 Đại Đao Sơn Tặc")
		var a = boss_avatar.equipped_items.get("armor", "")
		var dm = boss_avatar.equipped_items.get("defensive_mount", "")
		var om = boss_avatar.equipped_items.get("offensive_mount", "")
		var tr = boss_avatar.equipped_items.get("treasure", "")

		info_eq_weapon.text = _format_equipment_info("🗡️", "Vũ Khí", w, "#FFD700")
		info_eq_armor.text = _format_equipment_info("🛡️", "Giáp Phòng Thủ", a, "#65D8FF")
		info_eq_def_mount.text = _format_equipment_info("🐘", "Ngựa Thủ (+1)", dm, "#65F5AF")
		info_eq_off_mount.text = _format_equipment_info("🐎", "Ngựa Công (-1)", om, "#FFA585")
		info_eq_treasure.text = _format_equipment_info("👑", "Bảo Vật", tr, "#E0B5FF")

	general_info_modal.visible = true
	var box = general_info_modal.get_node("Dim/Box")
	var tw = create_tween()
	tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.2).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _hide_general_info_modal() -> void:
	AudioManager.play_card_select()
	general_info_modal.visible = false

func _show_arrow(pos: Vector2, text: String) -> void:
	arrow_target_pos = pos
	arrow_label.text = text
	arrow_node.position = pos
	arrow_node.visible = true
	arrow_time = 0.0

func _show_center_card(c_name: String, source: String, c_rank: String = "A", c_suit: String = "Spade", c_cat: int = 0, c_desc: String = "") -> void:
	if showcase_tween and showcase_tween.is_valid():
		showcase_tween.kill()

	# 1. Dọn dẹp lá bài cũ trong slot
	for child in showcase_card_slot.get_children():
		child.queue_free()

	# 2. Khởi tạo lá bài với kích thước chuẩn 1:1 (118x168) tại trung tâm bàn đấu
	var card_instance = CardUIScene.instantiate()
	showcase_card_slot.add_child(card_instance)
	card_instance.setup_card_data("center_" + c_name, c_name, c_rank, c_suit, c_cat, c_desc)
	if card_instance.click_button:
		card_instance.click_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3. Đặt nội dung biển hiệu
	showcase_label.text = "%s dùng [%s]!" % [source, c_name]
	center_showcase.visible = true
	center_showcase.modulate.a = 1.0

	# 4. Giữ nguyên kích thước gốc (Vector2(1.0, 1.0)), không phóng to hay viền bao quanh
	center_showcase.scale = Vector2(1.0, 1.0)
	showcase_tween = create_tween()
	showcase_tween.tween_interval(1.8)
	showcase_tween.tween_property(center_showcase, "modulate:a", 0.0, 0.3)
	showcase_tween.tween_callback(func(): center_showcase.visible = false)

func _animate_card_play_to_center(card_node: Control) -> void:
	if is_instance_valid(card_node):
		card_node.queue_free()

func _play_slash_effect(target_center: Vector2) -> void:
	var slash_line = Line2D.new()
	slash_line.width = 16.0
	slash_line.default_color = Color(1.8, 1.6, 0.7, 1.0)
	slash_line.points = PackedVector2Array([
		target_center + Vector2(-95, -110),
		target_center + Vector2(95, 110)
	])
	slash_line.z_index = 60
	add_child(slash_line)

	var tw = create_tween()
	tw.tween_property(slash_line, "width", 26.0, 0.06)
	tw.parallel().tween_property(slash_line, "default_color", Color(2.5, 0.5, 0.4, 0.95), 0.1)
	tw.chain().tween_property(slash_line, "width", 0.0, 0.1)
	tw.chain().tween_callback(slash_line.queue_free)

func _on_claim_reward_clicked() -> void:
	claim_reward_btn.release_focus()
	AuthManager.set_onboarding_done()
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")
