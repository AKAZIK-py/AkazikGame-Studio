# DragDropController.gd
# 拖放交互控制器
# 处理从商店拖动角色到棋盘放置的交互
class_name DragDropController
extends Node

# PRODUCTION CODE - V-Tacit Drag-Drop Interaction
# Implements: design/gdd/drag-drop-interaction.md

## 信号：拖动开始
signal drag_started(character: CharacterData)

## 信号：拖动移动
signal drag_moved(position: Vector2)

## 信号：拖动结束
signal drag_ended(success: bool, position: Vector2i)

## 信号：放置成功
signal placed_character(character: CharacterInstance, position: Vector2i)

## 信号：放置失败
signal placement_failed(reason: String)

## 信号：拖动预览更新（用于渲染器）
signal preview_updated(character: CharacterData, q: int, r: int, visible: bool)


## 棋盘系统引用
@export var board_system: BoardSystem

## 格子显示系统引用
@export var cell_display: CellDisplaySystem

## 拖动状态枚举
enum DragState {
	IDLE,       ## 空闲
	DRAGGING,   ## 拖动中
	HOVERING    ## 悬停在格子上
}

## 当前拖动状态
var _state: DragState = DragState.IDLE

## 正在拖动的角色数据
var _dragging_character: CharacterData = null

## 当前悬停的格子
var _hover_cell: Vector2i = Vector2i(-1, -1)

## 拖动来源（"shop", "board", 或 "bench"）
var _drag_source: String = ""

## 商店卡槽索引（如果从商店拖动）
var _shop_slot_index: int = -1

## 源格子位置（如果从棋盘拖动）
var _source_cell: Vector2i = Vector2i(-1, -1)

## 源观战席位置（如果从观战席拖动）
var _source_bench_slot: int = -1

## 拖动中的实例（如果从棋盘或观战席拖动）
var _dragging_instance: CharacterInstance = null


func _process(_delta: float) -> void:
	if _state == DragState.IDLE:
		return

	# 更新拖动位置（使用全局鼠标位置）
	update_drag_position(get_viewport().get_mouse_position())


func _input(event: InputEvent) -> void:
	if _state == DragState.IDLE:
		return

	# 监听鼠标释放
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			end_drag()
			get_viewport().set_input_as_handled()


#region 公共接口

## 从商店开始拖动
func start_drag_from_shop(character: CharacterData, slot_index: int) -> bool:
	if _state != DragState.IDLE:
		return false

	_dragging_character = character
	_drag_source = "shop"
	_shop_slot_index = slot_index
	_state = DragState.DRAGGING

	# 显示格子
	if cell_display:
		cell_display.show_cells()

	drag_started.emit(character)
	print("Drag started: %s" % character.display_name)
	return true


## 从棋盘开始拖动（移动已有角色）
func start_drag_from_board(character_id: String, from_pos: Vector2i) -> bool:
	if _state != DragState.IDLE:
		return false

	var instance := GameState.get_character_at(from_pos.x, from_pos.y)
	if instance == null:
		return false

	_dragging_character = CharacterRegistry.get_character(character_id)
	_drag_source = "board"
	_source_cell = from_pos
	_state = DragState.DRAGGING

	# 显示格子
	if cell_display:
		cell_display.show_cells()

	drag_started.emit(_dragging_character)
	return true


## 从棋盘实例开始拖动
func start_drag_from_board_instance(instance: CharacterInstance, from_pos: Vector2i) -> bool:
	if _state != DragState.IDLE:
		return false

	if instance == null:
		return false

	_dragging_character = instance.get_character_data()
	_drag_source = "board"
	_source_cell = from_pos
	_dragging_instance = instance
	_state = DragState.DRAGGING

	# 显示格子
	if cell_display:
		cell_display.show_cells()

	drag_started.emit(_dragging_character)
	print("Drag from board: %s at (%d, %d)" % [_dragging_character.display_name, from_pos.x, from_pos.y])
	return true


## 从观战席开始拖动
func start_drag_from_bench(instance: CharacterInstance, slot: int) -> bool:
	if _state != DragState.IDLE:
		return false

	if instance == null:
		return false

	_dragging_character = instance.get_character_data()
	_drag_source = "bench"
	_source_bench_slot = slot
	_dragging_instance = instance
	_state = DragState.DRAGGING

	# 显示格子
	if cell_display:
		cell_display.show_cells()

	drag_started.emit(_dragging_character)
	print("Drag from bench: %s at slot %d" % [_dragging_character.display_name, slot])
	return true


## 更新拖动位置
func update_drag_position(screen_position: Vector2) -> void:
	if _state == DragState.IDLE or board_system == null:
		return

	drag_moved.emit(screen_position)

	# 转换到棋盘坐标（直接使用屏幕坐标，因为board_center已经是屏幕坐标）
	var hex_coord := board_system.pixel_to_hex(screen_position)

	# 检查是否在有效格子上
	var is_valid := false

	if _drag_source == "shop":
		# 从商店拖动：只允许放置在我方区域的空格子
		is_valid = board_system.can_player_place(hex_coord.x, hex_coord.y)
	elif _drag_source == "board":
		# 从棋盘拖动：允许放置在我方区域（包括已有角色的格子，用于交换）
		is_valid = board_system.is_valid_position(hex_coord.x, hex_coord.y) and board_system.is_player_zone(hex_coord.x, hex_coord.y)

	if is_valid:
		# 进入有效格子
		_state = DragState.HOVERING
		_hover_cell = hex_coord

		# 高亮格子
		if cell_display:
			cell_display.highlight_cell(hex_coord.x, hex_coord.y)

		# 发送预览信号
		preview_updated.emit(_dragging_character, hex_coord.x, hex_coord.y, true)
	else:
		# 格子无效
		_state = DragState.DRAGGING
		_hover_cell = Vector2i(-1, -1)

		if cell_display:
			cell_display.clear_highlight()

		# 隐藏预览
		preview_updated.emit(_dragging_character, -1, -1, false)


## 结束拖动
func end_drag() -> bool:
	if _state == DragState.IDLE:
		drag_ended.emit(false, Vector2i(-1, -1))
		return false

	var success := false

	if _state == DragState.HOVERING and _hover_cell.x >= 0:
		# 放置到悬停的格子
		success = _place_character()

		if success:
			drag_ended.emit(true, _hover_cell)
		else:
			drag_ended.emit(false, Vector2i(-1, -1))
	else:
		# 取消放置
		placement_failed.emit("未悬停在有效格子上")
		drag_ended.emit(false, Vector2i(-1, -1))

	# 隐藏预览
	preview_updated.emit(null, -1, -1, false)

	# 隐藏格子
	if cell_display:
		cell_display.hide_cells()

	# 重置状态
	_dragging_character = null
	_hover_cell = Vector2i(-1, -1)
	_drag_source = ""
	_shop_slot_index = -1
	_source_cell = Vector2i(-1, -1)
	_source_bench_slot = -1
	_dragging_instance = null
	_state = DragState.IDLE

	return success


## 取消拖动
func cancel_drag() -> void:
	if _state == DragState.IDLE:
		return

	# 隐藏预览
	preview_updated.emit(null, -1, -1, false)

	# 隐藏格子
	if cell_display:
		cell_display.hide_cells()

	# 重置状态
	_dragging_character = null
	_hover_cell = Vector2i(-1, -1)
	_drag_source = ""
	_shop_slot_index = -1
	_source_cell = Vector2i(-1, -1)
	_source_bench_slot = -1
	_dragging_instance = null
	_state = DragState.IDLE


## 获取当前拖动状态
func get_state() -> DragState:
	return _state


## 是否正在拖动
func is_dragging() -> bool:
	return _state != DragState.IDLE


## 获取正在拖动的角色
func get_dragging_character() -> CharacterData:
	return _dragging_character


## 获取当前悬停的格子
func get_hover_cell() -> Vector2i:
	return _hover_cell


## 获取拖动来源
func get_drag_source() -> String:
	return _drag_source


## 获取源格子位置
func get_source_cell() -> Vector2i:
	return _source_cell


## 获取源观战席位置
func get_source_bench_slot() -> int:
	return _source_bench_slot


#endregion


#region 内部方法

func _place_character() -> bool:
	if _dragging_character == null or board_system == null:
		return false

	match _drag_source:
		"shop":
			return _place_from_shop()
		"board":
			return _move_on_board()
		"bench":
			return _place_from_bench()
		_:
			return false


func _place_from_shop() -> bool:
	# 只允许放置在我方区域
	if not board_system.can_player_place(_hover_cell.x, _hover_cell.y):
		placement_failed.emit("只能在我方区域放置角色")
		return false

	var instance := board_system.place_character(_dragging_character, _hover_cell.x, _hover_cell.y)
	if instance == null:
		placement_failed.emit("放置失败：格子无效或已占用")
		return false

	placed_character.emit(instance, _hover_cell)
	print("Character placed: %s at (%d, %d)" % [_dragging_character.display_name, _hover_cell.x, _hover_cell.y])
	return true


func _place_from_bench() -> bool:
	# 从观战席移动到棋盘
	if not board_system.can_player_place(_hover_cell.x, _hover_cell.y):
		placement_failed.emit("只能在我方区域放置角色")
		return false

	var success := GameState.move_bench_to_board(_source_bench_slot, _hover_cell.x, _hover_cell.y)
	if not success:
		placement_failed.emit("放置失败：格子无效或已占用")
		return false

	print("Character moved from bench to board: (%d, %d)" % [_hover_cell.x, _hover_cell.y])
	return true


func _move_on_board() -> bool:
	if board_system == null:
		return false

	# 目标格子必须在我方区域
	if not board_system.is_player_zone(_hover_cell.x, _hover_cell.y):
		placement_failed.emit("只能在我方区域放置角色")
		return false

	# 检查是否移动到同一个位置
	if _source_cell.x == _hover_cell.x and _source_cell.y == _hover_cell.y:
		return true  # 移动到同一位置，视为成功

	# 检查目标格子是否有角色
	var target_instance := board_system.get_character_at(_hover_cell.x, _hover_cell.y)

	if target_instance != null:
		# 目标格子有角色，交换位置
		var success := _swap_characters(_source_cell, _hover_cell)
		if success:
			print("Swapped characters at (%d, %d) and (%d, %d)" % [_source_cell.x, _source_cell.y, _hover_cell.x, _hover_cell.y])
		return success
	else:
		# 目标格子为空，移动角色
		var success := board_system.move_character(_source_cell.x, _source_cell.y, _hover_cell.x, _hover_cell.y)
		if success:
			print("Moved character to (%d, %d)" % [_hover_cell.x, _hover_cell.y])
		return success


func _swap_characters(pos_a: Vector2i, pos_b: Vector2i) -> bool:
	if board_system == null:
		return false

	# 获取两个位置的角色实例
	var instance_a := board_system.get_character_at(pos_a.x, pos_a.y)
	var instance_b := board_system.get_character_at(pos_b.x, pos_b.y)

	if instance_a == null or instance_b == null:
		return false

	# 使用 GameState 交换
	return GameState.swap_characters(pos_a.x, pos_a.y, pos_b.x, pos_b.y)


#endregion
