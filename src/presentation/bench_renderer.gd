# BenchRenderer.gd
# 观战席渲染器
# 渲染观战席上的角色
class_name BenchRenderer
extends Node2D

# PRODUCTION CODE - V-Tacit Bench Rendering System

## 信号：点击观战席角色
signal character_clicked(instance: CharacterInstance, slot: int)

## 信号：开始拖动观战席角色
signal character_drag_initiated(instance: CharacterInstance, slot: int)


## 棋盘系统引用
@export var board_system: BoardSystem

## 拖放控制器引用
@export var drag_controller: DragDropController

## 槽位大小（缩小以避免重叠）
@export var slot_size: Vector2 = Vector2(50, 60)

## 槽位间距
@export var slot_spacing: float = 5.0

## 起始位置（屏幕坐标）
@export var bench_position: Vector2 = Vector2(200, 500)

## 稀有度颜色
const TIER_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),    # 1费 灰色
	Color(0.3, 0.7, 0.3),    # 2费 绿色
	Color(0.3, 0.5, 0.9),    # 3费 蓝色
	Color(0.7, 0.4, 0.9),    # 4费 紫色
	Color(0.95, 0.8, 0.2),   # 5费 金色
]

## 拖动状态
var _is_dragging: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _dragging_slot: int = -1
var _drag_threshold: float = 10.0


func _ready() -> void:
	if GameState:
		GameState.bench_changed.connect(queue_redraw)

	# 自动计算位置
	call_deferred("_update_bench_position")


func _update_bench_position() -> void:
	var viewport := get_viewport()
	if viewport:
		var viewport_size := viewport.get_visible_rect().size
		var total_width := GameState.BENCH_MAX_SIZE * (slot_size.x + slot_spacing) - slot_spacing
		# X位置：屏幕中央偏左，避开羁绊面板
		var bench_x := 170.0  # 羁绊面板宽度 + 间距
		# Y位置：商店面板正上方
		var bench_y := viewport_size.y - 140 - slot_size.y - 10
		bench_position = Vector2(bench_x, bench_y)
		queue_redraw()


func _draw() -> void:
	# 绘制观战席背景
	var total_width := GameState.BENCH_MAX_SIZE * (slot_size.x + slot_spacing) - slot_spacing
	var bg_rect := Rect2(bench_position - Vector2(10, 10), Vector2(total_width + 20, slot_size.y + 20))
	draw_rect(bg_rect, Color(0.15, 0.15, 0.2, 0.8), true, 5.0)

	# 绘制标题
	var title_pos := bench_position + Vector2(0, -15)
	draw_string(ThemeDB.fallback_font, title_pos, "观战席", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))

	# 绘制每个槽位
	for i in range(GameState.BENCH_MAX_SIZE):
		var slot_pos := _get_slot_position(i)

		# 绘制槽位背景
		var slot_rect := Rect2(slot_pos, slot_size)
		draw_rect(slot_rect, Color(0.2, 0.2, 0.25, 0.5), true)
		draw_rect(slot_rect, Color(0.4, 0.4, 0.45), false, 1.5)

		# 绘制角色
		var instance := GameState.get_bench_character_at(i)
		if instance != null:
			# 跳过正在被拖动的
			if drag_controller and drag_controller.is_dragging() and drag_controller.get_drag_source() == "bench":
				if drag_controller.get_source_bench_slot() == i:
					continue

			_draw_character_in_slot(instance, slot_pos)


func _draw_character_in_slot(instance: CharacterInstance, slot_pos: Vector2) -> void:
	var char_data := instance.get_character_data()
	if char_data == null:
		return

	# 背景（按稀有度）
	var bg_color := TIER_COLORS[char_data.rarity - 1]
	var bg_rect := Rect2(slot_pos + Vector2(1, 1), slot_size - Vector2(2, 2))
	draw_rect(bg_rect, bg_color, true)

	# 边框
	draw_rect(bg_rect, Color(0.6, 0.6, 0.6), false, 1.0)

	# 角色名字（缩小字体）
	var name_pos := slot_pos + Vector2(3, slot_size.y - 22)
	draw_string(ThemeDB.fallback_font, name_pos, char_data.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# 星级
	var stars := char_data.get_rarity_stars()
	var stars_pos := slot_pos + Vector2(3, slot_size.y - 10)
	draw_string(ThemeDB.fallback_font, stars_pos, stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.YELLOW)


func _get_slot_position(slot: int) -> Vector2:
	return bench_position + Vector2(slot * (slot_size.x + slot_spacing), 0)


func _get_slot_at_position(pos: Vector2) -> int:
	for i in range(GameState.BENCH_MAX_SIZE):
		var slot_pos := _get_slot_position(i)
		var slot_rect := Rect2(slot_pos, slot_size)
		if slot_rect.has_point(pos):
			return i
	return -1


func _input(event: InputEvent) -> void:
	# 只在商店阶段处理
	if GameState and GameState.current_phase != GameState.Phase.SHOP:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_global_mouse_position()
			var slot := _get_slot_at_position(mouse_pos)

			if event.pressed:
				if slot >= 0:
					var instance := GameState.get_bench_character_at(slot)
					if instance != null:
						_is_dragging = true
						_drag_start_pos = mouse_pos
						_dragging_slot = slot
			else:
				if _is_dragging and _dragging_slot >= 0:
					var distance := mouse_pos.distance_to(_drag_start_pos)
					if distance <= _drag_threshold:
						# 点击
						var instance := GameState.get_bench_character_at(_dragging_slot)
						if instance != null:
							character_clicked.emit(instance, _dragging_slot)

				_is_dragging = false
				_dragging_slot = -1


func _process(_delta: float) -> void:
	if not _is_dragging or drag_controller == null:
		return

	var mouse_pos := get_global_mouse_position()
	var distance := mouse_pos.distance_to(_drag_start_pos)

	if distance > _drag_threshold:
		var instance := GameState.get_bench_character_at(_dragging_slot)
		if instance != null:
			_is_dragging = false
			character_drag_initiated.emit(instance, _dragging_slot)
			drag_controller.start_drag_from_bench(instance, _dragging_slot)


## 请求重绘
func request_redraw() -> void:
	queue_redraw()
