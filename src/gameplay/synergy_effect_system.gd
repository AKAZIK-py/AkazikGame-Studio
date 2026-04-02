# SynergyEffectSystem.gd
# 羁绊效果系统
# 定义和应用羁绊的具体效果
class_name SynergyEffectSystem
extends Node

# PRODUCTION CODE - V-Tacit Synergy Effect System
# Implements: design/gdd/synergy-effect.md

## 信号：效果应用
signal effects_applied(character: CharacterInstance)

## 信号：EOE姐妹激活
signal eoe_sisters_activated(lu_zao: CharacterInstance, you_en: CharacterInstance)


## 羁绊检测系统引用
@export var detection_system: SynergyDetectionSystem

## 棋盘系统引用
@export var board_system: BoardSystem

## 羁绊效果配置 {synergy_id: {levels: [{...}]}}
var _effect_configs: Dictionary = {}

## 属性上限倍率（防止溢出）
const MAX_ATTRIBUTE_MULTIPLIER := 3.0


func _ready() -> void:
	_initialize_effect_configs()


#region 公共接口

## 应用羁绊效果到角色
func apply_synergy_effects(character: CharacterInstance) -> void:
	if detection_system == null:
		return

	var char_data := character.get_character_data()
	if char_data == null:
		return

	# 重置到基础属性
	character.current_attack = char_data.base_attack
	character.max_health = char_data.base_health

	# 收集所有适用的加成
	var attack_multiplier := 1.0
	var health_multiplier := 1.0
	var attack_speed_multiplier := 1.0
	var skill_damage_multiplier := 1.0

	# 遍历激活的羁绊
	for synergy_id in detection_system.get_active_synergies():
		var effect := _get_synergy_effect_for_character(synergy_id, character)
		if effect.is_empty():
			continue

		# 应用效果
		if effect.has("attack_bonus"):
			attack_multiplier *= (1.0 + effect.attack_bonus)
		if effect.has("health_bonus"):
			health_multiplier *= (1.0 + effect.health_bonus)
		if effect.has("attack_speed_bonus"):
			attack_speed_multiplier *= (1.0 + effect.attack_speed_bonus)
		if effect.has("skill_damage_bonus"):
			skill_damage_multiplier *= (1.0 + effect.skill_damage_bonus)

	# 应用EOE姐妹特殊效果（如果是露早或柚恩）
	if detection_system.is_eoe_sisters_active():
		if character.character_id == "lu_zao" or character.character_id == "you_en":
			attack_multiplier *= 1.8
			health_multiplier *= 1.5

	# 应用单挂效果（如果是hirro）
	if character.character_id == "hirro" and board_system != null:
		if board_system.is_isolated(character.position.x, character.position.y):
			attack_multiplier *= 1.4
			health_multiplier *= 1.3

	# 应用全局效果（PSP）
	if detection_system.is_synergy_active("psp"):
		var psp_level := detection_system.get_synergy_level("psp")
		if psp_level > 0 and not ("psp" in char_data.synergy_tags):
			# PSP对非PSP角色也生效（全局效果）
			attack_multiplier *= 1.12
			health_multiplier *= 1.12

	# 限制最大倍率
	attack_multiplier = minf(attack_multiplier, MAX_ATTRIBUTE_MULTIPLIER)
	health_multiplier = minf(health_multiplier, MAX_ATTRIBUTE_MULTIPLIER)

	# 计算最终属性
	character.current_attack = int(char_data.base_attack * attack_multiplier)
	character.max_health = int(char_data.base_health * health_multiplier)
	character.current_health = character.max_health

	effects_applied.emit(character)


## 应用所有角色的羁绊效果
func apply_all_effects() -> void:
	if board_system == null or detection_system == null:
		return

	# 先检测羁绊
	detection_system.detect_active_synergies()

	# 应用到所有角色
	var characters := board_system.get_all_characters()
	for instance in characters:
		apply_synergy_effects(instance)


## 获取羁绊效果参数
func get_synergy_effect(synergy_id: String, level: int) -> Dictionary:
	if not _effect_configs.has(synergy_id):
		return {}

	var levels: Array = _effect_configs[synergy_id].get("levels", [])
	if level < 1 or level > levels.size():
		return {}

	return levels[level - 1]


## 获取角色的羁绊加成摘要
func get_character_synergy_summary(character: CharacterInstance) -> Dictionary:
	var summary := {
		"attack_bonus": 0.0,
		"health_bonus": 0.0,
		"attack_speed_bonus": 0.0,
		"skill_damage_bonus": 0.0,
		"active_synergies": []
	}

	if detection_system == null:
		return summary

	var char_data := character.get_character_data()
	if char_data == null:
		return summary

	for synergy_id in detection_system.get_active_synergies():
		var effect := _get_synergy_effect_for_character(synergy_id, character)
		if not effect.is_empty():
			summary.attack_bonus += effect.get("attack_bonus", 0.0)
			summary.health_bonus += effect.get("health_bonus", 0.0)
			summary.attack_speed_bonus += effect.get("attack_speed_bonus", 0.0)
			summary.skill_damage_bonus += effect.get("skill_damage_bonus", 0.0)
			summary.active_synergies.append(synergy_id)

	return summary


#endregion


#region 内部方法

func _initialize_effect_configs() -> void:
	# VR羁绊：攻击力加成
	_effect_configs["VR"] = {
		"levels": [
			{"attack_bonus": 0.15},  # 1级：2人
			{"attack_bonus": 0.30}   # 2级：4人
		]
	}

	# 偶像羁绊：生命值加成
	_effect_configs["idol"] = {
		"levels": [
			{"health_bonus": 0.12},  # 1级：2人
			{"health_bonus": 0.25},  # 2级：4人
			{"health_bonus": 0.40}   # 3级：5人
		]
	}

	# 歌手羁绊：技能伤害加成
	_effect_configs["singer"] = {
		"levels": [
			{"skill_damage_bonus": 0.20},  # 1级：2人
			{"skill_damage_bonus": 0.40}   # 2级：4人
		]
	}

	# 糖羁绊：攻击速度加成
	_effect_configs["candy"] = {
		"levels": [
			{"attack_speed_bonus": 0.15},  # 1级：2人
			{"attack_speed_bonus": 0.30}   # 2级：3人
		]
	}

	# 枪手羁绊：额外射击（特殊效果）
	_effect_configs["gunslinger"] = {
		"levels": [
			{"extra_shot_chance": 0.35, "extra_shot_damage": 0.5}  # 1级：2人
		]
	}

	# PSP羁绊：全体增益
	_effect_configs["psp"] = {
		"levels": [
			{"attack_bonus": 0.12, "health_bonus": 0.12}  # 1级：2人，全队生效
		]
	}

	# EOE姐妹：组合羁绊，特殊处理
	_effect_configs["eoe_sisters"] = {
		"levels": [
			{"attack_multiplier": 1.8, "health_multiplier": 1.5, "targets": ["lu_zao", "you_en"]}
		]
	}

	# 狍子：万能羁绊，无独立效果
	_effect_configs["deer"] = {
		"levels": [
			{}  # 无效果
		]
	}

	# 东京：单体效果
	_effect_configs["tokyo"] = {
		"levels": [
			{"skill_damage_bonus": 0.25}  # 1级：1人
		]
	}


func _get_synergy_effect_for_character(synergy_id: String, character: CharacterInstance) -> Dictionary:
	var synergy := SynergyRegistry.get_synergy(synergy_id)
	if synergy == null:
		return {}

	var level := detection_system.get_synergy_level(synergy_id)
	if level <= 0:
		return {}

	var char_data := character.get_character_data()
	if char_data == null:
		return {}

	# 检查角色是否有该羁绊标签
	var has_tag := synergy_id in char_data.synergy_tags

	# 特殊处理：PSP是全局效果
	if synergy_id == "psp":
		# PSP效果在apply_synergy_effects中单独处理
		return {}

	# 如果角色没有该羁绊标签，返回空
	if not has_tag:
		return {}

	return get_synergy_effect(synergy_id, level)


#endregion
