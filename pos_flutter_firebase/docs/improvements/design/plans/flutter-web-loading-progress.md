# Fix: web opens on a blank white page while Flutter boots

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/flutter-web-loading-progress
- **Needs new dependency**: none

## Why

If the pollería admin ever opens the app as a web page, they stare at a blank white page for seconds wondering if it is broken. A small branded progress bar that moves with the real boot milestones tells them the app is coming.

## Where

Stock Flutter web shell — body holds only the bootstrap script:

```html
<!-- web/index.html:19-45 — current -->
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
</head>
<body>
  <!-- ...flutter_bootstrap.js comment... -->
  <script src="flutter_bootstrap.js" async></script>
</body>
```

## The fix

The article's fix, tinted to the brand (`#F76707` = `AppColors.accent`). Three files, all under `web/`:

`web/index.html` — add the stylesheet link in `<head>` (after the manifest line) and the markup in `<body>` (before the bootstrap script):

```html
  <link rel="manifest" href="manifest.json">
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <div class="progress-container">
    <div class="progress-bar"></div>
  </div>

  <script src="flutter_bootstrap.js" async></script>
</body>
```

New `web/style.css`, exactly:

```css
body {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
  margin: 0;
  background-color: #ffffff;
}

.progress-container {
  width: 120px;
  height: 8px;
  background-color: #FAFAFA;
  border-radius: 10px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  width: 0;
  background-color: #F76707;
  transition: width 0.4s ease;
}
```

New `web/flutter_bootstrap.js` (when this file exists Flutter uses it instead of the auto-generated one), article code verbatim:

```js
{{flutter_js}}
{{flutter_build_config}}

const bar = document.querySelector('.progress-bar');
const setProgress = (pct) => { bar.style.width = pct + '%'; };

setProgress(20); // bootstrap running

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    setProgress(50); // main.dart.js downloaded
    const appRunner = await engineInitializer.initializeEngine();
    setProgress(80); // engine ready
    await appRunner.runApp();
    // Flutter has taken over the page, nothing else to do
  },
});
```

## Steps

1. Edit `web/index.html` as above (keep every other line byte-identical).
2. Create `web/style.css` with the CSS above, exactly.
3. Create `web/flutter_bootstrap.js` with the JS above, exactly (keep the `{{flutter_js}}` / `{{flutter_build_config}}` placeholders literally — Flutter fills them at build time).
4. Run `flutter build web` and confirm it succeeds (proves the custom bootstrap file is accepted).

## Check it

`flutter build web` succeeds. Plus:
- `grep -c "progress-bar" web/index.html` → 1
- `grep -c "stylesheet" web/index.html` → 1
- `grep -c "F76707" web/style.css` → 1
- `grep -c "onEntrypointLoaded" web/flutter_bootstrap.js` → 1

## Don't touch

- Any Dart code (`dart analyze` need not even run for this plan; if run, it must stay clean).
- Manifest, icons, or other meta tags (preview-card plan owns those).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- `flutter build web` fails on the custom bootstrap file (then delete `web/flutter_bootstrap.js`, keep markup+CSS, and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
