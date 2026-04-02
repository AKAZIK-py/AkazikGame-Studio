# CharacterInstance.gd
# 角色实例数据
# 表示棋盘上的一个角色实例，包含运行时状态
class_name CharacterInstance
extends RefCounted

# PRODUCTION CODE - V-Tacit Game State System
# Implements: design/gdd/game-state.md

## 角色数据ID
var character_id: String = ""

## 棋盘位置 (q, r)
var position: Vector2i = Vector2i(-1, -1)

## 星级 (1-6，通过合成升级)
var star_level: int = 1

## 当前生命值（战斗中）
var current_health: int = 0

## 最大生命值（计算后）
var max_health: int = 0

## 当前攻击力（计算后）
var current_attack: int = 0

## 攻击次数计数（用于技能触发）
var attack_count: int = 0

## 是否存活
var is_alive: bool = true

## 角色数据引用（运行时缓存）
var _character_data: CharacterData = null


## 从CharacterData创建实例
static func from_data(data: CharacterData, pos: Vector2i, star: int = 1) -> CharacterInstance:
	var instance := CharacterInstance.new()
	instance.character_id = data.id
	instance.position = pos
	instance.star_level = star
	instance._character_data = data
	# 初始化属性（后续由属性计算系统覆盖）
	instance.max_health = data.base_health
	instance.current_health = instance.max_health
	instance.current_attack = data.base_attack
	return instance


## 升星（增加星级）
func upgrade_star() -> void:
	star_level += 1
	# 属性会由属性计算系统重新计算


## 获取角色数据
func get_character_data() -> CharacterData:
	if _character_data == null and not character_id.is_empty():
		_character_data = CharacterRegistry.get_character(character_id)
	return _character_data


## 受到伤害
func take_damage(damage: int) -> int:
	var actual_damage := mini(damage, current_health)
	current_health -= actual_damage
	if current_health <= 0:
		current_health = 0
		is_alive = false
	return actual_damage


## 治疗
func heal(amount: int) -> int:
	var old_health := current_health
	current_health = mini(current_health + amount, max_health)
	return current_health - old_health


## 重置战斗状态
func reset_battle_state() -> void:
	current_health = max_health
	attack_count = 0
	is_alive = true


## 增加攻击计数
func increment_attack_count() -> int:
	attack_count += 1
	return attack_count


## 重置攻击计数
func reset_attack_count() -> void:
	attack_count = 0


## 序列化为字典（用于保存）
func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"position": {"q": position.x, "r": position.y},
		"star_level": star_level,
		"current_health": current_health,
		"max_health": max_health,
		"current_attack": current_attack,
		"attack_count": attack_count,
		"is_alive": is_alive
	}


## 从字典加载
static func from_dict(data: Dictionary) -> CharacterInstance:
	var instance := CharacterInstance.new()
	instance.character_id = data.get("character_id", "")
	instance.position = Vector2i(
		data.position.get("q", -1),
		data.position.get("r", -1)
	)
	instance.star_level = data.get("star_level", 1)
	instance.current_health = data.get("current_health", 0)
	instance.max_health = data.get("max_health", 0)
	instance.current_attack = data.get("current_attack", 0)
	instance.attack_count = data.get("attack_count", 0)
	instance.is_alive = data.get("is_alive", true)
	return instance
