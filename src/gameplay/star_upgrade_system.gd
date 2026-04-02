# StarUpgradeSystem.gd
# 升星系统
# 检测并处理三张相同角色的自动升星
class_name StarUpgradeSystem
extends Node

# PRODUCTION CODE - V-Tacit Star Upgrade System

## 信号：角色升星
signal character_upgraded(instance: CharacterInstance, old_star: int, new_star: int)

## 信号：升星合并（返回被合并的实例列表）
signal star_merge_completed(merged_instances: Array, upgraded_instance: CharacterInstance)

## 棋盘系统引用
@export var board_system: BoardSystem

## 升星所需数量
const UPGRADE_COUNT := 3

## 星级上限（普通角色）
const MAX_STAR_LEVEL := 5

## 星瞳特殊上限
const XING_TONG_MAX_STAR := 6

## 星瞳ID
const XING_TONG_ID := "xing_tong"


## 检查并执行升星（在角色放置后调用）
## 返回升星后的实例（如果发生升星），否则返回null
func check_and_upgrade(placed_instance: CharacterInstance, placed_q: int, placed_r: int) -> CharacterInstance:
	if board_system == null:
		return null

	var char_id := placed_instance.character_id

	# 获取棋盘上所有相同角色ID的实例
	var same_instances := _get_same_characters(char_id)

	# 需要至少3个相同角色才能升星
	if same_instances.size() < UPGRADE_COUNT:
		return null

	# 检查是否所有实例星级相同（不能跨星级合成）
	var star_level := placed_instance.star_level
	var same_star_instances: Array[CharacterInstance] = []

	for instance in same_instances:
		if instance.star_level == star_level:
			same_star_instances.append(instance)

	# 相同星级的数量不足
	if same_star_instances.size() < UPGRADE_COUNT:
		return null

	# 检查是否可以升星
	if not _can_upgrade(char_id, star_level):
		return null

	# 执行升星合并
	return _perform_upgrade(same_star_instances, placed_q, placed_r)


## 获取棋盘上所有相同角色的实例
func _get_same_characters(char_id: String) -> Array[CharacterInstance]:
	var result: Array[CharacterInstance] = []
	var all_instances := board_system.get_all_characters()

	for instance in all_instances:
		if instance.character_id == char_id:
			result.append(instance)

	return result


## 检查是否可以升星
func _can_upgrade(char_id: String, current_star: int) -> bool:
	# 星瞳特殊规则：可以升到6星
	if char_id == XING_TONG_ID:
		return current_star < XING_TONG_MAX_STAR

	# 普通角色：最高5星
	return current_star < MAX_STAR_LEVEL


## 执行升星合并
func _perform_upgrade(instances: Array[CharacterInstance], target_q: int, target_r: int) -> CharacterInstance:
	# 取前3个实例进行合并（包括刚放置的那个）
	var to_merge: Array[CharacterInstance] = []
	var upgraded_instance: CharacterInstance = null

	# 找到刚放置的实例，保留它
	for instance in instances:
		if instance.position.x == target_q and instance.position.y == target_r:
			upgraded_instance = instance
			break

	# 如果没找到，使用第一个
	if upgraded_instance == null and instances.size() > 0:
		upgraded_instance = instances[0]

	if upgraded_instance == null:
		return null

	# 收集要合并的其他实例
	for instance in instances:
		if instance != upgraded_instance and to_merge.size() < UPGRADE_COUNT - 1:
			to_merge.append(instance)

	# 如果要合并的数量不足，返回null
	if to_merge.size() < UPGRADE_COUNT - 1:
		return null

	var old_star := upgraded_instance.star_level

	# 从棋盘移除被合并的实例
	for instance in to_merge:
		board_system.remove_character_at(instance.position.x, instance.position.y)

	# 升星
	upgraded_instance.upgrade_star()

	# 发射信号
	character_upgraded.emit(upgraded_instance, old_star, upgraded_instance.star_level)
	star_merge_completed.emit(to_merge, upgraded_instance)

	print("StarUpgradeSystem: %s 升星 %d -> %d" % [
		upgraded_instance.character_id,
		old_star,
		upgraded_instance.star_level
	])

	return upgraded_instance


## 获取星级乘数
func get_star_multiplier(star_level: int) -> float:
	# 每星增加50%属性
	# 1星 = 1.0x, 2星 = 1.5x, 3星 = 2.0x, 4星 = 2.5x, 5星 = 3.0x, 6星 = 3.5x
	return 1.0 + (star_level - 1) * 0.5
