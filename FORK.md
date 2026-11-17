# Fork: philipbelesky/buzz

This is Philip Belesky's fork of [block/buzz](https://github.com/block/buzz). It exists to build a small, focused personal build of the **mobile** app (`mobile/`) that talks to Philip's own relay. Everything else in the monorepo is upstream's and is carried unchanged.

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
| `mobile/ios/Flutter/AppOverrides.xcconfig` | identity | iOS identity: `com.belesky.buzz` (Release), `com.belesky.buzz.dev` (Debug), team `CNPCA4RAWZ`; the app group and keychain group follow. Display name Hive (Release) and Hive Dev (Debug). Upstream gitignores this file as a local override slot; the fork force-tracks it so the identity is versioned. It also overrides upstream's per-worktree Debug ids, so Debug builds from two worktrees replace each other. | None: upstream never creates it. |
| `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | identity | The Hive icon in every size, replacing upstream's PNGs in place (the set's `Contents.json` is unchanged). | Low: upstream rarely changes its icon. On a conflict take upstream's `Contents.json`, then rerun the generator, which writes every size the set lists. |
| `fork/` | add | Fork-only tooling and assets. `fork/assets/make_hive_icon.py` draws the icon (`uv run --with pillow python fork/assets/make_hive_icon.py` from the repo root) and keeps the 1024 px master beside it; `fork/release/testflight.sh` builds and uploads to TestFlight. | None: upstream has no such directory. |
| `fork/packages/hive_native/` | add | A fork-only Flutter plugin for native iOS controls: `HiveTabBar`, a standalone UITabBar that iOS 26 draws as the Liquid Glass tab bar. A plugin, so Flutter's plugin registrant wires it up with no change to the Runner project or AppDelegate. | None. |
| `fork/tools/sim-driver/` | add | A generic XCUITest runner that drives the installed Hive Dev app in a simulator from a JSON step file (tap, type, swipe, screenshot, accessibility tree). See Testing. | None. |
| `mobile/pubspec.yaml`, `mobile/pubspec.lock` | config | Path dependency on `hive_native`. | Low: one block in the yaml; regenerate the lock with `flutter pub get` on conflict. |
| `mobile/lib/fork/hive_home.dart` | add | `HiveHomeTab` (Activity, Channels, DMs), `HiveInventoryScope` (which half of the inventory a ChannelsPage lists) and `kHiveTabs`, the switch every Home edit below tests. | None. |
| `mobile/lib/features/home/home_page.dart` | change | Behind `kHiveTabs`: no All/Solo/Team filter (fixed on All), Solo hidden, ChannelsPage's native header (Search and New) instead of the bell and community menu, a selected-tab state, Activity embedded as a tab, and `HiveTabBar` at the bottom left in place of Search/New/Bestie. iPad and foldable layouts still use upstream's navigation. | Medium: upstream changes Home often. Every edit is a `FORK:` line or block. |
| `mobile/lib/features/home/home_screen_shortcut_host.dart` | hide | App-icon quick actions drop New chat (Solo) and Message Bestie. | Low. |
| `mobile/lib/features/channels/channels_page.dart` | change | Imports the scope; the native header's title is the Hive tab's. | Low. |
| `mobile/lib/features/channels/channels_page/body.dart` | change | `showsChannels`/`showsDms` guards on the inventory groups, left unformatted so upstream's lines keep their indentation. | Low. |
| `mobile/lib/features/activity/activity_page.dart` | change | `showClose` parameter; the Activity tab has no close button. | Low. |

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

- **Upstream behaviour:** set `kHiveTabs` to `false` in `mobile/lib/fork/hive_home.dart` and run `flutter test`. With it `true`, upstream's Home tests that assert the filter, the bell or the Search/New/Bestie bar fail by design (16 in `test/features/home`, `test/features/activity` and `channels_page_test.dart` on 17 Nov 2026); everything else must pass either way.
- **Test relay:** a disposable relay runs on Repose beside the real one, as Compose project `buzz-test` in `~/.local/share/buzz-relay-test` (same image as production, its own database and keys), on `127.0.0.1:3012` and tailnet-only `wss://repose.tail66778.ts.net:13012`. `seed.sh` there creates four personas (`personas.env`), three channels, three DMs and two mentions on a fresh database. Stop it with `./run.sh stop`; wipe it with `docker compose -p buzz-test down -v`.
- **Simulator:** build with `flutter build ios --simulator --debug`, install, and sign in to the test relay as the seeded "Philip Test" persona through Enter a community link → Import a Nostr key. `fork/tools/sim-driver/drive.sh <steps.json> <udid>` then taps through the app and saves screenshots and accessibility trees to `/tmp/sim-driver/out`.

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
