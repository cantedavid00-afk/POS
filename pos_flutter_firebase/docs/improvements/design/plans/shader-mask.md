# Fix: the category strip gives no hint it scrolls

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/shader-mask
- **Needs new dependency**: none

## Why

In the POS screen the category chips sit in a horizontal strip that often fits exactly on screen, so cashiers never realize there are more categories to the side. Fading the trailing edge hints that the strip scrolls, using only `ShaderMask` with no new package.

## Where

The only horizontal tab-like list in the app (no `ShaderMask`/`LinearGradient` fade exists anywhere in `lib/`):

```dart
// lib/features/pos/ui/pos_screen.dart:960-984 — current
        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return ChoiceChip(
                  selected: widget.selectedCategoryId == null,
                  label: const Text('Todas'),
                  onSelected: (_) => widget.onChanged(null),
                );
              }

              final category = categories[index - 1];
              return ChoiceChip(
                selected: widget.selectedCategoryId == category.id,
                avatar: CircleAvatar(backgroundColor: Color(category.color)),
                label: Text(category.name),
                onSelected: (_) => widget.onChanged(category.id),
              );
            },
          ),
        );
```

(The other horizontal scroller, the yield table in `butcher_recipe_screen.dart:542`, is a wide data table, not a tab strip — out of scope, see Don't touch.)

## The fix

The article's reusable `Edgy` widget, then wrap this strip with the horizontal direction (fade the end edge). New file `lib/shared/widgets/edgy.dart`, article code verbatim:

```dart
import 'package:flutter/material.dart';

class Edgy extends StatelessWidget {
  final Widget child;
  final Axis axis;
  final bool fadeStart;
  final bool fadeEnd;

  const Edgy({
    super.key,
    required this.child,
    this.axis = Axis.vertical,
    this.fadeStart = true,
    this.fadeEnd = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVertical = axis == Axis.vertical;

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: <Color>[
            fadeStart ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            const Color(0xFFFFFFFF),
            fadeEnd ? const Color(0x00FFFFFF) : const Color(0xFFFFFFFF),
          ],
          stops: const <double>[0.0, 0.12, 0.88, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
```

Target state in `pos_screen.dart` (import `../.../shared/widgets/edgy.dart` with the correct relative path from `lib/features/pos/ui/`):

```dart
        return SizedBox(
          height: 42,
          child: Edgy(
            axis: Axis.horizontal,
            fadeStart: false,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              ... // unchanged
            ),
          ),
        );
```

Only the end edge fades (`fadeStart: false`): the strip starts at "Todas", so users only need the hint that more lies to the right.

## Steps

1. Create `lib/shared/widgets/edgy.dart` with the widget above, exactly.
2. In `lib/features/pos/ui/pos_screen.dart`, add the import and wrap the `ListView.separated` of `_CategoryFilterState.build` in `Edgy(axis: Axis.horizontal, fadeStart: false, child: ...)`, changing nothing else.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "Edgy" lib/features/pos/ui/pos_screen.dart` → 2 (import + usage)
- `grep -c "ShaderMask" lib/shared/widgets/edgy.dart` → 1

## Don't touch

- The yield table scroller in `butcher_recipe_screen.dart` (data table, not a tab strip).
- Chip visuals, selection logic, or the `onChanged` callback.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
