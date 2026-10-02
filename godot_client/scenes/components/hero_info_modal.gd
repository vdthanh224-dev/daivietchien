extends Control

signal closed()

@onready var dark_mask: ColorRect = $DarkMask
@onready var modal_box: PanelContainer = $Dim/Box
@onready var modal_title: Label = $Dim/Box/Margin/VBox/HeaderHBox/ModalTitle
@onready var team_badge: PanelContainer = $Dim/Box/Margin/VBox/HeaderHBox/TeamBadge
@onready var team_badge_label: Label = $Dim/Box/Margin/VBox/HeaderHBox/TeamBadge/Label
@onready var close_x_btn: Button = $Dim/Box/Margin/VBox/HeaderHBox/CloseXBtn

# Left Column (Hero Card)
@onready var portrait_card: PanelContainer = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard
@onready var card_background: TextureRect = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard/CardBg
@onready var hero_portrait: TextureRect = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard/HeroPortrait
@onready var dynasty_badge: PanelContainer = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard/DynastyBadge
@onready var dynasty_label: Label = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard/DynastyBadge/Label
@onready var hero_name_label: Label = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/PortraitCard/NameBanner/Margin/HeroName

# Stats
@onready var hp_icons_label: Label = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/StatsPanel/Margin/VBox/HpRow/HpIcons
@onready var hp_text_label: Label = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/StatsPanel/Margin/VBox/HpRow/HpText
@onready var hand_label: Label = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/StatsPanel/Margin/VBox/HandRow/HandLabel
@onready var status_badges_container: HBoxContainer = $Dim/Box/Margin/VBox/ContentHBox/LeftCol/StatsPanel/Margin/VBox/StatusRow

# Right Column (Skills & Equipment)
@onready var skills_container: VBoxContainer = $Dim/Box/Margin/VBox/ContentHBox/RightCol/SkillsSection/Scroll/SkillsList
@onready var eq_weapon_label: RichTextLabel = $Dim/Box/Margin/VBox/ContentHBox/RightCol/EquipSection/EquipGrid/SlotWeapon/Margin/RichText
@onready var eq_armor_label: RichTextLabel = $Dim/Box/Margin/VBox/ContentHBox/RightCol/EquipSection/EquipGrid/SlotArmor/Margin/RichText
@onready var eq_off_horse_label: RichTextLabel = $Dim/Box/Margin/VBox/ContentHBox/RightCol/EquipSection/EquipGrid/SlotOffHorse/Margin/RichText
@onready var eq_def_horse_label: RichTextLabel = $Dim/Box/Margin/VBox/ContentHBox/RightCol/EquipSection/EquipGrid/SlotDefHorse/Margin/RichText
@onready var eq_treasure_label: RichTextLabel = $Dim/Box/Margin/VBox/ContentHBox/RightCol/EquipSection/EquipGrid/SlotTreasure/Margin/RichText

@onready var close_modal_btn: Button = $Dim/Box/Margin/VBox/FooterHBox/CloseModalBtn

const BG_DRAGON_TEX = preload("res://assets/ui/hero_backgrounds/bg_hero_green.png")
const BG_PHOENIX_TEX = preload("res://assets/ui/hero_backgrounds/bg_hero_red.png")

var is_animating := false

func _ready() -> void:
	visible = false
	if is_instance_valid(close_x_btn):
		close_x_btn.pressed.connect(close_modal)
	if is_instance_valid(close_modal_btn):
		close_modal_btn.pressed.connect(close_modal)
	if is_instance_valid(dark_mask):
		dark_mask.gui_input.connect(_on_dark_mask_gui_input)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_modal()

func _on_dark_mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()

func open_modal() -> void:
	if is_animating:
		return
	is_animating = true
	visible = true
	modulate.a = 0.0

	if is_instance_valid(modal_box):
		modal_box.scale = Vector2(0.92, 0.92)
		modal_box.pivot_offset = modal_box.size * 0.5

	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(modal_box):
		tw.tween_property(modal_box, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): is_animating = false)

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_card_select"):
		audio_mgr.play_card_select()

func close_modal() -> void:
	if not visible or is_animating:
		return
	is_animating = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if is_instance_valid(modal_box):
		tw.tween_property(modal_box, "scale", Vector2(0.94, 0.94), 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		visible = false
		is_animating = false
		closed.emit()
	)
	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr and audio_mgr.has_method("play_card_select"):
		audio_mgr.play_card_select()

# Main Entry Point to display hero information
func display_general(g: Dictionary, my_seat: int = 1) -> void:
	if g.is_empty():
		return

	var seat_num = int(g.get("seat", 1))
	var is_dragon = bool(g.get("isDragon", true))
	var is_player = bool(g.get("isPlayer", false)) or (seat_num == my_seat)
	var hero_name = str(g.get("name", "Vô Danh"))
	var faction = str(g.get("faction", "Đại Việt"))
	var hero_id = int(g.get("hero_id", 47))
	var current_hp = int(g.get("hp", 4))
	var max_hp = int(g.get("max_hp", 4))
	var hand_count = int(g.get("hand_count", 0))
	var is_chained = bool(g.get("is_chained", false))
	var is_alive = bool(g.get("is_alive", true))

	# 1. Header & Team Badge
	var role_name := ""
	if is_player:
		role_name = "BẠN"
	elif (seat_num % 2) == (my_seat % 2):
		role_name = "ĐỒNG MINH"
	else:
		role_name = "ĐỐI THỦ"

	var team_title = "PHE RỒNG" if is_dragon else "PHE PHƯỢNG"
	var team_icon = "🐉" if is_dragon else "🦅"
	if is_instance_valid(team_badge_label):
		team_badge_label.text = "%s %s • GHẾ %d (%s)" % [team_icon, team_title, seat_num, role_name]

	_style_team_badge(is_dragon)

	# 2. Left Column: Hero Card & Texture
	var slug := ""
	var hero_db = get_node_or_null("/root/HeroDatabase")
	if hero_db and hero_db.has_method("get_hero"):
		var db_h = hero_db.get_hero(hero_id)
		if db_h is Dictionary:
			slug = str(db_h.get("slug", ""))
			if faction == "Đại Việt" or faction == "":
				faction = str(db_h.get("faction", faction))
	if slug.is_empty():
		slug = str(hero_id)

	# Faction Background behind portrait
	if is_instance_valid(card_background):
		card_background.texture = BG_DRAGON_TEX if is_dragon else BG_PHOENIX_TEX

	# Hero Portrait (Prioritize transparent cutout)
	var trans_path = "res://assets/heroes_transparent/" + slug + ".png"
	var standard_path = "res://assets/ui/" + slug + ".png"
	if is_instance_valid(hero_portrait):
		if ResourceLoader.exists(trans_path):
			hero_portrait.texture = load(trans_path)
		elif ResourceLoader.exists(standard_path):
			hero_portrait.texture = load(standard_path)
		elif hero_db and hero_db.has_method("get_avatar_texture"):
			hero_portrait.texture = hero_db.get_avatar_texture("")

	# Dynasty & Hero Name
	if is_instance_valid(dynasty_label):
		dynasty_label.text = faction
	if is_instance_valid(hero_name_label):
		hero_name_label.text = hero_name

	# HP Blossoms Display
	_update_hp_display(current_hp, max_hp)

	# Hand count
	if is_instance_valid(hand_label):
		hand_label.text = "🎴 Bài trên tay: %d lá" % hand_count

	# Status Badges
	_update_status_badges(is_alive, current_hp, max_hp, is_chained)

	# 3. Right Column: Skills
	_populate_skills(hero_id, g)

	# 4. Right Column: Equipment
	_populate_equipments(g)

	open_modal()

func _style_team_badge(is_dragon: bool) -> void:
	if not is_instance_valid(team_badge):
		return
	var style = StyleBoxFlat.new()
	if is_dragon:
		style.bg_color = Color(0.06, 0.22, 0.16, 0.95)
		style.border_color = Color(0.32, 0.85, 0.58, 1.0)
		if is_instance_valid(team_badge_label):
			team_badge_label.add_theme_color_override("font_color", Color(0.65, 0.98, 0.82, 1.0))
	else:
		style.bg_color = Color(0.28, 0.08, 0.1, 0.95)
		style.border_color = Color(0.95, 0.35, 0.42, 1.0)
		if is_instance_valid(team_badge_label):
			team_badge_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.8, 1.0))
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	team_badge.add_theme_stylebox_override("panel", style)

func _update_hp_display(current_hp: int, max_hp: int) -> void:
	if is_instance_valid(hp_icons_label):
		var lotus_str := ""
		for i in range(max_hp):
			if i < current_hp:
				lotus_str += "🪷 "
			else:
				lotus_str += "🥀 "
		hp_icons_label.text = lotus_str.strip_edges()
	if is_instance_valid(hp_text_label):
		hp_text_label.text = "%d/%d đóa sen" % [current_hp, max_hp]
		var col = Color(0.4, 0.95, 0.6) if current_hp > 1 else Color(1.0, 0.35, 0.35)
		hp_text_label.add_theme_color_override("font_color", col)

func _update_status_badges(is_alive: bool, current_hp: int, max_hp: int, is_chained: bool) -> void:
	if not is_instance_valid(status_badges_container):
		return
	for c in status_badges_container.get_children():
		c.queue_free()

	if not is_alive or current_hp <= 0:
		_add_status_pill("⚠️ CẬN TỬ", Color(0.85, 0.15, 0.2, 0.9), Color(1, 0.4, 0.4))
	elif current_hp == 1:
		_add_status_pill("⚡ NGUY CẤP", Color(0.8, 0.45, 0.1, 0.9), Color(1, 0.8, 0.4))
	elif current_hp < max_hp:
		_add_status_pill("⚔️ BỊ THƯƠNG", Color(0.65, 0.35, 0.1, 0.9), Color(1.0, 0.65, 0.3))
	else:
		_add_status_pill("🛡️ KHỎE MẠNH", Color(0.08, 0.32, 0.18, 0.9), Color(0.5, 0.95, 0.65))

	if is_chained:
		_add_status_pill("⛓️ XÍCH TỎA", Color(0.65, 0.3, 0.05, 0.95), Color(1, 0.7, 0.2))

func _add_status_pill(text: String, bg_col: Color, border_col: Color) -> void:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_color = border_col
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)

	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	panel.add_child(lbl)
	status_badges_container.add_child(panel)

func _populate_skills(hero_id: int, g: Dictionary) -> void:
	if not is_instance_valid(skills_container):
		return
	for c in skills_container.get_children():
		c.queue_free()

	var skills = []
	var hero_db = get_node_or_null("/root/HeroDatabase")
	if hero_db and hero_db.has_method("get_hero_skills"):
		skills = hero_db.get_hero_skills(hero_id)

	if skills.is_empty():
		# Default fallback skill
		skills = [{
			"name": "Dũng Tướng",
			"desc": "Tướng lĩnh uy phong lẫm liệt, dốc lòng vì giang sơn Đại Việt.",
			"type": "BỊ ĐỘNG"
		}]

	for skill in skills:
		if not (skill is Dictionary):
			continue
		var s_name = str(skill.get("name", "Kỹ năng"))
		var s_desc = str(skill.get("desc", ""))
		var s_type = _determine_skill_type(s_name, s_desc, skill)

		var card = _create_skill_card_ui(s_name, s_desc, s_type)
		skills_container.add_child(card)

func _determine_skill_type(s_name: String, s_desc: String, skill: Dictionary) -> String:
	if skill.has("type") and str(skill.get("type", "")).strip_edges() != "":
		return str(skill.get("type")).to_upper()
	var lower = (s_name + " " + s_desc).to_lower()
	if "bật:" in lower or "trong giai đoạn" in lower or "một lần mỗi lượt" in lower or "có thể dùng" in lower or "chủ động" in lower:
		return "CHỦ ĐỘNG"
	elif "khóa:" in lower or "vô hiệu hóa" in lower or "miễn nhiễm" in lower:
		return "KHÓA / MIỄN"
	elif "khi rơi vào" in lower or "khi mất máu" in lower or "khi bị" in lower or "sau khi" in lower or "khi dùng trảm" in lower:
		return "PHẢN ỨNG / BỊ ĐỘNG"
	return "BỊ ĐỘNG"

func _create_skill_card_ui(s_name: String, s_desc: String, s_type: String) -> Control:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.09, 0.15, 0.95)
	style.border_color = Color(0.85, 0.72, 0.32, 0.6)
	style.border_width_left = 2
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	panel.add_child(vbox)

	# Header: Type Tag + Skill Name
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var tag_panel = PanelContainer.new()
	var tag_style = StyleBoxFlat.new()
	var tag_text_color = Color(1, 1, 1)
	match s_type:
		"CHỦ ĐỘNG":
			tag_style.bg_color = Color(0.08, 0.28, 0.45, 0.95)
			tag_style.border_color = Color(0.3, 0.75, 1.0, 0.9)
			tag_text_color = Color(0.7, 0.92, 1.0)
		"KHÓA / MIỄN":
			tag_style.bg_color = Color(0.32, 0.1, 0.4, 0.95)
			tag_style.border_color = Color(0.85, 0.4, 0.95, 0.9)
			tag_text_color = Color(0.95, 0.75, 1.0)
		_:
			tag_style.bg_color = Color(0.38, 0.24, 0.05, 0.95)
			tag_style.border_color = Color(1.0, 0.78, 0.25, 0.9)
			tag_text_color = Color(1.0, 0.92, 0.65)
	tag_style.border_width_left = 1
	tag_style.border_width_top = 1
	tag_style.border_width_right = 1
	tag_style.border_width_bottom = 1
	tag_style.corner_radius_top_left = 6
	tag_style.corner_radius_top_right = 6
	tag_style.corner_radius_bottom_right = 6
	tag_style.corner_radius_bottom_left = 6
	tag_style.content_margin_left = 6
	tag_style.content_margin_right = 6
	tag_style.content_margin_top = 1
	tag_style.content_margin_bottom = 1
	tag_panel.add_theme_stylebox_override("panel", tag_style)

	var tag_lbl = Label.new()
	tag_lbl.text = s_type
	tag_lbl.add_theme_font_size_override("font_size", 10)
	tag_lbl.add_theme_color_override("font_color", tag_text_color)
	tag_panel.add_child(tag_lbl)
	header.add_child(tag_panel)

	var name_lbl = Label.new()
	name_lbl.text = s_name
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	header.add_child(name_lbl)

	# Description RichTextLabel
	var desc_lbl = RichTextLabel.new()
	desc_lbl.bbcode_enabled = true
	desc_lbl.text = _format_bbcode_keywords(s_desc)
	desc_lbl.fit_content = true
	desc_lbl.scroll_active = false
	desc_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	desc_lbl.add_theme_font_size_override("normal_font_size", 12)
	desc_lbl.add_theme_color_override("default_color", Color(0.88, 0.91, 0.95, 1.0))
	vbox.add_child(desc_lbl)

	return panel

func _format_bbcode_keywords(text: String) -> String:
	var result = text
	# Highlight Card Names
	var card_keywords = ["Trảm", "Trảm - Hỏa", "Trảm - Lôi", "Trảm - Thủy", "Đỡ", "Hủ Rượu", "Bánh Chưng", "Đào", "Vô Trung Sinh Hữu", "Vườn Không Nhà Trống", "Mưa Tên Liên Châu", "Giặc Tới", "Diệu Kế Phá Mưu", "Xích Tâm Tỏa", "Thuận Thủ Khiên Dương", "Quá Hà Táp Kiều", "Lạc Bất Tư Thục"]
	for kw in card_keywords:
		result = result.replace("[%s]" % kw, "[b][color=#FFB74D][%s][/color][/b]" % kw)
		result = result.replace("lá %s" % kw, "lá [b][color=#FFB74D]%s[/color][/b]" % kw)
		result = result.replace("chiêu %s" % kw, "chiêu [b][color=#FFB74D]%s[/color][/b]" % kw)

	# Highlight Game terms
	result = result.replace("Máu", "[color=#EF5350][b]Máu[/b][/color]")
	result = result.replace("sát thương", "[color=#EF5350][b]sát thương[/b][/color]")
	result = result.replace("Cận Tử", "[color=#E53935][b]Cận Tử[/b][/color]")
	result = result.replace("Phán xét", "[color=#FFD54F][b]Phán xét[/b][/color]")
	result = result.replace("trang bị", "[color=#81D4FA][b]trang bị[/b][/color]")
	result = result.replace("rút", "[color=#A5D6A7][b]rút[/b][/color]")
	return result

func _populate_equipments(g: Dictionary) -> void:
	var w = str(g.get("equipped_weapon", ""))
	var a = str(g.get("equipped_armor", ""))
	var om = str(g.get("equipped_off_horse", ""))
	var dm = str(g.get("equipped_def_horse", ""))
	var tr = str(g.get("equipped_treasure", ""))

	# Also check avatar_node if fields in g are empty
	var avatar = g.get("avatar_node", null)
	if is_instance_valid(avatar) and avatar.get("equipped_items") is Dictionary:
		var items: Dictionary = avatar.equipped_items
		if w.is_empty(): w = str(items.get("weapon", ""))
		if a.is_empty(): a = str(items.get("armor", ""))
		if om.is_empty(): om = str(items.get("off_horse", items.get("offensive_mount", "")))
		if dm.is_empty(): dm = str(items.get("def_horse", items.get("defensive_mount", "")))
		if tr.is_empty(): tr = str(items.get("treasure", ""))

	_format_slot(eq_weapon_label, "🗡️", "Vũ Khí", w, "#FFD54F")
	_format_slot(eq_armor_label, "🛡️", "Phòng Cụ", a, "#4FC3F7")
	_format_slot(eq_off_horse_label, "🐎", "Chiến Mã (Công -1)", om, "#FF8A65")
	_format_slot(eq_def_horse_label, "🐘", "Chiến Mã (Thủ +1)", dm, "#81C784")
	_format_slot(eq_treasure_label, "👑", "Thần Khí", tr, "#BA68C8")

func _format_slot(label: RichTextLabel, icon: String, slot_title: String, item_str: String, accent_hex: String) -> void:
	if not is_instance_valid(label):
		return
	var clean: String = item_str.strip_edges()
	if clean.is_empty() or clean == "(Chưa trang bị)":
		label.text = "[b][color=#6E7D8F]%s %s:[/color][/b] [color=#525E6B](Trống)[/color]" % [icon, slot_title]
		return

	var parts = clean.split(" ", false, 1)
	var suit_part: String = ""
	var name_part: String = clean
	if parts.size() >= 2 and (parts[0].begins_with("♠") or parts[0].begins_with("♥") or parts[0].begins_with("♦") or parts[0].begins_with("♣")):
		suit_part = parts[0]
		name_part = parts[1]

	var formatted_name := ""
	if suit_part != "":
		var is_red = ("♥" in suit_part or "♦" in suit_part)
		var suit_col = "#FF5252" if is_red else "#ECEFF1"
		formatted_name = "[color=%s][b]%s[/b][/color] [color=%s][b]%s[/b][/color]" % [suit_col, suit_part, accent_hex, name_part]
	else:
		formatted_name = "[color=%s][b]%s[/b][/color]" % [accent_hex, name_part]

	var desc = _get_equipment_description(name_part)
	label.text = "[b][color=%s]%s %s:[/color][/b] %s\n[color=#90CAF9]↳ %s[/color]" % [accent_hex, icon, slot_title, formatted_name, desc]

func _get_equipment_description(item_name: String) -> String:
	match item_name:
		"Kiếm Thuận Thiên": return "Tầm 2 • Trảm bỏ qua giáp mục tiêu."
		"Song Cung Mường Nhạ": return "Tầm 2 • Trảm bị Đỡ, bỏ 2 lá để bỏ qua Đỡ (Trảm vẫn trúng)."
		"Nỏ Thần Kim Quy": return "Tầm 1 • Không giới hạn số lá Trảm trong lượt."
		"Trường Đao Nam Sơn": return "Tầm 3 • Khi Trảm bị Đỡ, không mất lượt dùng Trảm."
		"Thương Ngâu Lãng Bạc": return "Tầm 4 • Trảm trúng hủy 1 lá trên tay hoặc trang bị."
		"Súng Thần Công Hồ Triều": return "Tầm 5 • Mục tiêu không được Đỡ cùng màu với Trảm."
		"Hỏa Mai Tây Sơn": return "Tầm 4 • Trảm Thường có thể xem như Trảm Hỏa."
		"Liêm Đao Đống Đa": return "Tầm 2 • Lần đầu mỗi lượt gây sát thương, rút 1 lá."
		"Đoản Đao Lam Sơn": return "Tầm 2 • Trảm trúng có thể hủy 2 lá bài thay vì gây sát thương."
		"Giáp Đồng Sơn Vi": return "Vô hiệu hóa toàn bộ Trảm Thường."
		"Giáp Tây Sơn": return "Vô hiệu hóa mọi Trảm màu Đen (Bích hoặc Chuồn)."
		"Khiên Mây Bện": return "Khi cần Đỡ, lật bài phán xét Đỏ tự động Đỡ."
		"Áo Bào Hoàng Tộc": return "Chặn tối đa 2 sát thương, sau đó bị hủy."
		"Voi Chiến Đại Việt": return "+1 Khoảng cách phòng thủ (người khác tới bạn)."
		"Ngựa Trắng Thuần Nông": return "-1 Khoảng cách tấn công (bạn tới người khác)."
		"Thuyền Bạch Đằng": return "Trảm Thủy bỏ qua khoảng cách."
		"Trống Đồng Đông Sơn": return "Điểm Trống: Buộc mục tiêu bỏ 1 lá hoặc lộ bài."
		"Hổ Phù Trần Triều": return "Cho 1 lá bài; nếu họ dùng trước lượt kế tiếp, bạn rút 1 lá."
		_:
			if "đao" in item_name.to_lower() or "kiếm" in item_name.to_lower():
				return "Vũ khí cận chiến sắc bén, gia tăng uy lực đòn Trảm."
			elif "giáp" in item_name.to_lower() or "khiên" in item_name.to_lower():
				return "Bảo vệ danh tướng, triệt tiêu sát thương từ đòn đánh đối phương."
			elif "ngựa" in item_name.to_lower() or "voi" in item_name.to_lower():
				return "Chiến thú trợ trận, cải thiện khoảng cách chiến lược."
			return "Bảo vật linh thiêng phù trợ tướng quân trong chiến trận."
