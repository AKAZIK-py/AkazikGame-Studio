# 角色渲染 (Character Rendering)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 粉丝幻想

## Overview

角色渲染系统负责**显示角色立绘和选中状态**。

## Detailed Design

### 核心功能

- 显示角色立绘（AI生成）
- 显示角色名称
- 显示星级
- 显示选中/悬停状态

### 渲染层级

```
背景 → 棋盘 → 格子 → 角色立绘 → UI
```

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 角色数据 | 角色显示名称、星级 |

## Acceptance Criteria

- [ ] 角色立绘正确显示
- [ ] 星级正确显示
- [ ] 选中状态正确响应
