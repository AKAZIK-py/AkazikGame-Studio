# test_synergy_detection.gd
# Unit tests for SynergyDetectionSystem

extends "res://tests/unit/test_base.gd"

var _detection: SynergyDetectionSystem
var _board: BoardSystem


func before_all() -> void:
	CharacterRegistry.initialize()
	SynergyRegistry.initialize()


func before_each() -> void:
	super.before_each()
	_board = BoardSystem.new()
	_board.board_rows = 4
	_board.board_cols = 8
	add_child(_board)

	_detection = SynergyDetectionSystem.new()
	_detection.board_system = _board
	add_child(_detection)


func after_each() -> void:
	if _detection:
		_detection.queue_free()
	if _board:
		_board.queue_free()
	_detection = null
	_board = null
	super.after_each()


func test_empty_board() -> void:
	var active: Dictionary = _detection.detect_active_synergies()
	assert_eq(active.size(), 0, "Empty board should have no active synergies")


func test_single_character_synergy() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("a_zi")
	_board.place_character(char_data, 0, 0)

	_detection.detect_active_synergies()

	assert_eq(_detection.get_synergy_count("VR"), 1, "Should have 1 VR character")
	assert_eq(_detection.get_synergy_count("singer"), 1, "Should have 1 singer")
	assert_eq(_detection.get_synergy_count("candy"), 1, "Should have 1 candy")


func test_vr_synergy_activation() -> void:
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var a_zi: CharacterData = CharacterRegistry.get_character("a_zi")

	_board.place_character(xiao_ke, 0, 0)
	_board.place_character(a_zi, 1, 0)

	_detection.detect_active_synergies()

	assert_true(_detection.is_synergy_active("VR"), "VR synergy should be active")
	assert_eq(_detection.get_synergy_level("VR"), 1, "VR should be level 1 with 2 characters")


func test_vr_synergy_level_2() -> void:
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var a_zi: CharacterData = CharacterRegistry.get_character("a_zi")
	var qi_hai: CharacterData = CharacterRegistry.get_character("qi_hai")
	var tian_dou: CharacterData = CharacterRegistry.get_character("tian_dou")

	_board.place_character(xiao_ke, 0, 0)
	_board.place_character(a_zi, 1, 0)
	_board.place_character(qi_hai, 2, 0)
	_board.place_character(tian_dou, 3, 0)

	_detection.detect_active_synergies()

	assert_true(_detection.is_synergy_active("VR"), "VR synergy should be active")
	assert_eq(_detection.get_synergy_level("VR"), 2, "VR should be level 2 with 4 characters")


func test_idol_synergy_levels() -> void:
	var lu_lulu: CharacterData = CharacterRegistry.get_character("lu_lulu")
	var tian_dou: CharacterData = CharacterRegistry.get_character("tian_dou")
	var qi_hai: CharacterData = CharacterRegistry.get_character("qi_hai")
	var yong_chu_ta_fei: CharacterData = CharacterRegistry.get_character("yong_chu_ta_fei")
	var xing_tong: CharacterData = CharacterRegistry.get_character("xing_tong")

	# 2人激活1级
	_board.place_character(lu_lulu, 0, 0)
	_board.place_character(tian_dou, 1, 0)

	_detection.detect_active_synergies()
	assert_eq(_detection.get_synergy_level("idol"), 1, "Idol should be level 1")

	# 4人激活2级
	_board.place_character(qi_hai, 2, 0)
	_board.place_character(yong_chu_ta_fei, 3, 0)

	_detection.detect_active_synergies()
	assert_eq(_detection.get_synergy_level("idol"), 2, "Idol should be level 2")

	# 5人激活3级
	_board.place_character(xing_tong, 4, 0)

	_detection.detect_active_synergies()
	assert_eq(_detection.get_synergy_level("idol"), 3, "Idol should be level 3")


func test_eoe_sisters_combo() -> void:
	var lu_zao: CharacterData = CharacterRegistry.get_character("lu_zao")
	var you_en: CharacterData = CharacterRegistry.get_character("you_en")

	_board.place_character(lu_zao, 0, 0)
	_board.place_character(you_en, 1, 0)

	_detection.detect_active_synergies()

	assert_true(_detection.is_eoe_sisters_active(), "EOE sisters should be active")


func test_eoe_sisters_only_one() -> void:
	var lu_zao: CharacterData = CharacterRegistry.get_character("lu_zao")
	_board.place_character(lu_zao, 0, 0)

	_detection.detect_active_synergies()

	assert_false(_detection.is_eoe_sisters_active(), "EOE sisters should not be active with only one")


func test_synergy_progress() -> void:
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var a_zi: CharacterData = CharacterRegistry.get_character("a_zi")

	_board.place_character(xiao_ke, 0, 0)
	_board.place_character(a_zi, 1, 0)

	_detection.detect_active_synergies()
	var progress: Dictionary = _detection.get_all_synergy_progress()

	assert_true(progress.has("VR"), "Should have VR in progress")
	assert_eq(progress["VR"]["count"], 2, "VR count should be 2")
	assert_eq(progress["VR"]["level"], 1, "VR level should be 1")


func test_character_removal() -> void:
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var a_zi: CharacterData = CharacterRegistry.get_character("a_zi")

	_board.place_character(xiao_ke, 0, 0)
	_board.place_character(a_zi, 1, 0)

	_detection.detect_active_synergies()
	assert_true(_detection.is_synergy_active("VR"))

	# 移除一个角色
	_board.remove_character(1, 0)

	_detection.detect_active_synergies()
	assert_false(_detection.is_synergy_active("VR"), "VR should not be active after removal")


# ============================================
# 万能羁绊（狍子/东爱璃）测试
# ============================================

func test_wildcard_picks_most_numerous_synergy() -> void:
	var dong_ai_li: CharacterData = CharacterRegistry.get_character("dong_ai_li")
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var a_zi: CharacterData = CharacterRegistry.get_character("a_zi")
	var ze_yin: CharacterData = CharacterRegistry.get_character("ze_yin")

	_board.place_character(dong_ai_li, 0, 0)
	_board.place_character(xiao_ke, 1, 0)
	_board.place_character(a_zi, 2, 0)
	_board.place_character(ze_yin, 3, 0)

	_detection.detect_active_synergies()

	# VR: xiao_ke, a_zi = 2
	# singer: xiao_ke, a_zi, ze_yin = 3
	# 万能羁绊选择数量最多的 singer
	var singer_count: int = _detection.get_synergy_count("singer")
	assert_eq(singer_count, 4, "Deer should join singer (most numerous synergy with 3 base + 1 deer)")


func test_wildcard_picks_upgrade_synergy() -> void:
	var dong_ai_li: CharacterData = CharacterRegistry.get_character("dong_ai_li")
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")

	_board.place_character(dong_ai_li, 0, 0)
	_board.place_character(xiao_ke, 1, 0)

	_detection.detect_active_synergies()

	assert_true(
		_detection.is_synergy_active("VR") or _detection.is_synergy_active("singer"),
		"Deer should activate either VR or singer"
	)


func test_wildcard_alone_no_synergy() -> void:
	var dong_ai_li: CharacterData = CharacterRegistry.get_character("dong_ai_li")

	_board.place_character(dong_ai_li, 0, 0)

	_detection.detect_active_synergies()

	var active: Dictionary = _detection.get_active_synergies()
	assert_eq(active.size(), 0, "Single deer should not activate any synergy")


func test_wildcard_with_upgrade_possible() -> void:
	var dong_ai_li: CharacterData = CharacterRegistry.get_character("dong_ai_li")
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var ze_yin: CharacterData = CharacterRegistry.get_character("ze_yin")

	_board.place_character(dong_ai_li, 0, 0)
	_board.place_character(xiao_ke, 1, 0)
	_board.place_character(ze_yin, 2, 0)

	_detection.detect_active_synergies()

	# VR: xiao_ke = 1, +1 = 2 会升级（阈值 [2, 4]）
	# singer: xiao_ke, ze_yin = 2, +1 = 3 不会升级（阈值 [2, 4]）
	# 万能羁绊优先选择能升级的 VR
	assert_true(_detection.is_synergy_active("VR"), "VR should be active with deer upgrade")
	assert_eq(_detection.get_synergy_level("VR"), 1, "VR should be level 1 with deer")


func test_multiple_wildcards_different_synergies() -> void:
	var dong_ai_li: CharacterData = CharacterRegistry.get_character("dong_ai_li")
	var xiao_ke: CharacterData = CharacterRegistry.get_character("xiao_ke")

	_board.place_character(dong_ai_li, 0, 0)
	_board.place_character(xiao_ke, 1, 0)

	_detection.detect_active_synergies()

	var singer_count: int = _detection.get_synergy_count("singer")
	var vr_count: int = _detection.get_synergy_count("VR")

	assert_true(singer_count > 0 or vr_count > 0, "Deer should join at least one synergy")
