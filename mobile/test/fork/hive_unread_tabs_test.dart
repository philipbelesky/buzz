// FORK: fork-only test (see FORK.md).
import 'package:buzz/fork/hive_home.dart';
import 'package:buzz/shared/theme/theme_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> container(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [savedPrefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('Unread filters start off on a fresh install', () async {
    final c = await container({});
    expect(c.read(hiveUnreadTabsProvider), isEmpty);
  });

  test('Unread filters survive a relaunch', () async {
    final first = await container({});
    first
        .read(hiveUnreadTabsProvider.notifier)
        .setUnreadOnly(HiveHomeTab.dms, true);
    first
        .read(hiveUnreadTabsProvider.notifier)
        .setUnreadOnly(HiveHomeTab.activity, true);
    first
        .read(hiveUnreadTabsProvider.notifier)
        .setUnreadOnly(HiveHomeTab.activity, false);
    final saved = (await SharedPreferences.getInstance()).getStringList(
      HiveUnreadTabs.prefsKey,
    )!;

    final relaunched = await container({HiveUnreadTabs.prefsKey: saved});
    expect(relaunched.read(hiveUnreadTabsProvider), {HiveHomeTab.dms});
  });

  test('unknown saved tab names are ignored', () async {
    final c = await container({
      HiveUnreadTabs.prefsKey: ['channels', 'gone'],
    });
    expect(c.read(hiveUnreadTabsProvider), {HiveHomeTab.channels});
  });
}
