extends Control

signal clicked()
signal skill_clicked()
signal info_clicked()

@onready var portrait_rect: TextureRect = $Frame/Portrait
@onready var name_label: Label = $Frame/TopBanner/Margin/HBox/NameLabel
@onready var role_badge: Label = $Frame/TopBanner/Margin/HBox/RoleBadge
@onready var faction_badge: Label = $Frame/BottomBanner/Margin/HBox/FactionBadge
@onready var hp_box: HBoxContainer = $Frame/BottomBanner/Margin/HBox/HpBox
@onready var lotus_container: HBoxContainer = $Frame/BottomBanner/Margin/HBox/HpBox/LotusContainer
@onready var hp_text_label: Label = $Frame/BottomBanner/Margin/HBox/HpBox/HpTextLabel
@onready var hp_label: Label = $Frame/BottomBanner/Margin/HBox/HpBox/HpTextLabel
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

	_init_equipment_slots()

func _init_equipment_slots() -> void:
	if is_instance_valid(weapon_slot):
		weapon_slot.visible = true
		if is_instance_valid(weapon_label):
			weapon_label.text = "🗡️ (Trống)"
			weapon_label.modulate.a = 0.45
	if is_instance_valid(armor_slot):
		armor_slot.visible = true
		if is_instance_valid(armor_label):
			armor_label.text = "🛡️ (Trống)"
			armor_label.modulate.a = 0.45
	if is_instance_valid(defensive_mount_slot):
		defensive_mount_slot.visible = true
		if is_instance_valid(defensive_mount_label):
			defensive_mount_label.text = "🐘 (+1) Trống"
			defensive_mount_label.modulate.a = 0.45
	if is_instance_valid(offensive_mount_slot):
		offensive_mount_slot.visible = true
		if is_instance_valid(offensive_mount_label):
			offensive_mount_label.text = "🐎 (-1) Trống"
			offensive_mount_label.modulate.a = 0.45
	if is_instance_valid(treasure_slot):
		treasure_slot.visible = true
		if is_instance_valid(treasure_label):
			treasure_label.text = "👑 (Trống)"
			treasure_label.modulate.a = 0.45

func _on_avatar_clicked() -> void:
	clicked.emit()

func set_skill(skill_title: String) -> void:
	if is_instance_valid(skill_btn):
		skill_btn.text = skill_title
		skill_btn.visible = (skill_title != "")

func set_target_highlight(active: bool) -> void:
	if is_instance_valid(target_border):
		target_border.visible = active
		if active:
			var tw = target_border.create_tween().set_loops(4)
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
			if is_instance_valid(weapon_slot):
				weapon_slot.visible = true
				if is_instance_valid(weapon_label):
					if item_name != "":
						weapon_label.text = _format_equip_str("🗡️", suit_rank, item_name)
						weapon_label.modulate.a = 1.0
					else:
						weapon_label.text = "🗡️ (Trống)"
						weapon_label.modulate.a = 0.45
		"armor", "giap":
			key = "armor"
			if is_instance_valid(armor_slot):
				armor_slot.visible = true
				if is_instance_valid(armor_label):
					if item_name != "":
						armor_label.text = _format_equip_str("🛡️", suit_rank, item_name)
						armor_label.modulate.a = 1.0
					else:
						armor_label.text = "🛡️ (Trống)"
						armor_label.modulate.a = 0.45
		"defensive_mount", "mount_defense", "ngua_thu", "mount":
			key = "defensive_mount"
			if is_instance_valid(defensive_mount_slot):
				defensive_mount_slot.visible = true
				if is_instance_valid(defensive_mount_label):
					if item_name != "":
						defensive_mount_label.text = _format_equip_str("🐘 (+1)", suit_rank, item_name)
						defensive_mount_label.modulate.a = 1.0
					else:
						defensive_mount_label.text = "🐘 (+1) Trống"
						defensive_mount_label.modulate.a = 0.45
		"offensive_mount", "mount_offense", "ngua_cong":
			key = "offensive_mount"
			if is_instance_valid(offensive_mount_slot):
				offensive_mount_slot.visible = true
				if is_instance_valid(offensive_mount_label):
					if item_name != "":
						offensive_mount_label.text = _format_equip_str("🐎 (-1)", suit_rank, item_name)
						offensive_mount_label.modulate.a = 1.0
					else:
						offensive_mount_label.text = "🐎 (-1) Trống"
						offensive_mount_label.modulate.a = 0.45
		"treasure", "bao_vat":
			key = "treasure"
			if is_instance_valid(treasure_slot):
				treasure_slot.visible = true
				if is_instance_valid(treasure_label):
					if item_name != "":
						treasure_label.text = _format_equip_str("👑", suit_rank, item_name)
						treasure_label.modulate.a = 1.0
					else:
						treasure_label.text = "👑 (Trống)"
						treasure_label.modulate.a = 0.45

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
	return equipped_items.get("armor", "") != ""

func get_armor_name() -> String:
	return equipped_items.get("armor", "")

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
	if is_instance_valid(name_label):
		name_label.text = p_name
	if is_instance_valid(faction_badge):
		faction_badge.text = " %s " % p_faction
	current_hp = p_hp
	max_hp = p_max_hp

	if is_instance_valid(role_badge):
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
	if ResourceLoader.exists(tex_path) and is_instance_valid(portrait_rect):
		portrait_rect.texture = load(tex_path)

	update_hp(current_hp, max_hp)
	update_hand_count(hand_count)

const LOTUS_FULL_TEX = preload("res://assets/ui/lotus_full.png")
const LOTUS_EMPTY_TEX = preload("res://assets/ui/lotus_empty.png")

func update_hp(p_hp: int, p_max_hp: int) -> void:
	var old_hp = current_hp
	current_hp = clamp(p_hp, 0, p_max_hp)
	max_hp = p_max_hp

	if is_instance_valid(lotus_container):
		while lotus_container.get_child_count() < max_hp:
			var tr = TextureRect.new()
			tr.custom_minimum_size = Vector2(18, 18)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lotus_container.add_child(tr)

		while lotus_container.get_child_count() > max_hp:
			var c = lotus_container.get_child(lotus_container.get_child_count() - 1)
			lotus_container.remove_child(c)
			c.queue_free()

		for i in range(max_hp):
			var tr = lotus_container.get_child(i)
			if is_instance_valid(tr):
				if i < current_hp:
					tr.texture = LOTUS_FULL_TEX
					tr.modulate = Color(1, 1, 1, 1)
				else:
					tr.texture = LOTUS_EMPTY_TEX
					tr.modulate = Color(1, 1, 1, 0.75)

		# If HP changed, animate the affected lotus unit
		if old_hp != current_hp and current_hp < max_hp and current_hp >= 0:
			var anim_idx = clamp(current_hp if current_hp < old_hp else current_hp - 1, 0, max_hp - 1)
			if anim_idx < lotus_container.get_child_count():
				var anim_tr = lotus_container.get_child(anim_idx)
				if is_instance_valid(anim_tr):
					var tw = create_tween()
					tw.tween_property(anim_tr, "scale", Vector2(1.35, 1.35), 0.1).set_trans(Tween.TRANS_BACK)
					tw.tween_property(anim_tr, "scale", Vector2(1.0, 1.0), 0.15)

	if is_instance_valid(hp_text_label):
		hp_text_label.text = "(%d/%d)" % [current_hp, max_hp]

func update_hand_count(count: int) -> void:
	hand_count = count
	if is_instance_valid(hand_count_label):
		hand_count_label.text = "🎴 %d" % hand_count

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
