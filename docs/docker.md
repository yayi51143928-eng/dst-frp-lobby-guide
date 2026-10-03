# Mac mini + Docker：把代理隧道放在容器网络里

**容器里的 `127.0.0.1` 是容器自己。** 在 Mac 终端建立回环 SSH 转发，再把 `https_proxy=http://127.0.0.1:8888` 写进游戏容器，会连接到错误的地方。

本文给出一个明确的选择：新增 `dst-lobby-proxy` 容器，在其中建立 SSH 本地转发；DST 通过同一 Compose 网络的服务名访问它。VPS 上 Tinyproxy 继续只监听 `127.0.0.1:8888`。

```text
DST 容器
  HTTPS → http://dst-lobby-proxy:8888
           → 容器内 SSH 隧道
             → VPS 127.0.0.1:8888 Tinyproxy → Klei

外网玩家
  UDP → VPS frps → Mac 上 frpc
                    → Mac 发布的 UDP 10999 / 10998 → DST 容器
```

本例假设 frpc 在 Mac 宿主机，DST 使用普通 Compose bridge 网络，游戏已正常运行。若使用 host 网络、独立 Docker 网络、分离的 Master/Caves 容器或其他容器运行时，先按实际网络调整。不要为了套示例替换工作中的游戏镜像、存档卷或分片配置。[Docker Desktop 网络](https://docs.docker.com/desktop/features/networking/)、[Compose 网络](https://docs.docker.com/compose/how-tos/networking/)。

## 1. 把代理示例放进现有 Compose 项目

从 [examples/docker](../examples/docker/) 复制文件到你现有 Compose 项目的目录，形成：

```text
原有项目/
├── compose.yaml                 # 原有游戏配置
├── compose.proxy.yaml           # 新增：只定义代理
├── proxy/
│   ├── Dockerfile
│   └── tunnel.sh
├── .env                         # 本地实际参数
└── secrets/                     # 不提交 GitHub
    ├── vps_ssh_key
    └── known_hosts
```

如果已有 `.env`，合并示例的三个变量，不要覆盖原内容。路径相对于第一个 Compose 文件所在目录；示例把所有文件放在同一目录以避免歧义。

```dotenv
VPS_HOST=你的VPS地址
VPS_USER=你的SSH用户名
VPS_SSH_PORT=22
```

在 `secrets/vps_ssh_key` 放入可用于该 VPS 登录的既有私钥文件；限制其文件权限：

```bash
chmod 700 secrets
chmod 600 secrets/vps_ssh_key
```

示例使用非交互 SSH，不能弹出密码或私钥口令输入框。若你的登录依赖密码、需要口令的私钥或 SSH agent，先使用现有环境中合适的密钥/agent 方案；不要为运行示例清除已有私钥口令。不要把整个 `~/.ssh` 目录挂入容器。

`known_hosts` 必须包含**已核对指纹**的 VPS 主机公钥，主机名/IP 要与 `VPS_HOST` 一致；非 22 端口需要对应的 `[host]:port` 条目。可以从自己已确认的记录中提取所需条目，不要直接将未核对的 `ssh-keyscan` 输出视为可信。示例启用 `StrictHostKeyChecking=yes`，不跳过校验。[OpenSSH 配置](https://man.openbsd.org/ssh_config)。

## 2. 在原游戏服务中合并环境和 UDP 发布

假设原服务名是 `dst`，地面与洞穴在同一容器。将下面的选项**合并到它的现有配置**，保留已有 image、command、volumes 和其他 environment：

```yaml
services:
  dst:
    # 保留原有游戏配置，以下只是修改片段，不能独立运行。
    environment:
      https_proxy: http://dst-lobby-proxy:8888
      no_proxy: localhost,127.0.0.1
      NO_PROXY: localhost,127.0.0.1
    ports:
      - "127.0.0.1:10999:10999/udp"
      - "127.0.0.1:10998:10998/udp"
```

确认已有端口列表没有相同端口的重复发布；同时保留部署所需的其他端口。DST `server.ini` 里的端口是**最右边的容器端口**，Mac 宿主机 frpc 的 `localPort` 是**中间的宿主机端口**，VPS 的 `remotePort` 与 DST 玩家端口保持相同。省略 `/udp` 会默认发布 TCP。[Compose 服务设置](https://docs.docker.com/reference/compose-file/services/)。

如果地面和洞穴分为两个服务，每个服务都加代理环境，分别发布各自 UDP 端口。它们必须与代理共享至少一个可通信网络；如原游戏使用自定义网络，把代理也接到那个网络。原有分片互联继续使用容器服务名或实际内部地址，不能改成跨容器回环。

代理容器监听自己的 `0.0.0.0:8888` 以供同网络容器访问，Compose 示例**没有 `ports`，不发布该端口到 Mac**。该网络中的容器都可访问它，适合由你控制的游戏项目；不要把它接入不可信共享网络。

## 3. 先启动代理，再重建游戏容器

在现有项目目录执行，两个 `-f` 参数在后续命令中保持一致：

```bash
docker compose -f compose.yaml -f compose.proxy.yaml config --quiet
docker compose -f compose.yaml -f compose.proxy.yaml up -d --build dst-lobby-proxy
docker compose -f compose.yaml -f compose.proxy.yaml logs --tail=50 dst-lobby-proxy
docker compose -f compose.yaml -f compose.proxy.yaml exec dst-lobby-proxy \
  curl --fail --show-error --silent --noproxy '' \
  --connect-timeout 5 --max-time 15 \
  --proxy http://127.0.0.1:8888 https://api.ipify.org
```

返回的 IP 应与 FRP 公网入口相同。错误包括私钥权限、主机密钥缺失、SSH 登录拒绝、VPS Tinyproxy 未启动等，先解决再继续。构建使用 Alpine 官方镜像和发行版软件包；生产复现可记录实际构建结果及镜像 digest，版本标签本身不保证内容永远不变。

然后在游戏容器中检查代理是否可达。若已有 `curl`：

```bash
docker compose -f compose.yaml -f compose.proxy.yaml exec dst \
  curl --fail --show-error --silent --noproxy '' \
  --connect-timeout 5 --max-time 15 \
  --proxy http://dst-lobby-proxy:8888 https://api.ipify.org
```

如果游戏镜像没有 curl，可临时借用代理镜像，在项目网络中发起请求：

```bash
docker compose -f compose.yaml -f compose.proxy.yaml run --rm --no-deps \
  --entrypoint curl dst-lobby-proxy \
  --fail --show-error --silent --noproxy '' \
  --connect-timeout 5 --max-time 15 \
  --proxy http://dst-lobby-proxy:8888 https://api.ipify.org
```

后一种只验证该 Compose 网络的代理可达性；如 DST 另有网络、DNS 或限制，仍需在 DST 环境单独确认。

先通过原有管理方式保存世界并正常停止游戏，再更新游戏容器：

```bash
docker compose -f compose.yaml -f compose.proxy.yaml up -d dst
```

若是两个服务，将 `dst` 替换为实际 Master、Caves 服务名。修改 environment 后，`restart` 不会加载新的容器定义；`up -d` 会在配置变化时重建。整个过程中不要使用 `down -v`，也不要改变存档挂载。

## 4. 核对游戏进程，而非仅核对容器声明

```bash
docker compose -f compose.yaml -f compose.proxy.yaml exec dst printenv https_proxy
```

这只说明新建 exec 进程可见该变量。若镜像启动脚本通过 `su`、`env -i` 等清理环境，实际 DST 子进程仍可能缺失它。检查镜像启动流程；Linux 容器可在权限允许时读取 `/proc/实际DST进程PID/environ`，只筛选代理变量，不要把整个环境输出贴到公开帖子。最终仍以 Klei 代理请求与真实游戏通信为准。

完成主教程的外网大厅加入、洞穴往返和 UDP 抓包验收。[返回验收步骤](guide.md#6-怎么证明玩家实际走了-frp)。

## 5. 重启恢复也要测试

代理的 `restart: unless-stopped` 可在 SSH 退出后重新启动容器，但启动成功并不代表 Tinyproxy 已经可用。本示例故意要求先人工验证代理，再启动游戏；没有将端到端请求检查写成自动健康检查。

长期运行时，把原有游戏服务的启动顺序纳入管理，或在原有启动器中加入等待代理成功的步骤；仅用短格式 `depends_on` 不能保证代理就绪。代理运行中断开也不会由 `depends_on` 自动重启游戏。机器重启后必须重复验收，不能把本例宣称为已经完成全自动恢复的整套部署。
