extends Control

signal clicked()
signal skill_clicked()
signal skill_button_clicked(skill_key: String)
signal info_clicked()

@onready var portrait_rect: TextureRect = $Frame/Portrait
@onready var background_rect: TextureRect = $Frame.get_node_or_null("Background")

const BG_DRAGON_TEX = preload("res://assets/ui/hero_backgrounds/bg_hero_green.png")
const BG_PHOENIX_TEX = preload("res://assets/ui/hero_backgrounds/bg_hero_red.png")
@onready var name_label: Label = $Frame/TopBanner/Margin/HBox/NameLabel
@onready var role_badge: Label = $Frame/TopBanner/Margin/HBox/RoleBadge
@onready var health_rail: PanelContainer = $HealthRail
@onready var lotus_container: VBoxContainer = $HealthRail/LotusContainer
@onready var hand_count_label: Label = $Frame/HandBadge/HandLabel
@onready var an_tich_count_label: Label = $Frame/AnTichBadge/AnTichLabel
@onready var target_border: ReferenceRect = $TargetBorder
@onready var skill_button_stack: VBoxContainer = $SkillButtonStack
@onready var skill_btn: Button = $SkillButtonStack/SkillBtn
@onready var click_btn: Button = $ClickBtn
@onready var info_btn: Button = $InfoBtn
@onready var seat_label: Label = $SeatLabel
@onready var frame_panel: Panel = $Frame
@onready var inner_rim: Panel = $Frame/InnerRim
@onready var top_banner: PanelContainer = $Frame/TopBanner

@onready var weapon_slot = $Frame/EquipContainer/WeaponSlot
@onready var weapon_label = $Frame/EquipContainer/WeaponSlot/Label
@onready var armor_slot = $Frame/EquipContainer/ArmorSlot
@onready var armor_label = $Frame/EquipContainer/ArmorSlot/Label
@onready var defensive_mount_slot = $Frame/EquipContainer/MountRow/DefensiveMountSlot
@onready var defensive_mount_label = $Frame/EquipContainer/MountRow/DefensiveMountSlot/Label
@onready var offensive_mount_slot = $Frame/EquipContainer/MountRow/OffensiveMountSlot
@onready var offensive_mount_label = $Frame/EquipContainer/MountRow/OffensiveMountSlot/Label
@onready var mount_divider: Label = $Frame/EquipContainer/MountRow/MountDivider
@onready var mount_row = $Frame/EquipContainer/MountRow
@onready var treasure_slot = $Frame/EquipContainer/TreasureSlot
@onready var treasure_label = $Frame/EquipContainer/TreasureSlot/Label

var general_id: String = "tran_hung_dao"
var current_hp: int = 4
var max_hp: int = 4
var has_initialized_hp: bool = false
var hand_count: int = 4
var an_tich_count: int = 0
var equipped_items: Dictionary = {
	"weapon": "",
	"armor": "",
	"defensive_mount": "",
	"offensive_mount": "",
	"treasure": ""
}
var defensive_mount_suit_rank := ""
var offensive_mount_suit_rank := ""
var defensive_mount_equipped := false
var offensive_mount_equipped := false

var is_turn_active: bool = false
var displayed_turn_seconds: int = -1
var displayed_distance: int = -2
var is_near_death: bool = false
var turn_border_timer: float = 0.0
var turn_dots: Array = []
var turn_dots_container: Control = null
var turn_timer_badge: PanelContainer = null
var turn_timer_label: Label = null
var is_chained: bool = false
var chain_overlay: Control = null
var delayed_tricks_container: HBoxContainer = null
var active_delayed_tricks: Dictionary = {}
var last_damage_effect_time: float = 0.0
var defeated_overlay: ColorRect = null
var defeated_label: Label = null
var is_defeated: bool = false
var distance_label: Label = null
var near_death_tween: Tween = null
var near_death_halo: ReferenceRect = null
var skill_buttons: Array[Button] = []
var depth_light_rim: Panel = null
var depth_shade_rim: Panel = null
var frame_rest_position: Vector2
var frame_shake_tween: Tween = null

const DRAGON_TEAM_COLOR := Color(0.22, 0.82, 0.42, 1.0)
const PHOENIX_TEAM_COLOR := Color(0.93, 0.24, 0.22, 1.0)
const NEUTRAL_TEAM_COLOR := Color(0.9, 0.75, 0.28, 1.0)

func _ready() -> void:
	frame_rest_position = frame_panel.position
	if skill_button_stack:
		skill_button_stack.mouse_filter = Control.MOUSE_FILTER_STOP
		skill_button_stack.z_as_relative = false
		skill_button_stack.z_index = 1000
		skill_button_stack.offset_left = -104.0
		skill_button_stack.offset_right = -8.0
		skill_button_stack.move_to_front()
	if click_btn:
		# Avatar click target must always stay below the equipment skill controls.
		click_btn.z_as_relative = false
		click_btn.z_index = -10
		click_btn.pressed.connect(_on_avatar_clicked)
		click_btn.mouse_entered.connect(_on_mouse_entered)
		click_btn.mouse_exited.connect(_on_mouse_exited)

	if skill_btn:
		skill_buttons.append(skill_btn)
		skill_btn.pressed.connect(_on_skill_button_pressed.bind(skill_btn))

	if info_btn:
		info_btn.pressed.connect(func():
			info_clicked.emit()
		)

	_init_equipment_slots()
	_build_turn_indicators()
	_build_distance_label()
	_build_depth_rim()

func _build_distance_label() -> void:
	distance_label = Label.new()
	distance_label.name = "DistanceLabel"
	distance_label.anchor_left = 0.5
	distance_label.anchor_right = 0.5
	distance_label.anchor_top = 1.0
	distance_label.anchor_bottom = 1.0
	distance_label.offset_left = -78
	distance_label.offset_right = 78
	distance_label.offset_top = 3
	distance_label.offset_bottom = 22
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.add_theme_font_size_override("font_size", 11)
	distance_label.add_theme_color_override("font_color", Color(0.9, 0.84, 0.55, 1.0))
	distance_label.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.08, 1.0))
	distance_label.add_theme_constant_override("outline_size", 3)
	distance_label.mouse_filter = MOUSE_FILTER_IGNORE
	distance_label.z_index = 30
	add_child(distance_label)

func set_distance_label(distance: int) -> void:
	if displayed_distance == distance:
		return
	displayed_distance = distance
	if distance_label:
		distance_label.visible = distance > 0
		distance_label.text = "Khoảng cách: %d" % distance if distance > 0 else ""

func _build_depth_rim() -> void:
	var light_rim = Panel.new()
	light_rim.name = "DepthLightRim"
	light_rim.set_anchors_preset(PRESET_FULL_RECT)
	light_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light_rim.z_index = 8
	var light_style = StyleBoxFlat.new()
	light_style.bg_color = Color(0, 0, 0, 0)
	light_style.border_width_left = 2
	light_style.border_width_top = 2
	light_style.border_color = Color(1.0, 0.92, 0.55, 0.72)
	light_style.corner_radius_top_left = 10
	light_style.corner_radius_top_right = 10
	light_style.corner_radius_bottom_left = 10
	light_style.corner_radius_bottom_right = 10
	light_rim.add_theme_stylebox_override("panel", light_style)
	add_child(light_rim)
	depth_light_rim = light_rim

	var shade_rim = Panel.new()
	shade_rim.name = "DepthShadeRim"
	shade_rim.set_anchors_preset(PRESET_FULL_RECT)
	shade_rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade_rim.z_index = 9
	var shade_style = StyleBoxFlat.new()
	shade_style.bg_color = Color(0, 0, 0, 0)
	shade_style.border_width_right = 3
	shade_style.border_width_bottom = 4
	shade_style.border_color = Color(0.01, 0.015, 0.04, 0.72)
	shade_style.corner_radius_top_left = 10
	shade_style.corner_radius_top_right = 10
	shade_style.corner_radius_bottom_left = 10
	shade_style.corner_radius_bottom_right = 10
	shade_rim.add_theme_stylebox_override("panel", shade_style)
	add_child(shade_rim)
	depth_shade_rim = shade_rim

func _apply_team_presentation(p_role: String) -> void:
	var team_color := NEUTRAL_TEAM_COLOR
	if p_role.contains("RỒNG"):
		team_color = DRAGON_TEAM_COLOR
	elif p_role.contains("PHƯỢNG"):
		team_color = PHOENIX_TEAM_COLOR
	# Keep the team surfaces visibly colored while preserving readable text.
	var team_surface := Color(
		0.035 + team_color.r * 0.20,
		0.045 + team_color.g * 0.20,
		0.075 + team_color.b * 0.20,
		0.97
	)

	_apply_team_style(frame_panel, team_color, 3, 0.62)
	_apply_team_style(inner_rim, Color(team_color.r, team_color.g, team_color.b, 0.78), 1, 0.0)
	_apply_team_style(top_banner, Color(team_color.r, team_color.g, team_color.b, 0.92), 1, 0.0, team_surface)
	_apply_team_style(health_rail, Color(team_color.r, team_color.g, team_color.b, 0.98), 4, 0.0, team_surface)
	_apply_team_style(depth_light_rim, Color(team_color.r, team_color.g, team_color.b, 0.82), 2, 0.0)

	# Nền đằng sau hình tướng: Rồng = xanh lá, Phượng = đỏ
	if not is_instance_valid(background_rect):
		background_rect = $Frame.get_node_or_null("Background")
		if not is_instance_valid(background_rect) and is_instance_valid(frame_panel):
			background_rect = TextureRect.new()
			background_rect.name = "Background"
			background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			frame_panel.add_child(background_rect)
			frame_panel.move_child(background_rect, 0)

	if is_instance_valid(background_rect):
		if p_role.contains("PHƯỢNG"):
			background_rect.texture = BG_PHOENIX_TEX
			background_rect.visible = true
		else:
			background_rect.texture = BG_DRAGON_TEX
			background_rect.visible = true

	if is_instance_valid(role_badge):
		var badge_style := role_badge.get_theme_stylebox("normal") as StyleBoxFlat
		if badge_style:
			badge_style = badge_style.duplicate() as StyleBoxFlat
			badge_style.bg_color = Color(team_color.r * 0.12, team_color.g * 0.12, team_color.b * 0.12, 0.96)
			badge_style.border_color = Color(team_color.r, team_color.g, team_color.b, 0.9)
			role_badge.add_theme_stylebox_override("normal", badge_style)

	for corner_name in ["CornerTL", "CornerTR", "CornerBL", "CornerBR"]:
		var corner := $Frame.get_node_or_null(corner_name) as Label
		if corner:
			corner.add_theme_color_override("font_color", Color(team_color.r, team_color.g, team_color.b, 0.95))

func _apply_team_style(panel: Control, border_color: Color, border_width: int, shadow_alpha: float, fill_color: Color = Color(0, 0, 0, 0)) -> void:
	if not is_instance_valid(panel):
		return
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	if not style:
		return
	style = style.duplicate() as StyleBoxFlat
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border_color
	if fill_color.a > 0.0:
		style.bg_color = fill_color
	if shadow_alpha > 0.0:
		style.shadow_color = Color(border_color.r, border_color.g, border_color.b, shadow_alpha)
	panel.add_theme_stylebox_override("panel", style)

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
	if is_turn_active == active:
		return
	is_turn_active = active
	if turn_dots_container:
		turn_dots_container.visible = active
	if turn_timer_badge:
		turn_timer_badge.visible = active
	_update_delayed_tricks_position()

func update_turn_timer(seconds_left: int) -> void:
	var seconds: int = maxi(0, seconds_left)
	if displayed_turn_seconds == seconds:
		return
	displayed_turn_seconds = seconds
	if turn_timer_label:
		turn_timer_label.text = "⏳ %ds" % seconds
		if seconds <= 5:
			turn_timer_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
		else:
			turn_timer_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))

func set_chained(chained: bool) -> void:
	is_chained = chained
	if chained:
		if not chain_overlay:
			chain_overlay = Control.new()
			chain_overlay.name = "ChainOverlay"
			chain_overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			chain_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chain_overlay.tooltip_text = "Xích Liên Hoàn: cùng nhận sát thương nguyên tố với các tướng đang xích."
			chain_overlay.z_index = 5
			var chain_icon = Label.new()
			chain_icon.text = "⛓⛓⛓⛓"
			chain_icon.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
			chain_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chain_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chain_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			chain_icon.add_theme_font_size_override("font_size", 34)
			chain_icon.add_theme_color_override("font_color", Color(0.75, 0.91, 0.96, 0.92))
			chain_icon.add_theme_color_override("font_outline_color", Color(0.04, 0.10, 0.14, 0.92))
			chain_icon.add_theme_constant_override("outline_size", 3)
			chain_overlay.add_child(chain_icon)
			portrait_rect.add_child(chain_overlay)
		chain_overlay.visible = true
		chain_overlay.scale = Vector2(1.12, 1.12)
		create_tween().tween_property(chain_overlay, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	else:
		if chain_overlay:
			chain_overlay.visible = false

func set_near_death(active: bool) -> void:
	active = active and not is_defeated
	if is_near_death == active:
		return
	is_near_death = active
	if near_death_tween:
		near_death_tween.kill()
		near_death_tween = null
	if active:
		pivot_offset = size / 2.0
		if not near_death_halo:
			near_death_halo = ReferenceRect.new()
			near_death_halo.name = "NearDeathHalo"
			near_death_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
			near_death_halo.editor_only = false
			near_death_halo.border_color = Color(1.0, 0.15, 0.15, 1.0)
			near_death_halo.border_width = 4.0
			near_death_halo.set_anchors_preset(PRESET_FULL_RECT)
			near_death_halo.offset_left = -4
			near_death_halo.offset_top = -4
			near_death_halo.offset_right = 4
			near_death_halo.offset_bottom = 4
			near_death_halo.z_index = 28
			add_child(near_death_halo)
		near_death_halo.visible = true

		near_death_tween = create_tween().set_loops()
		# Nhấp nháy đỏ dồn dập + hiệu ứng nhịp tim
		near_death_tween.tween_property(self, "modulate", Color(1.0, 0.35, 0.35, 1.0), 0.22)
		near_death_tween.parallel().tween_property(self, "scale", Vector2(1.035, 1.035), 0.22).set_trans(Tween.TRANS_SINE)
		near_death_tween.parallel().tween_property(near_death_halo, "border_color", Color(1.0, 0.1, 0.1, 1.0), 0.22)
		near_death_tween.tween_property(self, "modulate", Color(1.0, 0.9, 0.9, 1.0), 0.22)
		near_death_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_SINE)
		near_death_tween.parallel().tween_property(near_death_halo, "border_color", Color(1.0, 0.4, 0.4, 0.35), 0.22)
	else:
		if near_death_halo:
			near_death_halo.visible = false
		scale = Vector2.ONE
		modulate = Color(0.72, 0.72, 0.78, 1.0) if is_defeated else Color.WHITE

func set_defeated(defeated: bool) -> void:
	if is_defeated == defeated and (not defeated or defeated_overlay != null):
		return
	is_defeated = defeated
	if defeated:
		set_near_death(false)
		if not defeated_overlay:
			defeated_overlay = ColorRect.new()
			defeated_overlay.name = "DefeatedOverlay"
			defeated_overlay.color = Color(0.03, 0.03, 0.04, 0.82)
			defeated_overlay.set_anchors_preset(PRESET_FULL_RECT)
			defeated_overlay.mouse_filter = MOUSE_FILTER_IGNORE
			defeated_overlay.z_index = 70
			add_child(defeated_overlay)

			defeated_label = Label.new()
			defeated_label.name = "DefeatedLabel"
			defeated_label.text = "☠\nTỬ TRẬN"
			defeated_label.set_anchors_preset(PRESET_FULL_RECT)
			defeated_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			defeated_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			defeated_label.add_theme_font_size_override("font_size", 23)
			defeated_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
			defeated_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
			defeated_label.add_theme_constant_override("outline_size", 6)
			defeated_label.mouse_filter = MOUSE_FILTER_IGNORE
			defeated_label.z_index = 71
			add_child(defeated_label)
		defeated_overlay.visible = true
		defeated_label.visible = true
		modulate = Color(0.72, 0.72, 0.78, 1.0)
		set_turn_active(false)
		set_chained(false)
	else:
		if defeated_overlay:
			defeated_overlay.visible = false
		if defeated_label:
			defeated_label.visible = false
		modulate = Color.WHITE

func _update_delayed_tricks_position() -> void:
	if delayed_tricks_container:
		delayed_tricks_container.reset_size()
		var cont_w = max(84.0, delayed_tricks_container.size.x)
		var target_y = -56.0 if (turn_timer_badge and turn_timer_badge.visible) else -28.0
		delayed_tricks_container.position = Vector2((size.x - cont_w) * 0.5, target_y)

func _normalize_delayed_trick_type(raw_type: String) -> String:
	var norm = raw_type.to_lower().strip_edges()
	if "dai_hong_thuy" in norm or "dai hong thuy" in norm or "đại hồng thủy" in norm or "lightning" in norm or "sam" in norm or "sấm" in norm or norm == "19" or norm == "8":
		return "dai_hong_thuy"
	elif "supply" in norm or "luong" in norm or "lương" in norm or norm == "12":
		return "cat_luong"
	elif "acedia" in norm or "tram" in norm or "trầm" in norm or "indulgence" in norm or norm == "13":
		return "tram_ao"
	elif "bai coc" in norm or "bãi cọc" in norm or "bachdang" in norm or norm == "22":
		return "bai_coc"
	return norm

func set_delayed_trick(trick_type: String, active: bool) -> void:
	var key = _normalize_delayed_trick_type(trick_type)

	if not delayed_tricks_container:
		delayed_tricks_container = HBoxContainer.new()
		delayed_tricks_container.name = "DelayedTricksContainer"
		delayed_tricks_container.alignment = BoxContainer.ALIGNMENT_CENTER
		delayed_tricks_container.add_theme_constant_override("separation", 4)
		delayed_tricks_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		delayed_tricks_container.z_index = 25
		add_child(delayed_tricks_container)

	if active:
		if not active_delayed_tricks.has(key):
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

			badge.custom_minimum_size = Vector2(84, 22)
			if key == "dai_hong_thuy":
				badge.custom_minimum_size = Vector2(112, 22)
				style.bg_color = Color(0.12, 0.15, 0.38, 0.95)
				style.border_color = Color(0.4, 0.8, 1.0, 1.0)
				style.shadow_color = Color(0.2, 0.6, 1.0, 0.6)
				lbl.text = "🌊 ĐẠI HỒNG THỦY"
				lbl.add_theme_color_override("font_color", Color(0.65, 0.95, 1.0, 1.0))
			elif key == "cat_luong":
				style.bg_color = Color(0.35, 0.20, 0.05, 0.95)
				style.border_color = Color(1.0, 0.85, 0.3, 1.0)
				style.shadow_color = Color(0.8, 0.5, 0.1, 0.6)
				lbl.text = "🌾 CẮT LƯƠNG"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
			elif key == "tram_ao":
				style.bg_color = Color(0.20, 0.08, 0.28, 0.95)
				style.border_color = Color(0.95, 0.35, 0.75, 1.0)
				style.shadow_color = Color(0.8, 0.2, 0.6, 0.6)
				lbl.text = "🕸️ TRẦM ẢO"
				lbl.add_theme_color_override("font_color", Color(1.0, 0.65, 0.85, 1.0))
			elif key == "bai_coc":
				style.bg_color = Color(0.12, 0.28, 0.24, 0.95)
				style.border_color = Color(0.35, 0.9, 0.75, 1.0)
				style.shadow_color = Color(0.15, 0.65, 0.5, 0.6)
				lbl.text = "🪵 BÃI CỌC BẠCH ĐẰNG"
				lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.85, 1.0))
			else:
				style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
				style.border_color = Color(0.7, 0.7, 0.7, 1.0)
				lbl.text = trick_type

			badge.add_theme_stylebox_override("panel", style)
			badge.add_child(lbl)
			delayed_tricks_container.add_child(badge)
			active_delayed_tricks[key] = badge

			# Lá trì hoãn bay từ dưới lên đúng vị trí vùng phán xét.
			badge.pivot_offset = Vector2(42, 11)
			badge.position.y += 28.0
			var tw = create_tween()
			tw.set_parallel(true)
			tw.tween_property(badge, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(badge, "scale", Vector2(1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK)
			tw.chain().tween_property(badge, "scale", Vector2.ONE, 0.12)
	else:
		if active_delayed_tricks.has(key):
			var badge = active_delayed_tricks[key]
			if is_instance_valid(badge):
				badge.queue_free()
			active_delayed_tricks.erase(key)

	_update_delayed_tricks_position()

func _init_equipment_slots() -> void:
	var equip_container = weapon_slot.get_parent() if is_instance_valid(weapon_slot) else null
	if equip_container:
		equip_container.z_index = 20
		equip_container.move_child(weapon_slot, 0)
		equip_container.move_child(armor_slot, 1)
		equip_container.move_child(defensive_mount_slot.get_parent(), 2)
		equip_container.move_child(treasure_slot, 3)
	if is_instance_valid(weapon_slot):
		weapon_slot.visible = true
		if is_instance_valid(weapon_label):
			weapon_label.add_theme_font_size_override("font_size", 12)
			weapon_label.text = ""
			weapon_label.modulate.a = 1.0
	if is_instance_valid(armor_slot):
		armor_slot.visible = true
		if is_instance_valid(armor_label):
			armor_label.add_theme_font_size_override("font_size", 12)
			armor_label.text = ""
			armor_label.modulate.a = 1.0
	if is_instance_valid(defensive_mount_slot):
		defensive_mount_slot.visible = true
		if is_instance_valid(defensive_mount_label):
			defensive_mount_label.add_theme_font_size_override("font_size", 12)
			defensive_mount_label.text = ""
			defensive_mount_label.modulate.a = 1.0
	if is_instance_valid(offensive_mount_slot):
		offensive_mount_slot.visible = true
		if is_instance_valid(offensive_mount_label):
			offensive_mount_label.add_theme_font_size_override("font_size", 12)
			offensive_mount_label.text = ""
			offensive_mount_label.modulate.a = 1.0
	if is_instance_valid(treasure_slot):
		treasure_slot.visible = true
		if is_instance_valid(treasure_label):
			treasure_label.add_theme_font_size_override("font_size", 12)
			treasure_label.text = ""
			treasure_label.modulate.a = 1.0
	_refresh_mount_slots_visibility()

func _refresh_mount_slots_visibility() -> void:
	var has_defensive := defensive_mount_equipped
	var has_offensive := offensive_mount_equipped or _has_default_offensive_mount()
	if is_instance_valid(defensive_mount_slot):
		defensive_mount_slot.visible = has_defensive
		defensive_mount_slot.modulate.a = 1.0
	if is_instance_valid(offensive_mount_slot):
		offensive_mount_slot.visible = has_offensive
		offensive_mount_slot.modulate.a = 1.0
	var mount_row = defensive_mount_slot.get_parent() if is_instance_valid(defensive_mount_slot) else null
	if mount_row:
		# Ngựa cộng (+) luôn ở nửa trái, Ngựa trừ (-) luôn ở nửa phải.
		mount_row.move_child(defensive_mount_slot, 0)
		mount_row.move_child(mount_divider, 1)
		mount_row.move_child(offensive_mount_slot, 2)
		mount_row.z_index = 2
		mount_row.alignment = BoxContainer.ALIGNMENT_CENTER
		mount_row.visible = has_defensive or has_offensive
		if is_instance_valid(mount_divider):
			mount_divider.visible = has_defensive and has_offensive

func _on_avatar_clicked() -> void:
	clicked.emit()

func _input(event: InputEvent) -> void:
	# The stack intentionally extends beyond the avatar's rect; reserve that exposed area before Control hit-testing discards it.
	if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	for button in skill_buttons:
		if is_instance_valid(button) and button.visible and not button.disabled and button.get_global_rect().has_point(event.position):
			button.remove_meta("manual_skill_press_until_msec")
			_on_skill_button_pressed(button)
			button.set_meta("manual_skill_press_until_msec", Time.get_ticks_msec() + 250)
			get_viewport().set_input_as_handled()
			return

func set_skill(skill_title: String) -> void:
	set_skill_buttons([{"id": "primary", "text": skill_title}])

func set_skill_buttons(button_specs: Array) -> void:
	var visible_count = 0
	for spec_index in range(button_specs.size()):
		var spec = button_specs[spec_index]
		if not (spec is Dictionary):
			continue
		var title = str(spec.get("text", spec.get("title", ""))).strip_edges()
		if title.is_empty():
			continue
		var button = _get_or_create_skill_button(visible_count)
		button.text = title
		button.tooltip_text = str(spec.get("description", title))
		button.set_meta("skill_key", str(spec.get("id", "skill_%d" % visible_count)))
		button.visible = true
		button.disabled = bool(spec.get("disabled", false))
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.custom_minimum_size = Vector2(96, 28)
		button.add_theme_font_size_override("font_size", 8)
		_set_skill_button_style(button, bool(spec.get("selected", false)))
		visible_count += 1

	for button_index in range(visible_count, skill_buttons.size()):
		var button = skill_buttons[button_index]
		if is_instance_valid(button):
			button.visible = false
			button.disabled = true

	if is_instance_valid(skill_button_stack):
		skill_button_stack.mouse_filter = Control.MOUSE_FILTER_STOP
		skill_button_stack.z_as_relative = false
		skill_button_stack.z_index = 1000
		skill_button_stack.offset_left = -104.0
		skill_button_stack.offset_right = -8.0
		skill_button_stack.move_to_front()
		skill_button_stack.visible = visible_count > 0
		var stack_height = max(28.0, float(visible_count * 28 + max(0, visible_count - 1) * 3))
		skill_button_stack.offset_top = -stack_height * 0.5
		skill_button_stack.offset_bottom = stack_height * 0.5
	if visible_count > 0 and ("ĐIỂM TRỐNG" in skill_buttons[0].text or "HỔ PHÙ" in skill_buttons[0].text):
		set_treasure_skill_selected(false)

func set_treasure_skill_selected(selected: bool) -> void:
	for button in skill_buttons:
		if not is_instance_valid(button) or not button.visible or not str(button.get_meta("skill_key", "")) in ["treasure_drum", "treasure_ho_phu"]:
			continue
		_set_skill_button_style(button, selected)

func set_skill_button_selected(skill_key: String, selected: bool) -> void:
	for button in skill_buttons:
		if is_instance_valid(button) and button.visible and str(button.get_meta("skill_key", "")) == skill_key:
			_set_skill_button_style(button, selected)

func _set_skill_button_style(button: Button, selected: bool) -> void:
	var background = Color(0.20, 0.72, 0.34, 1.0) if selected else Color(0.96, 0.98, 0.94, 1.0)
	var border = Color(0.08, 0.38, 0.16, 1.0) if selected else Color(0.55, 0.61, 0.54, 1.0)
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1) if selected else Color(0.08, 0.14, 0.08, 1))

func _get_or_create_skill_button(button_index: int) -> Button:
	if button_index < skill_buttons.size() and is_instance_valid(skill_buttons[button_index]):
		return skill_buttons[button_index]
	var button = Button.new()
	button.custom_minimum_size = Vector2(96, 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	button.add_theme_stylebox_override("normal", skill_btn.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("hover", skill_btn.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("pressed", skill_btn.get_theme_stylebox("pressed"))
	button.pressed.connect(_on_skill_button_pressed.bind(button))
	skill_button_stack.add_child(button)
	skill_buttons.append(button)
	return button

func _on_skill_button_pressed(pressed_button: Button) -> void:
	if is_instance_valid(pressed_button) and Time.get_ticks_msec() <= int(pressed_button.get_meta("manual_skill_press_until_msec", 0)):
		pressed_button.remove_meta("manual_skill_press_until_msec")
		return
	var skill_key = str(pressed_button.get_meta("skill_key", "primary")) if is_instance_valid(pressed_button) else "primary"
	skill_button_clicked.emit(skill_key)
	skill_clicked.emit()

func set_target_highlight(active: bool) -> void:
	if is_instance_valid(target_border):
		target_border.visible = active
		if active:
			var tw = target_border.create_tween().set_loops(4)
			tw.tween_property(target_border, "border_color", Color(1, 1, 0.5, 1), 0.2)
			tw.tween_property(target_border, "border_color", Color(1, 0.7, 0.1, 1), 0.2)

func _format_equip_str(icon: String, suit_rank: String, item_name: String) -> String:
	var name = item_name.strip_edges()
	if name.is_empty():
		return ""
	var rank = suit_rank.strip_edges()
	return "%s %s %s" % [icon, rank, name] if not rank.is_empty() else "%s %s" % [icon, name]

func _refresh_mount_labels() -> void:
	var defensive_modifier := 1 if defensive_mount_equipped else 0
	var has_default_offensive := _has_default_offensive_mount()
	var offensive_modifier := -2 if has_default_offensive else 0
	if offensive_mount_equipped:
		offensive_modifier -= 1
	if is_instance_valid(defensive_mount_label):
		defensive_mount_label.text = ("🐘 " + _format_mount_modifier(defensive_modifier, defensive_mount_suit_rank)) if defensive_mount_equipped else ""
		defensive_mount_label.modulate.a = 1.0 if defensive_mount_equipped else 0.45
	if is_instance_valid(offensive_mount_label):
		offensive_mount_label.text = ("🐎 " + _format_mount_modifier(offensive_modifier, offensive_mount_suit_rank)) if (offensive_mount_equipped or has_default_offensive) else ""
		offensive_mount_label.modulate.a = 1.0 if (offensive_mount_equipped or has_default_offensive) else 0.45
	if is_instance_valid(mount_divider):
		mount_divider.visible = defensive_mount_equipped and (offensive_mount_equipped or has_default_offensive)
	if is_instance_valid(mount_row):
		mount_row.visible = true
		mount_row.z_index = 50

func _has_default_offensive_mount() -> bool:
	return general_id.to_lower() in ["dao_han", "2", "hero_2"]

func _format_mount_modifier(modifier: int, suit_rank: String) -> String:
	if modifier == 0:
		return ""
	var sign := "+" if modifier > 0 else ""
	var rank := suit_rank.strip_edges()
	if rank.length() > 1:
		var suit := rank.substr(0, 1)
		var card_rank := rank.substr(1).strip_edges()
		return "%s%d %s%s" % [sign, modifier, card_rank, suit]
	return "%s%d" % [sign, modifier]

func set_equipment(slot_type: String, item_name: String, suit_rank: String = "") -> void:
	var key = ""
	var s_lower = slot_type.to_lower().strip_edges()
	match s_lower:
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
		"defensive_mount", "mount_defense", "ngua_thu", "mount", "def_horse", "defensive_horse", "horse_def":
			key = "defensive_mount"
			defensive_mount_equipped = not item_name.is_empty()
			defensive_mount_suit_rank = suit_rank if not item_name.is_empty() else ""
		"offensive_mount", "mount_offense", "ngua_cong", "off_horse", "offensive_horse", "horse_off":
			key = "offensive_mount"
			offensive_mount_equipped = not item_name.is_empty()
			offensive_mount_suit_rank = suit_rank if not item_name.is_empty() else ""
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
		"horse":
			if "voi" in item_name.to_lower() or "+1" in item_name:
				set_equipment("def_horse", item_name, suit_rank)
			else:
				set_equipment("off_horse", item_name, suit_rank)
			return

	if key != "":
		var val = ""
		if item_name != "":
			var sr = suit_rank.strip_edges()
			var iname = item_name.strip_edges()
			val = ("%s %s" % [sr, iname]) if sr != "" else iname
		equipped_items[key] = val
		if key == "defensive_mount":
			equipped_items["def_horse"] = val
		elif key == "offensive_mount":
			equipped_items["off_horse"] = val
		if key in ["defensive_mount", "offensive_mount"]:
			_refresh_mount_labels()
			_refresh_mount_slots_visibility()

func has_armor() -> bool:
	return equipped_items.get("armor", "") != ""

func get_armor_name() -> String:
	return equipped_items.get("armor", "")

func play_damage_effect(damage_element: String = "NORMAL") -> void:
	if damage_element == "LIGHTNING":
		damage_element = "WATER"
	last_damage_effect_time = float(Time.get_ticks_msec())

	# 1. Rung lắc chấn động mạnh trên Frame nội bộ
	var frame_node = get_node_or_null("Frame")
	if frame_node and is_instance_valid(frame_node):
		if frame_shake_tween and frame_shake_tween.is_valid():
			frame_shake_tween.kill()
		frame_node.position = frame_rest_position
		frame_shake_tween = create_tween()
		frame_shake_tween.tween_property(frame_node, "position", frame_rest_position + Vector2(-12, 7), 0.04)
		frame_shake_tween.tween_property(frame_node, "position", frame_rest_position + Vector2(11, -8), 0.04)
		frame_shake_tween.tween_property(frame_node, "position", frame_rest_position + Vector2(-8, 5), 0.04)
		frame_shake_tween.tween_property(frame_node, "position", frame_rest_position + Vector2(5, -3), 0.04)
		frame_shake_tween.tween_property(frame_node, "position", frame_rest_position, 0.04)
		frame_shake_tween.tween_callback(func(): frame_shake_tween = null)

	# 2. Chớp đỏ rực / thuộc tính trên chân dung tướng
	var flash_color = Color(3.2, 0.3, 0.3, 1.0)
	if damage_element == "FIRE":
		flash_color = Color(3.5, 1.4, 0.2, 1.0)
	elif damage_element == "WATER":
		flash_color = Color(0.25, 1.7, 3.5, 1.0)

	if portrait_rect and is_instance_valid(portrait_rect):
		var tw = create_tween()
		tw.tween_property(portrait_rect, "modulate", flash_color, 0.06)
		tw.tween_property(portrait_rect, "modulate", Color.WHITE, 0.28)

	# 3. Vết chém kiếm rạch ngang thẻ tướng (Slash VFX)
	_spawn_slash_cut_vfx(damage_element)

func play_heal_effect() -> void:
	# 1. Hào quang ngọc bích / xanh lá tỏa sáng êm dịu trên chân dung tướng
	var heal_color = Color(0.4, 2.8, 1.2, 1.0)
	if portrait_rect and is_instance_valid(portrait_rect):
		var tw = create_tween()
		tw.tween_property(portrait_rect, "modulate", heal_color, 0.08)
		tw.tween_property(portrait_rect, "modulate", Color.WHITE, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Vòng sáng hồi phục tỏa ra viền tướng
	_spawn_heal_aura_vfx()

func play_armor_effect(armor_name: String, success: bool = true, charges_left: int = -1) -> void:
	var color = Color(0.45, 0.85, 1.0, 1.0)
	var title = "GIÁP ĐỒNG SƠN VI\nCHẶN ĐỨNG ĐÒN TRẢM!"
	var fill = Color(0.08, 0.28, 0.48, 0.90)
	var border = Color(0.55, 0.9, 1.0, 1.0)
	var icon_path = "res://assets/ui/cards/card_armor_giap_dong.png"

	if "Khiên Mây" in armor_name:
		if success:
			color = Color(0.4, 0.95, 0.65, 1.0)
			title = "KHIÊN MÂY BỆN\nHÓA GIẢI ĐÒN!"
			fill = Color(0.08, 0.38, 0.22, 0.90)
			border = Color(0.5, 1.0, 0.7, 1.0)
		else:
			color = Color(0.95, 0.35, 0.35, 1.0)
			title = "KHIÊN MÂY BỆN\nPHÁN XÉT THẤT BẠI!"
			fill = Color(0.42, 0.08, 0.12, 0.90)
			border = Color(0.95, 0.4, 0.45, 1.0)
		icon_path = "res://assets/ui/cards/card_armor_khien_may.png"
	elif "Áo Bào" in armor_name:
		color = Color(1.0, 0.82, 0.3, 1.0)
		title = "ÁO BÀO HOÀNG TỘC\nCHẶN SÁT THƯƠNG!" if charges_left != 0 else "ÁO BÀO HOÀNG TỘC\nĐÃ KIỆT LỰC!"
		fill = Color(0.4, 0.18, 0.45, 0.90)
		border = Color(1.0, 0.82, 0.35, 1.0)
		icon_path = "res://assets/ui/cards/card_armor_ao_bao.png"

	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/ui/icon_armor.png"

	if success:
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_parry"):
			am.play_parry()

	# Root VFX container over this avatar - render above all seat containers
	var fx = Control.new()
	fx.set_anchors_preset(PRESET_FULL_RECT)
	fx.mouse_filter = MOUSE_FILTER_IGNORE
	fx.z_as_relative = false
	fx.z_index = 180
	add_child(fx)

	# Full avatar aura glow
	var aura = Panel.new()
	aura.set_anchors_preset(PRESET_FULL_RECT)
	aura.mouse_filter = MOUSE_FILTER_IGNORE
	var aura_style = StyleBoxFlat.new()
	aura_style.bg_color = Color(fill.r, fill.g, fill.b, 0.3)
	aura_style.border_width_left = 4
	aura_style.border_width_top = 4
	aura_style.border_width_right = 4
	aura_style.border_width_bottom = 4
	aura_style.border_color = border
	aura_style.corner_radius_top_left = 10
	aura_style.corner_radius_top_right = 10
	aura_style.corner_radius_bottom_right = 10
	aura_style.corner_radius_bottom_left = 10
	aura_style.shadow_color = Color(color.r, color.g, color.b, 0.8)
	aura_style.shadow_size = 20
	aura.add_theme_stylebox_override("panel", aura_style)
	fx.add_child(aura)

	# Shield Root positioned at center
	var avatar_center = size * 0.5
	if avatar_center == Vector2.ZERO:
		avatar_center = Vector2(87, 119)

	var shield_root = Control.new()
	shield_root.position = avatar_center
	shield_root.scale = Vector2(0.2, 0.2)
	shield_root.modulate.a = 0.0
	shield_root.mouse_filter = MOUSE_FILTER_IGNORE
	fx.add_child(shield_root)

	# Shockwave circular barrier
	var shockwave = Panel.new()
	shockwave.custom_minimum_size = Vector2(160, 160)
	shockwave.size = Vector2(160, 160)
	shockwave.position = -Vector2(80, 80)
	shockwave.mouse_filter = MOUSE_FILTER_IGNORE
	var sw_style = StyleBoxFlat.new()
	sw_style.bg_color = Color(color.r, color.g, color.b, 0.16)
	sw_style.border_width_left = 5
	sw_style.border_width_top = 5
	sw_style.border_width_right = 5
	sw_style.border_width_bottom = 5
	sw_style.border_color = border
	sw_style.corner_radius_top_left = 80
	sw_style.corner_radius_top_right = 80
	sw_style.corner_radius_bottom_right = 80
	sw_style.corner_radius_bottom_left = 80
	sw_style.shadow_color = Color(color.r, color.g, color.b, 0.9)
	sw_style.shadow_size = 25
	shockwave.add_theme_stylebox_override("panel", sw_style)
	shield_root.add_child(shockwave)

	# Flying Armor Badge / Card
	var shield_card = Panel.new()
	var card_w = 90.0
	var card_h = 124.0
	shield_card.custom_minimum_size = Vector2(card_w, card_h)
	shield_card.size = Vector2(card_w, card_h)
	shield_card.position = Vector2(-card_w * 0.5, -card_h * 0.5 - 14.0)
	shield_card.mouse_filter = MOUSE_FILTER_IGNORE
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = fill
	card_style.border_width_left = 4
	card_style.border_width_top = 4
	card_style.border_width_right = 4
	card_style.border_width_bottom = 4
	card_style.border_color = border
	card_style.corner_radius_top_left = 10
	card_style.corner_radius_top_right = 10
	card_style.corner_radius_bottom_right = 10
	card_style.corner_radius_bottom_left = 10
	card_style.shadow_color = Color(color.r, color.g, color.b, 0.95)
	card_style.shadow_size = 22
	shield_card.add_theme_stylebox_override("panel", card_style)
	shield_root.add_child(shield_card)

	# Armor Card Texture
	if ResourceLoader.exists(icon_path):
		var tex_rect = TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.set_anchors_preset(PRESET_FULL_RECT)
		tex_rect.offset_left = 6
		tex_rect.offset_top = 6
		tex_rect.offset_right = -6
		tex_rect.offset_bottom = -6
		tex_rect.mouse_filter = MOUSE_FILTER_IGNORE
		shield_card.add_child(tex_rect)

	# Deflection banner label
	var label = Label.new()
	label.custom_minimum_size = Vector2(190, 44)
	label.size = Vector2(190, 44)
	label.position = Vector2(-95, 52)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.98))
	label.add_theme_constant_override("outline_size", 6)
	shield_root.add_child(label)

	# Parry sparks
	var sparks_container = Control.new()
	sparks_container.mouse_filter = MOUSE_FILTER_IGNORE
	shield_root.add_child(sparks_container)

	# Animation sequence
	var tw = create_tween()

	if success:
		# Rapid pop forward with back-ease (flying armor slams into position)
		tw.parallel().tween_property(shield_root, "scale", Vector2(1.22, 1.22), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(shield_root, "modulate:a", 1.0, 0.08)
		tw.parallel().tween_property(aura, "scale", Vector2(1.08, 1.08), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# Deflection impact: shockwave expands and fades
		tw.parallel().tween_property(shockwave, "scale", Vector2(2.1, 2.1), 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Shield bright flash upon absorbing hit
		tw.parallel().tween_property(shield_card, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.07)
		tw.chain().tween_property(shield_card, "modulate", Color.WHITE, 0.12)
		tw.parallel().tween_property(shield_root, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Spawn flying deflection spark particles
		for i in range(6):
			var spark = ColorRect.new()
			spark.custom_minimum_size = Vector2(5, 5)
			spark.size = Vector2(5, 5)
			spark.color = border
			spark.position = Vector2.ZERO
			spark.mouse_filter = MOUSE_FILTER_IGNORE
			sparks_container.add_child(spark)
			var angle = (float(i) / 6.0) * TAU + randf_range(-0.3, 0.3)
			var dist = randf_range(40.0, 70.0)
			var target_pos = Vector2(cos(angle), sin(angle)) * dist
			tw.parallel().tween_property(spark, "position", target_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(spark, "scale", Vector2.ZERO, 0.28).set_delay(0.08)

		# The final charge has to remain visible before the equipped armor disappears.
		tw.chain().tween_interval(1.35 if ("Áo Bào" in armor_name and charges_left == 0) else 0.85)

		# Smooth floating exit
		tw.chain().tween_property(shield_root, "position:y", avatar_center.y - 22.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_callback(fx.queue_free)
	else:
		# Judgement failed: pop up then shake / shatter down
		tw.parallel().tween_property(shield_root, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(shield_root, "modulate:a", 1.0, 0.08)
		# Shake
		tw.chain().tween_property(shield_root, "position:x", avatar_center.x - 8.0, 0.05)
		tw.chain().tween_property(shield_root, "position:x", avatar_center.x + 8.0, 0.05)
		tw.chain().tween_property(shield_root, "position:x", avatar_center.x - 5.0, 0.05)
		tw.chain().tween_property(shield_root, "position:x", avatar_center.x + 5.0, 0.05)
		tw.chain().tween_property(shield_root, "position:x", avatar_center.x, 0.05)
		# Shatter down and fade
		tw.chain().tween_property(shield_root, "position:y", avatar_center.y + 25.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(fx, "modulate:a", 0.0, 0.3)
		tw.chain().tween_callback(fx.queue_free)

func _spawn_heal_aura_vfx() -> void:
	var panel = Panel.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	panel.mouse_filter = MOUSE_FILTER_IGNORE
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.9, 0.5, 0.25)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 1.0, 0.7, 0.9)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", style)
	panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	panel.z_index = 45
	add_child(panel)

	var tw = create_tween()
	tw.tween_property(panel, "modulate:a", 0.9, 0.1)
	tw.tween_property(panel, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(panel.queue_free)

func _spawn_slash_cut_vfx(damage_element: String = "NORMAL") -> void:
	if damage_element == "LIGHTNING":
		damage_element = "WATER"
	var slash_overlay = Control.new()
	slash_overlay.set_anchors_preset(PRESET_FULL_RECT)
	slash_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	slash_overlay.z_index = 45
	add_child(slash_overlay)

	var slash_color = Color(1.0, 0.2, 0.2, 0.95)
	var core_color = Color(1.0, 0.95, 0.85, 1.0)
	if damage_element == "FIRE":
		slash_color = Color(1.0, 0.5, 0.1, 0.95)
	elif damage_element == "WATER":
		slash_color = Color(0.15, 0.7, 1.0, 0.95)

	# Lớp viền phát sáng của nhát chém
	var outer_slash = Line2D.new()
	outer_slash.width = 16.0
	outer_slash.default_color = slash_color
	outer_slash.begin_cap_mode = Line2D.LINE_CAP_ROUND
	outer_slash.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Lớp lõi sắc bén sáng rực
	var blade_core = Line2D.new()
	blade_core.width = 5.0
	blade_core.default_color = core_color
	blade_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	blade_core.end_cap_mode = Line2D.LINE_CAP_ROUND

	var p_start = Vector2(size.x * 0.88, size.y * 0.15)
	var p_end = Vector2(size.x * 0.12, size.y * 0.85)

	outer_slash.add_point(p_start)
	outer_slash.add_point(p_start)
	blade_core.add_point(p_start)
	blade_core.add_point(p_start)

	slash_overlay.add_child(outer_slash)
	slash_overlay.add_child(blade_core)

	# Vệt chém vung ngang trong 0.06s
	var slice_tw = create_tween().set_parallel(true)
	slice_tw.tween_method(func(pt: Vector2):
		if is_instance_valid(outer_slash) and outer_slash.get_point_count() >= 2:
			outer_slash.set_point_position(1, pt)
		if is_instance_valid(blade_core) and blade_core.get_point_count() >= 2:
			blade_core.set_point_position(1, pt)
	, p_start, p_end, 0.06).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# Đốm tóe máu/lửa văng ra từ giữa vết chém
	var p_mid = (p_start + p_end) * 0.5
	for i in range(4):
		var spark = ColorRect.new()
		spark.custom_minimum_size = Vector2(4, 4)
		spark.color = slash_color
		spark.position = p_mid
		slash_overlay.add_child(spark)
		var spark_target = p_mid + Vector2(randf_range(-35.0, 35.0), randf_range(-35.0, 35.0))
		slice_tw.tween_property(spark, "position", spark_target, 0.25).set_trans(Tween.TRANS_QUAD)
		slice_tw.tween_property(spark, "scale", Vector2.ZERO, 0.25).set_delay(0.05)

	# Tản rộng và tan biến mượt mà
	slice_tw.chain().tween_property(slash_overlay, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD)
	slice_tw.parallel().tween_property(outer_slash, "width", 24.0, 0.24)
	slice_tw.chain().tween_callback(slash_overlay.queue_free)

func spawn_damage_number(amount: int, damage_element: String = "NORMAL") -> void:
	if damage_element == "LIGHTNING":
		damage_element = "WATER"
	var lbl = Label.new()
	var elem_symbol = "🩸"
	var text_color = Color(1.0, 0.2, 0.2, 1.0)
	if damage_element == "FIRE":
		elem_symbol = "🔥"
		text_color = Color(1.0, 0.45, 0.1, 1.0)
	elif damage_element == "WATER":
		elem_symbol = "🌊"
		text_color = Color(0.2, 0.75, 1.0, 1.0)

	lbl.text = "-%d MÁU %s" % [amount, elem_symbol]
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))

	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(size.x, 36)
	lbl.position = Vector2(0, size.y * 0.42)
	lbl.pivot_offset = Vector2(size.x * 0.5, 18)
	lbl.scale = Vector2(1.7, 1.7)
	lbl.z_index = 60
	add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "position:y", lbl.position.y - 10.0, 0.12)
	tw.tween_property(lbl, "position:y", lbl.position.y - 60.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65).set_delay(0.15)
	tw.chain().tween_callback(lbl.queue_free)

func spawn_heal_number(amount: int) -> void:
	var lbl = Label.new()
	lbl.text = "+%d MÁU 💚" % amount
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", Color(0.25, 1.0, 0.4, 1.0))
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))

	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(size.x, 36)
	lbl.position = Vector2(0, size.y * 0.42)
	lbl.pivot_offset = Vector2(size.x * 0.5, 18)
	lbl.scale = Vector2(1.5, 1.5)
	lbl.z_index = 60
	add_child(lbl)

	var tw = create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position:y", lbl.position.y - 50.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65).set_delay(0.15)
	tw.chain().tween_callback(lbl.queue_free)

var skill_banner_queue: Array[Dictionary] = []
var skill_banner_active: bool = false

func show_skill_banner(skill_name: String, duration: float = 2.0, play_voice: bool = false) -> void:
	skill_banner_queue.append({"name": skill_name, "duration": duration, "play_voice": play_voice})
	if not skill_banner_active:
		_display_next_skill_banner()

func _display_next_skill_banner() -> void:
	if skill_banner_queue.is_empty():
		skill_banner_active = false
		return
	skill_banner_active = true
	var banner_data: Dictionary = skill_banner_queue.pop_front()
	var skill_name := str(banner_data.get("name", "KỸ NĂNG"))
	var duration := float(banner_data.get("duration", 2.0))
	var previous = get_node_or_null("SkillActivationBanner")
	if is_instance_valid(previous):
		previous.queue_free()
	var label = Label.new()
	label.name = "SkillActivationBanner"
	label.text = skill_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-30.0, size.y * 0.18)
	label.size = Vector2(size.x + 60.0, 42.0)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.7, 0.7)
	label.modulate.a = 0.0
	label.z_index = 2200
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.08, 0.12, 1.0))
	label.add_theme_constant_override("outline_size", 7)
	add_child(label)
	if bool(banner_data.get("play_voice", false)):
		AudioManager.play_voice(skill_name)
		AudioManager.play_skill()
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(max(0.0, duration - 0.42))
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(label, "position:y", label.position.y - 18.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
		skill_banner_active = false
		call_deferred("_display_next_skill_banner")
	)

func setup_general(p_id: String, p_name: String, p_faction: String = "Trần", p_hp: int = 4, p_max_hp: int = 4, p_role: String = "", p_seat: int = 0) -> void:
	general_id = p_id
	_refresh_mount_labels()
	if is_instance_valid(name_label):
		name_label.text = p_name
	var faction_color := Color.WHITE
	match p_faction:
		"Hồng Bàng": faction_color = Color(0.15, 0.85, 0.55, 1.0)
		"Thăng Long": faction_color = Color(0.15, 0.75, 0.95, 1.0)
		"Đông A": faction_color = Color(0.95, 0.45, 0.2, 1.0)
		"Đại Nam": faction_color = Color(0.95, 0.4, 0.65, 1.0)
	var faction_background := Color(faction_color.r * 0.32, faction_color.g * 0.32, faction_color.b * 0.32, 0.96)
	var rail_style := health_rail.get_theme_stylebox("panel") as StyleBoxFlat
	if rail_style:
		rail_style = rail_style.duplicate() as StyleBoxFlat
		rail_style.bg_color = faction_background
		rail_style.border_color = faction_color
		health_rail.add_theme_stylebox_override("panel", rail_style)
	var banner_style := top_banner.get_theme_stylebox("panel") as StyleBoxFlat
	if banner_style:
		banner_style = banner_style.duplicate() as StyleBoxFlat
		banner_style.bg_color = faction_background
		top_banner.add_theme_stylebox_override("panel", banner_style)
	current_hp = p_hp
	max_hp = p_max_hp
	has_initialized_hp = true

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
	if is_instance_valid(seat_label):
		seat_label.text = str(p_seat) if p_seat > 0 else ""
		seat_label.visible = p_seat > 0

	_apply_team_presentation(p_role)

	# Tải ảnh chân dung tướng nếu có (ưu tiên bản tách nền trong suốt)
	var trans_path = "res://assets/heroes_transparent/" + p_id + ".png"
	var tex_path = "res://assets/ui/" + p_id + ".png"
	if ResourceLoader.exists(trans_path) and is_instance_valid(portrait_rect):
		portrait_rect.texture = load(trans_path)
	elif ResourceLoader.exists(tex_path) and is_instance_valid(portrait_rect):
		portrait_rect.texture = load(tex_path)

	update_hp(current_hp, max_hp, true)
	update_hand_count(hand_count)

const LOTUS_FULL_TEX = preload("res://assets/ui/lotus_full.png")
const LOTUS_EMPTY_TEX = preload("res://assets/ui/lotus_empty.png")

func update_hp(p_hp: int, p_max_hp: int, is_initial: bool = false) -> void:
	var old_hp = current_hp
	current_hp = clamp(p_hp, 0, p_max_hp)
	max_hp = p_max_hp
	# A revived general must immediately leave the near-death pulse, regardless of
	# whether the heal came from a local rescue or a synchronized server update.
	if current_hp > 0 and (near_death_tween or (near_death_halo and near_death_halo.visible)):
		set_near_death(false)

	var is_first = is_initial or (not has_initialized_hp)
	has_initialized_hp = true

	# Tự động kích hoạt hiệu ứng mất máu nếu HP giảm và KHÔNG PHẢI lần khởi tạo đầu tiên, và không phải đang đầy máu
	if not is_first and old_hp > 0 and current_hp < old_hp and current_hp < max_hp:
		var dmg = old_hp - current_hp
		if Time.get_ticks_msec() - last_damage_effect_time > 300:
			play_damage_effect()
			spawn_damage_number(dmg)
	elif not is_first and current_hp > old_hp:
		play_heal_effect()
		spawn_heal_number(current_hp - old_hp)

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

		# Hiệu ứng nổ/vỡ của hoa sen khi mất máu hoặc nở rực khi hồi máu
		if not is_first and old_hp != current_hp and current_hp <= max_hp and current_hp >= 0:
			var anim_idx = clamp(current_hp if current_hp < old_hp else current_hp - 1, 0, max_hp - 1)
			if anim_idx < lotus_container.get_child_count():
				var anim_tr = lotus_container.get_child(anim_idx)
				if is_instance_valid(anim_tr):
					var tw = create_tween()
					if current_hp < old_hp:
						anim_tr.modulate = Color(3.0, 0.3, 0.3, 1.0)
						tw.tween_property(anim_tr, "scale", Vector2(1.65, 1.65), 0.12).set_trans(Tween.TRANS_BACK)
						tw.tween_property(anim_tr, "scale", Vector2(1.0, 1.0), 0.18)
						tw.parallel().tween_property(anim_tr, "modulate", Color(1, 1, 1, 0.75), 0.25)
					else:
						anim_tr.modulate = Color(0.4, 2.5, 0.8, 1.0)
						tw.tween_property(anim_tr, "scale", Vector2(1.5, 1.5), 0.12).set_trans(Tween.TRANS_BACK)
						tw.tween_property(anim_tr, "scale", Vector2(1.0, 1.0), 0.18)
						tw.parallel().tween_property(anim_tr, "modulate", Color(1, 1, 1, 1.0), 0.25)

func update_hand_count(count: int) -> void:
	hand_count = count
	if is_instance_valid(hand_count_label):
		hand_count_label.text = "🎴 %d" % hand_count

func update_an_tich_count(count: int) -> void:
	an_tich_count = max(0, count)
	if is_instance_valid(an_tich_count_label):
		an_tich_count_label.text = "%d Ẩn" % an_tich_count
		an_tich_count_label.get_parent().visible = an_tich_count > 0

func _on_mouse_entered() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_SINE)
