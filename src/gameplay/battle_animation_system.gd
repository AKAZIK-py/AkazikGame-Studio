# BattleAnimationSystem.gd
# 战斗动画系统
# 管理战斗中的移动、攻击、技能动画
class_name BattleAnimationSystem
extends Node

# PRODUCTION CODE - V-Tacit Auto-Battle Animation
# Implements: design/gdd/auto-battle-system.md

## 信号：动画完成
signal animation_completed(animation_type: String)

## 角色渲染器引用
@export var character_renderer: CharacterRenderer

## 棋盘系统引用
@export var board_system: BoardSystem

## 移动动画时长（秒）
@export var move_duration: float = 0.3

## 攻击动画时长（秒）
@export var attack_duration: float = 0.2

## 技能动画时长（秒）
@export var skill_duration: float = 0.4

## 闪烁次数（攻击动画）
@export var flash_count: int = 2

## 正在播放的动画数
var _active_animations: int = 0

## 动画队列
var _animation_queue: Array[Callable] = []

## 动画位置映射（CharacterInstance -> 当前屏幕位置）
var _character_positions: Dictionary = {}


#region 公共接口

## 播放移动动画
func play_move_animation(instance: CharacterInstance, from_pos: Vector2i, to_pos: Vector2i) -> void:
	if board_system == null:
		animation_completed.emit("move")
		return

	# 获取屏幕坐标
	var from_pixel: Vector2 = board_system.hex_to_pixel(from_pos.x, from_pos.y)
	var to_pixel: Vector2 = board_system.hex_to_pixel(to_pos.x, to_pos.y)

	# 创建动画
	_active_animations += 1

	var tween: Tween = create_tween()
	tween.tween_method(
		_update_character_position.bind(instance),
		from_pixel,
		to_pixel,
		move_duration
	)
	tween.tween_callback(_on_move_animation_complete.bind(instance, to_pixel))

	# 等待动画完成
	await animation_completed


## 播放攻击动画
func play_attack_animation(attacker: CharacterInstance, target: CharacterInstance) -> void:
	_active_animations += 1

	# 攻击者向目标方向冲刺
	var attacker_pos: Vector2 = _get_character_screen_position(attacker)
	var target_pos: Vector2 = _get_character_screen_position(target)

	var invalid := Vector2(-999999, -999999)
	if attacker_pos == invalid or target_pos == invalid:
		animation_completed.emit("attack")
		return

	# 计算冲刺方向
	var direction: Vector2 = (target_pos - attacker_pos).normalized()
	var dash_distance: float = 20.0  # 冲刺距离

	# 冲刺动画
	var tween: Tween = create_tween()
	tween.set_parallel(true)

	# 攻击者冲刺
	tween.tween_method(
		_update_character_position.bind(attacker),
		attacker_pos,
		attacker_pos + direction * dash_distance,
		attack_duration * 0.3
	)

	# 目标闪烁
	tween.tween_callback(_flash_character.bind(target)).set_delay(attack_duration * 0.2)

	# 攻击者返回
	tween.chain().tween_method(
		_update_character_position.bind(attacker),
		attacker_pos + direction * dash_distance,
		attacker_pos,
		attack_duration * 0.3
	)

	tween.tween_callback(_on_attack_animation_complete)

	await animation_completed


## 播放技能动画
func play_skill_animation(caster: CharacterInstance, target: CharacterInstance, skill_id: String) -> void:
	_active_animations += 1

	# MVP+简化：技能动画与攻击动画类似，但更长
	await play_attack_animation(caster, target)

	# 额外的技能效果（可扩展）
	# TODO: 根据skill_id播放不同特效

	animation_completed.emit("skill")


## 播放待机动画
func play_idle_animation(instance: CharacterInstance) -> void:
	# 简单的上下浮动效果
	var base_pos: Vector2 = _get_character_screen_position(instance)

	var invalid := Vector2(-999999, -999999)
	if base_pos == invalid:
		animation_completed.emit("idle")
		return

	_active_animations += 1

	var tween: Tween = create_tween()
	tween.tween_method(
		_update_character_position.bind(instance),
		base_pos,
		base_pos + Vector2(0, -5),
		0.2
	)
	tween.tween_method(
		_update_character_position.bind(instance),
		base_pos + Vector2(0, -5),
		base_pos,
		0.2
	)
	tween.tween_callback(_on_idle_animation_complete)

	await animation_completed


## 播放阵亡动画
func play_death_animation(instance: CharacterInstance) -> void:
	var base_pos: Vector2 = _get_character_screen_position(instance)

	var invalid := Vector2(-999999, -999999)
	if base_pos == invalid:
		animation_completed.emit("death")
		return

	_active_animations += 1

	var tween: Tween = create_tween()
	# 缩小并淡出
	tween.tween_method(
		_set_character_scale.bind(instance),
		1.0,
		0.0,
		0.5
	)
	tween.tween_callback(_on_death_animation_complete.bind(instance))

	await animation_completed


## 设置战斗速度
func set_animation_speed(speed: float) -> void:
	# 调整动画时长
	move_duration = 0.3 / speed
	attack_duration = 0.2 / speed
	skill_duration = 0.4 / speed


#endregion


#region 内部方法

## 获取角色屏幕位置
## 返回 Vector2，如果无效返回 Vector2(-999999, -999999)
func _get_character_screen_position(instance: CharacterInstance) -> Vector2:
	if _character_positions.has(instance.character_id):
		return _character_positions[instance.character_id]

	if board_system:
		return board_system.hex_to_pixel(instance.position.x, instance.position.y)

	return Vector2(-999999, -999999)  # 无效位置标记


## 更新角色位置（用于动画）
func _update_character_position(position: Vector2, instance: CharacterInstance) -> void:
	_character_positions[instance.character_id] = position

	# 通知渲染器更新
	if character_renderer:
		character_renderer.request_redraw()


## 设置角色缩放
func _set_character_scale(scale: float, instance: CharacterInstance) -> void:
	# TODO: 在CharacterRenderer中实现缩放
	pass


## 闪烁角色
func _flash_character(instance: CharacterInstance) -> void:
	# 通过多次设置可见性实现闪烁
	# TODO: 在CharacterRenderer中实现闪烁效果
	pass


#region 动画完成回调

func _on_move_animation_complete(instance: CharacterInstance, final_pos: Vector2) -> void:
	_character_positions[instance.character_id] = final_pos
	_active_animations -= 1
	animation_completed.emit("move")


func _on_attack_animation_complete() -> void:
	_active_animations -= 1
	animation_completed.emit("attack")


func _on_idle_animation_complete() -> void:
	_active_animations -= 1
	animation_completed.emit("idle")


func _on_death_animation_complete(instance: CharacterInstance) -> void:
	_character_positions.erase(instance.character_id)
	_active_animations -= 1
	animation_completed.emit("death")


#endregion

#endregion
