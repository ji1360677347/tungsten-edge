import AppKit
import Combine

/// 更新服务的占位实现。
///
/// ## 为什么没有自动更新
///
/// iBar 是 Tungsten Edge 的分支。上游的 `TRADEMARK.md` 明确写着：官方构建、Homebrew cask
/// 与 **Sparkle 更新源**只由 Moonbai Studio 提供；也明确要求分支版本换名换图标再分发。
/// 沿用官方 `https://tungstenedge.app/appcast.xml` 后果很直接——iBar 会把自己更新成
/// 官方 Tungsten Edge，覆盖掉分支的全部改动。
///
/// 因此这里不做任何网络检查：没有 appcast，没有 EdDSA 密钥，没有后台轮询。
/// 将来若要做自己的更新通道，需要三样东西：自建 appcast、自己的一对 EdDSA 密钥、
/// 以及把公钥写进 `Info.plist` 的 `SUPublicEDKey`。在那之前，界面上「检查更新」
/// 保留但恒为不可用状态，避免用户点了没反应却不知道原因。
///
/// ## 为什么保留 `UpdateControlling` 这层
///
/// 状态栏菜单与设置窗口都只认这个协议，不认具体实现。换掉实现不需要动界面代码。
@MainActor
final class UpdateService: ObservableObject, UpdateControlling {
    /// 永远为 false：没有可用的更新通道。
    @Published private(set) var canCheckForUpdates = false

    /// 永远为 nil：不会发现任何新版本。
    @Published private(set) var pendingUpdateVersion: String?

    /// 恒为 false 且写入无效。上游用 Sparkle 自己的偏好存这个值，这里没有对应存储，
    /// 也就不给界面一个"开关看起来能关、其实一直在联网"的假象。
    var automaticallyChecksForUpdates: Bool {
        get { false }
        set { _ = newValue }
    }

    var changes: AnyPublisher<Void, Never> {
        objectWillChange.map { _ in () }.eraseToAnyPublisher()
    }

    /// 上游在非临时副本的正常启动路径上调用它来起更新器。这里无事可做。
    func start() {
        // 无更新通道。
    }

    /// 上游在此处打开 Sparkle 的更新窗口。这里无事可做。
    func checkForUpdates() {
        // 无更新通道。
    }
}
