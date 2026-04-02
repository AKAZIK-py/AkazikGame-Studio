# 拖放交互 (Drag-Drop Interaction)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

拖放交互系统负责**处理角色拖放操作**。玩家从商店拖动角色到棋盘上放置。

## Detailed Design

### 交互流程

1. 从商店拖动角色
2. 拖动过程中显示格子
3. 悬停在格子上时高亮
4. 松开放置角色

### 核心接口

```gdscript
func start_drag(character: CharacterData) -> void
func update_drag_position(position: Vector2) -> void
func end_drag() -> void
```

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 输入管理 | 拖动事件 |
| 棋盘系统 | 放置验证 |
| 格子显示 | 显示格子 |
| 角色渲染 | 拖动中的角色显示 |

## Acceptance Criteria

- [ ] 拖动开始正确响应
- [ ] 拖动中格子显示
- [ ] 放置成功/失败正确处理
