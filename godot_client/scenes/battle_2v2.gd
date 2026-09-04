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

@onready var dodge_modal: Control = $DodgeModal
@onready var dodge_desc_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/Desc
@onready var dodge_timer_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/TimerLbl
@onready var dodge_confirm_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/DodgeBtn
@onready var dodge_pass_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/PassBtn

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
var deck_count: int = 52
var selected_card_ui: Control = null
var selected_target_seat: int = -1
var is_game_over: bool = false

# Waiting for Dodge reaction
var is_waiting_dodge: bool = false
var dodge_attacker_seat: int = -1
var dodge_time_left: float = 15.0

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
	info_close_x_btn.pressed.connect(_hide_general_info_modal)
	info_close_btn.pressed.connect(_hide_general_info_modal)
	victory_return_btn.pressed.connect(_on_return_home_clicked)

	dodge_modal.visible = false
	general_info_modal.visible = false
	victory_defeat_modal.visible = false
	center_showcase.visible = false
	card_play_btn.visible = false
	end_turn_btn.visible = false

	_init_deck()
	_init_generals_from_draft()
	_deal_initial_hands()

	_add_log("⚔️ Chào mừng đến Đấu Trường Đại Việt 2v2 (Phe Rồng vs Phe Phượng)!")

	# Start turn loop
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

func _process(delta: float) -> void:
	if is_game_over:
		return

	# Handle Player Turn Timer
	if is_player_turn:
		current_turn_timer -= delta
		var sec = max(0, int(ceil(current_turn_timer)))
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (%ds)" % sec
		if current_turn_timer <= 0:
			_on_end_turn_btn_clicked()

	# Handle Dodge Reaction Timer
	if is_waiting_dodge:
		dodge_time_left -= delta
		var sec = max(0, int(ceil(dodge_time_left)))
		dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if dodge_time_left <= 0:
			_on_dodge_passed()

func _init_deck() -> void:
	card_deck_pile.clear()
	var suits = ["Spade", "Heart", "Club", "Diamond"]
	
	# Trảm x18
	for i in range(18):
		var suit = suits[i % 4]
		var rank = (i % 10) + 2
		card_deck_pile.append({"id": "tram_%d" % i, "name": "Trảm", "suit": suit, "rank": rank, "cat": 0, "desc": "Tấn công 1 tướng địch gây 1 sát thương."})

	# Đỡ x12
	for i in range(12):
		var suit = suits[i % 4]
		var rank = (i % 9) + 2
		card_deck_pile.append({"id": "do_%d" % i, "name": "Đỡ", "suit": suit, "rank": rank, "cat": 0, "desc": "Hóa giải 1 đòn Trảm nhắm vào bản thân."})

	# Bánh Chưng x8
	for i in range(8):
		var suit = ["Heart", "Diamond"][i % 2]
		var rank = (i % 8) + 3
		card_deck_pile.append({"id": "banh_%d" % i, "name": "Bánh Chưng", "suit": suit, "rank": rank, "cat": 0, "desc": "Hồi phục 1 Máu (tối đa bằng Máu gốc)."})

	# Hủ Rượu x4
	for i in range(4):
		var suit = ["Diamond", "Club"][i % 2]
		var rank = (i % 5) + 3
		card_deck_pile.append({"id": "ruou_%d" % i, "name": "Hủ Rượu", "suit": suit, "rank": rank, "cat": 0, "desc": "Uống rượu: đòn Trảm kế tiếp gây thêm +1 sát thương."})

	# Nỏ Thần Kim Quy x2 (Vũ Khí)
	for i in range(2):
		card_deck_pile.append({"id": "nothan_%d" % i, "name": "Nỏ Thần Kim Quy", "suit": "Club", "rank": 1, "cat": 1, "desc": "Trang bị Vũ Khí: Tầm đánh 3, không giới hạn số lần Trảm trong 1 lượt."})

	# Khiên Mây Bện x2 (Áo Giáp)
	for i in range(2):
		card_deck_pile.append({"id": "khienmay_%d" % i, "name": "Khiên Mây Bện", "suit": "Spade", "rank": 2, "cat": 1, "desc": "Trang bị Giáp: Có cơ hội tự động đỡ đòn tấn công khi cần phòng thủ."})

	# Diệu Kế Phá Mưu x4 (Cẩm Nang)
	for i in range(4):
		card_deck_pile.append({"id": "dieuke_%d" % i, "name": "Diệu Kế Phá Mưu", "suit": suits[i % 4], "rank": 11, "cat": 2, "desc": "Cẩm Nang: Vô hiệu hóa hiệu ứng của một lá Cẩm Nang khác."})

	# Xích Tâm Tỏa x2 (Cẩm Nang)
	for i in range(2):
		card_deck_pile.append({"id": "xichtam_%d" % i, "name": "Xích Tâm Tỏa", "suit": "Club", "rank": 12, "cat": 2, "desc": "Cẩm Nang: Khóa xích đối phương để nhận chung sát thương thuộc tính."})

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

	# Determine my seat
	my_seat = 1
	for slot in draft:
		if slot.get("isPlayer", false) or (AuthManager and slot.get("userId", "") == AuthManager.current_user_id and AuthManager.current_user_id != ""):
			my_seat = slot.get("seatNumber", 1)
			break

	my_team_is_dragon = (my_seat == 1 or my_seat == 3)

	# Fallback default heroes if draft is empty
	var default_heroes = [
		{"id": 53, "name": "Trần Hưng Đạo", "faction": "Thời Trần", "maxHp": 4, "slug": "tran_hung_dao", "skills": [{"name": "⚡ HỊCH TƯỚNG", "desc": "Tập kích hiệu triệu ba quân."}]},
		{"id": 1, "name": "Cao Lỗ", "faction": "Âu Lạc", "maxHp": 4, "slug": "cao_lo", "skills": [{"name": "🎯 CHẾ NỎ", "desc": "Bắn nỏ thần uy lực muôn dặm."}]},
		{"id": 47, "name": "Lý Thường Kiệt", "faction": "Thời Lý", "maxHp": 4, "slug": "ly_thuong_kiet", "skills": [{"name": "📜 TIẾN THOÁI", "desc": "Công thủ vẹn toàn, biến Trảm thành Đỡ."}]},
		{"id": 14, "name": "Triệu Quang Phục", "faction": "Vạn Xuân", "maxHp": 4, "slug": "trieu_quang_phuc", "skills": [{"name": "🌫️ DẠ TRẠCH", "desc": "Ẩn mình nơi đầm lầy Dạ Trạch."}]}
	]

	# Map Unity layout:
	# Local player is ALWAYS at SeatBottomRight
	# Offset 1 (seat + 1): Top-Right
	# Offset 2 (seat + 2): Top-Left (Ally)
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
		var h_faction = hero_info.get("faction", "Đại Việt")
		var h_hp = int(hero_info.get("maxHp", hero_info.get("hp", 4)))
		
		var slug = hero_info.get("slug", "")
		if slug == "":
			var h_id_int = int(hero_info.get("id", 0))
			if HeroDatabase:
				var db_h = HeroDatabase.get_hero(h_id_int)
				if db_h and not db_h.is_empty():
					slug = db_h.get("slug", "")
		if slug == "":
			slug = str(hero_info.get("id", s_num))

		var role_str = ""
		if is_p:
			role_str = "BẠN"
		elif (is_drag and my_team_is_dragon) or (not is_drag and not my_team_is_dragon):
			role_str = "ĐỒNG ĐỘI"
		else:
			role_str = "ĐỐI THỦ"

		var avatar_node = seat_to_avatar[s_num]
		avatar_node.setup_general(slug, h_name, h_faction, h_hp, h_hp, role_str)

		# Explicitly verify portrait texture
		var tex_path = "res://assets/ui/" + slug + ".png"
		if ResourceLoader.exists(tex_path) and is_instance_valid(avatar_node.portrait_rect):
			avatar_node.portrait_rect.texture = load(tex_path)

		# Set visual team badge color
		if is_drag:
			avatar_node.set_faction_color(Color(0.2, 0.8, 1.0, 1.0))
		else:
			avatar_node.set_faction_color(Color(1.0, 0.4, 0.2, 1.0))

		# Adjust SkillBtn position so it never overflows offscreen
		var offset = seat_to_offset[s_num]
		var skill_btn = avatar_node.get_node_or_null("SkillBtn")
		if skill_btn:
			if offset == 3: # SeatMidLeft
				skill_btn.anchor_left = 1.0
				skill_btn.anchor_right = 1.0
				skill_btn.offset_left = 8.0
				skill_btn.offset_right = 108.0
				skill_btn.offset_top = -32.0
				skill_btn.offset_bottom = -2.0
			elif offset == 0: # Player Bottom-Right
				skill_btn.anchor_left = 0.0
				skill_btn.anchor_right = 0.0
				skill_btn.offset_left = -110.0
				skill_btn.offset_right = -10.0
				skill_btn.offset_top = -32.0
				skill_btn.offset_bottom = -2.0

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
			"equipped_armor": ""
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

func _on_player_hand_card_clicked(card_node: Control, c_info: Dictionary) -> void:
	if not is_player_turn or is_waiting_dodge:
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

	var c_name = c_info.get("name", "")
	var c_desc = c_info.get("desc", "")
	var suit = c_info.get("suit", "")
	var rank = c_info.get("rank", 1)
	desc_text.text = "🎴 [%s %s] %s: %s" % [suit, rank, c_name, c_desc]

	_update_action_btn()

func _on_general_avatar_clicked(seat_num: int) -> void:
	if is_game_over:
		return

	var g = generals_data.get(seat_num, null)
	if not g or not g["is_alive"]:
		return

	# Don't target self for attack
	if seat_num == my_seat and selected_card_ui:
		var c_info = _get_card_info_from_ui(selected_card_ui)
		if c_info.get("name", "") == "Trảm":
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
	if c_name == null or c_name == "":
		if ui_node.card_data:
			c_name = ui_node.card_data.card_name
	return {
		"name": c_name,
		"card_node": ui_node
	}

func _update_action_btn() -> void:
	if not is_player_turn or selected_card_ui == null:
		card_play_btn.visible = false
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")

	if c_name == "Trảm":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt["isDragon"] != my_team_is_dragon and tgt["is_alive"]:
				card_play_btn.text = "⚔️ TRẢM ➜ %s" % tgt["name"]
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
	elif c_name in ["Nỏ Thần Kim Quy", "Khiên Mây Bện"]:
		card_play_btn.text = "🛡️ TRANG BỊ [%s]" % c_name
		card_play_btn.visible = true
	elif c_name == "Diệu Kế Phá Mưu":
		card_play_btn.text = "📜 DÙNG DIỆU KẾ PHÁ MƯU"
		card_play_btn.visible = true
	else:
		card_play_btn.text = "DÙNG [%s]" % c_name
		card_play_btn.visible = true

func _on_card_play_btn_clicked() -> void:
	if not is_player_turn or selected_card_ui == null:
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")

	if c_name == "Trảm":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng đối thủ trên bàn để Trảm!"
			return
		var tgt = generals_data[selected_target_seat]
		if tgt["isDragon"] == my_team_is_dragon:
			desc_text.text = "⚠️ Không thể Trảm đồng đội của mình!"
			return

		var p_gen = generals_data[my_seat]
		var has_no_than = (p_gen["equipped_weapon"] == "Nỏ Thần Kim Quy")
		if slashes_used_this_turn >= 1 and not has_no_than:
			desc_text.text = "⚠️ Mỗi lượt chỉ được Trảm 1 lần (Trừ khi có Nỏ Thần)!"
			return

		slashes_used_this_turn += 1
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false

		_animate_showcase_card(c_name, "Bạn dùng [Trảm] tấn công %s!" % tgt["name"])
		_add_log("⚔️ Bạn dùng [Trảm] lên %s (Ghế %d)." % [tgt["name"], tgt["seat"]])

		# Check target reaction
		_handle_slash_attack(my_seat, tgt["seat"])

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
		_animate_showcase_card(c_name, "Bạn ăn Bánh Chưng hồi 1 Máu!")
		_add_log("🍲 Bạn hồi phục 1 Máu bằng [Bánh Chưng] (%d/%d)." % [p_gen["hp"], p_gen["max_hp"]])

	elif c_name == "Nỏ Thần Kim Quy":
		var p_gen = generals_data[my_seat]
		p_gen["equipped_weapon"] = c_name
		p_gen["avatar_node"].set_equipment("weapon", c_name, "♣ A")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_animate_showcase_card(c_name, "Bạn trang bị [Nỏ Thần Kim Quy]!")
		_add_log("🗡️ Bạn đã trang bị Vũ Khí: [Nỏ Thần Kim Quy] (Không giới hạn Trảm)!")

	elif c_name == "Khiên Mây Bện":
		var p_gen = generals_data[my_seat]
		p_gen["equipped_armor"] = c_name
		p_gen["avatar_node"].set_equipment("armor", c_name, "♠ 2")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_animate_showcase_card(c_name, "Bạn trang bị [Khiên Mây Bện]!")
		_add_log("🛡️ Bạn đã trang bị Áo Giáp: [Khiên Mây Bện]!")

	else:
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_animate_showcase_card(c_name, "Bạn đã dùng [%s]!" % c_name)
		_add_log("🎴 Bạn đã dùng [%s]." % c_name)

func _discard_player_card(card_node: Control) -> void:
	if not card_node or not is_instance_valid(card_node):
		return
	hand_container.remove_child(card_node)
	card_node.queue_free()
	var g = generals_data[my_seat]
	g["hand_count"] = max(0, g["hand_count"] - 1)
	g["avatar_node"].update_hand_count(g["hand_count"])

func _handle_slash_attack(attacker_seat: int, target_seat: int) -> void:
	var tgt = generals_data[target_seat]

	if tgt["isPlayer"]:
		_prompt_dodge_reaction(attacker_seat)
		return

	# Target is AI
	await get_tree().create_timer(1.2).timeout
	var ai_has_dodge = (randf() < 0.45 and tgt["hand_count"] > 0)
	if ai_has_dodge:
		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		_animate_showcase_card("Đỡ", "%s dùng [Đỡ] hóa giải đòn tấn công!" % tgt["name"])
		_add_log("🛡️ %s đã dùng [Đỡ] hóa giải đòn Trảm thành công!" % tgt["name"])
	else:
		_apply_damage_to_general(target_seat, 1, attacker_seat)

func _prompt_dodge_reaction(attacker_seat: int) -> void:
	var atk = generals_data[attacker_seat]
	dodge_attacker_seat = attacker_seat
	dodge_time_left = 15.0
	is_waiting_dodge = true

	dodge_desc_lbl.text = "%s (Ghế %d) đang dùng [Trảm] tấn công bạn! Bạn có muốn dùng lá [ĐỠ] trên tay không?" % [atk["name"], attacker_seat]
	dodge_timer_lbl.text = "⏳ Còn lại: 15s"
	
	# Check if player has Dodge card in hand
	var has_dodge = _find_card_in_hand("Đỡ") != null
	dodge_confirm_btn.disabled = not has_dodge
	if has_dodge:
		dodge_confirm_btn.text = "🛡️ DÙNG [ĐỠ]"
	else:
		dodge_confirm_btn.text = "❌ KHÔNG CÓ [ĐỠ]"

	dodge_modal.visible = true

func _find_card_in_hand(c_name: String) -> Control:
	for c in hand_container.get_children():
		var info = _get_card_info_from_ui(c)
		if info.get("name", "") == c_name:
			return c
	return null

func _on_dodge_confirmed() -> void:
	if not is_waiting_dodge:
		return
	var dodge_card = _find_card_in_hand("Đỡ")
	if dodge_card:
		_discard_player_card(dodge_card)
		dodge_modal.visible = false
		is_waiting_dodge = false
		_animate_showcase_card("Đỡ", "Bạn dùng [Đỡ] hóa giải đòn tấn công!")
		_add_log("🛡️ Bạn đã dùng [Đỡ] hóa giải đòn Trảm thành công!")
	else:
		_on_dodge_passed()

func _on_dodge_passed() -> void:
	if not is_waiting_dodge:
		return
	dodge_modal.visible = false
	is_waiting_dodge = false
	_apply_damage_to_general(my_seat, 1, dodge_attacker_seat)

func _apply_damage_to_general(target_seat: int, amount: int, _attacker_seat: int = -1) -> void:
	if not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	tgt["hp"] = max(0, tgt["hp"] - amount)
	tgt["avatar_node"].update_hp(tgt["hp"], tgt["max_hp"])
	tgt["avatar_node"].play_damage_effect()
	tgt["avatar_node"].spawn_damage_number(amount)

	_add_log("💥 %s nhận %d sát thương! Còn (%d/%d) Máu." % [tgt["name"], amount, tgt["hp"], tgt["max_hp"]])

	if tgt["hp"] <= 0:
		_handle_general_death(target_seat)

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
	_add_log("📜 [LƯỢT %d] Tướng %s (%s) bước vào lượt chiến đấu." % [seat_num, g["name"], "Phe Rồng" if g["isDragon"] else "Phe Phượng"])

	# Draw 2 cards phase
	for k in range(2):
		var card_info = _draw_card_from_pile()
		if g["isPlayer"]:
			_add_card_to_player_hand(card_info)
		else:
			g["hand_count"] += 1
	g["avatar_node"].update_hand_count(g["hand_count"])

	if g["isPlayer"]:
		is_player_turn = true
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		end_turn_btn.visible = true
		card_play_btn.visible = false
		desc_text.text = "💡 Lượt của bạn: Rút 2 lá bài. Hãy chọn bài trên tay và mục tiêu để tấn công!"
	else:
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		turn_indicator.text = "🤖 Lượt của %s..." % g["name"]
		_execute_ai_turn(seat_num)

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

		_animate_showcase_card("Trảm", "%s dùng [Trảm] tấn công %s!" % [ai_gen["name"], tgt_gen["name"]])
		_add_log("⚔️ %s (Ghế %d) dùng [Trảm] lên %s (Ghế %d)." % [ai_gen["name"], ai_seat, tgt_gen["name"], chosen_tgt_seat])

		_handle_slash_attack(ai_seat, chosen_tgt_seat)

		if chosen_tgt_seat == my_seat:
			while is_waiting_dodge and not is_game_over:
				await get_tree().create_timer(0.3).timeout
		else:
			await get_tree().create_timer(1.2).timeout

	# End AI turn
	await get_tree().create_timer(1.0).timeout
	_next_turn()

func _on_end_turn_btn_clicked() -> void:
	if not is_player_turn:
		return
	is_player_turn = false
	end_turn_btn.visible = false
	card_play_btn.visible = false
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_ui.set_selected(false)
		selected_card_ui = null
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
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
	info_title.text = "THÔNG TIN TƯỚNG (GHẾ %d - %s)" % [seat_num, "PHE RỒNG" if g["isDragon"] else "PHE PHƯỢNG"]
	info_hero_name.text = g["name"]
	info_hero_stats.text = "Phe: %s\nMáu: %d/%d\nBài trên tay: %d lá" % [g["faction"], g["hp"], g["max_hp"], g["hand_count"]]

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
