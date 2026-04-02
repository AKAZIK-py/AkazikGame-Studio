# 格子显示 (Cell Display)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

格子显示系统负责在玩家**拖动角色时**显示蜂窝格子网格和高亮可放置位置。平时棋盘不显示明显的格子边界，保持简洁美观；拖动时显示蜂窝帮助玩家确定放置位置。

## Player Fantasy

- **简洁界面**: 平时棋盘干净，不被格子线干扰
- **即时反馈**: 拖动时立即显示可用位置
- **清晰引导**: 高亮显示可放置的格子

## Detailed Design

### Core Rules

#### 显示状态

| 状态 | 触发条件 | 显示内容 |
|------|----------|----------|
| `hidden` | 无拖动 | 不显示格子 |
| `visible` | 拖动角色中 | 显示所有格子轮廓 |
| `highlight` | 拖动悬停在某格子上 | 高亮该格子 |

#### 显示逻辑

```gdscript
# CellDisplaySystem.gd
class_name CellDisplaySystem

## 显示格子（拖动开始时调用）
func show_cells() -> void

## 隐藏格子（拖动结束时调用）
func hide_cells() -> void

## 高亮指定格子
func highlight_cell(q: int, r: int) -> void

## 清除高亮
func clear_highlight() -> void
```

### States and Transitions

```
[HIDDEN] ──开始拖动──> [VISIBLE] ──悬停格子──> [HIGHLIGHT]
    ↑                      │                       │
    └──────────────────────┴───────────────────────┘
                         结束拖动
```

### Interactions with Other Systems

| 系统 | 关系 | 数据流 |
|------|------|--------|
| 棋盘系统 | 依赖 | 获取格子位置 |
| 输入管理 | 依赖 | 监听拖动事件 |
| 拖放交互 | 被依赖 | 提供显示/隐藏接口 |

## Formulas

无公式。格子位置由棋盘系统提供。

## Edge Cases

| 情况 | 处理 |
|------|------|
| 拖动到棋盘外 | 不显示格子或隐藏 |
| 快速拖动 | 立即更新高亮位置 |
| 多点触控 | 忽略额外触点 |

## Dependencies

### 上游依赖

| 系统 | 使用内容 |
|------|----------|
| 棋盘系统 | 格子坐标和位置 |
| 输入管理 | 拖动事件 |

### 下游依赖

| 系统 | 使用内容 |
|------|----------|
| 拖放交互 | 显示/隐藏格子接口 |
| 棋盘渲染 | 格子视觉渲染 |

## Tuning Knobs

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 格子边框颜色 | 半透明白色 | 格子轮廓颜色 |
| 高亮颜色 | 半透明绿色 | 可放置位置颜色 |
| 动画时间 | 0.1秒 | 显示/隐藏动画时长 |

## Visual/Audio Requirements

- 格子轮廓：细线，半透明
- 高亮效果：填充色或边框加粗
- 动画：淡入淡出

## UI Requirements

无。

## Acceptance Criteria

- [ ] 拖动开始时显示所有格子
- [ ] 拖动结束时隐藏格子
- [ ] 悬停格子时高亮
- [ ] 格子位置与棋盘系统一致

## Open Questions

| 问题 | 负责人 | 目标解决时间 |
|------|--------|--------------|
| 格子具体视觉样式？ | 美术 | 实现阶段 |
