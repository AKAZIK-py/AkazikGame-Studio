# ADR-0001: 核心架构设计

## Status
Accepted

## Date
2026-03-28

## Context

### Problem Statement
V-Tacit（虚拟羁绊）是一款VTuber主题的自走棋MVP游戏。需要确定核心架构方案，包括：
1. 渲染方案：如何实现云顶之弈风格的视觉效果
2. 状态管理：如何管理游戏状态和数据流
3. 数据驱动：如何实现数值可配置

### Constraints
- **引擎**: Godot 4.6
- **语言**: GDScript (主要)
- **目标平台**: Web MVP优先，后续PC
- **性能目标**: 60fps / 16.6ms帧预算
- **MVP范围**: 核心循环可玩，无需完整内容

### Requirements
- 支持32格六边形棋盘渲染
- 支持14个角色的数据管理
- 支持羁绊检测和效果应用
- 支持商店刷新和抽卡概率
- 支持纯数值战斗计算
- 所有游戏数值可配置（外部资源文件）

## Decision

### 1. 渲染方案：2D + 透视模拟

使用2D节点模拟云顶之弈的倾斜视角效果，不使用真3D。

**实现方式**:
- 棋盘使用 `Node2D` + 自定义绘制
- 角色使用 `Sprite2D` + Y-sort排序
- 通过缩放模拟深度（前排大、后排小）
- 蜂窝格子在拖动时显示，平时隐藏

**坐标系统**:
- 六边形使用 Axial 坐标系 (q, r)
- 屏幕坐标转换公式在 `board-system.md` 定义

### 2. 状态管理：集中式 GameState

采用单一数据源模式，所有游戏状态存储在 `GameState` 资源中。

**架构图**:
```
┌─────────────────────────────────────────────────────────┐
│                      GameState                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   board     │  │   shop      │  │  synergies  │    │
│  │  (棋盘状态)  │  │  (商店状态)  │  │ (羁绊状态)  │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
│  ┌─────────────┐  ┌─────────────┐                      │
│  │  card_pool  │  │   battle    │                      │
│  │ (卡池状态)   │  │ (战斗状态)  │                      │
│  └─────────────┘  └─────────────┘                      │
└─────────────────────────────────────────────────────────┘
          │
          │ Signals (状态变化通知)
          ▼
┌─────────────────────────────────────────────────────────┐
│                     UI Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │ BoardRender │  │  ShopUI     │  │SynergyPanel │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

**核心原则**:
- GameState 是唯一状态源
- UI 层只读状态，通过信号响应变化
- 状态修改通过系统层方法进行

### 3. 数据驱动：Resource 文件外部化

所有游戏数值使用 Godot Resource (.tres) 文件定义。

**数据文件结构**:
```
assets/data/
├── characters/
│   ├── character_xiao_ke.tres
│   ├── character_azi.tres
│   └── ...
├── synergies/
│   ├── synergy_vr.tres
│   ├── synergy_idol.tres
│   └── ...
└── balance/
    ├── probability.tres     # 抽卡概率
    └── battle_params.tres   # 战斗参数
```

**加载流程**:
1. 游戏启动时加载所有资源到 Registry
2. Registry 提供查询接口
3. 系统层从 Registry 获取数据

### 4. 信号架构：事件驱动通信

使用 Godot 信号实现系统间通信，避免紧耦合。

**核心信号**:
```gdscript
# GameState 信号
signal board_changed()        # 棋盘变化
signal shop_refreshed()       # 商店刷新
signal synergy_activated(synergy_id: String, level: int)
signal battle_completed(result: Dictionary)

# 系统层信号
signal character_placed(character: CharacterData, q: int, r: int)
signal character_removed(q: int, r: int)
signal shop_card_selected(slot_index: int)
```

## Alternatives Considered

### Alternative 1: 真3D渲染
- **Description**: 使用 Godot 的 3D 功能渲染棋盘
- **Pros**: 更真实的视觉效果，摄像机控制灵活
- **Cons**: 开发复杂度高，Web端性能压力大，与"简单MVP"目标不符
- **Rejection Reason**: MVP阶段优先快速验证核心玩法，视觉可以后续迭代

### Alternative 2: 分散式状态管理
- **Description**: 每个系统管理自己的状态
- **Pros**: 系统独立性强
- **Cons**: 状态同步困难，容易产生不一致，调试困难
- **Rejection Reason**: 集中式状态更容易调试和维护

### Alternative 3: 硬编码数值
- **Description**: 直接在代码中定义数值
- **Pros**: 开发初期更快
- **Cons**: 调整需要改代码，不利于平衡迭代
- **Rejection Reason**: 数值需要频繁调整，外部化配置更合理

## Consequences

### Positive
- **开发效率高**: 2D方案开发速度快，原型验证阶段足够
- **易于调试**: 集中式状态管理便于追踪问题
- **灵活调参**: 数据驱动设计支持快速迭代
- **Web友好**: 2D渲染在Web端性能压力小

### Negative
- **视觉上限有限**: 2D透视模拟无法达到真3D的视觉深度
- **状态管理复杂度**: 随着系统增加，GameState 会变得庞大
- **需要数据验证**: 外部资源文件可能出现配置错误

### Risks
- **状态同步问题**: 多个系统同时修改状态可能产生冲突
  - *Mitigation*: 使用信号通知，确保状态修改经过统一入口
- **资源加载时间**: 大量 .tres 文件可能增加启动时间
  - *Mitigation*: MVP阶段数据量小，影响可忽略

## Performance Implications

- **CPU**: 2D渲染CPU开销低，预计< 5ms/帧
- **Memory**: 14个角色 + 10个羁绊数据，预计< 5MB
- **Load Time**: 资源加载预计< 500ms
- **Network**: MVP阶段无网络需求

## Migration Plan

初始架构，无需迁移。

## Validation Criteria

- [ ] 32格棋盘正确渲染，拖动时格子显示
- [ ] 商店刷新显示5张卡，概率分布符合设计
- [ ] 羁绊激活正确检测和显示
- [ ] 战斗计算正确输出胜率
- [ ] 所有数值可通过资源文件调整

## Related Decisions

- design/gdd/game-state.md - 状态管理详细设计
- design/gdd/board-system.md - 六边形坐标系统
- .claude/docs/technical-preferences.md - 命名规范和性能预算
