# Fix: tapping a half-hidden category doesn't bring it into view

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tab-visibility
- **Needs new dependency**: none

## Why

The POS category strip is custom-built (not a Material `TabBar`, which would handle this itself). When the cashier taps a category chip that is only half visible, the strip stays put and the selection feels disconnected. The tapped chip must scroll fully into view, centered.

## Where

The only custom tab bar in the app (no `Scrollable.ensureVisible` anywhere in `lib/`):

```dart
// lib/features/pos/ui/pos_screen.dart:920-988 — current (_CategoryFilterState)
class _CategoryFilterState extends State<_CategoryFilter> {
  late Stream<List<app_models.Category>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = context
        .read<CategoryRepository>()
        .watchCategories(businessId: widget.businessId);
  }

  @override
  void didUpdateWidget(_CategoryFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessId != widget.businessId) {
      _categoriesStream = context
          .read<CategoryRepository>()
          .watchCategories(businessId: widget.businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<app_models.Category>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <app_models.Category>[];
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

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
      },
    );
  }
}
```

## The fix

The article's pattern: one `GlobalKey` per tab, `Scrollable.ensureVisible` with `alignment: 0.5` on selection. Convert `_CategoryFilterState` to keep a `Map<String, GlobalKey>` keyed by `'all'` + each category id (rebuilt when the category list changes), wrap each chip in a keyed transparent wrapper (chips can't take the key for scrolling purposes — attach the key to a `Container` around each `ChoiceChip`), and scroll on selection:

```dart
  final Map<String, GlobalKey> _keys = {};

  void _syncKeys(List<app_models.Category> categories) {
    final ids = {'all', for (final c in categories) c.id};
    _keys.removeWhere((id, _) => !ids.contains(id));
    for (final id in ids) {
      _keys.putIfAbsent(id, () => GlobalKey());
    }
  }

  void _scrollTo(String id) {
    final context = _keys[id]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }
```

In `build`, after computing `categories`, call `_syncKeys(categories)`. Wrap the two chip returns: `Container(key: _keys['all'], child: ChoiceChip(...))` and `Container(key: _keys[category.id], child: ChoiceChip(...))`. In each `onSelected`, after `widget.onChanged(...)`, call `_scrollTo('all')` / `_scrollTo(category.id)`. Also scroll to the initially selected tab one frame after first layout:

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = widget.selectedCategoryId ?? 'all';
      _scrollTo(selected);
    });
```

(place it in `initState`).

## Steps

1. In `lib/features/pos/ui/pos_screen.dart`, apply the `_keys`/`_syncKeys`/`_scrollTo` additions, the keyed wrappers, the `onSelected` scroll calls, and the post-frame initial scroll in `_CategoryFilterState`.
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "ensureVisible" lib/features/pos/ui/pos_screen.dart` → 1
- `grep -c "_scrollTo" lib/features/pos/ui/pos_screen.dart` → 4 (definition + initState + 2 onSelected calls)
- `grep -c "GlobalKey" lib/features/pos/ui/pos_screen.dart` → 2 (`Map<String, GlobalKey>` + `() => GlobalKey()`)

## Don't touch

- Chip visuals, filtering logic, or the `onChanged` contract (scroll calls are additions after it).
- The Material `TabBar`s (losses, back office, products) — they already auto-scroll.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
