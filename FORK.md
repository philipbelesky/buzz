# Fork: philipbelesky/buzz

This is Philip Belesky's fork of [block/buzz](https://github.com/block/buzz). It exists to build a small, focused personal build of the **mobile** app (`mobile/`) that talks to Philip's own relay. Everything else in the monorepo is upstream's and is carried unchanged.

Read this file before changing anything in the fork, and update it in the same commit as any change that diverges from upstream.

## Rules for diverging

The goal is that merging upstream stays cheap. Every rule below serves that.

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
| `mobile/ios/Flutter/AppOverrides.xcconfig` | identity | iOS identity: `com.belesky.buzz` (Release), `com.belesky.buzz.dev` (Debug), team `CNPCA4RAWZ`; the app group and keychain group follow. Upstream gitignores this file as a local override slot; the fork force-tracks it so the identity is versioned. It also overrides upstream's per-worktree Debug ids, so Debug builds from two worktrees replace each other. | None: upstream never creates it. |

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

## Integration log

| Date | Upstream commit | Notes |
|---|---|---|
| 2026-11-17 | `3d975351` | Fork created from `block/buzz` main. |
