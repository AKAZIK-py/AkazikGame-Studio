# CardSlot.gd
# 商店卡牌槽位
# 显示单个角色卡牌，支持拖动
class_name CardSlot
extends Control

# PRODUCTION CODE - V-Tacit Shop UI

## 信号：点击卡牌
signal card_clicked(slot_index: int)

## 信号：开始拖动
signal drag_initiated(slot_index: int, character: CharacterData)

## 信号：悬停进入
signal hover_entered(slot_index: int)

## 信号：悬停离开
signal hover_exited(slot_index: int)


## 卡槽索引
@export var slot_index: int = 0

## 角色数据
var _character_data: CharacterData = null

## 是否为空
var _is_empty: bool = true

## 是否正在拖动
var _is_dragging: bool = false

## 拖动阈值（像素）
@export var drag_threshold: float = 10.0

## 按下位置
var _press_position: Vector2 = Vector2.ZERO

## 是否按下
var _is_pressed: bool = false

## 卡牌背景颜色（按稀有度）
var _tier_colors: Array[Color] = [
	Color(0.5, 0.5, 0.5),    # 1费 灰色
	Color(0.2, 0.6, 0.2),    # 2费 绿色
	Color(0.2, 0.4, 0.8),    # 3费 蓝色
	Color(0.6, 0.3, 0.8),    # 4费 紫色
	Color(0.9, 0.7, 0.1),    # 5费 金色
]


## 设置角色数据
func set_character(data: CharacterData) -> void:
	_character_data = data
	_is_empty = data == null
	queue_redraw()


## 清空卡槽
func clear() -> void:
	_character_data = null
	_is_empty = true
	queue_redraw()


## 获取角色数据
func get_character() -> CharacterData:
	return _character_data


## 是否为空
func is_empty() -> bool:
	return _is_empty


func _ready() -> void:
	custom_minimum_size = Vector2(100, 140)
	# 确保可以接收输入
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# 确保 rect 有有效大小
	if rect.size.x <= 0 or rect.size.y <= 0:
		rect.size = custom_minimum_size

	if _is_empty or _character_data == null:
		# 空槽位
		draw_rect(rect, Color(0.2, 0.2, 0.25, 0.8))
		draw_rect(rect, Color(0.4, 0.4, 0.45), false, 2.0)
		return

	# 背景（按稀有度）
	var bg_color := _tier_colors[mini(_character_data.rarity - 1, _tier_colors.size() - 1)]
	draw_rect(rect, bg_color)

	# 边框
	var border_color := Color(0.8, 0.8, 0.8)
	if _is_dragging:
		border_color = Color(1.0, 0.8, 0.2)
	draw_rect(rect, border_color, false, 2.0)

	# 角色名称
	var name_pos := Vector2(10, rect.size.y - 40)
	draw_string(ThemeDB.fallback_font, name_pos, _character_data.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	# 星级
	var stars := _character_data.get_rarity_stars()
	var stars_pos := Vector2(10, rect.size.y - 20)
	draw_string(ThemeDB.fallback_font, stars_pos, stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.YELLOW)

	# 费用
	var cost_text := str(_character_data.rarity)
	var cost_pos := Vector2(rect.size.x - 25, 20)
	draw_string(ThemeDB.fallback_font, cost_pos, cost_text, HORIZONTAL_ALIGNMENT_RIGHT, -1, 16, Color.WHITE)

	# 定位
	var role_name := _character_data.get_role_name()
	var role_pos := Vector2(10, 25)
	draw_string(ThemeDB.fallback_font, role_pos, role_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.7, 0.7))

	# 羁绊标签
	var tags_text := ", ".join(_character_data.synergy_tags)
	var tags_pos := Vector2(10, 45)
	draw_string(ThemeDB.fallback_font, tags_pos, tags_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.8, 0.6))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press(event.position)
			else:
				_on_release(event.position)


func _on_press(_pos: Vector2) -> void:
	if _is_empty:
		return

	_is_pressed = true
	_press_position = _pos


func _on_release(_pos: Vector2) -> void:
	if not _is_pressed:
		return

	var distance := _pos.distance_to(_press_position)

	if distance <= drag_threshold:
		# 点击
		card_clicked.emit(slot_index)

	_is_pressed = false


func _process(_delta: float) -> void:
	if _is_pressed and not _is_empty:
		var current_pos := get_local_mouse_position()
		var distance := current_pos.distance_to(_press_position)

		if distance > drag_threshold:
			# 开始拖动
			_is_pressed = false
			_is_dragging = true
			drag_initiated.emit(slot_index, _character_data)
			queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if not _is_empty:
			hover_entered.emit(slot_index)
	elif what == NOTIFICATION_MOUSE_EXIT:
		if not _is_empty:
			hover_exited.emit(slot_index)
		_is_pressed = false


## 设置拖动状态
func set_dragging(dragging: bool) -> void:
	_is_dragging = dragging
	queue_redraw()
