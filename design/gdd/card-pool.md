# 卡池管理 (Card Pool Management)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 策略发现

## Overview

卡池管理系统负责定义**可用角色池**、**抽卡概率**和**已选角色追踪**。商店系统从卡池中抽取角色供玩家选择。

## Player Fantasy

- 每局游戏体验不同（随机性）
- 高费角色稀有但有价值
- 策略选择：选择哪个角色？

## Detailed Design

### Core Rules

#### 卡池定义

卡池包含所有可用角色，按费用分组：

| 费用 | 角色 | 出现概率 |
|------|------|----------|
| 1费 | 小可, 柚恩, 泽音, 露早 | 30% |
| 2费 | hirro, 雪糕, 白神遥 | 25% |
| 3费 | 雫lulu, 阿梓, 恬豆, 东爱璃 | 25% |
| 4费 | 七海, 永雏塔菲 | 15% |
| 5费 | 星瞳 | 5% |

#### 抽卡逻辑

```gdscript
# CardPoolManager.gd
class_name CardPoolManager

## 初始化卡池
func initialize_pool() -> void

## 抽取一张卡（按概率）
func draw_card() -> CharacterData

## 抽取N张卡
func draw_cards(count: int) -> Array[CharacterData]

## 从卡池移除角色（已选走）
func remove_from_pool(character_id: String) -> void

## 重置卡池
func reset_pool() -> void
```

#### 商店卡槽数量

MVP阶段：**5个卡槽**（每次刷新显示5张卡）

### States and Transitions

卡池状态存储在 `GameState`，本系统提供操作逻辑。

```
[完整卡池] ──抽取──> [减少] ──重置──> [完整卡池]
```

### Interactions with Other Systems

| 系统 | 关系 | 数据流 |
|------|------|--------|
| 角色数据 | 依赖 | 读取所有角色定义 |
| 游戏状态 | 依赖 | 存储卡池状态 |
| 商店系统 | 被依赖 | 提供抽卡接口 |

## Formulas

### 概率计算

```gdscript
func draw_card() -> CharacterData:
    var roll = randf()  # 0.0 - 1.0

    if roll < 0.30:      # 30%
        return draw_from_tier(1)
    elif roll < 0.55:    # 25%
        return draw_from_tier(2)
    elif roll < 0.80:    # 25%
        return draw_from_tier(3)
    elif roll < 0.95:    # 15%
        return draw_from_tier(4)
    else:                # 5%
        return draw_from_tier(5)
```

## Edge Cases

| 情况 | 处理 |
|------|------|
| 某费用角色全部被选走 | 概率重新分配到其他费用 |
| 卡池为空 | 返回 null |
| 抽取数量超过剩余卡数 | 返回剩余所有卡 |

## Dependencies

### 上游依赖

| 系统 | 使用内容 |
|------|----------|
| 角色数据 | 角色列表和费用 |
| 游戏状态 | 卡池状态存储 |

### 下游依赖

| 系统 | 使用内容 |
|------|----------|
| 商店系统 | 抽卡接口 |

## Tuning Knobs

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 1费概率 | 30% | 可调整平衡 |
| 2费概率 | 25% | 可调整平衡 |
| 3费概率 | 25% | 可调整平衡 |
| 4费概率 | 15% | 可调整平衡 |
| 5费概率 | 5% | 可调整平衡 |
| 商店卡槽数 | 5 | 可调整 |

## Visual/Audio Requirements

无。

## UI Requirements

无。

## Acceptance Criteria

- [ ] 抽卡概率符合设计
- [ ] 可抽取指定数量卡牌
- [ ] 已选角色从卡池移除
- [ ] 卡池可重置

## Open Questions

无。
