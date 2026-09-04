extends Node

# Database of 100 Vietnamese Historical Generals
# Auto-synced with Unity HeroDatabase100.cs
# - Weekly Free Rotation (Resets 00:00 Monday UTC+7)
# - Owned generals filter from AuthManager

var all_heroes: Array[Dictionary] = []
var hero_dict: Dictionary = {}

func _ready() -> void:
	_init_all_heroes()

func get_hero(id: int) -> Dictionary:
	if hero_dict.has(id):
		return hero_dict[id]
	return hero_dict.get(47, all_heroes[0] if not all_heroes.is_empty() else {})

func get_hero_by_name(name: String) -> Dictionary:
	if name.strip_edges() == "":
		return get_hero(47)
	var lower = name.to_lower()
	for h in all_heroes:
		if lower in h["name"].to_lower():
			return h
	return get_hero(47)

# 10 Tướng Free mỗi tuần (Reset 00:00 Thứ 2 hàng tuần theo giờ Việt Nam UTC+7)
func get_weekly_free_hero_ids() -> Array[int]:
	var unix_vn = int(Time.get_unix_time_from_system()) + 7 * 3600
	var dt_vn = Time.get_datetime_dict_from_unix_time(unix_vn)
	# weekday: 0 = Sunday, 1 = Monday, 2 = Tuesday, ..., 6 = Saturday
	var wday = dt_vn.get("weekday", 1)
	var diff = (7 + (wday - 1)) % 7
	var last_monday_unix = unix_vn - diff * 86400
	var last_monday_dt = Time.get_datetime_dict_from_unix_time(last_monday_unix)
	
	var y = int(last_monday_dt.get("year", 2026))
	var m = int(last_monday_dt.get("month", 1))
	var d = int(last_monday_dt.get("day", 1))
	var day_of_year = _get_day_of_year(y, m, d)
	var week_seed = y * 1000 + day_of_year

	var rng = RandomNumberGenerator.new()
	rng.seed = week_seed

	var candidates: Array[int] = []
	for i in range(1, 101):
		candidates.append(i)

	var free_ids: Array[int] = []
	while free_ids.size() < 10 and not candidates.is_empty():
		var idx = rng.randi_range(0, candidates.size() - 1)
		free_ids.append(candidates[idx])
		candidates.remove_at(idx)

	return free_ids

func _get_day_of_year(year: int, month: int, day: int) -> int:
	var days_in_months = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var is_leap = (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
	if is_leap:
		days_in_months[2] = 29
	var doy = 0
	for i in range(1, month):
		doy += days_in_months[i]
	doy += day
	return doy

func is_hero_owned(hero_id: int) -> bool:
	if AuthManager:
		if AuthManager.current_user_name == "Admin" or AuthManager.current_user_email.ends_with("@admin.vn"):
			return true
	if hero_id == 47: # Lý Thường Kiệt khởi đầu mặc định
		return true
	if not AuthManager:
		return false
	
	var hero = get_hero(hero_id)
	var slug = hero.get("slug", "")
	var hero_name = hero.get("name", "")

	for item in AuthManager.current_generals:
		var item_str = str(item).strip_edges().to_lower()
		if item_str == str(hero_id):
			return true
		if item_str == slug.to_lower():
			return true
		if item_str == hero_name.to_lower():
			return true
	return false

func get_available_pick_heroes() -> Array[Dictionary]:
	if AuthManager:
		if AuthManager.current_user_name == "Admin" or AuthManager.current_user_email.ends_with("@admin.vn"):
			return all_heroes.duplicate()

	var free_ids = get_weekly_free_hero_ids()
	var available: Array[Dictionary] = []
	for h in all_heroes:
		var hid = h["id"]
		if hid in free_ids or is_hero_owned(hid):
			var copy = h.duplicate()
			copy["is_weekly_free"] = (hid in free_ids)
			copy["is_owned"] = is_hero_owned(hid)
			available.append(copy)
	return available

func get_avatar_texture(avatar_path: String) -> Texture2D:
	if avatar_path != "" and ResourceLoader.exists(avatar_path):
		var tex = load(avatar_path) as Texture2D
		if tex:
			return tex
	var def_path = "res://assets/ui/ly_thuong_kiet.png"
	if ResourceLoader.exists(def_path):
		var def_tex = load(def_path) as Texture2D
		if def_tex:
			return def_tex
	var alt_path = "res://assets/ui/game_avatar.png"
	if ResourceLoader.exists(alt_path):
		return load(alt_path) as Texture2D
	return null

func _init_all_heroes() -> void:
	hero_dict.clear()
	all_heroes.clear()
	_add_hero(1, "Cao Lỗ", "Âu Lạc", 4, "Chế Nỏ", "Bạn có thể dùng bất kỳ lá bài chất Bích (♠) như lá trang bị Nỏ Thần Kim Quy.", "res://assets/ui/cao_lo.png", "cao_lo")
	_add_hero(2, "Đào Hãn", "Âu Lạc", 4, "Xạ Thuẫn", "Khoảng cách khi bạn dùng Trảm lên mục tiêu luôn được giảm 2.", "res://assets/ui/dao_han.png", "dao_han")
	_add_hero(3, "Thi Sách", "Thời Trưng Vương", 4, "Hịch Nghĩa", "Khi bạn rơi vào trạng thái Cận Tử, bạn lập tức rút 3 lá bài.", "res://assets/ui/thi_sach.png", "thi_sach")
	_add_hero(4, "Lê Chân", "Thời Trưng Vương", 3, "Triều Dâng", "Một lần mỗi lượt, chỉ định hủy 1 lá trang bị của 1 người khác.", "res://assets/ui/le_chan.png", "le_chan")
	_add_hero(5, "Thánh Thiên", "Thời Trưng Vương", 4, "Dũng Nữ", "Đòn Trảm của bạn khiến mục tiêu phải đánh ra 2 lá Đỡ mới có thể triệt tiêu nếu mục tiêu có lượng Máu hiện tại nhiều hơn bạn.", "res://assets/ui/thanh_thien.png", "thanh_thien")
	_add_hero(6, "Bát Nàn", "Thời Trưng Vương", 3, "Trinh Liệt", "Mỗi khi chịu sát thương từ đòn đánh của người chơi khác, bạn được rút ngẫu nhiên 1 lá bài trên tay của người gây sát thương.", "res://assets/ui/bat_nan.png", "bat_nan")
	_add_hero(7, "Nàng Nội", "Thời Trưng Vương", 3, "Tiên Phong", "Trong lượt đầu tiên của trận đấu, bạn được rút thêm 2 lá bài và không bị giới hạn số lần ra lá Trảm trong Giai đoạn Ra bài.", "res://assets/ui/nang_noi.png", "nang_noi")
	_add_hero(8, "Triệu Quốc Đạt", "Khởi nghĩa Bà Triệu", 4, "Khởi Binh", "Khi đồng minh cùng thế lực dùng Trảm gây sát thương thành công, họ có thể chọn cho bạn rút 1 lá bài.", "res://assets/ui/trieu_quoc_dat.png", "trieu_quoc_dat")
	_add_hero(9, "Triệu Thị Trinh", "Khởi nghĩa Bà Triệu", 4, "Trảm Kình", "Khi bạn đánh ra lá Trảm - Hỏa hoặc Trảm - Lôi, nếu trúng đích, sát thương gây ra được tăng thêm +1.", "res://assets/ui/ba_trieu.png", "ba_trieu")
	_add_hero(10, "Lý Bí", "Vạn Xuân", 4, "Dựng Nước", "Đầu Giai đoạn Rút bài, bạn có thể bỏ qua việc rút bài để hồi 1 Máu và thu 1 lá chất Cơ (♥) từ xấp bài bỏ vào tay.", "res://assets/ui/ly_bi.png", "ly_bi")
	_add_hero(11, "Triệu Túc", "Vạn Xuân", 4, "Tùng Nghĩa", "Khi vùng trang bị của bạn có ít nhất 1 lá Chiến Mã hoặc Áo Giáp, giới hạn bài giữ trên tay cuối lượt của bạn được tăng thêm +1.", "res://assets/ui/trieu_tuc.png", "trieu_tuc")
	_add_hero(12, "Tinh Thiều", "Vạn Xuân", 3, "Văn Sách", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể đổi 1 lá Cẩm Nang trên tay lấy 1 lá Bài Cơ Bản ngẫu nhiên từ xấp bài rút.", "res://assets/ui/tinh_thieu.png", "tinh_thieu")
	_add_hero(13, "Phạm Tu", "Vạn Xuân", 4, "Trấn Nam", "Bạn miễn nhiễm hoàn toàn với sát thương từ Cẩm Nang Bãi Cọc Ngầm. Khi bạn dùng Trảm Thường Đen, mục tiêu không thể kích hoạt hiệu ứng của Giáp Đồng Sơn Vi.", "res://assets/ui/pham_tu.png", "pham_tu")
	_add_hero(14, "Triệu Quang Phục", "Vạn Xuân", 4, "Dạ Trạch", "Khi bạn không còn lá bài nào trên tay, bạn không thể trở thành mục tiêu của các đòn Trảm Thường.", "res://assets/ui/trieu_quang_phuc.png", "trieu_quang_phuc")
	_add_hero(15, "Phùng Hưng", "Thời Bắc thuộc", 4, "Phục Hổ", "Khi bạn sử dụng lá Thách Đấu hoặc bị người khác chỉ định bởi Thách Đấu, đối phương phải ra 2 lá Trảm cho mỗi lần đáp trả.", "res://assets/ui/phung_hung.png", "phung_hung")
	_add_hero(16, "Phùng Hải", "Thời Bắc thuộc", 4, "Lực Địch", "Bạn có thể trang bị tối đa 2 lá Vũ Khí cùng lúc trên vùng trang bị của mình.", "res://assets/ui/phung_hai.png", "phung_hai")
	_add_hero(17, "Mai Thúc Loan", "Thời Bắc thuộc", 4, "Vạn An", "Bạn có thể dùng 2 lá bài màu Đen bất kỳ trên tay để xem như vừa sử dụng lá Cẩm Nang Bãi Cọc Ngầm.", "res://assets/ui/mai_thuc_loan.png", "mai_thuc_loan")
	_add_hero(18, "Khúc Thừa Dụ", "Thời Tự Chủ", 3, "Khoan Giản", "Trong Giai đoạn Bỏ bài, giới hạn số bài bạn được giữ trên tay được cộng thêm bằng đúng số trang bị bạn đang mang.", "res://assets/ui/khuc_thua_du.png", "khuc_thua_du")
	_add_hero(19, "Khúc Hạo", "Thời Tự Chủ", 3, "Khoan Hòa", "Cuối lượt của bạn, nếu bạn không gây sát thương cho bất kỳ ai trong lượt đó, bạn và tối đa 1 người chơi khác do bạn chọn cùng được rút 1 lá bài.", "res://assets/ui/khuc_hao.png", "khuc_hao")
	_add_hero(20, "Dương Đình Nghệ", "Thời Tự Chủ", 4, "Nghĩa Tử", "Khi một người chơi khác bị nhận sát thương, bạn có thể bỏ 2 lá bài trên tay để chịu thay 1 sát thương cho họ.", "res://assets/ui/duong_dinh_nghe.png", "duong_dinh_nghe")
	_add_hero(21, "Kiều Công Tiễn", "Thời Bắc thuộc/Tiền Ngô", 3, "Nghịch Ý", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 2 lá bài trên tay để chuyển mục tiêu của đòn Trảm đó sang 1 người chơi khác bất kỳ.", "res://assets/ui/kieu_cong_tien.png", "kieu_cong_tien")
	_add_hero(22, "Ngô Quyền", "Thời Ngô", 4, "Thủy Chiến", "Bạn có thể dùng bất kỳ lá bài chất Rô (♦) hoặc Chuồn (♣) như một lá Bãi Cọc Ngầm; bản thân bạn miễn nhiễm sát thương từ Bãi Cọc Ngầm.", "res://assets/ui/ngo_quyen.png", "ngo_quyen")
	_add_hero(23, "Dương Tam Kha", "Thời Ngô", 4, "Đoạt Vị", "Khi bạn tiêu diệt một người chơi, bạn thu lấy toàn bộ số bài trên tay và vùng trang bị của nạn nhân.", "res://assets/ui/duong_tam_kha.png", "duong_tam_kha")
	_add_hero(24, "Ngô Xương Ngập", "Thời Ngô", 3, "Thiên Cảm", "Khi lượng Máu hiện tại của bạn từ 1 trở xuống, bạn không thể bị đặt các lá Cẩm Nang Trì Hoãn (Cắt Đường Lương, Trầm Ảo Sa Bẫy, Thần Sấm Báo Ứng).", "res://assets/ui/ngo_xuong_ngap.png", "ngo_xuong_ngap")
	_add_hero(25, "Ngô Xương Văn", "Thời Ngô", 4, "Nam Tấn", "Mỗi khi đòn Trảm của bạn gây sát thương thành công lên mục tiêu, bạn được rút ngay 1 lá bài.", "res://assets/ui/ngo_xuong_van.png", "ngo_xuong_van")
	_add_hero(26, "Đỗ Cảnh Thạc", "Thời 12 Sứ Quân", 4, "Cát Cứ", "Mỗi khi bị đối phương chọn làm mục tiêu của Vườn Không Nhà Trống hoặc Đột Kích Trộm Lương, bạn lập tức được rút 1 lá bài.", "res://assets/ui/do_canh_thac.png", "do_canh_thac")
	_add_hero(27, "Kiều Thuận", "Thời 12 Sứ Quân", 4, "Hồi Hồ", "Nếu trong lượt của mình bạn không sử dụng lá Trảm nào, sát thương đầu tiên bạn nhận cho tới lượt kế tiếp của bạn được giảm đi 1 điểm.", "res://assets/ui/kieu_thuan.png", "kieu_thuan")
	_add_hero(28, "Nguyễn Siêu", "Thời 12 Sứ Quân", 4, "Liệt Chiến", "Khi tham gia vào lá Thách Đấu (do bạn dùng hoặc người khác dùng vào bạn), nếu bạn là người chiến thắng, bạn hồi phục ngay 1 Máu.", "res://assets/ui/nguyen_sieu.png", "nguyen_sieu")
	_add_hero(29, "Lã Đường", "Thời 12 Sứ Quân", 4, "Tế Giang", "Khi dùng Trảm nhắm vào mục tiêu không trang bị lá Chiến Mã (+1 Khoảng cách), Tầm đánh của bạn tính là không giới hạn khoảng cách.", "res://assets/ui/la_duong.png", "la_duong")
	_add_hero(30, "Đinh Bộ Lĩnh", "Thời Đinh", 4, "Cờ Lau", "Mỗi khi đòn Trảm của bạn gây sát thương lên mục tiêu, bạn được chọn: Rút 1 lá bài từ xấp rút HOẶC phá hủy 1 lá trang bị của nạn nhân.", "res://assets/ui/dinh_bo_linh.png", "dinh_bo_linh")
	_add_hero(31, "Đinh Liễn", "Thời Đinh", 4, "Trữ Quân", "Đầu Giai đoạn Rút bài, bạn có thể tự giảm 1 Máu để được rút thêm 2 lá bài.", "res://assets/ui/dinh_lien.png", "dinh_lien")
	_add_hero(32, "Đinh Điền", "Thời Đinh", 4, "Trung Tiết", "Khi chúa công hoặc người chơi cùng phe nhận sát thương chí tử, bạn có thể tự mất 1 Máu để họ hồi lại 1 Máu ngay lập tức.", "res://assets/ui/dinh_dien.png", "dinh_dien")
	_add_hero(33, "Nguyễn Bặc", "Thời Đinh", 4, "Định Quốc", "Bạn có thể dùng bất kỳ lá bài chất Bích (♠) như lá Thách Đấu.", "res://assets/ui/nguyen_bac.png", "nguyen_bac")
	_add_hero(34, "Phạm Hạp", "Thời Đinh", 4, "Tận Trung", "Mỗi khi có người chơi khác sử dụng Bánh Chưng để hồi máu, bạn được rút 1 lá bài từ xấp bài rút.", "res://assets/ui/pham_hap.png", "pham_hap")
	_add_hero(35, "Lê Hoàn", "Thời Tiền Lê", 4, "Phá Tống", "Khi đánh ra lá Trảm, bạn có thể bỏ thêm 1 lá bài trên tay để đòn Trảm đó không thể bị đối phương dùng Đỡ triệt tiêu.", "res://assets/ui/le_hoan.png", "le_hoan")
	_add_hero(36, "Dương Vân Nga", "Thời Đinh / Tiền Lê", 3, "Trao Bào", "Trong Giai đoạn Ra bài, bạn có thể chuyển 1 lá bài trang bị từ tay hoặc vùng trang bị của mình cho người chơi khác; người đó hồi 1 Máu và bạn được rút 1 lá bài.", "res://assets/ui/duong_van_nga.png", "duong_van_nga")
	_add_hero(37, "Lê Long Đĩnh", "Thời Tiền Lê", 4, "Bạo Nộ", "Bạn có thể sử dụng lá Hủ Rượu không giới hạn số lần trong một lượt; cuối lượt nếu không gây sát thương cho ai, bạn phải tự mất 1 Máu.", "res://assets/ui/le_long_dinh.png", "le_long_dinh")
	_add_hero(38, "Đào Cam Mộc", "Thời Tiền Lê / Lý", 3, "Phò Tá", "Trong Giai đoạn Rút bài, bạn có thể đưa số bài vừa rút được cho 1 người chơi khác thay vì giữ lại cho bản thân.", "res://assets/ui/dao_cam_moc.png", "dao_cam_moc")
	_add_hero(39, "Lý Công Uẩn", "Thời Lý", 4, "Dời Đô", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ toàn bộ bài trên tay để rút lại số lượng lá bài tương đương từ xấp rút.", "res://assets/ui/ly_cong_uan.png", "ly_cong_uan")
	_add_hero(40, "Lý Phật Mã", "Thời Lý", 4, "Thân Chinh", "Khi bạn lần đầu dùng Trảm gây sát thương thành công cho mục tiêu trong lượt, bạn được quyền đánh thêm 1 lá Trảm nữa trong lượt đó.", "res://assets/ui/ly_phat_ma.png", "ly_phat_ma")
	_add_hero(41, "Lý Nhật Tôn", "Thời Lý", 4, "Đại Việt", "Đầu lượt, bạn chọn 1 chất bài (♠, ♥, ♣, ♦); trong lượt đó, mỗi khi bạn đánh ra 1 lá bài có chất đã chọn, bạn lập tức được rút 1 lá bài.", "res://assets/ui/ly_nhat_ton.png", "ly_nhat_ton")
	_add_hero(42, "Lý Đạo Thành", "Thời Lý", 3, "Can Gián", "Khi bất kỳ người chơi nào bị đặt Cẩm Nang Trì Hoãn, bạn có thể bỏ 1 lá bài màu Đỏ trên tay để hủy bỏ hoàn toàn lá Cẩm Nang đó.", "res://assets/ui/ly_dao_thanh.png", "ly_dao_thanh")
	_add_hero(43, "Ỷ Lan", "Thời Lý", 3, "Nhiếp Chính", "Giai đoạn Rút bài của bạn được rút 3 lá bài thay vì 2. Trong lượt, bạn có thể tặng 1 lá bài trên tay cho đồng minh.", "res://assets/ui/y_lan.png", "y_lan")
	_add_hero(44, "Tông Đản", "Thời Lý", 4, "Thổ Binh", "Khi tấn công mục tiêu ở Khoảng cách <=2, đòn Trảm của bạn không thể bị vô hiệu hóa bởi các lá Đỡ có giá trị từ 2->5.", "res://assets/ui/tong_dan.png", "tong_dan")
	_add_hero(45, "Thân Cảnh Phúc", "Thời Lý", 4, "Động Phục", "Mỗi khi bạn chịu sát thương từ các lá Cẩm Nang, bạn lập tức được rút 2 lá bài.", "res://assets/ui/than_canh_phuc.png", "than_canh_phuc")
	_add_hero(46, "Tô Hiến Thành", "Thời Lý", 3, "Thiết Diện", "Bạn miễn nhiễm hoàn toàn với các hiệu ứng ép bỏ bài hoặc cướp bài từ Vườn Không Nhà Trống và Đột Kích Trộm Lương.", "res://assets/ui/to_hien_thanh.png", "to_hien_thanh")
	_add_hero(47, "Lý Thường Kiệt", "Thời Lý", 4, "Tiến Thoái", "Bạn có thể sử dụng lá Trảm như lá Đỡ, và sử dụng lá Đỡ như lá Trảm.", "res://assets/ui/ly_thuong_kiet.png", "ly_thuong_kiet")
	_add_hero(48, "Trần Cảnh", "Thời Trần", 4, "Khai Sáng", "Mỗi khi bạn lắp một lá bài Vũ Khí hoặc Áo Giáp vào vùng trang bị của mình, bạn được hồi ngay 1 Máu.", "res://assets/ui/tran_canh.png", "tran_canh")
	_add_hero(49, "Trần Thủ Độ", "Thời Trần", 4, "Chuyên Chế", "Trong Giai đoạn Ra bài, bạn có thể bỏ 1 lá bài trên tay để chỉ định hủy 1 lá trang bị của người khác đang đeo trang bị; người đó phải ra 1 lá Trảm hoặc mất 1 Máu.", "res://assets/ui/tran_thu_do.png", "tran_thu_do")
	_add_hero(50, "Trần Liễu", "Thời Trần", 4, "Ấp Phụ", "Khi bạn bị mất Máu do hành động của người chơi khác, bạn được rút 1 lá bài từ xấp rút và lấy 1 lá Trảm từ xấp bài bỏ vào tay (nếu có).", "res://assets/ui/tran_lieu.png", "tran_lieu")
	_add_hero(51, "Trần Hoảng", "Thời Trần", 4, "Hội Nghị", "Khi bạn hoặc người chơi khác sử dụng lá Mở Kho Cứu Tế, bạn được chỉ định thêm người, bạn và họ rút thêm 1 lá bài từ xấp bài rút.", "res://assets/ui/tran_hoang.png", "tran_hoang")
	_add_hero(52, "Trần Khâm", "Thời Trần", 4, "Thiền Tâm", "Khi rơi vào trạng thái Cận Tử (0 Máu), bạn có thể bỏ 2 lá bài trên tay để tự hồi phục 1 Máu mà không cần dùng Bánh Chưng hay Hủ Rượu.", "res://assets/ui/tran_kham.png", "tran_kham")
	_add_hero(53, "Trần Quốc Tuấn", "Thời Trần", 4, "Hịch Tướng", "Trong Giai đoạn Ra bài, bạn có thể chọn phát động lệnh tập kích: Từng người chơi có thể tự nguyện bỏ 1 lá Trảm để giúp bạn rút 1 lá bài.", "res://assets/ui/tran_hung_dao.png", "tran_hung_dao")
	_add_hero(54, "Trần Quang Khải", "Thời Trần", 4, "Thái Bình", "Cuối lượt của bạn, nếu bạn không sử dụng bất kỳ lá Trảm nào trong lượt đó, bạn có thể lấy 1 lá Áo Giáp hoặc Chiến Mã từ xấp bài bỏ gắn trực tiếp vào vùng trang bị của mình.", "res://assets/ui/tran_quang_khai.png", "tran_quang_khai")
	_add_hero(55, "Trần Nhật Duật", "Thời Trần", 3, "Đồng Hóa", "Khi trở thành mục tiêu của Thách Đấu hoặc Đột Kích Trộm Lương, bạn có thể đổi 1 lá bài trên tay của mình với 1 lá bài ngẫu nhiên trên tay kẻ phát động trước khi giải quyết hiệu ứng.", "res://assets/ui/tran_nhat_duat.png", "tran_nhat_duat")
	_add_hero(56, "Trần Quốc Toản", "Thời Trần", 4, "Phá Cường Địch", "Trong lượt, nếu vùng trang bị của bạn chưa gắn Vũ Khí, đòn Trảm đầu tiên bạn đánh ra sẽ gây thêm +1 sát thương nếu trúng đích.", "res://assets/ui/tran_quoc_toan.png", "tran_quoc_toan")
	_add_hero(57, "Trần Bình Trọng", "Thời Trần", 4, "Bảo Quốc", "Khi bạn bị hạ gục, bạn có thể chỉ định kẻ tiêu diệt mình phải hủy toàn bộ bài trong vùng trang bị và bỏ 2 lá bài trên tay.", "res://assets/ui/tran_binh_trong.png", "tran_binh_trong")
	_add_hero(58, "Trần Khánh Dư", "Thời Trần", 4, "Đoạt Lương", "Khi bạn sử dụng thành công lá Cắt Đường Lương lên mục tiêu bất kỳ, bạn lập tức được rút 2 lá bài từ xấp rút.", "res://assets/ui/tran_khanh_du.png", "tran_khanh_du")
	_add_hero(59, "Phạm Ngũ Lão", "Thời Trần", 4, "Phục Kích", "Giới hạn 1 lượt 1 lần, bạn có thể dùng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Đột Kích Trộm Lương.", "res://assets/ui/pham_ngu_lao.png", "pham_ngu_lao")
	_add_hero(60, "Yết Kiêu", "Thời Trần", 4, "Thấu Thủy", "Bạn miễn nhiễm hoàn toàn với sát thương từ lá Bãi Cọc Ngầm. Bạn có thể dùng bất kỳ lá Trảm nào như một lá Trảm - Lôi.", "res://assets/ui/yet_kieu.png", "yet_kieu")
	_add_hero(61, "Dã Tượng", "Thời Trần", 4, "Ngự Tượng", "Bạn mặc định sở hữu hiệu ứng tăng khoảng cách của Voi Chiến Đại Việt (+1 Khoảng cách) mà không cần phải trang bị lá bài này, nếu trang bị, khoảng cách phòng thủ của bạn trở thành +2.", "res://assets/ui/da_tuong.png", "da_tuong")
	_add_hero(62, "Đỗ Khắc Chung", "Thời Trần", 3, "Thuyết Khách", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 1 lá Cẩm Nang bất kỳ trên tay để vô hiệu hóa hoàn toàn đòn đánh đó.", "res://assets/ui/do_khac_chung.png", "do_khac_chung")
	_add_hero(63, "Hà Đặc", "Thời Trần", 4, "Tráng Khí", "Khi bạn đánh ra lá Trảm, nếu mục tiêu dùng lá Đỡ để triệt tiêu đòn đánh, bạn lập tức được rút 1 lá bài từ xấp bài rút.", "res://assets/ui/ha_dac.png", "ha_dac")
	_add_hero(64, "Hà Chương", "Thời Trần", 4, "Thác Binh", "Mỗi khi bạn nhận sát thương, bạn được xem 2 lá bài trên cùng của xấp bài rút, lấy 1 lá vào tay và đặt 1 lá còn lại xuống đáy xấp bài.", "res://assets/ui/ha_chuong.png", "ha_chuong")
	_add_hero(65, "Nguyễn Khoái", "Thời Trần", 4, "Tiệp Lộ", "Khi bạn sử dụng lá Bãi Cọc Ngầm, bạn có thể chỉ định tối đa 2 người chơi khác không phải chịu ảnh hưởng của lá bài này.", "res://assets/ui/nguyen_khoai.png", "nguyen_khoai")
	_add_hero(66, "Trần Thì Kiến", "Thời Trần", 3, "Cương Trực", "Đối phương không thể sử dụng lá Diệu Kế Phá Mưu để vô hiệu hóa các lá Cẩm Nang do bạn đánh ra.", "res://assets/ui/tran_thi_kien.png", "tran_thi_kien")
	_add_hero(67, "Chu Văn An", "Thời Trần", 3, "Thất Trảm", "Trong Giai đoạn Ra bài, giới hạn 2 lần, bạn có thể bỏ 2 lá bài cùng chất trên tay để phá hủy 1 lá bài bất kỳ trong vùng chơi của một người chơi khác, sau đó rút 1 lá.", "res://assets/ui/chu_van_an.png", "chu_van_an")
	_add_hero(68, "Trương Hán Siêu", "Thời Trần", 3, "Bạch Đằng Phú", "Khi bạn sử dụng lá Cẩm Nang Dụng Binh Như Thần, bạn được rút 3 lá bài thay vì 2 lá bài từ xấp rút.", "res://assets/ui/truong_han_sieu.png", "truong_han_sieu")
	_add_hero(69, "Mạc Đĩnh Chi", "Thời Trần", 3, "Lưỡng Quốc", "Giới hạn bài giữ trên tay tối đa trong Giai đoạn Bỏ bài của bạn luôn bằng Máu tối đa của bạn cộng thêm 1.", "res://assets/ui/mac_dinh_chi.png", "mac_dinh_chi")
	_add_hero(70, "Đoàn Nhữ Hài", "Thời Trần", 3, "Sứ Giả", "Trong Giai đoạn Ra bài, bạn có thể đưa 1 lá bài trên tay cho một người chơi khác để lấy 1 lá trang bị từ vùng trang bị của họ đưa về tay mình.", "res://assets/ui/doan_nhu_hai.png", "doan_nhu_hai")
	_add_hero(71, "Trần Nghệ Tông", "Thời Trần", 4, "Bảo Thủ", "Bạn miễn nhiễm hoàn toàn với hiệu ứng giam cầm của Cẩm Nang Trì Hoãn Trầm Ảo Sa Bẫy.", "res://assets/ui/tran_nghe_tong.png", "tran_nghe_tong")
	_add_hero(72, "Trần Duệ Tông", "Thời Trần", 4, "Trực Chiến", "Khi bạn đánh ra lá Trảm, đối phương bắt buộc phải sử dụng lá Đỡ >=7 điểm mới có thể triệt tiêu đòn đánh.", "res://assets/ui/tran_due_tong.png", "tran_due_tong")
	_add_hero(73, "Trần Khát Chân", "Thời Trần", 4, "Hỏa Pháo", "Khi bạn sử dụng lá Trảm - Hỏa gây sát thương thành công cho mục tiêu, bạn có thể bắt mục tiêu phải bỏ thêm 1 lá bài trên tay hoặc nhận thêm 1 sát thương thường.", "res://assets/ui/tran_khat_chan.png", "tran_khat_chan")
	_add_hero(74, "Đỗ Tử Bình", "Thời Trần", 4, "Úng Binh", "Khi một người chơi cùng thế lực nhận sát thương từ người khác, bạn được quyền rút ngay 1 lá bài từ xấp bài rút.", "res://assets/ui/do_tu_binh.png", "do_tu_binh")
	_add_hero(75, "Nguyễn Sư Tề", "Thời Trần", 4, "Chấn Giáp", "Mỗi khi bạn lắp một lá Áo Giáp vào vùng trang bị của mình, bạn được rút ngay 1 lá bài từ xấp bài rút.", "res://assets/ui/nguyen_su_te.png", "nguyen_su_te")
	_add_hero(76, "Hồ Quý Ly", "Thời Hồ", 4, "Cải Chế", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ 1 lá bài bất kỳ trên tay để lấy 1 lá Trảm hoặc Đỡ từ xấp bài bỏ vào tay.", "res://assets/ui/ho_quy_ly.png", "ho_quy_ly")
	_add_hero(77, "Hồ Hán Thương", "Thời Hồ", 4, "Tiền Giấy", "Trong Giai đoạn Bỏ bài, các lá bài bạn phải bỏ đi có thể được trao cho các người chơi khác tùy ý thay vì đưa vào xấp bài bỏ.", "res://assets/ui/ho_han_thuong.png", "ho_han_thuong")
	_add_hero(78, "Hồ Nguyên Trừng", "Thời Hồ", 3, "Thần Cơ", "Bạn có thể dùng bất kỳ lá bài Đen nào như lá vũ khí Súng Thần Công Hồ Triều hoặc sử dụng như một lá Trảm - Hỏa.", "res://assets/ui/ho_nguyen_trung.png", "ho_nguyen_trung")
	_add_hero(79, "Trần Ngỗi", "Hậu Trần", 4, "Phục Hưng", "Đầu Giai đoạn Rút bài, nếu lượng Máu hiện tại của bạn từ 2 trở xuống, bạn được rút thêm 1 lá bài từ xấp rút.", "res://assets/ui/tran_ngoi.png", "tran_ngoi")
	_add_hero(80, "Trần Quý Khoáng", "Hậu Trần", 4, "Kế Nghiệp", "Khi một đồng minh cùng thế lực bị hạ gục, bạn được thu toàn bộ số bài trên tay và vùng trang bị còn lại của người đó vào tay mình.", "res://assets/ui/tran_quy_khoang.png", "tran_quy_khoang")
	_add_hero(81, "Đặng Dung", "Hậu Trần", 4, "Mài Kiếm", "Bạn có thể dùng lá Hủ Rượu như một lá Trảm Thường; đòn Trảm này không thể bị triệt tiêu bởi lá Đỡ.", "res://assets/ui/dang_dung.png", "dang_dung")
	_add_hero(82, "Đặng Tất", "Hậu Trần", 4, "Trận Pháp", "Khi bạn sử dụng lá Cẩm Nang Vườn Không Nhà Trống, bạn có thể chọn đồng thời 2 mục tiêu thay vì 1.", "res://assets/ui/dang_tat.png", "dang_tat")
	_add_hero(83, "Nguyễn Cảnh Chân", "Hậu Trần", 4, "Thủy Binh", "Bạn có thể dùng bất kỳ lá bài chất Chuồn (♣) nào trên tay như một lá Đỡ.", "res://assets/ui/nguyen_canh_chan.png", "nguyen_canh_chan")
	_add_hero(84, "Nguyễn Cảnh Dị", "Hậu Trần", 4, "Kỵ Chiến", "Khoảng cách tấn công tính từ bạn tới tất cả các người chơi khác luôn được giảm 1 điểm (tương tự hiệu ứng của Ngựa Trắng Thuần Nông). Nếu mang Ngựa Trắng Thuần Nông, khoảng cách sẽ là -2.", "res://assets/ui/nguyen_canh_di.png", "nguyen_canh_di")
	_add_hero(85, "Nguyễn Biểu", "Hậu Trần", 3, "Trinh Tiết", "Khi bạn là mục tiêu của lá Thách Đấu, bạn có thể không ra lá Trảm mà không bị mất Máu; thay vào đó, kẻ phát động phải bỏ 1 lá bài trên tay.", "res://assets/ui/nguyen_bieu.png", "nguyen_bieu")
	_add_hero(86, "Lê Lợi", "Khởi nghĩa Lam Sơn", 4, "Khởi Nghĩa", "Khi bạn trang bị vũ khí Kiếm Thuận Thiên, mỗi đòn Trảm của bạn gây trúng đích sẽ gây thêm +1 điểm sát thương. Đầu lượt, nếu trên tay hoặc trang bị chưa có Kiếm Thuận Thiên, nếu Kiếm Thuận Thiên nằm trên chồng bài rút hoặc bài bỏ, thu lấy nó.", "res://assets/ui/le_loi.png", "le_loi")
	_add_hero(87, "Nguyễn Trãi", "Khởi nghĩa Lam Sơn", 3, "Bình Ngô", "Trong Giai đoạn Ra bài, bạn có thể bỏ 2 lá Cẩm Nang trên tay để chỉ định 1 người chơi phải bỏ toàn bộ bài trên tay xuống xấp bài bỏ.", "res://assets/ui/nguyen_trai.png", "nguyen_trai")
	_add_hero(88, "Lê Lai", "Khởi nghĩa Lam Sơn", 4, "Liều Thân", "Khi một người chơi khác nhận sát thương chí tử, bạn có thể tự giảm 1 Máu của mình để gánh toàn bộ sát thương đó thay cho mục tiêu.", "res://assets/ui/le_lai.png", "le_lai")
	_add_hero(89, "Trần Nguyên Hãn", "Khởi nghĩa Lam Sơn", 4, "Thủy Kế", "Bạn có thể sử dụng bất kỳ lá bài mang chất Rô (♦) nào trên tay như một lá Cẩm Nang Bãi Cọc Ngầm.", "res://assets/ui/tran_nguyen_han.png", "tran_nguyen_han")
	_add_hero(90, "Lưu Nhân Chú", "Khởi nghĩa Lam Sơn", 4, "Tráng Tiết", "Khi bạn đánh ra lá Trảm - Lôi, đòn đánh này bỏ qua hoàn toàn các hiệu ứng phòng vệ từ các lá Áo Giáp của mục tiêu.", "res://assets/ui/luu_nhan_chu.png", "luu_nhan_chu")
	_add_hero(91, "Đinh Liệt", "Khởi nghĩa Lam Sơn", 4, "Thiết Kỵ", "Khi dùng Trảm nhắm vào mục tiêu đang gắn Chiến Mã (+1 Khoảng cách), bạn được quyền bỏ qua hiệu ứng tăng khoảng cách của lá ngựa đó.", "res://assets/ui/dinh_liet.png", "dinh_liet")
	_add_hero(92, "Phạm Văn Xảo", "Khởi nghĩa Lam Sơn", 3, "Trấn Tây", "Khi vùng trang bị của bạn hoàn toàn trống, mọi sát thương bạn phải nhận từ các đòn Trảm thường đều được giảm đi 1 điểm.", "res://assets/ui/pham_van_xao.png", "pham_van_xao")
	_add_hero(93, "Lê Sát", "Khởi nghĩa Lam Sơn", 4, "Dũng Tướng", "Bạn có thể sử dụng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Thách Đấu.", "res://assets/ui/le_sat.png", "le_sat")
	_add_hero(94, "Lê Ngân", "Khởi nghĩa Lam Sơn", 3, "Mật Vũ", "Cuối lượt, bạn có thể đặt úp 1 lá bài trên tay vào khu vực riêng; khi bị nhắm bởi Trảm, bạn có thể lật lá bài này lên để tính như vừa đánh ra 1 lá Đỡ.", "res://assets/ui/le_ngan.png", "le_ngan")
	_add_hero(95, "Nguyễn Xí", "Khởi nghĩa Lam Sơn", 4, "Khuyển Đội", "Mỗi khi đòn Trảm của bạn gây sát thương thành công, bạn được rút ngẫu nhiên 1 lá bài trên tay của nạn nhân.", "res://assets/ui/nguyen_xi.png", "nguyen_xi")
	_add_hero(96, "Trịnh Khả", "Khởi nghĩa Lam Sơn", 4, "Bình Định", "Khi bạn sử dụng lá Vườn Không Nhà Trống lên mục tiêu, thay vì bạn chọn, nạn nhân phải đồng thời phải tự bỏ 1 lá bài trên tay và chọn phá hủy 1 lá bài trong vùng trang bị (nếu có), sau đó bạn rút 1 lá.", "res://assets/ui/trinh_kha.png", "trinh_kha")
	_add_hero(97, "Nguyễn Chích", "Khởi nghĩa Lam Sơn", 3, "Bồ Câu", "Tầm tác dụng của các lá Cẩm Nang do bạn sử dụng không bị giới hạn bởi khoảng cách bàn chơi.", "res://assets/ui/nguyen_chich.png", "nguyen_chich")
	_add_hero(98, "Bùi Bị", "Khởi nghĩa Lam Sơn", 4, "Dũng Hãn", "Khi bạn sử dụng Trảm nhắm vào mục tiêu có lượng Máu hiện tại nhiều hơn bạn, đòn Trảm đó không thể bị đối phương dùng lá Đỡ triệt tiêu.", "res://assets/ui/bui_bi.png", "bui_bi")
	_add_hero(99, "Lê Khôi", "Khởi nghĩa Lam Sơn", 4, "Khai Biên", "Mỗi khi bạn tiêu diệt thành công một người chơi khác, bạn lập tức được hồi 1 Máu và rút thêm 2 lá bài từ xấp bài rút.", "res://assets/ui/le_khoi.png", "le_khoi")
	_add_hero(100, "Nguyễn Nhữ Lãm", "Khởi nghĩa Lam Sơn", 4, "Trấn Ải", "Bạn hoàn toàn miễn nhiễm với các lá Cẩm Nang Trì Hoãn.", "res://assets/ui/nguyen_nhu_lam.png", "nguyen_nhu_lam")

func _add_hero(id: int, name: String, faction: String, hp: int, skill_name: String, skill_desc: String, avatar_path: String, slug: String) -> void:
	var h = {
		"id": id,
		"name": name,
		"faction": faction,
		"maxHp": hp,
		"skillName": skill_name,
		"skillDesc": skill_desc,
		"avatarPath": avatar_path,
		"slug": slug
	}
	hero_dict[id] = h
	all_heroes.append(h)
