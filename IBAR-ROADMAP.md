# iBar — 改名与功能复刻计划

> 基线：`moonbai-studio/tungsten-edge` @ v0.18.4 + 1（2026-10-28）
> 分叉方：`ji1360677347/ibar`
> 本文档由源码实测统计得出，未标注数字的结论均已标注「待核实」。

---

## 0. 合规前置（不是可选项）

`TRADEMARK.md` 第 14 行原文：

> 再分发你自己编译的版本，**但必须换名字、换图标**。

也就是说：**iBar 必须改名、必须换图标，否则不能合法分发**。改名不是"想不想"的问题。

同时必须遵守：

| 约束 | 来源 | 对 iBar 的要求 |
|---|---|---|
| 换名 + 换图标 | TRADEMARK.md | App 包名、菜单栏、网站、包管理器配方都不能出现 Tungsten Edge / 钨极 / 其图标 |
| 保留 GPL | LICENSE (GPL-3.0-or-later) | 衍生作品继续 GPL-3.0-or-later，保留原版权声明，分发时提供源码 |
| 可声明来源 | TRADEMARK.md | 应当写明 "based on Tungsten Edge" 或 "Tungsten Edge 的分支" |
| **不得沿用官方更新源** | TRADEMARK.md | Sparkle 源只由 Moonbai 提供，iBar 必须断开 |
| 不得暗示官方背书 | TRADEMARK.md | 官网/README 需明确是第三方分叉 |

---

## 1. 改名改造清单（源码实测统计）

品牌字符串分布：

| 字符串 | 命中文件数 |
|---|---|
| `com.caye.macosdockcc.v2`（Bundle ID） | 38 |
| `Tungsten Edge` | 74 |
| `钨极` | 83 |
| `tungstenedge` | 47 |
| `TungstenEdge` | 4 |
| 字符串表 `Localizable.xcstrings` / `InfoPlist.xcstrings` | 2 个文件 |

### 必改项（按风险从高到低）

1. **`Resources/Info.plist` → `SUFeedURL` 必须删除或改指向**
   现值为 `https://tungstenedge.app/appcast.xml`。
   **这是头号地雷**：留着它，iBar 会自动下载并安装官方 Tungsten Edge 覆盖自己。
   同处的 `SUPublicEDKey` 也要删（iBar 若要做自动更新，需自建 appcast 和自己的 EdDSA 密钥对）。

2. **`PRODUCT_BUNDLE_IDENTIFIER` 必须换成自己的域**
   现值 `com.caye.macosdockcc.v2`。不换会导致与官方版冲突：辅助功能（TCC）授权、`~/Library/Preferences` 偏好域、单实例锁、登录项注册全部串在一起，两个 App 会互相干扰。

3. **`Resources/Info.plist` 的显示名**
   `CFBundleDisplayName` 与 `CFBundleName` 现为 `Tungsten Edge 钨极` → `iBar`。

4. **App 图标必须更换**（TRADEMARK 强制，非建议）
   资源位置需在 `Resources/` 下确认图标集，不能沿用原 `AppIcon`。

5. **`NSHumanReadableCopyright`**
   现值 `Copyright © 2026 Moonbai Studio. Licensed under GPL-3.0-or-later.`
   GPL 要求保留原声明 → 保留这行，**另起一行**补 iBar 自己的版权与分叉说明。

6. **两个字符串表**
   `Resources/Localizable.xcstrings`、`Resources/InfoPlist.xcstrings` 内的品牌词与中文名需全量替换（涉及 10 种语言）。

7. **README / TRADEMARK.md**
   README 顶部加"第三方分叉"声明；原 TRADEMARK.md 保留（作为上游权利声明），另加 iBar 自己的说明。

---

## 2. 构建环境

| 项 | 状态 |
|---|---|
| 工程类型 | Xcode 工程（`macos-dock-cc-v2.xcodeproj`），**非** SwiftPM |
| Xcode | 已安装 `/Applications/Xcode.app` |
| `xcode-select` | 当前指向 `/Library/Developer/CommandLineTools`，`xcodebuild` 直接调会报错 |
| 绕行方式 | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild ...`（无需 sudo） |
| 磁盘 | Data 卷可用 **107 GB**，充足 |
| 打包脚本 | `Scripts/build_and_run.sh`、`package_release.sh`、`install_local_release.sh` |

---

## 3. 功能差距：uBar 5.0.5 → iBar

### 3.1 已具备（无需复刻）

- 每窗口一张卡片、单击切换 / 最小化
- 单窗口应用折叠为图标（Smart Expand）
- 原生标签合并（Ghostty / Finder 不跳位）
- 抽屉（收纳少用应用、可固定成启动器）
- 拖拽排序、拖入抽屉
- 固定文件夹（Fan / Grid / List / Automatic，Dock 式动画）
- 未读角标（微信、飞书等）
- 多显示器：每屏独立条 / 跟随指针；条间拖窗口换屏
- 边缘自动隐藏 + 可调唤醒延迟
- 毛玻璃外观
- 全屏切换防闪烁
- 拖文件到图标启动
- 外观：System / Light / Dark 三档
- 十语言界面

### 3.2 缺失（需复刻）

| 功能 | iBar 现状（源码核实） | 复刻难度 | 优先级 |
|---|---|---|---|
| **Dock 模式 / Taskbar 模式双模** | 无（`dockMode` 0 命中） | 中 | P0 |
| **四边位置 + 四档尺寸** | 仅底部（README 明示 "sit at the bottom edge"） | 中高 | P0 |
| **窗口缩略图悬停预览** | 无（`SCScreenshotManager` / `CGWindowListCreateImage` 0 命中） | 高（需屏幕录制权限 + 缓存策略） | P0 |
| **窗口分组 Always / Never / Automatic 三档** | 仅"智能标签合并"，无三档开关 | 中 | P1 |
| **App Flashes（请求注意时卡片闪动）** | 无（`requestUserAttention` 0 命中） | 低 | P1 |
| **App Progress（媒体播放进度）** | 无（`MPNowPlayingInfoCenter` 0 命中） | 中 | P2 |
| **App Status（启动中 / 无响应 / 可恢复）** | 待核实 | 低 | P2 |
| **App Activity（按 Control 看 CPU / 内存）** | 无 | 低 | P2 |
| **可扩展到 5 行** | 待核实 | 中 | P2 |
| **镜像模式（所有屏显示同一条）** | `mirror` 命中 5 个文件，**待核实是否已实现** | 低 | P1 |
| **主题扩展（Platinum Neue / Now Playing / Custom）** | 仅三档外观 | 中 | P3 |
| **电池与声音（健康度 / 输出切换）** | 无（`IOPSGetPowerSourceDescription` / `AVAudioEngine` 0 命中） | 低 | P3 |
| **Devices（一键推出外置盘 / 蓝牙设备）** | 无 | 低 | P3 |
| **时钟与日历** | `Clock` 命中 4 文件（**待核实**是否为菜单栏时钟）；日历 0 命中 | 低 | P3 |
| **钉住四角 / 浮动** | 无 | 低 | P3 |
| **Command（输入 / "Hey iBar" 语音控制）** | 无 | **极高**（需 ASR + 意图解析 + 窗口操作编排，uBar 走的是端侧+云端混合） | P3，建议单独立项 |

---

## 4. 分阶段计划

**阶段 0 — 改名落地（1 次提交可完成）**
删除 Sparkle 源 → 换 Bundle ID → 换显示名 → 换图标 → 字符串表批量替换 → 版权行处理。
验收：`xcodebuild` 出包，App 名显示 iBar，偏好域为新的，不与官方版冲突。

**阶段 1 — 位置与形态（P0）**
四边位置 + 尺寸档位；Dock 模式（应用为中心，不带窗口卡片）。
这一阶段动的是布局核心，`Core` 与 `UI` 下的条状容器需要抽象出"轴向"概念（横/竖），现有的顶部/底部假设要拆掉。

**阶段 2 — 预览与反馈（P0/P1）**
窗口缩略图预览（屏幕录制权限 + 缩略图缓存 + 与现有 FSEvents 无关的独立刷新节流）；
App Flashes；镜像模式确认或补齐。

**阶段 3 — 状态与信息（P2/P3）**
App Progress / Status / Activity、主题扩展、电池声音、Devices、时钟日历、钉角浮动。

**阶段 4 — Command（独立立项，可选）**
不建议与上述阶段混做。

---

## 5. 每次同步上游的做法

```bash
# master 只做上游镜像，不提交
git checkout master
git fetch upstream
git merge --ff-only upstream/master
git push origin master

# iBar 开发主线
git checkout main
git merge master          # 把上游更新并进来
```

上游发版节奏约每周一次（0.18.x 系列 10 月内发了 6 个），合并冲突会集中在 P0 阶段动过的布局文件上。

---

## 6. 待决定

1. **Bundle ID 用什么**（例如 `com.ji1360677347.ibar`）
2. **图标**：自己做，还是先用一个临时占位图标把流程跑通
3. **是否需要自动更新**：不要则彻底删除 Sparkle 依赖；要则需自建 appcast 与密钥对
