# Fix: users never hear about what's new after an update

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/in-app-changelog
- **Needs new dependency**: package_info_plus (read installed version), shared_preferences (persist last seen version), pub_semver (compare versions)

## Why

After an update, users open the app and nothing tells them what's new. In this pollería app the admin gets features like split payment or loss tracking and never notices. Showing the changes as a list on first open after an update tells the admin who asked for a fix that they were heard.

## Where

The app has no changelog infrastructure at all (`grep changelog|whats_new|last_seen_version` over `lib/` returns nothing). Version source today is only this line:

```dart
// pubspec.yaml:19 — current
version: 1.0.1+2
```

Providers are registered here, where the new notifier will be added:

```dart
// lib/main.dart:89-100 — current
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeNotifier()),
          ChangeNotifierProvider(create: (_) => FontSizeNotifier()),
          ChangeNotifierProvider(
            create: (_) => AppSessionNotifier(
              appContextService: _serviceLocator.appContextRepository,
            )..loadSession(),
          ),
          ..._serviceLocator.providers,
        ],
```

The check will run from the home state, which already is a `StatefulWidget` with `initState` available:

```dart
// lib/features/home/ui/home_screen.dart:32-37 — current
class _HomeScreenState extends State<HomeScreen> {
  AuthRepository get _authService => context.read<AuthRepository>();
  bool get _isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  int _selectedIndex = 0;
```

The settings list ends here, where a "Novedades" entry will be appended so the admin can reopen the changelog any time:

```dart
// lib/features/settings/ui/settings_screen.dart:129-142 — current
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Importar respaldo'),
              subtitle: const Text('Restaura en este dispositivo un respaldo local'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importLocalBackup(context),
            ),
          ),
        ],
      ),
    );
  }
```

## The fix

The article's fix, adapted: the app is Spanish-only, so there is a single `es` list per version (no `Language` enum). State uses `ChangeNotifier` like the rest of this codebase (`ThemeNotifier`, `AppSessionNotifier`), not a Cubit. Existing users have no saved version, so per the article they count as first install and will only see future updates.

End state:

```dart
// NEW lib/features/settings/data/changelog_data.dart
const Map<String, List<String>> kChangelogEs = {
  '1.0.6': [
    'Cobro con pago dividido oculto tras el botón de tres puntos, con cálculo de cambio.',
    'La pantalla de Pérdidas ahora está visible para todos los usuarios.',
  ],
  '1.0.5': [
    'Cobro dividido entre efectivo y tarjeta.',
    'Nueva pantalla de Pérdidas de mercancía con historial.',
  ],
};
```

```dart
// NEW lib/shared/providers/changelog_notifier.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/data/changelog_data.dart';

class ChangelogNotifier extends ChangeNotifier {
  static const _prefsKey = 'last_seen_version';

  String? _currentVersion;
  List<String>? _unseen;
  List<String>? get unseen => _unseen;

  Future<void> initialize() async {
    final current = (await PackageInfo.fromPlatform()).version;
    _currentVersion = current;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_prefsKey);
    if (lastSeen == null) {
      await prefs.setString(_prefsKey, current);
      return;
    }
    if (lastSeen == current) return;
    final changes = _unseenChanges(lastSeen: lastSeen, current: current);
    if (changes.isEmpty) {
      await prefs.setString(_prefsKey, current);
      return;
    }
    _unseen = changes;
    notifyListeners();
  }

  List<String> _unseenChanges({required String lastSeen, required String current}) {
    final lastSeenVersion = Version.parse(lastSeen);
    final currentVersion = Version.parse(current);
    final result = <String>[];
    for (final entry in kChangelogEs.entries) {
      final entryVersion = Version.parse(entry.key);
      if (entryVersion > lastSeenVersion && entryVersion <= currentVersion) {
        result.addAll(entry.value);
      }
    }
    return result;
  }

  Future<void> dismiss() async {
    final version = _currentVersion;
    if (version != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, version);
    }
    _unseen = null;
    notifyListeners();
  }
}
```

`pubspec.yaml:19` becomes `version: 1.0.6+7` (matches latest tag `v1.0.6`). Dependencies gain `package_info_plus`, `shared_preferences`, `pub_semver` (use current versions from `flutter pub add`, which also runs `pub get`).

`main.dart` providers gain one line after the `FontSizeNotifier` line:

```dart
          ChangeNotifierProvider(create: (_) => ChangelogNotifier()),
```

`_HomeScreenState` gains (needs `import 'package:provider/provider.dart';` — already imported — plus the notifier import and `widgets` for the post-frame callback — `material.dart` already imported):

```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowChangelog());
  }

  Future<void> _maybeShowChangelog() async {
    final changelog = context.read<ChangelogNotifier>();
    await changelog.initialize();
    if (!mounted || changelog.unseen == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novedades'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final change in changelog.unseen!) Text('• $change'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              changelog.dismiss();
              Navigator.pop(context);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
```

Settings gains a "Novedades" card after the Importar-respaldo card that re-opens the same dialog by calling `context.read<ChangelogNotifier>()` and showing `unseen ??` the latest version entry (if null, show a dialog with the latest `kChangelogEs` values). Implement it as a private method `_showChangelogAgain(BuildContext context)` reusing the exact dialog above.

## Steps

1. In `pubspec.yaml`, change line 19 to `version: 1.0.6+7` and add the three dependencies, then run `flutter pub get`.
2. Create `lib/features/settings/data/changelog_data.dart` with the `kChangelogEs` map above, exactly.
3. Create `lib/shared/providers/changelog_notifier.dart` with the class above, exactly.
4. In `lib/main.dart`, add the import and the `ChangeNotifierProvider(create: (_) => ChangelogNotifier()),` line after the `FontSizeNotifier` provider line.
5. In `lib/features/home/ui/home_screen.dart`, add the import, `initState`, and `_maybeShowChangelog` exactly as above.
6. In `lib/features/settings/ui/settings_screen.dart`, add the "Novedades" card plus `_showChangelogAgain`, reusing the same dialog content.
7. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus these file-scoped greps:
- `grep -c "ChangelogNotifier" lib/main.dart` → 1
- `grep -c "_maybeShowChangelog" lib/features/home/ui/home_screen.dart` → 2
- `grep -c "Novedades" lib/features/settings/ui/settings_screen.dart` → 2
- `grep -c "package_info_plus\|shared_preferences\|pub_semver" pubspec.yaml` → 3

## Don't touch

- `docs/` outside this plan's scope; Firestore rules/indexes; any existing screen logic. The changelog map keys must stay parseable by `pub_semver` (`mayor.minor.patch`).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The fix seems to require touching something in "Don't touch".
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
