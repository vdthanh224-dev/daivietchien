class_name TitleBadge
extends PanelContainer

## Component hiển thị huy hiệu danh hiệu người chơi
## Hỗ trợ danh hiệu ADMIN bảy sắc cầu vồng nhấp nháy neon trên nền chữ nhật bo góc có độ mờ

var _stylebox: StyleBoxFlat
var _rtl: RichTextLabel
var title_id: String = "admin"
var is_neon_animated: bool = true

func _init(p_title_id: String = "admin") -> void:
	title_id = p_title_id.strip_edges().to_lower()
	custom_minimum_size = Vector2(62, 22)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS

	_stylebox = StyleBoxFlat.new()
	_stylebox.bg_color = Color(0.04, 0.05, 0.08, 0.88)
	_stylebox.border_width_left = 1
	_stylebox.border_width_top = 1
	_stylebox.border_width_right = 1
	_stylebox.border_width_bottom = 1
	_stylebox.border_color = Color(1.0, 0.35, 0.70, 0.85)
	_stylebox.corner_radius_top_left = 5
	_stylebox.corner_radius_top_right = 5
	_stylebox.corner_radius_bottom_right = 5
	_stylebox.corner_radius_bottom_left = 5
	_stylebox.shadow_color = Color(0, 0, 0, 0.65)
	_stylebox.shadow_size = 4
	_stylebox.shadow_offset = Vector2(0, 1)
	_stylebox.content_margin_left = 7
	_stylebox.content_margin_right = 7
	_stylebox.content_margin_top = 2
	_stylebox.content_margin_bottom = 2
	add_theme_stylebox_override("panel", _stylebox)

	_rtl = RichTextLabel.new()
	_rtl.bbcode_enabled = true
	_rtl.fit_content = true
	_rtl.scroll_active = false
	_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rtl.add_theme_font_size_override("normal_font_size", 10)
	_rtl.add_theme_font_size_override("bold_font_size", 10)

	if title_id == "admin":
		_rtl.text = "[center][rainbow freq=0.6 sat=1.0 val=1.0][b]ADMIN[/b][/rainbow][/center]"
	else:
		_rtl.text = "[center][b]%s[/b][/center]" % title_id.to_upper()
	add_child(_rtl)

func _process(_delta: float) -> void:
	if not is_neon_animated or not is_instance_valid(_stylebox):
		return
	if title_id == "admin":
		var hue = fmod(Time.get_ticks_msec() / 1800.0, 1.0)
		var neon_col = Color.from_hsv(hue, 0.85, 1.0, 0.85)
		_stylebox.border_color = neon_col
		_stylebox.shadow_color = Color.from_hsv(hue, 0.9, 0.7, 0.45)
