# Codex Silent Proxy Launcher

Windows Codex 桌面版的轻量静默代理启动器。双击桌面图标，使用本机 HTTP 代理启动 Codex；Codex 已经运行时直接静默退出。

适用于本地代理已经正常运行，但 Codex 仍反复显示 `Reconnecting 1/5 ... 5/5` 的情况。如果原因是启动进程没有取得代理环境变量，这个启动方式可能改善连接。

## 特点

- 日常启动不弹终端，不需要额外的启动器界面。
- Codex 已运行时不提示、不强制关闭、不重复启动。
- 为新启动的 Codex 进程设置 `HTTP_PROXY` 和 `HTTPS_PROXY`；其子进程也会继承。
- 保留现有 Windows 系统代理、TUN 和代理客户端设置。
- 默认使用 `127.0.0.1:7890`，支持自定义端口。
- 从已安装的 Codex 包中读取当前 ChatGPT 图标，复制到固定位置，避免应用更新后旧图标路径失效。
- 每次启动动态查找 Codex 安装位置，支持当前以 `ChatGPT.exe` 作为入口的 Windows 安装包。
- 不依赖 Python、Node.js 或另装 .NET SDK。

## 使用条件

- Windows 10/11、Windows PowerShell 5.1 和可用的 Windows Script Host/VBScript。
- 已安装可被 `Get-AppxPackage -Name OpenAI.Codex` 找到的 Codex 桌面版。
- FlClash、Clash/Mihomo 或其他代理客户端正在提供本地 **HTTP 或 mixed 代理**。SOCKS-only 端口不适用。

## 安装

1. 点击仓库右上角 **Code → Download ZIP**，解压到普通文件夹。
2. 双击 `Install.cmd`。默认安装到 `%LOCALAPPDATA%\CodexSilentProxyLauncher`，创建桌面 **Codex Proxy** 快捷方式。
3. 保持代理客户端运行，先完全退出现有 Codex，再通过新桌面入口启动。

安装不会启动或关闭现有 Codex，也不会更改系统代理或创建开机启动项。

需要其他端口或桌面名称时，在解压目录打开 PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install.ps1 -ProxyPort 7897 -ShortcutName "Codex"
```

若同名桌面快捷方式属于其他程序，安装脚本会停止；请改用其他名称。重新运行安装脚本可更新启动器和本机图标。

## 日常行为

| 状态 | 结果 |
| --- | --- |
| Codex 未运行，代理端口可用 | 隐藏终端并启动 Codex |
| Codex 已运行 | 静默退出，保留当前会话 |
| 代理未启动或安装路径不可用 | 静默入口不弹终端；使用下方诊断入口查看原因 |

已有 Codex 进程的环境变量不会被改写。第一次使用，以及需要切换代理启动方式时，都要先完全退出 Codex。

## 排查问题

到安装目录双击 `Start-Codex-With-FlClash.cmd`，可在可见终端中查看启动失败原因。这个文件只用于诊断；桌面快捷方式使用 `.vbs` 静默入口。

检查代理端口是否与 `settings.json` 中的 `ProxyPort` 一致。文件名沿用 FlClash，但其他提供本机 HTTP 代理的客户端也可使用。

如果仍然重连，需要进一步检查代理节点、网络连通性、服务状态或客户端自身问题。此工具不会提高重试次数，也不保证消除所有重连。

## 卸载

从已安装目录运行 `Uninstall.cmd`，删除此启动器的文件和对应桌面快捷方式。保留 Codex 本体、代理客户端、系统代理设置和目录中其他文件；空目录可手动删除。

## 验证范围

本机已验证 Codex `26.1007.2314.0` 的安装位置识别、静默入口、重复点击时不新增/结束 Codex 进程，以及本地 `7890` 代理下的 WebSocket 连接。其他安装渠道和受组织策略限制的环境尚未验证。

这是个人脚本项目，与 OpenAI 无官方关联。仓库不分发应用图标；图标仅在安装时从用户本机读取。

## License

[MIT](LICENSE)。
