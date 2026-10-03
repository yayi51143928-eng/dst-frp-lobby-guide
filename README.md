# dst-frp-lobby-guide

> 饥荒联机版：让服务器列表进入玩家自动使用内网穿透

针对 **FRP 手动直连正常，但从游戏大厅加入延迟高或连接异常** 的情况，整理代理登记、UDP 转发和双世界验证方法。适合希望继续使用家中服务器或 Mac mini 的服主。

## 解决思路

让大厅登记与 FRP 使用同一个公网出口：

- **游戏连接**：玩家 → VPS 上的 FRP → 家中地面 / 洞穴服务器。
- **大厅登记**：服务端通过 VPS HTTP 代理发送 HTTPS 请求；两个世界进程设置 `https_proxy`。

目标是让玩家直接在服务器列表搜索、点击加入，无需安装额外软件或手动输入连接地址。

## 文档

- [完整教程](docs/guide.md)：端口、FRP、代理设置与验收。
- [Mac mini / Docker 配置](docs/docker.md)
- [配置示例](examples/) · [启动脚本](scripts/with-proxy.sh)
- [故障排查](docs/troubleshooting.md) · [实测记录](docs/test-record.md)

方案依据 [Klei 开发者建议](https://kleiforums.com/forums/topic/161083-request-permission-to-customize-the-independent-server-ipdomain-in-browse-games/#findComment-1762838)。当前示例尚未完成真实服务器的双世界验收，部署后请按教程验证。
