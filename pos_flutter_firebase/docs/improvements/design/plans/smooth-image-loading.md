# Fix: product photos pop in with no placeholder or fade

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/smooth-image-loading
- **Needs new dependency**: image_fade (placeholder + cross-fade + error widget in one, exactly what the article prescribes)

## Why

Product photos in the catalog load over the network and just pop in, with no placeholder while loading and no fade. Cashiers scrolling products see images flashing into place. A plain grey box until each photo is ready, faded in, makes the grid feel calm.

## Where

The single network-image site in the app (`Image.network` grep over `lib/` returns only this; it already has an error fallback but no loading placeholder and no fade):

```dart
// lib/shared/widgets/product_presentation.dart:40-58 — current
    if (product.presentationType == 'image' && product.imageUrl != null) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 0,
        blur: 4,
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Image.network(
            product.imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _ShapePresentation(product: product, size: size),
          ),
        ),
      );
    }
```

## The fix

The article's fix: `ImageFade` with a plain grey placeholder and a subtle broken-image error state. Target state (keeps the surrounding `GlassContainer`/`ClipRRect`/sizing untouched; the box is already fixed at `size × size`, so layout never jumps):

```dart
    if (product.presentationType == 'image' && product.imageUrl != null) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 0,
        blur: 4,
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: ImageFade(
            image: NetworkImage(product.imageUrl!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: Container(
              color: Colors.grey.shade100,
            ),
            errorBuilder: (context, exception) {
              return Container(
                color: Colors.grey.shade100,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              );
            },
          ),
        ),
      );
    }
```

Keep placeholders simple per the article: solid light grey, no spinners. Error stays subtle: small icon, no technical message (replaces the current shape-letter fallback only for the network branch; `_ShapePresentation` itself is untouched).

## Steps

1. Add `image_fade` to `pubspec.yaml` dependencies and run `flutter pub get`.
2. In `lib/shared/widgets/product_presentation.dart`, add `import 'package:image_fade/image_fade.dart';` and replace the `Image.network(...)` call with the `ImageFade(...)` above, exactly.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "ImageFade" lib/shared/widgets/product_presentation.dart` → 2 (import + usage)
- `grep -c "Image.network" lib/shared/widgets/product_presentation.dart` → 0
- `grep -c "image_fade" pubspec.yaml` → 1

## Don't touch

- `_ShapePresentation` and the `Image.file` (local photo) branch: local files load instantly.
- Grid layout, sizes, or `GlassContainer`.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- `ImageFade` has no `width`/`height`/`fit` parameters in the installed version (then wrap it in a `SizedBox(width: size, height: size)` instead and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
