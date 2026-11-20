# Fix: text selection uses default colors instead of the brand

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/selection-color
- **Needs new dependency**: none

## Why

Every text field in the app (product names, phone numbers, amounts) selects text with Flutter's default tint instead of the pollería's orange brand. Matching selection, handles and cursor to the brand color makes typing feel like part of the app. Brand color is `AppColors.accent = Color(0xFFF76707)` (see `lib/core/theme/glass_theme.dart:6`).

## Where

The theme has no `textSelectionTheme` (grep over `lib/` returns nothing), while dozens of `TextField`s exist across POS, products, employees, settings and dialogs. The two `ThemeData` constructors to change:

```dart
// lib/core/theme/glass_theme.dart:46-54 — current (light)
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.lightSurface,
      error: AppColors.danger,
    ),
```

```dart
// lib/core/theme/glass_theme.dart:190-195 — current (dark)
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: ColorScheme.dark(
      primary: AppColors.accent,
```

## The fix

The article's fix with the brand color (orange is dark, so the selection gets opacity per the article, cursor and handles stay full color). Add to BOTH `light()` and `dark()`, right after their `colorScheme:` block:

```dart
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.accent.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.accent,
      cursorColor: AppColors.accent,
    ),
```

This covers `TextField`, `SelectableText` and anything else using text selection app-wide; no per-field change needed. This codebase already uses `withValues(alpha: ...)` elsewhere, so imitate that (not the article's `withOpacity`).

## Steps

1. In `lib/core/theme/glass_theme.dart`, add the `textSelectionTheme:` block above after the `colorScheme:` block in `light()` and again in `dark()`.
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "textSelectionTheme" lib/core/theme/glass_theme.dart` → 2
- `grep -c "selectionHandleColor" lib/core/theme/glass_theme.dart` → 2

## Don't touch

- Any individual `TextField` (the theme covers them all).
- Other theme values, dark/light logic, or `ThemeNotifier`.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
