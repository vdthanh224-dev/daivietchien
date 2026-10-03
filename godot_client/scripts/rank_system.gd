extends Node

# Hệ Thống 12 Bậc Xếp Hạng 2v2 Đại Việt Chiến (Godot)
# Cơ chế tính điểm bằng Sao (Stars) & Điểm Tích Lũy (Accumulation/Bravery Points)

const STARS_PER_TIER := 5
const WIN_STARS := 1
const LOSE_STARS := -1
const WIN_ACCUMULATION_POINTS := 25
const LOSE_ACCUMULATION_POINTS := 10
const MAX_ACCUMULATION_POINTS := 100

const RANK_DATA := [
	{
		"index": 0,
		"tier": 1,
		"name": "Dân Binh",
		"badge": "🛡️",
		"icon_path": "res://assets/ui/ranks/dan_binh.png",
		"stars": 5,
		"color": Color(0.63, 0.68, 0.75),
		"description": "Nghĩa dũng mới gia nhập thao trường 2v2, bắt đầu rèn luyện tinh thần kề vai sát cánh."
	},
	{
		"index": 1,
		"tier": 2,
		"name": "Hương Dũng",
		"badge": "⚔️",
		"icon_path": "res://assets/ui/ranks/huong_dung.png",
		"stars": 5,
		"color": Color(0.80, 0.84, 0.88),
		"description": "Lực lượng tự vệ địa phương thiện chiến, biết tiếp ứng và bọc lót cơ bản cho đồng đội."
	},
	{
		"index": 2,
		"tier": 3,
		"name": "Lại Viên",
		"badge": "📜",
		"icon_path": "res://assets/ui/ranks/lai_vien.png",
		"stars": 5,
		"color": Color(0.49, 0.83, 0.99),
		"description": "Quan viên phụ trách quân vụ, nắm rõ quy tắc chia sẻ tài nguyên và điều phối nhịp độ trận đấu."
	},
	{
		"index": 3,
		"tier": 4,
		"name": "Chủ Sự",
		"badge": "🎖️",
		"icon_path": "res://assets/ui/ranks/chu_su.png",
		"stars": 5,
		"color": Color(0.22, 0.74, 0.97),
		"description": "Chủ trì việc quân cơ, phối hợp đồng đội công thủ song toàn, giữ vững thế trận."
	},
	{
		"index": 4,
		"tier": 5,
		"name": "Viên Ngoại Lang",
		"badge": "🏮",
		"icon_path": "res://assets/ui/ranks/vien_ngoai_lang.png",
		"stars": 5,
		"color": Color(0.29, 0.87, 0.50),
		"description": "Tướng tài đắc lực nơi tiền tuyến, tung combo bài ăn ý bẻ gãy ý đồ của đối phương."
	},
	{
		"index": 5,
		"tier": 6,
		"name": "Lang Trung",
		"badge": "🏯",
		"icon_path": "res://assets/ui/ranks/lang_trung.png",
		"stars": 5,
		"color": Color(0.98, 0.80, 0.08),
		"description": "Trọng thần nắm quyền điều hành nha môn, tạo lá chắn thép bất khả xâm phạm cùng bạn đồng hành."
	},
	{
		"index": 6,
		"tier": 7,
		"name": "Thị Lang",
		"badge": "⚡",
		"icon_path": "res://assets/ui/ranks/thi_lang.png",
		"stars": 5,
		"color": Color(0.98, 0.57, 0.24),
		"description": "Phó thủ lĩnh bộ bộ triều đình, mưu lược kỳ biến, chuyên tạo các pha lật kèo 2v2 ngoạn mục."
	},
	{
		"index": 7,
		"tier": 8,
		"name": "Thượng Thư",
		"badge": "👑",
		"icon_path": "res://assets/ui/ranks/thuong_thu.png",
		"stars": 5,
		"color": Color(0.97, 0.44, 0.44),
		"description": "Đứng đầu Lục Bộ triều đình, uy danh hiển hách, cặp bài trùng bách chiến bách thắng."
	},
	{
		"index": 8,
		"tier": 9,
		"name": "Thái Phó",
		"badge": "🌟",
		"icon_path": "res://assets/ui/ranks/thai_pho.png",
		"stars": 5,
		"color": Color(0.91, 0.47, 0.98),
		"description": "Bậc thầy thao lược của quốc gia, nhìn thấu mọi mưu kế, điều binh khiển tướng như thần."
	},
	{
		"index": 9,
		"tier": 10,
		"name": "Quốc Công",
		"badge": "🐅",
		"icon_path": "res://assets/ui/ranks/quoc_cong.png",
		"stars": 5,
		"color": Color(0.75, 0.52, 0.99),
		"description": "Tước vị chí tôn phụ chính đại thần, cặp đôi dũng mãnh quét sạch mọi đối thủ trên đấu trường."
	},
	{
		"index": 10,
		"tier": 11,
		"name": "Thân Vương",
		"badge": "🐉",
		"icon_path": "res://assets/ui/ranks/than_vuong.png",
		"stars": 5,
		"color": Color(0.38, 0.65, 0.98),
		"description": "Hoàng tộc quý tộc tối cao, thống lĩnh muôn quân, bước chân vào hàng ngũ cao thủ vô địch cõi Đại Việt."
	},
	{
		"index": 11,
		"tier": 12,
		"name": "Hoàng Đế",
		"badge": "🔥",
		"icon_path": "res://assets/ui/ranks/hoang_de.png",
		"stars": -1, # Vô hạn sao
		"color": Color(1.00, 0.84, 0.00),
		"description": "Bậc Quân Vương Tối Thượng đứng trên đỉnh vinh quang bất diệt của Đại Việt Chiến, tích lũy sao tranh Top 1."
	}
]

func get_rank_info(rank_idx: int) -> Dictionary:
	rank_idx = clampi(rank_idx, 0, RANK_DATA.size() - 1)
	return RANK_DATA[rank_idx]

func get_rank_name(rank_idx: int) -> String:
	return str(get_rank_info(rank_idx).get("name", "Dân Binh"))

func get_rank_icon_path(rank_idx: int) -> String:
	return str(get_rank_info(rank_idx).get("icon_path", ""))

func get_rank_display(rank_idx: int, stars: int) -> String:
	var info := get_rank_info(rank_idx)
	if rank_idx >= 11:
		return "%s (%d★)" % [info.name, stars]
	return "%s (%d/5★)" % [info.name, stars]

# Xử lý kết quả trận đấu 2v2:
# Trả về Dictionary chứa:
# {
#   "rank_index": int,
#   "stars": int,
#   "accumulation_points": int,
#   "tier_changed": bool,
#   "promoted": bool,
#   "demoted": bool,
#   "star_bonus_from_points": bool
# }
func process_match_result(
	is_win: bool,
	current_rank_idx: int,
	current_stars: int,
	current_acc_points: int
) -> Dictionary:
	var old_rank_idx: int = clampi(current_rank_idx, 0, 11)
	var old_stars: int = maxi(0, current_stars)
	var old_acc: int = clampi(current_acc_points, 0, MAX_ACCUMULATION_POINTS)

	var rank_idx: int = old_rank_idx
	var stars: int = old_stars
	var acc_points: int = old_acc
	var promoted := false
	var demoted := false
	var star_bonus := false

	if is_win:
		stars += WIN_STARS
		acc_points += WIN_ACCUMULATION_POINTS
	else:
		stars += LOSE_STARS
		acc_points += LOSE_ACCUMULATION_POINTS

	# Đủ 100 điểm tích lũy: tiêu thụ 100 điểm và cộng thêm 1 sao
	if acc_points >= MAX_ACCUMULATION_POINTS:
		acc_points -= MAX_ACCUMULATION_POINTS
		stars += 1
		star_bonus = true

	# Kiểm tra Thăng hạng (riêng Hoàng Đế tích sao vô hạn)
	if rank_idx < 11:
		while stars > STARS_PER_TIER and rank_idx < 11:
			stars -= (STARS_PER_TIER + 1) # 5 sao + 1 sao = 0 sao ở rank kế
			rank_idx += 1
			promoted = true
	
	# Kiểm tra Rớt hạng nếu sao âm
	if stars < 0:
		if rank_idx > 0:
			rank_idx -= 1
			stars = STARS_PER_TIER # Rớt về 5 sao của rank trước
			demoted = true
		else:
			stars = 0 # Sàn Dân Binh 0 sao không trừ âm

	return {
		"is_win": is_win,
		"old_rank_idx": old_rank_idx,
		"old_stars": old_stars,
		"old_acc_points": old_acc,
		"rank_index": rank_idx,
		"stars": stars,
		"accumulation_points": acc_points,
		"stars_delta": (stars - old_stars) if not (promoted or demoted) else (1 if is_win else -1),
		"acc_points_delta": (WIN_ACCUMULATION_POINTS if is_win else LOSE_ACCUMULATION_POINTS),
		"tier_changed": promoted or demoted,
		"promoted": promoted,
		"demoted": demoted,
		"star_bonus_from_points": star_bonus
	}
