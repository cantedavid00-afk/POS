# Fix: long lists give no sense of position on phones

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/scrollbars
- **Needs new dependency**: none

## Why

Cashiers scrolling hundreds of products or receipts on a phone have no scrollbar, so they can't tell where they are in the list or how much is left. Desktop already draws scrollbars automatically; the fix adds them on mobile only, so the two never clash.

## Where

No `Scrollbar`, `scrollBehavior` or `MaterialScrollBehavior` override exists in `lib/` (all three greps return nothing), while the app has 60+ vertical scrollables on pages the staff scrolls daily. Per the article, the app-wide override is the right call (not per-list wrapping).

Current app wrapper (no `scrollBehavior` today):

```dart
// lib/main.dart:134-140 — current
          child: MaterialApp.router(
            title: 'PV Donald',
            theme: GlassTheme.light(),
            darkTheme: GlassTheme.dark(),
            themeMode: themeNotifier.mode,
            routerConfig: goRouter,
```

## The fix

The article's automatic approach, verbatim. New behavior class — put it at the bottom of `lib/main.dart` (no new file; it is app wiring, and `main.dart` already imports `material.dart`):

```dart
class AlwaysScrollbarBehavior extends MaterialScrollBehavior {
  const AlwaysScrollbarBehavior();

  @override
  Widget buildScrollbar(context, child, details) {
    return Scrollbar(
      controller: details.controller,
      child: child,
    );
  }
}
```

And one line in the router constructor:

```dart
          child: MaterialApp.router(
            title: 'PV Donald',
            theme: GlassTheme.light(),
            darkTheme: GlassTheme.dark(),
            themeMode: themeNotifier.mode,
            routerConfig: goRouter,
            scrollBehavior: const AlwaysScrollbarBehavior(),
```

## Steps

1. In `lib/main.dart`, add `scrollBehavior: const AlwaysScrollbarBehavior(),` and append the `AlwaysScrollbarBehavior` class at the end of the file.
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "AlwaysScrollbarBehavior" lib/main.dart` → 3 (class + const usage; the `extends MaterialScrollBehavior` line also matches → expect 3)
- `grep -c "scrollBehavior" lib/main.dart` → 2 (override + assignment)

## Don't touch

- Individual `ListView`s (the override covers them; per-list `Scrollbar` wrapping would clash with the automatic desktop one per the article).
- Single-line fields, dropdowns, or page views (they stay scrollbar-free by design per the article).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
