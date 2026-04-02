# ShopSystem.gd
# 商店系统
# 管理商店卡槽、刷新、选择角色
class_name ShopSystem
extends Node

# PRODUCTION CODE - V-Tacit Shop System
# Implements: design/gdd/shop-system.md

## 信号：商店刷新
signal shop_refreshed(cards: Array)

## 信号：角色被选择
signal character_selected(character: CharacterData, slot_index: int)

## 信号：卡槽变空
signal slot_emptied(slot_index: int)


## 卡池管理器引用
@export var card_pool: CardPoolManager

## 商店卡槽数量
@export var slot_count: int = 5

## 商店卡牌（可能为null表示空槽）
## 注意：使用普通数组而非类型化数组，因为需要支持null值
var _shop_cards: Array = []

## 卡槽是否为空
var _slot_empty: Array[bool] = []


#region 公共接口

## 初始化商店
func initialize() -> void:
	if card_pool == null:
		card_pool = CardPoolManager.new()
		card_pool.initialize_pool()
		add_child(card_pool)

	_shop_cards.clear()
	_slot_empty.clear()
	for i in range(slot_count):
		_shop_cards.append(null)
		_slot_empty.append(true)


## 刷新商店（重新抽取卡牌）
func refresh_shop() -> void:
	# 确保数组已初始化
	if _shop_cards.size() != slot_count:
		_shop_cards.clear()
		_slot_empty.clear()
		for i in range(slot_count):
			_shop_cards.append(null)
			_slot_empty.append(true)

	# 清空当前商店
	clear_shop()

	# 抽取新卡牌
	if card_pool == null:
		push_error("ShopSystem: card_pool is null!")
		return

	var new_cards := card_pool.draw_cards(slot_count)
	if new_cards.is_empty():
		push_warning("ShopSystem: card_pool returned no cards!")
		return

	for i in range(new_cards.size()):
		_shop_cards[i] = new_cards[i]
		_slot_empty[i] = false

	# 更新GameState
	GameState.set_shop_cards(_shop_cards)
	GameState.increment_refresh_count()

	print("ShopSystem: Refreshed shop with %d cards" % new_cards.size())
	shop_refreshed.emit(new_cards)


## 选择角色（从商店购买/领取）
func select_character(slot_index: int) -> CharacterData:
	if slot_index < 0 or slot_index >= slot_count:
		return null

	if _slot_empty[slot_index]:
		return null

	var char_data: CharacterData = _shop_cards[slot_index]
	if char_data == null:
		return null

	# 从卡池移除
	card_pool.remove_from_pool(char_data.id)

	# 清空卡槽
	_shop_cards[slot_index] = null
	_slot_empty[slot_index] = true

	character_selected.emit(char_data, slot_index)
	slot_emptied.emit(slot_index)

	return char_data


## 获取当前商店卡牌
func get_shop_cards() -> Array:
	return _shop_cards.duplicate()


## 获取指定卡槽的角色
func get_card_at(slot_index: int) -> CharacterData:
	if slot_index < 0 or slot_index >= slot_count:
		return null
	return _shop_cards[slot_index]


## 检查卡槽是否为空
func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slot_count:
		return true
	return _slot_empty[slot_index]


## 清空商店
func clear_shop() -> void:
	# 安全检查：确保数组大小正确
	if _shop_cards.size() != slot_count:
		_shop_cards.clear()
		_slot_empty.clear()
		for i in range(slot_count):
			_shop_cards.append(null)
			_slot_empty.append(true)
		return

	for i in range(slot_count):
		_shop_cards[i] = null
		_slot_empty[i] = true


## 获取非空卡槽数量
func get_filled_slot_count() -> int:
	var count := 0
	for i in range(slot_count):
		if not _slot_empty[i]:
			count += 1
	return count


## 获取刷新次数
func get_refresh_count() -> int:
	return GameState.get_refresh_count()


#endregion


#region 内部方法

func _ready() -> void:
	# Initialization is handled by game.gd to ensure correct order
	# (CharacterRegistry must be initialized before card_pool draws cards)
	pass


#endregion
