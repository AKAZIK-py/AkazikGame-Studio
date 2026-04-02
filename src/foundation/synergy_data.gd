# SynergyData.gd
# 羁绊数据资源类
# 定义羁绊类型、触发阈值、效果参数等静态数据
class_name SynergyData
extends Resource

# PRODUCTION CODE - V-Tacit Synergy Data System
# Implements: design/gdd/synergy-data.md

## 羁绊唯一标识
@export var id: String = ""

## 显示名称
@export var display_name: String = ""

## 羁绊类型
@export_enum("normal", "wildcard", "combo", "hidden") var type: String = "normal"

## 触发阈值（角色数量）
@export var thresholds: Array[int] = []

## 效果ID列表（每个阈值对应一个效果ID）
@export var effect_ids: Array[String] = []

## 效果描述（用于UI显示）
@export_multiline var effect_descriptions: Array[String] = []

## 羁绊图标路径（预留）
@export var icon_path: String = ""


## 验证数据有效性
func validate() -> bool:
	if id.is_empty():
		push_error("SynergyData: id cannot be empty")
		return false
	if display_name.is_empty():
		push_error("SynergyData: display_name cannot be empty for %s" % id)
		return false
	if thresholds.is_empty():
		push_error("SynergyData: thresholds cannot be empty for %s" % id)
		return false
	# 检查阈值是否递增
	for i in range(1, thresholds.size()):
		if thresholds[i] <= thresholds[i - 1]:
			push_error("SynergyData: thresholds must be in ascending order for %s" % id)
			return false
	return true


## 获取最高激活层级
func get_max_level() -> int:
	return thresholds.size()


## 获取指定角色数量对应的激活层级
func get_level_for_count(count: int) -> int:
	var level := 0
	for threshold in thresholds:
		if count >= threshold:
			level += 1
		else:
			break
	return level


## 获取指定层级的效果ID
func get_effect_id_for_level(level: int) -> String:
	if level < 1 or level > effect_ids.size():
		return ""
	return effect_ids[level - 1]


## 获取指定层级的效果描述
func get_effect_description_for_level(level: int) -> String:
	if level < 1 or level > effect_descriptions.size():
		return ""
	return effect_descriptions[level - 1]


## 获取指定层级的阈值
func get_threshold_for_level(level: int) -> int:
	if level < 1 or level > thresholds.size():
		return -1
	return thresholds[level - 1]


## 获取下一个阈值（用于UI显示进度）
func get_next_threshold(current_count: int) -> int:
	for threshold in thresholds:
		if current_count < threshold:
			return threshold
	return thresholds[-1] if thresholds.size() > 0 else -1


## 检查是否为万能羁绊
func is_wildcard() -> bool:
	return type == "wildcard"


## 检查是否为组合羁绊
func is_combo() -> bool:
	return type == "combo"


## 检查是否为隐藏羁绊
func is_hidden() -> bool:
	return type == "hidden"


## 获取类型中文名称
func get_type_name() -> String:
	match type:
		"normal": return "普通羁绊"
		"wildcard": return "万能羁绊"
		"combo": return "组合羁绊"
		"hidden": return "隐藏羁绊"
		_: return "未知类型"


## 获取激活状态文本
func get_activation_text(current_count: int) -> String:
	var level := get_level_for_count(current_count)
	if level == 0:
		return "%s: %d/%d (未激活)" % [display_name, current_count, thresholds[0]]
	else:
		var next_threshold := get_next_threshold(current_count)
		if next_threshold <= current_count:
			return "%s: Lv.%d (已满级)" % [display_name, level]
		return "%s: Lv.%d → %d/%d" % [display_name, level, current_count, next_threshold]
