extends Control

const CardResourceClass = preload("res://scripts/resources/card_resource.gd")
const CardDatabaseClass = preload("res://scripts/resources/card_database.gd")
const CardUIScene = preload("res://scenes/components/card_ui.tscn")
const GeneralSeatUIScene = preload("res://scenes/components/general_seat_ui.tscn")

@onready var opponents_container: HBoxContainer = $TableTop/OpponentsContainer
@onready var player_seat_ui: Control = $TableTop/PlayerArea/PlayerSeatUI
@onready var hand_cards_container: HBoxContainer = $TableTop/PlayerArea/HandCards
@onready var deck_pile_btn: Button = $TableTop/CenterBattleArea/Piles/DeckPileBtn
@onready var discard_pile_btn: Button = $TableTop/CenterBattleArea/Piles/DiscardPileBtn
@onready var action_panel: HBoxContainer = $ActionPanel
@onready var btn_play: Button = $ActionPanel/BtnPlay
@onready var btn_end_turn: Button = $ActionPanel/BtnEndTurn
@onready var btn_khien_may: Button = $ActionPanel/BtnKhienMay
@onready var log_label: RichTextLabel = $LogPanel/Margin/LogLabel
@onready var center_showcase: Panel = $TableTop/CenterBattleArea/CenterShowcase
@onready var center_card_lbl: Label = $TableTop/CenterBattleArea/CenterShowcase/CenterCardLabel

var seats_map: Dictionary = {} # seat_num -> Control
var selected_card_ui: Control = null
var target_seat: int = 2 # Mặc định chọn đối thủ ghế 2

func _ready() -> void:
	_setup_seats()
	_setup_signals()
	_load_demo_data()
	append_log("[color=#D4AF37][b]Chào mừng bạn đến với ĐẠI VIỆT CHIẾN (Godot 4 Prototype)![/b][/color]")
	center_showcase.visible = false

	if "--screenshot" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		await get_tree().process_frame
		var img = get_viewport().get_texture().get_image()
		img.save_png("res://screenshot.png")
		print("[Screenshot] Đã lưu screenshot.png!")
		get_tree().quit()

func _setup_seats() -> void:
	# Ghế 1: BẠN
	seats_map[1] = player_seat_ui
	player_seat_ui.is_player = true
	player_seat_ui.seat_number = 1
	player_seat_ui.update_seat_display(1, "Trần Hưng Đạo", 4, 4, 4)
	player_seat_ui.seat_selected.connect(_on_seat_clicked)

	# Ghế 2, 3, 4: Opponents & Teammate
	var seat_names = { 2: "Đào Hãn (Đối thủ)", 3: "Trần Khánh Dư (Đồng đội)", 4: "Ô Mã Nhi (Đối thủ)" }
	for s in [2, 3, 4]:
		var seat_ui = GeneralSeatUIScene.instantiate()
		seat_ui.seat_number = s
		seat_ui.is_player = false
		opponents_container.add_child(seat_ui)
		seats_map[s] = seat_ui
		seat_ui.update_seat_display(s, seat_names[s], 4, 4, 4)
		seat_ui.seat_selected.connect(_on_seat_clicked)

func _setup_signals() -> void:
	btn_play.pressed.connect(_on_play_card_pressed)
	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	btn_khien_may.pressed.connect(_on_khien_may_pressed)

	NetworkClient.game_state_updated.connect(_on_game_state_updated)
	NetworkClient.action_received.connect(_on_action_received)
	NetworkClient.log_received.connect(append_log)

func _load_demo_data() -> void:
	# Tạo sẵn các lá bài mẫu phong cách Đại Việt để test bàn đấu ngay
	var sample_cards = [
		{ "id": "D_S_1_Tram", "name": "Trảm Thường", "suit": "Spade", "rank": 1, "category": 0, "subType": 0, "desc": "Tấn công gây 1 sát thương" },
		{ "id": "D_D_2_Do", "name": "Đỡ", "suit": "Diamond", "rank": 2, "category": 0, "subType": 3, "desc": "Hóa giải 1 đòn Trảm" },
		{ "id": "D_H_3_Banh", "name": "Bánh Chưng", "suit": "Heart", "rank": 3, "category": 0, "subType": 4, "desc": "Hồi phục 1 Máu" },
		{ "id": "D_D_K_KhienMay", "name": "Khiên Mây Bện", "suit": "Diamond", "rank": 13, "category": 1, "subType": 7, "desc": "Phán xét Đỏ tự động Đỡ" },
		{ "id": "D_C_1_NoThan", "name": "Nỏ Thần Kim Quy", "suit": "Club", "rank": 1, "category": 1, "subType": 6, "desc": "Tầm 3. Bắn Trảm không giới hạn" }
	]

	for c_data in sample_cards:
		var c_res = CardDatabaseClass.create_card_from_dict(c_data)
		add_card_to_hand(c_res)

func add_card_to_hand(card_res: Resource) -> void:
	var card_ui = CardUIScene.instantiate()
	hand_cards_container.add_child(card_ui)
	card_ui.update_card(card_res)
	card_ui.card_clicked.connect(_on_card_clicked)

func _on_card_clicked(card_ui: Control) -> void:
	if selected_card_ui == card_ui and not card_ui.is_selected:
		selected_card_ui = null
		btn_play.disabled = true
		return

	# Bỏ chọn thẻ cũ
	if selected_card_ui and selected_card_ui != card_ui:
		selected_card_ui.set_selected(false)

	selected_card_ui = card_ui
	btn_play.disabled = (selected_card_ui == null)
	if selected_card_ui:
		append_log("Đã chọn: [color=#D4AF37]<b>%s</b>[/color] (%s). Nhấn [Đánh Bài] để dùng!" % [selected_card_ui.card_data.card_name, selected_card_ui.card_data.get_rank_string()])

func _on_seat_clicked(seat_num: int) -> void:
	target_seat = seat_num
	append_log("Đã chọn mục tiêu: Ghế %d" % seat_num)

func _on_play_card_pressed() -> void:
	if not selected_card_ui:
		return

	var card = selected_card_ui.card_data
	append_log("⚔️ Bạn xuất chiêu: [color=#D4AF37]<b>[%s]</b>[/color] nhắm vào Ghế %d!" % [card.card_name, target_seat])

	# Hiển thị bài ra giữa bàn
	_show_card_at_center(card)

	# Gửi lên Server nếu có kết nối
	if NetworkClient.is_connected_to_server:
		NetworkClient.send_play_card(card.id, target_seat)

	# Xóa bài khỏi tay
	selected_card_ui.queue_free()
	selected_card_ui = null
	btn_play.disabled = true

func _on_end_turn_pressed() -> void:
	append_log("🛑 Bạn đã bấm kết thúc lượt.")
	if NetworkClient.is_connected_to_server:
		NetworkClient.send_end_turn()

func _on_khien_may_pressed() -> void:
	append_log("🛡️ [Khiên Mây Bện]: Đang lật phán xét...")
	# Giả lập lật phán xét ngẫu nhiên
	var is_red = (randi() % 2 == 0)
	if is_red:
		append_log("🛡️ [Khiên Mây Bện]: [color=#10B981]<b>✔ THÀNH CÔNG (CHẤT ĐỎ)! Tự động hóa giải đòn đánh!</b>[/color]")
	else:
		append_log("🛡️ [Khiên Mây Bện]: [color=#EF4444]<b>✖ THẤT BẠI (CHẤT ĐEN)! Vui lòng đánh Đỡ trên tay.</b>[/color]")

	if NetworkClient.is_connected_to_server:
		NetworkClient.send_respond_action(true, "KHIEN_MAY")

func _show_card_at_center(card: Resource) -> void:
	center_showcase.visible = true
	center_card_lbl.text = "%s %s\n%s" % [card.get_suit_symbol(), card.get_rank_string(), card.card_name]
	center_card_lbl.modulate = card.get_suit_color()

	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	center_showcase.scale = Vector2(0.5, 0.5)
	tween.tween_property(center_showcase, "scale", Vector2(1.0, 1.0), 0.25)
	tween.tween_interval(1.5)
	tween.tween_property(center_showcase, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		center_showcase.visible = false
		center_showcase.modulate.a = 1.0
	)

func _on_game_state_updated(state: Dictionary) -> void:
	var players = state.get("players", [])
	for p in players:
		var s = int(p.get("seat", 0))
		if seats_map.has(s):
			var seat_ui = seats_map[s]
			var g_name = p.get("generalName", "Tướng")
			var hp = int(p.get("hp", 4))
			var max_hp = int(p.get("maxHp", 4))
			var hand_count = int(p.get("handCount", 4))
			seat_ui.update_seat_display(s, g_name, hp, max_hp, hand_count)
			seat_ui.set_chained(bool(p.get("isChained", false)))
			if p.has("equipments"):
				seat_ui.update_equipments(p["equipments"])

func _on_action_received(delta: Dictionary) -> void:
	var desc = delta.get("description", "")
	if desc != "":
		append_log(desc)

func append_log(text: String) -> void:
	var bb = text.replace("<color=", "[color=").replace("</color>", "[/color]")
	bb = bb.replace("<b>", "[b]").replace("</b>", "[/b]")
	log_label.append_text(bb + "\n")
