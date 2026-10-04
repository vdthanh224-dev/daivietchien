extends Node

signal quests_updated()

# Hệ Thống Nhiệm Vụ Ngày - Quân Lệnh Triều Đình (Đại Việt Chiến)
# 7 Nhiệm vụ ngày quen thuộc + 5 Mốc Rương Năng Động (20, 40, 60, 80, 100)

const QUEST_DEFS: Dictionary = {
	"login": {
		"id": "login",
		"name": "Điểm danh đầu ngày",
		"desc": "Đăng nhập vào trò chơi.",
		"target": 1,
		"points": 10,
		"icon": "🌅",
		"nav_action": "none"
	},
	"battle": {
		"id": "battle",
		"name": "Xông pha trận mạc",
		"desc": "Tham gia 1 trận đấu bất kỳ (2v2 hoặc Luyện tập).",
		"target": 1,
		"points": 20,
		"icon": "⚔️",
		"nav_action": "battle"
	},
	"slash": {
		"id": "slash",
		"name": "Thanh gươm sắc bén",
		"desc": "Dùng thành công 3 lá [Trảm] (Thường, Hỏa hoặc Thủy).",
		"target": 3,
		"points": 20,
		"icon": "🗡️",
		"nav_action": "battle"
	},
	"dodge": {
		"id": "dodge",
		"name": "Kiên cường phòng ngự",
		"desc": "Đánh ra 2 lá [Đỡ] hoặc kích hoạt Khiên Mây Bện.",
		"target": 2,
		"points": 20,
		"icon": "🛡️",
		"nav_action": "battle"
	},
	"trick": {
		"id": "trick",
		"name": "Thi triển mưu kế",
		"desc": "Sử dụng 2 lá Bài Cẩm Nang bất kỳ.",
		"target": 2,
		"points": 20,
		"icon": "📜",
		"nav_action": "battle"
	},
	"heal": {
		"id": "heal",
		"name": "Nồi Bánh Chưng ấm",
		"desc": "Hồi phục 1 Máu bằng [Bánh Chưng] (tự dùng hoặc cứu đồng đội).",
		"target": 1,
		"points": 15,
		"icon": "🍲",
		"nav_action": "battle"
	},
	"win": {
		"id": "win",
		"name": "Khải hoàn thắng trận",
		"desc": "Giành chiến thắng 1 trận đấu bất kỳ.",
		"target": 1,
		"points": 25,
		"icon": "🏆",
		"nav_action": "battle"
	}
}

const MILESTONES: Array[Dictionary] = [
	{"points": 20, "silver": 50, "tickets": 0, "name": "Rương Tiền Đồn"},
	{"points": 40, "silver": 100, "tickets": 0, "name": "Rương Quân Nhu"},
	{"points": 60, "silver": 150, "tickets": 0, "name": "Rương Tướng Hiệu"},
	{"points": 80, "silver": 250, "tickets": 0, "name": "Rương Đô Đốc"},
	{"points": 100, "silver": 350, "tickets": 1, "name": "Đại Rương Khải Hoàn"}
]

func _ready() -> void:
	if AuthManager:
		if not AuthManager.profile_updated.is_connected(_on_profile_updated):
			AuthManager.profile_updated.connect(_on_profile_updated)
	call_deferred("ensure_today_quests")

func _on_profile_updated() -> void:
	ensure_today_quests()

func get_today_string() -> String:
	return Time.get_date_string_from_system()

func ensure_today_quests() -> void:
	if not AuthManager:
		return
	var data: Dictionary = AuthManager.daily_quests_data
	var today_str := get_today_string()
	var current_date: String = str(data.get("date", ""))
	
	if current_date != today_str or not data.has("quests") or not (data["quests"] is Dictionary):
		var new_quests := {}
		for q_id in QUEST_DEFS.keys():
			new_quests[q_id] = {
				"progress": 1 if q_id == "login" else 0,
				"claimed": false
			}
		data = {
			"date": today_str,
			"activity_points": 0,
			"claimed_milestones": [],
			"quests": new_quests
		}
		AuthManager.daily_quests_data = data
		AuthManager.save_session()
		AuthManager.save_profile_to_appwrite()
		quests_updated.emit()
	else:
		var quests_dict: Dictionary = data.get("quests", {})
		var changed := false
		if quests_dict.has("login"):
			var login_q: Dictionary = quests_dict["login"]
			if not login_q.get("claimed", false) and int(login_q.get("progress", 0)) < 1:
				login_q["progress"] = 1
				changed = true
		for q_id in QUEST_DEFS.keys():
			if not quests_dict.has(q_id):
				quests_dict[q_id] = {"progress": 1 if q_id == "login" else 0, "claimed": false}
				changed = true
		if changed:
			AuthManager.save_session()
			quests_updated.emit()

func get_activity_points() -> int:
	if not AuthManager:
		return 0
	return int(AuthManager.daily_quests_data.get("activity_points", 0))

func get_claimed_milestones() -> Array[int]:
	var result: Array[int] = []
	if not AuthManager or not (AuthManager.daily_quests_data is Dictionary):
		return result
	var arr = AuthManager.daily_quests_data.get("claimed_milestones", [])
	if arr is Array:
		for item in arr:
			var int_val := int(item)
			if int_val > 0 and not (int_val in result):
				result.append(int_val)
	AuthManager.daily_quests_data["claimed_milestones"] = result
	return result

func is_milestone_claimed(points: int) -> bool:
	var target_pts := int(points)
	for m in get_claimed_milestones():
		if int(m) == target_pts:
			return true
	return false

func record_progress(quest_id: String, amount: int = 1) -> void:
	if not QUEST_DEFS.has(quest_id) or not AuthManager:
		return
	ensure_today_quests()
	var data: Dictionary = AuthManager.daily_quests_data
	var quests_dict: Dictionary = data.get("quests", {})
	if not quests_dict.has(quest_id):
		return
	var q_state: Dictionary = quests_dict[quest_id]
	if q_state.get("claimed", false):
		return
	var target: int = int(QUEST_DEFS[quest_id]["target"])
	var current_p: int = int(q_state.get("progress", 0))
	var new_p: int = min(target, current_p + amount)
	if new_p != current_p:
		q_state["progress"] = new_p
		AuthManager.save_session()
		AuthManager.save_profile_to_appwrite()
		quests_updated.emit()

func claim_quest(quest_id: String) -> Dictionary:
	if not QUEST_DEFS.has(quest_id) or not AuthManager:
		return {"success": false, "error": "Nhiệm vụ không tồn tại"}
	ensure_today_quests()
	var data: Dictionary = AuthManager.daily_quests_data
	var quests_dict: Dictionary = data.get("quests", {})
	if not quests_dict.has(quest_id):
		return {"success": false, "error": "Chưa có tiến độ"}
	var q_state: Dictionary = quests_dict[quest_id]
	if q_state.get("claimed", false):
		return {"success": false, "error": "Đã nhận thưởng rồi"}
	var target: int = int(QUEST_DEFS[quest_id]["target"])
	var current_p: int = int(q_state.get("progress", 0))
	if current_p < target:
		return {"success": false, "error": "Chưa hoàn thành"}
	
	q_state["claimed"] = true
	var pts: int = int(QUEST_DEFS[quest_id]["points"])
	var current_pts: int = int(data.get("activity_points", 0))
	data["activity_points"] = min(130, current_pts + pts)
	AuthManager.save_session()
	AuthManager.save_profile_to_appwrite()
	quests_updated.emit()
	return {"success": true, "points": pts}

func claim_all_quests() -> Dictionary:
	ensure_today_quests()
	var total_pts_gained := 0
	var claimed_count := 0
	for q_id in QUEST_DEFS.keys():
		var res = claim_quest(q_id)
		if res.get("success", false):
			total_pts_gained += int(res.get("points", 0))
			claimed_count += 1
	return {"claimed_count": claimed_count, "points": total_pts_gained}

func claim_milestone(points: int) -> Dictionary:
	var target_pts := int(points)
	if not AuthManager:
		return {"success": false, "error": "Chưa đăng nhập"}
	ensure_today_quests()
	var milestone_info := {}
	for m in MILESTONES:
		if int(m["points"]) == target_pts:
			milestone_info = m
			break
	if milestone_info.is_empty():
		return {"success": false, "error": "Mốc rương không hợp lệ"}
	
	var data: Dictionary = AuthManager.daily_quests_data
	var current_pts: int = get_activity_points()
	if current_pts < target_pts:
		return {"success": false, "error": "Chưa đủ điểm năng động"}
	
	if is_milestone_claimed(target_pts):
		return {"success": false, "error": "Rương này đã mở rồi"}
	
	var claimed: Array[int] = get_claimed_milestones()
	claimed.append(target_pts)
	data["claimed_milestones"] = claimed
	
	var silver_gain: int = int(milestone_info.get("silver", 0))
	var ticket_gain: int = int(milestone_info.get("tickets", 0))
	
	if silver_gain > 0:
		AuthManager.current_silver += silver_gain
	if ticket_gain > 0:
		AuthManager.current_hero_tickets += ticket_gain
	
	AuthManager.save_session()
	AuthManager.save_profile_to_appwrite()
	AuthManager.profile_updated.emit()
	quests_updated.emit()
	
	return {
		"success": true,
		"silver": silver_gain,
		"tickets": ticket_gain,
		"name": milestone_info.get("name", "Rương Bổng Lộc")
	}

func claim_all_available() -> Dictionary:
	var quest_res = claim_all_quests()
	var total_silver := 0
	var total_tickets := 0
	var chests_opened := 0
	var cur_pts := get_activity_points()
	for m in MILESTONES:
		var p: int = int(m["points"])
		if cur_pts >= p and not is_milestone_claimed(p):
			var m_res = claim_milestone(p)
			if m_res.get("success", false):
				total_silver += int(m_res.get("silver", 0))
				total_tickets += int(m_res.get("tickets", 0))
				chests_opened += 1
	return {
		"quests_claimed": quest_res.get("claimed_count", 0),
		"points_gained": quest_res.get("points", 0),
		"chests_opened": chests_opened,
		"silver_gained": total_silver,
		"tickets_gained": total_tickets
	}

func get_quests_list() -> Array[Dictionary]:
	ensure_today_quests()
	var res: Array[Dictionary] = []
	var data: Dictionary = AuthManager.daily_quests_data if AuthManager else {}
	var q_dict: Dictionary = data.get("quests", {})
	for q_id in ["login", "battle", "slash", "dodge", "trick", "heal", "win"]:
		var def: Dictionary = QUEST_DEFS[q_id]
		var state: Dictionary = q_dict.get(q_id, {"progress": 0, "claimed": false})
		res.append({
			"id": q_id,
			"name": def["name"],
			"desc": def["desc"],
			"target": def["target"],
			"points": def["points"],
			"icon": def["icon"],
			"progress": state.get("progress", 0),
			"claimed": state.get("claimed", false)
		})
	return res

func has_unclaimed_rewards() -> bool:
	if not AuthManager:
		return false
	var data: Dictionary = AuthManager.daily_quests_data
	var quests_dict: Dictionary = data.get("quests", {})
	for q_id in QUEST_DEFS.keys():
		if quests_dict.has(q_id):
			var q = quests_dict[q_id]
			if not q.get("claimed", false) and int(q.get("progress", 0)) >= int(QUEST_DEFS[q_id]["target"]):
				return true
	var cur_pts: int = get_activity_points()
	for m in MILESTONES:
		var p: int = int(m["points"])
		if cur_pts >= p and not is_milestone_claimed(p):
			return true
	return false
