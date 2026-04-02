#!/usr/bin/env python3
# PROTOTYPE - NOT FOR PRODUCTION
# Question: 拖放交互流程是否正确？状态管理是否准确？放置验证是否工作？
# Date: 2026-03-28
"""
拖放交互原型 - 验证核心逻辑 (Python版本)

运行: python3 drag_drop_prototype.py

验证内容:
1. 拖放状态机
2. 拖动开始/结束流程
3. 格子显示/隐藏逻辑
4. 放置验证
5. 成功/失败处理
"""

import sys
from dataclasses import dataclass
from typing import Optional, List, Tuple
from enum import Enum, auto

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

# ============================================================
# 拖放状态机
# ============================================================

class DragState(Enum):
    IDLE = auto()        # 空闲状态
    DRAGGING = auto()    # 正在拖动
    HOVERING = auto()    # 悬停在格子上
    DROPPED = auto()     # 已放下
    CANCELLED = auto()   # 取消拖动

# ============================================================
# 模拟棋盘系统
# ============================================================

class MockBoardSystem:
    """模拟棋盘系统"""

    def __init__(self, rows: int = 4, cols: int = 8):
        self.rows = rows
        self.cols = cols
        self._board = {}

    def is_valid_position(self, q: int, r: int) -> bool:
        return 0 <= q < self.cols and 0 <= r < self.rows

    def is_cell_empty(self, q: int, r: int) -> bool:
        return (q, r) not in self._board

    def place_character(self, character: Character, q: int, r: int) -> bool:
        if not self.is_valid_position(q, r):
            return False
        if not self.is_cell_empty(q, r):
            return False
        self._board[(q, r)] = character
        return True

    def remove_character(self, q: int, r: int) -> Optional[Character]:
        return self._board.pop((q, r), None)

    def get_all_cells(self) -> List[Tuple[int, int]]:
        """获取所有格子"""
        cells = []
        for r in range(self.rows):
            for q in range(self.cols):
                cells.append((q, r))
        return cells

    def get_empty_cells(self) -> List[Tuple[int, int]]:
        """获取所有空格子"""
        return [(q, r) for q, r in self.get_all_cells() if self.is_cell_empty(q, r)]

# ============================================================
# 模拟格子显示系统
# ============================================================

class MockCellDisplay:
    """模拟格子显示系统"""

    def __init__(self):
        self.cells_visible = False
        self.highlighted_cell: Optional[Tuple[int, int]] = None
        self.valid_cells: List[Tuple[int, int]] = []

    def show_cells(self, valid_cells: List[Tuple[int, int]]):
        """显示格子（拖动开始时调用）"""
        self.cells_visible = True
        self.valid_cells = valid_cells
        print(f"    [格子显示] 显示 {len(valid_cells)} 个可放置格子")

    def hide_cells(self):
        """隐藏格子（拖动结束时调用）"""
        self.cells_visible = False
        self.highlighted_cell = None
        self.valid_cells = []
        print("    [格子显示] 隐藏所有格子")

    def highlight_cell(self, q: int, r: int):
        """高亮格子（悬停时调用）"""
        self.highlighted_cell = (q, r)
        print(f"    [格子显示] 高亮格子 ({q}, {r})")

    def clear_highlight(self):
        """清除高亮"""
        self.highlighted_cell = None
        print("    [格子显示] 清除高亮")

# ============================================================
# 拖放交互系统
# ============================================================

class DragDropInteraction:
    """
    拖放交互系统

    负责：
    - 拖放状态管理
    - 格子显示控制
    - 放置验证
    """

    def __init__(self, board: MockBoardSystem, cell_display: MockCellDisplay):
        self._board = board
        self._cell_display = cell_display
        self._state = DragState.IDLE
        self._dragging_character: Optional[Character] = None
        self._hover_cell: Optional[Tuple[int, int]] = None
        self._drag_source: Optional[str] = None  # "shop" or "board"

    def get_state(self) -> DragState:
        """获取当前状态"""
        return self._state

    def is_dragging(self) -> bool:
        """是否正在拖动"""
        return self._state in [DragState.DRAGGING, DragState.HOVERING]

    def get_dragging_character(self) -> Optional[Character]:
        """获取正在拖动的角色"""
        return self._dragging_character

    def start_drag(self, character: Character, source: str = "shop") -> bool:
        """
        开始拖动

        Args:
            character: 要拖动的角色
            source: 拖动来源 ("shop" 或 "board")

        Returns:
            是否成功开始拖动
        """
        if self._state != DragState.IDLE:
            print(f"    [拖放] 无法开始拖动: 当前状态为 {self._state.name}")
            return False

        self._dragging_character = character
        self._drag_source = source
        self._state = DragState.DRAGGING

        print(f"    [拖放] 开始拖动: {character.display_name} (来源: {source})")

        # 显示可放置格子
        valid_cells = self._board.get_empty_cells()
        self._cell_display.show_cells(valid_cells)

        return True

    def update_drag_position(self, screen_x: float, screen_y: float, cell_q: int, cell_r: int):
        """
        更新拖动位置

        Args:
            screen_x, screen_y: 屏幕坐标
            cell_q, cell_r: 悬停的棋盘格子坐标
        """
        if not self.is_dragging():
            return

        # 检查是否在有效格子上
        if self._board.is_valid_position(cell_q, cell_r):
            if self._board.is_cell_empty(cell_q, cell_r):
                # 进入有效格子
                self._state = DragState.HOVERING
                self._hover_cell = (cell_q, cell_r)
                self._cell_display.highlight_cell(cell_q, cell_r)
            else:
                # 格子被占用
                self._state = DragState.DRAGGING
                self._hover_cell = None
                self._cell_display.clear_highlight()
        else:
            # 在格子外
            if self._state == DragState.HOVERING:
                self._state = DragState.DRAGGING
                self._hover_cell = None
                self._cell_display.clear_highlight()

    def end_drag(self) -> Tuple[bool, str]:
        """
        结束拖动

        Returns:
            (成功与否, 消息)
        """
        if not self.is_dragging():
            return False, "未在拖动状态"

        character = self._dragging_character
        success = False
        message = ""

        if self._state == DragState.HOVERING and self._hover_cell:
            # 放置到悬停的格子
            q, r = self._hover_cell
            if self._board.place_character(character, q, r):
                success = True
                message = f"成功放置 {character.display_name} 到 ({q}, {r})"
                self._state = DragState.DROPPED
                print(f"    [拖放] {message}")
            else:
                message = f"放置失败: 格子 ({q}, {r}) 无效或已占用"
                self._state = DragState.CANCELLED
                print(f"    [拖放] {message}")
        else:
            # 未悬停在有效格子上，取消放置
            message = f"取消放置 {character.display_name}"
            self._state = DragState.CANCELLED
            print(f"    [拖放] {message}")

        # 隐藏格子
        self._cell_display.hide_cells()

        # 重置状态
        self._dragging_character = None
        self._hover_cell = None
        self._drag_source = None
        self._state = DragState.IDLE

        return success, message

    def cancel_drag(self):
        """取消拖动"""
        if not self.is_dragging():
            return

        print(f"    [拖放] 取消拖动: {self._dragging_character.display_name if self._dragging_character else 'None'}")

        self._cell_display.hide_cells()
        self._dragging_character = None
        self._hover_cell = None
        self._drag_source = None
        self._state = DragState.IDLE

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

def test_drag_state_machine(test: TestRunner):
    """测试拖放状态机"""
    print("\n### 测试1: 拖放状态机 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    # 初始状态
    print("  初始状态检查:")
    test.assert_true(drag_drop.get_state() == DragState.IDLE, "初始状态应为IDLE")
    test.assert_true(not drag_drop.is_dragging(), "初始不应在拖动")

    # 开始拖动
    print("\n  开始拖动:")
    result = drag_drop.start_drag(char, "shop")
    test.assert_true(result, "开始拖动应成功")
    test.assert_true(drag_drop.get_state() == DragState.DRAGGING, "状态应为DRAGGING")
    test.assert_true(drag_drop.is_dragging(), "应在拖动")
    test.assert_true(drag_drop.get_dragging_character().id == "azi", "拖动角色应为阿梓")

    # 结束拖动（取消）
    print("\n  取消拖动:")
    drag_drop.cancel_drag()
    test.assert_true(drag_drop.get_state() == DragState.IDLE, "状态应回到IDLE")
    test.assert_true(not drag_drop.is_dragging(), "不应在拖动")

def test_cell_display(test: TestRunner):
    """测试格子显示"""
    print("\n### 测试2: 格子显示 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    # 开始拖动时显示格子
    drag_drop.start_drag(char, "shop")
    test.assert_true(cell_display.cells_visible, "拖动时应显示格子")
    test.assert_true(len(cell_display.valid_cells) == 32, "应显示32个格子（全部为空）")

    # 结束拖动时隐藏格子
    drag_drop.cancel_drag()
    test.assert_true(not cell_display.cells_visible, "拖动结束应隐藏格子")

def test_hover_highlight(test: TestRunner):
    """测试悬停高亮"""
    print("\n### 测试3: 悬停高亮 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    drag_drop.start_drag(char, "shop")

    # 移动到有效格子
    print("  移动到有效格子 (3, 1):")
    drag_drop.update_drag_position(200, 150, 3, 1)
    test.assert_true(drag_drop.get_state() == DragState.HOVERING, "状态应为HOVERING")
    test.assert_true(cell_display.highlighted_cell == (3, 1), "应高亮格子(3,1)")

    # 移动到无效格子
    print("\n  移动到无效格子 (10, 10):")
    drag_drop.update_drag_position(500, 500, 10, 10)
    test.assert_true(drag_drop.get_state() == DragState.DRAGGING, "状态应回到DRAGGING")
    test.assert_true(cell_display.highlighted_cell is None, "应清除高亮")

    drag_drop.cancel_drag()

def test_successful_placement(test: TestRunner):
    """测试成功放置"""
    print("\n### 测试4: 成功放置 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    # 开始拖动
    drag_drop.start_drag(char, "shop")

    # 移动到有效格子
    drag_drop.update_drag_position(200, 150, 2, 1)

    # 结束拖动（放置）
    success, message = drag_drop.end_drag()

    print(f"  放置结果: {message}")
    test.assert_true(success, "放置应成功")
    test.assert_true(board.get_empty_cells().__len__() == 31, "空格子应减少1个")
    test.assert_true(not board.is_cell_empty(2, 1), "格子(2,1)应被占用")
    test.assert_true(drag_drop.get_state() == DragState.IDLE, "状态应回到IDLE")

def test_failed_placement(test: TestRunner):
    """测试放置失败"""
    print("\n### 测试5: 放置失败 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char1 = Character("azi", "阿梓")
    char2 = Character("qi_hai", "七海")

    # 先放置一个角色
    board.place_character(char1, 2, 1)
    print(f"  预先放置阿梓到(2,1)")

    # 开始拖动另一个角色
    drag_drop.start_drag(char2, "shop")

    # 尝试移动到已占用的格子
    print("\n  尝试放置到已占用格子:")
    drag_drop.update_drag_position(200, 150, 2, 1)  # 已被占用

    # 状态应为DRAGGING（不是HOVERING）
    test.assert_true(drag_drop.get_state() == DragState.DRAGGING, "占用格子不应触发HOVERING")

    # 结束拖动（取消）
    success, message = drag_drop.end_drag()
    print(f"  结果: {message}")
    test.assert_true(not success, "放置到已占用格子应失败")

def test_drag_from_board(test: TestRunner):
    """测试从棋盘拖动"""
    print("\n### 测试6: 从棋盘拖动 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    # 预先放置角色
    board.place_character(char, 3, 2)
    print(f"  预先放置阿梓到(3,2)")

    # 从棋盘拖动（需要先移除）
    board.remove_character(3, 2)

    drag_drop.start_drag(char, "board")
    test.assert_true(drag_drop.get_dragging_character().id == "azi", "应能拖动棋盘上的角色")

    # 移动到新位置
    drag_drop.update_drag_position(300, 200, 5, 1)
    success, message = drag_drop.end_drag()

    print(f"  结果: {message}")
    test.assert_true(success, "移动到新位置应成功")
    test.assert_true(not board.is_cell_empty(5, 1), "新位置应被占用")

def test_multiple_drag_sequence(test: TestRunner):
    """测试多次拖放序列"""
    print("\n### 测试7: 多次拖放序列 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)

    characters = [
        Character("azi", "阿梓"),
        Character("qi_hai", "七海"),
        Character("tian_dou", "恬豆"),
    ]

    # 连续放置多个角色
    for i, char in enumerate(characters):
        print(f"\n  放置第{i+1}个角色: {char.display_name}")

        drag_drop.start_drag(char, "shop")
        drag_drop.update_drag_position(100 + i * 100, 100 + i * 50, i * 2, i)
        success, message = drag_drop.end_drag()

        print(f"    结果: {message}")
        test.assert_true(success, f"放置{char.display_name}应成功")

    # 验证棋盘状态
    print(f"\n  棋盘状态:")
    print(f"    空格子数: {len(board.get_empty_cells())}")
    test.assert_true(len(board.get_empty_cells()) == 29, "应有29个空格子")

def test_drag_cancellation(test: TestRunner):
    """测试拖动取消"""
    print("\n### 测试8: 拖动取消 ###")

    board = MockBoardSystem()
    cell_display = MockCellDisplay()
    drag_drop = DragDropInteraction(board, cell_display)
    char = Character("azi", "阿梓")

    # 开始拖动
    drag_drop.start_drag(char, "shop")
    test.assert_true(drag_drop.is_dragging(), "应在拖动")

    # 取消拖动
    drag_drop.cancel_drag()
    test.assert_true(not drag_drop.is_dragging(), "取消后不应在拖动")
    test.assert_true(drag_drop.get_state() == DragState.IDLE, "状态应为IDLE")
    test.assert_true(len(board.get_empty_cells()) == 32, "棋盘应无变化")

# ============================================================
# 主程序
# ============================================================

def main():
    print("=" * 60)
    print("拖放交互原型测试")
    print("=" * 60)

    test = TestRunner()

    test_drag_state_machine(test)
    test_cell_display(test)
    test_hover_highlight(test)
    test_successful_placement(test)
    test_failed_placement(test)
    test_drag_from_board(test)
    test_multiple_drag_sequence(test)
    test_drag_cancellation(test)

    test.print_results()

    return test.failed

if __name__ == "__main__":
    sys.exit(main())
