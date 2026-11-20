# Fix: detail sheets open and close with a mechanical motion

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-draggable-bottom-sheets
- **Needs new dependency**: none

## Why

On the desktop admin screens, tapping a shift or a product pops a detail sheet with Material's stiff mechanical motion, and it can't be dragged away. A spring-driven sheet that follows the finger and settles softly makes these everyday lookups feel crafted.

## Where

The only two `showModalBottomSheet` calls in the app, both small non-scrolling detail sheets (`Column` + `mainAxisSize.min`, no scrollable inside — exactly the article's scope):
- `lib/features/home/ui/desktop/shifts_view_screen.dart:151-155`:
```dart
  void _showShiftDetail(BuildContext context, Shift shift) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
```
- `lib/features/home/ui/desktop/inventory_view_screen.dart:151-155`:
```dart
  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
```

New file `lib/shared/widgets/spring_sheet.dart` with the article's whole file verbatim (copy the full 285-line file from the article: `showSpringBottomSheet`, `SpringSheetRoute`, `SheetContainer`, `_ClampedAnimation` — imports `package:flutter/material.dart` + `package:flutter/physics.dart`). Adapt one value to this app: `SheetContainer`'s surface `color: Colors.white` → `Theme.of(context).colorScheme.surface` so sheets follow light/dark mode:

```dart
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: child,
        ),
      ),
    );
  }
```

(Note: the article's dots (`.transparency`, `.vertical`) are the author's shorthand — write them out as `MaterialType.transparency` and `BorderRadius.vertical`, as above. Everything else stays verbatim.)

Content builders stay untouched (they already build `Column(mainAxisSize: MainAxisSize.min)` content with padding — the route wraps them in `SheetContainer`, so remove nothing from them; the extra `Padding(viewInsets.bottom)` + `Container(padding: 16)` wrappers stay as the builder's content).

Call-site changes (same API as `showModalBottomSheet`):
- shifts: `showModalBottomSheet(context: context, isScrollControlled: true, builder: ...)` → `showSpringBottomSheet(context: context, builder: ...)` + import.
- inventory: identical replacement + import.

## The fix

Article's spring sheet file (with the surface-color adaptation above) plus the two call-site swaps.

## Steps

1. Create `lib/shared/widgets/spring_sheet.dart` with the article's file (adapted `SheetContainer` only), exactly.
2. Swap the two `showModalBottomSheet` calls to `showSpringBottomSheet`, dropping `isScrollControlled` (the route is bottom-anchored by construction) and adding imports.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "showSpringBottomSheet" lib/features/home/ui/desktop/shifts_view_screen.dart lib/features/home/ui/desktop/inventory_view_screen.dart` → 4 (2 imports + 2 calls)
- `grep -c "showModalBottomSheet" lib/features/home/ui/desktop/shifts_view_screen.dart lib/features/home/ui/desktop/inventory_view_screen.dart` → 0
- `grep -c "SpringSimulation" lib/shared/widgets/spring_sheet.dart` → 3

## Don't touch

- Sheet contents (rows, padding, viewInsets handling) — only the route changes.
- Full-screen flows (none exist; the iOS-26-style sheet article is out of scope).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
