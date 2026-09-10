# INKBOUND play handoff

纸境。固定地址 `http://127.0.0.1:8787`。操作说明见同目录 [`README.md`](README.md)。

在仓库根执行下列命令。`ROOT` 指本 git 仓库根。

## 启动

完成标准：`curl -fsS http://127.0.0.1:8787/health` 返回 JSON 且含 `"ok":true`，同时 `GET /` 的 HTML 含 `INKBOUND`。

```sh
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT/games/inkbound"
node -e "process.exit(Number(process.versions.node.split('.')[0])>=20?0:1)"
npm install
```

Node 低于 20 则停下。

已在跑本游戏则复用，不要再起一份：

```sh
curl -fsS --max-time 2 http://127.0.0.1:8787/health
```

该命令失败时，若 8787 已被别的进程占用则停下并报告 PID，不要换端口。空闲则启动：

```sh
mkdir -p .run
HOST=127.0.0.1 PORT=8787 nohup node server.mjs > .run/server.log 2>&1 &
echo $! > .run/server.pid
```

最多等 10 秒，直到 health 通过。失败则打印 `.run/server.log` 后停下。

通过之后才对人类说可以打开 `http://127.0.0.1:8787`，并写：玩完说「退出游戏」，关标签不会停服。

## 停止

完成标准：`curl -fsS --max-time 2 http://127.0.0.1:8787/health` 失败，且 8787 无监听。

```sh
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT/games/inkbound"
if [ -f .run/server.pid ]; then
  kill -TERM "$(cat .run/server.pid)" 2>/dev/null || true
fi
# pid 文件不准时，按端口收
if command -v lsof >/dev/null; then
  lsof -nP -iTCP:8787 -sTCP:LISTEN -t | xargs -n1 kill -TERM 2>/dev/null || true
fi
```

等 2 秒再验 health。仍在听就 `kill -KILL` 该 PID，再验一次。最后删 `.run/server.pid`。告诉人类已经停掉。
