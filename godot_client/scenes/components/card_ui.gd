class_name CardUI
extends Control

signal card_clicked(card_ui: Control)
signal card_selected_state_changed(card_ui: Control, is_selected: bool)

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")

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

func _ready() -> void:
	if click_button:
		click_button.pressed.connect(_on_card_button_pressed)
		click_button.mouse_entered.connect(_on_card_mouse_entered)
		click_button.mouse_exited.connect(_on_card_mouse_exited)

	if card_data:
		update_card(card_data)

func setup_card_data(id: String, p_name: String, rank_val: Variant, suit_str: String, cat: int, desc: String) -> void:
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
	res.description = desc
	update_card(res)

func update_card(data: Resource) -> void:
	card_data = data
	card_name = data.card_name
	if not is_inside_tree():
		return

	var suit_sym = data.get_suit_symbol()
	var rank_str = data.get_rank_string()
	suit_rank_lbl.text = "%s %s" % [suit_sym, rank_str]
	var s_col = data.get_suit_color()
	suit_rank_lbl.add_theme_color_override("font_color", s_col)

	cat_lbl.text = data.get_category_name()
	name_lbl.text = data.card_name

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
		z_index = 10
	else:
		z_index = 0
		if is_hovered:
			_animate_elevation(-4.0, Vector2(1.02, 1.02))
		else:
			_animate_elevation(0.0, Vector2(1.0, 1.0))

	card_selected_state_changed.emit(self, is_selected)

func _animate_elevation(target_y: float, target_scale: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", target_y, 0.15)
	tween.tween_property(self, "scale", target_scale, 0.15)
