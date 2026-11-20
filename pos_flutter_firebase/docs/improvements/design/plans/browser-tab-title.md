# Fix: every browser tab says the same thing

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/browser-tab-title
- **Needs new dependency**: none

## Why

With several web tabs open (sales, config, tickets), every tab reads the same static title, so history, bookmarks and the tab strip can't tell them apart. Each route must set its own tab title.

## Where

No `Title(` widget exists in `lib/` and the router has exactly these routes (`lib/core/router/app_router.dart:16-86`): `/` (auth gate), `/home` (main screen), `/home/products/add`, `/home/products/edit`, `/home/tickets/:saleId`. `MaterialApp.router` with `goRouter` is built here:

```dart
// lib/main.dart:134-162 — current (relevant part)
          child: MaterialApp.router(
            title: 'PV Donald',
            ...
            routerConfig: goRouter,
            builder: (context, child) {
              ErrorWidget.builder = (errorDetails) {
                ...
              };
              return child!;
            },
          ),
```

## The fix

The article's wrapper, adapted: this app uses go_router, so copy the article's `RouteTitle` verbatim into `app_router.dart` with this `titleForPath`:

```dart
String titleForPath(String path) {
  final List<String> segments = Uri.parse(path).pathSegments;
  final String? page = switch (segments) {
    [] => null,
    ['home'] => null,
    ['home', 'products', 'add'] => 'Nuevo producto',
    ['home', 'products', 'edit'] => 'Editar producto',
    ['home', 'tickets', _] => 'Ticket',
    _ => null,
  };

  return page == null ? 'PV Donald' : '$page · PV Donald';
}
```

```dart
class RouteTitle extends StatelessWidget {
  final Widget child;

  const RouteTitle({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        goRouter.routerDelegate,
        goRouter.routeInformationProvider,
      ]),
      builder: (context, _) {
        final String path = goRouter.routeInformationProvider.value.uri.path;

        return Title(
          title: titleForPath(path),
          color: const Color(0xFFFFFFFF),
          child: child,
        );
      },
    );
  }
}
```

(`Title.color` must be opaque per the article: plain white `0xFFFFFFFF`. `ListenableBuilder` and `Title` come from `material.dart`, already imported in both files.)

Wire it in `main.dart`'s existing `builder` (the `ErrorWidget.builder` assignment stays exactly where it is):

```dart
            builder: (context, child) {
              ErrorWidget.builder = (errorDetails) {
                ...
              };
              return RouteTitle(child: child!);
            },
```

## Steps

1. In `lib/core/router/app_router.dart`, append `titleForPath` + `RouteTitle` exactly as above.
2. In `lib/main.dart`, import the router file's `RouteTitle` (same import already used for `goRouter`) and change `return child!;` to `return RouteTitle(child: child!);`.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "RouteTitle" lib/core/router/app_router.dart` → 2 (class + usage in itself? class definition only → expect 1; plus `titleForPath` separate) — use: `grep -c "class RouteTitle" lib/core/router/app_router.dart` → 1
- `grep -c "RouteTitle(child" lib/main.dart` → 1
- `grep -c "titleForPath" lib/core/router/app_router.dart` → 2

## Don't touch

- Routes, redirects, or navigation logic.
- `onGenerateTitle` (stays unused — it can't track navigation per the article).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
