# 羁绊检测 (Synergy Detection)

> **Status**: Approved
> **Author**: user + agents
> **Last Updated**: 2026-04-02
> **Implements Pillar**: 粉丝幻想、策略发现、快速反馈

## Overview

羁绊检测系统负责**检测棋盘上激活的羁绊组合**。当玩家放置角色后，系统自动识别哪些羁绊被激活，并确定激活等级。核心职责是：统计标签 → 匹配阈值 → 输出激活列表。

## Player Fantasy

玩家在放置角色后，**立即看到羁绊激活的反馈**。这种"发现"的感觉是核心体验：

- **期待感**：放置角色后想知道"这次激活了什么羁绊？"
- **惊喜感**：发现隐藏羁绊或组合羁绊时的惊喜
- **掌控感**：理解羁绊机制后可以主动构建配队

符合**快速反馈**支柱：角色放置后 **≤0.5秒** 内显示羁绊激活结果。

## Detailed Rules

### 数据结构

```gdscript
# 激活的羁绊信息
class ActivatedSynergy:
    var synergy_id: String          # 羁绊ID，如 "vr", "idol"
    var count: int                  # 当前角色数量
    var level: int                  # 激活等级 (0=未激活, 1=一级, 2=二级...)
    var affected_characters: Array  # 受影响的角色列表
    var bonus_value: float          # 加成数值（由羁绊效果系统使用）

# 检测结果
class DetectionResult:
    var activated: Array[ActivatedSynergy]  # 所有激活的羁绊
    var pending: Array[String]              # 差1个即可激活的羁绊（UI提示用）
```

### 检测流程

```
1. 触发条件：棋盘状态变化（角色放置/移除）
2. 收集标签：遍历棋盘角色，收集所有synergy_tags
3. 统计计数：按标签分组统计角色数量
4. 匹配阈值：对比synergy-data中的thresholds，确定激活等级
5. 处理特殊类型：万能羁绊、组合羁绊、隐藏羁绊
6. 输出结果：返回DetectionResult
```

### 检测算法（伪代码）

```gdscript
func detect_active_synergies(board: BoardSystem) -> DetectionResult:
    var result = DetectionResult.new()
    var tag_counts: Dictionary = {}  # {tag: count}

    # 1. 统计标签
    for character in board.get_all_characters():
        for tag in character.synergy_tags:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1

    # 2. 处理万能羁绊（狍子）
    if "deer" in tag_counts:
        var wildcard_count = tag_counts["deer"]
        tag_counts.erase("deer")
        # 分配万能角色到最需要的羁绊
        var assignment = resolve_wildcard_assignment(tag_counts, wildcard_count)
        for tag in assignment:
            tag_counts[tag] += assignment[tag]

    # 3. 匹配阈值
    for synergy_id in get_all_synergy_ids():
        var synergy_data = SynergyRegistry.get(synergy_id)
        var count = tag_counts.get(synergy_id, 0)

        # 检查组合羁绊（如EOE姐妹）
        if synergy_data.type == SynergyType.COMBO:
            if check_combo_condition(synergy_data.required_characters, board):
                result.activated.append(create_combo_synergy(synergy_id, board))
            continue

        # 普通羁绊阈值检测
        var level = get_activation_level(count, synergy_data.thresholds)
        if level > 0:
            result.activated.append(create_activated_synergy(synergy_id, count, level))
        elif count >= synergy_data.thresholds[0] - 1:
            result.pending.append(synergy_id)

    return result
```

### 羁绊类型处理

| 类型 | 检测方式 | 示例 |
|------|----------|------|
| **normal** | 计数 ≥ 阈值 | VR: 2/4/6 |
| **wildcard** | 可分配到任意羁绊 | 狍子 |
| **combo** | 特定角色都在场 | EOE姐妹: 露早+柚恩 |
| **hidden** | 满足条件后解锁 | 大厂: 未在UI显示 |

### 万能羁绊分配算法

```gdscript
func resolve_wildcard_assignment(tag_counts: Dictionary, wildcard_count: int) -> Dictionary:
    var assignment: Dictionary = {}
    var remaining = wildcard_count

    # 按优先级分配：最接近阈值的羁绊优先
    var candidates = []
    for tag in tag_counts:
        var synergy = SynergyRegistry.get(tag)
        if synergy.type != SynergyType.NORMAL:
            continue
        var count = tag_counts[tag]
        for threshold in synergy.thresholds:
            var gap = threshold - count
            if gap > 0 and gap <= remaining:
                candidates.append({tag=tag, gap=gap, threshold=threshold})

    # 按gap升序排序（最接近阈值的优先）
    candidates.sort_custom(func(a, b): return a.gap < b.gap)

    # 分配
    for candidate in candidates:
        if remaining <= 0:
            break
        var needed = candidate.gap
        var allocated = min(needed, remaining)
        assignment[candidate.tag] = assignment.get(candidate.tag, 0) + allocated
        remaining -= allocated

    return assignment
```

## Formulas

### 激活等级计算

```
activation_level(count, thresholds) = max(i) where count >= thresholds[i]

示例：
- VR阈值 [2, 4, 6]
- count=1 → level=0（未激活）
- count=2 → level=1
- count=4 → level=2
- count=6 → level=3
- count=8 → level=3（超过最高阈值仍为最高等级）
```

### 万能羁绊优先级评分

```
priority_score = (threshold - count) / threshold

越小的score优先级越高（最接近阈值）
```

### 检测触发时机

| 事件 | 是否触发检测 | 说明 |
|------|-------------|------|
| 角色放置 | ✓ | 主要触发点 |
| 角色移除 | ✓ | 需重新计算 |
| 角色交换位置 | ✗ | 不改变羁绊计数 |
| 商店刷新 | ✗ | 与棋盘无关 |

## Edge Cases

| 边界情况 | 处理方式 |
|----------|----------|
| 空棋盘 | 返回空结果，无激活羁绊 |
| 角色无羁绊标签 | 该角色不参与羁绊计数 |
| 多个万能羁绊 | 依次分配，先满足最高优先级 |
| 组合羁绊角色移除 | 整个组合羁绊失效 |
| 隐藏羁绊 | 正常检测但不显示在pending列表 |
| 阈值跨级 | count=5时VR激活等级仍为2（需6才到3） |
| 同一角色多标签 | 该角色同时计入所有标签的计数 |

## Dependencies

| 系统 | 使用内容 | 数据格式 |
|------|----------|----------|
| 角色数据 | 角色羁绊标签 | `synergy_tags: Array[String]` |
| 羁绊数据 | 羁绊阈值、类型 | `thresholds: Array[int]`, `type: SynergyType` |
| 棋盘系统 | 棋盘角色位置 | `get_all_characters() -> Array[CharacterInstance]` |

**被依赖**:
- 羁绊效果系统 — 需要检测结果来应用效果
- 羁绊反馈UI — 需要检测结果来显示激活状态

## Tuning Knobs

| 参数 | 默认值 | 安全范围 | 影响 |
|------|--------|----------|------|
| 检测延迟 | 0ms | 0-100ms | 角色放置后延迟多久检测（用于动画） |
| 万能优先级算法 | closest | [closest, manual] | closest=自动分配最接近阈值的 |
| 组合羁绊容错 | false | true/false | 是否允许组合羁绊差1人仍激活 |

## Acceptance Criteria

- [ ] 放置角色后0.5秒内显示羁绊激活结果
- [ ] 正确统计各羁绊角色数量（单元测试验证）
- [ ] 正确判断羁绊激活等级（VR: 2人=1级, 4人=2级, 6人=3级）
- [ ] 万能羁绊（狍子）正确分配到最需要的羁绊
- [ ] 组合羁绊（EOE姐妹）正确检测特定角色是否都在场
- [ ] 隐藏羁绊不显示在UI但正确参与计算
- [ ] 角色移除后羁绊状态正确更新

## Open Questions

无。
