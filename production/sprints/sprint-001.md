# Sprint 1 -- Foundation & Board System

**Start Date**: 2026-03-28
**End Date**: 2026-04-04 (7 days)

## Sprint Goal

建立游戏基础架构，实现数据层和棋盘系统，确保核心交互可运行。

## Capacity

- **Total days**: 7
- **Buffer (20%)**: 1.4 days
- **Available**: 5.6 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T1 | 创建角色数据资源文件 | gameplay-programmer | 0.5 | GDD完成 | 14个角色.tres文件加载成功 |
| T2 | 创建羁绊数据资源文件 | gameplay-programmer | 0.5 | GDD完成 | 10个羁绊.tres文件加载成功 |
| T3 | 实现GameState单例 | gameplay-programmer | 0.5 | 无 | 状态读写正常，信号触发正确 |
| T4 | 实现CharacterRegistry | gameplay-programmer | 0.5 | T1 | 可查询所有角色，按条件筛选 |
| T5 | 实现SynergyRegistry | gameplay-programmer | 0.5 | T2 | 可查询所有羁绊，获取阈值 |
| T6 | 实现六边形棋盘系统 | gameplay-programmer | 1.0 | T3 | 32格棋盘，放置/移除/移动正常 |
| T7 | 实现棋盘坐标转换 | gameplay-programmer | 0.5 | T6 | 像素↔六边形坐标转换正确 |
| T8 | 实现输入管理器 | gameplay-programmer | 0.5 | 无 | 鼠标/触摸事件正确分发 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T9 | 基础棋盘渲染 | ui-programmer | 1.0 | T6 | 棋盘可视化显示（简单矩形占位） |
| T10 | 角色数据编辑器 | tools-programmer | 0.5 | T1 | 可在编辑器中修改角色数据 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|-------------|-------------------|
| T11 | 单元测试框架搭建 | qa-tester | 0.5 | 无 | GUT配置完成，可运行测试 |

## Carryover from Previous Sprint

无（首个冲刺）

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 六边形坐标计算错误 | Medium | High | 复用原型验证代码 |
| Godot 4.6 API差异 | Low | Medium | 参考engine-reference文档 |
| 数据格式设计不当 | Medium | Medium | 原型已验证，可复用 |

## Dependencies on External Factors

- 无

## Definition of Done for this Sprint

- [ ] 所有Must Have任务完成
- [ ] 角色和羁绊数据可从资源文件加载
- [ ] 棋盘可正确放置和移除角色
- [ ] 坐标转换验证通过
- [ ] 代码遵循命名规范
- [ ] 基础测试覆盖核心逻辑

## Notes

- 本冲刺聚焦Foundation层和棋盘系统（Core层第一个系统）
- 视觉表现使用占位符，后续冲刺优化
- 参考 `prototypes/` 目录的原型代码

## Next Sprint Preview

- Sprint 2: 商店系统、卡池管理
- Sprint 3: 羁绊检测、羁绊效果、属性计算
- Sprint 4: 战斗系统、UI集成
