# test_board_system.gd
# Unit tests for BoardSystem

extends "res://tests/unit/test_base.gd"

var _board: BoardSystem


func before_each() -> void:
	super.before_each()
	_board = BoardSystem.new()
	_board.board_rows = 4
	_board.board_cols = 8
	_board.hex_size = 40.0
	add_child(_board)


func after_each() -> void:
	if _board:
		_board.queue_free()
		_board = null


func test_is_valid_position() -> void:
	assert_true(_board.is_valid_position(0, 0), "0,0 should be valid")
	assert_true(_board.is_valid_position(7, 3), "7,3 should be valid (corner)")
	assert_false(_board.is_valid_position(-1, 0), "-1,0 should be invalid")
	assert_false(_board.is_valid_position(0, -1), "0,-1 should be invalid")
	assert_false(_board.is_valid_position(8, 0), "8,0 should be invalid (out of bounds)")
	assert_false(_board.is_valid_position(0, 4), "0,4 should be invalid (out of bounds)")


func test_is_cell_empty() -> void:
	assert_true(_board.is_cell_empty(0, 0), "Empty board should have empty cells")


func test_get_neighbors() -> void:
	# 中心位置
	var neighbors := _board.get_neighbors(3, 2)
	assert_eq(neighbors.size(), 6, "Center cell should have 6 neighbors")

	# 边缘位置
	var edge_neighbors := _board.get_neighbors(0, 0)
	assert_lt(edge_neighbors.size(), 6, "Edge cell should have fewer neighbors")


func test_hex_to_pixel_and_back() -> void:
	var q := 3
	var r := 2
	var pixel := _board.hex_to_pixel(q, r)
	var back := _board.pixel_to_hex(pixel)

	assert_eq(back.x, q, "Q should round-trip correctly")
	assert_eq(back.y, r, "R should round-trip correctly")


func test_hex_distance() -> void:
	var from := Vector2i(0, 0)
	var to := Vector2i(2, 0)

	var dist := _board.hex_distance(from, to)
	assert_eq(dist, 2, "Distance should be 2")


func test_get_all_cells() -> void:
	var cells := _board.get_all_cells()
	assert_eq(cells.size(), 32, "Should have 32 cells (4x8)")


func test_get_empty_cells() -> void:
	var empty := _board.get_empty_cells()
	assert_eq(empty.size(), 32, "All cells should be empty initially")


func test_is_edge_cell() -> void:
	assert_true(_board.is_edge_cell(0, 0), "Corner should be edge")
	assert_true(_board.is_edge_cell(7, 3), "Corner should be edge")
	assert_false(_board.is_edge_cell(3, 2), "Center should not be edge")


func test_is_isolated() -> void:
	assert_true(_board.is_isolated(3, 2), "Cell on empty board should be isolated")


func test_get_cells_in_range() -> void:
	var center := Vector2i(3, 2)
	var in_range := _board.get_cells_in_range(center, 1)
	assert_gt(in_range.size(), 0, "Should find cells in range")
