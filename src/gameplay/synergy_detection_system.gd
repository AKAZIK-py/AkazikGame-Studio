# SynergyDetectionSystem.gd
# 羁绊检测系统
# 检测棋盘上激活的羁绊组合
class_name SynergyDetectionSystem
extends Node

# PRODUCTION CODE - V-Tacit Synergy Detection System
# Implements: design/gdd/synergy-detection.md

## 信号：羁绊激活
signal synergy_activated(synergy_id: String, level: int)

## 信号：羁绊失效
signal synergy_deactivated(synergy_id: String)

## 信号：羁绊状态变化
signal synergies_changed(active_synergies: Dictionary)


## 棋盘系统引用
@export var board_system: BoardSystem

## 当前激活的羁绊 {synergy_id: {level: int, count: int, characters: Array}}
var _active_synergies: Dictionary = {}

## 各羁绊的角色数量统计 {synergy_id: int}
var _synergy_counts: Dictionary = {}

## 万能羁绊（狍子）分配 {deer_character_id: target_synergy_id}
var _wildcard_assignments: Dictionary = {}

## 狍子角色ID列表
var _deer_characters: Array[String] = []


#region 公共接口

## 检测所有激活的羁绊
func detect_active_synergies() -> Dictionary:
	# 清空统计
	_synergy_counts.clear()
	_active_synergies.clear()
	_wildcard_assignments.clear()
	_deer_characters.clear()

	if board_system == null:
		return {}

	# 收集棋盘上所有角色的羁绊标签
	var characters := board_system.get_all_characters()
	for instance in characters:
		_count_character_synergies(instance)

	# 处理万能羁绊（狍子）
	_resolve_wildcard_synergies()

	# 检测激活的羁绊
	_detect_activated_synergies()

	synergies_changed.emit(_active_synergies.duplicate())
	return _active_synergies.duplicate()


## 获取某羁绊当前角色数量
func get_synergy_count(synergy_id: String) -> int:
	return _synergy_counts.get(synergy_id, 0)


## 获取激活的羁绊
func get_active_synergies() -> Dictionary:
	return _active_synergies.duplicate()


## 检查羁绊是否激活
func is_synergy_active(synergy_id: String) -> bool:
	return _active_synergies.has(synergy_id)


## 获取羁绊激活等级
func get_synergy_level(synergy_id: String) -> int:
	if not _active_synergies.has(synergy_id):
		return 0
	return _active_synergies[synergy_id].get("level", 0)


## 获取某羁绊涉及的 character 实例列表
func get_synergy_characters(synergy_id: String) -> Array:
	if not _active_synergies.has(synergy_id):
		return []
	return _active_synergies[synergy_id].get("characters", [])


## 检查EOE姐妹组合是否激活
func is_eoe_sisters_active() -> bool:
	return _is_combo_synergy_active("eoe_sisters")


## 获取所有羁绊进度（用于UI显示）
func get_all_synergy_progress() -> Dictionary:
	var result := {}
	var all_synergies := SynergyRegistry.get_active_synergies()

	for synergy in all_synergies:
		var count := get_synergy_count(synergy.id)
		var level := synergy.get_level_for_count(count)
		var next_threshold := synergy.get_next_threshold(count)

		result[synergy.id] = {
			"display_name": synergy.display_name,
			"count": count,
			"level": level,
			"thresholds": synergy.thresholds,
			"next_threshold": next_threshold,
			"is_active": level > 0
		}

	return result


#endregion


#region 内部方法

func _count_character_synergies(instance: CharacterInstance) -> void:
	var char_data := instance.get_character_data()
	if char_data == null:
		return

	# 检查是否是狍子（万能羁绊）
	if "deer" in char_data.synergy_tags:
		_deer_characters.append(instance.character_id)
		return

	# 统计普通羁绊标签
	for tag in char_data.synergy_tags:
		# 跳过隐藏羁绊
		var synergy := SynergyRegistry.get_synergy(tag)
		if synergy == null or synergy.is_hidden():
			continue

		if not _synergy_counts.has(tag):
			_synergy_counts[tag] = 0
		_synergy_counts[tag] += 1


func _resolve_wildcard_synergies() -> void:
	# 处理狍子（万能羁绊）
	if _deer_characters.is_empty():
		return

	for deer_id in _deer_characters:
		var best_synergy := _find_best_synergy_for_wildcard()
		if best_synergy.is_empty():
			continue

		# 分配狍子到最佳羁绊
		_wildcard_assignments[deer_id] = best_synergy
		if not _synergy_counts.has(best_synergy):
			_synergy_counts[best_synergy] = 0
		_synergy_counts[best_synergy] += 1


func _find_best_synergy_for_wildcard() -> String:
	# 策略：优先选择能触发升级的羁绊，其次选择数量最多的羁绊
	var best_synergy := ""
	var best_can_upgrade := false
	var best_count := -1

	var all_synergies := SynergyRegistry.get_active_synergies()
	for synergy in all_synergies:
		if synergy.is_hidden() or synergy.is_wildcard():
			continue

		var count: int = _synergy_counts.get(synergy.id, 0)
		var can_upgrade := false

		# 检查+1后是否能达到新阈值
		for threshold in synergy.thresholds:
			if count + 1 == threshold:
				can_upgrade = true
				break
			if count < threshold:
				break

		# 选择逻辑：
		# 1. 能升级的优先
		# 2. 都能升级或都不能升级时，选数量多的
		if can_upgrade and not best_can_upgrade:
			# 能升级的优先
			best_synergy = synergy.id
			best_can_upgrade = true
			best_count = count
		elif can_upgrade == best_can_upgrade and count > best_count:
			# 同等条件下，选数量多的
			best_synergy = synergy.id
			best_count = count

	return best_synergy


func _detect_activated_synergies() -> void:
	var all_synergies := SynergyRegistry.get_active_synergies()

	for synergy in all_synergies:
		if synergy.is_hidden():
			continue

		# 特殊处理组合羁绊
		if synergy.is_combo():
			if _check_combo_synergy(synergy):
				_activate_synergy(synergy)
			continue

		var count: int = _synergy_counts.get(synergy.id, 0)
		var level := synergy.get_level_for_count(count)

		if level > 0:
			_activate_synergy(synergy, level, count)


func _check_combo_synergy(synergy: SynergyData) -> bool:
	# EOE姐妹特殊处理：检查露早和柚恩是否都在场
	if synergy.id == "eoe_sisters":
		return _is_eoe_sisters_on_board()
	return false


func _is_eoe_sisters_on_board() -> bool:
	var has_lu_zao := false
	var has_you_en := false

	if board_system == null:
		return false

	var characters := board_system.get_all_characters()
	for instance in characters:
		if instance.character_id == "lu_zao":
			has_lu_zao = true
		elif instance.character_id == "you_en":
			has_you_en = true

	return has_lu_zao and has_you_en


func _is_combo_synergy_active(synergy_id: String) -> bool:
	if synergy_id == "eoe_sisters":
		return _is_eoe_sisters_on_board()
	return false


func _activate_synergy(synergy: SynergyData, level: int = 1, count: int = 0) -> void:
	var characters := _get_characters_with_synergy(synergy.id)

	_active_synergies[synergy.id] = {
		"level": level,
		"count": count,
		"characters": characters,
		"synergy_data": synergy
	}

	synergy_activated.emit(synergy.id, level)


func _get_characters_with_synergy(synergy_id: String) -> Array:
	var result := []
	if board_system == null:
		return result

	var characters := board_system.get_all_characters()
	for instance in characters:
		var char_data := instance.get_character_data()
		if char_data == null:
			continue

		if synergy_id in char_data.synergy_tags:
			result.append(instance)

	return result


#endregion
