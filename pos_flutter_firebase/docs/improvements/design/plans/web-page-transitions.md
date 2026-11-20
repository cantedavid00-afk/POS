# Fix: sub-pages slide like mobile on the desktop .exe

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/web-page-transitions
- **Needs new dependency**: none

## Why

The admin's `.exe` is click-and-open, but "Nuevo producto", "Editar producto" and ticket detail slide in with mobile animations, which looks cheap on desktop. Pages must switch with no transition on desktop (and web), keeping native transitions on phones.

## Where

`windows/` (and `web/`) folders exist, and there is no `pageTransitionsTheme`/`PageTransitionsBuilder` branch anywhere in `lib/`. The shell route already uses `NoTransitionPage`, but the three pushed sub-routes use the default `builder:` (mobile slide on desktop):

```dart
// lib/core/router/app_router.dart:28-44 — current
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
          routes: [
            GoRoute(
              path: 'products/add',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                return AddProductScreen(
                  businessId: params['businessId'] as String? ?? '',
                  storeId: params['storeId'] as String? ?? '',
                );
              },
            ),
```

```dart
// lib/core/router/app_router.dart:45-68 — current
            GoRoute(
              path: 'products/edit',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                return AddProductScreen(
                  businessId: params['businessId'] as String? ?? '',
                  storeId: params['storeId'] as String? ?? '',
                  product: params['product'] as Product?,
                );
              },
            ),
            GoRoute(
              path: 'tickets/:saleId',
              parentNavigatorKey: _rootNavigatorKey,
              builder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                return TicketDetailScreen(
                  businessName: params['businessName'] as String? ?? '',
                  store: params['store'] as Store,
                  sale: params['sale'] as Sale,
                );
              },
            ),
```

Theme constructors without any transition override:

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

(`dark()` at `glass_theme.dart:190` has the mirrored `colorScheme: ColorScheme.dark(...)` block.)

## The fix

The article's fix at both levels. First the theme (covers `MaterialPageRoute` pushes like the Pollería config at `settings_screen.dart:101-105`), article code verbatim adapted to this file:

```dart
// add to lib/core/theme/glass_theme.dart (needs package:flutter/foundation.dart import)
const PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ZoomPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: _NoPageTransitionsBuilder(),
    TargetPlatform.windows: _NoPageTransitionsBuilder(),
    TargetPlatform.linux: _NoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
  },
);

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
```

Then assign `pageTransitionsTheme: appPageTransitionsTheme,` inside both `ThemeData(` constructors in `GlassTheme.light()` and `GlassTheme.dark()` (after each `colorScheme:` block).

Then the router (per the article: "Not using MaterialApp? Customize it at your router (go_router uses pageBuilder)"). Convert the three sub-route `builder:` blocks to:

```dart
              pageBuilder: (context, state) {
                final params = state.extra as Map<String, dynamic>? ?? {};
                final child = AddProductScreen(
                  businessId: params['businessId'] as String? ?? '',
                  storeId: params['storeId'] as String? ?? '',
                );
                if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) {
                  return NoTransitionPage(child: child);
                }
                return MaterialPage(child: child);
              },
```

(same shape for `products/edit` with its extra `product:` arg, and for `tickets/:saleId` with its `TicketDetailScreen`). `app_router.dart` already imports `material.dart` (covers `kIsWeb`? no — add `import 'package:flutter/foundation.dart';` for `kIsWeb`/`defaultTargetPlatform`).

## Steps

1. In `glass_theme.dart`, add the foundation import, the `appPageTransitionsTheme` + `_NoPageTransitionsBuilder`, and assign `pageTransitionsTheme:` in both theme constructors.
2. In `app_router.dart`, add the foundation import and convert the three sub-route builders to the desktop-gated `pageBuilder` above.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "pageTransitionsTheme" lib/core/theme/glass_theme.dart` → 2
- `grep -c "NoTransitionPage" lib/core/router/app_router.dart` → 4
- `grep -c "defaultTargetPlatform" lib/core/router/app_router.dart` → 3

## Don't touch

- Route paths, params, guards, or `parentNavigatorKey`s.
- Mobile behavior: Android keeps zoom, iOS keeps Cupertino (article: native defaults on phones).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
