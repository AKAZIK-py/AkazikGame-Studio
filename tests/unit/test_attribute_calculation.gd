# test_attribute_calculation.gd
# Unit tests for AttributeCalculationSystem

extends "res://tests/unit/test_base.gd"

var _attr_calc: AttributeCalculationSystem
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

	_attr_calc = AttributeCalculationSystem.new()
	_attr_calc.synergy_effect_system = _effect_system
	_attr_calc.board_system = _board
	add_child(_attr_calc)


func after_each() -> void:
	if _attr_calc:
		_attr_calc.queue_free()
	if _effect_system:
		_effect_system.queue_free()
	if _detection_system:
		_detection_system.queue_free()
	if _board:
		_board.queue_free()
	_attr_calc = null
	_effect_system = null
	_detection_system = null
	_board = null
	super.after_each()


func test_calculate_final_attributes() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	var attrs := _attr_calc.calculate_final_attributes(instance)

	assert_true(attrs.has("attack"), "Should have attack attribute")
	assert_true(attrs.has("health"), "Should have health attribute")
	assert_eq(attrs.attack, a_zi.base_attack, "Should have base attack")


func test_get_final_attack() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	_detection_system.detect_active_synergies()
	_attr_calc.calculate_final_attributes(instance)

	var attack := _attr_calc.get_final_attack(instance)
	assert_gt(attack, 0, "Should have positive attack")


func test_get_final_health() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	_detection_system.detect_active_synergies()
	_attr_calc.calculate_final_attributes(instance)

	var health := _attr_calc.get_final_health(instance)
	assert_gt(health, 0, "Should have positive health")


func test_calculate_combat_power() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	_detection_system.detect_active_synergies()
	_attr_calc.calculate_final_attributes(instance)

	var power := _attr_calc.calculate_combat_power(instance)
	assert_gt(power, 0, "Should have positive combat power")


func test_team_combat_power() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")

	_board.place_character(a_zi, 0, 0)
	_board.place_character(xiao_ke, 1, 0)

	_attr_calc.calculate_all_attributes()

	var team_power := _attr_calc.calculate_team_combat_power()
	assert_gt(team_power, 0, "Team should have positive combat power")


func test_team_stats() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")

	_board.place_character(a_zi, 0, 0)
	_board.place_character(xiao_ke, 1, 0)

	_attr_calc.calculate_all_attributes()

	var stats := _attr_calc.get_team_stats()

	assert_eq(stats.character_count, 2, "Should have 2 characters")
	assert_gt(stats.total_attack, 0, "Should have total attack")
	assert_gt(stats.total_health, 0, "Should have total health")


func test_attribute_summary() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := _board.place_character(a_zi, 0, 0)

	_attr_calc.calculate_all_attributes()

	var summary := _attr_calc.get_character_attribute_summary(instance)

	assert_eq(summary.character_id, "a_zi", "Should have correct character ID")
	assert_eq(summary.display_name, "阿梓", "Should have correct display name")
	assert_eq(summary.rarity, 3, "Should have correct rarity")
