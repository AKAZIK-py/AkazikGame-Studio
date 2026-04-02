# 商店UI (Shop UI)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

商店UI系统负责**展示商店卡牌和刷新按钮**。

## Detailed Design

### UI元素

- 5个卡牌槽位
- 刷新按钮
- 角色信息（名称、星级、羁绊、技能）

### 布局

商店位于屏幕底部，横向排列5张卡牌。

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 商店系统 | 卡牌数据 |
| 角色渲染 | 卡牌显示 |

## Acceptance Criteria

- [ ] 卡牌正确显示
- [ ] 刷新按钮响应
- [ ] 卡牌选择响应
