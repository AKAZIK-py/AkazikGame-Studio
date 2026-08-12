# Contributing Guide

欢迎为 OpenClaw Agent Workspace 贡献代码或文档！

## 贡献流程

### 1. 发现问题或提出改进

- 使用 `.github/ISSUE_TEMPLATE/gameplay-feedback.yml` 提交体验反馈
- 使用 `.github/ISSUE_TEMPLATE/code-contribution.yml` 提交代码贡献提案

### 2. 讨论方案

在 Issue 中讨论技术方案、评估可行性，确认任务范围和验收标准。

### 3. 编写规格文档

使用 `docs/templates/spec.md` 模板编写详细规格文档，包含：
- 背景与目标
- 功能范围
- 技术设计
- 实现计划

### 4. 编写执行计划

使用 `docs/templates/plan.md` 模板编写执行计划，明确：
- 执行步骤
- 预期结果
- 回滚方案
- 进度跟踪

### 5. 实现代码

遵循以下原则：
- 创建新分支（命名规范：`feature/<feature-name>` 或 `fix/<bug-name>`）
- 保持代码简洁
- 添加必要的测试
- 更新文档

### 6. 提交证据

使用 `docs/templates/evidence.md` 模板提交验收证据，包含：
- 功能演示
- 测试结果
- 回归检查

### 7. 创建PR

使用 `.github/pull_request_template.md` 模板创建PR，包含：
- 摘要
- 变更清单
- 测试结果
- 关联Issue

## Agent协作指南

对于AI Agent贡献者：

### 工作流程

1. **创建控制文件**：使用 `docs/templates/control.json` 记录运行状态
2. **维护运行日志**：在 `docs/runs/` 目录记录每次运行摘要
3. **自我改进**：从失败运行中提取教训，更新技能文件

### 模板使用

所有Agent任务应遵循以下生命周期：
```
spec → plan → evidence → control
```

### 文件命名

- 运行日志：`YYYY-MM-DD-HHMM-agentId-runId.md`
- 任务目录：`docs/runs/TASK-xxx/`
- 控制文件：`docs/runs/TASK-xxx/control.json`

## 编码规范

- 保持文件简洁，避免过度复杂化
- 优先使用现有技能，避免创建重复功能
- 所有外部操作（API调用、邮件发送等）需要明确安全边界
- 私人数据保护：不泄露用户敏感信息

## 安全检查

- 所有技能安装前必须通过 `skill-vetter` 审查
- 不运行未经批准的外部命令
- 不修改系统安全配置
