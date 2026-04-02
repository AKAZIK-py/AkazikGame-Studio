# GameState.gd
# 游戏状态单例
# 管理全局游戏状态：阶段、棋盘、商店、战斗结果
# Autoload: GameState (无需 class_name)
extends Node

# PRODUCTION CODE - V-Tacit Game State System
# Implements: design/gdd/game-state.md

## 信号：游戏阶段改变
signal phase_changed(old_phase: String, new_phase: String)

## 信号：棋盘状态改变
signal board_changed()

## 信号：角色放置
signal character_placed(instance: CharacterInstance, q: int, r: int)

## 信号：角色移除
signal character_removed(instance: CharacterInstance, q: int, r: int)

## 信号：棋盘清空
signal board_cleared()

## 信号：敌方棋盘更新
signal enemy_board_changed()

## 信号：商店刷新
signal shop_refreshed(cards: Array)

## 信号：战斗结果
signal battle_completed(result: Dictionary)

## 信号：游戏重置
signal game_reset()

## 信号：观战席更新
signal bench_changed()


## 游戏阶段枚举
enum Phase {
	SHOP,    ## 商店阶段
	BATTLE,  ## 战斗阶段
	RESULT   ## 结果展示
}

## 当前游戏阶段
var current_phase: Phase = Phase.SHOP

## 棋盘状态 (cell_key -> CharacterInstance)
## cell_key 格式: "q_r"
var _board: Dictionary = {}

## 敌方棋盘状态 (战斗时使用)
var _enemy_board: Dictionary = {}

## 观战席状态 (slot_index -> CharacterInstance)
var _bench: Dictionary = {}

## 观战席最大容量
const BENCH_MAX_SIZE: int = 9

## 商店卡牌（使用普通数组支持null值）
var _shop_cards: Array = []

## 已刷新次数
var _refresh_count: int = 0

## 战斗结果
var _battle_result: Dictionary = {}

## 总回合数
var _total_rounds: int = 0


#region 公共接口

## 获取当前阶段名称
func get_phase_name() -> String:
	match current_phase:
		Phase.SHOP: return "shop"
		Phase.BATTLE: return "battle"
		Phase.RESULT: return "result"
		_: return "unknown"


## 设置游戏阶段
func set_phase(new_phase: Phase) -> void:
	if current_phase == new_phase:
		return
	var old_phase := current_phase
	current_phase = new_phase
	phase_changed.emit(_get_phase_name_for(old_phase), _get_phase_name_for(new_phase))


## 获取指定阶段的名称（内部使用）
func _get_phase_name_for(phase: Phase) -> String:
	match phase:
		Phase.SHOP: return "shop"
		Phase.BATTLE: return "battle"
		Phase.RESULT: return "result"
		_: return "unknown"


## 获取棋盘上的所有角色
func get_board_characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for instance in _board.values():
		result.append(instance)
	return result


## 获取棋盘上的角色数量
func get_board_count() -> int:
	return _board.size()


## 获取指定位置的角色
func get_character_at(q: int, r: int) -> CharacterInstance:
	var key := _make_cell_key(q, r)
	return _board.get(key)


## 检查位置是否有角色
func has_character_at(q: int, r: int) -> bool:
	return _board.has(_make_cell_key(q, r))


## 放置角色到棋盘
func place_character(data: CharacterData, q: int, r: int) -> CharacterInstance:
	var key := _make_cell_key(q, r)

	# 如果位置已有角色，先移除
	if _board.has(key):
		remove_character(q, r)

	# 创建新实例
	var instance := CharacterInstance.from_data(data, Vector2i(q, r))
	_board[key] = instance

	character_placed.emit(instance, q, r)
	board_changed.emit()
	return instance


## 移除角色
func remove_character(q: int, r: int) -> CharacterInstance:
	var key := _make_cell_key(q, r)
	if not _board.has(key):
		return null

	var instance: CharacterInstance = _board[key]
	_board.erase(key)

	character_removed.emit(instance, q, r)
	board_changed.emit()
	return instance


## 移动角色
func move_character(from_q: int, from_r: int, to_q: int, to_r: int) -> bool:
	var instance := get_character_at(from_q, from_r)
	if instance == null:
		return false

	# 移除原位置
	_board.erase(_make_cell_key(from_q, from_r))

	# 检查目标位置
	if _board.has(_make_cell_key(to_q, to_r)):
		# 目标位置已有角色，放回原位置
		_board[_make_cell_key(from_q, from_r)] = instance
		return false

	# 放置到新位置
	instance.position = Vector2i(to_q, to_r)
	_board[_make_cell_key(to_q, to_r)] = instance

	board_changed.emit()
	return true


## 交换两个位置的角色
func swap_characters(pos_a_q: int, pos_a_r: int, pos_b_q: int, pos_b_r: int) -> bool:
	var key_a := _make_cell_key(pos_a_q, pos_a_r)
	var key_b := _make_cell_key(pos_b_q, pos_b_r)

	var instance_a: CharacterInstance = _board.get(key_a)
	var instance_b: CharacterInstance = _board.get(key_b)

	if instance_a == null or instance_b == null:
		return false

	# 交换位置
	instance_a.position = Vector2i(pos_b_q, pos_b_r)
	instance_b.position = Vector2i(pos_a_q, pos_a_r)

	# 更新字典
	_board[key_a] = instance_b
	_board[key_b] = instance_a

	board_changed.emit()
	return true


## 清空棋盘
func clear_board() -> void:
	_board.clear()
	board_cleared.emit()
	board_changed.emit()


## 获取敌方棋盘上的所有角色
func get_enemy_characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for instance in _enemy_board.values():
		result.append(instance)
	return result


## 设置敌方棋盘（战斗时使用）
func set_enemy_board(enemies: Array[CharacterInstance]) -> void:
	_enemy_board.clear()
	for instance in enemies:
		var key := _make_cell_key(instance.position.x, instance.position.y)
		_enemy_board[key] = instance
	enemy_board_changed.emit()


## 获取敌方指定位置的角色
func get_enemy_at(q: int, r: int) -> CharacterInstance:
	var key := _make_cell_key(q, r)
	return _enemy_board.get(key)


## 清空敌方棋盘
func clear_enemy_board() -> void:
	_enemy_board.clear()
	enemy_board_changed.emit()


#region 观战席管理

## 获取观战席上的所有角色
func get_bench_characters() -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for i in range(BENCH_MAX_SIZE):
		if _bench.has(i):
			result.append(_bench[i])
	return result


## 获取观战席上的角色数量
func get_bench_count() -> int:
	return _bench.size()


## 获取观战席指定位置的角色
func get_bench_character_at(slot: int) -> CharacterInstance:
	return _bench.get(slot)


## 检查观战席位置是否有角色
func has_bench_character_at(slot: int) -> bool:
	return _bench.has(slot)


## 检查观战席是否已满
func is_bench_full() -> bool:
	return _bench.size() >= BENCH_MAX_SIZE


## 获取观战席第一个空位
func get_first_empty_bench_slot() -> int:
	for i in range(BENCH_MAX_SIZE):
		if not _bench.has(i):
			return i
	return -1


## 放置角色到观战席
func place_character_on_bench(data: CharacterData, slot: int = -1) -> CharacterInstance:
	if _bench.size() >= BENCH_MAX_SIZE:
		return null

	# 如果未指定位置，找第一个空位
	if slot < 0:
		slot = get_first_empty_bench_slot()
		if slot < 0:
			return null

	# 检查位置是否有效
	if slot < 0 or slot >= BENCH_MAX_SIZE:
		return null

	# 如果位置已有角色，先移除
	if _bench.has(slot):
		remove_bench_character(slot)

	# 创建新实例
	var instance := CharacterInstance.from_data(data, Vector2i(slot, -1))  # 使用负Y表示观战席
	_bench[slot] = instance

	bench_changed.emit()
	return instance


## 移除观战席上的角色
func remove_bench_character(slot: int) -> CharacterInstance:
	if not _bench.has(slot):
		return null

	var instance: CharacterInstance = _bench[slot]
	_bench.erase(slot)

	bench_changed.emit()
	return instance


## 从观战席移动到棋盘
func move_bench_to_board(bench_slot: int, board_q: int, board_r: int) -> bool:
	var instance := get_bench_character_at(bench_slot)
	if instance == null:
		return false

	# 检查棋盘位置是否为空
	if has_character_at(board_q, board_r):
		return false

	# 从观战席移除
	_bench.erase(bench_slot)

	# 放置到棋盘
	instance.position = Vector2i(board_q, board_r)
	_board[_make_cell_key(board_q, board_r)] = instance

	bench_changed.emit()
	character_placed.emit(instance, board_q, board_r)
	board_changed.emit()
	return true


## 从棋盘移动到观战席
func move_board_to_bench(board_q: int, board_r: int, bench_slot: int = -1) -> bool:
	var instance := get_character_at(board_q, board_r)
	if instance == null:
		return false

	# 如果观战席已满
	if is_bench_full():
		return false

	# 如果未指定位置，找第一个空位
	if bench_slot < 0:
		bench_slot = get_first_empty_bench_slot()
		if bench_slot < 0:
			return false

	# 从棋盘移除
	_board.erase(_make_cell_key(board_q, board_r))

	# 放置到观战席
	instance.position = Vector2i(bench_slot, -1)
	_bench[bench_slot] = instance

	bench_changed.emit()
	character_removed.emit(instance, board_q, board_r)
	board_changed.emit()
	return true


## 清空观战席
func clear_bench() -> void:
	_bench.clear()
	bench_changed.emit()


#endregion


## 获取商店卡牌
func get_shop_cards() -> Array:
	return _shop_cards


## 设置商店卡牌
func set_shop_cards(cards: Array) -> void:
	_shop_cards = cards
	shop_refreshed.emit(cards)


## 获取刷新次数
func get_refresh_count() -> int:
	return _refresh_count


## 增加刷新次数
func increment_refresh_count() -> void:
	_refresh_count += 1


## 重置刷新次数
func reset_refresh_count() -> void:
	_refresh_count = 0


## 设置战斗结果
func set_battle_result(result: Dictionary) -> void:
	_battle_result = result
	battle_completed.emit(result)


## 获取战斗结果
func get_battle_result() -> Dictionary:
	return _battle_result


## 增加回合数
func increment_round() -> void:
	_total_rounds += 1


## 获取总回合数
func get_total_rounds() -> int:
	return _total_rounds


## 重置游戏状态
func reset_game() -> void:
	current_phase = Phase.SHOP
	_board.clear()
	_enemy_board.clear()
	_bench.clear()
	_shop_cards.clear()
	_refresh_count = 0
	_battle_result.clear()
	_total_rounds = 0
	game_reset.emit()
	phase_changed.emit("", "shop")


#endregion


#region 内部方法

func _make_cell_key(q: int, r: int) -> String:
	return "%d_%d" % [q, r]


#endregion


#region 信号处理

func _ready() -> void:
	# 初始化状态
	current_phase = Phase.SHOP


#endregion
