extends Node

signal login_succeeded(user_data: Dictionary)
signal login_failed(error_message: String)
signal profile_updated()

const ENDPOINT = "https://sgp.cloud.appwrite.io/v1"
const PROJECT_ID = "6a885457002da3f3d47e"
const SAVE_PATH = "user://auth_session.json"

var current_user_name: String = "Đại Tướng Quân"
var current_user_email: String = ""
var current_user_id: String = ""
var session_secret: String = ""
var session_cookie: String = ""
var is_logged_in: bool = false
var is_deleting_session: bool = false

# Player Profile & Progression (Synced with Appwrite /account/prefs)
var current_level: int = 1
var current_exp: int = 0
var current_silver: int = 25000
var current_gold: int = 1200
var current_generals: Array = ["ly_thuong_kiet"]
var current_2v2_points: int = 1200
var tutorial_reward_claimed: bool = false
var pending_exp_gain: Dictionary = {}

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

func get_auth_headers(include_session: bool = true) -> PackedStringArray:
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"X-Appwrite-Project: " + PROJECT_ID
	])
	if include_session:
		if session_secret != "":
			headers.append("X-Appwrite-Session: " + session_secret)
		if session_cookie != "":
			headers.append("Cookie: " + session_cookie)
	return headers

# --- Level Progression Formulas ---
# Kinh nghiệm để lên level là: lên level X cần X*10 kinh nghiệm.
# Lên cấp 2: cần 2*10 = 20 Exp. Lên cấp 3: cần 3*10 = 30 Exp.
func get_exp_required_for_level(lvl: int) -> int:
	return lvl * 10

func get_exp_to_next_level() -> int:
	return (current_level + 1) * 10

func add_exp(amount: int) -> Dictionary:
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
# Exp Quân hàm: Cứ 1 tướng sở hữu +50.
func get_military_points() -> int:
	if current_generals.is_empty():
		current_generals = ["ly_thuong_kiet"]
	return current_generals.size() * 50

func add_general(hero_id: String) -> void:
	if not current_generals.has(hero_id):
		current_generals.append(hero_id)
		save_session()
		save_profile_to_appwrite()
		profile_updated.emit()

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
# Lần đầu chơi tân thủ cho được 20Exp cho vừa tròn lên cấp 2. Tướng Lý Thường Kiệt +50 Exp quân hàm.
func claim_tutorial_reward(exp_amt: int = 20, silver_amt: int = 2000, gold_amt: int = 200) -> Dictionary:
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
					if data.has("level") and int(data["level"]) > 0:
						current_level = int(data["level"])
					if data.has("exp"):
						current_exp = int(data["exp"])
					if data.has("silver"):
						current_silver = int(data["silver"])
					if data.has("gold"):
						current_gold = int(data["gold"])
					if data.has("rank2v2Points"):
						current_2v2_points = int(data["rank2v2Points"])
					if data.has("tutorialRewardClaimed"):
						tutorial_reward_claimed = bool(data["tutorialRewardClaimed"])
					if data.has("generals"):
						var g_val = data["generals"]
						if g_val is String and g_val != "":
							current_generals = Array(g_val.split(","))
						elif g_val is Array:
							current_generals = g_val
					if current_generals.is_empty():
						current_generals = ["ly_thuong_kiet"]

					save_session()
					profile_updated.emit()
					print("[AuthManager] Đồng bộ Appwrite thành công! Level: %d, Exp: %d, Tướng: %d (Quân hàm: %dđ)" % [
						current_level, current_exp, current_generals.size(), get_military_points()
					])
		if on_completed.is_valid():
			on_completed.call()
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func save_profile_to_appwrite(on_completed: Callable = Callable()) -> void:
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
			"militaryPoints": get_military_points(),
			"rank2v2Points": current_2v2_points,
			"generals": ",".join(current_generals),
			"tutorialRewardClaimed": tutorial_reward_claimed,
			"onboardingComplete": true
		}
	})

	http.request_completed.connect(func(result, response_code, resp_headers, resp_body):
		http.queue_free()
		if response_code == 200:
			print("[AuthManager] Đã lưu thông tin Profile lên Appwrite thành công!")
		else:
			print("[AuthManager] Lưu Profile Appwrite kết quả mã: ", response_code)
		if on_completed.is_valid():
			on_completed.call()
	)

	http.request(url, headers, HTTPClient.METHOD_PATCH, body)

# --- Authentication Logic ---
func login_email(email: String, password: String) -> void:
	email = email.strip_edges()
	if email == "" or password == "":
		login_failed.emit("Vui lòng nhập đầy đủ Email và Mật thư.")
		return

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
		session_secret = ""
		session_cookie = ""
		is_logged_in = false
		save_session()
		print("[AuthManager] Đã giải phóng phiên cũ thành công!")
		if on_completed.is_valid():
			on_completed.call()
	)

	var err = http.request(url, headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		http.queue_free()
		is_deleting_session = false
		session_secret = ""
		session_cookie = ""
		if on_completed.is_valid():
			on_completed.call()

func register_email(email: String, password: String, name: String) -> void:
	email = email.strip_edges()
	name = name.strip_edges()
	if name == "": name = "Đại Tướng Quân"

	if email == "" or password.length() < 8:
		login_failed.emit("Email hợp lệ và Mật thư tối thiểu 8 ký tự.")
		return

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
				login_email(email, password)
			else:
				var err_msg = _parse_error_msg(resp_body)
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
			current_user_id = data.get("userId", "")
			session_secret = data.get("secret", "")
			current_user_email = fallback_email
			is_logged_in = true

			for h in headers:
				if h.to_lower().begins_with("set-cookie:"):
					var cookie_str = h.substr(11).strip_edges().split(";")[0]
					session_cookie = cookie_str

			save_session()
			fetch_account_info()
	else:
		var err_msg = _parse_error_msg(body)
		if ("session is active" in err_msg.to_lower() or "prohibited when a session is active" in err_msg.to_lower()) and original_password != "":
			print("[AuthManager] Phát hiện phiên cũ đang treo. Đang tự động giải phóng phiên và đăng nhập lại...")
			delete_current_session(func():
				await get_tree().create_timer(0.2).timeout
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
				save_session()

		# Tiếp tục đồng bộ Profile/Level từ Appwrite
		fetch_profile_from_appwrite(func():
			login_succeeded.emit({
				"name": current_user_name,
				"email": current_user_email,
				"userId": current_user_id,
				"level": current_level,
				"exp": current_exp,
				"silver": current_silver,
				"gold": current_gold
			})
		)
	)

	http.request(url, headers, HTTPClient.METHOD_GET)

func _parse_error_msg(body: PackedByteArray) -> String:
	var json = JSON.new()
	var raw = body.get_string_from_utf8()
	if json.parse(raw) == OK:
		var d = json.get_data()
		if d is Dictionary and d.has("message"):
			return d["message"]
	return "Không thể kết nối máy chủ xác thực hoặc thông tin không chính xác."

func save_session() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"name": current_user_name,
			"email": current_user_email,
			"userId": current_user_id,
			"secret": session_secret,
			"cookie": session_cookie,
			"level": current_level,
			"exp": current_exp,
			"silver": current_silver,
			"gold": current_gold,
			"generals": current_generals,
			"rank2v2Points": current_2v2_points,
			"tutorialRewardClaimed": tutorial_reward_claimed
		}
		file.store_string(JSON.stringify(data))

func should_show_onboarding() -> bool:
	if current_user_email == "": return false
	if tutorial_reward_claimed: return false
	var key = "onboarding_" + current_user_email
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.get_data()
				if data is Dictionary and data.get(key, 0) == 2:
					return false
	return true

func set_onboarding_done() -> void:
	if current_user_email == "": return
	var key = "onboarding_" + current_user_email
	var data = {}
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var d = json.get_data()
				if d is Dictionary:
					data = d
	data[key] = 2
	data["name"] = current_user_name
	data["email"] = current_user_email
	data["userId"] = current_user_id
	data["secret"] = session_secret
	data["cookie"] = session_cookie
	data["level"] = current_level
	data["exp"] = current_exp
	data["silver"] = current_silver
	data["gold"] = current_gold
	data["generals"] = current_generals
	data["tutorialRewardClaimed"] = tutorial_reward_claimed

	var wfile = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if wfile:
		wfile.store_string(JSON.stringify(data))

func load_saved_session() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
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
					current_level = int(data.get("level", 1))
					current_exp = int(data.get("exp", 0))
					current_silver = int(data.get("silver", 25000))
					current_gold = int(data.get("gold", 1200))
					current_generals = data.get("generals", ["ly_thuong_kiet"])
					if current_generals.is_empty():
						current_generals = ["ly_thuong_kiet"]
					current_2v2_points = int(data.get("rank2v2Points", 1200))
					tutorial_reward_claimed = bool(data.get("tutorialRewardClaimed", false))
					if session_secret != "":
						is_logged_in = true
