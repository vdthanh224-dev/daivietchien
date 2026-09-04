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

# Remote Player State (Real Human Player on other machine)
var is_remote_turn_active: bool = false
var remote_turn_timer: float = 40.0
var remote_poll_timer: float = 0.0

# Waiting for Dodge reaction
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

	dodge_modal.visible = false
	rescue_modal.visible = false
	general_info_modal.visible = false
	victory_defeat_modal.visible = false
	center_showcase.visible = false
	card_play_btn.visible = false
	end_turn_btn.visible = false

	_start_ambient_effects()
	_init_deck()
	_init_generals_from_draft()
	_deal_initial_hands()

	_add_log("⚔️ Đấu Trường Đại Việt 2v2: Phe Rồng ([1], [3]) vs Phe Phượng ([2], [4])!")
	_add_log("📜 Thứ tự ra bài: Ghế 1 ➔ Ghế 2 ➔ Ghế 3 ➔ Ghế 4.")

	# Bắt đầu trận chiến tại Ghế 1 (Lượt 1 - Phe Rồng)
	_start_turn(1)

	# Handle headless screenshot test
	var cmd_args = OS.get_cmdline_user_args()
	if cmd_args.is_empty():
		cmd_args = OS.get_cmdline_args()
	if "--screenshot-battle-2v2" in cmd_args:
		await get_tree().create_timer(1.2).timeout
		var img = get_viewport().get_texture().get_image()
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
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://battle_2v2_dodge_screenshot.png")
		print("[Screenshot] Đã lưu battle_2v2_dodge_screenshot.png!")
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
	elif AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary and AppwriteMatchmaking.current_room.get("draft_slots", []).size() == 4:
		draft = AppwriteMatchmaking.current_room["draft_slots"]

	# Xác định ghế của người chơi tại máy
	my_seat = 1
	for slot in draft:
		if slot.get("isPlayer", false) or (AuthManager and slot.get("userId", "") == AuthManager.current_user_id and AuthManager.current_user_id != ""):
			my_seat = slot.get("seatNumber", 1)
			break

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
		var is_ai = slot_data.get("isAI", not is_p)
		
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
			"is_alive": true,
			"hero_data": hero_info,
			"avatar_node": avatar_node,
			"equipped_weapon": "",
			"equipped_armor": "",
			"is_chained": false,
			"ao_bao_charges": 0
		}

func _deal_initial_hands() -> void:
	for s_num in [1, 2, 3, 4]:
		var g = generals_data[s_num]
		for k in range(4):
			var card_info = _draw_card_from_pile()
			if g["isPlayer"]:
				_add_card_to_player_hand(card_info)
			else:
				g["hand_count"] += 1
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

	desc_text.text = "🎴 [%s %s] %s: %s" % [suit, rank, c_name, c_desc]

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
		card_play_btn.text = "⛓️ DÙNG XÍCH TÂM TỎA"
		card_play_btn.visible = true
	elif c_name == "Diệu Kế Phá Mưu":
		card_play_btn.text = "📜 DÙNG DIỆU KẾ PHÁ MƯU"
		card_play_btn.visible = true
	elif c_name == "Vườn Không Nhà Trống":
		card_play_btn.text = "🌾 DÙNG VƯỜN KHÔNG NHÀ TRỐNG"
		card_play_btn.visible = true
	elif c_name == "Đột Kích Trộm Lương":
		card_play_btn.text = "🗡️ DÙNG ĐỘT KÍCH TRỘM LƯƠNG"
		card_play_btn.visible = true
	else:
		card_play_btn.text = "DÙNG [%s]" % c_name
		card_play_btn.visible = true

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
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "ruou", my_seat)
		_animate_showcase_card(c_name, "Bạn uống Hủ Rượu (+1 Sát Thương)!")
		_add_log("🍶 Bạn đã uống [Hủ Rượu], đòn Trảm kế tiếp được +1 Sát Thương!")

	elif c_name == "Xích Tâm Tỏa":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		var tgt_seat = selected_target_seat if (selected_target_seat > 0 and generals_data.has(selected_target_seat)) else my_seat
		var tgt = generals_data[tgt_seat]
		tgt["is_chained"] = !tgt["is_chained"]
		var chain_desc = "⛓️ Trói Xích Liên Hoàn" if tgt["is_chained"] else "🔓 Gỡ Xích Liên Hoàn"
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "xichtam", tgt_seat)
		_animate_showcase_card(c_name, "%s lên %s!" % [chain_desc, tgt["name"]])
		_add_log("⛓️ Bạn dùng [Xích Tâm Tỏa] %s đối với %s (Ghế %d)!" % [chain_desc, tgt["name"], tgt_seat])

	elif c_name == "Dụng Binh Như Thần":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		for k in range(2):
			var c_draw = _draw_card_from_pile()
			_add_card_to_player_hand(c_draw)
		_broadcast_player_battle_action("PLAY_CARD", "dungbinh", my_seat)
		_animate_showcase_card(c_name, "Rút ngay 2 lá bài!")
		_add_log("📜 Bạn thi triển [Dụng Binh Như Thần], rút ngay 2 lá bài từ xấp bài!")

	elif c_name == "Đột Kích Trộm Lương":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ để cướp bài!"
			return
		var tgt = generals_data[selected_target_seat]
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		var stolen = _draw_card_from_pile()
		_add_card_to_player_hand(stolen)
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", "dotkich", tgt["seat"])
		_animate_showcase_card(c_name, "Cướp 1 lá bài từ %s!" % tgt["name"])
		_add_log("🗡️ Bạn dùng [Đột Kích Trộm Lương] cướp 1 lá bài từ %s!" % tgt["name"])

	elif c_name == "Vườn Không Nhà Trống":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng mục tiêu để phá hủy bài!"
			return
		var tgt = generals_data[selected_target_seat]
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		if tgt["equipped_weapon"] != "":
			var old_w = tgt["equipped_weapon"]
			tgt["equipped_weapon"] = ""
			tgt["avatar_node"].set_equipment("weapon", "", "")
			_add_log("🌾 Bạn dùng [Vườn Không Nhà Trống] phá hủy vũ khí [%s] của %s!" % [old_w, tgt["name"]])
		elif tgt["equipped_armor"] != "":
			var old_a = tgt["equipped_armor"]
			tgt["equipped_armor"] = ""
			tgt["avatar_node"].set_equipment("armor", "", "")
			_add_log("🌾 Bạn dùng [Vườn Không Nhà Trống] phá hủy giáp [%s] của %s!" % [old_a, tgt["name"]])
		else:
			tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
			tgt["avatar_node"].update_hand_count(tgt["hand_count"])
			_add_log("🌾 Bạn dùng [Vườn Không Nhà Trống] ép %s bỏ 1 lá bài trên tay!" % tgt["name"])
		_broadcast_player_battle_action("PLAY_CARD", "vuonkhong", tgt["seat"])
		_animate_showcase_card(c_name, "Phá hủy bài của %s!" % tgt["name"])

	elif c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		var p_gen = generals_data[my_seat]
		p_gen["equipped_weapon"] = c_name
		p_gen["avatar_node"].set_equipment("weapon", c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
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
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn trang bị [%s]!" % c_name)
		_add_log("🛡️ Bạn đã trang bị Áo Giáp: [%s]!" % c_name)

	elif c_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
		var p_gen = generals_data[my_seat]
		var slot_type = "def_horse" if c_name == "Voi Chiến Đại Việt" else "off_horse"
		p_gen["avatar_node"].set_equipment(slot_type, c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, my_seat)
		_animate_showcase_card(c_name, "Bạn cưỡi [%s]!" % c_name)
		_add_log("🐎 Bạn đã trang bị Chiến Mã: [%s]!" % c_name)

	else:
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_name, 0)
		_animate_showcase_card(c_name, "Bạn đã dùng [%s]!" % c_name)
		_add_log("🎴 Bạn đã dùng [%s]." % c_name)

func _broadcast_player_battle_action(act_type: String, card_id: String, target_seat: int = 0) -> void:
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		var r_id = AppwriteMatchmaking.current_room.get("roomId", "")
		if not r_id.is_empty():
			AppwriteMatchmaking.send_battle_action({
				"roomId": r_id,
				"casterSeat": my_seat,
				"targetSeat": target_seat,
				"actionType": act_type,
				"cardId": card_id,
				"senderUserId": AuthManager.current_user_id if AuthManager else ""
			})

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
	var ai_has_dodge = (randf() < 0.45 and tgt["hand_count"] > 0)
	if ai_has_dodge:
		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		_animate_showcase_card("Đỡ", "%s dùng [Đỡ] hóa giải đòn tấn công!" % tgt["name"])
		_add_log("🛡️ %s đã dùng [Đỡ] hóa giải đòn Trảm thành công!" % tgt["name"])
		AudioManager.play_voice("Đỡ")
		AudioManager.play_parry()

		# Kiểm tra Song Cung Mường Nhạ của người tấn công
		if atk.get("equipped_weapon", "") == "Song Cung Mường Nhạ" and attacker_seat == my_seat and hand_container.get_child_count() >= 2:
			_add_log("🏹 [Song Cung Mường Nhạ] của bạn ép %s chịu 1 sát thương!" % tgt["name"])
			AudioManager.play_skill()
			_apply_damage_to_general(target_seat, 1, attacker_seat, "NORMAL")
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

	dodge_desc_lbl.text = "%s (Ghế %d) đang dùng [Trảm] tấn công bạn!\nHãy CHỌN một lá bài trên tay để Đỡ:" % [atk["name"], attacker_seat]
	dodge_timer_lbl.text = "⏳ Còn lại: 15s"

	var valid_cards = _get_valid_dodge_cards(attacker_seat)
	_build_dodge_card_selector_buttons(valid_cards)

	if valid_cards.size() > 0:
		_select_dodge_card(valid_cards[0])
		desc_text.text = "🛡️ Bị Trảm! Nhấp lá bài trên tay hoặc các nút ở trên để đổi lá Đỡ bạn muốn dùng."
	else:
		_select_dodge_card(null)

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
		dodge_confirm_btn.text = "❌ KHÔNG CÓ [ĐỠ]"
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "❌ Bạn không có lá bài nào có thể dùng để Đỡ!"
		desc_text.text = "💥 Bạn không có lá Đỡ nào trên tay! Bấm [CHỊU ĐÒN] hoặc đợi hết giờ."
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
	var c_name = info.get("name", "Đỡ")

	dodge_confirm_btn.disabled = false
	dodge_confirm_btn.text = "🛡️ DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name]
	if dodge_selected_lbl:
		dodge_selected_lbl.text = "👉 Đang chọn: %s %s [%s]" % [suit_sym, rank_str, c_name]
	desc_text.text = "🛡️ Đã chọn lá [%s %s %s] để Đỡ đòn Trảm! Bấm nút để xác nhận hoặc nhấp lá khác trên tay." % [suit_sym, rank_str, c_name]

	_update_dodge_card_selector_buttons()

func _on_dodge_confirmed() -> void:
	if not is_waiting_dodge:
		return
	if not selected_dodge_card_ui or not is_instance_valid(selected_dodge_card_ui):
		_on_dodge_passed()
		return

	var chosen_card = selected_dodge_card_ui
	var card_info = _get_card_info_from_ui(chosen_card)
	var c_name = card_info.get("name", "Đỡ")
	var suit_sym = _get_suit_icon(card_info.get("suit", ""))
	var rank_str = _format_rank(card_info.get("rank", 1))

	if chosen_card.has_method("set_selected"):
		chosen_card.set_selected(false)
	_discard_player_card(chosen_card)
	selected_dodge_card_ui = null

	dodge_modal.visible = false
	is_waiting_dodge = false

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

func _on_dodge_passed() -> void:
	if not is_waiting_dodge:
		return
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)
	selected_dodge_card_ui = null
	dodge_modal.visible = false
	is_waiting_dodge = false
	_broadcast_player_battle_action("DODGE_RESPONSE", "pass", dodge_attacker_seat)
	_apply_damage_to_general(my_seat, incoming_slash_damage, dodge_attacker_seat, incoming_slash_element)

func _calculate_distance(seat_a: int, seat_b: int) -> int:
	var diff = abs(seat_a - seat_b)
	return min(diff, 4 - diff)

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
		for other_seat in [1, 2, 3, 4]:
			if other_seat != target_seat and generals_data.has(other_seat):
				var other = generals_data[other_seat]
				if other["is_alive"] and other.get("is_chained", false):
					other["is_chained"] = false
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
	# Kiểm tra nếu nạn nhân là AI (hoặc đồng đội AI) có tự cứu không
	if victim["isAI"] and victim["hand_count"] > 0 and randf() < 0.65:
		victim["hand_count"] = max(0, victim["hand_count"] - 1)
		victim["avatar_node"].update_hand_count(victim["hand_count"])
		victim["hp"] = 1
		victim["avatar_node"].update_hp(victim["hp"], victim["max_hp"])
		_animate_showcase_card("Bánh Chưng", "%s dùng [Bánh Chưng] thoát chết!" % victim["name"])
		_add_log("💮 %s đã dùng [Bánh Chưng] thoát khỏi trạng thái Cận Tử (1/%d Máu)!" % [victim["name"], victim["max_hp"]])
		AudioManager.play_voice("Bánh Chưng")
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

	# Draw 2 cards phase
	for k in range(2):
		var card_info = _draw_card_from_pile()
		if g["isPlayer"]:
			_add_card_to_player_hand(card_info)
		else:
			g["hand_count"] += 1
	g["avatar_node"].update_hand_count(g["hand_count"])

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
		# 3. Bot máy (AI): Tự động tính toán xuất bài
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		turn_indicator.text = "🤖 Lượt của %s (Máy)..." % g["name"]
		desc_text.text = "🤖 Máy %s đang tính toán nước đi..." % g["name"]
		_execute_ai_turn(seat_num)

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
	var caster = generals_data[caster_seat]
	caster["hand_count"] = max(0, caster["hand_count"] - 1)
	caster["avatar_node"].update_hand_count(caster["hand_count"])

	var card_name = "Trảm"
	if card_id.contains("banh"): card_name = "Bánh Chưng"
	elif card_id.contains("do"): card_name = "Đỡ"
	elif card_id.contains("nothan"): card_name = "Nỏ Thần Kim Quy"
	elif card_id.contains("khienmay"): card_name = "Khiên Mây Bện"

	if card_name == "Bánh Chưng":
		caster["hp"] = min(caster["max_hp"], caster["hp"] + 1)
		caster["avatar_node"].update_hp(caster["hp"], caster["max_hp"])
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s dùng [Bánh Chưng] hồi 1 Máu!" % caster["name"])
		_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu." % caster["name"])
	elif target_seat > 0 and generals_data.has(target_seat):
		var tgt = generals_data[target_seat]
		AudioManager.play_voice(card_name)
		AudioManager.play_slash()
		_animate_showcase_card(card_name, "%s dùng [%s] tấn công %s!" % [caster["name"], card_name, tgt["name"]])
		_add_log("⚔️ %s dùng [%s] lên %s (Ghế %d)." % [caster["name"], card_name, tgt["name"], target_seat])
		_handle_slash_attack(caster_seat, target_seat)

func _execute_ai_turn(ai_seat: int) -> void:
	await get_tree().create_timer(1.2).timeout
	if is_game_over:
		return

	var ai_gen = generals_data[ai_seat]
	if not ai_gen["is_alive"]:
		_next_turn()
		return

	# 1. AI check healing if low HP
	if ai_gen["hp"] < ai_gen["max_hp"] and randf() < 0.4 and ai_gen["hand_count"] > 1:
		ai_gen["hand_count"] = max(0, ai_gen["hand_count"] - 1)
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		ai_gen["hp"] = min(ai_gen["max_hp"], ai_gen["hp"] + 1)
		ai_gen["avatar_node"].update_hp(ai_gen["hp"], ai_gen["max_hp"])
		AudioManager.play_voice("Bánh Chưng")
		AudioManager.play_skill()
		_animate_showcase_card("Bánh Chưng", "%s dùng [Bánh Chưng] hồi 1 Máu!" % ai_gen["name"])
		_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu (%d/%d)." % [ai_gen["name"], ai_gen["hp"], ai_gen["max_hp"]])
		await get_tree().create_timer(1.0).timeout

	# 2. AI attack enemy
	var enemies = []
	for s in [1, 2, 3, 4]:
		var other = generals_data[s]
		if other["is_alive"] and other["isDragon"] != ai_gen["isDragon"]:
			enemies.append(s)

	if not enemies.is_empty() and randf() < 0.75 and ai_gen["hand_count"] > 0:
		var chosen_tgt_seat = enemies.pick_random()
		for e_seat in enemies:
			if e_seat == my_seat and randf() < 0.6:
				chosen_tgt_seat = e_seat
				break

		var tgt_gen = generals_data[chosen_tgt_seat]
		ai_gen["hand_count"] = max(0, ai_gen["hand_count"] - 1)
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])

		AudioManager.play_voice("Trảm")
		AudioManager.play_slash()
		_animate_showcase_card("Trảm", "%s dùng [Trảm] tấn công %s!" % [ai_gen["name"], tgt_gen["name"]])
		_add_log("⚔️ %s (Ghế %d) dùng [Trảm] lên %s (Ghế %d)." % [ai_gen["name"], ai_seat, tgt_gen["name"], chosen_tgt_seat])

		var ai_slash_suit = ["Spade", "Heart", "Club", "Diamond"].pick_random()
		_handle_slash_attack(ai_seat, chosen_tgt_seat, 1, "NORMAL", ai_slash_suit)

		if chosen_tgt_seat == my_seat:
			while is_waiting_dodge and not is_game_over:
				await get_tree().create_timer(0.3).timeout
		else:
			await get_tree().create_timer(1.2).timeout

	# 3. AI Discard Phase (Bỏ bài thừa)
	var ai_hp = ai_gen["hp"]
	var ai_excess = ai_gen["hand_count"] - ai_hp
	if ai_excess > 0:
		ai_gen["hand_count"] = ai_hp
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		_animate_showcase_card("Bỏ bài thừa", "%s bỏ %d lá bài thừa!" % [ai_gen["name"], ai_excess])
		_add_log("🗑️ %s đã bỏ %d lá bài thừa (Còn %d lá = %d Máu)." % [ai_gen["name"], ai_excess, ai_hp, ai_hp])
		AudioManager.play_card_draw()
		await get_tree().create_timer(0.8).timeout

	# End AI turn
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

func _next_turn() -> void:
	if is_game_over:
		return
	var next_seat = (current_turn_seat % 4) + 1
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
