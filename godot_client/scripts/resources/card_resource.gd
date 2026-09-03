class_name CardResource
extends Resource

enum CardCategory {
	CO_BAN = 0,
	TRANG_BI = 1,
	CAM_NANG = 2,
	TRI_HOAN = 3
}

enum CardSubType {
	TRAM = 0,
	TRAM_HOA = 1,
	TRAM_LOI = 2,
	DO = 3,
	BANH_CHUNG = 4,
	HU_RUOU = 5,
	VU_KHI = 6,
	AO_GIAP = 7,
	NGUA_CONG = 8,
	NGUA_THU = 9,
	DIEU_KE = 10,
	THIEN_HA_VO_SONG = 11,
	DOT_KICH = 12,
	DUNG_BINH = 13,
	THACH_DAU = 14,
	XICH_TAM_TOA = 15,
	MO_KHO_CUU_TE = 16,
	BAI_COC_NGAM = 17,
	MUA_TEN = 18,
	VUON_KHONG = 19,
	CAT_LUONG = 20,
	TRAM_AO = 21
}

@export var id: String = ""
@export var card_name: String = ""
@export var suit: String = "Heart" # Heart, Diamond, Spade, Club
@export var rank: int = 1 # 1 to 13
@export var category: CardCategory = CardCategory.CO_BAN
@export var sub_type: CardSubType = CardSubType.TRAM
@export var description: String = ""
@export var icon: Texture2D = null
@export var attack_range: int = 1

func get_suit_symbol() -> String:
	match suit.to_lower():
		"heart": return "♥"
		"diamond": return "♦"
		"spade": return "♠"
		"club": return "♣"
		_: return "?"

func get_rank_string() -> String:
	match rank:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(rank)

func is_red() -> bool:
	var s = suit.to_lower()
	return s == "heart" or s == "diamond"

func get_suit_color() -> Color:
	if is_red():
		return Color("#D32F2F") # Đỏ son
	else:
		return Color("#1C160C") # Đen mực

func get_category_name() -> String:
	match category:
		CardCategory.CO_BAN: return "Cơ Bản"
		CardCategory.TRANG_BI: return "Trang Bị"
		CardCategory.CAM_NANG: return "Cẩm Nang"
		CardCategory.TRI_HOAN: return "Phán Xét"
		_: return "Khác"
