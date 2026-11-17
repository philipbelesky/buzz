// FORK: fork-only file (see FORK.md). Hive's Home navigation: three tabs in
// a native Liquid Glass tab bar instead of upstream's All/Solo/Team filter.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_native/hive_native.dart';

import '../shared/theme/buzz_icons.dart';
import '../shared/theme/theme.dart';
import '../shared/widgets/ios_glass_navigation_button.dart';

enum HiveHomeTab {
  activity('Activity', 'bell', BuzzIcons.bell),
  channels('Channels', 'number', BuzzIcons.hash),
  dms('DMs', 'bubble.left.and.bubble.right', BuzzIcons.messageCircle);

  const HiveHomeTab(this.title, this.symbol, this.icon);

  final String title;
  final String symbol;
  final IconData icon;

  HiveTabItem get item => HiveTabItem(title: title, symbol: symbol, icon: icon);
}

/// Which part of the channel inventory the Channels page under it lists:
/// stream channels (Starred, custom sections and Channels) or DMs.
///
/// An inherited widget rather than constructor parameters, so upstream's
/// ChannelsPage only reads it where the sections are built.
class HiveInventoryScope extends InheritedWidget {
  const HiveInventoryScope({
    super.key,
    required this.tab,
    this.unreadOnly = false,
    this.onUnreadOnlyChanged,
    required super.child,
  });

  final HiveHomeTab tab;

  /// Whether the Channels or DMs tab lists only unread conversations.
  final bool unreadOnly;
  final ValueChanged<bool>? onUnreadOnlyChanged;

  /// Whether this tab's inventory lists only unread conversations.
  static bool unreadOnlyOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<HiveInventoryScope>()
          ?.unreadOnly ??
      false;

  /// Null outside Hive's Home, where upstream shows every group.
  static HiveHomeTab? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HiveInventoryScope>()?.tab;

  /// The page title for the tab under this scope, or '' outside Hive's Home.
  static String titleOf(BuildContext context) => maybeOf(context)?.title ?? '';

  static bool showsChannels(BuildContext context) =>
      maybeOf(context) != HiveHomeTab.dms;

  static bool showsDms(BuildContext context) =>
      maybeOf(context) != HiveHomeTab.channels;

  @override
  bool updateShouldNotify(HiveInventoryScope oldWidget) =>
      tab != oldWidget.tab || unreadOnly != oldWidget.unreadOnly;
}

/// Whether Home uses Hive's tabs. A constant rather than deletions, so the
/// upstream code it replaces stays in place and merges cleanly.
const kHiveTabs = true;

/// The Unread toggle at the top of the Channels and DMs tabs: the same glass
/// chip as Activity's Unread filter (`activity_page/header_actions.dart`).
class HiveUnreadToggle extends StatelessWidget {
  const HiveUnreadToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HiveInventoryScope>();
    if (scope == null) return const SizedBox.shrink();
    final selected = scope.unreadOnly;
    void toggle() => scope.onUnreadOnlyChanged?.call(!selected);
    final Widget chip;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final scaler = MediaQuery.textScalerOf(context);
      final height = max(48.0, scaler.scale(16) * 1.4 + 16);
      final width =
          (TextPainter(
            text: TextSpan(
              text: 'Unread',
              style: filterChipTextStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            textScaler: scaler,
            textDirection: Directionality.of(context),
          )..layout()).width +
          32;
      chip = IosGlassNavigationButton(
        key: ValueKey('hive-unread-filter-${scope.tab.name}'),
        icon: IosGlassNavigationIcon.more,
        label: 'Unread',
        semanticLabel: 'Unread',
        isSelected: selected,
        onPressed: toggle,
        width: width,
        height: height,
        controlSize: height - 8,
        fillWidth: true,
        foregroundColor: context.colors.primary,
      );
    } else {
      chip = FilterChip(
        label: const Text('Unread'),
        selected: selected,
        onSelected: (_) => toggle(),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Grid.gutter - Grid.half,
        0,
        Grid.gutter,
        Grid.xxs,
      ),
      child: Align(alignment: Alignment.centerLeft, child: chip),
    );
  }
}
