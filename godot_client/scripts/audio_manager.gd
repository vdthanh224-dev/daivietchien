extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

var clips: Dictionary = {}
var voice_cache: Dictionary = {}

const SKILL_VOICE_KEYS := {
	"chế nỏ": "che_no",
	"cơ biến": "co_bien",
	"liên châu": "lien_chau",
	"xạ thuẫn": "xa_thuan",
	"phù trấn": "phu_tran",
	"hịch nghĩa": "hich_nghia",
	"uất khí": "uat_khi",
	"triều dâng": "trieu_dang",
	"lập làng": "lap_lang",
	"dũng nữ": "dung_nu",
	"thủ mục": "thu_muc",
	"trinh liệt": "trinh_liet",
	"bát nạ": "bat_na",
	"tiên phong": "tien_phong",
	"trận tiền": "tran_tien",
	"khởi binh": "khoi_binh",
	"huynh trưởng": "huynh_truong",
	"chiến tượng": "chien_tuong",
	"oai nhược": "oai_nhuoc",
	"dựng nước": "dung_nuoc",
	"xưng đế": "xung_de",
	"tùng nghĩa": "tung_nghia",
	"trung kiên": "trung_kien",
	"văn sách": "van_sach",
	"hán lâm": "han_lam",
	"trấn nam": "tran_nam",
	"hóa dân": "hoa_dan",
	"dạ trạch": "da_trach",
	"nỏ đỉnh": "no_dinh",
	"phục hổ": "phuc_ho",
	"an dân": "an_dan",
	"ẩn tích": "an_tich",
	"lực địch": "luc_dich",
	"hùng sức": "hung_suc"
}

const FEMALE_SKILL_VOICE_KEYS := {
	"triều dâng": true, "trieu_dang": true,
	"dũng nữ": true, "dung_nu": true,
	"trinh liệt": true, "trinh_liet": true,
	"tiên phong": true, "tien_phong": true,
	"chiến tượng": true, "chien_tuong": true,
	"bát nạ": true, "bat_na": true,
	"trao bào": true, "trao_bao": true,
	"nhiếp chính": true, "nhiep_chinh": true
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = -8.0
	add_child(bgm_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	sfx_player.volume_db = 0.0
	add_child(sfx_player)

	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Master"
	voice_player.volume_db = 2.0
	add_child(voice_player)

	_preload_audio()
	call_deferred("play_bgm", "bgm_battle")

func _preload_audio() -> void:
	var list = [
		"sfx_slash", "sfx_damage", "sfx_parry", "sfx_skill",
		"sfx_card_draw", "sfx_card_select", "sfx_victory", "bgm_battle",
		"sfx_exp_tick", "sfx_exp_fill", "sfx_levelup"
	]
	for name in list:
		var path = "res://assets/audio/%s.wav" % name
		if ResourceLoader.exists(path):
			var stream = load(path)
			if name == "bgm_battle" and stream is AudioStreamWAV:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			clips[name] = stream

func play_bgm(music_name: String = "bgm_battle") -> void:
	if clips.has(music_name) and bgm_player:
		if bgm_player.stream != clips[music_name] or not bgm_player.playing:
			bgm_player.stream = clips[music_name]
			bgm_player.play()

func stop_bgm() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()

func play_sfx(name: String, vol_db: float = 0.0) -> void:
	if clips.has(name) and sfx_player:
		var p = AudioStreamPlayer.new()
		p.stream = clips[name]
		p.volume_db = vol_db
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func play_slash() -> void:
	play_sfx("sfx_slash", 2.0)

func play_damage() -> void:
	play_sfx("sfx_damage", 1.0)

func play_hurt() -> void:
	play_damage()

func play_defeat() -> void:
	play_sfx("sfx_damage", 2.0)

func play_parry() -> void:
	play_sfx("sfx_parry", 2.0)

func play_skill() -> void:
	play_sfx("sfx_skill", 1.0)

func play_card_draw() -> void:
	play_sfx("sfx_card_draw", -2.0)

func play_card_select() -> void:
	play_sfx("sfx_card_select", -3.0)

func play_card_cancel() -> void:
	play_sfx("sfx_parry", 1.0)

func play_card_sound(card_name: String, is_female: bool = false) -> void:
	play_voice(card_name, is_female)

func play_victory() -> void:
	play_sfx("sfx_victory", 3.0)

func play_sfx_with_pitch(name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	if clips.has(name):
		var p = AudioStreamPlayer.new()
		p.stream = clips[name]
		p.pitch_scale = pitch
		p.volume_db = vol_db
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func play_exp_tick(pitch: float = 1.0, vol_db: float = 0.0) -> void:
	play_sfx_with_pitch("sfx_exp_tick", pitch, vol_db)

func play_exp_fill(vol_db: float = 0.0) -> void:
	play_sfx("sfx_exp_fill", vol_db)

func play_levelup(vol_db: float = 2.0) -> void:
	play_sfx("sfx_levelup", vol_db)

func play_voice(card_or_skill_name: String, is_female: bool = false) -> void:
	var key = _normalize_voice_key(card_or_skill_name)
	if key == "":
		return

	var raw_lower = card_or_skill_name.to_lower().strip_edges()
	var effective_female = is_female or FEMALE_SKILL_VOICE_KEYS.has(raw_lower) or FEMALE_SKILL_VOICE_KEYS.has(key)

	var female_key = key + "_female"
	var chosen_stream: AudioStream = null

	if effective_female:
		if not voice_cache.has(female_key):
			var female_path = "res://assets/audio/Voice/%s.wav" % female_key
			if not ResourceLoader.exists(female_path):
				female_path = "res://assets/audio/voice/%s.wav" % female_key
			if ResourceLoader.exists(female_path):
				voice_cache[female_key] = load(female_path)
			else:
				voice_cache[female_key] = null
		if voice_cache.get(female_key, null) != null:
			chosen_stream = voice_cache[female_key]

	if chosen_stream == null:
		if not voice_cache.has(key):
			var path = "res://assets/audio/Voice/%s.wav" % key
			if not ResourceLoader.exists(path):
				path = "res://assets/audio/voice/%s.wav" % key
			if ResourceLoader.exists(path):
				voice_cache[key] = load(path)
		if voice_cache.has(key):
			chosen_stream = voice_cache[key]

	if chosen_stream != null:
		var p = AudioStreamPlayer.new()
		p.stream = chosen_stream
		if effective_female and voice_cache.get(female_key, null) == null:
			# Female voice pitch shift (+4.2 semitones up for natural female voice tone)
			p.pitch_scale = 1.28
			p.volume_db = 2.8
		else:
			p.pitch_scale = 1.0
			p.volume_db = 2.0
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func play_voice_for_hero(card_or_skill_name: String, hero_identifier) -> void:
	var is_fem := false
	var hero_db = get_node_or_null("/root/HeroDatabase")
	if hero_db and hero_db.has_method("is_female_hero"):
		is_fem = hero_db.is_female_hero(hero_identifier)
	play_voice(card_or_skill_name, is_fem)

func has_voice(card_or_skill_name: String) -> bool:
	var key = _normalize_voice_key(card_or_skill_name)
	return not key.is_empty() and (ResourceLoader.exists("res://assets/audio/Voice/%s.wav" % key) or ResourceLoader.exists("res://assets/audio/voice/%s.wav" % key))

func _normalize_voice_key(raw_name: String) -> String:
	var n = raw_name.to_lower().strip_edges()
	if SKILL_VOICE_KEYS.has(n):
		return str(SKILL_VOICE_KEYS[n])
	if ("thủy" in n or "thuy" in n) and ("trảm" in n or "tram" in n): return "tram_thuy"
	elif "đại hồng thủy" in n or "dai hong thuy" in n: return "dai_hong_thuy"
	# Only the actual fire slash card uses the Trảm Hỏa voice. Equipment such as
	# Hỏa Mai Tây Sơn must not fall through to this generic substring match.
	elif ("hỏa" in n or "hoa" in n) and ("trảm" in n or "tram" in n): return "tram_hoa"
	elif ("lôi" in n or "loi" in n) and ("trảm" in n or "tram" in n): return "tram_loi"
	elif "trầm ảo" in n or "tram ao" in n or "sa bẫy" in n or "sa bay" in n: return "tram_ao_sa_bay"
	elif "trảm" in n or "tram" in n: return "tram"
	elif n == "đỡ" or n == "do": return "do"
	elif "bánh chưng" in n or "banh chung" in n: return "banh_chung"
	elif "rượu" in n or "ruou" in n: return "hu_ruou"
	elif "tiến thoái" in n or "tien thoai" in n: return "tien_thoai"
	elif "giáp đồng" in n or "giap dong" in n: return "giap_dong_son_vi"
	elif "khiên mây" in n or "khien may" in n: return "khien_may_ben"
	elif "áo bào" in n or "ao bao" in n: return "ao_bao_hoang_toc"
	elif "nỏ thần" in n or "no than" in n: return "no_than_kim_quy"
	elif "song cung" in n or "muong nha" in n: return "song_cung_muong_nha"
	elif "thuận thiên" in n or "thuan thien" in n: return "kiem_thuan_thien"
	elif "trường đao" in n or "truong dao" in n: return "truong_dao_nam_son"
	elif "thương ngâu" in n or "thuong ngau" in n or "lãng bạc" in n or "lang bac" in n: return "thuong_ngau_lang_bac"
	elif "súng thần công" in n or "sung than cong" in n or "hồ triều" in n or "ho trieu" in n: return "sung_than_cong_ho_trieu"
	elif "voi chiến" in n or "voi chien" in n: return "voi_chien_dai_viet"
	elif "ngựa trắng" in n or "ngua trang" in n: return "ngua_trang_thuan_nong"
	elif "diệu kế" in n or "dieu ke" in n: return "dieu_ke_pha_muu"
	elif "vô trung" in n or "dụng binh" in n or "dung binh" in n: return "dung_binh_nhu_than"
	elif "vườn không" in n or "vuon khong" in n or "rút ván" in n: return "vuon_khong_nha_trong"
	elif "đột kích" in n or "dot kich" in n or "trộm lương" in n or "dắt dê" in n: return "dot_kich_trom_luong"
	elif "xích tâm" in n or "xich tam" in n: return "xich_tam_toa"
	elif "huyết chiến" in n or "huyet chien" in n: return "huyet_chien"
	elif "quyết đấu" in n or "thách đấu" in n or "thach dau" in n: return "thach_dau"
	elif "mưa tên" in n or "vạn tiễn" in n or "mua ten" in n: return "mua_ten_lien_chau"
	elif "giặc tới" in n or "giac toi" in n: return "giac_toi"
	elif "bãi cọc bạch đằng" in n or "bai coc bach dang" in n: return "bai_coc_bach_dang"
	elif "cọc ngầm" in n or "coc ngam" in n: return "bai_coc_ngam"
	elif "mở kho" in n or "mo kho" in n: return "mo_kho_cuu_te"
	elif "thủy triều rút" in n or "thuy trieu rut" in n: return "thuy_trieu_rut"
	elif "mượn gươm" in n or "muon guom" in n: return "muon_guom_diet_dich"
	elif "mở yến tiệc" in n or "mo yen tiec" in n: return "mo_yen_tiec"
	elif "hịch tướng sĩ" in n or "hich tuong si" in n: return "hich_tuong_si"
	elif "trống đồng" in n or "trong dong" in n: return "trong_dong_dong_son"
	elif "cắt lương" in n or "cat luong" in n or "cắt đường" in n or "cat duong" in n: return "cat_duong_luong"
	return ""
