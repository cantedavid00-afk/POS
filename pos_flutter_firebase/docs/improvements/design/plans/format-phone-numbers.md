# Fix: phone numbers are an unreadable run of digits

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-phone-numbers
- **Needs new dependency**: mask_text_input_formatter (single-country mask + format/unformat helpers, exactly the article's approach)

## Why

Branch and employee phones show as `5512345678` in lists, on the printed receipt and in the Excel export — hard to read and easy to mistype. The pollería operates in one country (Mexico, 10 digits), so one mask formats every display and every keystroke, while the database keeps raw digits.

## Where

No phone mask/formatter exists (`MaskTextInputFormatter|inputFormatters` on phone fields and `maskPhoneNumber` greps return nothing). New file `lib/shared/extensions/phone_x.dart`, article code verbatim with the Mexican mask:

```dart
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

final phoneNumberInputFormatter = MaskTextInputFormatter(
  mask: '+52 ## #### ####',
  filter: {
    "#": RegExp(r'[0-9]'),
  },
  type: MaskAutoCompletionType.eager,
);

extension StringX on String {
  String get maskPhoneNumber {
    return phoneNumberInputFormatter.maskText(this);
  }

  String get unmaskPhoneNumber {
    return phoneNumberInputFormatter.unmaskText(this);
  }
}
```

(Note: this `StringX` extension is on non-nullable `String` for masking only; the null-guard `StringX` from the never-show-null plan lives on `String?` in `string_x.dart` — different files, no clash. If both plans run, keep both files as-is.)

Typing fields (wire `inputFormatters: [phoneNumberInputFormatter]` + import; the mask inserts spaces eagerly as they type):
- `lib/features/home/ui/back_office_screen.dart:1263-1267`:
```dart
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefono (opcional)', border: OutlineInputBorder()),
            ),
```
- `lib/features/home/ui/desktop/employees_view_screen.dart:184`: `TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder())),`
- `lib/features/home/ui/desktop/business_config_screen.dart:139`: `TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder())),`
- `lib/features/settings/ui/settings_screen.dart:476`: `TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Telefono', border: OutlineInputBorder())),`

Saving must send raw digits (article: `unmaskText` before the API). The save sites pass controller text straight through today:
- `lib/features/home/ui/back_office_screen.dart:1388` (`final phone = _phoneController.text.trim();` → `final phone = _phoneController.text.unmaskPhoneNumber();`)
- `lib/features/home/ui/desktop/employees_view_screen.dart` (its save passes `phoneController.text` → wrap with `.unmaskPhoneNumber()`; find the exact line by reading the dialog's save — STOP if it doesn't pass controller text directly)
- `lib/features/home/ui/desktop/business_config_screen.dart` (same: wrap the store-create `phoneController.text`)
- `lib/features/settings/ui/settings_screen.dart:504` (`phone: _phoneController.text,` → `phone: _phoneController.text.unmaskPhoneNumber(),`)

Displays (wrap the raw value with `.maskPhoneNumber`):
- `lib/features/home/ui/home_screen.dart:328` (`if (store.phone.isNotEmpty) store.phone,` → `if (store.phone.isNotEmpty) store.phone.maskPhoneNumber,`)
- `lib/features/home/ui/desktop/desktop_layout.dart:243` (`... if (store.phone.isNotEmpty) store.phone].join(' · ')` → mask the phone element)
- `lib/features/home/ui/desktop/business_config_screen.dart:64` (`subtitle: Text('${store.address} · ${store.phone}'),` → mask `store.phone`)
- `lib/features/home/ui/back_office_screen.dart:891` (`if (employee.phone.isNotEmpty) employee.phone,` → mask it)
- `lib/features/settings/ui/settings_screen.dart:81` (`if (store.phone.isNotEmpty) store.phone,` → mask it)
- `lib/features/sales/data/pdf_service.dart:53-54` (`pw.Text('Tel: ${store.phone}', ...)`) → mask it
- `lib/features/business/data/excel_report_sheets.dart:193` (`[_str(s['name']), _str(s['address']), _str(s['phone']), ...]`) → mask the phone cell: `maskPhoneNumber` needs import of the extension into a data file — allowed (pure helper, no UI dependency; the file imports only `mask_text_input_formatter` + Flutter-free code... `mask_text_input_formatter` imports flutter/services — data-layer import of a Flutter package is already precedented by `cloud_firestore` in data files, fine).

## The fix

Article's mask + extension, wired into the 4 fields (with unmask on save) and 7 displays above.

## Steps

1. Add `mask_text_input_formatter` to `pubspec.yaml` and run `flutter pub get`.
2. Create `lib/shared/extensions/phone_x.dart` with the code above, exactly.
3. Wire the 4 fields, the 4 save sites, and the 7 displays.
4. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -c "phoneNumberInputFormatter" lib/features/home/ui/back_office_screen.dart lib/features/home/ui/desktop/employees_view_screen.dart lib/features/home/ui/desktop/business_config_screen.dart lib/features/settings/ui/settings_screen.dart` → 4 (one per field)
- `grep -c "unmaskPhoneNumber" lib/features/home/ui/back_office_screen.dart lib/features/settings/ui/settings_screen.dart` → 2
- `grep -c "maskPhoneNumber" lib/features/home/ui/home_screen.dart lib/features/home/ui/desktop/desktop_layout.dart lib/features/home/ui/desktop/business_config_screen.dart lib/features/home/ui/back_office_screen.dart lib/features/settings/ui/settings_screen.dart lib/features/sales/data/pdf_service.dart lib/features/business/data/excel_report_sheets.dart` → 7

## Don't touch

- Stored values: Firestore keeps raw digits (mask is display-only; unmask on save proves it).
- Non-Mexican formats: single country per the article; no country picker exists.
- Validation logic or required/optional rules of the phone fields.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- A save site doesn't pass controller text directly (then wrap at the exact handoff and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
