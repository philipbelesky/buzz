// FORK: fork-only file (see FORK.md). Hive's Home navigation: three tabs in
// a native Liquid Glass tab bar instead of upstream's All/Solo/Team filter.
import 'package:flutter/widgets.dart';
import 'package:hive_native/hive_native.dart';

import '../shared/theme/buzz_icons.dart';

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
    required super.child,
  });

  final HiveHomeTab tab;

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
  bool updateShouldNotify(HiveInventoryScope oldWidget) => tab != oldWidget.tab;
}

/// Whether Home uses Hive's tabs. A constant rather than deletions, so the
/// upstream code it replaces stays in place and merges cleanly.
const kHiveTabs = true;
