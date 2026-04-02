# BoardSystem.gd
# 六边形棋盘系统
# 管理棋盘位置逻辑：放置/移除/移动角色、坐标验证、相邻格计算
class_name BoardSystem
extends Node

# PRODUCTION CODE - V-Tacit Board System
# Implements: design/gdd/board-system.md

## 信号：格子状态改变
signal cell_changed(q: int, r: int)

## 信号：角色放置成功
signal character_placed(instance: CharacterInstance, q: int, r: int)

## 信号：角色移除成功
signal character_removed(instance: CharacterInstance, q: int, r: int)

## 信号：角色移动成功
signal character_moved(instance: CharacterInstance, from: Vector2i, to: Vector2i)


## 六边形的6个方向偏移（odd-q offset coordinates）
## 偶数行的邻居偏移
const HEX_DIRECTIONS_EVEN: Array[Vector2i] = [
	Vector2i(1, 0),   # 右
	Vector2i(0, -1),  # 右上
	Vector2i(-1, -1), # 左上
	Vector2i(-1, 0),  # 左
	Vector2i(-1, 1),  # 左下
	Vector2i(0, 1),   # 右下
]

## 奇数行的邻居偏移
const HEX_DIRECTIONS_ODD: Array[Vector2i] = [
	Vector2i(1, 0),   # 右
	Vector2i(1, -1),  # 右上
	Vector2i(0, -1),  # 左上
	Vector2i(-1, 0),  # 左
	Vector2i(0, 1),   # 左下
	Vector2i(1, 1),   # 右下
]

## 棋盘行数（上下分区：上4行敌方，下4行我方）
@export var board_rows: int = 8

## 棋盘列数
@export var board_cols: int = 7

## 我方区域起始行（下4行）
const PLAYER_ZONE_START: int = 4

## 六边形格子大小（像素）- 内接圆半径
@export var hex_size: float = 60.0

## 棋盘中心位置（屏幕坐标）- 可以在运行时设置
@export var board_center: Vector2 = Vector2(800, 340)

## 是否自动计算棋盘中心（基于视口大小）
@export var auto_center: bool = true


func _ready() -> void:
	if auto_center:
		# 延迟一帧，等待视口初始化
		call_deferred("_update_board_center")


func _update_board_center() -> void:
	var viewport := get_viewport()
	if viewport:
		var viewport_size := viewport.get_visible_rect().size
		board_center = Vector2(viewport_size.x / 2.0, viewport_size.y * 0.40)


#region 公共接口

## 检查位置是否有效（在棋盘范围内）
func is_valid_position(q: int, r: int) -> bool:
	return q >= 0 and q < board_cols and r >= 0 and r < board_rows


## 检查位置是否在我方区域
func is_player_zone(q: int, r: int) -> bool:
	return r >= PLAYER_ZONE_START and r < board_rows


## 检查位置是否在敌方区域
func is_enemy_zone(q: int, r: int) -> bool:
	return r >= 0 and r < PLAYER_ZONE_START


## 我方是否可以在该位置放置角色
func can_player_place(q: int, r: int) -> bool:
	return is_valid_position(q, r) and is_player_zone(q, r) and is_cell_empty(q, r)


## 检查格子是否为空
func is_cell_empty(q: int, r: int) -> bool:
	if not is_valid_position(q, r):
		return false
	return not GameState.has_character_at(q, r)


## 获取格子上的角色
func get_character_at(q: int, r: int) -> CharacterInstance:
	if not is_valid_position(q, r):
		return null
	return GameState.get_character_at(q, r)


## 放置角色到格子
func place_character(data: CharacterData, q: int, r: int) -> CharacterInstance:
	if not is_valid_position(q, r):
		push_warning("BoardSystem: Invalid position (%d, %d)" % [q, r])
		return null

	if not is_cell_empty(q, r):
		push_warning("BoardSystem: Cell (%d, %d) is not empty" % [q, r])
		return null

	var instance := GameState.place_character(data, q, r)
	character_placed.emit(instance, q, r)
	cell_changed.emit(q, r)
	return instance


## 移除角色
func remove_character(q: int, r: int) -> CharacterInstance:
	if not is_valid_position(q, r):
		return null

	var instance := GameState.remove_character(q, r)
	if instance != null:
		character_removed.emit(instance, q, r)
		cell_changed.emit(q, r)
	return instance


## 移除指定位置的角色（别名）
func remove_character_at(q: int, r: int) -> CharacterInstance:
	return remove_character(q, r)


## 移动角色
func move_character(from_q: int, from_r: int, to_q: int, to_r: int) -> bool:
	if not is_valid_position(from_q, from_r):
		return false
	if not is_valid_position(to_q, to_r):
		return false

	var instance := get_character_at(from_q, from_r)
	if instance == null:
		return false

	# 使用GameState的移动方法
	var success := GameState.move_character(from_q, from_r, to_q, to_r)
	if success:
		character_moved.emit(instance, Vector2i(from_q, from_r), Vector2i(to_q, to_r))
		cell_changed.emit(from_q, from_r)
		cell_changed.emit(to_q, to_r)
	return success


## 获取相邻格子（6个方向，根据奇偶行使用不同的方向偏移）
func get_neighbors(q: int, r: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = HEX_DIRECTIONS_EVEN if r % 2 == 0 else HEX_DIRECTIONS_ODD

	for dir in directions:
		var nq := q + dir.x
		var nr := r + dir.y
		if is_valid_position(nq, nr):
			neighbors.append(Vector2i(nq, nr))
	return neighbors


## 获取所有已放置的角色
func get_all_characters() -> Array[CharacterInstance]:
	return GameState.get_board_characters()


## 获取棋盘上的角色数量
func get_character_count() -> int:
	return GameState.get_board_count()


## 获取所有空格子
func get_empty_cells() -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	for r in range(board_rows):
		for q in range(board_cols):
			if is_cell_empty(q, r):
				empty.append(Vector2i(q, r))
	return empty


## 清空棋盘
func clear_board() -> void:
	GameState.clear_board()
	# 发射所有格子的改变信号
	for r in range(board_rows):
		for q in range(board_cols):
			cell_changed.emit(q, r)


## 获取所有格子位置
func get_all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for r in range(board_rows):
		for q in range(board_cols):
			cells.append(Vector2i(q, r))
	return cells


#endregion


#region 坐标转换

## 棋盘坐标转屏幕坐标（pointy-top，中心构图）
## 奇数行向右偏移半个格子，形成蜂窝效果
func hex_to_pixel(q: int, r: int) -> Vector2:
	# pointy-top 六边形坐标转换
	var x: float = hex_size * sqrt(3.0) * (q + 0.5 * (r % 2))
	var y: float = hex_size * 1.5 * r

	# 计算棋盘总大小
	var total_width := hex_size * sqrt(3.0) * (board_cols + 0.5)
	var total_height := hex_size * 1.5 * (board_rows - 1) + hex_size * 2.0

	# 从棋盘中心偏移
	var board_origin := board_center - Vector2(total_width / 2.0, total_height / 2.0)
	return board_origin + Vector2(x + hex_size * sqrt(3.0) / 2.0, y + hex_size)


## 屏幕坐标转棋盘坐标（pointy-top）
func pixel_to_hex(pixel: Vector2) -> Vector2i:
	# 计算棋盘原点
	var total_width := hex_size * sqrt(3.0) * (board_cols + 0.5)
	var total_height := hex_size * 1.5 * (board_rows - 1) + hex_size * 2.0
	var board_origin := board_center - Vector2(total_width / 2.0, total_height / 2.0)

	# 转换到棋盘局部坐标
	var local := pixel - board_origin - Vector2(hex_size * sqrt(3.0) / 2.0, hex_size)

	# 计算行列（考虑奇数行偏移）
	var approx_r := local.y / (hex_size * 1.5)
	var approx_q := (local.x / (hex_size * sqrt(3.0))) - 0.5 * (int(round(approx_r)) % 2)

	var r := roundi(approx_r)
	var q := roundi(approx_q)

	# 验证并修正（处理六边形边缘情况）
	var best_cell := Vector2i(q, r)
	var best_dist := INF

	# 检查当前格子和相邻格子，找到最近的
	for check_r in range(maxi(0, r - 1), mini(board_rows, r + 2)):
		for check_q in range(maxi(0, q - 1), mini(board_cols, q + 2)):
			var center := hex_to_pixel(check_q, check_r)
			var dist := pixel.distance_to(center)
			if dist < best_dist:
				best_dist = dist
				best_cell = Vector2i(check_q, check_r)

	return best_cell


## 六边形坐标取整（从浮点坐标）
func hex_round(q: float, r: float) -> Vector2i:
	var s: float = -q - r

	var rq: int = roundi(q)
	var rr: int = roundi(r)
	var rs: int = roundi(s)

	var q_diff: float = absf(rq - q)
	var r_diff: float = absf(rr - r)
	var s_diff: float = absf(rs - s)

	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs

	return Vector2i(rq, rr)


## 获取格子的屏幕边界（用于渲染）- pointy-top 尖顶六边形
func get_hex_corners(q: int, r: int) -> Array[Vector2]:
	var center := hex_to_pixel(q, r)
	var corners: Array[Vector2] = []
	for i in range(6):
		# pointy-top: 从顶部开始，每个角间隔60度
		var angle: float = PI / 6.0 + PI / 3.0 * i
		corners.append(center + Vector2(cos(angle), sin(angle)) * hex_size)
	return corners


## 检查屏幕坐标是否在某个格子内
func is_point_in_hex(pixel: Vector2, q: int, r: int) -> bool:
	var hex_coord := pixel_to_hex(pixel)
	return hex_coord.x == q and hex_coord.y == r


#endregion


#region 辅助方法

## 获取两格之间的距离
func hex_distance(from: Vector2i, to: Vector2i) -> int:
	var dq: int = absi(from.x - to.x)
	var dr: int = absi(from.y - to.y)
	var ds: int = absi((-from.x - from.y) - (-to.x - to.y))
	return maxi(maxi(dq, dr), ds)


## 获取指定范围内的格子
func get_cells_in_range(center: Vector2i, range_val: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for r in range(board_rows):
		for q in range(board_cols):
			var dist := hex_distance(center, Vector2i(q, r))
			if dist <= range_val and dist > 0:
				cells.append(Vector2i(q, r))
	return cells


## 检查格子是否在棋盘边缘
func is_edge_cell(q: int, r: int) -> bool:
	return q == 0 or q == board_cols - 1 or r == 0 or r == board_rows - 1


## 检查格子周围是否有其他角色（用于hirro单挂检测）
func is_isolated(q: int, r: int) -> bool:
	var neighbors := get_neighbors(q, r)
	for n in neighbors:
		if not is_cell_empty(n.x, n.y):
			return false
	return true


#endregion
