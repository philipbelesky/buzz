// FORK: fork-only file (see FORK.md).
import Flutter
import UIKit

final class HiveTabBarFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    HiveTabBarPlatformView(frame: frame, viewId: viewId, arguments: args, messenger: messenger)
  }
}

/// A standalone UITabBar, which iOS 26 draws as the floating Liquid Glass bar.
/// Items show icons only; each title becomes its VoiceOver label.
///
/// Arguments and `setState`: `items` ([{title, symbol}], SF Symbol names),
/// `selectedIndex`, `badges` (indexes that show a dot), `brightness`
/// ("light"/"dark") and `tint` (ARGB int). Selection is reported back as
/// `selected` with the index.
final class HiveTabBarPlatformView: NSObject, FlutterPlatformView, UITabBarDelegate {
  private let container: LeadingTabBarContainer
  private let tabBar = InsetFreeTabBar()
  private let channel: FlutterMethodChannel
  private var itemsSignature: [String] = []

  init(frame: CGRect, viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
    container = LeadingTabBarContainer(frame: frame, tabBar: tabBar)
    channel = FlutterMethodChannel(name: "hive/tab_bar/\(viewId)", binaryMessenger: messenger)
    super.init()

    tabBar.delegate = self
    // On iPad the regular width class draws a shorter, label-style platter;
    // the compact class keeps the iPhone's 62pt one, which New and the
    // Flutter layout are sized against.
    if #available(iOS 17.0, *) {
      tabBar.traitOverrides.horizontalSizeClass = .compact
    }
    apply(args)

    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setState" else { return result(FlutterMethodNotImplemented) }
      self?.apply(call.arguments)
      result(nil)
    }
  }

  func view() -> UIView { container }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    channel.invokeMethod("selected", arguments: item.tag)
  }

  private func apply(_ value: Any?) {
    guard let args = value as? [String: Any] else { return }
    if let items = args["items"] as? [[String: Any]] {
      let signature = items.map { "\($0["title"] ?? "")|\($0["symbol"] ?? "")" }
      if signature != itemsSignature {
        itemsSignature = signature
        tabBar.setItems(items.enumerated().map { index, item in
          let symbol = item["symbol"] as? String ?? "circle"
          let tabItem = UITabBarItem(title: nil, image: UIImage(systemName: symbol), tag: index)
          tabItem.accessibilityLabel = item["title"] as? String
          tabItem.selectedImage = UIImage(systemName: "\(symbol).fill") ?? UIImage(systemName: symbol)
          return tabItem
        }, animated: false)
      }
    }
    let badges = Set((args["badges"] as? [NSNumber] ?? []).map(\.intValue))
    for item in tabBar.items ?? [] {
      // An empty badge value draws iOS's small dot.
      item.badgeValue = badges.contains(item.tag) ? "" : nil
    }
    if let index = (args["selectedIndex"] as? NSNumber)?.intValue,
       let items = tabBar.items, items.indices.contains(index) {
      tabBar.selectedItem = items[index]
    }
    switch args["brightness"] as? String {
    case "dark": container.overrideUserInterfaceStyle = .dark
    case "light": container.overrideUserInterfaceStyle = .light
    default: container.overrideUserInterfaceStyle = .unspecified
    }
    if let tint = (args["tint"] as? NSNumber)?.uint32Value {
      tabBar.tintColor = UIColor(
        red: CGFloat((tint >> 16) & 0xFF) / 255,
        green: CGFloat((tint >> 8) & 0xFF) / 255,
        blue: CGFloat(tint & 0xFF) / 255,
        alpha: CGFloat((tint >> 24) & 0xFF) / 255
      )
    }
  }
}

/// Holds the tab bar so its glass platter sits at the leading edge rather
/// than centred. UITabBar sizes the platter for its items (squeezing them when
/// the bar is too narrow) and centres it; this shifts the whole bar left until
/// the platter is `margin` from the container's edge, the inset a
/// UITabBarController's bar keeps.
private final class LeadingTabBarContainer: UIView {
  private let tabBar: UITabBar
  private let margin: CGFloat = 21

  init(frame: CGRect, tabBar: UITabBar) {
    self.tabBar = tabBar
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    addSubview(tabBar)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override func layoutSubviews() {
    super.layoutSubviews()
    tabBar.frame = bounds
    tabBar.layoutIfNeeded()
    // The platter is the bar's one subview narrower than the bar itself.
    let platters = tabBar.subviews.filter { $0.frame.width < tabBar.bounds.width - 1 }
    let platterMinX = platters.map(\.frame.minX).min() ?? margin
    tabBar.frame.origin.x = -max(0, platterMinX - margin)
    // Its bottom `margin` above the container's, as on an iPhone. iPad keeps
    // less padding below the platter, which would drop it below New.
    if let platterMaxY = platters.map(\.frame.maxY).max() {
      tabBar.frame.origin.y = bounds.height - margin - platterMaxY
    }
  }
}

/// A tab bar that ignores the window's safe area. Hosted in Flutter near the
/// bottom of the screen, a plain UITabBar takes the home-indicator inset as
/// its own. Even so the bar keeps about 21pt of bottom padding below its
/// 62pt glass platter, so the Flutter side gives it 83pt on the screen's
/// bottom edge, which puts the platter where a UITabBarController would.
private final class InsetFreeTabBar: UITabBar {
  override var safeAreaInsets: UIEdgeInsets { .zero }
}
