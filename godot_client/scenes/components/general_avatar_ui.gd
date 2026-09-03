extends Control

signal clicked()
signal skill_clicked()

@onready var portrait_rect: TextureRect = $Frame/Portrait
@onready var name_label: Label = $Frame/TopBanner/Margin/HBox/NameLabel
@onready var role_badge: Label = $Frame/TopBanner/Margin/HBox/RoleBadge
@onready var faction_badge: Label = $Frame/BottomBanner/Margin/HBox/FactionBadge
@onready var hp_label: Label = $Frame/BottomBanner/Margin/HBox/HpLabel
@onready var hand_count_label: Label = $Frame/HandBadge/HandLabel
@onready var target_border: ReferenceRect = $TargetBorder
@onready var skill_btn: Button = $SkillBtn
@onready var click_btn: Button = $ClickBtn

var general_id: String = "tran_hung_dao"
var current_hp: int = 4
var max_hp: int = 4
var hand_count: int = 4

func _ready() -> void:
	if click_btn:
		click_btn.pressed.connect(_on_avatar_clicked)
		click_btn.mouse_entered.connect(_on_mouse_entered)
		click_btn.mouse_exited.connect(_on_mouse_exited)

	if skill_btn:
		skill_btn.pressed.connect(func(): skill_clicked.emit())

func _on_avatar_clicked() -> void:
	clicked.emit()

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
