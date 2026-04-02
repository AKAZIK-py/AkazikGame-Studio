# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (primary)
- **Rendering**: 2D + 透视模拟（倾斜45度视角）
- **Physics**: Godot Physics (内置)

## Naming Conventions

### GDScript Standard

- **Classes**: PascalCase (e.g., `PlayerController`, `SynergyDetector`)
- **Variables**: snake_case (e.g., `move_speed`, `current_health`)
- **Functions**: snake_case (e.g., `take_damage()`, `calculate_win_rate()`)
- **Signals**: snake_case past tense (e.g., `health_changed`, `synergy_activated`)
- **Files**: snake_case matching class (e.g., `player_controller.gd`, `synergy_detector.gd`)
- **Scenes**: PascalCase matching root node (e.g., `GameBoard.tscn`, `ShopUI.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`, `GRID_SIZE`)

### Project-Specific

- **角色数据文件**: `character_[name].tres` (e.g., `character_azi.tres`)
- **羁绊数据文件**: `synergy_[type].tres` (e.g., `synergy_vr.tres`)
- **场景文件**: PascalCase (e.g., `HexBoard.tscn`, `ShopPanel.tscn`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: TBD (profile during development)
- **Memory Ceiling**: TBD (profile during development)

## Testing

- **Framework**: GUT (Godot Unit Test)
- **Minimum Coverage**: Core systems should have unit tests
- **Required Tests**: 羁绊检测、属性计算、战斗系统

## Forbidden Patterns

- 不要在 `_process()` 中进行复杂计算，使用事件驱动
- 不要硬编码数值，所有游戏数值应该来自资源文件
- 不要直接访问其他节点的内部状态，使用信号通信

## Allowed Libraries / Addons

- GUT (Godot Unit Test) — 单元测试框架
- 其他库待定，按需添加

## Architecture Decisions Log

- **ADR-0001**: 核心架构设计 (渲染方案、状态管理、数据驱动) — Accepted
