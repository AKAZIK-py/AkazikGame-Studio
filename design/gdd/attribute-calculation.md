# 属性计算 (Attribute Calculation)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-03-27
> **Implements Pillar**: 策略发现

## Overview

属性计算系统负责**计算角色的最终战斗属性**。它整合基础属性和羁绊加成，为战斗系统提供输入。

## Detailed Design

### Core Rules

```gdscript
# AttributeCalculationSystem.gd
class_name AttributeCalculationSystem

## 计算角色的最终属性
func calculate_final_attributes(character: CharacterInstance) -> Dictionary

## 获取攻击力（基础 + 羁绊加成）
func get_final_attack(character: CharacterInstance) -> int

## 获取生命值（基础 + 羁绊加成）
func get_final_health(character: CharacterInstance) -> int
```

### 计算公式

```
最终攻击力 = 基础攻击力 × (1 + 羁绊攻击加成%)
最终生命值 = 基础生命值 × (1 + 羁绊生命加成%)
```

### 属性来源

| 来源 | 提供者 |
|------|--------|
| 基础属性 | 角色数据 |
| 羁绊加成 | 羁绊效果系统 |

## Dependencies

| 系统 | 使用内容 |
|------|----------|
| 角色数据 | 基础属性 |
| 羁绊效果 | 羁绊加成 |

## Acceptance Criteria

- [ ] 基础属性正确读取
- [ ] 羁绊加成正确应用
- [ ] 最终属性计算正确
