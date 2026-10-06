class_name CardUI
extends Control

signal card_clicked(card_ui: Control)
signal card_selected_state_changed(card_ui: Control, is_selected: bool)

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")
const CardDatabaseScript = preload("res://scripts/resources/card_database.gd")

@export var card_data: Resource

@onready var panel: Panel = $Panel
@onready var suit_rank_lbl: Label = $Panel/Margin/VBox/SubHeader/SuitRankLabel
@onready var cat_lbl: Label = $Panel/Margin/VBox/SubHeader/CategoryLabel
@onready var name_lbl: Label = $Panel/Margin/VBox/NameBanner/NameLabel
@onready var artwork_rect: TextureRect = $Panel/Margin/VBox/Artwork
@onready var border: ReferenceRect = $Panel/Border
@onready var glow_border: ReferenceRect = $Panel/GlowBorder
@onready var click_button: Button = $ClickButton

var is_selected: bool = false
var is_hovered: bool = false
var original_y: float = 0.0
var tween: Tween
var card_name: String = ""
var equipped_badge: Label = null

func _ready() -> void:
	if click_button:
		click_button.pressed.connect(_on_card_button_pressed)
		click_button.mouse_entered.connect(_on_card_mouse_entered)
		click_button.mouse_exited.connect(_on_card_mouse_exited)

	if card_data:
		update_card(card_data)

func setup_card_data(id: String, p_name: String, rank_val: Variant, suit_str: String, cat: int, desc: String, sub_type_val: int = -1) -> void:
	card_name = p_name
	var res = CardResourceScript.new()
	res.id = id
	res.card_name = p_name
	res.suit = suit_str
	var r_str = str(rank_val).to_upper()
	match r_str:
		"A", "1": res.rank = 1
		"J", "11": res.rank = 11
		"Q", "12": res.rank = 12
		"K", "13": res.rank = 13
		_: res.rank = r_str.to_int()
	res.category = cat
	if sub_type_val >= 0:
		res.sub_type = sub_type_val as CardResourceScript.CardSubType
	else:
		res.sub_type = _infer_sub_type_from_name(p_name)
		if cat == 0:
			res.category = _infer_category_from_name(p_name)
	res.description = desc
	update_card(res)

static func _infer_sub_type_from_name(p_name: String) -> int:
	var n = p_name.to_lower()
	if "hỏa" in n and "trảm" in n: return CardResourceScript.CardSubType.TRAM_HOA
	if ("thủy" in n or "thuy" in n) and ("trảm" in n or "tram" in n): return CardResourceScript.CardSubType.TRAM_THUY
	if "trảm" in n: return CardResourceScript.CardSubType.TRAM
	if "đỡ" in n: return CardResourceScript.CardSubType.DO
	if "bánh chưng" in n: return CardResourceScript.CardSubType.BANH_CHUNG
	if "rượu" in n: return CardResourceScript.CardSubType.HU_RUOU
	if "khiên mây" in n or "áo bào" in n or "giáp đồng" in n: return CardResourceScript.CardSubType.AO_GIAP
	if "thuận thiên" in n or "song cung" in n or "nỏ thần" in n or "trường đao" in n or "thương ngâu" in n or "súng thần công" in n: return CardResourceScript.CardSubType.VU_KHI
	if "ngựa trắng" in n: return CardResourceScript.CardSubType.NGUA_CONG
	if "voi chiến" in n: return CardResourceScript.CardSubType.NGUA_THU
	if "trống đồng" in n or "bảo vật" in n: return CardResourceScript.CardSubType.BRONZE_DRUM
	if "diệu kế" in n: return CardResourceScript.CardSubType.DIEU_KE
	if "vườn không" in n: return CardResourceScript.CardSubType.VUON_KHONG
	if "đột kích" in n: return CardResourceScript.CardSubType.DOT_KICH
	if "dụng binh" in n: return CardResourceScript.CardSubType.DUNG_BINH
	if "huyết chiến" in n or "quyết đấu" in n or "thách đấu" in n: return CardResourceScript.CardSubType.HUYET_CHIEN
	if "xích" in n or "tỏa" in n: return CardResourceScript.CardSubType.XICH_TAM_TOA
	if "mở kho" in n: return CardResourceScript.CardSubType.MO_KHO_CUU_TE
	if "giặc tới" in n: return CardResourceScript.CardSubType.GIAC_TOI
	if "mưa tên" in n or "vạn tiễn" in n: return CardResourceScript.CardSubType.MUA_TEN
	if "đại hồng thủy" in n: return CardResourceScript.CardSubType.DAI_HONG_THUY
	if "cắt lương" in n: return CardResourceScript.CardSubType.CAT_LUONG
	if "trầm ảo" in n: return CardResourceScript.CardSubType.TRAM_AO
	if "bãi cọc" in n: return CardResourceScript.CardSubType.BAI_COC_BACH_DANG
	if "thủy triều" in n: return CardResourceScript.CardSubType.THUY_TRIEU_RUT
	if "mượn gươm" in n: return CardResourceScript.CardSubType.MUON_GUOM_DIET_DICH
	if "mở yến tiệc" in n: return CardResourceScript.CardSubType.MO_YEN_TIEC
	if "hịch tướng sĩ" in n: return CardResourceScript.CardSubType.HICH_TUONG_SI
	if "khổ nhục" in n: return CardResourceScript.CardSubType.KHO_NHUC_KE
	if "tẩu vi" in n: return CardResourceScript.CardSubType.TAU_VI_THUONG_SACH
	if "phủ để" in n: return CardResourceScript.CardSubType.PHU_DE_TRUU_TAN
	return CardResourceScript.CardSubType.TRAM

static func _infer_category_from_name(p_name: String) -> int:
	var n = p_name.to_lower()
	if "khiên mây" in n or "áo bào" in n or "giáp đồng" in n or "thuận thiên" in n or "song cung" in n or "nỏ thần" in n or "trường đao" in n or "thương ngâu" in n or "súng thần công" in n or "ngựa trắng" in n or "voi chiến" in n or "trống đồng" in n or "bảo vật" in n:
		return CardResourceScript.CardCategory.TRANG_BI
	if "đại hồng thủy" in n or "cắt lương" in n or "trầm ảo" in n or "bãi cọc" in n:
		return CardResourceScript.CardCategory.TRI_HOAN
	if "diệu kế" in n or "vườn không" in n or "đột kích" in n or "dụng binh" in n or "huyết chiến" in n or "quyết đấu" in n or "thách đấu" in n or "xích" in n or "mở kho" in n or "giặc tới" in n or "mưa tên" in n or "vạn tiễn" in n or "thủy triều" in n or "mượn gươm" in n or "mở yến tiệc" in n or "hịch tướng sĩ" in n or "khổ nhục" in n or "tẩu vi" in n or "phủ để" in n:
		return CardResourceScript.CardCategory.CAM_NANG
	return CardResourceScript.CardCategory.CO_BAN

func update_card(data: Resource) -> void:
	card_data = data
	card_name = data.card_name
	# Keep the hover tooltip aligned with the canonical local card description.
	if not str(data.id).is_empty():
		var database_card = CardDatabaseScript.get_card(str(data.id))
		if database_card != null and not str(database_card.description).is_empty():
			data.description = database_card.description
	if not is_inside_tree():
		return

	var rank_str = data.get_rank_string()
	var suit_name = data.get_suit_name() if data.has_method("get_suit_name") else ""
	if suit_name != "":
		suit_rank_lbl.text = "%s %s" % [rank_str, suit_name]
	else:
		suit_rank_lbl.text = rank_str
	UIScaleManager.scale_node_font(suit_rank_lbl, 11)

	_apply_card_theme(data)

	cat_lbl.text = data.get_category_name()
	name_lbl.text = data.card_name
	var base_card_font: int = 13
	if data.card_name.length() >= 14:
		base_card_font = 9
	elif data.card_name.length() >= 10:
		base_card_font = 11
	UIScaleManager.scale_node_font(name_lbl, base_card_font)

	# Tải hình minh họa lá bài (Artwork)
	if artwork_rect:
		var art_path = ""
		if data.has_method("get_artwork_path"):
			art_path = data.get_artwork_path()
		if art_path != "" and ResourceLoader.exists(art_path):
			artwork_rect.texture = load(art_path)
			artwork_rect.visible = true
		else:
			artwork_rect.visible = false

	if click_button:
		var d_text = data.description if "description" in data and data.description != "" else data.card_name
		var full_suit_text = ("%s %s" % [rank_str, suit_name]) if suit_name != "" else rank_str
		click_button.tooltip_text = "[%s] %s\n%s" % [full_suit_text, data.card_name, d_text]

func _apply_card_theme(data: Resource) -> void:
	if not panel:
		return
	var p_box = panel.get_theme_stylebox("panel")
	var panel_style: StyleBoxFlat = p_box.duplicate() if p_box is StyleBoxFlat else StyleBoxFlat.new()
	var banner_node = $Panel/Margin/VBox/NameBanner
	var b_box = banner_node.get_theme_stylebox("panel") if banner_node else null
	var banner_style: StyleBoxFlat = b_box.duplicate() if b_box is StyleBoxFlat else StyleBoxFlat.new()

	var is_red = data.has_method("is_red") and data.is_red()
	var is_white = data.has_method("is_white") and data.is_white()
	var is_yellow = data.has_method("is_yellow") and data.is_yellow()
	var is_black = data.has_method("is_black") and data.is_black()

	if is_red:
		# LÁ BÀI ĐỎ: Màu đỏ thắm cổ phong, viền vàng kim
		panel_style.bg_color = Color(0.70, 0.16, 0.16, 1.0)
		panel_style.border_color = Color(0.96, 0.82, 0.38, 1.0)
		banner_style.bg_color = Color(0.44, 0.08, 0.08, 0.95)
		banner_style.border_color = Color(1.0, 0.85, 0.40, 0.9)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.85, 1.0))
		suit_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.50, 1.0))
		suit_rank_lbl.add_theme_color_override("font_outline_color", Color(0.28, 0.05, 0.05, 1.0))
		suit_rank_lbl.add_theme_constant_override("outline_size", 2)
		cat_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.72, 1.0))
		if border:
			border.border_color = Color(0.96, 0.82, 0.38, 0.85)

	elif is_white:
		# LÁ BÀI TRẮNG: Màu trắng ngà sáng thanh thoát, viền bạc xanh thép
		panel_style.bg_color = Color(0.96, 0.97, 0.98, 1.0)
		panel_style.border_color = Color(0.42, 0.50, 0.60, 1.0)
		banner_style.bg_color = Color(0.22, 0.28, 0.36, 0.95)
		banner_style.border_color = Color(0.60, 0.68, 0.78, 0.9)
		name_lbl.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
		suit_rank_lbl.add_theme_color_override("font_color", Color(0.12, 0.16, 0.22, 1.0))
		suit_rank_lbl.add_theme_color_override("font_outline_color", Color(0.85, 0.90, 0.96, 1.0))
		suit_rank_lbl.add_theme_constant_override("outline_size", 2)
		cat_lbl.add_theme_color_override("font_color", Color(0.30, 0.38, 0.48, 1.0))
		if border:
			border.border_color = Color(0.42, 0.50, 0.60, 0.85)

	elif is_yellow:
		# LÁ BÀI VÀNG: Màu vàng hoàng kim rực rỡ, viền vàng sáng
		panel_style.bg_color = Color(0.86, 0.66, 0.16, 1.0)
		panel_style.border_color = Color(1.0, 0.92, 0.55, 1.0)
		banner_style.bg_color = Color(0.46, 0.32, 0.05, 0.95)
		banner_style.border_color = Color(1.0, 0.88, 0.45, 0.9)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
		suit_rank_lbl.add_theme_color_override("font_color", Color(0.22, 0.14, 0.02, 1.0))
		suit_rank_lbl.add_theme_color_override("font_outline_color", Color(1.0, 0.94, 0.70, 1.0))
		suit_rank_lbl.add_theme_constant_override("outline_size", 2)
		cat_lbl.add_theme_color_override("font_color", Color(0.30, 0.20, 0.04, 1.0))
		if border:
			border.border_color = Color(1.0, 0.92, 0.55, 0.85)

	elif is_black:
		# LÁ BÀI ĐEN: Màu đen than obsidian quyền lực, viền bạc ánh trăng
		panel_style.bg_color = Color(0.15, 0.16, 0.19, 1.0)
		panel_style.border_color = Color(0.68, 0.72, 0.80, 1.0)
		banner_style.bg_color = Color(0.07, 0.08, 0.10, 0.95)
		banner_style.border_color = Color(0.55, 0.60, 0.70, 0.8)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))
		suit_rank_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 0.96, 1.0))
		suit_rank_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.07, 1.0))
		suit_rank_lbl.add_theme_constant_override("outline_size", 2)
		cat_lbl.add_theme_color_override("font_color", Color(0.70, 0.75, 0.82, 1.0))
		if border:
			border.border_color = Color(0.68, 0.72, 0.80, 0.85)

	panel.add_theme_stylebox_override("panel", panel_style)
	if banner_node:
		banner_node.add_theme_stylebox_override("panel", banner_style)

func _on_card_mouse_entered() -> void:
	is_hovered = true
	mouse_entered.emit()
	if not is_selected:
		_animate_elevation(-4.0, Vector2(1.02, 1.02))

func _on_card_mouse_exited() -> void:
	is_hovered = false
	mouse_exited.emit()
	if not is_selected:
		_animate_elevation(0.0, Vector2(1.0, 1.0))

func _on_card_button_pressed() -> void:
	set_selected(not is_selected)
	card_clicked.emit(self)

func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	is_selected = selected

	if glow_border:
		glow_border.visible = is_selected

	if is_selected:
		_animate_elevation(-10.0, Vector2(1.04, 1.04))
	else:
		if is_hovered:
			_animate_elevation(-4.0, Vector2(1.02, 1.02))
		else:
			_animate_elevation(0.0, Vector2(1.0, 1.0))

	card_selected_state_changed.emit(self, is_selected)

func set_equipped_badge(visible: bool) -> void:
	if visible and not is_instance_valid(equipped_badge):
		equipped_badge = Label.new()
		equipped_badge.name = "EquippedBadge"
		equipped_badge.text = "ĐANG MANG"
		equipped_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipped_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		equipped_badge.set_anchors_preset(Control.PRESET_TOP_WIDE)
		equipped_badge.offset_left = 5.0
		equipped_badge.offset_top = 62.0
		equipped_badge.offset_right = -5.0
		equipped_badge.offset_bottom = 90.0
		equipped_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		equipped_badge.z_index = 50
		UIScaleManager.scale_node_font(equipped_badge, 15)
		equipped_badge.add_theme_color_override("font_color", Color(1.0, 0.08, 0.08, 1.0))
		equipped_badge.add_theme_color_override("font_outline_color", Color(0.08, 0.0, 0.0, 1.0))
		equipped_badge.add_theme_constant_override("outline_size", 5)
		add_child(equipped_badge)
	if is_instance_valid(equipped_badge):
		equipped_badge.visible = visible

func _animate_elevation(target_y: float, target_scale: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", target_y, 0.15)
	tween.tween_property(self, "scale", target_scale, 0.15)
