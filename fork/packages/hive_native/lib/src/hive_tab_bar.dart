// FORK: fork-only file (see FORK.md).
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One tab: its label and an SF Symbol name (the native bar uses the
/// `.fill` variant for the selected tab when one exists).
@immutable
class HiveTabItem {
  const HiveTabItem({
    required this.title,
    required this.symbol,
    required this.icon,
  });

  final String title;
  final String symbol;

  /// The Material fallback for platforms without the native bar.
  final IconData icon;
}

/// iOS 26's Liquid Glass tab bar, as a native UITabBar hosted in Flutter.
///
/// Elsewhere it falls back to a Material [NavigationBar] so the app still
/// builds and runs.
class HiveTabBar extends StatefulWidget {
  const HiveTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.badges = const {},
    this.tint,
  });

  final List<HiveTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Tabs that show the system's unread dot.
  final Set<int> badges;
  final Color? tint;

  /// Width the native bar needs for [count] tabs.
  static double widthFor(int count) => 24.0 + count * 82.0;
  /// The native bar's height: its 62pt glass platter plus the padding
  /// UITabBar keeps below it (see HiveTabBar.swift).
  static const double height = 83;

  /// The visible platter's height, for laying the bar out against others.
  static const double platterHeight = 62;

  @override
  State<HiveTabBar> createState() => _HiveTabBarState();
}

class _HiveTabBarState extends State<HiveTabBar> {
  MethodChannel? _channel;

  Map<String, Object?> _state(BuildContext context) => {
    'items': [
      for (final item in widget.items)
        {'title': item.title, 'symbol': item.symbol},
    ],
    'selectedIndex': widget.selectedIndex,
    'badges': widget.badges.toList(),
    'brightness': Theme.of(context).brightness == Brightness.dark
        ? 'dark'
        : 'light',
    if (widget.tint != null) 'tint': widget.tint!.toARGB32(),
  };

  @override
  void didUpdateWidget(covariant HiveTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _channel?.invokeMethod<void>('setState', _state(context));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _channel?.invokeMethod<void>('setState', _state(context));
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          for (final (index, item) in widget.items.indexed)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: widget.badges.contains(index),
                child: Icon(item.icon),
              ),
              label: item.title,
            ),
        ],
      );
    }
    return SizedBox(
      width: HiveTabBar.widthFor(widget.items.length),
      height: HiveTabBar.height,
      child: Semantics(
        container: true,
        child: UiKitView(
          viewType: 'hive/tab_bar',
          creationParams: _state(context),
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: {
            Factory<TapGestureRecognizer>(TapGestureRecognizer.new),
          },
          onPlatformViewCreated: (id) {
            final channel = MethodChannel('hive/tab_bar/$id');
            channel.setMethodCallHandler((call) async {
              if (call.method == 'selected' && call.arguments is int) {
                widget.onSelected(call.arguments as int);
              }
            });
            _channel = channel;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}
