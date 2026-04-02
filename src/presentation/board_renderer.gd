# BoardRenderer.gd
# 棋盘渲染器
# 渲染六边形棋盘背景和格子轮廓
class_name BoardRenderer
extends Node2D

# PRODUCTION CODE - V-Tacit Board Rendering System
# Implements: design/gdd/board-rendering.md

## 棋盘系统引用
@export var board_system: BoardSystem

## 格子边框颜色
@export var cell_border_color: Color = Color(1, 1, 1, 0.3)

## 格子填充颜色（空格子）
@export var cell_fill_color: Color = Color(0.5, 0.5, 0.5, 0.1)

## 棋盘背景颜色
@export var board_bg_color: Color = Color(0.1, 0.1, 0.15, 0.8)

## 敌方区域背景颜色
@export var enemy_zone_color: Color = Color(0.4, 0.15, 0.15, 0.3)

## 我方区域背景颜色
@export var player_zone_color: Color = Color(0.15, 0.3, 0.15, 0.3)

## 分界线颜色
@export var divider_color: Color = Color(1.0, 0.8, 0.2, 0.6)

## 是否显示格子（由CellDisplaySystem控制）
var show_cells: bool = false:
	set(value):
		if show_cells != value:
			show_cells = value
			queue_redraw()


func _ready() -> void:
	# 延迟初始化，确保 board_system 已被设置
	call_deferred("_delayed_init")


func _delayed_init() -> void:
	if board_system == null:
		# 尝试从场景树获取
		board_system = get_node_or_null("../BoardSystem")
		if board_system == null:
			# 尝试从父节点获取
			var parent := get_parent()
			if parent and parent.has_node("BoardSystem"):
				board_system = parent.get_node("BoardSystem")

	if board_system:
		print("BoardRenderer: board_system connected successfully")
		# 连接信号
		if not board_system.cell_changed.is_connected(_on_cell_changed):
			board_system.cell_changed.connect(_on_cell_changed)
	else:
		push_error("BoardRenderer: board_system is null! Board will not render correctly.")

	queue_redraw()


func _on_cell_changed(_q: int, _r: int) -> void:
	queue_redraw()


func _draw() -> void:
	if board_system == null:
		# 显示占位符提示
		var viewport := get_viewport()
		var center := Vector2(640, 300)
		if viewport:
			center = viewport.get_visible_rect().size / 2.0
		draw_string(ThemeDB.fallback_font, center - Vector2(100, 0), "棋盘加载中...", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.RED)
		return

	# 绘制棋盘背景
	_draw_board_background()

	# 绘制区域颜色
	_draw_zone_backgrounds()

	# 绘制分界线
	_draw_divider_line()

	# 如果需要显示格子，绘制格子
	if show_cells:
		_draw_all_cells()


func _draw_board_background() -> void:
	# 计算棋盘边界
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)

	for r in range(board_system.board_rows):
		for q in range(board_system.board_cols):
			var pos := board_system.hex_to_pixel(q, r)
			min_pos.x = minf(min_pos.x, pos.x)
			min_pos.y = minf(min_pos.y, pos.y)
			max_pos.x = maxf(max_pos.x, pos.x)
			max_pos.y = maxf(max_pos.y, pos.y)

	# 扩展边界以包含六边形的边缘（pointy-top）
	var padding := board_system.hex_size * 1.2
	min_pos -= Vector2(padding, padding)
	max_pos += Vector2(padding, padding)

	# 绘制圆角矩形背景
	var rect := Rect2(min_pos, max_pos - min_pos)
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = board_bg_color
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	style_box.border_color = Color(0.3, 0.3, 0.35, 0.5)
	style_box.set_border_width_all(2)

	draw_style_box(style_box, rect)


func _draw_zone_backgrounds() -> void:
	# 绘制敌方区域（上4行）
	var enemy_min := Vector2(INF, INF)
	var enemy_max := Vector2(-INF, -INF)
	for r in range(0, BoardSystem.PLAYER_ZONE_START):
		for q in range(board_system.board_cols):
			var pos := board_system.hex_to_pixel(q, r)
			enemy_min.x = minf(enemy_min.x, pos.x)
			enemy_min.y = minf(enemy_min.y, pos.y)
			enemy_max.x = maxf(enemy_max.x, pos.x)
			enemy_max.y = maxf(enemy_max.y, pos.y)

	var padding := board_system.hex_size * 0.8
	enemy_min -= Vector2(padding, padding)
	enemy_max += Vector2(padding, padding)

	var enemy_rect := Rect2(enemy_min, enemy_max - enemy_min)
	draw_rect(enemy_rect, enemy_zone_color)

	# 绘制我方区域（下4行）
	var player_min := Vector2(INF, INF)
	var player_max := Vector2(-INF, -INF)
	for r in range(BoardSystem.PLAYER_ZONE_START, board_system.board_rows):
		for q in range(board_system.board_cols):
			var pos := board_system.hex_to_pixel(q, r)
			player_min.x = minf(player_min.x, pos.x)
			player_min.y = minf(player_min.y, pos.y)
			player_max.x = maxf(player_max.x, pos.x)
			player_max.y = maxf(player_max.y, pos.y)

	player_min -= Vector2(padding, padding)
	player_max += Vector2(padding, padding)

	var player_rect := Rect2(player_min, player_max - player_min)
	draw_rect(player_rect, player_zone_color)


func _draw_divider_line() -> void:
	# 绘制敌我分界线（在第3行和第4行之间）
	var left_pos := board_system.hex_to_pixel(0, BoardSystem.PLAYER_ZONE_START - 1)
	var right_pos := board_system.hex_to_pixel(board_system.board_cols - 1, BoardSystem.PLAYER_ZONE_START - 1)

	# 计算分界线Y位置（在两行中间）
	var hex_size := board_system.hex_size
	var divider_y := (left_pos.y + board_system.hex_to_pixel(0, BoardSystem.PLAYER_ZONE_START).y) / 2.0

	# 绘制虚线
	var start_x := left_pos.x - hex_size
	var end_x := right_pos.x + hex_size
	var dash_length := 10.0
	var gap_length := 5.0
	var current_x := start_x

	while current_x < end_x:
		var dash_end := minf(current_x + dash_length, end_x)
		draw_line(Vector2(current_x, divider_y), Vector2(dash_end, divider_y), divider_color, 3.0)
		current_x += dash_length + gap_length

	# 绘制"敌方"和"我方"标签
	var enemy_label_pos := Vector2(left_pos.x - hex_size, divider_y - hex_size * 2)
	draw_string(ThemeDB.fallback_font, enemy_label_pos, "敌方区域",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.5, 0.5))

	var player_label_pos := Vector2(left_pos.x - hex_size, divider_y + hex_size * 2)
	draw_string(ThemeDB.fallback_font, player_label_pos, "我方区域",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 1.0, 0.5))


func _draw_all_cells() -> void:
	for r in range(board_system.board_rows):
		for q in range(board_system.board_cols):
			# 我方区域用高亮显示可放置区域
			if board_system.is_player_zone(q, r):
				_draw_hex_cell(q, r, Color(0.5, 1.0, 0.5, 0.4), Color(0.3, 0.5, 0.3, 0.15))
			else:
				_draw_hex_cell(q, r, cell_border_color, cell_fill_color)


func _draw_hex_cell(q: int, r: int, border_color: Color, fill_color: Color) -> void:
	var center := board_system.hex_to_pixel(q, r)
	var corners := board_system.get_hex_corners(q, r)

	# 绘制填充
	var points := PackedVector2Array(corners)
	draw_colored_polygon(points, fill_color)

	# 绘制边框
	for i in range(6):
		var from := corners[i]
		var to := corners[(i + 1) % 6]
		draw_line(from, to, border_color, 2.0)


## 绘制高亮格子
func draw_highlighted_cell(q: int, r: int, highlight_color: Color) -> void:
	var center := board_system.hex_to_pixel(q, r)
	var corners := board_system.get_hex_corners(q, r)

	# 绘制填充
	var points := PackedVector2Array(corners)
	draw_colored_polygon(points, highlight_color)

	# 绘制加粗边框
	for i in range(6):
		var from := corners[i]
		var to := corners[(i + 1) % 6]
		draw_line(from, to, highlight_color, 3.0)


## 请求重绘
func request_redraw() -> void:
	queue_redraw()
