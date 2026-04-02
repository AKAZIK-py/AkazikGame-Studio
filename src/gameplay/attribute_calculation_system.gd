# AttributeCalculationSystem.gd
# 属性计算系统
# 计算角色的最终战斗属性：基础属性 + 羁绊加成 + 位置加成
class_name AttributeCalculationSystem
extends Node

# PRODUCTION CODE - V-Tacit Attribute Calculation System
# Implements: design/gdd/attribute-calculation.md

## 信号：属性更新
signal attributes_updated(character: CharacterInstance)

## 信号：所有属性更新完成
signal all_attributes_updated()


## 羁绊效果系统引用
@export var synergy_effect_system: SynergyEffectSystem

## 棋盘系统引用
@export var board_system: BoardSystem


## 属性类型枚举
enum AttributeType {
	ATTACK,
	HEALTH,
	ATTACK_SPEED,
	SKILL_DAMAGE,
	CRITICAL_CHANCE,
	CRITICAL_DAMAGE
}

## 位置加成配置
## 前排定义：我方区域的前两行（行4-5）
## 后排定义：我方区域的后两行（行6-7）
const FRONT_ROWS: Array[int] = [4, 5]  # 前排行号
const BACK_ROWS: Array[int] = [6, 7]   # 后排行号

## 各定位的位置加成系数
const POSITION_BONUSES: Dictionary = {
	# 坦克在前排：生命+15%，胜率加成
	"tank": {
		"front": {"health_mult": 1.15, "win_rate_bonus": 0.05},
		"back": {"health_mult": 1.0, "win_rate_bonus": -0.05},
		"wrong_position_penalty": -0.05
	},
	# 输出在后排：攻击+10%
	"output": {
		"front": {"attack_mult": 1.0, "win_rate_bonus": -0.03},
		"back": {"attack_mult": 1.10, "win_rate_bonus": 0.03},
		"wrong_position_penalty": -0.03
	},
	# 核心在后排：攻击+15%
	"core": {
		"front": {"attack_mult": 1.0, "win_rate_bonus": -0.05},
		"back": {"attack_mult": 1.15, "win_rate_bonus": 0.05},
		"wrong_position_penalty": -0.05
	},
	# 辅助在后排：效果+20%
	"support": {
		"front": {"effect_mult": 1.0, "win_rate_bonus": -0.03},
		"back": {"effect_mult": 1.20, "win_rate_bonus": 0.03},
		"wrong_position_penalty": -0.03
	},
	# 法师在后排：技能伤害+10%
	"mage": {
		"front": {"skill_damage_mult": 1.0, "win_rate_bonus": -0.02},
		"back": {"skill_damage_mult": 1.10, "win_rate_bonus": 0.02},
		"wrong_position_penalty": -0.02
	},
	# 战士：无位置限制
	"warrior": {
		"front": {"attack_mult": 1.0, "win_rate_bonus": 0.0},
		"back": {"attack_mult": 1.0, "win_rate_bonus": 0.0},
		"wrong_position_penalty": 0.0
	}
}

## 不受位置限制的特殊羁绊
const POSITION_IMMUNE_SYNERGIES: Array[String] = [
	"deer",      # 狍子
	"big_corp",   # 大厂
	"solo"        # 单挂
]


#region 公共接口

## 计算角色的最终属性
func calculate_final_attributes(character: CharacterInstance) -> Dictionary:
	if character == null:
		return {}

	var char_data := character.get_character_data()
	if char_data == null:
		return {}

	# 基础属性
	var base_attack := char_data.base_attack
	var base_health := char_data.base_health

	# 应用羁绊效果
	if synergy_effect_system:
		synergy_effect_system.apply_synergy_effects(character)

	return {
		"attack": character.current_attack,
		"health": character.current_health,
		"max_health": character.max_health,
		"base_attack": base_attack,
		"base_health": base_health
	}


## 获取攻击力（基础 + 羁绊加成）
func get_final_attack(character: CharacterInstance) -> int:
	if character == null:
		return 0
	return character.current_attack


## 获取生命值（基础 + 羁绊加成）
func get_final_health(character: CharacterInstance) -> int:
	if character == null:
		return 0
	return character.max_health


## 计算所有角色的属性
func calculate_all_attributes() -> void:
	if board_system == null or synergy_effect_system == null:
		return

	# 先重置所有属性为基础值
	var characters := board_system.get_all_characters()
	for instance in characters:
		var char_data := instance.get_character_data()
		if char_data:
			instance.current_attack = char_data.base_attack
			instance.max_health = char_data.base_health
			instance.current_health = char_data.base_health

	# 应用羁绊效果
	synergy_effect_system.apply_all_effects()

	# 应用星级乘区
	for instance in characters:
		_apply_star_multiplier(instance)

	# 应用位置加成
	for instance in characters:
		apply_position_bonus(instance)

	# 发射更新信号
	for instance in characters:
		attributes_updated.emit(instance)

	all_attributes_updated.emit()


## 获取角色的属性摘要（用于UI显示）
func get_character_attribute_summary(character: CharacterInstance) -> Dictionary:
	if character == null:
		return {}

	var char_data := character.get_character_data()
	if char_data == null:
		return {}

	return {
		"character_id": character.character_id,
		"display_name": char_data.display_name,
		"rarity": char_data.rarity,
		"role": char_data.get_role_name(),
		"base_attack": char_data.base_attack,
		"base_health": char_data.base_health,
		"final_attack": character.current_attack,
		"final_health": character.max_health,
		"current_health": character.current_health,
		"synergy_tags": char_data.synergy_tags,
		"skill_name": char_data.skill_name
	}


## 计算角色战斗力（用于评估）
func calculate_combat_power(character: CharacterInstance) -> int:
	if character == null:
		return 0

	# 简单战斗力公式：攻击力 * 生命值 / 100
	var attack := character.current_attack
	var health := character.max_health

	return (attack * health) / 100


## 计算队伍总战斗力
func calculate_team_combat_power() -> int:
	if board_system == null:
		return 0

	var total_power := 0
	var characters := board_system.get_all_characters()

	for instance in characters:
		total_power += calculate_combat_power(instance)

	return total_power


## 计算角色的位置加成
func calculate_position_bonus(character: CharacterInstance) -> Dictionary:
	if character == null:
		return {}

	var char_data := character.get_character_data()
	if char_data == null:
		return {}

	var role := char_data.role
	var pos := character.position
	var row := pos.y

	# 检查是否有位置免疫羁绊
	for tag in char_data.synergy_tags:
		if tag.to_lower() in POSITION_IMMUNE_SYNERGIES:
			return {
				"position_type": "immune",
				"attack_mult": 1.0,
				"health_mult": 1.0,
				"effect_mult": 1.0,
				"skill_damage_mult": 1.0,
				"win_rate_bonus": 0.0
			}

	# 获取定位配置
	var role_config: Dictionary = POSITION_BONUSES.get(role, {})
	if role_config.is_empty():
		return {
			"position_type": "none",
			"attack_mult": 1.0,
			"health_mult": 1.0,
			"effect_mult": 1.0,
			"skill_damage_mult": 1.0,
			"win_rate_bonus": 0.0
		}

	# 判断在前排还是后排
	var is_front := row in FRONT_ROWS
	var is_back := row in BACK_ROWS

	var position_type := "middle"
	if is_front:
		position_type = "front"
	elif is_back:
		position_type = "back"

	# 获取位置加成
	var bonus: Dictionary
	if is_front:
		bonus = role_config.get("front", {})
	elif is_back:
		bonus = role_config.get("back", {})
	else:
		bonus = {"attack_mult": 1.0, "health_mult": 1.0, "effect_mult": 1.0, "skill_damage_mult": 1.0, "win_rate_bonus": 0.0}

	return {
		"position_type": position_type,
		"attack_mult": bonus.get("attack_mult", 1.0),
		"health_mult": bonus.get("health_mult", 1.0),
		"effect_mult": bonus.get("effect_mult", 1.0),
		"skill_damage_mult": bonus.get("skill_damage_mult", 1.0),
		"win_rate_bonus": bonus.get("win_rate_bonus", 0.0)
	}


## 应用位置加成到角色属性
func apply_position_bonus(character: CharacterInstance) -> void:
	if character == null:
		return

	var bonus := calculate_position_bonus(character)

	# 应用攻击力加成
	if bonus.attack_mult > 1.0:
		character.current_attack = int(character.current_attack * bonus.attack_mult)

	# 应用生命值加成
	if bonus.health_mult > 1.0:
		character.max_health = int(character.max_health * bonus.health_mult)
		character.current_health = character.max_health


## 应用星级乘区
func _apply_star_multiplier(character: CharacterInstance) -> void:
	if character == null:
		return

	var star_mult := get_star_multiplier(character.star_level)

	# 应用星级乘数
	character.current_attack = int(character.current_attack * star_mult)
	character.max_health = int(character.max_health * star_mult)
	character.current_health = character.max_health


## 获取星级乘数
func get_star_multiplier(star_level: int) -> float:
	# 每星增加50%属性
	# 1星 = 1.0x, 2星 = 1.5x, 3星 = 2.0x, 4星 = 2.5x, 5星 = 3.0x, 6星 = 3.5x
	return 1.0 + (star_level - 1) * 0.5


## 计算队伍的位置胜率加成
func calculate_team_position_win_rate_bonus() -> float:
	if board_system == null:
		return 0.0

	var total_bonus := 0.0
	var characters := board_system.get_all_characters()

	for instance in characters:
		var bonus := calculate_position_bonus(instance)
		total_bonus += bonus.get("win_rate_bonus", 0.0)

	return total_bonus


## 获取角色位置评价（用于UI显示）
func get_position_evaluation(character: CharacterInstance) -> Dictionary:
	var bonus := calculate_position_bonus(character)
	var char_data := character.get_character_data()
	if char_data == null:
		return {}

	var role := char_data.role
	var pos := character.position

	var is_front := pos.y in FRONT_ROWS
	var is_back := pos.y in BACK_ROWS

	var optimal_position := "任意"
	if role == "tank":
		optimal_position = "前排"
	elif role in ["output", "core", "support", "mage"]:
		optimal_position = "后排"

	var current_position := "中排"
	if is_front:
		current_position = "前排"
	elif is_back:
		current_position = "后排"

	var is_optimal := false
	if role == "warrior":
		is_optimal = true
	elif bonus.position_type == "immune":
		is_optimal = true
	elif role == "tank" and is_front:
		is_optimal = true
	elif role in ["output", "core", "support", "mage"] and is_back:
		is_optimal = true

	return {
		"role": role,
		"current_position": current_position,
		"optimal_position": optimal_position,
		"is_optimal": is_optimal,
		"attack_mult": bonus.attack_mult,
		"health_mult": bonus.health_mult,
		"win_rate_bonus": bonus.win_rate_bonus
	}


## 获取队伍属性统计
func get_team_stats() -> Dictionary:
	if board_system == null:
		return {}

	var stats := {
		"total_attack": 0,
		"total_health": 0,
		"character_count": 0,
		"average_attack": 0,
		"average_health": 0
	}

	var characters := board_system.get_all_characters()
	stats.character_count = characters.size()

	for instance in characters:
		stats.total_attack += instance.current_attack
		stats.total_health += instance.max_health

	if stats.character_count > 0:
		stats.average_attack = stats.total_attack / stats.character_count
		stats.average_health = stats.total_health / stats.character_count

	return stats


#endregion
