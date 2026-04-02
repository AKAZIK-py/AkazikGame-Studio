# BattleTimelineSystem.gd
# 战斗时间线系统
# 管理回合制战斗的行动顺序和时间控制
class_name BattleTimelineSystem
extends Node

# PRODUCTION CODE - V-Tacit Auto-Battle Timeline
# Implements: design/gdd/auto-battle-system.md

## 信号：回合开始
signal turn_started(turn_number: int)

## 信号：回合结束
signal turn_ended(turn_number: int)

## 信号：行动开始（某个棋子开始行动）
signal action_started(instance: CharacterInstance, action_type: String)

## 信号：行动结束
signal action_ended(instance: CharacterInstance, action_type: String)

## 信号：战斗结束
signal battle_ended(winner: String)  # "player" or "enemy"

## 信号：棋子阵亡
signal character_died(instance: CharacterInstance, killer: CharacterInstance)

## 棋盘系统引用
@export var board_system: BoardSystem

## 战斗系统引用
@export var battle_system: BattleSystem

## 战斗动画系统引用
@export var animation_system: BattleAnimationSystem

## 战斗AI系统引用
@export var ai_system: BattleAISystem

## 最大回合数
@export var max_turns: int = 50

## 行动动画时长（秒）
@export var action_duration: float = 0.5

## 战斗速度倍率
var battle_speed: float = 1.0:
	set(value):
		battle_speed = clampf(value, 0.5, 4.0)

## 当前回合数
var current_turn: int = 0

## 当前行动索引
var _current_action_index: int = 0

## 行动顺序列表（CharacterInstance数组）
var _action_queue: Array[CharacterInstance] = []

## 战斗是否进行中
var _battle_in_progress: bool = false

## 战斗是否暂停
var _battle_paused: bool = false

## 玩家队伍
var _player_team: Array[CharacterInstance] = []

## 敌方队伍
var _enemy_team: Array[CharacterInstance] = []

## 战斗日志
var _battle_log: Array[Dictionary] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # 即使游戏暂停也能运行


#region 公共接口

## 开始战斗
func start_battle(player_team: Array[CharacterInstance], enemy_team: Array[CharacterInstance]) -> void:
	if _battle_in_progress:
		push_warning("BattleTimelineSystem: Battle already in progress")
		return

	_player_team = player_team.duplicate()
	_enemy_team = enemy_team.duplicate()
	_battle_in_progress = true
	_battle_paused = false
	current_turn = 0
	_battle_log.clear()

	# 计算初始行动顺序
	_build_action_queue()

	# 开始第一回合
	_start_next_turn()


## 暂停战斗
func pause_battle() -> void:
	_battle_paused = true


## 继续战斗
func resume_battle() -> void:
	_battle_paused = false


## 设置战斗速度
func set_speed(speed: float) -> void:
	battle_speed = speed


## 跳过战斗（直接显示结果）
func skip_battle() -> void:
	if not _battle_in_progress:
		return

	# 立即结束战斗，计算结果
	_end_battle(_calculate_winner())


## 获取战斗日志
func get_battle_log() -> Array[Dictionary]:
	return _battle_log


## 战斗是否进行中
func is_battle_in_progress() -> bool:
	return _battle_in_progress


#endregion


#region 回合管理

## 构建行动队列（按速度排序）
func _build_action_queue() -> void:
	_action_queue.clear()

	# 收集所有存活的棋子
	var all_characters: Array[CharacterInstance] = []

	for instance in _player_team:
		if instance.current_health > 0:
			all_characters.append(instance)

	for instance in _enemy_team:
		if instance.current_health > 0:
			all_characters.append(instance)

	# 按速度排序（降序）
	all_characters.sort_custom(_compare_speed)

	_action_queue = all_characters
	_log_event("turn_order", {"characters": all_characters.map(func(c): return c.character_id)})


## 速度比较函数
func _compare_speed(a: CharacterInstance, b: CharacterInstance) -> bool:
	var speed_a: float = _calculate_speed(a)
	var speed_b: float = _calculate_speed(b)

	if speed_a != speed_b:
		return speed_a > speed_b

	# 速度相同时，按角色ID排序（确定性）
	return a.character_id < b.character_id


## 计算棋子速度
func _calculate_speed(_instance: CharacterInstance) -> float:
	var base_speed: float = 10.0

	# TODO: 加上羁绊速度加成
	# 每激活一个羁绊 +2 速度

	return base_speed


## 开始下一回合
func _start_next_turn() -> void:
	current_turn += 1
	_current_action_index = 0

	_log_event("turn_start", {"turn": current_turn})
	turn_started.emit(current_turn)

	# 重新构建行动队列（可能有棋子阵亡）
	_build_action_queue()

	# 检查是否所有棋子都阵亡
	if _action_queue.is_empty():
		_end_battle("draw")
		return

	# 开始执行行动
	_execute_next_action()


## 执行下一个行动
func _execute_next_action() -> void:
	if _battle_paused:
		# 等待恢复
		await resume_battle

	if not _battle_in_progress:
		return

	# 检查回合是否结束
	if _current_action_index >= _action_queue.size():
		_end_current_turn()
		return

	var instance: CharacterInstance = _action_queue[_current_action_index]

	# 检查棋子是否存活
	if instance.current_health <= 0:
		_current_action_index += 1
		_execute_next_action()
		return

	# 让AI系统决定行动
	if ai_system:
		var action: Dictionary = ai_system.decide_action(instance, _get_enemies_of(instance))
		await _perform_action(instance, action)
	else:
		# 无AI系统，简单攻击
		await _perform_simple_attack(instance)

	# 检查胜负
	var winner: String = _check_victory()
	if winner != "":
		_end_battle(winner)
		return

	# 下一个行动
	_current_action_index += 1

	# 延迟后执行下一个行动
	var delay: float = action_duration / battle_speed
	await get_tree().create_timer(delay).timeout

	_execute_next_action()


## 执行行动
func _perform_action(instance: CharacterInstance, action: Dictionary) -> void:
	var action_type: String = action.get("type", "wait")

	_log_event("action", {
		"character": instance.character_id,
		"type": action_type
	})

	action_started.emit(instance, action_type)

	match action_type:
		"move":
			await _execute_move(instance, action)
		"attack":
			await _execute_attack(instance, action)
		"skill":
			await _execute_skill(instance, action)
		"wait":
			await _execute_wait(instance)

	action_ended.emit(instance, action_type)


## 执行移动
func _execute_move(instance: CharacterInstance, action: Dictionary) -> void:
	var target_pos: Vector2i = action.get("target_position", Vector2i(-1, -1))

	if target_pos.x < 0 or target_pos.y < 0:
		return

	var from_pos: Vector2i = instance.position

	# 更新位置
	instance.position = target_pos

	# 播放动画
	if animation_system:
		await animation_system.play_move_animation(instance, from_pos, target_pos)

	_log_event("move", {
		"character": instance.character_id,
		"from": [from_pos.x, from_pos.y],
		"to": [target_pos.x, target_pos.y]
	})


## 执行攻击
func _execute_attack(instance: CharacterInstance, action: Dictionary) -> void:
	var target: CharacterInstance = action.get("target")

	if target == null:
		return

	# 计算伤害
	var damage: int = _calculate_damage(instance, target)

	# 应用伤害
	target.current_health = maxi(0, target.current_health - damage)

	# 播放动画
	if animation_system:
		await animation_system.play_attack_animation(instance, target)

	_log_event("attack", {
		"attacker": instance.character_id,
		"target": target.character_id,
		"damage": damage,
		"target_health": target.current_health
	})

	# 检查目标是否阵亡
	if target.current_health <= 0:
		_log_event("death", {
			"character": target.character_id,
			"killer": instance.character_id
		})
		character_died.emit(target, instance)


## 执行技能
func _execute_skill(instance: CharacterInstance, action: Dictionary) -> void:
	# MVP+简化：技能视为强化攻击
	var target: CharacterInstance = action.get("target")
	var skill_id: String = action.get("skill_id", "")

	if target == null:
		return

	# 计算技能伤害（简化：1.5倍攻击力）
	var damage: int = int(instance.current_attack * 1.5)

	# 应用伤害
	target.current_health = maxi(0, target.current_health - damage)

	# 播放动画
	if animation_system:
		await animation_system.play_skill_animation(instance, target, skill_id)

	_log_event("skill", {
		"caster": instance.character_id,
		"skill": skill_id,
		"target": target.character_id,
		"damage": damage,
		"target_health": target.current_health
	})

	# 检查目标是否阵亡
	if target.current_health <= 0:
		_log_event("death", {
			"character": target.character_id,
			"killer": instance.character_id
		})
		character_died.emit(target, instance)


## 执行等待
func _execute_wait(instance: CharacterInstance) -> void:
	_log_event("wait", {
		"character": instance.character_id
	})

	# 等待动画
	if animation_system:
		await animation_system.play_idle_animation(instance)


## 简单攻击（无AI时的回退）
func _perform_simple_attack(instance: CharacterInstance) -> void:
	var enemies: Array[CharacterInstance] = _get_enemies_of(instance)

	if enemies.is_empty():
		await _execute_wait(instance)
		return

	# 攻击最近的敌人
	var nearest: CharacterInstance = null
	var nearest_dist: float = INF

	for enemy in enemies:
		var dist: int = _hex_distance(instance.position, enemy.position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	if nearest != null:
		await _execute_attack(instance, {"target": nearest})
	else:
		await _execute_wait(instance)


## 结束当前回合
func _end_current_turn() -> void:
	_log_event("turn_end", {"turn": current_turn})
	turn_ended.emit(current_turn)

	# 检查是否超过最大回合
	if current_turn >= max_turns:
		_end_battle("draw")
		return

	# 开始下一回合
	_start_next_turn()


## 结束战斗
func _end_battle(winner: String) -> void:
	_battle_in_progress = false

	_log_event("battle_end", {
		"winner": winner,
		"turns": current_turn
	})

	battle_ended.emit(winner)


#endregion


#region 辅助方法

## 获取某棋子的敌方列表
func _get_enemies_of(instance: CharacterInstance) -> Array[CharacterInstance]:
	# 检查是否是玩家棋子
	var is_player: bool = _player_team.has(instance)

	var result: Array[CharacterInstance] = []
	if is_player:
		for enemy in _enemy_team:
			if enemy.current_health > 0:
				result.append(enemy)
	else:
		for ally in _player_team:
			if ally.current_health > 0:
				result.append(ally)

	return result


## 计算伤害
func _calculate_damage(attacker: CharacterInstance, _defender: CharacterInstance) -> int:
	# 简化伤害公式：攻击力（MVP+暂无防御）
	return attacker.current_attack


## 检查胜负
func _check_victory() -> String:
	var player_alive: bool = _player_team.any(func(c): return c.current_health > 0)
	var enemy_alive: bool = _enemy_team.any(func(c): return c.current_health > 0)

	if not player_alive and not enemy_alive:
		return "draw"
	elif not player_alive:
		return "enemy"
	elif not enemy_alive:
		return "player"
	else:
		return ""  # 战斗继续


## 计算胜者（用于跳过战斗）
func _calculate_winner() -> String:
	# 基于剩余生命值比例判定
	var player_hp: int = 0
	var enemy_hp: int = 0

	for c in _player_team:
		player_hp += c.current_health
	for c in _enemy_team:
		enemy_hp += c.current_health

	if player_hp > enemy_hp:
		return "player"
	elif enemy_hp > player_hp:
		return "enemy"
	else:
		return "draw"


## 六边形距离
func _hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = absi(a.x - b.x)
	var dr: int = absi(a.y - b.y)
	var ds: int = absi((-a.x - a.y) - (-b.x - b.y))
	return maxi(maxi(dq, dr), ds)


## 记录战斗日志
func _log_event(event_type: String, data: Dictionary) -> void:
	var event: Dictionary = {
		"turn": current_turn,
		"type": event_type,
		"data": data,
		"timestamp": Time.get_ticks_msec()
	}
	_battle_log.append(event)


#endregion
