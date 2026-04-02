# 羁绊反馈 (Synergy Feedback)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

羁绊反馈系统负责**显示羁绊激活的视觉提示**。

## Detailed Design

### 反馈元素

- 羁绊激活图标
- 羁绊面板（显示所有羁绊状态）
- 激活动画/特效

### 显示时机

- 放置角色后检测羁绊
- 羁绊激活时显示特效
- 羁绊面板实时更新

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 羁绊检测 | 激活的羁绊 |
| 羁绊效果 | 羁绊效果参数 |

## Acceptance Criteria

- [ ] 羁绊激活正确显示
- [ ] 羁绊面板正确更新
