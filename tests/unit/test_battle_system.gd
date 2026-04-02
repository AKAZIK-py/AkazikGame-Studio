# test_battle_system.gd
# Unit tests for BattleSystem

extends "res://tests/unit/test_base.gd"

var _battle: BattleSystem
var _board: BoardSystem
var _attr_calc: AttributeCalculationSystem
var _synergy_effect: SynergyEffectSystem
var _synergy_detection: SynergyDetectionSystem


func before_all() -> void:
	CharacterRegistry.initialize()
	SynergyRegistry.initialize()


func before_each() -> void:
	super.before_each()
	_board = BoardSystem.new()
	_board.board_rows = 4
	_board.board_cols = 8
	add_child(_board)

	_synergy_detection = SynergyDetectionSystem.new()
	_synergy_detection.board_system = _board
	add_child(_synergy_detection)

	_synergy_effect = SynergyEffectSystem.new()
	_synergy_effect.detection_system = _synergy_detection
	_synergy_effect.board_system = _board
	add_child(_synergy_effect)

	_attr_calc = AttributeCalculationSystem.new()
	_attr_calc.synergy_effect_system = _synergy_effect
	_attr_calc.board_system = _board
	add_child(_attr_calc)

	_battle = BattleSystem.new()
	_battle.attribute_calc = _attr_calc
	_battle.synergy_effect = _synergy_effect
	_battle.synergy_detection = _synergy_detection
	_battle.board_system = _board
	add_child(_battle)


func after_each() -> void:
	if _battle:
		_battle.queue_free()
	if _attr_calc:
		_attr_calc.queue_free()
	if _synergy_effect:
		_synergy_effect.queue_free()
	if _synergy_detection:
		_synergy_detection.queue_free()
	if _board:
		_board.queue_free()
	_battle = null
	_attr_calc = null
	_synergy_effect = null
	_synergy_detection = null
	_board = null
	super.after_each()


func test_calculate_character_power() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var instance := CharacterInstance.from_data(a_zi, Vector2i(0, 0))

	var power := _battle.calculate_character_power(instance)
	assert_gt(power, 0, "Character should have positive power")


func test_calculate_team_power() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	var xiao_ke := CharacterRegistry.get_character("xiao_ke")

	var team: Array = [
		CharacterInstance.from_data(a_zi, Vector2i(0, 0)),
		CharacterInstance.from_data(xiao_ke, Vector2i(1, 0))
	]

	var power := _battle.calculate_team_power(team)
	assert_gt(power, 0, "Team should have positive power")


func test_win_rate_calculation() -> void:
	var team1: Array = [
		CharacterInstance.from_data(CharacterRegistry.get_character("a_zi"), Vector2i(0, 0))
	]
	var team2: Array = [
		CharacterInstance.from_data(CharacterRegistry.get_character("xiao_ke"), Vector2i(0, 0))
	]

	var win_rate := _battle.calculate_win_rate(team1, team2)

	assert_gt(win_rate, 0.0, "Win rate should be > 0")
	assert_lt(win_rate, 1.0, "Win rate should be < 1")


func test_win_rate_equal_teams() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")

	var team: Array = [
		CharacterInstance.from_data(a_zi, Vector2i(0, 0))
	]

	var win_rate := _battle.calculate_win_rate(team, team.duplicate())

	assert_almost_eq(win_rate, 0.5, 0.01, "Equal teams should have ~50% win rate")


func test_win_rate_empty_team() -> void:
	var team: Array = []

	var win_rate := _battle.calculate_win_rate(team, team)
	assert_eq(win_rate, 0.5, "Both empty should return 50%")


func test_execute_battle_empty_board() -> void:
	var result := _battle.execute_battle()

	assert_true(result.has("error"), "Should have error for empty board")
	assert_eq(result.error, "empty_team")


func test_execute_battle_with_characters() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	_board.place_character(a_zi, 0, 0)

	var result := _battle.execute_battle()

	assert_false(result.has("error"), "Should not have error")
	assert_true(result.has("win_rate"), "Should have win_rate")
	assert_true(result.has("player_wins"), "Should have player_wins")


func test_battle_result_values() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	_board.place_character(a_zi, 0, 0)

	var result := _battle.execute_battle()

	assert_gt(result.player_power, 0, "Player power should be > 0")
	assert_gt(result.enemy_power, 0, "Enemy power should be > 0")
	assert_gt(result.win_rate, 0.0, "Win rate should be > 0")
	assert_lt(result.win_rate, 1.0, "Win rate should be < 1")


func test_role_coefficients() -> void:
	assert_eq(BattleSystem.ROLE_COEFFICIENTS["output"], 1.1, "Output coeff should be 1.1")
	assert_eq(BattleSystem.ROLE_COEFFICIENTS["tank"], 1.0, "Tank coeff should be 1.0")
	assert_eq(BattleSystem.ROLE_COEFFICIENTS["support"], 0.9, "Support coeff should be 0.9")
	assert_eq(BattleSystem.ROLE_COEFFICIENTS["core"], 1.2, "Core coeff should be 1.2")


func test_get_enemy_team() -> void:
	var a_zi := CharacterRegistry.get_character("a_zi")
	_board.place_character(a_zi, 0, 0)

	_battle.execute_battle()

	var enemy := _battle.get_enemy_team()
	assert_gt(enemy.size(), 0, "Should have enemy team")
