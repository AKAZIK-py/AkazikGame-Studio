# ADR-0002: 游戏数据存储格式

## Status
Accepted

## Date
2026-03-29

## Context

### Problem Statement
V-Tacit 需要存储角色数据（14个角色）和羁绊数据（9+个羁绊），这些数据需要：
- 支持频繁调整（数值平衡迭代）
- 易于编辑（非程序员也能修改）
- 类型安全（避免运行时类型错误）
- 与 Godot 引擎良好集成

### Constraints
- 引擎: Godot 4.6
- 数据量: MVP阶段约20-30个数据文件
- 编辑者: 单人开发，无专门数值策划
- 目标平台: Web优先，启动时间敏感

### Requirements
- 支持复杂嵌套结构（技能触发条件、羁绊阈值数组）
- 支持类型验证（稀有度1-5、角色定位枚举）
- 支持编辑器内预览和调试
- 加载性能可接受（<500ms）

## Decision

**选择 Godot Resource (.tres) 作为游戏数据存储格式。**

### 架构设计

```
assets/data/
├── characters/
│   ├── character_a_zi.tres      # CharacterData 资源
│   ├── character_qi_hai.tres
│   └── ...
├── synergies/
│   ├── synergy_vr.tres          # SynergyData 资源
│   ├── synergy_idol.tres
│   └── ...
└── balance/
    └── (预留: 抽卡概率、战斗参数)
```

### 数据类定义

所有数据类继承 `Resource`，使用 `@export` 注解定义字段：

```gdscript
class_name CharacterData extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_range(1, 5) var rarity: int = 1
@export_enum("output", "tank", "support") var role: String = "output"
@export var synergy_tags: Array[String] = []
```

### 加载机制

使用 Registry 模式统一加载和管理：

```gdscript
# CharacterRegistry.gd
const CHARACTER_DATA_PATH := "res://assets/data/characters/"

func _load_all_characters() -> void:
    var dir := DirAccess.open(CHARACTER_DATA_PATH)
    # 遍历 .tres 文件并 load()
    var data := load(full_path) as CharacterData
    if data.validate():
        _characters[data.id] = data
```

### 关键优势

| 特性 | Resource (.tres) | JSON |
|------|-----------------|------|
| 类型安全 | ✅ 编译时检查 | ❌ 运行时才能发现错误 |
| 编辑器集成 | ✅ Inspector 可视化编辑 | ❌ 需要外部编辑器 |
| 枚举支持 | ✅ @export_enum 下拉选择 | ❌ 手动输入字符串 |
| 范围约束 | ✅ @export_range 滑块 | ❌ 无验证 |
| 数组类型 | ✅ Array[String] 强类型 | ❌ 弱类型 |
| 内置验证 | ✅ validate() 方法 | ⚠️ 需要额外实现 |

## Alternatives Considered

### Alternative 1: JSON 文件

- **Description**: 使用 `.json` 文件存储数据，通过 `JSON.parse()` 加载
- **Pros**:
  - 通用格式，任何编辑器都能编辑
  - 可被外部工具（Excel导出、Python脚本）处理
  - Git diff 更友好
- **Cons**:
  - 无类型安全，拼写错误运行时才报错
  - 需要手动实现验证逻辑
  - 枚举值无法在编辑器中下拉选择
- **Rejection Reason**: 单人开发不需要跨工具协作，类型安全和编辑器集成更重要

### Alternative 2: CSV 表格

- **Description**: 使用 `.csv` 文件，类似传统游戏配置表
- **Pros**:
  - Excel/WPS 直接编辑，非程序员友好
  - 批量修改方便
- **Cons**:
  - 不支持嵌套结构（羁绊阈值数组）
  - 无类型信息
  - 需要额外的解析和转换代码
- **Rejection Reason**: 羁绊阈值、技能触发条件等嵌套结构难以用表格表达

### Alternative 3: GDScript 常量

- **Description**: 直接在 `.gd` 文件中定义 `const` 数据
- **Pros**:
  - 最简单的实现
  - 完全类型安全
- **Cons**:
  - 修改数据需要重新编译
  - 无法在编辑器中可视化编辑
  - 不适合频繁调整的平衡数值
- **Rejection Reason**: 数据与代码耦合，不符合数据驱动原则

## Consequences

### Positive
- **开发效率高**: Inspector 编辑器直接修改数值，无需切换工具
- **类型安全**: @export 装饰器提供编译时类型检查
- **验证内置**: 每个数据类有 `validate()` 方法，加载时自动检查
- **热重载**: 修改 .tres 文件后可重新加载，无需重启游戏

### Negative
- **Godot 特有格式**: .tres 文件无法用其他工具编辑
- **Git diff 不友好**: 二进制/文本混合格式，冲突解决困难
- **学习曲线**: 新贡献者需要了解 Godot Resource 系统

### Risks
- **文件冲突**: 多人协作时 .tres 文件容易产生合并冲突
  - *Mitigation*: MVP阶段单人开发，风险可控；后续可考虑 YAML/JSON + 导入流程
- **数据迁移**: 如果未来需要切换格式，需要编写转换脚本
  - *Mitigation*: Godot 提供 ResourceSaver/ResourceLoader API，导出为 JSON 并不困难

## Performance Implications

- **CPU**: 加载时间可忽略（14个角色 + 9个羁绊 < 50ms）
- **Memory**: 每个数据文件约 1-2KB，总计 < 100KB
- **Load Time**: 启动时一次性加载，预计 < 100ms
- **Network**: Web 版需要下载所有 .tres 文件，但体积小影响有限

## Migration Plan

初始架构，无需迁移。

如需未来切换到 JSON：
1. 编写导出脚本：`Resource → JSON`
2. 实现 `JSON → Resource` 加载器
3. 在 Registry 中替换加载逻辑

## Validation Criteria

- [x] 14个角色数据文件正确加载
- [x] 9个羁绊数据文件正确加载
- [x] Inspector 中可直接编辑数据
- [x] 加载时自动验证数据有效性
- [x] 修改 .tres 文件后可热重载

## Related Decisions

- ADR-0001: 核心架构设计（数据驱动原则）
- design/gdd/character-data.md - 角色数据结构定义
- design/gdd/synergy-data.md - 羁绊数据结构定义
