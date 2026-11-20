# Fix: shared web links show as a bare URL with no preview

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/flutter-web-og-image
- **Needs new dependency**: none

## Why

If anyone shares the web build of the pollería app on WhatsApp or X, it renders as a bare URL instead of a card with title, description and image. A few meta tags in `web/index.html` fix that everywhere the link is pasted.

## Where

`web/index.html` head today (no `og:`/`twitter:` tags anywhere):

```html
<!-- web/index.html:19-34 — current -->
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="pos_flutter_firebase">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>pos_flutter_firebase</title>
  <link rel="manifest" href="manifest.json">
```

## The fix

The article's tags, adapted to this app. Image URL uses the public raw file of the repo's own icon (`assets/app_icon.jpg`, referenced by `flutter_launcher_icons` in `pubspec.yaml:117`):

```html
  <title>PV Donald · Punto de venta para pollerías</title>

  <!-- Open Graph -->
  <meta property="og:title" content="PV Donald · Punto de venta para pollerías">
  <meta property="og:description" content="Ventas, inventario, turnos y destazado para tu pollería.">
  <meta property="og:image" content="https://raw.githubusercontent.com/Alolo777/POS/main/assets/app_icon.jpg">
  <meta property="og:url" content="https://github.com/Alolo777/POS">
  <meta property="og:type" content="website">

  <!-- X / Twitter -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="PV Donald · Punto de venta para pollerías">
  <meta name="twitter:description" content="Ventas, inventario, turnos y destazado para tu pollería.">
  <meta name="twitter:image" content="https://raw.githubusercontent.com/Alolo777/POS/main/assets/app_icon.jpg">
```

Per the article: `og:image` is absolute, and `twitter:image` is set explicitly (X reads its own tags first).

## Steps

1. In `web/index.html`, replace the `<title>pos_flutter_firebase</title>` line with the title + tags above, keeping every other line byte-identical.
2. Verify the image URL returns bytes: `curl.exe -sI https://raw.githubusercontent.com/Alolo777/POS/main/assets/app_icon.jpg` must show `200` and a `content-type: image/...` header.

## Check it

Step 2 passes. Plus:
- `grep -c "og:title\|og:image\|twitter:card" web/index.html` → 3
- `grep -c "twitter:image" web/index.html` → 1

## Don't touch

- Any Dart code, manifest, icons, or other meta tags (loading-progress plan owns the body).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The image URL check in step 2 fails (wrong repo path or private repo) — report the failure instead of inventing another URL. The tags must also be 1200×630 ideally; if the icon is square, note it in the final report so the developer can ship a proper banner later.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
