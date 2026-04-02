# ShopPanel.gd
# 商店面板
# 显示5个卡牌槽位和刷新按钮
class_name ShopPanel
extends Control

# PRODUCTION CODE - V-Tacit Shop UI
# Implements: design/gdd/shop-ui.md

## 信号：角色被选择（准备放置）
signal character_selected(character: CharacterData)

## 信号：商店刷新
signal shop_refresh()


## 商店系统引用
@export var shop_system: ShopSystem:
	set(value):
		shop_system = value
		if shop_system and is_inside_tree():
			_connect_shop_signals()
			update_display()

## 拖放控制器引用
@export var drag_controller: DragDropController

## 卡槽场景
@export var card_slot_scene: PackedScene

## 卡槽数量
@export var slot_count: int = 5

## 卡槽容器
@onready var _slots_container: HBoxContainer = $SlotsContainer

## 刷新按钮
@onready var _refresh_button: Button = $ButtonContainer/RefreshButton

## 卡槽数组
var _card_slots: Array[CardSlot] = []

## 当前选中/拖动的卡槽
var _active_slot_index: int = -1


func _ready() -> void:
	_create_slots()
	_connect_signals()
	_apply_apple_style()
	# 延迟初始化，确保所有系统都已就绪
	call_deferred("_delayed_init")


func _apply_apple_style() -> void:
	# 苹果风格按钮样式
	if _refresh_button:
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.25, 0.55, 0.85, 0.9)  # 苹果蓝
		normal_style.set_corner_radius_all(6)
		_refresh_button.add_theme_stylebox_override("normal", normal_style)
		_refresh_button.add_theme_color_override("font_color", Color.WHITE)
		_refresh_button.add_theme_font_size_override("font_size", 13)

		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.6, 0.9, 0.95)
		hover_style.set_corner_radius_all(6)
		_refresh_button.add_theme_stylebox_override("hover", hover_style)


func _delayed_init() -> void:
	if shop_system:
		_connect_shop_signals()
		update_display()
		print("ShopPanel: Initialized with shop_system")
	else:
		push_warning("ShopPanel: shop_system is null!")


func _delayed_update() -> void:
	# 已被 _delayed_init 替代
	pass


func _create_slots() -> void:
	_card_slots.clear()

	# 检查容器是否存在
	if _slots_container == null:
		push_error("ShopPanel: _slots_container is null!")
		return

	# 清空现有子节点
	for child in _slots_container.get_children():
		child.queue_free()

	# 创建卡槽
	for i in range(slot_count):
		var slot: CardSlot
		if card_slot_scene:
			slot = card_slot_scene.instantiate()
		else:
			slot = CardSlot.new()

		slot.slot_index = i
		slot.card_clicked.connect(_on_slot_clicked)
		slot.drag_initiated.connect(_on_slot_drag_initiated)
		slot.hover_entered.connect(_on_slot_hover_entered)
		slot.hover_exited.connect(_on_slot_hover_exited)

		_slots_container.add_child(slot)
		_card_slots.append(slot)


func _connect_signals() -> void:
	if _refresh_button:
		_refresh_button.pressed.connect(_on_refresh_pressed)

	_connect_shop_signals()


func _connect_shop_signals() -> void:
	if shop_system == null:
		push_warning("ShopPanel: Cannot connect signals - shop_system is null")
		return

	if not shop_system.shop_refreshed.is_connected(_on_shop_refreshed):
		shop_system.shop_refreshed.connect(_on_shop_refreshed)
	if not shop_system.slot_emptied.is_connected(_on_slot_emptied):
		shop_system.slot_emptied.connect(_on_slot_emptied)

	# 连接拖放控制器的结束信号
	if drag_controller and not drag_controller.drag_ended.is_connected(_on_drag_ended):
		drag_controller.drag_ended.connect(_on_drag_ended)

	print("ShopPanel: Connected to shop_system signals")


#region 公共接口

## 更新商店显示
func update_display() -> void:
	if shop_system == null:
		return

	var cards: Array = shop_system.get_shop_cards()
	for i in range(_card_slots.size()):
		if i < cards.size():
			_card_slots[i].set_character(cards[i])
		else:
			_card_slots[i].clear()


## 刷新商店
func refresh_shop() -> void:
	if shop_system:
		shop_system.refresh_shop()


## 清空显示
func clear_display() -> void:
	for slot in _card_slots:
		slot.clear()


#endregion


#region 信号处理

func _on_slot_clicked(slot_index: int) -> void:
	if shop_system == null:
		return

	var char_data: CharacterData = shop_system.get_card_at(slot_index)
	if char_data == null:
		return

	# 选中角色（准备放置）
	_active_slot_index = slot_index
	character_selected.emit(char_data)


func _on_slot_drag_initiated(slot_index: int, _character: CharacterData) -> void:
	if drag_controller == null or shop_system == null:
		return

	# 选中角色
	var char_data: CharacterData = shop_system.select_character(slot_index)
	if char_data == null:
		return

	# 开始拖动
	drag_controller.start_drag_from_shop(char_data, slot_index)
	_card_slots[slot_index].set_dragging(true)
	_active_slot_index = slot_index

	character_selected.emit(char_data)


func _on_slot_hover_entered(_slot_index: int) -> void:
	# 可以在这里显示卡牌详情
	pass


func _on_slot_hover_exited(_slot_index: int) -> void:
	pass


func _on_refresh_pressed() -> void:
	refresh_shop()
	shop_refresh.emit()


func _on_shop_refreshed(_cards: Array) -> void:
	update_display()


func _on_slot_emptied(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < _card_slots.size():
		_card_slots[slot_index].clear()


#endregion


#region 内部方法

func _on_drag_ended(_success: bool, _position: Vector2i) -> void:
	# 重置卡槽拖动状态
	for slot in _card_slots:
		slot.set_dragging(false)

	_active_slot_index = -1
	update_display()


#endregion
