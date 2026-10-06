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
var checkin_7day_claimed: Array = []
var last_checkin_date: String = ""
var current_2v2_points: int = 1200
var current_2v2_rank_index: int = 0
var current_2v2_stars: int = 0
var current_2v2_accumulation_points: int = 0
var current_wins: int = 0
var current_losses: int = 0
var tutorial_reward_claimed: bool = false
var onboarding_completed: bool = false
var has_played_before: bool = false
var pending_exp_gain: Dictionary = {}
var daily_quests_data: Dictionary = {}
var disable_session_save: bool = false

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

func is_checkin_day_claimed(day_num: int) -> bool:
	return checkin_7day_claimed.has(day_num)

func can_claim_checkin_today() -> bool:
	var today = Time.get_date_string_from_system()
	if last_checkin_date == today:
		return false
	return checkin_7day_claimed.size() < 7

func get_next_checkin_day() -> int:
	return clampi(checkin_7day_claimed.size() + 1, 1, 7)

func claim_7day_reward(day_num: int) -> Dictionary:
	var tickets = day_num
	var silver = day_num * 1000
	if not checkin_7day_claimed.has(day_num):
		checkin_7day_claimed.append(day_num)
	last_checkin_date = Time.get_date_string_from_system()
	current_hero_tickets += tickets
	current_silver += silver
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()
	return {"day": day_num, "tickets": tickets, "silver": silver}

func dev_reset_7day_checkin() -> void:
	checkin_7day_claimed.clear()
	last_checkin_date = ""
	save_session()
	save_profile_to_appwrite()
	profile_updated.emit()

func dev_advance_checkin_day() -> void:
	last_checkin_date = ""
	save_session()
	profile_updated.emit()

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
	var body = JSON.stringify({
		"prefs": {
			"level": current_level,
			"exp": current_exp,
			"silver": current_silver,
			"gold": current_gold,
			"heroTickets": current_hero_tickets,
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
			"hasPlayedBefore": has_played_before or onboarding_completed or tutorial_reward_claimed
		}
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

	return {
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
		"rank_index": current_2v2_rank_index,
		"rank_name": rank_name,
		"rank_stars": current_2v2_stars,
		"rank_acc": current_2v2_accumulation_points,
		"rank_points": current_2v2_points,
		"wins": current_wins,
		"losses": current_losses,
		"updated_at": int(Time.get_unix_time_from_system())
	}

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
				if val >= 1 and val <= 4:
					inst = val
					break
	if inst > 1:
		return "user://auth_session_%d.json" % inst
	return "user://auth_session.json"

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
			"onboardingComplete": (onboarding_completed or tutorial_reward_claimed)
		}
		if current_user_email != "":
			data["onboarding_" + current_user_email] = 2 if (onboarding_completed or tutorial_reward_claimed) else 0
		file.store_string(JSON.stringify(data))

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

	if current_user_id == "":
		current_user_id = "u_" + str(Time.get_unix_time_from_system()).replace(".", "") + "_" + str(randi() % 10000)
		save_session()
	if current_user_name == "":
		current_user_name = "Đại Tướng Quân"
		save_session()

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
