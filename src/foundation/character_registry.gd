# CharacterRegistry.gd
# 角色数据注册表
# 单例：加载和管理所有角色数据
# Autoload: CharacterRegistry (无需 class_name)
extends Node

# PRODUCTION CODE - V-Tacit Character Data System
# Implements: design/gdd/character-data.md

## 信号：数据加载完成
signal data_loaded()

## 信号：数据加载失败
signal data_load_failed(error: String)


## 角色数据目录路径
const CHARACTER_DATA_PATH := "res://assets/data/characters/"

## 角色数据缓存 {id: CharacterData}
var _characters: Dictionary = {}

## 是否已初始化
var _is_initialized: bool = false


## 初始化：加载所有角色数据
func initialize() -> void:
	if _is_initialized:
		push_warning("CharacterRegistry: Already initialized")
		return

	_load_all_characters()
	_is_initialized = true

	if _characters.is_empty():
		push_error("CharacterRegistry: No characters loaded!")
	else:
		print("CharacterRegistry: Initialized with %d characters" % _characters.size())

	data_loaded.emit()


## 获取单个角色数据
func get_character(id: String) -> CharacterData:
	var result: Variant = _characters.get(id)
	if result == null:
		return null
	return result


## 获取所有角色
func get_all_characters() -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for data in _characters.values():
		result.append(data)
	return result


## 按羁绊标签筛选
func get_by_synergy_tag(tag: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for data in _characters.values():
		if tag in data.synergy_tags:
			result.append(data)
	return result


## 按稀有度筛选
func get_by_rarity(rarity: int) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for data in _characters.values():
		if data.rarity == rarity:
			result.append(data)
	return result


## 按定位筛选
func get_by_role(role: String) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for data in _characters.values():
		if data.role == role:
			result.append(data)
	return result


## 获取角色数量
func get_character_count() -> int:
	return _characters.size()


## 检查角色是否存在
func has_character(id: String) -> bool:
	return _characters.has(id)


## 获取所有羁绊标签
func get_all_synergy_tags() -> Array[String]:
	var tags: Array[String] = []
	for data in _characters.values():
		for tag in data.synergy_tags:
			if tag not in tags:
				tags.append(tag)
	return tags


## 获取指定标签的角色数量
func get_count_by_synergy_tag(tag: String) -> int:
	return get_by_synergy_tag(tag).size()


## 获取稀有度分布
func get_rarity_distribution() -> Dictionary:
	var dist := {}
	for rarity in range(1, 6):
		dist[rarity] = get_by_rarity(rarity).size()
	return dist


## 重新加载数据
func reload() -> void:
	_characters.clear()
	_is_initialized = false
	initialize()


## 验证所有数据
func validate_all() -> bool:
	var all_valid := true
	for data in _characters.values():
		if not data.validate():
			all_valid = false
	return all_valid


#region 内部方法

func _load_all_characters() -> void:
	var dir := DirAccess.open(CHARACTER_DATA_PATH)
	if dir == null:
		push_error("CharacterRegistry: Cannot open directory %s" % CHARACTER_DATA_PATH)
		data_load_failed.emit("Cannot open character data directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := CHARACTER_DATA_PATH + file_name
			var data := load(full_path) as CharacterData
			if data != null:
				if data.validate():
					_characters[data.id] = data
				else:
					push_error("CharacterRegistry: Invalid character data in %s" % file_name)
			else:
				push_warning("CharacterRegistry: Failed to load %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if _characters.is_empty():
		push_warning("CharacterRegistry: No character data loaded")
	else:
		print("CharacterRegistry: Loaded %d characters" % _characters.size())


#endregion
