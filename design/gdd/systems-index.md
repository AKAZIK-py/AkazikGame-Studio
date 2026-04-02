# Systems Index: V-Tacit（虚拟羁绊）

> **Status**: Draft
> **Created**: 2026-03-27
> **Last Updated**: 2026-03-27
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

V-Tacit 是一款面向虚拟主播粉丝的自走棋MVP，核心玩法是羁绊组合策略。玩家通过商店抽取角色，放置到六边形棋盘上，激活羁绊效果，与AI对战验证胜率。

本游戏需要 **19个系统**，分为 Foundation（基础层）、Core（核心层）、Presentation（呈现层）三个层级。核心系统包括：棋盘系统、商店系统、羁绊系统、战斗系统、角色系统。设计遵循"粉丝幻想"和"快速反馈"两大支柱，确保每次操作都有视觉响应。

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 角色数据 | Foundation | MVP | Designed | design/gdd/character-data.md | — |
| 2 | 羁绊数据 | Foundation | MVP | Designed | design/gdd/synergy-data.md | — |
| 3 | 游戏状态 | Foundation | MVP | Designed | design/gdd/game-state.md | — |
| 4 | 输入管理 | Foundation | MVP | Designed | design/gdd/input-manager.md | — |
| 5 | 棋盘系统 | Core | MVP | Approved | design/gdd/board-system.md | 游戏状态 |
| 6 | 格子显示 | Core | MVP | Designed | design/gdd/cell-display.md | 棋盘系统, 输入管理 |
| 7 | 卡池管理 | Core | MVP | Designed | design/gdd/card-pool.md | 角色数据, 游戏状态 |
| 8 | 商店系统 | Core | MVP | Approved | design/gdd/shop-system.md | 卡池管理, 游戏状态 |
| 9 | 羁绊检测 | Core | MVP | Approved | design/gdd/synergy-detection.md | 角色数据, 羁绊数据, 棋盘系统 |
| 10 | 羁绊效果 | Core | MVP | Approved | design/gdd/synergy-effect.md | 羁绊检测, 羁绊数据 |
| 11 | 属性计算 | Core | MVP | Designed | design/gdd/attribute-calculation.md | 角色数据, 羁绊效果 |
| 12 | 战斗系统 | Core | MVP | Approved | design/gdd/battle-system.md | 属性计算, 游戏状态 |
| 13 | 重置系统 | Core | MVP | Designed | design/gdd/reset-system.md | 游戏状态, 棋盘系统, 商店系统 |
| 14 | 角色渲染 | Presentation | MVP | Designed | design/gdd/character-rendering.md | 角色数据 |
| 15 | 棋盘渲染 | Presentation | MVP | Designed | design/gdd/board-rendering.md | 棋盘系统, 格子显示 |
| 16 | 拖放交互 | Presentation | MVP | Designed | design/gdd/drag-drop-interaction.md | 输入管理, 棋盘系统, 格子显示, 角色渲染 |
| 17 | 商店UI | Presentation | MVP | Designed | design/gdd/shop-ui.md | 商店系统, 角色渲染 |
| 18 | 羁绊反馈 | Presentation | MVP | Designed | design/gdd/synergy-feedback.md | 羁绊检测, 羁绊效果 |
| 19 | 战斗结果 | Presentation | MVP | Designed | design/gdd/battle-result.md | 战斗系统 |

---

## Categories

| Category | Description | Systems in This Project |
|----------|-------------|------------------------|
| **Foundation** | 最底层系统，无依赖，为其他系统提供基础 | 角色数据, 羁绊数据, 游戏状态, 输入管理 |
| **Core** | 核心玩法逻辑，游戏规则实现 | 棋盘系统, 格子显示, 卡池管理, 商店系统, 羁绊检测, 羁绊效果, 属性计算, 战斗系统, 重置系统 |
| **Presentation** | 玩家界面，视觉反馈 | 棋盘渲染, 拖放交互, 商店UI, 羁绊反馈, 战斗结果, 角色渲染 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | 核心循环必需，测试"是否有趣" | 首个可玩原型 | 立即设计 |

> 注：所有19个系统均为MVP优先级，因为本项目的MVP范围已覆盖完整核心循环。后续版本（养成、PVP、排位）不在当前MVP范围内。

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **角色数据** — 定义角色属性结构、羁绊标签格式，多个系统依赖
2. **羁绊数据** — 定义羁绊类型、触发条件、效果参数，羁绊系统依赖
3. **游戏状态** — 全局状态容器，管理阶段、阵容、商店状态
4. **输入管理** — 原始输入捕获，拖放交互依赖

### Core Layer (depends on foundation)

1. **棋盘系统** — depends on: 游戏状态 — 六边形位置管理、放置验证
2. **格子显示** — depends on: 棋盘系统, 输入管理 — 拖动时显示蜂窝、高亮可放置位置
3. **卡池管理** — depends on: 角色数据, 游戏状态 — 角色池定义、抽卡概率、已选追踪
4. **商店系统** — depends on: 卡池管理, 游戏状态 — 刷新、展示、选择角色
5. **羁绊检测** — depends on: 角色数据, 羁绊数据, 棋盘系统 — 检测棋盘上的羁绊组合
6. **羁绊效果** — depends on: 羁绊检测, 羁绊数据 — 应用羁绊效果、数值加成计算
7. **属性计算** — depends on: 角色数据, 羁绊效果 — 计算最终战斗属性
8. **战斗系统** — depends on: 属性计算, 游戏状态 — 胜率计算、结果判定
9. **重置系统** — depends on: 游戏状态, 棋盘系统, 商店系统 — 清空棋盘、重置商店

### Presentation Layer (depends on core)

1. **角色渲染** — depends on: 角色数据 — 显示角色立绘、选中状态
2. **棋盘渲染** — depends on: 棋盘系统, 格子显示 — 2D透视模拟云顶风格、背景装饰
3. **拖放交互** — depends on: 输入管理, 棋盘系统, 格子显示, 角色渲染 — 拖放操作、放置反馈
4. **商店UI** — depends on: 商店系统, 角色渲染 — 卡牌展示、刷新按钮、选择反馈
5. **羁绊反馈** — depends on: 羁绊检测, 羁绊效果 — 羁绊激活视觉提示
6. **战斗结果** — depends on: 战斗系统 — 胜率显示、结果展示

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | 角色数据 | MVP | Foundation | game-designer, systems-designer | M |
| 2 | 羁绊数据 | MVP | Foundation | game-designer, systems-designer | M |
| 3 | 游戏状态 | MVP | Foundation | gameplay-programmer | S |
| 4 | 输入管理 | MVP | Foundation | gameplay-programmer | S |
| 5 | 棋盘系统 | MVP | Core | game-designer, gameplay-programmer | M |
| 6 | 格子显示 | MVP | Core | game-designer, gameplay-programmer | S |
| 7 | 卡池管理 | MVP | Core | game-designer | S |
| 8 | 商店系统 | MVP | Core | game-designer, gameplay-programmer | M |
| 9 | 羁绊检测 | MVP | Core | game-designer, gameplay-programmer | M |
| 10 | 羁绊效果 | MVP | Core | game-designer, systems-designer | M |
| 11 | 属性计算 | MVP | Core | systems-designer | S |
| 12 | 战斗系统 | MVP | Core | game-designer, systems-designer | M |
| 13 | 重置系统 | MVP | Core | gameplay-programmer | S |
| 14 | 角色渲染 | MVP | Presentation | ui-programmer, art-director | S |
| 15 | 棋盘渲染 | MVP | Presentation | ui-programmer, art-director | M |
| 16 | 拖放交互 | MVP | Presentation | ui-programmer, ux-designer | M |
| 17 | 商店UI | MVP | Presentation | ui-programmer, ux-designer | S |
| 18 | 羁绊反馈 | MVP | Presentation | ui-programmer, technical-artist | S |
| 19 | 战斗结果 | MVP | Presentation | ui-programmer | S |

**Effort Legend**: S = 1 session, M = 2-3 sessions, L = 4+ sessions

---

## Circular Dependencies

- **None found** ✓

所有依赖单向流动，无循环依赖。

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|------------------|------------|
| 角色数据 | Design | 数值策划需要多次迭代才能平衡，变更影响6+系统 | 数据外置为JSON/Resource，定义稳定接口，内部实现可变 |
| 羁绊数据 | Design | 羁绊效果需要测试验证才能定型，变更影响战斗平衡 | 效果参数化，预留调参接口，单元测试覆盖计算链 |
| 羁绊效果 | Design | 触发式羁绊机制复杂度可能超出预期 | 早期原型验证 (`/prototype 羁绊系统`) |
| 战斗系统 | Design | 纯数值战斗可能缺乏"爽感" | MVP验证核心假设，收集反馈后决定是否添加战斗动画 |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 19 |
| Design docs started | 19 |
| Design docs reviewed | 5 |
| Design docs approved | 5 |
| MVP systems designed | 19/19 |

---

## 🎉 ALL SYSTEMS DESIGNED! 🎉

所有 19 个系统 GDD 完成！

### Foundation Layer (4/4) ✓
- 角色数据
- 羁绊数据
- 游戏状态
- 输入管理

### Core Layer (9/9) ✓
- 棋盘系统
- 格子显示
- 卡池管理
- 商店系统
- 羁绊检测
- 羁绊效果
- 属性计算
- 战斗系统
- 重置系统

### Presentation Layer (6/6) ✓
- 角色渲染
- 棋盘渲染
- 拖放交互
- 商店UI
- 羁绊反馈
- 战斗结果

---

## Design Notes

### 待定内容（需要迭代调整）

- **角色内容**：角色数量、名字、属性数值、技能描述待定
- **羁绊内容**：羁绊类型、触发条件、效果参数待定
- **视觉风格**：棋盘装饰、角色立绘风格、UI配色方案待定

### 设计约束

- 渲染方案：2D + 透视模拟（倾斜45度视角），不使用真3D
- 交互特点：蜂窝格子仅在拖动棋子时显示
- 数值计算：纯数值计算胜率，无实时战斗动画（MVP阶段）

---

## Next Steps

- [x] 系统枚举完成
- [x] 依赖映射完成
- [x] 优先级分配完成
- [ ] 设计第一个系统：`/design-system 角色数据`
- [ ] 依次设计其他系统（按 Recommended Design Order）
- [ ] 每个 GDD 完成后运行 `/design-review`
- [ ] 所有 MVP 系统设计完成后运行 `/gate-check pre-production`
- [ ] 原型高风险系统 `/prototype 羁绊系统`
