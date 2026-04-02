# 战斗结果 (Battle Result)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 快速反馈

## Overview

战斗结果系统负责**显示战斗胜率和结果**。

## Detailed Design

### 显示内容

- 胜率百分比
- 胜负结果
- 继续按钮

### 界面

战斗结果弹窗，显示：
- 玩家阵容战力
- 敌方阵容战力
- 计算胜率
- 最终结果

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 战斗系统 | 战斗结果数据 |

## Acceptance Criteria

- [ ] 胜率正确显示
- [ ] 结果正确显示
- [ ] 继续按钮响应
