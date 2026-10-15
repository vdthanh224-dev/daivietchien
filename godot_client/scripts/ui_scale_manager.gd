extends Node

## Dùng giao diện Mobile 135% ngay từ lúc khởi động trên mọi thiết bị.
## Không đọc lựa chọn scale cũ để các bản cài đặt trước cũng nhận mặc định này.
const DEFAULT_SCALE: float = 1.35
var current_scale: float = DEFAULT_SCALE

# Sàn cỡ chữ tối thiểu trên thiết bị di động (tránh các cỡ chữ 8, 9, 10px quá nhỏ)
const MIN_FONT_SIZE_MOBILE: int = 12

func _ready() -> void:
	_init_scale()
	get_tree().node_added.connect(_on_node_added)
	_apply_theme_scale()
	_apply_scale_to_subtree(get_tree().root)
	print("[UIScaleManager] Khởi tạo hoàn tất. Thiết bị: %s | Tỉ lệ áp dụng: %.0f%%" % [
		OS.get_name(), current_scale * 100.0
	])

## Kiểm tra có đang chạy trên thiết bị di động thực tế không
func is_mobile_device() -> bool:
	var os_name = OS.get_name().to_lower()
	if os_name == "android" or os_name == "ios":
		return true
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		return true
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	if os_name == "web":
		if OS.has_feature("web"):
			var is_mobile_ua = JavaScriptBridge.eval("/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)")
			if is_mobile_ua == true:
				return true
	if DisplayServer.is_touchscreen_available() and (os_name != "windows" and os_name != "macos" and os_name != "linux"):
		return true
	return false

## Bố cục Mobile được dùng cùng mức chữ mặc định 135%.
func is_mobile_mode() -> bool:
	return is_mobile_device() or current_scale > 1.0

func _init_scale() -> void:
	current_scale = DEFAULT_SCALE

## Hàm tính cỡ chữ theo tỉ lệ hiện tại
func scale_font(base_size: int) -> int:
	if base_size <= 0:
		return base_size
	var target = int(round(float(base_size) * current_scale))
	if is_mobile_mode() and target < MIN_FONT_SIZE_MOBILE:
		target = MIN_FONT_SIZE_MOBILE
	return target

## Helper để code chủ động gán font size đã scale kèm lưu base size
func scale_node_font(ctrl: Control, base_size: int, property_name: String = "font_size") -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.set_meta("_base_" + property_name, base_size)
	ctrl.add_theme_font_size_override(property_name, scale_font(base_size))

## Cache StyleBoxEmpty dùng chung tránh cấp phát bộ nhớ nhiều lần
var _shared_empty_stylebox: StyleBoxEmpty = null

func get_empty_stylebox() -> StyleBoxEmpty:
	if _shared_empty_stylebox == null:
		_shared_empty_stylebox = StyleBoxEmpty.new()
	return _shared_empty_stylebox

## Hàm dùng chung toàn cục để thiết lập bất kỳ Button nào (nút overlay thẻ tướng, nút rương quà, nút flat...)
## khi click hoặc ở trạng thái đang chọn (focus/pressed) KHÔNG BAO GIỜ bị đổi màu trắng hoặc phủ viền trắng.
func style_transparent_button(btn: Button, keep_pointer_cursor: bool = true) -> Button:
	if not is_instance_valid(btn):
		return btn
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	if keep_pointer_cursor:
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty_sb = get_empty_stylebox()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)
	btn.add_theme_stylebox_override("disabled", empty_sb)
	return btn

## Lắng nghe khi có node mới thêm vào scene tree
func _on_node_added(node: Node) -> void:
	if node is Control:
		Callable(self, "_apply_scale_to_control").call_deferred(node)

## Áp dụng scale cho một Control
func _apply_scale_to_control(ctrl: Control) -> void:
	if not is_instance_valid(ctrl):
		return

	# Xử lý các node có font_size override (Label, Button, LineEdit, TextEdit, TabBar...)
	if ctrl.has_theme_font_size_override("font_size"):
		var base_size: int
		if ctrl.has_meta("_base_font_size"):
			base_size = int(ctrl.get_meta("_base_font_size"))
		else:
			base_size = ctrl.get_theme_font_size("font_size")
			ctrl.set_meta("_base_font_size", base_size)
		ctrl.add_theme_font_size_override("font_size", scale_font(base_size))

	# Xử lý RichTextLabel có nhiều loại font size
	if ctrl is RichTextLabel:
		var rtl_props = [
			"normal_font_size",
			"bold_font_size",
			"italics_font_size",
			"bold_italics_font_size",
			"mono_font_size"
		]
		for prop in rtl_props:
			if ctrl.has_theme_font_size_override(prop):
				var meta_k = "_base_" + prop
				var base_size: int
				if ctrl.has_meta(meta_k):
					base_size = int(ctrl.get_meta(meta_k))
				else:
					base_size = ctrl.get_theme_font_size(prop)
					ctrl.set_meta(meta_k, base_size)
				ctrl.add_theme_font_size_override(prop, scale_font(base_size))

	# Tự động bảo vệ tất cả các nút dạng flat trong toàn bộ game:
	# Tắt focus và gán StyleBoxEmpty cho focus/pressed/hover để không bao giờ bị phủ trắng khi nhấp hoặc chọn
	if ctrl is Button and ctrl.flat:
		ctrl.focus_mode = Control.FOCUS_NONE
		var empty_sb = get_empty_stylebox()
		if not ctrl.has_theme_stylebox_override("focus"):
			ctrl.add_theme_stylebox_override("focus", empty_sb)
		if not ctrl.has_theme_stylebox_override("pressed"):
			ctrl.add_theme_stylebox_override("pressed", empty_sb)
		if not ctrl.has_theme_stylebox_override("hover"):
			ctrl.add_theme_stylebox_override("hover", empty_sb)
		if not ctrl.has_theme_stylebox_override("normal"):
			ctrl.add_theme_stylebox_override("normal", empty_sb)
		if not ctrl.has_theme_stylebox_override("disabled"):
			ctrl.add_theme_stylebox_override("disabled", empty_sb)

## Đệ quy cập nhật toàn bộ subtree
func _apply_scale_to_subtree(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is Control:
		_apply_scale_to_control(node)
	for child in node.get_children():
		_apply_scale_to_subtree(child)

## Cập nhật theme chung của game
func _apply_theme_scale() -> void:
	ThemeDB.fallback_font_size = scale_font(16)
	var theme_path = "res://resources/themes/royal_gold_theme.tres"
	if ResourceLoader.exists(theme_path):
		var theme = load(theme_path) as Theme
		if theme:
			theme.default_font_size = scale_font(16)
			theme.set_font_size("font_size", "Label", scale_font(16))
			theme.set_font_size("font_size", "Button", scale_font(16))

## Áp dụng scale cho toàn bộ node trong một scene
func apply_to_scene(root_node: Node) -> void:
	if not is_instance_valid(root_node):
		return
	_apply_scale_to_subtree(root_node)

