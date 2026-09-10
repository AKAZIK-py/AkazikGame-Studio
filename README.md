# AkazikGame Studio

AKAZIK 的游戏工坊。仓库用来放可运行的游戏，以及共用的制作工具。

以前叫 `Game_Autochess`。GitHub 会把旧地址重定向到这里。

## 游戏

| 游戏 | 位置 | 状态 | 说明 |
|---|---|---|---|
| **纸境 INKBOUND** | [`games/inkbound/`](games/inkbound) | 可玩 | 浏览器第一人称波次生存。蓝墨线稿，2–4 人同页联机。 |
| **V-Tacit** | 仓库根目录（Godot 4.6） | 制作中 | VTuber 主题自走棋。14 名角色、10 条羁绊，主场景 `scenes/Game.tscn`。 |

### 纸境 INKBOUND

需要 Node.js 20+。

```sh
cd games/inkbound
npm install
npm start
```

浏览器打开 http://127.0.0.1:8787 。单人模式不依赖 WebSocket；`public/` 也可以单独放到静态网页服务器。

```sh
npm test                 # 核心规则 23 项 + 真实 WebSocket 10 项
npx playwright install chromium
npm run test:browser     # 浏览器端到端
```

操作、联机部署和已知限制见 [`games/inkbound/README.md`](games/inkbound/README.md)。

### V-Tacit

用 Godot 4.6 打开本仓库根目录。角色与羁绊数据在 `assets/data/`，逻辑在 `src/`。

## 目录

```
AkazikGame-Studio/
├── games/inkbound/     # 纸境：完整网页游戏 + 权威服务器
├── src/                # V-Tacit 游戏逻辑
├── assets/             # V-Tacit 角色 / 羁绊数据
├── scenes/             # V-Tacit 场景
├── tests/              # V-Tacit 测试
├── .claude/            # 游戏制作 agent、skill、hooks
└── CLAUDE.md           # studio agent 协作约定
```

`.claude/` 是工作室内部的 agent 工具，不是游戏本体。

## 许可

仓库根目录的 [LICENSE](LICENSE) 覆盖 studio 工具与 V-Tacit 骨架。INKBOUND 的第三方许可证在 [`games/inkbound/THIRD-PARTY-LICENSES/`](games/inkbound/THIRD-PARTY-LICENSES)。
