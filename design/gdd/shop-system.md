# 商店系统 (Shop System)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-02
> **Implements Pillar**: 策略发现、粉丝幻想、快速反馈

## Overview

商店系统负责**展示卡牌**、**刷新商店**、**选择角色**。玩家通过商店获取角色，是游戏的核心交互之一。

## Player Fantasy

### 情感体验

- **期待感**: 每次刷新都期待看到喜爱的虚拟主播角色（粉丝幻想）
- **惊喜感**: 发现高费/稀有角色的惊喜
- **选择困难**: "选哪个角色？"的策略思考

### 支柱对齐

| 支柱 | 实现 |
|------|------|
| **粉丝幻想** | 看到喜爱的虚拟主播角色出现，情感连接 |
| **策略发现** | 选择哪个角色的策略决策 |
| **快速反馈** | 刷新/选择操作后立即视觉响应（<0.3秒） |

## Detailed Rules

### 商店状态

- 卡槽数量：**5个**
- 刷新机制：点击刷新，重新抽取5张卡
- MVP阶段：**无经济限制**，刷新免费

### 核心接口

```gdscript
# ShopSystem.gd
class_name ShopSystem

## 刷新商店（重新抽取5张卡）
func refresh_shop() -> void

## 选择角色（从商店领取，准备放置到棋盘）
func select_character(slot_index: int) -> CharacterData

## 获取当前商店卡牌
func get_shop_cards() -> Array  # Array[Variant]，支持null表示空槽

## 清空商店
func clear_shop() -> void

## 检查卡槽是否为空
func is_slot_empty(slot_index: int) -> bool
```

### 选择角色行为

```
玩家点击卡牌 → select_character() 返回 CharacterData
                ↓
         卡槽标记为空（该卡不再可用）
                ↓
         触发 shop_card_selected 信号
                ↓
         拖放系统接管 → 玩家拖动到棋盘放置
```

**重要**: 商店系统只负责"领取"角色，不负责放置。放置由**拖放交互系统**处理。

### 状态转换

```
[商店空] ──refresh_shop()──> [商店满（5张卡）]
    ↑                              │
    │                         select_character()
    │                              │
    │                              ↓
    │                        [减少（该槽变空）]
    │                              │
    └────────── clear_shop() ──────┘
```

### 数据存储

商店状态存储在 `GameState.shop_cards: Array`：
```gdscript
# 游戏状态中的商店数据
var shop_cards: Array = []  # Array[Variant]，null表示空槽

# 示例状态
shop_cards = [
    character_data_1,  # 槽0: 有角色
    null,              # 槽1: 空
    character_data_2,  # 槽2: 有角色
    null,              # 槽3: 空
    character_data_3,  # 槽4: 有角色
]
```

## Formulas

商店刷新的抽卡概率由**卡池管理系统** (`card-pool.md`) 定义。商店系统不包含独立的概率公式。

相关参数：
- 抽卡概率表：见 `card-pool.md` 的 Probability Table
- 角色星级分布：见 `card-pool.md` 的 Star Distribution

## Edge Cases

| 情况 | 处理 |
|------|------|
| 选择已空的卡槽 | 返回 null，UI显示空槽提示 |
| 卡池为空时刷新 | 空槽显示为空，不报错 |
| 刷新次数无限制 | MVP允许无限刷新 |
| 连续快速点击刷新 | 防抖处理，忽略500ms内的重复请求 |
| 商店已满时刷新 | 覆盖所有卡槽（包括未选择的卡） |

## Dependencies

| 系统 | 使用内容 | 数据格式 |
|------|----------|----------|
| 卡池管理 | 抽卡接口 | `draw_cards(count: int) -> Array[CharacterData]` |
| 游戏状态 | 商店状态存储 | `shop_cards: Array` |

**被依赖**:
- 商店UI — 显示商店卡牌
- 拖放交互 — 接收选中的角色

## Tuning Knobs

| 参数 | 默认值 | 安全范围 | 说明 |
|------|--------|----------|------|
| 卡槽数量 | 5 | 3-7 | 影响选择策略复杂度 |
| 刷新限制 | 无限制 | 无限制/3次/5次 | MVP无限制 |
| 刷新防抖时间 | 500ms | 300-1000ms | 防止快速点击 |

## Visual/Audio Requirements

| 操作 | 视觉反馈 | 音效 |
|------|----------|------|
| 刷新 | 卡牌翻转/滑入动画（<300ms） | 刷新音效 |
| 选择角色 | 卡牌上浮、发光边框 | 选择音效 |
| 空槽点击 | 轻微抖动提示无效 | 错误提示音 |

## Acceptance Criteria

- [ ] 刷新商店显示5张卡（或空槽，如卡池不足）
- [ ] 选择角色后该卡槽变空
- [ ] 商店状态与 GameState.shop_cards 同步
- [ ] 刷新操作响应时间 < 300ms
- [ ] 空槽点击有视觉提示
- [ ] 快速连续刷新被正确防抖

## Open Questions

| 问题 | 决策 | 状态 |
|------|------|------|
| 是否需要刷新次数限制？ | MVP阶段无限制 | 已决定 |
| 是否需要"锁定"功能（保护某张卡不被刷新）？ | MVP不实现 | 延后 |
