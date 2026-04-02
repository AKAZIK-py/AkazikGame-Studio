# test_battle_ai_system.gd
# Unit tests for BattleAISystem

extends "res://tests/unit/test_base.gd"

var _ai: BattleAISystem
var _board: BoardSystem


func before_all() -> void:
	CharacterRegistry.initialize()
	SynergyRegistry.initialize()


func before_each() -> void:
	super.before_each()
	_board = BoardSystem.new()
	_board.board_rows = 8
	_board.board_cols = 7
	add_child(_board)

	_ai = BattleAISystem.new()
	_ai.board_system = _board
	add_child(_ai)


func after_each() -> void:
	if _ai:
		_ai.queue_free()
	if _board:
		_board.queue_free()
	_ai = null
	_board = null


# ============================================
# 攻击范围测试
# ============================================

func test_melee_attack_range() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("xiao_ke")
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, Vector2i(0, 0))
	assert_eq(_ai.get_attack_range(instance), 1)


func test_tank_attack_range() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("bai_shen_yao")
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, Vector2i(0, 0))
	assert_eq(_ai.get_attack_range(instance), 1)


func test_mage_attack_range() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("ze_yin")
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, Vector2i(0, 0))
	assert_eq(_ai.get_attack_range(instance), 3)


func test_core_attack_range() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("xing_tong")
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, Vector2i(0, 0))
	assert_eq(_ai.get_attack_range(instance), 2)


func test_support_attack_range() -> void:
	var char_data: CharacterData = CharacterRegistry.get_character("dong_ai_li")
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, Vector2i(0, 0))
	assert_eq(_ai.get_attack_range(instance), 2)


# ============================================
# 目标选择测试
# ============================================

func test_select_target_lowest_hp() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 0))
	# 敌人放在攻击范围内（xiao_ke 是 output，攻击范围 1）
	var enemy1: CharacterInstance = _create_instance("a_zi", Vector2i(1, 0))
	var enemy2: CharacterInstance = _create_instance("ze_yin", Vector2i(0, 1))

	enemy1.current_health = 100
	enemy2.current_health = 50

	var enemies: Array[CharacterInstance] = [enemy1, enemy2]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "attack", "Should attack")
	if String(action.get("type", "")) == "attack":
		var target: CharacterInstance = action.get("target")
		assert_eq(target.character_id, "ze_yin", "Should target lowest HP enemy")


func test_select_target_nearest() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 0))
	var enemy1: CharacterInstance = _create_instance("a_zi", Vector2i(5, 0))
	var enemy2: CharacterInstance = _create_instance("ze_yin", Vector2i(1, 0))

	enemy1.current_health = 50
	enemy2.current_health = 50

	var enemies: Array[CharacterInstance] = [enemy1, enemy2]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	if String(action.get("type", "")) == "attack":
		var target: CharacterInstance = action.get("target")
		assert_eq(target.character_id, "ze_yin", "Should target nearest enemy")


# ============================================
# 攻击决策测试
# ============================================

func test_attack_when_in_range() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 0))
	var enemy: CharacterInstance = _create_instance("a_zi", Vector2i(1, 0))

	var enemies: Array[CharacterInstance] = [enemy]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "attack", "Should attack when in range")


func test_move_when_out_of_range() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 0))
	var enemy: CharacterInstance = _create_instance("a_zi", Vector2i(3, 0))

	var enemies: Array[CharacterInstance] = [enemy]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "move", "Should move when out of range")


func test_mage_attacks_from_distance() -> void:
	var attacker: CharacterInstance = _create_instance("a_zi", Vector2i(0, 0))
	var enemy: CharacterInstance = _create_instance("xiao_ke", Vector2i(2, 0))

	var enemies: Array[CharacterInstance] = [enemy]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "attack", "Mage should attack from distance")


# ============================================
# 边界情况测试
# ============================================

func test_no_enemies_default_forward() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 4))

	var enemies: Array[CharacterInstance] = []
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "move", "Should move forward when no enemies")


func test_enemy_dead_ignored() -> void:
	var attacker: CharacterInstance = _create_instance("xiao_ke", Vector2i(0, 0))
	var enemy: CharacterInstance = _create_instance("a_zi", Vector2i(1, 0))
	enemy.current_health = 0

	var enemies: Array[CharacterInstance] = [enemy]
	var action: Dictionary = _ai.decide_action(attacker, enemies)

	assert_eq(action.get("type", ""), "move", "Should move when all enemies are dead")


# ============================================
# 辅助方法
# ============================================

func _create_instance(character_id: String, pos: Vector2i) -> CharacterInstance:
	var char_data: CharacterData = CharacterRegistry.get_character(character_id)
	var instance: CharacterInstance = CharacterInstance.from_data(char_data, pos)
	instance.current_health = 100
	instance.max_health = 100
	instance.current_attack = char_data.base_attack
	return instance
