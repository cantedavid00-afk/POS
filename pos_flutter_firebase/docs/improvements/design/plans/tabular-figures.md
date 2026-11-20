# Fix: totals and money jiggle as digits change

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/tabular-figures
- **Needs new dependency**: none

## Why

Totals in the cart, the payment dialog, shift details and report metrics use proportional digits, so a `1` turning into an `8` shifts everything after it and aligned money columns wobble. Tabular figures give every digit the same width, so changing numbers stay still and columns line up. Never global — only where numbers change or align.

## Where

No `tabularFigures` anywhere in `lib/` (grep returns nothing). Apply `fontFeatures: [FontFeature.tabularFigures()]` to the `TextStyle` of each changing/aligned number below (`FontFeature` needs no import beyond `material.dart`, already present everywhere):

POS cart + payment (`lib/features/pos/ui/pos_screen.dart`):
- cart total value `Text('\$${_total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge)` → wrap style: `Theme.of(context).textTheme.titleLarge?.copyWith(fontFeatures: [FontFeature.tabularFigures()])`
- `1324` total, `1355-1358` change `Text`, `1398` efectivo necesario, `1404` falta, `1407` cambio, `1415` summary — same treatment on each value `Text` style.

Desktop dashboard (`lib/features/home/ui/desktop/dashboard_screen.dart`): metric values at `232` (`Text('\$${...}', style: Theme.of(context).textTheme.titleLarge)`), `332` (`...titleMedium`), `363`/`370` percent Texts — add the feature to each style.

Back office (`lib/features/home/ui/back_office_screen.dart`): metric value `299` (`Text('\$${metric.$2.toStringAsFixed(2)}', style: ...titleLarge)`), chart value `363` (fontSize 10), trailing money `328`, `419`, `464` — add the feature to each style.

Reports (`lib/features/home/ui/desktop/reports_screen.dart`): `_MetricRow` builds `196: title: Text(value, style: Theme.of(context).textTheme.titleMedium),` — add the feature once here and all three money metrics are covered. Trailing money at `105` and `120` — add to each style.

Shift details: `lib/features/shift/ui/shift_screen.dart:328` is the shared row builder:
```dart
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text('\$${value.toStringAsFixed(2)}', style: style)]),
```
→ change the value `Text` to `Text('\$${value.toStringAsFixed(2)}', style: style?.copyWith(fontFeatures: [FontFeature.tabularFigures()]))` (covers every row it builds: `89`, `136`, `162`, `164`, `272`, `277`).
`lib/features/home/ui/desktop/shifts_view_screen.dart:202-213` is that screen's builder:
```dart
  Widget _detailRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
```
→ change to `Text(value, style: (valueStyle ?? const TextStyle()).copyWith(fontFeatures: [FontFeature.tabularFigures()]))` (covers rows `165-177`, `186-187`).
`lib/features/home/ui/desktop/inventory_view_screen.dart:210-221` builder:
```dart
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
```
→ change the value style to `const TextStyle(fontWeight: FontWeight.w500, fontFeatures: [FontFeature.tabularFigures()])` (covers rows `166-169`).
`lib/features/home/ui/desktop/business_config_screen.dart:169-180` `_configRow`:
```dart
  Widget _configRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
```
→ same value-style change (only digits are affected; non-numeric values render identically).

## The fix

Article's one-line font flag, applied per display above. Sentence-embedded numbers (helper texts, reasons, empty states) are intentionally left alone.

## Steps

1. Apply the style change to every site listed above (builder edits cover their rows; do not also edit the individual `_detailRow(...)` call sites).
2. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "tabularFigures" lib/features/pos/ui/pos_screen.dart` → 6
- `grep -c "tabularFigures" lib/features/home/ui/back_office_screen.dart` → 5
- `grep -c "tabularFigures" lib/features/home/ui/desktop/dashboard_screen.dart` → 4
- `grep -c "tabularFigures" lib/features/home/ui/desktop/shifts_view_screen.dart lib/features/home/ui/desktop/inventory_view_screen.dart lib/features/home/ui/desktop/business_config_screen.dart lib/features/home/ui/desktop/reports_screen.dart lib/features/shift/ui/shift_screen.dart` → 5

## Don't touch

- Sentence-embedded numbers (helper texts, reasons, chart axis labels, empty states).
- Money values themselves (numbers plan owns grouping; this plan only steadies digits).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
