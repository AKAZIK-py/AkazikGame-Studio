# 游戏状态 (Game State)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 策略发现、快速反馈

## Overview

游戏状态系统是 V-Tacit 的**全局状态容器**，管理：
- **游戏阶段**（商店/战斗/结算）
- **棋盘阵容**（哪些角色在哪些位置）
- **商店状态**（当前卡牌、刷新次数）
- **战斗结果**（胜率、结果）

它是多个系统的**协调中心**，确保各系统状态同步。本系统是基础设施，玩家不直接感知，但通过状态管理确保操作响应即时、游戏流程清晰。

## Player Fantasy

本系统是**基础设施**，玩家不会直接感知。但通过状态管理，确保：
- 操作响应即时（快速反馈支柱）
- 游戏流程清晰（策略发现支柱）

## Detailed Design

### Core Rules

#### 游戏阶段

MVP的游戏流程：

```
[商店阶段] → [战斗阶段] → [结果展示] → [商店阶段]（循环）
```

| 阶段 | 描述 | 可执行操作 |
|------|------|----------|
| `shop` | 商店购买/刷新 | 刷新商店、选择角色、放置棋子 |
| `battle` | 战斗计算 | 无（自动进行） |
| `result` | 结果展示 | 查看结果、点击"继续" |

#### 状态数据结构

```gdscript
# GameState.gd
class_name GameState

# 游戏阶段
var phase: String = "shop"  # shop / battle / result

# 棋盘状态 (位置 -> 角色实例)
var board: Dictionary = {}  # {cell_id: CharacterInstance}

# 商店状态
var shop_cards: Array = []  # 当前商店卡牌 (CharacterData数组)
var refresh_count: int = 0  # 已刷新次数

# 战斗结果
var battle_result: Dictionary = {}  # {win_rate: float, winner: String}

# 统计
var total_rounds: int = 0  # 总回合数
```

#### 角色实例数据

```gdscript
# CharacterInstance.gd
class_name CharacterInstance

var character_id: String    # 角色ID
var position: Vector2i      # 棋盘位置
var current_health: int     # 当前生命值（战斗中）
```

### States and Transitions

```
         ┌──────────────────────────────────────┐
         ↓                                      │
[SHOP] ──点击对战──> [BATTLE] ──计算完成──> [RESULT]
    │                    │                  │
    └──重置游戏──────────┴──────────────────┘
```

#### 阶段转换条件

| 转换 | 条件 | 触发者 |
|------|------|--------|
| shop → battle | 玩家点击"对战"按钮 | 玩家操作 |
| battle → result | 战斗计算完成 | 战斗系统 |
| result → shop | 玩家点击"继续" | 玩家操作 |
| 任意 → shop | 玩家点击"重置" | 玩家操作 |

### Interactions with Other Systems

游戏状态被以下系统依赖：

| 系统 | 读取 | 写入 |
|------|------|------|
| 棋盘系统 | 读取board | 写入board（放置/移除角色） |
| 商店系统 | 读取shop_cards | 写入shop_cards |
| 战斗系统 | 读取board | 写入battle_result |
| 重置系统 | — | 清空所有状态 |
| UI系统 | 读取phase | — |

## Formulas

本系统不涉及公式计算，只存储状态数据。

## Edge Cases

| 情况 | 处理 |
|------|------|
| 商店卡牌为空 | 初始化时自动填充 |
| 棋盘为空时点击对战 | 允许，胜率为0 |
| 战斗中点击重置 | 取消战斗，重置状态 |
| 同一位置重复放置角色 | 后放置的角色覆盖 |
| 角色实例数据丢失 | 从角色数据重新创建实例 |

## Dependencies

### 上游依赖

**无**。游戏状态是 Foundation 层系统。

### 下游依赖

| 系统 | 依赖类型 | 使用内容 |
|------|----------|----------|
| 棋盘系统 | 强依赖 | 读写board状态 |
| 商店系统 | 强依赖 | 读写shop_cards状态 |
| 战斗系统 | 强依赖 | 读取board，写入battle_result |
| 重置系统 | 强依赖 | 清空所有状态 |

## Tuning Knobs

本系统无调参需求。游戏参数由其他系统管理。

## Visual/Audio Requirements

无。本系统不涉及视觉/音频。

## UI Requirements

UI系统根据 `phase` 显示不同界面：
- `shop`: 商店界面、棋盘界面
- `battle`: 战斗动画界面（或加载界面）
- `result`: 结果展示界面

## Acceptance Criteria

### 功能验证

- [ ] 游戏阶段正确转换（shop → battle → result → shop）
- [ ] 棋盘状态可读写（放置、移除角色）
- [ ] 商店状态可读写（刷新、选择）
- [ ] 战斗结果可存储
- [ ] 重置功能清空所有状态

### 性能要求

- [ ] 状态读写响应时间 < 1ms

## Open Questions

| 问题 | 负责人 | 目标解决时间 |
|------|--------|--------------|
| 刷新次数是否有限制？ | 策划 | 实现阶段 |
| 是否需要保存/加载功能？ | 策划 | 完整版规划 |
