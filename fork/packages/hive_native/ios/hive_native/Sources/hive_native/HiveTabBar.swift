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
  private let container: UIView
  private let tabBar = InsetFreeTabBar()
  private let channel: FlutterMethodChannel
  private var itemsSignature: [String] = []

  init(frame: CGRect, viewId: Int64, arguments args: Any?, messenger: FlutterBinaryMessenger) {
    container = UIView(frame: frame)
    channel = FlutterMethodChannel(name: "hive/tab_bar/\(viewId)", binaryMessenger: messenger)
    super.init()

    container.backgroundColor = .clear
    container.isOpaque = false
    tabBar.delegate = self
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(tabBar)
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      tabBar.topAnchor.constraint(equalTo: container.topAnchor),
      tabBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
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

/// A tab bar that ignores the window's safe area. Hosted in Flutter near the
/// bottom of the screen, a plain UITabBar takes the home-indicator inset as
/// its own; Flutter already places the bar above it. Even so the bar keeps
/// about 21pt of bottom padding below its 62pt glass platter, which is why
/// the Flutter side gives it 83pt and lets the padding hang below its slot.
private final class InsetFreeTabBar: UITabBar {
  override var safeAreaInsets: UIEdgeInsets { .zero }
}
