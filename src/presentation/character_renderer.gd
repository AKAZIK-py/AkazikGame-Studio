# CharacterRenderer.gd
# 角色渲染器
# 在棋盘上渲染已放置的角色棋子
class_name CharacterRenderer
extends Node2D

# PRODUCTION CODE - V-Tacit Character Rendering System
# Implements: design/gdd/character-rendering.md

## 信号：点击棋盘上的角色
signal character_clicked(instance: CharacterInstance, q: int, r: int)

## 信号：开始拖动棋盘上的角色
signal character_drag_initiated(instance: CharacterInstance, q: int, r: int)


## 棋盘系统引用
@export var board_system: BoardSystem

## 羁绊效果系统引用（用于显示加成）
@export var synergy_effect: SynergyEffectSystem

## 拖放控制器引用
@export var drag_controller: DragDropController

## 稀有度颜色
const TIER_COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),    # 1费 灰色
	Color(0.3, 0.7, 0.3),    # 2费 绿色
	Color(0.3, 0.5, 0.9),    # 3费 蓝色
	Color(0.7, 0.4, 0.9),    # 4费 紫色
	Color(0.95, 0.8, 0.2),   # 5费 金色
]

## 拖动预览数据
var _preview_character: CharacterData = null
var _preview_q: int = -1
var _preview_r: int = -1
var _preview_visible: bool = false

## 拖动时的鼠标位置
var _drag_mouse_pos: Vector2 = Vector2.ZERO

## 正在拖动的角色实例（用于跟随鼠标渲染）
var _dragging_instance: CharacterInstance = null

## 拖动状态
var _is_dragging_board: bool = false
var _drag_start_pos: Vector2 = Vector2.ZERO
var _dragging_cell: Vector2i = Vector2i(-1, -1)
var _drag_threshold: float = 10.0


func _ready() -> void:
	# 延迟初始化
	call_deferred("_delayed_init")


func _delayed_init() -> void:
	# 连接GameState信号
	if GameState:
		if not GameState.character_placed.is_connected(_on_character_placed):
			GameState.character_placed.connect(_on_character_placed)
		if not GameState.character_removed.is_connected(_on_character_removed):
			GameState.character_removed.connect(_on_character_removed)
		if not GameState.board_cleared.is_connected(_on_board_cleared):
			GameState.board_cleared.connect(_on_board_cleared)
		if not GameState.enemy_board_changed.is_connected(_on_enemy_board_changed):
			GameState.enemy_board_changed.connect(_on_enemy_board_changed)

	print("CharacterRenderer: Initialized")


func _draw() -> void:
	if board_system == null:
		return

	# 绘制所有已放置的玩家角色
	var characters := board_system.get_all_characters()
	for instance in characters:
		# 跳过正在被拖动的棋子
		if drag_controller and drag_controller.is_dragging():
			if drag_controller.get_drag_source() == "board":
				var source_cell := drag_controller.get_source_cell()
				if instance.position.x == source_cell.x and instance.position.y == source_cell.y:
					# 记录正在拖动的实例
					_dragging_instance = instance
					continue  # 不绘制原位置的棋子

		_draw_character(instance, false)

	# 绘制敌方角色（战斗时）
	var enemies := GameState.get_enemy_characters()
	for instance in enemies:
		_draw_character(instance, true)

	# 绘制拖动预览（在目标格子位置）
	if _preview_visible and _preview_character != null and _preview_q >= 0 and _preview_r >= 0:
		_draw_preview_character(_preview_character, _preview_q, _preview_r)

	# 绘制跟随鼠标的拖动角色
	if drag_controller and drag_controller.is_dragging() and _dragging_instance != null:
		_draw_dragging_character(_dragging_instance, _drag_mouse_pos)


func _draw_character(instance: CharacterInstance, is_enemy: bool = false) -> void:
	var char_data := instance.get_character_data()
	if char_data == null:
		return

	var pos := instance.position
	var center := board_system.hex_to_pixel(pos.x, pos.y)
	var hex_size := board_system.hex_size

	# 绘制六边形背景
	var bg_color := TIER_COLORS[char_data.rarity - 1]
	var corners := board_system.get_hex_corners(pos.x, pos.y)
	var points := PackedVector2Array(corners)
	draw_colored_polygon(points, bg_color)

	# 绘制边框（敌方红色，我方绿色）
	var border_color: Color
	if is_enemy:
		border_color = Color(1.0, 0.4, 0.4)  # 敌方红色边框
	else:
		border_color = Color(0.4, 1.0, 0.4)  # 我方绿色边框

	for i in range(6):
		draw_line(corners[i], corners[(i + 1) % 6], border_color, 2.5)

	# 绘制星级（如果大于1）
	if instance.star_level > 1:
		var star_text := "★".repeat(instance.star_level)
		var star_pos := center + Vector2(0, -hex_size * 0.55)
		draw_string(ThemeDB.fallback_font, star_pos, star_text,
			HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 10, Color(1.0, 0.85, 0.2))

	# 绘制角色名字（居中显示）
	var name_pos := center + Vector2(0, -hex_size * 0.3)
	draw_string(ThemeDB.fallback_font, name_pos, char_data.display_name,
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 12, Color.WHITE)

	# 绘制定位
	var role_pos := center + Vector2(0, hex_size * 0.1)
	draw_string(ThemeDB.fallback_font, role_pos, char_data.get_role_name(),
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 10, Color(0.8, 0.8, 0.8))

	# 绘制攻击力和生命值
	var stats_pos := center + Vector2(0, hex_size * 0.45)
	var stats_text := "ATK:%d HP:%d" % [instance.current_attack, instance.max_health]
	draw_string(ThemeDB.fallback_font, stats_pos, stats_text,
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 9, Color.YELLOW)


func _draw_preview_character(character: CharacterData, q: int, r: int) -> void:
	var center := board_system.hex_to_pixel(q, r)
	var hex_size := board_system.hex_size

	# 绘制半透明六边形
	var bg_color := TIER_COLORS[character.rarity - 1]
	bg_color.a = 0.5
	var corners := board_system.get_hex_corners(q, r)
	var points := PackedVector2Array(corners)
	draw_colored_polygon(points, bg_color)

	# 绘制边框
	for i in range(6):
		draw_line(corners[i], corners[(i + 1) % 6], Color(1.0, 1.0, 0.4, 0.8), 3.0)

	# 绘制名字
	var name_pos := center + Vector2(0, -hex_size * 0.3)
	draw_string(ThemeDB.fallback_font, name_pos, character.display_name,
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 12, Color(1.0, 1.0, 1.0, 0.8))

	# 绘制定位
	var role_pos := center + Vector2(0, hex_size * 0.1)
	draw_string(ThemeDB.fallback_font, role_pos, character.get_role_name(),
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 10, Color(0.8, 0.8, 0.8, 0.8))


## 绘制跟随鼠标的拖动角色
func _draw_dragging_character(instance: CharacterInstance, mouse_pos: Vector2) -> void:
	var char_data := instance.get_character_data()
	if char_data == null:
		return

	var hex_size := board_system.hex_size
	var center := mouse_pos

	# 绘制半透明六边形背景
	var bg_color := TIER_COLORS[char_data.rarity - 1]
	bg_color.a = 0.7

	var corners: Array[Vector2] = []
	for i in range(6):
		var angle: float = PI / 6.0 + PI / 3.0 * i
		corners.append(center + Vector2(cos(angle), sin(angle)) * hex_size)

	var points := PackedVector2Array(corners)
	draw_colored_polygon(points, bg_color)

	# 绘制边框
	for i in range(6):
		draw_line(corners[i], corners[(i + 1) % 6], Color(1.0, 1.0, 0.5), 3.0)

	# 绘制角色名字
	var name_pos := center + Vector2(0, -hex_size * 0.3)
	draw_string(ThemeDB.fallback_font, name_pos, char_data.display_name,
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 12, Color.WHITE)

	# 绘制定位
	var role_pos := center + Vector2(0, hex_size * 0.1)
	draw_string(ThemeDB.fallback_font, role_pos, char_data.get_role_name(),
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 10, Color(0.8, 0.8, 0.8))

	# 绘制攻击力和生命值
	var stats_pos := center + Vector2(0, hex_size * 0.45)
	var stats_text := "ATK:%d HP:%d" % [instance.current_attack, instance.max_health]
	draw_string(ThemeDB.fallback_font, stats_pos, stats_text,
		HORIZONTAL_ALIGNMENT_CENTER, hex_size * 1.5, 9, Color.YELLOW)


## 设置拖动预览
func set_drag_preview(character: CharacterData, q: int, r: int, visible: bool) -> void:
	_preview_character = character
	_preview_q = q
	_preview_r = r
	_preview_visible = visible
	queue_redraw()


## 请求重绘
func request_redraw() -> void:
	queue_redraw()


#region 输入处理

func _input(event: InputEvent) -> void:
	if board_system == null:
		return

	# 只在商店阶段处理棋盘输入
	if GameState and GameState.current_phase != GameState.Phase.SHOP:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_global_mouse_position()
			var hex := board_system.pixel_to_hex(mouse_pos)

			if event.pressed:
				# 检查是否点击了棋子
				if board_system.is_valid_position(hex.x, hex.y):
					var instance := board_system.get_character_at(hex.x, hex.y)
					if instance != null and board_system.is_player_zone(hex.x, hex.y):
						_is_dragging_board = true
						_drag_start_pos = mouse_pos
						_dragging_cell = hex
			else:
				# 鼠标释放
				if _is_dragging_board:
					# 检查是点击还是拖动
					var distance := mouse_pos.distance_to(_drag_start_pos)
					if distance <= _drag_threshold:
						# 点击 - 发射点击信号
						var instance := board_system.get_character_at(_dragging_cell.x, _dragging_cell.y)
						if instance != null:
							character_clicked.emit(instance, _dragging_cell.x, _dragging_cell.y)

				_is_dragging_board = false
				_dragging_cell = Vector2i(-1, -1)


func _process(_delta: float) -> void:
	# 更新拖动时的鼠标位置
	if drag_controller and drag_controller.is_dragging():
		_drag_mouse_pos = get_global_mouse_position()
		queue_redraw()  # 持续重绘以跟随鼠标
	else:
		# 拖动结束，清除拖动实例
		if _dragging_instance != null:
			_dragging_instance = null
			queue_redraw()

	if not _is_dragging_board or board_system == null or drag_controller == null:
		return

	var mouse_pos := get_global_mouse_position()
	var distance := mouse_pos.distance_to(_drag_start_pos)

	# 超过阈值，开始拖动
	if distance > _drag_threshold:
		var instance := board_system.get_character_at(_dragging_cell.x, _dragging_cell.y)
		if instance != null:
			# 开始从棋盘拖动
			_is_dragging_board = false
			_dragging_instance = instance
			character_drag_initiated.emit(instance, _dragging_cell.x, _dragging_cell.y)
			drag_controller.start_drag_from_board_instance(instance, _dragging_cell)


#endregion


#region 信号处理

func _on_character_placed(_instance: CharacterInstance, _q: int, _r: int) -> void:
	queue_redraw()


func _on_character_removed(_instance: CharacterInstance, _q: int, _r: int) -> void:
	queue_redraw()


func _on_board_cleared() -> void:
	queue_redraw()


func _on_enemy_board_changed() -> void:
	queue_redraw()


#endregion
