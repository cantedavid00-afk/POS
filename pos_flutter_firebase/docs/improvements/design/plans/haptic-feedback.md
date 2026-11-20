# Fix: taps and results happen in silence, the app feels flat

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/haptic-feedback
- **Needs new dependency**: haptic_feedback (richer types than built-in `HapticFeedback`: success/warning/error/light/medium/heavy)

## Why

Closing a sale, registering chicken, switching tabs or hitting an error all happen with zero vibration, so the app feels unresponsive in the hand. Subtle haptics on success, error, tab switches and toggles make every key moment land.

## Where

No haptics exist anywhere (`HapticFeedback|haptic_feedback|Haptics\.|vibrate` grep over `lib/` returns nothing). New file `lib/shared/utils/haptics_helper.dart`, article code verbatim:

```dart
import 'package:haptic_feedback/haptic_feedback.dart';

class HapticsHelper {
  HapticsHelper._();

  static bool? _canVibrate;

  static Future<void> _vibrate(HapticsType type) async {
    _canVibrate ??= await Haptics.canVibrate();

    if (_canVibrate ?? false) {
      await Haptics.vibrate(type);
    }
  }

  // Declarative shorthand for each type
  static Future<void> success() => _vibrate(HapticsType.success);
  static Future<void> warning() => _vibrate(HapticsType.warning);
  static Future<void> error() => _vibrate(HapticsType.error);
  static Future<void> light() => _vibrate(HapticsType.light);
  static Future<void> medium() => _vibrate(HapticsType.medium);
  static Future<void> heavy() => _vibrate(HapticsType.heavy);
  static Future<void> selection() => _vibrate(HapticsType.selection);
}
```

Wire these moments (pairings per the article: success = completed sale/submit, error = failed request, light = tab tap/toggle):
- `lib/features/pos/ui/pos_screen.dart:246-253` — after the folio success message is built in `_charge`, call `HapticsHelper.success()`; in `_charge`'s catch where `_logger.error('Error al crear venta: $e', tag: 'Sale');` runs, call `HapticsHelper.error()`. Current success text:
```dart
              ? 'Venta $folio guardada. Efectivo: \$${(cashAmount ?? 0).toStringAsFixed(2)} · Tarjeta: \$${(cardAmount ?? 0).toStringAsFixed(2)} · Cambio: \$${cambio.toStringAsFixed(2)}'
```
- `lib/features/shift/ui/shift_screen.dart:235` — `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Turno cerrado')));` → add `HapticsHelper.success();` before it. Error paths at `:209` and `:238` (`SnackBar(content: Text(e.toString()))`) → add `HapticsHelper.error();` before each.
- `lib/features/losses/ui/losses_screen.dart:277-281` — before the `ScaffoldMessenger.of(context).showSnackBar(` with `'Pérdida registrada: ...'`, add `HapticsHelper.success();`. In its catch (`:284-289` ending `return;`), add `HapticsHelper.error();` before the `setState`.
- `lib/features/poultry/ui/receive_chicken_screen.dart:64` — `const SnackBar(content: Text('Recepción guardada correctamente')),` → `HapticsHelper.success();` before the messenger call. Line `:77` error snackbar → `HapticsHelper.error();` before it.
- `lib/features/poultry/ui/poultry_config_screen.dart:115` — `const SnackBar(content: Text('Configuración guardada')),` → success haptic before it. Line `:120` error snackbar → error haptic before it.
- `lib/features/butcher/ui/butcher_screen.dart:207-209` — `const SnackBar(content: Text('Destazado registrado correctamente')),` → success haptic before it. Its `_showError` (`:219-222`) → error haptic inside `_showError` before showing the bar.
- `lib/features/transfers/ui/send_transfer_screen.dart:158-160` — `const SnackBar(content: Text('Transferencia enviada')),` → success haptic before it. Lines `:164-165` error snackbar → error haptic before it.
- Tab switches: `lib/features/losses/ui/losses_screen.dart:55`, `lib/features/home/ui/back_office_screen.dart:78`, `lib/features/products/ui/products_screen.dart:49` — each is `bottom: TabBar(`. Add `onTap: (_) => HapticsHelper.light(),` as a `TabBar` parameter (fire-and-forget; do not await in the callback).
- Toggles: `lib/features/home/ui/back_office_screen.dart:1298-1310` (store `CheckboxListTile`), `:1317-1331` (permission `CheckboxListTile`), `:1333-1338` (`SwitchListTile` `'Activo'`) — add `HapticsHelper.light();` as the first statement inside each `onChanged`/`setState` body.

All haptic calls are fire-and-forget (no `await`, no signature changes). Each touched file gains `import '<relative>/shared/utils/haptics_helper.dart';`.

## The fix

Article's `HapticsHelper` plus the call sites above, using the article's pairings.

## Steps

1. Add `haptic_feedback` to `pubspec.yaml` and run `flutter pub get`.
2. Create `lib/shared/utils/haptics_helper.dart` with the helper above, exactly.
3. Add the success/error/light calls at every site listed above.
4. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "HapticsHelper" lib/shared/utils/haptics_helper.dart` → 9
- `grep -c "HapticsHelper.success()" lib/features/pos/ui/pos_screen.dart lib/features/shift/ui/shift_screen.dart lib/features/losses/ui/losses_screen.dart lib/features/poultry/ui/receive_chicken_screen.dart lib/features/poultry/ui/poultry_config_screen.dart lib/features/butcher/ui/butcher_screen.dart lib/features/transfers/ui/send_transfer_screen.dart` → 7
- `grep -c "HapticsHelper.error()" lib/features/pos/ui/pos_screen.dart lib/features/shift/ui/shift_screen.dart lib/features/losses/ui/losses_screen.dart lib/features/poultry/ui/receive_chicken_screen.dart lib/features/poultry/ui/poultry_config_screen.dart lib/features/butcher/ui/butcher_screen.dart lib/features/transfers/ui/send_transfer_screen.dart` → 8
- `grep -c "HapticsHelper.light()" lib/features/losses/ui/losses_screen.dart lib/features/home/ui/back_office_screen.dart lib/features/products/ui/products_screen.dart` → 6 (3 tab bars + 3 toggles, the toggles all live in back_office)

## Don't touch

- iOS-only behavior, vibration settings UI, or any business logic (calls are side-effect-only additions).
- Desktop-only flows need no guard: `canVibrate` already no-ops where there is no motor.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- The installed `haptic_feedback` API differs (`Haptics.canVibrate`, `Haptics.vibrate`, `HapticsType` names) — adapt names only, keep the pairings, and report.
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
