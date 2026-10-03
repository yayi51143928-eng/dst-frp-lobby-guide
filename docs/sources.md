# 资料与核验说明

核对日期：2026-10-03。本文依据 Klei 开发者讨论及以下项目文档整理；实施示例需按实际部署验证。

## 证据层级

| 结论 | 依据 | 本文处理 |
| --- | --- | --- |
| 用 `https_proxy` 使大厅看到代理出口是开发者提出的思路 | nome 于 2024-11-26、27 的解释 | 保留，注明归档帖与版本限制 |
| 有玩家报告实现过同类效果 | clearlove 于 2024-12-03 的留言 | 保留，但其使用 Proxychains，并未验证环境变量方式 |
| Tinyproxy、SSH、FRP 可以构成本文两条网络路径 | 对应项目的官方文档 | 整理为实施示例，需实机验收 |
| 本文方案已在当前 DST 版本、Mac mini、双世界上成功 | 没有本次实测证据 | 不作此声明 |
| 游戏服务器延迟问题一定由中继造成 | 未观察实际网络路径 | 不作此断言，以抓包和日志验证 |

## 原始资料

1. [Klei：公网入口自定义讨论](https://kleiforums.com/forums/topic/161083-request-permission-to-customize-the-independent-server-ipdomain-in-browse-games/)。重点看开发者 [1762838](https://kleiforums.com/forums/topic/161083-request-permission-to-customize-the-independent-server-ipdomain-in-browse-games/#findComment-1762838) 与玩家 [1767709](https://kleiforums.com/forums/topic/161083-request-permission-to-customize-the-independent-server-ipdomain-in-browse-games/#findComment-1767709)。论坛显示该话题已归档，并提示内容可能过时。
2. [Klei：启动参数](https://support.klei.com/hc/en-us/articles/360029556192-Dedicated-Server-Command-Line-Options-Guide)。核对 `-port` 覆盖关系、两分片启动方式与配置目录。
3. [Klei：服务端设置](https://kleiforums.com/forums/topic/64552-dedicated-server-settings-guide/)。核对玩家端口、分片互联端口与 Steam 端口的区别。
4. [FRP：UDP 转发示例](https://gofrp.org/en/docs/examples/dns/)。该页面示范 DNS，但配置结构适用于普通 UDP 代理。
5. [FRP：配置格式与校验](https://gofrp.org/en/docs/features/common/configure/)、[认证](https://gofrp.org/en/docs/features/common/authentication/)、[服务端配置](https://gofrp.org/en/docs/reference/server-configures/)。核对 TOML、`verify`、token 和 `allowPorts`。
6. [Tinyproxy 官方文档](https://tinyproxy.github.io/)。核对监听、访问控制与 CONNECT。
7. [OpenSSH ssh](https://man.openbsd.org/ssh)、[ssh_config](https://man.openbsd.org/ssh_config)。核对转发绑定、存活检测和转发失败检测的范围。
8. [libcurl 环境变量](https://curl.se/libcurl/c/libcurl-env.html)、[代理参数](https://curl.se/libcurl/c/CURLOPT_PROXY.html)。核对代理变量、绕过规则与代理协议前缀；实际应用也可能覆盖环境变量。
9. [Docker Desktop 网络](https://docs.docker.com/desktop/features/networking/)、[Compose 网络](https://docs.docker.com/compose/how-tos/networking/)、[服务配置](https://docs.docker.com/reference/compose-file/services/)。核对容器网络、服务名、UDP 发布与环境变量。
10. [Alpine 官方镜像清单](https://github.com/docker-library/official-images/blob/master/library/alpine)、[Alpine 3.22 OpenSSH 客户端包](https://pkgs.alpinelinux.org/package/v3.22/main/x86_64/openssh-client-default)。用于容器隧道示例的基础镜像与包名核对。

本文没有读取或更改真实 VPS、FRP、DST 服务配置，未以生产配置执行文中的部署步骤。语法与本地模拟检查的记录见 [test-record.md](test-record.md)。

## 主页结构参考

参考 [Jamesits/docker-dst-server](https://github.com/Jamesits/docker-dst-server) 与 [carrot-hu23/dst-admin-go](https://github.com/carrot-hu23/dst-admin-go) 的项目定位、方案概述与文档入口组织方式，未复用其文字、宣传或配置。
