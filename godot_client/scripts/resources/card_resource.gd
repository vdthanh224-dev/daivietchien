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
	TRAM_THUY = 2,
	DO = 3,
	BANH_CHUNG = 4,
	HU_RUOU = 5,
	VU_KHI = 6,
	AO_GIAP = 7,
	NGUA_CONG = 8,
	NGUA_THU = 9,
	DIEU_KE = 10,
	VUON_KHONG = 11,
	DOT_KICH = 12,
	DUNG_BINH = 13,
	HUYET_CHIEN = 14,
	THACH_DAU = 14,
	XICH_TAM_TOA = 15,
	MO_KHO_CUU_TE = 16,
	GIAC_TOI = 17,
	BAI_COC_NGAM = 17,
	MUA_TEN = 18,
	DAI_HONG_THUY = 19,
	CAT_LUONG = 20,
	TRAM_AO = 21,
	BAI_COC_BACH_DANG = 22,
	THUY_TRIEU_RUT = 23,
	MUON_GUOM_DIET_DICH = 24,
	MO_YEN_TIEC = 25,
	HICH_TUONG_SI = 26,
	BRONZE_DRUM = 27,
	KHO_NHUC_KE = 28,
	TAU_VI_THUONG_SACH = 29,
	PHU_DE_TRUU_TAN = 30
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

	# 1. Khớp ưu tiên theo tên lá bài (card_name) để đảm bảo hình ảnh luôn đúng chuẩn với tên hiển thị
	if "hỏa" in n and "trảm" in n: return "res://assets/ui/cards/card_slash_fire.png"
	elif ("thủy" in n or "thuy" in n) and ("trảm" in n or "tram" in n): return "res://assets/ui/cards/card_slash_water.png"
	elif "sấm" in n and "trảm" in n: return "res://assets/ui/cards/card_slash_thunder.png"
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
	elif "thương ngâu" in n: return "res://assets/ui/cards/card_weapon_thuong_ngau.png"
	elif "súng thần công" in n: return "res://assets/ui/cards/card_weapon_sung_than_cong.png"
	elif "voi chiến" in n: return "res://assets/ui/cards/card_mount_voi_chien.png"
	elif "ngựa trắng" in n: return "res://assets/ui/cards/card_mount_ngua_trang.png"
	elif "trống đồng" in n or "trong dong" in n or "bảo vật" in n: return "res://assets/ui/cards/card_treasure_trong_dong.png"
	elif "diệu kế" in n: return "res://assets/ui/cards/card_flawless.png"
	elif "xích" in n or "tỏa" in n: return "res://assets/ui/cards/card_iron_chain.png"
	elif "vạn tiễn" in n or "mưa tên" in n or "mua ten" in n: return "res://assets/ui/cards/card_arrow_rain.png"
	elif "giặc tới" in n or "giac toi" in n: return "res://assets/ui/cards/card_giac_toi.png"
	elif "bãi cọc bạch đằng" in n or "bai coc bach dang" in n: return "res://assets/ui/cards/card_bai_coc_bach_dang.png"
	elif "bãi cọc" in n or "bai coc" in n: return "res://assets/ui/cards/card_bai_coc_bach_dang.png"
	elif "quyết đấu" in n or "thách đấu" in n or "thach dau" in n or "huyết chiến" in n or "huyet chien" in n: return "res://assets/ui/cards/card_duel.png"
	elif "mở kho" in n or "ngũ cốc" in n or "mo kho" in n: return "res://assets/ui/cards/card_harvest.png"
	elif "thủy triều" in n or "thuy trieu" in n: return "res://assets/ui/cards/card_thuy_trieu_rut.png"
	elif "mượn gươm" in n or "muon guom" in n: return "res://assets/ui/cards/card_muon_guom.png"
	elif "mở yến tiệc" in n or "mo yen tiec" in n: return "res://assets/ui/cards/card_mo_yen_tiec.png"
	elif "hịch tướng sĩ" in n or "hich tuong si" in n: return "res://assets/ui/cards/card_hich_tuong_si.png"
	elif "khổ nhục" in n or "kho nhuc" in n: return "res://assets/ui/cards/card_ex_nihilo.png"
	elif "tẩu vi" in n or "tau vi" in n: return "res://assets/ui/cards/card_dismantle.png"
	elif "phủ để" in n or "phu de" in n: return "res://assets/ui/cards/card_dismantle.png"
	elif "vườn không" in n: return "res://assets/ui/cards/card_dismantle.png"
	elif "đột kích" in n: return "res://assets/ui/cards/card_snatch.png"
	elif "đại hồng thủy" in n or "dai hong thuy" in n or "thần sấm" in n or "sấm sét" in n: return "res://assets/ui/cards/card_dai_hong_thuy.png"
	elif "dụng binh" in n or "vô trung" in n or "sinh hữu" in n: return "res://assets/ui/cards/card_ex_nihilo.png"
	elif "trầm ảo" in n or "lạc bất" in n: return "res://assets/ui/cards/card_acedia.png"
	elif "cắt lương" in n or "cắt đường" in n or "cat luong" in n: return "res://assets/ui/cards/card_supply_shortage.png"

	# 2. Khớp theo sub_type nếu tên lá bài chưa nhận diện được
	match sub_type:
		CardSubType.TRAM: return "res://assets/ui/cards/card_slash.png"
		CardSubType.TRAM_HOA: return "res://assets/ui/cards/card_slash_fire.png"
		CardSubType.TRAM_THUY: return "res://assets/ui/cards/card_slash_water.png"
		CardSubType.DO: return "res://assets/ui/cards/card_dodge.png"
		CardSubType.BANH_CHUNG: return "res://assets/ui/cards/card_banh_chung.png"
		CardSubType.HU_RUOU: return "res://assets/ui/cards/card_wine.png"
		CardSubType.AO_GIAP:
			if "khiên mây" in n or "khien may" in n: return "res://assets/ui/cards/card_armor_khien_may.png"
			elif "áo bào" in n or "ao bao" in n: return "res://assets/ui/cards/card_armor_ao_bao.png"
			else: return "res://assets/ui/cards/card_armor_giap_dong.png"
		CardSubType.VU_KHI:
			if "song cung" in n: return "res://assets/ui/cards/card_weapon_song_cung.png"
			elif "nỏ thần" in n or "no than" in n: return "res://assets/ui/cards/card_weapon_no_than.png"
			elif "trường đao" in n or "truong dao" in n: return "res://assets/ui/cards/card_weapon_truong_dao.png"
			elif "thương ngâu" in n or "thuong ngau" in n: return "res://assets/ui/cards/card_weapon_thuong_ngau.png"
			elif "súng thần công" in n or "sung than cong" in n: return "res://assets/ui/cards/card_weapon_sung_than_cong.png"
			else: return "res://assets/ui/cards/card_weapon_thuan_thien.png"
		CardSubType.NGUA_CONG: return "res://assets/ui/cards/card_mount_ngua_trang.png"
		CardSubType.NGUA_THU: return "res://assets/ui/cards/card_mount_voi_chien.png"
		CardSubType.BRONZE_DRUM: return "res://assets/ui/cards/card_treasure_trong_dong.png"
		CardSubType.DIEU_KE: return "res://assets/ui/cards/card_flawless.png"
		CardSubType.VUON_KHONG: return "res://assets/ui/cards/card_dismantle.png"
		CardSubType.DOT_KICH: return "res://assets/ui/cards/card_snatch.png"
		CardSubType.DUNG_BINH: return "res://assets/ui/cards/card_ex_nihilo.png"
		CardSubType.HUYET_CHIEN: return "res://assets/ui/cards/card_duel.png"
		CardSubType.XICH_TAM_TOA: return "res://assets/ui/cards/card_iron_chain.png"
		CardSubType.MO_KHO_CUU_TE: return "res://assets/ui/cards/card_harvest.png"
		CardSubType.GIAC_TOI: return "res://assets/ui/cards/card_giac_toi.png"
		CardSubType.MUA_TEN: return "res://assets/ui/cards/card_arrow_rain.png"
		CardSubType.DAI_HONG_THUY: return "res://assets/ui/cards/card_dai_hong_thuy.png"
		CardSubType.CAT_LUONG: return "res://assets/ui/cards/card_supply_shortage.png"
		CardSubType.TRAM_AO: return "res://assets/ui/cards/card_acedia.png"
		CardSubType.BAI_COC_BACH_DANG: return "res://assets/ui/cards/card_bai_coc_bach_dang.png"
		CardSubType.THUY_TRIEU_RUT: return "res://assets/ui/cards/card_thuy_trieu_rut.png"
		CardSubType.MUON_GUOM_DIET_DICH: return "res://assets/ui/cards/card_muon_guom.png"
		CardSubType.MO_YEN_TIEC: return "res://assets/ui/cards/card_mo_yen_tiec.png"
		CardSubType.HICH_TUONG_SI: return "res://assets/ui/cards/card_hich_tuong_si.png"
		CardSubType.KHO_NHUC_KE: return "res://assets/ui/cards/card_ex_nihilo.png"
		CardSubType.TAU_VI_THUONG_SACH: return "res://assets/ui/cards/card_dismantle.png"
		CardSubType.PHU_DE_TRUU_TAN: return "res://assets/ui/cards/card_dismantle.png"

	return "res://assets/ui/cards/card_slash.png"

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
