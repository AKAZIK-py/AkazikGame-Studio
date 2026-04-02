#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
# Question: 六边形坐标系统是否正确工作？邻居检测、放置验证、坐标转换是否准确？
# Date: 2026-03-28
"""
棋盘系统原型 - 验证核心逻辑 (Python版本)

运行: python3 board_prototype.py

验证内容:
1. 六边形 Axial 坐标系统
2. 邻居检测 (6个方向)
3. 角色放置和移除
4. 位置验证
5. 坐标转换 (屏幕坐标 ↔ 棋盘坐标)
6. 边缘情况处理
"""

import math
import sys
from dataclasses import dataclass
from typing import Optional, List, Tuple, Set

# ============================================================
# 常量定义
# ============================================================

# 棋盘规格
BOARD_ROWS = 4
BOARD_COLS = 8
TOTAL_CELLS = BOARD_ROWS * BOARD_COLS  # 32格

# 六边形方向 (Axial坐标系)
HEX_DIRECTIONS = [
    (1, 0),   # 右
    (1, -1),  # 右上
    (0, -1),  # 左上
    (-1, 0),  # 左
    (-1, 1),  # 左下
    (0, 1),   # 右下
]

# ============================================================
# 数据类
# ============================================================

@dataclass
class Character:
    id: str
    display_name: str

@dataclass
class HexCell:
    q: int
    r: int

    def __hash__(self):
        return hash((self.q, self.r))

    def __eq__(self, other):
        return self.q == other.q and self.r == other.r

    def __repr__(self):
        return f"({self.q},{self.r})"

# ============================================================
# 棋盘系统
# ============================================================

class BoardSystem:
    """
    六边形棋盘系统

    使用 Axial 坐标系 (q, r)
    棋盘范围: q ∈ [0, 7], r ∈ [0, 3]
    """

    def __init__(self, rows: int = BOARD_ROWS, cols: int = BOARD_COLS):
        self.rows = rows
        self.cols = cols
        self._board: dict = {}  # key: (q, r), value: Character

    def is_valid_position(self, q: int, r: int) -> bool:
        """检查位置是否在棋盘范围内"""
        return 0 <= q < self.cols and 0 <= r < self.rows

    def is_cell_empty(self, q: int, r: int) -> bool:
        """检查格子是否为空"""
        if not self.is_valid_position(q, r):
            return False
        return (q, r) not in self._board

    def get_character_at(self, q: int, r: int) -> Optional[Character]:
        """获取格子上的角色"""
        return self._board.get((q, r))

    def place_character(self, character: Character, q: int, r: int) -> bool:
        """
        放置角色到格子

        返回: True 成功, False 失败
        """
        if not self.is_valid_position(q, r):
            return False
        if not self.is_cell_empty(q, r):
            return False

        self._board[(q, r)] = character
        return True

    def remove_character(self, q: int, r: int) -> Optional[Character]:
        """移除角色，返回被移除的角色或None"""
        if not self.is_valid_position(q, r):
            return None
        return self._board.pop((q, r), None)

    def move_character(self, from_q: int, from_r: int, to_q: int, to_r: int) -> bool:
        """
        移动角色从一个格子到另一个格子

        返回: True 成功, False 失败
        """
        # 验证源位置
        if not self.is_valid_position(from_q, from_r):
            return False
        if self.is_cell_empty(from_q, from_r):
            return False

        # 验证目标位置
        if not self.is_valid_position(to_q, to_r):
            return False
        if not self.is_cell_empty(to_q, to_r):
            return False

        # 执行移动
        character = self._board.pop((from_q, from_r))
        self._board[(to_q, to_r)] = character
        return True

    def get_neighbors(self, q: int, r: int) -> List[Tuple[int, int]]:
        """获取相邻格子（6个方向）"""
        neighbors = []
        for dq, dr in HEX_DIRECTIONS:
            nq, nr = q + dq, r + dr
            if self.is_valid_position(nq, nr):
                neighbors.append((nq, nr))
        return neighbors

    def get_all_characters(self) -> List[Tuple[int, int, Character]]:
        """获取所有已放置的角色"""
        return [(q, r, char) for (q, r), char in self._board.items()]

    def get_occupied_cells(self) -> Set[Tuple[int, int]]:
        """获取所有已占用的格子"""
        return set(self._board.keys())

    def clear(self):
        """清空棋盘"""
        self._board.clear()

    def get_cell_count(self) -> int:
        """获取已放置角色数量"""
        return len(self._board)

    def is_isolated(self, q: int, r: int) -> bool:
        """检查格子是否孤立（周围6格无其他棋子）"""
        if not self.is_valid_position(q, r):
            return False

        neighbors = self.get_neighbors(q, r)
        for nq, nr in neighbors:
            if (nq, nr) in self._board:
                return False
        return True

    # ============================================================
    # 坐标转换
    # ============================================================

    @staticmethod
    def hex_to_pixel(q: int, r: int, hex_size: float) -> Tuple[float, float]:
        """
        棋盘坐标转屏幕坐标 (Pointy-top hexagon)

        Args:
            q, r: Axial 坐标
            hex_size: 六边形大小（中心到顶点的距离）

        Returns:
            (x, y): 屏幕坐标
        """
        x = hex_size * (math.sqrt(3) * q + math.sqrt(3) / 2 * r)
        y = hex_size * (3 / 2 * r)
        return (x, y)

    @staticmethod
    def pixel_to_hex(x: float, y: float, hex_size: float) -> Tuple[int, int]:
        """
        屏幕坐标转棋盘坐标 (Pointy-top hexagon)

        Args:
            x, y: 屏幕坐标
            hex_size: 六边形大小

        Returns:
            (q, r): Axial 坐标（已四舍五入）
        """
        q = (math.sqrt(3) / 3 * x - 1 / 3 * y) / hex_size
        r = (2 / 3 * y) / hex_size
        return BoardSystem.hex_round(q, r)

    @staticmethod
    def hex_round(q: float, r: float) -> Tuple[int, int]:
        """
        六边形坐标四舍五入

        将浮点坐标四舍五入到最近的整数坐标
        """
        s = -q - r

        rq = round(q)
        rr = round(r)
        rs = round(s)

        q_diff = abs(rq - q)
        r_diff = abs(rr - r)
        s_diff = abs(rs - s)

        if q_diff > r_diff and q_diff > s_diff:
            rq = -rr - rs
        elif r_diff > s_diff:
            rr = -rq - rs

        return (int(rq), int(rr))

    def visualize_board(self) -> str:
        """
        可视化棋盘（文本形式）

        返回: 棋盘的ASCII艺术表示
        """
        lines = []
        lines.append("   " + "  ".join(f"{i:2d}" for i in range(self.cols)))
        lines.append("   " + "---" * self.cols)

        for r in range(self.rows):
            row_chars = []
            for q in range(self.cols):
                if (q, r) in self._board:
                    char = self._board[(q, r)]
                    row_chars.append(f"{char.display_name[0]}  ")
                else:
                    row_chars.append("·  ")
            lines.append(f"{r:2d}| " + "".join(row_chars))

        return "\n".join(lines)

# ============================================================
# 测试用例
# ============================================================

class TestRunner:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.results = []

    def assert_true(self, condition: bool, message: str):
        if condition:
            self.passed += 1
            self.results.append(f"  ✓ {message}")
        else:
            self.failed += 1
            self.results.append(f"  ✗ {message}")

    def print_results(self):
        print("-" * 50)
        for result in self.results:
            print(result)
        print("-" * 50)
        print(f"通过: {self.passed}, 失败: {self.failed}")

def test_board_dimensions(test: TestRunner):
    """测试棋盘尺寸"""
    print("\n### 测试1: 棋盘尺寸 ###")

    board = BoardSystem()

    print(f"  棋盘规格: {board.rows}行 × {board.cols}列 = {board.rows * board.cols}格")
    test.assert_true(board.rows == BOARD_ROWS, f"行数应为{BOARD_ROWS}")
    test.assert_true(board.cols == BOARD_COLS, f"列数应为{BOARD_COLS}")
    test.assert_true(board.get_cell_count() == 0, "初始时应为空")

    print(f"\n{board.visualize_board()}")

def test_valid_positions(test: TestRunner):
    """测试位置验证"""
    print("\n### 测试2: 位置验证 ###")

    board = BoardSystem()

    # 有效位置
    valid_positions = [(0, 0), (7, 0), (0, 3), (7, 3), (3, 1)]
    for q, r in valid_positions:
        result = board.is_valid_position(q, r)
        print(f"  ({q}, {r}): 有效={result}")
        test.assert_true(result, f"({q}, {r}) 应为有效位置")

    # 无效位置
    invalid_positions = [(-1, 0), (8, 0), (0, -1), (0, 4), (8, 4)]
    for q, r in invalid_positions:
        result = board.is_valid_position(q, r)
        print(f"  ({q}, {r}): 有效={result}")
        test.assert_true(not result, f"({q}, {r}) 应为无效位置")

def test_place_and_remove(test: TestRunner):
    """测试放置和移除"""
    print("\n### 测试3: 放置和移除 ###")

    board = BoardSystem()
    char1 = Character("azi", "阿梓")
    char2 = Character("qi_hai", "七海")

    # 放置角色
    result = board.place_character(char1, 2, 1)
    print(f"  放置阿梓到(2,1): {result}")
    test.assert_true(result, "放置应成功")

    result = board.place_character(char2, 5, 2)
    print(f"  放置七海到(5,2): {result}")
    test.assert_true(result, "放置应成功")

    test.assert_true(board.get_cell_count() == 2, "应有2个角色")

    # 尝试放置到已占用格子
    result = board.place_character(char1, 2, 1)
    print(f"  放置到已占用格子(2,1): {result}")
    test.assert_true(not result, "放置到已占用格子应失败")

    # 尝试放置到无效位置
    result = board.place_character(char1, 10, 10)
    print(f"  放置到无效位置(10,10): {result}")
    test.assert_true(not result, "放置到无效位置应失败")

    print(f"\n{board.visualize_board()}")

    # 移除角色
    removed = board.remove_character(2, 1)
    print(f"\n  移除(2,1)的角色: {removed.display_name if removed else None}")
    test.assert_true(removed is not None and removed.id == "azi", "应移除阿梓")
    test.assert_true(board.get_cell_count() == 1, "应有1个角色")

    # 移除空格子
    removed = board.remove_character(2, 1)
    print(f"  移除空格子(2,1): {removed}")
    test.assert_true(removed is None, "移除空格子应返回None")

def test_move_character(test: TestRunner):
    """测试移动角色"""
    print("\n### 测试4: 移动角色 ###")

    board = BoardSystem()
    char = Character("azi", "阿梓")

    # 放置角色
    board.place_character(char, 0, 0)
    print(f"  初始位置: (0, 0)")

    # 移动到新位置
    result = board.move_character(0, 0, 3, 2)
    print(f"  移动到(3, 2): {result}")
    test.assert_true(result, "移动应成功")
    test.assert_true(board.get_character_at(0, 0) is None, "原位置应为空")
    test.assert_true(board.get_character_at(3, 2).id == "azi", "新位置应有角色")

    # 移动到已占用位置
    board.place_character(Character("qi_hai", "七海"), 5, 1)
    result = board.move_character(3, 2, 5, 1)
    print(f"  移动到已占用位置: {result}")
    test.assert_true(not result, "移动到已占用位置应失败")

    # 移动空格子
    result = board.move_character(0, 0, 1, 1)
    print(f"  移动空格子: {result}")
    test.assert_true(not result, "移动空格子应失败")

    print(f"\n{board.visualize_board()}")

def test_neighbors(test: TestRunner):
    """测试邻居检测"""
    print("\n### 测试5: 邻居检测 ###")

    board = BoardSystem()

    # 中心位置的邻居
    neighbors = board.get_neighbors(4, 1)
    print(f"  (4, 1)的邻居: {neighbors}")
    test.assert_true(len(neighbors) == 6, "中心位置应有6个邻居")

    # 角落位置的邻居
    neighbors = board.get_neighbors(0, 0)
    print(f"  (0, 0)的邻居: {neighbors}")
    test.assert_true(len(neighbors) == 2, "角落位置应有2个邻居")  # 只有右和右下方向有效

    neighbors = board.get_neighbors(7, 3)
    print(f"  (7, 3)的邻居: {neighbors}")
    test.assert_true(len(neighbors) == 2, "角落位置应有2个邻居")  # 只有左和上方向有效

    # 边缘位置的邻居
    neighbors = board.get_neighbors(0, 1)
    print(f"  (0, 1)的邻居: {neighbors}")
    test.assert_true(len(neighbors) == 4, "边缘位置应有4个邻居")

    neighbors = board.get_neighbors(4, 0)
    print(f"  (4, 0)的邻居: {neighbors}")
    test.assert_true(len(neighbors) == 4, "上边缘位置应有4个邻居")

def test_isolation_detection(test: TestRunner):
    """测试孤立检测"""
    print("\n### 测试6: 孤立检测 ###")

    board = BoardSystem()

    # 放置一个孤立的角色
    char1 = Character("hirro", "hirro")
    board.place_character(char1, 5, 2)
    is_isolated = board.is_isolated(5, 2)
    print(f"  hirro单独放置在(5,2): 孤立={is_isolated}")
    test.assert_true(is_isolated, "单独放置应为孤立")

    # 在旁边放置另一个角色
    char2 = Character("xiao_ke", "小可")
    board.place_character(char2, 6, 2)  # (6,2)是(5,2)的邻居
    is_isolated = board.is_isolated(5, 2)
    print(f"  旁边放置小可后: 孤立={is_isolated}")
    test.assert_true(not is_isolated, "有邻居后不应孤立")

    # 移除邻居
    board.remove_character(6, 2)
    is_isolated = board.is_isolated(5, 2)
    print(f"  移除邻居后: 孤立={is_isolated}")
    test.assert_true(is_isolated, "移除邻居后应恢复孤立")

    print(f"\n{board.visualize_board()}")

def test_coordinate_conversion(test: TestRunner):
    """测试坐标转换"""
    print("\n### 测试7: 坐标转换 ###")

    hex_size = 50.0

    # 测试几个关键位置
    test_positions = [
        (0, 0),
        (1, 0),
        (0, 1),
        (4, 2),
        (7, 3),
    ]

    for q, r in test_positions:
        x, y = BoardSystem.hex_to_pixel(q, r, hex_size)
        rq, rr = BoardSystem.pixel_to_hex(x, y, hex_size)
        print(f"  ({q},{r}) → 像素({x:.1f},{y:.1f}) → hex({rq},{rr})")
        test.assert_true(q == rq and r == rr, f"坐标转换应可逆: ({q},{r}) ↔ ({rq},{rr})")

    # 测试偏移像素也能正确转换
    print("\n  测试偏移像素:")
    for q, r in test_positions:
        x, y = BoardSystem.hex_to_pixel(q, r, hex_size)
        # 添加小偏移
        for dx, dy in [(10, 10), (-10, 5), (5, -10)]:
            rq, rr = BoardSystem.pixel_to_hex(x + dx, y + dy, hex_size)
            print(f"    偏移({dx},{dy}): ({q},{r}) → ({rq},{rr})")
            test.assert_true(q == rq and r == rr, f"小偏移应四舍五入到原格子")

def test_full_board(test: TestRunner):
    """测试完整棋盘"""
    print("\n### 测试8: 完整棋盘 ###")

    board = BoardSystem()

    # 填满棋盘
    chars = []
    for i in range(TOTAL_CELLS):
        q = i % BOARD_COLS
        r = i // BOARD_COLS
        char = Character(f"char_{i}", f"角色{i}")
        chars.append(char)
        result = board.place_character(char, q, r)
        test.assert_true(result, f"放置角色{i}到({q},{r})应成功")

    print(f"  已放置角色数: {board.get_cell_count()}")
    test.assert_true(board.get_cell_count() == TOTAL_CELLS, f"应有{TOTAL_CELLS}个角色")

    print(f"\n{board.visualize_board()}")

    # 尝试再放置
    result = board.place_character(Character("extra", "额外"), 0, 0)
    print(f"\n  棋盘满后放置: {result}")
    test.assert_true(not result, "棋盘满后无法放置")

    # 清空棋盘
    board.clear()
    test.assert_true(board.get_cell_count() == 0, "清空后应为0个角色")
    print(f"  清空后角色数: {board.get_cell_count()}")

# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 60)
    print("棋盘系统原型测试")
    print("=" * 60)
    print(f"棋盘规格: {BOARD_ROWS}行 × {BOARD_COLS}列 = {TOTAL_CELLS}格")

    test = TestRunner()

    test_board_dimensions(test)
    test_valid_positions(test)
    test_place_and_remove(test)
    test_move_character(test)
    test_neighbors(test)
    test_isolation_detection(test)
    test_coordinate_conversion(test)
    test_full_board(test)

    test.print_results()

    return test.failed

if __name__ == "__main__":
    sys.exit(main())
