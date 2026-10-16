extends Node

signal login_succeeded(user_data: Dictionary)
signal login_failed(error_message: String)
signal profile_updated()
signal profile_loaded()

const ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
const PROJECT_ID = "6a885457002da3f3d47e"
const SAVE_PATH = "user://auth_session.json"

var current_user_name: String = "Đại Tướng Quân"
var current_user_email: String = ""
var current_user_id: String = ""
var current_user_labels: PackedStringArray = PackedStringArray()
var session_secret: String = ""
var session_cookie: String = ""
var fallback_cookies: String = ""
var is_logged_in: bool = false
var is_deleting_session: bool = false

# Player Profile & Progression (Synced with Appwrite /account/prefs)
var current_level: int = 1
var current_exp: int = 0
var current_silver: int = 5000
var current_gold: int = 0
var current_generals: Array = ["ly_thuong_kiet"]
var current_hero_tickets: int = 0
var current_skin_tickets: int = 0
var checkin_7day_claimed: Array = []
var last_checkin_date: String = ""
var current_2v2_points: int = 1200
var current_2v2_rank_index: int = 0
var current_2v2_stars: int = 0
var current_2v2_accumulation_points: int = 0
var current_2v2_entry_stake_room_id: String = ""
var current_2v2_entry_stake_amount: int = 0
var current_wins: int = 0
var current_losses: int = 0
var tutorial_reward_claimed: bool = false
var onboarding_completed: bool = false
var has_played_before: bool = false
var pending_exp_gain: Dictionary = {}
var daily_quests_data: Dictionary = {}
var disable_session_save: bool = false
var redeemed_codes: Array = []
var claimed_mails: Array = []
var claimed_match_rewards: Dictionary = {}
var deleted_mails: Array = []
var admin_gift_code: String = "DAIVIETCHIEN"
var admin_gift_reward: String = "5 vé quay tướng"
var current_title: String = ""
var current_profile_bg: int = 0

# 12 Tiers of Military Ranks
const MILITARY_TIERS = [
	{"tier": 1,  "name": "Tân Binh",       "badge": "🔰", "min": 0,    "max": 99,   "desc": "Chiến sĩ mới gia nhập hàng ngũ nghĩa quân Đại Việt."},
	{"tier": 2,  "name": "Binh Nhì",       "badge": "🗡️", "min": 100,  "max": 299,  "desc": "Đã thuần thục kiếm pháp và thao lược trận mạc cơ bản."},
	{"tier": 3,  "name": "Binh Nhất",      "badge": "⚔️", "min": 300,  "max": 599,  "desc": "Tay giáo thiện chiến nơi tiền tuyến, dũng cảm xung phong."},
	{"tier": 4,  "name": "Thập Trưởng",    "badge": "🛡️", "min": 600,  "max": 999,  "desc": "Chỉ huy tiểu đội 10 binh sĩ, kiên cố phòng thủ biên cương."},
	{"tier": 5,  "name": "Bách Trưởng",    "badge": "🎖️", "min": 1000, "max": 1499, "desc": "Thống lĩnh đại đội 100 quân sĩ, dạn dày khói lửa sa trường."},
	{"tier": 6,  "name": "Thiên Trưởng",   "badge": "🚩", "min": 1500, "max": 2199, "desc": "Chỉ huy chiến đoàn ngàn binh mã, cờ phướn rợp trời."},
	{"tier": 7,  "name": "Phó Tướng",      "badge": "⚡", "min": 2200, "max": 2999, "desc": "Cánh tay đắc lực của chủ tướng, điều binh khiển tướng như thần."},
	{"tier": 8,  "name": "Chánh Tướng",    "badge": "⭐", "min": 3000, "max": 3999, "desc": "Thống lĩnh đại quân trấn giữ yếu đạo, uy danh vang dội."},
	{"tier": 9,  "name": "Thiếu Tướng",    "badge": "🌟", "min": 4000, "max": 5199, "desc": "Tướng lĩnh cao cấp nắm giữ vận mệnh nhiều chiến dịch lớn."},
	{"tier": 10, "name": "Trung Tướng",    "badge": "👑", "min": 5200, "max": 6599, "desc": "Trụ cột triều đình, mưu lược cái thế, địch nghe tên kinh hồn bạt vía."},
	{"tier": 11, "name": "Đại Tướng Quân", "badge": "🦅", "min": 6600, "max": 8199, "desc": "Tướng soái bách chiến bách thắng, uy danh chấn động bốn cõi non sông."},
	{"tier": 12, "name": "Đại Nguyên Soái","badge": "🔥", "min": 8200, "max": 999999, "desc": "Bậc Thống Soái tối cao, thống lĩnh toàn bộ quân lực bảo vệ xã tắc vĩnh cửu."}
]

func _ready() -> void:
	load_saved_session()
	if is_logged_in:
		fetch_account_info()

func get_auth_headers(include_session: bool = true) -> PackedStringArray:
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"X-Appwrite-Project: " + PROJECT_ID
	])
	if include_session:
		if session_secret != "":
			headers.append("X-Appwrite-Session: " + session_secret)
		if fallback_cookies != "":
			headers.append("X-Fallback-Cookies: " + fallback_cookies)
		if session_cookie != "" and not OS.has_feature("web"):
			headers.append("Cookie: " + session_cookie)
	return headers

func is_admin() -> bool:
	var args = OS.get_cmdline_user_args() + OS.get_cmdline_args()
	if "--admin-test" in args:
		return true
	for account_label in current_user_labels:
		if account_label.strip_edges().to_lower() == "admin":
			return true
	if current_user_email == "vdthanh224@gmail.com":
		return true
	var lower_name = current_user_name.strip_edges().to_lower()
	if lower_name == "thành hydro" or lower_name == "thanh hydro" or lower_name == "thanhhydro":
		return true
	return false

# --- Level Progression Formulas ---
# Kinh nghiệm để lên level là: lên level X cần X*10 kinh nghiệm.
# Lên cấp 2: cần 2*10 = 20 Exp. Lên cấp 3: cần 3*10 = 30 Exp.
func get_exp_required_for_level(lvl: int) -> int:
	return lvl * 10

func get_exp_to_next_level() -> int:
	return (current_level + 1) * 10

func normalize_exp_progress() -> bool:
	var changed := false
	if current_level < 1:
		current_level = 1
		changed = true
	while current_exp >= get_exp_to_next_level():
		current_exp -= get_exp_to_next_level()
		current_level += 1
		changed = true
	return changed

func add_exp(amount: int) -> Dictionary:
	normalize_exp_progress()
	var old_lvl = current_level
	var old_exp = current_exp
	current_exp += amount
	var leveled_up: bool = false
	var levels_gained: int = 0
	var next_req = get_exp_to_next_level()

	while current_exp >= next_req:
		current_exp -= next_req
		current_level += 1
		levels_gained += 1
		leveled_up = true
		next_req = get_exp_to_next_level()

	if leveled_up:
		pending_exp_gain = {
			"old_level": old_lvl,
			"old_exp": old_exp,
			"new_level": current_level,
			"new_exp": current_exp,
			"exp_added": amount,
			"show_modal": true
		}

	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

	return {
		"leveled_up": leveled_up,
		"levels_gained": levels_gained,
		"new_level": current_level,
		"current_exp": current_exp,
		"next_req": next_req
	}

# --- Military Rank Formulas ---
# Exp Quân hàm: Cứ 1 tướng sở hữu +5.
func get_military_points() -> int:
	if current_generals.is_empty():
		current_generals = ["ly_thuong_kiet"]
	return current_generals.size() * 5

func add_general(hero_id: String) -> void:
	if not current_generals.has(hero_id):
		current_generals.append(hero_id)
		save_session()
		save_profile_to_appwrite()
		profile_updated.emit()

func add_silver(amount: int) -> void:
	current_silver += amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func consume_silver(amount: int) -> bool:
	if current_silver < amount:
		return false
	current_silver -= amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return true

func add_gold(amount: int) -> void:
	current_gold += amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func consume_gold(amount: int) -> bool:
	if current_gold < amount:
		return false
	current_gold -= amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return true

func add_hero_tickets(amount: int) -> void:
	current_hero_tickets += amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func consume_hero_tickets(amount: int) -> bool:
	if current_hero_tickets < amount:
		return false
	current_hero_tickets -= amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return true

func add_skin_tickets(amount: int) -> void:
	current_skin_tickets += amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func consume_skin_tickets(amount: int) -> bool:
	if current_skin_tickets < amount:
		return false
	current_skin_tickets -= amount
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return true

# --- Danh hiệu & Nền hồ sơ tướng ---
func get_available_titles() -> Array:
	var list: Array = []
	var admin_unlocked: bool = is_admin()
	list.append({
		"id": "admin",
		"name": "ADMIN",
		"desc": "Danh hiệu tối cao độc quyền dành riêng cho Quản Trị Viên Đại Việt Chiến.",
		"badge_type": "rainbow_neon",
		"unlocked": admin_unlocked,
		"req_text": "Chỉ dành cho nick có nhãn (label) 'admin' trong hệ thống Appwrite"
	})
	return list

func equip_title(title_id: String) -> void:
	var clean = title_id.strip_edges().to_lower()
	if clean == "admin" and not is_admin():
		print("[AuthManager] Không thể trang bị danh hiệu ADMIN do tài khoản không có quyền admin!")
		return
	current_title = clean
	save_session()
	save_profile_to_appwrite()
	var nc = get_node_or_null("/root/NetworkClient")
	if nc and nc.has_method("register_social_profile"):
		nc.register_social_profile()
	profile_updated.emit()

func unequip_title() -> void:
	current_title = ""
	save_session()
	save_profile_to_appwrite()
	var nc = get_node_or_null("/root/NetworkClient")
	if nc and nc.has_method("register_social_profile"):
		nc.register_social_profile()
	profile_updated.emit()

func set_profile_bg(hero_id: int) -> void:
	current_profile_bg = hero_id
	save_session()
	save_profile_to_appwrite()
	var nc = get_node_or_null("/root/NetworkClient")
	if nc and nc.has_method("register_social_profile"):
		nc.register_social_profile()
	profile_updated.emit()


# --- 7-Day Login Rewards ---
const SEVEN_DAY_REWARDS = [
	{"day": 1, "tickets": 1, "silver": 1000, "title": "Khởi Sự Nghĩa Quân"},
	{"day": 2, "tickets": 2, "silver": 2000, "title": "Binh Hùng Tướng Mạnh"},
	{"day": 3, "tickets": 3, "silver": 3000, "title": "Uy Chấn Biên Cương"},
	{"day": 4, "tickets": 4, "silver": 4000, "title": "Đại Thắng Vang Dội"},
	{"day": 5, "tickets": 5, "silver": 5000, "title": "Thống Soái Ba Quân"},
	{"day": 6, "tickets": 6, "silver": 6000, "title": "Xã Tắc Vững Bền"},
	{"day": 7, "tickets": 7, "silver": 7000, "title": "Đại Định Giang Sơn (Thần Thưởng)"},
]

# --- 7-Day Login Rewards (Đảm bảo đúng 7 ngày đầu, không quay vòng, độc lập theo nick) ---
func _get_user_checkin_file(uid: String = "") -> String:
	if uid == "":
		uid = current_user_id
	if uid == "":
		return "user://checkin_guest.json"
	var clean_uid = uid.replace("/", "_").replace("\\", "_").replace(":", "_").replace("@", "_")
	return "user://checkin_%s.json" % clean_uid

func _load_local_user_checkin() -> void:
	if current_user_id == "":
		return
	var path = _get_user_checkin_file(current_user_id)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				if parsed.has("claimed") and parsed["claimed"] is Array:
					for d in parsed["claimed"]:
						var d_int = int(d)
						if d_int >= 1 and d_int <= 7 and not checkin_7day_claimed.has(d_int):
							checkin_7day_claimed.append(d_int)
				if parsed.has("last_date") and last_checkin_date == "":
					last_checkin_date = str(parsed["last_date"])

func _save_local_user_checkin() -> void:
	if current_user_id == "":
		return
	var path = _get_user_checkin_file(current_user_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"userId": current_user_id,
			"claimed": checkin_7day_claimed,
			"last_date": last_checkin_date
		}))

func is_checkin_day_claimed(day_num: int) -> bool:
	return checkin_7day_claimed.has(day_num)

func can_claim_checkin_today() -> bool:
	var today = Time.get_date_string_from_system()
	if last_checkin_date == today:
		return false
	# Đủ 7 ngày là xong, không có ngày thứ 8 và không bao giờ lặp lại
	return checkin_7day_claimed.size() < 7

func get_next_checkin_day() -> int:
	return clampi(checkin_7day_claimed.size() + 1, 1, 7)

func claim_7day_reward(day_num: int) -> Dictionary:
	# 1. Giới hạn nghiêm ngặt chỉ từ ngày 1 đến ngày 7
	if day_num < 1 or day_num > 7:
		print("[AuthManager] Ngày điểm danh không hợp lệ: ", day_num)
		return {"success": false, "message": "Chỉ có quà điểm danh từ ngày 1 đến ngày 7!"}

	# 2. Đã nhận đủ 7 ngày thì hoàn tất vĩnh viễn cho nick này, tuyệt đối không lặp lại vòng mới
	if checkin_7day_claimed.size() >= 7:
		print("[AuthManager] Nick này đã hoàn thành trọn vẹn 7 ngày điểm danh tân thủ!")
		return {"success": false, "message": "Đã hoàn thành toàn bộ 7 ngày điểm danh tân thủ!"}

	# 3. Ngày này đã nhận rồi thì không cho nhận lại
	if checkin_7day_claimed.has(day_num):
		print("[AuthManager] Phần thưởng ngày %d đã nhận rồi!" % day_num)
		return {"success": false, "message": "Phần thưởng ngày này đã được nhận trước đó!"}

	# 4. Bắt buộc nhận tuần tự theo ngày tiếp theo (không nhảy ngày)
	var expected_day = get_next_checkin_day()
	if day_num != expected_day:
		print("[AuthManager] Chưa tới lượt nhận ngày %d, lượt tiếp theo là ngày %d" % [day_num, expected_day])
		return {"success": false, "message": "Chưa đến lượt nhận quà ngày này!"}

	# 5. Mỗi ngày thực tế chỉ điểm danh 1 lần
	var today = Time.get_date_string_from_system()
	if last_checkin_date == today:
		print("[AuthManager] Hôm nay đã điểm danh rồi!")
		return {"success": false, "message": "Hôm nay Đại Tướng Quân đã điểm danh rồi!"}

	# Hợp lệ -> Thêm vào danh sách và cộng thưởng
	checkin_7day_claimed.append(day_num)
	last_checkin_date = today

	var tickets = day_num
	var silver = day_num * 1000
	current_hero_tickets += tickets
	current_silver += silver

	_save_local_user_checkin()
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	print("[AuthManager] Điểm danh thành công Ngày %d! (+%d Vé, +%d Bạc) Tiến trình: %d/7" % [day_num, tickets, silver, checkin_7day_claimed.size()])
	return {"success": true, "day": day_num, "tickets": tickets, "silver": silver}

func dev_reset_7day_checkin() -> void:
	checkin_7day_claimed.clear()
	last_checkin_date = ""
	_save_local_user_checkin()
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func dev_advance_checkin_day() -> void:
	last_checkin_date = ""
	_save_local_user_checkin()
	save_session()
	profile_updated.emit()

# --- Mailbox System (Tối ưu theo nick, không theo máy) ---
func _get_user_mailbox_file(uid: String = "") -> String:
	if uid == "":
		uid = current_user_id
	if uid == "":
		return "user://mailbox_guest.json"
	var clean_uid = uid.replace("/", "_").replace("\\", "_").replace(":", "_").replace("@", "_")
	return "user://mailbox_%s.json" % clean_uid

func _load_local_user_mailbox() -> void:
	if current_user_id == "":
		return
	var path = _get_user_mailbox_file(current_user_id)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				if parsed.has("claimed") and parsed["claimed"] is Array:
					for m in parsed["claimed"]:
						if not claimed_mails.has(str(m)):
							claimed_mails.append(str(m))
				if parsed.has("deleted") and parsed["deleted"] is Array:
					for m in parsed["deleted"]:
						if not deleted_mails.has(str(m)):
							deleted_mails.append(str(m))

func _save_local_user_mailbox() -> void:
	if current_user_id == "":
		return
	var path = _get_user_mailbox_file(current_user_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"userId": current_user_id,
			"claimed": claimed_mails,
			"deleted": deleted_mails
		}))

func is_mail_claimed(mail_id: String) -> bool:
	return claimed_mails.has(mail_id)

func is_mail_deleted(mail_id: String) -> bool:
	return deleted_mails.has(mail_id)

func claim_mail_reward(mail_id: String) -> Dictionary:
	if is_mail_claimed(mail_id):
		return {"success": false, "message": "Thư đã nhận trước đó"}
	if not claimed_mails.has(mail_id):
		claimed_mails.append(mail_id)
	
	var res = {"success": true, "silver": 0, "tickets": 0}
	if mail_id == "tan_thu_gift":
		current_silver += 5000
		current_hero_tickets += 1
		res["silver"] = 5000
		res["tickets"] = 1
	
	_save_local_user_mailbox()
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return res

func delete_mail(mail_id: String) -> bool:
	if not deleted_mails.has(mail_id):
		deleted_mails.append(mail_id)
	_save_local_user_mailbox()
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return true

# ID duy nhất của laptop nhà phát triển
const DEV_LAPTOP_MACHINE_IDS: Array[String] = [
	"87b3fe32-b39f-11f0-abd7-806e6f6e6963",
	"{87b3fe32-b39f-11f0-abd7-806e6f6e6963}"
]

func is_dev_machine() -> bool:
	var raw_id = OS.get_unique_id().strip_edges().to_lower()
	var clean_id = raw_id.replace("{", "").replace("}", "")
	return (raw_id in DEV_LAPTOP_MACHINE_IDS or clean_id in DEV_LAPTOP_MACHINE_IDS)

func get_military_rank_info() -> Dictionary:
	var pts = get_military_points()
	var current_tier = MILITARY_TIERS[0]
	var next_tier = MILITARY_TIERS[0]

	for i in range(MILITARY_TIERS.size() - 1, -1, -1):
		if pts >= MILITARY_TIERS[i]["min"]:
			current_tier = MILITARY_TIERS[i]
			if i < MILITARY_TIERS.size() - 1:
				next_tier = MILITARY_TIERS[i + 1]
			else:
				next_tier = current_tier
			break

	var progress = 1.0
	if current_tier["tier"] < 12:
		var span = float(next_tier["min"] - current_tier["min"])
		if span > 0:
			progress = clampf(float(pts - current_tier["min"]) / span, 0.0, 1.0)

	return {
		"points": pts,
		"tier": current_tier["tier"],
		"name": current_tier["name"],
		"badge": current_tier["badge"],
		"full_name": "%s %s" % [current_tier["badge"], current_tier["name"]],
		"next_min": next_tier["min"],
		"progress": progress
	}

# --- Tutorial Reward ---
# Lần đầu chơi tân thủ cho được 20Exp cho vừa tròn lên cấp 2. Tướng Lý Thường Kiệt +5 Exp quân hàm.
func claim_tutorial_reward(exp_amt: int = 20, silver_amt: int = 5000, gold_amt: int = 0) -> Dictionary:
	var old_lvl = current_level
	var old_exp_val = current_exp
	tutorial_reward_claimed = true
	add_general("ly_thuong_kiet")
	current_silver += silver_amt
	current_gold += gold_amt
	var exp_res = add_exp(exp_amt)
	set_onboarding_done()
	save_session()
	save_profile_to_appwrite()

	pending_exp_gain = {
		"old_level": old_lvl,
		"old_exp": old_exp_val,
		"new_level": current_level,
		"new_exp": current_exp,
		"exp_added": exp_amt,
		"show_modal": true
	}

	profile_updated.emit()

	return {
		"exp_result": exp_res,
		"silver": current_silver,
		"gold": current_gold,
		"generals": current_generals,
		"military_info": get_military_rank_info()
	}

# --- Appwrite Account Prefs Sync ---
func fetch_profile_from_appwrite(on_completed: Callable = Callable()) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account/prefs"
	var headers = get_auth_headers(true)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		if response_code == 200:
			var json = JSON.new()
			if json.parse(resp_body.get_string_from_utf8()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					var needs_init_on_appwrite: bool = false

					if data.has("level") and int(data["level"]) > 0:
						current_level = int(data["level"])
					else:
						current_level = 1
						needs_init_on_appwrite = true

					if data.has("exp"):
						current_exp = int(data["exp"])
					else:
						current_exp = 0
						needs_init_on_appwrite = true

					if normalize_exp_progress():
						needs_init_on_appwrite = true

					if data.has("silver"):
						current_silver = int(data["silver"])
					else:
						current_silver = 5000
						needs_init_on_appwrite = true

					if data.has("gold"):
						current_gold = int(data["gold"])
					else:
						current_gold = 0
						needs_init_on_appwrite = true

					if data.has("rank2v2Points"):
						current_2v2_points = int(data["rank2v2Points"])
					else:
						current_2v2_points = 1200
						needs_init_on_appwrite = true

					# 2v2 Rank & Stars: NẾU TRÊN APPWRITE CHƯA CÓ -> BẮT BUỘC 0 SAO & RANK 0 (DÂN BINH)!
					if data.has("rank2v2Index"):
						current_2v2_rank_index = int(data["rank2v2Index"])
					else:
						current_2v2_rank_index = 0
						needs_init_on_appwrite = true

					if data.has("rank2v2Stars"):
						current_2v2_stars = int(data["rank2v2Stars"])
					else:
						current_2v2_stars = 0
						needs_init_on_appwrite = true

					if data.has("rank2v2AccPoints"):
						current_2v2_accumulation_points = int(data["rank2v2AccPoints"])
					else:
						current_2v2_accumulation_points = 0
						needs_init_on_appwrite = true

					if data.has("wins"):
						current_wins = max(0, int(data["wins"]))
					else:
						current_wins = 0
						needs_init_on_appwrite = true
					if data.has("losses"):
						current_losses = max(0, int(data["losses"]))
					else:
						current_losses = 0
						needs_init_on_appwrite = true

					if data.has("tutorialRewardClaimed"):
						tutorial_reward_claimed = bool(data["tutorialRewardClaimed"])
					else:
						tutorial_reward_claimed = false
						needs_init_on_appwrite = true

					if data.has("onboardingComplete"):
						onboarding_completed = bool(data["onboardingComplete"])
					elif tutorial_reward_claimed or current_level > 1 or current_exp > 0 or current_generals.size() > 1:
						onboarding_completed = true
					else:
						onboarding_completed = false

					if data.has("hasPlayedBefore"):
						has_played_before = bool(data["hasPlayedBefore"])
					elif data.has("tutorialCompleted"):
						has_played_before = bool(data["tutorialCompleted"])
					else:
						has_played_before = onboarding_completed or tutorial_reward_claimed
					if has_played_before:
						onboarding_completed = true
					elif current_wins > 0 or current_losses > 0:
						# Tài khoản đã có lịch sử đấu thì không còn là người mới.
						has_played_before = true
						onboarding_completed = true

					if data.has("generals"):
						var g_val = data["generals"]
						if g_val is String and g_val != "":
							current_generals = Array(g_val.split(","))
						elif g_val is Array:
							current_generals = g_val
					else:
						current_generals = ["ly_thuong_kiet"]
						needs_init_on_appwrite = true
					if current_generals.is_empty():
						current_generals = ["ly_thuong_kiet"]

					if data.has("heroTickets"):
						current_hero_tickets = int(data["heroTickets"])
					else:
						current_hero_tickets = 0
						needs_init_on_appwrite = true
					if data.has("skinTickets"):
						current_skin_tickets = int(data["skinTickets"])
					else:
						current_skin_tickets = 0
					if data.has("checkin7DayClaimed"):
						var c_val = data["checkin7DayClaimed"]
						if c_val is String and c_val != "":
							var parsed = JSON.parse_string(c_val)
							if parsed is Array:
								checkin_7day_claimed = parsed
						elif c_val is Array:
							checkin_7day_claimed = c_val
					if data.has("lastCheckinDate"):
						last_checkin_date = str(data["lastCheckinDate"])
					if data.has("dailyQuestsData"):
						var q_val = data["dailyQuestsData"]
						if q_val is String and q_val != "":
							var parsed = JSON.parse_string(q_val)
							if parsed is Dictionary:
								daily_quests_data = parsed
						elif q_val is Dictionary:
							daily_quests_data = q_val
						_sanitize_daily_quests_data()
					if data.has("redeemedCodes"):
						var r_val = data["redeemedCodes"]
						if r_val is String and r_val != "":
							var parsed_rc = JSON.parse_string(r_val)
							if parsed_rc is Array:
								redeemed_codes = parsed_rc
						elif r_val is Array:
							redeemed_codes = r_val
					if data.has("claimedMails"):
						var c_val = data["claimedMails"]
						if c_val is String and c_val != "":
							var parsed_cm = JSON.parse_string(c_val)
							if parsed_cm is Array:
								for item in parsed_cm:
									if not claimed_mails.has(str(item)):
										claimed_mails.append(str(item))
						elif c_val is Array:
							for item in c_val:
								if not claimed_mails.has(str(item)):
									claimed_mails.append(str(item))
					if data.has("deletedMails"):
						var d_val = data["deletedMails"]
						if d_val is String and d_val != "":
							var parsed_dm = JSON.parse_string(d_val)
							if parsed_dm is Array:
								for item in parsed_dm:
									if not deleted_mails.has(str(item)):
										deleted_mails.append(str(item))
						elif d_val is Array:
							for item in d_val:
								if not deleted_mails.has(str(item)):
									deleted_mails.append(str(item))
					_load_local_user_mailbox()
					_save_local_user_mailbox()
					_load_local_user_checkin()
					_save_local_user_checkin()
					if data.has("code"):
						admin_gift_code = str(data["code"])
					if data.has("gift"):
						admin_gift_reward = str(data["gift"])
					elif data.has("qua"):
						admin_gift_reward = str(data["qua"])
					elif data.has("reward"):
						admin_gift_reward = str(data["reward"])

					if data.has("title"):
						current_title = str(data["title"])
					if data.has("profileBg"):
						current_profile_bg = int(data["profileBg"])
					if current_title == "admin" and not is_admin():
						current_title = ""

					save_session()

					if needs_init_on_appwrite:
						print("[AuthManager] Tài khoản mới hoặc thiếu prefs Appwrite -> Đang khởi tạo chuẩn: Rank 0 Dân Binh, 0 sao, 0 điểm!")
						save_profile_to_appwrite()

					profile_updated.emit()
					sync_leaderboard_entry()
					print("[AuthManager] Đồng bộ Appwrite thành công! User: %s, Level: %d, Exp: %d, Bạc: %d, Vé: %d, 2v2: Rank %d (%s), %d sao, %d/100 điểm tích lũy" % [
						current_user_name, current_level, current_exp, current_silver, current_hero_tickets, current_2v2_rank_index,
						RankSystem.get_rank_name(current_2v2_rank_index) if RankSystem else "Dân Binh",
						current_2v2_stars, current_2v2_accumulation_points
					])
		if on_completed.is_valid():
			on_completed.call()
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func save_profile_to_appwrite(on_completed: Callable = Callable()) -> void:
	if disable_session_save:
		if on_completed.is_valid(): on_completed.call()
		return
	save_session()

	if session_secret == "" and session_cookie == "":
		if on_completed.is_valid(): on_completed.call()
		return

	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account/prefs"
	var headers = get_auth_headers(true)
	var prefs_payload = {
		"level": current_level,
		"exp": current_exp,
		"silver": current_silver,
		"gold": current_gold,
		"heroTickets": current_hero_tickets,
		"skinTickets": current_skin_tickets,
		"checkin7DayClaimed": JSON.stringify(checkin_7day_claimed),
		"lastCheckinDate": last_checkin_date,
		"dailyQuestsData": JSON.stringify(daily_quests_data),
		"militaryPoints": get_military_points(),
		"rank2v2Points": current_2v2_points,
		"rank2v2Index": current_2v2_rank_index,
		"rank2v2Stars": current_2v2_stars,
		"rank2v2AccPoints": current_2v2_accumulation_points,
		"wins": current_wins,
		"losses": current_losses,
		"generals": ",".join(current_generals),
		"tutorialRewardClaimed": tutorial_reward_claimed,
		"onboardingComplete": onboarding_completed or tutorial_reward_claimed,
		"tutorialCompleted": onboarding_completed or tutorial_reward_claimed,
		"hasPlayedBefore": has_played_before or onboarding_completed or tutorial_reward_claimed,
		"redeemedCodes": JSON.stringify(redeemed_codes),
		"claimedMails": JSON.stringify(claimed_mails),
		"deletedMails": JSON.stringify(deleted_mails),
		"title": current_title,
		"profileBg": current_profile_bg
	}
	if current_user_email == "vdthanh224@gmail.com" or current_user_name == "Thành Hydro" or is_admin():
		prefs_payload["code"] = admin_gift_code
		prefs_payload["gift"] = admin_gift_reward
		prefs_payload["qua"] = admin_gift_reward
	var body = JSON.stringify({
		"prefs": prefs_payload
	})

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		if response_code == 200:
			print("[AuthManager] Đã lưu thông tin Profile lên Appwrite thành công!")
			sync_leaderboard_entry()
		else:
			print("[AuthManager] Lưu Profile Appwrite kết quả mã: ", response_code)
		if on_completed.is_valid():
			on_completed.call()
	)

	http.request(url, headers, HTTPClient.METHOD_PATCH, body)

# --- Leaderboard Real Data Synchronization (Appwrite Singapore) ---
func get_leaderboard_doc_id() -> String:
	var key = current_user_id if not current_user_id.is_empty() else current_user_email
	if key.is_empty():
		key = current_user_name
	if key.is_empty():
		key = "guest_" + OS.get_unique_id()
	return "lb_" + key.md5_text().substr(0, 24)

func get_leaderboard_player_data() -> Dictionary:
	var tier_info = get_military_rank_info()
	var rank_name = "Dân Binh"
	var rs = get_node_or_null("/root/RankSystem")
	if rs and rs.has_method("get_rank_name"):
		rank_name = rs.get_rank_name(current_2v2_rank_index)

	var p_data = {
		"user_id": current_user_id,
		"name": current_user_name,
		"email": current_user_email,
		"level": current_level,
		"exp": current_exp,
		"generals_count": current_generals.size(),
		"military_points": get_military_points(),
		"military_tier": tier_info.get("tier", 1),
		"military_name": tier_info.get("name", "Tân Binh"),
		"military_badge": tier_info.get("badge", "🔰"),
		"hero_tickets": current_hero_tickets,
		"skin_tickets": current_skin_tickets,
		"rank_index": current_2v2_rank_index,
		"rank_name": rank_name,
		"rank_stars": current_2v2_stars,
		"rank_acc": current_2v2_accumulation_points,
		"rank_points": current_2v2_points,
		"wins": current_wins,
		"losses": current_losses,
		"title": current_title,
		"profile_bg": current_profile_bg,
		"updated_at": int(Time.get_unix_time_from_system())
	}
	if current_user_email == "vdthanh224@gmail.com" or current_user_name == "Thành Hydro" or is_admin():
		p_data["code"] = admin_gift_code
		p_data["gift"] = admin_gift_reward
		p_data["qua"] = admin_gift_reward
	return p_data

func sync_leaderboard_entry(on_completed: Callable = Callable()) -> void:
	if disable_session_save:
		if on_completed.is_valid(): on_completed.call()
		return

	var http = HTTPRequest.new()
	add_child(http)

	var doc_id = get_leaderboard_doc_id()
	var player_data = get_leaderboard_player_data()
	var now_ms = int(Time.get_unix_time_from_system() * 1000.0)

	var payload_data = {
		"userId": "LEADERBOARD_PLAYER",
		"userName": JSON.stringify(player_data),
		"rankPoints": current_2v2_points,
		"timestamp": now_ms
	}
	var permissions = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"]

	var patch_url = "%s/databases/game/collections/matchmaking_queue/documents/%s" % [ENDPOINT, doc_id]
	var headers = get_auth_headers(true)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		if response_code == 404:
			# Document does not exist yet -> Create with POST
			var post_http = HTTPRequest.new()
			add_child(post_http)
			var post_url = "%s/databases/game/collections/matchmaking_queue/documents" % ENDPOINT
			var post_body = JSON.stringify({
				"documentId": doc_id,
				"data": payload_data,
				"permissions": permissions
			})
			post_http.request_completed.connect(func(p_res, p_code, p_h, p_b):
				post_http.queue_free()
				http.queue_free()
				if p_code == 200 or p_code == 201:
					print("[AuthManager] Đã tạo mới bản ghi Bảng Vàng trên Appwrite thành công! Doc ID: ", doc_id)
				else:
					print("[AuthManager] Tạo bản ghi Bảng Vàng Appwrite mã: ", p_code)
				if on_completed.is_valid(): on_completed.call()
			)
			post_http.request(post_url, headers, HTTPClient.METHOD_POST, post_body)
		else:
			http.queue_free()
			if response_code == 200:
				print("[AuthManager] Đã cập nhật bản ghi Bảng Vàng trên Appwrite thành công! Doc ID: ", doc_id)
			else:
				print("[AuthManager] Cập nhật bản ghi Bảng Vàng Appwrite mã: ", response_code)
			if on_completed.is_valid(): on_completed.call()
	)

	var patch_body = JSON.stringify({
		"data": payload_data,
		"permissions": permissions
	})
	http.request(patch_url, headers, HTTPClient.METHOD_PATCH, patch_body)

func fetch_leaderboard_players(on_done: Callable) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var q_equal = "{\"method\":\"equal\",\"attribute\":\"userId\",\"values\":[\"LEADERBOARD_PLAYER\"]}".uri_encode()
	var q_limit = "{\"method\":\"limit\",\"values\":[100]}".uri_encode()
	var url = "%s/databases/game/collections/matchmaking_queue/documents?queries[0]=%s&queries[1]=%s" % [ENDPOINT, q_equal, q_limit]
	var headers = get_auth_headers(false)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		var players: Array = []
		if response_code == 200:
			var body_str = resp_body.get_string_from_utf8()
			var json = JSON.parse_string(body_str)
			if json is Dictionary and json.has("documents"):
				for doc in json["documents"]:
					if doc is Dictionary and doc.has("userName"):
						var parsed = JSON.parse_string(str(doc["userName"]))
						if parsed is Dictionary:
							players.append(parsed)
		if on_done.is_valid():
			on_done.call(players)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

# --- Giftcode System (Appwrite Singapore & Thành Hydro) ---
const THANH_HYDRO_DOC_ID: String = "lb_0a0142270b7d1ad35c482ada"

func parse_gift_reward(reward_raw: Variant) -> Dictionary:
	var res = {
		"hero_tickets": 0,
		"skin_tickets": 0,
		"silver": 0,
		"gold": 0,
		"exp": 0,
		"summary": ""
	}

	if reward_raw is Dictionary:
		_fill_reward_dict(res, reward_raw)
	elif reward_raw is String:
		var raw_str = str(reward_raw).strip_edges()
		if raw_str.begins_with("{") and raw_str.ends_with("}"):
			var parsed_json = JSON.parse_string(raw_str)
			if parsed_json is Dictionary:
				_fill_reward_dict(res, parsed_json)
		if res["hero_tickets"] == 0 and res["skin_tickets"] == 0 and res["silver"] == 0 and res["gold"] == 0 and res["exp"] == 0:
			_parse_reward_text(res, raw_str)

	if res["summary"] == "":
		var parts: Array[String] = []
		if res["hero_tickets"] > 0:
			parts.append("%d Vé quay tướng" % res["hero_tickets"])
		if res["skin_tickets"] > 0:
			parts.append("%d Vé trang phục" % res["skin_tickets"])
		if res["gold"] > 0:
			parts.append("%d Vàng" % res["gold"])
		if res["silver"] > 0:
			parts.append("%d Bạc" % res["silver"])
		if res["exp"] > 0:
			parts.append("%d Exp" % res["exp"])
		if parts.is_empty():
			res["summary"] = "Phần quà bí mật"
		else:
			res["summary"] = ", ".join(parts)

	return res

func _fill_reward_dict(target: Dictionary, src: Dictionary) -> void:
	target["hero_tickets"] = int(src.get("hero_tickets", src.get("heroTickets", src.get("ve_quay_tuong", src.get("ve_quay", 0)))))
	target["skin_tickets"] = int(src.get("skin_tickets", src.get("skinTickets", src.get("ve_trang_phuc", 0))))
	target["silver"] = int(src.get("silver", src.get("bac", src.get("xu", 0))))
	target["gold"] = int(src.get("gold", src.get("vang", 0)))
	target["exp"] = int(src.get("exp", src.get("kinh_nghiem", 0)))

func _parse_reward_text(target: Dictionary, text: String) -> void:
	var lower = text.to_lower()
	var delimiters = [",", ";", "+", " và ", " va "]
	var chunks = [lower]
	for d in delimiters:
		var new_chunks = []
		for c in chunks:
			for piece in c.split(d):
				var p_trim = piece.strip_edges()
				if p_trim != "":
					new_chunks.append(p_trim)
		chunks = new_chunks

	var regex = RegEx.new()
	regex.compile("\\d+")

	for chunk in chunks:
		var match_num = regex.search(chunk)
		var num = 0
		if match_num:
			num = int(match_num.get_string())
		if num <= 0:
			continue

		if "trang phục" in chunk or "trang phuc" in chunk or "skin" in chunk:
			target["skin_tickets"] += num
		elif "tướng" in chunk or "tuong" in chunk or "vé" in chunk or "ve" in chunk or "ticket" in chunk or "quay" in chunk:
			target["hero_tickets"] += num
		elif "bạc" in chunk or "bac" in chunk or "silver" in chunk or "xu" in chunk:
			target["silver"] += num
		elif "vàng" in chunk or "vang" in chunk or "gold" in chunk:
			target["gold"] += num
		elif "exp" in chunk or "kinh nghiệm" in chunk or "kinh nghiem" in chunk:
			target["exp"] += num
		else:
			target["hero_tickets"] += num

func apply_gift_reward(reward_dict: Dictionary) -> String:
	var granted: Array[String] = []
	var ht = int(reward_dict.get("hero_tickets", 0))
	if ht > 0:
		current_hero_tickets += ht
		granted.append("+%d Vé quay tướng" % ht)
	var st = int(reward_dict.get("skin_tickets", 0))
	if st > 0:
		current_skin_tickets += st
		granted.append("+%d Vé trang phục" % st)
	var s = int(reward_dict.get("silver", 0))
	if s > 0:
		current_silver += s
		granted.append("+%d Bạc" % s)
	var g = int(reward_dict.get("gold", 0))
	if g > 0:
		current_gold += g
		granted.append("+%d Vàng" % g)
	var exp_pts = int(reward_dict.get("exp", 0))
	if exp_pts > 0:
		add_exp(exp_pts)
		granted.append("+%d Exp" % exp_pts)

	var summary = ", ".join(granted) if not granted.is_empty() else str(reward_dict.get("summary", "Phần quà đặc biệt"))
	return summary

func fetch_admin_giftcode(on_done: Callable = Callable()) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var url = "%s/databases/game/collections/matchmaking_queue/documents/%s" % [ENDPOINT, THANH_HYDRO_DOC_ID]
	var headers = get_auth_headers(false)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		var found = false
		if response_code == 200:
			var body_str = resp_body.get_string_from_utf8()
			var json = JSON.parse_string(body_str)
			if json is Dictionary and json.has("userName"):
				var parsed = JSON.parse_string(str(json["userName"]))
				if parsed is Dictionary:
					if parsed.has("code"):
						admin_gift_code = str(parsed["code"]).strip_edges()
						found = true
					if parsed.has("gift"):
						admin_gift_reward = str(parsed["gift"]).strip_edges()
					elif parsed.has("qua"):
						admin_gift_reward = str(parsed["qua"]).strip_edges()
					elif parsed.has("reward"):
						admin_gift_reward = str(parsed["reward"]).strip_edges()
		if not found:
			fetch_leaderboard_players(func(players: Array):
				for p in players:
					if p is Dictionary:
						var p_id = str(p.get("user_id", ""))
						var p_email = str(p.get("email", "")).to_lower()
						var p_name = str(p.get("name", "")).to_lower()
						if p_id == "348b57be51fd4dea87a1f8ab03271664" or p_email == "vdthanh224@gmail.com" or "thành hydro" in p_name or "thanh hydro" in p_name:
							if p.has("code"):
								admin_gift_code = str(p["code"]).strip_edges()
								found = true
							if p.has("gift"):
								admin_gift_reward = str(p["gift"]).strip_edges()
							elif p.has("qua"):
								admin_gift_reward = str(p["qua"]).strip_edges()
							elif p.has("reward"):
								admin_gift_reward = str(p["reward"]).strip_edges()
							break
				if on_done.is_valid():
					on_done.call(found, admin_gift_code, admin_gift_reward)
			)
			return

		if on_done.is_valid():
			on_done.call(found, admin_gift_code, admin_gift_reward)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func redeem_giftcode(input_code: String, on_completed: Callable = Callable()) -> void:
	var clean_code = input_code.strip_edges().to_upper()
	if clean_code == "":
		if on_completed.is_valid():
			on_completed.call(false, "Vui lòng nhập mã CODE quà tặng!", {})
		return

	if clean_code in redeemed_codes:
		if on_completed.is_valid():
			on_completed.call(false, "Đại Tướng Quân đã nhập mã CODE này rồi!", {})
		return

	fetch_admin_giftcode(func(fetch_success: bool, active_code: String, active_reward: String):
		var target_code = active_code.strip_edges().to_upper()
		if target_code == "":
			target_code = "DAIVIETCHIEN"

		if clean_code != target_code:
			if on_completed.is_valid():
				on_completed.call(false, "Mã CODE không chính xác hoặc đã hết hạn!", {})
			return

		var reward_dict = parse_gift_reward(active_reward)
		var summary = apply_gift_reward(reward_dict)
		redeemed_codes.append(clean_code)
		save_session()
		save_profile_to_appwrite()
		profile_updated.emit()

		var msg = "Chúc mừng Đại Tướng Quân! Đổi mã CODE thành công:\n%s" % summary
		if on_completed.is_valid():
			on_completed.call(true, msg, reward_dict)
	)

func update_admin_giftcode_to_appwrite(new_code: String, new_reward: String, on_done: Callable = Callable()) -> void:
	var clean_code = new_code.strip_edges().to_upper()
	var clean_reward = new_reward.strip_edges()
	if clean_code == "":
		clean_code = "DAIVIETCHIEN"
	if clean_reward == "":
		clean_reward = "5 vé quay tướng"

	admin_gift_code = clean_code
	admin_gift_reward = clean_reward
	save_session()
	save_profile_to_appwrite()

	var http = HTTPRequest.new()
	add_child(http)

	var url = "%s/databases/game/collections/matchmaking_queue/documents/%s" % [ENDPOINT, THANH_HYDRO_DOC_ID]
	var headers = get_auth_headers(true)

	var p_data = get_leaderboard_player_data()
	p_data["code"] = clean_code
	p_data["gift"] = clean_reward
	p_data["qua"] = clean_reward

	var now_ms = int(Time.get_unix_time_from_system() * 1000.0)
	var payload_data = {
		"userId": "LEADERBOARD_PLAYER",
		"userName": JSON.stringify(p_data),
		"rankPoints": current_2v2_points,
		"timestamp": now_ms
	}
	var permissions = ["read(\"any\")", "update(\"any\")", "delete(\"any\")"]
	var patch_body = JSON.stringify({
		"data": payload_data,
		"permissions": permissions
	})

	http.request_completed.connect(func(res, code, h, b):
		http.queue_free()
		print("[AuthManager] Đã cập nhật CODE và QUÀ lên Appwrite, mã: ", code)
		if on_done.is_valid():
			on_done.call(code == 200 or code == 201)
	)

	http.request(url, headers, HTTPClient.METHOD_PATCH, patch_body)



func reset_to_defaults() -> void:
	current_user_name = "Đại Tướng Quân"
	current_user_email = ""
	current_user_id = ""
	current_user_labels.clear()
	session_secret = ""
	session_cookie = ""
	fallback_cookies = ""
	is_logged_in = false
	current_level = 1
	current_exp = 0
	current_silver = 5000
	current_gold = 0
	current_hero_tickets = 0
	current_skin_tickets = 0
	checkin_7day_claimed.clear()
	last_checkin_date = ""
	current_generals = ["ly_thuong_kiet"]
	current_2v2_points = 1200
	current_2v2_rank_index = 0
	current_2v2_stars = 0
	current_2v2_accumulation_points = 0
	current_wins = 0
	current_losses = 0
	tutorial_reward_claimed = false
	onboarding_completed = false
	pending_exp_gain.clear()
	daily_quests_data.clear()
	redeemed_codes.clear()
	claimed_mails.clear()
	claimed_match_rewards.clear()
	deleted_mails.clear()
	save_session()

# --- Authentication Logic ---
func login_email(email: String, password: String) -> void:
	email = email.strip_edges()
	if email == "" or password == "":
		login_failed.emit("Vui lòng nhập đầy đủ Email và Mật thư.")
		return

	if (session_secret != "" or session_cookie != "") and current_user_email != email:
		print("[AuthManager] Đang chuyển từ tài khoản %s sang %s -> Giải phóng phiên cũ..." % [current_user_email, email])
		delete_current_session(func():
			_do_login_email(email, password)
		)
		return

	_do_login_email(email, password)

func _do_login_email(email: String, password: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account/sessions/email"
	var body = JSON.stringify({ "email": email, "password": password })
	var headers = get_auth_headers(false)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		_handle_login_response(result, response_code, resp_headers, resp_body, email, password)
	)

	var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		login_failed.emit("Lỗi khởi tạo kết nối HTTP: " + str(err))

func delete_current_session(on_completed: Callable = Callable()) -> void:
	if is_deleting_session:
		if on_completed.is_valid(): on_completed.call()
		return

	is_deleting_session = true
	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account/sessions/current"
	var headers = get_auth_headers(true)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		is_deleting_session = false
		reset_to_defaults()
		print("[AuthManager] Đã giải phóng phiên cũ và làm mới dữ liệu người chơi về mặc định!")
		if on_completed.is_valid():
			on_completed.call()
	)

	var err = http.request(url, headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		http.queue_free()
		is_deleting_session = false
		reset_to_defaults()
		if on_completed.is_valid():
			on_completed.call()

func register_email(email: String, password: String, name: String) -> void:
	email = email.strip_edges()
	name = name.strip_edges()
	if name == "": name = "Đại Tướng Quân"

	if email == "" or password.length() < 8:
		login_failed.emit("Email hợp lệ và Mật thư tối thiểu 8 ký tự.")
		return

	# Làm sạch dữ liệu của tài khoản cũ trước khi tạo tài khoản mới
	reset_to_defaults()

	delete_current_session(func():
		var http = HTTPRequest.new()
		add_child(http)

		var url = ENDPOINT + "/account"
		var user_id = "u_" + str(Time.get_unix_time_from_system()).replace(".", "")
		var body = JSON.stringify({
			"userId": user_id,
			"email": email,
			"password": password,
			"name": name
		})
		var headers = get_auth_headers(false)

		http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
			http.queue_free()
			if response_code == 201 or response_code == 200:
				print("[AuthManager] Đăng ký thành công! Đang tự động đăng nhập...")
				reset_to_defaults()
				login_email(email, password)
			else:
				var err_msg = _parse_error_msg(resp_body, response_code)
				login_failed.emit("Đăng ký thất bại: " + err_msg)
		)

		var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
		if err != OK:
			http.queue_free()
			login_failed.emit("Lỗi gửi yêu cầu đăng ký: " + str(err))
	)

func login_anonymous() -> void:
	delete_current_session(func():
		var http = HTTPRequest.new()
		add_child(http)

		var url = ENDPOINT + "/account/sessions/anonymous"
		var headers = get_auth_headers(false)

		http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
			http.queue_free()
			_handle_login_response(result, response_code, resp_headers, resp_body, "khach@daiviet.vn")
		)

		var err = http.request(url, headers, HTTPClient.METHOD_POST, "{}")
		if err != OK:
			http.queue_free()
			login_failed.emit("Lỗi tạo phiên chơi khách: " + str(err))
	)

func quick_login(num: int) -> void:
	var email = "vdthanh22%d@gmail.com" % num
	var password = "matkhau123"
	login_email(email, password)

func _handle_login_response(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, fallback_email: String, original_password: String = "") -> void:
	if response_code == 200 or response_code == 201:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var data = json.get_data()
		if data is Dictionary:
			var new_uid = data.get("userId", "")
			if new_uid != current_user_id:
				reset_to_defaults()

			current_user_id = new_uid
			_load_local_user_mailbox()
			_load_local_user_checkin()
			session_secret = data.get("secret", "")
			current_user_email = fallback_email
			is_logged_in = true

			for h in headers:
				var h_lower = h.to_lower()
				if h_lower.begins_with("set-cookie:"):
					var cookie_str = h.substr(11).strip_edges().split(";")[0]
					session_cookie = cookie_str
				elif h_lower.begins_with("x-fallback-cookies:"):
					fallback_cookies = h.substr(19).strip_edges()

			# Nếu secret bị trống (trên Web Appwrite không trả secret qua body), giải mã từ X-Fallback-Cookies
			if session_secret == "" and fallback_cookies != "":
				var parsed_fb = JSON.parse_string(fallback_cookies)
				if parsed_fb is Dictionary:
					for k in parsed_fb:
						var val_str = str(parsed_fb[k])
						var b64_bytes = Marshalls.base64_to_raw(val_str)
						var b64_json_str = b64_bytes.get_string_from_utf8()
						var sub_data = JSON.parse_string(b64_json_str)
						if sub_data is Dictionary and sub_data.has("secret"):
							session_secret = str(sub_data["secret"])
							print("[AuthManager] Đã giải mã session_secret từ Fallback Cookies Web thành công!")
							break

			save_session()
			# Thông báo thành công tức thì không bắt người chơi đợi nhiều vòng HTTP
			login_succeeded.emit({
				"name": current_user_name,
				"email": current_user_email,
				"userId": current_user_id,
				"level": current_level,
				"exp": current_exp,
				"silver": current_silver,
				"gold": current_gold
			})
			fetch_account_info()
	else:
		var err_msg = _parse_error_msg(body, response_code)
		if ("session is active" in err_msg.to_lower() or "prohibited when a session is active" in err_msg.to_lower()) and original_password != "":
			# Nếu phiên đang active đúng là tài khoản này, sử dụng luôn không cần xóa đi tạo lại
			if current_user_email == fallback_email and session_secret != "":
				print("[AuthManager] Phiên hiện tại của %s vẫn còn hiệu lực. Đăng nhập tức thì!" % fallback_email)
				is_logged_in = true
				login_succeeded.emit({
					"name": current_user_name,
					"email": current_user_email,
					"userId": current_user_id,
					"level": current_level,
					"exp": current_exp,
					"silver": current_silver,
					"gold": current_gold
				})
				fetch_account_info()
				return

			print("[AuthManager] Phát hiện phiên cũ đang treo. Đang tự động giải phóng phiên và đăng nhập lại...")
			delete_current_session(func():
				await get_tree().create_timer(0.1).timeout
				login_email(fallback_email, original_password)
			)
			return

		login_failed.emit(err_msg)

func fetch_account_info() -> void:
	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account"
	var headers = get_auth_headers(true)

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		if response_code == 200:
			var json = JSON.new()
			json.parse(resp_body.get_string_from_utf8())
			var data = json.get_data()
			if data is Dictionary:
				var u_name = data.get("name", "")
				if u_name != "":
					current_user_name = u_name
				var u_email = data.get("email", "")
				if u_email != "":
					current_user_email = u_email
				current_user_labels.clear()
				var labels = data.get("labels", [])
				if labels is Array:
					for account_label in labels:
						current_user_labels.append(str(account_label))
				save_session()

		# Đồng bộ Profile/Level từ Appwrite ngầm
		fetch_profile_from_appwrite(func():
			profile_updated.emit()
			profile_loaded.emit()
		)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func _parse_error_msg(body: PackedByteArray, response_code: int = 0) -> String:
	var json = JSON.new()
	var raw = body.get_string_from_utf8()
	if json.parse(raw) == OK:
		var d = json.get_data()
		if d is Dictionary and d.has("message"):
			return d["message"]
	if response_code == 0:
		if OS.has_feature("web"):
			return "Lỗi kết nối Web (CORS): Tên miền chưa được thêm vào mục Platforms trên Appwrite Console hoặc mạng bị gián đoạn."
		return "Không thể kết nối máy chủ xác thực. Vui lòng kiểm tra kết nối mạng."
	if response_code == 403:
		return "Máy chủ từ chối kết nối (Mã 403 - Invalid Origin). Vui lòng thêm tên miền này vào Appwrite Console > Platforms."
	return "Không thể kết nối máy chủ xác thực hoặc thông tin không chính xác."

func get_save_path() -> String:
	var inst = 1
	if Engine.get_main_loop() and Engine.get_main_loop().has_method("get_root"):
		var root = Engine.get_main_loop().root
		if root and root.has_node("NetworkClient"):
			var net = root.get_node("NetworkClient")
			if "auto_instance_index" in net:
				inst = net.auto_instance_index
	if inst == 1:
		var all_args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
		for arg in all_args:
			if arg.begins_with("--seat=") or arg.begins_with("--tester="):
				var val = arg.split("=")[1].to_int()
				if val >= 1 and val <= 8:
					inst = val
					break
	if inst > 1:
		return "user://auth_session_%d.json" % inst
	return "user://auth_session.json"

func claim_match_reward(result: Dictionary, mode_id: String, stake_recorded: bool = false, stake_amount: int = 0) -> bool:
	var match_id := str(result.get("matchId", ""))
	if match_id.is_empty() or claimed_match_rewards.has(match_id):
		return false
	var is_win := bool(result.get("isWinner", false))
	claimed_match_rewards[match_id] = true
	current_silver += 150 if is_win else 75
	if is_win:
		current_wins += 1
	else:
		current_losses += 1
	if mode_id == "2v2":
		var star_delta := RankSystem.WIN_STARS if is_win else RankSystem.LOSE_STARS
		if stake_recorded:
			star_delta = RankSystem.WIN_STARS + stake_amount if is_win else 0
		var rank_result = RankSystem.process_match_result_adjusted(is_win, current_2v2_rank_index, current_2v2_stars,
			current_2v2_accumulation_points, star_delta,
			RankSystem.WIN_ACCUMULATION_POINTS if is_win else RankSystem.LOSE_ACCUMULATION_POINTS)
		current_2v2_rank_index = rank_result.rank_index
		current_2v2_stars = rank_result.stars
		current_2v2_accumulation_points = rank_result.accumulation_points
		current_2v2_entry_stake_room_id = ""
		current_2v2_entry_stake_amount = 0
	if DailyQuestSystem:
		DailyQuestSystem.record_progress("battle", 1)
		if is_win:
			DailyQuestSystem.record_progress("win", 1)
	# add_exp saves the complete updated profile and the claim marker together.
	add_exp(20 if is_win else 12)
	return true

func save_session() -> void:
	if disable_session_save:
		return
	var path = get_save_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var data = {
			"name": current_user_name,
			"email": current_user_email,
			"userId": current_user_id,
			"secret": session_secret,
			"cookie": session_cookie,
			"fallbackCookies": fallback_cookies,
			"level": current_level,
			"exp": current_exp,
			"silver": current_silver,
			"gold": current_gold,
			"heroTickets": current_hero_tickets,
			"skinTickets": current_skin_tickets,
			"checkin7DayClaimed": checkin_7day_claimed,
			"lastCheckinDate": last_checkin_date,
			"generals": current_generals,
			"rank2v2Points": current_2v2_points,
			"rank2v2Index": current_2v2_rank_index,
			"rank2v2Stars": current_2v2_stars,
			"rank2v2AccPoints": current_2v2_accumulation_points,
			"wins": current_wins,
			"losses": current_losses,
			"tutorialRewardClaimed": tutorial_reward_claimed,
			"hasPlayedBefore": has_played_before,
			"dailyQuestsData": daily_quests_data,
			"labels": Array(current_user_labels),
			"onboardingComplete": (onboarding_completed or tutorial_reward_claimed),
			"redeemedCodes": redeemed_codes,
			"claimedMails": claimed_mails,
			"claimedMatchRewards": claimed_match_rewards,
			"deletedMails": deleted_mails,
			"adminGiftCode": admin_gift_code,
			"adminGiftReward": admin_gift_reward,
			"title": current_title,
			"profileBg": current_profile_bg
		}
		if current_user_email != "":
			data["onboarding_" + current_user_email] = 2 if (onboarding_completed or tutorial_reward_claimed) else 0
		file.store_string(JSON.stringify(data))
	_save_local_user_mailbox()
	_save_local_user_checkin()

func should_show_onboarding() -> bool:
	if current_user_email == "": return false
	if onboarding_completed or tutorial_reward_claimed or has_played_before: return false
	if current_level > 1 or current_exp > 0 or current_generals.size() > 1:
		onboarding_completed = true
		return false
	var key = "onboarding_" + current_user_email
	var path = get_save_path()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					if data.get(key, 0) == 2 or data.get("onboardingComplete", false) == true:
						onboarding_completed = true
						return false
	return true

func set_onboarding_done() -> void:
	onboarding_completed = true
	tutorial_reward_claimed = true
	has_played_before = true
	save_session()
	save_profile_to_appwrite()
	print("[AuthManager] Đã lưu hoàn tất Onboarding vào local và Appwrite cho: ", current_user_email)

func mark_played_before() -> void:
	has_played_before = true
	onboarding_completed = true
	save_session()
	save_profile_to_appwrite()
	print("[AuthManager] Đã ghi nhận người chơi đã từng chơi trên Appwrite: ", current_user_email)

func load_saved_session() -> void:
	var path = get_save_path()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary:
					current_user_name = data.get("name", "Đại Tướng Quân")
					current_user_email = data.get("email", "")
					current_user_id = data.get("userId", "")
					session_secret = data.get("secret", "")
					session_cookie = data.get("cookie", "")
					fallback_cookies = data.get("fallbackCookies", "")
					current_level = int(data.get("level", 1))
					current_exp = int(data.get("exp", 0))
					current_silver = int(data.get("silver", 5000))
					current_gold = int(data.get("gold", 0))
					current_hero_tickets = int(data.get("heroTickets", 0))
					current_skin_tickets = int(data.get("skinTickets", 0))
					var saved_claimed = data.get("checkin7DayClaimed", [])
					if saved_claimed is Array:
						checkin_7day_claimed = saved_claimed
					last_checkin_date = str(data.get("lastCheckinDate", ""))
					var saved_quests = data.get("dailyQuestsData", {})
					if saved_quests is Dictionary:
						daily_quests_data = saved_quests
						_sanitize_daily_quests_data()
					current_generals = data.get("generals", ["ly_thuong_kiet"])
					if current_generals.is_empty():
						current_generals = ["ly_thuong_kiet"]
					current_2v2_points = int(data.get("rank2v2Points", 1200))
					current_2v2_rank_index = int(data.get("rank2v2Index", 0))
					current_2v2_stars = int(data.get("rank2v2Stars", 0))
					current_2v2_accumulation_points = int(data.get("rank2v2AccPoints", 0))
					current_wins = max(0, int(data.get("wins", 0)))
					current_losses = max(0, int(data.get("losses", 0)))
					var saved_match_rewards = data.get("claimedMatchRewards", {})
					claimed_match_rewards = saved_match_rewards if saved_match_rewards is Dictionary else {}
					tutorial_reward_claimed = bool(data.get("tutorialRewardClaimed", false))
					has_played_before = bool(data.get("hasPlayedBefore", data.get("tutorialCompleted", false)))
					var saved_labels = data.get("labels", [])
					if saved_labels is Array:
						current_user_labels.clear()
						for lbl in saved_labels:
							current_user_labels.append(str(lbl))
					onboarding_completed = bool(data.get("onboardingComplete", false))
					if not onboarding_completed and current_user_email != "":
						var key = "onboarding_" + current_user_email
						if data.get(key, 0) == 2:
							onboarding_completed = true
					if not onboarding_completed and (current_level > 1 or current_exp > 0 or current_generals.size() > 1):
						onboarding_completed = true
					if session_secret != "" or session_cookie != "" or fallback_cookies != "":
						is_logged_in = true
					var saved_rc = data.get("redeemedCodes", [])
					if saved_rc is Array:
						redeemed_codes.clear()
						for rc in saved_rc:
							redeemed_codes.append(str(rc))
					admin_gift_code = str(data.get("adminGiftCode", admin_gift_code))
					admin_gift_reward = str(data.get("adminGiftReward", admin_gift_reward))
					current_title = str(data.get("title", ""))
					current_profile_bg = int(data.get("profileBg", 0))
					if current_title == "admin" and not is_admin():
						current_title = ""
					var saved_claimed_m = data.get("claimedMails", [])
					if saved_claimed_m is Array:
						for cm in saved_claimed_m:
							if not claimed_mails.has(str(cm)):
								claimed_mails.append(str(cm))
					var saved_del_m = data.get("deletedMails", [])
					if saved_del_m is Array:
						for dm in saved_del_m:
							if not deleted_mails.has(str(dm)):
								deleted_mails.append(str(dm))

	if current_user_id == "":
		current_user_id = "u_" + str(Time.get_unix_time_from_system()).replace(".", "") + "_" + str(randi() % 10000)
		save_session()
	if current_user_name == "":
		current_user_name = "Đại Tướng Quân"
		save_session()
	_load_local_user_mailbox()
	_load_local_user_checkin()

func _sanitize_daily_quests_data() -> void:
	if not (daily_quests_data is Dictionary) or daily_quests_data.is_empty():
		return
	if daily_quests_data.has("claimed_milestones") and daily_quests_data["claimed_milestones"] is Array:
		var clean: Array[int] = []
		for item in daily_quests_data["claimed_milestones"]:
			var v := int(item)
			if v > 0 and not (v in clean):
				clean.append(v)
		daily_quests_data["claimed_milestones"] = clean
	if daily_quests_data.has("activity_points"):
		daily_quests_data["activity_points"] = int(daily_quests_data["activity_points"])
