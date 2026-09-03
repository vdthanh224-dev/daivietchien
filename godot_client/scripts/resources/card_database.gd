class_name CardDatabase
extends RefCounted

const CardResourceScript = preload("res://scripts/resources/card_resource.gd")

static var _cards_cache: Dictionary = {}

static func get_card(id: String) -> Resource:
	if _cards_cache.has(id):
		return _cards_cache[id]
	return create_card_from_id(id)

static func create_card_from_dict(data: Dictionary) -> Resource:
	var c = CardResourceScript.new()
	c.id = data.get("id", "")
	c.card_name = data.get("name", data.get("cardName", "Lá Bài"))
	c.suit = data.get("suit", "Spade")
	c.rank = int(data.get("rank", 1))
	c.category = int(data.get("category", 0)) as CardResourceScript.CardCategory
	c.sub_type = int(data.get("subType", 0)) as CardResourceScript.CardSubType
	c.description = data.get("desc", data.get("description", ""))
	c.attack_range = int(data.get("range", data.get("attackRange", 1)))
	return c

static func create_card_from_id(id: String) -> Resource:
	var c = CardResourceScript.new()
	c.id = id
	c.card_name = "Thẻ Bài"
	c.suit = "Spade"
	c.rank = 1

	if id.contains("NoThan"):
		c.card_name = "Nỏ Thần Kim Quy"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.VU_KHI
		c.attack_range = 3
		c.description = "Tầm 3. Không giới hạn số Trảm trong lượt"
	elif id.contains("KhienMay"):
		c.card_name = "Khiên Mây Bện"
		c.category = CardResourceScript.CardCategory.TRANG_BI
		c.sub_type = CardResourceScript.CardSubType.AO_GIAP
		c.description = "Khi cần Đỡ, lật phán xét: chất Đỏ tự động Đỡ"
	elif id.contains("DieuKe"):
		c.card_name = "Diệu Kế Phá Mưu"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.DIEU_KE
		c.description = "Hóa giải 1 lá Cẩm Nang bất kỳ"
	elif id.contains("Banh"):
		c.card_name = "Bánh Chưng"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.BANH_CHUNG
		c.description = "Hồi 1 Máu cho bản thân hoặc cứu tướng Cận Tử"
	elif id.contains("Ruou"):
		c.card_name = "Hủ Rượu"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.HU_RUOU
		c.description = "Tăng +1 sát thương đòn Trảm kế tiếp hoặc tự cứu khi 0 máu"
	elif id.contains("Do"):
		c.card_name = "Đỡ"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.DO
		c.description = "Hóa giải 1 đòn Trảm"
	elif id.contains("Xich"):
		c.card_name = "Xích Tâm Tỏa"
		c.category = CardResourceScript.CardCategory.CAM_NANG
		c.sub_type = CardResourceScript.CardSubType.XICH_TAM_TOA
		c.description = "Khóa xích tối đa 2 tướng"
	else:
		c.card_name = "Trảm"
		c.category = CardResourceScript.CardCategory.CO_BAN
		c.sub_type = CardResourceScript.CardSubType.TRAM
		c.description = "Tấn công gây 1 sát thương"

	return c
