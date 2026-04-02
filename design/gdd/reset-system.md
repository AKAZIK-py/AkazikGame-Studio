# 重置系统 (Reset System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

重置系统负责**清空棋盘、重置商店、开始新局**。让玩家可以快速重新开始。

## Detailed Design

### Core Rules

```gdscript
# ResetSystem.gd
class_name ResetSystem

## 完全重置（新游戏）
func full_reset() -> void

## 重置棋盘
func reset_board() -> void

## 重置商店
func reset_shop() -> void
```

### 重置流程

1. 清空棋盘所有角色
2. 刷新商店（新卡牌）
3. 重置卡池
4. 重置回合数

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 游戏状态 | 清空所有状态 |
| 棋盘系统 | 清空棋盘 |
| 商店系统 | 刷新商店 |

## Acceptance Criteria

- [ ] 棋盘清空
- [ ] 商店刷新
- [ ] 卡池重置
- [ ] 游戏状态清零
