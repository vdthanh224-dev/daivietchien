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
@export var icon_path: String = ""
@export var attack_range: int = 1

func get_artwork_path() -> String:
	if icon_path != "" and ResourceLoader.exists(icon_path):
		return icon_path

	var n = card_name.to_lower()
	if "hỏa" in n and "trảm" in n: return "res://assets/ui/cards/card_slash_fire.png"
	elif "lôi" in n and "trảm" in n: return "res://assets/ui/cards/card_slash_thunder.png"
	elif "trảm" in n: return "res://assets/ui/cards/card_slash.png"
	elif "đỡ" in n: return "res://assets/ui/cards/card_dodge.png"
	elif "bánh chưng" in n: return "res://assets/ui/cards/card_banh_chung.png"
	elif "rượu" in n: return "res://assets/ui/cards/card_wine.png"
	elif "khiên mây" in n: return "res://assets/ui/cards/card_armor_khien_may.png"
	elif "giáp đồng" in n: return "res://assets/ui/cards/card_armor_giap_dong.png"
	elif "áo bào" in n: return "res://assets/ui/cards/card_armor_ao_bao.png"
	elif "nỏ thần" in n: return "res://assets/ui/cards/card_weapon_no_than.png"
	elif "song cung" in n: return "res://assets/ui/cards/card_weapon_song_cung.png"
	elif "thuận thiên" in n: return "res://assets/ui/cards/card_weapon_thuan_thien.png"
	elif "trường đao" in n: return "res://assets/ui/cards/card_weapon_truong_dao.png"
	elif "voi chiến" in n: return "res://assets/ui/cards/card_mount_voi_chien.png"
	elif "ngựa trắng" in n: return "res://assets/ui/cards/card_mount_ngua_trang.png"
	elif "diệu kế" in n: return "res://assets/ui/cards/card_flawless.png"
	elif "xích" in n or "tỏa" in n: return "res://assets/ui/cards/card_iron_chain.png"
	elif "vạn tiễn" in n or "mưa tên" in n: return "res://assets/ui/cards/card_arrow_rain.png"
	elif "nam man" in n: return "res://assets/ui/cards/card_barbarian.png"
	elif "quyết đấu" in n or "thách đấu" in n: return "res://assets/ui/cards/card_duel.png"
	elif "mở kho" in n or "ngũ cốc" in n: return "res://assets/ui/cards/card_harvest.png"
	elif "súng thần công" in n: return "res://assets/ui/cards/card_weapon_no_than.png"
	elif "thương ngâu" in n: return "res://assets/ui/cards/card_weapon_thuan_thien.png"
	elif "vườn không" in n: return "res://assets/ui/cards/card_dismantle.png"
	elif "đột kích" in n: return "res://assets/ui/cards/card_snatch.png"
	elif "thần sấm" in n or "sấm sét" in n: return "res://assets/ui/cards/card_lightning.png"
	elif "dụng binh" in n or "vô trung" in n or "sinh hữu" in n: return "res://assets/ui/cards/card_ex_nihilo.png"
	elif "trầm ảo" in n or "lạc bất" in n: return "res://assets/ui/cards/card_acedia.png"
	elif "cắt lương" in n: return "res://assets/ui/cards/card_supply_shortage.png"

	return ""

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
	return s == "heart" or s == "diamond" or s == "co" or s == "ro"

func get_suit_color() -> Color:
	if is_red():
		return Color(0.92, 0.15, 0.15, 1.0) # Đỏ son rực rỡ
	else:
		return Color(0.12, 0.12, 0.14, 1.0) # Đen mực sắc nét

func get_category_name() -> String:
	match category:
		CardCategory.CO_BAN: return "Cơ Bản"
		CardCategory.TRANG_BI: return "Trang Bị"
		CardCategory.CAM_NANG: return "Cẩm Nang"
		CardCategory.TRI_HOAN: return "Phán Xét"
		_: return "Khác"
