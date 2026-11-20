import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/data/changelog_data.dart';

/// Muestra las novedades la primera vez que se abre una versión nueva.
/// Sin versión guardada se considera primera instalación y no muestra nada.
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
