# 棋盘系统 (Board System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 策略发现

## Overview

棋盘系统管理六边形棋盘的**位置逻辑**，包括格子坐标、角色放置/移除、位置验证。它是游戏交互的核心——玩家通过在棋盘上放置角色来组建阵容。

棋盘规格：**4行8列六边形格子（32格）**。

## Player Fantasy

棋盘是玩家表达策略的画布：
- 位置选择创造策略深度（谁在前排？谁保护谁？）
- 六边形格子提供更灵活的站位选择
- 拖放操作直观流畅

## Detailed Design

### Core Rules

#### 棋盘规格

| 属性 | 值 |
|------|-----|
| 行数 | 4 |
| 列数 | 8 |
| 总格数 | 32 |
| 格子形状 | 六边形（flat-top） |
| 格子大小 | 64px（半径），范围 48-80px |

#### 六边形坐标系统

使用 **Axial 坐标系** (q, r)：

```
     0   1   2   3   4   5   6   7
   ┌───┬───┬───┬───┬───┬───┬───┬───┐
 0 │   │   │   │   │   │   │   │   │
   ├───┼───┼───┼───┼───┼───┼───┼───┤
 1 │   │   │   │   │   │   │   │   │
   ├───┼───┼───┼───┼───┼───┼───┼───┤
 2 │   │   │   │   │   │   │   │   │
   ├───┼───┼───┼───┼───┼───┼───┼───┤
 3 │   │   │   │   │   │   │   │   │
   └───┴───┴───┴───┴───┴───┴───┴───┘
```

#### 核心接口

```gdscript
# BoardSystem.gd
class_name BoardSystem

## 检查格子是否为空
func is_cell_empty(q: int, r: int) -> bool

## 获取格子上的角色
func get_character_at(q: int, r: int) -> CharacterInstance

## 放置角色到格子
func place_character(character: CharacterInstance, q: int, r: int) -> bool

## 移除角色
func remove_character(q: int, r: int) -> CharacterInstance

## 移动角色（从一个格子到另一个格子）
func move_character(from_q: int, from_r: int, to_q: int, to_r: int) -> bool

## 获取相邻格子（6个方向）
func get_neighbors(q: int, r: int) -> Array[Vector2i]

## 检查位置是否有效（在棋盘范围内）
func is_valid_position(q: int, r: int) -> bool

## 获取所有已放置的角色
func get_all_characters() -> Array[CharacterInstance]
```

### States and Transitions

棋盘系统本身是无状态逻辑层，状态存储在 `GameState.board`。

```
[格子为空] ──放置角色──> [格子被占用]
      ↑                      │
      └──────移除角色─────────┘
```

### Interactions with Other Systems

| 系统 | 关系 | 数据流 |
|------|------|--------|
| **游戏状态** | 依赖 | 读写 `GameState.board` |
| **格子显示** | 被依赖 | 提供格子位置信息 |
| **羁绊检测** | 被依赖 | 提供棋盘上的角色位置 |
| **重置系统** | 被依赖 | 清空棋盘 |
| **拖放交互** | 被依赖 | 验证放置位置 |

## Formulas

### 六边形相邻格计算

```gdscript
# 六边形的6个方向偏移
const DIRECTIONS = [
    Vector2i(1, 0),   # 右
    Vector2i(1, -1),  # 右上
    Vector2i(0, -1),  # 左上
    Vector2i(-1, 0),  # 左
    Vector2i(-1, 1),  # 左下
    Vector2i(0, 1),   # 右下
]

func get_neighbors(q: int, r: int) -> Array[Vector2i]:
    var neighbors = []
    for dir in DIRECTIONS:
        var nq = q + dir.x
        var nr = r + dir.y
        if is_valid_position(nq, nr):
            neighbors.append(Vector2i(nq, nr))
    return neighbors
```

### 屏幕坐标 ↔ 棋盘坐标转换

```gdscript
# 棋盘坐标转屏幕坐标
func hex_to_pixel(q: int, r: int, hex_size: float) -> Vector2:
    var x = hex_size * (3/2 * q)
    var y = hex_size * (sqrt(3)/2 * q + sqrt(3) * r)
    return Vector2(x, y)

# 屏幕坐标转棋盘坐标
func pixel_to_hex(x: float, y: float, hex_size: float) -> Vector2i:
    var q = (2/3 * x) / hex_size
    var r = (-1/3 * x + sqrt(3)/3 * y) / hex_size
    return hex_round(q, r)

# 六边形坐标取整（将浮点坐标转为最近的格子）
func hex_round(q: float, r: float) -> Vector2i:
    var s = -q - r
    var rq = round(q)
    var rr = round(r)
    var rs = round(s)
    var q_diff = abs(rq - q)
    var r_diff = abs(rr - r)
    var s_diff = abs(rs - s)
    if q_diff > r_diff and q_diff > s_diff:
        rq = -rr - rs
    elif r_diff > s_diff:
        rr = -rq - rs
    return Vector2i(int(rq), int(rr))
```

### Cell ID 格式

GameState 使用 `cell_id` 作为键存储棋盘状态。格式定义：

```gdscript
# cell_id 格式: "q_r" 字符串
# 示例: "0_0", "2_3", "7_3"

func cell_id_from_coords(q: int, r: int) -> String:
    return "%d_%d" % [q, r]

func coords_from_cell_id(cell_id: String) -> Vector2i:
    var parts = cell_id.split("_")
    return Vector2i(int(parts[0]), int(parts[1]))
```

**设计决策**: 使用字符串而非 `Vector2i` 作为键，因为：
- Dictionary 的键需要可哈希，字符串更稳定
- 便于调试和日志输出
- 与 JSON 序列化兼容

## Edge Cases

| 情况 | 处理 |
|------|------|
| 放置到已占用的格子 | 返回失败，不覆盖 |
| 移动到无效位置 | 返回失败，保留原位置 |
| 棋盘已满 | 允许，但无法继续放置 |
| 同一角色重复放置 | 允许（角色可重复） |

## Dependencies

### 上游依赖

| 系统 | 使用内容 |
|------|----------|
| 游戏状态 | 读写 `GameState.board` |

### 下游依赖

| 系统 | 使用内容 |
|------|----------|
| 格子显示 | 格子位置、状态 |
| 羁绊检测 | 角色位置列表 |
| 重置系统 | 清空棋盘接口 |
| 拖放交互 | 放置/移除接口 |

## Tuning Knobs

| 参数 | 默认值 | 调整影响 |
|------|--------|----------|
| 棋盘行数 | 4 | 影响策略深度 |
| 棋盘列数 | 8 | 影响阵容规模 |
| 六边形大小 | 64px | 48-80px | 影响显示和触控 |

## Visual/Audio Requirements

棋盘渲染由**棋盘渲染系统**负责，本系统只提供逻辑。

## UI Requirements

无。

## Acceptance Criteria

### 功能验证

- [ ] 放置角色到空格子成功
- [ ] 放置角色到已占用格子失败
- [ ] 移除角色成功
- [ ] 移动角色成功
- [ ] 获取相邻格子正确
- [ ] 坐标转换正确

### 边界验证

- [ ] 无效位置（超出棋盘范围）返回失败
- [ ] 空格子移除返回 null

## Open Questions

| 问题 | 负责人 | 目标解决时间 |
|------|--------|--------------|
| 六边形的具体像素大小？ | 美术 + 程序 | 实现阶段 |
| 是否需要格子位置标记（如前排/后排）？ | 策划 | 实现阶段 |
