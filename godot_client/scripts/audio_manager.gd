extends Node

var bgm_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

var clips: Dictionary = {}
var voice_cache: Dictionary = {}

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

func _preload_audio() -> void:
	var list = [
		"sfx_slash", "sfx_damage", "sfx_parry", "sfx_skill",
		"sfx_card_draw", "sfx_card_select", "sfx_victory", "bgm_battle"
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

func play_parry() -> void:
	play_sfx("sfx_parry", 2.0)

func play_skill() -> void:
	play_sfx("sfx_skill", 1.0)

func play_card_draw() -> void:
	play_sfx("sfx_card_draw", -2.0)

func play_card_select() -> void:
	play_sfx("sfx_card_select", -3.0)

func play_victory() -> void:
	play_sfx("sfx_victory", 3.0)

func play_voice(card_or_skill_name: String) -> void:
	var key = _normalize_voice_key(card_or_skill_name)
	if key == "":
		return

	if not voice_cache.has(key):
		var path = "res://assets/audio/voice/%s.wav" % key
		if ResourceLoader.exists(path):
			voice_cache[key] = load(path)

	if voice_cache.has(key) and voice_cache[key] != null:
		var p = AudioStreamPlayer.new()
		p.stream = voice_cache[key]
		p.volume_db = 2.0
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)

func _normalize_voice_key(raw_name: String) -> String:
	var n = raw_name.to_lower()
	if "lôi" in n or "loi" in n: return "tram_loi"
	elif "hỏa" in n or "hoa" in n: return "tram_hoa"
	elif "trảm" in n or "tram" in n: return "tram"
	elif "đỡ" in n or "do" in n: return "do"
	elif "bánh chưng" in n or "banh chung" in n: return "banh_chung"
	elif "rượu" in n or "ruou" in n: return "hu_ruou"
	elif "tiến thoái" in n or "tien thoai" in n: return "tien_thoai"
	elif "khiên mây" in n or "khien may" in n: return "khien_may_ben"
	elif "áo bào" in n: return "ao_bao_hoang_toc"
	elif "nỏ thần" in n: return "no_than_kim_quy"
	elif "song cung" in n: return "song_cung_muong_nha"
	elif "thuận thiên" in n: return "kiem_thuan_thien"
	elif "trường đao" in n: return "truong_dao_nam_son"
	elif "voi chiến" in n: return "voi_chien_dai_viet"
	elif "ngựa trắng" in n: return "ngua_trang_thuan_nong"
	elif "diệu kế" in n: return "dieu_ke_pha_muu"
	elif "vô trung" in n or "dụng binh" in n: return "dung_binh_nhu_than"
	elif "vườn không" in n or "rút ván" in n: return "vuon_khong_nha_trong"
	elif "đột kích" in n or "dắt dê" in n: return "dot_kich_trom_luong"
	elif "quyết đấu" in n or "thách đấu" in n: return "thach_dau"
	elif "mưa tên" in n or "vạn tiễn" in n: return "mua_ten_lien_chau"
	elif "cọc ngầm" in n or "bãi cọc" in n: return "bai_coc_ngam"
	elif "mở kho" in n: return "mo_kho_cuu_te"
	elif "trầm ảo" in n: return "tram_ao_sa_bay"
	elif "cắt lương" in n: return "cat_duong_luong"
	elif "thần sấm" in n: return "than_sam_bao_ung"
	return ""
