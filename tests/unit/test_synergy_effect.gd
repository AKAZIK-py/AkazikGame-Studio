# test_synergy_effect.gd
# Unit tests for SynergyEffectSystem

extends "res://tests/unit/test_base.gd"

var _effect_system: SynergyEffectSystem
var _detection_system: SynergyDetectionSystem
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

	_detection_system = SynergyDetectionSystem.new()
	_detection_system.board_system = _board
	add_child(_detection_system)

	_effect_system = SynergyEffectSystem.new()
	_effect_system.detection_system = _detection_system
	_effect_system.board_system = _board
	add_child(_effect_system)


func after_each() -> void:
	if _effect_system:
		_effect_system.queue_free()
	if _detection_system:
		_detection_system.queue_free()
	if _board:
		_board.queue_free()
	_effect_system = null
	_detection_system = null
	_board = null
	super.after_each()


func test_base_attributes() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	# 无羁绊激活，应该是基础属性
	_detection_system.detect_active_synergies()
	_effect_system.apply_synergy_effects(instance)

	assert_eq(instance.current_attack, a_zi.base_attack, "Should have base attack")
	assert_eq(instance.max_health, a_zi.base_health, "Should have base health")


func test_vr_attack_bonus() -> void:
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")  # VR, base_attack=48
	var a_zi := CharacterRegistry.get_character("a_zi")        # VR, base_attack=70

	var instance1 := _board.place_character(xiao_ke, 0, 0)
	var instance2 := _board.place_character(a_zi, 1, 0)

	_detection_system.detect_active_synergies()

	# 应用效果
	_effect_system.apply_synergy_effects(instance1)
	_effect_system.apply_synergy_effects(instance2)

	# VR 1级加成：攻击力+15%
	var expected_attack := int(48 * 1.15)
	assert_eq(instance1.current_attack, expected_attack, "Xiao Ke should have VR bonus")


func test_idol_health_bonus() -> void:
	var lu_lulu := CharacterRegistry.get_character("lu_lulu")    # idol, base_health=720
	var tian_dou := CharacterRegistry.get_character("tian_dou")  # idol, base_health=780

	var instance1 := _board.place_character(lu_lulu, 0, 0)
	var instance2 := _board.place_character(tian_dou, 1, 0)

	_detection_system.detect_active_synergies()

	_effect_system.apply_synergy_effects(instance1)

	# 偶像1级加成：生命值+12%
	var expected_health := int(720 * 1.12)
	assert_eq(instance1.max_health, expected_health, "Lu lulu should have idol health bonus")


func test_eoe_sisters_bonus() -> void:
	var lu_zao := CharacterRegistry.get_character("lu_zao")  # 1费, base_attack=44
	var you_en := CharacterRegistry.get_character("you_en")  # 1费, base_attack=42

	var instance1 := _board.place_character(lu_zao, 0, 0)
	var instance2 := _board.place_character(you_en, 1, 0)

	_detection_system.detect_active_synergies()

	_effect_system.apply_synergy_effects(instance1)
	_effect_system.apply_synergy_effects(instance2)

	# EOE姐妹加成：攻击×1.8, 生命×1.5
	var expected_attack := int(44 * 1.8)
	var expected_health := int(580 * 1.5)

	assert_eq(instance1.current_attack, expected_attack, "Lu Zao should have EOE attack bonus")
	assert_eq(instance1.max_health, expected_health, "Lu Zao should have EOE health bonus")


func test_multiple_synergies() -> void:
	# 阿梓有 VR, singer, candy 三个羁绊
	var a_zi := CharacterRegistry.get_character("a_zi")
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")    # VR, singer
	var xue_gao := CharacterRegistry.get_character("xue_gao")   # candy

	_board.place_character(a_zi, 0, 0)
	_board.place_character(xiao_ke, 1, 0)
	_board.place_character(xue_gao, 2, 0)

	var a_zi_instance := _board.get_character_at(0, 0)

	_detection_system.detect_active_synergies()
	_effect_system.apply_synergy_effects(a_zi_instance)

	# 阿梓应该有：
	# - VR攻击加成15%（与xiao_ke）
	# - singer技能伤害加成20%（与xiao_ke）
	# - candy攻速加成15%（与xue_gao）
	var synergy_summary := _effect_system.get_character_synergy_summary(a_zi_instance)

	assert_true("VR" in synergy_summary.active_synergies, "Should have VR active")
	assert_true("singer" in synergy_summary.active_synergies, "Should have singer active")
	assert_true("candy" in synergy_summary.active_synergies, "Should have candy active")


func test_attribute_cap() -> void:
	# 测试属性上限
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")

	var instance := _board.place_character(xiao_ke, 0, 0)
	_detection_system.detect_active_synergies()
	_effect_system.apply_synergy_effects(instance)

	# 属性不应超过基础的300%
	var max_attack := xiao_ke.base_attack * 3
	var max_health := xiao_ke.base_health * 3

	assert_true(instance.current_attack <= max_attack, "Attack should not exceed cap")
	assert_true(instance.max_health <= max_health, "Health should not exceed cap")


func test_effect_config() -> void:
	var effect := _effect_system.get_synergy_effect("VR", 1)
	assert_eq(effect.attack_bonus, 0.15, "VR level 1 should give 15% attack bonus")

	effect = _effect_system.get_synergy_effect("VR", 2)
	assert_eq(effect.attack_bonus, 0.30, "VR level 2 should give 30% attack bonus")

	effect = _effect_system.get_synergy_effect("idol", 2)
	assert_eq(effect.health_bonus, 0.25, "Idol level 2 should give 25% health bonus")
