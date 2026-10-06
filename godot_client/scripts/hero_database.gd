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

func get_hero_skills(hero_id: int) -> Array:
	return get_hero(hero_id).get("skills", []).duplicate(true)

func has_hero_skill(hero_id: int, skill_id: String) -> bool:
	for skill in get_hero_skills(hero_id):
		if skill is Dictionary and str(skill.get("id", "")) == skill_id:
			return true
	return false

func get_skill_summary(hero_id: int) -> String:
	var names: Array[String] = []
	for skill in get_hero_skills(hero_id):
		if skill is Dictionary:
			names.append(str(skill.get("name", "Kỹ năng")))
	return ", ".join(names)

func get_skill_details(hero_id: int) -> String:
	var details: Array[String] = []
	for skill in get_hero_skills(hero_id):
		if skill is Dictionary:
			details.append("%s: %s" % [skill.get("name", "Kỹ năng"), skill.get("desc", "Chưa có mô tả.")])
	return "\n".join(details)

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

	var is_admin = AuthManager and AuthManager.is_admin()
	var max_candidate_id = 100 if is_admin else 28

	var candidates: Array[int] = []
	for i in range(1, max_candidate_id + 1):
		candidates.append(i)

	var free_ids: Array[int] = []
	var target_free_count = min(10, candidates.size())
	while free_ids.size() < target_free_count and not candidates.is_empty():
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
	if AuthManager and AuthManager.is_admin():
		return true
	if hero_id == 1 or hero_id == 47: # Tướng khởi đầu mặc định (Cao Lỗ #1, Lý Thường Kiệt #47)
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
	var is_admin = AuthManager and AuthManager.is_admin()
	if is_admin:
		return all_heroes.duplicate()

	var free_ids = get_weekly_free_hero_ids()
	var available: Array[Dictionary] = []
	for h in all_heroes:
		var hid = int(h["id"])
		# Chỉ xuất hiện các tướng từ 1->28 nếu không phải người có label appwrite Admin
		if hid < 1 or hid > 28:
			continue
		if hid in free_ids or is_hero_owned(hid):
			var copy = h.duplicate()
			copy["is_weekly_free"] = (hid in free_ids)
			copy["is_owned"] = is_hero_owned(hid)
			available.append(copy)
	return available

func get_all_heroes() -> Array[Dictionary]:
	return all_heroes

func get_avatar_texture(avatar_path: String) -> Texture2D:
	if avatar_path != "":
		var base_name = avatar_path.get_file()
		var trans_path = "res://assets/heroes_transparent/" + base_name
		if ResourceLoader.exists(trans_path):
			var trans_tex = load(trans_path) as Texture2D
			if trans_tex:
				return trans_tex
		if ResourceLoader.exists(avatar_path):
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
	_add_hero(1, "Cao Lỗ", "Hồng Bàng", 4, "Chế Nỏ", "Bạn có thể dùng bất kỳ lá bài Đen như lá trang bị Nỏ Thần Kim Quy.", "res://assets/ui/cao_lo.png", "cao_lo")
	_add_hero(2, "Đào Hãn", "Hồng Bàng", 4, "Xạ Thuẫn", "Bạn mặc định tăng 2 tầm Ngựa công.", "res://assets/ui/dao_han.png", "dao_han")
	_add_hero(3, "Thi Sách", "Hồng Bàng", 4, "Hịch Nghĩa", "Khi bạn rơi vào trạng thái Cận Tử, bạn lập tức rút 3 lá bài.", "res://assets/ui/thi_sach.png", "thi_sach")
	_add_hero(4, "Lê Chân", "Hồng Bàng", 3, "Triều Dâng", "Một lần mỗi lượt, chỉ định hủy 1 lá trang bị của 1 người khác.", "res://assets/ui/le_chan.png", "le_chan")
	_add_hero(5, "Thánh Thiên", "Hồng Bàng", 4, "Dũng Nữ", "Đòn Trảm của bạn khiến mục tiêu phải đánh ra 2 lá Đỡ mới có thể triệt tiêu nếu mục tiêu có lượng Máu hiện tại nhiều hơn bạn.", "res://assets/ui/thanh_thien.png", "thanh_thien")
	_add_hero(6, "Vũ Thị Thục", "Hồng Bàng", 3, "Trinh Liệt", "Mỗi khi chịu sát thương từ đòn Trảm, bạn được rút 1 lá bài trong vùng chơi của nguồn gây sát thương.", "res://assets/ui/bat_nan.png", "bat_nan")
	_add_hero(7, "Nàng Nội", "Hồng Bàng", 4, "Tiên Phong", "Trong lượt đầu tiên của trận đấu, bạn được rút thêm 2 lá bài và không bị giới hạn số lần ra lá Trảm trong lượt đầu tiên.", "res://assets/ui/nang_noi.png", "nang_noi")
	_add_hero(8, "Triệu Quốc Đạt", "Hồng Bàng", 4, "Khởi Binh", "Khi người khác dùng Trảm gây sát thương thành công, bạn có thể chọn cho bạn và họ, mỗi người rút 1 lá bài.", "res://assets/ui/trieu_quoc_dat.png", "trieu_quoc_dat")
	_add_hero(9, "Triệu Thị Trinh", "Hồng Bàng", 4, "Chiến Tượng", "Khi có trang bị trên ô Ngựa, sát thương gây ra bởi Trảm +1.", "res://assets/ui/ba_trieu.png", "ba_trieu")
	_add_hero(10, "Lý Bí", "Hồng Bàng", 4, "Dựng Nước", "Đầu Giai đoạn Rút bài, bạn có thể bỏ qua việc rút bài để hồi 1 Máu và thu ngẫu nhiên 1 lá bài Đỏ từ xấp bài bỏ vào tay nếu có.", "res://assets/ui/ly_bi.png", "ly_bi")
	_add_hero(11, "Triệu Túc", "Hồng Bàng", 4, "Tùng Nghĩa", "Khi vùng trang bị của bạn có ít nhất 1 lá Chiến Mã hoặc Áo Giáp, cuối lượt, bạn được rút 1 lá và giới hạn trữ bài +1.", "res://assets/ui/trieu_tuc.png", "trieu_tuc")
	_add_hero(12, "Tinh Thiều", "Hồng Bàng", 3, "Hán Lâm", "Mỗi khi bạn dùng thành công một lá Bài Cẩm Nang, bạn được xem lá bài trên cùng của xấp bài rút và có quyền chọn để nguyên hay đặt xuống đáy, sau đó rút 1 lá.", "res://assets/ui/tinh_thieu.png", "tinh_thieu")
	_add_hero(13, "Phạm Tu", "Hồng Bàng", 4, "Trấn Nam", "Bạn miễn nhiễm hoàn toàn với sát thương từ Cẩm Nang Giặc Tới. Khi bạn dùng Trảm Thường Đen hoặc Vàng, mục tiêu không thể kích hoạt hiệu ứng của Giáp Đồng Sơn Vi.", "res://assets/ui/pham_tu.png", "pham_tu")
	_add_hero(14, "Triệu Quang Phục", "Hồng Bàng", 4, "Dạ Trạch", "Khi bạn không còn lá bài nào trên tay, bạn không thể trở thành mục tiêu của các đòn Trảm. Đầu lượt, nếu trên tay bạn không có bài, bạn được rút thêm 1 lá. Cuối lượt, nếu trên tay bạn có bài, bạn có thể bỏ thêm 1 lá nếu muốn.", "res://assets/ui/trieu_quang_phuc.png", "trieu_quang_phuc")
	_add_hero(15, "Phùng Hưng", "Hồng Bàng", 4, "Phục Hổ", "Khi bạn sử dụng lá Huyết Chiến hoặc bị người khác chỉ định bởi Huyết Chiến, đối phương phải ra 2 lá Trảm cho mỗi lần đáp trả.", "res://assets/ui/phung_hung.png", "phung_hung")
	_add_hero(16, "Phùng Hải", "Hồng Bàng", 4, "Lực Địch", "Bạn có thể trang bị tối đa 2 lá Vũ Khí cùng lúc trên vùng trang bị của mình, tầm đánh và kỹ năng trang bị được cộng dồn.", "res://assets/ui/phung_hai.png", "phung_hai")
	_add_hero(17, "Mai Thúc Loan", "Hồng Bàng", 4, "Vạn An", "Giới hạn mỗi lượt 2 lần, bạn có thể dùng 2 lá bài bất kỳ trên tay để xem như sử dụng lá Cẩm Nang Bãi Cọc Bạch Đằng. Lần đầu sử dụng trong lượt, rút 1 lá bài.", "res://assets/ui/mai_thuc_loan.png", "mai_thuc_loan")
	_add_hero(18, "Khúc Thừa Dụ", "Hồng Bàng", 3, "Khoan Giản", "Sau giai đoạn Bỏ bài, bạn được rút X+1 lá, giới hạn trữ bài +(X+1) (X là một nửa số trang bị bạn đang mang, làm tròn lên).", "res://assets/ui/khuc_thua_du.png", "khuc_thua_du")
	_add_hero(19, "Khúc Hạo", "Hồng Bàng", 3, "Khoan Hòa", "Cuối lượt của bạn, nếu bạn không gây sát thương cho bất kỳ ai trong lượt đó, bạn rút 1 lá bài, sau đó bạn chọn tối đa 2 người chơi khác, mỗi người trong số họ rút 1 lá bài.", "res://assets/ui/khuc_hao.png", "khuc_hao")
	_add_hero(20, "Dương Đình Nghệ", "Hồng Bàng", 4, "Nghĩa Tử", "Khi một người chơi khác bị nhận sát thương, bạn có thể bỏ 1 lá bài trên tay để chịu thay 1 sát thương cho họ.", "res://assets/ui/duong_dinh_nghe.png", "duong_dinh_nghe")
	_add_hero(21, "Kiều Công Tiễn", "Hồng Bàng", 3, "Nghịch Ý", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 1 lá bài trên tay để chuyển mục tiêu của đòn Trảm đó sang 1 người chơi khác trong tầm đánh của bạn.", "res://assets/ui/kieu_cong_tien.png", "kieu_cong_tien")
	_add_hero(22, "Ngô Quyền", "Hồng Bàng", 3, "Thủy Chiến", "Bạn có thể dùng bất kỳ lá bài Trắng hoặc bài Vàng như một lá Bãi Cọc Bạch Đằng; bạn không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng.", "res://assets/ui/ngo_quyen.png", "ngo_quyen")
	_add_hero(23, "Dương Tam Kha", "Thăng Long", 4, "Đoạt Vị", "Khi có người chơi bị tiêu diệt, bạn thu lấy toàn bộ số bài trên tay và vùng trang bị của nạn nhân.", "res://assets/ui/duong_tam_kha.png", "duong_tam_kha")
	_add_hero(24, "Ngô Xương Ngập", "Thăng Long", 3, "Thiên Cảm", "Khi lượng Máu hiện tại của bạn từ 1 trở xuống, bạn không thể bị đặt các lá Cẩm Nang Trì Hoãn, các lá Cẩm Nang Trì Hoãn đang trên người bạn đi vào xấp bài bỏ. Bạn có thể đổi lá Cẩm Nang Trì Hoãn trên tay thành 2 lá mới.", "res://assets/ui/ngo_xuong_ngap.png", "ngo_xuong_ngap")
	_add_hero(25, "Ngô Xương Văn", "Thăng Long", 4, "Nam Tấn", "Khi Trảm của bạn gây sát thương, rút 1 lá.", "res://assets/ui/ngo_xuong_van.png", "ngo_xuong_van")
	_add_hero(26, "Đỗ Cảnh Thạc", "Thăng Long", 4, "Cát Cứ", "Mỗi khi bị chọn làm mục tiêu của Vườn Không Nhà Trống hoặc Đột Kích Trộm Lương, bạn lập tức được rút 1 lá bài.", "res://assets/ui/do_canh_thac.png", "do_canh_thac")
	_add_hero(27, "Kiều Thuận", "Thăng Long", 4, "Hồi Hồ", "Nếu trong lượt của mình bạn không sử dụng lá Trảm nào, sát thương đầu tiên bạn nhận cho tới lượt kế tiếp của bạn được giảm đi 1 điểm.", "res://assets/ui/kieu_thuan.png", "kieu_thuan")
	_add_hero(28, "Nguyễn Siêu", "Thăng Long", 4, "Liệt Chiến", "Khi tham gia vào lá Huyết Chiến, nếu bạn là người chiến thắng, hồi 1 Máu.", "res://assets/ui/nguyen_sieu.png", "nguyen_sieu")
	_add_hero(29, "Lã Đường", "Thăng Long", 4, "Tế Giang", "Khi dùng Trảm nhắm vào mục tiêu không trang bị lá Chiến Mã (+1 Khoảng cách), Tầm đánh của bạn tính là không giới hạn khoảng cách.", "res://assets/ui/la_duong.png", "la_duong")
	_add_hero(30, "Đinh Bộ Lĩnh", "Thăng Long", 4, "Cờ Lau", "Mỗi khi đòn Trảm của bạn gây sát thương lên mục tiêu, bạn được chọn: Rút 1 lá bài từ xấp rút HOẶC phá hủy 1 lá trang bị của nạn nhân.", "res://assets/ui/dinh_bo_linh.png", "dinh_bo_linh")
	_add_hero(31, "Đinh Liễn", "Thăng Long", 4, "Trữ Quân", "Đầu Giai đoạn Rút bài, bạn có thể tự giảm 1 Máu để được rút thêm 2 lá bài.", "res://assets/ui/dinh_lien.png", "dinh_lien")
	_add_hero(32, "Đinh Điền", "Thăng Long", 4, "Trung Tiết", "Khi chúa công hoặc người chơi cùng phe nhận sát thương chí tử, bạn có thể tự mất 1 Máu để họ hồi lại 1 Máu ngay lập tức.", "res://assets/ui/dinh_dien.png", "dinh_dien")
	_add_hero(33, "Nguyễn Bặc", "Thăng Long", 4, "Định Quốc", "Bạn có thể dùng bất kỳ lá bài Đen như lá Huyết Chiến.", "res://assets/ui/nguyen_bac.png", "nguyen_bac")
	_add_hero(34, "Phạm Hạp", "Thăng Long", 4, "Tận Trung", "Mỗi khi có người chơi khác sử dụng Bánh Chưng để hồi máu, bạn được rút 1 lá bài từ xấp bài rút.", "res://assets/ui/pham_hap.png", "pham_hap")
	_add_hero(35, "Lê Hoàn", "Thăng Long", 4, "Phá Tống", "Khi đánh ra lá Trảm, bạn có thể bỏ thêm 1 lá bài trên tay để đòn Trảm đó không thể bị đối phương dùng Đỡ triệt tiêu.", "res://assets/ui/le_hoan.png", "le_hoan")
	_add_hero(36, "Dương Vân Nga", "Thăng Long", 3, "Trao Bào", "Trong Giai đoạn Ra bài, bạn có thể chuyển 1 lá bài trang bị từ tay hoặc vùng trang bị của mình cho người chơi khác; người đó hồi 1 Máu và bạn được rút 1 lá bài.", "res://assets/ui/duong_van_nga.png", "duong_van_nga")
	_add_hero(37, "Lê Long Đĩnh", "Thăng Long", 4, "Bạo Nộ", "Bạn có thể sử dụng lá Hủ Rượu không giới hạn số lần trong một lượt; cuối lượt nếu không gây sát thương cho ai, bạn phải tự mất 1 Máu.", "res://assets/ui/le_long_dinh.png", "le_long_dinh")
	_add_hero(38, "Đào Cam Mộc", "Thăng Long", 3, "Phò Tá", "Trong Giai đoạn Rút bài, bạn có thể đưa số bài vừa rút được cho 1 người chơi khác thay vì giữ lại cho bản thân.", "res://assets/ui/dao_cam_moc.png", "dao_cam_moc")
	_add_hero(39, "Lý Công Uẩn", "Thăng Long", 4, "Dời Đô", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ toàn bộ bài trên tay để rút lại số lượng lá bài tương đương từ xấp rút.", "res://assets/ui/ly_cong_uan.png", "ly_cong_uan")
	_add_hero(40, "Lý Phật Mã", "Thăng Long", 4, "Thân Chinh", "Khi bạn lần đầu dùng Trảm gây sát thương thành công cho mục tiêu trong lượt, bạn được quyền đánh thêm 1 lá Trảm nữa trong lượt đó.", "res://assets/ui/ly_phat_ma.png", "ly_phat_ma")
	_add_hero(41, "Lý Nhật Tôn", "Thăng Long", 4, "Đại Việt", "Đầu lượt, bạn chọn 1 màu bài (Đỏ, Trắng, Vàng, Đen); trong lượt đó, mỗi khi bạn đánh ra 1 lá bài có màu đã chọn, bạn lập tức được rút 1 lá bài.", "res://assets/ui/ly_nhat_ton.png", "ly_nhat_ton")
	_add_hero(42, "Lý Đạo Thành", "Thăng Long", 3, "Can Gián", "Khi bất kỳ người chơi nào bị đặt Cẩm Nang Trì Hoãn, bạn có thể bỏ 1 lá bài màu Đỏ trên tay để hủy bỏ hoàn toàn lá Cẩm Nang đó.", "res://assets/ui/ly_dao_thanh.png", "ly_dao_thanh")
	_add_hero(43, "Ỷ Lan", "Thăng Long", 3, "Nhiếp Chính", "Giai đoạn Rút bài của bạn được rút 3 lá bài thay vì 2. Trong lượt, bạn có thể tặng 1 lá bài trên tay cho đồng minh.", "res://assets/ui/y_lan.png", "y_lan")
	_add_hero(44, "Tông Đản", "Thăng Long", 4, "Thổ Binh", "Khi tấn công mục tiêu ở Khoảng cách <=2, đòn Trảm của bạn không thể bị vô hiệu hóa bởi các lá Đỡ có giá trị từ 2->5.", "res://assets/ui/tong_dan.png", "tong_dan")
	_add_hero(45, "Thân Cảnh Phúc", "Thăng Long", 4, "Động Phục", "Mỗi khi bạn chịu sát thương từ các lá Cẩm Nang, bạn lập tức được rút 2 lá bài.", "res://assets/ui/than_canh_phuc.png", "than_canh_phuc")
	_add_hero(46, "Tô Hiến Thành", "Thăng Long", 3, "Thiết Diện", "Bạn miễn nhiễm hoàn toàn với các hiệu ứng ép bỏ bài hoặc cướp bài từ Vườn Không Nhà Trống và Đột Kích Trộm Lương.", "res://assets/ui/to_hien_thanh.png", "to_hien_thanh")
	_add_hero(47, "Lý Thường Kiệt", "Thăng Long", 4, "Tiến Thoái", "Bạn có thể sử dụng lá Trảm như lá Đỡ, và sử dụng lá Đỡ như lá Trảm.", "res://assets/ui/ly_thuong_kiet.png", "ly_thuong_kiet")
	_add_hero(48, "Trần Cảnh", "Đông A", 4, "Khai Sáng", "Mỗi khi bạn lắp một lá bài Vũ Khí hoặc Áo Giáp vào vùng trang bị của mình, bạn được hồi ngay 1 Máu.", "res://assets/ui/tran_canh.png", "tran_canh")
	_add_hero(49, "Trần Thủ Độ", "Đông A", 4, "Chuyên Chế", "Trong Giai đoạn Ra bài, bạn có thể bỏ 1 lá bài trên tay để chỉ định hủy 1 lá trang bị của người khác đang đeo trang bị; người đó phải ra 1 lá Trảm hoặc mất 1 Máu.", "res://assets/ui/tran_thu_do.png", "tran_thu_do")
	_add_hero(50, "Trần Liễu", "Đông A", 4, "Ấp Phụ", "Khi bạn bị mất Máu do hành động của người chơi khác, bạn được rút 1 lá bài từ xấp rút và lấy 1 lá Trảm từ xấp bài bỏ vào tay (nếu có).", "res://assets/ui/tran_lieu.png", "tran_lieu")
	_add_hero(51, "Trần Hoảng", "Đông A", 4, "Hội Nghị", "Khi bạn hoặc người chơi khác sử dụng lá Mở Kho Cứu Tế, bạn được chỉ định thêm người, bạn và họ rút thêm 1 lá bài từ xấp bài rút.", "res://assets/ui/tran_hoang.png", "tran_hoang")
	_add_hero(52, "Trần Khâm", "Đông A", 4, "Thiền Tâm", "Khi rơi vào trạng thái Cận Tử (0 Máu), bạn có thể bỏ 2 lá bài trên tay để tự hồi phục 1 Máu mà không cần dùng Bánh Chưng hay Hủ Rượu.", "res://assets/ui/tran_kham.png", "tran_kham")
	_add_hero(53, "Trần Quốc Tuấn", "Đông A", 4, "Hịch Tướng", "Trong Giai đoạn Ra bài, bạn có thể chọn phát động lệnh tập kích: Từng người chơi có thể tự nguyện bỏ 1 lá Trảm để giúp bạn rút 1 lá bài.", "res://assets/ui/tran_hung_dao.png", "tran_hung_dao")
	_add_hero(54, "Trần Quang Khải", "Đông A", 4, "Thái Bình", "Cuối lượt của bạn, nếu bạn không sử dụng bất kỳ lá Trảm nào trong lượt đó, bạn có thể lấy 1 lá Áo Giáp hoặc Chiến Mã từ xấp bài bỏ gắn trực tiếp vào vùng trang bị của mình.", "res://assets/ui/tran_quang_khai.png", "tran_quang_khai")
	_add_hero(55, "Trần Nhật Duật", "Đông A", 3, "Đồng Hóa", "Khi trở thành mục tiêu của Huyết Chiến hoặc Đột Kích Trộm Lương, bạn có thể đổi 1 lá bài trên tay của mình với 1 lá bài ngẫu nhiên trên tay kẻ phát động trước khi giải quyết hiệu ứng.", "res://assets/ui/tran_nhat_duat.png", "tran_nhat_duat")
	_add_hero(56, "Trần Quốc Toản", "Đông A", 4, "Phá Cường Địch", "Trong lượt, nếu vùng trang bị của bạn chưa gắn Vũ Khí, đòn Trảm đầu tiên bạn đánh ra sẽ gây thêm +1 sát thương nếu trúng đích.", "res://assets/ui/tran_quoc_toan.png", "tran_quoc_toan")
	_add_hero(57, "Trần Bình Trọng", "Đông A", 4, "Bảo Quốc", "Khi bạn bị hạ gục, bạn có thể chỉ định kẻ tiêu diệt mình phải hủy toàn bộ bài trong vùng trang bị và bỏ 2 lá bài trên tay.", "res://assets/ui/tran_binh_trong.png", "tran_binh_trong")
	_add_hero(58, "Trần Khánh Dư", "Đông A", 4, "Đoạt Lương", "Khi bạn sử dụng thành công lá Cắt Đường Lương lên mục tiêu bất kỳ, bạn lập tức được rút 2 lá bài từ xấp rút.", "res://assets/ui/tran_khanh_du.png", "tran_khanh_du")
	_add_hero(59, "Phạm Ngũ Lão", "Đông A", 4, "Phục Kích", "Giới hạn 1 lượt 1 lần, bạn có thể dùng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Đột Kích Trộm Lương.", "res://assets/ui/pham_ngu_lao.png", "pham_ngu_lao")
	_add_hero(60, "Yết Kiêu", "Đông A", 4, "Thấu Thủy", "Bạn miễn nhiễm hoàn toàn với sát thương từ lá Giặc Tới. Bạn có thể dùng bất kỳ lá Trảm nào như một lá Trảm - Thủy.", "res://assets/ui/yet_kieu.png", "yet_kieu")
	_add_hero(61, "Dã Tượng", "Đông A", 4, "Ngự Tượng", "Bạn mặc định sở hữu hiệu ứng tăng khoảng cách của Voi Chiến Đại Việt (+1 Khoảng cách) mà không cần phải trang bị lá bài này, nếu trang bị, khoảng cách phòng thủ của bạn trở thành +2.", "res://assets/ui/da_tuong.png", "da_tuong")
	_add_hero(62, "Đỗ Khắc Chung", "Đông A", 3, "Thuyết Khách", "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 1 lá Cẩm Nang bất kỳ trên tay để vô hiệu hóa hoàn toàn đòn đánh đó.", "res://assets/ui/do_khac_chung.png", "do_khac_chung")
	_add_hero(63, "Hà Đặc", "Đông A", 4, "Tráng Khí", "Khi bạn đánh ra lá Trảm, nếu mục tiêu dùng lá Đỡ để triệt tiêu đòn đánh, bạn lập tức được rút 1 lá bài từ xấp bài rút.", "res://assets/ui/ha_dac.png", "ha_dac")
	_add_hero(64, "Hà Chương", "Đông A", 4, "Thác Binh", "Mỗi khi bạn nhận sát thương, bạn được xem 2 lá bài trên cùng của xấp bài rút, lấy 1 lá vào tay và đặt 1 lá còn lại xuống đáy xấp bài.", "res://assets/ui/ha_chuong.png", "ha_chuong")
	_add_hero(65, "Nguyễn Khoái", "Đông A", 4, "Tiệp Lộ", "Khi bạn sử dụng lá Giặc Tới, bạn có thể chỉ định tối đa 2 người chơi khác không phải chịu ảnh hưởng của lá bài này.", "res://assets/ui/nguyen_khoai.png", "nguyen_khoai")
	_add_hero(66, "Trần Thì Kiến", "Đông A", 3, "Cương Trực", "Đối phương không thể sử dụng lá Diệu Kế Phá Mưu để vô hiệu hóa các lá Cẩm Nang do bạn đánh ra.", "res://assets/ui/tran_thi_kien.png", "tran_thi_kien")
	_add_hero(67, "Chu Văn An", "Đông A", 3, "Thất Trảm", "Trong Giai đoạn Ra bài, giới hạn 2 lần, bạn có thể bỏ 2 lá bài cùng chất trên tay để phá hủy 1 lá bài bất kỳ trong vùng chơi của một người chơi khác, sau đó rút 1 lá.", "res://assets/ui/chu_van_an.png", "chu_van_an")
	_add_hero(68, "Trương Hán Siêu", "Đông A", 3, "Bạch Đằng Phú", "Khi bạn sử dụng lá Cẩm Nang Dụng Binh Như Thần, bạn được rút 3 lá bài thay vì 2 lá bài từ xấp rút.", "res://assets/ui/truong_han_sieu.png", "truong_han_sieu")
	_add_hero(69, "Mạc Đĩnh Chi", "Đông A", 3, "Lưỡng Quốc", "Giới hạn bài giữ trên tay tối đa trong Giai đoạn Bỏ bài của bạn luôn bằng Máu tối đa của bạn cộng thêm 1.", "res://assets/ui/mac_dinh_chi.png", "mac_dinh_chi")
	_add_hero(70, "Đoàn Nhữ Hài", "Đông A", 3, "Sứ Giả", "Trong Giai đoạn Ra bài, bạn có thể đưa 1 lá bài trên tay cho một người chơi khác để lấy 1 lá trang bị từ vùng trang bị của họ đưa về tay mình.", "res://assets/ui/doan_nhu_hai.png", "doan_nhu_hai")
	_add_hero(71, "Trần Nghệ Tông", "Đông A", 4, "Bảo Thủ", "Bạn miễn nhiễm hoàn toàn với hiệu ứng giam cầm của Cẩm Nang Trì Hoãn Trầm Ảo Sa Bẫy.", "res://assets/ui/tran_nghe_tong.png", "tran_nghe_tong")
	_add_hero(72, "Trần Duệ Tông", "Đông A", 4, "Trực Chiến", "Khi bạn đánh ra lá Trảm, đối phương bắt buộc phải sử dụng lá Đỡ >=7 điểm mới có thể triệt tiêu đòn đánh.", "res://assets/ui/tran_due_tong.png", "tran_due_tong")
	_add_hero(73, "Trần Khát Chân", "Đông A", 4, "Hỏa Pháo", "Khi bạn sử dụng lá Trảm - Hỏa gây sát thương thành công cho mục tiêu, bạn có thể bắt mục tiêu phải bỏ thêm 1 lá bài trên tay hoặc nhận thêm 1 sát thương thường.", "res://assets/ui/tran_khat_chan.png", "tran_khat_chan")
	_add_hero(74, "Đỗ Tử Bình", "Đông A", 4, "Úng Binh", "Khi một người chơi cùng thế lực nhận sát thương từ người khác, bạn được quyền rút ngay 1 lá bài từ xấp bài rút.", "res://assets/ui/do_tu_binh.png", "do_tu_binh")
	_add_hero(75, "Nguyễn Sư Tề", "Đông A", 4, "Chấn Giáp", "Mỗi khi bạn lắp một lá Áo Giáp vào vùng trang bị của mình, bạn được rút ngay 1 lá bài từ xấp bài rút.", "res://assets/ui/nguyen_su_te.png", "nguyen_su_te")
	_add_hero(76, "Hồ Quý Ly", "Đông A", 4, "Cải Chế", "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể bỏ 1 lá bài bất kỳ trên tay để lấy 1 lá Trảm hoặc Đỡ từ xấp bài bỏ vào tay.", "res://assets/ui/ho_quy_ly.png", "ho_quy_ly")
	_add_hero(77, "Hồ Hán Thương", "Đông A", 4, "Tiền Giấy", "Trong Giai đoạn Bỏ bài, các lá bài bạn phải bỏ đi có thể được trao cho các người chơi khác tùy ý thay vì đưa vào xấp bài bỏ.", "res://assets/ui/ho_han_thuong.png", "ho_han_thuong")
	_add_hero(78, "Hồ Nguyên Trừng", "Đông A", 3, "Thần Cơ", "Bạn có thể dùng bất kỳ lá bài Đen nào như lá vũ khí Súng Thần Công Hồ Triều hoặc sử dụng như một lá Trảm - Hỏa.", "res://assets/ui/ho_nguyen_trung.png", "ho_nguyen_trung")
	_add_hero(79, "Trần Ngỗi", "Đông A", 4, "Phục Hưng", "Đầu Giai đoạn Rút bài, nếu lượng Máu hiện tại của bạn từ 2 trở xuống, bạn được rút thêm 1 lá bài từ xấp rút.", "res://assets/ui/tran_ngoi.png", "tran_ngoi")
	_add_hero(80, "Trần Quý Khoáng", "Đông A", 4, "Kế Nghiệp", "Khi một đồng minh cùng thế lực bị hạ gục, bạn được thu toàn bộ số bài trên tay và vùng trang bị còn lại của người đó vào tay mình.", "res://assets/ui/tran_quy_khoang.png", "tran_quy_khoang")
	_add_hero(81, "Đặng Dung", "Đông A", 4, "Mài Kiếm", "Bạn có thể dùng lá Hủ Rượu như một lá Trảm Thường; đòn Trảm này không thể bị triệt tiêu bởi lá Đỡ.", "res://assets/ui/dang_dung.png", "dang_dung")
	_add_hero(82, "Đặng Tất", "Đông A", 4, "Trận Pháp", "Khi bạn sử dụng lá Cẩm Nang Vườn Không Nhà Trống, bạn có thể chọn đồng thời 2 mục tiêu thay vì 1.", "res://assets/ui/dang_tat.png", "dang_tat")
	_add_hero(83, "Nguyễn Cảnh Chân", "Đông A", 4, "Thủy Binh", "Bạn có thể dùng bất kỳ lá bài Vàng nào trên tay như một lá Đỡ.", "res://assets/ui/nguyen_canh_chan.png", "nguyen_canh_chan")
	_add_hero(84, "Nguyễn Cảnh Dị", "Đông A", 4, "Kỵ Chiến", "Khoảng cách tấn công tính từ bạn tới tất cả các người chơi khác luôn được giảm 1 điểm (tương tự hiệu ứng của Ngựa Trắng Thuần Nông). Nếu mang Ngựa Trắng Thuần Nông, khoảng cách sẽ là -2.", "res://assets/ui/nguyen_canh_di.png", "nguyen_canh_di")
	_add_hero(85, "Nguyễn Biểu", "Đông A", 3, "Trinh Tiết", "Khi bạn là mục tiêu của lá Huyết Chiến, bạn có thể không ra lá Trảm mà không bị mất Máu; thay vào đó, kẻ phát động phải bỏ 1 lá bài trên tay.", "res://assets/ui/nguyen_bieu.png", "nguyen_bieu")
	_add_hero(86, "Lê Lợi", "Đông A", 4, "Khởi Nghĩa", "Khi bạn trang bị vũ khí Kiếm Thuận Thiên, mỗi đòn Trảm của bạn gây trúng đích sẽ gây thêm +1 điểm sát thương. Đầu lượt, nếu trên tay hoặc trang bị chưa có Kiếm Thuận Thiên, nếu Kiếm Thuận Thiên nằm trên chồng bài rút hoặc bài bỏ, thu lấy nó.", "res://assets/ui/le_loi.png", "le_loi")
	_add_hero(87, "Nguyễn Trãi", "Đông A", 3, "Bình Ngô", "Trong Giai đoạn Ra bài, bạn có thể bỏ 2 lá Cẩm Nang trên tay để chỉ định 1 người chơi phải bỏ toàn bộ bài trên tay xuống xấp bài bỏ.", "res://assets/ui/nguyen_trai.png", "nguyen_trai")
	_add_hero(88, "Lê Lai", "Đông A", 4, "Liều Thân", "Khi một người chơi khác nhận sát thương chí tử, bạn có thể tự giảm 1 Máu của mình để gánh toàn bộ sát thương đó thay cho mục tiêu.", "res://assets/ui/le_lai.png", "le_lai")
	_add_hero(89, "Trần Nguyên Hãn", "Đông A", 4, "Thủy Kế", "Bạn có thể sử dụng bất kỳ lá bài Trắng nào trên tay như một lá Cẩm Nang Giặc Tới.", "res://assets/ui/tran_nguyen_han.png", "tran_nguyen_han")
	_add_hero(90, "Lưu Nhân Chú", "Đông A", 4, "Tráng Tiết", "Khi bạn đánh ra lá Trảm - Thủy, đòn đánh này bỏ qua hoàn toàn các hiệu ứng phòng vệ từ các lá Áo Giáp của mục tiêu.", "res://assets/ui/luu_nhan_chu.png", "luu_nhan_chu")
	_add_hero(91, "Đinh Liệt", "Đông A", 4, "Thiết Kỵ", "Khi dùng Trảm nhắm vào mục tiêu đang gắn Chiến Mã (+1 Khoảng cách), bạn được quyền bỏ qua hiệu ứng tăng khoảng cách của lá ngựa đó.", "res://assets/ui/dinh_liet.png", "dinh_liet")
	_add_hero(92, "Phạm Văn Xảo", "Đông A", 3, "Trấn Tây", "Khi vùng trang bị của bạn hoàn toàn trống, mọi sát thương bạn phải nhận từ các đòn Trảm thường đều được giảm đi 1 điểm.", "res://assets/ui/pham_van_xao.png", "pham_van_xao")
	_add_hero(93, "Lê Sát", "Đông A", 4, "Dũng Tướng", "Bạn có thể sử dụng bất kỳ lá bài màu Đen nào trên tay như một lá Cẩm Nang Huyết Chiến.", "res://assets/ui/le_sat.png", "le_sat")
	_add_hero(94, "Lê Ngân", "Đông A", 3, "Mật Vũ", "Cuối lượt, bạn có thể đặt úp 1 lá bài trên tay vào khu vực riêng; khi bị nhắm bởi Trảm, bạn có thể lật lá bài này lên để tính như vừa đánh ra 1 lá Đỡ.", "res://assets/ui/le_ngan.png", "le_ngan")
	_add_hero(95, "Nguyễn Xí", "Đông A", 4, "Khuyển Đội", "Mỗi khi đòn Trảm của bạn gây sát thương thành công, bạn được rút ngẫu nhiên 1 lá bài trên tay của nạn nhân.", "res://assets/ui/nguyen_xi.png", "nguyen_xi")
	_add_hero(96, "Trịnh Khả", "Đông A", 4, "Bình Định", "Khi bạn sử dụng lá Vườn Không Nhà Trống lên mục tiêu, thay vì bạn chọn, nạn nhân phải đồng thời phải tự bỏ 1 lá bài trên tay và chọn phá hủy 1 lá bài trong vùng trang bị (nếu có), sau đó bạn rút 1 lá.", "res://assets/ui/trinh_kha.png", "trinh_kha")
	_add_hero(97, "Nguyễn Chích", "Đông A", 3, "Bồ Câu", "Tầm tác dụng của các lá Cẩm Nang do bạn sử dụng không bị giới hạn bởi khoảng cách bàn chơi.", "res://assets/ui/nguyen_chich.png", "nguyen_chich")
	_add_hero(98, "Bùi Bị", "Đông A", 4, "Dũng Hãn", "Khi bạn sử dụng Trảm nhắm vào mục tiêu có lượng Máu hiện tại nhiều hơn bạn, đòn Trảm đó không thể bị đối phương dùng lá Đỡ triệt tiêu.", "res://assets/ui/bui_bi.png", "bui_bi")
	_add_hero(99, "Lê Khôi", "Đông A", 4, "Khai Biên", "Mỗi khi bạn tiêu diệt thành công một người chơi khác, bạn lập tức được hồi 1 Máu và rút thêm 2 lá bài từ xấp bài rút.", "res://assets/ui/le_khoi.png", "le_khoi")
	_add_hero(100, "Nguyễn Nhữ Lãm", "Đông A", 4, "Trấn Ải", "Bạn hoàn toàn miễn nhiễm với các lá Cẩm Nang Trì Hoãn.", "res://assets/ui/nguyen_nhu_lam.png", "nguyen_nhu_lam")

func _add_hero(id: int, name: String, faction: String, hp: int, skill_name: String, skill_desc: String, avatar_path: String, slug: String) -> void:
	var skills: Array = [{"id": skill_name.to_lower().replace(" ", "_"), "name": skill_name, "desc": skill_desc}]
	if id == 1:
		skills = [
			{"id": "che_no", "name": "Chế Nỏ", "desc": "Bạn có thể dùng bất kỳ lá bài Đen như lá trang bị Nỏ Thần Kim Quy."},
			{"id": "lien_chau", "name": "Liên Châu", "desc": "Bạn đánh ra lá Trảm khi đang đeo Nỏ Thần Kim Quy, bạn có thể bỏ thêm 1 lá bài trên tay để chọn thêm 1 mục tiêu khác trong Tầm đánh."}
		]
	elif id == 2:
		skills = [
			{"id": "xa_thuan", "name": "Xạ Thuẫn", "desc": "Bạn mặc định tăng 2 tầm Ngựa công."},
			{"id": "phu_tran", "name": "Phù Trấn", "desc": "Khi bạn sử dụng Trảm mà không đeo vũ khí, bạn được rút 1 lá bài."}
		]
	elif id == 3:
		skills = [
			{"id": "hich_nghia", "name": "Hịch Nghĩa", "desc": "Khi bạn rơi vào trạng thái Cận Tử, bạn lập tức rút 3 lá bài."},
			{"id": "uat_khi", "name": "Uất Khí", "desc": "Khi bạn bị mất Máu mà chưa rơi vào trạng thái Cận Tử, bạn có thể cho 1 mục tiêu rút 1 lá bài."}
		]
	elif id == 4:
		skills = [
			{"id": "trieu_dang", "name": "Triều Dâng", "desc": "Một lần mỗi lượt, chỉ định hủy 1 lá trang bị của 1 người khác."},
			{"id": "lap_lang", "name": "Lập Làng", "desc": "Cuối lượt của mình, nếu bạn không gây sát thương, bạn rút 2 lá bài."}
		]
	elif id == 5:
		skills = [
			{"id": "dung_nu", "name": "Dũng Nữ", "desc": "Đòn Trảm của bạn khiến mục tiêu phải đánh ra 2 lá Đỡ mới có thể triệt tiêu nếu mục tiêu có lượng Máu hiện tại nhiều hơn bạn."},
			{"id": "thu_muc", "name": "Thủ Mục", "desc": "Trước khi nhận sát thương từ lá Trảm, bạn có thể bỏ 1 lá bài Đỏ hoặc bài Trắng trên tay để khiến đòn Trảm đó bị giảm đi 1 điểm sát thương."}
		]
	elif id == 6:
		skills = [
			{"id": "trinh_liet", "name": "Trinh Liệt", "desc": "Mỗi khi chịu sát thương từ đòn Trảm, bạn được rút 1 lá bài trong vùng chơi của nguồn gây sát thương."},
			{"id": "bat_na", "name": "Bát Nạ", "desc": "Trong Giai đoạn Ra bài giới hạn 1 lần, bạn có thể biến 1 lá Bài Cơ Bản thành lá Trảm thường không tính vào giới hạn lần sử dụng Trảm trong lượt."}
		]
	elif id == 7:
		skills = [
			{"id": "tien_phong", "name": "Tiên Phong", "desc": "Trong lượt đầu tiên của trận đấu, bạn được rút thêm 2 lá bài và không bị giới hạn số lần ra lá Trảm trong lượt đầu tiên."},
			{"id": "tran_tien", "name": "Trận Tiền", "desc": "Khi bạn hạ gục 1 người, bạn được lập tức rút 2 lá."}
		]
	elif id == 8:
		skills = [
			{"id": "khoi_binh", "name": "Khởi Binh", "desc": "Khi người khác dùng Trảm gây sát thương thành công, bạn có thể chọn cho bạn và họ, mỗi người rút 1 lá bài."},
			{"id": "huynh_truong", "name": "Huynh Trưởng", "desc": "Khi bạn bị mất Máu, bạn có thể chuyển 1 lá bài trên tay mình cho 1 người khác, sau đó rút 1 lá."}
		]
	elif id == 9:
		skills = [
			{"id": "chien_tuong", "name": "Chiến Tượng", "desc": "Khi có trang bị trên ô Ngựa, sát thương gây ra bởi Trảm +1."},
			{"id": "oai_nhuoc", "name": "Oai Nhược", "desc": "Mỗi khi bạn đánh ra 1 lá Trảm - Hỏa hoặc Trảm - Thủy, đối phương phải bỏ 1 lá bài trên tay trước khi đánh ra lá Đỡ."}
		]
	elif id == 10:
		skills = [
			{"id": "dung_nuoc", "name": "Dựng Nước", "desc": "Đầu Giai đoạn Rút bài, bạn có thể bỏ qua việc rút bài để hồi 1 Máu và thu ngẫu nhiên 1 lá bài Đỏ từ xấp bài bỏ vào tay nếu có."},
			{"id": "xung_de", "name": "Xưng Đế", "desc": "Khi bạn không bị thương, giới hạn bài giữ trên tay của bạn được tăng thêm 2 lá."}
		]
	elif id == 11:
		skills = [
			{"id": "tung_nghia", "name": "Tùng Nghĩa", "desc": "Khi vùng trang bị của bạn có ít nhất 1 lá Chiến Mã hoặc Áo Giáp, cuối lượt, bạn được rút 1 lá và giới hạn trữ bài +1."},
			{"id": "trung_kien", "name": "Trung Kiên", "desc": "Khi một người sắp vào trạng thái tử trận, bạn có thể tự giảm 1 Máu để giúp người đó hồi đến 1 máu."}
		]
	elif id == 12:
		skills = [
			{"id": "han_lam", "name": "Hán Lâm", "desc": "Mỗi khi bạn dùng thành công một lá Bài Cẩm Nang, bạn được xem lá bài trên cùng của xấp bài rút và có quyền chọn để nguyên hay đặt xuống đáy, sau đó rút 1 lá."},
			{"id": "van_sach", "name": "Văn Sách", "desc": "Sau khi bạn sử dụng lá bài Cẩm Nang thứ hai trong lượt, bạn có thể bỏ 1 lá bài trên tay để rút 1 lá."}
		]
	elif id == 13:
		skills = [
			{"id": "tran_nam", "name": "Trấn Nam", "desc": "Bạn miễn nhiễm hoàn toàn với sát thương từ Cẩm Nang Giặc Tới. Khi bạn dùng Trảm Thường Đen hoặc Vàng, mục tiêu không thể kích hoạt hiệu ứng của Giáp Đồng Sơn Vi."},
			{"id": "hoa_dan", "name": "Hóa Dân", "desc": "Cuối lượt của bạn, nếu bạn đang đeo trang bị Áo Giáp, bạn có thể bỏ 1 trang bị bất kỳ để hồi 1 máu."}
		]
	elif id == 14:
		skills = [
			{"id": "da_trach", "name": "Dạ Trạch", "desc": "Khi bạn không còn lá bài nào trên tay, bạn không thể trở thành mục tiêu của các đòn Trảm. Đầu lượt, nếu trên tay bạn không có bài, bạn được rút thêm 1 lá. Cuối lượt, nếu trên tay bạn có bài, bạn có thể bỏ thêm 1 lá nếu muốn."},
			{"id": "no_dinh", "name": "Nỏ Đỉnh", "desc": "Đòn Trảm của bạn đánh ra có Tầm đánh không giới hạn khi bạn có số Máu bé hơn hoặc bằng 2."}
		]
	elif id == 15:
		skills = [
			{"id": "phuc_ho", "name": "Phục Hổ", "desc": "Khi bạn sử dụng lá Huyết Chiến hoặc bị người khác chỉ định bởi Huyết Chiến, đối phương phải ra 2 lá Trảm cho mỗi lần đáp trả."},
			{"id": "an_dan", "name": "An Dân", "desc": "Đầu lượt, bạn có thể chọn bỏ qua việc rút bài để di chuyển 1 lá Cẩm Nang Trì Hoãn đang đặt lên người bất kỳ sang người khác. Nếu làm vậy, sau khi thao tác xong, bạn có thể chọn 1 mục tiêu xem như sử dụng 1 lá Huyết Chiến lên họ."}
		]
	elif id == 16:
		skills = [
			{"id": "luc_dich", "name": "Lực Địch", "desc": "Bạn có thể trang bị tối đa 2 lá Vũ Khí cùng lúc trên vùng trang bị của mình, tầm đánh và kỹ năng trang bị được cộng dồn."},
			{"id": "hung_suc", "name": "Hùng Sức", "desc": "Trong Giai đoạn Ra bài, bạn có thể bỏ 1 lá Vũ Khí để gây 1 sát thương lên 1 mục tiêu trong Tầm đánh 1, sau đó rút 1 lá."}
		]
	elif id == 17:
		skills = [
			{"id": "van_an", "name": "Vạn An", "desc": "Giới hạn mỗi lượt 2 lần, bạn có thể dùng 2 lá bài bất kỳ trên tay để xem như sử dụng lá Cẩm Nang Bãi Cọc Bạch Đằng. Lần đầu sử dụng trong lượt, rút 1 lá bài."},
			{"id": "de_nghiep", "name": "Đế Nghiệp", "desc": "Mỗi khi bạn gây sát thương đơn mục tiêu bằng Cẩm Nang, bạn rút 1 lá bài."}
		]
	elif id == 18:
		skills = [
			{"id": "khoan_gian", "name": "Khoan Giản", "desc": "Sau giai đoạn Bỏ bài, bạn được rút X+1 lá, giới hạn trữ bài +(X+1) (X là một nửa số trang bị bạn đang mang, làm tròn lên)."},
			{"id": "chinh_thong", "name": "Chính Thống", "desc": "Đầu lượt của bạn, bạn có thể chọn 1 người chơi khác; người đó phải chuyển 1 lá bài trên tay cho bạn hoặc lộ diện toàn bộ bài trên tay."}
		]
	elif id == 19:
		skills = [
			{"id": "khoan_hoa", "name": "Khoan Hòa", "desc": "Cuối lượt của bạn, nếu bạn không gây sát thương cho bất kỳ ai trong lượt đó, bạn rút 1 lá bài, sau đó bạn chọn tối đa 2 người chơi khác, mỗi người trong số họ rút 1 lá bài."},
			{"id": "cai_cach", "name": "Cải Cách", "desc": "Trong Giai đoạn Ra bài, giới hạn 1 lần, bạn có thể đổi 2 lá bài lấy 2 lá bài mới."}
		]
	elif id == 20:
		skills = [
			{"id": "nghia_tu", "name": "Nghĩa Tử", "desc": "Khi một người chơi khác bị nhận sát thương, bạn có thể bỏ 1 lá bài trên tay để chịu thay 1 sát thương cho họ."},
			{"id": "duong_binh", "name": "Dưỡng Binh", "desc": "Mỗi khi bạn chịu thay sát thương, rút 2 lá."}
		]
	elif id == 21:
		skills = [
			{"id": "nghich_y", "name": "Nghịch Ý", "desc": "Khi trở thành mục tiêu của đòn Trảm, bạn có thể bỏ 1 lá bài trên tay để chuyển mục tiêu của đòn Trảm đó sang 1 người chơi khác trong tầm đánh của bạn."},
			{"id": "dan_cau", "name": "Dẫn Cầu", "desc": "Trong Giai đoạn Ra bài giới hạn 1 lần, bạn có thể trao 1 lá bài trên tay cho người khác để ép họ phải đánh ra 1 lá Trảm nhắm vào 1 mục tiêu do bạn chỉ định, nếu họ không đánh hoặc không thể đánh, bạn cướp 2 lá trong vùng chơi của họ."}
		]
	elif id == 22:
		skills = [
			{"id": "thuy_chien", "name": "Thủy Chiến", "desc": "Bạn có thể dùng bất kỳ lá bài Trắng hoặc bài Vàng như một lá Bãi Cọc Bạch Đằng; bạn không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng."},
			{"id": "coc_ngam", "name": "Cọc Ngầm", "desc": "Khi đòn Trảm Thủy của bạn gây sát thương lên mục tiêu đang bị Cẩm Nang Bãi Cọc Bạch Đằng, sát thương đó được tăng thêm +1."}
		]
	elif id == 23:
		skills = [
			{"id": "doat_vi", "name": "Đoạt Vị", "desc": "Khi có người chơi bị tiêu diệt, bạn thu lấy toàn bộ số bài trên tay và vùng trang bị của nạn nhân."},
			{"id": "xung_vuong", "name": "Xưng Vương", "desc": "Giai đoạn Rút bài, nếu bạn là một trong những người có nhiều bài trên tay nhất, bạn được rút thêm 1 lá bài. Nếu bạn là một trong những người có ít bài trên tay nhất, bạn chọn tối đa 2 người, yêu cầu họ tự bỏ 1 lá trên tay hoặc trang bị."}
		]
	elif id == 24:
		skills = [
			{"id": "thien_cam", "name": "Thiên Cảm", "desc": "Khi lượng Máu hiện tại của bạn từ 1 trở xuống, bạn không thể bị đặt các lá Cẩm Nang Trì Hoãn, các lá Cẩm Nang Trì Hoãn đang trên người bạn đi vào xấp bài bỏ. Bạn có thể đổi lá Cẩm Nang Trì Hoãn trên tay thành 2 lá mới."},
			{"id": "an_tich", "name": "Ẩn Tích", "desc": "Cuối lượt của mình, nếu không gây sát thương trong lượt và chưa có “Ẩn”, bạn được đặt 1 lá bài trên tay úp xuống, gọi là “Ẩn”; khi cần dùng Đỡ, có thể bỏ lá “Ẩn” ra, xem như vừa dùng 1 lá Đỡ."}
		]
	elif id == 25:
		skills = [
			{"id": "nam_tan", "name": "Nam Tấn", "desc": "Khi Trảm của bạn gây sát thương, rút 1 lá."},
			{"id": "binh_san", "name": "Bình Sạn", "desc": "Trong Giai đoạn Ra bài, bạn có thể bỏ 1 lá trang bị để hủy 1 lá bài trong vùng chơi của 1 mục tiêu."}
		]
	elif id == 26:
		skills = [
			{"id": "cat_cu", "name": "Cát Cứ", "desc": "Mỗi khi bị chọn làm mục tiêu của Vườn Không Nhà Trống hoặc Đột Kích Trộm Lương, bạn lập tức được rút 1 lá bài."},
			{"id": "co_thu", "name": "Cố Thủ", "desc": "Khi bạn có trang bị trên ô Áo Giáp, khoảng cách phòng thủ của bạn đối với tất cả người chơi khác +1."}
		]
	elif id == 27:
		skills = [
			{"id": "hoi_ho", "name": "Hồi Hồ", "desc": "Nếu trong lượt của mình bạn không sử dụng lá Trảm nào, sát thương đầu tiên bạn nhận cho tới lượt kế tiếp của bạn được giảm đi 1 điểm."},
			{"id": "phong_duyen", "name": "Phòng Duyện", "desc": "Cuối lượt của bạn, bạn được lấy lại 1 lá bài Đen từ xấp bài bỏ đưa về tay nếu vòng vừa rồi bạn không nhận sát thương."}
		]
	elif id == 28:
		skills = [
			{"id": "liet_chien", "name": "Liệt Chiến", "desc": "Khi tham gia vào lá Huyết Chiến, nếu bạn là người chiến thắng, hồi 1 Máu."},
			{"id": "tay_phu", "name": "Tây Phu", "desc": "Bạn có thể dùng 2 lá trên tay để xem như sử dụng 1 lá Cẩm Nang Huyết Chiến nhắm vào mục tiêu bất kỳ."}
		]
	var h = {
		"id": id,
		"name": name,
		"faction": faction,
		"maxHp": hp,
		"skills": skills,
		"avatarPath": avatar_path,
		"slug": slug
	}
	hero_dict[id] = h
	all_heroes.append(h)

static func get_faction_full_name(faction: String) -> String:
	match faction:
		"Hồng Bàng": return "Hồng Bàng"
		"Thăng Long": return "Thăng Long"
		"Đông A": return "Đông A"
		"Đại Nam": return "Đại Nam"
		_: return faction

static func get_faction_color(faction: String) -> Color:
	match faction:
		"Hồng Bàng": return Color(0.15, 0.85, 0.55, 1.0)
		"Thăng Long": return Color(0.15, 0.75, 0.95, 1.0)
		"Đông A": return Color(0.95, 0.45, 0.2, 1.0)
		"Đại Nam": return Color(0.95, 0.4, 0.65, 1.0)
		_: return Color(0.85, 0.85, 0.85, 1.0)
