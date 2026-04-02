# InputManager.gd
# 输入管理器
# 捕获和处理鼠标/触摸输入，为拖放交互系统提供事件
# Autoload: InputManager (无需 class_name)
extends Node

# PRODUCTION CODE - V-Tacit Input System
# Implements: design/gdd/input-manager.md

## 信号：点击事件
signal clicked(position: Vector2, target: Node)

## 信号：拖动开始
signal drag_started(position: Vector2, target: Node)

## 信号：拖动移动
signal drag_moved(position: Vector2, delta: Vector2)

## 信号：拖动结束
signal drag_ended(position: Vector2)

## 信号：悬停进入
signal hover_entered(position: Vector2, target: Node)

## 信号：悬停离开
signal hover_exited(position: Vector2, target: Node)

## 信号：拖动取消
signal drag_cancelled()


## 输入状态枚举
enum InputState {
	IDLE,       ## 空闲
	PRESSED,    ## 按下（等待判定）
	DRAGGING,   ## 正在拖动
	HOVERING    ## 悬停
}

## 当前输入状态
var _state: InputState = InputState.IDLE

## 拖动判定距离（像素）
@export var drag_threshold: float = 10.0

## 点击判定时间（毫秒）
@export var click_time_threshold: float = 300.0

## 按下时的位置
var _press_position: Vector2 = Vector2.ZERO

## 按下时的时间
var _press_time: float = 0.0

## 当前悬停的目标
var _hover_target: Node = null

## 当前拖动目标
var _drag_target: Node = null

## 上一次鼠标位置
var _last_mouse_position: Vector2 = Vector2.ZERO

## 预分配的物理查询参数（避免每次点击分配）
var _point_query_params: PhysicsPointQueryParameters2D = null


#region 公共接口

## 获取当前输入状态
func get_state() -> InputState:
	return _state


## 是否正在拖动
func is_dragging() -> bool:
	return _state == InputState.DRAGGING


## 是否按下
func is_pressed() -> bool:
	return _state == InputState.PRESSED or _state == InputState.DRAGGING


## 获取当前鼠标/触摸位置
func get_pointer_position() -> Vector2:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return get_viewport().get_mouse_position()
	var touches := Input.get_connected_joypads()
	# 简化处理，返回鼠标位置
	return get_viewport().get_mouse_position()


## 取消当前操作
func cancel() -> void:
	if _state == InputState.DRAGGING:
		drag_cancelled.emit()
	_state = InputState.IDLE
	_drag_target = null


#endregion


#region 内部方法

func _ready() -> void:
	# 预分配物理查询参数，避免运行时内存分配
	_point_query_params = PhysicsPointQueryParameters2D.new()
	_point_query_params.collide_with_areas = true
	_point_query_params.collide_with_bodies = true


func _process(delta: float) -> void:
	match _state:
		InputState.PRESSED:
			_check_drag_threshold()
		InputState.HOVERING:
			_update_hover()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_press(event.position)
		else:
			_on_release(event.position)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _state == InputState.DRAGGING:
		var delta := event.position - _last_mouse_position
		drag_moved.emit(event.position, delta)
		_last_mouse_position = event.position
	elif _state == InputState.IDLE:
		_check_hover(event.position)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_on_press(event.position)
	else:
		_on_release(event.position)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if _state == InputState.DRAGGING:
		drag_moved.emit(event.position, event.relative)
		_last_mouse_position = event.position


func _on_press(position: Vector2) -> void:
	_press_position = position
	_press_time = Time.get_ticks_msec()
	_last_mouse_position = position
	_state = InputState.PRESSED

	# 检测点击的目标
	_drag_target = _get_target_at_position(position)


func _on_release(position: Vector2) -> void:
	var elapsed := Time.get_ticks_msec() - _press_time
	var distance := position.distance_to(_press_position)

	match _state:
		InputState.PRESSED:
			# 在判定范围内释放 = 点击
			if distance <= drag_threshold:
				clicked.emit(position, _drag_target)
		InputState.DRAGGING:
			# 拖动结束
			drag_ended.emit(position)

	_state = InputState.IDLE
	_drag_target = null


func _check_drag_threshold() -> void:
	var current_pos := get_pointer_position()
	var distance := current_pos.distance_to(_press_position)

	if distance > drag_threshold:
		_state = InputState.DRAGGING
		drag_started.emit(_press_position, _drag_target)
		_last_mouse_position = current_pos


func _check_hover(position: Vector2) -> void:
	var target := _get_target_at_position(position)

	if target != _hover_target:
		if _hover_target != null:
			hover_exited.emit(position, _hover_target)
		_hover_target = target
		if _hover_target != null:
			hover_entered.emit(position, _hover_target)
			_state = InputState.HOVERING
	else:
		_state = InputState.IDLE


func _update_hover() -> void:
	var position := get_pointer_position()
	var target := _get_target_at_position(position)

	if target != _hover_target:
		if _hover_target != null:
			hover_exited.emit(position, _hover_target)
		_hover_target = target
		if _hover_target != null:
			hover_entered.emit(position, _hover_target)
		else:
			_state = InputState.IDLE


func _get_target_at_position(position: Vector2) -> Node:
	# 获取位置下的最上层节点
	var viewport := get_viewport()

	# 使用预分配的查询参数，避免每次分配
	_point_query_params.position = position

	var space_state := viewport.get_world_2d().direct_space_state
	var results := space_state.intersect_point(_point_query_params)
	if results.size() > 0:
		return results[0].get("collider")

	return null


#endregion
