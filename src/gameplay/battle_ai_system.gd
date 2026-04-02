# BattleAISystem.gd
# 战斗AI系统
# 为棋子提供自动决策：移动、攻击、技能使用
# 模仿云顶之弈的AI逻辑
class_name BattleAISystem
extends Node

# PRODUCTION CODE - V-Tacit Auto-Battle AI
# Implements: design/gdd/auto-battle-system.md

## 棋盘系统引用
@export var board_system: BoardSystem

## 定位配置（云顶之弈风格）
## 每个定位有不同的攻击距离和目标优先级
const ROLE_CONFIG: Dictionary = {
	"output": {
		"attack_range": 1,        # 近战输出
		"prefer_low_hp": true,    # 优先攻击低血量
		"move_aggressive": true   # 激进移动
	},
	"tank": {
		"attack_range": 1,        # 近战坦克
		"prefer_low_hp": false,   # 不优先低血量，吸引火力
		"move_aggressive": true   # 激进移动
	},
	"warrior": {
		"attack_range": 1,        # 近战战士
		"prefer_low_hp": true,    # 优先低血量
		"move_aggressive": true   # 激进移动
	},
	"core": {
		"attack_range": 2,        # 中程核心
		"prefer_low_hp": true,    # 优先低血量
		"move_aggressive": false  # 保持距离
	},
	"support": {
		"attack_range": 2,        # 远程辅助
		"prefer_low_hp": false,   # 攻击最近的
		"move_aggressive": false  # 保持距离
	},
	"mage": {
		"attack_range": 3,        # 远程法师
		"prefer_low_hp": true,    # 优先低血量
		"move_aggressive": false  # 保持距离
	}
}


#region 公共接口

## 决定棋子的行动
## 返回: {"type": "move"|"attack"|"skill"|"wait", ...其他参数}
func decide_action(instance: CharacterInstance, enemies: Array[CharacterInstance]) -> Dictionary:
	# 过滤存活敌人
	var valid_enemies := _get_valid_enemies(enemies)

	if valid_enemies.is_empty():
		# 没有敌人，默认往前走
		return _get_default_forward_move(instance)

	# 获取角色配置
	var config: Dictionary = _get_role_config(instance)
	var attack_range: int = config.get("attack_range", 1)

	# 1. 选择目标
	var target := _select_target(instance, valid_enemies, config)

	if target == null:
		# 找不到目标，默认往前走
		return _get_default_forward_move(instance)

	# 2. 检查是否可以攻击（目标在攻击范围内）
	if _is_in_attack_range(instance, target, attack_range):
		return {
			"type": "attack",
			"target": target
		}

	# 3. 需要移动向目标
	var move_pos := _find_move_position(instance, target, config)
	if move_pos.x >= 0 and move_pos.y >= 0:
		return {
			"type": "move",
			"target_position": move_pos
		}

	# 4. 无法移动，尝试攻击范围内最近的敌人
	var nearest_in_range := _find_nearest_enemy_in_range(instance, valid_enemies, attack_range)
	if nearest_in_range != null:
		return {
			"type": "attack",
			"target": nearest_in_range
		}

	# 5. 完全无法行动，默认往前走
	return _get_default_forward_move(instance)


## 获取角色的攻击范围
func get_attack_range(instance: CharacterInstance) -> int:
	var config: Dictionary = _get_role_config(instance)
	return config.get("attack_range", 1)


#endregion


#region 目标选择

## 选择攻击目标（云顶之弈风格）
func _select_target(instance: CharacterInstance, enemies: Array[CharacterInstance], config: Dictionary) -> CharacterInstance:
	var attack_range: int = config.get("attack_range", 1)
	var prefer_low_hp: bool = config.get("prefer_low_hp", true)

	# 1. 优先选择攻击范围内的目标
	var in_range_enemies := _get_enemies_in_range(instance, enemies, attack_range)

	if not in_range_enemies.is_empty():
		# 在范围内，根据策略选择
		if prefer_low_hp:
			return _get_lowest_hp_target(in_range_enemies)
		else:
			return _get_nearest_target(instance, in_range_enemies)

	# 2. 没有在范围内的敌人，选择最近的作为移动目标
	return _get_nearest_target(instance, enemies)


## 获取攻击范围内的敌人
func _get_enemies_in_range(instance: CharacterInstance, enemies: Array[CharacterInstance], attack_range: int) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []

	for enemy in enemies:
		if enemy.current_health <= 0:
			continue
		var dist := _hex_distance(instance.position, enemy.position)
		if dist <= attack_range:
			result.append(enemy)

	return result


## 获取最低血量目标
func _get_lowest_hp_target(enemies: Array[CharacterInstance]) -> CharacterInstance:
	var lowest: CharacterInstance = null
	var lowest_hp: int = 999999

	for enemy in enemies:
		if enemy.current_health < lowest_hp:
			lowest_hp = enemy.current_health
			lowest = enemy

	return lowest


## 获取最近目标
func _get_nearest_target(instance: CharacterInstance, enemies: Array[CharacterInstance]) -> CharacterInstance:
	var nearest: CharacterInstance = null
	var nearest_dist: int = 999999

	for enemy in enemies:
		var dist := _hex_distance(instance.position, enemy.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


## 找到攻击范围内最近的敌人
func _find_nearest_enemy_in_range(instance: CharacterInstance, enemies: Array[CharacterInstance], attack_range: int) -> CharacterInstance:
	var in_range := _get_enemies_in_range(instance, enemies, attack_range)
	if in_range.is_empty():
		return null
	return _get_nearest_target(instance, in_range)


#endregion


#region 移动逻辑

## 找到最佳移动位置
func _find_move_position(instance: CharacterInstance, target: CharacterInstance, config: Dictionary) -> Vector2i:
	if board_system == null:
		return Vector2i(-1, -1)

	var attack_range: int = config.get("attack_range", 1)
	var move_aggressive: bool = config.get("move_aggressive", true)

	# 获取相邻格子
	var neighbors := board_system.get_neighbors(instance.position.x, instance.position.y)
	if neighbors.is_empty():
		return Vector2i(-1, -1)

	# 策略：
	# - 激进（近战）：向目标移动，尽量靠近
	# - 保守（远程）：保持攻击距离，不要太近
	var best_pos: Vector2i = Vector2i(-1, -1)
	var best_score: int = -999999

	for pos in neighbors:
		# 检查格子是否可移动
		if not _can_move_to(pos, target):
			continue

		# 计算移动评分
		var score := _evaluate_move_position(pos, target, attack_range, move_aggressive)
		if score > best_score:
			best_score = score
			best_pos = pos

	return best_pos


## 检查是否可以移动到某位置
func _can_move_to(pos: Vector2i, target: CharacterInstance) -> bool:
	if board_system == null:
		return false

	# 不能移动到棋盘外
	if not board_system.is_valid_position(pos.x, pos.y):
		return false

	# 不能移动到敌人位置
	if target != null and pos == target.position:
		return false

	# 格子必须为空
	return board_system.is_cell_empty(pos.x, pos.y)


## 评估移动位置的评分
func _evaluate_move_position(pos: Vector2i, target: CharacterInstance, attack_range: int, aggressive: bool) -> int:
	var dist_to_target := _hex_distance(pos, target.position)
	var score: int = 0

	if aggressive:
		# 激进模式：越近越好，但要在攻击距离内停止
		if dist_to_target <= attack_range:
			# 在攻击范围内，很好
			score += 100
		else:
			# 不在范围内，距离越近越好
			score += 50 - dist_to_target
	else:
		# 保守模式：保持在攻击距离最佳
		if dist_to_target == attack_range:
			# 刚好在攻击距离，最佳
			score += 100
		elif dist_to_target < attack_range:
			# 太近了，稍微扣分
			score += 80 - (attack_range - dist_to_target) * 10
		else:
			# 太远了，需要靠近
			score += 50 - (dist_to_target - attack_range)

	return score


## 获取默认的前进移动（找不到敌人时）
func _get_default_forward_move(instance: CharacterInstance) -> Dictionary:
	if board_system == null:
		return {"type": "wait"}

	# 确定前进方向
	# 玩家棋子：向上移动（row减小）
	# 敌方棋子：向下移动（row增大）
	var forward_dir := _get_forward_direction(instance)

	# 尝试向前移动
	var neighbors := board_system.get_neighbors(instance.position.x, instance.position.y)

	for pos in neighbors:
		# 检查是否是前进方向
		if _is_forward_move(instance.position, pos, forward_dir):
			# 检查格子是否为空
			if board_system.is_cell_empty(pos.x, pos.y):
				return {
					"type": "move",
					"target_position": pos
				}

	# 如果不能前进，尝试横向移动
	for pos in neighbors:
		if board_system.is_cell_empty(pos.x, pos.y):
			return {
				"type": "move",
				"target_position": pos
			}

	return {"type": "wait"}


## 获取前进方向（1为向下，-1为向上）
func _get_forward_direction(instance: CharacterInstance) -> int:
	# 检查是否在玩家区域（row >= 4）
	# 玩家棋子向前进 = 向上（row减小）
	# 敌方棋子向前进 = 向下（row增大）
	if instance.position.y >= BoardSystem.PLAYER_ZONE_START:
		return -1  # 玩家区域，向上
	else:
		return 1   # 敌方区域，向下


## 检查移动是否是前进方向
func _is_forward_move(from: Vector2i, to: Vector2i, forward_dir: int) -> bool:
	var row_diff: int = to.y - from.y
	if forward_dir < 0:
		return row_diff < 0  # 向上移动
	else:
		return row_diff > 0  # 向下移动


#endregion


#region 辅助方法

## 获取角色配置
func _get_role_config(instance: CharacterInstance) -> Dictionary:
	var char_data := instance.get_character_data()
	if char_data == null:
		return ROLE_CONFIG["warrior"]  # 默认配置

	return ROLE_CONFIG.get(char_data.role, ROLE_CONFIG["warrior"])


## 过滤存活的敌人
func _get_valid_enemies(enemies: Array[CharacterInstance]) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	for enemy in enemies:
		if enemy.current_health > 0:
			result.append(enemy)
	return result


## 检查目标是否在攻击范围内
func _is_in_attack_range(instance: CharacterInstance, target: CharacterInstance, attack_range: int) -> bool:
	var dist := _hex_distance(instance.position, target.position)
	return dist <= attack_range


## 六边形距离
func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq := absi(a.x - b.x)
	var dr := absi(a.y - b.y)
	var ds := absi((-a.x - a.y) - (-b.x - b.y))
	return maxi(maxi(dq, dr), ds)


#endregion
