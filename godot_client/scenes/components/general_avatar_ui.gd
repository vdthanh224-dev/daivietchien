extends Control

signal clicked()
signal skill_clicked()

@onready var portrait_rect: TextureRect = $Frame/Portrait
@onready var frame_rect: TextureRect = $Frame/CardFrame
@onready var name_label: Label = $Frame/NamePlaque/VBox/NameLabel
@onready var faction_badge: Label = $Frame/FactionBadge
@onready var hp_label: Label = $Frame/HpContainer/HpLabel
@onready var hand_count_label: Label = $Frame/HandBadge/HandLabel
@onready var role_badge: Label = $Frame/RoleBadge
@onready var target_border: ReferenceRect = $TargetBorder
@onready var skill_btn: Button = $SkillBtn

@onready var equip_weapon: Label = $Frame/EquipSlots/Weapon
@onready var equip_armor: Label = $Frame/EquipSlots/Armor
@onready var equip_off_mount: Label = $Frame/EquipSlots/OffMount
@onready var equip_def_mount: Label = $Frame/EquipSlots/DefMount
@onready var equip_treasure: Label = $Frame/EquipSlots/Treasure

var general_id: String = "tran_hung_dao"
var current_hp: int = 4
var max_hp: int = 4
var hand_count: int = 4

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if skill_btn:
		skill_btn.pressed.connect(func(): skill_clicked.emit())

func set_skill(skill_title: String) -> void:
	if skill_btn:
		skill_btn.text = skill_title
		skill_btn.visible = (skill_title != "")

func set_target_highlight(active: bool) -> void:
	if target_border:
		target_border.visible = active

func set_faction_color(color: Color) -> void:
	if faction_badge:
		faction_badge.modulate = color

func setup_general(p_id: String, p_name: String, p_faction: String = "Trần", p_hp: int = 4, p_max_hp: int = 4, p_role: String = "") -> void:
	general_id = p_id
	name_label.text = p_name
	faction_badge.text = p_faction
	current_hp = p_hp
	max_hp = p_max_hp

	if p_role != "":
		role_badge.visible = true
		role_badge.text = p_role
	else:
		role_badge.visible = false

	# Tải ảnh chân dung tướng nếu có
	var tex_path = "res://assets/ui/" + p_id + ".png"
	if ResourceLoader.exists(tex_path):
		portrait_rect.texture = load(tex_path)

	update_hp(current_hp, max_hp)
	update_hand_count(hand_count)

func update_hp(p_hp: int, p_max_hp: int) -> void:
	current_hp = clamp(p_hp, 0, p_max_hp)
	max_hp = p_max_hp

	var lotus = ""
	for i in range(max_hp):
		if i < current_hp:
			lotus += "🌸 "
		else:
			lotus += "⚪ "
	hp_label.text = "%s(%d/%d)" % [lotus, current_hp, max_hp]
	if current_hp <= 1:
		hp_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	else:
		hp_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func update_hand_count(count: int) -> void:
	hand_count = count
	if hand_count_label:
		hand_count_label.text = "🎴 %d" % count

func set_equipment(slot: int, card_name: String) -> void:
	match slot:
		0: equip_weapon.text = "⚔️ " + (card_name if card_name != "" else "Trống")
		1: equip_armor.text = "🛡️ " + (card_name if card_name != "" else "Trống")
		2: equip_off_mount.text = "🐎 " + (card_name if card_name != "" else "Trống")
		3: equip_def_mount.text = "🛡️🐎 " + (card_name if card_name != "" else "Trống")
		4: equip_treasure.text = "🔮 " + (card_name if card_name != "" else "Trống")

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit()

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
