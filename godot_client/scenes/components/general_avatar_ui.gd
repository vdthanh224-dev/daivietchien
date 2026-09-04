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

var is_turn_active: bool = false
var turn_border_timer: float = 0.0
var turn_dots: Array = []
var turn_dots_container: Control = null
var turn_timer_badge: PanelContainer = null
var turn_timer_label: Label = null
var is_chained: bool = false
var chain_badge: PanelContainer = null
var lightning_badge: PanelContainer = null
var delayed_tricks_container: HBoxContainer = null
var active_delayed_tricks: Dictionary = {}

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
	_build_turn_indicators()

func _build_turn_indicators() -> void:
	# 1. Container cho 3 dấu chấm chạy quanh border
	turn_dots_container = Control.new()
	turn_dots_container.set_anchors_preset(PRESET_FULL_RECT)
	turn_dots_container.mouse_filter = MOUSE_FILTER_IGNORE
	turn_dots_container.z_index = 25
	turn_dots_container.visible = false
	add_child(turn_dots_container)

	# 3 dấu chấm vàng hoàng gia rực rỡ (glowing royal gold dots)
	for i in range(3):
		var dot = Panel.new()
		var d_size = 11.0
		dot.custom_minimum_size = Vector2(d_size, d_size)
		dot.size = Vector2(d_size, d_size)
		dot.mouse_filter = MOUSE_FILTER_IGNORE

		var dot_style = StyleBoxFlat.new()
		dot_style.bg_color = Color(1.0, 0.96, 0.45, 1.0)
		dot_style.border_width_left = 1
		dot_style.border_width_top = 1
		dot_style.border_width_right = 1
		dot_style.border_width_bottom = 1
		dot_style.border_color = Color(1.0, 1.0, 0.85, 1.0)
		dot_style.corner_radius_top_left = 6
		dot_style.corner_radius_top_right = 6
		dot_style.corner_radius_bottom_right = 6
		dot_style.corner_radius_bottom_left = 6
		dot_style.shadow_color = Color(1.0, 0.85, 0.25, 0.95)
		dot_style.shadow_size = 7
		dot.add_theme_stylebox_override("panel", dot_style)

		turn_dots_container.add_child(dot)
		turn_dots.append(dot)

	# 2. Đồng hồ đếm ngược đặt ngay trên đầu avatar
	turn_timer_badge = PanelContainer.new()
	turn_timer_badge.custom_minimum_size = Vector2(76, 24)
	turn_timer_badge.mouse_filter = MOUSE_FILTER_IGNORE
	turn_timer_badge.z_index = 30
	turn_timer_badge.visible = false

	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.11, 0.18, 0.95)
	badge_style.border_width_left = 1
	badge_style.border_width_top = 1
	badge_style.border_width_right = 1
	badge_style.border_width_bottom = 1
	badge_style.border_color = Color(1.0, 0.85, 0.3, 1.0)
	badge_style.corner_radius_top_left = 12
	badge_style.corner_radius_top_right = 12
	badge_style.corner_radius_bottom_right = 12
	badge_style.corner_radius_bottom_left = 12
	badge_style.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	badge_style.shadow_size = 5
	badge_style.shadow_offset = Vector2(0, 2)
	turn_timer_badge.add_theme_stylebox_override("panel", badge_style)

	turn_timer_label = Label.new()
	turn_timer_label.text = "⏳ 40s"
	turn_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_timer_label.add_theme_font_size_override("font_size", 11)
	turn_timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))
	turn_timer_badge.add_child(turn_timer_label)

	turn_timer_badge.position = Vector2((size.x - 76) * 0.5, -28)
	add_child(turn_timer_badge)

func _process(delta: float) -> void:
	if not is_turn_active:
		return

	if turn_timer_badge:
		turn_timer_badge.position = Vector2((size.x - 76) * 0.5, -28)

	turn_border_timer += delta * 0.75
	var w = size.x
	var h = size.y
	var perimeter = 2.0 * (w + h)
	var d_size = 11.0

	for i in range(turn_dots.size()):
		var dot = turn_dots[i]
		var t = fposmod(turn_border_timer + float(i) / float(turn_dots.size()), 1.0)
		var dist = t * perimeter
		var px = 0.0
		var py = 0.0

		if dist < w:
			# Cạnh trên: trái -> phải
			px = dist
			py = 0.0
		elif dist < w + h:
			# Cạnh phải: trên -> dưới
			px = w
			py = dist - w
		elif dist < 2.0 * w + h:
			# Cạnh dưới: phải -> trái
			px = w - (dist - (w + h))
			py = h
		else:
			# Cạnh trái: dưới -> trên
			px = 0.0
			py = h - (dist - (2.0 * w + h))

		dot.position = Vector2(px - d_size * 0.5, py - d_size * 0.5)

func set_turn_active(active: bool) -> void:
	is_turn_active = active
	if turn_dots_container:
		turn_dots_container.visible = active
	if turn_timer_badge:
		turn_timer_badge.visible = active

func update_turn_timer(seconds_left: int) -> void:
	if turn_timer_label:
		turn_timer_label.text = "⏳ %ds" % max(0, seconds_left)
		if seconds_left <= 5:
			turn_timer_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
		else:
			turn_timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))

func set_chained(chained: bool) -> void:
	is_chained = chained
	if chained:
		if not chain_badge:
			chain_badge = PanelContainer.new()
			chain_badge.custom_minimum_size = Vector2(104, 22)
			chain_badge.mouse_filter = MOUSE_FILTER_IGNORE
			chain_badge.z_index = 20
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.25, 0.08, 0.06, 0.95)
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.border_color = Color(1.0, 0.45, 0.35, 1.0)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			style.shadow_color = Color(0.8, 0.2, 0.1, 0.6)
			style.shadow_size = 5
			chain_badge.add_theme_stylebox_override("panel", style)

			var lbl = Label.new()
			lbl.text = "⛓️ XÍCH LIÊN HOÀN"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8, 1.0))
			chain_badge.add_child(lbl)
			add_child(chain_badge)

		chain_badge.position = Vector2((size.x - 104) * 0.5, size.y * 0.42)
		chain_badge.visible = true
	else:
		if chain_badge:
			chain_badge.visible = false

func _update_delayed_tricks_position() -> void:
	if delayed_tricks_container:
		delayed_tricks_container.reset_size()
		var cont_w = max(92.0, delayed_tricks_container.size.x)
		delayed_tricks_container.position = Vector2((size.x - cont_w) * 0.5, -56.0)

func set_delayed_trick(trick_type: String, active: bool) -> void:
	if not delayed_tricks_container:
		delayed_tricks_container = HBoxContainer.new()
		delayed_tricks_container.name = "DelayedTricksContainer"
		delayed_tricks_container.alignment = BoxContainer.ALIGNMENT_CENTER
		delayed_tricks_container.add_theme_constant_override("separation", 4)
		delayed_tricks_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		delayed_tricks_container.z_index = 25
		add_child(delayed_tricks_container)

	if active:
		if not active_delayed_tricks.has(trick_type):
			var badge = PanelContainer.new()
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var style = StyleBoxFlat.new()
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_right = 6
			style.corner_radius_bottom_left = 6
			style.border_width_left = 1
			style.border_width_top = 1
			style.border_width_right = 1
			style.border_width_bottom = 1
			style.shadow_size = 4

			var lbl = Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 9)

			if trick_type == "lightning":
				badge.custom_minimum_size = Vector2(92, 22)
				style.bg_color = Color(0.12, 0.15, 0.38, 0.95)
				style.border_color = Color(0.4, 0.8, 1.0, 1.0)
				style.shadow_color = Color(0.2, 0.6, 1.0, 0.6)
				lbl.text = "⚡ THẦN SẤM"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
			elif trick_type == "cat_luong":
				badge.custom_minimum_size = Vector2(92, 22)
				style.bg_color = Color(0.28, 0.18, 0.08, 0.95)
				style.border_color = Color(0.95, 0.75, 0.2, 1.0)
				style.shadow_color = Color(0.8, 0.5, 0.1, 0.6)
				lbl.text = "🌾 CẮT LƯƠNG"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
			elif trick_type == "tram_ao":
				badge.custom_minimum_size = Vector2(92, 22)
				style.bg_color = Color(0.28, 0.08, 0.18, 0.95)
				style.border_color = Color(0.95, 0.3, 0.5, 1.0)
				style.shadow_color = Color(0.8, 0.2, 0.4, 0.6)
				lbl.text = "🕸️ TRẦM ẢO"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.7, 1.0))

			badge.add_theme_stylebox_override("panel", style)
			badge.add_child(lbl)
			delayed_tricks_container.add_child(badge)
			active_delayed_tricks[trick_type] = badge
	else:
		if active_delayed_tricks.has(trick_type):
			var badge = active_delayed_tricks[trick_type]
			if is_instance_valid(badge):
				badge.queue_free()
			active_delayed_tricks.erase(trick_type)

	_update_delayed_tricks_position()

func _init_equipment_slots() -> void:
	if is_instance_valid(weapon_slot):
		weapon_slot.visible = true
		if is_instance_valid(weapon_label):
			weapon_label.text = ""
			weapon_label.modulate.a = 0.45
	if is_instance_valid(armor_slot):
		armor_slot.visible = true
		if is_instance_valid(armor_label):
			armor_label.text = ""
			armor_label.modulate.a = 0.45
	if is_instance_valid(defensive_mount_slot):
		defensive_mount_slot.visible = true
		if is_instance_valid(defensive_mount_label):
			defensive_mount_label.text = ""
			defensive_mount_label.modulate.a = 0.45
	if is_instance_valid(offensive_mount_slot):
		offensive_mount_slot.visible = true
		if is_instance_valid(offensive_mount_label):
			offensive_mount_label.text = ""
			offensive_mount_label.modulate.a = 0.45
	if is_instance_valid(treasure_slot):
		treasure_slot.visible = true
		if is_instance_valid(treasure_label):
			treasure_label.text = ""
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
						weapon_label.text = ""
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
						armor_label.text = ""
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
						defensive_mount_label.text = ""
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
						offensive_mount_label.text = ""
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
						treasure_label.text = ""
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
		match p_faction:
			"Cổ":
				faction_badge.add_theme_color_override("font_color", Color(0.15, 0.85, 0.55, 1.0))
			"Tiền":
				faction_badge.add_theme_color_override("font_color", Color(0.15, 0.75, 0.95, 1.0))
			"Trung":
				faction_badge.add_theme_color_override("font_color", Color(0.95, 0.75, 0.2, 1.0))
			"Hậu":
				faction_badge.add_theme_color_override("font_color", Color(0.95, 0.4, 0.65, 1.0))
			_:
				faction_badge.add_theme_color_override("font_color", Color.WHITE)
	current_hp = p_hp
	max_hp = p_max_hp

	if is_instance_valid(role_badge):
		if p_role != "":
			role_badge.visible = true
			role_badge.text = " %s " % p_role
			if p_role == "RỒNG" or p_role.contains("RỒNG"):
				role_badge.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 1.0))
			elif p_role == "PHƯỢNG" or p_role.contains("PHƯỢNG"):
				role_badge.add_theme_color_override("font_color", Color(1.0, 0.4, 0.25, 1.0))
			elif p_role == "BẠN":
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
