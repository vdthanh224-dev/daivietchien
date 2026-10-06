extends Node

## UIScaleManager - Quản lý tự động tỉ lệ chữ và giao diện (Adaptive UI & Font Scale)
## Tự động phát hiện môi trường Mobile (Android/iOS) hoặc màn hình mật độ DPI cao
## để nhân tỉ lệ font chữ giúp dễ đọc trên điện thoại (như Redmi 12) mà không làm vỡ layout.

signal scale_changed(new_scale: float)

const SETTINGS_FILE: String = "user://ui_settings.cfg"
const SETTINGS_SECTION: String = "display"
const SETTINGS_KEY: String = "ui_scale"

# Các mức tỉ lệ chuẩn
const SCALE_PC: float = 1.0           # 100% (Mặc định máy tính)
const SCALE_MOBILE_NORMAL: float = 1.25 # 125% (Tiêu chuẩn Mobile dễ nhìn)
const SCALE_MOBILE_LARGE: float = 1.35  # 135% (Chữ lớn cho màn hình nhỏ hoặc mắt kém)

# Tỉ lệ hiện tại
var current_scale: float = 1.0

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
	return os_name == "android" or os_name == "ios"

## Kiểm tra chế độ Mobile (thiết bị di động hoặc người dùng đang chọn scale > 1.0)
func is_mobile_mode() -> bool:
	return is_mobile_device() or current_scale > 1.0

## Khởi tạo giá trị tỉ lệ từ file cấu hình người dùng hoặc tự động nhận diện
func _init_scale() -> void:
	var saved_scale = _load_saved_scale()
	if saved_scale > 0.0:
		current_scale = saved_scale
	else:
		if is_mobile_device():
			current_scale = SCALE_MOBILE_NORMAL
		else:
			current_scale = SCALE_PC

func _load_saved_scale() -> float:
	if not FileAccess.file_exists(SETTINGS_FILE):
		return -1.0
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	if err == OK:
		return float(config.get_value(SETTINGS_SECTION, SETTINGS_KEY, -1.0))
	return -1.0

func _save_scale(scale_val: float) -> void:
	var config = ConfigFile.new()
	var _err = config.load(SETTINGS_FILE)
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, scale_val)
	config.save(SETTINGS_FILE)

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

## Đổi tỉ lệ và cập nhật toàn bộ cây giao diện ngay lập tức
func set_scale_factor(new_scale: float) -> void:
	if is_equal_approx(current_scale, new_scale):
		return
	current_scale = new_scale
	_save_scale(new_scale)
	_apply_theme_scale()
	_apply_scale_to_subtree(get_tree().root)
	scale_changed.emit(current_scale)
	print("[UIScaleManager] Đã áp dụng tỉ lệ UI mới: %.0f%%" % (current_scale * 100.0))

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
