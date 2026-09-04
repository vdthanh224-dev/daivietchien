extends Control

const CardUIScene = preload("res://scenes/components/card_ui.tscn")

# UI Node References
@onready var table_top: Control = $TableTop
@onready var seat_bottom_right = $TableTop/Seats/SeatBottomRight/PlayerAvatar
@onready var seat_top_right = $TableTop/Seats/SeatTopRight/Enemy1Avatar
@onready var seat_top_left = $TableTop/Seats/SeatTopLeft/AllyAvatar
@onready var seat_mid_left = $TableTop/Seats/SeatMidLeft/Enemy2Avatar

@onready var hand_container: HBoxContainer = $TableTop/HandCards
@onready var deck_label: Label = $TableTop/DeckHUD/DeckPlaque/DeckLabel
@onready var log_text: RichTextLabel = $TableTop/LogPanel/Margin/VBox/Scroll/LogText
@onready var desc_text: Label = $TableTop/CardDescBar/Margin/DescText
@onready var card_play_btn: Button = $TableTop/CardPlayBtn
@onready var end_turn_btn: Button = $TableTop/EndTurnBtn
@onready var turn_indicator: Label = $TableTop/TurnInfoBar/TurnLabel

@onready var center_showcase: Control = $CenterArea/CardShowcase
@onready var showcase_card_slot: Control = $CenterArea/CardShowcase/CardSlot
@onready var showcase_label: Label = $CenterArea/CardShowcase/ActionBanner/ShowcaseName

@onready var bg_rect: TextureRect = $Background
@onready var embers_layer: Control = $EmbersLayer

@onready var dodge_modal: Control = $DodgeModal
@onready var dodge_title_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/Title
@onready var dodge_desc_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/Desc
@onready var dodge_timer_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/TimerLbl
@onready var dodge_confirm_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/DodgeBtn
@onready var dodge_pass_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/PassBtn
@onready var dodge_card_selector_hbox: HBoxContainer = $DodgeModal/Dim/Box/Margin/VBox/CardSelectorScroll/CardSelectorHBox
@onready var dodge_selected_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/SelectedCardStatus

@onready var rescue_modal: Control = $RescueModal
@onready var rescue_desc_lbl: Label = $RescueModal/Dim/Box/Margin/VBox/Desc
@onready var rescue_timer_lbl: Label = $RescueModal/Dim/Box/Margin/VBox/TimerLbl
@onready var rescue_confirm_btn: Button = $RescueModal/Dim/Box/Margin/VBox/HBox/RescueBtn
@onready var rescue_pass_btn: Button = $RescueModal/Dim/Box/Margin/VBox/HBox/PassBtn

@onready var general_info_modal: Control = $GeneralInfoModal
@onready var info_title: Label = $GeneralInfoModal/Dim/Box/Margin/VBox/HeaderHBox/ModalTitle
@onready var info_hero_name: Label = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/LeftCol/HeroName
@onready var info_hero_stats: Label = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/LeftCol/HeroStats
@onready var info_skill_title: Label = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/SkillBox/Margin/VBox/SkillTitle
@onready var info_skill_desc: Label = $GeneralInfoModal/Dim/Box/Margin/VBox/ContentHBox/RightCol/SkillBox/Margin/VBox/SkillDesc
@onready var info_close_x_btn: Button = $GeneralInfoModal/Dim/Box/Margin/VBox/HeaderHBox/CloseXBtn
@onready var info_close_btn: Button = $GeneralInfoModal/Dim/Box/Margin/VBox/CloseModalBtn

@onready var victory_defeat_modal: Control = $VictoryDefeatModal
@onready var victory_title: Label = $VictoryDefeatModal/Dim/Box/Margin/VBox/Title
@onready var victory_desc: Label = $VictoryDefeatModal/Dim/Box/Margin/VBox/Desc
@onready var victory_return_btn: Button = $VictoryDefeatModal/Dim/Box/Margin/VBox/ReturnBtn

# Iron Chain Modal (Xích Tâm Tỏa đa mục tiêu)
@onready var iron_chain_modal: Control = $IronChainModal
@onready var iron_chain_grid: HBoxContainer = $IronChainModal/Dim/Box/Margin/VBox/GeneralsGrid
@onready var iron_chain_status_lbl: Label = $IronChainModal/Dim/Box/Margin/VBox/StatusLbl
@onready var iron_chain_confirm_btn: Button = $IronChainModal/Dim/Box/Margin/VBox/HBox/ConfirmBtn
@onready var iron_chain_cancel_btn: Button = $IronChainModal/Dim/Box/Margin/VBox/HBox/CancelBtn

# Card Pick Modal (Cướp / Phá Hủy bài mục tiêu)
@onready var card_pick_modal: Control = $CardPickModal
@onready var card_pick_title: Label = $CardPickModal/Dim/Box/Margin/VBox/Title
@onready var card_pick_desc: Label = $CardPickModal/Dim/Box/Margin/VBox/Desc
@onready var card_pick_options_hbox: HBoxContainer = $CardPickModal/Dim/Box/Margin/VBox/Scroll/OptionsHBox
@onready var card_pick_status_lbl: Label = $CardPickModal/Dim/Box/Margin/VBox/SelectedStatusLbl
@onready var card_pick_confirm_btn: Button = $CardPickModal/Dim/Box/Margin/VBox/HBox/ConfirmBtn
@onready var card_pick_cancel_btn: Button = $CardPickModal/Dim/Box/Margin/VBox/HBox/CancelBtn

# Battle State
var my_seat: int = 1
var my_team_is_dragon: bool = true
var current_turn_seat: int = 1
var current_turn_timer: float = 40.0
var is_player_turn: bool = false
var slashes_used_this_turn: int = 0
var is_wine_buff_active: bool = false
var deck_count: int = 80
var selected_card_ui: Control = null
var selected_target_seat: int = -1
var is_game_over: bool = false

# Multi-target Chain State
var selected_chain_seats: Array = []

# Card Pick (Steal / Destroy) State
var card_pick_is_steal: bool = false
var card_pick_target_seat: int = -1
var selected_card_pick_option: Dictionary = {}

# Remote Player State (Real Human Player on other machine)
var is_remote_turn_active: bool = false
var remote_turn_timer: float = 40.0
var remote_poll_timer: float = 0.0

# Waiting for Dodge reaction
signal custom_reaction_finished(accepted: bool)
var custom_reaction_callback: Callable = Callable()
var last_custom_reaction_card_info: Dictionary = {}
var is_waiting_dodge: bool = false
var dodge_attacker_seat: int = -1
var dodge_time_left: float = 15.0
var incoming_slash_damage: int = 1
var incoming_slash_element: String = "NORMAL"
var selected_dodge_card_ui: Control = null

# Waiting for Rescue (Bánh Chưng / Hủ Rượu)
var is_waiting_rescue: bool = false
var rescue_victim_seat: int = -1
var rescue_time_left: float = 10.0
var rescue_card_to_use: Control = null

# Discard Phase State (Bỏ bài thừa)
var is_discard_phase: bool = false
var cards_to_discard_count: int = 0

# Dynamic Background & Embers
var ember_particles: Array = []
var bg_anim_timer: float = 0.0

# General Info Table (Key: seatNumber 1..4)
var generals_data: Dictionary = {}

# 52-card standard deck pile
var card_deck_pile: Array = []

func _ready() -> void:
	randomize()
	AudioManager.play_bgm("bgm_battle")

	# Connect buttons
	card_play_btn.pressed.connect(_on_card_play_btn_clicked)
	end_turn_btn.pressed.connect(_on_end_turn_btn_clicked)
	dodge_confirm_btn.pressed.connect(_on_dodge_confirmed)
	dodge_pass_btn.pressed.connect(_on_dodge_passed)
	rescue_confirm_btn.pressed.connect(_on_rescue_confirmed)
	rescue_pass_btn.pressed.connect(_on_rescue_passed)
	info_close_x_btn.pressed.connect(_hide_general_info_modal)
	info_close_btn.pressed.connect(_hide_general_info_modal)
	victory_return_btn.pressed.connect(_on_return_home_clicked)
	iron_chain_confirm_btn.pressed.connect(_on_iron_chain_confirmed)
	iron_chain_cancel_btn.pressed.connect(_hide_iron_chain_modal)
	card_pick_confirm_btn.pressed.connect(_on_card_pick_confirmed)
	card_pick_cancel_btn.pressed.connect(_hide_card_pick_modal)

	dodge_modal.visible = false
	rescue_modal.visible = false
	general_info_modal.visible = false
	victory_defeat_modal.visible = false
	iron_chain_modal.visible = false
	card_pick_modal.visible = false
	center_showcase.visible = false
	card_play_btn.visible = false
	end_turn_btn.visible = false

	_start_ambient_effects()
	_init_deck()
	_init_generals_from_draft()
	_deal_initial_hands()

	# Kết nối WebSocket Realtime Local Server
	if NetworkClient:
		if not NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.connect(_on_network_action_received)
		if not NetworkClient.connection_established.is_connected(_on_network_connected):
			NetworkClient.connection_established.connect(_on_network_connected)
		if not NetworkClient.player_joined.is_connected(_on_network_player_joined):
			NetworkClient.player_joined.connect(_on_network_player_joined)
		if not NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.connect(_on_network_game_state_updated)
		if not NetworkClient.error_received.is_connected(_on_network_error_received):
			NetworkClient.error_received.connect(_on_network_error_received)
		if NetworkClient.is_connected_to_server:
			_on_network_connected()

	_add_log("⚔️ Đấu Trường Đại Việt 2v2: Phe Rồng ([1], [3]) vs Phe Phượng ([2], [4])!")
	_add_log("📜 Thứ tự ra bài: Ghế 1 ➔ Ghế 2 ➔ Ghế 3 ➔ Ghế 4.")

	# Bắt đầu trận chiến tại Ghế 1 (Lượt 1 - Phe Rồng)
	_start_turn(1)

	# Handle headless screenshot test
	var cmd_args = OS.get_cmdline_user_args()
	if cmd_args.is_empty():
		cmd_args = OS.get_cmdline_args()
	if "--screenshot-battle-2v2" in cmd_args:
		# Equip items and lightning badge to verify font size x1.4 and UI layout
		if generals_data.has(1):
			var p1 = generals_data[1]
			p1["equipped_weapon"] = "Nỏ Thần Kim Quy"
			p1["avatar_node"].set_equipment("weapon", "Nỏ Thần Kim Quy", "")
			p1["equipped_armor"] = "Khiên Mây Bện"
			p1["avatar_node"].set_equipment("armor", "Khiên Mây Bện", "")
			p1["has_lightning"] = true
			p1["avatar_node"].set_delayed_trick("lightning", true)
		if generals_data.has(2):
			var p2 = generals_data[2]
			p2["equipped_weapon"] = "Kiếm Thuận Thiên"
			p2["avatar_node"].set_equipment("weapon", "Kiếm Thuận Thiên", "")
			p2["equipped_def_horse"] = "Voi Chiến Đại Việt"
			p2["avatar_node"].set_equipment("def_horse", "Voi Chiến Đại Việt", "")

		await get_tree().create_timer(1.5).timeout
		var tex = get_viewport().get_texture()
		if tex:
			var img = tex.get_image()
			if img:
				img.save_png("res://battle_2v2_screenshot.png")
				print("[Screenshot] Đã lưu battle_2v2_screenshot.png!")
		get_tree().quit()

	if "--screenshot-dodge-modal" in cmd_args:
		# Add 2 Dodge cards with different suits/ranks to test selection
		_add_card_to_player_hand({"id": "D80_DO_D2", "name": "Đỡ", "rank": 2, "suit": "Diamond", "cat": 0, "desc": "Hóa giải hoàn toàn 1 đòn Trảm"})
		_add_card_to_player_hand({"id": "D80_DO_H7", "name": "Đỡ", "rank": 7, "suit": "Heart", "cat": 0, "desc": "Hóa giải hoàn toàn 1 đòn Trảm"})
		await get_tree().create_timer(0.5).timeout
		_prompt_dodge_reaction(2, 1, "NORMAL")
		await get_tree().create_timer(0.4).timeout

		# Test switching to the second valid card (♦ 2 Đỡ) to prove manual selection works
		var valid_cards = _get_valid_dodge_cards(2)
		if valid_cards.size() >= 2:
			_select_dodge_card(valid_cards[1])

		await get_tree().create_timer(0.6).timeout
		var tex_d = get_viewport().get_texture()
		if tex_d:
			var img_d = tex_d.get_image()
			if img_d:
				img_d.save_png("res://battle_2v2_dodge_screenshot.png")
				print("[Screenshot] Đã lưu battle_2v2_dodge_screenshot.png!")
		get_tree().quit()

	if "--screenshot-dodge-nododge" in cmd_args:
		# Discard all dodge cards from hand so player has no Dodge
		for ch in hand_container.get_children():
			var info = _get_card_info_from_ui(ch)
			if "đỡ" in info.get("name", "").to_lower():
				ch.queue_free()
		await get_tree().create_timer(0.5).timeout
		_prompt_dodge_reaction(2, 1, "NORMAL")
		await get_tree().create_timer(0.6).timeout
		var tex_nd = get_viewport().get_texture()
		if tex_nd:
			var img_nd = tex_nd.get_image()
			if img_nd:
				img_nd.save_png("res://battle_2v2_dodge_nododge_screenshot.png")
				print("[Screenshot] Đã lưu battle_2v2_dodge_nododge_screenshot.png!")
		get_tree().quit()

	if "--screenshot-chain-modal" in cmd_args:
		await get_tree().create_timer(0.5).timeout
		_show_iron_chain_modal()
		await get_tree().create_timer(0.4).timeout
		# Select seat 2 (Cao Lỗ - ally) and seat 4 (enemy) to showcase multi-target & ally chaining
		_toggle_chain_selection(2)
		_toggle_chain_selection(4)
		await get_tree().create_timer(0.6).timeout
		var tex_c = get_viewport().get_texture()
		if tex_c:
			var img_c = tex_c.get_image()
			if img_c:
				img_c.save_png("res://battle_2v2_chain_screenshot.png")
				print("[Screenshot] Đã lưu battle_2v2_chain_screenshot.png!")
		get_tree().quit()

	if "--screenshot-card-pick-modal" in cmd_args:
		# Equip some items to seat 2 to show both face-down cards & equipment options
		if generals_data.has(2):
			generals_data[2]["equipped_weapon"] = "Nỏ Thần Kim Quy"
			generals_data[2]["avatar_node"].set_equipment("weapon", "Nỏ Thần Kim Quy", "Nỏ Thần Kim Quy")
			generals_data[2]["equipped_def_horse"] = "Voi Chiến Đại Việt"
			generals_data[2]["avatar_node"].set_equipment("def_horse", "Voi Chiến Đại Việt", "Voi Chiến Đại Việt")
			generals_data[2]["hand_count"] = 4
		await get_tree().create_timer(0.5).timeout
		_show_card_pick_modal(true, 2)
		await get_tree().create_timer(0.4).timeout
		# Pick the weapon button if available
		for child in card_pick_options_hbox.get_children():
			if "VŨ KHÍ" in child.text:
				child.emit_signal("pressed")
				break
		await get_tree().create_timer(0.6).timeout
		var tex_p = get_viewport().get_texture()
		if tex_p:
			var img_p = tex_p.get_image()
			if img_p:
				img_p.save_png("res://battle_2v2_card_pick_screenshot.png")
				print("[Screenshot] Đã lưu battle_2v2_card_pick_screenshot.png!")
		get_tree().quit()

func _process(delta: float) -> void:
	# Subtle background breathing animation
	bg_anim_timer += delta * 0.35
	if bg_rect and is_instance_valid(bg_rect):
		var scale_v = 1.02 + sin(bg_anim_timer) * 0.02
		bg_rect.scale = Vector2(scale_v, scale_v)
		bg_rect.position = Vector2(cos(bg_anim_timer * 0.6) * 8.0 - 40.0, sin(bg_anim_timer * 0.4) * 6.0 - 25.0)

	# Floating Golden Embers
	for p in ember_particles:
		if is_instance_valid(p):
			var pos = p.position
			pos.y -= p.get_meta("speed_y") * delta
			pos.x += p.get_meta("drift_x") * delta * sin(Time.get_ticks_msec() * 0.002)
			if pos.y < -10:
				pos.y = 730
				pos.x = randf_range(0, 1280)
			p.position = pos

	if is_game_over:
		return

	# Handle Local Player Turn Timer
	if is_player_turn:
		current_turn_timer -= delta
		var sec = max(0, int(ceil(current_turn_timer)))
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (%ds)" % sec
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node"):
			generals_data[my_seat]["avatar_node"].update_turn_timer(sec)
		if current_turn_timer <= 0:
			_on_player_turn_timeout()

	# Handle Remote / AI Turn Timer
	if not is_player_turn and current_turn_seat > 0 and generals_data.has(current_turn_seat):
		var sec_remote = max(0, int(ceil(remote_turn_timer)))
		generals_data[current_turn_seat]["avatar_node"].update_turn_timer(sec_remote)

	# Handle Dodge Reaction Timer
	if is_waiting_dodge:
		dodge_time_left -= delta
		var sec = max(0, int(ceil(dodge_time_left)))
		dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if dodge_time_left <= 0:
			_on_dodge_passed()

	# Handle Rescue Reaction Timer (Bánh Chưng / Hủ Rượu Cận Tử)
	if is_waiting_rescue:
		rescue_time_left -= delta
		var sec = max(0, int(ceil(rescue_time_left)))
		rescue_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if rescue_time_left <= 0:
			_on_rescue_passed()

func _start_ambient_effects() -> void:
	if not is_instance_valid(embers_layer):
		return
	for i in range(22):
		var ember = ColorRect.new()
		var s = randf_range(3.0, 7.0)
		ember.custom_minimum_size = Vector2(s, s)
		ember.color = Color(1.0, randf_range(0.75, 0.95), randf_range(0.25, 0.45), randf_range(0.35, 0.75))
		ember.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		ember.set_meta("speed_y", randf_range(25.0, 60.0))
		ember.set_meta("drift_x", randf_range(-18.0, 18.0))
		embers_layer.add_child(ember)
		ember_particles.append(ember)

func _init_deck() -> void:
	card_deck_pile.clear()
	card_deck_pile = CardDatabase.create_deck_80()
	var room_id = ""
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		room_id = AppwriteMatchmaking.current_room.get("roomId", "")
	elif NetworkClient and NetworkClient.room_id != "":
		room_id = NetworkClient.room_id

	if room_id != "":
		# Đồng bộ 100% hạt giống xáo bài giữa các máy người chơi trong cùng một phòng đấu
		seed(hash(room_id))
	else:
		randomize()

	# Xáo bài đa tầng (5-pass shuffle) để phá vỡ hoàn toàn các cụm bài Trảm / Đỡ khởi tạo tuần tự:
	for p in range(5):
		card_deck_pile.shuffle()
	deck_count = card_deck_pile.size()
	_update_deck_hud()

func _update_deck_hud() -> void:
	if deck_label:
		deck_label.text = "🎴 %d" % deck_count

func _draw_card_from_pile() -> Dictionary:
	if card_deck_pile.is_empty():
		_init_deck()
	deck_count = max(0, deck_count - 1)
	_update_deck_hud()
	return card_deck_pile.pop_back()

func _init_generals_from_draft() -> void:
	var draft = []
	if AppwriteMatchmaking and not AppwriteMatchmaking.draft_slots.is_empty():
		draft = AppwriteMatchmaking.draft_slots
	elif AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		if AppwriteMatchmaking.current_room.get("draft_slots", []).size() == 4:
			draft = AppwriteMatchmaking.current_room["draft_slots"]
		elif AppwriteMatchmaking.current_room.get("slots", []).size() == 4:
			draft = AppwriteMatchmaking.current_room["slots"]

	# Xác định ghế của người chơi tại máy
	my_seat = 1
	var found_player_seat = false
	for slot in draft:
		var slot_uid = slot.get("userId", "")
		var is_slot_p = slot.get("isPlayer", false)
		if is_slot_p:
			my_seat = slot.get("seatNumber", 1)
			found_player_seat = true
			break
		elif AuthManager and AuthManager.current_user_id != "" and slot_uid == AuthManager.current_user_id:
			my_seat = slot.get("seatNumber", 1)
			found_player_seat = true
			break

	if not found_player_seat and NetworkClient and NetworkClient.my_seat > 0:
		my_seat = NetworkClient.my_seat

	my_team_is_dragon = (my_seat == 1 or my_seat == 3)

	# 4 Tướng mặc định chuẩn 4 thế lực Cổ - Tiền - Trung - Hậu
	var default_heroes = [
		{"id": 53, "name": "Trần Hưng Đạo", "faction": "Trung", "maxHp": 4, "slug": "tran_hung_dao", "skills": [{"name": "⚡ HỊCH TƯỚNG", "desc": "Tập kích hiệu triệu ba quân."}]},
		{"id": 1, "name": "Cao Lỗ", "faction": "Cổ", "maxHp": 4, "slug": "cao_lo", "skills": [{"name": "🎯 CHẾ NỎ", "desc": "Bắn nỏ thần uy lực muôn dặm."}]},
		{"id": 47, "name": "Lý Thường Kiệt", "faction": "Trung", "maxHp": 4, "slug": "ly_thuong_kiet", "skills": [{"name": "📜 TIẾN THOÁI", "desc": "Công thủ vẹn toàn, biến Trảm thành Đỡ."}]},
		{"id": 14, "name": "Triệu Quang Phục", "faction": "Cổ", "maxHp": 4, "slug": "trieu_quang_phuc", "skills": [{"name": "🌫️ DẠ TRẠCH", "desc": "Ẩn mình nơi đầm lầy Dạ Trạch."}]}
	]

	# Ánh xạ layout bàn cờ theo chuẩn Unity:
	# Bạn (Người chơi tại máy) luôn ngồi góc Dưới Phải (SeatBottomRight)
	# Offset 1 (seat + 1): Top-Right
	# Offset 2 (seat + 2): Top-Left (Đồng Đội)
	# Offset 3 (seat + 3): Mid-Left
	var seat_to_avatar = {}
	var seat_to_offset = {}
	for s_num in [1, 2, 3, 4]:
		var offset = (s_num - my_seat + 4) % 4
		seat_to_offset[s_num] = offset
		if offset == 0:
			seat_to_avatar[s_num] = seat_bottom_right
		elif offset == 1:
			seat_to_avatar[s_num] = seat_top_right
		elif offset == 2:
			seat_to_avatar[s_num] = seat_top_left
		else:
			seat_to_avatar[s_num] = seat_mid_left

	for i in range(4):
		var s_num = i + 1
		var slot_data = {}
		if i < draft.size():
			slot_data = draft[i]

		var is_p = (s_num == my_seat)
		var is_drag = (s_num == 1 or s_num == 3)
		var slot_uid = slot_data.get("userId", "")
		var is_ai = false
		if is_p:
			is_ai = false
		elif slot_data.has("isAI"):
			is_ai = bool(slot_data["isAI"])
		elif slot_uid != "" and not slot_uid.begins_with("bot_") and slot_uid != "empty":
			is_ai = false
		else:
			is_ai = bool(slot_data.get("isAI", not is_p))

		var hero_info = slot_data.get("chosenHero", {})
		if hero_info.is_empty():
			hero_info = default_heroes[i]

		var h_name = hero_info.get("name", "Tướng %d" % s_num)
		var h_faction = hero_info.get("faction", "Trung")
		var h_hp = int(hero_info.get("maxHp", hero_info.get("hp", 4)))
		
		var slug = hero_info.get("slug", "")
		if slug == "":
			var h_id_int = int(hero_info.get("id", 0))
			if HeroDatabase:
				var db_h = HeroDatabase.get_hero(h_id_int)
				if db_h and not db_h.is_empty():
					slug = db_h.get("slug", "")
					h_faction = db_h.get("faction", h_faction)
		if slug == "":
			slug = str(hero_info.get("id", s_num))

		# Hiển thị số thứ tự ghế và tên phe: [1] RỒNG, [2] PHƯỢNG, [3] RỒNG, [4] PHƯỢNG
		var role_str = ("[%d] RỒNG" % s_num) if is_drag else ("[%d] PHƯỢNG" % s_num)

		var avatar_node = seat_to_avatar[s_num]
		avatar_node.setup_general(slug, h_name, h_faction, h_hp, h_hp, role_str)

		# Explicitly verify portrait texture
		var tex_path = "res://assets/ui/" + slug + ".png"
		if ResourceLoader.exists(tex_path) and is_instance_valid(avatar_node.portrait_rect):
			avatar_node.portrait_rect.texture = load(tex_path)

		# Căn chỉnh vị trí nút kỹ năng sao cho thoáng đẹp
		var offset = seat_to_offset[s_num]
		var skill_btn = avatar_node.get_node_or_null("SkillBtn")
		if skill_btn:
			if offset == 3: # SeatMidLeft (Triệu Quang Phục)
				skill_btn.anchor_left = 1.0
				skill_btn.anchor_right = 1.0
				skill_btn.anchor_top = 0.5
				skill_btn.anchor_bottom = 0.5
				skill_btn.offset_left = 8.0
				skill_btn.offset_right = 108.0
				skill_btn.offset_top = -15.0
				skill_btn.offset_bottom = 15.0
			elif offset == 0: # Player Bottom-Right
				skill_btn.anchor_left = 0.5
				skill_btn.anchor_right = 0.5
				skill_btn.anchor_top = 0.0
				skill_btn.anchor_bottom = 0.0
				skill_btn.offset_left = -55.0
				skill_btn.offset_right = 55.0
				skill_btn.offset_top = -36.0
				skill_btn.offset_bottom = -6.0

		# Set skill title if available
		var skills = hero_info.get("skills", [])
		if not skills.is_empty():
			var sk_name = skills[0].get("name", "KỸ NĂNG")
			avatar_node.set_skill(sk_name)

		# Connect click signals
		avatar_node.clicked.connect(func(): _on_general_avatar_clicked(s_num))
		avatar_node.info_clicked.connect(func(): _show_general_info_modal(s_num))
		avatar_node.skill_clicked.connect(func(): _on_general_skill_clicked(s_num))

		generals_data[s_num] = {
			"seat": s_num,
			"isPlayer": is_p,
			"isAI": is_ai,
			"isDragon": is_drag,
			"name": h_name,
			"faction": h_faction,
			"hp": h_hp,
			"max_hp": h_hp,
			"hand_count": 0,
			"hand_cards": [],
			"is_alive": true,
			"hero_data": hero_info,
			"avatar_node": avatar_node,
			"equipped_weapon": "",
			"equipped_armor": "",
			"equipped_off_horse": "",
			"equipped_def_horse": "",
			"is_chained": false,
			"has_lightning": false,
			"has_cat_luong": false,
			"has_tram_ao": false,
			"ao_bao_charges": 0
		}

func _on_general_skill_clicked(s_num: int) -> void:
	if not generals_data.has(s_num):
		return
	var g = generals_data[s_num]
	var h_id = int(g.get("hero_data", {}).get("id", 0))
	var h_name = g.get("name", "")

	# 1. Lý Thường Kiệt (ID 47 - Tiến Thoái): Biến Trảm thành Đỡ và ngược lại
	if (h_id == 47 or "Lý Thường Kiệt" in h_name) and s_num == my_seat:
		var converted_count = 0
		for card_ui in hand_container.get_children():
			var info = _get_card_info_from_ui(card_ui)
			var c_name = info.get("name", "")
			if "Trảm" in c_name:
				card_ui.setup_card_data(info.get("id", ""), "Đỡ", info.get("rank", 1), info.get("suit", ""), 0, "Hóa giải hoàn toàn 1 đòn Trảm (Tiến Thoái)")
				converted_count += 1
			elif c_name == "Đỡ":
				card_ui.setup_card_data(info.get("id", ""), "Trảm Thường", info.get("rank", 1), info.get("suit", ""), 0, "Tấn công gây 1 sát thương (Tiến Thoái)")
				converted_count += 1
		if converted_count > 0:
			_animate_showcase_card("Tiến Thoái", "Lý Thường Kiệt: Hoán đổi %d lá Trảm ⟷ Đỡ!" % converted_count)
			_add_log("✨ [TIẾN THOÁI] Lý Thường Kiệt đã hoán chuyển %d lá Trảm ⟷ Đỡ trên tay!" % converted_count)
			AudioManager.play_skill()
			if is_waiting_dodge:
				var valid_cards = _get_valid_dodge_cards(dodge_attacker_seat)
				_build_dodge_card_selector_buttons(valid_cards)
				if valid_cards.size() > 0:
					_select_dodge_card(valid_cards[0])
				else:
					_select_dodge_card(null)
			elif selected_card_ui:
				_update_action_btn()
		else:
			desc_text.text = "💡 [Tiến Thoái]: Không có lá Trảm hoặc Đỡ nào trên tay để hoán đổi!"
	else:
		desc_text.text = "📜 Kỹ năng của %s: %s" % [g["name"], g.get("hero_data", {}).get("skills", [{}])[0].get("desc", "")]

func _deal_initial_hands() -> void:
	for s_num in [1, 2, 3, 4]:
		var g = generals_data[s_num]
		for k in range(4):
			var card_info = _draw_card_from_pile()
			if g["isPlayer"]:
				_add_card_to_player_hand(card_info)
			else:
				g["hand_cards"].append(card_info)
				g["hand_count"] = g["hand_cards"].size()
		g["avatar_node"].update_hand_count(g["hand_count"])

func _add_card_to_player_hand(c_info: Dictionary) -> void:
	var g = generals_data[my_seat]
	g["hand_count"] += 1
	g["avatar_node"].update_hand_count(g["hand_count"])

	var card_ui = CardUIScene.instantiate()
	hand_container.add_child(card_ui)
	card_ui.setup_card_data(c_info["id"], c_info["name"], c_info["rank"], c_info["suit"], c_info["cat"], c_info["desc"])
	card_ui.card_clicked.connect(func(_c): _on_player_hand_card_clicked(card_ui, c_info))
	AudioManager.play_card_draw()

func _on_player_hand_card_clicked(card_node: Control, c_info: Dictionary) -> void:
	if is_waiting_dodge:
		_handle_dodge_hand_card_selection(card_node, c_info)
		return
	if is_waiting_rescue:
		_handle_rescue_hand_card_selection(card_node, c_info)
		return
	if not is_player_turn:
		return

	if selected_card_ui == card_node:
		# Deselect
		selected_card_ui = null
		desc_text.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng..."
		_update_action_btn()
		return

	# Select new card
	if selected_card_ui and is_instance_valid(selected_card_ui) and selected_card_ui.has_method("set_selected"):
		selected_card_ui.set_selected(false)

	selected_card_ui = card_node
	selected_card_ui.set_selected(true)
	AudioManager.play_card_select()

	var c_name = c_info.get("name", "")
	var c_desc = c_info.get("desc", "")
	var suit = c_info.get("suit", "")
	var rank = c_info.get("rank", 1)

	if is_discard_phase:
		card_play_btn.visible = true
		card_play_btn.disabled = false
		card_play_btn.text = "🗑️ BỎ [%s] (CÒN %d LÁ)" % [c_name.to_upper(), cards_to_discard_count]
		desc_text.text = "🗑️ Nhấp nút để bỏ lá [%s]. Cần bỏ thêm %d lá bài thừa để kết thúc lượt." % [c_name, cards_to_discard_count]
		return

	desc_text.text = "🎴 [%s %s] %s: %s" % [_get_suit_icon(suit), _format_rank(rank), c_name, c_desc]

	_update_action_btn()

func _handle_dodge_hand_card_selection(card_node: Control, _c_info: Dictionary) -> void:
	if not is_waiting_dodge:
		return
	var is_valid = _is_card_valid_for_dodge(card_node, dodge_attacker_seat)
	if is_valid:
		_select_dodge_card(card_node)
	else:
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
		var info = _get_card_info_from_ui(card_node)
		var c_name = info.get("name", "Lá bài")
		desc_text.text = "❌ Lá [%s] không thể dùng để Đỡ đòn Trảm này! Hãy chọn lá [Đỡ] hợp lệ." % c_name
		AudioManager.play_skill()

func _handle_rescue_hand_card_selection(card_node: Control, _c_info: Dictionary) -> void:
	if not is_waiting_rescue:
		return
	var info = _get_card_info_from_ui(card_node)
	var c_name = info.get("name", "")
	var is_valid = false
	if c_name == "Bánh Chưng":
		is_valid = true
	elif c_name == "Hủ Rượu" and rescue_victim_seat == my_seat:
		is_valid = true

	if is_valid:
		if rescue_card_to_use and is_instance_valid(rescue_card_to_use) and rescue_card_to_use != card_node:
			if rescue_card_to_use.has_method("set_selected"):
				rescue_card_to_use.set_selected(false)
		rescue_card_to_use = card_node
		if card_node.has_method("set_selected"):
			card_node.set_selected(true)
		AudioManager.play_card_select()
		var suit_sym = _get_suit_icon(info.get("suit", ""))
		var rank_str = _format_rank(info.get("rank", 1))
		rescue_confirm_btn.text = "🍲 DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name.to_upper()]
		desc_text.text = "🍲 Đã chọn lá [%s %s %s] để cứu viện. Bấm nút để xác nhận." % [suit_sym, rank_str, c_name]
	else:
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
		desc_text.text = "❌ Lá [%s] không thể dùng để cứu viện cận tử!" % c_name
		AudioManager.play_skill()

func _on_general_avatar_clicked(seat_num: int) -> void:
	if is_game_over:
		return

	var g = generals_data.get(seat_num, null)
	if not g or not g["is_alive"]:
		return

	# Don't target self for attack
	if seat_num == my_seat and selected_card_ui:
		var c_info = _get_card_info_from_ui(selected_card_ui)
		if "Trảm" in c_info.get("name", ""):
			return

	# Clear previous target border
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)

	selected_target_seat = seat_num
	g["avatar_node"].set_target_highlight(true)
	_update_action_btn()

func _get_card_info_from_ui(ui_node: Control) -> Dictionary:
	if not ui_node or not is_instance_valid(ui_node):
		return {}
	var c_name = ui_node.get("card_name")
	var suit = ""
	var rank = 1
	var desc = ""
	var cat = 0
	var id = ""
	if ui_node.get("card_data") and ui_node.card_data != null:
		if c_name == null or c_name == "":
			c_name = ui_node.card_data.card_name
		suit = ui_node.card_data.suit
		rank = ui_node.card_data.rank
		desc = ui_node.card_data.description
		cat = ui_node.card_data.category
		id = ui_node.card_data.id
	return {
		"id": id,
		"name": c_name if c_name != null else "",
		"suit": suit,
		"rank": rank,
		"desc": desc,
		"cat": cat,
		"card_node": ui_node
	}

func _update_action_btn() -> void:
	if not is_player_turn or selected_card_ui == null:
		card_play_btn.visible = false
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")

	if "Trảm" in c_name:
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt["isDragon"] != my_team_is_dragon and tgt["is_alive"]:
				card_play_btn.text = "⚔️ %s ➜ %s" % [c_name.to_upper(), tgt["name"]]
				card_play_btn.visible = true
				return
		card_play_btn.text = "⚔️ CHỌN MỤC TIÊU ĐỊCH..."
		card_play_btn.visible = true
	elif c_name == "Bánh Chưng":
		var p_gen = generals_data[my_seat]
		if p_gen["hp"] < p_gen["max_hp"]:
			card_play_btn.text = "🍲 DÙNG BÁNH CHƯNG (HỒI 1 MÁU)"
			card_play_btn.visible = true
		else:
			card_play_btn.text = "MÁU ĐÃ ĐẦY (KHÔNG THỂ DÙNG)"
			card_play_btn.visible = true
	elif c_name == "Hủ Rượu":
		card_play_btn.text = "🍶 UỐNG RƯỢU (+1 SÁT THƯƠNG)"
		card_play_btn.visible = true
	elif c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		card_play_btn.text = "🗡️ TRANG BỊ VŨ KHÍ [%s]" % c_name
		card_play_btn.visible = true
	elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
		card_play_btn.text = "🛡️ TRANG BỊ ÁO GIÁP [%s]" % c_name
		card_play_btn.visible = true
	elif c_name == "Voi Chiến Đại Việt":
		card_play_btn.text = "🐘 TRANG BỊ NGỰA THỦ (+1 K/CÁCH)"
		card_play_btn.visible = true
	elif c_name == "Ngựa Trắng Thuần Nông":
		card_play_btn.text = "🐎 TRANG BỊ NGỰA CÔNG (-1 K/CÁCH)"
		card_play_btn.visible = true
	elif c_name == "Xích Tâm Tỏa":
		card_play_btn.text = "⛓️ DÙNG XÍCH TÂM TỎA (CHỌN TƯỚNG)"
		card_play_btn.visible = true
	elif c_name == "Thần Sấm Báo Ứng":
		card_play_btn.text = "⚡ ĐẶT [THẦN SẤM BÁO ỨNG] (VÀO BẢN THÂN)"
		card_play_btn.visible = true
	elif c_name == "Diệu Kế Phá Mưu":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "📜 PHÁ MƯU ➜ %s" % tgt["name"]
		else:
			card_play_btn.text = "📜 CHỌN MỤC TIÊU ĐỂ PHÁ MƯU..."
		card_play_btn.visible = true
	elif c_name == "Vườn Không Nhà Trống":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "🌾 PHÁ HỦY BÀI ➜ %s" % tgt["name"]
		else:
			card_play_btn.text = "🌾 CHỌN MỤC TIÊU ĐỂ PHÁ HỦY..."
		card_play_btn.visible = true
	elif c_name == "Đột Kích Trộm Lương":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "🗡️ CƯỚP BÀI ➜ %s" % tgt["name"]
		else:
			card_play_btn.text = "🗡️ CHỌN MỤC TIÊU ĐỂ CƯỚP..."
		card_play_btn.visible = true
	elif c_name == "Bãi Cọc Ngầm":
		card_play_btn.text = "🪵 BÃI CỌC NGẦM (TẤT CẢ NGƯỜI KHÁC)"
		card_play_btn.visible = true
	elif c_name == "Mưa Tên Liên Châu":
		card_play_btn.text = "🏹 MƯA TÊN LIÊN CHÂU (TẤT CẢ NGƯỜI KHÁC)"
		card_play_btn.visible = true
	elif c_name == "Thách Đấu":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt["seat"] != my_seat and tgt["is_alive"]:
				card_play_btn.text = "⚔️ THÁCH ĐẤU ➜ %s" % tgt["name"]
				card_play_btn.visible = true
				return
		card_play_btn.text = "⚔️ CHỌN MỤC TIÊU THÁCH ĐẤU..."
		card_play_btn.visible = true
	elif c_name == "Mở Kho Cứu Tế":
		card_play_btn.text = "🌾 MỞ KHO CỨU TẾ (CHIA ĐỀU BÀI)"
		card_play_btn.visible = true
	elif c_name == "Dụng Binh Như Thần":
		card_play_btn.text = "📜 RÚT 2 LÁ BÀI (DỤNG BINH)"
		card_play_btn.visible = true
	else:
		card_play_btn.text = "DÙNG [%s]" % c_name
		card_play_btn.visible = true

func _reset_player_turn_timer() -> void:
	if is_player_turn:
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node"):
			generals_data[my_seat]["avatar_node"].update_turn_timer(40)

func _on_card_play_btn_clicked() -> void:
	if not is_player_turn or selected_card_ui == null:
		return

	if is_discard_phase:
		var info_d = _get_card_info_from_ui(selected_card_ui)
		var c_name_d = info_d.get("name", "Bài")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		cards_to_discard_count -= 1
		_add_log("🗑️ Bạn đã bỏ lá bài thừa [%s] (Còn cần bỏ %d lá)." % [c_name_d, cards_to_discard_count])
		_animate_showcase_card(c_name_d, "Bỏ bài thừa: %s" % c_name_d)
		AudioManager.play_card_draw()

		if cards_to_discard_count > 0:
			card_play_btn.text = "🗑️ BỎ %d LÁ THỪA (CHỌN BÀI)" % cards_to_discard_count
			card_play_btn.disabled = true
			desc_text.text = "⚠️ Hãy chọn tiếp lá bài thừa để bỏ (Còn %d lá)." % cards_to_discard_count
		else:
			is_discard_phase = false
			card_play_btn.visible = false
			card_play_btn.disabled = false
			_add_log("✅ Bạn đã hoàn thành việc bỏ bài thừa.")
			_finish_player_end_turn()
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")

	if "Trảm" in c_name:
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ trên bàn để Trảm!"
			return
		var tgt = generals_data[selected_target_seat]
		if tgt["isDragon"] == my_team_is_dragon:
			desc_text.text = "⚠️ Không thể Trảm đồng minh cùng phe!"
			return

		var p_gen = generals_data[my_seat]
		var has_no_than = (p_gen["equipped_weapon"] == "Nỏ Thần Kim Quy")
		if slashes_used_this_turn >= 1 and not has_no_than:
			desc_text.text = "⚠️ Mỗi lượt chỉ được Trảm 1 lần (Trừ khi có Nỏ Thần)!"
			return

		var is_wine = is_wine_buff_active
		var base_slash_dmg = 1
		var slash_dmg = base_slash_dmg + (1 if is_wine else 0)
		is_wine_buff_active = false

		var elem = "NORMAL"
		if "Hỏa" in c_name: elem = "FIRE"
		elif "Lôi" in c_name: elem = "LIGHTNING"

		slashes_used_this_turn += 1
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()

		AudioManager.play_voice(c_name)
		AudioManager.play_slash()
		_broadcast_player_battle_action("PLAY_CARD", c_name, tgt["seat"])
		_animate_showcase_card(c_name, "Bạn dùng [%s] tấn công %s!" % [c_name, tgt["name"]])
		_add_log("⚔️ Bạn dùng [%s]%s lên %s (Ghế %d)." % [c_name, " (kèm Hủ Rượu: +1 Sát Thương)" if is_wine else "", tgt["name"], tgt["seat"]])

		var slash_suit = c_info.get("suit", "")
		_handle_slash_attack(my_seat, tgt["seat"], slash_dmg, elem, slash_suit)

	elif c_name == "Bánh Chưng":
		var p_gen = generals_data[my_seat]
		if p_gen["hp"] >= p_gen["max_hp"]:
			desc_text.text = "⚠️ Máu của bạn đã đầy (%d/%d)!" % [p_gen["hp"], p_gen["max_hp"]]
			return
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		p_gen["hp"] = min(p_gen["max_hp"], p_gen["hp"] + 1)
		p_gen["avatar_node"].update_hp(p_gen["hp"], p_gen["max_hp"])
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "banh_chung", my_seat)
		_animate_showcase_card(c_name, "Bạn ăn Bánh Chưng hồi 1 Máu!")
		_add_log("🍲 Bạn hồi phục 1 Máu bằng [Bánh Chưng] (%d/%d)." % [p_gen["hp"], p_gen["max_hp"]])

	elif c_name == "Hủ Rượu":
		is_wine_buff_active = true
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "ruou", my_seat)
		_animate_showcase_card(c_name, "Bạn uống Hủ Rượu (+1 Sát Thương)!")
		_add_log("🍶 Bạn đã uống [Hủ Rượu], đòn Trảm kế tiếp được +1 Sát Thương!")

	elif c_name == "Xích Tâm Tỏa":
		_show_iron_chain_modal()
		return

	elif c_name == "Dụng Binh Như Thần":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		var p_gen_db = generals_data.get(my_seat, {})
		var draw_num = 3 if p_gen_db.get("hero_id", 0) == 68 else 2
		for k in range(draw_num):
			var c_draw = _draw_card_from_pile()
			_add_card_to_player_hand(c_draw)
		_broadcast_player_battle_action("PLAY_CARD", "dungbinh", my_seat)
		_animate_showcase_card(c_name, "Rút ngay %d lá bài!" % draw_num)
		_add_log("📜 Bạn thi triển [Dụng Binh Như Thần], rút ngay %d lá bài từ xấp bài!" % draw_num)

	elif c_name == "Đột Kích Trộm Lương":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ trên bàn để cướp bài!"
			return
		var tgt = generals_data[selected_target_seat]
		if tgt["isDragon"] == my_team_is_dragon:
			desc_text.text = "⚠️ Không thể cướp bài của đồng đội cùng phe!"
			return
		var dist = _calculate_distance(my_seat, selected_target_seat)
		if dist > 1:
			desc_text.text = "⚠️ Khoảng cách tới %s là %d (Vượt quá cự ly 1 của Đột Kích Trộm Lương)!" % [tgt["name"], dist]
			return
		_show_card_pick_modal(true, selected_target_seat)
		return

	elif c_name == "Vườn Không Nhà Trống":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng mục tiêu trên bàn để phá hủy bài!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự phá hủy bài của chính mình!"
			return
		_show_card_pick_modal(false, selected_target_seat)
		return

	elif c_name == "Diệu Kế Phá Mưu":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng mục tiêu để phá mưu/hủy bài!"
			return
		_show_card_pick_modal(false, selected_target_seat)
		return

	elif c_name == "Bãi Cọc Ngầm":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Bãi Cọc Ngầm")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "D80_CN_BaiCoc", 0)
		_animate_showcase_card(c_name, "Bãi Cọc Ngầm: Toàn bộ người chơi khác phải đánh 1 Trảm!")
		_add_log("🪵 Bạn phát động [Bãi Cọc Ngầm]! Toàn bộ người chơi khác phải đánh 1 lá Trảm hoặc mất 1 Máu.")
		_execute_aoe_attack(my_seat, "Bãi Cọc Ngầm", "Trảm")

	elif c_name == "Mưa Tên Liên Châu":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Mưa Tên Liên Châu")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "D80_CN_MuaTen", 0)
		_animate_showcase_card(c_name, "Mưa Tên Liên Châu: Toàn bộ người chơi khác phải đánh 1 Đỡ!")
		_add_log("🏹 Bạn thi triển [Mưa Tên Liên Châu]! Toàn bộ người chơi khác phải đánh 1 lá Đỡ hoặc mất 1 Máu.")
		_execute_aoe_attack(my_seat, "Mưa Tên Liên Châu", "Đỡ")

	elif c_name == "Thách Đấu":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ trên bàn để Thách Đấu!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự Thách Đấu chính mình!"
			return
		var tgt = generals_data[selected_target_seat]
		if not tgt["is_alive"]:
			desc_text.text = "⚠️ Mục tiêu đã tử trận!"
			return
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Thách Đấu")
		AudioManager.play_slash()
		_broadcast_player_battle_action("PLAY_CARD", "D80_CN_ThachDau", tgt["seat"])
		_animate_showcase_card(c_name, "Bạn thách đấu %s!" % tgt["name"])
		_add_log("⚔️ Bạn phát động [Thách Đấu] lên %s (Ghế %d)!" % [tgt["name"], tgt["seat"]])
		_execute_duel(my_seat, selected_target_seat)

	elif c_name == "Mở Kho Cứu Tế":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Mở Kho Cứu Tế")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "D80_CN_MoKho", 0)
		_animate_showcase_card(c_name, "Mở kho phát bài cho tất cả người chơi!")
		_add_log("🌾 Bạn thi triển [Mở Kho Cứu Tế]! Chia bài cho toàn bộ người chơi còn sống.")
		_execute_harvest(my_seat)

	elif c_name == "Thần Sấm Báo Ứng":
		var p_gen = generals_data[my_seat]
		p_gen["has_lightning"] = true
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			p_gen["avatar_node"].set_delayed_trick("lightning", true)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn tự đặt [Thần Sấm Báo Ứng] vào khu phán xét!")
		_add_log("⚡ Bạn đã đặt Cẩm Nang Trì Hoãn [Thần Sấm Báo Ứng] vào khu phán xét của chính mình!")

	elif c_name in ["Cắt Đường Lương", "Trầm Ảo Sa Bẫy"]:
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ để dán [Cẩm Nang Trì Hoãn]!"
			return
		var tgt = generals_data[selected_target_seat]
		if c_name == "Cắt Đường Lương":
			tgt["has_cat_luong"] = true
			if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
				tgt["avatar_node"].set_delayed_trick("supply_shortage", true)
		else:
			tgt["has_tram_ao"] = true
			if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
				tgt["avatar_node"].set_delayed_trick("acedia", true)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, tgt["seat"])
		_animate_showcase_card(c_name, "Đặt [%s] lên %s!" % [c_name, tgt["name"]])
		_add_log("⏳ Bạn đặt Cẩm Nang Trì Hoãn [%s] vào khu phán xét của %s (Ghế %d)!" % [c_name, tgt["name"], tgt["seat"]])

	elif c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		var p_gen = generals_data[my_seat]
		p_gen["equipped_weapon"] = c_name
		p_gen["avatar_node"].set_equipment("weapon", c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn trang bị [%s]!" % c_name)
		_add_log("🗡️ Bạn đã trang bị Vũ Khí: [%s]!" % c_name)

	elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
		var p_gen = generals_data[my_seat]
		p_gen["equipped_armor"] = c_name
		if c_name == "Áo Bào Hoàng Tộc":
			p_gen["ao_bao_charges"] = 3
		p_gen["avatar_node"].set_equipment("armor", c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn trang bị [%s]!" % c_name)
		_add_log("🛡️ Bạn đã trang bị Áo Giáp: [%s]!" % c_name)

	elif c_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
		var p_gen = generals_data[my_seat]
		var slot_type = "def_horse" if c_name == "Voi Chiến Đại Việt" else "off_horse"
		if c_name == "Voi Chiến Đại Việt":
			p_gen["equipped_def_horse"] = c_name
		else:
			p_gen["equipped_off_horse"] = c_name
		p_gen["avatar_node"].set_equipment(slot_type, c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn cưỡi [%s]!" % c_name)
		_add_log("🐎 Bạn đã trang bị Chiến Mã: [%s]!" % c_name)

	else:
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, 0)
		_animate_showcase_card(c_name, "Bạn đã dùng [%s]!" % c_name)
		_add_log("🎴 Bạn đã dùng [%s]." % c_name)

func _broadcast_player_battle_action(act_type: String, card_id: String, target_seat: int = 0, caster_seat: int = 0) -> void:
	var c_seat = caster_seat if caster_seat > 0 else my_seat
	if NetworkClient and NetworkClient.is_connected_to_server:
		if act_type == "PLAY_CARD":
			NetworkClient.send_play_card_for_seat(c_seat, card_id, target_seat)
		elif act_type == "END_TURN":
			NetworkClient.send_end_turn_for_seat(c_seat)

	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		var r_id = AppwriteMatchmaking.current_room.get("roomId", "")
		if not r_id.is_empty():
			AppwriteMatchmaking.send_battle_action({
				"roomId": r_id,
				"casterSeat": c_seat,
				"targetSeat": target_seat,
				"actionType": act_type,
				"cardId": card_id,
				"senderUserId": AuthManager.current_user_id if AuthManager else ""
			})

func _build_initial_server_players() -> Array:
	var players = []
	for seat in [1, 2, 3, 4]:
		if not generals_data.has(seat):
			continue
		var g = generals_data[seat]
		var h_info = g.get("hero_data", {})
		var h_id = str(h_info.get("id", seat))
		var is_p = (seat == my_seat)
		var is_ai = g.get("isAI", not is_p)
		var u_id = ""
		if AppwriteMatchmaking and AppwriteMatchmaking.draft_slots.size() >= seat:
			u_id = AppwriteMatchmaking.draft_slots[seat - 1].get("userId", "")
		elif AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary and AppwriteMatchmaking.current_room.get("slots", []).size() >= seat:
			u_id = AppwriteMatchmaking.current_room["slots"][seat - 1].get("userId", "")
		if u_id.is_empty():
			u_id = ("user_%d" % seat) if not is_ai else ("bot_%d" % seat)

		players.append({
			"seat": seat,
			"userId": u_id,
			"heroId": h_id,
			"generalName": g.get("name", "Tướng %d" % seat),
			"maxHp": g.get("max_hp", 4),
			"hp": g.get("hp", 4),
			"isAlly": (seat == 1 or seat == 3),
			"isAI": is_ai
		})
	return players

func _on_network_connected() -> void:
	if not NetworkClient:
		return
	var r_id = "room_1"
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		var appwrite_r_id = AppwriteMatchmaking.current_room.get("roomId", "")
		if not appwrite_r_id.is_empty():
			r_id = appwrite_r_id
	var initial_players = _build_initial_server_players()
	NetworkClient.send_join_room(r_id, my_seat, initial_players)
	_add_log("🌐 [ĐỒNG BỘ MẠNG] Đã kết nối Local Server (Cổng 8080)! Phòng: %s, Ghế: %d" % [r_id, my_seat])

func _on_network_player_joined(joined_seat: int, active_seats: Array) -> void:
	for s in active_seats:
		var s_num = int(s)
		if generals_data.has(s_num) and s_num != my_seat:
			if generals_data[s_num].get("isAI", false):
				generals_data[s_num]["isAI"] = false
				_add_log("👤 [KẾT NỐI MẠNG] Người chơi thật đã nhận Ghế %d! Chuyển quyền điều khiển cho người thật." % s_num)
	if joined_seat > 0 and joined_seat != my_seat:
		_add_log("👋 Tướng Ghế %d đã tham gia phòng qua Local Server!" % joined_seat)

func _on_network_error_received(err_msg: String) -> void:
	_add_log("⚠️ [MẠNG SERVER] %s" % err_msg)

func _on_network_game_state_updated(state: Dictionary) -> void:
	if state.is_empty():
		return
	var players = state.get("players", [])
	for p in players:
		var seat = int(p.get("seat", 0))
		if generals_data.has(seat):
			var g = generals_data[seat]
			var server_hp = int(p.get("hp", g["hp"]))
			var server_max_hp = int(p.get("maxHp", g["max_hp"]))
			if server_hp != g["hp"]:
				g["hp"] = server_hp
				g["avatar_node"].update_hp(g["hp"], server_max_hp)
			var is_chained = bool(p.get("isChained", false))
			if is_chained != g.get("is_chained", false):
				g["is_chained"] = is_chained
				g["avatar_node"].set_chained(is_chained)

func _on_network_action_received(delta: Dictionary) -> void:
	if delta.is_empty():
		return
	var caster_seat = int(delta.get("casterSeat", delta.get("seat", 0)))
	if caster_seat == 0 and delta.has("turnSeat"):
		caster_seat = int(delta.get("turnSeat", 0))

	# Bỏ qua hành động của chính mình để tránh xử lý 2 lần
	if caster_seat == my_seat and caster_seat > 0:
		return

	var act_type = delta.get("actionType", delta.get("type", delta.get("action", "")))
	var target_seat = int(delta.get("targetSeat", 0))
	var card_id = delta.get("cardId", "")
	if card_id.is_empty() and delta.has("activeCard") and delta["activeCard"] is Dictionary:
		card_id = delta["activeCard"].get("name", delta["activeCard"].get("id", ""))

	if act_type in ["PLAY_CARD", "play_card", "CARD_PLAYED"]:
		if caster_seat > 0 and not card_id.is_empty():
			_handle_remote_card_play(caster_seat, card_id, target_seat)
	elif act_type in ["END_TURN", "end_turn", "TURN_ENDED"]:
		if is_remote_turn_active and current_turn_seat == caster_seat:
			is_remote_turn_active = false
	elif act_type in ["DODGE_RESPONSE", "dodge_response"]:
		if card_id == "pass":
			_add_log("🛡️ Tướng Ghế %d không đỡ đòn!" % caster_seat)
		else:
			_add_log("🛡️ Tướng Ghế %d đã dùng Đỡ!" % caster_seat)

func _discard_player_card(card_node: Control) -> void:
	if not card_node or not is_instance_valid(card_node):
		return
	hand_container.remove_child(card_node)
	card_node.queue_free()
	var g = generals_data[my_seat]
	g["hand_count"] = max(0, g["hand_count"] - 1)
	g["avatar_node"].update_hand_count(g["hand_count"])

func _handle_slash_attack(attacker_seat: int, target_seat: int, damage_amount: int = 1, damage_element: String = "NORMAL", slash_card_suit: String = "") -> void:
	var tgt = generals_data[target_seat]
	var atk = generals_data.get(attacker_seat, {})
	atk["last_slash_suit"] = slash_card_suit
	var has_thuan_thien = (atk.get("equipped_weapon", "") == "Kiếm Thuận Thiên")

	# 1. Kiểm tra Giáp Đồng Sơn Vi (chỉ chặn Trảm Thường, bị Kiếm Thuận Thiên xuyên qua)
	if not has_thuan_thien and damage_element == "NORMAL" and tgt["equipped_armor"] == "Giáp Đồng Sơn Vi":
		_animate_showcase_card("Giáp Đồng Sơn Vi", "Giáp Đồng vô hiệu hóa đòn Trảm Thường!")
		_add_log("🛡️ [Giáp Đồng Sơn Vi] của %s đã vô hiệu hóa hoàn toàn đòn Trảm Thường!" % tgt["name"])
		return

	# 2. Kiểm tra Khiên Mây Bện (lật phán xét Đỏ tự động Đỡ, nếu Thuận Thiên thì xuyên)
	if not has_thuan_thien and tgt["equipped_armor"] == "Khiên Mây Bện":
		var judge_card = _draw_card_from_pile()
		var is_red = (judge_card.get("suit", "") in ["Heart", "Diamond"])
		if is_red:
			_animate_showcase_card("Khiên Mây Bện", "Phán xét ĐỎ -> Tự động Đỡ thành công!")
			_add_log("🛡️ [Khiên Mây Bện] của %s lật %s %d (ĐỎ) -> Tự động Đỡ thành công!" % [tgt["name"], judge_card.get("suit", ""), judge_card.get("rank", 1)])
			return
		else:
			_add_log("🛡️ [Khiên Mây Bện] của %s lật %s %d (ĐEN) -> Phán xét thất bại!" % [tgt["name"], judge_card.get("suit", ""), judge_card.get("rank", 1)])

	# 3. Kỹ năng Bùi Bị (Hero 98 - Dũng Hãn): Nếu Máu mục tiêu > Máu người Trảm thì không thể Đỡ
	var cannot_be_dodged = false
	if atk.get("hero_id", -1) == 98 and tgt.get("hp", 0) > atk.get("hp", 0):
		cannot_be_dodged = true
		_add_log("⚔️ Kỹ năng [Dũng Hãn] của %s: Đòn Trảm không thể bị Đỡ!" % atk["name"])

	if cannot_be_dodged:
		_animate_showcase_card("Không Thể Đỡ", "Đòn Trảm không thể bị hóa giải!")
		_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
		return

	if tgt["isPlayer"]:
		_prompt_dodge_reaction(attacker_seat, damage_amount, damage_element)
		return

	# Target is AI
	await get_tree().create_timer(1.2).timeout
	var dodge_idx = -1
	for idx in range(tgt["hand_cards"].size()):
		var c = tgt["hand_cards"][idx]
		if c.get("name", "") == "Đỡ":
			# Nếu người tấn công có Súng Thần Công Hồ Triều: không được Đỡ cùng chất với Trảm
			var has_sung = (atk.get("equipped_weapon", "") == "Súng Thần Công Hồ Triều")
			if has_sung and slash_card_suit != "" and c.get("suit", "") == slash_card_suit:
				continue
			dodge_idx = idx
			break

	if dodge_idx >= 0:
		var used_dodge = tgt["hand_cards"][dodge_idx]
		tgt["hand_cards"].remove_at(dodge_idx)
		tgt["hand_count"] = tgt["hand_cards"].size()
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		var suit_sym = _get_suit_icon(used_dodge.get("suit", ""))
		var rank_str = _format_rank(used_dodge.get("rank", 1))
		_animate_showcase_card("Đỡ", "%s dùng [%s %s Đỡ] hóa giải đòn tấn công!" % [tgt["name"], suit_sym, rank_str])
		_add_log("🛡️ %s đã dùng lá [%s %s Đỡ] hóa giải đòn Trảm thành công!" % [tgt["name"], suit_sym, rank_str])
		AudioManager.play_voice("Đỡ")
		AudioManager.play_parry()

		# Kiểm tra Song Cung Mường Nhạ của người tấn công
		if atk.get("equipped_weapon", "") == "Song Cung Mường Nhạ" and attacker_seat == my_seat and hand_container.get_child_count() >= 2:
			_add_log("🏹 [Song Cung Mường Nhạ] của bạn ép %s chịu 1 sát thương!" % tgt["name"])
			AudioManager.play_skill()
			_apply_damage_to_general(target_seat, 1, attacker_seat, "NORMAL")

		# Kiểm tra Trường Đao Nam Sơn của người tấn công
		if atk.get("equipped_weapon", "") == "Trường Đao Nam Sơn":
			if attacker_seat == my_seat:
				var has_extra_slash = false
				for ch in hand_container.get_children():
					if "trảm" in _get_card_info_from_ui(ch).get("name", "").to_lower():
						has_extra_slash = true
						break
				if has_extra_slash:
					var use_td = await _prompt_custom_reaction_async(
						"🗡️ TRƯỜNG ĐAO NAM SƠN",
						"Mục tiêu %s vừa dùng Đỡ!\nBạn có muốn bỏ thêm 1 lá [Trảm] để ép đối phương phải Đỡ lần thứ hai không?" % tgt["name"],
						"Trảm",
						"BỎ QUA",
						"🗡️ BỎ 1 TRẢM ÉP ĐỠ TIẾP",
						10.0
					)
					if use_td:
						_add_log("🗡️ [Trường Đao Nam Sơn] Bạn bỏ thêm 1 lá Trảm ép %s phải Đỡ tiếp!" % tgt["name"])
						# AI mục tiêu kiểm tra lá Đỡ thứ 2
						var second_d_idx = -1
						for idx2 in range(tgt["hand_cards"].size()):
							if tgt["hand_cards"][idx2].get("name", "") == "Đỡ":
								second_d_idx = idx2
								break
						if second_d_idx >= 0:
							var used_d2 = tgt["hand_cards"][second_d_idx]
							tgt["hand_cards"].remove_at(second_d_idx)
							tgt["hand_count"] = tgt["hand_cards"].size()
							tgt["avatar_node"].update_hand_count(tgt["hand_count"])
							_animate_showcase_card("Đỡ", "%s dùng lá Đỡ thứ 2 né đòn thành công!" % tgt["name"])
							_add_log("🛡️ %s đã bỏ thêm lá Đỡ thứ hai né đòn Trường Đao!" % tgt["name"])
							AudioManager.play_parry()
							return
						else:
							_add_log("💥 %s không có lá Đỡ thứ 2, chịu sát thương từ Trường Đao!" % tgt["name"])
							_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
							return
			elif not atk.get("isPlayer", false):
				# AI tấn công có Trường Đao: tự động bỏ thêm Trảm nếu còn
				var extra_s_idx = -1
				for idx_s in range(atk["hand_cards"].size()):
					if "trảm" in atk["hand_cards"][idx_s].get("name", "").to_lower():
						extra_s_idx = idx_s
						break
				if extra_s_idx >= 0:
					atk["hand_cards"].remove_at(extra_s_idx)
					atk["hand_count"] = atk["hand_cards"].size()
					atk["avatar_node"].update_hand_count(atk["hand_count"])
					_animate_showcase_card("Trường Đao Nam Sơn", "%s bỏ thêm 1 Trảm ép %s phải Đỡ tiếp!" % [atk["name"], tgt["name"]])
					_add_log("🗡️ [Trường Đao Nam Sơn] %s bỏ thêm 1 Trảm ép %s phải Đỡ tiếp!" % [atk["name"], tgt["name"]])
					# Check if target has 2nd dodge
					var tgt_d2_idx = -1
					for idx_d in range(tgt["hand_cards"].size()):
						if tgt["hand_cards"][idx_d].get("name", "") == "Đỡ":
							tgt_d2_idx = idx_d
							break
					if tgt_d2_idx >= 0:
						tgt["hand_cards"].remove_at(tgt_d2_idx)
						tgt["hand_count"] = tgt["hand_cards"].size()
						tgt["avatar_node"].update_hand_count(tgt["hand_count"])
						_animate_showcase_card("Đỡ", "%s dùng lá Đỡ thứ 2 né đòn!" % tgt["name"])
						_add_log("🛡️ %s dùng lá Đỡ thứ 2 né đòn thành công!" % tgt["name"])
						return
					else:
						_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
						return
	else:
		_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)

func _prompt_dodge_reaction(attacker_seat: int, damage_amount: int = 1, damage_element: String = "NORMAL") -> void:
	var atk = generals_data[attacker_seat]
	dodge_attacker_seat = attacker_seat
	incoming_slash_damage = damage_amount
	incoming_slash_element = damage_element
	dodge_time_left = 15.0
	is_waiting_dodge = true
	selected_dodge_card_ui = null

	# Hủy chọn bài đang chọn ở lượt trước nếu có
	if selected_card_ui and is_instance_valid(selected_card_ui):
		if selected_card_ui.has_method("set_selected"):
			selected_card_ui.set_selected(false)
		selected_card_ui = null

	dodge_desc_lbl.text = "%s (Ghế %d) đang dùng [Trảm] tấn công bạn!\nHãy CHỌN một lá bài trên tay để Đỡ hoặc bấm [CHỊU ĐÒN]:" % [atk["name"], attacker_seat]
	dodge_timer_lbl.text = "⏳ Còn lại: 15s"
	dodge_pass_btn.text = "💥 CHỊU ĐÒN (-%d MÁU)" % incoming_slash_damage
	dodge_pass_btn.disabled = false

	var valid_cards = _get_valid_dodge_cards(attacker_seat)
	_build_dodge_card_selector_buttons(valid_cards)

	if valid_cards.size() > 0:
		_select_dodge_card(valid_cards[0])
		desc_text.text = "🛡️ Bị Trảm! Nhấp lá bài trên tay hoặc các nút ở trên để đổi lá Đỡ bạn muốn dùng."
	else:
		_select_dodge_card(null)
		desc_text.text = "⚠️ Bị Trảm nhưng không có sẵn lá Đỡ! Bạn hãy bấm [💥 CHỊU ĐÒN] hoặc dùng kỹ năng tướng đổi bài."

	dodge_modal.visible = true

func _is_card_valid_for_dodge(card_ui: Control, attacker_seat: int) -> bool:
	if not card_ui or not is_instance_valid(card_ui):
		return false
	var info = _get_card_info_from_ui(card_ui)
	var c_name = info.get("name", "")
	var suit = info.get("suit", "")
	var rank = int(info.get("rank", 1))

	var my_gen = generals_data.get(my_seat, {})
	var atk_gen = generals_data.get(attacker_seat, {})

	# 1. Súng Thần Công Hồ Triều: Mục tiêu không được dùng Đỡ cùng chất với Trảm
	if atk_gen.get("equipped_weapon", "") == "Súng Thần Công Hồ Triều":
		var slash_suit = atk_gen.get("last_slash_suit", "")
		if slash_suit != "" and suit == slash_suit:
			return false

	# 2. Hero 72: Trần Duệ Tông ("Trực Chiến"): Đỡ phải >= 7
	if atk_gen.get("hero_id", -1) == 72:
		if rank < 7:
			return false

	# 3. Hero 44: Tông Đản ("Thổ Binh"): Cự ly <= 2 không được dùng Đỡ từ 2..5
	if atk_gen.get("hero_id", -1) == 44:
		var dist = _calculate_distance(attacker_seat, my_seat)
		if dist <= 2 and rank >= 2 and rank <= 5:
			return false

	# Cơ bản: Lá bài "Đỡ"
	if "đỡ" in c_name.to_lower():
		return true

	# Hero 47: Lý Thường Kiệt ("Tiến Thoái"): Dùng Trảm như Đỡ
	if my_gen.get("hero_id", -1) == 47 and "trảm" in c_name.to_lower():
		return true

	# Hero 83: Nguyễn Cảnh Chân ("Thủy Binh"): Dùng bài chất Chuồn (♣) như Đỡ
	if my_gen.get("hero_id", -1) == 83 and suit == "Club":
		return true

	return false

func _get_valid_dodge_cards(attacker_seat: int) -> Array:
	var valid_list: Array = []
	for card_ui in hand_container.get_children():
		if _is_card_valid_for_dodge(card_ui, attacker_seat):
			valid_list.append(card_ui)
	return valid_list

func _build_dodge_card_selector_buttons(valid_cards: Array) -> void:
	if not dodge_card_selector_hbox:
		return
	for ch in dodge_card_selector_hbox.get_children():
		ch.queue_free()

	if valid_cards.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "❌ Không có lá Đỡ phù hợp trên tay"
		empty_lbl.add_theme_color_override("font_color", Color(0.9, 0.45, 0.45, 1.0))
		empty_lbl.add_theme_font_size_override("font_size", 11)
		dodge_card_selector_hbox.add_child(empty_lbl)
		return

	for card_ui in valid_cards:
		var info = _get_card_info_from_ui(card_ui)
		var suit = info.get("suit", "")
		var suit_sym = _get_suit_icon(suit)
		var rank_str = _format_rank(info.get("rank", 1))
		var c_name = info.get("name", "Đỡ")

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(105, 34)
		btn.text = "%s %s %s" % [suit_sym, rank_str, c_name]
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 11)
		if suit in ["Heart", "Diamond"]:
			btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
		else:
			btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))

		var captured_card = card_ui
		btn.pressed.connect(func(): _select_dodge_card(captured_card))
		btn.set_meta("card_ui", card_ui)
		dodge_card_selector_hbox.add_child(btn)

func _update_dodge_card_selector_buttons() -> void:
	if not dodge_card_selector_hbox:
		return
	for ch in dodge_card_selector_hbox.get_children():
		if ch is Button and ch.has_meta("card_ui"):
			var card_ref = ch.get_meta("card_ui")
			if card_ref == selected_dodge_card_ui:
				ch.modulate = Color(1.4, 1.4, 1.0, 1.0)
				if not ch.text.begins_with("👉 "):
					ch.text = "👉 " + ch.text
			else:
				ch.modulate = Color(0.85, 0.85, 0.85, 0.85)
				ch.text = ch.text.trim_prefix("👉 ")

func _select_dodge_card(card_ui: Control) -> void:
	if card_ui == null:
		selected_dodge_card_ui = null
		dodge_confirm_btn.disabled = true
		dodge_confirm_btn.text = "❌ KHÔNG CÓ BÀI PHÙ HỢP"
		if not custom_reaction_callback.is_valid():
			dodge_pass_btn.text = "💥 CHỊU ĐÒN (-%d MÁU)" % incoming_slash_damage
		dodge_pass_btn.disabled = false
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "⚠️ Bạn chưa chọn lá bài phù hợp. Hãy bấm nút bỏ qua hoặc chịu đòn."
		desc_text.text = "💥 Bạn không có sẵn lá bài phù hợp trên tay!"
		_update_dodge_card_selector_buttons()
		return

	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) and selected_dodge_card_ui != card_ui:
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)

	selected_dodge_card_ui = card_ui
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(true)

	AudioManager.play_card_select()

	var info = _get_card_info_from_ui(card_ui)
	var suit_sym = _get_suit_icon(info.get("suit", ""))
	var rank_str = _format_rank(info.get("rank", 1))
	var c_name = info.get("name", "Bài")

	dodge_confirm_btn.disabled = false
	if custom_reaction_callback.is_valid():
		dodge_confirm_btn.text = "✅ DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name]
	else:
		dodge_confirm_btn.text = "🛡️ DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name]

	if dodge_selected_lbl:
		dodge_selected_lbl.text = "👉 Đang chọn: %s %s [%s]" % [suit_sym, rank_str, c_name]
	desc_text.text = "🛡️ Đã chọn lá [%s %s %s]! Bấm nút để xác nhận hoặc nhấp lá khác trên tay." % [suit_sym, rank_str, c_name]

	_update_dodge_card_selector_buttons()

func _on_dodge_confirmed() -> void:
	if not is_waiting_dodge:
		return
	if not selected_dodge_card_ui or not is_instance_valid(selected_dodge_card_ui):
		_on_dodge_passed()
		return

	var chosen_card = selected_dodge_card_ui
	var card_info = _get_card_info_from_ui(chosen_card)
	var c_name = card_info.get("name", "Bài")
	var suit_sym = _get_suit_icon(card_info.get("suit", ""))
	var rank_str = _format_rank(card_info.get("rank", 1))

	if chosen_card.has_method("set_selected"):
		chosen_card.set_selected(false)
	_discard_player_card(chosen_card)
	selected_dodge_card_ui = null

	dodge_modal.visible = false
	is_waiting_dodge = false

	if custom_reaction_callback.is_valid():
		var cb = custom_reaction_callback
		custom_reaction_callback = Callable()
		last_custom_reaction_card_info = card_info
		cb.call(true, card_info)
		return

	var card_id = card_info.get("id", "do")
	_broadcast_player_battle_action("DODGE_RESPONSE", card_id, dodge_attacker_seat)
	_animate_showcase_card(c_name, "Bạn dùng [%s %s %s] hóa giải đòn Trảm!" % [suit_sym, rank_str, c_name])
	_add_log("🛡️ Bạn đã tự chọn dùng lá [%s %s %s] hóa giải đòn Trảm thành công!" % [suit_sym, rank_str, c_name])
	AudioManager.play_voice("Đỡ")
	AudioManager.play_parry()

	# Kiểm tra Song Cung Mường Nhạ của người tấn công
	var atk = generals_data.get(dodge_attacker_seat, {})
	if atk.get("equipped_weapon", "") == "Song Cung Mường Nhạ" and dodge_attacker_seat != my_seat and atk.get("hand_count", 0) >= 2:
		atk["hand_count"] = max(0, atk["hand_count"] - 2)
		atk["avatar_node"].update_hand_count(atk["hand_count"])
		_add_log("🏹 [Song Cung Mường Nhạ] của %s ép bạn chịu 1 sát thương!" % atk["name"])
		AudioManager.play_skill()
		_apply_damage_to_general(my_seat, 1, dodge_attacker_seat, "NORMAL")

	# Kiểm tra Trường Đao Nam Sơn của người tấn công
	if atk.get("equipped_weapon", "") == "Trường Đao Nam Sơn" and dodge_attacker_seat != my_seat:
		var has_s = false
		for idx in range(atk.get("hand_cards", []).size()):
			if "Trảm" in atk["hand_cards"][idx].get("name", ""):
				has_s = true
				atk["hand_cards"].remove_at(idx)
				atk["hand_count"] = atk["hand_cards"].size()
				atk["avatar_node"].update_hand_count(atk["hand_count"])
				break
		if has_s:
			_animate_showcase_card("Trường Đao Nam Sơn", "%s bỏ thêm 1 Trảm ép bạn phải Đỡ tiếp!" % atk["name"])
			_add_log("🗡️ [Trường Đao Nam Sơn] %s bỏ thêm 1 lá Trảm ép bạn phải Đỡ thêm lần nữa!" % atk["name"])
			await get_tree().create_timer(0.6).timeout
			_prompt_dodge_reaction(dodge_attacker_seat, incoming_slash_damage, incoming_slash_element)
			return

func _on_dodge_passed() -> void:
	if not is_waiting_dodge:
		return
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)
	selected_dodge_card_ui = null
	dodge_modal.visible = false
	is_waiting_dodge = false

	if custom_reaction_callback.is_valid():
		var cb = custom_reaction_callback
		custom_reaction_callback = Callable()
		last_custom_reaction_card_info = {}
		cb.call(false, {})
		return

	_broadcast_player_battle_action("DODGE_RESPONSE", "pass", dodge_attacker_seat)
	_apply_damage_to_general(my_seat, incoming_slash_damage, dodge_attacker_seat, incoming_slash_element)

func _prompt_custom_reaction_async(title_text: String, desc_text_msg: String, required_type: String, pass_text: String, confirm_text: String, timeout_sec: float = 15.0) -> bool:
	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = title_text
	dodge_desc_lbl.text = desc_text_msg
	dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)
	dodge_pass_btn.text = pass_text
	dodge_pass_btn.disabled = false
	dodge_confirm_btn.text = confirm_text
	dodge_confirm_btn.disabled = true

	dodge_time_left = timeout_sec
	is_waiting_dodge = true
	selected_dodge_card_ui = null

	var valid_cards: Array = []
	var my_gen = generals_data.get(my_seat, {})
	for card_ui in hand_container.get_children():
		var info = _get_card_info_from_ui(card_ui)
		var c_name = info.get("name", "").to_lower()
		if required_type == "Trảm":
			if "trảm" in c_name:
				valid_cards.append(card_ui)
			elif my_gen.get("hero_id", -1) == 47 and "đỡ" in c_name:
				valid_cards.append(card_ui)
		elif required_type == "Đỡ":
			if _is_card_valid_for_dodge(card_ui, 0):
				valid_cards.append(card_ui)

	_build_dodge_card_selector_buttons(valid_cards)

	if valid_cards.size() > 0:
		_select_dodge_card(valid_cards[0])
	else:
		_select_dodge_card(null)

	dodge_modal.visible = true

	custom_reaction_callback = func(accepted: bool, _card_info: Dictionary):
		custom_reaction_finished.emit(accepted)

	var accepted_res = await custom_reaction_finished
	return accepted_res

func _calculate_distance(seat_a: int, seat_b: int) -> int:
	var diff = abs(seat_a - seat_b)
	var d = min(diff, 4 - diff)
	if generals_data.has(seat_a) and generals_data[seat_a].get("equipped_off_horse", "") != "":
		d -= 1
	if generals_data.has(seat_b) and generals_data[seat_b].get("equipped_def_horse", "") != "":
		d += 1
	return max(1, d)

func _get_suit_icon(suit: String) -> String:
	match suit:
		"Heart": return "♥"
		"Diamond": return "♦"
		"Club": return "♣"
		"Spade": return "♠"
		_: return ""

func _format_rank(r: Variant) -> String:
	var val = int(r)
	match val:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(val)

func _apply_damage_to_general(target_seat: int, amount: int, attacker_seat: int = -1, damage_element: String = "NORMAL") -> void:
	if not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	var atk = generals_data.get(attacker_seat, {})
	var has_thuan_thien = (atk.get("equipped_weapon", "") == "Kiếm Thuận Thiên")

	# Kiểm tra Áo Bào Hoàng Tộc (giảm 1 ST, tối đa 3 lần, trừ khi bị Thuận Thiên)
	if not has_thuan_thien and tgt["equipped_armor"] == "Áo Bào Hoàng Tộc":
		tgt["ao_bao_charges"] = tgt.get("ao_bao_charges", 3)
		if tgt["ao_bao_charges"] > 0:
			tgt["ao_bao_charges"] -= 1
			amount = max(0, amount - 1)
			_add_log("🛡️ [Áo Bào Hoàng Tộc] của %s giảm 1 sát thương (Còn %d lần)." % [tgt["name"], tgt["ao_bao_charges"]])
			if tgt["ao_bao_charges"] <= 0:
				tgt["equipped_armor"] = ""
				tgt["avatar_node"].set_equipment("armor", "", "")
				_add_log("🛡️ [Áo Bào Hoàng Tộc] của %s đã hết linh lực và tan biến!" % tgt["name"])

	# Kiểm tra Thương Ngâu Lãng Bạc của người đánh
	if amount > 0 and atk.get("equipped_weapon", "") == "Thương Ngâu Lãng Bạc":
		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		_add_log("🗡️ [Thương Ngâu Lãng Bạc] của %s phá hủy 1 lá bài của %s!" % [atk.get("name", "Người đánh"), tgt["name"]])

	tgt["hp"] = max(0, tgt["hp"] - amount)
	tgt["avatar_node"].update_hp(tgt["hp"], tgt["max_hp"])
	tgt["avatar_node"].play_damage_effect()
	tgt["avatar_node"].spawn_damage_number(amount)
	AudioManager.play_damage()

	_add_log("💥 %s nhận %d sát thương! Còn (%d/%d) Máu." % [tgt["name"], amount, tgt["hp"], tgt["max_hp"]])

	# Lan truyền Xích Liên Hoàn nếu là sát thương Lôi hoặc Hỏa
	var is_elemental = (damage_element == "FIRE" or damage_element == "LIGHTNING")
	if is_elemental and tgt.get("is_chained", false) and amount > 0:
		tgt["is_chained"] = false
		if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
			tgt["avatar_node"].set_chained(false)
		for other_seat in [1, 2, 3, 4]:
			if other_seat != target_seat and generals_data.has(other_seat):
				var other = generals_data[other_seat]
				if other["is_alive"] and other.get("is_chained", false):
					other["is_chained"] = false
					if other.has("avatar_node") and is_instance_valid(other["avatar_node"]):
						other["avatar_node"].set_chained(false)
					_add_log("⛓️⚡ [XÍCH LIÊN HOÀN]: Sát thương %s (%d điểm) lan truyền sang %s và gỡ xích!" % ["Hỏa" if damage_element == "FIRE" else "Lôi", amount, other["name"]])
					_apply_damage_to_general(other_seat, amount, -1, "NORMAL")

	if tgt["hp"] <= 0:
		_prompt_near_death_check(target_seat)
	else:
		_check_victory_condition()

func _prompt_near_death_check(victim_seat: int) -> void:
	if not generals_data.has(victim_seat):
		return
	var victim = generals_data[victim_seat]
	if not victim["is_alive"]:
		return

	# Kiểm tra người chơi có thể cứu không
	var is_victim_ally = (victim["isDragon"] == my_team_is_dragon)
	var player_can_rescue = false
	var found_rescue_card_node: Control = null
	var found_rescue_card_name: String = ""

	if is_victim_ally:
		for c_node in hand_container.get_children():
			var info = _get_card_info_from_ui(c_node)
			var n = info.get("name", "")
			if n == "Bánh Chưng":
				player_can_rescue = true
				found_rescue_card_node = c_node
				found_rescue_card_name = "Bánh Chưng"
				break
			elif n == "Hủ Rượu" and victim_seat == my_seat:
				player_can_rescue = true
				found_rescue_card_node = c_node
				found_rescue_card_name = "Hủ Rượu"
				break

	if player_can_rescue:
		is_waiting_rescue = true
		rescue_victim_seat = victim_seat
		rescue_card_to_use = found_rescue_card_node
		rescue_time_left = 10.0

		var who_text = "BẠN ĐANG HẤP HỐI" if victim_seat == my_seat else ("ĐỒNG ĐỘI " + victim["name"])
		rescue_desc_lbl.text = "%s (Ghế %d) đang cận tử (%d/%d Máu)!\nBạn có muốn dùng [%s] trên tay để cứu viện không?" % [who_text, victim_seat, victim["hp"], victim["max_hp"], found_rescue_card_name]
		rescue_timer_lbl.text = "⏳ Còn lại: 10s"
		rescue_confirm_btn.text = "🍲 DÙNG [%s]" % found_rescue_card_name.to_upper()
		rescue_modal.visible = true
		_add_log("🚨 CẬN TỬ: %s đang cận tử (%d Máu)! Đang chờ cứu viện..." % [victim["name"], victim["hp"]])
		return

	# Nếu người chơi không thể cứu hoặc nạn nhân là phe địch:
	# Kiểm tra nếu nạn nhân là AI (hoặc đồng đội AI) có Bánh Chưng / Hủ Rượu để tự cứu
	if victim["isAI"]:
		var rescue_idx = -1
		var rescue_name = ""
		var rescuer_seat = victim_seat
		for idx in range(victim["hand_cards"].size()):
			var c = victim["hand_cards"][idx]
			if c.get("name", "") in ["Bánh Chưng", "Hủ Rượu"]:
				rescue_idx = idx
				rescue_name = c.get("name", "")
				rescuer_seat = victim_seat
				break

		# Đồng đội AI cùng phe có Bánh Chưng cứu không?
		if rescue_idx < 0:
			for s in [1, 2, 3, 4]:
				if s != victim_seat and generals_data.has(s):
					var ally = generals_data[s]
					if ally["is_alive"] and ally["isAI"] and ally["isDragon"] == victim["isDragon"]:
						for a_idx in range(ally["hand_cards"].size()):
							if ally["hand_cards"][a_idx].get("name", "") == "Bánh Chưng":
								rescue_idx = a_idx
								rescue_name = "Bánh Chưng"
								rescuer_seat = s
								break
						if rescue_idx >= 0:
							break

		if rescue_idx >= 0:
			var rescuer = generals_data[rescuer_seat]
			rescuer["hand_cards"].remove_at(rescue_idx)
			rescuer["hand_count"] = rescuer["hand_cards"].size()
			rescuer["avatar_node"].update_hand_count(rescuer["hand_count"])
			generals_data[victim_seat]["hp"] = 1
			generals_data[victim_seat]["avatar_node"].update_hp(1, generals_data[victim_seat]["max_hp"])
			_animate_showcase_card(rescue_name, "%s dùng [%s] cứu sống %s!" % [rescuer["name"], rescue_name, victim["name"]])
			_add_log("💮 %s đã dùng [%s] cứu sống %s thoát khỏi Cận Tử (1/%d Máu)!" % [rescuer["name"], rescue_name, victim["name"], victim["max_hp"]])
			AudioManager.play_voice(rescue_name)
			AudioManager.play_skill()
			_check_victory_condition()
			return

	# Không có ai cứu -> Tử trận
	_handle_general_death(victim_seat)
	_check_victory_condition()

func _on_rescue_confirmed() -> void:
	if not is_waiting_rescue or not generals_data.has(rescue_victim_seat):
		return
	rescue_modal.visible = false
	is_waiting_rescue = false

	var victim = generals_data[rescue_victim_seat]
	if rescue_card_to_use and is_instance_valid(rescue_card_to_use):
		var info = _get_card_info_from_ui(rescue_card_to_use)
		var c_name = info.get("name", "Bánh Chưng")
		_discard_player_card(rescue_card_to_use)
		rescue_card_to_use = null
		victim["hp"] = min(victim["max_hp"], victim["hp"] + 1)
		victim["avatar_node"].update_hp(victim["hp"], victim["max_hp"])
		_broadcast_player_battle_action("RESCUE_RESPONSE", c_name, rescue_victim_seat)
		_animate_showcase_card(c_name, "Bạn cứu sống %s (+1 Máu)!" % victim["name"])
		_add_log("💮 Bạn dùng [%s] cứu sống %s (%d/%d Máu)!" % [c_name, victim["name"], victim["hp"], victim["max_hp"]])
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()

	if victim["hp"] <= 0:
		_prompt_near_death_check(rescue_victim_seat)
	else:
		_check_victory_condition()

func _on_rescue_passed() -> void:
	if not is_waiting_rescue:
		return
	rescue_modal.visible = false
	is_waiting_rescue = false
	_broadcast_player_battle_action("RESCUE_RESPONSE", "pass", rescue_victim_seat)
	_handle_general_death(rescue_victim_seat)
	_check_victory_condition()

func _handle_general_death(seat_num: int) -> void:
	var g = generals_data[seat_num]
	g["is_alive"] = false
	g["avatar_node"].modulate = Color(0.4, 0.4, 0.4, 0.8)
	_add_log("☠️ Tướng %s (Ghế %d) đã ngã xuống trên chiến trường!" % [g["name"], seat_num])

func _check_victory_condition() -> void:
	var dragon_alive = 0
	var phoenix_alive = 0

	for s_num in [1, 2, 3, 4]:
		var g = generals_data[s_num]
		if g["is_alive"]:
			if g["isDragon"]:
				dragon_alive += 1
			else:
				phoenix_alive += 1

	if dragon_alive == 0 or phoenix_alive == 0:
		is_game_over = true
		var player_won = (my_team_is_dragon and phoenix_alive == 0) or (not my_team_is_dragon and dragon_alive == 0)
		_show_victory_defeat_modal(player_won)

func _show_victory_defeat_modal(is_win: bool) -> void:
	victory_defeat_modal.visible = true
	AudioManager.play_victory()
	if is_win:
		victory_title.text = "🎉 CHIẾN THẮNG HUY HOÀNG!"
		victory_title.add_theme_color_override("font_color", Color(1, 0.85, 0.25, 1))
		victory_desc.text = "Chúc mừng! Phe của bạn đã đại phá toàn bộ chiến tuyến của đối phương!\n\n🎁 Phần thưởng: +150 EXP • +300 Vàng • +25 Điểm Xếp Hạng"
	else:
		victory_title.text = "💀 THẤT BẠI!"
		victory_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
		victory_desc.text = "Tất cả các tướng phe bạn đã ngã xuống. Hãy rèn luyện thêm binh pháp và trở lại phục thù!\n\n🎁 Phần thưởng: +40 EXP • +50 Vàng"

func _on_return_home_clicked() -> void:
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _is_ai_controller() -> bool:
	var lowest_human_seat = 99
	for s in [1, 2, 3, 4]:
		if generals_data.has(s):
			var g = generals_data[s]
			if g.get("is_alive", false) and not g.get("isAI", false) and s < lowest_human_seat:
				lowest_human_seat = s
	return (my_seat == lowest_human_seat)

func _start_turn(seat_num: int) -> void:
	if is_game_over:
		return

	# Skip dead generals
	var g = generals_data[seat_num]
	if not g["is_alive"]:
		_next_turn()
		return

	current_turn_seat = seat_num
	slashes_used_this_turn = 0
	is_discard_phase = false
	cards_to_discard_count = 0
	_add_log("📜 [LƯỢT %d] Tướng %s (%s) bước vào lượt chiến đấu." % [seat_num, g["name"], "Phe Rồng" if g["isDragon"] else "Phe Phượng"])

	# Kích hoạt 3 dấu chấm viền chạy quanh và đồng hồ đếm ngược trên đầu avatar tướng
	for s in [1, 2, 3, 4]:
		if generals_data.has(s) and generals_data[s].has("avatar_node"):
			var is_active = (s == seat_num and generals_data[s]["is_alive"])
			generals_data[s]["avatar_node"].set_turn_active(is_active)
			generals_data[s]["avatar_node"].update_turn_timer(40)

	# GIAI ĐOẠN PHÁN XÉT (JUDGEMENT PHASE)
	# 1. Thần Sấm Báo Ứng
	if g.get("has_lightning", false):
		await _handle_lightning_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# 2. Cắt Đường Lương (Supply Shortage)
	var skip_draw_phase = false
	if g.get("has_cat_luong", false):
		skip_draw_phase = await _handle_supply_shortage_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# 3. Trầm Ảo Sa Bẫy (Acedia)
	var skip_play_phase = false
	if g.get("has_tram_ao", false):
		skip_play_phase = await _handle_acedia_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# Draw Phase
	if not skip_draw_phase:
		for k in range(2):
			var card_info = _draw_card_from_pile()
			if g["isPlayer"]:
				_add_card_to_player_hand(card_info)
			else:
				g["hand_cards"].append(card_info)
				g["hand_count"] = g["hand_cards"].size()
		g["avatar_node"].update_hand_count(g["hand_count"])
	else:
		_add_log("🌾 [CẮT ĐƯỜNG LƯƠNG] %s bị tước quyền rút 2 lá bài lượt này!" % g["name"])

	# Play Phase
	if skip_play_phase:
		_add_log("🕸️ [TRẦM ẢO SA BẪY] %s bị phong ấn, mất lượt ra bài!" % g["name"])
		await get_tree().create_timer(1.2).timeout
		_next_turn()
		return

	# PHÂN LUỒNG: NGƯỜI THẬT CỤC BỘ vs NGƯỜI THẬT TỪ XA vs BOT AI
	if g["isPlayer"]:
		# 1. Người chơi tại máy: Điều khiển tự do, 40 giây
		is_player_turn = true
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		end_turn_btn.visible = true
		card_play_btn.visible = false
		desc_text.text = "💡 Lượt của bạn: Rút 2 lá bài. Hãy chọn bài trên tay và mục tiêu để tấn công!"
	elif not g["isAI"]:
		# 2. Người thật từ xa qua mạng: Chờ đủ 40s, không để AI đánh hộ!
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - ĐANG CHỜ RA BÀI (40s)" % [g["name"], seat_num]
		desc_text.text = "⏳ Đang đợi người chơi %s suy nghĩ và ra đòn..." % g["name"]
		_execute_remote_player_turn(seat_num)
	else:
		# 3. Bot máy (AI): Chỉ Client là AI Controller (chủ phòng / lowest human seat) mới tính toán và phát sóng
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		if _is_ai_controller():
			turn_indicator.text = "🤖 Lượt của %s (Máy)..." % g["name"]
			desc_text.text = "🤖 Máy %s đang tính toán nước đi..." % g["name"]
			_execute_ai_turn(seat_num)
		else:
			turn_indicator.text = "⏳ LƯỢT %s (MÁY) - CHỜ ĐIỀU PHỐI..." % g["name"]
			desc_text.text = "⏳ Đang đồng bộ lượt máy của %s từ chủ phòng..." % g["name"]
			_execute_remote_player_turn(seat_num)

func _execute_remote_player_turn(remote_seat: int) -> void:
	var g = generals_data[remote_seat]
	remote_turn_timer = 40.0
	is_remote_turn_active = true
	remote_poll_timer = 0.0
	var room_id = ""
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		room_id = AppwriteMatchmaking.current_room.get("roomId", "")

	_add_log("👉 Đang chờ người chơi thật %s (Ghế %d) ra bài..." % [g["name"], remote_seat])

	while is_remote_turn_active and remote_turn_timer > 0.0 and not is_game_over:
		await get_tree().create_timer(0.2).timeout
		remote_turn_timer -= 0.2
		var sec = max(0, int(ceil(remote_turn_timer)))
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - %ds..." % [g["name"], remote_seat, sec]

		# Polling hành động người thật từ Appwrite
		remote_poll_timer += 0.2
		if remote_poll_timer >= 1.0 and not room_id.is_empty() and AppwriteMatchmaking:
			remote_poll_timer = 0.0
			var acts = await AppwriteMatchmaking.poll_battle_actions(room_id)
			for act in acts:
				if int(act.get("casterSeat", 0)) == remote_seat:
					var act_type = act.get("actionType", "")
					if act_type == "PLAY_CARD":
						var card_id = act.get("cardId", "tram")
						var target_seat = int(act.get("targetSeat", 0))
						_handle_remote_card_play(remote_seat, card_id, target_seat)
					elif act_type == "END_TURN":
						is_remote_turn_active = false
						break

	is_remote_turn_active = false
	if remote_turn_timer <= 0:
		_add_log("⏰ Hết 40s thời gian lượt của %s." % g["name"])
	await get_tree().create_timer(0.5).timeout
	_next_turn()

func _handle_remote_card_play(caster_seat: int, card_id: String, target_seat: int) -> void:
	if not generals_data.has(caster_seat):
		return
	var caster = generals_data[caster_seat]
	caster["hand_count"] = max(0, caster["hand_count"] - 1)
	caster["avatar_node"].update_hand_count(caster["hand_count"])

	var card_name = card_id
	var cid_lower = card_id.to_lower()
	if "banh" in cid_lower: card_name = "Bánh Chưng"
	elif "do" in cid_lower: card_name = "Đỡ"
	elif "nothan" in cid_lower: card_name = "Nỏ Thần Kim Quy"
	elif "khienmay" in cid_lower: card_name = "Khiên Mây Bện"
	elif "ruou" in cid_lower: card_name = "Hủ Rượu"
	elif "thansam" in cid_lower or "samset" in cid_lower: card_name = "Thần Sấm Báo Ứng"
	elif "xichtam" in cid_lower or "xich" in cid_lower: card_name = "Xích Tâm Tỏa"
	elif "dungbinh" in cid_lower: card_name = "Dụng Binh Như Thần"
	elif "baicoc" in cid_lower: card_name = "Bãi Cọc Ngầm"
	elif "muaten" in cid_lower: card_name = "Mưa Tên Liên Châu"
	elif "thachdau" in cid_lower: card_name = "Thách Đấu"
	elif "mokho" in cid_lower: card_name = "Mở Kho Cứu Tế"
	elif "vuonkhong" in cid_lower: card_name = "Vườn Không Nhà Trống"
	elif "dotkich" in cid_lower: card_name = "Đột Kích Trộm Lương"
	elif "dieuke" in cid_lower: card_name = "Diệu Kế Phá Mưu"
	elif "catluong" in cid_lower: card_name = "Cắt Đường Lương"
	elif "tramao" in cid_lower: card_name = "Trầm Ảo Sa Bẫy"
	elif "thuanthien" in cid_lower: card_name = "Kiếm Thuận Thiên"
	elif "songcung" in cid_lower: card_name = "Song Cung Mường Nhạ"
	elif "truongdao" in cid_lower: card_name = "Trường Đao Nam Sơn"
	elif "thuongngau" in cid_lower: card_name = "Thương Ngâu Lãng Bạc"
	elif "sungthancong" in cid_lower: card_name = "Súng Thần Công Hồ Triều"
	elif "giapdong" in cid_lower: card_name = "Giáp Đồng Sơn Vi"
	elif "aobao" in cid_lower: card_name = "Áo Bào Hoàng Tộc"
	elif "voichien" in cid_lower: card_name = "Voi Chiến Đại Việt"
	elif "nguatrang" in cid_lower: card_name = "Ngựa Trắng Thuần Nông"

	if card_name == "Bánh Chưng":
		caster["hp"] = min(caster["max_hp"], caster["hp"] + 1)
		caster["avatar_node"].update_hp(caster["hp"], caster["max_hp"])
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s dùng [Bánh Chưng] hồi 1 Máu!" % caster["name"])
		_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu." % caster["name"])
	elif card_name == "Hủ Rượu":
		caster["is_wine_buff_active"] = true
		AudioManager.play_voice("Hủ Rượu")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s uống Hủ Rượu (+1 Sát Thương)!" % caster["name"])
		_add_log("🍶 %s đã uống [Hủ Rượu]!" % caster["name"])
	elif card_name == "Thần Sấm Báo Ứng":
		caster["has_lightning"] = true
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			caster["avatar_node"].set_delayed_trick("lightning", true)
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s đặt [Thần Sấm Báo Ứng] vào khu phán xét!" % caster["name"])
		_add_log("⚡ %s đã tự gắn [Thần Sấm Báo Ứng] vào khu phán xét!" % caster["name"])
	elif card_name == "Bãi Cọc Ngầm":
		AudioManager.play_voice("Bãi Cọc Ngầm")
		AudioManager.play_skill()
		_animate_showcase_card("Bãi Cọc Ngầm", "%s phát động [Bãi Cọc Ngầm]!" % caster["name"])
		_add_log("🪵 %s phát động [Bãi Cọc Ngầm]! Toàn bộ người chơi khác phải đánh 1 Trảm." % caster["name"])
		_execute_aoe_attack(caster_seat, "Bãi Cọc Ngầm", "Trảm")
	elif card_name == "Mưa Tên Liên Châu":
		AudioManager.play_voice("Mưa Tên Liên Châu")
		AudioManager.play_skill()
		_animate_showcase_card("Mưa Tên Liên Châu", "%s phát động [Mưa Tên Liên Châu]!" % caster["name"])
		_add_log("🏹 %s phát động [Mưa Tên Liên Châu]! Toàn bộ người chơi khác phải đánh 1 Đỡ." % caster["name"])
		_execute_aoe_attack(caster_seat, "Mưa Tên Liên Châu", "Đỡ")
	elif card_name == "Thách Đấu":
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_duel = generals_data[target_seat]
			AudioManager.play_voice("Thách Đấu")
			AudioManager.play_slash()
			_animate_showcase_card("Thách Đấu", "%s thách đấu %s!" % [caster["name"], tgt_duel["name"]])
			_add_log("⚔️ %s phát động [Thách Đấu] lên %s!" % [caster["name"], tgt_duel["name"]])
			_execute_duel(caster_seat, target_seat)
	elif card_name == "Mở Kho Cứu Tế":
		AudioManager.play_voice("Mở Kho Cứu Tế")
		AudioManager.play_skill()
		_animate_showcase_card("Mở Kho Cứu Tế", "%s phát động [Mở Kho Cứu Tế]!" % caster["name"])
		_add_log("🌾 %s phát động [Mở Kho Cứu Tế]! Mở kho phát lương cho toàn bàn." % caster["name"])
		_execute_harvest(caster_seat)
	elif card_name == "Dụng Binh Như Thần":
		var draw_num = 3 if caster.get("hero_id", 0) == 68 else 2
		caster["hand_count"] += draw_num
		caster["avatar_node"].update_hand_count(caster["hand_count"])
		AudioManager.play_voice("Dụng Binh Như Thần")
		AudioManager.play_skill()
		_animate_showcase_card("Dụng Binh Như Thần", "%s dùng [Dụng Binh Như Thần] rút %d lá!" % [caster["name"], draw_num])
		_add_log("📜 %s dùng [Dụng Binh Như Thần] rút %d lá bài!" % [caster["name"], draw_num])
	elif card_name == "Đột Kích Trộm Lương":
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_d = generals_data[target_seat]
			if target_seat == my_seat and hand_container.get_child_count() > 0:
				var stolen_c = hand_container.get_child(hand_container.get_child_count() - 1)
				_discard_player_card(stolen_c)
			elif tgt_d["equipped_weapon"] != "":
				tgt_d["equipped_weapon"] = ""
				tgt_d["avatar_node"].set_equipment("weapon", "", "")
			elif tgt_d["equipped_armor"] != "":
				tgt_d["equipped_armor"] = ""
				tgt_d["avatar_node"].set_equipment("armor", "", "")
			else:
				tgt_d["hand_count"] = max(0, tgt_d["hand_count"] - 1)
				tgt_d["avatar_node"].update_hand_count(tgt_d["hand_count"])
			caster["hand_count"] += 1
			caster["avatar_node"].update_hand_count(caster["hand_count"])
			AudioManager.play_voice("Đột Kích Trộm Lương")
			AudioManager.play_skill()
			_animate_showcase_card("Đột Kích Trộm Lương", "%s cướp 1 lá của %s!" % [caster["name"], tgt_d["name"]])
			_add_log("🗡️ %s dùng [Đột Kích Trộm Lương] cướp bài của %s!" % [caster["name"], tgt_d["name"]])
	elif card_name in ["Vườn Không Nhà Trống", "Diệu Kế Phá Mưu"]:
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_v = generals_data[target_seat]
			if target_seat == my_seat and hand_container.get_child_count() > 0:
				var rem_c = hand_container.get_child(hand_container.get_child_count() - 1)
				_discard_player_card(rem_c)
			elif tgt_v["equipped_weapon"] != "":
				var old_w = tgt_v["equipped_weapon"]
				tgt_v["equipped_weapon"] = ""
				tgt_v["avatar_node"].set_equipment("weapon", "", "")
			elif tgt_v["equipped_armor"] != "":
				var old_a = tgt_v["equipped_armor"]
				tgt_v["equipped_armor"] = ""
				tgt_v["avatar_node"].set_equipment("armor", "", "")
			else:
				tgt_v["hand_count"] = max(0, tgt_v["hand_count"] - 1)
				tgt_v["avatar_node"].update_hand_count(tgt_v["hand_count"])
			AudioManager.play_voice(card_name)
			AudioManager.play_skill()
			_animate_showcase_card(card_name, "%s phá hủy 1 lá của %s!" % [caster["name"], tgt_v["name"]])
			_add_log("🌾 %s dùng [%s] phá hủy 1 lá bài của %s!" % [caster["name"], card_name, tgt_v["name"]])
	elif card_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		caster["equipped_weapon"] = card_name
		caster["avatar_node"].set_equipment("weapon", card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị vũ khí [%s]!" % [caster["name"], card_name])
		_add_log("🗡️ %s trang bị Vũ Khí: [%s]!" % [caster["name"], card_name])
	elif card_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
		caster["equipped_armor"] = card_name
		if card_name == "Áo Bào Hoàng Tộc": caster["ao_bao_charges"] = 3
		caster["avatar_node"].set_equipment("armor", card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị áo giáp [%s]!" % [caster["name"], card_name])
		_add_log("🛡️ %s trang bị Áo Giáp: [%s]!" % [caster["name"], card_name])
	elif card_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
		var slot_m = "def_horse" if card_name == "Voi Chiến Đại Việt" else "off_horse"
		caster["equipped_" + slot_m] = card_name
		caster["avatar_node"].set_equipment(slot_m, card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị [%s]!" % [caster["name"], card_name])
		_add_log("🐎 %s trang bị Chiến Mã: [%s]!" % [caster["name"], card_name])
	elif card_name == "Xích Tâm Tỏa":
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_x = generals_data[target_seat]
			tgt_x["is_chained"] = !tgt_x.get("is_chained", false)
			if tgt_x.has("avatar_node") and is_instance_valid(tgt_x["avatar_node"]):
				tgt_x["avatar_node"].set_chained(tgt_x["is_chained"])
		_animate_showcase_card(card_name, "%s dùng [Xích Tâm Tỏa]!" % caster["name"])
		_add_log("⛓️ %s dùng [Xích Tâm Tỏa]!" % caster["name"])
	elif card_name == "Cắt Đường Lương" or card_id.contains("catluong"):
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_c = generals_data[target_seat]
			tgt_c["has_cat_luong"] = true
			if tgt_c.has("avatar_node") and is_instance_valid(tgt_c["avatar_node"]):
				tgt_c["avatar_node"].set_delayed_trick("supply_shortage", true)
		AudioManager.play_voice("Cắt Đường Lương")
		AudioManager.play_skill()
		_animate_showcase_card("Cắt Đường Lương", "%s đặt [Cắt Đường Lương] lên đối thủ!" % caster["name"])
		_add_log("🌾 %s đặt [Cắt Đường Lương] vào khu phán xét của Ghế %d!" % [caster["name"], target_seat])
	elif card_name == "Trầm Ảo Sa Bẫy" or card_id.contains("tramao"):
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_t = generals_data[target_seat]
			tgt_t["has_tram_ao"] = true
			if tgt_t.has("avatar_node") and is_instance_valid(tgt_t["avatar_node"]):
				tgt_t["avatar_node"].set_delayed_trick("acedia", true)
		AudioManager.play_voice("Trầm Ảo Sa Bẫy")
		AudioManager.play_skill()
		_animate_showcase_card("Trầm Ảo Sa Bẫy", "%s đặt [Trầm Ảo Sa Bẫy] lên đối thủ!" % caster["name"])
		_add_log("🕸️ %s đặt [Trầm Ảo Sa Bẫy] vào khu phán xét của Ghế %d!" % [caster["name"], target_seat])
	elif target_seat > 0 and generals_data.has(target_seat):
		var tgt = generals_data[target_seat]
		var elem = "NORMAL"
		if "Hỏa" in card_name: elem = "FIRE"
		elif "Lôi" in card_name: elem = "LIGHTNING"
		AudioManager.play_voice(card_name if AudioManager.has_voice(card_name) else "Trảm")
		AudioManager.play_slash()
		_animate_showcase_card(card_name, "%s dùng [%s] tấn công %s!" % [caster["name"], card_name, tgt["name"]])
		_add_log("⚔️ %s dùng [%s] lên %s (Ghế %d)." % [caster["name"], card_name, tgt["name"], target_seat])
		_handle_slash_attack(caster_seat, target_seat, 1, elem)

func _execute_ai_turn(ai_seat: int) -> void:
	await get_tree().create_timer(1.0).timeout
	if is_game_over:
		return

	var ai_gen = generals_data[ai_seat]
	if not ai_gen["is_alive"]:
		_next_turn()
		return

	# 1. AI kiểm tra hồi máu bằng Bánh Chưng nếu mất máu
	if ai_gen["hp"] < ai_gen["max_hp"]:
		var bc_idx = -1
		for idx in range(ai_gen["hand_cards"].size()):
			if ai_gen["hand_cards"][idx].get("name", "") == "Bánh Chưng":
				bc_idx = idx
				break
		if bc_idx >= 0:
			ai_gen["hand_cards"].remove_at(bc_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			ai_gen["hp"] = min(ai_gen["max_hp"], ai_gen["hp"] + 1)
			ai_gen["avatar_node"].update_hp(ai_gen["hp"], ai_gen["max_hp"])
			AudioManager.play_voice("Bánh Chưng")
			AudioManager.play_skill()
			_animate_showcase_card("Bánh Chưng", "%s dùng [Bánh Chưng] hồi 1 Máu!" % ai_gen["name"])
			_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu (%d/%d)." % [ai_gen["name"], ai_gen["hp"], ai_gen["max_hp"]])
			await get_tree().create_timer(0.8).timeout

	# 2. AI trang bị Vũ Khí / Áo Giáp / Chiến Mã nếu rút trúng
	var equip_idx = -1
	for idx in range(ai_gen["hand_cards"].size()):
		var c = ai_gen["hand_cards"][idx]
		var c_name = c.get("name", "")
		if c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
			equip_idx = idx
			ai_gen["equipped_weapon"] = c_name
			ai_gen["avatar_node"].set_equipment("weapon", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị vũ khí [%s]!" % [ai_gen["name"], c_name])
			_add_log("🗡️ %s trang bị Vũ Khí: [%s]!" % [ai_gen["name"], c_name])
			break
		elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
			equip_idx = idx
			ai_gen["equipped_armor"] = c_name
			if c_name == "Áo Bào Hoàng Tộc":
				ai_gen["ao_bao_charges"] = 3
			ai_gen["avatar_node"].set_equipment("armor", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị áo giáp [%s]!" % [ai_gen["name"], c_name])
			_add_log("🛡️ %s trang bị Áo Giáp: [%s]!" % [ai_gen["name"], c_name])
			break
		elif c_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
			equip_idx = idx
			if c_name == "Voi Chiến Đại Việt":
				ai_gen["equipped_def_horse"] = c_name
				ai_gen["avatar_node"].set_equipment("def_horse", c_name, "")
			else:
				ai_gen["equipped_off_horse"] = c_name
				ai_gen["avatar_node"].set_equipment("off_horse", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị chiến mã [%s]!" % [ai_gen["name"], c_name])
			_add_log("🐎 %s trang bị Chiến Mã: [%s]!" % [ai_gen["name"], c_name])
			break

	if equip_idx >= 0:
		ai_gen["hand_cards"].remove_at(equip_idx)
		ai_gen["hand_count"] = ai_gen["hand_cards"].size()
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		AudioManager.play_skill()
		await get_tree().create_timer(0.8).timeout

	# 3. AI dùng Cẩm Nang nếu có
	var enemies = []
	for s in [1, 2, 3, 4]:
		var other = generals_data[s]
		if other["is_alive"] and other["isDragon"] != ai_gen["isDragon"]:
			enemies.append(s)

	var scroll_idx = -1
	for idx in range(ai_gen["hand_cards"].size()):
		var c = ai_gen["hand_cards"][idx]
		var c_name = c.get("name", "")

		# AI tự đặt Thần Sấm Báo Ứng vào bản thân nếu chưa có
		if c_name == "Thần Sấm Báo Ứng" and not ai_gen.get("has_lightning", false):
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			ai_gen["has_lightning"] = true
			if ai_gen.has("avatar_node") and is_instance_valid(ai_gen["avatar_node"]):
				ai_gen["avatar_node"].set_delayed_trick("lightning", true)
			AudioManager.play_voice("Thần Sấm Báo Ứng")
			AudioManager.play_skill()
			_animate_showcase_card("Thần Sấm Báo Ứng", "%s tự gắn [Thần Sấm Báo Ứng] vào khu phán xét!" % ai_gen["name"])
			_add_log("⚡ %s đã tự gắn [Thần Sấm Báo Ứng] vào khu phán xét của mình!" % ai_gen["name"])
			await get_tree().create_timer(0.8).timeout
			break

		if c_name == "Bãi Cọc Ngầm":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Bãi Cọc Ngầm")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_BaiCoc", 0, ai_seat)
			_animate_showcase_card("Bãi Cọc Ngầm", "%s dùng [Bãi Cọc Ngầm]!" % ai_gen["name"])
			_add_log("🪵 %s phát động [Bãi Cọc Ngầm]! Mọi người phải đánh Trảm hoặc mất 1 Máu." % ai_gen["name"])
			await _execute_aoe_attack(ai_seat, "Bãi Cọc Ngầm", "Trảm")
			await get_tree().create_timer(0.8).timeout
			break

		if c_name == "Mưa Tên Liên Châu":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Mưa Tên Liên Châu")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_MuaTen", 0, ai_seat)
			_animate_showcase_card("Mưa Tên Liên Châu", "%s dùng [Mưa Tên Liên Châu]!" % ai_gen["name"])
			_add_log("🏹 %s phát động [Mưa Tên Liên Châu]! Mọi người phải đánh Đỡ hoặc mất 1 Máu." % ai_gen["name"])
			await _execute_aoe_attack(ai_seat, "Mưa Tên Liên Châu", "Đỡ")
			await get_tree().create_timer(0.8).timeout
			break

		if c_name == "Thách Đấu" and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Thách Đấu")
			AudioManager.play_slash()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_ThachDau", tgt_s, ai_seat)
			_animate_showcase_card("Thách Đấu", "%s thách đấu %s!" % [ai_gen["name"], tgt_e["name"]])
			_add_log("⚔️ %s phát động [Thách Đấu] lên %s!" % [ai_gen["name"], tgt_e["name"]])
			await _execute_duel(ai_seat, tgt_s)
			await get_tree().create_timer(0.8).timeout
			break

		if c_name == "Dụng Binh Như Thần":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			var draw_num = 3 if ai_gen.get("hero_id", 0) == 68 else 2
			for k in range(draw_num):
				var card_drawn = _draw_card_from_pile()
				ai_gen["hand_cards"].append(card_drawn)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Dụng Binh Như Thần")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_DungBinh", 0, ai_seat)
			_animate_showcase_card("Dụng Binh Như Thần", "%s dùng [Dụng Binh Như Thần] rút %d lá!" % [ai_gen["name"], draw_num])
			_add_log("📜 %s thi triển [Dụng Binh Như Thần] rút ngay %d lá bài!" % [ai_gen["name"], draw_num])
			await get_tree().create_timer(0.8).timeout
			break

		if c_name == "Mở Kho Cứu Tế":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Mở Kho Cứu Tế")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_MoKho", 0, ai_seat)
			_animate_showcase_card("Mở Kho Cứu Tế", "%s dùng [Mở Kho Cứu Tế]!" % ai_gen["name"])
			_add_log("🌾 %s thi triển [Mở Kho Cứu Tế]! Mở kho phát lương cho toàn bàn." % ai_gen["name"])
			await _execute_harvest(ai_seat)
			await get_tree().create_timer(0.8).timeout
			break

		if c_name in ["Cắt Đường Lương", "Trầm Ảo Sa Bẫy"] and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			if c_name == "Cắt Đường Lương":
				tgt_e["has_cat_luong"] = true
				if tgt_e.has("avatar_node") and is_instance_valid(tgt_e["avatar_node"]):
					tgt_e["avatar_node"].set_delayed_trick("supply_shortage", true)
			else:
				tgt_e["has_tram_ao"] = true
				if tgt_e.has("avatar_node") and is_instance_valid(tgt_e["avatar_node"]):
					tgt_e["avatar_node"].set_delayed_trick("acedia", true)
			AudioManager.play_voice(c_name)
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", c_name, tgt_s, ai_seat)
			_animate_showcase_card(c_name, "%s đặt [%s] lên %s!" % [ai_gen["name"], c_name, tgt_e["name"]])
			_add_log("⏳ %s đặt Cẩm Nang Trì Hoãn [%s] vào khu phán xét của %s!" % [ai_gen["name"], c_name, tgt_e["name"]])
			await get_tree().create_timer(0.8).timeout
			break

		if c_name in ["Đột Kích Trộm Lương", "Vườn Không Nhà Trống", "Diệu Kế Phá Mưu", "Xích Tâm Tỏa"] and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])

			if c_name == "Đột Kích Trộm Lương":
				if tgt_e["isPlayer"]:
					if hand_container.get_child_count() > 0:
						var stolen_c = hand_container.get_child(hand_container.get_child_count() - 1)
						var info_s = _get_card_info_from_ui(stolen_c)
						_discard_player_card(stolen_c)
						ai_gen["hand_cards"].append(info_s)
						ai_gen["hand_count"] = ai_gen["hand_cards"].size()
						ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
				else:
					if not tgt_e["hand_cards"].is_empty():
						var stolen_c = tgt_e["hand_cards"].pop_back()
						tgt_e["hand_count"] = tgt_e["hand_cards"].size()
						tgt_e["avatar_node"].update_hand_count(tgt_e["hand_count"])
						ai_gen["hand_cards"].append(stolen_c)
						ai_gen["hand_count"] = ai_gen["hand_cards"].size()
						ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
				_animate_showcase_card(c_name, "%s dùng [Đột Kích Trộm Lương] lên %s!" % [ai_gen["name"], tgt_e["name"]])
				_add_log("🗡️ %s dùng [Đột Kích Trộm Lương] cướp bài của %s!" % [ai_gen["name"], tgt_e["name"]])

			elif c_name in ["Vườn Không Nhà Trống", "Diệu Kế Phá Mưu"]:
				if tgt_e["equipped_weapon"] != "":
					var old_w = tgt_e["equipped_weapon"]
					tgt_e["equipped_weapon"] = ""
					tgt_e["avatar_node"].set_equipment("weapon", "", "")
					_add_log("🌾 %s dùng [%s] phá hủy vũ khí [%s] của %s!" % [ai_gen["name"], c_name, old_w, tgt_e["name"]])
				elif tgt_e["equipped_armor"] != "":
					var old_a = tgt_e["equipped_armor"]
					tgt_e["equipped_armor"] = ""
					tgt_e["avatar_node"].set_equipment("armor", "", "")
					_add_log("🌾 %s dùng [%s] phá hủy giáp [%s] của %s!" % [ai_gen["name"], c_name, old_a, tgt_e["name"]])
				else:
					if tgt_e["isPlayer"] and hand_container.get_child_count() > 0:
						var c_rem = hand_container.get_child(hand_container.get_child_count() - 1)
						_discard_player_card(c_rem)
					elif not tgt_e["hand_cards"].is_empty():
						tgt_e["hand_cards"].pop_back()
						tgt_e["hand_count"] = tgt_e["hand_cards"].size()
						tgt_e["avatar_node"].update_hand_count(tgt_e["hand_count"])
					_add_log("🌾 %s dùng [%s] ép %s bỏ 1 lá bài!" % [ai_gen["name"], c_name, tgt_e["name"]])
				_animate_showcase_card(c_name, "%s dùng [%s] lên %s!" % [ai_gen["name"], c_name, tgt_e["name"]])

			elif c_name == "Xích Tâm Tỏa":
				tgt_e["is_chained"] = !tgt_e.get("is_chained", false)
				_animate_showcase_card(c_name, "%s dùng [Xích Tâm Tỏa] lên %s!" % [ai_gen["name"], tgt_e["name"]])
				_add_log("⛓️ %s dùng [Xích Tâm Tỏa] %s đối với %s!" % [ai_gen["name"], "khóa xích" if tgt_e["is_chained"] else "gỡ xích", tgt_e["name"]])

			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", c_name, tgt_s, ai_seat)
			await get_tree().create_timer(0.8).timeout
			break

	# 4. AI tấn công kẻ địch bằng Trảm
	if not enemies.is_empty():
		var slash_idx = -1
		for idx in range(ai_gen["hand_cards"].size()):
			if "Trảm" in ai_gen["hand_cards"][idx].get("name", ""):
				slash_idx = idx
				break

		if slash_idx >= 0:
			var slash_card = ai_gen["hand_cards"][slash_idx]
			ai_gen["hand_cards"].remove_at(slash_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])

			var chosen_tgt_seat = enemies.pick_random()
			for e_seat in enemies:
				if e_seat == my_seat and randf() < 0.6:
					chosen_tgt_seat = e_seat
					break

			var tgt_gen = generals_data[chosen_tgt_seat]
			var card_name = slash_card.get("name", "Trảm Thường")
			var elem = "NORMAL"
			if "Hỏa" in card_name: elem = "FIRE"
			elif "Lôi" in card_name: elem = "LIGHTNING"

			AudioManager.play_voice(card_name)
			AudioManager.play_slash()
			_broadcast_player_battle_action("PLAY_CARD", card_name, chosen_tgt_seat, ai_seat)
			_animate_showcase_card(card_name, "%s dùng [%s] tấn công %s!" % [ai_gen["name"], card_name, tgt_gen["name"]])
			_add_log("⚔️ %s (Ghế %d) dùng [%s] lên %s (Ghế %d)." % [ai_gen["name"], ai_seat, card_name, tgt_gen["name"], chosen_tgt_seat])

			var ai_slash_suit = slash_card.get("suit", "Spade")
			_handle_slash_attack(ai_seat, chosen_tgt_seat, 1, elem, ai_slash_suit)

			if chosen_tgt_seat == my_seat:
				while is_waiting_dodge and not is_game_over:
					await get_tree().create_timer(0.3).timeout
			else:
				await get_tree().create_timer(1.2).timeout

	# 5. AI Discard Phase (Bỏ bài thừa)
	var ai_hp = ai_gen["hp"]
	var ai_excess = ai_gen["hand_cards"].size() - ai_hp
	if ai_excess > 0:
		for d in range(ai_excess):
			if not ai_gen["hand_cards"].is_empty():
				ai_gen["hand_cards"].pop_back()
		ai_gen["hand_count"] = ai_gen["hand_cards"].size()
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		_animate_showcase_card("Bỏ bài thừa", "%s bỏ %d lá bài thừa!" % [ai_gen["name"], ai_excess])
		_add_log("🗑️ %s đã bỏ %d lá bài thừa (Còn %d lá = %d Máu)." % [ai_gen["name"], ai_excess, ai_hp, ai_hp])
		AudioManager.play_card_draw()
		await get_tree().create_timer(0.8).timeout

	# End AI turn
	_broadcast_player_battle_action("END_TURN", "", 0, ai_seat)
	await get_tree().create_timer(0.8).timeout
	_next_turn()

func _on_end_turn_btn_clicked() -> void:
	if not is_player_turn:
		return

	var p_gen = generals_data[my_seat]
	var current_cards = hand_container.get_child_count()
	var hp = p_gen["hp"]
	var excess = current_cards - hp

	if excess > 0:
		is_discard_phase = true
		cards_to_discard_count = excess
		end_turn_btn.visible = false
		card_play_btn.visible = true
		card_play_btn.disabled = true
		card_play_btn.text = "🗑️ BỎ %d LÁ THỪA (CHỌN BÀI)" % cards_to_discard_count
		desc_text.text = "⚠️ Giai đoạn bỏ bài: Bạn có %d lá bài nhưng chỉ còn %d Máu! Vui lòng chọn và bỏ %d lá bài thừa để kết thúc lượt." % [current_cards, hp, excess]
		_add_log("⚠️ [BỎ BÀI]: Bạn có %d lá bài nhưng chỉ còn %d Máu. Phải bỏ %d lá bài thừa để kết thúc lượt!" % [current_cards, hp, excess])
		return

	_finish_player_end_turn()

func _on_player_turn_timeout() -> void:
	var p_gen = generals_data[my_seat]
	var hp = p_gen["hp"]
	while hand_container.get_child_count() > hp and hand_container.get_child_count() > 0:
		var c_last = hand_container.get_child(hand_container.get_child_count() - 1)
		var info = _get_card_info_from_ui(c_last)
		_discard_player_card(c_last)
		_add_log("⏰ Hết giờ: Tự động bỏ lá bài thừa [%s]." % info.get("name", "Bài"))
	is_discard_phase = false
	_finish_player_end_turn()

func _finish_player_end_turn() -> void:
	is_player_turn = false
	is_discard_phase = false
	end_turn_btn.visible = false
	card_play_btn.visible = false
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_ui.set_selected(false)
		selected_card_ui = null
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
	_broadcast_player_battle_action("END_TURN", "", 0)
	_add_log("⌛ Bạn đã kết thúc lượt của mình.")
	_next_turn()

func _get_next_alive_seat(current_seat: int) -> int:
	for step in range(1, 4):
		var next_s = ((current_seat - 1 + step) % 4) + 1
		if generals_data.has(next_s) and generals_data[next_s].get("is_alive", false):
			return next_s
	return -1

func _handle_lightning_judgement(seat_num: int) -> void:
	var g = generals_data[seat_num]
	_add_log("⚡ [GIAI ĐOẠN PHÁN XÉT] %s đang mang [Thần Sấm Báo Ứng]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Thần Sấm Báo Ứng", "⚡ [Thần Sấm Báo Ứng]: Phán xét ♠2..♠9!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_icon = _get_suit_icon(j_suit)
	var rank_str = _format_rank(j_rank)

	# Điều kiện trúng sấm sét: Bích từ 2 đến 9 (♠2 .. ♠9)
	var is_hit = (j_suit == "Spade" and j_rank >= 2 and j_rank <= 9)
	if is_hit:
		g["has_lightning"] = false
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_delayed_trick("lightning", false)
		_animate_showcase_card("Sấm Sét Giáng Trần!", "⚡⚡⚡ Lật [%s %s]: SẤM SÉT ĐÁNH TRÚNG %s (-3 MÁU)!" % [suit_icon, rank_str, g["name"]])
		_add_log("⚡⚡⚡ [Thần Sấm Báo Ứng] NỔ TUNG! Lật [%s %s] (Bích 2..9) ➜ %s chịu 3 Sát Thương Lôi!" % [suit_icon, rank_str, g["name"]])
		AudioManager.play_voice("Thần Sấm Báo Ứng")
		AudioManager.play_skill()
		_apply_damage_to_general(seat_num, 3, seat_num, "LIGHTNING")
		await get_tree().create_timer(1.2).timeout
	else:
		g["has_lightning"] = false
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_delayed_trick("lightning", false)

		var next_seat = _get_next_alive_seat(seat_num)
		if next_seat > 0 and generals_data.has(next_seat):
			var next_g = generals_data[next_seat]
			next_g["has_lightning"] = true
			if next_g.has("avatar_node") and is_instance_valid(next_g["avatar_node"]):
				next_g["avatar_node"].set_delayed_trick("lightning", true)
			_animate_showcase_card("Thần Sấm An Toàn", "⚡ Phán xét [%s %s] thoát hiểm! Chuyển sang %s!" % [suit_icon, rank_str, next_g["name"]])
			_add_log("⚡ [Thần Sấm Báo Ứng] Phán xét an toàn: Lật [%s %s]. Lá Thần Sấm được truyền sang khu phán xét của %s (Ghế %d)!" % [suit_icon, rank_str, next_g["name"], next_seat])
		else:
			_add_log("⚡ [Thần Sấm Báo Ứng] Phán xét an toàn: Lật [%s %s]. Không còn tướng nhận, lá bài bị loại bỏ!" % [suit_icon, rank_str])
		await get_tree().create_timer(1.0).timeout

func _handle_supply_shortage_judgement(seat_num: int) -> bool:
	var g = generals_data[seat_num]
	_add_log("🌾 [PHÁN XÉT CẮT LƯƠNG] %s bị [Cắt Đường Lương]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Cắt Đường Lương", "🌾 Phán xét: Không phải ♣ -> Cấm rút bài!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_icon = _get_suit_icon(j_suit)
	var rank_str = _format_rank(j_rank)

	g["has_cat_luong"] = false
	if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
		g["avatar_node"].set_delayed_trick("supply_shortage", false)

	# Thoát nếu lật được chất Chuồn (Club ♣)
	var is_safe = (j_suit == "Club")
	if is_safe:
		_animate_showcase_card("Thoát Cắt Lương", "🌾 Lật [%s %s ♣]: Thoát hiểm! Được rút bài bình thường." % [suit_icon, rank_str])
		_add_log("🌾 [Cắt Đường Lương] Thoát hiểm: Lật [%s %s] (Chuồn ♣) -> %s được rút bài!" % [suit_icon, rank_str, g["name"]])
		AudioManager.play_parry()
		await get_tree().create_timer(1.0).timeout
		return false
	else:
		_animate_showcase_card("Bị Cắt Lương!", "🌾 Lật [%s %s]: CẤM RÚT BÀI LƯỢT NÀY!" % [suit_icon, rank_str])
		_add_log("🌾 [Cắt Đường Lương] Hiệu lực: Lật [%s %s] (Không phải ♣) -> %s bị tước quyền rút bài!" % [suit_icon, rank_str, g["name"]])
		AudioManager.play_voice("Cắt Đường Lương")
		AudioManager.play_skill()
		await get_tree().create_timer(1.0).timeout
		return true

func _handle_acedia_judgement(seat_num: int) -> bool:
	var g = generals_data[seat_num]
	_add_log("🕸️ [PHÁN XÉT TRẦM ẢO] %s bị [Trầm Ảo Sa Bẫy]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Trầm Ảo Sa Bẫy", "🕸️ Phán xét: Không phải ♥ -> Cấm ra bài!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_icon = _get_suit_icon(j_suit)
	var rank_str = _format_rank(j_rank)

	g["has_tram_ao"] = false
	if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
		g["avatar_node"].set_delayed_trick("acedia", false)

	# Thoát nếu lật được chất Cơ (Heart ♥)
	var is_safe = (j_suit == "Heart")
	if is_safe:
		_animate_showcase_card("Thoát Trầm Ảo", "🕸️ Lật [%s %s ♥]: Thoát bẫy! Được ra bài bình thường." % [suit_icon, rank_str])
		_add_log("🕸️ [Trầm Ảo Sa Bẫy] Thoát bẫy: Lật [%s %s] (Cơ ♥) -> %s được ra bài!" % [suit_icon, rank_str, g["name"]])
		AudioManager.play_parry()
		await get_tree().create_timer(1.0).timeout
		return false
	else:
		_animate_showcase_card("Sa Vào Trầm Ảo!", "🕸️ Lật [%s %s]: BỎ QUA GIAI ĐOẠN RA BÀI!" % [suit_icon, rank_str])
		_add_log("🕸️ [Trầm Ảo Sa Bẫy] Hiệu lực: Lật [%s %s] (Không phải ♥) -> %s mất lượt ra bài!" % [suit_icon, rank_str, g["name"]])
		AudioManager.play_voice("Trầm Ảo Sa Bẫy")
		AudioManager.play_skill()
		await get_tree().create_timer(1.0).timeout
		return true

func _next_turn() -> void:
	if is_game_over:
		return
	var next_seat = _get_next_alive_seat(current_turn_seat)
	if next_seat <= 0:
		next_seat = (current_turn_seat % 4) + 1
	_start_turn(next_seat)

func _animate_showcase_card(c_name: String, banner_text: String) -> void:
	center_showcase.visible = true
	showcase_label.text = banner_text

	for c in showcase_card_slot.get_children():
		c.queue_free()

	var card_ui = CardUIScene.instantiate()
	showcase_card_slot.add_child(card_ui)
	card_ui.setup_card_data("showcase", c_name, 1, "Spade", 0, "")

	center_showcase.modulate.a = 0.0
	center_showcase.scale = Vector2(0.5, 0.5)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(center_showcase, "modulate:a", 1.0, 0.25)
	tw.tween_property(center_showcase, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(1.6).timeout
	var tw_out = create_tween().set_parallel(true)
	tw_out.tween_property(center_showcase, "modulate:a", 0.0, 0.25)
	tw_out.tween_property(center_showcase, "scale", Vector2(0.8, 0.8), 0.25)
	await tw_out.finished
	center_showcase.visible = false

func _add_log(msg: String) -> void:
	if log_text:
		log_text.text += "\n" + msg
		log_text.scroll_to_line(log_text.get_line_count() - 1)

func _show_general_info_modal(seat_num: int) -> void:
	var g = generals_data.get(seat_num, null)
	if not g:
		return
	var is_drag = g["isDragon"]
	info_title.text = "THÔNG TIN TƯỚNG (GHẾ %d - %s)" % [seat_num, "PHE RỒNG" if is_drag else "PHE PHƯỢNG"]
	info_hero_name.text = g["name"]
	var fac_name = g["faction"]
	var fac_full = HeroDatabase.get_faction_full_name(fac_name) if HeroDatabase else fac_name
	info_hero_stats.text = "Thế Lực: %s (%s)\nMáu: %d/%d đóa sen\nBài trên tay: %d lá" % [fac_name, fac_full, g["hp"], g["max_hp"], g["hand_count"]]

	var skills = g["hero_data"].get("skills", [])
	if not skills.is_empty():
		info_skill_title.text = "Kỹ năng: %s" % skills[0].get("name", "Kỹ năng chiến đấu")
		info_skill_desc.text = skills[0].get("desc", "Chưa có thông tin kỹ năng.")
	else:
		info_skill_title.text = "Kỹ năng: DŨNG TƯỚNG"
		info_skill_desc.text = "Không có kỹ năng chủ động đặc biệt."

	general_info_modal.visible = true

func _hide_general_info_modal() -> void:
	general_info_modal.visible = false

# ==========================================================
# 🌪️ CẨM NANG DIỆN RỘNG (AOE): BÃI CỌC NGẦM & MƯA TÊN LIÊN CHÂU
# ==========================================================
func _execute_aoe_attack(caster_seat: int, aoe_name: String, required_card_name: String) -> void:
	var caster = generals_data.get(caster_seat, {})
	var caster_name = caster.get("name", "Tướng")

	var victims_order: Array = []
	for i in range(1, 4):
		var s = ((caster_seat - 1 + i) % 4) + 1
		if generals_data.has(s) and generals_data[s]["is_alive"]:
			victims_order.append(s)

	_add_log("🌪️ <b>%s</b> phát động [%s]! Lần lượt kiểm tra các tướng theo chiều kim đồng hồ..." % [caster_name, aoe_name])

	for target_seat in victims_order:
		if is_game_over:
			break
		var tgt = generals_data[target_seat]
		if not tgt["is_alive"] or tgt["hp"] <= 0:
			continue

		# 1. Kiểm tra Miễn Nhiễm Tướng đối với Bãi Cọc Ngầm (Nam Man Nhập Xâm):
		# Phạm Tu (Hero 13 - Khang Dũng), Ngô Quyền (Hero 22 - Thủy Trận), Yết Kiêu (Hero 60 - Thủy Chiến)
		if aoe_name == "Bãi Cọc Ngầm":
			var hero_id = tgt.get("hero_id", -1)
			if hero_id in [13, 22, 60]:
				var skill_reason = "Khang Dũng" if hero_id == 13 else ("Thủy Trận" if hero_id == 22 else "Thủy Chiến")
				_animate_showcase_card("Miễn Nhiễm", "%s miễn nhiễm Bãi Cọc Ngầm nhờ [%s]!" % [tgt["name"], skill_reason])
				_add_log("🛡️ [Miễn Nhiễm] %s miễn nhiễm sát thương từ [Bãi Cọc Ngầm] nhờ kỹ năng [%s]!" % [tgt["name"], skill_reason])
				await get_tree().create_timer(0.6).timeout
				continue

		# 2. Kiểm tra Khiên Mây Bện đối với Mưa Tên Liên Châu (cần Đỡ):
		if aoe_name == "Mưa Tên Liên Châu" and tgt.get("equipped_armor", "") == "Khiên Mây Bện":
			var judge_card = _draw_card_from_pile()
			var is_red = (judge_card.get("suit", "") in ["Heart", "Diamond"])
			if is_red:
				_animate_showcase_card("Khiên Mây Bện", "Khiên Mây: Phán xét ĐỎ -> Tự động Đỡ Mưa Tên!")
				_add_log("🛡️ [Khiên Mây Bện] của %s lật %s %d (ĐỎ) -> Tự động Đỡ Mưa Tên thành công!" % [tgt["name"], judge_card.get("suit", ""), judge_card.get("rank", 1)])
				AudioManager.play_parry()
				await get_tree().create_timer(0.8).timeout
				continue
			else:
				_add_log("🛡️ [Khiên Mây Bện] của %s lật %s %d (ĐEN) -> Phán xét thất bại!" % [tgt["name"], judge_card.get("suit", ""), judge_card.get("rank", 1)])
				await get_tree().create_timer(0.5).timeout

		# 3. Phản ứng: Người chơi thật
		if tgt["isPlayer"]:
			var prompt_title = "🪵 NÉ BÃI CỌC NGẦM" if aoe_name == "Bãi Cọc Ngầm" else "🏹 NÉ MƯA TÊN LIÊN CHÂU"
			var prompt_desc = "⚠️ %s vừa dùng [%s]!\nHãy chọn 1 lá [%s] để hóa giải hoặc bấm [CHỊU ĐÒN]:" % [caster_name, aoe_name, required_card_name]
			var pass_btn_txt = "💥 CHỊU ĐÒN (-1 MÁU)"
			var confirm_btn_txt = "⚔️ ĐÁNH [TRẢM] ĐỂ NÉ" if aoe_name == "Bãi Cọc Ngầm" else "🛡️ ĐÁNH [ĐỠ] ĐỂ NÉ"

			var satisfied = await _prompt_custom_reaction_async(
				prompt_title,
				prompt_desc,
				required_card_name,
				pass_btn_txt,
				confirm_btn_txt,
				15.0
			)

			if satisfied:
				_animate_showcase_card(required_card_name, "Bạn đánh 1 lá [%s] né [%s] thành công!" % [required_card_name, aoe_name])
				_add_log("🛡️ Bạn đã đánh lá [%s] né [%s] thành công!" % [required_card_name, aoe_name])
				AudioManager.play_voice(required_card_name)
				AudioManager.play_parry()
			else:
				_add_log("💥 Bạn không đánh lá [%s], chịu 1 sát thương từ [%s]!" % [required_card_name, aoe_name])
				_apply_damage_to_general(target_seat, 1, caster_seat, "NORMAL")
			await get_tree().create_timer(0.6).timeout

		# 4. Phản ứng: Bot AI
		else:
			await get_tree().create_timer(0.8).timeout
			var matched_idx = -1
			for idx in range(tgt["hand_cards"].size()):
				var c = tgt["hand_cards"][idx]
				var c_name = c.get("name", "").to_lower()
				if aoe_name == "Bãi Cọc Ngầm":
					if "trảm" in c_name:
						matched_idx = idx
						break
				else:
					if "đỡ" in c_name:
						matched_idx = idx
						break

			if matched_idx >= 0:
				var used_c = tgt["hand_cards"][matched_idx]
				tgt["hand_cards"].remove_at(matched_idx)
				tgt["hand_count"] = tgt["hand_cards"].size()
				tgt["avatar_node"].update_hand_count(tgt["hand_count"])
				_animate_showcase_card(required_card_name, "%s dùng [%s] né [%s]!" % [tgt["name"], required_card_name, aoe_name])
				_add_log("🛡️ %s đã đánh 1 lá [%s] né [%s]!" % [tgt["name"], required_card_name, aoe_name])
				AudioManager.play_voice(required_card_name)
				AudioManager.play_parry()
			else:
				_add_log("💥 %s không có lá [%s], chịu 1 sát thương từ [%s]!" % [tgt["name"], required_card_name, aoe_name])
				_apply_damage_to_general(target_seat, 1, caster_seat, "NORMAL")
			await get_tree().create_timer(0.6).timeout

# ==========================================================
# ⚔️ THÁCH ĐẤU (DUEL): ĐỐI KHÁNG 1v1 LUÂN PHIÊN ĐÁNH TRẢM
# ==========================================================
func _execute_duel(caster_seat: int, target_seat: int) -> void:
	var caster = generals_data.get(caster_seat, {})
	var target = generals_data.get(target_seat, {})
	var caster_name = caster.get("name", "Tướng")
	var target_name = target.get("name", "Tướng")

	_animate_showcase_card("Thách Đấu", "⚔️ THÁCH ĐẤU: %s ⚔️ %s!" % [caster_name, target_name])
	_add_log("⚔️ <b>THÁCH ĐẤU PHÁT ĐỘNG!</b> %s thách đấu %s! Hai bên luân phiên đánh Trảm." % [caster_name, target_name])
	AudioManager.play_voice("Thách Đấu")
	AudioManager.play_slash()

	var current_duelist = target_seat
	var other_duelist = caster_seat
	var duel_ended = false

	while not duel_ended and not is_game_over:
		var cur_gen = generals_data.get(current_duelist, {})
		var oth_gen = generals_data.get(other_duelist, {})
		if not cur_gen.get("is_alive", false) or not oth_gen.get("is_alive", false):
			break

		var played_slash = false

		if cur_gen["isPlayer"]:
			played_slash = await _prompt_custom_reaction_async(
				"⚔️ THÁCH ĐẤU ĐỐI KHÁNG",
				"⚠️ Đến lượt bạn đáp trả [TRẢM] trong Thách Đấu với %s!\nHãy chọn 1 lá Trảm hoặc bấm [NHẬN THUA]:" % oth_gen["name"],
				"Trảm",
				"❌ NHẬN THUA (-1 MÁU)",
				"⚔️ ĐÁP TRẢ [TRẢM]",
				15.0
			)
			if played_slash:
				_animate_showcase_card("Trảm", "Bạn đáp trả 1 lá [Trảm] trong Thách Đấu!")
				_add_log("⚔️ Bạn đáp trả 1 lá [Trảm] trong Thách Đấu!")
				AudioManager.play_voice("Trảm")
				AudioManager.play_slash()
		else:
			await get_tree().create_timer(0.9).timeout
			var s_idx = -1
			for idx in range(cur_gen["hand_cards"].size()):
				if "trảm" in cur_gen["hand_cards"][idx].get("name", "").to_lower():
					s_idx = idx
					break
			if s_idx >= 0:
				var s_card = cur_gen["hand_cards"][s_idx]
				cur_gen["hand_cards"].remove_at(s_idx)
				cur_gen["hand_count"] = cur_gen["hand_cards"].size()
				cur_gen["avatar_node"].update_hand_count(cur_gen["hand_count"])
				_animate_showcase_card("Trảm", "%s đáp trả [Trảm] trong Thách Đấu!" % cur_gen["name"])
				_add_log("⚔️ %s đáp trả 1 lá [Trảm] trong Thách Đấu!" % cur_gen["name"])
				AudioManager.play_voice("Trảm")
				AudioManager.play_slash()
				played_slash = true
			else:
				played_slash = false

		if played_slash:
			var temp = current_duelist
			current_duelist = other_duelist
			other_duelist = temp
			await get_tree().create_timer(0.5).timeout
		else:
			duel_ended = true
			_add_log("💥 <b>%s</b> hết Trảm đáp trả, thất bại trong Thách Đấu và mất 1 Máu!" % cur_gen["name"])
			_animate_showcase_card("Thất Bại Thách Đấu", "%s thất bại trong Thách Đấu!" % cur_gen["name"])
			_apply_damage_to_general(current_duelist, 1, other_duelist, "NORMAL")
			await get_tree().create_timer(0.6).timeout

# ==========================================================
# 🌾 MỞ KHO CỨU TẾ: CHIA ĐỀU BÀI CHO TOÀN BỘ NGƯỜI CHƠI
# ==========================================================
func _execute_harvest(caster_seat: int) -> void:
	var caster = generals_data.get(caster_seat, {})
	_animate_showcase_card("Mở Kho Cứu Tế", "Mở kho phát lương cho tất cả người chơi!")
	_add_log("🌾 <b>%s</b> thi triển [Mở Kho Cứu Tế]! Tất cả người chơi còn sống nhận được 1 lá bài." % caster.get("name", "Người chơi"))
	AudioManager.play_voice("Mở Kho Cứu Tế")
	AudioManager.play_skill()

	for i in range(0, 4):
		var s = ((caster_seat - 1 + i) % 4) + 1
		if generals_data.has(s) and generals_data[s]["is_alive"]:
			var card = _draw_card_from_pile()
			var g = generals_data[s]
			if g["isPlayer"]:
				_add_card_to_player_hand(card)
				_add_log("🌾 Bạn nhận được [%s %d %s] từ Mở Kho Cứu Tế!" % [card.get("suit", ""), card.get("rank", 1), card.get("name", "")])
			else:
				g["hand_cards"].append(card)
				g["hand_count"] = g["hand_cards"].size()
				g["avatar_node"].update_hand_count(g["hand_count"])
				_add_log("🌾 %s nhận 1 lá bài từ Mở Kho Cứu Tế." % g["name"])
			await get_tree().create_timer(0.4).timeout

# ==========================================================
# ⛓️ XÍCH TÂM TỎA: CHỌN ĐA MỤC TIÊU (TỐI ĐA 2 TƯỚNG)
# ==========================================================
func _show_iron_chain_modal() -> void:
	if not iron_chain_modal:
		return
	selected_chain_seats.clear()
	for child in iron_chain_grid.get_children():
		child.queue_free()

	for s in [1, 2, 3, 4]:
		if not generals_data.has(s):
			continue
		var g = generals_data[s]
		if not g["is_alive"]:
			continue

		var item_box = PanelContainer.new()
		item_box.custom_minimum_size = Vector2(150, 125)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.14, 0.22, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.4, 0.4, 1.0) if g.get("is_chained", false) else Color(0.83, 0.68, 0.22, 0.8)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		item_box.add_theme_stylebox_override("panel", style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		item_box.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)

		# Role label
		var role_tag = "(Bạn)" if s == my_seat else ("(Đồng Đội)" if g["isDragon"] == my_team_is_dragon else "(Đối Thủ)")
		var name_lbl = Label.new()
		name_lbl.text = "[%d] %s" % [s, g["name"]]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)

		var role_lbl = Label.new()
		role_lbl.text = role_tag
		role_lbl.add_theme_font_size_override("font_size", 10)
		role_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0) if g["isDragon"] == my_team_is_dragon else Color(1.0, 0.5, 0.5, 1.0))
		role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(role_lbl)

		var hp_lbl = Label.new()
		hp_lbl.text = "❤️ %d/%d Máu" % [g["hp"], g["max_hp"]]
		hp_lbl.add_theme_font_size_override("font_size", 10)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hp_lbl)

		var chain_lbl = Label.new()
		chain_lbl.text = "⛓️ Đang Xích" if g.get("is_chained", false) else "🔓 Tự do"
		chain_lbl.add_theme_font_size_override("font_size", 10)
		chain_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0) if g.get("is_chained", false) else Color(0.7, 0.85, 0.7, 1.0))
		chain_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(chain_lbl)

		var check_btn = Button.new()
		check_btn.text = "☐ CHỌN"
		check_btn.custom_minimum_size = Vector2(0, 26)
		check_btn.add_theme_font_size_override("font_size", 11)
		check_btn.focus_mode = Control.FOCUS_NONE
		vbox.add_child(check_btn)

		var s_target = s
		check_btn.pressed.connect(func(): _toggle_chain_selection(s_target))
		iron_chain_grid.add_child(item_box)

	_update_iron_chain_ui()
	iron_chain_modal.visible = true

func _toggle_chain_selection(s: int) -> void:
	if s in selected_chain_seats:
		selected_chain_seats.erase(s)
	else:
		if selected_chain_seats.size() >= 2:
			desc_text.text = "⚠️ Xích Tâm Tỏa chỉ được chọn tối đa 2 tướng!"
			return
		selected_chain_seats.append(s)

	AudioManager.play_card_select()
	_update_iron_chain_ui()

func _update_iron_chain_ui() -> void:
	var count = selected_chain_seats.size()
	iron_chain_status_lbl.text = "👉 Đã chọn: %d/2 tướng" % count
	iron_chain_confirm_btn.disabled = (count == 0)
	iron_chain_confirm_btn.text = "⛓️ XÁC NHẬN XÍCH (%d TƯỚNG)" % count if count > 0 else "⛓️ XÁC NHẬN XÍCH"

	var child_idx = 0
	for s in [1, 2, 3, 4]:
		if not generals_data.has(s) or not generals_data[s]["is_alive"]:
			continue
		if child_idx < iron_chain_grid.get_child_count():
			var item_box = iron_chain_grid.get_child(child_idx) as PanelContainer
			var vbox = item_box.get_child(0).get_child(0) as VBoxContainer
			var check_btn = vbox.get_child(4) as Button
			var is_sel = (s in selected_chain_seats)
			var style = item_box.get_theme_stylebox("panel") as StyleBoxFlat
			if is_sel:
				style.bg_color = Color(0.32, 0.22, 0.08, 0.98)
				style.border_color = Color(1.0, 0.9, 0.35, 1.0)
				check_btn.text = "☑ ĐÃ CHỌN"
				check_btn.modulate = Color(1.0, 0.95, 0.4)
			else:
				var is_ch = generals_data[s].get("is_chained", false)
				style.bg_color = Color(0.1, 0.14, 0.22, 0.95)
				style.border_color = Color(1.0, 0.4, 0.4, 1.0) if is_ch else Color(0.83, 0.68, 0.22, 0.8)
				check_btn.text = "☐ CHỌN"
				check_btn.modulate = Color(1, 1, 1)
		child_idx += 1

func _on_iron_chain_confirmed() -> void:
	if selected_chain_seats.is_empty():
		return
	iron_chain_modal.visible = false

	if selected_card_ui and is_instance_valid(selected_card_ui):
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
	card_play_btn.visible = false

	AudioManager.play_voice("Xích Tâm Tỏa")
	AudioManager.play_skill()
	_animate_showcase_card("Xích Tâm Tỏa", "Đổi trạng thái xích cho %d tướng!" % selected_chain_seats.size())

	for s in selected_chain_seats:
		var g = generals_data[s]
		g["is_chained"] = !g.get("is_chained", false)
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_chained(g["is_chained"])
		var act_str = "trói vào Xích Liên Hoàn" if g["is_chained"] else "gỡ Xích Liên Hoàn"
		_add_log("⛓️ Bạn dùng [Xích Tâm Tỏa] %s cho %s (Ghế %d)!" % [act_str, g["name"], s])

	_broadcast_player_battle_action("PLAY_CARD", "xichtam", selected_chain_seats[0])
	selected_chain_seats.clear()
	_reset_player_turn_timer()

func _hide_iron_chain_modal() -> void:
	iron_chain_modal.visible = false
	selected_chain_seats.clear()

# ==========================================================
# 🗡️🌾 CƯỚP / PHÁ HỦY BÀI: TỰ CHỌN BÀI ÚP HOẶC TRANG BỊ
# ==========================================================
func _show_card_pick_modal(is_steal: bool, target_seat: int) -> void:
	if not card_pick_modal or not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	card_pick_is_steal = is_steal
	card_pick_target_seat = target_seat
	selected_card_pick_option.clear()

	for c in card_pick_options_hbox.get_children():
		c.queue_free()

	if is_steal:
		card_pick_title.text = "🗡️ ĐỘT KÍCH TRỘM LƯƠNG: CƯỚP BÀI TỪ %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🗡️ XÁC NHẬN CƯỚP"
	else:
		card_pick_title.text = "🌾 VƯỜN KHÔNG NHÀ TRỐNG: PHÁ HỦY BÀI CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🌾 XÁC NHẬN PHÁ HỦY"

	card_pick_desc.text = "💡 Hãy chọn 1 lá bài úp trên tay hoặc 1 trang bị đang mặc của %s:" % tgt["name"]

	var has_options = false

	# 1. Các lá bài úp trên tay (Face-down cards)
	var hand_count = tgt["hand_count"]
	for i in range(hand_count):
		has_options = true
		var card_btn = Button.new()
		card_btn.custom_minimum_size = Vector2(90, 110)
		card_btn.focus_mode = Control.FOCUS_NONE

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.16, 0.26, 0.98)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.83, 0.68, 0.22, 0.8)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_right = 6
		style.corner_radius_bottom_left = 6
		card_btn.add_theme_stylebox_override("normal", style)
		card_btn.text = "🎴\n\nLÁ BÀI #%d" % (i + 1)
		card_btn.add_theme_font_size_override("font_size", 11)
		card_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))

		var opt = {"type": "hand", "index": i, "label": "Lá bài úp #%d" % (i + 1), "button": card_btn}
		card_btn.pressed.connect(func(): _select_card_pick_option(opt))
		card_pick_options_hbox.add_child(card_btn)

	# 2. Trang bị đang mặc
	if tgt["equipped_weapon"] != "":
		has_options = true
		var w_btn = _create_equip_pick_button("🗡️ VŨ KHÍ", tgt["equipped_weapon"], "weapon")
		card_pick_options_hbox.add_child(w_btn)

	if tgt["equipped_armor"] != "":
		has_options = true
		var a_btn = _create_equip_pick_button("🛡️ ÁO GIÁP", tgt["equipped_armor"], "armor")
		card_pick_options_hbox.add_child(a_btn)

	if tgt["equipped_def_horse"] != "":
		has_options = true
		var h_btn = _create_equip_pick_button("🐘 NGỰA THỦ", tgt["equipped_def_horse"], "def_horse")
		card_pick_options_hbox.add_child(h_btn)

	if tgt["equipped_off_horse"] != "":
		has_options = true
		var h_btn = _create_equip_pick_button("🐎 NGỰA CÔNG", tgt["equipped_off_horse"], "off_horse")
		card_pick_options_hbox.add_child(h_btn)

	if not has_options:
		desc_text.text = "ℹ️ %s không có bài trên tay hoặc trang bị nào để cướp/hủy!" % tgt["name"]
		return

	card_pick_status_lbl.text = "👉 Đang chọn: Chưa chọn lá nào"
	card_pick_confirm_btn.disabled = true
	card_pick_modal.visible = true

func _create_equip_pick_button(slot_title: String, item_name: String, equip_type: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(105, 110)
	btn.focus_mode = Control.FOCUS_NONE

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.14, 0.24, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.8, 1.0, 0.8)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", style)
	btn.text = "%s\n\n%s" % [slot_title, item_name]
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 1.0))

	var opt = {"type": equip_type, "item_name": item_name, "label": "%s: %s" % [slot_title, item_name], "button": btn}
	btn.pressed.connect(func(): _select_card_pick_option(opt))
	return btn

func _select_card_pick_option(opt: Dictionary) -> void:
	selected_card_pick_option = opt
	AudioManager.play_card_select()

	for btn in card_pick_options_hbox.get_children():
		var st = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if st:
			st.border_color = Color(0.83, 0.68, 0.22, 0.8)

	if opt.has("button") and is_instance_valid(opt["button"]):
		var active_st = opt["button"].get_theme_stylebox("normal") as StyleBoxFlat
		if active_st:
			active_st.border_color = Color(1.0, 0.95, 0.35, 1.0)

	card_pick_status_lbl.text = "👉 Đã chọn: %s" % opt.get("label", "")
	card_pick_confirm_btn.disabled = false

func _on_card_pick_confirmed() -> void:
	if selected_card_pick_option.is_empty() or card_pick_target_seat <= 0:
		return
	card_pick_modal.visible = false

	if selected_card_ui and is_instance_valid(selected_card_ui):
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
	card_play_btn.visible = false

	var tgt = generals_data[card_pick_target_seat]
	var opt = selected_card_pick_option
	var opt_type = opt.get("type", "")

	if opt_type == "hand":
		var card_idx = opt.get("index", 0)
		var stolen_card = {}
		if tgt["isAI"] and not tgt["hand_cards"].is_empty():
			if card_idx < tgt["hand_cards"].size():
				stolen_card = tgt["hand_cards"][card_idx]
				tgt["hand_cards"].remove_at(card_idx)
			else:
				stolen_card = tgt["hand_cards"].pop_back()
		else:
			stolen_card = _draw_card_from_pile()

		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])

		var c_name = stolen_card.get("name", "Bài")
		if card_pick_is_steal:
			_add_card_to_player_hand(stolen_card)
			AudioManager.play_voice("Đột Kích Trộm Lương")
			AudioManager.play_skill()
			_animate_showcase_card("Đột Kích Trộm Lương", "Cướp được [%s] từ %s!" % [c_name, tgt["name"]])
			_add_log("🗡️ Bạn đã tự chọn cướp lá bài úp #%d từ %s (đó là lá [%s])!" % [card_idx + 1, tgt["name"], c_name])
			_broadcast_player_battle_action("PLAY_CARD", "dotkich", tgt["seat"])
		else:
			AudioManager.play_voice("Vườn Không Nhà Trống")
			AudioManager.play_skill()
			_animate_showcase_card("Vườn Không Nhà Trống", "Phá hủy 1 lá bài của %s!" % tgt["name"])
			_add_log("🌾 Bạn đã tự chọn phá hủy lá bài úp #%d của %s (đó là lá [%s])!" % [card_idx + 1, tgt["name"], c_name])
			_broadcast_player_battle_action("PLAY_CARD", "vuonkhong", tgt["seat"])

	elif opt_type in ["weapon", "armor", "def_horse", "off_horse"]:
		var item_name = opt.get("item_name", "")
		match opt_type:
			"weapon":
				tgt["equipped_weapon"] = ""
				tgt["avatar_node"].set_equipment("weapon", "", "")
			"armor":
				tgt["equipped_armor"] = ""
				tgt["avatar_node"].set_equipment("armor", "", "")
			"def_horse":
				tgt["equipped_def_horse"] = ""
				tgt["avatar_node"].set_equipment("def_horse", "", "")
			"off_horse":
				tgt["equipped_off_horse"] = ""
				tgt["avatar_node"].set_equipment("off_horse", "", "")

		if card_pick_is_steal:
			var card_dict = _find_card_dict_by_name(item_name)
			_add_card_to_player_hand(card_dict)
			AudioManager.play_voice("Đột Kích Trộm Lương")
			AudioManager.play_skill()
			_animate_showcase_card("Đột Kích Trộm Lương", "Cướp trang bị [%s] từ %s!" % [item_name, tgt["name"]])
			_add_log("🗡️ Bạn đã tự chọn cướp trang bị [%s] của %s!" % [item_name, tgt["name"]])
			_broadcast_player_battle_action("PLAY_CARD", "dotkich", tgt["seat"])
		else:
			AudioManager.play_voice("Vườn Không Nhà Trống")
			AudioManager.play_skill()
			_animate_showcase_card("Vườn Không Nhà Trống", "Phá hủy trang bị [%s] của %s!" % [item_name, tgt["name"]])
			_add_log("🌾 Bạn đã tự chọn phá hủy trang bị [%s] của %s!" % [item_name, tgt["name"]])
			_broadcast_player_battle_action("PLAY_CARD", "vuonkhong", tgt["seat"])

	selected_card_pick_option.clear()
	card_pick_target_seat = -1
	_reset_player_turn_timer()

func _hide_card_pick_modal() -> void:
	card_pick_modal.visible = false
	selected_card_pick_option.clear()
	card_pick_target_seat = -1

func _find_card_dict_by_name(c_name: String) -> Dictionary:
	var deck = CardDatabase.create_deck_80()
	for c in deck:
		if c.get("name", "") == c_name:
			return c
	return {"id": "item", "name": c_name, "suit": "Club", "rank": 1, "cat": 1, "desc": c_name}
