class_name CardDatabase
extends RefCounted

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")

static var _cards_cache: Dictionary = {}

static func get_card(id: String) -> Resource:
	if _cards_cache.has(id):
		return _cards_cache[id]
	var c = create_card_from_id(id)
	_cards_cache[id] = c
	return c

static func create_card_from_dict(data: Dictionary) -> Resource:
	var c = CardResourceScript.new()
	c.id = data.get("id", "")
	c.card_name = data.get("name", data.get("cardName", "Lá Bài"))
	c.suit = data.get("suit", "Spade")
	c.rank = int(data.get("rank", 1))
	c.category = int(data.get("category", data.get("cat", 0))) as CardResourceScript.CardCategory
	c.sub_type = int(data.get("subType", 0)) as CardResourceScript.CardSubType
	c.description = data.get("desc", data.get("description", ""))
	c.attack_range = int(data.get("range", data.get("attackRange", 1)))
	return c

static func _make_card_dict(id: String, name: String, suit: String, rank: int, cat: int, sub: int, desc: String, range_val: int = 1, dist_mod: int = 0) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"cardName": name,
		"suit": suit,
		"rank": rank,
		"category": cat,
		"cat": cat,
		"subType": sub,
		"desc": desc,
		"description": desc,
		"range": range_val,
		"attackRange": range_val,
		"distMod": dist_mod
	}

# ==========================================================
# BỘ BÀI 80 LÁ CHUẨN — CHẾ ĐỘ SONG HÙNG 2v2
# ==========================================================
static func create_deck_80() -> Array:
	var list: Array = []

	# 1. Trảm Thường — 22 lá (11 Đen, 11 Đỏ)
	# Đen 11 lá
	list.append(_make_card_dict("D80_TN_S2", "Trảm Thường", "Spade", 2, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_S3", "Trảm Thường", "Spade", 3, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_S4", "Trảm Thường", "Spade", 4, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_S5", "Trảm Thường", "Spade", 5, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_S6", "Trảm Thường", "Spade", 6, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_S7", "Trảm Thường", "Spade", 7, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_C8", "Trảm Thường", "Club", 8, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_C9", "Trảm Thường", "Club", 9, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_C10", "Trảm Thường", "Club", 10, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_CJ", "Trảm Thường", "Club", 11, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_CQ", "Trảm Thường", "Club", 12, 0, 0, "Tấn công gây 1 sát thương thường"))

	# Đỏ 11 lá
	list.append(_make_card_dict("D80_TN_D2", "Trảm Thường", "Diamond", 2, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_D3", "Trảm Thường", "Diamond", 3, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_D4", "Trảm Thường", "Diamond", 4, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_D5", "Trảm Thường", "Diamond", 5, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_D6", "Trảm Thường", "Diamond", 6, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_H7", "Trảm Thường", "Heart", 7, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_H8", "Trảm Thường", "Heart", 8, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_H9", "Trảm Thường", "Heart", 9, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_D10", "Trảm Thường", "Diamond", 10, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_HJ", "Trảm Thường", "Heart", 11, 0, 0, "Tấn công gây 1 sát thương thường"))
	list.append(_make_card_dict("D80_TN_HQ", "Trảm Thường", "Heart", 12, 0, 0, "Tấn công gây 1 sát thương thường"))

	# 2. Trảm - Lôi — 6 lá (Toàn bộ Đen)
	list.append(_make_card_dict("D80_TL_S8", "Trảm - Lôi", "Spade", 8, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))
	list.append(_make_card_dict("D80_TL_S9", "Trảm - Lôi", "Spade", 9, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))
	list.append(_make_card_dict("D80_TL_C10", "Trảm - Lôi", "Club", 10, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))
	list.append(_make_card_dict("D80_TL_CJ", "Trảm - Lôi", "Club", 11, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))
	list.append(_make_card_dict("D80_TL_SK", "Trảm - Lôi", "Spade", 13, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))
	list.append(_make_card_dict("D80_TL_CA", "Trảm - Lôi", "Club", 1, 0, 2, "Tấn công gây 1 sát thương thuộc tính Lôi"))

	# 3. Trảm - Hỏa — 6 lá (Toàn bộ Đỏ)
	list.append(_make_card_dict("D80_TH_D8", "Trảm - Hỏa", "Diamond", 8, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))
	list.append(_make_card_dict("D80_TH_D9", "Trảm - Hỏa", "Diamond", 9, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))
	list.append(_make_card_dict("D80_TH_H10", "Trảm - Hỏa", "Heart", 10, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))
	list.append(_make_card_dict("D80_TH_DJ", "Trảm - Hỏa", "Diamond", 11, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))
	list.append(_make_card_dict("D80_TH_HQ", "Trảm - Hỏa", "Heart", 12, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))
	list.append(_make_card_dict("D80_TH_HA", "Trảm - Hỏa", "Heart", 1, 0, 1, "Tấn công gây 1 sát thương thuộc tính Hỏa, lan qua Xích Liên Hoàn"))

	# 4. Đỡ — 14 lá (Toàn bộ Đỏ)
	list.append(_make_card_dict("D80_DO_D2", "Đỡ", "Diamond", 2, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_H3", "Đỡ", "Heart", 3, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_D4", "Đỡ", "Diamond", 4, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_H5", "Đỡ", "Heart", 5, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_D6", "Đỡ", "Diamond", 6, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_H7", "Đỡ", "Heart", 7, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_D8", "Đỡ", "Diamond", 8, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_H9", "Đỡ", "Heart", 9, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_D10", "Đỡ", "Diamond", 10, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_HJ", "Đỡ", "Heart", 11, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_DQ", "Đỡ", "Diamond", 12, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_HQ", "Đỡ", "Heart", 12, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_DK", "Đỡ", "Diamond", 13, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
	list.append(_make_card_dict("D80_DO_HK", "Đỡ", "Heart", 13, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))

	# 5. Bánh Chưng — 6 lá (Toàn bộ Cơ ♥)
	list.append(_make_card_dict("D80_BC_H2", "Bánh Chưng", "Heart", 2, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))
	list.append(_make_card_dict("D80_BC_H4", "Bánh Chưng", "Heart", 4, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))
	list.append(_make_card_dict("D80_BC_H6", "Bánh Chưng", "Heart", 6, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))
	list.append(_make_card_dict("D80_BC_H8", "Bánh Chưng", "Heart", 8, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))
	list.append(_make_card_dict("D80_BC_H10", "Bánh Chưng", "Heart", 10, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))
	list.append(_make_card_dict("D80_BC_HK", "Bánh Chưng", "Heart", 13, 0, 4, "Hồi phục 1 Máu hoặc cứu đồng minh Cận Tử"))

	# 6. Hủ Rượu — 4 lá
	list.append(_make_card_dict("D80_HR_C7", "Hủ Rượu", "Club", 7, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D80_HR_D7", "Hủ Rượu", "Diamond", 7, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D80_HR_SQ", "Hủ Rượu", "Spade", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D80_HR_HJ", "Hủ Rượu", "Heart", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))

	# 7. Xích Tâm Tỏa — 2 lá (Toàn bộ Đen)
	list.append(_make_card_dict("D80_XT_SK", "Xích Tâm Tỏa", "Spade", 13, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))
	list.append(_make_card_dict("D80_XT_CA", "Xích Tâm Tỏa", "Club", 1, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))

	# 8. Vũ Khí — 7 lá
	list.append(_make_card_dict("D80_VK_DA_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Trảm bỏ qua Trang bị Giáp của mục tiêu", 2))
	list.append(_make_card_dict("D80_VK_HK_SongCung", "Song Cung Mường Nhạ", "Heart", 13, 1, 6, "Tầm 2. Khi Trảm bị Đỡ, bỏ 2 lá trên tay ép chịu 1 sát thương", 2))
	list.append(_make_card_dict("D80_VK_SK_SongCung", "Song Cung Mường Nhạ", "Spade", 13, 1, 6, "Tầm 2. Khi Trảm bị Đỡ, bỏ 2 lá trên tay ép chịu 1 sát thương", 2))
	list.append(_make_card_dict("D80_VK_CQ_NoThan", "Nỏ Thần Kim Quy", "Club", 12, 1, 6, "Tầm 3. Không giới hạn số lá Trảm trong lượt", 3))
	list.append(_make_card_dict("D80_VK_CJ_TruongDao", "Trường Đao Nam Sơn", "Club", 11, 1, 6, "Tầm 3. Khi Trảm bị Đỡ, bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3))
	list.append(_make_card_dict("D80_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", "Diamond", 12, 1, 6, "Tầm 4. Khi Trảm trúng, hủy 1 lá trên tay hoặc trang bị", 4))
	list.append(_make_card_dict("D80_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", "Spade", 1, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm", 5))

	# 9. Áo Giáp — 3 lá
	list.append(_make_card_dict("D80_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", "Club", 13, 1, 7, "Vô hiệu hóa toàn bộ đòn Trảm Thường"))
	list.append(_make_card_dict("D80_AG_DK_KhienMay", "Khiên Mây Bện", "Diamond", 13, 1, 7, "Bị Trảm/Mưa Tên: lật phán xét Đỏ tự động Đỡ, Đen thất bại"))
	list.append(_make_card_dict("D80_AG_HA_AoBao", "Áo Bào Hoàng Tộc", "Heart", 1, 1, 7, "Tất cả sát thương nhận vào giảm 1, tối đa 3 lần"))

	# 10. Chiến Mã — 4 lá
	list.append(_make_card_dict("D80_CM_HK_VoiChien", "Voi Chiến Đại Việt", "Heart", 13, 1, 9, "Ngựa Thủ: Tăng +1 Khoảng cách từ người chơi khác tới bạn", 1, 1))
	list.append(_make_card_dict("D80_CM_CK_VoiChien", "Voi Chiến Đại Việt", "Club", 13, 1, 9, "Ngựa Thủ: Tăng +1 Khoảng cách từ người chơi khác tới bạn", 1, 1))
	list.append(_make_card_dict("D80_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Spade", 11, 1, 8, "Ngựa Công: Giảm -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))
	list.append(_make_card_dict("D80_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Diamond", 11, 1, 8, "Ngựa Công: Giảm -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))

	# 11. Cẩm Nang Tức Thời — 8 lá
	list.append(_make_card_dict("D80_CN_HA_DieuKe", "Diệu Kế Phá Mưu", "Heart", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn"))
	list.append(_make_card_dict("D80_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", "Club", 12, 2, 11, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"))
	list.append(_make_card_dict("D80_CN_SK_DotKich", "Đột Kích Trộm Lương", "Spade", 13, 2, 12, "Cướp 1 lá tay, trang bị hoặc Trì Hoãn của mục tiêu cự ly 1"))
	list.append(_make_card_dict("D80_CN_H3_DungBinh", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài từ xấp bài"))
	list.append(_make_card_dict("D80_CN_ThachDau", "Thách Đấu", "Diamond", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"))
	list.append(_make_card_dict("D80_CN_D4_MoKho", "Mở Kho Cứu Tế", "Diamond", 4, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"))
	list.append(_make_card_dict("D80_CN_BaiCoc", "Bãi Cọc Ngầm", "Spade", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"))
	list.append(_make_card_dict("D80_CN_MuaTen", "Mưa Tên Liên Châu", "Heart", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"))

	# 12. Cẩm Nang Trì Hoãn — 3 lá
	list.append(_make_card_dict("D80_TH_CA_SamSet", "Thần Sấm Báo Ứng", "Club", 1, 3, 19, "Phán xét: Bích ♠ 2..9 chịu 3 sát thương Lôi, trượt chuyển tiếp"))
	list.append(_make_card_dict("D80_TH_DQ_CatLuong", "Cắt Đường Lương", "Diamond", 12, 3, 20, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài"))
	list.append(_make_card_dict("D80_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", "Heart", 13, 3, 21, "Phán xét: Không phải Cơ ♥ -> bỏ qua Ra bài"))

	return list

# ==========================================================
# BỘ BÀI 150 LÁ CHUẨN — CHẾ ĐỘ ĐẠI CHIẾN 8 NGƯỜI / QUỐC CHIẾN
# ==========================================================
static func create_deck_150() -> Array:
	var list: Array = []

	# 1. Trảm Thường — 42 lá (21 Đen, 21 Đỏ)
	var spade_ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	for r in spade_ranks:
		list.append(_make_card_dict("D150_TN_S%d" % r, "Trảm Thường", "Spade", r, 0, 0, "Tấn công gây 1 sát thương thường"))
	var club_ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	for r in club_ranks:
		list.append(_make_card_dict("D150_TN_C%d" % r, "Trảm Thường", "Club", r, 0, 0, "Tấn công gây 1 sát thương thường"))
	var dia_ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	for r in dia_ranks:
		list.append(_make_card_dict("D150_TN_D%d" % r, "Trảm Thường", "Diamond", r, 0, 0, "Tấn công gây 1 sát thương thường"))
	var heart_ranks = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
	for r in heart_ranks:
		list.append(_make_card_dict("D150_TN_H%d" % r, "Trảm Thường", "Heart", r, 0, 0, "Tấn công gây 1 sát thương thường"))

	# 2. Trảm - Lôi — 12 lá (Toàn bộ Đen, 6 ♠, 6 ♣, mã 8..K)
	var loi_ranks = [8, 9, 10, 11, 12, 13]
	for r in loi_ranks:
		list.append(_make_card_dict("D150_TL_S%d" % r, "Trảm - Lôi", "Spade", r, 0, 2, "Tấn công gây 1 sát thương Lôi"))
		list.append(_make_card_dict("D150_TL_C%d" % r, "Trảm - Lôi", "Club", r, 0, 2, "Tấn công gây 1 sát thương Lôi"))

	# 3. Trảm - Hỏa — 12 lá (Toàn bộ Đỏ, 6 ♦, 6 ♥, mã 8..K)
	var hoa_ranks = [8, 9, 10, 11, 12, 13]
	for r in hoa_ranks:
		list.append(_make_card_dict("D150_TH_D%d" % r, "Trảm - Hỏa", "Diamond", r, 0, 1, "Tấn công gây 1 sát thương Hỏa"))
		list.append(_make_card_dict("D150_TH_H%d" % r, "Trảm - Hỏa", "Heart", r, 0, 1, "Tấn công gây 1 sát thương Hỏa"))

	# 4. Đỡ — 26 lá (Toàn bộ Đỏ, 13 ♦, 13 ♥: từ 2 đến K + A)
	for r in range(1, 14):
		list.append(_make_card_dict("D150_DO_D%d" % r, "Đỡ", "Diamond", r, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))
		list.append(_make_card_dict("D150_DO_H%d" % r, "Đỡ", "Heart", r, 0, 3, "Hóa giải hoàn toàn 1 đòn Trảm"))

	# 5. Bánh Chưng — 12 lá (Toàn bộ Cơ ♥ từ 2 đến K)
	for r in range(2, 14):
		list.append(_make_card_dict("D150_BC_H%d" % r, "Bánh Chưng", "Heart", r, 0, 4, "Hồi 1 Máu hoặc cứu đồng minh Cận Tử"))

	# 6. Hủ Rượu — 7 lá
	list.append(_make_card_dict("D150_HR_CJ", "Hủ Rượu", "Club", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_DJ", "Hủ Rượu", "Diamond", 11, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_SQ", "Hủ Rượu", "Spade", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_CQ", "Hủ Rượu", "Club", 12, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_DK", "Hủ Rượu", "Diamond", 13, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_SK", "Hủ Rượu", "Spade", 13, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))
	list.append(_make_card_dict("D150_HR_HA", "Hủ Rượu", "Heart", 1, 0, 5, "Uống trước Trảm (+1 ST) hoặc tự cứu khi 0 máu"))

	# 7. Xích Tâm Tỏa — 4 lá (Toàn bộ Đen)
	list.append(_make_card_dict("D150_XT_SQ", "Xích Tâm Tỏa", "Spade", 12, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))
	list.append(_make_card_dict("D150_XT_CQ", "Xích Tâm Tỏa", "Club", 12, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))
	list.append(_make_card_dict("D150_XT_SK", "Xích Tâm Tỏa", "Spade", 13, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))
	list.append(_make_card_dict("D150_XT_CA", "Xích Tâm Tỏa", "Club", 1, 2, 15, "Trói tối đa 2 mục tiêu bằng Xích Liên Hoàn hoặc gỡ Xích"))

	# 8. Vũ Khí — 12 lá (Mỗi loại 2 lá)
	list.append(_make_card_dict("D150_VK_DA_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 1, 1, 6, "Tầm 2. Trảm bỏ qua Trang bị Giáp mục tiêu", 2))
	list.append(_make_card_dict("D150_VK_D2_ThuanThien", "Kiếm Thuận Thiên", "Diamond", 2, 1, 6, "Tầm 2. Trảm bỏ qua Trang bị Giáp mục tiêu", 2))
	list.append(_make_card_dict("D150_VK_HK_SongCung", "Song Cung Mường Nhạ", "Heart", 13, 1, 6, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 sát thương", 2))
	list.append(_make_card_dict("D150_VK_SK_SongCung", "Song Cung Mường Nhạ", "Spade", 13, 1, 6, "Tầm 2. Trảm bị Đỡ: bỏ 2 lá ép chịu 1 sát thương", 2))
	list.append(_make_card_dict("D150_VK_CQ_NoThan", "Nỏ Thần Kim Quy", "Club", 12, 1, 6, "Tầm 3. Không giới hạn số Trảm trong lượt", 3))
	list.append(_make_card_dict("D150_VK_SA_NoThan", "Nỏ Thần Kim Quy", "Spade", 1, 1, 6, "Tầm 3. Không giới hạn số Trảm trong lượt", 3))
	list.append(_make_card_dict("D150_VK_CJ_TruongDao", "Trường Đao Nam Sơn", "Club", 11, 1, 6, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3))
	list.append(_make_card_dict("D150_VK_DQ_TruongDao", "Trường Đao Nam Sơn", "Diamond", 12, 1, 6, "Tầm 3. Trảm bị Đỡ: bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ", 3))
	list.append(_make_card_dict("D150_VK_DQ_ThuongNgau", "Thương Ngâu Lãng Bạc", "Diamond", 12, 1, 6, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị", 4))
	list.append(_make_card_dict("D150_VK_C5_ThuongNgau", "Thương Ngâu Lãng Bạc", "Club", 5, 1, 6, "Tầm 4. Trảm trúng: hủy 1 lá tay hoặc trang bị", 4))
	list.append(_make_card_dict("D150_VK_SA_SungThanCong", "Súng Thần Công Hồ Triều", "Spade", 1, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm", 5))
	list.append(_make_card_dict("D150_VK_DA_SungThanCong", "Súng Thần Công Hồ Triều", "Diamond", 1, 1, 6, "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm", 5))

	# 9. Áo Giáp — 6 lá (Mỗi loại 2 lá)
	list.append(_make_card_dict("D150_AG_CK_GiapDong", "Giáp Đồng Sơn Vi", "Club", 13, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"))
	list.append(_make_card_dict("D150_AG_S2_GiapDong", "Giáp Đồng Sơn Vi", "Spade", 2, 1, 7, "Vô hiệu hóa toàn bộ Trảm Thường"))
	list.append(_make_card_dict("D150_AG_DK_KhienMay", "Khiên Mây Bện", "Diamond", 13, 1, 7, "Khi bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại"))
	list.append(_make_card_dict("D150_AG_C2_KhienMay", "Khiên Mây Bện", "Club", 2, 1, 7, "Khi bị Trảm: lật phán xét Đỏ tự động Đỡ, Đen thất bại"))
	list.append(_make_card_dict("D150_AG_HA_AoBao", "Áo Bào Hoàng Tộc", "Heart", 1, 1, 7, "Giảm 1 sát thương nhận vào, tối đa 3 lần"))
	list.append(_make_card_dict("D150_AG_D3_AoBao", "Áo Bào Hoàng Tộc", "Diamond", 3, 1, 7, "Giảm 1 sát thương nhận vào, tối đa 3 lần"))

	# 10. Chiến Mã — 7 lá (3 Voi Chiến, 4 Ngựa Trắng)
	list.append(_make_card_dict("D150_CM_HK_VoiChien", "Voi Chiến Đại Việt", "Heart", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1))
	list.append(_make_card_dict("D150_CM_CK_VoiChien", "Voi Chiến Đại Việt", "Club", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1))
	list.append(_make_card_dict("D150_CM_DK_VoiChien", "Voi Chiến Đại Việt", "Diamond", 13, 1, 9, "Ngựa Thủ: +1 Khoảng cách từ người khác tới bạn", 1, 1))
	list.append(_make_card_dict("D150_CM_SJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Spade", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))
	list.append(_make_card_dict("D150_CM_DJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Diamond", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))
	list.append(_make_card_dict("D150_CM_CJ_NguaTrang", "Ngựa Trắng Thuần Nông", "Club", 11, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))
	list.append(_make_card_dict("D150_CM_H5_NguaTrang", "Ngựa Trắng Thuần Nông", "Heart", 5, 1, 8, "Ngựa Công: -1 Khoảng cách từ bạn tới tất cả người khác", 1, -1))

	# 11. Cẩm Nang Tức Thời — 14 lá
	list.append(_make_card_dict("D150_CN_HA_DieuKe", "Diệu Kế Phá Mưu", "Heart", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn"))
	list.append(_make_card_dict("D150_CN_SA_DieuKe", "Diệu Kế Phá Mưu", "Spade", 1, 2, 10, "Vô hiệu hóa 1 Cẩm Nang HOẶC hủy 1 lá trên tay/bàn"))
	list.append(_make_card_dict("D150_CN_CQ_VuonKhong", "Vườn Không Nhà Trống", "Club", 12, 2, 11, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"))
	list.append(_make_card_dict("D150_CN_S3_VuonKhong", "Vườn Không Nhà Trống", "Spade", 3, 2, 11, "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"))
	list.append(_make_card_dict("D150_CN_SK_DotKich", "Đột Kích Trộm Lương", "Spade", 13, 2, 12, "Cướp 1 lá tay, trang bị hoặc Trì Hoãn của mục tiêu cự ly 1"))
	list.append(_make_card_dict("D150_CN_H3_DungBinh", "Dụng Binh Như Thần", "Heart", 3, 2, 13, "Rút ngay 2 lá bài từ xấp bài"))
	list.append(_make_card_dict("D150_CN_S7_BaiCoc", "Bãi Cọc Ngầm", "Spade", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_C7_BaiCoc", "Bãi Cọc Ngầm", "Club", 7, 2, 17, "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_HA_MuaTen", "Mưa Tên Liên Châu", "Heart", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_DA_MuaTen", "Mưa Tên Liên Châu", "Diamond", 1, 2, 18, "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_DA_ThachDau", "Thách Đấu", "Diamond", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_SA_ThachDau", "Thách Đấu", "Spade", 1, 2, 14, "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"))
	list.append(_make_card_dict("D150_CN_H3_MoKho", "Mở Kho Cứu Tế", "Heart", 3, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"))
	list.append(_make_card_dict("D150_CN_D4_MoKho", "Mở Kho Cứu Tế", "Diamond", 4, 2, 16, "Mở kho phát bài cho tất cả người chơi còn sống"))

	# 12. Cẩm Nang Trì Hoãn — 4 lá
	list.append(_make_card_dict("D150_TH_CA_SamSet", "Thần Sấm Báo Ứng", "Club", 1, 3, 19, "Phán xét: Bích ♠ 2..9 chịu 3 sát thương Lôi, trượt chuyển tiếp"))
	list.append(_make_card_dict("D150_TH_DQ_CatLuong", "Cắt Đường Lương", "Diamond", 12, 3, 20, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài"))
	list.append(_make_card_dict("D150_TH_C4_CatLuong", "Cắt Đường Lương", "Club", 4, 3, 20, "Phán xét: Không phải Chuồn ♣ -> bỏ qua Rút bài"))
	list.append(_make_card_dict("D150_TH_HK_TramAo", "Trầm Ảo Sa Bẫy", "Heart", 13, 3, 21, "Phán xét: Không phải Cơ ♥ -> bỏ qua Ra bài"))

	return list

static func create_deck(mode: int = 80) -> Array:
	if mode >= 150:
		return create_deck_150()
	if mode <= 60:
		var d80 = create_deck_80()
		return d80.slice(0, 60)
	if mode == 80:
		return create_deck_80()
	if mode == 100:
		var d80 = create_deck_80()
		var extra = create_deck_150().slice(80, 100)
		d80.append_array(extra)
		return d80
	if mode == 125:
		var d80 = create_deck_80()
		var extra = create_deck_150().slice(80, 125)
		d80.append_array(extra)
		return d80
	return create_deck_80()

static func create_card_from_id(id: String) -> Resource:
	# Tìm trong deck 80 trước
	var d80 = create_deck_80()
	for d in d80:
		if d["id"] == id:
			return create_card_from_dict(d)

	# Tìm trong deck 150
	var d150 = create_deck_150()
	for d in d150:
		if d["id"] == id:
			return create_card_from_dict(d)

	# Fallback tạo theo từ khóa id
	var c = CardResourceScript.new()
	c.id = id
	c.card_name = "Thẻ Bài"
	c.suit = "Spade"
	c.rank = 1

	if id.contains("ThuanThien"):
		c.card_name = "Kiếm Thuận Thiên"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 2
		c.description = "Tầm 2. Trảm bỏ qua Trang bị Giáp của mục tiêu"
	elif id.contains("SongCung"):
		c.card_name = "Song Cung Mường Nhạ"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 2
		c.description = "Tầm 2. Khi Trảm bị Đỡ, bỏ 2 lá trên tay ép chịu 1 sát thương"
	elif id.contains("NoThan"):
		c.card_name = "Nỏ Thần Kim Quy"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 3
		c.description = "Tầm 3. Không giới hạn số Trảm trong lượt"
	elif id.contains("TruongDao"):
		c.card_name = "Trường Đao Nam Sơn"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 3
		c.description = "Tầm 3. Khi Trảm bị Đỡ, bỏ thêm 1 Trảm ép dùng thêm 1 Đỡ"
	elif id.contains("ThuongNgau"):
		c.card_name = "Thương Ngâu Lãng Bạc"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 4
		c.description = "Tầm 4. Khi Trảm trúng, hủy 1 lá trên tay hoặc trang bị"
	elif id.contains("SungThanCong"):
		c.card_name = "Súng Thần Công Hồ Triều"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 5
		c.description = "Tầm 5. Mục tiêu không được dùng Đỡ cùng chất với Trảm"
	elif id.contains("KhienMay"):
		c.card_name = "Khiên Mây Bện"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.AO_GIAP
		c.description = "Khi cần Đỡ, lật phán xét: chất Đỏ tự động Đỡ"
	elif id.contains("GiapDong"):
		c.card_name = "Giáp Đồng Sơn Vi"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.AO_GIAP
		c.description = "Vô hiệu hóa toàn bộ Trảm Thường"
	elif id.contains("AoBao"):
		c.card_name = "Áo Bào Hoàng Tộc"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.AO_GIAP
		c.description = "Giảm 1 sát thương nhận vào, tối đa 3 lần"
	elif id.contains("VoiChien"):
		c.card_name = "Voi Chiến Đại Việt"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.NGUA_THU
		c.description = "Ngựa Thủ: Tăng +1 Khoảng cách từ người khác tới bạn"
	elif id.contains("NguaTrang"):
		c.card_name = "Ngựa Trắng Thuần Nông"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.NGUA_CONG
		c.description = "Ngựa Công: Giảm -1 Khoảng cách từ bạn tới người khác"
	elif id.contains("DieuKe"):
		c.card_name = "Diệu Kế Phá Mưu"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.DIEU_KE
		c.description = "Hóa giải 1 lá Cẩm Nang bất kỳ hoặc hủy 1 lá trên bàn"
	elif id.contains("VuonKhong"):
		c.card_name = "Vườn Không Nhà Trống"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.VUON_KHONG
		c.description = "Ép mục tiêu bỏ 1 lá trên tay HOẶC hủy 1 trang bị"
	elif id.contains("DotKich"):
		c.card_name = "Đột Kích Trộm Lương"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.DOT_KICH
		c.description = "Cướp 1 lá bài của mục tiêu cự ly 1"
	elif id.contains("DungBinh"):
		c.card_name = "Dụng Binh Như Thần"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.DUNG_BINH
		c.description = "Rút ngay 2 lá bài từ xấp bài"
	elif id.contains("Banh"):
		c.card_name = "Bánh Chưng"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.BANH_CHUNG
		c.description = "Hồi 1 Máu cho bản thân hoặc cứu tướng Cận Tử"
	elif id.contains("Ruou"):
		c.card_name = "Hủ Rượu"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.HU_RUOU
		c.description = "Tăng +1 sát thương đòn Trảm kế tiếp hoặc tự cứu khi 0 máu"
	elif id.contains("Do"):
		c.card_name = "Đỡ"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.DO
		c.description = "Hóa giải 1 đòn Trảm"
	elif id.contains("Xich"):
		c.card_name = "Xích Tâm Tỏa"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.XICH_TAM_TOA
		c.description = "Khóa xích tối đa 2 tướng bằng Xích Liên Hoàn"
	elif id.contains("SamSet"):
		c.card_name = "Thần Sấm Báo Ứng"
		c.category = CardResourceScript.CardCategory.TRI_HOAN
		c.sub_type = CardResourceScript.CardSubType.THAN_SAM
		c.description = "Phán xét: Bích 2-9 chịu 3 sát thương Lôi"
	elif id.contains("BaiCoc"):
		c.card_name = "Bãi Cọc Ngầm"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.BAI_COC_NGAM
		c.description = "Ép tất cả người chơi khác phải đánh 1 Trảm hoặc chịu 1 sát thương"
	elif id.contains("MuaTen"):
		c.card_name = "Mưa Tên Liên Châu"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.MUA_TEN
		c.description = "Ép tất cả người chơi khác phải đánh 1 Đỡ hoặc chịu 1 sát thương"
	elif id.contains("ThachDau"):
		c.card_name = "Thách Đấu"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.THACH_DAU
		c.description = "Thách đấu 1 mục tiêu, hai bên luân phiên đánh Trảm, ai không đánh được chịu 1 sát thương"
	elif id.contains("MoKho"):
		c.card_name = "Mở Kho Cứu Tế"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.MO_KHO_CUU_TE
		c.description = "Mở kho phát bài cho tất cả người chơi còn sống"
	elif id.contains("CatLuong"):
		c.card_name = "Cắt Đường Lương"
		c.category = CardResourceScript.CardCategory.TRI_HOAN
		c.sub_type = CardResourceScript.CardSubType.CAT_LUONG
		c.description = "Phán xét: Không phải Chuồn -> mất lượt rút bài"
	elif id.contains("TramAo"):
		c.card_name = "Trầm Ảo Sa Bẫy"
		c.category = CardResourceScript.CardCategory.TRI_HOAN
		c.sub_type = CardResourceScript.CardSubType.TRAM_AO
		c.description = "Phán xét: Không phải Cơ -> mất lượt ra bài"
	elif id.contains("TL_"):
		c.card_name = "Trảm - Lôi"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.TRAM_LOI
		c.description = "Tấn công gây 1 sát thương thuộc tính Lôi"
	elif id.contains("TH_"):
		c.card_name = "Trảm - Hỏa"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.TRAM_HOA
		c.description = "Tấn công gây 1 sát thương thuộc tính Hỏa"
	else:
		c.card_name = "Trảm Thường"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.TRAM
		c.description = "Tấn công gây 1 sát thương"

	return c
