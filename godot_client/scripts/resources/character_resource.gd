class_name CharacterResource
extends Resource

enum Faction {
	TRAN = 0,
	HAU_LE = 1,
	TAY_SON = 2,
	AU_LAC = 3,
	LY = 4,
	TIEN_LE = 5
}

@export var hero_id: String = ""
@export var hero_name: String = ""
@export var title: String = ""
@export var faction: Faction = Faction.TRAN
@export var max_hp: int = 4
@export var avatar: Texture2D = null
@export var skills: Array[Dictionary] = [] # [{ "name": "Kỹ năng", "desc": "...", "type": "Chủ động" }]

func get_faction_name() -> String:
	match faction:
		Faction.TRAN: return "Đại Việt - Nhà Trần"
		Faction.HAU_LE: return "Đại Việt - Hậu Lê"
		Faction.TAY_SON: return "Đại Việt - Tây Sơn"
		Faction.AU_LAC: return "Âu Lạc"
		Faction.LY: return "Đại Việt - Nhà Lý"
		Faction.TIEN_LE: return "Đại Việt - Tiền Lê"
		_: return "Đại Việt"

func get_faction_color() -> Color:
	match faction:
		Faction.TRAN: return Color("#D4AF37") # Vàng hoàng tộc
		Faction.HAU_LE: return Color("#3B82F6") # Xanh lam
		Faction.TAY_SON: return Color("#EF4444") # Đỏ hỏa
		Faction.AU_LAC: return Color("#10B981") # Ngọc bích
		_: return Color("#D4AF37")
