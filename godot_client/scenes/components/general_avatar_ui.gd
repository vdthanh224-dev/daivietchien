extends Control

signal clicked()
signal skill_clicked()
signal info_clicked()

@onready var portrait_rect: TextureRect = $Frame/Portrait
@onready var name_label: Label = $Frame/TopBanner/Margin/HBox/NameLabel
@onready var role_badge: Label = $Frame/TopBanner/Margin/HBox/RoleBadge
@onready var faction_badge: Label = $Frame/BottomBanner/Margin/HBox/FactionBadge
@onready var hp_label: Label = $Frame/BottomBanner/Margin/HBox/HpLabel
@onready var hand_count_label: Label = $Frame/HandBadge/HandLabel
@onready var target_border: ReferenceRect = $TargetBorder
@onready var skill_btn: Button = $SkillBtn
@onready var click_btn: Button = $ClickBtn
@onready var info_btn: Button = $InfoBtn

@onready var weapon_slot = $Frame/EquipContainer/WeaponSlot
@onready var weapon_label = $Frame/EquipContainer/WeaponSlot/Label
@onready var armor_slot = $Frame/EquipContainer/ArmorSlot
@onready var armor_label = $Frame/EquipContainer/ArmorSlot/Label
@onready var defensive_mount_slot = $Frame/EquipContainer/DefensiveMountSlot
@onready var defensive_mount_label = $Frame/EquipContainer/DefensiveMountSlot/Label
@onready var offensive_mount_slot = $Frame/EquipContainer/OffensiveMountSlot
@onready var offensive_mount_label = $Frame/EquipContainer/OffensiveMountSlot/Label
@onready var treasure_slot = $Frame/EquipContainer/TreasureSlot
@onready var treasure_label = $Frame/EquipContainer/TreasureSlot/Label

var general_id: String = "tran_hung_dao"
var current_hp: int = 4
var max_hp: int = 4
var hand_count: int = 4
var equipped_items: Dictionary = {
	"weapon": "",
	"armor": "",
	"defensive_mount": "",
	"offensive_mount": "",
	"treasure": ""
}

func _ready() -> void:
	if click_btn:
		click_btn.pressed.connect(_on_avatar_clicked)
		click_btn.mouse_entered.connect(_on_mouse_entered)
		click_btn.mouse_exited.connect(_on_mouse_exited)

	if skill_btn:
		skill_btn.pressed.connect(func(): skill_clicked.emit())

	if info_btn:
		info_btn.pressed.connect(func():
			info_clicked.emit()
		)

func _on_avatar_clicked() -> void:
	clicked.emit()

func set_skill(skill_title: String) -> void:
	if skill_btn:
		skill_btn.text = skill_title
		skill_btn.visible = (skill_title != "")

func set_target_highlight(active: bool) -> void:
	if target_border:
		target_border.visible = active
		if active:
			var tw = create_tween().set_loops(4)
			tw.tween_property(target_border, "border_color", Color(1, 1, 0.5, 1), 0.2)
			tw.tween_property(target_border, "border_color", Color(1, 0.7, 0.1, 1), 0.2)

func _format_equip_str(icon: String, suit_rank: String, item_name: String) -> String:
	var sr = suit_rank.strip_edges()
	var iname = item_name.strip_edges()
	if sr != "":
		return "%s %s %s" % [icon, sr, iname]
	else:
		return "%s %s" % [icon, iname]

func set_equipment(slot_type: String, item_name: String, suit_rank: String = "") -> void:
	var key = ""
	match slot_type.to_lower():
		"weapon", "vu_khi":
			key = "weapon"
			if weapon_slot:
				weapon_slot.visible = (item_name != "")
				weapon_label.text = _format_equip_str("🗡️", suit_rank, item_name)
		"armor", "giap":
			key = "armor"
			if armor_slot:
				armor_slot.visible = (item_name != "")
				armor_label.text = _format_equip_str("🛡️", suit_rank, item_name)
		"defensive_mount", "mount_defense", "ngua_thu", "mount":
			key = "defensive_mount"
			if defensive_mount_slot:
				defensive_mount_slot.visible = (item_name != "")
				defensive_mount_label.text = _format_equip_str("🐘 (+1)", suit_rank, item_name)
		"offensive_mount", "mount_offense", "ngua_cong":
			key = "offensive_mount"
			if offensive_mount_slot:
				offensive_mount_slot.visible = (item_name != "")
				offensive_mount_label.text = _format_equip_str("🐎 (-1)", suit_rank, item_name)
		"treasure", "bao_vat":
			key = "treasure"
			if treasure_slot:
				treasure_slot.visible = (item_name != "")
				treasure_label.text = _format_equip_str("👑", suit_rank, item_name)

	if key != "":
		if item_name != "":
			var sr = suit_rank.strip_edges()
			var iname = item_name.strip_edges()
			if sr != "":
				equipped_items[key] = "%s %s" % [sr, iname]
			else:
				equipped_items[key] = iname
		else:
			equipped_items[key] = ""

func has_armor() -> bool:
	return armor_slot != null and armor_slot.visible

func get_armor_name() -> String:
	return armor_label.text if has_armor() else ""

func play_damage_effect() -> void:
	var orig_pos = position
	var tw = create_tween()
	tw.tween_property(portrait_rect, "modulate", Color(2.2, 0.35, 0.35, 1.0), 0.08)
	tw.tween_property(portrait_rect, "modulate", Color.WHITE, 0.25)

	var shake_tw = create_tween()
	shake_tw.tween_property(self, "position:x", orig_pos.x - 10.0, 0.05)
	shake_tw.tween_property(self, "position:x", orig_pos.x + 10.0, 0.05)
	shake_tw.tween_property(self, "position:x", orig_pos.x - 5.0, 0.05)
	shake_tw.tween_property(self, "position:x", orig_pos.x, 0.05)

func spawn_damage_number(amount: int) -> void:
	var lbl = Label.new()
	lbl.text = "-%d 🌸" % amount
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	lbl.position = Vector2(size.x * 0.5 - 32, size.y * 0.5 - 25)
	lbl.z_index = 50
	add_child(lbl)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(lbl.queue_free)

func set_faction_color(color: Color) -> void:
	if faction_badge:
		faction_badge.modulate = color

func setup_general(p_id: String, p_name: String, p_faction: String = "Trần", p_hp: int = 4, p_max_hp: int = 4, p_role: String = "") -> void:
	general_id = p_id
	name_label.text = p_name
	faction_badge.text = " %s " % p_faction
	current_hp = p_hp
	max_hp = p_max_hp

	if p_role != "":
		role_badge.visible = true
		role_badge.text = " %s " % p_role
		if p_role == "BẠN":
			role_badge.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1.0))
		else:
			role_badge.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0))
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

func update_hand_count(count: int) -> void:
	hand_count = count
	if hand_count_label:
		hand_count_label.text = "🎴 %d" % hand_count

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
