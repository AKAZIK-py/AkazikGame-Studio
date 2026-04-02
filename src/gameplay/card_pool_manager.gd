# CardPoolManager.gd
# 卡池管理器
# 管理角色池、抽卡概率、已选角色追踪
class_name CardPoolManager
extends Node

# PRODUCTION CODE - V-Tacit Card Pool System
# Implements: design/gdd/card-pool.md

## 信号：卡池变化
signal pool_changed()

## 信号：卡池为空
signal pool_empty()


## 商店卡槽数量
@export var shop_slot_count: int = 5

## 各费用出现概率
@export var tier_probabilities: Array[float] = [0.30, 0.25, 0.25, 0.15, 0.05]

## 各费用角色池 {tier: Array[CharacterData]}
var _tier_pools: Dictionary = {}

## 各费用剩余数量 {tier: int}
var _tier_counts: Dictionary = {}

## 已选角色ID列表
var _selected_ids: Array[String] = []

## 总卡池数量
var _total_count: int = 0


#region 公共接口

## 初始化卡池
func initialize_pool() -> void:
	_tier_pools.clear()
	_tier_counts.clear()
	_selected_ids.clear()
	_total_count = 0

	# 按费用分组角色
	for tier in range(1, 6):
		_tier_pools[tier] = []
		_tier_counts[tier] = 0

	# 从CharacterRegistry加载角色
	var all_chars := CharacterRegistry.get_all_characters()
	if all_chars.is_empty():
		push_error("CardPoolManager: CharacterRegistry returned empty character list!")
		return

	for char_data in all_chars:
		var tier := char_data.rarity
		if _tier_pools.has(tier):
			_tier_pools[tier].append(char_data)
			_tier_counts[tier] += 1
			_total_count += 1

	pool_changed.emit()

	# 打印详细信息
	print("CardPoolManager: Initialized with %d cards" % _total_count)
	for tier in range(1, 6):
		print("  Tier %d: %d cards" % [tier, _tier_counts[tier]])


## 抽取一张卡（按概率）
func draw_card() -> CharacterData:
	if _total_count <= 0:
		pool_empty.emit()
		return null

	# 按概率抽取
	var roll := randf()
	var cumulative := 0.0

	for tier in range(1, 6):
		cumulative += tier_probabilities[tier - 1]
		if roll < cumulative:
			return draw_from_tier(tier)

	# 默认抽取最低费用
	return draw_from_tier(1)


## 抽取N张卡
func draw_cards(count: int) -> Array[CharacterData]:
	var result: Array[CharacterData] = []
	for i in range(count):
		if _total_count <= 0:
			break
		var card := draw_card()
		if card != null:
			result.append(card)
	return result


## 从指定费用抽取
func draw_from_tier(tier: int) -> CharacterData:
	if not _tier_pools.has(tier):
		return null

	var pool: Array = _tier_pools[tier]
	if pool.is_empty():
		# 该费用已空，尝试其他费用
		return draw_from_available_tier()

	# 随机选择
	var index := randi() % pool.size()
	var char_data: CharacterData = pool[index]

	return char_data


## 从任意可用费用抽取
func draw_from_available_tier() -> CharacterData:
	# 收集所有非空费用
	var available_tiers: Array[int] = []
	for tier in range(1, 6):
		if _tier_counts.get(tier, 0) > 0:
			available_tiers.append(tier)

	if available_tiers.is_empty():
		return null

	# 按剩余概率抽取
	var total_weight := 0.0
	var weights: Array[float] = []
	for tier in available_tiers:
		var weight := tier_probabilities[tier - 1]
		weights.append(weight)
		total_weight += weight

	var roll := randf() * total_weight
	var cumulative := 0.0

	for i in range(available_tiers.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return draw_from_tier(available_tiers[i])

	return draw_from_tier(available_tiers[0])


## 从卡池移除角色（已选走）
func remove_from_pool(character_id: String) -> bool:
	var char_data: CharacterData = CharacterRegistry.get_character(character_id)
	if char_data == null:
		return false

	var tier := char_data.rarity
	if not _tier_pools.has(tier):
		return false

	var pool: Array = _tier_pools[tier]
	for i in range(pool.size()):
		var data: CharacterData = pool[i]
		if data.id == character_id:
			pool.remove_at(i)
			_tier_counts[tier] -= 1
			_total_count -= 1
			_selected_ids.append(character_id)
			pool_changed.emit()
			return true

	return false


## 重置卡池
func reset_pool() -> void:
	initialize_pool()


## 获取卡池总数量
func get_total_count() -> int:
	return _total_count


## 获取指定费用剩余数量
func get_tier_count(tier: int) -> int:
	return _tier_counts.get(tier, 0)


## 获取所有费用统计
func get_all_tier_counts() -> Dictionary:
	return _tier_counts.duplicate()


## 检查卡池是否为空
func is_pool_empty() -> bool:
	return _total_count <= 0


## 检查指定费用是否为空
func is_tier_empty(tier: int) -> bool:
	return _tier_counts.get(tier, 0) <= 0


## 获取已选角色列表
func get_selected_ids() -> Array[String]:
	return _selected_ids.duplicate()


## 获取剩余概率（考虑已空费用）
func get_effective_probabilities() -> Dictionary:
	var result := {}
	var total_weight := 0.0

	for tier in range(1, 6):
		if _tier_counts.get(tier, 0) > 0:
			var weight := tier_probabilities[tier - 1]
			result[tier] = weight
			total_weight += weight

	# 归一化
	if total_weight > 0:
		for tier in result:
			result[tier] = result[tier] / total_weight

	return result


#endregion
