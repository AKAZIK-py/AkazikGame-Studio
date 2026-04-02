# CharacterData.gd
# 角色数据资源类
# 存储角色的基础属性、羁绊标签、技能定义等静态数据
class_name CharacterData
extends Resource

# PRODUCTION CODE - V-Tacit Character Data System
# Implements: design/gdd/character-data.md

## 角色唯一标识（英文，用于代码引用）
@export var id: String = ""

## 显示名称（中文，用于UI展示）
@export var display_name: String = ""

## 稀有度/星级 (1-5)
@export_range(1, 5) var rarity: int = 1

## 战斗定位
@export_enum("output", "tank", "support", "core", "warrior", "mage") var role: String = "output"

## 基础攻击力
@export var base_attack: int = 50

## 基础生命值
@export var base_health: int = 600

## 羁绊标签列表
@export var synergy_tags: Array[String] = []

## 技能名称
@export var skill_name: String = ""

## 技能描述
@export_multiline var skill_description: String = ""

## 技能触发类型
@export_enum("none", "on_attack_count", "on_battle_start", "periodic", "on_damage_taken", "passive") var skill_trigger_type: String = "none"

## 技能触发参数（如攻击次数、周期秒数）
@export var skill_trigger_param: int = 0

## 技能效果ID（指向羁绊效果系统）
@export var skill_effect_id: String = ""

## 记忆点提示（MVP+）
@export var flavor_story_hint: String = ""

## 被击败台词（MVP+）
@export var flavor_defeat_line: String = ""


## 验证数据有效性
func validate() -> bool:
	if id.is_empty():
		push_error("CharacterData: id cannot be empty")
		return false
	if display_name.is_empty():
		push_error("CharacterData: display_name cannot be empty for %s" % id)
		return false
	if rarity < 1 or rarity > 5:
		push_error("CharacterData: rarity must be 1-5 for %s" % id)
		return false
	if base_attack <= 0:
		push_error("CharacterData: base_attack must be > 0 for %s" % id)
		return false
	if base_health <= 0:
		push_error("CharacterData: base_health must be > 0 for %s" % id)
		return false
	return true


## 获取技能触发信息
func get_skill_trigger() -> Dictionary:
	if skill_trigger_type == "none":
		return {}
	return {
		"type": skill_trigger_type,
		"param": skill_trigger_param
	}


## 检查是否有技能
func has_skill() -> bool:
	return skill_trigger_type != "none" and not skill_effect_id.is_empty()


## 获取技能完整信息
func get_skill_info() -> Dictionary:
	if not has_skill():
		return {}
	return {
		"name": skill_name,
		"description": skill_description,
		"trigger": get_skill_trigger(),
		"effect_id": skill_effect_id
	}


## 获取定位中文名称
func get_role_name() -> String:
	match role:
		"output": return "输出"
		"tank": return "坦克"
		"support": return "辅助"
		"core": return "核心"
		"warrior": return "战士"
		"mage": return "法师"
		_: return "未知"


## 获取星级显示文本
func get_rarity_stars() -> String:
	return "*".repeat(rarity)


## 获取稀有度对应的中文名称
func get_rarity_name() -> String:
	match rarity:
		1: return "1费"
		2: return "2费"
		3: return "3费"
		4: return "4费"
		5: return "5费"
		_: return "未知"
