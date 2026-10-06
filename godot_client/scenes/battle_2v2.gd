extends Control

const CardUIScene = preload("res://scenes/components/card_ui.tscn")
const GeneralAvatarScene = preload("res://scenes/components/general_avatar_ui.tscn")
const AI_CARD_PLAY_DELAY: float = 1.5
const IRON_CHAIN_DESCRIPTION := "Chạm avatar để chọn tối đa 2 mục tiêu để đưa họ vào hoặc thoát trạng thái xích (cùng nhận sát thương nguyên tố), có thể đổi thành lá mới."
const HERO_SKILL_ACTIONS := {
	"LIEN_CHAU_TRIGGERED": {"name": "Liên Châu"},
	"PHU_TRAN_DRAW": {"name": "Phù Trấn"},
	"UAT_KHI_DRAW": {"name": "Uất Khí"},
	"UAT_KHI_TRIGGERED": {"name": "Uất Khí"},
	"TRIEU_DANG_DESTROY": {"name": "Triều Dâng"},
	"LAP_LANG_DRAW": {"name": "Lập Làng"},
	"THU_MUC_REDUCED": {"name": "Thủ Mục"},
	"TRINH_LIET_STEAL": {"name": "Trinh Liệt"},
	"BAT_NA_TRIGGERED": {"name": "Bát Nạ"},
	"TRAN_TIEN_DRAW": {"name": "Trận Tiền"},
	"KHOI_BINH_DRAW": {"name": "Khởi Binh"},
	"HUYNH_TRUONG_TRIGGERED": {"name": "Huynh Trưởng"},
	"OAI_NHUOC_DISCARD": {"name": "Oai Nhược"},
	"OAI_NHUOC_HP_LOSS": {"name": "Oai Nhược"},
	"DUNG_NUOC_TRIGGERED": {"name": "Dựng Nước"},
	"XUNG_DE_TRIGGERED": {"name": "Xưng Đế"},
	"TUNG_NGHIA_DRAW": {"name": "Tùng Nghĩa"},
	"TRUNG_KIEN_TRIGGERED": {"name": "Trung Kiên"},
	"VAN_SACH_TRIGGERED": {"name": "Văn Sách"},
	"HAN_LAM_KEEP": {"name": "Hán Lâm"},
	"HAN_LAM_BOTTOM": {"name": "Hán Lâm"},
	"TRAN_NAM_IMMUNE": {"name": "Trấn Nam"},
	"HOA_DAN_TRIGGERED": {"name": "Hóa Dân"},
	"DA_TRACH_TRIGGERED": {"name": "Dạ Trạch", "owner": "target"},
	"AN_DAN_TRIGGERED": {"name": "An Dân"},
	"HUNG_SUC_TRIGGERED": {"name": "Hùng Sức"},
	"VAN_AN_TRIGGERED": {"name": "Vạn An"},
	"DE_NGHIEP_DRAW": {"name": "Đế Nghiệp"},
	"KHOAN_GIAN_DRAW": {"name": "Khoan Giản"},
	"CHINH_THONG_GIVE": {"name": "Chính Thống"},
	"CHINH_THONG_REVEAL": {"name": "Chính Thống"},
	"KHOAN_HOA_DRAW": {"name": "Khoan Hòa"},
	"CAI_CACH_TRIGGERED": {"name": "Cải Cách"},
	"THIEN_CAM_CLEARED": {"name": "Thiên Cảm"},
	"THIEN_CAM_RECAST": {"name": "Thiên Cảm"},
	"THIEN_CAM_BLOCKED": {"name": "Thiên Cảm"},
	"NAM_TAN_DRAW": {"name": "Nam Tấn"},
	"CAT_CU_DRAW": {"name": "Cát Cứ"},
	"HOI_HO_REDUCED": {"name": "Hồi Hồ"},
	"TAY_PHU_TRIGGERED": {"name": "Tây Phu"},
	"NGHIA_TU_TRIGGERED": {"name": "Nghĩa Tử"},
	"UU_THIEP_STEAL": {"name": "Ưu Thiếp"},
	"CO_LAU_DRAW": {"name": "Cờ Lau"},
	"CO_LAU_DESTROY": {"name": "Cờ Lau"},
	"THU_PHUC_TRIGGERED": {"name": "Thu Phục"},
	"VAN_THANG_TRIGGERED": {"name": "Vạn Thắng"},
	"TRU_QUAN_TRIGGERED": {"name": "Trữ Quân"},
	"COT_KINH_TRIGGERED": {"name": "Cột Kinh"},
	"TRUNG_TIET_TRIGGERED": {"name": "Trung Tiết"},
	"CAN_VE_TRIGGERED": {"name": "Cận Vệ"},
	"DINH_QUOC_TRIGGERED": {"name": "Định Quốc"},
	"TAN_TRUNG_DRAW": {"name": "Tận Trung"},
	"BAO_LAM_DRAW": {"name": "Bao Lăm"},
	"TRAN_THU_TRIGGERED": {"name": "Trấn Thủ"},
	"PHA_TONG_TRIGGERED": {"name": "Phá Tống"},
	"THAN_CHINH_LE_HOAN_TRIGGERED": {"name": "Thân Chinh"},
	"TRAO_BAO_TRIGGERED": {"name": "Trao Bào"},
	"NHIEP_CHINH_TRIGGERED": {"name": "Nhiếp Chính"},
	"BAO_NO_DAMAGE": {"name": "Bạo Nộ"},
	"NGOA_TRIEU_BLOCKED": {"name": "Ngọa Triều"},
	"PHO_TA_TRIGGERED": {"name": "Phò Tá"},
	"MUU_DINH_TRIGGERED": {"name": "Mưu Định"},
	"DOI_DO_TRIGGERED": {"name": "Dời Đô"},
	"THAI_BINH_TRIGGERED": {"name": "Thái Bình"},
	"THAN_CHINH_BONUS_SLASH": {"name": "Thân Chinh"},
	"PHAT_CHAM_HEAL": {"name": "Phạt Chăm"}
}
const IMPLEMENTED_HERO_SKILL_NAMES := [
	"Chế Nỏ", "Liên Châu", "Xạ Thuẫn", "Phù Trấn", "Hịch Nghĩa", "Uất Khí",
	"Triều Dâng", "Lập Làng", "Dũng Nữ", "Thủ Mục", "Trinh Liệt", "Bát Nạ",
	"Tiên Phong", "Trận Tiền", "Khởi Binh", "Huynh Trưởng", "Chiến Tượng", "Oai Nhược",
	"Dựng Nước", "Xưng Đế", "Tùng Nghĩa", "Trung Kiên", "Văn Sách", "Hán Lâm",
	"Trấn Nam", "Hóa Dân", "Dạ Trạch", "Nỏ Đỉnh", "Phục Hổ", "An Dân", "Lực Địch", "Hùng Sức",
	"Vạn An", "Đế Nghiệp", "Khoan Giản", "Chính Thống", "Khoan Hòa", "Cải Cách", "Thiên Cảm", "Nam Tấn", "Bình Sạn", "Cát Cứ", "Cố Thủ", "Hồi Hồ", "Phòng Duyện", "Liệt Chiến", "Tây Phu", "Nghĩa Tử", "Dưỡng Binh",
	"Tế Giang", "Ưu Thiếp", "Cờ Lau", "Thu Phục", "Vạn Thắng", "Trữ Quân", "Cột Kinh", "Trung Tiết", "Cận Vệ",
	"Định Quốc", "Tận Trung", "Bao Lăm", "Trấn Thủ", "Phá Tống", "Thân Chinh", "Trao Bào", "Nhiếp Chính", "Bạo Nộ", "Ngọa Triều", "Phò Tá", "Mưu Định", "Dời Đô", "Thái Bình", "Phạt Chăm"
]

# UI Node References
@onready var table_top: Control = $TableTop
@onready var seat_bottom_right = $TableTop/Seats/SeatBottomRight/PlayerAvatar
@onready var seat_top_right = $TableTop/Seats/SeatTopRight/Enemy1Avatar
@onready var seat_top_left = $TableTop/Seats/SeatTopLeft/AllyAvatar
@onready var seat_mid_left = $TableTop/Seats/SeatMidLeft/Enemy2Avatar

@onready var hand_container: Control = $TableTop/HandCards
@onready var deck_label: Label = $TableTop/DeckHUD/DeckPlaque/DeckLabel
@onready var log_text: RichTextLabel = $TableTop/LogPanel/Margin/VBox/Scroll/LogText
@onready var log_panel: Control = $TableTop/LogPanel
@onready var deck_hud: Control = $TableTop/DeckHUD
@onready var desc_text: Label = $TableTop/CardDescBar/Margin/DescText
@onready var card_play_btn: Button = $TableTop/CardPlayBtn
@onready var end_turn_btn: Button = $TableTop/EndTurnBtn
@onready var hich_recast_btn: Button = $TableTop/HichRecastBtn
@onready var turn_indicator: Label = $TableTop/TurnInfoBar/TurnLabel

@onready var center_showcase: Control = $CenterArea/CardShowcase
@onready var showcase_card_slot: Control = $CenterArea/CardShowcase/CardSlot
@onready var showcase_label: Label = $CenterArea/CardShowcase/ActionBanner/ShowcaseName

@onready var bg_rect: TextureRect = $Background
@onready var embers_layer: Control = $EmbersLayer

@onready var dodge_modal: Control = $DodgeModal
@onready var dodge_title_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/Title
@onready var dodge_desc_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/Desc
@onready var dodge_timer_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/TimerLbl
@onready var dodge_confirm_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/DodgeBtn
@onready var dodge_pass_btn: Button = $DodgeModal/Dim/Box/Margin/VBox/HBox/PassBtn
@onready var dodge_card_selector_hbox: HBoxContainer = $DodgeModal/Dim/Box/Margin/VBox/CardSelectorScroll/CardSelectorHBox
@onready var dodge_card_selector_scroll: ScrollContainer = $DodgeModal/Dim/Box/Margin/VBox/CardSelectorScroll
@onready var dodge_selected_lbl: Label = $DodgeModal/Dim/Box/Margin/VBox/SelectedCardStatus
var dodge_khien_may_btn: Button = null

@onready var rescue_modal: Control = $RescueModal
@onready var rescue_desc_lbl: Label = $RescueModal/Dim/Box/Margin/VBox/Desc
@onready var rescue_timer_lbl: Label = $RescueModal/Dim/Box/Margin/VBox/TimerLbl
@onready var rescue_confirm_btn: Button = $RescueModal/Dim/Box/Margin/VBox/HBox/RescueBtn
@onready var rescue_pass_btn: Button = $RescueModal/Dim/Box/Margin/VBox/HBox/PassBtn
var rescue_card_selector_hbox: HBoxContainer = null
var rescue_card_selector_scroll: ScrollContainer = null

@onready var general_info_modal: Control = $GeneralInfoModal
@onready var info_close_x_btn: Button = $GeneralInfoModal.get_node_or_null("Dim/Box/Margin/VBox/HeaderHBox/CloseXBtn")
@onready var info_close_btn: Button = $GeneralInfoModal.get_node_or_null("Dim/Box/Margin/VBox/FooterHBox/CloseModalBtn")

@onready var victory_defeat_modal: Control = $VictoryDefeatModal
@onready var victory_title: Label = $VictoryDefeatModal/Dim/Box/Margin/VBox/Title
@onready var victory_desc: Label = $VictoryDefeatModal/Dim/Box/Margin/VBox/Desc
@onready var victory_return_btn: Button = $VictoryDefeatModal/Dim/Box/Margin/VBox/ReturnBtn

# Iron Chain Modal (Xích Tâm Tỏa đa mục tiêu)
@onready var iron_chain_modal: Control = $IronChainModal
@onready var iron_chain_grid: HBoxContainer = $IronChainModal/Dim/Box/Margin/VBox/GeneralsGrid
@onready var iron_chain_status_lbl: Label = $IronChainModal/Dim/Box/Margin/VBox/StatusLbl
@onready var iron_chain_confirm_btn: Button = $IronChainModal/Dim/Box/Margin/VBox/HBox/ConfirmBtn
@onready var iron_chain_cancel_btn: Button = $IronChainModal/Dim/Box/Margin/VBox/HBox/CancelBtn

# Card Pick Modal (Cướp / Phá Hủy bài mục tiêu)
@onready var card_pick_modal: Control = $CardPickModal
@onready var card_pick_title: Label = $CardPickModal/Dim/Box/Margin/VBox/Title
@onready var card_pick_desc: Label = $CardPickModal/Dim/Box/Margin/VBox/Desc
@onready var card_pick_options_hbox: HBoxContainer = $CardPickModal/Dim/Box/Margin/VBox/Scroll/OptionsHBox
@onready var card_pick_equipment_hbox: HBoxContainer = $CardPickModal/Dim/Box/Margin/VBox/EquipmentScroll/OptionsHBox
@onready var card_pick_status_lbl: Label = $CardPickModal/Dim/Box/Margin/VBox/SelectedStatusLbl
@onready var card_pick_confirm_btn: Button = $CardPickModal/Dim/Box/Margin/VBox/HBox/ConfirmBtn
@onready var card_pick_cancel_btn: Button = $CardPickModal/Dim/Box/Margin/VBox/HBox/CancelBtn

# Battle State
var my_seat: int = 1
var my_team_is_dragon: bool = true
var current_turn_seat: int = 1
var battle_seat_count: int = 4
var battle_seat_nodes: Dictionary = {}

func _build_battle_seat_avatar_map(seat_count: int) -> Dictionary:
	var map: Dictionary = {}
	var base_nodes: Array = [seat_bottom_right, seat_top_right, seat_top_left, seat_mid_left]
	var seats_root: Control = $TableTop/Seats
	var center := Vector2(640.0, 355.0)
	var radius := Vector2(470.0, 220.0)
	# Place seats from the local player toward the right, then continue around
	# the table counter-clockwise; after the last seat, wrap back to seat 1.
	var other_seat_order: Array[int] = []
	for offset in range(1, seat_count):
		other_seat_order.append(((my_seat - 1 + offset) % seat_count) + 1)
	for old_node in seats_root.get_children():
		if old_node is Control and old_node.has_meta("dynamic_battle_seat"):
			old_node.queue_free()
	battle_seat_nodes.clear()
	for offset in range(seat_count):
		var avatar = base_nodes[offset] if offset < base_nodes.size() else null
		var holder: Control = avatar.get_parent() if avatar and is_instance_valid(avatar) else null
		if holder == null:
			holder = Control.new()
			holder.name = "DynastySeat%d" % (offset + 1)
			holder.set_meta("dynamic_battle_seat", true)
			holder.custom_minimum_size = Vector2(170, 230)
			seats_root.add_child(holder)
			avatar = GeneralAvatarScene.instantiate()
			holder.add_child(avatar)
		avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# The local player keeps the existing lower-right 2v2 position. Other seats
		# use the open upper and side arc so the lower area remains exclusively ours.
		if offset == 0:
			var player_seat := ((my_seat - 1 + offset) % seat_count) + 1
			map[player_seat] = avatar
			battle_seat_nodes[player_seat] = avatar
			continue
		var other_index := offset - 1
		var other_count := seat_count - 1
		# The first other seat is on the right. Decreasing screen-space angles
		# continue counter-clockwise toward the left side.
		var angle := -0.35 - 2.50 * float(other_index) / float(maxi(1, other_count - 1))
		holder.set_anchors_preset(Control.PRESET_TOP_LEFT)
		holder.position = center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y) - Vector2(85, 115)
		holder.size = Vector2(170, 230)
		var seat_number := other_seat_order[other_index]
		map[seat_number] = avatar
		battle_seat_nodes[seat_number] = avatar
	return map
var current_turn_timer: float = 40.0
var current_server_phase: String = "PLAY"
var is_player_turn: bool = false
var slashes_used_this_turn: int = 0
var is_wine_buff_active: bool = false
var wine_used_this_turn: bool = false
var deck_count: int = 80
var selected_card_ui: Control = null
var selected_target_seat: int = -1
var uat_khi_pending: bool = false
var uat_khi_target_seat: int = -1
var uat_khi_submission_pending: bool = false
var is_targeting_trieu_dang: bool = false
var is_targeting_bat_na: bool = false
var is_targeting_van_sach: bool = false
var is_targeting_hung_suc: bool = false
var is_targeting_van_an: bool = false
var local_van_an_uses: int = 0
var is_targeting_dan_cau: bool = false
var is_targeting_thuy_chien: bool = false
var is_targeting_nghich_y: bool = false
var selected_nghich_y_card_id: String = ""
var is_targeting_thien_cam: bool = false
var dan_cau_forced_target_seat: int = -1
var is_targeting_cai_cach: bool = false
var is_targeting_binh_san: bool = false
var is_targeting_tay_phu: bool = false
var selected_two_card_skill_nodes: Array[Control] = []
var is_targeting_chinh_thong: bool = false
var is_targeting_khoan_hoa: bool = false
var hung_suc_submission_pending: bool = false
var huynh_truong_pending: bool = false
var local_turn_dealt_damage: bool = false
var lap_lang_triggered_this_turn: bool = false
var is_targeting_drum_skill: bool = false
var is_targeting_ho_phu_skill: bool = false
var borrow_sword_owner_seat: int = -1
var borrow_sword_target_seat: int = -1
var is_game_over: bool = false
var exit_battle_btn: Button = null
var match_result_recorded: bool = false

# Multi-target Chain State
var selected_chain_seats: Array = []
var lien_chau_target_seat: int = -1
var lien_chau_cost_card: Control = null
var is_selecting_lien_chau_target: bool = false
var lien_chau_prompt_decided: bool = false
var lien_chau_prompt: ConfirmationDialog = null

# Card Pick (Steal / Destroy) State
var card_pick_is_steal: bool = false
var card_pick_target_seat: int = -1
var selected_card_pick_option: Dictionary = {}
var card_pick_source_card_id: String = ""
var card_pick_source_card_name: String = ""
var card_pick_effect_type: String = ""

# Remote Player State (Real Human Player on other machine)
var is_remote_turn_active: bool = false
var remote_turn_timer: float = 40.0
var remote_poll_timer: float = 0.0
var is_network_mode: bool = false
var pending_discard_card_ids: Array = []
var reaction_submission_pending: bool = false
var reaction_submission_version: int = -1
var last_server_version: int = -1
var last_played_card_info: Dictionary = {}
var pending_damage_elements: Dictionary = {}
var bai_coc_judgement_visual_until_msec: int = 0
const BAI_COC_JUDGEMENT_VISUAL_MSEC := 4300
const BAI_COC_JUDGEMENT_DEDUPE_MSEC := 8000
var last_bai_coc_judgement_signature: String = ""
var last_bai_coc_judgement_at_msec: int = -BAI_COC_JUDGEMENT_DEDUPE_MSEC
var pending_bai_coc_state: Dictionary = {}
var bai_coc_state_sync_until_msec: int = 0
var hand_sync_recovery_sent: bool = false

# Card showcase, history, and draw/discard VFX
var showcase_center: CenterContainer = null
var showcase_row: HBoxContainer = null
var showcase_entries: Array = []
var card_fx_layer: Control = null
var last_slash_card_ray_origin: Vector2 = Vector2.ZERO
var last_slash_card_ray_time: int = 0
var history_button: Button = null
var history_popup: Control = null
var history_view: RichTextLabel = null
var history_entries: Array[String] = []
var history_list: VBoxContainer = null
var history_scroll: ScrollContainer = null
var history_count_label: Label = null

# Waiting for Dodge reaction
signal custom_reaction_finished(accepted: bool)
signal song_cung_response_finished(accepted: bool)
signal harvest_card_chosen(card_id: String)
signal thuy_trieu_rut_give_finished
var custom_reaction_callback: Callable = Callable()
var song_cung_local_callback: Callable = Callable()
var last_custom_reaction_card_info: Dictionary = {}
var is_waiting_dodge: bool = false
var is_waiting_oai_nhuoc: bool = false
var is_waiting_nghia_tu: bool = false
var selected_oai_nhuoc_card_nodes: Array = []
var is_waiting_song_cung: bool = false
var song_cung_target_seat: int = 0
var song_cung_pending_damage: int = 1
var song_cung_pending_element: String = "NORMAL"
var selected_song_cung_card_nodes: Array = []
var is_waiting_thuy_trieu_rut_give: bool = false
var thuy_trieu_rut_give_sent: bool = false
var thuy_trieu_rut_giver_seat: int = 0
var thuy_trieu_rut_receiver_seat: int = 0
var thuy_trieu_rut_given_card_info: Dictionary = {}
var dodge_attacker_seat: int = -1
var is_current_reaction_slash: bool = true
var dodge_time_left: float = 40.0
var incoming_slash_damage: int = 1
var incoming_slash_element: String = "NORMAL"
var selected_dodge_card_ui: Control = null
var current_reaction_pass_text: String = ""
var current_reaction_confirm_prefix: String = ""
var current_reaction_required_type: String = "Đỡ"
var current_reaction_allow_dodge_as_slash: bool = false
var is_giac_toi_reaction: bool = false
var current_waiting_seat: int = 0
var current_waiting_timer: float = 0.0

# Waiting for Rescue (Bánh Chưng / Hủ Rượu)
var is_waiting_rescue: bool = false
var rescue_victim_seat: int = -1
var rescue_time_left: float = 40.0
var rescue_card_to_use: Control = null
var near_death_victim_seat: int = -1
var near_death_asker_queue: Array = []
var harvest_modal: Control = null
var harvest_cards_box: HBoxContainer = null
var harvest_status_lbl: Label = null
var harvest_timer_lbl: Label = null
var harvest_confirm_btn: Button = null
var selected_harvest_card_ui: Control = null
var selected_harvest_card_id: String = ""
var harvest_modal_local: bool = false
var harvest_choice_sent: bool = false
var harvest_modal_signature: String = ""
var harvest_waiting_seat: int = 0
var harvest_picked_card_ids: Array[String] = []

# Drum Reveal Modal (Trống Đồng Đông Sơn - Điểm Trống xem toàn bộ bài trên tay)
var drum_reveal_modal: Control = null
var drum_reveal_cards_box: HBoxContainer = null
var drum_reveal_title_lbl: Label = null
var drum_reveal_desc_lbl: Label = null
var drum_reveal_status_lbl: Label = null
var drum_reveal_close_btn: Button = null
var drum_reveal_dismissed: bool = false

# Discard Phase State (Bỏ bài thừa)
var is_discard_phase: bool = false
var cards_to_discard_count: int = 0
var selected_discard_nodes: Array = []
var discard_submission_pending: bool = false
var recent_heal_seats: Dictionary = {}
var last_processed_network_action_sig: String = ""
var last_processed_history_seq: int = -1

# Dynamic Background & Embers
var ember_particles: Array = []
var bg_anim_timer: float = 0.0

# General Info Table (Key: seatNumber 1..4)
var generals_data: Dictionary = {}

# 52-card standard deck pile
var card_deck_pile: Array = []
var hand_layout_refresh_timer: float = 0.0

func _show_no_server_modal(message: String = "") -> void:
	print("[Battle 2v2] ❌ Không có kết nối WebSocket Deno Server! Dừng trận đấu.")
	is_game_over = true
	var dim = ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.z_as_relative = false
	dim.z_index = 320
	dim.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 240)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.98)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.35, 0.35, 0.9)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "⚠️ MẤT KẾT NỐI MÁY CHỦ TRẬN ĐẤU"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = message if message != "" else "Không thể kết nối Máy Chủ Trận Đấu (Deno Cloud hoặc Local 8080).\nTrận đấu đã bị dừng do không có máy chủ điều phối."
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	vbox.add_child(desc_lbl)

	var btn = Button.new()
	btn.text = "↩️ QUAY VỀ SẢNH CHÍNH"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.size_flags_horizontal = SIZE_SHRINK_CENTER
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.25, 0.35, 1.0)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.pressed.connect(func():
		if NetworkClient:
			NetworkClient.room_id = ""
		get_tree().change_scene_to_file("res://scenes/home.tscn")
	)
	vbox.add_child(btn)

func _ready() -> void:
	randomize()
	AudioManager.play_bgm("bgm_battle")
	_setup_history_ui()
	for overlay in [dodge_modal, rescue_modal, general_info_modal, victory_defeat_modal, iron_chain_modal, card_pick_modal]:
		overlay.z_as_relative = false
		overlay.z_index = 320
	# The reaction panels deliberately leave the hand area uncovered so cards stay selectable.
	dodge_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rescue_modal.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect buttons
	card_play_btn.pressed.connect(_on_card_play_btn_clicked)
	end_turn_btn.pressed.connect(_on_end_turn_btn_clicked)
	hich_recast_btn.pressed.connect(_on_hich_recast_btn_clicked)
	dodge_confirm_btn.pressed.connect(_on_dodge_confirmed)
	dodge_pass_btn.pressed.connect(_on_dodge_passed)

	# Nút bấm Khiên Mây Bện phán xét trong Dodge Modal (chỉ hiển thị khi có trang bị)
	var dodge_btn_hbox = dodge_confirm_btn.get_parent()
	if dodge_btn_hbox:
		dodge_khien_may_btn = Button.new()
		dodge_khien_may_btn.custom_minimum_size = Vector2(210, 38)
		dodge_khien_may_btn.focus_mode = Control.FOCUS_NONE
		dodge_khien_may_btn.text = "🎲 LẬT KHIÊN MÂY (ĐỎ = ĐỠ)"
		dodge_khien_may_btn.add_theme_font_size_override("font_size", 11)

		var km_style = StyleBoxFlat.new()
		km_style.bg_color = Color(0.12, 0.22, 0.35, 0.95)
		km_style.border_width_left = 2
		km_style.border_width_top = 2
		km_style.border_width_right = 2
		km_style.border_width_bottom = 2
		km_style.border_color = Color(0.35, 0.75, 1.0, 0.9)
		km_style.corner_radius_top_left = 6
		km_style.corner_radius_top_right = 6
		km_style.corner_radius_bottom_right = 6
		km_style.corner_radius_bottom_left = 6
		dodge_khien_may_btn.add_theme_stylebox_override("normal", km_style)
		dodge_khien_may_btn.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0, 1.0))

		dodge_btn_hbox.add_child(dodge_khien_may_btn)
		dodge_btn_hbox.move_child(dodge_khien_may_btn, 0)
		dodge_khien_may_btn.pressed.connect(_on_dodge_khien_may_clicked)
		dodge_khien_may_btn.visible = false

	rescue_confirm_btn.pressed.connect(_on_rescue_confirmed)
	rescue_pass_btn.pressed.connect(_on_rescue_passed)
	if is_instance_valid(info_close_x_btn):
		info_close_x_btn.pressed.connect(_hide_general_info_modal)
	if is_instance_valid(info_close_btn):
		info_close_btn.pressed.connect(_hide_general_info_modal)
	victory_return_btn.pressed.connect(_on_return_home_clicked)
	iron_chain_confirm_btn.pressed.connect(_on_iron_chain_confirmed)
	iron_chain_cancel_btn.pressed.connect(_hide_iron_chain_modal)
	card_pick_confirm_btn.pressed.connect(_on_card_pick_confirmed)
	card_pick_cancel_btn.pressed.connect(_hide_card_pick_modal)
	_setup_lien_chau_prompt()

	dodge_modal.visible = false
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	rescue_modal.visible = false
	general_info_modal.visible = false
	victory_defeat_modal.visible = false
	iron_chain_modal.visible = false
	card_pick_modal.visible = false
	center_showcase.visible = false
	card_play_btn.visible = false
	hich_recast_btn.visible = false
	end_turn_btn.visible = false
	if has_node("TableTop/TurnInfoBar"):
		get_node("TableTop/TurnInfoBar").visible = false

	_start_ambient_effects()
	_init_deck()
	_init_generals_from_draft()

	# Handle headless screenshot test
	var cmd_args = OS.get_cmdline_user_args()
	if cmd_args.is_empty():
		cmd_args = OS.get_cmdline_args()

	var is_screenshot_test = false
	for a in cmd_args:
		if a.begins_with("--screenshot"):
			is_screenshot_test = true
			break

	# Kết nối WebSocket Realtime Local Server
	if NetworkClient and not is_screenshot_test:
		if not NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.connect(_on_network_action_received)
		if not NetworkClient.connection_established.is_connected(_on_network_connected):
			NetworkClient.connection_established.connect(_on_network_connected)
		if not NetworkClient.player_joined.is_connected(_on_network_player_joined):
			NetworkClient.player_joined.connect(_on_network_player_joined)
		if not NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.connect(_on_network_game_state_updated)
		if not NetworkClient.error_received.is_connected(_on_network_error_received):
			NetworkClient.error_received.connect(_on_network_error_received)
		if NetworkClient.is_connected_to_server:
			is_network_mode = true
			_on_network_connected()
		elif NetworkClient.has_method("is_connecting") and NetworkClient.is_connecting():
			# Chờ tối đa 1.5s nếu NetworkClient đang trong tiến trình dò quét ưu tiên Deno / Local
			var wait_t = 0.0
			while wait_t < 1.5 and NetworkClient.is_connecting() and not NetworkClient.is_connected_to_server:
				await get_tree().create_timer(0.1).timeout
				wait_t += 0.1
			if NetworkClient.is_connected_to_server:
				is_network_mode = true
				_on_network_connected()

	_add_log("⚔️ Đấu Trường Đại Việt: vai trò Vương Triều được giữ bí mật.")
	_add_log("📜 Thứ tự ra bài bắt đầu từ Quân Vương rồi lần lượt theo ghế.")

	if not is_network_mode and not is_screenshot_test:
		_add_log("⚔️ Chế độ Đấu Trường Cục Bộ (Local vs AI).")
		_deal_initial_hands()
		_start_turn(1)
	if "--screenshot-delayed-tricks" in cmd_args:
		# Chờ đồng bộ mạng ổn định
		await get_tree().create_timer(0.8).timeout
		# Gắn Cắt Đường Lương lên Ghế 2, Trầm Ảo Sa Bẫy lên Ghế 3, và Đại Hồng Thủy lên Ghế 1
		if generals_data.has(1):
			var p1 = generals_data[1]
			p1["has_dai_hong_thuy"] = true
			p1["has_lightning"] = true # Legacy snapshot compatibility.
			p1["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
		if generals_data.has(2):
			var p2 = generals_data[2]
			p2["has_cat_luong"] = true
			p2["avatar_node"].set_delayed_trick("cat_luong", true)
		if generals_data.has(3):
			var p3 = generals_data[3]
			p3["has_tram_ao"] = true
			p3["avatar_node"].set_delayed_trick("tram_ao", true)
		if generals_data.has(4):
			var p4 = generals_data[4]
			p4["has_cat_luong"] = true
			p4["has_tram_ao"] = true
			p4["avatar_node"].set_delayed_trick("cat_luong", true)
			p4["avatar_node"].set_delayed_trick("tram_ao", true)

		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_delayed_tricks_screenshot.png")
		get_tree().quit()

	if "--screenshot-bai-coc" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().create_timer(0.3).timeout
		if generals_data.has(1):
			var p1 = generals_data[1]
			p1["has_bai_coc"] = true
			p1["avatar_node"].set_delayed_trick("bai_coc", true)
		var test_judge_card = {"id": "D80_TH_S9_BaiCocBachDang", "name": "Bãi Cọc Bạch Đằng", "suit": "Spade", "rank": 9}
		_show_judgement_result(false, "Bãi Cọc Bạch Đằng", test_judge_card)
		await get_tree().create_timer(0.85).timeout
		_save_viewport_screenshot("res://battle_2v2_bai_coc_screenshot.png")
		_stop_test_audio()
		var bai_coc_test_root = get_node_or_null("JudgementRevealRoot")
		if bai_coc_test_root and is_instance_valid(bai_coc_test_root):
			bai_coc_test_root.queue_free()
		await get_tree().process_frame
		get_tree().quit()

	if "--screenshot-bai-coc-safe" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().create_timer(0.3).timeout
		if generals_data.has(1):
			var p1 = generals_data[1]
			p1["has_bai_coc"] = true
			p1["avatar_node"].set_delayed_trick("bai_coc", true)
		var test_judge_card = {"id": "D80_CB_H8_BanhChung", "name": "Bánh Chưng", "suit": "Heart", "rank": 8}
		_show_judgement_result(true, "Bãi Cọc Bạch Đằng", test_judge_card)
		await get_tree().create_timer(0.85).timeout
		_save_viewport_screenshot("res://battle_2v2_bai_coc_safe_screenshot.png")
		_stop_test_audio()
		var bai_coc_safe_test_root = get_node_or_null("JudgementRevealRoot")
		if bai_coc_safe_test_root and is_instance_valid(bai_coc_safe_test_root):
			bai_coc_safe_test_root.queue_free()
		await get_tree().process_frame
		get_tree().quit()

	if "--test-reaction-card-selection" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().process_frame
		var test_passed = _run_reaction_card_selection_test()
		var test_judgement = get_node_or_null("JudgementRevealRoot")
		if test_judgement and is_instance_valid(test_judgement):
			test_judgement.queue_free()
		await get_tree().process_frame
		await get_tree().create_timer(0.9).timeout
		if test_passed:
			print("[TEST PASS] Rescue cards, Borrow Sword Slash, and Bai Coc judgement")
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Reaction card selection regression")
			get_tree().quit(1)

	if "--test-hung-suc-action" in cmd_args:
		is_network_mode = false
		is_player_turn = true
		current_server_phase = "PLAY"
		generals_data[my_seat]["equipment_cards"] = [{
			"id": "test_hung_suc_equipped",
			"name": "Trường Đao Nam Sơn",
			"rank": 7,
			"suit": "Spade",
			"category": 1,
			"subType": 6,
			"desc": "Vũ khí đang trang bị"
		}]
		_on_general_skill_clicked(my_seat, "hung_suc")
		await get_tree().process_frame
		var equipped_preview: Control = null
		for child in hand_container.get_children():
			if child.has_meta("hung_suc_equipped_preview"):
				equipped_preview = child
				break
		var equipped_badge = equipped_preview.get_node_or_null("EquippedBadge") if is_instance_valid(equipped_preview) else null
		var equipped_preview_ok = is_instance_valid(equipped_preview) and is_instance_valid(equipped_badge) \
			and equipped_badge.text == "ĐANG MANG" and equipped_badge.get_theme_color("font_color") == Color(1.0, 0.08, 0.08, 1.0)
		hung_suc_submission_pending = true
		selected_target_seat = 2
		_on_network_action_received({
			"type": "HUNG_SUC_TRIGGERED",
			"actionSeq": 999001,
			"casterSeat": my_seat,
			"targetSeat": 2,
			"cardId": "test_hung_suc_weapon",
			"cardName": "Trường Đao Nam Sơn",
			"description": "Phùng Hải kích hoạt Hùng Sức."
		})
		await get_tree().process_frame
		var preview_removed = true
		for child in hand_container.get_children():
			if child.has_meta("hung_suc_equipped_preview"):
				preview_removed = false
		if equipped_preview_ok and preview_removed and not is_targeting_hung_suc and not hung_suc_submission_pending and selected_target_seat == -1:
			print("[TEST PASS] Hùng Sức chọn được Vũ Khí đang mang")
			await get_tree().create_timer(2.5).timeout
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Hùng Sức chưa hiện hoặc chưa bỏ được Vũ Khí đang mang")
			get_tree().quit(1)

	if "--test-cai-cach-equipment" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().process_frame
		is_player_turn = true
		current_server_phase = "PLAY"
		var test_cai_cach_equipment = {
			"id": "test_cai_cach_armor",
			"name": "Giáp Đồng Sơn Vi",
			"rank": 8,
			"suit": "Club",
			"category": 1,
			"subType": 7,
			"desc": "Áo giáp đang trang bị"
		}
		_sync_player_equipments_from_server(my_seat, [test_cai_cach_equipment])
		_on_general_skill_clicked(my_seat, "cai_cach")
		await get_tree().process_frame
		var cai_cach_preview: Control = null
		for child in hand_container.get_children():
			if child.has_meta("hung_suc_equipped_preview"):
				cai_cach_preview = child
				break
		var cai_cach_badge = cai_cach_preview.get_node_or_null("EquippedBadge") if is_instance_valid(cai_cach_preview) else null
		var preview_ok = is_instance_valid(cai_cach_preview) and is_instance_valid(cai_cach_badge) and cai_cach_badge.text == "ĐANG MANG"
		_on_general_skill_clicked(my_seat, "cai_cach")
		await get_tree().process_frame
		var preview_removed_after_cancel = true
		for child in hand_container.get_children():
			if child.has_meta("hung_suc_equipped_preview"):
				preview_removed_after_cancel = false
		var avatar = generals_data[my_seat].get("avatar_node")
		var armor_label = avatar.get_node_or_null("Frame/EquipContainer/ArmorSlot/Label") if is_instance_valid(avatar) else null
		var equipment_preserved = generals_data[my_seat].get("equipment_cards", []).size() == 1 \
			and is_instance_valid(armor_label) and "Giáp Đồng Sơn Vi" in armor_label.text
		if preview_ok and preview_removed_after_cancel and equipment_preserved and not is_targeting_cai_cach:
			print("[TEST PASS] Cải Cách chọn được Trang bị đang mang và hủy không làm mất Trang bị")
			await get_tree().create_timer(2.5).timeout
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Cải Cách: preview=%s removed=%s preserved=%s targeting=%s equips=%s equipped_armor=%s armor=%s" % [preview_ok, preview_removed_after_cancel, equipment_preserved, is_targeting_cai_cach, generals_data[my_seat].get("equipment_cards", []).size(), generals_data[my_seat].get("equipped_armor", "<missing>"), armor_label.text if is_instance_valid(armor_label) else "<missing>"])
			get_tree().quit(1)

	if "--test-chinh-thong-button" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().process_frame
		current_server_phase = "AWAIT_CHINH_THONG_TARGET"
		current_waiting_seat = my_seat
		is_player_turn = false
		is_targeting_chinh_thong = true
		selected_target_seat = -1
		_update_action_btn()
		var initial_button_ok = card_play_btn.visible and card_play_btn.disabled
		var chinh_thong_target = 2 if my_seat != 2 else 3
		_on_general_avatar_clicked(chinh_thong_target)
		_update_action_btn()
		_update_action_btn()
		var selected_button_ok = card_play_btn.visible and not card_play_btn.disabled and selected_target_seat == chinh_thong_target and card_play_btn.text == "📜 DÙNG CHÍNH THỐNG"
		if initial_button_ok and selected_button_ok:
			print("[TEST PASS] Nút Chính Thống giữ nguyên sau khi chọn mục tiêu và cập nhật UI")
			await get_tree().create_timer(2.5).timeout
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Nút Chính Thống bị ẩn hoặc vô hiệu sau khi chọn mục tiêu")
			get_tree().quit(1)

	if "--test-da-trach-banner" in cmd_args:
		is_network_mode = false
		_on_network_action_received({
			"type": "DA_TRACH_TRIGGERED",
			"actionSeq": 999002,
			"casterSeat": my_seat,
			"targetSeat": 2,
			"cardId": "test_da_trach_slash",
			"cardName": "Trảm",
			"description": "Triệu Quang Phục kích hoạt Dạ Trạch."
		})
		await get_tree().process_frame
		var da_trach_avatar = generals_data.get(2, {}).get("avatar_node")
		var banner_started = is_instance_valid(da_trach_avatar) and da_trach_avatar.get_node_or_null("SkillActivationBanner") != null
		await get_tree().create_timer(1.7).timeout
		var banner_still_visible = is_instance_valid(da_trach_avatar) and da_trach_avatar.get_node_or_null("SkillActivationBanner") != null
		await get_tree().create_timer(0.5).timeout
		var banner_finished = is_instance_valid(da_trach_avatar) and da_trach_avatar.get_node_or_null("SkillActivationBanner") == null
		if banner_started and banner_still_visible and banner_finished:
			print("[TEST PASS] Dạ Trạch hiện trên tướng 2 giây rồi biến mất")
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Thời gian hiển thị Dạ Trạch không đúng")
			get_tree().quit(1)

	if "--test-ai-slash-da-trach" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().process_frame

		# Setup Seat 1 as Triệu Quang Phục (Hero 14)
		generals_data[1]["hero_id"] = 14
		generals_data[1]["name"] = "Triệu Quang Phục"
		generals_data[1]["hero_data"] = {"id": 14, "name": "Triệu Quang Phục"}
		generals_data[1]["hand_count"] = 0
		generals_data[1]["hand_cards"] = []
		generals_data[1]["is_alive"] = true
		generals_data[1]["hp"] = 4
		generals_data[1]["isDragon"] = true
		if is_instance_valid(hand_container) and my_seat == 1:
			for c in hand_container.get_children():
				c.queue_free()

		# Setup Seat 3 as another general (Cao Lỗ) with cards
		generals_data[3]["hero_id"] = 1
		generals_data[3]["name"] = "Cao Lỗ"
		generals_data[3]["hero_data"] = {"id": 1, "name": "Cao Lỗ"}
		generals_data[3]["hand_count"] = 2
		generals_data[3]["hand_cards"] = [{"name": "Đỡ"}, {"name": "Trảm"}]
		generals_data[3]["is_alive"] = true
		generals_data[3]["hp"] = 3
		generals_data[3]["isDragon"] = true

		# Setup Seat 2 as AI (Team Tiger)
		generals_data[2]["isDragon"] = false
		generals_data[2]["is_alive"] = true
		generals_data[2]["hp"] = 4
		generals_data[2]["hand_cards"] = [{"name": "Trảm", "suit": "Spade", "rank": 7}]
		generals_data[2]["hand_count"] = 1

		# 1. Test immunity helper
		var tqp_empty_blocked = _is_da_trach_slash_blocked(1)
		var other_blocked = _is_da_trach_slash_blocked(3)
		if not tqp_empty_blocked or other_blocked:
			push_error("[TEST FAIL] _is_da_trach_slash_blocked: tqp_empty=%s (want true), other=%s (want false)" % [tqp_empty_blocked, other_blocked])
			get_tree().quit(1)
			return

		# 2. When Triệu Quang Phục has cards, he is NOT blocked
		generals_data[1]["hand_count"] = 1
		generals_data[1]["hand_cards"] = [{"name": "Trảm"}]
		if my_seat == 1 and is_instance_valid(hand_container):
			generals_data[1]["isPlayer"] = false # test as general dict
		var tqp_with_cards_blocked = _is_da_trach_slash_blocked(1)
		if tqp_with_cards_blocked:
			push_error("[TEST FAIL] Triệu Quang Phục có bài nhưng vẫn bị tính là Dạ Trạch chặn!")
			get_tree().quit(1)
			return

		# Reset Triệu Quang Phục to 0 cards
		generals_data[1]["hand_count"] = 0
		generals_data[1]["hand_cards"] = []

		# 3. Test AI filtering: enemies = [1, 3]
		var enemies_test = [1, 3]
		var valid_targets: Array = []
		for e_seat in enemies_test:
			if _is_da_trach_slash_blocked(e_seat):
				continue
			valid_targets.append(e_seat)

		if valid_targets != [3]:
			push_error("[TEST FAIL] valid_targets should be [3], got %s" % str(valid_targets))
			get_tree().quit(1)
			return

		# 4. Test AI when ONLY Triệu Quang Phục with 0 cards is enemy
		var solo_enemy = [1]
		var solo_valid: Array = []
		for e_seat in solo_enemy:
			if _is_da_trach_slash_blocked(e_seat):
				continue
			solo_valid.append(e_seat)

		if not solo_valid.is_empty():
			push_error("[TEST FAIL] solo_valid should be empty, got %s" % str(solo_valid))
			get_tree().quit(1)
			return

		print("[TEST PASS] AI Trảm skip Triệu Quang Phục khi không có bài hoàn toàn chính xác!")
		get_tree().quit(0)


	if "--test-all-skill-feedback" in cmd_args:
		is_network_mode = false
		var missing_skill_voices: Array[String] = []
		for skill_name in IMPLEMENTED_HERO_SKILL_NAMES:
			if not AudioManager.has_voice(skill_name):
				missing_skill_voices.append(skill_name)
		var test_avatar = generals_data.get(2, {}).get("avatar_node")
		_show_activated_skills([
			{"name": "Dạ Trạch", "seat": 2},
			{"name": "Nỏ Đỉnh", "seat": 2}
		])
		await get_tree().process_frame
		var first_banner = test_avatar.get_node_or_null("SkillActivationBanner") if is_instance_valid(test_avatar) else null
		var first_ok = is_instance_valid(first_banner) and first_banner.text == "DẠ TRẠCH"
		await get_tree().create_timer(2.1).timeout
		var second_banner = test_avatar.get_node_or_null("SkillActivationBanner") if is_instance_valid(test_avatar) else null
		var second_ok = is_instance_valid(second_banner) and second_banner.text == "NỎ ĐỈNH"
		await get_tree().create_timer(2.1).timeout
		var queue_finished = is_instance_valid(test_avatar) and test_avatar.get_node_or_null("SkillActivationBanner") == null
		if missing_skill_voices.is_empty() and first_ok and second_ok and queue_finished:
			print("[TEST PASS] 32 giọng skill và hàng đợi banner 2 giây")
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Skill feedback: missing=%s first=%s second=%s finished=%s" % [missing_skill_voices, first_ok, second_ok, queue_finished])
			get_tree().quit(1)

	if "--test-equipment-card-pick" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		var equipment_labels_are_correct = _get_equipment_slot_title({"subType": 6}, "Nỏ Thần Kim Quy") == "🗡️ VŨ KHÍ" \
			and _get_equipment_slot_title({"subType": 7}, "Giáp Đồng Sơn Vi") == "🛡️ ÁO GIÁP" \
			and _get_equipment_slot_title({"subType": 8}, "Ngựa Trắng Thuần Nông") == "🐎 NGỰA CÔNG" \
			and _get_equipment_slot_title({"subType": 9}, "Voi Chiến Đại Việt") == "🐘 NGỰA THỦ" \
			and _get_equipment_slot_title({"subType": 27}, "Trống Đồng Đông Sơn") == "🥁 BẢO VẬT"
		var old_judgement = get_node_or_null("JudgementRevealRoot")
		if old_judgement and is_instance_valid(old_judgement):
			old_judgement.queue_free()
		await get_tree().process_frame
		_on_network_action_received({
			"actionSeq": 987654,
			"type": "SLASH_BLOCKED_BY_ARMOR",
			"casterSeat": 2,
			"targetSeat": 1,
			"cardName": "Trảm",
			"judgeCard": {"id": "stale_judge", "name": "Bài Phán Xét", "suit": "Spade", "rank": 9}
		})
		await get_tree().process_frame
		var armor_block_keeps_bai_coc_judgement = get_node_or_null("JudgementRevealRoot") != null
		var test_judgement = get_node_or_null("JudgementRevealRoot")
		if test_judgement and is_instance_valid(test_judgement):
			test_judgement.queue_free()
		for entry in showcase_entries:
			var showcase_node = entry.get("node")
			if showcase_node and is_instance_valid(showcase_node):
				showcase_node.queue_free()
		showcase_entries.clear()
		await get_tree().process_frame
		# Đợi tween Giáp Đồng khép lại trước khi đóng tiến trình test.
		await get_tree().create_timer(2.0).timeout
		if equipment_labels_are_correct and armor_block_keeps_bai_coc_judgement:
			print("[TEST PASS] Equipment labels and Bãi Cọc before Giáp Đồng block")
			get_tree().quit(0)
		else:
			push_error("[TEST FAIL] Equipment labels or Bãi Cọc judgement regression")
			get_tree().quit(1)

	if "--screenshot-song-cung-modal" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().create_timer(0.3).timeout
		_deal_initial_hands()
		if generals_data.has(1):
			generals_data[1]["equipped_weapon"] = "Song Cung Mường Nhạ"
			generals_data[1]["avatar_node"].set_equipment("weapon", "Song Cung Mường Nhạ", "K Đen")
		_prompt_song_cung_modal(2, 40.0)
		if hand_container.get_child_count() > 0:
			_handle_song_cung_card_selection(hand_container.get_child(0))
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_song_cung_screenshot.png")
		get_tree().quit()

	if "--screenshot-mua-ten" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().create_timer(0.3).timeout
		for ch in hand_container.get_children():
			ch.queue_free()
		await get_tree().process_frame
		var test_hand = [
			{"id": "c1", "name": "Trảm", "suit": "Spade", "rank": 7, "cat": 0, "subType": 0, "desc": "Tấn công 1 tướng trong tầm"},
			{"id": "c2", "name": "Đỡ", "suit": "Diamond", "rank": 2, "cat": 0, "subType": 3, "desc": "Hóa giải Trảm hoặc Mưa Tên"},
			{"id": "c3", "name": "Bánh Chưng", "suit": "Heart", "rank": 9, "cat": 0, "subType": 4, "desc": "Hồi 1 máu"},
			{"id": "c4", "name": "Mượn Gươm", "suit": "Club", "rank": 12, "cat": 2, "subType": 14, "desc": "Mượn vũ khí"}
		]
		for c in test_hand:
			var card_ui = CardUIScene.instantiate()
			hand_container.add_child(card_ui)
			card_ui.setup_card_data(c["id"], c["name"], c["rank"], c["suit"], c["cat"], c["desc"], c["subType"])
			card_ui.card_clicked.connect(func(_node): _on_player_hand_card_clicked(card_ui, c))
		_relayout_hand_cards()
		dodge_attacker_seat = 2
		_prompt_reaction_modal(
			"🏹 NÉ MƯA TÊN LIÊN CHÂU",
			"⚠️ Tướng 2 vừa dùng [Mưa Tên Liên Châu]!\nHãy chạm chọn 1 lá [Đỡ] trên tay để hóa giải hoặc bấm [CHỊU ĐÒN]:",
			"Đỡ",
			_format_damage_pass_text(1),
			"🛡️ ĐÁNH [ĐỠ] ĐỂ NÉ",
			40.0,
			false,
			true,
			false,
			false
		)
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_mua_ten_screenshot.png")
		get_tree().quit()

	if "--screenshot-drum-reveal" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if NetworkClient and NetworkClient.action_received.is_connected(_on_network_action_received):
			NetworkClient.action_received.disconnect(_on_network_action_received)
		await get_tree().create_timer(0.3).timeout
		_deal_initial_hands()
		var sample_cards = [
			{"id": "d1", "name": "Trảm - Hỏa", "suit": "Heart", "rank": 10, "category": 0, "subType": 1, "desc": "Tấn công 1 tướng trong tầm gây 1 sát thương Hỏa"},
			{"id": "d2", "name": "Đỡ", "suit": "Diamond", "rank": 2, "category": 0, "subType": 3, "desc": "Hóa giải đòn Trảm"},
			{"id": "d3", "name": "Song Cung Mường Nhạ", "suit": "Spade", "rank": 13, "category": 1, "subType": 6, "desc": "Tầm 2. Khi Trảm bị Đỡ, bỏ 2 lá để bỏ qua Đỡ; Trảm vẫn gây sát thương"},
			{"id": "d4", "name": "Bánh Chưng", "suit": "Heart", "rank": 8, "category": 0, "subType": 4, "desc": "Hồi 1 đóa sen máu khi bị thương"},
			{"id": "d5", "name": "Dụng Binh Như Thần", "suit": "Club", "rank": 7, "category": 2, "subType": 13, "desc": "Rút ngay 2 lá bài từ cọc rút"}
		]
		_show_drum_reveal_modal(2, sample_cards)
		if drum_reveal_cards_box and drum_reveal_cards_box.get_child_count() > 0:
			var first_card = drum_reveal_cards_box.get_child(0)
			if first_card.has_method("set_selected"):
				first_card.set_selected(true)
			if drum_reveal_status_lbl:
				drum_reveal_status_lbl.text = "👉 [10 Đỏ Trảm - Hỏa]: Tấn công 1 tướng trong tầm gây 1 sát thương Hỏa, lan qua Xích Tâm Tỏa."
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_drum_reveal_screenshot.png")
		get_tree().quit()

	if "--screenshot-drum-button" in cmd_args:
		await get_tree().create_timer(0.3).timeout
		var drum_owner = generals_data.get(my_seat, {})
		var drum_avatar = drum_owner.get("avatar_node")
		if drum_owner.is_empty() or not is_instance_valid(drum_avatar) or not is_instance_valid(drum_avatar.skill_btn):
			push_error("[Test Drum Button] Không tạo được nút Điểm Trống.")
			get_tree().quit()
			return
		drum_owner["equipped_treasure"] = "Trống Đồng Đông Sơn"
		drum_avatar.set_equipment("treasure", "Trống Đồng Đông Sơn", "K Đen")
		drum_avatar.set_skill("🥁 ĐIỂM TRỐNG")
		drum_avatar.set_skill_buttons([
			{"id": "drum", "text": "🥁 ĐIỂM TRỐNG"},
			{"id": "future_skill", "text": "⚡ KỸ NĂNG MỚI"}
		])
		await get_tree().process_frame
		var stack_buttons = drum_avatar.skill_buttons
		var stacked_without_overlap = stack_buttons.size() >= 2 and stack_buttons[0].get_global_rect().end.y <= stack_buttons[1].get_global_rect().position.y
		var stack_receives_clicks_above_avatar = drum_avatar.skill_button_stack.z_index > drum_avatar.click_btn.z_index \
			and not drum_avatar.skill_button_stack.z_as_relative \
			and drum_avatar.skill_button_stack.mouse_filter == Control.MOUSE_FILTER_STOP \
			and drum_avatar.skill_btn.mouse_filter == Control.MOUSE_FILTER_STOP \
			and drum_avatar.skill_button_stack.get_index() > drum_avatar.click_btn.get_index()
		drum_avatar.set_skill("🥁 ĐIỂM TRỐNG")
		is_player_turn = true
		current_server_phase = "PLAY"
		# Đi qua luồng input thật để phát hiện lớp ClickBtn che nút kỹ năng.
		var drum_click_position = drum_avatar.skill_btn.get_global_rect().get_center()
		var drum_mouse_down = InputEventMouseButton.new()
		drum_mouse_down.button_index = MOUSE_BUTTON_LEFT
		drum_mouse_down.button_mask = MOUSE_BUTTON_MASK_LEFT
		drum_mouse_down.pressed = true
		drum_mouse_down.position = drum_click_position
		drum_mouse_down.global_position = drum_click_position
		Input.parse_input_event(drum_mouse_down)
		await get_tree().process_frame
		var drum_mouse_up = InputEventMouseButton.new()
		drum_mouse_up.button_index = MOUSE_BUTTON_LEFT
		drum_mouse_up.button_mask = 0
		drum_mouse_up.pressed = false
		drum_mouse_up.position = drum_click_position
		drum_mouse_up.global_position = drum_click_position
		Input.parse_input_event(drum_mouse_up)
		await get_tree().process_frame
		var avatar_rect = drum_avatar.get_global_rect()
		var button_rect = drum_avatar.skill_btn.get_global_rect()
		var signal_activates_treasure = is_targeting_drum_skill
		var button_is_left_and_compact = button_rect.end.x <= avatar_rect.position.x - 4.0 \
			and button_rect.position.x >= avatar_rect.position.x - button_rect.size.x - 12.0 \
			and button_rect.size.y <= avatar_rect.size.y * 0.25
		if not is_targeting_drum_skill or not button_is_left_and_compact or not stacked_without_overlap or not stack_receives_clicks_above_avatar:
			print("[Test Drum Button] targeting=%s signal=%s compact=%s stacked=%s input=%s" % [is_targeting_drum_skill, signal_activates_treasure, button_is_left_and_compact, stacked_without_overlap, stack_receives_clicks_above_avatar])
			push_error("[Test Drum Button] Stack kỹ năng chưa nhận thao tác, chưa gọn bên trái tướng, hoặc các nút đang chồng lên nhau.")
		else:
			print("[Test Drum Button] PASS: Điểm Trống nhận thao tác; stack kỹ năng nằm gọn bên trái và không chồng lấn.")
		await get_tree().create_timer(0.25).timeout
		_save_viewport_screenshot("res://battle_2v2_drum_button_screenshot.png")
		get_tree().quit()

	if "--test-showcase-cards-ignore-input" in cmd_args:
		var display_card = CardUIScene.instantiate()
		_make_card_display_only(display_card)
		var display_click_button := display_card.get_node_or_null("ClickButton") as Button
		var display_card_ignores_clicks = display_card.mouse_filter == Control.MOUSE_FILTER_IGNORE \
			and display_click_button != null \
			and display_click_button.mouse_filter == Control.MOUSE_FILTER_IGNORE \
			and display_click_button.disabled
		if not display_card_ignores_clicks:
			push_error("[Test Showcase Input] Lá bài trình bày ở giữa bàn vẫn nhận thao tác chuột.")
		else:
			print("[Test Showcase Input] PASS: Lá bài trình bày không nhận thao tác chuột.")
		display_card.queue_free()
		get_tree().quit()

	if "--test-hich-recast-button" in cmd_args:
		is_network_mode = false
		is_player_turn = true
		current_server_phase = "PLAY"
		for hand_card in hand_container.get_children():
			hand_card.queue_free()
		await get_tree().process_frame
		var hich_card = CardUIScene.instantiate()
		hand_container.add_child(hich_card)
		hich_card.setup_card_data("test_hich_recast", "Hịch Tướng Sĩ", 13, "Diamond", 2, "Bỏ lá này để rút 1 lá khác.", 26)
		selected_card_ui = hich_card
		_update_action_btn()
		await get_tree().process_frame
		var hand_count_before_recast = hand_container.get_child_count()
		var recast_button_is_visible = hich_recast_btn.visible and not hich_recast_btn.disabled
		var recast_button_is_clear = not hich_recast_btn.get_global_rect().intersects(card_play_btn.get_global_rect()) and not hich_recast_btn.get_global_rect().intersects(end_turn_btn.get_global_rect())
		is_player_turn = true
		is_network_mode = false
		current_server_phase = "PLAY"
		_on_hich_recast_btn_clicked()
		await get_tree().process_frame
		await get_tree().process_frame
		var hand_count_is_preserved = hand_container.get_child_count() == hand_count_before_recast
		var recast_is_complete = selected_card_ui == null
		if not recast_button_is_visible or not recast_button_is_clear or not hand_count_is_preserved or not recast_is_complete:
			push_error("[Test Hich Recast] Nút đổi Hịch chưa hiển thị đúng hoặc bỏ-rút bài không hoàn tất.")
		else:
			print("[Test Hich Recast] PASS: Đổi Hịch Tướng Sĩ rút 1 lá mới, không chồng nút.")
		for test_card in hand_container.get_children():
			hand_container.remove_child(test_card)
			test_card.queue_free()
		for entry in showcase_entries:
			var showcase_node = entry.get("node")
			if showcase_node and is_instance_valid(showcase_node):
				showcase_node.queue_free()
		showcase_entries.clear()
		await get_tree().create_timer(3.0).timeout
		get_tree().quit()

	if "--screenshot-battle-2v2" in cmd_args:
		# Equip items and Đại Hồng Thủy badge to verify font size x1.4 and UI layout
		if generals_data.has(1):
			var p1 = generals_data[1]
			p1["equipped_weapon"] = "Nỏ Thần Kim Quy"
			p1["avatar_node"].set_equipment("weapon", "Nỏ Thần Kim Quy", "")
			p1["equipped_armor"] = "Khiên Mây Bện"
			p1["avatar_node"].set_equipment("armor", "Khiên Mây Bện", "")
			p1["has_dai_hong_thuy"] = true
			p1["has_lightning"] = true # Legacy snapshot compatibility.
			p1["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
		if generals_data.has(2):
			var p2 = generals_data[2]
			p2["equipped_weapon"] = "Kiếm Thuận Thiên"
			p2["avatar_node"].set_equipment("weapon", "Kiếm Thuận Thiên", "")
			p2["equipped_def_horse"] = "Voi Chiến Đại Việt"
			p2["avatar_node"].set_equipment("def_horse", "Voi Chiến Đại Việt", "")

		await get_tree().create_timer(1.5).timeout
		_save_viewport_screenshot("res://battle_2v2_screenshot.png")
		get_tree().quit()

	if "--screenshot-victory" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if AuthManager:
			AuthManager.disable_session_save = true
			AuthManager.current_2v2_rank_index = 0 # Dân Binh
			AuthManager.current_2v2_stars = 2 # 2 sao -> lên 3 sao (+1 sao)
			AuthManager.current_2v2_accumulation_points = 50 # 50 -> 75đ (+25đ)
		_show_victory_defeat_modal(true)
		await get_tree().create_timer(3.5).timeout
		_save_viewport_screenshot("res://battle_2v2_victory_screenshot.png")
		get_tree().quit()

	if "--screenshot-promotion" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if AuthManager:
			AuthManager.disable_session_save = true
			AuthManager.current_2v2_rank_index = 0 # Dân Binh
			AuthManager.current_2v2_stars = 4 # 4 sao
			AuthManager.current_2v2_accumulation_points = 80 # 80 + 25 = 105 -> Đầy 100đ thưởng thêm 1 sao = 6 sao -> Thăng hạng Hương Dũng 0 sao, 5đ!
		_show_victory_defeat_modal(true)
		await get_tree().create_timer(4.5).timeout
		_save_viewport_screenshot("res://battle_2v2_promotion_screenshot.png")
		get_tree().quit()

	if "--screenshot-defeat" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if AuthManager:
			AuthManager.disable_session_save = true
			AuthManager.current_2v2_rank_index = 1 # Hương Dũng
			AuthManager.current_2v2_stars = 3 # 3 sao -> giảm xuống 2 sao (-1 sao)
			AuthManager.current_2v2_accumulation_points = 20 # 20 -> 30đ (+10đ an ủi)
		_show_victory_defeat_modal(false)
		await get_tree().create_timer(3.5).timeout
		_save_viewport_screenshot("res://battle_2v2_defeat_screenshot.png")
		get_tree().quit()

	if "--screenshot-history" in cmd_args:
		_add_log("⚔️ Lý Thường Kiệt dùng [Trảm] lên Trần Hưng Đạo.")
		_add_log("🛡️ Trần Hưng Đạo dùng [Đỡ] hóa giải đòn tấn công.")
		_add_log("🌊 [Đại Hồng Thủy] phán xét Bích 7: Trúng bão lũ, chịu 3 sát thương Thủy.")
		_add_log("🌾 [Cắt Đường Lương] hiệu lực: bỏ qua giai đoạn rút bài.")
		_add_log("🍲 Bạn hồi phục 1 Máu bằng [Bánh Chưng] (3/4).")
		_add_log("💥 Tướng Ghế 4 chịu 1 sát thương thường.")
		_add_log("📜 Lượt của Trương Hán Siêu bắt đầu.")
		_show_history_popup()
		await get_tree().create_timer(0.7).timeout
		_save_viewport_screenshot("res://battle_2v2_history_screenshot.png")
		get_tree().quit()

	if "--screenshot-my-turn" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		_start_turn(my_seat)
		await get_tree().create_timer(0.5).timeout
		_save_viewport_screenshot("res://battle_2v2_my_turn_screenshot.png")
		get_tree().quit()

	if "--screenshot-dodge-modal" in cmd_args:
		# Trang bị Khiên Mây Bện để kiểm tra nút lật phán xét đồng thời với lựa chọn bài trên tay
		if generals_data.has(my_seat):
			generals_data[my_seat]["equipped_armor"] = "Khiên Mây Bện"
			generals_data[my_seat]["avatar_node"].set_equipment("armor", "Khiên Mây Bện", "")

		# Add 2 Dodge cards with different suits/ranks to test selection
		_add_card_to_player_hand({"id": "D80_DO_D2", "name": "Đỡ", "rank": 2, "suit": "Diamond", "cat": 0, "desc": "Hóa giải hoàn toàn 1 đòn Trảm"})
		_add_card_to_player_hand({"id": "D80_DO_H7", "name": "Đỡ", "rank": 7, "suit": "Heart", "cat": 0, "desc": "Hóa giải hoàn toàn 1 đòn Trảm"})
		await get_tree().create_timer(0.5).timeout
		_prompt_dodge_reaction(2, 1, "NORMAL")
		await get_tree().create_timer(0.4).timeout

		# Test switching to the second valid card (♦ 2 Đỡ) to prove manual selection works
		var valid_cards = _get_valid_dodge_cards(2)
		if valid_cards.size() >= 2:
			_select_dodge_card(valid_cards[1])

		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_dodge_screenshot.png")
		get_tree().quit()

	if "--screenshot-dodge-nododge" in cmd_args:
		# Discard all dodge cards from hand so player has no Dodge
		for ch in hand_container.get_children():
			var info = _get_card_info_from_ui(ch)
			if "đỡ" in info.get("name", "").to_lower():
				ch.queue_free()
		await get_tree().create_timer(0.5).timeout
		_prompt_dodge_reaction(2, 1, "NORMAL")
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_dodge_nododge_screenshot.png")
		get_tree().quit()

	if "--screenshot-chain-modal" in cmd_args:
		await get_tree().create_timer(0.5).timeout
		_show_iron_chain_modal()
		await get_tree().create_timer(0.4).timeout
		# Select seat 2 (Cao Lỗ - ally) and seat 4 (enemy) to showcase multi-target & ally chaining
		_toggle_chain_selection(2)
		_toggle_chain_selection(4)
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_chain_screenshot.png")
		get_tree().quit()

	if "--screenshot-iron-chain-direct" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		if dodge_modal: dodge_modal.visible = false
		is_waiting_dodge = false
		await get_tree().create_timer(0.5).timeout
		if dodge_modal: dodge_modal.visible = false
		is_waiting_dodge = false
		# Set seat 2 and seat 4 as chained to showcase Unity chain visuals
		if generals_data.has(2):
			generals_data[2]["is_chained"] = true
			generals_data[2]["avatar_node"].set_chained(true)
		if generals_data.has(4):
			generals_data[4]["is_chained"] = true
			generals_data[4]["avatar_node"].set_chained(true)

		# Find or add Xích Tâm Tỏa card
		var found_chain_card: Control = null
		for c_ui in hand_container.get_children():
			var c_info = _get_card_info_from_ui(c_ui)
			if c_info.get("name", "") == "Xích Tâm Tỏa":
				found_chain_card = c_ui
				break
		if not found_chain_card:
			_add_card_to_player_hand({
				"id": "xichtam_demo",
				"name": "Xích Tâm Tỏa",
				"suit": "Spade",
				"rank": 11,
				"cat": 2,
				"desc": "Chạm avatar để chọn tối đa 2 mục tiêu để đưa họ vào hoặc thoát trạng thái xích (cùng nhận sát thương nguyên tố), có thể đổi thành lá mới"
			})
			if hand_container.get_child_count() > 0:
				found_chain_card = hand_container.get_child(hand_container.get_child_count() - 1)

		if found_chain_card:
			var c_info = _get_card_info_from_ui(found_chain_card)
			_on_player_hand_card_clicked(found_chain_card, c_info)

		_on_general_avatar_clicked(3)
		_on_general_avatar_clicked(4)

		await get_tree().create_timer(0.6).timeout
		if not DisplayServer.get_name().to_lower().contains("headless"):
			_save_viewport_screenshot("res://battle_2v2_chain_direct_screenshot.png")
		get_tree().quit()

	if "--screenshot-discard-40s" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		await get_tree().create_timer(0.4).timeout
		# Set player HP to 2, while hand has more cards -> trigger discard phase
		generals_data[my_seat]["hp"] = 2
		generals_data[my_seat]["avatar_node"].update_hp(2, 4)
		var excess = max(1, hand_container.get_child_count() - 2)
		_enter_discard_phase(excess)
		await get_tree().create_timer(0.5).timeout
		if not DisplayServer.get_name().to_lower().contains("headless"):
			_save_viewport_screenshot("res://battle_2v2_discard_40s_screenshot.png")
		get_tree().quit()

	if "--screenshot-card-pick-modal" in cmd_args:
		# Equip some items to seat 2 to show both face-down cards & equipment options
		if generals_data.has(2):
			generals_data[2]["equipped_weapon"] = "Nỏ Thần Kim Quy"
			generals_data[2]["avatar_node"].set_equipment("weapon", "Nỏ Thần Kim Quy", "Nỏ Thần Kim Quy")
			generals_data[2]["equipped_def_horse"] = "Voi Chiến Đại Việt"
			generals_data[2]["avatar_node"].set_equipment("def_horse", "Voi Chiến Đại Việt", "Voi Chiến Đại Việt")
			generals_data[2]["hand_count"] = 4
		await get_tree().create_timer(0.5).timeout
		_show_card_pick_modal(true, 2)
		await get_tree().create_timer(0.4).timeout
		# Pick the weapon button if available
		for child in card_pick_options_hbox.get_children():
			if "VŨ KHÍ" in child.text:
				child.emit_signal("pressed")
				break
		await get_tree().create_timer(0.6).timeout
		_save_viewport_screenshot("res://battle_2v2_card_pick_screenshot.png")
		get_tree().quit()

	if "--screenshot-damage-effect" in cmd_args:
		await get_tree().create_timer(0.6).timeout
		# Gây sát thương lên Ghế 1 (Bản thân - Fire) và Ghế 2 (Đối thủ - Water)
		_apply_damage_to_general(my_seat, 1, 2, "FIRE")
		_apply_damage_to_general(2, 1, 1, "WATER")
		await get_tree().create_timer(0.18).timeout
		_save_viewport_screenshot("res://battle_2v2_damage_screenshot.png")
		get_tree().quit()

	if "--screenshot-hero-3hp" in cmd_args:
		is_network_mode = false
		if NetworkClient and NetworkClient.game_state_updated.is_connected(_on_network_game_state_updated):
			NetworkClient.game_state_updated.disconnect(_on_network_game_state_updated)
		await get_tree().create_timer(0.2).timeout
		if generals_data.has(my_seat):
			var lc = HeroDatabase.get_hero(4) if HeroDatabase else {}
			generals_data[my_seat]["hero_data"] = lc
			generals_data[my_seat]["name"] = "Lê Chân"
			generals_data[my_seat]["hp"] = 3
			generals_data[my_seat]["max_hp"] = 3
			generals_data[my_seat]["avatar_node"].setup_general("le_chan", "Lê Chân", "Hồng Bàng", 3, 3, "[1] RỒNG")
		if generals_data.has(2):
			var nt = HeroDatabase.get_hero(87) if HeroDatabase else {}
			generals_data[2]["hero_data"] = nt
			generals_data[2]["name"] = "Nguyễn Trãi"
			generals_data[2]["hp"] = 3
			generals_data[2]["max_hp"] = 3
			generals_data[2]["avatar_node"].setup_general("nguyen_trai", "Nguyễn Trãi", "Đông A", 3, 3, "[2] PHƯỢNG")

		_on_network_game_state_updated({
			"players": [
				{"seat": my_seat, "hp": 3, "maxHp": 3, "generalName": "Lê Chân", "heroId": "HERO_4"},
				{"seat": 2, "hp": 3, "maxHp": 3, "generalName": "Nguyễn Trãi", "heroId": "HERO_87"},
				{"seat": 3, "hp": 4, "maxHp": 4, "generalName": "Lý Thường Kiệt", "heroId": "HERO_47"},
				{"seat": 4, "hp": 4, "maxHp": 4, "generalName": "Trần Hưng Đạo", "heroId": "HERO_53"}
			]
		})
		await get_tree().create_timer(0.5).timeout
		_save_viewport_screenshot("res://battle_2v2_hero_3hp_screenshot.png")
		get_tree().quit()

func _process(delta: float) -> void:
	# Subtle background breathing animation
	bg_anim_timer += delta * 0.35
	if bg_rect and is_instance_valid(bg_rect):
		var scale_v = 1.02 + sin(bg_anim_timer) * 0.02
		bg_rect.scale = Vector2(scale_v, scale_v)
		bg_rect.position = Vector2(cos(bg_anim_timer * 0.6) * 8.0 - 40.0, sin(bg_anim_timer * 0.4) * 6.0 - 25.0)

	# Floating Golden Embers
	for p in ember_particles:
		if is_instance_valid(p):
			var pos = p.position
			pos.y -= p.get_meta("speed_y") * delta
			pos.x += p.get_meta("drift_x") * delta * sin(Time.get_ticks_msec() * 0.002)
			if pos.y < -10:
				pos.y = 730
				pos.x = randf_range(0, 1280)
			p.position = pos

	_process_showcase_queue()
	_update_distance_labels()
	hand_layout_refresh_timer -= delta
	if hand_layout_refresh_timer <= 0.0:
		hand_layout_refresh_timer = 0.1
		_relayout_hand_cards()

	if is_game_over:
		return

	# Handle Reaction Timer (Đếm 40s trên đầu người bị trảm hoặc người đang phản hồi)
	if current_waiting_seat > 0 and current_waiting_seat <= 4:
		current_waiting_timer -= delta
		var sec_wait = max(0, int(ceil(current_waiting_timer)))
		if generals_data.has(current_waiting_seat) and generals_data[current_waiting_seat].has("avatar_node") and is_instance_valid(generals_data[current_waiting_seat]["avatar_node"]):
			generals_data[current_waiting_seat]["avatar_node"].update_turn_timer(sec_wait)

		if current_waiting_seat == my_seat:
			if uat_khi_pending:
				if current_waiting_timer <= 0 and not uat_khi_submission_pending:
					_on_end_turn_btn_clicked()
			elif is_waiting_dodge:
				dodge_time_left = current_waiting_timer
				if dodge_timer_lbl and is_instance_valid(dodge_timer_lbl):
					dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec_wait
				if current_waiting_timer <= 0:
					_on_dodge_passed()
			elif is_waiting_thuy_trieu_rut_give:
				dodge_time_left = current_waiting_timer
				if dodge_timer_lbl and is_instance_valid(dodge_timer_lbl):
					dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec_wait
				if current_waiting_timer <= 0:
					_on_dodge_confirmed()
			elif is_waiting_rescue:
				rescue_time_left = current_waiting_timer
				if rescue_timer_lbl and is_instance_valid(rescue_timer_lbl):
					rescue_timer_lbl.text = "⏳ Còn lại: %ds" % sec_wait
				if current_waiting_timer <= 0:
					_on_rescue_passed()
			elif is_waiting_song_cung:
				dodge_time_left = current_waiting_timer
				if dodge_timer_lbl and is_instance_valid(dodge_timer_lbl):
					dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec_wait
				if current_waiting_timer <= 0:
					_on_song_cung_passed()
		else:
			if is_network_mode:
				if is_waiting_dodge or is_waiting_song_cung:
					_close_song_cung_modal()
					_close_dodge_reaction_state()
				if is_waiting_rescue:
					_close_rescue_modal()
			var wait_gen = generals_data.get(current_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % current_waiting_seat)
			turn_indicator.text = "🛡️ ĐANG CHỜ %s ĐỠ ĐÒN (%ds)..." % [wait_name, sec_wait]

	# Handle Dodge Reaction Timer fallback (Local mode only)
	elif not is_network_mode and is_waiting_dodge:
		dodge_time_left -= delta
		var sec = max(0, int(ceil(dodge_time_left)))
		if dodge_timer_lbl and is_instance_valid(dodge_timer_lbl):
			dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
			generals_data[my_seat]["avatar_node"].update_turn_timer(sec)
		if dodge_time_left <= 0:
			_on_dodge_passed()

	# Handle Song Cung Mường Nhạ Reaction Timer fallback (Local mode only)
	elif not is_network_mode and is_waiting_song_cung:
		dodge_time_left -= delta
		var sec = max(0, int(ceil(dodge_time_left)))
		if dodge_timer_lbl and is_instance_valid(dodge_timer_lbl):
			dodge_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
			generals_data[my_seat]["avatar_node"].update_turn_timer(sec)
		if dodge_time_left <= 0:
			_on_song_cung_passed()

	# Handle Rescue Reaction Timer fallback (Local mode only)
	elif not is_network_mode and is_waiting_rescue:
		rescue_time_left -= delta
		var sec = max(0, int(ceil(rescue_time_left)))
		if rescue_timer_lbl and is_instance_valid(rescue_timer_lbl):
			rescue_timer_lbl.text = "⏳ Còn lại: %ds" % sec
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
			generals_data[my_seat]["avatar_node"].update_turn_timer(sec)
		if rescue_time_left <= 0:
			_on_rescue_passed()

	# Handle Local Player Turn Timer (Chỉ đếm khi không có bất kỳ phản ứng chờ nào)
	elif is_player_turn:
		current_turn_timer -= delta
		var sec = max(0, int(ceil(current_turn_timer)))
		if is_discard_phase:
			turn_indicator.text = "⏳ BỎ %d LÁ BÀI THỪA (%ds)!" % [cards_to_discard_count, sec]
		else:
			turn_indicator.text = "⏳ LƯỢT CỦA BẠN (%ds)" % sec
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
			generals_data[my_seat]["avatar_node"].update_turn_timer(sec)
		if current_turn_timer <= 0:
			_on_player_turn_timeout()

	# Handle Remote / AI Turn Timer (Chỉ đếm khi không có phản ứng chờ)
	elif current_turn_seat > 0 and generals_data.has(current_turn_seat) and is_instance_valid(generals_data[current_turn_seat]["avatar_node"]):
		remote_turn_timer -= delta
		var sec_remote = max(0, int(ceil(remote_turn_timer)))
		generals_data[current_turn_seat]["avatar_node"].update_turn_timer(sec_remote)
		var turn_gen = generals_data.get(current_turn_seat, {})
		var turn_gen_name = turn_gen.get("name", "Ghế %d" % current_turn_seat)
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - %ds..." % [turn_gen_name, current_turn_seat, sec_remote]

func _start_ambient_effects() -> void:
	if not is_instance_valid(embers_layer):
		return
	for i in range(22):
		var ember = ColorRect.new()
		var s = randf_range(3.0, 7.0)
		ember.custom_minimum_size = Vector2(s, s)
		ember.color = Color(1.0, randf_range(0.75, 0.95), randf_range(0.25, 0.45), randf_range(0.35, 0.75))
		ember.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
		ember.set_meta("speed_y", randf_range(25.0, 60.0))
		ember.set_meta("drift_x", randf_range(-18.0, 18.0))
		embers_layer.add_child(ember)
		ember_particles.append(ember)

func _init_deck() -> void:
	card_deck_pile.clear()
	card_deck_pile = CardDatabase.create_deck_80()
	var room_id = ""
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		room_id = AppwriteMatchmaking.current_room.get("roomId", "")
	elif NetworkClient and NetworkClient.room_id != "":
		room_id = NetworkClient.room_id

	if room_id != "":
		# Đồng bộ 100% hạt giống xáo bài giữa các máy người chơi trong cùng một phòng đấu
		seed(hash(room_id))
	else:
		randomize()

	# Xáo bài đa tầng (5-pass shuffle) để phá vỡ hoàn toàn các cụm bài Trảm / Đỡ khởi tạo tuần tự:
	for p in range(5):
		card_deck_pile.shuffle()
	deck_count = card_deck_pile.size()
	_update_deck_hud()

func _update_deck_hud() -> void:
	if deck_label:
		deck_label.text = "🎴 %d" % deck_count

func _draw_card_from_pile() -> Dictionary:
	if card_deck_pile.is_empty():
		_init_deck()
	deck_count = max(0, deck_count - 1)
	_update_deck_hud()
	return card_deck_pile.pop_back()

func _init_generals_from_draft() -> void:
	var draft = []
	if AppwriteMatchmaking and AppwriteMatchmaking.draft_slots is Array and not AppwriteMatchmaking.draft_slots.is_empty():
		draft = AppwriteMatchmaking.draft_slots
	elif AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		var room_draft = AppwriteMatchmaking.current_room.get("draft_slots", [])
		var room_slots = AppwriteMatchmaking.current_room.get("slots", [])
		if room_draft is Array and not room_draft.is_empty():
			draft = room_draft
		elif room_slots is Array and not room_slots.is_empty():
			draft = room_slots

	# Xác định ghế của người chơi tại máy
	var session_uid = AppwriteMatchmaking.my_session_user_id if AppwriteMatchmaking else ""
	var auth_uid = AuthManager.current_user_id if AuthManager else ""
	var my_name = AppwriteMatchmaking.my_session_user_name if AppwriteMatchmaking else ""
	if str(my_name).is_empty() and AuthManager:
		my_name = AuthManager.current_user_name

	my_seat = NetworkClient.my_seat if NetworkClient and NetworkClient.my_seat >= 1 and NetworkClient.my_seat <= 8 else 1
	var mode_id := str(AppwriteMatchmaking.current_room.get("modeId", "2v2")) if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary else "2v2"
	if mode_id.begins_with("dynasty_") and draft.size() > 4:
		print("[Battle] Khởi tạo Vương Triều %d người với state %d ghế" % [draft.size(), draft.size()])
	battle_seat_count = maxi(4, draft.size())
	var matching_seats: Array[int] = []
	for slot in draft:
		if not (slot is Dictionary):
			continue
		var slot_uid = str(slot.get("userId", ""))
		var slot_name = str(slot.get("userName", ""))
		var is_session_match = session_uid != "" and (slot_uid == session_uid or (AppwriteMatchmaking and AppwriteMatchmaking.is_same_user(slot_uid, slot_name, session_uid, my_name)))
		var is_auth_match = auth_uid != "" and (slot_uid == auth_uid or (AppwriteMatchmaking and AppwriteMatchmaking.is_same_user(slot_uid, slot_name, auth_uid, my_name)))
		var is_name_match = slot.get("isPlayer", false) and slot_name == my_name and not my_name.is_empty()
		if is_session_match or is_auth_match or is_name_match:
			matching_seats.append(int(slot.get("seatNumber", slot.get("seat", 1))))
	# UID/tên trùng trong nhiều cửa sổ debug: ghế server đã cấp mới là định danh duy nhất.
	if matching_seats.size() == 1:
		my_seat = matching_seats[0]
	if NetworkClient:
		NetworkClient.my_seat = my_seat
		NetworkClient.update_debug_window_title(my_name)

	print("[Battle 2v2] Xác định Ghế người chơi tại máy: Ghế %d (UID: %s, Tên: %s)" % [my_seat, session_uid, my_name])

	my_team_is_dragon = (my_seat == 1 or my_seat == 3)
	for slot in draft:
		if int(slot.get("seatNumber", slot.get("seat", 0))) == my_seat:
			my_team_is_dragon = bool(slot.get("isDragon", my_team_is_dragon))
			break

	var fallback_hero_ids = [53, 1, 3, 47, 2, 4, 5, 6]

	# Ánh xạ layout bàn cờ theo chuẩn Unity:
	# Bạn (Người chơi tại máy) luôn ngồi góc Dưới Phải (SeatBottomRight)
	# Offset 1 (seat + 1): Top-Right
	# Offset 2 (seat + 2): Top-Left (Đồng Đội)
	# Offset 3 (seat + 3): Mid-Left
	var seat_to_avatar = _build_battle_seat_avatar_map(battle_seat_count)
	var seat_count := battle_seat_count

	for i in range(seat_count):
		var s_num = i + 1
		var slot_data = {}
		for candidate in draft:
			if candidate is Dictionary and int(candidate.get("seatNumber", candidate.get("seat", 0))) == s_num:
				slot_data = candidate
				break

		var is_p = (s_num == my_seat)
		var is_drag = bool(slot_data.get("isDragon", s_num == 1 or s_num == 3))
		var slot_uid = slot_data.get("userId", "")
		var is_ai = false
		if is_p:
			is_ai = false
		elif slot_data.has("isAI"):
			is_ai = bool(slot_data["isAI"])
		elif slot_uid != "" and not slot_uid.begins_with("bot_") and slot_uid != "empty":
			is_ai = false
		else:
			is_ai = bool(slot_data.get("isAI", not is_p))

		var hero_info = slot_data.get("chosenHero", null)
		if hero_info == null or not (hero_info is Dictionary) or hero_info.is_empty():
			var raw_hid = slot_data.get("heroId", 0)
			var hid = 0
			if raw_hid is int or raw_hid is float:
				hid = int(raw_hid)
			elif raw_hid is String:
				if raw_hid.begins_with("HERO_"):
					hid = int(raw_hid.trim_prefix("HERO_"))
				elif raw_hid.is_valid_int():
					hid = int(raw_hid)
			if hid > 0 and HeroDatabase:
				var db_h = HeroDatabase.get_hero(hid)
				if db_h is Dictionary and not db_h.is_empty():
					hero_info = db_h
			if (hero_info == null or not (hero_info is Dictionary) or hero_info.is_empty()) and slot_data.get("heroName", "") != "" and HeroDatabase:
				var db_by_name = HeroDatabase.get_hero_by_name(str(slot_data["heroName"]))
				if db_by_name is Dictionary and not db_by_name.is_empty():
					hero_info = db_by_name
		if hero_info == null or not (hero_info is Dictionary) or hero_info.is_empty():
			hero_info = HeroDatabase.get_hero(fallback_hero_ids[i % fallback_hero_ids.size()])

		var h_name = hero_info.get("name", "Tướng %d" % s_num)
		var h_faction = hero_info.get("faction", "Thăng Long")
		var h_hp = int(slot_data.get("maxHp", hero_info.get("maxHp", hero_info.get("hp", 4))))
		
		var slug = hero_info.get("slug", "")
		if slug == "":
			var h_id_int = int(hero_info.get("id", 0))
			if HeroDatabase:
				var db_h = HeroDatabase.get_hero(h_id_int)
				if db_h is Dictionary and not db_h.is_empty():
					slug = db_h.get("slug", "")
					h_faction = db_h.get("faction", h_faction)
		if slug == "":
			slug = str(hero_info.get("id", s_num))

		var is_dynasty := mode_id.begins_with("dynasty_")
		var role_code := str(slot_data.get("role", ""))
		var role_str = ("VƯƠNG" if role_code == "KING" else "?") if is_dynasty else ("RỒNG" if is_drag else "PHƯỢNG")

		var avatar_node = seat_to_avatar[s_num]
		avatar_node.setup_general(slug, h_name, h_faction, h_hp, h_hp, role_str, s_num)

		# Explicitly verify portrait texture
		var trans_path = "res://assets/heroes_transparent/" + slug + ".png"
		var tex_path = "res://assets/ui/" + slug + ".png"
		if ResourceLoader.exists(trans_path) and is_instance_valid(avatar_node.portrait_rect):
			avatar_node.portrait_rect.texture = load(trans_path)
		elif ResourceLoader.exists(tex_path) and is_instance_valid(avatar_node.portrait_rect):
			avatar_node.portrait_rect.texture = load(tex_path)

		# Every active skill is rendered in the avatar's left-side button stack.
		var skill_btn = avatar_node.skill_btn
		if skill_btn:
			skill_btn.custom_minimum_size = Vector2(92, 24)

		avatar_node.set_skill("")

		# Connect click signals
		avatar_node.clicked.connect(func(): _on_general_avatar_clicked(s_num))
		avatar_node.info_clicked.connect(func(): _show_general_info_modal(s_num))
		avatar_node.skill_button_clicked.connect(func(skill_key: String): _on_general_skill_clicked(s_num, skill_key))

		generals_data[s_num] = {
			"seat": s_num,
			"isPlayer": is_p,
			"isAI": is_ai,
			"isDragon": is_drag,
			"role": role_code,
				"name": h_name,
				"hero_id": int(hero_info.get("id", s_num)),
				"faction": h_faction,
			"hp": h_hp,
			"max_hp": h_hp,
			"hand_count": 0,
			"an_tich_count": 0,
			"hand_cards": [],
			"is_alive": true,
			"hero_data": hero_info,
			"avatar_node": avatar_node,
			"equipped_weapon": "",
			"equipped_armor": "",
			"equipped_off_horse": "",
			"equipped_def_horse": "",
			"equipped_treasure": "",
			"equipment_cards": [],
			"is_chained": false,
			"has_dai_hong_thuy": false,
			"has_lightning": false, # Legacy state alias.
			"has_cat_luong": false,
			"has_tram_ao": false,
			"has_bai_coc": false,
			"bai_coc_judgement_count": 0,
			"ao_bao_charges": 0,
			"che_no_active": false,
			"suc_soi_turns_remaining": 0,
			"hp_synced": false
		}
		_refresh_local_skill_buttons(s_num)

func _hero_has_skill(g: Dictionary, skill_id: String) -> bool:
	var hero = g.get("hero_data", {})
	var hero_id = int(hero.get("id", g.get("hero_id", 0)))
	return hero_id > 0 and HeroDatabase.has_hero_skill(hero_id, skill_id)

func _is_da_trach_slash_blocked(target_seat: int) -> bool:
	if not generals_data.has(target_seat):
		return false
	var tgt = generals_data[target_seat]
	if not tgt.get("is_alive", false):
		return false
	var is_da_trach: bool = _hero_has_skill(tgt, "da_trach") or int(tgt.get("hero_id", 0)) == 14 or "Triệu Quang Phục" in str(tgt.get("name", ""))
	if not is_da_trach:
		return false
	var hand_cnt: int = int(tgt.get("hand_count", 0))
	if tgt.has("hand_cards") and tgt["hand_cards"] is Array:
		hand_cnt = max(hand_cnt, tgt["hand_cards"].size())
	if (tgt.get("isPlayer", false) or target_seat == my_seat) and is_instance_valid(hand_container):
		hand_cnt = max(hand_cnt, hand_container.get_child_count())
	return hand_cnt == 0


func _can_use_lien_chau(g: Dictionary) -> bool:
	var hero = g.get("hero_data", {})
	var hero_id = str(g.get("hero_id", hero.get("id", ""))).to_upper()
	return _hero_has_skill(g, "lien_chau") or hero_id == "1" or hero_id == "HERO_1" or str(g.get("name", "")) == "Cao Lỗ"

func _has_no_than(g: Dictionary) -> bool:
	var weapon = str(g.get("equipped_weapon", ""))
	return "Nỏ Thần" in weapon or "No Than" in weapon

func _has_equipped_horse(g: Dictionary) -> bool:
	if not str(g.get("equipped_off_horse", "")).is_empty() or not str(g.get("equipped_def_horse", "")).is_empty():
		return true
	for eq in g.get("equipments", []):
		if typeof(eq) == TYPE_DICTIONARY:
			var sub_type = eq.get("subType", "")
			if sub_type == 7 or sub_type == 8 or "HORSE" in str(sub_type).to_upper():
				return true
	return false

func _is_server_skill_active(player: Dictionary, skill_name: String) -> bool:
	var keys = player.get("activeSkillsKeys", [])
	var values = player.get("activeSkillsValues", [])
	if not (keys is Array) or not (values is Array):
		return false
	var index = keys.find(skill_name)
	return index >= 0 and index < values.size() and bool(values[index])

func _refresh_local_skill_buttons(seat: int) -> void:
	if not generals_data.has(seat):
		return
	var g = generals_data[seat]
	var avatar = g.get("avatar_node")
	if not is_instance_valid(avatar):
		return
	var buttons: Array = []
	var has_an_tich := int(g.get("an_tich_count", 0)) > 0
	var has_delayed_scroll := false
	if seat == my_seat:
		for hand_card in hand_container.get_children():
			var hand_info = _get_card_info_from_ui(hand_card)
			if int(hand_info.get("cat", hand_info.get("category", -1))) == 3:
				has_delayed_scroll = true
				break
	if seat == my_seat and _hero_has_skill(g, "an_tich") and has_an_tich and current_server_phase == "AWAIT_SLASH_DEFENSE" and current_waiting_seat == my_seat:
		buttons.append({"id": "an_tich", "text": "🌫️ ẨN TÍCH (%d)" % int(g.get("an_tich_count", 0)), "description": "Chọn 1 lá Ẩn để dùng như Đỡ cho đòn Trảm."})
	if seat == my_seat and _hero_has_skill(g, "thien_cam") and int(g.get("hp", 0)) <= 1 and current_server_phase == "PLAY" and current_turn_seat == my_seat and has_delayed_scroll:
		buttons.append({"id": "thien_cam", "text": "🌙 THIÊN CẢM", "description": "Bỏ 1 Cẩm Nang Trì Hoãn trên tay để rút 2 lá mới.", "selected": is_targeting_thien_cam})
	if seat == my_seat and _hero_has_skill(g, "che_no"):
		buttons.append({"id": "che_no", "text": "🎯 CHẾ NỎ", "description": "Bật: mọi lá bài Đen trên tay trở thành Nỏ Thần Kim Quy. Bấm lại để hủy.", "selected": bool(g.get("che_no_active", false))})
	if seat == my_seat and _hero_has_skill(g, "trieu_dang"):
		buttons.append({"id": "trieu_dang", "text": "🌊 TRIỀU DÂNG", "description": "Chọn 1 người khác có trang bị để hủy 1 trang bị của họ.", "selected": is_targeting_trieu_dang})
	if seat == my_seat and _hero_has_skill(g, "bat_na"):
		buttons.append({"id": "bat_na", "text": "🎭 BÁT NẠ", "description": "Một lần mỗi lượt: biến 1 Bài Cơ Bản thành Trảm không tính giới hạn.", "selected": is_targeting_bat_na})
	if seat == my_seat and _hero_has_skill(g, "hung_suc"):
		buttons.append({"id": "hung_suc", "text": "💪 HÙNG SỨC", "description": "Bỏ 1 Vũ Khí trên tay hoặc đang trang bị để gây 1 sát thương cho mục tiêu trong Tầm 1, sau đó rút 1 lá.", "selected": is_targeting_hung_suc})
	if seat == my_seat and _hero_has_skill(g, "van_an"):
		buttons.append({"id": "van_an", "text": "🏯 VẠN AN", "description": "Giới hạn mỗi lượt 2 lần: bỏ 2 lá bài bất kỳ trên tay để dùng Bãi Cọc Bạch Đằng. Lần đầu mỗi lượt, rút 1 lá.", "selected": is_targeting_van_an})
	if seat == my_seat and _hero_has_skill(g, "cai_cach"):
		buttons.append({"id": "cai_cach", "text": "🔄 CẢI CÁCH", "description": "Mỗi lượt 1 lần: đổi 2 lá bài trên tay hoặc đang mang lấy 2 lá mới.", "selected": is_targeting_cai_cach})
	if seat == my_seat and _hero_has_skill(g, "binh_san"):
		buttons.append({"id": "binh_san", "text": "🪨 BÌNH SẠN", "description": "Bỏ 1 lá trang bị để hủy 1 lá trong vùng chơi của mục tiêu.", "selected": is_targeting_binh_san})
	if seat == my_seat and _hero_has_skill(g, "tay_phu"):
		buttons.append({"id": "tay_phu", "text": "⚔️ TÂY PHU", "description": "Bỏ 2 lá trên tay để dùng như Huyết Chiến.", "selected": is_targeting_tay_phu})
	if seat == my_seat and _hero_has_skill(g, "dan_cau"):
		buttons.append({"id": "dan_cau", "text": "🌉 DẪN CẦU", "description": "Mỗi lượt 1 lần: trao 1 lá, ép Trảm mục tiêu chỉ định hoặc cướp 2 lá.", "selected": is_targeting_dan_cau})
	if seat == my_seat and _hero_has_skill(g, "thuy_chien"):
		buttons.append({"id": "thuy_chien", "text": "🌊 THỦY CHIẾN", "description": "Dùng bài Trắng hoặc bài Vàng như Bãi Cọc Bạch Đằng.", "selected": is_targeting_thuy_chien})
	if seat == my_seat and _hero_has_skill(g, "dinh_quoc"):
		buttons.append({"id": "dinh_quoc", "text": "⚔️ ĐỊNH QUỐC", "description": "Dùng bất kỳ lá bài Đen nào như Huyết Chiến."})
	if seat == my_seat and _hero_has_skill(g, "trao_bao"):
		buttons.append({"id": "trao_bao", "text": "👑 TRAO BÀO", "description": "Chuyển 1 trang bị cho người khác: hồi 1 máu, bạn rút 1 lá."})
	if seat == my_seat and _hero_has_skill(g, "muu_dinh"):
		buttons.append({"id": "muu_dinh", "text": "📜 MƯU ĐỊNH", "description": "Xem 2 lá đầu xấp rút, trao 1 lá cho người bất kỳ, đặt 1 lá lại lên đầu."})
	if seat == my_seat and _hero_has_skill(g, "doi_do"):
		buttons.append({"id": "doi_do", "text": "🏯 DỜI ĐÔ", "description": "Bỏ toàn bộ bài trên tay: rút lại + 1 lá, tối đa 4 người mỗi người rút 1 lá."})
	var treasure = str(g.get("equipped_treasure", ""))
	if seat == my_seat and treasure == "Trống Đồng Đông Sơn":
		buttons.append({"id": "treasure_drum", "text": "🥁 ĐIỂM TRỐNG"})
	elif seat == my_seat and treasure == "Hổ Phù Trần Triều":
		buttons.append({"id": "treasure_ho_phu", "text": "🐯 HỔ PHÙ"})
	avatar.set_skill_buttons(buttons)
	if avatar.has_method("set_skill_button_selected"):
		avatar.set_skill_button_selected("che_no", bool(g.get("che_no_active", false)))
		avatar.set_skill_button_selected("trieu_dang", is_targeting_trieu_dang)
		avatar.set_skill_button_selected("bat_na", is_targeting_bat_na)
		avatar.set_skill_button_selected("van_sach", is_targeting_van_sach)
		avatar.set_skill_button_selected("hung_suc", is_targeting_hung_suc)
		avatar.set_skill_button_selected("van_an", is_targeting_van_an)
		avatar.set_skill_button_selected("cai_cach", is_targeting_cai_cach)
		avatar.set_skill_button_selected("binh_san", is_targeting_binh_san)
		avatar.set_skill_button_selected("tay_phu", is_targeting_tay_phu)
	if avatar.has_method("set_treasure_skill_selected"):
		avatar.set_treasure_skill_selected(is_targeting_drum_skill or is_targeting_ho_phu_skill)
	_relayout_hand_cards()

func _set_local_che_no_hand(active: bool) -> void:
	for card_ui in hand_container.get_children():
		var info = _get_card_info_from_ui(card_ui)
		if active and _get_card_color(str(info.get("suit", ""))) == "BLACK" and int(info.get("subType", -1)) != 6:
			card_ui.set_meta("che_no_original", info.duplicate())
			card_ui.setup_card_data(str(info.get("id", "")), "Nỏ Thần Kim Quy", info.get("rank", 1), str(info.get("suit", "Spade")), 1, "Tầm 1. Không giới hạn số Trảm trong lượt", 6)
		elif not active and card_ui.has_meta("che_no_original"):
			var original = card_ui.get_meta("che_no_original") as Dictionary
			card_ui.setup_card_data(str(original.get("id", "")), str(original.get("name", "Bài")), original.get("rank", 1), str(original.get("suit", "Spade")), int(original.get("cat", 0)), str(original.get("desc", "")), int(original.get("subType", -1)))
			card_ui.remove_meta("che_no_original")

func _on_general_skill_clicked(s_num: int, skill_key: String = "") -> void:
	if not generals_data.has(s_num):
		return
	var g = generals_data[s_num]
	var h_data = g.get("hero_data", {})
	if not (h_data is Dictionary):
		h_data = {}
	var h_id = int(h_data.get("id", 0))
	var h_name = g.get("name", "")
	if s_num == my_seat and skill_key == "an_tich":
		if current_server_phase != "AWAIT_SLASH_DEFENSE" or current_waiting_seat != my_seat or int(g.get("an_tich_count", 0)) <= 0:
			desc_text.text = "⚠️ Không có lá Ẩn để dùng lúc này."
			return
		var hidden_options: Array = []
		for hidden in g.get("an_tich_cards", []):
			if hidden is Dictionary:
				hidden_options.append({"token": "AN_TICH:%s" % str(hidden.get("id", "")), "zone": "AN_TICH", "label": "ẨN", "card": hidden})
		if hidden_options.size() == 1:
			NetworkClient.send_respond_action(true, "AN_TICH:%s" % str(hidden_options[0].get("card", {}).get("id", "")))
		else:
			_show_card_pick_modal(true, my_seat, {"effectType": "AN_TICH_DEFENSE", "options": hidden_options})
		desc_text.text = "🌫️ Chọn 1 lá Ẩn để Đỡ đòn."
		return
	if s_num == my_seat and skill_key == "thien_cam":
		if current_server_phase != "PLAY" or current_turn_seat != my_seat or int(g.get("hp", 0)) > 1:
			desc_text.text = "⚠️ [THIÊN CẢM] chỉ dùng khi còn không quá 1 Máu trong lượt của bạn."
			return
		is_targeting_thien_cam = not is_targeting_thien_cam
		selected_card_ui = null
		if is_targeting_thien_cam:
			desc_text.text = "🌙 [THIÊN CẢM] Chọn 1 Cẩm Nang Trì Hoãn trên tay để đổi thành 2 lá mới."
			turn_indicator.text = "🌙 THIÊN CẢM: CHỌN CẨM NANG TRÌ HOÃN"
		else:
			desc_text.text = "🌙 Đã hủy chọn [THIÊN CẢM]."
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key == "binh_san":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [BÌNH SẠN] chỉ dùng trong Giai đoạn Ra bài của bạn."
			return
		is_targeting_binh_san = not is_targeting_binh_san
		is_targeting_tay_phu = false
		selected_two_card_skill_nodes.clear()
		selected_target_seat = -1
		selected_card_ui = null
		if is_targeting_binh_san:
			_refresh_hung_suc_equipped_weapon_previews()
		else:
			_clear_hung_suc_equipped_weapon_previews()
		desc_text.text = "🪨 [BÌNH SẠN] Chọn 1 trang bị để bỏ và 1 mục tiêu."
		turn_indicator.text = "🪨 BÌNH SẠN: CHỌN TRANG BỊ VÀ MỤC TIÊU"
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key == "tay_phu":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [TÂY PHU] chỉ dùng trong Giai đoạn Ra bài của bạn."
			return
		is_targeting_tay_phu = not is_targeting_tay_phu
		is_targeting_binh_san = false
		_clear_hung_suc_equipped_weapon_previews()
		selected_two_card_skill_nodes.clear()
		selected_target_seat = -1
		desc_text.text = "⚔️ [TÂY PHU] Chọn 2 lá trên tay và 1 mục tiêu Huyết Chiến."
		turn_indicator.text = "⚔️ TÂY PHU: CHỌN 2 LÁ VÀ MỤC TIÊU"
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and (skill_key == "che_no" or (skill_key.is_empty() and _hero_has_skill(g, "che_no"))):
		g["che_no_active"] = not bool(g.get("che_no_active", false))
		_set_local_che_no_hand(g["che_no_active"])
		_refresh_local_skill_buttons(s_num)
		if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
			NetworkClient.send_toggle_skill("Chế Nỏ")
		var state_text = "bật" if g["che_no_active"] else "tắt"
		desc_text.text = "🎯 [CHẾ NỎ] đã %s: lá bài Đen trên tay %s Nỏ Thần Kim Quy." % [state_text, "trở thành" if g["che_no_active"] else "trở lại"]
		return
	if s_num == my_seat and (skill_key == "trieu_dang" or (skill_key.is_empty() and _hero_has_skill(g, "trieu_dang"))):
		if not is_player_turn:
			desc_text.text = "⚠️ [TRIỀU DÂNG] chỉ dùng trong lượt của bạn."
			return
		if is_targeting_trieu_dang:
			is_targeting_trieu_dang = false
			if selected_target_seat > 0 and generals_data.has(selected_target_seat):
				generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
			selected_target_seat = -1
			card_play_btn.visible = false
			desc_text.text = "🌊 Đã hủy chọn [TRIỀU DÂNG]."
		else:
			_clear_treasure_targeting()
			is_targeting_trieu_dang = true
			desc_text.text = "🌊 [TRIỀU DÂNG] Chọn 1 người khác có trang bị để hủy 1 lá."
			turn_indicator.text = "🌊 TRIỀU DÂNG: CHỌN TƯỚNG CÓ TRANG BỊ"
			AudioManager.play_card_select()
		_refresh_local_skill_buttons(s_num)
		return
	if s_num == my_seat and (skill_key == "bat_na" or (skill_key.is_empty() and _hero_has_skill(g, "bat_na"))):
		if not is_player_turn:
			desc_text.text = "⚠️ [BÁT NẠ] chỉ dùng trong lượt của bạn."
			return
		is_targeting_bat_na = not is_targeting_bat_na
		desc_text.text = "🎭 [BÁT NẠ] Chọn 1 Bài Cơ Bản và 1 mục tiêu trong tầm."
		turn_indicator.text = "🎭 BÁT NẠ: CHỌN BÀI CƠ BẢN VÀ MỤC TIÊU"
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key == "van_sach":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [VĂN SÁCH] chỉ dùng trong Giai đoạn Ra bài."
			return
		is_targeting_van_sach = not is_targeting_van_sach
		desc_text.text = "📚 [VĂN SÁCH] Chọn 1 lá Bài Cơ Bản trên tay để đổi."
		turn_indicator.text = "📚 VĂN SÁCH: CHỌN 1 BÀI CƠ BẢN"
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key == "hung_suc":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [HÙNG SỨC] chỉ dùng trong Giai đoạn Ra bài."
			return
		is_targeting_hung_suc = not is_targeting_hung_suc
		if is_targeting_hung_suc:
			_refresh_hung_suc_equipped_weapon_previews()
		else:
			_clear_hung_suc_equipped_weapon_previews()
		desc_text.text = "💪 [HÙNG SỨC] Chọn 1 Vũ Khí trên tay hoặc đang đeo và 1 mục tiêu trong Tầm 1."
		turn_indicator.text = "💪 HÙNG SỨC: CHỌN VŨ KHÍ VÀ MỤC TIÊU"
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key in ["van_an", "cai_cach", "dan_cau", "thuy_chien"]:
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ Kỹ năng này chỉ dùng trong Giai đoạn Ra bài."
			return
		is_targeting_van_an = skill_key == "van_an" and not is_targeting_van_an
		is_targeting_dan_cau = skill_key == "dan_cau" and not is_targeting_dan_cau
		is_targeting_thuy_chien = skill_key == "thuy_chien" and not is_targeting_thuy_chien
		is_targeting_cai_cach = skill_key == "cai_cach" and not is_targeting_cai_cach
		selected_target_seat = -1
		dan_cau_forced_target_seat = -1
		_clear_normal_hand_selection()
		selected_card_ui = null
		for card_node in selected_two_card_skill_nodes:
			if is_instance_valid(card_node): card_node.set_selected(false)
		selected_two_card_skill_nodes.clear()
		if is_targeting_cai_cach:
			_refresh_hung_suc_equipped_weapon_previews()
			desc_text.text = "🔄 [CẢI CÁCH] Chọn đúng 2 lá trên tay hoặc đang mang."
			turn_indicator.text = "🔄 CẢI CÁCH: CHỌN 2 LÁ"
		elif is_targeting_van_an:
			_clear_hung_suc_equipped_weapon_previews()
			desc_text.text = "🏯 [VẠN AN] Chọn 2 lá bất kỳ và 1 mục tiêu."
			turn_indicator.text = "🏯 VẠN AN: CHỌN 2 LÁ BẤT KỲ VÀ MỤC TIÊU"
		elif is_targeting_dan_cau:
			desc_text.text = "🌉 [DẪN CẦU] Chọn 1 lá, người bị ép và mục tiêu Trảm."
			turn_indicator.text = "🌉 DẪN CẦU: CHỌN BÀI VÀ 2 MỤC TIÊU"
		elif is_targeting_thuy_chien:
			desc_text.text = "🌊 [THỦY CHIẾN] Chọn 1 lá bài Trắng/bài Vàng và mục tiêu."
			turn_indicator.text = "🌊 THỦY CHIẾN: CHỌN BÀI VÀ MỤC TIÊU"
		else:
			_clear_hung_suc_equipped_weapon_previews()
			desc_text.text = "🔄 Đã hủy chọn [CẢI CÁCH]."
		_refresh_local_skill_buttons(s_num)
		_update_action_btn()
		return
	if s_num == my_seat and skill_key == "doi_do":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [DỜI ĐÔ] chỉ dùng trong Giai đoạn Ra bài."
			return
		if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
			NetworkClient.send_use_skill("Dời Đô", 0)
		desc_text.text = "🏯 Đã phát động [DỜI ĐÔ]!"
		return
	if s_num == my_seat and skill_key == "muu_dinh":
		if not is_player_turn or current_server_phase != "PLAY":
			desc_text.text = "⚠️ [MƯU ĐỊNH] chỉ dùng trong Giai đoạn Ra bài."
			return
		if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
			NetworkClient.send_use_skill("Mưu Định", my_seat)
		desc_text.text = "📜 Đã phát động [MƯU ĐỊNH]!"
		return
	if s_num == my_seat and "hổ phù" in str(g.get("equipped_treasure", "")).to_lower():
		if is_targeting_ho_phu_skill:
			_clear_treasure_targeting()
			desc_text.text = "🐯 Đã hủy kích hoạt Hổ Phù."
			return
		_clear_treasure_targeting()
		is_targeting_ho_phu_skill = true
		_set_treasure_skill_selected(true)
		desc_text.text = "🐯 Hổ Phù: Chọn 1 tướng khác, rồi chọn 1 lá trên tay để giao."
		turn_indicator.text = "🐯 HỔ PHÙ: CHỌN TƯỚNG VÀ LÁ BÀI"
		_animate_showcase_card("Hổ Phù Trần Triều", "Chọn người nhận và 1 lá bài để giao.")
		AudioManager.play_card_select()
		_update_action_btn()
		return
	if s_num == my_seat and "trống đồng" in str(g.get("equipped_treasure", "")).to_lower():
		if is_targeting_drum_skill:
			_clear_treasure_targeting()
			desc_text.text = "🥁 Đã hủy kích hoạt Trống Đồng Đông Sơn."
			return

		_clear_treasure_targeting()
		is_targeting_drum_skill = true
		_set_treasure_skill_selected(true)
		var drum_instruction = "🥁 Điểm Trống: Chọn 1 tướng khác có bài trên tay. Người đó phải tự bỏ 1 lá hoặc lộ toàn bộ bài trên tay cho bạn xem."
		desc_text.text = drum_instruction
		turn_indicator.text = "🥁 ĐIỂM TRỐNG: CHỌN 1 TƯỚNG CÓ BÀI TRÊN TAY"
		_animate_showcase_card("Trống Đồng Đông Sơn", drum_instruction)
		AudioManager.play_card_select()

		if selected_card_ui and is_instance_valid(selected_card_ui):
			if selected_card_ui.has_method("set_selected"):
				selected_card_ui.set_selected(false)
			selected_card_ui = null

		if selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "🥁 DÙNG TRỐNG ĐỒNG ➜ %s" % tgt["name"]
			card_play_btn.disabled = false
			card_play_btn.visible = true
			desc_text.text = "🥁 [TRỐNG ĐỒNG ĐÔNG SƠN - ĐIỂM TRỐNG]: Đã chọn %s. Nhấn nút kích hoạt để bắt đầu!" % tgt["name"]
		else:
			card_play_btn.text = "🥁 DÙNG TRỐNG ĐỒNG: CHỌN MỤC TIÊU..."
			card_play_btn.disabled = true
			card_play_btn.visible = true
			desc_text.text = "🥁 [TRỐNG ĐỒNG ĐÔNG SƠN - ĐIỂM TRỐNG]: Hãy chọn 1 Tướng trên bàn để kích hoạt! Mục tiêu phải chọn bỏ 1 lá bài hoặc lộ toàn bộ bài trên tay."
		return
	var skill_name = ""
	var skills = HeroDatabase.get_hero_skills(int(g.get("hero_id", h_data.get("id", 0))))
	if skills is Array and not skills.is_empty() and skills[0] is Dictionary:
		skill_name = str(skills[0].get("name", ""))
	if is_network_mode and s_num == my_seat and NetworkClient and NetworkClient.is_connected_to_server:
		if "Chế Nỏ" in skill_name or "Chế Nỏ" in h_name:
			NetworkClient.send_toggle_skill(skill_name if not skill_name.is_empty() else "Chế Nỏ")
		else:
			NetworkClient.send_use_skill(skill_name if not skill_name.is_empty() else h_name, selected_target_seat if selected_target_seat > 0 else 0)

		# 1. Lý Thường Kiệt (ID 47 - Tiến Thoái): Biến Trảm thành Đỡ và ngược lại
	if (h_id == 47 or "Lý Thường Kiệt" in h_name) and s_num == my_seat:
		var converted_count = 0
		for card_ui in hand_container.get_children():
			var info = _get_card_info_from_ui(card_ui)
			var c_name = info.get("name", "")
			if "Trảm" in c_name:
				card_ui.setup_card_data(info.get("id", ""), "Đỡ", info.get("rank", 1), info.get("suit", ""), 0, "Hóa giải hoàn toàn 1 đòn Trảm (Tiến Thoái)")
				converted_count += 1
			elif c_name == "Đỡ":
				card_ui.setup_card_data(info.get("id", ""), "Trảm", info.get("rank", 1), info.get("suit", ""), 0, "Tấn công gây 1 sát thương (Tiến Thoái)")
				converted_count += 1
		if converted_count > 0:
			_animate_showcase_card("Tiến Thoái", "Lý Thường Kiệt: Hoán đổi %d lá Trảm ⟷ Đỡ!" % converted_count)
			_add_log("✨ [TIẾN THOÁI] Lý Thường Kiệt đã hoán chuyển %d lá Trảm ⟷ Đỡ trên tay!" % converted_count)
			AudioManager.play_skill()
			if is_waiting_dodge:
				_set_reaction_hand_focus(true, current_reaction_required_type, dodge_attacker_seat if is_current_reaction_slash else 0, current_reaction_allow_dodge_as_slash, is_current_reaction_slash)
				_select_dodge_card(null)
			elif selected_card_ui:
				_update_action_btn()
		else:
			desc_text.text = "💡 [Tiến Thoái]: Không có lá Trảm hoặc Đỡ nào trên tay để hoán đổi!"
	else:
		var skill_desc = ""
		if skills is Array and not skills.is_empty() and (skills[0] is Dictionary):
			skill_desc = skills[0].get("desc", "")
		desc_text.text = "📜 Kỹ năng của %s: %s" % [g.get("name", ""), skill_desc]

func _set_treasure_skill_selected(selected: bool) -> void:
	var avatar = generals_data.get(my_seat, {}).get("avatar_node")
	if is_instance_valid(avatar) and avatar.has_method("set_treasure_skill_selected"):
		avatar.set_treasure_skill_selected(selected)

func _clear_treasure_targeting() -> void:
	is_targeting_drum_skill = false
	is_targeting_ho_phu_skill = false
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
	selected_target_seat = -1
	card_play_btn.visible = false
	_set_treasure_skill_selected(false)

func _deal_initial_hands() -> void:
	for s_num in range(1, battle_seat_count + 1):
		var g = generals_data[s_num]
		for k in range(battle_seat_count):
			var card_info = _draw_card_from_pile()
			if g["isPlayer"]:
				_add_card_to_player_hand(card_info)
			else:
				g["hand_cards"].append(card_info)
				g["hand_count"] = g["hand_cards"].size()
				_animate_draw_to_seat(s_num)
		g["avatar_node"].update_hand_count(g["hand_count"])

func _add_card_to_player_hand(c_info: Dictionary) -> void:
	var g = generals_data[my_seat]
	g["hand_count"] += 1
	g["avatar_node"].update_hand_count(g["hand_count"])

	if c_info.get("name", "") == "Hịch Tướng Sĩ" or int(c_info.get("subType", -1)) == 26:
		c_info["desc"] = "Bạn và 1 người khác bạn chọn, bỏ 1 lá để nhận Sục Sôi: 1 vòng không giới hạn Trảm, tầm đánh +1. Có thể đổi lá để rút lá khác."

	var card_ui = CardUIScene.instantiate()
	card_ui.position.x = hand_container.size.x
	card_ui.modulate.a = 0.0
	hand_container.add_child(card_ui)
	card_ui.setup_card_data(c_info["id"], c_info["name"], c_info["rank"], c_info["suit"], c_info["cat"], c_info["desc"], int(c_info.get("subType", -1)))
	card_ui.card_clicked.connect(func(_c): _on_player_hand_card_clicked(card_ui, c_info))
	var fade_in_tw = card_ui.create_tween()
	fade_in_tw.tween_property(card_ui, "modulate:a", 1.0, 0.18)
	_relayout_hand_cards()
	_animate_draw_to_seat(my_seat)
	AudioManager.play_card_draw()

func _clear_hung_suc_equipped_weapon_previews() -> void:
	for child in hand_container.get_children():
		if child.has_meta("hung_suc_equipped_preview"):
			selected_two_card_skill_nodes.erase(child)
			if selected_card_ui == child:
				selected_card_ui = null
			hand_container.remove_child(child)
			child.queue_free()
	_relayout_hand_cards()

func _clear_song_cung_equipped_previews() -> void:
	for child in hand_container.get_children():
		if child.has_meta("song_cung_equipped_preview"):
			selected_song_cung_card_nodes.erase(child)
			if selected_card_ui == child:
				selected_card_ui = null
			hand_container.remove_child(child)
			child.queue_free()
	_relayout_hand_cards()

func _refresh_song_cung_equipped_previews() -> void:
	if not is_waiting_song_cung or not generals_data.has(my_seat):
		return
	var desired: Dictionary = {}
	var equipment_cards = _get_local_equipment_cards_for_song_cung(generals_data[my_seat])
	if equipment_cards is Array:
		for equipment in equipment_cards:
			if equipment is Dictionary and not _is_song_cung_equipment(equipment):
				desired[str(equipment.get("id", ""))] = equipment
	for child in hand_container.get_children():
		if not child.has_meta("song_cung_equipped_preview"):
			continue
		var preview_id := str(child.get_meta("song_cung_equipped_preview"))
		if desired.has(preview_id):
			desired.erase(preview_id)
		else:
			selected_song_cung_card_nodes.erase(child)
			if selected_card_ui == child:
				selected_card_ui = null
			hand_container.remove_child(child)
			child.queue_free()
	for equipment_id in desired:
		var equipment: Dictionary = desired[equipment_id]
		var card_ui = CardUIScene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup_card_data(
			str(equipment.get("id", "")),
			_get_card_display_name(equipment),
			equipment.get("rank", 1),
			str(equipment.get("suit", "Spade")),
			int(equipment.get("category", 1)),
			str(equipment.get("desc", "")),
			int(equipment.get("subType", -1))
		)
		card_ui.set_meta("song_cung_equipped_preview", equipment_id)
		if card_ui.has_method("set_equipped_badge"):
			card_ui.set_equipped_badge(true)
		var c_info = {
			"id": equipment_id,
			"name": _get_card_display_name(equipment),
			"rank": equipment.get("rank", 1),
			"suit": str(equipment.get("suit", "Spade")),
			"cat": int(equipment.get("category", 1)),
			"desc": str(equipment.get("desc", "")),
			"subType": int(equipment.get("subType", -1)),
			"is_equipped": true,
			"card_node": card_ui
		}
		card_ui.card_clicked.connect(func(_c): _on_player_hand_card_clicked(card_ui, c_info))
	_relayout_hand_cards()

func _is_song_cung_equipment(equipment: Dictionary) -> bool:
	var equipment_name := _get_card_display_name(equipment).to_lower()
	var equipment_id := str(equipment.get("id", "")).to_lower()
	return "song cung" in equipment_name or "songcung" in equipment_id

func _get_local_equipment_cards_for_song_cung(g: Dictionary) -> Array:
	var equipment_cards = g.get("equipment_cards", [])
	var result: Array = equipment_cards.duplicate(true) if equipment_cards is Array else []
	var known_names: Dictionary = {}
	for equipment in result:
		if equipment is Dictionary:
			known_names[_get_card_display_name(equipment).to_lower()] = true
	# Older local sessions only tracked slot names. Rebuild lightweight cards so
	# Song Cung can still offer those equipped slots as costs.
	var slots = [
		["equipped_weapon", 6],
		["equipped_armor", 7],
		["equipped_def_horse", 9],
		["equipped_off_horse", 8],
		["equipped_treasure", 27]
	]
	for slot in slots:
		var item_name := str(g.get(slot[0], "")).strip_edges()
		if item_name.is_empty() or known_names.has(item_name.to_lower()):
			continue
		var fallback_card := {
			"id": "LOCAL_EQUIP_%s" % slot[0],
			"name": item_name,
			"category": 1,
			"subType": int(slot[1]),
			"desc": ""
		}
		result.append(fallback_card)
		known_names[item_name.to_lower()] = true
	return result

func _record_local_equipment_card(card_info: Dictionary) -> void:
	if not generals_data.has(my_seat):
		return
	var g = generals_data[my_seat]
	var equipment_cards: Array = g.get("equipment_cards", []).duplicate(true)
	var new_card := card_info.duplicate(true)
	new_card["category"] = int(new_card.get("cat", new_card.get("category", 1)))
	new_card["subType"] = int(new_card.get("subType", -1))
	new_card["name"] = str(new_card.get("name", ""))
	var subtype := int(new_card.get("subType", -1))
	if subtype != 6:
		for i in range(equipment_cards.size() - 1, -1, -1):
			if equipment_cards[i] is Dictionary and int(equipment_cards[i].get("subType", -1)) == subtype:
				equipment_cards.remove_at(i)
	equipment_cards.append(new_card)
	g["equipment_cards"] = equipment_cards

func _refresh_hung_suc_equipped_weapon_previews() -> void:
	if not (is_targeting_hung_suc or is_targeting_cai_cach or is_targeting_binh_san) or not generals_data.has(my_seat):
		return
	var desired_weapons: Dictionary = {}
	var equipment_cards = generals_data[my_seat].get("equipment_cards", [])
	if equipment_cards is Array:
		for equipment in equipment_cards:
			if equipment is Dictionary and (is_targeting_cai_cach or is_targeting_binh_san or int(equipment.get("subType", -1)) == 6):
				desired_weapons[str(equipment.get("id", ""))] = equipment
	for child in hand_container.get_children():
		if child.has_meta("hung_suc_equipped_preview"):
			var preview_id := str(child.get_meta("hung_suc_equipped_preview"))
			if desired_weapons.has(preview_id):
				desired_weapons.erase(preview_id)
			else:
				if selected_card_ui == child:
					selected_card_ui = null
				hand_container.remove_child(child)
				child.queue_free()
	for weapon_id in desired_weapons:
		var equipment: Dictionary = desired_weapons[weapon_id]
		var card_ui = CardUIScene.instantiate()
		hand_container.add_child(card_ui)
		card_ui.setup_card_data(
			str(equipment.get("id", "")),
			_get_card_display_name(equipment),
			equipment.get("rank", 1),
			str(equipment.get("suit", "Spade")),
			int(equipment.get("category", 1)),
			str(equipment.get("desc", "")),
			int(equipment.get("subType", 6))
		)
		card_ui.set_meta("hung_suc_equipped_preview", str(equipment.get("id", "")))
		if card_ui.has_method("set_equipped_badge"):
			card_ui.set_equipped_badge(true)
		var c_info = {
			"id": str(equipment.get("id", "")),
			"name": _get_card_display_name(equipment),
			"rank": equipment.get("rank", 1),
			"suit": str(equipment.get("suit", "Spade")),
			"cat": int(equipment.get("category", 1)),
			"desc": str(equipment.get("desc", "")),
			"subType": int(equipment.get("subType", 6)),
			"is_equipped": true,
			"card_node": card_ui
		}
		card_ui.card_clicked.connect(func(_c): _on_player_hand_card_clicked(card_ui, c_info))
	_relayout_hand_cards()

func _on_player_hand_card_clicked(card_node: Control, c_info: Dictionary) -> void:
	if is_waiting_song_cung:
		_handle_song_cung_card_selection(card_node)
		return
	if is_waiting_thuy_trieu_rut_give:
		_select_dodge_card(card_node)
		return
	if is_waiting_rescue:
		_handle_rescue_hand_card_selection(card_node, c_info)
		return
	if is_waiting_dodge:
		_handle_dodge_hand_card_selection(card_node, c_info)
		return
	if is_network_mode and current_server_phase not in ["PLAY", "AWAIT_HUYNH_TRUONG", "AWAIT_DA_TRACH_DISCARD", "AWAIT_VAN_SACH", "AWAIT_NGHICH_Y"] and not is_discard_phase:
		card_play_btn.visible = false
		_clear_normal_hand_selection()
		return
	if not is_player_turn and not is_discard_phase:
		if current_server_phase not in ["AWAIT_DA_TRACH_DISCARD", "AWAIT_VAN_SACH", "AWAIT_NGHICH_Y"] or current_waiting_seat != my_seat:
			return
	if current_server_phase == "AWAIT_DA_TRACH_DISCARD" and current_waiting_seat == my_seat:
		if selected_card_ui and is_instance_valid(selected_card_ui) and selected_card_ui != card_node:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if current_server_phase == "AWAIT_VAN_SACH" and current_waiting_seat == my_seat:
		if selected_card_ui and is_instance_valid(selected_card_ui) and selected_card_ui != card_node:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_dan_cau:
		if selected_card_ui and is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_thuy_chien:
		var suit = str(c_info.get("suit", ""))
		if _get_card_color(suit) not in ["WHITE", "YELLOW"]:
			desc_text.text = "⚠️ Thủy Chiến chỉ dùng lá bài Trắng hoặc bài Vàng."
			return
		if selected_card_ui and is_instance_valid(selected_card_ui): selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_nghich_y:
		if selected_card_ui and is_instance_valid(selected_card_ui): selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		selected_nghich_y_card_id = str(c_info.get("id", ""))
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_thien_cam:
		if int(c_info.get("cat", c_info.get("category", -1))) != 3:
			desc_text.text = "⚠️ [THIÊN CẢM] chỉ chọn Cẩm Nang Trì Hoãn."
			return
		if selected_card_ui and is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_binh_san:
		if int(c_info.get("cat", c_info.get("category", -1))) != 1 and not card_node.has_meta("hung_suc_equipped_preview"):
			desc_text.text = "⚠️ [BÌNH SẠN] chỉ bỏ được lá trang bị."
			return
		if selected_card_ui and is_instance_valid(selected_card_ui) and selected_card_ui != card_node:
			selected_card_ui.set_selected(false)
		selected_card_ui = card_node
		card_node.set_selected(true)
		_update_action_btn()
		return
	if is_targeting_tay_phu:
		if card_node.has_meta("hung_suc_equipped_preview"):
			desc_text.text = "⚠️ [TÂY PHU] chỉ chọn lá đang có trên tay."
			return
		if card_node in selected_two_card_skill_nodes:
			selected_two_card_skill_nodes.erase(card_node)
			card_node.set_selected(false)
		elif selected_two_card_skill_nodes.size() < 2:
			selected_two_card_skill_nodes.append(card_node)
			card_node.set_selected(true)
		else:
			desc_text.text = "⚠️ [TÂY PHU] chỉ chọn đúng 2 lá."
		_update_action_btn()
		return
	if is_targeting_van_an or is_targeting_cai_cach:
		if card_node in selected_two_card_skill_nodes:
			selected_two_card_skill_nodes.erase(card_node)
			card_node.set_selected(false)
		elif selected_two_card_skill_nodes.size() < 2:
			selected_two_card_skill_nodes.append(card_node)
			card_node.set_selected(true)
		else:
			card_node.set_selected(false)
			desc_text.text = "⚠️ Kỹ năng này chỉ chọn đúng 2 lá."
			return
		_update_action_btn()
		return
	if lien_chau_target_seat > 0:
		if card_node == selected_card_ui:
			desc_text.text = "🏹 Liên Châu cần chọn 1 lá khác để bỏ."
			return
		if lien_chau_cost_card and is_instance_valid(lien_chau_cost_card):
			lien_chau_cost_card.set_selected(false)
		lien_chau_cost_card = card_node
		card_node.set_selected(true)
		desc_text.text = "🏹 Đã chọn lá phí Liên Châu. Nhấn nút để Trảm 2 mục tiêu."
		_update_action_btn()
		return

	# Giai đoạn bỏ bài thừa: Chọn / Bỏ chọn nhiều lá cùng một lúc (Multi-select)
	if is_discard_phase:
		if selected_discard_nodes.has(card_node):
			selected_discard_nodes.erase(card_node)
			if card_node.has_method("set_selected"):
				card_node.set_selected(false)
			AudioManager.play_card_select()
		else:
			if selected_discard_nodes.size() < cards_to_discard_count:
				selected_discard_nodes.append(card_node)
				if card_node.has_method("set_selected"):
					card_node.set_selected(true)
				AudioManager.play_card_select()
			else:
				if card_node.has_method("set_selected"):
					card_node.set_selected(false)
				desc_text.text = "⚠️ Bạn đã chọn đủ %d lá! Hãy bấm nút [BỎ BÀI] để xác nhận, hoặc nhấp lại lá bài đã chọn để đổi." % cards_to_discard_count
				AudioManager.play_skill()

		var chosen_count = selected_discard_nodes.size()
		card_play_btn.visible = true
		card_play_btn.text = "🗑️ BỎ BÀI (%d/%d)" % [chosen_count, cards_to_discard_count]
		card_play_btn.disabled = (chosen_count == 0)
		if chosen_count == cards_to_discard_count:
			desc_text.text = "💡 Đã chọn đủ %d lá! Bấm nút [BỎ BÀI (%d/%d)] để xác nhận và kết thúc lượt." % [chosen_count, chosen_count, cards_to_discard_count]
		else:
			desc_text.text = "⚠️ Hãy nhấp chọn thêm %d lá nữa (%d/%d) để bỏ bài thừa." % [cards_to_discard_count - chosen_count, chosen_count, cards_to_discard_count]
		return

	if selected_card_ui == card_node:
		# Deselect
		_clear_borrow_sword_targets()
		_clear_lien_chau_selection()
		selected_card_ui = null
		if not selected_chain_seats.is_empty():
			selected_chain_seats.clear()
			_update_chain_target_highlights()
		desc_text.text = "💡 Chạm chọn một lá bài trên tay để xem mô tả & sử dụng..."
		_update_action_btn()
		return

	# Select new card
	_clear_borrow_sword_targets()
	_clear_lien_chau_selection()
	# Bảo vật giữ trạng thái kích hoạt khi người chơi chọn mục tiêu hoặc lá bài.
	for other_card in hand_container.get_children():
		if other_card != card_node and other_card.has_method("set_selected"):
			other_card.set_selected(false)

	selected_card_ui = card_node
	selected_card_ui.set_selected(true)
	AudioManager.play_card_select()

	var c_name = c_info.get("name", "")
	var c_desc = _get_card_description_for_display(card_node, c_info)
	var suit = c_info.get("suit", "")
	var rank = c_info.get("rank", 1)

	if c_name == "Xích Tâm Tỏa":
		selected_chain_seats.clear()
		_update_chain_target_highlights()
	else:
		if not selected_chain_seats.is_empty():
			selected_chain_seats.clear()
			_update_chain_target_highlights()
	if c_name == "Mượn Gươm Diệt Địch":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1

	var s_name = _get_suit_name(suit)
	var r_str = _format_rank(rank)
	var card_color_tag = "%s %s" % [r_str, s_name] if not s_name.is_empty() else r_str
	desc_text.text = "🎴 [%s] %s: %s" % [card_color_tag, c_name, c_desc]

	_update_action_btn()

func _handle_dodge_hand_card_selection(card_node: Control, _c_info: Dictionary) -> void:
	if not is_waiting_dodge:
		return
	if is_waiting_oai_nhuoc:
		_handle_oai_nhuoc_card_selection(card_node)
		return
	var is_valid = _is_card_valid_for_reaction(
		card_node,
		current_reaction_required_type,
		dodge_attacker_seat if is_current_reaction_slash else 0,
		current_reaction_allow_dodge_as_slash,
		is_current_reaction_slash
	)
	if is_valid:
		_select_dodge_card(card_node)
	else:
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
		var info = _get_card_info_from_ui(card_node)
		var c_name = info.get("name", "Lá bài")
		var atk = generals_data.get(dodge_attacker_seat, {}) if is_current_reaction_slash else {}
		var slash_suit = atk.get("last_slash_suit", "") if is_current_reaction_slash else ""
		var card_suit = info.get("suit", "")
		if is_current_reaction_slash and _has_equipped_weapon_name(atk, "Súng Thần Công Hồ Triều") and slash_suit != "" and _is_same_card_color(card_suit, slash_suit):
			var forbidden_color = _get_suit_name(slash_suit).to_upper()
			desc_text.text = "❌ Súng Thần Công không cho phép bạn dùng Đỡ bài %s cho lượt Trảm này!" % forbidden_color
		else:
			var required_label = _get_reaction_required_label(current_reaction_required_type)
			desc_text.text = "❌ Lá [%s] không thể dùng cho phản ứng này! Hãy chạm lá [%s] hợp lệ trên tay." % [c_name, required_label]
		AudioManager.play_skill()

func _handle_rescue_hand_card_selection(card_node: Control, _c_info: Dictionary) -> void:
	if not is_waiting_rescue:
		return
	var info = _get_card_info_from_ui(card_node)
	var c_name = info.get("name", "")
	var is_valid = _is_card_valid_for_reaction(card_node, "Cứu")

	if is_valid:
		if rescue_card_to_use and is_instance_valid(rescue_card_to_use) and rescue_card_to_use != card_node:
			if rescue_card_to_use.has_method("set_selected"):
				rescue_card_to_use.set_selected(false)
		rescue_card_to_use = card_node
		if card_node.has_method("set_selected"):
			card_node.set_selected(true)
		AudioManager.play_card_select()
		var suit_sym = _get_suit_icon(info.get("suit", ""))
		var rank_str = _format_rank(info.get("rank", 1))
		rescue_confirm_btn.text = "🍲 DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name.to_upper()]
		rescue_confirm_btn.disabled = false
		var req_msg = _get_rescue_requirement_text(rescue_victim_seat)
		rescue_desc_lbl.text = "%s\n👉 Đã chọn lá [%s %s %s]. Bấm nút CỨU để xác nhận!" % [req_msg, suit_sym, rank_str, c_name]
		desc_text.text = "🍲 Đã chọn lá [%s %s %s]. Bấm nút CỨU để xác nhận!" % [suit_sym, rank_str, c_name]
	else:
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
		var req_label = "Bánh Chưng hoặc Hủ Rượu" if rescue_victim_seat == my_seat else "Bánh Chưng"
		desc_text.text = "❌ Lá [%s] không thể dùng để cứu! Hãy chọn lá [%s] trên tay." % [c_name, req_label]
		AudioManager.play_skill()

func _on_general_avatar_clicked(seat_num: int) -> void:
	if is_game_over:
		return

	var g = generals_data.get(seat_num, null)
	if not g or not g["is_alive"]:
		return
	if is_targeting_nghich_y:
		var nghich_active_card = NetworkClient.last_state.get("activeCard", {}) if NetworkClient and NetworkClient.last_state is Dictionary else {}
		var nghich_caster_seat = int(nghich_active_card.get("casterSeat", 0)) if nghich_active_card is Dictionary else 0
		if seat_num == my_seat or seat_num == nghich_caster_seat or _calculate_distance(my_seat, seat_num) > _get_attack_range(my_seat):
			desc_text.text = "⚠️ [NGHỊCH Ý] phải chọn người khác (không phải người ra Trảm) trong Tầm đánh."
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		_update_action_btn()
		return
	if is_targeting_chinh_thong or is_targeting_khoan_hoa or current_server_phase in ["AWAIT_AN_DAN_DUEL", "AWAIT_XUNG_VUONG_TARGET"]:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Hãy chọn một người chơi khác."
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		card_play_btn.visible = true
		card_play_btn.disabled = false
		card_play_btn.text = "📜 DÙNG CHÍNH THỐNG" if is_targeting_chinh_thong else ("🤝 CÙNG RÚT BÀI" if is_targeting_khoan_hoa else ("🏘️ CHỌN MỤC TIÊU HUYẾT CHIẾN" if current_server_phase == "AWAIT_AN_DAN_DUEL" else "👑 YÊU CẦU BỎ BÀI"))
		return

	if is_targeting_trieu_dang:
		if seat_num == my_seat:
			desc_text.text = "⚠️ [TRIỀU DÂNG] phải chọn một người khác."
			AudioManager.play_skill()
			return
		var has_equipment = not str(g.get("equipped_weapon", "")).is_empty() or not str(g.get("equipped_armor", "")).is_empty() or not str(g.get("equipped_def_horse", "")).is_empty() or not str(g.get("equipped_off_horse", "")).is_empty() or not str(g.get("equipped_treasure", "")).is_empty()
		if not has_equipment:
			desc_text.text = "⚠️ %s không có trang bị để [TRIỀU DÂNG] hủy." % g["name"]
			AudioManager.play_skill()
			return
		if selected_target_seat > 0 and selected_target_seat != seat_num and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		card_play_btn.text = "🌊 HỦY TRANG BỊ CỦA %s" % g["name"].to_upper()
		card_play_btn.disabled = false
		card_play_btn.visible = true
		desc_text.text = "🌊 [TRIỀU DÂNG] Chọn 1 trang bị của %s để hủy." % g["name"]
		AudioManager.play_card_select()
		return

	if is_targeting_dan_cau:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Dẫn Cầu phải chọn người khác."
			return
		if selected_target_seat <= 0:
			selected_target_seat = seat_num
			g["avatar_node"].set_target_highlight(true)
			desc_text.text = "🌉 Đã chọn người bị ép. Chọn tiếp mục tiêu Trảm."
		else:
			if seat_num == selected_target_seat:
				g["avatar_node"].set_target_highlight(false)
				if dan_cau_forced_target_seat > 0 and generals_data.has(dan_cau_forced_target_seat):
					generals_data[dan_cau_forced_target_seat]["avatar_node"].set_target_highlight(false)
				dan_cau_forced_target_seat = -1
				selected_target_seat = -1
				desc_text.text = "🌉 Đã hủy người bị ép. Chọn lại mục tiêu."
				_update_action_btn()
				return
			if seat_num == dan_cau_forced_target_seat:
				g["avatar_node"].set_target_highlight(false)
				dan_cau_forced_target_seat = -1
				desc_text.text = "🌉 Đã hủy mục tiêu Trảm. Chọn lại mục tiêu."
				_update_action_btn()
				return
			if dan_cau_forced_target_seat > 0 and generals_data.has(dan_cau_forced_target_seat):
				generals_data[dan_cau_forced_target_seat]["avatar_node"].set_target_highlight(false)
			dan_cau_forced_target_seat = seat_num
			g["avatar_node"].set_target_highlight(true)
			desc_text.text = "🌉 Đã chọn mục tiêu Trảm."
		_update_action_btn()
		return

	if is_targeting_thuy_chien:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Thủy Chiến phải chọn người khác."
			return
		if _hero_has_skill(g, "thuy_chien"):
			desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % g["name"]
			return
		if g.get("hp", 0) <= 1 and _hero_has_skill(g, "thien_cam"):
			desc_text.text = "⚠️ %s có [Thiên Cảm] (Máu ≤ 1), miễn nhiễm Cẩm Nang Trì Hoãn!" % g["name"]
			return
		if g.get("has_bai_coc", false):
			desc_text.text = "⚠️ %s đã có Bãi Cọc Bạch Đằng!" % g["name"]
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		_update_action_btn()
		return

	if is_targeting_bat_na or is_targeting_hung_suc or is_targeting_van_an or is_targeting_binh_san or is_targeting_tay_phu or huynh_truong_pending:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Kỹ năng này phải chọn một người khác."
			return
		if is_targeting_hung_suc and _calculate_distance(my_seat, seat_num) > 1:
			desc_text.text = "⚠️ [HÙNG SỨC] mục tiêu phải ở trong Tầm 1."
			return
		if is_targeting_van_an and selected_two_card_skill_nodes.size() != 2:
			desc_text.text = "⚠️ [VẠN AN] cần chọn đúng 2 lá bài trước."
			return
		if is_targeting_van_an and _hero_has_skill(g, "thuy_chien"):
			desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % g["name"]
			return
		if is_targeting_van_an and g.get("hp", 0) <= 1 and _hero_has_skill(g, "thien_cam"):
			desc_text.text = "⚠️ %s có [Thiên Cảm] (Máu ≤ 1), miễn nhiễm Cẩm Nang Trì Hoãn!" % g["name"]
			return
		if is_targeting_van_an and g.get("has_bai_coc", false):
			desc_text.text = "⚠️ %s đã có Bãi Cọc Bạch Đằng!" % g["name"]
			return
		if selected_target_seat > 0 and selected_target_seat != seat_num and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		_update_action_btn()
		return

	if uat_khi_pending:
		if seat_num == my_seat or int(g.get("hp", 0)) <= 0 or not g.get("is_alive", false):
			_show_toast("Chỉ có thể chọn người chơi khác còn sống!")
			return
		_clear_uat_khi_selection()
		uat_khi_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		card_play_btn.text = "💢 CHO %s HỒI 1 MÁU & RÚT 2 LÁ" % g["name"].to_upper()
		card_play_btn.disabled = false
		card_play_btn.visible = true
		desc_text.text = "💢 [UẤT KHÍ] Chọn %s hồi 1 máu và rút 2 lá bài." % g["name"]
		AudioManager.play_card_select()
		return

	if is_targeting_ho_phu_skill:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Hổ Phù phải giao bài cho một tướng khác."
			AudioManager.play_skill()
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		AudioManager.play_card_select()
		desc_text.text = "🐯 Đã chọn %s. Chọn 1 lá trên tay để giao, rồi nhấn [GIAO BÀI]." % g["name"]
		_update_action_btn()
		return

	if is_targeting_drum_skill:
		if seat_num == my_seat:
			desc_text.text = "⚠️ Không thể tự dùng Điểm Trống lên chính mình!"
			AudioManager.play_skill()
			return
		if not g["is_alive"]:
			desc_text.text = "⚠️ Mục tiêu đã tử trận!"
			AudioManager.play_skill()
			return
		var h_count = int(g.get("hand_count", 0))
		if h_count <= 0 and g.get("hand_cards", []).is_empty():
			desc_text.text = "⚠️ %s không có bài trên tay để Điểm Trống!" % g["name"]
			AudioManager.play_skill()
			return
		if selected_target_seat == seat_num:
			desc_text.text = "🥁 Đã chọn %s. Bấm [DÙNG TRỐNG ĐỒNG] để kích hoạt." % g["name"]
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = seat_num
		g["avatar_node"].set_target_highlight(true)
		AudioManager.play_card_select()
		card_play_btn.text = "🥁 DÙNG TRỐNG ĐỒNG ➜ %s" % g["name"]
		card_play_btn.disabled = false
		card_play_btn.visible = true
		desc_text.text = "🥁 [TRỐNG ĐỒNG]: Đã chọn %s. Nhấn [DÙNG TRỐNG ĐỒNG] để kích hoạt." % g["name"]
		return

	# Handle Xích Tâm Tỏa direct targeting on the battlefield (Unity Battle2v2UI.cs:9808-9828)
	if selected_card_ui and is_instance_valid(selected_card_ui):
		var cur_info = _get_card_info_from_ui(selected_card_ui)
		if cur_info.get("name", "") == "Xích Tâm Tỏa":
			AudioManager.play_card_select()
			if seat_num in selected_chain_seats:
				selected_chain_seats.erase(seat_num)
				_add_log("⛓️ Đã bỏ chọn tướng <b>%s</b>." % g["name"])
			else:
				if selected_chain_seats.size() >= 2:
					selected_chain_seats.pop_front() # Shift oldest target smoothly, exactly like Unity
				selected_chain_seats.append(seat_num)
				_add_log("⛓️ Đã chọn tướng <b>%s</b> (%d/2)." % [g["name"], selected_chain_seats.size()])

			_update_chain_target_highlights()
			_update_action_btn()
			return

		if cur_info.get("name", "") == "Mượn Gươm Diệt Địch":
			if borrow_sword_owner_seat < 0:
				if seat_num == my_seat:
					desc_text.text = "⚠️ Không thể chọn chính mình làm người bị Mượn Gươm."
					return
				if str(g.get("equipped_weapon", "")).is_empty():
					desc_text.text = "⚠️ Chỉ chọn Tướng đang trang bị Vũ khí để Mượn Gươm!"
					return
				borrow_sword_owner_seat = seat_num
				borrow_sword_target_seat = -1
				g["avatar_node"].set_target_highlight(true)
				desc_text.text = "🗡️ Đã chọn %s. Chạm 1 Tướng khác để chọn mục tiêu bị buộc Trảm." % g["name"]
			elif seat_num == borrow_sword_owner_seat:
				borrow_sword_owner_seat = -1
				borrow_sword_target_seat = -1
				_update_borrow_sword_target_highlights()
				desc_text.text = "🗡️ Đã bỏ chọn người có Vũ khí."
			else:
				var sword_owner = generals_data.get(borrow_sword_owner_seat, {})
				if not (sword_owner is Dictionary) or str(sword_owner.get("equipped_weapon", "")).is_empty():
					desc_text.text = "⚠️ Tướng được chọn không còn trang bị Vũ khí!"
					_clear_borrow_sword_targets()
					_update_action_btn()
					return
				var weapon_range = _get_attack_range(borrow_sword_owner_seat)
				var forced_distance = _calculate_distance(borrow_sword_owner_seat, seat_num)
				if forced_distance > weapon_range:
					desc_text.text = "⚠️ %s cách %d, vượt tầm vũ khí %d của %s!" % [g["name"], forced_distance, weapon_range, sword_owner["name"]]
					return
				if _is_da_trach_slash_blocked(seat_num):
					desc_text.text = "🌙 [DẠ TRẠCH] %s không có bài trên tay nên không thể bị Trảm!" % g["name"]
					return
				borrow_sword_target_seat = seat_num
				_update_borrow_sword_target_highlights()
				desc_text.text = "🗡️ %s sẽ bị buộc dùng Vũ khí đánh %s. Có thể bấm nút xác nhận." % [
					generals_data[borrow_sword_owner_seat]["name"], g["name"]
				]
			_update_action_btn()
			return

	# Don't target self for attack or invalid scroll target
	if selected_card_ui:
		var c_info = _get_card_info_from_ui(selected_card_ui)
		var c_name = c_info.get("name", "")
		if seat_num == my_seat and "Trảm" in c_name:
			return
		if c_name == "Bãi Cọc Bạch Đằng":
			if seat_num == my_seat:
				desc_text.text = "⚠️ Không thể tự gài Bãi Cọc Bạch Đằng lên chính mình!"
				return
			if _hero_has_skill(g, "thuy_chien"):
				desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % g["name"]
				return
			if g.get("hp", 0) <= 1 and _hero_has_skill(g, "thien_cam"):
				desc_text.text = "⚠️ %s có [Thiên Cảm] (Máu ≤ 1), miễn nhiễm Cẩm Nang Trì Hoãn!" % g["name"]
				return
			if g.get("has_bai_coc", false):
				desc_text.text = "⚠️ %s đã có Bãi Cọc Bạch Đằng!" % g["name"]
				return
	if selected_card_ui and selected_target_seat > 0 and seat_num != selected_target_seat:
		var slash_info = _get_card_info_from_ui(selected_card_ui)
		var me = generals_data.get(my_seat, {})
		if is_selecting_lien_chau_target and "Trảm" in str(slash_info.get("name", "")) and _can_use_lien_chau(me) and _has_no_than(me):
			if seat_num == my_seat or not g.get("is_alive", false) or _calculate_distance(my_seat, seat_num) > _get_attack_range(my_seat):
				desc_text.text = "⚠️ Mục tiêu Liên Châu phải còn sống, khác bạn và trong tầm đánh."
				return
			lien_chau_target_seat = seat_num
			g["avatar_node"].set_target_highlight(true)
			desc_text.text = "🏹 Liên Châu: chọn 1 lá khác trên tay để bỏ."
			_update_action_btn()
			return

	# Clear previous target border
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)

	selected_target_seat = seat_num
	g["avatar_node"].set_target_highlight(true)
	_update_action_btn()

func _update_chain_target_highlights() -> void:
	for s in range(1, battle_seat_count + 1):
		if generals_data.has(s) and generals_data[s].has("avatar_node") and is_instance_valid(generals_data[s]["avatar_node"]):
			var is_sel = (s in selected_chain_seats)
			generals_data[s]["avatar_node"].set_target_highlight(is_sel)

func _update_borrow_sword_target_highlights() -> void:
	for s in range(1, battle_seat_count + 1):
		if generals_data.has(s) and generals_data[s].has("avatar_node") and is_instance_valid(generals_data[s]["avatar_node"]):
			var is_selected = s == borrow_sword_owner_seat or s == borrow_sword_target_seat
			generals_data[s]["avatar_node"].set_target_highlight(is_selected)

func _clear_borrow_sword_targets() -> void:
	for s in [borrow_sword_owner_seat, borrow_sword_target_seat]:
		if s > 0 and generals_data.has(s) and generals_data[s].has("avatar_node") and is_instance_valid(generals_data[s]["avatar_node"]):
			generals_data[s]["avatar_node"].set_target_highlight(false)
	borrow_sword_owner_seat = -1
	borrow_sword_target_seat = -1

func _get_card_info_from_ui(ui_node: Control) -> Dictionary:
	if not ui_node or not is_instance_valid(ui_node):
		return {}
	var c_name = ui_node.get("card_name")
	var suit = ""
	var rank = 1
	var desc = ""
	var cat = 0
	var id = ""
	if ui_node.get("card_data") and ui_node.card_data != null:
		if c_name == null or c_name == "":
			c_name = ui_node.card_data.card_name
		suit = ui_node.card_data.suit
		rank = ui_node.card_data.rank
		desc = ui_node.card_data.description
		cat = ui_node.card_data.category
		id = ui_node.card_data.id
	return {
		"id": id,
		"name": c_name if c_name != null else "",
		"suit": suit,
		"rank": rank,
		"desc": desc,
		"cat": cat,
		"subType": ui_node.card_data.sub_type if ui_node.get("card_data") and ui_node.card_data != null else -1,
		"is_equipped": ui_node.has_meta("hung_suc_equipped_preview") or ui_node.has_meta("song_cung_equipped_preview"),
		"card_node": ui_node
	}

func _get_card_description_for_display(card_node: Control, c_info: Dictionary) -> String:
	# Use the same card resource as the hover tooltip.
	var card_data = card_node.get("card_data") if card_node and is_instance_valid(card_node) else null
	var card_name := str(c_info.get("name", ""))
	var card_id := str(c_info.get("id", ""))
	var description := ""
	if card_data != null:
		if card_name.is_empty():
			card_name = str(card_data.get("card_name"))
		description = str(card_data.description)
	if description.is_empty() and not str(c_info.get("desc", "")).is_empty():
		description = str(c_info.get("desc"))
	if description.is_empty() and CardDatabase and not card_id.is_empty():
		var database_card = CardDatabase.get_card(card_id)
		if database_card != null and not str(database_card.description).is_empty():
			description = str(database_card.description)
	if description.is_empty() and not card_name.is_empty():
		var database_info = _find_card_dict_by_name(card_name)
		description = str(database_info.get("desc", database_info.get("description", "")))
	return description if not description.is_empty() else card_name

func _update_action_btn() -> void:
	hich_recast_btn.visible = false
	if current_server_phase == "AWAIT_DA_TRACH_DISCARD" and current_waiting_seat == my_seat:
		var da_trach_ready := selected_card_ui != null and is_instance_valid(selected_card_ui)
		card_play_btn.visible = true
		card_play_btn.disabled = not da_trach_ready
		card_play_btn.text = "🌙 BỎ 1 LÁ" if da_trach_ready else "🌙 CHỌN 1 LÁ ĐỂ BỎ"
		return
	if current_server_phase == "AWAIT_VAN_SACH" and current_waiting_seat == my_seat:
		var van_sach_card_valid := selected_card_ui != null and is_instance_valid(selected_card_ui)
		card_play_btn.visible = true
		card_play_btn.disabled = not van_sach_card_valid
		card_play_btn.text = "📚 BỎ LÁ ĐỂ RÚT 1 LÁ" if van_sach_card_valid else "📚 CHỌN 1 LÁ ĐỂ BỎ"
		return
	if is_targeting_chinh_thong and current_server_phase == "AWAIT_CHINH_THONG_TARGET" and current_waiting_seat == my_seat:
		var chinh_thong_ready: bool = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and bool(generals_data[selected_target_seat].get("is_alive", false))
		card_play_btn.visible = true
		card_play_btn.disabled = not chinh_thong_ready
		card_play_btn.text = "📜 DÙNG CHÍNH THỐNG" if chinh_thong_ready else "📜 CHÍNH THỐNG: CHỌN 1 NGƯỜI"
		return
	if is_targeting_khoan_hoa and current_server_phase == "AWAIT_KHOAN_HOA" and current_waiting_seat == my_seat:
		var khoan_hoa_ready: bool = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and bool(generals_data[selected_target_seat].get("is_alive", false))
		card_play_btn.visible = true
		card_play_btn.disabled = not khoan_hoa_ready
		card_play_btn.text = "🤝 CÙNG RÚT BÀI" if khoan_hoa_ready else "🤝 KHOAN HÒA: CHỌN 1 NGƯỜI"
		return
	if current_server_phase == "AWAIT_XUNG_VUONG_TARGET" and current_waiting_seat == my_seat:
		var xung_vuong_ready: bool = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and bool(generals_data[selected_target_seat].get("is_alive", false))
		card_play_btn.visible = true
		card_play_btn.disabled = not xung_vuong_ready
		card_play_btn.text = "👑 YÊU CẦU BỎ BÀI" if xung_vuong_ready else "👑 XƯNG VƯƠNG: CHỌN 1 NGƯỜI"
		return
	if is_targeting_van_an:
		var van_an_ready := selected_two_card_skill_nodes.size() == 2 and selected_target_seat > 0 and selected_target_seat != my_seat
		card_play_btn.visible = true
		card_play_btn.disabled = not van_an_ready
		card_play_btn.text = "🏯 DÙNG VẠN AN" if van_an_ready else "🏯 VẠN AN: CHỌN 2 LÁ VÀ MỤC TIÊU"
		return
	if is_targeting_dan_cau:
		var dan_ready := selected_card_ui != null and is_instance_valid(selected_card_ui) and selected_target_seat > 0 and dan_cau_forced_target_seat > 0
		card_play_btn.visible = true
		card_play_btn.disabled = not dan_ready
		card_play_btn.text = "🌉 DÙNG DẪN CẦU" if dan_ready else "🌉 DẪN CẦU: CHỌN BÀI VÀ 2 MỤC TIÊU"
		return
	if is_targeting_thuy_chien:
		var thuy_ready := selected_card_ui != null and is_instance_valid(selected_card_ui) and selected_target_seat > 0
		card_play_btn.visible = true
		card_play_btn.disabled = not thuy_ready
		card_play_btn.text = "🌊 DÙNG THỦY CHIẾN" if thuy_ready else "🌊 THỦY CHIẾN: CHỌN BÀI VÀ MỤC TIÊU"
		return
	if is_targeting_nghich_y:
		var nghich_ready := not selected_nghich_y_card_id.is_empty() and selected_target_seat > 0
		card_play_btn.visible = true
		card_play_btn.disabled = not nghich_ready
		card_play_btn.text = "🌀 DÙNG NGHỊCH Ý" if nghich_ready else "🌀 NGHỊCH Ý: CHỌN BÀI VÀ MỤC TIÊU"
		return
	if is_targeting_thien_cam:
		var thien_cam_info := _get_card_info_from_ui(selected_card_ui) if selected_card_ui and is_instance_valid(selected_card_ui) else {}
		var thien_cam_ready := not thien_cam_info.is_empty() and int(thien_cam_info.get("cat", thien_cam_info.get("category", -1))) == 3
		card_play_btn.visible = true
		card_play_btn.disabled = not thien_cam_ready
		card_play_btn.text = "🌙 ĐỔI TRÌ HOÃN LẤY 2 LÁ" if thien_cam_ready else "🌙 THIÊN CẢM: CHỌN 1 CẨM NANG TRÌ HOÃN"
		return
	if is_targeting_binh_san:
		var binh_san_info := _get_card_info_from_ui(selected_card_ui) if selected_card_ui and is_instance_valid(selected_card_ui) else {}
		var binh_san_card_valid := not binh_san_info.is_empty() and (int(binh_san_info.get("cat", binh_san_info.get("category", -1))) == 1 or selected_card_ui.has_meta("hung_suc_equipped_preview"))
		var binh_san_target_valid := selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and bool(generals_data[selected_target_seat].get("is_alive", false))
		var binh_san_ready := binh_san_card_valid and binh_san_target_valid
		card_play_btn.visible = true
		card_play_btn.disabled = not binh_san_ready
		card_play_btn.text = "🪨 DÙNG BÌNH SẠN" if binh_san_ready else "🪨 BÌNH SẠN: CHỌN TRANG BỊ VÀ MỤC TIÊU"
		return
	if is_targeting_tay_phu:
		var tay_phu_ready := selected_two_card_skill_nodes.size() == 2 and selected_target_seat > 0 and selected_target_seat != my_seat
		card_play_btn.visible = true
		card_play_btn.disabled = not tay_phu_ready
		card_play_btn.text = "⚔️ DÙNG TÂY PHU" if tay_phu_ready else "⚔️ TÂY PHU: CHỌN 2 LÁ VÀ MỤC TIÊU"
		return
	if is_targeting_cai_cach:
		var cai_cach_ready := selected_two_card_skill_nodes.size() == 2
		card_play_btn.visible = true
		card_play_btn.disabled = not cai_cach_ready
		card_play_btn.text = "🔄 ĐỔI 2 LÁ" if cai_cach_ready else "🔄 CẢI CÁCH: CHỌN 2 LÁ TRÊN TAY/ĐANG MANG"
		return
	if is_targeting_hung_suc:
		var hung_target_valid = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false) and _calculate_distance(my_seat, selected_target_seat) <= 1
		var hung_card_valid = selected_card_ui != null and is_instance_valid(selected_card_ui)
		if hung_card_valid:
			var hung_card = _get_card_info_from_ui(selected_card_ui)
			hung_card_valid = int(hung_card.get("cat", -1)) == 1 and int(hung_card.get("subType", -1)) == 6
		card_play_btn.visible = true
		card_play_btn.disabled = not (hung_target_valid and hung_card_valid)
		card_play_btn.text = "💪 HÙNG SỨC ➜ %s" % generals_data[selected_target_seat]["name"] if hung_target_valid and hung_card_valid else "💪 HÙNG SỨC: CHỌN VŨ KHÍ VÀ MỤC TIÊU"
		return
	if is_targeting_van_sach:
		var van_sach_card_valid = selected_card_ui != null and is_instance_valid(selected_card_ui) and int(_get_card_info_from_ui(selected_card_ui).get("cat", -1)) == 0
		card_play_btn.visible = true
		card_play_btn.disabled = not van_sach_card_valid
		card_play_btn.text = "📚 ĐỔI BÀI BẰNG VĂN SÁCH" if van_sach_card_valid else "📚 VĂN SÁCH: CHỌN 1 BÀI CƠ BẢN"
		return
	if huynh_truong_pending:
		var huynh_target_valid = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false)
		var huynh_card_valid = selected_card_ui != null and is_instance_valid(selected_card_ui)
		card_play_btn.visible = true
		card_play_btn.disabled = not (huynh_target_valid and huynh_card_valid)
		card_play_btn.text = "🤝 ĐƯA BÀI ➜ %s" % generals_data[selected_target_seat]["name"] if huynh_target_valid and huynh_card_valid else "🤝 HUYNH TRƯỞNG: CHỌN TƯỚNG VÀ BÀI"
		return
	if is_targeting_bat_na:
		var bat_na_target_valid = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false)
		var bat_na_card_valid = selected_card_ui != null and is_instance_valid(selected_card_ui) and int(_get_card_info_from_ui(selected_card_ui).get("cat", -1)) == 0
		card_play_btn.visible = true
		card_play_btn.disabled = not (bat_na_target_valid and bat_na_card_valid)
		card_play_btn.text = "🎭 BÁT NẠ ➜ %s" % generals_data[selected_target_seat]["name"] if bat_na_target_valid and bat_na_card_valid else "🎭 BÁT NẠ: CHỌN BÀI CƠ BẢN VÀ MỤC TIÊU"
		return
	if is_targeting_ho_phu_skill:
		var ho_phu_target_valid = selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false)
		var ho_phu_card_valid = selected_card_ui != null and is_instance_valid(selected_card_ui)
		card_play_btn.visible = true
		card_play_btn.disabled = not (ho_phu_target_valid and ho_phu_card_valid)
		if ho_phu_target_valid and ho_phu_card_valid:
			var given_name = str(_get_card_info_from_ui(selected_card_ui).get("name", "lá bài"))
			card_play_btn.text = "🐯 GIAO [%s] ➜ %s" % [given_name.to_upper(), generals_data[selected_target_seat]["name"]]
		elif not ho_phu_target_valid:
			card_play_btn.text = "🐯 HỔ PHÙ: CHỌN TƯỚNG..."
		else:
			card_play_btn.text = "🐯 HỔ PHÙ: CHỌN 1 LÁ BÀI..."
		return
	if is_targeting_drum_skill:
		if selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt.get("is_alive", false):
				card_play_btn.text = "🥁 DÙNG TRỐNG ĐỒNG ➜ %s" % tgt["name"]
				card_play_btn.disabled = false
				card_play_btn.visible = true
				return
		card_play_btn.text = "🥁 DÙNG TRỐNG ĐỒNG: CHỌN MỤC TIÊU..."
		card_play_btn.disabled = true
		card_play_btn.visible = true
		return

	if not is_player_turn or selected_card_ui == null or is_waiting_dodge or is_waiting_rescue or (is_network_mode and current_server_phase != "PLAY"):
		card_play_btn.visible = false
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")
	card_play_btn.disabled = false

	if "Trảm" in c_name:
		if lien_chau_target_seat > 0 and generals_data.has(lien_chau_target_seat):
			card_play_btn.text = "🏹 LIÊN CHÂU ➜ %s & %s" % [generals_data[selected_target_seat]["name"], generals_data[lien_chau_target_seat]["name"]]
			card_play_btn.disabled = lien_chau_cost_card == null or not is_instance_valid(lien_chau_cost_card)
			card_play_btn.visible = true
			return
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt["is_alive"]:
				card_play_btn.text = "⚔️ %s ➜ %s" % [c_name.to_upper(), tgt["name"]]
				card_play_btn.visible = true
				return
		card_play_btn.text = "⚔️ CHỌN MỤC TIÊU..."
		card_play_btn.visible = true
	elif c_name == "Bánh Chưng":
		var p_gen = generals_data[my_seat]
		if p_gen["hp"] < p_gen["max_hp"]:
			card_play_btn.text = "🍲 DÙNG BÁNH CHƯNG (HỒI 1 MÁU)"
			card_play_btn.visible = true
		else:
			card_play_btn.text = "MÁU ĐÃ ĐẦY (KHÔNG THỂ DÙNG)"
			card_play_btn.visible = true
	elif c_name == "Hủ Rượu":
		card_play_btn.disabled = wine_used_this_turn
		card_play_btn.text = "🍶 ĐÃ UỐNG RƯỢU TRONG LƯỢT" if wine_used_this_turn else "🍶 UỐNG RƯỢU (+1 SÁT THƯƠNG)"
		card_play_btn.visible = true
	elif c_name == "Đỡ":
		# Đỡ chỉ hợp lệ trong pha phản ứng; trong lượt thường không có hành động để dùng.
		card_play_btn.visible = false
		desc_text.text = "🛡️ Lá Đỡ chỉ dùng khi bạn đang bị yêu cầu phản ứng."
		return
	elif c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		card_play_btn.text = "🗡️ TRANG BỊ VŨ KHÍ [%s]" % c_name
		card_play_btn.visible = true
	elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
		card_play_btn.text = "🛡️ TRANG BỊ ÁO GIÁP [%s]" % c_name
		card_play_btn.visible = true
	elif c_name == "Voi Chiến Đại Việt":
		card_play_btn.text = "🐘 TRANG BỊ NGỰA THỦ (+1 K/CÁCH)"
		card_play_btn.visible = true
	elif c_name == "Ngựa Trắng Thuần Nông":
		card_play_btn.text = "🐎 TRANG BỊ NGỰA CÔNG (-1 K/CÁCH)"
		card_play_btn.visible = true
	elif c_name == "Xích Tâm Tỏa":
		card_play_btn.visible = true
		if selected_chain_seats.is_empty():
			card_play_btn.disabled = false
			card_play_btn.text = "🔄 ĐỔI LÁ XÍCH (RÚT 1)"
			desc_text.text = "⛓️ " + IRON_CHAIN_DESCRIPTION
		elif selected_chain_seats.size() == 1:
			card_play_btn.disabled = false
			var n1 = generals_data[selected_chain_seats[0]]["name"].to_upper() if generals_data.has(selected_chain_seats[0]) else "TƯỚNG"
			card_play_btn.text = "⚔️ KHÓA/GỠ XÍCH [%s] (1/2)" % n1
			desc_text.text = "⛓️ %s Đã chọn 1 mục tiêu; chạm thêm tướng hoặc xác nhận." % IRON_CHAIN_DESCRIPTION
		else:
			card_play_btn.disabled = false
			var n1 = generals_data[selected_chain_seats[0]]["name"].to_upper() if generals_data.has(selected_chain_seats[0]) else "TƯỚNG 1"
			var n2 = generals_data[selected_chain_seats[1]]["name"].to_upper() if generals_data.has(selected_chain_seats[1]) else "TƯỚNG 2"
			card_play_btn.text = "⚔️ KHÓA/GỠ XÍCH [%s & %s] (2/2)" % [n1, n2]
			desc_text.text = "⛓️ %s Đã chọn 2 mục tiêu; nhấn xác nhận hoặc chạm avatar để đổi." % IRON_CHAIN_DESCRIPTION
	elif _is_dai_hong_thuy_name(c_name):
		card_play_btn.text = "🌊 ĐẶT [ĐẠI HỒNG THỦY] (VÀO BẢN THÂN)"
		card_play_btn.visible = true
	elif c_name == "Diệu Kế Phá Mưu":
		card_play_btn.text = "📜 CHỈ DÙNG KHI ĐƯỢC HỎI"
		card_play_btn.visible = true
	elif c_name == "Vườn Không Nhà Trống":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "🌾 PHÁ HỦY BÀI ➜ %s" % tgt["name"]
		else:
			card_play_btn.text = "🌾 CHỌN MỤC TIÊU ĐỂ PHÁ HỦY..."
		card_play_btn.visible = true
	elif c_name == "Đột Kích Trộm Lương":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			card_play_btn.text = "🗡️ CƯỚP BÀI ➜ %s" % tgt["name"]
		else:
			card_play_btn.text = "🗡️ CHỌN MỤC TIÊU ĐỂ CƯỚP..."
		card_play_btn.visible = true
	elif c_name == "Giặc Tới":
		card_play_btn.text = "🪵 GIẶC TỚI (TẤT CẢ NGƯỜI KHÁC)"
		card_play_btn.visible = true
	elif c_name == "Bãi Cọc Bạch Đằng":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			card_play_btn.text = "🪵 BÃI CỌC BẠCH ĐẰNG ➜ %s" % generals_data[selected_target_seat]["name"]
		else:
			card_play_btn.text = "🪵 CHỌN MỤC TIÊU ĐỂ GÀI BÃI CỌC..."
		card_play_btn.visible = true
	elif c_name == "Mưa Tên Liên Châu":
		card_play_btn.text = "🏹 MƯA TÊN LIÊN CHÂU (TẤT CẢ NGƯỜI KHÁC)"
		card_play_btn.visible = true
	elif c_name == "Huyết Chiến":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tgt = generals_data[selected_target_seat]
			if tgt["seat"] != my_seat and tgt["is_alive"]:
				card_play_btn.text = "⚔️ HUYẾT CHIẾN ➜ %s" % tgt["name"]
				card_play_btn.visible = true
				return
		card_play_btn.text = "⚔️ CHỌN MỤC TIÊU HUYẾT CHIẾN..."
		card_play_btn.visible = true
	elif c_name == "Mở Kho Cứu Tế":
		card_play_btn.text = "🌾 MỞ KHO CỨU TẾ (CHIA ĐỀU BÀI)"
		card_play_btn.visible = true
	elif c_name == "Dụng Binh Như Thần":
		card_play_btn.text = "📜 RÚT 2 LÁ BÀI (DỤNG BINH)"
		card_play_btn.visible = true
	elif c_name == "Thủy Triều Rút":
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			var tide_target = generals_data[selected_target_seat]
			if selected_target_seat != my_seat and tide_target.get("is_alive", false) and int(tide_target.get("hand_count", 0)) > 0:
				card_play_btn.text = "🌊 THỦY TRIỀU RÚT ➜ %s" % tide_target["name"]
			else:
				card_play_btn.disabled = true
				card_play_btn.text = "🌊 CHỌN MỤC TIÊU CÒN BÀI TAY..."
		else:
			card_play_btn.disabled = true
			card_play_btn.text = "🌊 CHỌN MỤC TIÊU THỦY TRIỀU RÚT..."
		card_play_btn.visible = true
	elif c_name == "Mượn Gươm Diệt Địch":
		if borrow_sword_owner_seat <= 0:
			card_play_btn.text = "🗡️ CHỌN NGƯỜI CÓ VŨ KHÍ..."
			card_play_btn.disabled = true
		elif borrow_sword_target_seat <= 0 or not generals_data.has(borrow_sword_target_seat):
			card_play_btn.text = "🗡️ TỪ %s ➜ CHỌN MỤC TIÊU" % generals_data[borrow_sword_owner_seat]["name"]
			card_play_btn.disabled = true
		else:
			card_play_btn.text = "🗡️ %s ➜ %s" % [
				generals_data[borrow_sword_owner_seat]["name"],
				generals_data[borrow_sword_target_seat]["name"]
			]
			card_play_btn.disabled = false
		card_play_btn.visible = true
	elif c_name == "Hịch Tướng Sĩ":
		hich_recast_btn.visible = true
		hich_recast_btn.disabled = false
		if selected_target_seat > 0 and selected_target_seat != my_seat and generals_data.has(selected_target_seat) and generals_data[selected_target_seat].get("is_alive", false):
			card_play_btn.text = "📣 HỊCH TƯỚNG SĨ ➜ %s" % generals_data[selected_target_seat]["name"]
		else:
			card_play_btn.disabled = true
			card_play_btn.text = "📣 CHỌN 1 NGƯỜI KHÁC CÒN SỐNG..."
		card_play_btn.visible = true
	elif c_name == "Mở Yến Tiệc":
		card_play_btn.text = "🍽️ MỞ YẾN TIỆC (HỒI 1 MÁU TOÀN BÀN)"
		card_play_btn.visible = true
	elif c_name == "Trống Đồng Đông Sơn":
		card_play_btn.text = "🥁 TRANG BỊ TRỐNG ĐỒNG ĐÔNG SƠN"
		card_play_btn.visible = true
	else:
		card_play_btn.text = "DÙNG [%s]" % c_name
		card_play_btn.visible = true

func _reset_player_turn_timer() -> void:
	if is_player_turn:
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node"):
			generals_data[my_seat]["avatar_node"].update_turn_timer(40)

func _on_hich_recast_btn_clicked() -> void:
	if not is_player_turn or not selected_card_ui or not is_instance_valid(selected_card_ui):
		return
	var c_info = _get_card_info_from_ui(selected_card_ui)
	if c_info.get("name", "") != "Hịch Tướng Sĩ":
		return
	var c_id = str(c_info.get("id", ""))
	if c_id.is_empty():
		desc_text.text = "⚠️ Không xác định được lá Hịch Tướng Sĩ để đổi."
		return

	_discard_player_card(selected_card_ui)
	selected_card_ui = null
	card_play_btn.visible = false
	hich_recast_btn.visible = false
	_reset_player_turn_timer()
	AudioManager.play_voice("Hịch Tướng Sĩ")
	AudioManager.play_skill()
	_broadcast_player_battle_action("PLAY_CARD", c_id, 0, my_seat, 0, [], true)
	_animate_showcase_card("Hịch Tướng Sĩ", "Bạn đổi Hịch Tướng Sĩ để rút 1 lá mới!", c_info)
	_add_log("🔄 Bạn đổi [Hịch Tướng Sĩ] để rút 1 lá bài khác.")
	if not is_network_mode:
		_add_card_to_player_hand(_draw_card_from_pile())
	# Thêm lá mới có thể làm cập nhật UI; không để nút đổi của lá Hịch cũ hiện lại.
	hich_recast_btn.visible = false
	hich_recast_btn.call_deferred("hide")

func _resolve_local_hich_tuong_si(target_seat: int) -> void:
	_prompt_reaction_modal(
		"📣 HỊCH TƯỚNG SĨ",
		"Chạm chọn 1 lá bài để bỏ và nhận Sục Sôi, hoặc bấm [BỎ QUA].",
		"Bỏ bài",
		"BỎ QUA",
		"📣 BỎ 1 LÁ NHẬN SỤC SÔI",
		40.0,
		false,
		true,
		false,
		false
	)
	custom_reaction_callback = func(accepted: bool, _card_info: Dictionary):
		var caster = generals_data.get(my_seat, {})
		if accepted:
			caster["suc_soi_turns_remaining"] = 1
			caster["hand_count"] = hand_container.get_child_count()
			caster["avatar_node"].update_hand_count(caster["hand_count"])
			_add_log("📣 Bạn bỏ 1 lá, nhận [SỤC SÔI].")
		else:
			_add_log("📣 Bạn từ chối nhận [SỤC SÔI].")

		var target = generals_data.get(target_seat, {})
		if not target.is_empty() and int(target.get("hand_count", 0)) > 0:
			target["hand_count"] -= 1
			if target.get("hand_cards", []) is Array and not target["hand_cards"].is_empty():
				target["hand_cards"].pop_back()
			target["suc_soi_turns_remaining"] = 1
			target["avatar_node"].update_hand_count(target["hand_count"])
			_animate_discard_from_seat(target_seat)
			_add_log("📣 %s bỏ 1 lá, nhận [SỤC SÔI]." % target["name"])
		else:
			_add_log("📣 %s không có bài để nhận [SỤC SÔI]." % target.get("name", "Mục tiêu"))

func _on_card_play_btn_clicked() -> void:
	if current_server_phase == "AWAIT_CHINH_THONG_TARGET" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0:
			desc_text.text = "⚠️ [CHÍNH THỐNG] cần chọn 1 người khác."
			return
		NetworkClient.send_use_skill("Chính Thống", selected_target_seat)
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_NGHICH_Y" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0 or selected_nghich_y_card_id.is_empty():
			desc_text.text = "⚠️ [NGHỊCH Ý] cần chọn 1 lá bỏ và 1 mục tiêu khác trong tầm đánh."
			return
		var nghich_card_id := selected_nghich_y_card_id
		if selected_card_ui and is_instance_valid(selected_card_ui):
			nghich_card_id = str(_get_card_info_from_ui(selected_card_ui).get("id", nghich_card_id))
		NetworkClient.send_use_skill("Nghịch Ý", selected_target_seat, nghich_card_id)
		is_targeting_nghich_y = false
		selected_nghich_y_card_id = ""
		if selected_card_ui and is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
			selected_card_ui = null
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		card_play_btn.disabled = true
		card_play_btn.visible = false
		end_turn_btn.disabled = true
		return
	if is_targeting_thien_cam:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [THIÊN CẢM] hãy chọn 1 Cẩm Nang Trì Hoãn trên tay."
			return
		var thien_card = _get_card_info_from_ui(selected_card_ui)
		if int(thien_card.get("cat", thien_card.get("category", -1))) != 3:
			desc_text.text = "⚠️ [THIÊN CẢM] chỉ chọn Cẩm Nang Trì Hoãn."
			return
		NetworkClient.send_use_skill("Thiên Cảm", 0, str(thien_card.get("id", "")))
		is_targeting_thien_cam = false
		selected_card_ui.set_selected(false)
		selected_card_ui = null
		card_play_btn.disabled = true
		_refresh_local_skill_buttons(my_seat)
		return
	if is_targeting_binh_san:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui) or selected_target_seat <= 0:
			desc_text.text = "⚠️ [BÌNH SẠN] cần chọn 1 trang bị để bỏ và 1 mục tiêu."
			return
		NetworkClient.send_use_skill("Bình Sạn", selected_target_seat, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		var binh_san_cost = selected_card_ui
		if binh_san_cost.has_meta("hung_suc_equipped_preview"):
			_clear_hung_suc_equipped_weapon_previews()
		else:
			_discard_player_card(binh_san_cost)
		is_targeting_binh_san = false
		if is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
		selected_card_ui = null
		selected_target_seat = -1
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.disabled = true
		return
	if is_targeting_tay_phu:
		if selected_two_card_skill_nodes.size() != 2 or selected_target_seat <= 0:
			desc_text.text = "⚠️ [TÂY PHU] cần chọn đúng 2 lá trên tay và 1 mục tiêu."
			return
		var tay_ids: Array[String] = []
		for card_node in selected_two_card_skill_nodes:
			tay_ids.append(str(_get_card_info_from_ui(card_node).get("id", "")))
		NetworkClient.send_use_skill("Tây Phu", selected_target_seat, "|".join(tay_ids))
		is_targeting_tay_phu = false
		for card_node in selected_two_card_skill_nodes:
			if is_instance_valid(card_node): card_node.set_selected(false)
		selected_two_card_skill_nodes.clear()
		selected_target_seat = -1
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_AN_TICH" and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		return
	if current_server_phase == "AWAIT_KHOAN_HOA" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0:
			desc_text.text = "⚠️ [KHOAN HÒA] cần chọn 1 người khác."
			return
		NetworkClient.send_use_skill("Khoan Hòa", selected_target_seat)
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_XUNG_VUONG_TARGET" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0:
			desc_text.text = "⚠️ [XƯNG VƯƠNG] cần chọn 1 người khác."
			return
		NetworkClient.send_respond_action(true, str(selected_target_seat))
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_AN_DAN_DUEL" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0 or selected_target_seat == my_seat:
			desc_text.text = "⚠️ [AN DÂN] cần chọn 1 mục tiêu khác."
			return
		NetworkClient.send_respond_action(true, str(selected_target_seat))
		card_play_btn.disabled = true
		return
	if is_targeting_dan_cau:
		if selected_card_ui == null or selected_target_seat <= 0 or dan_cau_forced_target_seat <= 0:
			desc_text.text = "⚠️ Dẫn Cầu cần chọn 1 lá và 2 mục tiêu."
			return
		var dan_card_id = str(_get_card_info_from_ui(selected_card_ui).get("id", ""))
		NetworkClient.send_use_skill("Dẫn Cầu", selected_target_seat, dan_card_id + "|" + str(dan_cau_forced_target_seat))
		is_targeting_dan_cau = false
		if selected_card_ui and is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
		selected_card_ui = null
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		if dan_cau_forced_target_seat > 0 and generals_data.has(dan_cau_forced_target_seat):
			generals_data[dan_cau_forced_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		dan_cau_forced_target_seat = -1
		card_play_btn.disabled = true
		card_play_btn.visible = false
		return
	if is_targeting_thuy_chien:
		if selected_card_ui == null or selected_target_seat <= 0:
			desc_text.text = "⚠️ Thủy Chiến cần chọn 1 lá và mục tiêu."
			return
		var tgt_gen = generals_data.get(selected_target_seat, {})
		if _hero_has_skill(tgt_gen, "thuy_chien"):
			desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % tgt_gen.get("name", "Mục tiêu")
			return
		NetworkClient.send_use_skill("Thủy Chiến", selected_target_seat, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		is_targeting_thuy_chien = false
		return
	if is_targeting_van_an or is_targeting_cai_cach:
		if selected_two_card_skill_nodes.size() != 2:
			desc_text.text = "⚠️ Cần chọn đúng 2 lá bài."
			return
		if is_targeting_van_an and selected_target_seat <= 0:
			desc_text.text = "⚠️ [VẠN AN] cần chọn 1 người chơi khác."
			return
		if is_targeting_van_an:
			var tgt_gen = generals_data.get(selected_target_seat, {})
			if _hero_has_skill(tgt_gen, "thuy_chien"):
				desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % tgt_gen.get("name", "Mục tiêu")
				return
		var skill_card_ids: Array[String] = []
		for card_node in selected_two_card_skill_nodes:
			skill_card_ids.append(str(_get_card_info_from_ui(card_node).get("id", "")))
		if is_network_mode:
			NetworkClient.send_use_skill("Vạn An" if is_targeting_van_an else "Cải Cách", selected_target_seat if is_targeting_van_an else 0, "|".join(skill_card_ids))
		else:
			if is_targeting_van_an:
				_execute_local_van_an(selected_target_seat, selected_two_card_skill_nodes.duplicate())
		is_targeting_van_an = false
		is_targeting_cai_cach = false
		_clear_hung_suc_equipped_weapon_previews()
		selected_two_card_skill_nodes.clear()
		card_play_btn.disabled = true
		_refresh_local_skill_buttons(my_seat)
		return
	if current_server_phase == "AWAIT_DA_TRACH_DISCARD" and current_waiting_seat == my_seat:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [DẠ TRẠCH] hãy chọn 1 lá trên tay."
			return
		NetworkClient.send_respond_action(true, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		card_play_btn.disabled = true
		return
	if current_server_phase in ["AWAIT_AN_DAN", "AWAIT_HOA_DAN", "AWAIT_DUNG_NUOC", "AWAIT_HAN_LAM", "AWAIT_TRUNG_KIEN", "AWAIT_TRU_QUAN", "AWAIT_TRUNG_TIET", "AWAIT_CAN_VE"] and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(true, "")
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_COT_KINH_TARGET" and current_waiting_seat == my_seat:
		if selected_target_seat <= 0 or selected_target_seat == my_seat:
			desc_text.text = "⚠️ [CỘT KINH] hãy chọn 1 người chơi khác."
			return
		NetworkClient.send_respond_action(true, str(selected_target_seat))
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_KHOI_BINH" and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(true, "")
		card_play_btn.disabled = true
		return
	if current_server_phase == "AWAIT_VAN_SACH" and current_waiting_seat == my_seat:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [VĂN SÁCH] hãy chọn 1 lá trên tay để bỏ."
			return
		NetworkClient.send_respond_action(true, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		card_play_btn.disabled = true
		return
	if huynh_truong_pending:
		if selected_target_seat <= 0 or selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [HUYNH TRƯỞNG] cần chọn một người khác và 1 lá bài."
			return
		NetworkClient.send_use_skill("Huynh Trưởng", selected_target_seat, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		card_play_btn.disabled = true
		return
	if is_targeting_bat_na:
		if selected_target_seat <= 0 or selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [BÁT NẠ] cần chọn 1 Bài Cơ Bản và 1 mục tiêu."
			return
		var bat_na_card = _get_card_info_from_ui(selected_card_ui)
		if int(bat_na_card.get("cat", -1)) != 0:
			desc_text.text = "⚠️ [BÁT NẠ] chỉ biến Bài Cơ Bản thành Trảm."
			return
		NetworkClient.send_use_skill("Bát Nạ", selected_target_seat, str(bat_na_card.get("id", "")))
		is_targeting_bat_na = false
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.disabled = true
		return
	if is_targeting_van_sach:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [VĂN SÁCH] cần chọn 1 Bài Cơ Bản."
			return
		var van_sach_card = _get_card_info_from_ui(selected_card_ui)
		if int(van_sach_card.get("cat", -1)) != 0:
			desc_text.text = "⚠️ [VĂN SÁCH] chỉ đổi được Bài Cơ Bản."
			return
		NetworkClient.send_use_skill("Văn Sách", 0, str(van_sach_card.get("id", "")))
		is_targeting_van_sach = false
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.disabled = true
		return
	if is_targeting_hung_suc:
		if hung_suc_submission_pending:
			return
		if selected_target_seat <= 0 or selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [HÙNG SỨC] cần chọn 1 Vũ Khí và 1 mục tiêu trong Tầm 1."
			return
		var hung_card = _get_card_info_from_ui(selected_card_ui)
		if int(hung_card.get("cat", -1)) != 1 or int(hung_card.get("subType", -1)) != 6:
			desc_text.text = "⚠️ [HÙNG SỨC] chỉ bỏ được lá Vũ Khí trên tay hoặc đang đeo."
			return
		NetworkClient.send_use_skill("Hùng Sức", selected_target_seat, str(hung_card.get("id", "")))
		hung_suc_submission_pending = true
		card_play_btn.disabled = true
		card_play_btn.text = "💪 ĐANG KÍCH HOẠT HÙNG SỨC..."
		return
	if uat_khi_pending:
		if uat_khi_target_seat <= 0 or not generals_data.has(uat_khi_target_seat):
			desc_text.text = "⚠️ [UẤT KHÍ] hãy chọn một người còn sống."
			return
		var uat_target = generals_data[uat_khi_target_seat]
		if not uat_target.get("is_alive", false) or int(uat_target.get("hp", 0)) <= 0:
			desc_text.text = "⚠️ Mục tiêu [UẤT KHÍ] không hợp lệ."
			_clear_uat_khi_selection()
			return
		if is_network_mode:
			uat_khi_submission_pending = true
			card_play_btn.disabled = true
			NetworkClient.send_respond_action(true, str(uat_khi_target_seat))
		else:
			var max_hp = int(uat_target.get("max_hp", 3))
			uat_target["hp"] = min(max_hp, int(uat_target.get("hp", 1)) + 1)
			if uat_target.has("avatar_node") and is_instance_valid(uat_target["avatar_node"]):
				uat_target["avatar_node"].update_hp(uat_target["hp"], max_hp)
			for _d in range(2):
				var drawn_card = _draw_card_from_pile()
				if uat_khi_target_seat == my_seat:
					_add_card_to_player_hand(drawn_card)
				else:
					uat_target["hand_cards"].append(drawn_card)
					uat_target["hand_count"] = uat_target["hand_cards"].size()
					uat_target["avatar_node"].update_hand_count(uat_target["hand_count"])
				_animate_draw_to_seat(uat_khi_target_seat)
			_add_log("💢 [UẤT KHÍ] %s chọn %s: hồi 1 máu và rút 2 lá bài." % [generals_data[my_seat]["name"], uat_target["name"]])
			_clear_uat_khi_selection()
			uat_khi_pending = false
			current_waiting_seat = 0
			current_waiting_timer = 0.0
			card_play_btn.visible = false
			end_turn_btn.visible = false
			_show_dead_player_exit()
		return

	if is_targeting_trieu_dang:
		if selected_target_seat <= 0 or selected_target_seat == my_seat or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ [TRIỀU DÂNG] hãy chọn một người khác có trang bị."
			return
		var trieu_target = generals_data[selected_target_seat]
		var target_has_equipment = not str(trieu_target.get("equipped_weapon", "")).is_empty() or not str(trieu_target.get("equipped_armor", "")).is_empty() or not str(trieu_target.get("equipped_def_horse", "")).is_empty() or not str(trieu_target.get("equipped_off_horse", "")).is_empty() or not str(trieu_target.get("equipped_treasure", "")).is_empty()
		if not target_has_equipment:
			desc_text.text = "⚠️ %s không còn trang bị để hủy." % trieu_target["name"]
			return
		var trieu_target_seat = selected_target_seat
		if generals_data.has(trieu_target_seat):
			generals_data[trieu_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		is_targeting_trieu_dang = false
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.visible = false
		if is_network_mode:
			NetworkClient.send_use_skill("Triều Dâng", trieu_target_seat)
		else:
			_show_card_pick_modal(false, trieu_target_seat, {"effectType": "TRIEU_DANG"})
		return

	if is_discard_phase:
		if selected_discard_nodes.is_empty():
			desc_text.text = "⚠️ Hãy chọn ít nhất 1 lá bài để bỏ."
			return

		pending_discard_card_ids.clear()
		var discarded_names: Array = []
		for c_node in selected_discard_nodes:
			if is_instance_valid(c_node):
				var info_d = _get_card_info_from_ui(c_node)
				var c_name_d = info_d.get("name", "Bài")
				var c_id_d = info_d.get("id", c_name_d)
				if c_id_d.is_empty(): c_id_d = c_name_d
				pending_discard_card_ids.append(c_id_d)
				discarded_names.append(c_name_d)
				_discard_player_card(c_node)

		var discarded_count = pending_discard_card_ids.size()
		selected_discard_nodes.clear()
		cards_to_discard_count = max(0, cards_to_discard_count - discarded_count)
		is_discard_phase = cards_to_discard_count > 0
		card_play_btn.visible = is_discard_phase
		card_play_btn.disabled = is_discard_phase
		if is_discard_phase:
			card_play_btn.text = "🗑️ BỎ BÀI (0/%d)" % cards_to_discard_count
		_add_log("🗑️ Bạn đã bỏ %d lá bài thừa: [%s]." % [pending_discard_card_ids.size(), ", ".join(discarded_names)])
		_animate_showcase_card("Bỏ Bài", "Bỏ %d lá bài thừa" % pending_discard_card_ids.size())
		AudioManager.play_card_draw()

		if is_network_mode:
			_broadcast_player_battle_action("DISCARD_CARDS", "")
			pending_discard_card_ids.clear()
			# Máy chủ quyết định đã đủ bài hay chưa. Giữ nguyên pha cho tới bản đồng bộ kế tiếp,
			# tránh giao diện chuyển sang lượt sau trước khi số bài bỏ được xác nhận.
			is_discard_phase = true
			discard_submission_pending = true
			card_play_btn.visible = true
			card_play_btn.disabled = true
			card_play_btn.text = "🗑️ ĐANG XÁC NHẬN..."
			desc_text.text = "🗑️ Đang chờ máy chủ xác nhận số bài đã bỏ..."
		elif not is_discard_phase:
			_finish_player_end_turn()
		else:
			desc_text.text = "🗑️ Đã bỏ %d lá. Bạn còn phải bỏ %d lá, hãy tiếp tục chọn bài." % [discarded_count, cards_to_discard_count]
		return

	if is_targeting_drum_skill:
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "🥁 Vui lòng chọn 1 Tướng trên bàn để phát động Điểm Trống!"
			return
		_activate_drum_skill(selected_target_seat)
		return

	if is_targeting_ho_phu_skill:
		_activate_ho_phu_skill()
		return

	if not is_player_turn or selected_card_ui == null:
		return

	var c_info = _get_card_info_from_ui(selected_card_ui)
	var c_name = c_info.get("name", "")
	var c_id = c_info.get("id", c_name)
	if c_id.is_empty(): c_id = c_name
	last_played_card_info = c_info.duplicate()

	if "Trảm" in c_name:
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng còn sống trên bàn để Trảm!"
			return
		var tgt = generals_data[selected_target_seat]
		var p_gen = generals_data[my_seat]
		var dist = _calculate_distance(my_seat, selected_target_seat)
		var max_r = _get_attack_range(my_seat)
		var water_bach_dang = ("Thủy" in c_name and p_gen.get("equipped_off_horse", "") == "Thuyền Bạch Đằng")
		var te_giang_ignore = (_hero_has_skill(p_gen, "te_giang") and not _has_equipped_horse(tgt))
		if dist > max_r and not water_bach_dang and not te_giang_ignore:
			desc_text.text = "⚠️ Khoảng cách tới %s là %d (Tầm đánh của bạn là %d)!" % [tgt["name"], dist, max_r]
			return
		var da_trach_blocks = _is_da_trach_slash_blocked(selected_target_seat)
		if da_trach_blocks:
			if is_network_mode:
				card_play_btn.disabled = true
				card_play_btn.text = "🌙 ĐANG KIỂM TRA DẠ TRẠCH..."
				_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"], my_seat)
			else:
				var target_avatar = tgt.get("avatar_node")
				if is_instance_valid(target_avatar) and target_avatar.has_method("show_skill_banner"):
					target_avatar.show_skill_banner("DẠ TRẠCH", 2.0)
				AudioManager.play_skill()
				desc_text.text = "🌙 [DẠ TRẠCH] %s không thể trở thành mục tiêu của Trảm khi không có bài trên tay." % tgt["name"]
			return

		var has_no_than = _has_no_than(p_gen)
		var has_suc_soi = int(p_gen.get("suc_soi_turns_remaining", 0)) > 0
		# Network server owns the Slash limit; local cached counters must not block Bát Nạ follow-ups.
		if not is_network_mode and slashes_used_this_turn >= 1 and not has_no_than and not has_suc_soi:
			desc_text.text = "⚠️ Mỗi lượt chỉ được Trảm 1 lần (trừ Nỏ Thần hoặc Sục Sôi)!"
			return
		if _offer_lien_chau_after_first_target():
			return

		if not is_network_mode and generals_data.has(my_seat) and generals_data[my_seat].get("has_bai_coc", false):
			if not await _resolve_local_bai_coc_action(my_seat, my_seat):
				_discard_player_card(selected_card_ui)
				selected_card_ui = null
				card_play_btn.visible = false
				_reset_player_turn_timer()
				return
		elif is_network_mode and p_gen.get("has_bai_coc", false):
			# Máy chủ sẽ trả về phán xét trước PLAY_SLASH; không phát hiệu ứng Trảm lạc quan trước đó.
			var lien_targets: Array = [tgt["seat"]]
			var lien_cost_id := ""
			if lien_chau_target_seat > 0 and lien_chau_cost_card and is_instance_valid(lien_chau_cost_card):
				lien_targets.append(lien_chau_target_seat)
				lien_cost_id = str(_get_card_info_from_ui(lien_chau_cost_card).get("id", ""))
				_discard_player_card(lien_chau_cost_card)
			_clear_lien_chau_selection()
			_discard_player_card(selected_card_ui)
			selected_card_ui = null
			card_play_btn.visible = false
			_reset_player_turn_timer()
			_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"], my_seat, 0, lien_targets, false, lien_cost_id)
			desc_text.text = "🪵 Đang phán xét [Bãi Cọc Bạch Đằng] trước khi tung Trảm..."
			return

		# Chỉ tiêu lượt Trảm và hiệu lực Hủ Rượu sau khi Bãi Cọc đã phán xét xong.
		var slash_dmg = 1
		var is_wine = is_wine_buff_active
		if is_wine_buff_active:
			slash_dmg += 1
			is_wine_buff_active = false
		var elem = "NORMAL"
		if "Hỏa" in c_name or p_gen.get("equipped_weapon", "") == "Hỏa Mai Tây Sơn": elem = "FIRE"
		elif "Thủy" in c_name or "Lôi" in c_name: elem = "WATER" # Accept old card names.
		slashes_used_this_turn += 1
		var lien_targets: Array = [tgt["seat"]]
		var lien_cost_id := ""
		if lien_chau_target_seat > 0 and lien_chau_cost_card and is_instance_valid(lien_chau_cost_card):
			lien_targets.append(lien_chau_target_seat)
			lien_cost_id = str(_get_card_info_from_ui(lien_chau_cost_card).get("id", ""))
			_discard_player_card(lien_chau_cost_card)
		_clear_lien_chau_selection()
		if not is_network_mode and _hero_has_skill(p_gen, "phu_tran") and str(p_gen.get("equipped_weapon", "")).is_empty():
			_add_card_to_player_hand(_draw_card_from_pile())
			_add_log("🏹 [PHÙ TRẤN] %s không đeo vũ khí, rút 1 lá khi dùng Trảm." % p_gen["name"])

		_play_smart_card_rays(c_name, my_seat, lien_targets, selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false

		AudioManager.play_voice(c_name)
		AudioManager.play_slash()
		_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"], my_seat, 0, lien_targets, false, lien_cost_id)
		_animate_showcase_card(c_name, "Bạn dùng [%s] tấn công %s!" % [c_name, tgt["name"]], c_info)
		_add_log("⚔️ Bạn dùng [%s]%s lên %s (Ghế %d)." % [c_name, " (kèm Hủ Rượu: +1 Sát Thương)" if is_wine else "", tgt["name"], tgt["seat"]])
		desc_text.text = "⚔️ Đã xuất Trảm lên %s! Đang chờ đối phương phản hồi..." % tgt["name"]
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("slash", 1)

		if not is_network_mode:
			var slash_suit = c_info.get("suit", "")
			await _handle_slash_attack(my_seat, tgt["seat"], slash_dmg, elem, slash_suit)
			if lien_targets.size() == 2:
				await _handle_slash_attack(my_seat, lien_targets[1], slash_dmg, elem, slash_suit)

	elif c_name == "Bánh Chưng":
		var p_gen = generals_data[my_seat]
		if p_gen["hp"] >= p_gen["max_hp"]:
			desc_text.text = "⚠️ Máu của bạn đã đầy (%d/%d)!" % [p_gen["hp"], p_gen["max_hp"]]
			return
		recent_heal_seats[my_seat] = Time.get_ticks_msec()
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		p_gen["hp"] = min(p_gen["max_hp"], p_gen["hp"] + 1)
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			p_gen["avatar_node"].update_hp(p_gen["hp"], p_gen["max_hp"])
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Bạn ăn Bánh Chưng hồi 1 Máu!", c_info)
		_add_log("🍲 Bạn hồi phục 1 Máu bằng [Bánh Chưng] (%d/%d)." % [p_gen["hp"], p_gen["max_hp"]])
		desc_text.text = "🍲 Đã dùng [Bánh Chưng] hồi 1 Máu (%d/%d)!" % [p_gen["hp"], p_gen["max_hp"]]
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("heal", 1)

	elif c_name == "Hủ Rượu":
		if wine_used_this_turn:
			desc_text.text = "⚠️ Mỗi lượt chỉ được dùng 1 Hủ Rượu để tăng sát thương."
			return
		is_wine_buff_active = true
		wine_used_this_turn = true
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Bạn uống Hủ Rượu (+1 Sát Thương)!", c_info)
		_add_log("🍶 Bạn đã uống [Hủ Rượu], đòn Trảm kế tiếp được +1 Sát Thương!")

	elif c_name == "Xích Tâm Tỏa":
		var is_chain_recast = selected_chain_seats.is_empty()
		var target_seats_list = selected_chain_seats.duplicate()
		if not target_seats_list.is_empty():
			_play_smart_card_rays(c_name, my_seat, target_seats_list, selected_card_ui)

		var c_to_discard = selected_card_ui
		_discard_player_card(c_to_discard)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()

		if is_chain_recast:
			_animate_showcase_card(c_name, "Đổi lá để rút 1 lá mới!", c_info)
			_add_log("🔄 Bạn đổi [Xích Tâm Tỏa] để rút 1 lá bài.")
		else:
			_animate_showcase_card(c_name, "Đổi trạng thái xích cho %d tướng!" % target_seats_list.size(), c_info)

		for s in target_seats_list:
			if generals_data.has(s) and generals_data[s]["is_alive"]:
				var g = generals_data[s]
				g["is_chained"] = !g.get("is_chained", false)
				if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
					g["avatar_node"].set_chained(g["is_chained"])
				var act_str = "trói vào Xích Liên Hoàn" if g["is_chained"] else "gỡ Xích Liên Hoàn"
				_add_log("⛓️ [XÍCH TÂM TỎA]: Đã %s cho <b>%s</b> (Ghế %d)!" % [act_str, g["name"], s])

		var seat1 = target_seats_list[0] if target_seats_list.size() > 0 else 0
		var seat2 = target_seats_list[1] if target_seats_list.size() > 1 else 0

		_broadcast_player_battle_action("PLAY_CARD", c_id, seat1, my_seat, seat2, target_seats_list, is_chain_recast)
		if is_chain_recast and not is_network_mode:
			_add_card_to_player_hand(_draw_card_from_pile())

		selected_chain_seats.clear()
		_update_chain_target_highlights()
		return

	elif c_name == "Dụng Binh Như Thần":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Rút ngay bài!", c_info)
		_add_log("📜 Bạn thi triển [Dụng Binh Như Thần]!")
		if not is_network_mode:
			var p_gen_db = generals_data.get(my_seat, {})
			var draw_num = 3 if p_gen_db.get("hero_id", 0) == 68 else 2
			for k in range(draw_num):
				var c_draw = _draw_card_from_pile()
				_add_card_to_player_hand(c_draw)

	elif c_name == "Đột Kích Trộm Lương":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng trên bàn để cướp bài!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự cướp bài của chính mình!"
			return
		var tgt = generals_data[selected_target_seat]
		var dist = _calculate_distance(my_seat, selected_target_seat)
		if dist > 1:
			desc_text.text = "⚠️ Khoảng cách tới %s là %d (Vượt quá cự ly 1 của Đột Kích Trộm Lương)!" % [tgt["name"], dist]
			return
		if is_network_mode:
			var c_to_discard = selected_card_ui
			_play_smart_card_rays(c_name, my_seat, [tgt["seat"]], c_to_discard)
			_discard_player_card(c_to_discard)
			selected_card_ui = null
			card_play_btn.visible = false
			_reset_player_turn_timer()
			AudioManager.play_voice(c_name)
			AudioManager.play_skill()
			_animate_showcase_card(c_name, "Dùng Đột Kích Trộm Lương lên %s!" % tgt["name"], c_info)
			_add_log("🗡️ Bạn dùng [%s] nhắm vào %s." % [c_name, tgt["name"]])
			desc_text.text = "🗡️ Đã dùng [Đột Kích Trộm Lương] lên %s! Đang bốc bài..." % tgt["name"]
			_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"])
			return
		else:
			_show_card_pick_modal(true, selected_target_seat)
			return

	elif c_name == "Vườn Không Nhà Trống":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng mục tiêu trên bàn để phá hủy bài!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự phá hủy bài của chính mình!"
			return
		var tgt = generals_data[selected_target_seat]
		if is_network_mode:
			var c_to_discard = selected_card_ui
			_play_smart_card_rays(c_name, my_seat, [tgt["seat"]], c_to_discard)
			_discard_player_card(c_to_discard)
			selected_card_ui = null
			card_play_btn.visible = false
			_reset_player_turn_timer()
			AudioManager.play_voice(c_name)
			AudioManager.play_skill()
			_animate_showcase_card(c_name, "Dùng Vườn Không Nhà Trống lên %s!" % tgt["name"], c_info)
			_add_log("🌾 Bạn dùng [%s] nhắm vào %s." % [c_name, tgt["name"]])
			desc_text.text = "🌾 Đã dùng [Vườn Không Nhà Trống] lên %s! Đang chọn bài..." % tgt["name"]
			_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"])
			return
		else:
			_show_card_pick_modal(false, selected_target_seat)
			return

	elif c_name == "Diệu Kế Phá Mưu":
		desc_text.text = "⚠️ Diệu Kế Phá Mưu chỉ được dùng khi bảng phản ứng đang hỏi."
		return

	elif c_name == "Giặc Tới":
		_play_smart_card_rays(c_name, my_seat, _get_aoe_ray_targets(my_seat), selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Giặc Tới")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Giặc Tới: Toàn bộ người chơi khác phải đánh 1 Trảm!", c_info)
		_add_log("🪵 Bạn phát động [Giặc Tới]! Toàn bộ người chơi khác phải đánh 1 lá Trảm hoặc mất 1 Máu.")
		desc_text.text = "🪵 Đã phát động [Giặc Tới]! Đang chờ người chơi khác phản hồi..."
		if not is_network_mode:
			_execute_aoe_attack(my_seat, "Giặc Tới", "Trảm")

	elif c_name == "Mưa Tên Liên Châu":
		_play_smart_card_rays(c_name, my_seat, _get_aoe_ray_targets(my_seat), selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Mưa Tên Liên Châu")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Mưa Tên Liên Châu: Toàn bộ người chơi khác phải đánh 1 Đỡ!", c_info)
		_add_log("🏹 Bạn thi triển [Mưa Tên Liên Châu]! Toàn bộ người chơi khác phải đánh 1 lá Đỡ hoặc mất 1 Máu.")
		desc_text.text = "🏹 Đã thi triển [Mưa Tên Liên Châu]! Đang chờ người chơi khác phản hồi..."
		if not is_network_mode:
			_execute_aoe_attack(my_seat, "Mưa Tên Liên Châu", "Đỡ")

	elif c_name == "Huyết Chiến":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng trên bàn để Huyết Chiến!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự Huyết Chiến chính mình!"
			return
		var tgt = generals_data[selected_target_seat]
		if not tgt["is_alive"]:
			desc_text.text = "⚠️ Mục tiêu đã tử trận!"
			return
		_play_smart_card_rays(c_name, my_seat, [tgt["seat"]], selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Huyết Chiến")
		AudioManager.play_slash()
		_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"])
		_animate_showcase_card(c_name, "Bạn huyết chiến %s!" % tgt["name"], c_info)
		_add_log("⚔️ Bạn phát động [Huyết Chiến] lên %s (Ghế %d)!" % [tgt["name"], tgt["seat"]])
		desc_text.text = "⚔️ Đã phát động [Huyết Chiến] lên %s! Đang chờ phản hồi..." % tgt["name"]
		if not is_network_mode:
			_execute_duel(my_seat, selected_target_seat)

	elif c_name == "Bãi Cọc Bạch Đằng":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng chọn 1 Tướng trên bàn để gài [Bãi Cọc Bạch Đằng]!"
			return
		if selected_target_seat == my_seat:
			desc_text.text = "⚠️ Không thể tự gài Bãi Cọc Bạch Đằng lên mình!"
			return
		var trap_target = generals_data[selected_target_seat]
		_play_smart_card_rays(c_name, my_seat, [trap_target["seat"]], selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, trap_target["seat"])
		_animate_showcase_card(c_name, "Bạn gài [Bãi Cọc Bạch Đằng] lên %s!" % trap_target["name"], c_info)
		_add_log("🪵 Bạn gài [Bãi Cọc Bạch Đằng] lên %s. Lần Trảm hoặc dùng Chiến Mã kế tiếp sẽ bị phán xét 1 lần, sau đó Bãi Cọc rời đi." % trap_target["name"])
		trap_target["has_bai_coc"] = true
		trap_target["bai_coc_judgement_count"] = 0
		if trap_target.has("avatar_node") and is_instance_valid(trap_target["avatar_node"]):
			trap_target["avatar_node"].set_delayed_trick("bai_coc", true)

	elif c_name == "Thủy Triều Rút":
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat) or selected_target_seat == my_seat:
			desc_text.text = "⚠️ Vui lòng chọn 1 Tướng khác để dùng Thủy Triều Rút!"
			return
		var tide_target = generals_data[selected_target_seat]
		if not tide_target.get("is_alive", false) or int(tide_target.get("hand_count", 0)) <= 0:
			desc_text.text = "⚠️ Mục tiêu Thủy Triều Rút phải còn sống và có ít nhất 1 lá trên tay!"
			return
		_play_smart_card_rays(c_name, my_seat, [tide_target["seat"]], selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, tide_target["seat"])
		AudioManager.play_voice(c_name)
		_animate_showcase_card(c_name, "Bạn dùng [Thủy Triều Rút] lên %s!" % tide_target["name"], c_info)
		_add_log("🌊 Bạn dùng [Thủy Triều Rút] lên %s." % tide_target["name"])
		if not is_network_mode:
			await _resolve_local_thuy_trieu_rut(my_seat, tide_target["seat"])

	elif c_name == "Mượn Gươm Diệt Địch":
		if borrow_sword_owner_seat <= 0 or not generals_data.has(borrow_sword_owner_seat):
			desc_text.text = "⚠️ Chọn 1 Tướng đang có Vũ khí để Mượn Gươm!"
			return
		if borrow_sword_target_seat <= 0 or not generals_data.has(borrow_sword_target_seat):
			desc_text.text = "⚠️ Chọn thêm 1 mục tiêu bị buộc Trảm!"
			return
		var sword_owner = generals_data[borrow_sword_owner_seat]
		if str(sword_owner.get("equipped_weapon", "")).is_empty():
			desc_text.text = "⚠️ Tướng được chọn không còn trang bị Vũ khí!"
			_clear_borrow_sword_targets()
			_update_action_btn()
			return
		var forced_target = generals_data[borrow_sword_target_seat]
		var weapon_range = _get_attack_range(sword_owner["seat"])
		var forced_distance = _calculate_distance(sword_owner["seat"], forced_target["seat"])
		if forced_distance > weapon_range:
			desc_text.text = "⚠️ %s cách %d, vượt tầm vũ khí %d của %s!" % [forced_target["name"], forced_distance, weapon_range, sword_owner["name"]]
			return
		if _is_da_trach_slash_blocked(borrow_sword_target_seat):
			desc_text.text = "🌙 [DẠ TRẠCH] %s không có bài trên tay nên không thể bị Trảm!" % forced_target["name"]
			return
		_play_smart_card_rays("Trảm", sword_owner["seat"], [forced_target["seat"]])
		if not is_network_mode:
			_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, sword_owner["seat"], my_seat, forced_target["seat"])
		AudioManager.play_voice(c_name)
		_animate_showcase_card(c_name, "Bạn mượn gươm của %s, buộc đánh %s!" % [sword_owner["name"], forced_target["name"]], c_info)
		_add_log("🗡️ Bạn mượn gươm của %s, chọn %s làm mục tiêu bị buộc Trảm." % [sword_owner["name"], forced_target["name"]])
		_clear_borrow_sword_targets()
		if not is_network_mode:
			await _resolve_local_borrow_sword(my_seat, sword_owner["seat"], forced_target["seat"])

	elif c_name == "Khổ Nhục Kế":
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Bạn nhận 1 sát thương rồi rút 3 lá!", c_info)
		if not is_network_mode:
			_apply_damage_to_general(my_seat, 1, my_seat)
			for _i in range(3):
				_add_card_to_player_hand(_draw_card_from_pile())

	elif c_name == "Tẩu Vi Thượng Sách":
		if str(generals_data[my_seat].get("equipped_weapon", "")).is_empty() and str(generals_data[my_seat].get("equipped_armor", "")).is_empty() and str(generals_data[my_seat].get("equipped_off_horse", "")).is_empty() and str(generals_data[my_seat].get("equipped_def_horse", "")).is_empty() and str(generals_data[my_seat].get("equipped_treasure", "")).is_empty():
			desc_text.text = "⚠️ Cần có ít nhất 1 Trang bị để dùng Tẩu Vi Thượng Sách!"
			return
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Bỏ 1 Trang bị của mình để rút 2 lá.", c_info)
		if not is_network_mode:
			_show_card_pick_modal(false, my_seat, {"effectType": "TAU_VI"})

	elif c_name == "Phủ Để Trừu Tân":
		if selected_target_seat <= 0 or selected_target_seat == my_seat or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Phủ Để Trừu Tân cần chọn 1 tướng khác có Trang bị!"
			return
		var phu_de_target = generals_data[selected_target_seat]
		if str(phu_de_target.get("equipped_weapon", "")).is_empty() and str(phu_de_target.get("equipped_armor", "")).is_empty() and str(phu_de_target.get("equipped_off_horse", "")).is_empty() and str(phu_de_target.get("equipped_def_horse", "")).is_empty() and str(phu_de_target.get("equipped_treasure", "")).is_empty():
			desc_text.text = "⚠️ Mục tiêu không có Trang bị để trả về tay!"
			return
		_play_smart_card_rays(c_name, my_seat, [selected_target_seat], selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, selected_target_seat)
		_animate_showcase_card(c_name, "Đưa 1 Trang bị của %s về tay họ." % phu_de_target["name"], c_info)

	elif c_name == "Hịch Tướng Sĩ":
		if selected_target_seat <= 0 or selected_target_seat == my_seat or not generals_data.has(selected_target_seat) or not generals_data[selected_target_seat].get("is_alive", false):
			desc_text.text = "⚠️ Hịch Tướng Sĩ cần chọn đúng 1 người chơi khác còn sống!"
			return
		var hich_targets: Array = [selected_target_seat]
		_play_smart_card_rays(c_name, my_seat, hich_targets, selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0, my_seat, 0, hich_targets)
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_animate_showcase_card(c_name, "Bạn phát Hịch Tướng Sĩ!", c_info)
		_add_log("📣 Bạn phát [Hịch Tướng Sĩ]%s." % (" cùng %s" % generals_data[hich_targets[0]]["name"] if not hich_targets.is_empty() else ""))
		if not is_network_mode:
			_resolve_local_hich_tuong_si(hich_targets[0])

	elif c_name == "Mở Yến Tiệc":
		_play_smart_card_rays(c_name, my_seat, _get_aoe_ray_targets(my_seat), selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_animate_showcase_card(c_name, "Bạn mở Yến Tiệc cho toàn bàn!", c_info)
		_add_log("🍽️ Bạn dùng [Mở Yến Tiệc].")

	elif c_name in ["Trống Đồng Đông Sơn", "Hổ Phù Trần Triều"]:
		var drum_gen = generals_data[my_seat]
		drum_gen["equipped_treasure"] = c_name
		_record_local_equipment_card(c_info)
		if drum_gen.has("avatar_node") and is_instance_valid(drum_gen["avatar_node"]):
			drum_gen["avatar_node"].set_equipment("treasure", c_name, "K Đen")
			drum_gen["avatar_node"].set_skill("🥁 ĐIỂM TRỐNG" if c_name == "Trống Đồng Đông Sơn" else "🐯 HỔ PHÙ")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_animate_showcase_card(c_name, "Bạn trang bị [Trống Đồng Đông Sơn]!", c_info)
		_add_log("🥁 Bạn trang bị [Trống Đồng Đông Sơn].")

	elif c_name == "Mở Kho Cứu Tế":
		_play_smart_card_rays(c_name, my_seat, _get_aoe_ray_targets(my_seat), selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice("Mở Kho Cứu Tế")
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Mở kho phát bài cho tất cả người chơi!", c_info)
		_add_log("🌾 Bạn thi triển [Mở Kho Cứu Tế]! Chia bài cho toàn bộ người chơi còn sống.")
		if not is_network_mode:
			_execute_harvest(my_seat)

	elif _is_dai_hong_thuy_name(c_name):
		var p_gen = generals_data[my_seat]
		p_gen["has_dai_hong_thuy"] = true
		p_gen["has_lightning"] = true # Legacy state alias.
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			p_gen["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card("Đại Hồng Thủy", "Bạn tự đặt [Đại Hồng Thủy] vào khu phán xét!", c_info)
		_add_log("🌊 Bạn đã đặt Cẩm Nang Trì Hoãn [Đại Hồng Thủy] vào khu phán xét của chính mình!")

	elif c_name in ["Cắt Đường Lương", "Trầm Ảo Sa Bẫy"]:
		if selected_target_seat <= 0 or not generals_data.has(selected_target_seat):
			desc_text.text = "⚠️ Vui lòng nhấp chọn 1 Tướng trên bàn để dán [Cẩm Nang Trì Hoãn]!"
			return
		if c_name == "Cắt Đường Lương" and _calculate_distance(my_seat, selected_target_seat) > 1:
			desc_text.text = "⚠️ Lá bài này cần dùng trong tầm Ngựa."
			return
		var tgt = generals_data[selected_target_seat]
		if c_name == "Cắt Đường Lương":
			tgt["has_cat_luong"] = true
			if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
				tgt["avatar_node"].set_delayed_trick("cat_luong", true)
		else:
			tgt["has_tram_ao"] = true
			if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
				tgt["avatar_node"].set_delayed_trick("tram_ao", true)
		_play_smart_card_rays(c_name, my_seat, [tgt["seat"]], selected_card_ui)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, tgt["seat"])
		_animate_showcase_card(c_name, "Đặt [%s] lên %s!" % [c_name, tgt["name"]], c_info)
		_add_log("⏳ Bạn đặt Cẩm Nang Trì Hoãn [%s] vào khu phán xét của %s (Ghế %d)!" % [c_name, tgt["name"], tgt["seat"]])

	elif c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều", "Hỏa Mai Tây Sơn", "Liêm Đao Đống Đa", "Đoản Đao Lam Sơn"]:
		var p_gen = generals_data[my_seat]
		p_gen["equipped_weapon"] = c_name
		_record_local_equipment_card(c_info)
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			p_gen["avatar_node"].set_equipment("weapon", c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Bạn trang bị [%s]!" % c_name, c_info)
		_add_log("🗡️ Bạn đã trang bị Vũ Khí: [%s]!" % c_name)

	elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc", "Giáp Tây Sơn"]:
		var p_gen = generals_data[my_seat]
		p_gen["equipped_armor"] = c_name
		_record_local_equipment_card(c_info)
		if c_name == "Áo Bào Hoàng Tộc":
			p_gen["ao_bao_charges"] = 2
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			p_gen["avatar_node"].set_equipment("armor", c_name, "")
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Bạn trang bị [%s]!" % c_name, c_info)
		_add_log("🛡️ Bạn đã trang bị Áo Giáp: [%s]!" % c_name)

	elif "Voi Chiến" in c_name or "Ngựa Trắng" in c_name or "Thuyền Bạch Đằng" in c_name or c_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
		var p_gen = generals_data[my_seat]
		var slot_type = "def_horse" if ("Voi Chiến" in c_name) else "off_horse"
		if not await _resolve_local_bai_coc_action(my_seat, my_seat):
			_discard_player_card(selected_card_ui)
			selected_card_ui = null
			card_play_btn.visible = false
			_reset_player_turn_timer()
			return
		if "Voi Chiến" in c_name:
			p_gen["equipped_def_horse"] = c_name
		else:
			p_gen["equipped_off_horse"] = c_name
		_record_local_equipment_card(c_info)
		if p_gen.has("avatar_node") and is_instance_valid(p_gen["avatar_node"]):
			var horse_rank := int(c_info.get("rank", 0))
			var horse_suit_rank := _get_suit_icon(str(c_info.get("suit", ""))) + (_format_rank(horse_rank) if horse_rank > 0 else "")
			p_gen["avatar_node"].set_equipment(slot_type, c_name, horse_suit_rank)
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, my_seat)
		_animate_showcase_card(c_name, "Bạn cưỡi [%s]!" % c_name, c_info)
		_add_log("🐎 Bạn đã trang bị Chiến Mã: [%s]!" % c_name)

	else:
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
		card_play_btn.visible = false
		_reset_player_turn_timer()
		AudioManager.play_voice(c_name)
		AudioManager.play_skill()
		_broadcast_player_battle_action("PLAY_CARD", c_id, 0)
		_animate_showcase_card(c_name, "Bạn đã dùng [%s]!" % c_name, c_info)
		_add_log("🎴 Bạn đã dùng [%s]." % c_name)

func _broadcast_player_battle_action(act_type: String, card_id: String, target_seat: int = 0, caster_seat: int = 0, target_seat2: int = 0, target_seats: Array = [], recast: bool = false, lien_chau_card_id: String = "") -> void:
	var c_seat = caster_seat if caster_seat > 0 else my_seat
	if act_type == "PLAY_CARD" and (caster_seat == 0 or caster_seat == my_seat):
		var played_cat: int = int(last_played_card_info.get("cat", -1))
		var is_trick = played_cat in [2, 3] or "_CN_" in card_id
		if is_trick and DailyQuestSystem:
			DailyQuestSystem.record_progress("trick", 1)

	if NetworkClient and NetworkClient.is_connected_to_server:
		if act_type == "PLAY_CARD":
			NetworkClient.send_play_card_for_seat(c_seat, card_id, target_seat, target_seat2, target_seats, recast, lien_chau_card_id)
		elif act_type == "END_TURN":
			NetworkClient.send_end_turn_for_seat(c_seat)
		elif act_type == "DODGE_RESPONSE":
			var accepted = (card_id != "pass" and not card_id.is_empty())
			var resp_card = "" if card_id == "pass" else card_id
			NetworkClient.send_respond_action(accepted, resp_card)
		elif act_type == "RESPOND_ACTION":
			var accepted = (card_id != "pass" and not card_id.is_empty())
			NetworkClient.send_respond_action(accepted, card_id)
		elif act_type == "RESCUE_RESPONSE":
			var accepted = (card_id != "pass" and not card_id.is_empty())
			var resp_card = "" if card_id == "pass" else card_id
			NetworkClient.send_respond_action(accepted, resp_card)
		elif act_type == "DISCARD_CARDS":
			NetworkClient.send_discard_cards(pending_discard_card_ids)

func _build_initial_server_players() -> Array:
	var players = []
	for seat in range(1, battle_seat_count + 1):
		if not generals_data.has(seat):
			continue
		var g = generals_data[seat]
		var h_info = g.get("hero_data", {})
		var h_id = str(h_info.get("id", seat))
		var is_p = (seat == my_seat)
		var is_ai = g.get("isAI", not is_p)
		var u_id = ""
		if AppwriteMatchmaking and AppwriteMatchmaking.draft_slots.size() >= seat:
			u_id = AppwriteMatchmaking.draft_slots[seat - 1].get("userId", "")
		elif AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary and AppwriteMatchmaking.current_room.get("slots", []).size() >= seat:
			u_id = AppwriteMatchmaking.current_room["slots"][seat - 1].get("userId", "")
		if u_id.is_empty():
			u_id = ("user_%d" % seat) if not is_ai else ("bot_%d" % seat)

		players.append({
			"seat": seat,
			"userId": u_id,
			"heroId": "HERO_" + h_id if not h_id.begins_with("HERO_") else h_id,
			"generalName": g.get("name", "Tướng %d" % seat),
			"maxHp": g.get("max_hp", 4),
			"hp": g.get("hp", 4),
			"isAlly": bool(g.get("isDragon", false)),
			"isAI": is_ai,
			"role": str(g.get("role", ""))
		})
	return players

func _on_network_connected() -> void:
	if not NetworkClient:
		return
	is_network_mode = true
	var r_id = "room_1"
	if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary:
		var appwrite_r_id = AppwriteMatchmaking.current_room.get("roomId", "")
		if not appwrite_r_id.is_empty():
			r_id = appwrite_r_id
	elif NetworkClient and NetworkClient.room_id != "":
		r_id = NetworkClient.room_id
	var mode_id := str(AppwriteMatchmaking.current_room.get("modeId", "2v2")) if AppwriteMatchmaking and AppwriteMatchmaking.current_room is Dictionary else "2v2"
	var initial_players = _build_initial_server_players()
	NetworkClient.send_join_room(r_id, my_seat, initial_players, mode_id)
	var s_name = NetworkClient.active_server_name if ("active_server_name" in NetworkClient and not NetworkClient.active_server_name.is_empty()) else "Game Server"
	var s_url = NetworkClient.active_server_url if ("active_server_url" in NetworkClient and not NetworkClient.active_server_url.is_empty()) else NetworkClient.server_url
	_add_log("🌐 [ĐỒNG BỘ MẠNG] Ưu tiên: Đã kết nối %s (%s)! Phòng: %s, Ghế: %d" % [s_name, s_url, r_id, my_seat])

func _on_network_player_joined(joined_seat: int, active_seats: Array) -> void:
	for s in active_seats:
		var s_num = int(s)
		if generals_data.has(s_num) and s_num != my_seat:
			if generals_data[s_num].get("isAI", false):
				generals_data[s_num]["isAI"] = false
				_add_log("👤 [KẾT NỐI MẠNG] Người chơi thật đã nhận Ghế %d! Chuyển quyền điều khiển cho người thật." % s_num)
	if joined_seat > 0 and joined_seat != my_seat:
		_add_log("👋 Tướng Ghế %d đã tham gia phòng qua Local Server!" % joined_seat)

func _on_network_error_received(err_msg: String) -> void:
	_clear_lien_chau_selection()
	if current_server_phase == "AWAIT_NGHICH_Y" and not end_turn_btn.disabled:
		# Keep the card and target selected so a transient rejected/stale request can be retried.
		is_targeting_nghich_y = true
		_update_action_btn()
	if hung_suc_submission_pending:
		hung_suc_submission_pending = false
		_update_action_btn()
	reaction_submission_pending = false
	reaction_submission_version = -1
	discard_submission_pending = false
	uat_khi_submission_pending = false
	thuy_trieu_rut_give_sent = false

	if err_msg.contains("Không phải lượt phản ứng") or err_msg.contains("Chưa tới lượt"):
		_close_dodge_reaction_state()
		_close_rescue_modal()
		_close_song_cung_modal()
		if err_msg.contains("Chưa tới lượt"):
			is_player_turn = false
			is_discard_phase = false
			card_play_btn.visible = false
			end_turn_btn.visible = false

	if NetworkClient and NetworkClient.is_connected_to_server:
		NetworkClient.send_get_state()
	_add_log("⚠️ [MẠNG SERVER] %s" % err_msg)

func _sync_player_hand_from_server(server_hand: Array) -> void:
	# Luôn dựng lại tay theo máy chủ, kể cả trong pha bỏ bài. Nếu giữ tay cũ
	# trong lúc đang chờ xác nhận, các lá còn lại sau Lập Làng có thể biến mất
	# khỏi UI và người chơi không thể chọn để bỏ tiếp.
	if server_hand.is_empty():
		for child in hand_container.get_children():
			if child == exit_battle_btn or child.has_meta("song_cung_equipped_preview"):
				continue
			selected_song_cung_card_nodes.erase(child)
			hand_container.remove_child(child)
			child.queue_free()
		selected_card_ui = null
		if generals_data.has(my_seat):
			generals_data[my_seat]["hand_count"] = 0
			if generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
				generals_data[my_seat]["avatar_node"].update_hand_count(0)
		_relayout_hand_cards()
		return

	# Không được xóa tay hiện tại khi server gửi nhầm tay đã ẩn.
	var has_hidden_card = false
	for server_card in server_hand:
		if server_card is Dictionary and (str(server_card.get("id", "")) == "HIDDEN" or str(server_card.get("name", "")) == "Ẩn"):
			has_hidden_card = true
			break
	if has_hidden_card:
		print("[Battle 2v2] Cảnh báo: Nhận trúng gói bài ẩn (HIDDEN), giữ tay hiện tại và yêu cầu đồng bộ lại.")
		if generals_data.has(my_seat):
			generals_data[my_seat]["hand_count"] = server_hand.size()
			if generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
				generals_data[my_seat]["avatar_node"].update_hand_count(server_hand.size())
		if not hand_sync_recovery_sent and NetworkClient and NetworkClient.is_connected_to_server:
			hand_sync_recovery_sent = true
			NetworkClient.send_get_state()
		return
	hand_sync_recovery_sent = false

	var current_cards: Array = []
	for child in hand_container.get_children():
		if child == exit_battle_btn or child.has_meta("hung_suc_equipped_preview") or child.has_meta("song_cung_equipped_preview"):
			continue
		var info = _get_card_info_from_ui(child)
		current_cards.append([str(info.get("id", "")), str(info.get("name", "")), int(info.get("subType", -1))])

	var server_cards: Array = []
	for c in server_hand:
		server_cards.append([str(c.get("id", "")), str(c.get("name", "")), int(c.get("subType", -1))])

	if current_cards == server_cards:
		return
	var selected_card_id := ""
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_id = str(_get_card_info_from_ui(selected_card_ui).get("id", ""))
	var selected_reaction_card_id := ""
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		selected_reaction_card_id = str(_get_card_info_from_ui(selected_dodge_card_ui).get("id", ""))
	var selected_song_cung_ids: Array[String] = []
	for node in selected_song_cung_card_nodes:
		if is_instance_valid(node) and not node.has_meta("song_cung_equipped_preview"):
			selected_song_cung_ids.append(str(_get_card_info_from_ui(node).get("id", "")))

	# Thu thập các thẻ bài hiện có theo id để tái sử dụng, tránh hủy và tạo lại gây giật/nháy hình
	var existing_nodes_by_id: Dictionary = {}
	for child in hand_container.get_children():
		if child == exit_battle_btn or child.has_meta("hung_suc_equipped_preview") or child.has_meta("song_cung_equipped_preview"):
			continue
		var cid = str(_get_card_info_from_ui(child).get("id", ""))
		if not cid.is_empty() and not existing_nodes_by_id.has(cid):
			existing_nodes_by_id[cid] = child
		else:
			hand_container.remove_child(child)
			child.queue_free()

	# Xóa những lá bài không còn trong server_hand
	var server_ids_map: Dictionary = {}
	for c in server_hand:
		server_ids_map[str(c.get("id", ""))] = true

	for cid in existing_nodes_by_id.keys():
		if not server_ids_map.has(cid):
			var node_to_remove = existing_nodes_by_id[cid]
			if node_to_remove == selected_card_ui:
				selected_card_ui = null
			if node_to_remove == selected_dodge_card_ui:
				selected_dodge_card_ui = null
			selected_song_cung_card_nodes.erase(node_to_remove)
			hand_container.remove_child(node_to_remove)
			node_to_remove.queue_free()
			existing_nodes_by_id.erase(cid)

	# Giữ hoặc khởi tạo các lá bài theo thứ tự server_hand
	var target_order_nodes: Array[Control] = []
	for c in server_hand:
		var c_id = str(c.get("id", ""))
		var card_ui: Control = null
		if existing_nodes_by_id.has(c_id):
			card_ui = existing_nodes_by_id[c_id]
		else:
			var c_name = str(c.get("name", "Bài"))
			if _is_dai_hong_thuy_name(c_name):
				c_name = "Đại Hồng Thủy"
			var c_rank = c.get("rank", 1)
			var c_suit = str(c.get("suit", "Spade"))
			var c_cat = int(c.get("category", 0))
			var c_desc = str(c.get("desc", ""))
			var c_sub_type = int(c.get("subType", -1))
			if c_sub_type == 26 or c_name == "Hịch Tướng Sĩ":
				c_desc = "Bạn và 1 người khác bạn chọn, bỏ 1 lá để nhận Sục Sôi: 1 vòng không giới hạn Trảm, tầm đánh +1. Có thể đổi lá để rút lá khác."

			card_ui = CardUIScene.instantiate()
			var init_x = hand_container.size.x
			if not target_order_nodes.is_empty() and is_instance_valid(target_order_nodes.back()):
				init_x = target_order_nodes.back().position.x + 30.0
			card_ui.position.x = init_x
			card_ui.modulate.a = 0.0
			hand_container.add_child(card_ui)
			card_ui.setup_card_data(c_id, c_name, c_rank, c_suit, c_cat, c_desc, c_sub_type)
			var fade_in_tw = card_ui.create_tween()
			fade_in_tw.tween_property(card_ui, "modulate:a", 1.0, 0.18)
			var c_info = {
				"id": c_id,
				"name": c_name,
				"rank": c_rank,
				"suit": c_suit,
				"cat": c_cat,
				"desc": c_desc,
				"subType": c_sub_type,
				"card_node": card_ui
			}
			card_ui.card_clicked.connect(func(_c): _on_player_hand_card_clicked(card_ui, c_info))
		target_order_nodes.append(card_ui)
		if is_waiting_song_cung and c_id in selected_song_cung_ids:
			if not selected_song_cung_card_nodes.has(card_ui):
				selected_song_cung_card_nodes.append(card_ui)
			card_ui.set_selected(true)

	for i in range(target_order_nodes.size()):
		var node = target_order_nodes[i]
		if node.get_parent() == hand_container and node.get_index() != i:
			hand_container.move_child(node, i)

	if generals_data.has(my_seat):
		generals_data[my_seat]["hand_count"] = server_hand.size()
		if generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
			generals_data[my_seat]["avatar_node"].update_hand_count(server_hand.size())

	_relayout_hand_cards()

	if selected_card_ui == null and not selected_card_id.is_empty():
		for card_ui in hand_container.get_children():
			if str(_get_card_info_from_ui(card_ui).get("id", "")) == selected_card_id:
				selected_card_ui = card_ui
				card_ui.set_selected(true)
				break
	if not selected_reaction_card_id.is_empty() and is_waiting_dodge:
		for card_ui in hand_container.get_children():
			if str(_get_card_info_from_ui(card_ui).get("id", "")) == selected_reaction_card_id:
				selected_dodge_card_ui = card_ui
				card_ui.set_selected(true)
				var reaction_info := _get_card_info_from_ui(card_ui)
				var suit_name := _get_suit_name(reaction_info.get("suit", ""))
				var rank_str := _format_rank(reaction_info.get("rank", 1))
				var reaction_name := str(reaction_info.get("name", "Bài"))
				var card_tag := "%s %s" % [rank_str, suit_name] if not suit_name.is_empty() else rank_str
				dodge_confirm_btn.disabled = false
				dodge_confirm_btn.text = "%s [%s %s]" % [current_reaction_confirm_prefix, card_tag, reaction_name]
				if dodge_selected_lbl:
					dodge_selected_lbl.text = "👉 Đang chọn: [%s %s] (Bấm nút để xác nhận)" % [card_tag, reaction_name]
				break
	_update_action_btn()

	if generals_data.has(my_seat):
		var g = generals_data[my_seat]
		g["hand_count"] = server_hand.size()
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].update_hand_count(g["hand_count"])
			g["avatar_node"].update_an_tich_count(int(g.get("an_tich_count", 0)))

func _clear_normal_hand_selection() -> void:
	_clear_lien_chau_selection()
	for card_node in hand_container.get_children():
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
	selected_card_ui = null

func _clear_uat_khi_selection() -> void:
	if uat_khi_target_seat > 0 and generals_data.has(uat_khi_target_seat):
		var target = generals_data[uat_khi_target_seat]
		if target.has("avatar_node") and is_instance_valid(target["avatar_node"]):
			target["avatar_node"].set_target_highlight(false)
	uat_khi_target_seat = -1

func _begin_uat_khi_prompt() -> void:
	_clear_uat_khi_selection()
	uat_khi_pending = true
	uat_khi_submission_pending = false
	current_waiting_seat = my_seat
	current_waiting_timer = 40.0
	end_turn_btn.visible = true
	end_turn_btn.disabled = false
	end_turn_btn.text = "BỎ QUA"
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].set_turn_active(true)
		generals_data[my_seat]["avatar_node"].update_turn_timer(40)

func _choose_ai_uat_khi_targets(ai_seat: int) -> Array[int]:
	var ai_gen = generals_data.get(ai_seat, {})
	var ai_team = ai_gen.get("isDragon", (ai_seat == 1 or ai_seat == 3))
	var other_allies: Array[int] = []
	for s in generals_data.keys():
		var s_num = int(s)
		if s_num != ai_seat and generals_data.has(s_num):
			var g = generals_data[s_num]
			if g.get("is_alive", false) and int(g.get("hp", 0)) > 0:
				var s_team = g.get("isDragon", (s_num == 1 or s_num == 3))
				if s_team == ai_team:
					other_allies.append(s_num)
	if other_allies.is_empty():
		return []
	other_allies.sort_custom(func(a: int, b: int) -> bool:
		var hp_a = float(generals_data[a].get("hp", 1)) / float(max(1, generals_data[a].get("max_hp", 1)))
		var hp_b = float(generals_data[b].get("hp", 1)) / float(max(1, generals_data[b].get("max_hp", 1)))
		if hp_a != hp_b:
			return hp_a < hp_b
		var count_a = hand_container.get_child_count() if a == my_seat else int(generals_data[a].get("hand_count", 0))
		var count_b = hand_container.get_child_count() if b == my_seat else int(generals_data[b].get("hand_count", 0))
		return count_a < count_b
	)
	var result: Array[int] = []
	for i in range(min(2, other_allies.size())):
		result.append(other_allies[i])
	return result

func _choose_ai_uat_khi_target(ai_seat: int) -> int:
	var targets = _choose_ai_uat_khi_targets(ai_seat)
	return targets[0] if not targets.is_empty() else 0

func _clear_lien_chau_selection() -> void:
	if lien_chau_cost_card and is_instance_valid(lien_chau_cost_card):
		lien_chau_cost_card.set_selected(false)
	lien_chau_cost_card = null
	is_selecting_lien_chau_target = false
	lien_chau_prompt_decided = false
	if lien_chau_target_seat > 0 and generals_data.has(lien_chau_target_seat):
		var avatar = generals_data[lien_chau_target_seat].get("avatar_node")
		if is_instance_valid(avatar):
			avatar.set_target_highlight(false)
	lien_chau_target_seat = -1

func _setup_lien_chau_prompt() -> void:
	lien_chau_prompt = ConfirmationDialog.new()
	lien_chau_prompt.title = "🏹 LIÊN CHÂU"
	lien_chau_prompt.dialog_text = "Bỏ 1 lá bài khác để chọn thêm 1 mục tiêu trong tầm đánh?"
	lien_chau_prompt.ok_button_text = "DÙNG LIÊN CHÂU"
	lien_chau_prompt.cancel_button_text = "BỎ QUA"
	lien_chau_prompt.exclusive = true
	lien_chau_prompt.confirmed.connect(_on_lien_chau_prompt_confirmed)
	lien_chau_prompt.canceled.connect(_on_lien_chau_prompt_canceled)
	add_child(lien_chau_prompt)

func _offer_lien_chau_after_first_target() -> bool:
	if lien_chau_prompt_decided or lien_chau_target_seat > 0 or is_selecting_lien_chau_target or not selected_card_ui or not is_instance_valid(selected_card_ui):
		return false
	var card_info = _get_card_info_from_ui(selected_card_ui)
	var me = generals_data.get(my_seat, {})
	if "Trảm" not in str(card_info.get("name", "")) or not _can_use_lien_chau(me) or not _has_no_than(me):
		return false
	var has_cost_card := false
	for hand_card in hand_container.get_children():
		if hand_card != selected_card_ui:
			has_cost_card = true
			break
	if not has_cost_card:
		return false
	for seat in generals_data:
		var target = generals_data[seat]
		if seat != my_seat and seat != selected_target_seat and target.get("is_alive", false) and _calculate_distance(my_seat, seat) <= _get_attack_range(my_seat):
			lien_chau_prompt.popup_centered()
			return true
	return false

func _on_lien_chau_prompt_confirmed() -> void:
	if not selected_card_ui or not is_instance_valid(selected_card_ui) or selected_target_seat <= 0:
		return
	lien_chau_prompt_decided = true
	is_selecting_lien_chau_target = true
	desc_text.text = "🏹 Liên Châu: chọn thêm 1 mục tiêu khác trong tầm đánh."

func _on_lien_chau_prompt_canceled() -> void:
	lien_chau_prompt_decided = true
	is_selecting_lien_chau_target = false
	desc_text.text = "⚔️ Đã bỏ qua Liên Châu. Bấm Trảm để tấn công %s." % generals_data.get(selected_target_seat, {}).get("name", "mục tiêu")

func _sync_player_equipments_from_server(seat: int, equips: Array) -> void:
	if not generals_data.has(seat) or not generals_data[seat].has("avatar_node"):
		return
	var g = generals_data[seat]
	g["equipment_cards"] = equips.duplicate(true)
	var avatar = g["avatar_node"]
	if not is_instance_valid(avatar):
		return

	var weapon_names: Array[String] = []
	var weapon_suits: Array[String] = []
	var armor = ""
	var armor_sr = ""
	var off_h = ""
	var off_h_sr = ""
	var treasure = ""
	var treasure_sr = ""
	var def_h = ""
	var def_h_sr = ""

	for e in equips:
		if not (e is Dictionary):
			continue
		var st = int(e.get("subType", -1))
		var e_name = _get_card_display_name(e)
		var s_icon = _get_suit_icon(str(e.get("suit", "")))
		var r_str = _format_rank(e.get("rank", 0)) if int(e.get("rank", 0)) > 0 else ""
		var sr = (s_icon + r_str).strip_edges()

		if st == 6 or "Kiếm" in e_name or "Cung" in e_name or "Nỏ" in e_name or "Đao" in e_name or "Thương" in e_name or "Súng" in e_name:
			weapon_names.append(e_name)
			weapon_suits.append(sr)
		elif st == 7 or "Giáp" in e_name or "Khiên" in e_name or "Áo Bào" in e_name:
			armor = e_name
			armor_sr = sr
		elif st == 8 or "Ngựa Trắng" in e_name or "ngựa công" in e_name.to_lower():
			off_h = e_name
			off_h_sr = sr
		elif st == 9 or "Voi Chiến" in e_name or "ngựa thủ" in e_name.to_lower():
			def_h = e_name
			def_h_sr = sr
		elif st == 27 or "Trống Đồng" in e_name:
			treasure = e_name
			treasure_sr = sr

	var weapon = " + ".join(weapon_names)
	var weapon_sr = " + ".join(weapon_suits)
	g["equipped_weapon"] = weapon
	g["equipped_armor"] = armor
	g["equipped_off_horse"] = off_h
	g["equipped_def_horse"] = def_h
	g["equipped_treasure"] = treasure
	# Đồng bộ lại nhãn cả khi state không đổi: node UI có thể vừa được khởi tạo lại.
	avatar.set_equipment("weapon", weapon, weapon_sr)
	avatar.set_equipment("armor", armor, armor_sr)
	avatar.set_equipment("off_horse", off_h, off_h_sr)
	avatar.set_equipment("def_horse", def_h, def_h_sr)
	avatar.set_equipment("treasure", treasure, treasure_sr)
	_refresh_local_skill_buttons(seat)
	if seat == my_seat and (is_targeting_hung_suc or is_targeting_cai_cach):
		_refresh_hung_suc_equipped_weapon_previews()
	if seat == my_seat and is_waiting_song_cung:
		_refresh_song_cung_equipped_previews()
		_update_song_cung_ui()

func _has_equipped_weapon_name(general: Dictionary, weapon_name: String) -> bool:
	return weapon_name in str(general.get("equipped_weapon", ""))

func _enter_discard_phase(excess: int) -> void:
	is_player_turn = true
	is_discard_phase = true
	discard_submission_pending = false
	cards_to_discard_count = excess
	selected_discard_nodes.clear()
	pending_discard_card_ids.clear()
	current_turn_timer = 40.0
	turn_indicator.text = "⏳ BỎ %d LÁ BÀI THỪA (40s)!" % cards_to_discard_count
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].update_turn_timer(40)

	# Bỏ hoàn toàn nút BỎ HẾT & KẾT THÚC
	end_turn_btn.visible = false

	# Bỏ chọn mọi lá bài trên tay trước đó
	for c in hand_container.get_children():
		if c.has_method("set_selected"):
			c.set_selected(false)
	selected_card_ui = null

	card_play_btn.visible = true
	card_play_btn.disabled = true
	card_play_btn.text = "🗑️ BỎ BÀI (0/%d)" % cards_to_discard_count
	desc_text.text = "⚠️ Giai đoạn bỏ bài (40s): Bạn có %d lá bài thừa! Hãy nhấp chọn %d lá trên tay để bỏ." % [cards_to_discard_count, cards_to_discard_count]
	_add_log("⚠️ [BỎ BÀI]: Bạn cần chọn %d lá bài thừa trên tay để bỏ và kết thúc lượt!" % cards_to_discard_count)

func _on_network_game_state_updated(state: Dictionary) -> void:
	if state == null or not (state is Dictionary) or state.is_empty():
		return
	var now_msec = Time.get_ticks_msec()
	var state_delta = state.get("delta", {})
	var has_bai_coc_judgement = state_delta is Dictionary and (
		str(state_delta.get("type", "")).begins_with("BAI_COC_BACH_DANG")
		or (state_delta.get("baiCocJudgeCard", {}) is Dictionary and not state_delta.get("baiCocJudgeCard", {}).is_empty())
	)
	if has_bai_coc_judgement or now_msec < bai_coc_state_sync_until_msec:
		pending_bai_coc_state = state.duplicate(true)
		if now_msec >= bai_coc_state_sync_until_msec:
			bai_coc_state_sync_until_msec = now_msec + BAI_COC_JUDGEMENT_VISUAL_MSEC
			get_tree().create_timer(float(BAI_COC_JUDGEMENT_VISUAL_MSEC) / 1000.0).timeout.connect(_apply_pending_bai_coc_state_sync, CONNECT_ONE_SHOT)
		return
	_apply_network_game_state(state)

func _apply_pending_bai_coc_state_sync() -> void:
	var deferred_state = pending_bai_coc_state
	pending_bai_coc_state = {}
	bai_coc_state_sync_until_msec = 0
	if not deferred_state.is_empty():
		_apply_network_game_state(deferred_state)

func _should_replay_history_effect(history_type: String, current_delta: Dictionary) -> bool:
	if history_type.begins_with("BAI_COC_BACH_DANG"):
		var delta_type = str(current_delta.get("type", current_delta.get("actionType", "")))
		var attached_judge = current_delta.get("baiCocJudgeCard", {})
		if delta_type.begins_with("BAI_COC_BACH_DANG"):
			return false
		if attached_judge is Dictionary and not attached_judge.is_empty():
			return false
	return true

func _get_han_lam_revealed_card(state: Dictionary, current_delta: Dictionary) -> Dictionary:
	var card = state.get("hanLamRevealedCard", {})
	if card is Dictionary and not card.is_empty():
		return card
	card = current_delta.get("revealedCard", {})
	if card is Dictionary and not card.is_empty():
		return card
	var last_action = state.get("lastAction", {})
	if last_action is Dictionary and str(last_action.get("type", "")) == "HAN_LAM_PROMPT":
		card = last_action.get("revealedCard", {})
		if card is Dictionary:
			return card
	return {}

func _apply_network_game_state(state: Dictionary) -> void:
	if state == null or not (state is Dictionary) or state.is_empty():
		return
	is_network_mode = true
	var previous_server_phase = current_server_phase
	var server_version = int(state.get("version", -1))
	if server_version >= 0 and server_version < last_server_version:
		return
	if server_version > last_server_version:
		last_server_version = server_version
	if reaction_submission_pending and reaction_submission_version >= 0 and server_version > reaction_submission_version:
		# A state refresh in the same reaction phase can arrive before the server
		# handles the submitted card. Keep the modal locked until the phase or
		# waiting seat changes, otherwise Dẫn Cầu briefly reopens and clears the
		# selected Trảm.
		var incoming_phase := str(state.get("phase", current_server_phase))
		var incoming_waiting_seat := int(state.get("waitingTargetSeat", current_waiting_seat))
		if incoming_phase not in ["AWAIT_SLASH_DEFENSE", "AWAIT_DAN_CAU"] or incoming_waiting_seat != my_seat:
			reaction_submission_pending = false
			reaction_submission_version = -1

	# 1. Đồng bộ người chơi (HP, MaxHP, Chained, Equipments, Hand)
	var players = state.get("players", [])
	if not (players is Array):
		return
	# The authoritative server owns the draw pile in network games. Keep the
	# HUD tied to that value instead of the local demo pile counter.
	if state.has("deckCount"):
		deck_count = max(0, int(state.get("deckCount", deck_count)))
		_update_deck_hud()
	var server_history = state.get("actionHistory", [])
	var current_delta = state.get("delta", {})
	if not (current_delta is Dictionary):
		current_delta = {}
	if server_history is Array and not server_history.is_empty():
		var initial_history_sync := last_processed_history_seq < 0
		var newest_history_seq := -1
		for history_item in server_history:
			if history_item is Dictionary:
				newest_history_seq = maxi(newest_history_seq, int(history_item.get("seq", -1)))
		history_entries.clear()
		for history_item in server_history:
			if history_item is Dictionary:
				var desc_str = str(history_item.get("description", ""))
				if not desc_str.is_empty():
					history_entries.append(desc_str)
				var h_seq = int(history_item.get("seq", -1))
				if h_seq > last_processed_history_seq:
					last_processed_history_seq = h_seq
					var h_type = str(history_item.get("type", ""))
					var has_skill_feedback := not _get_skill_activations(history_item).is_empty()
					var should_replay_skill := has_skill_feedback and (not initial_history_sync or h_seq == newest_history_seq)
					if _should_replay_history_effect(h_type, current_delta) and (should_replay_skill or h_type in [
						"DAI_HONG_THUY_HIT", "DAI_HONG_THUY_PASSED",
						"LIGHTNING_HIT", "LIGHTNING_PASSED",
						"SUPPLY_SHORTAGE_TRIGGERED", "SUPPLY_SHORTAGE_PASSED",
						"ACEDIA_TRIGGERED", "ACEDIA_PASSED",
						"KHIEN_MAY_SUCCESS", "KHIEN_MAY_FAILED",
						"BAI_COC_BACH_DANG_SAFE", "BAI_COC_BACH_DANG_TRIGGERED"
					]):
						_on_network_action_received(history_item)
		while history_entries.size() > 50:
			history_entries.pop_front()
		_render_history()
	for p in players:
		if not (p is Dictionary):
			continue
		var seat = int(p.get("seat", 0))
		if not generals_data.has(seat):
			continue
		var g = generals_data[seat]
		g["che_no_active"] = _is_server_skill_active(p, "Chế Nỏ")
		var old_hand_count = int(g.get("hand_count", 0))
		if p.has("isAlly"):
			g["isDragon"] = bool(p.get("isAlly", g.get("isDragon", false)))
			if seat == my_seat:
				my_team_is_dragon = g["isDragon"]
		var server_hp = int(p.get("hp", g["hp"]))
		var server_max_hp = int(p.get("maxHp", g["max_hp"]))
		# The server hides other players' roles. Do not erase a role already
		# received from the private draft snapshot when the incoming value is empty.
		var incoming_role := str(p.get("role", ""))
		if not incoming_role.is_empty():
			g["role"] = incoming_role
		var server_is_alive = bool(p.get("isAlive", g.get("is_alive", true)))
		var was_alive = bool(g.get("is_alive", true))
		g["suc_soi_turns_remaining"] = max(0, int(p.get("sucSoiTurnsRemaining", g.get("suc_soi_turns_remaining", 0))))
		g["is_wine_buff_active"] = bool(p.get("isWineBuffActive", g.get("is_wine_buff_active", false)))
		g["wine_used_this_turn"] = bool(p.get("wineUsedThisTurn", g.get("wine_used_this_turn", false)))
		g["an_tich_count"] = int(p.get("anTichCount", 1 if bool(p.get("hasAnTich", false)) else 0))
		g["an_tich_cards"] = p.get("anTichCards", []) if p.get("anTichCards", []) is Array else []
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].update_an_tich_count(g["an_tich_count"])
		if seat == my_seat:
			is_wine_buff_active = g["is_wine_buff_active"]
			wine_used_this_turn = g["wine_used_this_turn"]
		if g.get("is_alive", true) and not server_is_alive:
			g["is_alive"] = false
			if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
				g["avatar_node"].set_defeated(true)
			if seat == my_seat and was_alive:
				_show_dead_player_exit()
		var is_first_sync = not g.get("hp_synced", false)
		g["hp_synced"] = true

		if server_hp != g["hp"] or server_max_hp != g["max_hp"] or is_first_sync:
			var old_hp = g["hp"]
			g["hp"] = server_hp
			g["max_hp"] = server_max_hp
			var now_msec = Time.get_ticks_msec()
			var just_healed = recent_heal_seats.has(seat) and (now_msec - recent_heal_seats[seat] < 1500)

			if not is_first_sync and server_hp < old_hp and old_hp > 0 and server_hp < server_max_hp and not just_healed:
				var dmg = old_hp - server_hp
				var effect_element = str(pending_damage_elements.get(seat, "NORMAL"))
				pending_damage_elements.erase(seat)
				_trigger_damage_effects(seat, dmg, effect_element)
			elif not is_first_sync and server_hp > old_hp:
				recent_heal_seats[seat] = now_msec
				if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
					g["avatar_node"].play_heal_effect()
			if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
				g["avatar_node"].update_hp(g["hp"], server_max_hp, is_first_sync)

		# Đồng bộ danh tướng (Tên, Ảnh chân dung, Kỹ năng) từ Server
		var s_hero_name = str(p.get("generalName", ""))
		var s_hero_id = str(p.get("heroId", ""))
		if s_hero_name != "" and (g["name"].begins_with("Tướng ") or g["name"] != s_hero_name):
			g["name"] = s_hero_name
			if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
				if g["avatar_node"].name_label and is_instance_valid(g["avatar_node"].name_label):
					g["avatar_node"].name_label.text = s_hero_name
				var num_id = 0
				if s_hero_id.begins_with("HERO_"):
					num_id = int(s_hero_id.trim_prefix("HERO_"))
				elif s_hero_id.is_valid_int():
					num_id = int(s_hero_id)
				var h_data = HeroDatabase.get_hero(num_id) if (HeroDatabase and num_id > 0) else (HeroDatabase.get_hero_by_name(s_hero_name) if HeroDatabase else {})
				if h_data is Dictionary and not h_data.is_empty():
					g["hero_data"] = h_data
					g["hero_id"] = int(h_data.get("id", num_id))
					var slug = h_data.get("slug", "")
					if slug != "":
						var tex_path = "res://assets/ui/" + slug + ".png"
						if ResourceLoader.exists(tex_path) and is_instance_valid(g["avatar_node"].portrait_rect):
							g["avatar_node"].portrait_rect.texture = load(tex_path)
					var synced_treasure = str(g.get("equipped_treasure", ""))
					g["avatar_node"].set_skill("🥁 ĐIỂM TRỐNG" if (synced_treasure == "Trống Đồng Đông Sơn" and seat == my_seat) else ("🐯 HỔ PHÙ" if (synced_treasure == "Hổ Phù Trần Triều" and seat == my_seat) else ""))
					if seat == my_seat and g["avatar_node"].has_method("set_treasure_skill_selected"):
						g["avatar_node"].set_treasure_skill_selected(is_targeting_drum_skill or is_targeting_ho_phu_skill)

		var is_chained = bool(p.get("isChained", false))
		if is_chained != g.get("is_chained", false):
			g["is_chained"] = is_chained
			if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
				g["avatar_node"].set_chained(is_chained)

		# Đồng bộ bài
		if seat != my_seat:
			var server_hand_count = int(p.get("handCount", g["hand_count"]))
			if server_hand_count > old_hand_count:
				_animate_draw_to_seat(seat, server_hand_count - old_hand_count)
			if server_hand_count != g["hand_count"]:
				g["hand_count"] = server_hand_count
				if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
					g["avatar_node"].update_hand_count(server_hand_count)
		else:
			var server_hand = p.get("hand", [])
			if server_hand is Array and (not server_hand.is_empty() or p.has("hand")):
				if server_hand.size() > old_hand_count:
					_animate_draw_to_seat(my_seat, server_hand.size() - old_hand_count)
				_sync_player_hand_from_server(server_hand)
				# Keep every existing and newly drawn Spade visually transformed.
				if g["che_no_active"]:
					_set_local_che_no_hand(true)
			if seat == my_seat and not server_is_alive:
				_show_dead_player_exit()

		# Đồng bộ trang bị
		var equips = p.get("equipments", [])
		if equips is Array:
			_sync_player_equipments_from_server(seat, equips)

		# Đồng bộ cẩm nang trì hoãn (Khu Phán Xét / Judgements) từ Server
		var judgements = p.get("judgements", [])
		var has_dai_hong_thuy = false
		var has_cat_luong = false
		var has_tram_ao = false
		var has_bai_coc = false
		if judgements is Array:
			for j_card in judgements:
				if not (j_card is Dictionary):
					continue
				var c_sub = int(j_card.get("subType", 0))
				var c_n = str(j_card.get("name", "")).to_lower()
				if c_sub == 19 or "đại hồng thủy" in c_n or "dai hong thuy" in c_n or "sấm" in c_n or "lightning" in c_n:
					has_dai_hong_thuy = true
				elif c_sub == 20 or "lương" in c_n or "supply" in c_n:
					has_cat_luong = true
				elif c_sub == 21 or "trầm" in c_n or "acedia" in c_n:
					has_tram_ao = true
				elif c_sub == 22 or "bạch đằng" in c_n or "bai coc bach dang" in c_n:
					has_bai_coc = true

		if _hero_has_skill(g, "thuy_chien"):
			has_bai_coc = false

		g["has_dai_hong_thuy"] = has_dai_hong_thuy
		g["has_lightning"] = has_dai_hong_thuy # Legacy state alias.
		g["has_cat_luong"] = has_cat_luong
		g["has_tram_ao"] = has_tram_ao
		g["has_bai_coc"] = has_bai_coc
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_delayed_trick("dai_hong_thuy", has_dai_hong_thuy)
			g["avatar_node"].set_delayed_trick("cat_luong", has_cat_luong)
			g["avatar_node"].set_delayed_trick("tram_ao", has_tram_ao)
			g["avatar_node"].set_delayed_trick("bai_coc", has_bai_coc)

	# 2. Đồng bộ Lượt và Giai đoạn (Authoritative Turn & Phase từ Server)
	var server_turn_seat = int(state.get("turnSeat", 1))
	var server_phase = str(state.get("phase", "PLAY"))
	var server_turn_timer = int(state.get("turnTimer", 40))
	var server_waiting_seat = int(state.get("waitingTargetSeat", 0))
	var server_waiting_timer = int(state.get("waitingTimer", 0))

	current_server_phase = server_phase
	current_turn_seat = server_turn_seat
	current_waiting_seat = server_waiting_seat
	current_waiting_timer = float(server_waiting_timer)
	if previous_server_phase == "AWAIT_NGHICH_Y" and server_phase != "AWAIT_NGHICH_Y":
		is_targeting_nghich_y = false
		selected_nghich_y_card_id = ""
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		card_play_btn.visible = false
	# Uất Khí chỉ tồn tại trong đúng pha chờ server; dọn trạng thái cũ
	# trước khi phần render pha hiện tại thiết lập lại nút hành động.
	if server_phase != "AWAIT_UAT_KHI" and server_phase != "AWAIT_UAT_KHI_TARGET" and uat_khi_pending:
		_clear_uat_khi_selection()
		uat_khi_pending = false
		uat_khi_submission_pending = false
	if server_phase != "AWAIT_HARVEST" and harvest_modal and harvest_modal.visible:
		_hide_harvest_modal()
	if server_phase != "AWAIT_NEAR_DEATH" and is_waiting_rescue:
		_close_rescue_modal()
	# Cứu Hấp Hối và Mượn Gươm là các phản ứng độc quyền. Nếu state vừa đổi
	# pha, không để modal Đỡ/Trảm cũ chiếm lần bấm đầu tiên trên bài trên tay.
	if server_waiting_seat != my_seat:
		if is_waiting_dodge or is_waiting_song_cung or is_waiting_oai_nhuoc:
			_close_song_cung_modal()
			_close_dodge_reaction_state()
		if is_waiting_rescue:
			_close_rescue_modal()
		reaction_submission_pending = false
	elif previous_server_phase != server_phase and server_phase in ["AWAIT_NEAR_DEATH", "AWAIT_BORROW_SWORD"]:
		_close_dodge_reaction_state()
	elif previous_server_phase in ["AWAIT_SLASH_DEFENSE", "AWAIT_OAI_NHUOC", "AWAIT_HICH_CASTER_DISCARD", "AWAIT_HICH_TARGET_DISCARD", "AWAIT_DRUM_CHOICE", "AWAIT_SONG_CUNG_FOLLOW_UP", "AWAIT_DAN_CAU"] and server_phase != previous_server_phase and (is_waiting_dodge or is_waiting_song_cung):
		_close_song_cung_modal()
		_close_dodge_reaction_state()
	if server_phase not in ["AWAIT_SLASH_DEFENSE", "AWAIT_DAN_CAU"] or server_waiting_seat != my_seat:
		reaction_submission_pending = false
	if server_phase != "AWAIT_AOE":
		is_giac_toi_reaction = false
	if server_phase != "AWAIT_THUY_TRIEU_RUT_GIVE":
		thuy_trieu_rut_give_sent = false
		if is_waiting_thuy_trieu_rut_give:
			_close_thuy_trieu_rut_give_prompt()
	if server_phase != "AWAIT_HARVEST":
		harvest_choice_sent = false
		harvest_modal_signature = ""
		harvest_waiting_seat = 0
		_hide_harvest_modal()
	elif server_waiting_seat != harvest_waiting_seat:
		harvest_choice_sent = false
		harvest_modal_signature = ""
	var keep_reaction_hand_selection = server_waiting_seat == my_seat and (is_waiting_dodge or is_waiting_thuy_trieu_rut_give or is_waiting_song_cung or server_phase in ["AWAIT_DA_TRACH_DISCARD", "AWAIT_VAN_SACH", "AWAIT_NGHICH_Y"])
	if server_phase not in ["PLAY", "DISCARD", "AWAIT_HUYNH_TRUONG", "AWAIT_DA_TRACH_DISCARD", "AWAIT_VAN_SACH", "AWAIT_NGHICH_Y", "AWAIT_XUNG_VUONG_TARGET"] or (server_phase == "DISCARD" and server_waiting_seat != my_seat):
		card_play_btn.visible = false
		if not keep_reaction_hand_selection:
			_clear_normal_hand_selection()
		if server_waiting_seat != my_seat:
			_set_reaction_hand_focus(false)
			if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
				dodge_card_selector_scroll.visible = false
	if server_phase not in ["PLAY", "DISCARD", "AWAIT_HUYNH_TRUONG", "AWAIT_DA_TRACH_DISCARD", "AWAIT_VAN_SACH", "AWAIT_NGHICH_Y", "AWAIT_XUNG_VUONG_TARGET"]:
		is_player_turn = false
		is_discard_phase = false
		card_play_btn.visible = false
		if not keep_reaction_hand_selection and not (server_phase == "AWAIT_TARGET_CARD" and server_waiting_seat == my_seat):
			_clear_normal_hand_selection()

	# Đồng bộ trạng thái hấp hối (Near-Death) trên toàn bàn cờ
	if server_phase != "AWAIT_NEAR_DEATH":
		for s in generals_data.keys():
			var g_node = generals_data[s].get("avatar_node")
			if is_instance_valid(g_node):
				g_node.set_near_death(false)

	if state.has("slashesUsedThisTurn"):
		slashes_used_this_turn = int(state.get("slashesUsedThisTurn", 0))

	# Cập nhật vòng sáng và đồng hồ đếm ngược trên Avatar cả 4 ghế:
	# - Khi đang chờ phản ứng (server_waiting_seat > 0): Đồng hồ đếm ngược 40s trên đầu NGƯỜI BỊ TRẢM.
	# - Khi phản ứng kết thúc hoặc trong lượt đánh: Đồng hồ 40s trở về trên đầu NGƯỜI ĐÁNH (server_turn_seat).
	var active_action_seat = server_waiting_seat if (server_waiting_seat > 0 and generals_data.has(server_waiting_seat) and generals_data[server_waiting_seat]["is_alive"]) else server_turn_seat

	for s in range(1, battle_seat_count + 1):
		if generals_data.has(s) and generals_data[s].has("avatar_node") and is_instance_valid(generals_data[s]["avatar_node"]):
			var is_active = (s == active_action_seat and generals_data[s]["is_alive"])
			generals_data[s]["avatar_node"].set_turn_active(is_active)
			var cur_timer = 0
			if is_active:
				if server_waiting_seat > 0 and s == server_waiting_seat:
					cur_timer = server_waiting_timer
				else:
					cur_timer = server_turn_timer
			generals_data[s]["avatar_node"].update_turn_timer(cur_timer)

	var turn_gen = generals_data.get(server_turn_seat, {})
	var turn_gen_name = turn_gen.get("name", "Ghế %d" % server_turn_seat)

	if server_phase == "PLAY":
		is_targeting_chinh_thong = false
		is_targeting_khoan_hoa = false
		huynh_truong_pending = false
		# Refresh skill availability after authoritative HP/hand/turn data is applied.
		_refresh_local_skill_buttons(my_seat)
		current_waiting_seat = 0
		current_waiting_timer = 0.0
		if is_waiting_song_cung:
			_close_song_cung_modal()
		if is_waiting_dodge:
			_close_dodge_reaction_state()
		if is_waiting_rescue:
			_close_rescue_modal()
		reaction_submission_pending = false
		if server_turn_seat == my_seat:
			if not is_player_turn:
				slashes_used_this_turn = int(state.get("slashesUsedThisTurn", 0))
			is_player_turn = true
			is_discard_phase = false
			current_turn_timer = float(server_turn_timer)
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "KẾT THÚC LƯỢT"
			turn_indicator.text = "⏳ LƯỢT CỦA BẠN (%ds)" % server_turn_timer
			if not card_play_btn.visible:
				desc_text.text = "💡 Lượt của bạn: Hãy chọn bài trên tay và mục tiêu để tấn công!"
		else:
			is_player_turn = false
			remote_turn_timer = float(server_turn_timer)
			end_turn_btn.visible = false
			card_play_btn.visible = false
			turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - %ds..." % [turn_gen_name, server_turn_seat, server_turn_timer]
			desc_text.text = "⏳ Đang trong lượt của %s..." % turn_gen_name
			if selected_card_ui and is_instance_valid(selected_card_ui):
				if selected_card_ui.has_method("set_selected"):
					selected_card_ui.set_selected(false)
				selected_card_ui = null
			_update_action_btn()

	elif server_phase == "AWAIT_CHINH_THONG_TARGET":
		is_player_turn = false
		if server_waiting_seat == my_seat:
			is_targeting_chinh_thong = true
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "TỪ CHỐI"
			turn_indicator.text = "📜 CHÍNH THỐNG: CHỌN NGƯỜI (%ds)" % server_waiting_timer
			desc_text.text = "Chọn 1 người khác; họ phải giao 1 lá hoặc lộ toàn bộ bài trên tay."
		else:
			is_targeting_chinh_thong = false
			end_turn_btn.visible = false
		_update_action_btn()

	elif server_phase == "AWAIT_CHINH_THONG_GIVE":
		is_player_turn = false
		card_play_btn.visible = false
		end_turn_btn.visible = false
		if server_waiting_seat == my_seat and not is_waiting_dodge:
			_prompt_reaction_modal("📜 CHÍNH THỐNG", "Chọn 1 lá để giao; hoặc bấm [LỘ BÀI].", "Bài", "LỘ BÀI", "GIAO 1 LÁ", server_waiting_timer, false, true, false, false)
			custom_reaction_callback = func(accepted: bool, card_info: Dictionary):
				NetworkClient.send_respond_action(accepted, str(card_info.get("id", "")))

	elif server_phase == "AWAIT_KHOAN_HOA":
		is_player_turn = false
		if server_waiting_seat == my_seat:
			is_targeting_khoan_hoa = true
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "CHỈ MÌNH RÚT"
			turn_indicator.text = "🤝 KHOAN HÒA: CHỌN THÊM 1 NGƯỜI (%ds)" % server_waiting_timer
			desc_text.text = "Chọn tối đa 2 người khác, mỗi người rút 1 lá; hoặc bấm bỏ qua để kết thúc."
		else:
			is_targeting_khoan_hoa = false
			end_turn_btn.visible = false
		_update_action_btn()

	elif server_phase == "AWAIT_XUNG_VUONG_TARGET":
		is_player_turn = false
		if server_waiting_seat == my_seat:
			is_targeting_khoan_hoa = false
			card_play_btn.visible = true
			end_turn_btn.visible = true
			end_turn_btn.text = "BỎ QUA"
			turn_indicator.text = "👑 XƯNG VƯƠNG: CHỌN NGƯỜI (%ds)" % server_waiting_timer
			desc_text.text = "Chọn tối đa 2 người chơi khác để họ tự bỏ 1 lá trên tay hoặc trang bị."
		else:
			card_play_btn.visible = false
			end_turn_btn.visible = false
		_update_action_btn()

	elif server_phase == "AWAIT_NGHIA_TU":
		is_player_turn = false
		card_play_btn.visible = false
		end_turn_btn.visible = false
		if server_waiting_seat == my_seat and not is_waiting_dodge:
			var protected_seat := int(state.get("nghiaTuTargetSeat", 0))
			if protected_seat <= 0:
				var last_action = state.get("lastAction", {})
				if last_action is Dictionary and str(last_action.get("type", "")) == "NGHIA_TU_PROMPT":
					protected_seat = int(last_action.get("targetSeat", 0))
			var protected_general = generals_data.get(protected_seat, {})
			var protected_name := str(protected_general.get("name", "người chơi bị thương")) if protected_general is Dictionary else "người chơi bị thương"
			is_waiting_nghia_tu = true
			_prompt_oai_nhuoc(state.get("activeCard", {}), server_waiting_timer)
			is_waiting_nghia_tu = true
			dodge_title_lbl.text = "🛡️ NGHĨA TỬ"
			dodge_desc_lbl.text = "Chọn 1 lá để chịu thay 1 sát thương cho %s; hoặc từ chối." % protected_name
			dodge_pass_btn.text = "TỪ CHỐI"
			turn_indicator.text = "🛡️ NGHĨA TỬ: CHỊU THAY CHO %s? (%ds)" % [protected_name.to_upper(), server_waiting_timer]
			_update_oai_nhuoc_selection()

	elif server_phase in ["AWAIT_UAT_KHI", "AWAIT_UAT_KHI_TARGET"]:
		card_play_btn.visible = false
		is_player_turn = false
		if server_waiting_seat == my_seat:
			if not uat_khi_pending:
				_begin_uat_khi_prompt()
			uat_khi_pending = true
			end_turn_btn.visible = true
			end_turn_btn.text = "BỎ QUA"
			end_turn_btn.disabled = uat_khi_submission_pending
			turn_indicator.text = "💢 UẤT KHÍ: CHỌN MỤC TIÊU (%ds)" % server_waiting_timer
			card_play_btn.visible = true
			card_play_btn.disabled = uat_khi_submission_pending or uat_khi_target_seat <= 0
			card_play_btn.text = "💢 CHỌN MỤC TIÊU UẤT KHÍ" if uat_khi_target_seat <= 0 else "💢 CHO %s HỒI 1 MÁU & RÚT 2 LÁ" % generals_data[uat_khi_target_seat]["name"].to_upper()
			desc_text.text = "💢 [UẤT KHÍ] Chọn người còn sống (tối đa 2 người) để hồi 1 máu và rút 2 lá."
		else:
			end_turn_btn.visible = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat) if wait_gen is Dictionary else "Ghế %d" % server_waiting_seat
			turn_indicator.text = "💢 ĐANG CHỜ %s DÙNG UẤT KHÍ (%ds)..." % [wait_name.to_upper(), server_waiting_timer]
			desc_text.text = "💢 %s đang chọn mục tiêu [UẤT KHÍ]." % wait_name

	elif server_phase == "AWAIT_KHOI_BINH":
		is_player_turn = false
		if server_waiting_seat == my_seat:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			card_play_btn.text = "⚔️ PHÁT ĐỘNG KHỞI BINH"
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "TỪ CHỐI"
			turn_indicator.text = "⚔️ KHỞI BINH: QUYẾT ĐỊNH (%ds)" % server_waiting_timer
			desc_text.text = "⚔️ Bạn có thể cho mình và người dùng Trảm mỗi người rút 1 lá."
		else:
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_HUYNH_TRUONG":
		if server_waiting_seat == my_seat:
			huynh_truong_pending = true
			is_player_turn = true
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "TỪ CHỐI"
			turn_indicator.text = "🤝 HUYNH TRƯỞNG: CHỌN TƯỚNG VÀ BÀI (%ds)" % server_waiting_timer
			desc_text.text = "🤝 Đưa 1 lá trên tay cho người khác, rồi rút 1 lá; hoặc từ chối."
			_update_action_btn()
		else:
			huynh_truong_pending = false
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_NGHICH_Y":
		is_player_turn = false
		if server_waiting_seat == my_seat:
			if previous_server_phase != server_phase:
				is_targeting_nghich_y = true
				selected_nghich_y_card_id = ""
				selected_target_seat = -1
				if selected_card_ui and is_instance_valid(selected_card_ui):
					selected_card_ui.set_selected(false)
				selected_card_ui = null
			card_play_btn.visible = is_targeting_nghich_y
			end_turn_btn.visible = is_targeting_nghich_y
			end_turn_btn.text = "BỎ QUA"
			turn_indicator.text = "🌀 NGHỊCH Ý: CHỌN BÀI VÀ MỤC TIÊU (%ds)" % server_waiting_timer
			desc_text.text = "Chọn 1 lá bỏ và 1 người khác trong tầm đánh để chuyển Trảm."
			_update_action_btn()
		else:
			is_targeting_nghich_y = false
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_DAN_CAU":
		is_player_turn = false
		if server_waiting_seat == my_seat and not is_waiting_dodge and not reaction_submission_pending:
			_prompt_reaction_modal("🌉 DẪN CẦU", "Đánh 1 lá Trảm vào mục tiêu chỉ định, hoặc để Kiều Công Tiễn chọn cướp 2 lá trong vùng chơi.", "Trảm", "🗡️ BỊ CƯỚP 2 LÁ", "⚔️ CHỌN TRẢM", server_waiting_timer, false, true, false, false)
		else:
			card_play_btn.visible = false
			end_turn_btn.visible = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat) if wait_gen is Dictionary else "Ghế %d" % server_waiting_seat
			turn_indicator.text = "🌉 ĐANG CHỜ %s PHẢN ỨNG DẪN CẦU (%ds)..." % [wait_name.to_upper(), server_waiting_timer]
			desc_text.text = "🌉 %s đang chọn Trảm mục tiêu chỉ định hoặc chấp nhận để Kiều Công Tiễn cướp 2 lá..." % wait_name

	elif server_phase == "AWAIT_OAI_NHUOC":
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		if server_waiting_seat == my_seat and not is_waiting_dodge:
			_prompt_oai_nhuoc(state.get("activeCard", {}), server_waiting_timer)
			turn_indicator.text = "🐘 OAI NHƯỢC: BỎ 1 LÁ + ĐỠ HOẶC CHỊU ĐÒN (%ds)" % server_waiting_timer
		elif server_waiting_seat != my_seat:
			turn_indicator.text = "🐘 ĐANG CHỜ MỤC TIÊU CHỌN OAI NHƯỢC (%ds)..." % server_waiting_timer

	elif server_phase in ["AWAIT_AN_DAN", "AWAIT_AN_DAN_DUEL", "AWAIT_DA_TRACH_DISCARD", "AWAIT_HOA_DAN", "AWAIT_DUNG_NUOC", "AWAIT_HAN_LAM", "AWAIT_VAN_SACH", "AWAIT_TRUNG_KIEN", "AWAIT_TRU_QUAN", "AWAIT_COT_KINH_TARGET", "AWAIT_TRUNG_TIET", "AWAIT_CAN_VE"]:
		is_player_turn = false
		if server_waiting_seat == my_seat:
			card_play_btn.visible = true
			card_play_btn.disabled = false
			end_turn_btn.visible = true
			end_turn_btn.disabled = false
			end_turn_btn.text = "TỪ CHỐI"
			if server_phase == "AWAIT_DA_TRACH_DISCARD":
				card_play_btn.text = "🌙 BỎ 1 LÁ"
				end_turn_btn.text = "BỎ QUA"
				turn_indicator.text = "🌙 DẠ TRẠCH: BỎ THÊM 1 LÁ? (%ds)" % server_waiting_timer
				desc_text.text = "Bạn có muốn bỏ 1 lá bài không?"
				_update_action_btn()
			elif server_phase == "AWAIT_AN_DAN_DUEL":
				card_play_btn.text = "🏘️ CHỌN MỤC TIÊU HUYẾT CHIẾN"
				turn_indicator.text = "🏘️ AN DÂN: CHỌN MỤC TIÊU HUYẾT CHIẾN (%ds)" % server_waiting_timer
				desc_text.text = "Sau khi di chuyển Cẩm Nang Trì Hoãn, chọn 1 mục tiêu để xem như sử dụng Huyết Chiến."
			elif server_phase == "AWAIT_AN_DAN":
				card_play_btn.text = "🏘️ PHÁT ĐỘNG AN DÂN"
				turn_indicator.text = "🏘️ AN DÂN: QUYẾT ĐỊNH (%ds)" % server_waiting_timer
				desc_text.text = "Bỏ qua rút bài để chuyển 1 Cẩm Nang Trì Hoãn đang đặt lên một người sang người khác."
			elif server_phase == "AWAIT_HOA_DAN":
				card_play_btn.text = "🌾 PHÁT ĐỘNG HÓA DÂN"
				turn_indicator.text = "🌾 HÓA DÂN: QUYẾT ĐỊNH (%ds)" % server_waiting_timer
				desc_text.text = "Bỏ 1 Trang bị bất kỳ để hồi 1 Máu."
			elif server_phase == "AWAIT_DUNG_NUOC":
				card_play_btn.text = "🏯 PHÁT ĐỘNG DỰNG NƯỚC"
				turn_indicator.text = "🏯 DỰNG NƯỚC: QUYẾT ĐỊNH (%ds)" % server_waiting_timer
				desc_text.text = "Bỏ qua rút 2 lá để hồi 1 Máu và lấy ngẫu nhiên 1 lá bài Đỏ từ xấp bỏ nếu có."
			elif server_phase == "AWAIT_HAN_LAM":
				var han_card = _get_han_lam_revealed_card(state, current_delta)
				var han_name = str(han_card.get("name", "lá trên cùng")) if han_card is Dictionary else "lá trên cùng"
				card_play_btn.text = "📖 ĐỂ TRÊN CÙNG [%s]" % han_name.to_upper()
				end_turn_btn.text = "ĐẶT XUỐNG ĐÁY"
				turn_indicator.text = "📖 HÁN LÂM: ĐỂ TRÊN CÙNG HAY XUỐNG ĐÁY? (%ds)" % server_waiting_timer
				desc_text.text = "Lá trên cùng là [%s]. Chọn để trên cùng hoặc xuống đáy, sau đó rút 1 lá." % han_name
			elif server_phase == "AWAIT_VAN_SACH":
				card_play_btn.text = "📚 BỎ LÁ ĐỂ RÚT 1 LÁ"
				end_turn_btn.text = "BỎ QUA"
				turn_indicator.text = "📚 VĂN SÁCH: BỎ 1 LÁ ĐỂ RÚT 1 LÁ? (%ds)" % server_waiting_timer
				desc_text.text = "Sau khi dùng Cẩm Nang thứ hai trong lượt, chọn 1 lá trên tay để bỏ và rút 1 lá, hoặc bỏ qua."
			elif server_phase == "AWAIT_TRU_QUAN":
				card_play_btn.text = "👑 GIẢM 1 MÁU RÚT 2 LÁ"
				turn_indicator.text = "👑 TRỮ QUÂN: RÚT THÊM 2 LÁ? (%ds)" % server_waiting_timer
				desc_text.text = "Tự giảm 1 Máu để được rút thêm 2 lá bài ở đầu giai đoạn rút bài."
			elif server_phase == "AWAIT_COT_KINH_TARGET":
				card_play_btn.text = "🏛️ CHỌN MỤC TIÊU BỎ BÀI"
				turn_indicator.text = "🏛️ CỘT KINH: CHỌN NGƯỜI CHƠI BỎ BÀI (%ds)" % server_waiting_timer
				desc_text.text = "Chọn 1 người chơi khác; người đó phải bỏ 1 lá bài trên tay."
			elif server_phase == "AWAIT_TRUNG_TIET":
				card_play_btn.text = "🛡️ MẤT 1 MÁU RÚT 3 LÁ"
				turn_indicator.text = "🛡️ TRUNG TIẾT: CỨU NẠN NHÂN (%ds)" % server_waiting_timer
				desc_text.text = "Tự mất 1 Máu để rút 3 lá (nếu nạn nhân sống sót, bạn rút thêm 1 lá)."
			elif server_phase == "AWAIT_CAN_VE":
				card_play_btn.text = "🛡️ ĐỠ TRẢM THAY ĐỒNG ĐỘI"
				turn_indicator.text = "🛡️ CẬN VỆ: CHUYỂN TRẢM SANG BẢN THÂN (%ds)" % server_waiting_timer
				desc_text.text = "Thay đổi mục tiêu bị Trảm của người trong Tầm 1 thành bản thân."
			else:
				card_play_btn.text = "🛡️ PHÁT ĐỘNG TRUNG KIÊN"
				turn_indicator.text = "🛡️ TRUNG KIÊN: CỨU NGƯỜI SẮP TỬ TRẬN (%ds)" % server_waiting_timer
				desc_text.text = "Tự giảm 1 Máu để giúp người sắp tử trận hồi đến 1 Máu."
		else:
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_AN_TICH":
		is_player_turn = false
		if server_waiting_seat == my_seat and not is_waiting_dodge:
			_prompt_reaction_modal("🌫️ ẨN TÍCH", "Chọn 1 lá trên tay để đặt úp làm Đỡ, hoặc bỏ qua.", "Bài", "BỎ QUA", "🌫️ ĐẶT ẨN", server_waiting_timer, false, true, false, false)
			custom_reaction_callback = func(accepted: bool, card_info: Dictionary):
				NetworkClient.send_respond_action(accepted, str(card_info.get("id", "")))
		else:
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_THU_MUC":
		is_player_turn = false
		if server_waiting_seat == my_seat and not is_waiting_dodge:
			_prompt_reaction_modal("🛡️ THỦ MỤC", "Bỏ 1 lá bài Đỏ hoặc bài Trắng để giảm 1 sát thương Trảm, hoặc bỏ qua.", "Bỏ bài Đỏ/Trắng", "BỎ QUA", "🛡️ BỎ LÁ ĐỎ/TRẮNG", server_waiting_timer, false, true, false, false)
			custom_reaction_callback = func(accepted: bool, card_info: Dictionary):
				NetworkClient.send_respond_action(accepted, str(card_info.get("id", "")))
		elif server_waiting_seat != my_seat:
			card_play_btn.visible = false
			end_turn_btn.visible = false

	elif server_phase == "AWAIT_JUDGEMENT":
		current_waiting_seat = 0
		current_waiting_timer = float(server_waiting_timer if server_waiting_timer > 0 else 3)
		card_play_btn.visible = false
		end_turn_btn.visible = false
		is_player_turn = false
		turn_indicator.text = "📜 ĐANG PHÁN XÉT: %s..." % turn_gen_name.to_upper()
		desc_text.text = "📜 Đang lật bài phán xét cẩm nang trì hoãn cho %s..." % turn_gen_name
		if generals_data.has(server_turn_seat) and generals_data[server_turn_seat].has("avatar_node") and is_instance_valid(generals_data[server_turn_seat]["avatar_node"]):
			generals_data[server_turn_seat]["avatar_node"].update_turn_timer(int(current_waiting_timer))

	elif server_phase == "AWAIT_BORROW_SWORD":
		card_play_btn.visible = false
		if server_waiting_seat == my_seat:
			var active_c = state.get("activeCard", {})
			if not (active_c is Dictionary):
				active_c = {}
			var forced_target_seat = int(active_c.get("forcedTargetSeat", 0))
			var forced_target = generals_data.get(forced_target_seat, {})
			var target_name = forced_target.get("name", "Ghế %d" % forced_target_seat) if forced_target is Dictionary else "Ghế %d" % forced_target_seat
			if not is_waiting_dodge and not reaction_submission_pending:
				var borrower_seat = int(active_c.get("casterSeat", 0))
				var borrower = generals_data.get(borrower_seat, {})
				var borrower_name = borrower.get("name", "Ghế %d" % borrower_seat) if borrower is Dictionary else "Ghế %d" % borrower_seat
				_prompt_reaction_modal(
					"🗡️ MƯỢN GƯƠM DIỆT ĐỊCH",
					"[Mượn Gươm Diệt Địch] của %s đang ép bạn đánh [Trảm] lên %s.\nBạn phải ra Trảm lên %s hoặc cho %s vũ khí." % [borrower_name, target_name, target_name, borrower_name],
					"Trảm",
					"🎁 CHO VŨ KHÍ",
					"⚔️ ĐÁNH [TRẢM]",
					server_waiting_timer,
					false,
					false,
					false
				)
			dodge_time_left = float(server_waiting_timer)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "🗡️ BẠN PHẢI ĐÁNH %s HOẶC CHO VŨ KHÍ (%ds)!" % [target_name.to_upper(), server_waiting_timer]
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat) if wait_gen is Dictionary else "Ghế %d" % server_waiting_seat
			turn_indicator.text = "🗡️ ĐANG CHỜ %s QUYẾT ĐỊNH MƯỢN GƯƠM (%ds)..." % [wait_name, server_waiting_timer]
			desc_text.text = "🗡️ %s phải đánh Trảm hoặc cho vũ khí." % wait_name

	elif server_phase == "AWAIT_SLASH_DEFENSE":
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.visible = false
		if not (server_waiting_seat == my_seat and is_waiting_dodge):
			_clear_normal_hand_selection()
		if server_waiting_seat == my_seat:
			if not is_waiting_dodge and not reaction_submission_pending:
				var active_c = state.get("activeCard", {})
				if not (active_c is Dictionary):
					active_c = {}
				var atk_s = int(active_c.get("casterSeat", 0))
				var dmg = _get_effect_damage(active_c)
				var elem = str(active_c.get("damageElement", active_c.get("element", "NORMAL")))
				var slash_suit = str(active_c.get("suit", ""))
				if generals_data.has(atk_s):
					generals_data[atk_s]["last_slash_suit"] = slash_suit
				_prompt_dodge_reaction(atk_s, dmg, elem, slash_suit)
			dodge_time_left = float(server_waiting_timer)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			if not (wait_gen is Dictionary):
				wait_gen = {}
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)
			turn_indicator.text = "🛡️ ĐANG CHỜ %s ĐỠ ĐÒN (%ds)..." % [wait_name, server_waiting_timer]
			desc_text.text = "🛡️ Đang chờ %s phản hồi đòn Trảm..." % wait_name

	elif server_phase == "AWAIT_AOE":
		var active_c = state.get("activeCard", {})
		if not (active_c is Dictionary):
			active_c = {}
		var aoe_name = str(active_c.get("cardName", active_c.get("name", "Cẩm Nang Diện Rộng")))
		var req_name = str(active_c.get("reqName", "Trảm"))
		var req_type = str(active_c.get("reqType", "SLASH"))
		var atk_s = int(active_c.get("casterSeat", 0))
		var atk_gen = generals_data.get(atk_s, {})
		if not (atk_gen is Dictionary):
			atk_gen = {}
		var atk_name = atk_gen.get("name", "Ghế %d" % atk_s)
		var wait_gen = generals_data.get(server_waiting_seat, {})
		if not (wait_gen is Dictionary):
			wait_gen = {}
		var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)
		if server_waiting_seat == my_seat:
			if not is_waiting_dodge:
				dodge_attacker_seat = atk_s
				var is_giac_toi = "Giặc Tới" in aoe_name or "Bãi Cọc" in aoe_name
				is_giac_toi_reaction = is_giac_toi
				var prompt_title = "🪵 TRẢM GIẶC TỚI" if is_giac_toi else "🏹 NÉ MƯA TÊN LIÊN CHÂU"
				var prompt_desc = "⚠️ [%s] của %s đang tác động lên bạn!\nHãy chạm chọn 1 lá [Trảm] trên tay để Trảm Giặc hoặc bấm [CHỊU ĐÒN]:" % [aoe_name, atk_name] if is_giac_toi else "⚠️ [%s] của %s đang tác động lên bạn!\nHãy chạm chọn 1 lá [%s] trên tay để hóa giải hoặc bấm [CHỊU ĐÒN]:" % [aoe_name, atk_name, req_name]
				var pass_txt = _format_damage_pass_text(_get_effect_damage(active_c))
				var confirm_txt = "⚔️ DÙNG [TRẢM] TRẢM GIẶC" if is_giac_toi else "🛡️ ĐÁNH [%s] ĐỂ NÉ" % req_name.to_upper()
				_prompt_reaction_modal(prompt_title, prompt_desc, req_name, pass_txt, confirm_txt, server_waiting_timer, (req_type == "DODGE"), true, true, false)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "⚠️ BẠN ĐANG BỊ TẤN CÔNG BỞI [%s] (%ds)!" % [aoe_name.to_upper(), server_waiting_timer]
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			turn_indicator.text = "🏹 [%s]: ĐANG CHỜ %s RA [%s] (%ds)..." % [aoe_name.to_upper(), wait_name, req_name.to_upper(), server_waiting_timer]
			desc_text.text = "🏹 %s đang đợi %s ra lá [%s] để né..." % [aoe_name, wait_name, req_name]

	elif server_phase == "AWAIT_DUEL":
		var active_c = state.get("activeCard", {})
		if not (active_c is Dictionary):
			active_c = {}
		var atk_s = int(active_c.get("casterSeat", 0))
		var atk_gen = generals_data.get(atk_s, {})
		if not (atk_gen is Dictionary):
			atk_gen = {}
		var atk_name = atk_gen.get("name", "Ghế %d" % atk_s)
		var wait_gen = generals_data.get(server_waiting_seat, {})
		if not (wait_gen is Dictionary):
			wait_gen = {}
		var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)
		var required_slashes = max(1, int(active_c.get("duelRequiredSlashes", 1)))
		var used_slashes = max(0, int(active_c.get("duelSlashesUsed", 0)))
		var remaining_slashes = max(1, required_slashes - used_slashes)
		var phuc_ho_note := "Cần dùng hai lá Trảm mỗi lượt Huyết Chiến do kỹ năng Phục Hổ của Phùng Hưng." if required_slashes > 1 else ""
		var phuc_ho_active := false
		for duel_seat in [int(active_c.get("casterSeat", 0)), int(active_c.get("targetSeat", 0))]:
			if duel_seat > 0 and generals_data.has(duel_seat) and _hero_has_skill(generals_data[duel_seat], "phuc_ho"):
				phuc_ho_active = true
				break

		if server_waiting_seat == my_seat:
			if not is_waiting_dodge:
				dodge_attacker_seat = atk_s
				var prompt_title = "⚔️ HUYẾT CHIẾN ĐỐI KHÁNG"
				var prompt_desc = "⚠️ [Huyết Chiến] của %s đang đối kháng với bạn.\nHãy chạm chọn 1 lá Trảm để đáp trả hoặc bấm [NHẬN THUA]." % atk_name
				if not phuc_ho_note.is_empty():
					prompt_desc += "\n🐯 " + phuc_ho_note
				var pass_txt = _format_damage_pass_text(_get_effect_damage(active_c), "NHẬN THUA")
				var confirm_txt = "⚔️ ĐÁP TRẢ [TRẢM]"
				_prompt_reaction_modal(prompt_title, prompt_desc, "Trảm", pass_txt, confirm_txt, server_waiting_timer, false, true, true, false)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "⚔️ ĐẾN LƯỢT BẠN ĐÁNH TRẢM TRONG HUYẾT CHIẾN (%ds)!" % server_waiting_timer
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			var slash_label = "%d lá Trảm" % remaining_slashes if remaining_slashes > 1 else "1 lá Trảm"
			turn_indicator.text = "⚔️ HUYẾT CHIẾN: ĐANG CHỜ %s ĐÁNH %s (%ds)..." % [wait_name, slash_label, server_waiting_timer]
			desc_text.text = "⚔️ Đang chờ %s đáp trả %s trong Huyết Chiến..." % [wait_name, slash_label]
			if not phuc_ho_note.is_empty():
				desc_text.text += "\n🐯 " + phuc_ho_note

	elif server_phase == "AWAIT_NULLIFY":
		var chain = state.get("nullifyChain", {})
		if not (chain is Dictionary):
			chain = {}
		var root_c = chain.get("rootCard", {})
		if not (root_c is Dictionary):
			root_c = {}
		var root_name = root_c.get("name", "Mưu kế")
		var is_canceled = bool(chain.get("isCanceled", false))
		var root_caster_seat = int(chain.get("casterSeat", 0))
		var root_target_seat = int(chain.get("targetSeat", 0))
		var root_caster_name = generals_data[root_caster_seat].get("name", "Ghế %d" % root_caster_seat) if generals_data.has(root_caster_seat) else "Người dùng mưu kế"
		var root_target_name = generals_data[root_target_seat].get("name", "Ghế %d" % root_target_seat) if generals_data.has(root_target_seat) else "toàn bàn"
		var wait_gen = generals_data.get(server_waiting_seat, {})
		if not (wait_gen is Dictionary):
			wait_gen = {}
		var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)

		if server_waiting_seat == my_seat:
			if not is_waiting_dodge:
				dodge_attacker_seat = 0
				var prompt_title = "📜 DIỆU KẾ PHÁ MƯU"
				var action_intent = "phá bỏ hiệu ứng" if not is_canceled else "khôi phục hiệu lực"
				var prompt_desc = "[%s] của %s đang tác động lên %s.\nHãy chạm chọn [Diệu Kế Phá Mưu] để %s [%s] lên %s, hoặc bấm [BỎ QUA]:" % [root_name, root_caster_name, root_target_name, action_intent, root_name, root_target_name]
				var pass_txt = "BỎ QUA"
				var confirm_txt = "📜 DÙNG DIỆU KẾ"
				_prompt_reaction_modal(prompt_title, prompt_desc, "Diệu Kế", pass_txt, confirm_txt, server_waiting_timer, false, true, false, false)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "📜 BẠN CÓ MUỐN DÙNG DIỆU KẾ PHÁ MƯU KHÔNG (%ds)?" % server_waiting_timer
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			turn_indicator.text = "📜 ĐANG CÓ NGƯỜI SUY NGHĨ DÙNG DIỆU KẾ PHÁ MƯU (%ds)..." % server_waiting_timer
			desc_text.text = "📜 Đang chờ một người chơi phản hồi Diệu Kế Phá Mưu..."

	elif server_phase in ["AWAIT_HICH_CASTER_DISCARD", "AWAIT_HICH_TARGET_DISCARD"]:
		var active_hich = state.get("activeCard", {})
		if not (active_hich is Dictionary):
			active_hich = {}
		var hich_caster_seat = int(active_hich.get("casterSeat", 0))
		var hich_target_seat = int(active_hich.get("targetSeat", 0))
		var hich_caster = generals_data.get(hich_caster_seat, {})
		var hich_caster_name = hich_caster.get("name", "người phát Hịch") if hich_caster is Dictionary else "người phát Hịch"
		var hich_target = generals_data.get(hich_target_seat, {})
		var hich_target_name = hich_target.get("name", "mục tiêu") if hich_target is Dictionary else "mục tiêu"
		if server_waiting_seat == my_seat:
			if not is_waiting_dodge and not reaction_submission_pending:
				dodge_attacker_seat = hich_caster_seat
				_prompt_reaction_modal(
					"📣 HỊCH TƯỚNG SĨ",
					"[Hịch Tướng Sĩ] của %s đang tác động lên %s.\nChạm chọn 1 lá trên tay để bỏ và nhận Sục Sôi (1 vòng: Trảm không giới hạn, Tầm đánh +1), hoặc bấm [BỎ QUA]." % [hich_caster_name, hich_target_name],
					"Bỏ bài",
					"BỎ QUA",
					"📣 BỎ 1 LÁ NHẬN SỤC SÔI",
					server_waiting_timer,
					false,
					true,
					false,
					false
				)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "📣 BỎ 1 LÁ NHẬN SỤC SÔI (+1 TẦM, TRẢM VÔ HẠN) (%ds)!" % server_waiting_timer
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat) if wait_gen is Dictionary else "Ghế %d" % server_waiting_seat
			turn_indicator.text = "📣 ĐANG CHỜ %s PHẢN HỒI HỊCH TƯỚNG SĨ (%ds)..." % [wait_name, server_waiting_timer]

	elif server_phase == "AWAIT_TARGET_CARD":
		var sel = state.get("targetCardSelection", {})
		if not (sel is Dictionary):
			sel = {}
		var is_steal = (sel.get("operation", "") == "STEAL")
		var tgt_s = int(sel.get("targetSeat", 0))
		var wait_gen = generals_data.get(server_waiting_seat, {})
		if not (wait_gen is Dictionary):
			wait_gen = {}
		var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)

		if server_waiting_seat == my_seat:
			if not card_pick_modal.visible:
				_show_card_pick_modal(is_steal, tgt_s, sel)
			turn_indicator.text = "🗡️ BẠN ĐANG CHỌN BÀI MỤC TIÊU (%ds)!" % server_waiting_timer
		else:
			if card_pick_modal.visible:
				card_pick_modal.visible = false
			turn_indicator.text = "🗡️ %s ĐANG CHỌN BÀI MỤC TIÊU (%ds)..." % [wait_name, server_waiting_timer]
			desc_text.text = "🗡️ Đang chờ %s chọn lá bài để cướp hoặc phá..." % wait_name

	elif server_phase == "AWAIT_DOAN_DAO_CHOICE":
		if server_waiting_seat == my_seat and not dodge_modal.visible:
			var doan_card = state.get("activeCard", {})
			if not (doan_card is Dictionary):
				doan_card = {}
			var doan_attacker_seat = int(doan_card.get("casterSeat", 0))
			var doan_target_seat = int(doan_card.get("targetSeat", 0))
			var doan_attacker_name = generals_data[doan_attacker_seat].get("name", "Người dùng Trảm") if generals_data.has(doan_attacker_seat) else "Người dùng Trảm"
			var doan_target_name = generals_data[doan_target_seat].get("name", "mục tiêu") if generals_data.has(doan_target_seat) else "mục tiêu"
			_prompt_reaction_modal(
				"🗡️ ĐOẢN ĐAO LAM SƠN",
				"[Trảm] của %s đã trúng %s.\nChọn hủy 2 lá trên tay/trang bị của %s, hoặc gây sát thương như bình thường." % [doan_attacker_name, doan_target_name, doan_target_name],
				"NONE",
				"💥 GÂY SÁT THƯƠNG",
				"🗡️ HỦY 2 LÁ CỦA MỤC TIÊU"
			)
			custom_reaction_callback = func(use_dao: bool, _card_info: Dictionary):
				if NetworkClient and NetworkClient.is_connected_to_server:
					NetworkClient.send_respond_action(use_dao, "")
			turn_indicator.text = "🗡️ CHỌN HIỆU ỨNG ĐOẢN ĐAO (%ds)!" % server_waiting_timer
		else:
			turn_indicator.text = "🗡️ ĐANG CHỜ NGƯỜI ĐÁNH CHỌN HIỆU ỨNG ĐOẢN ĐAO (%ds)..." % server_waiting_timer

	elif server_phase == "AWAIT_HARVEST":
		var wait_gen = generals_data.get(server_waiting_seat, {})
		if not (wait_gen is Dictionary):
			wait_gen = {}
		var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)

		var pool = state.get("harvestDisplayPool", state.get("harvestPool", []))
		if not (pool is Array):
			pool = []
		var picked_ids_raw = state.get("harvestPickedCardIds", [])
		var picked_ids: Array[String] = []
		if picked_ids_raw is Array:
			for picked_id in picked_ids_raw:
				picked_ids.append(str(picked_id))
		var pool_signature = ""
		var pool_ids: Array = []
		for pool_card in pool:
			if pool_card is Dictionary:
				pool_ids.append(str(pool_card.get("id", "")))
		pool_signature = "%s|%s|%d" % [",".join(pool_ids), ",".join(picked_ids), server_waiting_seat]
		var harvest_visible = is_instance_valid(harvest_modal) and harvest_modal.visible
		var can_choose_harvest = server_waiting_seat == my_seat and not harvest_choice_sent
		if not pool.is_empty() and (not harvest_visible or harvest_modal_signature != pool_signature):
			_show_harvest_modal(pool, false, picked_ids, can_choose_harvest, server_waiting_seat)
		if harvest_status_lbl:
			harvest_status_lbl.text = "Đến lượt bạn chọn 1 lá." if can_choose_harvest else "%s đang chọn bài. Các lá đã lấy được làm tối." % wait_name
		if harvest_timer_lbl:
			harvest_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer

		if server_waiting_seat == my_seat:
			turn_indicator.text = "🌾 BẠN ĐANG CHỌN 1 LÁ TỪ KHO CỨU TẾ (%ds)!" % server_waiting_timer
		else:
			turn_indicator.text = "🌾 KHO CỨU TẾ: ĐANG CHỜ NGƯỜI CHƠI KHÁC CHỌN BÀI (%ds)..." % server_waiting_timer
			desc_text.text = "🌾 Đang chờ người chơi đang được hỏi chọn 1 lá từ Kho Cứu Tế..."

	elif server_phase == "AWAIT_THUY_TRIEU_RUT_GIVE":
		var tide_selection = state.get("thuyTrieuRutSelection", {})
		if not (tide_selection is Dictionary):
			tide_selection = {}
		var giver_seat = int(tide_selection.get("giverSeat", tide_selection.get("richerSeat", 0)))
		var receiver_seat = int(tide_selection.get("receiverSeat", tide_selection.get("poorerSeat", 0)))
		var active_tide = state.get("activeCard", {})
		if not (active_tide is Dictionary):
			active_tide = {}
		if giver_seat <= 0:
			giver_seat = int(active_tide.get("giverSeat", active_tide.get("richerSeat", server_waiting_seat)))
		if receiver_seat <= 0:
			receiver_seat = int(active_tide.get("receiverSeat", active_tide.get("poorerSeat", 0)))
		var giver_gen = generals_data.get(giver_seat, {})
		var receiver_gen = generals_data.get(receiver_seat, {})
		var giver_name = giver_gen.get("name", "Ghế %d" % giver_seat) if giver_gen is Dictionary else "Ghế %d" % giver_seat
		var receiver_name = receiver_gen.get("name", "Ghế %d" % receiver_seat) if receiver_gen is Dictionary else "Ghế %d" % receiver_seat
		if server_waiting_seat == my_seat:
			if not is_waiting_thuy_trieu_rut_give and not thuy_trieu_rut_give_sent:
				_prompt_thuy_trieu_rut_give(giver_seat, receiver_seat, server_waiting_timer)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "🌊 BẠN PHẢI ĐƯA 1 LÁ CHO %s (%ds)!" % [receiver_name.to_upper(), server_waiting_timer]
		else:
			if is_waiting_thuy_trieu_rut_give:
				_close_thuy_trieu_rut_give_prompt()
			turn_indicator.text = "🌊 THỦY TRIỀU RÚT: ĐANG CHỜ %s ĐƯA 1 LÁ (%ds)..." % [giver_name, server_waiting_timer]
			desc_text.text = "🌊 %s phải đưa 1 lá cho %s. Nếu lá đưa không phải Bài Cơ Bản, người ít bài hơn sau chuyển chịu 1 sát thương Thủy." % [giver_name, receiver_name]

	elif server_phase == "AWAIT_DRUM_CHOICE":
		var drum_sel = state.get("drumSelection", {})
		if not (drum_sel is Dictionary):
			drum_sel = {}
		var owner_s = int(drum_sel.get("ownerSeat", 0))
		var target_s = int(drum_sel.get("targetSeat", server_waiting_seat))
		var owner_name = generals_data[owner_s].get("name", "Ghế %d" % owner_s) if generals_data.has(owner_s) else "Người dùng Trống Đồng"
		var target_name = generals_data[target_s].get("name", "Ghế %d" % target_s) if generals_data.has(target_s) else "Ghế %d" % target_s

		if server_waiting_seat == my_seat:
			if not is_waiting_dodge:
				dodge_attacker_seat = owner_s
				_prompt_reaction_modal(
					"🥁 ĐIỂM TRỐNG - TRỐNG ĐỒNG",
				"🥁 [Điểm Trống] của %s đang tác động lên %s.\nBạn phải chọn: chạm 1 lá bài trên tay để BỎ hoặc LỘ BÀI cho %s xem." % [owner_name, target_name, owner_name],
					"Bài",
					"👁️ LỘ BÀI TRÊN TAY",
					"🗑️ BỎ",
					server_waiting_timer,
					false,
					true,
					false,
					false
				)
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "🥁 ĐIỂM TRỐNG: BẠN PHẢI BỎ 1 LÁ HOẶC LỘ BÀI (%ds)!" % server_waiting_timer
		else:
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			turn_indicator.text = "🥁 ĐIỂM TRỐNG: ĐANG CHỜ %s CHỌN (%ds)..." % [target_name, server_waiting_timer]
			desc_text.text = "🥁 %s đang chọn: bỏ 1 lá bài hoặc lộ toàn bộ bài trên tay cho %s xem..." % [target_name, owner_name]

	elif server_phase == "AWAIT_SONG_CUNG_FOLLOW_UP":
		card_play_btn.visible = false
		var active_c = state.get("activeCard", {})
		if not (active_c is Dictionary):
			active_c = {}
		var target_s = int(active_c.get("targetSeat", 0))
		var tgt_gen = generals_data.get(target_s, {})
		var tgt_name = tgt_gen.get("name", "Ghế %d" % target_s) if tgt_gen is Dictionary else "Ghế %d" % target_s

		if server_waiting_seat == my_seat:
			if not is_waiting_song_cung:
				_prompt_song_cung_modal(target_s, server_waiting_timer, int(active_c.get("damage", 1)), str(active_c.get("element", "NORMAL")))
			if dodge_timer_lbl:
				dodge_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
			turn_indicator.text = "🏹 BẠN CÓ MUỐN KÍCH HOẠT SONG CUNG ÉP %s CHỊU ĐÒN (%ds)?" % [tgt_name.to_upper(), server_waiting_timer]
		else:
			if is_waiting_song_cung:
				_close_song_cung_modal()
			if is_waiting_dodge:
				dodge_modal.visible = false
				is_waiting_dodge = false
			var wait_gen = generals_data.get(server_waiting_seat, {})
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat) if wait_gen is Dictionary else "Ghế %d" % server_waiting_seat
			turn_indicator.text = "🏹 SONG CUNG: ĐANG CHỜ %s QUYẾT ĐỊNH (%ds)..." % [wait_name, server_waiting_timer]
			desc_text.text = "🏹 %s đang chọn bỏ 2 lá trên tay hoặc đang mang để ép %s chịu sát thương..." % [wait_name, tgt_name]

	elif server_phase == "AWAIT_NEAR_DEATH":
		var victim_seat = int(state.get("nearDeathVictimSeat", 0))
		for s in generals_data.keys():
			var g_node = generals_data[s].get("avatar_node")
			if is_instance_valid(g_node):
				g_node.set_near_death(s == victim_seat)

		if server_waiting_seat == my_seat:
			if not is_waiting_rescue:
				_prompt_rescue_reaction(victim_seat)
			if rescue_timer_lbl:
				rescue_timer_lbl.text = "⏳ Còn lại: %ds" % server_waiting_timer
		else:
			if is_waiting_rescue:
				_close_rescue_modal()
			var wait_gen = generals_data.get(server_waiting_seat, {})
			if not (wait_gen is Dictionary):
				wait_gen = {}
			var wait_name = wait_gen.get("name", "Ghế %d" % server_waiting_seat)
			var victim_gen = generals_data.get(victim_seat, {})
			var victim_name = victim_gen.get("name", "Ghế %d" % victim_seat) if victim_gen is Dictionary else "Ghế %d" % victim_seat
			turn_indicator.text = "💮 ĐANG CHỜ %s SUY NGHĨ CÓ CỨU %s HAY KHÔNG (%ds)..." % [wait_name.to_upper(), victim_name.to_upper(), server_waiting_timer]
			desc_text.text = "💮 Đang chờ %s suy nghĩ có cứu %s hay không. Cần 1 Bánh Chưng; người cận tử có thể tự dùng 1 Hủ Rượu." % [wait_name, victim_name]

	elif server_phase == "DISCARD":
		if is_waiting_dodge:
			dodge_modal.visible = false
			is_waiting_dodge = false
		if is_waiting_rescue:
			rescue_modal.visible = false
			is_waiting_rescue = false

		if server_turn_seat == my_seat:
			is_player_turn = true
			var excess = max(0, generals_data[my_seat]["hand_count"] - _get_general_hand_limit(generals_data[my_seat]))
			if excess > 0 and (not is_discard_phase or cards_to_discard_count != excess or discard_submission_pending):
				_enter_discard_phase(excess)
			current_turn_timer = float(server_waiting_timer)
			turn_indicator.text = "🗑️ BẠN CẦN BỎ %d LÁ BÀI THỪA (%ds)!" % [cards_to_discard_count, server_waiting_timer]
			if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
				generals_data[my_seat]["avatar_node"].update_turn_timer(server_waiting_timer)
		else:
			is_player_turn = false
			is_discard_phase = false
			card_play_btn.visible = false
			turn_indicator.text = "🗑️ %s ĐANG BỎ BÀI THỪA (%ds)..." % [turn_gen_name, server_waiting_timer]
			desc_text.text = "🗑️ %s đang bỏ bớt bài thừa trên tay..." % turn_gen_name
			if generals_data.has(server_turn_seat) and generals_data[server_turn_seat].has("avatar_node") and is_instance_valid(generals_data[server_turn_seat]["avatar_node"]):
				generals_data[server_turn_seat]["avatar_node"].update_turn_timer(server_waiting_timer)

	# Hiển thị bài lộ từ Điểm Trống nếu mình là người xem
	if state.has("drumReveal") and state["drumReveal"] is Dictionary:
		var d_rev = state["drumReveal"]
		var v_seat = int(d_rev.get("viewerSeat", 0))
		var t_seat = int(d_rev.get("targetSeat", 0))
		var rev_cards = d_rev.get("cards", [])
		if v_seat == my_seat and rev_cards is Array and not rev_cards.is_empty() and not drum_reveal_dismissed:
			if not (drum_reveal_modal and is_instance_valid(drum_reveal_modal) and drum_reveal_modal.visible):
				_show_drum_reveal_modal(t_seat, rev_cards)
	else:
		if not (state.has("chinhThongReveal") and state["chinhThongReveal"] is Dictionary):
			drum_reveal_dismissed = false
	if state.has("chinhThongReveal") and state["chinhThongReveal"] is Dictionary:
		var ct_reveal = state["chinhThongReveal"]
		var ct_viewer = int(ct_reveal.get("viewerSeat", 0))
		var ct_target = int(ct_reveal.get("targetSeat", 0))
		var ct_cards = ct_reveal.get("cards", [])
		if ct_viewer == my_seat and ct_cards is Array and not drum_reveal_dismissed:
			if not (drum_reveal_modal and is_instance_valid(drum_reveal_modal) and drum_reveal_modal.visible):
				_show_drum_reveal_modal(ct_target, ct_cards, "📜 CHÍNH THỐNG")

	# 3. Kết thúc ván đấu
	if state.get("status") == "FINISHED" and not is_game_over:
		is_game_over = true
		_check_victory_condition()

func _get_rescue_requirement_text(victim_seat: int) -> String:
	var banh_count = 0
	var ruou_count = 0
	var victim_data = generals_data.get(victim_seat, {})
	var cards_needed = max(1, 1 - int(victim_data.get("hp", 0))) if victim_data is Dictionary else 1
	for card_node in hand_container.get_children():
		var info = _get_card_info_from_ui(card_node)
		var card_name = str(info.get("name", "")).to_lower()
		var card_sub_type = int(info.get("subType", -1))
		if card_sub_type == 4 or "bánh chưng" in card_name:
			banh_count += 1
		elif card_sub_type == 5 or "hủ rượu" in card_name:
			ruou_count += 1

	if victim_seat == my_seat:
		return "Cần %d lá để tự cứu: 🍲 Bánh Chưng hoặc 🍶 Hủ Rượu.\nBạn có: 🍲 Bánh Chưng x%d lá | 🍶 Hủ Rượu x%d lá." % [cards_needed, banh_count, ruou_count]
	return "Cần %d lá 🍲 Bánh Chưng để cứu người này.\nBạn có: 🍲 Bánh Chưng x%d lá. 🍶 Hủ Rượu chỉ dùng để tự cứu bản thân." % [cards_needed, banh_count]

func _get_valid_rescue_cards(victim_seat: int) -> Array:
	var valid_list: Array = []
	for card_ui in hand_container.get_children():
		var info = _get_card_info_from_ui(card_ui)
		var c_name = str(info.get("name", "")).to_lower()
		var c_sub_type = int(info.get("subType", -1))
		if c_sub_type == 4 or "bánh chưng" in c_name:
			valid_list.append(card_ui)
		elif (c_sub_type == 5 or "hủ rượu" in c_name) and victim_seat == my_seat:
			valid_list.append(card_ui)
	return valid_list

func _ensure_rescue_card_selector_container() -> void:
	if rescue_card_selector_scroll and is_instance_valid(rescue_card_selector_scroll):
		rescue_card_selector_scroll.visible = false

func _build_rescue_card_selector_buttons(_valid_cards: Array) -> void:
	if rescue_card_selector_scroll and is_instance_valid(rescue_card_selector_scroll):
		rescue_card_selector_scroll.visible = false

func _update_rescue_card_selector_buttons() -> void:
	pass

func _close_rescue_modal() -> void:
	if rescue_modal and is_instance_valid(rescue_modal):
		rescue_modal.visible = false
	is_waiting_rescue = false
	rescue_card_to_use = null
	_set_reaction_hand_focus(false)

func _prompt_rescue_reaction(victim_seat: int) -> void:
	if not generals_data.has(victim_seat):
		return
	var victim = generals_data[victim_seat]
	# Người chơi tự chọn trực tiếp lá bài trên tay; không lựa chọn trên popup.
	rescue_card_to_use = null
	for card_node in hand_container.get_children():
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)

	is_waiting_rescue = true
	rescue_victim_seat = victim_seat
	rescue_time_left = 40.0
	current_waiting_seat = my_seat
	current_waiting_timer = 40.0

	var who_text = "BẠN ĐANG HẤP HỐI!" if victim_seat == my_seat else ("TƯỚNG %s ĐANG CẬN TỬ!" % victim["name"])
	var req_label = "Bánh Chưng hoặc Hủ Rượu" if victim_seat == my_seat else "Bánh Chưng"
	rescue_desc_lbl.text = "🆘 %s (Ghế %d)\n%s\n👉 Hãy CHỌN TRỰC TIẾP lá [%s] trên tay bạn để cứu, hoặc bấm [KHÔNG CỨU]:" % [who_text, victim_seat, _get_rescue_requirement_text(victim_seat), req_label]
	rescue_confirm_btn.text = "✅ CHỌN LÁ TRÊN TAY ĐỂ CỨU"
	rescue_confirm_btn.disabled = true
	rescue_timer_lbl.text = "⏳ Còn lại: 40s"

	if rescue_card_selector_scroll and is_instance_valid(rescue_card_selector_scroll):
		rescue_card_selector_scroll.visible = false

	_set_reaction_hand_focus(true, "Cứu", victim_seat)
	desc_text.text = "🆘 Hãy bấm trực tiếp lá [%s] sáng trên tay bạn để chọn cứu!" % req_label

	rescue_modal.visible = true

func _close_dodge_reaction_state() -> void:
	for card_node in selected_oai_nhuoc_card_nodes:
		if is_instance_valid(card_node) and card_node.has_method("set_selected"):
			card_node.set_selected(false)
	selected_oai_nhuoc_card_nodes.clear()
	is_waiting_oai_nhuoc = false
	is_waiting_nghia_tu = false
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) and selected_dodge_card_ui.has_method("set_selected"):
		selected_dodge_card_ui.set_selected(false)
	selected_dodge_card_ui = null
	is_waiting_dodge = false
	is_current_reaction_slash = false
	if dodge_modal and is_instance_valid(dodge_modal):
		dodge_modal.visible = false
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	if dodge_confirm_btn and is_instance_valid(dodge_confirm_btn):
		dodge_confirm_btn.modulate = Color.WHITE
	_set_reaction_hand_focus(false)

func _prompt_oai_nhuoc(active_card_value: Variant, timeout_sec: float) -> void:
	var active_card: Dictionary = active_card_value if active_card_value is Dictionary else {}
	dodge_attacker_seat = int(active_card.get("casterSeat", 0))
	incoming_slash_damage = _get_effect_damage(active_card)
	incoming_slash_element = str(active_card.get("damageElement", "NORMAL"))
	if generals_data.has(dodge_attacker_seat):
		generals_data[dodge_attacker_seat]["last_slash_suit"] = str(active_card.get("suit", ""))
	is_waiting_dodge = true
	is_waiting_oai_nhuoc = true
	is_current_reaction_slash = true
	selected_dodge_card_ui = null
	selected_oai_nhuoc_card_nodes.clear()
	custom_reaction_callback = Callable()
	dodge_time_left = timeout_sec
	current_waiting_seat = my_seat
	current_waiting_timer = timeout_sec
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].set_turn_active(true)
		generals_data[my_seat]["avatar_node"].update_turn_timer(int(timeout_sec))
	if generals_data.has(dodge_attacker_seat) and generals_data[dodge_attacker_seat].has("avatar_node") and is_instance_valid(generals_data[dodge_attacker_seat]["avatar_node"]):
		generals_data[dodge_attacker_seat]["avatar_node"].set_turn_active(false)
	current_reaction_required_type = "Bài"
	current_reaction_allow_dodge_as_slash = false
	current_reaction_pass_text = "💥 CHỊU %d SÁT THƯƠNG" % incoming_slash_damage
	current_reaction_confirm_prefix = "🛡️ BỎ 1 LÁ + ĐỠ"
	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = "🐘 OAI NHƯỢC"
	dodge_desc_lbl.text = "Chọn đúng 2 lá trên tay, trong đó có ít nhất 1 lá Đỡ hợp lệ; hoặc chịu sát thương của đòn Trảm."
	dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)
	dodge_pass_btn.text = current_reaction_pass_text
	dodge_pass_btn.visible = true
	dodge_pass_btn.disabled = false
	if dodge_khien_may_btn:
		dodge_khien_may_btn.visible = false
	dodge_confirm_btn.visible = true
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	_set_reaction_hand_focus(true, "Bài")
	_update_oai_nhuoc_selection()
	dodge_modal.visible = true

func _handle_oai_nhuoc_card_selection(card_node: Control) -> void:
	if not is_instance_valid(card_node):
		return
	if is_waiting_nghia_tu:
		for selected_card in selected_oai_nhuoc_card_nodes:
			if selected_card != card_node and is_instance_valid(selected_card) and selected_card.has_method("set_selected"):
				selected_card.set_selected(false)
		selected_oai_nhuoc_card_nodes.assign([card_node])
		if card_node.has_method("set_selected"):
			card_node.set_selected(true)
		AudioManager.play_card_select()
		_update_oai_nhuoc_selection()
		return
	if card_node in selected_oai_nhuoc_card_nodes:
		selected_oai_nhuoc_card_nodes.erase(card_node)
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
	elif selected_oai_nhuoc_card_nodes.size() < (1 if is_waiting_nghia_tu else 2):
		selected_oai_nhuoc_card_nodes.append(card_node)
		if card_node.has_method("set_selected"):
			card_node.set_selected(true)
	else:
		desc_text.text = "❌ Nghĩa Tử chỉ cho chọn 1 lá." if is_waiting_nghia_tu else "❌ Oai Nhược chỉ cho chọn đúng 2 lá. Bỏ chọn một lá trước."
		AudioManager.play_skill()
		return
	AudioManager.play_card_select()
	_update_oai_nhuoc_selection()

func _update_oai_nhuoc_selection() -> void:
	if is_waiting_nghia_tu:
		var nghia_tu_valid := selected_oai_nhuoc_card_nodes.size() == 1
		dodge_confirm_btn.disabled = not nghia_tu_valid
		dodge_confirm_btn.text = "🛡️ CHỊU THAY (%d/1)" % selected_oai_nhuoc_card_nodes.size()
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "Đã chọn %d/1 lá" % selected_oai_nhuoc_card_nodes.size()
		desc_text.text = "🛡️ Có thể xác nhận Nghĩa Tử." if nghia_tu_valid else "👉 Chọn 1 lá để chịu thay 1 sát thương."
		return
	var has_valid_dodge := false
	for card_node in selected_oai_nhuoc_card_nodes:
		if _is_card_valid_for_dodge(card_node, dodge_attacker_seat, true):
			has_valid_dodge = true
			break
	var valid := selected_oai_nhuoc_card_nodes.size() == 2 and has_valid_dodge
	dodge_confirm_btn.disabled = not valid
	dodge_confirm_btn.text = "🛡️ BỎ 1 LÁ + ĐỠ (%d/2)" % selected_oai_nhuoc_card_nodes.size()
	dodge_confirm_btn.modulate = Color(0.65, 1.0, 0.65) if valid else Color.WHITE
	if dodge_selected_lbl:
		dodge_selected_lbl.text = "Đã chọn %d/2 lá%s" % [selected_oai_nhuoc_card_nodes.size(), " — hợp lệ" if valid else " — cần có 1 lá Đỡ hợp lệ"]
	desc_text.text = "🛡️ Có thể xác nhận Oai Nhược." if valid else "👉 Chọn đúng 2 lá, trong đó có ít nhất 1 lá Đỡ hợp lệ."

func _close_oai_nhuoc_prompt() -> void:
	_close_dodge_reaction_state()

func _stop_test_audio() -> void:
	if not AudioManager:
		return
	for audio_node in AudioManager.get_children():
		if audio_node is AudioStreamPlayer:
			audio_node.stop()
			if audio_node != AudioManager.bgm_player and audio_node != AudioManager.sfx_player and audio_node != AudioManager.voice_player:
				audio_node.queue_free()

func _run_reaction_card_selection_test() -> bool:
	for card_node in hand_container.get_children():
		hand_container.remove_child(card_node)
		card_node.queue_free()
	var test_cards = [
		{"id": "test_banh_chung", "name": "Bánh Chưng", "suit": "Heart", "rank": 8, "cat": 0, "subType": 4, "desc": "Cứu hấp hối"},
		{"id": "test_hu_ruou", "name": "Hủ Rượu", "suit": "Diamond", "rank": 9, "cat": 0, "subType": 5, "desc": "Tự cứu hấp hối"},
		{"id": "test_tram", "name": "Trảm", "suit": "Spade", "rank": 7, "cat": 0, "subType": 0, "desc": "Tấn công"},
		{"id": "test_do_first", "name": "Đỡ", "suit": "Heart", "rank": 2, "cat": 0, "subType": 3, "desc": "Né đòn"},
		{"id": "test_do_second", "name": "Đỡ", "suit": "Diamond", "rank": 7, "cat": 0, "subType": 3, "desc": "Né đòn"}
	]
	for card_info in test_cards:
		_add_card_to_player_hand(card_info)
	if hand_container.get_child_count() != test_cards.size():
		return false
	var banh_chung = hand_container.get_child(0)
	var hu_ruou = hand_container.get_child(1)
	var tram = hand_container.get_child(2)
	var first_dodge = hand_container.get_child(3)
	var second_dodge = hand_container.get_child(4)

	# Cứu phải được ưu tiên cả khi một phản ứng cũ chưa kịp đóng.
	is_waiting_dodge = true
	is_waiting_rescue = true
	rescue_victim_seat = my_seat
	_on_player_hand_card_clicked(banh_chung, _get_card_info_from_ui(banh_chung))
	var banh_chung_selected = rescue_card_to_use == banh_chung
	_on_player_hand_card_clicked(banh_chung, _get_card_info_from_ui(banh_chung))
	var rescue_second_click_keeps_selection = is_waiting_rescue and rescue_card_to_use == banh_chung
	if banh_chung.has_method("set_selected"):
		banh_chung.set_selected(false)
	rescue_card_to_use = null
	_on_player_hand_card_clicked(hu_ruou, _get_card_info_from_ui(hu_ruou))
	var hu_ruou_selected = rescue_card_to_use == hu_ruou
	_close_rescue_modal()

	# Sau khi Mượn Gươm thay pha, lá Trảm phải được chọn theo phản ứng mới.
	is_waiting_dodge = true
	current_reaction_required_type = "Trảm"
	current_reaction_allow_dodge_as_slash = false
	is_current_reaction_slash = false
	_on_player_hand_card_clicked(tram, _get_card_info_from_ui(tram))
	var tram_selected = selected_dodge_card_ui == tram
	_close_dodge_reaction_state()

	# Mọi modal phản ứng phải để người chơi tự chọn lá Đỡ mong muốn.
	_prompt_reaction_modal("KIỂM TRA", "Chọn Đỡ", "Đỡ", "BỎ", "DÙNG", 40.0, false, false, false, false)
	var generic_starts_unselected = selected_dodge_card_ui == null
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var generic_accepts_second_dodge = selected_dodge_card_ui == second_dodge
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var reaction_second_click_keeps_selection = is_waiting_dodge and selected_dodge_card_ui == second_dodge
	_close_dodge_reaction_state()

	_prompt_dodge_reaction(2, 1, "NORMAL")
	var slash_starts_unselected = selected_dodge_card_ui == null
	_on_player_hand_card_clicked(first_dodge, _get_card_info_from_ui(first_dodge))
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var slash_accepts_second_dodge = selected_dodge_card_ui == second_dodge
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var slash_second_click_keeps_selection = is_waiting_dodge and selected_dodge_card_ui == second_dodge
	_close_dodge_reaction_state()

	_prompt_thuy_trieu_rut_give(my_seat, 2, 40.0)
	var tide_starts_unselected = selected_dodge_card_ui == null
	var tide_only_shows_give_button = not dodge_pass_btn.visible and "ĐƯA" in dodge_confirm_btn.text
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var tide_accepts_second_card = selected_dodge_card_ui == second_dodge
	_on_player_hand_card_clicked(second_dodge, _get_card_info_from_ui(second_dodge))
	var tide_second_click_keeps_selection = is_waiting_thuy_trieu_rut_give and selected_dodge_card_ui == second_dodge
	_close_thuy_trieu_rut_give_prompt()

	# Dẫn Cầu có thể nhận state refresh trong lúc người bị ép đang chọn Trảm.
	# Việc dựng lại tay phải giữ lá đã chọn và nút xác nhận đang bật.
	current_server_phase = "AWAIT_DAN_CAU"
	is_network_mode = true
	_prompt_reaction_modal("🌉 DẪN CẦU", "Chọn Trảm", "Trảm", "🗡️ BỊ CƯỚP 2 LÁ", "⚔️ CHỌN TRẢM", 40.0, false, false, false, false)
	_on_player_hand_card_clicked(tram, _get_card_info_from_ui(tram))
	var dan_cau_selected_before_sync = selected_dodge_card_ui == tram and not dodge_confirm_btn.disabled
	var refreshed_dan_cau_hand: Array = []
	for card_info in test_cards:
		refreshed_dan_cau_hand.append({
			"id": card_info["id"],
			"name": card_info["name"],
			"suit": card_info["suit"],
			"rank": card_info["rank"],
			"category": card_info["cat"],
			"subType": card_info["subType"],
			"desc": card_info["desc"]
		})
	refreshed_dan_cau_hand.append({"id": "test_dan_cau_refresh", "name": "Rượu", "suit": "Club", "rank": 3, "category": 0, "subType": 5, "desc": "Ép dựng lại tay"})
	_sync_player_hand_from_server(refreshed_dan_cau_hand)
	var dan_cau_selection_survives_sync = selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) \
		and str(_get_card_info_from_ui(selected_dodge_card_ui).get("id", "")) == "test_tram" \
		and not dodge_confirm_btn.disabled and "Trảm" in dodge_confirm_btn.text
	_close_dodge_reaction_state()

	_prompt_dodge_reaction(2, 2, "NORMAL")
	var wine_damage_label_is_accurate = dodge_pass_btn.visible and "-2 MÁU" in dodge_pass_btn.text
	var wine_damage_from_active_card_is_accurate = _get_effect_damage({"damage": 1, "isWineBuff": true}) == 2
	_close_dodge_reaction_state()
	generals_data[2]["is_wine_buff_active"] = false
	_on_network_action_received({
		"actionSeq": 999998,
		"type": "PLAY_SLASH",
		"casterSeat": 2,
		"targetSeat": my_seat,
		"cardId": "test_wine_slash",
		"cardName": "Trảm",
		"card": {"id": "test_wine_slash", "name": "Trảm", "suit": "Spade", "rank": 7},
		"damage": 2,
		"isWineBuff": true
	})
	var remote_wine_delta_keeps_damage = incoming_slash_damage == 2 and dodge_pass_btn.visible and "-2 MÁU" in dodge_pass_btn.text
	_close_dodge_reaction_state()

	_ensure_harvest_modal()
	_ensure_drum_reveal_modal()
	_ensure_showcase_layer()
	var static_overlays = [dodge_modal, rescue_modal, general_info_modal, victory_defeat_modal, iron_chain_modal, card_pick_modal]
	var static_popups_are_frontmost = true
	for overlay in static_overlays:
		static_popups_are_frontmost = static_popups_are_frontmost and overlay.z_as_relative == false and overlay.z_index >= 320
	var reaction_hand_is_reachable = dodge_modal.mouse_filter == Control.MOUSE_FILTER_IGNORE and rescue_modal.mouse_filter == Control.MOUSE_FILTER_IGNORE
	var dynamic_popups_are_frontmost = history_popup and history_popup.z_as_relative == false and history_popup.z_index >= 320 \
		and harvest_modal and harvest_modal.z_as_relative == false and harvest_modal.z_index >= 320 \
		and drum_reveal_modal and drum_reveal_modal.z_as_relative == false and drum_reveal_modal.z_index >= 320 \
		and showcase_center and showcase_center.z_as_relative == false and showcase_center.z_index >= 280
	var showcase_started_at = Time.get_ticks_msec() / 1000.0
	_animate_showcase_card("Kiếm Thuận Thiên", "Vườn Không Nhà Trống phá hủy [Kiếm Thuận Thiên] của mục tiêu!", _get_showcase_card_info("Kiếm Thuận Thiên"), 2.0)
	var village_destroy_duration_is_two_seconds = not showcase_entries.is_empty() and abs(float(showcase_entries.back().get("expires_at", 0.0)) - showcase_started_at - 2.0) < 0.1

	_on_network_action_received({
		"actionSeq": 999999,
		"type": "BAI_COC_BACH_DANG_TRIGGERED",
		"casterSeat": 2,
		"targetSeat": 2,
		"judgeCard": {"id": "test_judge", "name": "Bài Phán Xét", "suit": "Spade", "rank": 9}
	})
	var judgement_root = get_node_or_null("JudgementRevealRoot")
	var judgement_visible = judgement_root != null
	var judgement_is_frontmost = judgement_root and judgement_root.z_as_relative == false and judgement_root.z_index >= 300
	last_bai_coc_judgement_at_msec = Time.get_ticks_msec() - BAI_COC_JUDGEMENT_VISUAL_MSEC - 100
	var duplicate_bai_coc_tween = _show_judgement_result(false, "Bãi Cọc Bạch Đằng", {"id": "test_judge", "name": "Bài Phán Xét", "suit": "Spade", "rank": 9})
	var bai_coc_visual_is_deduplicated = duplicate_bai_coc_tween == null
	var bai_coc_history_is_deduplicated = not _should_replay_history_effect("BAI_COC_BACH_DANG_TRIGGERED", {
		"type": "BAI_COC_BACH_DANG_TRIGGERED",
		"judgeCard": {"id": "test_judge", "suit": "Spade", "rank": 9}
	}) and not _should_replay_history_effect("BAI_COC_BACH_DANG_SAFE", {
		"baiCocJudgeCard": {"id": "test_judge", "suit": "Spade", "rank": 9}
	}) and _should_replay_history_effect("BAI_COC_BACH_DANG_TRIGGERED", {})
	var rescued_avatar = generals_data[my_seat].get("avatar_node")
	rescued_avatar.set_near_death(true)
	rescued_avatar.update_hp(1, rescued_avatar.max_hp)
	var rescued_avatar_stops_flashing = rescued_avatar.near_death_tween == null and (not rescued_avatar.near_death_halo or not rescued_avatar.near_death_halo.visible) and rescued_avatar.scale == Vector2.ONE and rescued_avatar.modulate == Color.WHITE
	rescued_avatar.scale = Vector2(1.04, 1.04)
	rescued_avatar.set_near_death(false)
	var repeated_state_sync_keeps_hover_scale = rescued_avatar.scale == Vector2(1.04, 1.04)
	rescued_avatar.scale = Vector2.ONE
	var human_alive_states: Dictionary = {}
	for seat in generals_data:
		var test_general = generals_data[seat]
		if not test_general.get("isAI", false):
			human_alive_states[seat] = test_general.get("is_alive", false)
			test_general["is_alive"] = false
	var bots_continue_after_all_players_die = _is_ai_controller()
	for seat in human_alive_states:
		generals_data[seat]["is_alive"] = human_alive_states[seat]
	var ai_card_delay_is_one_point_five_seconds = AI_CARD_PLAY_DELAY == 1.5
	var han_lam_name_uses_state = str(_get_han_lam_revealed_card({"hanLamRevealedCard": {"name": "Trảm - Hỏa"}}, {}).get("name", "")) == "Trảm - Hỏa"
	var tung_nghia_discard_limit_is_correct = _get_general_hand_limit({
		"hp": 4,
		"max_hp": 4,
		"hero_data": {"id": 11},
		"equipped_armor": "Khiên Mây Bện"
	}) == 5
	var khoan_gian_minimum_is_correct = _get_general_hand_limit({
		"hp": 3,
		"max_hp": 3,
		"hero_data": {"id": 18}
	}) == 4
	var khoan_gian_rounding_is_correct = _get_general_hand_limit({
		"hp": 3,
		"max_hp": 3,
		"hero_data": {"id": 18},
		"equipped_weapon": "Trường Đao Nam Sơn",
		"equipped_armor": "Khiên Mây Bện",
		"equipped_treasure": "Trống Đồng Đông Sơn"
	}) == 6
	is_waiting_nghia_tu = true
	_prompt_oai_nhuoc(null, 40.0)
	is_waiting_nghia_tu = true
	_handle_oai_nhuoc_card_selection(tram)
	_handle_oai_nhuoc_card_selection(tram)
	var nghia_tu_single_selection_stays_enabled = selected_oai_nhuoc_card_nodes.size() == 1 and selected_oai_nhuoc_card_nodes[0] == tram and not dodge_confirm_btn.disabled and dodge_confirm_btn.visible
	_close_oai_nhuoc_prompt()
	_prompt_oai_nhuoc({"casterSeat": 2, "damage": 2, "damageElement": "FIRE", "suit": "Spade"}, 40.0)
	_handle_oai_nhuoc_card_selection(tram)
	_handle_oai_nhuoc_card_selection(first_dodge)
	var oai_nhuoc_valid_pair_enables_dodge = not dodge_confirm_btn.disabled and "(2/2)" in dodge_confirm_btn.text and dodge_confirm_btn.modulate == Color(0.65, 1.0, 0.65)
	var oai_nhuoc_uses_slash_damage = dodge_pass_btn.visible and dodge_pass_btn.text == "💥 CHỊU 2 SÁT THƯƠNG"
	_close_oai_nhuoc_prompt()
	_prompt_oai_nhuoc({"casterSeat": 2, "damage": 1, "damageElement": "FIRE", "suit": "Spade"}, 40.0)
	_handle_oai_nhuoc_card_selection(tram)
	_handle_oai_nhuoc_card_selection(banh_chung)
	var oai_nhuoc_rejects_pair_without_dodge = dodge_confirm_btn.disabled
	_close_dodge_reaction_state()
	return banh_chung_selected and rescue_second_click_keeps_selection and hu_ruou_selected and tram_selected and generic_starts_unselected and generic_accepts_second_dodge and reaction_second_click_keeps_selection and slash_starts_unselected and slash_accepts_second_dodge and slash_second_click_keeps_selection and tide_starts_unselected and tide_only_shows_give_button and tide_accepts_second_card and tide_second_click_keeps_selection and dan_cau_selected_before_sync and dan_cau_selection_survives_sync and wine_damage_label_is_accurate and wine_damage_from_active_card_is_accurate and remote_wine_delta_keeps_damage and static_popups_are_frontmost and reaction_hand_is_reachable and dynamic_popups_are_frontmost and village_destroy_duration_is_two_seconds and judgement_visible and judgement_is_frontmost and bai_coc_visual_is_deduplicated and bai_coc_history_is_deduplicated and rescued_avatar_stops_flashing and repeated_state_sync_keeps_hover_scale and bots_continue_after_all_players_die and ai_card_delay_is_one_point_five_seconds and han_lam_name_uses_state and tung_nghia_discard_limit_is_correct and khoan_gian_minimum_is_correct and khoan_gian_rounding_is_correct and nghia_tu_single_selection_stays_enabled and oai_nhuoc_valid_pair_enables_dodge and oai_nhuoc_uses_slash_damage and oai_nhuoc_rejects_pair_without_dodge

func _prompt_reaction_modal(title_text: String, desc_text_msg: String, required_type: String, pass_text: String, confirm_prefix: String, timeout_sec: float = 40.0, allow_khien_may: bool = false, _auto_select_first: bool = false, allow_dodge_as_slash: bool = true, is_slash_attack: bool = false) -> void:
	var requires_card := required_type.strip_edges().to_upper() != "NONE"
	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = title_text
	dodge_desc_lbl.text = desc_text_msg
	dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)
	current_reaction_pass_text = pass_text
	current_reaction_confirm_prefix = confirm_prefix
	current_reaction_required_type = required_type
	current_reaction_allow_dodge_as_slash = allow_dodge_as_slash
	is_current_reaction_slash = is_slash_attack
	dodge_pass_btn.text = pass_text
	dodge_pass_btn.visible = true
	dodge_pass_btn.disabled = false
	dodge_confirm_btn.text = "%s [CHỌN BÀI]" % confirm_prefix if requires_card else confirm_prefix
	dodge_confirm_btn.disabled = requires_card

	dodge_time_left = timeout_sec
	current_waiting_seat = my_seat
	current_waiting_timer = timeout_sec
	is_waiting_dodge = true
	selected_dodge_card_ui = null
	custom_reaction_callback = Callable()

	# Luôn ẩn selector button trong modal vì toàn bộ chọn bài chuyển xuống trên tay:
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	_build_dodge_card_selector_buttons([])

	# Đếm 40s trên đầu người bị nhắm đến (bạn)
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].set_turn_active(true)
		generals_data[my_seat]["avatar_node"].update_turn_timer(int(timeout_sec))

	if selected_card_ui and is_instance_valid(selected_card_ui):
		if selected_card_ui.has_method("set_selected"):
			selected_card_ui.set_selected(false)
		selected_card_ui = null

	if requires_card:
		_set_reaction_hand_focus(true, required_type, dodge_attacker_seat if is_slash_attack else 0, allow_dodge_as_slash, is_slash_attack)
		# Phản ứng dùng bài luôn chờ người chơi tự chọn lá trên tay.
		_select_dodge_card(null)
	else:
		_set_reaction_hand_focus(false)
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "👉 Chọn một trong hai hiệu ứng, không cần chọn bài trên tay."

	var failed_km_modal = false
	if is_network_mode:
		var last_state_dict = NetworkClient.last_state if NetworkClient else {}
		var active_c = last_state_dict.get("activeCard", {}) if last_state_dict is Dictionary else {}
		if active_c is Dictionary:
			var failed_seats = active_c.get("khienMayFailedSeats", [])
			if failed_seats is Array and my_seat in failed_seats:
				failed_km_modal = true

	var my_gen = generals_data.get(my_seat, {})
	var has_khien_may = (allow_khien_may and "Khiên Mây" in str(my_gen.get("equipped_armor", "")) and not failed_km_modal)
	if dodge_khien_may_btn:
		if has_khien_may:
			dodge_khien_may_btn.visible = true
			dodge_khien_may_btn.disabled = false
			dodge_khien_may_btn.text = "🎲 LẬT KHIÊN MÂY (ĐỎ = ĐỠ)"
		else:
			dodge_khien_may_btn.visible = false

	dodge_modal.visible = true

func _prompt_thuy_trieu_rut_give(giver_seat: int, receiver_seat: int, timeout_sec: float) -> void:
	if giver_seat != my_seat or receiver_seat <= 0:
		return
	thuy_trieu_rut_giver_seat = giver_seat
	thuy_trieu_rut_receiver_seat = receiver_seat
	is_waiting_thuy_trieu_rut_give = true
	selected_dodge_card_ui = null
	current_reaction_pass_text = ""
	current_reaction_confirm_prefix = "🌊 ĐƯA"
	current_reaction_required_type = "Bài"
	current_reaction_allow_dodge_as_slash = false
	dodge_time_left = timeout_sec
	current_waiting_seat = my_seat
	current_waiting_timer = timeout_sec
	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = "🌊 THỦY TRIỀU RÚT"
	var receiver_gen = generals_data.get(receiver_seat, {})
	var receiver_name = receiver_gen.get("name", "Ghế %d" % receiver_seat) if receiver_gen is Dictionary else "Ghế %d" % receiver_seat
	dodge_desc_lbl.text = "Hãy chọn 1 lá trên tay để đưa cho %s. Nếu lá đưa không phải Bài Cơ Bản, người ít bài hơn sau chuyển chịu 1 sát thương Thủy:" % receiver_name
	dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)
	dodge_pass_btn.visible = false
	dodge_confirm_btn.text = "🌊 ĐƯA [CHỌN BÀI]"
	dodge_confirm_btn.visible = true
	dodge_confirm_btn.disabled = true
	if dodge_khien_may_btn:
		dodge_khien_may_btn.visible = false

	is_current_reaction_slash = false
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	_build_dodge_card_selector_buttons([])
	_set_reaction_hand_focus(true, "Bài", 0, false, false)
	_select_dodge_card(null)
	dodge_modal.visible = true

func _close_thuy_trieu_rut_give_prompt() -> void:
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) and selected_dodge_card_ui.has_method("set_selected"):
		selected_dodge_card_ui.set_selected(false)
	selected_dodge_card_ui = null
	is_waiting_thuy_trieu_rut_give = false
	thuy_trieu_rut_giver_seat = 0
	thuy_trieu_rut_receiver_seat = 0
	_set_reaction_hand_focus(false)
	if dodge_modal:
		dodge_modal.visible = false
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

func _is_dai_hong_thuy_name(card_name: String) -> bool:
	var normalized = card_name.to_lower()
	return "đại hồng thủy" in normalized or "dai hong thuy" in normalized or "thần sấm" in normalized or "than sam" in normalized

func _get_friendly_card_name(card_id: String) -> String:
	var cid = card_id.to_lower()
	if cid.is_empty() or cid == "pass": return "Bỏ qua"
	if "thuanthien" in cid: return "Kiếm Thuận Thiên"
	if "songcung" in cid: return "Song Cung Mường Nhạ"
	if "nothan" in cid: return "Nỏ Thần Kim Quy"
	if "truongdao" in cid or "tdao" in cid: return "Trường Đao Nam Sơn"
	if "thuongngau" in cid: return "Thương Ngâu Lãng Bạc"
	if "sungthancong" in cid or "stc" in cid: return "Súng Thần Công Hồ Triều"
	if "giapdong" in cid or "gd" in cid: return "Giáp Đồng Sơn Vi"
	if "khienmay" in cid or "km" in cid: return "Khiên Mây Bện"
	if "aobao" in cid or "ab" in cid: return "Áo Bào Hoàng Tộc"
	if "voichien" in cid or "vc" in cid: return "Voi Chiến Đại Việt"
	if "nguatrang" in cid or "ntr" in cid: return "Ngựa Trắng Thuần Nông"
	if "trongdong" in cid or "bronzedrum" in cid: return "Trống Đồng Đông Sơn"
	if "dieuke" in cid or "dk" in cid or "nullify" in cid or "flawless" in cid: return "Diệu Kế Phá Mưu"
	if "vuonkhong" in cid or "vk" in cid: return "Vườn Không Nhà Trống"
	if "dotkich" in cid: return "Đột Kích Trộm Lương"
	if "dungbinh" in cid or "db" in cid: return "Dụng Binh Như Thần"
	if "thachdau" in cid or "huyetchien" in cid or "td" in cid: return "Huyết Chiến"
	if "mokho" in cid or "mk" in cid: return "Mở Kho Cứu Tế"
	if "thuytrieurut" in cid: return "Thủy Triều Rút"
	if "baicocbachdang" in cid: return "Bãi Cọc Bạch Đằng"
	if "baicoc" in cid or "giactoi" in cid or "bcn" in cid: return "Giặc Tới"
	if "muaten" in cid or "mt" in cid: return "Mưa Tên Liên Châu"
	if "daihongthuy" in cid or "samset" in cid or "thansam" in cid or "ts" in cid: return "Đại Hồng Thủy"
	if "catluong" in cid or "cl" in cid: return "Cắt Đường Lương"
	if "tramao" in cid or "ta" in cid: return "Trầm Ảo Sa Bẫy"
	if "xichtam" in cid or "xich" in cid or "xt" in cid: return "Xích Tâm Tỏa"
	if "banh" in cid or "bc" in cid: return "Bánh Chưng"
	if "ruou" in cid or "hr" in cid: return "Hủ Rượu"
	if "do" in cid: return "Đỡ"
	if "tl_" in cid or "loi" in cid or "thuy" in cid: return "Trảm - Thủy"
	if "th_" in cid or "hoa" in cid: return "Trảm - Hỏa"
	if "tn_" in cid or "tram" in cid: return "Trảm"
	return card_id

func _get_card_display_name(card: Dictionary) -> String:
	var name = str(card.get("name", card.get("cardName", ""))).strip_edges()
	if _is_dai_hong_thuy_name(name):
		return "Đại Hồng Thủy"
	if not name.is_empty() and name != "null":
		return name
	var card_id = str(card.get("id", "")).strip_edges()
	var friendly = _get_friendly_card_name(card_id).strip_edges()
	if not friendly.is_empty() and friendly != card_id:
		return friendly
	if CardDatabase and not card_id.is_empty():
		var resource = CardDatabase.get_card(card_id)
		if resource:
			var db_name = str(resource.get("card_name")).strip_edges()
			if not db_name.is_empty() and db_name != "null":
				return db_name
	return friendly if not friendly.is_empty() else card_id

func _on_network_action_received(delta: Dictionary) -> void:
	if delta == null or not (delta is Dictionary) or delta.is_empty():
		return
	var caster_seat = int(delta.get("casterSeat", delta.get("seat", 0)))
	if caster_seat == 0 and delta.has("turnSeat"):
		caster_seat = int(delta.get("turnSeat", 0))

	var act_type = delta.get("actionType", delta.get("type", delta.get("action", "")))
	var target_seat = int(delta.get("targetSeat", 0))
	var is_armor_event = act_type in ["SLASH_BLOCKED_BY_ARMOR", "KHIEN_MAY_SUCCESS", "KHIEN_MAY_FAILED"] \
		or str(delta.get("armorEffect", "")) == "AO_BAO_HOANG_TOC"
	var is_judgement_event = act_type in [
		"DAI_HONG_THUY_HIT", "DAI_HONG_THUY_PASSED",
		"LIGHTNING_HIT", "LIGHTNING_PASSED",
		"SUPPLY_SHORTAGE_TRIGGERED", "SUPPLY_SHORTAGE_PASSED",
		"ACEDIA_TRIGGERED", "ACEDIA_PASSED",
		"KHIEN_MAY_SUCCESS", "KHIEN_MAY_FAILED",
		"BAI_COC_BACH_DANG_SAFE", "BAI_COC_BACH_DANG_TRIGGERED"
	]
	var is_uat_khi_prompt = act_type in ["UAT_KHI_PROMPT", "UAT_KHI_TARGET_PROMPT"]
	var skill_activations := _get_skill_activations(delta)
	var is_visible_hero_skill_event = not skill_activations.is_empty()
	var is_an_tich_defense = str(delta.get("defenseSkill", "")) == "Ẩn Tích"
	var attached_bai_coc_judge = delta.get("baiCocJudgeCard", {})
	var is_confirmed_slash_after_bai_coc = act_type in ["PLAY_SLASH", "SLASH_ATTACK"] \
		and attached_bai_coc_judge is Dictionary and not attached_bai_coc_judge.is_empty()
	var is_visible_target_card_action = act_type in ["PLAY_SNATCH", "PLAY_DISMANTLE", "TRIEU_DANG_DESTROY", "THUONG_NGAU_DESTROY", "PLAY_FLAWLESS_DEFENSE", "BINH_SAN_DESTROY", "CO_LAU_DESTROY", "UU_THIEP_STEAL"]
	# Giáp và Phán xét phải hiện cho tất cả người chơi (kể cả nạn nhân vừa ra bài / người đang phán xét).
	if caster_seat == my_seat and caster_seat > 0 and not is_an_tich_defense and not is_armor_event and not is_judgement_event and not is_visible_target_card_action and not is_confirmed_slash_after_bai_coc and not is_uat_khi_prompt and not is_visible_hero_skill_event:
		return
	var target_seats = delta.get("targetSeats", [])
	if not (target_seats is Array):
		target_seats = []
	var card_name = str(delta.get("cardName", ""))
	var card_id = str(delta.get("cardId", ""))
	var played_card = delta.get("card", {})
	if not (played_card is Dictionary):
		played_card = {}

	var act_sig = "%s_%s_%s_%s_%s_%s" % [
		str(delta.get("actionSeq", delta.get("seq", ""))),
		act_type,
		caster_seat,
		target_seat,
		card_id,
		str(target_seats)
	]
	if not act_sig.begins_with("____") and act_sig == last_processed_network_action_sig:
		return
	last_processed_network_action_sig = act_sig
	_show_activated_skills(skill_activations)

	if card_name.is_empty() and delta.has("activeCard") and delta["activeCard"] is Dictionary:
		card_name = str(delta["activeCard"].get("name", ""))
		if card_id.is_empty():
			card_id = str(delta["activeCard"].get("cardId", delta["activeCard"].get("id", "")))
	if card_name.is_empty():
		card_name = _get_friendly_card_name(card_id)
	if not played_card.is_empty():
		last_played_card_info = played_card.duplicate()

	# Bãi Cọc can arrive either as its own judgement action or attached to the
	# resumed action. Support both payload shapes so every connected client sees it.
	var b_judge = delta.get("baiCocJudgeCard", delta.get("judgeCard", {}))
	if not is_judgement_event and b_judge is Dictionary and not b_judge.is_empty():
		var b_suit = str(b_judge.get("suit", "")).strip_edges().capitalize()
		var b_safe = (b_suit == "Heart" or b_suit == "Diamond")
		var judgement_tween = _show_judgement_result(b_safe, "Bãi Cọc Bạch Đằng", b_judge)
		if judgement_tween:
			await judgement_tween.finished

	# Một delta PLAY_SLASH có thể đến ngay sau delta phán xét Bãi Cọc.
	# Giữ hiệu ứng Trảm phía sau hoạt ảnh phán xét trong trường hợp đó.
	if not is_judgement_event and "Trảm" in card_name:
		var remaining_msec = bai_coc_judgement_visual_until_msec - Time.get_ticks_msec()
		if remaining_msec > 0:
			await get_tree().create_timer(float(remaining_msec) / 1000.0).timeout

	# Xử lý toàn bộ các loại hành động ra bài từ Server (PLAY_SLASH, PLAY_PEACH, PLAY_WINE, PLAY_IRON_CHAIN, PLAY_EX_NIHILO, PLAY_AOE, PLAY_DUEL, PLAY_SCROLL, EQUIP...)
	var is_play_action = act_type.begins_with("PLAY_") or act_type in ["PLAY_CARD", "play_card", "CARD_PLAYED", "SLASH_ATTACK", "EQUIP"]
	if str(delta.get("armorEffect", "")) == "AO_BAO_HOANG_TOC" and act_type in ["NEAR_DEATH", "PLAYER_DIED"]:
		_play_armor_effect(target_seat, "Áo Bào Hoàng Tộc", true, int(delta.get("armorChargesRemaining", -1)))
		AudioManager.play_voice("Áo Bào Hoàng Tộc")
	if is_visible_target_card_action:
		var target_card = delta.get("targetCard", {})
		var target_zone = str(delta.get("targetCardZone", ""))
		if target_zone != "HAND" and target_card is Dictionary and not target_card.is_empty():
			var target_name = _get_card_display_name(target_card)
			var actor_name = generals_data[caster_seat].get("name", "Ghế %d" % caster_seat) if generals_data.has(caster_seat) else "Ghế %d" % caster_seat
			var target_owner_name = generals_data[target_seat].get("name", "Ghế %d" % target_seat) if generals_data.has(target_seat) else "Ghế %d" % target_seat
			var action_verb = "cướp" if act_type in ["PLAY_SNATCH", "UU_THIEP_STEAL"] else "phá hủy"
			if act_type == "BINH_SAN_DESTROY":
				action_verb = "dùng Bình Sạn phá hủy"
			elif act_type == "CO_LAU_DESTROY":
				action_verb = "dùng Cờ Lau phá hủy"
			elif act_type == "UU_THIEP_STEAL":
				action_verb = "dùng Ưu Thiếp cướp"
			var display_duration = 2.0 if card_name == "Vườn Không Nhà Trống" and action_verb == "phá hủy" else -1.0
			_animate_showcase_card(target_name, "%s %s [%s] của %s!" % [actor_name, action_verb, target_name, target_owner_name], target_card, display_duration)
		if act_type in ["BINH_SAN_DESTROY", "CO_LAU_DESTROY", "UU_THIEP_STEAL"]:
			AudioManager.play_skill()
	elif act_type == "RECAST_IRON_CHAIN":
		# Recast discards and redraws without targeting anyone, so it must not use
		# the normal remote-card path that subtracts a card from the remote hand.
		if caster_seat > 0 and caster_seat != my_seat:
			var recast_card = played_card.duplicate() if not played_card.is_empty() else _get_showcase_card_info("Xích Tâm Tỏa")
			var caster_name = generals_data[caster_seat].get("name", "Ghế %d" % caster_seat) if generals_data.has(caster_seat) else "Ghế %d" % caster_seat
			_animate_showcase_card("Xích Tâm Tỏa", "%s đổi [Xích Tâm Tỏa] để rút 1 lá bài." % caster_name, recast_card)
			_animate_discard_from_seat(caster_seat)
			_animate_draw_to_seat(caster_seat)
			AudioManager.play_voice("Xích Tâm Tỏa")
			AudioManager.play_skill()
	elif is_play_action:
		if card_name.is_empty() or card_name == card_id:
			if act_type == "PLAY_SLASH": card_name = "Trảm"
			elif act_type == "PLAY_PEACH": card_name = "Bánh Chưng"
			elif act_type == "PLAY_WINE": card_name = "Hủ Rượu"
			elif act_type == "PLAY_IRON_CHAIN": card_name = "Xích Tâm Tỏa"
			elif act_type == "PLAY_EX_NIHILO": card_name = "Dụng Binh Như Thần"
			elif act_type == "PLAY_DUEL": card_name = "Huyết Chiến"
			elif act_type == "PLAY_AOE":
				var desc_str = str(delta.get("description", ""))
				if "Giặc Tới" in desc_str or "Bãi Cọc" in desc_str or "baicoc" in card_id.to_lower() or "giactoi" in card_id.to_lower(): card_name = "Giặc Tới"
				else: card_name = "Mưa Tên Liên Châu"
			elif act_type == "EQUIP":
				card_name = _get_friendly_card_name(card_id)
		if act_type == "PLAY_PEACH" or card_name == "Bánh Chưng":
			recent_heal_seats[caster_seat] = Time.get_ticks_msec()
		if caster_seat > 0 and (caster_seat != my_seat or is_confirmed_slash_after_bai_coc):
			# STATE_UPDATE is applied before its delta; it already contains the new hand count.
			var effect_card = played_card.duplicate()
			if delta.has("damage"):
				effect_card["damage"] = int(delta.get("damage", 0))
			if delta.has("isWineBuff"):
				effect_card["isWineBuff"] = bool(delta.get("isWineBuff", false))
			_handle_remote_card_play(
				caster_seat,
				card_id if not card_id.is_empty() else card_name,
				target_seat,
				effect_card,
				card_name,
				target_seats,
				false,
				caster_seat != my_seat
			)
	elif act_type in ["DODGE_RESPONSE", "dodge_response", "DODGE_SUCCESS"]:
		var resp_seat = caster_seat if caster_seat > 0 else target_seat
		var defense_skill := str(delta.get("defenseSkill", ""))
		if defense_skill == "Ẩn Tích":
			_play_dodge_response_ray(null, resp_seat)
			_animate_showcase_card("Ẩn Tích", str(delta.get("description", "🌫️ [Ẩn Tích] dùng 1 lá Ẩn để Đỡ đòn Trảm!")))
			_add_log(str(delta.get("description", "🌫️ [Ẩn Tích] dùng 1 lá Ẩn để Đỡ đòn Trảm!")))
			if AudioManager.has_voice("Ẩn Tích"):
				AudioManager.play_voice("Ẩn Tích")
			else:
				AudioManager.play_skill()
			AudioManager.play_parry()
			return
		if resp_seat == my_seat:
			return # Không phát lại âm thanh nếu chính mình vừa đỡ
		if "SUCCESS" in act_type or (card_name != "pass" and card_id != "pass" and not card_id.is_empty()):
			_play_dodge_response_ray(null, resp_seat)
			_show_remote_card_use(delta, "phản ứng")
			_add_log("🛡️ Tướng Ghế %d đã phản ứng thành công!" % resp_seat)
			if AudioManager.has_voice(card_name):
				AudioManager.play_voice(card_name)
			else:
				var resolved_name = _get_friendly_card_name(card_id)
				if AudioManager.has_voice(resolved_name):
					AudioManager.play_voice(resolved_name)
				else:
					AudioManager.play_voice("Đỡ")
			AudioManager.play_parry()
		else:
			_add_log("💥 Tướng Ghế %d không đỡ đòn!" % resp_seat)
	elif act_type in ["AOE_DEFENDED", "DUEL_RESPOND", "RESCUE_SUCCESS", "RESCUE_ATTEMPT", "HICH_TUONG_SI_DISCARD", "NULLIFY_PLAYED", "BORROW_SWORD_SLASH", "NAM_SON_FOLLOW_UP_PLAYED", "DRUM_DISCARD", "HARVEST_PICKED"]:
		if act_type == "BORROW_SWORD_SLASH" and caster_seat > 0 and target_seat > 0:
			_play_smart_card_rays("Trảm", caster_seat, [target_seat])
		_show_remote_card_use(delta, "phản ứng")
		if act_type == "RESCUE_SUCCESS":
			var vic_s = int(delta.get("targetSeat", 0))
			if vic_s > 0 and generals_data.has(vic_s) and is_instance_valid(generals_data[vic_s].get("avatar_node")):
				generals_data[vic_s]["avatar_node"].set_near_death(false)
	elif act_type == "THUY_TRIEU_RUT_GIVE":
		var given_card = delta.get("givenCard", {})
		if not (given_card is Dictionary):
			given_card = {}
		var giver_seat = int(delta.get("giverSeat", delta.get("richerSeat", 0)))
		var receiver_seat = int(delta.get("receiverSeat", delta.get("poorerSeat", 0)))
		var giver_name = generals_data[giver_seat].get("name", "Ghế %d" % giver_seat) if generals_data.has(giver_seat) else "Ghế %d" % giver_seat
		var receiver_name = generals_data[receiver_seat].get("name", "Ghế %d" % receiver_seat) if generals_data.has(receiver_seat) else "Ghế %d" % receiver_seat
		_animate_showcase_card(_get_card_display_name(given_card), "%s đưa 1 lá cho %s." % [giver_name, receiver_name], given_card)
	elif act_type in ["PLAY_SCROLL", "DELAYED_SCROLL_ATTACHED", "HARVEST_START", "THUY_TRIEU_RUT_PROMPT_GIVE", "HICH_TUONG_SI_PROMPT", "TARGET_CARD_PROMPT"]:
		_show_remote_card_use(delta, "thi triển")
	elif act_type in ["END_TURN", "end_turn", "TURN_ENDED", "TURN_START"]:
		if is_remote_turn_active and (current_turn_seat == caster_seat or act_type == "TURN_START"):
			is_remote_turn_active = false
	elif act_type == "SLASH_BLOCKED_BY_ARMOR":
		_play_armor_effect(target_seat, "Giáp Đồng Sơn Vi")
		AudioManager.play_voice("Giáp Đồng Sơn Vi")
	elif act_type == "DAMAGE_TAKEN":
		var victim_seat = int(delta.get("targetSeat", 0))
		pending_damage_elements[victim_seat] = str(delta.get("element", "NORMAL"))
		if str(delta.get("armorEffect", "")) == "AO_BAO_HOANG_TOC":
			_play_armor_effect(victim_seat, "Áo Bào Hoàng Tộc", true, int(delta.get("armorChargesRemaining", -1)))
			AudioManager.play_voice("Áo Bào Hoàng Tộc")
		if victim_seat > 0 and generals_data.has(victim_seat):
			var now_m = Time.get_ticks_msec()
			if not (recent_heal_seats.has(victim_seat) and (now_m - recent_heal_seats[victim_seat] < 1500)):
				AudioManager.play_damage()
	elif (act_type == "UAT_KHI_PROMPT" or act_type == "UAT_KHI_TARGET_PROMPT") and caster_seat == my_seat:
		_begin_uat_khi_prompt()
		desc_text.text = "💢 [UẤT KHÍ] Chọn người còn sống (tối đa 2 người) để hồi 1 máu và rút 2 lá."
	elif act_type == "PLAYER_DIED":
		var victim_seat = int(delta.get("targetSeat", 0))
		if victim_seat > 0 and generals_data.has(victim_seat):
			generals_data[victim_seat]["is_alive"] = false
			if generals_data[victim_seat].has("avatar_node") and is_instance_valid(generals_data[victim_seat]["avatar_node"]):
				generals_data[victim_seat]["avatar_node"].set_near_death(false)
				generals_data[victim_seat]["avatar_node"].set_defeated(true)
			AudioManager.play_defeat()
	elif act_type == "DISCARD_CARDS":
		_animate_discard_from_seat(caster_seat, int(delta.get("discardedCount", 1)))
	elif act_type == "CHAIN_DAMAGE_SPREAD":
		pending_damage_elements[target_seat] = str(delta.get("element", "NORMAL"))
	elif act_type == "DRUM_PROMPT":
		_animate_showcase_card("Trống Đồng Đông Sơn", delta.get("description", "Điểm Trống"))
		AudioManager.play_skill()
	elif act_type == "DRUM_REVEAL":
		var c_seat = int(delta.get("casterSeat", 0))
		var t_seat = int(delta.get("targetSeat", 0))
		if c_seat == my_seat:
			var rev_cards = delta.get("cards", [])
			if rev_cards is Array and not rev_cards.is_empty():
				drum_reveal_dismissed = false
				_show_drum_reveal_modal(t_seat, rev_cards)
	elif act_type == "SONG_CUNG_PROMPT":
		_animate_showcase_card("Song Cung Mường Nhạ", delta.get("description", "Song Cung Mường Nhạ"))
		AudioManager.play_voice("Song Cung Mường Nhạ")
		AudioManager.play_skill()
	elif act_type == "SONG_CUNG_TRIGGERED":
		_show_remote_card_use(delta, "kích hoạt Song Cung")
		AudioManager.play_voice("Song Cung Mường Nhạ")
		AudioManager.play_skill()
		_animate_showcase_card("Song Cung Mường Nhạ", delta.get("description", "Bỏ qua Đỡ để Trảm gây sát thương!"))
	elif act_type == "SONG_CUNG_PASSED":
		var p_desc = str(delta.get("description", "Không kích hoạt Song Cung."))
		_add_log(p_desc)
	elif act_type == "HUNG_SUC_TRIGGERED":
		hung_suc_submission_pending = false
		is_targeting_hung_suc = false
		_clear_hung_suc_equipped_weapon_previews()
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		selected_card_ui = null
		_refresh_local_skill_buttons(my_seat)
		card_play_btn.visible = false
		_play_smart_card_rays("Hùng Sức", caster_seat, [target_seat])
		_animate_showcase_card("Hùng Sức", str(delta.get("description", "Hùng Sức được kích hoạt.")), played_card if not played_card.is_empty() else _get_showcase_card_info(card_name))
	elif act_type == "DA_TRACH_TRIGGERED":
		if caster_seat == my_seat:
			_update_action_btn()
	elif act_type == "LAP_LANG_DRAW":
		_animate_showcase_card("Lập Làng", str(delta.get("description", "Lập Làng rút 2 lá bài.")))
		AudioManager.play_skill()
	elif act_type in ["OAI_NHUOC_DISCARD", "DUNG_NUOC_TRIGGERED", "TUNG_NGHIA_DRAW", "VAN_SACH_TRIGGERED", "HAN_LAM_KEEP", "HAN_LAM_BOTTOM", "TRUNG_KIEN_TRIGGERED"]:
		var skill_effect_names = {
			"OAI_NHUOC_DISCARD": "Oai Nhược",
			"DUNG_NUOC_TRIGGERED": "Dựng Nước",
			"TUNG_NGHIA_DRAW": "Tùng Nghĩa",
			"VAN_SACH_TRIGGERED": "Văn Sách",
			"HAN_LAM_KEEP": "Hán Lâm",
			"HAN_LAM_BOTTOM": "Hán Lâm",
			"TRUNG_KIEN_TRIGGERED": "Trung Kiên"
		}
		_animate_showcase_card(str(skill_effect_names.get(act_type, "Kỹ năng")), str(delta.get("description", "Kỹ năng được kích hoạt.")))
	elif act_type in ["DAI_HONG_THUY_HIT", "DAI_HONG_THUY_PASSED", "LIGHTNING_HIT", "LIGHTNING_PASSED", "SUPPLY_SHORTAGE_TRIGGERED", "SUPPLY_SHORTAGE_PASSED", "ACEDIA_TRIGGERED", "ACEDIA_PASSED", "KHIEN_MAY_SUCCESS", "KHIEN_MAY_FAILED", "BAI_COC_BACH_DANG_SAFE", "BAI_COC_BACH_DANG_TRIGGERED"]:
		var judgement_success = act_type in ["DAI_HONG_THUY_HIT", "LIGHTNING_HIT", "SUPPLY_SHORTAGE_TRIGGERED", "ACEDIA_TRIGGERED"]
		if act_type in ["KHIEN_MAY_SUCCESS", "BAI_COC_BACH_DANG_SAFE"]:
			judgement_success = true
		elif act_type in ["KHIEN_MAY_FAILED", "BAI_COC_BACH_DANG_TRIGGERED"]:
			judgement_success = false
		var judgement_name = "Bãi Cọc Bạch Đằng" if act_type.begins_with("BAI_COC") else ("Khiên Mây Bện" if act_type.begins_with("KHIEN") else ("Đại Hồng Thủy" if act_type.begins_with("DAI_HONG_THUY") or act_type.begins_with("LIGHTNING") else ("Cắt Đường Lương" if act_type.begins_with("SUPPLY") else ("Trầm Ảo Sa Bẫy" if act_type.begins_with("ACEDIA") else "Xích Liên Hoàn"))))
		var judge_card = delta.get("judgeCard", delta.get("baiCocJudgeCard", delta.get("revealedCard", {})))
		if judge_card == null or not (judge_card is Dictionary):
			judge_card = {}
		if act_type.begins_with("KHIEN"):
			_play_armor_effect(target_seat, "Khiên Mây Bện", act_type == "KHIEN_MAY_SUCCESS")
			AudioManager.play_voice("Khiên Mây Bện")
			if act_type == "KHIEN_MAY_SUCCESS":
				if target_seat == my_seat:
					dodge_modal.visible = false
					is_waiting_dodge = false
					_set_reaction_hand_focus(false)
			elif act_type == "KHIEN_MAY_FAILED":
				if target_seat == my_seat:
					if dodge_khien_may_btn:
						dodge_khien_may_btn.visible = false
					if dodge_desc_lbl:
						dodge_desc_lbl.text = "⚠️ [Khiên Mây Bện] Phán xét ĐEN thất bại!\nHãy chọn một lá bài trên tay để Đỡ hoặc bấm [CHỊU ĐÒN]:"
					dodge_modal.visible = true
					is_waiting_dodge = true
					reaction_submission_pending = false
		_show_judgement_result(judgement_success, judgement_name, judge_card)

	if delta.has("description") and not str(delta["description"]).is_empty():
		_add_log(str(delta["description"]))

func _get_skill_activations(delta: Dictionary) -> Array[Dictionary]:
	var activations: Array[Dictionary] = []
	var server_activations = delta.get("skillActivations", [])
	if server_activations is Array:
		for raw_activation in server_activations:
			if raw_activation is Dictionary:
				var server_name := str(raw_activation.get("name", "")).strip_edges()
				var server_seat := int(raw_activation.get("seat", 0))
				if not server_name.is_empty() and server_seat > 0:
					activations.append({"name": server_name, "seat": server_seat})
	if not activations.is_empty():
		return activations

	var act_type := str(delta.get("actionType", delta.get("type", delta.get("action", ""))))
	var caster_seat := int(delta.get("casterSeat", delta.get("seat", delta.get("turnSeat", 0))))
	var target_seat := int(delta.get("targetSeat", 0))
	if act_type == "TOGGLE_SKILL" and "bật" in str(delta.get("description", "")).to_lower():
		activations.append({"name": "Chế Nỏ", "seat": caster_seat})
	elif act_type == "USE_SKILL":
		var description := str(delta.get("description", ""))
		if "Hịch Nghĩa" in description:
			activations.append({"name": "Hịch Nghĩa", "seat": caster_seat})
	elif HERO_SKILL_ACTIONS.has(act_type):
		var action_data: Dictionary = HERO_SKILL_ACTIONS[act_type]
		var owner_seat := target_seat if str(action_data.get("owner", "caster")) == "target" else caster_seat
		activations.append({"name": str(action_data.get("name", "")), "seat": owner_seat})
	return activations

func _show_activated_skills(activations: Array[Dictionary]) -> void:
	for activation in activations:
		var skill_name := str(activation.get("name", "")).strip_edges()
		var owner_seat := int(activation.get("seat", 0))
		if skill_name.is_empty() or owner_seat <= 0 or not generals_data.has(owner_seat):
			continue
		var avatar = generals_data[owner_seat].get("avatar_node")
		if is_instance_valid(avatar) and avatar.has_method("show_skill_banner"):
			avatar.show_skill_banner(skill_name.to_upper(), 2.0, true)

func _show_remote_card_use(delta: Dictionary, action_label: String) -> void:
	var used_card = delta.get("card", {})
	if not (used_card is Dictionary) or used_card.is_empty():
		var fallback_name = str(delta.get("cardName", ""))
		if fallback_name.is_empty():
			fallback_name = _get_friendly_card_name(str(delta.get("cardId", "")))
		used_card = _get_showcase_card_info(fallback_name)
	var card_name = str(used_card.get("name", delta.get("cardName", "Bài")))
	var suit = _get_suit_icon(str(used_card.get("suit", "")))
	var rank = _format_rank(used_card.get("rank", 1))
	var seat = int(delta.get("casterSeat", delta.get("targetSeat", 0)))
	var actor = generals_data[seat].get("name", "Ghế %d" % seat) if generals_data.has(seat) and seat > 0 else "Một người chơi"
	var aoe_name = str(delta.get("aoeName", ""))
	var active_card = delta.get("activeCard", {})
	var source = aoe_name
	if source.is_empty() and active_card is Dictionary:
		source = str(active_card.get("cardName", active_card.get("name", "")))
	var banner = "%s dùng [%s %s %s] %s." % [actor, suit, rank, card_name, action_label]
	if source in ["Giặc Tới", "Mưa Tên Liên Châu"]:
		banner = "%s dùng [%s %s %s] %s [%s]." % [actor, suit, rank, card_name, action_label, source]
	_animate_showcase_card(card_name, banner, used_card)
	if AudioManager.has_voice(card_name):
		AudioManager.play_voice(card_name)

func _relayout_hand_cards() -> void:
	if not hand_container or not is_instance_valid(hand_container):
		return
	var count = hand_container.get_child_count()
	var card_width := 118.0
	var normal_step := card_width - 10.0
	var viewport_size := get_viewport_rect().size
	var left_limit := 10.0
	var right_limit := viewport_size.x - 10.0
	var avatar = generals_data.get(my_seat, {}).get("avatar_node")
	if is_instance_valid(avatar):
		# The hand must stop before the avatar even when no skill button is visible.
		var avatar_rect: Rect2 = avatar.get_global_rect()
		if avatar_rect.size.x > 0.0:
			right_limit = minf(right_limit, avatar_rect.position.x - 10.0)
		var skill_stack = avatar.get_node_or_null("SkillButtonStack")
		if is_instance_valid(skill_stack) and skill_stack.visible:
			right_limit = minf(right_limit, skill_stack.get_global_rect().position.x - 10.0)

	var parent_control := hand_container.get_parent() as Control
	if not is_instance_valid(parent_control):
		return
	var parent_inverse: Transform2D = parent_control.get_global_transform().affine_inverse()
	var left_local: float = float((parent_inverse * Vector2(left_limit, 0.0)).x)
	var right_local: float = float((parent_inverse * Vector2(right_limit, 0.0)).x)
	var available_width: float = maxf(card_width, right_local - left_local)
	hand_container.position.x = left_local
	hand_container.size.x = available_width
	if count == 0:
		return

	var step := normal_step
	if count > 1:
		step = minf(normal_step, (available_width - card_width) / float(count - 1))

	var selected_index := -1
	for index in range(count):
		var card = hand_container.get_child(index)
		card.z_index = index
		if card.has_method("set_selected") and bool(card.get("is_selected")):
			selected_index = index

	# A selected card stays below later cards, but remains at least half visible.
	var steps: Array[float] = []
	if count > 1 and selected_index >= 0 and selected_index < count - 1 and step < card_width * 0.5:
		var selected_step := card_width * 0.5
		var other_step := (available_width - card_width - selected_step) / float(count - 2) if count > 2 else selected_step
		other_step = maxf(1.0, other_step)
		for index in range(count - 1):
			steps.append(selected_step if index == selected_index else other_step)
	else:
		for _index in range(maxi(0, count - 1)):
			steps.append(step)

	var content_width: float = card_width
	for step_value in steps:
		content_width += step_value
	# Center the hand within the safe area while preserving both edge margins.
	var start_x: float = maxf(0.0, (available_width - content_width) * 0.5)
	var x: float = start_x
	for index in range(count):
		var card = hand_container.get_child(index)
		var target_x: float = x
		if not card.has_meta("is_animating_discard"):
			# _process() recalculates the hand layout every frame. Reuse the
			# existing tween while its destination is unchanged; recreating it
			# every frame made mobile devices continuously allocate and kill tweens.
			var previous_target := float(card.get_meta("layout_target_x", INF))
			if abs(previous_target - target_x) > 0.5:
				if card.has_meta("layout_tween"):
					var prev_tween = card.get_meta("layout_tween")
					if prev_tween and (prev_tween is Tween) and prev_tween.is_valid():
						prev_tween.kill()
				if abs(card.position.x - target_x) > 1.5:
					var t = card.create_tween()
					t.tween_property(card, "position:x", target_x, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					card.set_meta("layout_tween", t)
				else:
					card.position.x = target_x
				card.set_meta("layout_target_x", target_x)
		if index < steps.size():
			x += steps[index]

func _update_distance_labels() -> void:
	if not generals_data.has(my_seat):
		return
	for seat in generals_data:
		var g = generals_data[seat]
		var avatar = g.get("avatar_node")
		if avatar and is_instance_valid(avatar) and avatar.has_method("set_distance_label"):
			avatar.set_distance_label(_calculate_distance(my_seat, int(seat)) if int(seat) != my_seat and g.get("is_alive", false) else -1)

func _ensure_card_fx_layer() -> void:
	if card_fx_layer and is_instance_valid(card_fx_layer):
		return
	card_fx_layer = Control.new()
	card_fx_layer.name = "CardFxLayer"
	card_fx_layer.set_anchors_preset(PRESET_FULL_RECT)
	card_fx_layer.mouse_filter = MOUSE_FILTER_IGNORE
	card_fx_layer.z_index = 170
	add_child(card_fx_layer)

func _get_seat_ray_anchor(seat: int) -> Vector2:
	if not generals_data.has(seat):
		return Vector2.ZERO
	var avatar = generals_data[seat].get("avatar_node")
	if avatar and is_instance_valid(avatar):
		return avatar.get_global_rect().get_center()
	return Vector2.ZERO

func _get_ray_color(card_name: String) -> Color:
	var normalized = card_name.to_lower()
	if "đỡ" in normalized or "do" == normalized:
		return Color(0.26, 0.88, 1.0, 1.0)
	if card_name in ["Giặc Tới", "Mưa Tên Liên Châu"]:
		return Color(1.0, 0.72, 0.20, 1.0)
	if "trảm" in normalized or "tram" in normalized:
		return Color(1.0, 0.30, 0.18, 1.0)
	return Color(0.94, 0.78, 0.28, 1.0)

func _play_card_target_ray(start_global: Vector2, end_global: Vector2, color: Color, delay: float = 0.0) -> void:
	if start_global == Vector2.ZERO or end_global == Vector2.ZERO:
		return
	_ensure_card_fx_layer()
	var to_local = card_fx_layer.get_global_transform().affine_inverse()
	var start = to_local * start_global
	var finish = to_local * end_global
	var distance = start.distance_to(finish)
	if distance < 12.0:
		return
	var travel_time = clampf(0.24 + distance / 1800.0, 0.24, 0.52)

	var glow = Line2D.new()
	glow.width = 14.0
	glow.default_color = Color(color.r, color.g, color.b, 0.20)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.antialiased = true
	glow.points = PackedVector2Array([start, start])
	card_fx_layer.add_child(glow)

	var core = Line2D.new()
	core.width = 4.0
	core.default_color = color
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.antialiased = true
	core.points = PackedVector2Array([start, start])
	card_fx_layer.add_child(core)

	var bolt = Polygon2D.new()
	bolt.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(0, -7), Vector2(12, 0), Vector2(0, 7)])
	bolt.color = Color(1.0, 0.96, 0.72, 1.0)
	bolt.position = start
	card_fx_layer.add_child(bolt)

	var impact = Polygon2D.new()
	impact.polygon = PackedVector2Array([Vector2(-18, 0), Vector2(0, -18), Vector2(18, 0), Vector2(0, 18)])
	impact.color = color
	impact.position = finish
	impact.scale = Vector2(0.18, 0.18)
	impact.modulate.a = 0.0
	card_fx_layer.add_child(impact)

	var flight = create_tween()
	if delay > 0.0:
		flight.tween_interval(delay)
	flight.tween_method(func(progress: float):
		var point = start.lerp(finish, progress)
		glow.points = PackedVector2Array([start, point])
		core.points = PackedVector2Array([start, point])
		bolt.position = point
	, 0.0, 1.0, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flight.tween_property(bolt, "modulate:a", 0.0, 0.08)

	var hit = create_tween()
	if delay + travel_time > 0.0:
		hit.tween_interval(delay + travel_time)
	hit.set_parallel(true)
	hit.tween_property(impact, "modulate:a", 0.95, 0.05)
	hit.tween_property(impact, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hit.chain().tween_property(impact, "modulate:a", 0.0, 0.18)

	var cleanup = create_tween()
	cleanup.tween_interval(delay + travel_time + 0.42)
	cleanup.tween_callback(glow.queue_free)
	cleanup.tween_callback(core.queue_free)
	cleanup.tween_callback(bolt.queue_free)
	cleanup.tween_callback(impact.queue_free)

func _play_smart_card_rays(card_name: String, caster_seat: int, target_seats: Array, source_card: Control = null) -> void:
	var source = source_card.get_global_rect().get_center() if source_card and is_instance_valid(source_card) else _get_seat_ray_anchor(caster_seat)
	if source == Vector2.ZERO:
		return
	var ray_color = _get_ray_color(card_name)
	var ray_index = 0
	for raw_seat in target_seats:
		var target_seat = int(raw_seat)
		if target_seat <= 0 or target_seat == caster_seat or not generals_data.has(target_seat):
			continue
		if not generals_data[target_seat].get("is_alive", false):
			continue
		_play_card_target_ray(source, _get_seat_ray_anchor(target_seat), ray_color, ray_index * 0.07)
		ray_index += 1
	if ("trảm" in card_name.to_lower() or "tram" in card_name.to_lower()) and ray_index > 0:
		last_slash_card_ray_origin = source
		last_slash_card_ray_time = Time.get_ticks_msec()

func _get_aoe_ray_targets(caster_seat: int) -> Array:
	var targets: Array = []
	for seat in range(1, battle_seat_count + 1):
		if seat != caster_seat and generals_data.has(seat) and generals_data[seat].get("is_alive", false):
			targets.append(seat)
	return targets

func _play_dodge_response_ray(card_node: Control = null, responder_seat: int = 0) -> void:
	var source = card_node.get_global_rect().get_center() if card_node and is_instance_valid(card_node) else _get_seat_ray_anchor(responder_seat)
	var destination = last_slash_card_ray_origin
	if Time.get_ticks_msec() - last_slash_card_ray_time > 45000 or destination == Vector2.ZERO:
		destination = _get_seat_ray_anchor(dodge_attacker_seat)
	_play_card_target_ray(source, destination, _get_ray_color("Đỡ"))

func _card_back_fx(start: Vector2, target: Vector2, delay: float = 0.0) -> void:
	_ensure_card_fx_layer()
	var card = TextureRect.new()
	card.texture = load("res://assets/ui/card_back_bg.png")
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.size = Vector2(54, 78)
	card.position = start - card.size * 0.5
	card.mouse_filter = MOUSE_FILTER_IGNORE
	card.modulate = Color(1.0, 1.0, 1.0, 0.92)
	card_fx_layer.add_child(card)
	var tw = create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(card, "position", target - card.size * 0.5, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(card, "scale", Vector2(0.72, 0.72), 0.12)
	tw.tween_callback(card.queue_free)

func _animate_draw_to_seat(seat: int, count: int = 1) -> void:
	if not deck_hud or not is_instance_valid(deck_hud):
		return
	var start = deck_hud.get_global_rect().get_center()
	var target = hand_container.get_global_rect().get_center() if seat == my_seat else Vector2.ZERO
	if seat != my_seat and generals_data.has(seat):
		var avatar = generals_data[seat].get("avatar_node")
		if avatar and is_instance_valid(avatar):
			target = avatar.get_global_rect().get_center()
	if target == Vector2.ZERO:
		return
	for idx in range(max(1, count)):
		_card_back_fx(start, target, idx * 0.07)

func _animate_discard_to_history(card_node: Control) -> void:
	if not history_button or not is_instance_valid(history_button) or not card_node or not is_instance_valid(card_node):
		return
	var start = card_node.get_global_rect().get_center()
	var target = history_button.get_global_rect().get_center()
	for idx in range(2):
		_card_back_fx(start + Vector2(float(idx * 7), float(idx * -4)), target, idx * 0.04)

func _animate_discard_from_seat(seat: int, count: int = 1) -> void:
	if not history_button or not is_instance_valid(history_button):
		return
	var start = Vector2.ZERO
	if seat == my_seat:
		start = hand_container.get_global_rect().get_center()
	elif generals_data.has(seat):
		var avatar = generals_data[seat].get("avatar_node")
		if avatar and is_instance_valid(avatar):
			start = avatar.get_global_rect().get_center()
	if start == Vector2.ZERO:
		return
	var target = history_button.get_global_rect().get_center()
	for idx in range(max(1, count)):
		_card_back_fx(start + Vector2(float(idx * 8), float(idx * -4)), target, idx * 0.05)

func _discard_player_card(card_node: Control) -> void:
	if not card_node or not is_instance_valid(card_node):
		return
	_animate_discard_to_history(card_node)
	hand_container.remove_child(card_node)
	card_node.queue_free()
	var g = generals_data[my_seat]
	g["hand_count"] = max(0, g["hand_count"] - 1)
	g["avatar_node"].update_hand_count(g["hand_count"])
	_relayout_hand_cards()

func _restore_turn_timer_to_attacker(attacker_seat: int, victim_seat: int = 0) -> void:
	current_waiting_seat = 0
	current_waiting_timer = 0.0
	if victim_seat > 0 and generals_data.has(victim_seat) and generals_data[victim_seat].has("avatar_node") and is_instance_valid(generals_data[victim_seat]["avatar_node"]):
		generals_data[victim_seat]["avatar_node"].set_turn_active(false)
	if attacker_seat > 0 and generals_data.has(attacker_seat) and generals_data[attacker_seat].has("avatar_node") and is_instance_valid(generals_data[attacker_seat]["avatar_node"]):
		generals_data[attacker_seat]["avatar_node"].set_turn_active(true)
		generals_data[attacker_seat]["avatar_node"].update_turn_timer(40)
	if attacker_seat == my_seat:
		is_player_turn = true
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		desc_text.text = "💡 Lượt của bạn: Hãy chọn bài trên tay và mục tiêu để tấn công!"
	else:
		remote_turn_timer = 40.0
		var atk_name = generals_data[attacker_seat]["name"] if generals_data.has(attacker_seat) else "Ghế %d" % attacker_seat
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - 40s..." % [atk_name, attacker_seat]
		desc_text.text = "⏳ Đang trong lượt của %s..." % atk_name

func _restore_truong_dao_slash_allowance(attacker_seat: int) -> void:
	if is_network_mode or attacker_seat != my_seat or slashes_used_this_turn <= 0:
		return
	var attacker = generals_data.get(attacker_seat, {})
	if not _has_equipped_weapon_name(attacker, "Trường Đao Nam Sơn"):
		return
	slashes_used_this_turn -= 1
	_add_log("🗡️ [Trường Đao Nam Sơn] Trảm vừa bị Đỡ, lượt Trảm của bạn được hoàn lại.")

func _handle_slash_attack(attacker_seat: int, target_seat: int, damage_amount: int = 1, damage_element: String = "NORMAL", slash_card_suit: String = "") -> void:
	var tgt = generals_data[target_seat]
	var atk = generals_data.get(attacker_seat, {})

	# Kiểm tra Dạ Trạch (Triệu Quang Phục không có bài trên tay miễn nhiễm với đòn Trảm)
	if _is_da_trach_slash_blocked(target_seat):
		var target_avatar = tgt.get("avatar_node")
		if is_instance_valid(target_avatar) and target_avatar.has_method("show_skill_banner"):
			target_avatar.show_skill_banner("DẠ TRẠCH", 2.0)
		AudioManager.play_skill()
		_add_log("🌙 [DẠ TRẠCH] %s không có bài trên tay nên miễn nhiễm với đòn Trảm!" % tgt["name"])
		if not is_network_mode:
			_restore_turn_timer_to_attacker(attacker_seat, target_seat)
		return

	atk["last_slash_suit"] = slash_card_suit
	var has_thuan_thien = _has_equipped_weapon_name(atk, "Kiếm Thuận Thiên")
	var tran_nam_bypass := _hero_has_skill(atk, "tran_nam") and damage_element == "NORMAL" and _get_card_color(slash_card_suit) in ["BLACK", "YELLOW"]

	# Trong chế độ cục bộ (Local): Đếm 40s trên đầu người bị trảm, tạm tắt trên đầu người đánh
	if not is_network_mode:
		current_waiting_seat = target_seat
		current_waiting_timer = 40.0
		if generals_data.has(attacker_seat) and generals_data[attacker_seat].has("avatar_node") and is_instance_valid(generals_data[attacker_seat]["avatar_node"]):
			generals_data[attacker_seat]["avatar_node"].set_turn_active(false)
		if generals_data.has(target_seat) and generals_data[target_seat].has("avatar_node") and is_instance_valid(generals_data[target_seat]["avatar_node"]):
			generals_data[target_seat]["avatar_node"].set_turn_active(true)
			generals_data[target_seat]["avatar_node"].update_turn_timer(40)
		if attacker_seat == my_seat:
			turn_indicator.text = "🛡️ ĐANG CHỜ %s ĐỠ ĐÒN (40s)..." % tgt["name"]
			desc_text.text = "🛡️ Đang chờ %s quyết định Đỡ hay Chịu đòn..." % tgt["name"]

	# 1. Kiểm tra Giáp Đồng Sơn Vi (chỉ chặn Trảm Thường, bị Kiếm Thuận Thiên xuyên qua)
	if not tran_nam_bypass and not has_thuan_thien and damage_element == "NORMAL" and "Giáp Đồng" in tgt.get("equipped_armor", ""):
		_play_armor_effect(target_seat, "Giáp Đồng Sơn Vi")
		AudioManager.play_voice("Giáp Đồng Sơn Vi")
		_add_log("🛡️ [Giáp Đồng Sơn Vi] của %s đã vô hiệu hóa hoàn toàn đòn Trảm Thường!" % tgt["name"])
		if not is_network_mode:
			_restore_turn_timer_to_attacker(attacker_seat, target_seat)
		return
	if not has_thuan_thien and _get_card_color(slash_card_suit) in ["BLACK", "YELLOW"] and "Giáp Tây Sơn" in tgt.get("equipped_armor", ""):
		_play_armor_effect(target_seat, "Giáp Tây Sơn")
		_add_log("🛡️ [Giáp Tây Sơn] của %s đã vô hiệu hóa Trảm bài Đen hoặc bài Vàng!" % tgt["name"])
		if not is_network_mode:
			_restore_turn_timer_to_attacker(attacker_seat, target_seat)
		return

	# 2. Kỹ năng Bùi Bị (Hero 98 - Dũng Hãn): Nếu Máu mục tiêu > Máu người Trảm thì không thể Đỡ
	var cannot_be_dodged = false
	if atk.get("hero_id", -1) == 98 and tgt.get("hp", 0) > atk.get("hp", 0):
		cannot_be_dodged = true
		_add_log("⚔️ Kỹ năng [Dũng Hãn] của %s: Đòn Trảm không thể bị Đỡ!" % atk["name"])

	if cannot_be_dodged:
		_animate_showcase_card("Không Thể Đỡ", "Đòn Trảm không thể bị hóa giải!")
		_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
		if not is_network_mode:
			_restore_turn_timer_to_attacker(attacker_seat, target_seat)
		return

	# 3. Mục tiêu là NGƯỜI CHƠI THẬT: Luôn mở DodgeModal để người chơi tự quyết định
	# (Tự bấm Lật Khiên Mây Bện nếu có, tự chọn lá Đỡ trên tay, hoặc tự bấm Chịu Đòn)
	if target_seat == my_seat or tgt.get("isPlayer", false):
		_prompt_dodge_reaction(attacker_seat, damage_amount, damage_element)
		return

	# Trong chế độ Server (Network Mode), Server là nguồn chân lý duy nhất tính toán cho các ghế khác và AI
	if is_network_mode:
		return

	# 4. Mục tiêu là BOT AI:
	# 4.1. AI phán xét Khiên Mây Bện nếu có trang bị
	if not has_thuan_thien and "Khiên Mây" in tgt.get("equipped_armor", ""):
		var judge_card = _draw_card_from_pile()
		var is_red = (judge_card.get("suit", "") in ["Heart", "Diamond"])
		var suit_sym = _get_suit_icon(judge_card.get("suit", ""))
		var rank_str = _format_rank(judge_card.get("rank", 1))
		if is_red:
			_animate_showcase_card("Khiên Mây Bện", "%s lật [%s %s] (ĐỎ) -> Đỡ thành công!" % [tgt["name"], suit_sym, rank_str], judge_card)
			_play_armor_effect(target_seat, "Khiên Mây Bện", true)
			AudioManager.play_voice("Khiên Mây Bện")
			_show_judgement_result(true, "Khiên Mây Bện", judge_card)
			_add_log("🛡️ [Khiên Mây Bện] của %s lật [%s %s] (ĐỎ) -> Tự động Đỡ thành công!" % [tgt["name"], suit_sym, rank_str])
			AudioManager.play_parry()
			_restore_truong_dao_slash_allowance(attacker_seat)
			await _resolve_local_song_cung_if_applicable(attacker_seat, target_seat, damage_amount, damage_element)
			_restore_turn_timer_to_attacker(attacker_seat, target_seat)
			await get_tree().create_timer(1.5).timeout
			return
		else:
			_animate_showcase_card("Khiên Mây Bện", "%s lật [%s %s] (VÀNG/ĐEN) -> Phán xét thất bại!" % [tgt["name"], suit_sym, rank_str], judge_card)
			_play_armor_effect(target_seat, "Khiên Mây Bện", false)
			AudioManager.play_voice("Khiên Mây Bện")
			_show_judgement_result(false, "Khiên Mây Bện", judge_card)
			_add_log("🛡️ [Khiên Mây Bện] của %s lật [%s %s] (ĐEN) -> Phán xét thất bại!" % [tgt["name"], suit_sym, rank_str])

	# 4.2. AI tìm lá Đỡ trên tay
	await get_tree().create_timer(1.5).timeout
	var dodge_idx = -1
	for idx in range(tgt["hand_cards"].size()):
		var c = tgt["hand_cards"][idx]
		if c.get("name", "") == "Đỡ":
			# Nếu người tấn công có Súng Thần Công Hồ Triều: không được Đỡ cùng màu với Trảm
			var has_sung = _has_equipped_weapon_name(atk, "Súng Thần Công Hồ Triều")
			if has_sung and slash_card_suit != "" and _is_same_card_color(c.get("suit", ""), slash_card_suit):
				continue
			dodge_idx = idx
			break

	if dodge_idx >= 0:
		var used_dodge = tgt["hand_cards"][dodge_idx]
		tgt["hand_cards"].remove_at(dodge_idx)
		tgt["hand_count"] = tgt["hand_cards"].size()
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		var suit_sym = _get_suit_icon(used_dodge.get("suit", ""))
		var rank_str = _format_rank(used_dodge.get("rank", 1))
		_animate_showcase_card("Đỡ", "%s dùng [%s %s Đỡ] hóa giải đòn tấn công!" % [tgt["name"], suit_sym, rank_str], used_dodge)
		_add_log("🛡️ %s đã dùng lá [%s %s Đỡ] hóa giải đòn Trảm thành công!" % [tgt["name"], suit_sym, rank_str])
		_play_dodge_response_ray(null, target_seat)
		AudioManager.play_voice("Đỡ")
		AudioManager.play_parry()

		_restore_truong_dao_slash_allowance(attacker_seat)
		await _resolve_local_song_cung_if_applicable(attacker_seat, target_seat, damage_amount, damage_element)
		_restore_turn_timer_to_attacker(attacker_seat, target_seat)
	else:
		_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
		_restore_turn_timer_to_attacker(attacker_seat, target_seat)

func _get_effect_damage(card_data: Dictionary, fallback: int = 1) -> int:
	var damage = max(fallback, int(card_data.get("damage", fallback)))
	if bool(card_data.get("isWineBuff", false)):
		damage = max(damage, fallback + 1)
	return damage

func _format_damage_pass_text(damage_amount: int, action_label: String = "CHỊU ĐÒN") -> String:
	return "💥 %s (-%d MÁU)" % [action_label, max(1, damage_amount)]

func _prompt_dodge_reaction(attacker_seat: int, damage_amount: int = 1, damage_element: String = "NORMAL", slash_suit_override: String = "") -> void:
	var atk = generals_data[attacker_seat]
	if slash_suit_override != "":
		atk["last_slash_suit"] = slash_suit_override
	dodge_attacker_seat = attacker_seat
	incoming_slash_damage = max(1, damage_amount)
	incoming_slash_element = damage_element
	dodge_time_left = 40.0
	current_waiting_seat = my_seat
	current_waiting_timer = 40.0
	is_waiting_dodge = true
	selected_dodge_card_ui = null

	# Hiển thị đồng hồ 40s đếm trên đầu người bị trảm (bạn), tắt trên đầu người đánh
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].set_turn_active(true)
		generals_data[my_seat]["avatar_node"].update_turn_timer(40)
	if generals_data.has(attacker_seat) and generals_data[attacker_seat].has("avatar_node") and is_instance_valid(generals_data[attacker_seat]["avatar_node"]):
		generals_data[attacker_seat]["avatar_node"].set_turn_active(false)

	# Hủy chọn bài đang chọn ở lượt trước nếu có
	if selected_card_ui and is_instance_valid(selected_card_ui):
		if selected_card_ui.has_method("set_selected"):
			selected_card_ui.set_selected(false)
		selected_card_ui = null

	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = "⚔️ BỊ TẤN CÔNG BỞI [TRẢM]!"

	var slash_suit = atk.get("last_slash_suit", "")
	var defender_name = generals_data[my_seat].get("name", "Bạn") if generals_data.has(my_seat) else "Bạn"
	var has_sung = _has_equipped_weapon_name(atk, "Súng Thần Công Hồ Triều")
	var forbidden_color = ""
	if has_sung and slash_suit != "":
		forbidden_color = _get_suit_name(slash_suit).to_upper()

	if has_sung and forbidden_color != "":
		dodge_desc_lbl.text = "⚠️ [Trảm] của %s đang tác động lên %s.\nSúng Thần Công không cho phép bạn dùng Đỡ bài %s cho lượt Trảm này.\nHãy chọn lá Đỡ hợp lệ trên tay hoặc bấm [CHỊU ĐÒN]:" % [atk["name"], defender_name, forbidden_color]
	else:
		dodge_desc_lbl.text = "[Trảm] của %s đang tác động lên %s.\nHãy CHỌN một lá bài trên tay để Đỡ hoặc bấm [CHỊU ĐÒN]:" % [atk["name"], defender_name]

	dodge_timer_lbl.text = "⏳ Còn lại: 40s"
	current_reaction_pass_text = _format_damage_pass_text(incoming_slash_damage)
	current_reaction_confirm_prefix = "🛡️ DÙNG"
	current_reaction_required_type = "Đỡ"
	current_reaction_allow_dodge_as_slash = false
	dodge_pass_btn.text = current_reaction_pass_text
	dodge_pass_btn.visible = true
	dodge_pass_btn.disabled = false

	# Kiểm tra Khiên Mây Bện của Người chơi
	var p_gen = generals_data.get(my_seat, {})
	var has_khien_may = "Khiên Mây" in str(p_gen.get("equipped_armor", ""))
	var atk_has_thuan_thien = _has_equipped_weapon_name(atk, "Kiếm Thuận Thiên")

	var failed_km = false
	if is_network_mode:
		var last_state_dict = NetworkClient.last_state if NetworkClient else {}
		var active_c = last_state_dict.get("activeCard", {}) if last_state_dict is Dictionary else {}
		if active_c is Dictionary:
			var failed_seats = active_c.get("khienMayFailedSeats", [])
			if failed_seats is Array and my_seat in failed_seats:
				failed_km = true

	if dodge_khien_may_btn:
		if has_khien_may and not atk_has_thuan_thien and not failed_km:
			dodge_khien_may_btn.visible = true
			dodge_khien_may_btn.disabled = false
			dodge_khien_may_btn.text = "🎲 LẬT KHIÊN MÂY (ĐỎ = ĐỠ)"
			if has_sung and forbidden_color != "":
				dodge_desc_lbl.text = "⚠️ [Trảm] của %s đang tác động lên %s.\nSúng Thần Công không cho phép bạn dùng Đỡ màu %s cho lượt Trảm này.\nBạn có thể [🎲 LẬT KHIÊN MÂY], chọn lá [ĐỠ] hợp lệ trên tay hoặc [💥 CHỊU ĐÒN]:" % [atk["name"], defender_name, forbidden_color]
			else:
				dodge_desc_lbl.text = "[Trảm] của %s đang tác động lên %s.\nBạn có thể [🎲 LẬT KHIÊN MÂY], chọn lá [ĐỠ] trên tay hoặc [💥 CHỊU ĐÒN]:" % [atk["name"], defender_name]
		else:
			dodge_khien_may_btn.visible = false
			if failed_km and dodge_desc_lbl:
				dodge_desc_lbl.text = "⚠️ [Khiên Mây Bện] Phán xét ĐEN thất bại!\nHãy chọn một lá bài trên tay để Đỡ hoặc bấm [CHỊU ĐÒN]:"

	is_current_reaction_slash = true
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false
	_build_dodge_card_selector_buttons([])

	var valid_cards = _get_valid_dodge_cards(attacker_seat, true)
	_set_reaction_hand_focus(true, "Đỡ", attacker_seat, false, true)
	if valid_cards.size() > 0:
		_select_dodge_card(null)
		desc_text.text = "🛡️ Bị Trảm! Hãy chọn lá Đỡ bạn muốn dùng trên tay, rồi bấm nút để xác nhận."
	else:
		_select_dodge_card(null)
		if has_khien_may and not atk_has_thuan_thien:
			desc_text.text = "🛡️ Bị Trảm! Bạn có thể bấm [🎲 LẬT KHIÊN MÂY] để phán xét né đòn, hoặc bấm [💥 CHỊU ĐÒN]."
		elif has_sung and forbidden_color != "":
			desc_text.text = "⚠️ Bị Trảm bởi Súng Thần Công (cấm Đỡ màu %s) và không có lá Đỡ hợp lệ!" % forbidden_color
		else:
			desc_text.text = "⚠️ Bị Trảm nhưng không có sẵn lá Đỡ! Bạn hãy bấm [💥 CHỊU ĐÒN] hoặc dùng kỹ năng tướng đổi bài."

	dodge_modal.visible = true

func _is_card_valid_for_dodge(card_ui: Control, attacker_seat: int, is_slash_attack: bool = true) -> bool:
	if not card_ui or not is_instance_valid(card_ui):
		return false
	var info = _get_card_info_from_ui(card_ui)
	var c_name = info.get("name", "")
	var suit = info.get("suit", "")
	var rank = int(info.get("rank", 1))

	var my_gen = generals_data.get(my_seat, {})
	var atk_gen = generals_data.get(attacker_seat, {}) if attacker_seat > 0 else {}

	# Các điều kiện hạn chế né đòn này CHỈ áp dụng cho đòn TRẢM trực tiếp, không áp dụng cho cẩm nang Mưa Tên Liên Châu:
	if is_slash_attack and attacker_seat > 0 and atk_gen is Dictionary and not atk_gen.is_empty():
		# 1. Súng Thần Công Hồ Triều: Mục tiêu không được dùng Đỡ cùng màu với Trảm
		if _has_equipped_weapon_name(atk_gen, "Súng Thần Công Hồ Triều"):
			var slash_suit = atk_gen.get("last_slash_suit", "")
			if slash_suit != "" and _is_same_card_color(suit, slash_suit):
				return false

		# 2. Hero 72: Trần Duệ Tông ("Trực Chiến"): Đỡ phải >= 7
		if atk_gen.get("hero_id", -1) == 72:
			if rank < 7:
				return false

		# 3. Hero 44: Tông Đản ("Thổ Binh"): Cự ly <= 2 không được dùng Đỡ từ 2..5
		if atk_gen.get("hero_id", -1) == 44:
			var dist = _calculate_distance(attacker_seat, my_seat)
			if dist <= 2 and rank >= 2 and rank <= 5:
				return false

	# Cơ bản: Lá bài "Đỡ"
	if "đỡ" in c_name.to_lower():
		return true

	# Hero 47: Lý Thường Kiệt ("Tiến Thoái"): Dùng Trảm như Đỡ
	if my_gen.get("hero_id", -1) == 47 and "trảm" in c_name.to_lower():
		return true

	# Hero 83: Nguyễn Cảnh Chân ("Thủy Binh"): Dùng bài Vàng như Đỡ
	if my_gen.get("hero_id", -1) == 83 and _get_card_color(suit) == "YELLOW":
		return true

	return false

func _is_card_valid_for_reaction(card_ui: Control, required_type: String, attacker_seat: int = 0, allow_dodge_as_slash: bool = false, is_slash_attack: bool = true) -> bool:
	if not card_ui or not is_instance_valid(card_ui):
		return false
	var info = _get_card_info_from_ui(card_ui)
	var c_name = str(info.get("name", "")).to_lower()
	var c_sub_type = int(info.get("subType", -1))
	if required_type == "Đỡ":
		return _is_card_valid_for_dodge(card_ui, attacker_seat, is_slash_attack)
	if required_type == "Trảm":
		if "trảm" in c_name:
			return true
		var my_gen = generals_data.get(my_seat, {})
		return allow_dodge_as_slash and my_gen.get("hero_id", -1) == 47 and "đỡ" in c_name
	if required_type in ["Diệu Kế", "Diệu Kế Phá Mưu"]:
		return "diệu kế" in c_name or c_sub_type == 10
	if required_type in ["Bỏ bài", "Bài"]:
		return true
	if required_type == "Bỏ bài Đỏ":
		return _get_card_color(str(info.get("suit", ""))) == "RED"
	if required_type == "Cứu":
		if c_sub_type == 4 or "bánh chưng" in c_name:
			return true
		if (c_sub_type == 5 or "hủ rượu" in c_name) and rescue_victim_seat == my_seat:
			return true
		return false
	return false

func _get_reaction_required_label(required_type: String) -> String:
	if required_type == "Bỏ bài":
		return "Bài"
	if required_type == "Diệu Kế Phá Mưu":
		return "Diệu Kế"
	if required_type == "Cứu":
		return "Bánh Chưng / Hủ Rượu" if rescue_victim_seat == my_seat else "Bánh Chưng"
	return required_type if not required_type.is_empty() else "Bài"

func _get_reaction_empty_label() -> String:
	return "❌ Không có lá [%s] phù hợp trên tay" % _get_reaction_required_label(current_reaction_required_type)

func _set_reaction_hand_focus(active: bool, required_type: String = "Đỡ", attacker_seat: int = 0, allow_dodge_as_slash: bool = false, is_slash_attack: bool = true) -> void:
	for card_ui in hand_container.get_children():
		if not (card_ui is Control):
			continue
		if not active:
			card_ui.modulate = Color.WHITE
			continue
		var valid = _is_card_valid_for_reaction(card_ui, required_type, attacker_seat, allow_dodge_as_slash, is_slash_attack)
		card_ui.modulate = Color.WHITE if valid else Color(0.38, 0.4, 0.46, 0.72)

func _get_valid_dodge_cards(attacker_seat: int, is_slash_attack: bool = true) -> Array:
	var valid_list: Array = []
	for card_ui in hand_container.get_children():
		if _is_card_valid_for_dodge(card_ui, attacker_seat, is_slash_attack):
			valid_list.append(card_ui)
	return valid_list

func _build_dodge_card_selector_buttons(_valid_cards: Array) -> void:
	if dodge_card_selector_hbox:
		for ch in dodge_card_selector_hbox.get_children():
			ch.queue_free()
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

func _update_dodge_card_selector_buttons() -> void:
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

func _select_dodge_card(card_ui: Control) -> void:
	if card_ui == null:
		if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) and selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)
		selected_dodge_card_ui = null
		var has_valid_card = false
		var reaction_attacker = dodge_attacker_seat if is_current_reaction_slash else 0
		for hand_card in hand_container.get_children():
			if _is_card_valid_for_reaction(hand_card, current_reaction_required_type, reaction_attacker, current_reaction_allow_dodge_as_slash, is_current_reaction_slash):
				has_valid_card = true
				break
		dodge_confirm_btn.disabled = true
		dodge_confirm_btn.modulate = Color(0.55, 0.58, 0.64, 0.78)
		if has_valid_card:
			dodge_confirm_btn.text = "%s [CHỌN BÀI]" % current_reaction_confirm_prefix if not current_reaction_confirm_prefix.is_empty() else dodge_confirm_btn.text
		else:
			dodge_confirm_btn.text = "❌ KHÔNG CÓ BÀI PHÙ HỢP"
		if is_waiting_thuy_trieu_rut_give:
			dodge_pass_btn.visible = false
		elif not current_reaction_pass_text.is_empty():
			dodge_pass_btn.text = current_reaction_pass_text
			dodge_pass_btn.visible = true
		elif not custom_reaction_callback.is_valid():
			dodge_pass_btn.text = _format_damage_pass_text(incoming_slash_damage)
			dodge_pass_btn.visible = true
		if not is_waiting_thuy_trieu_rut_give:
			dodge_pass_btn.disabled = false
		var req_lbl = _get_reaction_required_label(current_reaction_required_type)
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "👉 Hãy chạm chọn 1 lá [%s] sáng trên tay bạn để đưa đi." % req_lbl if is_waiting_thuy_trieu_rut_give else "👉 Hãy chạm chọn 1 lá [%s] sáng trên tay bạn (hoặc bấm %s)." % [req_lbl, dodge_pass_btn.text]
		desc_text.text = "👉 Hãy chọn lá [%s] bạn muốn dùng trên tay." % req_lbl if has_valid_card else "💥 Bạn không có sẵn lá [%s] phù hợp trên tay!" % req_lbl
		_update_dodge_card_selector_buttons()
		return

	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui) and selected_dodge_card_ui != card_ui:
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)

	selected_dodge_card_ui = card_ui
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(true)

	AudioManager.play_card_select()

	var info = _get_card_info_from_ui(card_ui)
	var suit_sym = _get_suit_icon(info.get("suit", ""))
	var rank_str = _format_rank(info.get("rank", 1))
	var c_name = info.get("name", "Bài")

	# The reaction button is enabled only after a valid card is actually selected.
	dodge_confirm_btn.disabled = false
	dodge_confirm_btn.modulate = Color.WHITE
	if not current_reaction_confirm_prefix.is_empty():
		dodge_confirm_btn.text = "%s [%s %s %s]" % [current_reaction_confirm_prefix, suit_sym, rank_str, c_name]
	elif custom_reaction_callback.is_valid():
		dodge_confirm_btn.text = "✅ DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name]
	else:
		dodge_confirm_btn.text = "🛡️ DÙNG [%s %s %s]" % [suit_sym, rank_str, c_name]

	if dodge_selected_lbl:
		dodge_selected_lbl.text = "👉 Đang chọn: %s %s [%s] (Bấm nút để xác nhận)" % [suit_sym, rank_str, c_name]
	desc_text.text = "🛡️ Đã chọn lá [%s %s %s]! Bấm nút để dùng." % [suit_sym, rank_str, c_name]

	_update_dodge_card_selector_buttons()

func _on_dodge_khien_may_clicked() -> void:
	if not is_waiting_dodge:
		return
	if dodge_khien_may_btn:
		dodge_khien_may_btn.disabled = true

	if is_network_mode:
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		_broadcast_player_battle_action("DODGE_RESPONSE", "KHIEN_MAY", dodge_attacker_seat)
		_add_log("🎲 [Khiên Mây Bện] Bạn gửi yêu cầu phán xét Khiên Mây lên Server...")
		return

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_sym = _get_suit_icon(j_suit)
	var rank_str = _format_rank(j_rank)
	var is_red = (j_suit in ["Heart", "Diamond"])

	# HIỂN THỊ HOẠT ẢNH PHÁN XÉT KHIÊN MÂY BỆN RÕ RÀNG (Lá bài bay ra + Con Dấu Stamp)
	_show_judgement_result(is_red, "Khiên Mây Bện", judge_card)
	_play_armor_effect(my_seat, "Khiên Mây Bện", is_red)
	AudioManager.play_voice("Khiên Mây Bện")

	if is_red:
		_animate_showcase_card("Khiên Mây Bện", "Phán xét [%s %s] (ĐỎ) -> Đỡ thành công!" % [suit_sym, rank_str], judge_card)
		_add_log("🛡️ [Khiên Mây Bện] Bạn kích hoạt lật phán xét [%s %s] (ĐỎ) -> Hóa giải đòn đánh thành công!" % [suit_sym, rank_str])
		AudioManager.play_voice("Đỡ")
		AudioManager.play_parry()
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("dodge", 1)

		dodge_modal.visible = false
		is_waiting_dodge = false
		_set_reaction_hand_focus(false)
		if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
			dodge_card_selector_scroll.visible = false
		if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
			if selected_dodge_card_ui.has_method("set_selected"):
				selected_dodge_card_ui.set_selected(false)
			selected_dodge_card_ui = null

		if custom_reaction_callback.is_valid():
			var cb = custom_reaction_callback
			custom_reaction_callback = Callable()
			cb.call(true, judge_card)
		else:
			_broadcast_player_battle_action("DODGE_RESPONSE", "khien_may", dodge_attacker_seat)

			_restore_truong_dao_slash_allowance(dodge_attacker_seat)
			await _resolve_local_song_cung_if_applicable(dodge_attacker_seat, my_seat, incoming_slash_damage, incoming_slash_element)
			_restore_turn_timer_to_attacker(dodge_attacker_seat, my_seat)
	else:
		_animate_showcase_card("Khiên Mây Bện", "Phán xét [%s %s] (ĐEN) -> Thất bại!" % [suit_sym, rank_str], judge_card)
		_add_log("🛡️ [Khiên Mây Bện] Bạn lật phán xét [%s %s] (ĐEN) -> Phán xét thất bại! Hãy chọn lá Đỡ trên tay hoặc bấm Chịu đòn." % [suit_sym, rank_str])
		AudioManager.play_skill()
		if dodge_khien_may_btn:
			dodge_khien_may_btn.visible = false
		dodge_desc_lbl.text = "⚠️ [Khiên Mây Bện] Phán xét [%s %s] ĐEN thất bại!\nHãy chọn một lá bài trên tay để Đỡ hoặc bấm [CHỊU ĐÒN]:" % [suit_sym, rank_str]

func _on_dodge_confirmed() -> void:
	if is_network_mode and current_waiting_seat != my_seat:
		_close_dodge_reaction_state()
		return
	if is_network_mode and reaction_submission_pending:
		return
	if is_waiting_song_cung:
		_on_song_cung_confirmed()
		return
	if is_waiting_oai_nhuoc:
		var required_card_count := 1 if is_waiting_nghia_tu else 2
		if selected_oai_nhuoc_card_nodes.size() != required_card_count or dodge_confirm_btn.disabled:
			return
		var confirmed_nghia_tu := is_waiting_nghia_tu
		var card_ids: Array = []
		for card_node in selected_oai_nhuoc_card_nodes:
			var card_info = _get_card_info_from_ui(card_node)
			card_ids.append(str(card_info.get("id", card_info.get("name", ""))))
		_close_oai_nhuoc_prompt()
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		NetworkClient.send_respond_action(true, "", "", card_ids)
		_add_log("🛡️ [NGHĨA TỬ] Bạn bỏ 1 lá để chịu thay sát thương." if confirmed_nghia_tu else "🛡️ [OAI NHƯỢC] Bạn bỏ 1 lá và dùng 1 lá Đỡ. Đang chờ Server đồng bộ...")
		return
	if is_waiting_thuy_trieu_rut_give:
		if not selected_dodge_card_ui or not is_instance_valid(selected_dodge_card_ui):
			return
		var give_card = selected_dodge_card_ui
		var give_info = _get_card_info_from_ui(give_card)
		var give_id = str(give_info.get("id", give_info.get("name", "")))
		if give_id.is_empty():
			return
		if give_card.has_method("set_selected"):
			give_card.set_selected(false)
		selected_dodge_card_ui = null
		is_waiting_thuy_trieu_rut_give = false
		thuy_trieu_rut_give_sent = true
		dodge_modal.visible = false
		if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
			dodge_card_selector_scroll.visible = false
		var receiver_label = "Ghế %d" % thuy_trieu_rut_receiver_seat
		if generals_data.has(thuy_trieu_rut_receiver_seat):
			receiver_label = generals_data[thuy_trieu_rut_receiver_seat].get("name", receiver_label)
		if is_network_mode:
			_broadcast_player_battle_action("RESPOND_ACTION", give_id)
			_add_log("🌊 [THỦY TRIỀU RÚT] Bạn đưa 1 lá cho %s. Đang chờ Server đồng bộ..." % receiver_label)
			_animate_showcase_card(str(give_info.get("name", "Lá bài")), "Bạn đưa 1 lá cho %s." % receiver_label, give_info)
			_discard_player_card(give_card)
		else:
			hand_container.remove_child(give_card)
			give_card.queue_free()
			var giver = generals_data.get(my_seat, {})
			giver["hand_count"] = max(0, int(giver.get("hand_count", 0)) - 1)
			if giver.has("avatar_node") and is_instance_valid(giver["avatar_node"]):
				giver["avatar_node"].update_hand_count(giver["hand_count"])
			_relayout_hand_cards()
			thuy_trieu_rut_given_card_info = give_info.duplicate()
			current_waiting_seat = 0
			current_waiting_timer = 0.0
			thuy_trieu_rut_give_finished.emit()
		return
	if not is_waiting_dodge:
		return
	if custom_reaction_callback.is_valid() and current_reaction_required_type.strip_edges().to_upper() == "NONE":
		dodge_modal.visible = false
		is_waiting_dodge = false
		_set_reaction_hand_focus(false)
		var choice_callback = custom_reaction_callback
		custom_reaction_callback = Callable()
		choice_callback.call(true, {})
		return
	if not selected_dodge_card_ui or not is_instance_valid(selected_dodge_card_ui):
		_on_dodge_passed()
		return

	var chosen_card = selected_dodge_card_ui
	var card_info = _get_card_info_from_ui(chosen_card)
	var c_name = card_info.get("name", "Bài")
	var suit_sym = _get_suit_icon(card_info.get("suit", ""))
	var rank_str = _format_rank(card_info.get("rank", 1))
	if is_current_reaction_slash:
		_play_dodge_response_ray(chosen_card, my_seat)

	if chosen_card.has_method("set_selected"):
		chosen_card.set_selected(false)
	_discard_player_card(chosen_card)
	selected_dodge_card_ui = null

	dodge_modal.visible = false
	is_waiting_dodge = false
	_set_reaction_hand_focus(false)
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

	if custom_reaction_callback.is_valid():
		var cb = custom_reaction_callback
		custom_reaction_callback = Callable()
		last_custom_reaction_card_info = card_info
		_animate_showcase_card(c_name, "Bạn dùng [%s %s %s]." % [suit_sym, rank_str, c_name], card_info)
		if DailyQuestSystem:
			if "trảm" in c_name.to_lower():
				DailyQuestSystem.record_progress("slash", 1)
			elif "đỡ" in c_name.to_lower():
				DailyQuestSystem.record_progress("dodge", 1)
			elif "diệu kế" in c_name.to_lower() or int(card_info.get("cat", -1)) in [2, 3]:
				DailyQuestSystem.record_progress("trick", 1)
		if AudioManager.has_voice(c_name):
			AudioManager.play_voice(c_name)
		elif not current_reaction_required_type.is_empty() and AudioManager.has_voice(current_reaction_required_type):
			AudioManager.play_voice(current_reaction_required_type)
		cb.call(true, card_info)
		return

	var card_id = card_info.get("id", c_name)
	if is_network_mode:
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		if current_server_phase == "AWAIT_DAN_CAU":
			NetworkClient.send_respond_action(true, str(card_id))
			_add_log("⚔️ Bạn dùng lá [%s %s %s] theo Dẫn Cầu. Đang chờ Server đồng bộ..." % [suit_sym, rank_str, c_name])
			_animate_showcase_card(c_name, "Bạn dùng [%s %s %s] đánh theo Dẫn Cầu." % [suit_sym, rank_str, c_name], card_info)
			return
		if current_server_phase == "AWAIT_DRUM_CHOICE":
			NetworkClient.send_respond_action(true, card_id)
			_add_log("🥁 Bạn chọn BỎ lá [%s] theo Điểm Trống." % c_name)
			_animate_showcase_card(c_name, "Bạn bỏ 1 lá theo Điểm Trống.", card_info)
			return
	_broadcast_player_battle_action("DODGE_RESPONSE", card_id, dodge_attacker_seat)

	var req_type = current_reaction_required_type
	var is_dieu_ke = req_type in ["Diệu Kế", "Diệu Kế Phá Mưu"] or "diệu kế" in c_name.to_lower()
	var is_tram_reaction = req_type == "Trảm" or is_giac_toi_reaction or "trảm" in c_name.to_lower()
	var is_discard_reaction = req_type in ["Bỏ bài", "Bài"]

	if is_dieu_ke:
		_animate_showcase_card(c_name, "Bạn dùng [%s %s %s] hóa giải mưu kế!" % [suit_sym, rank_str, c_name], card_info)
		_add_log("📜 Bạn đã dùng lá [%s %s %s] hóa giải mưu kế thành công!" % [suit_sym, rank_str, c_name])
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("trick", 1)
	elif is_tram_reaction:
		_animate_showcase_card(c_name, "Bạn dùng [%s %s %s] đáp trả đòn đánh!" % [suit_sym, rank_str, c_name], card_info)
		_add_log("⚔️ Bạn đã dùng lá [%s %s %s] đáp trả đòn đánh thành công!" % [suit_sym, rank_str, c_name])
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("slash", 1)
	elif is_discard_reaction:
		_animate_showcase_card(c_name, "Bạn bỏ [%s %s %s] hưởng ứng Hịch Tướng Sĩ." % [suit_sym, rank_str, c_name], card_info)
		_add_log("📣 Bạn đã bỏ lá [%s %s %s] hưởng ứng Hịch Tướng Sĩ!" % [suit_sym, rank_str, c_name])
	else:
		_animate_showcase_card(c_name, "Bạn dùng [%s %s %s] hóa giải đòn Trảm!" % [suit_sym, rank_str, c_name], card_info)
		_add_log("🛡️ Bạn đã tự chọn dùng lá [%s %s %s] hóa giải đòn Trảm thành công!" % [suit_sym, rank_str, c_name])
		if DailyQuestSystem:
			DailyQuestSystem.record_progress("dodge", 1)

	if AudioManager.has_voice(c_name):
		AudioManager.play_voice(c_name)
	elif not req_type.is_empty() and AudioManager.has_voice(req_type):
		AudioManager.play_voice(req_type)
	else:
		AudioManager.play_voice("Trảm" if is_giac_toi_reaction else "Đỡ")

	if is_tram_reaction:
		AudioManager.play_slash()
	else:
		AudioManager.play_parry()

	# Local mode resolves immediately; network mode waits for authoritative state.
	if not is_network_mode:
		_restore_truong_dao_slash_allowance(dodge_attacker_seat)
		await _resolve_local_song_cung_if_applicable(dodge_attacker_seat, my_seat, incoming_slash_damage, incoming_slash_element)
		_restore_turn_timer_to_attacker(dodge_attacker_seat, my_seat)

	if is_network_mode:
		return

func _on_dodge_passed() -> void:
	if is_network_mode and current_waiting_seat != my_seat:
		_close_dodge_reaction_state()
		return
	if is_network_mode and reaction_submission_pending:
		return
	if is_waiting_song_cung:
		_on_song_cung_passed()
		return
	if is_waiting_oai_nhuoc:
		var declined_nghia_tu := is_waiting_nghia_tu
		_close_oai_nhuoc_prompt()
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		NetworkClient.send_respond_action(false, "")
		_add_log("🛡️ Bạn từ chối [NGHĨA TỬ]." if declined_nghia_tu else "💥 [OAI NHƯỢC] Bạn chọn chịu sát thương của đòn Trảm. Đang chờ Server tính sát thương...")
		return
	if not is_waiting_dodge:
		return
	if selected_dodge_card_ui and is_instance_valid(selected_dodge_card_ui):
		if selected_dodge_card_ui.has_method("set_selected"):
			selected_dodge_card_ui.set_selected(false)
	selected_dodge_card_ui = null
	dodge_modal.visible = false
	is_waiting_dodge = false
	_set_reaction_hand_focus(false)
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

	if custom_reaction_callback.is_valid():
		var cb = custom_reaction_callback
		custom_reaction_callback = Callable()
		last_custom_reaction_card_info = {}
		cb.call(false, {})
		return

	if is_network_mode and current_server_phase == "AWAIT_DAN_CAU":
		NetworkClient.send_respond_action(false, "")
		_add_log("🌉 Bạn từ chối Trảm theo Dẫn Cầu, để Kiều Công Tiễn cướp 2 lá.")
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		return

	if is_network_mode and current_server_phase == "AWAIT_DRUM_CHOICE":
		NetworkClient.send_respond_action(false, "")
		_add_log("🥁 Bạn chọn LỘ TOÀN BỘ BÀI TRÊN TAY theo Điểm Trống.")
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		return

	_broadcast_player_battle_action("DODGE_RESPONSE", "pass", dodge_attacker_seat)
	if not is_network_mode:
		_apply_damage_to_general(my_seat, incoming_slash_damage, dodge_attacker_seat, incoming_slash_element)
	else:
		_add_log("💥 Bạn chấp nhận Chịu Đòn! Đang chờ Server tính sát thương...")

	if is_network_mode:
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
	else:
		_restore_turn_timer_to_attacker(dodge_attacker_seat, my_seat)

func _prompt_custom_reaction_async(title_text: String, desc_text_msg: String, required_type: String, pass_text: String, confirm_text: String, timeout_sec: float = 40.0) -> bool:
	if dodge_title_lbl and is_instance_valid(dodge_title_lbl):
		dodge_title_lbl.text = title_text
	dodge_desc_lbl.text = desc_text_msg
	dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)
	dodge_pass_btn.text = pass_text
	dodge_pass_btn.visible = true
	dodge_pass_btn.disabled = false
	dodge_confirm_btn.text = confirm_text
	dodge_confirm_btn.disabled = true
	dodge_confirm_btn.modulate = Color(0.55, 0.58, 0.64, 0.78)
	current_reaction_pass_text = pass_text
	current_reaction_confirm_prefix = ""
	current_reaction_required_type = required_type
	current_reaction_allow_dodge_as_slash = true

	dodge_time_left = timeout_sec
	is_waiting_dodge = true
	selected_dodge_card_ui = null

	# Đếm 40s trên đầu người phản ứng (bạn)
	if generals_data.has(my_seat) and generals_data[my_seat].has("avatar_node") and is_instance_valid(generals_data[my_seat]["avatar_node"]):
		generals_data[my_seat]["avatar_node"].set_turn_active(true)
		generals_data[my_seat]["avatar_node"].update_turn_timer(int(timeout_sec))

	var my_gen = generals_data.get(my_seat, {})
	dodge_card_selector_scroll.visible = false
	_set_reaction_hand_focus(true, required_type, 0, current_reaction_allow_dodge_as_slash, false)
	_select_dodge_card(null)
	# Keep the confirm button visibly inactive until a valid reaction card is selected.
	if required_type == "Đỡ" and _get_valid_dodge_cards(0, false).is_empty():
		dodge_confirm_btn.disabled = true
		dodge_confirm_btn.modulate = Color(0.55, 0.58, 0.64, 0.78)

	var failed_km_custom = false
	if is_network_mode:
		var last_state_dict = NetworkClient.last_state if NetworkClient else {}
		var active_c = last_state_dict.get("activeCard", {}) if last_state_dict is Dictionary else {}
		if active_c is Dictionary:
			var failed_seats = active_c.get("khienMayFailedSeats", [])
			if failed_seats is Array and my_seat in failed_seats:
				failed_km_custom = true

	var has_khien_may_custom = (required_type == "Đỡ" and "Khiên Mây" in str(my_gen.get("equipped_armor", "")) and not failed_km_custom)
	if dodge_khien_may_btn:
		if has_khien_may_custom:
			dodge_khien_may_btn.visible = true
			dodge_khien_may_btn.disabled = false
			dodge_khien_may_btn.text = "🎲 LẬT KHIÊN MÂY (ĐỎ = ĐỠ)"
		else:
			dodge_khien_may_btn.visible = false

	dodge_modal.visible = true

	custom_reaction_callback = func(accepted: bool, _card_info: Dictionary):
		custom_reaction_finished.emit(accepted)

	var accepted_res = await custom_reaction_finished
	return accepted_res

func _calculate_distance(seat_a: int, seat_b: int) -> int:
	if seat_a == seat_b:
		return 0
	var living_seats: Array[int] = []
	for seat in range(1, battle_seat_count + 1):
		if generals_data.has(seat) and generals_data[seat].get("is_alive", true) and generals_data[seat].get("hp", 0) > 0:
			living_seats.append(seat)
	var from_index = living_seats.find(seat_a)
	var to_index = living_seats.find(seat_b)
	if from_index < 0 or to_index < 0 or living_seats.size() <= 1:
		return 999
	var diff = abs(from_index - to_index)
	var d = min(diff, living_seats.size() - diff)
	if generals_data.has(seat_a) and generals_data[seat_a].get("equipped_off_horse", "") != "":
		d -= 1
	if generals_data.has(seat_b) and generals_data[seat_b].get("equipped_def_horse", "") != "":
		d += 1
	# Cố Thủ increases the defensive distance while the target is wearing armor.
	if generals_data.has(seat_b) \
		and _hero_has_skill(generals_data[seat_b], "co_thu") \
		and str(generals_data[seat_b].get("equipped_armor", "")) != "":
		d += 1
	if generals_data.has(seat_a) and _hero_has_skill(generals_data[seat_a], "xa_thuan"):
		d -= 2
	return max(1, d)

func _get_attack_range(seat_num: int) -> int:
	if not generals_data.has(seat_num):
		return 1
	var general = generals_data[seat_num]
	if _hero_has_skill(general, "no_dinh") and int(general.get("hp", 0)) <= 2:
		return 999
	var weapon_names = str(general.get("equipped_weapon", "")).split(" + ", false)
	var base_range = 1
	if _hero_has_skill(general, "luc_dich") and weapon_names.size() > 1:
		base_range = 0
		for weapon_name in weapon_names:
			base_range += _get_weapon_range(str(weapon_name))
	elif not weapon_names.is_empty():
		base_range = _get_weapon_range(str(weapon_names[0]))
	return base_range + (1 if int(generals_data[seat_num].get("suc_soi_turns_remaining", 0)) > 0 else 0)

func _get_weapon_range(weapon_name: String) -> int:
	if "Súng Thần Công" in weapon_name: return 5
	if "Thương Ngâu" in weapon_name or "Hỏa Mai" in weapon_name: return 4
	if "Trường Đao" in weapon_name: return 3
	if "Liêm Đao" in weapon_name or "Đoản Đao" in weapon_name or "Kiếm Thuận Thiên" in weapon_name or "Song Cung" in weapon_name: return 2
	return 1

func _get_suit_icon(_suit: String) -> String:
	# Game Việt Nam: Không sử dụng 4 chất bài tây (♥ ♦ ♣ ♠)
	return ""

func _get_card_color(suit: String) -> String:
	var s = suit.to_lower()
	if s in ["heart", "co", "cơ", "đỏ", "do", "red", "♥"]: return "RED"
	if s in ["diamond", "ro", "rô", "trắng", "trang", "white", "♦"]: return "WHITE"
	if s in ["club", "chuon", "chuồn", "tep", "tép", "vàng", "vang", "yellow", "♣"]: return "YELLOW"
	if s in ["spade", "bich", "bích", "đen", "den", "black", "♠"]: return "BLACK"
	return ""

func _get_suit_name(suit: String) -> String:
	var s = suit.to_lower()
	if s in ["heart", "co", "cơ", "đỏ", "do", "red", "♥"]: return "Đỏ"
	if s in ["diamond", "ro", "rô", "trắng", "trang", "white", "♦"]: return "Trắng"
	if s in ["club", "chuon", "chuồn", "tep", "tép", "vàng", "vang", "yellow", "♣"]: return "Vàng"
	if s in ["spade", "bich", "bích", "đen", "den", "black", "♠"]: return "Đen"
	return ""

func _is_same_card_color(first_suit: String, second_suit: String) -> bool:
	var c1 = _get_card_color(first_suit)
	var c2 = _get_card_color(second_suit)
	return not c1.is_empty() and c1 == c2

func _format_rank(r: Variant) -> String:
	var val = int(r)
	match val:
		1: return "A"
		11: return "J"
		12: return "Q"
		13: return "K"
		_: return str(val)

var _damage_vignette: ColorRect = null
var _battlefield_shake_tween: Tween = null

func _shake_battlefield(intensity: float = 8.0) -> void:
	var table = get_node_or_null("TableTop")
	if not table or not is_instance_valid(table):
		return
	if _battlefield_shake_tween and _battlefield_shake_tween.is_valid():
		_battlefield_shake_tween.kill()
	table.position = Vector2.ZERO
	var orig_pos = Vector2.ZERO
	_battlefield_shake_tween = create_tween()
	_battlefield_shake_tween.tween_property(table, "position", orig_pos + Vector2(-intensity, intensity * 0.7), 0.04)
	_battlefield_shake_tween.tween_property(table, "position", orig_pos + Vector2(intensity * 0.8, -intensity), 0.04)
	_battlefield_shake_tween.tween_property(table, "position", orig_pos + Vector2(-intensity * 0.5, intensity * 0.4), 0.04)
	_battlefield_shake_tween.tween_property(table, "position", orig_pos + Vector2(intensity * 0.3, -intensity * 0.2), 0.04)
	_battlefield_shake_tween.tween_property(table, "position", orig_pos, 0.04)
	_battlefield_shake_tween.tween_callback(func(): _battlefield_shake_tween = null)

func _flash_screen_damage_vignette() -> void:
	if not _damage_vignette or not is_instance_valid(_damage_vignette):
		_damage_vignette = ColorRect.new()
		_damage_vignette.set_anchors_preset(PRESET_FULL_RECT)
		_damage_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_damage_vignette.color = Color(0.85, 0.05, 0.05, 0.0)
		_damage_vignette.z_index = 85
		add_child(_damage_vignette)

	var tw = create_tween()
	tw.tween_property(_damage_vignette, "color:a", 0.45, 0.05)
	tw.tween_property(_damage_vignette, "color:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _canonical_damage_element(damage_element: String) -> String:
	return "WATER" if damage_element.to_upper() == "LIGHTNING" else damage_element.to_upper()

func _trigger_damage_effects(target_seat: int, amount: int, damage_element: String = "NORMAL") -> void:
	if not generals_data.has(target_seat):
		return
	damage_element = _canonical_damage_element(damage_element)
	var tgt = generals_data[target_seat]
	if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
		tgt["avatar_node"].play_damage_effect(damage_element)
		tgt["avatar_node"].spawn_damage_number(amount, damage_element)

	AudioManager.play_damage()
	AudioManager.play_slash()

	# Rung lắc bàn cờ (bản thân chịu đòn rung mạnh 18px, đối thủ rung 8px)
	_shake_battlefield(18.0 if target_seat == my_seat else 8.0)

	# Nếu bản thân bị mất máu: chớp đỏ toàn màn hình báo động
	if target_seat == my_seat:
		_flash_screen_damage_vignette()

func _play_armor_effect(target_seat: int, armor_name: String, success: bool = true, charges_left: int = -1) -> void:
	if not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	var avatar = tgt.get("avatar_node")
	if avatar and is_instance_valid(avatar) and avatar.has_method("play_armor_effect"):
		avatar.play_armor_effect(armor_name, success, charges_left)
	# Showcase bài trung tâm màn hình để mọi người chơi đều thấy rõ giáp kích hoạt
	if "Giáp Đồng" in armor_name:
		_animate_showcase_card("Giáp Đồng Sơn Vi", "🛡️ [Giáp Đồng Sơn Vi] của %s đã vô hiệu hóa đòn Trảm Thường!" % tgt["name"])
	elif "Áo Bào" in armor_name:
		var charges_msg = " (Còn %d lần)" % charges_left if charges_left >= 0 else ""
		_animate_showcase_card("Áo Bào Hoàng Tộc", "🛡️ [Áo Bào Hoàng Tộc] của %s chặn sát thương%s!" % [tgt["name"], charges_msg])
	elif "Khiên Mây" in armor_name:
		if success:
			_animate_showcase_card("Khiên Mây Bện", "🛡️ [Khiên Mây Bện] của %s lật ĐỎ -> Tự động Đỡ thành công!" % tgt["name"])
		else:
			_animate_showcase_card("Khiên Mây Bện", "🛡️ [Khiên Mây Bện] của %s lật ĐEN -> Phán xét thất bại!" % tgt["name"])

func _apply_damage_to_general(target_seat: int, amount: int, attacker_seat: int = -1, damage_element: String = "NORMAL") -> void:
	if not generals_data.has(target_seat):
		return
	damage_element = _canonical_damage_element(damage_element)
	var tgt = generals_data[target_seat]
	var atk = generals_data.get(attacker_seat, {})
	var has_thuan_thien = _has_equipped_weapon_name(atk, "Kiếm Thuận Thiên")

	# Áo Bào hấp thụ tối đa hai điểm sát thương trước khi bị hủy.
	if not has_thuan_thien and "Áo Bào" in tgt.get("equipped_armor", ""):
		tgt["ao_bao_charges"] = tgt.get("ao_bao_charges", 2)
		if tgt["ao_bao_charges"] > 0:
			var absorbed_damage: int = mini(amount, int(tgt["ao_bao_charges"]))
			tgt["ao_bao_charges"] -= absorbed_damage
			amount -= absorbed_damage
			_play_armor_effect(target_seat, "Áo Bào Hoàng Tộc", true, tgt["ao_bao_charges"])
			AudioManager.play_voice("Áo Bào Hoàng Tộc")
			_add_log("🛡️ [Áo Bào Hoàng Tộc] của %s chặn %d sát thương (Còn %d điểm)." % [tgt["name"], absorbed_damage, tgt["ao_bao_charges"]])
			if tgt["ao_bao_charges"] <= 0:
				tgt["equipped_armor"] = ""
				tgt["avatar_node"].set_equipment("armor", "", "")
				_add_log("🛡️ [Áo Bào Hoàng Tộc] của %s đã hết linh lực và tan biến!" % tgt["name"])

	# Kiểm tra Thương Ngâu Lãng Bạc của người đánh
	if amount > 0 and _has_equipped_weapon_name(atk, "Thương Ngâu Lãng Bạc"):
		tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
		tgt["avatar_node"].update_hand_count(tgt["hand_count"])
		_add_log("🗡️ [Thương Ngâu Lãng Bạc] của %s phá hủy 1 lá bài của %s!" % [atk.get("name", "Người đánh"), tgt["name"]])

	tgt["hp"] = max(0, tgt["hp"] - amount)
	if amount > 0:
		_trigger_damage_effects(target_seat, amount, damage_element)
		if attacker_seat == current_turn_seat and attacker_seat != target_seat:
			local_turn_dealt_damage = true
	tgt["avatar_node"].update_hp(tgt["hp"], tgt["max_hp"])

	_add_log("💥 %s nhận %d sát thương! Còn (%d/%d) Máu." % [tgt["name"], amount, tgt["hp"], tgt["max_hp"]])

	# Lan truyền Xích Liên Hoàn nếu là sát thương Thủy hoặc Hỏa.
	var is_elemental = (damage_element == "FIRE" or damage_element == "WATER")
	if is_elemental and tgt.get("is_chained", false) and amount > 0:
		tgt["is_chained"] = false
		if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
			tgt["avatar_node"].set_chained(false)
		# Lan theo vòng chơi, bắt đầu từ người kế tiếp người nhận sát thương.
		for step in range(1, 4):
			var other_seat = ((target_seat - 1 + step) % battle_seat_count) + 1
			if not generals_data.has(other_seat):
				continue
			var other = generals_data[other_seat]
			if other["is_alive"] and other.get("is_chained", false):
				other["is_chained"] = false
				if other.has("avatar_node") and is_instance_valid(other["avatar_node"]):
					other["avatar_node"].set_chained(false)
				_add_log("⛓️🌊 [XÍCH LIÊN HOÀN]: Sát thương %s (%d điểm) lan truyền sang %s và gỡ xích!" % ["Hỏa" if damage_element == "FIRE" else "Thủy", amount, other["name"]])
				_apply_damage_to_general(other_seat, amount, -1, damage_element)

	if tgt["hp"] <= 0:
		if amount > 0 and _hero_has_skill(tgt, "hich_nghia"):
			for _draw_index in range(3):
				var hich_card = _draw_card_from_pile()
				if target_seat == my_seat:
					_add_card_to_player_hand(hich_card)
				else:
					tgt["hand_cards"].append(hich_card)
					tgt["hand_count"] = tgt["hand_cards"].size()
					_animate_draw_to_seat(target_seat)
			if target_seat != my_seat:
				tgt["avatar_node"].update_hand_count(tgt["hand_count"])
			_add_log("✨ [HỊCH NGHĨA] %s rơi vào Cận Tử, rút 3 lá bài!" % tgt["name"])
		_prompt_near_death_check(target_seat)
	else:
		_check_victory_condition()

func _prompt_near_death_check(victim_seat: int) -> void:
	if not generals_data.has(victim_seat):
		return
	var victim = generals_data[victim_seat]
	if not victim["is_alive"]:
		return

	near_death_victim_seat = victim_seat
	near_death_asker_queue.clear()
	var start_seat = current_turn_seat if current_turn_seat > 0 else my_seat
	for offset in range(battle_seat_count):
		var asker_seat = ((start_seat - 1 + offset) % battle_seat_count) + 1
		if not generals_data.has(asker_seat):
			continue
		var asker = generals_data[asker_seat]
		if asker.get("is_alive", false) or asker_seat == victim_seat:
			near_death_asker_queue.append(asker_seat)

	_add_log("🚨 CẬN TỬ: %s đang cận tử (%d Máu)! Hỏi cứu lần lượt từng ghế." % [victim["name"], victim["hp"]])
	if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
		victim["avatar_node"].set_near_death(true)
	_advance_near_death_rescue()

func _advance_near_death_rescue() -> void:
	if near_death_victim_seat <= 0 or not generals_data.has(near_death_victim_seat):
		return
	var victim_seat = near_death_victim_seat
	var victim = generals_data[victim_seat]
	if victim.get("hp", 0) > 0:
		if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
			victim["avatar_node"].set_near_death(false)
		near_death_asker_queue.clear()
		near_death_victim_seat = -1
		if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
			victim["avatar_node"].set_near_death(false)
		_check_victory_condition()
		return

	if near_death_asker_queue.is_empty():
		if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
			victim["avatar_node"].set_near_death(false)
		near_death_victim_seat = -1
		_handle_general_death(victim_seat)
		_check_victory_condition()
		return

	var asker_seat = int(near_death_asker_queue.pop_front())
	if not generals_data.has(asker_seat):
		_advance_near_death_rescue()
		return
	var asker = generals_data[asker_seat]
	if not asker.get("is_alive", false) and asker_seat != victim_seat:
		_advance_near_death_rescue()
		return
	if asker_seat != victim_seat and asker.get("isDragon", false) != victim.get("isDragon", false):
		_advance_near_death_rescue()
		return

	_add_log("🆘 Đang hỏi Ghế %d (%s) cứu %s." % [asker_seat, asker["name"], victim["name"]])
	if asker_seat == my_seat:
		_prompt_rescue_reaction(victim_seat)
		return

	var rescue_idx = -1
	var rescue_name = ""
	for idx in range(asker.get("hand_cards", []).size()):
		var card = asker["hand_cards"][idx]
		var card_name = card.get("name", "")
		if card_name == "Bánh Chưng" or (card_name == "Hủ Rượu" and asker_seat == victim_seat):
			rescue_idx = idx
			rescue_name = card_name
			break

	if rescue_idx >= 0:
		var rescue_card = asker["hand_cards"].pop_at(rescue_idx)
		asker["hand_count"] = asker["hand_cards"].size()
		asker["avatar_node"].update_hand_count(asker["hand_count"])
		victim["hp"] = min(victim["max_hp"], victim["hp"] + 1)
		victim["avatar_node"].update_hp(victim["hp"], victim["max_hp"])
		_animate_showcase_card(rescue_name, "%s dùng [%s] cứu sống %s!" % [asker["name"], rescue_name, victim["name"]], rescue_card)
		_add_log("💮 %s đã dùng [%s] cứu sống %s thoát khỏi Cận Tử (%d/%d Máu)!" % [asker["name"], rescue_name, victim["name"], victim["hp"], victim["max_hp"]])
		AudioManager.play_voice(rescue_name)
		AudioManager.play_skill()
		near_death_asker_queue.clear()
		near_death_victim_seat = -1
		if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
			victim["avatar_node"].set_near_death(false)
		_check_victory_condition()
		return

	_add_log("⏭️ Ghế %d (%s) không dùng lá cứu." % [asker_seat, asker["name"]])
	_advance_near_death_rescue()

func _on_rescue_confirmed() -> void:
	if not is_waiting_rescue or not generals_data.has(rescue_victim_seat):
		return
	if not rescue_card_to_use or not is_instance_valid(rescue_card_to_use):
		desc_text.text = "⚠️ Vui lòng chọn 1 lá bài cứu trước khi bấm xác nhận!"
		return
	var chosen_card = rescue_card_to_use
	var victim_seat = rescue_victim_seat
	_close_rescue_modal()

	var victim = generals_data[victim_seat]
	var info = _get_card_info_from_ui(chosen_card)
	var c_name = info.get("name", "Bánh Chưng")
	var c_id = info.get("id", c_name)
	_discard_player_card(chosen_card)
	if is_network_mode:
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
	_broadcast_player_battle_action("RESCUE_RESPONSE", c_id, victim_seat)
	_animate_showcase_card(c_name, "Bạn cứu sống %s (+1 Máu)!" % victim["name"], info)
	_add_log("💮 Bạn dùng [%s] cứu sống %s!" % [c_name, victim["name"]])
	if c_name == "Bánh Chưng" and DailyQuestSystem:
		DailyQuestSystem.record_progress("heal", 1)
	AudioManager.play_voice(c_name)
	AudioManager.play_skill()
	victim["hp"] = min(victim["max_hp"], victim["hp"] + 1)
	if victim.has("avatar_node") and is_instance_valid(victim["avatar_node"]):
		victim["avatar_node"].update_hp(victim["hp"], victim["max_hp"])
	if is_network_mode:
		return
	near_death_asker_queue.clear()
	near_death_victim_seat = -1

	if victim["hp"] <= 0:
		_advance_near_death_rescue()
	else:
		_check_victory_condition()

func _on_rescue_passed() -> void:
	if not is_waiting_rescue:
		return
	var victim_seat = rescue_victim_seat
	_close_rescue_modal()
	_broadcast_player_battle_action("RESCUE_RESPONSE", "pass", victim_seat)
	if not is_network_mode:
		_advance_near_death_rescue()

func _handle_general_death(seat_num: int) -> void:
	var g = generals_data[seat_num]
	g["is_alive"] = false
	if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
		g["avatar_node"].set_near_death(false)
		g["avatar_node"].set_defeated(true)
	_add_log("☠️ Tướng %s (Ghế %d) đã ngã xuống trên chiến trường!" % [g["name"], seat_num])
	# In local 2v2 games, the surviving teammate draws one card after the death.
	if not is_network_mode and battle_seat_count == 4:
		for teammate_seat in range(1, battle_seat_count + 1):
			if teammate_seat == seat_num or not generals_data.has(teammate_seat):
				continue
			var teammate = generals_data[teammate_seat]
			if not teammate.get("is_alive", false) or teammate.get("isDragon", false) != g.get("isDragon", false):
				continue
			var death_draw = _draw_card_from_pile()
			if teammate_seat == my_seat:
				_add_card_to_player_hand(death_draw)
			else:
				teammate["hand_cards"].append(death_draw)
				teammate["hand_count"] = teammate["hand_cards"].size()
				if teammate.has("avatar_node") and is_instance_valid(teammate["avatar_node"]):
					teammate["avatar_node"].update_hand_count(teammate["hand_count"])
			_animate_draw_to_seat(teammate_seat)
			_add_log("🃏 %s rút 1 lá vì đồng đội %s đã tử trận." % [teammate["name"], g["name"]])
			break

	if not is_network_mode and _hero_has_skill(g, "uat_khi"):
		if seat_num == my_seat:
			_begin_uat_khi_prompt()
			desc_text.text = "💢 [UẤT KHÍ] Chọn người còn sống (tối đa 2 người) để hồi 1 máu và rút 2 lá."
		else:
			var chosen_seats = _choose_ai_uat_khi_targets(seat_num)
			for c_seat in chosen_seats:
				if generals_data.has(c_seat):
					var c_gen = generals_data[c_seat]
					var max_hp = int(c_gen.get("max_hp", 3))
					c_gen["hp"] = min(max_hp, int(c_gen.get("hp", 1)) + 1)
					if c_gen.has("avatar_node") and is_instance_valid(c_gen["avatar_node"]):
						c_gen["avatar_node"].update_hp(c_gen["hp"], max_hp)
					for _d in range(2):
						var drawn = _draw_card_from_pile()
						if c_seat == my_seat:
							_add_card_to_player_hand(drawn)
						else:
							c_gen["hand_cards"].append(drawn)
							c_gen["hand_count"] = c_gen["hand_cards"].size()
							if c_gen.has("avatar_node") and is_instance_valid(c_gen["avatar_node"]):
								c_gen["avatar_node"].update_hand_count(c_gen["hand_count"])
						_animate_draw_to_seat(c_seat)
					_add_log("💢 [UẤT KHÍ] %s chọn %s: hồi 1 máu và rút 2 lá." % [g["name"], c_gen["name"]])
			var dead_avatar = g.get("avatar_node")
			if is_instance_valid(dead_avatar) and dead_avatar.has_method("show_skill_banner"):
				dead_avatar.show_skill_banner("UẤT KHÍ", 2.0, true)
			AudioManager.play_voice("Uất Khí")
			AudioManager.play_skill()

	if seat_num == my_seat and not uat_khi_pending:
		_show_dead_player_exit()

func _show_dead_player_exit() -> void:
	if exit_battle_btn and is_instance_valid(exit_battle_btn):
		return
	_clear_normal_hand_selection()
	for child in hand_container.get_children():
		child.queue_free()
	card_play_btn.visible = false
	end_turn_btn.visible = false
	hich_recast_btn.visible = false
	desc_text.text = "☠️ Bạn đã Tử trận. Trận đấu vẫn tiếp tục cho đến khi có kết quả."
	exit_battle_btn = Button.new()
	exit_battle_btn.text = "🚪 THOÁT TRẬN"
	exit_battle_btn.custom_minimum_size = Vector2(230, 54)
	exit_battle_btn.position = Vector2(285, 52)
	exit_battle_btn.focus_mode = Control.FOCUS_NONE
	exit_battle_btn.add_theme_font_size_override("font_size", 16)
	exit_battle_btn.pressed.connect(_on_exit_battle_clicked)
	hand_container.add_child(exit_battle_btn)

func _on_exit_battle_clicked() -> void:
	# Giữ kết nối để nhận trạng thái FINISHED và hiển thị kết quả tua nhanh.
	if exit_battle_btn and is_instance_valid(exit_battle_btn):
		exit_battle_btn.disabled = true
		exit_battle_btn.text = "⏩ ĐANG TUA NHANH..."
	desc_text.text = "⏩ Bạn đã thoát lượt điều khiển. Đang chờ các AI kết thúc trận đấu..."
	if NetworkClient and NetworkClient.is_connected_to_server:
		NetworkClient.send_fast_forward_match()

func _check_victory_condition() -> void:
	var dragon_alive = 0
	var phoenix_alive = 0

	for s_num in range(1, battle_seat_count + 1):
		var g = generals_data[s_num]
		if g["is_alive"]:
			if g["isDragon"]:
				dragon_alive += 1
			else:
				phoenix_alive += 1

	if dragon_alive == 0 or phoenix_alive == 0:
		is_game_over = true
		var player_won = (my_team_is_dragon and phoenix_alive == 0) or (not my_team_is_dragon and dragon_alive == 0)
		_show_victory_defeat_modal(player_won)

func _show_victory_defeat_modal(is_win: bool) -> void:
	if not victory_defeat_modal:
		return
	if match_result_recorded:
		victory_defeat_modal.visible = true
		return
	match_result_recorded = true

	victory_defeat_modal.visible = true

	# 1. Lấy dữ liệu Rank, Số Sao, Điểm Tích Lũy hiện tại của người chơi
	var cur_rank_idx = 0
	var cur_stars = 0
	var cur_acc = 0
	if AuthManager:
		cur_rank_idx = AuthManager.current_2v2_rank_index
		cur_stars = AuthManager.current_2v2_stars
		cur_acc = AuthManager.current_2v2_accumulation_points

	# 2. Xử lý tăng giảm sao và điểm tích lũy theo RankSystem
	var res = RankSystem.process_match_result(is_win, cur_rank_idx, cur_stars, cur_acc)

	# 3. Cập nhật và lưu ngay lập tức vào AuthManager
	if DailyQuestSystem:
		DailyQuestSystem.record_progress("battle", 1)
		if is_win:
			DailyQuestSystem.record_progress("win", 1)

	var exp_result: Dictionary = {}
	if AuthManager:
		AuthManager.current_2v2_rank_index = res["rank_index"]
		AuthManager.current_2v2_stars = res["stars"]
		AuthManager.current_2v2_accumulation_points = res["accumulation_points"]
		if is_win:
			AuthManager.current_wins += 1
		else:
			AuthManager.current_losses += 1
		var exp_gain: int = 20 if is_win else 12
		if AuthManager.has_method("add_exp"):
			exp_result = AuthManager.add_exp(exp_gain)
		else:
			AuthManager.current_exp += exp_gain
		AuthManager.current_silver += 300 if is_win else 100
		AuthManager.save_profile_to_appwrite()

	# 4. Tái cấu trúc Box hiển thị Thông báo cuối trận
	var box = victory_defeat_modal.get_node_or_null("Dim/Box") as PanelContainer
	if not box:
		return

	box.custom_minimum_size = Vector2(580, 480)
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.06, 0.08, 0.14, 0.98)
	box_style.border_width_left = 2
	box_style.border_width_top = 2
	box_style.border_width_right = 2
	box_style.border_width_bottom = 2
	box_style.border_color = Color(0.95, 0.78, 0.25, 1.0) if is_win else Color(0.75, 0.25, 0.25, 1.0)
	box_style.corner_radius_top_left = 16
	box_style.corner_radius_top_right = 16
	box_style.corner_radius_bottom_right = 16
	box_style.corner_radius_bottom_left = 16
	box_style.shadow_color = Color(0, 0, 0, 0.7)
	box_style.shadow_size = 12
	box_style.shadow_offset = Vector2(0, 4)
	box.add_theme_stylebox_override("panel", box_style)

	var vbox = victory_defeat_modal.get_node_or_null("Dim/Box/Margin/VBox") as VBoxContainer
	if not vbox:
		return

	# Xóa các con cũ để xây dựng giao diện động mới hoàn toàn
	for ch in vbox.get_children():
		ch.queue_free()

	vbox.add_theme_constant_override("separation", 10)

	# --- A. TIÊU ĐỀ KẾT QUẢ TRẬN ĐẤU ---
	var header_vbox = VBoxContainer.new()
	header_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_vbox.add_theme_constant_override("separation", 2)
	vbox.add_child(header_vbox)

	var title_lbl = Label.new()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.text = "🎉 CHIẾN THẮNG HUY HOÀNG!" if is_win else "💀 CHIẾN BẠI SA TRƯỜNG!"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0) if is_win else Color(0.95, 0.35, 0.35, 1.0))
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	header_vbox.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.text = "Đại phá phòng tuyến đối phương • Khắc ghi chiến công!" if is_win else "Toàn quân lui binh • Tu dưỡng thao lược chờ ngày phục thù!"
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.90, 0.9))
	header_vbox.add_child(sub_lbl)

	# --- B. KHUNG THÔNG TIN RANK & SAO & ĐIỂM TÍCH LŨY ---
	var card_panel = PanelContainer.new()
	var cp_style = StyleBoxFlat.new()
	cp_style.bg_color = Color(0.04, 0.06, 0.10, 0.9)
	cp_style.border_width_left = 1
	cp_style.border_width_top = 1
	cp_style.border_width_right = 1
	cp_style.border_width_bottom = 1
	cp_style.border_color = Color(0.4, 0.5, 0.7, 0.5)
	cp_style.corner_radius_top_left = 12
	cp_style.corner_radius_top_right = 12
	cp_style.corner_radius_bottom_right = 12
	cp_style.corner_radius_bottom_left = 12
	card_panel.add_theme_stylebox_override("panel", cp_style)
	vbox.add_child(card_panel)

	var card_margin = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card_panel.add_child(card_margin)

	var card_hbox = HBoxContainer.new()
	card_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_hbox.add_theme_constant_override("separation", 24)
	card_margin.add_child(card_hbox)

	# 1. Cột trái: Huy hiệu Rank
	var badge_col = VBoxContainer.new()
	badge_col.alignment = BoxContainer.ALIGNMENT_CENTER
	badge_col.custom_minimum_size = Vector2(130, 0)
	badge_col.add_theme_constant_override("separation", 4)
	card_hbox.add_child(badge_col)

	var badge_rect = TextureRect.new()
	badge_rect.custom_minimum_size = Vector2(96, 96)
	badge_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge_rect.pivot_offset = Vector2(48, 48)
	badge_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var initial_icon_path = RankSystem.get_rank_icon_path(res["old_rank_idx"])
	if ResourceLoader.exists(initial_icon_path):
		badge_rect.texture = load(initial_icon_path)
	badge_col.add_child(badge_rect)

	var rank_name_lbl = Label.new()
	rank_name_lbl.text = RankSystem.get_rank_name(res["old_rank_idx"]).to_upper()
	rank_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_name_lbl.add_theme_font_size_override("font_size", 15)
	var rank_color = RankSystem.get_rank_info(res["old_rank_idx"]).get("color", Color(1.0, 0.85, 0.4))
	rank_name_lbl.add_theme_color_override("font_color", rank_color)
	badge_col.add_child(rank_name_lbl)

	# Đường phân cách dọc
	var card_sep = VSeparator.new()
	var cs_style = StyleBoxLine.new()
	cs_style.color = Color(0.3, 0.4, 0.55, 0.3)
	cs_style.vertical = true
	card_sep.add_theme_stylebox_override("separator", cs_style)
	card_hbox.add_child(card_sep)

	# 2. Cột phải: Dải Sao & Thanh Điểm Tích Lũy
	var info_col = VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.alignment = BoxContainer.ALIGNMENT_CENTER
	info_col.add_theme_constant_override("separation", 10)
	card_hbox.add_child(info_col)

	# --- Dải Sao ---
	var star_section = VBoxContainer.new()
	star_section.add_theme_constant_override("separation", 2)
	info_col.add_child(star_section)

	var star_header = HBoxContainer.new()
	var star_title = Label.new()
	star_title.text = "Số sao xếp hạng:"
	star_title.add_theme_font_size_override("font_size", 13)
	star_title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	star_header.add_child(star_title)

	var star_tag = Label.new()
	star_tag.text = " +1 ★" if is_win else " -1 ★"
	star_tag.add_theme_font_size_override("font_size", 13)
	star_tag.add_theme_color_override("font_color", Color(0.35, 0.95, 0.45) if is_win else Color(1.0, 0.35, 0.35))
	star_header.add_child(star_tag)
	star_section.add_child(star_header)

	var stars_hbox = HBoxContainer.new()
	stars_hbox.add_theme_constant_override("separation", 6)
	star_section.add_child(stars_hbox)

	var star_nodes: Array = []
	for s in range(5):
		var star_lbl = Label.new()
		star_lbl.text = "★"
		star_lbl.add_theme_font_size_override("font_size", 24)
		star_lbl.pivot_offset = Vector2(12, 14)
		if s < res["old_stars"]:
			star_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
			star_lbl.add_theme_color_override("font_shadow_color", Color(0.9, 0.6, 0.1, 0.7))
		else:
			star_lbl.add_theme_color_override("font_color", Color(0.25, 0.28, 0.38, 0.8))
		stars_hbox.add_child(star_lbl)
		star_nodes.append(star_lbl)

	var star_count_lbl = Label.new()
	star_count_lbl.text = " %d/5 Sao" % res["old_stars"]
	star_count_lbl.add_theme_font_size_override("font_size", 12)
	star_count_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	stars_hbox.add_child(star_count_lbl)

	# --- Thanh Điểm Tích Lũy ---
	var acc_section = VBoxContainer.new()
	acc_section.add_theme_constant_override("separation", 4)
	info_col.add_child(acc_section)

	var acc_header = HBoxContainer.new()
	var acc_title = Label.new()
	acc_title.text = "Điểm tích lũy dũng cảm:"
	acc_title.add_theme_font_size_override("font_size", 13)
	acc_title.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	acc_header.add_child(acc_title)

	var acc_delta_lbl = Label.new()
	acc_delta_lbl.text = " +25đ" if is_win else " +10đ"
	acc_delta_lbl.add_theme_font_size_override("font_size", 13)
	acc_delta_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0) if is_win else Color(0.95, 0.75, 0.2))
	acc_header.add_child(acc_delta_lbl)
	acc_section.add_child(acc_header)

	var acc_bar = ProgressBar.new()
	acc_bar.custom_minimum_size = Vector2(0, 14)
	acc_bar.max_value = 100
	acc_bar.value = res["old_acc_points"]
	acc_bar.show_percentage = false
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.1, 0.13, 0.2, 0.9)
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_right = 6
	bar_bg.corner_radius_bottom_left = 6
	var bar_fg = StyleBoxFlat.new()
	bar_fg.bg_color = Color(0.2, 0.75, 0.95, 1.0)
	bar_fg.corner_radius_top_left = 6
	bar_fg.corner_radius_top_right = 6
	bar_fg.corner_radius_bottom_right = 6
	bar_fg.corner_radius_bottom_left = 6
	acc_bar.add_theme_stylebox_override("background", bar_bg)
	acc_bar.add_theme_stylebox_override("fill", bar_fg)
	acc_section.add_child(acc_bar)

	var acc_text_lbl = Label.new()
	acc_text_lbl.text = "%d/100 Điểm (Đủ 100đ đổi +1★)" % res["old_acc_points"]
	acc_text_lbl.add_theme_font_size_override("font_size", 11)
	acc_text_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	acc_section.add_child(acc_text_lbl)

	# --- C. BANNER THĂNG HẠNG (PROMOTION) ---
	var promo_panel = PanelContainer.new()
	promo_panel.visible = false
	promo_panel.pivot_offset = Vector2(250, 18)
	var pp_style = StyleBoxFlat.new()
	pp_style.bg_color = Color(0.35, 0.22, 0.05, 0.95)
	pp_style.border_width_left = 2
	pp_style.border_width_top = 2
	pp_style.border_width_right = 2
	pp_style.border_width_bottom = 2
	pp_style.border_color = Color(1.0, 0.9, 0.35, 1.0)
	pp_style.corner_radius_top_left = 10
	pp_style.corner_radius_top_right = 10
	pp_style.corner_radius_bottom_right = 10
	pp_style.corner_radius_bottom_left = 10
	promo_panel.add_theme_stylebox_override("panel", pp_style)
	vbox.add_child(promo_panel)

	var promo_margin = MarginContainer.new()
	promo_margin.add_theme_constant_override("margin_top", 6)
	promo_margin.add_theme_constant_override("margin_bottom", 6)
	promo_panel.add_child(promo_margin)

	var promo_lbl = Label.new()
	promo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	promo_lbl.text = "🌟 CHÚC MỪNG THĂNG HẠNG: %s! 🌟" % RankSystem.get_rank_name(res["rank_index"]).to_upper()
	promo_lbl.add_theme_font_size_override("font_size", 14)
	promo_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4, 1.0))
	promo_margin.add_child(promo_lbl)

	# --- D. PHẦN THƯỞNG & NÚT VỀ SẢNH ---
	var rewards_hbox = HBoxContainer.new()
	rewards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	rewards_hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(rewards_hbox)

	var exp_lbl = Label.new()
	exp_lbl.text = "🎁 +%d EXP" % (20 if is_win else 12)
	exp_lbl.add_theme_font_size_override("font_size", 13)
	exp_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	rewards_hbox.add_child(exp_lbl)
	if not exp_result.is_empty() and bool(exp_result.get("leveled_up", false)):
		var level_lbl = Label.new()
		level_lbl.text = "🎉 LÊN CẤP %d" % int(exp_result.get("new_level", 1))
		level_lbl.add_theme_font_size_override("font_size", 13)
		level_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
		rewards_hbox.add_child(level_lbl)

	var silver_lbl = Label.new()
	silver_lbl.text = "🪙 +%d Bạc" % (300 if is_win else 100)
	silver_lbl.add_theme_font_size_override("font_size", 13)
	silver_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	rewards_hbox.add_child(silver_lbl)

	var return_btn = Button.new()
	return_btn.custom_minimum_size = Vector2(240, 42)
	return_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return_btn.text = "🏠 VỀ SẢNH CHÍNH"
	var r_style = StyleBoxFlat.new()
	r_style.bg_color = Color(0.85, 0.68, 0.22, 1.0)
	r_style.corner_radius_top_left = 8
	r_style.corner_radius_top_right = 8
	r_style.corner_radius_bottom_right = 8
	r_style.corner_radius_bottom_left = 8
	r_style.shadow_color = Color(0, 0, 0, 0.4)
	r_style.shadow_size = 4
	return_btn.add_theme_stylebox_override("normal", r_style)
	return_btn.add_theme_color_override("font_color", Color(0.08, 0.05, 0.01))
	return_btn.add_theme_font_size_override("font_size", 14)
	return_btn.pressed.connect(_on_return_home_clicked)
	vbox.add_child(return_btn)

	# --- E. HOẠT HỌA TUẦN TỰ (SEQUENTIAL TWEEN ANIMATIONS) ---
	# 1. Xuất hiện Modal nảy nhẹ
	box.pivot_offset = Vector2(290, 240)
	box.scale = Vector2(0.85, 0.85)
	box.modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(box, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(box, "modulate:a", 1.0, 0.2)
	if is_win:
		AudioManager.play_victory()
	else:
		AudioManager.play_defeat()
	await tw.finished

	await get_tree().create_timer(0.3).timeout

	# 2. Hoạt họa Tăng / Giảm Sao
	if is_win:
		var target_star_idx = res["old_stars"]
		if target_star_idx < star_nodes.size():
			var s_node = star_nodes[target_star_idx] as Label
			var s_tw = create_tween()
			s_tw.tween_property(s_node, "scale", Vector2(1.8, 1.8), 0.18).set_trans(Tween.TRANS_BACK)
			s_tw.parallel().tween_property(s_node, "theme_override_colors/font_color", Color(1.0, 0.88, 0.2, 1.0), 0.18)
			s_tw.tween_property(s_node, "scale", Vector2(1.0, 1.0), 0.15)
			AudioManager.play_card_draw()
			await s_tw.finished
	else:
		if res["old_stars"] > 0:
			var target_star_idx = res["old_stars"] - 1
			if target_star_idx < star_nodes.size():
				var s_node = star_nodes[target_star_idx] as Label
				var s_tw = create_tween()
				s_tw.tween_property(s_node, "theme_override_colors/font_color", Color(1.0, 0.25, 0.25), 0.15)
				s_tw.tween_property(s_node, "theme_override_colors/font_color", Color(0.25, 0.28, 0.38, 0.8), 0.25)
				AudioManager.play_damage()
				await s_tw.finished

	# Cập nhật nhãn số sao sau khi sao đổi
	var intermediate_stars = res["stars"]
	if res["promoted"]:
		intermediate_stars = 5 # Đầy 5 sao trước khi biến hình thăng hạng
	star_count_lbl.text = " %d/5 Sao" % intermediate_stars

	await get_tree().create_timer(0.3).timeout

	# 3. Hoạt họa Thanh Điểm Tích Lũy
	var bar_tw = create_tween()
	if res["star_bonus_from_points"]:
		# Chạy lên 100/100 -> bùng nổ thưởng 1 sao -> chạy về điểm dư
		bar_tw.tween_property(acc_bar, "value", 100.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await bar_tw.finished
		
		acc_text_lbl.text = "⚡ ĐẦY 100 ĐIỂM TÍCH LŨY ➔ THƯỞNG +1 SAO! ⚡"
		acc_text_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		AudioManager.play_skill()

		# Thêm 1 sao nữa vào dải sao
		var bonus_star_idx = intermediate_stars
		if bonus_star_idx < star_nodes.size():
			var b_node = star_nodes[bonus_star_idx] as Label
			var b_tw = create_tween()
			b_tw.tween_property(b_node, "scale", Vector2(1.8, 1.8), 0.2)
			b_tw.parallel().tween_property(b_node, "theme_override_colors/font_color", Color(1.0, 0.88, 0.2), 0.2)
			b_tw.tween_property(b_node, "scale", Vector2(1.0, 1.0), 0.15)
			await b_tw.finished
		
		await get_tree().create_timer(0.3).timeout
		var bar_reset_tw = create_tween()
		bar_reset_tw.tween_property(acc_bar, "value", float(res["accumulation_points"]), 0.4)
		await bar_reset_tw.finished
		acc_text_lbl.text = "%d/100 Điểm (Đủ 100đ đổi +1★)" % res["accumulation_points"]
		acc_text_lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	else:
		bar_tw.tween_property(acc_bar, "value", float(res["accumulation_points"]), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await bar_tw.finished
		acc_text_lbl.text = "%d/100 Điểm (Đủ 100đ đổi +1★)" % res["accumulation_points"]

	# 4. Hoạt Họa Lên Rank (Promotion)
	if res["promoted"]:
		await get_tree().create_timer(0.4).timeout
		
		# Hiệu ứng huy hiệu phát sáng và rung lắc nhẹ
		var r_tw = create_tween()
		r_tw.tween_property(badge_rect, "scale", Vector2(1.4, 1.4), 0.25).set_trans(Tween.TRANS_BACK)
		r_tw.parallel().tween_property(badge_rect, "modulate", Color(2.5, 2.3, 1.5), 0.25)
		await r_tw.finished
		
		# Đổi sang icon rank mới
		var new_icon_path = RankSystem.get_rank_icon_path(res["rank_index"])
		if ResourceLoader.exists(new_icon_path):
			badge_rect.texture = load(new_icon_path)
		
		rank_name_lbl.text = RankSystem.get_rank_name(res["rank_index"]).to_upper()
		var new_color = RankSystem.get_rank_info(res["rank_index"]).get("color", Color(1.0, 0.9, 0.3))
		rank_name_lbl.add_theme_color_override("font_color", new_color)
		
		var r_down = create_tween()
		r_down.tween_property(badge_rect, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BOUNCE)
		r_down.parallel().tween_property(badge_rect, "modulate", Color(1.0, 1.0, 1.0), 0.35)
		
		# Hiện Banner thăng hạng
		promo_panel.visible = true
		promo_panel.scale = Vector2(0.6, 0.6)
		promo_panel.modulate.a = 0.0
		var p_tw = create_tween().set_parallel(true)
		p_tw.tween_property(promo_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)
		p_tw.tween_property(promo_panel, "modulate:a", 1.0, 0.2)
		
		AudioManager.play_victory()

		# Reset dải sao về số sao mới của rank mới (mặc định 0 sao)
		for s in range(5):
			var s_node = star_nodes[s] as Label
			if s < res["stars"]:
				s_node.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2, 1.0))
			else:
				s_node.add_theme_color_override("font_color", Color(0.25, 0.28, 0.38, 0.8))
		star_count_lbl.text = " %d/5 Sao" % res["stars"]

func _on_return_home_clicked() -> void:
	if NetworkClient:
		NetworkClient.room_id = ""
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _is_ai_controller() -> bool:
	var lowest_human_seat = 99
	for s in range(1, battle_seat_count + 1):
		if generals_data.has(s):
			var g = generals_data[s]
			if g.get("is_alive", false) and not g.get("isAI", false) and s < lowest_human_seat:
				lowest_human_seat = s
	if lowest_human_seat == 99:
		return true
	return (my_seat == lowest_human_seat)

func _start_turn(seat_num: int) -> void:
	if is_game_over:
		return
	if is_network_mode:
		return

	# Skip dead generals
	var g = generals_data[seat_num]
	if not g["is_alive"]:
		_next_turn()
		return

	current_turn_seat = seat_num
	local_turn_dealt_damage = false
	lap_lang_triggered_this_turn = false
	slashes_used_this_turn = 0
	local_van_an_uses = 0
	g["is_wine_buff_active"] = false
	g["wine_used_this_turn"] = false
	if seat_num == my_seat:
		is_wine_buff_active = false
		wine_used_this_turn = false
	is_discard_phase = false
	cards_to_discard_count = 0
	var turn_role := "VƯƠNG" if str(g.get("role", "")) == "KING" else "?"
	_add_log("📜 [LƯỢT %d] Tướng %s (%s) bước vào lượt chiến đấu." % [seat_num, g["name"], turn_role])

	# Kích hoạt 3 dấu chấm viền chạy quanh và đồng hồ đếm ngược trên đầu avatar tướng
	for s in range(1, battle_seat_count + 1):
		if generals_data.has(s) and generals_data[s].has("avatar_node"):
			var is_active = (s == seat_num and generals_data[s]["is_alive"])
			generals_data[s]["avatar_node"].set_turn_active(is_active)
			generals_data[s]["avatar_node"].update_turn_timer(40)

	# GIAI ĐOẠN PHÁN XÉT (JUDGEMENT PHASE)
	# 1. Đại Hồng Thủy
	if g.get("has_dai_hong_thuy", g.get("has_lightning", false)):
		await _handle_dai_hong_thuy_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# 2. Cắt Đường Lương (Supply Shortage)
	var skip_draw_phase = false
	if g.get("has_cat_luong", false):
		skip_draw_phase = await _handle_supply_shortage_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# 3. Trầm Ảo Sa Bẫy (Acedia)
	var skip_play_phase = false
	if g.get("has_tram_ao", false):
		skip_play_phase = await _handle_acedia_judgement(seat_num)
		if not g["is_alive"] or is_game_over:
			_next_turn()
			return

	# Draw Phase
	if not skip_draw_phase:
		for k in range(2):
			var card_info = _draw_card_from_pile()
			if g["isPlayer"]:
				_add_card_to_player_hand(card_info)
			else:
				g["hand_cards"].append(card_info)
				g["hand_count"] = g["hand_cards"].size()
		g["avatar_node"].update_hand_count(g["hand_count"])
	else:
		_add_log("🌾 [CẮT ĐƯỜNG LƯƠNG] %s bị tước quyền rút 2 lá bài lượt này!" % g["name"])

	# Play Phase
	if skip_play_phase:
		_add_log("🕸️ [TRẦM ẢO SA BẪY] %s bị phong ấn, mất lượt ra bài!" % g["name"])
		await get_tree().create_timer(1.2).timeout
		_next_turn()
		return

	# PHÂN LUỒNG: NGƯỜI THẬT CỤC BỘ vs NGƯỜI THẬT TỪ XA vs BOT AI
	if g["isPlayer"]:
		# 1. Người chơi tại máy: Điều khiển tự do, 40 giây
		is_player_turn = true
		current_turn_timer = 40.0
		turn_indicator.text = "⏳ LƯỢT CỦA BẠN (40s)"
		end_turn_btn.visible = true
		card_play_btn.visible = false
		desc_text.text = "💡 Lượt của bạn: Rút 2 lá bài. Hãy chọn bài trên tay và mục tiêu để tấn công!"
	elif not g["isAI"]:
		# 2. Người thật từ xa qua mạng: Chờ đủ 40s, không để AI đánh hộ!
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - ĐANG CHỜ RA BÀI (40s)" % [g["name"], seat_num]
		desc_text.text = "⏳ Đang đợi người chơi %s suy nghĩ và ra đòn..." % g["name"]
		_execute_remote_player_turn(seat_num)
	else:
		# 3. Bot máy (AI): Chỉ Client là AI Controller (chủ phòng / lowest human seat) mới tính toán và phát sóng
		is_player_turn = false
		end_turn_btn.visible = false
		card_play_btn.visible = false
		if _is_ai_controller():
			turn_indicator.text = "🤖 Lượt của %s (Máy)..." % g["name"]
			desc_text.text = "🤖 Máy %s đang tính toán nước đi..." % g["name"]
			_execute_ai_turn(seat_num)
		else:
			turn_indicator.text = "⏳ LƯỢT %s (MÁY) - CHỜ ĐIỀU PHỐI..." % g["name"]
			desc_text.text = "⏳ Đang đồng bộ lượt máy của %s từ chủ phòng..." % g["name"]
			_execute_remote_player_turn(seat_num)

func _execute_remote_player_turn(remote_seat: int) -> void:
	if is_network_mode:
		return
	var g = generals_data[remote_seat]
	remote_turn_timer = 40.0
	is_remote_turn_active = true

	_add_log("👉 Đang chờ người chơi %s (Ghế %d) ra bài..." % [g["name"], remote_seat])

	while is_remote_turn_active and remote_turn_timer > 0.0 and not is_game_over:
		await get_tree().create_timer(0.2).timeout
		remote_turn_timer -= 0.2
		var sec = max(0, int(ceil(remote_turn_timer)))
		turn_indicator.text = "⏳ LƯỢT %s (GHẾ %d) - %ds..." % [g["name"], remote_seat, sec]

	is_remote_turn_active = false
	if remote_turn_timer <= 0:
		_add_log("⏰ Hết 40s thời gian lượt của %s." % g["name"])
	await get_tree().create_timer(0.5).timeout
	_next_turn()

func _handle_remote_card_play(caster_seat: int, card_id: String, target_seat: int, played_card: Dictionary = {}, display_name: String = "", target_seats: Array = [], decrement_hand: bool = true, resolve_reaction: bool = true) -> void:
	if not generals_data.has(caster_seat):
		return
	var caster = generals_data[caster_seat]
	if decrement_hand:
		caster["hand_count"] = max(0, caster["hand_count"] - 1)
		caster["avatar_node"].update_hand_count(caster["hand_count"])
	var used_card = played_card.duplicate()
	var explicit_card_name = display_name.strip_edges()
	if explicit_card_name.is_empty():
		explicit_card_name = str(used_card.get("name", used_card.get("cardName", ""))).strip_edges()
	if explicit_card_name.is_empty():
		explicit_card_name = _get_card_display_name(used_card)
	if str(used_card.get("name", "")).strip_edges().is_empty() and not explicit_card_name.is_empty():
		used_card["name"] = explicit_card_name

	var card_name = card_id
	var cid_lower = card_id.to_lower()
	if "banh" in cid_lower: card_name = "Bánh Chưng"
	elif "do" in cid_lower: card_name = "Đỡ"
	elif "nothan" in cid_lower: card_name = "Nỏ Thần Kim Quy"
	elif "khienmay" in cid_lower: card_name = "Khiên Mây Bện"
	elif "ruou" in cid_lower: card_name = "Hủ Rượu"
	elif "daihongthuy" in cid_lower or "thansam" in cid_lower or "samset" in cid_lower: card_name = "Đại Hồng Thủy"
	elif "xichtam" in cid_lower or "xich" in cid_lower: card_name = "Xích Tâm Tỏa"
	elif "dungbinh" in cid_lower: card_name = "Dụng Binh Như Thần"
	elif "baicocbachdang" in cid_lower: card_name = "Bãi Cọc Bạch Đằng"
	elif "giactoi" in cid_lower or "baicoc" in cid_lower: card_name = "Giặc Tới"
	elif "muaten" in cid_lower: card_name = "Mưa Tên Liên Châu"
	elif "thachdau" in cid_lower or "huyetchien" in cid_lower: card_name = "Huyết Chiến"
	elif "mokho" in cid_lower: card_name = "Mở Kho Cứu Tế"
	elif "vuonkhong" in cid_lower: card_name = "Vườn Không Nhà Trống"
	elif "dotkich" in cid_lower: card_name = "Đột Kích Trộm Lương"
	elif "dieuke" in cid_lower: card_name = "Diệu Kế Phá Mưu"
	elif "catluong" in cid_lower: card_name = "Cắt Đường Lương"
	elif "tramao" in cid_lower: card_name = "Trầm Ảo Sa Bẫy"
	elif "thuytrieurut" in cid_lower: card_name = "Thủy Triều Rút"
	elif "muonguom" in cid_lower: card_name = "Mượn Gươm Diệt Địch"
	elif "moyentiec" in cid_lower: card_name = "Mở Yến Tiệc"
	elif "hichtuongsi" in cid_lower: card_name = "Hịch Tướng Sĩ"
	elif "trongdong" in cid_lower or "bronzedrum" in cid_lower: card_name = "Trống Đồng Đông Sơn"
	elif "thuanthien" in cid_lower: card_name = "Kiếm Thuận Thiên"
	elif "songcung" in cid_lower: card_name = "Song Cung Mường Nhạ"
	elif "truongdao" in cid_lower: card_name = "Trường Đao Nam Sơn"
	elif "thuongngau" in cid_lower: card_name = "Thương Ngâu Lãng Bạc"
	elif "sungthancong" in cid_lower: card_name = "Súng Thần Công Hồ Triều"
	elif "giapdong" in cid_lower: card_name = "Giáp Đồng Sơn Vi"
	elif "aobao" in cid_lower: card_name = "Áo Bào Hoàng Tộc"
	elif "voichien" in cid_lower: card_name = "Voi Chiến Đại Việt"
	elif "nguatrang" in cid_lower: card_name = "Ngựa Trắng Thuần Nông"
	if not explicit_card_name.is_empty():
		card_name = explicit_card_name
	if card_name in ["Giặc Tới", "Mưa Tên Liên Châu"]:
		_play_smart_card_rays(card_name, caster_seat, _get_aoe_ray_targets(caster_seat))
	elif target_seat > 0 and card_name in ["Huyết Chiến", "Bãi Cọc Bạch Đằng", "Đột Kích Trộm Lương", "Vườn Không Nhà Trống", "Cắt Đường Lương", "Trầm Ảo Sa Bẫy", "Thủy Triều Rút"]:
		_play_smart_card_rays(card_name, caster_seat, [target_seat])
	elif card_name == "Xích Tâm Tỏa" and not target_seats.is_empty():
		_play_smart_card_rays(card_name, caster_seat, target_seats)

	if card_name == "Bánh Chưng":
		recent_heal_seats[caster_seat] = Time.get_ticks_msec()
		if not is_network_mode:
			caster["hp"] = min(caster["max_hp"], caster["hp"] + 1)
			caster["avatar_node"].update_hp(caster["hp"], caster["max_hp"])
		AudioManager.play_voice(card_name)
		_animate_showcase_card(card_name, "%s dùng [Bánh Chưng] hồi 1 Máu!" % caster["name"], used_card)
		_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu." % caster["name"])
	elif card_name == "Hủ Rượu":
		caster["is_wine_buff_active"] = true
		caster["wine_used_this_turn"] = true
		AudioManager.play_voice("Hủ Rượu")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s uống Hủ Rượu (+1 Sát Thương)!" % caster["name"], used_card)
		_add_log("🍶 %s đã uống [Hủ Rượu]!" % caster["name"])
	elif _is_dai_hong_thuy_name(card_name):
		caster["has_dai_hong_thuy"] = true
		caster["has_lightning"] = true # Legacy state alias.
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			caster["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
		AudioManager.play_voice("Đại Hồng Thủy")
		AudioManager.play_skill()
		_animate_showcase_card("Đại Hồng Thủy", "%s đặt [Đại Hồng Thủy] vào khu phán xét!" % caster["name"], used_card)
		_add_log("🌊 %s đã tự gắn [Đại Hồng Thủy] vào khu phán xét!" % caster["name"])
	elif card_name == "Giặc Tới":
		AudioManager.play_voice("Giặc Tới")
		AudioManager.play_skill()
		_animate_showcase_card("Giặc Tới", "%s phát động [Giặc Tới]!" % caster["name"], used_card)
		_add_log("🪵 %s phát động [Giặc Tới]! Toàn bộ người chơi khác phải đánh 1 Trảm." % caster["name"])
		if not is_network_mode:
			_execute_aoe_attack(caster_seat, "Giặc Tới", "Trảm")
	elif card_name == "Bãi Cọc Bạch Đằng":
		if target_seat > 0 and generals_data.has(target_seat):
			var trap_target = generals_data[target_seat]
			if _hero_has_skill(trap_target, "thuy_chien"):
				_add_log("🛡️ %s có kỹ năng [Thủy Chiến], miễn nhiễm hoàn toàn với Bãi Cọc Bạch Đằng!" % trap_target["name"])
			else:
				trap_target["has_bai_coc"] = true
				if trap_target.has("avatar_node") and is_instance_valid(trap_target["avatar_node"]):
					trap_target["avatar_node"].set_delayed_trick("bai_coc", true)
				AudioManager.play_skill()
				_animate_showcase_card(card_name, "%s gài [Bãi Cọc Bạch Đằng] lên mục tiêu!" % caster["name"], used_card)
				_add_log("🪵 %s gài [Bãi Cọc Bạch Đằng] lên %s!" % [caster["name"], trap_target["name"]])
	elif card_name == "Mưa Tên Liên Châu":
		AudioManager.play_voice("Mưa Tên Liên Châu")
		AudioManager.play_skill()
		_animate_showcase_card("Mưa Tên Liên Châu", "%s phát động [Mưa Tên Liên Châu]!" % caster["name"], used_card)
		_add_log("🏹 %s phát động [Mưa Tên Liên Châu]! Toàn bộ người chơi khác phải đánh 1 Đỡ." % caster["name"])
		if not is_network_mode:
			_execute_aoe_attack(caster_seat, "Mưa Tên Liên Châu", "Đỡ")
	elif card_name == "Huyết Chiến":
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_duel = generals_data[target_seat]
			AudioManager.play_voice("Huyết Chiến")
			AudioManager.play_slash()
			_animate_showcase_card("Huyết Chiến", "%s huyết chiến %s!" % [caster["name"], tgt_duel["name"]], used_card)
			_add_log("⚔️ %s phát động [Huyết Chiến] lên %s!" % [caster["name"], tgt_duel["name"]])
			if not is_network_mode:
				_execute_duel(caster_seat, target_seat)
	elif card_name == "Mở Kho Cứu Tế":
		AudioManager.play_voice("Mở Kho Cứu Tế")
		AudioManager.play_skill()
		_animate_showcase_card("Mở Kho Cứu Tế", "%s phát động [Mở Kho Cứu Tế]!" % caster["name"], used_card)
		_add_log("🌾 %s phát động [Mở Kho Cứu Tế]! Mở kho phát lương cho toàn bàn." % caster["name"])
		if not is_network_mode:
			_execute_harvest(caster_seat)
	elif card_name == "Thủy Triều Rút":
		AudioManager.play_voice("Thủy Triều Rút")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s dùng [Thủy Triều Rút]!" % caster["name"], used_card)
		_add_log("🌊 %s dùng [Thủy Triều Rút]." % caster["name"])
	elif card_name == "Mượn Gươm Diệt Địch":
		AudioManager.play_voice("Mượn Gươm Diệt Địch")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s dùng [Mượn Gươm Diệt Địch]!" % caster["name"], used_card)
		_add_log("🗡️ %s dùng [Mượn Gươm Diệt Địch]." % caster["name"])
	elif card_name == "Mở Yến Tiệc":
		AudioManager.play_voice("Mở Yến Tiệc")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s mở [Mở Yến Tiệc]!" % caster["name"], used_card)
		_add_log("🍽️ %s mở [Mở Yến Tiệc]." % caster["name"])
	elif card_name == "Hịch Tướng Sĩ":
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s phát [Hịch Tướng Sĩ]!" % caster["name"], used_card)
		_add_log("📣 %s phát [Hịch Tướng Sĩ]." % caster["name"])
	elif card_name == "Trống Đồng Đông Sơn":
		caster["equipped_treasure"] = card_name
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			var drum_suit = _get_suit_icon(str(used_card.get("suit", "")))
			var drum_rank = _format_rank(used_card.get("rank", 0)) if int(used_card.get("rank", 0)) > 0 else ""
			caster["avatar_node"].set_equipment("treasure", card_name, (drum_suit + drum_rank).strip_edges())
			caster["avatar_node"].set_skill("🥁 ĐIỂM TRỐNG" if caster_seat == my_seat else "")
		AudioManager.play_voice("Trống Đồng Đông Sơn")
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị [Trống Đồng Đông Sơn]!" % caster["name"], used_card)
		_add_log("🥁 %s trang bị [Trống Đồng Đông Sơn]." % caster["name"])
	elif card_name == "Dụng Binh Như Thần":
		if not is_network_mode:
			var draw_num = 3 if caster.get("hero_id", 0) == 68 else 2
			caster["hand_count"] += draw_num
			caster["avatar_node"].update_hand_count(caster["hand_count"])
		AudioManager.play_voice("Dụng Binh Như Thần")
		AudioManager.play_skill()
		_animate_showcase_card("Dụng Binh Như Thần", "%s dùng [Dụng Binh Như Thần] rút bài!" % caster["name"], used_card)
		_add_log("📜 %s dùng [Dụng Binh Như Thần]!" % caster["name"])
	elif card_name == "Đột Kích Trộm Lương":
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_d = generals_data[target_seat]
			if not is_network_mode:
				if target_seat == my_seat and hand_container.get_child_count() > 0:
					var stolen_c = hand_container.get_child(hand_container.get_child_count() - 1)
					_discard_player_card(stolen_c)
				elif tgt_d["equipped_weapon"] != "":
					tgt_d["equipped_weapon"] = ""
					tgt_d["avatar_node"].set_equipment("weapon", "", "")
				elif tgt_d["equipped_armor"] != "":
					tgt_d["equipped_armor"] = ""
					tgt_d["avatar_node"].set_equipment("armor", "", "")
				else:
					tgt_d["hand_count"] = max(0, tgt_d["hand_count"] - 1)
					tgt_d["avatar_node"].update_hand_count(tgt_d["hand_count"])
				caster["hand_count"] += 1
				caster["avatar_node"].update_hand_count(caster["hand_count"])
			AudioManager.play_voice("Đột Kích Trộm Lương")
			AudioManager.play_skill()
			_animate_showcase_card("Đột Kích Trộm Lương", "%s cướp 1 lá của %s!" % [caster["name"], tgt_d["name"]], used_card)
			_add_log("🗡️ %s dùng [Đột Kích Trộm Lương] cướp bài của %s!" % [caster["name"], tgt_d["name"]])
	elif card_name in ["Vườn Không Nhà Trống", "Diệu Kế Phá Mưu"]:
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_v = generals_data[target_seat]
			if not is_network_mode:
				if target_seat == my_seat and hand_container.get_child_count() > 0:
					var rem_c = hand_container.get_child(hand_container.get_child_count() - 1)
					_discard_player_card(rem_c)
				elif tgt_v["equipped_weapon"] != "":
					tgt_v["equipped_weapon"] = ""
					tgt_v["avatar_node"].set_equipment("weapon", "", "")
				elif tgt_v["equipped_armor"] != "":
					tgt_v["equipped_armor"] = ""
					tgt_v["avatar_node"].set_equipment("armor", "", "")
				else:
					tgt_v["hand_count"] = max(0, tgt_v["hand_count"] - 1)
					tgt_v["avatar_node"].update_hand_count(tgt_v["hand_count"])
			AudioManager.play_voice(card_name)
			AudioManager.play_skill()
			_animate_showcase_card(card_name, "%s phá hủy 1 lá của %s!" % [caster["name"], tgt_v["name"]], used_card)
			_add_log("🌾 %s dùng [%s] phá hủy 1 lá bài của %s!" % [caster["name"], card_name, tgt_v["name"]])
	elif card_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
		caster["equipped_weapon"] = card_name
		caster["avatar_node"].set_equipment("weapon", card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị vũ khí [%s]!" % [caster["name"], card_name], used_card)
		_add_log("🗡️ %s trang bị Vũ Khí: [%s]!" % [caster["name"], card_name])
	elif card_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
		caster["equipped_armor"] = card_name
		if card_name == "Áo Bào Hoàng Tộc": caster["ao_bao_charges"] = 2
		caster["avatar_node"].set_equipment("armor", card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị áo giáp [%s]!" % [caster["name"], card_name], used_card)
		_add_log("🛡️ %s trang bị Áo Giáp: [%s]!" % [caster["name"], card_name])
	elif "Voi Chiến" in card_name or "Ngựa Trắng" in card_name or card_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
		var slot_m = "def_horse" if ("Voi Chiến" in card_name) else "off_horse"
		caster["equipped_" + slot_m] = card_name
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			caster["avatar_node"].set_equipment(slot_m, card_name, "")
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		_animate_showcase_card(card_name, "%s trang bị [%s]!" % [caster["name"], card_name], used_card)
		_add_log("🐎 %s trang bị Chiến Mã: [%s]!" % [caster["name"], card_name])
	elif card_name == "Xích Tâm Tỏa":
		AudioManager.play_voice(card_name)
		AudioManager.play_skill()
		var chain_targets: Array = []
		for raw_target in target_seats:
			var chain_seat = int(raw_target)
			if chain_seat > 0 and not chain_targets.has(chain_seat):
				chain_targets.append(chain_seat)
		if chain_targets.is_empty():
			var card_targets = used_card.get("targetSeats", [])
			if card_targets is Array:
				for raw_target in card_targets:
					var chain_seat = int(raw_target)
					if chain_seat > 0 and not chain_targets.has(chain_seat):
						chain_targets.append(chain_seat)
		if chain_targets.is_empty() and target_seat > 0:
			chain_targets.append(target_seat)
		for chain_seat in chain_targets:
			if not generals_data.has(chain_seat):
				continue
			var tgt_x = generals_data[chain_seat]
			tgt_x["is_chained"] = !tgt_x.get("is_chained", false)
			if tgt_x.has("avatar_node") and is_instance_valid(tgt_x["avatar_node"]):
				tgt_x["avatar_node"].set_chained(tgt_x["is_chained"])
		_animate_showcase_card(card_name, "%s dùng [Xích Tâm Tỏa]!" % caster["name"], used_card)
		_add_log("⛓️ %s dùng [Xích Tâm Tỏa]!" % caster["name"])
	elif card_name == "Cắt Đường Lương" or card_id.contains("catluong"):
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_c = generals_data[target_seat]
			tgt_c["has_cat_luong"] = true
			if tgt_c.has("avatar_node") and is_instance_valid(tgt_c["avatar_node"]):
				tgt_c["avatar_node"].set_delayed_trick("supply_shortage", true)
		AudioManager.play_voice("Cắt Đường Lương")
		AudioManager.play_skill()
		_animate_showcase_card("Cắt Đường Lương", "%s đặt [Cắt Đường Lương] lên đối thủ!" % caster["name"], used_card)
		_add_log("🌾 %s đặt [Cắt Đường Lương] vào khu phán xét của Ghế %d!" % [caster["name"], target_seat])
	elif card_name == "Trầm Ảo Sa Bẫy" or card_id.contains("tramao"):
		if target_seat > 0 and generals_data.has(target_seat):
			var tgt_t = generals_data[target_seat]
			tgt_t["has_tram_ao"] = true
			if tgt_t.has("avatar_node") and is_instance_valid(tgt_t["avatar_node"]):
				tgt_t["avatar_node"].set_delayed_trick("acedia", true)
		AudioManager.play_voice("Trầm Ảo Sa Bẫy")
		AudioManager.play_skill()
		_animate_showcase_card("Trầm Ảo Sa Bẫy", "%s đặt [Trầm Ảo Sa Bẫy] lên đối thủ!" % caster["name"], used_card)
		_add_log("🕸️ %s đặt [Trầm Ảo Sa Bẫy] vào khu phán xét của Ghế %d!" % [caster["name"], target_seat])
	elif target_seat > 0 and generals_data.has(target_seat):
		var tgt = generals_data[target_seat]
		var cached_wine_buff = bool(caster.get("is_wine_buff_active", false))
		var used_wine = bool(used_card.get("isWineBuff", false)) or cached_wine_buff
		var slash_damage = _get_effect_damage(used_card)
		if slash_damage <= 1 and cached_wine_buff:
			slash_damage = 2
		caster["is_wine_buff_active"] = false
		var elem = "NORMAL"
		if "Hỏa" in card_name: elem = "FIRE"
		elif "Thủy" in card_name or "Lôi" in card_name: elem = "WATER" # Accept old card names.
		AudioManager.play_voice(card_name)
		AudioManager.play_slash()
		_animate_showcase_card(card_name, "%s dùng [%s] tấn công %s!" % [caster["name"], card_name, tgt["name"]], used_card)
		_add_log("⚔️ %s dùng [%s]%s lên %s (Ghế %d)." % [caster["name"], card_name, " (kèm Hủ Rượu: +1 Sát Thương)" if used_wine else "", tgt["name"], target_seat])
		_play_smart_card_rays(card_name, caster_seat, [target_seat])
		if resolve_reaction:
			_handle_slash_attack(caster_seat, target_seat, slash_damage, elem, str(used_card.get("suit", "")))

func _execute_ai_turn(ai_seat: int) -> void:
	if is_network_mode:
		return
	await get_tree().create_timer(AI_CARD_PLAY_DELAY).timeout
	if is_game_over:
		return

	var ai_gen = generals_data[ai_seat]
	if not ai_gen["is_alive"]:
		_next_turn()
		return

	# 1. AI kiểm tra hồi máu bằng Bánh Chưng nếu mất máu
	if ai_gen["hp"] < ai_gen["max_hp"]:
		var bc_idx = -1
		for idx in range(ai_gen["hand_cards"].size()):
			if ai_gen["hand_cards"][idx].get("name", "") == "Bánh Chưng":
				bc_idx = idx
				break
		if bc_idx >= 0:
			var used_bc = ai_gen["hand_cards"][bc_idx]
			ai_gen["hand_cards"].remove_at(bc_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			ai_gen["hp"] = min(ai_gen["max_hp"], ai_gen["hp"] + 1)
			ai_gen["avatar_node"].update_hp(ai_gen["hp"], ai_gen["max_hp"])
			AudioManager.play_voice("Bánh Chưng")
			AudioManager.play_skill()
			_animate_showcase_card("Bánh Chưng", "%s dùng [Bánh Chưng] hồi 1 Máu!" % ai_gen["name"], used_bc)
			_add_log("🍲 %s dùng [Bánh Chưng] hồi 1 Máu (%d/%d)." % [ai_gen["name"], ai_gen["hp"], ai_gen["max_hp"]])
			await _wait_for_ai_card_play()

	# 2. AI trang bị Vũ Khí / Áo Giáp / Chiến Mã nếu rút trúng
	var equip_idx = -1
	for idx in range(ai_gen["hand_cards"].size()):
		var c = ai_gen["hand_cards"][idx]
		var c_name = c.get("name", "")
		if c_name in ["Kiếm Thuận Thiên", "Song Cung Mường Nhạ", "Nỏ Thần Kim Quy", "Trường Đao Nam Sơn", "Thương Ngâu Lãng Bạc", "Súng Thần Công Hồ Triều"]:
			equip_idx = idx
			ai_gen["equipped_weapon"] = c_name
			ai_gen["avatar_node"].set_equipment("weapon", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị vũ khí [%s]!" % [ai_gen["name"], c_name], c)
			_add_log("🗡️ %s trang bị Vũ Khí: [%s]!" % [ai_gen["name"], c_name])
			break
		elif c_name in ["Giáp Đồng Sơn Vi", "Khiên Mây Bện", "Áo Bào Hoàng Tộc"]:
			equip_idx = idx
			ai_gen["equipped_armor"] = c_name
			if c_name == "Áo Bào Hoàng Tộc":
				ai_gen["ao_bao_charges"] = 2
			ai_gen["avatar_node"].set_equipment("armor", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị áo giáp [%s]!" % [ai_gen["name"], c_name], c)
			_add_log("🛡️ %s trang bị Áo Giáp: [%s]!" % [ai_gen["name"], c_name])
			break
		elif c_name in ["Voi Chiến Đại Việt", "Ngựa Trắng Thuần Nông"]:
			equip_idx = idx
			if not await _resolve_local_bai_coc_action(ai_seat, ai_seat):
				break
			var ai_horse_rank := int(c.get("rank", 0))
			var ai_horse_suit_rank := _get_suit_icon(str(c.get("suit", ""))) + (_format_rank(ai_horse_rank) if ai_horse_rank > 0 else "")
			if c_name == "Voi Chiến Đại Việt":
				ai_gen["equipped_def_horse"] = c_name
				ai_gen["avatar_node"].set_equipment("def_horse", c_name, ai_horse_suit_rank)
			else:
				ai_gen["equipped_off_horse"] = c_name
				ai_gen["avatar_node"].set_equipment("off_horse", c_name, ai_horse_suit_rank)
			_animate_showcase_card(c_name, "%s trang bị chiến mã [%s]!" % [ai_gen["name"], c_name], c)
		elif c_name == "Trống Đồng Đông Sơn":
			equip_idx = idx
			ai_gen["equipped_treasure"] = c_name
			ai_gen["avatar_node"].set_equipment("treasure", c_name, "")
			_animate_showcase_card(c_name, "%s trang bị bảo vật [%s]!" % [ai_gen["name"], c_name], c)
			_add_log("🥁 %s trang bị Bảo Vật: [%s]!" % [ai_gen["name"], c_name])
			break

	if equip_idx >= 0:
		ai_gen["hand_cards"].remove_at(equip_idx)
		ai_gen["hand_count"] = ai_gen["hand_cards"].size()
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		AudioManager.play_skill()
		await _wait_for_ai_card_play()

	# 3. AI dùng Cẩm Nang nếu có
	var enemies = []
	for s in range(1, battle_seat_count + 1):
		var other = generals_data[s]
		if other["is_alive"] and other["isDragon"] != ai_gen["isDragon"]:
			enemies.append(s)

	# AI sử dụng Trống Đồng Đông Sơn (Điểm Trống) nếu có
	if ai_gen.get("equipped_treasure", "") == "Trống Đồng Đông Sơn":
		for enemy_s in enemies:
			var e_gen = generals_data.get(enemy_s, {})
			if e_gen.get("is_alive", false) and (int(e_gen.get("hand_count", 0)) > 0 or not e_gen.get("hand_cards", []).is_empty()):
				_animate_showcase_card("Điểm Trống", "🥁 %s phát động [Điểm Trống] lên %s!" % [ai_gen["name"], e_gen["name"]])
				_add_log("🥁 <b>%s</b> phát động [Điểm Trống] lên <b>%s</b>!" % [ai_gen["name"], e_gen["name"]])
				AudioManager.play_skill()
				await _wait_for_ai_card_play()
				_execute_local_drum_skill(ai_seat, enemy_s)
				break

	var scroll_idx = -1
	for idx in range(ai_gen["hand_cards"].size()):
		var c = ai_gen["hand_cards"][idx]
		var c_name = c.get("name", "")

		# AI tự đặt Đại Hồng Thủy vào bản thân nếu chưa có.
		if _is_dai_hong_thuy_name(c_name) and not ai_gen.get("has_dai_hong_thuy", ai_gen.get("has_lightning", false)):
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			ai_gen["has_dai_hong_thuy"] = true
			ai_gen["has_lightning"] = true # Legacy state alias.
			if ai_gen.has("avatar_node") and is_instance_valid(ai_gen["avatar_node"]):
				ai_gen["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
			AudioManager.play_voice("Đại Hồng Thủy")
			AudioManager.play_skill()
			_animate_showcase_card("Đại Hồng Thủy", "%s tự gắn [Đại Hồng Thủy] vào khu phán xét!" % ai_gen["name"], c)
			_add_log("🌊 %s đã tự gắn [Đại Hồng Thủy] vào khu phán xét của mình!" % ai_gen["name"])
			await _wait_for_ai_card_play()
			break

		if c_name == "Thủy Triều Rút":
			var tide_targets: Array = []
			for target_s in range(1, battle_seat_count + 1):
				if target_s != ai_seat and generals_data.has(target_s) and generals_data[target_s].get("is_alive", false) and int(generals_data[target_s].get("hand_count", 0)) > 0:
					tide_targets.append(target_s)
			if not tide_targets.is_empty():
				scroll_idx = idx
				var tide_target_seat = tide_targets.pick_random()
				var tide_target = generals_data[tide_target_seat]
				ai_gen["hand_cards"].remove_at(scroll_idx)
				ai_gen["hand_count"] = ai_gen["hand_cards"].size()
				ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
				AudioManager.play_skill()
				_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), tide_target_seat, ai_seat)
				_animate_showcase_card(c_name, "%s dùng [Thủy Triều Rút] lên %s!" % [ai_gen["name"], tide_target["name"]], c)
				_add_log("🌊 %s dùng [Thủy Triều Rút] lên %s." % [ai_gen["name"], tide_target["name"]])
				await _resolve_local_thuy_trieu_rut(ai_seat, tide_target_seat)
				await _wait_for_ai_card_play()
				break

		if c_name == "Giặc Tới":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Giặc Tới")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), 0, ai_seat)
			_animate_showcase_card("Giặc Tới", "%s dùng [Giặc Tới]!" % ai_gen["name"], c)
			_add_log("🪵 %s phát động [Giặc Tới]! Mọi người phải đánh Trảm hoặc mất 1 Máu." % ai_gen["name"])
			_play_smart_card_rays(c_name, ai_seat, _get_aoe_ray_targets(ai_seat))
			await _execute_aoe_attack(ai_seat, "Giặc Tới", "Trảm")
			await _wait_for_ai_card_play()
			break

		if c_name == "Mưa Tên Liên Châu":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Mưa Tên Liên Châu")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", "D80_CN_MuaTen", 0, ai_seat)
			_animate_showcase_card("Mưa Tên Liên Châu", "%s dùng [Mưa Tên Liên Châu]!" % ai_gen["name"], c)
			_add_log("🏹 %s phát động [Mưa Tên Liên Châu]! Mọi người phải đánh Đỡ hoặc mất 1 Máu." % ai_gen["name"])
			_play_smart_card_rays(c_name, ai_seat, _get_aoe_ray_targets(ai_seat))
			await _execute_aoe_attack(ai_seat, "Mưa Tên Liên Châu", "Đỡ")
			await _wait_for_ai_card_play()
			break

		if c_name == "Huyết Chiến" and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Huyết Chiến")
			AudioManager.play_slash()
			_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), tgt_s, ai_seat)
			_animate_showcase_card("Huyết Chiến", "%s huyết chiến %s!" % [ai_gen["name"], tgt_e["name"]], c)
			_add_log("⚔️ %s phát động [Huyết Chiến] lên %s!" % [ai_gen["name"], tgt_e["name"]])
			await _execute_duel(ai_seat, tgt_s)
			await _wait_for_ai_card_play()
			break

		if c_name == "Dụng Binh Như Thần":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			var draw_num = 3 if ai_gen.get("hero_id", 0) == 68 else 2
			for k in range(draw_num):
				var card_drawn = _draw_card_from_pile()
				ai_gen["hand_cards"].append(card_drawn)
				_animate_draw_to_seat(ai_seat)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Dụng Binh Như Thần")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), 0, ai_seat)
			_animate_showcase_card("Dụng Binh Như Thần", "%s dùng [Dụng Binh Như Thần] rút %d lá!" % [ai_gen["name"], draw_num], c)
			_add_log("📜 %s thi triển [Dụng Binh Như Thần] rút ngay %d lá bài!" % [ai_gen["name"], draw_num])
			await _wait_for_ai_card_play()
			break

		if c_name == "Mở Kho Cứu Tế":
			scroll_idx = idx
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			AudioManager.play_voice("Mở Kho Cứu Tế")
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), 0, ai_seat)
			_animate_showcase_card("Mở Kho Cứu Tế", "%s dùng [Mở Kho Cứu Tế]!" % ai_gen["name"], c)
			_add_log("🌾 %s thi triển [Mở Kho Cứu Tế]! Mở kho phát lương cho toàn bàn." % ai_gen["name"])
			await _execute_harvest(ai_seat)
			await _wait_for_ai_card_play()
			break

		if c_name in ["Cắt Đường Lương", "Trầm Ảo Sa Bẫy"] and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
			if c_name == "Cắt Đường Lương":
				tgt_e["has_cat_luong"] = true
				if tgt_e.has("avatar_node") and is_instance_valid(tgt_e["avatar_node"]):
					tgt_e["avatar_node"].set_delayed_trick("supply_shortage", true)
			else:
				tgt_e["has_tram_ao"] = true
				if tgt_e.has("avatar_node") and is_instance_valid(tgt_e["avatar_node"]):
					tgt_e["avatar_node"].set_delayed_trick("acedia", true)
			AudioManager.play_voice(c_name)
			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", c_name, tgt_s, ai_seat)
			_animate_showcase_card(c_name, "%s đặt [%s] lên %s!" % [ai_gen["name"], c_name, tgt_e["name"]], c)
			_add_log("⏳ %s đặt Cẩm Nang Trì Hoãn [%s] vào khu phán xét của %s!" % [ai_gen["name"], c_name, tgt_e["name"]])
			await _wait_for_ai_card_play()
			break

		if c_name in ["Đột Kích Trộm Lương", "Vườn Không Nhà Trống", "Diệu Kế Phá Mưu", "Xích Tâm Tỏa"] and not enemies.is_empty():
			scroll_idx = idx
			var tgt_s = enemies.pick_random()
			var tgt_e = generals_data[tgt_s]
			ai_gen["hand_cards"].remove_at(scroll_idx)
			ai_gen["hand_count"] = ai_gen["hand_cards"].size()
			ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])

			if c_name == "Đột Kích Trộm Lương":
				if tgt_e["isPlayer"]:
					if hand_container.get_child_count() > 0:
						var stolen_c = hand_container.get_child(hand_container.get_child_count() - 1)
						var info_s = _get_card_info_from_ui(stolen_c)
						_discard_player_card(stolen_c)
						ai_gen["hand_cards"].append(info_s)
						ai_gen["hand_count"] = ai_gen["hand_cards"].size()
						ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
				else:
					if not tgt_e["hand_cards"].is_empty():
						var stolen_c = tgt_e["hand_cards"].pop_back()
						tgt_e["hand_count"] = tgt_e["hand_cards"].size()
						tgt_e["avatar_node"].update_hand_count(tgt_e["hand_count"])
						ai_gen["hand_cards"].append(stolen_c)
						ai_gen["hand_count"] = ai_gen["hand_cards"].size()
						ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
				_animate_showcase_card(c_name, "%s dùng [Đột Kích Trộm Lương] lên %s!" % [ai_gen["name"], tgt_e["name"]], c)
				_add_log("🗡️ %s dùng [Đột Kích Trộm Lương] cướp bài của %s!" % [ai_gen["name"], tgt_e["name"]])

			elif c_name in ["Vườn Không Nhà Trống", "Diệu Kế Phá Mưu"]:
				if tgt_e["equipped_weapon"] != "":
					var old_w = tgt_e["equipped_weapon"]
					tgt_e["equipped_weapon"] = ""
					tgt_e["avatar_node"].set_equipment("weapon", "", "")
					_add_log("🌾 %s dùng [%s] phá hủy vũ khí [%s] của %s!" % [ai_gen["name"], c_name, old_w, tgt_e["name"]])
					if c_name == "Vườn Không Nhà Trống":
						_animate_showcase_card(old_w, "Vườn Không Nhà Trống phá hủy [%s] của %s!" % [old_w, tgt_e["name"]], _get_showcase_card_info(old_w), 2.0)
				elif tgt_e["equipped_armor"] != "":
					var old_a = tgt_e["equipped_armor"]
					tgt_e["equipped_armor"] = ""
					tgt_e["avatar_node"].set_equipment("armor", "", "")
					_add_log("🌾 %s dùng [%s] phá hủy giáp [%s] của %s!" % [ai_gen["name"], c_name, old_a, tgt_e["name"]])
					if c_name == "Vườn Không Nhà Trống":
						_animate_showcase_card(old_a, "Vườn Không Nhà Trống phá hủy [%s] của %s!" % [old_a, tgt_e["name"]], _get_showcase_card_info(old_a), 2.0)
				else:
					if tgt_e["isPlayer"] and hand_container.get_child_count() > 0:
						var c_rem = hand_container.get_child(hand_container.get_child_count() - 1)
						_discard_player_card(c_rem)
					elif not tgt_e["hand_cards"].is_empty():
						tgt_e["hand_cards"].pop_back()
						tgt_e["hand_count"] = tgt_e["hand_cards"].size()
						tgt_e["avatar_node"].update_hand_count(tgt_e["hand_count"])
					_add_log("🌾 %s dùng [%s] ép %s bỏ 1 lá bài!" % [ai_gen["name"], c_name, tgt_e["name"]])
				_animate_showcase_card(c_name, "%s dùng [%s] lên %s!" % [ai_gen["name"], c_name, tgt_e["name"]], c)

			elif c_name == "Xích Tâm Tỏa":
				var chain_targets: Array = [tgt_s]
				var other_enemies = enemies.duplicate()
				other_enemies.erase(tgt_s)
				if not other_enemies.is_empty():
					chain_targets.append(other_enemies.pick_random())
				var chain_names: Array[String] = []
				for chain_seat in chain_targets:
					if not generals_data.has(chain_seat):
						continue
					var chain_target = generals_data[chain_seat]
					chain_target["is_chained"] = !chain_target.get("is_chained", false)
					if chain_target.has("avatar_node") and is_instance_valid(chain_target["avatar_node"]):
						chain_target["avatar_node"].set_chained(chain_target["is_chained"])
					chain_names.append("%s (%s)" % [chain_target["name"], "khóa" if chain_target["is_chained"] else "gỡ"])
				_animate_showcase_card(c_name, "%s dùng [Xích Tâm Tỏa] lên %s!" % [ai_gen["name"], ", ".join(chain_names)], c)
				_add_log("⛓️ %s dùng [Xích Tâm Tỏa] lên %s." % [ai_gen["name"], ", ".join(chain_names)])
				_broadcast_player_battle_action("PLAY_CARD", str(c.get("id", c_name)), chain_targets[0], ai_seat, chain_targets[1] if chain_targets.size() > 1 else 0, chain_targets)
				AudioManager.play_skill()
				await _wait_for_ai_card_play()
				break

			AudioManager.play_skill()
			_broadcast_player_battle_action("PLAY_CARD", c_name, tgt_s, ai_seat)
			await _wait_for_ai_card_play()
			break

	# 4. AI tấn công kẻ địch bằng Trảm
	if not enemies.is_empty():
		var slash_idx = -1
		for idx in range(ai_gen["hand_cards"].size()):
			if "Trảm" in ai_gen["hand_cards"][idx].get("name", ""):
				slash_idx = idx
				break

		if slash_idx >= 0:
			var slash_card = ai_gen["hand_cards"][slash_idx]
			var card_name = slash_card.get("name", "Trảm")
			var elem = "NORMAL"
			if "Hỏa" in card_name: elem = "FIRE"
			elif "Thủy" in card_name or "Lôi" in card_name: elem = "WATER" # Accept old card names.

			# Lọc các mục tiêu hợp lệ: trong tầm đánh và không bị Dạ Trạch chặn khi Triệu Quang Phục không có bài
			var valid_slash_targets: Array = []
			for e_seat in enemies:
				if _is_da_trach_slash_blocked(e_seat):
					continue
				var dist = _calculate_distance(ai_seat, e_seat)
				var max_r = _get_attack_range(ai_seat)
				var water_bach_dang = ("Thủy" in card_name and ai_gen.get("equipped_off_horse", "") == "Thuyền Bạch Đằng")
				var te_giang_ignore = (_hero_has_skill(ai_gen, "te_giang") and not _has_equipped_horse(generals_data[e_seat]))
				if dist <= max_r or water_bach_dang or te_giang_ignore:
					valid_slash_targets.append(e_seat)

			if not valid_slash_targets.is_empty():
				ai_gen["hand_cards"].remove_at(slash_idx)
				ai_gen["hand_count"] = ai_gen["hand_cards"].size()
				ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])

				if ai_gen.get("has_bai_coc", false):
					if not await _resolve_local_bai_coc_action(ai_seat, ai_seat):
						slash_idx = -1

				if slash_idx >= 0 and ai_gen.get("is_alive", false) and not is_game_over:
					var chosen_tgt_seat = valid_slash_targets.pick_random()
					for e_seat in valid_slash_targets:
						if e_seat == my_seat and randf() < 0.6:
							chosen_tgt_seat = e_seat
							break

					var tgt_gen = generals_data[chosen_tgt_seat]

					AudioManager.play_voice(card_name)
					AudioManager.play_slash()
					_broadcast_player_battle_action("PLAY_CARD", card_name, chosen_tgt_seat, ai_seat)
					_animate_showcase_card(card_name, "%s dùng [%s] tấn công %s!" % [ai_gen["name"], card_name, tgt_gen["name"]], slash_card)
					_add_log("⚔️ %s (Ghế %d) dùng [%s] lên %s (Ghế %d)." % [ai_gen["name"], ai_seat, card_name, tgt_gen["name"], chosen_tgt_seat])
					_play_smart_card_rays(card_name, ai_seat, [chosen_tgt_seat])

					var ai_slash_suit = slash_card.get("suit", "Spade")
					var ai_slash_damage = 1
					if ai_gen.get("is_wine_buff_active", false):
						ai_slash_damage += 1
						ai_gen["is_wine_buff_active"] = false
					await _handle_slash_attack(ai_seat, chosen_tgt_seat, ai_slash_damage, elem, ai_slash_suit)

					if chosen_tgt_seat == my_seat:
						while is_waiting_dodge and not is_game_over:
							await get_tree().create_timer(0.3).timeout
					else:
						await _wait_for_ai_card_play()

	# 5. AI Discard Phase (Bỏ bài thừa)
	var ai_hand_limit = _get_general_hand_limit(ai_gen)
	var ai_excess = ai_gen["hand_cards"].size() - ai_hand_limit
	if ai_excess > 0:
		for d in range(ai_excess):
			if not ai_gen["hand_cards"].is_empty():
				ai_gen["hand_cards"].pop_back()
		ai_gen["hand_count"] = ai_gen["hand_cards"].size()
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		_animate_discard_from_seat(ai_seat, ai_excess)
		_animate_showcase_card("Bỏ bài thừa", "%s bỏ %d lá bài thừa!" % [ai_gen["name"], ai_excess])
		_add_log("🗑️ %s đã bỏ %d lá bài thừa (Còn %d lá theo giới hạn trữ bài)." % [ai_gen["name"], ai_excess, ai_hand_limit])
		AudioManager.play_card_draw()
		await _wait_for_ai_card_play()

	# Lập Làng được xử lý sau khi AI đã bỏ đủ bài thừa.
	if _hero_has_skill(ai_gen, "lap_lang") and not local_turn_dealt_damage and not lap_lang_triggered_this_turn:
		lap_lang_triggered_this_turn = true
		for _draw_index in range(2):
			ai_gen["hand_cards"].append(_draw_card_from_pile())
		ai_gen["hand_count"] = ai_gen["hand_cards"].size()
		ai_gen["avatar_node"].update_hand_count(ai_gen["hand_count"])
		_animate_showcase_card("Lập Làng", "🏘️ %s đã bỏ bài xong và không gây sát thương, rút 2 lá bài." % ai_gen["name"])
		_add_log("🏘️ [LẬP LÀNG] %s đã bỏ bài xong và không gây sát thương, rút 2 lá bài." % ai_gen["name"])

	# End AI turn
	_broadcast_player_battle_action("END_TURN", "", 0, ai_seat)
	await get_tree().create_timer(AI_CARD_PLAY_DELAY).timeout
	_next_turn()

func _wait_for_ai_card_play() -> void:
	await get_tree().create_timer(AI_CARD_PLAY_DELAY).timeout

func _get_general_hand_limit(general: Dictionary) -> int:
	var limit = int(general.get("hp", 0))
	if _hero_has_skill(general, "xung_de") and int(general.get("hp", 0)) == int(general.get("max_hp", 0)):
		limit += 2
	var has_horse_or_armor = not str(general.get("equipped_armor", "")).is_empty() \
		or not str(general.get("equipped_def_horse", "")).is_empty() \
		or not str(general.get("equipped_off_horse", "")).is_empty()
	if _hero_has_skill(general, "tung_nghia") and has_horse_or_armor:
		limit += 1
	if _hero_has_skill(general, "khoan_gian"):
		var equipment_count = 0
		for equipment_key in ["equipped_weapon", "equipped_weapon_2", "equipped_armor", "equipped_def_horse", "equipped_off_horse", "equipped_treasure"]:
			if not str(general.get(equipment_key, "")).is_empty():
				equipment_count += 1
		var x = int(ceil(float(equipment_count) / 2.0))
		limit += x + 1
	return limit

func _on_end_turn_btn_clicked() -> void:
	if current_server_phase == "AWAIT_NGHICH_Y" and current_waiting_seat == my_seat:
		# Nghịch Ý là phản ứng tùy chọn, không phải kết thúc lượt.
		NetworkClient.send_respond_action(false, "")
		is_targeting_nghich_y = false
		selected_nghich_y_card_id = ""
		if selected_card_ui and is_instance_valid(selected_card_ui):
			selected_card_ui.set_selected(false)
			selected_card_ui = null
		if selected_target_seat > 0 and generals_data.has(selected_target_seat):
			generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
		card_play_btn.visible = false
		end_turn_btn.disabled = true
		return
	if current_server_phase in ["AWAIT_CHINH_THONG_TARGET", "AWAIT_KHOAN_HOA", "AWAIT_XUNG_VUONG_TARGET"] and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		end_turn_btn.disabled = true
		return
	if current_server_phase == "AWAIT_DA_TRACH_DISCARD" and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		end_turn_btn.disabled = true
		return
	if current_server_phase == "AWAIT_AN_DAN_DUEL" and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		end_turn_btn.disabled = true
		return
	if current_server_phase == "AWAIT_DA_TRACH_DISCARD" and current_waiting_seat == my_seat:
		if selected_card_ui == null or not is_instance_valid(selected_card_ui):
			desc_text.text = "⚠️ [DẠ TRẠCH] hãy chọn 1 lá trên tay."
			return
		NetworkClient.send_respond_action(true, str(_get_card_info_from_ui(selected_card_ui).get("id", "")))
		card_play_btn.disabled = true
		return
	if current_server_phase in ["AWAIT_AN_DAN", "AWAIT_HOA_DAN", "AWAIT_DUNG_NUOC", "AWAIT_HAN_LAM", "AWAIT_TRUNG_KIEN", "AWAIT_VAN_SACH", "AWAIT_TRU_QUAN", "AWAIT_COT_KINH_TARGET", "AWAIT_TRUNG_TIET", "AWAIT_CAN_VE"] and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		end_turn_btn.disabled = true
		return
	if current_server_phase == "AWAIT_KHOI_BINH" and current_waiting_seat == my_seat:
		NetworkClient.send_respond_action(false, "")
		return
	if huynh_truong_pending:
		NetworkClient.send_use_skill("Huynh Trưởng", 0)
		return
	if uat_khi_pending:
		if is_network_mode:
			uat_khi_submission_pending = true
			end_turn_btn.disabled = true
			NetworkClient.send_respond_action(false, "")
		else:
			_clear_uat_khi_selection()
			uat_khi_pending = false
			current_waiting_seat = 0
			current_waiting_timer = 0.0
			end_turn_btn.visible = false
			_add_log("💢 Bạn từ chối phát động [UẤT KHÍ].")
			_show_dead_player_exit()
		return

	if not is_player_turn and not is_discard_phase:
		return

	var p_gen = generals_data[my_seat]
	var current_cards = hand_container.get_child_count()
	var excess = current_cards - _get_general_hand_limit(p_gen)

	# 1. Nếu đang trong pha bỏ bài, TUYỆT ĐỐI không cho phép bấm kết thúc lượt để auto bỏ hết:
	if is_discard_phase:
		return

	# 2. Nếu có bài thừa so với máu: chuyển sang pha bỏ bài bắt buộc
	if excess > 0:
		_enter_discard_phase(excess)
		if is_network_mode:
			_broadcast_player_battle_action("END_TURN", "", 0)
		return

	if not is_network_mode and _hero_has_skill(p_gen, "lap_lang") and not local_turn_dealt_damage and not lap_lang_triggered_this_turn:
		lap_lang_triggered_this_turn = true
		for _draw_index in range(2):
			_add_card_to_player_hand(_draw_card_from_pile())
		_animate_showcase_card("Lập Làng", "🏘️ Đã bỏ bài xong, không gây sát thương trong lượt nên rút 2 lá bài.")
		_add_log("🏘️ [LẬP LÀNG] Bạn đã bỏ bài xong và không gây sát thương, rút 2 lá bài.")

	_finish_player_end_turn()

func _on_player_turn_timeout() -> void:
	var p_gen = generals_data[my_seat]
	var hand_limit = _get_general_hand_limit(p_gen)
	var auto_discard_ids: Array = []
	while hand_container.get_child_count() > hand_limit and hand_container.get_child_count() > 0:
		var c_last = hand_container.get_child(hand_container.get_child_count() - 1)
		var info = _get_card_info_from_ui(c_last)
		var cid = info.get("id", info.get("name", ""))
		if not cid.is_empty():
			auto_discard_ids.append(cid)
		_discard_player_card(c_last)
		_add_log("⏰ Hết giờ: Tự động bỏ lá bài thừa [%s]." % info.get("name", "Bài"))
	selected_discard_nodes.clear()
	if is_network_mode:
		# Dù tự bỏ khi hết giờ, vẫn phải chờ máy chủ xác nhận và chuyển lượt.
		pending_discard_card_ids = auto_discard_ids
		_broadcast_player_battle_action("DISCARD_CARDS", "")
		pending_discard_card_ids.clear()
		is_discard_phase = true
		discard_submission_pending = true
		card_play_btn.visible = true
		card_play_btn.disabled = true
		card_play_btn.text = "🗑️ ĐANG XÁC NHẬN..."
		desc_text.text = "🗑️ Đang chờ máy chủ xác nhận bài bỏ khi hết giờ..."
	else:
		is_discard_phase = false
		_finish_player_end_turn()

func _finish_player_end_turn(send_network_end_turn: bool = true) -> void:
	if not is_network_mode and generals_data.has(my_seat):
		var local_player = generals_data[my_seat]
		local_player["suc_soi_turns_remaining"] = max(0, int(local_player.get("suc_soi_turns_remaining", 0)) - 1)
	is_player_turn = false
	is_discard_phase = false
	if is_targeting_ho_phu_skill or is_targeting_drum_skill:
		_clear_treasure_targeting()
	is_targeting_trieu_dang = false
	is_targeting_bat_na = false
	is_targeting_van_sach = false
	is_targeting_hung_suc = false
	is_targeting_van_an = false
	is_targeting_cai_cach = false
	is_targeting_thien_cam = false
	hung_suc_submission_pending = false
	_clear_hung_suc_equipped_weapon_previews()
	selected_two_card_skill_nodes.clear()
	_refresh_local_skill_buttons(my_seat)
	slashes_used_this_turn = 0
	local_van_an_uses = 0
	is_wine_buff_active = false
	wine_used_this_turn = false
	if generals_data.has(my_seat):
		generals_data[my_seat]["is_wine_buff_active"] = false
		generals_data[my_seat]["wine_used_this_turn"] = false
	selected_discard_nodes.clear()
	end_turn_btn.visible = false
	card_play_btn.visible = false
	for c in hand_container.get_children():
		if c.has_method("set_selected"):
			c.set_selected(false)
	if not selected_chain_seats.is_empty():
		selected_chain_seats.clear()
		_update_chain_target_highlights()
	if selected_card_ui and is_instance_valid(selected_card_ui):
		selected_card_ui.set_selected(false)
		selected_card_ui = null
	_clear_lien_chau_selection()
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
	_clear_borrow_sword_targets()
	if send_network_end_turn:
		_broadcast_player_battle_action("END_TURN", "", 0)
	_add_log("⌛ Bạn đã kết thúc lượt của mình.")
	if not is_network_mode:
		_next_turn()

func _get_next_alive_seat(current_seat: int) -> int:
	for step in range(1, battle_seat_count + 1):
		var next_s = ((current_seat - 1 + step) % battle_seat_count) + 1
		if generals_data.has(next_s) and generals_data[next_s].get("is_alive", false):
			return next_s
	return -1

func _create_local_borrowed_weapon_card(weapon_name: String) -> Dictionary:
	for card in CardDatabase.create_deck_80():
		if card is Dictionary and str(card.get("name", "")) == weapon_name:
			return card.duplicate()
	return {
		"id": "borrowed_%s" % weapon_name.to_lower().replace(" ", "_"),
		"name": weapon_name,
		"rank": 1,
		"suit": "Spade",
		"cat": 1,
		"subType": 6,
		"desc": _get_equipment_description(weapon_name)
	}

func _resolve_local_borrow_sword(caster_seat: int, weapon_owner_seat: int, forced_target_seat: int) -> void:
	if is_network_mode:
		return
	if not generals_data.has(caster_seat) or not generals_data.has(weapon_owner_seat) or not generals_data.has(forced_target_seat):
		return
	var caster = generals_data[caster_seat]
	var weapon_owner = generals_data[weapon_owner_seat]
	var forced_target = generals_data[forced_target_seat]
	if not weapon_owner.get("is_alive", false) or not forced_target.get("is_alive", false):
		return

	var weapon_name = str(weapon_owner.get("equipped_weapon", ""))
	if weapon_name.is_empty():
		_add_log("🗡️ [MƯỢN GƯƠM] %s không còn vũ khí, hiệu ứng kết thúc." % weapon_owner.get("name", "Mục tiêu"))
		return
	var weapon_range = _get_attack_range(weapon_owner_seat)
	if _calculate_distance(weapon_owner_seat, forced_target_seat) > weapon_range:
		_add_log("🗡️ [MƯỢN GƯƠM] Mục tiêu đã ngoài tầm vũ khí của %s, hiệu ứng kết thúc." % weapon_owner.get("name", "Mục tiêu"))
		return

	var owner_cards: Array = weapon_owner.get("hand_cards", [])
	var slash_index = -1
	for index in range(owner_cards.size()):
		var candidate = owner_cards[index]
		if candidate is Dictionary and "trảm" in str(candidate.get("name", "")).to_lower():
			slash_index = index
			break

	if slash_index >= 0:
		var slash_card: Dictionary = owner_cards[slash_index]
		# Bãi Cọc phải phán xét trước khi bỏ lá, phát hiệu ứng hoặc xử lý Trảm.
		if not await _resolve_local_bai_coc_action(weapon_owner_seat, weapon_owner_seat):
			owner_cards.remove_at(slash_index)
			weapon_owner["hand_cards"] = owner_cards
			weapon_owner["hand_count"] = owner_cards.size()
			if weapon_owner.has("avatar_node") and is_instance_valid(weapon_owner["avatar_node"]):
				weapon_owner["avatar_node"].update_hand_count(weapon_owner["hand_count"])
			return
		owner_cards.remove_at(slash_index)
		weapon_owner["hand_cards"] = owner_cards
		weapon_owner["hand_count"] = owner_cards.size()
		if weapon_owner.has("avatar_node") and is_instance_valid(weapon_owner["avatar_node"]):
			weapon_owner["avatar_node"].update_hand_count(weapon_owner["hand_count"])

		var slash_name = str(slash_card.get("name", "Trảm"))
		var slash_element = "NORMAL"
		if "Hỏa" in slash_name:
			slash_element = "FIRE"
		elif "Thủy" in slash_name or "Lôi" in slash_name:
			slash_element = "WATER"
		var slash_damage = 1
		if weapon_owner.get("is_wine_buff_active", false):
			slash_damage += 1
			weapon_owner["is_wine_buff_active"] = false

		_animate_discard_from_seat(weapon_owner_seat)
		_animate_showcase_card(slash_name, "%s bị buộc dùng [%s] tấn công %s!" % [weapon_owner["name"], slash_name, forced_target["name"]], slash_card)
		_add_log("🗡️ [MƯỢN GƯƠM] %s dùng [%s] tấn công %s." % [weapon_owner["name"], slash_name, forced_target["name"]])
		AudioManager.play_voice(slash_name)
		AudioManager.play_slash()
		_play_smart_card_rays(slash_name, weapon_owner_seat, [forced_target_seat])
		await _handle_slash_attack(weapon_owner_seat, forced_target_seat, slash_damage, slash_element, str(slash_card.get("suit", "")))
		return

	weapon_owner["equipped_weapon"] = ""
	if weapon_owner.has("avatar_node") and is_instance_valid(weapon_owner["avatar_node"]):
		weapon_owner["avatar_node"].set_equipment("weapon", "", "")
	var borrowed_weapon = _create_local_borrowed_weapon_card(weapon_name)
	if caster_seat == my_seat:
		_add_card_to_player_hand(borrowed_weapon)
	else:
		var caster_cards: Array = caster.get("hand_cards", [])
		caster_cards.append(borrowed_weapon)
		caster["hand_cards"] = caster_cards
		caster["hand_count"] = caster_cards.size()
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			caster["avatar_node"].update_hand_count(caster["hand_count"])
	_animate_showcase_card(weapon_name, "%s không dùng Trảm; %s nhận [%s] vào tay." % [weapon_owner["name"], caster["name"], weapon_name], borrowed_weapon)
	_add_log("🗡️ [MƯỢN GƯƠM] %s không đánh Trảm, giao [%s] cho %s." % [weapon_owner["name"], weapon_name, caster["name"]])
	AudioManager.play_skill()

func _resolve_local_thuy_trieu_rut(caster_seat: int, target_seat: int) -> void:
	if not generals_data.has(caster_seat) or not generals_data.has(target_seat):
		return
	var caster = generals_data[caster_seat]
	var giver = generals_data[target_seat]
	if not giver.get("is_alive", false) or int(giver.get("hand_count", 0)) <= 0:
		_add_log("🌊 [THỦY TRIỀU RÚT] %s không có lá bài để đưa, không có hiệu ứng." % giver.get("name", "Mục tiêu"))
		return

	var given_card: Dictionary = {}
	if target_seat == my_seat:
		thuy_trieu_rut_given_card_info.clear()
		_prompt_thuy_trieu_rut_give(target_seat, caster_seat, 40.0)
		await thuy_trieu_rut_give_finished
		given_card = thuy_trieu_rut_given_card_info.duplicate()
	else:
		var hand_cards: Array = giver.get("hand_cards", [])
		if hand_cards.is_empty():
			_add_log("🌊 [THỦY TRIỀU RÚT] Không thể xác định lá bài của %s, bỏ qua hiệu ứng cục bộ." % giver.get("name", "Mục tiêu"))
			return
		given_card = hand_cards.pop_back()
		giver["hand_cards"] = hand_cards
		giver["hand_count"] = hand_cards.size()
		if giver.has("avatar_node") and is_instance_valid(giver["avatar_node"]):
			giver["avatar_node"].update_hand_count(giver["hand_count"])

	if given_card.is_empty():
		return
	if caster_seat == my_seat:
		_add_card_to_player_hand(given_card)
	else:
		var caster_cards: Array = caster.get("hand_cards", [])
		caster_cards.append(given_card)
		caster["hand_cards"] = caster_cards
		caster["hand_count"] = caster_cards.size()
		if caster.has("avatar_node") and is_instance_valid(caster["avatar_node"]):
			caster["avatar_node"].update_hand_count(caster["hand_count"])

	_animate_showcase_card(str(given_card.get("name", "Lá bài")), "%s đưa 1 lá cho %s." % [giver.get("name", "Mục tiêu"), caster.get("name", "Người dùng")], given_card)
	if int(given_card.get("category", -1)) == 0:
		_add_log("🌊 [THỦY TRIỀU RÚT] %s đưa một Bài Cơ Bản, không so số bài và không gây sát thương Thủy." % giver.get("name", "Mục tiêu"))
		return
	if int(giver.get("hand_count", 0)) == int(caster.get("hand_count", 0)):
		_add_log("🌊 [THỦY TRIỀU RÚT] Lá đưa không phải Bài Cơ Bản, nhưng hai bên bằng số bài sau chuyển, không ai chịu sát thương.")
		return
	var victim_seat = giver["seat"] if int(giver.get("hand_count", 0)) < int(caster.get("hand_count", 0)) else caster["seat"]
	var victim = generals_data[victim_seat]
	_add_log("🌊 [THỦY TRIỀU RÚT] Lá đưa không phải Bài Cơ Bản; %s ít bài hơn sau chuyển, chịu 1 sát thương Thủy." % victim.get("name", "Mục tiêu"))
	_apply_damage_to_general(victim_seat, 1, caster_seat, "WATER")

func _handle_dai_hong_thuy_judgement(seat_num: int) -> void:
	var g = generals_data[seat_num]
	if await _maybe_local_nullify_delayed(g, "Đại Hồng Thủy", "hủy phán xét Đại Hồng Thủy"):
		g["has_dai_hong_thuy"] = false
		g["has_lightning"] = false
		g["avatar_node"].set_delayed_trick("dai_hong_thuy", false)
		return
	_add_log("🌊 [GIAI ĐOẠN PHÁN XÉT] %s đang mang [Đại Hồng Thủy]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Đại Hồng Thủy", "🌊 [Đại Hồng Thủy]: Phán xét bài Đen 2..9!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_name = _get_suit_name(j_suit)
	var rank_str = _format_rank(j_rank)

	# Điều kiện trúng Đại Hồng Thủy: Bài Đen từ 2 đến 9.
	var is_hit = (_get_card_color(j_suit) == "BLACK" and j_rank >= 2 and j_rank <= 9)
	if is_hit:
		g["has_dai_hong_thuy"] = false
		g["has_lightning"] = false
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_delayed_trick("dai_hong_thuy", false)
		_animate_showcase_card("Đại Hồng Thủy ập đến!", "🌊🌊🌊 Lật [Bài %s %s]: ĐẠI HỒNG THỦY CUỐN TRÔI %s (-3 MÁU)!" % [rank_str, suit_name, g["name"]], judge_card)
		_show_judgement_result(true, "Đại Hồng Thủy", judge_card)
		_add_log("🌊🌊🌊 [Đại Hồng Thủy] ập đến! Lật [Bài %s %s] (bài Đen 2..9) ➜ %s chịu 3 Sát Thương Thủy!" % [rank_str, suit_name, g["name"]])
		AudioManager.play_voice("Đại Hồng Thủy")
		AudioManager.play_skill()
		_apply_damage_to_general(seat_num, 3, seat_num, "WATER")
		await get_tree().create_timer(1.2).timeout
	else:
		g["has_dai_hong_thuy"] = false
		g["has_lightning"] = false
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_delayed_trick("dai_hong_thuy", false)

		var next_seat = _get_next_alive_seat(seat_num)
		if next_seat > 0 and generals_data.has(next_seat):
			var next_g = generals_data[next_seat]
			next_g["has_dai_hong_thuy"] = true
			next_g["has_lightning"] = true # Legacy state alias.
			if next_g.has("avatar_node") and is_instance_valid(next_g["avatar_node"]):
				next_g["avatar_node"].set_delayed_trick("dai_hong_thuy", true)
			_animate_showcase_card("Đại Hồng Thủy rút lui", "🌊 Phán xét [Bài %s %s] thoát hiểm! Chuyển sang %s!" % [rank_str, suit_name, next_g["name"]], judge_card)
			_show_judgement_result(false, "Đại Hồng Thủy", judge_card)
			_add_log("🌊 [Đại Hồng Thủy] Phán xét an toàn: Lật [Bài %s %s]. Lá Đại Hồng Thủy được truyền sang khu phán xét của %s (Ghế %d)!" % [rank_str, suit_name, next_g["name"], next_seat])
		else:
			_show_judgement_result(false, "Đại Hồng Thủy", judge_card)
			_add_log("🌊 [Đại Hồng Thủy] Phán xét an toàn: Lật [Bài %s %s]. Không còn tướng nhận, lá bài bị loại bỏ!" % [rank_str, suit_name])
		await get_tree().create_timer(1.0).timeout

func _handle_supply_shortage_judgement(seat_num: int) -> bool:
	var g = generals_data[seat_num]
	if await _maybe_local_nullify_delayed(g, "Cắt Đường Lương", "hủy phán xét Cắt Đường Lương"):
		g["has_cat_luong"] = false
		g["avatar_node"].set_delayed_trick("supply_shortage", false)
		return false
	_add_log("🌾 [PHÁN XÉT CẮT LƯƠNG] %s bị [Cắt Đường Lương]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Cắt Đường Lương", "🌾 Phán xét: Không phải bài Vàng -> Cấm rút bài!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_name = _get_suit_name(j_suit)
	var rank_str = _format_rank(j_rank)

	g["has_cat_luong"] = false
	if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
		g["avatar_node"].set_delayed_trick("supply_shortage", false)

	# Thoát nếu lật được bài Vàng
	var is_safe = (_get_card_color(j_suit) == "YELLOW")
	if is_safe:
		_show_judgement_result(false, "Cắt Đường Lương", judge_card)
		_animate_showcase_card("Thoát Cắt Lương", "🌾 Lật [Bài %s %s]: Thoát hiểm! Được rút bài bình thường." % [rank_str, suit_name], judge_card)
		_add_log("🌾 [Cắt Đường Lương] Thoát hiểm: Lật [Bài %s %s] (bài Vàng) -> %s được rút bài!" % [rank_str, suit_name, g["name"]])
		AudioManager.play_parry()
		await get_tree().create_timer(1.0).timeout
		return false
	else:
		_show_judgement_result(true, "Cắt Đường Lương", judge_card)
		_animate_showcase_card("Bị Cắt Lương!", "🌾 Lật [Bài %s %s]: CẤM RÚT BÀI LƯỢT NÀY!" % [rank_str, suit_name], judge_card)
		_add_log("🌾 [Cắt Đường Lương] Hiệu lực: Lật [Bài %s %s] (Không phải bài Vàng) -> %s bị tước quyền rút bài!" % [rank_str, suit_name, g["name"]])
		AudioManager.play_voice("Cắt Đường Lương")
		AudioManager.play_skill()
		await get_tree().create_timer(1.0).timeout
		return true

func _handle_acedia_judgement(seat_num: int) -> bool:
	var g = generals_data[seat_num]
	if await _maybe_local_nullify_delayed(g, "Trầm Ảo Sa Bẫy", "hủy phán xét Trầm Ảo Sa Bẫy"):
		g["has_tram_ao"] = false
		g["avatar_node"].set_delayed_trick("acedia", false)
		return false
	_add_log("🕸️ [PHÁN XÉT TRẦM ẢO] %s bị [Trầm Ảo Sa Bẫy]! Bắt đầu lật bài phán xét..." % g["name"])
	_animate_showcase_card("Trầm Ảo Sa Bẫy", "🕸️ Phán xét: Không phải bài Đỏ -> Cấm ra bài!")
	await get_tree().create_timer(1.2).timeout

	var judge_card = _draw_card_from_pile()
	var j_suit = judge_card.get("suit", "")
	var j_rank = int(judge_card.get("rank", 1))
	var suit_name = _get_suit_name(j_suit)
	var rank_str = _format_rank(j_rank)

	g["has_tram_ao"] = false
	if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
		g["avatar_node"].set_delayed_trick("acedia", false)

	# Thoát nếu lật được bài Đỏ
	var is_safe = (_get_card_color(j_suit) == "RED")
	if is_safe:
		_show_judgement_result(false, "Trầm Ảo Sa Bẫy", judge_card)
		_animate_showcase_card("Thoát Trầm Ảo", "🕸️ Lật [Bài %s %s]: Thoát bẫy! Được ra bài bình thường." % [rank_str, suit_name], judge_card)
		_add_log("🕸️ [Trầm Ảo Sa Bẫy] Thoát bẫy: Lật [Bài %s %s] (bài Đỏ) -> %s được ra bài!" % [rank_str, suit_name, g["name"]])
		AudioManager.play_parry()
		await get_tree().create_timer(1.0).timeout
		return false
	else:
		_show_judgement_result(true, "Trầm Ảo Sa Bẫy", judge_card)
		_animate_showcase_card("Sa Vào Trầm Ảo!", "🕸️ Lật [Bài %s %s]: BỎ QUA GIAI ĐOẠN RA BÀI!" % [rank_str, suit_name], judge_card)
		_add_log("🕸️ [Trầm Ảo Sa Bẫy] Hiệu lực: Lật [Bài %s %s] (Không phải bài Đỏ) -> %s mất lượt ra bài!" % [rank_str, suit_name, g["name"]])
		AudioManager.play_voice("Trầm Ảo Sa Bẫy")
		AudioManager.play_skill()
		await get_tree().create_timer(1.0).timeout
		return true

func _next_turn() -> void:
	if is_game_over:
		return
	if is_network_mode:
		return
	if generals_data.has(current_turn_seat):
		generals_data[current_turn_seat]["is_wine_buff_active"] = false
		generals_data[current_turn_seat]["wine_used_this_turn"] = false
	var next_seat = _get_next_alive_seat(current_turn_seat)
	if next_seat <= 0:
		next_seat = (current_turn_seat % battle_seat_count) + 1
	_start_turn(next_seat)

func _ensure_showcase_layer() -> void:
	if showcase_center and is_instance_valid(showcase_center):
		return
	showcase_center = CenterContainer.new()
	showcase_center.name = "ShowcaseCenter"
	showcase_center.set_anchors_preset(PRESET_FULL_RECT)
	showcase_center.mouse_filter = MOUSE_FILTER_IGNORE
	showcase_center.z_as_relative = false
	showcase_center.z_index = 280
	add_child(showcase_center)
	showcase_row = HBoxContainer.new()
	showcase_row.name = "ShowcaseRow"
	showcase_row.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase_row.add_theme_constant_override("separation", 14)
	showcase_row.mouse_filter = MOUSE_FILTER_IGNORE
	showcase_center.add_child(showcase_row)
	center_showcase.visible = false

func _make_card_display_only(card_ui: CardUI) -> void:
	if not card_ui:
		return
	card_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var click_button := card_ui.get_node_or_null("ClickButton") as Button
	if click_button:
		click_button.disabled = true
		click_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _get_showcase_card_info(c_name: String, card_info: Dictionary = {}) -> Dictionary:
	var info = card_info.duplicate()
	if not info.is_empty() and not str(info.get("name", info.get("cardName", ""))).strip_edges().is_empty():
		return info
	var info_name = str(info.get("name", info.get("cardName", "")))
	if info_name != c_name:
		var last_name = str(last_played_card_info.get("name", last_played_card_info.get("cardName", "")))
		if last_name == c_name:
			info = last_played_card_info.duplicate()
		else:
			info = {}
	if info.is_empty() and CardDatabase:
		for candidate in CardDatabase.create_deck_80():
			if str(candidate.get("name", "")) == c_name:
				info = candidate.duplicate()
				break
	if info.is_empty():
		info = {"id": "showcase", "name": c_name, "rank": 1, "suit": "Spade", "category": 0, "desc": ""}
	elif str(info.get("name", info.get("cardName", ""))).strip_edges().is_empty():
		info["name"] = c_name
	return info

func _process_showcase_queue() -> void:
	if showcase_entries.is_empty():
		return
	var now = Time.get_ticks_msec() / 1000.0
	for idx in range(showcase_entries.size() - 1, -1, -1):
		var entry = showcase_entries[idx]
		if now >= float(entry.get("expires_at", 0.0)):
			var node = entry.get("node")
			if node and is_instance_valid(node):
				node.queue_free()
			showcase_entries.remove_at(idx)
	if showcase_entries.is_empty() and showcase_center and is_instance_valid(showcase_center):
		showcase_center.visible = false

func _save_viewport_screenshot(path: String) -> void:
	if DisplayServer.get_name().to_lower().contains("headless"):
		return
	var texture = get_viewport().get_texture()
	if not texture:
		return
	var image = texture.get_image()
	if image:
		var global_path = ProjectSettings.globalize_path(path)
		image.save_png(global_path)
		print("[Screenshot] Đã lưu %s!" % global_path)

func _animate_showcase_card(c_name: String, banner_text: String, card_info: Dictionary = {}, duration_override: float = -1.0) -> void:
	_ensure_showcase_layer()
	var info = _get_showcase_card_info(c_name, card_info)
	var entry = VBoxContainer.new()
	entry.custom_minimum_size = Vector2(138, 210)
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.mouse_filter = MOUSE_FILTER_IGNORE
	entry.pivot_offset = Vector2(69, 105)
	entry.modulate.a = 0.0
	entry.scale = Vector2(0.72, 0.72)

	var card_ui = CardUIScene.instantiate()
	_make_card_display_only(card_ui)
	entry.add_child(card_ui)
	card_ui.setup_card_data(
		str(info.get("id", "showcase")),
		str(info.get("name", c_name)),
		info.get("rank", 1),
		str(info.get("suit", "Spade")),
		int(info.get("category", info.get("cat", 0))),
		str(info.get("desc", "")),
		int(info.get("subType", -1))
	)

	var banner = Label.new()
	banner.custom_minimum_size = Vector2(138, 34)
	banner.text = banner_text
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.add_theme_font_size_override("font_size", 10)
	banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	banner.mouse_filter = MOUSE_FILTER_IGNORE
	entry.add_child(banner)
	showcase_row.add_child(entry)
	var display_duration = duration_override if duration_override > 0.0 else (4.0 if "Phán xét" in banner_text or "Lật [" in banner_text else (5.0 if _is_aoe_showcase(c_name, banner_text) else 2.5))
	showcase_entries.append({
		"node": entry,
		"expires_at": Time.get_ticks_msec() / 1000.0 + display_duration
	})
	showcase_center.visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(entry, "modulate:a", 1.0, 0.16)
	tw.tween_property(entry, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _is_aoe_showcase(c_name: String, banner_text: String) -> bool:
	return c_name in ["Giặc Tới", "Mưa Tên Liên Châu"] \
		or "Giặc Tới" in banner_text \
		or "Mưa Tên Liên Châu" in banner_text

func _add_log(msg: String) -> void:
	msg = _normalize_log_markup(msg)
	history_entries.append(msg)
	if history_entries.size() > 50:
		history_entries.pop_front()
	if log_text:
		log_text.text += "\n" + msg
		log_text.scroll_to_line(log_text.get_line_count() - 1)
	if history_view and is_instance_valid(history_view):
		_render_history()

func _setup_history_ui() -> void:
	if log_panel and is_instance_valid(log_panel):
		log_panel.visible = false
	history_entries = ["📜 Bắt đầu trận chiến 2v2."]
	history_button = Button.new()
	history_button.name = "HistoryButton"
	history_button.text = "📜  NHẬT KÝ ĐẤU"
	history_button.tooltip_text = "Mở nhật ký diễn biến trận đấu"
	history_button.custom_minimum_size = Vector2(190, 40)
	history_button.set_anchors_preset(PRESET_TOP_LEFT)
	history_button.position = Vector2(18, 18)
	history_button.z_index = 40
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.055, 0.09, 0.15, 0.97)
	button_style.border_width_left = 2
	button_style.border_width_top = 2
	button_style.border_width_right = 2
	button_style.border_width_bottom = 2
	button_style.border_color = Color(0.92, 0.69, 0.24, 0.95)
	button_style.corner_radius_top_left = 6
	button_style.corner_radius_top_right = 6
	button_style.corner_radius_bottom_left = 6
	button_style.corner_radius_bottom_right = 6
	button_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	button_style.shadow_size = 6
	history_button.add_theme_stylebox_override("normal", button_style)
	var hover_style = button_style.duplicate()
	hover_style.bg_color = Color(0.12, 0.18, 0.26, 1.0)
	hover_style.border_color = Color(1.0, 0.84, 0.40, 1.0)
	history_button.add_theme_stylebox_override("hover", hover_style)
	history_button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	history_button.add_theme_font_size_override("font_size", 12)
	history_button.pressed.connect(_show_history_popup)
	add_child(history_button)

	history_popup = Control.new()
	history_popup.name = "HistoryPopup"
	history_popup.set_anchors_preset(PRESET_FULL_RECT)
	history_popup.mouse_filter = MOUSE_FILTER_STOP
	history_popup.z_as_relative = false
	history_popup.z_index = 320
	history_popup.visible = false
	add_child(history_popup)

	var dim = ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.02, 0.05, 0.82)
	dim.mouse_filter = MOUSE_FILTER_STOP
	history_popup.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)
	var panel = PanelContainer.new()
	panel.name = "HistoryPanel"
	panel.custom_minimum_size = Vector2(900, 580)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.095, 0.99)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.91, 0.70, 0.26, 0.95)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.8)
	panel_style.shadow_size = 26
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	var header = HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 38)
	vbox.add_child(header)
	var title = Label.new()
	title.text = "NHẬT KÝ TRẬN ĐẤU"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	history_count_label = Label.new()
	history_count_label.custom_minimum_size = Vector2(116, 30)
	history_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	history_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	history_count_label.add_theme_font_size_override("font_size", 11)
	history_count_label.add_theme_color_override("font_color", Color(0.70, 0.86, 1.0, 1.0))
	var count_style = StyleBoxFlat.new()
	count_style.bg_color = Color(0.08, 0.16, 0.25, 0.95)
	count_style.border_width_left = 1
	count_style.border_width_top = 1
	count_style.border_width_right = 1
	count_style.border_width_bottom = 1
	count_style.border_color = Color(0.28, 0.58, 0.88, 0.82)
	count_style.corner_radius_top_left = 5
	count_style.corner_radius_top_right = 5
	count_style.corner_radius_bottom_left = 5
	count_style.corner_radius_bottom_right = 5
	history_count_label.add_theme_stylebox_override("normal", count_style)
	header.add_child(history_count_label)
	var clear = Button.new()
	clear.text = "XÓA"
	clear.tooltip_text = "Xóa toàn bộ nhật ký trận đấu"
	clear.custom_minimum_size = Vector2(54, 30)
	clear.add_theme_font_size_override("font_size", 10)
	clear.pressed.connect(_clear_history)
	header.add_child(clear)
	var close = Button.new()
	close.text = "X"
	close.tooltip_text = "Đóng nhật ký"
	close.custom_minimum_size = Vector2(34, 30)
	close.pressed.connect(_hide_history_popup)
	header.add_child(close)
	var sep = HSeparator.new()
	vbox.add_child(sep)
	history_scroll = ScrollContainer.new()
	history_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(history_scroll)
	history_list = VBoxContainer.new()
	history_list.name = "HistoryEventList"
	history_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history_list.add_theme_constant_override("separation", 6)
	history_scroll.add_child(history_list)
	_render_history()
	dim.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and not panel.get_global_rect().has_point(event.position):
			_hide_history_popup()
	)

func _history_event_tone(message: String) -> Dictionary:
	var content = message.to_lower()
	if "phán xét" in content or "bãi cọc" in content or "đại hồng thủy" in content:
		return {"tag": "PHÁN XÉT", "accent": Color(0.34, 0.78, 1.0, 1.0), "surface": Color(0.045, 0.13, 0.22, 0.96)}
	if "sát thương" in content or "mất " in content or "chết" in content or "thất bại" in content:
		return {"tag": "GIAO TRANH", "accent": Color(1.0, 0.34, 0.28, 1.0), "surface": Color(0.20, 0.045, 0.055, 0.96)}
	if "hồi" in content or "bánh chưng" in content or "đỡ" in content or "thoát" in content:
		return {"tag": "HỖ TRỢ", "accent": Color(0.34, 0.95, 0.62, 1.0), "surface": Color(0.035, 0.18, 0.12, 0.96)}
	if "lượt" in content or "rút" in content or "bỏ" in content:
		return {"tag": "DIỄN BIẾN", "accent": Color(1.0, 0.76, 0.28, 1.0), "surface": Color(0.20, 0.13, 0.035, 0.96)}
	return {"tag": "HỆ THỐNG", "accent": Color(0.60, 0.70, 0.86, 1.0), "surface": Color(0.075, 0.105, 0.16, 0.96)}

func _history_plain_text(message: String) -> String:
	var plain := _normalize_log_markup(message)
	plain = plain.replace("[b]", "").replace("[/b]", "")
	var tag_re = RegEx.new()
	tag_re.compile("\\[[^\\]]+\\]")
	return tag_re.sub(plain, "", true)

func _normalize_log_markup(message: String) -> String:
	var normalized := message
	normalized = normalized.replace("<b>", "[b]").replace("</b>", "[/b]")
	var color_re = RegEx.new()
	color_re.compile("<color=([^>]+)>")
	normalized = color_re.sub(normalized, "[color=$1]", true)
	normalized = normalized.replace("</color>", "[/color]")
	var html_re = RegEx.new()
	html_re.compile("<[^>]+>")
	return html_re.sub(normalized, "", true)

func _render_history() -> void:
	if history_count_label and is_instance_valid(history_count_label):
		history_count_label.text = "%d SỰ KIỆN" % history_entries.size()
	if not history_list or not is_instance_valid(history_list):
		return
	for child in history_list.get_children():
		child.queue_free()
	for index in range(history_entries.size()):
		var tone = _history_event_tone(history_entries[index])
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 52)
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = tone["surface"]
		row_style.border_width_left = 4
		row_style.border_width_top = 1
		row_style.border_width_right = 1
		row_style.border_width_bottom = 1
		row_style.border_color = Color(tone["accent"].r, tone["accent"].g, tone["accent"].b, 0.68)
		row_style.corner_radius_top_left = 5
		row_style.corner_radius_top_right = 5
		row_style.corner_radius_bottom_left = 5
		row_style.corner_radius_bottom_right = 5
		row.add_theme_stylebox_override("panel", row_style)
		history_list.add_child(row)

		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 10)
		row_margin.add_theme_constant_override("margin_top", 7)
		row_margin.add_theme_constant_override("margin_right", 12)
		row_margin.add_theme_constant_override("margin_bottom", 7)
		row.add_child(row_margin)
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		row_margin.add_child(line)

		var sequence = Label.new()
		sequence.text = "%02d" % (index + 1)
		sequence.custom_minimum_size = Vector2(30, 0)
		sequence.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sequence.add_theme_font_size_override("font_size", 11)
		sequence.add_theme_color_override("font_color", Color(0.62, 0.70, 0.82, 1.0))
		line.add_child(sequence)
		var tag = Label.new()
		tag.text = str(tone["tag"])
		tag.custom_minimum_size = Vector2(82, 0)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 10)
		tag.add_theme_color_override("font_color", tone["accent"])
		line.add_child(tag)
		var event_text = Label.new()
		event_text.text = _history_plain_text(history_entries[index])
		event_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		event_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		event_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		event_text.add_theme_font_size_override("font_size", 13)
		event_text.add_theme_color_override("font_color", Color(0.91, 0.94, 0.98, 1.0))
		line.add_child(event_text)
	call_deferred("_scroll_history_to_bottom")

func _scroll_history_to_bottom() -> void:
	if history_scroll and is_instance_valid(history_scroll):
		history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)

func _clear_history() -> void:
	history_entries.clear()
	_render_history()

func _show_history_popup() -> void:
	if history_popup and is_instance_valid(history_popup):
		history_popup.visible = true
		_render_history()

func _hide_history_popup() -> void:
	if history_popup and is_instance_valid(history_popup):
		history_popup.visible = false

func _create_judgement_visual_effect(root: Control, judgement_name: String, is_success: bool, rank: int) -> void:
	# The reveal card stays readable while each judgement gets a short, distinct battlefield cue.
	var effect = Control.new()
	effect.name = "JudgementVisualEffect"
	effect.set_anchors_preset(PRESET_FULL_RECT)
	effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.z_index = -1
	root.add_child(effect)

	var title = judgement_name.to_lower()
	var accent = Color(0.3, 0.8, 1.0, 0.85)
	var fill = Color(0.04, 0.14, 0.24, 0.42)
	var glow = Color(0.25, 0.72, 1.0, 0.48)
	var burst_count = 8
	var burst_distance = 250.0
	var is_bai_coc = "bãi cọc" in title or "bai coc" in title

	if is_bai_coc:
		accent = Color(0.42, 0.95, 0.72, 0.9) if is_success else Color(1.0, 0.26, 0.18, 0.95)
		fill = Color(0.02, 0.22, 0.23, 0.52) if is_success else Color(0.20, 0.035, 0.025, 0.58)
		glow = Color(0.08, 0.8, 0.68, 0.58) if is_success else Color(1.0, 0.14, 0.08, 0.62)
		burst_count = 12
		burst_distance = 300.0
	elif "đại hồng thủy" in title:
		accent = Color(0.26, 0.78, 1.0, 0.9)
		fill = Color(0.025, 0.10, 0.28, 0.52)
		glow = Color(0.12, 0.56, 1.0, 0.62)
		burst_count = 10
	elif "cắt đường lương" in title:
		accent = Color(1.0, 0.77, 0.2, 0.92)
		fill = Color(0.27, 0.13, 0.015, 0.50)
		glow = Color(1.0, 0.57, 0.08, 0.60)
	elif "trầm ảo" in title or "sa bẫy" in title:
		accent = Color(0.98, 0.35, 0.77, 0.92)
		fill = Color(0.20, 0.025, 0.28, 0.52)
		glow = Color(0.84, 0.18, 0.72, 0.60)
	elif "khiên mây" in title:
		accent = Color(0.48, 0.96, 0.74, 0.9) if is_success else Color(1.0, 0.36, 0.38, 0.92)
		fill = Color(0.04, 0.22, 0.19, 0.46) if is_success else Color(0.24, 0.035, 0.06, 0.52)
		glow = Color(0.30, 0.92, 0.68, 0.56) if is_success else Color(1.0, 0.22, 0.26, 0.56)

	var wash = ColorRect.new()
	wash.set_anchors_preset(PRESET_FULL_RECT)
	wash.color = fill
	wash.modulate.a = 0.0
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.add_child(wash)

	var halo = Panel.new()
	halo.set_anchors_preset(PRESET_CENTER)
	halo.offset_left = -135
	halo.offset_top = -135
	halo.offset_right = 135
	halo.offset_bottom = 135
	halo.pivot_offset = Vector2(135, 135)
	halo.modulate.a = 0.0
	halo.scale = Vector2(0.25, 0.25)
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var halo_style = StyleBoxFlat.new()
	halo_style.bg_color = Color(glow.r, glow.g, glow.b, 0.17)
	halo_style.border_width_left = 4
	halo_style.border_width_top = 4
	halo_style.border_width_right = 4
	halo_style.border_width_bottom = 4
	halo_style.border_color = accent
	halo_style.corner_radius_top_left = 135
	halo_style.corner_radius_top_right = 135
	halo_style.corner_radius_bottom_right = 135
	halo_style.corner_radius_bottom_left = 135
	halo_style.shadow_color = glow
	halo_style.shadow_size = 28
	halo.add_theme_stylebox_override("panel", halo_style)
	effect.add_child(halo)

	var vfx_center = Control.new()
	vfx_center.set_anchors_preset(PRESET_CENTER)
	vfx_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect.add_child(vfx_center)

	var tw = create_tween()
	tw.tween_property(wash, "modulate:a", 1.0, 0.16)
	tw.parallel().tween_property(halo, "modulate:a", 1.0, 0.10)
	tw.parallel().tween_property(halo, "scale", Vector2(1.28, 1.28), 0.54).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(halo, "modulate:a", 0.0, 0.38).set_delay(0.18)
	tw.parallel().tween_property(wash, "modulate:a", 0.0, 0.45).set_delay(0.44)
	tw.tween_callback(effect.queue_free)

	# Bãi Cọc exposes the stakes before they surge inward; the other cards emit their theme-colored judgement burst.
	if is_bai_coc:
		for i in range(11):
			var stake = Panel.new()
			var stake_width = 9.0 + float(i % 3) * 2.0
			var stake_height = 54.0 + float((i * 17) % 42)
			stake.size = Vector2(stake_width, stake_height)
			stake.position = Vector2(-122.0 + float(i) * 24.0, 148.0 + float(i % 2) * 14.0)
			stake.pivot_offset = Vector2(stake_width * 0.5, stake_height)
			stake.rotation = -0.22 + float(i % 4) * 0.14
			stake.modulate.a = 0.0
			stake.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var stake_style = StyleBoxFlat.new()
			stake_style.bg_color = Color(0.30, 0.13, 0.035, 0.96)
			stake_style.border_width_left = 2
			stake_style.border_width_top = 2
			stake_style.border_width_right = 2
			stake_style.border_width_bottom = 2
			stake_style.border_color = accent
			stake_style.corner_radius_top_left = 4
			stake_style.corner_radius_top_right = 4
			stake_style.shadow_color = glow
			stake_style.shadow_size = 9
			stake.add_theme_stylebox_override("panel", stake_style)
			vfx_center.add_child(stake)
			tw.parallel().tween_property(stake, "modulate:a", 1.0, 0.12).set_delay(0.04 + float(i % 3) * 0.035)
			tw.parallel().tween_property(stake, "position:y", stake.position.y - (82.0 if is_success else 122.0), 0.34).set_delay(0.08 + float(i % 3) * 0.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(stake, "rotation", stake.rotation * 0.25, 0.34).set_delay(0.08 + float(i % 3) * 0.035)
			tw.parallel().tween_property(stake, "modulate:a", 0.0, 0.26).set_delay(0.78)
	else:
		for i in range(burst_count):
			var shard = ColorRect.new()
			var shard_size = 5.0 + float(i % 3) * 3.0
			shard.size = Vector2(shard_size, shard_size * (1.8 if i % 2 == 0 else 1.0))
			shard.position = Vector2(-shard_size * 0.5, -shard_size * 0.5)
			shard.pivot_offset = shard.size * 0.5
			shard.color = accent
			shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vfx_center.add_child(shard)
			var angle = TAU * float(i) / float(burst_count) + 0.16 * float(rank % 3)
			var target = Vector2(cos(angle), sin(angle)) * (burst_distance * (0.68 + float(i % 4) * 0.09))
			tw.parallel().tween_property(shard, "position", target, 0.46).set_delay(0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(shard, "rotation", angle + 1.4, 0.46).set_delay(0.06)
			tw.parallel().tween_property(shard, "modulate:a", 0.0, 0.30).set_delay(0.28)

func _show_judgement_result(is_success: bool, judgement_name: String = "", judge_card: Dictionary = {}) -> Tween:
	if "bãi cọc" in judgement_name.to_lower() or "bai coc" in judgement_name.to_lower():
		var now_msec := Time.get_ticks_msec()
		var judgement_signature := "%s|%s|%s" % [
			str(judge_card.get("id", judge_card.get("name", ""))),
			str(judge_card.get("suit", "")),
			str(judge_card.get("rank", ""))
		]
		if judgement_signature == last_bai_coc_judgement_signature and now_msec - last_bai_coc_judgement_at_msec < BAI_COC_JUDGEMENT_DEDUPE_MSEC:
			return null
		last_bai_coc_judgement_signature = judgement_signature
		last_bai_coc_judgement_at_msec = now_msec
		bai_coc_judgement_visual_until_msec = now_msec + BAI_COC_JUDGEMENT_VISUAL_MSEC
	var existing = get_node_or_null("JudgementRevealRoot")
	if existing and is_instance_valid(existing):
		existing.queue_free()

	# Tạo container trung tâm hiển thị lá bài phán xét bay ra
	var root = Control.new()
	root.name = "JudgementRevealRoot"
	root.set_anchors_preset(PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_as_relative = false
	root.z_index = 330
	add_child(root)

	var effect_rank = int(judge_card.get("rank", 1))
	_create_judgement_visual_effect(root, judgement_name, is_success, effect_rank)

	# 1. Hộp trung tâm chứa Title, CardUI, và Stamp kết quả
	var center = VBoxContainer.new()
	center.name = "JudgementCenter"
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.set_anchors_preset(PRESET_CENTER)
	center.offset_left = -110
	center.offset_top = -160
	center.offset_right = 110
	center.offset_bottom = 160
	center.pivot_offset = Vector2(110, 160)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.modulate.a = 0.0
	center.scale = Vector2(0.3, 0.3)
	center.rotation = -0.15
	root.add_child(center)

	# Tiêu đề phán xét
	var j_title = judgement_name if not judgement_name.is_empty() else "PHÁN XÉT"
	var title_lbl = Label.new()
	title_lbl.text = "🪵 BÃI CỌC BẠCH ĐẰNG\n📜 PHÁN XÉT" if ("Bãi Cọc" in j_title and not is_success) else "📜 PHÁN XÉT: %s" % j_title.to_upper()
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.06, 0.95))
	title_lbl.add_theme_constant_override("outline_size", 5)
	center.add_child(title_lbl)

	# Lá bài bay ra (CardUI)
	var card_container = Control.new()
	card_container.custom_minimum_size = Vector2(140, 195)
	card_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(card_container)

	var card_ui = CardUIScene.instantiate()
	_make_card_display_only(card_ui)
	card_container.add_child(card_ui)

	var c_name = str(judge_card.get("name", "Bài Phán Xét"))
	var raw_suit = str(judge_card.get("suit", "")).strip_edges().to_lower()
	var c_suit = "Heart"
	if raw_suit in ["heart", "co", "cơ"]:
		c_suit = "Heart"
	elif raw_suit in ["diamond", "ro", "rô"]:
		c_suit = "Diamond"
	elif raw_suit in ["spade", "bich", "bích"]:
		c_suit = "Spade"
	elif raw_suit in ["club", "tep", "chuon", "tép", "chuồn"]:
		c_suit = "Club"
	elif raw_suit.capitalize() in ["Heart", "Diamond", "Spade", "Club"]:
		c_suit = raw_suit.capitalize()
	var c_rank = int(judge_card.get("rank", 1))
	var c_desc = "Lá bài rút từ chồng bài để phán xét %s" % j_title
	card_ui.setup_card_data(
		str(judge_card.get("id", "judge_card")),
		c_name,
		c_rank,
		c_suit,
		0,
		c_desc
	)

	# 2. Xác định nội dung Con Dấu (Stamp) dựa trên loại phán xét và kết quả
	var is_red = (c_suit == "Heart" or c_suit == "Diamond")
	var stamp_text = "✓ AN TOÀN"
	var stamp_is_green = true

	if "Bãi Cọc" in j_title:
		if is_red:
			stamp_text = "✓ AN TOÀN"
			stamp_is_green = true
		else:
			stamp_text = "✗ SẬP BẪY (-1 MÁU)"
			stamp_is_green = false
	elif "Khiên Mây" in j_title:
		if is_red:
			stamp_text = "✓ ĐỠ THÀNH CÔNG"
			stamp_is_green = true
		else:
			stamp_text = "✗ THẤT BẠI"
			stamp_is_green = false
	elif "Đại Hồng Thủy" in j_title:
		if c_suit == "Spade" and c_rank >= 2 and c_rank <= 9:
			stamp_text = "💥 TRÚNG BÃO LŨ (-3 MÁU)"
			stamp_is_green = false
		else:
			stamp_text = "✓ AN TOÀN (CHUYỂN)"
			stamp_is_green = true
	elif "Cắt Đường Lương" in j_title:
		if c_suit == "Club":
			stamp_text = "✓ THOÁT NẠN"
			stamp_is_green = true
		else:
			stamp_text = "✗ BỎ RÚT BÀI"
			stamp_is_green = false
	elif "Sa Bẫy" in j_title or "Trầm Ảo" in j_title:
		if c_suit == "Heart":
			stamp_text = "✓ THOÁT BẪY"
			stamp_is_green = true
		else:
			stamp_text = "✗ BỎ RA BÀI"
			stamp_is_green = false
	else:
		stamp_text = "✓ ĐẠT" if is_success else "✗ TRƯỢT"
		stamp_is_green = is_success

	# 3. Panel Con Dấu (Stamp) dập lên mặt lá bài
	var stamp_panel = PanelContainer.new()
	stamp_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stamp_style = StyleBoxFlat.new()
	stamp_style.bg_color = Color(0.04, 0.1, 0.04, 0.94) if stamp_is_green else Color(0.15, 0.02, 0.02, 0.94)
	stamp_style.border_width_left = 3
	stamp_style.border_width_top = 3
	stamp_style.border_width_right = 3
	stamp_style.border_width_bottom = 3
	stamp_style.border_color = Color(0.2, 1.0, 0.4, 1.0) if stamp_is_green else Color(1.0, 0.25, 0.25, 1.0)
	stamp_style.corner_radius_top_left = 8
	stamp_style.corner_radius_top_right = 8
	stamp_style.corner_radius_bottom_left = 8
	stamp_style.corner_radius_bottom_right = 8
	stamp_panel.add_theme_stylebox_override("panel", stamp_style)
	stamp_panel.set_anchors_preset(PRESET_CENTER)
	stamp_panel.offset_left = -110
	stamp_panel.offset_top = -25
	stamp_panel.offset_right = 110
	stamp_panel.offset_bottom = 25
	stamp_panel.pivot_offset = Vector2(110, 25)
	stamp_panel.modulate.a = 0.0
	stamp_panel.scale = Vector2(2.5, 2.5)
	stamp_panel.rotation = -0.08
	card_container.add_child(stamp_panel)

	var stamp_lbl = Label.new()
	stamp_lbl.text = stamp_text
	stamp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp_lbl.add_theme_font_size_override("font_size", 13)
	stamp_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45, 1.0) if stamp_is_green else Color(1.0, 0.35, 0.35, 1.0))
	stamp_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	stamp_lbl.add_theme_constant_override("outline_size", 4)
	stamp_panel.add_child(stamp_lbl)

	# 4. Âm thanh hiệu ứng
	if stamp_is_green:
		if "Bãi Cọc" in j_title:
			AudioManager.play_card_sound("Bãi Cọc Bạch Đằng")
		AudioManager.play_exp_tick(1.15, 2.0)
	else:
		if "Bãi Cọc" in j_title:
			AudioManager.play_damage()
		AudioManager.play_skill()

	# 5. Hoạt ảnh bài bay ra & con dấu dập xuống
	var tw = create_tween()
	tw.tween_property(center, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(center, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(center, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_SINE)
	tw.tween_property(center, "scale", Vector2(1.0, 1.0), 0.08)

	tw.tween_property(stamp_panel, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(stamp_panel, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	# Keep every judgement visible one second longer so all players can read the result.
	tw.tween_interval(3.2)
	tw.tween_property(root, "modulate:a", 0.0, 0.3)
	tw.tween_callback(root.queue_free)
	return tw

func _show_general_info_modal(seat_num: int) -> void:
	var g = generals_data.get(seat_num, null)
	if not g:
		return
	if general_info_modal.has_method("display_general"):
		general_info_modal.display_general(g, my_seat)
	else:
		general_info_modal.visible = true

func _hide_general_info_modal() -> void:
	if general_info_modal.has_method("close_modal"):
		general_info_modal.close_modal()
	else:
		general_info_modal.visible = false

func _get_equipment_description(item_name: String) -> String:
	match item_name:
		"Kiếm Thuận Thiên": return "Tầm 2; Trảm bỏ qua giáp mục tiêu."
		"Song Cung Mường Nhạ": return "Tầm 2; Trảm bị Đỡ, bỏ 2 lá để bỏ qua Đỡ; Trảm vẫn gây sát thương."
		"Nỏ Thần Kim Quy": return "Tầm 1; không giới hạn số lá Trảm trong lượt."
		"Trường Đao Nam Sơn": return "Tầm 3; khi Trảm bị Đỡ, xem như chưa sử dụng lượt Trảm trong lượt chơi này."
		"Thương Ngâu Lãng Bạc": return "Tầm 4; Trảm trúng hủy 1 lá tay hoặc trang bị."
		"Súng Thần Công Hồ Triều": return "Tầm 5; mục tiêu không được dùng Đỡ cùng màu với Trảm."
		"Hỏa Mai Tây Sơn": return "Tầm 4; Trảm Thường có thể xem như Trảm Hỏa."
		"Liêm Đao Đống Đa": return "Tầm 2; lần đầu mỗi lượt gây sát thương, rút 1 lá."
		"Đoản Đao Lam Sơn": return "Tầm 2; Trảm trúng có thể hủy 2 lá trên tay hoặc trang bị của mục tiêu thay vì gây sát thương."
		"Giáp Đồng Sơn Vi": return "Vô hiệu hóa Trảm Thường."
		"Giáp Tây Sơn": return "Vô hiệu hóa mọi Trảm bài Đen hoặc bài Vàng."
		"Khiên Mây Bện": return "Khi cần Đỡ: phán xét bài Đỏ hoặc bài Trắng tự động Đỡ, bài Vàng hoặc bài Đen thất bại."
		"Áo Bào Hoàng Tộc": return "Chặn tối đa 2 sát thương, rồi bị hủy."
		"Voi Chiến Đại Việt": return "Ngựa Thủ: +1 khoảng cách từ người khác tới bạn."
		"Ngựa Trắng Thuần Nông": return "Ngựa Công: -1 khoảng cách từ bạn tới người khác."
		"Thuyền Bạch Đằng": return "Ngựa Công: Trảm Thủy bỏ qua khoảng cách."
		"Trống Đồng Đông Sơn": return "Điểm Trống: mục tiêu bỏ 1 lá hoặc lộ bài."
		"Hổ Phù Trần Triều": return "Mỗi lượt đưa 1 lá trên tay cho người khác; nếu họ dùng trước lượt kế tiếp, bạn rút 1 lá."
		_: return "Hiệu ứng trang bị."

# ==========================================================
# 🌪️ CẨM NANG DIỆN RỘNG (AOE): BÃI CỌC NGẦM & MƯA TÊN LIÊN CHÂU
# ==========================================================
func _execute_aoe_attack(caster_seat: int, aoe_name: String, required_card_name: String, damage_amount: int = 1) -> void:
	var caster = generals_data.get(caster_seat, {})
	var caster_name = caster.get("name", "Tướng")
	var incoming_damage = max(1, damage_amount)

	var victims_order: Array = []
	for i in range(1, 4):
		var s = ((caster_seat - 1 + i) % battle_seat_count) + 1
		if generals_data.has(s) and generals_data[s]["is_alive"]:
			victims_order.append(s)

	_add_log("🌪️ <b>%s</b> phát động [%s]! Lần lượt kiểm tra các tướng theo chiều kim đồng hồ..." % [caster_name, aoe_name])

	for target_seat in victims_order:
		if is_game_over:
			break
		var tgt = generals_data[target_seat]
		if not tgt["is_alive"] or tgt["hp"] <= 0:
			continue

		# 1. Kiểm tra Miễn Nhiễm Tướng đối với Giặc Tới (Nam Man Nhập Xâm):
		# Phạm Tu (Hero 13 - Khang Dũng), Ngô Quyền (Hero 22 - Thủy Trận), Yết Kiêu (Hero 60 - Thủy Chiến)
		if aoe_name == "Giặc Tới":
			var hero_id = tgt.get("hero_id", -1)
			if hero_id in [13, 22, 60]:
				var skill_reason = "Khang Dũng" if hero_id == 13 else ("Thủy Trận" if hero_id == 22 else "Thủy Chiến")
				_animate_showcase_card("Miễn Nhiễm", "%s miễn nhiễm Giặc Tới nhờ [%s]!" % [tgt["name"], skill_reason])
				_add_log("🛡️ [Miễn Nhiễm] %s miễn nhiễm sát thương từ [Giặc Tới] nhờ kỹ năng [%s]!" % [tgt["name"], skill_reason])
				await get_tree().create_timer(0.6).timeout
				continue

		# Hỏi Diệu Kế riêng cho từng nạn nhân trước khi hỏi lá phản ứng AOE.
		if await _maybe_local_nullify_delayed(tgt, aoe_name, "hủy tác động riêng lên %s" % tgt["name"]):
			_add_log("🛡️ Diệu Kế Phá Mưu đã hủy tác động [%s] lên %s." % [aoe_name, tgt["name"]])
			await get_tree().create_timer(0.4).timeout
			continue

		# 2. Phản ứng: Người chơi thật (Luôn cho người chơi tự chọn)
		if target_seat == my_seat or tgt.get("isPlayer", false):
			var is_giac_toi = aoe_name == "Giặc Tới"
			var prompt_title = "🪵 TRẢM GIẶC TỚI" if is_giac_toi else "🏹 NÉ MƯA TÊN LIÊN CHÂU"
			var prompt_desc = "⚠️ %s vừa dùng [Giặc Tới]!\nHãy chạm chọn 1 lá [Trảm] trên tay để Trảm Giặc hoặc bấm [CHỊU ĐÒN]:" % caster_name if is_giac_toi else "⚠️ %s vừa dùng [%s]!\nHãy chạm chọn 1 lá [%s] trên tay để hóa giải hoặc bấm [CHỊU ĐÒN]:" % [caster_name, aoe_name, required_card_name]
			if aoe_name == "Mưa Tên Liên Châu" and "Khiên Mây" in tgt.get("equipped_armor", ""):
				prompt_desc = "⚠️ %s vừa dùng [Mưa Tên Liên Châu]!\nBạn có thể [🎲 LẬT KHIÊN MÂY], chạm chọn lá [Đỡ] trên tay để né hoặc [💥 CHỊU ĐÒN]:" % caster_name

			var pass_btn_txt = _format_damage_pass_text(incoming_damage)
			var confirm_btn_txt = "⚔️ DÙNG [TRẢM] TRẢM GIẶC" if is_giac_toi else "🛡️ ĐÁNH [ĐỠ] ĐỂ NÉ"

			dodge_attacker_seat = caster_seat
			is_current_reaction_slash = false

			var satisfied = await _prompt_custom_reaction_async(
				prompt_title,
				prompt_desc,
				required_card_name,
				pass_btn_txt,
				confirm_btn_txt,
				40.0
			)

			if satisfied:
				_animate_showcase_card(required_card_name, "Bạn né [%s] thành công!" % aoe_name, last_custom_reaction_card_info)
				_add_log("🛡️ Bạn đã né [%s] thành công!" % aoe_name)
				AudioManager.play_voice("Trảm" if is_giac_toi else (required_card_name if AudioManager.has_voice(required_card_name) else "Đỡ"))
				AudioManager.play_parry()
			else:
				_add_log("💥 Bạn không đánh lá [%s], chịu %d sát thương từ [%s]!" % [required_card_name, incoming_damage, aoe_name])
				_apply_damage_to_general(target_seat, incoming_damage, caster_seat, "NORMAL")
			await get_tree().create_timer(0.6).timeout

		# 3. Phản ứng: Bot AI
		else:
			# AI kiểm tra Khiên Mây Bện nếu là Mưa Tên Liên Châu
			if aoe_name == "Mưa Tên Liên Châu" and "Khiên Mây" in tgt.get("equipped_armor", ""):
				var judge_card = _draw_card_from_pile()
				var is_red = (_get_card_color(judge_card.get("suit", "")) in ["RED", "WHITE"])
				var suit_name = _get_suit_name(judge_card.get("suit", ""))
				var rank_str = _format_rank(judge_card.get("rank", 1))
				if is_red:
					_animate_showcase_card("Khiên Mây Bện", "%s lật [Bài %s %s] (Bài Đỏ/Bài Trắng) -> Đỡ Mưa Tên!" % [tgt["name"], rank_str, suit_name], judge_card)
					_play_armor_effect(target_seat, "Khiên Mây Bện", true)
					AudioManager.play_voice("Khiên Mây Bện")
					_show_judgement_result(true, "Khiên Mây Bện", judge_card)
					_add_log("🛡️ [Khiên Mây Bện] của %s lật [Bài %s %s] (Bài Đỏ/Bài Trắng) -> Tự động Đỡ Mưa Tên thành công!" % [tgt["name"], rank_str, suit_name])
					AudioManager.play_parry()
					await get_tree().create_timer(0.8).timeout
					continue
				else:
					_animate_showcase_card("Khiên Mây Bện", "%s lật [Bài %s %s] (Bài Vàng/Bài Đen) -> Phán xét thất bại!" % [tgt["name"], rank_str, suit_name], judge_card)
					_play_armor_effect(target_seat, "Khiên Mây Bện", false)
					AudioManager.play_voice("Khiên Mây Bện")
					_show_judgement_result(false, "Khiên Mây Bện", judge_card)
					_add_log("🛡️ [Khiên Mây Bện] của %s lật [Bài %s %s] (Bài Vàng/Bài Đen) -> Phán xét thất bại!" % [tgt["name"], rank_str, suit_name])
					await get_tree().create_timer(0.5).timeout

			await get_tree().create_timer(0.8).timeout
			var matched_idx = -1
			for idx in range(tgt["hand_cards"].size()):
				var c = tgt["hand_cards"][idx]
				var c_name = c.get("name", "").to_lower()
				if aoe_name == "Giặc Tới":
					if "trảm" in c_name:
						matched_idx = idx
						break
				else:
					if "đỡ" in c_name:
						matched_idx = idx
						break

			if matched_idx >= 0:
				var used_c = tgt["hand_cards"][matched_idx]
				tgt["hand_cards"].remove_at(matched_idx)
				tgt["hand_count"] = tgt["hand_cards"].size()
				tgt["avatar_node"].update_hand_count(tgt["hand_count"])
				_animate_showcase_card(required_card_name, "%s dùng [%s] né [%s]!" % [tgt["name"], required_card_name, aoe_name], used_c)
				_add_log("🛡️ %s đã đánh 1 lá [%s] né [%s]!" % [tgt["name"], required_card_name, aoe_name])
				AudioManager.play_voice(required_card_name)
				AudioManager.play_parry()
			else:
				_add_log("💥 %s không có lá [%s], chịu %d sát thương từ [%s]!" % [tgt["name"], required_card_name, incoming_damage, aoe_name])
				_apply_damage_to_general(target_seat, incoming_damage, caster_seat, "NORMAL")
			await get_tree().create_timer(0.6).timeout

# ==========================================================
# ⚔️ HUYẾT CHIẾN (DUEL): ĐỐI KHÁNG 1v1 LUÂN PHIÊN ĐÁNH TRẢM
# ==========================================================
func _execute_duel(caster_seat: int, target_seat: int) -> void:
	var caster = generals_data.get(caster_seat, {})
	var target = generals_data.get(target_seat, {})
	var caster_name = caster.get("name", "Tướng")
	var target_name = target.get("name", "Tướng")

	_animate_showcase_card("Huyết Chiến", "⚔️ HUYẾT CHIẾN: %s ⚔️ %s!" % [caster_name, target_name])
	_add_log("⚔️ <b>HUYẾT CHIẾN PHÁT ĐỘNG!</b> %s huyết chiến %s! Hai bên luân phiên đánh Trảm." % [caster_name, target_name])
	AudioManager.play_voice("Huyết Chiến")
	AudioManager.play_slash()

	var current_duelist = target_seat
	var other_duelist = caster_seat
	var duel_ended = false
	var phuc_ho_seat := 0
	for duel_seat in [caster_seat, target_seat]:
		if generals_data.has(duel_seat) and _hero_has_skill(generals_data[duel_seat], "phuc_ho"):
			phuc_ho_seat = duel_seat
			break

	while not duel_ended and not is_game_over:
		var cur_gen = generals_data.get(current_duelist, {})
		var oth_gen = generals_data.get(other_duelist, {})
		if not cur_gen.get("is_alive", false) or not oth_gen.get("is_alive", false):
			break

		var played_slash = false
		var required_slashes := 2 if phuc_ho_seat > 0 and current_duelist != phuc_ho_seat else 1
		for slash_index in range(required_slashes):
			if not cur_gen.get("is_alive", false) or not oth_gen.get("is_alive", false):
				break

			var slash_played := false
			if cur_gen["isPlayer"]:
				slash_played = await _prompt_custom_reaction_async(
				"⚔️ HUYẾT CHIẾN ĐỐI KHÁNG",
				"⚠️ Đến lượt bạn đáp trả [TRẢM] trong Huyết Chiến với %s!\nHãy chọn 1 lá Trảm hoặc bấm [NHẬN THUA].%s" % [oth_gen["name"], "\n🐯 Cần dùng hai lá Trảm mỗi lượt Huyết Chiến do kỹ năng Phục Hổ của Phùng Hưng." if required_slashes > 1 else ""],
				"Trảm",
				_format_damage_pass_text(1, "NHẬN THUA"),
				"⚔️ ĐÁP TRẢ [TRẢM]",
				40.0
				)
			else:
				await get_tree().create_timer(0.9).timeout
				var s_idx = -1
				for idx in range(cur_gen["hand_cards"].size()):
					if "trảm" in cur_gen["hand_cards"][idx].get("name", "").to_lower():
						s_idx = idx
						break
				if s_idx >= 0:
					var s_card = cur_gen["hand_cards"][s_idx]
					cur_gen["hand_cards"].remove_at(s_idx)
					cur_gen["hand_count"] = cur_gen["hand_cards"].size()
					cur_gen["avatar_node"].update_hand_count(cur_gen["hand_count"])
					_animate_showcase_card("Trảm", "%s đáp trả [Trảm] trong Huyết Chiến!" % cur_gen["name"], s_card)
					_add_log("⚔️ %s đáp trả 1 lá [Trảm] trong Huyết Chiến!" % cur_gen["name"])
					AudioManager.play_voice("Trảm")
					AudioManager.play_slash()
					slash_played = true
			if slash_played:
				played_slash = true
				if cur_gen["isPlayer"]:
					_animate_showcase_card("Trảm", "Bạn đáp trả 1 lá [Trảm] trong Huyết Chiến!", last_custom_reaction_card_info)
					_add_log("⚔️ Bạn đáp trả 1 lá [Trảm] trong Huyết Chiến!")
					AudioManager.play_voice("Trảm")
					AudioManager.play_slash()
			else:
				played_slash = false

		if played_slash:
			var temp = current_duelist
			current_duelist = other_duelist
			other_duelist = temp
			await get_tree().create_timer(0.5).timeout
		else:
			duel_ended = true
			_add_log("💥 <b>%s</b> hết Trảm đáp trả, thất bại trong Huyết Chiến và mất 1 Máu!" % cur_gen["name"])
			_animate_showcase_card("Thất Bại Huyết Chiến", "%s thất bại trong Huyết Chiến!" % cur_gen["name"])
			_apply_damage_to_general(current_duelist, 1, other_duelist, "NORMAL")
			await get_tree().create_timer(0.6).timeout

# ==========================================================
# 🌾 MỞ KHO CỨU TẾ: CHIA ĐỀU BÀI CHO TOÀN BỘ NGƯỜI CHƠI
# ==========================================================
func _execute_harvest(caster_seat: int) -> void:
	var caster = generals_data.get(caster_seat, {})
	_animate_showcase_card("Mở Kho Cứu Tế", "Mở kho phát lương cho tất cả người chơi!")
	_add_log("🌾 <b>%s</b> thi triển [Mở Kho Cứu Tế]! Lật bài cho từng người còn sống tự chọn 1 lá." % caster.get("name", "Người chơi"))
	AudioManager.play_voice("Mở Kho Cứu Tế")
	AudioManager.play_skill()

	var pool: Array = []
	var pickers: Array = []
	for i in range(0, 4):
		var s = ((caster_seat - 1 + i) % battle_seat_count) + 1
		if generals_data.has(s) and generals_data[s]["is_alive"]:
			pickers.append(s)
			pool.append(_draw_card_from_pile())
			_animate_draw_to_seat(s)

	for s in pickers:
		if pool.is_empty():
			break
		var g = generals_data[s]
		if await _maybe_local_nullify_delayed(g, "Mở Kho Cứu Tế", "hủy lượt bốc Kho Cứu Tế"):
			_add_log("🛡️ Diệu Kế Phá Mưu đã hủy lượt bốc Kho Cứu Tế của %s." % g["name"])
			await get_tree().create_timer(0.4).timeout
			continue
		var picked_index = 0
		if g["isPlayer"]:
			_show_harvest_modal(pool, true)
			var picked_id = await harvest_card_chosen
			for i in pool.size():
				if str(pool[i].get("id", "")) == picked_id:
					picked_index = i
					break
		var card = pool.pop_at(picked_index)
		if g["isPlayer"]:
			_add_card_to_player_hand(card)
			_add_log("🌾 Bạn đã chọn [%s] từ Kho Cứu Tế." % card.get("name", "Bài"))
		else:
			_animate_draw_to_seat(s)
			g["hand_cards"].append(card)
			g["hand_count"] = g["hand_cards"].size()
			g["avatar_node"].update_hand_count(g["hand_count"])
			_add_log("🌾 %s đã chọn 1 lá từ Kho Cứu Tế." % g["name"])
		await get_tree().create_timer(0.4).timeout
	_hide_harvest_modal()
	pool.clear()

func _maybe_local_nullify_delayed(actor: Dictionary, root_name: String, intent: String) -> bool:
	if actor.is_empty() or not actor.get("is_alive", false):
		return false
	if actor.get("isPlayer", false):
		for card_node in hand_container.get_children():
			var info = _get_card_info_from_ui(card_node)
			if "diệu kế" in str(info.get("name", "")).to_lower() or int(info.get("subType", -1)) == 10:
				return await _prompt_custom_reaction_async(
					"📜 DIỆU KẾ PHÁ MƯU",
					"[%s] sắp phán xét. Bạn có muốn dùng [Diệu Kế Phá Mưu] để %s không?" % [root_name, intent],
					"Diệu Kế Phá Mưu",
					"BỎ QUA",
					"📜 DÙNG DIỆU KẾ",
					40.0
				)
		return false

	var cards = actor.get("hand_cards", [])
	for idx in range(cards.size()):
		var info = cards[idx]
		if "diệu kế" in str(info.get("name", "")).to_lower() or int(info.get("subType", -1)) == 10:
			cards.remove_at(idx)
			actor["hand_count"] = cards.size()
			actor["avatar_node"].update_hand_count(actor["hand_count"])
			_animate_showcase_card("Diệu Kế Phá Mưu", "%s dùng [Diệu Kế Phá Mưu] để %s!" % [actor["name"], intent], info)
			_add_log("🛡️ %s dùng [Diệu Kế Phá Mưu] để %s." % [actor["name"], intent])
			AudioManager.play_voice("Diệu Kế Phá Mưu")
			AudioManager.play_skill()
			return true
	return false

func _resolve_local_bai_coc_action(actor_seat: int, attacker_seat: int) -> bool:
	if is_network_mode or not generals_data.has(actor_seat):
		return true
	var actor = generals_data[actor_seat]
	if not actor.get("has_bai_coc", false):
		return true
	if _hero_has_skill(actor, "thuy_chien"):
		actor["has_bai_coc"] = false
		actor["bai_coc_judgement_count"] = 0
		if actor.has("avatar_node") and is_instance_valid(actor["avatar_node"]):
			actor["avatar_node"].set_delayed_trick("bai_coc", false)
		return true
	if await _maybe_local_nullify_delayed(actor, "Bãi Cọc Bạch Đằng", "phá Bãi Cọc Bạch Đằng"):
		actor["has_bai_coc"] = false
		actor["bai_coc_judgement_count"] = 0
		actor["avatar_node"].set_delayed_trick("bai_coc", false)
		_add_log("🛡️ Diệu Kế Phá Mưu đã phá Bãi Cọc Bạch Đằng của %s." % actor["name"])
		return true

	var judge_card = _draw_card_from_pile()
	var suit = str(judge_card.get("suit", ""))
	var safe = _get_card_color(suit) in ["RED", "WHITE"]
	var judgement_count = 1
	var exhausted = true
	actor["bai_coc_judgement_count"] = judgement_count
	var suit_name = _get_suit_name(suit)
	var rank_text = _format_rank(judge_card.get("rank", 1))
	var judgement_tween = _show_judgement_result(safe, "Bãi Cọc Bạch Đằng", judge_card)
	if judgement_tween:
		await judgement_tween.finished
	if safe:
		actor["has_bai_coc"] = false
		actor["bai_coc_judgement_count"] = 0
		actor["avatar_node"].set_delayed_trick("bai_coc", false)
		_animate_showcase_card("Bãi Cọc Bạch Đằng", "Phán xét [Bài %s %s] Bài Đỏ/Bài Trắng -> hành động được tiếp tục. Bãi Cọc rời đi." % [rank_text, suit_name], judge_card)
		_add_log("🪵 [Bãi Cọc Bạch Đằng] phán xét Bài Đỏ/Bài Trắng cho %s, hành động tiếp tục; Bãi Cọc rời đi." % actor["name"])
		return true

	_animate_showcase_card("Bãi Cọc Bạch Đằng", "Phán xét [Bài %s %s] Bài Vàng/Bài Đen -> hủy hành động, -1 Máu thường. Bãi Cọc rời đi." % [rank_text, suit_name], judge_card)
	_add_log("🪵 [Bãi Cọc Bạch Đằng] phán xét Bài Vàng/Bài Đen: %s bị hủy hành động và chịu 1 sát thương thường; Bãi Cọc rời đi." % actor["name"])
	if exhausted:
		actor["has_bai_coc"] = false
		actor["bai_coc_judgement_count"] = 0
		actor["avatar_node"].set_delayed_trick("bai_coc", false)
	AudioManager.play_damage()
	_apply_damage_to_general(actor_seat, 1, attacker_seat, "NORMAL")
	return false

func _ensure_harvest_modal() -> void:
	if harvest_modal and is_instance_valid(harvest_modal):
		return
	harvest_modal = Control.new()
	harvest_modal.name = "HarvestModal"
	harvest_modal.set_anchors_preset(PRESET_FULL_RECT)
	harvest_modal.mouse_filter = MOUSE_FILTER_STOP
	harvest_modal.z_as_relative = false
	harvest_modal.z_index = 320
	add_child(harvest_modal)

	var dim = ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	harvest_modal.mouse_filter = MOUSE_FILTER_IGNORE
	harvest_modal.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 390)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.17, 0.99)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.68, 0.25, 1.0)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "🌾 MỞ KHO CỨU TẾ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3, 1.0))
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Chọn 1 lá bài công khai. Người kế tiếp sẽ chọn sau bạn."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92, 1.0))
	vbox.add_child(desc)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)
	harvest_cards_box = HBoxContainer.new()
	harvest_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	harvest_cards_box.add_theme_constant_override("separation", 12)
	scroll.add_child(harvest_cards_box)

	harvest_status_lbl = Label.new()
	harvest_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	harvest_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	vbox.add_child(harvest_status_lbl)
	harvest_timer_lbl = Label.new()
	harvest_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(harvest_timer_lbl)
	harvest_confirm_btn = Button.new()
	harvest_confirm_btn.text = "🌾 XÁC NHẬN CHỌN LÁ"
	harvest_confirm_btn.custom_minimum_size = Vector2(240, 42)
	harvest_confirm_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	harvest_confirm_btn.pressed.connect(_on_harvest_confirmed)
	vbox.add_child(harvest_confirm_btn)

func _show_harvest_modal(pool: Array, local_mode: bool, picked_ids: Array[String] = [], can_choose: bool = true, waiting_seat: int = 0) -> void:
	_ensure_harvest_modal()
	harvest_modal_local = local_mode
	harvest_picked_card_ids = picked_ids.duplicate()
	selected_harvest_card_ui = null
	selected_harvest_card_id = ""
	harvest_waiting_seat = waiting_seat if waiting_seat > 0 else my_seat
	for child in harvest_cards_box.get_children():
		child.queue_free()
	for card_data in pool:
		if not (card_data is Dictionary):
			continue
		var card_ui = CardUIScene.instantiate()
		harvest_cards_box.add_child(card_ui)
		card_ui.setup_card_data(
			str(card_data.get("id", "")),
			str(card_data.get("name", "Bài")),
			int(card_data.get("rank", 1)),
			str(card_data.get("suit", "")),
			int(card_data.get("category", card_data.get("cat", 0))),
			str(card_data.get("desc", "")),
			int(card_data.get("subType", -1))
		)
		var is_picked = harvest_picked_card_ids.has(str(card_data.get("id", "")))
		if is_picked:
			card_ui.modulate = Color(0.34, 0.34, 0.34, 0.72)
			card_ui.tooltip_text = "Đã được lấy"
		if not can_choose or is_picked:
			var click_button = card_ui.get_node_or_null("ClickButton")
			if click_button:
				click_button.disabled = true
		else:
			card_ui.card_clicked.connect(_on_harvest_card_clicked.bind(card_ui, str(card_data.get("id", ""))))
	harvest_status_lbl.text = "Chưa chọn lá nào." if can_choose else "Đang chờ người chơi khác chọn bài."
	harvest_timer_lbl.text = ""
	harvest_confirm_btn.visible = can_choose
	harvest_confirm_btn.disabled = true
	harvest_modal_signature = "%s|%s|%d" % [",".join(pool.map(func(c): return str(c.get("id", "")))), ",".join(harvest_picked_card_ids), harvest_waiting_seat]
	harvest_modal.visible = true

func _on_harvest_card_clicked(_card: Control, card_ui: Control, card_id: String) -> void:
	if selected_harvest_card_ui and is_instance_valid(selected_harvest_card_ui) and selected_harvest_card_ui != card_ui:
		selected_harvest_card_ui.set_selected(false)
	selected_harvest_card_ui = card_ui
	selected_harvest_card_id = card_id
	card_ui.set_selected(true)
	harvest_confirm_btn.disabled = false
	harvest_status_lbl.text = "Đã chọn 1 lá. Bấm xác nhận để tiếp tục."
	AudioManager.play_card_select()

func _on_harvest_confirmed() -> void:
	if selected_harvest_card_id.is_empty():
		return
	var picked_id = selected_harvest_card_id
	harvest_confirm_btn.disabled = true
	if harvest_modal_local:
		_hide_harvest_modal()
		harvest_card_chosen.emit(picked_id)
	else:
		harvest_choice_sent = true
		harvest_status_lbl.text = "Đã gửi lựa chọn. Chờ máy chủ xác nhận."
		_broadcast_player_battle_action("RESPOND_ACTION", picked_id)
		_add_log("🌾 Bạn đã chọn 1 lá từ Kho Cứu Tế.")

func _hide_harvest_modal() -> void:
	if harvest_modal and is_instance_valid(harvest_modal):
		harvest_modal.visible = false

# ==========================================================
# ⛓️ XÍCH TÂM TỎA: CHỌN ĐA MỤC TIÊU (TỐI ĐA 2 TƯỚNG)
# ==========================================================
func _show_iron_chain_modal() -> void:
	if not iron_chain_modal:
		return
	selected_chain_seats.clear()
	for child in iron_chain_grid.get_children():
		child.queue_free()

	for s in range(1, battle_seat_count + 1):
		if not generals_data.has(s):
			continue
		var g = generals_data[s]
		if not g["is_alive"]:
			continue

		var item_box = PanelContainer.new()
		item_box.custom_minimum_size = Vector2(150, 125)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.14, 0.22, 0.95)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.4, 0.4, 1.0) if g.get("is_chained", false) else Color(0.83, 0.68, 0.22, 0.8)
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		item_box.add_theme_stylebox_override("panel", style)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		item_box.add_child(margin)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)

		# Role label
		var role_tag = "(Bạn)" if s == my_seat else ("(Đồng Đội)" if g["isDragon"] == my_team_is_dragon else "(Đối Thủ)")
		var name_lbl = Label.new()
		name_lbl.text = "[%d] %s" % [s, g["name"]]
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)

		var role_lbl = Label.new()
		role_lbl.text = role_tag
		role_lbl.add_theme_font_size_override("font_size", 10)
		role_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0) if g["isDragon"] == my_team_is_dragon else Color(1.0, 0.5, 0.5, 1.0))
		role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(role_lbl)

		var hp_lbl = Label.new()
		hp_lbl.text = "❤️ %d/%d Máu" % [g["hp"], g["max_hp"]]
		hp_lbl.add_theme_font_size_override("font_size", 10)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(hp_lbl)

		var chain_lbl = Label.new()
		chain_lbl.text = "⛓️ Đang Xích" if g.get("is_chained", false) else "🔓 Tự do"
		chain_lbl.add_theme_font_size_override("font_size", 10)
		chain_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1.0) if g.get("is_chained", false) else Color(0.7, 0.85, 0.7, 1.0))
		chain_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(chain_lbl)

		var check_btn = Button.new()
		check_btn.text = "☐ CHỌN"
		check_btn.custom_minimum_size = Vector2(0, 26)
		check_btn.add_theme_font_size_override("font_size", 11)
		check_btn.focus_mode = Control.FOCUS_NONE
		vbox.add_child(check_btn)

		var s_target = s
		check_btn.pressed.connect(func(): _toggle_chain_selection(s_target))
		iron_chain_grid.add_child(item_box)

	_update_iron_chain_ui()
	iron_chain_modal.visible = true

func _toggle_chain_selection(s: int) -> void:
	if s in selected_chain_seats:
		selected_chain_seats.erase(s)
	else:
		if selected_chain_seats.size() >= 2:
			desc_text.text = "⚠️ Xích Tâm Tỏa chỉ được chọn tối đa 2 tướng!"
			return
		selected_chain_seats.append(s)

	AudioManager.play_card_select()
	_update_iron_chain_ui()

func _update_iron_chain_ui() -> void:
	var count = selected_chain_seats.size()
	iron_chain_status_lbl.text = "👉 Đã chọn: %d/2 tướng" % count if count > 0 else "👉 Chưa chọn mục tiêu: có thể đổi lá để rút 1 lá mới."
	iron_chain_confirm_btn.disabled = false
	iron_chain_confirm_btn.text = "⛓️ XÁC NHẬN XÍCH (%d TƯỚNG)" % count if count > 0 else "🔄 ĐỔI LÁ XÍCH (RÚT 1)"

	var child_idx = 0
	for s in range(1, battle_seat_count + 1):
		if not generals_data.has(s) or not generals_data[s]["is_alive"]:
			continue
		if child_idx < iron_chain_grid.get_child_count():
			var item_box = iron_chain_grid.get_child(child_idx) as PanelContainer
			var vbox = item_box.get_child(0).get_child(0) as VBoxContainer
			var check_btn = vbox.get_child(4) as Button
			var is_sel = (s in selected_chain_seats)
			var style = item_box.get_theme_stylebox("panel") as StyleBoxFlat
			if is_sel:
				style.bg_color = Color(0.32, 0.22, 0.08, 0.98)
				style.border_color = Color(1.0, 0.9, 0.35, 1.0)
				check_btn.text = "☑ ĐÃ CHỌN"
				check_btn.modulate = Color(1.0, 0.95, 0.4)
			else:
				var is_ch = generals_data[s].get("is_chained", false)
				style.bg_color = Color(0.1, 0.14, 0.22, 0.95)
				style.border_color = Color(1.0, 0.4, 0.4, 1.0) if is_ch else Color(0.83, 0.68, 0.22, 0.8)
				check_btn.text = "☐ CHỌN"
				check_btn.modulate = Color(1, 1, 1)
		child_idx += 1

func _on_iron_chain_confirmed() -> void:
	var c_info = _get_card_info_from_ui(selected_card_ui) if (selected_card_ui and is_instance_valid(selected_card_ui)) else {}
	if c_info.is_empty():
		desc_text.text = "⚠️ Hãy chọn lá [Xích Tâm Tỏa] trước khi xác nhận."
		return
	var is_chain_recast = selected_chain_seats.is_empty()
	var c_id = str(c_info.get("id", "Xích Tâm Tỏa"))
	if c_id.is_empty(): c_id = "Xích Tâm Tỏa"
	last_played_card_info = c_info.duplicate()
	iron_chain_modal.visible = false

	if selected_card_ui and is_instance_valid(selected_card_ui):
		_discard_player_card(selected_card_ui)
		selected_card_ui = null
	card_play_btn.visible = false

	AudioManager.play_voice("Xích Tâm Tỏa")
	AudioManager.play_skill()
	if is_chain_recast:
		_animate_showcase_card("Xích Tâm Tỏa", "Đổi lá để rút 1 lá mới!", c_info)
		_add_log("🔄 Bạn đổi [Xích Tâm Tỏa] để rút 1 lá bài.")
	else:
		_animate_showcase_card("Xích Tâm Tỏa", "Đổi trạng thái xích cho %d tướng!" % selected_chain_seats.size(), c_info)

	for s in selected_chain_seats:
		var g = generals_data[s]
		g["is_chained"] = !g.get("is_chained", false)
		if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
			g["avatar_node"].set_chained(g["is_chained"])
		var act_str = "trói vào Xích Liên Hoàn" if g["is_chained"] else "gỡ Xích Liên Hoàn"
		_add_log("⛓️ Bạn dùng [Xích Tâm Tỏa] %s cho %s (Ghế %d)!" % [act_str, g["name"], s])

	var target_seats_list = selected_chain_seats.duplicate()
	var target_seat_1 = target_seats_list[0] if target_seats_list.size() > 0 else 0
	var target_seat_2 = target_seats_list[1] if target_seats_list.size() > 1 else 0
	_broadcast_player_battle_action("PLAY_CARD", c_id, target_seat_1, my_seat, target_seat_2, target_seats_list, is_chain_recast)
	if is_chain_recast and not is_network_mode:
		_add_card_to_player_hand(_draw_card_from_pile())
	selected_chain_seats.clear()
	_update_chain_target_highlights()
	_reset_player_turn_timer()

func _hide_iron_chain_modal() -> void:
	iron_chain_modal.visible = false
	selected_chain_seats.clear()

# ==========================================================
# 🗡️🌾 CƯỚP / PHÁ HỦY BÀI: TỰ CHỌN BÀI ÚP HOẶC TRANG BỊ
# ==========================================================
func _show_card_pick_modal(is_steal: bool, target_seat: int, selection_data: Dictionary = {}) -> void:
	if not card_pick_modal or not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	card_pick_is_steal = is_steal
	card_pick_target_seat = target_seat
	selected_card_pick_option.clear()

	var src_info = _get_card_info_from_ui(selected_card_ui) if (selected_card_ui and is_instance_valid(selected_card_ui)) else {}
	card_pick_source_card_id = str(selection_data.get("cardId", src_info.get("id", "")))
	card_pick_source_card_name = str(selection_data.get("cardName", src_info.get("name", "")))
	card_pick_effect_type = str(selection_data.get("effectType", ""))

	for c in card_pick_options_hbox.get_children():
		c.queue_free()
	for c in card_pick_equipment_hbox.get_children():
		c.queue_free()

	var effect_type = card_pick_effect_type
	if effect_type == "THUONG_NGAU":
		card_pick_title.text = "🗡️ THƯƠNG NGÂU LÃNG BẠC: PHÁ HỦY BÀI CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🗡️ XÁC NHẬN PHÁ HỦY"
		card_pick_desc.text = "💡 Trảm đã trúng. Chọn 1 lá bài úp trên tay hoặc 1 trang bị của %s để phá hủy:" % tgt["name"]
	elif effect_type == "DOAN_DAO":
		card_pick_title.text = "🗡️ ĐOẢN ĐAO LAM SƠN: HỦY 2 LÁ CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🗡️ XÁC NHẬN HỦY"
		card_pick_desc.text = "💡 Chọn lá trên tay hoặc Trang bị. Cẩm Nang Trì Hoãn không thể chọn."
	elif effect_type == "TAU_VI":
		card_pick_title.text = "🏃 TẨU VI THƯỢNG SÁCH: BỎ TRANG BỊ"
		card_pick_confirm_btn.text = "🏃 BỎ VÀ RÚT 2 LÁ"
		card_pick_desc.text = "💡 Chọn 1 Trang bị của chính bạn để bỏ."
	elif effect_type == "PHU_DE":
		card_pick_title.text = "🔥 PHỦ ĐỂ TRỪU TÂN: TRẢ TRANG BỊ"
		card_pick_confirm_btn.text = "🔥 TRẢ VỀ TAY"
		card_pick_desc.text = "💡 Chọn 1 Trang bị của %s để đưa về tay họ." % tgt["name"]
	elif effect_type == "TRIEU_DANG":
		card_pick_title.text = "🌊 TRIỀU DÂNG: HỦY TRANG BỊ CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🌊 XÁC NHẬN HỦY"
		card_pick_desc.text = "💡 Chọn 1 trang bị đang đeo của %s để hủy." % tgt["name"]
	elif effect_type == "HOA_DAN":
		card_pick_title.text = "🌾 HÓA DÂN: BỎ TRANG BỊ"
		card_pick_confirm_btn.text = "🌾 BỎ VÀ HỒI 1 MÁU"
		card_pick_desc.text = "💡 Chọn 1 Trang bị bất kỳ của bạn để bỏ."
	elif effect_type == "AN_DAN":
		card_pick_title.text = "🏘️ AN DÂN: DI CHUYỂN CẨM NANG"
		card_pick_confirm_btn.text = "🏘️ XÁC NHẬN DI CHUYỂN"
		card_pick_desc.text = "💡 Chọn một phương án chuyển Cẩm Nang Trì Hoãn sang người khác."
	elif effect_type == "DAN_CAU_STEAL":
		card_pick_title.text = "🌉 DẪN CẦU: CHỌN LÁ BỊ CƯỚP TỪ %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🌉 XÁC NHẬN CƯỚP"
		card_pick_desc.text = "💡 Chọn 1 lá bài của %s để Kiều Công Tiễn cướp." % tgt["name"]
	elif effect_type == "XUNG_VUONG_DISCARD":
		card_pick_title.text = "👑 XƯNG VƯƠNG: CHỌN LÁ BỎ"
		card_pick_confirm_btn.text = "👑 BỎ LÁ NÀY"
		card_pick_desc.text = "💡 Chọn trực tiếp 1 lá trên tay hoặc 1 trang bị đang mang để bỏ."
	elif effect_type == "AN_TICH_DEFENSE":
		card_pick_title.text = "🌫️ ẨN TÍCH: CHỌN LÁ ĐỠ"
		card_pick_confirm_btn.text = "🌫️ DÙNG LÁ NÀY ĐỠ"
		card_pick_desc.text = "💡 Chọn 1 lá Ẩn để dùng như Đỡ cho đòn Trảm."
	elif effect_type == "UU_THIEP":
		card_pick_title.text = "🐎 ƯU THIẾP: CƯỚP 1 LÁ TRANG BỊ"
		card_pick_confirm_btn.text = "🐎 XÁC NHẬN CƯỚP"
		card_pick_cancel_btn.text = "BỎ QUA"
		card_pick_desc.text = "💡 Chọn 1 lá Trang bị của một mục tiêu để cướp về tay bạn (hoặc Bỏ qua):"
	elif effect_type == "CO_LAU":
		card_pick_title.text = "🎋 CỜ LAU: PHÁ HỦY TRANG BỊ CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🎋 XÁC NHẬN PHÁ HỦY"
		card_pick_desc.text = "💡 Chọn 1 lá trang bị của %s để phá hủy:" % tgt["name"]
	elif is_steal:
		card_pick_title.text = "🗡️ ĐỘT KÍCH TRỘM LƯƠNG: CƯỚP BÀI TỪ %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🗡️ XÁC NHẬN CƯỚP"
	else:
		card_pick_title.text = "🌾 VƯỜN KHÔNG NHÀ TRỐNG: PHÁ HỦY BÀI CỦA %s" % tgt["name"].to_upper()
		card_pick_confirm_btn.text = "🌾 XÁC NHẬN PHÁ HỦY"
	if effect_type not in ["THUONG_NGAU", "DOAN_DAO", "TAU_VI", "PHU_DE", "TRIEU_DANG", "HOA_DAN", "AN_DAN", "DAN_CAU_STEAL", "XUNG_VUONG_DISCARD", "AN_TICH_DEFENSE", "UU_THIEP", "CO_LAU"]:
		card_pick_desc.text = "💡 Hãy chọn 1 lá bài úp trên tay hoặc 1 trang bị đang mặc của %s:" % tgt["name"]

	var has_options = false
	var server_opts = selection_data.get("options", [])

	if server_opts is Array and not server_opts.is_empty():
		for s_opt in server_opts:
			var zone = s_opt.get("zone", "")
			var token = s_opt.get("token", "")
			var c_dict = s_opt.get("card", {})
			if zone == "HAND":
				has_options = true
				var idx = int(token.trim_prefix("HAND:"))
				if effect_type == "XUNG_VUONG_DISCARD":
					var local_card = {}
					if target_seat == my_seat and idx >= 0 and idx < hand_container.get_child_count():
						local_card = _get_card_info_from_ui(hand_container.get_child(idx))
					else:
						var local_cards = tgt.get("hand_cards", [])
						local_card = local_cards[idx] if idx >= 0 and idx < local_cards.size() else {}
					_add_visible_card_pick_option("🖐️ TRÊN TAY", str(local_card.get("name", "Lá trên tay")), "hand", token, local_card)
					continue
				var card_btn = Button.new()
				card_btn.custom_minimum_size = Vector2(90, 110)
				card_btn.focus_mode = Control.FOCUS_NONE
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.12, 0.16, 0.26, 0.98)
				style.border_width_left = 2
				style.border_width_top = 2
				style.border_width_right = 2
				style.border_width_bottom = 2
				style.border_color = Color(0.83, 0.68, 0.22, 0.8)
				style.corner_radius_top_left = 6
				style.corner_radius_top_right = 6
				style.corner_radius_bottom_right = 6
				style.corner_radius_bottom_left = 6
				card_btn.add_theme_stylebox_override("normal", style)
				card_btn.text = "🎴\n\nLÁ BÀI #%d" % (idx + 1)
				card_btn.add_theme_font_size_override("font_size", 11)
				card_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
				var opt = {"type": "hand", "index": idx, "token": token, "label": "Lá bài úp #%d" % (idx + 1), "button": card_btn}
				card_btn.pressed.connect(func(): _select_card_pick_option(opt))
				card_pick_options_hbox.add_child(card_btn)
			elif zone == "EQUIPMENT":
				has_options = true
				var item_name = c_dict.get("name", "Trang bị") if c_dict is Dictionary else "Trang bị"
				var slot_title = _get_equipment_slot_title(c_dict, item_name)
				var owner_seat = int(s_opt.get("ownerSeat", s_opt.get("targetSeat", 0)))
				if (effect_type == "UU_THIEP" or (owner_seat > 0 and owner_seat != target_seat)) and generals_data.has(owner_seat):
					var owner_name = generals_data[owner_seat].get("name", "Ghế %d" % owner_seat)
					slot_title = "%s (%s)" % [slot_title, owner_name]
				_add_visible_card_pick_option(slot_title, item_name, "equipment", token, c_dict)
			elif zone == "AN_TICH":
				has_options = true
				var hidden_name = c_dict.get("name", "Ẩn") if c_dict is Dictionary else "Ẩn"
				_add_visible_card_pick_option("🌫️ ẨN", hidden_name, "an_tich", token, c_dict)
			elif zone == "JUDGEMENT":
				has_options = true
				var item_name = c_dict.get("name", "Trì Hoãn") if c_dict is Dictionary else "Trì Hoãn"
				var option_label = str(s_opt.get("label", "⏳ PHÁN XÉT"))
				_add_visible_card_pick_option(option_label, item_name, "judgement", token, c_dict)
	else:
		if effect_type != "TRIEU_DANG":
			var hand_count = tgt["hand_count"]
			for i in range(hand_count):
				has_options = true
				var card_btn = Button.new()
				card_btn.custom_minimum_size = Vector2(90, 110)
				card_btn.focus_mode = Control.FOCUS_NONE

				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.12, 0.16, 0.26, 0.98)
				style.border_width_left = 2
				style.border_width_top = 2
				style.border_width_right = 2
				style.border_width_bottom = 2
				style.border_color = Color(0.83, 0.68, 0.22, 0.8)
				style.corner_radius_top_left = 6
				style.corner_radius_top_right = 6
				style.corner_radius_bottom_right = 6
				style.corner_radius_bottom_left = 6
				card_btn.add_theme_stylebox_override("normal", style)
				card_btn.text = "🎴\n\nLÁ BÀI #%d" % (i + 1)
				card_btn.add_theme_font_size_override("font_size", 11)
				card_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))

				var opt = {"type": "hand", "index": i, "token": "HAND:%d" % i, "label": "Lá bài úp #%d" % (i + 1), "button": card_btn}
				card_btn.pressed.connect(func(): _select_card_pick_option(opt))
				card_pick_options_hbox.add_child(card_btn)

		if tgt["equipped_weapon"] != "":
			has_options = true
			_add_visible_card_pick_option("🗡️ VŨ KHÍ", tgt["equipped_weapon"], "weapon", "EQUIPMENT:%s" % tgt["equipped_weapon"])

		if tgt["equipped_armor"] != "":
			has_options = true
			_add_visible_card_pick_option("🛡️ ÁO GIÁP", tgt["equipped_armor"], "armor", "EQUIPMENT:%s" % tgt["equipped_armor"])

		if tgt["equipped_def_horse"] != "":
			has_options = true
			_add_visible_card_pick_option("🐘 NGỰA THỦ", tgt["equipped_def_horse"], "def_horse", "EQUIPMENT:%s" % tgt["equipped_def_horse"])

		if tgt["equipped_off_horse"] != "":
			has_options = true
			_add_visible_card_pick_option("🐎 NGỰA CÔNG", tgt["equipped_off_horse"], "off_horse", "EQUIPMENT:%s" % tgt["equipped_off_horse"])

		if tgt.get("equipped_treasure", "") != "":
			has_options = true
			_add_visible_card_pick_option("🥁 BẢO VẬT", tgt["equipped_treasure"], "treasure", "EQUIPMENT:%s" % tgt["equipped_treasure"])

		var local_judgements = [
			["has_dai_hong_thuy", "Đại Hồng Thủy", "dai_hong_thuy"],
			["has_cat_luong", "Cắt Đường Lương", "cat_luong"],
			["has_tram_ao", "Trầm Ảo Sa Bẫy", "tram_ao"],
			["has_bai_coc", "Bãi Cọc Bạch Đằng", "bai_coc"]
		]
		if effect_type != "TRIEU_DANG":
			for judgement in local_judgements:
				if tgt.get(judgement[0], false):
					has_options = true
					_add_visible_card_pick_option("⏳ PHÁN XÉT", judgement[1], "judgement", "JUDGEMENT:%s" % judgement[2])

	if not has_options:
		desc_text.text = "ℹ️ %s không có bài trên tay hoặc trang bị nào để cướp/hủy!" % tgt["name"]
		return

	_layout_card_pick_hand()
	card_pick_status_lbl.text = "👉 Đang chọn: Chưa chọn lá nào"
	card_pick_confirm_btn.disabled = true
	card_pick_modal.visible = true

func _get_equipment_slot_title(card_info: Dictionary, item_name: String) -> String:
	var sub_type = int(card_info.get("subType", -1))
	match sub_type:
		6: return "🗡️ VŨ KHÍ"
		7: return "🛡️ ÁO GIÁP"
		8: return "🐎 NGỰA CÔNG"
		9: return "🐘 NGỰA THỦ"
		27: return "🥁 BẢO VẬT"

	# Tương thích dữ liệu cũ không gửi subType cho trang bị công khai.
	var lowered_name = item_name.to_lower()
	if "giáp" in lowered_name or "khiên" in lowered_name or "áo bào" in lowered_name:
		return "🛡️ ÁO GIÁP"
	if "voi chiến" in lowered_name:
		return "🐘 NGỰA THỦ"
	if "ngựa" in lowered_name:
		return "🐎 NGỰA CÔNG"
	if "trống đồng" in lowered_name:
		return "🥁 BẢO VẬT"
	return "🗡️ VŨ KHÍ"

func _add_visible_card_pick_option(slot_title: String, item_name: String, option_type: String, token: String, card_info: Dictionary = {}) -> void:
	var info = _get_showcase_card_info(item_name, card_info)
	var card_ui = CardUIScene.instantiate()
	card_ui.custom_minimum_size = Vector2(118, 168)
	card_ui.setup_card_data(
		str(info.get("id", "target_card")),
		str(info.get("name", item_name)),
		info.get("rank", 1),
		str(info.get("suit", "Spade")),
		int(info.get("category", info.get("cat", 1))),
		str(info.get("desc", info.get("description", ""))),
		int(info.get("subType", -1))
	)
	var opt = {"type": option_type, "item_name": item_name, "token": token, "label": "%s: %s" % [slot_title, item_name], "button": card_ui, "card": info}
	card_ui.card_clicked.connect(func(_card): _select_card_pick_option(opt))
	card_pick_equipment_hbox.add_child(card_ui)

func _select_card_pick_option(opt: Dictionary) -> void:
	selected_card_pick_option = opt
	AudioManager.play_card_select()

	for btn in card_pick_options_hbox.get_children():
		var st = btn.get_theme_stylebox("normal") as StyleBoxFlat
		if st:
			st.border_color = Color(0.83, 0.68, 0.22, 0.8)
	for card in card_pick_equipment_hbox.get_children():
		if card.has_method("set_selected"):
			card.set_selected(false)

	if opt.has("button") and is_instance_valid(opt["button"]):
		if opt["button"].has_method("set_selected"):
			opt["button"].set_selected(true)
		else:
			var active_st = opt["button"].get_theme_stylebox("normal") as StyleBoxFlat
			if active_st:
				active_st.border_color = Color(1.0, 0.95, 0.35, 1.0)
	_layout_card_pick_hand(opt.get("button", null))

	card_pick_status_lbl.text = "👉 Đã chọn: %s" % opt.get("label", "")
	card_pick_confirm_btn.disabled = false

func _layout_card_pick_hand(selected_btn: Control = null) -> void:
	var count = card_pick_options_hbox.get_child_count()
	if count <= 0:
		return
	var spacing = 8 if count <= 6 else clampi(int(floor((640.0 - 90.0 * count) / float(count - 1))), -58, 8)
	card_pick_options_hbox.add_theme_constant_override("separation", spacing)
	for btn in card_pick_options_hbox.get_children():
		btn.custom_minimum_size = Vector2(120, 110) if btn == selected_btn else Vector2(90, 110)

func _on_card_pick_confirmed() -> void:
	if selected_card_pick_option.is_empty() or card_pick_target_seat <= 0:
		return
	card_pick_modal.visible = false

	var tgt = generals_data[card_pick_target_seat]
	var opt = selected_card_pick_option
	var opt_type = opt.get("type", "")
	var target_token = opt.get("token", "")
	if target_token.is_empty():
		if opt_type == "hand":
			target_token = "HAND:%d" % opt.get("index", 0)
		else:
			target_token = "EQUIPMENT:%s" % opt.get("item_name", "")

	if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
		if card_pick_effect_type == "AN_TICH_DEFENSE":
			NetworkClient.send_respond_action(true, target_token)
		else:
			NetworkClient.send_respond_action(true, "", target_token)
	else:
		var fallback_name = "Đột Kích Trộm Lương" if card_pick_is_steal else "Vườn Không Nhà Trống"
		var c_id = card_pick_source_card_id
		if c_id.is_empty():
			var c_info = _get_card_info_from_ui(selected_card_ui) if (selected_card_ui and is_instance_valid(selected_card_ui)) else {}
			c_id = str(c_info.get("id", fallback_name))
		if c_id.is_empty(): c_id = fallback_name

		if selected_card_ui and is_instance_valid(selected_card_ui):
			_discard_player_card(selected_card_ui)
			selected_card_ui = null
		card_play_btn.visible = false

		if opt_type == "hand":
			var card_idx = opt.get("index", 0)
			var stolen_card = {}
			if tgt["isAI"] and not tgt["hand_cards"].is_empty():
				if card_idx < tgt["hand_cards"].size():
					stolen_card = tgt["hand_cards"][card_idx]
					tgt["hand_cards"].remove_at(card_idx)
				else:
					stolen_card = tgt["hand_cards"].pop_back()
			else:
				stolen_card = _draw_card_from_pile()

			tgt["hand_count"] = max(0, tgt["hand_count"] - 1)
			tgt["avatar_node"].update_hand_count(tgt["hand_count"])

			var c_name = stolen_card.get("name", "Bài")
			if card_pick_is_steal:
				_add_card_to_player_hand(stolen_card)
				AudioManager.play_voice("Đột Kích Trộm Lương")
				AudioManager.play_skill()
				_animate_showcase_card("Đột Kích Trộm Lương", "Cướp được [%s] từ %s!" % [c_name, tgt["name"]])
				_add_log("🗡️ Bạn đã tự chọn cướp lá bài úp #%d từ %s (đó là lá [%s])!" % [card_idx + 1, tgt["name"], c_name])
			else:
				AudioManager.play_voice("Vườn Không Nhà Trống")
				AudioManager.play_skill()
				_animate_showcase_card("Vườn Không Nhà Trống", "Phá hủy 1 lá bài úp của %s!" % tgt["name"])
				_add_log("🌾 Bạn đã tự chọn phá hủy lá bài úp #%d của %s (đó là lá [%s])!" % [card_idx + 1, tgt["name"], c_name])

		elif opt_type in ["weapon", "armor", "def_horse", "off_horse", "treasure", "equipment", "judgement"]:
			var item_name = opt.get("item_name", "")
			match opt_type:
				"weapon":
					tgt["equipped_weapon"] = ""
					tgt["avatar_node"].set_equipment("weapon", "", "")
				"armor":
					tgt["equipped_armor"] = ""
					tgt["avatar_node"].set_equipment("armor", "", "")
				"def_horse":
					tgt["equipped_def_horse"] = ""
					tgt["avatar_node"].set_equipment("def_horse", "", "")
				"off_horse":
					tgt["equipped_off_horse"] = ""
					tgt["avatar_node"].set_equipment("off_horse", "", "")
				"treasure":
					tgt["equipped_treasure"] = ""
					tgt["avatar_node"].set_equipment("treasure", "", "")
					tgt["avatar_node"].set_skill("")
				"equipment":
					if tgt.get("equipped_weapon", "") == item_name:
						tgt["equipped_weapon"] = ""
						tgt["avatar_node"].set_equipment("weapon", "", "")
					elif tgt.get("equipped_armor", "") == item_name:
						tgt["equipped_armor"] = ""
						tgt["avatar_node"].set_equipment("armor", "", "")
					elif tgt.get("equipped_def_horse", "") == item_name:
						tgt["equipped_def_horse"] = ""
						tgt["avatar_node"].set_equipment("def_horse", "", "")
					elif tgt.get("equipped_off_horse", "") == item_name:
						tgt["equipped_off_horse"] = ""
						tgt["avatar_node"].set_equipment("off_horse", "", "")
					elif tgt.get("equipped_treasure", "") == item_name:
						tgt["equipped_treasure"] = ""
						tgt["avatar_node"].set_equipment("treasure", "", "")
						tgt["avatar_node"].set_skill("")
				"judgement":
					match item_name:
						"Đại Hồng Thủy":
							tgt["has_dai_hong_thuy"] = false
							tgt["has_lightning"] = false
							tgt["avatar_node"].set_delayed_trick("dai_hong_thuy", false)
						"Cắt Đường Lương":
							tgt["has_cat_luong"] = false
							tgt["avatar_node"].set_delayed_trick("cat_luong", false)
						"Trầm Ảo Sa Bẫy":
							tgt["has_tram_ao"] = false
							tgt["avatar_node"].set_delayed_trick("tram_ao", false)
						"Bãi Cọc Bạch Đằng":
							tgt["has_bai_coc"] = false
							tgt["avatar_node"].set_delayed_trick("bai_coc", false)

			var target_card = opt.get("card", _find_card_dict_by_name(item_name))
			if not (target_card is Dictionary):
				target_card = _find_card_dict_by_name(item_name)
			if card_pick_effect_type == "PHU_DE":
				tgt["hand_count"] += 1
				tgt["avatar_node"].update_hand_count(tgt["hand_count"])
				_animate_showcase_card(item_name, "Phủ Để Trừu Tân đưa [%s] về tay %s!" % [item_name, tgt["name"]], target_card)
			elif card_pick_effect_type == "TRIEU_DANG":
				_animate_showcase_card("Triều Dâng", "🌊 Hủy [%s] của %s!" % [item_name, tgt["name"]], target_card)
				_add_log("🌊 [TRIỀU DÂNG] Bạn hủy [%s] của %s." % [item_name, tgt["name"]])
				AudioManager.play_skill()
			elif card_pick_effect_type == "UU_THIEP":
				_add_card_to_player_hand(target_card)
				AudioManager.play_skill()
				_animate_showcase_card(item_name, "Ưu Thiếp cướp [%s] từ %s!" % [item_name, tgt["name"]], target_card)
				_add_log("🐎 [ƯU THIẾP] Bạn cướp [%s] của %s!" % [item_name, tgt["name"]])
			elif card_pick_is_steal:
				_add_card_to_player_hand(target_card)
				AudioManager.play_voice("Đột Kích Trộm Lương")
				AudioManager.play_skill()
				_animate_showcase_card(item_name, "Cướp [%s] từ %s!" % [item_name, tgt["name"]], target_card)
				_add_log("🗡️ Bạn đã tự chọn cướp [%s] của %s!" % [item_name, tgt["name"]])
			else:
				AudioManager.play_voice("Vườn Không Nhà Trống")
				AudioManager.play_skill()
				_animate_showcase_card(item_name, "Vườn Không Nhà Trống phá hủy [%s] của %s!" % [item_name, tgt["name"]], target_card, 2.0)
				_add_log("🌾 Bạn đã tự chọn phá hủy [%s] của %s!" % [item_name, tgt["name"]])

		if card_pick_effect_type == "TAU_VI":
			for _i in range(2):
				_add_card_to_player_hand(_draw_card_from_pile())
			_animate_showcase_card("Tẩu Vi Thượng Sách", "Bỏ Trang bị, rút 2 lá bài.")

	if card_pick_effect_type == "TRIEU_DANG" and selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
	selected_card_pick_option.clear()
	card_pick_target_seat = -1
	card_pick_effect_type = ""
	_reset_player_turn_timer()

func _hide_card_pick_modal() -> void:
	if is_network_mode and current_server_phase == "AWAIT_TARGET_CARD" and card_pick_effect_type == "UU_THIEP":
		NetworkClient.send_respond_action(false)
	card_pick_modal.visible = false
	card_pick_confirm_btn.visible = true
	card_pick_cancel_btn.text = "HỦY"
	if card_pick_effect_type == "TRIEU_DANG" and selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
		selected_target_seat = -1
	selected_card_pick_option.clear()
	card_pick_target_seat = -1
	card_pick_effect_type = ""

func _find_card_dict_by_name(c_name: String) -> Dictionary:
	var deck = CardDatabase.create_deck_80()
	for c in deck:
		if c.get("name", "") == c_name:
			return c
	return {"id": "item", "name": c_name, "suit": "Club", "rank": 1, "cat": 1, "desc": c_name}

# ==========================================================
# 🥁 TRỐNG ĐỒNG ĐÔNG SƠN: ĐIỂM TRỐNG
# ==========================================================
func _activate_ho_phu_skill() -> void:
	if selected_target_seat <= 0 or selected_target_seat == my_seat or not generals_data.has(selected_target_seat) or not generals_data[selected_target_seat].get("is_alive", false):
		desc_text.text = "⚠️ Hổ Phù cần chọn 1 tướng khác còn sống."
		return
	if selected_card_ui == null or not is_instance_valid(selected_card_ui):
		desc_text.text = "⚠️ Hổ Phù cần chọn 1 lá trên tay để giao."
		return

	var given_card = _get_card_info_from_ui(selected_card_ui)
	var given_id = str(given_card.get("id", ""))
	if given_id.is_empty():
		desc_text.text = "⚠️ Không tìm được lá bài cần giao."
		return

	var target = generals_data[selected_target_seat]
	_play_smart_card_rays("Hổ Phù Trần Triều", my_seat, [selected_target_seat], selected_card_ui)
	if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
		NetworkClient.send_use_skill("Hổ Phù Trần Triều", selected_target_seat, given_id)
	else:
		_discard_player_card(selected_card_ui)
		var target_hand_cards: Array = target.get("hand_cards", [])
		target_hand_cards.append(given_card)
		target["hand_cards"] = target_hand_cards
		target["hand_count"] = int(target.get("hand_count", 0)) + 1
		if target.has("avatar_node") and is_instance_valid(target["avatar_node"]):
			target["avatar_node"].update_hand_count(target["hand_count"])

	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
	selected_card_ui = null
	selected_target_seat = -1
	is_targeting_ho_phu_skill = false
	_set_treasure_skill_selected(false)
	card_play_btn.visible = false
	AudioManager.play_skill()
	_animate_showcase_card("Hổ Phù Trần Triều", "Đưa [%s] cho %s." % [given_card.get("name", "Bài"), target["name"]], given_card)
	_add_log("🐯 Bạn dùng [Hổ Phù Trần Triều] đưa [%s] cho %s." % [given_card.get("name", "Bài"), target["name"]])

func _activate_drum_skill(target_seat: int) -> void:
	var tgt = generals_data.get(target_seat, {})
	if target_seat == my_seat or tgt.is_empty() or not tgt.get("is_alive", false):
		desc_text.text = "⚠️ Điểm Trống cần chọn 1 tướng khác còn sống."
		return
	if int(tgt.get("hand_count", 0)) <= 0 and tgt.get("hand_cards", []).is_empty():
		desc_text.text = "⚠️ %s không có bài trên tay để Điểm Trống!" % tgt.get("name", "Mục tiêu")
		return
	is_targeting_drum_skill = false
	_set_treasure_skill_selected(false)
	card_play_btn.visible = false
	if selected_target_seat > 0 and generals_data.has(selected_target_seat):
		generals_data[selected_target_seat]["avatar_node"].set_target_highlight(false)
	selected_target_seat = -1
	var tgt_name = tgt.get("name", "Ghế %d" % target_seat)
	var my_name = generals_data.get(my_seat, {}).get("name", "Bạn")

	AudioManager.play_skill()
	_animate_showcase_card("Trống Đồng Đông Sơn", "🥁 Kích hoạt [Điểm Trống] lên %s!" % tgt_name)
	_add_log("🥁 <b>%s</b> phát động [Điểm Trống] lên <b>%s</b>!" % [my_name, tgt_name])

	if is_network_mode and NetworkClient and NetworkClient.is_connected_to_server:
		NetworkClient.send_use_skill("Điểm Trống", target_seat)
	else:
		_execute_local_drum_skill(my_seat, target_seat)

func _execute_local_drum_skill(caster_seat: int, target_seat: int) -> void:
	var tgt = generals_data.get(target_seat, {})
	var tgt_name = tgt.get("name", "Ghế %d" % target_seat)
	var caster = generals_data.get(caster_seat, {})
	var caster_name = caster.get("name", "Ghế %d" % caster_seat)

	# 1. Người chơi nhận hiệu ứng Điểm Trống từ AI bot
	if target_seat == my_seat:
		var cards_on_hand = hand_container.get_children()
		if cards_on_hand.is_empty():
			_add_log("🥁 Bạn không có bài trên tay để Điểm Trống.")
			return
		_prompt_reaction_modal(
			"🥁 ĐIỂM TRỐNG - TRỐNG ĐỒNG",
			"🥁 %s dùng Điểm Trống lên bạn!\nBạn phải chọn: BỎ 1 LÁ BÀI trên tay hoặc LỘ TOÀN BỘ BÀI cho %s xem." % [caster_name, caster_name],
			"Bài",
			"👁️ LỘ BÀI TRÊN TAY",
			"🗑️ BỎ",
			40.0,
			false,
			true,
			false
		)
		custom_reaction_callback = func(accepted: bool, card_info: Dictionary):
			if accepted and not card_info.is_empty():
				_add_log("🥁 <b>%s</b> (Bạn) chọn bỏ 1 lá bài [%s] theo Điểm Trống của <b>%s</b>." % [tgt_name, card_info.get("name", "Bài"), caster_name])
				_animate_showcase_card(card_info.get("name", "Bài"), "Bạn bỏ 1 lá theo Điểm Trống.", card_info)
			else:
				_add_log("🥁 <b>%s</b> (Bạn) chọn LỘ TOÀN BỘ BÀI TRÊN TAY cho <b>%s</b> xem." % [tgt_name, caster_name])
		return

	# 2. AI Bot nhận hiệu ứng Điểm Trống từ người chơi hoặc bot khác
	var bot_cards: Array = tgt.get("hand_cards", [])
	var bot_count: int = int(tgt.get("hand_count", bot_cards.size()))
	if bot_count <= 0 and bot_cards.is_empty():
		_add_log("🥁 <b>%s</b> không có bài trên tay để Điểm Trống." % tgt_name)
		return

	# AI quyết định: 70% bỏ 1 lá bài, 30% để lộ toàn bộ bài
	var roll = randf()
	if roll < 0.70 and (not bot_cards.is_empty() or bot_count > 0):
		var discarded_card = {}
		if not bot_cards.is_empty():
			discarded_card = bot_cards.pop_at(randi() % bot_cards.size())
			tgt["hand_count"] = bot_cards.size()
		else:
			tgt["hand_count"] = max(0, bot_count - 1)
			discarded_card = {"name": "Lá bài bí mật"}

		if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
			tgt["avatar_node"].update_hand_count(tgt["hand_count"])

		var card_label = discarded_card.get("name", "Bài")
		_animate_showcase_card(card_label, "%s chọn BỎ 1 LÁ BÀI theo Điểm Trống!" % tgt_name, discarded_card)
		_add_log("🥁 <b>%s</b> chọn bỏ 1 lá bài [%s] theo Điểm Trống của <b>%s</b>." % [tgt_name, card_label, caster_name])
		AudioManager.play_card_draw()
	else:
		_add_log("🥁 <b>%s</b> chọn LỘ TOÀN BỘ BÀI TRÊN TAY cho <b>%s</b> xem theo Điểm Trống!" % [tgt_name, caster_name])
		var reveal_list: Array = []
		if not bot_cards.is_empty():
			reveal_list = bot_cards.duplicate()
		else:
			var deck = CardDatabase.create_deck_80()
			for i in range(bot_count):
				reveal_list.append(deck[randi() % deck.size()])

		if caster_seat == my_seat:
			_show_drum_reveal_modal(target_seat, reveal_list)

func _execute_local_van_an(target_seat: int, card_nodes: Array) -> void:
	if local_van_an_uses >= 2:
		desc_text.text = "⚠️ [VẠN AN] chỉ dùng tối đa 2 lần mỗi lượt."
		return
	if target_seat <= 0 or not generals_data.has(target_seat):
		desc_text.text = "⚠️ [VẠN AN] cần chọn 1 người chơi khác."
		return
	var tgt = generals_data[target_seat]
	if _hero_has_skill(tgt, "thuy_chien"):
		desc_text.text = "⚠️ %s có kỹ năng [Thủy Chiến], không thể trở thành mục tiêu của Bãi Cọc Bạch Đằng!" % tgt["name"]
		return
	if tgt.get("has_bai_coc", false):
		desc_text.text = "⚠️ %s đã có Bãi Cọc Bạch Đằng." % tgt["name"]
		return

	for c_node in card_nodes:
		if is_instance_valid(c_node):
			_discard_player_card(c_node)

	var is_first_use := (local_van_an_uses == 0)
	local_van_an_uses += 1

	if is_first_use:
		var drawn = _draw_card_from_pile()
		_add_card_to_player_hand(drawn)

	tgt["has_bai_coc"] = true
	if tgt.has("avatar_node") and is_instance_valid(tgt["avatar_node"]):
		tgt["avatar_node"].set_delayed_trick("bai_coc", true)

	AudioManager.play_skill()
	_animate_showcase_card("Vạn An", "%s kích hoạt [Vạn An], đặt Bãi Cọc Bạch Đằng lên %s!" % [generals_data[my_seat]["name"], tgt["name"]])
	_add_log("🏯 %s bỏ 2 lá trên tay kích hoạt [Vạn An], đặt Bãi Cọc Bạch Đằng lên %s.%s" % [
		generals_data[my_seat]["name"],
		tgt["name"],
		" Lần đầu sử dụng trong lượt: rút 1 lá." if is_first_use else ""
	])

func _ensure_drum_reveal_modal() -> void:
	if drum_reveal_modal and is_instance_valid(drum_reveal_modal):
		return

	drum_reveal_modal = Control.new()
	drum_reveal_modal.name = "DrumRevealModal"
	drum_reveal_modal.set_anchors_preset(PRESET_FULL_RECT)
	drum_reveal_modal.mouse_filter = MOUSE_FILTER_STOP
	drum_reveal_modal.z_as_relative = false
	drum_reveal_modal.z_index = 320
	add_child(drum_reveal_modal)

	var dim = ColorRect.new()
	dim.set_anchors_preset(PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = MOUSE_FILTER_IGNORE
	drum_reveal_modal.add_child(dim)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(840, 440)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.1, 0.18, 0.98)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.88, 0.72, 0.25, 1.0) # Hoàng Kim / Đồng Sơn
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0, 6)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	drum_reveal_title_lbl = Label.new()
	drum_reveal_title_lbl.text = "🥁 ĐIỂM TRỐNG - TRỐNG ĐỒNG ĐÔNG SƠN"
	drum_reveal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drum_reveal_title_lbl.add_theme_font_size_override("font_size", 20)
	drum_reveal_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
	vbox.add_child(drum_reveal_title_lbl)

	drum_reveal_desc_lbl = Label.new()
	drum_reveal_desc_lbl.text = "Mục tiêu đã chọn lộ toàn bộ bài trên tay cho bạn xem:"
	drum_reveal_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drum_reveal_desc_lbl.add_theme_font_size_override("font_size", 12)
	drum_reveal_desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98, 1.0))
	vbox.add_child(drum_reveal_desc_lbl)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(780, 215)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	drum_reveal_cards_box = HBoxContainer.new()
	drum_reveal_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	drum_reveal_cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drum_reveal_cards_box.add_theme_constant_override("separation", 16)
	scroll.add_child(drum_reveal_cards_box)

	drum_reveal_status_lbl = Label.new()
	drum_reveal_status_lbl.text = "💡 Chạm hoặc nhấp vào từng lá bài để xem chi tiết tác dụng & mô tả."
	drum_reveal_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drum_reveal_status_lbl.add_theme_font_size_override("font_size", 12)
	drum_reveal_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	vbox.add_child(drum_reveal_status_lbl)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)

	drum_reveal_close_btn = Button.new()
	drum_reveal_close_btn.text = "✅ ĐÃ XEM XONG (ĐÓNG)"
	drum_reveal_close_btn.custom_minimum_size = Vector2(240, 42)
	drum_reveal_close_btn.focus_mode = Control.FOCUS_NONE
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.18, 0.28, 0.45, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.85, 0.7, 0.25, 1.0)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.corner_radius_bottom_left = 8
	drum_reveal_close_btn.add_theme_stylebox_override("normal", btn_style)
	drum_reveal_close_btn.add_theme_font_size_override("font_size", 13)
	drum_reveal_close_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 1.0))
	drum_reveal_close_btn.pressed.connect(func():
		if drum_reveal_modal and is_instance_valid(drum_reveal_modal):
			drum_reveal_dismissed = true
			drum_reveal_modal.visible = false
	)
	btn_hbox.add_child(drum_reveal_close_btn)

	drum_reveal_modal.visible = false

func _show_drum_reveal_modal(target_seat: int, cards: Array, reveal_source: String = "🥁 ĐIỂM TRỐNG") -> void:
	_ensure_drum_reveal_modal()
	if not generals_data.has(target_seat):
		return
	var tgt = generals_data[target_seat]
	var tgt_name = tgt.get("name", "Ghế %d" % target_seat)

	for c in drum_reveal_cards_box.get_children():
		c.queue_free()

	drum_reveal_title_lbl.text = "%s: TOÀN BỘ BÀI TRÊN TAY CỦA %s" % [reveal_source, tgt_name.to_upper()]
	drum_reveal_desc_lbl.text = "🎯 %s đã chọn lộ toàn bộ bài trên tay (%d lá) cho bạn xem:" % [tgt_name, cards.size()]
	drum_reveal_status_lbl.text = "💡 Chạm hoặc nhấp vào từng lá bài để xem chi tiết tác dụng & thuộc tính."

	for i in range(cards.size()):
		var c_info = cards[i]
		if not (c_info is Dictionary):
			continue
		var c_name = str(c_info.get("name", c_info.get("cardName", "Bài")))
		var c_id = str(c_info.get("id", ""))
		var c_suit = str(c_info.get("suit", "Heart")).strip_edges().capitalize()
		var c_rank = c_info.get("rank", 1)
		var c_cat = int(c_info.get("category", c_info.get("cat", 0)))
		var c_sub = int(c_info.get("subType", -1))
		var c_desc = str(c_info.get("desc", c_info.get("description", "")))

		# Tra cứu thêm từ database nếu thiếu thông tin mô tả hoặc danh mục
		var db_info = _find_card_dict_by_name(c_name)
		if not db_info.is_empty():
			if c_cat == 0 and db_info.has("cat"):
				c_cat = int(db_info["cat"])
			if c_sub < 0 and db_info.has("subType"):
				c_sub = int(db_info["subType"])
			if c_desc.is_empty() and db_info.has("desc"):
				c_desc = str(db_info["desc"])

		var card_ui = CardUIScene.instantiate()
		drum_reveal_cards_box.add_child(card_ui)
		card_ui.setup_card_data(c_id, c_name, c_rank, c_suit, c_cat, c_desc, c_sub)

		# Khi nhấp vào lá bài, phát âm thanh và hiển thị chi tiết ở thanh trạng thái
		var captured_name = c_name
		var captured_suit = c_suit
		var captured_rank = c_rank
		var captured_desc = c_desc
		card_ui.card_clicked.connect(func(clicked_node):
			for other_c in drum_reveal_cards_box.get_children():
				if other_c != clicked_node and other_c.has_method("set_selected"):
					other_c.set_selected(false)
			AudioManager.play_card_select()
			var s_icon = _get_suit_icon(captured_suit)
			var r_str = _format_rank(captured_rank)
			drum_reveal_status_lbl.text = "👉 [%s %s %s]: %s" % [s_icon, r_str, captured_name, captured_desc]
		)

	AudioManager.play_skill()
	drum_reveal_modal.visible = true

# ==========================================================
# 🏹 SONG CUNG MƯỜNG NHẠ: PHẢN ỨNG BỎ 2 LÁ ĐỂ TRẢM XUYÊN QUA ĐỠ
# ==========================================================
func _prompt_song_cung_modal(target_seat: int, timeout_sec: float = 40.0, damage_amount: int = 1, damage_element: String = "NORMAL") -> void:
	is_waiting_song_cung = true
	is_waiting_dodge = false
	song_cung_target_seat = target_seat
	song_cung_pending_damage = max(1, damage_amount)
	song_cung_pending_element = damage_element
	selected_song_cung_card_nodes.clear()
	dodge_time_left = timeout_sec
	current_waiting_timer = timeout_sec
	current_waiting_seat = my_seat

	var tgt = generals_data.get(target_seat, {})
	var tgt_name = tgt.get("name", "Ghế %d" % target_seat) if tgt is Dictionary else "Ghế %d" % target_seat

	dodge_title_lbl.text = "🏹 SONG CUNG MƯỜNG NHẠ"
	dodge_desc_lbl.text = "⚠️ Trảm bị Đỡ! Bỏ 2 lá trên tay hoặc trang bị đang mang để bỏ qua Đỡ: Trảm vẫn gây %d sát thương lên %s." % [song_cung_pending_damage, tgt_name]
	if dodge_timer_lbl:
		dodge_timer_lbl.text = "⏳ Còn lại: %ds" % int(timeout_sec)

	if dodge_khien_may_btn:
		dodge_khien_may_btn.visible = false

	dodge_pass_btn.text = "❌ BỎ QUA"
	dodge_pass_btn.visible = true
	dodge_pass_btn.disabled = false

	dodge_confirm_btn.text = "🏹 BỎ 2 LÁ BỎ QUA ĐỠ (0/2)"
	dodge_confirm_btn.visible = true
	dodge_confirm_btn.disabled = true

	dodge_card_selector_scroll.visible = false
	_build_song_cung_card_selector_buttons()

	_refresh_song_cung_equipped_previews()
	_set_reaction_hand_focus(true, "Bài", 0, false, false)

	_update_song_cung_ui()
	dodge_modal.visible = true

func _build_song_cung_card_selector_buttons() -> void:
	if dodge_card_selector_hbox:
		for ch in dodge_card_selector_hbox.get_children():
			ch.queue_free()
	if dodge_card_selector_scroll and is_instance_valid(dodge_card_selector_scroll):
		dodge_card_selector_scroll.visible = false

func _handle_song_cung_card_selection(card_node: Control) -> void:
	if not is_waiting_song_cung:
		return
	if not card_node or not is_instance_valid(card_node):
		return

	if selected_song_cung_card_nodes.has(card_node):
		selected_song_cung_card_nodes.erase(card_node)
		if card_node.has_method("set_selected"):
			card_node.set_selected(false)
		AudioManager.play_card_select()
	else:
		if selected_song_cung_card_nodes.size() >= 2:
			var oldest = selected_song_cung_card_nodes.pop_front()
			if oldest and is_instance_valid(oldest) and oldest.has_method("set_selected"):
				oldest.set_selected(false)
		selected_song_cung_card_nodes.append(card_node)
		if card_node.has_method("set_selected"):
			card_node.set_selected(true)
		AudioManager.play_card_select()

	_update_song_cung_ui()

func _update_song_cung_ui() -> void:
	var count = selected_song_cung_card_nodes.size()
	dodge_confirm_btn.text = "🏹 BỎ 2 LÁ BỎ QUA ĐỠ (%d/2)" % count
	dodge_confirm_btn.disabled = (count != 2)

	var tgt = generals_data.get(song_cung_target_seat, {})
	var tgt_name = tgt.get("name", "Ghế %d" % song_cung_target_seat) if tgt is Dictionary else "Ghế %d" % song_cung_target_seat

	if count == 2:
		var n1 = _get_card_info_from_ui(selected_song_cung_card_nodes[0]).get("name", "Lá 1")
		var n2 = _get_card_info_from_ui(selected_song_cung_card_nodes[1]).get("name", "Lá 2")
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "✅ Đã chọn 2 lá: [%s] và [%s]" % [n1, n2]
		desc_text.text = "🏹 Đã chọn đủ 2 lá! Bấm nút để bỏ qua Đỡ: Trảm gây %d sát thương lên %s." % [song_cung_pending_damage, tgt_name]
	elif count == 1:
		var n1 = _get_card_info_from_ui(selected_song_cung_card_nodes[0]).get("name", "Lá 1")
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "👉 Đã chọn 1 lá: [%s]. Hãy chọn thêm 1 lá nữa (1/2)." % n1
		desc_text.text = "🏹 Hãy chọn thêm 1 lá trên tay hoặc đang mang (1/2), hoặc bấm BỎ QUA."
	else:
		if dodge_selected_lbl:
			dodge_selected_lbl.text = "👉 Chọn 2 lá trên tay hoặc đang mang để bỏ (hoặc bấm BỎ QUA)"
		desc_text.text = "🏹 Chạm chọn 2 lá bài trên tay hoặc đang mang để bỏ, hoặc bấm [❌ BỎ QUA]."

func _close_song_cung_modal() -> void:
	is_waiting_song_cung = false
	dodge_modal.visible = false
	dodge_card_selector_scroll.visible = false
	for node in selected_song_cung_card_nodes:
		if node and is_instance_valid(node) and node.has_method("set_selected"):
			node.set_selected(false)
	selected_song_cung_card_nodes.clear()
	_clear_song_cung_equipped_previews()
	_set_reaction_hand_focus(false)

func _on_song_cung_confirmed() -> void:
	if not is_waiting_song_cung:
		return
	if selected_song_cung_card_nodes.size() != 2:
		return

	var card_nodes = selected_song_cung_card_nodes.duplicate()
	var card_ids: Array = []
	var card_names: Array = []
	for node in card_nodes:
		if node and is_instance_valid(node):
			var info = _get_card_info_from_ui(node)
			card_ids.append(str(info.get("id", info.get("name", ""))))
			card_names.append(str(info.get("name", "Bài")))

	if is_network_mode:
		_close_song_cung_modal()
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		NetworkClient.send_respond_action(true, "", "", card_ids)
		_animate_showcase_card("Song Cung Mường Nhạ", "Bạn bỏ 2 lá kích hoạt Song Cung!")
		_add_log("🏹 Bạn bỏ 2 lá [%s, %s] kích hoạt [Song Cung Mường Nhạ]!" % [card_names[0], card_names[1]])
		AudioManager.play_voice("Song Cung Mường Nhạ")
		AudioManager.play_skill()
	else:
		# Local Mode: selected equipment is discarded from its equipped slot too.
		for node in card_nodes:
			if node and is_instance_valid(node) and node.get_parent() == hand_container:
				var card_info = _get_card_info_from_ui(node)
				if bool(card_info.get("is_equipped", false)):
					_remove_local_equipment_for_song_cung(str(card_info.get("id", "")))
				hand_container.remove_child(node)
				node.queue_free()
		_close_song_cung_modal()
		if generals_data.has(my_seat):
			var g = generals_data[my_seat]
			g["hand_count"] = hand_container.get_child_count()
			if g.has("avatar_node") and is_instance_valid(g["avatar_node"]):
				g["avatar_node"].update_hand_count(g["hand_count"])
		_relayout_hand_cards()
		AudioManager.play_voice("Song Cung Mường Nhạ")
		AudioManager.play_card_draw()

		if song_cung_local_callback.is_valid():
			var cb = song_cung_local_callback
			song_cung_local_callback = Callable()
			cb.call(true, card_nodes)
		song_cung_response_finished.emit(true)

func _remove_local_equipment_for_song_cung(equipment_id: String) -> void:
	if equipment_id.is_empty() or not generals_data.has(my_seat):
		return
	var g = generals_data[my_seat]
	if equipment_id.begins_with("LOCAL_EQUIP_"):
		var slot_key := equipment_id.trim_prefix("LOCAL_EQUIP_")
		var slot_to_avatar := {
			"equipped_weapon": ["weapon", ""],
			"equipped_armor": ["armor", ""],
			"equipped_def_horse": ["def_horse", ""],
			"equipped_off_horse": ["off_horse", ""],
			"equipped_treasure": ["treasure", ""]
		}
		if slot_to_avatar.has(slot_key):
			g[slot_key] = ""
			var avatar = g.get("avatar_node")
			if is_instance_valid(avatar):
				avatar.set_equipment(str(slot_to_avatar[slot_key][0]), "", "")
			return
	var equips: Array = g.get("equipment_cards", [])
	var index := -1
	for i in range(equips.size()):
		if equips[i] is Dictionary and str(equips[i].get("id", "")) == equipment_id:
			index = i
			break
	if index < 0:
		return
	equips.remove_at(index)
	g["equipment_cards"] = equips
	_sync_player_equipments_from_server(my_seat, equips)

func _on_song_cung_passed() -> void:
	if not is_waiting_song_cung:
		return

	_close_song_cung_modal()

	if is_network_mode:
		reaction_submission_pending = true
		reaction_submission_version = last_server_version
		NetworkClient.send_respond_action(false)
		_add_log("🏹 Bạn chọn BỎ QUA kích hoạt Song Cung Mường Nhạ.")
	else:
		_add_log("🏹 Bạn chọn BỎ QUA kích hoạt Song Cung Mường Nhạ.")
		if song_cung_local_callback.is_valid():
			var cb = song_cung_local_callback
			song_cung_local_callback = Callable()
			cb.call(false, [])
		song_cung_response_finished.emit(false)

func _prompt_song_cung_async(target_seat: int, timeout_sec: float = 40.0, damage_amount: int = 1, damage_element: String = "NORMAL") -> bool:
	_prompt_song_cung_modal(target_seat, timeout_sec, damage_amount, damage_element)
	var result = await song_cung_response_finished
	return result

func _resolve_local_song_cung_if_applicable(attacker_seat: int, target_seat: int, damage_amount: int = 1, damage_element: String = "NORMAL") -> void:
	if is_network_mode:
		return
	var atk = generals_data.get(attacker_seat, {})
	var tgt = generals_data.get(target_seat, {})
	var weapon = atk.get("equipped_weapon", "")
	if weapon != "Song Cung Mường Nhạ":
		return

	# Case 1: Attacker is the Local Player
	if attacker_seat == my_seat:
		var usable_equipment_count := 0
		for equipment in atk.get("equipment_cards", []):
			if equipment is Dictionary and _get_card_display_name(equipment) != "Song Cung Mường Nhạ":
				usable_equipment_count += 1
		var hand_cards_count = hand_container.get_child_count() + usable_equipment_count
		if hand_cards_count < 2:
			_add_log("🏹 [Song Cung Mường Nhạ]: Bạn không đủ 2 lá trên tay hoặc đang mang để kích hoạt.")
			return
		var accepted = await _prompt_song_cung_async(target_seat, 40.0, damage_amount, damage_element)
		if accepted:
			_add_log("🏹 [Song Cung Mường Nhạ] của bạn bỏ 2 lá, bỏ qua Đỡ: Trảm gây %d sát thương lên %s!" % [damage_amount, tgt.get("name", "Ghế %d" % target_seat)])
			AudioManager.play_skill()
			_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)

	# Case 2: Attacker is an AI bot
	else:
		var ai_hand_cards = atk.get("hand_cards", [])
		var ai_hand_count = int(atk.get("hand_count", ai_hand_cards.size()))
		if ai_hand_count >= 2:
			var atk_dragon = atk.get("isDragon", false)
			var tgt_dragon = tgt.get("isDragon", false)
			var is_enemy = (atk_dragon != tgt_dragon)
			if is_enemy:
				if not ai_hand_cards.is_empty() and ai_hand_cards.size() >= 2:
					ai_hand_cards.pop_front()
					ai_hand_cards.pop_front()
					atk["hand_count"] = ai_hand_cards.size()
				else:
					atk["hand_count"] = max(0, ai_hand_count - 2)
				if atk.has("avatar_node") and is_instance_valid(atk["avatar_node"]):
					atk["avatar_node"].update_hand_count(atk["hand_count"])
				_add_log("🏹 [Song Cung Mường Nhạ] của <b>%s</b> bỏ 2 lá, bỏ qua Đỡ: Trảm gây %d sát thương lên <b>%s</b>!" % [atk.get("name", "AI"), damage_amount, tgt.get("name", "Ghế %d" % target_seat)])
				AudioManager.play_skill()
				_apply_damage_to_general(target_seat, damage_amount, attacker_seat, damage_element)
