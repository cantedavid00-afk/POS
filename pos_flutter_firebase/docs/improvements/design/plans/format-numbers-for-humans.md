# Fix: prices and counts show as raw digits with no grouping

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-numbers-for-humans
- **Needs new dependency**: intl (for `NumberFormat`)

## Why

The admin reads `$1234567.5` in sales reports and `1234` chickens with no thousands separator. Users read these as "how much", so every price, weight, count and percent must use the device locale grouping (`1,234,567.5` / `1 234 567,5`). Identifiers (folios, REFs, phones, PINs) are "which one" and stay untouched.

## Where

No `NumberFormat` helper exists in `lib/` (grep returns nothing); all money/counts render via `toStringAsFixed` in display strings. New file `lib/shared/extensions/num_x.dart` with the article's extension, verbatim:

```dart
import 'package:intl/intl.dart';

extension NumX on num {
  String humanizedCount({
    int? decimalDigits,
  }) {
    return NumberFormat.decimalPatternDigits(
      decimalDigits: decimalDigits,
    ).format(this);
  }

  String humanizedCurrency(String code) {
    return NumberFormat.simpleCurrency(
      name: code,
    ).format(this);
  }

  String humanizedCompact() {
    return NumberFormat.compact().format(this);
  }
}
```

Mechanical replacements (money keeps its existing `$` prefix; only the digits get locale grouping; keep each site's old decimal count as `decimalDigits`):
- R1 money: `\$${EXPR.toStringAsFixed(2)}` → `\$${EXPR.humanizedCount(decimalDigits: 2)}`
- R2 money whole: `\$${EXPR.toStringAsFixed(0)}` → `\$${EXPR.humanizedCount(decimalDigits: 0)}`
- R3 weights/counts: `${EXPR.toStringAsFixed(N)}` → `${EXPR.humanizedCount(decimalDigits: N)}` (keep N; drop the unit text untouched)
- R4 integer counts: `${INTEXPR}` where the value is a chicken/unit count → `${INTEXPR.humanizedCount()}`
- R5 percents: `${EXPR.toStringAsFixed(N)}%` → `${EXPR.humanizedCount(decimalDigits: N)}%`

Apply to these UI sites (add `import '<relative>/shared/extensions/num_x.dart';` per file):
- `lib/features/pos/ui/pos_screen.dart` (8): lines 727 (R3 N=price decimals as-is), 1324 (R1), 1346 (R2), 1356 (R1 on both branches), 1398 (R1), 1404 (R1), 1407 (R1), 1415 (R1 ×3). Example current `Text('Total: \$${total.toStringAsFixed(2)}', ...)` → `Text('Total: \$${total.humanizedCount(decimalDigits: 2)}', ...)`.
- `lib/features/pos/ui/ticket_detail_screen.dart` (1): line 116 (R1 on `unitPrice`).
- `lib/features/sales/ui/receipts_screen.dart` (1): line 207 (R1 on `unitPrice`).
- `lib/features/home/ui/back_office_screen.dart` (18): lines 299, 328, 419, 463, 464 (R1); 363 (R2); 491–495, 497–499 (R1); 511, 513 (R3 N=2, keep `kg`); 794 (R3 N=2); 805 (R1 N=1 → decimalDigits: 1). Lines 854–855 are the `_formatQuantity` helper — do NOT change it (see Don't touch).
- `lib/features/home/ui/desktop/dashboard_screen.dart` (4): lines 232, 332 (R1); 363, 370 (R5 N=0).
- `lib/features/home/ui/desktop/reports_screen.dart` (6): lines 61, 68, 75, 105, 120 (R1); 165 `title: '${entry.value.key}\n${entry.value.value.toStringAsFixed(0)}'` (R3 N=0).
- `lib/features/home/ui/desktop/shifts_view_screen.dart` (14): lines 141, 143, 165–171, 173, 174, 177 (R1); 186, 187 (R3 N=2, keep `kg`).
- `lib/features/home/ui/desktop/inventory_view_screen.dart` (5): line 102 stock part (R3 N=2); 166, 167 (R1); 168, 169 (R3 N=2).
- `lib/features/shift/ui/shift_screen.dart` (7): lines 89, 136, 162, 164, 272, 277 (R1/R3 as written); 328 the `_row` builder `Text('\$${value.toStringAsFixed(2)}', ...)` (R1 — one edit covers all its rows).
- `lib/features/sales/data/pdf_service.dart` (5): lines 105 (R3 on `quantity`), 106, 142, 149 (R1); 166 (R3 on `qty`).
- `lib/features/butcher/ui/butcher_recipe_screen.dart` (13): lines 56, 93, 191, 192 (R5 N=2); 474, 481, 531, 538 (R3 N=3, keep `kg`); 548 (R4 on both counts); 590 (R3 N=3); 591 (R1); 592 (R3 N=0); 595 (R3 N=3).
- `lib/features/butcher/ui/butcher_screen.dart` (10): lines 144, 171, 308, 384, 410, 471, 474, 480 (R3, keep `kg` and `%` text); 411 (R5 N=1); 418 (R5 N=1).
- `lib/features/transfers/ui/send_transfer_screen.dart` (3): lines 104 (message, R3 N=2), 230, 260 (R3 N=2, keep `kg`/label).
- `lib/features/transfers/ui/receive_transfer_screen.dart` (1): line 219 (R3 N=2). Line 69 sets a controller (`text: item.sentQuantity.toStringAsFixed(2)`) — do NOT change it (input round-trip, see Don't touch).
- `lib/features/losses/ui/losses_screen.dart` (3): lines 255, 280, 315 (R3, keep N and unit).
- `lib/features/butcher/domain/butcher_anomaly.dart:63` (1): `'Quedan ${remainingKg.toStringAsFixed(2)} kg...'` (R3 N=2).
- `lib/features/butcher/data/butcher_receipt_service.dart:274-275` (1): the `'disponible ${...} kg, requerido ${...} kg'` message (R3 N=2 both).
- `lib/core/offline/sync_handlers.dart:1612-1613` (1): same stock message shape (R3 N=2 both).

## The fix

Article's `NumX` extension plus the replacements above. `NumberFormat` follows the device region by default — no locale passed, no `main()` change needed.

## Steps

1. Add `intl` to `pubspec.yaml` dependencies and run `flutter pub get`.
2. Create `lib/shared/extensions/num_x.dart` with the extension above, exactly.
3. Apply R1–R5 to every site listed above, adding the import per file.
4. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus per-file greps:
- `grep -c "humanized" lib/features/pos/ui/pos_screen.dart` → 10
- `grep -c "humanized" lib/features/home/ui/back_office_screen.dart` → 18
- `grep -c "humanized" lib/features/home/ui/desktop/shifts_view_screen.dart` → 14
- `grep -c "humanized" lib/features/butcher/ui/butcher_recipe_screen.dart` → 14
- `grep -c "humanized" lib/features/butcher/ui/butcher_screen.dart` → 11
- `grep -c "humanized" lib/features/shift/ui/shift_screen.dart` → 7
- `grep -c "humanized" lib/features/home/ui/desktop/reports_screen.dart` → 6
- `grep -c "humanized" lib/features/home/ui/desktop/inventory_view_screen.dart` → 5
- `grep -c "humanized" lib/features/sales/data/pdf_service.dart` → 5
- `grep -c "humanized" lib/features/home/ui/desktop/dashboard_screen.dart` → 4
- `grep -c "humanized" lib/features/transfers/ui/send_transfer_screen.dart` → 3
- `grep -c "humanized" lib/features/losses/ui/losses_screen.dart` → 3
- single-site files (`ticket_detail_screen`, `receipts_screen`, `receive_transfer_screen`, `butcher_anomaly`, `butcher_receipt_service`, `sync_handlers`): `grep -c "humanized"` → 1 (butcher_receipt_service and sync_handlers span 2 lines of one message → still 1 logical site but 2 `humanized` occurrences; expect 2 there)

## Don't touch

- IDs and codes: folios, REFs, phones, PINs, file names, chart grouping keys (`'${date.year}-...'` keys), controller initial texts (input round-trip: `receive_transfer_screen.dart:69`, `add_product`/adjust controllers).
- Machine-read formats: `backup_service.dart:348` `_numString`, `csv_export_service.dart` cells, `backup_service.dart:339` filename, `excel_export_service.dart:225-230` filename (CSV/Excel carry raw values for sums and re-import).
- Display helpers with their own trimming (`cart_item.dart` `formattedQuantity`, back office `_formatQuantity`): their call sites above are migrated, the helpers stay.
- `humanizedCurrency`/`humanizedCompact` exist for future use; this plan only wires `humanizedCount` (the app's `$` prefix and currency stay exactly as today).
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
