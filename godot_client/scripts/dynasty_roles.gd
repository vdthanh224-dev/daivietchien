extends RefCounted

const NAMES := {
	"KING": "VUA", "LOYALIST": "Trung Thần", "REBEL": "Phản Tặc", "SPY": "Nội Gián"
}
const COLORS := {
	"KING": Color("#ff4545"), "LOYALIST": Color("#ffdd33"),
	"REBEL": Color("#40e060"), "SPY": Color("#5599ff")
}
const FIVE_PLAYER_INSTRUCTIONS := {
	"KING": "Bạn là VUA, tiêu diệt hết 2 Phản Tặc và 1 Nội Gián để chiến thắng, đồng đội của bạn là 1 Trung Thần.",
	"LOYALIST": "Bạn là Trung Thần, nhiệm vụ của bạn là bảo vệ VUA và tiêu diệt những người chơi khác, có duy nhất 1 Trung Thần.",
	"REBEL": "Bạn là Phản Tặc, nhiệm vụ của bạn là tiêu diệt VUA để chiến thắng, đồng minh của VUA là 1 Trung Thần, có 2 Phản Tặc trong trận này.",
	"SPY": "Bạn là Nội Gián, nhiệm vụ của bạn là bảo vệ VUA và tiêu diệt hết tất cả những người chơi khác, sau đó tiêu diệt luôn VUA để chiến thắng, có duy nhất 1 Nội Gián."
}

static func display_name(role: String) -> String:
	return str(NAMES.get(role, "?"))

static func get_color(role_or_name: String) -> Color:
	var role = role_or_name if COLORS.has(role_or_name) else NAMES.find_key(role_or_name)
	return COLORS.get(role, Color.WHITE)

static func colorize(text: String) -> String:
	for role in NAMES:
		text = text.replace(NAMES[role], "[color=#%s]%s[/color]" % [COLORS[role].to_html(false), NAMES[role]])
	return text

static func five_player_instructions(role: String) -> String:
	return colorize(str(FIVE_PLAYER_INSTRUCTIONS.get(role, "Đang nhận vai trò từ máy chủ...")))

static func instructions(role: String, player_count: int) -> String:
	if player_count != 8:
		return five_player_instructions(role)
	var text := str(FIVE_PLAYER_INSTRUCTIONS.get(role, "Đang nhận vai trò từ máy chủ..."))
	text = text.replace("2 Phản Tặc", "4 Phản Tặc").replace("1 Trung Thần", "2 Trung Thần")
	text = text.replace("có duy nhất 2 Trung Thần", "có 2 Trung Thần")
	return colorize(text)
