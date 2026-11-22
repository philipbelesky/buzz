# Fork: philipbelesky/buzz

This is Philip Belesky's fork of [block/buzz](https://github.com/block/buzz). It exists to build a small, focused personal build of the **mobile** app (`mobile/`) that talks to Philip's own relay. Everything else in the monorepo is upstream's and is carried unchanged.

The build is called **Hive**. It is not the Buzz desktop app Philip runs, which is Buzz 1.x built from [block/buzz-app](https://github.com/block/buzz-app), cloned for reference at `~/Sites/buzz-app` (desktop UI, plugins, agent harness). `desktop/` in this repository is upstream's deprecated 0.X app: do not use it to answer questions about the installed desktop app.

Read this file before changing anything in the fork, and update it in the same commit as any change that diverges from upstream.

## Rules for diverging

The goal is that merging upstream stays cheap. Every rule below serves that.

- **Keep fork-only files under `fork/`** where they need no fixed location in the build.
- **Prefer upstream's extension points to edits.** Build-time settings (`--dart-define`), the gitignored-by-default `mobile/ios/Flutter/AppOverrides.xcconfig` (tracked here on purpose, see the register), and new files are all conflict-free. Editing a file upstream also edits is the last resort.
- **Hide, don't delete.** Remove a feature from navigation or entry points rather than deleting its code. Deleted upstream code conflicts with every later upstream change to it; unreachable code does not.
- **Mark every edit to an upstream file** with a `FORK:` comment on or above the changed lines, saying what changed and why, so `git grep -n "FORK:"` lists them. Files that are wholly ours need no marker; they are listed in the register.
- **One divergence per commit**, message prefixed `fork:` (for example `fork(mobile): use Philip's bundle id`), so `git log --oneline --grep '^fork'` is the fork's history.
- **Register every divergence** in the table below, in the same commit.
- **Do not open PRs to upstream from `main`.** Anything worth proposing upstream goes on its own branch cut from `upstream/main`, without fork commits.

## Branches and remotes

- `origin` is `philipbelesky/buzz`; `upstream` is `block/buzz`.
- `main` is the fork: upstream plus our `fork:` commits. Upstream is brought in by **merging** `upstream/main` into `main`, never by rebasing, so published history is never rewritten and each integration is one reviewable merge commit.
- Experiments go on short-lived branches off `main`.

## Divergence register

Fork-owned or fork-modified paths. Kind is one of: identity (signing, ids, names), config (build settings), hide (feature removed from reach), change (behaviour or UX changed), add (new fork-only code or files), docs.

| Path | Kind | What and why | Conflict risk |
|---|---|---|---|
| `FORK.md` | docs | This file. | None: upstream has no such file. |
| `AGENTS.md` (top block only) | docs | Points agents at this file before upstream's guide. | Low: a short block above upstream's first heading. |
| `mobile/ios/Flutter/AppOverrides.xcconfig` | identity | iOS identity: `com.belesky.buzz` (Release), `com.belesky.buzz.dev` (Debug), team `CNPCA4RAWZ`; the app group and keychain group follow. Display name Hive (Release) and Hive Dev (Debug). Device family iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`; upstream is iPhone-only, so on iPad it ran as a fixed-size iPhone window); the targets set no family of their own, so this wins for the app and its extensions. Push gateway `https://repose.tail66778.ts.net` for Release only: Philip's gateway for this app id shares the relay's tailnet origin (on Repose: `compose.push.yml` beside the relay, routes in `media-stack-serve`) and accepts only production App Attest, so Debug builds stay push-less. Upstream gitignores this file as a local override slot; the fork force-tracks it so the identity is versioned. It also overrides upstream's per-worktree Debug ids, so Debug builds from two worktrees replace each other. | None: upstream never creates it. |
| `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | identity | The Hive icon in every size, replacing upstream's PNGs in place (the set's `Contents.json` is unchanged). | Low: upstream rarely changes its icon. On a conflict take upstream's `Contents.json`, then rerun the generator, which writes every size the set lists. |
| `fork/` | add | Fork-only tooling and assets. `fork/assets/make_hive_icon.py` draws the icon (`uv run --with pillow python fork/assets/make_hive_icon.py` from the repo root) and keeps the 1024 px master beside it; `fork/release/testflight.sh` builds and uploads to TestFlight. | None: upstream has no such directory. |
| `mobile/ios/Runner/Info.plist` | config | `UISupportedInterfaceOrientations~ipad` with all four orientations, which iPad windowing and multitasking require. | Low: one marked block at the end of the dict. |
| `fork/packages/hive_native/` | add | A fork-only Flutter plugin for native iOS controls: `HiveTabBar`, a standalone UITabBar that iOS 26 draws as the Liquid Glass tab bar, icons only (titles become VoiceOver labels), its platter at the leading edge rather than centred and 21pt above its bottom edge. It is forced to the compact width class so iPad draws the iPhone's 62pt platter rather than its shorter one. A plugin, so Flutter's plugin registrant wires it up with no change to the Runner project or AppDelegate. | None. |
| `mobile/test/fork/` | add | Tests for fork-only code: the persisted Unread filters. | None. |
| `fork/tools/sim-driver/` | add | A generic XCUITest runner that drives the installed Hive Dev app in a simulator from a JSON step file (tap, type, swipe, screenshot, accessibility tree). See Testing. | None. |
| `mobile/pubspec.yaml`, `mobile/pubspec.lock` | config | Path dependency on `hive_native`. | Low: one block in the yaml; regenerate the lock with `flutter pub get` on conflict. |
| `mobile/lib/fork/hive_home.dart` | add | `HiveHomeTab` (Activity, Channels, DMs), `HiveInventoryScope` (which half of the inventory a ChannelsPage lists, and whether it lists only unread conversations), `HiveUnreadToggle` (the Unread chip, styled as Activity's), `HiveActivityFilters` (Activity's filter choices and scroll position, kept by Home across tab switches), `hiveUnreadTabsProvider` (which tabs have Unread on, saved device-wide in SharedPreferences so the choice survives relaunches) and `kHiveTabs`, the switch every Home edit below tests. | None. |
| `mobile/lib/features/home/home_page.dart` | change | Behind `kHiveTabs`: Solo hidden, a selected-tab state, its own `reselect` signal for tapping the selected tab again (upstream removed its own with the All/Solo/Team filter; only Activity listens, so Channels and DMs no longer scroll to the top on a second tap), a per-tab Unread toggle (persisted through `hiveUnreadTabsProvider`, Activity's included), one ChannelsPage serving all three tabs (so they share its header), `HiveTabBar` and a round New button (New channel, New DM) in place of Search/New/Bestie, on one row where Slack's iOS app puts its tab bar: the bar on the screen's bottom edge so its platter lands where a UITabBarController's would (21pt up and in), left-aligned (`HiveTabBar` shifts the platter iOS centres), New at the right with the same height and inset. Both are drawn in the body's Stack; the bottom bar slot stays, empty, so the body keeps its bottom padding. With two panes (iPad, `usesConversationPanes`) the row and its footer backdrop sit at the foot of the list pane instead of across the window. Foldable layouts still use upstream's navigation. Upstream's voice-recording blur (`focusedMessages`) wraps only upstream's Home: it comes from the Bestie button Hive hides. | Medium: upstream changes Home often. Every edit is a `FORK:` line or block. |
| `mobile/lib/features/home/home_screen_shortcut_host.dart` | hide | App-icon quick actions drop New chat (Solo) and Message Bestie. | Low. |
| `mobile/lib/features/channels/channels_page.dart` | change | Under a Hive tab: `messages` is false, so the page draws its standalone native header rather than Home's Messages header (Home's actions builder goes unused), with a native large title (the tab's name), Search and the community avatar as the trailing actions (Create moves to Home's bottom right), and `hiveActivityBuilder`, which draws the Activity tab under the same header in place of the inventory, in FrostedScaffold's pinned body so its filters ride up with the collapsing title. | Medium: the header block is dense; every change is a `FORK:` line. |
| `mobile/lib/features/channels/channels_page/body.dart` | change | On upstream's desktop-style sections (Starred, workspaces, Team, Direct messages): each Hive tab keeps only its own kind of row (`hiveKeeps`), drops the other tab's home section, and lists a workspace on the tab of the rows it holds (an empty one on Channels). No heading where the tab's large title already names its only section, the Unread chip at the top of the Channels and DMs tabs and the filter it applies to every group, left unformatted so upstream's lines keep their indentation. | Low. |
| `mobile/lib/features/channels/channels_page/sections.dart` | change | `_ChannelSection.showHeading`: without a heading the group cannot collapse, and its sort menu is not shown (sort order still syncs from Desktop). | Low. |
| `mobile/lib/features/activity/activity_page.dart` | change | `hiveTopInset` parameter: under Hive's Home header it drops its own title row and close button, starts below the header, and scrolls with the pinned body's primary controller. `hiveFilters`: Home's filter notifiers replace its own `useState` ones, so the choices survive tab switches, and the list's scroll position is saved there and restored when the tab returns. | Low. |

## Known limits of running beside Block's app

- Both apps register the `buzz://` URL scheme (`mobile/ios/Runner/Info.plist`). With both installed, iOS chooses which one opens `buzz://` links, including relay invite links. Uninstall one, or change the fork's scheme in a later divergence (relay web pages emit `buzz://join` links, so that also needs a matching relay-side change).
- Builderlab sign-in uses the hard-coded callback scheme `xyz.block.buzz.mobile`. Builderlab is disabled unless its three `--dart-define`s are set (`mobile/README.md`), and the fork does not set them.
- Push notifications need a gateway serving the fork's own app id; see Philip's plan in Orca's notes ("2026-11-17 buzz mobile push plan"). Push stays off until then.
- Android is not configured for the fork; it still builds as upstream's debug identity.

## Integrating upstream

1. `git fetch upstream` and check `git log --oneline main..upstream/main -- mobile` to see what changed in the app.
2. `git switch main && git merge upstream/main`. Resolve conflicts in favour of upstream's structure, re-applying our change on top; re-check each `FORK:` marker still says what the code does.
3. Check the register against `git grep -n "FORK:"` and `git diff upstream/main...main --stat`; every path in the diff should be in the register.
4. From `mobile/` with Hermit active (`. bin/activate-hermit` at the repo root): `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter build ios --simulator --debug` and launch it. Note any upstream test failures that also fail on `upstream/main` rather than fixing them here.
5. Add a row to the log below and push.

## Testing

- **Upstream behaviour:** set `kHiveTabs` to `false` in `mobile/lib/fork/hive_home.dart` and run `flutter test`. With it `true`, upstream's Home tests that assert the filter, the bell or the Search/New/Bestie bar fail by design (21 in `test/features/home`, `test/features/activity` and `channels_page_test.dart` on 17 Nov 2026); everything else must pass either way.
- **Test relay:** a disposable relay runs on Repose beside the real one, as Compose project `buzz-test` in `~/.local/share/buzz-relay-test` (its own database and keys, on production's pinned image: run `sync-image.sh` there after upgrading the real relay), on `127.0.0.1:3012` and tailnet-only `wss://repose.tail66778.ts.net:13012`. `seed.sh` there creates four personas (`personas.env`), three channels, three DMs and two mentions on a fresh database. Stop it with `./run.sh stop`; wipe it with `docker compose -p buzz-test down -v`.
- **Simulator:** build with `flutter build ios --simulator --debug`, install, and sign in to the test relay as the seeded "Philip Test" persona through Enter a community link → Import a Nostr key. `fork/tools/sim-driver/drive.sh <steps.json> <udid>` then taps through the app and saves screenshots and accessibility trees to `/tmp/sim-driver/out`. Flutter's accessibility tree sometimes comes back empty after a route transition (upstream's Home too, so not a fork regression); steps then fall back to `tapAt` coordinates.

## Releasing to TestFlight

The iOS app is App Store Connect app `6835712117` (bundle id `com.belesky.buzz`, team `CNPCA4RAWZ`). From a clean checkout of `main` on Repose:

```bash
fork/release/testflight.sh
```

It archives with the shared development identity, re-signs with the cloud-managed distribution certificate of the Apple account signed in to Xcode, and uploads with that account. The version is `HIVE_VERSION` (default in the script) and the build number is the commit count of `HEAD`, which only grows because upstream is merged, never rebased. Logs and the archive land in `mobile/build/hive-testflight/` (gitignored). `--no-upload` stops at an `.ipa`. App Store Connect then processes the build for 10–30 minutes before TestFlight offers it to the internal testing group. Build 1 (0.1.0) was uploaded by hand on 17 Nov 2026.

## Integration log

| Date | Upstream commit | Notes |
|---|---|---|
| 2026-11-17 | `3d975351` | Fork created from `block/buzz` main. |
| 2026-11-22 | `0e7fd48d` | 129 upstream commits. Conflicts in Home, the Channels page, its body and sections, Activity and `Podfile.lock`. Upstream moved iOS plugins to Swift Package Manager (`hive_native` already ships a `Package.swift`, so it left `Podfile.lock` too), replaced the All/Solo/Team filter and its `messagesFilters` header with desktop's unified sections, and added per-section filters, including an Unread mode that overlaps Hive's Unread toggle. |
