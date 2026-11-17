// FORK: fork-only file (see FORK.md).
import Flutter
import UIKit

/// Registers Hive's native controls with the Flutter engine. Flutter's
/// generated plugin registrant calls this, so the Runner needs no changes.
public final class HiveNativePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      HiveTabBarFactory(messenger: registrar.messenger()),
      withId: "hive/tab_bar"
    )
  }
}
