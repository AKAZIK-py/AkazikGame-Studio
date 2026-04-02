# CellDisplaySystem.gd
# 格子显示系统
# 控制拖动时显示/隐藏格子、高亮悬停格子
class_name CellDisplaySystem
extends Node

# PRODUCTION CODE - V-Tacit Cell Display System
# Implements: design/gdd/cell-display.md

## 棋盘渲染器引用
@export var board_renderer: BoardRenderer

## 棋盘系统引用
@export var board_system: BoardSystem

## 格子边框颜色（显示时）
@export var cell_border_color: Color = Color(1, 1, 1, 0.3)

## 格子填充颜色（显示时）
@export var cell_fill_color: Color = Color(0.5, 0.5, 0.5, 0.15)

## 高亮颜色（悬停时）
@export var highlight_color: Color = Color(0.3, 0.8, 0.4, 0.4)

## 高亮边框颜色
@export var highlight_border_color: Color = Color(0.4, 1.0, 0.5, 0.8)

## 动画时间（秒）
@export var animation_duration: float = 0.1


## 当前高亮的格子
var _highlighted_cell: Vector2i = Vector2i(-1, -1)

## 是否正在显示格子
var _is_showing: bool = false


#region 公共接口

## 显示格子（拖动开始时调用）
func show_cells() -> void:
	if _is_showing:
		return
	_is_showing = true
	_highlighted_cell = Vector2i(-1, -1)

	if board_renderer:
		board_renderer.show_cells = true


## 隐藏格子（拖动结束时调用）
func hide_cells() -> void:
	if not _is_showing:
		return
	_is_showing = false
	_highlighted_cell = Vector2i(-1, -1)

	if board_renderer:
		board_renderer.show_cells = false


## 高亮指定格子
func highlight_cell(q: int, r: int) -> void:
	if not _is_showing:
		return
	if _highlighted_cell.x == q and _highlighted_cell.y == r:
		return

	_highlighted_cell = Vector2i(q, r)

	# 请求重绘以显示高亮
	if board_renderer:
		board_renderer.queue_redraw()


## 清除高亮
func clear_highlight() -> void:
	if _highlighted_cell.x < 0:
		return

	_highlighted_cell = Vector2i(-1, -1)

	if board_renderer:
		board_renderer.queue_redraw()


## 是否正在显示
func is_showing() -> bool:
	return _is_showing


## 获取当前高亮的格子
func get_highlighted_cell() -> Vector2i:
	return _highlighted_cell


#endregion


#region 内部方法

func _ready() -> void:
	# 连接输入管理器信号
	if InputManager:
		InputManager.drag_started.connect(_on_drag_started)
		InputManager.drag_ended.connect(_on_drag_ended)
		InputManager.drag_moved.connect(_on_drag_moved)
		InputManager.drag_cancelled.connect(_on_drag_cancelled)


func _on_drag_started(_position: Vector2, _target: Node) -> void:
	show_cells()


func _on_drag_ended(_position: Vector2) -> void:
	hide_cells()


func _on_drag_moved(position: Vector2, _delta: Vector2) -> void:
	if not _is_showing or board_system == null:
		return

	# 转换屏幕坐标到棋盘坐标
	var hex_coord := board_system.pixel_to_hex(position)

	# 检查是否在有效范围内
	if board_system.is_valid_position(hex_coord.x, hex_coord.y):
		# 检查格子是否为空
		if board_system.is_cell_empty(hex_coord.x, hex_coord.y):
			highlight_cell(hex_coord.x, hex_coord.y)
		else:
			clear_highlight()
	else:
		clear_highlight()


func _on_drag_cancelled() -> void:
	hide_cells()


#endregion
