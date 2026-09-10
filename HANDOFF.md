# Play handoff

给下一个 agent：人类想在本机玩这个仓库里的游戏时，读完本文再执行对应游戏的 HANDOFF。不要凭记忆报 URL。

## 路由

| 人类说的 | 读并执行 | 本机可玩 |
|---|---|---|
| 纸境 / INKBOUND / inkbound | [`games/inkbound/HANDOFF.md`](games/inkbound/HANDOFF.md) | 是。固定 `http://127.0.0.1:8787` |
| V-Tacit / 自走棋 / autochess | 本文「V-Tacit」一节 | 否。需要 Godot 4.6 编辑器，没有本地网页端口 |

说不清玩哪个时先问一句，再进表。

固定端口只属于上表。被占用且 `/health` 不是本游戏时停下，改口告诉人类，不要换端口。

## 通用步骤

1. **仓库在本地。** 已在本仓库工作树则用当前树；否则 `git clone https://github.com/AKAZIK-py/AkazikGame-Studio.git`。完成标准：能读到目标游戏的 `HANDOFF.md`。
2. **读并执行该游戏 HANDOFF。** 启动、验活、报 URL、提醒退出，都以那份为准。
3. **报 URL 的完成标准。** 该游戏 HANDOFF 里的 health 检查已经通过。检查没过就说没起来，附日志。
4. **安全退出。** 人类说玩完 / 退出 / 停服时，执行该游戏 HANDOFF 的停止步骤。关浏览器标签不等于停服。报 URL 的同时写明这句话。

## V-Tacit

Godot 4.6 打开仓库根目录，主场景 `scenes/Game.tscn`。不要启动 Node 服务，也不要编造 `localhost` 地址。
