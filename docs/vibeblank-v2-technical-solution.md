# 黑码码 V2 技术方案

## 1. 目标

黑码码 V2 在 V1 的 macOS 菜单栏隐私遮罩工具基础上完成三项迭代：

1. 用户界面中文化，中文品牌名为「黑码码」。
2. 开启和退出黑屏时加入边缘向中心推进的渐变转场。
3. 增加小黑马图标，并接入菜单栏和本地 `.app` / `.dmg` 打包产物。

V2 保留 `VibeBlank` 作为 Swift package、target、可执行文件和内部兼容名，不改变既有设置数据结构和默认行为。

## 2. 架构调整

### 2.1 中文文案层

新增 `AppCopy` 集中存放用户可见文案。`AppDelegate`、`SettingsView`、`SettingsWindowController` 和 `OverlayContentView` 不再直接散落英文 UI 字符串。

`AppSettings` 中的枚举 `displayName` 改为中文展示名，`sanitizedCustomText` 的空值兜底改为「黑码码已开启」。`UserDefaults` key、通知名和 Codable raw value 保持不变，保证升级兼容。

### 2.2 遮罩转场状态机

新增 `OverlayTransitionPhase`：

- `appearing`：窗口已经创建并拦截输入，遮罩从四周向中心合拢。
- `visible`：稳定黑屏状态，背景为纯黑。
- `disappearing`：退出中，画面从四周向中心恢复，动画完成后释放窗口。

`OverlayWindow` 持有转场 phase，并通过 `NSHostingView` 渲染 `OverlayContentView`。`OverlayManager.activate(settings:)` 创建窗口后立即显示，窗口内部自动进入 `appearing`。约 320ms 后切换为 `visible`。

`OverlayManager.deactivate()` 不再立即 `orderOut`。它会请求所有窗口播放 `disappearing`，等最后一个窗口回调完成后再移除窗口、恢复前台 app、通知菜单刷新。重复退出请求在同一轮动画中只生效一次。

### 2.3 转场视觉实现

转场使用 SwiftUI 形状遮罩完成。稳定态仍使用全屏 `Color.black`，避免转场层残留导致漏光。

开启黑屏时，黑色边缘层从屏幕四周向中心推进；退出时反向推进，让底层画面从边缘向中心恢复。动画时长固定为 0.32 秒。V2 不新增动画开关或速度设置。

### 2.4 图标与打包

新增 `assets/heimama-icon.svg` 作为可复现的小黑马矢量源图，新增 `scripts/generate_icon.sh` 生成 `assets/heimama-icon.icns`。

`scripts/package_app.sh` 在打包时复制 `.icns` 到 `Contents/Resources`，并在 Info.plist 写入：

- `CFBundleDisplayName=黑码码`
- `CFBundleName=黑码码`
- `CFBundleIconFile=heimama-icon`
- `CFBundleDevelopmentRegion=zh_CN`

脚本同时生成 `dist/VibeBlank.dmg`。DMG 卷名为「黑码码」，内容包含「黑码码.app」和 `/Applications` 快捷方式，方便用户按常见 macOS 方式拖拽安装。

应用启动时从 bundle 读取 `heimama-icon`，设置为 template image 后用于菜单栏。图标不可用时，菜单栏按钮回退显示「黑码码」。

## 3. 数据流

1. App 启动，`AppDelegate` 配置菜单栏图标和中文 tooltip。
2. 首次启动打开「黑码码设置」窗口。
3. 用户通过菜单栏或快捷键开启黑屏。
4. `OverlayManager` 按当前设置选择目标屏幕并创建 `OverlayWindow`。
5. 每个窗口立即拦截输入，并播放 `appearing` 动画。
6. 动画结束后窗口进入 `visible`，保持纯黑遮罩和可选内容文字。
7. 用户触发退出后，窗口播放 `disappearing` 动画。
8. 所有窗口退场完成后，`OverlayManager` 释放窗口并恢复前台应用。

## 4. 错误处理

- 图标加载失败：菜单栏显示「黑码码」文字。
- `.icns` 缺失：打包脚本在生成 app 前自动运行图标生成脚本。
- 退场动画期间重复退出：忽略重复请求，等待当前退场完成。
- 屏幕布局变化：强制清理旧窗口并按当前屏幕重新创建遮罩。
- App 退出：强制移除遮罩窗口，不等待动画。

## 5. 验证

自动验证：

- `swift run VibeBlankCoreChecks`
- `swift build --product VibeBlank`
- `bash scripts/generate_icon.sh`
- `bash scripts/package_app.sh`
- `plutil -p dist/VibeBlank.app/Contents/Info.plist`
- `test -s dist/VibeBlank.app/Contents/Resources/heimama-icon.icns`
- `hdiutil verify dist/VibeBlank.dmg`

手动验证：

- 菜单栏显示小黑马图标或「黑码码」回退文字。
- 设置窗口和菜单项显示中文。
- 开启黑屏时黑色从四周向中心合拢。
- 退出黑屏时画面从四周向中心恢复。
- 动画期间输入不会穿透。
- Esc 在动画中和稳定黑屏中都能退出。
