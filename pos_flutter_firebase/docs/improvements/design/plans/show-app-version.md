# Fix: no one can tell which version is installed when reporting a bug

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/show-app-version
- **Needs new dependency**: package_info_plus (read app name, version, build number)

## Why

When a branch reports a bug on the admin's `.exe` or a cashier's phone, the first question is which version they're on, and the app has no place to answer it. A dim version line at the bottom of settings (and the desktop config screen) ends that back-and-forth.

## Where

No version display exists (`PackageInfo|package_info_plus|buildNumber` grep over `lib/` returns nothing; this app does not use Shorebird, so no patch number is needed). New file `lib/shared/widgets/version_indicator.dart`, article widget verbatim minus the Shorebird part:

```dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionIndicator extends StatefulWidget {
  const VersionIndicator({super.key});

  @override
  State<VersionIndicator> createState() => _VersionIndicatorState();
}

class _VersionIndicatorState extends State<VersionIndicator> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final PackageInfo info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _label = '${info.appName} ${info.version} (${info.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_label == null) {
      return const SizedBox.shrink();
    }

    return Text(
      _label!,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: Colors.grey.shade500,
      ),
    );
  }
}
```

Mount points (both settings surfaces, since admins live on desktop and cashiers on mobile):
- `lib/features/settings/ui/settings_screen.dart:129-142` — after the Importar-respaldo card, before the list end:
```dart
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
→ insert `const SizedBox(height: 16),` + `const Center(child: VersionIndicator()),` before the closing `],` of the children list, and add the import.
- `lib/features/home/ui/desktop/business_config_screen.dart:104-121` — after the Importar-respaldo card at `:105-113`, before the closing of the children/builder:
```dart
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.upload_file_outlined, color: AppColors.warning),
                      title: const Text('Importar respaldo'),
                      subtitle: const Text('Restaura en este dispositivo un respaldo local'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _importBackup(context),
                    ),
                  ),
                ],
              );
```
→ same insertion (`SizedBox` + `Center(child: VersionIndicator())`) plus import.

## The fix

Article's drop-in widget (Shorebird branch removed — not in `pubspec.yaml`) pasted in the two places above. Dim 12px grey per the article: the line whispers.

## Steps

1. Add `package_info_plus` to `pubspec.yaml` and run `flutter pub get`.
2. Create `lib/shared/widgets/version_indicator.dart` with the widget above, exactly.
3. Insert the version line in `settings_screen.dart` and `business_config_screen.dart` as above, with imports.
4. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "VersionIndicator" lib/features/settings/ui/settings_screen.dart` → 2 (import + usage)
- `grep -c "VersionIndicator" lib/features/home/ui/desktop/business_config_screen.dart` → 2
- `grep -c "package_info_plus" pubspec.yaml` → 1

## Don't touch

- `pubspec.yaml` version value itself (changelog plan owns version bumps).
- Any settings/config logic or list order beyond appending at the end.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The installed `package_info_plus` API differs (`fromPlatform`, `appName`, `version`, `buildNumber`) — adapt minimally and report.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
