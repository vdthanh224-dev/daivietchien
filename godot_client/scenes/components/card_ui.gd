class_name CardUI
extends Control

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")

signal card_clicked(card_ui: Control)
signal card_selected_state_changed(card_ui: Control, is_selected: bool)

@export var card_data: Resource

var card_name: String:
	get:
		return card_data.card_name if card_data else ""

@onready var panel: Panel = $Panel
@onready var suit_rank_lbl: Label = $Panel/Margin/VBox/Header/SuitRankLabel
@onready var cat_lbl: Label = $Panel/Margin/VBox/Header/CategoryLabel
@onready var name_lbl: Label = $Panel/Margin/VBox/NameLabel
@onready var desc_lbl: Label = $Panel/Margin/VBox/DescLabel
@onready var border: ReferenceRect = $Panel/Border

var is_selected: bool = false
var is_hovered: bool = false
var original_y: float = 0.0
var tween: Tween

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	if card_data:
		update_card(card_data)

func setup_card_data(id: String, p_name: String, rank_str: String, suit_str: String, cat: int, desc: String) -> void:
	var res = CardResourceScript.new()
	res.id = id
	res.card_name = p_name
	res.suit = suit_str
	match rank_str:
		"A": res.rank = 1
		"J": res.rank = 11
		"Q": res.rank = 12
		"K": res.rank = 13
		_: res.rank = rank_str.to_int()
	res.category = cat
	res.description = desc
	update_card(res)

func update_card(data: Resource) -> void:
	card_data = data
	if not is_inside_tree():
		return

	var suit_sym = data.get_suit_symbol()
	var rank_str = data.get_rank_string()
	suit_rank_lbl.text = "%s %s" % [suit_sym, rank_str]
	suit_rank_lbl.modulate = data.get_suit_color()

	cat_lbl.text = data.get_category_name()
	name_lbl.text = data.card_name
	desc_lbl.text = data.description

func _on_mouse_entered() -> void:
	is_hovered = true
	if not is_selected:
		_animate_hover(true)

func _on_mouse_exited() -> void:
	is_hovered = false
	if not is_selected:
		_animate_hover(false)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_select()
		card_clicked.emit(self)

func toggle_select() -> void:
	set_selected(not is_selected)

func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_border()
	if is_selected:
		_animate_lift(-35.0, 1.1)
	else:
		if is_hovered:
			_animate_lift(-20.0, 1.05)
		else:
			_animate_lift(0.0, 1.0)
	card_selected_state_changed.emit(self, is_selected)

func _animate_hover(hover: bool) -> void:
	if hover:
		_animate_lift(-20.0, 1.05)
	else:
		_animate_lift(0.0, 1.0)

func _animate_lift(offset_y: float, scale_val: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", offset_y, 0.18)
	tween.tween_property(panel, "scale", Vector2(scale_val, scale_val), 0.18)

func _update_border() -> void:
	if is_selected:
		border.border_color = Color("#E5A93C") # Vàng hoàng tộc phát sáng
		border.border_width = 3.0
	else:
		border.border_color = Color("#D4AF37") # Vàng kim tiêu chuẩn
		border.border_width = 1.5
