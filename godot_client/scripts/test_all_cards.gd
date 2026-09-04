extends SceneTree

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")
const CardDatabaseScript = preload("res://scripts/resources/card_database.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

func _init() -> void:
	print("==========================================================")
	print("  TỔNG RÀ SOÁT 29 LÁ BÀI — ĐẠI VIỆT CHIẾN (GODOT ENGINE)")
	print("==========================================================")

	var expected_cards = [
		# Cơ Bản (6)
		{"name": "Trảm Thường", "cat": 0, "sub": 0},
		{"name": "Trảm - Hỏa", "cat": 0, "sub": 1},
		{"name": "Trảm - Lôi", "cat": 0, "sub": 2},
		{"name": "Đỡ", "cat": 0, "sub": 3},
		{"name": "Bánh Chưng", "cat": 0, "sub": 4},
		{"name": "Hủ Rượu", "cat": 0, "sub": 5},
		# Vũ Khí (6)
		{"name": "Kiếm Thuận Thiên", "cat": 1, "sub": 6, "range": 2},
		{"name": "Song Cung Mường Nhạ", "cat": 1, "sub": 6, "range": 2},
		{"name": "Nỏ Thần Kim Quy", "cat": 1, "sub": 6, "range": 3},
		{"name": "Trường Đao Nam Sơn", "cat": 1, "sub": 6, "range": 3},
		{"name": "Thương Ngâu Lãng Bạc", "cat": 1, "sub": 6, "range": 4},
		{"name": "Súng Thần Công Hồ Triều", "cat": 1, "sub": 6, "range": 5},
		# Áo Giáp (3)
		{"name": "Giáp Đồng Sơn Vi", "cat": 1, "sub": 7},
		{"name": "Khiên Mây Bện", "cat": 1, "sub": 7},
		{"name": "Áo Bào Hoàng Tộc", "cat": 1, "sub": 7},
		# Chiến Mã (2)
		{"name": "Voi Chiến Đại Việt", "cat": 1, "sub": 9, "distMod": 1},
		{"name": "Ngựa Trắng Thuần Nông", "cat": 1, "sub": 8, "distMod": -1},
		# Cẩm Nang Tức Thời (9)
		{"name": "Diệu Kế Phá Mưu", "cat": 2, "sub": 10},
		{"name": "Vườn Không Nhà Trống", "cat": 2, "sub": 11},
		{"name": "Đột Kích Trộm Lương", "cat": 2, "sub": 12},
		{"name": "Dụng Binh Như Thần", "cat": 2, "sub": 13},
		{"name": "Thách Đấu", "cat": 2, "sub": 14},
		{"name": "Xích Tâm Tỏa", "cat": 2, "sub": 15},
		{"name": "Mở Kho Cứu Tế", "cat": 2, "sub": 16},
		{"name": "Bãi Cọc Ngầm", "cat": 2, "sub": 17},
		{"name": "Mưa Tên Liên Châu", "cat": 2, "sub": 18},
		# Cẩm Nang Trì Hoãn (3)
		{"name": "Thần Sấm Báo Ứng", "cat": 3, "sub": 19},
		{"name": "Cắt Đường Lương", "cat": 3, "sub": 20},
		{"name": "Trầm Ảo Sa Bẫy", "cat": 3, "sub": 21}
	]

	print("Tổng số lá cần kiểm tra: %d" % expected_cards.size())
	assert(expected_cards.size() == 29, "Phải có đúng 29 loại lá bài!")

	var pass_count = 0
	var errors = []

	for item in expected_cards:
		var c_name = item["name"]
		var c = CardResourceScript.new()
		c.card_name = c_name
		c.category = item["cat"]
		c.sub_type = item["sub"]

		# 1. Kiểm tra Artwork Path
		var art_path = c.get_artwork_path()
		if art_path == "":
			errors.append("❌ [%s]: Chưa có artwork path!" % c_name)
			continue
		elif not ResourceLoader.exists(art_path):
			errors.append("❌ [%s]: File artwork không tồn tại trên ổ đĩa (%s)!" % [c_name, art_path])
			continue

		# 2. Kiểm tra Voice mapping
		var am = AudioManagerScript.new()
		var voice_key = am._normalize_voice_key(c_name)
		if voice_key == "":
			errors.append("❌ [%s]: Chưa có voice key mapping trong AudioManager!" % c_name)
			continue

		pass_count += 1
		print("  [OK] Lá #%02d: %-26s | Cat: %d | Sub: %02d | Art: %s | Voice: %s" % [pass_count, c_name, item["cat"], item["sub"], art_path.get_file(), voice_key])

	# 3. Kiểm tra Deck 80 và Deck 150
	var d80 = CardDatabaseScript.create_deck_80()
	print("\nKiểm tra Deck 80: %d lá" % d80.size())
	var d80_names = {}
	for card_data in d80:
		var n = card_data.get("name", "")
		d80_names[n] = d80_names.get(n, 0) + 1

	for item in expected_cards:
		var n = item["name"]
		if not d80_names.has(n):
			errors.append("❌ Deck 80 thiếu lá: %s" % n)
		else:
			print("    - %-26s: %d lá trong Deck 80" % [n, d80_names[n]])

	var d150 = CardDatabaseScript.create_deck_150()
	print("\nKiểm tra Deck 150: %d lá" % d150.size())
	var d150_names = {}
	for card_data in d150:
		var n = card_data.get("name", "")
		d150_names[n] = d150_names.get(n, 0) + 1

	for item in expected_cards:
		var n = item["name"]
		if not d150_names.has(n):
			errors.append("❌ Deck 150 thiếu lá: %s" % n)
		else:
			print("    - %-26s: %d lá trong Deck 150" % [n, d150_names[n]])

	print("\n==========================================================")
	if errors.is_empty():
		print("  ✅ TẤT CẢ 29 LÁ BÀI ĐÃ HOÀN THIỆN 100% VÀ HỢP LỆ!")
		print("==========================================================")
		quit(0)
	else:
		print("  ❌ PHÁT HIỆN %d LỖI:" % errors.size())
		for err in errors:
			print("    " + err)
		print("==========================================================")
		quit(1)
