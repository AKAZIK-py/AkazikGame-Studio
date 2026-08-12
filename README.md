# Game_Autochess

用于筹备 Game_Autochess 项目的 OpenClaw Agent 工作区。

## 当前状态

仓库目前包含 Agent 配置、可复用技能、贡献流程和任务运行记录；尚未加入 Unity 工程或游戏源码。因此当前仓库不能直接用 Unity 打开，`Assets/`、`Packages/`、`ProjectSettings/` 等目录将在游戏工程正式初始化后再补充。

## 目录结构

```text
Game_Autochess/
├── .github/              # Issue 与 PR 模板
├── docs/
│   ├── templates/        # spec、plan、evidence、control 模板
│   └── runs/             # Agent 任务运行记录
├── skills/               # OpenClaw 技能及其脚本、参考资料与资源
├── AGENTS.md             # Agent 工作区约定
├── BOOTSTRAP.md          # 首次启动说明
├── CONTRIBUTING.md       # 贡献流程
├── HEARTBEAT.md          # 主动检查清单
├── IDENTITY.md           # Agent 身份配置
├── SOUL.md               # Agent 行为与价值约定
├── TOOLS.md              # 本地工具说明
└── USER.md               # 用户偏好与上下文
```

## 使用与贡献

1. 阅读 `AGENTS.md` 与 `BOOTSTRAP.md`，按当前工作区约定完成初始化。
2. 提交改动前阅读 `CONTRIBUTING.md`。
3. 新任务使用 `docs/templates/` 中的模板，并在 `docs/runs/` 中保留可核验的运行记录。

Unity 版本、首个场景路径和游戏源码布局尚未确定；在相关文件真正加入仓库前，不应把这些规划写成可执行的开发步骤。
