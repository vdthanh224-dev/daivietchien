extends Node

signal login_succeeded(user_data: Dictionary)
signal login_failed(error_message: String)

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

func login_email(email: String, password: String) -> void:
	email = email.strip_edges()
	if email == "" or password == "":
		login_failed.emit("Vui lòng nhập đầy đủ Email và Mật thư.")
		return

	var http = HTTPRequest.new()
	add_child(http)

	var url = ENDPOINT + "/account/sessions/email"
	var body = JSON.stringify({ "email": email, "password": password })
	# Khi tạo session mới, KHÔNG gửi session cũ kèm theo để tránh lỗi "session is active"
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

	# Hủy phiên cũ trước khi tạo tài khoản mới nếu có
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

			# Bắt cookie từ Header nếu có
			for h in headers:
				if h.to_lower().begins_with("set-cookie:"):
					var cookie_str = h.substr(11).strip_edges().split(";")[0]
					session_cookie = cookie_str

			save_session()
			fetch_account_info()
	else:
		var err_msg = _parse_error_msg(body)
		# Tự động khắc phục lỗi "session is active"
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

		# Báo thành công cho giao diện
		login_succeeded.emit({
			"name": current_user_name,
			"email": current_user_email,
			"userId": current_user_id
		})
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
			"cookie": session_cookie
		}
		file.store_string(JSON.stringify(data))

func should_show_onboarding() -> bool:
	if current_user_email == "": return false
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
	var data = {
		"name": current_user_name,
		"email": current_user_email,
		"userId": current_user_id,
		"secret": session_secret,
		"cookie": session_cookie
	}
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var d = json.get_data()
				if d is Dictionary:
					for k in d:
						data[k] = d[k]
	data[key] = 2
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
					if session_secret != "":
						is_logged_in = true
