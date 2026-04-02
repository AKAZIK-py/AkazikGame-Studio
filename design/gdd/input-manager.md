# 输入管理 (Input Manager)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

输入管理系统负责捕获和处理玩家的鼠标/触摸输入，为拖放交互系统提供输入事件。它是 MVP 的**交互基础**。

## Player Fantasy

本系统是基础设施，玩家不会直接感知。但通过流畅的输入响应，确保"快速反馈"支柱的实现。

## Detailed Design

### Core Rules

#### 输入类型

| 输入类型 | 触发条件 | 用途 |
|----------|----------|------|
| `click` | 鼠标点击/触摸 | 选择角色、点击按钮 |
| `drag_start` | 按下并移动 | 开始拖动角色 |
| `drag_move` | 拖动中移动 | 更新拖动位置 |
| `drag_end` | 松开 | 放置角色 |
| `hover` | 鼠标悬停 | 显示提示信息 |

#### 输入事件结构

```gdscript
# InputEvent.gd
class_name InputEventData

var type: String           # click / drag_start / drag_move / drag_end / hover
var position: Vector2      # 屏幕坐标
var target: Node           # 点击的目标节点（如果有）
var delta: Vector2         # 移动增量（仅drag_move）
```

### States and Transitions

```
[IDLE] ──按下──> [PRESSED] ──移动──> [DRAGGING] ──松开──> [IDLE]
   │                │                      │
   └────────────────┴──────────────────────┘
                    点击/取消
```

### Interactions with Other Systems

| 系统 | 关系 |
|------|------|
| 拖放交互 | 输入管理 → 拖放交互（提供输入事件） |
| 格子显示 | 输入管理 → 格子显示（触发显示蜂窝） |

## Formulas

无公式。输入管理是事件驱动系统。

## Edge Cases

| 情况 | 处理 |
|------|------|
| 触摸和鼠标同时操作 | 以第一个输入为准 |
| 拖动到屏幕外 | 取消拖动 |
| 多点触控 | MVP不支持，忽略额外触点 |

## Dependencies

### 上游依赖
无。

### 下游依赖
- 拖放交互
- 格子显示

## Tuning Knobs

| 参数 | 默认值 | 说明 |
|------|--------|------|
| 拖动判定距离 | 10px | 移动超过此距离才算拖动 |
| 点击判定时间 | 300ms | 超过此时间才算长按 |

## Visual/Audio Requirements

无。

## UI Requirements

无。

## Acceptance Criteria

- [ ] 点击事件正确触发
- [ ] 拖动事件正确触发（开始、移动、结束）
- [ ] 悬停事件正确触发
- [ ] 触摸和鼠标输入都支持

## Open Questions

无。
