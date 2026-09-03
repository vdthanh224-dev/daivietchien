class_name GeneralSeatUI
extends Control

signal seat_selected(seat_num: int)

@export var seat_number: int = 1
@export var is_player: bool = false

@onready var panel: Panel = $Panel
@onready var name_lbl: Label = $Panel/Margin/VBox/Header/NameLabel
@onready var role_lbl: Label = $Panel/Margin/VBox/Header/RoleBadge
@onready var hp_container: HBoxContainer = $Panel/Margin/VBox/HPContainer
@onready var hp_text_lbl: Label = $Panel/Margin/VBox/HPContainer/HPText
@onready var hand_count_lbl: Label = $Panel/Margin/VBox/Status/HandCountLabel
@onready var timer_lbl: Label = $Panel/Margin/VBox/Status/TimerLabel
@onready var equip_weapon_lbl: Label = $Panel/Margin/VBox/Equips/Weapon
@onready var equip_armor_lbl: Label = $Panel/Margin/VBox/Equips/Armor
@onready var chain_overlay: ColorRect = $Panel/ChainOverlay

var current_hp: int = 4
var max_hp: int = 4
var is_chained: bool = false
var is_my_turn: bool = false

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	chain_overlay.visible = false
	timer_lbl.visible = false
	update_seat_display(seat_number, "Tướng", 4, 4, 4)

func update_seat_display(seat: int, general_name: String, hp: int, m_hp: int, hand_count: int) -> void:
	seat_number = seat
	current_hp = hp
	max_hp = m_hp

	name_lbl.text = general_name
	_update_role_badge()
	update_hp(hp, m_hp)
	hand_count_lbl.text = "🎴 %d lá" % hand_count

func _update_role_badge() -> void:
	if is_player:
		role_lbl.text = "BẠN"
		role_lbl.modulate = Color("#10B981") # Xanh ngọc
	elif seat_number == 3:
		role_lbl.text = "ĐỒNG ĐỘI"
		role_lbl.modulate = Color("#3B82F6") # Xanh dương
	else:
		role_lbl.text = "ĐỐI THỦ"
		role_lbl.modulate = Color("#EF4444") # Đỏ

func update_hp(hp: int, m_hp: int) -> void:
	current_hp = hp
	max_hp = m_hp
	var petal_str = ""
	for i in range(m_hp):
		if i < hp:
			petal_str += "🌸 "
		else:
			petal_str += "🥀 "
	hp_text_lbl.text = "%s (%d/%d)" % [petal_str.strip_edges(), hp, m_hp]

func set_chained(chained: bool) -> void:
	is_chained = chained
	chain_overlay.visible = chained

func set_timer(seconds: int) -> void:
	if seconds > 0:
		timer_lbl.visible = true
		timer_lbl.text = "⏳ %ds" % seconds
	else:
		timer_lbl.visible = false

func update_equipments(equips: Array) -> void:
	var weapon_name = "⚔️ Trống"
	var armor_name = "🛡️ Trống"

	for eq in equips:
		var s_type = int(eq.get("subType", -1))
		var eq_name = eq.get("name", eq.get("cardName", ""))
		if s_type == 6: # Weapon
			weapon_name = "⚔️ " + eq_name
		elif s_type == 7: # Armor
			armor_name = "🛡️ " + eq_name

	equip_weapon_lbl.text = weapon_name
	equip_armor_lbl.text = armor_name

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		seat_selected.emit(seat_number)
