# Fix: the yield table clips at the card padding instead of the screen edge

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/horizontal-list-padding
- **Needs new dependency**: none

## Why

In the butchering recipe screen the admin swipes the yields table sideways, but its columns clip at the card's inner padding line instead of sliding edge to edge. Letting the horizontal list reach the edges while it carries its own padding makes the swipe feel full-bleed and native.

## Where

The horizontal table scroller nested inside the padded recipe card:

```dart
// lib/features/butcher/ui/butcher_recipe_screen.dart:503-510 — current (card)
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      borderRadius: 0,
      blur: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
```

```dart
// lib/features/butcher/ui/butcher_recipe_screen.dart:542-545 — current (table)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildYieldTable(widget.yields, widget.isDark),
          ),
```

## The fix

The article's rule: the page stays edge to edge, each child carries its own padding — applied at card level. Restructure this card so the header rows keep the 12px padding while the table breaks out of it:

```dart
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      borderRadius: 0,
      blur: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: ... // every header child that exists today above the table, unchanged and in order
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildYieldTable(widget.yields, widget.isDark),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ... // every child that exists today below the table, unchanged and in order
              ],
            ),
          ),
        ],
      ),
    );
```

Concretely: move the current card padding into two `Padding` wrappers (header part and footer part), give the `SingleChildScrollView` its own `padding: const EdgeInsets.symmetric(horizontal: 12)`, and set the card's own `padding:` to `EdgeInsets.zero`. No child is reordered, restyled, or removed — only re-wrapped.

## Steps

1. In `lib/features/butcher/ui/butcher_recipe_screen.dart`, restructure the recipe card exactly as above.
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "scrollDirection: Axis.horizontal" lib/features/butcher/ui/butcher_recipe_screen.dart` → 1
- the line after it is now `padding: const EdgeInsets.symmetric(horizontal: 12),` (verify by reading the hunk; the grep `grep -n -A1 "scrollDirection: Axis.horizontal" lib/features/butcher/ui/butcher_recipe_screen.dart` must show the padding line)

## Don't touch

- Table contents, `_buildYieldTable`, header/footer widgets, or their order.
- The category chip strip in POS (tab strip, owned by the tab-visibility and shader-mask plans).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The card's children above/below the table differ from what the file shows (then re-wrap faithfully around the actual children and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
