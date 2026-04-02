# SynergyRegistry.gd
# 羁绊数据注册表
# 单例：加载和管理所有羁绊数据
# Autoload: SynergyRegistry (无需 class_name)
extends Node

# PRODUCTION CODE - V-Tacit Synergy Data System
# Implements: design/gdd/synergy-data.md

## 信号：数据加载完成
signal data_loaded()

## 信号：数据加载失败
signal data_load_failed(error: String)


## 羁绊数据目录路径
const SYNERGY_DATA_PATH := "res://assets/data/synergies/"

## 羁绊数据缓存 {id: SynergyData}
var _synergies: Dictionary = {}

## 是否已初始化
var _is_initialized: bool = false


## 初始化：加载所有羁绊数据
func initialize() -> void:
	if _is_initialized:
		push_warning("SynergyRegistry: Already initialized")
		return

	_load_all_synergies()
	_is_initialized = true
	data_loaded.emit()


## 获取单个羁绊数据
func get_synergy(id: String) -> SynergyData:
	var result: Variant = _synergies.get(id)
	if result == null:
		return null
	return result


## 获取所有羁绊
func get_all_synergies() -> Array[SynergyData]:
	var result: Array[SynergyData] = []
	for data in _synergies.values():
		result.append(data)
	return result


## 按类型筛选
func get_by_type(type: String) -> Array[SynergyData]:
	var result: Array[SynergyData] = []
	for data in _synergies.values():
		if data.type == type:
			result.append(data)
	return result


## 获取羁绊阈值
func get_thresholds(synergy_id: String) -> Array[int]:
	var data := get_synergy(synergy_id)
	if data == null:
		return []
	return data.thresholds


## 获取羁绊数量
func get_synergy_count() -> int:
	return _synergies.size()


## 检查羁绊是否存在
func has_synergy(id: String) -> bool:
	return _synergies.has(id)


## 获取所有非隐藏羁绊
func get_active_synergies() -> Array[SynergyData]:
	var result: Array[SynergyData] = []
	for data in _synergies.values():
		if not data.is_hidden():
			result.append(data)
	return result


## 获取万能羁绊列表
func get_wildcard_synergies() -> Array[SynergyData]:
	return get_by_type("wildcard")


## 获取组合羁绊列表
func get_combo_synergies() -> Array[SynergyData]:
	return get_by_type("combo")


## 获取隐藏羁绊列表
func get_hidden_synergies() -> Array[SynergyData]:
	return get_by_type("hidden")


## 根据标签ID获取羁绊（兼容角色数据的synergy_tags）
func get_synergy_by_tag(tag: String) -> SynergyData:
	var result: Variant = _synergies.get(tag)
	if result == null:
		return null
	return result


## 批量获取羁绊
func get_synergies_by_tags(tags: Array[String]) -> Array[SynergyData]:
	var result: Array[SynergyData] = []
	for tag in tags:
		var data := get_synergy_by_tag(tag)
		if data != null and data not in result:
			result.append(data)
	return result


## 重新加载数据
func reload() -> void:
	_synergies.clear()
	_is_initialized = false
	initialize()


## 验证所有数据
func validate_all() -> bool:
	var all_valid := true
	for data in _synergies.values():
		if not data.validate():
			all_valid = false
	return all_valid


#region 内部方法

func _load_all_synergies() -> void:
	var dir := DirAccess.open(SYNERGY_DATA_PATH)
	if dir == null:
		push_error("SynergyRegistry: Cannot open directory %s" % SYNERGY_DATA_PATH)
		data_load_failed.emit("Cannot open synergy data directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := SYNERGY_DATA_PATH + file_name
			var data := load(full_path) as SynergyData
			if data != null:
				if data.validate():
					_synergies[data.id] = data
				else:
					push_error("SynergyRegistry: Invalid synergy data in %s" % file_name)
			else:
				push_warning("SynergyRegistry: Failed to load %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if _synergies.is_empty():
		push_warning("SynergyRegistry: No synergy data loaded")
	else:
		print("SynergyRegistry: Loaded %d synergies" % _synergies.size())


#endregion
