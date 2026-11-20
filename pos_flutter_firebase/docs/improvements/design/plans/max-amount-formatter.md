# Fix: amount fields accept more than the limit, then complain

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/max-amount-formatter
- **Needs new dependency**: none

## Why

At payment time the cashier types an amount past the ticket total and only then gets an error ("no cubre", "falta efectivo"); same for card amounts, weight entries over stock, and loss quantities over stock. A field that simply never accepts more than its limit removes the error-showing round trip entirely.

## Where

New file `lib/shared/widgets/max_amount_input_formatter.dart`, article code verbatim:

```dart
import 'package:flutter/services.dart';

class MaxAmountInputFormatter extends TextInputFormatter {
  final double maxAmount;

  MaxAmountInputFormatter(this.maxAmount);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final double? value = double.tryParse(newValue.text);
    if (value == null) return oldValue;

    if (value > maxAmount) return oldValue;

    return newValue;
  }
}
```

(No comma handling needed: every field below already restricts input to digits via keyboard type; the existing submit-time `replaceAll(',', '.')` parsing stays as a safety net.)

Five capped fields (each max is known at build time):
- `lib/features/pos/ui/pos_screen.dart:1327-1338` — "Dinero recibido" vs ticket total:
```dart
              TextField(
                controller: _receivedController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
```
→ add `inputFormatters: [MaxAmountInputFormatter(widget.total)],` (keep the existing `errorText`/validation as a safety net for pasted values; the formatter blocks typing past the total).
- `lib/features/pos/ui/pos_screen.dart:1361-1371` — "Monto con tarjeta", max = ticket total → `inputFormatters: [MaxAmountInputFormatter(total)],` (`total` is the local `widget.total` in scope at `:1299`).
- `lib/features/pos/ui/pos_screen.dart:1373-1383` — "Efectivo recibido" in split mode, max = ticket total → same formatter with `total`.
- Weight dialog in the same file (`_WeightQuantityDialogState`, field with `controller: _controller`, `keyboardType: numberWithOptions(decimal: true)`), max = `widget.product.stockQuantity` → `inputFormatters: [MaxAmountInputFormatter(widget.product.stockQuantity)],`.
- `lib/features/losses/ui/losses_screen.dart:319-327` — "Kilos/Piezas perdidas", max = `widget.currentStock`:
```dart
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.numberWithOptions(decimal: _isWeight),
```
→ add `inputFormatters: [MaxAmountInputFormatter(widget.currentStock)],`.

Each touched file gains the formatter import with the correct relative path.

## The fix

Article's `MaxAmountInputFormatter` wired into the five fields above. Empty text still passes (user can clear and retry); over-limit edits are dropped with no error UI.

## Steps

1. Create `lib/shared/widgets/max_amount_input_formatter.dart` with the class above, exactly.
2. Add the `inputFormatters:` line to the five fields above.
3. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "MaxAmountInputFormatter" lib/features/pos/ui/pos_screen.dart` → 4 (3 usages + 1 import)
- `grep -c "MaxAmountInputFormatter" lib/features/losses/ui/losses_screen.dart` → 2 (1 usage + 1 import)
- `grep -c "class MaxAmountInputFormatter" lib/shared/widgets/max_amount_input_formatter.dart` → 1

## Don't touch

- Absolute-stock fields with no upper max (inventory adjust dialog, opening/closing cash, cash movements): any positive value is legal there; existing validation stays.
- Controller-initial texts and submit-time parsing (safety nets, unchanged).
- The article's digit pre-filter (`FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))`): these money fields accept cents implicitly via the decimal keyboard; adding a 2-decimal filter would change kg inputs like `2.500`, so it is intentionally omitted.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
