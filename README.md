# Game_Autochess

自走棋游戏项目

## 技术栈

- **引擎**: Unity
- **语言**: C#

## 目录结构

```
Game_Autochess/
├── Assets/                 # Unity 资源
│   ├── Scripts/            # C# 脚本
│   │   ├── Core/           # 核心逻辑
│   │   ├── Entities/       # 游戏实体
│   │   ├── Systems/        # 游戏系统
│   │   ├── UI/             # UI 控制器
│   │   └── Utils/          # 工具类
│   ├── Prefabs/            # 预制体
│   ├── Scenes/             # 场景
│   ├── Art/                # 美术资源
│   ├── Audio/              # 音频
│   └── Resources/          # 动态加载资源
├── Packages/               # Unity 包
├── ProjectSettings/        # 项目设置
├── docs/                   # 文档
├── skills/                 # OpenClaw 技能
├── memory/                 # Agent 记忆
├── config/                 # 配置文件
└── scripts/                # 工具脚本
```

## 开发指南

1. 克隆仓库
2. 使用 Unity 2021.3+ 打开项目
3. 打开 `Assets/Scenes/Main.unity` 场景

## 工作流

本项目使用 OpenClaw Agent 工作流：
- `docs/templates/spec.md` — 规格文档
- `docs/templates/plan.md` — 执行计划
- `docs/templates/evidence.md` — 验收证据
